#!/usr/bin/env python3
"""Sintese original e deterministica da assinatura sonora da Koliani.

Uso: py -3.14 tools/gerar_sfx_koliani_signature.py
Nao usa samples externos: ar filtrado, transientes curtos e uma ressonancia
metalica de duas notas formam a familia Shadowblade. Saida PCM mono 44,1 kHz.
"""

from __future__ import annotations

from array import array
import math
from pathlib import Path
import random
import wave


TAXA = 44100
RAIZ = Path(__file__).resolve().parents[1]
SAIDA = RAIZ / "assets/audio/koliani_signature"

# Corpo ouvido na janela mais forte de 50 ms, antes do volume do callsite.
# Os passos ficam discretos, o remate pode dominar; nao e' LUFS uniforme.
ALVO_CORPO = {
    "koliani_jump": -11.5,
    "koliani_double_jump": -10.8,
    "koliani_land_soft": -18.0,
    "koliani_land_medium": -14.0,
    "koliani_land_hard": -11.0,
    "koliani_dash": -10.5,
    "koliani_roll": -14.0,
    "koliani_wall": -20.0,
    "koliani_grab": -15.0,
    "koliani_step_1": -16.0,
    "koliani_step_2": -15.8,
    "koliani_step_3": -15.6,
    "shadowblade_swing_1": -12.0,
    "shadowblade_swing_2": -11.0,
    "shadowblade_swing_3": -10.0,
    "shadowblade_finisher": -8.5,
    "shadowblade_hit": -9.5,
    "shadowblade_hit_v2": -9.3,
    "shadowblade_hit_v3": -9.1,
    "shadowblade_critical": -8.0,
    "shadowblade_energy_cast": -12.0,
    "koliani_energy_hit": -11.0,
    "shadow_shield_on": -12.5,
    "shadow_shield_hit": -9.5,
    "koliani_hurt": -10.0,
    "koliani_hurt_heavy": -8.8,
    "koliani_death": -9.0,
    "koliani_stomp": -11.0,
}


def vazio(duracao: float) -> array:
    return array("f", [0.0]) * round(duracao * TAXA)


def pulso(buf: array, inicio: float, duracao: float, ganho: float,
          grave: float, semente: int) -> None:
    """Impacto material: ruido passa-banda, sem subgrave nem clique digital."""
    rng = random.Random(semente)
    baixo = alto = 0.0
    primeiro = int(inicio * TAXA)
    quantidade = min(round(duracao * TAXA), len(buf) - primeiro)
    for i in range(max(0, quantidade)):
        t = i / TAXA
        x = rng.uniform(-1.0, 1.0)
        baixo += (x - baixo) * grave
        alto += (x - alto) * min(0.86, grave * 5.0)
        env = (1.0 - math.exp(-t * 1400.0)) * math.exp(-t * 40.0 / duracao)
        buf[primeiro + i] += (alto - baixo) * env * ganho


def ar(buf: array, inicio: float, duracao: float, ganho: float,
       abertura: float, semente: int, reverso: bool = False) -> None:
    """Corte de ar com centro espectral movel, nao um whoosh de biblioteca."""
    rng = random.Random(semente)
    lento = rapido = 0.0
    primeiro = int(inicio * TAXA)
    quantidade = min(round(duracao * TAXA), len(buf) - primeiro)
    for i in range(max(0, quantidade)):
        u = i / max(1, quantidade - 1)
        fase = 1.0 - u if reverso else u
        coef = 0.045 + abertura * (0.22 + 0.55 * math.sin(math.pi * fase))
        x = rng.uniform(-1.0, 1.0)
        lento += (x - lento) * max(0.015, coef * 0.24)
        rapido += (x - rapido) * min(0.90, coef)
        env = math.sin(math.pi * u) ** (0.70 if reverso else 1.35)
        buf[primeiro + i] += (rapido - lento) * env * ganho


def varrer(buf: array, inicio: float, duracao: float, ganho: float,
           f0: float, f1: float, queda: float = 4.0,
           harmonicos: float = 0.20) -> None:
    primeiro = int(inicio * TAXA)
    quantidade = min(round(duracao * TAXA), len(buf) - primeiro)
    fase = 0.0
    for i in range(max(0, quantidade)):
        u = i / max(1, quantidade - 1)
        frequencia = f0 * (f1 / f0) ** u
        fase += math.tau * frequencia / TAXA
        env = (1.0 - math.exp(-i / 70.0)) * math.exp(-queda * u)
        buf[primeiro + i] += (math.sin(fase) + harmonicos * math.sin(2.01 * fase)) * env * ganho


def sombra(buf: array, inicio: float, duracao: float, ganho: float,
           inclinacao: float = 1.0) -> None:
    """Duas parciais nao perfeitamente harmonicas: assinatura Shadowblade."""
    varrer(buf, inicio, duracao, ganho, 554.0 * inclinacao,
           370.0 * inclinacao, 5.2, 0.12)
    varrer(buf, inicio + 0.006, max(0.01, duracao - 0.006), ganho * 0.43,
           835.0 * inclinacao, 565.0 * inclinacao, 7.0, 0.06)


def finalizar(nome: str, buf: array, pico_db: float) -> None:
    # Segura o pico E aproxima o corpo de um alvo proprio. Normalizar apenas
    # por pico repetiria o erro da 9H.13: muita crista, pouca energia audivel.
    n = len(buf)
    for i in range(min(35, n)):
        buf[i] *= i / 35.0
    for i in range(min(500, n)):
        buf[n - 1 - i] *= i / 500.0
    maior = max((abs(x) for x in buf), default=1.0)
    teto = 10.0 ** (pico_db / 20.0)

    def processar(drive: float) -> array:
        divisor = math.tanh(drive)
        return array("f", (math.tanh(x / max(maior, 1e-9) * drive) /
                           divisor * teto for x in buf))

    def corpo_50ms(amostras: array) -> float:
        janela = round(TAXA * 0.05)
        passo = janela // 2
        quadrados = [x * x for x in amostras]
        maior_rms = 0.0
        for i in range(0, len(amostras) - janela + 1, passo):
            maior_rms = max(maior_rms,
                            math.sqrt(sum(quadrados[i:i + janela]) / janela))
        return 20.0 * math.log10(max(maior_rms, 1e-9))

    alvo = ALVO_CORPO[nome]
    baixo, alto = 0.10, 18.0
    for _ in range(10):
        meio = (baixo + alto) * 0.5
        if corpo_50ms(processar(meio)) < alvo:
            baixo = meio
        else:
            alto = meio
    final = processar(alto)
    medido = corpo_50ms(final)
    pcm = array("h", (max(-32767, min(32767, round(x * 32767))) for x in final))
    caminho = SAIDA / (nome + ".wav")
    with wave.open(str(caminho), "wb") as saida:
        saida.setnchannels(1)
        saida.setsampwidth(2)
        saida.setframerate(TAXA)
        saida.writeframes(pcm.tobytes())
    print(f"{caminho.name:31} {n / TAXA:.3f}s  pico {pico_db:.1f} dBFS"
          f"  corpo {medido:.1f}/{alvo:.1f} dBFS")


def movimento() -> None:
    b = vazio(0.20)
    pulso(b, 0.0, 0.045, 0.42, 0.12, 11)
    varrer(b, 0.0, 0.105, 0.36, 280, 430, 4.7)
    finalizar("koliani_jump", b, -4.7)

    b = vazio(0.27)
    pulso(b, 0.0, 0.037, 0.28, 0.16, 12)
    ar(b, 0.006, 0.12, 0.26, 0.34, 13)
    sombra(b, 0.010, 0.21, 0.39, 1.32)
    finalizar("koliani_double_jump", b, -4.0)

    for indice, (nome, dur, forca, tom, pico) in enumerate((
        ("koliani_land_soft", 0.16, 0.22, 165, -9.0),
        ("koliani_land_medium", 0.23, 0.39, 190, -6.0),
        ("koliani_land_hard", 0.32, 0.59, 220, -3.8),
    )):
        b = vazio(dur)
        pulso(b, 0.0, 0.046 + indice * 0.013, forca, 0.11, 30 + indice)
        varrer(b, 0.001, 0.09 + indice * 0.03, forca * 0.42,
               tom, 85, 5.0)
        if indice > 0:
            ar(b, 0.018, 0.07 + indice * 0.03, forca * 0.23,
               0.18, 40 + indice)
        finalizar(nome, b, pico)

    b = vazio(0.28)
    pulso(b, 0.0, 0.023, 0.27, 0.23, 50)
    ar(b, 0.0, 0.17, 0.62, 0.67, 51, True)
    varrer(b, 0.004, 0.19, 0.50, 950, 270, 3.0, 0.04)
    sombra(b, 0.028, 0.19, 0.26, 0.88)
    finalizar("koliani_dash", b, -3.4)

    b = vazio(0.31)
    for i, t in enumerate((0.0, 0.091, 0.173)):
        pulso(b, t, 0.034, 0.23 - 0.025 * i, 0.12, 60 + i)
        ar(b, t, 0.085, 0.20, 0.25, 70 + i)
    finalizar("koliani_roll", b, -6.5)

    b = vazio(0.17)
    ar(b, 0.0, 0.12, 0.22, 0.19, 80)
    pulso(b, 0.024, 0.050, 0.12, 0.08, 81)
    finalizar("koliani_wall", b, -10.0)

    b = vazio(0.21)
    pulso(b, 0.0, 0.044, 0.28, 0.16, 82)
    varrer(b, 0.014, 0.12, 0.18, 320, 225, 6.0)
    finalizar("koliani_grab", b, -7.0)

    for i in range(3):
        b = vazio(0.12)
        pulso(b, 0.0, 0.039 + 0.004 * i, 0.27,
              0.10 + 0.02 * i, 90 + i)
        varrer(b, 0.0, 0.060, 0.13, 180 + 25 * i, 110, 8.0)
        finalizar(f"koliani_step_{i + 1}", b, -9.5 + 0.4 * i)


def espada() -> None:
    # Os quatro ataques partilham sombra/metal mas nao a mesma forma de onda.
    perfis = (
        ("shadowblade_swing_1", 0.19, 0.060, 0.47, 1.17, -4.8),
        ("shadowblade_swing_2", 0.22, 0.078, 0.51, 0.98, -4.3),
        ("shadowblade_swing_3", 0.29, 0.102, 0.58, 0.83, -3.9),
        ("shadowblade_finisher", 0.39, 0.125, 0.66, 0.68, -3.4),
    )
    for i, (nome, dur, corte, peso, incl, pico) in enumerate(perfis):
        b = vazio(dur)
        inicio = 0.034 if i == 3 else 0.0
        if i == 3:
            ar(b, 0.0, 0.052, 0.21, 0.22, 100, True)
        pulso(b, inicio, 0.022 + i * 0.004, 0.27 + i * 0.055,
              0.25, 101 + i)
        ar(b, inicio, corte, peso, 0.58 - i * 0.055, 110 + i,
           reverso=i == 2)
        varrer(b, inicio + 0.004, 0.10 + i * 0.015, 0.26 + i * 0.05,
               1250 - i * 115, 490 - i * 45, 5.3)
        sombra(b, inicio + 0.010, 0.12 + i * 0.037,
               0.18 + i * 0.055, incl)
        if i == 3:
            pulso(b, 0.048, 0.042, 0.18, 0.12, 119)
        finalizar(nome, b, pico)

    for i in range(3):
        b = vazio(0.19 + i * 0.018)
        pulso(b, 0.0, 0.048, 0.52, 0.19 + i * 0.02, 130 + i)
        varrer(b, 0.002, 0.075, 0.36, 540 + 60 * i, 225, 7.0)
        sombra(b, 0.011, 0.12, 0.27, 1.02 + 0.04 * i)
        finalizar("shadowblade_hit" + ("" if i == 0 else f"_v{i + 1}"),
                 b, -4.1 + 0.35 * i)

    b = vazio(0.37)
    pulso(b, 0.0, 0.069, 0.67, 0.25, 140)
    varrer(b, 0.003, 0.17, 0.57, 790, 250, 4.2)
    sombra(b, 0.014, 0.30, 0.47, 0.72)
    pulso(b, 0.025, 0.033, 0.16, 0.33, 141)
    finalizar("shadowblade_critical", b, -3.0)

    b = vazio(0.33)
    ar(b, 0.0, 0.10, 0.25, 0.35, 150, True)
    sombra(b, 0.024, 0.22, 0.40, 1.41)
    varrer(b, 0.057, 0.17, 0.24, 400, 840, 4.8)
    finalizar("shadowblade_energy_cast", b, -4.5)


def defesa_e_dano() -> None:
    b = vazio(0.31)
    ar(b, 0.0, 0.115, 0.17, 0.25, 160, True)
    sombra(b, 0.018, 0.25, 0.51, 1.19)
    finalizar("shadow_shield_on", b, -5.5)

    b = vazio(0.29)
    pulso(b, 0.0, 0.054, 0.76, 0.27, 161)
    varrer(b, 0.0, 0.13, 0.43, 1150, 490, 6.7)
    sombra(b, 0.010, 0.19, 0.37, 0.85)
    finalizar("shadow_shield_hit", b, -3.7)

    b = vazio(0.24)
    pulso(b, 0.0, 0.052, 0.52, 0.17, 170)
    varrer(b, 0.002, 0.12, 0.31, 380, 150, 6.0)
    finalizar("koliani_hurt", b, -4.6)

    b = vazio(0.34)
    pulso(b, 0.0, 0.072, 0.66, 0.20, 171)
    varrer(b, 0.002, 0.19, 0.43, 510, 115, 4.2)
    ar(b, 0.020, 0.11, 0.17, 0.15, 172)
    finalizar("koliani_hurt_heavy", b, -3.8)

    b = vazio(0.77)
    pulso(b, 0.0, 0.070, 0.52, 0.14, 180)
    varrer(b, 0.0, 0.37, 0.58, 540, 88, 2.2)
    sombra(b, 0.045, 0.35, 0.38, 0.62)
    ar(b, 0.13, 0.40, 0.15, 0.15, 181, True)
    finalizar("koliani_death", b, -3.6)

    # Impacto do projétil de energia: magia curta e limpa, sem o transiente
    # metálico do impacto da Shadowblade.
    b = vazio(0.22)
    pulso(b, 0.0, 0.036, 0.36, 0.16, 185)
    varrer(b, 0.002, 0.14, 0.34, 720, 260, 6.8, 0.10)
    sombra(b, 0.014, 0.15, 0.16, 1.55)
    finalizar("koliani_energy_hit", b, -6.0)

    b = vazio(0.21)
    pulso(b, 0.0, 0.061, 0.58, 0.11, 190)
    varrer(b, 0.002, 0.10, 0.34, 245, 96, 6.2)
    finalizar("koliani_stomp", b, -4.6)


def main() -> None:
    SAIDA.mkdir(parents=True, exist_ok=True)
    movimento()
    espada()
    defesa_e_dano()


if __name__ == "__main__":
    main()
