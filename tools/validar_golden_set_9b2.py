#!/usr/bin/env python3
"""Execution 9B.2 -- valida os frames normalizados do Golden Set e gera previews.

1. Production Asset Validator v2 (tools/production_asset_validator) por animação,
   com os manifestos do contrato 9B.1 (assets/sprites/koliani_golden_set/),
   copiados para a pasta de saída -- os assets do repo não são tocados.
2. Verificações próprias: altura de repouso 64 px, anti-chibi (§E: mínimo 59 px),
   magenta fora do ataque, ilhas soltas.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

RAIZ = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RAIZ))
sys.path.insert(0, str(RAIZ / "tools"))
from tools.production_asset_validator.validator import (  # noqa: E402
    gerar_contact_sheet, markdown, validar_manifesto)
from extrair_golden_set_9b2 import (  # noqa: E402
    componentes, SAIDA, CANVAS, BASELINE, PIVOT, ALTURA_REPOUSO, ALTURA_MIN_ANTICHIBI)

MANIFESTOS = RAIZ / "assets/sprites/koliani_golden_set"


def magenta(img: Image.Image) -> int:
    return sum(1 for r, g, b, a in img.get_flattened_data() if a and r > 150 and b > 150 and g < 110)


def main() -> int:
    meta = json.loads((SAIDA / "reports/extraction_meta.json").read_text(encoding="utf-8"))
    anims = list(dict.fromkeys(f["animation"] for f in meta["frames"]))

    # 1. validator v2
    v2 = {}
    for a in anims:
        vfx = a.startswith("vfx")
        origem = MANIFESTOS / ("vfx" if vfx else "frames") / a / "manifest.json"
        man = json.loads(origem.read_text(encoding="utf-8"))
        man["visual_review_state"] = "EXTRACTED_9B2_PENDING_GAME_MASTER_REVIEW"
        man["source_image"] = meta["source"]
        man["source_sha256"] = meta["source_sha256"]
        destino = SAIDA / "normalized" / a / "manifest.json"
        destino.write_text(json.dumps(man, indent=2, ensure_ascii=False), encoding="utf-8")
        rel = validar_manifesto(destino)
        pasta = SAIDA / "reports/validator_v2"
        pasta.mkdir(parents=True, exist_ok=True)
        (pasta / f"{a}.json").write_text(json.dumps(rel, ensure_ascii=False, indent=2, sort_keys=True), encoding="utf-8")
        (pasta / f"{a}.md").write_text(markdown(rel), encoding="utf-8")
        gerar_contact_sheet(rel, SAIDA / "preview" / f"validator_v2_{a}.png", escala=2)
        an = rel["animation"]
        v2[a] = {"status": an["status"], "frames": an["frame_count"],
                 "problem_frames": an["problem_frames"],
                 "animation_findings": [x["code"] + ": " + x["message"] for x in an["findings"]],
                 "frame_findings": sorted({x["code"] for f in rel["frames"] for x in f["findings"]})}

    # 2. verificações próprias
    linhas = []
    for f in meta["frames"]:
        img = Image.open(RAIZ / f["normalized"]).convert("RGBA")
        bb = img.getchannel("A").getbbox()
        altura = bb[3] - bb[1]
        comps = sorted(componentes(img.getchannel("A"), 128), key=lambda c: -c[0])
        falhas = []
        if not f["vfx"]:
            if altura < ALTURA_MIN_ANTICHIBI:
                falhas.append(f"CHIBI_DRIFT: altura {altura}px < {ALTURA_MIN_ANTICHIBI}px "
                              f"({(altura / ALTURA_REPOUSO - 1) * 100:+.0f}% vs repouso)")
            if f["animation"] == "idle" and abs(altura - ALTURA_REPOUSO) > 1:
                falhas.append(f"REST_HEIGHT: idle com {altura}px, esperado {ALTURA_REPOUSO}±1")
            mg = magenta(img)
            if f["animation"] != "attack_basic" and mg > 3:
                falhas.append(f"MAGENTA: {mg}px num frame sem arma ativa")
        linhas.append({"name": Path(f["normalized"]).name, "animation": f["animation"],
                       "height_px": altura, "width_px": bb[2] - bb[0], "bbox": list(bb),
                       "components": len(comps), "anchor_x_shift_to_fit": f["anchor_x_shift_to_fit"],
                       "status": "FAIL" if falhas else "PASS", "fail_reasons": falhas})

    alturas = {}
    for v in linhas:
        alturas.setdefault(v["animation"], []).append(v["height_px"])
    consist = {k: {"min": min(a), "max": max(a)} for k, a in alturas.items()}
    rel = {"execution": "9B.2", "uniform_scale": meta["uniform_scale"],
           "contract": meta["contract"], "validator_v2": v2, "extra_checks": linhas,
           "height_consistency": consist,
           "summary": {"validator_v2": {a: v["status"] for a, v in v2.items()},
                       "extra_pass": sum(v["status"] == "PASS" for v in linhas),
                       "extra_fail": sum(v["status"] == "FAIL" for v in linhas)}}
    (SAIDA / "reports/validation_9b2.json").write_text(json.dumps(rel, indent=2, ensure_ascii=False), encoding="utf-8")

    # contact sheet geral: normalizados x3 sobre fundo escuro, baseline azul, pivot amarelo
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
            topo = cy + (BASELINE + 1 - ALTURA_REPOUSO) * Z
            d.line((cx, topo, cx + cel, topo), fill=(255, 80, 160, 255))
            d.line((cx + PIVOT[0] * Z, cy + cel - 30, cx + PIVOT[0] * Z, cy + cel), fill=(255, 200, 0, 255))
            spr = Image.open(RAIZ / f["normalized"]).resize((cel, cel), Image.NEAREST)
            folha.alpha_composite(spr, (cx, cy))
            d.text((cx + 4, cy + 4), Path(f["normalized"]).stem, fill=(200, 200, 200, 255))
        y += ((len(fs) + cols - 1) // cols) * cel
    folha.save(SAIDA / "preview/contact_sheet_normalized_x3.png")

    raws = [Image.open(SAIDA / "raw_frames" / f"{f['name']}.png") for f in meta["frames"]]
    wmax = max(r.width for r in raws) + 8
    hmax = max(r.height for r in raws) + 8
    folha = Image.new("RGBA", (wmax * cols, hmax * ((len(raws) + cols - 1) // cols)), (0, 255, 0, 255))
    for k, r in enumerate(raws):
        folha.alpha_composite(r, ((k % cols) * wmax + 4, (k // cols) * hmax + 4))
    folha.save(SAIDA / "preview/contact_sheet_raw_on_green.png")

    print(json.dumps(rel["summary"]))
    print(json.dumps(consist))
    for a, v in v2.items():
        if v["status"] != "PASS":
            print("v2", a, v["status"], v["animation_findings"], v["frame_findings"], v["problem_frames"])
    for v in linhas:
        if v["status"] == "FAIL":
            print("extra", v["name"], v["fail_reasons"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
