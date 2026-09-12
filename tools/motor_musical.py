#!/usr/bin/env python3
"""Motor de sintese musical -- Python puro, sem numpy e sem samples de fora.

Nasceu na Execution 9H.1 para compor a trilha de producao da Koliani. E' um
sintetizador pequeno mas honesto: osciladores por wavetable, corda pincada
por Karplus-Strong, filtro passa-baixo ressonante de 2 polos, envelopes ADSR
e uma reverberacao de Schroeder. Tudo o que sai daqui e' ORIGINAL e do
projecto -- nao ha' uma unica amostra de terceiros.

Porque wavetable e nao `math.sin` por amostra: uma faixa de 64 s a 32 kHz
sao 2 milhoes de frames; com tres vozes por nota e ~400 notas, `math.sin`
punha cada faixa em minutos. A tabela reduz a conta a um indice, uma
interpolacao e uma multiplicacao.

Unidades: tudo em float -1..1, mono por voz; o `Mistura` e' que espalha em
estereo. A escrita final e' WAV 16-bit estereo.
"""
from __future__ import annotations

import array
import math
import random
import struct
import wave

TAXA = 32000          # Hz. Chega para esta paleta (nada vive acima de 12 kHz)
TAM_TABELA = 2048


# ---------------------------------------------------------------- tabelas ---

def _tabela(harmonicos) -> array.array:
	"""Wavetable de um ciclo a partir de (numero_do_harmonico, amplitude)."""
	t = array.array("d", [0.0]) * TAM_TABELA
	for n, amp in harmonicos:
		if amp == 0.0:
			continue
		w = 2.0 * math.pi * n / TAM_TABELA
		for i in range(TAM_TABELA):
			t[i] += amp * math.sin(w * i)
	pico = max(abs(v) for v in t) or 1.0
	for i in range(TAM_TABELA):
		t[i] /= pico
	return t


def _serra(n=28):
	return [(k, 1.0 / k) for k in range(1, n + 1)]


def _quadrada(n=21):
	return [(k, 1.0 / k) for k in range(1, n + 1, 2)]


def _triangulo(n=15):
	return [(k, (1.0 / (k * k)) * (1 if (k // 2) % 2 == 0 else -1))
		for k in range(1, n + 1, 2)]


def _formantes(picos, n=40):
	"""Harmonicos pesados por picos de formante -- e' o que faz um coro soar
	a voz e nao a serra. `picos` = [(hz, largura, ganho), ...]."""
	fora = []
	f0 = 180.0   # frequencia de referencia para desenhar os formantes
	for k in range(1, n + 1):
		hz = f0 * k
		a = 0.06 / k
		for pico, larg, g in picos:
			a += g * math.exp(-((hz - pico) ** 2) / (2.0 * larg * larg)) / math.sqrt(k)
		fora.append((k, a))
	return fora


TAB = {
	"sine": _tabela([(1, 1.0)]),
	"saw": _tabela(_serra()),
	"square": _tabela(_quadrada()),
	"tri": _tabela(_triangulo()),
	# orgao de igreja: fundamental + oitava + quinta + oitava dupla
	"organ": _tabela([(1, 1.0), (2, 0.55), (3, 0.34), (4, 0.26), (6, 0.12), (8, 0.09)]),
	# "ah" de coro: formantes graves largos
	"choir": _tabela(_formantes([(620.0, 130.0, 1.0), (1100.0, 190.0, 0.55),
		(2500.0, 420.0, 0.16)])),
	# "oo" fechado, mais escuro -- para o baixo do coro
	"choir_oo": _tabela(_formantes([(380.0, 100.0, 1.0), (820.0, 150.0, 0.30),
		(2200.0, 380.0, 0.06)])),
	# metais: serra com os primeiros harmonicos reforcados
	"brass": _tabela([(1, 1.0), (2, 0.82), (3, 0.66), (4, 0.50), (5, 0.38),
		(6, 0.28), (7, 0.20), (8, 0.15), (9, 0.11), (10, 0.08)]),
}


# ------------------------------------------------------------------ notas ---

_PASSOS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def nota(nome: str) -> float:
	"""Nome cientifico -> Hz. A4 = 440. Aceita sustenidos e bemois."""
	p = _PASSOS[nome[0].upper()]
	i = 1
	while i < len(nome) and nome[i] in "#b":
		p += 1 if nome[i] == "#" else -1
		i += 1
	oit = int(nome[i:])
	midi = 12 * (oit + 1) + p
	return 440.0 * (2.0 ** ((midi - 69) / 12.0))


def transpor(f: float, semitons: float) -> float:
	return f * (2.0 ** (semitons / 12.0))


# --------------------------------------------------------------- envelope ---

def adsr(n: int, a: float, d: float, s: float, r: float) -> array.array:
	"""Envelope de `n` amostras. a/d/r em segundos, s em ganho (0..1)."""
	na = max(1, int(a * TAXA))
	nd = max(1, int(d * TAXA))
	nr = max(1, int(r * TAXA))
	if n <= na + nr:
		na = max(1, int(n * 0.25))
		nr = max(1, n - na - 1)
		nd = 1
	e = array.array("d", [0.0]) * n
	i = 0
	for k in range(min(na, n)):
		e[i] = (k / na) ** 1.6
		i += 1
	for k in range(nd):
		if i >= n:
			break
		e[i] = 1.0 + (s - 1.0) * (k / nd)
		i += 1
	while i < n - nr:
		e[i] = s
		i += 1
	inicio = e[i - 1] if i > 0 else s
	for k in range(nr):
		if i >= n:
			break
		e[i] = inicio * (1.0 - k / nr) ** 1.8
		i += 1
	return e


# ----------------------------------------------------------------- filtro ---

class Passabaixo:
	"""Passa-baixo ressonante de 2 polos (Chamberlin). `corte` em Hz,
	`q` 0.5..0.99 (quanto maior, mais ressonante)."""

	def __init__(self, corte: float, q: float = 0.6):
		self.baixo = 0.0
		self.banda = 0.0
		self.definir(corte, q)

	def definir(self, corte: float, q: float) -> None:
		corte = max(30.0, min(corte, TAXA * 0.45))
		self.f = 2.0 * math.sin(math.pi * corte / TAXA)
		self.q = max(0.02, min(1.0 - q, 1.0))

	def passo(self, x: float) -> float:
		self.baixo += self.f * self.banda
		alto = x - self.baixo - self.q * self.banda
		self.banda += self.f * alto
		return self.baixo


# ---------------------------------------------------------------- reverbe ---

class Reverbe:
	"""Schroeder: 4 pentes em paralelo -> 2 passa-tudo em serie. Um so'
	canal; o `Mistura` corre duas instancias com atrasos ligeiramente
	diferentes, e e' isso que abre o estereo."""

	def __init__(self, tamanho: float = 1.0, amortecer: float = 0.32, semente: int = 0):
		base = [1557, 1617, 1491, 1422]
		ap = [225, 556]
		r = random.Random(semente)
		self.pentes = []
		for m in base:
			m = int(m * tamanho) + r.randint(0, 23)
			self.pentes.append([array.array("d", [0.0]) * m, 0, 0.0])
		self.g_pente = 0.805
		self.amort = amortecer
		self.aps = []
		for m in ap:
			m = int(m * tamanho) + r.randint(0, 11)
			self.aps.append([array.array("d", [0.0]) * m, 0])

	def passo(self, x: float) -> float:
		fora = 0.0
		for p in self.pentes:
			buf, i, filtrado = p
			y = buf[i]
			filtrado = y * (1.0 - self.amort) + filtrado * self.amort
			p[2] = filtrado
			buf[i] = x + filtrado * self.g_pente
			p[1] = (i + 1) % len(buf)
			fora += y
		fora *= 0.25
		for p in self.aps:
			buf, i = p
			y = buf[i]
			buf[i] = fora + y * 0.5
			p[1] = (i + 1) % len(buf)
			fora = y - fora * 0.5
		return fora


# ------------------------------------------------------------------ vozes ---

def voz_tabela(nome_tab, freq, dur, env, detune=(0.0,), ganho=1.0, vibrato=0.0,
		vib_hz=5.0, corte=None, q=0.5, corte_fim=None):
	"""Uma nota de wavetable, com unissono desafinado opcional e um
	passa-baixo com envelope de corte."""
	tab = TAB[nome_tab]
	n = int(dur * TAXA)
	if n <= 0:
		return array.array("d")
	saida = array.array("d", [0.0]) * n
	k = ganho / max(1, len(detune))
	for cents in detune:
		f = freq * (2.0 ** (cents / 1200.0))
		passo = f * TAM_TABELA / TAXA
		fase = random.random() * TAM_TABELA
		if vibrato > 0.0:
			w = 2.0 * math.pi * vib_hz / TAXA
			for i in range(n):
				d = passo * (1.0 + vibrato * math.sin(w * i))
				i0 = int(fase)
				fr = fase - i0
				a = tab[i0 % TAM_TABELA]
				b = tab[(i0 + 1) % TAM_TABELA]
				saida[i] += (a + (b - a) * fr) * k
				fase += d
				if fase >= TAM_TABELA:
					fase -= TAM_TABELA
		else:
			for i in range(n):
				i0 = int(fase)
				fr = fase - i0
				a = tab[i0 % TAM_TABELA]
				b = tab[(i0 + 1) % TAM_TABELA]
				saida[i] += (a + (b - a) * fr) * k
				fase += passo
				if fase >= TAM_TABELA:
					fase -= TAM_TABELA
	if corte is not None:
		filtro = Passabaixo(corte, q)
		if corte_fim is None or abs(corte_fim - corte) < 1.0:
			for i in range(n):
				saida[i] = filtro.passo(saida[i])
		else:
			bloco = 64
			for i in range(n):
				if i % bloco == 0:
					filtro.definir(corte + (corte_fim - corte) * (i / n), q)
				saida[i] = filtro.passo(saida[i])
	m = min(n, len(env))
	for i in range(m):
		saida[i] *= env[i]
	for i in range(m, n):
		saida[i] = 0.0
	return saida


def voz_sino(freq, dur, ganho=1.0, brilho=1.0):
	"""Sino/celesta: parciais inarmonicos com decaimentos proprios. E' a
	inarmonicidade que faz soar a metal e nao a orgao."""
	n = int(dur * TAXA)
	saida = array.array("d", [0.0]) * n
	parciais = [(1.0, 1.0, 1.0), (2.01, 0.62, 0.72), (2.99, 0.44, 0.50),
		(4.21, 0.30 * brilho, 0.34), (5.43, 0.20 * brilho, 0.22),
		(6.79, 0.12 * brilho, 0.16)]
	for razao, amp, decai in parciais:
		f = freq * razao
		if f > TAXA * 0.45:
			continue
		w = 2.0 * math.pi * f / TAXA
		tau = max(0.02, decai * dur * 0.42) * TAXA
		k = ganho * amp
		fase = random.random() * 6.283
		for i in range(n):
			saida[i] += math.sin(w * i + fase) * k * math.exp(-i / tau)
	ataque = int(0.004 * TAXA)
	for i in range(min(ataque, n)):
		saida[i] *= i / ataque
	return saida


def voz_corda(freq, dur, ganho=1.0, brilho=0.5, decai=0.996):
	"""Karplus-Strong: corda pincada a serio (harpa/alaude). Uma rajada de
	ruido numa linha de atraso com media movel -- barato e convincente."""
	n = int(dur * TAXA)
	if n <= 0:
		return array.array("d")
	m = max(2, int(TAXA / freq))
	r = random.Random(int(freq * 977) & 0xFFFF)
	linha = array.array("d", [r.uniform(-1.0, 1.0) for _ in range(m)])
	# suaviza a rajada: menos brilho = pincada mais macia
	for _ in range(int((1.0 - brilho) * 6)):
		ant = linha[-1]
		for i in range(m):
			linha[i], ant = (linha[i] + ant) * 0.5, linha[i]
	saida = array.array("d", [0.0]) * n
	ant = 0.0
	for i in range(n):
		v = linha[i % m]
		linha[i % m] = (v + ant) * 0.5 * decai
		ant = v
		saida[i] = v * ganho
	cauda = min(n, int(0.03 * TAXA))
	for j in range(cauda):
		saida[n - cauda + j] *= 1.0 - j / cauda
	return saida


def voz_ruido(dur, corte, ganho=1.0, q=0.5, corte_fim=None, env=None,
		passa_alto=False):
	n = int(dur * TAXA)
	saida = array.array("d", [0.0]) * n
	r = random.Random()
	filtro = Passabaixo(corte, q)
	for i in range(n):
		if corte_fim is not None and i % 64 == 0:
			filtro.definir(corte + (corte_fim - corte) * (i / n), q)
		x = r.uniform(-1.0, 1.0)
		b = filtro.passo(x)
		saida[i] = (x - b if passa_alto else b) * ganho
	if env is not None:
		m = min(n, len(env))
		for i in range(m):
			saida[i] *= env[i]
		for i in range(m, n):
			saida[i] = 0.0
	return saida


def voz_bombo(dur, f_ini=120.0, f_fim=44.0, ganho=1.0, clique=0.35):
	"""Bombo/taiko: seno com envelope de altura + um estalo de ruido."""
	n = int(dur * TAXA)
	saida = array.array("d", [0.0]) * n
	fase = 0.0
	for i in range(n):
		t = i / n
		f = f_fim + (f_ini - f_fim) * math.exp(-t * 7.0)
		fase += 2.0 * math.pi * f / TAXA
		saida[i] = math.sin(fase) * math.exp(-t * 5.2) * ganho
	if clique > 0.0:
		nc = int(0.02 * TAXA)
		r = random.Random()
		filtro = Passabaixo(2600.0, 0.4)
		for i in range(min(nc, n)):
			saida[i] += filtro.passo(r.uniform(-1.0, 1.0)) * clique * ganho * (1.0 - i / nc) ** 2
	return saida


# ---------------------------------------------------------------- mistura ---

class Mistura:
	"""Tela estereo. `por(t, buf, ganho, pan, rev)` mistura uma voz no
	instante `t` (segundos); `render()` fecha com reverbe e limitador."""

	def __init__(self, dur: float):
		self.n = int(dur * TAXA)
		self.esq = array.array("d", [0.0]) * self.n
		self.dir = array.array("d", [0.0]) * self.n
		self.env_esq = array.array("d", [0.0]) * self.n
		self.env_dir = array.array("d", [0.0]) * self.n

	def por(self, t, buf, ganho=1.0, pan=0.0, rev=0.25, ciclico=True):
		"""Mistura `buf` em `t` segundos. Se `ciclico`, o que passar do fim
		da faixa reentra no principio -- e' o que faz um loop sem costura."""
		i0 = int(t * TAXA)
		if i0 >= self.n:
			if not ciclico:
				return
			i0 %= self.n
		ge = ganho * math.cos((pan + 1.0) * math.pi / 4.0) * 1.414 * 0.5
		gd = ganho * math.sin((pan + 1.0) * math.pi / 4.0) * 1.414 * 0.5
		esq, dire, ee, ed = self.esq, self.dir, self.env_esq, self.env_dir
		n = self.n
		# uma voz mais longa do que o proprio ciclo enrolaria por cima de si
		# mesma; corta-se ao comprimento do ciclo
		m = min(len(buf), n) if ciclico else min(len(buf), n - i0)
		re_, rd = ge * rev, gd * rev
		for i in range(m):
			j = i0 + i
			if j >= n:
				if not ciclico:
					break
				j -= n
			v = buf[i]
			esq[j] += v * ge
			dire[j] += v * gd
			if rev > 0.0:
				ee[j] += v * re_
				ed[j] += v * rd

	def render(self, rev_tam=1.0, rev_amort=0.34, ciclico=True, pico=0.89):
		"""Se `ciclico`, a cauda da reverbe volta ao inicio -- sem isso o
		loop tem um buraco na emenda."""
		ra = Reverbe(rev_tam, rev_amort, semente=1)
		rb = Reverbe(rev_tam * 1.031, rev_amort, semente=7)
		n = self.n
		ta = array.array("d", [0.0]) * n
		tb = array.array("d", [0.0]) * n
		for i in range(n):
			ta[i] = ra.passo(self.env_esq[i])
			tb[i] = rb.passo(self.env_dir[i])
		if ciclico:
			cauda = min(n, int(1.8 * TAXA))
			for i in range(cauda):
				k = 1.0 - i / cauda
				ta[i] += ra.passo(0.0) * k
				tb[i] += rb.passo(0.0) * k
		for i in range(n):
			self.esq[i] += ta[i]
			self.dir[i] += tb[i]
		maxv = 0.0
		for i in range(n):
			a, b = abs(self.esq[i]), abs(self.dir[i])
			if a > maxv:
				maxv = a
			if b > maxv:
				maxv = b
		k = (pico / maxv) if maxv > 0 else 1.0
		# saturacao suave: cola a mistura sem o corte duro do clip
		for i in range(n):
			self.esq[i] = math.tanh(self.esq[i] * k * 1.18) * 0.86
			self.dir[i] = math.tanh(self.dir[i] * k * 1.18) * 0.86
		if ciclico:
			# micro-esbatimento de 2,5 ms nas duas pontas. A amplitude no
			# fim e no principio ja' e' a mesma, mas a FASE nao tem de ser:
			# um salto de forma de onda na emenda ouve-se como estalo a cada
			# volta (medido: 0,18 na ambiencia da pausa, 40% do pico). 2,5 ms
			# nao se ouvem; o estalo ouvia-se.
			m = min(int(0.0025 * TAXA), n // 4)
			for i in range(m):
				f = i / m
				self.esq[i] *= f
				self.dir[i] *= f
				self.esq[n - 1 - i] *= f
				self.dir[n - 1 - i] *= f
		return self.esq, self.dir


def voz_continua(nome_tab, freq, dur, ganho=1.0, detune=(0.0,)):
	"""Nota SEM principio nem fim: para bordoes que atravessam o ciclo
	inteiro. A frequencia e' arredondada para caber um numero INTEIRO de
	ciclos em `dur` -- e' isso que faz a emenda do loop nao estalar (um
	envelope de ataque/queda so' troca o estalo por um buraco)."""
	tab = TAB[nome_tab]
	n = int(dur * TAXA)
	saida = array.array("d", [0.0]) * n
	k = ganho / max(1, len(detune))
	for cents in detune:
		f = freq * (2.0 ** (cents / 1200.0))
		ciclos = max(1.0, round(f * n / TAXA))
		passo = ciclos * TAM_TABELA / n
		fase = 0.0
		for i in range(n):
			i0 = int(fase)
			fr = fase - i0
			a = tab[i0 % TAM_TABELA]
			b = tab[(i0 + 1) % TAM_TABELA]
			saida[i] += (a + (b - a) * fr) * k
			fase += passo
			if fase >= TAM_TABELA:
				fase -= TAM_TABELA
	return saida


def escrever_wav(caminho: str, esq, dire) -> float:
	dados = bytearray()
	emp = struct.Struct("<hh").pack
	for i in range(len(esq)):
		dados += emp(int(max(-1.0, min(1.0, esq[i])) * 32767),
			int(max(-1.0, min(1.0, dire[i])) * 32767))
	with wave.open(caminho, "wb") as w:
		w.setnchannels(2)
		w.setsampwidth(2)
		w.setframerate(TAXA)
		w.writeframes(bytes(dados))
	return len(esq) / TAXA
