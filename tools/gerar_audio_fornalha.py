#!/usr/bin/env python3
"""Sons da Regiao IV (Fornalha) que faltavam -- B8 do plano N1-N20 (3 out 2026).

    python tools/gerar_audio_fornalha.py

A auditoria dizia que os mecanismos da Fornalha nao tinham som nenhum; nao era
verdade (procurou `Som.` e eles usam `get_node("/root/Som")`): o pistao avisa
e bate, o jato e o piso quente sopram fogo quando ATIVAM, a valvula estala.
O que faltava mesmo era o AVISO antes do perigo no jato e no piso, e a lava
nao tinha som nenhum. Dois sons, por SIGNIFICADO (ver memoria "som por
significado"): um para "isto vai queimar" e um laco de fundo para a lava.

  - fornalha_carga.wav   1,0 s: ronco de queimador a subir (ruido filtrado com
                         o corte a abrir + zumbido grave a subir de tom). Aviso
                         do jato (tom normal), do piso quente (mais grave) e da
                         lava que vai subir (o mais grave).
  - lava_borbulha.wav    4,0 s em laco sem emenda: borbulhar espesso e baixo
                         (bolhas = senos curtos com queda de tom) sobre um
                         rumor filtrado. Fica muito baixo (-26 dB) por baixo.

Puro Python, sem numpy, sem samples de terceiros. Escreve com `\\n` (CRLF parte
os testes -- ver memoria).
"""
import math
import os
import random
import struct
import wave

FS = 44100
AUDIO = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def escrever(nome, buf, ganho):
    pico = max(1e-9, max(abs(x) for x in buf))
    sc = ganho / pico
    with wave.open(os.path.join(AUDIO, nome), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FS)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-32767, min(32767, x * sc * 32767)))) for x in buf))
    print("%-22s %5.2f s" % (nome, len(buf) / FS))


def fornalha_carga():
    rnd = random.Random(1916)
    dur = 1.0
    n_tot = int(dur * FS)
    buf = [0.0] * n_tot
    lp1 = lp2 = 0.0
    fase = 0.0
    for n in range(n_tot):
        t = n / FS
        p = t / dur
        # ruido de queimador: o filtro abre com o tempo (escuro -> brilhante)
        corte = 0.02 + 0.22 * p * p
        r = rnd.uniform(-1.0, 1.0)
        lp1 += corte * (r - lp1)
        lp2 += corte * (lp1 - lp2)
        # zumbido grave que sobe (70 -> 140 Hz) e pulsa a acelerar
        f = 70.0 + 70.0 * p
        fase += 2 * math.pi * f / FS
        zumbido = math.sin(fase) + 0.35 * math.sin(2 * fase)
        pulso = 0.75 + 0.25 * math.sin(2 * math.pi * (4.0 + 14.0 * p) * t)
        env = min(1.0, t / 0.05) * (0.25 + 0.75 * p)
        if t > dur - 0.06:
            env *= max(0.0, (dur - t) / 0.06)
        buf[n] = env * (1.6 * lp2 + 0.45 * zumbido * pulso)
    escrever("fornalha_carga.wav", buf, 0.7)


def lava_borbulha():
    rnd = random.Random(1918)
    dur = 4.0
    n_tot = int(dur * FS)
    buf = [0.0] * n_tot
    # rumor de fundo: gera-se `cf` a mais e a cauda dobra-se sobre o inicio
    # (crossfade) -- sem isto o filtro comecava a zero e o laco estalava
    # (medido: salto de 1500 na emenda contra um passo tipico de 39)
    cf = int(0.3 * FS)
    rumor = [0.0] * (n_tot + cf)
    lp1 = lp2 = 0.0
    for n in range(n_tot + cf):
        r = rnd.uniform(-1.0, 1.0)
        lp1 += 0.012 * (r - lp1)
        lp2 += 0.012 * (lp1 - lp2)
        rumor[n] = 3.0 * lp2
    for n in range(n_tot):
        buf[n] = rumor[n]
    for i in range(cf):
        k = i / cf
        buf[i] = rumor[i] * k + rumor[n_tot + i] * (1.0 - k)
    # bolhas: "plop" = seno curto com queda de tom; espalhadas e CIRCULARES
    # (o indice da-se a volta ao buffer, por isso o laco nao tem emenda)
    for _ in range(46):
        t0 = int(rnd.uniform(0.0, dur) * FS)
        f0 = rnd.uniform(90.0, 210.0)
        d = rnd.uniform(0.05, 0.12)
        a = rnd.uniform(0.25, 0.6)
        fase = 0.0
        for k in range(int(d * FS)):
            tk = k / FS
            f = f0 * (1.0 + 1.4 * (tk / d))      # a bolha rebenta a subir
            fase += 2 * math.pi * f / FS
            env = math.sin(math.pi * tk / d) ** 2
            buf[(t0 + k) % n_tot] += a * env * math.sin(fase)
    escrever("lava_borbulha.wav", buf, 0.6)


if __name__ == "__main__":
    fornalha_carga()
    lava_borbulha()
