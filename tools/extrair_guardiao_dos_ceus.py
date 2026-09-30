#!/usr/bin/env python3
"""Monta o rig do GUARDIAO DOS CEUS (N10) A PARTIR DA PRANCHA APROVADA.

    python3 tools/extrair_guardiao_dos_ceus.py [--preview]

O rig anterior (`gerar_chefes_anim.py`) desenhava o corvideo com poligonos
lisos -- aves de "caixas" ao lado da prancha, que tem penas, bico, garras e
nucleo violeta pintados a sério. A linha ANIMACOES (SPRITES) do
`boss_pack.png` traz as poses nomeadas pelo contrato: idle asa fechada, idle
asa aberta, andar/ajuste, voo (loop), pousar, levantar voo, hurt 1/2 e
morte. Recorta-se cada uma (fundo -> alfa, des-premultiplicado), alinha-se
pelo OLHO/NUCLEO (ancora do contrato, L4/L7) e montam-se as tiras com essas
poses reais mais movimento de corpo (bob, squash, inclinacao).

Escreve `assets/sprites/pixel/bosses_anim/guardiao_dos_ceus/*.png` e a
entrada em `rigs.json`.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRANCHA = os.path.join(RAIZ, "docs/art_direction/regions/region_02", "boss_pack.png")
DESTINO = os.path.join(RAIZ, "assets/sprites/pixel/bosses_anim/guardiao_dos_ceus")
RIGS_JSON = os.path.join(RAIZ, "assets/sprites/pixel/bosses_anim/rigs.json")

FUNDO = np.array([3, 13, 21])
ALFA_ZERO, ALFA_CHEIO = 14, 46
AREA_MIN = 25
W, H = 340, 280
ESC = 1.23                 # prancha -> ecra (asa aberta = 240 px, o tecto do teste)
ANCORA = (170, 120)        # onde cai o olho em todos os frames

# caixas (x0, y0, x1, y1) em px da prancha; y ate' 447 (abaixo: legendas)
POSES = {
    "fechada1": (14, 346, 62, 447),
    "fechada2": (63, 346, 106, 447),
    "fechada3": (106, 346, 168, 447),
    "aberta": (174, 345, 372, 447),
    "andar_a": (376, 352, 506, 447),
    "andar_b": (507, 345, 566, 447),
    "voo": (567, 352, 712, 447),
    "pousar": (706, 352, 860, 447),
    "levantar": (868, 345, 1040, 447),
    "hurt1": (1062, 352, 1192, 447),
    "hurt2": (1195, 352, 1338, 447),
    "morte": (1338, 352, 1525, 447),
}


def recortar(src, box):
    x0, y0, x1, y1 = box
    c = src[y0:y1, x0:x1]
    d = np.abs(c - FUNDO).sum(2)
    m = d > 45
    lab, n = ndi.label(ndi.binary_dilation(m, iterations=2))
    areas = ndi.sum(m, lab, range(1, n + 1))
    keep = np.zeros_like(m)
    for k in range(1, n + 1):
        if areas[k - 1] >= AREA_MIN:
            keep |= (lab == k)
    alfa = np.clip((d - ALFA_ZERO) / float(ALFA_CHEIO - ALFA_ZERO), 0, 1) * keep
    a3 = np.maximum(alfa, 1e-3)[..., None]
    cor = np.clip((c - FUNDO * (1 - a3)) / a3, 0, 255)
    # olho/nucleo: o ponto violeta mais brilhante (b alto, g baixo)
    roxo = (c[..., 2] - c[..., 1]) * (c[..., 0] > 120) * (c[..., 2] > 200) * keep
    if roxo.max() > 0:
        ys, xs = np.nonzero(roxo >= roxo.max() * 0.85)
        olho = (xs.mean(), ys.mean())
    else:
        olho = None
    ys, xs = np.nonzero(alfa > 0.05)
    return cor, alfa, olho, (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)


def pose(src, nome, esc=ESC):
    cor, alfa, olho, bb = recortar(src, POSES[nome])
    x0, y0, x1, y1 = bb
    rgba = np.zeros((y1 - y0, x1 - x0, 4), np.float32)
    rgba[..., :3] = cor[y0:y1, x0:x1] * alfa[y0:y1, x0:x1, None]
    rgba[..., 3] = alfa[y0:y1, x0:x1] * 255
    rgba[..., :3] = rgba[..., :3]          # pre-multiplicado
    gw, gh = int(round((x1 - x0) * esc)), int(round((y1 - y0) * esc))
    ch = [np.array(Image.fromarray(rgba[..., i], "F").resize((gw, gh), Image.LANCZOS))
          for i in range(4)]
    out = np.stack(ch, -1)
    al = np.maximum(out[..., 3:4], 1e-3)
    out[..., :3] = np.clip(out[..., :3] / al * 255 * 1.0, 0, 255)
    out[..., 3] = np.clip(out[..., 3], 0, 255)
    out[out[..., 3] < 12] = 0
    img = Image.fromarray(out.astype(np.uint8), "RGBA")
    if olho is None:
        olho = ((x0 + x1) / 2.0, (y0 + y1) / 2.0)
    ox = (olho[0] - x0) * esc
    oy = (olho[1] - y0) * esc
    return {"img": img, "olho": (ox, oy), "nome": nome}


def tela_com(p, dx=0.0, dy=0.0, rot=0.0, esc=1.0, alfa=1.0, flash=0.0, brilho=0.0):
    img = p["img"]
    ox, oy = p["olho"]
    if flash > 0 or brilho:
        a = np.array(img).astype(np.float32)
        if flash > 0:
            for i in range(3):
                a[..., i] += (255 - a[..., i]) * flash
        if brilho:
            roxo = np.clip((a[..., 2] - a[..., 1] - 60) / 90.0, 0, 1) * (a[..., 3] > 0)
            for i, g in enumerate((70, 20, 40)):
                a[..., i] = np.clip(a[..., i] + roxo * g * brilho, 0, 255)
        img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    if esc != 1.0:
        img = img.resize((max(1, int(img.width * esc)), max(1, int(img.height * esc))),
                         Image.LANCZOS)
        ox, oy = ox * esc, oy * esc
    if abs(rot) > 0.01:
        # roda em torno do olho: expande e recalcula a ancora
        w0, h0 = img.size
        big = Image.new("RGBA", (w0 * 2, h0 * 2), (0, 0, 0, 0))
        big.paste(img, (int(w0 - ox), int(h0 - oy)))
        big = big.rotate(rot, resample=Image.BICUBIC, center=(w0, h0))
        img, ox, oy = big, float(w0), float(h0)
    if alfa < 1.0:
        a = np.array(img).astype(np.float32)
        a[..., 3] *= alfa
        img = Image.fromarray(a.astype(np.uint8), "RGBA")
    tela = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    tela.paste(img, (int(round(ANCORA[0] + dx - ox)), int(round(ANCORA[1] + dy - oy))))
    return tela


def tira(quadros):
    t = Image.new("RGBA", (W * len(quadros), H), (0, 0, 0, 0))
    for i, q in enumerate(quadros):
        t.paste(q, (i * W, 0))
    return t


def main():
    src = np.array(Image.open(PRANCHA).convert("RGB")).astype(int)
    P = {n: pose(src, n) for n in POSES}
    for n, p in P.items():
        print(n, p["img"].size, "olho", tuple(round(v) for v in p["olho"]))

    def bob(i, n, a=4.0):
        return math.sin(2 * math.pi * i / n) * a

    idle = [tela_com(P["aberta"], dy=bob(i, 6), brilho=0.4 * math.sin(2 * math.pi * i / 6))
            for i in range(6)]
    # bater de asas: aberta -> levantar (asas para cima) -> aberta -> voo (para baixo)
    walk = []
    seq = ["aberta", "levantar", "aberta", "voo", "aberta", "andar_a", "andar_b", "andar_a"]
    for i, nm in enumerate(seq):
        walk.append(tela_com(P[nm], dy=bob(i, 8, 5.0)))
    attack = [  # preparacao (recolhe) -> levantar -> mergulho (voo, inclinado) -> impacto
        tela_com(P["aberta"], dy=-2, brilho=0.4),
        tela_com(P["levantar"], dy=-8, brilho=0.8),
        tela_com(P["levantar"], dy=-16, brilho=1.0),
        tela_com(P["levantar"], dy=-20, rot=0, brilho=1.0),
        tela_com(P["voo"], dy=-6, brilho=1.0),
        tela_com(P["voo"], dx=14, dy=12, rot=-12, brilho=0.8),
        tela_com(P["voo"], dx=22, dy=26, rot=-18, brilho=0.6),
        tela_com(P["pousar"], dx=10, dy=22, brilho=0.4),
        tela_com(P["pousar"], dy=14),
        tela_com(P["aberta"], dy=4),
    ]
    hurt = [tela_com(P["hurt1"], flash=0.55), tela_com(P["hurt1"], dx=-6, flash=0.2),
            tela_com(P["hurt2"], dx=-4), tela_com(P["hurt2"], dx=-1)]
    death = [tela_com(P["hurt2"], flash=0.5), tela_com(P["hurt2"], dy=4)]
    mort = P["morte"]
    for i in range(8):
        u = i / 7.0
        death.append(tela_com(mort, dy=6 * u, esc=1.0 + 0.04 * u, alfa=1.0 - 0.75 * u * u))
    estados = {"idle": idle, "walk": walk, "attack": attack, "hurt": hurt, "death": death}

    os.makedirs(DESTINO, exist_ok=True)
    for nome, q in estados.items():
        t = tira(q)
        t.save(os.path.join(DESTINO, nome + ".png"))
        if "--preview" in sys.argv:
            f = Image.new("RGBA", t.size, (40, 52, 82, 255))
            f.alpha_composite(t)
            f.convert("RGB").save(os.path.join(os.environ.get("PREVIEW_DIR", "/tmp"),
                                               "gd_%s.png" % nome))
    with open(RIGS_JSON, encoding="utf-8") as f:
        rigs = json.load(f)
    rigs["guardiao_dos_ceus"] = {
        "w": W, "h": H, "pes_y": 235,
        "estados": {n: len(q) for n, q in estados.items()},
        "fps": {"idle": 7.0, "walk": 11.0, "attack": 12.0, "hurt": 12.0, "death": 9.0},
    }
    with open(RIGS_JSON, "w", encoding="utf-8") as f:
        json.dump(rigs, f, indent=1, ensure_ascii=False)
        f.write("\n")


if __name__ == "__main__":
    main()
