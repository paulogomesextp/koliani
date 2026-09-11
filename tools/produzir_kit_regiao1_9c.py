#!/usr/bin/env python3
"""Execution 9C -- kit de ambiente da Regiao I (Floresta Corrompida).

Deriva peças de runtime SÓ das pranchas aprovadas do Master Package v2:

- 08_REGION_I_ART_KIT_BACKGROUNDS_PARALLAX_v1_0.png  (AUTORIDADE da Região I)
- 10_PRODUCTION_PACK_v8_ENV_LIGHT_ATMOSPHERE.png     (estrutural: tileset e
  elementos soltos; o nome "Floresta Sagrada" e a luz de dia NÃO são canónicos)

Não se desenha nada. Cada peça é um recorte sem perdas de uma caixa medida na
prancha, com estas operações determinísticas e mais nenhuma:

1. alfa por chave de cor contra o fundo liso do painel (binário, pixel-art);
2. graduação da prancha 10 para a noite da 08: transferência de média/desvio
   por canal, medida no terreno do "exemplo em jogo" da 08 (a 08 manda);
3. continuidade de mosaico por cross-fade da própria borda (só nas peças de
   terreno e na névoa, que se repetem);
4. escala inteira nearest-neighbour: nenhuma (tudo sai a 1x da prancha).

Uso:
    python tools/produzir_kit_regiao1_9c.py            # gera + valida
    python tools/produzir_kit_regiao1_9c.py --validar  # só valida o que existe

Saída: assets/art/regions/region_01_forest/production/kit_9c/
Prancha de revisão: work/execution_9c/kit_9c_contacto.png
"""
from __future__ import annotations

import hashlib
import json
import sys
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw

RAIZ = Path(__file__).resolve().parents[1]
PACOTE = RAIZ / "Koliani_1.0_Master_Package_v2" / "references"
P08 = "08_REGION_I_ART_KIT_BACKGROUNDS_PARALLAX_v1_0.png"
P10 = "10_PRODUCTION_PACK_v8_ENV_LIGHT_ATMOSPHERE.png"
SAIDA = RAIZ / "assets/art/regions/region_01_forest/production/kit_9c"
REVISAO = RAIZ / "work/execution_9c"

# Fundo liso dos painéis (medido): prancha 10 = teal quase preto; painel de
# "Elementos de parallax" da 08 = navy com um brilho ténue à volta das árvores.
FUNDO_10 = (0, 27, 36)
FUNDO_08_PECAS = (7, 16, 25)

# Amostras do terreno no "Exemplo de background em jogo" da 08 (pedra com
# musgo, luar azul). É o alvo da graduação das peças que vêm da 10.
ALVO_TERRENO_08 = [(14, 853, 210, 900), (454, 820, 546, 887)]


def sha256(caminho: Path) -> str:
    return hashlib.sha256(caminho.read_bytes()).hexdigest()


def lum(p) -> int:
    return (p[0] * 299 + p[1] * 587 + p[2] * 114) // 1000


# --------------------------------------------------------------------------
# autoridade


def carregar_pranchas() -> dict:
    manifesto = json.loads((PACOTE / "manifest.json").read_text(encoding="utf-8"))
    esperado = {e["file"]: e["sha256"] for e in manifesto["approved_images"]}
    pranchas = {}
    for nome in (P08, P10):
        caminho = PACOTE / "approved" / nome
        real = sha256(caminho)
        if real != esperado.get(nome):
            sys.exit(f"ERRO: SHA de {nome} não bate com o manifesto ({real})")
        img = Image.open(caminho)
        pranchas[nome] = {"img": img.convert("RGB"), "sha256": real,
                          "tamanho": img.size, "modo": img.mode}
    return pranchas


# --------------------------------------------------------------------------
# operações


def chave_fundo(img: Image.Image, fundo, limiar: int = 34) -> Image.Image:
    """Alfa binário: opaco onde a cor se afasta do fundo liso do painel."""
    rgba = img.convert("RGBA")
    px = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, _ = px[x, y]
            d = abs(r - fundo[0]) + abs(g - fundo[1]) + abs(b - fundo[2])
            px[x, y] = (r, g, b, 255 if d > limiar else 0)
    return limpar_salpicos(rgba)


def chave_escura(img: Image.Image, limite: int) -> Image.Image:
    """Silhuetas escuras sobre fundo mais claro: opaco onde lum < limite, e os
    buracos interiores (pintas de luar dentro da copa) fecham-se."""
    rgba = img.convert("RGBA")
    px = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, _ = px[x, y]
            px[x, y] = (r, g, b, 255 if lum((r, g, b)) < limite else 0)
    return limpar_salpicos(fechar_buracos(rgba))


def chave_matiz_magenta(img: Image.Image) -> Image.Image:
    """Cristais de corrupção sobre parede: guarda o magenta e o contorno escuro
    que lhe encosta (1 px), mais nada."""
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    mag = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b, _ = px[x, y]
            mag[y][x] = r > g + 60 and b > g + 50
    for y in range(h):
        for x in range(w):
            r, g, b, _ = px[x, y]
            ok = mag[y][x]
            if not ok and lum((r, g, b)) < 40:
                ok = any(mag[ny][nx] for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1))
                         if 0 <= nx < w and 0 <= ny < h)
            px[x, y] = (r, g, b, 255 if ok else 0)
    return limpar_salpicos(rgba, minimo=3)


def alfa_por_luz(img: Image.Image, escala: float = 0.9, piso: float = 0.0) -> Image.Image:
    """Névoa/faísca: o alfa é a luminância acima do mínimo da amostra (suave,
    é ar e não pedra). Abaixo de `piso` (fração da gama) é o fundo do painel e
    fica alfa 0 real. A cor fica a da prancha."""
    rgba = img.convert("RGBA")
    px = rgba.load()
    ls = [lum(px[x, y]) for y in range(rgba.height) for x in range(rgba.width)]
    lo, hi = min(ls), max(ls)
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, _ = px[x, y]
            t = (lum((r, g, b)) - lo) / max(1, hi - lo)
            t = max(0.0, (t - piso) / (1.0 - piso))
            px[x, y] = (r, g, b, int(round(255 * escala * t)))
    return rgba


def dados(img: Image.Image) -> list:
    """Píxeis em lista (o `getdata` do Pillow está obsoleto)."""
    f = getattr(img, "get_flattened_data", None)
    return list(f() if f else img.getdata())


def tirar_aureola(rgba: Image.Image) -> Image.Image:
    """O brilho das peças da 10 tinge o fundo do painel à volta delas (teal /
    navy escuro), e a chave de cor guarda-o como uma auréola opaca. Inunda a
    partir da borda transparente por píxeis escuros de matiz frio e apaga-os.
    O contorno preto NEUTRO das peças (r≈g≈b) não é frio, e fica."""
    w, h = rgba.size
    px = rgba.load()

    def aureola(p) -> bool:
        r, g, b, a = p
        if a == 0:
            return False
        l = lum((r, g, b))
        frio = l < 58 and (g + b) / 2 - r > 12
        # à volta das chamas o fundo tinge-se de castanho-oliva: escuro e com
        # cor (o contorno das peças é preto neutro, max-min pequeno)
        quente = l < 42 and max(r, g, b) - min(r, g, b) > 14
        return frio or quente

    fila = deque()
    visto = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0 and (x in (0, w - 1) or y in (0, h - 1)):
                visto[y][x] = True
                fila.append((x, y))
    while fila:
        x, y = fila.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not visto[ny][nx]:
                p = px[nx, ny]
                if p[3] == 0 or aureola(p):
                    visto[ny][nx] = True
                    px[nx, ny] = (p[0], p[1], p[2], 0)
                    fila.append((nx, ny))
    return limpar_salpicos(rgba, 10)


def fechar_buracos(rgba: Image.Image) -> Image.Image:
    w, h = rgba.size
    px = rgba.load()
    fora = [[False] * w for _ in range(h)]
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if px[x, y][3] == 0 and not fora[y][x]:
                fora[y][x] = True
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if px[x, y][3] == 0 and not fora[y][x]:
                fora[y][x] = True
                q.append((x, y))
    while q:
        x, y = q.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not fora[ny][nx] and px[nx, ny][3] == 0:
                fora[ny][nx] = True
                q.append((nx, ny))
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0 and not fora[y][x]:
                r, g, b, _ = px[x, y]
                px[x, y] = (r, g, b, 255)
    return rgba


def limpar_salpicos(rgba: Image.Image, minimo: int = 6) -> Image.Image:
    """Tira ilhas opacas minúsculas (ruído de compressão da prancha)."""
    w, h = rgba.size
    px = rgba.load()
    visto = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if px[x, y][3] and not visto[y][x]:
                comp = [(x, y)]
                visto[y][x] = True
                i = 0
                while i < len(comp):
                    cx, cy = comp[i]
                    i += 1
                    for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                        if 0 <= nx < w and 0 <= ny < h and not visto[ny][nx] and px[nx, ny][3]:
                            visto[ny][nx] = True
                            comp.append((nx, ny))
                if len(comp) < minimo:
                    for cx, cy in comp:
                        r, g, b, _ = px[cx, cy]
                        px[cx, cy] = (r, g, b, 0)
    return rgba


def estatisticas(pixels) -> tuple:
    n = max(1, len(pixels))
    med = [sum(p[c] for p in pixels) / n for c in range(3)]
    desv = [max(1.0, (sum((p[c] - med[c]) ** 2 for p in pixels) / n) ** 0.5) for c in range(3)]
    return med, desv


def graduar(rgba: Image.Image, origem, alvo, forca: float) -> Image.Image:
    """Transferência de média/desvio por canal (Reinhard em RGB), misturada com
    o original por `forca`. É a luz de dia da 10 a passar para o luar da 08."""
    (mo, do), (ma, da) = origem, alvo
    px = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            novo = []
            for c, v in enumerate((r, g, b)):
                t = (v - mo[c]) / do[c] * da[c] + ma[c]
                novo.append(int(round(max(0, min(255, v + (t - v) * forca)))))
            px[x, y] = (novo[0], novo[1], novo[2], a)
    return rgba


def continuo_x(img: Image.Image, faixa: int, suave: bool = False) -> Image.Image:
    """Mosaico horizontal sem costura: as primeiras `faixa` colunas misturam-se
    com as que vêm a seguir ao corte, e a imagem perde essas colunas no fim."""
    w, h = img.size
    src = img.load()
    out = Image.new("RGBA", (w - faixa, h))
    dst = out.load()
    for y in range(h):
        for x in range(w - faixa):
            p = src[x, y]
            if x < faixa:
                q = src[w - faixa + x, y]
                t = x / faixa
                p = tuple(int(round(q[c] * (1 - t) + p[c] * t)) for c in range(4))
            dst[x, y] = p
    return out if suave else binarizar(out)


def continuo_y(img: Image.Image, faixa: int) -> Image.Image:
    return continuo_x(img.transpose(Image.Transpose.TRANSPOSE), faixa).transpose(
        Image.Transpose.TRANSPOSE)


def binarizar(rgba: Image.Image) -> Image.Image:
    px = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255 if a >= 128 else 0)
    return rgba


def opaco(rgba: Image.Image) -> Image.Image:
    """O corpo do terreno não pode ter buracos: o que ficou transparente (a
    argamassa entre pedras, que é quase o fundo do painel) passa a opaco com
    a cor mais escura da própria peça."""
    px = rgba.load()
    escuros = sorted((px[x, y] for y in range(rgba.height) for x in range(rgba.width)
                      if px[x, y][3]), key=lum)
    arg = escuros[len(escuros) // 50] if escuros else (8, 10, 16, 255)
    for y in range(rgba.height):
        for x in range(rgba.width):
            if px[x, y][3] == 0:
                px[x, y] = (arg[0], arg[1], arg[2], 255)
    return rgba


def aparar(rgba: Image.Image, margem: int = 1) -> Image.Image:
    caixa = rgba.getbbox()
    if caixa is None:
        return rgba
    x0, y0, x1, y1 = caixa
    rec = rgba.crop((x0, y0, x1, y1))
    out = Image.new("RGBA", (rec.width + margem * 2, rec.height + margem * 2), (0, 0, 0, 0))
    out.paste(rec, (margem, margem))
    return out


def linha_superficie(rgba: Image.Image, fracao: float = 0.8) -> int:
    for y in range(rgba.height):
        n = sum(1 for x in range(rgba.width) if rgba.getpixel((x, y))[3])
        if n >= rgba.width * fracao:
            return y
    return 0


def ultima_linha_cheia(rgba: Image.Image, fracao: float = 0.8) -> int:
    for y in range(rgba.height - 1, -1, -1):
        n = sum(1 for x in range(rgba.width) if rgba.getpixel((x, y))[3])
        if n >= rgba.width * fracao:
            return y
    return rgba.height - 1


def primeira_coluna_cheia(rgba: Image.Image, fracao: float = 0.8) -> int:
    for x in range(rgba.width):
        n = sum(1 for y in range(rgba.height) if rgba.getpixel((x, y))[3])
        if n >= rgba.height * fracao:
            return x
    return 0


# --------------------------------------------------------------------------
# produção


def produzir() -> list[dict]:
    pr = carregar_pranchas()
    b08 = pr[P08]["img"]
    b10 = pr[P10]["img"]
    ativos: list[dict] = []

    # alvo da graduação: terreno da 08. origem: todo o material do tileset da 10.
    alvo = estatisticas([p for c in ALVO_TERRENO_08 for p in dados(b08.crop(c))])
    painel10 = chave_fundo(b10.crop((18, 96, 618, 310)), FUNDO_10)
    origem = estatisticas([p[:3] for p in dados(painel10) if p[3]])

    def gravar(img, id_, pasta, fonte, caixa, ops, uso, categoria, tileable=""):
        caminho = SAIDA / pasta / f"{id_}.png"
        caminho.parent.mkdir(parents=True, exist_ok=True)
        img.save(caminho, optimize=True)
        ativos.append({
            "id": id_, "ficheiro": f"{pasta}/{id_}.png", "categoria": categoria,
            "fonte": fonte, "fonte_sha256": pr[fonte]["sha256"],
            "caixa_na_prancha": list(caixa), "operacoes": ops,
            "tamanho": list(img.size), "modo": img.mode, "mosaico": tileable,
            "sha256": sha256(caminho), "uso": uso,
        })

    # ---------------- A. terreno (tileset "CHÃO" da prancha 10) ----------------
    caixa_chao = (21, 97, 107, 204)
    bloco = graduar(chave_fundo(b10.crop(caixa_chao), FUNDO_10), origem, alvo, 0.65)
    s = linha_superficie(bloco)           # 1.ª linha de pedra cheia sob o musgo
    fundo_bloco = ultima_linha_cheia(bloco)
    esq = primeira_coluna_cheia(bloco)
    miolo_x0, miolo_x1 = esq + 3, bloco.width - esq - 3
    ops_t = ["chave_fundo(0,27,36;34)", "graduar(10->08;0.65)"]

    topo = bloco.crop((miolo_x0, max(0, s - 8), miolo_x1, max(0, s - 8) + 32))
    gravar(continuo_x(topo, 10), "terreno_topo", "terreno", P10, caixa_chao,
           ops_t + [f"linhas {s-8}..{s+24} (superficie na linha 8)", "continuo_x(10)"],
           "Capa do terreno: musgo e 1.ª fiada de pedra; superfície de pouso na linha 8.",
           "terrain_top", "x")

    # O miolo sai do bloco "PAREDES" (pedra quase sem musgo). No "CHÃO" o musgo
    # cobre quase todas as pedras e, em mosaico, lia-se como papel de parede;
    # na 08 a pedra é azul-cinza e o musgo está sobretudo no topo.
    caixa_parede = (193, 101, 243, 201)
    parede = graduar(chave_fundo(b10.crop(caixa_parede), FUNDO_10), origem, alvo, 0.65)
    pe = primeira_coluna_cheia(parede)
    ps = linha_superficie(parede)
    pf = ultima_linha_cheia(parede)
    corpo = parede.crop((pe + 3, ps + 4, parede.width - pe - 3, pf - 4))
    gravar(opaco(continuo_y(continuo_x(corpo, 8), 8)), "terreno_corpo", "terreno", P10,
           caixa_parede, ops_t + ["miolo do bloco PAREDES", "continuo_x(8)", "continuo_y(8)",
                                  "argamassa opaca"],
           "Miolo de pedra do terreno, em mosaico nos dois eixos.", "terrain_body", "xy")

    lado = bloco.crop((max(0, esq - 10), s + 16, max(0, esq - 10) + 16, fundo_bloco - 8))
    gravar(continuo_y(lado, 8), "terreno_lado", "terreno", P10, caixa_chao,
           ops_t + ["contorno esquerdo na coluna 10", "continuo_y(8)"],
           "Remate lateral (esquerdo; o direito é o mesmo espelhado).", "terrain_edge", "y")

    base = bloco.crop((miolo_x0, fundo_bloco - 12, miolo_x1, fundo_bloco + 12))
    gravar(continuo_x(base, 10), "terreno_base", "terreno", P10, caixa_chao,
           ops_t + ["remate inferior", "continuo_x(10)"],
           "Remate inferior: as pedras arredondadas onde o bloco acaba.", "terrain_bottom", "x")

    # variante de capa com erva alta (faixa "CHÃO" de baixo)
    caixa_erva = (21, 266, 106, 308)
    erva = graduar(chave_fundo(b10.crop(caixa_erva), FUNDO_10), origem, alvo, 0.65)
    s2 = linha_superficie(erva, 0.7)
    topo_b = erva.crop((esq + 3, max(0, s2 - 8), erva.width - esq - 3, max(0, s2 - 8) + 32))
    gravar(continuo_x(topo_b, 10), "terreno_topo_erva", "terreno", P10, caixa_erva,
           ops_t + ["superficie na linha 8", "continuo_x(10)"],
           "Variante da capa com erva alta, para as plataformas não serem todas iguais.",
           "terrain_top", "x")

    # ---------------- B. props naturais (prancha 10) ----------------
    props10 = [
        # id, caixa, onde, categoria, forca da graduação, uso
        ("vinha_a", (439, 231, 465, 287), "pendurado", "vegetation", 0.65, "Vinha curta pendurada."),
        ("vinha_b", (468, 232, 494, 284), "pendurado", "vegetation", 0.65, "Vinha curta pendurada."),
        ("vinha_longa", (536, 599, 587, 689), "pendurado", "vegetation", 0.65, "Cortina de vinhas."),
        ("plantas", (158, 602, 274, 686), "chao", "vegetation", 0.65, "Tufo de plantas e flor."),
        ("cogumelos", (282, 620, 351, 689), "chao", "bioluminescence", 0.45,
         "Cogumelos com o chapéu aceso (acento quente)."),
        ("rocha", (356, 604, 436, 685), "chao", "rocks", 0.65, "Rocha com musgo."),
        ("raizes", (442, 605, 526, 688), "chao", "roots", 0.65, "Toco e raízes monumentais."),
        ("planta_luminosa", (594, 602, 658, 686), "chao", "bioluminescence", 0.35,
         "Planta luminosa violeta (bioluminescência controlada)."),
        ("lanterna", (666, 262, 709, 316), "chao", "lanterns", 0.3, "Lanterna de ferro, luz quente."),
        ("tocha", (632, 241, 673, 316), "chao", "lanterns", 0.3, "Poste com chama, luz quente."),
        ("ruina", (637, 104, 739, 215), "fundo", "ruins", 0.65, "Ruína de pedra (plano de fundo)."),
        ("cascata", (864, 98, 948, 215), "fundo", "waterfalls", 0.5, "Cascata entre rochedos."),
    ]
    for id_, caixa, onde, cat, forca, uso in props10:
        img = tirar_aureola(chave_fundo(b10.crop(caixa), FUNDO_10))
        img = graduar(img, origem, alvo, forca)
        gravar(aparar(img), id_, "props", P10, caixa,
               ["chave_fundo(0,27,36;34)", "tirar_aureola", f"graduar(10->08;{forca})", "aparar"],
               uso + f" [onde={onde}]", cat)

    # ---------------- E. corrupção (exemplo em jogo da 08) ----------------
    cristais = [
        ("cristal_corrupcao_a", (16, 737, 67, 773)),
        ("cristal_corrupcao_b", (471, 779, 543, 818)),
        ("cristal_corrupcao_c", (421, 900, 454, 930)),
        ("cristal_corrupcao_d", (140, 820, 167, 845)),
    ]
    for id_, caixa in cristais:
        gravar(aparar(chave_matiz_magenta(b08.crop(caixa))), id_, "corrupcao", P08, caixa,
               ["chave_matiz_magenta(+contorno 1px)", "aparar"],
               "Cristal de corrupção magenta/violeta/preto. [onde=chao]", "corruption")

    # faísca de corrupção: a mais brilhante do painel "Partículas de Corrupção"
    painel = b08.crop((1165, 721, 1267, 782))
    melhor = max(((x, y) for y in range(painel.height) for x in range(painel.width)),
                 key=lambda p: lum(painel.getpixel(p)))
    cx, cy = melhor[0] + 1165, melhor[1] + 721
    caixa_f = (cx - 5, cy - 5, cx + 6, cy + 6)
    gravar(alfa_por_luz(b08.crop(caixa_f), 1.0, 0.3), "faisca_corrupcao", "corrupcao", P08,
           caixa_f, ["alfa_por_luz(1.0; piso 0.3)"], "Textura das partículas de corrupção.",
           "corruption_particle")

    # ---------------- F. profundidade (elementos de parallax da 08) ----------------
    brilhantes = [
        ("fundo_montanhas", (1117, 402, 1308, 446), "Serra distante (camada 3)."),
        ("fundo_arco_ruina", (1311, 402, 1386, 489), "Arco de ruína distante (camada 2/3)."),
        ("fundo_colunas_cascata", (1387, 416, 1437, 489), "Colunas e fios de água (camada 3)."),
        ("fundo_cascata", (1434, 403, 1510, 489), "Cascata grande com espuma (camada 3)."),
    ]
    for id_, caixa, uso in brilhantes:
        img = limpar_salpicos(chave_fundo(b08.crop(caixa), FUNDO_08_PECAS, 24), 40)
        gravar(aparar(img), id_, "fundo", P08, caixa,
               ["chave_fundo(7,16,25;24)", "limpar_salpicos(40)", "aparar"], uso,
               "background_element")
    escuras = [
        ("fundo_arvores_par", (1114, 449, 1312, 584), "Par de árvores em silhueta (camada 2)."),
        ("fundo_arvore_a", (1307, 502, 1413, 584), "Árvore em silhueta (camada 2)."),
        ("fundo_arvore_b", (1414, 497, 1514, 584), "Árvore em silhueta (camada 2)."),
    ]
    for id_, caixa, uso in escuras:
        gravar(aparar(chave_escura(b08.crop(caixa), 9)), id_, "fundo", P08, caixa,
               ["chave_escura(lum<9)", "fechar_buracos", "aparar"], uso, "background_element")

    # camada 1 da 08 (vegetação de primeiro plano), a banda inteira
    caixa_frente = (147, 597, 1089, 661)   # a linha 594-596 é o filete da moldura
    frente = chave_escura(b08.crop(caixa_frente), 13)
    gravar(frente, "frente_vegetacao", "fundo", P08, caixa_frente,
           ["chave_escura(lum<13)", "fechar_buracos"],
           "Silhuetas de vegetação em primeiro plano (camada 1 da 08).", "foreground")

    # ---------------- G. atmosfera ----------------
    caixa_nevoa = (1053, 707, 1153, 781)
    # a névoa não é pixel-art dura: mosaico com o alfa suave (sem binarizar)
    gravar(continuo_x(alfa_por_luz(b08.crop(caixa_nevoa), 0.85, 0.12), 24, suave=True),
           "nevoa", "atmosfera", P08, caixa_nevoa,
           ["alfa_por_luz(0.85; piso 0.12)", "continuo_x(24, alfa suave)"],
           "Névoa (foreground/midground) em mosaico horizontal.", "fog", "x")

    # tintas por nível: as 4 "variantes de cenário (mood)" da 08
    moods = {
        "entrada": (1142, 96, 1510, 153),     # níveis 1-2
        "ruinas": (1142, 160, 1510, 216),     # nível 3
        "cascatas": (1142, 222, 1510, 279),   # nível 4
        "coracao": (1142, 285, 1510, 341),    # nível 5
    }
    pan = estatisticas(dados(b08.crop((18, 97, 970, 344))))[0]
    tintas = {}
    for nome, caixa in moods.items():
        m = estatisticas(dados(b08.crop(caixa)))[0]
        # razão contra o panorama, contida: é uma gradação, não uma recoloração
        tintas[nome] = [round(max(0.85, min(1.18, (m[c] + 8) / (pan[c] + 8))), 3) for c in range(3)]

    manifesto = {
        "kit_id": "region_01_floresta_corrompida_9c",
        "execution": "9C",
        "autoridade": {
            "regiao": P08, "sha256": pr[P08]["sha256"],
            "tamanho": list(pr[P08]["tamanho"]), "modo": pr[P08]["modo"],
        },
        "referencia_estrutural": {
            "ficheiro": P10, "sha256": pr[P10]["sha256"],
            "nota": "tileset e elementos soltos; a luz de dia e o nome 'Floresta Sagrada' "
                    "não são canónicos -- tudo o que vem daqui é graduado para a noite da 08",
        },
        "graduacao_10_para_08": {
            "origem_media": [round(v, 2) for v in origem[0]],
            "origem_desvio": [round(v, 2) for v in origem[1]],
            "alvo_media": [round(v, 2) for v in alvo[0]],
            "alvo_desvio": [round(v, 2) for v in alvo[1]],
            "amostras_alvo_08": ALVO_TERRENO_08,
        },
        "tintas_por_mood_08": tintas,
        "ativos": ativos,
    }
    (SAIDA / "kit_9c_manifest.json").write_text(
        json.dumps(manifesto, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return ativos


# --------------------------------------------------------------------------
# validação técnica (ambiente: sem baseline/pivot de personagem)


def validar() -> int:
    manifesto = json.loads((SAIDA / "kit_9c_manifest.json").read_text(encoding="utf-8"))
    falhas = 0
    for a in manifesto["ativos"]:
        caminho = SAIDA / a["ficheiro"]
        erros = []
        try:
            img = Image.open(caminho)
            img.load()
        except Exception as e:  # noqa: BLE001
            print(f"FAIL {a['id']}: ilegível ({e})")
            falhas += 1
            continue
        if img.format != "PNG":
            erros.append("não é PNG")
        if img.mode != "RGBA":
            erros.append(f"modo {img.mode} (esperado RGBA)")
        if sha256(caminho) != a["sha256"]:
            erros.append("SHA diferente do manifesto")
        if list(img.size) != a["tamanho"]:
            erros.append("tamanho diferente do manifesto")
        alfa = img.getchannel("A")
        lo, hi = alfa.getextrema()
        tileable = a.get("mosaico", "")
        if a["id"] == "terreno_corpo":
            if lo != 255:
                erros.append("corpo com buracos")
        elif not (lo == 0 and hi >= 200):
            erros.append(f"alfa sem transparência real ({lo}..{hi})")
        # recorte cortado: píxeis opacos a encostar à borda (só peças soltas)
        if not tileable and a["categoria"] not in ("foreground",):
            w, h = img.size
            borda = [alfa.getpixel((x, y)) for x in range(w) for y in (0, h - 1)] + \
                    [alfa.getpixel((x, y)) for y in range(h) for x in (0, w - 1)]
            if sum(1 for v in borda if v > 0) > len(borda) * 0.02:
                erros.append("CLIPPED (opaco na borda)")
        # xadrez cozido: 2 cinzentos neutros a alternar em blocos regulares
        px = img.convert("RGB")
        cinzas = sum(1 for p in dados(px) if abs(p[0] - p[1]) < 4 and abs(p[1] - p[2]) < 4
                     and p[0] > 150)
        if cinzas > img.width * img.height * 0.15:
            erros.append("SUSPEITA de xadrez cozido")
        # separadores: uma linha opaca inteira de cor lisa
        for y in range(img.height):
            linha = [px.getpixel((x, y)) for x in range(img.width)]
            if img.width > 24 and len(set(linha)) == 1 and alfa.getpixel((0, y)) == 255:
                erros.append(f"linha lisa na y={y} (separador?)")
                break
        estado = "FAIL" if erros else "PASS"
        falhas += bool(erros)
        print(f"{estado} {a['id']:24s} {img.size[0]:4d}x{img.size[1]:<4d} {img.mode} "
              f"{'; '.join(erros)}")
    print(f"\n{len(manifesto['ativos'])} peças, {falhas} FAIL")
    return falhas


def prancha_revisao() -> None:
    manifesto = json.loads((SAIDA / "kit_9c_manifest.json").read_text(encoding="utf-8"))
    esc = 3
    cel = []
    for a in manifesto["ativos"]:
        img = Image.open(SAIDA / a["ficheiro"]).convert("RGBA")
        if img.width * esc > 900:
            img = img.resize((img.width, img.height), Image.NEAREST)
            e = 1
        else:
            e = esc
        cel.append((a["id"], img.resize((img.width * e, img.height * e), Image.NEAREST)))
    largura = 1400
    x = y = 10
    linha_h = 0
    pos = []
    for nome, img in cel:
        if x + img.width + 10 > largura:
            x = 10
            y += linha_h + 30
            linha_h = 0
        pos.append((nome, img, x, y))
        x += img.width + 20
        linha_h = max(linha_h, img.height)
    folha = Image.new("RGBA", (largura, y + linha_h + 40), (40, 44, 56, 255))
    d = ImageDraw.Draw(folha)
    for nome, img, px_, py_ in pos:
        folha.alpha_composite(img, (px_, py_ + 14))
        d.text((px_, py_), nome, fill=(230, 230, 240, 255))
    REVISAO.mkdir(parents=True, exist_ok=True)
    folha.save(REVISAO / "kit_9c_contacto.png")
    print("prancha:", REVISAO / "kit_9c_contacto.png")


if __name__ == "__main__":
    if "--validar" not in sys.argv:
        produzir()
        prancha_revisao()
    sys.exit(1 if validar() else 0)
