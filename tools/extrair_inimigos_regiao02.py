#!/usr/bin/env python3
"""Recorta o bestiario canonico da Regiao II DA PRANCHA APROVADA.

    python3 tools/extrair_inimigos_regiao02.py [--preview]

Porque isto existe
------------------
O audit mediu **0 dos 10 inimigos canonicos** em N06-N10: a Regiao II usava
o pool da antiga Prisao (`esqueleto, chort, orc, imp, mastim`), bichos
terrestres de masmorra, num sitio cuja identidade e' o AR.

A regra do processo e' nao recriar por script o que ja' existe desenhado na
referencia aprovada. E existe: `enemy_gameplay_pack.png` traz cada criatura
com poses a ~50-125 px de altura -- praticamente a' escala de jogo
(`DemonioBase.ALTURA_ALVO_INIMIGO` = 48). Nao ha' nada a inventar: chega
recortar, tirar o fundo e montar as tiras.

O que a prancha NAO da' (e porque so' saem 5 das 10)
---------------------------------------------------
O plano de cada painel nao e' o mesmo, e isso descobriu-se a olhar:

* MORCEGO, GAIVOTA e GOLEM tem a CRIATURA na linha de estados, com os cinco
  estados nomeados. Sao os tres casos limpos.
* A SENTINELA FLUTUANTE tem na linha de estados o **projectil** dela (orbes
  violeta), nao a criatura -- a sentinela so' existe na linha de conceito,
  em tres poses.
* O ELEMENTAL DO VENTO tem tres espirais na linha de estados para quatro
  legendas (sao largas e sobrepoem-se). Tres chegam: e' uma forma eterea.
* O MAGO DO VENTO tem a linha de estados quase toda em glifos de magia, e na
  linha de conceito as quatro figuras estao coladas umas as outras -- nao ha'
  corte honesto. Fica de fora **como inimigo comum**, e nao faz falta: a
  Feiticeira dos Ventos (guardia do N08) ja' e' o arquetipo `MAGO DO VENTO`.
* SERPENTE EOLICA, ESPECTRO DAS RUINAS, ARQUEIRO EOLICO e TORRE VIGIA ficam
  para depois; o Espectro e a Torre Vigia ja' existem como guardioes
  (Espectros Gemeos no N09, Vigia do Desfiladeiro no N07).

Como corta (medido, com auto-verificacao)
-----------------------------------------
1. Por painel, projecta as colunas com pixeis e parte nas colunas vazias.
2. Se sair mais corridas do que estados, junta as de menor intervalo ate'
   bater certo -- e' o GOLEM AEREO, cujo corpo sao pedras soltas com ar no
   meio.
3. Onde ha' legendas, confirma que o centro de cada corrida cai a menos de
   `DESVIO_MAX` px do centro da legenda. Se a prancha mudar, o script pa'ra
   em vez de recortar lixo.
4. O alfa vem da distancia a' cor do fundo, com rampa: binario deixava as
   bordas pintadas aos degraus. O limiar do CORTE e' mais apertado do que o
   do alfa -- os halos colam sprites vizinhos, e cortar pelo corpo e pintar
   pela borda sao duas perguntas diferentes.

Escreve `assets/sprites/pixel/enemies/<especie>/{idle,run,attack,hit,dead}.png`.
O `attack.png` e' novo: o `demonio_base.gd` ja' sabia tocar "attack" no
telegrafo (`_tem_anim("attack")`) mas o carregador nunca o montava.
"""
import os
import sys

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRANCHA = os.path.join(RAIZ, "docs/art_direction/regions/region_02",
                       "enemy_gameplay_pack.png")
DESTINO = os.path.join(RAIZ, "assets/sprites/pixel/enemies")

FUNDO = (1, 12, 22)          # amostrado no painel, longe de qualquer sprite
ALFA_ZERO = 11               # abaixo disto e' fundo (so' manda no alfa)
ALFA_CHEIO = 35              # a partir daqui o pixel e' opaco
LIMIAR_CORTE = 26            # limiar do corte -- ver ponto 4 do cabecalho
LARGURA_MIN = 12             # corridas mais estreitas sao respingos de FX
DESVIO_MAX = 25              # tolerancia entre centro do sprite e da legenda
ALTURA_ALVO = 56             # px; o jogo poe os inimigos a 48 (`_altura_alvo`)
# Manchas soltas mais pequenas do que isto sao respingos de FX e cacos das
# legendas apanhados pela banda -- nao sao a criatura.
AREA_MIN = 22

# Onde vive cada criatura na prancha. `legendas` = banda das etiquetas, ou
# None quando o corte nao tem etiquetas por baixo (linha de conceito).
CRIATURAS = [
    {"especie": "morcego_dos_ventos", "x": (258, 505), "y": (140, 197),
     "legendas": (205, 215),
     "estados": ["IDLE", "VOO", "INVESTIDA", "DANO", "MORTE"]},
    {"especie": "gaivota_sombria", "x": (730, 980), "y": (140, 197),
     "legendas": (205, 215),
     "estados": ["IDLE", "VOO", "MERGULHO", "ATAQUE", "MORTE"]},
    {"especie": "golem_aereo", "x": (980, 1255), "y": (140, 197),
     "legendas": (205, 215),
     "estados": ["IDLE", "LEVITA", "ATAQUE", "DANO", "MORTE"]},
    # linha de CONCEITO: a linha de estados deste painel e' o projectil
    {"especie": "sentinela_flutuante", "x": (505, 730), "y": (44, 138),
     "legendas": None, "estados": ["A", "B", "C"]},
    {"especie": "elemental_do_vento", "x": (1255, 1530), "y": (358, 422),
     "legendas": None, "estados": ["A", "B", "C"]},
]

# Que estados da prancha entram em cada animacao do jogo. Onde a prancha nao
# desenha DANO (gaivota) usa-se o IDLE: o pisca do dano e' do shader, como ja'
# acontecia nas especies do pack 0x72.
TIRAS = {
    "morcego_dos_ventos": {
        "idle": ["IDLE", "VOO"], "run": ["VOO", "INVESTIDA"],
        "attack": ["INVESTIDA"], "hit": ["DANO"], "dead": ["MORTE"]},
    "gaivota_sombria": {
        "idle": ["IDLE", "VOO"], "run": ["VOO", "MERGULHO"],
        "attack": ["MERGULHO", "ATAQUE"], "hit": ["IDLE"], "dead": ["MORTE"]},
    "golem_aereo": {
        "idle": ["IDLE", "LEVITA"], "run": ["LEVITA", "IDLE"],
        "attack": ["ATAQUE"], "hit": ["DANO"], "dead": ["MORTE"]},
    "sentinela_flutuante": {
        "idle": ["A", "B"], "run": ["B", "C"], "attack": ["C"],
        "hit": ["A"], "dead": ["C"]},
    "elemental_do_vento": {
        "idle": ["A", "B"], "run": ["B", "C"], "attack": ["C"],
        "hit": ["A"], "dead": ["C"]},
}


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
            if vazio > 9:
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


def main():
    im = Image.open(PRANCHA).convert("RGB")
    px = im.load()
    poses, erros = {}, []

    for c in CRIATURAS:
        x0, x1 = c["x"]
        y0, y1 = c["y"]
        cs = corridas(px, x0, x1, y0, y1)
        if len(cs) < len(c["estados"]):
            erros.append("%s: %d corridas para %d estados -- a prancha mudou?"
                         % (c["especie"], len(cs), len(c["estados"])))
            continue
        cs = juntar_ate(cs, len(c["estados"]))
        if c["legendas"]:
            legs = centros_das_legendas(px, x0, x1, *c["legendas"])
            if len(legs) == len(cs):
                for (a, b), lc in zip(cs, legs):
                    if abs((a + b) // 2 - lc) > DESVIO_MAX:
                        erros.append(
                            "%s: sprite em x=%d-%d longe da legenda em x=%d"
                            % (c["especie"], a, b, lc))
        poses[c["especie"]] = {}
        for (a, b), estado in zip(cs, c["estados"]):
            q = recortar(px, a, b, y0, y1)
            if q is None:
                erros.append("%s/%s sem pixeis" % (c["especie"], estado))
                continue
            q = limpar_manchas(q)
            if q.height > ALTURA_ALVO:       # linha de conceito: densidade
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
        for anim, estados in TIRAS[especie].items():
            tira = Image.new("RGBA", (larg * len(estados), alt), (0, 0, 0, 0))
            for i, e in enumerate(estados):
                q = poses[especie][e]
                tira.paste(q, (i * larg + (larg - q.width) // 2,
                               alt - q.height), q)
            tira.save(os.path.join(pasta, "%s.png" % anim))
        print("  %-22s quadro %dx%d  (%s)"
              % (especie, larg, alt, ", ".join(c["estados"])))

    if "--preview" in sys.argv:
        alt = max(q.height for e in poses.values() for q in e.values())
        larg = max(q.width for e in poses.values() for q in e.values())
        folha = Image.new("RGBA", (larg * 5, alt * len(CRIATURAS)),
                          (16, 16, 26, 255))
        for li, c in enumerate(CRIATURAS):
            for ci, e in enumerate(c["estados"]):
                q = poses[c["especie"]][e]
                folha.paste(q, (ci * larg + (larg - q.width) // 2,
                                li * alt + (alt - q.height)), q)
        folha = folha.resize((folha.width * 3, folha.height * 3), Image.NEAREST)
        cam = os.path.join(RAIZ, "work/preview_inimigos_r2.png")
        os.makedirs(os.path.dirname(cam), exist_ok=True)
        folha.save(cam)
        print("preview ->", cam)
    return 0


if __name__ == "__main__":
    sys.exit(main())
