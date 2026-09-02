#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Prepara os FUNDOS parallax novos (packs CC0 de 3 set 2026).

Cada regiao tinha UM pack de fundo para os seus 5 niveis -- cinco vezes a
mesma serra, a mesma vila, a mesma parede. Estes packs novos dao material
para cada nivel ter o seu ceu.

As camadas do `atmosfera.gd` repetem-se na horizontal (`motion_mirroring`),
por isso um fundo com um elemento UNICO (a lua) nao pode ser usado como
veio: `_alargar` monta uma tira larga em que esse elemento aparece uma vez
so' e o resto e' a nuvem/serra a repetir espelhada.

  python tools/gerar_fundos.py
"""

from __future__ import annotations

import os
import shutil

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INC = os.path.join(RAIZ, "assets", "sprites", "incoming")
DL = os.path.join(INC, "_dl")
DEST = os.path.join(RAIZ, "assets", "sprites", "pixel", "backgrounds")

PATREON = os.path.join(DL, "gothicvania_patreon", " gothicvania patreon collection")
CEMI = os.path.join(DL, "gothicvania-cemetery-files_1", "gothicvania-cemetery-files", "PNG", "Environment")
NOITE = os.path.join(PATREON, "night-town-background-files", "layers")
HORROR = os.path.join(PATREON, "Gothic-Horror-Files", "PNG", "layers")
VELHO = os.path.join(PATREON, "Old-dark-Castle-tileset-Files", "PNG")


def alargar(im: Image.Image, vezes: int, enchimento: float = 0.28) -> Image.Image:
    """Tira larga com a imagem inteira UMA vez e o resto so' 'enchimento'.

    `enchimento` = fraccao da esquerda da imagem que serve de padrao (a
    parte sem o elemento unico). Alterna espelhada para nao dar costura.
    """
    w, h = im.size
    fw = max(8, int(w * enchimento))
    tira = im.crop((0, 0, fw, h))
    out = Image.new("RGBA", (w * vezes, h), (0, 0, 0, 0))
    x = 0
    i = 0
    while x < out.size[0]:
        t = tira if i % 2 == 0 else tira.transpose(Image.FLIP_LEFT_RIGHT)
        out.alpha_composite(t, (x, 0))
        x += fw
        i += 1
    out.alpha_composite(im, ((out.size[0] - w) // 2, 0))
    return out


def copia(origem: str, pack: str, nome: str, transformar=None) -> None:
    pasta = os.path.join(DEST, pack)
    os.makedirs(pasta, exist_ok=True)
    if not os.path.exists(origem):
        print("  ! falta", origem)
        return
    im = Image.open(origem).convert("RGBA")
    if transformar:
        im = transformar(im)
    im.save(os.path.join(pasta, nome))
    print("  %-14s %-14s %dx%d" % (pack, nome, im.size[0], im.size[1]))


def main() -> int:
    # --- luar: lua de sangue sobre o cemiterio (e' o key_art em pixel) ---
    copia(os.path.join(CEMI, "background.png"), "luar", "ceu.png",
          lambda im: alargar(im, 4, 0.22))
    copia(os.path.join(CEMI, "mountains.png"), "luar", "serra.png")
    copia(os.path.join(CEMI, "graveyard.png"), "luar", "campo.png")

    # --- vilanoite: a vila ao fundo do vale, com janelas acesas ----------
    copia(os.path.join(NOITE, "night-town-background-sky.png"), "vilanoite", "ceu.png")
    copia(os.path.join(NOITE, "night-town-background-mountains-lights.png"), "vilanoite", "serra.png")
    copia(os.path.join(NOITE, "night-town-background-far-buildings.png"), "vilanoite", "casario.png")
    copia(os.path.join(NOITE, "night-town-background-town.png"), "vilanoite", "vila.png")

    # --- horror: nuvens baixas sobre a vila da colina --------------------
    copia(os.path.join(HORROR, "clouds.png"), "horror", "nuvens.png")
    copia(os.path.join(HORROR, "town.png"), "horror", "vila.png")

    # --- castelo_velho: o salao gotico com o vitral aceso ----------------
    # a folha traz o motivo duas vezes; corta-se uma so' unidade (480 px)
    copia(os.path.join(VELHO, "old-dark-castle-interior-background.png"),
          "castelo_velho", "salao.png", lambda im: im.crop((0, 0, 480, im.size[1])))
    copia(os.path.join(VELHO, "old-dark-castle-interior-background.png"),
          "castelo_velho", "nave.png",
          lambda im: im.crop((0, 0, 480, im.size[1])).transpose(Image.FLIP_LEFT_RIGHT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
