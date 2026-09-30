#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Prepara os SFX de combate aprovados (Pixabay) para o runtime.

Os originais, sem alteracao, estao em `assets/audio/acquisition/sfx/combate/`
(`<numero Pixabay>.mp3`, ver o README dessa pasta). Varios sao longos demais
para um efeito de jogo (a porta de forno tem 52 s, o fogo 8 s) ou tem o
golpe a meio (a garra so' ataca aos 1,4 s). Esta ferramenta so' CORTA,
faz fade-out e iguala o pico -- nao mistura nem troca sons.

Cada linha de `CORTES` diz: evento (chave do `som.gd`), numero Pixabay,
inicio e duracao do corte em segundos (None = ate' ao fim). Saida: `.ogg`
mono 44,1 kHz em `assets/audio/approved/sfx/combate/<evento>.ogg`, pico a
-3 dBFS, fade-out de 0,12 s (so' quando o corte encurta o original).

Uso:  python tools/preparar_sfx_combate.py
Precisa do ffmpeg: `pip install --user imageio-ffmpeg` (ou FFMPEG=<bin>).
"""
import os
import re
import subprocess
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGEM = os.path.join(RAIZ, "assets", "audio", "acquisition", "sfx", "combate")
DESTINO = os.path.join(RAIZ, "assets", "audio", "approved", "sfx", "combate")
PICO_DB = -3.0
FADE = 0.12

# evento: (numero, inicio, duracao[, tom])
# `tom` (opcional) e' um factor de velocidade/tom (0,94 = mais grave): so' para
# haver 3 passos e 3 golpes de combo distintos a partir do MESMO som aprovado.
CORTES = {
	"passo1": ("363353", 0.05, 0.50),
	"passo2": ("363353", 0.05, 0.50, 0.94),
	"passo3": ("363353", 0.05, 0.50, 1.06),
	"ataque": ("388941", 0.0, None),
	"ataque2": ("388941", 0.0, None, 0.92),
	"ataque3": ("388941", 0.0, None, 1.08),
	"acerto": ("266309", 0.0, None),
	"acerto_v2": ("266309", 0.0, None, 0.93),
	"acerto_v3": ("266309", 0.0, None, 1.07),
	"acerto_critico": ("352708", 0.0, None),
	"pisao_koliani": ("295404", 0.0, None),
	"dano": ("262618", 0.20, None),
	"morte_koliani": ("543682", 0.0, 1.60),
	"bloqueio": ("143940", 0.0, 0.60),
	"parede": ("100717", 0.20, 0.60),
	"investida": ("562431", 0.0, 1.60),
	"golpe_pesado": ("176434", 0.0, 1.60),
	"esmagar": ("515256", 0.0, 1.80),
	"garra": ("482516", 1.30, 0.80),
	"chama": ("378639", 0.0, 1.60),
	"chefe_magia": ("228343", 0.10, 2.10),
	"raio": ("386160", 0.10, None),
	"energia_impacto": ("351961", 0.0, 1.60),
	"olho_carregar": ("102051", 0.0, 2.00),
	"pedra_parte": ("6129", 0.90, 1.50),
	"praga": ("6184", 0.10, 1.50),
	"mecanismo": ("74847", 1.35, 1.00),
	"sino_mecanismo": ("352062", 0.0, 2.50),
	"lamina_cair": ("103800", 0.0, None),
}


def _ffmpeg() -> str:
	if os.environ.get("FFMPEG"):
		return os.environ["FFMPEG"]
	try:
		import imageio_ffmpeg
		return imageio_ffmpeg.get_ffmpeg_exe()
	except ImportError:
		sys.exit("falta o ffmpeg: pip install --user imageio-ffmpeg (ou FFMPEG=<bin>)")


def _pico(ff: str, args: list) -> float:
	r = subprocess.run([ff, "-hide_banner", *args, "-af", "volumedetect", "-f", "null", "-"],
			capture_output=True, text=True)
	m = re.search(r"max_volume: (-?[\d.]+) dB", r.stderr)
	return float(m.group(1)) if m else 0.0


def main() -> None:
	ff = _ffmpeg()
	os.makedirs(DESTINO, exist_ok=True)
	for evento, (num, ini, dur, *resto) in CORTES.items():
		tom = resto[0] if resto else 1.0
		src = os.path.join(ORIGEM, num + ".mp3")
		corte = ["-ss", str(ini), "-i", src] + (["-t", str(dur)] if dur else [])
		ganho = PICO_DB - _pico(ff, corte + ["-ac", "1"])
		filtros = ["asetrate=%d,aresample=44100" % round(44100 * tom)] if tom != 1.0 else []
		filtros.append("volume=%.2fdB" % ganho)
		if ini > 0.0:
			filtros.insert(0, "afade=t=in:d=0.005")
		if dur:
			filtros.append("afade=t=out:st=%.3f:d=%.3f" % (dur - FADE, FADE))
		out = os.path.join(DESTINO, evento + ".ogg")
		subprocess.run([ff, "-hide_banner", "-v", "error", "-y", *corte, "-ac", "1", "-ar", "44100",
				"-af", ",".join(filtros), "-c:a", "libvorbis", "-q:a", "6", out], check=True)
		print("%-16s <- %s.mp3  %.2fs+%s  ganho %+.1f dB" % (evento, num, ini,
				"%.2fs" % dur if dur else "fim", ganho))


if __name__ == "__main__":
	main()
