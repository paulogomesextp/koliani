#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Importa o rig **Shadowblade** (arte do Paulo) para as tiras da Koliani.

O atlas `assets/sprites/incoming/shadowblade/shadowblade_hero_atlas.png` e' de
1024x800 e esta' numa grelha REGULAR de 8 colunas x 5 linhas de 128x160 -- a
mesma que o `shadowblade_hero_frames.tres` que veio com o pack declara. A
primeira versao desta ferramenta deitou a grelha fora e foi procurar as
figuras por componentes ligados; como a arte de celulas vizinhas se toca, isso
dava frames com DUAS Kolianis e frames com meio corpo ("parece que tem frame
drop e duplica kolianis" -- Paulo, 4 set 2026). A grelha estava certa desde o
inicio.

O que esta ferramenta faz, por celula:

  1. apaga as linhas horizontais de fundo que sobraram da imagem de origem
     (atravessam a folha toda e colam figuras umas as outras);
  2. apaga as paredes de pedra desenhadas nos frames de `wallslide`;
  3. apaga o **transbordo do vizinho** -- os bocados de outra figura que
     entram pela borda esquerda/direita da celula. E' isto que dava as
     Kolianis a dobrar;
  4. recorta TODAS as celulas pelo MESMO rectangulo. A arte ja' vem alinhada
     dentro da celula: recentrar figura a figura (o que se fazia antes) era o
     que fazia a personagem tremer de frame para frame.

Estados: a ordem das celulas e' a do `.tres` do pack (idle 4, run 6, jump 7,
attack 6, crouch 3, wall_slide 3, double_jump 5 = 34), mas os frames sao
REDISTRIBUIDOS por estados do jogo -- ver `ESTADOS`. Em particular o "jump" do
pack e' o arco completo (agachar -> impulso -> subida -> queda -> aterrar) e
da' `jump` + `fall` + `aterrar`, e a linha de ataque da' os QUATRO golpes do
combo em vez de uma so' animacao com um frame vazio pelo meio.

    python tools/importar_rig_shadowblade.py [--contacto]

Escreve `assets/sprites/pixel/koliani_shadowblade/<estado>.png` (tira
horizontal, virada a' DIREITA, como manda a convencao do projeto) e, com
`--contacto`, `docs/img/rig_shadowblade.png`. Depois e' preciso
`--headless --import` no Godot.
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

CEL_W, CEL_H = 128, 160     # a grelha do atlas
COLS, LINHAS = 8, 5
LIM_ALFA = 24               # abaixo disto conta como transparente

# --- limpeza ---------------------------------------------------------------

## Uma linha do atlas com mais de tantos px opacos nao pode ser personagem.
LIMIAR_LINHA = 760
## Espessura maxima de uma banda de fundo: acima disto ja' e' desenho.
BANDA_MAX = 10
## Coluna opaca de alto a baixo da celula = parede de pedra. A coluna mais
## cheia de um boneco tem 146 px (medido nas quatro poses de `idle`).
PAREDE_COLUNA = 152
## Transbordo do vizinho: um pedaco que ENCOSTA a' borda lateral da celula e
## cujo centro de massa esta' a menos disto da borda nao e' desta figura.
BORDA_TRANSBORDO = 30
## ... e um pedaco solto a mais do que isto do corpo tambem se deita fora.
LONGE = 46

# --- saida -----------------------------------------------------------------

## A arte vem com a personagem a medir ~148 px de alto na celula de 160. Os
## 100 niveis estao desenhados para uma Koliani de ~59 px (a caixa de colisao
## mede 20x44), por isso reduz-se aqui, com um filtro a serio, e o jogo
## desenha a tira a 1:1 (`SHADOW_ESCALA = 1.0` em `koliani.gd`).
ESCALA = 0.4
SAIDA_W = int(round(CEL_W * ESCALA))   # 51
SAIDA_H = int(round(CEL_H * ESCALA))   # 64

## Linha do chao dentro da celula: o artista pousou TODAS as poses de pe' em
## y=156 (conferido nas 4 do `idle`, nas 6 do `run` e nas 7 da linha do
## ataque). E' esta a referencia de todo o rig.
CHAO = 156
## Altura de referencia do centro de massa (media do `idle`/`run`). As poses
## NO AR foram desenhadas a flutuar para cima dentro da celula -- a subida do
## salto sobe 60 px so' no desenho. Isso somava-se ao salto da fisica e dava
## um boneco a saltitar: aqui trazem-se todas de volta a esta altura.
ALVO_CY = 84

## Cada frame do rig: de onde vem no atlas e como se ancora.
##
##   (banda, x0, x1, ancora, dx, dy)
##
## `banda` e' a linha de 160 px; `x0`/`x1` a janela (x1 exclusivo). Para quase
## tudo isso e' a celula da grelha. A LINHA DA CORRIDA e' a excecao: na arte
## de origem as figuras da corrida estao empacotadas com ~90 px de passo e
## SOBREPOEM-SE (a grelha de 128 apanha duas de cada vez, que era o que dava
## as "Kolianis a dobrar"); ai vao janelas medidas a' mao sobre a figura que
## ficou POR CIMA, que e' a unica que esta' inteira.
##
## `ancora`:
##   "nada"    -- fica onde o artista a pos (celulas da grelha ja' alinhadas)
##   "chao"    -- tronco ao meio e pes na linha do chao
##   "ar"      -- tronco ao meio e centro de massa a altura de `ALVO_CY`
## `dx`/`dy` afinam a' mao por cima disso.
CH, AR, NADA = "chao", "ar", "nada"

FRAMES: dict[str, tuple] = {
    # --- parado (celulas 0,0-0,3) -------------------------------------
    "idle1": (0, 0, 128, NADA, 0, 0),
    "idle2": (0, 128, 256, NADA, 0, 0),
    "idle3": (0, 256, 384, NADA, 0, 0),
    "idle4": (0, 384, 512, NADA, 0, 0),
    # --- corrida (janelas a' mao; ver o comentario acima) --------------
    # a arte tem 6 poses de corrida mas cada uma esta' DESENHADA DUAS VEZES,
    # com ~35 px de desvio, e as copias tapam-se umas a's outras. Estas cinco
    # janelas apanham a copia que ficou inteira; a 6.a pose e' a ultima da
    # linha e o atlas corta-a ao meio, por isso perde-se.
    "run1": (0, 500, 634, CH, 0, 0),     # contacto, braco a' frente
    "run2": (0, 655, 768, CH, 0, 0),     # lamina de fora
    "run3": (0, 900, 1000, CH, 0, 0),    # braco atras, perna a' frente
    "run4": (1, 0, 121, CH, 0, 0),       # impulso
    "run5": (1, 121, 241, CH, 0, 0),     # lamina de fora, passada larga
    # --- salto: subida, queda, aterragem ------------------------------
    "sobe1": (1, 384, 512, AR, 0, 0),
    "sobe2": (1, 512, 640, AR, 0, 0),
    "apice": (1, 640, 768, AR, 0, 0),
    "cai1":  (1, 768, 896, AR, 0, 0),
    "cai2":  (1, 896, 1024, AR, 0, 0),
    "impulso": (1, 256, 384, NADA, 0, 0),   # agachar antes de largar do chao
    "pousa":   (2, 0, 128, NADA, 0, 0),     # joelho no chao
    # --- espada -------------------------------------------------------
    "atk_arma":   (2, 896, 1024, NADA, 0, 0),   # lamina atras, a carregar
    "atk_baixo":  (2, 128, 256, NADA, 0, 0),    # corte descendente
    # a janela vai 12 px para a direita da celula: o arco roxo passa a
    # ponta para a celula seguinte e assim nao fica cortado a direito
    "atk_arco":   (2, 268, 396, NADA, 0, 0),    # arco roxo por cima
    "atk_estoca": (2, 384, 512, NADA, 0, 0),    # estocada de punho
    "atk_calma":  (2, 640, 768, NADA, 0, 0),    # recolher
    "atk_frente": (2, 768, 896, NADA, 0, 0),    # remate, lamina a' frente
    "atk_rasteira": (3, 0, 128, NADA, 0, 0),    # investida baixa
    # --- agachar ------------------------------------------------------
    "agacha": (3, 128, 256, NADA, 0, 0),
    # --- parede (a pedra ja' foi apagada por `apagar_paredes`) ---------
    "parede1": (3, 256, 384, CH, 0, -4),
    "parede2": (3, 384, 512, CH, 0, -4),
    "parede3": (3, 512, 640, CH, 0, -4),
    # --- salto duplo --------------------------------------------------
    "dj1": (3, 640, 768, AR, 0, 0),
    "dj2": (3, 768, 896, NADA, 0, 0),   # o rebentamento roxo nasce nos pes
    "dj3": (3, 896, 1024, AR, 0, 0),
    "dj4": (4, 0, 128, AR, 0, 0),
    "dj5": (4, 128, 256, NADA, 0, 0),
}

## O frame composto "estocada + raio": o corpo de `atk_estoca` com o feixe
## magenta da celula (2,4) trazido para a mao. Sozinha, essa celula nao tem
## personagem nenhuma -- usa-la como frame fazia a Koliani DESAPARECER a meio
## do ataque, que era metade do "frame drop" de que o Paulo se queixou.
RAIO_FEIXE = (2, 512, 640)
RAIO_DESLOC = -16

## Os frames de cada estado do jogo. Um frame pode servir mais do que um
## estado -- a arte tem 34 poses para 13 estados.
##
## A linha de ataque do pack tem QUATRO poses diferentes; junta-las todas numa
## so' animacao (o que se fazia) dava "sempre a mesma animacao" no combo. Aqui
## cada golpe do combo tem a sua.
ESTADOS: dict[str, list] = {
    "idle":      ["idle1", "idle2", "idle3", "idle4"],
    "run":       ["run1", "run2", "run3", "run4", "run5"],
    "jump":      ["sobe1", "sobe2", "apice"],
    "fall":      ["cai1", "cai2"],
    "aterrar":   ["pousa", "impulso"],
    # combo de espada -- quatro golpes VISIVELMENTE diferentes
    "attack":    ["atk_arma", "atk_baixo", "atk_frente"],       # corte descendente
    "attack2":   ["atk_baixo", "atk_arco", "atk_calma"],        # arco por cima
    "attack3":   ["atk_estoca", "RAIO", "atk_calma"],           # estocada + raio
    "attack4":   ["atk_arma", "atk_rasteira", "atk_frente", "atk_calma"],
    # agachar e' uma pose parada: um so' frame, senao a Koliani
    # levantava-se e voltava a agachar-se em ciclo
    "crouch":    ["agacha"],
    "wallslide": ["parede1", "parede2", "parede3"],
    "borda":     ["parede1", "parede2"],   # a mesma pega, sem escorregar
    # o rebentamento roxo abre o salto duplo; a pose de aterrar (dj5)
    # nao entra aqui -- ficava congelada no ar no fim da animacao
    "djump":     ["dj2", "dj1", "dj3", "dj4"],
}


def carregar() -> Image.Image:
    if not os.path.exists(ATLAS):
        raise SystemExit("nao encontrei o atlas: " + ATLAS)
    return Image.open(ATLAS).convert("RGBA")


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
    boas = []
    for y in suspeitas:
        ini = y
        while ini > 0 and contagem[ini - 1] > LIMIAR_LINHA:
            ini -= 1
        fim = y
        while fim + 1 < h and contagem[fim + 1] > LIMIAR_LINHA:
            fim += 1
        if fim - ini + 1 <= BANDA_MAX:   # so' vale se a banda for FINA
            boas.append(y)
    return boas


def apagar_linhas(im: Image.Image, ys: list[int]) -> int:
    """Apaga so' os pixeis FINOS dessas linhas.

    Um pixel de fundo esta' sozinho na vertical; um que faca parte do boneco
    tem companhia acima e abaixo. Sem este teste, apagar a linha inteira abria
    um risco no meio de cada personagem.
    """
    px = im.load()
    w, h = im.size
    alvo = set(ys)
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
    return len(marcados)


def apagar_paredes(im: Image.Image) -> int:
    """Apaga as paredes de pedra desenhadas nos frames de `wallslide`.

    Sao colunas OPACAS DE ALTO A BAIXO da celula (157 dos 160 px); nenhuma
    coluna de um boneco passa dos 146. Nesta arte a Koliani esta' sempre A'
    FRENTE da parede, nunca por cima dela, por isso da' para levar a coluna
    inteira.
    """
    px = im.load()
    w, h = im.size
    fora = 0
    for r in range(h // CEL_H):
        y0 = r * CEL_H
        for x in range(w):
            n = 0
            for y in range(y0, y0 + CEL_H):
                if px[x, y][3] > LIM_ALFA:
                    n += 1
            if n >= PAREDE_COLUNA:
                for y in range(y0, y0 + CEL_H):
                    if px[x, y][3] > 0:
                        px[x, y] = (0, 0, 0, 0)
                        fora += 1
    return fora


def componentes(quadro: Image.Image) -> list[dict]:
    """Componentes ligados (8-vizinhanca) de um quadro solto."""
    w, h = quadro.size
    px = quadro.load()
    vis = bytearray(w * h)
    out = []
    for sy in range(h):
        base = sy * w
        for sx in range(w):
            if vis[base + sx] or px[sx, sy][3] <= LIM_ALFA:
                continue
            q = deque([(sx, sy)])
            vis[base + sx] = 1
            pontos = []
            x0 = x1 = sx
            y0 = y1 = sy
            soma_x = 0
            while q:
                cx, cy = q.popleft()
                pontos.append((cx, cy))
                soma_x += cx
                x0, x1 = min(x0, cx), max(x1, cx)
                y0, y1 = min(y0, cy), max(y1, cy)
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h \
                                and not vis[ny * w + nx] \
                                and px[nx, ny][3] > LIM_ALFA:
                            vis[ny * w + nx] = 1
                            q.append((nx, ny))
            out.append({"n": len(pontos), "pontos": pontos,
                        "cx": soma_x / float(len(pontos)),
                        "x0": x0, "x1": x1, "y0": y0, "y1": y1})
    return out


def limpar_celula(quadro: Image.Image) -> Image.Image:
    """Deixa na celula SO' a figura que lhe pertence.

    O corpo e' o maior componente. Fica tambem o que lhe anda colado (po' dos
    pes, faiscas da lamina, arco do golpe). Sai o que encosta a' borda lateral
    com o centro de massa junto a essa borda -- e' arte da celula do lado -- e
    o que fica longe do corpo.
    """
    cs = componentes(quadro)
    if not cs:
        return quadro
    corpo = max(cs, key=lambda c: c["n"])
    limpo = Image.new("RGBA", quadro.size, (0, 0, 0, 0))
    src, dst = quadro.load(), limpo.load()
    w = quadro.size[0]
    for c in cs:
        if c is not corpo:
            encosta_esq = c["x0"] <= 0 and c["cx"] < BORDA_TRANSBORDO
            encosta_dir = c["x1"] >= w - 1 and c["cx"] > w - 1 - BORDA_TRANSBORDO
            if encosta_esq or encosta_dir:
                continue
            dist = max(0, corpo["x0"] - c["x1"], c["x0"] - corpo["x1"]) \
                + max(0, corpo["y0"] - c["y1"], c["y0"] - corpo["y1"])
            if dist >= LONGE:
                continue
        for x, y in c["pontos"]:
            dst[x, y] = src[x, y]
    return limpo


def recortar(im: Image.Image, janela: tuple) -> Image.Image:
    """Uma janela do atlas, ja' limpa, na largura que tiver."""
    banda, x0, x1 = janela
    return limpar_celula(im.crop((x0, banda * CEL_H, x1, (banda + 1) * CEL_H)))


## A ancora horizontal e' a **mediana do tronco** -- a coluna que parte ao
## meio os pixeis da faixa entre 35% e 62% da altura do corpo (peito e anca).
## O centro de massa do boneco todo nao serve: a lamina que brilha e o manto
## que voa sao compridos e finos e puxam-no 20 px para o lado, o que fazia a
## Koliani deslizar de lado a cada frame da corrida. Medido nas 4 poses do
## `idle`, a mediana do tronco da' 61-62 -- praticamente sem variacao.
TRONCO_LO, TRONCO_HI = 0.35, 0.62
ALVO_CX = 62


def medir(quadro: Image.Image) -> dict:
    """Corpo do quadro: bbox, centro de massa e mediana do tronco. So' do
    maior componente, para o po' dos pes e as faiscas nao puxarem a ancora."""
    cs = componentes(quadro)
    if not cs:
        return {"tronco": quadro.size[0] / 2.0, "cy": CEL_H / 2.0, "y1": CHAO}
    b = max(cs, key=lambda c: c["n"])
    alt = b["y1"] - b["y0"] + 1
    lo = b["y0"] + int(alt * TRONCO_LO)
    hi = b["y0"] + int(alt * TRONCO_HI)
    xs = sorted(p[0] for p in b["pontos"] if lo <= p[1] <= hi)
    return {"tronco": float(xs[len(xs) // 2]) if xs
            else sum(p[0] for p in b["pontos"]) / float(b["n"]),
            "cy": sum(p[1] for p in b["pontos"]) / float(b["n"]),
            "y1": b["y1"]}


def montar_frame(im: Image.Image, spec: tuple) -> Image.Image:
    """Poe uma janela do atlas num quadro de 128x160, ancorada como manda a
    tabela `FRAMES`. O quadro final e' SEMPRE do mesmo tamanho e a ancoragem
    e' sempre a mesma dentro de cada estado -- e' isso que mantem a Koliani
    quieta em vez de saltitar de frame para frame."""
    banda, x0, x1, ancora, dx, dy = spec
    bruto = recortar(im, (banda, x0, x1))
    quadro = Image.new("RGBA", (CEL_W, CEL_H), (0, 0, 0, 0))
    if ancora == NADA:
        # a janela e' uma celula da grelha: ja' esta' onde o artista a pos
        ox, oy = dx, dy
    else:
        m = medir(bruto)
        ox = int(round(ALVO_CX - m["tronco"])) + dx
        oy = (CHAO - m["y1"] if ancora == CH else int(round(ALVO_CY - m["cy"]))) + dy
    # `paste` com mascara (e nao `alpha_composite`) porque a ancora pode dar
    # um deslocamento NEGATIVO -- o quadro esta' vazio, o resultado e' o mesmo
    quadro.paste(bruto, (ox, oy), bruto)
    return quadro


def frame_raio(im: Image.Image) -> Image.Image:
    """Estocada com o raio magenta a nascer do punho."""
    corpo = montar_frame(im, FRAMES["atk_estoca"])
    feixe = recortar(im, RAIO_FEIXE)
    corpo.paste(feixe.crop((-RAIO_DESLOC, 0, CEL_W, CEL_H)), (0, 0),
                feixe.crop((-RAIO_DESLOC, 0, CEL_W, CEL_H)))
    return corpo


def montar(im: Image.Image) -> dict:
    quadros = {n: montar_frame(im, s) for n, s in FRAMES.items()}
    quadros["RAIO"] = frame_raio(im)
    return {nome: [quadros[k] for k in chaves] for nome, chaves in ESTADOS.items()}


def gravar_tira(frames: list, nome: str) -> str:
    """Grava a tira ja' A' ESCALA DO JOGO.

    Cada frame e' reduzido SOZINHO e so' depois se monta a tira: reduzir a
    tira inteira dava frames fraccionarios, e `koliani.gd` corta as tiras por
    `largura / n_frames` -- com uma largura fraccionaria as regioes saem
    desalinhadas e a personagem "salta" de frame para frame.

    Nao ha' recentragem nenhuma: todas as celulas sao recortadas pelo MESMO
    rectangulo, que e' o que mantem a personagem quieta no ecra.
    """
    reduzidos = [f.resize((SAIDA_W, SAIDA_H), Image.LANCZOS) for f in frames]
    tira = Image.new("RGBA", (SAIDA_W * len(reduzidos), SAIDA_H), (0, 0, 0, 0))
    for i, f in enumerate(reduzidos):
        tira.alpha_composite(f, (i * SAIDA_W, 0))
    os.makedirs(DESTINO, exist_ok=True)
    caminho = os.path.join(DESTINO, nome + ".png")
    tira.save(caminho)
    return caminho


def folha_de_contacto(tiras: dict) -> str:
    """Todos os estados de relance, com a linha do chao e o eixo do corpo
    desenhados -- e' assim que se ve' se algum frame esta' desalinhado."""
    from PIL import ImageDraw
    largura = max(len(v) for v in tiras.values()) * CEL_W
    altura = len(tiras) * CEL_H
    folha = Image.new("RGBA", (largura, altura), (26, 20, 32, 255))
    d = ImageDraw.Draw(folha)
    for i, nome in enumerate(tiras):
        y0 = i * CEL_H
        d.line([(0, y0 + CHAO), (largura, y0 + CHAO)], fill=(90, 200, 130, 160))
        d.text((4, y0 + 4), nome, fill=(255, 220, 80, 255))
        for k, f in enumerate(tiras[nome]):
            folha.alpha_composite(f, (k * CEL_W, y0))
            d.line([(k * CEL_W + CEL_W // 2, y0), (k * CEL_W + CEL_W // 2, y0 + CEL_H)],
                   fill=(255, 220, 80, 60))
    os.makedirs(os.path.dirname(CONTACTO), exist_ok=True)
    folha.save(CONTACTO)
    return CONTACTO


def main() -> None:
    im = carregar()
    ys = linhas_de_fundo(im)
    print("linhas de fundo apagadas: %d linhas, %d pixeis" % (len(ys), apagar_linhas(im, ys)))
    print("paredes de pedra apagadas: %d pixeis" % apagar_paredes(im))

    tiras = montar(im)
    for nome in tiras:
        print("  %-10s %d frames -> %s"
              % (nome, len(tiras[nome]), gravar_tira(tiras[nome], nome)))
    if "--contacto" in sys.argv:
        print("folha de contacto -> " + folha_de_contacto(tiras))


if __name__ == "__main__":
    main()
