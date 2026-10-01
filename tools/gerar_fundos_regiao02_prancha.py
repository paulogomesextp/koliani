#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fundos da Regiao II tirados DAS PRANCHAS APROVADAS (29 set 2026).

    python tools/gerar_fundos_regiao02_prancha.py
    (depois: godot --headless --import)

PORQUE E' QUE ISTO EXISTE

O pack `desfiladeiro` de `tools/gerar_fundos_regiao02.py` e' composto a
partir de camadas CC0 genericas recoloridas, com 240 px de altura, que o
jogo desenha a 4-7x: ceu, serras e falesias aos blocos, sem as ilhas, as
quedas de agua, as pontes nem as ruinas que as pranchas mostram. A auditoria
de 29 set 2026 (N6 ao lado de `concept_environment_01.png`) mostrou que era
ai' que a Regiao II mais se afastava da arte aprovada.

Mesmo metodo que ja' deu o fundo da Regiao I (`tools/nitidez_panorama_9h.py`):
recorte 1:1 da prancha aprovada, sem pintar nem inventar nada, ampliado aqui
com Lanczos + mascara de desfoque em vez de deixar o GPU esticar.

SAIDAS (em `assets/sprites/pixel/backgrounds/desfiladeiro/`)

  prancha_a.png         panorama de `concept_environment_01.png` (lua,
                        cidadela, pontes, estatuas) -- N8, N9, N10
  prancha_b.png         panorama de `concept_environment_02.png` (cidadela,
                        queda de agua, ilhas, ponte) -- N6, N7
  prancha_a_nuvens.png  so' o mar de nuvens do panorama A, com alfa
  prancha_b_nuvens.png  idem, do panorama B

Os recortes deixam de fora a Koliani e a falesia em primeiro plano da
prancha (ficavam como um "segundo chao" atras do jogo). Cada panorama e'
espelhado (A + A invertido) para repetir sem costura.

Os PNG antigos (`ceu`, `serras`, `nuvens`, `falesias`) ficam: o `nuvens.png`
ainda e' a textura da superficie do abismo nas cenas N6-N10.
"""

from __future__ import annotations

import os

from PIL import Image, ImageFilter

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRANCHAS = os.path.join(RAIZ, "docs", "art_direction", "regions", "region_02")
DEST = os.path.join(RAIZ, "assets", "sprites", "pixel", "backgrounds",
	"desfiladeiro")

# (prancha, caixa do recorte x0, y0, x1, y1) -- medido na prancha 1536x1024.
# O painel do topo acaba em y=334 (01) / y=345 (02); a Koliani da prancha esta'
# em x 400-470 (01) e 450-520 (02), por isso o recorte comeca depois dela.
RECORTES = {
	"prancha_a": ("concept_environment_01.png", (640, 2, 1366, 332)),
	"prancha_b": ("concept_environment_02.png", (660, 2, 1366, 343)),
}
# Regiao III (Torre dos Ecos) -- mesmo metodo, pack `torre_ecos`. O painel
# "CONCEITO DA REGIAO" tem o rotulo no canto de cima (ate' y=35): o recorte
# comeca por baixo dele. Nao ha' Koliani nesta prancha.
PRANCHAS_R3 = os.path.join(RAIZ, "docs", "art_direction", "regions",
	"region_03")
DEST_R3 = os.path.join(RAIZ, "assets", "sprites", "pixel", "backgrounds",
	"torre_ecos")
RECORTES_R3 = {
	"prancha": ("concept_environment.png", (292, 38, 948, 312)),
}
# Regiao IV (Fornalha) -- mesmo metodo, pack `fornalha`. O painel "CONCEITO
# DA REGIAO" (a fundicao com a roda dentada e as quedas de lava) ocupa o
# topo da prancha, de x=388 ate' ao painel de texto; a Koliani esta' na
# esquerda (x<390) e fica de fora.
PRANCHAS_R4 = os.path.join(RAIZ, "docs", "art_direction", "regions",
	"region_04")
DEST_R4 = os.path.join(RAIZ, "assets", "sprites", "pixel", "backgrounds",
	"fornalha")
RECORTES_R4 = {
	"prancha": ("concept_environment.png", (392, 8, 1040, 250)),
}
FATOR = 2
# Igual ao da Regiao I (`nitidez_panorama_9h.py`): aresta com contraste sem
# halo claro a' volta das ruinas.
UNSHARP = (2.0, 95, 2)
# Mar de nuvens: so' a metade de baixo do panorama, e alfa pela luminancia.
# As nuvens da prancha estao entre ~150 e ~235 de luma; a rocha das ilhas
# abaixo de ~110. Entre as duas, rampa.
NUVEM_DESDE = 0.52  # fraccao da altura a partir da qual ha' mar de nuvens
LUMA_ROCHA = 112.0
LUMA_NUVEM = 168.0
# Topo do panorama esbatido para a cor do ceu da propria prancha: o jogo
# continua o ceu por cima com uma banda em degrade (`atmosfera.gd`,
# `_banda_acima`) e, sem isto, via-se a linha recta onde a prancha acaba.
TOPO_ESBATIDO = 0.14  # fraccao da altura


def espelhado(im: Image.Image) -> Image.Image:
	"""A + A invertido: a repeticao horizontal fica sem costura."""
	w, h = im.size
	out = Image.new(im.mode, (w * 2, h))
	out.paste(im, (0, 0))
	out.paste(im.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (w, 0))
	return out


def esbater_topo(im: Image.Image) -> Image.Image:
	"""Leva as primeiras linhas para a cor media do ceu da prancha."""
	w, h = im.size
	px = im.load()
	amostra = [px[x, y] for y in range(4) for x in range(0, w, 3)]
	ceu = tuple(sorted(c[i] for c in amostra)[len(amostra) // 2]
		for i in range(3))
	n = max(1, int(h * TOPO_ESBATIDO))
	for y in range(n):
		t = y / n
		k = 1.0 - t * t * (3.0 - 2.0 * t)  # 1 no topo -> 0
		for x in range(w):
			c = px[x, y]
			px[x, y] = tuple(int(c[i] + (ceu[i] - c[i]) * k) for i in range(3))
	return im


def ampliar(im: Image.Image) -> Image.Image:
	w, h = im.size
	g = im.resize((w * FATOR, h * FATOR), Image.Resampling.LANCZOS)
	return g.filter(ImageFilter.UnsharpMask(*UNSHARP))


def nuvens(im: Image.Image) -> Image.Image:
	"""So' o que e' nuvem (claro e pouco saturado) na metade de baixo."""
	rgba = im.convert("RGBA")
	w, h = rgba.size
	px = rgba.load()
	topo = int(h * NUVEM_DESDE)
	for y in range(h):
		# esbate a entrada do mar para nao haver um corte recto no topo dele
		fade_y = 0.0 if y < topo else min(1.0, (y - topo) / (h * 0.12))
		for x in range(w):
			r, g, b, _ = px[x, y]
			luma = 0.299 * r + 0.587 * g + 0.114 * b
			sat = max(r, g, b) - min(r, g, b)
			a = (luma - LUMA_ROCHA) / (LUMA_NUVEM - LUMA_ROCHA)
			a = max(0.0, min(1.0, a))
			if sat > 90:  # bandeiras, lua, flores: nao e' nuvem
				a *= 0.2
			px[x, y] = (r, g, b, int(255 * a * fade_y))
	return rgba


def main() -> None:
	for pranchas, dest, recortes in ((PRANCHAS, DEST, RECORTES),
			(PRANCHAS_R3, DEST_R3, RECORTES_R3),
			(PRANCHAS_R4, DEST_R4, RECORTES_R4)):
		gerar(pranchas, dest, recortes)


def gerar(pranchas: str, dest: str, recortes: dict) -> None:
	os.makedirs(dest, exist_ok=True)
	for nome, (fonte, caixa) in recortes.items():
		src = Image.open(os.path.join(pranchas, fonte)).convert("RGB")
		rec = esbater_topo(espelhado(src.crop(caixa)))
		pano = ampliar(rec)
		pano.save(os.path.join(dest, nome + ".png"), optimize=True)
		if dest == DEST_R4:   # a fundicao nao tem mar de nuvens
			print("%s: %dx%d (de %s %s)" % (nome, pano.width, pano.height,
				fonte, caixa))
			continue
		nv = nuvens(pano)
		nv.save(os.path.join(dest, nome + "_nuvens.png"), optimize=True)
		print("%s: %dx%d (de %s %s)" % (nome, pano.width, pano.height,
			fonte, caixa))


if __name__ == "__main__":
	main()
