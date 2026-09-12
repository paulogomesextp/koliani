#!/usr/bin/env python3
"""Execution 9H.1 -- PELE DO SELECTOR POR REGIAO (Regiao I: floresta).

    python tools/tema_regiao_9h1.py [--regiao 1]

O Game Master: o selector nao pode ter uma so' pele global. Cada regiao tem
de se ver ao entrar nela -- e a Regiao I tem de ler-se como FLORESTA
CORROMPIDA, nao como um ecra carmesim generico.

O que isto produz, tudo em `assets/ui/frontend_9h/regioes/r01/`:

  fundo_seletor.png   a vista da regiao, COMPOSTA a partir da arte de
                      producao ja' aprovada da Regiao I (o panorama da
                      Arvore-Coracao do 9H, a vegetacao da frente, as
                      silhuetas de arvore e a nevoa do kit 9C). Nao ha' aqui
                      um unico pixel inventado: e' o cenario do jogo, visto
                      de longe.
  <pecas>.png         as pecas do frontend (aneis, painel, abas, botao,
                      ficha, setas, ornamentos) com a mesma forma e o
                      carmesim rodado para VERDE DE MUSGO. Sao desenhos de
                      linha luminosa praticamente monocromaticos, por isso a
                      rotacao de matiz preserva tudo menos a cor.
  anel_chefe.png      excepcao deliberada: o no' do guardiao fica em
                      MAGENTA/VIOLETA -- e' o acento de corrupcao que a
                      regiao usa em todo o lado (VFX, inimigos, Arvore).
                      Verde = a floresta; magenta = o que lhe esta' a
                      acontecer.

REGIOES II-XX: nao se produz nada. Nao ha' autoridade visual aprovada para
elas e inventar uma seria exactamente o que o briefing proibe. O selector
usa a apresentacao NEUTRA (ver `scripts/tema_regiao.gd`).
"""
from __future__ import annotations

import colorsys
import hashlib
import json
import math
import os
import sys

from PIL import Image, ImageFilter

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI = os.path.join(RAIZ, "assets", "ui", "frontend_9h")
SAIDA = os.path.join(UI, "regioes", "r01")
NEUTRO_DIR = os.path.join(UI, "regioes", "neutro")
R1 = os.path.join(RAIZ, "assets", "art", "regions", "region_01_forest", "production")
KIT = os.path.join(R1, "kit_9c")

ECRA = (1920, 1080)
## Escrever sempre com LF: o Python no Windows mete CRLF por omissao e ha'
## ferramentas do repo que leem estes ficheiros linha a linha.
LF = chr(10)

## Matiz alvo das pecas. 0,30 = verde de musgo; 0,84 = o magenta da corrupcao.
VERDE = 0.30
MAGENTA = 0.84
## Pecas que levam o acento de corrupcao em vez do verde.
CORRUPCAO = {"anel_chefe", "cadeado"}
## Tudo o que o selector desenha.
PECAS = ["anel_normal", "anel_atual", "anel_chefe", "painel_detalhe",
	"botao_jogar", "aba_atual", "aba_bloqueada", "ficha_nivel",
	"placa_selecionada", "separador_menu", "seta_direita", "seta_esquerda",
	"cadeado", "ornamento_rodape", "voltar_seta", "losango"]


def rodar_matiz(im, alvo, forca_sat=0.70, espalhar=0.30, luz=0.86):
	"""Roda a matiz dos pixeis com cor para `alvo`, guardando luminancia e
	uma parte da variacao interna de matiz (`espalhar`). Os cinzentos (o
	metal e a pedra das molduras) ficam como estao -- so' a LUZ muda de cor."""
	px = im.load()
	fora = im.copy()
	fp = fora.load()
	for y in range(im.height):
		for x in range(im.width):
			r, g, b, a = px[x, y]
			if a == 0:
				continue
			h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
			if s < 0.10:
				continue
			# distancia do vermelho de origem (matiz ~0,98..0,02), em ciclo
			d = ((h - 0.99) + 0.5) % 1.0 - 0.5
			nh = (alvo + d * espalhar) % 1.0
			# musgo, nao neon: o verde a` mesma luminancia do carmesim sai
			# fluorescente e come o texto que tem por cima
			nr, ng, nb = colorsys.hls_to_rgb(nh, min(1.0, l * luz), min(1.0, s * forca_sat))
			fp[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), a)
	return fora


def dessaturar(im, tinta=(0.86, 0.88, 0.96), luz=0.78):
	"""Tira a COR e deixa a forma. E' isto a apresentacao neutra das regioes
	sem autoridade: a peca aprovada, em aco frio, a dizer "ainda nao ha'
	identidade para aqui". Modular por um cinzento nao chega -- multiplicar
	um carmesim por cinzento da' um carmesim escuro, continua vermelho."""
	px = im.load()
	fora = im.copy()
	fp = fora.load()
	for y in range(im.height):
		for x in range(im.width):
			r, g, b, a = px[x, y]
			if a == 0:
				continue
			v = (0.2126 * r + 0.7152 * g + 0.0722 * b) * luz
			fp[x, y] = (min(255, int(v * tinta[0])), min(255, int(v * tinta[1])),
				min(255, int(v * tinta[2])), a)
	return fora


def carregar(p, modo="RGBA"):
	return Image.open(p).convert(modo)


def por_largura(im, larg):
	return im.resize((larg, max(1, round(im.height * larg / im.width))), Image.LANCZOS)


def escurecer(im, k, tinta=(0.72, 0.86, 0.78)):
	"""Multiplica e puxa para o azul-esverdeado -- o ar da floresta a` noite."""
	px = im.load()
	for y in range(im.height):
		for x in range(im.width):
			r, g, b, a = px[x, y]
			if a == 0:
				continue
			px[x, y] = (int(r * k * tinta[0]), int(g * k * tinta[1]),
				int(b * k * tinta[2]), a)
	return im


def esbater(im, cima=0, baixo=0):
	"""Rampa de alfa no topo e/ou na base. Sem isto ve^-se a ARESTA de cada
	camada colada -- riscos horizontais a atravessar o ecra de lado a lado.

	NB: `im.getchannel("A")` devolve uma IMAGEM NOVA. A primeira versao
	escrevia nessa copia e devolvia o original intacto -- a ferramenta corria,
	nao dava erro, e as arestas continuavam la'. Tem de se repor com
	`putalpha`."""
	a = im.getchannel("A")
	ap = a.load()
	w, h = im.size
	for y in range(h):
		k = 1.0
		if cima and y < cima:
			k = min(k, y / float(cima))
		if baixo and y > h - baixo:
			k = min(k, (h - y) / float(baixo))
		if k >= 0.999:
			continue
		for x in range(w):
			ap[x, y] = int(ap[x, y] * k)
	im.putalpha(a)
	return im


def esbater_x(im, esq=0, dir=0):
	"""O mesmo nas pontas da esquerda/direita."""
	a = im.getchannel("A")
	ap = a.load()
	w, h = im.size
	for x in range(w):
		k = 1.0
		if esq and x < esq:
			k = min(k, x / float(esq))
		if dir and x > w - dir:
			k = min(k, (w - x) / float(dir))
		if k >= 0.999:
			continue
		for y in range(h):
			ap[x, y] = int(ap[x, y] * k)
	im.putalpha(a)
	return im


def degrade(tam, cima, baixo):
	im = Image.new("RGBA", tam)
	p = im.load()
	for y in range(tam[1]):
		t = y / max(1, tam[1] - 1)
		c = tuple(int(cima[i] + (baixo[i] - cima[i]) * t) for i in range(3))
		for x in range(tam[0]):
			p[x, y] = c + (255,)
	return im


def vinheta(tam, forca=0.82):
	im = Image.new("RGBA", tam, (0, 0, 0, 0))
	p = im.load()
	cx, cy = tam[0] / 2.0, tam[1] / 2.0
	rmax = math.hypot(cx, cy)
	for y in range(tam[1]):
		for x in range(tam[0]):
			t = math.hypot(x - cx, y - cy) / rmax
			a = int(255 * forca * max(0.0, (t - 0.42) / 0.58) ** 1.7)
			if a:
				p[x, y] = (3, 8, 6, a)
	return im


def fundo_regiao1():
	"""A vista da Regiao I para o ecra de seleccao. Camadas, de tras para a
	frente: ceu -> panorama da Arvore-Coracao -> o vale espelhado na agua ->
	nevoa -> silhuetas de arvore nas ombreiras -> vegetacao da frente em
	duas profundidades -> luz verde -> vinheta. Todas as pecas sao arte de
	producao ja' aprovada da Regiao I.

	Cada camada leva rampa de alfa nas pontas (`esbater`): coladas a direito,
	as arestas viam-se como riscos horizontais de lado a lado."""
	tela = degrade(ECRA, (10, 16, 32), (5, 11, 13))

	pan = carregar(os.path.join(R1, "backgrounds", "region1_panorama_heart_tree_x2.png"))
	pan = por_largura(pan, ECRA[0])
	topo = 70
	tela.alpha_composite(esbater(pan.copy(), 70, 130), (0, topo))

	# Abaixo do panorama e' so' escuro e nevoa. A primeira composicao punha
	# aqui o panorama espelhado a fazer de agua: lia-se como uma copia
	# esborratada e trazia mais uma aresta horizontal. A metade de baixo do
	# selector vai coberta pelo painel e pelas abas -- nao precisa de cenario.

	nevoa = por_largura(carregar(os.path.join(KIT, "atmosfera", "nevoa.png")), ECRA[0])
	n2 = nevoa.copy()
	n2.putalpha(n2.getchannel("A").point(lambda v: int(v * 0.5)))
	n2 = esbater(n2, n2.height // 2, n2.height // 2)
	tela.alpha_composite(n2, (0, topo + pan.height - n2.height // 2))
	n3 = nevoa.copy()
	n3.putalpha(n3.getchannel("A").point(lambda v: int(v * 0.34)))
	n3 = esbater(n3, n3.height // 2, n3.height // 2)
	tela.alpha_composite(n3, (0, ECRA[1] - n3.height - 150))

	# ombreiras: as arvores do kit, bem escuras, a fechar o quadro
	for nome, x, larg, k in (("fundo_arvores_par", -60, 540, 0.20),
			("fundo_arvore_a", ECRA[0] - 380, 440, 0.18),
			("fundo_arvore_b", ECRA[0] - 130, 320, 0.14)):
		t = por_largura(carregar(os.path.join(KIT, "fundo", nome + ".png")), larg)
		t = esbater_x(esbater(escurecer(t, k), 0, 80), 40, 40)
		tela.alpha_composite(t, (x, 40))

	# vegetacao da frente, duas passagens (longe mais clara, perto quase preta)
	veg = carregar(os.path.join(KIT, "fundo", "frente_vegetacao.png"))
	longe = por_largura(veg, int(ECRA[0] * 1.3))
	tela.alpha_composite(escurecer(longe.copy(), 0.30), (-140, ECRA[1] - longe.height - 84))
	perto = por_largura(veg, int(ECRA[0] * 2.0))
	tela.alpha_composite(escurecer(perto.copy(), 0.08), (-340, ECRA[1] - perto.height + 26))

	# a luz da regiao: verde de musgo por cima, mais forte em baixo (onde a
	# vegetacao esta') -- e' o que faz o ecra ler-se como FLORESTA a` vista
	luz = Image.new("RGBA", ECRA)
	lp = luz.load()
	for y in range(ECRA[1]):
		t = y / float(ECRA[1] - 1)
		a = int(30 + 52 * t ** 1.4)
		for x in range(ECRA[0]):
			lp[x, y] = (26, 70, 46, a)
	tela.alpha_composite(luz)
	# neblina de distancia na metade de baixo: alem de ser o que a floresta
	# faz a` noite, desmancha qualquer aresta que tenha sobrado das camadas
	baixo = tela.crop((0, ECRA[1] // 2, ECRA[0], ECRA[1]))
	baixo = baixo.filter(ImageFilter.GaussianBlur(1.8))
	baixo = esbater(baixo, 90)
	tela.alpha_composite(baixo, (0, ECRA[1] // 2))
	tela.alpha_composite(vinheta(ECRA))
	return tela.convert("RGBA")


def sha(p):
	h = hashlib.sha256()
	with open(p, "rb") as f:
		for b in iter(lambda: f.read(1 << 20), b""):
			h.update(b)
	return h.hexdigest()


def main(argv):
	os.makedirs(SAIDA, exist_ok=True)
	registo = {}

	fundo = fundo_regiao1()
	cam = os.path.join(SAIDA, "fundo_seletor.png")
	fundo.save(cam)
	registo["fundo_seletor"] = {"sha256": sha(cam), "dimensoes": list(fundo.size),
		"composto_de": [
			"assets/art/regions/region_01_forest/production/backgrounds/region1_panorama_heart_tree_x2.png",
			"assets/art/regions/region_01_forest/production/kit_9c/atmosfera/nevoa.png",
			"assets/art/regions/region_01_forest/production/kit_9c/fundo/frente_vegetacao.png",
			"assets/art/regions/region_01_forest/production/kit_9c/fundo/fundo_arvores_par.png",
			"assets/art/regions/region_01_forest/production/kit_9c/fundo/fundo_arvore_a.png",
			"assets/art/regions/region_01_forest/production/kit_9c/fundo/fundo_arvore_b.png"]}
	print("%-20s %s" % ("fundo_seletor", fundo.size))

	for nome in PECAS:
		src = os.path.join(UI, nome + ".png")
		if not os.path.exists(src):
			continue
		alvo = MAGENTA if nome in CORRUPCAO else VERDE
		# as abas ficam ainda mais contidas: sao cinco placas grandes lado a
		# lado e o texto vive POR CIMA delas
		fundo_de_texto = nome in ("aba_atual", "aba_bloqueada", "placa_selecionada")
		im = rodar_matiz(carregar(src), alvo,
			forca_sat=0.52 if fundo_de_texto else 0.70,
			luz=0.66 if fundo_de_texto else 0.86)
		cam = os.path.join(SAIDA, nome + ".png")
		im.save(cam)
		registo[nome] = {"sha256": sha(cam), "matiz": alvo,
			"origem": "assets/ui/frontend_9h/%s.png" % nome}
		print("%-20s matiz %.2f  %s" % (nome, alvo, im.size))

	# --- apresentacao NEUTRA (Regioes II-XX, sem autoridade visual) --------
	os.makedirs(NEUTRO_DIR, exist_ok=True)
	registo_n = {}
	for nome in ["fundo_seletor"] + PECAS:
		src = os.path.join(UI, nome + ".png")
		if not os.path.exists(src):
			continue
		im = dessaturar(carregar(src), luz=0.62 if nome == "fundo_seletor" else 0.82)
		cam = os.path.join(NEUTRO_DIR, nome + ".png")
		im.save(cam)
		registo_n[nome] = {"sha256": sha(cam), "origem": "assets/ui/frontend_9h/%s.png" % nome}
	print("%-20s %d pecas em aco frio" % ("neutro", len(registo_n)))
	with open(os.path.join(NEUTRO_DIR, "manifesto_tema_neutro.json"), "w",
			encoding="utf-8", newline=LF) as f:
		json.dump({
			"execucao": "9H.1",
			"o_que": "Apresentacao NEUTRA do selector, para as regioes sem "
				"autoridade visual aprovada (II-XX).",
			"como": "As pecas do frontend 9H dessaturadas para aco frio. Nao "
				"ha' identidade de regiao nenhuma aqui -- e' esse o ponto.",
			"estado": "REGION SELECTOR THEME AUTHORITY MISSING",
			"ficheiros": registo_n,
		}, f, indent=2, ensure_ascii=False)

	man = {
		"execucao": "9H.1",
		"regiao": 1,
		"nome": "FLORESTA CORROMPIDA",
		"o_que": "Pele do selector de niveis para a Regiao I.",
		"fundo": "Composicao de arte de producao APROVADA da Regiao I "
			"(panorama 9H + kit 9C). Nenhum cenario inventado.",
		"pecas": "As pecas do frontend 9H com a matiz do carmesim rodada "
			"para verde de musgo (0,30); o anel do guardiao e o cadeado "
			"ficam no magenta da corrupcao (0,84).",
		"regioes_sem_autoridade": "II-XX nao tem pele. O selector usa a "
			"apresentacao NEUTRA -- ver scripts/tema_regiao.gd. "
			"REGION SELECTOR THEME AUTHORITY MISSING.",
		"ficheiros": registo,
	}
	with open(os.path.join(SAIDA, "manifesto_tema_r01.json"), "w",
			encoding="utf-8", newline="\n") as f:
		json.dump(man, f, indent=2, ensure_ascii=False)
	print("manifesto:", os.path.relpath(os.path.join(SAIDA, "manifesto_tema_r01.json"), RAIZ))
	return 0


if __name__ == "__main__":
	raise SystemExit(main(sys.argv))
