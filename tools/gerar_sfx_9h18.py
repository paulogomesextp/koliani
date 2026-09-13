#!/usr/bin/env python3
"""Execution 9H.18 -- os SFX outra vez, agora pela FORMA.

    python tools/gerar_sfx_9h18.py [--so menu,combate,movimento]

Tudo sintetizado aqui: sem samples de terceiros, sem licencas, sem numpy,
sem API paga. Reaproveita as primitivas da 9H.13 e acrescenta as que
faltavam (filtro ressonante, objecto percutido com modos inarmonicos, grao).

## Porque e' que a 9H.13/13B ainda nao chegou

A 9H.13B ja' tinha resolvido a SONORIDADE (normalizar por energia, nao por
pico) e mesmo assim o Game Master ouviu a build e disse que continuavam
maus. Foi medido o que ninguem tinha medido -- a FORMA de cada som
(`tools/auditar_sfx_9h18.py`). O que apareceu:

  ui_mover        160 ms, cauda 109 ms   um "tique" de navegacao com 160 ms
                                         arrasta-se; a rolar a lista, as
                                         caudas empilham-se
  ui_confirmar    560 ms, cauda 417 ms   meio segundo para confirmar
  carrossel       ataque 136 ms          um clique cujo pico chega 136 ms
                                         depois do carregar NAO e' um clique
  porta          1000 ms, ataque 236 ms
  ataque_forte    ataque  70 ms          o REMATE do combo chega tarde ao
                                         golpe -- o pior sitio possivel
  ataque  15/75/11 % (grave/medio/agudo)
  acerto  20/64/16 %                     ou seja: o GOLPE e o ACERTO tem
                                         quase o mesmo timbre. Falhar e
                                         acertar soam igual.
  passo1  78/20/2   passo2 73/25/2   passo3 67/29/3
                                         tres "variacoes" que sao o mesmo som

Nada disto se ve numa tabela de sonoridade, e foi por isso que as duas
passagens anteriores se deram por boas.

## O que esta versao faz de diferente

1. **Cada som tem ALVOS DE FORMA** (`ALVOS`): duracao, tempo ate' ao pico,
   cauda e reparticao por bandas. O gerador MEDE o que produziu e imprime
   PASSA/FALHA por som -- nao se pode dar por boa sem cumprir.
2. **A interface encolheu.** Navegar sao 55 ms de madeira, nao 160 de sino.
   Confirmar sao 230 ms. E o pico chega sempre nos primeiros milissegundos.
3. **Golpe e acerto deixaram de ser o mesmo som.** O golpe e' ar e fio
   (pouco grave, muito agudo); o acerto e' impacto (grave a dominar, grao
   por cima). Os alvos de banda dos dois nem se sobrepoem.
4. **Os passos sao mesmo tres sons**: madeiras diferentes, grao diferente e
   ordem de modos diferente -- nao o mesmo com outra semente.
5. **Variacao a serio** para o que se repete: `passo`, `acerto` e `ui_mover`
   saem em tres versoes (`_v2`, `_v3`) e o autoload `Som` sorteia.
"""
from __future__ import annotations

import argparse
import math
import os
import random
import struct
import sys
import wave
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gerar_sfx_9h13 import (TAXA, SAIDA, corpo, limitar, sino,  # noqa: E402
	sonoridade, sopro, transiente)

rng = random.Random(918018)


# ------------------------------------------------- alvos de FORMA por evento
#
# (dur_max_ms, ataque_max_ms, cauda_max_ms, grave%, agudo%, sonoridade_db)
# As bandas sao intervalos (min, max) em percentagem da energia total:
# grave < 250 Hz, agudo > 2 kHz.
ALVOS = {
	# --- interface: curta, baixa, discreta. E' o que mais se repete. -------
	"ui_mover":      (70, 3, 60, (20, 62), (0, 16), -15.5),
	"ui_confirmar":  (260, 4, 240, (20, 62), (0, 18), -12.0),
	"ui_voltar":     (220, 6, 200, (25, 72), (0, 14), -13.0),
	"ui_negado":     (260, 5, 240, (25, 72), (0, 14), -12.0),
	"carrossel":     (90, 3, 80, (18, 62), (0, 18), -15.0),
	# --- movimento ---------------------------------------------------------
	"passo":         (90, 3, 80, (38, 82), (2, 24), -17.0),
	"salto":         (180, 4, 165, (28, 72), (0, 22), -12.5),
	"salto_duplo":   (240, 4, 225, (22, 68), (0, 24), -11.5),
	"aterrar":       (220, 3, 205, (42, 88), (0, 18), -10.5),
	"dash":          (240, 8, 225, (8, 48), (12, 48), -12.0),
	"rolamento":     (300, 10, 285, (32, 78), (0, 24), -14.0),
	# --- combate: o golpe e o acerto NAO podem cair na mesma banda ---------
	"ataque":        (170, 3, 155, (0, 22), (18, 58), -11.5),
	"ataque2":       (210, 3, 195, (6, 34), (12, 48), -10.0),
	"ataque3":       (280, 3, 265, (16, 50), (6, 34), -8.5),
	"ataque_forte":  (420, 8, 400, (40, 84), (0, 22), -5.5),
	"acerto":        (160, 3, 150, (31, 70), (8, 40), -9.0),
}


# ----------------------------------------------------- primitivas novas 9H.18

def novo(dur: float) -> list[float]:
	return [0.0] * int(TAXA * dur)


def passa_banda(buf: list[float], t0: float, dur: float, amp: float,
		f: float, q: float, k: float = 6.0) -> None:
	"""Ruido por um filtro RESSONANTE (variavel de estado). E' isto que da'
	TEXTURA -- um passa-baixo de um polo so' abafa, nao caracteriza."""
	n = max(1, int(TAXA * dur))
	i0 = int(TAXA * t0)
	fc = 2.0 * math.sin(math.pi * min(f, TAXA * 0.45) / TAXA)
	amortece = 1.0 / max(q, 0.5)
	baixo = banda = 0.0
	for i in range(n):
		if i0 + i >= len(buf):
			break
		entrada = rng.uniform(-1.0, 1.0)
		alto = entrada - baixo - amortece * banda
		banda += fc * alto
		baixo += fc * banda
		buf[i0 + i] += banda * amp * math.exp(-(i / n) * k)


def percutido(buf: list[float], t0: float,
		modos: list[tuple[float, float, float]], dur: float,
		amp: float) -> None:
	"""Objecto percutido: modos INARMONICOS, cada um com o seu decaimento.
	E' a diferenca entre "madeira" e "bip" -- as parciais nao sao multiplas
	umas das outras e as agudas morrem primeiro."""
	n = max(1, int(TAXA * dur))
	i0 = int(TAXA * t0)
	for (f, a, k) in modos:
		fase = rng.uniform(0.0, 2.0 * math.pi)
		w = 2.0 * math.pi * f / TAXA
		for i in range(n):
			if i0 + i >= len(buf):
				break
			buf[i0 + i] += math.sin(fase + w * i) * amp * a * math.exp(-(i / n) * k)


def grao(buf: list[float], t0: float, dur: float, amp: float, n_graos: int,
		f: float, q: float) -> None:
	"""GRAO: punhado de micro-impulsos ressonantes espalhados. E' o cascalho
	debaixo da bota e os estilhacos do acerto."""
	for _ in range(n_graos):
		u = rng.random() ** 2          # denso no impacto, ralo depois
		t = t0 + u * dur
		passa_banda(buf, t, rng.uniform(0.004, 0.012),
			amp * rng.uniform(0.4, 1.0) * (1.0 - 0.65 * u),
			f * rng.uniform(0.7, 1.5), q, 12.0)


def desvanecer(buf: list[float], ms: float = 4.0) -> None:
	"""Rampa no fim -- sem isto o corte do buffer e' um estalo."""
	n = min(len(buf), int(TAXA * ms / 1000.0))
	for i in range(n):
		buf[len(buf) - 1 - i] *= i / max(n, 1)


# ------------------------------------------------------------------ interface
#
# Direccao: fantasia escura cara. Madeira e pedra, nao plastico nem sci-fi.
# Grave-medio, curto, e no caso de navegar tao discreto que se possa carregar
# vinte vezes seguidas sem cansar.

def ui_mover(v: int = 0) -> list[float]:
	"""Tique de madeira escura: batida seca + dois modos baixos que morrem
	em 40 ms. 55 ms no total -- um terco do que ca' estava."""
	b = novo(0.055)
	base = [252.0, 268.0, 238.0][v]
	transiente(b, 0.0, 0.004, 0.55, 0.34)
	percutido(b, 0.0, [(base, 1.0, 6.0), (base * 2.41, 0.32, 11.0),
		(base * 4.03, 0.11, 18.0)], 0.050, 0.62)
	passa_banda(b, 0.0, 0.022, 0.46, 1150.0, 1.9, 11.0)
	desvanecer(b)
	return b


def ui_confirmar() -> list[float]:
	"""Confirmar: mais peso e uma badalada escura, mas curta. Metal batido
	com abafador em cima -- nao um sino de igreja a ressoar meio segundo."""
	b = novo(0.230)
	transiente(b, 0.0, 0.005, 0.86, 0.38)
	corpo(b, 0.0, 150.0, 104.0, 0.075, 0.26, k=8.0)
	percutido(b, 0.0, [(262.0, 1.0, 4.4), (262.0 * 2.72, 0.42, 8.0),
		(262.0 * 4.71, 0.16, 14.0)], 0.215, 0.46)
	passa_banda(b, 0.0, 0.036, 0.52, 1550.0, 2.2, 8.0)
	desvanecer(b)
	return b


def ui_voltar() -> list[float]:
	"""Voltar: a mesma familia, mas a DESCER e mais abafada. O gesto e' o
	contrario do confirmar e ouve-se que e'."""
	b = novo(0.200)
	transiente(b, 0.0, 0.005, 0.42, 0.24)
	corpo(b, 0.0, 220.0, 96.0, 0.17, 0.66, k=4.2)
	percutido(b, 0.002, [(150.0, 1.0, 5.4), (150.0 * 2.58, 0.18, 10.0)],
		0.185, 0.34)
	desvanecer(b)
	return b


def ui_negado() -> list[float]:
	"""Negado: pedra que nao cede. Duas batidas abafadas, sem harmonia --
	claro que nao deu, sem ser um buzzer de concurso."""
	b = novo(0.240)
	for (t, a) in ((0.0, 0.70), (0.062, 0.50)):
		transiente(b, t, 0.005, a * 0.6, 0.22)
		corpo(b, t, 150.0, 108.0, 0.060, a * 0.34, k=8.5, desafinar=1.031)
		percutido(b, t, [(214.0, 1.0, 8.0), (214.0 * 1.93, 0.62, 12.0),
			(214.0 * 4.10, 0.34, 16.0)], 0.070, a * 0.62)
		passa_banda(b, t, 0.024, a * 0.40, 980.0, 2.0, 11.0)
	desvanecer(b)
	return b


def carrossel() -> list[float]:
	"""Rodar o carrossel de niveis. Irmao do `ui_mover` -- um pouco mais
	claro e com um raspar curto, para se distinguir sem mudar de familia."""
	b = novo(0.075)
	transiente(b, 0.0, 0.004, 0.52, 0.42)
	percutido(b, 0.0, [(214.0, 1.0, 6.5), (214.0 * 2.33, 0.34, 12.0)],
		0.068, 0.56)
	passa_banda(b, 0.001, 0.026, 0.20, 1320.0, 2.0, 12.0)
	desvanecer(b)
	return b


# ------------------------------------------------------------------ movimento

## Cada passo e' uma madeira diferente -- nao o mesmo som com outra semente.
PASSOS = [
	# modo base, 2.o modo, grao (freq, n), brilho
	(126.0, 2.31, (2600.0, 8), 0.60),
	(148.0, 1.87, (3300.0, 6), 0.58),
	(112.0, 2.74, (2150.0, 10), 0.62),
]


def passo(n: int) -> list[float]:
	f, mult, (fg, ng), brilho = PASSOS[n]
	b = novo(0.075)
	transiente(b, 0.0, 0.0035, 0.78, 0.30)
	percutido(b, 0.0, [(f, 1.0, 7.0), (f * mult, 0.26, 13.0)], 0.070, 0.66)
	grao(b, 0.0, 0.024, brilho, ng, fg, 3.0)
	desvanecer(b)
	return b


def salto(duplo: bool = False) -> list[float]:
	"""Impulso: tecido e sola a largar o chao, mais um corpo grave curto.
	Sem subida de tom -- e' o que faz um salto soar a desenho animado."""
	b = novo(0.220 if duplo else 0.165)
	transiente(b, 0.0, 0.005, 0.46, 0.30)
	corpo(b, 0.0, 168.0 if duplo else 140.0, 72.0, 0.09, 0.34, k=7.0)
	sopro(b, 0.0, 0.11 if duplo else 0.085, 0.62, 0.62, 0.22, k=4.6)
	passa_banda(b, 0.0, 0.045, 0.20, 1800.0, 1.8, 9.0)
	if duplo:
		# o segundo salto tem uma lufada roxa a mais, uma oitava acima
		passa_banda(b, 0.012, 0.085, 0.24, 760.0, 1.6, 5.0)
	desvanecer(b)
	return b


def aterrar() -> list[float]:
	"""Aterrar: pancada com peso. O volume ja' vem escalado pela queda no
	`koliani.gd` -- aqui so' se garante o corpo grave e o cascalho."""
	b = novo(0.200)
	transiente(b, 0.0, 0.006, 0.66, 0.20)
	corpo(b, 0.0, 132.0, 54.0, 0.14, 0.90, k=5.5, desafinar=1.019)
	grao(b, 0.004, 0.055, 0.20, 11, 1500.0, 2.6)
	desvanecer(b)
	return b


def dash() -> list[float]:
	"""Dash: transiente de ar. Claro, mas nao a gritar -- o filtro fecha
	depressa para nao ficar uma chiadeira."""
	b = novo(0.215)
	transiente(b, 0.0, 0.004, 0.34, 0.72)
	sopro(b, 0.0, 0.175, 0.85, 0.80, 0.12, k=3.6)
	passa_banda(b, 0.0, 0.10, 0.24, 2400.0, 1.4, 5.0)
	corpo(b, 0.002, 190.0, 88.0, 0.10, 0.52, k=6.5)
	desvanecer(b)
	return b


def rolamento() -> list[float]:
	"""Rolamento: o corpo a passar pelo chao. Tres contactos abafados."""
	b = novo(0.280)
	for (t, a) in ((0.0, 0.85), (0.085, 0.62), (0.170, 0.40)):
		transiente(b, t, 0.006, a * 0.42, 0.22)
		corpo(b, t, 176.0, 104.0, 0.065, a * 0.34, k=7.5)
		grao(b, t, 0.050, 0.62 * a, 9, 1500.0, 2.0)
	desvanecer(b)
	return b


# -------------------------------------------------------------------- combate
#
# A progressao 1->4 e' de TIMBRE e de CORPO, nao de volume, e o alvo de
# bandas obriga a que se ouca: o 1 quase nao tem grave, o 4 e' quase so'
# grave. E o ACERTO cai noutra banda que nenhum dos golpes ocupa.

def golpe(passo_i: int) -> list[float]:
	if passo_i == 0:
		# fino e cortante: so' fio, sem peso nenhum
		b = novo(0.150)
		transiente(b, 0.0, 0.0030, 0.92, 0.86)
		sopro(b, 0.0, 0.095, 0.70, 0.72, 0.30, k=5.5)
		passa_banda(b, 0.0, 0.075, 0.30, 2900.0, 2.2, 7.0)
		passa_banda(b, 0.0, 0.070, 1.20, 940.0, 1.7, 6.5)
	elif passo_i == 1:
		# entra corpo: o mesmo fio com uma barriga media
		b = novo(0.190)
		transiente(b, 0.0, 0.0035, 0.48, 0.80)
		sopro(b, 0.0, 0.125, 0.74, 0.86, 0.30, k=4.6)
		passa_banda(b, 0.0, 0.090, 0.30, 2200.0, 2.0, 6.5)
		corpo(b, 0.001, 360.0, 190.0, 0.085, 0.58, k=6.5, grito=0.14)
	elif passo_i == 2:
		# pesado e com grito: ja' se compromete
		b = novo(0.260)
		transiente(b, 0.0, 0.004, 0.56, 0.68)
		sopro(b, 0.0, 0.165, 0.66, 0.78, 0.22, k=4.0)
		passa_banda(b, 0.0, 0.11, 0.30, 1700.0, 1.8, 5.5)
		corpo(b, 0.001, 270.0, 120.0, 0.115, 0.72, k=5.5, grito=0.40)
	else:
		# remate: sub, metal e a unica cauda longa. O PICO tem de estar no
		# inicio -- era aqui que a 9H.13 punha o transiente a 70 ms.
		b = novo(0.400)
		transiente(b, 0.0, 0.006, 0.95, 0.40)
		corpo(b, 0.0, 240.0, 44.0, 0.20, 1.00, k=4.2, grito=0.34,
			desafinar=1.014)
		sopro(b, 0.0, 0.16, 0.42, 0.62, 0.14, k=4.2)
		sino(b, 0.004, 118.0, 0.34, 0.24, brilho=0.26)
		grao(b, 0.004, 0.06, 0.22, 9, 900.0, 2.4)
	desvanecer(b)
	return b


def acerto(v: int = 0) -> list[float]:
	"""ACERTAR nao e' GOLPEAR. O golpe e' ar e fio; isto e' impacto: soco
	grave, osso a estalar e estilhaco por cima. As bandas dos dois nem se
	tocam, e e' de proposito -- falhar e acertar tem de soar diferente."""
	b = novo(0.145)
	f = [92.0, 84.0, 100.0][v]
	transiente(b, 0.0, 0.0030, 1.70, 0.62)
	transiente(b, 0.0, 0.0035, 0.72, 0.30)
	corpo(b, 0.0, f * 2.6, f * 1.05, 0.075, 0.56, k=7.5, grito=0.30,
		desafinar=1.022)
	percutido(b, 0.001, [(f * 3.1, 0.42, 12.0), (f * 6.7, 0.16, 20.0),
		(f * 27.0, 0.10, 26.0)], 0.055, 0.50)
	grao(b, 0.0, 0.030, 1.05, 13, 3000.0, 2.4)
	desvanecer(b)
	return b


# ------------------------------------------------------------------- medicoes

def forma(buf: list[float]) -> dict:
	"""As mesmas medidas do `auditar_sfx_9h18.py`, para o gerador se
	verificar a si proprio antes de escrever."""
	n = len(buf)
	jan = max(1, TAXA // 1000)
	env = [max(abs(v) for v in buf[i:i + jan]) for i in range(0, n, jan)]
	pico = max(env) if env else 0.0
	i_pico = env.index(pico) if env else 0
	lim = pico * 0.01
	i_fim = len(env) - 1
	while i_fim > i_pico and env[i_fim] < lim:
		i_fim -= 1

	def um_polo(fc: float, alto: bool) -> float:
		a = math.exp(-2.0 * math.pi * fc / TAXA)
		y = 0.0
		e = 0.0
		for v in buf:
			y = (1.0 - a) * v + a * y
			s = (v - y) if alto else y
			e += s * s
		return e

	tot = sum(v * v for v in buf) or 1.0
	return {
		"dur_ms": n / TAXA * 1000.0,
		"ataque_ms": float(i_pico),
		"cauda_ms": float(i_fim - i_pico),
		"grave": um_polo(250.0, False) / tot * 100.0,
		"agudo": um_polo(2000.0, True) / tot * 100.0,
	}


def normalizar(buf: list[float], alvo_db: float) -> None:
	limitar(buf)
	for _ in range(4):
		g = 10.0 ** ((alvo_db - sonoridade(buf)) / 20.0)
		if abs(20.0 * math.log10(max(g, 1e-9))) < 0.1:
			break
		for i in range(len(buf)):
			buf[i] *= g
		limitar(buf)


def escrever(ficheiro: str, buf: list[float], chave: str) -> bool:
	dur_max, atq_max, cauda_max, grave_lim, agudo_lim, alvo = ALVOS[chave]
	normalizar(buf, alvo)
	m = forma(buf)
	pico = max((abs(v) for v in buf), default=0.0)
	falhas = []
	if m["dur_ms"] > dur_max + 1:
		falhas.append("dur %.0f>%d" % (m["dur_ms"], dur_max))
	if m["ataque_ms"] > atq_max:
		falhas.append("ataque %.0f>%d" % (m["ataque_ms"], atq_max))
	if m["cauda_ms"] > cauda_max:
		falhas.append("cauda %.0f>%d" % (m["cauda_ms"], cauda_max))
	if not (grave_lim[0] <= m["grave"] <= grave_lim[1]):
		falhas.append("grave %.0f%% fora de %s" % (m["grave"], grave_lim))
	if not (agudo_lim[0] <= m["agudo"] <= agudo_lim[1]):
		falhas.append("agudo %.0f%% fora de %s" % (m["agudo"], agudo_lim))
	if pico > 1.0:
		falhas.append("pico %.2f" % pico)
	dados = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767))
		for v in buf)
	with wave.open(os.path.join(SAIDA, ficheiro), "wb") as w:
		w.setnchannels(1)
		w.setsampwidth(2)
		w.setframerate(TAXA)
		w.writeframes(dados)
	print("%-20s %4.0fms atq%3.0f cauda%4.0f  g%3.0f%% a%3.0f%%  son%6.1f  %s"
		% (ficheiro, m["dur_ms"], m["ataque_ms"], m["cauda_ms"], m["grave"],
			m["agudo"], sonoridade(buf),
			"PASSA" if not falhas else "FALHA: " + ", ".join(falhas)))
	return not falhas


GRUPOS = {
	"menu": [
		("ui_mover.wav", lambda: ui_mover(0), "ui_mover"),
		("ui_mover_v2.wav", lambda: ui_mover(1), "ui_mover"),
		("ui_mover_v3.wav", lambda: ui_mover(2), "ui_mover"),
		("ui_confirmar.wav", ui_confirmar, "ui_confirmar"),
		("ui_voltar.wav", ui_voltar, "ui_voltar"),
		("ui_negado.wav", ui_negado, "ui_negado"),
		("carrossel.wav", carrossel, "carrossel"),
	],
	"movimento": [
		("passo1.wav", lambda: passo(0), "passo"),
		("passo2.wav", lambda: passo(1), "passo"),
		("passo3.wav", lambda: passo(2), "passo"),
		("salto.wav", lambda: salto(False), "salto"),
		("salto_duplo.wav", lambda: salto(True), "salto_duplo"),
		("aterrar.wav", aterrar, "aterrar"),
		("dash.wav", dash, "dash"),
		("rolamento.wav", rolamento, "rolamento"),
	],
	"combate": [
		("ataque.wav", lambda: golpe(0), "ataque"),
		("ataque2.wav", lambda: golpe(1), "ataque2"),
		("ataque3.wav", lambda: golpe(2), "ataque3"),
		("ataque_forte.wav", lambda: golpe(3), "ataque_forte"),
		("acerto.wav", lambda: acerto(0), "acerto"),
		("acerto_v2.wav", lambda: acerto(1), "acerto"),
		("acerto_v3.wav", lambda: acerto(2), "acerto"),
	],
}


def main() -> int:
	ap = argparse.ArgumentParser()
	ap.add_argument("--so", default="", help="menu,movimento,combate")
	args = ap.parse_args()
	quais = [g.strip() for g in args.so.split(",") if g.strip()] or list(GRUPOS)
	ok = True
	for g in quais:
		print("")
		print("--- %s ---" % g.upper())
		for (ficheiro, fn, chave) in GRUPOS[g]:
			rng.seed(918018 + zlib.crc32(ficheiro.encode()))
			ok = escrever(ficheiro, fn(), chave) and ok
	print("")
	print("todos os sons cumprem os alvos de forma." if ok
		else "HA' SONS FORA DOS ALVOS -- ver acima.")
	return 0 if ok else 1


if __name__ == "__main__":
	sys.exit(main())
