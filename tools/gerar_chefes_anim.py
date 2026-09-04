#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Desenha os CHEFES do Koliani de raiz, em pixel-art animado.

Substitui os rigs de packs emprestados (`tools/importar_chefes_animados.py`)
por arte NOSSA, fiel ao lore de cada chefe -- que e' o pedido do Paulo:
"sair dos assets emprestados e desenhar cada chefe a traduzir mesmo o lore
dele". O Ghorak deixa de ser um minotauro, o Sino Vivo deixa de ser um
bau-mimico, a Rainha Aracnidea deixa de ser um "horror" generico.

A fonte do lore e' `docs/niveis.md` -- cada chefe aqui leva em comentario a
linha da biblia que a silhueta esta' a traduzir. Se a descricao mudar, muda
o desenho.

Motor em `tools/chefes_desenho.py` (poligonos + contorno + luz de topo),
corpos em `tools/chefes_corpos.py`, animacao em `tools/chefes_gaits.py`.

  python tools/gerar_chefes_anim.py                # grava tudo
  python tools/gerar_chefes_anim.py ghorak morvanna   # so' estes
  python tools/gerar_chefes_anim.py --preview      # + folha de contacto

Depois: `godot --headless --import` (os .import das tiras novas).
"""

from __future__ import annotations

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PIL import Image

from chefes_corpos import CORPOS, Juntas
from chefes_desenho import (Esqueleto, Peca, caixa, clarear, cor, elipse,
                            escurecer, esbater, estrela, exportar, membro,
                            mover, rodar, trapezio)
from chefes_gaits import PLANOS

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEST = os.path.join(RAIZ, "assets", "sprites", "pixel", "bosses_anim")

## Quantos frames tem cada estado. O ataque e' o mais longo de proposito: e'
## nele que vive o telegrafo, e um telegrafo curto e' um chefe injusto.
FRAMES = {"idle": 6, "walk": 8, "attack": 10, "hurt": 4, "death": 10}
FPS = {"idle": 7.0, "walk": 11.0, "attack": 14.0, "hurt": 12.0, "death": 10.0}


# ── paletas da casa ──────────────────────────────────────────────────────
# Todas saem do key art: violeta-preto, luar frio e magenta como unico
# acento quente. O `brilho` e' sempre o ponto fraco do chefe.

CONTORNO = cor("0a0a12")
MAGENTA = cor("ff45ef")
MAGENTA_ESC = cor("b023cf")


def paleta(corpo: str, corpo2: str, pele: str, detalhe: str,
           metal: str = "6b5f8f", brilho: str | None = None, **extra) -> dict:
    p = {
        "corpo": cor(corpo), "corpo2": cor(corpo2), "pele": cor(pele),
        "detalhe": cor(detalhe), "metal": cor(metal),
        "brilho": MAGENTA if brilho is None else cor(brilho),
        "contorno": CONTORNO,
    }
    p.update({k: cor(v) if isinstance(v, str) else v for k, v in extra.items()})
    return p


# ── ajudas para os adereços ──────────────────────────────────────────────

def junta(juntas: Juntas, nome: str, pai: str, x: float, y: float) -> None:
    juntas[nome] = (pai, (x, y))


def tirar(pecas: list[Peca], *tags: str) -> None:
    """Apaga pecas do corpo generico. Usa-se sempre que o chefe traz cabeca
    propria: a cabeca de base tem `z` alto e ficaria por cima do capuz."""
    fora = set(tags)
    pecas[:] = [p for p in pecas if p.tag not in fora]


def pintar(pecas: list[Peca], tags: str | tuple, c) -> None:
    """Repinta pecas do corpo generico (bracos de osso, pernas de pedra...)."""
    alvo = {tags} if isinstance(tags, str) else set(tags)
    for p in pecas:
        if p.tag in alvo:
            p.cor = c if p.z >= 0.0 else escurecer(c, 0.34)


def nucleo(pecas: list[Peca], j: str, x: float, y: float, r: float,
           c=MAGENTA) -> None:
    """O ponto fraco: um nucleo de luz. Todos os chefes tem um -- e' a
    linguagem visual que o jogo ja' usa (`cor_rim` magenta).

    Mantem-se PEQUENO de proposito: na primeira leva o nucleo saiu com o
    tamanho de uma cabeca e o chefe passou a ler-se como "boneco com uma
    bola roxa". Ele e' um pormenor que chama a atencao, nao a silhueta.
    """
    pecas.append(Peca(j, elipse(x, y, r * 1.5, r * 1.5), escurecer(c, 0.62), 4.0))
    pecas.append(Peca(j, elipse(x, y, r, r), c, 4.1, brilho=True))
    pecas.append(Peca(j, elipse(x - r * 0.28, y - r * 0.32, r * 0.4, r * 0.4),
                      clarear(c, 0.7), 4.2, brilho=True))


def veios(pecas: list[Peca], j: str, c, x0: float, y0: float, y1: float,
          n: int = 3, z: float = 0.65) -> None:
    """Riscos verticais: veio da madeira, dobras do pano, estrias da pedra.
    E' o que tira a mancha lisa de cima de uma peca grande."""
    for k in range(n):
        x = x0 + k * 4.0
        pecas.append(Peca(j, caixa(x, y0 + (k % 2) * 3.0, x + 1.2, y1 - (k % 3) * 4.0),
                          c, z))


def cranio(pecas: list[Peca], j: str, osso, r: float = 7.0, z: float = 2.0,
           c_olho=MAGENTA) -> None:
    """Cabeca de caveira: calote, orbitas fundas e maxilar. Muito mais
    legivel a esta escala do que uma cara desenhada."""
    pecas.append(Peca(j, elipse(0.0, -r * 0.65, r, r * 0.95), osso, z))
    pecas.append(Peca(j, [(-r * 0.62, -r * 0.1), (r * 0.62, -r * 0.1),
                          (r * 0.46, r * 0.7), (-r * 0.46, r * 0.7)], osso, z + 0.05))
    for lado in (-1.0, 1.0):
        pecas.append(Peca(j, elipse(lado * r * 0.36, -r * 0.62, r * 0.28, r * 0.34),
                          escurecer(osso, 0.78), z + 0.1))
        pecas.append(Peca(j, elipse(lado * r * 0.36, -r * 0.6, r * 0.16, r * 0.18),
                          c_olho, z + 0.15, brilho=True))
    for k in range(-1, 2):
        pecas.append(Peca(j, caixa(k * r * 0.3 - 0.6, -r * 0.05, k * r * 0.3 + 0.6, r * 0.62),
                          escurecer(osso, 0.6), z + 0.12))


def olhos(pecas: list[Peca], j: str, x: float, y: float, r: float = 1.3,
          c=MAGENTA, sep: float = 3.0, z: float = 4.0) -> None:
    """Dois olhos acesos. Achatados de proposito: redondos ficam com ar de
    desenho animado, e o jogo e' gotico."""
    for lado in (-1.0, 1.0):
        pecas.append(Peca(j, elipse(x + lado * sep, y, r * 1.2, r * 0.8), c, z, brilho=True))


def chifres(pecas: list[Peca], j: str, c, alt: float = 9.0,
            aber: float = 5.5, z: float = 2.4) -> None:
    for lado in (-1.0, 1.0):
        pecas.append(Peca(j, [
            (lado * 2.5, -6.0), (lado * (aber + 1.0), -6.0 - alt * 0.55),
            (lado * (aber + 3.5), -6.0 - alt), (lado * (aber - 1.5), -6.0 - alt * 0.5),
            (lado * 1.5, -3.0)], c, z))


def capuz(pecas: list[Peca], j: str, c, r: float = 9.0, z: float = 2.6) -> None:
    """Capuz fechado: a cara fica no escuro e so' se veem os olhos."""
    pecas.append(Peca(j, [
        (-r, 2.0), (-r * 0.95, -r * 0.9), (-r * 0.3, -r * 1.5),
        (r * 0.5, -r * 1.45), (r * 1.05, -r * 0.55), (r * 0.9, 3.0),
        (r * 0.2, -r * 0.15), (-r * 0.45, -r * 0.1)], c, z))


def manto_ombros(pecas: list[Peca], j: str, c, larg: float = 22.0,
                 alt: float = 12.0, z: float = 3.4) -> None:
    pecas.append(Peca(j, [(-larg * 0.5, -2.0), (larg * 0.5, -2.0),
                          (larg * 0.42, alt), (-larg * 0.42, alt)], c, z))


def espinhos_ombro(pecas: list[Peca], j: str, c, y: float, n: int = 3,
                   larg: float = 18.0, alt: float = 7.0, z: float = 3.5) -> None:
    for k in range(n):
        x = -larg * 0.5 + larg * (k + 0.5) / n
        pecas.append(Peca(j, [(x - 2.6, y), (x + 2.6, y), (x, y - alt)], c, z))


def foice(pecas: list[Peca], j: str, cabo, lamina, comp: float = 34.0) -> None:
    pecas.append(Peca(j, membro(comp, 3.0, 2.5), cabo, 4.0))
    pecas.append(Peca(j, [(0.0, comp), (16.0, comp - 4.0), (23.0, comp - 15.0),
                          (19.0, comp - 6.0), (6.0, comp + 3.0)], lamina, 4.1))


def martelo(pecas: list[Peca], j: str, cabo, cabeca, comp: float = 26.0) -> None:
    pecas.append(Peca(j, membro(comp, 3.5, 3.0), cabo, 4.0))
    pecas.append(Peca(j, caixa(-8.0, comp - 3.0, 8.0, comp + 10.0), cabeca, 4.1))
    pecas.append(Peca(j, caixa(-9.5, comp - 1.0, 9.5, comp + 8.0), clarear(cabeca, 0.18), 4.15))


def espada(pecas: list[Peca], j: str, cabo, lamina, comp: float = 30.0,
           larg: float = 4.0) -> None:
    pecas.append(Peca(j, membro(8.0, 3.0), cabo, 4.0))
    pecas.append(Peca(j, caixa(-6.0, 7.0, 6.0, 9.5), cabo, 4.05))
    pecas.append(Peca(j, [(-larg, 9.0), (larg, 9.0), (larg * 0.7, comp),
                          (0.0, comp + 6.0), (-larg * 0.7, comp)], lamina, 4.1))


def cajado(pecas: list[Peca], j: str, cabo, c_orbe, comp: float = 32.0) -> None:
    pecas.append(Peca(j, membro(comp, 3.0, 2.5), cabo, 4.0))
    pecas.append(Peca(j, elipse(0.0, -3.0, 6.5, 6.5), escurecer(c_orbe, 0.5), 4.05))
    pecas.append(Peca(j, elipse(0.0, -3.0, 4.5, 4.5), c_orbe, 4.1, brilho=True))


def coroa(pecas: list[Peca], j: str, c, r: float = 8.0, z: float = 2.5) -> None:
    pecas.append(Peca(j, caixa(-r, -r * 1.5, r, -r * 1.05), c, z))
    for k in range(-1, 2):
        x = k * r * 0.62
        pecas.append(Peca(j, [(x - 2.2, -r * 1.4), (x + 2.2, -r * 1.4),
                              (x, -r * 2.25)], c, z))


def chama(pecas: list[Peca], j: str, x: float, y: float, alt: float,
          c=cor("ff8a3d"), z: float = 4.5) -> None:
    pecas.append(Peca(j, [(x - alt * 0.32, y), (x + alt * 0.32, y),
                          (x + alt * 0.12, y - alt * 0.55), (x, y - alt),
                          (x - alt * 0.2, y - alt * 0.5)], c, z, brilho=True))


# ── os chefes ────────────────────────────────────────────────────────────
# Cada entrada cita a linha de `docs/niveis.md` que esta' a traduzir.

def _ghorak(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "guerreiro de tronco, ossos e raizes. Fraqueza: nucleo purpura no peito"
    casca, musgo, osso = pal["corpo"], pal["corpo2"], pal["pele"]
    tirar(pecas, "cabeca", "pescoco")
    # os antebracos sao OSSO a' mostra -- mas num tom cavado, senao sao a
    # coisa mais clara do sprite e roubam o olho ao nucleo
    pintar(pecas, ("antebraco_t", "antebraco_f"), escurecer(osso, 0.34))
    # ombros de raiz enrolada, muito mais largos que a cintura: le'-se como
    # arvore antes de se ler como homem
    for lado, j in ((-1.0, "ombro_t"), (1.0, "ombro_f")):
        z = -1.4 if lado < 0 else 3.4
        pecas.append(Peca(j, elipse(lado * 3.0, -1.0, 9.5, 7.5), casca, z))
        for ang in (-34.0, 0.0, 34.0):
            pecas.append(Peca(j, rodar(membro(10.0, 4.0, 1.8), ang + lado * 22.0 - 90.0),
                              escurecer(casca, 0.18), z + 0.05))
        pecas.append(Peca(j, elipse(lado * 4.5, -5.0, 5.0, 3.0), musgo, z + 0.1))
    veios(pecas, "torso", escurecer(casca, 0.4), -6.0, -23.0, -3.0, n=4)
    # costelas de osso a romper a casca. Em tom ESCURECIDO: a osso cheio
    # eram a coisa mais clara do sprite e roubavam o olho ao nucleo.
    osso_fundo = escurecer(osso, 0.42)
    for k in range(2):
        y = -12.0 + k * 5.5
        pecas.append(Peca("torso", [(-8.0, y), (8.0, y - 1.0), (7.0, y + 2.2),
                                    (-7.0, y + 3.0)], osso_fundo, 0.7))
    # A cabeca e' um CAPUZ de casca com um cranio la' dentro, quase todo na
    # sombra -- so' as orbitas acesas se leem. Mais gotico e mais legivel do
    # que uma caveira inteira em osso claro a esta escala.
    pecas.append(Peca("cabeca", elipse(0.0, -5.0, 8.6, 8.0), casca, 1.7))
    pecas.append(Peca("cabeca", elipse(1.0, -4.0, 6.0, 6.2), escurecer(casca, 0.72), 1.75))
    pecas.append(Peca("cabeca", elipse(1.5, -1.5, 4.2, 3.4), osso_fundo, 1.8))
    for k in range(-1, 2):
        pecas.append(Peca("cabeca", caixa(1.5 + k * 2.2 - 0.6, -2.0,
                                          1.5 + k * 2.2 + 0.6, 1.6),
                          escurecer(osso, 0.7), 1.85))
    olhos(pecas, "cabeca", 1.5, -6.0, 1.2, MAGENTA, sep=2.8, z=1.9)
    chifres(pecas, "cabeca", casca, alt=11.0, aber=6.5, z=1.6)
    # raizes a sair do queixo, como uma barba
    pecas.append(Peca("cabeca", [(-4.5, 1.0), (4.5, 1.0), (3.0, 11.0),
                                 (0.0, 6.0), (-3.0, 12.0)], musgo, 1.75))
    # placas de casca sobre os joelhos: parte a mancha lisa das pernas
    for j, z in (("joelho_t", -1.9), ("joelho_f", 1.2)):
        pecas.append(Peca(j, [(-5.5, -2.0), (5.5, -2.0), (4.5, 5.0), (-4.5, 5.0)],
                          casca if z > 0 else escurecer(casca, 0.34), z))
    nucleo(pecas, "torso", 1.0, -17.0, 3.0)
    # garras de raiz nas maos
    for j, z in (("cotovelo_t", -1.4), ("cotovelo_f", 3.6)):
        for ang in (-16.0, 0.0, 16.0):
            pecas.append(Peca(j, mover(rodar(membro(9.0, 3.4, 1.2), ang), 0.0, 10.0),
                              casca, z))


def _morvanna(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "flutua sobre a agua, invoca maos espectrais, cria clones de lama"
    manto, lodo = pal["corpo"], pal["corpo2"]
    tirar(pecas, "cabeca", "pescoco")
    junta(juntas, "chapeu", "cabeca", 0.0, -6.0)
    capuz(pecas, "cabeca", manto, r=8.5)
    # chapeu de bruxa tombado para tras -- a silhueta que a identifica de
    # longe, mesmo em pixel-art pequena
    pecas.append(Peca("chapeu", [(-11.0, 0.0), (11.0, 0.0), (6.0, -3.0),
                                 (-1.0, -9.0), (-9.0, -21.0), (-4.0, -6.0)],
                      escurecer(manto, 0.15), 2.8))
    pecas.append(Peca("chapeu", caixa(-11.5, -1.5, 11.5, 1.5), lodo, 2.85))
    olhos(pecas, "cabeca", 1.5, -6.0, 1.6, cor("9dff6b"), sep=3.0)
    cajado(pecas, "arma", cor("2c2118"), cor("9dff6b"), comp=30.0)
    # pingos de lodo a cair do manto: e' o pantano a acompanha'-la
    for x, y, r in ((-7.0, 6.0, 2.2), (4.0, 10.0, 1.8), (-1.0, 15.0, 1.5)):
        pecas.append(Peca("cauda2", elipse(x, y, r, r * 1.4), lodo, -0.55))
    nucleo(pecas, "corpo", 1.0, -13.0, 3.4, cor("9dff6b"))


def _rainha(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "aranha colossal com ROSTO HUMANO. Cospe teias; solta ovos"
    quitina, veludo = pal["corpo"], pal["corpo2"]
    tirar(pecas, "cabeca")
    # cabelo comprido a cair do rosto humano para cima do cefalotorax
    pecas.append(Peca("cabeca", [(-7.0, -4.0), (6.0, -6.0), (8.0, 4.0),
                                 (-2.0, 12.0), (-9.0, 6.0)], pal["detalhe"], 0.9))
    coroa(pecas, "cabeca", pal["metal"], r=6.5, z=1.4)
    olhos(pecas, "cabeca", 1.0, -2.0, 1.3, cor("ff2d6f"), sep=2.6, z=1.3)
    # os oito olhos de aranha, esses ficam no abdomen -- e' o detalhe que
    # torna o rosto bonito em algo errado
    for x, y in ((-16.0, -12.0), (-11.0, -14.0), (-21.0, -9.0), (-13.0, -8.0)):
        pecas.append(Peca("corpo", elipse(x, y, 1.6, 1.6), cor("ff2d6f"), 0.6, brilho=True))
    # ampulheta vermelha da viuva negra
    pecas.append(Peca("corpo", [(-13.0, -6.0), (-9.0, -6.0), (-13.0, 1.0),
                                (-9.0, 1.0)], cor("ff2d6f"), 0.55))
    pecas.append(Peca("corpo", elipse(-13.0, -3.0, 7.0, 9.0), escurecer(veludo, 0.25), 0.45))
    nucleo(pecas, "corpo", -11.0, -22.0, 3.6)
    # presas
    for lado in (-1.0, 1.0):
        pecas.append(Peca("cabeca", [(lado * 2.0, 4.0), (lado * 4.5, 4.0),
                                     (lado * 3.0, 10.0)], pal["pele"], 1.1))


def _entrevane(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "varios rostos; galhos atacam de varias direccoes; lagrimas acidas"
    casca, seiva = pal["corpo"], pal["corpo2"]
    # nao tem cabeca nenhuma: e' uma arvore
    tirar(pecas, "cabeca", "pescoco")
    # nao tem cabeca: tem ROSTOS abertos na casca, a varias alturas
    for x, y, r in ((-4.0, -30.0, 4.5), (5.0, -18.0, 3.4), (-6.0, -9.0, 3.0)):
        pecas.append(Peca("torso", elipse(x, y, r * 1.15, r * 1.4),
                          escurecer(casca, 0.55), 0.7))
        pecas.append(Peca("torso", elipse(x - r * 0.4, y - r * 0.35, r * 0.34, r * 0.4),
                          cor("d8ff8a"), 0.75, brilho=True))
        pecas.append(Peca("torso", elipse(x + r * 0.45, y - r * 0.3, r * 0.34, r * 0.4),
                          cor("d8ff8a"), 0.75, brilho=True))
        # a lagrima acida, pendurada por baixo de cada rosto
        pecas.append(Peca("torso", [(x - 1.3, y + r * 0.9), (x + 1.3, y + r * 0.9),
                                    (x, y + r * 0.9 + 5.0)], cor("9dff6b"), 0.8, brilho=True))
    # copa: galhos abertos por cima do tronco em vez de cabeca
    for ang, comp in ((-52.0, 20.0), (-24.0, 26.0), (6.0, 22.0), (34.0, 17.0)):
        pecas.append(Peca("cabeca", rodar(membro(comp, 5.0, 2.0), ang + 180.0), casca, 1.8))
    # raizes em vez de pes: alargam a base e prendem-no ao chao
    for x, ang in ((-11.0, -28.0), (-3.0, -8.0), (6.0, 12.0), (13.0, 30.0)):
        pecas.append(Peca("anca", mover(rodar(membro(16.0, 6.0, 2.5), ang), x, 24.0),
                          escurecer(casca, 0.2), -2.5))
    nucleo(pecas, "torso", 0.0, -24.0, 3.2, cor("9dff6b"))


def _coracao(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "raizes, cadaveres e um CORACAO PURPURA. F2 o coracao bate"
    raiz_c, carne = pal["corpo"], pal["corpo2"]
    # o "corpo" e o "manto" dao lugar ao novelo de raizes
    tirar(pecas, "cabeca", "pescoco", "torso", "manto", "ponta")
    # novelo de raizes em vez de tronco: circulos irregulares sobrepostos
    for x, y, rx, ry in ((-9.0, -14.0, 11.0, 9.0), (8.0, -19.0, 9.0, 8.0),
                         (0.0, -6.0, 13.0, 8.0), (5.0, -28.0, 8.0, 7.0)):
        pecas.append(Peca("corpo", elipse(x, y, rx, ry), raiz_c, 0.1))
    # bracos que sao molhos de raiz
    for j, z in (("ombro_t", -1.4), ("ombro_f", 3.4)):
        for ang in (-10.0, 8.0, 24.0):
            pecas.append(Peca(j, rodar(membro(15.0, 4.5, 2.0), ang), raiz_c, z))
    # caras de cadaver presas no novelo -- ossos que a floresta engoliu
    for x, y in ((-13.0, -20.0), (11.0, -10.0)):
        pecas.append(Peca("corpo", elipse(x, y, 4.0, 4.6), pal["pele"], 0.5))
        pecas.append(Peca("corpo", elipse(x - 1.4, y - 0.5, 1.1, 1.4), CONTORNO, 0.55))
        pecas.append(Peca("corpo", elipse(x + 1.4, y - 0.5, 1.1, 1.4), CONTORNO, 0.55))
    # O CORACAO, no meio, grande: e' o chefe e o ponto fraco ao mesmo tempo
    pecas.append(Peca("cabeca", elipse(0.0, 6.0, 12.0, 11.0), escurecer(carne, 0.35), 2.0))
    pecas.append(Peca("cabeca", elipse(0.0, 5.0, 9.5, 9.0), carne, 2.1))
    nucleo(pecas, "cabeca", 0.0, 5.0, 5.2)
    # veias a sair do coracao para o novelo
    for ang in (-140.0, -95.0, -50.0, 150.0):
        pecas.append(Peca("cabeca", mover(rodar(membro(13.0, 3.0, 1.2), ang), 0.0, 5.0),
                          MAGENTA_ESC, 1.9))


CHEFES: dict[str, dict] = {
    # ── Regiao I -- Floresta Putrefacta ──────────────────────────────────
    "ghorak": {
        "plano": "humanoide",
        "par": {"coxa": 16.0, "canela": 15.0, "esp_perna": 10.0, "torso": 26.0,
                "ombros": 26.0, "cintura": 15.0, "braco": 14.0, "antebraco": 13.0,
                "esp_braco": 8.0, "cabeca": 8.0},
        "pal": paleta("4a3a28", "2f4224", "cdbb96", "1b2414", metal="2b2118"),
        "cfg": {"ataque": "golpe", "amp": 0.8},
        "extras": _ghorak,
    },
    "morvanna": {
        "plano": "flutuante",
        "par": {"voo": 30.0, "torso": 21.0, "ombros": 16.0, "manto": 26.0,
                "manto_larg": 21.0},
        "pal": paleta("2a2340", "3d5236", "b9a9c9", "1a1526", metal="8f7fae",
                      brilho="9dff6b"),
        "cfg": {"ataque": "magia", "amp": 1.15},
        "extras": _morvanna,
    },
    "rainha_aracnidea": {
        "plano": "aracnideo",
        "par": {"alt": 28.0, "abdomen": 19.0, "cefalo": 12.0, "seg1": 19.0,
                "seg2": 20.0, "esp_pata": 4.5, "cabeca": 7.0},
        "pal": paleta("1d1526", "2c1f38", "e0cbd6", "3a1326", metal="c8b06a"),
        "cfg": {"amp": 1.0},
        "extras": _rainha,
    },
    "entrevane": {
        "plano": "humanoide",
        "par": {"coxa": 13.0, "canela": 12.0, "esp_perna": 12.0, "torso": 40.0,
                "ombros": 24.0, "cintura": 22.0, "braco": 15.0, "antebraco": 14.0,
                "esp_braco": 7.0, "cabeca": 5.0, "pescoco": 1.0},
        "pal": paleta("3f3324", "26361d", "b8a684", "141c0e", metal="5c6b3a"),
        "cfg": {"ataque": "golpe", "amp": 0.6},
        "extras": _entrevane,
    },
    "coracao_putrefacto": {
        "plano": "flutuante",
        "par": {"voo": 30.0, "torso": 24.0, "ombros": 4.0, "cintura": 4.0,
                "manto": 22.0, "manto_larg": 24.0, "braco": 12.0, "antebraco": 11.0},
        "pal": paleta("34281c", "5c1f3a", "cdbb96", "1b1410", metal="6b5f8f"),
        "cfg": {"ataque": "magia", "amp": 0.9},
        "extras": _coracao,
    },
}


# ── geracao ──────────────────────────────────────────────────────────────

def gerar(nome: str, spec: dict) -> tuple[dict, list[Image.Image]]:
    juntas, pecas = CORPOS[spec["plano"]](spec.get("par", {}), spec["pal"])
    extras = spec.get("extras")
    if extras:
        extras(juntas, pecas, spec["pal"])
    esq = Esqueleto(juntas)
    gait = PLANOS[spec["plano"]]
    cfg = spec.get("cfg", {})

    estados: dict[str, list[Image.Image]] = {}
    for estado, n in FRAMES.items():
        imgs: list[Image.Image] = []
        for i in range(n):
            img = desenhar_frame(pecas, esq, gait(estado, i, n, cfg), spec["pal"])
            if estado == "death":
                imgs.append(esbater(img, 1.0 - 0.72 * (i / float(n - 1))))
            else:
                imgs.append(img)
        estados[estado] = imgs

    entrada = exportar(nome, estados, FPS, DEST)
    return entrada, estados["idle"] + estados["attack"][:4]


def desenhar_frame(pecas, esq, pose, pal):
    from chefes_desenho import desenhar
    return desenhar(pecas, esq, pose, pal["contorno"])


def _folha_de_contacto(amostras: dict[str, list[Image.Image]]) -> None:
    """Uma linha por chefe, para se ver tudo de relance sem abrir o jogo."""
    if not amostras:
        return
    # corta o ar a' volta e sobe x2: e' preciso ver os PIXELS para julgar
    # o desenho, nao a silhueta ao longe
    cortadas = {n: [im.crop(im.getbbox()) for im in ims] for n, ims in amostras.items()}
    cel_w = max(im.width for ims in cortadas.values() for im in ims) + 6
    cel_h = max(im.height for ims in cortadas.values() for im in ims) + 6
    cols = max(len(ims) for ims in cortadas.values())
    folha = Image.new("RGBA", (cel_w * cols * 2, cel_h * len(cortadas) * 2), cor("140d1e"))
    for linha, (_nome, ims) in enumerate(sorted(cortadas.items())):
        for c, im in enumerate(ims):
            g = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
            x = c * cel_w * 2 + (cel_w * 2 - g.width) // 2
            y = linha * cel_h * 2 + (cel_h * 2 - g.height)
            folha.paste(g, (x, y), g)
    cam = os.path.join(DEST, "_preview_chefes_proprios.png")
    folha.save(cam)
    print("  folha de contacto: %s" % os.path.relpath(cam, RAIZ))


def main(argv: list[str]) -> int:
    preview = "--preview" in argv
    pedidos = [a for a in argv if not a.startswith("--")]
    alvos = pedidos or list(CHEFES)

    cam_json = os.path.join(DEST, "rigs.json")
    catalogo: dict = {}
    if os.path.exists(cam_json):
        with open(cam_json, "r", encoding="utf-8") as f:
            catalogo = json.load(f)

    amostras: dict[str, list[Image.Image]] = {}
    for nome in alvos:
        if nome not in CHEFES:
            print("  ! chefe desconhecido: %s" % nome)
            continue
        entrada, amostra = gerar(nome, CHEFES[nome])
        catalogo[nome] = entrada
        amostras[nome] = amostra
        print("  %-22s %dx%d  %s" % (
            nome, entrada["w"], entrada["h"],
            " ".join("%s:%d" % (k, v) for k, v in entrada["estados"].items())))

    with open(cam_json, "w", encoding="utf-8") as f:
        json.dump(catalogo, f, indent=1, ensure_ascii=False)
    print("%d chefes -> %s" % (len(amostras), os.path.relpath(DEST, RAIZ)))

    if preview:
        _folha_de_contacto(amostras)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
