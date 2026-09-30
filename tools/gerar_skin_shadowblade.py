#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Gera a skin Shadowblade Koliani (espelho recolorido do Golden Set).

Independente de `gerar_skins_koliani.py`: nao reescreve nenhuma outra skin.
Mesmas regras -- 84+ frames, mesmo canvas 128x128, pes em y=104; so' pintura e
pecas coladas, NUNCA poses novas (o `run_final` e' a fonte de verdade).

  python tools/gerar_skin_shadowblade.py            # grava assets/sprites/koliani_skins/shadowblade
  python tools/gerar_skin_shadowblade.py --preview  # + work/skins_koliani/shadowblade_folha.png
Depois: godot --headless --import.
"""

from __future__ import annotations

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gerar_skins_koliani as G  # noqa: E402
import trajes_shadowblade as S  # noqa: E402

DEST = os.path.join(G.DEST, "shadowblade")


def gerar() -> int:
	fontes = {os.path.relpath(f, G.GOLDEN).replace(os.sep, "/"): f for f in G._pngs(G.GOLDEN)}
	vestidas = {}
	for i, (rel, f) in enumerate(sorted(fontes.items())):
		if rel in G.RODADOS:
			continue
		num = int(os.path.splitext(rel)[0].rsplit("_", 1)[-1]) if rel[-7:-4].isdigit() else i
		vestidas[rel] = G.vestir(Image.open(f), S.SKIN, num)
	for rel, (fonte, ang) in G.RODADOS.items():
		if rel in fontes and fonte in vestidas:
			vestidas[rel] = G._rodar_como(vestidas[fonte], Image.open(fontes[fonte]).convert("RGBA"),
										  Image.open(fontes[rel]).convert("RGBA"), ang)
	# nada da skin fica abaixo da linha do chao do Golden Set (baseline e pes
	# intocaveis): capa/brilho cortados ao ultimo pixel opaco do original
	for rel, im in vestidas.items():
		if rel.startswith("roll/"):
			continue
		bb = Image.open(fontes[rel]).convert("RGBA").getbbox()
		if bb:
			px = im.load()
			for y in range(bb[3], im.height):
				for x in range(im.width):
					px[x, y] = (0, 0, 0, 0)
	for rel, im in vestidas.items():
		dst = os.path.join(DEST, "frames", rel)
		os.makedirs(os.path.dirname(dst), exist_ok=True)
		im.save(dst, optimize=True)
	G.preview_loja(DEST).save(os.path.join(DEST, "preview.png"), optimize=True)
	print(f"skin shadowblade: {len(vestidas)} frames")
	return len(vestidas)


def folha(saida: str) -> None:
	poses = ["idle/idle_001.png", "run_final/run_001.png", "run_final/run_004.png", "run_final/run_007.png",
			 "attack_basic/attack_basic_003.png", "jump_loop/jump_loop_002.png", "dash/dash_002.png"]
	fontes = [G.GOLDEN, os.path.join(DEST, "frames")]
	cel, esc = 96, 3
	f = Image.new("RGBA", (len(poses) * cel * esc, len(fontes) * cel * esc), (26, 18, 30, 255))
	for j, d in enumerate(fontes):
		for i, p in enumerate(poses):
			im = Image.open(os.path.join(d, p)).convert("RGBA").crop((16, 16, 112, 112))
			f.alpha_composite(im.resize((cel * esc, cel * esc), Image.NEAREST), (i * cel * esc, j * cel * esc))
	os.makedirs(os.path.dirname(saida), exist_ok=True)
	f.save(saida)


if __name__ == "__main__":
	gerar()
	if "--preview" in sys.argv:
		folha(os.path.join(G.RAIZ, "work", "skins_koliani", "shadowblade_folha.png"))
