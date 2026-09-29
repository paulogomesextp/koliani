#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""TRAJES das skins da Koliani: pecas pixel-art desenhadas a mao (elmo com
cornos, capuz, aureola, asas) coladas em cada frame do Golden Set.

Usado por `tools/gerar_skins_koliani.py`. As pecas estao aqui em grelhas de
texto -- um caracter por pixel -- para se poderem rever e retocar sem editor:

  .  transparente           K  contorno
  1..6  rampa da peca (1 = mais escuro, 6 = mais claro; cores na skin)
  E  brilho (emissivo, cor `brilho` da skin)

Cada peca tem uma ANCORA: o `@` na grelha e' o pixel que cai no centro da cara
(detetada por frame em `ancora_cara`). O `@` conta como o caracter a sua
esquerda para o desenho (ou transparente, se estiver na borda).

Camadas:
  frente -- por cima da Koliani (elmo, capuz, aureola);
  tras   -- por baixo dela (asas, veu): so' aparece onde ela nao esta, e o
            cabelo continua a passar-lhe por cima.
"""

from __future__ import annotations

import colorsys
import math

from PIL import Image

# --------------------------------------------------------------------------
# Pecas. Todas viradas a DIREITA (como o Golden Set).
# --------------------------------------------------------------------------

# Elmo da Forja: dois cornos a varrer para tras, viseira aberta para a cara.
ELMO_CORNOS = [
	"..KK......................",
	".K65K.....................",
	".K654K....................",
	"..K654K...................",
	"...K543K..................",
	"...K5433K.................",
	"....K5433K.......KK.......",
	"....K54332K.....K54K......",
	".....K54332K...K543K......",
	".....KK543322KK5432K......",
	"......KK22222222222K......",
	".....K2233333333332K......",
	"....K223344444443332K.....",
	"...K2233444333333332K.....",
	"...K2333333333333332K.....",
	"..K23333333333333333KK....",
	"..K2333E333322KKKKKK2K....",
	"..K233333332K.............",
	"..K23333E32K..............",
	"..K2333332K...............",
	"...K233332K...............",
	"...K23332K................",
	"....K232K.....@...........",
	".....KK2K.................",
	".......K..................",
]

# Capuz da Abadia: bico caido para tras, aba sobre a testa, gola ao pescoco.
CAPUZ = [
	"..........KKKKK........",
	"........KK33333KK......",
	"......KK333344333K.....",
	".....K33334443333K.....",
	"....K3333444333333K....",
	"...K33334433332222K....",
	"..K333344333322KKK2K...",
	".K33334433332K....K2K..",
	".K3333333332K......K5K.",
	"K33333333322K.......K5K",
	"K3333333332K.........KK",
	"K3333333322K...........",
	"K333333332K............",
	"K33333332K.............",
	"K2333332K......@.......",
	".K233332K..............",
	".K2333332K......KK.....",
	"..K233333KKKKKKK2K.....",
	"..K2333333333332K......",
	"...K22E2222E222K.......",
	"....KKKKKKKKKKK........",
]

# Aureola: anel fino por cima da cabeca, inclinado.
AUREOLA = [
	"....KKKKKKK....",
	"..KKEEEEEEEKK..",
	".KE6KKKKKKK6EK.",
	"..KKEEEEEEEKK..",
	"....KKKKKKK....",
	"...............",
	"...............",
	"...............",
	"...............",
	"...............",
	"...............",
	"...............",
	"...............",
	"...............",
	"...............",
	"...............",
	".......@.......",
]

# Asa (a de tras, vista de lado): penas em degraus, abertas para cima e tras.
# Ancora = omoplata. Duas poses para bater na corrida/salto.
ASA_A = [
	"..................KK........",
	"...............KKK66K.......",
	"............KKK666665K......",
	"..........KK66655555K.......",
	"........KK66555544444K......",
	"......KK6655554444333K......",
	".....K665554444333322K......",
	"....K66554443333222KK.......",
	"...K6655443332222KK.........",
	"..K665544332222K............",
	"..K65544332222K.............",
	".K6554433222KK..............",
	".K655443222K................",
	"K65544322K..................",
	"K6544322K..........@........",
	"K654422K....................",
	".K5432K.....................",
	".K542K......................",
	"..K4K.......................",
	"...K........................",
]
ASA_B = [
	"............................",
	"............................",
	"............................",
	"............................",
	"..............KKKK..........",
	"...........KKK6666KK........",
	"........KKK66665555K........",
	"......KK66655554444K........",
	"....KK6655544443333K........",
	"...K66554443332222K.........",
	"..K6554433322222KK..........",
	".K655443322222K.............",
	".K65443322KKK...............",
	"K6544322K...................",
	"K654422K...........@........",
	"K65432K.....................",
	".K542K......................",
	"..K4K.......................",
	"...K........................",
	"............................",
]


def _grelha(g: list[str]) -> tuple[list[str], int, int]:
	"""Devolve (linhas, ax, ay) com o @ trocado pelo vizinho da esquerda."""
	ax = ay = -1
	fora = []
	for y, linha in enumerate(g):
		i = linha.find("@")
		if i >= 0:
			ax, ay = i, y
			viz = linha[i - 1] if i > 0 else "."
			linha = linha[:i] + (viz if viz in "123456E" else ".") + linha[i + 1:]
		fora.append(linha)
	assert ax >= 0, "peca sem @"
	return fora, ax, ay


def _hx(s: str) -> tuple[int, int, int, int]:
	s = s.lstrip("#")
	return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)


def desenhar(grelha: list[str], rampa: list[str], contorno: str, brilho: str) -> tuple[Image.Image, int, int]:
	"""Rasteriza uma peca. Devolve (imagem, ax, ay)."""
	linhas, ax, ay = _grelha(grelha)
	w = max(len(l) for l in linhas)
	im = Image.new("RGBA", (w, len(linhas)), (0, 0, 0, 0))
	px = im.load()
	for y, l in enumerate(linhas):
		for x, c in enumerate(l):
			if c == ".":
				continue
			if c == "K":
				px[x, y] = _hx(contorno)
			elif c == "E":
				px[x, y] = _hx(brilho)
			else:
				px[x, y] = _hx(rampa[int(c) - 1])
	return im, ax, ay


# --------------------------------------------------------------------------
# Ancora: centro da cara
# --------------------------------------------------------------------------

def _pele(r: int, g: int, b: int) -> bool:
	h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
	return 8 <= h * 360 <= 45 and 0.15 <= s <= 0.6 and v >= 0.55


def ancora_cara(im: Image.Image) -> tuple[int, int] | None:
	"""Centro da cara: media dos pixeis de pele nas 8 linhas abaixo do pixel
	de pele mais alto (a cara esta' sempre acima do peito e dos bracos nas
	poses em pe'; as rodadas do rolamento tratam-se a parte)."""
	px = im.load()
	pts = [(x, y) for y in range(im.height) for x in range(im.width)
		   if px[x, y][3] > 200 and _pele(*px[x, y][:3])]
	if not pts:
		return None
	ymin = min(y for _x, y in pts)
	cara = [(x, y) for x, y in pts if y <= ymin + 7]
	return (round(sum(x for x, _ in cara) / len(cara)), round(sum(y for _, y in cara) / len(cara)))


def colar(base: Image.Image, peca: Image.Image, ax: int, ay: int, alvo: tuple[int, int], frente: bool) -> Image.Image:
	"""Cola `peca` com a ancora em `alvo`. Frente: por cima; tras: por baixo."""
	camada = Image.new("RGBA", base.size, (0, 0, 0, 0))
	camada.paste(peca, (alvo[0] - ax, alvo[1] - ay))
	if frente:
		return Image.alpha_composite(base, camada)
	return Image.alpha_composite(camada, base)


# --------------------------------------------------------------------------
# Asas (procedurais): um "braco" da asa do ombro ao pulso e penas a cair dele,
# cada vez mais compridas para fora. `abertura` 0..1 levanta a asa (bater).
# --------------------------------------------------------------------------

def contornar(im: Image.Image, contorno) -> Image.Image:
	"""Contorno de 1 px por fora da silhueta da peca (4-vizinhos)."""
	W, H = im.size
	a = im.getchannel("A").load()
	out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	o = out.load()
	for y in range(H):
		for x in range(W):
			if a[x, y] == 0 and any(0 <= x + dx < W and 0 <= y + dy < H and a[x + dx, y + dy] > 0
									for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
				o[x, y] = contorno
	return Image.alpha_composite(out, im)


def _pena(d, base, ponta, largura: float, cor, contorno) -> None:
	"""Pena afunilada: quadrilatero da base (larga) a ponta (1 px), com o seu
	proprio contorno -- sobrepostas, as penas ficam separadas por uma linha."""
	bx, by = base
	tx, ty = ponta
	dx, dy = tx - bx, ty - by
	n = math.hypot(dx, dy) or 1.0
	nx, ny = -dy / n, dx / n
	h = largura / 2.0
	pts = [(bx + nx * h, by + ny * h), (tx + nx * 0.8, ty + ny * 0.8),
		   (tx - nx * 0.8, ty - ny * 0.8), (bx - nx * h, by - ny * h)]
	d.polygon(pts, fill=cor, outline=contorno)


def asa(rampa: list[str], contorno: str, abertura: float = 1.0) -> tuple[Image.Image, int, int]:
	"""Asa de tras (vista de lado), ancora no ombro. `abertura` 1 = erguida,
	0 = recolhida (a meio do bater)."""
	from PIL import ImageDraw
	W, H = 56, 56
	ox, oy = 46, 40
	im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	d = ImageDraw.Draw(im)
	c = [_hx(x) for x in rampa]
	k = _hx(contorno)
	kl = c[1]   # linha entre penas: mais suave que o contorno de fora
	lev = 0.55 + 0.45 * abertura
	# braco da asa: ombro -> cotovelo -> pulso
	cot = (ox - 9, oy - 14 * lev)
	pul = (ox - 20, oy - 26 * lev)
	# primarias: do pulso, em leque para tras e para baixo (as de fora primeiro)
	for i in range(6):
		t = i / 5.0
		ang = math.radians(192 + 48 * t - 12 * (1 - abertura))
		comp = 26 - 8 * t
		base = (pul[0] + 3 * t, pul[1] + 5 * t)
		ponta = (base[0] + comp * math.cos(ang), base[1] - comp * math.sin(ang))
		_pena(d, base, ponta, 5.0, c[2 + (i % 2)], kl)
	# secundarias: ao longo do antebraco, a cair
	for i in range(6):
		t = i / 5.0
		base = (pul[0] + (cot[0] - pul[0]) * t, pul[1] + (cot[1] - pul[1]) * t + 2)
		ang = math.radians(246 + 24 * t)
		comp = 18 - 5 * t
		ponta = (base[0] + comp * math.cos(ang), base[1] - comp * math.sin(ang))
		_pena(d, base, ponta, 5.0, c[3 + (i % 2)], kl)
	# cobertas: penas curtas por cima do braco (cotovelo -> ombro)
	for i in range(5):
		t = i / 4.0
		seg = (pul, cot) if t < 0.5 else (cot, (ox, oy))
		u = t * 2 if t < 0.5 else (t - 0.5) * 2
		base = (seg[0][0] + (seg[1][0] - seg[0][0]) * u, seg[0][1] + (seg[1][1] - seg[0][1]) * u)
		ponta = (base[0] - 5, base[1] + 8)
		_pena(d, base, ponta, 6.0, c[4], kl)
	# o proprio braco: osso claro
	d.line([(ox, oy), cot, pul], fill=c[5], width=3)
	d.line([(ox, oy), cot, pul], fill=c[4], width=1)
	return contornar(im, k), ox, oy


# --------------------------------------------------------------------------
# Cornos (procedurais): curva do topo da cabeca para tras, afunilada, com
# aneis alternados. Ancora = centro da cara.
# --------------------------------------------------------------------------

def _bezier(p0, p1, p2, n):
	return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
			 (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1])
			for t in (i / n for i in range(n + 1))]


def cornos(rampa: list[str], contorno: str, brilho: str) -> tuple[Image.Image, int, int]:
	"""Dois cornos a varrer para tras: o de perto nasce atras da orelha, o de
	longe (mais escuro, mais pequeno) espreita por cima da cabeca. Com uma
	fenda de brasa no de perto."""
	from PIL import ImageDraw
	W, H = 34, 30
	ax, ay = 24, 26
	c = [_hx(x) for x in rampa]
	k = _hx(contorno)
	def corno(p0, p1, p2, larg0, escuro, fenda):
		im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
		d = ImageDraw.Draw(im)
		pts = _bezier((ax + p0[0], ay + p0[1]), (ax + p1[0], ay + p1[1]), (ax + p2[0], ay + p2[1]), 10)
		for i in range(len(pts) - 1):
			larg = larg0 - (larg0 - 0.8) * i / (len(pts) - 1)
			base = 1 if escuro else 3
			cor = c[base + (1 if i % 3 == 0 else 0)]
			_pena(d, pts[i], pts[i + 1], larg, cor, cor)
		if fenda:
			for i in (2, 3):
				im.putpixel((round(pts[i][0]), round(pts[i][1])), _hx(brilho))
		return contornar(im, k)
	im = corno((-1, -10), (1, -17), (-8, -20), 3.2, True, False)
	im = Image.alpha_composite(im, corno((-5, -6), (-4, -19), (-17, -20), 4.2, False, True))
	return im, ax, ay


# --------------------------------------------------------------------------
# ARMAS. A lamina do Golden Set e' magenta (a Shadowblade) e so' aparece nos
# golpes: detetamo-la, apagamo-la e desenhamos a arma nova sobre a mesma reta
# (punho no lado do corpo), maior ou igual, para tapar o que se apagou.
# --------------------------------------------------------------------------

def _lamina_mag(r: int, g: int, b: int) -> bool:
	h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
	return 280 <= h * 360 <= 340 and s > 0.30 and v > 0.30


def lamina(im: Image.Image, cara: tuple[int, int]) -> dict | None:
	"""{"pixeis", "punho", "ponta", "comp"} da lamina, ou None se nao ha'."""
	px = im.load()
	pts = [(x, y) for y in range(im.height) for x in range(im.width)
		   if px[x, y][3] > 60 and _lamina_mag(*px[x, y][:3])]
	# so' o maior aglomerado (vizinhanca de 2 px): brilhos rosa soltos no
	# cabelo ou na roupa desviavam a reta
	resto = set(pts)
	grupos = []
	while resto:
		fila = [resto.pop()]
		grupo = []
		while fila:
			x, y = fila.pop()
			grupo.append((x, y))
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					q = (x + dx, y + dy)
					if q in resto:
						resto.remove(q)
						fila.append(q)
		grupos.append(grupo)
	pts = max(grupos, key=len) if grupos else []
	if len(pts) < 12:
		return None
	mx = sum(x for x, _ in pts) / len(pts)
	my = sum(y for _, y in pts) / len(pts)
	sxx = sum((x - mx) ** 2 for x, _ in pts)
	syy = sum((y - my) ** 2 for _, y in pts)
	sxy = sum((x - mx) * (y - my) for x, y in pts)
	ang = 0.5 * math.atan2(2 * sxy, sxx - syy)
	ux, uy = math.cos(ang), math.sin(ang)
	proj = [(x - mx) * ux + (y - my) * uy for x, y in pts]
	a = (mx + ux * min(proj), my + uy * min(proj))
	b = (mx + ux * max(proj), my + uy * max(proj))
	# o punho e' a ponta mais perto do corpo (um pouco abaixo da cara)
	corpo = (cara[0], cara[1] + 14)
	da = math.hypot(a[0] - corpo[0], a[1] - corpo[1])
	db = math.hypot(b[0] - corpo[0], b[1] - corpo[1])
	punho, ponta = (a, b) if da <= db else (b, a)
	return {"pixeis": pts, "punho": punho, "ponta": ponta,
			"comp": math.hypot(ponta[0] - punho[0], ponta[1] - punho[1])}


def _quad(d, p0, p1, w0: float, w1: float, cor) -> None:
	dx, dy = p1[0] - p0[0], p1[1] - p0[1]
	n = math.hypot(dx, dy) or 1.0
	nx, ny = -dy / n, dx / n
	d.polygon([(p0[0] + nx * w0 / 2, p0[1] + ny * w0 / 2), (p1[0] + nx * w1 / 2, p1[1] + ny * w1 / 2),
			   (p1[0] - nx * w1 / 2, p1[1] - ny * w1 / 2), (p0[0] - nx * w0 / 2, p0[1] - ny * w0 / 2)], fill=cor)


def _ao_longo(p0, u, t):
	return (p0[0] + u[0] * t, p0[1] + u[1] * t)


# Cada arma: funcao (draw, punho, direcao unitaria, comp_original, cores).
def _espada_brasa(d, p, u, comp, c):
	"""Montante de ferro negro com gume de brasa e guarda larga."""
	n = (-u[1], u[0])
	L = comp + 5
	_quad(d, _ao_longo(p, u, 3), _ao_longo(p, u, L), 5.0, 1.0, c["gume"])
	_quad(d, _ao_longo(p, u, 3), _ao_longo(p, u, L - 2), 3.0, 1.0, c["lamina"])
	_quad(d, _ao_longo(p, u, 4), _ao_longo(p, u, L - 6), 1.0, 1.0, c["fio"])
	g = _ao_longo(p, u, 2.5)
	_quad(d, (g[0] - n[0] * 4.5, g[1] - n[1] * 4.5), (g[0] + n[0] * 4.5, g[1] + n[1] * 4.5), 2.0, 2.0, c["guarda"])
	_quad(d, _ao_longo(p, u, -4), _ao_longo(p, u, 2), 1.6, 1.6, c["punho"])


def _lanca_mare(d, p, u, comp, c):
	"""Tridente: haste comprida (passa atras da mao) e tres dentes."""
	n = (-u[1], u[0])
	L = comp + 12
	_quad(d, _ao_longo(p, u, -8), _ao_longo(p, u, L - 6), 1.6, 1.6, c["punho"])
	cab = _ao_longo(p, u, L - 7)
	_quad(d, (cab[0] - n[0] * 4, cab[1] - n[1] * 4), (cab[0] + n[0] * 4, cab[1] + n[1] * 4), 1.8, 1.8, c["guarda"])
	for k in (-3.2, 0.0, 3.2):
		b0 = (cab[0] + n[0] * k, cab[1] + n[1] * k)
		_quad(d, b0, _ao_longo(b0, u, 7 if k == 0 else 5), 1.8, 0.8, c["lamina"])
	_quad(d, cab, _ao_longo(cab, u, 7), 0.9, 0.6, c["fio"])


def _espada_sol(d, p, u, comp, c):
	"""Espada longa branca com sulco de ouro e guarda em asa."""
	n = (-u[1], u[0])
	L = comp + 3
	_quad(d, _ao_longo(p, u, 3), _ao_longo(p, u, L), 3.4, 1.0, c["lamina"])
	_quad(d, _ao_longo(p, u, 4), _ao_longo(p, u, L - 4), 1.0, 1.0, c["fio"])
	g = _ao_longo(p, u, 2.5)
	for s in (-1, 1):
		a0 = (g[0] + n[0] * s * 1.0, g[1] + n[1] * s * 1.0)
		a1 = (g[0] + n[0] * s * 5.5 - u[0] * 2.5, g[1] + n[1] * s * 5.5 - u[1] * 2.5)
		_quad(d, a0, a1, 2.2, 1.0, c["guarda"])
	_quad(d, _ao_longo(p, u, -3), _ao_longo(p, u, 2), 1.6, 1.6, c["punho"])
	pm = _ao_longo(p, u, -4)
	d.point([pm], fill=c["gume"])


ARMAS = {"espada_brasa": _espada_brasa, "lanca_mare": _lanca_mare, "espada_sol": _espada_sol}


def trocar_arma(im: Image.Image, lam: dict | None, tipo: str, cores: dict, contorno: str) -> Image.Image:
	"""Apaga a lamina (detetada ANTES de trocar a paleta, com `lamina`) e
	desenha a arma `tipo` no mesmo sitio."""
	from PIL import ImageDraw
	if lam is None:
		return im
	im = im.copy()
	px = im.load()
	for x, y in lam["pixeis"]:
		px[x, y] = (0, 0, 0, 0)
	# e o halo rosado a volta (1 px), que ficava como fantasma
	for x, y in lam["pixeis"]:
		for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
			q = (x + dx, y + dy)
			if 0 <= q[0] < im.width and 0 <= q[1] < im.height:
				r, g, b, a = px[q]
				h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
				if a > 0 and 270 <= h * 360 <= 350 and s > 0.2:
					px[q] = (0, 0, 0, 0)
	camada = Image.new("RGBA", im.size, (0, 0, 0, 0))
	d = ImageDraw.Draw(camada)
	p, t = lam["punho"], lam["ponta"]
	u = ((t[0] - p[0]) / lam["comp"], (t[1] - p[1]) / lam["comp"])
	# a ponta nunca toca a borda do canvas (ficava cortada no jogo): encurta
	# a lamina ate' caber, com 2 px de folga + contorno
	lim = 1e9
	for c, uc, n in ((p[0], u[0], im.width), (p[1], u[1], im.height)):
		if uc > 1e-6:
			lim = min(lim, (n - 3 - c) / uc)
		elif uc < -1e-6:
			lim = min(lim, (2 - c) / uc)
	comp = min(lam["comp"], lim - 8)
	ARMAS[tipo](d, p, u, comp, {k: _hx(v) for k, v in cores.items()})
	camada = contornar(camada, _hx(contorno))
	return Image.alpha_composite(im, camada)


# --------------------------------------------------------------------------
# OMBREIRAS. Ancora = topo do ombro, achado pela pele do braco logo abaixo da
# cara (as poses mudam muito o braco; a cara sozinha nao chega).
# --------------------------------------------------------------------------

OMBREIRA_ESPIGAO = [   # Fornalha: placas de ferro com espigao e rebite de brasa
	"....KK....",
	"...K5K....",
	"..KK54K...",
	".K55554KK.",
	"K5544443K.",
	"K44E4332K.",
	".K333222K.",
	".KK22K2KK.",
	"..K1KK1K..",
	"...K..K...",
]
OMBREIRA_CONCHA = [    # Abadia: concha/escama de bronze molhado
	"..KKKKK...",
	".K65554K..",
	"K6554443K.",
	"K5E43332K.",
	".K433322K.",
	".KK3KK2KK.",
	"..K2KK2K..",
	"...KK.KK..",
]
OMBREIRA_ASA = [       # Celestial: ouro em asa, pena a subir
	"KK........",
	"K6KK......",
	".K66KKK...",
	".K655554K.",
	"K65544443K",
	"K6E443332K",
	".K4433322K",
	"..KK322KK.",
	"....KKK...",
]
ANCORA_OMBREIRA = (4, 4)


def ancora_ombro(im: Image.Image, cara: tuple[int, int]) -> tuple[int, int] | None:
	fx, fy = cara
	px = im.load()
	pts = [(x, y) for y in range(fy + 3, fy + 14) for x in range(fx - 11, fx + 7)
		   if 0 <= x < im.width and 0 <= y < im.height and px[x, y][3] > 200 and _pele(*px[x, y][:3])]
	if not pts:
		return None
	ymin = min(y for _, y in pts)
	topo = [(x, y) for x, y in pts if y <= ymin + 2]
	return (min(x for x, _ in topo) + 1, ymin + 1)


def ombreira(grelha: list[str], rampa: list[str], contorno: str, brilho: str) -> tuple[Image.Image, int, int]:
	g = [l for l in grelha]
	ax, ay = ANCORA_OMBREIRA
	g[ay] = g[ay][:ax] + "@" + g[ay][ax + 1:] if g[ay][ax] == "." else g[ay]
	if "@" not in "".join(g):
		# a ancora cai num pixel desenhado: marca-a sem o apagar
		im, _x, _y = desenhar(grelha + ["@"], rampa, contorno, brilho)
		return im.crop((0, 0, im.width, len(grelha))), ax, ay
	return desenhar(g, rampa, contorno, brilho)


# --------------------------------------------------------------------------
# Arauta do Vazio: coroa de espinhos, capa rasgada, foice.
# --------------------------------------------------------------------------

COROA_ESPINHOS = [
	"..K.....K....K.....",
	".K5K...K6K..K5K....",
	".K4K..K65K..K4K..K.",
	".K43KK4E43KK43K.K5K",
	"..K3KK3443KK33KK43K",
	"..K3333333333333K3K",
	"...K222E222222E22K.",
	"....KKKKKKKKKKKKKK.",
	"...................",
	"...................",
	"...................",
	"...................",
	"...................",
	"...................",
	"...................",
	"...........@.......",
]


def capa(rampa: list[str], contorno: str, brilho: str, vento: float = 0.0) -> tuple[Image.Image, int, int]:
	"""Capa presa aos ombros a cair para tras, com a bainha rasgada em
	dentes. Ancora = nuca. `vento` 0..1 levanta a bainha (corrida/salto)."""
	from PIL import ImageDraw
	W, H = 44, 52
	ax, ay = 34, 6
	im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	d = ImageDraw.Draw(im)
	c = [_hx(x) for x in rampa]
	queda = 40 - 14 * vento      # quanto desce
	recuo = 14 + 18 * vento      # quanto vai para tras
	topo = [(ax + 2, ay), (ax - 6, ay - 1)]
	fundo_tras = (ax - 6 - recuo, ay + queda)
	fundo_frente = (ax - 2 - recuo * 0.35, ay + queda + 4)
	corpo = [topo[0], topo[1], (ax - 10 - recuo * 0.6, ay + queda * 0.55), fundo_tras]
	# bainha em dentes, de tras para a frente
	dentes = []
	n = 6
	for i in range(n + 1):
		t = i / n
		x = fundo_tras[0] + (fundo_frente[0] - fundo_tras[0]) * t
		y = fundo_tras[1] + (fundo_frente[1] - fundo_tras[1]) * t
		dentes.append((x, y + (4 if i % 2 else -2)))
	pts = corpo + dentes + [(ax + 1, ay + queda * 0.6), (ax + 3, ay + 4)]
	d.polygon(pts, fill=c[1])
	# dobras: faixas mais claras a descer
	for k, f in enumerate((0.25, 0.5, 0.75)):
		x0 = ax - 6 * (1 - f) - 2
		d.line([(x0, ay + 2), (x0 - recuo * 0.8 * f - 4, ay + queda * 0.95)], fill=c[2 + (k % 2)], width=2)
	# forro visivel junto a gola + fecho brilhante
	d.line([(ax - 6, ay), (ax + 2, ay)], fill=c[4], width=2)
	im.putpixel((ax + 1, ay + 1), _hx(brilho))
	return contornar(im, _hx(contorno)), ax, ay


def _foice(d, p, u, comp, c):
	"""Foice de cabo comprido: a lamina curva nasce na ponta, para tras."""
	n = (-u[1], u[0])
	L = max(10.0, comp - 2)
	_quad(d, _ao_longo(p, u, -10), _ao_longo(p, u, L), 1.6, 1.6, c["punho"])
	topo = _ao_longo(p, u, L)
	# lamina: arco de ~12 px virado para o lado "n" e para tras
	pts = []
	for i in range(9):
		t = i / 8
		ang = math.pi * 0.9 * t
		r = 13
		x = topo[0] + n[0] * r * math.sin(ang) - u[0] * r * (1 - math.cos(ang)) * 0.6
		y = topo[1] + n[1] * r * math.sin(ang) - u[1] * r * (1 - math.cos(ang)) * 0.6
		pts.append((x, y))
	for i in range(len(pts) - 1):
		w = 4.2 - 3.2 * i / (len(pts) - 1)
		_quad(d, pts[i], pts[i + 1], w, max(0.8, w - 0.4), c["lamina"])
	for i in range(len(pts) - 2):
		_quad(d, pts[i], pts[i + 1], 0.9, 0.9, c["fio"])
	d.point([topo], fill=c["gume"])


ARMAS["foice"] = _foice
