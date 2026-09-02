#!/usr/bin/env python3
"""Gera os .wav sintetizados novos do Koliani (sem samples de terceiros):

    python tools/gerar_audio.py

  - game_over.wav       voz de "GAME OVER" estilo speaker de arcada (síntese
                        de formantes, grave, com grão e cauda de reverb)
  - menu.wav            tema do menu inicial: lento, pad + melodia esparsa
                        de sino, fantasmagórico e calmo (loop de 16 s)
  - boss.wav            cama de música do chefe final: mais rápida, mais
                        alta, fantasmagórica (loop de 8 s)
  - assombracao.wav     ruídos de casa assombrada para pôr por baixo da
                        música (vento, rangidos, correntes, gemido) -- loop
  - demonio_ataque.wav  rosnar curto quando um demónio nos acerta
  - salto.wav           salto: "whoop" suave e curto (sino filtrado, pouco
                        ruído) -- substitui o som antigo, que era áspero
  - salto_duplo.wav     salto duplo: igual mas mais brilhante + faísca
  - conquista.wav       chefe derrotado: arpejo de sino ascendente +
                        cintilação + cauda de reverb (som de "conquista")

Tudo é nosso (sem licença de terceiros). Puro Python (sem numpy).
"""
import math
import os
import random
import zlib
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
# 1b) TEMA DO MENU  (loop 16 s, lento e calmo -- "drone + melodia esparsa")
# --------------------------------------------------------------------------
def menu_loop():
    random.seed(909)
    dur = 16.0
    cf = int(0.5 * FS)
    N = int(dur * FS)
    total = N + cf
    buf = [0.0] * total

    def nota(semi):
        return 146.83 * (2.0 ** (semi / 12.0))  # a partir de Re3

    frigia = [0, 3, 5, 7, 10, 12, 15]

    # pad: tres vozes (unissono/quinta/oitava) com vibrato lento e swell
    for n in range(total):
        t = n / FS
        vib = 1.0 + 0.003 * math.sin(2 * math.pi * 0.13 * t)
        p = 0.0
        for k, semi in enumerate((-12, -5, 0)):
            fp = nota(semi) * vib * (1.0 + 0.002 * k)
            p += math.sin(2 * math.pi * fp * t + k * 1.7)
        swell = 0.55 + 0.45 * math.sin(2 * math.pi * (t / dur) * 2.0 - 1.2)
        buf[n] += p * 0.07 * swell

    # melodia esparsa: notas de "sino" (sino = seno + parcial 2.76 + decay)
    melodia = [(0.5, 12), (2.0, 15), (3.5, 10), (6.0, 7), (8.5, 12),
               (10.0, 17), (12.0, 10), (13.5, 8), (14.5, 5)]
    for t0, semi in melodia:
        f = nota(semi)
        dur_n = 2.2
        for n in range(int(t0 * FS), min(total, int((t0 + dur_n) * FS))):
            tt = n / FS - t0
            env = math.exp(-tt * 1.9)
            s = math.sin(2 * math.pi * f * tt)
            s += 0.5 * math.sin(2 * math.pi * f * 2.76 * tt) * math.exp(-tt * 3.5)
            s += 0.25 * math.sin(2 * math.pi * f * 5.4 * tt) * math.exp(-tt * 6.0)
            buf[n] += s * env * 0.16

    # sopro de vento muito ao fundo
    rw = Reson()
    lp = 0.0
    for n in range(total):
        t = n / FS
        x = random.uniform(-1, 1)
        lp += 0.04 * (x - lp)
        s = rw.passo(lp, 420 + 150 * math.sin(2 * math.pi * 0.03 * t), 260.0)
        buf[n] += s * 0.12

    # passa-baixo geral (suave)
    lp = 0.0
    alp = math.exp(-2 * math.pi * 4200 / FS)
    for n in range(total):
        lp += (1 - alp) * (buf[n] - lp)
        buf[n] = math.tanh(lp * 1.1)

    buf = enrolar(buf, N, cf)
    escrever("menu.wav", buf, 0.85)


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


# --------------------------------------------------------------------------
# 5) SALTO / SALTO DUPLO  (substituem os antigos, que eram asperos e altos)
# --------------------------------------------------------------------------
def _salto(nome, f0c, f1c, brilho, ganho):
    """'Whoop' curto e suave: seno com glissando ascendente + sopro de ar
    muito filtrado. Nada de dente-de-serra/quadrada."""
    # nao usar o hash() nativo de strings: e' salgado por processo
    # (PYTHONHASHSEED) e dava um .wav diferente a cada corrida do script.
    random.seed(zlib.crc32(nome.encode()) & 0xffff)
    dur = 0.12
    N = int(dur * FS)
    buf = [0.0] * N
    lp = 0.0
    for n in range(N):
        p = n / N
        f = f0c + (f1c - f0c) * (p ** 0.6)          # sobe depressa e assenta
        env = min(1.0, p / 0.02) * math.exp(-p * 7.0)  # ataque 2 ms, cai rapido
        s = math.sin(2 * math.pi * f * (n / FS))
        s += 0.18 * brilho * math.sin(2 * math.pi * f * 2.0 * (n / FS)) * math.exp(-p * 10.0)
        ar = random.uniform(-1, 1)
        lp += 0.06 * (ar - lp)                       # ar bem abafado
        s += lp * 0.12 * math.exp(-p * 9.0)
        buf[n] = s * env
    # lowpass geral (~2.6 kHz) para tirar aspereza
    y = 0.0
    a = math.exp(-2 * math.pi * 2600 / FS)
    for n in range(N):
        y += (1 - a) * (buf[n] - y)
        buf[n] = y
    escrever(nome, buf, ganho)


def saltos():
    _salto("salto.wav", 190.0, 360.0, 0.5, 0.34)
    _salto("salto_duplo.wav", 300.0, 560.0, 1.0, 0.30)


# --------------------------------------------------------------------------
# 6) CONQUISTA  (chefe derrotado -- arpejo de sino ascendente, com brilho)
# --------------------------------------------------------------------------
def conquista():
    random.seed(2027)
    dur = 1.7
    N = int(dur * FS)
    buf = [0.0] * N

    def sino(t0, f, amp, decai):
        for n in range(int(t0 * FS), N):
            tt = n / FS - t0
            env = math.exp(-tt * decai)
            s = math.sin(2 * math.pi * f * tt)
            s += 0.55 * math.sin(2 * math.pi * f * 2.01 * tt) * math.exp(-tt * decai * 1.8)
            s += 0.30 * math.sin(2 * math.pi * f * 3.03 * tt) * math.exp(-tt * decai * 3.0)
            s += 0.16 * math.sin(2 * math.pi * f * 4.7 * tt) * math.exp(-tt * decai * 5.0)
            buf[n] += s * env * amp

    # arpejo ascendente (Re maior add9): D4 F#4 A4 D5 E5  -> "hopeful"
    freqs = [293.66, 369.99, 440.0, 587.33, 659.25]
    for i, f in enumerate(freqs):
        sino(0.02 + i * 0.09, f, 0.22 - i * 0.015, 3.4 + i * 0.5)
    # acorde a segurar por baixo
    for f in (146.83, 220.0, 293.66):
        sino(0.0, f, 0.10, 1.6)

    # boom sub no arranque
    for n in range(int(0.5 * FS)):
        tt = n / FS
        buf[n] += math.sin(2 * math.pi * (70 * math.exp(-tt * 4.0) + 32) * tt) * math.exp(-tt * 5.0) * 0.35

    # cintilacao aguda a subir
    for n in range(N):
        tt = n / FS
        f = 1400 + 2600 * min(1.0, tt / 0.6)
        buf[n] += math.sin(2 * math.pi * f * tt) * 0.05 * math.exp(-tt * 2.2) * (tt < 0.7)

    # reverb FIR curto
    taps = [(0.037, 0.4), (0.061, 0.3), (0.089, 0.22), (0.125, 0.15), (0.170, 0.09)]
    wet = [0.0] * N
    for dt, g in taps:
        d = int(dt * FS)
        for n in range(d, N):
            wet[n] += buf[n - d] * g
    for n in range(N):
        buf[n] = buf[n] * 0.9 + wet[n] * 0.5
    fo = int(0.25 * FS)
    for n in range(N - fo, N):
        buf[n] *= (N - n) / fo
    escrever("conquista.wav", buf, 0.9)


# --------------------------------------------------------------------------
# 7) BLOQUEIO  (defesa com escudo -- "tink" metalico curto e subtil)
# --------------------------------------------------------------------------
def bloqueio():
    random.seed(51)
    dur = 0.16
    N = int(dur * FS)
    buf = [0.0] * N
    # duas "campainhas" metalicas curtas + um toque de ruido no ataque
    r1, r2, r3 = Reson(), Reson(), Reson()
    for n in range(N):
        p = n / N
        # excitacao: clique de ruido nos primeiros ~4 ms
        exc = random.uniform(-1, 1) * math.exp(-p * 140.0)
        s = r1.passo(exc, 1850.0, 90.0)
        s += 0.7 * r2.passo(exc, 3200.0, 150.0)
        s += 0.4 * r3.passo(exc, 5400.0, 260.0)
        env = min(1.0, p / 0.002) * math.exp(-p * 22.0)
        buf[n] = s * env
    # passa-alto leve para soar "metal" e nao "madeira"
    hp, ain = 0.0, 0.0
    ahp = math.exp(-2 * math.pi * 500 / FS)
    for n in range(N):
        x = buf[n]
        hp = ahp * (hp + x - ain)
        ain = x
        buf[n] = math.tanh(hp * 1.4)
    escrever("bloqueio.wav", buf, 0.55)


# --------------------------------------------------------------------------
# 8) COMBATE  (espada, acerto, tiro) e 9) SELO DE CHECKPOINT
#
# Refeitos a pedido do Paulo (1 set 2026): os antigos eram agudos, sempre
# iguais e a tocar a 0.85 de pico -- ao fim de dois minutos de jogo davam
# cabo dos ouvidos. Referencia: Dead Cells -- os golpes sao CURTOS, com
# corpo grave e ar por cima (nada de "bip"), e o checkpoint e' um sino
# quente, nao um "ping" brilhante. Quem varia o tom em cada golpe e' o
# `koliani.gd` (Som.toca com pitch aleatorio), para nao cansar.
# --------------------------------------------------------------------------
def espada():
    """Golpe: sopro de ar a descer de tom + corpo grave curto."""
    random.seed(4101)
    dur = 0.15
    N = int(dur * FS)
    buf = [0.0] * N
    ar = Reson()
    for n in range(N):
        p = n / N
        # o "silvo" desce de 1900 para 550 Hz -> le-se como lamina a passar
        # (mais grave do que o instinto pede: o agudo e' que cansa)
        f = 1900.0 - 1350.0 * p
        ruido = random.uniform(-1.0, 1.0)
        s = ar.passo(ruido, f, 650.0) * 0.9
        # corpo: o peso do golpe (fica por baixo, quase nao se "ouve" sozinho)
        corpo = math.sin(2 * math.pi * (150.0 - 60.0 * p) * (n / FS))
        s += corpo * 0.5 * math.exp(-p * 16.0)
        env = min(1.0, p / 0.05) * math.exp(-p * 9.0)
        buf[n] = math.tanh(s * env * 1.3)
    # passa-baixo final: tira o "chiado" que ficava por cima do silvo
    lp = 0.0
    for n in range(N):
        lp += 0.30 * (buf[n] - lp)
        buf[n] = lp
    escrever("ataque.wav", buf, 0.55)


def acerto():
    """Acerto na carne: pancada grave + estalo curto, sem cauda metalica."""
    random.seed(4102)
    dur = 0.18
    N = int(dur * FS)
    buf = [0.0] * N
    crunch, metal = Reson(), Reson()
    fase = 0.0
    for n in range(N):
        p = n / N
        f = 125.0 * (1.0 - 0.55 * p) + 45.0     # pancada que "afunda"
        fase += f / FS
        s = math.sin(2 * math.pi * fase) * math.exp(-p * 15.0)
        ruido = random.uniform(-1.0, 1.0)
        s += crunch.passo(ruido, 1100.0 - 400.0 * p, 900.0) * 0.55 * math.exp(-p * 26.0)
        s += metal.passo(ruido, 2600.0, 400.0) * 0.14 * math.exp(-p * 20.0)
        buf[n] = math.tanh(s * 1.5)
    escrever("acerto.wav", buf, 0.7)


def tiro():
    """Tiro roxo: sopro curto e MOLE (dispara-se sem parar -> tem de ser
    discreto), com um corpo a descer de tom."""
    random.seed(4103)
    dur = 0.14
    N = int(dur * FS)
    buf = [0.0] * N
    ar = Reson()
    lp = 0.0
    fase = 0.0
    for n in range(N):
        p = n / N
        f = 330.0 - 170.0 * p
        fase += f / FS
        s = math.sin(2 * math.pi * fase) * 0.7 * math.exp(-p * 13.0)
        s += ar.passo(random.uniform(-1.0, 1.0), 1000.0 - 650.0 * p, 500.0) * 0.5
        lp += 0.25 * (s - lp)                   # tira o brilho de cima
        env = min(1.0, p / 0.04) * math.exp(-p * 11.0)
        buf[n] = lp * env
    escrever("projetil.wav", buf, 0.42)


def selo():
    """Checkpoint: sino QUENTE de duas notas (sol -> do), ataque suave e
    cauda longa. O antigo era um ping agudo e seco."""
    random.seed(4104)
    dur = 1.1
    N = int(dur * FS)
    buf = [0.0] * N
    # (freq, atraso, peso) -- duas notas + um sub que da' corpo
    notas = [(392.0, 0.0, 1.0), (587.33, 0.16, 0.85), (196.0, 0.0, 0.5)]
    for freq, atraso, peso in notas:
        n0 = int(atraso * FS)
        for n in range(n0, N):
            t = (n - n0) / FS
            env = min(1.0, t / 0.012) * math.exp(-t * 3.0)
            s = math.sin(2 * math.pi * freq * t)
            s += 0.28 * math.sin(2 * math.pi * freq * 2.0 * t) * math.exp(-t * 5.5)
            s += 0.12 * math.sin(2 * math.pi * freq * 3.01 * t) * math.exp(-t * 8.0)
            buf[n] += s * env * peso
    # passa-baixo: nada de arestas agudas
    lp = 0.0
    for n in range(N):
        lp += 0.22 * (buf[n] - lp)
        buf[n] = lp
    escrever("selo.wav", buf, 0.5)


# --------------------------------------------------------------------------
# 9) LEVAR DANO (Koliani) -- baque seco e curto, distinto do ataque
# --------------------------------------------------------------------------
def dano():
    """A Koliani leva dano: baque grave curto + estalido seco no ataque.
    Nada agudo/metalico -- não pode soar ao "investida" dos chefes nem ao
    disparo de uma armadilha, senão confunde-se com "o chefe a atacar"."""
    random.seed(6102)
    dur = 0.3
    N = int(dur * FS)
    buf = [0.0] * N
    for n in range(N):
        t = n / FS
        f = 150.0 * math.exp(-t * 18.0) + 42.0
        buf[n] += math.sin(2 * math.pi * f * t) * math.exp(-t * 16.0) * 0.8
    rr = Reson()
    for n in range(int(0.05 * FS)):
        t = n / FS
        s = rr.passo(random.uniform(-1, 1), 950.0, 550.0)
        buf[n] += s * math.exp(-t * 55.0) * 0.45
    escrever("dano.wav", buf, 0.88)


# --------------------------------------------------------------------------
# 10) INVESTIDA (chefes/armadilhas) -- ataque especial, "whoosh" + impacto
# --------------------------------------------------------------------------
def investida():
    """Investida/ataque especial dos chefes (e das armadilhas que a
    reaproveitam): corte de ar + impacto surdo no fim. Usada a pitch
    variável (0.5-1.7) por cada chefe -- tem de ler como "o chefe ataca",
    não como "eu levo dano" (esse é o `dano.wav`, mais seco e sem o
    whoosh)."""
    random.seed(7301)
    dur = 0.48
    N = int(dur * FS)
    buf = [0.0] * N
    rr = Reson()
    lp = 0.0
    for n in range(N):
        t = n / FS
        p = t / dur
        x = random.uniform(-1, 1)
        lp += 0.12 * (x - lp)
        fc = 1900.0 - 1350.0 * p
        s = rr.passo(lp, max(280.0, fc), 380.0)
        env = math.sin(math.pi * min(1.0, p / 0.55)) ** 0.6 * math.exp(-p * 1.2)
        buf[n] += s * env * 0.85
    t0 = int(0.28 * FS)
    for n in range(t0, N):
        t = (n - t0) / FS
        f = 110.0 * math.exp(-t * 10.0) + 40.0
        buf[n] += math.sin(2 * math.pi * f * t) * math.exp(-t * 9.0) * 0.5
    escrever("investida.wav", buf, 0.88)


# --------------------------------------------------------------------------
# 11) CHEFE CAI (derrota) -- colapso pesado; a fanfarra fica para conquista.wav
# --------------------------------------------------------------------------
def chefe_cai():
    """Chefe derrotado: colapso grave em dois baques + estilhaços curtos.
    Sem nada agudo/festivo aqui -- isso é o `conquista.wav`, que toca logo
    a seguir; este é só o peso da queda."""
    random.seed(8407)
    dur = 0.85
    N = int(dur * FS)
    buf = [0.0] * N
    for t0, amp, f0 in [(0.0, 0.9, 58.0), (0.16, 0.55, 44.0)]:
        n0 = int(t0 * FS)
        for n in range(n0, N):
            t = (n - n0) / FS
            f = f0 * math.exp(-t * 6.0) + 22.0
            buf[n] += math.sin(2 * math.pi * f * t) * math.exp(-t * 5.5) * amp
    for _ in range(14):
        tc = random.uniform(0.02, 0.45)
        rc = Reson()
        for n in range(int(tc * FS), min(N, int((tc + 0.05) * FS))):
            tt = n / FS - tc
            s = rc.passo(random.uniform(-1, 1), random.uniform(1800.0, 3600.0), 500.0)
            buf[n] += s * math.exp(-tt * 90.0) * 0.32
    escrever("chefe_cai.wav", buf, 0.88)


# --------------------------------------------------------------------------
# 12) TRANSIÇÃO DE NÍVEL (porta no fim do nível) -- "whoosh" de portal
# --------------------------------------------------------------------------
def transicao():
    """Avançar para o próximo nível através da porta: sopro de portal
    moderno (ruído filtrado a subir + brilho a entrar), sem nada áspero
    ou repetitivo -- substitui a antiga porta a ranger, ouvida em cada
    nível e por isso repetitiva/irritante."""
    random.seed(5501)
    dur = 0.6
    N = int(dur * FS)
    buf = [0.0] * N
    rr = Reson()
    lp = 0.0
    for n in range(N):
        t = n / FS
        p = t / dur
        x = random.uniform(-1, 1)
        lp += 0.09 * (x - lp)
        fc = 260.0 + 2600.0 * (p ** 1.6)
        s = rr.passo(lp, fc, 260.0 + 500.0 * p)
        env = math.sin(math.pi * min(1.0, p / 0.85)) ** 0.7
        buf[n] += s * env * 0.6
    for n in range(N):
        t = n / FS
        p = t / dur
        if p < 0.25:
            continue
        pp = (p - 0.25) / 0.75
        f = 720.0 + 1400.0 * pp
        env = math.sin(math.pi * pp) * 0.16
        buf[n] += math.sin(2 * math.pi * f * t) * env
        buf[n] += math.sin(2 * math.pi * f * 1.5 * t) * env * 0.4
    fo = int(0.08 * FS)
    for n in range(N - fo, N):
        buf[n] *= max(0.0, (N - n) / fo)
    escrever("transicao.wav", buf, 0.55)


# --------------------------------------------------------------------------
# 13) MAGIA DE CHEFE -- ataque à distância (feixe/projétil mágico)
# --------------------------------------------------------------------------
def chefe_magia():
    """Ataque mágico à distância dos chefes (ex.: o raio do olho do
    Zeriko): um "carregar" agudo em cintilação ascendente + o disparo
    grave a seguir -- lê-se como magia, distinto do "investida" (corpo a
    corpo)."""
    random.seed(9102)
    dur = 0.55
    N = int(dur * FS)
    buf = [0.0] * N
    # carregar: cintilação a subir de frequência, ganha corpo até disparar
    for n in range(int(0.32 * FS)):
        t = n / FS
        p = t / 0.32
        f = 900.0 + 2600.0 * (p ** 1.4)
        env = (p ** 1.6) * 0.3
        buf[n] += math.sin(2 * math.pi * f * t) * env
        buf[n] += math.sin(2 * math.pi * f * 1.5 * t) * env * 0.4
    # disparo: feixe curto e grave, sai no instante em que a cintilação atinge o topo
    t0 = int(0.32 * FS)
    rr = Reson()
    for n in range(t0, N):
        t = (n - t0) / FS
        fc = 700.0 * math.exp(-t * 8.0) + 180.0
        s = rr.passo(random.uniform(-1, 1) * 0.6, fc, 260.0)
        buf[n] += s * math.exp(-t * 7.0) * 0.9
        buf[n] += math.sin(2 * math.pi * fc * t) * math.exp(-t * 9.0) * 0.35
    escrever("chefe_magia.wav", buf, 0.85)


# ==========================================================================
# 14) SONS DE HABILIDADE POR CHEFE  (pedido do Paulo, 2 set 2026)
#
# Até agora quase todos os 30 chefes partilhavam `investida` (corpo a corpo)
# e `chefe_magia` (distância), só variando o pitch. Aqui está uma família de
# timbres POR ARQUÉTIPO DE ATAQUE -- baque no chão, lâmina pesada, garra,
# fogo, gelo, praga, raio, invocação, grito -- mais três ASSINATURAS de
# chefe (o Sino Vivo, o Maquinista, a Dama Guilhotina) e um feixe próprio
# para o Zeriko / Olho do Abismo. Cada `scripts/chefe_*.gd` mapeia agora as
# suas habilidades para o arquétipo certo (continua a variar pitch/volume
# por instância, para dois chefes do mesmo arquétipo não soarem idênticos).
#
# Regra de estilo herdada dos sons de combate: CURTOS, corpo grave + ar por
# cima, nada de "bip" agudo, `tanh` a amaciar o pico.
# ==========================================================================
def _impacto(buf, t0, amp, f0, decai):
    """Baque grave curto somado ao buffer a partir de `t0` s."""
    n0 = int(t0 * FS)
    for n in range(n0, len(buf)):
        t = (n - n0) / FS
        f = f0 * math.exp(-t * 9.0) + 24.0
        buf[n] += math.sin(2 * math.pi * f * t) * math.exp(-t * decai) * amp


def esmagar():
    """Baque no chão / pisão de chefe: sub que afunda + estalo de terra +
    cauda curta de rumor. Substitui os muitos `onda` que eram, na verdade,
    o chefe a bater no solo (Ghorak, Colosso, Carcereiro, Capitão...)."""
    random.seed(31001)
    dur = 0.5
    N = int(dur * FS)
    buf = [0.0] * N
    _impacto(buf, 0.0, 0.95, 82.0, 7.5)
    # estalo de terra: ruído filtrado em banda, cai depressa
    rr = Reson()
    for n in range(int(0.09 * FS)):
        t = n / FS
        s = rr.passo(random.uniform(-1, 1), 720.0 - 2600.0 * t, 900.0)
        buf[n] += s * math.exp(-t * 42.0) * 0.5
    # rumor: ruído grave que treme e esvai
    lp = 0.0
    for n in range(N):
        t = n / FS
        x = random.uniform(-1, 1)
        lp += 0.03 * (x - lp)
        buf[n] += lp * math.exp(-t * 6.0) * 0.35 * (0.7 + 0.3 * math.sin(2 * math.pi * 30.0 * t))
    for n in range(N):
        buf[n] = math.tanh(buf[n] * 1.4)
    escrever("esmagar.wav", buf, 0.9)


def golpe_pesado():
    """Lâmina de duas mãos / gadanha / cutelo: sopro de ar LENTO e grave a
    descer + impacto surdo no fim. Distinto do `ataque` leve da Koliani."""
    random.seed(31002)
    dur = 0.4
    N = int(dur * FS)
    buf = [0.0] * N
    ar = Reson()
    lp = 0.0
    for n in range(N):
        p = n / N
        x = random.uniform(-1, 1)
        lp += 0.10 * (x - lp)
        f = 1200.0 - 950.0 * p          # mais grave que o golpe leve (1900->550)
        s = ar.passo(lp, max(220.0, f), 520.0)
        env = math.sin(math.pi * min(1.0, p / 0.62)) ** 0.7 * math.exp(-p * 1.6)
        buf[n] += s * env * 0.8
    _impacto(buf, 0.24, 0.6, 120.0, 11.0)
    for n in range(N):
        buf[n] = math.tanh(buf[n] * 1.3)
    escrever("golpe_pesado.wav", buf, 0.85)


def garra():
    """Garra / cauda / rajada de talhes: três silvos curtos e agudos,
    escalonados, a fechar depressa (aranha, dragão, Koliani Sombria)."""
    random.seed(31003)
    dur = 0.34
    N = int(dur * FS)
    buf = [0.0] * N
    for k, t0 in enumerate((0.0, 0.045, 0.092)):
        ar = Reson()
        lp = 0.0
        n0 = int(t0 * FS)
        for n in range(n0, min(N, n0 + int(0.13 * FS))):
            p = (n - n0) / (0.13 * FS)
            x = random.uniform(-1, 1)
            lp += 0.16 * (x - lp)
            f = 2600.0 - 1500.0 * p - k * 180.0
            s = ar.passo(lp, max(500.0, f), 700.0)
            env = min(1.0, p / 0.04) * math.exp(-p * 12.0)
            buf[n] += s * env * (0.9 - 0.12 * k)
    for n in range(N):
        buf[n] = math.tanh(buf[n] * 1.25)
    escrever("garra.wav", buf, 0.62)


def chama():
    """Golfada de fogo / ignição de projétil: roar grave + crepitar
    aleatório + ar quente por cima. Ignivar, Arauto, Vyrak, Coração."""
    random.seed(31004)
    dur = 0.5
    N = int(dur * FS)
    buf = [0.0] * N
    roar, ar = Reson(), Reson()
    lp = 0.0
    for n in range(N):
        t = n / FS
        p = t / dur
        x = random.uniform(-1, 1)
        lp += 0.09 * (x - lp)
        s = roar.passo(lp, 240.0 + 90.0 * math.sin(2 * math.pi * 18.0 * t), 260.0) * 0.9
        s += ar.passo(x, 1400.0 - 500.0 * p, 1100.0) * 0.35
        env = math.sin(math.pi * min(1.0, p / 0.7)) ** 0.6 * math.exp(-p * 1.1)
        buf[n] += s * env
    # crepitar: cliques esparsos
    for _ in range(22):
        tc = random.uniform(0.02, dur - 0.03)
        rc = Reson()
        for n in range(int(tc * FS), min(N, int((tc + 0.02) * FS))):
            tt = n / FS - tc
            buf[n] += rc.passo(random.uniform(-1, 1), random.uniform(1600, 3400), 600.0) \
                * math.exp(-tt * 130.0) * 0.3
    for n in range(N):
        buf[n] = math.tanh(buf[n] * 1.3)
    escrever("chama.wav", buf, 0.8)


def gelo():
    """Estilhaço de gelo / maré lunar: cristal vítreo a descer + campainhas
    agudas curtas (Sacerdotisa Lunar, Aerion frio, Morvanna)."""
    random.seed(31005)
    dur = 0.44
    N = int(dur * FS)
    buf = [0.0] * N
    r1, r2, r3 = Reson(), Reson(), Reson()
    for n in range(N):
        p = n / N
        exc = random.uniform(-1, 1) * math.exp(-p * 55.0)
        s = r1.passo(exc, 2600.0, 120.0)
        s += 0.7 * r2.passo(exc, 4300.0, 190.0)
        s += 0.4 * r3.passo(exc, 6400.0, 300.0)
        env = min(1.0, p / 0.004) * math.exp(-p * 9.0)
        buf[n] += s * env
    # cristal a descer (sine glissando) + tinir na cauda
    fase = 0.0
    for n in range(N):
        p = n / N
        f = 3200.0 - 2100.0 * (p ** 0.5)
        fase += f / FS
        buf[n] += math.sin(2 * math.pi * fase) * 0.3 * math.exp(-p * 6.0)
    for _ in range(9):
        tc = random.uniform(0.05, dur - 0.02)
        fc = random.uniform(3800, 7200)
        for n in range(int(tc * FS), min(N, int((tc + 0.05) * FS))):
            tt = n / FS - tc
            buf[n] += math.sin(2 * math.pi * fc * tt) * 0.12 * math.exp(-tt * 40.0)
    hp, ain = 0.0, 0.0
    ahp = math.exp(-2 * math.pi * 600 / FS)
    for n in range(N):
        x = buf[n]
        hp = ahp * (hp + x - ain)
        ain = x
        buf[n] = math.tanh(hp * 1.3)
    escrever("gelo.wav", buf, 0.62)


def praga():
    """Cuspo de veneno / esporos / poça: assopro molhado com borbulhar
    lento + gorgolejo grave (Rainha Aracnídea, Naga, Freira, Coração)."""
    random.seed(31006)
    dur = 0.46
    N = int(dur * FS)
    buf = [0.0] * N
    banda, gorg = Reson(), Reson()
    lp = 0.0
    fase = 0.0
    for n in range(N):
        t = n / FS
        p = t / dur
        x = random.uniform(-1, 1)
        lp += 0.07 * (x - lp)
        borb = 0.5 + 0.5 * math.sin(2 * math.pi * 26.0 * t + 2.0 * math.sin(2 * math.pi * 5.0 * t))
        s = banda.passo(lp, 780.0 - 300.0 * p, 520.0) * (0.5 + 0.5 * borb)
        fase += (150.0 - 60.0 * p) / FS
        s += gorg.passo(math.sin(2 * math.pi * fase), 320.0, 180.0) * 0.6 * math.exp(-p * 2.4)
        env = min(1.0, p / 0.03) * math.exp(-p * 2.6)
        buf[n] += s * env
    for n in range(N):
        buf[n] = math.tanh(buf[n] * 1.35)
    escrever("praga.wav", buf, 0.66)


def raio():
    """Raio / descarga eléctrica: estalo branco seco + zunido a 90 Hz que
    esvai + assobio agudo a descer (Voltaris)."""
    random.seed(31007)
    dur = 0.36
    N = int(dur * FS)
    buf = [0.0] * N
    r1, r2 = Reson(), Reson()
    for n in range(N):
        t = n / FS
        p = t / dur
        # estalo: ruído muito agudo nos primeiros ms
        exc = random.uniform(-1, 1)
        s = r1.passo(exc * math.exp(-p * 30.0), 3200.0, 1400.0) * 0.8
        # zunido eléctrico: AM dura a ~90 Hz sobre banda média
        buzz = (1.0 if math.sin(2 * math.pi * 90.0 * t) > 0 else -1.0)
        s += r2.passo(buzz * exc * 0.3, 1500.0, 500.0) * 0.5 * math.exp(-p * 6.0)
        # assobio a descer
        s += math.sin(2 * math.pi * (4200.0 - 3400.0 * p) * t) * 0.18 * math.exp(-p * 7.0)
        env = min(1.0, p / 0.002) * math.exp(-p * 4.5)
        buf[n] += s * env
    _impacto(buf, 0.0, 0.35, 70.0, 16.0)
    for n in range(N):
        buf[n] = math.tanh(buf[n] * 1.5)
    escrever("raio.wav", buf, 0.72)


def invocar():
    """Invocação / abrir fenda: rumor grave + coro de sines desafinados a
    subir e a florir (todos os chefes que largam clones/servos/cobras)."""
    random.seed(31008)
    dur = 0.6
    N = int(dur * FS)
    buf = [0.0] * N
    lp = 0.0
    for n in range(N):
        t = n / FS
        p = t / dur
        x = random.uniform(-1, 1)
        lp += 0.02 * (x - lp)
        buf[n] += lp * 0.4 * math.exp(-p * 1.6)          # rumor
        p2 = p ** 1.3
        coro = 0.0
        for k, semi in enumerate((-12, -5, 0, 4)):
            f = 110.0 * (2.0 ** (semi / 12.0)) * (1.0 + 0.35 * p2) * (1.0 + 0.004 * k)
            coro += math.sin(2 * math.pi * f * t + k * 1.3)
        env = math.sin(math.pi * min(1.0, p / 0.9)) ** 1.1
        buf[n] += coro * 0.12 * env
    # florir agudo no fim
    for n in range(N):
        t = n / FS
        p = t / dur
        if p < 0.55:
            continue
        pp = (p - 0.55) / 0.45
        buf[n] += math.sin(2 * math.pi * (1400.0 + 1800.0 * pp) * t) * 0.08 * math.sin(math.pi * pp)
    for n in range(N):
        buf[n] = math.tanh(buf[n] * 1.25)
    escrever("invocar.wav", buf, 0.78)


def grito():
    """Grito / uivo / lamento de chefe (buff, mudança de fase, vento):
    duas vozes desafinadas que sobem e descem por um formante, com ar e
    tremolo (Noiva do Eclipse, Morvanna, Entrevane, Aerion)."""
    random.seed(31009)
    dur = 0.55
    N = int(dur * FS)
    buf = [0.0] * N
    fmt = Reson()
    lp = 0.0
    for n in range(N):
        t = n / FS
        p = t / dur
        gliss = 300.0 + 420.0 * math.sin(math.pi * p) + 30.0 * math.sin(2 * math.pi * 6.0 * t)
        src = math.sin(2 * math.pi * gliss * t) + math.sin(2 * math.pi * gliss * 1.012 * t)
        x = random.uniform(-1, 1)
        lp += 0.08 * (x - lp)
        src += lp * 0.4
        s = fmt.passo(src, 780.0 + 300.0 * math.sin(math.pi * p), 110.0)
        trem = 0.78 + 0.22 * math.sin(2 * math.pi * 7.5 * t)
        env = math.sin(math.pi * min(1.0, p / 0.85)) ** 0.7
        buf[n] += s * env * trem * 0.7
    for n in range(N):
        buf[n] = math.tanh(buf[n] * 1.3)
    escrever("grito.wav", buf, 0.74)


def sino_ataque():
    """ASSINATURA do Sino Vivo: badalada de bronze grave, parciais
    inarmónicos e cauda a ressoar -- tudo o que ele faz "toca"."""
    random.seed(31010)
    dur = 0.95
    N = int(dur * FS)
    buf = [0.0] * N
    f0 = 165.0
    for parcial, peso, dec in ((1.0, 1.0, 3.0), (2.76, 0.6, 4.2), (5.40, 0.34, 6.5),
                               (8.93, 0.18, 9.0)):
        for n in range(N):
            t = n / FS
            env = min(1.0, t / 0.006) * math.exp(-t * dec)
            buf[n] += math.sin(2 * math.pi * f0 * parcial * t) * env * peso
    _impacto(buf, 0.0, 0.5, 60.0, 6.0)
    # batida metálica no ataque
    rc = Reson()
    for n in range(int(0.03 * FS)):
        t = n / FS
        buf[n] += rc.passo(random.uniform(-1, 1), 2400.0, 800.0) * math.exp(-t * 90.0) * 0.4
    for n in range(N):
        buf[n] = math.tanh(buf[n] * 0.9)
    escrever("sino_ataque.wav", buf, 0.82)


def engrenagem():
    """ASSINATURA do Maquinista Infernal: engrenagens a ranger (cliques
    ritmados), vapor por cima e um motor grave por baixo."""
    random.seed(31011)
    dur = 0.5
    N = int(dur * FS)
    buf = [0.0] * N
    # motor
    fase = 0.0
    for n in range(N):
        t = n / FS
        p = t / dur
        fase += (92.0 + 10.0 * math.sin(2 * math.pi * 7.0 * t)) / FS
        saw = 2.0 * (fase % 1.0) - 1.0
        buf[n] += saw * 0.28 * math.exp(-p * 1.8)
    # ratchet: cliques metálicos a ~34 Hz
    passo = FS / 34.0
    k = 0
    while k * passo < N:
        tc = k * passo / FS + random.uniform(-0.002, 0.002)
        rc = Reson()
        for n in range(int(tc * FS), min(N, int((tc + 0.03) * FS))):
            tt = n / FS - tc
            buf[n] += rc.passo(random.uniform(-1, 1), 1800.0 + 400.0 * (k % 3), 500.0) \
                * math.exp(-tt * 70.0) * 0.5
        k += 1
    # vapor: ruído passa-alto a esvair
    hp, ain = 0.0, 0.0
    ahp = math.exp(-2 * math.pi * 2600 / FS)
    for n in range(N):
        t = n / FS
        x = random.uniform(-1, 1)
        hp = ahp * (hp + x - ain)
        ain = x
        buf[n] += hp * 0.3 * math.exp(-(t / dur) * 2.2)
    for n in range(N):
        buf[n] = math.tanh(buf[n] * 1.3)
    escrever("engrenagem.wav", buf, 0.72)


def lamina_cair():
    """ASSINATURA da Dama Guilhotina: silvo metálico a acelerar + SCHWING
    agudo + baque pesado da lâmina a assentar."""
    random.seed(31012)
    dur = 0.42
    N = int(dur * FS)
    buf = [0.0] * N
    ar = Reson()
    lp = 0.0
    for n in range(N):
        p = n / N
        x = random.uniform(-1, 1)
        lp += 0.12 * (x - lp)
        f = 600.0 + 2600.0 * (p ** 1.8)     # acelera para cima
        s = ar.passo(lp, f, 400.0)
        env = (p ** 0.7) * (p < 0.62)
        buf[n] += s * env * 0.6
    # schwing: ping brilhante no instante do corte
    t0 = int(0.6 * dur * FS)
    r1, r2 = Reson(), Reson()
    for n in range(t0, N):
        tt = (n - t0) / FS
        exc = random.uniform(-1, 1) * math.exp(-tt * 120.0)
        s = r1.passo(exc, 3100.0, 130.0) + 0.6 * r2.passo(exc, 5200.0, 240.0)
        buf[n] += s * math.exp(-tt * 16.0) * 0.7
    _impacto(buf, 0.62 * dur, 0.7, 95.0, 13.0)
    for n in range(N):
        buf[n] = math.tanh(buf[n] * 1.35)
    escrever("lamina_cair.wav", buf, 0.8)


def feixe_vil():
    """Feixe do Zeriko / Olho do Abismo: carregar grave e sombrio + feixe
    longo com ondulação lenta (mais ameaçador que o `chefe_magia` comum)."""
    random.seed(31013)
    dur = 0.62
    N = int(dur * FS)
    buf = [0.0] * N
    # carregar: cintilação BAIXA a ganhar corpo
    for n in range(int(0.34 * FS)):
        t = n / FS
        p = t / 0.34
        f = 460.0 + 1200.0 * (p ** 1.5)
        env = (p ** 1.8) * 0.34
        buf[n] += math.sin(2 * math.pi * f * t) * env
        buf[n] += math.sin(2 * math.pi * f * 0.5 * t) * env * 0.5     # sub-oitava = "vil"
    # feixe: ruído grave com AM lenta + sub
    t0 = int(0.34 * FS)
    rr = Reson()
    for n in range(t0, N):
        t = (n - t0) / FS
        wob = 0.7 + 0.3 * math.sin(2 * math.pi * 11.0 * t)
        fc = 520.0 * math.exp(-t * 5.0) + 150.0
        s = rr.passo(random.uniform(-1, 1) * 0.6, fc, 240.0) * wob
        buf[n] += s * math.exp(-t * 4.5) * 0.9
        buf[n] += math.sin(2 * math.pi * fc * 0.5 * t) * math.exp(-t * 6.0) * 0.4
    for n in range(N):
        buf[n] = math.tanh(buf[n] * 1.3)
    escrever("feixe_vil.wav", buf, 0.82)


def meteoro():
    """Zeriko F1 -- chuva de meteoros púrpura (antes só caíam em silêncio):
    assobio a descer + chiar de magia + baque roxo no fim."""
    random.seed(31014)
    dur = 0.55
    N = int(dur * FS)
    buf = [0.0] * N
    fase = 0.0
    ar = Reson()
    lp = 0.0
    for n in range(N):
        p = n / N
        f = 1800.0 * math.exp(-p * 2.6) + 260.0        # assobio que despenha
        fase += f / FS
        s = math.sin(2 * math.pi * fase) * 0.55
        x = random.uniform(-1, 1)
        lp += 0.10 * (x - lp)
        s += ar.passo(lp, 2200.0 - 1400.0 * p, 900.0) * 0.4    # ar rasgado
        # chiar de magia: parcial agudo tremido
        s += math.sin(2 * math.pi * f * 3.01 * (n / FS)) * 0.12 * math.exp(-p * 3.0) \
            * (0.6 + 0.4 * math.sin(2 * math.pi * 40.0 * (n / FS)))
        env = min(1.0, p / 0.02) * (1.0 - 0.3 * p)
        buf[n] += s * env
    _impacto(buf, 0.42, 0.7, 96.0, 12.0)
    for n in range(N):
        buf[n] = math.tanh(buf[n] * 1.35)
    escrever("meteoro.wav", buf, 0.78)


def mudar_forma():
    """Zeriko / Arauto -- transição de forma: rumor grave a SUBIR de tom,
    coro desafinado a inchar e um rasgão no pico (o momento em que a coisa
    troca de cara). Fica por cima do `chefe_cai` que parte a armadura."""
    random.seed(31015)
    dur = 0.72
    N = int(dur * FS)
    buf = [0.0] * N
    lp = 0.0
    for n in range(N):
        t = n / FS
        p = t / dur
        # sub a subir 45 -> 130 Hz
        fsub = 45.0 + 85.0 * (p ** 1.4)
        buf[n] += math.sin(2 * math.pi * fsub * t) * 0.5 * (0.3 + 0.7 * p)
        # coro desafinado a inchar
        coro = 0.0
        for k, semi in enumerate((-5, 0, 1, 6)):     # cluster de 2a menor = "errado"
            f = 130.0 * (2.0 ** (semi / 12.0)) * (1.0 + 0.006 * k)
            coro += math.sin(2 * math.pi * f * t + k * 1.9)
        buf[n] += coro * 0.10 * (p ** 1.2)
        # sopro que cresce (reverse-swell)
        x = random.uniform(-1, 1)
        lp += 0.05 * (x - lp)
        buf[n] += lp * 0.35 * (p ** 2.0)
    # rasgão no pico
    t0 = int(0.62 * dur * FS)
    rc = Reson()
    for n in range(t0, N):
        tt = (n - t0) / FS
        s = rc.passo(random.uniform(-1, 1), 1400.0 - 6000.0 * tt, 1200.0)
        buf[n] += s * math.exp(-tt * 22.0) * 0.6
    fo = int(0.1 * FS)
    for n in range(N - fo, N):
        buf[n] *= (N - n) / fo
    for n in range(N):
        buf[n] = math.tanh(buf[n] * 1.3)
    escrever("mudar_forma.wav", buf, 0.82)


def olho_carregar():
    """Telégrafo do olho / laser (Zeriko F3, Olho do Abismo) -- antes o
    aviso era mudo. Zunido sombrio a subir de tom com um brilho a ganhar
    corpo; SEM impacto (é só o carregar, o disparo é o `feixe_vil`)."""
    random.seed(31016)
    dur = 0.5
    N = int(dur * FS)
    buf = [0.0] * N
    for n in range(N):
        t = n / FS
        p = t / dur
        g = 120.0 + 220.0 * (p ** 1.3)
        s = math.sin(2 * math.pi * g * t) + math.sin(2 * math.pi * g * 1.008 * t)
        s *= 0.35
        # brilho agudo a entrar na 2a metade
        if p > 0.4:
            pp = (p - 0.4) / 0.6
            s += math.sin(2 * math.pi * (1600.0 + 1800.0 * pp) * t) * 0.12 * pp
        trem = 0.8 + 0.2 * math.sin(2 * math.pi * 9.0 * t)
        env = (p ** 0.8) * (1.0 if p < 0.92 else (1.0 - p) / 0.08)
        buf[n] += s * env * trem
    for n in range(N):
        buf[n] = math.tanh(buf[n] * 1.3)
    escrever("olho_carregar.wav", buf, 0.6)


if __name__ == "__main__":
    game_over_voz()
    menu_loop()
    boss_loop()
    assombracao_loop()
    demonio_ataque()
    saltos()
    conquista()
    bloqueio()
    espada()
    acerto()
    tiro()
    selo()
    dano()
    investida()
    chefe_cai()
    transicao()
    chefe_magia()
    # sons de habilidade por chefe (2 set 2026)
    esmagar()
    golpe_pesado()
    garra()
    chama()
    gelo()
    praga()
    raio()
    invocar()
    grito()
    sino_ataque()
    engrenagem()
    lamina_cair()
    feixe_vil()
    meteoro()
    mudar_forma()
    olho_carregar()
