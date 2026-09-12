"""Execution 9H -- frontend de producao (menu, seletor, icone) a partir das
pranchas aprovadas pelo Game Master em `work/production_art_gate/10_menu_rebrand/`.

    python tools/produzir_frontend_9h.py             # produz tudo
    python tools/produzir_frontend_9h.py --validar   # confere SHAs do manifesto
    python tools/produzir_frontend_9h.py --folha F   # folha de contacto

As duas pranchas de ecra (menu e seletor) sao MAQUETES: arte pintada com a
UI ja' desenhada por cima, em portugues, com um estado de jogo fixo. O que
o jogo precisa e' o contrario -- a arte limpa por baixo e as pecas da UI
soltas, para os rotulos virem do `Textos` e o estado vir do `EstadoJogo`.

Metodo (o mesmo principio do 9G: `efeito = px - fundo`):

  1  MASCARA  as zonas onde esta' pintada UI sao marcadas como buraco;
  2  INPAINT  o buraco e' preenchido por difusao multi-escala (borroes
     gaussianos de raio decrescente, com os pixeis conhecidos repostos a
     cada passo) -> da' a ARTE LIMPA, sem inventar desenho novo;
  3  DIFERENCA  `peca = prancha - arte limpa`, com o alfa preso a' forca
     da diferenca -> da' as PECAS da UI ja' recortadas do fundo pintado.

O passo 2 serve os dois fins de uma vez: o fundo do ecra e a fonte de
extracao. Nenhum texto sobrevive nas imagens.

O icone vem da prancha de branding, que ja' e' quadrada e ja' tem cantos
arredondados pintados: so' precisa de mascara de canto e das medidas.
"""
from __future__ import annotations

import hashlib
import json
import struct
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

RAIZ = Path(__file__).resolve().parent.parent
GATE = RAIZ / "work/production_art_gate/10_menu_rebrand"

PRANCHAS = {
	"menu": (GATE / "01_main_menu_approved/koliani_main_menu_v1.png",
		"22d1ecf0889f02e6445346d2e85716490460010164a5680f69014bbee05d21b6"),
	"seletor": (GATE / "02_level_selector_approved/koliani_level_selector_v1.png",
		"3fbaa747f6da1d4761380f5734a6687f9fb89e6bfe2bd02f148a9be030599323"),
	"icone": (GATE / "04_branding_icon_approved/koliani_logo_icon_v1.png",
		"948e01984a7325d41792f16f65dd73d85a1e64e682db30ab63dc2a4f6ed78066"),
}

SAIDA = RAIZ / "assets/ui/frontend_9h"
SAIDA_ICONE = RAIZ / "assets/branding"
MANIFESTO = SAIDA / "manifesto_frontend_9h.json"

# --------------------------------------------------------------------------
# 1. zonas de UI pintada, por prancha (coordenadas da prancha, 1672x941)
# --------------------------------------------------------------------------

# retangulos: (x0, y0, x1, y1)
LIMPAR_MENU = [
	(812, 281, 1332, 332),    # subtitulo "FLORESTA SAGRADA" + tracos
	(850, 364, 1256, 440),    # placa "Continuar"
	(886, 436, 1218, 458),    # separador 1
	(936, 454, 1168, 508),    # "Novo Jogo"
	(886, 502, 1218, 526),    # separador 2
	(916, 520, 1194, 582),    # "Selecionar Nivel"
	(886, 572, 1218, 596),    # separador 3
	(956, 592, 1154, 654),    # "Opcoes"
	(886, 644, 1218, 668),    # separador 4
	(976, 664, 1130, 724),    # "Sair"
	(886, 788, 1218, 818),    # regua do rodape
	(916, 814, 1184, 858),    # "PREMIR ENTER"
	(1368, 810, 1664, 894),   # versao + "Developed by Paulitos" + ornamento
]

LIMPAR_SELETOR = [
	(14, 12, 194, 84),        # "VOLTAR AO MENU"
	(536, 158, 1140, 202),    # "REGIAO I - FLORESTA CORROMPIDA"
	(696, 200, 976, 220),     # regua + losango
	(686, 220, 986, 270),     # citacao
	(696, 268, 976, 294),     # regua + losango
	(486, 506, 1588, 780),    # painel de detalhe
	(20, 804, 1460, 906),     # abas das regioes
	(1456, 818, 1668, 898),   # citacao do canto
	(4, 376, 112, 508),       # seta "REGIAO ANTERIOR"
	(1582, 376, 1668, 508),   # seta "PROXIMA REGIAO"
	# fichas dos nos (o "1-1" etc.)
	(404, 354, 496, 400), (610, 388, 702, 434), (884, 436, 986, 486),
	(1124, 424, 1218, 472), (1390, 424, 1500, 504),
]

# aneis dos nos: (cx, cy, raio_ext, raio_int) -- so' a coroa e' apagada; o
# interior e' vista, e e' vista que o jogo poe' la' a correr.
ANEIS_SELETOR = [
	(452, 345, 72, 34), (658, 379, 72, 34), (932, 420, 82, 40),
	(1172, 419, 72, 34), (1443, 394, 118, 66),
]

# caminho que liga os nos (linha grossa apagada)
CAMINHO_SELETOR = [(452, 345), (560, 368), (658, 379), (800, 408), (932, 420),
	(1060, 432), (1172, 419), (1300, 408), (1443, 394)]
CAMINHO_ESPESSURA = 26

# --------------------------------------------------------------------------
# 2. pecas a extrair da camada de diferenca
# --------------------------------------------------------------------------
# nome: (prancha, caixa, margens nine-patch na textura FINAL 2x ou None,
#        ganho de alfa)
PECAS = {
	# nome: (prancha, caixa, margens nine-patch 2x ou None, ganho de alfa,
	#        extras) -- extras:
	#   "texto"  zonas (coords da prancha) onde o rotulo pintado e' apagado
	#            por interpolacao horizontal (preserva o gradiente da peca);
	#   "apagar" zonas que ficam totalmente transparentes (conteudo da
	#            maquete que o jogo desenha vivo: fichas, cadeados, miolo);
	#   "oco"    px de bordadura a guardar -- o interior da moldura fica
	#            transparente (o painel e' so' a moldura).
	# --- menu ---------------------------------------------------------
	"placa_selecionada": ("menu", (854, 366, 1254, 438), [110, 26, 110, 26], 3.0,
		{"texto": [(960, 378, 1140, 428)]}),
	"separador_menu": ("menu", (886, 434, 1218, 460), None, 3.4, {}),
	"ornamento_rodape": ("menu", (886, 786, 1218, 820), None, 3.4, {}),
	# --- seletor ------------------------------------------------------
	"painel_detalhe": ("seletor", (486, 506, 1588, 780), [70, 60, 70, 60], 2.2,
		{"oco": 26}),
	"botao_jogar": ("seletor", (862, 696, 1216, 758), [90, 26, 90, 26], 2.8,
		{"texto": [(960, 706, 1120, 750)]}),
	# as abas levam inpaint VERTICAL: o rotulo ocupa quase todo o miolo e a
	# interpolacao horizontal deixava um rasto claro de lado a lado (visto
	# na 2.a corrida). Na vertical a placa so' tem gradiente, e fecha bem.
	"aba_atual": ("seletor", (26, 810, 288, 902), [36, 28, 36, 28], 3.2,
		{"texto_v": [(40, 824, 274, 892)]}),
	"aba_bloqueada": ("seletor", (310, 812, 570, 898), [36, 28, 36, 28], 3.2,
		{"texto_v": [(326, 824, 556, 890)]}),
	"seta_esquerda": ("seletor", (12, 382, 74, 458), None, 3.2, {}),
	"seta_direita": ("seletor", (1598, 382, 1660, 458), None, 3.2, {}),
	"voltar_seta": ("seletor", (20, 18, 74, 76), None, 3.2, {}),
	"ficha_nivel": ("seletor", (884, 434, 986, 488), [30, 14, 30, 14], 3.0,
		{"texto": [(900, 448, 970, 476)]}),
	"cadeado": ("seletor", (348, 850, 384, 890), None, 3.0, {}),
	"losango": ("seletor", (566, 838, 610, 882), None, 3.4, {}),
}

# aneis extraidos a parte (recorte circular da camada de diferenca)
# nome: (cx, cy, raio, zonas a apagar dentro do recorte -- a ficha pintada,
# que o jogo volta a desenhar viva por cima)
ANEIS_PECA = {
	"anel_normal": (452, 345, 62, [(412, 356, 492, 404)]),
	"anel_atual": (932, 420, 72, [(886, 436, 982, 490)]),
	"anel_chefe": (1443, 394, 106, [(1392, 424, 1496, 502)]),
}

ESCALA = 2          # as pranchas sao pintura: as pecas saem a 2x (LANCZOS)
LARGURA_ECRA = 1920  # o fundo do ecra sai a 1920x1080 (16:9 exato)
ALTURA_ECRA = 1080


# --------------------------------------------------------------------------
# ferramentas
# --------------------------------------------------------------------------
def sha(caminho: Path) -> str:
	return hashlib.sha256(caminho.read_bytes()).hexdigest()


def mascara_buraco(tam: tuple[int, int], rects, aneis=(), caminho=()) -> Image.Image:
	"""255 = buraco (UI pintada), 0 = arte a preservar."""
	# os aneis primeiro, NUM MAPA A PARTE: a coroa e' feita a apagar o
	# interior do circulo, e se fosse desenhada por cima dos retangulos
	# devolvia ao fundo as fichas que eles ja' tinham tapado (visto na 1.a
	# corrida: os rotulos "1-4" e "1-5" sobreviviam no fundo).
	coroas = Image.new("L", tam, 0)
	dc = ImageDraw.Draw(coroas)
	for cx, cy, re_, ri in aneis:
		dc.ellipse((cx - re_, cy - re_, cx + re_, cy + re_), fill=255)
		dc.ellipse((cx - ri, cy - ri, cx + ri, cy + ri), fill=0)
	m = coroas
	d = ImageDraw.Draw(m)
	if caminho:
		d.line(list(caminho), fill=255, width=CAMINHO_ESPESSURA, joint="curve")
	for r in rects:
		d.rectangle(r, fill=255)
	return m


def inpaint(img: Image.Image, buraco: Image.Image) -> Image.Image:
	"""Preenche `buraco` por difusao multi-escala.

	A cada passo o borrao espalha cor de fora para dentro e os pixeis
	conhecidos sao REPOSTOS do original -- so' o buraco evolui. Comeca com
	raio grande (enche depressa, sem estrutura) e acaba fino (suaviza a
	junta). Nao inventa desenho: o que la' fica e' a media suavizada da
	vizinhanca real.
	"""
	conhecido = ImageChops.invert(buraco)
	# semente: media da arte conhecida, para o buraco nao partir do preto
	estat = img.copy()
	estat.paste((0, 0, 0), (0, 0) + img.size, buraco)
	n = sum(conhecido.point(lambda v: 1 if v > 127 else 0).getdata())
	soma = [sum(c.getdata()) for c in estat.split()[:3]]
	media = tuple(int(s / max(n, 1)) for s in soma)
	saida = img.copy()
	saida.paste(media, (0, 0) + img.size, buraco)
	for raio in (128, 96, 72, 54, 40, 30, 22, 16, 12, 9, 7, 5, 4, 3, 2, 1.5, 1):
		for _ in range(2):
			borrado = saida.filter(ImageFilter.GaussianBlur(raio))
			saida = Image.composite(img, borrado, conhecido)
	return saida


def camada_diferenca(prancha: Image.Image, limpo: Image.Image, ganho: float) -> Image.Image:
	"""RGBA com a UI pintada recortada do fundo.

	O alfa e' a forca da diferenca por pixel (maximo dos tres canais),
	multiplicada por `ganho`; a cor e' a da prancha. Serve tanto para a UI
	que ACRESCENTA luz (glow vermelho) como para a que ESCURECE (interior
	da placa), porque a diferenca e' tomada em valor absoluto.
	"""
	dif = ImageChops.difference(prancha, limpo).convert("RGB")
	r, g, b = dif.split()
	forca = ImageChops.lighter(ImageChops.lighter(r, g), b)
	alfa = forca.point(lambda v: min(255, int(v * ganho)))
	fora = prancha.convert("RGBA")
	fora.putalpha(alfa)
	return fora


def apagar_texto_v(peca: Image.Image, zonas, ox: int, oy: int) -> None:
	"""Como `apagar_texto`, mas na vertical: cada COLUNA passa a ser a
	interpolacao entre as linhas logo fora da zona. E' o que serve as pecas
	cujo rotulo ocupa quase toda a largura (as abas das regioes)."""
	px = peca.load()
	for (x0, y0, x1, y1) in zonas:
		x0, y0, x1, y1 = x0 - ox, y0 - oy, x1 - ox, y1 - oy
		cima, baixo = max(y0 - 2, 0), min(y1 + 2, peca.height - 1)
		if cima >= baixo:
			continue
		alt = baixo - cima
		for x in range(max(x0, 0), min(x1, peca.width)):
			a, b = px[x, cima], px[x, baixo]
			for y in range(max(y0, 0), min(y1, peca.height)):
				t = (y - cima) / alt
				px[x, y] = tuple(int(a[c] + (b[c] - a[c]) * t) for c in range(4))


def apagar_texto(peca: Image.Image, zonas, ox: int, oy: int) -> None:
	"""Apaga rotulos pintados dentro de uma peca ja' recortada.

	Cada linha da zona passa a ser a interpolacao linear entre as colunas
	imediatamente fora dela (o mesmo metodo da 9F): preserva o gradiente
	horizontal da placa e nao inventa desenho. Feito nos 4 canais, alfa
	incluido -- senao ficava o recorte do texto em silhueta.
	"""
	px = peca.load()
	for (x0, y0, x1, y1) in zonas:
		x0, y0, x1, y1 = x0 - ox, y0 - oy, x1 - ox, y1 - oy
		esq, dir_ = max(x0 - 2, 0), min(x1 + 2, peca.width - 1)
		if esq >= dir_:
			continue
		for y in range(max(y0, 0), min(y1, peca.height)):
			a, b = px[esq, y], px[dir_, y]
			larg = dir_ - esq
			for x in range(max(x0, 0), min(x1, peca.width)):
				t = (x - esq) / larg
				px[x, y] = tuple(int(a[c] + (b[c] - a[c]) * t) for c in range(4))


def esvaziar(peca: Image.Image, zonas, ox: int, oy: int) -> None:
	"""Zonas totalmente transparentes (conteudo da maquete)."""
	d = ImageDraw.Draw(peca)
	for (x0, y0, x1, y1) in zonas:
		d.rectangle((x0 - ox, y0 - oy, x1 - ox, y1 - oy), fill=(0, 0, 0, 0))


def vazar_miolo(peca: Image.Image, bordadura: int) -> None:
	"""So' a moldura: o interior alem de `bordadura` px fica transparente,
	com uma pequena rampa para a junta nao marcar."""
	mask = Image.new("L", peca.size, 255)
	d = ImageDraw.Draw(mask)
	d.rectangle((bordadura, bordadura, peca.width - 1 - bordadura,
		peca.height - 1 - bordadura), fill=0)
	mask = mask.filter(ImageFilter.GaussianBlur(3))
	peca.putalpha(ImageChops.multiply(peca.split()[3], mask))


def ampliar(img: Image.Image, escala: int = ESCALA) -> Image.Image:
	return img.resize((img.width * escala, img.height * escala), Image.LANCZOS)


def recorte_circular(camada: Image.Image, cx: int, cy: int, raio: int,
		apagar=()) -> Image.Image:
	caixa = (cx - raio, cy - raio, cx + raio, cy + raio)
	peca = camada.crop(caixa)
	if apagar:
		esvaziar(peca, apagar, caixa[0], caixa[1])
	mask = Image.new("L", peca.size, 0)
	ImageDraw.Draw(mask).ellipse((0, 0, peca.width - 1, peca.height - 1), fill=255)
	mask = mask.filter(ImageFilter.GaussianBlur(2))
	peca.putalpha(ImageChops.multiply(peca.split()[3], mask))
	return peca


def escrever_import(destino: Path, filtro_linear: bool) -> None:
	"""`.import` do Godot. O kit e' pintura ampliada: filtro LINEAR."""
	uid = "uid://" + hashlib.sha1(str(destino).encode()).hexdigest()[:13]
	rel = destino.relative_to(RAIZ).as_posix()
	md5 = hashlib.md5(rel.encode()).hexdigest()
	filtro = 1 if filtro_linear else 0
	destino.with_suffix(destino.suffix + ".import").write_text(
		"[remap]\n\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n"
		f"uid=\"{uid}\"\npath=\"res://.godot/imported/{destino.name}-{md5}.ctex\"\n"
		f"metadata={{\n\"vram_texture\": false\n}}\n\n[deps]\n\n"
		f"source_file=\"res://{rel}\"\ndest_files=[\"res://.godot/imported/{destino.name}-{md5}.ctex\"]\n\n"
		"[params]\n\ncompress/mode=0\ncompress/high_quality=false\n"
		"compress/lossy_quality=0.7\ncompress/hdr_compression=1\n"
		"compress/normal_map=0\ncompress/channel_pack=0\nmipmaps/generate=false\n"
		"mipmaps/limit=-1\nroughness/mode=0\nroughness/src_normal=\"\"\n"
		"process/fix_alpha_border=true\nprocess/premult_alpha=false\n"
		"process/normal_map_invert_y=false\nprocess/hdr_as_srgb=false\n"
		"process/hdr_clamp_exposure=false\nprocess/size_limit=0\n"
		f"detect_3d/compress_to=0\nsvg/scale=1.0\neditor/scale_with_editor_scale=false\n"
		f"editor/convert_colors_with_editor_theme=false\nroughness/src_normal=\"\"\n"
		f"compress/normal_map=0\nprocess/channel_remap/red=0\n"
		f"; filtro: {'linear' if filtro_linear else 'nearest'}\n", encoding="utf-8")


def guardar(img: Image.Image, destino: Path, registos: dict, linear: bool = True) -> None:
	destino.parent.mkdir(parents=True, exist_ok=True)
	img.save(destino)
	escrever_import(destino, linear)
	registos[destino.relative_to(RAIZ).as_posix()] = {
		"sha256": sha(destino), "tamanho": list(img.size), "modo": img.mode}


# --------------------------------------------------------------------------
# icone / logo
# --------------------------------------------------------------------------
TAMANHOS_ICONE = [16, 24, 32, 48, 64, 128, 180, 192, 256, 384, 512, 1024]


def produzir_icone(registos: dict) -> None:
	fonte = Image.open(PRANCHAS["icone"][0]).convert("RGB")
	lado = min(fonte.size)
	fonte = fonte.crop(((fonte.width - lado) // 2, (fonte.height - lado) // 2,
		(fonte.width + lado) // 2, (fonte.height + lado) // 2))
	# a prancha ja' vem com cantos arredondados pintados sobre preto: a
	# mascara de canto so' os torna transparentes (raio medido = 13,5 % do lado)
	base = fonte.convert("RGBA")
	raio = int(lado * 0.135)
	mask = Image.new("L", (lado, lado), 0)
	ImageDraw.Draw(mask).rounded_rectangle((0, 0, lado - 1, lado - 1), radius=raio, fill=255)
	base.putalpha(mask)

	guardar(base.resize((1024, 1024), Image.LANCZOS), SAIDA_ICONE / "icone_9h_1024.png", registos)
	for t in TAMANHOS_ICONE:
		img = base.resize((t, t), Image.LANCZOS)
		guardar(img, SAIDA_ICONE / f"icone_9h_{t}.png", registos)

	# .ico do Windows (PNG embutido por tamanho, como o formato permite)
	ico = SAIDA_ICONE / "koliani.ico"
	base.resize((256, 256), Image.LANCZOS).save(
		ico, format="ICO", sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64),
			(128, 128), (256, 256)])
	registos[ico.relative_to(RAIZ).as_posix()] = {"sha256": sha(ico), "tamanho": [256, 256], "modo": "ICO"}

	# icone do projeto (substitui o icon.svg no `config/icon`)
	guardar(base.resize((512, 512), Image.LANCZOS), RAIZ / "icon.png", registos)


# --------------------------------------------------------------------------
# principal
# --------------------------------------------------------------------------
def produzir() -> dict:
	registos: dict = {}
	SAIDA.mkdir(parents=True, exist_ok=True)

	limpos: dict[str, Image.Image] = {}
	camadas: dict[str, Image.Image] = {}

	for nome, rects, aneis, caminho in (
			("menu", LIMPAR_MENU, (), ()),
			("seletor", LIMPAR_SELETOR, ANEIS_SELETOR, CAMINHO_SELETOR)):
		caminho_prancha, esperado = PRANCHAS[nome]
		if sha(caminho_prancha) != esperado:
			raise SystemExit(f"SHA da prancha {nome} nao bate -- autoridade trocada")
		prancha = Image.open(caminho_prancha).convert("RGB")
		print(f"  {nome}: inpaint de {len(rects)} zonas...", flush=True)
		buraco = mascara_buraco(prancha.size, rects, aneis, caminho)
		# a junta fica menos visivel se a mascara for ligeiramente dilatada
		buraco = buraco.filter(ImageFilter.MaxFilter(5))
		limpo = inpaint(prancha, buraco)
		limpos[nome] = limpo
		camadas[nome] = camada_diferenca(prancha, limpo, 1.0)
		fundo = limpo.resize((LARGURA_ECRA, ALTURA_ECRA), Image.LANCZOS)
		guardar(fundo, SAIDA / f"fundo_{nome}.png", registos)

	print("  pecas...", flush=True)
	pranchas_rgb = {n: Image.open(c).convert("RGB") for n, (c, _s) in PRANCHAS.items()
		if n in limpos}
	for nome, (prancha_nome, caixa, _margens, ganho, extras) in PECAS.items():
		camada = camada_diferenca(pranchas_rgb[prancha_nome], limpos[prancha_nome], ganho)
		peca = camada.crop(caixa)
		if extras.get("texto"):
			apagar_texto(peca, extras["texto"], caixa[0], caixa[1])
		if extras.get("texto_v"):
			apagar_texto_v(peca, extras["texto_v"], caixa[0], caixa[1])
		if extras.get("apagar"):
			esvaziar(peca, extras["apagar"], caixa[0], caixa[1])
		if extras.get("oco"):
			vazar_miolo(peca, extras["oco"])
		guardar(ampliar(peca), SAIDA / f"{nome}.png", registos)

	camada_sel = camada_diferenca(pranchas_rgb["seletor"], limpos["seletor"], 3.0)
	for nome, (cx, cy, raio, apagar) in ANEIS_PECA.items():
		guardar(ampliar(recorte_circular(camada_sel, cx, cy, raio, apagar)),
			SAIDA / f"{nome}.png", registos)

	print("  icone...", flush=True)
	produzir_icone(registos)

	# margens das nine-patch, para o GDScript nao as repetir
	margens = {n: p[2] for n, p in PECAS.items() if p[2]}
	MANIFESTO.write_text(json.dumps({
		"execucao": "9H",
		"autoridade": {n: {"ficheiro": str(c.relative_to(RAIZ).as_posix()), "sha256": s}
			for n, (c, s) in PRANCHAS.items()},
		"margens_nine_patch": margens,
		"ficheiros": registos,
	}, indent=2, ensure_ascii=False), encoding="utf-8")
	return registos


def validar() -> int:
	if not MANIFESTO.exists():
		print("FALHA: manifesto nao existe")
		return 1
	dados = json.loads(MANIFESTO.read_text(encoding="utf-8"))
	mau = 0
	for nome, (caminho, esperado) in PRANCHAS.items():
		if sha(caminho) != esperado:
			print(f"FALHA autoridade {nome}: SHA mudou")
			mau += 1
	for rel, info in dados["ficheiros"].items():
		f = RAIZ / rel
		if not f.exists():
			print(f"FALHA: falta {rel}")
			mau += 1
		elif sha(f) != info["sha256"]:
			print(f"FALHA: {rel} mudou fora da ferramenta")
			mau += 1
	print(f"{len(dados['ficheiros'])} ficheiros; {mau} falhas")
	return 1 if mau else 0


def folha(destino: Path) -> None:
	dados = json.loads(MANIFESTO.read_text(encoding="utf-8"))
	nomes = [r for r in dados["ficheiros"] if r.startswith("assets/ui/frontend_9h/")]
	cel, cols = 240, 5
	linhas = (len(nomes) + cols - 1) // cols
	folha_img = Image.new("RGB", (cel * cols, (cel + 18) * linhas), (18, 12, 22))
	d = ImageDraw.Draw(folha_img)
	for i, rel in enumerate(nomes):
		im = Image.open(RAIZ / rel).convert("RGBA")
		im.thumbnail((cel - 12, cel - 12), Image.LANCZOS)
		x, y = (i % cols) * cel, (i // cols) * (cel + 18)
		xadrez = Image.new("RGB", im.size, (40, 30, 46))
		xadrez.paste(im, (0, 0), im)
		folha_img.paste(xadrez, (x + 6, y + 6))
		d.text((x + 6, y + cel + 2), Path(rel).stem, fill=(210, 200, 220))
	destino.parent.mkdir(parents=True, exist_ok=True)
	folha_img.save(destino)
	print("folha:", destino)


def main(argv: list[str]) -> int:
	if "--validar" in argv:
		return validar()
	if "--folha" in argv:
		folha(Path(argv[argv.index("--folha") + 1]))
		return 0
	print("Execution 9H -- frontend de producao")
	registos = produzir()
	print(f"OK: {len(registos)} ficheiros -> {SAIDA} + {SAIDA_ICONE}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main(sys.argv[1:]))
