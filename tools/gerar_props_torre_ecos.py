#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Props canonicos da REGIAO III -- Torre dos Ecos.

PORQUE E' QUE ISTO EXISTE

O audit fechou a passagem anterior em PARTIAL com dois eixos em LOW:
"arquitetura do primeiro plano" e "props jogaveis". A causa esta' medida:
o bioma `torres` tinha DOZE props, e tres deles eram de cemiterio
(`cruz`, `lapide`), o que e' metade da razao de os cinco niveis lerem
como campa em vez de campanario. Nenhum era um SINO -- numa regiao cujo
elemento central sao sinos. A Regiao II (`desfiladeiro`), que ja' levou
o seu passe, tem vinte e cinco.

PORQUE E' QUE ISTO DESENHA EM VEZ DE RECORTAR

O `tools/gerar_deco.py` recorta os props das folhas dos packs CC0 em
`assets/sprites/incoming/`, que esta' `.gdignore`d e NAO vem no Git. Das
fontes que o bioma `torres` usa (`church`, `cemetery`, `town`), nenhuma
existe fora da maquina do Paulo -- por isso o `gerar_deco.py` nao
consegue sequer correr para esta regiao. O precedente para este caso ja'
esta' no repo: o fundo desta mesma regiao
(`tools/gerar_fundo_torre_ecos.py`) e' DESENHADO, nao recortado. Isto faz
o mesmo para os props, com a mesma paleta do contrato.

VOCABULARIO (contrato §5, "Props" e "Interativos"): sinos (pequeno /
medio / grande / partido), candelabro, braseiro, estatua angelica,
gargula, engrenagem, relogio antigo, memorial, urna, livros, arco,
coluna dupla, vitral, pedra de memoria, detritos.

  python3 tools/gerar_props_torre_ecos.py
  (depois: godot --headless --import)
"""
from __future__ import annotations

import json
import math
import pathlib
import random

from PIL import Image, ImageDraw

RAIZ = pathlib.Path(__file__).resolve().parent.parent
DEST = RAIZ / "assets/sprites/pixel/deco/torres"
MANIFESTO = RAIZ / "assets/sprites/pixel/deco/deco.json"

# --- paleta do contrato (§1), a MESMA do fundo desta regiao -------------
PEDRA_CLARA = (150, 158, 196)
PEDRA = (104, 112, 152)
PEDRA_ESCURA = (62, 68, 104)
PEDRA_SOMBRA = (38, 42, 70)
OURO = (214, 164, 84)
OURO_VIVO = (242, 202, 126)
OURO_ESCURO = (142, 104, 50)
BRONZE = (166, 126, 70)
BRONZE_ESCURO = (96, 70, 40)
VITRAL_AZUL = (96, 132, 214)
VITRAL_ROXO = (146, 104, 200)
VITRAL_OURO = (224, 186, 110)
CHAMA = (255, 214, 140)
CHAMA_NUCLEO = (255, 246, 214)
FERRO = (70, 76, 104)
FERRO_CLARO = (108, 116, 148)


def _nova(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def _sombrear(d: ImageDraw.ImageDraw, caixa, base, claro, escuro) -> None:
    """Volume barato mas legivel: luz em cima-esquerda, sombra em baixo-direita.
    E' a convencao do resto do jogo (o luar vem de cima), e sem ela um prop
    pixel-art le-se como mancha."""
    x0, y0, x1, y1 = caixa
    d.rectangle(caixa, fill=base)
    d.line([(x0, y0), (x1, y0)], fill=claro)
    d.line([(x0, y0), (x0, y1)], fill=claro)
    d.line([(x0, y1), (x1, y1)], fill=escuro)
    d.line([(x1, y0), (x1, y1)], fill=escuro)


def _perfil_sino(t: float) -> float:
    """Meia-largura do sino a` altura `t` (0 = ombro, 1 = boca), em fraccao da
    largura total. A primeira versao usava `t ** 2.2` e saia um CONE: sem
    ombro e sem aba, nao se lia como sino nenhum -- e o sino e' a assinatura
    da regiao inteira. Um sino a serio tem tres tempos: ombro quase a
    direito, cintura que abre devagar, e aba que abre de repente no fim."""
    return 0.22 + 0.18 * t + 0.60 * (t ** 4.0)


def _sino(larg: int, alt: int, cor=BRONZE, partido=False) -> Image.Image:
    """Um sino, desenhado pela SILHUETA. A coroa (a argola por onde pende)
    tem tela reservada em cima -- na primeira versao ficava em y negativo e
    era cortada, o que tirava metade da leitura."""
    im = _nova(larg, alt)
    d = ImageDraw.Draw(im)
    cx = (larg - 1) / 2.0
    coroa = max(4, alt // 8)          # tela reservada a` coroa
    aba = max(3, alt // 12)           # altura da aba
    corpo0 = coroa
    corpo1 = alt - aba - 1
    h = max(1, corpo1 - corpo0)

    # --- calote: o topo do sino e' redondo, nao cortado a direito --------
    r0 = _perfil_sino(0.0) * larg
    d.ellipse([cx - r0, corpo0 - r0 * 0.75, cx + r0, corpo0 + r0 * 0.75],
              fill=cor)

    # --- corpo ------------------------------------------------------------
    for y in range(corpo0, corpo1 + 1):
        t = (y - corpo0) / h
        r = _perfil_sino(t) * larg
        rd = r
        if partido and t > 0.62:
            # falta um gomo do lado direito -- o "sino partido" do contrato
            rd = r * (1.0 - 0.8 * ((t - 0.62) / 0.38))
        x0 = int(round(cx - r))
        x1 = int(round(cx + rd))
        if x1 < x0:
            continue
        d.line([(x0, y), (x1, y)], fill=cor)
        # luz de cima-esquerda, sombra a` direita (convencao do jogo)
        d.line([(x0, y), (x0 + max(1, larg // 14), y)],
               fill=tuple(min(255, v + 46) for v in cor))
        d.point((x1, y), fill=BRONZE_ESCURO)
        if not partido and abs(t - 0.74) < (0.5 / h):
            d.line([(x0 + 1, y), (x1 - 1, y)], fill=OURO_ESCURO)  # friso

    # --- aba: abre PARA FORA do corpo, que e' o que remata a silhueta -----
    r_boca = _perfil_sino(1.0) * larg
    for i in range(aba):
        e = r_boca + (larg * 0.06) * (i / max(1, aba - 1))
        y = corpo1 + i
        x0 = int(round(cx - e))
        x1 = int(round(cx + (e if not partido else e * 0.55)))
        d.line([(x0, y), (x1, y)], fill=OURO if i < aba - 1 else OURO_ESCURO)
    d.line([(int(cx - r_boca), corpo1), (int(cx + r_boca), corpo1)],
           fill=OURO_VIVO)

    # --- coroa: pilar + argola, dentro da tela ---------------------------
    pw = max(1, larg // 12)
    d.rectangle([cx - pw, coroa - max(2, coroa // 2), cx + pw, coroa + 1],
                fill=OURO_ESCURO)
    ar = max(2, larg // 9)
    d.ellipse([cx - ar, 0, cx + ar, ar * 2], outline=OURO)
    d.ellipse([cx - ar + 1, 1, cx + ar - 1, ar * 2 - 1], outline=OURO_VIVO)
    return im


def sino_p() -> Image.Image:
    return _sino(22, 28)


def sino_m() -> Image.Image:
    return _sino(38, 48)


def sino_g() -> Image.Image:
    return _sino(76, 96, cor=(184, 142, 82))


def sino_partido() -> Image.Image:
    im = _sino(40, 46, partido=True)
    d = ImageDraw.Draw(im)
    # estilhacos no chao, para se ler como CAIDO e nao como pendurado
    for x, w in ((3, 5), (11, 3), (32, 4)):
        d.rectangle([x, 43, x + w, 45], fill=BRONZE_ESCURO)
    return im


def candelabro() -> Image.Image:
    """Pendurado. Tres bracos com chama -- a luz de vela do contrato."""
    im = _nova(46, 70)
    d = ImageDraw.Draw(im)
    d.line([(23, 0), (23, 26)], fill=FERRO)           # corrente
    d.line([(24, 0), (24, 26)], fill=FERRO_CLARO)
    d.ellipse([16, 24, 30, 32], outline=OURO, fill=OURO_ESCURO)
    d.arc([4, 26, 42, 48], 200, 340, fill=OURO)       # aro
    d.arc([4, 27, 42, 49], 200, 340, fill=OURO_ESCURO)
    for bx in (7, 23, 39):
        d.line([(bx, 34), (bx, 44)], fill=OURO)
        d.rectangle([bx - 2, 44, bx + 1, 52], fill=(236, 232, 214))  # vela
        d.rectangle([bx - 1, 40, bx, 44], fill=CHAMA)
        d.point((bx - 1, 39), fill=CHAMA_NUCLEO)
    return im


def braseiro() -> Image.Image:
    """Chao. Taca de bronze com brasas -- as 'chamas azuis' do contrato
    ficam para o FX; aqui a brasa e' quente para contrastar com o azul."""
    im = _nova(38, 44)
    d = ImageDraw.Draw(im)
    d.polygon([(6, 18), (32, 18), (27, 33), (11, 33)], fill=BRONZE)
    d.line([(6, 18), (32, 18)], fill=OURO_VIVO)
    d.line([(11, 33), (27, 33)], fill=BRONZE_ESCURO)
    d.rectangle([17, 33, 21, 40], fill=BRONZE_ESCURO)      # pe
    d.rectangle([12, 40, 26, 43], fill=BRONZE)
    for x in range(9, 30, 3):                               # brasas
        d.rectangle([x, 14, x + 2, 18], fill=CHAMA)
    d.rectangle([16, 8, 22, 15], fill=CHAMA)
    d.rectangle([18, 5, 20, 10], fill=CHAMA_NUCLEO)
    return im


def estatua_anjo() -> Image.Image:
    """Parede. Guardia de pedra. A primeira versao desenhava as asas como
    barras horizontais empilhadas e lia-se um totem -- as asas tem de ABRIR
    para fora e para cima, senao nao ha' anjo nenhum."""
    im = _nova(78, 132)
    d = ImageDraw.Draw(im)
    cx = 39

    # asas primeiro (ficam ATRAS do corpo)
    for lado in (-1, 1):
        for cam in range(3):                    # tres fiadas de penas
            for i in range(6):
                t = i / 5.0
                # arco que sobe e abre: perto do ombro curto, na ponta longo
                px = cx + lado * int(10 + 26 * t)
                py = int(58 - 34 * t + cam * 9)
                comp = int(12 - 7 * t + cam * 2)
                x0 = px if lado > 0 else px - comp
                cor = (PEDRA_CLARA, PEDRA, PEDRA_ESCURA)[cam]
                d.rectangle([x0, py, x0 + comp, py + 4], fill=cor)
                d.line([(x0, py), (x0 + comp, py)], fill=PEDRA_SOMBRA)

    _sombrear(d, (cx - 15, 112, cx + 15, 131),
              PEDRA_ESCURA, PEDRA, PEDRA_SOMBRA)          # plinto
    # manto: estreito nos ombros, a abrir ate' aos pes
    for y in range(44, 113):
        t = (y - 44) / 68.0
        w = int(9 + 9 * t)
        d.line([(cx - w, y), (cx + w, y)], fill=PEDRA)
        d.line([(cx - w, y), (cx - w + 2, y)], fill=PEDRA_CLARA)
        d.point((cx + w, y), fill=PEDRA_ESCURA)
        if y % 9 == 0:                                     # pregas
            d.line([(cx - w + 3, y), (cx + w - 3, y)], fill=PEDRA_ESCURA)
    d.ellipse([cx - 7, 26, cx + 7, 44], fill=PEDRA_CLARA,
              outline=PEDRA_ESCURA)                        # cabeca
    d.arc([cx - 11, 16, cx + 11, 34], 180, 360, fill=OURO) # halo
    d.arc([cx - 10, 17, cx + 10, 33], 180, 360, fill=OURO_VIVO)
    # bracos juntos a` frente, a segurar um sino pequeno
    d.line([(cx - 8, 56), (cx - 3, 74)], fill=PEDRA_ESCURA)
    d.line([(cx + 8, 56), (cx + 3, 74)], fill=PEDRA_ESCURA)
    im.alpha_composite(_sino(16, 20), (cx - 8, 70))
    return im


def gargula() -> Image.Image:
    """Pendurado. Cabeca de besta numa consola, a olhar para baixo. A
    primeira versao era pequena e sem cara -- lia-se um lampiao."""
    im = _nova(46, 54)
    d = ImageDraw.Draw(im)
    d.rectangle([2, 0, 43, 7], fill=PEDRA_ESCURA)          # consola
    d.line([(2, 0), (43, 0)], fill=PEDRA_CLARA)
    d.line([(2, 7), (43, 7)], fill=PEDRA_SOMBRA)
    for lado in (-1, 1):                                   # asas encolhidas
        bx = 23 + lado * 15
        for i in range(4):
            d.rectangle([bx - 4 if lado < 0 else bx, 9 + i * 6,
                         bx if lado < 0 else bx + 4, 13 + i * 6],
                        fill=PEDRA_ESCURA if i % 2 else PEDRA)
    d.polygon([(10, 7), (36, 7), (32, 24), (14, 24)], fill=PEDRA)  # ombros
    d.line([(10, 7), (14, 24)], fill=PEDRA_CLARA)
    for lado in (-1, 1):                                   # cornos
        d.polygon([(23 + lado * 7, 20), (23 + lado * 11, 12),
                   (23 + lado * 9, 22)], fill=PEDRA_CLARA)
    d.ellipse([12, 20, 34, 42], fill=PEDRA, outline=PEDRA_SOMBRA)  # cara
    d.line([(14, 26), (20, 28)], fill=PEDRA_SOMBRA)        # sobrancelhas
    d.line([(26, 28), (32, 26)], fill=PEDRA_SOMBRA)
    d.rectangle([17, 29, 20, 32], fill=OURO)               # olhos
    d.rectangle([26, 29, 29, 32], fill=OURO)
    d.polygon([(16, 38), (30, 38), (23, 50)], fill=PEDRA_ESCURA)   # focinho
    for x in range(18, 29, 3):                             # dentes
        d.rectangle([x, 38, x + 1, 41], fill=(226, 224, 214))
    return im


def engrenagem() -> Image.Image:
    """Chao. A roda dentada do N13 -- o 'mecanismo antigo' visto de lado."""
    im = _nova(44, 44)
    d = ImageDraw.Draw(im)
    cx = cy = 22.0
    for i in range(10):                                   # dentes
        a = i * (2 * math.pi / 10)
        x = cx + math.cos(a) * 19
        y = cy + math.sin(a) * 19
        d.rectangle([x - 3, y - 3, x + 3, y + 3], fill=BRONZE)
    d.ellipse([6, 6, 38, 38], fill=BRONZE, outline=BRONZE_ESCURO)
    d.ellipse([9, 9, 35, 35], outline=OURO_ESCURO)
    d.ellipse([16, 16, 28, 28], fill=PEDRA_SOMBRA, outline=BRONZE_ESCURO)
    d.arc([6, 6, 38, 38], 190, 300, fill=OURO_VIVO)       # fio de luz
    return im


def relogio_antigo() -> Image.Image:
    """Parede. Mostrador parado -- 'o passado move o presente' (N13)."""
    im = _nova(44, 58)
    d = ImageDraw.Draw(im)
    _sombrear(d, (4, 2, 40, 50), PEDRA_ESCURA, PEDRA_CLARA, PEDRA_SOMBRA)
    d.ellipse([8, 6, 36, 34], fill=(226, 222, 206), outline=BRONZE_ESCURO)
    d.ellipse([10, 8, 34, 32], outline=OURO_ESCURO)
    d.line([(22, 20), (22, 12)], fill=(40, 40, 52))       # ponteiros parados
    d.line([(22, 20), (29, 24)], fill=(40, 40, 52))
    d.point((22, 20), fill=OURO)
    d.rectangle([18, 38, 26, 48], fill=BRONZE_ESCURO)     # pendulo
    d.line([(22, 34), (22, 38)], fill=BRONZE)
    d.polygon([(2, 2), (42, 2), (22, -4)], fill=PEDRA)    # cornija
    return im


def memorial() -> Image.Image:
    """Chao. Placa com inscricao -- o 'memorial' narrativo do contrato.
    Substitui a `lapide` de cemiterio, que nao pertence a uma torre."""
    im = _nova(34, 40)
    d = ImageDraw.Draw(im)
    _sombrear(d, (2, 30, 32, 38), PEDRA_ESCURA, PEDRA, PEDRA_SOMBRA)
    _sombrear(d, (6, 4, 28, 32), PEDRA, PEDRA_CLARA, PEDRA_ESCURA)
    d.arc([6, -4, 28, 14], 180, 360, fill=PEDRA_CLARA)
    for i, y in enumerate((12, 17, 22, 27)):              # inscricao
        d.line([(10, y), (24 - i * 3, y)], fill=PEDRA_SOMBRA)
    d.point((17, 8), fill=OURO)                            # simbolo do eco
    d.arc([13, 4, 21, 12], 0, 360, fill=OURO_ESCURO)
    return im


def urna() -> Image.Image:
    im = _nova(26, 34)
    d = ImageDraw.Draw(im)
    d.ellipse([3, 8, 23, 32], fill=PEDRA, outline=PEDRA_ESCURA)
    d.rectangle([9, 2, 17, 10], fill=PEDRA_ESCURA)
    d.ellipse([7, 0, 19, 6], fill=PEDRA_CLARA, outline=PEDRA_ESCURA)
    d.arc([3, 8, 23, 32], 190, 280, fill=PEDRA_CLARA)
    d.line([(8, 18), (18, 18)], fill=OURO_ESCURO)
    return im


def livros() -> Image.Image:
    im = _nova(30, 22)
    d = ImageDraw.Draw(im)
    cores = [(126, 72, 68), (68, 86, 128), (104, 86, 132)]
    y = 21
    for i, c in enumerate(cores):
        h = 5
        w = 26 - i * 4
        d.rectangle([2 + i, y - h, 2 + i + w, y], fill=c)
        d.line([(2 + i, y - h), (2 + i + w, y - h)],
               fill=tuple(min(255, v + 40) for v in c))
        d.line([(2 + i + w, y - h), (2 + i + w, y)], fill=OURO_ESCURO)
        y -= h + 1
    return im


def pedra_memoria() -> Image.Image:
    """Chao. O interativo 'pedra de memoria' do contrato, em versao prop."""
    im = _nova(28, 30)
    d = ImageDraw.Draw(im)
    d.polygon([(4, 28), (24, 28), (20, 6), (8, 6)], fill=PEDRA)
    d.line([(8, 6), (20, 6)], fill=PEDRA_CLARA)
    d.line([(4, 28), (8, 6)], fill=PEDRA_CLARA)
    d.line([(24, 28), (20, 6)], fill=PEDRA_SOMBRA)
    for r in (4, 7, 10):                                   # onda de eco
        d.arc([14 - r, 16 - r, 14 + r, 16 + r], 0, 360, fill=VITRAL_AZUL)
    d.point((14, 16), fill=CHAMA_NUCLEO)
    return im


def detritos() -> Image.Image:
    im = _nova(36, 14)
    d = ImageDraw.Draw(im)
    rng = random.Random(30303)
    for _ in range(9):
        x = rng.randint(0, 30)
        y = rng.randint(6, 12)
        w = rng.randint(2, 5)
        d.rectangle([x, y, x + w, y + rng.randint(1, 3)],
                    fill=rng.choice([PEDRA, PEDRA_ESCURA, PEDRA_CLARA]))
    return im


def _vitral(larg: int, alt: int) -> Image.Image:
    """Janela de vitral: moldura de pedra, ogiva, e vidro em gomos. E' o
    motivo que o contrato repete mais vezes (parede com vitral, vitrais
    interativos, construto vitral, espinhos de vitral)."""
    im = _nova(larg, alt)
    d = ImageDraw.Draw(im)
    d.rectangle([0, larg // 2, larg - 1, alt - 1], fill=PEDRA_ESCURA)
    d.pieslice([0, 0, larg - 1, larg - 1], 180, 360, fill=PEDRA_ESCURA)
    m = max(3, larg // 8)
    d.rectangle([m, larg // 2, larg - 1 - m, alt - 1 - m], fill=VITRAL_AZUL)
    d.pieslice([m, m, larg - 1 - m, larg - 1 - m], 180, 360, fill=VITRAL_AZUL)
    rng = random.Random(larg * 97 + alt)
    for y in range(larg // 2, alt - m, max(5, alt // 9)):   # gomos
        for x in range(m, larg - m, max(5, larg // 5)):
            if rng.random() < 0.45:
                d.rectangle([x, y, x + 3, y + 3],
                            fill=rng.choice([VITRAL_ROXO, VITRAL_OURO]))
    d.line([(larg // 2, m), (larg // 2, alt - 1 - m)], fill=PEDRA_ESCURA)
    for y in range(larg // 2, alt - m, max(6, alt // 7)):
        d.line([(m, y), (larg - 1 - m, y)], fill=PEDRA_SOMBRA)
    d.rectangle([0, 0, larg - 1, alt - 1], outline=PEDRA)
    return im


def vitral_alto() -> Image.Image:
    return _vitral(46, 132)


def vitral_partido() -> Image.Image:
    im = _vitral(40, 92)
    d = ImageDraw.Draw(im)
    for pts in (((14, 40), (26, 62)), ((26, 40), (12, 70)), ((8, 56), (32, 58))):
        d.line(list(pts), fill=PEDRA_SOMBRA)
    d.rectangle([16, 74, 30, 88], fill=(0, 0, 0, 0))      # gomo em falta
    return im


def arco_grande() -> Image.Image:
    """Parede. A ogiva -- a peca de arquitetura que mais falta a` camada
    jogavel: sem arcos, um corredor de torre le-se como corredor de cave."""
    im = _nova(120, 190)
    d = ImageDraw.Draw(im)
    for lado in (0, 96):                                   # pes-direitos
        _sombrear(d, (lado, 60, lado + 23, 189),
                  PEDRA_ESCURA, PEDRA, PEDRA_SOMBRA)
        for y in range(64, 188, 16):                       # silhares
            d.line([(lado, y), (lado + 23, y)], fill=PEDRA_SOMBRA)
    d.pieslice([0, 0, 119, 132], 180, 360, fill=PEDRA_ESCURA)
    d.pieslice([23, 22, 96, 120], 180, 360, fill=(0, 0, 0, 0))
    d.arc([0, 0, 119, 132], 180, 360, fill=PEDRA)
    d.arc([23, 22, 96, 120], 180, 360, fill=PEDRA_SOMBRA)
    for i in range(9):                                     # aduelas
        a = math.pi + i * (math.pi / 8)
        x0 = 60 + math.cos(a) * 36
        y0 = 66 + math.sin(a) * 49
        x1 = 60 + math.cos(a) * 59
        y1 = 66 + math.sin(a) * 66
        d.line([(x0, y0), (x1, y1)], fill=PEDRA_SOMBRA)
    d.rectangle([54, 4, 66, 14], fill=OURO_ESCURO)         # fecho
    return im


def arco_pequeno() -> Image.Image:
    im = _nova(64, 104)
    d = ImageDraw.Draw(im)
    for lado in (0, 50):
        _sombrear(d, (lado, 34, lado + 13, 103),
                  PEDRA_ESCURA, PEDRA, PEDRA_SOMBRA)
    d.pieslice([0, 0, 63, 72], 180, 360, fill=PEDRA_ESCURA)
    d.pieslice([13, 13, 50, 66], 180, 360, fill=(0, 0, 0, 0))
    d.arc([0, 0, 63, 72], 180, 360, fill=PEDRA)
    d.rectangle([29, 2, 35, 9], fill=OURO_ESCURO)
    return im


def coluna_dupla() -> Image.Image:
    """Parede. Duas colunas com capitel e entablamento -- da' profundidade
    de nave a uma galeria (N12 'Galerias Verticais')."""
    im = _nova(72, 210)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 71, 12], fill=PEDRA_ESCURA)         # entablamento
    d.line([(0, 0), (71, 0)], fill=PEDRA_CLARA)
    d.line([(0, 12), (71, 12)], fill=PEDRA_SOMBRA)
    for cx in (16, 56):
        d.rectangle([cx - 13, 12, cx + 13, 22], fill=PEDRA)     # capitel
        d.line([(cx - 13, 12), (cx + 13, 12)], fill=PEDRA_CLARA)
        _sombrear(d, (cx - 9, 22, cx + 9, 190), PEDRA, PEDRA_CLARA, PEDRA_ESCURA)
        for dx in (-5, 0, 5):                                    # caneluras
            d.line([(cx + dx, 24), (cx + dx, 188)], fill=PEDRA_ESCURA)
        d.rectangle([cx - 13, 190, cx + 13, 205], fill=PEDRA_ESCURA)  # base
        d.line([(cx - 13, 190), (cx + 13, 190)], fill=PEDRA)
    d.arc([16, -46, 56, 34], 180, 360, fill=PEDRA_SOMBRA)   # arco entre elas
    return im


def corrente_sino() -> Image.Image:
    """Pendurado. Corrente grossa com sino pequeno na ponta -- o motivo
    'correntes moveis' + 'sino' do contrato, num so' prop."""
    im = _nova(24, 96)
    d = ImageDraw.Draw(im)
    for i in range(0, 62, 8):                              # elos
        d.ellipse([8, i, 15, i + 9], outline=FERRO_CLARO)
        d.ellipse([9, i + 1, 14, i + 8], outline=FERRO)
    sino = _sino(22, 30)
    im.alpha_composite(sino, (1, 64))
    return im


def lanterna_eco() -> Image.Image:
    im = _nova(24, 56)
    d = ImageDraw.Draw(im)
    d.line([(12, 0), (12, 16)], fill=FERRO)
    d.rectangle([5, 16, 19, 21], fill=BRONZE_ESCURO)
    d.polygon([(6, 21), (18, 21), (16, 42), (8, 42)], fill=VITRAL_AZUL)
    d.polygon([(6, 21), (18, 21), (16, 42), (8, 42)], outline=BRONZE)
    d.rectangle([10, 28, 14, 36], fill=CHAMA)
    d.point((12, 32), fill=CHAMA_NUCLEO)
    d.rectangle([6, 42, 18, 46], fill=BRONZE_ESCURO)
    return im


# nome -> (funcao, onde). `onde` e' o que o jogo usa para assentar o prop:
#   chao      -- em cima das plataformas (`plataforma.gd::_decorar`)
#   parede    -- atras da accao (`gerador_corredor.gd::_coluna_fundo`)
#   pendurado -- por baixo dos degraus grossos
PROPS = [
    ("sino_p", sino_p, "chao"),
    ("sino_partido", sino_partido, "chao"),
    ("braseiro", braseiro, "chao"),
    ("engrenagem", engrenagem, "chao"),
    ("memorial", memorial, "chao"),
    ("urna", urna, "chao"),
    ("livros", livros, "chao"),
    ("pedra_memoria", pedra_memoria, "chao"),
    ("detritos", detritos, "chao"),
    ("arco_grande", arco_grande, "parede"),
    ("arco_pequeno", arco_pequeno, "parede"),
    ("coluna_dupla", coluna_dupla, "parede"),
    ("vitral_alto", vitral_alto, "parede"),
    ("vitral_partido", vitral_partido, "parede"),
    ("estatua_anjo", estatua_anjo, "parede"),
    ("relogio_antigo", relogio_antigo, "parede"),
    ("sino_g", sino_g, "parede"),
    ("candelabro", candelabro, "pendurado"),
    ("gargula", gargula, "pendurado"),
    ("corrente_sino", corrente_sino, "pendurado"),
    ("lanterna_eco", lanterna_eco, "pendurado"),
    ("sino_m", sino_m, "pendurado"),
]

# Props que SAEM do bioma `torres`: sao de cemiterio (vieram da folha
# `gothicvania-cemetery`) e sao parte medida da razao de os cinco niveis da
# Torre dos Ecos lerem como campa. Continuam a existir para as Catacumbas,
# que e' onde pertencem (`cruz_a`, `lapide_a`... no bioma `catacumbas`).
REMOVER = ["cruz", "lapide"]


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    for nome, fn, _onde in PROPS:
        im = fn()
        im.save(DEST / f"{nome}.png")
        print(f"  {nome:>16}.png  {im.size[0]:>3}x{im.size[1]}")

    cat = json.loads(MANIFESTO.read_text(encoding="utf-8"))
    antigos = cat.get("torres", [])
    ficam = [p for p in antigos
             if p["nome"] not in REMOVER
             and p["nome"] not in {n for n, _f, _o in PROPS}]
    novos = [{"nome": n, "onde": o} for n, _f, o in PROPS]
    cat["torres"] = ficam + novos
    MANIFESTO.write_text(json.dumps(cat, ensure_ascii=False, indent=1) + "\n",
                         encoding="utf-8")

    for nome in REMOVER:
        for suf in (".png", ".png.import"):
            alvo = DEST / (nome + suf)
            if alvo.exists():
                alvo.unlink()
                print(f"  removido (cemiterio): {alvo.name}")

    por_onde: dict[str, int] = {}
    for p in cat["torres"]:
        por_onde[p["onde"]] = por_onde.get(p["onde"], 0) + 1
    print(f"\ntorres: {len(cat['torres'])} props "
          + " · ".join(f"{k} {v}" for k, v in sorted(por_onde.items())))


if __name__ == "__main__":
    main()
