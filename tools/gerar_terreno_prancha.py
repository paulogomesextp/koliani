#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Terreno de uma regiao tirado DO TILESET DA PRANCHA APROVADA (29 set 2026).

    python tools/gerar_terreno_prancha.py            # todas as regioes
    python tools/gerar_terreno_prancha.py desfiladeiro
    (depois: godot --headless --import)

PORQUE E' QUE ISTO EXISTE

O terreno das Regioes II e III (`desfiladeiro`, `torres`) saia de
`tools/gerar_terreno.py` / `tools/gerar_terreno_regiao02.py`: tijolo CC0
generico recolorido. Nos niveis lia-se como uma laje roxa lisa, enquanto a
prancha aprovada da regiao (`asset_atlas_tileset.png`) tem pedra talhada com
musgo e vinhas carmesim. A auditoria de 29 set 2026 pos-o como a segunda
maior distancia entre a arte aprovada e o jogo, logo a seguir ao fundo.

Isto recorta as pecas 1:1 da prancha, amplia-as 2x (Lanczos, igual aos
fundos) e monta as quatro texturas que o `plataforma.gd` ja' sabe usar:

  corpo.png  miolo em mosaico, sem costura (alvenaria em junta desencontrada)
  topo.png   a capa: 8 px de balanco acima da linha de pouso (`SUPERFICIE`)
  lado.png   o corte lateral, com alfa fora da pedra
  base.png   o que se esfarela / pende por baixo, com alfa (mais alta do que
             os 24 px antigos: o `plataforma.gd` passa a usar a altura da
             textura)

Os tamanhos sao os do contrato antigo (topo 96x32, lado 16x96, base 96x24);
o corpo pode ter qualquer tamanho porque e' desenhado em mosaico.

As caixas (x0, y0, x1, y1) sao medidas na prancha de 1536x1024: as juntas
de argamassa foram encontradas pela luminancia media por linha/coluna, e os
recortes do corpo comecam e acabam numa junta para o mosaico nao ter costura.
"""

from __future__ import annotations

import os
import sys

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEST = os.path.join(RAIZ, "assets", "sprites", "pixel", "terreno")
FATOR = 2

REGIOES = {
	# Regiao II -- Desfiladeiro dos Ventos.
	"desfiladeiro": {
		"prancha": "docs/art_direction/regions/region_02/asset_atlas_tileset.png",
		# duas paredes, cada uma de junta a junta (2 pedras x 3 fiadas):
		# "PAREDES" (juntas x 547/561, y 57/75/94/113) e a coluna alta da
		# esquerda (juntas x 272, y 128/146/164/182)
		"corpo": [(533, 57, 561, 113), (256, 128, 282, 182)],
		# capas de cinco blocos da fiada de cima, lado a lado: pedra comeca
		# em y=40, musgo/flores de 37 a 39 -- linha de pouso em y=39
		"topo_y": (35, 51),
		"topo_x": [(254, 293), (404, 463), (534, 573), (595, 638), (310, 383)],
		# aresta esquerda da parede, com o fundo escuro da prancha a' volta
		"lado": (527, 57, 535, 105),
		# CASCA (`CascaMasmorra`, estilo "desfiladeiro"): as celulas 16x16 que
		# ela usa na folha `desfiladeiro_0x72.png` sao repintadas com pedra
		# da prancha. So' a imagem: coordenadas e colisao do `.tres` ficam.
		"casca_png": "assets/sprites/pixel/tiles/desfiladeiro_0x72.png",
		"casca": {
			(2, 1): (533, 58, 549, 74),   # wall_mid
			(1, 1): (547, 58, 563, 74),   # wall_left
			(3, 1): (547, 58, 563, 74),   # wall_right
			(2, 0): (404, 35, 420, 51),   # wall_top_mid (capa com musgo)
			(2, 4): (547, 76, 563, 92),   # floor_1
			(3, 2): (533, 76, 549, 92),   # wall_hole_1 (escurecida)
		},
		# a barriga da "ESTRUTURA GRANDE" (pedra a escorrer, vinhas carmesim):
		# comeca ainda na pedra (y=178), para a franja nascer agarrada ao
		# bloco em vez de flutuar por baixo dele
		"base": (505, 178, 570, 198),
	},
}

# Fundo escuro das pranchas (~ (1, 11, 20)): tudo o que e' perto dele e'
# transparente, com rampa para nao ficar serrilhado.
FUNDO = (2, 11, 20)
ALFA_DE = 18.0
ALFA_ATE = 60.0


def ampliar(im: Image.Image) -> Image.Image:
	return im.resize((im.width * FATOR, im.height * FATOR),
		Image.Resampling.LANCZOS)


# A capa da prancha e' carmesim quase puro; debaixo da luz magenta da
# Koliani e do `CanvasModulate` do bioma chegava ao ecra a gritar mais do que
# a propria Koliani. Tira-se-lhe um pouco de saturacao.
SATURACAO_TOPO = 0.78


def menos_saturado(im: Image.Image, f: float) -> Image.Image:
	from PIL import ImageEnhance
	a = im.getchannel("A") if im.mode == "RGBA" else None
	out = ImageEnhance.Color(im.convert("RGB")).enhance(f).convert("RGBA")
	if a is not None:
		out.putalpha(a)
	return out


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


def corpo(src: Image.Image, caixas: list) -> Image.Image:
	"""O miolo sao recortes de paredes da prancha cortados JUNTA A JUNTA
	(argamassa nas quatro bordas), postos lado a lado e trocados de ordem na
	segunda metade -- o mosaico fica sem costura e o padrao so' se repete de
	4 em 4 pedras em vez de 2 em 2.

	Tentou-se primeiro partir as paredes em pedras soltas e remontar fiadas
	ao acaso: a prancha e' pequena e irregular demais, a segmentacao apanhava
	fundo e contornos e o resultado lia-se como ruido. Espelhar tambem nao
	serve -- a simetria ve-se logo."""
	alt = (caixas[0][3] - caixas[0][1]) * FATOR
	pecas = []
	for cx in caixas:
		p = ampliar(src.crop(cx))
		pecas.append(p.resize((p.width, alt), Image.Resampling.LANCZOS))
	larg = sum(p.width for p in pecas)
	out = Image.new("RGBA", (larg, alt * 2))
	for fila, ordem in enumerate([pecas, pecas[::-1]]):
		x = 0
		for p in ordem:
			out.paste(p, (x, fila * alt))
			x += p.width
	return out


def topo(src: Image.Image, ys: tuple, xs: list) -> Image.Image:
	"""As capas de varios blocos lado a lado (o mosaico repete a tira toda,
	portanto a largura nao tem de ser 96)."""
	segs = [src.crop((a, ys[0], b, ys[1])) for a, b in xs]
	tira = Image.new("RGB", (sum(s.width for s in segs), ys[1] - ys[0]))
	x = 0
	for s in segs:
		tira.paste(s, (x, 0))
		x += s.width
	return menos_saturado(com_alfa(ampliar(tira)), SATURACAO_TOPO)


def franja(im: Image.Image) -> Image.Image:
	"""A barriga por baixo do bloco: o alfa por cor sozinho deixava bolhas
	soltas a flutuar debaixo da laje (a pedra da prancha nao e' continua na
	linha de cima). O terco de cima fica opaco a' forca, para a franja nascer
	AGARRADA ao bloco, e tudo escurece para baixo como a sombra do corpo."""
	rgba = com_alfa(im)
	px = rgba.load()
	h = rgba.height
	for y in range(h):
		t = y / max(1, h - 1)
		minimo = max(0.0, 1.0 - t / 0.35)
		esc = 0.85 - 0.45 * t
		for x in range(rgba.width):
			r, g, b, a = px[x, y]
			a = max(int(a * (1.0 - t) ** 0.7), int(255 * minimo))
			px[x, y] = (int(r * esc), int(g * esc), int(b * esc), a)
	return rgba


def casca(src: Image.Image, cfg: dict) -> None:
	"""Repinta as celulas da folha da `CascaMasmorra` (16 px, desenhada a 2x
	no jogo -- a mesma escala do terreno ampliado aqui)."""
	caminho = os.path.join(RAIZ, cfg["casca_png"])
	folha = Image.open(caminho).convert("RGBA")
	for (cx, cy), caixa in cfg["casca"].items():
		cel = src.crop(caixa).convert("RGBA")
		if (cx, cy) == (3, 2):
			cel = Image.eval(cel, lambda v: v // 2)
			cel.putalpha(255)
		folha.paste(cel, (cx * 16, cy * 16))
	folha.save(caminho, optimize=True)
	print("%s: %d celulas" % (cfg["casca_png"], len(cfg["casca"])))


def gerar(nome: str, cfg: dict) -> None:
	src = Image.open(os.path.join(RAIZ, cfg["prancha"])).convert("RGB")
	dest = os.path.join(DEST, nome)
	os.makedirs(dest, exist_ok=True)
	pecas = {
		"corpo": corpo(src, cfg["corpo"]),
		"topo": topo(src, cfg["topo_y"], cfg["topo_x"]),
		"lado": com_alfa(ampliar(src.crop(cfg["lado"]))),
		"base": franja(ampliar(src.crop(cfg["base"]))),
	}
	for peca, im in pecas.items():
		im.save(os.path.join(dest, peca + ".png"), optimize=True)
		print("%s/%s.png %dx%d" % (nome, peca, im.width, im.height))
	if "casca" in cfg:
		casca(src, cfg)


def main() -> None:
	nomes = sys.argv[1:] or list(REGIOES)
	for n in nomes:
		gerar(n, REGIOES[n])


if __name__ == "__main__":
	main()
