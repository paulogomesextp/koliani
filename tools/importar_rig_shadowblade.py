#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Importa o rig **Shadowblade** (arte do Paulo) para as tiras da Koliani.

O Paulo deu o rig em `assets/sprites/incoming/shadowblade/`: um atlas
`shadowblade_hero_atlas.png` (1024x800) e um `SpriteFrames` que o corta numa
grelha fixa de 128x160. **A grelha nao serve.** O atlas foi recortado de uma
imagem de apresentacao, e dai vem tudo o que esta ferramenta tem de resolver:

  1. o passo real entre figuras MUDA de estado para estado (o `idle` anda de
     128 em 128, o `run` de ~153) -- cortar de 128 em 128 parte os bonecos ao
     meio, que era o que se via na primeira tentativa;
  2. sobraram **linhas horizontais do fundo** (y 231-236, 415-418, 465-466 no
     atlas) que atravessam a folha toda e **colam as figuras umas as outras**
     -- e' por isso que uma analise de componentes dava um so' borrao de 768px
     de largura na linha 1;
  3. sobraram as **paredes de pedra** desenhadas nos frames de `wallslide`
     (duas tiras verticais estreitas, altas como a celula);
  4. as figuras nao estao centradas na celula, e uma tira que oscila em X faz
     a personagem tremer no ecra.

Receita: limpar (1) as linhas horizontais e (2) as paredes, procurar as
figuras por **componentes ligados** (ai ja' separam), agrupar cada corpo com
o po'/faiscas que lhe pertencem, e reescrever cada frame centrado no CORPO
(nao na espada, senao a personagem oscila quando da' o golpe).

    python tools/importar_rig_shadowblade.py [--contacto]

Escreve `assets/sprites/pixel/koliani_shadowblade/<estado>.png` (uma tira
horizontal por estado, virada a' DIREITA, como manda a convencao do projeto)
e, com `--contacto`, tambem `docs/img/rig_shadowblade.png` para se rever de
relance. Depois e' preciso `--headless --import` no Godot.
"""
from __future__ import annotations

import os
import sys
from collections import deque

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ATLAS = os.path.join(RAIZ, "assets", "sprites", "incoming", "shadowblade",
                     "shadowblade_hero_atlas.png")
DESTINO = os.path.join(RAIZ, "assets", "sprites", "pixel", "koliani_shadowblade")
CONTACTO = os.path.join(RAIZ, "docs", "img", "rig_shadowblade.png")

BANDA = 160          # altura de cada linha do atlas
LIM_ALFA = 24        # abaixo disto e' transparente para efeitos de analise

## Ordem das figuras no atlas (a mesma do `.tres` que veio com o pack).
## Os nomes sao os que `koliani.gd` espera nas tiras.
ORDEM = [
    ("idle", 4),
    ("run", 6),
    ("jump", 7),
    ("attack", 6),
    # o `.tres` do pack diz 3, mas o atlas so' tem DUAS poses de agachar --
    # sao 33 figuras, nao 34 (conferido na folha de contacto)
    ("crouch", 2),
    ("wallslide", 3),
    ("djump", 5),
]

## Tamanho do frame de saida. 112x160 chega para a figura mais larga depois de
## limpa (a maior media 144 px, mas 30 desses eram rasto do vizinho).
FRAME_W = 128
FRAME_H = 160

## Uma linha do atlas com mais de tantos px opacos nao pode ser personagem --
## e' fundo. (A figura mais larga ocupa ~150 px; 8 figuras dao ~700.)
LIMIAR_LINHA = 760
## Espessura maxima de uma banda de fundo: acima disto ja' e' desenho.
BANDA_MAX = 10
## Uma parede: tira vertical alta e estreita.
PAREDE_ALT_MIN = 130
PAREDE_LARG_MAX = 34
## Coluna opaca de alto a baixo da celula = parede (ver `apagar_paredes`).
PAREDE_COLUNA = 152
## Um "corpo" tem pelo menos isto; abaixo e' po', faisca ou rasto.
CORPO_MIN = 900
## Um fragmento a menos de tantos px de um corpo pertence-lhe.
COLA = 26
## Um pedaco mais estreito do que isto nao e' uma figura -- e' rasto solto.
SLIVER_MAX = 50
## Tamanho do frame NA TIRA FINAL -- ver `gravar_tira`. A arte vem a 128x160
## com a personagem a medir ~148 px; a 52x64 ela fica com ~59, que e' a
## escala a que os 100 niveis estao desenhados (o rig "cavaleiro" tinha 55 e
## a caixa de colisao mede 20x44).
SAIDA_W = 52
SAIDA_H = 64

## Cortes a' mao, por linha do atlas. Na linha 2 (o `attack`) o RASTO do golpe
## liga as figuras todas -- da' um so' componente de 894 px de largura, e nem
## a analise so' pelas pernas o separa, porque o chao da imagem de origem
## tambem ficou desenhado. Estes x foram medidos a' vista sobre a folha com
## regua (`docs/img/rig_shadowblade.png` mostra o resultado).
## Formato: linha -> lista de x onde CORTAR.
CORTES = {
    2: [138, 244, 396, 636, 752, 900],
}


def carregar() -> Image.Image:
    if not os.path.exists(ATLAS):
        raise SystemExit("nao encontrei o atlas: " + ATLAS)
    return Image.open(ATLAS).convert("RGBA")


# --- limpeza ---------------------------------------------------------------

def linhas_de_fundo(im: Image.Image) -> list[int]:
    """As linhas y que atravessam a folha e nao podem ser desenho."""
    w, h = im.size
    px = im.load()
    contagem = []
    for y in range(h):
        n = 0
        for x in range(w):
            if px[x, y][3] > LIM_ALFA:
                n += 1
        contagem.append(n)
    suspeitas = [y for y, n in enumerate(contagem) if n > LIMIAR_LINHA]
    # so' vale se a banda for FINA -- uma zona larga e' o chao dos frames
    boas = []
    for y in suspeitas:
        ini = y
        while ini > 0 and contagem[ini - 1] > LIMIAR_LINHA:
            ini -= 1
        fim = y
        while fim + 1 < h and contagem[fim + 1] > LIMIAR_LINHA:
            fim += 1
        if fim - ini + 1 <= BANDA_MAX:
            boas.append(y)
    return boas


def apagar_linhas(im: Image.Image, ys: list[int]) -> int:
    """Apaga so' os pixeis FINOS dessas linhas.

    Um pixel de fundo esta' sozinho na vertical; um que faca parte do boneco
    tem companhia acima e abaixo. Sem este teste, apagar a linha inteira
    abria um risco branco no meio de cada personagem.
    """
    px = im.load()
    w, h = im.size
    alvo = set(ys)
    fora = 0
    marcados = []
    for y in ys:
        for x in range(w):
            if px[x, y][3] <= LIM_ALFA:
                continue
            grosso = False
            for dy in (-4, -3, 3, 4):
                ny = y + dy
                if 0 <= ny < h and ny not in alvo and px[x, ny][3] > LIM_ALFA:
                    grosso = True
                    break
            if not grosso:
                marcados.append((x, y))
    for x, y in marcados:
        px[x, y] = (0, 0, 0, 0)
        fora += 1
    return fora


def apagar_paredes(im: Image.Image) -> int:
    """Apaga as paredes de pedra desenhadas nos frames de `wallslide`.

    Sao colunas OPACAS DE ALTO A BAIXO da celula (157 dos 160 px). A
    personagem nunca chega la': a coluna mais cheia de um boneco tem 146 px
    (medido nas quatro poses de `idle`), portanto 152 separa os dois casos
    sem tocar no desenho. Nesta arte a Koliani esta' sempre A' FRENTE da
    parede, nunca por cima dela -- por isso da' para levar a coluna inteira.
    """
    px = im.load()
    w, h = im.size
    fora = 0
    for r in range(h // BANDA):
        y0 = r * BANDA
        for x in range(w):
            n = 0
            for y in range(y0, y0 + BANDA):
                if px[x, y][3] > LIM_ALFA:
                    n += 1
            if n >= PAREDE_COLUNA:
                for y in range(y0, y0 + BANDA):
                    if px[x, y][3] > 0:
                        px[x, y] = (0, 0, 0, 0)
                        fora += 1
    return fora


def componentes(im: Image.Image, y0: int, y1: int) -> list[dict]:
    """Componentes ligados (8-vizinhanca) da banda [y0, y1)."""
    px = im.load()
    w = im.size[0]
    alt = y1 - y0
    vis = bytearray(w * alt)
    out = []
    for sy in range(alt):
        base = sy * w
        for sx in range(w):
            if vis[base + sx] or px[sx, y0 + sy][3] <= LIM_ALFA:
                continue
            q = deque([(sx, sy)])
            vis[base + sx] = 1
            pontos = []
            x0 = x1 = sx
            ry0 = ry1 = sy
            while q:
                cx, cy = q.popleft()
                pontos.append((cx, cy))
                if cx < x0:
                    x0 = cx
                if cx > x1:
                    x1 = cx
                if cy < ry0:
                    ry0 = cy
                if cy > ry1:
                    ry1 = cy
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < alt \
                                and not vis[ny * w + nx] \
                                and px[nx, y0 + ny][3] > LIM_ALFA:
                            vis[ny * w + nx] = 1
                            q.append((nx, ny))
            out.append({
                "n": len(pontos), "pontos": pontos,
                "x0": x0, "x1": x1, "y0": ry0, "y1": ry1,
            })
    return out


def cortar(cs: list[dict], xs: list[int]) -> list[dict]:
    """Parte os componentes nos x dados -- cada pedaco vira componente."""
    limites = [0] + sorted(xs) + [10 ** 9]
    out = []
    for c in cs:
        baldes: dict[int, list] = {}
        for x, y in c["pontos"]:
            k = 0
            while limites[k + 1] <= x:
                k += 1
            baldes.setdefault(k, []).append((x, y))
        for k in sorted(baldes):
            pts = baldes[k]
            out.append({
                "n": len(pts), "pontos": pts,
                "x0": min(p[0] for p in pts), "x1": max(p[0] for p in pts),
                "y0": min(p[1] for p in pts), "y1": max(p[1] for p in pts),
            })
    return out


def juntar_sobrepostos(corpos: list[dict]) -> list[dict]:
    """Um pedaco ESTREITO que se sobrepoe a um corpo e' o mesmo boneco.

    Acontece quando o rasto da lamina fica desligado do boneco por um pixel:
    a linha 0 dava 9 figuras em vez de 8, com uma tira de 33 px pelo meio.
    So' vale para pedacos estreitos -- na linha 1 ha' duas figuras a serio que
    se sobrepoem 5 px em X (o manto de uma passa por tras da outra), e juntar
    essas comia um frame.
    """
    out: list[dict] = []
    for c in corpos:
        larg = c["x1"] - c["x0"] + 1
        larg_ant = (out[-1]["x1"] - out[-1]["x0"] + 1) if out else 0
        estreito = min(larg, larg_ant) < SLIVER_MAX
        if out and c["x0"] <= out[-1]["x1"] and estreito:
            a = out[-1]
            a["pontos"] = a["pontos"] + c["pontos"]
            a["n"] += c["n"]
            a["x1"] = max(a["x1"], c["x1"])
            a["y0"] = min(a["y0"], c["y0"])
            a["y1"] = max(a["y1"], c["y1"])
        else:
            out.append(c)
    return out


def e_parede(c: dict) -> bool:
    alt = c["y1"] - c["y0"] + 1
    larg = c["x1"] - c["x0"] + 1
    return alt >= PAREDE_ALT_MIN and larg <= PAREDE_LARG_MAX


# --- figuras ---------------------------------------------------------------

def figuras_da_banda(im: Image.Image, r: int) -> list[dict]:
    """As figuras de uma linha do atlas, da esquerda para a direita.

    Cada figura e' um corpo (componente grande) mais os fragmentos que lhe
    ficam colados -- po' debaixo dos pes, faiscas da lamina, pontas do manto.
    """
    y0, y1 = r * BANDA, (r + 1) * BANDA
    cs = [c for c in componentes(im, y0, y1) if not e_parede(c)]
    if r in CORTES:
        cs = cortar(cs, CORTES[r])
    corpos = [c for c in cs if c["n"] >= CORPO_MIN]
    restos = [c for c in cs if c["n"] < CORPO_MIN]
    corpos.sort(key=lambda c: c["x0"])
    corpos = juntar_sobrepostos(corpos)
    for c in corpos:
        c["extra"] = []
        c["corpo_x0"], c["corpo_x1"] = c["x0"], c["x1"]
    for f in restos:
        melhor, dist = None, 10 ** 9
        for c in corpos:
            d = max(0, c["x0"] - f["x1"], f["x0"] - c["x1"]) \
                + max(0, c["y0"] - f["y1"], f["y0"] - c["y1"])
            if d < dist:
                melhor, dist = c, d
        if melhor is not None and dist <= COLA:
            melhor["extra"].append(f)
            melhor["x0"] = min(melhor["x0"], f["x0"])
            melhor["x1"] = max(melhor["x1"], f["x1"])
            melhor["y0"] = min(melhor["y0"], f["y0"])
            melhor["y1"] = max(melhor["y1"], f["y1"])
    for c in corpos:
        c["banda"] = r
    return corpos


def recortar(im: Image.Image, fig: dict) -> Image.Image:
    """Um frame de FRAME_W x FRAME_H com a figura centrada pelo CORPO.

    Centrar pelo bbox todo faria a personagem saltar de lado sempre que a
    espada saisse para fora; o corpo e' que manda.
    """
    y0 = fig["banda"] * BANDA
    quadro = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    src = im.load()
    dst = quadro.load()
    centro = (fig["corpo_x0"] + fig["corpo_x1"]) // 2
    desloc = FRAME_W // 2 - centro
    for c in [fig] + fig["extra"]:
        for x, y in c["pontos"]:
            nx = x + desloc
            if 0 <= nx < FRAME_W and 0 <= y < FRAME_H:
                dst[nx, y] = src[x, y0 + y]
    return quadro


# --- saida -----------------------------------------------------------------

def gravar_tira(frames: list[Image.Image], nome: str) -> str:
    """Grava a tira ja' A' ESCALA DO JOGO.

    A arte vem a 128x160 com a personagem a medir ~148 px de alto. O rig
    anterior ("cavaleiro") tinha-a com 55 px, e e' a esse tamanho que os 100
    niveis estao desenhados -- a caixa de colisao mede 20x44. Reduzir no
    Godot (`_corpo.scale = 0.4`) com filtro Nearest fazia a personagem
    cintilar a cada pixel de movimento; reduzir AQUI, com um filtro a serio,
    da' uma tira limpa que o jogo desenha a 1:1.
    """
    # cada frame e' reduzido SOZINHO e so' depois se monta a tira: reduzir a
    # tira inteira dava frames de 51,2 px, e `koliani.gd` corta as tiras por
    # `largura / n_frames` -- com uma largura fraccionaria as regioes saem
    # desalinhadas e a personagem "salta" de frame para frame.
    frames = [f.resize((SAIDA_W, SAIDA_H), Image.LANCZOS) for f in frames]
    tira = Image.new("RGBA", (SAIDA_W * len(frames), SAIDA_H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        tira.alpha_composite(f, (i * SAIDA_W, 0))
    os.makedirs(DESTINO, exist_ok=True)
    caminho = os.path.join(DESTINO, nome + ".png")
    tira.save(caminho)
    return caminho


def folha_de_contacto(tiras: dict[str, list[Image.Image]]) -> str:
    largura = max(len(v) for v in tiras.values()) * FRAME_W
    altura = len(tiras) * FRAME_H
    folha = Image.new("RGBA", (largura, altura), (26, 20, 32, 255))
    for i, (nome, frames) in enumerate(tiras.items()):
        for k, f in enumerate(frames):
            folha.alpha_composite(f, (k * FRAME_W, i * FRAME_H))
    os.makedirs(os.path.dirname(CONTACTO), exist_ok=True)
    folha.save(CONTACTO)
    return CONTACTO


def main() -> None:
    im = carregar()
    ys = linhas_de_fundo(im)
    n_fora = apagar_linhas(im, ys)
    print("linhas de fundo apagadas: %d linhas, %d pixeis" % (len(ys), n_fora))
    print("paredes de pedra apagadas: %d pixeis" % apagar_paredes(im))

    todas: list[dict] = []
    for r in range(im.size[1] // BANDA):
        fs = figuras_da_banda(im, r)
        print("  linha %d: %d figuras  x=%s" % (r, len(fs), [f["corpo_x0"] for f in fs]))
        todas.extend(fs)

    esperado = sum(n for _, n in ORDEM)
    print("figuras encontradas: %d (esperado %d)" % (len(todas), esperado))
    if len(todas) != esperado:
        print("!! a contagem nao bate certo -- ver a folha de contacto antes de usar")

    tiras: dict[str, list[Image.Image]] = {}
    i = 0
    for nome, n in ORDEM:
        frames = []
        for _ in range(n):
            if i < len(todas):
                frames.append(recortar(im, todas[i]))
                i += 1
        if frames:
            tiras[nome] = frames
            print("  %-10s %d frames -> %s" % (nome, len(frames), gravar_tira(frames, nome)))

    # `fall` nao vem no pack: sao os dois ultimos frames do salto (a subida ja'
    # acabou), que e' exactamente a pose de queda.
    if "jump" in tiras and len(tiras["jump"]) >= 2:
        queda = tiras["jump"][-2:]
        tiras["fall"] = queda
        print("  %-10s %d frames -> %s  (derivado do jump)"
              % ("fall", len(queda), gravar_tira(queda, "fall")))

    if "--contacto" in sys.argv:
        print("folha de contacto -> " + folha_de_contacto(tiras))


if __name__ == "__main__":
    main()
