#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Gera o TERRENO pixel-art de cada regiao a partir de SEIS packs diferentes.

O problema que isto resolve: ate' agora todas as plataformas do jogo eram um
`NinePatchRect` com um padrao "seamless" recolorido -- as 6 regioes eram a
mesma laje em 6 tons, e a 4000 px de largura lia-se como um rectangulo
chapado. Aqui cada regiao vai buscar o material a um pack CC0 DIFERENTE e o
terreno passa a ter as tres pecas que o fazem ler como terreno:

  corpo.png  96x96  -- miolo "seamless" (a rocha/tijolo da regiao, escura)
  topo.png   96x32  -- a CAPA: aresta iluminada + silhueta irregular que
                       sobressai por cima do plano de colisao
  base.png   96x24  -- a franja de baixo (a rocha a esfarelar-se no escuro)
  lado.png   16x96  -- o corte lateral (esquerdo; o direito e' o espelho)

`topo.png` guarda a linha da superficie em `terreno.json` (`superficie`):
e' a que o `plataforma.gd` alinha com o topo da colisao, para a capa
sobressair sem mexer no sitio onde a Koliani pousa.

  python tools/gerar_terreno.py           # grava tudo
  python tools/gerar_terreno.py --preview  # + _preview_terreno.png

Packs (ver assets/sprites/pixel/CREDITS.md): anokolisa Legacy Fantasy,
Pixel Frog Kings & Pigs, ansimuz GothicVania Church / Town / Old Dark
Castle, Szadi art Fantasy Caves.
"""

from __future__ import annotations

import json
import os
import random
import sys

from PIL import Image, ImageFilter

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INC = os.path.join(RAIZ, "assets", "sprites", "incoming")
DL = os.path.join(INC, "_dl")
DEST = os.path.join(RAIZ, "assets", "sprites", "pixel", "terreno")

N = 96          # largura da tira de capa/franja (multiplo de 16)
N_CORPO = 192   # o miolo e' MAIOR que a tira: a 4000 px de plataforma um
                # bloco de 96 lia-se como riscas; 192 ja' nao da' nas vistas
H_TOPO = 32     # altura da tira da capa
H_BASE = 24     # altura da franja de baixo
W_LADO = 16     # largura do corte lateral

# ---------------------------------------------------------------- fontes
FOLHAS = {
    "anokolisa": (os.path.join(INC, "anokolisa", "Legacy-Fantasy - High Forest 2.3", "Assets", "Tiles.png"), 16),
    "kingspigs": (os.path.join(INC, "kings-and-pigs", "Sprites", "14-TileSets", "Terrain (32x32).png"), 32),
    "church": (os.path.join(INC, "gothicvania", "gothicvania church files", "ENVIRONMENT", "tileset.png"), 16),
    "town": (os.path.join(INC, "gothicvania", "GothicVania-town-files", "PNG", "environment", "layers", "tileset.png"), 16),
    "oldcastle": (os.path.join(DL, "gothicvania_patreon", " gothicvania patreon collection",
                               "Old-dark-Castle-tileset-Files", "PNG", "old-dark-castle-interior-tileset.png"), 16),
    "szadi": (os.path.join(INC, "szadiart", "mainlev_build.png"), 32),
}

# Uma regiao = um pack. `topo`/`corpo` sao coordenadas de celula na folha.
#   tinta      -- multiplicada por cima (puxa o pack para a paleta da regiao)
#   dessat     -- quanto se tira da cor PROPRIA do pack antes da tinta
#   escuro     -- quanto se escurece o corpo (o topo leva metade)
#   rim        -- fio de luz na aresta de cima (o luar da regiao)
#   veio       -- fio magenta do key_art (0 = sem)
REGIOES = {
    # I -- Floresta Putrefacta: terra viva com relva pútrida por cima.
    "floresta": dict(
        fonte="anokolisa",
        topo=[(0, 0), (1, 0), (2, 0), (3, 0), (4, 0)],
        corpo=[(2, 6), (3, 6), (1, 11), (2, 11), (3, 6), (1, 7)],
        tinta=(0.80, 0.98, 0.72), dessat=0.40, escuro=0.34,
        rim=(0.58, 1.00, 0.70), veio=0.30,
    ),
    # II -- Prisao dos Condenados: tijolo de masmorra, silhar iluminado a frio.
    "prisao": dict(
        fonte="kingspigs",
        topo=[(2, 1), (5, 1), (11, 1), (14, 1)],
        corpo=[(5, 2), (5, 3), (1, 3), (5, 5), (3, 5), (5, 2)],
        tinta=(0.62, 0.74, 1.05), dessat=0.55, escuro=0.46,
        rim=(0.66, 0.82, 1.00), veio=0.22,
    ),
    # III -- Torres: pedra clara talhada, gasta pelo vento, cheia de luar.
    "torres": dict(
        fonte="church",
        topo=[(2, 10), (4, 10), (5, 10), (6, 10), (8, 10), (9, 10)],
        corpo=[(1, 2), (3, 2), (4, 2), (6, 2), (1, 3), (3, 3), (4, 3), (6, 3)],
        tinta=(0.86, 0.88, 1.06), dessat=0.20, escuro=0.30,
        rim=(0.90, 0.94, 1.00), veio=0.26,
    ),
    # IV -- Catacumbas: rocha viva escura, lascada, com veios de sangue seco.
    "catacumbas": dict(
        fonte="szadi",
        topo=[],   # o pack nao traz capa utilizavel -- sintetizada da rocha
        corpo=[(26, 14), (29, 14), (30, 16), (27, 16), (27, 17), (8, 20)],
        tinta=(1.06, 0.86, 0.92), dessat=0.10, escuro=0.00,
        rim=(0.92, 0.72, 0.80), veio=0.34,
    ),
    # V -- Cidade Corrompida: tijolo e calcada cor de ameixa.
    "cidade": dict(
        fonte="town",
        topo=[(1, 10), (3, 10), (4, 10), (5, 10), (7, 10), (8, 10)],
        corpo=[(10, 4), (11, 4), (13, 4), (14, 4), (10, 7), (12, 7)],
        tinta=(1.00, 0.76, 0.92), dessat=0.18, escuro=0.34,
        rim=(1.00, 0.62, 0.92), veio=0.40,
    ),
    # VI -- Castelo de Zeriko: pedra negra com cornija dourada.
    "castelo": dict(
        fonte="oldcastle",
        topo=[(20, 9), (24, 9), (35, 9), (36, 9), (42, 9)],
        corpo=[(20, 10), (21, 10), (23, 10), (26, 10), (29, 10), (21, 10)],
        tinta=(0.86, 0.72, 1.10), dessat=0.34, escuro=0.30,
        rim=(0.94, 0.60, 1.00), veio=0.46,
    ),
}

VEIO = (0.93, 0.42, 1.00)   # o magenta do key_art, comum a todas as regioes


# ------------------------------------------------------------ utilitarios
def celula(folha: str, cx: int, cy: int) -> Image.Image:
    """Recorta a celula (cx, cy) da folha `folha` e devolve-a a 16x16."""
    im, t = _folha(folha)
    c = im.crop((cx * t, cy * t, cx * t + t, cy * t + t))
    if t != 16:
        c = c.resize((16, 16), Image.NEAREST)
    return c


_cache: dict[str, tuple[Image.Image, int]] = {}


def _folha(nome: str) -> tuple[Image.Image, int]:
    if nome not in _cache:
        cam, t = FOLHAS[nome]
        if not os.path.exists(cam):
            raise SystemExit("falta a folha %s (%s)" % (nome, cam))
        _cache[nome] = (Image.open(cam).convert("RGBA"), t)
    return _cache[nome]


def graduar(img: Image.Image, tinta, dessat: float, escuro: float) -> Image.Image:
    """Dessatura, tinge e escurece -- puxa qualquer pack para a paleta da regiao."""
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            luz = r * 0.30 + g * 0.59 + b * 0.11
            r = r + (luz - r) * dessat
            g = g + (luz - g) * dessat
            b = b + (luz - b) * dessat
            f = 1.0 - escuro
            px[x, y] = (
                min(255, int(r * tinta[0] * f)),
                min(255, int(g * tinta[1] * f)),
                min(255, int(b * tinta[2] * f)),
                a,
            )
    return img


def mistura(c1, c2, t: float):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def cor_media(img: Image.Image, escura=False):
    """Cor media dos pixeis opacos (ou a media do terco mais escuro)."""
    px = img.load()
    w, h = img.size
    vals = []
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 200:
                vals.append((r * 0.3 + g * 0.59 + b * 0.11, (r, g, b)))
    if not vals:
        return (30, 28, 38)
    vals.sort(key=lambda v: v[0])
    fatia = vals[: max(1, len(vals) // 3)] if escura else vals
    n = len(fatia)
    return (sum(v[1][0] for v in fatia) // n,
            sum(v[1][1] for v in fatia) // n,
            sum(v[1][2] for v in fatia) // n)


# -------------------------------------------------------------- as pecas
def faz_corpo(cfg, rng: random.Random) -> Image.Image:
    """Miolo: mosaico das celulas-corpo do pack, sem repetir o padrao."""
    out = Image.new("RGBA", (N_CORPO, N_CORPO), (0, 0, 0, 255))
    cels = [celula(cfg["fonte"], cx, cy) for cx, cy in cfg["corpo"]]
    for j in range(N_CORPO // 16):
        for i in range(N_CORPO // 16):
            c = rng.choice(cels)
            if rng.random() < 0.35:
                c = c.transpose(Image.FLIP_LEFT_RIGHT)
            out.paste(c, (i * 16, j * 16))
    out = graduar(out, cfg["tinta"], cfg["dessat"], cfg["escuro"])
    return out


def faz_topo(cfg, rng: random.Random, corpo: Image.Image) -> tuple[Image.Image, int]:
    """96x32 de capa. Devolve (imagem, linha_da_superficie)."""
    if not cfg["topo"]:
        return _topo_sintetico(cfg, rng, corpo)
    cels = [celula(cfg["fonte"], cx, cy) for cx, cy in cfg["topo"]]
    corpo_cels = [celula(cfg["fonte"], cx, cy) for cx, cy in cfg["corpo"]]

    # onde e' que a capa "assenta": 1.a linha do tile com >=60% de opacidade
    base = cels[0]
    px = base.load()
    superficie = 0
    for y in range(16):
        if sum(1 for x in range(16) if px[x, y][3] > 200) >= 10:
            superficie = y
            break
    # a capa fica com o corpo por baixo, para nao haver costura com o miolo
    folga = 8                       # px de balanco por cima da linha de colisao
    desloc = folga - superficie     # onde comeca o tile da capa dentro da tira

    out = Image.new("RGBA", (N, H_TOPO), (0, 0, 0, 0))
    for i in range(N // 16):
        c = cels[rng.randrange(len(cels))]
        if rng.random() < 0.4:
            c = c.transpose(Image.FLIP_LEFT_RIGHT)
        out.paste(c, (i * 16, desloc), c)
        y = desloc + 16
        while y < H_TOPO:
            b = rng.choice(corpo_cels)
            out.paste(b, (i * 16, y), b)
            y += 16
    out = graduar(out, cfg["tinta"], cfg["dessat"], cfg["escuro"] * 0.5)

    linha = folga  # a superficie de colisao dentro da tira
    _rim(out, linha, cfg)
    return out, linha


def _topo_sintetico(cfg, rng: random.Random, corpo: Image.Image) -> tuple[Image.Image, int]:
    """Capa feita da propria rocha, com a aresta de cima partida.

    Para os packs que nao trazem tile de superficie utilizavel (a folha de
    grutas do Szadi so' tem pecas soltas). Fica uma rocha lascada -- que e'
    exactamente o que uma catacumba escavada devia ler.
    """
    folga = 8
    out = Image.new("RGBA", (N, H_TOPO), (0, 0, 0, 0))
    px = out.load()
    px_c = corpo.load()
    claro = mistura(cor_media(corpo), (255, 255, 255), 0.28)

    alturas = []
    a = rng.randint(0, folga)
    for x in range(N):
        a += rng.randint(-2, 2)
        a = max(0, min(folga + 4, a))
        alturas.append(a)
    for x in range(8):                     # cose o fim com o principio
        t = x / 8.0
        alturas[N - 8 + x] = int(alturas[N - 8 + x] * (1 - t) + alturas[x] * t)

    for x in range(N):
        for y in range(alturas[x], H_TOPO):
            r, g, b, _a = px_c[x, (y + 40) % N_CORPO]
            d = y - alturas[x]
            if d < 4:                       # crista batida pela luz
                c = mistura((r, g, b), claro, 0.55 - d * 0.12)
            else:
                c = (r, g, b)
            px[x, y] = (c[0], c[1], c[2], 255)

    _rim(out, folga, cfg)
    return out, folga


def _rim(img: Image.Image, linha: int, cfg) -> None:
    """Aresta de luar + fio magenta: a assinatura visual comum as 6 regioes.

    O rim segue a SILHUETA (o 1.o pixel opaco de cada coluna), nao uma linha
    recta -- e' o que faz a relva/rocha ler como recorte e nao como fita.
    """
    px = img.load()
    w, h = img.size
    for x in range(w):
        topo_y = None
        for y in range(h):
            if px[x, y][3] > 200:
                topo_y = y
                break
        if topo_y is None or topo_y > linha + 10:
            continue
        for k, forca in ((0, 1.0), (1, 0.45), (2, 0.18)):
            y = topo_y + k
            if y >= h:
                break
            r, g, b, a = px[x, y]
            if a < 200:
                continue
            luar = tuple(int(c * 255) for c in cfg["rim"])
            nc = mistura((r, g, b), luar, 0.62 * forca)
            px[x, y] = (nc[0], nc[1], nc[2], a)
        if cfg["veio"] > 0.0 and px[x, topo_y][3] > 200:
            r, g, b, a = px[x, topo_y]
            nc = mistura((r, g, b), tuple(int(c * 255) for c in VEIO), cfg["veio"] * 0.5)
            px[x, topo_y] = (nc[0], nc[1], nc[2], a)


def faz_base(cfg, corpo: Image.Image, rng: random.Random) -> Image.Image:
    """96x24: o terreno a esfarelar-se para o escuro por baixo.

    Sintetizada (nenhum dos packs traz franja de baixo utilizavel a esta
    escala): degrade da cor escura do corpo com uma silhueta serrilhada, e'
    o que impede a plataforma de acabar num corte recto a meio do ar.
    """
    escura = cor_media(corpo, escura=True)
    ainda = mistura(escura, (0, 0, 0), 0.45)
    out = Image.new("RGBA", (N, H_BASE), (0, 0, 0, 0))
    px = out.load()

    # perfil serrilhado, continuo nas pontas (tem de repetir na horizontal)
    alturas = []
    a = rng.randint(8, H_BASE - 4)
    for x in range(N):
        a += rng.randint(-2, 2)
        a = max(5, min(H_BASE - 1, a))
        alturas.append(a)
    for x in range(6):   # cose o fim com o principio
        t = x / 6.0
        alturas[N - 6 + x] = int(alturas[N - 6 + x] * (1 - t) + alturas[x] * t)

    for x in range(N):
        for y in range(alturas[x]):
            t = y / float(max(1, alturas[x]))
            c = mistura(escura, ainda, min(1.0, t * 1.4))
            alfa = 255 if t < 0.55 else int(255 * (1.0 - (t - 0.55) / 0.45) ** 0.8)
            px[x, y] = (c[0], c[1], c[2], max(0, alfa))
    return out


def faz_lado(cfg, corpo: Image.Image, rng: random.Random) -> Image.Image:
    """16x96: o corte lateral -- corpo escurecido com a aresta lascada."""
    out = Image.new("RGBA", (W_LADO, N), (0, 0, 0, 0))
    src = corpo.crop((0, 0, W_LADO, N))
    escura = cor_media(corpo, escura=True)
    px_s = src.load()
    px = out.load()
    largs = []
    lg = rng.randint(9, W_LADO)
    for y in range(N):
        lg += rng.randint(-1, 1)
        lg = max(6, min(W_LADO, lg))
        largs.append(lg)
    for y in range(6):
        t = y / 6.0
        largs[N - 6 + y] = int(largs[N - 6 + y] * (1 - t) + largs[y] * t)
    for y in range(N):
        for x in range(W_LADO):
            xs = W_LADO - largs[y]
            if x < xs:
                continue
            r, g, b, a = px_s[x, y]
            f = (x - xs) / float(max(1, largs[y]))     # 0 = aresta exterior
            c = mistura(escura, (r, g, b), min(1.0, 0.25 + f * 1.1))
            px[x, y] = (c[0], c[1], c[2], 255)
    return out


# ------------------------------------------------------------------ main
def main() -> int:
    quero_previa = "--preview" in sys.argv
    os.makedirs(DEST, exist_ok=True)
    meta: dict[str, dict] = {}
    previas = []

    for i, (nome, cfg) in enumerate(REGIOES.items()):
        rng = random.Random(0xC0FFEE + i * 977)
        pasta = os.path.join(DEST, nome)
        os.makedirs(pasta, exist_ok=True)

        corpo = faz_corpo(cfg, rng)
        topo, linha = faz_topo(cfg, rng, corpo)
        base = faz_base(cfg, corpo, rng)
        lado = faz_lado(cfg, corpo, rng)

        corpo.save(os.path.join(pasta, "corpo.png"))
        topo.save(os.path.join(pasta, "topo.png"))
        base.save(os.path.join(pasta, "base.png"))
        lado.save(os.path.join(pasta, "lado.png"))

        meta[nome] = {
            "superficie": linha,
            "fonte": cfg["fonte"],
            "escura": list(cor_media(corpo, escura=True)),
            "rim": [round(c, 3) for c in cfg["rim"]],
        }
        print("  %-11s <- %-10s superficie=%d" % (nome, cfg["fonte"], linha))
        if quero_previa:
            previas.append((nome, corpo, topo, base, lado, linha))

    with open(os.path.join(DEST, "terreno.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=1, ensure_ascii=False)

    if quero_previa:
        _previa(previas)
    return 0


def _previa(previas) -> None:
    """Maqueta: uma plataforma de cada regiao, montada como no jogo."""
    LARG, ALT = 384, 190
    folha = Image.new("RGBA", (LARG, ALT * len(previas)), (14, 12, 20, 255))
    for i, (nome, corpo, topo, base, lado, linha) in enumerate(previas):
        y0 = i * ALT
        topo_plat = y0 + 60
        alt_plat = 96
        # corpo em mosaico
        for yy in range(topo_plat, topo_plat + alt_plat, N):
            for xx in range(24, LARG - 24, N):
                folha.paste(corpo, (xx, yy))
        folha.paste(Image.new("RGBA", (LARG, ALT), (0, 0, 0, 0)), (0, y0))  # limpa
        for yy in range(topo_plat, topo_plat + alt_plat, N):
            for xx in range(24, LARG - 24, N):
                cx = min(N, LARG - 24 - xx)
                folha.paste(corpo.crop((0, 0, cx, min(N, topo_plat + alt_plat - yy))), (xx, yy))
        # capa
        for xx in range(24, LARG - 24, N):
            cx = min(N, LARG - 24 - xx)
            folha.alpha_composite(topo.crop((0, 0, cx, topo.size[1])), (xx, topo_plat - linha))
        # franja
        for xx in range(24, LARG - 24, N):
            cx = min(N, LARG - 24 - xx)
            folha.alpha_composite(base.crop((0, 0, cx, base.size[1])), (xx, topo_plat + alt_plat))
        # lados
        folha.alpha_composite(lado.crop((0, 0, W_LADO, alt_plat)), (24 - W_LADO, topo_plat))
        esp = lado.transpose(Image.FLIP_LEFT_RIGHT)
        folha.alpha_composite(esp.crop((0, 0, W_LADO, alt_plat)), (LARG - 24, topo_plat))
    saida = os.path.join(DEST, "_preview_terreno.png")
    folha.convert("RGB").resize((folha.size[0] * 2, folha.size[1] * 2), Image.NEAREST).save(saida)
    print("previa ->", saida)


if __name__ == "__main__":
    raise SystemExit(main())
