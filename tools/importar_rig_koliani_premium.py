#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Converte a folha-mestra da Execution 5B em tiras para o runtime.

A folha-mestra e' preservada em ``assets/sprites/source``. O gerador remove
apenas o fundo claro da apresentacao, recorta as poses pela disposicao
documentada abaixo e ancora todas as poses de chao na mesma linha. Os PNGs em
``assets/sprites/pixel/koliani_premium_v1`` sao derivados; para os refazer:

    python tools/importar_rig_koliani_premium.py

O script nao toca em colisao, hitbox, movimento ou tempos de gameplay.
"""
from __future__ import annotations

import os
from collections import deque

from PIL import Image


RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTE = os.path.join(
    RAIZ, "assets", "sprites", "source", "koliani_premium_v1",
    "koliani_premium_v1_sheet.png",
)
DESTINO = os.path.join(
    RAIZ, "assets", "sprites", "pixel", "koliani_premium_v1",
)

CEL_W = 160
CEL_H = 96
ESCALA = 0.5
ALFA_MIN = 16
CHAO = 90
CENTRO_AR = 49

# As fronteiras sao os meios entre as poses da folha aprovada. A geracao
# artistica nao produziu uma grelha matematica, por isso a fonte continua a
# ser a autoridade e este mapa torna o recorte repetivel.
LINHAS: dict[str, tuple[int, int, list[int]]] = {
    "idle":   (0, 205, [25, 200, 365, 525, 690]),
    "run":    (195, 410, [20, 210, 405, 595, 785, 975]),
    "aereo":  (385, 615, [10, 200, 390, 570, 745, 910, 1135, 1322, 1530]),
    "combate": (590, 785, []),
    "morte":  (810, 1024, []),
}

CAIXAS: dict[str, list[tuple[int, int]]] = {
    "run": [(20, 205), (220, 390), (420, 610), (620, 810), (805, 960)],
    "aereo": [
        (25, 175), (190, 345), (370, 520), (545, 700),
        (720, 855), (890, 1100), (1110, 1295), (1280, 1490),
    ],
    "combate": [
        (20, 175), (180, 325), (330, 505), (500, 660),
        (660, 835), (820, 1110), (1150, 1300), (1305, 1440),
    ],
    "morte": [(25, 165), (180, 305), (320, 490), (500, 690), (700, 920)],
}


def _tirar_fundo(imagem: Image.Image) -> Image.Image:
    """Transforma apenas o checkerboard quase branco em alfa real."""
    src = imagem.convert("RGBA")
    px = src.load()
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, _a = px[x, y]
            if min(r, g, b) >= 190 and max(r, g, b) - min(r, g, b) <= 18:
                px[x, y] = (0, 0, 0, 0)
    return src


def _componentes(imagem: Image.Image) -> list[dict]:
    """Devolve componentes opacos, incluindo os pixeis de cada um."""
    px = imagem.load()
    w, h = imagem.size
    vistos = bytearray(w * h)
    saida: list[dict] = []
    for sy in range(h):
        for sx in range(w):
            indice = sy * w + sx
            if vistos[indice] or px[sx, sy][3] <= ALFA_MIN:
                continue
            fila = deque([(sx, sy)])
            vistos[indice] = 1
            area = 0
            pontos: list[tuple[int, int]] = []
            x0 = x1 = sx
            y0 = y1 = sy
            while fila:
                x, y = fila.popleft()
                area += 1
                pontos.append((x, y))
                x0, x1 = min(x0, x), max(x1, x)
                y0, y1 = min(y0, y), max(y1, y)
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if not (0 <= nx < w and 0 <= ny < h):
                            continue
                        ni = ny * w + nx
                        if vistos[ni] or px[nx, ny][3] <= ALFA_MIN:
                            continue
                        vistos[ni] = 1
                        fila.append((nx, ny))
            saida.append({
                "area": area,
                "x0": x0,
                "y0": y0,
                "x1": x1 + 1,
                "y1": y1 + 1,
                "pontos": pontos,
            })
    return saida


def _caixa_corpo(imagem: Image.Image) -> dict:
    """Estima o corpo pelas cores escuras, ignorando arcos violeta claros."""
    px = imagem.load()
    pontos = []
    for y in range(imagem.height):
        for x in range(imagem.width):
            r, g, b, a = px[x, y]
            if a > ALFA_MIN and max(r, g, b) < 190:
                pontos.append((x, y))
    if not pontos:
        pontos = [(0, 0), (imagem.width - 1, imagem.height - 1)]
    return {
        "x0": min(p[0] for p in pontos), "y0": min(p[1] for p in pontos),
        "x1": max(p[0] for p in pontos) + 1, "y1": max(p[1] for p in pontos) + 1,
    }


def _limpar_sobras(imagem: Image.Image) -> tuple[Image.Image, dict]:
    """Remove fragmentos da pose vizinha sem apagar corpo/VFX ligados."""
    componentes = [c for c in _componentes(imagem) if c["area"] >= 4]
    if not componentes:
        vazio = {"area": 0, "x0": 0, "y0": 0,
                 "x1": imagem.width, "y1": imagem.height, "pontos": []}
        return imagem, vazio
    limpo = Image.new("RGBA", imagem.size, (0, 0, 0, 0))
    src, dst = imagem.load(), limpo.load()
    for componente in componentes:
        # O gerador deixou partes da pose seguinte a entrar pela margem. A
        # pose pretendida fica inteira dentro da janela; so' o transbordo
        # toca a fronteira lateral. Os restantes componentes (cabelo, brilho,
        # po' e arco) pertencem ao frame e ficam.
        manter = componente["x0"] > 0 and componente["x1"] < imagem.width
        if manter:
            for x, y in componente["pontos"]:
                dst[x, y] = src[x, y]
    return limpo, _caixa_corpo(limpo)


def _quadro(fonte: Image.Image, caixa: tuple[int, int, int, int], ar: bool) -> Image.Image:
    recorte = fonte.crop(caixa)
    novo_tamanho = (
        max(1, round(recorte.width * ESCALA)),
        max(1, round(recorte.height * ESCALA)),
    )
    recorte = recorte.resize(novo_tamanho, Image.Resampling.NEAREST)
    recorte, corpo = _limpar_sobras(recorte)
    x0, y0, x1, y1 = corpo["x0"], corpo["y0"], corpo["x1"], corpo["y1"]
    dx = round(CEL_W * 0.5 - (x0 + x1) * 0.5)
    if ar:
        dy = round(CENTRO_AR - (y0 + y1) * 0.5)
    else:
        dy = CHAO - y1
    caixa_total = recorte.getbbox()
    if caixa_total:
        tx0, _ty0, tx1, _ty1 = caixa_total
        if dx + tx1 > CEL_W:
            dx -= dx + tx1 - CEL_W
        if dx + tx0 < 0:
            dx -= dx + tx0
    quadro = Image.new("RGBA", (CEL_W, CEL_H), (0, 0, 0, 0))
    quadro.alpha_composite(recorte, (dx, dy))
    return quadro


def _poses(fonte: Image.Image, linha: str, ar: bool = False) -> list[Image.Image]:
    y0, y1, xs = LINHAS[linha]
    if linha in CAIXAS:
        return [_quadro(fonte, (x0, y0, x1, y1), ar)
                for x0, x1 in CAIXAS[linha]]
    return [
        _quadro(fonte, (xs[i], y0, xs[i + 1], y1), ar)
        for i in range(len(xs) - 1)
    ]


def _guardar(nome: str, quadros: list[Image.Image]) -> None:
    tira = Image.new("RGBA", (CEL_W * len(quadros), CEL_H), (0, 0, 0, 0))
    for i, quadro in enumerate(quadros):
        tira.alpha_composite(quadro, (i * CEL_W, 0))
    tira.save(os.path.join(DESTINO, nome + ".png"), optimize=True)


def main() -> None:
    if not os.path.exists(FONTE):
        raise SystemExit("folha-mestra em falta: " + FONTE)
    os.makedirs(DESTINO, exist_ok=True)
    fonte = _tirar_fundo(Image.open(FONTE))

    idle = _poses(fonte, "idle")
    corrida = _poses(fonte, "run")
    aereo = _poses(fonte, "aereo", ar=True)
    combate = _poses(fonte, "combate")
    morte = _poses(fonte, "morte")

    estados = {
        "idle": idle,
        "run": corrida,
        "jump": aereo[0:3],
        "fall": aereo[3:5],
        "dash": aereo[5:8],
        "attack": combate[0:6],
        "attack2": combate[0:6],
        "attack3": combate[0:6],
        "attack4": combate[0:6],
        "hurt": combate[6:8],
        "morte": morte,
        # Fallbacks coerentes do mesmo prototype; nao misturam escalas com o
        # rig antigo e nao inventam semantica de gameplay.
        "aterrar": [morte[0], idle[0]],
        "crouch": [morte[0]],
        "wallslide": aereo[3:5],
        "borda": aereo[3:5],
        "djump": aereo[0:3],
        "roll": aereo[5:8],
        "defesa": [idle[0]],
    }
    for nome, quadros in estados.items():
        _guardar(nome, quadros)

    resumo = ", ".join(f"{nome}={len(q)}" for nome, q in estados.items())
    print("Koliani premium v1: " + resumo)


if __name__ == "__main__":
    main()
