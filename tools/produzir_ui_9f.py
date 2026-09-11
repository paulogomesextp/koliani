"""Execution 9F -- kit de UI de producao derivado da prancha 09 (UI/HUD).

    python tools/produzir_ui_9f.py            # produz assets/ui/producao_9f/
    python tools/produzir_ui_9f.py --validar  # confere SHAs contra o manifesto
    python tools/produzir_ui_9f.py --folha F  # folha de contacto (revisao)

A prancha 09 e' uma folha de APRESENTACAO (RGB, sem alfa, texto em
portugues pintado dentro dos botoes), nao um atlas. Tudo aqui e'
deterministico e so' usa tres operacoes, por peca:

  A  recorte direto (icones em ladrilho, molduras vazias);
  B  reconstrucao tecnica: recorte + INPAINT do texto pintado (cada
     linha da zona de texto passa a ser a interpolacao linear entre as
     colunas logo fora dela -- preserva o gradiente vertical da peca e
     nao inventa desenho) + MASCARA do fundo da prancha (flood-fill a
     partir das bordas, por distancia de cor ao fundo medido na propria
     borda);
  C  derivacao: calha vazia da barra = colunas vazias da propria barra
     repetidas por cima do enchimento pintado; enchimento = fatia do
     enchimento pintado.

Nenhum texto fica nas imagens (os rotulos sao dinamicos, `Textos.t`).
Saida ampliada 2x (LANCZOS): a prancha e' pintura, nao pixel-art, e as
nine-patch do Godot desenham os cantos a 1:1.
"""
from __future__ import annotations

import hashlib
import json
import sys
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw

RAIZ = Path(__file__).resolve().parent.parent
AUTORIDADE = RAIZ / "Koliani_1.0_Master_Package_v2/references/approved/09_PRODUCTION_PACK_v7_UI_HUD_MAPS_MENUS.png"
SHA_AUTORIDADE = "264d6def7c961ea04635754ae91f33f81c891a6eae6eddaf0b1420f094a7aba9"
SAIDA = RAIZ / "assets/ui/producao_9f"
MANIFESTO = SAIDA / "manifesto_ui_9f.json"
ESCALA = 2

# nome: caixa (x0,y0,x1,y1) na prancha, metodo, zonas de inpaint (coords da
# prancha), mascara ("bordas" = fundo da prancha fora da moldura fica
# transparente; "oco" = tambem o interior, para molduras de cartao), e
# tolerancia da mascara.
PECAS: dict[str, dict] = {
    # --- 9. botoes e molduras -----------------------------------------
    "botao_normal": {"caixa": (1019, 590, 1177, 616), "metodo": "B",
                     "texto": [(1050, 595, 1146, 612)], "mascara": "bordas", "tol": 26},
    "botao_selecionado": {"caixa": (1012, 617, 1185, 646), "metodo": "B",
                          "texto": [(1043, 622, 1154, 641)], "mascara": "bordas", "tol": 26},
    "botao_desativado": {"caixa": (1021, 646, 1177, 672), "metodo": "B",
                         "texto": [(1047, 651, 1148, 667)], "mascara": "bordas", "tol": 26},
    "moldura_painel": {"caixa": (1426, 686, 1516, 756), "metodo": "A",
                       "texto": [], "mascara": "bordas", "tol": 22},
    "moldura_ornamentada": {"caixa": (1186, 589, 1279, 659), "metodo": "A",
                            "texto": [], "mascara": "bordas", "tol": 22},
    "caixa_dialogo": {"caixa": (1298, 580, 1517, 656), "metodo": "B",
                      "texto": [(1306, 585, 1472, 641), (1482, 624, 1504, 647)],
                      "mascara": "bordas", "tol": 22},
    # --- 8. feedback --------------------------------------------------
    "toast_info": {"caixa": (779, 588, 983, 622), "metodo": "B",
                   "texto": [(791, 591, 972, 619)], "mascara": "bordas", "tol": 22},
    "toast_habilidade": {"caixa": (779, 718, 983, 758), "metodo": "B",
                         "texto": [(787, 722, 974, 755)], "mascara": "bordas", "tol": 22},
    # --- 3. icones de habilidade (ladrilho inteiro) ---------------------
    "ico_dash": {"caixa": (1075, 94, 1134, 148), "metodo": "A", "texto": [], "mascara": "bordas", "tol": 20},
    "ico_salto_duplo": {"caixa": (1183, 94, 1242, 148), "metodo": "A", "texto": [], "mascara": "bordas", "tol": 20},
    "ico_escudo": {"caixa": (1290, 94, 1349, 148), "metodo": "A", "texto": [], "mascara": "bordas", "tol": 20},
    "ico_ataque_especial": {"caixa": (1400, 94, 1458, 148), "metodo": "A", "texto": [], "mascara": "bordas", "tol": 20},
    # --- 1/8. glifos sem ladrilho (fundo liso recortado) ----------------
    "ico_cristal": {"caixa": (403, 97, 429, 135), "metodo": "B", "texto": [], "mascara": "bordas", "tol": 34},
    "ico_coracao": {"caixa": (132, 113, 155, 138), "metodo": "B", "texto": [], "mascara": "bordas", "tol": 34},
    "ico_checkpoint": {"caixa": (786, 673, 817, 707), "metodo": "B", "texto": [], "mascara": "bordas", "tol": 30},
}

# 2. barras: calha vazia (C) + enchimento (C). `vazio` = colunas da propria
# barra onde a calha ja' esta' vazia; `cheio` = fatia do enchimento pintado.
BARRAS: dict[str, dict] = {
    "vida": {"caixa": (503, 104, 722, 126), "cheio_x": (521, 674), "vazio_x": (682, 712),
             "fatia": (540, 108, 604, 122)},
    "energia": {"caixa": (503, 131, 722, 153), "cheio_x": (521, 653), "vazio_x": (662, 712),
                "fatia": (540, 135, 604, 149)},
}


def sha(caminho: Path) -> str:
    return hashlib.sha256(caminho.read_bytes()).hexdigest()


def inpaint(img: Image.Image, zonas: list[tuple[int, int, int, int]], ox: int, oy: int) -> None:
    """Cada linha da zona = interpolacao linear entre a coluna logo a
    esquerda e a logo a direita (media de 2 px), em coords do recorte."""
    px = img.load()
    for (x0, y0, x1, y1) in zonas:
        x0, x1, y0, y1 = x0 - ox, x1 - ox, y0 - oy, y1 - oy
        for y in range(y0, y1):
            esq = [px[x0 - 1, y], px[x0 - 2, y]]
            dir_ = [px[x1, y], px[x1 + 1, y]]
            a = tuple(sum(c[i] for c in esq) / 2 for i in range(3))
            b = tuple(sum(c[i] for c in dir_) / 2 for i in range(3))
            n = x1 - x0
            for k, x in enumerate(range(x0, x1)):
                t = (k + 1) / (n + 1)
                px[x, y] = tuple(int(round(a[i] * (1 - t) + b[i] * t)) for i in range(3)) + (255,)


def mascara_bordas(img: Image.Image, tol: int) -> None:
    """Flood-fill a partir de todas as bordas: o que estiver a menos de
    `tol` da cor mediana da borda (o fundo da prancha) fica alfa 0."""
    w, h = img.size
    px = img.load()
    borda = [px[x, 0] for x in range(w)] + [px[x, h - 1] for x in range(w)] \
        + [px[0, y] for y in range(h)] + [px[w - 1, y] for y in range(h)]
    ref = tuple(sorted(c[i] for c in borda)[len(borda) // 2] for i in range(3))

    def perto(c) -> bool:
        return sum(abs(c[i] - ref[i]) for i in range(3)) <= tol * 3 // 2

    visto = bytearray(w * h)
    fila = deque()
    for x in range(w):
        fila.append((x, 0)); fila.append((x, h - 1))
    for y in range(h):
        fila.append((0, y)); fila.append((w - 1, y))
    while fila:
        x, y = fila.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or visto[y * w + x]:
            continue
        visto[y * w + x] = 1
        c = px[x, y]
        if not perto(c):
            continue
        px[x, y] = (c[0], c[1], c[2], 0)
        fila.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))


def produzir_peca(prancha: Image.Image, nome: str, p: dict) -> Image.Image:
    x0, y0, x1, y1 = p["caixa"]
    img = prancha.crop((x0, y0, x1, y1)).convert("RGBA")
    if p["texto"]:
        inpaint(img, p["texto"], x0, y0)
    if p["mascara"] == "bordas":
        mascara_bordas(img, p["tol"])
    return img


def produzir_barra(prancha: Image.Image, b: dict) -> tuple[Image.Image, Image.Image]:
    x0, y0, x1, y1 = b["caixa"]
    calha = prancha.crop((x0, y0, x1, y1)).convert("RGBA")
    px = calha.load()
    v0, v1 = b["vazio_x"][0] - x0, b["vazio_x"][1] - x0
    c0, c1 = b["cheio_x"][0] - x0, b["cheio_x"][1] - x0
    largura = v1 - v0
    for x in range(c0, c1 + 1):
        fonte = v0 + (x - c0) % largura
        for y in range(calha.height):
            px[x, y] = px[fonte, y]
    mascara_bordas(calha, 22)
    fatia = prancha.crop(b["fatia"]).convert("RGBA")
    return calha, fatia


def ampliar(img: Image.Image) -> Image.Image:
    return img.resize((img.width * ESCALA, img.height * ESCALA), Image.LANCZOS)


def main() -> int:
    if sha(AUTORIDADE) != SHA_AUTORIDADE:
        print("ERRO: a prancha 09 nao tem o SHA aprovado")
        return 2
    prancha = Image.open(AUTORIDADE).convert("RGB")
    saidas: dict[str, Image.Image] = {}
    registo: dict[str, dict] = {}
    for nome, p in PECAS.items():
        saidas[nome] = ampliar(produzir_peca(prancha, nome, p))
        registo[nome] = {"metodo": p["metodo"], "caixa_prancha": list(p["caixa"]),
                         "inpaint_texto": [list(z) for z in p["texto"]], "mascara": p["mascara"]}
    for nome, b in BARRAS.items():
        calha, fatia = produzir_barra(prancha, b)
        saidas["barra_%s_calha" % nome] = ampliar(calha)
        saidas["barra_%s_enchimento" % nome] = ampliar(fatia)
        registo["barra_%s_calha" % nome] = {"metodo": "C", "caixa_prancha": list(b["caixa"]),
                                            "enchimento_substituido_x": list(b["cheio_x"]),
                                            "colunas_vazias_x": list(b["vazio_x"])}
        registo["barra_%s_enchimento" % nome] = {"metodo": "C", "caixa_prancha": list(b["fatia"])}

    if "--folha" in sys.argv:
        destino = Path(sys.argv[sys.argv.index("--folha") + 1])
        folha(saidas, destino)
        print("folha:", destino)
        return 0

    SAIDA.mkdir(parents=True, exist_ok=True)
    manifesto = {"execution": "9F", "autoridade": AUTORIDADE.name, "sha_autoridade": SHA_AUTORIDADE,
                 "escala": ESCALA, "pecas": {}}
    validar = "--validar" in sys.argv
    antigo = json.loads(MANIFESTO.read_text(encoding="utf-8")) if validar and MANIFESTO.exists() else None
    falhas = 0
    for nome, img in sorted(saidas.items()):
        destino = SAIDA / (nome + ".png")
        if validar:
            import io
            buf = io.BytesIO(); img.save(buf, "PNG", optimize=False)
            atual = hashlib.sha256(buf.getvalue()).hexdigest()
            esperado = (antigo or {}).get("pecas", {}).get(nome, {}).get("sha256")
            ok = atual == esperado and destino.exists() and sha(destino) == esperado
            falhas += 0 if ok else 1
            print(("PASS " if ok else "FAIL ") + nome)
            continue
        img.save(destino, "PNG", optimize=False)
        manifesto["pecas"][nome] = dict(registo[nome], ficheiro=destino.name,
                                        tamanho=list(img.size), sha256=sha(destino))
    if validar:
        print("%d/%d PASS" % (len(saidas) - falhas, len(saidas)))
        return 1 if falhas else 0
    MANIFESTO.write_text(json.dumps(manifesto, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("%d pecas em %s" % (len(saidas), SAIDA.relative_to(RAIZ)))
    return 0


def folha(saidas: dict[str, Image.Image], destino: Path) -> None:
    larg = 1500
    x = y = alt = 0
    posicoes = []
    for nome, img in saidas.items():
        if x + img.width > larg:
            x, y, alt = 0, y + alt + 22, 0
        posicoes.append((nome, img, x, y + 16))
        x += img.width + 14
        alt = max(alt, img.height + 16)
    fundo = Image.new("RGBA", (larg, y + alt + 30), (255, 0, 255, 255))
    d = ImageDraw.Draw(fundo)
    for yy in range(0, fundo.height, 12):
        for xx in range(0, larg, 12):
            if (xx // 12 + yy // 12) % 2:
                d.rectangle((xx, yy, xx + 11, yy + 11), fill=(200, 200, 200, 255))
            else:
                d.rectangle((xx, yy, xx + 11, yy + 11), fill=(120, 120, 120, 255))
    for nome, img, px, py in posicoes:
        fundo.alpha_composite(img, (px, py))
        d.text((px, py - 14), nome, fill=(255, 255, 0, 255))
    fundo.save(destino)


if __name__ == "__main__":
    sys.exit(main())
