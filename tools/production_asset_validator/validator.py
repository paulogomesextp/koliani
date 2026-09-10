"""Validação técnica conservadora de frames PNG, sem modificar as fontes."""
from __future__ import annotations

import hashlib
import json
import math
from collections import Counter, deque
from pathlib import Path
from statistics import median
from typing import Any

from PIL import Image, ImageDraw, ImageFont

ESTADOS = {"PASS", "WARNING", "FAIL", "MANUAL_REVIEW_REQUIRED"}
TIPOS = {"BODY", "VFX", "ENVIRONMENT", "UI", "OTHER"}


def _pixels(imagem: Image.Image) -> list[Any]:
    """Compatibilidade Pillow sem usar a API getdata em descontinuação."""
    return list(imagem.get_flattened_data())


def _sha256(caminho: Path) -> str:
    h = hashlib.sha256()
    with caminho.open("rb") as ficheiro:
        for bloco in iter(lambda: ficheiro.read(1024 * 1024), b""):
            h.update(bloco)
    return h.hexdigest()


def _achado(codigo: str, estado: str, mensagem: str) -> dict[str, str]:
    assert estado in ESTADOS
    return {"code": codigo, "status": estado, "message": mensagem}


def _componentes(mask: list[bool], largura: int, altura: int) -> list[dict[str, int]]:
    vistos = bytearray(largura * altura)
    saida: list[dict[str, int]] = []
    for origem, ativo in enumerate(mask):
        if not ativo or vistos[origem]:
            continue
        fila = deque([origem]); vistos[origem] = 1
        xs: list[int] = []; ys: list[int] = []
        while fila:
            atual = fila.popleft(); y, x = divmod(atual, largura)
            xs.append(x); ys.append(y)
            for nx, ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                ni = ny * largura + nx
                if 0 <= nx < largura and 0 <= ny < altura and mask[ni] and not vistos[ni]:
                    vistos[ni] = 1; fila.append(ni)
        saida.append({"pixels": len(xs), "left": min(xs), "top": min(ys),
                      "right": max(xs) + 1, "bottom": max(ys) + 1})
    return sorted(saida, key=lambda c: (-c["pixels"], c["top"], c["left"]))


def _checkerboard(imagem: Image.Image) -> tuple[bool, float]:
    """Deteta padrão alternado repetido; é indício, nunca prova artística."""
    rgb = imagem.convert("RGB")
    w, h = rgb.size
    if w < 16 or h < 16:
        return False, 0.0
    amostras = []
    for bloco in (4, 8, 16):
        acertos = total = 0
        for y in range(h):
            for x in range(w):
                if x + bloco >= w or y + bloco >= h:
                    continue
                p = rgb.getpixel((x, y))
                total += 2
                acertos += p == rgb.getpixel((x + bloco, y))
                acertos += p == rgb.getpixel((x, y + bloco))
        amostras.append(acertos / total if total else 0.0)
    score = max(amostras)
    cores = Counter(_pixels(rgb)).most_common(4)
    cobertura = sum(n for _, n in cores[:2]) / (w * h)
    return score > 0.88 and cobertura > 0.55 and len(cores) >= 2, round(score * cobertura, 6)


def _contaminacao(imagem: Image.Image, alpha: list[int]) -> tuple[dict[str, Any], list[dict[str, str]]]:
    w, h = imagem.size; achados: list[dict[str, str]] = []
    checker, score = _checkerboard(imagem)
    if checker:
        achados.append(_achado("SUSPICIOUS_CHECKERBOARD", "MANUAL_REVIEW_REQUIRED",
                               "Padrão periódico compatível com checkerboard incorporado."))
    rgba = imagem.convert("RGBA"); px = _pixels(rgba)
    borda = [px[x] for x in range(w)] + [px[(h-1)*w+x] for x in range(w)]
    borda += [px[y*w] for y in range(h)] + [px[y*w+w-1] for y in range(h)]
    dominante = Counter(borda).most_common(1)[0][1] / len(borda) if borda else 0.0
    sheet_border = dominante > 0.92 and borda and borda[0][3] > 0
    if sheet_border:
        achados.append(_achado("SUSPICIOUS_SHEET_BORDER", "MANUAL_REVIEW_REQUIRED",
                               "Borda opaca quase uniforme pode pertencer a uma folha/referência."))
    linhas = sum(all(alpha[y*w+x] > 0 for x in range(w)) for y in range(h))
    colunas = sum(all(alpha[y*w+x] > 0 for y in range(h)) for x in range(w))
    separators = linhas + colunas
    if separators >= 2:
        achados.append(_achado("SUSPICIOUS_FRAME_SEPARATORS", "MANUAL_REVIEW_REQUIRED",
                               "Foram encontradas linhas/colunas opacas contínuas."))
    # Texto não pode ser provado sem OCR. Faixas densas isoladas são sinalizadas.
    topo = sum(alpha[y*w+x] > 0 for y in range(max(1, h//5)) for x in range(w))
    meio = sum(alpha[y*w+x] > 0 for y in range(h//3, max(h//3+1, 2*h//3)) for x in range(w))
    label_band = topo > w * max(1, h//5) * .35 and meio < w * max(1, h//3) * .08
    if label_band:
        achados.append(_achado("SUSPICIOUS_LABEL_AREA", "MANUAL_REVIEW_REQUIRED",
                               "Faixa superior isolada pode conter rótulo/texto."))
    return {"checkerboard_score": score, "uniform_opaque_border": sheet_border,
            "continuous_separator_lines": separators, "suspicious_label_band": label_band}, achados


def validar_frame(caminho: Path, contrato: dict[str, Any]) -> dict[str, Any]:
    achados: list[dict[str, str]] = []
    base = {"filename": caminho.name, "path": str(caminho.resolve()), "exists": caminho.is_file(),
            "readable": False, "file_size": caminho.stat().st_size if caminho.is_file() else None,
            "sha256": _sha256(caminho) if caminho.is_file() else None}
    if not caminho.is_file():
        base.update({"status": "FAIL", "findings": [_achado("FILE_MISSING", "FAIL", "Ficheiro ausente.")]})
        return base
    try:
        with Image.open(caminho) as aberta:
            formato, modo, dimensoes = aberta.format, aberta.mode, list(aberta.size)
            aberta.load(); imagem = aberta.copy()
    except Exception as erro:
        base.update({"status": "FAIL", "findings": [_achado("UNREADABLE", "FAIL", f"Imagem ilegível: {erro}")]})
        return base
    base["readable"] = True
    if formato != "PNG": achados.append(_achado("NOT_PNG", "FAIL", f"Formato {formato}; esperado PNG."))
    if modo != "RGBA": achados.append(_achado("NOT_RGBA", "FAIL", f"Modo {modo}; esperado RGBA."))
    has_alpha = "A" in imagem.getbands()
    if not has_alpha: achados.append(_achado("NO_ALPHA_CHANNEL", "FAIL", "Não existe canal alpha real."))
    rgba = imagem.convert("RGBA"); w, h = rgba.size
    alpha = [p[3] for p in _pixels(rgba)]
    zeros = alpha.count(0); opacos = alpha.count(255); semi = len(alpha)-zeros-opacos
    if not zeros: achados.append(_achado("NO_TRANSPARENT_PIXELS", "FAIL", "Não existem pixels alpha 0; transparência pode estar incorporada em RGB."))
    bbox = rgba.getchannel("A").getbbox()
    bounds = list(bbox) if bbox else None
    if not bbox: achados.append(_achado("EMPTY_FRAME", "FAIL", "Frame sem pixels visíveis."))
    esperado_w, esperado_h = contrato.get("canvas_width"), contrato.get("canvas_height")
    if esperado_w is not None and w != esperado_w: achados.append(_achado("CANVAS_WIDTH", "FAIL", f"Largura {w}; esperada {esperado_w}."))
    if esperado_h is not None and h != esperado_h: achados.append(_achado("CANVAS_HEIGHT", "FAIL", f"Altura {h}; esperada {esperado_h}."))
    edges = {"left": bool(bbox and bbox[0] == 0), "right": bool(bbox and bbox[2] == w),
             "top": bool(bbox and bbox[1] == 0), "bottom": bool(bbox and bbox[3] == h)}
    for lado, clipped in edges.items():
        if clipped: achados.append(_achado(f"CLIPPED_{lado.upper()}", "FAIL", f"Conteúdo toca o limite {lado}."))
    baseline = bbox[3]-1 if bbox else None
    baseline_expected = contrato.get("baseline_y"); tolerance = int(contrato.get("baseline_tolerance", 0))
    baseline_delta = baseline-baseline_expected if baseline is not None and baseline_expected is not None else None
    baseline_ok = baseline_delta is None or abs(baseline_delta) <= tolerance
    if not baseline_ok: achados.append(_achado("BASELINE_OUT_OF_TOLERANCE", "FAIL", f"Baseline {baseline}; esperada {baseline_expected} ± {tolerance}."))
    if bbox and edges["bottom"]: achados.append(_achado("LIKELY_CUT_FEET", "FAIL", "Baseline encosta ao fundo; pernas/pés podem estar cortados."))
    contamination, extra = _contaminacao(rgba, alpha); achados.extend(extra)
    components = _componentes([a > int(contrato.get("opaque_threshold", 0)) for a in alpha], w, h)
    if contrato.get("asset_type") == "BODY" and len(components) > 1 and components[0]["pixels"]:
        detached = sum(c["pixels"] for c in components[1:] if c["pixels"] >= max(4, components[0]["pixels"]*.03))
        if detached >= components[0]["pixels"]*.08:
            achados.append(_achado("DETACHED_BODY_REGIONS", "MANUAL_REVIEW_REQUIRED",
                                   "Regiões opacas destacadas relevantes podem ser VFX ou partes corporais legítimas."))
    pivot = {"expected_x": contrato.get("pivot_x"), "expected_y": contrato.get("pivot_y")}
    if pivot["expected_x"] is not None and not 0 <= pivot["expected_x"] < w:
        achados.append(_achado("PIVOT_X_OUTSIDE_CANVAS", "FAIL", "Pivot X fora do canvas."))
    if pivot["expected_y"] is not None and not 0 <= pivot["expected_y"] < h:
        achados.append(_achado("PIVOT_Y_OUTSIDE_CANVAS", "FAIL", "Pivot Y fora do canvas."))
    if pivot["expected_y"] is not None and baseline_expected is not None:
        pivot["baseline_delta"] = baseline_expected-pivot["expected_y"]
    estado = "FAIL" if any(a["status"] == "FAIL" for a in achados) else ("MANUAL_REVIEW_REQUIRED" if any(a["status"] == "MANUAL_REVIEW_REQUIRED" for a in achados) else ("WARNING" if achados else "PASS"))
    base.update({"format": formato, "dimensions": dimensoes, "mode": modo, "has_alpha_channel": has_alpha,
                 "alpha": {"min": min(alpha), "max": max(alpha), "transparent_pixels": zeros,
                           "opaque_pixels": opacos, "semi_transparent_pixels": semi,
                           "transparent_ratio": round(zeros/len(alpha), 8)},
                 "opaque_bounds": bounds, "occupied_area": (bbox[2]-bbox[0])*(bbox[3]-bbox[1]) if bbox else 0,
                 "occupied_pixel_count": len(alpha)-zeros, "edge_clipping": edges,
                 "transparent_border": bool(bbox and not any(edges.values())),
                 "baseline": {"observed_y": baseline, "expected_y": baseline_expected,
                              "tolerance": tolerance, "delta": baseline_delta, "pass": baseline_ok},
                 "pivot": pivot, "contamination": contamination, "components": components,
                 "status": estado, "warnings": [a["message"] for a in achados if a["status"] == "WARNING"],
                 "failures": [a["message"] for a in achados if a["status"] == "FAIL"],
                 "manual_review_flags": [a["message"] for a in achados if a["status"] == "MANUAL_REVIEW_REQUIRED"],
                 "findings": achados})
    return base


def _consistencia(frames: list[dict[str, Any]], contrato: dict[str, Any]) -> dict[str, Any]:
    validos = [f for f in frames if f.get("opaque_bounds")]
    achados: list[dict[str, str]] = []
    dimensoes = {tuple(f.get("dimensions", [])) for f in frames}
    modos = {f.get("mode") for f in frames}
    if len(dimensoes) > 1: achados.append(_achado("INCONSISTENT_CANVAS", "FAIL", "Dimensões variam entre frames."))
    if len(modos) > 1: achados.append(_achado("INCONSISTENT_MODE", "FAIL", "Modo varia entre frames."))
    baselines = [f["baseline"]["observed_y"] for f in validos]
    max_baseline_drift = max(baselines)-min(baselines) if baselines else 0
    if max_baseline_drift > int(contrato.get("baseline_tolerance", 0))*2:
        achados.append(_achado("INCONSISTENT_VERTICAL_PLACEMENT", "FAIL", "Baseline varia excessivamente entre frames."))
    areas = [f["occupied_area"] for f in validos]
    area_ratio = max(areas)/min(areas) if areas and min(areas) else None
    if area_ratio and area_ratio > float(contrato.get("max_scale_ratio", 1.6)):
        achados.append(_achado("GROSS_SCALE_VARIATION", "FAIL", f"Variação de área delimitadora {area_ratio:.3f}×."))
    centers = [((f["opaque_bounds"][0]+f["opaque_bounds"][2])/2, (f["opaque_bounds"][1]+f["opaque_bounds"][3])/2) for f in validos]
    drift = max((math.dist(a,b) for a in centers for b in centers), default=0.0)
    limite = float(contrato.get("max_bbox_drift", max(4, (contrato.get("canvas_width") or 32)*.25)))
    if drift > limite: achados.append(_achado("BOUNDING_BOX_DRIFT", "MANUAL_REVIEW_REQUIRED", f"Deriva máxima do centro {drift:.3f}px excede {limite}px."))
    return {"canvas_consistent": len(dimensoes)<=1, "mode_consistent": len(modos)<=1,
            "baseline_values": baselines, "max_baseline_drift": max_baseline_drift,
            "occupied_area_ratio": round(area_ratio, 6) if area_ratio else None,
            "bbox_center_max_drift": round(drift, 6), "findings": achados}


def validar_manifesto(caminho_manifesto: Path) -> dict[str, Any]:
    manifesto = json.loads(caminho_manifesto.read_text(encoding="utf-8"))
    raiz = caminho_manifesto.parent
    contrato = dict(manifesto); tipo = contrato.get("asset_type", "OTHER")
    if tipo not in TIPOS: raise ValueError(f"asset_type inválido: {tipo}")
    frames = [validar_frame((raiz / nome).resolve(), contrato) for nome in manifesto.get("frames", [])]
    consistencia = _consistencia(frames, contrato)
    esperado = contrato.get("frame_count")
    problemas = []
    if esperado is not None and len(frames) != esperado:
        problemas.append(_achado("FRAME_COUNT", "FAIL", f"Encontrados {len(frames)} frames; esperados {esperado}."))
    problemas.extend(consistencia["findings"])
    codigos_animacao = [a["code"] for a in problemas]
    for frame in frames:
        frame["consistency_result"] = {
            "status": "FAIL" if any(c in codigos_animacao for c in ("INCONSISTENT_CANVAS", "INCONSISTENT_MODE", "INCONSISTENT_VERTICAL_PLACEMENT", "GROSS_SCALE_VARIATION")) else
                      ("MANUAL_REVIEW_REQUIRED" if "BOUNDING_BOX_DRIFT" in codigos_animacao else "PASS"),
            "animation_findings": codigos_animacao,
        }
    todos = [a for f in frames for a in f.get("findings", [])] + problemas
    estado = "FAIL" if any(a["status"]=="FAIL" for a in todos) else ("REVIEW" if any(a["status"]=="MANUAL_REVIEW_REQUIRED" for a in todos) else "PASS")
    ref = contrato.get("reference_path")
    ref_path = Path(ref) if ref else None
    return {"schema_version": 2, "validator": "production_asset_validator_v2",
            "manifest_path": str(caminho_manifesto.resolve()), "manifest_sha256": _sha256(caminho_manifesto),
            "reference_path": ref, "reference_sha256": _sha256(ref_path) if ref_path and ref_path.is_file() else contrato.get("reference_sha256"),
            "animation": {"character": contrato.get("character"), "name": contrato.get("animation"),
                          "asset_type": tipo, "status": estado, "frame_count": len(frames),
                          "expected_frame_count": esperado, "canvas_consistency": consistencia["canvas_consistent"],
                          "baseline_consistency": not any(a["code"]=="INCONSISTENT_VERTICAL_PLACEMENT" for a in problemas),
                          "scale_bounds_consistency": not any(a["code"] in {"GROSS_SCALE_VARIATION","BOUNDING_BOX_DRIFT"} for a in problemas),
                          "problem_frames": [f["filename"] for f in frames if f["status"] != "PASS"],
                          "consistency": consistencia, "findings": problemas}, "frames": frames}


def markdown(relatorio: dict[str, Any]) -> str:
    a = relatorio["animation"]
    linhas = ["# Production Asset Validator v2", "", f"- Status: **{a['status']}**", f"- Animação: `{a['name']}`", f"- Tipo: `{a['asset_type']}`", f"- Frames: {a['frame_count']}", f"- Manifest SHA256: `{relatorio['manifest_sha256']}`", "", "## Frames", "", "| Frame | Status | Dimensões | Baseline | Problemas |", "|---|---|---:|---:|---|"]
    for f in relatorio["frames"]:
        dims = "×".join(map(str, f.get("dimensions", []))) or "—"
        base = f.get("baseline", {}).get("observed_y", "—")
        probs = "; ".join(x["code"] for x in f.get("findings", [])) or "—"
        linhas.append(f"| `{f['filename']}` | {f['status']} | {dims} | {base} | {probs} |")
    linhas += ["", "## Consistência", ""]
    for x in a["findings"]: linhas.append(f"- **{x['status']} — {x['code']}**: {x['message']}")
    if not a["findings"]: linhas.append("- Sem problemas de consistência.")
    linhas += ["", "> Resultado técnico apenas; aprovação visual pertence ao Game Master.", ""]
    return "\n".join(linhas)


def gerar_contact_sheet(relatorio: dict[str, Any], saida: Path, fundo=(96, 96, 104, 255), escala: int = 1) -> None:
    if escala < 1 or int(escala) != escala: raise ValueError("escala deve ser inteiro >= 1")
    frames = relatorio["frames"]
    if not frames: raise ValueError("relatório sem frames")
    imagens = [Image.open(f["path"]).convert("RGBA") for f in frames]
    cell_w = max(i.width for i in imagens)*escala + 16; cell_h = max(i.height for i in imagens)*escala + 42
    cols = min(4, len(imagens)); rows = math.ceil(len(imagens)/cols)
    sheet = Image.new("RGBA", (cols*cell_w, rows*cell_h), fundo); draw = ImageDraw.Draw(sheet); font = ImageFont.load_default()
    baseline = relatorio["frames"][0].get("baseline", {}).get("expected_y")
    px = relatorio["frames"][0].get("pivot", {}).get("expected_x"); py = relatorio["frames"][0].get("pivot", {}).get("expected_y")
    for idx, (im, info) in enumerate(zip(imagens, frames)):
        col, row = idx%cols, idx//cols; ox, oy = col*cell_w+8, row*cell_h+28
        shown = im if escala == 1 else im.resize((im.width*escala, im.height*escala), Image.Resampling.NEAREST)
        sheet.alpha_composite(shown, (ox, oy))
        draw.text((col*cell_w+8, row*cell_h+5), f"{idx+1:03d} {info['filename']}", fill=(245,245,245,255), font=font)
        if baseline is not None: draw.line((ox, oy+baseline*escala, ox+im.width*escala-1, oy+baseline*escala), fill=(255,210,0,255))
        if px is not None and py is not None:
            x, y = ox+px*escala, oy+py*escala; draw.line((x-4,y,x+4,y), fill=(255,0,255,255)); draw.line((x,y-4,x,y+4), fill=(255,0,255,255))
    saida.parent.mkdir(parents=True, exist_ok=True); sheet.save(saida, format="PNG", optimize=False, compress_level=9)
    for im in imagens: im.close()
