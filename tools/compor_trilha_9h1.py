#!/usr/bin/env python3
"""Execution 9H.1 -- TRILHA SONORA DE PRODUCAO (menu + Regiao I).

    python tools/compor_trilha_9h1.py [nome_da_faixa ...]

O Game Master fechou a 9H com a trilha marcada PRODUCTION AUDIO MISSING e
pediu que se fechasse: "soundtrack, menu music, gameplay music, boss music".
Tambem disse, e importa: *nao* fazer 40 faixas medianas para satisfazer um
numero. Por isso isto compoe SEIS pecas para o que existe a serio -- o
frontend e a fatia vertical da Regiao I -- e deixa as 20+20 faixas antigas
a servir as Regioes II-XX ate' essas terem autoridade propria.

PROVENIENCIA: 100 % original, composto e sintetizado aqui por
`tools/motor_musical.py` (Python puro). Zero amostras de terceiros, zero
licencas, zero atribuicao devida. E' material do projecto.

O QUE AS FAIXAS SAO
-------------------
  tema_menu             D menor, 60 bpm. O TEMA DA KOLIANI enunciado
                        inteiro. Cordas + coro + sino, um taiko por
                        semi-frase.
  regiao1_exploracao    72 bpm. O mesmo tema desfeito em fragmentos sobre
                        um arpejo de harpa (Karplus-Strong). Melancolico,
                        a andar.
  regiao1_combate       128 bpm. Ostinato de cordas curtas, percussao,
                        naipe de metais a citar o tema. E' a camada de
                        intensidade da Regiao I.
  regiao1_guardiao      100 bpm. Tema dos guardioes: f???io (o ii bemol),
                        metais em oitavas, coro fechado, taiko pesado.
  regiao1_coracao       88 bpm. Climax do Coracao Putrefacto. A batida do
                        proprio coracao e' a espinha ritmica; o tema vem
                        INVERTIDO, e os sinos desafinam (a corrupcao).
  pausa_ambiente        Sem pulso. Um acorde e um sino de onde a onde.

UNIDADE TEMATICA. As cinco pecas com melodia usam o mesmo motivo de sete
notas (`MOTIVO`). E' o que separa uma banda sonora de seis loops soltos:
quando o combate cita em metais o que o menu disse em sino, o jogador
reconhece sem saber porque'.

TUDO EM CICLO. Cada peca fecha sobre si mesma: as vozes que passam do fim
reentram no principio (`Mistura.por(..., ciclico=True)`) e a cauda da
reverbe tambem. Uma cama de jogo toca em ciclo -- uma faixa que "acaba"
denuncia a emenda a cada volta (licao do 9H).
"""
from __future__ import annotations

import hashlib
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musical as M   # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "assets", "audio", "musica", "producao")
MANIFESTO = os.path.join(SAIDA, "manifesto_trilha_9h1.json")

N = M.nota

# ---------------------------------------------------------------- material ---

## O TEMA DA KOLIANI. Sete notas em re menor: sobe a` terceira, cai ate' ao
## setimo grau. (grau, duracao em tempos) -- o grau e' em semitons sobre re.
MOTIVO = [(7, 1.5), (12, 1.5), (15, 1.0), (14, 1.0), (12, 1.5), (10, 1.0), (7, 2.0)]
## Inversao (o Coracao): o mesmo desenho ao contrario, de cabeca para baixo.
MOTIVO_INV = [(7, 1.5), (2, 1.5), (-1, 1.0), (0, 1.0), (2, 1.5), (4, 1.0), (7, 2.0)]

RE = N("D3")     # tonica de referencia para os graus acima


def g(semitons: float, oitava: int = 0) -> float:
	"""Grau em semitons sobre re, com oitava opcional."""
	return M.transpor(RE, semitons + 12 * oitava)


## Acordes em graus sobre re menor natural (D E F G A Bb C).
ACORDES = {
	"Dm": [0, 3, 7], "Dm9": [0, 3, 7, 14], "Bb": [-2, 2, 5], "F": [3, 7, 10],
	"C": [-2, 2, 7], "Gm": [5, 8, 12], "A": [7, 11, 14], "Eb": [1, 5, 8],
	"Dsus": [0, 5, 7], "Dm7": [0, 3, 7, 10],
}


def acorde(nome: str, oitava: int = 0):
	return [g(s, oitava) for s in ACORDES[nome]]


# ------------------------------------------------------------- instrumentos ---

def cordas(mix, t, freq, dur, ganho=0.30, pan=0.0, rev=0.34, corte=780.0):
	"""Naipe de cordas: tres serras desafinadas, ataque lento, filtro a
	abrir. E' a cama harmonica de tudo."""
	n = int(dur * M.TAXA)
	env = M.adsr(n, min(0.9, dur * 0.35), 0.5, 0.78, min(1.4, dur * 0.45))
	b = M.voz_tabela("saw", freq, dur, env, detune=(-9.0, 0.0, 9.0),
		corte=corte, corte_fim=corte * 1.9, q=0.35)
	mix.por(t, b, ganho, pan, rev)


def coro(mix, t, freq, dur, ganho=0.22, pan=0.0, rev=0.46, fechado=False):
	n = int(dur * M.TAXA)
	env = M.adsr(n, min(1.1, dur * 0.4), 0.6, 0.82, min(1.6, dur * 0.5))
	b = M.voz_tabela("choir_oo" if fechado else "choir", freq, dur, env,
		detune=(-6.0, 5.0), vibrato=0.006, vib_hz=4.6, corte=2200.0, q=0.3)
	mix.por(t, b, ganho, pan, rev)


def bordao(mix, freq, dur, ganho=0.14, pan=0.0, rev=0.45, tab="organ"):
	"""Nota que atravessa o ciclo inteiro. Sem ataque nem queda: a
	frequencia e' arredondada para caber um numero inteiro de ciclos, e por
	isso a emenda do loop nao se ouve. Um ADSR aqui punha um BURACO no
	ponto de repeticao -- foi o que a primeira passagem fez (-27 dB na
	emenda do tema do menu)."""
	b = M.voz_continua(tab, freq, dur, 1.0, detune=(-3.0, 3.0))
	mix.por(0.0, b, ganho, pan, rev)


def orgao(mix, t, freq, dur, ganho=0.17, pan=0.0, rev=0.40):
	n = int(dur * M.TAXA)
	env = M.adsr(n, min(1.4, dur * 0.3), 0.4, 0.9, min(2.0, dur * 0.4))
	b = M.voz_tabela("organ", freq, dur, env, detune=(-3.0, 3.0), corte=1500.0)
	mix.por(t, b, ganho, pan, rev)


def metais(mix, t, freq, dur, ganho=0.26, pan=0.0, rev=0.28, ataque=0.05):
	n = int(dur * M.TAXA)
	env = M.adsr(n, ataque, 0.18, 0.72, min(0.45, dur * 0.4))
	b = M.voz_tabela("brass", freq, dur, env, detune=(-5.0, 4.0), vibrato=0.004,
		corte=900.0, corte_fim=2600.0, q=0.42)
	mix.por(t, b, ganho, pan, rev)


def sino(mix, t, freq, dur, ganho=0.30, pan=0.0, rev=0.55, brilho=1.0):
	mix.por(t, M.voz_sino(freq, dur, 1.0, brilho), ganho, pan, rev)


def harpa(mix, t, freq, dur, ganho=0.30, pan=0.0, rev=0.42, brilho=0.55):
	mix.por(t, M.voz_corda(freq, dur, 1.0, brilho), ganho, pan, rev)


def curto(mix, t, freq, dur, ganho=0.26, pan=0.0, rev=0.16):
	"""Cordas em staccato -- o ostinato do combate."""
	n = int(dur * M.TAXA)
	env = M.adsr(n, 0.006, dur * 0.45, 0.35, dur * 0.45)
	b = M.voz_tabela("saw", freq, dur, env, detune=(-7.0, 7.0),
		corte=520.0, corte_fim=1500.0, q=0.45)
	mix.por(t, b, ganho, pan, rev)


def taiko(mix, t, ganho=0.55, pan=0.0, grave=False, rev=0.22):
	b = M.voz_bombo(0.9 if grave else 0.6, 150.0 if grave else 190.0,
		42.0 if grave else 58.0, 1.0, 0.30)
	mix.por(t, b, ganho, pan, rev)


def caixa(mix, t, ganho=0.30, pan=0.0):
	n = int(0.18 * M.TAXA)
	env = M.adsr(n, 0.002, 0.06, 0.18, 0.10)
	b = M.voz_ruido(0.18, 1900.0, 1.0, 0.55, corte_fim=900.0, env=env)
	mix.por(t, b, ganho, pan, 0.24)


def chapeu(mix, t, ganho=0.10, pan=0.0):
	n = int(0.07 * M.TAXA)
	env = M.adsr(n, 0.001, 0.03, 0.10, 0.035)
	b = M.voz_ruido(0.07, 5200.0, 1.0, 0.3, env=env, passa_alto=True)
	mix.por(t, b, ganho, pan, 0.10)


def sopro(mix, t, dur, ganho=0.08, pan=0.0, corte=700.0, rev=0.5):
	"""Respiracao larga de ruido -- o vento/nevoa por baixo de tudo."""
	n = int(dur * M.TAXA)
	env = M.adsr(n, dur * 0.4, dur * 0.1, 0.7, dur * 0.45)
	b = M.voz_ruido(dur, corte, 1.0, 0.25, corte_fim=corte * 2.4, env=env)
	mix.por(t, b, ganho, pan, rev)


def batida_coracao(mix, t, ganho=0.62, pan=0.0):
	"""Lub-dub: dois golpes, o segundo mais fraco e 0,26 s depois."""
	mix.por(t, M.voz_bombo(0.7, 96.0, 36.0, 1.0, 0.10), ganho, pan, 0.18)
	mix.por(t + 0.26, M.voz_bombo(0.55, 82.0, 33.0, 1.0, 0.06), ganho * 0.62, pan, 0.18)


def frase(mix, t0, bpm, notas, voz, oitava=0, ganho=0.3, pan=0.0, escala=1.0,
		legato=1.06, **kw):
	"""Toca uma sequencia (grau, tempos) a partir de `t0`."""
	seg = 60.0 / bpm
	t = t0
	for grau, tempos in notas:
		d = tempos * seg * escala
		voz(mix, t, g(grau, oitava), d * legato, ganho=ganho, pan=pan, **kw)
		t += d
	return t


# -------------------------------------------------------------- as seis pecas ---

def tema_menu():
	"""48 s, 60 bpm, 4/4 -- 12 compassos de 4 s."""
	bpm, comp, nc = 60.0, 4.0, 12
	dur = comp * nc
	mix = M.Mistura(dur)
	prog = ["Dm", "Dm", "Bb", "Bb", "F", "F", "C", "C", "Dm", "Bb", "Gm", "A"]

	# bordao de re, do principio ao fim (uma nota so', a atravessar o loop)
	bordao(mix, g(0, -1), dur, 0.13, 0.0, 0.50)
	for i, nome in enumerate(prog):
		t = i * comp
		notas = acorde(nome)
		# cordas: o acorde aberto, a voz de baixo uma oitava abaixo
		cordas(mix, t, notas[0] / 2.0, comp * 1.55, 0.26, -0.10)
		for k, f in enumerate(notas):
			cordas(mix, t + 0.05 * k, f, comp * 1.55, 0.17, -0.45 + 0.45 * k)
		# coro entra na segunda metade e fica
		if i >= 4:
			for k, f in enumerate(notas[:3]):
				coro(mix, t, f * 2.0, comp * 1.6, 0.115, 0.5 - 0.5 * k)
		sopro(mix, t, comp * 2.0, 0.05, (-1.0 if i % 2 else 1.0) * 0.6, 620.0)
	# taiko no principio de cada semi-frase
	for c in (0, 4, 8):
		taiko(mix, c * comp, 0.42, 0.0, grave=True)
	# O TEMA, em sino, duas vezes -- a segunda uma oitava acima e mais leve
	frase(mix, comp * 0.5, bpm, MOTIVO, sino, oitava=1, ganho=0.34, pan=-0.18,
		escala=1.0, brilho=1.0)
	frase(mix, comp * 8.5, bpm, MOTIVO, sino, oitava=2, ganho=0.20, pan=0.24,
		escala=1.0, brilho=0.7)
	# contracanto de cordas na terceira frase
	frase(mix, comp * 4.0, bpm, [(3, 2.0), (2, 2.0), (0, 4.0)], cordas, oitava=1,
		ganho=0.13, pan=0.3, corte=1100.0)
	return mix, dur


def regiao1_exploracao():
	"""60 s, 72 bpm -- 18 compassos de 3,333 s."""
	bpm = 72.0
	comp = 4 * 60.0 / bpm
	nc = 18
	dur = comp * nc
	mix = M.Mistura(dur)
	prog = ["Dm", "Dm", "F", "F", "Bb", "Bb", "C", "Dm",
		"Dm", "Dm", "F", "F", "Bb", "Bb", "C", "Dm", "Gm", "A"]
	seg = 60.0 / bpm
	bordao(mix, g(0, -1), dur, 0.09, 0.0, 0.50)
	for i, nome in enumerate(prog):
		t = i * comp
		notas = acorde(nome)
		cordas(mix, t, notas[0] / 2.0, comp * 1.55, 0.15, 0.0, corte=620.0)
		for k, f in enumerate(notas):
			cordas(mix, t + 0.03 * k, f, comp * 1.55, 0.085, -0.35 + 0.35 * k,
				corte=680.0)
		# arpejo de harpa: colcheias a subir e a descer pelo acorde
		desenho = [0, 1, 2, 1, 2, 3, 2, 1]
		aberto = notas + [notas[0] * 2.0]
		for k, idx in enumerate(desenho):
			f = aberto[idx % len(aberto)] * (2.0 if k >= 4 else 1.0)
			harpa(mix, t + k * seg * 0.5, f, seg * 1.3,
				0.20 if k % 2 == 0 else 0.13, -0.30 + 0.08 * k)
		if i % 4 == 0:
			sopro(mix, t, comp * 3.0, 0.055, 0.7 if i % 8 else -0.7, 540.0)
		if i % 8 == 3:
			taiko(mix, t, 0.20, 0.0)
	# o tema em fragmentos: tres entradas, nunca inteiro (e' exploracao)
	frase(mix, comp * 2.0, bpm, MOTIVO[:3], sino, oitava=1, ganho=0.24, pan=-0.25)
	frase(mix, comp * 7.0, bpm, MOTIVO[3:], sino, oitava=1, ganho=0.21, pan=0.28,
		brilho=0.75)
	frase(mix, comp * 12.0, bpm, MOTIVO[:4], sino, oitava=2, ganho=0.17, pan=0.0,
		brilho=0.6)
	frase(mix, comp * 16.0, bpm, [(5, 2.0), (7, 2.0), (11, 4.0)], coro, oitava=1,
		ganho=0.10, pan=0.0)
	return mix, dur


def regiao1_combate():
	"""60 s, 128 bpm -- 32 compassos de 1,875 s."""
	bpm = 128.0
	seg = 60.0 / bpm
	comp = 4 * seg
	nc = 32
	dur = comp * nc
	mix = M.Mistura(dur)
	# 8+4+4 / 8+4+4
	prog = (["Dm"] * 8 + ["Bb"] * 4 + ["C"] * 4) * 2
	# ostinato: colcheias em re com dois desvios por compasso
	desenho = [0, 0, 0, 3, 0, 0, 2, 0]
	for i in range(nc):
		t = i * comp
		nome = prog[i]
		raiz = ACORDES[nome][0]
		for k, d in enumerate(desenho):
			acento = 0.30 if k in (0, 4) else 0.19
			curto(mix, t + k * seg * 0.5, g(raiz + d, -1), seg * 0.42, acento, -0.22)
			curto(mix, t + k * seg * 0.5, g(raiz + d, 0), seg * 0.40, acento * 0.55, 0.24)
		# percussao
		taiko(mix, t, 0.50, 0.0, grave=True)
		taiko(mix, t + seg * 2, 0.34, 0.0)
		caixa(mix, t + seg, 0.26, 0.12)
		caixa(mix, t + seg * 3, 0.26, -0.12)
		if i % 4 == 3:
			caixa(mix, t + seg * 3.5, 0.20, 0.0)
		for k in range(8):
			chapeu(mix, t + k * seg * 0.5, 0.085 if k % 2 else 0.12, 0.42)
		# coro em quintas, a partir do compasso 8
		if i >= 8 and i % 2 == 0:
			f = g(ACORDES[nome][0], 0)
			coro(mix, t, f, comp * 2.1, 0.09, -0.5, fechado=True)
			coro(mix, t, f * 1.4983, comp * 2.1, 0.075, 0.5, fechado=True)
	# metais: o tema citado em compasso duplo, duas vezes
	frase(mix, comp * 4.0, bpm, MOTIVO, metais, oitava=0, ganho=0.22, pan=-0.2,
		escala=1.0, ataque=0.03)
	frase(mix, comp * 20.0, bpm, MOTIVO, metais, oitava=1, ganho=0.19, pan=0.22,
		escala=1.0, ataque=0.03)
	# estocadas de metal nas viragens
	for i in (12, 16, 28):
		for f in acorde(prog[i], 0):
			metais(mix, i * comp, f, seg * 1.6, 0.15, 0.0, ataque=0.012)
	return mix, dur


def regiao1_guardiao():
	"""57,6 s, 100 bpm -- 24 compassos de 2,4 s. Frigio: o mi bemol e' a
	cor do guardiao (o mesmo intervalo que a corrupcao usa nos VFX)."""
	bpm = 100.0
	seg = 60.0 / bpm
	comp = 4 * seg
	nc = 24
	dur = comp * nc
	mix = M.Mistura(dur)
	prog = ["Dm", "Dm", "Eb", "Eb", "Dm", "Dm", "C", "Dm"] * 3
	bordao(mix, g(0, -2), dur, 0.15, 0.0, 0.42)
	for i, nome in enumerate(prog):
		t = i * comp
		notas = acorde(nome)
		# taiko pesado: 1 . . 3 e
		taiko(mix, t, 0.62, 0.0, grave=True)
		taiko(mix, t + seg * 2, 0.44, -0.18)
		taiko(mix, t + seg * 3, 0.30, 0.18)
		if i % 4 == 3:
			taiko(mix, t + seg * 3.5, 0.34, 0.0)
			caixa(mix, t + seg * 3.75, 0.22, 0.0)
		# cordas graves no acorde
		cordas(mix, t, notas[0] / 2.0, comp * 1.55, 0.24, 0.0, corte=520.0)
		for k, f in enumerate(notas):
			cordas(mix, t, f, comp * 1.55, 0.11, -0.4 + 0.4 * k, corte=700.0)
		# coro fechado, pedal de re contra o acorde -- a friccao e' o ponto
		if i >= 4:
			coro(mix, t, g(0, 1), comp * 1.6, 0.10, -0.35, fechado=True)
			coro(mix, t, g(ACORDES[nome][1], 1), comp * 1.6, 0.085, 0.35, fechado=True)
		# cacho agudo no mi bemol (so' nos compassos frigios)
		if nome == "Eb":
			for d in (1, 2):
				cordas(mix, t, g(d, 2), comp, 0.055, (d - 1.5) * 0.8, corte=2400.0)
	# metais em oitavas: o tema ALARGADO (cada nota vale o dobro)
	frase(mix, comp * 8.0, bpm, MOTIVO, metais, oitava=-1, ganho=0.26, pan=-0.15,
		escala=1.6, ataque=0.04)
	frase(mix, comp * 8.0, bpm, MOTIVO, metais, oitava=0, ganho=0.17, pan=0.18,
		escala=1.6, ataque=0.04)
	# resposta curta nos ultimos quatro compassos
	frase(mix, comp * 20.0, bpm, [(12, 1.0), (13, 1.0), (12, 2.0), (7, 4.0)],
		metais, oitava=0, ganho=0.20, pan=0.0, ataque=0.02)
	return mix, dur


def regiao1_coracao():
	"""60 s, 88 bpm -- 22 compassos de 2,727 s. A batida do coracao e' o
	metronomo; tudo o resto entra por camadas ate' ao fim."""
	bpm = 88.0
	seg = 60.0 / bpm
	comp = 4 * seg
	nc = 22
	dur = comp * nc
	mix = M.Mistura(dur)
	prog = ["Dm", "Dm", "Eb", "Dm", "Gm", "Dm", "Eb", "C"] * 3
	prog = prog[:nc]
	bordao(mix, g(0, -2), dur, 0.16, 0.0, 0.45)
	for i, nome in enumerate(prog):
		t = i * comp
		notas = acorde(nome)
		# a batida, sempre -- e' o unico elemento que nunca falha
		batida_coracao(mix, t, 0.58, 0.0)
		if i >= 6:
			batida_coracao(mix, t + comp * 0.5, 0.34 + 0.010 * i, 0.0)
		# orgao no acorde (o Coracao e' uma coisa de igreja podre)
		for k, f in enumerate(notas):
			orgao(mix, t, f, comp * 1.58, 0.085, -0.4 + 0.4 * k, 0.42)
		if i >= 4:
			cordas(mix, t, notas[0] / 2.0, comp * 1.55, 0.16, 0.0, corte=560.0)
		if i >= 10:
			coro(mix, t, g(0, 1), comp * 1.6, 0.10, -0.4)
			coro(mix, t, g(ACORDES[nome][2], 1), comp * 1.6, 0.085, 0.4)
		if i >= 14:
			for d in (1, 3):
				cordas(mix, t, g(d, 2), comp, 0.05, (d - 2) * 0.5, corte=2600.0)
		sopro(mix, t, comp * 2.0, 0.05 + 0.002 * i, (-1) ** i * 0.55, 480.0)
	# o tema INVERTIDO em sino, e um segundo sino 18 cents acima: a
	# corrupcao e' isto -- a mesma nota a discutir consigo propria
	for t0, oit, gan in ((comp * 2.0, 1, 0.26), (comp * 12.0, 2, 0.21)):
		frase(mix, t0, bpm, MOTIVO_INV, sino, oitava=oit, ganho=gan, pan=-0.22)
		seg2 = 60.0 / bpm
		t = t0 + 0.045
		for grau, tempos in MOTIVO_INV:
			d = tempos * seg2
			sino(mix, t, g(grau, oit) * 1.0104, d * 1.06, gan * 0.55, 0.26, brilho=0.6)
			t += d
	# ultimo compasso: o acorde inteiro em metais, a fechar o ciclo
	for f in acorde("Dm", 0):
		metais(mix, comp * (nc - 2), f, comp * 1.8, 0.16, 0.0, ataque=0.5)
	return mix, dur


def pausa_ambiente():
	"""32 s. Sem pulso e sem tema: um acorde suspenso, um sino de onde a
	onde. Toca por cima de um jogo parado -- nao pode puxar por nada."""
	dur = 32.0
	mix = M.Mistura(dur)
	bordao(mix, g(0, -1), dur, 0.13, 0.0, 0.55)
	for k, s in enumerate(ACORDES["Dm9"]):
		bordao(mix, g(s), dur, 0.075, -0.45 + 0.30 * k, 0.50, tab="saw")
	bordao(mix, g(0, 1), dur, 0.055, 0.0, 0.55, tab="choir_oo")
	for t, s in ((3.0, 12), (11.5, 15), (19.0, 10), (26.5, 12)):
		sino(mix, t, g(s, 1), 5.0, 0.17, (-1) ** int(t) * 0.3, 0.6, brilho=0.55)
	sopro(mix, 0.0, 16.0, 0.05, -0.6, 500.0)
	sopro(mix, 14.0, 16.0, 0.05, 0.6, 460.0)
	return mix, dur


# ------------------------------------------------------------------ pipeline ---

## nome -> (funcao, papel no jogo, ganho final relativo)
FAIXAS = {
	"tema_menu": (tema_menu, "Menu inicial, intro e ecras do frontend", 0.86),
	"regiao1_exploracao": (regiao1_exploracao, "Regiao I -- niveis 1-5, exploracao", 0.80),
	"regiao1_combate": (regiao1_combate, "Regiao I -- camada de intensidade/combate", 0.84),
	"regiao1_guardiao": (regiao1_guardiao, "Regiao I -- guardioes (1-1 a 1-4)", 0.88),
	"regiao1_coracao": (regiao1_coracao, "Regiao I -- Coracao Putrefacto (1-5)", 0.90),
	"pausa_ambiente": (pausa_ambiente, "Pausa/Opcoes", 0.62),
}

IMPORT_WAV = """[remap]

importer="wav"
type="AudioStreamWAV"

[deps]

source_file="res://{res}"

[params]

force/8_bit=false
force/mono=false
force/max_rate=false
force/max_rate_hz=44100
edit/trim=false
edit/normalize=false
edit/loop_mode=2
edit/loop_begin=0
edit/loop_end=-1
compress/mode=2
"""


def sha(caminho: str) -> str:
	h = hashlib.sha256()
	with open(caminho, "rb") as f:
		for bloco in iter(lambda: f.read(1 << 20), b""):
			h.update(bloco)
	return h.hexdigest()


def main(argv) -> int:
	os.makedirs(SAIDA, exist_ok=True)
	pedidas = argv[1:] or list(FAIXAS)
	registo = {}
	if os.path.exists(MANIFESTO):
		with open(MANIFESTO, encoding="utf-8") as f:
			registo = json.load(f).get("faixas", {})
	for nome in pedidas:
		if nome not in FAIXAS:
			print("faixa desconhecida:", nome)
			return 2
		fn, papel, pico = FAIXAS[nome]
		t0 = time.time()
		mix, dur = fn()
		esq, dire = mix.render(rev_tam=1.25, rev_amort=0.33, ciclico=True, pico=pico)
		caminho = os.path.join(SAIDA, nome + ".wav")
		M.escrever_wav(caminho, esq, dire)
		# o .import fica escrito por nos: loop LIGADO no proprio recurso e
		# compressao QOA (senao o PCK do Web leva 40 MB de PCM cru)
		res = os.path.relpath(caminho, RAIZ).replace(os.sep, "/")
		with open(caminho + ".import", "w", encoding="utf-8", newline="\n") as f:
			f.write(IMPORT_WAV.format(res=res))
		tam = os.path.getsize(caminho)
		registo[nome] = {
			"ficheiro": "assets/audio/musica/producao/%s.wav" % nome,
			"papel": papel,
			"duracao_s": round(dur, 3),
			"taxa_hz": M.TAXA,
			"canais": 2,
			"bytes": tam,
			"sha256": sha(caminho),
			"origem": "ORIGINAL -- composto e sintetizado por tools/compor_trilha_9h1.py",
			"licenca": "Propriedade do projecto Koliani (sem terceiros, sem atribuicao devida)",
			"ciclo": True,
		}
		print("%-22s %5.1f s  %6.1f MB  %5.1f s a render" % (
			nome, dur, tam / 1e6, time.time() - t0))
	with open(MANIFESTO, "w", encoding="utf-8", newline="\n") as f:
		json.dump({
			"execucao": "9H.1",
			"o_que_e": "Trilha sonora de producao do frontend e da Regiao I.",
			"proveniencia": "100% original do projecto. Sintese por "
				"tools/motor_musical.py (Python puro). Nenhuma amostra, "
				"gravacao ou composicao de terceiros.",
			"licenca": "Propriedade do projecto Koliani.",
			"atribuicao_devida": "nenhuma",
			"motor": "tools/motor_musical.py",
			"compositor": "tools/compor_trilha_9h1.py",
			"taxa_hz": M.TAXA,
			"faixas": registo,
			"regioes_ii_xx": "Continuam nas 20+20 faixas CC0/CC-BY de "
				"assets/audio/musica/{niveis,chefes} (ver CREDITS.md). Sem "
				"autoridade visual nem playtest, compor 38 faixas seria "
				"exactamente o que o Game Master proibiu.",
		}, f, indent=2, ensure_ascii=False)
	print("manifesto:", os.path.relpath(MANIFESTO, RAIZ))
	return 0


if __name__ == "__main__":
	raise SystemExit(main(sys.argv))
