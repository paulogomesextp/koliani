#!/usr/bin/env python3
"""Galeria de Conceitos (extra da Loja `extra_galeria_conceitos`): copia as
pranchas aprovadas de `docs/art_direction/regions/` (que NÃO vão no export)
para `assets/ui/galeria/` em JPG, que é o que o jogo lê. Correr depois de
aprovar/mudar uma prancha:

    python tools/preparar_galeria.py

A ordem e o desbloqueio das páginas vivem em `scripts/galeria.gd` (PAGINAS);
os nomes dos ficheiros têm de bater certo com essa lista.
"""
import os
from PIL import Image

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
REG = os.path.join(RAIZ, "docs", "art_direction", "regions")
SAIDA = os.path.join(RAIZ, "assets", "ui", "galeria")
QUALIDADE = 80
LARGURA_MAX = 1536

# (ficheiro de saída, origem relativa à raiz)
PAGINAS = [("key_art", "assets/branding/menu_bg.png"),
           ("koliani_ref", "assets/branding/koliani_ref_nova.png")]
for r, nomes in [(2, ["concept_environment_01", "concept_environment_02", "boss_pack"]),
                 (3, ["concept_environment", "boss_pack"]),
                 (4, ["concept_environment", "boss_pack"])]:
    for n in nomes:
        PAGINAS.append(("r%02d_%s" % (r, n), "docs/art_direction/regions/region_%02d/%s.png" % (r, n)))
for r in range(5, 21):
    PAGINAS.append(("r%02d_master_production_board" % r,
                    "docs/art_direction/regions/region_%02d/master_production_board.png" % r))


def main():
    os.makedirs(SAIDA, exist_ok=True)
    total = 0
    for nome, origem in PAGINAS:
        im = Image.open(os.path.join(RAIZ, origem)).convert("RGB")
        if im.width > LARGURA_MAX:
            im = im.resize((LARGURA_MAX, round(im.height * LARGURA_MAX / im.width)), Image.LANCZOS)
        dest = os.path.join(SAIDA, nome + ".jpg")
        im.save(dest, quality=QUALIDADE, optimize=True, progressive=False)
        total += os.path.getsize(dest)
        print("%-40s %dx%d" % (nome + ".jpg", im.width, im.height))
    print("total: %.1f MB em %d paginas" % (total / 1e6, len(PAGINAS)))



# --- preview do item na Loja (346x130, como as outras previews) -----------
PREVIEW = os.path.join(RAIZ, "assets", "ui", "shop", "galeria", "preview.png")
# (origem, recorte na imagem original) -- três "provas" lado a lado
RECORTES = [
    ("assets/branding/menu_bg.png", (430, 170, 990, 782)),
    ("docs/art_direction/regions/region_03/boss_pack.png", (455, 12, 725, 308)),
    ("docs/art_direction/regions/region_12/master_production_board.png", (1086, 596, 1326, 860)),
]


def preview():
    W, H = 346, 130
    fundo = (20, 10, 18)
    carmesim = (226, 34, 60)
    im = Image.new("RGB", (W, H), fundo)
    tw, th, gap = 104, 114, 12
    x0 = (W - (3 * tw + 2 * gap)) // 2
    y0 = (H - th) // 2
    for i, (orig, caixa) in enumerate(RECORTES):
        src = Image.open(os.path.join(RAIZ, orig)).convert("RGB").crop(caixa)
        src = src.resize((tw - 4, th - 4), Image.LANCZOS)
        x = x0 + i * (tw + gap)
        # passe-partout: fio carmesim, filete escuro, a imagem
        im.paste(Image.new("RGB", (tw, th), carmesim), (x, y0))
        im.paste(Image.new("RGB", (tw - 2, th - 2), (8, 4, 8)), (x + 1, y0 + 1))
        im.paste(src, (x + 2, y0 + 2))
    os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
    im.save(PREVIEW)
    print("preview:", os.path.relpath(PREVIEW, RAIZ))


if __name__ == "__main__":
    main()
    preview()
