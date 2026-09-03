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
GCASTELO = os.path.join(PATREON, "Gothic-Castle-Files", "PNG", "layers",
                        "gothic-castle-background.png")
SZADI = os.path.join(INC, "szadiart")


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


# Pecas do `gothic-castle-background.png`, medidas pelas ilhas de alfa da
# folha (ver o comentario de `tira`). Sao PECAS soltas, nao uma tira de
# parallax: e' preciso monta-las lado a lado.
GC = {
    "escadaria": (16, 0, 176, 160),     # escadaria + lustre de velas
    "janela": (192, 0, 272, 160),
    "gargula": (288, 0, 368, 160),
    "alcova": (384, 0, 464, 160),       # nicho de rocha com dois circios
    "pilar_ossos": (16, 176, 144, 304),
    "parede": (160, 176, 224, 304),
    "coluna": (240, 176, 256, 304),
    "coluna_luz": (272, 176, 288, 304),  # tira estreita com lanterna
    "grades": (304, 176, 352, 304),      # PORTAO GRADEADO -- a cela
    "arco": (368, 176, 416, 304),
}


def realcar(im: Image.Image, gama: float) -> Image.Image:
    """Levanta os tons escuros sem queimar os claros (curva de gama).

    A folha do Gothic Castle e' desenhada quase a preto -- luminancia media
    ~11, quando a familia dos fundos interiores do jogo anda nos 26..46
    (`prisao` 26-46, `igreja` 37-58, `castelo_velho` 42). Posta no jogo tal
    e qual, com a dessaturacao e a tinta escura da Atmosfera por cima, dava
    um ecra preto: nao se via nem o portao gradeado nem a arcada. Multiplicar
    por um ganho queimava as chamas das velas; a gama levanta as sombras e
    deixa o 255 em 255.
    """
    tabela = [min(255, int(round(255.0 * (i / 255.0) ** (1.0 / gama)))) for i in range(256)]
    r, g, b, a = im.split()
    return Image.merge("RGBA", (r.point(tabela), g.point(tabela), b.point(tabela), a))


def empilhar(*tiras: Image.Image) -> Image.Image:
    """Poe tiras umas por cima das outras (a primeira em cima).

    Os packs do jogo tem 736 a 1325 px de altura depois da escala -- e' o
    que faz a camada tapar o ecra todo para cima a partir do `y_base`. Uma
    fiada sozinha desta folha da' 384 e ficava desenhada abaixo do ecra.
    """
    larg = max(t.size[0] for t in tiras)
    out = Image.new("RGBA", (larg, sum(t.size[1] for t in tiras)), (0, 0, 0, 0))
    y = 0
    for t in tiras:
        out.alpha_composite(t, (0, y))
        y += t.size[1]
    return out


def tira(folha: Image.Image, pecas: dict, ordem: list[str]) -> Image.Image:
    """Monta uma tira de parallax colando pecas da folha lado a lado.

    As folhas de "layers" da GothicVania nem sempre sao tiras prontas: a do
    Gothic Castle e' um mostruario de dez pecas separadas por alfa. Todas as
    pecas de uma `ordem` tem de ter a mesma altura (a folha agrupa-as por
    linha, portanto e' o caso).
    """
    cortes = [folha.crop(pecas[n]) for n in ordem]
    h = max(c.size[1] for c in cortes)
    out = Image.new("RGBA", (sum(c.size[0] for c in cortes), h), (0, 0, 0, 0))
    x = 0
    for c in cortes:
        out.alpha_composite(c, (x, h - c.size[1]))
        x += c.size[0]
    return out


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

    # --- masmorra (R2): o 2.o fundo da Prisao dos Condenados -------------
    # A R2 tinha UM pack para os cinco niveis. Esta folha do Gothic Castle
    # estava por usar e traz justamente o que falta a uma prisao: o portao
    # gradeado, o pilar de ossos, a arcada de pedra.
    if os.path.exists(GCASTELO):
        gc = realcar(Image.open(GCASTELO).convert("RGBA"), 1.8)
        # as duas fiadas tem exactamente a mesma largura (400 px), portanto
        # empilham sem folga: o salao em cima, o corredor de celas em baixo
        salao = tira(gc, GC, ["janela", "escadaria", "gargula", "alcova"])
        celas = tira(gc, GC, ["parede", "coluna", "grades", "coluna_luz",
                              "arco", "coluna", "pilar_ossos", "parede"])
        copia_im(empilhar(salao, celas), "masmorra", "parede.png")
        copia_im(celas, "masmorra", "celas.png")
        copia_im(tira(gc, GC, ["arco", "coluna", "parede", "coluna_luz"]),
                 "masmorra", "arcada.png")
    else:
        print("  ! falta", GCASTELO)

    # --- gruta (R4): o 2.o fundo das Catacumbas do Abismo ----------------
    # O Szadi "Fantasy Caves" (que ja' da' o terreno da R4) traz cinco
    # camadas de parallax prontas, 960x480, que nunca tinham sido usadas.
    copia(os.path.join(SZADI, "background1.png"), "gruta", "back.png")
    copia(os.path.join(SZADI, "background2.png"), "gruta", "rocha.png")
    copia(os.path.join(SZADI, "background3.png"), "gruta", "boca.png")
    copia(os.path.join(SZADI, "background4a.png"), "gruta", "estalactites.png")
    return 0


def copia_im(im: Image.Image, pack: str, nome: str) -> None:
    """Como `copia`, mas a partir de uma imagem ja' montada em memoria."""
    pasta = os.path.join(DEST, pack)
    os.makedirs(pasta, exist_ok=True)
    im.save(os.path.join(pasta, nome))
    print("  %-14s %-14s %dx%d" % (pack, nome, im.size[0], im.size[1]))


if __name__ == "__main__":
    raise SystemExit(main())
