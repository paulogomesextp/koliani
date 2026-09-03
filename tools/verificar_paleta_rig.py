#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Mostra o que o `equipamento.gdshader` apanha no rig da Koliani.

O shader troca duas rampas de cinzento do rig "cavaleiro" pelas cores do
equipamento: uma é o fio da lâmina, a outra são as placas da armadura.
Como as duas rampas foram lidas à mão da arte, isto é a rede de segurança
-- se um dia se trocar o rig, correr esta ferramenta diz logo se as cores
ainda batem certo.

    python tools/verificar_paleta_rig.py [estado ...]

Grava em `docs/img/paleta_rig_<estado>.png`:
  - linha 1: a tira original
  - linha 2: as duas rampas remarcadas (vermelho = arma, verde = armadura)
  - linhas 3+: a tira já trocada por algumas cores de arma/armadura reais,
    com a MESMA conta do shader (`rampa_de`).
"""
from __future__ import annotations

import os
import sys

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RIG = os.path.join(RAIZ, "assets", "sprites", "pixel", "koliani_cavaleiro")
SAIDA = os.path.join(RAIZ, "docs", "img")

# As duas rampas, do escuro para o claro, com a posição de cada degrau
# (tem de bater certo com `assets/shaders/equipamento.gdshader`).
RAMPA_ARMA = [
    ((0x5F, 0x5C, 0x69), 0.00),
    ((0x66, 0x63, 0x71), 0.22),
    ((0x6C, 0x69, 0x78), 0.40),
    ((0x6E, 0x6B, 0x7A), 0.46),
    ((0xC6, 0xB9, 0xD2), 1.00),
]
RAMPA_ARMADURA = [
    ((0x2B, 0x29, 0x31), 0.00),
    ((0x3D, 0x3B, 0x44), 0.36),
    ((0x49, 0x47, 0x51), 0.62),
    ((0x54, 0x52, 0x5E), 1.00),
]

# Amostra de cores reais de `Equipamento.cor_arma` / `cor_armadura`.
AMOSTRAS = [
    ("lamina gasta / trapos", (0.62, 0.62, 0.68), (0.78, 0.73, 0.64)),
    ("forjaluz / casca teia", (0.98, 0.82, 0.42), (0.69, 0.64, 0.75)),
    ("brasa do inferno", (1.00, 0.48, 0.14), (0.60, 0.55, 0.85)),
    ("ultima lamina", (0.94, 0.95, 1.00), (0.50, 0.45, 0.95)),
]


def rampa_de(cor: tuple[float, float, float], t: float) -> tuple[int, int, int]:
    """A mesma conta do shader: uma rampa de pixel-art a partir de UMA cor."""
    out = []
    for canal in cor:
        escuro = canal * 0.42
        claro = canal + (1.0 - canal) * 0.42
        out.append(int(round(255.0 * (escuro + (claro - escuro) * t))))
    return (out[0], out[1], out[2])


def trocar(im: Image.Image, cor_arma, cor_armadura) -> Image.Image:
    tabela = {}
    for rgb, t in RAMPA_ARMA:
        tabela[rgb] = rampa_de(cor_arma, t)
    for rgb, t in RAMPA_ARMADURA:
        tabela[rgb] = rampa_de(cor_armadura, t)
    out = im.copy()
    px = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 8 and (r, g, b) in tabela:
                nr, ng, nb = tabela[(r, g, b)]
                px[x, y] = (nr, ng, nb, a)
    return out


def marcar(im: Image.Image) -> Image.Image:
    arma = {rgb for rgb, _ in RAMPA_ARMA}
    armadura = {rgb for rgb, _ in RAMPA_ARMADURA}
    out = im.copy()
    px = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 9:
                continue
            if (r, g, b) in arma:
                px[x, y] = (255, 40, 40, 255)
            elif (r, g, b) in armadura:
                px[x, y] = (40, 255, 60, 255)
    return out


def folha(estado: str, escala: int = 3) -> str:
    caminho = os.path.join(RIG, estado + ".png")
    if not os.path.exists(caminho):
        raise SystemExit("nao existe: " + caminho)
    base = Image.open(caminho).convert("RGBA")
    linhas = [base, marcar(base)]
    linhas += [trocar(base, w, a) for _, w, a in AMOSTRAS]
    w, h = base.size
    folha_im = Image.new("RGBA", (w, h * len(linhas)), (24, 20, 30, 255))
    for i, ln in enumerate(linhas):
        folha_im.alpha_composite(ln, (0, i * h))
    folha_im = folha_im.resize((w * escala, h * len(linhas) * escala), Image.NEAREST)
    os.makedirs(SAIDA, exist_ok=True)
    destino = os.path.join(SAIDA, "paleta_rig_%s.png" % estado)
    folha_im.save(destino)
    return destino


def main() -> None:
    estados = sys.argv[1:] or ["idle", "run", "attack"]
    for e in estados:
        print(folha(e))
    print("\nLinha 1 = original, 2 = rampas marcadas (vermelho arma, verde armadura),")
    print("3+ = a troca de paleta com as cores de:", ", ".join(n for n, _, _ in AMOSTRAS))


if __name__ == "__main__":
    main()
