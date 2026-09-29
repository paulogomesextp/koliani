#!/usr/bin/env python3
"""Recorta os PROPS canonicos da Regiao II da prancha aprovada.

    python3 tools/extrair_props_regiao02.py [--preview]

Porque isto existe
------------------
O catalogo de decoracao dava 12 props ao `desfiladeiro` -- e eram os props da
Regiao III copiados a mao (`torres`: balaustrada, velas, tocha, janela
gotica, coluna de igreja, cruz, lapide...). Nenhuma ferramenta os gerava.
Tres assentavam no chao e DOIS desses (`cruz`, `lapide`) sao vocabulario de
CEMITERIO, que nao aparece em nenhuma prancha da Regiao II. A Regiao I tem 17
props e 8 de chao.

A prancha `asset_atlas_level_assets.png` tem uma fila inteira chamada
`PROPS E DETALHES AMBIENTAIS` com exactamente o que faltava: ESTATUAS,
BANDEIRAS (carmesim, com cruz), CORRENTES, GARGULAS, LANTERNAS, GAIOLAS,
COLUNAS, ARCOS, JANELAS, PEDRAS E ESCOMBROS, CRISTAIS (violeta), VEGETACAO
(carmesim) e ARVORES SECAS. Nao ha' nada a desenhar: ha' a recortar.

A VEGETACAO CARMESIM e' a peca mais importante da fila. O audit poe o terreno
como "maior desvio visual" da regiao precisamente por causa dela: a prancha
define o Desfiladeiro por pedra com folhagem carmesim a cair das bordas, e o
jogo nao tinha uma unica folha.

Os cortes sao RECTANGULOS MEDIDOS a olho na prancha (ela e' fixa e aprovada),
e nao detectados: ao contrario da fila do bestiario, aqui os props tocam-se
uns nos outros e as legendas de duas palavras partem-se, portanto a deteccao
automatica dava cortes errados. O que o script faz sozinho e' apertar cada
caixa ao conteudo e tirar o fundo com rampa de alfa.
"""
import json
import os
import sys

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRANCHA = os.path.join(RAIZ, "docs/art_direction/regions/region_02",
                       "asset_atlas_level_assets.png")
DECO = os.path.join(RAIZ, "assets/sprites/pixel/deco")
REGIAO = "desfiladeiro"

FUNDO = (0, 14, 20)
ALFA_ZERO = 11
ALFA_CHEIO = 35
LIMIAR_CORTE = 26
BANDA = (500, 604)           # fila dos props; as legendas comecam em y=606

## nome -> (x0, x1, onde, altura). `onde` e' o que o `plataforma.gd` e o
## `atmosfera.gd` usam para decidir onde o prop assenta.
##
## A ALTURA importa e nao e' estetica. A prancha desenha a fila toda ao mesmo
## tamanho, para se comparar; em jogo, um monte de escombros de 109 px numa
## saliencia de 22 px le'-se como ARQUITECTURA e nao como entulho -- foi o
## que se viu na primeira passagem, com duas pedras a fazerem de pilares ao
## lado da Koliani (que tem 65 px). Por isso o que se PISA e' encolhido para
## a escala dela, e o que e' monumental (estatua, gargula) fica acima.
## 0 = fica como esta' na prancha.
PROPS = [
    ("estatua",         25,   73, "chao", 96),
    ("bandeira",        94,  145, "pendurado", 0),
    ("correntes",      178,  215, "pendurado", 0),
    ("gargula",        243,  305, "chao", 82),
    ("lanterna",       320,  363, "pendurado", 0),
    ("gaiola",         405,  441, "pendurado", 0),
    ("coluna",         450,  480, "parede", 0),
    ("arco",           506,  558, "parede", 0),
    ("janela",         568,  622, "parede", 0),
    ("escombros",      624,  722, "chao", 54),
    ("vitral",         734,  774, "parede", 0),
    ("pedras",         775,  842, "chao", 40),
    ("cristais",       843,  886, "chao", 58),
    ("vegetacao_alta", 888,  936, "chao", 70),
    ("vegetacao_baixa", 938, 992, "chao", 46),
    ("arvore_seca",    995, 1102, "parede", 0),
]

## Props da Regiao III que estavam emprestados ao Desfiladeiro e saem do
## catalogo. Os PNG ficam no disco (nao custam nada e o `torres` usa-os);
## o que sai e' a entrada, para o gerador deixar de os poder escolher.
FORA = ["cruz", "lapide", "flamula"]


def dist(p):
    return abs(p[0] - FUNDO[0]) + abs(p[1] - FUNDO[1]) + abs(p[2] - FUNDO[2])


def recortar(px, x0, x1, y0, y1):
    ay, by, ax, bx = None, None, None, None
    for y in range(y0, y1):
        for x in range(x0, x1):
            if dist(px[x, y]) > LIMIAR_CORTE:
                ay = y if ay is None else ay
                by = y
                ax = x if ax is None or x < ax else ax
                bx = x if bx is None or x > bx else bx
    if ay is None:
        return None
    out = Image.new("RGBA", (bx - ax + 1, by - ay + 1), (0, 0, 0, 0))
    po = out.load()
    for j in range(out.height):
        for i in range(out.width):
            r, g, b = px[ax + i, ay + j]
            d = dist((r, g, b))
            if d <= ALFA_ZERO:
                continue
            a = 255 if d >= ALFA_CHEIO else int(
                255 * (d - ALFA_ZERO) / (ALFA_CHEIO - ALFA_ZERO))
            po[i, j] = (r, g, b, a)
    return out


def main():
    im = Image.open(PRANCHA).convert("RGB")
    px = im.load()
    pasta = os.path.join(DECO, REGIAO)
    os.makedirs(pasta, exist_ok=True)

    feitos, previas = [], []
    for nome, x0, x1, onde, alvo in PROPS:
        q = recortar(px, x0, x1, *BANDA)
        if q is None:
            print("ERRO: %s sem pixeis em x=%d-%d" % (nome, x0, x1))
            return 1
        if alvo and q.height > alvo:
            e = alvo / float(q.height)
            q = q.resize((max(1, round(q.width * e)), alvo), Image.LANCZOS)
        q.save(os.path.join(pasta, "%s.png" % nome))
        feitos.append({"nome": nome, "onde": onde, "w": q.width, "h": q.height})
        previas.append((nome, q))
        print("  %-16s %s  %dx%d" % (nome, onde, q.width, q.height))

    cam = os.path.join(DECO, "deco.json")
    with open(cam, encoding="utf-8") as f:
        cat = json.load(f)
    antigos = [p for p in cat.get(REGIAO, [])
               if p.get("nome") not in FORA
               and p.get("nome") not in {d["nome"] for d in feitos}]
    cat[REGIAO] = antigos + feitos
    with open(cam, "w", encoding="utf-8") as f:
        json.dump(cat, f, indent=1, ensure_ascii=False)
    chao = sum(1 for p in cat[REGIAO] if p["onde"] == "chao")
    print("deco.json: %s fica com %d props (%d de chao)"
          % (REGIAO, len(cat[REGIAO]), chao))

    if "--preview" in sys.argv:
        alt = max(q.height for _, q in previas) + 8
        larg = sum(q.width + 8 for _, q in previas)
        folha = Image.new("RGBA", (larg, alt), (14, 16, 26, 255))
        x = 0
        for _, q in previas:
            folha.paste(q, (x + 4, alt - q.height - 4), q)
            x += q.width + 8
        folha = folha.resize((folha.width * 2, folha.height * 2), Image.NEAREST)
        out = os.path.join(RAIZ, "work/preview_props_r2.png")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        folha.save(out)
        print("preview ->", out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
