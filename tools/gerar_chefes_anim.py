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


def corrente(pecas: list[Peca], j: str, x: float, y: float, n: int, passo: float,
             c, z: float = 3.8, ang: float = 90.0) -> None:
    """Fio de elos. As correntes sao a assinatura da Regiao II inteira."""
    import math as _m
    dx, dy = _m.cos(_m.radians(ang)) * passo, _m.sin(_m.radians(ang)) * passo
    for k in range(n):
        pecas.append(Peca(j, elipse(x + dx * k, y + dy * k, 2.2, 1.6), c, z))


def asas(pecas: list[Peca], juntas: Juntas, pai: str, x: float, y: float,
         comp: float, esp: float, c, penas: bool = True) -> None:
    """Par de asas num corpo FLUTUANTE. O gait `flutuante` ja' anima as
    juntas `asa_t`/`asa_f` -- por isso e' que nao ha' um plano de corpo so'
    para os chefes alados humanoides."""
    junta(juntas, "asa_t", pai, x - 2.0, y)
    junta(juntas, "asa_f", pai, x + 2.0, y + 1.0)
    for nome, z, tom in (("asa_t", -2.6, escurecer(c, 0.34)), ("asa_f", 3.6, c)):
        if penas:
            for k in range(4):
                f = 1.0 - k * 0.16
                pecas.append(Peca(nome, [(0.0, -2.0 + k * 2.4),
                                         (-comp * f, -esp * 0.5 + k * 3.0),
                                         (-comp * f * 0.9, esp * 0.2 + k * 3.0),
                                         (0.0, 2.0 + k * 2.4)], tom, z + k * 0.01))
        else:
            pecas.append(Peca(nome, [(2.0, -esp * 0.35), (-comp, -esp),
                                     (-comp * 0.9, esp * 0.55), (-comp * 0.45, esp * 0.2),
                                     (2.0, esp * 0.3)], tom, z))


def elmo(pecas: list[Peca], j: str, c, r: float = 8.0, z: float = 2.0,
         c_olho=MAGENTA, crista=None) -> None:
    """Elmo fechado com fresta. O truque de sempre: a cara fica escura e o
    que se le' e' a linha acesa da fresta."""
    pecas.append(Peca(j, [(-r, -r * 1.1), (r, -r * 1.1), (r * 1.05, r * 0.35),
                          (r * 0.55, r * 0.95), (-r * 0.55, r * 0.95),
                          (-r * 1.05, r * 0.35)], c, z))
    pecas.append(Peca(j, caixa(-r * 0.75, -r * 0.35, r * 0.9, -r * 0.02),
                      escurecer(c, 0.8), z + 0.05))
    pecas.append(Peca(j, caixa(-r * 0.55, -r * 0.28, r * 0.7, -r * 0.1),
                      c_olho, z + 0.1, brilho=True))
    if crista is not None:
        pecas.append(Peca(j, [(-r * 0.3, -r * 1.05), (r * 0.3, -r * 1.05),
                              (r * 0.15, -r * 2.1), (-r * 0.15, -r * 1.9)], crista, z - 0.05))


def mitra(pecas: list[Peca], j: str, c, alt: float = 16.0, z: float = 2.5) -> None:
    pecas.append(Peca(j, [(-6.5, 0.0), (6.5, 0.0), (4.0, -alt * 0.6),
                          (0.0, -alt), (-4.0, -alt * 0.6)], c, z))
    pecas.append(Peca(j, caixa(-6.8, -1.5, 6.8, 1.0), clarear(c, 0.22), z + 0.05))


def disco(pecas: list[Peca], j: str, x: float, y: float, r: float, c,
          z: float = -2.0, mordida: bool = False) -> None:
    """Lua / eclipse / astro atras do chefe. Fica em `z` negativo: e' fundo,
    nao adereço."""
    pecas.append(Peca(j, elipse(x, y, r, r, n=28), c, z))
    if mordida:
        pecas.append(Peca(j, elipse(x + r * 0.42, y - r * 0.2, r * 0.82, r * 0.82, n=28),
                          escurecer(c, 0.86), z + 0.05))


def tentaculos(pecas: list[Peca], j: str, c, n: int, raio: float, comp: float,
               a0: float = 40.0, a1: float = 150.0, z: float = -1.0) -> None:
    for k in range(n):
        ang = a0 + (a1 - a0) * k / max(1, n - 1)
        pecas.append(Peca(j, rodar(membro(comp * (0.7 + 0.3 * (k % 2)), 4.5, 1.2), ang),
                          c, z + k * 0.01))


def cutelo(pecas: list[Peca], j: str, cabo, lamina, comp: float = 16.0) -> None:
    pecas.append(Peca(j, membro(7.0, 3.0), cabo, 4.0))
    pecas.append(Peca(j, [(-2.0, 7.0), (9.0, 8.0), (10.0, comp + 7.0),
                          (-3.0, comp + 5.0)], lamina, 4.1))


def lanca(pecas: list[Peca], j: str, cabo, ponta, comp: float = 40.0) -> None:
    pecas.append(Peca(j, membro(comp, 2.6, 2.2), cabo, 4.0))
    pecas.append(Peca(j, [(-3.5, comp - 2.0), (3.5, comp - 2.0), (0.0, comp + 9.0)],
                      ponta, 4.1))


def escudo(pecas: list[Peca], j: str, c, borda, alt: float = 22.0,
           larg: float = 15.0, z: float = -1.6) -> None:
    pecas.append(Peca(j, [(-larg * 0.5, 2.0), (larg * 0.5, 2.0),
                          (larg * 0.5, alt * 0.6), (0.0, alt),
                          (-larg * 0.5, alt * 0.6)], c, z))
    pecas.append(Peca(j, caixa(-larg * 0.14, 3.0, larg * 0.14, alt * 0.8), borda, z + 0.05))


def chapeu_alto(pecas: list[Peca], j: str, c, alt: float = 13.0, z: float = 2.4) -> None:
    pecas.append(Peca(j, caixa(-9.0, -7.0, 9.0, -5.0), c, z))
    pecas.append(Peca(j, caixa(-5.5, -7.0 - alt, 5.5, -6.0), c, z + 0.05))


def cristais(pecas: list[Peca], j: str, c, pontos: list, z: float = 3.6) -> None:
    """Lascas de cristal/gelo espetadas no corpo."""
    for x, y, h, ang in pontos:
        pecas.append(Peca(j, mover(rodar([(-2.6, 0.0), (2.6, 0.0), (0.0, -h)], ang), x, y),
                          c, z, brilho=False))


def engrenagem(pecas: list[Peca], j: str, x: float, y: float, r: float, c,
               dentes: int = 8, z: float = 0.7) -> None:
    pecas.append(Peca(j, elipse(x, y, r, r, n=20), c, z))
    for k in range(dentes):
        ang = 360.0 * k / dentes
        pecas.append(Peca(j, mover(rodar(caixa(-1.6, -r - 2.4, 1.6, -r + 0.5), ang), x, y),
                          c, z))
    pecas.append(Peca(j, elipse(x, y, r * 0.34, r * 0.34), escurecer(c, 0.6), z + 0.05))


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
    junta(juntas, "chapeu", "cabeca", 0.0, -5.0)
    # ombros largos por cima do manto: sem isto ela lia-se como um pau com
    # chapeu -- era a critica justa a' primeira versao
    pecas.append(Peca("corpo", [(-14.0, -20.0), (14.0, -20.0), (11.0, -8.0),
                                (-11.0, -8.0)], manto, 0.4))
    veios(pecas, "cauda1", escurecer(manto, 0.35), -8.0, 2.0, 22.0, n=5, z=-0.45)
    capuz(pecas, "cabeca", manto, r=9.5)
    # cabelo esfarrapado a sair do capuz
    for x, comp in ((-8.0, 16.0), (-6.0, 20.0), (8.0, 13.0)):
        pecas.append(Peca("cabeca", mover(rodar(membro(comp, 3.5, 1.0), 8.0), x, -2.0),
                          escurecer(lodo, 0.3), 2.4))
    # chapeu de bruxa tombado para tras -- a silhueta que a identifica de
    # longe, mesmo em pixel-art pequena
    pecas.append(Peca("chapeu", [(-12.0, 0.0), (12.0, 0.0), (6.0, -4.0),
                                 (-2.0, -11.0), (-12.0, -25.0), (-5.0, -7.0)],
                      escurecer(manto, 0.15), 2.8))
    pecas.append(Peca("chapeu", caixa(-13.0, -2.0, 13.0, 1.5), lodo, 2.85))
    olhos(pecas, "cabeca", 1.5, -6.0, 1.4, cor("9dff6b"), sep=3.2, z=2.9)
    cajado(pecas, "arma", cor("2c2118"), cor("9dff6b"), comp=30.0)
    # pingos de lodo a cair do manto: e' o pantano a acompanha'-la
    for x, y, r in ((-7.0, 6.0, 2.2), (4.0, 10.0, 1.8), (-1.0, 15.0, 1.5)):
        pecas.append(Peca("cauda2", elipse(x, y, r, r * 1.4), lodo, -0.55))
    nucleo(pecas, "corpo", 1.0, -14.0, 2.8, cor("9dff6b"))


def _rainha(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "aranha colossal com ROSTO HUMANO. Cospe teias; solta ovos"
    quitina, veludo = pal["corpo"], pal["corpo2"]
    # o rosto humano da base FICA -- e' o lore todo ("aranha colossal com
    # rosto humano"); o cabelo e' que vai por baixo dele
    pecas.append(Peca("cabeca", [(-8.0, -6.0), (7.0, -8.0), (9.0, 4.0),
                                 (-2.0, 14.0), (-10.0, 7.0)], pal["detalhe"], 0.9))
    # patas da frente num tom mais claro, senao coladas ao abdomen so' se
    # veem riscos escuros por cima de uma bola escura
    pintar(pecas, ("pf1", "pf2", "pf3"), clarear(veludo, 0.22))
    coroa(pecas, "cabeca", pal["metal"], r=6.0, z=1.4)
    olhos(pecas, "cabeca", 0.5, -3.0, 1.2, cor("ff2d6f"), sep=2.6, z=1.35)
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


# ── Regiao II -- Prisao dos Condenados ───────────────────────────────────

def _carcereiro(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "gigante com uma CHAVE no lugar da cabeca. Correntes como chicotes"
    ferro, couro = pal["metal"], pal["corpo"]
    tirar(pecas, "cabeca", "pescoco")
    # a chave: anel, haste e dentes. Nao ha' cara nenhuma -- e' isso que
    # faz dele o Carcereiro SEM ROSTO.
    #
    # A primeira versao lia-se como uma ANTENA: o anel era pequeno, a haste
    # fina e os dentes ficavam escondidos por tras do peitoral. A chave e'
    # a identidade dele, portanto e' GRANDE (tao larga como os ombros),
    # desce ate' ao peito e os dentes saem de lado, onde se veem.
    pecas.append(Peca("cabeca", elipse(0.0, -17.0, 11.5, 11.5), ferro, 2.0))
    pecas.append(Peca("cabeca", elipse(0.0, -17.0, 6.0, 6.0), pal["detalhe"], 2.05))
    pecas.append(Peca("cabeca", elipse(0.0, -17.0, 3.4, 3.4), MAGENTA, 2.1, brilho=True))
    pecas.append(Peca("cabeca", caixa(-3.4, -8.0, 3.4, 6.0), ferro, 2.15))
    # dentes: dois, de lado e ACIMA da linha do ombro. Mais abaixo passavam
    # por tras do peitoral e a chave voltava a ler-se como uma antena.
    pecas.append(Peca("cabeca", caixa(3.2, -6.5, 13.0, -3.0), ferro, 2.15))
    pecas.append(Peca("cabeca", caixa(3.2, -1.5, 10.5, 2.0), ferro, 2.15))
    # peitoral de placas e argolas de cela
    pecas.append(Peca("torso", trapezio(-24.0, 28.0, -8.0, 22.0), ferro, 0.6))
    for k in range(3):
        pecas.append(Peca("torso", elipse(-8.0 + k * 8.0, -6.0, 3.0, 3.0), ferro, 0.7))
    espinhos_ombro(pecas, "torso", ferro, -25.0, n=4, larg=26.0, alt=6.0, z=0.8)
    veios(pecas, "anca", escurecer(couro, 0.4), -6.0, 0.0, 10.0, n=3)
    # correntes penduradas dos pulsos: sao os chicotes dele
    corrente(pecas, "cotovelo_t", 0.0, 12.0, 6, 4.0, escurecer(ferro, 0.3), z=-1.6)
    corrente(pecas, "cotovelo_f", 0.0, 12.0, 7, 4.0, ferro, z=3.7)
    nucleo(pecas, "torso", 0.0, -16.0, 2.8)


def _ignivar(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "ferreiro maldito: forja armas durante a luta; martelo cria ondas"
    ferro, brasa = pal["metal"], cor("ff7a2d")
    tirar(pecas, "cabeca", "pescoco")
    # avental de couro do ferreiro, a peca que o identifica
    pecas.append(Peca("torso", [(-11.0, -18.0), (11.0, -18.0), (13.0, 4.0),
                                (-13.0, 4.0)], pal["corpo2"], 0.6))
    veios(pecas, "torso", escurecer(pal["corpo2"], 0.45), -8.0, -14.0, 2.0, n=4, z=0.65)
    # cabeca: elmo de forja com a viseira acesa a laranja. SEM chifres e
    # com a chama atras da cabeca em vez de nos ombros -- com as duas
    # coisas o elmo lia-se como uma cara de raposa, orelhas e tudo.
    elmo(pecas, "cabeca", ferro, r=8.0, c_olho=brasa)
    for x, y, alt in ((-6.0, -7.0, 7.0), (0.0, -9.0, 5.5), (6.5, -6.5, 6.5)):
        chama(pecas, "cabeca", x, y, alt, brasa, z=1.7)
    # as pauliteiras dos ombros sao de ferro macico: e' um ferreiro
    for j, z in (("ombro_t", -1.3), ("ombro_f", 3.5)):
        pecas.append(Peca(j, elipse(0.0, 0.0, 8.5, 7.0), ferro, z))
        pecas.append(Peca(j, caixa(-6.0, -1.5, 6.0, 1.5), escurecer(ferro, 0.3), z + 0.05))
    martelo(pecas, "arma", cor("3a2a1c"), ferro, comp=24.0)
    # rachas incandescentes na pele, como metal ao rubro
    for x, y in ((-6.0, -10.0), (4.0, -14.0), (-2.0, -4.0)):
        pecas.append(Peca("torso", elipse(x, y, 2.2, 1.2), brasa, 0.9, brilho=True))
    nucleo(pecas, "torso", 1.0, -22.0, 2.6, brasa)


def _dama_guilhotina(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "executora fantasma. Teleporta-se; lanca laminas"
    pano, aco = pal["corpo"], pal["metal"]
    tirar(pecas, "cabeca", "pescoco")
    capuz(pecas, "cabeca", escurecer(pano, 0.2), r=8.5)
    olhos(pecas, "cabeca", 1.5, -6.0, 1.2, cor("ff4d4d"), sep=3.0, z=2.9)
    # gola alta e a corda do carrasco ao pescoco
    pecas.append(Peca("corpo", [(-12.0, -20.0), (12.0, -20.0), (8.0, -12.0),
                                (-8.0, -12.0)], escurecer(pano, 0.3), 1.6))
    corrente(pecas, "corpo", 6.0, -14.0, 5, 3.2, cor("6b5a3c"), z=1.7)
    # a lamina da guilhotina: enorme, obliqua, e a assinatura dela
    pecas.append(Peca("arma", membro(10.0, 3.0), cor("2b2118"), 4.0))
    pecas.append(Peca("arma", [(-7.0, 10.0), (16.0, 10.0), (16.0, 30.0),
                               (-7.0, 22.0)], aco, 4.1))
    pecas.append(Peca("arma", [(-7.0, 22.0), (16.0, 30.0), (16.0, 33.0),
                               (-7.0, 25.0)], clarear(aco, 0.35), 4.15))
    nucleo(pecas, "corpo", 1.0, -14.0, 2.6, cor("ff4d4d"))


def _irmaos_condenados(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "dois fantasmas ligados por CORRENTE (um de perto, outro a' distancia)"
    espectro = pal["corpo"]
    tirar(pecas, "cabeca", "pescoco")
    capuz(pecas, "cabeca", espectro, r=8.0)
    olhos(pecas, "cabeca", 1.5, -5.5, 1.2, MAGENTA, sep=3.0, z=2.9)
    # o SEGUNDO irmao, mais pequeno e atras -- e' o chefe todo numa imagem
    junta(juntas, "irmao", "corpo", -26.0, -6.0)
    pecas.append(Peca("irmao", [(-9.0, -14.0), (9.0, -14.0), (7.0, 16.0),
                                (2.0, 10.0), (-3.0, 18.0), (-8.0, 11.0)],
                      escurecer(espectro, 0.3), -2.4))
    pecas.append(Peca("irmao", elipse(0.0, -17.0, 6.5, 6.8), escurecer(espectro, 0.2), -2.3))
    olhos(pecas, "irmao", 0.0, -18.0, 1.1, MAGENTA, sep=2.6, z=-2.2)
    # a corrente que os prende um ao outro
    corrente(pecas, "corpo", -4.0, -12.0, 6, 3.6, pal["metal"], z=-2.0, ang=182.0)
    nucleo(pecas, "corpo", 1.0, -13.0, 2.6)


def _primeiro_prisioneiro(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "heroi antigo. Espada parecida com a da Koliani; imita ataques dela"
    trapo, pele = pal["corpo"], pal["pele"]
    tirar(pecas, "cabeca")
    # cabeca encovada, cabelo comprido a tapar a cara: foi um heroi, agora
    # e' um homem que ninguem reconhece
    pecas.append(Peca("cabeca", elipse(0.0, -4.0, 6.8, 7.2), pele, 2.0))
    pecas.append(Peca("cabeca", [(-8.0, -10.0), (7.0, -11.0), (8.5, -3.0),
                                 (3.0, -6.5), (-3.0, -5.0), (-9.0, -1.0)],
                      pal["detalhe"], 2.1))
    olhos(pecas, "cabeca", 1.0, -4.0, 1.2, MAGENTA, sep=2.8, z=2.2)
    # trapos de prisioneiro por cima do peito
    pecas.append(Peca("torso", [(-10.0, -20.0), (10.0, -20.0), (8.0, 2.0),
                                (3.0, -4.0), (-2.0, 4.0), (-9.0, -3.0)],
                      escurecer(trapo, 0.25), 0.6))
    # grilhetas nos pulsos, com o resto da corrente partida
    for j, z in (("cotovelo_t", -1.4), ("cotovelo_f", 3.6)):
        pecas.append(Peca(j, caixa(-4.0, 9.0, 4.0, 12.0), pal["metal"], z))
    corrente(pecas, "cotovelo_t", 0.0, 13.0, 3, 3.6, pal["metal"], z=-1.5)
    # a espada dele e' a irma da da Koliani -- lamina recta, brilho roxo
    espada(pecas, "arma", cor("2b2118"), clarear(pal["metal"], 0.3), comp=30.0, larg=4.0)
    nucleo(pecas, "torso", 1.0, -14.0, 2.6)


# ── Regiao III -- Torres Esquecidas ──────────────────────────────────────

def _sino_vivo(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "criatura presa DENTRO DO SINO; ataques por ondas sonoras"
    bronze = pal["corpo"]
    # argola de suspensao no topo -- e' o que diz "sino" e nao "campanula"
    pecas.append(Peca("corpo", elipse(0.0, -6.0, 5.0, 5.0), pal["corpo2"], -0.1))
    pecas.append(Peca("corpo", elipse(0.0, -6.0, 2.6, 2.6), CONTORNO, -0.05))
    # banda de runas a meio do sino
    pecas.append(Peca("corpo", caixa(-15.0, 14.0, 15.0, 19.0), escurecer(bronze, 0.4), 0.5))
    for k in range(4):
        pecas.append(Peca("corpo", caixa(-11.0 + k * 7.0, 15.0, -9.5 + k * 7.0, 18.0),
                          MAGENTA, 0.55, brilho=True))
    # a criatura la' dentro: so' os olhos e as maos agarradas ao rebordo
    olhos(pecas, "cabeca", 0.0, -1.0, 1.4, MAGENTA, sep=3.6, z=0.0)
    for j, z in (("cotovelo_t", -1.4), ("cotovelo_f", 3.5)):
        pecas.append(Peca(j, elipse(0.0, 10.0, 4.0, 3.0), pal["pele"], z))
    # rachas no bronze
    for x, y, h in ((-9.0, 22.0, 8.0), (7.0, 18.0, 10.0)):
        pecas.append(Peca("corpo", [(x, y), (x + 2.0, y + h * 0.4), (x - 1.0, y + h)],
                          escurecer(bronze, 0.55), 0.6))


def _aerion(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "cavaleiro alado: VOA SEMPRE; cria tornados; atira lancas"
    aco, penas = pal["metal"], pal.get("asa", pal["corpo2"])
    tirar(pecas, "cabeca", "pescoco")
    asas(pecas, juntas, "corpo", 0.0, -16.0, 30.0, 13.0, penas)
    elmo(pecas, "cabeca", aco, r=8.0, c_olho=cor("bfe9ff"),
         crista=clarear(penas, 0.2))
    # peitoral e capa curta
    pecas.append(Peca("corpo", trapezio(-22.0, 22.0, -4.0, 15.0), aco, 0.6))
    pecas.append(Peca("corpo", [(-13.0, -20.0), (13.0, -20.0), (10.0, -2.0),
                                (-10.0, -2.0)], escurecer(pal["corpo"], 0.15), -0.4))
    lanca(pecas, "arma", cor("3a2f22"), clarear(aco, 0.35), comp=42.0)
    nucleo(pecas, "corpo", 1.0, -14.0, 2.6, cor("bfe9ff"))


def _voltaris(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "mago morto-vivo: teleporta-se; invoca raios; clones electricos"
    raio = cor("9fd8ff")
    tirar(pecas, "cabeca", "pescoco")
    cranio(pecas, "cabeca", pal["pele"], r=6.5, z=2.0, c_olho=raio)
    capuz(pecas, "cabeca", escurecer(pal["corpo"], 0.25), r=10.0, z=1.8)
    # gola em bico e o manto esfarrapado
    pecas.append(Peca("corpo", [(-13.0, -21.0), (13.0, -21.0), (9.0, -10.0),
                                (-9.0, -10.0)], pal["corpo"], 1.6))
    veios(pecas, "cauda1", escurecer(pal["corpo2"], 0.4), -9.0, 2.0, 20.0, n=5, z=-0.45)
    cajado(pecas, "arma", cor("2b2118"), raio, comp=34.0)
    # faiscas a saltar entre os dedos e o cajado
    for x, y in ((-9.0, -18.0), (10.0, -12.0), (-4.0, -26.0)):
        pecas.append(Peca("corpo", [(x, y), (x + 2.5, y + 3.0), (x - 1.0, y + 3.0),
                                    (x + 1.5, y + 7.0)], raio, 1.9, brilho=True))
    nucleo(pecas, "corpo", 1.0, -15.0, 2.4, raio)


def _sacerdotisa_lunar(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "manipula a LUA; cria luas falsas; invoca meteoros purpura"
    luar = cor("dfe6ff")
    tirar(pecas, "cabeca", "pescoco")
    # o disco da lua atras dela: le'-se de longe e e' so' dela
    disco(pecas, "corpo", 0.0, -22.0, 20.0, escurecer(luar, 0.55), z=-3.0, mordida=True)
    # veu comprido e diadema
    pecas.append(Peca("cabeca", elipse(0.0, -4.0, 6.6, 7.0), pal["pele"], 2.0))
    pecas.append(Peca("cabeca", [(-10.0, -8.0), (10.0, -8.0), (8.0, 20.0),
                                 (-8.0, 20.0)], pal["corpo"], 1.7))
    pecas.append(Peca("cabeca", [(-7.0, -9.0), (7.0, -9.0), (0.0, -16.0)], pal["metal"], 2.2))
    olhos(pecas, "cabeca", 0.5, -4.0, 1.1, luar, sep=2.6, z=2.3)
    # luas pequenas a orbitar (as "luas falsas")
    for x, y, r in ((-18.0, -30.0, 3.0), (17.0, -18.0, 2.2), (-14.0, -6.0, 2.0)):
        pecas.append(Peca("corpo", elipse(x, y, r, r), luar, 3.6, brilho=True))
    cajado(pecas, "arma", clarear(pal["metal"], 0.2), luar, comp=32.0)
    nucleo(pecas, "corpo", 1.0, -14.0, 2.4, luar)


def _vyrak(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "Vyrak, o DRAGAO DAS SOMBRAS. F2 destroi a torre e voa"
    escama, sombra = pal["corpo"], pal["corpo2"]
    # crista de espinhos das costas ate' a' cauda
    for k in range(6):
        pecas.append(Peca("corpo", [(-14.0 + k * 6.0, -8.0), (-10.0 + k * 6.0, -8.0),
                                    (-12.0 + k * 6.0, -15.0 + abs(k - 2) * 1.5)],
                          sombra, 0.6))
    # chifres e mandibula
    chifres(pecas, "cabeca", sombra, alt=12.0, aber=4.0, z=1.2)
    pecas.append(Peca("cabeca", [(4.0, 2.0), (16.0, 3.0), (15.0, 6.5), (4.0, 6.0)],
                      escama, 1.15))
    for k in range(3):
        pecas.append(Peca("cabeca", [(6.0 + k * 3.5, 2.0), (8.0 + k * 3.5, 2.0),
                                     (7.0 + k * 3.5, 6.0)], pal["pele"], 1.2))
    pecas.append(Peca("cabeca", elipse(6.0, -1.0, 1.6, 1.1), MAGENTA, 1.3, brilho=True))
    # garras
    for j, z in (("perna_t", -1.9), ("perna_f", 2.1)):
        for ang in (-14.0, 0.0, 14.0):
            pecas.append(Peca(j, mover(rodar(membro(7.0, 2.6, 1.0), ang), 0.0, 14.0),
                              pal["pele"], z))
    nucleo(pecas, "corpo", -4.0, 0.0, 3.0)


# -- Regiao IV -- Catacumbas do Abismo ------------------------------------

def _rei_ossario(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "rei morto-vivo num CAVALO ESQUELETICO"
    osso, panos = escurecer(pal["pele"], 0.34), pal["corpo2"]
    # o cavalo e' um esqueleto: costelas a' mostra e cranio comprido
    for k in range(5):
        x = -14.0 + k * 7.0
        pecas.append(Peca("corpo", caixa(x, -7.0, x + 2.6, 7.0), osso, 0.3))
    pecas.append(Peca("cabeca", [(-2.0, -4.0), (20.0, -3.0), (21.0, 3.0),
                                 (-2.0, 4.5)], osso, 0.6))
    pecas.append(Peca("cabeca", elipse(2.0, -1.0, 2.0, 1.6), CONTORNO, 0.7))
    pecas.append(Peca("cabeca", elipse(3.0, -1.0, 1.2, 1.0), MAGENTA, 0.75, brilho=True))
    # o rei: cranio coroado e manto por cima da garupa
    # o manto acaba a' altura da sela: a versao anterior descia 16 px pela
    # garupa abaixo e tapava as costelas do cavalo, que sao metade do lore
    pecas.append(Peca("cavaleiro", [(-15.0, -14.0), (9.0, -14.0), (12.0, 4.0),
                                    (-18.0, 4.0)], panos, 1.9))
    veios(pecas, "cavaleiro", escurecer(panos, 0.4), -11.0, -8.0, 2.0, n=4, z=1.95)
    cranio(pecas, "cab_cav", osso, r=6.5, z=2.3, c_olho=MAGENTA)
    coroa(pecas, "cab_cav", pal["metal"], r=6.5, z=2.5)
    espada(pecas, "braco_c", cor("2b2118"), clarear(pal["metal"], 0.25), comp=30.0, larg=4.5)
    nucleo(pecas, "cavaleiro", -3.0, -2.0, 2.6)


def _colosso_osseo(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "gigante de CENTENAS DE ESQUELETOS; ao perder partes, faz armas novas"
    osso = escurecer(pal["pele"], 0.34)
    tirar(pecas, "cabeca", "pescoco")
    pintar(pecas, ("antebraco_t", "antebraco_f"), osso)
    # caveiras encaixadas no tronco -- e' isso que diz "centenas", nao uma
    for x, y, r in ((-7.0, -16.0, 4.2), (6.0, -12.0, 3.6), (-2.0, -5.0, 3.8),
                    (9.0, -20.0, 3.0), (-10.0, -6.0, 3.0)):
        pecas.append(Peca("torso", elipse(x, y, r, r * 1.05), osso, 0.7))
        pecas.append(Peca("torso", elipse(x - r * 0.35, y - r * 0.1, r * 0.28, r * 0.24),
                          CONTORNO, 0.75))
        pecas.append(Peca("torso", elipse(x + r * 0.35, y - r * 0.1, r * 0.28, r * 0.24),
                          CONTORNO, 0.75))
    espinhos_ombro(pecas, "torso", osso, -24.0, n=5, larg=24.0, alt=8.0, z=0.9)
    cranio(pecas, "cabeca", osso, r=9.0, z=2.0, c_olho=MAGENTA)
    chifres(pecas, "cabeca", osso, alt=10.0, aber=8.0, z=1.9)
    nucleo(pecas, "torso", 0.0, -13.0, 3.0)


def _freira_negra(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "APAGA AS VELAS; manter certas chamas acesas durante a luta"
    pano, cera = pal["corpo"], cor("e8dfc4")
    tirar(pecas, "cabeca", "pescoco")
    capuz(pecas, "cabeca", pano, r=9.5, z=2.0)
    # a touca vai POR CIMA do capuz: por baixo ficava tapada e ela era so'
    # um vulto preto. E' a unica coisa clara nela -- e e' o que a faz
    # freira e nao feiticeira.
    pecas.append(Peca("cabeca", caixa(-9.5, -9.5, 9.5, -6.0), cera, 2.75))
    pecas.append(Peca("cabeca", caixa(-9.5, -9.0, -5.5, 4.0), cera, 2.75))
    pecas.append(Peca("cabeca", caixa(5.5, -9.0, 9.5, 4.0), cera, 2.75))
    olhos(pecas, "cabeca", 1.0, -4.0, 1.2, MAGENTA, sep=3.0, z=2.9)
    # a cruz ao peito, virada ao contrario
    pecas.append(Peca("corpo", caixa(-1.6, -18.0, 1.6, -4.0), pal["metal"], 1.5))
    pecas.append(Peca("corpo", caixa(-5.5, -10.0, 5.5, -7.0), pal["metal"], 1.5))
    # as velas: tres a flutuar a' volta dela, uma ja' apagada -- e' a
    # ameaca dela numa imagem so'
    for x, y, aceso in ((-20.0, -26.0, True), (19.0, -18.0, True), (-16.0, -6.0, False)):
        pecas.append(Peca("corpo", caixa(x - 1.8, y, x + 1.8, y + 9.0), cera, 3.4))
        if aceso:
            chama(pecas, "corpo", x, y, 6.0, cor("ffd27a"), z=3.5)
        else:
            pecas.append(Peca("corpo", caixa(x - 0.8, y - 2.5, x + 0.8, y), CONTORNO, 3.5))
    nucleo(pecas, "corpo", 1.0, -13.0, 2.4, cor("ffd27a"))


def _naga_zeraph(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "invoca cobras; VENENO; troca de posicao com estatuas"
    escama, veneno = pal["corpo"], cor("9dff6b")
    tirar(pecas, "cabeca")
    # capuz de naja aberto atras da cabeca: le'-se de longe e e' so' dela
    pecas.append(Peca("cabeca", [(-15.0, 2.0), (-11.0, -12.0), (0.0, -17.0),
                                 (11.0, -12.0), (15.0, 2.0), (0.0, 6.0)],
                      pal["corpo2"], 1.6))
    pecas.append(Peca("cabeca", elipse(0.0, -4.0, 6.5, 7.0), escama, 2.0))
    olhos(pecas, "cabeca", 1.0, -5.0, 1.3, veneno, sep=3.2, z=2.2)
    # a lingua bifida, sempre de fora
    pecas.append(Peca("cabeca", [(5.0, -1.0), (13.0, 0.0), (10.0, 1.2),
                                 (13.0, 2.6), (5.0, 1.6)], cor("ff5f8a"), 2.15))
    # peito de escamas CLARAS: a versao anterior era verde sobre verde e a
    # metade de cima dela desaparecia contra os aneis
    pintar(pecas, "torso", clarear(escama, 0.22))
    for k in range(4):
        y = -18.0 + k * 5.0
        pecas.append(Peca("torso", caixa(-6.0, y, 6.0, y + 3.2),
                          escurecer(escama, 0.3), 0.62))
    # cobras pequenas enroladas nos antebracos
    for j, z in (("cotovelo_t", -1.4), ("cotovelo_f", 3.6)):
        corrente(pecas, j, 0.0, 4.0, 4, 3.4, pal["corpo2"], z=z + 0.05)
    cajado(pecas, "arma", cor("2b2118"), veneno, comp=34.0)
    nucleo(pecas, "torso", 1.0, -13.0, 2.6, veneno)


def _olho_do_abismo(juntas: Juntas, pecas: list[Peca], pal: dict) -> None:
    # "OLHO FLUTUANTE SEM CORPO. Lasers; plataformas falsas; clones"
    carne, iris = pal["corpo"], MAGENTA
    # sem corpo nenhum: fica so' a esfera. E' literalmente o lore.
    tirar(pecas, "torso", "manto", "ponta", "pescoco", "cabeca",
          "braco_t", "antebraco_t", "braco_f", "antebraco_f")
    tentaculos(pecas, "corpo", escurecer(carne, 0.3), 7, 16.0, 26.0,
               a0=30.0, a1=150.0, z=-1.0)
    pecas.append(Peca("corpo", elipse(0.0, -14.0, 20.0, 20.0), carne, 0.0))
    pecas.append(Peca("corpo", elipse(2.0, -14.0, 11.0, 11.0), pal["pele"], 0.3))
    pecas.append(Peca("corpo", elipse(4.0, -14.0, 6.5, 6.5), iris, 0.4, brilho=True))
    pecas.append(Peca("corpo", elipse(5.0, -14.0, 2.8, 2.8), CONTORNO, 0.5))
    # veias por cima da esclerotica -- sem elas e' uma bola, nao um olho
    for x, y in ((-13.0, -22.0), (-15.0, -10.0), (-8.0, -27.0), (-10.0, -3.0)):
        pecas.append(Peca("corpo", [(x, y), (x + 6.0, y + 1.5), (x + 3.0, y + 3.0),
                                    (x + 8.0, y + 4.0)], escurecer(carne, 0.45), 0.2))



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
        "par": {"alt": 44.0, "abdomen": 18.0, "cefalo": 12.0, "seg1": 24.0,
                "seg2": 32.0, "esp_pata": 5.0, "cabeca": 7.5},
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

    # ── Regiao II -- Prisao dos Condenados ───────────────────────────────
    "carcereiro": {
        # gigante: ombros largos, pernas curtas, e a chave por cabeca
        "plano": "humanoide",
        "par": {"coxa": 15.0, "canela": 14.0, "esp_perna": 12.0, "torso": 30.0,
                "ombros": 30.0, "cintura": 18.0, "braco": 16.0, "antebraco": 15.0,
                "esp_braco": 10.0, "cabeca": 8.0, "pescoco": 2.0},
        "pal": paleta("3a2f28", "241d1a", "8f8272", "141010", metal="7d7f8c"),
        "cfg": {"ataque": "golpe", "amp": 0.75},
        "extras": _carcereiro,
    },
    "ignivar": {
        "plano": "humanoide",
        "par": {"coxa": 14.0, "canela": 13.0, "esp_perna": 10.0, "torso": 25.0,
                "ombros": 26.0, "cintura": 16.0, "braco": 14.0, "antebraco": 14.0,
                "esp_braco": 9.0, "cabeca": 7.0, "pescoco": 2.0},
        "pal": paleta("2b2119", "6b3a1e", "b07a52", "17110c", metal="8a8a94",
                      brilho="ff7a2d"),
        "cfg": {"ataque": "golpe", "amp": 0.95},
        "extras": _ignivar,
    },
    "dama_guilhotina": {
        "plano": "flutuante",
        "par": {"voo": 32.0, "torso": 22.0, "ombros": 16.0, "cintura": 10.0,
                "manto": 30.0, "manto_larg": 19.0, "braco": 12.0, "antebraco": 12.0},
        "pal": paleta("241e2c", "39121e", "cfc6d6", "120e18", metal="b9c2cc",
                      brilho="ff4d4d"),
        "cfg": {"ataque": "golpe", "amp": 1.1},
        "extras": _dama_guilhotina,
    },
    "irmaos_condenados": {
        # dois de uma vez: o corpo estreita-se para caber o irmao ao lado
        "plano": "flutuante",
        "par": {"voo": 30.0, "torso": 20.0, "ombros": 14.0, "cintura": 9.0,
                "manto": 24.0, "manto_larg": 16.0, "braco": 11.0, "antebraco": 10.0},
        "pal": paleta("36305a", "241f3d", "b6aee0", "16132a", metal="6d6790"),
        "cfg": {"ataque": "magia", "amp": 1.05},
        "extras": _irmaos_condenados,
    },
    "primeiro_prisioneiro": {
        # a silhueta dela, gasta: mesmas proporcoes, ombros mais caidos
        "plano": "humanoide",
        "par": {"coxa": 15.0, "canela": 15.0, "esp_perna": 8.0, "torso": 23.0,
                "ombros": 19.0, "cintura": 12.0, "braco": 13.0, "antebraco": 12.0,
                "esp_braco": 6.0, "cabeca": 7.0, "pescoco": 3.0},
        # tons claros de proposito: a versao escura lia-se como uma
        # mancha preta e ele TEM de se ler como um heroi gasto
        "pal": paleta("7a6f5c", "50493c", "cdae90", "3a3226", metal="b9b2d6"),
        "cfg": {"ataque": "golpe", "amp": 1.0},
        "extras": _primeiro_prisioneiro,
    },

    # ── Regiao III -- Torres Esquecidas ──────────────────────────────────
    "sino_vivo": {
        "plano": "objeto",
        "par": {"alt": 20.0, "sino_a": 38.0, "sino_l": 36.0, "braco": 12.0,
                "esp_braco": 5.0, "cabeca": 6.5},
        "pal": paleta("8a6a2c", "b08a3c", "c9bfae", "20180c", metal="6f5722"),
        "cfg": {"amp": 1.2},
        "extras": _sino_vivo,
    },
    "aerion": {
        # VOA SEMPRE -- por isso flutuante e nao humanoide; as asas sao dele
        "plano": "flutuante",
        "par": {"voo": 36.0, "torso": 23.0, "ombros": 19.0, "cintura": 12.0,
                "manto": 18.0, "manto_larg": 17.0, "braco": 13.0, "antebraco": 12.0},
        "pal": paleta("22304a", "5d7ea8", "cdd8e6", "121a2a", metal="9fb2c8",
                      brilho="bfe9ff", asa="d8e6f2"),
        "cfg": {"ataque": "golpe", "amp": 1.15},
        "extras": _aerion,
    },
    "voltaris": {
        "plano": "flutuante",
        "par": {"voo": 32.0, "torso": 21.0, "ombros": 16.0, "cintura": 10.0,
                "manto": 30.0, "manto_larg": 21.0, "braco": 12.0, "antebraco": 11.0},
        "pal": paleta("1e2a3e", "2c4a63", "d8d2c0", "101823", metal="7f93a8",
                      brilho="9fd8ff"),
        "cfg": {"ataque": "magia", "amp": 1.2},
        "extras": _voltaris,
    },
    "sacerdotisa_lunar": {
        "plano": "flutuante",
        "par": {"voo": 34.0, "torso": 21.0, "ombros": 15.0, "cintura": 10.0,
                "manto": 32.0, "manto_larg": 20.0, "braco": 12.0, "antebraco": 11.0},
        "pal": paleta("2b2648", "3a3468", "e8dcc8", "161335", metal="c9c2e8",
                      brilho="dfe6ff"),
        "cfg": {"ataque": "magia", "amp": 1.0},
        "extras": _sacerdotisa_lunar,
    },
    "vyrak": {
        # dragao: o plano alado da-lhe pescoco, cauda e asas de membrana
        "plano": "alado",
        "par": {"voo": 30.0, "corpo_c": 40.0, "corpo_a": 19.0, "pescoco": 16.0,
                "cabeca": 8.5, "asa1": 30.0, "asa2": 26.0, "asa_esp": 18.0,
                "cauda": 22.0, "perna": 15.0},
        "pal": paleta("1a1626", "2e2444", "d8d0e6", "0d0a16", metal="5a4f78",
                      asa="241d38"),
        "cfg": {"amp": 1.1},
        "extras": _vyrak,
    },

    # -- Regiao IV -- Catacumbas do Abismo --------------------------------
    "rei_ossario": {
        "plano": "quadrupede",
        "par": {"alt": 26.0, "corpo_c": 44.0, "corpo_a": 15.0, "pescoco": 15.0,
                "cabeca": 6.0, "seg1": 15.0, "seg2": 15.0, "esp_pata": 5.0,
                "tronco": 22.0, "braco": 13.0, "cab_c": 6.5},
        "pal": paleta("3b3a44", "3a1f2e", "e6dcc4", "16151c", metal="c8ac52",
                      cavaleiro="2a2436"),
        "cfg": {"amp": 0.9},
        "extras": _rei_ossario,
    },
    "colosso_osseo": {
        # gigante: tudo o que e' de cima e' largo, tudo o que e' de baixo e' curto
        "plano": "humanoide",
        "par": {"coxa": 14.0, "canela": 13.0, "esp_perna": 13.0, "torso": 32.0,
                "ombros": 32.0, "cintura": 17.0, "braco": 17.0, "antebraco": 16.0,
                "esp_braco": 11.0, "cabeca": 9.0, "pescoco": 1.0},
        "pal": paleta("504a3e", "36322a", "e6dcc4", "17150f", metal="8a8272"),
        "cfg": {"ataque": "golpe", "amp": 0.7},
        "extras": _colosso_osseo,
    },
    "freira_negra": {
        "plano": "flutuante",
        "par": {"voo": 30.0, "torso": 22.0, "ombros": 16.0, "cintura": 10.0,
                "manto": 30.0, "manto_larg": 20.0, "braco": 12.0, "antebraco": 11.0},
        "pal": paleta("1a1720", "24202c", "cfc4b0", "0e0c12", metal="b8ac7a",
                      brilho="ffd27a"),
        "cfg": {"ataque": "magia", "amp": 1.0},
        "extras": _freira_negra,
    },
    "naga_zeraph": {
        "plano": "serpente",
        # aneis mais curtos: a 20 a cauda media 324 px e o jogo normaliza o
        # chefe pela LARGURA -- ficava com a cabeca do tamanho de um bicho
        "par": {"anel": 14.0, "esp_anel": 15.0, "torso": 26.0, "ombros": 18.0,
                "braco": 13.0, "antebraco": 12.0, "esp_braco": 6.0, "cabeca": 7.5},
        "pal": paleta("1f3a2c", "2f5c3e", "cfe0c4", "0e1a14", metal="b8a45a",
                      brilho="9dff6b"),
        "cfg": {"ataque": "magia", "amp": 1.05},
        "extras": _naga_zeraph,
    },
    "olho_do_abismo": {
        "plano": "flutuante",
        "par": {"voo": 40.0, "torso": 10.0, "manto": 4.0, "manto_larg": 4.0},
        "pal": paleta("6a2038", "3a1224", "f2e8ea", "1a0a12", metal="8a5a6a"),
        "cfg": {"ataque": "magia", "amp": 1.3},
        "extras": _olho_do_abismo,
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
