#!/usr/bin/env python3
"""Monta o rig do GOLEM DAS FALESIAS (N06) A PARTIR DA PRANCHA APROVADA.

    python3 tools/extrair_golem_falesias.py [--preview]

Porque isto existe
------------------
O rig antigo (`tools/gerar_chefes_anim.py`, `_golem_falesias`) desenhava o
golem com poligonos -- um boneco humanoide de "caixas" com duas bolas roxas,
que o Paulo reprovou ("bosses quadrados, parecem desenhados por criancas").
A arte aprovada do arquetipo existe: `enemy_gameplay_pack.png`, painel
GOLEM AEREO ("corpo de pedra levitacao"), com tres poses grandes do
golem -- um peito de pedra com o NUCLEO violeta e lajes soltas (ombros,
punhos, antebracos, pes) a pairar a volta do tronco.

Em vez de redesenhar, recorta-se a pose "de pe" da prancha, parte-se nas
pecas que a propria arte ja' separa (componentes ligados -- o golem e'
feito de pedras soltas com ar no meio) e anima-se como ele e': cada laje
paira com a sua fase, junta-se no ar antes do baque, salta em estilhacos
quando leva dano e desfaz-se quando morre.

Escreve `assets/sprites/pixel/bosses_anim/golem_falesias/{idle,walk,attack,
hurt,death}.png` (tiras horizontais) e actualiza a entrada do rig em
`rigs.json`. A escala e' ja' a final (corpo a `ALTURA_CORPO` px), por isso a
cena poe `escala_visual = 1.0`: nada e' reamostrado no motor.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRANCHA = os.path.join(RAIZ, "docs/art_direction/regions/region_02",
                       "enemy_gameplay_pack.png")
DESTINO = os.path.join(RAIZ, "assets/sprites/pixel/bosses_anim/golem_falesias")
RIGS_JSON = os.path.join(RAIZ, "assets/sprites/pixel/bosses_anim/rigs.json")

# pose "de pe" (a da esquerda) no painel GOLEM AEREO, em px da prancha
CORTE = (984, 44, 1076, 146)
FUNDO = np.array([1, 12, 22])
LIMIAR_CORTE = 40          # soma |rgb - fundo| acima disto = pixel do golem
ALFA_ZERO, ALFA_CHEIO = 11, 38
AREA_MIN = 20              # manchas mais pequenas sao ruido das legendas
ALTURA_CORPO = 130.0       # px no ecra (era 100 * 1.3 do rig antigo)
W, H = 272, 264            # tamanho do frame
CHAO_Y = 214               # base da pose em repouso
CX = W // 2


def carregar_pecas():
    """Devolve (pecas, escala, altura_na_prancha)."""
    src = np.array(Image.open(PRANCHA).convert("RGB")).astype(int)
    x0, y0, x1, y1 = CORTE
    c = src[y0:y1, x0:x1]
    d = np.abs(c - FUNDO).sum(2)
    mascara = d > LIMIAR_CORTE
    lab, n = ndi.label(mascara)
    areas = ndi.sum(mascara, lab, range(1, n + 1))
    for k in range(1, n + 1):
        if areas[k - 1] < AREA_MIN:
            lab[lab == k] = 0
    # cada pixel, ate' 2 px de uma peca, pertence 'a peca mais proxima --
    # assim a borda macia nao rouba pixeis 'as vizinhas
    dist, (iy, ix) = ndi.distance_transform_edt(lab == 0, return_indices=True)
    dono = lab[iy, ix]
    dono[dist > 2.2] = 0
    # alfa por rampa de distancia ao fundo (binario deixava bordas aos degraus)
    alfa = np.clip((d - ALFA_ZERO) / float(ALFA_CHEIO - ALFA_ZERO), 0.0, 1.0)
    # cor sem o fundo misturado (des-premultiplicar)
    a3 = np.maximum(alfa, 1e-3)[..., None]
    cor = np.clip((c - FUNDO * (1.0 - a3)) / a3, 0, 255)

    ys, xs = np.nonzero(dono)
    alt_src = ys.max() - ys.min() + 1
    esc = ALTURA_CORPO / float(alt_src)
    ymin = ys.min()
    xmid = (xs.min() + xs.max()) / 2.0

    pecas = []
    for k in sorted(set(dono.flatten().tolist()) - {0}):
        m = dono == k
        yy, xx = np.nonzero(m)
        ya, yb, xa, xb = yy.min(), yy.max() + 1, xx.min(), xx.max() + 1
        rgba = np.zeros((yb - ya, xb - xa, 4), dtype=np.float32)
        sub = m[ya:yb, xa:xb]
        rgba[..., :3] = cor[ya:yb, xa:xb]
        rgba[..., 3] = np.where(sub, alfa[ya:yb, xa:xb], 0.0) * 255.0
        gw = max(1, int(round((xb - xa) * esc)))
        gh = max(1, int(round((yb - ya) * esc)))
        # alfa pre-multiplicado ao reamostrar, senao a borda ganha halo escuro
        pm = rgba.copy()
        pm[..., :3] *= pm[..., 3:4] / 255.0
        canais = [np.array(Image.fromarray(pm[..., i], "F").resize(
            (gw, gh), Image.LANCZOS)) for i in range(4)]
        out = np.stack(canais, axis=-1)
        al = np.maximum(out[..., 3:4], 1e-3)
        out[..., :3] = np.clip(out[..., :3] / al * 255.0, 0, 255)
        out[..., 3] = np.clip(out[..., 3], 0, 255)
        out[out[..., 3] < 10] = 0
        img2 = Image.fromarray(out.astype(np.uint8), "RGBA")
        cx = ((xa + xb) / 2.0 - xmid) * esc
        cy = ((ya + yb) / 2.0 - ymin) * esc
        pecas.append({"img": img2, "cx": cx, "cy": cy,
                      "area": int(areas[k - 1]), "nome": ""})
    return pecas, esc, alt_src


def classificar(pecas):
    """Da' nome 'as pecas pelo sitio onde estao (a pose e' esta, fixa)."""
    pecas.sort(key=lambda p: -p["area"])
    corpo = pecas[0]
    corpo["nome"] = "corpo"
    for p in pecas[1:]:
        dx, dy = p["cx"] - corpo["cx"], p["cy"] - corpo["cy"]
        if p["area"] < 70:
            p["nome"] = "estilhaco"
        elif p["area"] > 330:
            p["nome"] = "braco_g" if dx < 0 else "braco_d"
        elif abs(dx) < 70 and dy > 60:
            p["nome"] = "pe"
        else:
            p["nome"] = ("ombro_" if dy < 25 else "punho_") + ("g" if dx < 0 else "d")
    return pecas


def pulso_nucleo(img, k):
    """Acende (k>0) ou apaga (k<0) o nucleo violeta: pixeis saturados roxos."""
    a = np.array(img).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    roxo = np.clip((b - np.maximum(r, g) - 18.0) / 70.0, 0.0, 1.0)
    roxo *= (a[..., 3] > 0)
    if k >= 0:
        a[..., 0] = np.clip(r + roxo * 90.0 * k, 0, 255)
        a[..., 1] = np.clip(g + roxo * 35.0 * k, 0, 255)
        a[..., 2] = np.clip(b * (1.0 + 0.2 * roxo * k) + roxo * 30.0 * k, 0, 255)
    else:
        f = 1.0 + 0.5 * k
        for i in range(3):
            a[..., i] = a[..., i] * (1.0 - roxo) + a[..., i] * f * roxo
    return Image.fromarray(a.astype(np.uint8), "RGBA")


def branquear(img, q):
    a = np.array(img).astype(np.float32)
    for i in range(3):
        a[..., i] = a[..., i] + (255 - a[..., i]) * q
    return Image.fromarray(a.astype(np.uint8), "RGBA")


def pintar(tela, p, dx, dy, rot=0.0, alfa=1.0, flash=0.0, nucleo=0.0, esc=1.0):
    img = p["img"]
    if nucleo and p["nome"] == "corpo":
        img = pulso_nucleo(img, nucleo)
    if flash > 0:
        img = branquear(img, flash)
    if esc != 1.0:
        img = img.resize((max(1, int(img.width * esc)),
                          max(1, int(img.height * esc))), Image.LANCZOS)
    if abs(rot) > 0.01:
        img = img.rotate(rot, resample=Image.BICUBIC, expand=True)
    if alfa < 1.0:
        a = np.array(img).astype(np.float32)
        a[..., 3] *= alfa
        img = Image.fromarray(a.astype(np.uint8), "RGBA")
    px = int(round(CX + p["cx"] + dx - img.width / 2.0))
    py = int(round(CHAO_Y - ALTURA_CORPO + p["cy"] + dy - img.height / 2.0))
    camada = Image.new("RGBA", tela.size, (0, 0, 0, 0))
    camada.paste(img, (px, py))
    tela.alpha_composite(camada)


# fase/amplitude de flutuacao de cada laje: nenhuma se mexe ao mesmo tempo
FASE = {"corpo": (0.0, 1.6), "braco_g": (1.1, 3.4), "braco_d": (2.3, 3.0),
        "ombro_g": (0.6, 2.6), "ombro_d": (1.9, 2.6), "punho_g": (2.9, 3.6),
        "punho_d": (0.3, 3.4), "pe": (1.5, 3.0), "estilhaco": (2.0, 4.2)}


def flutua(nome, idx, t, amp=1.0):
    f, a = FASE[nome]
    f += idx * 0.9
    s = math.sin(2 * math.pi * t + f) - math.sin(f)        # 0 em t = 0
    c = math.cos(2 * math.pi * t + f + 1.3) - math.cos(f + 1.3)
    return c * a * 0.35 * amp, s * a * amp


def ordem_z(p):
    # lajes de tras primeiro, corpo a meio, punhos e pedras da frente por cima
    return {"estilhaco": 0, "braco_g": 1, "ombro_g": 1, "pe": 2, "corpo": 3,
            "ombro_d": 4, "braco_d": 4, "punho_g": 5, "punho_d": 5}.get(p["nome"], 3)


def novo():
    return Image.new("RGBA", (W, H), (0, 0, 0, 0))


def quadro_idle(pecas, i, n):
    t = i / float(n)
    tela = novo()
    for k, p in enumerate(sorted(pecas, key=ordem_z)):
        dx, dy = flutua(p["nome"], k, t)
        pintar(tela, p, dx, dy, nucleo=0.5 * math.sin(2 * math.pi * t))
    return tela


def quadro_walk(pecas, i, n):
    t = i / float(n)
    tela = novo()
    for k, p in enumerate(sorted(pecas, key=ordem_z)):
        dx, dy = flutua(p["nome"], k, t, amp=1.5)
        # desliza: as lajes ficam um pouco para tras do tronco
        arr = {"corpo": 0, "pe": -3, "ombro_g": -2, "ombro_d": -2}.get(
            p["nome"], -5)
        pintar(tela, p, dx + arr, dy, nucleo=0.3 * math.sin(2 * math.pi * t))
    return tela


def suavizar(x):
    return x * x * (3 - 2 * x)


def quadro_ataque(pecas, i, n):
    """Junta-se no ar (0-3), aguenta carregado (4-5), baque (6-9)."""
    tela = novo()
    if i <= 3:
        q = suavizar(i / 3.0)              # 0 -> 1: contrai e sobe
    elif i <= 5:
        q = 1.0
    else:
        q = 1.0 - suavizar(min(1.0, (i - 5) / 2.0))   # larga tudo para baixo
    baque = i >= 6
    for k, p in enumerate(sorted(pecas, key=ordem_z)):
        nome = p["nome"]
        dx = dy = rot = 0.0
        if nome == "corpo":
            dy = -8.0 * q + (10.0 if i in (6, 7) else 0.0)
        elif nome in ("braco_g", "braco_d"):
            s = -1.0 if nome == "braco_g" else 1.0
            dx = -s * 18.0 * q
            dy = -46.0 * q
            rot = s * -28.0 * q
        elif nome.startswith("punho"):
            s = -1.0 if nome.endswith("g") else 1.0
            dx = -s * 30.0 * q
            dy = -34.0 * q
        elif nome.startswith("ombro"):
            s = -1.0 if nome.endswith("g") else 1.0
            dx = -s * 8.0 * q
            dy = -14.0 * q
        elif nome == "pe":
            dy = -10.0 * q + (12.0 if i in (6, 7) else 0.0)
        else:
            dx, dy = flutua(nome, k, i / float(n), amp=2.0)
            dy -= 12.0 * q
        if baque:
            dx += math.sin(i * 7.3 + k) * 1.5
        pintar(tela, p, dx, dy, rot=rot,
               nucleo=1.0 if 3 <= i <= 6 else 0.3 * q,
               flash=0.35 if i == 6 else 0.0)
    return tela


def quadro_dano(pecas, i, n):
    tela = novo()
    sacudir = [1.0, 0.6, 0.25, 0.0][i]
    for k, p in enumerate(sorted(pecas, key=ordem_z)):
        ang = k * 1.1
        dx = math.cos(ang) * 7.0 * sacudir
        dy = math.sin(ang) * 5.0 * sacudir
        if p["nome"] == "corpo":
            dx, dy = -3.0 * sacudir, 1.0 * sacudir
        pintar(tela, p, dx, dy, rot=(k % 3 - 1) * 6.0 * sacudir,
               flash=0.7 if i == 0 else (0.3 if i == 1 else 0.0),
               nucleo=0.9 * sacudir)
    return tela


def quadro_morte(pecas, i, n):
    """A pedra perde o nucleo e cai: cada laje com a sua velocidade."""
    tela = novo()
    t = i / float(n - 1)
    for k, p in enumerate(sorted(pecas, key=ordem_z)):
        nome = p["nome"]
        ang = (k * 1.9) % (2 * math.pi)
        espalha = 26.0 if nome != "corpo" else 6.0
        queda = 60.0 if nome != "corpo" else 30.0
        atraso = 0.1 * (k % 4)
        u = max(0.0, (t - atraso) / (1.0 - atraso))
        dx = math.cos(ang) * espalha * u * (1.3 if nome.startswith("braco") else 1.0)
        dy = -math.sin(ang) * 6.0 * u + queda * u * u
        rot = (k % 2 * 2 - 1) * 70.0 * u
        alfa = 1.0 if t < 0.55 else max(0.0, 1.0 - (t - 0.55) / 0.45)
        nuc = 1.0 if i < 4 else 0.6 - 1.4 * u
        pintar(tela, p, dx, dy, rot=rot, alfa=alfa,
               flash=0.4 if i == 1 else 0.0, nucleo=nuc, esc=1.0 - 0.25 * u)
    return tela


ESTADOS = [("idle", 6, quadro_idle), ("walk", 8, quadro_walk),
           ("attack", 10, quadro_ataque), ("hurt", 4, quadro_dano),
           ("death", 10, quadro_morte)]


def main():
    pecas, esc, alt_src = carregar_pecas()
    classificar(pecas)
    print("escala %.3f (corpo %d px na prancha), %d pecas: %s" % (
        esc, alt_src, len(pecas),
        ", ".join("%s(%d)" % (p["nome"], p["area"]) for p in pecas)))
    os.makedirs(DESTINO, exist_ok=True)
    preview = "--preview" in sys.argv
    for nome, n, fn in ESTADOS:
        tira = Image.new("RGBA", (W * n, H), (0, 0, 0, 0))
        for i in range(n):
            tira.paste(fn(pecas, i, n), (i * W, 0))
        tira.save(os.path.join(DESTINO, nome + ".png"))
        if preview:
            fundo = Image.new("RGBA", tira.size, (40, 52, 82, 255))
            fundo.alpha_composite(tira)
            fundo.convert("RGB").save(os.path.join(
                os.environ.get("PREVIEW_DIR", "/tmp"), "golem_%s.png" % nome))
    with open(RIGS_JSON, encoding="utf-8") as f:
        rigs = json.load(f)
    rigs["golem_falesias"] = {
        "w": W, "h": H, "pes_y": CHAO_Y,
        "estados": {n: c for n, c, _ in ESTADOS},
        "fps": {"idle": 7.0, "walk": 10.0, "attack": 14.0, "hurt": 12.0,
                "death": 9.0},
    }
    with open(RIGS_JSON, "w", encoding="utf-8") as f:
        json.dump(rigs, f, indent=1, ensure_ascii=False)
        f.write("\n")


if __name__ == "__main__":
    main()
