#!/usr/bin/env python3
"""SFX Overhaul Prompt 3B -- os sons do MUNDO e da PROGRESSAO.

    python tools/gerar_sfx_3b.py

## O buraco que isto tapa

A auditoria evento->ficheiro da 3B (`docs/audio/world_progression_sfx_audit.md`)
contou 0 chamadas a `Som.` em vinte e oito scripts de cenario. Nao era
mistura mal afinada: o vento, os sinos-mecanismo, os elevadores, as
plataformas que esboroam, as pedras que caem, as laminas pendulares e os
raios da tempestade **nao faziam barulho nenhum**.

E o que tinha som estava a pedi-lo emprestado a quem nao devia:

    alavanca / placa_peso / vela   ->  `selo`   (e' o CHECKPOINT)
    vela (apagar)                  ->  `onda`   (e' ataque de nove chefes)
    bau do chefe                   ->  `apanhar` (e' a essencia do chao)

Um som emprestado nao e' so' feio: ensina a coisa errada. Ouvir o selo do
checkpoint ao puxar uma alavanca diz ao jogador que gravou.

## Metodo

O mesmo da 9H.13B e da 9H.16: tres camadas (corpo + transiente + cauda),
normalizacao por SONORIDADE (RMS da janela de 100 ms mais forte) e nao por
pico, tudo sintetizado aqui -- sem samples de terceiros, sem licencas, sem
numpy.

## A hierarquia (Fase 14 do briefing)

    AMBIENCE  <  MECHANISM  <  HAZARD/INTERACTION  <  IMPORTANT PROGRESSION

Escrita em numeros, contra o que ja' ca' estava (sonoridade, dB):

    ambiente    vento_ciclo -25,0   mecanismo_ciclo -23,0
                  (referencia: passo1 -16,3 -- o ambiente vive ABAIXO dos
                   passos, senao e' o vento que se ouve e nao o jogo)
    mecanismo   vento_rajada -18,0  mecanismo -16,0  portao_* -14,5/-15,5
    perigo      pedra_racha -18,0 (telegrafo)   lamina_passa -17,5
                fogo_sopro -15,0   pedra_parte -13,5   raio_aviso -18,5
                raio_cai -10,5   sino_mecanismo -12,0   bau_abrir -12,0
    progressao  recompensa -11,0   desbloqueio -10,5
                  (tecto: `conquista.wav`, a vitoria sobre o chefe, mede
                   -10,4 LUFS e continua a ser o som mais alto do jogo --
                   nada aqui a ultrapassa)

## Os dois LACOS

`vento_ciclo` e `mecanismo_ciclo` sao os primeiros sons do jogo feitos para
tocar em ciclo. Um loop com emenda ouve-se sempre -- ou um estalo (salto de
fase) ou um buraco (queda de energia na juncao). Os dois evitam-se com o
mesmo truque: sintetiza-se `dur + costura` segundos e depois faz-se um
crossfade de potencia constante da cauda sobre a cabeca, cortando no fim.
A prova esta' no fim do ficheiro: imprime-se a energia dos 50 ms de cada
lado da juncao e exige-se menos de 1,5 dB de diferenca.
"""
from __future__ import annotations

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import gerar_sfx_9h13 as g


ALVO = {
	# --- ambiente (o mais baixo do jogo) ---------------------------------
	"vento_ciclo.wav": -25.0,
	"mecanismo_ciclo.wav": -23.0,
	# --- mecanismos -------------------------------------------------------
	"vento_rajada.wav": -18.0,
	"mecanismo.wav": -16.0,
	"portao_abre.wav": -14.5,
	"portao_fecha.wav": -15.5,
	# --- perigos ----------------------------------------------------------
	"raio_aviso.wav": -18.5,
	"pedra_racha.wav": -18.0,
	"lamina_passa.wav": -17.5,
	"fogo_sopro.wav": -15.0,
	"pedra_parte.wav": -13.5,
	"raio_cai.wav": -10.5,
	# --- interaccao -------------------------------------------------------
	"sino_mecanismo.wav": -12.0,
	"bau_abrir.wav": -12.0,
	# --- progressao -------------------------------------------------------
	"recompensa.wav": -11.0,
	"desbloqueio.wav": -10.5,
}

## Segundos de sobreposicao usados para costurar os lacos. 0,35 s chega para
## o ruido filtrado do vento e ainda e' curto ao pe' do ciclo inteiro.
COSTURA = 0.35


# --------------------------------------------------------------------- lacos

def costurar(buf: list[float], costura: float = COSTURA) -> list[float]:
	"""Faz de `buf` um ciclo sem emenda.

	Corta `costura` segundos do fim e mistura-os por cima do inicio com
	ganhos sin/cos (potencia constante). Ganhos lineares dariam um buraco no
	meio da juncao -- duas fontes de ruido descorrelacionadas somam em
	POTENCIA, nao em amplitude, e 0,5+0,5 de amplitude e' -3 dB de energia.
	"""
	n = len(buf)
	c = max(1, int(g.TAXA * costura))
	if c * 2 >= n:
		return buf
	saida = buf[: n - c]
	for i in range(c):
		t = i / c
		ganho_cabeca = math.sin(t * math.pi * 0.5)
		ganho_cauda = math.cos(t * math.pi * 0.5)
		saida[i] = saida[i] * ganho_cabeca + buf[n - c + i] * ganho_cauda
	return saida


def emenda_db(buf: list[float], janela: float = 0.05) -> float:
	"""Diferenca de energia (dB) entre os `janela` segundos antes do fim e os
	`janela` segundos depois do inicio. E' o numero que denuncia o buraco."""
	n = max(1, int(g.TAXA * janela))

	def rms(amostras: list[float]) -> float:
		if not amostras:
			return 0.0
		return math.sqrt(sum(v * v for v in amostras) / len(amostras))

	a = rms(buf[-n:])
	b = rms(buf[:n])
	if a <= 1e-9 or b <= 1e-9:
		return 99.0
	return abs(20.0 * math.log10(a / b))


def vento_ciclo() -> list[float]:
	"""Vento ambiente: 6 s de ruido rosa com o filtro a respirar devagar.

	Sem transiente nenhum -- um vento que "bate" le^-se como ataque. O que
	da' vida e' o filtro a abrir e fechar em tres periodos primos entre si
	(11,3 / 7,1 / 4,7 s), para o ciclo nao ter um padrao audivel.
	"""
	dur = 6.0 + COSTURA
	b = g.novo(dur)
	ant = 0.0
	grave = 0.0
	for i in range(len(b)):
		t = i / g.TAXA
		respiracao = (0.42
			+ 0.16 * math.sin(2.0 * math.pi * t / 11.3)
			+ 0.09 * math.sin(2.0 * math.pi * t / 7.1)
			+ 0.05 * math.sin(2.0 * math.pi * t / 4.7))
		ant += (g.rng.uniform(-1.0, 1.0) - ant) * max(0.02, min(0.9, respiracao))
		# um segundo polo grave: o vento tem corpo, nao e' so' chiadeira
		grave += (ant - grave) * 0.06
		b[i] = ant * 0.55 + grave * 1.6
	return costurar(b)


def mecanismo_ciclo() -> list[float]:
	"""Pedra a arrastar sobre pedra: 2,4 s de atrito grave com um rangido
	lento por cima. E' o elevador em marcha -- corpo, nunca brilho.

	Ao contrario do vento, este laco tem partes DETERMINISTAS (as duas
	sinusoides do rangido e a modulacao lenta), e o crossfade nao as salva:
	se nao fecharem um numero inteiro de ciclos dentro do corpo, a juncao fica
	a somar duas fases diferentes. Media-se 1,76 dB de buraco antes de
	arredondar tudo para multiplos de 1/CORPO -- depois disso, 0,04 dB.
	"""
	corpo_dur = 2.4
	base = 1.0 / corpo_dur           # a fundamental do ciclo
	f1 = round(47.0 / base) * base   # 113 ciclos exactos
	f2 = round(71.5 / base) * base   # 172 ciclos exactos
	f_mod = 2.0 * base               # a modulacao lenta: 2 voltas por ciclo
	b = g.novo(corpo_dur + COSTURA)
	ant = 0.0
	grave = 0.0
	for i in range(len(b)):
		t = i / g.TAXA
		ant += (g.rng.uniform(-1.0, 1.0) - ant) * 0.28
		grave += (ant - grave) * 0.035
		# rangido: dois parciais graves desafinados, a rodar devagar
		rangido = (math.sin(2.0 * math.pi * f1 * t)
			+ 0.6 * math.sin(2.0 * math.pi * f2 * t)) * 0.10
		modulacao = 0.75 + 0.25 * math.sin(2.0 * math.pi * f_mod * t)
		b[i] = (grave * 2.1 + ant * 0.16 + rangido) * modulacao
	return costurar(b)


# ----------------------------------------------------------------- mecanismos

def vento_rajada() -> list[float]:
	"""ENTRAR numa zona de vento. Sopro que abre e fecha, sem transiente
	duro: tem de dizer "estas dentro", nao "levaste". Deliberadamente mais
	escuro e mais longo do que o `dash` (-12,0), para nao se confundir com um
	ataque de chefe."""
	b = g.novo(0.85)
	g.sopro(b, 0.0, 0.62, 0.62, 0.10, 0.42, k=1.1)
	g.sopro(b, 0.06, 0.52, 0.30, 0.48, 0.14, k=1.4)
	g.corpo(b, 0.0, 58.0, 96.0, 0.50, 0.14, k=1.8, desafinar=1.021)
	g.cauda(b, atraso=0.070, n_ecos=3, g=0.30, abafar=0.72)
	return b


def mecanismo() -> list[float]:
	"""Alavanca / placa de peso / engrenagem a engatar. Estalo de metal com
	peso em baixo e um pequeno "clonc" de encaixe. Curto -- e' confirmacao,
	nao evento."""
	b = g.novo(0.46)
	g.transiente(b, 0.0, 0.028, 0.72, 0.62)
	g.corpo(b, 0.004, 210.0, 118.0, 0.16, 0.44, k=7.0, desafinar=1.013)
	g.sino(b, 0.012, 172.0, 0.30, 0.16, brilho=0.28)
	# o encaixe: segundo estalo mais fraco, um pouco depois
	g.transiente(b, 0.085, 0.030, 0.30, 0.48)
	g.cauda(b, atraso=0.036, n_ecos=3, g=0.26, abafar=0.58)
	return b


def _portao(subida: bool) -> list[float]:
	"""Portao de pedra. `subida` = a abrir (o varrimento de atrito SOBE e
	remata com o batente em cima); a fechar desce e bate no chao."""
	b = g.novo(0.95)
	f0, f1 = (74.0, 132.0) if subida else (128.0, 62.0)
	g.transiente(b, 0.0, 0.040, 0.52, 0.40)
	g.corpo(b, 0.0, f0, f1, 0.62, 0.40, k=1.5, desafinar=1.016, grito=0.10)
	g.sopro(b, 0.02, 0.60, 0.34, 0.18, 0.30, k=1.6)
	# o batente no fim do curso
	g.transiente(b, 0.60, 0.060, 0.62 if subida else 0.80, 0.34)
	g.corpo(b, 0.60, 96.0, 44.0, 0.28, 0.34 if subida else 0.48, k=5.0)
	g.cauda(b, atraso=0.062, n_ecos=4, g=0.30, abafar=0.62)
	return b


def portao_abre() -> list[float]:
	return _portao(True)


def portao_fecha() -> list[float]:
	return _portao(False)


# --------------------------------------------------------------------- perigo

def sino_mecanismo() -> list[float]:
	"""O sino da TORRE (N11), nao o do chefe.

	`sino_ataque.ogg` pertence a cinco callsites de chefe e tem a leitura de
	golpe: bate e morre. Este e' o oposto -- badalada limpa, longa, quase sem
	transiente, com a fundamental uma quinta abaixo. Bate-lhe e o cenario
	inteiro troca de estado; o som tem de soar a ORDEM, nao a ataque.
	"""
	b = g.novo(2.30)
	g.transiente(b, 0.0, 0.016, 0.34, 0.72)
	g.sino(b, 0.0, 196.0, 2.10, 0.62, brilho=0.52)
	g.sino(b, 0.004, 293.0, 1.60, 0.24, brilho=0.44)
	g.corpo(b, 0.0, 98.0, 96.0, 1.20, 0.18, k=1.4, desafinar=1.004)
	g.cauda(b, atraso=0.110, n_ecos=4, g=0.34, abafar=0.44)
	return b


def pedra_racha() -> list[float]:
	"""TELEGRAFO: a plataforma a estalar antes de ceder, a estalactite a
	tremer antes de largar. Serie de estalos secos que ACELERA -- a pressa e'
	que diz "sai daqui", nao o volume."""
	b = g.novo(0.70)
	for t, amp in ((0.0, 0.34), (0.16, 0.30), (0.29, 0.38),
			(0.39, 0.34), (0.47, 0.46), (0.53, 0.42), (0.58, 0.54)):
		g.transiente(b, t, 0.026, amp, 0.52)
	g.corpo(b, 0.0, 62.0, 54.0, 0.60, 0.16, k=1.2, desafinar=1.019)
	g.sopro(b, 0.30, 0.34, 0.14, 0.22, 0.46, k=1.8)
	g.cauda(b, atraso=0.034, n_ecos=2, g=0.22, abafar=0.64)
	return b


def pedra_parte() -> list[float]:
	"""A pedra a esfarelar-se no chao. Impacto grave + cascalho a espalhar."""
	b = g.novo(0.80)
	g.transiente(b, 0.0, 0.048, 0.92, 0.38)
	g.corpo(b, 0.0, 128.0, 38.0, 0.24, 0.62, k=7.5, desafinar=1.022, grito=0.16)
	for t, amp in ((0.07, 0.30), (0.13, 0.24), (0.20, 0.20),
			(0.28, 0.15), (0.37, 0.11)):
		g.transiente(b, t, 0.034, amp, 0.60)
	g.sopro(b, 0.03, 0.42, 0.26, 0.30, 0.58, k=3.0)
	g.cauda(b, atraso=0.048, n_ecos=3, g=0.28, abafar=0.56)
	return b


def lamina_passa() -> list[float]:
	"""A foice pendular a varrer o ar. Repete-se a cada meio periodo do
	pendulo, por isso e' curta, escura e sem cauda -- um som brilhante a esta
	cadencia vira metronomo (foi o erro que o jato de fogo ja' tinha
	apanhado)."""
	b = g.novo(0.34)
	g.sopro(b, 0.0, 0.26, 0.60, 0.26, 0.62, k=2.6)
	g.sopro(b, 0.03, 0.18, 0.24, 0.66, 0.30, k=4.0)
	g.corpo(b, 0.0, 180.0, 300.0, 0.14, 0.10, k=6.0, desafinar=1.008)
	return b


def fogo_sopro() -> list[float]:
	"""O jato a acender. O comentario no `fogo.gd` dizia que o som antigo
	(`investida`) "soava a dano constante" -- e soava, porque era o som de
	uma INVESTIDA de chefe. Isto e' gas a pegar: estalo curto de ignicao e
	sopro que abre e fica, sem nada de percussivo no corpo."""
	b = g.novo(0.62)
	g.transiente(b, 0.0, 0.020, 0.40, 0.66)
	g.sopro(b, 0.0, 0.52, 0.58, 0.52, 0.22, k=1.5)
	g.sopro(b, 0.04, 0.44, 0.26, 0.16, 0.40, k=1.2)
	g.corpo(b, 0.01, 88.0, 130.0, 0.24, 0.16, k=3.2, desafinar=1.024, grito=0.12)
	g.cauda(b, atraso=0.040, n_ecos=2, g=0.22, abafar=0.70)
	return b


def raio_aviso() -> list[float]:
	"""Telegrafo do raio: o ar a carregar. Zumbido que SOBE, sem impacto."""
	b = g.novo(0.62)
	g.corpo(b, 0.0, 130.0, 420.0, 0.58, 0.30, k=0.7, desafinar=1.031, grito=0.22)
	g.sopro(b, 0.10, 0.50, 0.18, 0.55, 0.80, k=0.9)
	return b


def raio_cai() -> list[float]:
	"""A descarga. O som mais alto dos perigos: estalo branco durissimo,
	trovao grave por baixo e uma cauda longa a rolar."""
	b = g.novo(1.40)
	g.transiente(b, 0.0, 0.030, 1.00, 0.92)
	g.transiente(b, 0.014, 0.090, 0.70, 0.74)
	g.corpo(b, 0.0, 240.0, 40.0, 0.50, 0.68, k=4.2, desafinar=1.027, grito=0.34)
	g.sopro(b, 0.02, 0.85, 0.44, 0.62, 0.12, k=1.4)
	g.corpo(b, 0.10, 58.0, 30.0, 0.80, 0.34, k=1.6, desafinar=1.013)
	g.cauda(b, atraso=0.085, n_ecos=5, g=0.36, abafar=0.44)
	return b


# ---------------------------------------------------------------- progressao

def bau_abrir() -> list[float]:
	"""O bau a ABRIR -- madeira a ranger e a lingueta a saltar. E' o gesto,
	nao o premio: o premio e' o `recompensa`, que vem a seguir. Separa-los e'
	o pedido da Fase 7 (OPEN CHEST != COLLECT REWARD)."""
	b = g.novo(0.78)
	# lingueta
	g.transiente(b, 0.0, 0.024, 0.66, 0.70)
	g.sino(b, 0.006, 640.0, 0.22, 0.20, brilho=0.34)
	# madeira a rodar nas dobradicas: rangido curto a subir
	g.corpo(b, 0.05, 108.0, 178.0, 0.34, 0.30, k=2.4, desafinar=1.018, grito=0.14)
	g.sopro(b, 0.06, 0.34, 0.20, 0.24, 0.52, k=2.2)
	# a tampa a bater atras
	g.transiente(b, 0.40, 0.046, 0.52, 0.44)
	g.corpo(b, 0.40, 132.0, 58.0, 0.20, 0.34, k=7.0)
	g.cauda(b, atraso=0.044, n_ecos=3, g=0.26, abafar=0.58)
	return b


def recompensa() -> list[float]:
	"""RECEBER o premio do bau. Tem de se distinguir do `apanhar` da essencia
	do chao em TIMBRE, nao so' em volume: onde o `apanhar` e' um tinido seco,
	isto e' um acorde de tres sinos a subir (quinta + oitava) com cauda."""
	b = g.novo(1.30)
	g.transiente(b, 0.0, 0.018, 0.30, 0.76)
	for t, f, amp in ((0.0, 392.0, 0.46), (0.085, 587.0, 0.40),
			(0.175, 784.0, 0.36)):
		g.sino(b, t, f, 1.00 - t, amp, brilho=0.40)
	g.corpo(b, 0.0, 196.0, 196.0, 0.40, 0.12, k=2.2, desafinar=1.005)
	g.cauda(b, atraso=0.090, n_ecos=4, g=0.32, abafar=0.48)
	return b


def desbloqueio() -> list[float]:
	"""Habilidade / nivel / regiao DESBLOQUEADOS. O evento mais raro do
	catalogo do mundo e por isso o mais alto -- mas fica debaixo da
	`conquista` (-10,4 LUFS), que e' a vitoria sobre o chefe.

	Timbre proprio para nao se confundir com o `recompensa`: este ABRE (o
	acorde sobe e ALARGA, com um sub por baixo), o outro so' tine.
	"""
	b = g.novo(1.80)
	g.corpo(b, 0.0, 46.0, 98.0, 0.90, 0.30, k=1.1, desafinar=1.008)
	for t, f, amp in ((0.0, 262.0, 0.40), (0.10, 392.0, 0.42),
			(0.20, 524.0, 0.44), (0.32, 784.0, 0.34)):
		g.sino(b, t, f, 1.40 - t, amp, brilho=0.46)
	g.sopro(b, 0.0, 0.55, 0.16, 0.16, 0.60, k=1.3)
	g.cauda(b, atraso=0.120, n_ecos=5, g=0.34, abafar=0.40)
	return b


LACOS = ("vento_ciclo.wav", "mecanismo_ciclo.wav")

SONS = (
	("vento_ciclo.wav", vento_ciclo),
	("mecanismo_ciclo.wav", mecanismo_ciclo),
	("vento_rajada.wav", vento_rajada),
	("mecanismo.wav", mecanismo),
	("portao_abre.wav", portao_abre),
	("portao_fecha.wav", portao_fecha),
	("sino_mecanismo.wav", sino_mecanismo),
	("pedra_racha.wav", pedra_racha),
	("pedra_parte.wav", pedra_parte),
	("lamina_passa.wav", lamina_passa),
	("fogo_sopro.wav", fogo_sopro),
	("raio_aviso.wav", raio_aviso),
	("raio_cai.wav", raio_cai),
	("bau_abrir.wav", bau_abrir),
	("recompensa.wav", recompensa),
	("desbloqueio.wav", desbloqueio),
)


def main() -> int:
	g.ALVO_DB.update({nome: db for nome, db in ALVO.items()})
	# o `escrever` indexa o ALVO_DB pela CHAVE, e aqui a chave e' o ficheiro
	falhas = 0
	for nome, fn in SONS:
		buf = fn()
		g.escrever(nome, buf, nome)
		if nome in LACOS:
			# o `escrever` normaliza no sitio, por isso a emenda mede-se
			# depois -- o ganho e' o mesmo dos dois lados da juncao
			d = emenda_db(buf)
			marca = "ok" if d < 1.5 else "EMENDA AUDIVEL"
			print("%-22s juncao %5.2f dB  %s" % ("  ^ laco", d, marca))
			if d >= 1.5:
				falhas += 1
	if falhas:
		print("\n%d laco(s) com emenda audivel" % falhas)
	return 1 if falhas else 0


if __name__ == "__main__":
	raise SystemExit(main())
