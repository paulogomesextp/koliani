#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Gera as SKINS da Koliani (Loja > Skins) a partir do Golden Set.

Uma skin e' o Golden Set INTEIRO (`assets/sprites/koliani_golden_set/frames/`,
todas as animacoes) com a paleta trocada -- mesma silhueta, mesmos frames,
mesmo contrato de canvas (128x128, pes em y=104). Por isso nao ha' nada a
afinar no codigo por skin: o `koliani.gd` so' troca a pasta de onde le os
frames (`CosmeticosVisuais.dir_skin`).

A arte do Golden Set nao e' indexada (~1200 cores por frame), por isso a troca
e' por MATERIAL, classificado em HSV com pesos suaves (sem serrilha nas
fronteiras):

  acento  -- os vermelhos (lenco, pontas do cabelo, fivelas): hue >= 295 ou < 10
  pele    -- hue 10..45, claro: NUNCA se mexe (a Koliani continua a ser ela)
  gema    -- o cristal ciano do cinto: hue 140..210
  tecido  -- o resto (roupa, cabelo, botas; quase sem saturacao)

Cada material passa por uma RAMPA de cores da skin indexada pelo brilho do
pixel original -- como uma rampa de pixel-art -- e o contorno (muito escuro)
fica intacto para a silhueta ler igual em qualquer cenario.

  python tools/gerar_skins_koliani.py            # grava as 3 skins
  python tools/gerar_skins_koliani.py --preview  # + folha de previews em work/

Saida por skin: `assets/sprites/koliani_skins/<pasta>/frames/<anim>/<png>`
(espelho do Golden Set) + `preview.png` (o cartao da Loja).
Depois: `godot --headless --import` para gerar os `.import`.
"""

from __future__ import annotations

import colorsys
import os
import sys

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GOLDEN = os.path.join(RAIZ, "assets", "sprites", "koliani_golden_set", "frames")
DEST = os.path.join(RAIZ, "assets", "sprites", "koliani_skins")
# o `run_native` so' existe quando a arte nativa chegar; se chegar, entra aqui
# sozinho (espelha-se tudo o que houver em frames/).


def _hx(s: str) -> tuple[float, float, float]:
	s = s.lstrip("#")
	return tuple(int(s[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


# Rampas: (brilho do pixel original 0..1, cor). O brilho do Golden Set e' baixo
# (roupa ~0.10-0.30, acentos ~0.25-0.70), por isso as paragens concentram-se ai.
SKINS: dict[str, dict] = {
	# Regiao IV -- Fornalha. Brasa viva sobre carvao: o lenco e as pontas do
	# cabelo ficam metal fundido, a roupa passa a ferro queimado.
	"fornalha": {
		"acento": [(0.00, "1A0804"), (0.22, "5C1606"), (0.42, "B8380A"),
				   (0.62, "F07818"), (0.85, "FFC048"), (1.00, "FFF0B0")],
		"tecido": [(0.00, "0E0908"), (0.12, "1E1512"), (0.24, "33231C"),
				   (0.40, "54392A"), (0.70, "8A6A50")],
		"forca_tecido": 0.85,
		"gema": "FFD040",
	},
	# Regiao IX -- Abadia Afogada. Agua funda: acentos verde-agua a brilhar,
	# roupa azul-ardosia como pano encharcado.
	"abadia_afogada": {
		"acento": [(0.00, "03141A"), (0.22, "0A3A44"), (0.42, "15777A"),
				   (0.62, "35B8A8"), (0.85, "8CEBD6"), (1.00, "E0FFF6")],
		"tecido": [(0.00, "070B12"), (0.12, "111A28"), (0.24, "1C2A40"),
				   (0.40, "2E4462"), (0.70, "5A7898")],
		"forca_tecido": 0.9,
		"gema": "F2F6FF",
	},
	# Regiao XIV -- Planicies Celestiais. A inversa das outras: roupa marfim e
	# prata, acentos ouro. O contorno fica escuro para ela nao se perder no ceu.
	"celestial": {
		"acento": [(0.00, "2A1404"), (0.22, "74420A"), (0.42, "C8861A"),
				   (0.62, "F4BE36"), (0.85, "FFE680"), (1.00, "FFFBE0")],
		"tecido": [(0.00, "16141C"), (0.07, "2C2A36"), (0.12, "6E6A7C"),
				   (0.20, "A8A4B8"), (0.30, "D2CEDD"), (0.50, "F0EEF6")],
		"forca_tecido": 1.0,
		"gema": "7FD8FF",
	},
}

# Brilho abaixo do qual o pixel e' contorno e nao muda (a silhueta).
CONTORNO_V = 0.07


def _rampa(paragens: list, v: float) -> tuple[float, float, float]:
	pts = [(p, _hx(c)) for p, c in paragens]
	if v <= pts[0][0]:
		return pts[0][1]
	for (p0, c0), (p1, c1) in zip(pts, pts[1:]):
		if v <= p1:
			t = (v - p0) / (p1 - p0) if p1 > p0 else 0.0
			return tuple(c0[i] + (c1[i] - c0[i]) * t for i in range(3))
	return pts[-1][1]


def _suave(a: float, b: float, x: float) -> float:
	"""smoothstep de a para b (a > b inverte)."""
	if a == b:
		return 1.0 if x >= a else 0.0
	t = max(0.0, min(1.0, (x - a) / (b - a)))
	return t * t * (3.0 - 2.0 * t)


def _pesos(h: float, s: float, v: float) -> tuple[float, float, float]:
	"""(acento, pele, gema) em 0..1; o tecido e' o que sobra."""
	hd = h * 360.0
	sat = _suave(0.16, 0.34, s)
	# acento: vermelho/magenta. Distancia ao centro 342 graus, a dar a volta.
	d = min(abs(hd - 342.0), 360.0 - abs(hd - 342.0))
	acento = sat * _suave(34.0, 24.0, d)
	# pele: laranja claro (inclui os realces 255,212,176)
	pele = _suave(0.10, 0.16, s) * _suave(0.36, 0.48, v) \
		* _suave(7.0, 12.0, hd) * _suave(50.0, 42.0, hd)
	# couro/pele na sombra (10..20 graus, escuro): tambem nao se mexe
	sombra = _suave(0.30, 0.45, s) * _suave(7.0, 12.0, hd) * _suave(26.0, 20.0, hd)
	pele = max(pele, sombra)
	gema = sat * _suave(130.0, 145.0, hd) * _suave(220.0, 205.0, hd)
	return acento, pele, gema


def recolorir(img: Image.Image, skin: dict) -> Image.Image:
	img = img.convert("RGBA")
	px = img.load()
	w, h = img.size
	gema = _hx(skin["gema"])
	forca = float(skin["forca_tecido"])
	cache: dict = {}
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a == 0:
				continue
			chave = (r, g, b)
			if chave not in cache:
				cache[chave] = _pixel(r, g, b, skin, gema, forca)
			nr, ng, nb = cache[chave]
			px[x, y] = (nr, ng, nb, a)
	return img


def _pixel(r: int, g: int, b: int, skin: dict, gema, forca: float) -> tuple[int, int, int]:
	rf, gf, bf = r / 255.0, g / 255.0, b / 255.0
	h, s, v = colorsys.rgb_to_hsv(rf, gf, bf)
	orig = (rf, gf, bf)
	if v < CONTORNO_V:
		return r, g, b
	w_ac, w_pe, w_ge = _pesos(h, s, v)
	w_ac *= 1.0 - w_pe
	w_ge *= 1.0 - w_pe
	w_te = max(0.0, 1.0 - w_ac - w_pe - w_ge) * forca
	# brilho de referencia: o V original (mantem o volume desenhado)
	ac = _rampa(skin["acento"], v)
	te = _rampa(skin["tecido"], v)
	ge = tuple(min(1.0, c * (0.45 + 0.75 * v)) for c in gema)
	out = []
	for i in range(3):
		c = orig[i] * (1.0 - w_ac - w_te - w_ge) + ac[i] * w_ac + te[i] * w_te + ge[i] * w_ge
		out.append(int(round(max(0.0, min(1.0, c)) * 255)))
	# contorno suave: entre CONTORNO_V e o dobro, volta aos poucos ao original
	k = _suave(CONTORNO_V, CONTORNO_V * 2.0, v)
	return tuple(int(round(r0 + (o - r0) * k)) for r0, o in zip((r, g, b), out))


def _pngs(raiz: str):
	for d, _sub, fs in os.walk(raiz):
		for f in sorted(fs):
			if f.lower().endswith(".png"):
				yield os.path.join(d, f)


def preview_loja(skin_dir: str) -> Image.Image:
	"""Cartao da Loja: o idle_001 recortado a caixa da figura, com folga."""
	im = Image.open(os.path.join(skin_dir, "frames", "idle", "idle_001.png")).convert("RGBA")
	x0, y0, x1, y1 = im.getbbox()
	lado = max(x1 - x0, y1 - y0) + 8
	cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
	return im.crop((cx - lado // 2, cy - lado // 2, cx - lado // 2 + lado, cy - lado // 2 + lado))


def gerar() -> None:
	for nome, skin in SKINS.items():
		base = os.path.join(DEST, nome)
		n = 0
		for f in _pngs(GOLDEN):
			rel = os.path.relpath(f, GOLDEN)
			dst = os.path.join(base, "frames", rel)
			os.makedirs(os.path.dirname(dst), exist_ok=True)
			recolorir(Image.open(f), skin).save(dst, optimize=True)
			n += 1
		preview_loja(base).save(os.path.join(base, "preview.png"), optimize=True)
		print(f"skin {nome}: {n} frames")


def folha_previews(saida: str) -> None:
	"""Base + cada skin em idle/run/ataque/salto, x4, lado a lado."""
	poses = ["idle/idle_001.png", "run_final/run_004.png", "attack_basic/attack_basic_004.png",
			 "jump_loop/jump_loop_002.png", "dash/dash_002.png"]
	fontes = [("base", GOLDEN)] + [(n, os.path.join(DEST, n, "frames")) for n in SKINS]
	cel, esc = 96, 3
	folha = Image.new("RGBA", (len(poses) * cel * esc, len(fontes) * cel * esc), (26, 18, 30, 255))
	for j, (_n, d) in enumerate(fontes):
		for i, p in enumerate(poses):
			im = Image.open(os.path.join(d, p)).convert("RGBA").crop((16, 16, 112, 112))
			im = im.resize((cel * esc, cel * esc), Image.NEAREST)
			folha.alpha_composite(im, (i * cel * esc, j * cel * esc))
	os.makedirs(os.path.dirname(saida), exist_ok=True)
	folha.save(saida)
	print("preview:", saida)


if __name__ == "__main__":
	gerar()
	if "--preview" in sys.argv:
		folha_previews(os.path.join(RAIZ, "work", "skins_koliani", "folha_skins.png"))
