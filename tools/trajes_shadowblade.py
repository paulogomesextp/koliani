#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Pecas e materiais da skin PREMIUM Shadowblade Koliani.

Vive num modulo proprio para nao tocar em `trajes_premium.py` (Anjo/Demonio):
a skin e' independente e reversivel. Regra do handoff: NENHUMA pose nova --
tudo aqui e' pintura/pecas coladas sobre os frames finais do Golden Set (incl.
`run_final`), ancoradas a cara como as outras premium. Cabelo prata/marfim,
base preto + roxo fundo, roxo neon so' como energia, metal escuro com um
brilho contido, arma curva de energia.
"""

from __future__ import annotations

import colorsys
import math

from PIL import Image, ImageDraw

import trajes_koliani as T
import trajes_premium as P

_hx = T._hx

K = "07040C"
# cabelo: sombra lilas -> marfim
PRATA = ["17141F", "393341", "625C70", "9C94AC", "CFC9DC", "EEEAF4"]
# roupa/couraca: preto arroxeado
NOITE = ["07040C", "140A22", "241238", "381C56", "50307A", "7A50B0"]
# capa/cornos
SOMBRA = ["07040C", "12081E", "1E1032", "2E1A4C", "44286E", "6A44A0"]
ROXO_NEON = "B040FF"
LILAS = "E0A0FF"
OURO_FOSCO = ["4A3410", "7A5A1C", "A88428", "C8A040", "E8CC70", "FFF0B0"]

ACENTO_ROXO = [(0.00, "090611"), (0.22, "251A39"), (0.42, "503168"),
			   (0.62, "875398"), (0.85, "C693D1"), (1.00, "ECE0F2")]
TECIDO_NOITE = [(0.00, "05030A"), (0.12, "0E0818"), (0.24, "1A0F2C"),
				(0.40, "2C1A48"), (0.70, "4C3078")]

SKIN = {
	"acento": ACENTO_ROXO, "tecido": TECIDO_NOITE, "forca_tecido": 0.65,
	"gema": "C060FF", "premium": "shadowblade",
}


# --------------------------------------------------------------------------
# Cabelo prata. No Golden Set cabelo e roupa tem a mesma cor (preto), por isso
# o cabelo apanha-se por GEOMETRIA relativa a cara: a cabeca e a cascata que
# cai por tras (os fios vermelhos do Golden Set entram por aqui tambem).
# --------------------------------------------------------------------------

def _rampa(c: list[str], t: float):
	# Transferencia de cor por pixel, SEM filtro espacial. Preserva a graduacao
	# original: quantizar em seis tons destruia as mechas finas do Golden.
	t = max(0.0, min(1.0, t)) * (len(c) - 1)
	i = min(int(t), len(c) - 2)
	a, b = _hx(c[i]), _hx(c[i + 1])
	f = t - i
	return tuple(round(a[k] + (b[k] - a[k]) * f) for k in range(3))


def cabelo_prata(orig: Image.Image, im: Image.Image, cara) -> Image.Image:
	im = im.copy()
	po, px = orig.load(), im.load()
	fx, fy = cara
	W, H = im.size
	for y in range(max(0, fy - 46), min(H, fy + 30)):
		for x in range(max(0, fx - 52), min(W, fx + 16)):
			r, g, b, a = po[x, y]
			if a < 40 or T._pele(r, g, b):
				continue
			h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
			dx, dy = x - fx, y - fy
			cabeca = -9 <= dx <= 8 and -14 <= dy <= 4
			vermelho = s > 0.35 and (h * 360 >= 320 or h * 360 <= 8)
			cascata = (dx < -3 and -6 <= dy <= 26 and vermelho) \
				or (vermelho and -44 <= dy < -6 and dx < 40) \
				or (dy < -4 and v < 0.3)
			# lenco/gola: junto ao pescoco, sob o queixo, fica roxo (nao prata)
			pescoco = -6 <= dx <= 7 and 4 < dy <= 10
			if pescoco and not cabeca:
				continue
			if not (cabeca or cascata):
				continue
			if v < 0.05 and a > 200 and s < 0.35:
				# contorno: fica muito escuro, so' um pouco roxo
				px[x, y] = (18, 10, 30, a)
				continue
			# brilho original 0.06..0.7 -> luz do cabelo; vermelho vivo (pontas) = claro
			# Sombras ficam sombras, em vez de todas virarem uma massa lilas clara.
			t = min(1.0, v / 0.85)
			cr, cg, cb = _rampa(PRATA, t)
			px[x, y] = (cr, cg, cb, a)
	return im


# --------------------------------------------------------------------------
# Pecas
# --------------------------------------------------------------------------

def cornos_sombra() -> tuple[Image.Image, int, int]:
	"""Coroa de dois cornos em obsidiana: contorno forte e pontas de prata.
	Pecas nativas, nao miniaturas reamostradas de outro traje.
	"""
	im = Image.new("RGBA", (23, 20), (0, 0, 0, 0))
	d = ImageDraw.Draw(im)
	for pontos in [[(7, 17), (2, 13), (1, 8), (3, 2), (5, 8), (5, 11), (10, 15)],
				   [(13, 15), (17, 11), (17, 6), (20, 1), (21, 8), (20, 13), (16, 17)]]:
		d.polygon(pontos, fill=_hx("514365"), outline=_hx(K))
	d.line([(3, 3), (3, 8), (5, 12), (8, 15)], fill=_hx("C3B6D8"), width=1)
	d.line([(20, 2), (19, 7), (19, 11), (16, 15)], fill=_hx("EEE3FF"), width=1)
	d.line([(7, 17), (16, 17)], fill=_hx("655375"), width=1)
	d.point((12, 16), fill=_hx("C8AACF"))
	return im, 12, 18


def capa_penas(vento: float) -> tuple[Image.Image, int, int]:
	"""Capa em duas penas longas, por tras do corpo, com forro ameixa.
	Recorte aberto: separa-se do cabelo e nunca pinta por cima dos membros.
	"""
	im = Image.new("RGBA", (36, 34), (0, 0, 0, 0))
	d = ImageDraw.Draw(im)
	recuo = round(vento * 8)
	cont = _hx(K)
	d.polygon([(29, 3), (22, 4), (10-recuo, 15), (3, 27), (15, 23), (8, 32),
			   (22, 25), (27, 15), (31, 6)], fill=_hx("443052"), outline=cont)
	d.polygon([(24, 6), (16-recuo, 17), (7, 27), (18, 20), (24, 13)], fill=_hx("9473AC"))
	d.polygon([(28, 8), (25, 21), (12, 30), (22, 19)], fill=_hx("74538F"))
	d.line([(22, 5), (11-recuo, 16), (4, 26)], fill=_hx("D3B3ED"), width=1)
	d.line([(27, 14), (24, 24), (10, 31)], fill=_hx("AA82C9"), width=1)
	return im, 29, 3


def ombreira_espigao() -> tuple[Image.Image, int, int]:
	"""Ombreira assimetrica de aco negro, com um espigao e friso de prata."""
	im = Image.new("RGBA", (12, 12), (0, 0, 0, 0))
	d = ImageDraw.Draw(im)
	d.polygon([(1, 4), (3, 1), (7, 3), (9, 0), (10, 5), (11, 8), (7, 10), (1, 8)],
			  fill=_hx("635071"), outline=_hx(K))
	d.line([(2, 4), (5, 3), (9, 5)], fill=_hx("E5D9F1"), width=1)
	d.line([(2, 7), (7, 8), (10, 7)], fill=_hx("71647C"), width=1)
	d.point((6, 5), fill=_hx("B68AC8"))
	return im, 6, 6


def manopla_sombra(orig: Image.Image, im: Image.Image, cara) -> Image.Image:
	"""Bracelete no braco original: segue os pixels de pele, nao inventa pose.
	As duas faixas de metal ficam longe da cara/pernas, sem massa sobreposta.
	"""
	po, px = orig.load(), im.load()
	fx, fy = cara
	for y in range(max(0, fy+13), min(im.height, fy+24)):
		for x in range(max(0, fx-18), min(im.width, fx+24)):
			r, g, b, a = po[x, y]
			if a < 180 or not T._pele(r, g, b) or abs(x-fx) < 7:
				continue
			# A forma do membro e o alfa original sao conservados.
			v = max(r, g, b) / 255
			cor = _rampa(["17121F", "393040", "766581", "B4A7BD"], v)
			px[x, y] = (*cor, a)
	return im


def lamina_sombra(d, p, u, comp, c):
	"""Lamina curva de sombra com fio de energia (referencia 'main weapon'):
	dorso negro, fio roxo, guarda em asa com gema, punho enrolado."""
	n = (-u[1], u[0])
	A = T._ao_longo
	L = comp + 6
	# lamina em arco: o centro desvia para o lado do dorso
	N = 14
	pts = []
	for i in range(N + 1):
		t = i / N
		curva = math.sin(t * math.pi * 0.85) * 2.6
		q = A(p, u, 3 + (L - 3) * t)
		pts.append((q[0] + n[0] * curva, q[1] + n[1] * curva))
	for i in range(N):
		w = 3.2 * (1 - i / N) + 0.7
		T._quad(d, pts[i], pts[i + 1], w, 3.2 * (1 - (i + 1) / N) + 0.7, c["lamina"])
	# fio de energia no gume (lado oposto ao dorso) e veio central
	for i in range(N):
		a0 = (pts[i][0] - n[0] * 1.6, pts[i][1] - n[1] * 1.6)
		a1 = (pts[i + 1][0] - n[0] * 1.6, pts[i + 1][1] - n[1] * 1.6)
		d.line([a0, a1], fill=c["fio"], width=1)
	d.line([pts[1], pts[N - 3]], fill=c["gume"], width=1)
	d.point([pts[-1]], fill=c["gume"])
	# guarda em asa
	g = A(p, u, 2.5)
	for s in (-1, 1):
		a0 = (g[0] + n[0] * s * 1.0, g[1] + n[1] * s * 1.0)
		a1 = (g[0] + n[0] * s * 4.6 - u[0] * 1.5, g[1] + n[1] * s * 4.6 - u[1] * 1.5)
		T._quad(d, a0, a1, 2.0, 0.8, c["guarda"])
	T._quad(d, A(p, u, -4), A(p, u, 2), 1.8, 1.8, c["punho"])
	d.point([A(p, u, -5)], fill=c["gume"])
	d.point([g], fill=c["gume"])


T.ARMAS["lamina_sombra"] = lamina_sombra

ARMA_CORES = {"lamina": "140A22", "gume": "F0D0FF", "fio": "A040FF",
			  "guarda": "A88428", "punho": "241238"}


def _veios_tronco(orig, im, cara):
	"""Veios de energia so' no tronco/ombros: nas pernas ficavam a ruido."""
	com = P.veios_lava(orig, im, cara, ["7A22D8", "A040FF", "E0A0FF"])
	fora = im.copy()
	corte = cara[1] + 16
	fora.paste(com.crop((0, 0, im.width, corte)), (0, 0))
	return fora


def vestir_shadowblade(orig: Image.Image, im: Image.Image, cara, lam, indice: int) -> Image.Image:
	im = cabelo_prata(orig, im, cara)
	# O metal e o emblema conservam o conceito; rachas aleatorias sujavam o peito.
	# Roupa/peito mantem TODOS os detalhes pintados originalmente: a placa
	# procedural e a orla dourada substituiam-nos por ruido de baixa resolucao.
	im = P.olhos(im, cara, "E070FF", orig)
	im = T.trocar_arma(im, lam, "lamina_sombra", ARMA_CORES, K)
	im = manopla_sombra(orig, im, cara)
	vento = 0.25 if (indice // 2) % 2 == 0 else 0.45
	im = T.colar(im, *capa_penas(vento), (cara[0] - 4, cara[1] + 6), False)
	im = T.colar(im, *cornos_sombra(), (cara[0] + 1, cara[1] - 1), True)
	o = T.ancora_ombro(orig, cara)
	if o:
		im = T.colar(im, *ombreira_espigao(), o, True)
	return contorno_fiel(orig, im, lam)


def contorno_fiel(orig: Image.Image, im: Image.Image, lam) -> Image.Image:
	"""Conserva as separacoes escuras do Golden e o alfa original do corpo.
	Energia/glow ficam nos VFX separados; nenhuma expansao semitransparente.
	A lamina substituida tem o seu proprio contorno e nao e reconstruida aqui.
	"""
	po, px = orig.load(), im.load()
	arma = set(lam["pixeis"]) if lam else set()
	for y in range(orig.height):
		for x in range(orig.width):
			r, g, b, a = po[x, y]
			if a == 0 or (x, y) in arma:
				continue
			# Separacao de pernas/bracos e limite externo sem pintar volumes novos.
			borda = any(not (0 <= x + dx < orig.width and 0 <= y + dy < orig.height)
				or po[x + dx, y + dy][3] == 0 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
			nr, ng, nb, na = px[x, y]
			if na == 0:
				# Troca de arma nao pode apagar o corpo junto ao punho.
				nr, ng, nb = r, g, b
			if max(r, g, b) < 12 or (borda and max(r, g, b) < 25):
				nr, ng, nb = r, g, b
			px[x, y] = (nr, ng, nb, a)
	return im


P.VESTIR["shadowblade"] = vestir_shadowblade
