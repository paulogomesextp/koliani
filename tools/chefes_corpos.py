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

from chefes_desenho import (CENTRO_X, CHAO_Y, Cor, Peca, caixa, elipse,
                            escurecer, membro, trapezio)

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
_PATAS_BASE = [
    ("pa1", -7.0, -58.0), ("pa2", -1.0, -30.0), ("pa3", 5.0, -8.0),
    ("pf1", -6.0, -50.0), ("pf2", 0.0, -22.0), ("pf3", 6.0, 2.0),
]


def aracnideo(par: dict, pal: dict) -> tuple[Juntas, list[Peca]]:
    p = dict(ARACNIDEO)
    p.update(par)
    juntas: Juntas = {
        "raiz": (None, (CENTRO_X, CHAO_Y - p["alt"])),
        "corpo": ("raiz", (0.0, 0.0)),
        "cabeca": ("corpo", (p["cefalo"] + 2.0, -p["cefalo"] * 0.5)),
    }
    for nome, x, _ang in _PATAS_BASE:
        juntas[nome] = ("corpo", (x, -2.0))
        juntas[nome + "j"] = (nome, (0.0, p["seg1"]))

    c, c2 = pal["corpo"], pal["corpo2"]
    pes: list[Peca] = []
    # as patas de tras primeiro (mais escuras e por baixo de tudo)
    for nome, _x, ang in _PATAS_BASE:
        atras = nome.startswith("pa")
        tom = _atras(c2) if atras else c2
        z = -3.0 if atras else 2.5
        # a pata sai da junta ja' aberta: e' o angulo de repouso, somado
        # depois pela pose
        pes.append(Peca(nome, _pata(p["seg1"], p["esp_pata"], ang), tom, z))
        pes.append(Peca(nome + "j", _pata(p["seg2"], p["esp_pata"] * 0.8, ang + 95.0),
                        tom, z))
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
    "quadrupede": quadrupede,
    "objeto": objeto,
}
