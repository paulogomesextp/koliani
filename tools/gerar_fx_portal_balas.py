#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Recorta o PORTAL de fim de nivel e as BALAS DE ENERGIA roxas.

Dois packs que o Paulo largou em `assets/sprites/incoming/` (ambos
`.gitignore`d -- so' se comita a tira ja' recortada):

  codemanu/     "Pixel FX Pack" do CodeManu/DavitMasia -- DOMINIO PUBLICO
                ("no credit required", ver o README.txt do pack). A folha
                `13_vortex_spritesheet.png` sao 8x8 frames de 100x100 de um
                vortice de particulas a rodar. E' o substituto GRATIS do
                portal da Frostwindz, que era pago e cuja licenca proibe
                redistribuir os ficheiros num repo publico (ver LICENSES.md).
                O vermelho do pack e' recolorido para o magenta da casa.
  bullets-500/  "500 Bullet 24x24 Free". Cada folha e' 576x360 = 24x15
                celulas de 24x24, organizada em TRES blocos de cor de 5
                linhas; dentro de cada linha ha' tres balas de 8 frames
                (colunas 0-7, 8-15, 16-23). A paleta muda de folha para
                folha: no `Part 1A` os blocos sao laranja/vermelho/ROXO,
                no `Part 2C` sao LAVANDA/prateado/branco. Usam-se so' os
                blocos que casam com a casa (roxo e lavanda).

Saida (tiras horizontais, uma linha de frames, prontas para `hframes`):

  assets/sprites/pixel/props/portal.png       2048x64, 32 frames
  assets/sprites/pixel/fx/bala_roxa.png       192x24, 8 frames (Koliani)
  assets/sprites/pixel/fx/bala_roxa_grande.png  192x24, 8 frames (Zeriko)
  assets/sprites/pixel/fx/flare_roxo.png      192x24, 8 frames (kamehameha)
  assets/sprites/pixel/fx/tiro_{dardo,seta,risco}.png  192x24, 8 frames
                                             (o tiro da Koliani, sorteado)

  python tools/gerar_fx_portal_balas.py
  python tools/gerar_fx_portal_balas.py --preview   # + _preview_*.png x4
"""

from __future__ import annotations

import os
import sys

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INC = os.path.join(RAIZ, "assets", "sprites", "incoming")
FX = os.path.join(RAIZ, "assets", "sprites", "pixel", "fx")
PROPS = os.path.join(RAIZ, "assets", "sprites", "pixel", "props")

PORTAL = os.path.join(INC, "codemanu", "13_vortex_spritesheet.png")
BALAS = os.path.join(INC, "bullets-500")

# nome de saida -> (folha, linha 0-14 da folha, grupo de 8 colunas)
# (o bloco roxo do `Part 1A` comeca na linha 10; o lavanda do `2C` na 0)
CORTES = {
    # vortice a girar: as bolas do Zeriko ficaram com esta forma
    "fx/bala_roxa": ("Bullet 24x24 Free Part 1A.png", 10, 0),
    # anel grosso a pulsar
    "fx/bala_roxa_grande": ("Bullet 24x24 Free Part 1A.png", 14, 1),
    # estrela espetada: a cabeca do kamehameha
    "fx/flare_roxo": ("Bullet 24x24 Part 7A Free.png", 10, 2),
    # -- os TRES que o Paulo escolheu (bloco lavanda do 2C): o tiro basico
    # da Koliani sorteia um destes a cada disparo, para nao sair sempre a
    # mesma coisa. Sao formas DIRECCIONAIS -- apontam para onde vao.
    "fx/tiro_dardo": ("Bullet 24x24 Free Part 2C.png", 2, 0),
    "fx/tiro_seta": ("Bullet 24x24 Free Part 2C.png", 3, 0),
    "fx/tiro_risco": ("Bullet 24x24 Free Part 2C.png", 4, 0),
}


def _tira(folha: Image.Image, celula: int, cels: list[tuple[int, int]]) -> Image.Image:
    """Cola as celulas `(coluna, linha)` numa tira horizontal."""
    fora = Image.new("RGBA", (celula * len(cels), celula), (0, 0, 0, 0))
    for i, (cx, cy) in enumerate(cels):
        recorte = folha.crop((cx * celula, cy * celula, (cx + 1) * celula, (cy + 1) * celula))
        fora.paste(recorte, (i * celula, 0))
    return fora


def _gravar(img: Image.Image, caminho: str, preview: bool) -> None:
    os.makedirs(os.path.dirname(caminho), exist_ok=True)
    img.save(caminho)
    print(f"  {os.path.relpath(caminho, RAIZ)}  {img.width}x{img.height}")
    if preview:
        pasta, nome = os.path.split(caminho)
        fundo = Image.new("RGBA", img.size, (18, 10, 28, 255))
        fundo.alpha_composite(img)
        fundo = fundo.resize((img.width * 3, img.height * 3), Image.NEAREST)
        fundo.save(os.path.join(pasta, "_preview_" + nome))


## Rampa magenta/violeta para o vortice: escuro -> roxo, meio -> magenta,
## brilho -> rosa quase branco. O pack e' vermelho e o jogo e' de luar roxo.
RAMPA_PORTAL = [(26, 6, 44), (92, 20, 130), (168, 40, 198), (232, 96, 236),
                (255, 198, 252)]
## Quantos dos 64 frames e' que entram na tira (de 2 em 2 -- 32 chegam para o
## rodopio se ler continuo e a tira fica com metade da largura).
PASSO_PORTAL = 2


def _tingir(img: Image.Image, rampa: list) -> Image.Image:
    """Troca a cor guardando a forma: luminancia -> tom da `rampa`."""
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    src, dst = img.load(), out.load()
    n = len(rampa) - 1
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = src[x, y]
            if a == 0:
                continue
            f = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
            pos = f * n
            i = min(int(pos), n - 1)
            t = pos - i
            c0, c1 = rampa[i], rampa[i + 1]
            dst[x, y] = (int(c0[0] + (c1[0] - c0[0]) * t),
                         int(c0[1] + (c1[1] - c0[1]) * t),
                         int(c0[2] + (c1[2] - c0[2]) * t), a)
    return out


def gerar_portal(preview: bool) -> None:
    if not os.path.exists(PORTAL):
        print(f"! falta {os.path.relpath(PORTAL, RAIZ)} -- portal saltado")
        return
    folha = _tingir(Image.open(PORTAL).convert("RGBA"), RAMPA_PORTAL)
    # 8x8 celulas de 100x100, lidas por linhas (a animacao e' continua)
    cels = [(i % 8, i // 8) for i in range(0, 64, PASSO_PORTAL)]
    tira = _tira(folha, 100, cels)
    # 100 -> 64 px por frame: o portal tem ~44 px de altura em jogo, e a
    # 100 a tira ficava com 3200 px de largura sem se ganhar detalhe
    tira = tira.resize((64 * len(cels), 64), Image.LANCZOS)
    _gravar(tira, os.path.join(PROPS, "portal.png"), preview)


def gerar_balas(preview: bool) -> None:
    for nome, (folha_nome, linha, grupo) in CORTES.items():
        caminho = os.path.join(BALAS, folha_nome)
        if not os.path.exists(caminho):
            print(f"! falta {os.path.relpath(caminho, RAIZ)} -- {nome} saltado")
            continue
        folha = Image.open(caminho).convert("RGBA")
        cels = [(grupo * 8 + i, linha) for i in range(8)]
        destino = os.path.join(RAIZ, "assets", "sprites", "pixel", *nome.split("/"))
        _gravar(_tira(folha, 24, cels), destino + ".png", preview)


def main() -> None:
    preview = "--preview" in sys.argv
    print("portal de fim de nivel:")
    gerar_portal(preview)
    print("balas de energia:")
    gerar_balas(preview)
    print("feito. Nao esquecer o --headless --import do Godot.")


if __name__ == "__main__":
    main()
