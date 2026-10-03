#!/usr/bin/env python3
"""Monta o rig do GUARDIAO DA FORNALHA (N20) A PARTIR DA PRANCHA APROVADA.

    python3 tools/extrair_guardiao_da_fornalha.py [--preview]

Prancha: docs/art_direction/regions/region_04/boss_pack.png, painel
"SPRITES PRINCIPAIS (EXEMPLOS)": idle, andar, preparacao de ataque, ataque,
dano, transicao (fase 2) e derrota. Recorta-se cada pose (fundo -> alfa por
inundacao a partir da borda, para a armadura escura nao ficar furada),
alinha-se pelos PES (centro da zona dos pes) e montam-se as tiras com essas
poses reais mais movimento de corpo (respiracao, pancada, brilho do nucleo).
O rig mantem a escala relativa entre poses (o martelo e' maior que o corpo
em repouso, como na prancha).

Escreve `assets/sprites/pixel/bosses_anim/guardiao_da_fornalha/*.png` e a
entrada em `rigs.json`. A prancha e' a fonte; nada e' redesenhado.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRANCHA = os.path.join(RAIZ, "docs/art_direction/regions/region_04", "boss_pack.png")
DESTINO = os.path.join(RAIZ, "assets/sprites/pixel/bosses_anim/guardiao_da_fornalha")
RIGS_JSON = os.path.join(RAIZ, "assets/sprites/pixel/bosses_anim/rigs.json")

W, H = 520, 260
ESC = 2.9
PES = (260, 240)           # (x, y) onde caem os pes em todos os frames

# caixas (x0, y0, x1, y1) em px da prancha; acima da linha de chao (y=302)
POSES = {
    "idle": (663, 239, 742, 302),
    "andar": (748, 247, 822, 302),
    "prep": (836, 240, 932, 302),
    "ataque": (944, 236, 1090, 302),
    "dano": (664, 332, 780, 396),
    "transicao": (790, 327, 960, 396),
    "derrota": (970, 344, 1090, 396),
}


def recortar(src, box):
    x0, y0, x1, y1 = box
    c = src[y0:y1, x0:x1].astype(float)
    borda = np.concatenate([c[0], c[-1], c[:, 0], c[:, -1]])
    bg = np.median(borda, axis=0)
    d = np.abs(c - bg).sum(2)
    cand = d < 38
    lab, n = ndi.label(cand)
    fundo = np.zeros_like(cand)
    tocam = (set(lab[0].tolist()) | set(lab[-1].tolist())
             | set(lab[:, 0].tolist()) | set(lab[:, -1].tolist()))
    for k in tocam:
        if k:
            fundo |= lab == k
    fg = ~fundo
    # descarta ilhas minusculas (poeira da prancha)
    l2, n2 = ndi.label(fg)
    if n2:
        areas = ndi.sum(fg, l2, range(1, n2 + 1))
        keep = np.zeros_like(fg)
        for k in range(1, n2 + 1):
            if areas[k - 1] >= 30:
                keep |= l2 == k
        fg = keep
    alfa = fg.astype(float)
    borda_fg = fg & ~ndi.binary_erosion(fg, iterations=1)
    alfa[borda_fg] = np.clip(d[borda_fg] / 60.0, 0.45, 1.0)
    ys, xs = np.nonzero(fg)
    bb = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    # centro dos pes: a faixa mais baixa (18 %) do corpo
    alt = bb[3] - bb[1]
    faixa = fg[bb[3] - max(3, int(alt * 0.18)):bb[3]]
    fx = np.nonzero(faixa.any(0))[0]
    cx = (fx.min() + fx.max() + 1) / 2.0
    return c, alfa, bb, (cx, bb[3])


def pose(src, nome):
    cor, alfa, bb, pes = recortar(src, POSES[nome])
    x0, y0, x1, y1 = bb
    rgba = np.zeros((y1 - y0, x1 - x0, 4), np.float32)
    rgba[..., :3] = cor[y0:y1, x0:x1] * alfa[y0:y1, x0:x1, None]
    rgba[..., 3] = alfa[y0:y1, x0:x1] * 255
    gw, gh = int(round((x1 - x0) * ESC)), int(round((y1 - y0) * ESC))
    ch = [np.array(Image.fromarray(rgba[..., i], "F").resize((gw, gh), Image.LANCZOS))
          for i in range(4)]
    out = np.stack(ch, -1)
    # des-premultiplica (a cor foi multiplicada pelo alfa de 0..1; o alfa vai de 0..255)
    al = np.maximum(out[..., 3:4] / 255.0, 1e-3)
    out[..., :3] = np.clip(out[..., :3] / al, 0, 255)
    out[..., 3] = np.clip(out[..., 3], 0, 255)
    out[out[..., 3] < 14] = 0
    img = Image.fromarray(out.astype(np.uint8), "RGBA")
    return {"img": img, "pes": ((pes[0] - x0) * ESC, (pes[1] - y0) * ESC), "nome": nome}


def tela_com(p, dx=0.0, dy=0.0, rot=0.0, esc=1.0, alfa=1.0, flash=0.0, brilho=0.0, sq=1.0):
    brilho *= 0.5   # a pose da prancha ja' e' muito quente: o brilho so' acentua o nucleo
    img = p["img"]
    px, py = p["pes"]
    if flash > 0 or brilho:
        a = np.array(img).astype(np.float32)
        if flash > 0:
            for i in range(3):
                a[..., i] += (255 - a[..., i]) * flash
        if brilho:
            # realca o NUCLEO / brasas: pixeis laranja-vivo (r alto, g medio, b baixo)
            q = (np.clip((a[..., 0] - 170) / 70.0, 0, 1) * np.clip((a[..., 1] - 70) / 90.0, 0, 1)
                 * np.clip((140 - a[..., 2]) / 90.0, 0, 1) * (a[..., 3] > 0))
            for i, g in enumerate((70, 60, 20)):
                a[..., i] = np.clip(a[..., i] + q * g * brilho, 0, 255)
        img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    if esc != 1.0 or sq != 1.0:
        img = img.resize((max(1, int(img.width * esc)), max(1, int(img.height * esc * sq))),
                         Image.LANCZOS)
        px, py = px * esc, py * esc * sq
    if abs(rot) > 0.01:
        w0, h0 = img.size
        big = Image.new("RGBA", (w0 * 2, h0 * 2), (0, 0, 0, 0))
        big.paste(img, (int(w0 - px), int(h0 - py)))
        big = big.rotate(rot, resample=Image.BICUBIC, center=(w0, h0))
        img, px, py = big, float(w0), float(h0)
    if alfa < 1.0:
        a = np.array(img).astype(np.float32)
        a[..., 3] *= alfa
        img = Image.fromarray(a.astype(np.uint8), "RGBA")
    tela = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    tela.paste(img, (int(round(PES[0] + dx - px)), int(round(PES[1] + dy - py))))
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
        print(n, p["img"].size, "pes", tuple(round(v) for v in p["pes"]))
        assert p["img"].width <= W * 1.0 and p["img"].height <= H, (n, p["img"].size)

    def resp(i, n, a=3.0):
        return math.sin(2 * math.pi * i / n) * a

    # idle: respira (squash leve) e o nucleo pulsa
    idle = [tela_com(P["idle"], dy=-abs(resp(i, 6, 2.0)), sq=1.0 + 0.012 * resp(i, 6, 1.0),
                     brilho=0.35 + 0.35 * math.sin(2 * math.pi * i / 6)) for i in range(6)]
    # andar: pesado, com o corpo a balancar
    walk = [tela_com(P["andar"], dx=resp(i, 8, 2.0), dy=-abs(resp(i, 8, 5.0)), rot=resp(i, 8, 1.5))
            for i in range(8)]
    # ataque: 6 de preparacao (martelo a subir, brasa a crescer) + 4 de pancada
    prep = [tela_com(P["idle"], brilho=0.5),
            tela_com(P["prep"], dx=-6, dy=-2, brilho=0.4),
            tela_com(P["prep"], dx=-9, dy=-5, brilho=0.7),
            tela_com(P["prep"], dx=-12, dy=-7, brilho=0.9),
            tela_com(P["prep"], dx=-12, dy=-8, brilho=1.0),
            tela_com(P["prep"], dx=-13, dy=-8, brilho=1.2)]
    pancada = [tela_com(P["ataque"], dx=4, dy=2, brilho=1.0),
               tela_com(P["ataque"], dx=8, dy=0, brilho=0.8),
               tela_com(P["ataque"], dx=8, dy=1, brilho=0.5),
               tela_com(P["ataque"], dx=6, dy=0, brilho=0.3)]
    attack = prep + pancada
    # cast (chamas do nucleo): o corpo contrai-se (idle) e abre-se (transicao)
    cast = [tela_com(P["idle"], brilho=0.5), tela_com(P["idle"], dy=-2, brilho=0.8),
            tela_com(P["idle"], dy=-4, brilho=1.1, esc=1.02),
            tela_com(P["transicao"], brilho=0.6, alfa=0.9, esc=0.84),
            tela_com(P["transicao"], brilho=0.9, esc=0.86),
            tela_com(P["transicao"], brilho=1.0, esc=0.86),
            tela_com(P["transicao"], brilho=0.7, esc=0.86),
            tela_com(P["idle"], brilho=0.4)]
    # transformacao (fase 2): treme, abre-se em chamas, e volta mais brilhante
    transf = [tela_com(P["dano"], dx=-3, flash=0.4), tela_com(P["idle"], dx=3, brilho=0.8, dy=-3),
              tela_com(P["transicao"], esc=0.86, brilho=0.7),
              tela_com(P["transicao"], esc=0.86, brilho=1.2),
              tela_com(P["transicao"], esc=0.86, brilho=1.5),
              tela_com(P["transicao"], esc=0.86, brilho=1.2),
              tela_com(P["idle"], brilho=1.0, dy=-4), tela_com(P["idle"], brilho=0.8)]
    hurt = [tela_com(P["dano"], flash=0.55), tela_com(P["dano"], dx=-4, flash=0.2),
            tela_com(P["dano"], dx=-2), tela_com(P["idle"], dx=-1)]
    death = [tela_com(P["dano"], flash=0.5), tela_com(P["dano"], dy=3, brilho=0.6)]
    for i in range(8):
        u = i / 7.0
        death.append(tela_com(P["derrota"], dy=2 * u, alfa=1.0 - 0.7 * u * u,
                              brilho=max(0.0, 0.8 - u)))
    estados = {"idle": idle, "walk": walk, "attack": attack, "cast": cast,
               "transform": transf, "hurt": hurt, "death": death}

    os.makedirs(DESTINO, exist_ok=True)
    for nome, q in estados.items():
        t = tira(q)
        t.save(os.path.join(DESTINO, nome + ".png"))
        if "--preview" in sys.argv:
            f = Image.new("RGBA", t.size, (40, 28, 30, 255))
            f.alpha_composite(t)
            f.convert("RGB").save(os.path.join(os.environ.get("PREVIEW_DIR", "."),
                                               "gf_%s.png" % nome))
    with open(RIGS_JSON, encoding="utf-8") as f:
        rigs = json.load(f)
    rigs["guardiao_da_fornalha"] = {
        "w": W, "h": H, "pes_y": PES[1],
        "estados": {n: len(q) for n, q in estados.items()},
        "fps": {"idle": 7.0, "walk": 9.0, "attack": 12.0, "cast": 9.0, "transform": 8.0,
                "hurt": 12.0, "death": 9.0},
    }
    with open(RIGS_JSON, "w", encoding="utf-8", newline="\n") as f:
        json.dump(rigs, f, indent=1, ensure_ascii=False)
        f.write("\n")


if __name__ == "__main__":
    main()
