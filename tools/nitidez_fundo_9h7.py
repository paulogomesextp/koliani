"""Execution 9H.7 -- fundo da Regiao I desenhado a 1:1 no pixel do ecra.

    python tools/nitidez_fundo_9h7.py            # produz
    python tools/nitidez_fundo_9h7.py --validar  # so verifica

PORQUE: o Game Master voltou a dizer que "os backgrounds estao desfocados".
Estavam. Cada camada de fundo da Regiao I e' desenhada com
`TEXTURE_FILTER_LINEAR` a uma AMPLIACAO de 2,1x a 3,6x no pixel do ecra
(escala no mundo x zoom 1,4 da camara), a partir de pinturas pequenas -- o
panorama tem 952x247 e as pecas de fundo 50-200 px. Ampliacao bilinear e'
interpolacao: quanto mais se amplia, mais macia fica. A 9H atacou so o
panorama (4,2x -> 2,1x) e deixou a serra, as arvores, as ruinas, as cascatas
e o primeiro plano -- que sao a maior parte do ecra -- nos 2,5x-3,6x.

O QUE ISTO FAZ: amplia no DISCO, ao fator exato a que cada camada desenha,
trocando a interpolacao do GPU (bilinear, 2 amostras por eixo) por Lanczos
(janela larga) + a mascara de desfoque que qualquer reamostragem obriga a
repor. O jogo passa a dividir a escala pelo mesmo fator, portanto:
  - a geometria no mundo NAO muda (k x (e/k) = e);
  - a composicao aprovada NAO muda (nenhum pixel e' pintado ou movido);
  - a ampliacao que sobra para o GPU passa a ~1:1 (0,84x-1,21x).

NAO inventa desenho: nao pinta, nao gera, nao recompoe, nao recolore. Os
originais ficam (sao a prova do recorte 1:1 da autoridade).
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

RAIZ = Path(__file__).resolve().parent.parent
DIR_BG = RAIZ / "assets/art/regions/region_01_forest/production/backgrounds"
DIR_KIT = RAIZ / "assets/art/regions/region_01_forest/production/kit_9c"

# O panorama e' a camada 4 e desenha-se a 3x no mundo: 3 x 1,4 = 4,2x no
# ecra. x4 no disco deixa 1,05x para o GPU -- 1:1 na pratica.
PANORAMA = ["region1_panorama_heart_tree", "region1_panorama_left_cap",
	"region1_panorama_right_cap"]
FATOR_PANORAMA = 4

# As pecas do kit desenham-se a 1,8x-3,0x no mundo (2,5x-4,2x no ecra). x3 no
# disco deixa 0,84x-1,4x -- a nevoa e' a unica acima de 1,2x, e e' nevoa.
KIT = [
	"fundo/fundo_montanhas.png", "fundo/fundo_cascata.png",
	"fundo/fundo_colunas_cascata.png", "fundo/fundo_arco_ruina.png",
	"fundo/fundo_arvore_a.png", "fundo/fundo_arvore_b.png",
	"fundo/fundo_arvores_par.png", "fundo/frente_vegetacao.png",
	"atmosfera/nevoa.png",
	"corrupcao/cristal_corrupcao_a.png", "corrupcao/cristal_corrupcao_b.png",
	"corrupcao/cristal_corrupcao_c.png", "corrupcao/cristal_corrupcao_d.png",
	"props/ruina.png", "props/cascata.png",
	"props/vinha_a.png", "props/vinha_b.png", "props/vinha_longa.png",
]
FATOR_KIT = 3

# Mascara de desfoque. O raio acompanha o fator (a acutancia tem de ser
# reposta na frequencia certa: a 9H mediu 2,0 px para x2, ou seja raio = k).
# 95 % foi o ponto em que a aresta ganha contraste sem halo claro; acima de
# 140 % via-se auréola nas ruinas.
PERCENT = 95
THRESHOLD = 2
SUFIXO = "_hd"


def sha(c: Path) -> str:
	return hashlib.sha256(c.read_bytes()).hexdigest()


def destino(origem: Path, k: int) -> Path:
	return origem.with_name("%s%s_x%d.png" % (origem.stem, SUFIXO, k))


def _reparar_borda(im: Image.Image) -> Image.Image:
	"""Copia o vizinho para cima da coluna/linha de fora.

	O recorte do panorama (6A, caixa 18,97,952,247 na prancha 08) leva uma
	coluna da MOLDURA do painel em cada lado: a coluna 0 do panorama e do cap
	esquerdo tem luminancia media 55 contra 148 na coluna 1, e as colunas da
	direita 19 contra 27. As pontas do panorama sao ESPELHADAS e encostadas
	uma a outra, portanto essa coluna escura aparecia a dobrar -- ampliada 3x
	era a risca vertical escura de 6 px que se via no L5 (antes da 9H.7 estava
	escondida porque o fundo saturava a azul, ver `nitidez_fundo.gdshader`).

	Nao inventa pixeis: repete o pixel aprovado que esta' ao lado. A caixa e o
	tamanho ficam iguais, portanto a composicao nao se move.
	"""
	w, h = im.size
	im = im.copy()
	im.paste(im.crop((1, 0, 2, h)), (0, 0))
	im.paste(im.crop((w - 2, 0, w - 1, h)), (w - 1, 0))
	im.paste(im.crop((0, 1, w, 2)), (0, 0))
	im.paste(im.crop((0, h - 2, w, h - 1)), (0, h - 1))
	return im


def _orlar(im: Image.Image, p: int) -> Image.Image:
	"""A imagem com uma orla de `p` px copiada da propria borda."""
	w, h = im.size
	fora = Image.new(im.mode, (w + p * 2, h + p * 2))
	fora.paste(im, (p, p))
	fora.paste(im.crop((0, 0, 1, h)).resize((p, h)), (0, p))
	fora.paste(im.crop((w - 1, 0, w, h)).resize((p, h)), (w + p, p))
	fora.paste(fora.crop((0, p, w + p * 2, p + 1)).resize((w + p * 2, p)), (0, 0))
	fora.paste(fora.crop((0, h + p - 1, w + p * 2, h + p)).resize((w + p * 2, p)),
		(0, h + p))
	return fora


def ampliar(origem: Path, k: int, reparar: bool = False) -> tuple[Path, tuple[int, int]]:
	im = Image.open(origem).convert("RGBA")
	if reparar:
		im = _reparar_borda(im)
	tam = (im.width * k, im.height * k)
	# Lanczos mistura a cor dos pixeis transparentes (que nas silhuetas e'
	# arbitraria) para dentro da franja. Premultiplica pelo alfa, reamostra, e
	# desfaz: sem isto as arvores e a banda de primeiro plano ganham halo.
	rgb = Image.merge("RGB", im.split()[:3])
	alfa = im.getchannel("A")
	prem = Image.merge("RGB", [
		ImageChops.multiply(c, alfa) for c in rgb.split()])
	prem = prem.resize(tam, Image.LANCZOS)
	alfa_g = alfa.resize(tam, Image.LANCZOS)
	px_a = alfa_g.load()
	px_p = prem.load()
	fora = Image.new("RGB", tam)
	px_o = fora.load()
	for y in range(tam[1]):
		for x in range(tam[0]):
			a = px_a[x, y]
			if a == 0:
				px_o[x, y] = (0, 0, 0)
			else:
				r, g, b = px_p[x, y]
				px_o[x, y] = (min(255, r * 255 // a), min(255, g * 255 // a),
					min(255, b * 255 // a))
	# A mascara de desfoque so na cor: no alfa desenhava franja dura. E sobre
	# a imagem ORLADA por replicacao: na borda o filtro nao tem vizinhos e
	# afia contra o vazio, o que escurece a coluna de fora. As pontas do
	# panorama sao espelhadas e encostadas uma a outra, portanto esse degrade
	# escuro aparecia a dobrar -- era a risca vertical escura que se via no L5.
	fora = _orlar(fora, 2 * k).filter(ImageFilter.UnsharpMask(
		radius=float(k), percent=PERCENT, threshold=THRESHOLD)).crop(
			(2 * k, 2 * k, 2 * k + tam[0], 2 * k + tam[1]))
	grande = fora.convert("RGBA")
	grande.putalpha(alfa_g)
	saida = destino(origem, k)
	grande.save(saida)
	return saida, grande.size


def pecas() -> list[tuple[Path, int, bool]]:
	lista: list[tuple[Path, int, bool]] = []
	for nome in PANORAMA:
		lista.append((DIR_BG / (nome + ".png"), FATOR_PANORAMA, True))
	for rel in KIT:
		# As pecas do kit ja' vem limpas da borda do painel (a 9C inunda a
		# auréola a partir da borda); so o panorama da 6A e' que nao.
		lista.append((DIR_KIT / rel, FATOR_KIT, False))
	return lista


def main(argv: list[str]) -> int:
	validar = "--validar" in argv
	manifesto: dict = {"fator_panorama": FATOR_PANORAMA, "fator_kit": FATOR_KIT,
		"unsharp": {"raio": "k", "percent": PERCENT, "threshold": THRESHOLD},
		"pecas": {}}
	falhas = 0
	for origem, k, reparar in pecas():
		if not origem.exists():
			print("FALHA: falta", origem)
			falhas += 1
			continue
		alvo = destino(origem, k)
		if validar:
			if not alvo.exists():
				print("FALHA: falta o HD de", origem.name)
				falhas += 1
				continue
			o = Image.open(origem)
			d = Image.open(alvo)
			if d.size != (o.width * k, o.height * k):
				print("FALHA: %s tem %s, esperado %s" % (
					alvo.name, d.size, (o.width * k, o.height * k)))
				falhas += 1
				continue
			if d.mode != "RGBA":
				print("FALHA: %s nao e' RGBA" % alvo.name)
				falhas += 1
				continue
			print("OK   %-44s %s" % (alvo.name, d.size))
		else:
			alvo, tam = ampliar(origem, k, reparar)
			print("%-44s x%d -> %s  sha=%s" % (alvo.name, k, tam, sha(alvo)[:12]))
		rel = alvo.relative_to(RAIZ).as_posix()
		manifesto["pecas"][rel] = {"origem": origem.relative_to(RAIZ).as_posix(),
			"fator": k, "borda_reparada": reparar,
			"sha256": sha(alvo) if alvo.exists() else ""}
	if falhas:
		print("FALHAS:", falhas)
		return 1
	if not validar:
		cam = RAIZ / "assets/art/regions/region_01_forest/production/nitidez_9h7_manifest.json"
		with open(cam, "w", encoding="utf-8", newline="\n") as f:
			json.dump(manifesto, f, indent="\t", ensure_ascii=False)
			f.write("\n")
		print("manifesto:", cam.relative_to(RAIZ).as_posix())
	print("9H.7 nitidez: %d pecas OK" % len(manifesto["pecas"]))
	return 0


if __name__ == "__main__":
	sys.exit(main(sys.argv[1:]))
