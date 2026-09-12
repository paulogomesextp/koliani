#!/usr/bin/env python3
"""Execution 9H.13 -- passe profissional dos SFX que o jogo toca mesmo.

    python tools/gerar_sfx_9h13.py

O Game Master: "os SFX gerais continuam fracos/amadores". Este ficheiro
refaz SO' os sons que o runtime dispara de facto (`grep 'Som.toca('`), na
direccao do rebrand: fantasia escura, cinematografico, impacto limpo, sem
bips de arcade.

O QUE MUDA DE METODO face ao `tools/gerar_audio.py` (que fez a 1.a leva):

1. **Tres camadas em vez de uma.** Um som de jogo le^-se como "profissional"
   quando tem CORPO (o peso, grave, e' o que se sente), BATIDA (o transiente,
   e' o que da' a leitura de impacto) e AR (a cauda, e' o que da' o espaco).
   A leva antiga era quase so' corpo -- dai' soar a sintetizador.
2. **O transiente vem primeiro e e' curtissimo.** 3 a 8 ms de ruido com
   queda abrupta. E' isto, e nao o volume, que faz um golpe "bater".
3. **Cauda com reverbera'cao** (`cauda()`): ecos curtos, cada vez mais
   abafados. Sem cauda um som acaba a pique e soa a amostra cortada.
4. **Sem ondas puras a descoberto.** Toda a senoide leva batimento (duas
   vozes desafinadas) ou ruido por cima. Uma senoide limpa e' um bip.
5. **Pico controlado por soma, nao por normalizacao cega.** Cada som sai a
   um alvo de pico proprio (ver `ALVO`), para a mistura ficar hierarquizada:
   o remate do combo tem de ser o mais pesado do teclado, o passo o mais
   discreto.

MISTURA: os alvos de pico abaixo sao deliberadamente baixos (0,55-0,90) e o
`Som.toca` ainda aplica -4 a -24 dB por evento. Nenhum som chega a 1,0, logo
nao ha' clipping na soma de vozes do pool.

LICENCAS: 100% sintetizado aqui, sem samples de terceiros. Sem numpy.
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

## Pico alvo de cada som. E' a hierarquia da mistura, escrita de uma vez:
## o combo cresce 1->4, o remate manda, e o que e' constante (passos) fica
## em baixo para nao mascarar os telegrafos dos inimigos.
ALVO = {
	"passo": 0.42,
	"salto": 0.66,
	"salto_duplo": 0.70,
	"aterrar": 0.72,
	"dash": 0.74,
	"rolamento": 0.60,
	"ataque": 0.70,
	"ataque2": 0.76,
	"ataque3": 0.82,
	"ataque_forte": 0.92,
	"acerto": 0.80,
	"dano": 0.74,
	"morte_koliani": 0.86,
	"bloqueio": 0.72,
	"apanhar": 0.58,
	"selo": 0.70,
	"transicao": 0.80,
	"ui_mover": 0.40,
	"ui_confirmar": 0.60,
	"ui_voltar": 0.52,
	"ui_negado": 0.58,
}

rng = random.Random(91314)


# --------------------------------------------------------------- utilitarios

def novo(dur: float) -> list[float]:
	return [0.0] * int(TAXA * dur)


def escrever(nome: str, buf: list[float], alvo: float) -> None:
	"""Grava a `alvo` de pico. Nao normaliza para 1,0 de proposito -- ver
	o cabecalho: a hierarquia da mistura esta' no `ALVO`."""
	pico = max((abs(v) for v in buf), default=1.0) or 1.0
	k = alvo / pico
	dados = b"".join(
		struct.pack("<h", int(max(-1.0, min(1.0, v * k)) * 32767)) for v in buf)
	with wave.open(os.path.join(SAIDA, nome), "wb") as w:
		w.setnchannels(1)
		w.setsampwidth(2)
		w.setframerate(TAXA)
		w.writeframes(dados)
	print("%-24s %5.3f s  pico=%.2f" % (nome, len(buf) / TAXA, alvo))


def queda(t: float, k: float) -> float:
	return math.exp(-t * k)


def transiente(buf: list[float], t0: float, dur: float, amp: float,
		cor: float = 0.5) -> None:
	"""A BATIDA: ruido de 3-8 ms com queda abrupta. `cor` de 0 (escuro) a 1
	(brilhante) -- e' um passa-baixo de um polo aplicado ao ruido."""
	n = int(TAXA * dur)
	i0 = int(TAXA * t0)
	ant = 0.0
	for i in range(n):
		if i0 + i >= len(buf):
			break
		r = rng.uniform(-1.0, 1.0)
		ant += (r - ant) * (0.04 + 0.92 * cor)
		buf[i0 + i] += ant * amp * queda(i / n, 7.0)


def corpo(buf: list[float], t0: float, f0: float, f1: float, dur: float,
		amp: float, k: float = 4.0, desafinar: float = 1.006) -> None:
	"""O PESO: duas vozes graves em varrimento de `f0` para `f1`, desafinadas
	entre si. O batimento das duas e' o que impede isto de soar a bip."""
	n = int(TAXA * dur)
	i0 = int(TAXA * t0)
	fa = fb = 0.0
	for i in range(n):
		if i0 + i >= len(buf):
			break
		t = i / n
		f = f0 * (f1 / f0) ** t
		fa += 2.0 * math.pi * f / TAXA
		fb += 2.0 * math.pi * f * desafinar / TAXA
		buf[i0 + i] += (math.sin(fa) + 0.7 * math.sin(fb)) * amp * queda(t, k)


def sopro(buf: list[float], t0: float, dur: float, amp: float,
		cor0: float, cor1: float, k: float = 3.0) -> None:
	"""O AR: ruido filtrado com o filtro a abrir/fechar. E' o que da' o
	'whoosh' de uma lamina e o espaco de uma sala."""
	n = int(TAXA * dur)
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
	"""Sino: fundamental + as parciais inarmonicas 2,76 e 5,40 de um sino
	real, cada uma a decair mais depressa. E' a voz do menu."""
	n = int(TAXA * dur)
	i0 = int(TAXA * t0)
	for p, (mult, ka) in enumerate(((1.0, 3.0), (2.76, 5.0), (5.40, 8.0))):
		a = amp * (1.0 if p == 0 else brilho ** p)
		for i in range(n):
			if i0 + i >= len(buf):
				break
			t = i / n
			buf[i0 + i] += math.sin(
				2.0 * math.pi * f * mult * (i / TAXA)) * a * queda(t, ka)


def cauda(buf: list[float], atraso: float = 0.045, n_ecos: int = 4,
		g: float = 0.34, abafar: float = 0.5) -> None:
	"""Reverbera'cao pobre mas honesta: ecos curtos, cada um mais abafado que
	o anterior. Sem isto o som acaba a pique e denuncia-se como sintetico."""
	d = int(TAXA * atraso)
	fonte = list(buf)
	ant = 0.0
	for e in range(1, n_ecos + 1):
		amp = g ** e
		off = d * e
		ant = 0.0
		for i in range(len(fonte)):
			if i + off >= len(buf):
				break
			ant += (fonte[i] - ant) * abafar
			buf[i + off] += ant * amp


def limitar(buf: list[float], tecto: float = 0.98) -> None:
	"""Saturacao suave (tanh) em vez de corte -- so' morde nos picos."""
	for i, v in enumerate(buf):
		if abs(v) > tecto * 0.7:
			buf[i] = tecto * math.tanh(v / tecto)


# ------------------------------------------------------------------- jogador

def salto(duplo: bool = False) -> list[float]:
	"""Salto: nao e' um 'boing'. E' o ATRITO da bota a largar o chao (sopro
	curto e escuro) mais uma subida de corpo. O salto duplo leva um sino
	roxo por cima -- e' magia, tem de se ouvir que e' outra coisa."""
	b = novo(0.40)
	transiente(b, 0.0, 0.006, 0.5, 0.35)
	sopro(b, 0.0, 0.16, 0.30, 0.10, 0.45, k=4.5)
	corpo(b, 0.004, 150.0 if not duplo else 210.0,
		330.0 if not duplo else 520.0, 0.20, 0.55, k=5.5)
	if duplo:
		sino(b, 0.01, 660.0, 0.34, 0.20, 0.5)
		sopro(b, 0.01, 0.26, 0.16, 0.5, 0.9, k=3.0)
	cauda(b, 0.038, 3, 0.26)
	limitar(b)
	return b


def aterrar() -> list[float]:
	"""Aterragem: batida escura + corpo a descer + poeira. O peso esta' na
	descida da frequencia, nao no volume."""
	b = novo(0.50)
	transiente(b, 0.0, 0.008, 0.85, 0.22)
	corpo(b, 0.0, 190.0, 58.0, 0.20, 0.75, k=7.0)
	sopro(b, 0.006, 0.30, 0.22, 0.30, 0.06, k=3.4)
	cauda(b, 0.050, 4, 0.30)
	limitar(b)
	return b


def dash() -> list[float]:
	"""Arranque: sopro que ABRE e volta a fechar (o corpo a rasgar o ar) com
	um fio de corpo grave por baixo. Sem transiente forte -- um dash nao
	bate em nada, desliza."""
	b = novo(0.42)
	transiente(b, 0.0, 0.005, 0.34, 0.6)
	sopro(b, 0.0, 0.13, 0.46, 0.20, 0.85, k=1.6)
	sopro(b, 0.11, 0.22, 0.30, 0.85, 0.12, k=3.2)
	corpo(b, 0.0, 260.0, 90.0, 0.18, 0.30, k=6.0)
	cauda(b, 0.042, 3, 0.28)
	limitar(b)
	return b


def rolamento() -> list[float]:
	"""Rolamento: tres roces de tecido/couro em cima do chao, nao um."""
	b = novo(0.46)
	for i, t in enumerate((0.0, 0.085, 0.175)):
		sopro(b, t, 0.12, 0.34 - 0.07 * i, 0.24, 0.08, k=4.0)
		transiente(b, t, 0.005, 0.22, 0.25)
	corpo(b, 0.0, 120.0, 70.0, 0.22, 0.24, k=5.0)
	cauda(b, 0.045, 3, 0.24)
	limitar(b)
	return b


def passo(n: int) -> list[float]:
	"""Passo: discreto de proposito (alvo 0,42 e o runtime ainda poe -24 dB).
	Um passo que se ouve bem e' um passo que chateia ao fim de dois minutos."""
	b = novo(0.16)
	transiente(b, 0.0, 0.004 + 0.001 * n, 0.55, 0.28 + 0.07 * n)
	corpo(b, 0.0, 130.0 + 22.0 * n, 62.0, 0.07, 0.34, k=9.0)
	sopro(b, 0.002, 0.075, 0.16, 0.35, 0.10, k=6.0)
	cauda(b, 0.028, 2, 0.18)
	limitar(b)
	return b


# ------------------------------------------------------------------- combate

def golpe(passo_combo: int) -> list[float]:
	"""Os quatro golpes do combo. Crescem em TRES eixos ao mesmo tempo --
	nao chega subir o volume, que e' o que soa a amador:

	  1. o corpo desce de registo (400->150 Hz no 1.o, 300->70 no remate):
	     grave = pesado;
	  2. o sopro alarga (a lamina 'rasga' mais ar);
	  3. a cauda cresce (o espaco abre-se a cada golpe).

	O remate (indice 3) leva ainda um transiente duplo -- arma e bate -- e
	uma badalada grave por baixo. E' o golpe mais lento e o mais fundo.
	"""
	remate = passo_combo >= 3
	dur = 0.34 + 0.10 * passo_combo
	b = novo(dur + 0.30)
	f0 = (400.0, 360.0, 330.0, 300.0)[passo_combo]
	f1 = (150.0, 125.0, 100.0, 70.0)[passo_combo]
	larg = 0.30 + 0.09 * passo_combo
	if remate:
		# antecipacao: a lamina arma-se antes de bater
		sopro(b, 0.0, 0.10, 0.20, 0.70, 0.35, k=2.0)
		transiente(b, 0.098, 0.010, 0.90, 0.30)
		t_bate = 0.10
	else:
		t_bate = 0.0
	transiente(b, t_bate, 0.005 + 0.001 * passo_combo,
		0.55 + 0.12 * passo_combo, 0.62 - 0.10 * passo_combo)
	# o 'rasgar' da lamina: abre e fecha
	sopro(b, t_bate, 0.10 + 0.02 * passo_combo, larg, 0.30, 0.88, k=2.2)
	sopro(b, t_bate + 0.06, 0.20, larg * 0.7, 0.88, 0.14, k=3.0)
	corpo(b, t_bate, f0, f1, 0.16 + 0.05 * passo_combo,
		0.50 + 0.14 * passo_combo, k=5.5 - 0.7 * passo_combo)
	if remate:
		corpo(b, t_bate + 0.01, 92.0, 46.0, 0.34, 0.55, k=3.0, desafinar=1.011)
		sino(b, t_bate + 0.012, 138.0, 0.40, 0.16, 0.30)
	cauda(b, 0.046 + 0.006 * passo_combo, 3 + passo_combo,
		0.28 + 0.03 * passo_combo)
	limitar(b)
	return b


def acerto() -> list[float]:
	"""Confirmacao de golpe: e' o som mais repetido do jogo, por isso e'
	CURTO (0,22 s) e sem cauda longa. Metal a morder carne: transiente
	brilhante, corpo curto, e um raspar por cima."""
	b = novo(0.30)
	transiente(b, 0.0, 0.005, 0.95, 0.72)
	corpo(b, 0.0, 300.0, 110.0, 0.08, 0.48, k=11.0)
	sopro(b, 0.003, 0.10, 0.26, 0.65, 0.20, k=6.0)
	cauda(b, 0.030, 2, 0.22)
	limitar(b)
	return b


def dano() -> list[float]:
	"""LEVAR dano. O briefing pede "claro sem ser agressivo": a leitura vem
	de um corpo grave a cair e de um abafamento (o mundo a fechar-se por um
	instante), NAO de ruido agudo -- ruido agudo em cima do jogador que acaba
	de ser atingido e' o que torna um jogo cansativo."""
	b = novo(0.60)
	transiente(b, 0.0, 0.007, 0.55, 0.18)
	corpo(b, 0.0, 240.0, 62.0, 0.26, 0.80, k=5.0, desafinar=1.013)
	# sub por baixo: sente-se mais do que se ouve
	corpo(b, 0.0, 70.0, 44.0, 0.40, 0.42, k=3.2, desafinar=1.004)
	sopro(b, 0.004, 0.18, 0.14, 0.22, 0.05, k=4.0)
	cauda(b, 0.055, 4, 0.32, abafar=0.34)
	limitar(b)
	return b


def morte() -> list[float]:
	"""Morte: o unico som do jogador com direito a cauda longa. Corpo a
	afundar + sino grave invertido (o ar a ser sugado) + silencio."""
	b = novo(1.30)
	transiente(b, 0.0, 0.010, 0.50, 0.20)
	corpo(b, 0.0, 300.0, 38.0, 0.70, 0.85, k=2.4, desafinar=1.016)
	corpo(b, 0.02, 110.0, 30.0, 0.95, 0.50, k=1.8, desafinar=1.007)
	sino(b, 0.04, 96.0, 1.00, 0.26, 0.34)
	sopro(b, 0.0, 0.55, 0.18, 0.30, 0.03, k=2.0)
	cauda(b, 0.075, 5, 0.38, abafar=0.30)
	limitar(b)
	return b


def bloqueio() -> list[float]:
	"""Escudo: metal contra metal, brilhante e CURTO, com um anel a seguir.
	E' o unico som do jogador que pode ser agudo -- e' a recompensa de ter
	defendido a tempo."""
	b = novo(0.44)
	transiente(b, 0.0, 0.004, 0.90, 0.88)
	sino(b, 0.0, 880.0, 0.30, 0.34, 0.55)
	sino(b, 0.002, 1320.0, 0.20, 0.18, 0.45)
	corpo(b, 0.0, 320.0, 160.0, 0.07, 0.40, k=10.0)
	cauda(b, 0.034, 4, 0.30, abafar=0.62)
	limitar(b)
	return b


# --------------------------------------------------------------- mundo e UI

def apanhar() -> list[float]:
	"""Essencia/coletavel: dois sinos em quinta ascendente, curtos e doces.
	Sem 'moeda de arcade' -- o brilho vem do sino, nao de uma onda quadrada."""
	b = novo(0.50)
	sino(b, 0.0, 784.0, 0.26, 0.34, 0.42)
	sino(b, 0.055, 1174.0, 0.30, 0.26, 0.38)
	sopro(b, 0.0, 0.10, 0.08, 0.75, 0.95, k=5.0)
	cauda(b, 0.040, 4, 0.30, abafar=0.60)
	limitar(b)
	return b


def selo() -> list[float]:
	"""Checkpoint (a fogueira a acender): sino grave a abrir + fole de chama
	+ cauda larga. Tem de soar a ALIVIO, e' a unica boa noticia do nivel."""
	b = novo(1.10)
	transiente(b, 0.0, 0.012, 0.40, 0.30)
	sino(b, 0.0, 196.0, 0.85, 0.40, 0.40)
	sino(b, 0.10, 294.0, 0.70, 0.26, 0.36)
	sino(b, 0.20, 392.0, 0.60, 0.18, 0.34)
	# a chama a pegar: ruido a abrir devagar
	sopro(b, 0.03, 0.55, 0.20, 0.08, 0.40, k=1.6)
	corpo(b, 0.0, 120.0, 84.0, 0.50, 0.30, k=2.6, desafinar=1.009)
	cauda(b, 0.070, 5, 0.36, abafar=0.44)
	limitar(b)
	return b


def transicao() -> list[float]:
	"""Porta/portal: sopro a ABRIR longo (o vacuo a puxar) e um sino grave a
	fechar por cima. Cinematografico, e' o corte entre dois sitios."""
	b = novo(1.20)
	sopro(b, 0.0, 0.60, 0.34, 0.06, 0.70, k=0.9)
	corpo(b, 0.0, 60.0, 190.0, 0.55, 0.40, k=1.4, desafinar=1.012)
	sino(b, 0.42, 262.0, 0.70, 0.30, 0.40)
	transiente(b, 0.42, 0.012, 0.45, 0.40)
	sopro(b, 0.45, 0.50, 0.20, 0.70, 0.05, k=2.2)
	cauda(b, 0.080, 5, 0.38, abafar=0.40)
	limitar(b)
	return b


def ui_mover() -> list[float]:
	"""Foco no menu: o mais discreto do teclado (0,40). Sopro + meio sino."""
	b = novo(0.22)
	sopro(b, 0.0, 0.07, 0.20, 0.55, 0.92, k=6.0)
	sino(b, 0.0, 523.0, 0.16, 0.16, 0.28)
	cauda(b, 0.026, 2, 0.22, abafar=0.60)
	limitar(b)
	return b


def ui_confirmar() -> list[float]:
	"""Confirmar: quinta ASCENDENTE, com cauda -- le^-se como porta a abrir."""
	b = novo(0.70)
	sino(b, 0.0, 392.0, 0.38, 0.34, 0.40)
	sino(b, 0.070, 588.0, 0.46, 0.30, 0.38)
	sopro(b, 0.0, 0.14, 0.10, 0.50, 0.90, k=4.0)
	cauda(b, 0.052, 4, 0.34, abafar=0.50)
	limitar(b)
	return b


def ui_voltar() -> list[float]:
	"""Recuar: a mesma voz, DESCENDENTE e mais curta."""
	b = novo(0.50)
	sino(b, 0.0, 523.0, 0.30, 0.30, 0.36)
	sino(b, 0.060, 349.0, 0.34, 0.26, 0.34)
	sopro(b, 0.0, 0.10, 0.08, 0.80, 0.40, k=5.0)
	cauda(b, 0.044, 3, 0.30, abafar=0.46)
	limitar(b)
	return b


def ui_negado() -> list[float]:
	"""Trancado: golpe abafado, SEM brilho nenhum. Todo o passa-baixo."""
	b = novo(0.42)
	transiente(b, 0.0, 0.008, 0.40, 0.12)
	corpo(b, 0.0, 150.0, 74.0, 0.22, 0.70, k=6.0, desafinar=1.015)
	sopro(b, 0.004, 0.12, 0.10, 0.14, 0.04, k=5.0)
	cauda(b, 0.040, 3, 0.24, abafar=0.30)
	limitar(b)
	return b


def main() -> None:
	escrever("salto.wav", salto(False), ALVO["salto"])
	escrever("salto_duplo.wav", salto(True), ALVO["salto_duplo"])
	escrever("aterrar.wav", aterrar(), ALVO["aterrar"])
	escrever("dash.wav", dash(), ALVO["dash"])
	escrever("rolamento.wav", rolamento(), ALVO["rolamento"])
	for n in range(3):
		escrever("passo%d.wav" % (n + 1), passo(n), ALVO["passo"])
	escrever("ataque.wav", golpe(0), ALVO["ataque"])
	escrever("ataque2.wav", golpe(1), ALVO["ataque2"])
	escrever("ataque3.wav", golpe(2), ALVO["ataque3"])
	escrever("ataque_forte.wav", golpe(3), ALVO["ataque_forte"])
	escrever("acerto.wav", acerto(), ALVO["acerto"])
	escrever("dano.wav", dano(), ALVO["dano"])
	escrever("morte_koliani.wav", morte(), ALVO["morte_koliani"])
	escrever("bloqueio.wav", bloqueio(), ALVO["bloqueio"])
	escrever("apanhar.wav", apanhar(), ALVO["apanhar"])
	escrever("selo.wav", selo(), ALVO["selo"])
	escrever("transicao.wav", transicao(), ALVO["transicao"])
	escrever("ui_mover.wav", ui_mover(), ALVO["ui_mover"])
	escrever("ui_confirmar.wav", ui_confirmar(), ALVO["ui_confirmar"])
	escrever("ui_voltar.wav", ui_voltar(), ALVO["ui_voltar"])
	escrever("ui_negado.wav", ui_negado(), ALVO["ui_negado"])


if __name__ == "__main__":
	main()
