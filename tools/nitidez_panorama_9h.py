"""Execution 9H -- panorama da Regiao I em dobro, com acutancia reposta.

    python tools/nitidez_panorama_9h.py

O panorama de fundo da Regiao I (prancha 08) e' um recorte 1:1 de 952x247 e
o jogo desenhava-o a 3x com filtro LINEAR, ainda por cima com o zoom 1,4 da
camara por cima: ~4,2x de ampliacao bilinear. E' isso que o Game Master viu
("o background esta' desfocado") -- ampliacao bilinear e' interpolacao, e
quanto mais se amplia mais macia fica.

O recorte e' 1:1 da autoridade: NAO ha' mais detalhe para ir buscar. O que se
pode fazer -- e e' o que isto faz -- e' trocar a interpolacao do GPU (bilinear,
2 amostras por eixo) por uma melhor feita aqui (Lanczos, janela larga) e
repor a acutancia que qualquer reamostragem come (mascara de desfoque). O
jogo passa a desenhar a 1,5x em vez de 3x: metade da ampliacao bilinear, com
a mesma geometria no mundo.

Nao inventa desenho: nao pinta, nao gera, nao muda a composicao. Sai
`<nome>_x2.png` ao lado do original; o original fica (e' a prova do recorte).
"""
from __future__ import annotations

import hashlib
import sys
from pathlib import Path

from PIL import Image, ImageFilter

RAIZ = Path(__file__).resolve().parent.parent
DIR = RAIZ / "assets/art/regions/region_01_forest/production/backgrounds"
PECAS = ["region1_panorama_heart_tree", "region1_panorama_left_cap",
	"region1_panorama_right_cap"]
FATOR = 2
# Mascara de desfoque: raio em px da imagem JA' ampliada. 2,0/95/2 foi o
# ponto em que a aresta ganha contraste sem desenhar halo claro a` volta das
# ruinas (a 140 % ja' se via).
UNSHARP = (2.0, 95, 2)


def sha(c: Path) -> str:
	return hashlib.sha256(c.read_bytes()).hexdigest()


def main() -> int:
	if not DIR.exists():
		print("FALHA: falta", DIR)
		return 1
	for nome in PECAS:
		origem = DIR / (nome + ".png")
		if not origem.exists():
			print("FALHA: falta", origem)
			return 1
		im = Image.open(origem).convert("RGBA")
		grande = im.resize((im.width * FATOR, im.height * FATOR), Image.LANCZOS)
		grande = grande.filter(ImageFilter.UnsharpMask(
			radius=UNSHARP[0], percent=UNSHARP[1], threshold=UNSHARP[2]))
		destino = DIR / ("%s_x%d.png" % (nome, FATOR))
		grande.save(destino)
		print("%-46s %s -> %s  sha=%s" % (destino.name, im.size, grande.size,
			sha(destino)[:12]))
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
