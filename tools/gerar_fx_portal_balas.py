#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Recorta o PORTAL de fim de nivel e as BALAS DE ENERGIA roxas.

Dois packs que o Paulo largou em `assets/sprites/incoming/` (ambos
`.gitignore`d -- so' se comita a tira ja' recortada):

  frostwindz/   "Pixel Art Animated Portal" (comprado; licenca Frostwindz,
                uso comercial OK, redistribuicao NAO -- ver LICENSES.md).
                Folha 256x128 = celulas de 64x64, 7 frames uteis.
                ATENCAO: o `portal_fim.png` que sai daqui esta' no
                `.gitignore` e NAO e' usado pelo jogo -- o repo e' publico e
                a clausula 2.1 da licenca nao deixa. Fica para experimentar
                em local; a `Porta.tscn` continua com o vortice por codigo.
  bullets-500/  "500 Bullet 24x24 Free". Cada folha e' 576x360 = 24x15
                celulas de 24x24, organizada em TRES blocos de cor de 5
                linhas; dentro de cada linha ha' tres balas de 8 frames
                (colunas 0-7, 8-15, 16-23). A paleta muda de folha para
                folha: no `Part 1A` os blocos sao laranja/vermelho/ROXO,
                no `Part 2C` sao LAVANDA/prateado/branco. Usam-se so' os
                blocos que casam com a casa (roxo e lavanda).

Saida (tiras horizontais, uma linha de frames, prontas para `hframes`):

  assets/sprites/pixel/props/portal_fim.png   448x64, 7 frames (SO' LOCAL)
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

PORTAL = os.path.join(INC, "frostwindz", "portal_sheet.png")
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


def gerar_portal(preview: bool) -> None:
    if not os.path.exists(PORTAL):
        print(f"! falta {os.path.relpath(PORTAL, RAIZ)} -- portal saltado")
        return
    folha = Image.open(PORTAL).convert("RGBA")
    # 4 colunas x 2 linhas de 64px; o ultimo canto (3,1) esta' vazio
    cels = [(c, r) for r in range(2) for c in range(4)][:7]
    _gravar(_tira(folha, 64, cels), os.path.join(PROPS, "portal_fim.png"), preview)


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
