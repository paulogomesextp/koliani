#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Recorta os CANDEEIROS e as TOCHAS que iluminam os niveis.

O Paulo queixou-se de que "o jogo esta' um bocado escuro no geral" e pediu
"candeeiros ou lampadas a acompanhar os niveis". Sao dois props, os dois de
packs que ja' estao em `incoming/` e cujos fundos ja' andam no jogo:

  gothicvania/GothicVania-town-files/.../props-sliced/street-lamp.png
      Candeeiro de rua gotico, 35x108, tres lanternas em cima. Poste roxo
      escuro + luz ambar -- e' exactamente a paleta do `key_art`.
  ansimuz-parallax/Cold Corridors Files/Assets/Torch/torch-sheet.png
      Tocha de parede, 128x32 = 4 frames de 32x32, chama animada.

Os dois sao do Ansimuz (Luis Zuno). Saida:

  assets/sprites/pixel/props/candeeiro.png   35x108, 1 frame
  assets/sprites/pixel/props/tocha.png       4 frames numa tira horizontal

A tocha e' recortada pela UNIAO das caixas dos 4 frames -- frame a frame a
chama mudava de tamanho e o sprite abanava no sitio.

  python tools/gerar_luzes.py
  python tools/gerar_luzes.py --preview   # + _preview_*.png x4
"""

from __future__ import annotations

import os
import sys

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INCOMING = os.path.join(RAIZ, "assets", "sprites", "incoming")
SAIDA = os.path.join(RAIZ, "assets", "sprites", "pixel", "props")

CANDEEIRO = os.path.join(
    INCOMING, "gothicvania", "GothicVania-town-files", "PNG", "environment",
    "props-sliced", "street-lamp.png",
)
TOCHA = os.path.join(
    INCOMING, "ansimuz-parallax", "Cold Corridors Files", "Assets", "Torch",
    "torch-sheet.png",
)

TOCHA_CEL = 32
LIMIAR_ALPHA = 8


def _caixa(im: Image.Image) -> tuple[int, int, int, int] | None:
    return im.getchannel("A").point(lambda v: 255 if v > LIMIAR_ALPHA else 0).getbbox()


def _gravar(im: Image.Image, nome: str, preview: bool) -> None:
    os.makedirs(SAIDA, exist_ok=True)
    im.save(os.path.join(SAIDA, nome))
    print("%s  %dx%d" % (nome, im.width, im.height))
    if preview:
        im.resize((im.width * 4, im.height * 4), Image.NEAREST).save(
            os.path.join(SAIDA, "_preview_" + nome)
        )


def gerar_candeeiro(preview: bool) -> None:
    if not os.path.isfile(CANDEEIRO):
        raise SystemExit("falta o pack GothicVania Town: " + CANDEEIRO)
    im = Image.open(CANDEEIRO).convert("RGBA")
    caixa = _caixa(im)
    if caixa:
        im = im.crop(caixa)
    _gravar(im, "candeeiro.png", preview)


def gerar_tocha(preview: bool) -> None:
    if not os.path.isfile(TOCHA):
        raise SystemExit("falta o pack Cold Corridors: " + TOCHA)
    folha = Image.open(TOCHA).convert("RGBA")
    n = folha.width // TOCHA_CEL
    frames = [folha.crop((i * TOCHA_CEL, 0, (i + 1) * TOCHA_CEL, folha.height))
              for i in range(n)]

    # uniao das caixas: a chama muda de tamanho de frame para frame e, se
    # cada um fosse apertado a' sua, a tocha abanava no sitio
    caixas = [c for c in (_caixa(f) for f in frames) if c]
    if not caixas:
        raise SystemExit("tocha vazia")
    x0 = min(c[0] for c in caixas)
    y0 = min(c[1] for c in caixas)
    x1 = max(c[2] for c in caixas)
    y1 = max(c[3] for c in caixas)

    largura, altura = x1 - x0, y1 - y0
    tira = Image.new("RGBA", (largura * n, altura), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        tira.paste(f.crop((x0, y0, x1, y1)), (i * largura, 0))
    _gravar(tira, "tocha.png", preview)


def main() -> None:
    preview = "--preview" in sys.argv
    gerar_candeeiro(preview)
    gerar_tocha(preview)


if __name__ == "__main__":
    main()
