#!/usr/bin/env python3
"""Rootbound Frame -- arte do cosmético `hud_moldura_raizes` (Relíquias do
Coração Podre, Região I). DETERMINÍSTICO: mexer AQUI e regerar, nunca nos PNG.

    python tools/gerar_rootbound.py

Gera em assets/ui/shop/heartrot/rootbound_frame/:
  rootbound_frame.png   nine-patch do disco da arma   (88x88, pixel x2, margem 22)
  rootbound_placa.png   nine-patch da placa do nível  (128x64, pixel x2, margens 16/14/16/14)
  base_raizes.png       raízes à volta da fogueira    (48x16, pixel x1)
  cogumelos.png         fungos junto à base           (56x12, pixel x1)
  cogumelos_brilho.png  halo fúngico (fogueira apagada) (56x12, pixel x1)
  preview.png           preview da Loja, COMPOSTA a partir dos assets acima (340x130)

Paleta canónica (aprovada): musgo #5E7A3A, bile #B8C24A, madeira #3A2A20,
casca #1E1712, osso #E8DCC0, carmesim #E22A3C, púrpura #9B3FB0.
Regras: interior limpo; no máximo dois acentos fortes (bile + carmesim); o
estado de um checkpoint nunca depende só da cor (forma/altura/intensidade).
"""
import os
import random
from PIL import Image

SAIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..",
                     "assets", "ui", "shop", "heartrot", "rootbound_frame")

MUSGO = (0x5E, 0x7A, 0x3A)
MUSGO_ESC = (0x43, 0x59, 0x2A)
BILE = (0xB8, 0xC2, 0x4A)
MADEIRA = (0x3A, 0x2A, 0x20)
MADEIRA_LUZ = (0x55, 0x40, 0x30)
RAIZ_LUZ = (0x86, 0x66, 0x4A)           # fio de luz das raízes (sobressai da madeira)
CASCA = (0x1E, 0x17, 0x12)
CONTORNO = (0x10, 0x0B, 0x08)
OSSO = (0xE8, 0xDC, 0xC0)
OSSO_SOMBRA = (0xB0, 0xA4, 0x88)
CARMESIM = (0xE2, 0x2A, 0x3C)
CARMESIM_ESC = (0x6E, 0x18, 0x26)
PURPURA = (0x9B, 0x3F, 0xB0)


def nova(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def pt(im, x, y, cor, a=255):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), (cor[0], cor[1], cor[2], a))


def linha(im, p0, p1, cor, a=255):
    """Bresenham."""
    x0, y0 = p0
    x1, y1 = p1
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    err = dx + dy
    while True:
        pt(im, x0, y0, cor, a)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def raiz(im, pts, luz=True):
    """Raiz de 2 px: corpo casca/madeira com um fio de luz por cima."""
    for a, b in zip(pts, pts[1:]):
        linha(im, (a[0], a[1] + 1), (b[0], b[1] + 1), CONTORNO)
        linha(im, (a[0], a[1] + 1), (b[0], b[1] + 1), MADEIRA)
        linha(im, a, b, MADEIRA_LUZ)
        if luz:
            linha(im, (a[0], a[1] - 1), (b[0], b[1] - 1), RAIZ_LUZ)


def musgo(im, cx, cy, rng, n=6, raio=2):
    for _ in range(n):
        x = cx + rng.randint(-raio, raio)
        y = cy + rng.randint(-raio + 1, raio - 1)
        pt(im, x, y, MUSGO)
    pt(im, cx, cy, MUSGO_ESC)
    if rng.random() < 0.8:
        pt(im, cx + 1, cy - 1, BILE)          # o acento: um único fio de bile


def osso(im, x, y, dx=1, dy=1):
    """Osso pequeno, diagonal: haste de 5 px com duas pontas grossas."""
    for i in range(5):
        pt(im, x + dx * i, y + dy * i, OSSO)
    pt(im, x - dx, y, OSSO)
    pt(im, x, y - dy, OSSO)
    pt(im, x + dx * 5, y + dy * 4, OSSO)
    pt(im, x + dx * 4, y + dy * 5, OSSO)
    pt(im, x + dx * 1, y + dy * 1 + 1, OSSO_SOMBRA)
    pt(im, x + dx * 3, y + dy * 3 + 1, OSSO_SOMBRA)


def cogumelo(im, x, y, cor=BILE):
    """Cogumelo minúsculo: chapéu de 3 px, pé de osso."""
    pt(im, x, y + 1, OSSO)
    pt(im, x, y + 2, OSSO_SOMBRA)
    for dx in (-1, 0, 1):
        pt(im, x + dx, y, cor)
    pt(im, x, y - 1, cor)
    pt(im, x - 1, y - 0, MUSGO_ESC)


def amp(im, f):
    return im.resize((im.width * f, im.height * f), Image.NEAREST)


def madeira_faixa(im, x0, y0, x1, y1, rng, veio_horizontal):
    for y in range(y0, y1):
        for x in range(x0, x1):
            pt(im, x, y, MADEIRA)
    # veios: fios claros e escuros curtos ao longo da faixa
    for _ in range(((x1 - x0) * (y1 - y0)) // 7):
        x, y = rng.randint(x0, x1 - 1), rng.randint(y0, y1 - 1)
        c = MADEIRA_LUZ if rng.random() < 0.45 else CASCA
        n = rng.randint(2, 4)
        for i in range(n):
            xx, yy = (x + i, y) if veio_horizontal else (x, y + i)
            if x0 <= xx < x1 and y0 <= yy < y1:
                pt(im, xx, yy, c)


def moldura(w, h, espessura, fundo_alpha, rng, cantos, bone_canto):
    """Nine-patch: aro de madeira, aresta interior de carmesim escuro,
    centro limpo e escuro, ornamentos só nos cantos (as arestas esticam)."""
    im = nova(w, h)
    for y in range(h):
        for x in range(w):
            pt(im, x, y, CASCA, fundo_alpha)
    e = espessura
    madeira_faixa(im, 0, 0, w, e, rng, True)
    madeira_faixa(im, 0, h - e, w, h, rng, True)
    madeira_faixa(im, 0, 0, e, h, rng, False)
    madeira_faixa(im, w - e, 0, w, h, rng, False)
    # contorno exterior
    for x in range(w):
        pt(im, x, 0, CONTORNO)
        pt(im, x, h - 1, CONTORNO)
    for y in range(h):
        pt(im, 0, y, CONTORNO)
        pt(im, w - 1, y, CONTORNO)
    # aresta interior: casca + um fio de carmesim escuro (ligação ao frontend)
    for x in range(e - 1, w - e + 1):
        pt(im, x, e - 1, CASCA)
        pt(im, x, h - e, CASCA)
        pt(im, x, e, CARMESIM_ESC)
        pt(im, x, h - e - 1, CARMESIM_ESC)
    for y in range(e - 1, h - e + 1):
        pt(im, e - 1, y, CASCA)
        pt(im, w - e, y, CASCA)
        pt(im, e, y, CARMESIM_ESC)
        pt(im, w - e - 1, y, CARMESIM_ESC)
    for canto in cantos:
        canto(im)
    return im


def canto_tl_slot(im):
    rng = random.Random(11)
    # raízes a nascer do canto, uma pela aresta de cima e outra pela da esquerda
    raiz(im, [(1, 8), (2, 6), (4, 5), (7, 4), (9, 3)])
    raiz(im, [(8, 1), (6, 2), (5, 4), (4, 7), (3, 9)])
    musgo(im, 4, 4, rng, 7, 2)
    musgo(im, 8, 3, rng, 3, 1)
    osso(im, 2, 1, 1, 1)


def canto_br_slot(im):
    rng = random.Random(23)
    w, h = im.width, im.height
    raiz(im, [(w - 2, h - 9), (w - 3, h - 7), (w - 5, h - 6), (w - 8, h - 5), (w - 10, h - 4)])
    raiz(im, [(w - 9, h - 2), (w - 7, h - 3), (w - 6, h - 5), (w - 5, h - 8), (w - 4, h - 10)])
    musgo(im, w - 5, h - 5, rng, 7, 2)
    cogumelo(im, w - 8, h - 7)
    cogumelo(im, w - 6, h - 8, MUSGO)


def canto_tr_slot(im):
    rng = random.Random(31)
    w = im.width
    raiz(im, [(w - 2, 7), (w - 4, 5), (w - 6, 4), (w - 9, 3)])
    musgo(im, w - 5, 3, rng, 4, 1)


def canto_bl_slot(im):
    rng = random.Random(37)
    h = im.height
    raiz(im, [(1, h - 8), (3, h - 6), (5, h - 5), (8, h - 4)])
    musgo(im, 4, h - 4, rng, 4, 1)


def gerar_slot():
    rng = random.Random(1)
    im = moldura(44, 44, 5, 235, rng, [canto_tl_slot, canto_br_slot, canto_tr_slot, canto_bl_slot], None)
    return amp(im, 2)


def canto_tl_placa(im):
    rng = random.Random(41)
    raiz(im, [(1, 6), (2, 4), (4, 3), (7, 2)], luz=False)
    musgo(im, 3, 3, rng, 5, 1)
    osso(im, 1, 1, 1, 1)


def canto_br_placa(im):
    rng = random.Random(43)
    w, h = im.width, im.height
    raiz(im, [(w - 2, h - 7), (w - 3, h - 5), (w - 5, h - 4), (w - 8, h - 3)], luz=False)
    musgo(im, w - 4, h - 4, rng, 5, 1)
    cogumelo(im, w - 7, h - 5)


def gerar_placa():
    rng = random.Random(2)
    im = moldura(64, 32, 3, 175, rng, [canto_tl_placa, canto_br_placa], None)
    # fio de raiz fino ao longo da aresta de baixo, discreto
    raiz(im, [(14, 30), (22, 29), (30, 30), (40, 29), (50, 30)], luz=False)
    return amp(im, 2)


def gerar_base():
    """Raízes que abraçam a roda de pedras: dois arcos nodosos, de baixo
    para os lados; o centro fica livre para a chama."""
    rng = random.Random(3)
    im = nova(48, 16)
    raiz(im, [(1, 13), (4, 11), (7, 12), (11, 10), (15, 12), (19, 13)])
    raiz(im, [(46, 13), (43, 11), (40, 12), (36, 10), (32, 12), (28, 13)])
    raiz(im, [(3, 14), (9, 14), (15, 15), (23, 14)], luz=False)
    raiz(im, [(44, 14), (38, 14), (32, 15), (25, 14)], luz=False)
    raiz(im, [(10, 10), (8, 7), (9, 5)], luz=False)          # garra a subir à esquerda
    raiz(im, [(37, 10), (39, 7), (38, 5)], luz=False)        # e à direita
    for cx, cy in [(5, 11), (12, 10), (36, 10), (43, 11), (24, 14)]:
        musgo(im, cx, cy, rng, 4, 1)
    osso(im, 20, 13, -1, 0) if False else None
    # um osso pequeno metido entre as raízes da direita (o detalhe de osso)
    pt(im, 30, 13, OSSO)
    pt(im, 31, 13, OSSO)
    pt(im, 32, 13, OSSO)
    pt(im, 29, 12, OSSO)
    pt(im, 33, 12, OSSO)
    pt(im, 31, 14, OSSO_SOMBRA)
    return im


def _grupo_cogumelos(im, xs, brilho):
    for x, y, cor in xs:
        if brilho:
            # halo pequeno e suave (a fogueira apagada brilha por aqui)
            for dx, dy, a in [(0, 0, 200), (-1, 0, 120), (1, 0, 120), (0, -1, 120), (0, 1, 90),
                              (-2, 0, 60), (2, 0, 60), (0, -2, 60)]:
                pt(im, x + dx, y + dy, cor, a)
        else:
            cogumelo(im, x, y, cor)


COGUMELOS = [(4, 6, BILE), (7, 8, MUSGO), (10, 5, BILE),
             (45, 6, BILE), (48, 8, MUSGO), (51, 5, BILE)]


def gerar_cogumelos(brilho):
    im = nova(56, 12)
    _grupo_cogumelos(im, COGUMELOS, brilho)
    if not brilho:
        rng = random.Random(5)
        for cx in (7, 48):
            musgo(im, cx, 10, rng, 5, 2)
    return im


# --- preview da Loja: composta a partir dos assets acima ---------------------
def chama(im, cx, base_y, alto, forte):
    """Chama em pixel para o PREVIEW (no jogo é um sistema de partículas)."""
    perfil = [(0, 7), (1, 9), (3, 8), (5, 7), (8, 5), (11, 3), (14, 1)]
    for i, (d, larg) in enumerate(perfil):
        if d > alto:
            break
        y = base_y - d
        for dx in range(-larg // 2, larg // 2 + 1):
            cor = MUSGO if abs(dx) * 2 >= larg - 1 else (BILE if d > 1 else (0xE8, 0xF0, 0xA0))
            pt(im, cx + dx, y, cor, 235 if forte else 130)
    if forte:
        for (dx, dy) in [(-4, -8), (3, -11), (5, -6), (-2, -14)]:
            pt(im, cx + dx, base_y + dy, PURPURA)


def gerar_preview(slot, placa, base, cog, cog_b):
    """346x130 = exactamente a caixa de preview da Loja (sem reescala)."""
    W, H = 346, 130
    im = Image.new("RGBA", (W, H), (0x0B, 0x06, 0x0B, 255))
    # esquerda: fragmento do HUD (disco da arma + placa com barras abstractas)
    im.alpha_composite(slot.resize((56, 56), Image.NEAREST), (10, 14))
    im.alpha_composite(placa.resize((96, 48), Image.NEAREST), (74, 18))
    for i, (cor, larg) in enumerate([(CARMESIM, 62), ((0x3A, 0x6E, 0xC8), 40)]):
        y = 84 + i * 14
        for xx in range(10, 10 + 160):
            for yy in range(y, y + 9):
                pt(im, xx, yy, CASCA)
        for xx in range(11, 11 + larg * 2 - 2):
            if xx >= 169:
                break
            for yy in range(y + 1, y + 8):
                pt(im, xx, yy, cor)
    # direita: a mesma fogueira apagada e acesa (forma e altura, nao so' cor)
    for i, aceso in enumerate((False, True)):
        g = nova(56, 40)
        pedras = nova(36, 6)
        for k in range(5):
            for xx in range(k * 7 + 1, k * 7 + 6):
                for yy in range(1, 5):
                    pt(pedras, xx, yy, (0x3C, 0x38, 0x44))
        g.alpha_composite(pedras, (10, 32))
        g.alpha_composite(base, (4, 24))
        g.alpha_composite(cog, (0, 26))
        if not aceso:
            g.alpha_composite(cog_b, (0, 26))
        chama(g, 28, 32, 14 if aceso else 2, aceso)
        im.alpha_composite(g.resize((84, 60), Image.NEAREST), (178 + i * 84, 44))
    return im


def main():
    os.makedirs(SAIDA, exist_ok=True)
    slot, placa = gerar_slot(), gerar_placa()
    base, cog, cog_b = gerar_base(), gerar_cogumelos(False), gerar_cogumelos(True)
    preview = gerar_preview(slot, placa, base, cog, cog_b)
    for nome, im in [("rootbound_frame", slot), ("rootbound_placa", placa), ("base_raizes", base),
                     ("cogumelos", cog), ("cogumelos_brilho", cog_b), ("preview", preview)]:
        caminho = os.path.join(SAIDA, nome + ".png")
        im.save(caminho, optimize=False)
        print("%-18s %dx%d" % (nome + ".png", im.width, im.height))


if __name__ == "__main__":
    main()
