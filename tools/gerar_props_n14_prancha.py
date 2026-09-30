#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Pecas do N14 (Campanario) recortadas das PRANCHAS APROVADAS.

    python tools/gerar_props_n14_prancha.py
    (depois: godot --headless --import)

Mesmo metodo do `tools/gerar_props_n13_prancha.py`: recorte 1:1, fundo
escuro -> alfa, aparar, ampliar com Lanczos. Nenhum PNG editado a' mao.

Fonte: `region_03/level_mechanics.png`, coluna "N14 -- CAMPANARIO" --
sino em sequencia, plataforma grande (oscilacao), correntes controlaveis,
vento vertical, plataforma temporizada, sino gigante (com a trave e os
contrapesos), plataforma circular, corrente que muda direcao, sino em
queda, vento que empurra, laminas em cruz.

Grava ficheiros NOVOS com prefixo `c_` em `assets/sprites/pixel/deco/torres/`.
"""

from __future__ import annotations

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gerar_props_prancha import DEST, PRANCHA, aparar, com_alfa, sem_molduras  # noqa: E402

MECANICAS = os.path.join(os.path.dirname(PRANCHA), "level_mechanics.png")

# nome -> (caixa (x0, y0, x1, y1) por dentro da moldura, ampliacao)
CAIXAS = {
	# MECANICAS PRINCIPAIS
	"c_sino_sequencia": ((927, 430, 982, 491), 3),
	"c_plat_oscilante": ((984, 430, 1048, 491), 3),
	"c_correntes": ((1051, 430, 1102, 491), 3),
	"c_updraft": ((1104, 430, 1158, 491), 3),
	"c_plat_temporizada": ((1161, 430, 1213, 491), 3),
	# ELEMENTOS UNICOS
	"c_sino_gigante": ((927, 546, 1004, 614), 4),
	"c_plat_circular": ((1007, 546, 1083, 614), 3),
	"c_corrente_muda": ((1086, 546, 1147, 614), 3),
	# HAZARDS
	"c_sino_queda": ((927, 666, 991, 722), 3),
	"c_vento": ((993, 666, 1072, 722), 3),
	"c_laminas_cruz": ((1074, 666, 1148, 722), 3),
}


def main() -> None:
	fonte = Image.open(MECANICAS).convert("RGB")
	for nome, (caixa, amp) in CAIXAS.items():
		x0, y0, x1, y1 = caixa
		p = aparar(sem_molduras(com_alfa(fonte.crop((x0 + 2, y0 + 2, x1 - 2, y1 - 2)))))
		p = p.resize((p.width * amp, p.height * amp), Image.Resampling.LANCZOS)
		p.save(os.path.join(DEST, nome + ".png"), optimize=True)
		print("%s: %dx%d" % (nome, p.width, p.height))


if __name__ == "__main__":
	main()
