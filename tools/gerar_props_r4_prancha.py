#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Pecas da Regiao IV (Fornalha, N16-N20) recortadas das PRANCHAS APROVADAS.

    python tools/gerar_props_r4_prancha.py
    (depois: godot --headless --import)

Mesmo metodo dos `gerar_props_n1X_prancha.py` da Regiao III: recorte 1:1,
fundo escuro -> alfa, aparar, ampliar com Lanczos. Nenhum PNG editado a' mao.

Fontes (todas em `docs/art_direction/regions/region_04/`):
  concept_environment.png  "ELEMENTOS DE CENARIO" (pecas grandes e limpas)
  asset_atlas.png          plataformas moveis, metal, tubagens, props,
                           hazards, interactivos, engrenagens, lava
  level_mechanics.png      "PROPS EXCLUSIVOS" de cada nivel

Grava em `assets/sprites/pixel/deco/fornalha/`, prefixo `r4_`. Os efeitos de
luz (jato, brasas, lava) ficam com alfa = brilho (`modo "luz"`): pintam-se em
blend ADD, em que o preto nao conta.
"""

from __future__ import annotations

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gerar_props_prancha import aparar, sem_molduras  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REG = os.path.join(RAIZ, "docs", "art_direction", "regions", "region_04")
DEST = os.path.join(RAIZ, "assets", "sprites", "pixel", "deco", "fornalha")

CON, ATL, MEC = "concept_environment.png", "asset_atlas.png", "level_mechanics.png"

# O fundo destas pranchas e' quase preto-azulado (~(1, 8, 12)); as pecas tem
# metal escuro, por isso o limiar e' mais baixo do que o da Regiao III.
FUNDO = (1, 8, 12)
ALFA_DE = 12.0
ALFA_ATE = 34.0

# nome -> (prancha, (x0, y0, x1, y1) medido na prancha 1536x1024, ampliacao,
#          modo) com modo "solido" (alfa por distancia ao fundo) ou "luz".
CAIXAS = {
	# --- ELEMENTOS DE CENARIO (concept_environment) ----------------------
	"r4_fornalha": (CON, (20, 852, 86, 928), 3, "solido"),
	"r4_coluna": (CON, (96, 852, 144, 928), 3, "solido"),
	"r4_arco_gotico": (CON, (152, 850, 222, 928), 3, "solido"),
	"r4_corrente": (CON, (231, 852, 291, 928), 3, "solido"),
	"r4_engrenagem": (CON, (300, 852, 391, 928), 3, "solido"),
	"r4_jato_fogo": (CON, (400, 852, 469, 928), 3, "luz"),
	"r4_detalhe_destrutivel": (CON, (476, 852, 572, 928), 3, "solido"),
	"r4_piso_quente": (CON, (96, 774, 160, 813), 3, "luz"),
	"r4_plat_metalica": (CON, (170, 774, 240, 813), 3, "solido"),
	"r4_plat_corrente": (CON, (249, 772, 322, 813), 3, "solido"),
	"r4_tubo_lava": (CON, (331, 774, 439, 813), 3, "solido"),
	"r4_valvula_roda": (CON, (447, 774, 506, 813), 3, "solido"),
	"r4_grelha": (CON, (515, 774, 572, 813), 3, "solido"),
	# --- PLATAFORMAS E ELEMENTOS MOVEIS (asset_atlas) --------------------
	"r4_plat_fixa": (ATL, (831, 171, 880, 296), 3, "solido"),
	"r4_plat_movel": (ATL, (890, 171, 951, 296), 3, "solido"),
	"r4_elevador": (ATL, (964, 171, 1003, 296), 3, "solido"),
	"r4_plat_em_corrente": (ATL, (1012, 171, 1044, 296), 3, "solido"),
	"r4_pistao_v": (ATL, (1057, 171, 1088, 296), 3, "solido"),
	"r4_pistao_h": (ATL, (1097, 171, 1146, 296), 3, "solido"),
	"r4_plat_oscilante": (ATL, (1155, 171, 1217, 296), 3, "solido"),
	# --- METAL E ESTRUTURAS ----------------------------------------------
	"r4_plataforma_a": (ATL, (431, 178, 510, 211), 3, "solido"),
	"r4_plataforma_b": (ATL, (431, 224, 510, 266), 3, "solido"),
	"r4_plataforma_c": (ATL, (431, 273, 510, 307), 3, "solido"),
	"r4_viga_suporte": (ATL, (519, 176, 569, 240), 3, "solido"),
	"r4_grade_quadro": (ATL, (519, 247, 569, 303), 3, "solido"),
	"r4_grades": (ATL, (579, 174, 639, 307), 3, "solido"),
	"r4_parede_pilar": (ATL, (646, 176, 680, 306), 3, "solido"),
	"r4_arco_a": (ATL, (688, 174, 749, 244), 3, "solido"),
	"r4_arco_b": (ATL, (688, 250, 749, 307), 3, "solido"),
	"r4_estrutura": (ATL, (760, 178, 807, 307), 3, "solido"),
	# --- TUBAGENS E MAQUINARIA -------------------------------------------
	"r4_tubo_reto": (ATL, (1271, 178, 1296, 300), 3, "solido"),
	"r4_tubo_curvo": (ATL, (1298, 190, 1336, 250), 3, "solido"),
	"r4_tubo_l": (ATL, (1271, 178, 1336, 295), 3, "solido"),
	"r4_valvulas": (ATL, (1344, 174, 1381, 296), 3, "solido"),
	"r4_juncoes": (ATL, (1391, 178, 1433, 296), 3, "solido"),
	"r4_maquina": (ATL, (1439, 172, 1472, 296), 3, "solido"),
	"r4_caldeira": (ATL, (1480, 170, 1523, 301), 3, "solido"),
	# --- PROPS E DETALHES AMBIENTAIS -------------------------------------
	"r4_forno": (ATL, (484, 380, 548, 465), 3, "solido"),
	"r4_brasas": (ATL, (554, 416, 610, 465), 3, "luz"),
	"r4_bandeira": (ATL, (662, 372, 697, 465), 3, "solido"),
	"r4_blocos_parede": (ATL, (707, 380, 755, 424), 3, "solido"),
	"r4_caixa": (ATL, (716, 433, 755, 465), 3, "solido"),
	"r4_minerio_pilha": (ATL, (764, 400, 816, 432), 3, "solido"),
	"r4_carrinho_minerio": (ATL, (768, 433, 814, 465), 3, "solido"),
	"r4_sucata": (ATL, (822, 384, 876, 465), 3, "solido"),
	"r4_gancho": (ATL, (882, 372, 907, 465), 3, "solido"),
	"r4_polia": (ATL, (910, 394, 961, 465), 3, "solido"),
	"r4_bigorna": (ATL, (967, 395, 1027, 465), 3, "solido"),
	# --- HAZARDS ---------------------------------------------------------
	"r4_espinhos_solo": (ATL, (16, 576, 66, 618), 3, "solido"),
	"r4_espinhos_teto": (ATL, (75, 540, 135, 583), 3, "solido"),
	"r4_jato_a": (ATL, (149, 538, 181, 616), 3, "luz"),
	"r4_lamina_rotativa": (ATL, (199, 553, 259, 618), 3, "solido"),
	"r4_martelo": (ATL, (268, 536, 326, 610), 3, "solido"),
	"r4_prensa": (ATL, (337, 536, 371, 618), 3, "solido"),
	"r4_chao_desaba": (ATL, (382, 541, 456, 617), 3, "solido"),
	"r4_lava_eruptiva": (ATL, (462, 536, 529, 618), 3, "luz"),
	# --- INTERACTIVOS ----------------------------------------------------
	"r4_alavanca": (ATL, (550, 556, 599, 614), 3, "solido"),
	"r4_valvula_int": (ATL, (611, 548, 653, 614), 3, "solido"),
	"r4_placa_pressao": (ATL, (722, 594, 778, 614), 3, "solido"),
	"r4_porta_metal": (ATL, (812, 539, 871, 618), 3, "solido"),
	"r4_porta_corrente": (ATL, (881, 539, 944, 618), 3, "solido"),
	"r4_plat_ativada": (ATL, (957, 545, 1014, 616), 3, "solido"),
	"r4_mecanismo": (ATL, (1027, 540, 1094, 616), 3, "solido"),
	# --- ENGRENAGENS -----------------------------------------------------
	"r4_eng_grande": (ATL, (1050, 372, 1146, 468), 3, "solido"),
	"r4_eng_media": (ATL, (1150, 378, 1212, 436), 3, "solido"),
	"r4_eng_pequena": (ATL, (1222, 378, 1254, 410), 3, "solido"),
	"r4_eixos": (ATL, (1270, 378, 1322, 466), 3, "solido"),
	# --- LAVA ------------------------------------------------------------
	"r4_lava_estatica": (ATL, (15, 425, 71, 466), 4, "luz"),
	"r4_lava_movimento": (ATL, (79, 418, 144, 466), 4, "luz"),
	"r4_queda_lava": (ATL, (152, 375, 214, 466), 3, "luz"),
	"r4_lava_borbulhante": (ATL, (297, 375, 376, 466), 3, "luz"),
	# --- PROPS EXCLUSIVOS (level_mechanics) ------------------------------
	"r4_portao_forja": (MEC, (36, 920, 90, 975), 4, "solido"),
	"r4_trilho_minerio": (MEC, (108, 934, 195, 962), 4, "solido"),
	"r4_grelha_incandescente": (MEC, (216, 918, 269, 965), 4, "solido"),
	"r4_caldeirao": (MEC, (326, 916, 379, 969), 4, "solido"),
	"r4_elevador_corrente": (MEC, (407, 908, 469, 972), 4, "solido"),
	"r4_plat_industrial": (MEC, (486, 918, 560, 967), 4, "solido"),
}


# modo "luz" com limiar proprio: o vermelho-escuro de fundo de alguns efeitos
# (queda de lava, jato) tem brilho ~60 e dava um retangulo de bordas duras.
LIMIAR_LUZ = {"r4_queda_lava": 90.0, "r4_jato_fogo": 70.0, "r4_jato_a": 60.0,
	"r4_lava_eruptiva": 80.0, "r4_lava_borbulhante": 40.0, "r4_piso_quente": 40.0}
# pecas que se usam rodadas 90 graus (a `Line2D` ladrilha ao longo da linha)
ROTADAS = {}
# versao FINA da corrente para a `Line2D` das plataformas penduradas (que
# poe a largura da linha = largura da textura): 20 px de largura
FINAS = {"r4_corrente": ("r4_corrente_fina", 20)}


def suave_bordas(im: Image.Image, fr: float = 0.16) -> Image.Image:
	"""Esbate o alfa nas bordas do recorte (efeitos de luz nao levam corte
	direito: a caixa da prancha nao pode ler-se no jogo)."""
	a = im.getchannel("A")
	w, h = im.size
	px = a.load()
	fx, fy = max(2, int(w * fr)), max(2, int(h * fr))
	for y in range(h):
		ky = min(1.0, min(y, h - 1 - y) / fy)
		for x in range(w):
			k = min(ky, min(1.0, min(x, w - 1 - x) / fx))
			px[x, y] = int(px[x, y] * k * k * (3 - 2 * k))
	out = im.copy()
	out.putalpha(a)
	return out


def com_alfa(im: Image.Image, modo: str, nome: str = "") -> Image.Image:
	rgba = im.convert("RGBA")
	px = rgba.load()
	lim = LIMIAR_LUZ.get(nome, 10.0)
	for y in range(rgba.height):
		for x in range(rgba.width):
			r, g, b, _ = px[x, y]
			if modo == "luz":
				a = max(r, g, b) / 255.0
				a = max(0.0, min(1.0, (a * 255.0 - lim) / 50.0))
			else:
				d = ((r - FUNDO[0]) ** 2 + (g - FUNDO[1]) ** 2 + (b - FUNDO[2]) ** 2) ** 0.5
				a = max(0.0, min(1.0, (d - ALFA_DE) / (ALFA_ATE - ALFA_DE)))
			px[x, y] = (r, g, b, int(255 * a))
	return rgba


def main() -> None:
	os.makedirs(DEST, exist_ok=True)
	fontes: dict[str, Image.Image] = {}
	for nome, (prancha, caixa, amp, modo) in CAIXAS.items():
		if prancha not in fontes:
			fontes[prancha] = Image.open(os.path.join(REG, prancha)).convert("RGB")
		x0, y0, x1, y1 = caixa
		p = com_alfa(fontes[prancha].crop((x0, y0, x1, y1)), modo, nome)
		p = aparar(sem_molduras(p))
		p = p.resize((p.width * amp, p.height * amp), Image.Resampling.LANCZOS)
		if modo == "luz" and nome not in ("r4_piso_quente",):
			p = suave_bordas(p, 0.18)
		p.save(os.path.join(DEST, nome + ".png"), optimize=True)
		if nome in FINAS:
			nn, w = FINAS[nome]
			p.resize((w, max(1, round(p.height * w / p.width))), Image.Resampling.LANCZOS).save(
				os.path.join(DEST, nn + ".png"), optimize=True)
		if nome in ROTADAS:
			p.transpose(Image.Transpose.ROTATE_90).save(
				os.path.join(DEST, ROTADAS[nome] + ".png"), optimize=True)
		print("%s: %dx%d" % (nome, p.width, p.height))


if __name__ == "__main__":
	main()
