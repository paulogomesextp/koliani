#!/usr/bin/env python3
"""Execution 9H.13/9H.13B -- os SFX que o runtime dispara mesmo.

    python tools/gerar_sfx_9h13.py

Tudo sintetizado aqui: sem samples de terceiros, sem licencas, sem numpy.

## Porque e' que a 1.a versao (9H.13) falhou

O Game Master ouviu a build e disse: "os SFX parecem praticamente iguais aos
anteriores". Estavam ligados -- os 13 eventos do jogador apontavam mesmo para
os ficheiros novos. O que estava mal era o DESENHO, e mediu-se:

1. **Normalizei por PICO, e o ouvido nao ouve picos, ouve ENERGIA.** Os sons
   novos eram cheios de transiente e vazios de corpo: crista de 14 a 18 dB,
   contra 8 a 12 dB dos antigos. Com o pico igual, a energia ficava muito
   abaixo. Medido na janela de 100 ms mais forte, novo contra antigo:

       hit confirm  -7,5 dB     passos    -6,2 dB
       UI move     -12,0 dB     bloqueio  -1,3 dB

   O `acerto` e' o som mais repetido do combate inteiro. Tirar-lhe 7,5 dB fez
   o combate soar MENOS forte do que antes -- exactamente o contrario do
   pedido.

2. **Os golpes eram mais compridos do que o proprio combo.** O passo do combo
   e' 0,18 / 0,20 / 0,30 / 0,26 s (`DUR_COMBO` no `koliani.gd`) e os sons
   duravam 0,64 a 0,94 s: 64 a 73% de sobreposicao. Quatro caudas empilhadas
   nao se ouvem como quatro golpes, ouvem-se como uma papa -- e a progressao
   1->4, que era o ponto todo, desaparecia.

## O que esta versao faz de diferente

- **Normaliza para SONORIDADE** (`ALVO_DB`, RMS da janela de 100 ms mais
  forte), nao para pico. O pico passa a ser so' um tecto que o limitador
  segura. E' esta a linha que resolve o ponto 1.
- **O corpo do golpe cabe no passo do combo.** Cada ataque tem o seu peso
  entregue nos primeiros ~0,12 s; so' o remate tem direito a cauda longa, e
  mesmo essa e' cauda a decair, nao corpo.
- **A progressao 1->4 e' de TIMBRE, nao so' de volume:** o 1 e' fino e
  cortante (agudo, sem grave), e a cada golpe desce o registo, entra grito
  harmonico (distorcao suave) e alarga a cauda. O remate e' o unico com sub
  e badalada de metal.

Verifica-se sozinho: no fim imprime a sonoridade medida de cada ficheiro ao
lado do alvo, e o desvio. Se um som nao chegar ao alvo, ve^-se na tabela.
"""
from __future__ import annotations

import math
import os
import random
import struct
import wave

TAXA = 44100
SAIDA = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
	"assets", "audio")

## SONORIDADE alvo de cada som, em dB (RMS da janela de 100 ms mais forte).
##
## E' a hierarquia da mistura escrita de uma vez. Referencia do que ca' estava
## ANTES da 9H.13, para nenhum som de feedback voltar a ficar mais fraco do
## que o legado que substitui:
##
##   acerto -10,4 | aterrar -13,9 | ataque -16,4 | ataque_forte -12,5
##   dano -11,3   | passo1 -16,3  | dash -13,4   | bloqueio -11,4
##
## Tudo o que e' feedback de combate fica ACIMA do legado. O que e' constante
## (passos) fica em baixo, mas audivel -- os -22,5 dB da 1.a versao eram
## inaudiveis por cima da musica.
ALVO_DB = {
	"passo": -17.0,
	"salto": -12.5,
	"salto_duplo": -11.5,
	"aterrar": -10.5,
	"dash": -12.0,
	"rolamento": -14.0,
	"ataque": -11.5,
	"ataque2": -10.0,
	"ataque3": -8.5,
	"ataque_forte": -5.5,
	"acerto": -9.0,
	"dano": -9.0,
	"morte_koliani": -7.0,
	"bloqueio": -9.5,
	"apanhar": -12.0,
	"selo": -10.0,
	"transicao": -8.0,
	"ui_mover": -14.5,
	"ui_confirmar": -11.5,
	"ui_voltar": -12.5,
	"ui_negado": -11.5,
}

## Tecto de pico. Abaixo de 1,0 para as 8 vozes do pool poderem somar sem
## clipar o master.
TECTO = 0.93

rng = random.Random(913132)


# --------------------------------------------------------------- utilitarios

def novo(dur: float) -> list[float]:
	return [0.0] * int(TAXA * dur)


def sonoridade(buf: list[float]) -> float:
	"""RMS da janela de 100 ms mais forte, em dB. E' o numero que acompanha o
	"quao alto isto soa" -- muito melhor do que o pico, que so' diz o quao
	afiado e' o transiente."""
	n = len(buf)
	w = int(TAXA * 0.1)
	if n < w:
		s = math.sqrt(sum(x * x for x in buf) / max(n, 1))
		return 20.0 * math.log10(max(s, 1e-9))
	melhor = 0.0
	passo = max(1, w // 2)
	for i in range(0, n - w + 1, passo):
		s = math.sqrt(sum(x * x for x in buf[i:i + w]) / w)
		melhor = max(melhor, s)
	return 20.0 * math.log10(max(melhor, 1e-9))


def limitar(buf: list[float], tecto: float = TECTO) -> None:
	"""Saturacao suave: so' morde nos picos, e por isso SOBE a energia media
	em vez de a baixar (e' o que um limitador faz num master a serio)."""
	joelho = tecto * 0.72
	for i, v in enumerate(buf):
		a = abs(v)
		if a > joelho:
			sinal = 1.0 if v >= 0.0 else -1.0
			excesso = (a - joelho) / max(tecto - joelho, 1e-6)
			buf[i] = sinal * (joelho + (tecto - joelho) * math.tanh(excesso))


def normalizar(buf: list[float], alvo_db: float) -> None:
	"""Leva o som ate' a' SONORIDADE pedida e so' depois segura o pico.
	Itera porque o limitador muda a energia -- duas voltas chegam a <0,3 dB."""
	# O limitador corre SEMPRE uma vez antes de medir. Sem isto, um som que ja'
	# nascesse com a sonoridade certa saltava o ciclo inteiro e ficava por
	# limitar: foi assim que o `ataque_forte` saiu com pico 1,89 (a cortar em
	# bruto na escrita, que e' o pior tipo de distorcao que ha').
	limitar(buf)
	for _ in range(4):
		actual = sonoridade(buf)
		ganho = 10.0 ** ((alvo_db - actual) / 20.0)
		if abs(20.0 * math.log10(max(ganho, 1e-9))) < 0.1:
			break
		for i in range(len(buf)):
			buf[i] *= ganho
		limitar(buf)


def escrever(nome: str, buf: list[float], chave: str) -> tuple[float, float]:
	alvo = ALVO_DB[chave]
	normalizar(buf, alvo)
	medido = sonoridade(buf)
	pico = max((abs(v) for v in buf), default=0.0)
	dados = b"".join(
		struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in buf)
	with wave.open(os.path.join(SAIDA, nome), "wb") as w:
		w.setnchannels(1)
		w.setsampwidth(2)
		w.setframerate(TAXA)
		w.writeframes(dados)
	print("%-22s %5.2f s  alvo %6.1f  medido %6.1f  (%+.1f)  pico %.2f" % (
		nome, len(buf) / TAXA, alvo, medido, medido - alvo, pico))
	return medido, pico


def queda(t: float, k: float) -> float:
	return math.exp(-t * k)


def transiente(buf: list[float], t0: float, dur: float, amp: float,
		cor: float = 0.5) -> None:
	"""A BATIDA: ruido curtissimo com queda abrupta."""
	n = max(1, int(TAXA * dur))
	i0 = int(TAXA * t0)
	ant = 0.0
	for i in range(n):
		if i0 + i >= len(buf):
			break
		ant += (rng.uniform(-1.0, 1.0) - ant) * (0.04 + 0.92 * cor)
		buf[i0 + i] += ant * amp * queda(i / n, 7.0)


def corpo(buf: list[float], t0: float, f0: float, f1: float, dur: float,
		amp: float, k: float = 4.0, desafinar: float = 1.006,
		grito: float = 0.0) -> None:
	"""O PESO: duas vozes graves em varrimento, desafinadas (o batimento e' o
	que impede isto de soar a bip). `grito` mete distorcao suave -- e' o que
	da' agressividade sem subir o volume."""
	n = max(1, int(TAXA * dur))
	i0 = int(TAXA * t0)
	fa = fb = 0.0
	for i in range(n):
		if i0 + i >= len(buf):
			break
		t = i / n
		f = f0 * (f1 / f0) ** t
		fa += 2.0 * math.pi * f / TAXA
		fb += 2.0 * math.pi * f * desafinar / TAXA
		s = math.sin(fa) + 0.7 * math.sin(fb)
		if grito > 0.0:
			s = math.tanh(s * (1.0 + 4.0 * grito)) * (1.0 - 0.25 * grito)
		buf[i0 + i] += s * amp * queda(t, k)


def sopro(buf: list[float], t0: float, dur: float, amp: float,
		cor0: float, cor1: float, k: float = 3.0) -> None:
	"""O AR: ruido filtrado com o filtro a abrir/fechar -- o 'whoosh'."""
	n = max(1, int(TAXA * dur))
	i0 = int(TAXA * t0)
	ant = 0.0
	for i in range(n):
		if i0 + i >= len(buf):
			break
		t = i / n
		c = cor0 + (cor1 - cor0) * t
		ant += (rng.uniform(-1.0, 1.0) - ant) * max(0.01, min(0.99, c))
		buf[i0 + i] += ant * amp * queda(t, k)


def sino(buf: list[float], t0: float, f: float, dur: float, amp: float,
		brilho: float = 0.4) -> None:
	"""Sino: fundamental + parciais inarmonicas 2,76 e 5,40 (as de um sino
	real), cada uma a decair mais depressa."""
	n = max(1, int(TAXA * dur))
	i0 = int(TAXA * t0)
	for p, (mult, ka) in enumerate(((1.0, 3.0), (2.76, 5.0), (5.40, 8.0))):
		a = amp * (1.0 if p == 0 else brilho ** p)
		for i in range(n):
			if i0 + i >= len(buf):
				break
			buf[i0 + i] += math.sin(
				2.0 * math.pi * f * mult * (i / TAXA)) * a * queda(i / n, ka)


def cauda(buf: list[float], atraso: float = 0.045, n_ecos: int = 4,
		g: float = 0.34, abafar: float = 0.5) -> None:
	"""Reverberacao pobre mas honesta: ecos curtos, cada um mais abafado."""
	d = max(1, int(TAXA * atraso))
	fonte = list(buf)
	for e in range(1, n_ecos + 1):
		amp = g ** e
		off = d * e
		ant = 0.0
		for i in range(len(fonte)):
			if i + off >= len(buf):
				break
			ant += (fonte[i] - ant) * abafar
			buf[i + off] += ant * amp


# ------------------------------------------------------------------- combate

## Os quatro golpes. O CORPO de cada um cabe no passo do combo (`DUR_COMBO` =
## 0,18 / 0,20 / 0,30 / 0,26 s); o que passa disso e' cauda a decair, nunca
## corpo, para os golpes nao se taparem uns aos outros.
##
## A progressao e' de TIMBRE:
##   1  fino e cortante -- agudo, sem grave nenhum, cauda curtissima
##   2  entra corpo medio
##   3  entra grito (distorcao) -- agressivo
##   4  desce ao sub, badalada de metal e a unica cauda longa
COMBO = [
	# dur, f0,    f1,   grito, cauda_ecos, cor_transiente
	(0.30, 620.0, 300.0, 0.00, 2, 0.80),
	(0.34, 500.0, 220.0, 0.18, 3, 0.70),
	(0.40, 420.0, 150.0, 0.42, 4, 0.58),
	(0.68, 300.0, 62.0, 0.30, 5, 0.42),
]


def golpe(passo: int) -> list[float]:
	dur, f0, f1, grito, ecos, cor = COMBO[passo]
	remate = passo == 3
	b = novo(dur)
	t = 0.0
	if remate:
		# antecipacao curta: a lamina arma-se. 60 ms, nao 100 -- tem de caber.
		sopro(b, 0.0, 0.055, 0.26, 0.72, 0.40, k=3.0)
		t = 0.06
	# BATIDA
	transiente(b, t, 0.004 + 0.001 * passo, 0.85 + 0.10 * passo, cor)
	# o corte de ar: curto e a fechar
	sopro(b, t, 0.055 + 0.012 * passo, 0.40 + 0.06 * passo, 0.34, 0.90, k=5.0)
	sopro(b, t + 0.03, 0.10, 0.26, 0.90, 0.20, k=6.0)
	# CORPO -- entregue nos primeiros ~0,12 s
	corpo(b, t, f0, f1, 0.10 + 0.02 * passo, 0.62 + 0.10 * passo,
		k=9.0 - 1.2 * passo, grito=grito)
	if remate:
		corpo(b, t + 0.008, 88.0, 44.0, 0.26, 0.70, k=5.0, desafinar=1.012)
		sino(b, t + 0.012, 146.0, 0.34, 0.26, 0.32)
	cauda(b, 0.030 + 0.005 * passo, ecos, 0.24 + 0.03 * passo)
	return b


def acerto() -> list[float]:
	"""Confirmacao de golpe -- o som mais repetido do jogo. Na 1.a versao
	perdeu 7,5 dB face ao legado e foi isso que fez o combate soar mais fraco.
	Agora e' CURTO (0,20 s) e forte: metal a morder, sem cauda que se arraste.
	"""
	b = novo(0.20)
	transiente(b, 0.0, 0.004, 1.00, 0.78)
	corpo(b, 0.0, 340.0, 120.0, 0.055, 0.80, k=13.0, grito=0.25)
	sopro(b, 0.002, 0.060, 0.40, 0.70, 0.28, k=8.0)
	sino(b, 0.0, 1180.0, 0.075, 0.22, 0.5)
	cauda(b, 0.022, 2, 0.20)
	return b


def dano() -> list[float]:
	"""LEVAR dano: claro e SECO (o Game Master pediu "nao abafado demais").
	A 1.a versao era so' grave -- lia-se como um baque distante. Agora tem
	corpo grave E um estalo medio por cima, que e' o que se ouve."""
	b = novo(0.46)
	transiente(b, 0.0, 0.006, 0.85, 0.45)
	corpo(b, 0.0, 300.0, 70.0, 0.16, 0.85, k=7.0, desafinar=1.013, grito=0.30)
	corpo(b, 0.0, 74.0, 46.0, 0.30, 0.42, k=4.0, desafinar=1.004)
	sopro(b, 0.003, 0.10, 0.26, 0.45, 0.12, k=6.0)
	cauda(b, 0.040, 3, 0.26, abafar=0.42)
	return b


def bloqueio() -> list[float]:
	"""Escudo: metal contra metal, brilhante, curto, com anel."""
	b = novo(0.40)
	transiente(b, 0.0, 0.004, 1.00, 0.90)
	sino(b, 0.0, 900.0, 0.26, 0.40, 0.55)
	sino(b, 0.002, 1350.0, 0.17, 0.22, 0.45)
	corpo(b, 0.0, 340.0, 170.0, 0.05, 0.45, k=13.0)
	cauda(b, 0.028, 4, 0.28, abafar=0.64)
	return b


# ------------------------------------------------------------------- jogador

def salto(duplo: bool = False) -> list[float]:
	"""Salto: leve, curto, FISICO. O atrito da bota a largar o chao."""
	b = novo(0.26 if not duplo else 0.32)
	transiente(b, 0.0, 0.005, 0.60, 0.38)
	sopro(b, 0.0, 0.10, 0.34, 0.12, 0.50, k=6.0)
	corpo(b, 0.003, 160.0 if not duplo else 230.0,
		340.0 if not duplo else 540.0, 0.11, 0.60, k=8.0)
	if duplo:
		sino(b, 0.008, 680.0, 0.22, 0.24, 0.5)
		sopro(b, 0.008, 0.18, 0.18, 0.55, 0.92, k=4.0)
	cauda(b, 0.026, 2, 0.22)
	return b


def aterrar() -> list[float]:
	"""Aterragem: impacto corporal + terreno. O peso esta' na descida."""
	b = novo(0.40)
	transiente(b, 0.0, 0.007, 0.95, 0.26)
	corpo(b, 0.0, 210.0, 54.0, 0.14, 0.90, k=9.0, grito=0.20)
	sopro(b, 0.005, 0.20, 0.30, 0.34, 0.07, k=4.5)
	cauda(b, 0.038, 3, 0.28)
	return b


def dash() -> list[float]:
	"""Arranque: sopro que abre e fecha; desliza, nao bate."""
	b = novo(0.34)
	transiente(b, 0.0, 0.004, 0.40, 0.62)
	sopro(b, 0.0, 0.10, 0.55, 0.22, 0.88, k=2.2)
	sopro(b, 0.085, 0.17, 0.34, 0.88, 0.14, k=4.0)
	corpo(b, 0.0, 280.0, 95.0, 0.13, 0.34, k=8.0)
	cauda(b, 0.032, 3, 0.24)
	return b


def rolamento() -> list[float]:
	b = novo(0.38)
	for i, t in enumerate((0.0, 0.075, 0.155)):
		sopro(b, t, 0.10, 0.40 - 0.08 * i, 0.26, 0.10, k=5.0)
		transiente(b, t, 0.004, 0.30, 0.28)
	corpo(b, 0.0, 130.0, 70.0, 0.16, 0.28, k=7.0)
	cauda(b, 0.034, 3, 0.22)
	return b


def passo(n: int) -> list[float]:
	"""Passo: discreto, mas nao inaudivel -- a 1.a versao tinha -22,5 dB e
	desaparecia por baixo da musica."""
	b = novo(0.13)
	transiente(b, 0.0, 0.004 + 0.001 * n, 0.70, 0.30 + 0.07 * n)
	corpo(b, 0.0, 140.0 + 22.0 * n, 64.0, 0.05, 0.45, k=12.0)
	sopro(b, 0.002, 0.055, 0.22, 0.38, 0.12, k=8.0)
	cauda(b, 0.022, 2, 0.16)
	return b


def morte() -> list[float]:
	b = novo(1.10)
	transiente(b, 0.0, 0.009, 0.60, 0.24)
	corpo(b, 0.0, 320.0, 38.0, 0.55, 0.90, k=3.0, desafinar=1.016, grito=0.35)
	corpo(b, 0.02, 112.0, 30.0, 0.80, 0.55, k=2.2, desafinar=1.007)
	sino(b, 0.04, 98.0, 0.85, 0.28, 0.34)
	sopro(b, 0.0, 0.45, 0.22, 0.32, 0.04, k=2.4)
	cauda(b, 0.065, 5, 0.36, abafar=0.32)
	return b


# --------------------------------------------------------------- mundo e UI

def apanhar() -> list[float]:
	b = novo(0.40)
	sino(b, 0.0, 784.0, 0.22, 0.40, 0.42)
	sino(b, 0.048, 1174.0, 0.26, 0.30, 0.38)
	sopro(b, 0.0, 0.07, 0.12, 0.78, 0.95, k=6.0)
	cauda(b, 0.034, 4, 0.28, abafar=0.60)
	return b


def selo() -> list[float]:
	"""Checkpoint (a fogueira a pegar): alivio."""
	b = novo(1.00)
	transiente(b, 0.0, 0.010, 0.50, 0.32)
	sino(b, 0.0, 196.0, 0.75, 0.45, 0.40)
	sino(b, 0.09, 294.0, 0.62, 0.30, 0.36)
	sino(b, 0.18, 392.0, 0.52, 0.20, 0.34)
	sopro(b, 0.03, 0.48, 0.24, 0.09, 0.42, k=1.8)
	corpo(b, 0.0, 122.0, 84.0, 0.42, 0.34, k=3.0, desafinar=1.009)
	cauda(b, 0.060, 5, 0.34, abafar=0.46)
	return b


def transicao() -> list[float]:
	b = novo(1.05)
	sopro(b, 0.0, 0.52, 0.38, 0.07, 0.72, k=1.0)
	corpo(b, 0.0, 62.0, 195.0, 0.48, 0.44, k=1.6, desafinar=1.012)
	sino(b, 0.38, 262.0, 0.60, 0.34, 0.40)
	transiente(b, 0.38, 0.010, 0.55, 0.42)
	sopro(b, 0.40, 0.42, 0.22, 0.72, 0.06, k=2.4)
	cauda(b, 0.070, 5, 0.36, abafar=0.42)
	return b


def ui_mover() -> list[float]:
	"""Foco no menu. Discreto, mas a 1.a versao tinha -12 dB face ao legado --
	era um sopro que ninguem ouvia."""
	b = novo(0.16)
	transiente(b, 0.0, 0.003, 0.45, 0.85)
	sino(b, 0.0, 620.0, 0.11, 0.34, 0.30)
	sopro(b, 0.0, 0.045, 0.26, 0.60, 0.94, k=7.0)
	cauda(b, 0.020, 2, 0.20, abafar=0.62)
	return b


def ui_confirmar() -> list[float]:
	b = novo(0.56)
	sino(b, 0.0, 392.0, 0.30, 0.42, 0.40)
	sino(b, 0.060, 588.0, 0.36, 0.34, 0.38)
	transiente(b, 0.0, 0.004, 0.35, 0.70)
	sopro(b, 0.0, 0.10, 0.14, 0.55, 0.92, k=5.0)
	cauda(b, 0.042, 4, 0.32, abafar=0.52)
	return b


def ui_voltar() -> list[float]:
	b = novo(0.40)
	sino(b, 0.0, 523.0, 0.24, 0.36, 0.36)
	sino(b, 0.050, 349.0, 0.28, 0.30, 0.34)
	sopro(b, 0.0, 0.075, 0.12, 0.82, 0.42, k=6.0)
	cauda(b, 0.036, 3, 0.28, abafar=0.48)
	return b


def ui_negado() -> list[float]:
	b = novo(0.36)
	transiente(b, 0.0, 0.007, 0.50, 0.14)
	corpo(b, 0.0, 155.0, 76.0, 0.18, 0.80, k=7.0, desafinar=1.015, grito=0.25)
	sopro(b, 0.003, 0.09, 0.14, 0.16, 0.05, k=6.0)
	cauda(b, 0.034, 3, 0.22, abafar=0.32)
	return b


def main() -> None:
	print("%-22s %7s  %11s  %14s  %s" % (
		"ficheiro", "duracao", "alvo dB", "medido dB", "pico"))
	res = []
	res.append(("salto.wav", escrever("salto.wav", salto(False), "salto")))
	res.append(("salto_duplo.wav",
		escrever("salto_duplo.wav", salto(True), "salto_duplo")))
	res.append(("aterrar.wav", escrever("aterrar.wav", aterrar(), "aterrar")))
	res.append(("dash.wav", escrever("dash.wav", dash(), "dash")))
	res.append(("rolamento.wav",
		escrever("rolamento.wav", rolamento(), "rolamento")))
	for n in range(3):
		res.append(("passo%d.wav" % (n + 1),
			escrever("passo%d.wav" % (n + 1), passo(n), "passo")))
	for i, nome in enumerate(
			["ataque.wav", "ataque2.wav", "ataque3.wav", "ataque_forte.wav"]):
		chave = nome[:-4]
		res.append((nome, escrever(nome, golpe(i), chave)))
	res.append(("acerto.wav", escrever("acerto.wav", acerto(), "acerto")))
	res.append(("dano.wav", escrever("dano.wav", dano(), "dano")))
	res.append(("morte_koliani.wav",
		escrever("morte_koliani.wav", morte(), "morte_koliani")))
	res.append(("bloqueio.wav", escrever("bloqueio.wav", bloqueio(), "bloqueio")))
	res.append(("apanhar.wav", escrever("apanhar.wav", apanhar(), "apanhar")))
	res.append(("selo.wav", escrever("selo.wav", selo(), "selo")))
	res.append(("transicao.wav",
		escrever("transicao.wav", transicao(), "transicao")))
	res.append(("ui_mover.wav", escrever("ui_mover.wav", ui_mover(), "ui_mover")))
	res.append(("ui_confirmar.wav",
		escrever("ui_confirmar.wav", ui_confirmar(), "ui_confirmar")))
	res.append(("ui_voltar.wav",
		escrever("ui_voltar.wav", ui_voltar(), "ui_voltar")))
	res.append(("ui_negado.wav",
		escrever("ui_negado.wav", ui_negado(), "ui_negado")))
	mau = [n for n, (m, _p) in res if abs(m - ALVO_DB[n[:-4].rstrip("123")
		if n.startswith("passo") else n[:-4]]) > 1.0]
	print()
	print("fora do alvo por mais de 1 dB: %s" % (mau or "nenhum"))


if __name__ == "__main__":
	main()
