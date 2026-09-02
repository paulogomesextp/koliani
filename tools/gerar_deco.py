#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Recorta o CATALOGO DE DECORACAO de cada regiao a partir dos packs CC0.

O jogo tinha seis props ao todo (`assets/sprites/pixel/props/`) e o
`gerador_corredor` espalhava sempre os mesmos tres -- e' por isso que dois
niveis de regioes diferentes se pareciam. Aqui cada regiao ganha o seu
catalogo proprio, tirado dos packs que ja' lhe dao o terreno.

Saida: `assets/sprites/pixel/deco/<regiao>/<nome>.png` + `deco.json` com,
por regiao, a lista de props e onde e' que cada um assenta:

  chao    -- pousa EM CIMA de uma plataforma (pedras, caixas, lapides...)
  parede  -- fica NO FUNDO, atras da accao (colunas, arcos, arvores, casas)

  python tools/gerar_deco.py            # grava tudo
  python tools/gerar_deco.py --preview  # + _preview_deco.png
"""

from __future__ import annotations

import json
import os
import sys

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INC = os.path.join(RAIZ, "assets", "sprites", "incoming")
DL = os.path.join(INC, "_dl")
DEST = os.path.join(RAIZ, "assets", "sprites", "pixel", "deco")

CEMI = os.path.join(DL, "gothicvania-cemetery-files_1", "gothicvania-cemetery-files", "PNG", "Environment")
PATREON = os.path.join(DL, "gothicvania_patreon", " gothicvania patreon collection")
OPP3 = os.path.join(DL, "opp3_cave_tiles", "opp3_cave_tiles", "environment")
TOWN = os.path.join(INC, "gothicvania", "GothicVania-town-files", "PNG", "environment")
CHURCH = os.path.join(INC, "gothicvania", "gothicvania church files", "ENVIRONMENT")

FOLHAS = {
    "anokolisa": (os.path.join(INC, "anokolisa", "Legacy-Fantasy - High Forest 2.3", "Assets", "Tiles.png"), 16),
    "anoprops": (os.path.join(INC, "anokolisa", "Legacy-Fantasy - High Forest 2.3", "Assets", "Props-Rocks.png"), 16),
    "anoarv": (os.path.join(INC, "anokolisa", "Legacy-Fantasy - High Forest 2.3", "Assets", "Tree-Assets.png"), 16),
    "church": (os.path.join(CHURCH, "tileset.png"), 16),
    "town": (os.path.join(TOWN, "layers", "tileset.png"), 16),
    "townprops": (os.path.join(TOWN, "props", "props.png"), 16),
    "oldcastle": (os.path.join(PATREON, "Old-dark-Castle-tileset-Files", "PNG", "old-dark-castle-interior-tileset.png"), 16),
    "kpdeco": (os.path.join(INC, "kings-and-pigs", "Sprites", "14-TileSets", "Decorations (32x32).png"), 32),
    "cristal": (os.path.join(OPP3, "tiles", "cave", "tile_cave_bg_crystal.png"), 16),
    "caveobj": (os.path.join(OPP3, "tiles", "cave", "tile_cave_bg_objects.png"), 16),
    "szadi": (os.path.join(INC, "szadiart", "mainlev_build.png"), 32),
}

# Um prop = (nome, onde, fonte, corte, escala)
#   fonte: "@caminho"                 -> ficheiro inteiro
#          ("folha", cx0,cy0,cx1,cy1) -> celulas [cx0..cx1] x [cy0..cy1]
#   onde:  "chao" | "parede"
#   escala: multiplicador (os packs estao a resolucoes diferentes)
P = os.path.join

DECO: dict[str, list] = {
    # I -- Floresta Putrefacta ------------------------------------------
    "floresta": [
        ("cogumelo_g", "chao", ("anokolisa", 16, 14, 17, 16), 1.6),
        ("cogumelo_p", "chao", ("anokolisa", 15, 14, 15, 16), 1.6),
        ("cogumelo_m", "chao", ("anokolisa", 18, 14, 19, 16), 1.6),
        ("flores", "chao", ("anokolisa", 15, 17, 16, 18), 1.6),
        ("lavanda", "chao", ("anokolisa", 17, 17, 17, 19), 1.6),
        ("erva", "chao", ("anokolisa", 21, 17, 21, 18), 1.8),
        ("nenufar", "chao", ("anokolisa", 18, 19, 19, 20), 1.6),
        ("pedra_musgo", "chao", ("anoprops", 0, 0, 3, 3), 1.5),
        ("tronco", "parede", ("anokolisa", 10, 0, 12, 8), 1.4),
        ("arbusto_g", "parede", "@" + P(CEMI, "sliced-objects", "bush-large.png"), 1.2),
        ("arbusto_p", "chao", "@" + P(CEMI, "sliced-objects", "bush-small.png"), 1.2),
        ("arvore_morta", "parede", "@" + P(CEMI, "sliced-objects", "tree-1.png"), 1.1),
        ("arvore_morta2", "parede", "@" + P(CEMI, "sliced-objects", "tree-3.png"), 1.1),
    ],
    # II -- Prisao dos Condenados ---------------------------------------
    "prisao": [
        ("caixa", "chao", "@" + P(RAIZ, "assets", "sprites", "pixel", "props", "crate.png"), 3.0),
        ("cranio", "chao", "@" + P(RAIZ, "assets", "sprites", "pixel", "props", "skull.png"), 3.0),
        ("escada", "parede", "@" + P(RAIZ, "assets", "sprites", "pixel", "props", "floor_ladder.png"), 3.0),
        ("estandarte", "parede", "@" + P(RAIZ, "assets", "sprites", "pixel", "props", "wall_banner_blue.png"), 3.0),
        ("coluna", "parede", "@" + P(RAIZ, "assets", "sprites", "pixel", "props", "column.png"), 3.0),
        # caixotes e pilar da folha de grutas do Szadi -- a masmorra precisava
        # de volumes de madeira/pedra que o Kings & Pigs nao da' a esta escala
        ("caixote", "chao", ("szadi", 24, 3, 25, 4), 1.4),
        ("caixote2", "chao", ("szadi", 26, 3, 27, 4), 1.4),
        ("pilar", "parede", ("szadi", 26, 9, 26, 14), 1.4),
        ("pilar2", "parede", ("szadi", 29, 12, 29, 14), 1.4),
        ("tabua", "parede", ("szadi", 24, 1, 28, 1), 1.4),
        ("barril", "chao", "@" + P(TOWN, "props-sliced", "barrel.png"), 1.0),
        ("pilha_caixas", "chao", "@" + P(TOWN, "props-sliced", "crate-stack.png"), 1.0),
    ],
    # III -- Torres ------------------------------------------------------
    "torres": [
        ("balaustrada", "parede", ("church", 12, 6, 16, 8), 1.2),
        ("velas", "parede", ("church", 12, 1, 13, 4), 1.2),
        ("tocha", "parede", ("church", 15, 5, 16, 8), 1.2),
        ("janela_gotica", "parede", ("church", 18, 0, 19, 4), 1.2),
        ("coluna_igreja", "parede", "@" + P(CHURCH, "column.png"), 1.2),
        ("pedra_talhada", "chao", ("church", 12, 10, 13, 11), 1.2),
        ("cruz", "chao", "@" + P(CEMI, "sliced-objects", "stone-2.png"), 1.0),
        ("lapide", "chao", "@" + P(CEMI, "sliced-objects", "stone-1.png"), 1.0),
    ],
    # IV -- Catacumbas ---------------------------------------------------
    "catacumbas": [
        ("lapide_a", "chao", "@" + P(CEMI, "sliced-objects", "stone-1.png"), 1.2),
        ("lapide_b", "chao", "@" + P(CEMI, "sliced-objects", "stone-3.png"), 1.2),
        ("cruz_a", "chao", "@" + P(CEMI, "sliced-objects", "stone-2.png"), 1.2),
        ("cruz_b", "chao", "@" + P(CEMI, "sliced-objects", "stone-4.png"), 1.2),
        ("ceifeiro", "parede", "@" + P(CEMI, "sliced-objects", "statue.png"), 1.1),
        ("arvore_ossos", "parede", "@" + P(CEMI, "sliced-objects", "tree-2.png"), 1.0),
        ("cristal_g", "chao", ("cristal", 1, 0, 2, 2), 2.0),
        ("cristal_p", "chao", ("cristal", 0, 1, 0, 2), 2.0),
        ("cristal_teto", "parede", ("cristal", 6, 0, 8, 2), 2.0),
        ("ossada", "chao", ("caveobj", 0, 3, 2, 5), 2.0),
        ("lanterna", "chao", ("caveobj", 0, 6, 2, 8), 2.0),
        ("cranio_c", "chao", "@" + P(RAIZ, "assets", "sprites", "pixel", "props", "skull.png"), 3.0),
    ],
    # V -- Cidade Corrompida ---------------------------------------------
    "cidade": [
        ("barril", "chao", "@" + P(TOWN, "props-sliced", "barrel.png"), 1.2),
        ("caixa", "chao", "@" + P(TOWN, "props-sliced", "crate.png"), 1.2),
        ("pilha_caixas", "chao", "@" + P(TOWN, "props-sliced", "crate-stack.png"), 1.2),
        ("poco", "chao", "@" + P(TOWN, "props-sliced", "well.png"), 1.1),
        ("carroca", "chao", "@" + P(TOWN, "props-sliced", "wagon.png"), 1.1),
        ("candeeiro", "parede", "@" + P(TOWN, "props-sliced", "street-lamp.png"), 1.1),
        ("tabuleta", "parede", "@" + P(TOWN, "props-sliced", "sign.png"), 1.1),
        ("casa_a", "parede", "@" + P(TOWN, "props-sliced", "house-a.png"), 1.0),
        ("casa_b", "parede", "@" + P(TOWN, "props-sliced", "house-b.png"), 1.0),
        ("janela_vila", "parede", ("town", 10, 1, 11, 4), 1.2),
        ("porta_vila", "parede", ("town", 17, 5, 18, 10), 1.2),
    ],
    # VI -- Castelo de Zeriko --------------------------------------------
    "castelo": [
        ("porta_negra", "parede", ("oldcastle", 41, 3, 42, 6), 1.3),
        ("nicho", "parede", ("oldcastle", 3, 9, 5, 11), 1.3),
        ("tocha_muro", "parede", ("oldcastle", 8, 5, 9, 7), 1.3),
        ("fresta", "parede", ("oldcastle", 46, 3, 47, 6), 1.3),
        ("velas_c", "parede", ("church", 12, 1, 13, 4), 1.2),
        ("balaustrada_c", "parede", ("church", 12, 6, 16, 8), 1.2),
        ("estandarte_r", "parede", "@" + P(RAIZ, "assets", "sprites", "pixel", "props", "wall_banner_red.png"), 3.0),
        ("coluna_c", "parede", "@" + P(RAIZ, "assets", "sprites", "pixel", "props", "column.png"), 3.0),
        ("cranio_t", "chao", "@" + P(RAIZ, "assets", "sprites", "pixel", "props", "skull.png"), 3.0),
        ("caixa_c", "chao", "@" + P(RAIZ, "assets", "sprites", "pixel", "props", "crate.png"), 3.0),
        ("lapide_c", "chao", "@" + P(CEMI, "sliced-objects", "stone-4.png"), 1.1),
    ],
}

# Graduacao por regiao, para os packs todos assentarem na mesma paleta.
# (tinta, dessaturar, escurecer) -- a mesma ideia do gerar_terreno.py.
TOM = {
    "floresta": ((0.82, 1.00, 0.78), 0.34, 0.24),
    "prisao": ((0.68, 0.80, 1.06), 0.46, 0.26),
    "torres": ((0.88, 0.90, 1.08), 0.24, 0.16),
    "catacumbas": ((0.94, 0.80, 0.92), 0.22, 0.20),
    "cidade": ((1.02, 0.78, 0.94), 0.20, 0.22),
    "castelo": ((0.88, 0.72, 1.10), 0.32, 0.20),
}

_cache: dict[str, tuple[Image.Image, int]] = {}


def folha(nome: str) -> tuple[Image.Image, int]:
    if nome not in _cache:
        cam, t = FOLHAS[nome]
        _cache[nome] = (Image.open(cam).convert("RGBA"), t)
    return _cache[nome]


def apara(im: Image.Image) -> Image.Image:
    """Corta as margens transparentes -- assim as coordenadas nao tem de ser
    exactas: basta apanhar a celula certa com folga."""
    bb = im.getbbox()
    return im.crop(bb) if bb else im


def graduar(im: Image.Image, tom) -> Image.Image:
    tinta, dessat, escuro = tom
    px = im.load()
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            luz = r * 0.30 + g * 0.59 + b * 0.11
            r += (luz - r) * dessat
            g += (luz - g) * dessat
            b += (luz - b) * dessat
            f = 1.0 - escuro
            px[x, y] = (min(255, int(r * tinta[0] * f)),
                        min(255, int(g * tinta[1] * f)),
                        min(255, int(b * tinta[2] * f)), a)
    return im


def recorta(fonte) -> Image.Image:
    if isinstance(fonte, str) and fonte.startswith("@"):
        cam = fonte[1:]
        if not os.path.exists(cam):
            raise FileNotFoundError(cam)
        return Image.open(cam).convert("RGBA")
    nome, cx0, cy0, cx1, cy1 = fonte
    im, t = folha(nome)
    return im.crop((cx0 * t, cy0 * t, (cx1 + 1) * t, (cy1 + 1) * t))


def main() -> int:
    quero_previa = "--preview" in sys.argv
    os.makedirs(DEST, exist_ok=True)
    meta: dict[str, list] = {}
    previas = []

    for reg, props in DECO.items():
        pasta = os.path.join(DEST, reg)
        os.makedirs(pasta, exist_ok=True)
        lista = []
        for nome, onde, fonte, esc in props:
            try:
                im = apara(recorta(fonte))
            except (FileNotFoundError, KeyError) as e:
                print("  ! %s/%s saltado (%s)" % (reg, nome, e))
                continue
            if im.size[0] == 0 or im.size[1] == 0:
                print("  ! %s/%s vazio" % (reg, nome))
                continue
            if esc != 1.0:
                im = im.resize((max(1, int(im.size[0] * esc)), max(1, int(im.size[1] * esc))), Image.NEAREST)
            im = graduar(im, TOM[reg])
            im.save(os.path.join(pasta, nome + ".png"))
            lista.append({"nome": nome, "onde": onde, "w": im.size[0], "h": im.size[1]})
            if quero_previa:
                previas.append((reg, nome, im))
        meta[reg] = lista
        print("  %-11s %2d props (%d chao / %d parede)" % (
            reg, len(lista),
            sum(1 for p in lista if p["onde"] == "chao"),
            sum(1 for p in lista if p["onde"] == "parede")))

    with open(os.path.join(DEST, "deco.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=1, ensure_ascii=False)

    if quero_previa:
        _previa(previas)
    return 0


def _previa(previas) -> None:
    COL, CEL = 8, 160
    linhas = (len(previas) + COL - 1) // COL
    folha_im = Image.new("RGBA", (COL * CEL, linhas * CEL), (18, 15, 24, 255))
    for i, (_reg, _nome, im) in enumerate(previas):
        cx, cy = (i % COL) * CEL, (i // COL) * CEL
        e = min(1.0, (CEL - 16) / max(im.size))
        if e < 1.0:
            im = im.resize((max(1, int(im.size[0] * e)), max(1, int(im.size[1] * e))), Image.NEAREST)
        folha_im.alpha_composite(im, (cx + (CEL - im.size[0]) // 2, cy + CEL - 8 - im.size[1]))
    saida = os.path.join(DEST, "_preview_deco.png")
    folha_im.convert("RGB").save(saida)
    print("previa ->", saida)


if __name__ == "__main__":
    raise SystemExit(main())
