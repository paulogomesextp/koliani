#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Recorta e RECOLORE o kit de HUD para a paleta gotica do Koliani.

A HUD nao tinha arte nenhuma: era toda `Label` + `StyleBoxFlat` desenhados
por codigo (`scripts/controlos_toque.gd`). O kit certo ja' estava no repo, do
mesmo pack anokolisa que da' o terreno da floresta -- so' que e' de fantasia
clara (pergaminho bege, madeira, verde/azul/amarelo) e o jogo e' gotico de
luar com brilho magenta. Por isso nao se copia: RECOLORE-SE.

Como se recolore sem perder o pixel-art: para cada pixel mede-se a
luminancia e mapeia-se essa luminancia numa RAMPA de 5 cores da paleta
nova (`RAMPAS`). O desenho -- a moldura preta, o relevo, o granulado da
pedra -- fica todo; so' muda a cor. Um `modulate` no Godot nao servia: ele
multiplica, e sobre um bege claro devolve sempre pastel.

Tudo sai a 3x (NEAREST): a 1280x720 uma moldura de 1 px desaparecia, e uma
`NinePatchRect` nao escala os cantos. A 3x a moldura le'-se e os cantos
ficam iguais em qualquer tamanho de caixa.

Saida: `assets/ui/*.png`.

  python tools/gerar_ui.py              # grava tudo
  python tools/gerar_ui.py --preview    # + _preview_ui.png (folha de contacto)
"""

from __future__ import annotations

import os
import sys

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FOLHA = os.path.join(
    RAIZ, "assets", "sprites", "incoming", "anokolisa",
    "Legacy-Fantasy - High Forest 2.3", "HUD", "Base-01.png")
SAIDA = os.path.join(RAIZ, "assets", "ui")

ESCALA = 3

# --- paleta ---------------------------------------------------------
#
# Rampas de 5 tons, do mais escuro (moldura) ao mais claro (brilho). Saem
# do `key_art.png`: pedra roxa-azulada ao luar, brilho magenta.
RAMPAS = {
    # painel de pedra: o fundo de tudo o que e' caixa da HUD
    "pedra":   [(10, 7, 16), (28, 20, 40), (46, 34, 62), (66, 50, 86), (92, 74, 116)],
    # calha das barras -- quase preta, so' a moldura e' que se ve'
    "calha":   [(6, 4, 9), (14, 10, 19), (22, 15, 29), (30, 21, 39), (44, 32, 56)],
    # placa do cabecalho de nivel: pedra mais clara, para o texto assentar
    "placa":   [(12, 8, 18), (40, 28, 54), (62, 44, 82), (86, 64, 110), (120, 96, 148)],
    # placa do chefe: a mesma pedra tocada a sangue
    "chefe":   [(12, 5, 8), (44, 12, 18), (68, 20, 28), (96, 30, 40), (132, 48, 60)],
    # madeira escura (listas, caixas de menu)
    "madeira": [(9, 6, 8), (34, 22, 22), (52, 34, 32), (72, 48, 44), (98, 68, 60)],
    # icones: osso palido, para se lerem sobre a pedra
    "osso":    [(10, 7, 14), (74, 66, 84), (128, 118, 140), (186, 176, 198), (238, 232, 246)],
    # icone de essencia: magenta
    "magenta": [(24, 4, 20), (92, 14, 74), (150, 28, 120), (206, 60, 170), (255, 140, 226)],
}

# --- pecas do kit ---------------------------------------------------
#
# (x, y, w, h) na folha original de 432x304. O painel de pergaminho vem em
# quatro tamanhos colados uns aos outros: o quadrado 64x64 (o unico que
# serve de nine-patch), uma coluna, uma faixa e um quadradinho de 16x16.
PAINEL_GRANDE = (0, 0, 64, 64)
PAINEL_SELO = (64, 64, 16, 16)
# A madeira vem no MESMO arranjo de quatro paineis, mas o quadrado dela e'
# 48x48, nao 64x64. O recorte antigo (64x64) levava junto a coluna da
# direita e a faixa de baixo, e no Godot a nine-patch saia AOS BOCADOS --
# os botoes do rodape do seletor desenhavam-se como tres blocos soltos.
# Medido pelas divisorias pretas da folha: x = 16 | 64 | 79, y = 224 | 272 | 287.
PAINEL_MADEIRA = (16, 224, 48, 48)

ICONES = {
    "ico_caveira": (4, 259, 8, 10),
    "ico_relogio": (4, 275, 9, 9),
    "ico_casa": (3, 243, 10, 9),
    "ico_aviso": (7, 212, 2, 8),
    "ico_pausa": (5, 149, 6, 7),
    "ico_x": (20, 149, 7, 7),
    "ico_mais": (5, 165, 6, 6),
    "ico_seta_dir": (6, 180, 4, 7),
    "ico_seta_esq": (5, 196, 4, 7),
    "ico_coroa": (33, 193, 14, 13),
    "ico_engrenagem": (49, 209, 14, 13),
    "ico_losango": (140, 60, 24, 24),
}

# Margem da nine-patch dos paineis, em px da folha ORIGINAL. Quem os monta
# multiplica por ESCALA (ver `UI.MARGEM_PAINEL` em scripts/ui.gd).
MARGEM_PAINEL = 10
MARGEM_SELO = 5


def luminancia(r: int, g: int, b: int) -> float:
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255.0


## Abaixo desta luminancia o pixel e' MOLDURA, nao corpo: o kit desenha as
## molduras a preto e o corpo a bege claro.
LIMIAR_MOLDURA = 0.22


def _mistura(rampa: list, f: float):
    """Cor a `f` (0..1) ao longo da rampa, interpolada entre os tons."""
    n = len(rampa) - 1
    pos = max(0.0, min(1.0, f)) * n
    i = min(int(pos), n - 1)
    t = pos - i
    c0, c1 = rampa[i], rampa[i + 1]
    return (int(c0[0] + (c1[0] - c0[0]) * t),
            int(c0[1] + (c1[1] - c0[1]) * t),
            int(c0[2] + (c1[2] - c0[2]) * t))


def recolorir(img: Image.Image, rampa: list) -> Image.Image:
    """Mapeia a luminancia de cada pixel na `rampa` (5 tons), guardando o alfa.

    O corpo do painel do kit e' bege quase liso: se se mapear a luminancia
    crua, tudo cai no topo da rampa e o painel sai CHAPADO, sem relevo. Por
    isso o corpo e' ESTICADO -- normaliza-se o intervalo real de luminancia
    do corpo para os tons 1..4 -- e a moldura (preta) e' fixada no tom 0.
    """
    src = img.load()
    corpo = [luminancia(*src[x, y][:3])
             for y in range(img.height) for x in range(img.width)
             if src[x, y][3] > 0 and luminancia(*src[x, y][:3]) >= LIMIAR_MOLDURA]
    lo, hi = (min(corpo), max(corpo)) if corpo else (0.0, 1.0)
    if hi - lo < 0.02:          # corpo liso: cai a meio da rampa
        lo, hi = lo - 0.5, hi + 0.5

    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    dst = out.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = src[x, y]
            if a == 0:
                continue
            f = luminancia(r, g, b)
            if f < LIMIAR_MOLDURA:
                cor = rampa[0]
            else:
                # o corpo ocupa 0.35..0.95 da rampa: esticado o suficiente
                # para o relevo se ver, sem transformar o granulado em ruido
                cor = _mistura(rampa, 0.35 + 0.60 * (f - lo) / (hi - lo))
            dst[x, y] = (cor[0], cor[1], cor[2], a)
    return out


def silhueta(img: Image.Image, rampa: list) -> Image.Image:
    """Icone chapado + contorno escuro de 1 px a toda a volta.

    Os icones do kit sao silhuetas de UMA cor escura. Passados pela rampa
    saiam pretos sobre pedra preta -- nao se viam. Aqui pinta-se o interior
    com o tom claro da rampa e desenha-se a moldura por fora, para se lerem
    sobre qualquer fundo.
    """
    w, h = img.width + 2, img.height + 2
    src = img.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dst = out.load()
    cheio = rampa[4]
    brilho = tuple(int(c + (255 - c) * 0.45) for c in cheio)
    contorno = rampa[0]
    for y in range(img.height):
        for x in range(img.width):
            if src[x, y][3] < 96:
                continue
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    px, py = x + 1 + dx, y + 1 + dy
                    if dst[px, py][3] == 0:
                        dst[px, py] = (contorno[0], contorno[1], contorno[2], 255)
    for y in range(img.height):
        for x in range(img.width):
            if src[x, y][3] < 96:
                continue
            # linha de cima mais clara: da' volume sem desenhar sombra
            topo = y == 0 or src[x, y - 1][3] < 96
            c = brilho if topo else cheio
            dst[x + 1, y + 1] = (c[0], c[1], c[2], 255)
    return out


def ampliar(img: Image.Image, z: int = ESCALA) -> Image.Image:
    return img.resize((img.width * z, img.height * z), Image.NEAREST)


def peca(rect, rampa_id: str, icone: bool = False) -> Image.Image:
    x, y, w, h = rect
    folha = Image.open(FOLHA).convert("RGBA")
    corte = folha.crop((x, y, x + w, y + h))
    trata = silhueta if icone else recolorir
    return ampliar(trata(corte, RAMPAS[rampa_id]))


# --- enchimento das barras ------------------------------------------
#
# O kit traz enchimentos de 2 e 4 px de altura -- num ecra' de 720 isso e'
# um fio. Desenha-se aqui de raiz, em BRANCO, com o relevo de pixel-art
# (aresta viva em cima, corpo, sombra em baixo) e um risco de brilho: a cor
# entra depois pelo `modulate_color` da `StyleBoxTexture`, uma tinta por barra.
## GOTCHA: o enchimento tem de ser MAIS ALTO do que qualquer barra do HUD.
## A 8 px (24 na arte final) a barra de Vida, que tem 26, nao desenhava
## NADA -- nem sequer com o modo `STRETCH`; a de Energia, com 18, desenhava.
## Uma `StyleBoxTexture` esticada para ALEM da altura da textura fica em
## branco. A 16 px (48 na arte final) todas as barras esmagam a textura em
## vez de a esticarem, que e' o sentido que funciona.
def enchimento(altura: int = 16, largura: int = 24) -> Image.Image:
    img = Image.new("RGBA", (largura, altura), (0, 0, 0, 0))
    px = img.load()
    for y in range(altura):
        f = y / max(altura - 1, 1)
        if y == 0:
            tom = 255            # aresta viva
        elif y == altura - 1:
            tom = 96             # sombra em baixo
        elif y == altura - 2:
            tom = 130
        else:
            tom = int(206 - 66 * f)
        for x in range(largura):
            px[x, y] = (tom, tom, tom, 255)
    # risco de brilho na 2.a linha, com falhas -- tira o ar de degrade'
    for x in range(largura):
        if x % 5 != 3:
            px[x, 1] = (255, 255, 255, 255)
    return ampliar(img)


# --- coracao (arte propria: o kit nao traz nenhum) -------------------
CORACAO = [
    "..XX.XX..",
    ".XHHXHHX.",
    "XHHHHHHHX",
    "XHHHHHHHX",
    ".XHHHHHX.",
    "..XHHHX..",
    "...XHX...",
    "....X....",
]


def coracao(cheio: bool = True) -> Image.Image:
    img = Image.new("RGBA", (9, 8), (0, 0, 0, 0))
    px = img.load()
    borda = (26, 6, 12, 255)
    corpo = (196, 32, 48, 255) if cheio else (48, 30, 40, 255)
    alto = (255, 118, 128, 255) if cheio else (72, 50, 62, 255)
    for y, linha in enumerate(CORACAO):
        for x, c in enumerate(linha):
            if c == "X":
                px[x, y] = borda
            elif c == "H":
                px[x, y] = alto if (y <= 2 and 1 <= x <= 3) else corpo
    return ampliar(img)


def gravar(img: Image.Image, nome: str) -> None:
    img.save(os.path.join(SAIDA, nome + ".png"))
    print("  %-22s %dx%d" % (nome + ".png", img.width, img.height))


def folha_de_contacto() -> None:
    """Mosaico de tudo o que se gerou, para ver de relance."""
    nomes = sorted(f for f in os.listdir(SAIDA)
                   if f.endswith(".png") and not f.startswith("_"))
    cel = 200
    cols = 6
    linhas = (len(nomes) + cols - 1) // cols
    folha = Image.new("RGBA", (cols * cel, linhas * cel), (18, 12, 26, 255))
    for i, n in enumerate(nomes):
        im = Image.open(os.path.join(SAIDA, n)).convert("RGBA")
        if im.width > cel - 16 or im.height > cel - 16:
            im.thumbnail((cel - 16, cel - 16), Image.NEAREST)
        cx = (i % cols) * cel + (cel - im.width) // 2
        cy = (i // cols) * cel + (cel - im.height) // 2
        folha.alpha_composite(im, (cx, cy))
    destino = os.path.join(SAIDA, "_preview_ui.png")
    folha.save(destino)
    print("preview -> " + destino)


def main() -> int:
    if not os.path.isfile(FOLHA):
        print("ERRO: falta a folha do kit:\n  " + FOLHA, file=sys.stderr)
        return 1
    os.makedirs(SAIDA, exist_ok=True)
    print("kit de HUD -> assets/ui/  (recolorido, %dx)" % ESCALA)

    # paineis (nine-patch)
    gravar(peca(PAINEL_GRANDE, "pedra"), "painel_pedra")
    gravar(peca(PAINEL_GRANDE, "placa"), "painel_placa")
    gravar(peca(PAINEL_GRANDE, "chefe"), "painel_chefe")
    gravar(peca(PAINEL_GRANDE, "calha"), "calha")
    gravar(peca(PAINEL_MADEIRA, "madeira"), "painel_madeira")
    gravar(peca(PAINEL_SELO, "placa"), "selo")

    # enchimento das barras (branco -- tinge-se no Godot)
    gravar(enchimento(), "enchimento")

    # icones
    for nome, rect in ICONES.items():
        rampa = "magenta" if nome == "ico_losango" else "osso"
        gravar(peca(rect, rampa, icone=True), nome)

    # coracao (arte propria)
    gravar(coracao(True), "ico_coracao")
    gravar(coracao(False), "ico_coracao_vazio")

    if "--preview" in sys.argv:
        folha_de_contacto()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
