"""Reextrai a corrida da Koliani pelas células reais da autoridade 05.

O gerador usa apenas crop, segmentação determinística, alpha binário e
normalização nearest-neighbour. Não pinta, interpola nem infere pixels.
"""

from __future__ import annotations

import argparse
from collections import deque
from hashlib import sha256
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


RAIZ = Path(__file__).resolve().parents[1]
FONTE = RAIZ / "Koliani_1.0_Master_Package_v2/references/approved/05_KOLIANI_IDLE_RUN_CLEAN_v1_1.png"
SAIDA = RAIZ / "work/execution_6b/koliani_diagnostics/reextracted_run"
DESTINO = RAIZ / "assets/sprites/pixel/koliani_visual_pilot_5g/run.png"
SEPARADORES = [29, 146, 257, 370, 484, 596, 709, 823, 937, 1048, 1160, 1272, 1389, 1506]
TOPO, FUNDO = 350, 478


def componentes(mascara: np.ndarray) -> list[list[tuple[int, int]]]:
    altura, largura = mascara.shape
    vistos = np.zeros_like(mascara, dtype=bool)
    saida: list[list[tuple[int, int]]] = []
    for y, x in zip(*np.nonzero(mascara)):
        if vistos[y, x]:
            continue
        fila = deque([(int(y), int(x))])
        vistos[y, x] = True
        componente: list[tuple[int, int]] = []
        while fila:
            cy, cx = fila.popleft()
            componente.append((cy, cx))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = cy + dy, cx + dx
                    if not (dy or dx) or not (0 <= ny < altura and 0 <= nx < largura):
                        continue
                    if mascara[ny, nx] and not vistos[ny, nx]:
                        vistos[ny, nx] = True
                        fila.append((ny, nx))
        saida.append(componente)
    return sorted(saida, key=len, reverse=True)


def caixa(componente: list[tuple[int, int]]) -> tuple[int, int, int, int]:
    ys = [p[0] for p in componente]
    xs = [p[1] for p in componente]
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def distancia_caixas(a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> int:
    dx = max(a[0] - b[2], b[0] - a[2], 0)
    dy = max(a[1] - b[3], b[1] - a[3], 0)
    return max(dx, dy)


def extrair(recorte: Image.Image) -> tuple[Image.Image, list[int]]:
    rgb = np.asarray(recorte.convert("RGB"), dtype=np.int16)
    maior, menor = rgb.max(axis=2), rgb.min(axis=2)
    candidata = ~(((maior - menor) <= 17) & (maior >= 22) & (maior <= 78))
    candidata[:2, :] = False
    candidata[:, :2] = False
    candidata[:, -2:] = False
    candidata[-26:, :] = False
    todas = componentes(candidata)
    candidatos = []
    for componente in todas:
        x1, y1, x2, y2 = caixa(componente)
        largura, altura = x2 - x1, y2 - y1
        centro = (x1 + x2) / 2
        if altura < 20 or largura > recorte.width * 0.88:
            continue
        if not recorte.width * 0.08 <= centro <= recorte.width * 0.92:
            continue
        candidatos.append((altura * 12 + len(componente) - largura * 2, componente))
    if not candidatos:
        raise RuntimeError("Nenhuma personagem separável na célula")
    principal = max(candidatos, key=lambda item: item[0])[1]
    escolhidas = [principal]
    # Botas e pernas escuras podem formar componentes separados sobre o
    # checkerboard. Junta apenas ilhas observadas que encostam à silhueta já
    # provada; moldura e número foram excluídos acima.
    mudou = True
    while mudou:
        mudou = False
        caixas = [caixa(item) for item in escolhidas]
        for componente in todas:
            if componente in escolhidas or len(componente) < 4:
                continue
            box = caixa(componente)
            if box[0] < 3 or box[2] > recorte.width - 3:
                continue
            if min(distancia_caixas(box, atual) for atual in caixas) <= 4:
                escolhidas.append(componente)
                mudou = True
    selecionada = np.zeros(candidata.shape, dtype=bool)
    for componente in escolhidas:
        for y, x in componente:
            selecionada[y, x] = True
    for _ in range(2):
        expandida = selecionada.copy()
        for y, x in zip(*np.nonzero(selecionada)):
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = int(y + dy), int(x + dx)
                    if 0 <= ny < recorte.height and 0 <= nx < recorte.width:
                        pixel = rgb[ny, nx]
                        if pixel.max() < 36 or pixel.max() - pixel.min() > 9:
                            expandida[ny, nx] = True
        selecionada = expandida
    final = componentes(selecionada)
    limpa = np.zeros_like(selecionada)
    for y, x in final[0]:
        limpa[y, x] = True
    ys, xs = np.nonzero(limpa)
    bbox = [int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1)]
    rgba = np.dstack([rgb.astype(np.uint8), np.where(limpa, 255, 0).astype(np.uint8)])
    return Image.fromarray(rgba, "RGBA"), bbox


def normalizar(imagem: Image.Image) -> tuple[Image.Image, list[int]]:
    alpha = np.asarray(imagem)[:, :, 3]
    ys, xs = np.nonzero(alpha)
    bbox = (int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1))
    objeto = imagem.crop(bbox)
    escala = min(1.0, 78 / objeto.height, 140 / objeto.width)
    if escala < 1:
        objeto = objeto.resize((round(objeto.width * escala), round(objeto.height * escala)), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (160, 96), (0, 0, 0, 0))
    x, y = 80 - objeto.width // 2, 90 - objeto.height
    canvas.alpha_composite(objeto, (x, y))
    return canvas, [x, y, x + objeto.width, y + objeto.height]


def main(promover: bool = False) -> None:
    (SAIDA / "raw").mkdir(parents=True, exist_ok=True)
    (SAIDA / "normalized").mkdir(parents=True, exist_ok=True)
    fonte = Image.open(FONTE).convert("RGBA")
    frames = []
    strip = Image.new("RGBA", (160 * 12, 96), (0, 0, 0, 0))
    review = Image.new("RGB", (960, 125 * 2), (18, 19, 25))
    draw = ImageDraw.Draw(review)
    font = ImageFont.load_default()
    for indice in range(12):
        nome = f"run_{indice + 1:02d}"
        box = [SEPARADORES[indice], TOPO, SEPARADORES[indice + 1], FUNDO]
        crop = fonte.crop(box)
        rgba, bbox = extrair(crop)
        norm, bbox_norm = normalizar(rgba)
        touched = []
        if bbox[0] == 0:
            touched.append("left")
        if bbox[2] == crop.width:
            touched.append("right")
        if bbox[1] == 0:
            touched.append("top")
        if bbox[3] == crop.height:
            touched.append("bottom")
        passed = not touched and norm.size == (160, 96) and bbox_norm[3] == 90
        crop.save(SAIDA / f"raw/{nome}_source_crop.png")
        rgba.save(SAIDA / f"raw/{nome}.png")
        norm.save(SAIDA / f"normalized/{nome}.png")
        strip.alpha_composite(norm, (indice * 160, 0))
        frames.append({"frame": nome, "source_box": box, "extracted_bbox": bbox, "normalized_bbox": bbox_norm, "touched_sides": touched, "status": "SAFE" if passed else "BLOCKED"})
        tile = Image.new("RGBA", (160, 96), (35, 36, 44, 255))
        tile.alpha_composite(norm)
        x, y = (indice % 6) * 160, (indice // 6) * 125
        draw.text((x + 3, y + 3), f"{nome} {frames[-1]['status']}", fill=(240, 240, 246), font=font)
        review.paste(tile.convert("RGB"), (x, y + 22))
    strip.save(SAIDA / "run.png")
    review.save(SAIDA / "run_reextraction_review.png")
    report = {
        "source": str(FONTE.resolve()),
        "source_sha256": sha256(FONTE.read_bytes()).hexdigest(),
        "method": "verified_actual_cell_boundaries + deterministic foreground component + nearest normalization",
        "separators": SEPARADORES,
        "frames": frames,
        "summary": {"safe": sum(f["status"] == "SAFE" for f in frames), "blocked": sum(f["status"] != "SAFE" for f in frames)},
    }
    (SAIDA / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    if promover:
        if report["summary"]["blocked"]:
            raise RuntimeError("Promoção recusada: há frames bloqueados")
        strip.save(DESTINO)
        report["promoted_to"] = str(DESTINO.resolve())
        report["promoted_sha256"] = sha256(DESTINO.read_bytes()).hexdigest()
        (SAIDA / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(report["summary"]))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--promote", action="store_true", help="substitui apenas o strip run após gate 12/12")
    args = parser.parse_args()
    main(args.promote)
