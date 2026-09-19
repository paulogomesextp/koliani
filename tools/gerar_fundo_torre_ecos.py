#!/usr/bin/env python3
"""Gera o pack de parallax `torre_ecos` -- o fundo proprio da Regiao III.

PORQUE E' QUE ISTO EXISTE

Os cinco niveis da Torre dos Ecos usavam `fundo_pack = "montanhas"`, que
tem uma camada `trees.png` de PINHEIROS. A prova visual da auditoria
(docs/playtests/region_03_visual_evidence/antes/) mostrava a "torre de
sinos" a ler-se como floresta ao entardecer: pinheiros verdes, ceu
castanho-avermelhado, cruzes de campa. Ver
`docs/implementation/region_03_audit.md` §5b.

As pranchas APPROVED (`asset_atlas.png`) nomeiam CINCO camadas:
  1 silhueta proxima · 2 torres distantes · 3 catedral da cidade
  4 montanhas e nuvens · 5 lua e ceu

O `Atmosfera._montar_fundo_pack` limpa a camada a cada entrada, por isso
so' ha' QUATRO ranhuras (Fundo/Longe/Meio/Perto) e uma entrada por
ranhura. As camadas 4 e 5 juntam-se no `ceu.png`, que e' como os outros
packs ja' fazem.

Paleta: a do contrato -- azul noite, azul profundo, pedra antiga, ouro
envelhecido, luz de lua. Sem verdes.

Uso:  python3 tools/gerar_fundo_torre_ecos.py
Saida: assets/sprites/pixel/backgrounds/torre_ecos/*.png
       (correr o `--headless --import` do Godot a seguir)
"""
from __future__ import annotations

import math
import pathlib
import random

from PIL import Image, ImageDraw

DEST = pathlib.Path(__file__).resolve().parent.parent / \
    "assets/sprites/pixel/backgrounds/torre_ecos"
ALTURA = 240

# --- paleta do contrato (§1) -------------------------------------------
NOITE_TOPO = (10, 12, 30)
NOITE_BASE = (20, 25, 56)
AZUL_PROFUNDO = (18, 22, 48)
LUA = (232, 238, 255)
LUAR = (150, 170, 220)
PEDRA_LONGE = (58, 66, 112)
PEDRA_MEIO = (46, 52, 96)
PEDRA_PERTO = (20, 21, 42)
OURO = (214, 164, 84)
OURO_FRACO = (150, 112, 58)
VITRAL = (120, 150, 230)


def _nova(larg: int) -> Image.Image:
    return Image.new("RGBA", (larg, ALTURA), (0, 0, 0, 0))


def _mistura(a, b, t: float):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


# =======================================================================
#  CAMADA "Fundo" -- lua e ceu (5) + montanhas e nuvens (4)
# =======================================================================
def ceu(larg: int = 1600) -> Image.Image:
    im = _nova(larg)
    px = im.load()
    for y in range(ALTURA):
        t = y / (ALTURA - 1)
        cor = _mistura(NOITE_TOPO, NOITE_BASE, t ** 0.75)
        for x in range(larg):
            px[x, y] = cor + (255,)

    rng = random.Random(1103)
    # estrelas: mais densas em cima, nunca por cima da lua
    lua_x, lua_y, lua_r = int(larg * 0.72), 66, 30
    for _ in range(larg // 5):
        x = rng.randrange(larg)
        y = int(abs(rng.gauss(0, 1)) * 52)
        if y >= ALTURA - 70:
            continue
        if (x - lua_x) ** 2 + (y - lua_y) ** 2 < (lua_r + 14) ** 2:
            continue
        b = rng.choice((150, 190, 230, 255))
        px[x, y] = (b, b, min(255, b + 20), 255)

    d = ImageDraw.Draw(im)
    # halo da lua, em aneis (pixel-art: sem gradiente continuo)
    for r in range(lua_r + 26, lua_r, -1):
        a = int(46 * (1.0 - (r - lua_r) / 26.0) ** 2)
        d.ellipse([lua_x - r, lua_y - r, lua_x + r, lua_y + r],
                  fill=LUAR + (a,))
    d.ellipse([lua_x - lua_r, lua_y - lua_r, lua_x + lua_r, lua_y + lua_r],
              fill=LUA + (255,))
    # crateras (a lua da key_art tem relevo)
    for cx, cy, cr in ((-10, -8, 7), (8, 4, 5), (-2, 12, 4), (13, -12, 3)):
        d.ellipse([lua_x + cx - cr, lua_y + cy - cr,
                   lua_x + cx + cr, lua_y + cy + cr],
                  fill=_mistura(LUA, LUAR, 0.38) + (255,))

    # camada 4 -- montanhas e nuvens: um mar de nuvens baixo, em bandas
    base = ALTURA - 54
    for banda, (amp, passo, alfa, desv) in enumerate((
            (13, 190.0, 54, 0.0), (9, 128.0, 74, 61.0), (6, 86.0, 96, 133.0))):
        topo = base + banda * 13
        pts = []
        for x in range(larg + 1):
            y = topo - amp * (0.5 + 0.5 * math.sin((x + desv) / passo)) \
                - amp * 0.28 * math.sin((x + desv) / (passo * 0.37))
            pts.append((x, y))
        d.polygon(pts + [(larg, ALTURA), (0, ALTURA)],
                  fill=_mistura(AZUL_PROFUNDO, LUAR, 0.10 + banda * 0.05)
                  + (alfa,))
    return im


# =======================================================================
#  CAMADA "Longe" -- catedral da cidade (3)
# =======================================================================
def _agulha(d: ImageDraw.ImageDraw, x: int, base: int, larg: int,
            alt: int, cor, ouro=False) -> None:
    """Torre gotica: corpo + coroamento em agulha."""
    corpo = alt - larg
    d.rectangle([x, base - corpo, x + larg, base], fill=cor + (255,))
    d.polygon([(x - 2, base - corpo), (x + larg + 2, base - corpo),
               (x + larg // 2, base - alt)], fill=cor + (255,))
    # janelas em ogiva, acesas
    passo = max(9, larg // 3)
    jl = max(2, larg // 5)
    for jy in range(base - corpo + 10, base - 6, passo):
        jx = x + larg // 2 - jl // 2
        c = OURO if ouro else VITRAL
        d.rectangle([jx, jy, jx + jl - 1, jy + jl + 1], fill=c + (255,))
        d.point((jx + jl // 2, jy - 1), fill=c + (255,))


def catedral(larg: int = 768) -> Image.Image:
    im = _nova(larg)
    d = ImageDraw.Draw(im)
    base = ALTURA
    cor = PEDRA_LONGE

    # nave central + duas torres, repetida de forma tilable
    meio = larg // 2
    d.rectangle([meio - 96, base - 92, meio + 96, base], fill=cor + (255,))
    # telhado da nave
    d.polygon([(meio - 100, base - 92), (meio + 100, base - 92),
               (meio, base - 126)], fill=cor + (255,))
    # rosacea
    d.ellipse([meio - 19, base - 84, meio + 19, base - 46],
              fill=_mistura(VITRAL, LUA, 0.25) + (255,))
    d.ellipse([meio - 12, base - 77, meio + 12, base - 53],
              fill=VITRAL + (255,))
    for k in range(8):  # rendilhado
        a = k * math.pi / 4
        d.line([meio, base - 65,
                meio + 18 * math.cos(a), base - 65 + 18 * math.sin(a)],
               fill=cor + (255,))
    # arcaria da nave
    for k in range(-3, 4):
        ax = meio + k * 26
        d.rectangle([ax - 6, base - 34, ax + 6, base], fill=AZUL_PROFUNDO + (255,))
        d.ellipse([ax - 6, base - 42, ax + 6, base - 26], fill=AZUL_PROFUNDO + (255,))

    _agulha(d, meio - 128, base, 30, 168, cor)
    _agulha(d, meio + 98, base, 30, 168, cor)
    # torres menores nas pontas (fecham o tile)
    _agulha(d, -14, base, 26, 118, cor)
    _agulha(d, larg - 12, base, 26, 118, cor)
    _agulha(d, meio - 210, base, 22, 96, cor)
    _agulha(d, meio + 190, base, 22, 96, cor)
    return im


# =======================================================================
#  CAMADA "Meio" -- torres distantes (2)
# =======================================================================
def torres(larg: int = 640) -> Image.Image:
    im = _nova(larg)
    d = ImageDraw.Draw(im)
    base = ALTURA
    cor = PEDRA_MEIO
    rng = random.Random(77)

    # um skyline de torres interligadas -- "arquitetura vertical e
    # interligada" (contrato §1.3)
    x = -18
    alturas = []
    while x < larg + 18:
        w = rng.choice((24, 30, 34, 40))
        h = rng.choice((104, 132, 150, 176, 196))
        _agulha(d, x, base, w, h, cor, ouro=rng.random() < 0.35)
        alturas.append((x + w // 2, base - h + w, w))
        x += w + rng.choice((22, 30, 38))

    # pontes/arcos entre torres vizinhas (as "pontes entre torres" da prancha)
    for i in range(len(alturas) - 1):
        (x0, y0, _), (x1, y1, _) = alturas[i], alturas[i + 1]
        if abs(y0 - y1) > 46 or x1 - x0 > 92:
            continue
        y = max(y0, y1) + rng.randrange(26, 58)
        if y >= base - 8:
            continue
        d.rectangle([x0, y, x1, y + 5], fill=cor + (255,))
        for k in range(x0 + 8, x1 - 4, 16):  # arcos por baixo
            d.arc([k, y + 3, k + 12, y + 17], 180, 360, fill=cor + (255,))
    return im


# =======================================================================
#  CAMADA "Perto" -- silhueta proxima (1)
# =======================================================================
def silhueta(larg: int = 480) -> Image.Image:
    im = _nova(larg)
    d = ImageDraw.Draw(im)
    base = ALTURA
    cor = PEDRA_PERTO

    # contrafortes e uma arcada grande, muito escuros: e' recorte, nao detalhe
    d.rectangle([0, base - 26, larg, base], fill=cor + (255,))
    for cx in range(0, larg + 1, 160):
        # pilar
        d.rectangle([cx - 15, base - 150, cx + 15, base], fill=cor + (255,))
        # capitel
        d.rectangle([cx - 21, base - 158, cx + 21, base - 146], fill=cor + (255,))
        # arco ogival entre pilares
        d.arc([cx + 15, base - 196, cx + 145, base - 66], 180, 360,
              fill=cor + (255,), width=13)
        # SINO pendurado no arco -- o elemento central da regiao
        sx, sy = cx + 80, base - 118
        d.polygon([(sx - 13, sy + 20), (sx + 13, sy + 20), (sx + 9, sy - 6),
                   (sx - 9, sy - 6)], fill=OURO_FRACO + (255,))
        d.rectangle([sx - 16, sy + 20, sx + 16, sy + 25], fill=OURO_FRACO + (255,))
        d.rectangle([sx - 1, sy - 16, sx + 1, sy - 6], fill=OURO_FRACO + (255,))
        d.point((sx, sy + 27), fill=OURO + (255,))
    return im


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    for nome, img in (("ceu.png", ceu()), ("catedral.png", catedral()),
                      ("torres.png", torres()), ("silhueta.png", silhueta())):
        img.save(DEST / nome)
        print(f"{DEST.relative_to(DEST.parents[4])}/{nome}  {img.size}")


if __name__ == "__main__":
    main()
