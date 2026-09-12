#!/usr/bin/env python3
"""Execution 9H.12D -- KIT DE TERRENO HD DA REGIAO I.

    python tools/gerar_terreno_hd_regiao1.py

O problema medido na 9H.12B e confirmado pelo QA: o corpo das plataformas do
L1 e' `terreno_corpo.png` de **30x75 px** repetido ~35 vezes numa plataforma
de 1050 px. A 30 px de periodo, o olho ve a GRELHA, nao a rocha -- e' isso
que faz o chao ler-se como mosaico pobre contra um fundo pintado.

A materia-prima ja' estava no repo e estava a ser deitada fora: as pranchas
de `_source/imagegen_v1/` tem 1254x1254 a 2172x724 e o produtor antigo
(`build_region_01_sprite_kit.py`) reduzia-as a 32/64/96 px porque o contrato
pedia "hard pixel clusters; no antialiasing". Esse contrato caiu na 9H.12D
(direccao HYBRID CINEMATIC 2D): aqui reamostra-se com Lanczos e guarda-se o
antialiasing.

O que sai, em `kit_9c/terreno/`:

  terreno_corpo_hd.png   384x384  massa de rocha, periodo 12x maior
  terreno_topo_hd.png    512x56   capa com musgo e trepadeiras
  terreno_lado_hd.png     28x384  corte lateral
  terreno_base_hd.png    512x34   franja de pedras de baixo

Todas as pecas sao COSTURAVEIS: as arestas que vao encostar a` copia
seguinte levam um cross-fade, senao o `texture_repeat` marca uma linha a
cada periodo (que seria trocar uma grelha de 30 px por uma de 384).

GRADUACAO: a fonte e' pedra azul-acinzentada com musgo amarelo-lima vivo. O
lima a full em TODA a massa era metade do "parede de tijolo amarelo" que o
QA viu. Aqui o musgo do CORPO recua (dessaturado e escurecido) e so' a CAPA
o mantem -- e' onde ele faz sentido e onde da' leitura a` aresta de pouso.
"""
from __future__ import annotations

import colorsys
import os

from PIL import Image, ImageEnhance

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTE = os.path.join(RAIZ, "assets", "art", "regions", "region_01_forest",
                     "production", "_source", "imagegen_v1")
SAIDA = os.path.join(RAIZ, "assets", "art", "regions", "region_01_forest",
                     "production", "kit_9c", "terreno")

## Luar frio da Regiao I: a pedra da fonte e' neutra demais para a noite da
## prancha 08. Multiplicador por canal + escurecimento global.
LUAR = (0.98, 0.96, 1.04)
ESCURO = 0.62


def carregar(nome: str) -> Image.Image:
	return Image.open(os.path.join(FONTE, nome + ".png")).convert("RGBA")


def graduar(im: Image.Image, musgo: float, escuro: float = ESCURO) -> Image.Image:
	"""Luar frio + recuo do musgo. `musgo` = quanto do lima da fonte fica
	(1.0 = tudo, 0.0 = pedra). O musgo identifica-se pelo MATIZ (60-110 graus
	no circulo), nao por um limiar de verde: a pedra azul tambem tem verde."""
	im = im.copy()
	px = im.load()
	w, h = im.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a == 0:
				continue
			hh, ll, ss = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
			if 0.14 <= hh <= 0.33 and ss > 0.22:      # musgo/lima
				ss *= musgo
				ll *= 0.70 + 0.30 * musgo
				hh = 0.33 - (0.33 - hh) * (0.45 + 0.55 * musgo)   # puxa ao verde
				r2, g2, b2 = colorsys.hls_to_rgb(hh, ll, ss)
				r, g, b = r2 * 255.0, g2 * 255.0, b2 * 255.0
			px[x, y] = (
				min(255, int(r * LUAR[0] * escuro)),
				min(255, int(g * LUAR[1] * escuro)),
				min(255, int(b * LUAR[2] * escuro)), a)
	return im


def costurar_x(im: Image.Image, n: int) -> Image.Image:
	"""Cross-fade da aresta direita sobre a esquerda: a copia seguinte encosta
	sem linha. Devolve a imagem com `n` px cortados a` direita."""
	w, h = im.size
	esq = im.crop((0, 0, n, h))
	dir_ = im.crop((w - n, 0, w, h))
	mist = Image.new("RGBA", (n, h))
	for x in range(n):
		t = x / float(n - 1) if n > 1 else 0.0        # 0 na esquerda
		col_e = esq.crop((x, 0, x + 1, h))
		col_d = dir_.crop((x, 0, x + 1, h))
		mist.paste(Image.blend(col_d, col_e, t), (x, 0))
	out = im.crop((0, 0, w - n, h))
	out.paste(mist, (0, 0))
	return out


def costurar_y(im: Image.Image, n: int) -> Image.Image:
	return costurar_x(im.transpose(Image.ROTATE_90), n).transpose(Image.ROTATE_270)


def escrever(im: Image.Image, nome: str) -> None:
	cam = os.path.join(SAIDA, nome + ".png")
	im.save(cam)
	print("%-22s %s" % (nome, im.size))


def main() -> int:
	os.makedirs(SAIDA, exist_ok=True)

	# --- CORPO: massa de rocha, periodo 384 px (era 30) -------------------
	fill = carregar("terrain_fill")
	# recorte central: as pontas da prancha tem a moldura mais escura
	lado = min(fill.size) - 120
	cx, cy = fill.size[0] // 2, fill.size[1] // 2
	corpo = fill.crop((cx - lado // 2, cy - lado // 2, cx + lado // 2, cy + lado // 2))
	corpo = corpo.resize((384 + 48, 384 + 48), Image.LANCZOS)
	corpo = graduar(corpo, musgo=0.34, escuro=0.80)
	corpo = costurar_y(costurar_x(corpo, 48), 48)
	escrever(corpo, "terreno_corpo_hd")

	# --- CAPA: musgo e trepadeiras, periodo 512 px ------------------------
	seg = carregar("platform_large_segment")
	w, h = seg.size
	# a coroa da prancha ocupa o terco de cima, MAS a prancha tem uma margem
	# transparente por cima: cortar por fraccao gravava 56 px em que 40 eram
	# vazio e a capa saia preta. O corte sai da caixa do ALFA, nao de uma
	# fraccao escrita a mao.
	topo_util = seg.crop((0, 0, w, int(h * 0.42)))
	caixa = topo_util.getchannel("A").getbbox()
	capa = topo_util.crop((0, caixa[1], w, caixa[3]))
	capa = capa.resize((512 + 64, 56), Image.LANCZOS)
	capa = graduar(capa, musgo=0.62, escuro=0.80)
	capa = costurar_x(capa, 64)
	escrever(capa, "terreno_topo_hd")

	# --- LADO: corte lateral, periodo 384 px ------------------------------
	esq = carregar("terrain_edge_left")
	we, he = esq.size
	lat = esq.crop((0, int(he * 0.18), int(we * 0.22), he))
	lat = lat.resize((28, 384 + 48), Image.LANCZOS)
	lat = graduar(lat, musgo=0.34, escuro=0.74)
	lat = costurar_y(lat, 48)
	escrever(lat, "terreno_lado_hd")

	# --- BASE: franja de pedras de baixo ----------------------------------
	base_util = seg.crop((0, int(h * 0.55), w, h))
	cb = base_util.getchannel("A").getbbox()
	base = base_util.crop((0, cb[1], w, cb[3]))
	base = base.resize((512 + 64, 34), Image.LANCZOS)
	base = graduar(base, musgo=0.22, escuro=0.66)
	base = costurar_x(base, 64)
	escrever(base, "terreno_base_hd")

	return 0


if __name__ == "__main__":
	raise SystemExit(main())
