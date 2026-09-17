#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""O KIT de material da Regiao II: terreno `desfiladeiro` + props.

PORQUE E' QUE ISTO NAO E' UMA ENTRADA NO `gerar_terreno.py`

O `tools/gerar_terreno.py` gera cada material a partir da folha de tiles
do pack de origem. Das seis fontes que ele usa, so' a `kingspigs` esta'
neste repositorio -- as outras (`anokolisa`, `church`, `town`,
`oldcastle`, `szadi`) foram descarregadas para `assets/sprites/incoming/`
localmente e NAO estao no Git (packs grandes, alguns nao redistribuiveis).
E a `kingspigs` e' tijolo de prisao de ponta a ponta: nao ha' nela uma
unica celula de rocha viva.

O que ESTA' no repositorio sao os materiais ja' GERADOS. O `torres`
("pedra clara talhada, gasta pelo VENTO, cheia de luar", palavras do
proprio `gerar_terreno.py`) e' o mais perto do que o canone da Regiao II
pede: rocha exposta, nao alvenaria de cela. Por isso este material
deriva-se dele -- a mesma pedra, empurrada para a paleta desta regiao.

Fica DIFERENTE do `torres` da Regiao III: a base e' violeta-indigo
(`#433d80`) com o veio carmesim da prancha (`#8e3a3c`) em vez do prateado
frio, e a aresta de luz e' o `#c68af9` do nucleo do Guardiao.

  python tools/gerar_terreno_regiao02.py
  (depois: godot --headless --import)
"""

from __future__ import annotations

import json
import os

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TERR = os.path.join(RAIZ, "assets", "sprites", "pixel", "terreno")
BASE = os.path.join(TERR, "torres")
DEST = os.path.join(TERR, "desfiladeiro")
MANIFESTO = os.path.join(TERR, "terreno.json")

PECAS = ["corpo.png", "topo.png", "lado.png", "base.png"]

DECO = os.path.join(RAIZ, "assets", "sprites", "pixel", "deco")
DECO_BASE = os.path.join(DECO, "torres")
DECO_DEST = os.path.join(DECO, "desfiladeiro")
DECO_MANIFESTO = os.path.join(DECO, "deco.json")

# Paleta canonica da Regiao II (prancha aprovada `boss_pack.png`).
PEDRA = (0x43, 0x3d, 0x80)      # a rocha ao luar
ESCURA = (0x1a, 0x18, 0x2c)     # o fundo das fendas
VEIO = (0x8e, 0x3a, 0x3c)       # o carmesim da regiao, nas gretas
RIM = (0.78, 0.54, 0.98)        # a aresta de luz = o violeta do Guardiao


def recolorir(im: Image.Image, poupar=None) -> Image.Image:
    """Dessatura a pedra e empurra-a para a paleta da regiao.

    A modulacao pela luminancia e' a mesma ideia do `gerar_terreno.py`:
    o relevo que o artista desenhou continua la', so' muda a cor. Os
    pontos mais escuros vao para `ESCURA` e os mais claros para `PEDRA`;
    no meio entra um fio de `VEIO`, que e' o que da' o carmesim da regiao
    sem repintar a rocha de vermelho.
    """
    im = im.convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if poupar is not None and poupar(r, g, b):
                continue
            lum = (r * 0.299 + g * 0.587 + b * 0.114) / 255.0
            # O pivot esta' em 0.3 e nao a meio: a folha do `torres` e'
            # quase toda media-escura, e com o pivot a 0.5 quase tudo
            # caia na metade de baixo e era puxado para `ESCURA`. O
            # resultado foi uma chapa preta sem relevo nenhum -- a
            # primeira tentativa perdeu a pedra que se queria manter.
            if lum < 0.3:
                t = lum / 0.3
                alvo = tuple(int(ESCURA[i] + (PEDRA[i] - ESCURA[i]) * t)
                             for i in range(3))
            else:
                t = min(1.0, (lum - 0.3) / 0.7)
                alvo = tuple(int(PEDRA[i] + (250 - PEDRA[i]) * t * 0.8)
                             for i in range(3))
            # fio carmesim na faixa media-escura (as gretas da rocha)
            if 0.2 <= lum <= 0.36:
                f = 1.0 - abs(lum - 0.28) / 0.08
                alvo = tuple(int(alvo[i] + (VEIO[i] - alvo[i]) * 0.34 * f)
                             for i in range(3))
            px[x, y] = (alvo[0], alvo[1], alvo[2], a)
    return im


def _e_estandarte(r: int, g: int, b: int) -> bool:
    """Vermelho saturado: os estandartes e as flamulas.

    O canone da Regiao II tem estandartes CARMESINS pendurados nas ruinas
    -- sao o unico acento quente do cenario, tal como a lua. Empurra-los
    para indigo com o resto da pedra apagava-os.
    """
    return r > 90 and r > g + 40 and r > b + 30


def props() -> int:
    """Os props goticos do `torres`, na paleta desta regiao.

    A folha do `torres` traz exatamente o que a prancha da Regiao II pede
    -- balaustradas, colunas partidas, correntes, lampioes, estandartes.
    Sem props proprios as plataformas do desfiladeiro ficavam nuas: o
    `plataforma.gd` devolve lista vazia para um bioma que nao esta' no
    `deco.json`.
    """
    os.makedirs(DECO_DEST, exist_ok=True)
    n = 0
    for nome in sorted(os.listdir(DECO_BASE)):
        if not nome.endswith(".png"):
            continue
        im = recolorir(Image.open(os.path.join(DECO_BASE, nome)),
                       poupar=_e_estandarte)
        im.save(os.path.join(DECO_DEST, nome))
        n += 1

    with open(DECO_MANIFESTO, encoding="utf-8") as f:
        cat = json.load(f)
    cat["desfiladeiro"] = cat["torres"]
    with open(DECO_MANIFESTO, "w", encoding="utf-8", newline="\n") as f:
        json.dump(cat, f, indent=1, ensure_ascii=False)
        f.write("\n")
    return n


def main() -> None:
    os.makedirs(DEST, exist_ok=True)
    for nome in PECAS:
        origem = os.path.join(BASE, nome)
        im = recolorir(Image.open(origem))
        im.save(os.path.join(DEST, nome))
        print("  %-10s %s" % (nome, im.size))

    with open(MANIFESTO, encoding="utf-8") as f:
        dados = json.load(f)
    dados["desfiladeiro"] = {
        "superficie": dados["torres"]["superficie"],
        "fonte": "torres (recolorido)",
        "escura": list(ESCURA),
        "rim": list(RIM),
    }
    # `newline="\n"`: o Godot le' isto como recurso e o CRLF do Windows
    # ja' inventou falhas de teste neste repositorio.
    with open(MANIFESTO, "w", encoding="utf-8", newline="\n") as f:
        json.dump(dados, f, indent=1, ensure_ascii=False)
        f.write("\n")
    n = props()
    print("  %d props goticos -> %s" % (n, os.path.relpath(DECO_DEST, RAIZ)))
    print("material `desfiladeiro` -> %s" % os.path.relpath(DEST, RAIZ))


if __name__ == "__main__":
    main()
