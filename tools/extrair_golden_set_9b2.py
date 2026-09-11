#!/usr/bin/env python3
"""Execution 9B.2 -- extrai os frames da Koliani da imagem Golden Set aprovada.

Sem redesenho: só recorta o que o alpha da fonte já separa, retira labels e
números (componentes soltos fora do corpo), reduz com escala UNIFORME e
binariza o alpha para o contrato 128x128 / pivot (64,104) / baseline 103.
Não toca no runtime.
"""
from __future__ import annotations

import hashlib
import json
import shutil
import sys
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw

RAIZ = Path(__file__).resolve().parents[1]
GATE = RAIZ / "work/production_art_gate"
FONTE = GATE / "koliani_golden_set_approved.png.png"
SAIDA = GATE / "9b2_extraction"

CANVAS = 128
PIVOT = (64, 104)
BASELINE = 103
LIMIAR_SEG = 16      # alpha mínimo para contar como conteúdo na segmentação
LIMIAR_BIN = 128     # alpha final 0/255

LIMIAR_CORPO = 128   # alpha para os componentes-semente (um corpo = um componente)
AREA_SEMENTE = 400

# Faixas (x0, y0, x1, y1) medidas na fonte; retângulos a apagar = labels/logo/molduras.
# O JUMP/FALL fica dentro das 3 molduras (cabeçalho y 471-491, bordas nas colunas
# 28, 502-508, 933-938, 1433 e linha 682) -- as caixas começam por dentro delas.
FAIXAS = {
    "idle":    {"caixa": (0, 32, 1290, 222), "esperados": 7},
    "run":     {"caixa": (0, 254, 1536, 440), "esperados": 10},
    "jump_start": {"caixa": (31, 494, 500, 681), "esperados": 4},
    "air":     {"caixa": (511, 494, 931, 681), "esperados": 3},
    "fall":    {"caixa": (941, 494, 1431, 681), "esperados": 3},
    "attack":  {"caixa": (0, 688, 1300, 878), "esperados": 6,
                "apagar": [(0, 688, 305, 720)]},
    "vfx":     {"caixa": (0, 912, 1300, 1015), "esperados": 6, "vfx": True},
}


def componentes(alpha: Image.Image, limiar: int):
    """Componentes 8-conexas (lista de (area, bbox, pixels))."""
    w, h = alpha.size
    dados = alpha.load()
    visto = bytearray(w * h)
    saida = []
    for y in range(h):
        for x in range(w):
            i = y * w + x
            if visto[i] or dados[x, y] < limiar:
                continue
            fila = deque([(x, y)])
            visto[i] = 1
            pix = []
            while fila:
                cx, cy = fila.popleft()
                pix.append((cx, cy))
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h:
                            j = ny * w + nx
                            if not visto[j] and dados[nx, ny] >= limiar:
                                visto[j] = 1
                                fila.append((nx, ny))
            xs = [p[0] for p in pix]
            ys = [p[1] for p in pix]
            saida.append((len(pix), (min(xs), min(ys), max(xs) + 1, max(ys) + 1), pix))
    return saida


def _dist_bbox(a, b) -> int:
    dx = max(b[0] - a[2], a[0] - b[2], 0)
    dy = max(b[1] - a[3], a[1] - b[3], 0)
    return max(dx, dy)


def segmentar(faixa: Image.Image, vfx: bool):
    """Um corpo = um componente grande (semente); fragmentos pequenos vão para a
    semente mais próxima; números (debaixo dos pés) e labels são largados."""
    comps = componentes(faixa.getchannel("A"), LIMIAR_CORPO)
    sementes = [c for c in comps if c[0] >= AREA_SEMENTE and c[1][3] - c[1][1] > 8]
    sementes.sort(key=lambda c: c[1][0])
    grupos = [{"bbox": s[1], "pix": list(s[2]), "n": 1} for s in sementes]
    largados = []
    for area, bb, pix in comps:
        if any(bb == s[1] and area == s[0] for s in sementes):
            continue
        if not grupos:
            break
        g = min(grupos, key=lambda g: _dist_bbox(g["bbox"], bb))
        # números "1".."10": glifos pequenos (~6x11) na base da faixa, por baixo dos pés
        larg, alt = bb[2] - bb[0], bb[3] - bb[1]
        e_numero = (area <= 80 and 7 <= alt <= 14 and larg <= 12
                    and bb[1] >= faixa.height - (30 if vfx else 45))
        perto = _dist_bbox(g["bbox"], bb) <= (40 if vfx else 12)
        if perto and not e_numero:
            g["pix"].extend(pix)
            g["n"] += 1
        else:
            largados.append({"area": area, "bbox": list(bb),
                             "reason": "numero_de_frame" if e_numero else "fragmento_solto"})
    # máscara de dono por píxel (inclui a franja de alpha fraco colada a cada grupo)
    dono = Image.new("L", faixa.size, 0)
    d = dono.load()
    for k, g in enumerate(grupos, 1):
        for p in g["pix"]:
            d[p] = k
    alpha = faixa.getchannel("A").load()
    w, h = faixa.size
    for _ in range(2):  # franja de 2 px, só píxeis com alpha >= LIMIAR_SEG
        novos = []
        for y in range(h):
            for x in range(w):
                if d[x, y] or alpha[x, y] < LIMIAR_SEG:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and d[nx, ny]:
                        novos.append((x, y, d[nx, ny]))
                        break
        for x, y, k in novos:
            d[x, y] = k
    saida = []
    for k, g in enumerate(grupos, 1):
        mascara = dono.point(lambda v, k=k: 255 if v == k else 0)
        img = Image.new("RGBA", faixa.size, (0, 0, 0, 0))
        img.paste(faixa, (0, 0), mascara)
        saida.append((img, g["n"]))
    return saida, largados


def main() -> int:
    if not FONTE.is_file():
        print("ERRO: fonte ausente", FONTE)
        return 2
    for sub in ("source", "raw_frames", "normalized", "strips", "preview", "reports"):
        (SAIDA / sub).mkdir(parents=True, exist_ok=True)
    shutil.copy2(FONTE, SAIDA / "source" / "koliani_golden_set_approved.png")
    sha = hashlib.sha256(FONTE.read_bytes()).hexdigest().upper()
    fonte = Image.open(FONTE).convert("RGBA")

    frames = []  # dicts
    for anim, cfg in FAIXAS.items():
        faixa = fonte.crop(cfg["caixa"])
        d = ImageDraw.Draw(faixa)
        ox, oy = cfg["caixa"][:2]
        for (x0, y0, x1, y1) in cfg.get("apagar", []):
            d.rectangle((x0 - ox, y0 - oy, x1 - ox - 1, y1 - oy - 1), fill=(0, 0, 0, 0))
        grupos, largados = segmentar(faixa, cfg.get("vfx", False))
        cfg["largados"] = largados
        for i, (limpo, n_comp) in enumerate(grupos, 1):
            bb = limpo.getchannel("A").getbbox()
            raw = limpo.crop(bb)
            toca = bb[0] == 0 or bb[1] == 0 or bb[2] == faixa.width or bb[3] == faixa.height
            nome = f"{anim}_{i:02d}"
            raw.save(SAIDA / "raw_frames" / f"{nome}.png")
            frames.append({
                "name": nome, "animation": anim, "index": i, "vfx": cfg.get("vfx", False),
                "source_bbox": [ox + bb[0], oy + bb[1], ox + bb[2], oy + bb[3]],
                "raw_size": list(raw.size), "kept_components": n_comp,
                "touches_band_edge": toca, "_img": raw,
            })
        cfg["encontrados"] = len(grupos)

    # escala uniforme: cabe tudo (personagem e VFX) no canvas com 2 px de margem
    pers = [f for f in frames if not f["vfx"]]
    s = min(min((BASELINE - 1) / f["raw_size"][1] for f in pers),
            min((CANVAS - 4) / f["raw_size"][0] for f in frames))
    s = round(s, 4)

    for f in frames:
        raw = f.pop("_img")
        nw, nh = max(1, round(raw.width * s)), max(1, round(raw.height * s))
        red = raw.convert("RGBa").resize((nw, nh), Image.LANCZOS).convert("RGBA")
        a = red.getchannel("A").point(lambda v: 255 if v >= LIMIAR_BIN else 0)
        red.putalpha(a)
        vazio = Image.new("RGBA", red.size, (0, 0, 0, 0))
        red = Image.composite(red, vazio, a)
        bb = a.getbbox()
        red = red.crop(bb)
        # âncora X: mediana das colunas opacas na zona tronco/anca (40-70% da altura)
        al = red.getchannel("A").load()
        cols = [x for y in range(int(red.height * 0.4), int(red.height * 0.7))
                for x in range(red.width) if al[x, y]]
        cols.sort()
        ax = cols[len(cols) // 2] if cols else red.width // 2
        px = PIVOT[0] - ax
        px_fit = min(max(px, 1), CANVAS - 1 - red.width)
        if f["vfx"]:
            py = (CANVAS - red.height) // 2
        else:
            py = BASELINE + 1 - red.height
        tela = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
        tela.paste(red, (px_fit, py))
        caminho = SAIDA / "normalized" / f"{f['name']}.png"
        tela.save(caminho)
        f.update(normalized=caminho.relative_to(RAIZ).as_posix(),
                 anchor_x_shift_to_fit=px_fit - px, placed_at=[px_fit, py],
                 scaled_size=list(red.size))

    # strips
    for anim in FAIXAS:
        fs = [f for f in frames if f["animation"] == anim]
        tira = Image.new("RGBA", (CANVAS * len(fs), CANVAS), (0, 0, 0, 0))
        for k, f in enumerate(fs):
            tira.paste(Image.open(RAIZ / f["normalized"]), (k * CANVAS, 0))
        tira.save(SAIDA / "strips" / f"koliani_{anim}_strip.png")

    meta = {"source": FONTE.relative_to(RAIZ).as_posix(), "source_sha256": sha,
            "source_size": list(fonte.size), "uniform_scale": s,
            "contract": {"canvas": [CANVAS, CANVAS], "pivot": list(PIVOT), "baseline_y": BASELINE,
                         "facing": "right", "alpha": "0/255"},
            "bands": {k: {"expected": v["esperados"], "found": v["encontrados"],
                          "dropped_components": v["largados"]} for k, v in FAIXAS.items()},
            "frames": frames}
    (SAIDA / "reports" / "extraction_meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    for k, v in FAIXAS.items():
        print(f"{k:11s} esperados {v['esperados']:2d} encontrados {v['encontrados']:2d}")
    print("escala", s)
    return 0 if all(v["esperados"] == v["encontrados"] for v in FAIXAS.values()) else 1


if __name__ == "__main__":
    sys.exit(main())
