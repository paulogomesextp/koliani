#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Pecas do N13 (Mecanismos Antigos) recortadas das PRANCHAS APROVADAS.

    python tools/gerar_props_n13_prancha.py
    (depois: godot --headless --import)

Mesmo metodo do `tools/gerar_props_prancha.py` e do
`tools/gerar_props_n12_prancha.py`: recorte 1:1, fundo escuro -> alfa,
aparar, ampliar com Lanczos. Nenhum PNG editado a' mao.

Fontes:
  * `region_03/level_mechanics.png`, coluna do N13 -- rodas de engrenagem,
    sino com padrao, alavanca, plataforma rotativa, ponte reconfiguravel,
    mecanismo central de 3 sinos, ponte movel, engrenagem giratoria,
    contrapeso, engrenagem mortal, corrente com peso, lamina de pendulo;
  * `region_03/asset_atlas.png`, "INTERATIVOS E MECANICAS" -- alavanca,
    interruptor, mecanismo de sino, porta com chave, elevador, roda.

Grava ficheiros NOVOS com prefixo `m_` em `assets/sprites/pixel/deco/torres/`.
"""

from __future__ import annotations

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gerar_props_prancha import DEST, PRANCHA, aparar, com_alfa, sem_molduras  # noqa: E402

MECANICAS = os.path.join(os.path.dirname(PRANCHA), "level_mechanics.png")

# nome -> (prancha, caixa (x0, y0, x1, y1) por dentro da moldura, ampliacao)
CAIXAS = {
	# level_mechanics.png, coluna "N13 -- MECANISMOS ANTIGOS"
	"m_roda": (MECANICAS, (629, 435, 678, 491), 4),
	"m_sino_padrao": (MECANICAS, (687, 435, 733, 491), 3),
	"m_plat_rotativa": (MECANICAS, (795, 437, 853, 489), 3),
	"m_ponte_reconfig": (MECANICAS, (859, 449, 908, 481), 3),
	"m_mecanismo_central": (MECANICAS, (631, 547, 695, 613), 4),
	"m_ponte_movel": (MECANICAS, (701, 558, 776, 611), 3),
	"m_engrenagem": (MECANICAS, (783, 551, 841, 614), 4),
	"m_contrapeso": (MECANICAS, (851, 547, 910, 613), 3),
	"m_engrenagem_mortal": (MECANICAS, (631, 671, 695, 719), 3),
	"m_corrente_peso": (MECANICAS, (796, 665, 820, 718), 3),
	"m_lamina_pendulo": (MECANICAS, (851, 666, 913, 719), 3),
	# asset_atlas.png, "INTERATIVOS E MECANICAS"
	"m_alavanca": (PRANCHA, (837, 622, 881, 674), 3),
	"m_interruptor": (PRANCHA, (889, 614, 934, 674), 3),
	"m_mecanismo_sino": (PRANCHA, (1009, 609, 1058, 674), 3),
	"m_porta": (PRANCHA, (1069, 609, 1121, 674), 3),
	"m_elevador": (PRANCHA, (1129, 611, 1168, 674), 3),
}


# "TEXTURAS E MATERIAIS (REFERENCIA)" do atlas: amostras quadradas que se
# repetem sem alfa (metal, bronze, madeira) e as correntes douradas (com
# alfa, repetem na vertical). Portas de bronze, bracos das rodas, casas das
# maquinas.
TEXTURAS = {
	"m_tex_metal": ((590, 37, 634, 89), False),
	"m_tex_bronze": ((647, 37, 692, 89), False),
	"m_tex_madeira": ((760, 40, 798, 89), False),
	"m_tex_correntes": ((813, 36, 827, 91), True),
}


def main() -> None:
	fontes: dict = {}
	for nome, (fonte, caixa, amp) in CAIXAS.items():
		if fonte not in fontes:
			fontes[fonte] = Image.open(fonte).convert("RGB")
		x0, y0, x1, y1 = caixa
		p = aparar(sem_molduras(com_alfa(fontes[fonte].crop((x0 + 2, y0 + 2, x1 - 2, y1 - 2)))))
		p = p.resize((p.width * amp, p.height * amp), Image.Resampling.LANCZOS)
		p.save(os.path.join(DEST, nome + ".png"), optimize=True)
		print("%s: %dx%d" % (nome, p.width, p.height))
	atlas = Image.open(PRANCHA).convert("RGB")
	for nome, (caixa, alfa) in TEXTURAS.items():
		p = atlas.crop(caixa)
		if alfa:
			p = aparar(com_alfa(p))
		else:
			p = p.convert("RGBA")
		p = p.resize((p.width * 2, p.height * 2), Image.Resampling.LANCZOS)
		p.save(os.path.join(DEST, nome + ".png"), optimize=True)
		print("%s: %dx%d" % (nome, p.width, p.height))


if __name__ == "__main__":
	main()
