#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Pecas e materiais das skins PREMIUM da Koliani (Anjo e Demonio).

Mais pormenor do que `trajes_koliani.py`: armadura com material proprio
(orla de ouro / veios de lava), olhos que brilham, duas asas com tres
camadas de penas, aureola com raios, cornos de carneiro enrolados, cauda,
capa com forro e buracos, e armas com brilho. Tudo desenhado por codigo para
alinhar com os 84 frames do Golden Set -- ver `tools/gerar_skins_koliani.py`.
"""

from __future__ import annotations

import colorsys
import math

from PIL import Image, ImageDraw

import trajes_koliani as T

_hx = T._hx


# --------------------------------------------------------------------------
# Materiais sobre o corpo
# --------------------------------------------------------------------------

def _e_pele(r, g, b):
	return T._pele(r, g, b)


def olhos(im: Image.Image, cara: tuple[int, int], cor: str, orig: Image.Image | None = None) -> Image.Image:
	"""Os olhos do Golden Set sao os pixeis quase pretos DENTRO da cara
	(rodeados de pele): pintam-se da cor dada, a brilhar."""
	im = im.copy()
	px = im.load()
	po = (orig or im).load()
	fx, fy = cara
	c = _hx(cor)
	for y in range(fy - 4, fy + 2):
		for x in range(fx - 3, fx + 5):
			if not (0 <= x < im.width and 0 <= y < im.height):
				continue
			r, g, b, a = po[x, y]
			if a < 200 or max(r, g, b) > 40:
				continue
			pele = sum(1 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
					   if po[x + dx, y + dy][3] > 200 and _e_pele(*po[x + dx, y + dy][:3]))
			if pele >= 2:
				px[x, y] = c
	return im


def _ruido(x: float, y: float, sem: int) -> float:
	"""Ruido de valor suave (0..1), deterministico."""
	def h(ix, iy):
		n = (ix * 374761393 + iy * 668265263 + sem * 982451653) & 0xFFFFFFFF
		n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
		return (n & 0xFFFF) / 65535.0
	x0, y0 = math.floor(x), math.floor(y)
	tx, ty = x - x0, y - y0
	tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
	a = h(x0, y0) + (h(x0 + 1, y0) - h(x0, y0)) * tx
	b = h(x0, y0 + 1) + (h(x0 + 1, y0 + 1) - h(x0, y0 + 1)) * tx
	return a + (b - a) * ty


def _e_tecido(r, g, b, a) -> bool:
	if a < 200 or _e_pele(r, g, b):
		return False
	h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
	return v > 0.05


def veios_lava(orig: Image.Image, im: Image.Image, cara, cores: list[str]) -> Image.Image:
	"""Rachas finas a brilhar na roupa (nao no cabelo solto nem na pele).
	As rachas vivem no espaco do CORPO (relativo a cara), por isso ficam
	coladas a ela de frame para frame em vez de deslizar."""
	im = im.copy()
	po = orig.load()
	px = im.load()
	fx, fy = cara
	c = [_hx(x) for x in cores]
	for y in range(fy + 3, im.height):
		for x in range(max(0, fx - 12), min(im.width, fx + 14)):
			if not _e_tecido(*po[x, y]):
				continue
			n = _ruido((x - fx) / 4.5, (y - fy) / 4.5, 7)
			d = abs(n - 0.5)
			if d < 0.022:
				px[x, y] = c[2]
			elif d < 0.045:
				r, g, b, a = px[x, y]
				px[x, y] = ((r + c[0][0]) // 2, (g + c[0][1]) // 2, (b + c[0][2]) // 2, a)
	return im


def orla_ouro(orig: Image.Image, im: Image.Image, cara, cor: str, cor2: str) -> Image.Image:
	"""Filigrana de ouro na armadura: a borda da roupa do tronco/pernas junto
	a pele (decotes, punhos, coxas) fica dourada, e ha' um friso a meio."""
	im = im.copy()
	po = orig.load()
	px = im.load()
	fx, fy = cara
	c, c2 = _hx(cor), _hx(cor2)
	W, H = im.size
	for y in range(fy + 3, H):
		for x in range(max(0, fx - 12), min(W, fx + 14)):
			if not _e_tecido(*po[x, y]):
				continue
			viz_pele = any(0 <= x + dx < W and 0 <= y + dy < H and po[x + dx, y + dy][3] > 200
						   and _e_pele(*po[x + dx, y + dy][:3]) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
			if viz_pele:
				px[x, y] = c
	return im


def brilho(im: Image.Image, cores: list[str], alfa: int = 90, cor_brilho: str | None = None) -> Image.Image:
	"""Aura de 1-2 px a volta dos pixeis emissivos (so' no transparente)."""
	alvo = {_hx(c)[:3] for c in cores}
	px = im.load()
	W, H = im.size
	fontes = [(x, y) for y in range(H) for x in range(W) if px[x, y][3] > 200 and px[x, y][:3] in alvo]
	if not fontes:
		return im
	cb = _hx(cor_brilho or cores[0])
	aura = Image.new("RGBA", im.size, (0, 0, 0, 0))
	pa = aura.load()
	for x, y in fontes:
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				q = (x + dx, y + dy)
				if not (0 <= q[0] < W and 0 <= q[1] < H) or px[q][3] > 0:
					continue
				d = abs(dx) + abs(dy)
				a = alfa if d <= 1 else alfa // 3
				if pa[q][3] < a:
					pa[q] = (cb[0], cb[1], cb[2], a)
	return Image.alpha_composite(aura, im)


def peitoral(orig: Image.Image, im: Image.Image, cara, rampa: list[str], orla: str, emblema: str) -> Image.Image:
	"""Couraca: a roupa do peito (so' tecido, nunca pele nem cabelo solto por
	tras) passa a placa de metal com a rampa dada, mantendo o volume do
	desenho original, com orla no topo (decote), uma costura central e um
	emblema no esterno."""
	im = im.copy()
	po = orig.load()
	px = im.load()
	fx, fy = cara
	c = [_hx(x) for x in rampa]
	co, ce = _hx(orla), _hx(emblema)
	W, H = im.size
	y0, y1 = fy + 5, fy + 15
	placa = set()
	for y in range(y0, y1):
		for x in range(fx - 5, fx + 6):
			if 0 <= x < W and _e_tecido(*po[x, y]):
				r, g, b, _a = po[x, y]
				# o lenco vermelho fica por cima (gola); so' o pano escuro vira placa
				if colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)[1] < 0.45 or max(r, g, b) < 40:
					placa.add((x, y))
	if not placa:
		return im
	for x, y in placa:
		r, g, b, _a = po[x, y]
		v = max(r, g, b) / 255.0
		i = min(len(c) - 1, max(0, int((v - 0.03) * 22)))   # o tecido do Golden Set e' ~0.05-0.30
		# luz de cima-frente na placa
		if (x - fx) + (y0 - y) * 0.6 > -1 and i + 1 < len(c):
			i += 1
		px[x, y] = c[max(1, i)]
	for x, y in placa:
		if (x, y - 1) not in placa:
			px[x, y] = co                            # orla do decote / ombro
		elif (x, y + 1) not in placa and y > y0 + 4:
			px[x, y] = c[1]                          # aba de baixo mais escura
	# costura central e emblema no esterno
	cx = fx
	for y in range(y0 + 2, y1 - 1):
		if (cx, y) in placa and (cx, y - 1) in placa:
			px[cx, y] = c[0]
	e = (cx, y0 + 4)
	if e in placa:
		px[e] = ce
		for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
			q = (e[0] + dx, e[1] + dy)
			if q in placa:
				px[q] = co
	return im


def capa_nobre(rampa: list[str], orla: str, contorno: str, vento: float) -> tuple[Image.Image, int, int]:
	"""Capa comprida e inteira (sem rasgoes), dobras largas e bainha com orla
	de ouro. Ancora = nuca."""
	W, H = 46, 56
	ax, ay = 36, 5
	im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	d = ImageDraw.Draw(im)
	c = [_hx(x) for x in rampa]
	queda = 44 - 12 * vento
	recuo = 10 + 16 * vento
	bainha = []
	n = 8
	t0 = (ax - 9 - recuo, ay + queda - 3)
	t1 = (ax - 2 - recuo * 0.3, ay + queda + 1)
	for i in range(n + 1):
		t = i / n
		bainha.append((t0[0] + (t1[0] - t0[0]) * t, t0[1] + (t1[1] - t0[1]) * t + 1.5 * math.sin(t * math.pi * 3)))
	pts = [(ax + 1, ay), (ax - 7, ay - 1), (ax - 12 - recuo * 0.55, ay + queda * 0.5)] + bainha + [(ax - 1, ay + queda * 0.55)]
	d.polygon(pts, fill=c[2])
	# dobras: vale escuro + crista clara ao lado, a abrir em leque para baixo
	for f in (0.12, 0.35, 0.58, 0.8):
		x0 = ax - 8 * (1 - f)
		xb = x0 - recuo * 0.95 * f - 4
		d.line([(x0, ay + 2), (xb, ay + queda * 0.97)], fill=c[1], width=1)
		d.line([(x0 + 1, ay + 3), (xb + 1.5, ay + queda * 0.97)], fill=c[4], width=1)
	# o lado de dentro (junto ao corpo) na sombra
	d.line([(ax - 1, ay + 2), (ax - 2 - recuo * 0.3, ay + queda)], fill=c[1], width=2)
	d.line(bainha, fill=_hx(orla), width=2)
	d.line([(ax - 8, ay), (ax + 2, ay)], fill=_hx(orla), width=2)
	return T.contornar(im, _hx(contorno)), ax, ay


# --------------------------------------------------------------------------
# DEMONIO
# --------------------------------------------------------------------------

def cornos_carneiro(rampa: list[str], contorno: str, brilho_c: str) -> tuple[Image.Image, int, int]:
	"""Dois cornos grandes que nascem na testa, sobem e varrem para tras, com
	a ponta a curvar de novo para cima -- a silhueta de demonio le-se logo,
	mesmo pequena. Aneis claros/escuros ao longo do corno e uma racha de
	brasa na base. O de longe e' mais escuro e fica atras. Ancora = cara."""
	W, H = 34, 26
	ax, ay = 20, 20
	c = [_hx(x) for x in rampa]
	k = _hx(contorno)

	def corno(p0, p1, p2, p3, larg, tom):
		im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
		d = ImageDraw.Draw(im)
		n = 18
		pts = []
		for i in range(n + 1):
			t = i / n
			x = (1 - t) ** 3 * p0[0] + 3 * (1 - t) ** 2 * t * p1[0] + 3 * (1 - t) * t * t * p2[0] + t ** 3 * p3[0]
			y = (1 - t) ** 3 * p0[1] + 3 * (1 - t) ** 2 * t * p1[1] + 3 * (1 - t) * t * t * p2[1] + t ** 3 * p3[1]
			pts.append((x, y))
		for i in range(n):
			w = larg * (1 - i / n) + 0.8
			cor = c[tom + (1 if (i // 2) % 2 == 0 else 0)]
			T._pena(d, pts[i], pts[i + 1], w, cor, cor)
		# luz no dorso (lado de cima)
		for i in range(1, n - 3):
			x, y = pts[i]
			d.point([(round(x), round(y - larg * (1 - i / n) * 0.5))], fill=c[min(5, tom + 2)])
		return T.contornar(im, k), pts

	far, _ = corno((ax + 3, ay - 8), (ax + 4, ay - 15), (ax - 2, ay - 17), (ax - 4, ay - 21), 3.0, 0)
	near, pts = corno((ax + 1, ay - 6), (ax + 1, ay - 13), (ax - 6, ay - 14), (ax - 9, ay - 18), 4.0, 2)
	im = Image.alpha_composite(far, near)
	for i in (1, 2):
		x, y = pts[i]
		im.putpixel((round(x), round(y)), _hx(brilho_c))
	return im, ax, ay


def cauda(rampa: list[str], contorno: str, brilho_c: str, fase: float) -> tuple[Image.Image, int, int]:
	"""Cauda em S que nasce do fundo das costas e acaba em ponta de lanca.
	`fase` 0..1 balanca-a."""
	W, H = 40, 36
	ax, ay = 34, 6
	im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	d = ImageDraw.Draw(im)
	c = [_hx(x) for x in rampa]
	s = math.sin(fase * 2 * math.pi)
	p0 = (ax, ay)
	p1 = (ax - 10, ay + 14 + 3 * s)
	p2 = (ax - 22, ay + 8 - 4 * s)
	p3 = (ax - 30, ay + 18 + 5 * s)
	pts = []
	for i in range(19):
		t = i / 18
		x = (1 - t) ** 3 * p0[0] + 3 * (1 - t) ** 2 * t * p1[0] + 3 * (1 - t) * t * t * p2[0] + t ** 3 * p3[0]
		y = (1 - t) ** 3 * p0[1] + 3 * (1 - t) ** 2 * t * p1[1] + 3 * (1 - t) * t * t * p2[1] + t ** 3 * p3[1]
		pts.append((x, y))
	for i in range(18):
		T._pena(d, pts[i], pts[i + 1], 3.2 - 1.8 * i / 18, c[2 if i % 3 else 1], c[2 if i % 3 else 1])
	# ponta em losango
	tx, ty = pts[-1]
	ux, uy = tx - pts[-3][0], ty - pts[-3][1]
	n = math.hypot(ux, uy) or 1
	ux, uy = ux / n, uy / n
	vx, vy = -uy, ux
	d.polygon([(tx - ux, ty - uy), (tx + vx * 3, ty + vy * 3), (tx + ux * 6, ty + uy * 6),
			   (tx - vx * 3, ty - vy * 3)], fill=c[3])
	im.putpixel((int(tx + ux * 2), int(ty + uy * 2)), _hx(brilho_c))
	return T.contornar(im, _hx(contorno)), ax, ay


def capa_rasgada(rampa: list[str], forro: str, contorno: str, vento: float) -> tuple[Image.Image, int, int]:
	"""Capa pesada: exterior escuro, forro carmim a ver-se na dobra, bainha em
	farrapos e dois buracos. Ancora = nuca."""
	W, H = 48, 56
	ax, ay = 38, 5
	im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	d = ImageDraw.Draw(im)
	c = [_hx(x) for x in rampa]
	fo = _hx(forro)
	queda = 44 - 14 * vento
	recuo = 12 + 18 * vento
	# forro (por tras do exterior, a espreitar do lado de dentro)
	d.polygon([(ax + 1, ay + 1), (ax - 4 - recuo * 0.3, ay + queda + 2), (ax - 1 - recuo * 0.2, ay + queda + 3)], fill=fo)
	# exterior com bainha em farrapos
	bainha = []
	n = 8
	t0 = (ax - 8 - recuo, ay + queda - 2)
	t1 = (ax - 3 - recuo * 0.3, ay + queda + 1)
	for i in range(n + 1):
		t = i / n
		x = t0[0] + (t1[0] - t0[0]) * t
		y = t0[1] + (t1[1] - t0[1]) * t
		bainha.append((x, y + (5 if i % 2 else -1) + (2 if i % 3 == 0 else 0)))
	pts = [(ax + 1, ay), (ax - 7, ay - 1), (ax - 12 - recuo * 0.55, ay + queda * 0.5)] + bainha + [(ax - 2, ay + queda * 0.55)]
	d.polygon(pts, fill=c[2])
	# dobras: vale escuro + crista com reflexo carmim
	for f in (0.15, 0.4, 0.65, 0.85):
		x0 = ax - 7 * (1 - f) - 1
		xb = x0 - recuo * 0.9 * f - 3
		d.line([(x0, ay + 3), (xb, ay + queda * 0.92)], fill=c[0], width=1)
		d.line([(x0 + 1, ay + 4), (xb + 1.5, ay + queda * 0.92)], fill=c[4], width=1)
	# bainha chamuscada: brasa nas pontas dos farrapos
	for x, y in bainha[1::2]:
		d.point([(x, y - 1)], fill=fo)
	# buracos (so' ve o que esta' atras)
	for hx, hy in ((ax - 9 - recuo * 0.5, ay + queda * 0.62), (ax - 5 - recuo * 0.35, ay + queda * 0.8)):
		d.ellipse([hx - 1.5, hy - 1, hx + 1.5, hy + 1.5], fill=(0, 0, 0, 0))
	# gola de pelo/ossos
	d.line([(ax - 8, ay), (ax + 2, ay)], fill=c[3], width=3)
	for i in range(4):
		im.putpixel((ax - 7 + i * 3, ay - 2), c[4])
	return T.contornar(im, _hx(contorno)), ax, ay


def lamina_demonio(d, p, u, comp, c):
	"""Espadao serrilhado: lamina larga de obsidiana com dentes no dorso, veio
	de lava a meio e guarda em chifres."""
	n = (-u[1], u[0])
	L = comp + 6
	A = T._ao_longo
	T._quad(d, A(p, u, 3), A(p, u, L), 6.0, 1.0, c["lamina"])
	# dentes no dorso
	for i in range(4, int(L) - 3, 4):
		b0 = A(p, u, i)
		b0 = (b0[0] - n[0] * 2.6, b0[1] - n[1] * 2.6)
		T._quad(d, b0, (b0[0] - n[0] * 2.2 + u[0] * 1.5, b0[1] - n[1] * 2.2 + u[1] * 1.5), 2.2, 0.6, c["lamina"])
	T._quad(d, A(p, u, 4), A(p, u, L - 3), 1.0, 1.0, c["fio"])
	# guarda: dois chifres curvos para a frente
	g = A(p, u, 2.5)
	for s in (-1, 1):
		a0 = (g[0] + n[0] * s * 1.5, g[1] + n[1] * s * 1.5)
		a1 = (g[0] + n[0] * s * 5.0 + u[0] * 2.5, g[1] + n[1] * s * 5.0 + u[1] * 2.5)
		T._quad(d, a0, a1, 2.4, 0.8, c["guarda"])
	T._quad(d, A(p, u, -4), A(p, u, 2), 1.8, 1.8, c["punho"])
	d.point([A(p, u, -5)], fill=c["gume"])
	d.point([A(p, u, 2.5)], fill=c["gume"])


# --------------------------------------------------------------------------
# ANJO
# --------------------------------------------------------------------------

def asa_anjo(rampa: list[str], contorno: str, abertura: float, esc: float = 1.0) -> tuple[Image.Image, int, int]:
	"""Asa grande de tres camadas (primarias compridas, secundarias, cobertas
	em escamas) com sombra por camada e a ponta de cada pena mais clara."""
	W, H = 70, 64
	ox, oy = 58, 46
	im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	d = ImageDraw.Draw(im)
	c = [_hx(x) for x in rampa]
	kl = c[1]
	lev = 0.55 + 0.45 * abertura
	cot = (ox - 11 * esc, oy - 17 * lev * esc)
	pul = (ox - 25 * esc, oy - 31 * lev * esc)
	# primarias (8), da mais de fora para dentro
	for i in range(8):
		t = i / 7
		ang = math.radians(118 + 62 * t + 30 * (1 - abertura))
		comp = (30 - 9 * t) * esc
		base = (pul[0] + 3 * t, pul[1] + 6 * t)
		ponta = (base[0] + comp * math.cos(ang), base[1] - comp * math.sin(ang))
		T._pena(d, base, ponta, 5.5, c[2 + (i % 2)], kl)
		# ponta clara
		mx = (base[0] * 0.25 + ponta[0] * 0.75, base[1] * 0.25 + ponta[1] * 0.75)
		T._pena(d, mx, ponta, 2.5, c[5], c[5])
	# secundarias (7)
	for i in range(7):
		t = i / 6
		base = (pul[0] + (cot[0] - pul[0]) * t, pul[1] + (cot[1] - pul[1]) * t + 2)
		ang = math.radians(210 + 40 * t)
		comp = (20 - 6 * t) * esc
		ponta = (base[0] + comp * math.cos(ang), base[1] - comp * math.sin(ang))
		T._pena(d, base, ponta, 5.5, c[3 + (i % 2)], kl)
	# cobertas em duas filas de escamas
	for fila, (desl, comp) in enumerate(((2, 7), (5, 5))):
		for i in range(7):
			t = i / 6
			seg = (pul, cot) if t < 0.5 else (cot, (ox, oy))
			u = t * 2 if t < 0.5 else (t - 0.5) * 2
			base = (seg[0][0] + (seg[1][0] - seg[0][0]) * u, seg[0][1] + (seg[1][1] - seg[0][1]) * u + desl)
			ponta = (base[0] - 4, base[1] + comp)
			T._pena(d, base, ponta, 6.0, c[4 if fila == 0 else 5], kl)
	d.line([(ox, oy), cot, pul], fill=c[5], width=3)
	d.line([(ox, oy), cot, pul], fill=c[4], width=1)
	# joia de ouro no pulso
	d.point([pul], fill=_hx("FFE680"))
	return T.contornar(im, _hx(contorno)), ox, oy


def aureola_raios(ouro: list[str], contorno: str) -> tuple[Image.Image, int, int]:
	"""Aureola em anel com 8 raios curtos e brilho -- ancora = cara."""
	W, H = 23, 26
	ax, ay = 11, 18
	im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	d = ImageDraw.Draw(im)
	c = [_hx(x) for x in ouro]
	cx, cy = 11, 5
	for k in range(8):
		a = k * math.pi / 4 + math.pi / 8
		r0, r1 = 6.5, 9.5 if k % 2 == 0 else 8.2
		d.line([(cx + math.cos(a) * r0, cy + math.sin(a) * r0 * 0.45),
				(cx + math.cos(a) * r1, cy + math.sin(a) * r1 * 0.45)], fill=c[1], width=1)
	d.ellipse([cx - 6, cy - 2.5, cx + 6, cy + 2.5], outline=c[3], width=2)
	d.ellipse([cx - 5, cy - 1.5, cx + 5, cy + 1.5], outline=c[4], width=1)
	im = T.contornar(im, _hx(contorno))
	return im, ax, ay


def diadema_alado(ouro: list[str], contorno: str, gema: str) -> tuple[Image.Image, int, int]:
	"""Diadema de ouro na testa com uma asinha para tras sobre a orelha."""
	g = [
		"K.............",
		"4K............",
		"54K...........",
		"554K..........",
		"K554KK........",
		".K5544KK......",
		"..K4443KKKKK..",
		"...KK33333GK..",
		".....KKKKKKK..",
		"..............",
		"..............",
		"..............",
		"..............",
		"........@.....",
	]
	im, ax, ay = T.desenhar([l.replace("G", "E") for l in g], ouro, contorno, gema)
	return im, ax, ay


def tassets_penas(rampa: list[str], contorno: str, ouro: str) -> tuple[Image.Image, int, int]:
	"""Saiote de penas de ouro e branco que cai da cintura (frente)."""
	W, H = 22, 18
	ax, ay = 11, 2
	im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	d = ImageDraw.Draw(im)
	c = [_hx(x) for x in rampa]
	for i, (dx, comp) in enumerate(((-8, 11), (-5, 14), (-2, 15), (1, 14), (4, 12), (7, 9))):
		base = (ax + dx, ay + 1)
		ponta = (ax + dx - 1.5, ay + comp)
		T._pena(d, base, ponta, 3.6, c[3 + (i % 2)], c[1])
	d.line([(ax - 9, ay), (ax + 8, ay)], fill=_hx(ouro), width=2)
	return T.contornar(im, _hx(contorno)), ax, ay


def espada_anjo(d, p, u, comp, c):
	"""Espada sagrada: lamina larga branca com sulco de luz, guarda em asas
	abertas e pomo com gema."""
	n = (-u[1], u[0])
	L = comp + 6
	A = T._ao_longo
	T._quad(d, A(p, u, 3), A(p, u, L), 4.6, 1.0, c["lamina"])
	T._quad(d, A(p, u, 4), A(p, u, L - 4), 1.2, 1.0, c["fio"])
	g = A(p, u, 2.5)
	for s in (-1, 1):
		for k, (r, back) in enumerate(((6.5, 2.5), (5.0, 1.0))):
			a0 = (g[0] + n[0] * s * 1.2, g[1] + n[1] * s * 1.2)
			a1 = (g[0] + n[0] * s * r - u[0] * back, g[1] + n[1] * s * r - u[1] * back)
			T._quad(d, a0, a1, 2.2 - k * 0.6, 0.9, c["guarda"])
	T._quad(d, A(p, u, -4), A(p, u, 2), 1.7, 1.7, c["punho"])
	d.point([A(p, u, -5)], fill=c["gume"])


T.ARMAS["lamina_demonio"] = lamina_demonio
T.ARMAS["espada_anjo"] = espada_anjo


# --------------------------------------------------------------------------
# Os dois conjuntos. Cada um recebe o frame ORIGINAL (para as ancoras e a
# lamina, que se detetam antes da paleta) e o ja' recolorido.
# --------------------------------------------------------------------------

K = "0A0808"
ASA_PERTO = ["2C2A3E", "6E6C88", "A8A6C0", "D4D2E4", "EEEDF6", "FFFFFF"]
ASA_LONGE = ["1E1C2C", "4A4862", "7C7A96", "A4A2BC", "C4C2D8", "DCDAEC"]
OURO = ["6A4A12", "A87420", "D8A030", "F4BE36", "FFE680", "FFFBE0"]
OBSIDIANA = ["08060A", "1A1216", "2E2228", "4A3A40", "6E5A60", "A08A8A"]
ACO_NEGRO = ["0A0608", "2A1E24", "4A3A44", "6A5864", "8E7A88", "C0A8B0"]
PRATA = ["2A2838", "5C5A70", "9A98B0", "C8C6D8", "E8E6F2", "FFFFFF"]
OSSO = ["1A1412", "3A2E28", "6A5A4C", "9A8870", "C8B89A", "EDE2C8"]


def _anca(orig: Image.Image, cara) -> tuple[int, int]:
	"""Fundo das costas: um pouco atras da cara, a ~42% da cara aos pes."""
	bb = orig.getbbox()
	return (cara[0] - 3, int(cara[1] + (bb[3] - cara[1]) * 0.42))


def vestir_anjo(orig: Image.Image, im: Image.Image, cara, lam, indice: int) -> Image.Image:
	im = orla_ouro(orig, im, cara, "F4BE36", "C8861A")
	im = peitoral(orig, im, cara, PRATA, "F4BE36", "7FD8FF")
	im = olhos(im, cara, "7FD8FF", orig)
	im = T.trocar_arma(im, lam, "espada_anjo", {"lamina": "F6F6FC", "gume": "7FD8FF", "fio": "FFE680",
												 "guarda": "F4BE36", "punho": "6A4A12"}, K)
	# as asas batem: abrem e fecham de dois em dois frames
	ab = 1.0 if (indice // 2) % 2 == 0 else 0.5
	vento = 0.2 if (indice // 2) % 2 == 0 else 0.4
	im = T.colar(im, *capa_nobre(ASA_PERTO, "F4BE36", K, vento), (cara[0] - 4, cara[1] + 6), False)
	im = T.colar(im, *asa_anjo(ASA_LONGE, K, ab, 0.55), (cara[0] - 2, cara[1] + 7), False)
	im = T.colar(im, *asa_anjo(ASA_PERTO, K, ab * 0.9, 0.62), (cara[0] - 7, cara[1] + 10), False)
	o = T.ancora_ombro(orig, cara)
	if o:
		im = T.colar(im, *T.ombreira(T.OMBREIRA_ASA, OURO, K, "FFFFFF"), o, True)
	im = T.colar(im, *aureola_raios(OURO, K), cara, True)
	return brilho(im, ["7FD8FF", "FFE680", "FFFBE0"], 70, "FFF4C0")


def vestir_demonio(orig: Image.Image, im: Image.Image, cara, lam, indice: int) -> Image.Image:
	im = veios_lava(orig, im, cara, ["FF5A1A", "E8401A", "FFB040"])
	im = peitoral(orig, im, cara, ACO_NEGRO, "C8401A", "FFB040")
	im = olhos(im, cara, "FFD040", orig)
	im = T.trocar_arma(im, lam, "lamina_demonio", {"lamina": "1E1418", "gume": "FFB040", "fio": "FF5A1A",
													"guarda": "3A2E28", "punho": "2A1A14"}, K)
	vento = 0.25 if (indice // 2) % 2 == 0 else 0.45
	im = T.colar(im, *capa_rasgada(OBSIDIANA, "7A1010", K, vento), (cara[0] - 4, cara[1] + 6), False)
	h = _anca(orig, cara)
	im = T.colar(im, *cauda(OBSIDIANA, K, "FF5A1A", (indice % 4) / 4), (h[0] - 3, h[1]), False)
	im = T.colar(im, *cornos_carneiro(OSSO, K, "FF5A1A"), cara, True)
	return brilho(im, ["FF5A1A", "FFB040", "FFD040"], 80, "FF5A1A")


VESTIR = {"anjo": vestir_anjo, "demonio": vestir_demonio}


def pecas_soltas() -> dict[str, Image.Image]:
	"""As pecas x1, para rever e para futuros icones."""
	from PIL import ImageDraw
	out = {
		"anjo_asa": asa_anjo(ASA_PERTO, K, 1.0, 0.62)[0],
		"anjo_aureola": aureola_raios(OURO, K)[0],
		"demonio_cornos": cornos_carneiro(OSSO, K, "FF5A1A")[0],
		"demonio_capa": capa_rasgada(OBSIDIANA, "7A1010", K, 0.25)[0],
		"demonio_cauda": cauda(OBSIDIANA, K, "FF5A1A", 0.0)[0],
		"anjo_capa": capa_nobre(ASA_PERTO, "F4BE36", K, 0.2)[0],
	}
	for nome, tipo, cores in (
			("anjo_espada", "espada_anjo", {"lamina": "F6F6FC", "gume": "7FD8FF", "fio": "FFE680", "guarda": "F4BE36", "punho": "6A4A12"}),
			("demonio_espadao", "lamina_demonio", {"lamina": "1E1418", "gume": "FFB040", "fio": "FF5A1A", "guarda": "3A2E28", "punho": "2A1A14"})):
		tela = Image.new("RGBA", (44, 18), (0, 0, 0, 0))
		T.ARMAS[tipo](ImageDraw.Draw(tela), (7.0, 9.0), (1.0, 0.0), 26, {k: _hx(v) for k, v in cores.items()})
		out[nome] = T.contornar(tela, _hx(K))
	return out
