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
    # Verdugo -- Kronovi- "Boss: Undead Executioner" (itch.io, gratuito,
    # sem clausula anti-IA -- ver assets/sprites/incoming/kronovi/LICENSE.txt).
    # Silhueta escura de chapeu pontiagudo com foice; e' o executor da Dama
    # da Guilhotina. "idle2" (8 frames) serve de walk -- o pack nao anda,
    # so' flutua, e a variacao ja' da' movimento.
    "verdugo": {
        "base": "kronovi/undead_executioner/png",
        "estados": {"idle": "#idle.png:100", "walk": "#idle2.png:100",
                    "attack": "#attacking.png:100", "death": "#death.png:100"},
        "fps": {"idle": 6.0, "walk": 8.0, "attack": 14.0, "death": 10.0},
    },
    # Golem-de-pedra -- Kronovi- "Boss: Mecha-Stone Golem". Uma so' folha
    # 1000x1000 em grelha 100x100; cada estado e' uma LINHA (0-indexed).
    "golem_pedra": {
        "base": "kronovi/mecha_golem",
        "estados": {"idle": "#Character_sheet.png:100:0",
                    "walk": "#Character_sheet.png:100:1",
                    "attack": "#Character_sheet.png:100:2",
                    "hurt": "#Character_sheet.png:100:3",
                    "death": "#Character_sheet.png:100:6"},
        "fps": {"idle": 6.0, "walk": 8.0, "attack": 10.0, "hurt": 10.0, "death": 8.0},
    },
    # Arqueiro-encapuzado -- Kronovi- "Archer Hero". Celula 64x64; varias
    # folhas, uma por estado (algumas com 2+ linhas -- fica tudo em fila).
    # Nota: "Normal Attack.png" e "death.png" tem uma legenda ("Loop
    # Attack" / "death") desenhada NA PROPRIA folha, numa linha fina no
    # meio -- ficam de fora das linhas listadas, senao aparece texto a
    # piscar entre os frames.
    "arqueiro": {
        "base": "kronovi/archer_hero",
        "estados": {"idle": "#Idle and running.png:64:0",
                    "walk": "#Idle and running.png:64:1",
                    "attack": "#Normal Attack.png:64:0,1,3",
                    "death": "#death.png:64:1,2"},
        "fps": {"idle": 6.0, "walk": 12.0, "attack": 14.0, "death": 10.0},
    },
    # Cavaleiro-errante -- Kronovi- "Wandering Knight". O mais completo dos
    # quatro (idle/death/running/jump/fall/crouch/dash/3 ataques numa so'
    # folha 1000x1200, grelha 100x100 -- ver GUIDE.png do pack). Serve de
    # base para VARIOS chefes humanos por recolor (so' 1 usado por agora,
    # `cavaleiro_negro` -- falta repetir a entrada com paletas diferentes
    # para os outros chefes-guerreiro).
    "cavaleiro_negro": {
        "base": "kronovi/wandering_knight",
        "estados": {"idle": "#SPRITESHEET.png:100:0",
                    "walk": "#SPRITESHEET.png:100:3",
                    "attack": "#SPRITESHEET.png:100:8",
                    "hurt": "#SPRITESHEET.png:100:5",
                    "death": "#SPRITESHEET.png:100:1"},
        "fps": {"idle": 6.0, "walk": 12.0, "attack": 14.0, "hurt": 10.0, "death": 10.0},
    },
    # --- LuizMelo, CC0 (3 set 2026) -------------------------------------
    # Packs gratuitos do mesmo autor do "Evil Wizard 2" que ja' usavamos,
    # trazidos por `tools/baixar_packs_itch.py`. Sao todos tiras
    # horizontais de celula fixa: a contagem de frames sai da propria folha
    # (ver `celula_comum`), por isso os specs nao levam `:n`.
    #
    # E' isto que fecha o "cada chefe com a SUA silhueta": em vez de
    # recolorir o mesmo cavaleiro 20 vezes, cada chefe tem um boneco
    # diferente, no mesmo estilo e na mesma escala.
    "rei_ossario": {
        "base": "luizmelo/medieval-king-pack/Medieval King Pack",
        "estados": {"idle": "@Idle.png", "walk": "@Run.png",
                    "attack": "@Attack_1.png", "hurt": "@Hit.png",
                    "death": "@Death.png"},
        "fps": {"idle": 8.0, "walk": 12.0, "attack": 12.0, "hurt": 12.0, "death": 10.0},
    },
    "rei_devorador": {
        "base": "luizmelo/medieval-king-pack-2/Medieval King Pack 2/Sprites",
        "estados": {"idle": "@Idle.png", "walk": "@Run.png",
                    "attack": "@Attack1.png", "hurt": "@Take Hit.png",
                    "death": "@Death.png"},
        "fps": {"idle": 8.0, "walk": 12.0, "attack": 12.0, "hurt": 12.0, "death": 10.0},
    },
    "noiva": {
        "base": "luizmelo/huntress/Huntress/Sprites",
        "estados": {"idle": "@Idle.png", "walk": "@Run.png",
                    "attack": "@Attack1.png", "hurt": "@Take hit.png",
                    "death": "@Death.png"},
        "fps": {"idle": 8.0, "walk": 12.0, "attack": 14.0, "hurt": 12.0, "death": 10.0},
    },
    "sacerdotisa": {
        "base": "luizmelo/huntress-2/Huntress 2/Sprites/Character",
        "estados": {"idle": "@Idle.png", "walk": "@Run.png",
                    "attack": "@Attack.png", "hurt": "@Get Hit.png",
                    "death": "@Death.png"},
        "fps": {"idle": 8.0, "walk": 12.0, "attack": 14.0, "hurt": 12.0, "death": 10.0},
    },
    "bruxa": {
        "base": "luizmelo/wizard-pack/Wizard Pack",
        "estados": {"idle": "@Idle.png", "walk": "@Run.png",
                    "attack": "@Attack1.png", "hurt": "@Hit.png",
                    "death": "@Death.png"},
        "fps": {"idle": 8.0, "walk": 12.0, "attack": 14.0, "hurt": 12.0, "death": 10.0},
    },
    "arauto": {
        "base": "luizmelo/evil-wizard-3/Evil Wizard 3/Sprites",
        "estados": {"idle": "@Idle.png", "walk": "@Run.png",
                    "attack": "@Attack.png", "hurt": "@Get hit.png",
                    "death": "@Death.png"},
        "fps": {"idle": 9.0, "walk": 12.0, "attack": 15.0, "hurt": 12.0, "death": 12.0},
    },
    "feiticeiro_sombrio": {
        "base": "luizmelo/evil-wizard/Evil Wizard/Sprites",
        "estados": {"idle": "@Idle.png", "walk": "@Move.png",
                    "attack": "@Attack.png", "hurt": "@Take Hit.png",
                    "death": "@Death.png"},
        "fps": {"idle": 8.0, "walk": 10.0, "attack": 13.0, "hurt": 12.0, "death": 10.0},
    },
    # Verme de fogo -- serve o chefe-serpente (Naga Zeraph). Nao tem pernas:
    # o "walk" e' o proprio rastejar.
    "serpente": {
        "base": "luizmelo/fire-worm/Fire Worm/Sprites/Worm",
        "estados": {"idle": "@Idle.png", "walk": "@Walk.png",
                    "attack": "@Attack.png", "hurt": "@Get Hit.png",
                    "death": "@Death.png"},
        "fps": {"idle": 8.0, "walk": 10.0, "attack": 16.0, "hurt": 12.0, "death": 10.0},
    },
    "prisioneiro": {
        "base": "luizmelo/medieval-warrior-pack/Medieval Warrior Pack",
        "estados": {"idle": "@Idle.png", "walk": "@Run.png",
                    "attack": "@Attack1.png", "hurt": "@Hit.png",
                    "death": "@Death.png"},
        "fps": {"idle": 8.0, "walk": 12.0, "attack": 13.0, "hurt": 12.0, "death": 10.0},
    },
    "carniceiro": {
        "base": "luizmelo/medieval-warrior-pack-2/Medieval Warrior Pack 2/Sprites",
        "estados": {"idle": "@Idle.png", "walk": "@Run.png",
                    "attack": "@Attack1.png", "hurt": "@Take Hit.png",
                    "death": "@Death.png"},
        "fps": {"idle": 8.0, "walk": 12.0, "attack": 13.0, "hurt": 12.0, "death": 10.0},
    },
    "lanceiro": {
        "base": "luizmelo/medieval-warrior-pack-3/Medieval Warrior Pack 3/Sprites",
        "estados": {"idle": "@Idle.png", "walk": "@Run.png",
                    "attack": "@Attack1.png", "hurt": "@Get Hit.png",
                    "death": "@Death.png"},
        "fps": {"idle": 8.0, "walk": 12.0, "attack": 13.0, "hurt": 12.0, "death": 10.0},
    },
    "monge": {
        "base": "luizmelo/martial-hero/Martial Hero/Sprites",
        "estados": {"idle": "@Idle.png", "walk": "@Run.png",
                    "attack": "@Attack1.png", "hurt": "@Take Hit.png",
                    "death": "@Death.png"},
        "fps": {"idle": 8.0, "walk": 12.0, "attack": 14.0, "hurt": 12.0, "death": 10.0},
    },
    "monge_celeste": {
        "base": "luizmelo/martial-hero-3/Martial Hero 3/Sprite",
        "estados": {"idle": "@Idle.png", "walk": "@Run.png",
                    "attack": "@Attack1.png", "hurt": "@Take Hit.png",
                    "death": "@Death.png"},
        "fps": {"idle": 8.0, "walk": 12.0, "attack": 14.0, "hurt": 12.0, "death": 10.0},
    },
    "colosso": {
        "base": "luizmelo/fantasy-warrior/Fantasy Warrior/Sprites",
        "estados": {"idle": "@Idle.png", "walk": "@Run.png",
                    "attack": "@Attack1.png", "hurt": "@Take hit.png",
                    "death": "@Death.png"},
        "fps": {"idle": 8.0, "walk": 12.0, "attack": 12.0, "hurt": 12.0, "death": 10.0},
    },
    # Bau-mimico -- o unico "monstro-objecto" gratuito que apareceu; e' o
    # que faz sentido para o Sino Vivo (um objecto que ganha vida e morde).
    "mimico": {
        "base": "luizmelo/monsters-creatures-fantasy-2/Monsters Creatures Fantasy 2/Mimic",
        "estados": {"idle": "@idle_transformed.png", "walk": "@walk.png",
                    "attack": "@attack_1.png", "hurt": "@hurt.png",
                    "death": "@death.png"},
        "fps": {"idle": 8.0, "walk": 10.0, "attack": 14.0, "hurt": 12.0, "death": 10.0},
    },
    # Morcego gigante -- o `fly` serve de idle E de walk (nao pousa).
    "alado": {
        "base": "luizmelo/monsters-creatures-fantasy-2/Monsters Creatures Fantasy 2/Bat",
        "estados": {"idle": "@fly.png", "walk": "@fly.png",
                    "attack": "@attack.png", "hurt": "@hurt.png",
                    "death": "@death.png"},
        "fps": {"idle": 12.0, "walk": 14.0, "attack": 14.0, "hurt": 12.0, "death": 10.0},
    },
    # Olho voador -- ja' estava no repo desde 1 set, mas so' como folha de
    # 4 POSES (`tools/extrair_chefes_packs.gd`). Aqui anima a serio.
    "olho_voador": {
        "base": "luizmelo/Monsters_Creatures_Fantasy/Flying eye",
        "estados": {"idle": "@Flight.png", "walk": "@Flight.png",
                    "attack": "@Attack.png", "hurt": "@Take Hit.png",
                    "death": "@Death.png"},
        "fps": {"idle": 10.0, "walk": 12.0, "attack": 14.0, "hurt": 12.0, "death": 10.0},
    },
    # --- chierit, CC-BY 4.0 (creditar) ----------------------------------
    # Horror de tentaculos -- a Rainha Aracnidea (nivel 3). Nao e' uma
    # aranha, mas e' a unica coisa gratuita com muitos membros e postura de
    # bicho grande de ninho.
    "horror": {
        "base": "chierit/free-cthulu/free_cthulu/animations/PNG",
        "estados": {"idle": "idle", "walk": "walk", "attack": "1atk",
                    "hurt": "hurt", "death": "death"},
        "fps": {"idle": 8.0, "walk": 10.0, "attack": 14.0, "hurt": 12.0, "death": 10.0},
    },
    # Elemental de folha -- o Entrevane (a arvore que chora, nivel 4).
    "folha": {
        "base": "chierit/elementals-leaf-ranger/Elementals_Leaf_ranger_Free_v1.0/animations/PNG",
        "estados": {"idle": "idle", "walk": "run", "attack": "1_atk",
                    "hurt": "take_hit", "death": "death"},
        "fps": {"idle": 8.0, "walk": 12.0, "attack": 14.0, "hurt": 12.0, "death": 10.0},
    },
    # Cavaleiro de fogo -- o Ignivar (Fornalha dos Pecadores, nivel 7).
    "cavaleiro_fogo": {
        "base": "chierit/elementals-fire-knight/Elementals_fire_knight_FREE_v1.1/png/fire_knight",
        "estados": {"idle": "01_idle", "walk": "02_run", "attack": "05_1_atk",
                    "hurt": "10_take_hit", "death": "11_death"},
        "fps": {"idle": 8.0, "walk": 12.0, "attack": 14.0, "hurt": 12.0, "death": 10.0},
    },
}


def frames(base: str, spec: str, cel_auto: int = 0) -> list[Image.Image]:
    """Frames de um estado: pasta de PNGs soltos, tira `@ficheiro:n`, ou
    grelha `#ficheiro:celula[:linha]` (célula quadrada; sem `:linha` varre
    a folha toda em row-major e só usa as células com conteúdo -- é o que
    os packs "Kronovi-" precisam, cada estado empilhado em N linhas de uma
    folha só)."""
    if spec.startswith("@"):
        nome = spec[1:]
        cel = cel_auto
        if ":" in nome:
            nome, n = nome.rsplit(":", 1)
            cel = -int(n)                    # negativo = "sao N frames"
        im = Image.open(os.path.join(base, nome)).convert("RGBA")
        w = -(im.size[0] // cel) if cel < 0 else (cel or im.size[1])
        return [im.crop((i * w, 0, (i + 1) * w, im.size[1]))
                for i in range(max(1, im.size[0] // w))]
    if spec.startswith("#"):
        partes = spec[1:].split(":")
        nome, cel = partes[0], int(partes[1])
        im = Image.open(os.path.join(base, nome)).convert("RGBA")
        w, h = im.size
        cols, rows = w // cel, h // cel
        # sem ":linha(s)" -> varre a folha toda; "n" -> so' essa linha;
        # "n,m,o" -> so' essas (uma folha pode ter uma legenda tipo "Loop
        # Attack" numa linha no meio -- essa fica de fora).
        linhas = [int(x) for x in partes[2].split(",")] if len(partes) > 2 else range(rows)
        out = []
        for r in linhas:
            for c in range(cols):
                corte = im.crop((c * cel, r * cel, (c + 1) * cel, (r + 1) * cel))
                if corte.getbbox() is not None:
                    out.append(corte)
        return out
    fs = sorted(glob.glob(os.path.join(base, spec, "*.png")),
                key=lambda c: _ordem(os.path.basename(c)))
    return [Image.open(f).convert("RGBA") for f in fs]


def celula_comum(base: str, specs: dict) -> int:
    """Largura da célula das tiras `@ficheiro.png` sem contagem.

    Os packs do LuizMelo vêm como tiras horizontais de célula fixa, mas o
    número de frames muda de estado para estado e não vem escrito em lado
    nenhum. O máximo divisor comum das larguras das folhas do MESMO rig dá
    a célula (a menos de um múltiplo, se todas as contagens forem pares --
    daí o corte pela altura no fim: uma célula nunca é 2x mais larga que
    alta nestes packs)."""
    larguras, alturas = [], []
    for spec in specs.values():
        if not spec.startswith("@") or ":" in spec:
            continue
        cam = os.path.join(base, spec[1:])
        if not os.path.isfile(cam):
            continue
        w, h = Image.open(cam).size
        larguras.append(w)
        alturas.append(h)
    if not larguras:
        return 0
    g = larguras[0]
    for w in larguras[1:]:
        g = _mdc(g, w)
    alto = max(alturas)
    while g > alto * 1.6 and g % 2 == 0:
        g //= 2
    return g


def _mdc(a: int, b: int) -> int:
    while b:
        a, b = b, a % b
    return a


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
        cel = celula_comum(base, cfg["estados"])
        por_estado = {e: frames(base, s, cel) for e, s in cfg["estados"].items()}
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
