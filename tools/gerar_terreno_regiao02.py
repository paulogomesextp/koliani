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

## Props do `torres` que NAO servem o Desfiladeiro. Sao os do audit: cruz e
## lapide sao cemiterio, e a flamula e' lavanda onde o canone pede carmesim
## (ha' a `bandeira` da prancha, que e' carmesim e tem a cruz).
FORA_DA_REGIAO = {"cruz", "lapide", "flamula"}

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
    # NAO fazer `cat["desfiladeiro"] = cat["torres"]`.
    #
    # Era o que estava aqui, e e' a origem exacta do achado do audit: a
    # Regiao II ficava com o catalogo INTEIRO da Regiao III, incluindo
    # `cruz` e `lapide`, que sao vocabulario de cemiterio e nao aparecem em
    # nenhuma prancha do Desfiladeiro. Os props canonicos da regiao vem
    # agora do `extrair_props_regiao02.py`, recortados da prancha aprovada,
    # e esta linha apagava-os de cada vez que alguem corresse este script.
    #
    # Os props do `torres` continuam a ser RECOLORIDOS (o `for` acima) e
    # ficam no disco -- ha' entradas que sobreviveram ao corte (balaustrada,
    # tocha, velas, coluna...) e essas continuam a apontar para estes PNG.
    # O que muda e' que o catalogo nao se reescreve: acrescenta-se o que
    # falta e nao se mexe no que ja' la' esta'.
    jah = {p["nome"] for p in cat.get("desfiladeiro", [])}
    for prop in cat["torres"]:
        if prop["nome"] not in jah and prop["nome"] not in FORA_DA_REGIAO:
            cat.setdefault("desfiladeiro", []).append(dict(prop))
    with open(DECO_MANIFESTO, "w", encoding="utf-8", newline="\n") as f:
        json.dump(cat, f, indent=1, ensure_ascii=False)
        f.write("\n")
    return n


def folhagem_no_topo(topo: Image.Image) -> Image.Image:
    """Folhagem CARMESIM a nascer do labio da pedra.

    O audit poe o terreno como "maior desvio visual" da regiao, e nao por
    causa da cor: a prancha define o Desfiladeiro por pedra com folhagem
    carmesim a cair das bordas, e o jogo tinha uma parede de alvenaria sem
    uma unica folha -- em 100% do ecra, 100% do tempo, nos cinco niveis.

    As folhas nao sao desenhadas aqui: sao as `vegetacao_*` recortadas da
    prancha aprovada pelo `extrair_props_regiao02.py`, encolhidas para a
    escala do labio. Se ainda nao tiverem sido extraidas, o terreno sai
    como antes em vez de rebentar.

    O `plataforma.gd` desenha a capa a partir de `y0 - SUPERFICIE`, ou seja
    as 8 primeiras linhas da textura caem ACIMA da linha onde se pisa. E'
    nessas que a folhagem vive, com a base a entrar uns pixeis na pedra para
    nao ficar pousada por cima.

    A tira e' um mosaico de 96 px: quem cruza a borda e' carimbado tambem do
    outro lado, senao aparecia um corte a cada 96 px de plataforma.
    """
    tufos = []
    for nome, alt in (("vegetacao_alta.png", 15), ("vegetacao_baixa.png", 11),
                      ("vegetacao_alta.png", 10)):
        cam = os.path.join(DECO_DEST, nome)
        if not os.path.exists(cam):
            continue
        v = Image.open(cam).convert("RGBA")
        e = alt / float(v.height)
        tufos.append(v.resize((max(1, round(v.width * e)), alt), Image.LANCZOS))
    if not tufos:
        print("  (sem vegetacao extraida -- topo fica sem folhagem)")
        return topo

    fora = topo.copy()
    # posicoes fixas: o terreno tem de sair igual entre sessoes
    for i, (x, k, espelho) in enumerate((
            (6, 0, False), (27, 1, True), (46, 2, False),
            (63, 1, False), (82, 0, True))):
        t = tufos[k % len(tufos)]
        if espelho:
            t = t.transpose(Image.FLIP_LEFT_RIGHT)
        y = 9 - t.height + 3           # 3 px enterrados na pedra
        for dx in (0, -fora.width, fora.width):
            fora.alpha_composite(t, (x + dx, max(0, y))) if 0 <= x + dx < fora.width else None
            if x + dx + t.width > fora.width and dx == 0:
                fora.alpha_composite(t, (x - fora.width, max(0, y)))
    return fora


def main() -> None:
    os.makedirs(DEST, exist_ok=True)
    for nome in PECAS:
        origem = os.path.join(BASE, nome)
        im = recolorir(Image.open(origem))
        if nome == "topo.png":
            im = folhagem_no_topo(im)
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
