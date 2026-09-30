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
PRATA = ["3E3652", "6A5E86", "9C90BA", "C8BEDC", "E8E2F2", "FFFFFF"]
# roupa/couraca: preto arroxeado
NOITE = ["07040C", "140A22", "241238", "381C56", "50307A", "7A50B0"]
# capa/cornos
SOMBRA = ["07040C", "12081E", "1E1032", "2E1A4C", "44286E", "6A44A0"]
ROXO_NEON = "B040FF"
LILAS = "E0A0FF"
OURO_FOSCO = ["4A3410", "7A5A1C", "A88428", "C8A040", "E8CC70", "FFF0B0"]

ACENTO_ROXO = [(0.00, "0C0418"), (0.22, "2E0E5C"), (0.42, "6A1CC0"),
			   (0.62, "A040FF"), (0.85, "D890FF"), (1.00, "F6E0FF")]
TECIDO_NOITE = [(0.00, "05030A"), (0.12, "0E0818"), (0.24, "1A0F2C"),
				(0.40, "2C1A48"), (0.70, "4C3078")]

SKIN = {
	"acento": ACENTO_ROXO, "tecido": TECIDO_NOITE, "forca_tecido": 0.9,
	"gema": "C060FF", "premium": "shadowblade",
}


# --------------------------------------------------------------------------
# Cabelo prata. No Golden Set cabelo e roupa tem a mesma cor (preto), por isso
# o cabelo apanha-se por GEOMETRIA relativa a cara: a cabeca e a cascata que
# cai por tras (os fios vermelhos do Golden Set entram por aqui tambem).
# --------------------------------------------------------------------------

def _rampa(c: list[str], t: float):
	t = max(0.0, min(1.0, t)) * (len(c) - 1)
	i = min(int(t), len(c) - 2)
	a, b = _hx(c[i]), _hx(c[i + 1])
	f = t - i
	return tuple(int(a[k] + (b[k] - a[k]) * f) for k in range(3))


def cabelo_prata(orig: Image.Image, im: Image.Image, cara) -> Image.Image:
	im = im.copy()
	po, px = orig.load(), im.load()
	fx, fy = cara
	W, H = im.size
	for y in range(max(0, fy - 16), min(H, fy + 30)):
		for x in range(max(0, fx - 52), min(W, fx + 16)):
			r, g, b, a = po[x, y]
			if a < 40 or T._pele(r, g, b):
				continue
			h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
			dx, dy = x - fx, y - fy
			cabeca = -9 <= dx <= 8 and -14 <= dy <= 4
			vermelho = s > 0.35 and (h * 360 >= 320 or h * 360 <= 8)
			cascata = dx < -3 and -6 <= dy <= 26 and (vermelho or (dy <= 12 and v < 0.2))
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
			t = 0.18 + min(1.0, v / 0.62) * 0.82
			if s > 0.5 and v > 0.3:
				t = min(1.0, t + 0.15)
			cr, cg, cb = _rampa(PRATA, t)
			px[x, y] = (cr, cg, cb, a)
	return im


# --------------------------------------------------------------------------
# Pecas
# --------------------------------------------------------------------------

def cornos_sombra() -> tuple[Image.Image, int, int]:
	"""Dois cornos negros curtos com veio de energia (mais discretos que os do
	Arquidemonio: a silhueta continua a ler-se como a da Koliani)."""
	im, ax, ay = P.cornos_carneiro(SOMBRA, K, LILAS)
	# escala 0.75 no sitio, preservando a ancora
	w, h = im.size
	im = im.resize((max(1, int(w * 0.78)), max(1, int(h * 0.78))), Image.NEAREST)
	return im, int(ax * 0.78), int(ay * 0.78)


def capa_penas(vento: float) -> tuple[Image.Image, int, int]:
	"""Capa/saia de penas rasgadas (referencia: 'shadow cloak / feathers'),
	exterior noite, forro roxo neon a espreitar."""
	im, ax, ay = P.capa_rasgada(SOMBRA, "5A1CA8", K, vento)
	w, h = im.size
	return im.resize((int(w * 0.8), int(h * 0.72)), Image.NEAREST), int(ax * 0.8), int(ay * 0.72)


def ombreira_espigao() -> tuple[Image.Image, int, int]:
	return T.ombreira(T.OMBREIRA_ESPIGAO, SOMBRA, K, ROXO_NEON)


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
		w = 5.2 * (1 - i / N) + 0.9
		T._quad(d, pts[i], pts[i + 1], w, 5.2 * (1 - (i + 1) / N) + 0.9, c["lamina"])
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


def vestir_shadowblade(orig: Image.Image, im: Image.Image, cara, lam, indice: int) -> Image.Image:
	im = cabelo_prata(orig, im, cara)
	im = P.veios_lava(orig, im, cara, ["7A22D8", "A040FF", "E0A0FF"])
	im = P.orla_ouro(orig, im, cara, "7A5A1C", "4A3410")
	im = P.peitoral(orig, im, cara, NOITE, "C8A040", ROXO_NEON)
	im = P.olhos(im, cara, "E070FF", orig)
	im = T.trocar_arma(im, lam, "lamina_sombra", ARMA_CORES, K)
	vento = 0.25 if (indice // 2) % 2 == 0 else 0.45
	im = T.colar(im, *capa_penas(vento), (cara[0] - 4, cara[1] + 6), False)
	im = T.colar(im, *cornos_sombra(), (cara[0] + 1, cara[1] - 1), True)
	o = T.ancora_ombro(orig, cara)
	if o:
		im = T.colar(im, *ombreira_espigao(), o, True)
	return P.brilho(im, ["A040FF", "E0A0FF", "F0D0FF"], 70, "A040FF")


P.VESTIR["shadowblade"] = vestir_shadowblade
