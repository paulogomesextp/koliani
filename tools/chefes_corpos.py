#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Os CORPOS: para cada plano, a arvore de juntas + as pecas de base.

Um chefe concreto (ver `tools/gerar_chefes_anim.py`) escolhe um plano,
passa as proporcoes e a paleta, e depois PENDURA os adereços que contam o
lore dele -- a foice, a coroa, o nucleo roxo no peito, o sino, as chamas.
Aqui ficam so' as pecas que todos os corpos daquele plano tem.

Convencoes:
  - y cresce para BAIXO; a raiz esta' no chao, portanto o corpo desenha-se
    com y NEGATIVO;
  - o boneco olha para a DIREITA (+x);
  - `_t` e' o membro de TRAS (mais escuro, z negativo) e `_f` o da FRENTE.

A paleta de um chefe e' um dicionario com estas chaves:
    corpo · corpo2 (segundo tom) · pele · detalhe · metal · brilho ·
    contorno
"""

from __future__ import annotations

import math

from chefes_desenho import (CENTRO_X, CHAO_Y, Cor, Peca, caixa, clarear,
                            elipse, escurecer, espelhar_x, membro, mover,
                            rodar, trapezio)

Juntas = dict[str, tuple[str | None, tuple[float, float]]]


def _atras(c: Cor) -> Cor:
    """Membro do lado de tras: o mesmo tom, mais fundo na sombra."""
    return escurecer(c, 0.34)


# ── humanoide ────────────────────────────────────────────────────────────

HUMANOIDE = {
    "coxa": 15.0, "canela": 14.0, "esp_perna": 8.0,
    "torso": 22.0, "ombros": 20.0, "cintura": 13.0,
    "braco": 12.0, "antebraco": 11.0, "esp_braco": 6.0,
    "cabeca": 7.0, "pescoco": 3.0,
}


def humanoide(par: dict, pal: dict) -> tuple[Juntas, list[Peca]]:
    p = dict(HUMANOIDE)
    p.update(par)
    pernas = p["coxa"] + p["canela"]
    juntas: Juntas = {
        "raiz": (None, (CENTRO_X, CHAO_Y - pernas)),
        "anca": ("raiz", (0.0, 0.0)),
        "torso": ("anca", (0.0, 0.0)),
        "cabeca": ("torso", (1.0, -p["torso"] - p["pescoco"])),
        "ombro_t": ("torso", (-2.0, -p["torso"] + 4.0)),
        "ombro_f": ("torso", (3.0, -p["torso"] + 5.0)),
        "cotovelo_t": ("ombro_t", (0.0, p["braco"])),
        "cotovelo_f": ("ombro_f", (0.0, p["braco"])),
        "coxa_t": ("anca", (-3.5, -1.0)),
        "coxa_f": ("anca", (3.0, -1.0)),
        "joelho_t": ("coxa_t", (0.0, p["coxa"])),
        "joelho_f": ("coxa_f", (0.0, p["coxa"])),
        "arma": ("cotovelo_f", (0.0, p["antebraco"] * 0.9)),
    }

    c, c2 = pal["corpo"], pal["corpo2"]
    pes: list[Peca] = [
        # perna de tras
        Peca("coxa_t", membro(p["coxa"], p["esp_perna"]), _atras(c2), -2.0, tag="coxa_t"),
        Peca("joelho_t", membro(p["canela"], p["esp_perna"] * 0.82), _atras(c2), -2.0,
             tag="canela_t"),
        Peca("joelho_t", caixa(-p["esp_perna"] * 0.4, p["canela"] - 3.0,
                               p["esp_perna"] * 0.8, p["canela"]), _atras(pal["metal"]), -1.9,
             tag="pe_t"),
        # braco de tras
        Peca("ombro_t", membro(p["braco"], p["esp_braco"]), _atras(c), -1.5, tag="braco_t"),
        Peca("cotovelo_t", membro(p["antebraco"], p["esp_braco"] * 0.85), _atras(pal["pele"]),
             -1.5, tag="antebraco_t"),
        # tronco
        Peca("torso", trapezio(-p["torso"], p["ombros"], 0.0, p["cintura"]), c, 0.0, tag="torso"),
        # perna da frente
        Peca("coxa_f", membro(p["coxa"], p["esp_perna"]), c2, 1.0, tag="coxa_f"),
        Peca("joelho_f", membro(p["canela"], p["esp_perna"] * 0.82), c2, 1.0, tag="canela_f"),
        Peca("joelho_f", caixa(-p["esp_perna"] * 0.4, p["canela"] - 3.0,
                               p["esp_perna"] * 0.9, p["canela"]), pal["metal"], 1.1, tag="pe_f"),
        # cabeca
        Peca("torso", caixa(-2.5, -p["torso"] - p["pescoco"], 3.5, -p["torso"] + 2.0),
             pal["pele"], 1.5, tag="pescoco"),
        Peca("cabeca", elipse(0.0, -p["cabeca"] * 0.55, p["cabeca"], p["cabeca"] * 1.05),
             pal["pele"], 2.0, tag="cabeca"),
        # braco da frente
        Peca("ombro_f", membro(p["braco"], p["esp_braco"]), c, 3.0, tag="braco_f"),
        Peca("cotovelo_f", membro(p["antebraco"], p["esp_braco"] * 0.85), pal["pele"], 3.0,
             tag="antebraco_f"),
    ]
    return juntas, pes


# ── flutuante ────────────────────────────────────────────────────────────

FLUTUANTE = {
    "voo": 26.0, "torso": 22.0, "ombros": 17.0, "cintura": 12.0,
    "braco": 11.0, "antebraco": 10.0, "esp_braco": 5.0,
    "cabeca": 7.0, "manto": 24.0, "manto_larg": 20.0, "cauda": 14.0,
}


def flutuante(par: dict, pal: dict) -> tuple[Juntas, list[Peca]]:
    p = dict(FLUTUANTE)
    p.update(par)
    juntas: Juntas = {
        "raiz": (None, (CENTRO_X, CHAO_Y - p["voo"])),
        "corpo": ("raiz", (0.0, 0.0)),
        "cabeca": ("corpo", (1.0, -p["torso"] - 3.0)),
        "ombro_t": ("corpo", (-2.0, -p["torso"] + 5.0)),
        "ombro_f": ("corpo", (3.0, -p["torso"] + 6.0)),
        "cotovelo_t": ("ombro_t", (0.0, p["braco"])),
        "cotovelo_f": ("ombro_f", (0.0, p["braco"])),
        "cauda1": ("corpo", (0.0, 0.0)),
        "cauda2": ("cauda1", (0.0, p["manto"])),
        "arma": ("cotovelo_f", (0.0, p["antebraco"] * 0.9)),
    }

    c, c2 = pal["corpo"], pal["corpo2"]
    pes: list[Peca] = [
        Peca("ombro_t", membro(p["braco"], p["esp_braco"]), _atras(c), -1.5, tag="braco_t"),
        Peca("cotovelo_t", membro(p["antebraco"], p["esp_braco"] * 0.85), _atras(pal["pele"]),
             -1.5, tag="antebraco_t"),
        # manto que desce e se desfaz em duas pontas -- nao ha' pernas
        Peca("cauda1", trapezio(0.0, p["manto_larg"], p["manto"], p["manto_larg"] * 0.5), c2,
             -0.5, tag="manto"),
        Peca("cauda2", [(-p["manto_larg"] * 0.26, 0.0), (p["manto_larg"] * 0.26, 0.0),
                        (p["manto_larg"] * 0.05, p["cauda"]),
                        (-p["manto_larg"] * 0.16, p["cauda"] * 0.7)],
             escurecer(c2, 0.2), -0.6, tag="ponta"),
        Peca("corpo", trapezio(-p["torso"], p["ombros"], 0.0, p["cintura"]), c, 0.0, tag="torso"),
        Peca("corpo", caixa(-2.0, -p["torso"] - 3.0, 3.0, -p["torso"] + 2.0), pal["pele"], 1.5,
             tag="pescoco"),
        Peca("cabeca", elipse(0.0, -p["cabeca"] * 0.55, p["cabeca"], p["cabeca"] * 1.05),
             pal["pele"], 2.0, tag="cabeca"),
        Peca("ombro_f", membro(p["braco"], p["esp_braco"]), c, 3.0, tag="braco_f"),
        Peca("cotovelo_f", membro(p["antebraco"], p["esp_braco"] * 0.85), pal["pele"], 3.0,
             tag="antebraco_f"),
    ]
    return juntas, pes


# ── aracnideo ────────────────────────────────────────────────────────────

ARACNIDEO = {
    "alt": 26.0, "abdomen": 17.0, "cefalo": 11.0,
    "seg1": 17.0, "seg2": 18.0, "esp_pata": 4.0, "cabeca": 7.0,
}

# (nome, x na aresta do corpo, angulo de repouso do 1.o segmento)
# As patas saem MUITO abertas de proposito: fechadas, ficavam escondidas
# atras do abdomen e a Rainha lia-se como uma bola com cabeca.
_PATAS_BASE = [
    ("pa1", -9.0, 152.0), ("pa2", -2.0, 128.0), ("pa3", 5.0, 104.0),
    ("pf1", -8.0, -152.0), ("pf2", -1.0, -128.0), ("pf3", 6.0, -104.0),
]


def aracnideo(par: dict, pal: dict) -> tuple[Juntas, list[Peca]]:
    p = dict(ARACNIDEO)
    p.update(par)
    juntas: Juntas = {
        "raiz": (None, (CENTRO_X, CHAO_Y - p["alt"])),
        "corpo": ("raiz", (0.0, 0.0)),
        "cabeca": ("corpo", (p["cefalo"] + 2.0, -p["cefalo"] * 0.5)),
    }
    for nome, x, ang in _PATAS_BASE:
        juntas[nome] = ("corpo", (x, -2.0))
        # O "joelho" tem de ficar na PONTA do 1.o segmento ja' rodado. Ao
        # deixa'-lo em (0, seg1) -- como estava -- o angulo de repouso vivia
        # so' no desenho e a canela nascia noutro sitio: as patas saiam
        # todas penduradas por baixo da barriga, como um pente.
        a = math.radians(ang)
        juntas[nome + "j"] = (nome, (-p["seg1"] * math.sin(a), p["seg1"] * math.cos(a)))

    c, c2 = pal["corpo"], pal["corpo2"]
    pes: list[Peca] = []
    # as patas de tras primeiro (mais escuras e por baixo de tudo)
    for nome, _x, ang in _PATAS_BASE:
        atras = nome.startswith("pa")
        tom = _atras(c2) if atras else c2
        # as patas da frente ficam a' frente do corpo mas ATRAS do rosto
        # humano -- senao passam-lhe por cima da cara
        z = -3.0 if atras else 0.8
        # a pata sai da junta ja' aberta: e' o angulo de repouso, somado
        # depois pela pose
        pes.append(Peca(nome, _pata(p["seg1"], p["esp_pata"], ang), tom, z, tag=nome))
        # o 2.o segmento cai quase a direito: e' o "joelho" da aranha
        pes.append(Peca(nome + "j", _pata(p["seg2"], p["esp_pata"] * 0.8, ang * 0.22),
                        tom, z, tag=nome))
    pes += [
        Peca("corpo", elipse(-p["abdomen"] * 0.75, -p["abdomen"] * 0.25,
                             p["abdomen"], p["abdomen"] * 0.86), c, 0.0, tag="abdomen"),
        Peca("corpo", elipse(p["cefalo"] * 0.2, 0.0, p["cefalo"], p["cefalo"] * 0.8), c2, 0.5, tag="cefalo"),
        # rosto humano preso a' frente do cefalotorax -- e' o lore inteiro
        Peca("cabeca", elipse(0.0, -p["cabeca"] * 0.3, p["cabeca"] * 0.86, p["cabeca"]),
             pal["pele"], 1.0, tag="cabeca"),
    ]
    return juntas, pes


def _pata(comp: float, esp: float, ang: float) -> list[tuple[float, float]]:
    """Segmento de pata ja' rodado `ang` graus a partir da junta."""
    from chefes_desenho import rodar
    return rodar(membro(comp, esp, esp * 0.55), ang)


# ── serpente ─────────────────────────────────────────────────────────────

SERPENTE = {
    "anel": 15.0, "esp_anel": 13.0, "torso": 22.0, "ombros": 18.0,
    "braco": 12.0, "antebraco": 11.0, "esp_braco": 5.5, "cabeca": 7.0,
}


def serpente(par: dict, pal: dict) -> tuple[Juntas, list[Peca]]:
    p = dict(SERPENTE)
    p.update(par)
    juntas: Juntas = {
        "raiz": (None, (CENTRO_X + 6.0, CHAO_Y - p["esp_anel"] * 0.5)),
        "s1": ("raiz", (0.0, 0.0)),
    }
    for k in range(2, 6):
        juntas["s%d" % k] = ("s%d" % (k - 1), (-p["anel"], 0.0))
    juntas.update({
        "torso": ("s1", (0.0, -p["esp_anel"] * 0.4)),
        "cabeca": ("torso", (1.0, -p["torso"] - 3.0)),
        "ombro_t": ("torso", (-2.0, -p["torso"] + 5.0)),
        "ombro_f": ("torso", (3.0, -p["torso"] + 6.0)),
        "cotovelo_t": ("ombro_t", (0.0, p["braco"])),
        "cotovelo_f": ("ombro_f", (0.0, p["braco"])),
        "arma": ("cotovelo_f", (0.0, p["antebraco"] * 0.9)),
    })

    c, c2 = pal["corpo"], pal["corpo2"]
    pes: list[Peca] = [
        Peca("ombro_t", membro(p["braco"], p["esp_braco"]), _atras(c), -1.5),
        Peca("cotovelo_t", membro(p["antebraco"], p["esp_braco"] * 0.85), _atras(pal["pele"]), -1.5),
    ]
    for k in range(5, 0, -1):
        esp = p["esp_anel"] * (0.42 + 0.14 * k)
        pes.append(Peca("s%d" % k,
                        elipse(-p["anel"] * 0.5, 0.0, p["anel"] * 0.72, esp * 0.5),
                        c2 if k % 2 else escurecer(c2, 0.12), -1.0 + k * 0.05))
    pes += [
        Peca("torso", trapezio(-p["torso"], p["ombros"], 2.0, p["ombros"] * 0.86), c, 0.5, tag="torso"),
        Peca("torso", caixa(-2.0, -p["torso"] - 3.0, 3.0, -p["torso"] + 2.0), pal["pele"], 1.5, tag="pescoco"),
        Peca("cabeca", elipse(0.5, -p["cabeca"] * 0.4, p["cabeca"] * 1.1, p["cabeca"] * 0.9),
             pal["pele"], 2.0, tag="cabeca"),
        Peca("ombro_f", membro(p["braco"], p["esp_braco"]), c, 3.0),
        Peca("cotovelo_f", membro(p["antebraco"], p["esp_braco"] * 0.85), pal["pele"], 3.0),
    ]
    return juntas, pes


# ── alado ────────────────────────────────────────────────────────────────

ALADO = {
    "voo": 34.0, "corpo_c": 34.0, "corpo_a": 17.0,
    "pescoco": 15.0, "cabeca": 8.0,
    "asa1": 24.0, "asa2": 22.0, "asa_esp": 15.0,
    "cauda": 18.0, "perna": 15.0,
}


def alado(par: dict, pal: dict) -> tuple[Juntas, list[Peca]]:
    p = dict(ALADO)
    p.update(par)
    juntas: Juntas = {
        "raiz": (None, (CENTRO_X, CHAO_Y - p["voo"])),
        "corpo": ("raiz", (0.0, 0.0)),
        "pescoco": ("corpo", (p["corpo_c"] * 0.4, -p["corpo_a"] * 0.35)),
        "cabeca": ("pescoco", (0.0, -p["pescoco"])),
        "asa_t1": ("corpo", (-3.0, -p["corpo_a"] * 0.5)),
        "asa_t2": ("asa_t1", (-p["asa1"], 0.0)),
        "asa_f1": ("corpo", (2.0, -p["corpo_a"] * 0.4)),
        "asa_f2": ("asa_f1", (-p["asa1"], 0.0)),
        "cauda1": ("corpo", (-p["corpo_c"] * 0.45, -2.0)),
        "cauda2": ("cauda1", (-p["cauda"], 0.0)),
        "perna_t": ("corpo", (-2.0, p["corpo_a"] * 0.3)),
        "perna_f": ("corpo", (6.0, p["corpo_a"] * 0.3)),
    }

    c, c2 = pal["corpo"], pal["corpo2"]
    asa = pal.get("asa", c2)
    pes: list[Peca] = [
        # asa de tras
        Peca("asa_t1", _asa(p["asa1"], p["asa_esp"]), _atras(asa), -3.0),
        Peca("asa_t2", _asa(p["asa2"], p["asa_esp"] * 0.8), _atras(asa), -3.0),
        Peca("perna_t", membro(p["perna"], 7.0), _atras(c2), -2.0),
        Peca("cauda1", trapezio(0.0, 11.0, 0.0, 11.0), c2, -1.0),
        Peca("cauda1", [(0.0, -5.5), (-p["cauda"], -3.5), (-p["cauda"], 3.5), (0.0, 5.5)], c2, -1.0),
        Peca("cauda2", [(0.0, -3.5), (-p["cauda"] * 0.9, -1.0),
                        (-p["cauda"] * 0.9, 1.0), (0.0, 3.5)], escurecer(c2, 0.15), -1.0),
        Peca("corpo", elipse(0.0, 0.0, p["corpo_c"] * 0.5, p["corpo_a"] * 0.5), c, 0.0, tag="corpo"),
        Peca("pescoco", trapezio(0.0, 11.0, -p["pescoco"], 8.0), c, 0.5, tag="pescoco"),
        Peca("cabeca", elipse(2.0, 0.0, p["cabeca"] * 1.25, p["cabeca"] * 0.72), c, 1.0, tag="cabeca"),
        Peca("cabeca", [(p["cabeca"] * 1.1, -2.0), (p["cabeca"] * 2.0, 1.0),
                        (p["cabeca"] * 1.0, 3.5)], c2, 1.1),
        Peca("perna_f", membro(p["perna"], 7.5), c2, 2.0),
        # asa da frente
        Peca("asa_f1", _asa(p["asa1"], p["asa_esp"]), asa, 3.0),
        Peca("asa_f2", _asa(p["asa2"], p["asa_esp"] * 0.8), asa, 3.0),
    ]
    return juntas, pes


def _asa(comp: float, esp: float) -> list[tuple[float, float]]:
    """Membrana entre dois dedos: cresce para -x (para tras do bicho)."""
    return [(2.0, -esp * 0.35), (-comp, -esp), (-comp * 0.92, esp * 0.55),
            (-comp * 0.5, esp * 0.2), (2.0, esp * 0.3)]


# ── ave (corvideo colossal: o Guardiao dos Ceus) ─────────────────

## Usa os MESMOS nomes de junta do plano `alado`, de proposito: assim
## reaproveita o gait dele (as asas batem sempre, a cauda arrasta, o
## pescoco recolhe antes do golpe) sem duplicar animacao. O que muda e' o
## DESENHO -- um corvideo nao tem asa de membrana nem pescoco de dragao:
## tem penas sobrepostas, cauda em leque, bico curvo e garras.
## Contrato visual: docs/art_direction/regions/region_02/
## GUARDIAO_DOS_CEUS_VISUAL_CONTRACT.md

## Angulo a que a asa LEVANTA. Usado em dois sitios que tem de concordar:
## a rotacao do desenho e a posicao da junta da 2.a metade da asa. Quando
## so' o desenho rodava, a ponta da asa descolava do ombro e ficava um
## naco de penas a flutuar ao lado do bicho.
ARCO_ASA = -48.0

AVE = {
    "voo": 52.0, "corpo_c": 30.0, "corpo_a": 34.0,
    "pescoco": 10.0, "cabeca": 9.5,
    "asa1": 40.0, "asa2": 36.0, "asa_esp": 18.0,
    "cauda": 22.0, "perna": 16.0,
    "penas": 5,
}


def ave(par: dict, pal: dict) -> tuple[Juntas, list[Peca]]:
    """Corvideo colossal em TRES QUARTOS -- nao de perfil.

    A prancha aprovada desenha o Guardiao de frente/tres quartos, com as
    DUAS asas abertas (`IDLE (ASA ABERTA)`, `ANDAR / AJUSTE`). De perfil
    estrito, com as duas asas varridas para tras, a silhueta lia-se como
    um galinaceo deitado -- tentou-se e nao passava. Em tres quartos o
    corpo fica de pe', a asa de tras abre para -x, a da frente para +x, e
    a cabeca fica de perfil com o bico para o lado que o chefe encara --
    por isso o `scale.x = +-1` do jogo continua a servir.

    Juntas com os mesmos nomes do plano `alado`, para reusar o gait dele.
    """
    p = dict(AVE)
    p.update(par)
    juntas: Juntas = {
        "raiz": (None, (CENTRO_X, CHAO_Y - p["voo"])),
        "corpo": ("raiz", (0.0, 0.0)),
        "pescoco": ("corpo", (p["corpo_c"] * 0.3, -p["corpo_a"] * 0.44)),
        "cabeca": ("pescoco", (p["pescoco"] * 0.42, -p["pescoco"] * 0.9)),
        # asa de TRAS: ombro de la', abre para -x
        "asa_t1": ("corpo", (-p["corpo_c"] * 0.3, -p["corpo_a"] * 0.34)),
        "asa_t2": ("asa_t1", _ponta_asa(p["asa1"] * 0.86, False)),
        # asa da FRENTE: ombro de ca', abre para +x (espelhada)
        "asa_f1": ("corpo", (p["corpo_c"] * 0.26, -p["corpo_a"] * 0.28)),
        "asa_f2": ("asa_f1", _ponta_asa(p["asa1"] * 0.86, True)),
        "cauda1": ("corpo", (-p["corpo_c"] * 0.2, p["corpo_a"] * 0.42)),
        "cauda2": ("cauda1", (-p["cauda"] * 0.72, p["cauda"] * 0.2)),
        "perna_t": ("corpo", (-p["corpo_c"] * 0.24, p["corpo_a"] * 0.38)),
        "perna_f": ("corpo", (p["corpo_c"] * 0.2, p["corpo_a"] * 0.4)),
    }

    c, c2 = pal["corpo"], pal["corpo2"]
    asa = pal.get("asa", c2)
    ponta = pal.get("ponta", pal["detalhe"])
    ouro = pal.get("ouro", pal["metal"])
    n = int(p["penas"])

    pes: list[Peca] = []

    # asa de tras (mais escura; fica atras do corpo)
    _asa_de_penas(pes, "asa_t1", p["asa1"], p["asa_esp"], n,
                  _atras(asa), _atras(ponta), -3.2)
    _asa_de_penas(pes, "asa_t2", p["asa2"], p["asa_esp"] * 0.88, n,
                  _atras(asa), _atras(ponta), -3.0, remiges=True)

    # cauda, curta e em baixo
    _leque(pes, "cauda1", p["cauda"], n - 1, escurecer(c2, 0.2), ponta, -2.4)

    # perna de tras
    pes.append(Peca("perna_t", membro(p["perna"], 7.0), _atras(c2), -1.2,
                    tag="perna_t"))
    _garra(pes, "perna_t", p["perna"], _atras(ouro), -1.0)

    # corpo: de pe', peito largo em baixo
    pes.append(Peca("corpo", elipse(0.0, 0.0, p["corpo_c"] * 0.5,
                                    p["corpo_a"] * 0.5), c, 0.0, tag="corpo"))
    pes.append(Peca("corpo", elipse(0.0, p["corpo_a"] * 0.18,
                                    p["corpo_c"] * 0.38, p["corpo_a"] * 0.3),
                    clarear(c, 0.1), 0.08))
    # colar escuro em V, como o dos corvideos
    pes.append(Peca("corpo", [
        (-p["corpo_c"] * 0.36, -p["corpo_a"] * 0.34),
        (p["corpo_c"] * 0.36, -p["corpo_a"] * 0.34),
        (0.0, p["corpo_a"] * 0.06),
    ], escurecer(c, 0.24), 0.12))
    pes.append(Peca("pescoco", trapezio(0.0, 16.0, -p["pescoco"], 12.0), c,
                    0.5, tag="pescoco"))

    # cabeca de perfil + bico curvo
    pes.append(Peca("cabeca", elipse(0.6, 0.0, p["cabeca"] * 1.12,
                                     p["cabeca"] * 0.95), c, 1.0, tag="cabeca"))
    pes.append(Peca("cabeca", elipse(p["cabeca"] * 0.34, -p["cabeca"] * 0.18,
                                     p["cabeca"] * 0.7, p["cabeca"] * 0.6),
                    escurecer(c, 0.3), 1.02))
    _bico(pes, "cabeca", p["cabeca"], ouro, 1.2)

    # perna da frente
    pes.append(Peca("perna_f", membro(p["perna"], 7.5), c2, 2.0, tag="perna_f"))
    _garra(pes, "perna_f", p["perna"], ouro, 2.2)

    # asa da frente, ESPELHADA (abre para +x)
    _asa_de_penas(pes, "asa_f1", p["asa1"], p["asa_esp"], n, asa, ponta, 3.0,
                  espelhada=True)
    _asa_de_penas(pes, "asa_f2", p["asa2"], p["asa_esp"] * 0.88, n, asa,
                  ponta, 3.2, remiges=True, espelhada=True)
    return juntas, pes


def _asa_de_penas(pes: list[Peca], junta: str, comp: float, esp: float,
                  n: int, c: Cor, c_ponta: Cor, z: float,
                  remiges: bool = False, arco: float = ARCO_ASA,
                  espelhada: bool = False) -> None:
    """Uma asa, nao um leque.

    A primeira versao punha N penas a irradiar da MESMA junta e lia-se
    como a cauda de um peru. Uma asa le'-se por uma massa varrida (as
    coberturas) com as penas de voo a abrir SO' na ponta -- e e' a ponta
    que leva o carmesim, porque na prancha o vermelho e' acento nas
    remiges, nunca cor de corpo. `espelhada` da' a asa da FRENTE, que em
    tres quartos abre para o lado oposto.
    """
    def _a(pts):
        pts = rodar(pts, arco)
        return espelhar_x(pts) if espelhada else pts

    pes.append(Peca(junta, _a([
        (3.0, -esp * 0.34), (-comp * 0.42, -esp * 0.86),
        (-comp * 0.88, -esp * 0.74), (-comp, -esp * 0.18),
        (-comp * 0.8, esp * 0.36), (-comp * 0.3, esp * 0.5),
        (3.0, esp * 0.3),
    ]), c, z))
    pes.append(Peca(junta, _a([
        (1.0, -esp * 0.2), (-comp * 0.22, -esp * 0.5),
        (-comp * 0.36, -esp * 0.3), (-comp * 0.16, -esp * 0.04),
        (0.0, esp * 0.0),
    ]), clarear(c, 0.05), z + 0.01))
    if not remiges:
        return
    for k in range(max(2, n)):
        t = k / float(max(1, n - 1))
        ang = -22.0 + 52.0 * t
        comp_p = comp * (0.62 + 0.3 * (1.0 - abs(t - 0.35)))
        desl = (-comp * 0.78, -esp * 0.34 + esp * 0.5 * t)
        pes.append(Peca(junta,
                        _a(mover(rodar(_remige(comp_p, esp * 0.42), ang), *desl)),
                        escurecer(c, 0.06 * k), z + 0.02 + k * 0.01))
        if k >= n - 2:
            pes.append(Peca(junta,
                            _a(mover(rodar(_ponta_remige(comp_p, esp * 0.42),
                                           ang), *desl)),
                            c_ponta, z + 0.03 + k * 0.01))


def _ponta_asa(comp: float, espelhada: bool) -> tuple[float, float]:
    """Onde acaba a 1.a metade da asa, JA' com o `ARCO_ASA` aplicado."""
    a = math.radians(ARCO_ASA)
    x, y = -comp * math.cos(a), -comp * math.sin(a)
    return (-x, y) if espelhada else (x, y)


def _remige(comp: float, esp: float) -> list[tuple[float, float]]:
    """Pena de voo inteira: base larga na asa, ponta fina para -x."""
    return [
        (1.0, -esp * 0.5), (-comp * 0.6, -esp * 0.42),
        (-comp, -esp * 0.08), (-comp * 0.94, esp * 0.12),
        (-comp * 0.5, esp * 0.42), (1.0, esp * 0.5),
    ]


def _ponta_remige(comp: float, esp: float) -> list[tuple[float, float]]:
    """So' o terco da ponta -- o acento carmesim da prancha."""
    return [
        (-comp * 0.66, -esp * 0.4), (-comp, -esp * 0.08),
        (-comp * 0.94, esp * 0.12), (-comp * 0.56, esp * 0.4),
    ]


def _leque(pes: list[Peca], junta: str, comp: float, n: int, c: Cor,
           c_ponta: Cor, z: float) -> None:
    """Cauda: leque ESTREITO e baixo, para nao competir com a asa."""
    n = max(2, n)
    for k in range(n):
        t = k / float(n - 1)
        ang = -12.0 + 34.0 * t
        pena = rodar(_remige(comp * (0.84 + 0.16 * (1.0 - abs(t - 0.5) * 2.0)),
                             6.5), ang)
        pes.append(Peca(junta, pena, escurecer(c, 0.05 * k), z + k * 0.02))
        if k >= n - 2:
            comp_p = comp * (0.84 + 0.16 * (1.0 - abs(t - 0.5) * 2.0))
            pes.append(Peca(junta, rodar(_ponta_remige(comp_p, 6.5), ang),
                            c_ponta, z + 0.01 + k * 0.02))


def _bico(pes: list[Peca], junta: str, cab: float, ouro: Cor,
          z: float) -> None:
    """Bico de RAPINA: curto, fundo na base, com gancho a descer.

    A primeira versao saiu um pau horizontal claro -- lia-se como uma
    tabua espetada na cara. O que da' a leitura e' o GANCHO e a base
    funda, nao o comprimento.
    """
    pes.append(Peca(junta, [
        (cab * 0.5, -cab * 0.6), (cab * 1.62, -cab * 0.4),
        (cab * 2.02, cab * 0.1), (cab * 1.66, cab * 0.82),
        (cab * 1.36, cab * 0.2), (cab * 0.56, cab * 0.28),
    ], ouro, z))
    # narina + sombra da mandibula de baixo
    pes.append(Peca(junta, [
        (cab * 0.58, cab * 0.16), (cab * 1.44, cab * 0.18),
        (cab * 1.26, cab * 0.54), (cab * 0.62, cab * 0.48),
    ], escurecer(ouro, 0.38), z + 0.05))
    pes.append(Peca(junta, elipse(cab * 0.86, -cab * 0.22, 1.2, 1.0),
                    escurecer(ouro, 0.5), z + 0.06))


def _garra(pes: list[Peca], junta: str, perna: float, ouro: Cor,
           z: float) -> None:
    """Tres dedos curvos, dourados, na ponta da perna."""
    for k, ang in enumerate((-34.0, -4.0, 24.0)):
        dedo = mover(rodar(membro(8.5, 3.2, 1.0), ang - 90.0), 0.0, perna)
        pes.append(Peca(junta, dedo, ouro if k == 1 else escurecer(ouro, 0.18),
                        z + k * 0.01))
    # esporao virado para tras
    pes.append(Peca(junta, mover(rodar(membro(5.5, 2.6, 1.0), -118.0),
                                 0.0, perna), escurecer(ouro, 0.28), z - 0.01))


# ── quadrupede ───────────────────────────────────────────────────────────

QUADRUPEDE = {
    "alt": 30.0, "corpo_c": 42.0, "corpo_a": 16.0,
    "pescoco": 14.0, "cabeca": 7.0,
    "seg1": 15.0, "seg2": 15.0, "esp_pata": 6.0,
    "tronco": 20.0, "braco": 12.0, "cab_c": 6.5,
}


def quadrupede(par: dict, pal: dict) -> tuple[Juntas, list[Peca]]:
    p = dict(QUADRUPEDE)
    p.update(par)
    juntas: Juntas = {
        "raiz": (None, (CENTRO_X, CHAO_Y - p["alt"] - p["corpo_a"] * 0.5)),
        "corpo": ("raiz", (0.0, 0.0)),
        "pescoco": ("corpo", (p["corpo_c"] * 0.42, -p["corpo_a"] * 0.3)),
        "cabeca": ("pescoco", (0.0, -p["pescoco"])),
        "cavaleiro": ("corpo", (-4.0, -p["corpo_a"] * 0.5)),
        "cab_cav": ("cavaleiro", (1.0, -p["tronco"] - 3.0)),
        "braco_c": ("cavaleiro", (2.0, -p["tronco"] + 5.0)),
    }
    for nome, x in (("pat_dt", p["corpo_c"] * 0.3), ("pat_df", p["corpo_c"] * 0.34),
                    ("pat_tt", -p["corpo_c"] * 0.32), ("pat_tf", -p["corpo_c"] * 0.28)):
        juntas[nome] = ("corpo", (x, p["corpo_a"] * 0.35))
        juntas[nome + "j"] = (nome, (0.0, p["seg1"]))

    c, c2 = pal["corpo"], pal["corpo2"]
    cav = pal.get("cavaleiro", pal["metal"])
    pes: list[Peca] = []
    for nome in ("pat_dt", "pat_tt"):
        pes.append(Peca(nome, membro(p["seg1"], p["esp_pata"]), _atras(c), -3.0))
        pes.append(Peca(nome + "j", membro(p["seg2"], p["esp_pata"] * 0.75), _atras(c), -3.0))
    pes += [
        Peca("corpo", elipse(0.0, 0.0, p["corpo_c"] * 0.5, p["corpo_a"] * 0.5), c, 0.0, tag="corpo"),
        Peca("pescoco", trapezio(0.0, 12.0, -p["pescoco"], 8.0), c, 0.4, tag="pescoco"),
        Peca("cabeca", elipse(3.0, 0.0, p["cabeca"] * 1.5, p["cabeca"] * 0.7), c, 0.5, tag="cabeca"),
    ]
    for nome in ("pat_df", "pat_tf"):
        pes.append(Peca(nome, membro(p["seg1"], p["esp_pata"]), c2, 1.0))
        pes.append(Peca(nome + "j", membro(p["seg2"], p["esp_pata"] * 0.75), c2, 1.0))
    pes += [
        Peca("cavaleiro", trapezio(-p["tronco"], 17.0, 0.0, 12.0), cav, 2.0, tag="tronco_cav"),
        Peca("cab_cav", elipse(0.0, -p["cab_c"] * 0.5, p["cab_c"], p["cab_c"] * 1.05),
             pal["pele"], 2.2, tag="cabeca_cav"),
        Peca("braco_c", membro(p["braco"], 6.0), cav, 2.5),
    ]
    return juntas, pes


# ── objeto vivo ──────────────────────────────────────────────────────────

OBJETO = {
    "alt": 22.0, "sino_a": 34.0, "sino_l": 34.0, "boca": 8.0,
    "braco": 11.0, "esp_braco": 5.0, "cabeca": 6.0,
}


def objeto(par: dict, pal: dict) -> tuple[Juntas, list[Peca]]:
    p = dict(OBJETO)
    p.update(par)
    juntas: Juntas = {
        "raiz": (None, (CENTRO_X, CHAO_Y - p["alt"] - p["sino_a"])),
        "corpo": ("raiz", (0.0, 0.0)),
        "badalo": ("corpo", (0.0, p["sino_a"] * 0.45)),
        "cabeca": ("corpo", (2.0, p["sino_a"] * 0.72)),
        "ombro_t": ("corpo", (-p["sino_l"] * 0.42, p["sino_a"] * 0.52)),
        "ombro_f": ("corpo", (p["sino_l"] * 0.38, p["sino_a"] * 0.52)),
        "cotovelo_t": ("ombro_t", (0.0, p["braco"])),
        "cotovelo_f": ("ombro_f", (0.0, p["braco"])),
    }

    c, c2 = pal["corpo"], pal["corpo2"]
    pes: list[Peca] = [
        Peca("ombro_t", membro(p["braco"], p["esp_braco"]), _atras(pal["pele"]), -1.5),
        Peca("cotovelo_t", membro(p["braco"] * 0.9, p["esp_braco"] * 0.85),
             _atras(pal["pele"]), -1.5),
        # a boca do sino e' um vao escuro: e' de la' que a criatura espreita
        Peca("corpo", trapezio(p["sino_a"] * 0.55, p["sino_l"] * 0.62,
                               p["sino_a"], p["sino_l"] * 0.86), pal["detalhe"], -0.5),
        Peca("cabeca", elipse(0.0, 0.0, p["cabeca"], p["cabeca"] * 0.9), pal["pele"], -0.4, tag="cabeca"),
        # o corpo do sino, com o rebordo mais claro
        Peca("corpo", [(-p["sino_l"] * 0.16, 0.0), (p["sino_l"] * 0.16, 0.0),
                       (p["sino_l"] * 0.34, p["sino_a"] * 0.42),
                       (p["sino_l"] * 0.5, p["sino_a"] * 0.86),
                       (-p["sino_l"] * 0.5, p["sino_a"] * 0.86),
                       (-p["sino_l"] * 0.34, p["sino_a"] * 0.42)], c, 0.0),
        Peca("corpo", caixa(-p["sino_l"] * 0.53, p["sino_a"] * 0.84,
                            p["sino_l"] * 0.53, p["sino_a"] * 0.96), c2, 0.6),
        Peca("badalo", membro(p["sino_a"] * 0.42, 4.0, 3.0), pal["metal"], -0.45),
        Peca("badalo", elipse(0.0, p["sino_a"] * 0.44, 5.0, 5.0), pal["metal"], -0.45),
        Peca("ombro_f", membro(p["braco"], p["esp_braco"]), pal["pele"], 3.0),
        Peca("cotovelo_f", membro(p["braco"] * 0.9, p["esp_braco"] * 0.85), pal["pele"], 3.0),
    ]
    return juntas, pes


CORPOS = {
    "humanoide": humanoide,
    "flutuante": flutuante,
    "aracnideo": aracnideo,
    "serpente": serpente,
    "alado": alado,
    "ave": ave,
    "quadrupede": quadrupede,
    "objeto": objeto,
}
