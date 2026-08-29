#!/usr/bin/env python3
"""Gera os .wav sintetizados novos do Koliani (sem samples de terceiros):

    python tools/gerar_audio.py

  - game_over.wav       voz de "GAME OVER" estilo speaker de arcada (síntese
                        de formantes, grave, com grão e cauda de reverb)
  - boss.wav            cama de música do chefe final: mais rápida, mais
                        alta, fantasmagórica (loop de 8 s)
  - assombracao.wav     ruídos de casa assombrada para pôr por baixo da
                        música (vento, rangidos, correntes, gemido) -- loop
  - demonio_ataque.wav  rosnar curto quando um demónio nos acerta

Tudo é nosso (sem licença de terceiros). Puro Python (sem numpy).
"""
import math
import os
import random
import struct
import wave

FS = 44100
AUDIO = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def escrever(nome, buf, ganho=0.92):
    pico = max(1e-9, max(abs(x) for x in buf))
    sc = ganho / pico
    caminho = os.path.join(AUDIO, nome)
    with wave.open(caminho, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FS)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-32767, min(32767, x * sc * 32767))))
            for x in buf))
    print("%-22s %5.2f s" % (nome, len(buf) / FS))


def enrolar(buf, n, cf):
    """Faz o buffer (n+cf amostras) dar loop sem clique: dobra a cauda `cf`
    sobre a cabeca e corta."""
    for i in range(cf):
        a = i / cf
        buf[i] = buf[i] * a + buf[n + i] * (1.0 - a)
    return buf[:n]


class Reson:
    """Ressoador de 2 polos (formante / filtro de banda)."""
    def __init__(self):
        self.y1 = 0.0
        self.y2 = 0.0

    def passo(self, x, f, bw):
        theta = 2 * math.pi * f / FS
        r = math.exp(-math.pi * bw / FS)
        y = (1.0 - r * r) * x + 2 * r * math.cos(theta) * self.y1 - r * r * self.y2
        self.y2 = self.y1
        self.y1 = y
        return y


# --------------------------------------------------------------------------
# 1) VOZ "GAME OVER"
# --------------------------------------------------------------------------
def game_over_voz():
    random.seed(20260829)
    # linha do tempo: (t, F1, F2, F3, voz, ruido, amp)
    KF = [
        (0.00, 300, 1600, 2400, 0.0, 0.0, 0.0),
        (0.045, 300, 1600, 2400, 0.0, 0.0, 0.0),
        (0.055, 320, 1500, 2300, 0.6, 0.55, 0.9),   # G (oclusiva)
        (0.085, 500, 1750, 2500, 1.0, 0.05, 1.0),
        (0.230, 520, 1830, 2520, 1.0, 0.0, 1.0),    # "EI"
        (0.330, 400, 2150, 2600, 1.0, 0.0, 0.95),
        (0.360, 300, 1200, 2300, 0.8, 0.0, 0.7),
        (0.470, 280, 1050, 2250, 0.75, 0.0, 0.6),   # "M"
        (0.500, 280, 1050, 2250, 0.0, 0.0, 0.0),
        (0.585, 280, 1050, 2250, 0.0, 0.0, 0.0),
        (0.610, 500, 950, 2350, 1.0, 0.0, 1.0),     # "OU"
        (0.760, 470, 900, 2350, 1.0, 0.0, 1.0),
        (0.850, 370, 820, 2350, 1.0, 0.0, 0.95),
        (0.880, 350, 1350, 2100, 0.55, 0.4, 0.7),   # "V"
        (0.950, 360, 1400, 2150, 0.7, 0.25, 0.85),
        (0.980, 480, 1350, 1600, 1.0, 0.0, 1.0),    # "ER" (r baixo em F3)
        (1.230, 470, 1300, 1550, 1.0, 0.0, 1.0),
        (1.330, 470, 1300, 1550, 0.9, 0.0, 0.8),
        (1.470, 470, 1300, 1550, 0.0, 0.0, 0.0),
        (2.30, 470, 1300, 1550, 0.0, 0.0, 0.0),     # cauda de reverb
    ]
    N = int(KF[-1][0] * FS)

    def kf(t):
        for i in range(len(KF) - 1):
            t0, t1 = KF[i][0], KF[i + 1][0]
            if t0 <= t <= t1:
                a = 0.0 if t1 == t0 else (t - t0) / (t1 - t0)
                return [KF[i][j] + (KF[i + 1][j] - KF[i][j]) * a for j in range(1, 7)]
        return list(KF[-1][1:])

    def f0(t):
        if t < 0.5:
            base = 118 + (100 - 118) * (t / 0.5)
        elif t < 1.0:
            base = 100 + (92 - 100) * ((t - 0.5) / 0.5)
        else:
            base = 92 + (72 - 92) * min(1.0, (t - 1.0) / 0.5)
        return max(50.0, base + 2.0 * math.sin(2 * math.pi * 4.7 * t) + random.uniform(-0.8, 0.8))

    R1, R2, R3 = Reson(), Reson(), Reson()
    buf = [0.0] * N
    fase = 0.0
    lp = 0.0
    for n in range(N):
        t = n / FS
        F1, F2, F3, voz, ruido, amp = kf(t)
        fase += f0(t) / FS
        if fase >= 1.0:
            fase -= 1.0
        saw = 2.0 * fase - 1.0
        lp += 0.35 * (saw - lp)
        exc = lp * voz + random.uniform(-1.0, 1.0) * ruido * 0.5
        s = R1.passo(exc, max(180.0, F1), 70.0)
        s += 0.7 * R2.passo(exc, max(400.0, F2), 95.0)
        s += 0.35 * R3.passo(exc, max(1200.0, F3), 130.0)
        buf[n] = s * amp

    # grão + passa-banda de "coluna de arcada"
    for n in range(N):
        g = min(1.0, (n / FS) / 0.006)
        buf[n] = math.tanh(buf[n] * g * 2.7)
    hp, ain = 0.0, 0.0
    ahp = math.exp(-2 * math.pi * 170 / FS)
    for n in range(N):
        x = buf[n]
        hp = ahp * (hp + x - ain)
        ain = x
        buf[n] = hp
    lp = 0.0
    alp = math.exp(-2 * math.pi * 3600 / FS)
    for n in range(N):
        lp += (1 - alp) * (buf[n] - lp)
        buf[n] = lp
    # reverb FIR (estável) para o "eco de fliperama"
    taps = [(0.031, 0.5), (0.055, 0.38), (0.083, 0.28), (0.117, 0.20),
            (0.151, 0.14), (0.197, 0.09), (0.243, 0.06)]
    wet = [0.0] * N
    for dt, g in taps:
        d = int(dt * FS)
        for n in range(d, N):
            wet[n] += buf[n - d] * g
    for n in range(N):
        buf[n] = buf[n] * 0.86 + wet[n] * 0.5
    fo = int(0.2 * FS)
    for n in range(N - fo, N):
        buf[n] *= (N - n) / fo
    escrever("game_over.wav", buf, 0.97)


# --------------------------------------------------------------------------
# 2) MUSICA DO CHEFE FINAL  (loop 8 s, fantasmagorica e mexida)
# --------------------------------------------------------------------------
def boss_loop():
    random.seed(4242)
    dur = 8.0
    cf = int(0.25 * FS)
    N = int(dur * FS)
    total = N + cf
    bpm = 140.0
    beat = 60.0 / bpm
    buf = [0.0] * total

    # escala frigia em Ré: 0,1,3,5,7,8,10 semitons
    frigia = [0, 1, 3, 5, 7, 8, 10]

    def nota(semi):
        return 146.83 * (2.0 ** (semi / 12.0))  # a partir de Ré3

    # --- baixo pulsante (colcheias) ---
    padrao_baixo = [0, 0, 0, 3, 0, 0, -2, 0]  # graus, -2 => oitava abaixo do 5
    blp = 0.0
    for n in range(total):
        t = n / FS
        passo = int(t / (beat / 2)) % len(padrao_baixo)
        g = padrao_baixo[passo]
        fb = nota(frigia[g % 7] - 24 + (0 if g >= 0 else -3))
        ph = (t * fb) % 1.0
        env_pos = (t % (beat / 2)) / (beat / 2)
        env = math.exp(-env_pos * 4.0) * 0.9 + 0.1
        saw = (2.0 * ph - 1.0)
        saw += 0.5 * (2.0 * ((t * fb * 1.005) % 1.0) - 1.0)  # leve desafinação
        blp += 0.22 * (saw - blp)
        buf[n] += blp * env * 0.5

    # --- arpejo fantasmagorico (semicolcheias, par desafinado + tremolo) ---
    arp = [0, 3, 5, 7, 5, 3, 7, 10, 7, 5, 3, 0, 3, 5, 7, 10]
    for n in range(total):
        t = n / FS
        i16 = int(t / (beat / 4)) % len(arp)
        fa = nota(frigia[arp[i16] % 7] + 12 * (arp[i16] // 7))
        env_pos = (t % (beat / 4)) / (beat / 4)
        env = math.exp(-env_pos * 6.0)
        trem = 0.75 + 0.25 * math.sin(2 * math.pi * 7.0 * t)
        tri = 2.0 * abs(2.0 * ((t * fa) % 1.0) - 1.0) - 1.0
        tri += 2.0 * abs(2.0 * ((t * fa * 1.01) % 1.0) - 1.0) - 1.0
        buf[n] += tri * 0.16 * env * trem

    # --- pad de cluster (2a menor) com chorus lento ---
    for n in range(total):
        t = n / FS
        vib = 1.0 + 0.004 * math.sin(2 * math.pi * 0.3 * t)
        p = 0.0
        for k, semi in enumerate((0, 1, 7)):
            fp = nota(frigia[semi % 7] - 12) * vib * (1.0 + 0.003 * k)
            p += math.sin(2 * math.pi * fp * t + k)
        swell = 0.5 + 0.5 * math.sin(2 * math.pi * (t / dur) - math.pi / 2)
        buf[n] += p * 0.06 * (0.5 + 0.5 * swell)

    # --- cintilacoes agudas nos contratempos ---
    for k in range(int(dur / (beat / 2))):
        if k % 2 == 0:
            continue
        t0 = k * (beat / 2) + random.uniform(-0.01, 0.01)
        fsh = nota(random.choice(frigia) + 24)
        for n in range(int(t0 * FS), min(total, int((t0 + 0.4) * FS))):
            tt = n / FS - t0
            buf[n] += math.sin(2 * math.pi * fsh * tt) * 0.10 * math.exp(-tt * 9.0)

    # --- percussao: thump nos tempos 1 e 3, chiado nas colcheias ---
    for n in range(total):
        t = n / FS
        # thump
        fb = t % (2 * beat)
        if fb < 0.12:
            fk = 120.0 * math.exp(-fb * 18.0) + 45.0
            buf[n] += math.sin(2 * math.pi * fk * fb) * math.exp(-fb * 12.0) * 0.55
        # chiado (hat)
        fh = t % (beat / 2)
        if fh < 0.05:
            buf[n] += random.uniform(-1, 1) * math.exp(-fh * 80.0) * 0.14

    # passa-alto suave + tanh leve
    hp, ain = 0.0, 0.0
    ahp = math.exp(-2 * math.pi * 40 / FS)
    for n in range(total):
        x = buf[n]
        hp = ahp * (hp + x - ain)
        ain = x
        buf[n] = math.tanh(hp * 1.3)

    buf = enrolar(buf, N, cf)
    escrever("boss.wav", buf, 0.95)


# --------------------------------------------------------------------------
# 3) RUIDOS DE CASA ASSOMBRADA  (loop 12 s, por baixo da musica)
# --------------------------------------------------------------------------
def assombracao_loop():
    random.seed(1313)
    dur = 12.0
    cf = int(0.4 * FS)
    N = int(dur * FS)
    total = N + cf
    buf = [0.0] * total

    # vento: ruido rosa filtrado em banda, com a frequencia a passear
    rw = Reson()
    lp = 0.0
    for n in range(total):
        t = n / FS
        fc = 500 + 260 * math.sin(2 * math.pi * 0.05 * t) + 120 * math.sin(2 * math.pi * 0.017 * t)
        x = random.uniform(-1, 1)
        lp += 0.05 * (x - lp)          # rosa-ish
        s = rw.passo(lp, max(120.0, fc), 220.0)
        amp = 0.32 + 0.18 * math.sin(2 * math.pi * 0.08 * t + 1.0)
        buf[n] += s * amp

    # rangidos: varrimento de um ressoador estreito sobre ruido
    for _ in range(6):
        t0 = random.uniform(0.0, dur)
        d = random.uniform(0.5, 1.3)
        f0c = random.uniform(180, 420)
        f1c = f0c * random.uniform(1.4, 2.4)
        rr = Reson()
        for n in range(int(t0 * FS), min(total, int((t0 + d) * FS))):
            tt = (n / FS - t0) / d
            env = math.sin(math.pi * tt) ** 2
            fc = f0c + (f1c - f0c) * tt
            s = rr.passo(random.uniform(-1, 1) * 0.5, fc, 30.0)
            buf[n] += s * env * 0.5

    # correntes: rajadas de cliques de ruido filtrado
    for _ in range(5):
        t0 = random.uniform(0.0, dur)
        for _ in range(random.randint(5, 11)):
            tc = t0 + random.uniform(0.0, 0.5)
            rc = Reson()
            for n in range(int(tc * FS), min(total, int((tc + 0.05) * FS))):
                tt = n / FS - tc
                s = rc.passo(random.uniform(-1, 1), random.uniform(2200, 4200), 400.0)
                buf[n] += s * math.exp(-tt * 120.0) * 0.5

    # gemido distante: duas sinusoides desafinadas com formante e swell lento
    for _ in range(2):
        t0 = random.uniform(0.5, dur - 3.0)
        d = random.uniform(2.0, 3.0)
        base = random.uniform(90, 150)
        fm = Reson()
        for n in range(int(t0 * FS), min(total, int((t0 + d) * FS))):
            tt = (n / FS - t0)
            p = tt / d
            env = math.sin(math.pi * p) ** 2
            gliss = base * (1.0 + 0.06 * math.sin(2 * math.pi * 0.4 * tt))
            src = math.sin(2 * math.pi * gliss * tt) + math.sin(2 * math.pi * gliss * 1.01 * tt)
            s = fm.passo(src, 620.0, 90.0)
            buf[n] += s * env * 0.18

    # trovao/baque raro
    for _ in range(2):
        t0 = random.uniform(0.0, dur)
        for n in range(int(t0 * FS), min(total, int((t0 + 0.9) * FS))):
            tt = n / FS - t0
            buf[n] += math.sin(2 * math.pi * (55 * math.exp(-tt * 3.0) + 22) * tt) * math.exp(-tt * 4.0) * 0.4

    # passa-baixo geral (soa "abafado / longe")
    lp = 0.0
    alp = math.exp(-2 * math.pi * 3000 / FS)
    for n in range(total):
        lp += (1 - alp) * (buf[n] - lp)
        buf[n] = lp

    buf = enrolar(buf, N, cf)
    escrever("assombracao.wav", buf, 0.7)


# --------------------------------------------------------------------------
# 4) DEMONIO A ATACAR  (rosnar curto)
# --------------------------------------------------------------------------
def demonio_ataque():
    random.seed(77)
    dur = 0.42
    N = int(dur * FS)
    buf = [0.0] * N
    r1, r2 = Reson(), Reson()
    lp = 0.0
    for n in range(N):
        t = n / FS
        p = t / dur
        f = 190.0 * (1.0 - 0.55 * p) + 60.0        # desce de tom
        buzz = 2.0 * ((t * f) % 1.0) - 1.0
        buzz += 0.6 * (random.uniform(-1, 1))       # aspereza
        lp += 0.4 * (buzz - lp)
        s = r1.passo(lp, 380.0 - 120.0 * p, 120.0)
        s += 0.6 * r2.passo(lp, 900.0 - 300.0 * p, 200.0)
        env = (min(1.0, p / 0.03)) * math.exp(-p * 3.2)
        buf[n] = math.tanh(s * 2.0) * env
    # "chiado" de ar no arranque
    for n in range(int(0.06 * FS)):
        buf[n] += random.uniform(-1, 1) * math.exp(-n / FS * 40.0) * 0.4
    escrever("demonio_ataque.wav", buf, 0.9)


if __name__ == "__main__":
    game_over_voz()
    boss_loop()
    assombracao_loop()
    demonio_ataque()
