#!/usr/bin/env python3
"""Execution 9H.1 -- FOLHA DE REVISAO para o Game Master.

    python tools/folha_revisao_9h1.py

Junta num unico PNG tudo o que a 9H.1 produziu como prova: o combo (com e
sem VFX), o movimento das criaturas e das duas fases do Coracao, o seletor
com pele de regiao contra a apresentacao neutra, e o que se viu no EXE de
release e no Chrome real.

Cada painel leva o titulo por cima. Nao esconde o que ficou por provar: os
painteis em falta aparecem como uma caixa a dizer o que falta e porque.
"""
from __future__ import annotations

import os

from PIL import Image, ImageDraw

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W = os.path.join(RAIZ, "work", "execution_9h1")
SAIDA = os.path.join(W, "folha_revisao_9h1.png")

LARG = 1800
MARGEM = 16
TITULO = 22

## (titulo, caminho, altura maxima do painel)
PAINEIS = [
	("1. COMBO -- os quatro golpes no jogo a correr (8 instantes cada)",
		"movimento/koliani_combo.png", 420),
	("2. O MESMO COMBO SEM VFX -- 'reads without VFX?'",
		"movimento/koliani_combo_sem_vfx.png", 420),
	("3. KOLIANI -- as quatro tiras derivadas, lado a lado (sprite, 4x)",
		"combo_tiras_zoom.png", 460),
	("4. GHORAK -- idle / run / attack",
		"movimento/ghorak.png", 300),
	("5. GOBLIN -- idle / run / attack",
		"movimento/goblin.png", 300),
	("6. MORVANNA -- idle / run / attack",
		"movimento/morvanna.png", 300),
	("7. RAINHA ARACNIDEA -- idle / run / attack",
		"movimento/rainha_aracnidea.png", 300),
	("8. ENTREVANE -- idle / run / attack",
		"movimento/entrevane.png", 300),
	("9. CORACAO PUTREFACTO -- FASE 1 (idle + attack)",
		"movimento/coracao_fase1.png", 290),
	("10. CORACAO PUTREFACTO -- FASE 2 (amplitude 1,9x)",
		"movimento/coracao_fase2.png", 290),
	("11. SELETOR -- REGIAO I no EXE de release (verde de musgo, acento magenta no guardiao)",
		"windows/03_seletor_r1.png", 430),
	("12. SELETOR -- regiao SEM autoridade visual, apresentacao neutra em aco frio",
		"windows/04_seletor_neutro.png", 430),
	("13. WEB/PWA em CHROME REAL -- menu (v0.18.0)",
		"web/web_01_menu.png", 400),
	("14. WEB/PWA em CHROME REAL -- seletor da Regiao I",
		"web/web_02_seletor_r1.png", 400),
	("15. WEB/PWA em CHROME REAL -- apresentacao neutra",
		"web/web_03_seletor_neutro.png", 400),
	("16. WEB/PWA em CHROME REAL -- EDITAR LAYOUT",
		"web/web_04_editor_layout.png", 400),
	("17. WEB/PWA -- layout editado (joystick e salto movidos E aumentados)",
		"web/web_05_layout_editado.png", 400),
	("18. EXE de release -- intro, menu, e os niveis 1/3/5 com HUD",
		"windows_montagem.png", 460),
]


def montar_windows():
	"""Monta as fotos do frontend/gameplay do EXE numa tira so'."""
	fs = ["windows/01_intro.png", "windows/02_menu.png", "windows/11_nivel1.png",
		"windows/13_nivel3.png", "windows/15_nivel5.png"]
	ims = []
	for f in fs:
		p = os.path.join(W, f)
		if os.path.exists(p):
			ims.append(Image.open(p).convert("RGB"))
	if not ims:
		return None
	h = 220
	esc = [i.resize((round(i.width * h / i.height), h), Image.LANCZOS) for i in ims]
	larg = sum(i.width for i in esc)
	fora = Image.new("RGB", (larg, h), (14, 12, 18))
	x = 0
	for i in esc:
		fora.paste(i, (x, 0))
		x += i.width
	cam = os.path.join(W, "windows_montagem.png")
	fora.save(cam)
	return cam


def montar_combo_zoom():
	"""As quatro tiras derivadas, recortadas à volta da figura e a 4x."""
	F = os.path.join(RAIZ, "assets/sprites/koliani_golden_set/frames")
	linhas = [("1 corte", "attack_basic"), ("2 reves", "attack_2"),
		("3 rodopio", "attack_3"), ("4 remate", "attack_4")]
	CX, CY, CW, CH, Z = 24, 30, 104, 78, 4
	folha = Image.new("RGB", (CW * 6 * Z, (CH * Z + 18) * 4), (14, 12, 18))
	d = ImageDraw.Draw(folha)
	for r, (nome, pasta) in enumerate(linhas):
		for i in range(6):
			p = os.path.join(F, pasta, "%s_%03d.png" % (pasta, i + 1))
			if not os.path.exists(p):
				continue
			im = Image.open(p).convert("RGBA").crop((CX, CY, CX + CW, CY + CH))
			im = im.resize((CW * Z, CH * Z), Image.NEAREST)
			fundo = Image.new("RGBA", im.size, (14, 12, 18, 255))
			fundo.alpha_composite(im)
			folha.paste(fundo.convert("RGB"), (i * CW * Z, r * (CH * Z + 18) + 18))
		d.text((6, r * (CH * Z + 18) + 4), nome, fill=(240, 225, 235))
	cam = os.path.join(W, "combo_tiras_zoom.png")
	folha.save(cam)
	return cam


def main():
	montar_windows()
	montar_combo_zoom()
	blocos = []
	for titulo, rel, alt in PAINEIS:
		p = os.path.join(W, rel)
		if not os.path.exists(p):
			blocos.append((titulo, None, 90))
			continue
		im = Image.open(p).convert("RGB")
		larg = LARG - 2 * MARGEM
		nova = (larg, max(1, round(im.height * larg / im.width)))
		if nova[1] > alt:
			nova = (max(1, round(im.width * alt / im.height)), alt)
		blocos.append((titulo, im.resize(nova, Image.LANCZOS), nova[1]))

	altura = sum(b[2] + TITULO + MARGEM for b in blocos) + MARGEM + 70
	folha = Image.new("RGB", (LARG, altura), (12, 10, 15))
	d = ImageDraw.Draw(folha)
	d.text((MARGEM, 14), "KOLIANI -- Execution 9H.1 -- folha de revisao "
		"(v0.18.0, commit 12f1209)", fill=(255, 240, 245))
	d.text((MARGEM, 38), "Trilha sonora original | combo com poses proprias | "
		"movimento das criaturas | seletor com tema por regiao | "
		"prova em Windows e em Chrome real", fill=(190, 180, 195))
	y = 70
	for titulo, im, alt in blocos:
		d.text((MARGEM, y + 4), titulo, fill=(250, 225, 235))
		y += TITULO
		if im is None:
			d.rectangle([MARGEM, y, LARG - MARGEM, y + 70], outline=(160, 70, 90))
			d.text((MARGEM + 10, y + 26), "SEM PROVA -- ver 'o que fica por fazer' "
				"no relatorio", fill=(230, 150, 170))
			y += 70 + MARGEM
			continue
		folha.paste(im, (MARGEM, y))
		y += alt + MARGEM
	folha.save(SAIDA)
	print("folha -> %s  (%dx%d)" % (SAIDA, folha.width, folha.height))


if __name__ == "__main__":
	main()
