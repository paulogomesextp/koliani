#!/usr/bin/env python3
"""Revisao das ANIMACOES dos inimigos comuns/guardioes da Regiao II (N6-N10).

    python3 tools/animar_regiao02.py [especie ...] [--preview]

O PROBLEMA. O bestiario da Regiao II (`tools/extrair_inimigos_regiao02.py`)
trouxe da prancha aprovada UMA pose por estado: idle 2, run 2, attack/hit/dead
1 quadro cada. Pior: os quadros 'idle' e 'run' sao desenhos de tamanhos
diferentes (o golem 'idle' e' o dobro do 'run'), por isso o bicho saltitava de
tamanho em vez de se mexer. O Paulo (30 set 2026): "a arte esta de acordo com o
aprovado mas as animacoes sao fracas, precisam de mais movimento".

O QUE ISTO FAZ. Mesmo metodo da Regiao I (`tools/animar_criaturas_9h1.py`,
frames derivados autorizados pela 9H.1): a pose aprovada do IDLE e' a base e
ninguem desenha nada de novo -- so' translacoes, compressoes, cisalhamentos,
ondas por linha, rotacoes e pedacos soltos a mover-se cada um com a sua fase.
As poses de ATAQUE/MORTE que a prancha desenhou entram como o quadro-chave do
golpe e do fim (normalizadas para a escala da base). Nada de saltos de
tamanho: todos os quadros vivem na MESMA tela e a base e' sempre a mesma.

  idle 8 | run 8 | attack 6 | hit 4 | dead 8     (iguais para as 4 especies)

A base e as poses desenhadas ficam em `_origem/` (copiadas da 1.a execucao):
correr duas vezes da' o mesmo resultado. Hitboxes e IA nao mudam.
Cada tira tem a MESMA largura de quadro (o teste `teste_especies_dos_inimigos_existem`
exige-o) e o quadro 0 do idle e' a base, para a escala do jogo (medida nesse
quadro) ficar igual.
"""
import math
import os
import shutil
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PASTA = os.path.join(RAIZ, "assets/sprites/pixel/enemies")
PAD = 14
N = {"idle": 8, "run": 8, "attack": 6, "hit": 4, "dead": 8}
# strips originais: (n idle, n run) -> quadro 0 do idle e' a base
ORIG = {"morcego_dos_ventos": 2, "sentinela_flutuante": 2,
        "golem_aereo": 2, "elemental_do_vento": 2}
TAU = 2 * math.pi


# ------------------------------------------------------------------ base ---

def _tira(path, n):
    im = Image.open(path).convert("RGBA")
    w = im.width // n
    return [im.crop((i * w, 0, (i + 1) * w, im.height)) for i in range(n)]


def preparar_origem(esp):
    """Copia (so' da 1.a vez) a base e as poses desenhadas para `_origem/`."""
    pasta = os.path.join(PASTA, esp)
    og = os.path.join(pasta, "_origem")
    if not os.path.isdir(og):
        os.makedirs(og)
        _tira(os.path.join(pasta, "idle.png"), 2)[0].save(os.path.join(og, "base.png"))
        for nome in ("attack", "hit", "dead"):
            _tira(os.path.join(pasta, nome + ".png"), 1)[0].save(os.path.join(og, nome + ".png"))
    return {k: np.array(Image.open(os.path.join(og, k + ".png")).convert("RGBA"))
            for k in ("base", "attack", "hit", "dead")}


def pad(a, p=PAD):
    return np.pad(a, ((p, p), (p, p), (0, 0)))


def bbox(a):
    ys, xs = np.nonzero(a[..., 3] > 40)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def normalizar_pose(pose, base):
    """Poe uma pose desenhada na escala e no centro da base (tela com PAD)."""
    bx0, by0, bx1, by1 = bbox(base)
    px0, py0, px1, py1 = bbox(pose)
    area_b = (bx1 - bx0) * (by1 - by0)
    area_p = (px1 - px0) * (py1 - py0)
    k = float(np.clip(math.sqrt(area_b / area_p), 0.7, 1.7))
    rec = Image.fromarray(pose[py0:py1, px0:px1]).convert("RGBA")
    rec = rec.resize((max(1, round(rec.width * k)), max(1, round(rec.height * k))), Image.NEAREST)
    saida = np.zeros_like(base)
    cx, cy = (bx0 + bx1) // 2, (by0 + by1) // 2
    x = cx - rec.width // 2
    y = cy - rec.height // 2
    ra = np.array(rec)
    H, W = saida.shape[:2]
    xa, ya = max(0, x), max(0, y)
    xb, yb = min(W, x + rec.width), min(H, y + rec.height)
    saida[ya:yb, xa:xb] = ra[ya - y:yb - y, xa - x:xb - x]
    return saida


# ---------------------------------------------------------------- primitivas ---

def warp(src, fn):
    """Mapeamento INVERSO: para cada pixel de saida, fn(yy, xx) -> (sy, sx)."""
    H, W = src.shape[:2]
    yy, xx = np.mgrid[0:H, 0:W].astype(float)
    sy, sx = fn(yy, xx)
    sy = np.rint(sy).astype(int)
    sx = np.rint(sx).astype(int)
    ok = (sy >= 0) & (sy < H) & (sx >= 0) & (sx < W)
    out = np.zeros_like(src)
    out[ok] = src[sy[ok], sx[ok]]
    return out


def mover(src, dx, dy):
    return warp(src, lambda y, x: (y - dy, x - dx))


def escalar(src, sx, sy, cx, cy):
    """Escala a volta de (cx, cy)."""
    return warp(src, lambda y, x: (cy + (y - cy) / sy, cx + (x - cx) / sx))


def cisalhar(src, k, y_fixo, altura):
    """Desloca x em `k` px por `altura` px acima de y_fixo (topo anda, base fica)."""
    return warp(src, lambda y, x: (y, x - k * (y_fixo - y) / altura))


def onda(src, amp, y0, y1, fase, ondas=1.0):
    """Onda horizontal por linha em [y0,y1]; peso 0 em y0, cheio em y1."""
    def f(y, x):
        t = np.clip((y - y0) / max(1.0, y1 - y0), 0, 1)
        return y, x - amp * t * np.sin(TAU * (ondas * t + fase))
    return warp(src, f)


def girar(src, graus, cx, cy):
    im = Image.fromarray(src)
    im = im.rotate(graus, resample=Image.NEAREST, center=(cx, cy))
    return np.array(im)


def alfa(src, k):
    out = src.copy()
    out[..., 3] = (out[..., 3] * np.clip(k, 0, 1)).astype(np.uint8)
    return out


def dissolver(src, frac, semente=1, de_cima=False):
    """Apaga pixeis ao acaso (mais depressa para cima ou para baixo)."""
    rng = np.random.RandomState(semente)
    ruido = rng.rand(*src.shape[:2])
    H = src.shape[0]
    yy = np.arange(H)[:, None] / float(H)
    grad = (1.0 - yy) if de_cima else yy
    lim = frac * (0.6 + 0.8 * grad) * 1.3
    out = src.copy()
    out[ruido < lim, 3] = 0
    return out


def pecas(base, dil=2, area_min=6):
    """Pedacos soltos (componentes ligados) -> lista de mascaras."""
    m = base[..., 3] > 40
    lab, n = ndi.label(ndi.binary_dilation(m, iterations=dil))
    lab = lab * m
    out = []
    for k in range(1, n + 1):
        mk = lab == k
        if mk.sum() >= area_min:
            out.append(mk)
    # pixeis soltos que sobraram vao para a peca mais proxima
    if out:
        tudo = np.any(out, axis=0)
        resto = m & ~tudo
        if resto.any():
            _, (iy, ix) = ndi.distance_transform_edt(~tudo, return_indices=True)
            idx = np.full(m.shape, -1)
            for k, mk in enumerate(out):
                idx[mk] = k
            near = idx[iy, ix]
            for k in range(len(out)):
                out[k] = out[k] | (resto & (near == k))
    return out


def pedras(base, k):
    """Parte um corpo de pedras coladas em `k` blocos (k-medias, semente fixa)."""
    from scipy.cluster.vq import kmeans2
    ys, xs = np.nonzero(base[..., 3] > 40)
    pts = np.stack([xs, ys], 1).astype(float)
    np.random.seed(3)
    cen, lab = kmeans2(pts, k, minit="++", seed=3)
    out = []
    for i in range(k):
        mk = np.zeros(base.shape[:2], bool)
        sel = lab == i
        mk[ys[sel], xs[sel]] = True
        if mk.any():
            out.append(mk)
    return out


def compor(base, mascaras, desloc, escalas=None, centro=None):
    """Cola cada peca deslocada (dx, dy) por cima, da maior para a menor."""
    H, W = base.shape[:2]
    out = np.zeros_like(base)
    ordem = sorted(range(len(mascaras)), key=lambda k: -mascaras[k].sum())
    for k in ordem:
        dx, dy = desloc[k]
        peca = np.where(mascaras[k][..., None], base, 0).astype(np.uint8)
        if escalas is not None and centro is not None:
            peca = escalar(peca, escalas, escalas, centro[0], centro[1])
        peca = mover(peca, int(round(dx)), int(round(dy)))
        mk = peca[..., 3] > 0
        out[mk] = peca[mk]
    return out


# ----------------------------------------------------------------- especies ---

def s(t, ph=0.0):
    """Seno que vale 0 em t=0 se ph=0; usar `s(t,ph)-s(0,ph)` p/ loops."""
    return math.sin(TAU * t + ph)


def ciclo(t, ph=0.0):
    return s(t, ph) - s(0.0, ph)


def morcego(P):
    b = pad(P["base"])
    H, W = b.shape[:2]
    x0, y0, x1, y1 = bbox(b)
    cx = (x0 + x1) / 2.0
    hw = (x1 - x0) / 2.0
    cy = (y0 + y1) / 2.0

    def asas(src, a, amp):
        """a em [-1,1]: +1 = asas em baixo, -1 = em cima."""
        # asa em baixo (a>0): pontas descem -> amostra de cima -> sy = y - dy
        def g(y, x):
            d = np.clip(np.abs(x - cx) / hw, 0, 1)
            enc = 1.0 - 0.14 * abs(a) * d
            return y - a * amp * d ** 1.4, cx + (x - cx) / enc
        return warp(src, g)

    def quadro(a, amp, dx=0, dy=0, incl=0.0, sy=1.0, sx=1.0):
        im = asas(b, a, amp)
        if sx != 1.0 or sy != 1.0:
            im = escalar(im, sx, sy, cx, cy)
        if incl:
            im = girar(im, incl, cx, cy)
        return mover(im, dx, dy)

    F = {}
    F["idle"] = [quadro(s(i / 8), 11, dy=-round(s(i / 8) * 3)) for i in range(8)]
    F["run"] = [quadro(s(i / 8), 15, dx=1, dy=-round(s(i / 8) * 4), incl=-8) for i in range(8)]
    golpe = normalizar_pose(P["attack"], b)
    F["attack"] = [
        quadro(-1.0, 8, dx=-3, dy=-2, incl=14, sy=1.06),       # arma-se: asas no alto, recua
        quadro(-1.0, 9, dx=-5, dy=-3, incl=18, sy=1.08, sx=0.94),
        mover(golpe, 3, 1),                                     # a pose desenhada da investida
        mover(golpe, 9, 3),
        quadro(0.7, 7, dx=6, dy=2, incl=-12, sx=1.05),
        quadro(0.2, 5, dx=2, dy=0, incl=-4),
    ]
    F["hit"] = [
        quadro(-0.8, 7, dx=-4, dy=-2, incl=16, sx=0.9),
        quadro(0.6, 6, dx=-5, dy=1, incl=22, sx=0.88),
        quadro(-0.3, 5, dx=-2, incl=8),
        quadro(0.0, 3, dx=-1, incl=2),
    ]
    mortoP = normalizar_pose(P["dead"], b)
    F["dead"] = [
        mover(quadro(-1.0, 6, dy=0, incl=20), -2, 0),
        mover(mortoP, -2, 0),
        mover(girar(mortoP, 35, cx, cy), -3, 4),
        mover(girar(mortoP, 80, cx, cy), -4, 11),
        mover(girar(mortoP, 120, cx, cy), -4, 19),
        mover(girar(mortoP, 160, cx, cy), -4, 27),
        alfa(mover(girar(mortoP, 200, cx, cy), -4, 33), 0.6),
        alfa(mover(girar(mortoP, 235, cx, cy), -4, 38), 0.25),
    ]
    return b, F


def sentinela(P):
    b = pad(P["base"])
    H, W = b.shape[:2]
    x0, y0, x1, y1 = bbox(b)
    cx = (x0 + x1) // 2
    h = y1 - y0
    saia0 = y0 + int(h * 0.55)

    def q(dy=0, dx=0, incl=0.0, saia=0.0, fase=0.0, sy=1.0, sx=1.0, arrasto=0.0):
        im = b
        if saia:
            im = onda(im, saia, saia0, y1, fase, 1.1)
        if arrasto:
            im = cisalhar(im, -arrasto, y1, h) if False else warp(
                im, lambda y, x: (y, x + arrasto * np.clip((y - saia0) / (y1 - saia0), 0, 1)))
        if incl:
            im = cisalhar(im, incl, y1, h)
        if sx != 1.0 or sy != 1.0:
            im = escalar(im, sx, sy, cx, y1)
        return mover(im, dx, dy)

    F = {}
    F["idle"] = [q(dy=-round(ciclo(i / 8) * 2.2), saia=2.4, fase=i / 8, incl=ciclo(i / 8, 1.0) * 0.9)
                 for i in range(8)]
    F["run"] = [q(dy=-round(abs(s(i / 8)) * 2.5), dx=1, incl=4.5 + s(i / 8) * 0.8,
                  saia=2.6, fase=i / 8 * 2, arrasto=-4) for i in range(8)]
    golpe = normalizar_pose(P["attack"], b)
    F["attack"] = [
        q(dy=-1, dx=-2, incl=-3.5, saia=1.5, sy=1.03),
        q(dy=-2, dx=-4, incl=-6, saia=2.0, sy=1.05, sx=0.96),
        mover(golpe, 5, 0),
        q(dy=1, dx=8, incl=8, arrasto=-5, sx=1.04, sy=0.97),
        q(dy=0, dx=5, incl=5, saia=2.5, fase=0.3, arrasto=-3),
        q(dy=0, dx=1, incl=1.5, saia=2.0, fase=0.6),
    ]
    F["hit"] = [
        q(dx=-4, incl=-6, sx=0.93, sy=1.04),
        q(dx=-6, dy=1, incl=-8, sx=0.9, sy=1.05, saia=2.5),
        q(dx=-3, incl=-3.5, saia=2.0, fase=0.5),
        q(dx=-1, incl=-1, saia=1.2),
    ]
    mortoP = normalizar_pose(P["dead"], b)
    F["dead"] = [
        q(dx=-3, incl=-7, sy=1.04),
        mover(mortoP, -3, 1),
        dissolver(mover(escalar(mortoP, 1.0, 0.94, cx, y1), -3, 3), 0.10, 3),
        dissolver(mover(escalar(mortoP, 1.04, 0.84, cx, y1), -3, 6), 0.25, 3),
        dissolver(mover(escalar(mortoP, 1.1, 0.7, cx, y1), -3, 10), 0.45, 3),
        dissolver(mover(escalar(mortoP, 1.2, 0.5, cx, y1), -3, 15), 0.65, 3),
        dissolver(mover(escalar(mortoP, 1.3, 0.3, cx, y1), -3, 20), 0.85, 3),
        dissolver(mover(escalar(mortoP, 1.4, 0.15, cx, y1), -3, 24), 0.95, 3),
    ]
    return b, F


def golem(P):
    b = pad(P["base"])
    x0, y0, x1, y1 = bbox(b)
    cx, cy = (x0 + x1) / 2.0, (y0 + y1) / 2.0
    ms = pedras(b, 12)
    n = len(ms)
    rng = np.random.RandomState(7)
    fase = rng.rand(n) * TAU
    ampx = 0.8 + rng.rand(n) * 1.4
    ampy = 1.2 + rng.rand(n) * 1.6
    cent = [np.array(ndi.center_of_mass(m))[::-1] for m in ms]

    def q(t, k_amp=1.0, dx=0.0, dy=0.0, junta=0.0, incl=0.0, extra=None):
        d = []
        for k in range(n):
            ox = (math.sin(TAU * t + fase[k]) - math.sin(fase[k])) * ampx[k] * k_amp
            oy = (math.sin(TAU * 2 * t + fase[k]) - math.sin(fase[k])) * ampy[k] * k_amp
            vx, vy = cent[k][0] - cx, cent[k][1] - cy
            ox += -vx * junta + dx
            oy += -vy * junta + dy
            if incl:
                ox += incl * (cy - cent[k][1]) / 20.0
            if extra:
                ex, ey = extra(k)
                ox += ex
                oy += ey
            d.append((ox, oy))
        return compor(b, ms, d)

    F = {}
    F["idle"] = [q(i / 8, 1.0, dy=-ciclo(i / 8, 0.0) * 1.6) for i in range(8)]
    F["run"] = [q(i / 8, 1.6, dx=1.5, dy=-abs(s(i / 8)) * 3, incl=2.2) for i in range(8)]
    golpe = normalizar_pose(P["attack"], b)
    F["attack"] = [
        q(0.1, 0.4, dx=-2, dy=-1, junta=0.12),                   # contrai-se
        q(0.2, 0.3, dx=-4, dy=-3, junta=-0.22),                  # desdobra-se no ar
        mover(golpe, 3, 0),                                      # pose desenhada: o punho cai
        q(0.5, 0.6, dx=6, dy=3, junta=-0.10, incl=3),            # o baque: pedras abrem
        q(0.7, 0.8, dx=3, dy=1, junta=-0.05, incl=1.5),
        q(0.9, 0.9, dx=1, junta=0.0),
    ]
    F["hit"] = [
        q(0.0, 0.5, dx=-4, dy=-1, junta=-0.14),
        q(0.2, 0.5, dx=-6, dy=1, junta=-0.20),
        q(0.4, 0.6, dx=-3, junta=-0.07),
        q(0.6, 0.8, dx=-1, junta=-0.02),
    ]
    mortoP = normalizar_pose(P["dead"], b)
    cm = ms  # as pecas da pose de morte caem cada uma a sua
    mm = pecas(mortoP)
    nm = len(mm)
    rng2 = np.random.RandomState(11)
    vx = (rng2.rand(nm) - 0.5) * 1.6
    cm_ = [np.array(ndi.center_of_mass(m))[::-1] for m in mm]
    F["dead"] = [q(0.0, 0.5, dx=-3, junta=-0.16), mortoP]
    for i in range(6):
        t = i + 1
        d = []
        for k in range(nm):
            gx = vx[k] * t * 1.4 + (cm_[k][0] - cx) * 0.05 * t
            gy = 0.9 * t * t * (0.6 + 0.8 * (k % 3) / 2.0)
            d.append((gx - 2, gy))
        im = compor(mortoP, mm, d)
        F["dead"].append(alfa(dissolver(im, min(0.9, 0.12 * t), 5), 1.0 - 0.1 * t))
    return b, F


def elemental(P):
    b = pad(P["base"])
    x0, y0, x1, y1 = bbox(b)
    cx = (x0 + x1) / 2.0
    h = y1 - y0

    def q(t, amp=3.0, dx=0.0, dy=0.0, sx=1.0, sy=1.0, incl=0.0, voltas=1.0, torce=0.0):
        im = warp(b, lambda y, x: (y, x - amp * np.clip((y1 - y) / h, 0, 1) ** 0.9
                                    * (np.sin(TAU * (t + voltas * (y - y0) / h)) - np.sin(TAU * voltas * (y - y0) / h))))
        if torce:
            im = onda(im, torce, y0, y1, t, 1.5)
        if sx != 1.0 or sy != 1.0:
            im = escalar(im, sx, sy, cx, y1)
        if incl:
            im = cisalhar(im, incl, y1, h)
        return mover(im, dx, dy)

    F = {}
    F["idle"] = [q(i / 8, 2.6, dy=-round(ciclo(i / 8) * 1.5), sx=1 + ciclo(i / 8, 0.5) * 0.015)
                 for i in range(8)]
    F["run"] = [q(i / 8 * 2, 3.4, dx=1, dy=-round(abs(s(i / 8)) * 1.5), incl=5.0, voltas=1.5)
                for i in range(8)]
    golpe = normalizar_pose(P["attack"], b)
    F["attack"] = [
        q(0.1, 2.0, dx=-3, sx=0.86, sy=1.08, incl=-4),           # aperta-se
        q(0.3, 1.6, dx=-5, sx=0.78, sy=1.14, incl=-6),
        mover(golpe, 4, 0),                                       # a pose desenhada
        q(0.6, 4.6, dx=8, sx=1.22, sy=0.94, incl=9, voltas=2.0),  # alarga e varre
        q(0.8, 3.6, dx=4, sx=1.1, sy=0.98, incl=4),
        q(0.95, 2.8, dx=1, sx=1.03),
    ]
    F["hit"] = [
        q(0.0, 3.0, dx=-4, sx=0.9, sy=1.05, incl=-6),
        q(0.3, 4.0, dx=-6, dy=1, sx=0.84, sy=1.07, incl=-9, torce=2.0),
        q(0.6, 3.2, dx=-3, sx=0.95, incl=-4),
        q(0.8, 2.6, dx=-1, incl=-1),
    ]
    mortoP = normalizar_pose(P["dead"], b)
    F["dead"] = []
    for i in range(8):
        t = i / 7.0
        im = mortoP if i else q(0.0, 3.0, dx=-2, sx=0.9)
        im = escalar(im, 1.0 + 0.35 * t, 1.0 - 0.45 * t, cx, y1)
        im = warp(im, lambda y, x, tt=t: (y, x - 3.0 * np.sin(TAU * (tt * 1.5 + (y - y0) / h)) * tt * 2))
        im = dissolver(im, 0.12 + 0.85 * t, 9, de_cima=True)
        F["dead"].append(alfa(im, 1.0 - 0.6 * t))
    return b, F


ESPECIES = {"morcego_dos_ventos": morcego, "sentinela_flutuante": sentinela,
            "golem_aereo": golem, "elemental_do_vento": elemental}


def gravar(esp, F, b):
    pasta = os.path.join(PASTA, esp)
    H, W = b.shape[:2]
    for nome, n in N.items():
        quadros = F[nome]
        assert len(quadros) == n, (esp, nome, len(quadros))
        tira = Image.new("RGBA", (W * n, H), (0, 0, 0, 0))
        for i, q in enumerate(quadros):
            if nome == "idle" and i == 0:
                q = b      # quadro 0 do idle = a base, intacta (escala do jogo)
            tira.alpha_composite(Image.fromarray(q.astype(np.uint8)), (i * W, 0))
        tira.save(os.path.join(pasta, nome + ".png"))


def previa(esp, F, b):
    out = os.path.join(RAIZ, "work/previa_r2")
    os.makedirs(out, exist_ok=True)
    H, W = b.shape[:2]
    linhas = []
    for nome in N:
        fr = F[nome]
        r = Image.new("RGBA", (W * 8 * 3, H * 3), (36, 36, 56, 255))
        for i, q in enumerate(fr):
            r.alpha_composite(Image.fromarray(q.astype(np.uint8)).resize((W * 3, H * 3), Image.NEAREST),
                              (i * W * 3, 0))
        linhas.append(r)
    sh = Image.new("RGBA", (linhas[0].width, sum(l.height for l in linhas)), (36, 36, 56, 255))
    y = 0
    for l in linhas:
        sh.paste(l, (0, y))
        y += l.height
    sh.save(os.path.join(out, esp + ".png"))


def guardiao_idle(n=10):
    """Guardiao dos Ceus (N10): o idle tinha 6 quadros com 2 pares REPETIDOS
    (diferenca 0 entre 1-2 e 4-5): parecia a engasgar. Refaz-se como ciclo
    continuo -- bater de asas lento + respirar + corpo a balouçar -- a partir
    do quadro 0 original (guardado em `_origem/`). Actualiza `rigs.json`."""
    import json
    pasta = os.path.join(RAIZ, "assets/sprites/pixel/bosses_anim/guardiao_dos_ceus")
    og = os.path.join(pasta, "_origem")
    rigs_p = os.path.join(RAIZ, "assets/sprites/pixel/bosses_anim/rigs.json")
    rigs = json.load(open(rigs_p))
    r = rigs["guardiao_dos_ceus"]
    if not os.path.isdir(og):
        os.makedirs(og)
        w = r["w"]
        Image.open(os.path.join(pasta, "idle.png")).convert("RGBA").crop((0, 0, w, r["h"])).save(
            os.path.join(og, "idle0.png"))
        open(os.path.join(og, ".gdignore"), "w").close()
    b = np.array(Image.open(os.path.join(og, "idle0.png")).convert("RGBA"))
    x0, y0, x1, y1 = bbox(b)
    cx, cy = (x0 + x1) / 2.0, y0 + (y1 - y0) * 0.45
    hw = (x1 - x0) / 2.0
    Hh, Ww = b.shape[:2]
    quadros = []
    for i in range(n):
        t = i / float(n)
        a = ciclo(t)                     # batida: 0 em t=0 (quadro 0 = original)
        bob = ciclo(t, 0.9)

        def g(y, x, a=a):
            d = np.clip(np.abs(x - cx) / hw, 0, 1)
            enc = 1.0 - 0.07 * abs(a) * d
            return y - a * 9.0 * d ** 1.5, cx + (x - cx) / enc
        im = warp(b, g)
        im = escalar(im, 1.0 - 0.01 * bob, 1.0 + 0.015 * bob, cx, y1)
        im = mover(im, 0, -round(bob * 2.5))
        quadros.append(im)
    tira = Image.new("RGBA", (Ww * n, Hh), (0, 0, 0, 0))
    for i, q in enumerate(quadros):
        tira.alpha_composite(Image.fromarray(q.astype(np.uint8)), (i * Ww, 0))
    tira.save(os.path.join(pasta, "idle.png"))
    r["estados"]["idle"] = n
    r["fps"]["idle"] = 10.0
    json.dump(rigs, open(rigs_p, "w"), indent=1)
    print("guardiao_dos_ceus idle", n)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if "--guardiao" in sys.argv:
        guardiao_idle()
        sys.exit(0)
    alvo = args or list(ESPECIES)
    for esp in alvo:
        P = preparar_origem(esp)
        b, F = ESPECIES[esp](P)
        if "--preview" in sys.argv:
            previa(esp, F, b)
        else:
            gravar(esp, F, b)
        print(esp, "ok", b.shape)
