"""Compõe as capturas reais da Execution 6B sem alterar o seu conteúdo."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


RAIZ = Path(__file__).resolve().parents[1]
PREVIEW = RAIZ / "work/execution_6b/preview"
SHOTS = PREVIEW / "shots"
FONT = ImageFont.load_default()


def rotulo(canvas: Image.Image, text: str, x: int, y: int) -> None:
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((x, y, x + 638, y + 24), fill=(8, 10, 17))
    draw.text((x + 8, y + 7), text, fill=(240, 240, 246), font=FONT)


def nivel() -> Image.Image:
    names = ["level_opening", "level_traversal", "level_platforms", "level_heart_tree", "level_enemies", "level_ruins", "level_corruption", "level_exit"]
    canvas = Image.new("RGB", (2560, 720), (10, 12, 20))
    for i, name in enumerate(names):
        img = Image.open(SHOTS / f"{name}.png").convert("RGB").resize((640, 360), Image.Resampling.LANCZOS)
        x, y = (i % 4) * 640, (i // 4) * 360
        canvas.paste(img, (x, y))
        rotulo(canvas, name.replace("level_", "").replace("_", " ").upper(), x, y)
    canvas.save(PREVIEW / "level1_6b_review.png", optimize=True)
    return canvas


def koliani() -> None:
    names = ["koliani_idle"] + [f"koliani_run_{i:02d}" for i in range(3, 10)]
    canvas = Image.new("RGB", (2560, 960), (10, 12, 20))
    for i, name in enumerate(names):
        img = Image.open(SHOTS / f"{name}.png").convert("RGB")
        crop = img.crop((400, 180, 880, 540)).resize((640, 480), Image.Resampling.NEAREST)
        x, y = (i % 4) * 640, (i // 4) * 480
        canvas.paste(crop, (x, y))
        rotulo(canvas, name.replace("koliani_", "").replace("_", " ").upper(), x, y)
    canvas.save(PREVIEW / "koliani_6b_gameplay_review.png", optimize=True)


def comparacao(current: Image.Image) -> None:
    old_path = RAIZ / "work/execution_6a/preview/level1_6a_review.png"
    old = Image.open(old_path).convert("RGB").resize((2560, 720), Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", (2560, 1488), (8, 10, 17))
    canvas.paste(old, (0, 24))
    canvas.paste(current, (0, 768))
    draw = ImageDraw.Draw(canvas)
    draw.text((10, 7), "6A — PARTIAL VISUAL BUILD / CHARACTER CLIPPING PRESENT", fill=(245, 208, 92), font=FONT)
    draw.text((10, 751), "6B — ENVIRONMENT PRESERVED / KOLIANI RUN FIXED / HUMAN REVIEW REQUIRED", fill=(128, 235, 180), font=FONT)
    canvas.save(PREVIEW / "level1_6a_vs_6b.png", optimize=True)


def main() -> None:
    PREVIEW.mkdir(parents=True, exist_ok=True)
    current = nivel()
    koliani()
    comparacao(current)
    print("EXECUTION 6B PREVIEWS: PASS")


if __name__ == "__main__":
    main()
