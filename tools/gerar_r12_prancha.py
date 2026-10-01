#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Arte da Regiao XII (Terras Envenenadas, N56-N60) recortada da PRANCHA APROVADA.

    python3 tools/gerar_r12_prancha.py            # terreno + fundos + props
    python3 tools/gerar_r12_prancha.py props      # so' uma das tres
    (depois: godot --headless --import)

Fonte unica: `docs/art_direction/regions/region_12/master_production_board.png`
(1448x1086). Mesmo metodo das regioes III e IV -- recorte 1:1, fundo escuro ->
alfa, ampliar com Lanczos -- mas a prancha desta regiao e' um quadro unico e
pequeno (as pecas tem 25-50 px), por isso as ampliacoes sao maiores (x4) e o
terreno junta uma textura de ruido fino para nao ficar borrado.

Saidas:
  assets/sprites/pixel/terreno/terras_envenenadas/{corpo,topo,lado,base}.png
  assets/sprites/pixel/backgrounds/terras_n56 .. terras_n60/prancha.png
  assets/sprites/pixel/deco/terras_envenenadas/r12_*.png
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gerar_terreno_prancha as gt  # noqa: E402
from gerar_props_prancha import aparar, sem_molduras  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRANCHA = os.path.join(RAIZ, "docs/art_direction/regions/region_12/master_production_board.png")
ASSETS = os.path.join(RAIZ, "assets/sprites/pixel")

# fundo quase preto-esverdeado dos paineis
FUNDO = (11, 16, 14)

# ----------------------------------------------------------------- terreno
CFG_TERRENO = {
	"prancha": "docs/art_direction/regions/region_12/master_production_board.png",
	# "SOLO NORMAL" (terra castanha com raizes) e a "LAMA ENVENENADA" (pedra
	# cinza) -> miolo feito repetivel por `sem_costura`
	"espelho": [(12, 569, 38, 592), (12, 592, 38, 615)],
	# capa: o labio de lodo verde da "TERRA TOXICA" (com gotas)
	"topo_y": (566, 578),
	"topo_x": [(55, 90), (55, 90)],
	"lado": (11, 580, 16, 614),
	# a franja de gotas por baixo da "TERRA TOXICA"
	"base": (55, 607, 90, 618),
}


def corpo_uniforme(src: Image.Image, caixa: tuple) -> Image.Image:
	"""Miolo da terra: o recorte, sem as bandas claras/escuras (passa-alto +
	media), feito repetivel nos dois eixos. Sem isto o mosaico lia-se como
	um tabuleiro de xadrez."""
	c0 = src.crop(caixa)
	rec = c0.resize((c0.width * 4, c0.height * 4), Image.Resampling.LANCZOS)
	a = np.asarray(rec.convert("RGB"), dtype=np.float32)
	baixa = np.asarray(rec.convert("RGB").filter(ImageFilter.GaussianBlur(26)), dtype=np.float32)
	media = a.reshape(-1, 3).mean(axis=0)
	alvo = np.clip((a - baixa) * 0.7 + media * 0.8, 0, 255).astype(np.uint8)
	rec = Image.fromarray(alvo).convert("RGBA")
	rec = gt.sem_costura(rec)
	# grelha de variantes dihedrais ao acaso (semente fixa): a terra e' ruido
	# fino, sem estrutura, por isso a mistura nao deixa costuras a' vista.
	import random
	rng = random.Random(1256)
	w, h = rec.size
	cols, filas = 5, 4
	out = Image.new("RGBA", (w * cols, h * filas))
	ops = [None, Image.Transpose.FLIP_LEFT_RIGHT, Image.Transpose.FLIP_TOP_BOTTOM,
		Image.Transpose.ROTATE_180]
	for j in range(filas):
		for i in range(cols):
			op = rng.choice(ops)
			t = rec if op is None else rec.transpose(op)
			out.paste(t, (i * w, j * h))
	return out


def terreno() -> None:
	gt.FUNDO = FUNDO
	gt.ALFA_DE, gt.ALFA_ATE = 14.0, 46.0
	gt.gerar("terras_envenenadas", CFG_TERRENO)
	src = Image.open(PRANCHA).convert("RGB")
	corpo_uniforme(src, (12, 569, 38, 615)).save(
		os.path.join(ASSETS, "terreno", "terras_envenenadas", "corpo.png"), optimize=True)


# ------------------------------------------------------------------ fundos
# Cada nivel tem o seu mural no cartao do nivel (o titulo ocupa o topo: o
# recorte comeca por baixo dele). (x0, y0, x1, y1) medido na prancha.
MURAIS = {
	"terras_n56": (10, 270, 291, 374),
	"terras_n57": (303, 270, 580, 374),
	"terras_n58": (590, 270, 858, 374),
	"terras_n59": (871, 270, 1146, 374),
	"terras_n60": (1160, 270, 1441, 374),
}
FATOR = 4
UNSHARP = (2.0, 70, 2)


def fundos() -> None:
	src = Image.open(PRANCHA).convert("RGB")
	for nome, caixa in MURAIS.items():
		rec = src.crop(caixa)
		# espelhado: A + A invertido, repete sem costura
		w, h = rec.size
		dup = Image.new("RGB", (w * 2, h))
		dup.paste(rec, (0, 0))
		dup.paste(rec.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (w, 0))
		dup = gt_esbater_topo(dup)
		g = dup.resize((dup.width * FATOR, dup.height * FATOR), Image.Resampling.LANCZOS)
		g = g.filter(ImageFilter.UnsharpMask(*UNSHARP))
		dest = os.path.join(ASSETS, "backgrounds", nome)
		os.makedirs(dest, exist_ok=True)
		g.save(os.path.join(dest, "prancha.png"), optimize=True)
		print("%s/prancha.png %dx%d" % (nome, g.width, g.height))


def gt_esbater_topo(im: Image.Image) -> Image.Image:
	"""Topo para a cor do ceu (o jogo continua o ceu por cima com um degrade)."""
	import gerar_fundos_regiao02_prancha as gf
	gf.TOPO_ESBATIDO = 0.22
	return gf.esbater_topo(im)


# ------------------------------------------------------------------- props
ROOT_DECO = os.path.join(ASSETS, "deco", "terras_envenenadas")
ALFA_DE, ALFA_ATE = 16.0, 44.0

# nome -> (caixa x0,y0,x1,y1, ampliacao, modo)  [modo: solido | luz]
CAIXAS = {
	# --- ESTRUTURAS E RUINAS ---
	"r12_cerca": ((198, 578, 242, 622), 4, "solido"),
	"r12_palicada": ((248, 574, 282, 622), 4, "solido"),
	"r12_ruinas": ((281, 580, 307, 624), 4, "solido"),
	"r12_moinho": ((309, 550, 357, 624), 4, "solido"),
	"r12_casas": ((360, 545, 407, 627), 4, "solido"),
	# --- PROPS FUNCIONAIS ---
	"r12_barril": ((416, 574, 447, 622), 4, "solido"),
	"r12_tubo_a": ((455, 574, 480, 622), 4, "solido"),
	"r12_tubo_b": ((481, 574, 506, 622), 4, "solido"),
	"r12_valvula": ((520, 586, 555, 619), 4, "solido"),
	"r12_passarela": ((563, 568, 610, 624), 4, "solido"),
	"r12_ponte": ((616, 570, 657, 624), 4, "solido"),
	"r12_escada": ((659, 565, 712, 627), 4, "solido"),
	# --- VEGETACAO ---
	"r12_arvore_morta_p": ((14, 680, 62, 737), 4, "solido"),
	"r12_arvore_morta_g": ((68, 673, 142, 737), 4, "solido"),
	"r12_fungos_p": ((144, 683, 195, 737), 4, "solido"),
	"r12_fungos_g": ((198, 668, 278, 737), 4, "solido"),
	"r12_planta_toxica": ((279, 673, 342, 737), 4, "solido"),
	# --- DETALHES ---
	"r12_ossos": ((350, 690, 392, 732), 4, "solido"),
	"r12_carroca": ((389, 685, 437, 732), 4, "solido"),
	"r12_estacas": ((434, 688, 480, 734), 4, "solido"),
	"r12_cranios": ((477, 695, 507, 732), 4, "solido"),
	"r12_poste": ((508, 675, 540, 734), 4, "solido"),
	"r12_bandeira": ((541, 662, 575, 734), 4, "solido"),
	"r12_santuario": ((576, 668, 636, 734), 4, "solido"),
	"r12_estatua": ((637, 658, 717, 734), 4, "solido"),
	# --- EFEITOS (alfa = brilho, blend ADD) ---
	"r12_poca_toxica": ((353, 778, 427, 817), 4, "luz"),
	"r12_geiser": ((440, 762, 477, 817), 4, "luz"),
	"r12_nuvem_veneno": ((478, 768, 547, 814), 4, "luz"),
	"r12_bolhas": ((548, 790, 587, 814), 4, "luz"),
	"r12_vento_toxico": ((596, 768, 657, 814), 4, "luz"),
	"r12_valvula_ativa": ((660, 758, 709, 817), 4, "solido"),
}
LIMIAR_LUZ = {"r12_poca_toxica": 50.0, "r12_geiser": 50.0, "r12_nuvem_veneno": 46.0,
	"r12_bolhas": 48.0, "r12_vento_toxico": 44.0}


def com_alfa(im: Image.Image, modo: str, nome: str) -> Image.Image:
	a = np.asarray(im.convert("RGB"), dtype=np.float32)
	if modo == "luz":
		br = a.max(axis=2)
		lim = LIMIAR_LUZ.get(nome, 40.0)
		al = np.clip((br - lim) / 60.0, 0.0, 1.0)
	else:
		d = np.sqrt(((a - np.array(FUNDO, dtype=np.float32)) ** 2).sum(axis=2))
		al = np.clip((d - ALFA_DE) / (ALFA_ATE - ALFA_DE), 0.0, 1.0)
	out = np.dstack([a, al * 255.0]).astype(np.uint8)
	return Image.fromarray(out, "RGBA").copy()


def suave(im: Image.Image, fr: float = 0.2) -> Image.Image:
	w, h = im.size
	a = np.asarray(im.getchannel("A"), dtype=np.float32)
	fx, fy = max(2, int(w * fr)), max(2, int(h * fr))
	ky = np.minimum(np.arange(h), h - 1 - np.arange(h)) / fy
	kx = np.minimum(np.arange(w), w - 1 - np.arange(w)) / fx
	k = np.clip(np.minimum(ky[:, None], kx[None, :]), 0, 1)
	a = a * k * k * (3 - 2 * k)
	out = im.copy()
	out.putalpha(Image.fromarray(a.astype(np.uint8)))
	return out


def props() -> None:
	os.makedirs(ROOT_DECO, exist_ok=True)
	src = Image.open(PRANCHA).convert("RGB")
	for nome, (caixa, amp, modo) in CAIXAS.items():
		p = com_alfa(src.crop(caixa), modo, nome)
		p = aparar(sem_molduras(p))
		p = p.resize((p.width * amp, p.height * amp), Image.Resampling.LANCZOS)
		if modo == "luz":
			p = suave(p, 0.18)
		else:
			p = p.filter(ImageFilter.UnsharpMask(1.2, 60, 2))
		p.save(os.path.join(ROOT_DECO, nome + ".png"), optimize=True)
		print("%s: %dx%d" % (nome, p.width, p.height))


def main() -> None:
	quais = sys.argv[1:] or ["terreno", "fundos", "props"]
	if "terreno" in quais:
		terreno()
	if "fundos" in quais:
		fundos()
	if "props" in quais:
		props()


if __name__ == "__main__":
	main()
