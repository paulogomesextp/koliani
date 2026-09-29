#!/usr/bin/env python3
"""SFX Overhaul Prompt 4 -- tirar o clipping objetivo de tres assets.

    python tools/corrigir_clipping_p4.py                     # mede e corrige
    python tools/corrigir_clipping_p4.py --medir             # so' mede
    python tools/corrigir_clipping_p4.py --forcar X.ogg      # aceita X fora
                                                             # da tolerancia

## O defeito

Tres samples CC0 do catalogo DESCODIFICAM ACIMA DE 0 dBFS:

    esmagar.ogg        pico  +7,26 dBFS   RMS -20,8   16 callsites
    golpe_pesado.ogg   pico  +9,63 dBFS   RMS -20,2   11 callsites
    grito.ogg          pico  +1,90 dBFS   RMS -16,0    4 callsites

Nao se via com `volumedetect`, que mede depois de cortar a int16 e por isso
dizia "0,0 dB" -- parecia um ficheiro no tecto, e era um ficheiro POR CIMA
do tecto. Quem mostra o valor a serio e' `astats`, que le a descodificacao
em virgula flutuante.

E' proprio do Vorbis: o codificador pode devolver amostras acima de 1,0 se o
sinal original ja' estava rente ao tecto. O Godot descodifica para float,
soma no bus e so' corta no fim -- e os dois piores estao nos callsites a
-5/-6 dB, ou seja chegam ao master a +3,6 dBFS. Sao os dois ataques de chefe
mais usados do jogo inteiro a distorcer.

## Porque e' um LIMITADOR e nao um ganho

A tentacao e' meter -8 dB de compensacao no `Som.COMPENSACAO`. Nao serve: o
ficheiro nao esta' alto, esta' PICUDO. A crista (pico menos RMS) e' de 28 dB
no `esmagar` -- o excesso e' um transiente unico, e o corpo do som vive 20 dB
abaixo. Baixar tudo 8 dB arrumava o pico e tornava o golpe inaudivel, o que
seria uma mudanca de mistura (subjetiva) e nao uma correccao (objetiva).

Um limitador com antecipacao morde SO' no transiente -- e o transiente e'
mesmo isolado. Medido:

    esmagar        107 amostras acima de 1,0, todas dentro de 18 ms (2% do ficheiro)
    golpe_pesado    36 amostras, todas dentro de  3 ms (1%)
    grito           13 amostras, todas dentro de 11 ms (1%)

## O criterio de aceitacao (e porque e' que o obvio esta' errado)

A 1.a tentativa exigiu que o LUFS integrado nao mexesse mais de 0,5 dB. Os
ficheiros falharam por 2,7 e 3,5 dB -- e o criterio e' que estava errado,
nao o limitador.

Estes sons sao quase silencio com um golpe: no `esmagar` a mediana das
amostras e' 0,002 e o maximo e' 2,308. Esse transiente E' praticamente toda
a energia do ficheiro, portanto domina o RMS e domina o bloco de 400 ms que
o EBU R128 usa. Baixar um pico de +9,6 dB para -1 dB TEM de mover essas
medidas muito, por construcao.

So' que o jogador nunca ouviu esses +9,6 dB. O motor descodifica para float,
soma, e CORTA no fim -- o que sai hoje pelas colunas ja' e' o sinal ceifado
a 0 dBFS, com a distorcao harmonica que isso traz. A referencia honesta nao
e' o float cru (que e' irreproduzivel); e' o MESMO ficheiro ceifado, que e'
o que se ouve hoje.

E' contra essa referencia que se mede. Assim a pergunta passa a ser a certa:
"depois de tirar a distorcao, o golpe ficou com o mesmo peso?" -- e a
resposta tem de ser sim a menos de 0,5 dB, tanto em LUFS como em SONORIDADE
(RMS da janela de 100 ms mais forte, a medida que o projecto ja' usa em
`gerar_sfx_9h13.py` por ser a que acompanha o ouvido).

## E porque e' preciso ganho de compensacao

So' limitar nao chega, e mediu-se: contra o ficheiro ceifado, o `esmagar`
perdia 1,81 dB de sonoridade e o `golpe_pesado` 1,60 dB. Faz sentido -- um
sinal ceifado tem o topo CHATO em 1,0 durante 107 amostras, e isso e' mais
energia do que a mesma onda limitada com uma rampa. Tirar a distorcao tira
tambem esse peso emprestado.

1,7 dB nos dois ataques de chefe mais usados do jogo ja' se ouve, e mudar o
peso de um som e' decisao humana, nao tecnica. A saida nao e' escolher entre
distorcao e um som mais fraco: e' limitar E repor o nivel. Aplica-se ganho,
limita-se, mede-se a sonoridade contra a referencia e repete-se ate' fechar.
Converge em duas ou tres voltas porque o corpo do som vive 20 dB abaixo do
pico -- levantar o corpo 1,7 dB nao o poe ao pe' do tecto.

Assim a correccao e' neutra em volume POR CONSTRUCAO: o que muda e' so' a
distorcao, que desaparece.

## O `esmagar` NAO passa -- e fica por decidir

Dos tres, dois fecham dentro da tolerancia:

    golpe_pesado   +2,69 dB de compensacao   dLUFS -0,30   dSON -0,09   OK
    grito          +0,42 dB                  dLUFS +0,40   dSON -0,05   OK
    esmagar        +4,88 dB                  dLUFS -1,40   dSON -0,48   RECUSADO

O `esmagar` e' o caso dificil: o excesso nao e' um pico, sao SETE rajadas
espalhadas por 18 ms. Para repor a sonoridade sao precisos +4,88 dB, e a
esse nivel o limitador passa a morder 451 amostras em vez de 107 -- ja' nao
e' cirurgico, e o LUFS integrado cai 1,40 dB.

Nao se forca. A regra do Prompt 4 e' clara: o que muda o que se OUVE mais do
que a tolerancia e' decisao do Paulo, nao do script. Fica medido e fica a um
comando de distancia:

    python tools/corrigir_clipping_p4.py --forcar esmagar.ogg

Ate' la' o `esmagar` continua como esta': a distorcer a +7,26 dBFS nos seus
16 callsites, exactamente como ja' distorcia antes deste overhaul.

## O que NAO se corrige aqui

`raio.wav` tem 238 amostras coladas ao tecto (0,096% de 247 475) e um flat
factor de 10,6: ja' vem CLIPADO de origem. Um limitador nao desfaz o que ja'
foi cortado -- so' re-sintetizar, e isso e' redesenho, que este prompt proibe.
E' tocado entre -8 e -15 dB, portanto nunca chega ao tecto do master.
Fica documentado para HUMAN LISTEN e nao se lhe toca.
"""
from __future__ import annotations

import math
import os
import re
import shutil
import struct
import subprocess
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO = os.path.join(RAIZ, "assets", "audio")

CANDIDATOS = [os.path.join(os.environ.get("LOCALAPPDATA", ""), "Microsoft",
	"WinGet", "Packages",
	"Gyan.FFmpeg.Essentials_Microsoft.Winget.Source_8wekyb3d8bbwe",
	"ffmpeg-9.0.1-essentials_build", "bin")]


def achar(exe: str) -> str:
	a = shutil.which(exe)
	if a:
		return a
	for p in CANDIDATOS:
		c = os.path.join(p, exe + ".exe")
		if os.path.exists(c):
			return c
	raise SystemExit("falta %s no PATH" % exe)


FFMPEG = achar("ffmpeg")
FFPROBE = achar("ffprobe")

## Tecto de saida. -1,0 dBFS deixa margem para o codificador Vorbis voltar a
## ultrapassar um bocadinho na re-codificacao (e volta -- e' o mesmo efeito
## que criou o problema) sem chegar outra vez a 0.
TECTO_DB = -1.0
TECTO = 10.0 ** (TECTO_DB / 20.0)

## Largura da janela em que o limitador espalha cada reducao de ganho. 6 ms
## e' curto o suficiente para nao tocar no corpo do som (o excesso vive em
## menos de 0,5% das amostras) e largo o suficiente para a rampa nao se ouvir
## como estalo.
JANELA_MS = 6.0

## Fraccao do erro corrigida em cada volta da procura de ganho. 1,0 (o passo
## inteiro) oscila: subir o ganho alarga a mordida do limitador, que baixa a
## sonoridade, que pede mais ganho.
AMORTECIMENTO = 0.5

## Quantos dB o LUFS integrado pode mexer. Acima disto deixa de ser uma
## correccao de pico e passa a ser mistura -- e o script recusa.
TOLERANCIA_LUFS = 0.5

ALVOS = ("esmagar.ogg", "golpe_pesado.ogg", "grito.ogg")


def sondar(f: str) -> dict:
	cam = os.path.join(AUDIO, f)
	j = subprocess.run([FFPROBE, "-v", "error", "-show_entries",
		"stream=sample_rate,channels", "-of", "csv=p=0", cam],
		capture_output=True, text=True).stdout.strip().split("\n")[0]
	sr, ch = (int(x) for x in j.split(","))
	st = subprocess.run([FFMPEG, "-hide_banner", "-i", cam,
		"-af", "astats=measure_perchannel=0", "-f", "null", "-"],
		capture_output=True, text=True).stderr
	pico = float(re.search(r"Peak level dB:\s*(-?[\d.]+)", st).group(1))
	rms = float(re.search(r"RMS level dB:\s*(-?[\d.]+)", st).group(1))
	eb = subprocess.run([FFMPEG, "-hide_banner", "-i", cam,
		"-af", "ebur128", "-f", "null", "-"],
		capture_output=True, text=True).stderr
	lufs = float(re.search(r"I:\s*(-?[\d.]+) LUFS",
		eb.rsplit("Integrated loudness", 1)[1]).group(1))
	return {"sr": sr, "ch": ch, "pico": pico, "rms": rms, "lufs": lufs}


def sonoridade(amostras: list[float], canais: int, sr: int) -> float:
	"""RMS da janela de 100 ms mais forte, em dB -- a medida que acompanha o
	ouvido em sons curtos (a mesma de `tools/gerar_sfx_9h13.py`)."""
	n = len(amostras) // canais
	jan = max(1, int(sr * 0.1))
	if n <= jan:
		soma = sum(v * v for v in amostras)
		return 10.0 * math.log10(max(1e-12, soma / max(1, len(amostras))))
	# soma corrida dos quadrados (mistura os canais: e' o que sai no master)
	quad = [sum(amostras[i * canais + c] ** 2 for c in range(canais)) / canais
		for i in range(n)]
	corrente = sum(quad[:jan])
	melhor = corrente
	for i in range(jan, n):
		corrente += quad[i] - quad[i - jan]
		if corrente > melhor:
			melhor = corrente
	return 10.0 * math.log10(max(1e-12, melhor / jan))


def ceifar(amostras: list[float]) -> list[float]:
	"""O sinal como o motor o entrega HOJE: cortado a direito em +-1,0.
	E' esta a referencia contra a qual o resultado e' julgado."""
	return [max(-1.0, min(1.0, v)) for v in amostras]


def ler_float(f: str) -> list[float]:
	cru = subprocess.run([FFMPEG, "-v", "error", "-i",
		os.path.join(AUDIO, f), "-f", "f32le", "-acodec", "pcm_f32le", "-"],
		capture_output=True).stdout
	return list(struct.unpack("<%df" % (len(cru) // 4), cru))


def limitar(amostras: list[float], canais: int, sr: int) -> tuple[list[float], int]:
	"""Limitador de pico com ANTECIPACAO, feito para transientes isolados.

	Nao e' um `clamp`: cortar a direito gera harmonicos duros, que e'
	exactamente o som que estamos a tirar.

	A 1.a versao usou um limitador classico (ataque instantaneo, libertacao de
	40 ms) e arruinou os ficheiros -- o `golpe_pesado` perdeu 6,7 LUFS. A
	razao e' a forma destes sons: 28 dB de crista, com o excesso concentrado
	em 47 a 161 amostras num ficheiro de 21 000 a 52 000. Uma libertacao de
	40 ms sobre um corte de -9,6 dB agarra 1 700 amostras por cada pico, e
	num som de meio segundo isso e' o som inteiro a levar duck.

	Esta versao ataca o problema pela dimensao certa: a JANELA, nao o tempo
	de recuperacao. Calcula-se o ganho necessario amostra a amostra, e depois
	espalha-se esse ganho por uma janela curta (`JANELA_MS`) com um perfil de
	coseno levantado. O pico fica coberto com uma rampa suave a entrar e a
	sair -- sem degrau (que seria um estalo) e sem cauda (que seria o duck).
	Tudo o que esta' fora da janela nao e' tocado, que e' 99,7% do ficheiro.

	O ganho e' partilhado por todos os canais: limitar canais em separado
	desloca a imagem estereo no pico, um artefacto pior do que o original.
	"""
	n = len(amostras) // canais
	meia = max(1, int(sr * JANELA_MS * 0.001 * 0.5))

	# ganho MINIMO exigido por cada amostra (1.0 = nao mexe)
	preciso = [1.0] * n
	mordeu = 0
	for i in range(n):
		base = i * canais
		alto = max(abs(amostras[base + c]) for c in range(canais))
		if alto > TECTO:
			preciso[i] = TECTO / alto
			mordeu += 1

	# espalha cada reducao pela janela, com perfil de coseno levantado; fica
	# o MENOR ganho pedido por qualquer vizinho (o envelope tem de cobrir o
	# pico mais exigente da vizinhanca)
	ganho = [1.0] * n
	for i in range(n):
		if preciso[i] >= 1.0:
			continue
		reducao = 1.0 - preciso[i]
		for d in range(-meia, meia + 1):
			j = i + d
			if j < 0 or j >= n:
				continue
			# 1 no centro, 0 nas pontas -- sem degrau em nenhuma das bordas
			peso = 0.5 * (1.0 + math.cos(math.pi * d / meia))
			g = 1.0 - reducao * peso
			if g < ganho[j]:
				ganho[j] = g

	saida = [0.0] * len(amostras)
	for i in range(n):
		base = i * canais
		g = ganho[i]
		for c in range(canais):
			v = amostras[base + c] * g
			saida[base + c] = max(-TECTO, min(TECTO, v))
	return saida, mordeu


def limitar_ao_nivel(amostras: list[float], ch: int, sr: int,
		alvo_son: float) -> tuple[list[float], int, float]:
	"""Limita o pico e repoe a sonoridade do sinal ceifado de referencia.

	O ganho e' PROCURADO, nao calculado: cada volta muda quanto o limitador
	morde, por isso a correccao exacta so' se sabe medindo.

	A procura e' amortecida (`AMORTECIMENTO`) porque sem isso oscila -- e
	oscilou: no `esmagar` o primeiro salto pedia +4,1 dB, o que punha o pico
	em +11,4 dBFS, alargava a mordida de 161 para 397 amostras e voltava a
	baixar a sonoridade, pedindo mais ganho ainda. Dar meio passo de cada vez
	converge em vez de fugir.

	Guarda-se sempre a MELHOR volta, nao a ultima: se nenhuma chegar a'
	tolerancia, quem decide e' o `main`, com o erro real a' vista.
	"""
	ganho_db = 0.0
	melhor = None
	melhor_erro = None
	for _ in range(10):
		g = 10.0 ** (ganho_db / 20.0)
		saida, mordeu = limitar([v * g for v in amostras], ch, sr)
		erro = alvo_son - sonoridade(saida, ch, sr)
		if melhor_erro is None or abs(erro) < abs(melhor_erro):
			melhor_erro = erro
			melhor = (saida, mordeu, ganho_db)
		if abs(erro) <= 0.05:
			break
		ganho_db += erro * AMORTECIMENTO
	return melhor


def escrever(f: str, amostras: list[float], sr: int, ch: int) -> None:
	cru = struct.pack("<%df" % len(amostras), *amostras)
	destino = os.path.join(AUDIO, f)
	cmd = [FFMPEG, "-y", "-v", "error", "-f", "f32le", "-ar", str(sr),
		"-ac", str(ch), "-i", "-"]
	if f.endswith(".ogg"):
		# q:a 6 = ~192 kbps. Uma geracao a mais num sample ja' lossy, com
		# artefactos muito abaixo do clipping que se esta' a tirar.
		cmd += ["-c:a", "libvorbis", "-q:a", "6"]
	else:
		cmd += ["-c:a", "pcm_s16le"]
	cmd.append(destino + ".tmp" + os.path.splitext(f)[1])
	subprocess.run(cmd, input=cru, check=True, capture_output=True)
	os.replace(cmd[-1], destino)


def main() -> int:
	so_medir = "--medir" in sys.argv
	# ficheiros que o Paulo mandou aceitar mesmo fora da tolerancia
	forcados = {a for a in sys.argv[sys.argv.index("--forcar") + 1:]} 		if "--forcar" in sys.argv else set()
	falhas = 0
	print("%-18s %7s | %7s %7s | %7s %7s | %6s %6s  %s" % (
		"FICHEIRO", "pico", "ref.LU", "ref.SON", "novo.LU", "novo.SON",
		"dLU", "dSON", "veredicto"))
	for f in ALVOS:
		antes = sondar(f)
		amostras = ler_float(f)
		ch, sr = antes["ch"], antes["sr"]
		# referencia = o que o jogador ouve hoje (o motor ja' ceifa)
		ref = ceifar(amostras)
		ref_son = sonoridade(ref, ch, sr)
		ref_lu = lufs_de(ref, ch, sr)
		if so_medir:
			print("%-18s %7.2f | %7.2f %7.2f |" % (
				f, antes["pico"], ref_lu, ref_son))
			continue
		if antes["pico"] <= TECTO_DB + 0.05:
			print("%-18s %7.2f | %39s ja' abaixo do tecto, nao mexido"
				% (f, antes["pico"], ""))
			continue
		saida, mordeu, ganho_db = limitar_ao_nivel(amostras, ch, sr, ref_son)
		novo_son = sonoridade(saida, ch, sr)
		novo_lu = lufs_de(saida, ch, sr)
		d_son = novo_son - ref_son
		d_lu = novo_lu - ref_lu
		dentro = abs(d_son) <= TOLERANCIA_LUFS and abs(d_lu) <= TOLERANCIA_LUFS
		ok = dentro or f in forcados
		if ok:
			escrever(f, saida, sr, ch)
			depois = sondar(f)
			pico_final = depois["pico"]
		else:
			falhas += 1
			pico_final = float("nan")
		print("%-18s %7.2f | %7.2f %7.2f | %7.2f %7.2f | %+6.2f %+6.2f  "
			"%s (%d amostras, compensacao %+.2f dB, pico final %.2f)" % (
			f, antes["pico"], ref_lu, ref_son, novo_lu, novo_son, d_lu, d_son,
			("OK" if dentro else "FORCADO") if ok else "RECUSADO",
			mordeu, ganho_db, pico_final))
	print("\nReferencia = o mesmo ficheiro CEIFADO a +-1,0, que e' o que o "
		"motor entrega hoje.")
	if falhas:
		print("%d ficheiro(s) recusado(s): a correccao do pico mexia mais de "
			"%.1f dB no que se ouve, logo deixava de ser objetiva e passa a "
			"ser decisao humana.\nPara aceitar mesmo assim: --forcar <ficheiro>"
			% (falhas, TOLERANCIA_LUFS))
	return 1 if falhas else 0


def lufs_de(amostras: list[float], ch: int, sr: int) -> float:
	"""LUFS integrado de um buffer em memoria, via `ffmpeg` por stdin."""
	cru = struct.pack("<%df" % len(amostras), *amostras)
	r = subprocess.run([FFMPEG, "-hide_banner", "-f", "f32le", "-ar", str(sr),
		"-ac", str(ch), "-i", "-", "-af", "ebur128", "-f", "null", "-"],
		input=cru, capture_output=True).stderr.decode("utf-8", "replace")
	m = re.search(r"I:\s*(-?[\d.]+) LUFS", r.rsplit("Integrated loudness", 1)[-1])
	return float(m.group(1)) if m else float("nan")


if __name__ == "__main__":
	raise SystemExit(main())
