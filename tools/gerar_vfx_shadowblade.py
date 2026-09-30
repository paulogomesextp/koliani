#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""VFX da skin Shadowblade, camadas SEPARADAS do corpo (nunca dentro do frame).

  - vfx_slash_basic: os 6 frames do arco do Golden Set repintados a roxo
    (mesma geometria e alfa -> mesma duracao/cadencia; so' muda a cor).
  - double_jump_ring, land_impact, pogo_impact, particulas: procedurais
    (v1, sem arte final no handoff -- as folhas do pacote sao so' referencia).
Saida: assets/sprites/koliani_skins/shadowblade/vfx/<slot>/<slot>_NNN.png
"""
from __future__ import annotations

import math
import os
import random

from PIL import Image, ImageDraw

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GOLD = os.path.join(RAIZ, "assets", "sprites", "koliani_golden_set", "vfx", "vfx_slash_basic")
OUT = os.path.join(RAIZ, "assets", "sprites", "koliani_skins", "shadowblade", "vfx")
RAMPA = [(0.0, (30, 6, 70)), (0.35, (110, 30, 200)), (0.65, (176, 64, 255)), (0.85, (224, 160, 255)), (1.0, (255, 245, 255))]


def _cor(t: float):
	for (p0, c0), (p1, c1) in zip(RAMPA, RAMPA[1:]):
		if t <= p1:
			f = (t - p0) / (p1 - p0)
			return tuple(int(c0[i] + (c1[i] - c0[i]) * f) for i in range(3))
	return RAMPA[-1][1]


def _grava(slot: str, frames: list[Image.Image]) -> None:
	d = os.path.join(OUT, slot)
	os.makedirs(d, exist_ok=True)
	for i, im in enumerate(frames):
		im.save(os.path.join(d, f"{slot}_{i + 1:03d}.png"), optimize=True)


def slash() -> None:
	fr = []
	for i in range(6):
		im = Image.open(os.path.join(GOLD, f"vfx_slash_basic_{i + 1:03d}.png")).convert("RGBA")
		px = im.load()
		for y in range(im.height):
			for x in range(im.width):
				r, g, b, a = px[x, y]
				if a:
					v = max(r, g, b) / 255.0 * 0.6 + (min(r, g, b) / 255.0) * 0.8
					px[x, y] = _cor(min(1.0, v * 1.1)) + (a,)
		fr.append(im)
	_grava("vfx_slash_basic", fr)


def anel() -> None:
	"""Anel de sombra a abrir (visto de lado, achatado), 64x32."""
	fr = []
	for i in range(6):
		t = i / 5
		im = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
		d = ImageDraw.Draw(im)
		rx, ry = 8 + 22 * t, 3 + 9 * t
		a = int(255 * (1 - t) ** 0.8)
		for k, (dw, col) in enumerate(((3, (110, 30, 200)), (2, (176, 64, 255)), (1, (240, 200, 255)))):
			d.ellipse([32 - rx - (2 - k), 16 - ry - (2 - k) * 0.5, 32 + rx + (2 - k), 16 + ry + (2 - k) * 0.5],
					  outline=col + (a,), width=dw)
		fr.append(im)
	_grava("double_jump_ring", fr)


def _espinhos(im, cx, base, n, altura, larg, cor_a, cor_b, rnd):
	d = ImageDraw.Draw(im)
	for k in range(n):
		x = cx + (k - (n - 1) / 2) * larg * 1.3 + rnd.uniform(-2, 2)
		h = altura * rnd.uniform(0.55, 1.0) * (1 - abs(k - (n - 1) / 2) / n * 0.9)
		d.polygon([(x - larg / 2, base), (x + rnd.uniform(-2, 2), base - h), (x + larg / 2, base)], fill=cor_a)
		d.line([(x, base), (x, base - h * 0.85)], fill=cor_b, width=1)


def impacto_chao() -> None:
	"""Explosao de espinhos de sombra a partir do chao, 96x48 (pes ao centro-baixo)."""
	rnd = random.Random(7)
	fr = []
	for i in range(6):
		t = i / 5
		im = Image.new("RGBA", (96, 48), (0, 0, 0, 0))
		alt = 26 * math.sin(min(1.0, t * 1.6) * math.pi * 0.5) * (1 - max(0.0, t - 0.55) * 1.4)
		_espinhos(im, 48, 44, 7, max(3, alt), 6, (110, 30, 200, 235), (240, 190, 255, 255), rnd)
		# onda rasa no chao
		d = ImageDraw.Draw(im)
		w = 10 + 36 * t
		d.line([(48 - w, 45), (48 + w, 45)], fill=(176, 64, 255, int(255 * (1 - t))), width=2)
		fr.append(im)
	_grava("land_impact", fr)


def impacto_pogo() -> None:
	"""Cruz de faiscas/espinhos a partir do ponto de acerto, 64x64."""
	rnd = random.Random(11)
	fr = []
	for i in range(6):
		t = i / 5
		im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
		d = ImageDraw.Draw(im)
		a = int(255 * (1 - t) ** 0.7)
		r0, r1 = 4 + 10 * t, 8 + 22 * t
		for k in range(8):
			ang = k * math.pi / 4 + 0.2
			L = r1 * (1.0 if k % 2 == 0 else 0.6)
			p0 = (32 + math.cos(ang) * r0, 32 + math.sin(ang) * r0)
			p1 = (32 + math.cos(ang) * L, 32 + math.sin(ang) * L)
			d.line([p0, p1], fill=(176, 64, 255, a), width=3 if k % 2 == 0 else 2)
			d.line([p0, p1], fill=(240, 200, 255, a), width=1)
		if t < 0.5:
			d.ellipse([32 - 6 * (1 - t), 32 - 6 * (1 - t), 32 + 6 * (1 - t), 32 + 6 * (1 - t)], fill=(255, 240, 255, 255))
		fr.append(im)
	_grava("pogo_impact", fr)


def particulas() -> None:
	"""Motes/faiscas de sombra reutilizaveis, 12x12 (4 tamanhos a esvair)."""
	fr = []
	for i in range(4):
		im = Image.new("RGBA", (12, 12), (0, 0, 0, 0))
		d = ImageDraw.Draw(im)
		r = 4 - i
		a = 255 - i * 40
		d.ellipse([6 - r, 6 - r, 6 + r, 6 + r], fill=(110, 30, 200, a))
		d.ellipse([6 - r + 1, 6 - r + 1, 6 + r - 1, 6 + r - 1], fill=(176, 64, 255, a))
		if i < 3:
			d.point([(6, 6)], fill=(255, 240, 255, 255))
		fr.append(im)
	_grava("particulas", fr)


if __name__ == "__main__":
	slash(); anel(); impacto_chao(); impacto_pogo(); particulas()
	print("vfx shadowblade gerados em", OUT)
