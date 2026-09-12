#!/usr/bin/env python3
"""Execution 9H -- passe de audio do frontend e da ambiencia da Regiao I.

    python tools/gerar_audio_9h.py

O Game Master pediu um refresh global do som: "mudar soundtrack completa,
musicas, sons, menus, animacoes, combate". O que se pode fazer AQUI, sem
licencas de terceiros, e' o que esta' neste ficheiro -- tudo sintetizado,
tudo nosso, na direcao dark-fantasy do rebrand (carmesim sobre carvao):

  ui_mover.wav      mover no menu/mapa: sopro curto com um harmonico de
                    sino por cima. Substitui o `carrossel`, que era um
                    clique seco de interface e destoava do ecra novo.
  ui_confirmar.wav  confirmar: dois toques de sino em quinta ascendente,
                    com cauda -- le^-se como "porta a abrir", nao como "ok".
  ui_voltar.wav     recuar: o mesmo, descendente e mais curto.
  ui_negado.wav     nivel trancado: golpe abafado, sem brilho nenhum.
  ambiente_floresta.wav
                    cama de ambiencia da Regiao I (loop de 20 s): vento nas
                    folhas (ruido filtrado a variar), agua ao longe, e um
                    bordao muito grave de corrupcao a pulsar. Vai POR BAIXO
                    da musica, a -24 dB -- e' o chao do quadro, nao musica.

O QUE NAO ESTA' AQUI, e porque: as 40 faixas de musica (20 de nivel + 20 de
chefe) sao pecas compostas, com licenca, em `assets/audio/musica/`.
Substitui-las por sintese seria trocar musica a serio por bordoes -- pior,
nao melhor. Fica marcado como PRODUCTION AUDIO MISSING no relatorio da 9H.

Sem numpy, sem samples de terceiros. Espelha o metodo do
`tools/gerar_audio.py` (o mesmo `escrever`, a mesma taxa).
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


def escrever(nome: str, buf: list[float], ganho: float = 0.92) -> None:
	pico = max((abs(v) for v in buf), default=1.0) or 1.0
	k = ganho / pico
	dados = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * k)) * 32767)) for v in buf)
	caminho = os.path.join(SAIDA, nome)
	with wave.open(caminho, "wb") as w:
		w.setnchannels(1)
		w.setsampwidth(2)
		w.setframerate(TAXA)
		w.writeframes(dados)
	print("%-26s %5.2f s" % (nome, len(buf) / TAXA))


def env(i: int, n: int, ataque: float, queda: float) -> float:
	"""Envelope ataque/queda simples, em fracoes do comprimento."""
	t = i / max(n - 1, 1)
	if t < ataque:
		return t / max(ataque, 1e-6)
	s = (t - ataque) / max(1.0 - ataque, 1e-6)
	return math.exp(-s * queda)


def sino(buf: list[float], t0: float, f: float, dur: float, amp: float,
		brilho: float = 0.45) -> None:
	"""Toque de sino: fundamental + duas parciais inarmonicas (2,76 e 5,40 --
	as de um sino real), cada uma a decair mais depressa que a anterior."""
	n = int(dur * TAXA)
	i0 = int(t0 * TAXA)
	for i in range(n):
		if i0 + i >= len(buf):
			break
		t = i / TAXA
		v = math.sin(TAU * f * t) * math.exp(-t * 3.0)
		v += brilho * math.sin(TAU * f * 2.76 * t) * math.exp(-t * 5.5)
		v += brilho * 0.5 * math.sin(TAU * f * 5.40 * t) * math.exp(-t * 9.0)
		buf[i0 + i] += v * amp


TAU = math.tau


def sopro(buf: list[float], t0: float, dur: float, amp: float, corte: float,
		rng: random.Random) -> None:
	"""Ruido passa-baixo de um polo -- o "ar" dos sons de interface."""
	n = int(dur * TAXA)
	i0 = int(t0 * TAXA)
	a = math.exp(-TAU * corte / TAXA)
	y = 0.0
	for i in range(n):
		if i0 + i >= len(buf):
			break
		y = a * y + (1.0 - a) * (rng.random() * 2.0 - 1.0)
		buf[i0 + i] += y * amp * env(i, n, 0.06, 5.0)


# --------------------------------------------------------------------------
# vozes de interface
# --------------------------------------------------------------------------
def ui_mover() -> None:
	rng = random.Random(9101)
	n = int(0.18 * TAXA)
	buf = [0.0] * n
	sopro(buf, 0.0, 0.10, 0.22, 2200.0, rng)
	sino(buf, 0.004, 1180.0, 0.16, 0.30, 0.30)
	escrever("ui_mover.wav", buf, 0.55)


def ui_confirmar() -> None:
	n = int(0.95 * TAXA)
	buf = [0.0] * n
	# quinta ascendente (A3 -> E4), com a cauda do segundo toque a ficar
	sino(buf, 0.0, 220.0, 0.55, 0.42, 0.40)
	sino(buf, 0.075, 330.0, 0.85, 0.50, 0.48)
	sino(buf, 0.075, 660.0, 0.40, 0.16, 0.60)
	escrever("ui_confirmar.wav", buf, 0.78)


def ui_voltar() -> None:
	n = int(0.55 * TAXA)
	buf = [0.0] * n
	sino(buf, 0.0, 330.0, 0.34, 0.38, 0.35)
	sino(buf, 0.060, 220.0, 0.45, 0.42, 0.30)
	escrever("ui_voltar.wav", buf, 0.66)


def ui_negado() -> None:
	rng = random.Random(9102)
	n = int(0.36 * TAXA)
	buf = [0.0] * n
	# sem brilho: fundamental grave batida, ruido escuro, nada de parciais
	for i in range(n):
		t = i / TAXA
		buf[i] += math.sin(TAU * 98.0 * t) * math.exp(-t * 11.0) * 0.75
		buf[i] += math.sin(TAU * 73.0 * t) * math.exp(-t * 14.0) * 0.45
	sopro(buf, 0.0, 0.14, 0.30, 420.0, rng)
	escrever("ui_negado.wav", buf, 0.72)


# --------------------------------------------------------------------------
# ambiencia da Regiao I
# --------------------------------------------------------------------------
def ambiente_floresta() -> None:
	"""Vento + agua ao longe + bordao de corrupcao. 20 s, com as pontas
	cruzadas para o ciclo nao marcar (a cama toca em loop; um fade-out seria
	um buraco -- ver a nota do `Musica`)."""
	rng = random.Random(9103)
	dur = 20.0
	n = int(dur * TAXA)
	buf = [0.0] * n

	# vento: ruido passa-baixo com o corte a respirar entre 300 e 1400 Hz
	y = 0.0
	for i in range(n):
		t = i / TAXA
		corte = 850.0 + 550.0 * math.sin(TAU * t / 11.0) + 180.0 * math.sin(TAU * t / 3.7)
		a = math.exp(-TAU * max(corte, 80.0) / TAXA)
		y = a * y + (1.0 - a) * (rng.random() * 2.0 - 1.0)
		respira = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(TAU * t / 8.5))
		buf[i] += y * 0.42 * respira

	# agua ao longe: ruido de banda estreita, quase constante
	y2 = 0.0
	y3 = 0.0
	for i in range(n):
		r = rng.random() * 2.0 - 1.0
		y2 = 0.86 * y2 + 0.14 * r          # passa-baixo
		y3 = 0.72 * y3 + 0.28 * (r - y2)   # passa-alto do que sobrou
		buf[i] += y3 * 0.16

	# bordao de corrupcao: duas quintas muito graves a bater uma na outra
	for i in range(n):
		t = i / TAXA
		pulso = 0.5 + 0.5 * math.sin(TAU * t / 6.2)
		buf[i] += math.sin(TAU * 55.0 * t) * 0.20 * pulso
		buf[i] += math.sin(TAU * 82.41 * t) * 0.11 * pulso
		# terceira harmonica fraca, so' para o bordao nao ser um seno limpo
		buf[i] += math.sin(TAU * 164.81 * t + 0.7) * 0.035 * pulso

	# estalos de mata: raros, curtos, espalhados
	for _ in range(26):
		t0 = rng.uniform(0.2, dur - 0.6)
		i0 = int(t0 * TAXA)
		m = int(rng.uniform(0.01, 0.05) * TAXA)
		amp = rng.uniform(0.05, 0.16)
		for i in range(m):
			if i0 + i >= n:
				break
			buf[i0 + i] += (rng.random() * 2.0 - 1.0) * amp * math.exp(-i / (m * 0.35))

	# cruzamento das pontas: 1,5 s do fim somados ao inicio, em rampa
	m = int(1.5 * TAXA)
	for i in range(m):
		k = i / m
		buf[i] = buf[i] * k + buf[n - m + i] * (1.0 - k)
	del buf[n - m:]
	escrever("ambiente_floresta.wav", buf, 0.62)


def main() -> int:
	if not os.path.isdir(SAIDA):
		print("FALHA: falta", SAIDA)
		return 1
	ui_mover()
	ui_confirmar()
	ui_voltar()
	ui_negado()
	ambiente_floresta()
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
