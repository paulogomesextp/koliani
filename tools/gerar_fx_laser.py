#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Recorta os LASERS ROXOS do pack Wenrexa "Laser2020".

O Paulo escolheu, na imagem de capa do pack, o cometa MAGENTA/roxo de cauda
comprida. A capa mostra 10 por linha e a numeracao dos ficheiros tambem anda
de 10 em 10 -- mas o 10.o ficheiro e' uma bola AMARELA, portanto a ordem da
capa nao bate certo com os nomes. Vai-se pelo conteudo (e pelo pedido escrito
dele, "roxo com brilho"): o cometa magenta e' o `13.png`.

  assets/sprites/incoming/wenrexa/laser2020/  (CC0, uso comercial, sem
                                               credito obrigatorio)

Sao glows suaves de alta resolucao, NAO pixel-art: recortam-se pelo alpha,
reduzem-se com LANCZOS e ficam a ser desenhados com filtro LINEAR (o no'
poe `texture_filter = 3`). Passa-los por Nearest so' lhes daria degraus.

A cabeca aponta para a DIREITA no pack, que e' a convencao do jogo.

Saida:

  assets/sprites/pixel/fx/laser_roxo.png       ~72x39  (tiro da Koliani)
  assets/sprites/pixel/fx/laser_raio_roxo.png  ~96x42  (kamehameha)

  python tools/gerar_fx_laser.py
  python tools/gerar_fx_laser.py --preview   # + _preview_*.png x4
"""

from __future__ import annotations

import os
import sys

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PACK = os.path.join(
    RAIZ, "assets", "sprites", "incoming", "wenrexa", "laser2020", "Laser Sprites"
)
SAIDA = os.path.join(RAIZ, "assets", "sprites", "pixel", "fx")

## (ficheiro de origem, nome de saida, largura final).
## 13 = cometa magenta de cauda comprida -- o que o Paulo apontou.
## 22 = raio roxo aos ziguezagues -- le'-se como feixe, serve o kamehameha
##      muito melhor do que o flare redondo que la' estava.
LASERS: list[tuple[str, str, int]] = [
    ("13.png", "laser_roxo.png", 72),
    ("22.png", "laser_raio_roxo.png", 96),
]

## Abaixo disto o pixel conta como fundo. O pack tem uma penugem de alpha 1-6
## a toda a volta que, se entrar no recorte, deixa a moldura folgada.
LIMIAR_ALPHA = 8


def _recortar(im: Image.Image) -> Image.Image:
    """Aperta a moldura ao que se ve' mesmo (alpha acima do limiar)."""
    mascara = im.getchannel("A").point(lambda v: 255 if v > LIMIAR_ALPHA else 0)
    caixa = mascara.getbbox()
    if caixa is None:
        raise SystemExit("laser vazio -- alpha todo abaixo do limiar")
    return im.crop(caixa)


def gerar(preview: bool) -> None:
    os.makedirs(SAIDA, exist_ok=True)
    for origem, nome, largura in LASERS:
        caminho = os.path.join(PACK, origem)
        if not os.path.isfile(caminho):
            raise SystemExit("falta o pack Wenrexa: " + caminho)
        im = _recortar(Image.open(caminho).convert("RGBA"))
        altura = max(1, round(im.height * largura / im.width))
        im = im.resize((largura, altura), Image.LANCZOS)
        destino = os.path.join(SAIDA, nome)
        im.save(destino)
        print("%s  %dx%d  <- %s" % (nome, im.width, im.height, origem))
        if preview:
            grande = im.resize((im.width * 4, im.height * 4), Image.NEAREST)
            grande.save(os.path.join(SAIDA, "_preview_" + nome))


def main() -> None:
    gerar("--preview" in sys.argv)


if __name__ == "__main__":
    main()
