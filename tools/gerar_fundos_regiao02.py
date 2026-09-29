#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Monta o pack de fundo `desfiladeiro` -- o ceu SO' da Regiao II.

PORQUE E' QUE ISTO EXISTE

A Regiao II e' o Desfiladeiro dos Ventos: falesias, ceu, mar de nuvens,
lua de sangue, ruinas goticas suspensas. Corria com `prisao` e `masmorra`
-- paredes de cela e corredores fechados. Nada mais longe do canone.

Os packs certos em MATERIA (`montanhas` tem a lua e as serras, `rochoso`
tem o mar de nuvens e as falesias) sao os da REGIAO III. A regra do
`afinar_atmosfera.py` e' clara e vale a pena: **um pack nunca aparece em
duas regioes**, senao o jogador deixa de sentir que mudou de sitio.

Por isso nao se reutiliza: COMPOE-SE um pack novo a partir das camadas que
ja' estao no repo (todas CC0, ja' creditadas em
`assets/sprites/pixel/CREDITS.md`), recortadas e recoloridas para a paleta
canonica da Regiao II amostrada da prancha aprovada. As imagens ficam
diferentes das da Regiao III -- outra cor, outra montagem, outra camada de
silhueta gotica por cima.

CAMADAS (as quatro que `concept_environment_01.png` nomeia)

  ceu.png       Fundo  -- ceu violeta + lua de sangue (uma so' vez)
  serras.png    Longe  -- cristas distantes + torres goticas partidas
  nuvens.png    Meio   -- o mar de nuvens: e' o que diz ALTITUDE
  falesias.png  Perto  -- a rocha exposta do desfiladeiro

  python tools/gerar_fundos_regiao02.py
  (depois: godot --headless --import)
"""

from __future__ import annotations

import os

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG = os.path.join(RAIZ, "assets", "sprites", "pixel", "backgrounds")
DEST = os.path.join(BG, "desfiladeiro")

# Paleta canonica da Regiao II, amostrada de
# docs/art_direction/regions/region_02/boss_pack.png (painel PALETA DE
# CORES) e de concept_environment_01.png (PALETA DE CORES DA REGIAO).
PEDRA = (0x43, 0x3d, 0x80)      # violeta-indigo da rocha iluminada
SOMBRA = (0x1e, 0x1e, 0x33)     # o fundo das fendas
CEU = (0x2b, 0x25, 0x4a)        # o ceu alto
LUA = (0xb0, 0x4a, 0x4e)        # a lua de sangue
NUVEM = (0x8c, 0x82, 0xb4)      # o mar de nuvens ao luar


def _carregar(pack: str, nome: str) -> Image.Image:
    return Image.open(os.path.join(BG, pack, nome)).convert("RGBA")


def tingir(im: Image.Image, alvo: tuple[int, int, int], forca: float,
           dessat: float = 0.55, poupar=None) -> Image.Image:
    """Dessatura e puxa para `alvo`, preservando a luminancia.

    E' o mesmo principio do `gerar_terreno.py`: nao se repinta a arte,
    empurra-se a paleta dela. Assim a rocha continua a ter o relevo que o
    artista desenhou, mas passa a ser a rocha DESTA regiao.
    """
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if poupar is not None and poupar(r, g, b):
                continue
            lum = (r * 0.299 + g * 0.587 + b * 0.114)
            r = r + (lum - r) * dessat
            g = g + (lum - g) * dessat
            b = b + (lum - b) * dessat
            # a tinta e' modulada pela luminancia: as zonas escuras ficam
            # escuras (senao o fundo inteiro vira uma chapa de cor)
            k = forca * (0.35 + 0.65 * (lum / 255.0))
            px[x, y] = (
                int(r + (alvo[0] - r) * k),
                int(g + (alvo[1] - g) * k),
                int(b + (alvo[2] - b) * k),
                a,
            )
    return im


def alargar(im: Image.Image, vezes: int, enchimento: float = 0.3) -> Image.Image:
    """Tira larga com a imagem inteira UMA vez e o resto so' `enchimento`.

    As camadas repetem-se na horizontal (`motion_mirroring`), por isso um
    elemento UNICO -- a lua -- nao pode ser usado como veio: apareciam
    cinco luas no mesmo ceu.
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


def realcar_lua(im: Image.Image) -> Image.Image:
    """Poe a lua da `montanhas/sky.png` a arder em vermelho-SANGUE.

    A lua original e' pessego claro -- tres tons, `(251,188,161)` e
    vizinhos, 2237 pixeis ao todo. Sao os unicos pixeis do ceu com
    r > 200, portanto a regra e' exata e nao apanha mais nada. Faz-se
    ANTES da tinta e a tinta depois poupa-os: se se tingisse a lua com o
    resto do ceu ela ficava cinzenta, que foi o que aconteceu a' primeira
    versao.

    A prancha da Regiao II tem uma lua de SANGUE, e e' o unico elemento
    quente do ceu -- e' ela que faz as ruinas lerem-se a contraluz.
    """
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0 or r <= 200:
                continue
            # quanto mais clara era, mais perto do nucleo da lua
            f = min(1.0, (r - 200) / 55.0)
            px[x, y] = (
                int(210 + 45 * f),
                int(LUA[1] * (0.7 + 0.5 * f)),
                int(LUA[2] * (0.7 + 0.5 * f)),
                a,
            )
    return im


def _e_lua(r: int, _g: int, _b: int) -> bool:
    return r > 200


def ceu() -> Image.Image:
    """Fundo: o ceu alto com a lua de sangue, uma so' vez na tira."""
    im = _carregar("montanhas", "sky.png")            # 320x240
    im = realcar_lua(im)
    im = tingir(im, CEU, 0.5, dessat=0.4, poupar=_e_lua)
    return alargar(im, 5, enchimento=0.22)


def serras() -> Image.Image:
    """Longe: cristas distantes com as ruinas goticas em cima.

    As cristas vem da `montanhas/far.png`; as torres vem da silhueta da
    `cidade/vila.png`, reduzida e posta na linha do horizonte -- e' o que
    faz a diferenca entre "uma serra" e "um desfiladeiro habitado".
    """
    base = _carregar("montanhas", "far.png")          # 160x240
    base = base.resize((480, 240), Image.NEAREST)
    base = tingir(base, SOMBRA, 0.62, dessat=0.62)

    vila = _carregar("cidade", "vila.png")            # 384x288
    # so' a metade de cima: os telhados, sem a rua
    vila = vila.crop((0, 0, 384, 150)).resize((360, 132), Image.NEAREST)
    vila = tingir(vila, SOMBRA, 0.9, dessat=0.9)      # quase so' silhueta
    vila.putalpha(vila.getchannel("A").point(lambda v: int(v * 0.85)))

    out = Image.new("RGBA", (480, 240), (0, 0, 0, 0))
    out.alpha_composite(vila, (58, 54))
    out.alpha_composite(base, (0, 0))
    return alargar(out, 3, enchimento=0.34)


def nuvens() -> Image.Image:
    """Meio: o mar de nuvens. E' esta camada que diz ALTITUDE."""
    im = _carregar("rochoso", "back.png")             # 512x240
    im = tingir(im, NUVEM, 0.58, dessat=0.5)
    # o mar de nuvens vive na metade de baixo do ecra: o topo desaparece
    alfa = im.getchannel("A")
    w, h = im.size
    px = alfa.load()
    for y in range(h):
        f = max(0.0, min(1.0, (y - h * 0.18) / (h * 0.3)))
        for x in range(w):
            px[x, y] = int(px[x, y] * f)
    im.putalpha(alfa)
    return im


def falesias() -> Image.Image:
    """Perto: a rocha exposta -- as paredes do desfiladeiro."""
    meio = _carregar("rochoso", "middle.png")         # 512x240
    perto = _carregar("rochoso", "near.png")          # 512x240
    # a `near.png` do pack `rochoso` e' vermelho-tijolo `(84,36,56)`. Sem
    # dessaturar quase tudo, as paredes do desfiladeiro saiam castanhas --
    # canyon do Arizona, nao falesia ao luar.
    meio = tingir(meio, PEDRA, 0.55, dessat=0.5)
    perto = tingir(perto, SOMBRA, 0.78, dessat=0.92)
    out = Image.new("RGBA", (512, 240), (0, 0, 0, 0))
    out.alpha_composite(meio, (0, 0))
    # a parede de ca' entra pelos lados, deixando o meio aberto ao ceu
    out.alpha_composite(perto, (-140, 16))
    out.alpha_composite(perto.transpose(Image.FLIP_LEFT_RIGHT), (150, 24))
    return out


CAMADAS = {
    "ceu.png": ceu,
    "serras.png": serras,
    "nuvens.png": nuvens,
    "falesias.png": falesias,
}


def main() -> None:
    os.makedirs(DEST, exist_ok=True)
    for nome, faz in CAMADAS.items():
        im = faz()
        im.save(os.path.join(DEST, nome))
        print("  %-14s %s" % (nome, im.size))
    print("%d camadas -> %s" % (len(CAMADAS), os.path.relpath(DEST, RAIZ)))


if __name__ == "__main__":
    main()
