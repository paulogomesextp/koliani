# -*- coding: utf-8 -*-
"""Auditoria OBJECTIVA dos SFX (Execution 9H.18).

Porque existe
-------------
O Game Master ouviu a build e disse que os sons continuam maus. As passagens
anteriores provaram ligacao, duracao e sonoridade -- nao provaram DESENHO.
Um som mau mais alto continua mau. Isto mede o que se pode medir sem ouvir:

  ataque   quanto tempo leva a chegar ao pico. Um transiente de combate tem
           de estabelecer identidade nos primeiros ~50 ms; acima de 80 ms
           soa mole e chega tarde ao golpe.
  cauda    do pico ate' -40 dB. Caudas longas de mais empastam o combo (os
           quatro golpes tocam em 0,2-0,3 s uns dos outros).
  crista   pico menos RMS. Pouca crista = som achatado, sem impacto.
  bandas   % de energia em grave (<250 Hz) / medio / agudo (>2 kHz). Sem
           grave nao ha' corpo; agudo a mais e' o "chirp barato".
  corte    amostras encostadas ao fundo de escala.

Uso:
    python tools/auditar_sfx_9h18.py [ficheiro.wav ...]
    python tools/auditar_sfx_9h18.py --catalogo   (os sons auditados na 9H.18)
"""
import argparse
import math
import os
import struct
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO = os.path.join(RAIZ, "assets", "audio")

## Os eventos audiveis do Menu, do Seletor e da Regiao I -- por grupo.
CATALOGO = {
	"MENU": ["ui_mover", "ui_confirmar", "ui_voltar", "ui_negado", "carrossel",
		"porta", "transicao"],
	"MOVIMENTO": ["salto", "salto_duplo", "aterrar", "dash", "rolamento",
		"passo1", "passo2", "passo3"],
	"COMBATE": ["ataque", "ataque2", "ataque3", "ataque_forte", "acerto",
		"dano", "bloqueio", "morte_koliani"],
	"MUNDO": ["apanhar", "selo", "raiz_aviso", "raiz_irrompe",
		"plataforma_surge", "conquista", "projetil", "investida", "chefe_cai"],
}


def ler_wav(caminho: str):
	"""Le WAV PCM (8/16/24/32 bits) e IEEE float. O modulo `wave` rejeita o
	formato 3 (float), que e' o que o Godot escreve em varios destes sons."""
	with open(caminho, "rb") as f:
		cru = f.read()
	if cru[:4] != b"RIFF" or cru[8:12] != b"WAVE":
		raise SystemExit("%s nao e' WAV" % caminho)
	i = 12
	fmt = None
	dados = None
	while i + 8 <= len(cru):
		nome = cru[i:i + 4]
		tam = struct.unpack("<I", cru[i + 4:i + 8])[0]
		corpo = cru[i + 8:i + 8 + tam]
		if nome == b"fmt ":
			fmt = struct.unpack("<HHIIHH", corpo[:16])
		elif nome == b"data":
			dados = corpo
		i += 8 + tam + (tam & 1)
	if fmt is None or dados is None:
		raise SystemExit("%s: sem fmt/data" % caminho)
	etiqueta, canais, sr, _, _, bits = fmt
	if etiqueta == 3 and bits == 32:
		amostras = list(struct.unpack("<%df" % (len(dados) // 4), dados))
	elif etiqueta in (1, 0xFFFE) and bits == 16:
		amostras = [v / 32768.0 for v in struct.unpack("<%dh" % (len(dados) // 2), dados)]
	elif etiqueta in (1, 0xFFFE) and bits == 8:
		amostras = [(b - 128) / 128.0 for b in dados]
	elif etiqueta in (1, 0xFFFE) and bits == 24:
		amostras = [int.from_bytes(dados[k:k + 3], "little", signed=True) / 8388608.0
			for k in range(0, len(dados) - 2, 3)]
	elif etiqueta in (1, 0xFFFE) and bits == 32:
		amostras = [v / 2147483648.0 for v in struct.unpack("<%di" % (len(dados) // 4), dados)]
	else:
		raise SystemExit("%s: formato %d/%d bits nao suportado" % (caminho, etiqueta, bits))
	if canais > 1:
		amostras = [sum(amostras[k:k + canais]) / canais
			for k in range(0, len(amostras) - canais + 1, canais)]
	return amostras, sr


def db(v: float) -> float:
	return 20.0 * math.log10(max(v, 1e-9))


def um_polo(x: list[float], sr: int, fc: float, passa_alto: bool) -> list[float]:
	"""Filtro de um polo -- chega para repartir energia por bandas."""
	a = math.exp(-2.0 * math.pi * fc / sr)
	y = 0.0
	baixo = []
	for v in x:
		y = (1.0 - a) * v + a * y
		baixo.append(y)
	if not passa_alto:
		return baixo
	return [x[i] - baixo[i] for i in range(len(x))]


def energia(x: list[float]) -> float:
	return sum(v * v for v in x)


def analisa(nome: str, caminho: str) -> dict:
	x, sr = ler_wav(caminho)
	n = len(x)
	dur = n / sr
	pico = max(abs(v) for v in x) if n else 0.0
	rms = math.sqrt(energia(x) / n) if n else 0.0
	# envelope por janelas de 1 ms
	jan = max(1, sr // 1000)
	env = [max(abs(v) for v in x[i:i + jan]) for i in range(0, n, jan)]
	i_pico = env.index(max(env)) if env else 0
	ataque_ms = i_pico * (jan / sr) * 1000.0
	limiar = pico * (10 ** (-40.0 / 20.0))
	i_fim = len(env) - 1
	while i_fim > i_pico and env[i_fim] < limiar:
		i_fim -= 1
	cauda_ms = (i_fim - i_pico) * (jan / sr) * 1000.0
	tot = energia(x) or 1.0
	grave = energia(um_polo(x, sr, 250.0, False)) / tot
	agudo = energia(um_polo(x, sr, 2000.0, True)) / tot
	medio = max(0.0, 1.0 - grave - agudo)
	corte = sum(1 for v in x if abs(v) >= 0.999)
	return {
		"nome": nome, "sr": sr, "dur_ms": dur * 1000.0,
		"pico_db": db(pico), "rms_db": db(rms), "crista_db": db(pico) - db(rms),
		"ataque_ms": ataque_ms, "cauda_ms": cauda_ms,
		"grave": grave * 100.0, "medio": medio * 100.0, "agudo": agudo * 100.0,
		"corte": corte,
	}


CAB = ("evento          dur_ms  pico  rms  crista  ataque  cauda   grav med agud  corte")


def linha(a: dict) -> str:
	return ("%-15s %6.0f %5.1f %5.1f %6.1f %7.1f %6.0f  %4.0f%%%4.0f%%%4.0f%%  %5d"
		% (a["nome"], a["dur_ms"], a["pico_db"], a["rms_db"], a["crista_db"],
			a["ataque_ms"], a["cauda_ms"], a["grave"], a["medio"], a["agudo"],
			a["corte"]))


def main() -> int:
	ap = argparse.ArgumentParser()
	ap.add_argument("ficheiros", nargs="*")
	ap.add_argument("--catalogo", action="store_true")
	args = ap.parse_args()
	if args.catalogo:
		for grupo, nomes in CATALOGO.items():
			print("\n--- %s ---" % grupo)
			print(CAB)
			for nome in nomes:
				p = os.path.join(AUDIO, nome + ".wav")
				if not os.path.exists(p):
					print("%-15s AUSENTE" % nome)
					continue
				print(linha(analisa(nome, p)))
		return 0
	print(CAB)
	for f in args.ficheiros:
		print(linha(analisa(os.path.basename(f).rsplit(".", 1)[0], f)))
	return 0


if __name__ == "__main__":
	sys.exit(main())
