#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Monta o RIG NOVO da Koliani a partir da pixel-art que o Paulo desenhou.

Fonte (3 set 2026): `C:/Users/paulo/Desktop/newkoliani/` -- duas folhas,
`idle` (10 frames de 46x55) e `walk` (24 frames de 45x58, grelha 4x6).
Ambas viradas a' ESQUERDA; o jogo tem a convencao contraria
(`scale.x = +olha_para`), por isso tudo e' espelhado a' entrada.

O jogo precisa de 18 estados (ver `_KOLI_ANIMS_NOVA` em `koliani.gd`) e a
arte so' traz dois. Os outros 16 sao DERIVADOS por transformacao dos frames
de origem -- inclinar, achatar, rodar, deslocar, mais um arco de espada
desenhado por cima nos ataques. Fica coerente (e' sempre a mesma
personagem) mas nao substitui frames desenhados a' mao: se o Paulo vier a
ter `attack`/`jump`/`roll` do mesmo artista, e' so' larga-los na pasta de
origem e ligar aqui.

  python tools/importar_rig_koliani_nova.py
  python tools/importar_rig_koliani_nova.py --preview   # + folha de contacto
"""

from __future__ import annotations

import math
import os
import sys

from PIL import Image, ImageDraw

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTE = os.environ.get("KOLI_FONTE", r"C:\Users\paulo\Desktop\newkoliani")
DEST = os.path.join(RAIZ, "assets", "sprites", "pixel", "koliani_nova")

# Tela de cada frame. Mais alta e mais larga do que a personagem para as
# rotacoes (rolamento, salto duplo, morte) nao cortarem os cantos.
LARG, ALT = 72, 72
BASE_Y = 68          # linha dos pes dentro da tela
CENTRO_X = 36

# Azul da Koliani (o do manto, `#0321bc`) e os seus tons -- e' a cor que os
# projeteis passam a ter (ver `tools/extrair_efeitos_azuis.py`).
AZUL = (0x03, 0x21, 0xbc)
AZUL_CLARO = (0x6e, 0x8c, 0xff)
LAVANDA = (0xb2, 0xb2, 0xff)
BRANCO = (0xff, 0xff, 0xff)


# ------------------------------------------------------------ utilitarios
def folha(cam: str) -> Image.Image:
    p = os.path.join(FONTE, cam)
    if not os.path.exists(p):
        raise SystemExit("falta a folha de origem: %s" % p)
    return Image.open(p).convert("RGBA")


def corta(im: Image.Image, cx: int, cy: int, w: int, h: int) -> Image.Image:
    return im.crop((cx * w, cy * h, cx * w + w, cy * h + h))


def assenta(f: Image.Image, dy: int = 0, dx: int = 0) -> Image.Image:
    """Poe o frame na tela padrao, virado a' DIREITA e com os pes na base."""
    f = f.transpose(Image.FLIP_LEFT_RIGHT)          # a arte vem virada a' esquerda
    bb = f.getbbox()
    if bb:
        f = f.crop(bb)
    out = Image.new("RGBA", (LARG, ALT), (0, 0, 0, 0))
    out.alpha_composite(f, (CENTRO_X - f.size[0] // 2 + dx, BASE_Y - f.size[1] + dy))
    return out


def roda(f: Image.Image, graus: float, cx: int = CENTRO_X, cy: int = BASE_Y - 22) -> Image.Image:
    return f.rotate(graus, resample=Image.NEAREST, center=(cx, cy))


PIVO = (CENTRO_X, BASE_Y - 26)


def centra(f: Image.Image) -> Image.Image:
    """Poe o CENTRO do corpo no pivo das rotacoes.

    Sem isto, uma pirueta feita com os pes na base descrevia um circulo
    enorme e a personagem saltava para fora da tela a meio do rolamento.
    """
    bb = f.getbbox()
    if not bb:
        return f
    corpo = f.crop(bb)
    out = Image.new("RGBA", (LARG, ALT), (0, 0, 0, 0))
    out.alpha_composite(corpo, (PIVO[0] - corpo.size[0] // 2, PIVO[1] - corpo.size[1] // 2))
    return out


def pirueta(f: Image.Image, graus: float) -> Image.Image:
    """Rotacao a' volta do centro do corpo (salto duplo, rolamento)."""
    return centra(f).rotate(graus, resample=Image.NEAREST, center=PIVO)


def achata(f: Image.Image, fx: float, fy: float) -> Image.Image:
    """Escala o conteudo mantendo os pes na base (agachar, aterrar)."""
    bb = f.getbbox()
    if not bb:
        return f
    corpo = f.crop(bb)
    nw = max(1, int(corpo.size[0] * fx))
    nh = max(1, int(corpo.size[1] * fy))
    corpo = corpo.resize((nw, nh), Image.NEAREST)
    out = Image.new("RGBA", (LARG, ALT), (0, 0, 0, 0))
    out.alpha_composite(corpo, (CENTRO_X - nw // 2, BASE_Y - nh))
    return out


def tinge(f: Image.Image, cor, forca: float) -> Image.Image:
    out = f.copy()
    px = out.load()
    for y in range(out.size[1]):
        for x in range(out.size[0]):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            px[x, y] = (int(r + (cor[0] - r) * forca),
                        int(g + (cor[1] - g) * forca),
                        int(b + (cor[2] - b) * forca), a)
    return out


def rastro(f: Image.Image, n: int, passo: int, alfa: float) -> Image.Image:
    """Cópias esbatidas atrás do corpo -- dá velocidade ao dash/rolamento."""
    out = Image.new("RGBA", (LARG, ALT), (0, 0, 0, 0))
    for i in range(n, 0, -1):
        c = tinge(f, AZUL_CLARO, 0.75)
        c.putalpha(c.getchannel("A").point(lambda v, i=i: int(v * alfa / (i + 1))))
        out.alpha_composite(c, (-passo * (i + 1), 0))
    out.alpha_composite(f)
    return out


def arco_espada(f: Image.Image, t0: float, t1: float, raio: int, brilho: float,
                dx: int = 6, dy: int = -24, espessura: int = 5) -> Image.Image:
    """Desenha o rasto do golpe -- um arco azul da paleta da personagem.

    A arte nao traz frames de ataque; e' este arco (mais a inclinacao do
    corpo) que faz o golpe ler. `t0`/`t1` em graus, 0 = para a direita.
    """
    out = f.copy()
    cx, cy = CENTRO_X + dx, BASE_Y + dy
    cap = Image.new("RGBA", (LARG, ALT), (0, 0, 0, 0))
    d = ImageDraw.Draw(cap)
    caixa = [cx - raio, cy - raio, cx + raio, cy + raio]
    d.arc(caixa, -t1, -t0, fill=AZUL_CLARO + (int(210 * brilho),), width=espessura)
    caixa2 = [cx - raio + 3, cy - raio + 3, cx + raio - 3, cy + raio - 3]
    d.arc(caixa2, -t1 + 6, -t0 - 6, fill=BRANCO + (int(190 * brilho),), width=2)
    out.alpha_composite(cap)
    return out


def grava(nome: str, frames: list[Image.Image]) -> None:
    tira = Image.new("RGBA", (LARG * len(frames), ALT), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        tira.alpha_composite(f, (i * LARG, 0))
    tira.save(os.path.join(DEST, nome + ".png"))
    print("  %-10s %2d frames" % (nome, len(frames)))


# ------------------------------------------------------------------ main
def main() -> int:
    os.makedirs(DEST, exist_ok=True)
    f_idle = folha(os.path.join("idle", "sprite sheets", "idle.png"))
    f_walk = folha(os.path.join("walk", "sprite sheets", "walk.png"))

    idle = [assenta(corta(f_idle, i, 0, 46, 55)) for i in range(10)]
    andar = [assenta(corta(f_walk, c, r, 45, 58))
             for r in range(6) for c in range(4)]

    parado = idle[0]
    passo = andar[6]        # perna a' frente, bom para saltos
    junto = andar[0]        # pernas juntas

    estados: dict[str, list[Image.Image]] = {}

    # --- os dois que vieram desenhados --------------------------------
    estados["idle"] = idle
    estados["run"] = andar[::2]          # 12 dos 24: a passada fica mais viva

    # --- ar ------------------------------------------------------------
    estados["jump"] = [
        achata(roda(passo, -6), 0.96, 1.06),
        roda(passo, -9),
        roda(passo, -6),
    ]
    estados["fall"] = [roda(junto, 5), roda(junto, 8), roda(junto, 5)]
    # salto duplo: pirueta completa
    estados["djump"] = [pirueta(achata(junto, 0.92, 0.88), -a * 45.0) for a in range(8)]

    # --- chao ----------------------------------------------------------
    estados["crouch"] = [achata(parado, 1.06, 0.72), achata(idle[4], 1.06, 0.70)]
    estados["wallslide"] = [roda(junto, 10), roda(junto, 13)]
    estados["borda"] = [achata(junto, 0.94, 1.0), achata(junto, 0.94, 0.98)]
    estados["aterrar"] = [
        achata(parado, 1.22, 0.66), achata(parado, 1.12, 0.82),
        achata(parado, 1.04, 0.95), parado,
    ]
    estados["defesa"] = [achata(roda(parado, 7), 1.02, 0.94),
                         achata(roda(idle[5], 7), 1.02, 0.93)]

    # --- movimento rapido ---------------------------------------------
    estados["roll"] = [rastro(roda(achata(junto, 0.9, 0.72), -a * 60.0), 2, 5, 0.5)
                       for a in range(6)]
    estados["dash"] = [rastro(roda(passo, -14), 3, 7, 0.65) for _ in range(2)] + \
                      [rastro(roda(passo, -10), 2, 5, 0.5)]

    # --- dano / morte ---------------------------------------------------
    estados["hurt"] = [
        tinge(roda(parado, 16), BRANCO, 0.55),
        tinge(roda(parado, 20), (255, 90, 90), 0.38),
        roda(parado, 14),
    ]
    morte = []
    for i in range(6):
        t = i / 5.0
        f = roda(achata(parado, 1.0 + 0.2 * t, 1.0 - 0.45 * t), -78.0 * t)
        f = tinge(f, (40, 30, 60), 0.35 * t)
        f.putalpha(f.getchannel("A").point(lambda v, t=t: int(v * (1.0 - 0.55 * t))))
        morte.append(f)
    estados["morte"] = morte

    # --- combo de espada (arco desenhado; ver `arco_espada`) -----------
    def golpe(base, incl, arcos, raio=26, dx=6, dy=-24):
        fora = []
        for i, (t0, t1, br) in enumerate(arcos):
            c = roda(base, -incl[i])
            fora.append(arco_espada(c, t0, t1, raio, br, dx, dy))
        return fora

    estados["attack"] = golpe(passo, [-4, -10, -14, -10, -4], [
        (60, 95, 0.35), (10, 90, 0.9), (-30, 55, 1.0), (-50, 5, 0.6), (-55, -25, 0.2)])
    estados["attack2"] = golpe(junto, [6, 12, 14, 10, 4], [
        (-70, -35, 0.35), (-60, 10, 0.9), (-25, 60, 1.0), (20, 85, 0.6), (60, 95, 0.2)])
    estados["attack3"] = golpe(passo, [-6, -14, -18, -16, -10, -4], [
        (70, 120, 0.4), (20, 115, 0.85), (-40, 70, 1.0), (-80, 10, 0.8),
        (-95, -40, 0.45), (-100, -80, 0.15)], raio=31)
    # 4.o golpe: estocada -- sem arco, um feixe a' frente
    estocada = []
    for i, (av, br) in enumerate([(2, 0.3), (8, 0.9), (11, 1.0), (7, 0.5), (3, 0.15)]):
        c = assenta(corta(f_walk, 2, 1, 45, 58), dx=av)
        c = roda(c, -12)
        cap = Image.new("RGBA", (LARG, ALT), (0, 0, 0, 0))
        d = ImageDraw.Draw(cap)
        y = BASE_Y - 26
        d.line([(CENTRO_X + 6, y), (CENTRO_X + 20 + av * 2, y)],
               fill=AZUL_CLARO + (int(220 * br),), width=5)
        d.line([(CENTRO_X + 8, y), (CENTRO_X + 18 + av * 2, y)],
               fill=BRANCO + (int(200 * br),), width=2)
        c.alpha_composite(cap)
        estocada.append(c)
    estados["attack4"] = estocada

    for nome, frames in sorted(estados.items()):
        grava(nome, frames)

    if "--preview" in sys.argv:
        _previa(estados)
    return 0


def _previa(estados) -> None:
    largura = max(len(v) for v in estados.values())
    folha_im = Image.new("RGBA", (LARG * largura, ALT * len(estados)), (24, 20, 32, 255))
    d = ImageDraw.Draw(folha_im)
    for j, (nome, frames) in enumerate(sorted(estados.items())):
        for i, f in enumerate(frames):
            folha_im.alpha_composite(f, (i * LARG, j * ALT))
        d.text((3, j * ALT + 3), nome, fill=(255, 220, 120, 255))
    saida = os.path.join(DEST, "_preview_koliani_nova.png")
    folha_im.convert("RGB").resize(
        (folha_im.size[0] * 2, folha_im.size[1] * 2), Image.NEAREST).save(saida)
    print("previa ->", saida)


if __name__ == "__main__":
    raise SystemExit(main())
