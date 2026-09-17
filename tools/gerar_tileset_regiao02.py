#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""A casca da Regiao II: o mesmo tileset, a pedra do desfiladeiro.

A `CascaMasmorra` fecha os niveis com o `assets/tiles/masmorra.tres`
(0x72 DungeonTileset II, CC0) -- tijolo de cela. Na Regiao II isso e' o
que mais grita "prisao".

NAO SE PODE TROCAR OS TILES por outros: no `masmorra.tres` cada tile
solido traz o seu proprio poligono de colisao 16x16, e o
`casca_masmorra.gd` conta com isso (ver o comentario do `abrir_esquerda`:
"o tileset tem colisao propria por tile"). Mudar coordenadas de atlas
mudava a colisao, e o passe de arte nao pode mexer em colisao.

Por isso troca-se so' a TEXTURA. O `desfiladeiro.tres` e' o
`masmorra.tres` com outra imagem e EXATAMENTE as mesmas coordenadas e os
mesmos poligonos -- a colisao e' identica por construcao, e ha' um teste
que o prova.

  python tools/gerar_tileset_regiao02.py
  (depois: godot --headless --import)
"""

from __future__ import annotations

import io
import os

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TILES = os.path.join(RAIZ, "assets", "sprites", "pixel", "tiles")
ORIGEM_PNG = os.path.join(TILES, "dungeon_0x72.png")
DESTINO_PNG = os.path.join(TILES, "desfiladeiro_0x72.png")
ORIGEM_TRES = os.path.join(RAIZ, "assets", "tiles", "masmorra.tres")
DESTINO_TRES = os.path.join(RAIZ, "assets", "tiles", "desfiladeiro.tres")

PEDRA = (0x43, 0x3d, 0x80)
ESCURA = (0x16, 0x14, 0x26)
VEIO = (0x8e, 0x3a, 0x3c)


def recolorir(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            lum = (r * 0.299 + g * 0.587 + b * 0.114) / 255.0
            if lum < 0.32:
                t = lum / 0.32
                alvo = [int(ESCURA[i] + (PEDRA[i] - ESCURA[i]) * t)
                        for i in range(3)]
            else:
                t = min(1.0, (lum - 0.32) / 0.68)
                alvo = [int(PEDRA[i] + (244 - PEDRA[i]) * t * 0.78)
                        for i in range(3)]
            if 0.22 <= lum <= 0.38:
                f = 1.0 - abs(lum - 0.3) / 0.08
                alvo = [int(alvo[i] + (VEIO[i] - alvo[i]) * 0.3 * f)
                        for i in range(3)]
            px[x, y] = (alvo[0], alvo[1], alvo[2], a)
    return im


def main() -> None:
    im = recolorir(Image.open(ORIGEM_PNG))
    im.save(DESTINO_PNG)
    print("  textura %s %s" % (os.path.basename(DESTINO_PNG), im.size))

    tres = io.open(ORIGEM_TRES, encoding="utf-8", newline="").read()
    tres = tres.replace("dungeon_0x72.png", "desfiladeiro_0x72.png")
    tres = tres.replace(
        '[gd_resource type="TileSet" format=3]',
        '[gd_resource type="TileSet" format=3]\n\n'
        '; GERADO por tools/gerar_tileset_regiao02.py -- NAO editar a mao.\n'
        '; E\' o masmorra.tres com outra TEXTURA e as mesmas coordenadas de\n'
        '; atlas e os mesmos poligonos de fisica: a colisao da CascaMasmorra\n'
        '; e\' identica por construcao (tests/run_region02_casca.tscn prova-o).')
    io.open(DESTINO_TRES, "w", encoding="utf-8", newline="\n").write(tres)
    print("  tileset %s" % os.path.relpath(DESTINO_TRES, RAIZ))


if __name__ == "__main__":
    main()
