#!/usr/bin/env python3
"""QA FFmpeg dos WAV originais da Koliani; nao modifica os assets."""

from __future__ import annotations

import json
from array import array
import math
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import wave


RAIZ = Path(__file__).resolve().parents[1]
PASTA = RAIZ / "assets/audio/koliani_signature"
BIN = (Path(os.environ.get("LOCALAPPDATA", "")) / "Microsoft/WinGet/Packages" /
       "Gyan.FFmpeg.Essentials_Microsoft.Winget.Source_8wekyb3d8bbwe" /
       "ffmpeg-9.0.1-essentials_build/bin")


def ferramenta(nome: str) -> str:
    return shutil.which(nome) or str(BIN / (nome + ".exe"))


def main() -> int:
    ffprobe = ferramenta("ffprobe")
    ffmpeg = ferramenta("ffmpeg")
    if not Path(ffprobe).is_file() or not Path(ffmpeg).is_file():
        print("FFmpeg/ffprobe indisponivel", file=sys.stderr)
        return 2
    ficheiros = sorted(PASTA.glob("*.wav"))
    falhas = []
    print("asset | duracao s | Hz | canais | pico dBFS | LUFS")
    for caminho in ficheiros:
        probe = subprocess.run(
            [ffprobe, "-v", "error", "-show_entries",
             "stream=codec_name,sample_rate,channels,duration", "-of", "json",
             str(caminho)], capture_output=True, text=True, check=True)
        stream = json.loads(probe.stdout)["streams"][0]
        duracao = float(stream["duration"])
        analise = subprocess.run(
            [ffmpeg, "-hide_banner", "-nostats", "-i", str(caminho), "-af",
             "astats=metadata=0:reset=0,ebur128=peak=true", "-f", "null", "NUL"],
            capture_output=True, text=True, check=True)
        saida = analise.stderr
        picos = re.findall(r"Peak level dB:\s*(-?\d+(?:\.\d+)?)", saida)
        lufs = re.findall(r"\bI:\s*(-?\d+(?:\.\d+)?)\s+LUFS", saida)
        pico = float(picos[-1]) if picos else 99.0
        integrado = float(lufs[-1]) if lufs else -70.0
        if stream["codec_name"] != "pcm_s16le" or int(stream["sample_rate"]) != 44100 \
                or int(stream["channels"]) != 1 or not 0.10 <= duracao <= 0.80 \
                or pico > -1.0:
            falhas.append(caminho.name)
        lufs_txt = f"{integrado:.1f}" if integrado > -69.0 else "n/a (<400ms)"
        print(f"{caminho.name} | {duracao:.3f} | {stream['sample_rate']} | "
              f"{stream['channels']} | {pico:.2f} | {lufs_txt}")
    if len(ficheiros) != 27:
        falhas.append(f"quantidade={len(ficheiros)} (esperada 27)")
    # Ensaio conservador: quatro golpes na cadencia real, cada um com impacto.
    # Nao substitui mistura ou audicao em jogo, mas encontra clipping obvio.
    eventos = (
        ("shadowblade_swing_1.wav", 0.00, -8.0),
        ("shadowblade_hit.wav", 0.10, -8.0),
        ("shadowblade_swing_2.wav", 0.18, -7.0),
        ("shadowblade_hit_v2.wav", 0.29, -8.0),
        ("shadowblade_swing_3.wav", 0.38, -6.0),
        ("shadowblade_hit_v3.wav", 0.51, -8.0),
        ("shadowblade_finisher.wav", 0.68, -3.0),
        ("shadowblade_critical.wav", 0.82, -6.0),
    )
    mistura = array("f", [0.0]) * round(1.4 * 44100)
    for nome, tempo, volume_db in eventos:
        with wave.open(str(PASTA / nome), "rb") as entrada:
            pcm = array("h")
            pcm.frombytes(entrada.readframes(entrada.getnframes()))
        ganho = 10.0 ** (volume_db / 20.0) / 32768.0
        offset = round(tempo * 44100)
        for i, amostra in enumerate(pcm):
            mistura[offset + i] += amostra * ganho
    pico_mistura = max(abs(v) for v in mistura)
    print(f"combo+4 impactos: pico {20.0 * math.log10(pico_mistura):.2f} dBFS")
    if pico_mistura >= 1.0:
        falhas.append("mistura do combo excede 0 dBFS")
    print(f"QA KOLIANI: {len(ficheiros)} ficheiros, {len(falhas)} falhas {falhas}")
    return 1 if falhas else 0


if __name__ == "__main__":
    raise SystemExit(main())
