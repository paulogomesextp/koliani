#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Deriva o `olho_carregar.wav` (Prompt 3A -- SFX Overhaul dos chefes).

## Porque e' que isto existe

`raio.wav` e `olho_carregar.wav` eram **byte a byte o mesmo ficheiro**
(md5 `60d89d5f...`, unico par duplicado em todo o catalogo de audio).
Ou seja: a CARGA do laser do Olho do Abismo -- e a do olho do Zeriko --
soava exactamente ao RELAMPAGO do Voltaris. Duas chaves semanticas, uma
so' forma de onda, em dois chefes de regioes diferentes.

Uma carga e um impacto sao envelopes opostos: a carga cresce e resolve no
disparo, o impacto arranca no pico e decai. Aqui a carga e' derivada do
mesmo material CC0 -- INVERTIDO no tempo, que e' precisamente o que
transforma um decaimento num crescendo -- com um passa-banda a fechar e
uma cauda curta antes do disparo.

Fonte: "Overloading Sound", jwiese, OpenGameArt, usado sob CC0 (ja'
creditado em `assets/audio/CREDITS.md` para `raio`/`olho_carregar`).
Nao ha' material novo nem licenca nova: e' o mesmo sample, tratado.

## Correr

    python tools/gerar_sfx_3a.py

Precisa do `ffmpeg` no PATH. Reescreve `assets/audio/olho_carregar.wav`;
o `raio.wav` NAO e' tocado. Depois disto e' preciso reimportar:

    godot --headless --import
"""

import os
import shutil
import subprocess
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO = os.path.join(RAIZ, "assets", "audio")
FONTE = os.path.join(AUDIO, "raio.wav")
ALVO = os.path.join(AUDIO, "olho_carregar.wav")

# 1,6 s: o telegrafo do Olho do Abismo e do Zeriko vive a volta disso. Os
# 5,61 s do original nunca chegavam a ouvir-se inteiros -- o disparo
# cortava-os a meio, e o que se ouvia era o arranque de um RELAMPAGO.
DURACAO = 1.6

# `areverse` transforma o decaimento num crescendo -- e' o truque todo.
# `highpass` tira o murro grave do relampago (uma carga nao bate, aperta);
# `lowpass` fecha o brilho para o disparo ter para onde abrir.
# O `afade` de saida deixa 90 ms de silencio antes do `feixe_vil`.
FILTRO = (
    "areverse,"
    "atrim=0:%0.2f,"
    "highpass=f=320,"
    "lowpass=f=6200,"
    "afade=t=in:st=0:d=0.45,"
    "afade=t=out:st=%0.2f:d=0.18,"
    "loudnorm=I=-15:TP=-1.5:LRA=11"
) % (DURACAO, DURACAO - 0.22)


def main() -> int:
    if shutil.which("ffmpeg") is None:
        print("ffmpeg nao esta' no PATH", file=sys.stderr)
        return 2
    if not os.path.exists(FONTE):
        print("falta %s" % FONTE, file=sys.stderr)
        return 2
    tmp = ALVO + ".tmp.wav"
    cmd = [
        "ffmpeg", "-y", "-loglevel", "error", "-i", FONTE,
        "-af", FILTRO, "-ar", "44100", "-ac", "2", "-c:a", "pcm_s16le", tmp,
    ]
    subprocess.run(cmd, check=True)
    os.replace(tmp, ALVO)
    print("olho_carregar.wav derivado de raio.wav (%.1fs, invertido)" % DURACAO)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
