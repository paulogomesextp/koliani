"""Execution 9D+9E -- arte de produção dos inimigos, guardiões, crias e do
Coração Putrefacto da Região I, derivada da autoridade visual aprovada pelo
Game Master (prancha `region1_enemies_boss_visual_authority_v1_0.png`).

Só operações técnicas sobre a autoridade (nada é repintado):
  1. recorte do painel de cada entidade (caixas fixas, abaixo);
  2. máscara alfa por segmentação determinística: o fundo de apresentação
     (xadrez desfocado nos comuns/crias, cinzento liso nos guardiões, névoa
     magenta no boss) é inundado a partir da borda do recorte; buracos
     fechados com assinatura de fundo também saem; ilhas minúsculas saem;
  3. redução BOX (alfa pré-multiplicado) ao tamanho de ecrã do contrato, alfa
     binarizado 0/255;
  4. estados derivados só por píxel inteiro: translação (idle/run/hit),
     dissolução por matriz de Bayer (dead) e, no boss, ganho da corrupção
     magenta (pulso/fase 2 -- "brighter core", secção 13 do briefing).

Uso (a partir da raiz do repo):
    python tools/produzir_inimigos_regiao1.py            # produz + manifesto
    python tools/produzir_inimigos_regiao1.py --previa DIR  # + folhas de prova

Sem numpy: só Pillow, como o resto das ferramentas do repo.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw

RAIZ = Path(__file__).resolve().parent.parent
AUTORIDADE = RAIZ / "work/production_art_gate/9D1_game_master_approved/region1_enemies_boss_visual_authority_v1_0.png"
AUTORIDADE_SHA = "8ebf8ecd13e8d7e7d803acfcccf3361a35cb77ff9ad6dd1d01c79b8b24ebb2fd"
DIR = RAIZ / "assets/art/regions/region_01_forest/enemies/production"
MANIFESTO = DIR / "enemy_production_manifest.json"
RES = "res://assets/art/regions/region_01_forest/enemies/production"

## Contratos de frame. O comum passou de 96 para 128 de largura: o besouro e a
## gosma da autoridade são mais largos que altos e, a 48 px de corpo, medem
## 94-96 px -- em 96 tocavam a borda. O guardião e o boss seguem a regra que o
## runtime já aplica (`ChefeBase`: altura 100, teto de largura 110), para o
## `_normalizar_escala` dar k = 1 e não reamostrar a arte no ecrã.
CONTRATOS = {
    "comum":    {"canvas": (128, 96), "baseline_y": 88, "pivot": (64, 88), "altura": 48, "largura_max": None},
    "guardiao": {"canvas": (192, 192), "baseline_y": 180, "pivot": (96, 180), "altura": 100, "largura_max": 110},
    "boss":     {"canvas": (192, 192), "baseline_y": 180, "pivot": (96, 180), "altura": 100, "largura_max": 110},
}

## Caixas na autoridade (x0, y0, x1, y1), por dentro das molduras dos painéis.
## `fundo`: "xadrez" (cinzentos desfocados), "liso" (cinzento-escuro plano) ou
## "nevoa" (boss). `limiar` = (croma máx., gradiente máx.) de um píxel de fundo.
ENTIDADES = {
    "goblin":           {"tipo": "comum", "caixa": (27, 183, 280, 339), "fundo": "xadrez", "limiar": (14, 10),
                         "cena": "res://scenes/actors/DemonioBase.tscn", "autoridade_n": 1},
    "mushroom":         {"tipo": "comum", "caixa": (290, 183, 606, 339), "fundo": "xadrez", "limiar": (14, 10),
                         "cena": "res://scenes/actors/DemonioBase.tscn", "autoridade_n": 2},
    "gosma":            {"tipo": "comum", "caixa": (616, 183, 865, 339), "fundo": "xadrez", "limiar": (14, 10),
                         "cena": "res://scenes/actors/DemonioBase.tscn", "autoridade_n": 3},
    "besouro":          {"tipo": "comum", "caixa": (874, 183, 1208, 339), "fundo": "xadrez", "limiar": (14, 10),
                         "cena": "res://scenes/actors/DemonioBase.tscn", "autoridade_n": 4},
    "lodo":             {"tipo": "comum", "caixa": (1218, 183, 1510, 339), "fundo": "xadrez", "limiar": (14, 10),
                         "cena": "res://scenes/actors/DemonioBase.tscn", "autoridade_n": 5},
    "ghorak":           {"tipo": "guardiao", "caixa": (27, 452, 373, 630), "fundo": "liso", "limiar": (10, 6),
                         "cena": "res://scenes/actors/ChefeGhorak.tscn", "autoridade_n": 6},
    "morvanna":         {"tipo": "guardiao", "caixa": (383, 450, 708, 630), "fundo": "liso", "limiar": (10, 6),
                         "cena": "res://scenes/actors/ChefeMorvanna.tscn", "autoridade_n": 7},
    "rainha_aracnidea": {"tipo": "guardiao", "caixa": (718, 450, 1104, 630), "fundo": "liso", "limiar": (10, 6),
                         "cena": "res://scenes/actors/ChefeRainhaAracnidea.tscn", "autoridade_n": 8},
    "entrevane":        {"tipo": "guardiao", "caixa": (1206, 424, 1511, 630), "fundo": "liso", "limiar": (10, 6),
                         "linhas_fundo": [444, 445, 446, 447, 448],
                         "cena": "res://scenes/actors/ChefeEntrevane.tscn", "autoridade_n": 9},
    "clone_morvanna":   {"tipo": "comum", "caixa": (27, 745, 264, 890), "fundo": "xadrez", "limiar": (14, 10),
                         "cena": "res://scenes/actors/DemonioBase.tscn", "autoridade_n": 10},
    "cria_rainha":      {"tipo": "comum", "caixa": (274, 745, 511, 890), "fundo": "xadrez", "limiar": (14, 10),
                         "cena": "res://scenes/actors/DemonioBase.tscn", "autoridade_n": 11},
}

## O boss (item 12) NÃO sai daqui. Está pintado DENTRO da arena: raízes escuras
## sobre névoa magenta e sombra roxa, sem fundo de apresentação. Três tentativas
## de máscara determinística (névoa lisa: 99 % opaco = cenário incluído; casca
## escura: idem; casca neutra + núcleo: o contorno do coração passa a ser uma
## elipse geométrica e os troncos, tingidos de roxo, perdem-se -- lê-se como
## "coração a flutuar com gravetos", o que o briefing proíbe). Derivação fiel
## tecnicamente impossível = condição C da política: fica o legado até o Game
## Master entregar o Coração isolado (alfa real ou fundo liso).
BOSS_BLOQUEADO = {
    "tipo": "boss", "status": "PRODUCTION_ASSET_MISSING", "autoridade_item": 12,
    "cena": "res://scenes/actors/ChefeCoracaoPutrefacto.tscn",
    "classificacao": "D",
    "motivo": ("APPROVED DESIGN / PRODUCTION ASSET MISSING: o Coração está pintado dentro da arena, sem "
               "fundo separável; as máscaras determinísticas ou incluem o cenário ou inventam o contorno "
               "(elipse) e perdem os troncos. Precisa de uma fonte isolada do Coração (alfa real ou fundo liso)."),
    "tentativas_mascara": ["nevoa_magenta_lisa: 99% opaco", "casca_escura: 99% opaco",
                           "casca_neutra+elipse_nucleo: 35% opaco, contorno inventado, troncos perdidos"],
    "animacoes": {},
}

## Estados derivados (só píxel inteiro). (fps, ciclo, deslocamentos (dx, dy)).
ESTADOS_COMUM = {
    "idle": (5.0, True, [(0, 0), (0, 0), (0, -1), (0, -1)]),
    "run":  (10.0, True, [(0, 0), (0, -1), (0, -2), (0, -1), (0, 0), (0, -1)]),
    "hit":  (12.0, False, [(-3, 0), (-2, 0), (-1, 0)]),
}
DEAD_PASSOS = 6          # dissolução: 0 %, 17 %, ..., 83 % dos píxeis retirados
DEAD_PASSOS_BOSS = 10
GANHOS_BOSS = {"idle": [1.0, 1.1, 1.2, 1.1], "idle_f2": [1.3, 1.45, 1.6, 1.45]}

BAYER4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def sha256(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def _lum(p) -> float:
    return (p[0] * 3 + p[1] * 6 + p[2]) / 10.0


## --- segmentação -----------------------------------------------------------

def _e_fundo(p, g, fundo: str, limiar, ref_lum: float) -> bool:
    croma = max(p[:3]) - min(p[:3])
    # sombra/aura desfocada da prancha (a aura do orbe da Morvanna, a sombra
    # da gosma): escura, MUITO lisa e pouco tingida -- é fundo em qualquer painel
    if fundo != "nevoa" and g <= 5 and _lum(p) <= 58 and croma <= 26:
        return True
    if fundo == "xadrez":
        return croma <= limiar[0] and g <= limiar[1]
    if fundo == "liso":
        # o painel escurece em vinheta junto às criaturas (lum 10-16 perto da
        # Entrevane, contra ~31 na borda): conta tudo o que é liso, sem cor e
        # não mais claro que o painel
        return croma <= limiar[0] and g <= limiar[1] and _lum(p) <= ref_lum + 14
    # névoa do boss: magenta/roxo claro e liso, ou o fumo escuro liso do chão
    r, gr, b = p[:3]
    magenta = r - gr >= 30 and b - gr >= 10 and _lum(p) >= 48 and g <= limiar[1]
    return magenta


def segmentar(im: Image.Image, e: dict) -> Image.Image:
    x0, y0, x1, y1 = e["caixa"]
    c = im.crop((x0, y0, x1, y1)).convert("RGB")
    W, H = c.size
    px = c.load()
    lum = [[_lum(px[x, y]) for x in range(W)] for y in range(H)]
    grad = [[0.0] * W for _ in range(H)]
    for y in range(H):
        for x in range(W):
            g = 0.0
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                u, v = x + dx, y + dy
                if 0 <= u < W and 0 <= v < H:
                    g = max(g, abs(lum[y][x] - lum[v][u]))
            grad[y][x] = g
    borda = sorted([lum[0][x] for x in range(W)] + [lum[H - 1][x] for x in range(W)])
    ref = borda[len(borda) // 2]
    cand = [[_e_fundo(px[x, y], grad[y][x], e["fundo"], e["limiar"], ref) for x in range(W)] for y in range(H)]
    # linhas da moldura do cabeçalho que atravessam o recorte (y da autoridade)
    for ya in e.get("linhas_fundo", []):
        y = ya - y0
        if 0 <= y < H:
            for x in range(W):
                p = px[x, y]
                if max(p) - min(p) <= 16:
                    cand[y][x] = True

    fundo = [[False] * W for _ in range(H)]
    dq: deque = deque()
    for x in range(W):
        for y in (0, H - 1):
            if cand[y][x] and not fundo[y][x]:
                fundo[y][x] = True; dq.append((x, y))
    for y in range(H):
        for x in (0, W - 1):
            if cand[y][x] and not fundo[y][x]:
                fundo[y][x] = True; dq.append((x, y))
    while dq:
        x, y = dq.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            u, v = x + dx, y + dy
            if 0 <= u < W and 0 <= v < H and cand[v][u] and not fundo[v][u]:
                fundo[v][u] = True; dq.append((u, v))

    # buracos fechados com assinatura de fundo (vão entre pernas/patas): saem
    # se forem grandes o bastante para não serem textura do próprio corpo
    visto = [[False] * W for _ in range(H)]
    for y in range(H):
        for x in range(W):
            if cand[y][x] and not fundo[y][x] and not visto[y][x]:
                comp = []; dq.append((x, y)); visto[y][x] = True
                while dq:
                    a, b = dq.popleft(); comp.append((a, b))
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        u, v = a + dx, b + dy
                        if 0 <= u < W and 0 <= v < H and cand[v][u] and not fundo[v][u] and not visto[v][u]:
                            visto[v][u] = True; dq.append((u, v))
                media = sum(lum[b][a] for a, b in comp) / len(comp)
                claro = media >= 50 if e["fundo"] == "xadrez" else media <= 60
                if len(comp) >= 30 and claro:
                    for a, b in comp:
                        fundo[b][a] = True

    # descasca o halo: a sombra desfocada que a prancha pôs à volta dos bichos
    # é cinzenta, escura e LISA; o contorno verdadeiro também é escuro, mas tem
    # vizinhos de cor (o corpo) -- esse não sai. O anel cinzento claro onde o
    # halo encontra o xadrez sai sempre (é o que fechava o halo da cria). Só
    # píxeis da borda, 12 passes.
    frente = [[not fundo[y][x] for x in range(W)] for y in range(H)]
    for _ in range(12):
        tirar = []
        for y in range(H):
            for x in range(W):
                if not frente[y][x]:
                    continue
                p = px[x, y]
                franja = max(p) - min(p) <= 8 and 70 <= lum[y][x] < 200  # anel cinzento claro do xadrez
                if not franja and (max(p) - min(p) > 12 or lum[y][x] >= 70):
                    continue
                borda_ = False; dif = 0.0
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    u, v = x + dx, y + dy
                    if not (0 <= u < W and 0 <= v < H) or not frente[v][u]:
                        borda_ = True
                    else:
                        q = px[u, v]
                        dif = max(dif, abs(lum[y][x] - lum[v][u]), float(max(q) - min(q)))
                if borda_ and (dif <= 12 or franja):
                    tirar.append((x, y))
        if not tirar:
            break
        for x, y in tirar:
            frente[y][x] = False

    # componentes do corpo (8-conexas): fica a maior + ilhas perto dela
    comps = []
    visto = [[False] * W for _ in range(H)]
    for y in range(H):
        for x in range(W):
            if frente[y][x] and not visto[y][x]:
                comp = []; dq.append((x, y)); visto[y][x] = True
                while dq:
                    a, b = dq.popleft(); comp.append((a, b))
                    for dx in (-1, 0, 1):
                        for dy in (-1, 0, 1):
                            u, v = a + dx, b + dy
                            if 0 <= u < W and 0 <= v < H and frente[v][u] and not visto[v][u]:
                                visto[v][u] = True; dq.append((u, v))
                comps.append(comp)
    comps.sort(key=len, reverse=True)
    maior = comps[0]
    bx0 = min(a for a, _ in maior); bx1 = max(a for a, _ in maior)
    by0 = min(b for _, b in maior); by1 = max(b for _, b in maior)
    manter = set()
    for i, comp in enumerate(comps):
        if i == 0:
            manter.update(comp); continue
        if len(comp) < 12:
            continue
        cx0 = min(a for a, _ in comp); cx1 = max(a for a, _ in comp)
        cy0 = min(b for _, b in comp); cy1 = max(b for _, b in comp)
        perto = cx1 >= bx0 - 10 and cx0 <= bx1 + 10 and cy1 >= by0 - 10 and cy0 <= by1 + 10
        if perto:
            manter.update(comp)
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    o = out.load()
    for a, b in manter:
        o[a, b] = px[a, b] + (255,)
    return out


## --- normalização ao contrato --------------------------------------------

def _binarizar(im: Image.Image) -> Image.Image:
    im = im.copy(); p = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = p[x, y]
            p[x, y] = (r, g, b, 255) if a >= 110 else (0, 0, 0, 0)
    return im


def normalizar(fonte: Image.Image, contrato: dict) -> tuple[Image.Image, float]:
    corpo = fonte.crop(fonte.getchannel("A").getbbox())
    w, h = corpo.size
    alvo_h = contrato["altura"]
    if contrato["largura_max"]:
        k = min(alvo_h / h, contrato["largura_max"] / w)
    else:
        k = alvo_h / h
    alvo = (max(1, round(w * k)), max(1, round(h * k)))
    # medida da silhueta binarizada: ajusta até ao píxel (o runtime reescala
    # por `used_rect` e um píxel a mais já o obrigava a reamostrar)
    for _ in range(4):
        red = _binarizar(corpo.resize(alvo, Image.BOX))
        bb = red.getchannel("A").getbbox()
        uw, uh = bb[2] - bb[0], bb[3] - bb[1]
        quer_h = round(h * k); quer_w = round(w * k)
        if uh == quer_h and (not contrato["largura_max"] or uw <= contrato["largura_max"]):
            break
        alvo = (max(1, alvo[0] + (quer_w - uw)), max(1, alvo[1] + (quer_h - uh)))
    red = red.crop(red.getchannel("A").getbbox())
    cw, ch = contrato["canvas"]
    tela = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    ox = contrato["pivot"][0] - red.width // 2
    oy = contrato["baseline_y"] + 1 - red.height
    tela.alpha_composite(red, (ox, oy))
    return tela, k


def deslocar(im: Image.Image, dx: int, dy: int) -> Image.Image:
    t = Image.new("RGBA", im.size, (0, 0, 0, 0))
    t.alpha_composite(im, (dx, dy))
    return t


def dissolver(im: Image.Image, fracao: float) -> Image.Image:
    t = im.copy(); p = t.load()
    corte = fracao * 16.0
    for y in range(t.height):
        for x in range(t.width):
            if p[x, y][3] and BAYER4[y % 4][x % 4] < corte:
                p[x, y] = (0, 0, 0, 0)
    return t


def ganho_corrupcao(im: Image.Image, ganho: float) -> Image.Image:
    """Aviva só os píxeis de corrupção (magenta/violeta) -- o pulso do núcleo."""
    if ganho == 1.0:
        return im.copy()
    t = im.copy(); p = t.load()
    for y in range(t.height):
        for x in range(t.width):
            r, g, b, a = p[x, y]
            if a and r - g >= 40 and b - g >= 20:
                p[x, y] = (min(255, round(r * ganho)), min(255, round(g * ganho)), min(255, round(b * ganho)), a)
    return t


def nucleo_vfx(im: Image.Image) -> tuple[Image.Image, tuple[int, int]]:
    """VFX separado do núcleo: o clarão do centro do coração, isolado por
    luminância (só os píxeis claros de corrupção)."""
    x0, y0, x1, y1 = 1040, 796, 1100, 852
    c = im.crop((x0, y0, x1, y1)).convert("RGBA"); p = c.load()
    for y in range(c.height):
        for x in range(c.width):
            r, g, b, a = p[x, y]
            p[x, y] = (r, g, b, 255) if (_lum((r, g, b)) >= 120 and r - g >= 25) else (0, 0, 0, 0)
    return c, (x0, y0)


## --- produção ---------------------------------------------------------------

def produzir(previa: Path | None) -> dict:
    if sha256(AUTORIDADE) != AUTORIDADE_SHA:
        raise SystemExit("autoridade com SHA diferente do aprovado -- nada produzido")
    im = Image.open(AUTORIDADE).convert("RGBA")
    entradas: dict = {}
    folhas = []
    for eid, e in ENTIDADES.items():
        contrato = CONTRATOS[e["tipo"]]
        fonte = segmentar(im, e)
        base, k = normalizar(fonte, contrato)
        pasta = DIR / eid / "frames"
        pasta.mkdir(parents=True, exist_ok=True)
        for velho in pasta.glob("*.png"):
            velho.unlink()
        anims: dict = {}

        def gravar(nome: str, fps: float, ciclo: bool, imgs: list[Image.Image]) -> None:
            fr = []
            for i, fimg in enumerate(imgs):
                arq = pasta / f"{nome}_{i + 1:02d}.png"
                fimg.save(arq, format="PNG", optimize=False, compress_level=9)
                fr.append({"ficheiro": f"{eid}/frames/{arq.name}", "sha256": sha256(arq),
                           "dimensoes": list(fimg.size)})
            anims[nome] = {"fps": fps, "ciclo": ciclo, "frames": fr}

        if True:
            for nome, (fps, ciclo, desl) in ESTADOS_COMUM.items():
                gravar(nome, fps, ciclo, [deslocar(base, dx, dy) for dx, dy in desl])
            gravar("dead", 10.0, False, [dissolver(base, i / DEAD_PASSOS) for i in range(DEAD_PASSOS)])

        bb = base.getchannel("A").getbbox()
        entrada = {
            "tipo": e["tipo"], "status": "PRODUCTION_INTEGRATED", "cena": e["cena"],
            "autoridade_item": e["autoridade_n"],
            "proveniencia": {"caixa_autoridade": list(e["caixa"]), "fundo_removido": e["fundo"],
                             "limiar_croma_gradiente": list(e["limiar"]),
                             "escala_reducao": round(k, 6), "classificacao": "B"},
            "contrato": {"canvas": list(contrato["canvas"]), "baseline_y": contrato["baseline_y"],
                         "pivot": list(contrato["pivot"]), "corpo_px": [bb[2] - bb[0], bb[3] - bb[1]]},
            "animacoes": anims,
        }
        entradas[eid] = entrada
        folhas.append((eid, fonte, base))
        print(f"{eid:20s} corpo {bb[2]-bb[0]}x{bb[3]-bb[1]}  k={k:.4f}")

    if previa:
        previa.mkdir(parents=True, exist_ok=True)
        for eid, fonte, base in folhas:
            prev = Image.new("RGBA", fonte.size, (0, 190, 90, 255)); prev.alpha_composite(fonte)
            prev.resize((fonte.width * 2, fonte.height * 2), Image.NEAREST).save(previa / f"{eid}_mascara.png")
            # frame final a 4x: em verde (prova do alfa) e no tom da floresta 9C
            bb = base.getchannel("A").getbbox()
            corpo = base.crop((bb[0] - 2, bb[1] - 2, bb[2] + 2, bb[3] + 2))
            par = Image.new("RGBA", (corpo.width * 2 + 4, corpo.height), (0, 190, 90, 255))
            par.paste((24, 20, 30, 255), (corpo.width + 4, 0, par.width, par.height))
            par.alpha_composite(corpo, (0, 0)); par.alpha_composite(corpo, (corpo.width + 4, 0))
            par.resize((par.width * 4, par.height * 4), Image.NEAREST).save(previa / f"{eid}_frame4x.png")
        _folha(previa / "folha_producao_9d_9e.png")
    return entradas


def _folha(saida: Path) -> None:
    """Folha de prova: idle/run/hit/dead de cada entidade, a 3x, sobre o tom
    do chão da floresta."""
    linhas = []
    for eid in ENTIDADES:
        pasta = DIR / eid / "frames"
        linha = [Image.open(p).convert("RGBA") for p in sorted(pasta.glob("*.png"))]
        linhas.append((eid, linha))
    esc = 2
    cw = max(i.width for _, l in linhas for i in l) * esc + 4
    ch = max(i.height for _, l in linhas for i in l) * esc + 16
    cols = max(len(l) for _, l in linhas)
    folha = Image.new("RGBA", (cols * cw, len(linhas) * ch), (22, 18, 28, 255))
    d = ImageDraw.Draw(folha)
    for r, (eid, linha) in enumerate(linhas):
        d.text((2, r * ch + 2), eid, fill=(240, 240, 240, 255))
        for c, im in enumerate(linha):
            folha.alpha_composite(im.resize((im.width * esc, im.height * esc), Image.NEAREST), (c * cw + 2, r * ch + 14))
    folha.save(saida)


def gravar_manifesto(entradas: dict) -> None:
    man = json.loads(MANIFESTO.read_text(encoding="utf-8"))
    velho = man.get("inimigos", {})
    man["execution"] = "9D+9E"
    man["estado_geral"] = "PRODUCTION_INTEGRATED"
    man["nota"] = ("Arte derivada da autoridade visual aprovada pelo Game Master (itens 1-12) por "
                   "tools/produzir_inimigos_regiao1.py: recorte, remoção determinística do fundo de "
                   "apresentação, redução BOX ao contrato, alfa 0/255. Estados derivados só por píxel "
                   "inteiro (translação, dissolução Bayer; no boss, ganho da corrupção). A autoridade "
                   "tem UMA pose por entidade: ciclos articulados (pernas a andar) seriam poses novas "
                   "-- APPROVED DESIGN / PRODUCTION ASSET MISSING, não se inventaram.")
    man["autoridade"] = {
        "inimigos_boss": "work/production_art_gate/9D1_game_master_approved/region1_enemies_boss_visual_authority_v1_0.png",
        "inimigos_boss_sha256": AUTORIDADE_SHA, "inimigos_boss_dimensoes": [1536, 1024], "inimigos_boss_modo": "RGBA",
        "aprovacao": "GAME MASTER APPROVED (Paulo, 11 set 2026)",
        "regiao": "Koliani_1.0_Master_Package_v2/references/approved/08_REGION_I_ART_KIT_BACKGROUNDS_PARALLAX_v1_0.png",
        "sha256": "840cfd8241a54f7bab0be58ab96892eba8438517888e490587451339b23263a7",
        "ambiente_producao": "assets/art/regions/region_01_forest/production/kit_9c/",
    }
    man["contrato_frames"] = {
        "formato": "PNG RGBA, alfa 0/255, um ficheiro por frame, sem VFX grandes no corpo, virado para a direita",
        "inimigo_comum": {"canvas": [128, 96], "altura_corpo_px": 48, "baseline_y": 88, "pivot": [64, 88],
                          "porque": "besouro/gosma da autoridade medem 94-96 px de largura a 48 de altura"},
        "guardiao": {"canvas": [192, 192], "altura_corpo_px": 100, "largura_max_px": 110, "baseline_y": 180, "pivot": [96, 180]},
        "boss": {"canvas": [192, 192], "altura_corpo_px": 100, "largura_max_px": 110, "baseline_y": 180, "pivot": [96, 180],
                 "porque": "mesma regra do ChefeBase; no ecrã vai x escala_visual 1.7 -- o tamanho do Coração não baixa"},
    }
    novo = {}
    for eid, e in entradas.items():
        antigo = velho.get(eid, {})
        for chave in ("niveis", "legado", "nota"):
            if chave in antigo:
                e[chave] = antigo[chave]
        e["estados_alcancaveis"] = sorted(e["animacoes"].keys())
        novo[eid] = e
    novo["goblin"]["niveis"] = {"L1": ["EliteGoblin (elite, carga, x1.4)", "GoblinBaixa (patrulha)"]}
    novo["clone_morvanna"]["niveis"] = {"L2": ["clones largados pela Morvanna (identidade_visual; especie continua goblin)"]}
    novo["cria_rainha"]["niveis"] = {"L3": ["crias que eclodem dos ovos da Rainha (identidade_visual; especie continua goblin, x0.62)"]}
    boss = dict(BOSS_BLOQUEADO)
    boss["niveis"] = {"L5": ["Chefe (escala_visual 1.7, enraizado)"]}
    boss["legado"] = "res://assets/sprites/pixel/bosses_anim/coracao_putrefacto/"
    boss["estados_alcancaveis"] = ["idle", "hit", "dead"]
    novo["coracao_putrefacto"] = boss
    man["inimigos"] = novo
    MANIFESTO.write_text(json.dumps(man, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--previa", type=Path, default=None)
    a = ap.parse_args()
    gravar_manifesto(produzir(a.previa))
