"""Gera apenas fixtures sintéticas versionadas do validator."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).parent / "fixtures"
ROOT.mkdir(parents=True, exist_ok=True)

def save(name, mode="RGBA", size=(32, 32), box=(10, 8, 21, 28), baseline=None):
    bg = (0,0,0,0) if mode == "RGBA" else (90,90,90)
    im = Image.new(mode, size, bg); d = ImageDraw.Draw(im)
    fill = (170,40,190,255) if mode == "RGBA" else (170,40,190)
    d.rectangle(box, fill=fill)
    im.save(ROOT / name)

save("valid_rgba.png")
save("valid_rgba_2.png", box=(11,8,22,28))
save("rgb_no_alpha.png", mode="RGB")
save("clipped_bottom.png", box=(10,8,21,31))
save("wrong_canvas.png", size=(31,32), box=(10,8,20,28))
save("baseline_bad.png", box=(10,5,21,24))
checker = Image.new("RGBA", (32,32), (255,255,255,255)); d = ImageDraw.Draw(checker)
for y in range(0,32,4):
    for x in range(0,32,4):
        d.rectangle((x,y,x+3,y+3), fill=((190,190,190,255) if (x//4+y//4)%2 else (235,235,235,255)))
checker.save(ROOT / "checkerboard.png")
