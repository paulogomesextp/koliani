#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Transforma os packs de CHEFE em tiras de animacao.

O problema que isto resolve: ate' 3 set 2026 nenhum chefe do jogo animava.
O `tools/extrair_chefes_packs.gd` monta uma folha de QUATRO frames que sao
POSES, nao uma animacao -- 0 normal, 1 pose alternativa, 2 a piscar, 3
nucleo a' mostra -- e o chefe salta entre elas. Por isso e' que os chefes se
leem como "muito basicos": um boneco parado com um shader por cima, ao lado
de uma Koliani com 18 estados animados.

Aqui cada pack vira cinco tiras horizontais, o vocabulario comum a todos:

    idle . walk . attack . hurt . death

Saida: `assets/sprites/pixel/bosses_anim/<rig>/<estado>.png` + `rigs.json`
com o numero de frames e o tamanho de celula de cada um.

Alinhamento: todos os frames de um rig sao cortados pela MESMA caixa (a
uniao das caixas de todos os estados) antes de escalar. Sem isso o chefe
saltitava ao mudar de animacao, porque cada pack centra o boneco de maneira
diferente em cada estado.

  python tools/importar_chefes_animados.py
  python tools/importar_chefes_animados.py --preview   # + _preview_<rig>.png
"""

from __future__ import annotations

import glob
import json
import os
import sys

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INC = os.path.join(RAIZ, "assets", "sprites", "incoming")
DEST = os.path.join(RAIZ, "assets", "sprites", "pixel", "bosses_anim")

## Altura do BONECO (ja' sem o ar a' volta) depois de escalado. E' a altura
## a que os chefes de folha estatica ja' aparecem hoje, para o rig novo nao
## mudar o tamanho de ninguem no ecra.
ALVO_H = 112

## Um rig = pasta de origem + que sub-pasta serve cada estado.
##   "@ficheiro.png:n" -> tira ja' pronta com n frames (packs do LuizMelo)
RIGS = {
    # Ceifeiro -- clembod "Bringer of Death". O unico com os 5 estados e
    # ainda Cast/Spell; e' o chefe-morte do plano (nivel 75).
    "ceifeiro": {
        "base": "clembod/Bringer-Of-Death/Individual Sprite",
        "estados": {"idle": "Idle", "walk": "Walk", "attack": "Attack",
                    "hurt": "Hurt", "death": "Death"},
        "fps": {"idle": 8.0, "walk": 10.0, "attack": 14.0, "hurt": 12.0, "death": 10.0},
    },
    # Demonio de lodo -- chierit, versao gratuita (5 animacoes).
    "demonio_lodo": {
        "base": "chierit/boss_demon_slime_FREE_v1.0/individual sprites",
        "estados": {"idle": "01_demon_idle", "walk": "02_demon_walk",
                    "attack": "03_demon_cleave", "hurt": "04_demon_take_hit",
                    "death": "05_demon_death"},
        "fps": {"idle": 8.0, "walk": 12.0, "attack": 16.0, "hurt": 12.0, "death": 14.0},
    },
    # Guardiao de gelo -- chierit. Estava no repo desde 1 set e por usar;
    # e' o chefe natural do Reino do Gelo (regiao IX, niveis 41-45).
    "guardiao_gelo": {
        "base": "chierit/Frost_Guardian_FREE_v1.0/PNG files",
        "estados": {"idle": "idle", "walk": "walk", "attack": "1_atk",
                    "hurt": "take_hit", "death": "death"},
        "fps": {"idle": 8.0, "walk": 11.0, "attack": 15.0, "hurt": 12.0, "death": 12.0},
    },
    # Minotauro -- chierit. A versao gratuita nao traz hurt/death: caem para
    # o idle (melhor um idle do que um frame preso).
    "minotauro": {
        "base": "chierit/mino_v1.1_free/animations",
        "estados": {"idle": "idle", "walk": "walk", "attack": "atk_1"},
        "fps": {"idle": 10.0, "walk": 12.0, "attack": 16.0},
    },
    # Feiticeiro -- LuizMelo "Evil Wizard 2", que ja' vem em tiras.
    "feiticeiro": {
        "base": "luizmelo/EVil Wizard 2/Sprites",
        "estados": {"idle": "@Idle.png:8", "walk": "@Run.png:8",
                    "attack": "@Attack1.png:8", "hurt": "@Take hit.png:3",
                    "death": "@Death.png:7"},
        "fps": {"idle": 8.0, "walk": 12.0, "attack": 14.0, "hurt": 12.0, "death": 10.0},
    },
}


def frames(base: str, spec: str) -> list[Image.Image]:
    """Frames de um estado: pasta de PNGs soltos ou tira `@ficheiro:n`."""
    if spec.startswith("@"):
        nome, n = spec[1:].rsplit(":", 1)
        im = Image.open(os.path.join(base, nome)).convert("RGBA")
        w = im.size[0] // int(n)
        return [im.crop((i * w, 0, (i + 1) * w, im.size[1])) for i in range(int(n))]
    fs = sorted(glob.glob(os.path.join(base, spec, "*.png")),
                key=lambda c: _ordem(os.path.basename(c)))
    return [Image.open(f).convert("RGBA") for f in fs]


def _ordem(nome: str) -> tuple:
    """`x_10.png` tem de vir depois de `x_9.png` -- ordenar pelo NUMERO."""
    digitos = ""
    for c in reversed(os.path.splitext(nome)[0]):
        if c.isdigit():
            digitos = c + digitos
        elif digitos:
            break
    return (int(digitos) if digitos else 0, nome)


def caixa_comum(todos: list[Image.Image]) -> tuple[int, int, int, int]:
    """União das caixas de conteúdo -- é o que mantém o boneco no sítio."""
    x0, y0, x1, y1 = 10 ** 6, 10 ** 6, -1, -1
    for im in todos:
        bb = im.getbbox()
        if bb is None:
            continue
        x0, y0 = min(x0, bb[0]), min(y0, bb[1])
        x1, y1 = max(x1, bb[2]), max(y1, bb[3])
    if x1 < 0:
        return (0, 0, 1, 1)
    return (x0, y0, x1, y1)


def main() -> int:
    quero_previa = "--preview" in sys.argv
    os.makedirs(DEST, exist_ok=True)
    meta: dict[str, dict] = {}

    for rig, cfg in RIGS.items():
        base = os.path.join(INC, cfg["base"])
        if not os.path.isdir(base):
            print("  ! %s saltado (falta %s)" % (rig, cfg["base"]))
            continue
        por_estado = {e: frames(base, s) for e, s in cfg["estados"].items()}
        todos = [im for lista in por_estado.values() for im in lista]
        if not todos:
            print("  ! %s sem frames" % rig)
            continue

        # A caixa de CORTE e' a uniao de tudo (nada pode ficar cortado), mas
        # a ESCALA sai da caixa do `idle`: se saisse da uniao, um ataque com
        # muito fumo encolhia o boneco a metade -- foi o que aconteceu na
        # 1.a versao, em que o ceifeiro ficou com 60 px de corpo em 112 de
        # celula, por causa do rasto da foice.
        cx0, cy0, cx1, cy1 = caixa_comum(todos)
        ix0, iy0, ix1, iy1 = caixa_comum(por_estado.get("idle", todos))
        esc = max(0.05, round(ALVO_H / max(1, iy1 - iy0) * 100) / 100.0)
        cw = max(1, int((cx1 - cx0) * esc))
        ch = max(1, int((cy1 - cy0) * esc))
        # linha dos PES: onde acaba o corpo no `idle`, medida dentro da
        # celula ja' escalada. E' com isto que o jogo assenta o chefe no
        # chao em vez de o deixar a flutuar ou enterrado.
        pes_y = max(1, int((iy1 - cy0) * esc))

        pasta = os.path.join(DEST, rig)
        os.makedirs(pasta, exist_ok=True)
        info = {"w": cw, "h": ch, "pes_y": pes_y, "estados": {}, "fps": cfg["fps"]}
        for estado, lista in por_estado.items():
            tira = Image.new("RGBA", (cw * len(lista), ch), (0, 0, 0, 0))
            for i, im in enumerate(lista):
                corte = im.crop((cx0, cy0, cx1, cy1)).resize((cw, ch), Image.NEAREST)
                tira.alpha_composite(corte, (i * cw, 0))
            tira.save(os.path.join(pasta, estado + ".png"))
            info["estados"][estado] = len(lista)
        meta[rig] = info
        print("  %-14s %s  (%dx%d por frame, pes a %d)" % (
            rig, ", ".join("%s=%d" % (e, n) for e, n in info["estados"].items()),
            cw, ch, pes_y))
        if quero_previa:
            _previa(rig, por_estado, (cx0, cy0, cx1, cy1), cw, ch)

    with open(os.path.join(DEST, "rigs.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=1, ensure_ascii=False)
    print("%d rigs -> %s" % (len(meta), DEST))
    return 0


def _previa(rig: str, por_estado: dict, caixa, cw: int, ch: int) -> None:
    linhas = len(por_estado)
    largo = max(len(l) for l in por_estado.values())
    out = Image.new("RGB", (largo * cw, linhas * ch), (22, 18, 28))
    for li, (_estado, lista) in enumerate(sorted(por_estado.items())):
        for i, im in enumerate(lista):
            corte = im.crop(caixa).resize((cw, ch), Image.NEAREST)
            out.paste(corte, (i * cw, li * ch), corte)
    out.save(os.path.join(DEST, "_preview_%s.png" % rig))


if __name__ == "__main__":
    raise SystemExit(main())
