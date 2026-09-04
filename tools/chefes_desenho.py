#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Motor de desenho + animacao dos CHEFES em pixel-art proprio.

Porque e' que isto existe: ate' 4 set 2026 todos os chefes animados do jogo
vestiam sprites de packs emprestados (`tools/importar_chefes_animados.py`).
Funciona, mas nao traduz o lore -- o Ghorak, que e' um guardiao de tronco e
raizes com nucleo roxo no peito, andava com o corpo de um minotauro; o Sino
Vivo era um bau-mimico. O Paulo pediu arte PROPRIA, fiel ao lore, um chefe
por nivel.

Desenhar 30 chefes x 5 animacoes a' mao seria pixel a pixel para sempre.
Por isso isto e' um pequeno sistema de ESQUELETO:

  - um chefe = paleta + arvore de JUNTAS + lista de PECAS (poligonos em
    coordenadas locais da junta a que estao presas);
  - uma animacao = uma POSE por frame, ou seja `junta -> (dx, dy, rotacao)`;
  - o "andar" (gait) de cada plano de corpo -- humanoide, flutuante,
    aracnideo, serpente, alado, quadrupede, objeto -- e' uma funcao que
    devolve essa pose. Ver `tools/chefes_gaits.py`.

Tudo o que se desenha e' POLIGONO (ate' as elipses, que sao poligonos de N
lados). E' de proposito: um poligono roda de graca e o preenchimento do PIL
nao tem antialiasing, portanto sai pixel-art limpo. Desenha-se pequeno
(corpo com ~56 px de altura) e sobe-se x2 em NEAREST -- e' o que faz os
pixels grandes e assumidos, em vez de um desenho vectorial encolhido.

Depois do desenho passam-se tres filtros, os mesmos que o
`tools/gerar_sprites.gd` faz a' mao: CONTORNO de 1 px, LUZ DE TOPO (a
aresta virada para cima aclara, a virada para baixo escurece) e o brilho
dos nucleos magenta, que nao levam contorno nenhum.

Saida: o mesmo contrato que os rigs de pack -- uma tira horizontal por
estado em `assets/sprites/pixel/bosses_anim/<rig>/<estado>.png`, mais a
entrada no `rigs.json` que o `scripts/chefe_base.gd` le'.
"""

from __future__ import annotations

import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

# ── tela nativa ──────────────────────────────────────────────────────────
# Grande o suficiente para caber o chefe mais largo com os bracos abertos e
# a rotacao da morte. O que sobra e' cortado no fim (caixa comum a todos os
# frames), por isso ar a mais nao custa nada.
NATIVO_W = 200
NATIVO_H = 176
CHAO_Y = 158.0     # onde assentam os pes, em coordenadas nativas
CENTRO_X = 100.0
ESCALA = 2         # NEAREST; corpo de ~56 px -> ~112 px, a altura da casa

Cor = tuple[int, int, int, int]
Ponto = tuple[float, float]


# ── cor ──────────────────────────────────────────────────────────────────

def cor(hexa: str, alfa: int = 255) -> Cor:
    """`"1e1430"` -> `(30, 20, 48, 255)`."""
    h = hexa.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alfa)


def misturar(a: Cor, b: Cor, f: float) -> Cor:
    """`f=0` da' `a`, `f=1` da' `b`."""
    return (
        int(round(a[0] + (b[0] - a[0]) * f)),
        int(round(a[1] + (b[1] - a[1]) * f)),
        int(round(a[2] + (b[2] - a[2]) * f)),
        a[3],
    )


BRANCO: Cor = (255, 255, 255, 255)
PRETO: Cor = (0, 0, 0, 255)


def clarear(c: Cor, f: float = 0.25) -> Cor:
    return misturar(c, BRANCO, f)


def escurecer(c: Cor, f: float = 0.3) -> Cor:
    return misturar(c, PRETO, f)


# ── geometria: tudo vira poligono ────────────────────────────────────────

def elipse(cx: float, cy: float, rx: float, ry: float, n: int = 22) -> list[Ponto]:
    return [
        (cx + rx * math.cos(2.0 * math.pi * i / n),
         cy + ry * math.sin(2.0 * math.pi * i / n))
        for i in range(n)
    ]


def caixa(x0: float, y0: float, x1: float, y1: float) -> list[Ponto]:
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


def trapezio(y0: float, larg0: float, y1: float, larg1: float,
             cx: float = 0.0) -> list[Ponto]:
    """Tronco/perna: larguras diferentes em cima e em baixo, centrado em `cx`."""
    return [
        (cx - larg0 / 2.0, y0), (cx + larg0 / 2.0, y0),
        (cx + larg1 / 2.0, y1), (cx - larg1 / 2.0, y1),
    ]


def membro(comp: float, esp0: float, esp1: float | None = None) -> list[Ponto]:
    """Braco/perna presos a uma junta: crescem para BAIXO (+y) a partir dela."""
    if esp1 is None:
        esp1 = esp0 * 0.8
    return trapezio(0.0, esp0, comp, esp1)


def estrela(cx: float, cy: float, r_out: float, r_in: float,
            pontas: int = 5, fase: float = -90.0) -> list[Ponto]:
    pts: list[Ponto] = []
    for i in range(pontas * 2):
        r = r_out if i % 2 == 0 else r_in
        a = math.radians(fase + 180.0 * i / pontas)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def rodar(pts: list[Ponto], graus: float,
          ox: float = 0.0, oy: float = 0.0) -> list[Ponto]:
    a = math.radians(graus)
    ca, sa = math.cos(a), math.sin(a)
    return [
        (ox + (x - ox) * ca - (y - oy) * sa,
         oy + (x - ox) * sa + (y - oy) * ca)
        for x, y in pts
    ]


def mover(pts: list[Ponto], dx: float, dy: float) -> list[Ponto]:
    return [(x + dx, y + dy) for x, y in pts]


def espelhar_x(pts: list[Ponto], eixo: float = 0.0) -> list[Ponto]:
    return [(2.0 * eixo - x, y) for x, y in pts]


# ── esqueleto ────────────────────────────────────────────────────────────

class Peca:
    """Um poligono preso a uma junta.

    `z` manda na ordem de desenho (maior = mais a' frente). `brilho` marca
    as pecas que sao LUZ -- nucleos, olhos, chamas: nao levam contorno nem
    sombreado, para nao ficarem com um risco preto a' volta.

    A `tag` e' o nome da peca no corpo de base ("cabeca", "antebraco_f",
    "pe_t"...). Serve para um chefe concreto TIRAR ou REPINTAR uma peca que
    o plano generico desenhou -- sem isso, a cabeca humana de base ficava
    por cima do capuz de casca do Ghorak, porque tem `z` maior.
    """

    __slots__ = ("junta", "pts", "cor", "z", "brilho", "tag")

    def __init__(self, junta: str, pts: list[Ponto], c: Cor,
                 z: float = 0.0, brilho: bool = False, tag: str = "") -> None:
        self.junta = junta
        self.pts = pts
        self.cor = c
        self.z = z
        self.brilho = brilho
        self.tag = tag


class Esqueleto:
    """Arvore de juntas. Cada junta e' `(pai, (x, y))` local ao pai."""

    def __init__(self, juntas: dict[str, tuple[str | None, Ponto]]) -> None:
        self.juntas = juntas
        self.ordem = self._ordenar()

    def _ordenar(self) -> list[str]:
        feito: list[str] = []
        vistos: set[str] = set()

        def visitar(nome: str) -> None:
            if nome in vistos:
                return
            pai = self.juntas[nome][0]
            if pai is not None:
                visitar(pai)
            vistos.add(nome)
            feito.append(nome)

        for nome in self.juntas:
            visitar(nome)
        return feito

    def mundo(self, pose: dict[str, tuple[float, float, float]]
              ) -> dict[str, tuple[float, float, float]]:
        """Resolve a arvore: `junta -> (x, y, angulo)` em coordenadas da tela."""
        out: dict[str, tuple[float, float, float]] = {}
        for nome in self.ordem:
            pai, (lx, ly) = self.juntas[nome]
            dx, dy, rot = pose.get(nome, (0.0, 0.0, 0.0))
            if pai is None:
                out[nome] = (lx + dx, ly + dy, rot)
                continue
            px, py, pang = out[pai]
            a = math.radians(pang)
            ox, oy = lx + dx, ly + dy
            out[nome] = (
                px + ox * math.cos(a) - oy * math.sin(a),
                py + ox * math.sin(a) + oy * math.cos(a),
                pang + rot,
            )
        return out


# ── desenho de um frame ──────────────────────────────────────────────────

def desenhar(pecas: list[Peca], esq: Esqueleto,
             pose: dict[str, tuple[float, float, float]],
             cor_contorno: Cor) -> Image.Image:
    """Um frame: resolve o esqueleto, desenha as pecas e passa os filtros."""
    mundo = esq.mundo(pose)
    img = Image.new("RGBA", (NATIVO_W, NATIVO_H), (0, 0, 0, 0))
    luz = Image.new("RGBA", (NATIVO_W, NATIVO_H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    dl = ImageDraw.Draw(luz)

    for p in sorted(pecas, key=lambda q: q.z):
        if p.junta not in mundo:
            continue
        x, y, ang = mundo[p.junta]
        pts = mover(rodar(p.pts, ang), x, y)
        if len(pts) < 3:
            continue
        inteiros = [(round(a), round(b)) for a, b in pts]
        if p.brilho:
            dl.polygon(inteiros, fill=p.cor)
            continue
        # RISCO INTERNO: cada peca leva um contorno de 1 px do seu proprio
        # tom, mais escuro. Sem isto o boneco todo cola-se numa mancha so'
        # -- foi o que estragou a primeira leva de desenhos: bracos, tronco
        # e pernas do mesmo tom nao se distinguiam uns dos outros.
        d.polygon(inteiros, fill=p.cor, outline=escurecer(p.cor, 0.45))

    img = _luz_de_topo(img)
    img = _contornar(img, cor_contorno)
    # o brilho entra DEPOIS do contorno: nucleos e chamas nao levam risco
    img.alpha_composite(luz)
    return img


def _contornar(img: Image.Image, c: Cor) -> Image.Image:
    """Risco de 1 px por fora da silhueta (dilatacao do alfa menos o alfa)."""
    alfa = img.getchannel("A").point(lambda v: 255 if v > 8 else 0)
    dilatado = alfa.filter(ImageFilter.MaxFilter(3))
    anel = ImageChops.subtract(dilatado, alfa)
    fora = Image.new("RGBA", img.size, c)
    base = Image.new("RGBA", img.size, (0, 0, 0, 0))
    base.paste(fora, (0, 0), anel)
    base.alpha_composite(img)
    return base


def _luz_de_topo(img: Image.Image) -> Image.Image:
    """A aresta virada para cima aclara; a virada para baixo escurece.

    E' o truque barato que da' volume a pixel-art sem sombrear a' mao: em
    vez de pintar luz por peca, mede-se onde o alfa comeca (topo) e onde
    acaba (base) e mexe-se so' nessas duas linhas de pixels.
    """
    alfa = img.getchannel("A").point(lambda v: 255 if v > 8 else 0)
    desceu = ImageChops.offset(alfa, 0, 1)
    subiu = ImageChops.offset(alfa, 0, -1)
    topo = ImageChops.subtract(alfa, desceu)     # ha' alfa aqui e nao acima
    base = ImageChops.subtract(alfa, subiu)      # ha' alfa aqui e nao abaixo

    claro = Image.eval(img, lambda v: min(255, int(v * 1.30 + 16)))
    claro.putalpha(img.getchannel("A"))
    escuro = Image.eval(img, lambda v: int(v * 0.62))
    escuro.putalpha(img.getchannel("A"))

    out = img.copy()
    out.paste(escuro, (0, 0), base)
    out.paste(claro, (0, 0), topo)
    return out


def esbater(img: Image.Image, f: float) -> Image.Image:
    """Multiplica o alfa por `f` -- usado no fim da animacao de morte."""
    if f >= 0.999:
        return img
    out = img.copy()
    out.putalpha(out.getchannel("A").point(lambda v: int(v * f)))
    return out


def tingir(img: Image.Image, c: Cor, f: float) -> Image.Image:
    """Puxa o frame todo para uma cor -- o vermelho do dano, o roxo da morte."""
    if f <= 0.001:
        return img
    tinta = Image.new("RGBA", img.size, (c[0], c[1], c[2], 255))
    out = Image.blend(img.convert("RGBA"), tinta, f)
    out.putalpha(img.getchannel("A"))
    return out


# ── exportacao ───────────────────────────────────────────────────────────

def exportar(rig: str, estados: dict[str, list[Image.Image]],
             fps: dict[str, float], dest: str,
             escala: int = ESCALA) -> dict:
    """Grava as tiras e devolve a entrada do `rigs.json`.

    Todos os frames de todos os estados sao cortados pela MESMA caixa (a
    uniao das caixas de cada um). Sem isto o chefe saltitava ao mudar de
    animacao -- foi a licao que o importador dos packs ja' tinha aprendido.
    """
    caixa: tuple[int, int, int, int] | None = None
    for imgs in estados.values():
        for im in imgs:
            b = im.getbbox()
            if b is None:
                continue
            caixa = b if caixa is None else (
                min(caixa[0], b[0]), min(caixa[1], b[1]),
                max(caixa[2], b[2]), max(caixa[3], b[3]))
    if caixa is None:
        raise ValueError("rig '%s' saiu em branco" % rig)

    x0, y0, x1, y1 = caixa
    x0, y0 = max(0, x0 - 1), max(0, y0 - 1)
    x1, y1 = min(NATIVO_W, x1 + 1), min(NATIVO_H, y1 + 1)
    cw, ch = (x1 - x0) * escala, (y1 - y0) * escala

    pasta = os.path.join(dest, rig)
    os.makedirs(pasta, exist_ok=True)
    contagens: dict[str, int] = {}
    for nome, imgs in estados.items():
        tira = Image.new("RGBA", (cw * len(imgs), ch), (0, 0, 0, 0))
        for i, im in enumerate(imgs):
            cel = im.crop((x0, y0, x1, y1)).resize((cw, ch), Image.NEAREST)
            tira.paste(cel, (i * cw, 0))
        tira.save(os.path.join(pasta, "%s.png" % nome))
        contagens[nome] = len(imgs)

    return {
        "w": cw,
        "h": ch,
        "pes_y": int(round((CHAO_Y - y0) * escala)),
        "estados": contagens,
        "fps": {k: float(v) for k, v in fps.items() if k in contagens},
    }
