#!/usr/bin/env python3
"""Execution 9H.1 -- MOVIMENTO DERIVADO das criaturas da Regiao I.

    python tools/animar_criaturas_9h1.py [id ...]

O PROBLEMA. A 9D/9E produziu UMA pose por estado a partir da autoridade
aprovada, e escreveu no manifesto que ciclos articulados "seriam poses novas
-- APPROVED DESIGN / PRODUCTION ASSET MISSING, nao se inventaram". A 9H pos
por cima uma camada procedimental (`DemonioBase._vida_no_anim`) que respira,
inclina e recua a IMAGEM INTEIRA. O Game Master leu o resultado pelo que ele
e': uma imagem parada a ser transformada. A 9H.1 autoriza expressamente
frames derivados com movimento anatomico segmentado.

O QUE ISTO FAZ. Corta cada criatura em segmentos (pernas, tronco, cabeca,
copa, tentaculos, nucleo) e move CADA UM com a sua propria fase. As pernas
sao detectadas automaticamente -- na faixa de baixo da silhueta, cada corrida
de colunas ligadas e' uma perna -- e por isso o mesmo codigo serve um goblin
de duas, um Ghorak de quatro e uma Rainha de oito.

O QUE SE PRESERVA. Anatomia, especie, traje, paleta. Nenhum pixel e'
desenhado: tudo sao translacoes de pixel inteiro, compressoes verticais e
rotacoes de faixas, a partir da pose aprovada. A pose original fica guardada
em `frames/_base_9h1.png` e e' SEMPRE dela que se deriva (correr a ferramenta
duas vezes da' o mesmo resultado).

ESTADOS PRODUZIDOS
  idle    8 frames  respiracao, oscilacao propria, brilho da corrupcao a pulsar
  run     8 frames  ciclo de pernas a serio (grupos alternados), corpo a saltar
  attack  7 frames  antecipacao -> golpe -> recuperacao (NAO existia)
  hit/dead            ficam como estavam (ja' tinham 3 e 6 frames proprios)

O boss tem duas fases com camadas proprias (ver `CORACAO`).
"""
from __future__ import annotations

import hashlib
import json
import math
import os
import shutil
import sys

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INIM = os.path.join(RAIZ, "assets/art/regions/region_01_forest/enemies/production")
BOSS = os.path.join(RAIZ, "assets/art/regions/region_01_forest/bosses/coracao_putrefacto/production")
MANIFESTO = os.path.join(INIM, "enemy_production_manifest.json")
PROVA = os.path.join(RAIZ, "work/production_art_gate/9h1/criaturas")


# ------------------------------------------------------------------ utilidades ---

def carregar(p):
	return Image.open(p).convert("RGBA")


def caixa(im):
	bb = im.getbbox()
	return bb if bb else (0, 0, im.width, im.height)


def mapa(im, f, faixa=None):
	"""Aplica `f(x, y) -> (dx, dy)` aos pixeis opacos (dentro de `faixa`,
	se dada). Tudo por pixel inteiro."""
	px = im.load()
	fora = Image.new("RGBA", im.size, (0, 0, 0, 0))
	fp = fora.load()
	y0, y1 = faixa if faixa else (0, im.height)
	for y in range(im.height):
		for x in range(im.width):
			c = px[x, y]
			if c[3] < 40:
				continue
			if y0 <= y < y1:
				dx, dy = f(x, y)
				nx, ny = x + dx, y + dy
			else:
				nx, ny = x, y
			if 0 <= nx < im.width and 0 <= ny < im.height:
				fp[nx, ny] = c
	return fora


def comprimir(im, k, base_y):
	"""Escala vertical com a linha `base_y` presa. k>0 encolhe, k<0 estica.

	Redimensiona a REGIAO (NEAREST) em vez de mapear linha a linha: a versao
	linha-a-linha deixava uma fila vazia sempre que esticava, e o que se via
	era uma COSTURA horizontal a atravessar o bicho a meio da respiracao."""
	if abs(k) < 1e-4:
		return im.copy()
	base_y = max(1, min(base_y, im.height - 1))
	topo = im.crop((0, 0, im.width, base_y))
	nova_alt = max(1, int(round(base_y * (1.0 - k))))
	topo = topo.resize((im.width, nova_alt), Image.NEAREST)
	fora = Image.new("RGBA", im.size, (0, 0, 0, 0))
	fora.paste(im.crop((0, base_y, im.width, im.height)), (0, base_y))
	fora.alpha_composite(topo, (0, base_y - nova_alt))
	return fora


def oscilar(im, y0, y1, dx, ondas=1.0, fase=0.0, ancora="baixo"):
	"""Onda horizontal dentro de uma faixa: 0 na ancora, `dx` na outra ponta,
	com `ondas` periodos pelo meio. E' o que mexe tentaculos, copas, mantos,
	caudas e raizes sem os arrancar do corpo."""
	alt = max(1, y1 - y0)

	def f(x, y):
		t = (y1 - y) / alt if ancora == "baixo" else (y - y0) / alt
		return int(round(dx * t * math.sin(math.pi * (ondas * t + fase)))), 0
	return mapa(im, f, (y0, y1))


def inclinar(im, dx, y0, y1):
	"""Cisalhamento simples: `dx` no topo da faixa, 0 na base."""
	alt = max(1, y1 - y0)
	return mapa(im, lambda x, y: (int(round(dx * (y1 - y) / alt)), 0), (y0, y1))


def mover_faixa(im, y0, y1, dx, dy):
	"""Move uma faixa com RAMPA: deslocacao inteira em `y0`, zero em `y1`.

	A versao sem rampa deslocava a faixa inteira em bloco e deixava uma LINHA
	VAZIA na fronteira (medido: a linha 138 do Ghorak ficava a zero sempre
	que a cabeca subia 1 px -- via-se um risco preto a atravessar o lombo)."""
	alt = max(1, y1 - y0)

	def f(x, y):
		t = (y1 - y) / alt
		return int(round(dx * t)), int(round(dy * t))
	return mapa(im, f, (y0, y1))


def grupos_de_pernas(im, y0, y1):
	"""Corridas de colunas ocupadas na faixa de baixo = pernas. Devolve
	[(x_ini, x_fim), ...] da esquerda para a direita."""
	px = im.load()
	col = [any(px[x, y][3] >= 40 for y in range(y0, y1)) for x in range(im.width)]
	fora = []
	x = 0
	while x < im.width:
		if col[x]:
			a = x
			while x < im.width and col[x]:
				x += 1
			if x - a >= 2:
				fora.append((a, x - 1))
		else:
			x += 1
	return fora


def mexer_pernas(im, y0, y1, grupos, passos):
	"""`passos` = [(dx, dy)] por grupo. A deslocacao tem rampa de 0 na anca
	ate' ao maximo nos pes -- sem isso a perna arrancava-se do corpo."""
	alt = max(1, y1 - y0)
	faixas = {}
	for (a, b), (dx, dy) in zip(grupos, passos):
		for x in range(a, b + 1):
			faixas[x] = (dx, dy)

	def f(x, y):
		if x not in faixas:
			return 0, 0
		dx, dy = faixas[x]
		t = (y - y0) / alt
		return int(round(dx * t)), int(round(dy * t))
	return mapa(im, f, (y0, y1))


def pulsar_corrupcao(im, k):
	"""A corrupcao magenta acende e apaga. Todas as criaturas da Regiao I
	tem este brilho, e e' o sinal de vida mais barato e mais legivel que
	existe -- nao mexe uma unica silhueta."""
	if abs(k) < 1e-3:
		return im.copy()
	px = im.load()
	fora = im.copy()
	fp = fora.load()
	for y in range(im.height):
		for x in range(im.width):
			r, g, b, a = px[x, y]
			if a < 40:
				continue
			mx, mn = max(r, g, b), min(r, g, b)
			if mx < 60 or mx == mn:
				continue
			# magenta/violeta: vermelho e azul altos, verde em baixo
			if not (r > g and b > g and (r + b) > g * 2.2):
				continue
			f = 1.0 + k
			fp[x, y] = (min(255, int(r * f)), min(255, int(g * (1.0 + k * 0.45))),
				min(255, int(b * f)), a)
	return fora


def alfa_binario(im):
	px = im.load()
	for y in range(im.height):
		for x in range(im.width):
			a = px[x, y][3]
			if 0 < a < 255:
				px[x, y] = px[x, y][:3] + (255 if a >= 96 else 0,)
	return im


# --------------------------------------------------------------------- especies ---
#
# `tipo` escolhe a coreografia; as fraccoes sao da ALTURA DA CAIXA da
# criatura, medidas nos perfis do proprio sprite (ver o relatorio).
ESPECIES = {
	"goblin":           {"tipo": "bipede", "pernas": 0.64, "cabeca": 0.34, "amp": 1.0},
	"clone_morvanna":   {"tipo": "bipede", "pernas": 0.70, "cabeca": 0.30, "amp": 0.9,
	                     "manto": True},
	"morvanna":         {"tipo": "bipede", "pernas": 0.78, "cabeca": 0.26, "amp": 1.0,
	                     "manto": True, "guardiao": True},
	"ghorak":           {"tipo": "quadrupede", "pernas": 0.58, "cabeca": 0.34, "amp": 1.2,
	                     "guardiao": True},
	"rainha_aracnidea": {"tipo": "aracnideo", "pernas": 0.36, "amp": 1.2, "guardiao": True},
	"cria_rainha":      {"tipo": "aracnideo", "pernas": 0.40, "amp": 1.0},
	"besouro":          {"tipo": "aracnideo", "pernas": 0.52, "amp": 1.0},
	"gosma":            {"tipo": "blob", "amp": 1.3},
	"lodo":             {"tipo": "blob", "amp": 1.1},
	"mushroom":         {"tipo": "fungo", "copa": 0.55, "amp": 1.1},
	"entrevane":        {"tipo": "planta", "copa": 0.62, "amp": 1.2, "guardiao": True},
}

## As duas fases do Coracao vivem em pastas proprias, com nomes de estado
## proprios. A fase 2 leva quase o DOBRO da amplitude: e' o mesmo corpo, mas
## visivelmente mais agitado -- e' essa a diferenca que o Game Master pediu.
CORACAO = {"phase_1": {"amp": 1.0, "idle": "idle"},
	"phase_2": {"amp": 1.9, "idle": "idle_f2"}}

N_IDLE, N_RUN, N_ATK = 8, 8, 7


# ------------------------------------------------------------------ coreografia ---

def coreografar(base, cfg, estado, i, n):
	"""Devolve o frame `i` de `n` do `estado`, derivado de `base`."""
	x0, y0, x1, y1 = caixa(base)
	alt = max(1, y1 - y0)
	amp = cfg.get("amp", 1.0)
	tipo = cfg["tipo"]
	t = i / n                       # 0..1 dentro do ciclo
	im = base.copy()

	def linha(frac):
		return int(round(y0 + alt * frac))

	# --- fases por estado -------------------------------------------------
	if estado == "idle":
		s = math.sin(2 * math.pi * t)
		s2 = math.sin(4 * math.pi * t)
		respirar = 0.035 * amp * s
		brilho = 0.22 * amp * math.sin(2 * math.pi * t + 0.9)
		balanco = 1.2 * amp * s
		empinar = 0.0
		avanco = 0.0
		perna_fase = None
	elif estado == "run":
		s = math.sin(2 * math.pi * t)
		s2 = math.sin(4 * math.pi * t)
		respirar = 0.02 * amp * s2
		brilho = 0.16 * amp * s2
		balanco = 1.8 * amp * s
		empinar = 0.0
		avanco = 1.0 + 0.9 * amp * s
		perna_fase = t
	else:   # attack: 2 de antecipacao, 2 de golpe, 3 de recuperacao
		fase = i / max(1, n - 1)
		if i <= 1:                       # armar
			k = (i + 1) / 2.0
			respirar = 0.07 * amp * k
			balanco = -3.0 * amp * k
			empinar = -13.0 * amp * k
			avanco = -2.0 * amp * k
			brilho = 0.30 * amp * k
		elif i <= 3:                     # bater
			k = (i - 1) / 2.0
			respirar = -0.05 * amp * k
			balanco = 4.5 * amp * k
			empinar = 16.0 * amp * k
			avanco = 4.0 * amp * k
			brilho = 0.55 * amp
		else:                            # recuperar
			k = 1.0 - (i - 3) / float(max(1, n - 4))
			respirar = -0.02 * amp * k
			balanco = 2.4 * amp * k
			empinar = 8.0 * amp * k
			avanco = 2.2 * amp * k
			brilho = 0.22 * amp * k
		s = math.sin(math.pi * fase)
		s2 = s
		perna_fase = None

	# --- aplicacao por anatomia -------------------------------------------
	if tipo in ("bipede", "quadrupede", "aracnideo"):
		yp = linha(cfg["pernas"])
		grupos = grupos_de_pernas(im, yp, y1 + 1)
		if grupos:
			if perna_fase is not None:
				passos = []
				for k, _ in enumerate(grupos):
					f = perna_fase + k / float(len(grupos))
					passos.append((int(round(3.2 * amp * math.cos(2 * math.pi * f))),
						-max(0, int(round(2.6 * amp * math.sin(2 * math.pi * f))))))
			else:
				passos = [(int(round(avanco * (1 if k % 2 else -0.6))),
					-max(0, int(round(1.4 * amp * math.sin(math.pi * t + k)))))
					for k, _ in enumerate(grupos)]
			im = mexer_pernas(im, yp, y1 + 1, grupos, passos)
		# tronco: respira e balanca
		im = comprimir(im, respirar, yp)
		im = inclinar(im, balanco, y0, yp)
		if tipo == "quadrupede" and abs(empinar) > 0.3:
			# a cabecada e' do TERCO DA FRENTE (em x), nao de uma fatia
			# horizontal: cortar o lobo a meio da altura e rodar a metade de
			# cima partia-o em duas -- via-se a emenda.
			xf = x0 + (x1 - x0) * 2 // 3
			larg = max(1, x1 - xf)
			im = mapa(im, lambda x, y: (
				(int(round(empinar * 0.34 * (x - xf) / larg)),
					int(round(empinar * 0.16 * (x - xf) / larg)))
				if x >= xf else (0, 0)), (y0, yp))
		elif tipo == "aracnideo" and abs(empinar) > 0.3:
			# empinar: o corpo inclina-se sobre as pernas de tras. Outra vez
			# por cisalhamento -- continuo na fronteira, e por isso sem corte.
			im = inclinar(im, empinar * 0.85, y0, yp)
		elif "cabeca" in cfg:
			yc = linha(cfg["cabeca"])
			# horizontal com rampa (nao abre buracos) e vertical por
			# COMPRESSAO da regiao acima da linha do pescoco. Uma rampa
			# vertical em pixeis inteiros deixa uma fila vazia em cada
			# degrau -- foi assim que o clone da Morvanna ficou com um risco
			# transparente na linha 47 em todos os frames com a cabeca a
			# subir.
			im = mover_faixa(im, y0, yc, int(round(empinar * 0.32 + balanco * 0.4)), 0)
			sobe = 0.8 * amp * s
			if abs(sobe) > 0.35 and yc > 2:
				im = comprimir(im, -sobe / float(yc), yc)
		if cfg.get("manto"):
			im = oscilar(im, linha(0.45), y1 + 1, 2.0 * amp * s, 1.2, t)
	elif tipo == "blob":
		# a gosma nao tem esqueleto: e' toda squash & stretch, com uma onda
		# a subir pelo corpo
		im = comprimir(im, respirar * 2.4, y1)
		im = oscilar(im, y0, y1 + 1, 2.6 * amp * s, 1.6, t)
		im = inclinar(im, balanco * 0.8 + avanco, y0, y1 + 1)
		if abs(empinar) > 0.3:
			im = comprimir(im, -0.06 * amp * (empinar / 16.0), y1)
	elif tipo == "fungo":
		yc = linha(cfg["copa"])
		im = comprimir(im, respirar * 1.6, y1)
		im = oscilar(im, y0, yc, 2.2 * amp * s, 0.9, t)
		if abs(empinar) > 0.3:
			im = inclinar(im, -empinar * 0.42, y0, yc)
		sobe = 1.2 * amp * s
		if abs(sobe) > 0.35 and yc > 2:
			im = comprimir(im, -sobe / float(yc), yc)
	elif tipo == "planta":
		yc = linha(cfg["copa"])
		im = oscilar(im, y0, yc, 3.0 * amp * s, 1.8, t)
		im = comprimir(im, respirar * 0.8, y1)
		if abs(empinar) > 0.3:
			# o golpe e' uma raiz a chicotear: so' a metade da frente
			im = mapa(im, lambda x, y: (
				int(round(empinar * 0.30 * (yc - y) / max(1, yc - y0)))
				if x > (x0 + x1) // 2 else 0, 0), (y0, yc))
	elif tipo == "nucleo":
		# tentaculos em onda, nucleo a bater
		im = oscilar(im, y0, y1 + 1, 3.4 * amp * s, 2.4, t)
		im = oscilar(im, y0, linha(0.55), 2.2 * amp * s2, 1.3, t + 0.35)
		im = comprimir(im, respirar * 1.4, y1)
		if abs(empinar) > 0.3:
			im = inclinar(im, empinar * 0.18, y0, y1 + 1)

	im = pulsar_corrupcao(im, brilho)
	return alfa_binario(im)


# ---------------------------------------------------------------------- pipeline ---

def sha(p):
	h = hashlib.sha256()
	with open(p, "rb") as f:
		for b in iter(lambda: f.read(1 << 20), b""):
			h.update(b)
	return h.hexdigest()


def base_de(pasta, nome_pose):
	"""A pose de partida. Guarda-se uma copia intocada na primeira passagem,
	e e' sempre dela que se deriva -- correr a ferramenta duas vezes tem de
	dar exactamente o mesmo resultado."""
	guardado = os.path.join(pasta, "_base_9h1.png")
	if not os.path.exists(guardado):
		shutil.copyfile(os.path.join(pasta, nome_pose + ".png"), guardado)
	return carregar(guardado)


def produzir(pasta, prefixo, cfg, estados, registo):
	base = base_de(pasta, prefixo + "_01")
	for estado, n in estados:
		nome_fich = estado if prefixo == "idle" else estado
		frames = []
		for i in range(n):
			im = coreografar(base, cfg, estado.replace("_f2", ""), i, n)
			f = "%s_%02d.png" % (estado, i + 1)
			cam = os.path.join(pasta, f)
			im.save(cam)
			frames.append({"ficheiro": os.path.relpath(cam, INIM).replace(os.sep, "/")
				if cam.startswith(INIM) else "res://" + os.path.relpath(cam, RAIZ).replace(os.sep, "/"),
				"sha256": sha(cam), "dimensoes": list(im.size)})
		registo[estado] = frames
	return base


def main(argv):
	with open(MANIFESTO, encoding="utf-8") as f:
		man = json.load(f)
	pedidos = [a for a in argv[1:] if not a.startswith("-")]
	os.makedirs(PROVA, exist_ok=True)
	previas = []

	for nome, cfg in ESPECIES.items():
		if pedidos and nome not in pedidos:
			continue
		pasta = os.path.join(INIM, nome, "frames")
		registo = {}
		base = produzir(pasta, "idle", cfg, [("idle", N_IDLE), ("run", N_RUN),
			("attack", N_ATK)], registo)
		e = man["inimigos"][nome]["animacoes"]
		for estado, fps, ciclo in (("idle", 7.0, True), ("run", 11.0, True),
				("attack", 14.0, False)):
			e[estado] = {"fps": fps, "ciclo": ciclo, "frames": registo[estado],
				"origem": "DERIVED_9H1"}
		man["inimigos"][nome]["animacao_9h1"] = {
			"tipo": cfg["tipo"],
			"ferramenta": "tools/animar_criaturas_9h1.py",
			"o_que": "Movimento anatomico segmentado derivado da pose aprovada.",
		}
		previas.append((nome, base, [carregar(os.path.join(pasta, "attack_%02d.png" % (i + 1)))
			for i in range(N_ATK)]))
		print("%-18s %-11s idle %d  run %d  attack %d" % (nome, cfg["tipo"],
			N_IDLE, N_RUN, N_ATK))

	# --- o Coracao Putrefacto, por fase -----------------------------------
	if not pedidos or "coracao_putrefacto" in pedidos:
		e = man["inimigos"]["coracao_putrefacto"]["animacoes"]
		for fase, cfgf in CORACAO.items():
			pasta = os.path.join(BOSS, fase)
			idle_nome = cfgf["idle"]
			cfg = {"tipo": "nucleo", "amp": cfgf["amp"]}
			registo = {}
			base = base_de(pasta, idle_nome + "_01")
			for estado, n in ((idle_nome, N_IDLE), (idle_nome.replace("idle", "attack"), N_ATK)):
				frames = []
				for i in range(n):
					im = coreografar(base, cfg, "idle" if estado.startswith("idle") else "attack", i, n)
					cam = os.path.join(pasta, "%s_%02d.png" % (estado, i + 1))
					im.save(cam)
					frames.append({"ficheiro": "res://" + os.path.relpath(cam, RAIZ).replace(os.sep, "/"),
						"sha256": sha(cam), "dimensoes": list(im.size)})
				e[estado] = {"fps": 7.0 if estado.startswith("idle") else 12.0,
					"ciclo": estado.startswith("idle"), "frames": frames,
					"origem": "DERIVED_9H1"}
			previas.append(("coracao_" + fase, base,
				[carregar(os.path.join(pasta, "%s_%02d.png" % (idle_nome, i + 1)))
					for i in range(N_IDLE)]))
			print("%-18s %-11s idle %d  attack %d  (amp %.1f)" % (
				"coracao " + fase, "nucleo", N_IDLE, N_ATK, cfgf["amp"]))

	man["execucao_9h1"] = {
		"o_que": "Movimento anatomico derivado: pernas por grupos detectados, "
			"tronco a respirar, cabeca/copa/tentaculos com fase propria, "
			"brilho da corrupcao a pulsar, e um estado ATTACK que nao existia.",
		"autorizacao": "GAME MASTER 9H.1 - DERIVED ANIMATION FRAMES / SEGMENTED "
			"ANATOMICAL MOTION",
		"ferramenta": "tools/animar_criaturas_9h1.py",
		"pose_de_partida": "frames/_base_9h1.png (copia intocada da pose 9D/9E)",
	}
	with open(MANIFESTO, "w", encoding="utf-8", newline="\n") as f:
		json.dump(man, f, indent=2, ensure_ascii=False)

	# folha de prova: base + tira, uma linha por criatura
	if previas:
		cel_w = max(p[1].width for p in previas)
		cel_h = max(p[1].height for p in previas)
		cols = 1 + max(len(p[2]) for p in previas)
		folha = Image.new("RGBA", (cel_w * cols, cel_h * len(previas)), (16, 14, 20, 255))
		for r, (nome, base, tira) in enumerate(previas):
			folha.alpha_composite(base, (0, r * cel_h))
			for i, fr in enumerate(tira):
				folha.alpha_composite(fr, ((i + 1) * cel_w, r * cel_h))
		cam = os.path.join(PROVA, "criaturas_9h1_tiras.png")
		folha.convert("RGB").save(cam)
		print("folha:", os.path.relpath(cam, RAIZ))
	print("manifesto:", os.path.relpath(MANIFESTO, RAIZ))
	return 0


if __name__ == "__main__":
	raise SystemExit(main(sys.argv))
