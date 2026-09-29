#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Props da Torre dos Ecos recortados da PRANCHA APROVADA (29 set 2026).

    python tools/gerar_props_prancha.py
    (depois: godot --headless --import)

PORQUE E' QUE ISTO EXISTE

Os props do catalogo `torres` (`assets/sprites/pixel/deco/torres/`) sairam
de `tools/gerar_props_torre_ecos.py`: formas geometricas chapadas (sinos em
trapezio cor de mostarda, um relogio de mostrador liso, vitrais azuis em
grelha). Na auditoria de 29 set 2026 eram, a seguir ao fundo e ao terreno,
o que mais afastava os niveis da Regiao III da prancha aprovada
`region_03/asset_atlas.png`, que tem estes mesmos objectos pintados.

Isto recorta cada prop da prancha (fundo escuro -> alfa, aparado a' caixa
do desenho), amplia-o com Lanczos e grava-o POR CIMA do PNG antigo com a
MESMA ALTURA que ele tinha -- o `plataforma.gd` e a `atmosfera.gd` desenham
os props ao tamanho da textura, portanto a escala no mundo nao muda. So' a
largura acompanha a proporcao do desenho novo.

Correr o `gerar_props_torre_ecos.py` depois deste desfaz o trabalho: se for
preciso, corre-se este outra vez a seguir.
"""

from __future__ import annotations

import os

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRANCHA = os.path.join(RAIZ, "docs", "art_direction", "regions", "region_03",
	"asset_atlas.png")
DEST = os.path.join(RAIZ, "assets", "sprites", "pixel", "deco", "torres")

# nome do prop -> caixa (x0, y0, x1, y1) na prancha de 1536x1024, POR DENTRO
# da moldura de cada celula (a moldura clara nao pode entrar no recorte).
# "PROPS E CENARIO": y 466-546.
CAIXAS = {
	"estatua_anjo": (18, 471, 64, 546),
	"gargula": (122, 471, 172, 546),
	"coluna_igreja": (183, 471, 222, 546),
	"candelabro": (233, 471, 289, 546),
	"tocha": (300, 471, 337, 546),
	"lanterna_eco": (353, 471, 382, 546),
	"lampiao_t": (353, 471, 382, 546),
	"sino_p": (398, 471, 444, 546),
	"sino_m": (460, 471, 504, 546),
	"sino_g": (598, 471, 652, 546),
	"sino_partido": (665, 471, 712, 546),
	"relogio_antigo": (730, 471, 777, 546),
	"flamula": (788, 471, 827, 546),
	"livros": (878, 490, 917, 546),
	"urna": (1022, 490, 1068, 546),
	# "PAREDES, ARCOS E ESTRUTURAS" e "VITRAIS E JANELAS"
	"arco_grande": (1165, 160, 1230, 257),
	"vitral_alto": (1331, 318, 1382, 421),
	# o `Vitral` do N12 troca para este quando e' partido: tem de se ler
	# PARTIDO, por isso vem das "JANELAS QUEBRADAS" e nao de outro vitral
	"vitral_partido": (1447, 318, 1520, 412),
	"coluna_dupla": (1288, 167, 1333, 252),
	"pedra_memoria": (950, 610, 999, 676),
	"engrenagem": (1245, 617, 1300, 676),
}

# Altura no mundo (px) de cada prop -- a que o PNG gerado antigo tinha, para
# a escala no jogo nao mudar. Fixada aqui (e nao lida do PNG) para o script
# poder correr mais do que uma vez.
ALTURAS = {
	"estatua_anjo": 132, "gargula": 54, "coluna_igreja": 228, "candelabro": 70,
	"tocha": 62, "lanterna_eco": 56, "lampiao_t": 97, "sino_p": 28,
	"sino_m": 48, "sino_g": 96, "sino_partido": 46, "relogio_antigo": 58,
	"flamula": 106, "livros": 22, "urna": 34,
	"arco_grande": 190, "vitral_alto": 132, "vitral_partido": 92,
	"coluna_dupla": 210, "pedra_memoria": 40, "engrenagem": 44,
}

FUNDO = (1, 10, 16)
ALFA_DE = 16.0
ALFA_ATE = 48.0


def com_alfa(im: Image.Image) -> Image.Image:
	rgba = im.convert("RGBA")
	px = rgba.load()
	for y in range(rgba.height):
		for x in range(rgba.width):
			r, g, b, _ = px[x, y]
			d = ((r - FUNDO[0]) ** 2 + (g - FUNDO[1]) ** 2 + (b - FUNDO[2]) ** 2) ** 0.5
			a = max(0.0, min(1.0, (d - ALFA_DE) / (ALFA_ATE - ALFA_DE)))
			px[x, y] = (r, g, b, int(255 * a))
	return rgba


def sem_molduras(im: Image.Image) -> Image.Image:
	"""Apaga linhas/colunas quase cheias JUNTO A' BORDA do recorte: sao a
	moldura da celula. (So' ate' 4 px da borda -- um pilar tambem enche a
	coluna toda, e esse fica.)"""
	px = im.load()
	w, h = im.size
	perto = lambda i, n: i < 4 or i >= n - 4
	for y in [y for y in range(h) if perto(y, h)]:
		if sum(1 for x in range(w) if px[x, y][3] > 64) > 0.8 * w:
			for x in range(w):
				px[x, y] = (0, 0, 0, 0)
	for x in [x for x in range(w) if perto(x, w)]:
		if sum(1 for y in range(h) if px[x, y][3] > 64) > 0.9 * h:
			for y in range(h):
				px[x, y] = (0, 0, 0, 0)
	return im


def aparar(im: Image.Image) -> Image.Image:
	"""Corta a' caixa do que tem alfa a serio (ignora poeira < 25%)."""
	a = im.getchannel("A").point(lambda v: 255 if v > 64 else 0)
	caixa = a.getbbox()
	return im.crop(caixa) if caixa else im


def main() -> None:
	src = Image.open(PRANCHA).convert("RGB")
	for nome, caixa in CAIXAS.items():
		dest = os.path.join(DEST, nome + ".png")
		alt = ALTURAS.get(nome, 64)
		p = aparar(sem_molduras(com_alfa(src.crop(caixa))))
		larg = max(1, round(p.width * alt / p.height))
		p = p.resize((larg, alt), Image.Resampling.LANCZOS)
		p.save(dest, optimize=True)
		print("%s: %dx%d" % (nome, larg, alt))


if __name__ == "__main__":
	main()
