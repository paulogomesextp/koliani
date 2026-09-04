#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Gera os icones da app Web (PWA) a partir do `key_art.png`.

O build Web e' a unica via gratis para iPhone: abre-se no Safari e faz-se
"Adicionar ao ecra principal". Para isso ficar em cheio (icone proprio, sem
barra do browser, em landscape) o preset "Web" tem de ter o PWA ligado, e o
PWA precisa de tres icones quadrados.

O `key_art.png` NAO e' um icone -- e' um cartaz inteiro (logo, texto, tres
mosaicos de regiao, badges das lojas). Cortado ao quadrado pelo centro sai
uma miniatura ilegivel. O que serve e' o RETRATO dela, em baixo a' esquerda
do cartaz: e' a `CAIXA` abaixo, medida a olho sobre a imagem, apertada para
nao apanhar nem a etiqueta "FLORESTA PUTREFATA" (por cima) nem a barra
"Editar" (por baixo).

Saida: assets/branding/pwa_{144,180,512}.png

  python tools/gerar_icones_pwa.py
"""

from __future__ import annotations

import os

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGEM = os.path.join(RAIZ, "assets", "branding", "key_art.png")
SAIDA = os.path.join(RAIZ, "assets", "branding")
TAMANHOS = (144, 180, 512)
## Recorte do retrato no `key_art.png` (405x464): x0, y0, x1, y1.
CAIXA = (54, 362, 126, 434)


def main() -> None:
    if not os.path.isfile(ORIGEM):
        raise SystemExit("falta o key_art: " + ORIGEM)
    im = Image.open(ORIGEM).convert("RGBA")
    quadrado = im.crop(CAIXA)

    for n in TAMANHOS:
        destino = os.path.join(SAIDA, "pwa_%d.png" % n)
        quadrado.resize((n, n), Image.LANCZOS).save(destino)
        print("pwa_%d.png  %dx%d" % (n, n, n))


if __name__ == "__main__":
    main()
