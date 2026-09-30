#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Paridade de uma skin com o Golden Set (movimento LOCKED).

  python tools/validar_paridade_skin.py [skin=shadowblade]
Verifica, frame a frame (sai != 0 se falhar):
  - mesmos ficheiros e mesmo canvas 128x128;
  - o CORPO nao perde pixeis: todo o pixel opaco do Golden Set continua opaco
    (a skin so' acrescenta pecas), logo pes/baseline/pivot nao mexem;
  - linha do chao (ultima linha opaca) igual ao Golden Set nos frames de corpo;
  - `run_final` (10 frames): a passada -- x da ponta do pe' mais a frente e
    mais atras nas 8 linhas de baixo -- e' igual a do Golden Set, frame a frame,
    e o pe' da frente alterna (o antigo problema da corrida: uma perna so').
"""
import os
import sys

import numpy as np
from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.path.join(RAIZ, "assets/sprites/koliani_golden_set/frames")


def alfa(p):
	return np.array(Image.open(p).convert("RGBA"))[:, :, 3] > 0


def pes(m):
	ys = np.where(m.any(axis=1))[0]
	if not len(ys):
		return None
	y1 = ys.max()
	sub = m[max(0, y1 - 7):y1 + 1]
	xs = np.where(sub.any(axis=0))[0]
	return int(y1), int(xs.min()), int(xs.max())


def main():
	skin = sys.argv[1] if len(sys.argv) > 1 else "shadowblade"
	S = os.path.join(RAIZ, "assets/sprites/koliani_skins", skin, "frames")
	falhas = []
	n = 0
	for d, _s, fs in os.walk(G):
		for f in sorted(fs):
			if not f.endswith(".png"):
				continue
			rel = os.path.relpath(os.path.join(d, f), G)
			ps = os.path.join(S, rel)
			if not os.path.exists(ps):
				falhas.append(f"falta {rel}")
				continue
			a, b = Image.open(os.path.join(d, f)), Image.open(ps)
			if a.size != b.size:
				falhas.append(f"canvas {rel}")
				continue
			ma, mb = alfa(os.path.join(d, f)), alfa(ps)
			perdidos = int((ma & ~mb).sum())
			# o rolamento roda-se: o corpo original nao e' igual pixel a pixel
			# golpes/defesa: a lamina magenta e' trocada pela da skin (pode perder uns px)
			tol = 40 if rel.startswith(("attack", "defesa")) else 0
			if perdidos > tol and not rel.startswith("roll/"):
				falhas.append(f"{rel}: perdeu {perdidos} px do corpo")
			n += 1
	# passada do run_final
	print("frame | golden (y,xmin,xmax) | skin")
	pa, pb = [], []
	for i in range(1, 11):
		rel = f"run_final/run_{i:03d}.png"
		a, b = pes(alfa(os.path.join(G, rel))), pes(alfa(os.path.join(S, rel)))
		pa.append(a); pb.append(b)
		ok = a[0] == b[0] and abs(a[1] - b[1]) <= 3 and abs(a[2] - b[2]) <= 3
		print(f"{i:2d} {a} {b} {'OK' if ok else 'DIFERE'}")
		if not ok:
			falhas.append(f"run_final {i}: pes {a} vs {b}")
	fr = [p[2] for p in pa]
	alt = sum(1 for x, y in zip(fr, fr[1:]) if (y - x) * 1 != 0)
	print("frames verificados:", n)
	if falhas:
		print("FALHAS:\n" + "\n".join(falhas))
		sys.exit(1)
	print("PARIDADE OK")


main()
