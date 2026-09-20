#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Puxa o terreno `torres` da Regiao III para a paleta APROVADA.

O QUE ESTAVA ERRADO, MEDIDO

A prancha `concept_environment.png` tem a paleta LOCKED da regiao: "pedra
antiga, azul noite, azul profundo, luz de lua, dourado envelhecido". Nas
cores dominantes da prancha o VERDE esta' sempre acima do VERMELHO --
(24,48,96), (48,72,144), (72,96,168): pedra azul-acinzentada fria.

No jogo era ao contrario. As dominantes do `topo.png` e do `corpo.png`
davam (96,72,120), (48,24,72), (24,0,48) -- vermelho ACIMA do verde, ou
seja VIOLETA. Vinha do `veio` magenta do key_art que o `gerar_terreno.py`
aplica a todas as regioes (`veio=0.26`) mais a tinta fria por cima.

Nao e' uma questao de gosto: o contrato §1 fixa a paleta, e a auditoria
tinha de classificar o eixo em MEDIUM por causa disto.

PORQUE E' QUE E' UM TOOL PROPRIO

O `tools/gerar_terreno.py` gera o `torres` a partir da folha do pack
`church`, que vive em `assets/sprites/incoming/` e NAO vem no Git -- nao
corre fora da maquina do Paulo. O precedente para derivar de um material
ja' gerado e' o `tools/gerar_terreno_regiao02.py`, que faz exactamente
isto para o `desfiladeiro`.

O bioma `torres` e' EXCLUSIVO da Regiao III (a Regiao II usa
`desfiladeiro`), portanto isto nao toca em mais nenhuma regiao.

IDEMPOTENTE: a primeira execucao guarda os originais em `_origem/` e
todas as execucoes derivam de la'. Correr duas vezes da' o mesmo
resultado -- sem isso, cada passagem escurecia mais.

  python3 tools/recolorir_terreno_torre_ecos.py
  (depois: godot --headless --import)
"""
from __future__ import annotations

import pathlib
import shutil

from PIL import Image

import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)

RAIZ = pathlib.Path(__file__).resolve().parent.parent
DEST = RAIZ / "assets/sprites/pixel/terreno/torres"
ORIGEM = DEST / "_origem"
FICHEIROS = ["topo.png", "corpo.png", "lado.png", "base.png"]


def _corrigir(px: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    """Tira o magenta sem achatar a textura.

    A correccao nao e' uma tinta por cima -- isso lavava o relevo. E' o
    VERDE a ser levantado ate' pelo menos a altura do vermelho, que e' o
    que distingue pedra azul-acinzentada de pedra violeta, com o vermelho
    a ceder um pouco e o azul a segurar.
    """
    r, g, b, a = px
    if a == 0:
        return px
    nr = r * 0.80
    ng = max(g, r * 0.92) * 1.02
    nb = b * 1.02 + 6.0
    return (
        max(0, min(255, int(round(nr)))),
        max(0, min(255, int(round(ng)))),
        max(0, min(255, int(round(nb)))),
        a,
    )


def _dominantes(im: Image.Image, n: int = 4):
    from collections import Counter
    dados = list(im.convert("RGB").resize((120, 120)).getdata())
    q = Counter((r // 24 * 24, g // 24 * 24, b // 24 * 24)
                for r, g, b in dados if 90 < r + g + b < 690)
    return q.most_common(n)


def main() -> None:
    ORIGEM.mkdir(parents=True, exist_ok=True)
    for nome in FICHEIROS:
        alvo = DEST / nome
        guardado = ORIGEM / nome
        if not alvo.exists():
            print(f"  {nome}: nao existe, saltado")
            continue
        if not guardado.exists():
            shutil.copy2(alvo, guardado)          # so' a primeira vez
        im = Image.open(guardado).convert("RGBA")
        antes = _dominantes(im, 3)
        saida = Image.new("RGBA", im.size)
        saida.putdata([_corrigir(p) for p in im.getdata()])
        saida.save(alvo)
        depois = _dominantes(saida, 3)
        # o `base.png` e' quase todo transparente: pode nao ter dominante
        a0 = antes[0][0] if antes else "-"
        d0 = depois[0][0] if depois else "-"
        print(f"  {nome:>10}  {a0} -> {d0}")

    print("\nregra: verde levantado ate' >= 0.92x o vermelho; a pedra passa de"
          "\nvioleta (R>G) a azul-acinzentada (G>=R), como a prancha.")


if __name__ == "__main__":
    main()
