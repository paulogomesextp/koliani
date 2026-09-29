# -*- coding: utf-8 -*-
"""Crivo da PASSADA da Koliani (Execution 9H.18).

O que prova, e porque este criterio e nao outro
-----------------------------------------------
Medir a "abertura das pernas" NAO chega: um ciclo de UMA perna abre e fecha
na mesma. O que separa as duas coisas e' o VARRIMENTO DE CADA PERNA. Em
cada frame de contacto ha' dois pes separados; segue-se o de tras e o da
frente ao longo do ciclo e mede-se quanto chao cada um percorre. Numa
corrida a serio os dois percorrem mais ou menos o mesmo -- e' o mesmo
movimento desfasado de meio ciclo. Se um deles quase nao anda, esta' a ser
arrastado, e e' exactamente isso que o jogador le' como "ela desliza".

Medido na folha golden que o jogo usa (9H.18):
  contactos 4/10 | pe' de tras varre 7 px | pe' da frente varre 29 px
  -> razao 0,24: uma perna anda quatro vezes menos do que a outra. REPROVA.
Na folha do piloto 5G, para comparar:
  contactos 11/12 | tras 22 px | frente 20 px -> razao 1,10. PASSA.

Uso
---
    python tools/validar_run_nativo_9h18.py <pasta_de_frames>
    python tools/validar_run_nativo_9h18.py <folha.png> --largura 128

Sai 0 se PASSA, 1 se REPROVA. Serve tal e qual para validar a arte nativa
que vier a substituir o `run` -- ver `docs/spec_run_nativo_koliani.md`.
"""
import argparse
import glob
import os
import sys

from PIL import Image

LIMIAR_ALFA = 24
## Fraccao minima de frames que tem de mostrar os DOIS pes separados.
MIN_FRACCAO_CONTACTOS = 0.50
## Chao que CADA perna tem de varrer ao longo do ciclo, em px do frame.
MIN_VARRIMENTO = 16
## Razao entre a perna que anda menos e a que anda mais. Abaixo disto uma
## delas esta' a ser arrastada.
MIN_RAZAO_PERNAS = 0.55
## Os pes nao podem flutuar: a base do corpo e' a mesma em todo o ciclo.
MAX_DERIVA_BASE = 2


def carregar(caminho: str, largura: int | None) -> list[Image.Image]:
	if os.path.isdir(caminho):
		fs = sorted(glob.glob(os.path.join(caminho, "*.png")))
		if not fs:
			raise SystemExit("sem PNGs em %s" % caminho)
		return [Image.open(f).convert("RGBA") for f in fs]
	folha = Image.open(caminho).convert("RGBA")
	if not largura:
		raise SystemExit("uma folha precisa de --largura (px por celula)")
	n = folha.width // largura
	return [folha.crop((i * largura, 0, (i + 1) * largura, folha.height)) for i in range(n)]


def medir(im: Image.Image) -> dict | None:
	"""Anca em x e os blobs do tornozelo, em x relativo a` anca."""
	px = im.load()
	W, H = im.size
	pontos = [(x, y) for y in range(H) for x in range(W) if px[x, y][3] > LIMIAR_ALFA]
	if not pontos:
		return None
	y0 = min(p[1] for p in pontos)
	y1 = max(p[1] for p in pontos)
	alt = y1 - y0 + 1
	# A anca fica entre 50% e 62% da altura do corpo -- e' a faixa mais estavel
	# (o cabelo e a capa mexem em cima, as pernas em baixo).
	ha, hb = y0 + int(alt * 0.50), y0 + int(alt * 0.62)
	xs = [x for (x, y) in pontos if ha <= y <= hb]
	anca = (min(xs) + max(xs)) // 2 if xs else (min(p[0] for p in pontos) + max(p[0] for p in pontos)) // 2
	# Banda dos tornozelos: os 10% de baixo do corpo.
	banda = range(y1 - max(2, int(alt * 0.10)), y1 + 1)
	ligado = [False] * W
	for y in banda:
		for x in range(W):
			if px[x, y][3] > LIMIAR_ALFA:
				ligado[x] = True
	blobs: list[int] = []
	ini = None
	for x in range(W + 1):
		v = ligado[x] if x < W else False
		if v and ini is None:
			ini = x
		if not v and ini is not None:
			blobs.append(((ini + x - 1) // 2) - anca)
			ini = None
	return {"anca": anca, "pes": blobs, "base": y1}


def main() -> int:
	ap = argparse.ArgumentParser()
	ap.add_argument("caminho")
	ap.add_argument("--largura", type=int, default=None)
	ap.add_argument("--silencioso", action="store_true")
	args = ap.parse_args()

	frames = carregar(args.caminho, args.largura)
	tras: list[int] = []
	frente: list[int] = []
	bases: list[int] = []
	contactos = 0
	uteis = 0
	for i, im in enumerate(frames):
		m = medir(im)
		if m is None:
			print("  f%02d VAZIO" % i)
			continue
		uteis += 1
		bases.append(m["base"])
		pes = m["pes"]
		marca = ""
		if len(pes) >= 2:
			contactos += 1
			tras.append(min(pes))
			frente.append(max(pes))
			marca = "  <- contacto"
		if not args.silencioso:
			print("  f%02d anca_x=%3d base_y=%3d pes(rel)=%s%s"
				% (i, m["anca"], m["base"], ["%+d" % p for p in pes], marca))

	fraccao = (contactos / uteis) if uteis else 0.0
	varr_tras = (max(tras) - min(tras)) if tras else 0
	varr_frente = (max(frente) - min(frente)) if frente else 0
	maior = max(varr_tras, varr_frente)
	razao = (min(varr_tras, varr_frente) / maior) if maior else 0.0
	deriva_base = (max(bases) - min(bases)) if bases else 0

	print("")
	print("frames.................: %d" % uteis)
	print("frames de contacto.....: %d (%.0f%%, minimo %.0f%%)"
		% (contactos, fraccao * 100.0, MIN_FRACCAO_CONTACTOS * 100.0))
	print("varrimento do pe' tras.: %d px (minimo %d)" % (varr_tras, MIN_VARRIMENTO))
	print("varrimento do da frente: %d px (minimo %d)" % (varr_frente, MIN_VARRIMENTO))
	print("razao entre as pernas..: %.2f (minimo %.2f)" % (razao, MIN_RAZAO_PERNAS))
	print("deriva da base.........: %d px (maximo %d)" % (deriva_base, MAX_DERIVA_BASE))

	falhas = []
	if fraccao < MIN_FRACCAO_CONTACTOS:
		falhas.append("so' %.0f%% dos frames mostram os dois pes separados"
			% (fraccao * 100.0))
	if varr_tras < MIN_VARRIMENTO:
		falhas.append("o pe' de tras varre %d px -- esta' arrastado" % varr_tras)
	if varr_frente < MIN_VARRIMENTO:
		falhas.append("o pe' da frente varre %d px -- esta' arrastado" % varr_frente)
	if razao < MIN_RAZAO_PERNAS:
		falhas.append("uma perna anda %.2f do que a outra -- nao ha' alternancia"
			% razao)
	if deriva_base > MAX_DERIVA_BASE:
		falhas.append("a base varia %d px -- a personagem flutua" % deriva_base)
	if falhas:
		print("")
		print("REPROVA:")
		for f in falhas:
			print("  - %s" % f)
		return 1
	print("")
	print("PASSA -- o ciclo tem passada de duas pernas.")
	return 0


if __name__ == "__main__":
	sys.exit(main())
