#!/usr/bin/env python3
"""Cosméticos da Loja com ARTE REAL (fora os da Koliani e a Rootbound Frame,
que tem o seu `gerar_rootbound.py`). DETERMINÍSTICO: mexer AQUI e regerar,
nunca nos PNG.

    python tools/gerar_cosmeticos_loja.py

Molduras HUD + fogueira (mesmo contrato da Rootbound Frame):
  assets/ui/shop/ossario/          Moldura do Ossário   (`hud_moldura_osso`)
  assets/ui/shop/gaiola_aurora/    Gaiola de Aurora     (`hud_moldura_gaiola`)
    moldura.png  nine-patch do disco da arma  (88x88, pixel x2, margem 22)
    placa.png    nine-patch da placa do nível (128x64, pixel x2, margens 16/14/16/14)
    base.png     peça da fogueira POR CIMA da lenha e da chama (pixel x1)
    frente.png   detalhe à frente, rente ao chão (pixel x1)
    brilho.png   o que brilha com a fogueira APAGADA (pixel x1)
    preview.png  preview da Loja, composta a partir das peças (346x130)

Rastos do dash (folhas de partículas animadas, lidas por `rasto_cosmetico.gd`):
  assets/ui/shop/rastos/<nome>/
    particula_a.png, particula_b.png  tiras horizontais de N frames quadrados
    preview.png                       preview da Loja (346x130)

Sprites desenhados à mão como grelhas de caracteres (uma letra = uma cor da
paleta da peça, '.' = transparente). Luz sempre de cima-esquerda.
"""
import math
import os
import random
from PIL import Image

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SHOP = os.path.join(RAIZ, "assets", "ui", "shop")
KOLIANI_DASH = os.path.join(RAIZ, "assets", "sprites", "koliani_golden_set", "frames", "dash", "dash_002.png")

FUNDO_PREVIEW = (0x0B, 0x06, 0x0B)


# --- utilitários -------------------------------------------------------------
def hexc(s):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))


def nova(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def pt(im, x, y, cor, a=255):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), (cor[0], cor[1], cor[2], a))


def linha(im, p0, p1, cor, a=255):
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


def grelha(im, x, y, linhas, pal, espelho=False):
    """Carimba um sprite ASCII. `pal`: letra -> (r,g,b) ou (r,g,b,a)."""
    w = max(len(l) for l in linhas)
    for j, ln in enumerate(linhas):
        ln = ln.ljust(w, ".")
        if espelho:
            ln = ln[::-1]
        for i, ch in enumerate(ln):
            if ch == "." or ch == " ":
                continue
            c = pal[ch]
            pt(im, x + i, y + j, c[:3], c[3] if len(c) > 3 else 255)


def sprite(linhas, pal, espelho=False):
    w = max(len(l) for l in linhas)
    im = nova(w, len(linhas))
    grelha(im, 0, 0, [l.ljust(w, ".") for l in linhas], pal, espelho)
    return im


def amp(im, f):
    return im.resize((im.width * f, im.height * f), Image.NEAREST)


def tira(frames):
    """Frames do mesmo tamanho lado a lado (folha para `hframes`)."""
    w, h = frames[0].size
    im = nova(w * len(frames), h)
    for i, f in enumerate(frames):
        im.alpha_composite(f, (i * w, 0))
    return im


def halo(im, cx, cy, raio, cor, a_max):
    """Brilho redondo e suave em degraus (pixel-art: 4 anéis de alfa)."""
    for y in range(cy - raio, cy + raio + 1):
        for x in range(cx - raio, cx + raio + 1):
            d = math.hypot(x - cx, y - cy) / max(raio, 1)
            if d > 1.0:
                continue
            a = int(a_max * (1.0 - math.floor(d * 4) / 4.0))
            if a <= 0 or not (0 <= x < im.width and 0 <= y < im.height):
                continue
            r, g, b, a0 = im.getpixel((x, y))
            if a > a0:
                pt(im, x, y, cor, a)


# =============================================================================
# SOMBREADO -- volumes a pixel (esfera / cápsula ao longo de uma polilinha),
# luz de cima-esquerda, rampa discreta (sem gradientes), contorno por camada.
# Desenha-se cada objeto numa camada própria, contorna-se, e só então se
# compõe: é o que dá a leitura "pixel a pixel" e não "forma geométrica".
# =============================================================================
_L = (-0.48, -0.66, 0.58)
_n = math.sqrt(sum(v * v for v in _L))
LUZ = tuple(v / _n for v in _L)


def tom(i, rampa, cortes=None):
    """rampa escura -> clara; `cortes` = limiares de intensidade (len-1)."""
    if cortes is None:
        cortes = [-0.05, 0.38, 0.72, 0.93][:len(rampa) - 1]
    for k, c in enumerate(cortes):
        if i < c:
            return rampa[k]
    return rampa[len(cortes)]


def esfera(im, cx, cy, rx, ry, rampa, cortes=None, a=255):
    for y in range(int(cy - ry - 1), int(cy + ry + 2)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            nx, ny = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            d2 = nx * nx + ny * ny
            if d2 > 1.0:
                continue
            nz = math.sqrt(1.0 - d2)
            pt(im, x, y, tom(nx * LUZ[0] + ny * LUZ[1] + nz * LUZ[2], rampa, cortes), a)


def capsula(im, pts, r, rampa, cortes=None, a=255):
    """Tubo de raio `r` ao longo da polilinha `pts` (osso, costela, barra)."""
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    for y in range(int(min(ys) - r - 1), int(max(ys) + r + 2)):
        for x in range(int(min(xs) - r - 1), int(max(xs) + r + 2)):
            px, py = x + 0.5, y + 0.5
            melhor = None
            for (ax, ay), (bx, by) in zip(pts, pts[1:]):
                dx, dy = bx - ax, by - ay
                l2 = dx * dx + dy * dy or 1e-9
                t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / l2))
                vx, vy = px - (ax + t * dx), py - (ay + t * dy)
                d = math.hypot(vx, vy)
                if melhor is None or d < melhor[0]:
                    melhor = (d, vx, vy)
            d, vx, vy = melhor
            if d > r:
                continue
            nz = math.sqrt(max(0.0, 1.0 - (d / r) ** 2))
            pt(im, x, y, tom((vx / r) * LUZ[0] + (vy / r) * LUZ[1] + nz * LUZ[2], rampa, cortes), a)


def contornar(im, cor, cor_sombra=None):
    """Contorno de 1 px à volta do que está pintado. `cor_sombra` (opcional)
    no lado de baixo-direita: o selout que dá peso à peça."""
    px = im.load()
    w, h = im.size
    cheio = [[px[x, y][3] > 0 for x in range(w)] for y in range(h)]
    for y in range(h):
        for x in range(w):
            if cheio[y][x]:
                continue
            viz = [(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
            toca = [(vx, vy) for vx, vy in viz if 0 <= vx < w and 0 <= vy < h and cheio[vy][vx]]
            if toca:
                c = cor
                if cor_sombra is not None and any(vx < x or vy < y for vx, vy in toca):
                    c = cor_sombra
                pt(im, x, y, c)
    return im


def por(dest, camada, x=0, y=0):
    dest.alpha_composite(camada, (x, y))


def recolher(im, cor, raio, a_max, tol=10):
    """Camada de brilho: halo à volta de TODOS os pixels da cor `cor` em `im`
    (os olhos, as pedras) -- o brilho segue sempre o desenho."""
    out = nova(*im.size)
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a > 0 and abs(r - cor[0]) + abs(g - cor[1]) + abs(b - cor[2]) <= tol:
                halo(out, x, y, raio, cor, a_max)
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a > 0 and abs(r - cor[0]) + abs(g - cor[1]) + abs(b - cor[2]) <= tol:
                pt(out, x, y, cor)
    return out


# =============================================================================
# MOLDURA 1 -- OSSÁRIO (`hud_moldura_osso`)
# Ossos longos a fazer de aro, epífises nos cantos, caveiras com a alma acesa
# nos olhos. A fogueira arde numa caixa torácica, com chama de alma.
# =============================================================================
OSSO = [hexc("4E4336"), hexc("8C7C62"), hexc("C4B593"), hexc("E6DBBE"), hexc("FFF6E0")]
OS = {
    "k": hexc("0E0B10"), "c": hexc("2A221C"),  # contorno / contorno do lado da sombra
    "a": hexc("1E1A22"),                       # interior
    "t": hexc("A6FFF2"), "T": hexc("3FB8B4"),  # alma
    "r": hexc("6E1826"),                       # fio carmesim (ligação ao frontend)
    "x": hexc("120C0E"),                       # órbita
}


def caveira(w=20, h=20, jaw=False):
    """Caveira de ossário, de frente, sem mandíbula: crânio, maçãs, órbitas
    fundas com a alma acesa ao fundo, cavidade nasal, fiada de dentes."""
    c = nova(w, h)
    cx = w / 2.0
    # crânio
    esfera(c, cx, h * 0.40, w * 0.46, h * 0.40, OSSO)
    # maxila (mais estreita) e maçãs do rosto
    esfera(c, cx, h * 0.66, w * 0.31, h * 0.22, OSSO)
    esfera(c, cx - w * 0.25, h * 0.60, w * 0.13, h * 0.12, OSSO)
    esfera(c, cx + w * 0.25, h * 0.60, w * 0.13, h * 0.12, OSSO)
    # órbitas: aro de sombra, fundo quase preto, alma num pixel
    for s in (-1, 1):
        ox, oy = cx + s * w * 0.20, h * 0.50
        esfera(c, ox, oy, w * 0.15, h * 0.13, [OSSO[0]] * 5)
        esfera(c, ox + 0.3, oy + 0.3, w * 0.11, h * 0.09, [OS["x"]] * 5)
        pt(c, int(ox + (0 if s < 0 else -1)), int(oy), OS["t"])
        pt(c, int(ox + (0 if s < 0 else -1)), int(oy) + 1, OS["T"])
    # cavidade nasal: triângulo invertido
    ny = int(h * 0.64)
    pt(c, int(cx) - 1, ny, OS["x"])
    pt(c, int(cx), ny, OS["x"])
    pt(c, int(cx) - 1, ny + 1, OS["x"])
    pt(c, int(cx), ny + 1, OSSO[0])
    # dentes: fiada alternada, com a linha da gengiva por cima
    ty = int(h * 0.80)
    for x in range(int(cx - w * 0.24), int(cx + w * 0.24) + 1):
        pt(c, x, ty - 1, OSSO[1])
        pt(c, x, ty, OSSO[3] if (x % 2 == 0) else OSSO[0])
        pt(c, x, ty + 1, OSSO[2] if (x % 2 == 0) else OS["x"])
    # fissura (sutura) no alto do crânio
    for (x, y) in [(int(cx) + 1, 2), (int(cx) + 2, 3), (int(cx) + 1, 4), (int(cx) + 2, 5)]:
        pt(c, x, y, OSSO[1])
    return contornar(c, OS["k"])


def osso_longo(w, h, p0, p1, r, knob):
    """Osso inteiro (haste + epífises duplas nas pontas) numa camada."""
    c = nova(w, h)
    capsula(c, [p0, p1], r, OSSO)
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    l = math.hypot(dx, dy)
    ux, uy = dx / l, dy / l
    px_, py_ = -uy, ux
    for (ex, ey), sg in ((p0, -1), (p1, 1)):
        for s in (-1, 1):
            esfera(c, ex + ux * sg * r * 0.4 + px_ * s * r * 0.75, ey + uy * sg * r * 0.4 + py_ * s * r * 0.75,
                   knob, knob, OSSO)
    return contornar(c, OS["k"])


def haste(w, h, eixo, pos, r, de, ate):
    """Haste lisa (aresta do nine-patch): uniforme ao longo do comprimento,
    para esticar/encolher sem deformar nada."""
    c = nova(w, h)
    if eixo == "h":
        capsula(c, [(de, pos), (ate, pos)], r, OSSO)
    else:
        capsula(c, [(pos, de), (pos, ate)], r, OSSO)
    return c


def moldura_ossario_disco():
    W = H = 88
    im = nova(W, H)
    for y in range(H):
        for x in range(W):
            pt(im, x, y, OS["a"], 235)
    aro = nova(W, H)
    r = 4.6
    m = 5.5
    for c in (haste(W, H, "h", m, r, -10, W + 10), haste(W, H, "h", H - m, r, -10, W + 10),
              haste(W, H, "v", m, r, -10, H + 10), haste(W, H, "v", W - m, r, -10, H + 10)):
        por(aro, c)
    contornar(aro, OS["k"])
    por(im, aro)
    # fio interior: sombra + carmesim (a ligação ao frontend)
    for i in range(12, W - 12):
        for (x, y, cor) in [(i, 11, OS["k"]), (i, 12, OS["r"]), (i, H - 12, OS["k"]), (i, H - 13, OS["r"]),
                            (11, i, OS["k"]), (12, i, OS["r"]), (W - 12, i, OS["k"]), (W - 13, i, OS["r"])]:
            pt(im, x, y, cor)
    # cantos (22x22 cada, nunca esticam): epífises + caveiras
    for (cx, cy) in [(W - 6, 6), (6, H - 6)]:
        ep = nova(W, H)
        for (ox, oy) in [(-2.6, -2.6), (2.4, 2.4), (-2.8, 2.6), (2.6, -2.8)]:
            esfera(ep, cx + ox, cy + oy, 4.2, 4.2, OSSO)
        esfera(ep, cx, cy, 3.2, 3.2, OSSO)
        por(im, contornar(ep, OS["k"]))
    # caveira grande em cima-esquerda, caveira pequena em baixo-direita com
    # dois ossos cruzados por trás
    por(im, caveira(21, 21), 0, 0)
    cruz = nova(W, H)
    por(cruz, osso_longo(W, H, (W - 21, H - 5), (W - 5, H - 21), 1.6, 1.9))
    por(cruz, osso_longo(W, H, (W - 21, H - 19), (W - 5, H - 3), 1.6, 1.9))
    por(im, cruz)
    por(im, caveira(15, 15), W - 17, H - 17)
    return im


def moldura_ossario_placa():
    W, H = 128, 64
    im = nova(W, H)
    for y in range(H):
        for x in range(W):
            pt(im, x, y, OS["a"], 175)
    aro = nova(W, H)
    r, m = 2.8, 3.2
    for c in (haste(W, H, "h", m, r, -10, W + 10), haste(W, H, "h", H - m, r, -10, W + 10),
              haste(W, H, "v", m, r, -10, H + 10), haste(W, H, "v", W - m, r, -10, H + 10)):
        por(aro, c)
    contornar(aro, OS["k"])
    por(im, aro)
    for i in range(8, W - 8):
        pt(im, i, 7, OS["r"])
        pt(im, i, H - 8, OS["r"])
    for i in range(8, H - 8):
        pt(im, 7, i, OS["r"])
        pt(im, W - 8, i, OS["r"])
    for (cx, cy) in [(W - 4, 4), (4, H - 4)]:
        ep = nova(W, H)
        for (ox, oy) in [(-1.8, -1.8), (1.8, 1.8), (-1.8, 1.8), (1.8, -1.8)]:
            esfera(ep, cx + ox, cy + oy, 2.8, 2.8, OSSO)
        por(im, contornar(ep, OS["k"]))
    por(im, caveira(13, 13), 0, 0)
    por(im, caveira(13, 13), W - 13, H - 13)
    return im


def ossario_fogueira():
    """base (56x40): caixa torácica de pé à volta da chama -- esterno curto no
    alto, quatro pares de costelas a abrir para os lados e a descer até ao
    chão -- e, no lugar da lenha, três fémures cruzados. frente (56x16):
    caveira, velas de sebo, um osso solto. brilho: os olhos (alma) com a
    fogueira apagada. A lenha poligonal do jogo fica escondida."""
    W, H = 56, 40
    base = nova(W, H)
    cx = W / 2.0
    chao = H - 3
    lenha = nova(W, H)
    por(lenha, osso_longo(W, H, (14, chao - 1), (42, chao - 5), 1.5, 1.9))
    por(lenha, osso_longo(W, H, (14, chao - 5), (42, chao - 1), 1.5, 1.9))
    por(base, lenha)
    costelas = nova(W, H)
    for i in range(3):
        topo = 6 + i * 6          # onde a costela nasce no esterno
        larg = 16 + i * 5         # até onde abre
        fim = 21 + i * 6          # as de cima são curtas, as de baixo longas
        for s_ in (-1, 1):
            pts = []
            for k in range(12):
                t = k / 11.0
                # sai do esterno quase na horizontal, abre e cai (quarto de elipse)
                x = cx + s_ * (2 + larg * math.sin(t * math.pi / 2))
                y = topo + (fim - topo) * (1 - math.cos(t * math.pi / 2))
                pts.append((x, y))
            capsula(costelas, pts, 1.3, OSSO)
    capsula(costelas, [(cx, 3), (cx, 20)], 1.9, OSSO)
    contornar(costelas, OS["k"])
    por(base, costelas)

    frente = nova(56, 16)
    por(frente, osso_longo(56, 16, (38, 14), (45, 12), 1.0, 1.4))
    por(frente, caveira(14, 14), 2, 2)
    # velas de sebo a derreter, pavio apagado (a fogueira é que acende)
    for (x, alto) in [(47, 9), (52, 6)]:
        v = nova(56, 16)
        capsula(v, [(x, 15 - alto), (x, 14.5)], 1.6, [hexc("7A6A4E"), hexc("B8A47E"), hexc("E4D6B0"), hexc("F6ECCE")])
        pt(v, x, 15 - alto - 2, hexc("2A1E14"))
        pt(v, x + 1, 15 - alto + 2, hexc("E4D6B0"))   # pingo de cera
        pt(v, x + 1, 15 - alto + 3, hexc("B8A47E"))
        por(frente, contornar(v, OS["k"]))
    brilho = recolher(frente, OS["t"], 3, 170)
    return base, frente, brilho


# =============================================================================
# MOLDURA 2 -- GAIOLA DE AURORA (`hud_moldura_gaiola`)
# O ferro da gaiola onde o Zeriko prende a Aurora: bandas rebitadas, remates
# de lança gótica, pedras-da-lua magenta engastadas. A fogueira arde DENTRO de
# uma gaiola de cúpula com argola, e a corrente partida fica no chão.
# =============================================================================
FERRO = [hexc("1E1828"), hexc("3A3150"), hexc("5C5276"), hexc("8C84A6"), hexc("D6DCF0")]
PEDRA = [hexc("3A0E4C"), hexc("8E2FA8"), hexc("D23CC0"), hexc("FF7AE6"), hexc("FFE4FA")]
GA = {
    "k": hexc("0A0610"), "a": hexc("130D1B"), "q": hexc("4A1560"), "m": hexc("E040C8"),
    "L": hexc("DCE4F6"),
}


def pedra_lua(d):
    """Pedra-da-lua lapidada, com reflexo de luar e brilho interno."""
    c = nova(d + 2, d + 2)
    esfera(c, (d + 2) / 2.0, (d + 2) / 2.0, d / 2.0, d / 2.0, PEDRA, [-0.2, 0.3, 0.7, 0.9])
    pt(c, int(d * 0.35) + 1, int(d * 0.3) + 1, GA["L"])
    return contornar(c, GA["k"])


def engaste(d):
    """Engaste de ferro em losango à volta de uma pedra."""
    t = d + 8
    c = nova(t, t)
    m = t / 2.0
    for y in range(t):
        for x in range(t):
            if abs(x + 0.5 - m) + abs(y + 0.5 - m) <= m - 0.5:
                nx, ny = (x + 0.5 - m) / m, (y + 0.5 - m) / m
                i = -(nx * 0.6 + ny * 0.8)
                pt(c, x, y, FERRO[3] if i > 0.25 else FERRO[2] if i > -0.25 else FERRO[1])
    contornar(c, GA["k"])
    por(c, pedra_lua(d), (t - d - 2) // 2, (t - d - 2) // 2)
    return c


def lanca(h):
    """Remate de lança gótica (ponta de barra de gaiola), vertical, para cima."""
    w = 7
    c = nova(w, h)
    capsula(c, [(3.5, 5), (3.5, h)], 1.3, FERRO)
    for y in range(0, 6):
        meia = [0, 1, 2, 2, 1, 1][y]
        for x in range(int(3.5 - meia), int(3.5 + meia) + 1):
            pt(c, x, y, FERRO[3] if x <= 3 else FERRO[1])
    return contornar(c, GA["k"])


def crescente(d):
    """Crescente de luar, com o lado claro para a esquerda."""
    c = nova(d, d)
    esfera(c, d / 2.0, d / 2.0, d / 2.0 - 1, d / 2.0 - 1, [hexc("5A6280"), hexc("9AA6C8"), hexc("DCE4F6"), hexc("FFFFFF")])
    for y in range(d):
        for x in range(d):
            if (x + 0.5 - d * 0.68) ** 2 + (y + 0.5 - d * 0.38) ** 2 < (d * 0.36) ** 2:
                c.putpixel((x, y), (0, 0, 0, 0))
    return contornar(c, GA["k"])


def banda_ferro(W, H, r, m, rebites):
    aro = nova(W, H)
    for (eixo, pos) in [("h", m), ("h", H - m), ("v", m), ("v", W - m)]:
        c = nova(W, H)
        if eixo == "h":
            for x in range(-2, W + 2):
                for dy in range(-int(r), int(r) + 1):
                    y = int(pos) + dy
                    i = -dy / r
                    pt(c, x, y, tom(i * 0.9, FERRO[1:4], [-0.3, 0.45]))
        else:
            for y in range(-2, H + 2):
                for dx in range(-int(r), int(r) + 1):
                    x = int(pos) + dx
                    i = -dx / r
                    pt(c, x, y, tom(i * 0.9, FERRO[1:4], [-0.3, 0.45]))
        por(aro, c)
    contornar(aro, GA["k"])
    return aro


def moldura_gaiola_disco():
    W = H = 88
    im = nova(W, H)
    for y in range(H):
        for x in range(W):
            pt(im, x, y, GA["a"], 235)
    por(im, banda_ferro(W, H, 4, 5, True))
    # fio magenta escuro por dentro: o brilho da pedra a vazar para o HUD
    for i in range(11, W - 11):
        for (x, y) in [(i, 10), (i, H - 11), (10, i), (W - 11, i)]:
            pt(im, x, y, GA["k"])
        for (x, y) in [(i, 11), (i, H - 12), (11, i), (W - 12, i)]:
            pt(im, x, y, GA["q"])
    # cantos: engaste com pedra em cima-esq. e baixo-dir.; lanças cruzadas
    # e rebite grande nos outros dois
    por(im, engaste(9), 1, 1)
    por(im, engaste(9), W - 18, H - 18)
    # nos outros dois cantos, o crescente de luar (Aurora) sobre um rebite
    for (x, y, virar) in [(W - 17, 1, False), (1, H - 17, True)]:
        r = nova(16, 16)
        esfera(r, 8, 8, 3.4, 3.4, FERRO)
        por(im, contornar(r, GA["k"]), x, y)
        l = crescente(14)
        por(im, l.transpose(Image.FLIP_LEFT_RIGHT) if virar else l, x + 1, y + 1)
    return im


def moldura_gaiola_placa():
    W, H = 128, 64
    im = nova(W, H)
    for y in range(H):
        for x in range(W):
            pt(im, x, y, GA["a"], 175)
    por(im, banda_ferro(W, H, 2, 3, False))
    for i in range(7, W - 7):
        pt(im, i, 6, GA["q"])
        pt(im, i, H - 7, GA["q"])
    for i in range(7, H - 7):
        pt(im, 6, i, GA["q"])
        pt(im, W - 7, i, GA["q"])
    por(im, engaste(5), 0, 0)
    por(im, engaste(5), W - 13, H - 13)
    por(im, crescente(12), W - 13, 1)
    por(im, crescente(12).transpose(Image.FLIP_LEFT_RIGHT), 1, H - 13)
    return im


def gaiola_fogueira():
    """base (50x58): gaiola de cúpula, barras de trás escuras e finas, barras
    da frente sombreadas, aros, tampa com argola e pedra-da-lua, pés em garra.
    frente (64x16): corrente partida caída + cadeado aberto. brilho: halo da
    pedra da tampa e fio de luar nas barras (fogueira apagada)."""
    W, H = 50, 58
    cx = W / 2.0
    topo, fundo = 13, H - 5
    tras = nova(W, H)
    frente_b = nova(W, H)
    for off, da_frente in [(-21, True), (-15, False), (-8, True), (0, False), (8, True), (15, False), (21, True)]:
        pts = []
        for k in range(13):
            t = k / 12.0
            y = topo + (fundo - topo) * t
            curva = math.sin(min(1.0, t * 1.7) * math.pi / 2)
            pts.append((cx + off * curva, y))
        if da_frente:
            capsula(frente_b, pts, 1.25, FERRO[1:])
        else:
            capsula(tras, pts, 0.8, [FERRO[0], FERRO[1]], [0.3])
    for y, meia in [(fundo - 1, 22.5), (fundo - 19, 22.5)]:
        capsula(frente_b, [(cx - meia, y), (cx + meia, y)], 1.4, FERRO[1:])
    capsula(frente_b, [(cx - 7, topo), (cx + 7, topo)], 1.6, FERRO[1:])
    # argola
    arg = nova(W, H)
    for a in range(0, 360, 12):
        x = cx + 3.2 * math.cos(math.radians(a))
        y = topo - 7 + 3.2 * math.sin(math.radians(a))
        capsula(arg, [(x, y), (x + 0.01, y)], 1.0, FERRO[1:])
    capsula(arg, [(cx, topo - 3.5), (cx, topo - 1)], 1.0, FERRO[1:])
    por(frente_b, arg)
    # pés em garra
    for s in (-1, 1):
        capsula(frente_b, [(cx + s * 21, fundo), (cx + s * 23.5, fundo + 3.2)], 1.3, FERRO[1:])
    contornar(tras, GA["k"])
    contornar(frente_b, GA["k"])
    base = nova(W, H)
    por(base, tras)
    por(base, frente_b)
    por(base, pedra_lua(6), int(cx) - 4, topo - 3)

    frente = nova(56, 16)
    cor = nova(56, 16)
    x, y = 1.0, 12.0
    for i in range(8):
        if i % 2 == 0:
            for a in range(0, 360, 20):
                px_ = x + 2.4 + 2.4 * math.cos(math.radians(a))
                py_ = y + 1.4 * math.sin(math.radians(a))
                capsula(cor, [(px_, py_), (px_ + 0.01, py_)], 0.7, FERRO[2:])
            x += 4.0
        else:
            capsula(cor, [(x - 0.5, y), (x + 2.8, y)], 0.75, FERRO[2:])
            x += 2.6
        y = 12.0 + (0.6 if 2 <= i <= 5 else 0.0)
    por(frente, contornar(cor, GA["k"]))
    cad = nova(56, 16)
    for a in range(180, 361, 15):   # arco aberto do cadeado, rodado para o lado
        px_ = 45.5 + 3.0 * math.cos(math.radians(a))
        py_ = 7.0 + 3.0 * math.sin(math.radians(a))
        capsula(cad, [(px_ + 2.2, py_ - 0.5), (px_ + 2.21, py_ - 0.5)], 0.8, FERRO[1:])
    for yy in range(7, 15):
        for xx in range(41, 49):
            i = -((xx - 45) / 4.0) * 0.6 - ((yy - 11) / 4.0) * 0.8
            pt(cad, xx, yy, tom(i, FERRO[1:4], [-0.2, 0.35]))
    pt(cad, 44, 10, GA["k"])
    pt(cad, 44, 11, GA["k"])
    pt(cad, 44, 12, PEDRA[2])
    por(frente, contornar(cad, GA["k"]))
    brilho = nova(W, H)
    halo(brilho, int(cx) - 1, topo, 8, PEDRA[3], 190)
    return base, frente, brilho


# --- preview das molduras ----------------------------------------------------
def barras_hud(im, x, y, fundo):
    for i, (cor, larg) in enumerate([(hexc("E22A3C"), 124), (hexc("3A6EC8"), 80)]):
        yy0 = y + i * 14
        for xx in range(x, x + 142):
            for yy in range(yy0, yy0 + 9):
                pt(im, xx, yy, fundo)
        for xx in range(x + 1, x + larg):
            for yy in range(yy0 + 1, yy0 + 8):
                pt(im, xx, yy, cor)


def nine(tex, w, h, m):
    """Nine-patch como o StyleBoxTexture o desenha (cantos 1:1, arestas esticadas)."""
    ml, mt, mr, mb = m
    out = nova(w, h)
    tw, th = tex.size
    xs = [(0, ml, 0, ml), (ml, tw - mr, ml, w - mr), (tw - mr, tw, w - mr, w)]
    ys = [(0, mt, 0, mt), (mt, th - mb, mt, h - mb), (th - mb, th, h - mb, h)]
    for (sx0, sx1, dx0, dx1) in xs:
        for (sy0, sy1, dy0, dy1) in ys:
            if sx1 <= sx0 or sy1 <= sy0 or dx1 <= dx0 or dy1 <= dy0:
                continue
            p = tex.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.NEAREST)
            out.alpha_composite(p, (dx0, dy0))
    return out


def fogueira_preview(base, frente, brilho, aceso, rampa, lenha, dy_base, fagulha):
    """A fogueira do jogo em ponto pequeno: pedras, lenha, peças e chama."""
    g = nova(72, 72)
    cx, chao = 36, 62
    for k in range(5):
        for xx in range(cx - 18 + k * 7, cx - 13 + k * 7):
            for yy in range(chao - 3, chao + 1):
                pt(g, xx, yy, (0x3C, 0x38, 0x44))
    for (ox, oy, cor) in [(-13, -7, lenha[0]), (-9, -4, lenha[1]), (-5, -6, lenha[0])]:
        for xx in range(cx + ox, cx + ox + 18):
            for yy in range(chao + oy, chao + oy + 4):
                pt(g, xx, yy, cor)
    if aceso:
        halo(g, cx, chao - 14, 22, rampa[1], 55)
        perfil = [(0, 11), (2, 13), (4, 12), (7, 11), (10, 9), (13, 7), (16, 5), (19, 4), (22, 3), (25, 2), (28, 1)]
        for i, (d, larg) in enumerate(perfil):
            nxt = perfil[i + 1][0] if i + 1 < len(perfil) else d + 1
            for yy in range(chao - 5 - nxt + 1, chao - 5 - d + 1):
                for dx in range(-larg // 2, larg // 2 + 1):
                    borda = abs(dx) * 2 >= larg - 2
                    cor = rampa[2] if borda else (rampa[1] if d > 8 else rampa[0])
                    pt(g, cx + dx, yy, cor, 240)
        for (dx, dy) in [(-7, -34), (6, -40), (8, -28), (-4, -46), (2, -52)]:
            pt(g, cx + dx, chao + dy, fagulha)
    g.alpha_composite(base, (cx - base.width // 2, chao + 3 - base.height + dy_base))
    fx, fy = cx - frente.width // 2, chao + 5 - frente.height
    if not aceso:
        if brilho.size == frente.size:
            g.alpha_composite(brilho, (fx, fy))
        else:
            g.alpha_composite(brilho, (cx - base.width // 2, chao + 3 - base.height + dy_base))
    g.alpha_composite(frente, (fx, fy))
    return g


def preview_moldura(disco, placa, m_placa, fogo_apagado, fogo_aceso):
    """346x130 = a caixa de preview da Loja, 1:1. Esquerda: o HUD como o jogo
    o desenha (nine-patch real). Direita: a fogueira apagada e acesa, x2."""
    W, H = 346, 130
    im = Image.new("RGBA", (W, H), FUNDO_PREVIEW + (255,))
    im.alpha_composite(nine(disco, 56, 56, (22, 22, 22, 22)), (8, 8))
    im.alpha_composite(nine(placa, 104, 50, m_placa), (8, 72))
    for i, g in enumerate((fogo_apagado, fogo_aceso)):
        # recorte 57x64 da fogueira (72x72), ampliado x2
        rec = g.crop((36 - 28, 72 - 66, 36 + 29, 72 - 2)).resize((114, 128), Image.NEAREST)
        im.alpha_composite(rec, (118 + i * 114, 1))
    return im


# =============================================================================
# RASTOS DO DASH
# =============================================================================
BR = [hexc("5A1A12"), hexc("B8321E"), hexc("F0702A"), hexc("FFC248"), hexc("FFF4D0")]
CINZA = [hexc("4A4248"), hexc("7A7076"), hexc("A89CA0")]


def faisca(tam, raio, calor):
    """Brasa em estrela de 4 pontas: miolo branco-quente, braços laranja, e o
    calor (1..0) a descer a rampa frame a frame."""
    c = nova(tam, tam)
    m = tam // 2
    for y in range(tam):
        for x in range(tam):
            dx, dy = abs(x - m), abs(y - m)
            # losango + braços em cruz (a estrela)
            d = min(dx + dy, (max(dx, dy) + 0.0) * (1.0 if min(dx, dy) == 0 else 9.0) * 0.62)
            if d > raio:
                continue
            k = (1.0 - d / (raio + 0.01)) * calor
            idx = min(4, int(k * 5.2))
            if idx < 0:
                continue
            pt(c, x, y, BR[idx])
    return c


def gerar_brasa():
    """particula_a: brasa 9x9 em 6 frames (acende, arde, arrefece, apaga em
    fumo). particula_b: floco de cinza 5x5 a rodar em 4 frames."""
    fa = [faisca(9, r, h) for (r, h) in [(1.6, 1.0), (3.2, 1.0), (4.2, 0.95), (3.6, 0.72), (2.6, 0.5), (1.4, 0.3)]]
    fb = []
    for linhas in [[".....", ".ab..", ".bc..", "..a..", "....."],
                   [".....", "..b..", ".acb.", "..a..", "....."],
                   [".....", "..ba.", "..cb.", "..a..", "....."],
                   [".....", ".....", ".bca.", ".....", "....."]]:
        fb.append(sprite(linhas, {"a": CINZA[0], "b": CINZA[1], "c": CINZA[2]}))
    return tira(fa), tira(fb)


ESP = [hexc("3E5028"), hexc("5E7A3A"), hexc("8FA043"), hexc("B8C24A"), hexc("E8F07A")]
FOLHA = {"d": hexc("2E2018"), "l": hexc("86664A"), "L": hexc("B08A5A"), "m": hexc("5E7A3A")}


def gerar_esporos():
    """particula_a: nuvem de esporos 13x13 em 6 frames -- 5 bolinhas
    sombreadas que se afastam do centro, incham e se desfazem em pontos.
    particula_b: folha morta 7x7 a rodopiar em 4 frames."""
    rng = random.Random(55)
    bolhas = [(rng.uniform(0, 6.28), rng.uniform(0.7, 1.0), rng.uniform(1.3, 2.0)) for _ in range(6)]
    fa = []
    for f in range(6):
        c = nova(13, 13)
        t = f / 5.0
        for ang, dist, r in bolhas:
            d = 0.8 + dist * 4.2 * t
            rr = r * (0.7 + 0.9 * math.sin(min(1.0, t * 1.6) * math.pi * 0.62))
            x, y = 6.5 + math.cos(ang) * d, 6.5 + math.sin(ang) * d - t * 1.5
            if f < 4:
                esfera(c, x, y, rr, rr, ESP[1:], [0.0, 0.45, 0.85], a=255 if f < 3 else 190)
            else:
                pt(c, int(x), int(y), ESP[4 - f + 3 if f == 4 else 2], 220 if f == 4 else 150)
        if f < 3:
            pt(c, 6, 6 - f, ESP[4])
        fa.append(c)
    fb = []
    for linhas in [[".......", "...d...", "..dLd..", ".dLlld.", "..dlm..", "...dd..", "....d.."],
                   [".......", ".......", ".ddd...", "dLLldd.", ".dllmd.", "...dd..", "......."],
                   [".......", "..d....", "..dd...", ".dLld..", ".dlmd..", "..dd...", "...d..."],
                   [".......", ".......", "...ddd.", ".ddlLLd", ".dmld..", "..dd...", "......."]]:
        fb.append(sprite(linhas, FOLHA))
    return tira(fa), tira(fb)


MA = {
    "k": hexc("1A1228"), "W": hexc("F6F8FF"), "w": hexc("C8D0F0"), "v": hexc("8E8AC8"),
    "V": hexc("5C528E"), "m": hexc("E040C8"), "b": hexc("2A2040"), "L": hexc("DCE4F6"),
}


def gerar_mariposas():
    """particula_a: mariposa lunar 13x9 em 4 frames (asas em cima, abertas,
    em baixo, abertas), asas de prata com o olho magenta. particula_b: pó de
    luar 5x5 a cintilar em 4 frames."""
    cima = [".kk.......kk.", "kwWk.....kWwk", "kwmwk...kwmwk", ".kwvvk.kvvwk.", "..kvvVkVvvk..",
            "...kkVbVkk...", "....kVbVk....", ".....kbk.....", "......k......"]
    meio = [".............", ".............", "kkk.......kkk", "kWwwk...kwwWk", "kwmvvkbkvvmwk",
            ".kvvVkbkVvvk.", "..kkVkbkVkk..", "....k.b.k....", "......k......"]
    baixo = [".............", ".............", ".............", ".....kbk.....", "..kkvkbkvkk..",
             ".kwvvVbVvvwk.", "kwmvvk.kvvmwk", "kWwwk...kwwWk", "kkk.......kkk"]
    for g in (cima, meio, baixo):
        assert all(len(l) == 13 for l in g), g
    fa = [sprite(g, MA) for g in (cima, meio, baixo, meio)]
    fb = [sprite(g, MA) for g in [
        [".....", ".....", "..L..", ".....", "....."],
        [".....", "..w..", ".wLw.", "..w..", "....."],
        ["..w..", ".....", "w.W.w", ".....", "..w.."],
        [".....", "..v..", ".v.v.", "..v..", "....."]]]
    return tira(fa), tira(fb)


def eco_silhueta(k, tinta, a):
    """O mesmo que o shader do eco no jogo (`rasto_cosmetico.gd`): a cor do
    frame puxada para a tinta (fica luminoso, sem perder o desenho)."""
    eco = nova(*k.size)
    px = k.load()
    for y in range(k.height):
        for x in range(k.width):
            r, g, b, aa = px[x, y]
            if aa > 0:
                c = tuple(int((v / 255.0 * t / 255.0 * 0.35 + t / 255.0 * 0.65) * 255) for v, t in zip((r, g, b), tinta))
                eco.putpixel((x, y), c + (int(aa * a),))
    return eco


def preview_rasto(fa, fb, n_a, n_b, tinta, seed, dispersao, deriva):
    """Koliani a meio do dash (frame golden real) com os ecos tingidos para
    trás e as partículas pelo caminho, como no jogo. Desenhado a 1:1 numa
    tela de 173x65 e ampliado x2 (346x130 = a caixa da Loja)."""
    W, H = 173, 65
    im = Image.new("RGBA", (W, H), FUNDO_PREVIEW + (255,))
    chao = H - 3
    for x in range(W):
        pt(im, x, chao, (0x33, 0x28, 0x3C))
        for y in range(chao + 1, H):
            pt(im, x, y, (0x1C, 0x14, 0x22))
    k = Image.open(KOLIANI_DASH).convert("RGBA")
    k = k.crop(k.getbbox())
    kx, ky = W - k.width - 6, chao + 1 - k.height
    # ecos: silhueta tingida, cada vez mais transparentes (como o `_rasto_dash`)
    for i, a in enumerate([0.16, 0.26, 0.38, 0.52]):
        im.alpha_composite(eco_silhueta(k, tinta, a), (kx - 104 + i * 26, ky))
    rng = random.Random(seed)
    wa, wb = fa.width // n_a, fb.width // n_b
    anima = n_a == 4        # as mariposas batem as asas em ciclo, não "envelhecem"
    parts = []
    for i in range(dispersao):
        # quanto mais longe da Koliani, mais velha a partícula (frame mais tardio)
        idade = rng.random()
        x = int(kx + 14 - idade * 120 + rng.randint(-5, 5))
        y = int(ky + 8 + rng.random() * (k.height - 20) - idade * deriva)
        if rng.random() < 0.7:
            f = rng.randint(0, n_a - 1) if anima else min(n_a - 1, int(idade * (n_a - 0.4)))
            parts.append((fa.crop((f * wa, 0, (f + 1) * wa, fa.height)), (x, y)))
        else:
            f = rng.randint(0, n_b - 1)
            parts.append((fb.crop((f * wb, 0, (f + 1) * wb, fb.height)), (x, y)))
    for p, xy in parts:
        im.alpha_composite(p, xy)
    im.alpha_composite(k, (kx, ky))
    return amp(im, 2)


# =============================================================================
def guardar(pasta, nome, im):
    os.makedirs(pasta, exist_ok=True)
    im.save(os.path.join(pasta, nome + ".png"), optimize=False)
    print("%-44s %dx%d" % (os.path.relpath(os.path.join(pasta, nome + ".png"), RAIZ), im.width, im.height))


def main():
    # --- Ossário
    d = os.path.join(SHOP, "ossario")
    disco, placa = moldura_ossario_disco(), moldura_ossario_placa()
    base, frente, brilho = ossario_fogueira()
    rampa = (hexc("E8FFF8"), hexc("9CF5E8"), hexc("37A3A6"))
    lenha = (hexc("8A8070"), hexc("5E5648"))
    fogos = [fogueira_preview(base, frente, brilho, a, rampa, lenha, 0, OSSO[4]) for a in (False, True)]
    for nome, im in [("moldura", disco), ("placa", placa), ("base", base), ("frente", frente),
                     ("brilho", brilho), ("preview", preview_moldura(disco, placa, (16, 14, 16, 14), *fogos))]:
        guardar(d, nome, im)
    # --- Gaiola de Aurora
    d = os.path.join(SHOP, "gaiola_aurora")
    disco, placa = moldura_gaiola_disco(), moldura_gaiola_placa()
    base, frente, brilho = gaiola_fogueira()
    rampa = (hexc("FFD8F6"), hexc("F070D8"), hexc("9B3FB0"))
    lenha = (hexc("2E2438"), hexc("1E1828"))
    fogos = [fogueira_preview(base, frente, brilho, a, rampa, lenha, 0, GA["L"]) for a in (False, True)]
    for nome, im in [("moldura", disco), ("placa", placa), ("base", base), ("frente", frente),
                     ("brilho", brilho), ("preview", preview_moldura(disco, placa, (16, 14, 16, 14), *fogos))]:
        guardar(d, nome, im)
    # --- Rastos
    for pasta, (fa, fb), (na, nb), tinta, seed, n, deriva in [
        ("brasa", gerar_brasa(), (6, 4), (255, 138, 52), 7, 26, 14),
        ("esporos", gerar_esporos(), (6, 4), (172, 200, 84), 8, 20, 6),
        ("mariposas", gerar_mariposas(), (4, 4), (196, 206, 255), 9, 14, 18),
    ]:
        d = os.path.join(SHOP, "rastos", pasta)
        guardar(d, "particula_a", fa)
        guardar(d, "particula_b", fb)
        guardar(d, "preview", preview_rasto(fa, fb, na, nb, tinta, seed, n, deriva))
    # --- Pack Luar de Aurora: a gaiola acesa + o rasto de mariposas
    fogo = Image.open(os.path.join(SHOP, "gaiola_aurora", "preview.png")).convert("RGBA").crop((232, 0, 346, 130))
    rasto = Image.open(os.path.join(SHOP, "rastos", "mariposas", "preview.png")).convert("RGBA").crop((114, 0, 346, 130))
    pack = Image.new("RGBA", (346, 130), FUNDO_PREVIEW + (255,))
    pack.alpha_composite(rasto, (114, 0))
    pack.alpha_composite(fogo, (0, 0))
    guardar(os.path.join(SHOP, "pack_luar_aurora"), "preview", pack)


if __name__ == "__main__":
    main()
