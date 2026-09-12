#!/usr/bin/env python3
"""Execution 9H -- folha de revisao humana.

    python tools/folha_revisao_9h.py <pasta_com_pngs> [saida.png]

Junta as provas do EXE de release (intro, menu, seletor, HUD, L1..L5, mobs,
guardioes, boss) numa folha so', com o nome de cada uma por baixo. E' o que
o Game Master abre para dar (ou nao dar) o gate.

Nao mede nada nem decide nada: so' monta. Quem mede e' o `run_tests.gd` e as
rotas de prova do proprio jogo (`--foto-menu=`, `--foto-mapa=`,
`--foto-intro=`, `--nivel=N --foto=`, `--foto-estado=inimigos`).
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

from PIL import Image, ImageDraw

# nome do ficheiro (sem .png) -> legenda na folha, pela ordem da folha
ORDEM = [
	("exe_intro", "1. INTRO (video, EXE de release, pos=2,93 s)"),
	("exe_menu", "2. MENU PRINCIPAL (EXE, v0.17.0)"),
	("exe_mapa", "3. SELETOR / MAPA DA REGIAO I (EXE)"),
	("hud_9h", "4. HUD in-game (kit 9H: carmesim)"),
	("layout3", "5. EDITAR LAYOUT (Web/PWA + toque)"),
	("l1_blur_antes_depois", "6. FUNDO: antes / depois (nitidez)"),
	("exe_l1", "7. L1 Floresta Putrefata"),
	("exe_l2", "8. L2 Pantano dos Sussurros"),
	("exe_l3", "9. L3 Ninho da Viuva Negra"),
	("exe_l4", "10. L4 A Arvore que Chora"),
	("exe_l5", "11. L5 Coracao da Floresta"),
]

LARG = 620          # largura de cada celula
RODAPE = 26


def montar(pasta: Path, destino: Path) -> int:
	celulas: list[tuple[Image.Image, str]] = []
	for nome, legenda in ORDEM:
		f = pasta / (nome + ".png")
		if not f.exists():
			print("  (falta)", f.name)
			continue
		im = Image.open(f).convert("RGB")
		alt = int(im.height * LARG / im.width)
		celulas.append((im.resize((LARG, alt), Image.LANCZOS), legenda))
	if not celulas:
		print("FALHA: nenhuma prova encontrada em", pasta)
		return 1

	cols = 2
	linhas = (len(celulas) + cols - 1) // cols
	alt_linha = max(c[0].height for c in celulas) + RODAPE
	folha = Image.new("RGB", (LARG * cols + 12, alt_linha * linhas + 12), (14, 8, 14))
	d = ImageDraw.Draw(folha)
	for i, (im, legenda) in enumerate(celulas):
		x = (i % cols) * LARG + 6
		y = (i // cols) * alt_linha + 6
		folha.paste(im, (x, y))
		d.rectangle((x, y, x + LARG - 1, y + im.height - 1), outline=(150, 30, 46))
		d.text((x + 4, y + im.height + 6), legenda, fill=(230, 210, 218))
	destino.parent.mkdir(parents=True, exist_ok=True)
	folha.save(destino)
	print("folha de revisao ->", destino, folha.size)
	return 0


def main(argv: list[str]) -> int:
	if not argv:
		print(__doc__)
		return 1
	pasta = Path(argv[0])
	destino = Path(argv[1]) if len(argv) > 1 else pasta / "folha_revisao_9h.png"
	return montar(pasta, destino)


if __name__ == "__main__":
	raise SystemExit(main(sys.argv[1:]))
