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
	preview_premium().save(os.path.join(DEST, "preview.png"), optimize=True)
	print(f"skin shadowblade: {len(vestidas)} frames")
	return len(vestidas)


def preview_premium() -> Image.Image:
	"""Cartao da Loja: o golpe (arma + arco de sombra) sobre uma aura violeta
	suave, para a lendaria se ler logo no cartao. Mesma moldura quadrada."""
	from PIL import ImageFilter
	corpo = Image.open(os.path.join(DEST, "frames", "attack_basic", "attack_basic_003.png")).convert("RGBA")
	arco = Image.open(os.path.join(DEST, "vfx", "vfx_slash_basic", "vfx_slash_basic_005.png")).convert("RGBA")
	# o arco sai da `SlashVFX` deslocada (16,-30) do centro do corpo
	cena = Image.new("RGBA", corpo.size, (0, 0, 0, 0))
	cena.alpha_composite(arco, (16, -30 + 0))
	cena = Image.alpha_composite(cena, Image.new("RGBA", cena.size, (0, 0, 0, 0)))
	tudo = Image.alpha_composite(Image.alpha_composite(Image.new("RGBA", corpo.size, (0, 0, 0, 0)), cena), corpo)
	x0, y0, x1, y1 = tudo.getbbox()
	lado = max(x1 - x0, y1 - y0) + 18
	cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
	tela = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
	aura = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
	from PIL import ImageDraw
	ImageDraw.Draw(aura).ellipse([lado * 0.12, lado * 0.1, lado * 0.88, lado * 0.92], fill=(120, 30, 210, 120))
	tela.alpha_composite(aura.filter(ImageFilter.GaussianBlur(lado * 0.09)))
	tela.alpha_composite(tudo, (lado // 2 - cx, lado // 2 - cy))
	return tela


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
