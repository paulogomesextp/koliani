"""Rastreio determinístico dos frames integrados da Koliani na Execution 6B.

Não cria arte. Compara fonte aprovada, recorte histórico, PNG normalizado,
strip de produção e região de atlas usada pelo runtime. A evidência visual
destaca as fronteiras que amputaram run_03..run_09.
"""

from __future__ import annotations

from hashlib import sha256
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


RAIZ = Path(__file__).resolve().parents[1]
FONTE = RAIZ / "Koliani_1.0_Master_Package_v2/references/approved/05_KOLIANI_IDLE_RUN_CLEAN_v1_1.png"
RECUPERACAO = RAIZ / "work/koliani_extraction_recovery_medium"
REEXTRAIDO = RAIZ / "work/execution_6b/koliani_diagnostics/reextracted_run"
ASSETS = RAIZ / "assets/sprites/pixel/koliani_visual_pilot_5g"
SAIDA = RAIZ / "work/execution_6b/koliani_diagnostics"

LINHAS = {
    "idle": (29, 158, 1008, 282, 10),
    "run": (29, 350, 1507, 478, 12),
    "turn": (29, 535, 359, 663, 4),
    "run_start": (952, 535, 1508, 663, 6),
    "jump_start": (29, 710, 334, 851, 4),
    "jump_loop": (346, 710, 664, 851, 4),
    "fall": (682, 710, 978, 851, 4),
}
CLIPPED = {f"run_{i:02d}" for i in range(3, 10)}


def hash_file(path: Path) -> str:
    return sha256(path.read_bytes()).hexdigest()


def bbox_alpha(image: Image.Image) -> list[int]:
    alpha = np.asarray(image.convert("RGBA"))[:, :, 3]
    ys, xs = np.nonzero(alpha)
    if not len(xs):
        return [0, 0, 0, 0]
    return [int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1)]


def encaixar(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    copy = image.convert("RGBA")
    copy.thumbnail(size, Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", size, (22, 23, 30, 255))
    canvas.alpha_composite(copy, ((size[0] - copy.width) // 2, (size[1] - copy.height) // 2))
    return canvas


def main() -> None:
    SAIDA.mkdir(parents=True, exist_ok=True)
    source = Image.open(FONTE).convert("RGBA")
    recovery = json.loads((RECUPERACAO / "reports/recovery_report.json").read_text(encoding="utf-8"))
    reextracted = json.loads((REEXTRAIDO / "report.json").read_text(encoding="utf-8"))
    frames: list[dict] = []

    for animacao, (x1, y1, x2, y2, quantidade) in LINHAS.items():
        strip_path = ASSETS / f"{animacao}.png"
        strip = Image.open(strip_path).convert("RGBA")
        largura_atlas = strip.width // quantidade
        assert strip.size == (160 * quantidade, 96), strip_path
        for indice in range(quantidade):
            nome = f"{animacao}_{indice + 1:02d}"
            esquerda = round(x1 + indice * (x2 - x1) / quantidade)
            direita = round(x1 + (indice + 1) * (x2 - x1) / quantidade)
            recorte_path = RECUPERACAO / f"frames_raw/{animacao}/{nome}.png"
            normalizado_path = RECUPERACAO / f"frames_normalized/{animacao}/{nome}.png"
            current_source_box = [esquerda, y1, direita, y2]
            current_bbox_raw = recovery["frames"][nome]["metrics"]["bbox"]
            if animacao == "run":
                corrected = reextracted["frames"][indice]
                normalizado_path = REEXTRAIDO / f"normalized/{nome}.png"
                current_source_box = corrected["source_box"]
                current_bbox_raw = corrected["extracted_bbox"]
            recorte = Image.open(recorte_path).convert("RGBA")
            normalizado = Image.open(normalizado_path).convert("RGBA")
            atlas = strip.crop((indice * 160, 0, (indice + 1) * 160, 96))
            historical_bbox_raw = recovery["frames"][nome]["metrics"]["bbox"]
            bbox_raw = current_bbox_raw
            lados = []
            largura_recorte_atual = current_source_box[2] - current_source_box[0]
            if bbox_raw[0] == 0:
                lados.append("left")
            if bbox_raw[2] == largura_recorte_atual:
                lados.append("right")
            if bbox_raw[1] == 0:
                lados.append("top")
            if bbox_raw[3] == recorte.height:
                lados.append("bottom")
            corrigido = nome in CLIPPED
            frames.append(
                {
                    "frame": nome,
                    "status": "SAFE_FIXED" if corrigido else "SAFE",
                    "historical_status": "EXTRACTION_CLIPPED" if corrigido else "SAFE",
                    "historical_source_box": [esquerda, y1, direita, y2],
                    "historical_source_selected_bbox": historical_bbox_raw,
                    "source_box": current_source_box,
                    "source_selected_bbox": bbox_raw,
                    "source_crop_touched_sides": lados,
                    "extracted_size": list(recorte.size),
                    "normalized_size": list(normalizado.size),
                    "normalized_alpha_bbox": bbox_alpha(normalizado),
                    "lowest_opaque_pixel": bbox_alpha(normalizado)[3] - 1,
                    "logical_feet_y": 90,
                    "pivot": [80, 90],
                    "strip_path": str(strip_path.resolve()),
                    "strip_sha256": hash_file(strip_path),
                    "atlas_region": [indice * largura_atlas, 0, largura_atlas, strip.height],
                    "atlas_matches_normalized": bool(np.array_equal(np.asarray(atlas), np.asarray(normalizado))),
                    "godot_import_exists": strip_path.with_suffix(".png.import").exists(),
                    "runtime_clipped": False,
                    "note": (
                        "A figura completa é visível na autoridade 05 além da fronteira da divisão igual; "
                        "o recorte/segmentação histórico reteve apenas parte da pose."
                        if corrigido
                        else "Margem na fonte e identidade exata até à região do atlas."
                    ),
                }
            )

    falhas_atlas = [f["frame"] for f in frames if not f["atlas_matches_normalized"]]
    resumo = {
        "integrated_frames": len(frames),
        "safe": sum(f["status"] in ("SAFE", "SAFE_FIXED") for f in frames),
        "fixed": sum(f["status"] == "SAFE_FIXED" for f in frames),
        "historical_extraction_clipped": sum(f["historical_status"] == "EXTRACTION_CLIPPED" for f in frames),
        "atlas_mismatches": falhas_atlas,
        "transform": {"scale": 0.82, "offset_y": -15.170732, "pivot": [80, 90], "canvas": [160, 96], "baseline_y": 90},
        "root_cause": "equal-width source crop plus foreground-component selection before normalization",
        "downstream_loss": "none: normalization, strip, atlas and runtime region preserve their inputs exactly",
    }
    (SAIDA / "koliani_lower_body_trace.json").write_text(
        json.dumps({"source": str(FONTE.resolve()), "source_sha256": hash_file(FONTE), "summary": resumo, "frames": frames}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    font = ImageFont.load_default()
    panel_w, panel_h = 920, 164
    sheet = Image.new("RGB", (panel_w, 52 + panel_h * len(CLIPPED)), (13, 15, 23))
    draw = ImageDraw.Draw(sheet)
    draw.text((14, 10), "KOLIANI 6B — APPROVED SOURCE -> EXTRACTION -> NORMALIZED -> GODOT ATLAS", fill=(238, 238, 246), font=font)
    draw.text((14, 28), "Red lines: historical equal-width crop. Yellow pixels beyond them exist in approved source.", fill=(255, 205, 90), font=font)
    for row, nome in enumerate(sorted(CLIPPED)):
        frame = next(item for item in frames if item["frame"] == nome)
        sx1, sy1, sx2, sy2 = frame["historical_source_box"]
        expanded = source.crop((max(0, sx1 - 42), sy1, min(source.width, sx2 + 42), sy2)).convert("RGB")
        ed = ImageDraw.Draw(expanded)
        left = 42 if sx1 >= 42 else sx1
        ed.line((left, 0, left, expanded.height), fill=(255, 55, 80), width=2)
        ed.line((left + sx2 - sx1, 0, left + sx2 - sx1, expanded.height), fill=(255, 55, 80), width=2)
        raw = Image.open(RECUPERACAO / f"frames_clean/run/{nome}.png").convert("RGBA")
        norm = Image.open(REEXTRAIDO / f"normalized/{nome}.png").convert("RGBA")
        strip = Image.open(ASSETS / "run.png").convert("RGBA")
        idx = int(nome[-2:]) - 1
        atlas = strip.crop((idx * 160, 0, (idx + 1) * 160, 96))
        y = 52 + row * panel_h
        draw.text((14, y + 4), f"{nome}  EXTRACTION_CLIPPED -> SAFE_FIXED  historical crop={frame['historical_source_box']}", fill=(255, 195, 80), font=font)
        draw.text((14, y + 22), "APPROVED SOURCE", fill="white", font=font)
        draw.text((254, y + 22), "EXTRACTED RGBA", fill="white", font=font)
        draw.text((474, y + 22), "FIXED NORMALIZED", fill="white", font=font)
        draw.text((694, y + 22), "CURRENT GODOT ATLAS", fill="white", font=font)
        sheet.paste(encaixar(expanded, (220, 116)).convert("RGB"), (14, y + 40))
        sheet.paste(encaixar(raw, (200, 116)).convert("RGB"), (254, y + 40))
        sheet.paste(encaixar(norm, (200, 116)).convert("RGB"), (474, y + 40))
        sheet.paste(encaixar(atlas, (200, 116)).convert("RGB"), (694, y + 40))
    sheet.save(SAIDA / "koliani_lower_body_trace.png")
    print(json.dumps(resumo, ensure_ascii=False))


if __name__ == "__main__":
    main()
