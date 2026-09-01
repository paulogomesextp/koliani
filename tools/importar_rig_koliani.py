#!/usr/bin/env python3
"""Importa um rig de animacao pronto (Ansimuz "Gothicvania Church", CC0) para
a Koliani, recolorido para a paleta roxo/luar do key_art.

Le as tiras de `assets/sprites/incoming/.../gothicvania church files/.../player/`
(ja sao tiras horizontais, 82px/frame) e grava-as em
`assets/sprites/pixel/koliani_gothic/<estado>.png` com um duotone roxo.

Uso:  python tools/importar_rig_koliani.py
Depois: reimportar no Godot e por RIG = "gothic" em koliani.gd.
Sem numpy (so PIL) -- como o tools/gerar_audio.py.
"""
from pathlib import Path
from PIL import Image, ImageOps

RAIZ = Path(__file__).resolve().parent.parent
SRC = RAIZ / "assets/sprites/incoming/ansimuz-parallax/gothicvania church files/Assets/SPRITES/player"
DST = RAIZ / "assets/sprites/pixel/koliani_gothic"

# estado da Koliani  ->  pasta do rig (usa o spritesheet.png de cada uma)
MAPA = {
    "idle": "Idle",
    "run": "Walk",
    "jump": "jump",
    "fall": "fall",
    "attack": "Punch",
    "crouch": "chrouch",
    "wallslide": "fall",
    "djump": "jump",
}

# duotone "luar roxo" (sombra -> meio -> luz), tirado do branding/key_art
SOMBRA = (26, 18, 46)      # indigo profundo
MEIO = (108, 63, 160)      # roxo
LUZ = (230, 213, 255)      # lavanda quase branca


def recolor(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    alpha = img.getchannel("A")
    cinza = ImageOps.grayscale(img)
    # leve boost de contraste para o duotone nao achatar
    cinza = ImageOps.autocontrast(cinza, cutoff=2)
    duo = ImageOps.colorize(cinza, black=SOMBRA, white=LUZ, mid=MEIO)
    duo = duo.convert("RGBA")
    duo.putalpha(alpha)
    return duo


def main() -> None:
    if not SRC.exists():
        raise SystemExit(f"nao encontrei o rig em {SRC}")
    DST.mkdir(parents=True, exist_ok=True)
    for estado, pasta in MAPA.items():
        tira = SRC / pasta / "spritesheet.png"
        if not tira.exists():
            print(f"  ! sem {tira}")
            continue
        out = recolor(Image.open(tira))
        out.save(DST / f"{estado}.png")
        print(f"  {estado:9s} <- {pasta:12s} {out.size}")
    print(f"feito -> {DST}")


if __name__ == "__main__":
    main()
