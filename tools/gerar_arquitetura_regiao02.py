#!/usr/bin/env python3
"""Gera os landmarks arquitetónicos da Região II em pixel-art.

Fonte de direção: as pranchas APPROVED em
`docs/art_direction/regions/region_02/`. Os PNGs deste lote são saída;
este script é a fonte que se deve alterar. A geometria é puramente visual:
não há colisões, navegação ou dados de gameplay nestes ficheiros.
"""
from pathlib import Path
from PIL import Image, ImageDraw


RAIZ = Path(__file__).resolve().parents[1]
SAIDA = RAIZ / "assets/sprites/pixel/arquitetura/desfiladeiro"
FONTES = SAIDA / "_source"

TRANSPARENTE = (0, 0, 0, 0)
CONTORNO = (18, 18, 38, 255)
SOMBRA = (31, 29, 63, 255)
PEDRA = (57, 53, 93, 255)
PEDRA_LUZ = (92, 82, 129, 255)
LUAR = (142, 132, 181, 255)
MAGENTA = (174, 49, 105, 255)
CARMESIM = (205, 58, 75, 255)
DOURADO = (218, 155, 91, 255)
AZUL = (105, 164, 230, 255)
AZUL_LUZ = (181, 220, 255, 255)


def imagem(w, h):
    return Image.new("RGBA", (w, h), TRANSPARENTE)


def tijolos(d, caixa, passo=12):
    x0, y0, x1, y1 = caixa
    for y in range(y0 + 6, y1, passo):
        desloc = (passo // 2) if ((y - y0) // passo) % 2 else 0
        for x in range(x0 + desloc, x1, passo):
            d.line((x, y, min(x + passo - 2, x1), y), fill=SOMBRA, width=1)
    d.rectangle(caixa, outline=CONTORNO, width=2)


def arco_vazio(d, caixa, espessura=9):
    x0, y0, x1, y1 = caixa
    cx = (x0 + x1) // 2
    raio = (x1 - x0) // 2
    d.rectangle((x0, y0 + raio, x1, y1), fill=PEDRA)
    d.pieslice((cx - raio, y0, cx + raio, y0 + raio * 2), 180, 360,
               fill=PEDRA)
    r2 = max(2, raio - espessura)
    d.rectangle((x0 + espessura, y0 + raio, x1 - espessura, y1),
                fill=TRANSPARENTE)
    d.pieslice((cx - r2, y0 + espessura, cx + r2,
                y0 + espessura + r2 * 2), 180, 360, fill=TRANSPARENTE)
    d.line((x0, y1, x0, y0 + raio), fill=CONTORNO, width=2)
    d.line((x1, y1, x1, y0 + raio), fill=CONTORNO, width=2)


def janela(d, caixa, cor=MAGENTA):
    x0, y0, x1, y1 = caixa
    cx = (x0 + x1) // 2
    d.polygon([(cx, y0), (x1, y0 + 12), (x1, y1), (x0, y1),
               (x0, y0 + 12)], fill=CONTORNO)
    d.polygon([(cx, y0 + 5), (x1 - 4, y0 + 14), (x1 - 4, y1 - 4),
               (x0 + 4, y1 - 4), (x0 + 4, y0 + 14)], fill=cor)
    d.line((cx, y0 + 6, cx, y1 - 4), fill=AZUL_LUZ, width=2)
    d.line((x0 + 4, (y0 + y1) // 2, x1 - 4, (y0 + y1) // 2),
           fill=AZUL_LUZ, width=1)


def ponte_monumental():
    im = imagem(360, 168)
    d = ImageDraw.Draw(im)
    d.rectangle((8, 25, 351, 48), fill=PEDRA)
    tijolos(d, (8, 25, 351, 48), 11)
    d.rectangle((0, 18, 359, 27), fill=PEDRA_LUZ)
    d.line((0, 18, 359, 18), fill=LUAR, width=2)
    for x in (16, 126, 236):
        arco_vazio(d, (x, 39, x + 108, 164), 13)
        d.rectangle((x + 3, 46, x + 12, 164), fill=SOMBRA)
        d.rectangle((x + 96, 46, x + 105, 164), fill=PEDRA_LUZ)
    for x in range(12, 352, 30):
        d.rectangle((x, 7, x + 5, 18), fill=PEDRA)
        d.rectangle((x - 2, 5, x + 7, 8), fill=PEDRA_LUZ)
    d.polygon([(41, 44), (64, 33), (91, 44)], fill=SOMBRA)
    d.polygon([(151, 44), (178, 31), (214, 44)], fill=SOMBRA)
    d.polygon([(265, 44), (293, 35), (333, 44)], fill=SOMBRA)
    for x in (70, 178, 286):
        d.line((x, 19, x, 39), fill=CARMESIM, width=3)
        d.polygon([(x, 25), (x + 18, 29), (x + 4, 39)], fill=MAGENTA)
    return im


def torre_partida():
    im = imagem(190, 330)
    d = ImageDraw.Draw(im)
    d.polygon([(34, 326), (27, 83), (50, 78), (43, 47), (68, 56),
               (78, 19), (91, 49), (103, 29), (111, 70), (132, 78),
               (123, 326)], fill=PEDRA)
    d.polygon([(104, 326), (114, 132), (137, 127), (129, 96), (153, 105),
               (162, 70), (173, 116), (183, 326)], fill=SOMBRA)
    d.polygon([(27, 83), (50, 78), (43, 47), (68, 56), (78, 19),
               (91, 49), (103, 29), (111, 70), (132, 78), (121, 92),
               (91, 83), (62, 94)], fill=PEDRA_LUZ)
    # Fratura clara que torna a silhueta legível mesmo de longe.
    d.polygon([(104, 74), (91, 116), (107, 145), (88, 186), (102, 224),
               (89, 269), (104, 326), (116, 326), (106, 268), (121, 224),
               (105, 188), (122, 145), (108, 116), (120, 83)], fill=TRANSPARENTE)
    for y in (103, 156, 211, 266):
        janela(d, (54, y, 82, y + 43), AZUL)
    for y in (151, 222):
        janela(d, (139, y, 161, y + 38), MAGENTA)
    tijolos(d, (31, 92, 50, 326), 14)
    tijolos(d, (118, 142, 136, 326), 14)
    return im


def queda_agua():
    im = imagem(188, 420)
    d = ImageDraw.Draw(im)
    # Ilha/ruína no topo, cascata que desaparece nas nuvens.
    d.polygon([(18, 42), (48, 24), (142, 24), (172, 47), (153, 82),
               (127, 93), (116, 126), (91, 103), (68, 127), (55, 87),
               (31, 76)], fill=PEDRA)
    d.line((20, 42, 169, 47), fill=LUAR, width=3)
    arco_vazio(d, (36, 1, 92, 66), 8)
    arco_vazio(d, (96, 5, 151, 69), 8)
    d.rectangle((67, 55, 124, 104), fill=AZUL)
    d.polygon([(67, 55), (79, 118), (70, 202), (83, 287), (74, 418),
               (119, 418), (111, 304), (122, 211), (110, 122), (124, 55)],
              fill=(82, 145, 222, 210))
    d.polygon([(82, 55), (91, 154), (84, 258), (94, 417), (105, 417),
               (100, 265), (108, 159), (102, 55)], fill=(192, 229, 255, 225))
    for y in range(124, 410, 37):
        d.line((75, y, 116, y + 11), fill=AZUL_LUZ, width=2)
    return im


def altar_ruinas():
    im = imagem(230, 164)
    d = ImageDraw.Draw(im)
    d.polygon([(8, 157), (20, 139), (45, 133), (58, 112), (174, 112),
               (188, 132), (215, 138), (226, 157)], fill=SOMBRA)
    d.rectangle((55, 92, 179, 126), fill=PEDRA)
    tijolos(d, (55, 92, 179, 126), 12)
    d.polygon([(74, 92), (88, 38), (105, 20), (116, 4), (127, 20),
               (145, 39), (158, 92)], fill=PEDRA_LUZ)
    d.polygon([(92, 92), (101, 48), (116, 30), (132, 49), (141, 92)],
              fill=CONTORNO)
    d.polygon([(108, 87), (116, 45), (124, 87)], fill=MAGENTA)
    d.ellipse((104, 72, 128, 96), fill=(226, 91, 133, 150))
    d.line((25, 138, 47, 91), fill=PEDRA_LUZ, width=8)
    d.line((184, 133, 207, 77), fill=PEDRA, width=9)
    d.polygon([(40, 93), (29, 72), (54, 83)], fill=CARMESIM)
    d.polygon([(198, 81), (217, 72), (207, 99)], fill=MAGENTA)
    return im


def torre_ceus():
    im = imagem(330, 470)
    d = ImageDraw.Draw(im)
    # Corpo central e duas torres laterais, composição da prancha.
    d.polygon([(80, 468), (72, 128), (91, 116), (87, 76), (106, 87),
               (119, 27), (133, 85), (150, 69), (160, 468)], fill=PEDRA)
    d.polygon([(157, 468), (167, 91), (184, 79), (196, 14), (210, 78),
               (232, 91), (239, 468)], fill=PEDRA_LUZ)
    d.polygon([(12, 468), (21, 205), (38, 194), (48, 133), (61, 192),
               (78, 205), (84, 468)], fill=SOMBRA)
    d.polygon([(238, 468), (246, 185), (263, 174), (275, 111), (289, 174),
               (307, 185), (317, 468)], fill=SOMBRA)
    for caixa in [(105, 113, 137, 177), (101, 206, 141, 276),
                  (181, 105, 217, 174), (177, 205, 221, 284),
                  (35, 241, 64, 300), (263, 226, 293, 288)]:
        janela(d, caixa, MAGENTA)
    # Ponte entre torres e contrafortes.
    d.rectangle((57, 321, 276, 341), fill=PEDRA)
    tijolos(d, (57, 321, 276, 341), 12)
    for x in (69, 125, 181, 237):
        arco_vazio(d, (x, 331, x + 48, 410), 7)
    for x in (20, 76, 152, 233, 307):
        d.polygon([(x - 7, 198), (x, 170), (x + 7, 198)], fill=LUAR)
    d.line((196, 14, 196, 1), fill=AZUL_LUZ, width=2)
    d.polygon([(187, 34), (196, 15), (205, 34)], fill=CARMESIM)
    return im


def lua_sangue():
    im = imagem(220, 220)
    p = im.load()
    cx = cy = 110
    for y in range(220):
        for x in range(220):
            dx, dy = x - cx, y - cy
            r2 = dx * dx + dy * dy
            if r2 > 104 * 104:
                continue
            r = (r2 ** 0.5) / 104.0
            # Gradacao + dither deterministico: a lua continua a ser um
            # acento carmesim, mas deixa de parecer um circulo liso de UI.
            ruido = ((x * 37 + y * 17 + x * y * 3) % 19) - 9
            rr = max(0, min(255, int(222 - 78 * r) + ruido))
            gg = max(0, min(255, int(72 - 24 * r) + ruido // 3))
            bb = max(0, min(255, int(105 - 22 * r) + ruido // 2))
            p[x, y] = (rr, gg, bb, 232)
    d = ImageDraw.Draw(im)
    for caixa in [(36, 53, 73, 72), (127, 39, 164, 59),
                  (72, 133, 111, 152), (145, 151, 174, 169)]:
        d.ellipse(caixa, fill=(104, 38, 75, 82))
    d.arc((7, 7, 213, 213), 115, 285, fill=(255, 143, 151, 205), width=3)
    d.arc((7, 7, 213, 213), 295, 100, fill=(111, 34, 74, 190), width=3)
    return im


def reduzir_fonte(nome, limite, fallback):
    """Recorta alfa e reduz uma fonte aprovada sem a editar a mao."""
    caminho = FONTES / nome
    if not caminho.exists():
        return fallback()
    im = Image.open(caminho).convert("RGBA")
    alfa = im.getchannel("A")
    # O ImageGen deixa uma franja de alfa quase nulo para o brilho. Pixeis
    # abaixo de 8 nao sobrevivem no jogo e impedem um recorte apertado.
    alfa_limpo = alfa.point(lambda a: 0 if a < 8 else a)
    im.putalpha(alfa_limpo)
    caixa = alfa_limpo.getbbox()
    if caixa:
        im = im.crop(caixa)
    im.thumbnail(limite, Image.Resampling.LANCZOS)
    return im


def main():
    SAIDA.mkdir(parents=True, exist_ok=True)
    imagens = {
        "ponte_monumental.png": reduzir_fonte(
            "ponte_monumental_source.png", (720, 360), ponte_monumental),
        "torre_partida.png": reduzir_fonte(
            "torre_partida_source.png", (400, 620), torre_partida),
        "queda_agua.png": reduzir_fonte(
            "queda_agua_source.png", (420, 630), queda_agua),
        "altar_ruinas.png": reduzir_fonte(
            "altar_ruinas_source.png", (540, 360), altar_ruinas),
        "torre_ceus.png": reduzir_fonte(
            "torre_ceus_source.png", (720, 500), torre_ceus),
        "lua_sangue.png": lua_sangue(),
    }
    for nome, im in imagens.items():
        caminho = SAIDA / nome
        im.save(caminho)
        print(f"{nome}: {im.width}x{im.height}")


if __name__ == "__main__":
    main()
