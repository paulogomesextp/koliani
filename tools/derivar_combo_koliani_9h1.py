#!/usr/bin/env python3
"""Execution 9H.1 -- POSES DE COMBATE DERIVADAS da Koliani (golpes 2/3/4).

    python tools/derivar_combo_koliani_9h1.py [--folha]

O PROBLEMA QUE ISTO RESOLVE. Ate' aqui os quatro golpes do combo saiam dos
MESMOS seis frames golden do `attack_basic`, so' com velocidades e arcos de
VFX diferentes. O Game Master leu isso como insuficiente e tem razao: com os
efeitos desligados, os tres golpes eram a mesma animacao repetida. A 9H.1
autoriza explicitamente POSES DE CORPO DERIVADAS.

O QUE SE PRESERVA (identidade imutavel): cara, cabelo, fato, proporcoes,
Shadowblade e o estilo do Golden Set. Nao ha' um unico pixel desenhado a`
mao: cada frame novo e' um frame golden com operacoes de pixel inteiro.

O METODO, em tres partes
------------------------
1. SEPARAR. A Shadowblade e' o unico elemento magenta saturado da figura
   (matiz 0,78-0,95, S>=0,30, L>=0,22). A mascara sai limpa nos seis frames
   -- 28 a 47 pixeis, a lamina inteira e nada do corpo. Fica-se com duas
   camadas: LAMINA e CORPO.

2. REPOR O CORPO. Sobre a camada do corpo correm quatro operacoes, todas
   por pixel inteiro e todas reversiveis:
     inclinar  cisalha as linhas acima da anca -> o tronco pesa para a
               frente (ataque) ou recua (antecipacao);
     passada   abaixo da anca, o que esta' a` frente do eixo da anca avanca
               e o que esta' atras recua, com rampa da anca ate' aos pes ->
               a posicao das pernas muda de verdade (avanco/afastamento);
     agachar   comprime na vertical com os pes presos a` linha de base ->
               a antecipacao do remate;
     espelhar  vira a figura sobre o pivot -> no rodopio veem-se as COSTAS,
               que nenhum outro golpe mostra.

3. REPOR A LAMINA. A lamina e' rodada em torno do PUNHO (a ponta da mascara
   mais perto do centro do corpo) para um angulo ABSOLUTO por frame. E' isto
   que da' a cada golpe uma trajectoria de espada propria e nao um arco de
   VFX diferente por cima da mesma pose. Depois da rotacao: alfa a 0/255,
   cores presas a` paleta da lamina original (nenhuma cor nova entra no
   sprite) e um fecho morfologico de 1 pixel para a diagonal nao partir.

AS QUATRO LEITURAS
------------------
  1 CORTE DESCENDENTE  (attack_basic, intocado -- a autoridade aprovada)
  2 REVES ASCENDENTE   lamina de baixo-atras ate' ao alto; tronco desenrola
  3 RODOPIO            a figura roda; frames 3-4 sao as COSTAS
  4 REMATE             agacha, carrega por cima da cabeca, crava para baixo
                       com avanco fundo e recuperacao longa

Saida: assets/sprites/koliani_golden_set/frames/attack_{2,3,4}/ com
manifest.json cada, entradas no production_manifest.json, e a folha de prova
em work/production_art_gate/9h1/combo/.
"""
from __future__ import annotations

import hashlib
import json
import math
import os
import sys

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GS = os.path.join(RAIZ, "assets", "sprites", "koliani_golden_set")
FRAMES = os.path.join(GS, "frames")
PROVA = os.path.join(RAIZ, "work", "production_art_gate", "9h1", "combo")

CANVAS = 128
BASE = 103          # ultima linha opaca (contrato 9B.1)
PIVOT = (64, 104)
AUTORIDADE = "work/production_art_gate/9b1_game_master_approved/koliani_golden_set_approved.png"
AUTORIDADE_SHA = "0b067780d316d1fcb288c2a3d944cd758a212f8d696c1818ae6ac0e4db0c60c4"

# Marcos anatomicos, medidos nas linhas dos frames golden (ver o cabecalho
# do relatorio): ombro 58, cintura 74, anca 80, pes 103.
Y_TOPO = 48
Y_ANCA = 80


# ------------------------------------------------------------ segmentacao ---

def _hls(r, g, b):
	mx, mn = max(r, g, b) / 255.0, min(r, g, b) / 255.0
	l = (mx + mn) / 2.0
	if mx == mn:
		return 0.0, l, 0.0
	d = mx - mn
	s = d / (2.0 - mx - mn) if l > 0.5 else d / (mx + mn)
	R, G, B = r / 255.0, g / 255.0, b / 255.0
	if mx == R:
		h = ((G - B) / d) % 6.0
	elif mx == G:
		h = (B - R) / d + 2.0
	else:
		h = (R - G) / d + 4.0
	return h / 6.0, l, s


def separar(im):
	"""(lamina, corpo) -- duas imagens 128x128 com alfa 0/255."""
	px = im.load()
	lam = Image.new("RGBA", im.size, (0, 0, 0, 0))
	cor = Image.new("RGBA", im.size, (0, 0, 0, 0))
	lp, cp = lam.load(), cor.load()
	for y in range(im.height):
		for x in range(im.width):
			r, g, b, a = px[x, y]
			if a < 40:
				continue
			h, l, s = _hls(r, g, b)
			if 0.78 <= h <= 0.95 and s >= 0.30 and l >= 0.22:
				lp[x, y] = (r, g, b, 255)
			else:
				cp[x, y] = (r, g, b, 255)
	limpa = maior_componente(lam)
	lp2, kp = limpa.load(), lam.load()
	for y in range(im.height):
		for x in range(im.width):
			if kp[x, y][3] >= 128 and lp2[x, y][3] < 128:
				cp[x, y] = kp[x, y]      # brilho solto: pertence ao corpo
	# o CONTORNO da lamina (um anel de 1 px, matiz 0,70-0,91 e pouca
	# saturacao) falha o teste do nucleo. Deixado no corpo, o cisalhamento
	# do tronco levava-o para outro sitio e via-se uma segunda espada, a
	# tracejado, ao lado da verdadeira. A capa fica de fora (matiz ~0,97).
	nucleo = pixeis(limpa)
	for (x, y) in nucleo:
		for dy in (-1, 0, 1):
			for dx in (-1, 0, 1):
				nx, ny = x + dx, y + dy
				if not (0 <= nx < im.width and 0 <= ny < im.height):
					continue
				if lp2[nx, ny][3] >= 128 or cp[nx, ny][3] < 128:
					continue
				r, g, b, _ = cp[nx, ny]
				h, l, sa = _hls(r, g, b)
				if 0.70 <= h <= 0.91 and sa >= 0.10:
					lp2[nx, ny] = (r, g, b, 255)
					cp[nx, ny] = (0, 0, 0, 0)
	return limpa, cor


def maior_componente(im):
	"""So' a maior mancha ligada. A mascara de matiz apanha, num dos frames,
	um brilho magenta solto no lado errado do corpo (x=52 contra uma lamina
	em x=89..117); sem isto o punho era detectado nesse brilho e a espada
	saia do frame."""
	px = im.load()
	w, h = im.size
	visto = [[False] * w for _ in range(h)]
	melhor = []
	for y0 in range(h):
		for x0 in range(w):
			if visto[y0][x0] or px[x0, y0][3] < 128:
				continue
			pilha = [(x0, y0)]
			visto[y0][x0] = True
			grupo = []
			while pilha:
				x, y = pilha.pop()
				grupo.append((x, y))
				for dy in (-1, 0, 1):
					for dx in (-1, 0, 1):
						nx, ny = x + dx, y + dy
						if (0 <= nx < w and 0 <= ny < h and not visto[ny][nx]
								and px[nx, ny][3] >= 128):
							visto[ny][nx] = True
							pilha.append((nx, ny))
			if len(grupo) > len(melhor):
				melhor = grupo
	fora = Image.new("RGBA", im.size, (0, 0, 0, 0))
	fp = fora.load()
	for x, y in melhor:
		fp[x, y] = px[x, y]
	return fora


def pixeis(im):
	px = im.load()
	return [(x, y) for y in range(im.height) for x in range(im.width)
		if px[x, y][3] >= 128]


def centro(pts):
	if not pts:
		return (PIVOT[0], 70.0)
	return (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts))


def punho_e_angulo(lam, cor):
	"""Punho = ponta da lamina mais perto do centro do corpo; angulo =
	direccao punho->ponta, em graus (0 = para a direita, +90 = para cima)."""
	pl = pixeis(lam)
	if not pl:
		return (86, 74), 0.0
	# centro do TRONCO (linhas do ombro a` anca), nao da figura inteira: a
	# capa vermelha arrasta o centroide ~15 px para tras e o "punho" ia
	# parar ao meio da lamina em vez do cabo
	tronco = [p for p in pixeis(cor) if 56 <= p[1] <= Y_ANCA]
	cc = centro(tronco or pixeis(cor))
	dist = [((p[0] - cc[0]) ** 2 + (p[1] - cc[1]) ** 2, p) for p in pl]
	dist.sort()
	punho = dist[0][1]
	ponta = dist[-1][1]
	dx = ponta[0] - punho[0]
	dy = punho[1] - ponta[1]       # y cresce para baixo
	return punho, math.degrees(math.atan2(dy, dx))


# ------------------------------------------------- operacoes de pixel inteiro ---

def _mapa(im, f):
	"""Aplica `f(x, y) -> (x, y)` a cada pixel opaco. Escreve por ordem de
	cima para baixo (o que vem de baixo fica por cima, como no desenho)."""
	px = im.load()
	fora = Image.new("RGBA", im.size, (0, 0, 0, 0))
	fp = fora.load()
	for y in range(im.height):
		for x in range(im.width):
			if px[x, y][3] < 128:
				continue
			nx, ny = f(x, y)
			if 0 <= nx < im.width and 0 <= ny < im.height:
				fp[nx, ny] = px[x, y]
	return fora


def op_inclinar(k, y_ref=Y_ANCA):
	"""Cisalha o tronco: k>0 inclina para a frente (direita)."""
	def f(x, y):
		if y >= y_ref:
			return x, y
		t = (y_ref - y) / float(y_ref - Y_TOPO)
		return x + int(round(k * 14.0 * t)), y
	return f


def op_passada(d, x_div=None):
	"""Abaixo da anca, a perna da frente avanca `d` e a de tras recua 0,7d,
	com rampa ate' aos pes. Isto e' uma passada/avanco a serio, nao um
	arrastar da figura inteira."""
	def f(x, y):
		if y <= Y_ANCA:
			return x, y
		t = (y - Y_ANCA) / float(BASE - Y_ANCA)
		if x >= x_div:
			return x + int(round(d * t)), y
		return x - int(round(d * 0.7 * t)), y
	return f


def op_agachar(k):
	"""Comprime na vertical com os pes presos a` linha de base."""
	def f(x, y):
		return x, BASE - int(round((BASE - y) * (1.0 - k)))
	return f


def op_deslocar(dx, dy):
	return lambda x, y: (x + dx, y + dy)


def espelhar(im):
	"""Vira sobre a coluna do pivot (x' = 2*64 - x)."""
	vir = im.transpose(Image.FLIP_LEFT_RIGHT)
	fora = Image.new("RGBA", im.size, (0, 0, 0, 0))
	fora.paste(vir, (2 * PIVOT[0] - (im.width - 1), 0))
	return fora


def ponto_espelhado(p):
	return (2 * PIVOT[0] - p[0], p[1])


# ------------------------------------------------------------ rodar a lamina ---

def _paleta(im):
	px = im.load()
	cores = set()
	for y in range(im.height):
		for x in range(im.width):
			if px[x, y][3] >= 128:
				cores.add(px[x, y][:3])
	return sorted(cores)


def _mais_perto(c, paleta):
	melhor, dmin = paleta[0], 1e9
	for p in paleta:
		d = (c[0] - p[0]) ** 2 + (c[1] - p[1]) ** 2 + (c[2] - p[2]) ** 2
		if d < dmin:
			dmin, melhor = d, p
	return melhor


def _fechar(mascara):
	"""Costura buracos de 1 px sem ENGORDAR a lamina. Um dilatar+erodir
	classico engrossava a espada de uma linha fina para um risco gordo (viu-se
	na primeira passagem); aqui so' se enche um pixel vazio que tenha vizinhos
	opacos em LADOS OPOSTOS -- exactamente o buraco que uma diagonal rodada
	deixa, e nada mais.
	"""
	w, h = mascara.size
	mp = mascara.load()
	fora = mascara.copy()
	fp = fora.load()
	pares = [((-1, 0), (1, 0)), ((0, -1), (0, 1)),
		((-1, -1), (1, 1)), ((-1, 1), (1, -1))]
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			if mp[x, y]:
				continue
			for (ax, ay), (bx, by) in pares:
				if mp[x + ax, y + ay] and mp[x + bx, y + by]:
					fp[x, y] = 255
					break
	return fora


def rodar_lamina(lam, punho, graus, destino):
	"""Roda a lamina `graus` (delta) em torno de `punho` e poe o punho em
	`destino`. Devolve uma imagem 128x128."""
	if graus == 0.0 and punho == destino:
		return lam.copy()
	paleta = _paleta(lam)
	if not paleta:
		return lam.copy()
	L = 256
	tela = Image.new("RGBA", (L, L), (0, 0, 0, 0))
	tela.paste(lam, (L // 2 - punho[0], L // 2 - punho[1]))
	# rotate() do PIL roda no sentido anti-horario para angulos positivos e
	# a nossa convencao de angulo visual e' a mesma (y cresce para baixo,
	# por isso passa-se o angulo tal e qual)
	rod = tela.rotate(graus, resample=Image.BILINEAR, center=(L // 2, L // 2))
	rp = rod.load()
	masc = Image.new("L", (L, L), 0)
	mp = masc.load()
	for y in range(L):
		for x in range(L):
			if rp[x, y][3] >= 96:
				mp[x, y] = 255
	masc = _fechar(masc)
	mp = masc.load()
	limpa = Image.new("RGBA", (L, L), (0, 0, 0, 0))
	lp = limpa.load()
	for y in range(L):
		for x in range(L):
			if not mp[x, y]:
				continue
			c = rp[x, y]
			if c[3] < 8:
				# pixel nascido do fecho: herda a cor do vizinho mais opaco
				melhor = None
				for dy in (-1, 0, 1):
					for dx in (-1, 0, 1):
						nx, ny = x + dx, y + dy
						if 0 <= nx < L and 0 <= ny < L and rp[nx, ny][3] >= 96:
							if melhor is None or rp[nx, ny][3] > melhor[3]:
								melhor = rp[nx, ny]
				if melhor is None:
					continue
				c = melhor
			lp[x, y] = _mais_perto(c[:3], paleta) + (255,)
	fora = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
	fora.paste(limpa, (destino[0] - L // 2, destino[1] - L // 2))
	return fora


# ---------------------------------------------------------------- receitas ---

## Cada frame: (frame de origem, [operacoes de corpo], espelhar, DELTA do
## angulo da lamina em graus).
##
## O delta e' RELATIVO ao angulo nativo do frame de origem, e e' pequeno de
## proposito (|delta| <= 40 graus). A primeira passagem usava angulos
## absolutos e rodava a lamina ate' 160 graus: a espada ia parar a sitios
## onde o BRACO desenhado nao podia leva-la, e lia-se como uma lamina solta
## a flutuar. A trajectoria de cada golpe vem sobretudo da ESCOLHA do frame
## de origem -- os seis frames golden dao angulos nativos de -39, +24, +29,
## +33, +36 e +119 graus -- e o delta so' afina.
##
## Espelhar vira o corpo E a lamina: o angulo nativo passa a 180-ang. E' o
## que da' o meio do rodopio (as costas, com a espada a vir por cima do
## ombro esquerdo) sem desenhar um unico pixel novo.
RECEITAS = {
	"attack_2": {
		"leitura": "reves ascendente -- a lamina sobe de baixo-atras ate' ao alto",
		"fps": 30.0,
		"frames": [
			# antecipacao: peso todo atras, pes juntos, lamina em baixo
			("attack_basic_001", [("inclinar", -0.55), ("passada", -4)], False, -40.0),
			("attack_basic_001", [("inclinar", -0.28), ("passada", -2)], False, -12.0),
			# activa: o tronco desenrola e a lamina passa a horizontal
			("attack_basic_006", [("inclinar", 0.20), ("passada", 4)], False, -30.0),
			("attack_basic_005", [("inclinar", 0.52), ("passada", 9)], False, 0.0),
			# remate do golpe: figura esticada, lamina no alto
			("attack_basic_002", [("inclinar", 0.60), ("passada", 11)], False, 38.0),
			# recuperacao
			("attack_basic_002", [("inclinar", 0.30), ("passada", 5)], False, 20.0),
		],
	},
	"attack_3": {
		"leitura": "rodopio -- a figura da' a volta; nos frames 3 e 4 veem-se as costas",
		"fps": 20.0,
		"frames": [
			("attack_basic_001", [("inclinar", -0.45), ("passada", -2)], False, -20.0),
			("attack_basic_002", [("inclinar", -0.10), ("passada", 1)], False, 25.0),
			# COSTAS: espelhado, a lamina vem por cima do ombro
			("attack_basic_004", [("agachar", 0.04)], True, -18.0),
			("attack_basic_005", [("inclinar", 0.18)], True, -12.0),
			# volta a` frente e o corte sai na horizontal
			("attack_basic_006", [("inclinar", 0.56), ("passada", 10)], False, -30.0),
			("attack_basic_001", [("inclinar", 0.24), ("passada", 5)], False, 15.0),
		],
	},
	"attack_4": {
		"leitura": "remate -- agacha, arma por cima da cabeca e crava com avanco fundo",
		"fps": 23.076923,
		"frames": [
			# antecipacao longa: agacha e recua (2 frames -- e' o que separa
			# um remate de mais um golpe)
			("attack_basic_001", [("agachar", 0.10), ("inclinar", -0.60), ("passada", -5)], False, 22.0),
			("attack_basic_004", [("agachar", 0.16), ("inclinar", -0.70), ("passada", -7)], False, 30.0),
			# a espada no ponto mais alto, corpo a subir
			("attack_basic_004", [("inclinar", -0.08), ("passada", 2), ("deslocar", 0, -3)], False, -28.0),
			# crava: avanco fundo, tronco todo a` frente
			("attack_basic_005", [("inclinar", 0.72), ("passada", 14)], False, -38.0),
			# impacto: joelho fundo, lamina no chao
			("attack_basic_001", [("agachar", 0.14), ("inclinar", 0.80), ("passada", 17)], False, -30.0),
			# recuperacao longa
			("attack_basic_006", [("agachar", 0.07), ("inclinar", 0.46), ("passada", 11)], False, -34.0),
		],
	},
}


def aplicar(cor, punho, ops):
	"""Corre as operacoes no corpo e leva o punho pelo mesmo caminho."""
	p = (float(punho[0]), float(punho[1]))
	for nome, *arg in ops:
		if nome == "inclinar":
			f = op_inclinar(arg[0])
		elif nome == "passada":
			# o eixo da anca e' o centro horizontal das linhas da anca
			px = cor.load()
			xs = [x for x in range(CANVAS) for y in range(Y_ANCA - 2, Y_ANCA + 3)
				if px[x, y][3] >= 128]
			x_div = (min(xs) + max(xs)) // 2 if xs else PIVOT[0]
			f = op_passada(arg[0], x_div)
		elif nome == "agachar":
			f = op_agachar(arg[0])
		elif nome == "deslocar":
			f = op_deslocar(arg[0], arg[1])
		else:
			raise SystemExit("operacao desconhecida: " + nome)
		cor = _mapa(cor, f)
		p = f(int(round(p[0])), int(round(p[1])))
	return cor, (int(round(p[0])), int(round(p[1])))


def sha(caminho):
	h = hashlib.sha256()
	with open(caminho, "rb") as f:
		for b in iter(lambda: f.read(1 << 20), b""):
			h.update(b)
	return h.hexdigest()


def gerar(nome, receita):
	saida = os.path.join(FRAMES, nome)
	os.makedirs(saida, exist_ok=True)
	registo = []
	previa = []
	for i, (origem, ops, vira, ang) in enumerate(receita["frames"]):
		src = os.path.join(FRAMES, "attack_basic", origem + ".png")
		im = Image.open(src).convert("RGBA")
		lam, cor = separar(im)
		punho, ang0 = punho_e_angulo(lam, cor)
		cor, punho2 = aplicar(cor, punho, ops)
		if vira:
			cor = espelhar(cor)
			punho2 = ponto_espelhado(punho2)
			lam = espelhar(lam)
			punho = ponto_espelhado(punho)
			ang0 = 180.0 - ang0
		nova_lam = rodar_lamina(lam, punho, ang, punho2)
		ang_final = ang0 + ang
		frame = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
		frame.alpha_composite(cor)
		frame.alpha_composite(nova_lam)
		# contrato: alfa estritamente 0/255
		fp = frame.load()
		for y in range(CANVAS):
			for x in range(CANVAS):
				a = fp[x, y][3]
				if 0 < a < 255:
					fp[x, y] = fp[x, y][:3] + (255 if a >= 128 else 0,)
		ficheiro = "%s_%03d.png" % (nome, i + 1)
		cam = os.path.join(saida, ficheiro)
		frame.save(cam)
		registo.append({
			"ficheiro": ficheiro,
			"origem_golden": origem + ".png",
			"operacoes_corpo": [list(o) for o in ops],
			"espelhado": vira,
			"delta_lamina_graus": ang,
			"angulo_lamina_origem_graus": round(ang0, 1),
			"angulo_lamina_final_graus": round(ang_final, 1),
			"sha256": sha(cam),
		})
		previa.append(frame)
	man = {
		"schema_version": 2,
		"character": "Koliani",
		"animation": nome,
		"leitura": receita["leitura"],
		"frame_count": len(registo),
		"canvas_width": CANVAS,
		"canvas_height": CANVAS,
		"pivot_x": PIVOT[0],
		"pivot_y": PIVOT[1],
		"baseline_y": BASE,
		"asset_type": "BODY",
		"expected_alpha": True,
		"vfx_separate": True,
		"fps": receita["fps"],
		"derivacao": "Execution 9H.1 -- tools/derivar_combo_koliani_9h1.py. "
			"Poses de corpo derivadas de frames do Golden Set aprovado, por "
			"operacoes de pixel inteiro (cisalhamento do tronco, passada, "
			"compressao vertical, espelho) mais rotacao da Shadowblade em "
			"torno do punho. Nenhum pixel desenhado a mao; cara, cabelo, "
			"fato e proporcoes vem intactos da autoridade.",
		"autorizacao": "GAME MASTER 9H.1 - DERIVED BODY COMBAT POSES",
		"authority": [{"file": AUTORIDADE, "sha256": AUTORIDADE_SHA}],
		"visual_review_state": "DERIVED_9H1_PENDING_GAME_MASTER",
		"runtime_integration_state": "INTEGRATED_9H1",
		"frames": registo,
		"godot": {"scale": 1.0, "offset": [0, -18]},
	}
	with open(os.path.join(saida, "manifest.json"), "w", encoding="utf-8",
			newline="\n") as f:
		json.dump(man, f, indent=2, ensure_ascii=False)
	return previa, man


def folha(tiras):
	"""Prova de movimento: uma linha por golpe, os seis frames em sequencia,
	e a MESMA linha so' com o corpo (sem lamina) por baixo -- e' a pergunta
	do Game Master, 'le^-se sem VFX?'."""
	larg = CANVAS * 6
	linhas = len(tiras) * 2
	folha = Image.new("RGBA", (larg, CANVAS * linhas), (16, 14, 20, 255))
	for r, (nome, frames) in enumerate(tiras):
		for i, fr in enumerate(frames):
			folha.alpha_composite(fr, (i * CANVAS, (r * 2) * CANVAS))
			_, corpo = separar(fr)
			folha.alpha_composite(corpo, (i * CANVAS, (r * 2 + 1) * CANVAS))
	folha = folha.resize((folha.width * 2, folha.height * 2), Image.NEAREST)
	os.makedirs(PROVA, exist_ok=True)
	cam = os.path.join(PROVA, "combo_9h1_tiras.png")
	folha.convert("RGB").save(cam)
	return cam


def main(argv):
	base = []
	for i in range(6):
		base.append(Image.open(os.path.join(
			FRAMES, "attack_basic", "attack_basic_%03d.png" % (i + 1))).convert("RGBA"))
	tiras = [("attack_1 (autoridade)", base)]
	mans = {}
	for nome in ("attack_2", "attack_3", "attack_4"):
		previa, man = gerar(nome, RECEITAS[nome])
		tiras.append((nome, previa))
		mans[nome] = man
		print("%-10s %d frames  %s" % (nome, len(previa), RECEITAS[nome]["leitura"]))
	cam = folha(tiras)
	print("folha:", os.path.relpath(cam, RAIZ))

	# production_manifest.json do Golden Set
	pm = os.path.join(GS, "production_manifest.json")
	with open(pm, encoding="utf-8") as f:
		d = json.load(f)
	alvo = d.get("animations", d.get("animacoes"))
	chave = "animations" if "animations" in d else "animacoes"
	if not isinstance(alvo, dict):
		alvo = {}
	for nome, man in mans.items():
		alvo[nome] = {
			"frame_count": man["frame_count"],
			"fps": man["fps"],
			"loop": False,
			"source": "DERIVED_9H1",
			"leitura": man["leitura"],
			"visual_review_state": man["visual_review_state"],
			"runtime_integration_state": man["runtime_integration_state"],
			"manifest": "frames/%s/manifest.json" % nome,
		}
	d[chave] = alvo
	d["execution_9h1"] = {
		"o_que": "Golpes 2/3/4 do combo com poses de corpo proprias.",
		"ferramenta": "tools/derivar_combo_koliani_9h1.py",
		"autorizacao": "GAME MASTER 9H.1 - DERIVED BODY COMBAT POSES",
	}
	with open(pm, "w", encoding="utf-8", newline="\n") as f:
		json.dump(d, f, indent=2, ensure_ascii=False)
	print("manifesto:", os.path.relpath(pm, RAIZ))
	return 0


if __name__ == "__main__":
	raise SystemExit(main(sys.argv))
