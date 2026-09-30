"""Previa animada a partir de fotogramas do renderer real, sem alterar arte."""
from pathlib import Path
from PIL import Image

raiz = Path(__file__).resolve().parents[1]
origem = raiz / 'work/shadowblade_fidelity'
frames = [Image.open(p).convert('RGB').resize((640, 360), Image.Resampling.NEAREST)
          for p in sorted(origem.glob('movimento_*.png'))]
assert frames
frames[0].save(raiz / 'docs/qa/shadowblade_fidelity/movimento.gif', save_all=True,
               append_images=frames[1:], duration=50, loop=0)
print(f'Previa: {len(frames)} fotogramas reais; reproducao nao prova performance do dispositivo.')
