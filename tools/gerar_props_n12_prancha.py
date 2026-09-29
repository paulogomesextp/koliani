#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Pecas de cenario do N12 (Galerias Verticais) recortadas da PRANCHA APROVADA.

    python tools/gerar_props_n12_prancha.py
    (depois: godot --headless --import)

Complemento do `tools/gerar_props_prancha.py` (PR "arte das pranchas"), com
o MESMO metodo -- recorte 1:1 de `region_03/asset_atlas.png`, fundo escuro
-> alfa, aparar, ampliar com Lanczos -- mas so' para pecas que o catalogo
`torres` nao tinha: paredes e estruturas para a parede do fundo da torre,
vitrais variados, plataformas especiais, hazards, FX (raios de luz, poeira,
particulas) e vegetacao/detritos.

Grava FICHEIROS NOVOS com prefixo `p_` em `assets/sprites/pixel/deco/torres/`
-- nao sobrescreve nada do outro gerador. Nenhum PNG editado a' mao.

Tambem acaba a lista "o que ficou por fazer" do relatorio das pranchas
(`docs/execution_arte_pranchas_regioes_1_3.md`): os props do catalogo
`torres` que ainda eram formas geometricas (braseiro, memorial,
pedra_talhada, detritos, velas, janela_gotica, balaustrada, arco_pequeno,
corrente_sino) -- a `Plataforma` espalha-os sozinha em cima das lajes e
eram os unicos "cubos roxos" que sobravam nos niveis da Regiao III. Esses
sao SOBRESCRITOS com a MESMA ALTURA que tinham (a escala no mundo nao muda),
exactamente como o `gerar_props_prancha.py` faz aos outros. Correr o
`gerar_props_torre_ecos.py` depois deste desfa'-los; correr este outra vez.
"""

from __future__ import annotations

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gerar_props_prancha import PRANCHA, DEST, aparar, com_alfa, sem_molduras  # noqa: E402

CONCEITO = os.path.join(os.path.dirname(PRANCHA), "concept_environment.png")

# props antigos do catalogo `torres` -> (prancha, caixa, altura no mundo que
# o PNG antigo tinha). A prancha de atlas nao tem braseiro, janela pequena
# nem arco pequeno inteiro: esses vem da fila "ELEMENTOS DO CENARIO" da
# prancha de conceito (a mesma regiao, tambem aprovada).
SUBSTITUI = {
	"braseiro": (CONCEITO, (338, 478, 371, 546), 44),
	"janela_gotica": (CONCEITO, (242, 478, 281, 546), 76),
	"arco_pequeno": (CONCEITO, (176, 478, 229, 546), 104),
	"velas": (CONCEITO, (379, 478, 419, 546), 76),
	"corrente_sino": (CONCEITO, (655, 478, 701, 546), 96),
	"pedra_talhada": (PRANCHA, (1077, 527, 1117, 549), 38),
	"memorial": (PRANCHA, (934, 852, 1001, 924), 40),
	"detritos": (PRANCHA, (1352, 524, 1404, 548), 14),
	"balaustrada": (PRANCHA, (1096, 325, 1187, 411), 57),
}

# nome -> caixa (x0, y0, x1, y1) na prancha de 1536x1024, por dentro da
# moldura da celula.
CAIXAS = {
	# "PAREDES, ARCOS E ESTRUTURAS" (y 160-250)
	"p_parede": (901, 162, 940, 249),
	"p_parede_gasta": (955, 162, 1003, 249),
	"p_parede_vitral": (1019, 160, 1076, 250),
	"p_torre_lateral": (1394, 160, 1446, 250),
	"p_parede_destruida": (1450, 164, 1518, 250),
	# "VITRAIS E JANELAS" (y 318-420)
	"p_vitral_dourado": (1275, 318, 1327, 421),
	"p_rosacea": (1396, 318, 1436, 360),
	"p_vitral_pequeno": (1399, 361, 1436, 421),
	# "PLATAFORMAS ESPECIAIS" e "ESCADAS E ESTRUTURAS" (y 322-410)
	"p_plat_corrente": (479, 322, 541, 402),
	"p_updraft": (774, 322, 841, 402),
	"p_estrutura_vertical": (1044, 322, 1086, 411),
	"p_passarela": (1096, 325, 1187, 411),
	"p_suporte": (1193, 325, 1247, 411),
	# "HAZARDS E OBSTACULOS" (y 612-676)
	"p_lamina_pendular": (67, 612, 119, 677),
	"p_lamina_rotativa": (124, 612, 176, 677),
	# "FX E PARTICULAS" (y 735-792)
	"p_particulas_luz": (93, 735, 151, 792),
	"p_poeira_ar": (158, 735, 216, 792),
	"p_brilho_sino": (219, 735, 281, 792),
	"p_raios_luz": (391, 735, 473, 796),
	"p_neblina": (481, 735, 541, 792),
	# "VEGETACAO E DETRITOS" (y 470-556)
	"p_heras": (1139, 468, 1207, 556),
	"p_detritos": (1349, 474, 1406, 556),
	"p_poeira_chao": (1409, 474, 1521, 556),
}

# FX: o fundo escuro e' quase da cor do proprio efeito nas bordas, por isso o
# alfa vem da LUMINANCIA (mais claro = mais opaco), como o mar de nuvens da
# Regiao II no PR das pranchas -- senao ficam com um "cartao" escuro a' volta.
FX = {"p_particulas_luz", "p_poeira_ar", "p_brilho_sino", "p_raios_luz", "p_neblina",
	"p_updraft"}

AMPLIAR = 2


def alfa_luminancia(im: Image.Image) -> Image.Image:
	rgba = im.convert("RGBA")
	px = rgba.load()
	for y in range(rgba.height):
		for x in range(rgba.width):
			r, g, b, _ = px[x, y]
			lum = 0.3 * r + 0.55 * g + 0.15 * b
			a = max(0.0, min(1.0, (lum - 34.0) / 100.0))
			px[x, y] = (r, g, b, int(255 * a))
	return rgba


def main() -> None:
	src = Image.open(PRANCHA).convert("RGB")
	for nome, caixa in CAIXAS.items():
		# 3 px para dentro: a moldura clara da celula nao pode entrar
		x0, y0, x1, y1 = caixa
		corte = src.crop((x0 + 3, y0 + 2, x1 - 3, y1 - 2))
		p = alfa_luminancia(corte) if nome in FX else com_alfa(corte)
		p = aparar(sem_molduras(p))
		p = p.resize((p.width * AMPLIAR, p.height * AMPLIAR), Image.Resampling.LANCZOS)
		p.save(os.path.join(DEST, nome + ".png"), optimize=True)
		print("%s: %dx%d" % (nome, p.width, p.height))
	fontes: dict = {}
	for nome, (fonte, caixa, alt) in SUBSTITUI.items():
		if fonte not in fontes:
			fontes[fonte] = Image.open(fonte).convert("RGB")
		x0, y0, x1, y1 = caixa
		p = aparar(sem_molduras(com_alfa(fontes[fonte].crop((x0 + 2, y0, x1 - 2, y1)))))
		larg = max(1, round(p.width * alt / p.height))
		p = p.resize((larg, alt), Image.Resampling.LANCZOS)
		p.save(os.path.join(DEST, nome + ".png"), optimize=True)
		print("%s: %dx%d (substitui o geometrico)" % (nome, larg, alt))


if __name__ == "__main__":
	main()
