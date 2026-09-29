#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Gera as SKINS da Koliani (Loja > Skins): o Golden Set com um CONJUNTO de
armadura e arma por cima.

Uma skin e' o Golden Set INTEIRO (`assets/sprites/koliani_golden_set/frames/`,
84 frames, todas as animacoes) vestido com pecas desenhadas a proposito
(`tools/trajes_koliani.py`), mesmo contrato de canvas (128x128, pes em
y=104). A colisao, os tempos e a hitbox nao mudam: o `koliani.gd` so' troca a
pasta de onde le os frames (`CosmeticosVisuais.DIR_SKIN`).

Por frame:
  1. ancora -- centro da cara e topo do ombro (pele), lamina (magenta);
  2. paleta -- troca por material (acento/tecido/gema; a pele nunca muda);
  3. arma -- apaga a lamina magenta e desenha a arma nova na mesma reta;
  4. pecas -- ombreira e cabeca por cima, asas por baixo do corpo.
Os tres frames rodados do rolamento vestem-se no original e rodam-se juntos.

  python tools/gerar_skins_koliani.py            # grava as 3 skins + pecas/
  python tools/gerar_skins_koliani.py --preview  # + folha em work/skins_koliani/

Saida: `assets/sprites/koliani_skins/<skin>/frames/<anim>/<png>` +
`preview.png` (cartao da Loja) e `assets/sprites/koliani_skins/pecas/`
(as pecas soltas). Depois: `godot --headless --import`.
"""

from __future__ import annotations

import colorsys
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import trajes_koliani as T  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GOLDEN = os.path.join(RAIZ, "assets", "sprites", "koliani_golden_set", "frames")
DEST = os.path.join(RAIZ, "assets", "sprites", "koliani_skins")
# o `run_native` so' existe quando a arte nativa chegar; se chegar, entra aqui
# sozinho (espelha-se tudo o que houver em frames/).


def _hx(s: str) -> tuple[float, float, float]:
	s = s.lstrip("#")
	return tuple(int(s[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


# Rampas: (brilho do pixel original 0..1, cor). O brilho do Golden Set e' baixo
# (roupa ~0.10-0.30, acentos ~0.25-0.70), por isso as paragens concentram-se ai.
SKINS: dict[str, dict] = {
	# Regiao IV -- Fornalha. Brasa viva sobre carvao: o lenco e as pontas do
	# cabelo ficam metal fundido, a roupa passa a ferro queimado.
	"fornalha": {
		"acento": [(0.00, "1A0804"), (0.22, "5C1606"), (0.42, "B8380A"),
				   (0.62, "F07818"), (0.85, "FFC048"), (1.00, "FFF0B0")],
		"tecido": [(0.00, "0E0908"), (0.12, "1E1512"), (0.24, "33231C"),
				   (0.40, "54392A"), (0.70, "8A6A50")],
		"forca_tecido": 0.85,
		"gema": "FFD040",
		"conjunto": {
			"cabeca": ("cornos", ["2A1E1A", "4A3A32", "A89478", "D8C8A8", "F4ECD8", "FFFFFF"], "FFB030"),
			"ombreira": ("OMBREIRA_ESPIGAO", ["1A1414", "2E2624", "4A3E3A", "6E625C", "9A8A80", "D8C8B8"], "FF9020"),
			"arma": ("espada_brasa", {"lamina": "2A2220", "gume": "FF8A1E", "fio": "FFE08A",
									  "guarda": "5A4A40", "punho": "3A2A20"}),
		},
	},
	# Regiao IX -- Abadia Afogada. Agua funda: acentos verde-agua a brilhar,
	# roupa azul-ardosia como pano encharcado.
	"abadia_afogada": {
		"acento": [(0.00, "03141A"), (0.22, "0A3A44"), (0.42, "15777A"),
				   (0.62, "35B8A8"), (0.85, "8CEBD6"), (1.00, "E0FFF6")],
		"tecido": [(0.00, "070B12"), (0.12, "111A28"), (0.24, "1C2A40"),
				   (0.40, "2E4462"), (0.70, "5A7898")],
		"forca_tecido": 0.9,
		"gema": "F2F6FF",
		"conjunto": {
			"cabeca": ("CAPUZ", ["0C1A26", "1C3446", "2E5068", "4A7490", "8CEBD6", "E0FFF6"], "5CE0C8"),
			"arma": ("lanca_mare", {"lamina": "8CEBD6", "gume": "35B8A8", "fio": "E0FFF6",
									"guarda": "2E5068", "punho": "4A3A30"}),
		},
	},
	# Regiao XIV -- Planicies Celestiais. A inversa das outras: roupa marfim e
	# prata, acentos ouro. O contorno fica escuro para ela nao se perder no ceu.
	"celestial": {
		"acento": [(0.00, "2A1404"), (0.22, "74420A"), (0.42, "C8861A"),
				   (0.62, "F4BE36"), (0.85, "FFE680"), (1.00, "FFFBE0")],
		"tecido": [(0.00, "16141C"), (0.07, "2C2A36"), (0.12, "6E6A7C"),
				   (0.20, "A8A4B8"), (0.30, "D2CEDD"), (0.50, "F0EEF6")],
		"forca_tecido": 1.0,
		"gema": "7FD8FF",
		"conjunto": {
			"costas": ("asa", ["2C2A36", "6E6A7C", "B8B4C8", "DCD8E6", "F0EEF6", "FFFFFF"]),
			"ombreira": ("OMBREIRA_ASA", ["6A4A12", "A87420", "D8A030", "F4BE36", "FFE680", "FFFBE0"], "FFFFFF"),
			"cabeca": ("AUREOLA", ["C8861A", "C8861A", "C8861A", "C8861A", "C8861A", "FFF4C0"], "FFE680"),
			"arma": ("espada_sol", {"lamina": "F4F4FA", "gume": "FFE680", "fio": "E0BE4A",
									"guarda": "F4BE36", "punho": "6A4A12"}),
		},
	},
	# Regiao XIX -- Portal Dimensional. Roxo do vazio e magenta a brilhar (o
	# tema da key art); coroa de espinhos, capa rasgada e foice.
	"vazio": {
		"acento": [(0.00, "12041A"), (0.22, "3A0C4A"), (0.42, "7A1A90"),
				   (0.62, "C83CD8"), (0.85, "F29AF8"), (1.00, "FFE6FF")],
		"tecido": [(0.00, "08060C"), (0.12, "141020"), (0.24, "221A34"),
				   (0.40, "3A2C54"), (0.70, "6A5890")],
		"forca_tecido": 0.9,
		"gema": "FF6AF0",
		"conjunto": {
			"costas_capa": (["0A0810", "1A1428", "2C2244", "3E3260", "B86AD8", "F29AF8"], "FF6AF0"),
			"cabeca": ("COROA_ESPINHOS", ["2A1A34", "4A3460", "6A5090", "9A80C0", "D0C0F0", "FFFFFF"], "FF6AF0"),
			"arma": ("foice", {"lamina": "C8C0E0", "gume": "FF6AF0", "fio": "FFFFFF",
							   "guarda": "4A3460", "punho": "2A1E30"}),
		},
	},
}

# Os conjuntos (pecas desenhadas) usam as mesmas rampas que as tres skins SO'
# de paleta que o Paulo aprovou (29 set): essas ficam com a pasta/id originais
# (fornalha, abadia_afogada, celestial) e os conjuntos ganham pasta propria.
for _novo, _base in (("guardia_forja", "fornalha"), ("abadessa_afogada", "abadia_afogada"),
					 ("serafim_celestial", "celestial")):
	SKINS[_novo] = dict(SKINS[_base])
	SKINS[_base] = {k: v for k, v in SKINS[_base].items() if k != "conjunto"}

# Brilho abaixo do qual o pixel e' contorno e nao muda (a silhueta).
CONTORNO_V = 0.07


def _rampa(paragens: list, v: float) -> tuple[float, float, float]:
	pts = [(p, _hx(c)) for p, c in paragens]
	if v <= pts[0][0]:
		return pts[0][1]
	for (p0, c0), (p1, c1) in zip(pts, pts[1:]):
		if v <= p1:
			t = (v - p0) / (p1 - p0) if p1 > p0 else 0.0
			return tuple(c0[i] + (c1[i] - c0[i]) * t for i in range(3))
	return pts[-1][1]


def _suave(a: float, b: float, x: float) -> float:
	"""smoothstep de a para b (a > b inverte)."""
	if a == b:
		return 1.0 if x >= a else 0.0
	t = max(0.0, min(1.0, (x - a) / (b - a)))
	return t * t * (3.0 - 2.0 * t)


def _pesos(h: float, s: float, v: float) -> tuple[float, float, float]:
	"""(acento, pele, gema) em 0..1; o tecido e' o que sobra."""
	hd = h * 360.0
	sat = _suave(0.16, 0.34, s)
	# acento: vermelho/magenta. Distancia ao centro 342 graus, a dar a volta.
	d = min(abs(hd - 342.0), 360.0 - abs(hd - 342.0))
	acento = sat * _suave(34.0, 24.0, d)
	# pele: laranja claro (inclui os realces 255,212,176)
	pele = _suave(0.10, 0.16, s) * _suave(0.36, 0.48, v) \
		* _suave(7.0, 12.0, hd) * _suave(50.0, 42.0, hd)
	# couro/pele na sombra (10..20 graus, escuro): tambem nao se mexe
	sombra = _suave(0.30, 0.45, s) * _suave(7.0, 12.0, hd) * _suave(26.0, 20.0, hd)
	pele = max(pele, sombra)
	gema = sat * _suave(130.0, 145.0, hd) * _suave(220.0, 205.0, hd)
	return acento, pele, gema


def recolorir(img: Image.Image, skin: dict) -> Image.Image:
	img = img.convert("RGBA")
	px = img.load()
	w, h = img.size
	gema = _hx(skin["gema"])
	forca = float(skin["forca_tecido"])
	cache: dict = {}
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a == 0:
				continue
			chave = (r, g, b)
			if chave not in cache:
				cache[chave] = _pixel(r, g, b, skin, gema, forca)
			nr, ng, nb = cache[chave]
			px[x, y] = (nr, ng, nb, a)
	return img


def _pixel(r: int, g: int, b: int, skin: dict, gema, forca: float) -> tuple[int, int, int]:
	rf, gf, bf = r / 255.0, g / 255.0, b / 255.0
	h, s, v = colorsys.rgb_to_hsv(rf, gf, bf)
	orig = (rf, gf, bf)
	if v < CONTORNO_V:
		return r, g, b
	w_ac, w_pe, w_ge = _pesos(h, s, v)
	w_ac *= 1.0 - w_pe
	w_ge *= 1.0 - w_pe
	w_te = max(0.0, 1.0 - w_ac - w_pe - w_ge) * forca
	# brilho de referencia: o V original (mantem o volume desenhado)
	ac = _rampa(skin["acento"], v)
	te = _rampa(skin["tecido"], v)
	ge = tuple(min(1.0, c * (0.45 + 0.75 * v)) for c in gema)
	out = []
	for i in range(3):
		c = orig[i] * (1.0 - w_ac - w_te - w_ge) + ac[i] * w_ac + te[i] * w_te + ge[i] * w_ge
		out.append(int(round(max(0.0, min(1.0, c)) * 255)))
	# contorno suave: entre CONTORNO_V e o dobro, volta aos poucos ao original
	k = _suave(CONTORNO_V, CONTORNO_V * 2.0, v)
	return tuple(int(round(r0 + (o - r0) * k)) for r0, o in zip((r, g, b), out))


def _pngs(raiz: str):
	for d, _sub, fs in os.walk(raiz):
		for f in sorted(fs):
			if f.lower().endswith(".png"):
				yield os.path.join(d, f)


CONTORNO_PECAS = "0A0808"

# Frames do rolamento que sao o `jump_loop_003` RODADO (derivados na 9B.4 por
# rotacao exata; confirmado por comparacao pixel a pixel). Veste-se o original
# e roda-se o resultado -- assim cornos, asas e arma rodam com o corpo.
RODADOS = {
	"roll/roll_003.png": ("jump_loop/jump_loop_003.png", 270),
	"roll/roll_004.png": ("jump_loop/jump_loop_003.png", 180),
	"roll/roll_005.png": ("jump_loop/jump_loop_003.png", 90),
}


def _peca_cabeca(spec) -> tuple:
	nome, rampa, brilho = spec
	if nome == "cornos":
		return T.cornos(rampa, CONTORNO_PECAS, brilho)
	return T.desenhar(getattr(T, nome), rampa, CONTORNO_PECAS, brilho)


def vestir(orig: Image.Image, skin: dict, indice: int = 0) -> Image.Image:
	"""Golden Set -> skin: paleta + conjunto (arma, ombreira, cabeca, costas)."""
	orig = orig.convert("RGBA")
	cara = T.ancora_cara(orig)
	lam = T.lamina(orig, cara) if cara else None
	im = recolorir(orig, skin)
	cj = skin.get("conjunto", {})
	if cara is None:
		return im
	if "arma" in cj:
		im = T.trocar_arma(im, lam, cj["arma"][0], cj["arma"][1], CONTORNO_PECAS)
	if "costas" in cj:
		# bate as asas: abre e fecha de frame para frame
		asa = T.asa(cj["costas"][1], CONTORNO_PECAS, 1.0 if (indice // 2) % 2 == 0 else 0.45)
		im = T.colar(im, *asa, (cara[0] - 6, cara[1] + 9), False)
	if "costas_capa" in cj:
		rampa, brilho = cj["costas_capa"]
		vento = 0.0 if indice < 0 else (0.25 if (indice // 2) % 2 == 0 else 0.45)
		cp = T.capa(rampa, CONTORNO_PECAS, brilho, vento)
		im = T.colar(im, *cp, (cara[0] - 4, cara[1] + 6), False)
	if "ombreira" in cj:
		o = T.ancora_ombro(orig, cara)
		if o:
			g, rampa, brilho = cj["ombreira"]
			im = T.colar(im, *T.ombreira(getattr(T, g), rampa, CONTORNO_PECAS, brilho), o, True)
	if "cabeca" in cj:
		im = T.colar(im, *_peca_cabeca(cj["cabeca"]), cara, True)
	return im


def _rodar_como(vestida_fonte: Image.Image, fonte: Image.Image, alvo: Image.Image, ang: int) -> Image.Image:
	"""Roda `vestida_fonte` `ang` graus e alinha-a pelo corpo original, para o
	corpo cair exatamente onde esta' no frame derivado `alvo`."""
	rv = vestida_fonte.rotate(ang, expand=True)
	rf = fonte.rotate(ang, expand=True)
	# o corpo (sem pecas) dentro da imagem rodada
	bf = rf.getbbox()
	ba = alvo.getbbox()
	dx, dy = ba[0] - bf[0], ba[1] - bf[1]
	out = Image.new("RGBA", alvo.size, (0, 0, 0, 0))
	out.paste(rv, (dx, dy), rv)
	return out


def preview_loja(skin_dir: str) -> Image.Image:
	"""Cartao da Loja: um golpe (mostra a arma) recortado a figura, com folga."""
	im = Image.open(os.path.join(skin_dir, "frames", "attack_basic", "attack_basic_003.png")).convert("RGBA")
	x0, y0, x1, y1 = im.getbbox()
	lado = max(x1 - x0, y1 - y0) + 6
	cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
	return im.crop((cx - lado // 2, cy - lado // 2, cx - lado // 2 + lado, cy - lado // 2 + lado))


def exportar_pecas() -> None:
	"""As pecas soltas (x1), para rever e para futuros icones."""
	dest = os.path.join(DEST, "pecas")
	os.makedirs(dest, exist_ok=True)
	for nome, skin in SKINS.items():
		cj = skin.get("conjunto", {})
		if "cabeca" in cj:
			_peca_cabeca(cj["cabeca"])[0].save(os.path.join(dest, f"{nome}_cabeca.png"))
		if "ombreira" in cj:
			g, rampa, brilho = cj["ombreira"]
			T.ombreira(getattr(T, g), rampa, CONTORNO_PECAS, brilho)[0].save(os.path.join(dest, f"{nome}_ombreira.png"))
		if "costas_capa" in cj:
			T.capa(cj["costas_capa"][0], CONTORNO_PECAS, cj["costas_capa"][1])[0].save(os.path.join(dest, f"{nome}_capa.png"))
		if "costas" in cj:
			T.asa(cj["costas"][1], CONTORNO_PECAS, 1.0)[0].save(os.path.join(dest, f"{nome}_asa.png"))
		if "arma" in cj:
			from PIL import ImageDraw
			tela = Image.new("RGBA", (40, 12), (0, 0, 0, 0))
			d = ImageDraw.Draw(tela)
			tipo, cores = cj["arma"]
			comp = {"lanca_mare": 18, "foice": 16}.get(tipo, 24)
			T.ARMAS[tipo](d, (6.0, 6.0), (1.0, 0.0), comp, {k: T._hx(v) for k, v in cores.items()})
			T.contornar(tela, T._hx(CONTORNO_PECAS)).save(os.path.join(dest, f"{nome}_arma_{tipo}.png"))


def gerar() -> None:
	fontes = {os.path.relpath(f, GOLDEN).replace(os.sep, "/"): f for f in _pngs(GOLDEN)}
	for nome, skin in SKINS.items():
		base = os.path.join(DEST, nome)
		vestidas = {}
		for i, (rel, f) in enumerate(sorted(fontes.items())):
			if rel in RODADOS:
				continue
			num = int(os.path.splitext(rel)[0].rsplit("_", 1)[-1]) if rel[-7:-4].isdigit() else i
			vestidas[rel] = vestir(Image.open(f), skin, num)
		for rel, (fonte, ang) in RODADOS.items():
			if rel in fontes and fonte in vestidas:
				vestidas[rel] = _rodar_como(vestidas[fonte], Image.open(fontes[fonte]).convert("RGBA"),
										   Image.open(fontes[rel]).convert("RGBA"), ang)
		for rel, im in vestidas.items():
			dst = os.path.join(base, "frames", rel)
			os.makedirs(os.path.dirname(dst), exist_ok=True)
			im.save(dst, optimize=True)
		preview_loja(base).save(os.path.join(base, "preview.png"), optimize=True)
		print(f"skin {nome}: {len(vestidas)} frames")
	exportar_pecas()


def folha_previews(saida: str) -> None:
	"""Base + cada skin em idle/run/ataque/salto, x4, lado a lado."""
	poses = ["idle/idle_001.png", "run_final/run_004.png", "attack_basic/attack_basic_004.png",
			 "jump_loop/jump_loop_002.png", "dash/dash_002.png"]
	fontes = [("base", GOLDEN)] + [(n, os.path.join(DEST, n, "frames")) for n in SKINS]
	cel, esc = 96, 3
	folha = Image.new("RGBA", (len(poses) * cel * esc, len(fontes) * cel * esc), (26, 18, 30, 255))
	for j, (_n, d) in enumerate(fontes):
		for i, p in enumerate(poses):
			im = Image.open(os.path.join(d, p)).convert("RGBA").crop((16, 16, 112, 112))
			im = im.resize((cel * esc, cel * esc), Image.NEAREST)
			folha.alpha_composite(im, (i * cel * esc, j * cel * esc))
	os.makedirs(os.path.dirname(saida), exist_ok=True)
	folha.save(saida)
	print("preview:", saida)


if __name__ == "__main__":
	gerar()
	if "--preview" in sys.argv:
		folha_previews(os.path.join(RAIZ, "work", "skins_koliani", "folha_skins.png"))
