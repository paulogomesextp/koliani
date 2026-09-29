#!/usr/bin/env python3
"""Recorta o bestiario canonico da Regiao III DA PRANCHA APROVADA.

    python3 tools/extrair_inimigos_regiao03.py [--preview]

Porque isto existe
------------------
A auditoria mediu **0 dos 10 inimigos canonicos** em N11-N15: a Torre dos
Ecos usava `xamane, wogol, olho, abutre, imp` -- demonios genericos
herdados das regioes anteriores, que e' exatamente o que o briefing
proibe ("inimigos herdados de biomas anteriores sem razao", "nada de
recolor de demonios de prisao").

A regra do processo e' nao recriar por script o que ja' existe desenhado
na referencia aprovada. E existe: o `enemy_gameplay_pack.png` da Regiao
III traz os DEZ inimigos, cada um com a sua linha de cinco estados
(IDLE/ANDA/ATAQUE/DANO/MORTE) a ~45-55 px de altura -- praticamente a'
escala de jogo (`DemonioBase.ALTURA_ALVO_INIMIGO` = 48). Nao ha' nada a
inventar: chega recortar, tirar o fundo e montar as tiras.

Este e' o mesmo metodo do `extrair_inimigos_regiao02.py`, e o algoritmo
(corridas -> legendas -> recorte por distancia ao fundo -> limpar
manchas) e' o mesmo, testado nessa regiao.

O que esta prancha tem de melhor do que a da Regiao II
------------------------------------------------------
Na II so' sairam 5 dos 10 porque metade dos paineis tinha na linha de
estados o PROJECTIL em vez da criatura, ou glifos de magia. Aqui os dez
paineis tem todos a criatura com os cinco estados nomeados e em caixas
alinhadas -- por isso saem os dez.

Armadilha: as duas linhas de paineis NAO estao a' mesma altura. A linha
de cima tem as legendas em y=221-228 e a de baixo em y=538-548. Medir uma
e assumir a outra da' recortes vazios.
"""

from __future__ import annotations

import os
import sys

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRANCHA = os.path.join(RAIZ, "docs/art_direction/regions/region_03",
                       "enemy_gameplay_pack.png")
DESTINO = os.path.join(RAIZ, "assets/sprites/pixel/enemies")

FUNDO = (2, 11, 20)          # amostrado dentro de uma caixa, longe do sprite
ALFA_ZERO = 12               # abaixo disto e' fundo (so' manda no alfa)
ALFA_CHEIO = 38              # a partir daqui o pixel e' opaco
LIMIAR_CORTE = 30            # limiar do corte em colunas
LARGURA_MIN = 10             # corridas mais estreitas sao respingos de FX
DESVIO_MAX = 26              # tolerancia entre centro do sprite e da legenda
ALTURA_ALVO = 56             # px; o jogo poe os inimigos a 48
AREA_MIN = 20                # manchas menores do que isto sao cacos

ESTADOS = ["IDLE", "ANDA", "ATAQUE", "DANO", "MORTE"]

# Onde vive a linha de estados de cada criatura. `y` e' a banda dos
# sprites, `legendas` a banda das etiquetas logo abaixo.
# `y` e' o INTERIOR da caixa, ja' sem a moldura: a borda de cima da linha
# 1 esta' em y=172-173 e a de baixo em y=215 (na linha 2, 485-486 e
# 531-532). Incluir essas linhas punha um risco da moldura em cima e em
# baixo de cada sprite.
L1_Y, L1_LEG = (175, 214), (221, 229)
L2_Y, L2_LEG = (488, 530), (538, 549)

# O centro de cada uma das cinco caixas, medido na prancha pelas LEGENDAS
# que ficam mesmo por baixo ("IDLE ANDA ATAQUE DANO MORTE"). As legendas
# sao o unico marcador fiavel: as caixas tocam-se e as molduras confundem
# qualquer deteccao por colunas vazias.
#
# Os centros do `acolito_do_eco` e do `automato_do_sino` comecam num valor
# EXTRAPOLADO (593 e 856): nesses dois paineis a legenda "IDLE" sai
# demasiado apagada para o detector a apanhar, e o passo das outras
# quatro da' a posicao que falta.
MEIA_CAIXA = 15          # px para cada lado do centro (passo medido ~33)

CRIATURAS = [
    # ---- linha de cima ----------------------------------------------
    {"especie": "sentinela_da_torre",
     "centros": [329, 360, 395, 431, 465], "y": L1_Y},
    {"especie": "acolito_do_eco",
     "centros": [593, 628, 664, 700, 732], "y": L1_Y},
    {"especie": "automato_do_sino",
     "centros": [856, 887, 917, 950, 980], "y": L1_Y},
    {"especie": "gargula_vitral",
     "centros": [1106, 1136, 1172, 1207, 1239], "y": L1_Y},
    {"especie": "sino_flutuante",
     "centros": [1363, 1395, 1430, 1466, 1499], "y": L1_Y},
    # ---- linha de baixo ---------------------------------------------
    {"especie": "arqueiro_das_sombras",
     "centros": [140, 173, 210, 250, 285], "y": L2_Y},
    {"especie": "monge_das_correntes",
     "centros": [454, 485, 521, 560, 596], "y": L2_Y},
    {"especie": "espirito_do_eco",
     "centros": [746, 780, 819, 859, 895], "y": L2_Y},
    {"especie": "construto_vitral",
     "centros": [1052, 1086, 1123, 1162, 1196], "y": L2_Y},
    {"especie": "corvo_do_sino",
     "centros": [1359, 1388, 1423, 1461, 1496], "y": L2_Y},
]

# Que estados da prancha entram em cada animacao do jogo. O `hit` usa o
# DANO da prancha; o pisca e' do shader, como nas outras especies.
TIRAS_PADRAO = {
    "idle": ["IDLE", "ANDA"], "run": ["ANDA", "ATAQUE"],
    "attack": ["ATAQUE"], "hit": ["DANO"], "dead": ["MORTE"],
}
# Os que voam nao "andam": o idle ja' e' movimento.
TIRAS_VOADOR = {
    "idle": ["IDLE", "ANDA"], "run": ["IDLE", "ANDA"],
    "attack": ["ATAQUE"], "hit": ["DANO"], "dead": ["MORTE"],
}
VOAM = {"gargula_vitral", "sino_flutuante", "corvo_do_sino", "espirito_do_eco"}


def dist_fundo(p):
    return abs(p[0] - FUNDO[0]) + abs(p[1] - FUNDO[1]) + abs(p[2] - FUNDO[2])


def corridas(px, x0, x1, y0, y1):
    """Corridas de colunas com pixeis, partidas nas colunas vazias."""
    saida, ini = [], None
    for x in range(x0, x1):
        cheia = any(dist_fundo(px[x, y]) > LIMIAR_CORTE for y in range(y0, y1))
        if cheia and ini is None:
            ini = x
        elif not cheia and ini is not None:
            if x - ini >= LARGURA_MIN:
                saida.append((ini, x - 1))
            ini = None
    if ini is not None and x1 - ini >= LARGURA_MIN:
        saida.append((ini, x1 - 1))
    return saida


def juntar_ate(cs, quantos):
    """Junta as corridas de menor intervalo ate' sobrarem `quantos`."""
    cs = list(cs)
    while len(cs) > quantos:
        k = min(range(1, len(cs)), key=lambda i: cs[i][0] - cs[i - 1][1])
        cs[k - 1] = (cs[k - 1][0], cs[k][1])
        del cs[k]
    return cs


def centros_das_legendas(px, x0, x1, y0, y1):
    claro, saida, ini, vazio = [], [], None, 0
    for x in range(x0, x1):
        claro.append(any(px[x, y][0] > 120 and px[x, y][1] > 120
                         and px[x, y][2] > 120 for y in range(y0, y1)))
    for i, v in enumerate(claro):
        if v:
            if ini is None:
                ini = i
            vazio = 0
        elif ini is not None:
            vazio += 1
            if vazio > 8:
                saida.append(x0 + (ini + i - vazio) // 2)
                ini, vazio = None, 0
    if ini is not None:
        saida.append(x0 + (ini + len(claro)) // 2)
    return saida


def recortar(px, ax, bx, y0, y1):
    """Aperta em y e recorta com alfa vindo da distancia ao fundo."""
    ay, by = None, None
    for y in range(y0, y1):
        if any(dist_fundo(px[x, y]) > LIMIAR_CORTE for x in range(ax, bx + 1)):
            ay = y if ay is None else ay
            by = y
    if ay is None:
        return None
    out = Image.new("RGBA", (bx - ax + 1, by - ay + 1), (0, 0, 0, 0))
    po = out.load()
    for j in range(out.height):
        for i in range(out.width):
            r, g, b = px[ax + i, ay + j]
            d = dist_fundo((r, g, b))
            if d <= ALFA_ZERO:
                continue
            a = 255 if d >= ALFA_CHEIO else int(
                255 * (d - ALFA_ZERO) / (ALFA_CHEIO - ALFA_ZERO))
            po[i, j] = (r, g, b, a)
    return out


def limpar_manchas(q):
    """Apaga componentes opacas minusculas (respingos de FX, cacos de texto)."""
    po = q.load()
    W, H = q.size
    visto = bytearray(W * H)
    for y0 in range(H):
        for x0 in range(W):
            if visto[y0 * W + x0] or po[x0, y0][3] == 0:
                continue
            pilha, celulas = [(x0, y0)], []
            visto[y0 * W + x0] = 1
            while pilha:
                cx, cy = pilha.pop()
                celulas.append((cx, cy))
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < W and 0 <= ny < H:
                            k = ny * W + nx
                            if not visto[k] and po[nx, ny][3] > 0:
                                visto[k] = 1
                                pilha.append((nx, ny))
            if len(celulas) < AREA_MIN:
                for cx, cy in celulas:
                    po[cx, cy] = (0, 0, 0, 0)
    return q.crop(q.getbbox() or (0, 0, W, H))


def main() -> int:
    im = Image.open(PRANCHA).convert("RGB")
    px = im.load()
    poses, erros = {}, []

    for c in CRIATURAS:
        y0, y1 = c["y"]
        # Uma caixa por centro. Nao se corta por colunas vazias (como na
        # Regiao II): aqui cada sprite vive dentro de uma CAIXA com borda
        # desenhada, as caixas tocam-se, e nao ha' uma unica coluna vazia
        # na tira toda -- o corte por corridas devolvia sempre "1 corrida
        # para 5 estados". E uma grelha de cinco partes iguais tambem nao
        # chega: o passo nao e' perfeitamente constante e o erro acumula,
        # a ponto de a quinta caixa apanhar metade do vizinho.
        cs = [(cx - MEIA_CAIXA, cx + MEIA_CAIXA) for cx in c["centros"]]
        poses[c["especie"]] = {}
        for (a, b), estado in zip(cs, ESTADOS):
            q = recortar(px, a, b, y0, y1)
            if q is None:
                erros.append("%s/%s sem pixeis" % (c["especie"], estado))
                continue
            q = limpar_manchas(q)
            if q.height > ALTURA_ALVO:
                e = ALTURA_ALVO / float(q.height)
                q = q.resize((max(1, round(q.width * e)), ALTURA_ALVO),
                             Image.LANCZOS)
            poses[c["especie"]][estado] = q

    if erros:
        for e in erros:
            print("ERRO:", e)
        return 1

    for c in CRIATURAS:
        especie = c["especie"]
        pasta = os.path.join(DESTINO, especie)
        os.makedirs(pasta, exist_ok=True)
        todos = list(poses[especie].values())
        larg = max(q.width for q in todos)
        alt = max(q.height for q in todos)
        tiras = TIRAS_VOADOR if especie in VOAM else TIRAS_PADRAO
        for anim, estados in tiras.items():
            tira = Image.new("RGBA", (larg * len(estados), alt), (0, 0, 0, 0))
            for i, e in enumerate(estados):
                q = poses[especie][e]
                tira.paste(q, (i * larg + (larg - q.width) // 2,
                               alt - q.height), q)
            tira.save(os.path.join(pasta, "%s.png" % anim))
        print("  %-22s quadro %dx%d" % (especie, larg, alt))

    if "--preview" in sys.argv:
        alt = max(q.height for e in poses.values() for q in e.values())
        larg = max(q.width for e in poses.values() for q in e.values())
        folha = Image.new("RGBA", (larg * 5, alt * len(CRIATURAS)),
                          (16, 16, 26, 255))
        for li, c in enumerate(CRIATURAS):
            for i, e in enumerate(ESTADOS):
                q = poses[c["especie"]].get(e)
                if q is None:
                    continue
                folha.paste(q, (i * larg + (larg - q.width) // 2,
                                li * alt + alt - q.height), q)
        cam = os.path.join(RAIZ, "work", "_preview_inimigos_r3.png")
        os.makedirs(os.path.dirname(cam), exist_ok=True)
        folha.save(cam)
        print("preview ->", cam)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
