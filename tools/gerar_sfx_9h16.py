#!/usr/bin/env python3
"""Execution 9H.16 E4 -- os sons das MECANICAS do nivel 1.

    python tools/gerar_sfx_9h16.py

A auditoria evento->ficheiro do L1 (9H.16 E4) deu um buraco que nenhuma
afinacao de mistura resolvia: as DUAS mecanicas-assinatura da Regiao I nao
tinham som nenhum.

    scripts/raiz_perigo.gd        0 chamadas a `Som.`
    scripts/plataforma_ritmada.gd 0 chamadas a `Som.`

Uma armadilha que irrompe do chao sem fazer barulho nao se pode ler pelo
ouvido -- o telegrafo era so' visual, e quem estivesse a olhar para o
inimigo levava com ela. O mesmo para a plataforma que nasce e some.

Metodo: o da 9H.13B -- tres camadas (corpo + transiente + cauda), nada de
senoide a descoberto, e normalizacao por SONORIDADE (RMS da janela de
100 ms mais forte) e nao por pico. Tudo sintetizado aqui, sem samples de
terceiros e sem servicos pagos.

A hierarquia escolhida, contra o que ja' ca' estava:

    raiz_irrompe   -13,5 dB   e' um PERIGO: tem de passar a' frente dos
                              passos e ficar a par do `dano` (-11,3)
    raiz_aviso     -21,0 dB   telegrafo: ouve-se, nao tapa o combate
    plataforma_surge -19,5 dB cenario ritmado; repete-se muito, fica em
                              baixo mas audivel (referencia: passo1 -16,3)
"""
from __future__ import annotations

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import gerar_sfx_9h13 as g


ALVO = {
	"raiz_irrompe.wav": -13.5,
	"raiz_aviso.wav": -21.0,
	"plataforma_surge.wav": -19.5,
}


def raiz_irrompe() -> list[float]:
	"""Madeira a rachar + terra a abrir. Estalo seco, corpo grave curto que
	SOBE (a raiz vem de baixo) e cauda de detritos."""
	b = g.novo(0.62)
	# estalo da casca: transiente escuro, quase sem brilho
	g.transiente(b, 0.0, 0.035, 0.95, 0.22)
	# a raiz a subir: varrimento ASCENDENTE com grito (fibra a torcer)
	g.corpo(b, 0.005, 68.0, 190.0, 0.26, 0.72, k=3.2, desafinar=1.017, grito=0.45)
	# terra a abrir-se
	g.sopro(b, 0.0, 0.30, 0.55, 0.08, 0.55, k=3.4)
	# detritos a cair
	g.transiente(b, 0.20, 0.14, 0.28, 0.62)
	g.transiente(b, 0.29, 0.10, 0.18, 0.70)
	g.cauda(b, atraso=0.052, n_ecos=3, g=0.30, abafar=0.62)
	return b


def raiz_aviso() -> list[float]:
	"""Telegrafo: a terra a estalar baixinho e um ringer de fibra a esticar.
	Sobe de intensidade -- e' a deixa para sair de cima."""
	b = g.novo(0.55)
	for i, t in enumerate((0.0, 0.14, 0.26, 0.36, 0.44)):
		g.transiente(b, t, 0.03, 0.16 + 0.07 * i, 0.45)
	g.corpo(b, 0.02, 44.0, 76.0, 0.50, 0.30, k=1.6, desafinar=1.011, grito=0.18)
	g.sopro(b, 0.10, 0.42, 0.22, 0.30, 0.70, k=1.4)
	g.cauda(b, atraso=0.040, n_ecos=2, g=0.26, abafar=0.7)
	return b


def plataforma_surge() -> list[float]:
	"""Raiz-plataforma a nascer: range de madeira verde, curto e macio. Sem
	estalo duro -- repete-se de segundos a segundos e um transiente afiado
	a esta cadencia vira metronomo."""
	b = g.novo(0.40)
	g.transiente(b, 0.0, 0.022, 0.34, 0.30)
	g.corpo(b, 0.0, 96.0, 172.0, 0.22, 0.52, k=4.2, desafinar=1.009, grito=0.12)
	g.sopro(b, 0.01, 0.24, 0.26, 0.20, 0.62, k=3.8)
	g.cauda(b, atraso=0.038, n_ecos=2, g=0.24, abafar=0.66)
	return b


def main() -> None:
	g.ALVO_DB.update(ALVO)
	for nome, fn in (
			("raiz_irrompe.wav", raiz_irrompe),
			("raiz_aviso.wav", raiz_aviso),
			("plataforma_surge.wav", plataforma_surge)):
		g.escrever(nome, fn(), nome)


if __name__ == "__main__":
	main()
