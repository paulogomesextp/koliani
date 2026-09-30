#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Pecas do N15 (O Topo dos Ecos) recortadas das PRANCHAS APROVADAS.

    python tools/gerar_props_n15_prancha.py
    (depois: godot --headless --import)

Mesmo metodo do `tools/gerar_props_n14_prancha.py`: recorte 1:1, fundo
escuro -> alfa, aparar, ampliar com Lanczos. Nenhum PNG editado a' mao.

Fonte: `region_03/level_mechanics.png`, coluna "N15 -- O TOPO DOS ECOS" --
combinacao de sinos, plataformas dinamicas, ecos de memoria (plataformas
ilusorias), vento intenso, elementos destrutiveis; plataforma final
(multiplas fases), sinos celestiais, fragmentos de eco (ativam a arena),
estruturas em colapso; feixes de luz, plataformas instaveis, queda com
vento, destrocos.

Grava ficheiros NOVOS com prefixo `f_` em `assets/sprites/pixel/deco/torres/`.
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
	"f_sinos": ((1227, 430, 1282, 491), 3),
	"f_plat_dinamica": ((1285, 430, 1345, 491), 3),
	"f_ecos_memoria": ((1349, 430, 1412, 491), 3),
	"f_vento": ((1415, 430, 1464, 491), 3),
	"f_destrutiveis": ((1466, 430, 1522, 491), 3),
	# ELEMENTOS UNICOS
	"f_plat_final": ((1227, 546, 1305, 614), 4),
	"f_sinos_celestiais": ((1308, 546, 1380, 614), 3),
	"f_fragmentos": ((1382, 546, 1457, 614), 3),
	"f_colapso": ((1460, 546, 1523, 614), 3),
	# HAZARDS
	"f_feixes": ((1227, 666, 1306, 722), 3),
	"f_instavel": ((1308, 666, 1386, 722), 3),
	"f_queda_vento": ((1388, 666, 1460, 722), 3),
	"f_destrocos": ((1462, 666, 1524, 722), 3),
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
