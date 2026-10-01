#!/usr/bin/env python3
"""Recorta o bestiario da Regiao IV (Fornalha) DA PRANCHA APROVADA.

    python3 tools/extrair_inimigos_regiao04.py [--preview]

`region_04/enemy_gameplay_pack.png` traz, por criatura, um sprite grande e
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
PRANCHA = os.path.join(RAIZ, "docs/art_direction/regions/region_04",
                       "enemy_gameplay_pack.png")
DESTINO = os.path.join(RAIZ, "assets/sprites/pixel/enemies")

r3.FUNDO = (1, 8, 12)
r3.ALFA_ZERO = 14
r3.ALFA_CHEIO = 42
r3.LIMIAR_CORTE = 34
r3.AREA_MIN = 14

# especie -> (caixa do retrato x0, y0, x1, y1, altura alvo em px)
CRIATURAS = {
    "trabalhador_corrompido": ((58, 232, 150, 309), 60),
    "arqueiro_da_fornalha":   ((238, 232, 348, 309), 60),
    "operario_blindado":      ((430, 232, 529, 309), 62),
    "lanca_chamas":           ((610, 232, 756, 309), 60),
    "automato_de_fundicao":   ((810, 232, 915, 309), 64),
    "drone_de_lava":          ((998, 240, 1106, 305), 44),
    "sentinela_de_pressao":   ((1210, 230, 1262, 307), 64),
    "coloso_de_metal":        ((1353, 230, 1507, 353), 96),
}
VOAM = {"drone_de_lava"}


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


def main() -> int:
    px = Image.open(PRANCHA).convert("RGB").load()
    folha = []
    for especie, (caixa, alvo) in CRIATURAS.items():
        q = retrato(px, caixa, alvo)
        larg = int(q.width * 1.25) + 4
        alt = q.height + 6
        base = Image.new("RGBA", (larg, alt), (0, 0, 0, 0))
        base.paste(q, ((larg - q.width) // 2, alt - q.height), q)
        respira = Image.new("RGBA", (larg, alt), (0, 0, 0, 0))
        respira.paste(q, ((larg - q.width) // 2, alt - q.height + 1), q)
        if especie in VOAM:
            idle = [base, respira]
            run = [base, respira]
        else:
            idle = [base, respira]
            run = [inclinar(q, 3, larg, alt), inclinar(q, -3, larg, alt)]
        ataque = inclinar(clarear(q, 1.25), -7, larg, alt)
        pasta = os.path.join(DESTINO, especie)
        os.makedirs(pasta, exist_ok=True)
        tira(idle).save(os.path.join(pasta, "idle.png"))
        tira(run).save(os.path.join(pasta, "run.png"))
        ataque.save(os.path.join(pasta, "attack.png"))
        clarear(base, 1.9).save(os.path.join(pasta, "hit.png"))
        tombado(q, larg, alt).save(os.path.join(pasta, "dead.png"))
        print("  %-24s quadro %dx%d" % (especie, larg, alt))
        folha.append((especie, idle[0], run[0], ataque, tombado(q, larg, alt)))
    if "--preview" in sys.argv:
        alt = max(f[1].height for f in folha)
        larg = max(f[1].width for f in folha)
        img = Image.new("RGBA", (larg * 4, alt * len(folha)), (30, 22, 28, 255))
        for li, f in enumerate(folha):
            for i, q in enumerate(f[1:]):
                img.paste(q, (i * larg, li * alt + alt - q.height), q)
        cam = os.path.join(RAIZ, "work", "_preview_inimigos_r4.png")
        os.makedirs(os.path.dirname(cam), exist_ok=True)
        img.save(cam)
        print("preview ->", cam)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
