#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Os "andares" dos chefes: uma POSE por frame, por plano de corpo.

Um plano de corpo (humanoide, flutuante, aracnideo, serpente, alado,
quadrupede, objeto) fixa os NOMES das juntas; cada funcao daqui devolve
`junta -> (dx, dy, rotacao)` para o frame `i` de `n` do estado pedido.

Regras que valem para todos:

  - o chefe olha para a DIREITA (convencao do jogo: `scale.x = +olha_para`);
  - `t` no nome e' o lado de TRAS e `f` o da FRENTE -- o de tras desenha-se
    mais escuro e por baixo, e' o que da' profundidade a um boneco de lado;
  - o ataque tem sempre tres tempos: RECUO (telegrafo), GOLPE e RECUPERAR.
    O telegrafo e' o que deixa o jogador reagir, por isso ocupa quase
    metade dos frames -- e' desenho a servir a mecanica, nao enfeite.

Uma junta que a funcao nao mencione fica em repouso `(0, 0, 0)`.
"""

from __future__ import annotations

import math

Pose = dict[str, tuple[float, float, float]]


def _osc(i: int, n: int, fase: float = 0.0) -> float:
    """Seno de um ciclo completo ao longo dos `n` frames."""
    return math.sin(2.0 * math.pi * (i / float(n) + fase))


def _rampa(i: int, n: int) -> float:
    """0 -> 1 ao longo da animacao (para as que nao sao em ciclo)."""
    return i / float(max(1, n - 1))


def _fases_ataque(i: int, n: int) -> tuple[float, float, float]:
    """Reparte o ataque em (recuo, golpe, recuperar), cada um 0..1.

    Recuo ate' 45% dos frames, golpe ate' 62% (rapido, e' o impacto),
    recuperar o resto.
    """
    t = _rampa(i, n)
    if t < 0.45:
        return t / 0.45, 0.0, 0.0
    if t < 0.62:
        return 1.0, (t - 0.45) / 0.17, 0.0
    return 1.0, 1.0, (t - 0.62) / 0.38


# ── humanoide (serve tambem os colossos: e' so' subir as proporcoes) ──────

def humanoide(estado: str, i: int, n: int, cfg: dict) -> Pose:
    amp = float(cfg.get("amp", 1.0))
    estilo = cfg.get("ataque", "golpe")
    p: Pose = {}

    if estado == "idle":
        s = _osc(i, n)
        p["raiz"] = (0.0, -0.8 * s * amp, 0.0)
        p["torso"] = (0.0, -0.6 * s * amp, 1.2 * s)
        p["cabeca"] = (0.0, 0.0, -1.6 * s)
        p["ombro_t"] = (0.0, 0.0, 6.0 + 4.0 * s)
        p["ombro_f"] = (0.0, 0.0, -5.0 - 4.0 * s)
        p["cotovelo_t"] = (0.0, 0.0, 8.0 + 3.0 * s)
        p["cotovelo_f"] = (0.0, 0.0, 10.0 - 3.0 * s)

    elif estado == "walk":
        s = _osc(i, n)
        c = _osc(i, n, 0.25)
        p["raiz"] = (0.0, -1.6 * abs(c) * amp, 0.0)
        p["torso"] = (0.0, 0.0, 3.0 * c)
        p["cabeca"] = (0.0, 0.0, -2.0 * c)
        p["coxa_f"] = (0.0, 0.0, 26.0 * s)
        p["coxa_t"] = (0.0, 0.0, -26.0 * s)
        p["joelho_f"] = (0.0, 0.0, max(0.0, -30.0 * s))
        p["joelho_t"] = (0.0, 0.0, max(0.0, 30.0 * s))
        p["ombro_f"] = (0.0, 0.0, -22.0 * s)
        p["ombro_t"] = (0.0, 0.0, 22.0 * s)
        p["cotovelo_f"] = (0.0, 0.0, 14.0)
        p["cotovelo_t"] = (0.0, 0.0, 14.0)

    elif estado == "attack":
        recuo, golpe, volta = _fases_ataque(i, n)
        if estilo == "magia":
            # bracos ao ceu, corpo em arco para tras, e o golpe e' a
            # descarga -- o boneco quase nao anda, quem se move e' a magia
            p["raiz"] = (-2.0 * recuo + 3.0 * golpe, -1.0 * recuo, 0.0)
            p["torso"] = (0.0, 0.0, -12.0 * recuo + 20.0 * golpe - 8.0 * volta)
            p["cabeca"] = (0.0, 0.0, -8.0 * recuo + 10.0 * golpe)
            p["ombro_t"] = (0.0, 0.0, -120.0 * recuo + 70.0 * golpe)
            p["ombro_f"] = (0.0, 0.0, -140.0 * recuo + 95.0 * golpe)
            p["cotovelo_t"] = (0.0, 0.0, -20.0 * recuo + 30.0 * golpe)
            p["cotovelo_f"] = (0.0, 0.0, -25.0 * recuo + 35.0 * golpe)
        elif estilo == "investida":
            # agacha, arranca e trava -- a arma vai a' frente do corpo
            p["raiz"] = (-6.0 * recuo + 22.0 * golpe - 6.0 * volta,
                         4.0 * recuo - 2.0 * golpe, 0.0)
            p["torso"] = (0.0, 0.0, -10.0 * recuo + 26.0 * golpe - 10.0 * volta)
            p["cabeca"] = (0.0, 0.0, 6.0 * recuo - 12.0 * golpe)
            p["ombro_f"] = (0.0, 0.0, 30.0 * recuo - 80.0 * golpe)
            p["ombro_t"] = (0.0, 0.0, 40.0 * recuo - 30.0 * golpe)
            p["coxa_f"] = (0.0, 0.0, 20.0 * recuo - 40.0 * golpe)
            p["coxa_t"] = (0.0, 0.0, -20.0 * recuo + 34.0 * golpe)
        else:   # "golpe": arma atras da cabeca e desce em arco
            p["raiz"] = (-4.0 * recuo + 10.0 * golpe - 4.0 * volta, 0.0, 0.0)
            p["torso"] = (0.0, 0.0, -14.0 * recuo + 30.0 * golpe - 12.0 * volta)
            p["cabeca"] = (0.0, 0.0, 8.0 * recuo - 14.0 * golpe)
            p["ombro_f"] = (0.0, 0.0, -110.0 * recuo + 190.0 * golpe - 40.0 * volta)
            p["cotovelo_f"] = (0.0, 0.0, -30.0 * recuo + 60.0 * golpe)
            p["ombro_t"] = (0.0, 0.0, 45.0 * recuo - 60.0 * golpe)
            p["coxa_f"] = (0.0, 0.0, -10.0 * recuo + 22.0 * golpe)
            p["coxa_t"] = (0.0, 0.0, 12.0 * recuo - 18.0 * golpe)

    elif estado == "hurt":
        t = _rampa(i, n)
        k = math.sin(math.pi * t)
        p["raiz"] = (-7.0 * k, -1.5 * k, 0.0)
        p["torso"] = (0.0, 0.0, -18.0 * k)
        p["cabeca"] = (0.0, 0.0, -16.0 * k)
        p["ombro_t"] = (0.0, 0.0, -50.0 * k)
        p["ombro_f"] = (0.0, 0.0, -35.0 * k)
        p["coxa_t"] = (0.0, 0.0, -14.0 * k)

    elif estado == "death":
        t = _rampa(i, n)
        e = t * t              # cai a acelerar, como deve ser
        p["raiz"] = (-14.0 * t, 10.0 * e, -78.0 * e)
        p["torso"] = (0.0, 0.0, 16.0 * t)
        p["cabeca"] = (0.0, 0.0, 26.0 * t)
        p["ombro_t"] = (0.0, 0.0, -70.0 * t)
        p["ombro_f"] = (0.0, 0.0, -50.0 * t)
        p["coxa_f"] = (0.0, 0.0, 40.0 * t)
        p["coxa_t"] = (0.0, 0.0, -30.0 * t)
    return p


# ── flutuante (bruxas, fantasmas, olhos, entidades) ──────────────────────

def flutuante(estado: str, i: int, n: int, cfg: dict) -> Pose:
    amp = float(cfg.get("amp", 1.0))
    estilo = cfg.get("ataque", "magia")
    p: Pose = {}

    # Asas OPCIONAIS: quem nao as tiver ignora estas entradas (a pose pode
    # falar de juntas que o esqueleto nao tem). E' o que deixa o Aerion e o
    # Arauto voarem sem precisarem de um plano de corpo so' para eles.
    bat = {"idle": 0.6, "walk": 1.0, "attack": 0.9, "hurt": 0.5, "death": 0.25}
    for lado, atraso in (("asa_t", 0.06), ("asa_f", 0.0)):
        p[lado] = (0.0, 0.0, 30.0 * _osc(i, n, atraso) * bat.get(estado, 0.6))

    if estado == "idle":
        s = _osc(i, n)
        p["raiz"] = (0.0, -3.0 * s * amp, 0.0)
        p["corpo"] = (0.0, 0.0, 2.5 * s)
        p["cabeca"] = (0.0, -0.6 * s, -3.0 * s)
        p["ombro_t"] = (0.0, 0.0, -14.0 + 7.0 * s)
        p["ombro_f"] = (0.0, 0.0, 12.0 - 7.0 * s)
        p["cauda1"] = (0.0, 0.0, 7.0 * s)
        p["cauda2"] = (0.0, 0.0, 11.0 * _osc(i, n, 0.18))

    elif estado == "walk":
        s = _osc(i, n)
        p["raiz"] = (2.0 * _osc(i, n, 0.25), -4.0 * s * amp, 0.0)
        p["corpo"] = (0.0, 0.0, 5.0 * s)
        p["cabeca"] = (0.0, 0.0, -4.0 * s)
        p["ombro_t"] = (0.0, 0.0, -26.0 + 9.0 * s)
        p["ombro_f"] = (0.0, 0.0, 22.0 - 9.0 * s)
        p["cauda1"] = (0.0, 0.0, 13.0 * s)
        p["cauda2"] = (0.0, 0.0, 19.0 * _osc(i, n, 0.2))

    elif estado == "attack":
        recuo, golpe, volta = _fases_ataque(i, n)
        if estilo == "investida":
            p["raiz"] = (-8.0 * recuo + 26.0 * golpe - 8.0 * volta,
                         -3.0 * recuo + 4.0 * golpe, 0.0)
            p["corpo"] = (0.0, 0.0, -14.0 * recuo + 24.0 * golpe)
            p["cabeca"] = (0.0, 0.0, 8.0 * recuo - 16.0 * golpe)
            p["ombro_t"] = (0.0, 0.0, 30.0 * recuo - 70.0 * golpe)
            p["ombro_f"] = (0.0, 0.0, -30.0 * recuo - 40.0 * golpe)
        else:
            p["raiz"] = (-3.0 * recuo + 5.0 * golpe, -6.0 * recuo + 2.0 * golpe, 0.0)
            p["corpo"] = (0.0, 0.0, -10.0 * recuo + 16.0 * golpe - 6.0 * volta)
            p["cabeca"] = (0.0, 0.0, -6.0 * recuo + 8.0 * golpe)
            p["ombro_t"] = (0.0, 0.0, -130.0 * recuo + 80.0 * golpe)
            p["ombro_f"] = (0.0, 0.0, -150.0 * recuo + 100.0 * golpe)
            p["cauda1"] = (0.0, 0.0, -10.0 * recuo + 14.0 * golpe)
            p["cauda2"] = (0.0, 0.0, -16.0 * recuo + 22.0 * golpe)

    elif estado == "hurt":
        k = math.sin(math.pi * _rampa(i, n))
        p["raiz"] = (-8.0 * k, 3.0 * k, 0.0)
        p["corpo"] = (0.0, 0.0, -20.0 * k)
        p["cabeca"] = (0.0, 0.0, -14.0 * k)
        p["ombro_t"] = (0.0, 0.0, -45.0 * k)
        p["ombro_f"] = (0.0, 0.0, 40.0 * k)
        p["cauda1"] = (0.0, 0.0, -18.0 * k)

    elif estado == "death":
        t = _rampa(i, n)
        # nao tomba: AFUNDA-SE e desfaz-se, que e' o que um espectro faz
        p["raiz"] = (0.0, 26.0 * t * t, 12.0 * t)
        p["corpo"] = (0.0, 0.0, -10.0 * t)
        p["cabeca"] = (0.0, 2.0 * t, 22.0 * t)
        p["ombro_t"] = (0.0, 0.0, -60.0 * t)
        p["ombro_f"] = (0.0, 0.0, 55.0 * t)
        p["cauda1"] = (0.0, 0.0, 26.0 * t)
        p["cauda2"] = (0.0, 0.0, 38.0 * t)
    return p


# ── aracnideo (3 pares de patas visiveis, 2 segmentos cada) ──────────────

_PATAS = ["pa1", "pa2", "pa3", "pf1", "pf2", "pf3"]
_FASE_PATA = {"pa1": 0.0, "pf2": 0.08, "pa3": 0.16,
              "pf1": 0.5, "pa2": 0.58, "pf3": 0.66}


def aracnideo(estado: str, i: int, n: int, cfg: dict) -> Pose:
    amp = float(cfg.get("amp", 1.0))
    p: Pose = {}

    if estado == "idle":
        s = _osc(i, n)
        p["raiz"] = (0.0, -1.2 * s * amp, 0.0)
        p["corpo"] = (0.0, 0.0, 1.5 * s)
        p["cabeca"] = (0.0, 0.0, -2.5 * s)
        for k, nome in enumerate(_PATAS):
            q = _osc(i, n, _FASE_PATA[nome])
            p[nome] = (0.0, 0.0, 5.0 * q)
            p[nome + "j"] = (0.0, 0.0, -7.0 * q)

    elif estado == "walk":
        p["raiz"] = (0.0, -2.0 * abs(_osc(i, n, 0.25)) * amp, 0.0)
        p["corpo"] = (0.0, 0.0, 3.0 * _osc(i, n, 0.25))
        p["cabeca"] = (0.0, 0.0, -3.0 * _osc(i, n, 0.25))
        for nome in _PATAS:
            q = _osc(i, n, _FASE_PATA[nome])
            p[nome] = (0.0, 0.0, 22.0 * q)
            p[nome + "j"] = (0.0, -1.5 * max(0.0, q), -26.0 * max(0.0, q))

    elif estado == "attack":
        recuo, golpe, volta = _fases_ataque(i, n)
        # levanta-se nas patas de tras e deixa-se cair para a frente
        p["raiz"] = (-4.0 * recuo + 16.0 * golpe - 6.0 * volta,
                     -10.0 * recuo + 8.0 * golpe, 0.0)
        p["corpo"] = (0.0, 0.0, -22.0 * recuo + 34.0 * golpe - 12.0 * volta)
        p["cabeca"] = (0.0, 0.0, -14.0 * recuo + 22.0 * golpe)
        for nome in ("pf1", "pf2", "pf3"):
            p[nome] = (0.0, 0.0, -45.0 * recuo + 60.0 * golpe)
            p[nome + "j"] = (0.0, 0.0, 30.0 * recuo - 40.0 * golpe)
        for nome in ("pa1", "pa2", "pa3"):
            p[nome] = (0.0, 0.0, 14.0 * recuo - 10.0 * golpe)

    elif estado == "hurt":
        k = math.sin(math.pi * _rampa(i, n))
        p["raiz"] = (-6.0 * k, 3.0 * k, 0.0)
        p["corpo"] = (0.0, 0.0, 12.0 * k)
        p["cabeca"] = (0.0, 0.0, 10.0 * k)
        for nome in _PATAS:
            p[nome] = (0.0, 0.0, -16.0 * k)
            p[nome + "j"] = (0.0, 0.0, 20.0 * k)

    elif estado == "death":
        t = _rampa(i, n)
        # patas encolhidas para dentro, como uma aranha morta de verdade
        p["raiz"] = (0.0, 6.0 * t * t, 8.0 * t)
        p["corpo"] = (0.0, 0.0, -12.0 * t)
        p["cabeca"] = (0.0, 0.0, 18.0 * t)
        for nome in _PATAS:
            p[nome] = (0.0, 0.0, -55.0 * t)
            p[nome + "j"] = (0.0, 0.0, 75.0 * t)
    return p


# ── serpente (cauda em cadeia + tronco humanoide por cima) ───────────────

_ANEIS = ["s1", "s2", "s3", "s4", "s5"]


def serpente(estado: str, i: int, n: int, cfg: dict) -> Pose:
    amp = float(cfg.get("amp", 1.0))
    p: Pose = {}
    onda = {"idle": 5.0, "walk": 11.0, "attack": 7.0,
            "hurt": 4.0, "death": 3.0}.get(estado, 5.0)

    for k, nome in enumerate(_ANEIS):
        p[nome] = (0.0, 0.0, onda * _osc(i, n, -0.12 * k) * amp)

    if estado == "idle":
        s = _osc(i, n)
        p["raiz"] = (0.0, -1.0 * s, 0.0)
        p["torso"] = (0.0, 0.0, 3.0 * s)
        p["cabeca"] = (0.0, 0.0, -3.5 * s)
        p["ombro_t"] = (0.0, 0.0, -10.0 + 6.0 * s)
        p["ombro_f"] = (0.0, 0.0, 9.0 - 6.0 * s)

    elif estado == "walk":
        s = _osc(i, n)
        p["raiz"] = (0.0, -2.0 * abs(s), 0.0)
        p["torso"] = (0.0, 0.0, 6.0 * s)
        p["cabeca"] = (0.0, 0.0, -6.0 * s)
        p["ombro_t"] = (0.0, 0.0, -18.0 * s)
        p["ombro_f"] = (0.0, 0.0, 18.0 * s)

    elif estado == "attack":
        recuo, golpe, volta = _fases_ataque(i, n)
        # enrola-se para tras e projecta o tronco -- a bordoada e' a cabeca
        p["raiz"] = (-6.0 * recuo + 18.0 * golpe - 6.0 * volta, 0.0, 0.0)
        p["torso"] = (0.0, 0.0, -26.0 * recuo + 44.0 * golpe - 16.0 * volta)
        p["cabeca"] = (0.0, 0.0, -16.0 * recuo + 26.0 * golpe)
        p["ombro_t"] = (0.0, 0.0, -80.0 * recuo + 120.0 * golpe)
        p["ombro_f"] = (0.0, 0.0, -95.0 * recuo + 140.0 * golpe)

    elif estado == "hurt":
        k = math.sin(math.pi * _rampa(i, n))
        p["raiz"] = (-7.0 * k, 0.0, 0.0)
        p["torso"] = (0.0, 0.0, -22.0 * k)
        p["cabeca"] = (0.0, 0.0, -18.0 * k)
        p["ombro_t"] = (0.0, 0.0, -40.0 * k)
        p["ombro_f"] = (0.0, 0.0, 30.0 * k)

    elif estado == "death":
        t = _rampa(i, n)
        p["raiz"] = (-6.0 * t, 8.0 * t * t, 0.0)
        p["torso"] = (0.0, 0.0, 60.0 * t)
        p["cabeca"] = (0.0, 0.0, 40.0 * t)
        p["ombro_t"] = (0.0, 0.0, -50.0 * t)
        p["ombro_f"] = (0.0, 0.0, 45.0 * t)
        for k, nome in enumerate(_ANEIS):
            p[nome] = (0.0, 0.0, 14.0 * t * (1 if k % 2 else -1))
    return p


# ── alado (dragoes e cavaleiros que voam sempre) ─────────────────────────

def alado(estado: str, i: int, n: int, cfg: dict) -> Pose:
    amp = float(cfg.get("amp", 1.0))
    p: Pose = {}
    bat = {"idle": 1.0, "walk": 1.5, "attack": 1.2,
           "hurt": 0.8, "death": 0.3}.get(estado, 1.0)
    s = _osc(i, n)
    # as asas batem SEMPRE -- e' o que separa um bicho que voa de um boneco
    # pendurado no ar
    for lado, sinal in (("t", 1.0), ("f", 1.0)):
        atraso = 0.0 if lado == "f" else 0.06
        q = _osc(i, n, atraso)
        p["asa_%s1" % lado] = (0.0, 0.0, sinal * 32.0 * q * bat)
        p["asa_%s2" % lado] = (0.0, 0.0, sinal * 26.0 * _osc(i, n, atraso + 0.12) * bat)

    if estado == "idle":
        p["raiz"] = (0.0, -4.0 * s * amp, 0.0)
        p["corpo"] = (0.0, 0.0, 2.0 * s)
        p["pescoco"] = (0.0, 0.0, -3.0 * s)
        p["cabeca"] = (0.0, 0.0, -2.0 * s)
        p["cauda1"] = (0.0, 0.0, 8.0 * s)
        p["cauda2"] = (0.0, 0.0, 12.0 * _osc(i, n, 0.2))
        p["perna_t"] = (0.0, 0.0, 10.0 + 5.0 * s)
        p["perna_f"] = (0.0, 0.0, 6.0 - 5.0 * s)

    elif estado == "walk":
        p["raiz"] = (3.0 * _osc(i, n, 0.25), -6.0 * s * amp, 0.0)
        p["corpo"] = (0.0, 0.0, -4.0 + 3.0 * s)
        p["pescoco"] = (0.0, 0.0, -5.0 * s)
        p["cabeca"] = (0.0, 0.0, -4.0 * s)
        p["cauda1"] = (0.0, 0.0, 14.0 * s)
        p["cauda2"] = (0.0, 0.0, 20.0 * _osc(i, n, 0.2))
        p["perna_t"] = (0.0, 0.0, 18.0 + 8.0 * s)
        p["perna_f"] = (0.0, 0.0, 12.0 - 8.0 * s)

    elif estado == "attack":
        recuo, golpe, volta = _fases_ataque(i, n)
        # recolhe o pescoco, abre as asas e cospe/morde para a frente
        p["raiz"] = (-6.0 * recuo + 16.0 * golpe - 6.0 * volta,
                     -6.0 * recuo + 6.0 * golpe, 0.0)
        p["corpo"] = (0.0, 0.0, -12.0 * recuo + 20.0 * golpe)
        p["pescoco"] = (0.0, 0.0, 26.0 * recuo - 48.0 * golpe + 16.0 * volta)
        p["cabeca"] = (0.0, 0.0, 16.0 * recuo - 34.0 * golpe)
        p["asa_t1"] = (0.0, 0.0, -46.0 * recuo + 20.0 * golpe)
        p["asa_f1"] = (0.0, 0.0, -50.0 * recuo + 22.0 * golpe)
        p["cauda1"] = (0.0, 0.0, 18.0 * recuo - 24.0 * golpe)

    elif estado == "hurt":
        k = math.sin(math.pi * _rampa(i, n))
        p["raiz"] = (-9.0 * k, 4.0 * k, 0.0)
        p["corpo"] = (0.0, 0.0, 14.0 * k)
        p["pescoco"] = (0.0, 0.0, -26.0 * k)
        p["cabeca"] = (0.0, 0.0, -18.0 * k)
        p["asa_t1"] = (0.0, 0.0, 30.0 * k)
        p["asa_f1"] = (0.0, 0.0, 34.0 * k)

    elif estado == "death":
        t = _rampa(i, n)
        p["raiz"] = (-8.0 * t, 30.0 * t * t, 26.0 * t)
        p["corpo"] = (0.0, 0.0, 10.0 * t)
        p["pescoco"] = (0.0, 0.0, 34.0 * t)
        p["cabeca"] = (0.0, 0.0, 28.0 * t)
        p["asa_t1"] = (0.0, 0.0, 70.0 * t)
        p["asa_f1"] = (0.0, 0.0, 62.0 * t)
        p["cauda1"] = (0.0, 0.0, -24.0 * t)
        p["perna_t"] = (0.0, 0.0, 40.0 * t)
        p["perna_f"] = (0.0, 0.0, 34.0 * t)
    return p


# ── quadrupede (o rei morto e o seu cavalo esqueletico) ──────────────────

_PATAS4 = ["pat_dt", "pat_df", "pat_tt", "pat_tf"]
_FASE4 = {"pat_df": 0.0, "pat_tt": 0.12, "pat_dt": 0.5, "pat_tf": 0.62}


def quadrupede(estado: str, i: int, n: int, cfg: dict) -> Pose:
    amp = float(cfg.get("amp", 1.0))
    p: Pose = {}

    if estado == "idle":
        s = _osc(i, n)
        p["raiz"] = (0.0, -1.0 * s * amp, 0.0)
        p["corpo"] = (0.0, 0.0, 1.2 * s)
        p["pescoco"] = (0.0, 0.0, -3.0 * s)
        p["cabeca"] = (0.0, 0.0, 2.0 * s)
        p["cavaleiro"] = (0.0, 0.0, -2.0 * s)
        p["braco_c"] = (0.0, 0.0, -8.0 + 6.0 * s)
        for nome in _PATAS4:
            p[nome] = (0.0, 0.0, 4.0 * _osc(i, n, _FASE4[nome]))

    elif estado == "walk":
        s = _osc(i, n, 0.25)
        p["raiz"] = (0.0, -3.0 * abs(s) * amp, 0.0)
        p["corpo"] = (0.0, 0.0, 3.0 * s)
        p["pescoco"] = (0.0, 0.0, -6.0 * s)
        p["cabeca"] = (0.0, 0.0, 4.0 * s)
        p["cavaleiro"] = (0.0, -1.0 * abs(s), -4.0 * s)
        for nome in _PATAS4:
            q = _osc(i, n, _FASE4[nome])
            p[nome] = (0.0, 0.0, 30.0 * q)
            p[nome + "j"] = (0.0, 0.0, -34.0 * max(0.0, q))

    elif estado == "attack":
        recuo, golpe, volta = _fases_ataque(i, n)
        # empina-se e o cavaleiro desce a arma
        p["raiz"] = (-4.0 * recuo + 12.0 * golpe - 4.0 * volta, -6.0 * recuo, 0.0)
        p["corpo"] = (0.0, 0.0, -26.0 * recuo + 18.0 * golpe + 8.0 * volta)
        p["pescoco"] = (0.0, 0.0, -14.0 * recuo + 10.0 * golpe)
        p["cabeca"] = (0.0, 0.0, -10.0 * recuo + 16.0 * golpe)
        p["cavaleiro"] = (0.0, 0.0, 10.0 * recuo - 6.0 * golpe)
        p["braco_c"] = (0.0, 0.0, -120.0 * recuo + 190.0 * golpe - 40.0 * volta)
        p["pat_df"] = (0.0, 0.0, -60.0 * recuo + 50.0 * golpe)
        p["pat_dt"] = (0.0, 0.0, -50.0 * recuo + 42.0 * golpe)

    elif estado == "hurt":
        k = math.sin(math.pi * _rampa(i, n))
        p["raiz"] = (-6.0 * k, 2.0 * k, 0.0)
        p["corpo"] = (0.0, 0.0, 10.0 * k)
        p["pescoco"] = (0.0, 0.0, -20.0 * k)
        p["cavaleiro"] = (0.0, 0.0, -16.0 * k)
        p["braco_c"] = (0.0, 0.0, -40.0 * k)

    elif estado == "death":
        t = _rampa(i, n)
        p["raiz"] = (-8.0 * t, 16.0 * t * t, -40.0 * t * t)
        p["corpo"] = (0.0, 0.0, 12.0 * t)
        p["pescoco"] = (0.0, 0.0, 30.0 * t)
        p["cabeca"] = (0.0, 0.0, 20.0 * t)
        p["cavaleiro"] = (0.0, 0.0, -30.0 * t)
        p["braco_c"] = (0.0, 0.0, -70.0 * t)
        for nome in _PATAS4:
            p[nome] = (0.0, 0.0, 50.0 * t)
            p[nome + "j"] = (0.0, 0.0, -60.0 * t)
    return p


# ── objeto vivo (o Sino Vivo: um sino que baloica e abre a boca) ─────────

def objeto(estado: str, i: int, n: int, cfg: dict) -> Pose:
    amp = float(cfg.get("amp", 1.0))
    p: Pose = {}

    if estado == "idle":
        s = _osc(i, n)
        p["raiz"] = (0.0, -1.5 * s * amp, 0.0)
        p["corpo"] = (0.0, 0.0, 4.0 * s)
        p["badalo"] = (0.0, 0.0, -9.0 * _osc(i, n, 0.12))
        p["cabeca"] = (0.0, 0.0, -2.0 * s)
        p["ombro_t"] = (0.0, 0.0, 10.0 * s)
        p["ombro_f"] = (0.0, 0.0, -10.0 * s)

    elif estado == "walk":
        s = _osc(i, n)
        # nao anda: SALTITA, com o sino a badalar a cada pousada
        p["raiz"] = (0.0, -7.0 * abs(s) * amp, 0.0)
        p["corpo"] = (0.0, 0.0, 9.0 * s)
        p["badalo"] = (0.0, 0.0, -22.0 * _osc(i, n, 0.1))
        p["cabeca"] = (0.0, 0.0, -5.0 * s)
        p["ombro_t"] = (0.0, 0.0, 24.0 * s)
        p["ombro_f"] = (0.0, 0.0, -24.0 * s)

    elif estado == "attack":
        recuo, golpe, volta = _fases_ataque(i, n)
        # inclina-se todo para tras e devolve a badalada -- a onda sonora
        # e' o `golpe`
        p["raiz"] = (-3.0 * recuo + 8.0 * golpe, -4.0 * recuo + 3.0 * golpe, 0.0)
        p["corpo"] = (0.0, 0.0, -30.0 * recuo + 46.0 * golpe - 16.0 * volta)
        p["badalo"] = (0.0, 0.0, 40.0 * recuo - 80.0 * golpe + 30.0 * volta)
        p["cabeca"] = (0.0, 0.0, -12.0 * recuo + 18.0 * golpe)
        p["ombro_t"] = (0.0, 0.0, -60.0 * recuo + 40.0 * golpe)
        p["ombro_f"] = (0.0, 0.0, -70.0 * recuo + 50.0 * golpe)

    elif estado == "hurt":
        k = math.sin(math.pi * _rampa(i, n))
        p["raiz"] = (-6.0 * k, 0.0, 0.0)
        p["corpo"] = (0.0, 0.0, -22.0 * k)
        p["badalo"] = (0.0, 0.0, 34.0 * k)
        p["cabeca"] = (0.0, 0.0, -12.0 * k)

    elif estado == "death":
        t = _rampa(i, n)
        p["raiz"] = (-6.0 * t, 12.0 * t * t, -70.0 * t * t)
        p["corpo"] = (0.0, 0.0, 14.0 * t)
        p["badalo"] = (0.0, 0.0, -40.0 * t)
        p["cabeca"] = (0.0, 0.0, 24.0 * t)
        p["ombro_t"] = (0.0, 0.0, -50.0 * t)
        p["ombro_f"] = (0.0, 0.0, 45.0 * t)
    return p


PLANOS = {
    "humanoide": humanoide,
    "flutuante": flutuante,
    "aracnideo": aracnideo,
    "serpente": serpente,
    "alado": alado,
    "quadrupede": quadrupede,
    "objeto": objeto,
}
