#!/usr/bin/env python3
"""Execution 9B.2 -- valida os frames normalizados do Golden Set e gera previews.

Reutiliza `_validar_png` do validator de produção (tools/validate_koliani_production.py)
com a spec 128x128 / baseline 103, e acrescenta verificações de contaminação.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

RAIZ = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RAIZ / "tools"))
from validate_koliani_production import _validar_png  # noqa: E402
from extrair_golden_set_9b2 import componentes, SAIDA, CANVAS, BASELINE, PIVOT  # noqa: E402

SPEC = {"format": "PNG", "mode": "RGBA", "width": CANVAS, "height": CANVAS,
        "baseline_y": BASELINE, "outside_alpha": 0, "interior_alpha": 255,
        "pivot": list(PIVOT), "target_character_height_px": 91}  # altura do idle extraído
NO_CHAO = ("idle", "attack")  # animações com contacto no chão confirmado na fonte


def magenta(img: Image.Image) -> int:
    n = 0
    for r, g, b, a in img.getdata():
        if a and r > 150 and b > 150 and g < 110:
            n += 1
    return n


def main() -> int:
    meta = json.loads((SAIDA / "reports/extraction_meta.json").read_text(encoding="utf-8"))
    linhas = []
    for f in meta["frames"]:
        caminho = RAIZ / f["normalized"]
        v = _validar_png(caminho, SPEC, exigir_baseline=f["animation"] in NO_CHAO)
        img = Image.open(caminho).convert("RGBA")
        comps = componentes(img.getchannel("A"), 128)
        comps.sort(key=lambda c: -c[0])
        ilhas = [{"area": a, "bbox": list(b)} for a, b, _ in comps[1:] if a <= 6]
        contam = []
        mg = magenta(img)
        if not f["vfx"] and f["animation"] != "attack" and mg > 3:
            contam.append(f"{mg} px magenta num frame sem arma ativa")
        # a altura-alvo só vale para o idle (poses de corrida/salto/ataque variam por natureza);
        # VFX não tem baseline nem pivot de corpo
        info = []
        for r in list(v.get("fail_reasons", [])):
            if (r.startswith("altura visual") and f["animation"] != "idle") or \
               (f["vfx"] and (r.startswith("baseline") or r.startswith("pivot"))):
                v["fail_reasons"].remove(r)
                info.append(r)
        v["informational"] = info
        v.update(animation=f["animation"], vfx=f["vfx"], components=len(comps),
                 tiny_islands=len(ilhas), magenta_px=mg, contamination=contam,
                 anchor_x_shift_to_fit=f["anchor_x_shift_to_fit"])
        if contam:
            v.setdefault("fail_reasons", []).extend(contam)
        v["status"] = "FAIL" if v.get("fail_reasons") else "PASS"
        linhas.append(v)

    # consistência: altura por animação (idle deve ser estável)
    alturas = {}
    for v in linhas:
        if v.get("bounding_box"):
            alturas.setdefault(v["animation"], []).append(v["bounding_box"][3] - v["bounding_box"][1])
    consist = {k: {"min": min(a), "max": max(a)} for k, a in alturas.items()}

    rel = {"execution": "9B.2", "spec": SPEC, "pivot": list(PIVOT),
           "validator": "tools/validate_koliani_production.py::_validar_png (spec 128x128)",
           "frames": linhas, "height_consistency": consist,
           "summary": {"total": len(linhas),
                       "pass": sum(v["status"] == "PASS" for v in linhas),
                       "fail": sum(v["status"] == "FAIL" for v in linhas)}}
    (SAIDA / "reports/validation_9b2.json").write_text(json.dumps(rel, indent=2), encoding="utf-8")

    # contact sheet: normalizados x3 sobre fundo escuro, com baseline e pivot
    anims = list(dict.fromkeys(f["animation"] for f in meta["frames"]))
    Z, cols = 3, 10
    cel = CANVAS * Z
    alt = sum(((sum(f["animation"] == a for f in meta["frames"]) + cols - 1) // cols) for a in anims)
    folha = Image.new("RGBA", (cel * cols, cel * alt + 20 * len(anims)), (24, 20, 30, 255))
    d = ImageDraw.Draw(folha)
    y = 0
    for a in anims:
        fs = [f for f in meta["frames"] if f["animation"] == a]
        d.text((4, y + 4), a, fill=(230, 230, 230, 255))
        y += 20
        for k, f in enumerate(fs):
            cx, cy = (k % cols) * cel, y + (k // cols) * cel
            d.rectangle((cx, cy, cx + cel - 1, cy + cel - 1), outline=(70, 60, 80, 255))
            d.line((cx, cy + BASELINE * Z + Z // 2, cx + cel, cy + BASELINE * Z + Z // 2), fill=(0, 160, 255, 255))
            d.line((cx + PIVOT[0] * Z, cy + cel - 30, cx + PIVOT[0] * Z, cy + cel), fill=(255, 200, 0, 255))
            spr = Image.open(RAIZ / f["normalized"]).resize((cel, cel), Image.NEAREST)
            folha.alpha_composite(spr, (cx, cy))
            d.text((cx + 4, cy + 4), f["name"], fill=(200, 200, 200, 255))
        y += ((len(fs) + cols - 1) // cols) * cel
    folha.save(SAIDA / "preview/contact_sheet_normalized_x3.png")

    # contact sheet dos raw sobre verde (prova de separação)
    raws = [Image.open(SAIDA / "raw_frames" / f"{f['name']}.png") for f in meta["frames"]]
    wmax = max(r.width for r in raws) + 8
    hmax = max(r.height for r in raws) + 8
    folha = Image.new("RGBA", (wmax * cols, hmax * ((len(raws) + cols - 1) // cols)), (0, 255, 0, 255))
    for k, r in enumerate(raws):
        folha.alpha_composite(r, ((k % cols) * wmax + 4, (k // cols) * hmax + 4))
    folha.save(SAIDA / "preview/contact_sheet_raw_on_green.png")

    print(json.dumps(rel["summary"]), json.dumps(consist))
    for v in linhas:
        if v["status"] == "FAIL":
            print(v["path"], v["fail_reasons"])
    return 0 if rel["summary"]["fail"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
