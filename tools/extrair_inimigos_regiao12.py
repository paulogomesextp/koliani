#!/usr/bin/env python3
"""Recorta o bestiario da Regiao XII (Terras Envenenadas) DA PRANCHA APROVADA.

    python3 tools/extrair_inimigos_regiao04.py [--preview]

`region_12/master_production_board.png` traz, por criatura, um sprite grande e
limpo (o "retrato") e uma linha de poses pequenas -- nao a linha de cinco
estados que a da Regiao III tem. Por isso aqui TODOS os estados saem do
retrato, que e' a melhor arte da prancha, e o movimento vem da animacao
procedural do `DemonioBase` (balanco de idle/andar, recuo, antecipacao):

  idle  2 quadros: o retrato e uma copia 1 px mais baixa (respira)
  run   2 quadros: o retrato inclinado para cada lado
  hit   1 quadro : o retrato esbranquicado (o pisca final e' do shader)
  dead  1 quadro : o retrato tombado e apagado em brasa
  attack 1 quadro: o retrato inclinado em frente, com brilho

Mesmo algoritmo de recorte da Regiao III (`extrair_inimigos_regiao03.py`):
distancia ao fundo -> alfa -> limpar manchas.
"""

from __future__ import annotations

import os
import sys

from PIL import Image, ImageEnhance

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import extrair_inimigos_regiao03 as r3  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRANCHA = os.path.join(RAIZ, "docs/art_direction/regions/region_12",
                       "master_production_board.png")
DESTINO = os.path.join(RAIZ, "assets/sprites/pixel/enemies")

r3.FUNDO = (11, 16, 14)
r3.ALFA_ZERO = 16
r3.ALFA_CHEIO = 48
r3.LIMIAR_CORTE = 40
r3.AREA_MIN = 14

# especie -> (caixa do retrato x0, y0, x1, y1, altura alvo em px)
CRIATURAS = {
    "rato_pestilento":        ((731, 572, 797, 619), 34),
    "espreitador_fungico":    ((808, 558, 882, 622), 56),
    "besteiro_corrompido":    ((900, 560, 972, 626), 60),
    "leproso_das_ruinas":     ((985, 560, 1067, 624), 60),
    "mosca_acida":            ((731, 686, 797, 744), 42),
    "carcaca_envenenada":     ((808, 678, 890, 772), 76),
    "xama_da_praga":          ((903, 686, 975, 772), 68),
    "guardiao_toxico":        ((988, 680, 1066, 776), 82),
}
VOAM = {"mosca_acida"}


def retrato(px, caixa, alvo):
    x0, y0, x1, y1 = caixa
    q = r3.recortar(px, x0, x1, y0, y1)
    q = r3.limpar_manchas(q)
    e = alvo / float(q.height)
    return q.resize((max(1, round(q.width * e)), alvo), Image.LANCZOS)


def clarear(q, f):
    a = q.getchannel("A")
    rgb = ImageEnhance.Brightness(q.convert("RGB")).enhance(f)
    out = rgb.convert("RGBA")
    out.putalpha(a)
    return out


def inclinar(q, graus, larg, alt):
    """Roda o retrato sobre o pe' e cola-o no quadro (larg x alt)."""
    quadro = Image.new("RGBA", (larg, alt), (0, 0, 0, 0))
    big = Image.new("RGBA", (larg * 2, alt * 2), (0, 0, 0, 0))
    big.paste(q, ((big.width - q.width) // 2, big.height - q.height - 4), q)
    # pivo no pe' (centro-baixo)
    big = big.rotate(graus, resample=Image.BICUBIC,
                     center=(big.width // 2, big.height - 4))
    bb = big.getbbox()
    if bb:
        big = big.crop(bb)
    quadro.paste(big, ((larg - big.width) // 2, alt - big.height), big)
    return quadro


def tombado(q, larg, alt):
    a = q.transpose(Image.Transpose.ROTATE_90)
    a = clarear(a, 0.55)
    quadro = Image.new("RGBA", (larg, alt), (0, 0, 0, 0))
    e = min(1.0, larg / a.width, alt / a.height)
    a = a.resize((max(1, round(a.width * e)), max(1, round(a.height * e))), Image.LANCZOS)
    quadro.paste(a, ((larg - a.width) // 2, alt - a.height), a)
    return quadro


def tira(quadros):
    larg, alt = quadros[0].size
    t = Image.new("RGBA", (larg * len(quadros), alt), (0, 0, 0, 0))
    for i, q in enumerate(quadros):
        t.paste(q, (i * larg, 0), q)
    return t


def pose(q, larg, alt, rot=0.0, sx=1.0, sy=1.0, dx=0, dy=0, shear=0.0, brilho=1.0, alfa=1.0):
    """Quadro (larg x alt) com o retrato achatado/esticado (pivo no pe'),
    inclinado, deslocado e com cisalhamento (balanco do tronco)."""
    w, h = max(1, round(q.width * sx)), max(1, round(q.height * sy))
    r = q.resize((w, h), Image.LANCZOS)
    if shear:
        r = r.transform((w + int(abs(shear) * h) + 2, h), Image.AFFINE,
                        (1, shear, -shear * h if shear > 0 else 0, 0, 1, 0), Image.BICUBIC)
    if brilho != 1.0:
        r = clarear(r, brilho)
    if alfa != 1.0:
        a = r.getchannel("A").point(lambda v: int(v * alfa))
        r.putalpha(a)
    big = Image.new("RGBA", (larg * 2, alt * 2), (0, 0, 0, 0))
    big.paste(r, ((big.width - r.width) // 2, big.height - r.height - 4), r)
    if rot:
        big = big.rotate(rot, resample=Image.BICUBIC, center=(big.width // 2, big.height - 4))
    bb = big.getbbox()
    quadro = Image.new("RGBA", (larg, alt), (0, 0, 0, 0))
    if bb:
        big = big.crop(bb)
        quadro.paste(big, ((larg - big.width) // 2 + dx, alt - big.height + dy), big)
    return quadro


def tiras_animadas(q, larg, alt, voa):
    """Ciclos com mais movimento a partir de um so' retrato."""
    P = lambda **k: pose(q, larg, alt, **k)
    if voa:
        idle = [P(dy=-3), P(dy=-1, sy=1.02), P(dy=2, sy=0.98), P(dy=0, sy=1.02)]
        run = [P(dy=-4, rot=4), P(dy=-1, rot=0, sx=1.04), P(dy=3, rot=-4), P(dy=0, rot=0, sx=0.96),
               P(dy=-3, rot=3), P(dy=1, rot=-2)]
        ataque = [P(dx=-4, rot=8, sx=0.95), P(dx=-2, rot=12, brilho=1.15),
                  P(dx=8, rot=-14, sx=1.1, brilho=1.45), P(dx=3, rot=-4)]
    else:
        idle = [P(), P(sy=1.025, sx=0.99, dy=-1), P(sy=1.04, sx=0.98, dy=-1, shear=0.02), P(sy=1.02, dy=0)]
        run = [P(rot=4, dy=-2, sy=1.03), P(rot=1, dy=0, sy=0.97, sx=1.03), P(rot=-3, dy=-3, sy=1.04),
               P(rot=-4, dy=-2, sy=1.03), P(rot=-1, dy=0, sy=0.97, sx=1.03), P(rot=3, dy=-3, sy=1.04)]
        ataque = [P(rot=6, sy=0.93, sx=1.06, dx=-3, brilho=1.1),     # antecipacao: recua e acacha
                  P(rot=10, sy=0.9, sx=1.08, dx=-5, brilho=1.2),
                  P(rot=-14, sy=1.05, sx=1.1, dx=9, brilho=1.5),     # golpe: lanca-se em frente
                  P(rot=-5, dx=3, sy=0.98)]                          # recupera
    hit = [P(rot=-9, dx=-4, sx=0.94, brilho=1.9), P(rot=5, dx=-2, brilho=1.3)]
    morte = [P(rot=-8, dx=-3, brilho=1.7), P(rot=-26, dx=-6, sy=0.9, brilho=1.2),
             P(rot=-58, dx=-8, sy=0.85, brilho=0.8), tombado(q, larg, alt),
             pose(tombado(q, larg, alt), larg, alt, alfa=0.55, brilho=0.6)]
    return idle, run, ataque, hit, morte


def main() -> int:
    px = Image.open(PRANCHA).convert("RGB").load()
    folha = []
    for especie, (caixa, alvo) in CRIATURAS.items():
        q = retrato(px, caixa, alvo)
        larg = int(q.width * 1.4) + 6
        alt = int(q.height * 1.15) + 8
        idle, run, ataque, hit, morte = tiras_animadas(q, larg, alt, especie in VOAM)
        pasta = os.path.join(DESTINO, especie)
        os.makedirs(pasta, exist_ok=True)
        tira(idle).save(os.path.join(pasta, "idle.png"))
        tira(run).save(os.path.join(pasta, "run.png"))
        tira(ataque).save(os.path.join(pasta, "attack.png"))
        tira(hit).save(os.path.join(pasta, "hit.png"))
        tira(morte).save(os.path.join(pasta, "dead.png"))
        print("  %-24s quadro %dx%d" % (especie, larg, alt))
        folha.append((especie, idle[0], run[2], ataque[2], morte[3]))
    if "--preview" in sys.argv:
        alt = max(f[1].height for f in folha)
        larg = max(f[1].width for f in folha)
        img = Image.new("RGBA", (larg * 4, alt * len(folha)), (30, 22, 28, 255))
        for li, f in enumerate(folha):
            for i, q in enumerate(f[1:]):
                img.paste(q, (i * larg, li * alt + alt - q.height), q)
        cam = os.path.join(RAIZ, "work", "_preview_inimigos_r12.png")
        os.makedirs(os.path.dirname(cam), exist_ok=True)
        img.save(cam)
        print("preview ->", cam)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
