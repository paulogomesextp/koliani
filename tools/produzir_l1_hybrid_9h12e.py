"""9H.12E — produz o kit visual do L1 a partir da autoridade APROVADA.

Reparação da 12E (o primeiro passe colava RECORTES RECTANGULARES):

* o alfa deixa de ser só o "carvão ligado à borda". As peças que vêm de
  painéis PINTADOS (floresta, cascata, torres, arcos) não têm fundo carvão
  nenhum -- tinham céu pintado, e por isso saíam rectângulos inteiros. Agora
  cada coluna procura onde a pintura se afasta do CÉU dessa coluna
  (`silhueta_topo`) e as margens dissolvem-se com um degradê ondulado
  (`esbater_lados` / `esbater_baixo`). Nenhuma aresta recta sobra.
* a franja preta no alfa (serrilha do flood-fill) morre no `limpar_alfa`:
  mediana no canal alfa + desfoque de 0,7 px.
* não se gravam mais canvases de 1920x950 com 60% de vazio. Só a camada 01
  (que é uma pintura inteira) é uma imagem; o resto são ELEMENTOS soltos que
  o `l1_hybrid_9h12e.gd` espalha pelo nível -- é isso que tira a repetição
  de landmark, porque cada peça é colocada uma vez onde faz sentido.
* a camada 01 deixa de ser repetida 9x com flip_h. Com o fator de parallax
  0,12 e 6400 px de nível, a camada só percorre 6400*0,12 = 768 px: uma
  imagem de ~2000 px cobre o nível inteiro. Uma lua, um castelo.
* terreno: o `corpo` era um upscale desfocado. Passa a ser um RECORTE NATIVO
  1:1 das colunas de rocha da prancha (nítido), costurado para repetir, e
  arrefecido -- o musgo amarelo-lima desce em verde e sobe em azul.

Correr: python tools/produzir_l1_hybrid_9h12e.py
"""
from pathlib import Path
from collections import deque
import hashlib
import json
import math
from PIL import Image, ImageChops, ImageFilter

RAIZ = Path(__file__).resolve().parents[1]
KIT = RAIZ / 'assets/art/regions/region_01_forest/production/l1_hybrid_9h12e'
WORK = RAIZ / 'work/production_art_gate/9H12E_astra_production'
AUTORIDADE = RAIZ / 'work/production_art_gate/9H12D_astra_approved/region1_l1_hybrid_visual_authority_v1.png'
SHA_APROVADO = '8ca9a4f4e548024688e19945c0560c23c5411b5f92d376de2547687225b7c2df'

sha = hashlib.sha256(AUTORIDADE.read_bytes()).hexdigest()
assert sha == SHA_APROVADO, 'autoridade aprovada mudou: %s' % sha
IM = Image.open(AUTORIDADE).convert('RGBA')
assert IM.size == (1536, 1024), IM.size
registos = []


# ---------------------------------------------------------------- alfa ----
def matte_carvao(p, tol=20):
	"""Tira o carvão do FUNDO (só o que toca na borda). Painéis de props."""
	w, h = p.size
	px = p.load()
	vistos = bytearray(w * h)
	fila = deque([(x, 0) for x in range(w)] + [(x, h - 1) for x in range(w)] +
	             [(0, y) for y in range(h)] + [(w - 1, y) for y in range(h)])
	while fila:
		x, y = fila.popleft()
		if x < 0 or y < 0 or x >= w or y >= h or vistos[y * w + x]:
			continue
		vistos[y * w + x] = 1
		r, g, b, a = px[x, y]
		if max(abs(r - 26), abs(g - 29), abs(b - 36)) > tol:
			continue
		px[x, y] = (r, g, b, 0)
		fila.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
	return p


def silhueta_topo(p, tol=26, margem=3):
	"""Painéis PINTADOS: apaga o céu por cima da silhueta, coluna a coluna.

	O céu de cada coluna é a média das primeiras linhas dessa coluna; desce-se
	até a pintura se afastar dele. Dá copas de árvore e cumes recortados em vez
	do rectângulo que o primeiro passe gravava.
	"""
	w, h = p.size
	px = p.load()
	limite = []
	for x in range(w):
		cr = cg = cb = 0
		for y in range(margem):
			r, g, b, _ = px[x, y]
			cr += r; cg += g; cb += b
		cr //= margem; cg //= margem; cb //= margem
		corte = h
		for y in range(h):
			r, g, b, _ = px[x, y]
			if abs(r - cr) + abs(g - cg) + abs(b - cb) > tol * 3:
				corte = y
				break
		limite.append(corte)
	# suaviza o perfil para não ficar aos dentes
	suave = []
	for x in range(w):
		j0 = max(0, x - 6); j1 = min(w, x + 7)
		suave.append(sum(limite[j0:j1]) / (j1 - j0))
	alfa = p.getchannel('A').load()
	for x in range(w):
		c = suave[x]
		for y in range(h):
			if y < c - 2:
				px[x, y] = px[x, y][:3] + (0,)
			elif y < c + 2:
				f = (y - (c - 2)) / 4.0
				px[x, y] = px[x, y][:3] + (int(alfa[x, y] * f),)
	return p


def _onda(i, n, amp=0.16, fase=0.0):
	t = i / max(1.0, n - 1.0)
	return 1.0 + amp * math.sin(t * 9.0 + fase) + amp * 0.6 * math.sin(t * 23.0 + fase * 2.1)


def esbater_lados(p, frac=0.28):
	"""Dissolve as margens esquerda/direita com um degradê ONDULADO."""
	w, h = p.size
	px = p.load()
	n = max(1, int(w * frac))
	for y in range(h):
		k = _onda(y, h, 0.22, 1.7)
		largura = max(1, int(n * k))
		for x in range(largura):
			f = x / largura
			r, g, b, a = px[x, y]
			px[x, y] = (r, g, b, int(a * f * f))
		k2 = _onda(y, h, 0.22, 4.4)
		largura2 = max(1, int(n * k2))
		for i in range(largura2):
			x = w - 1 - i
			f = i / largura2
			r, g, b, a = px[x, y]
			px[x, y] = (r, g, b, int(a * f * f))
	return p


def esbater_baixo(p, frac=0.22):
	w, h = p.size
	px = p.load()
	n = max(1, int(h * frac))
	for i in range(n):
		y = h - 1 - i
		f = i / n
		for x in range(w):
			r, g, b, a = px[x, y]
			px[x, y] = (r, g, b, int(a * f))
	return p


def limpar_alfa(p, mediana=3, desfoque=0.7):
	"""Mata a serrilha/franja preta: mediana no alfa e um fio de desfoque."""
	r, g, b, a = p.split()
	a = a.filter(ImageFilter.MedianFilter(mediana))
	a = a.filter(ImageFilter.GaussianBlur(desfoque))
	return Image.merge('RGBA', (r, g, b, a))


def arrefecer(p, verde=0.88, azul=1.02, vermelho=0.92, valor=0.62):
	"""Tira o musgo amarelo-lima e BAIXA O VALOR da rocha.

	Cuidado medido no 1º ensaio da 12E: cortar muito o verde e empurrar muito
	o azul num musgo amarelo dá MAGENTA -- as plataformas saíram cor-de-rosa.
	O corte do verde é suave e quem faz o trabalho é o `valor`: a rocha tem de
	ficar mais escura que o fundo, senão o cenário ganha ao plano de jogo.
	"""
	r, g, b, a = p.split()
	r = r.point(lambda v: min(255, int(v * vermelho * valor)))
	g = g.point(lambda v: min(255, int(v * verde * valor)))
	b = b.point(lambda v: min(255, int(v * azul * valor + 4)))
	return Image.merge('RGBA', (r, g, b, a))


def costurar_x(p, frac=0.22):
	"""Faz a peça repetir na horizontal sem linha (cross-fade das arestas)."""
	w, h = p.size
	n = max(1, int(w * frac))
	base = p.copy()
	px = base.load()
	fonte = p.load()
	for i in range(n):
		f = i / n
		for y in range(h):
			a = fonte[i, y]
			b = fonte[w - n + i, y]
			mist = tuple(int(b[c] * (1 - f) + a[c] * f) for c in range(4))
			px[i, y] = mist
	return base.crop((0, 0, w - n, h))


def costurar_y(p, frac=0.22):
	w, h = p.size
	n = max(1, int(h * frac))
	base = p.copy()
	px = base.load()
	fonte = p.load()
	for j in range(n):
		f = j / n
		for x in range(w):
			a = fonte[x, j]
			b = fonte[x, h - n + j]
			px[x, j] = tuple(int(b[c] * (1 - f) + a[c] * f) for c in range(4))
	return base.crop((0, 0, w, h - n))


def guardar(p, pasta, nome, caixa=None):
	for base in (KIT, WORK):
		(base / pasta).mkdir(parents=True, exist_ok=True)
		p.save(base / pasta / (nome + '.png'))
	registos.append(dict(ficheiro='%s/%s.png' % (pasta, nome), tamanho=list(p.size), recorte=caixa))
	return p


# ------------------------------------------------------- camada 01 ---------
# Panorama aprovado (painel superior direito da prancha). UMA instância: com
# parallax 0,12 num nível de 6400 px a camada só percorre 768 px.
CAIXA_PAN = (780, 5, 1528, 375)
pan = IM.crop(CAIXA_PAN)
guardar(pan, 'source_clean', 'panorama', list(CAIXA_PAN))

# Alarga as laterais com uma faixa NEUTRA -- floresta e serra, a coluna
# 200..340 do panorama, que NÃO tem lua, castelo nem a árvore-marco. Espelhar
# a margem (1º ensaio) duplicava o castelo à direita e dava uma simetria
# evidente à esquerda: é exactamente a repetição de landmark que a 12E vem
# matar. A faixa vai escurecida e desfocada, a ler como orla fora de foco.
mw, mh = pan.size
ala = 150
neutro = pan.crop((200, 0, 340, mh))
neutro = neutro.filter(ImageFilter.GaussianBlur(1.6))
esq = Image.new('RGBA', (ala, mh))
dir_ = Image.new('RGBA', (ala, mh))
for i in range(0, ala, neutro.size[0]):
	esq.paste(neutro.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (i, 0))
	dir_.paste(neutro, (i, 0))
largo = Image.new('RGBA', (mw + ala * 2, mh))
largo.paste(esq, (0, 0)); largo.paste(pan, (ala, 0)); largo.paste(dir_, (ala + mw, 0))
# As asas escurecem por DEGRADÊ a partir da costura (1,0 na emenda -> 0,5 na
# ponta). Escurecê-las por igual deixava um degrau de valor visível, que é
# outra vez uma aresta recta no cenário.
lpx = largo.load()
for i in range(ala):
	fe = 0.50 + 0.50 * (i / ala)          # asa esquerda: escura fora, clara na costura
	fd = 1.00 - 0.50 * (i / ala)          # asa direita: clara na costura, escura fora
	for y in range(mh):
		for x, f in ((i, fe), (ala + mw + i, fd)):
			r, g, b, a = lpx[x, y]
			lpx[x, y] = (int(r * f), int(g * (f + 0.02)), int(b * min(1.0, f + 0.10)), a)
# Sobre cada costura assenta uma COLUNA DE BRUMA. Duas pinturas diferentes
# encostadas deixam sempre uma linha vertical, por mais igualado que esteja o
# valor; a bruma é o que a paisagem já tem em todo o lado e dissolve a emenda
# sem inventar linguagem nova.
for costura in (ala, ala + mw):
	for i in range(-110, 110):
		x = costura + i
		if x < 0 or x >= largo.size[0]:
			continue
		f = math.exp(-(i / 52.0) ** 2) * 0.62
		for y in range(mh):
			r, g, b, a = lpx[x, y]
			vy = 0.55 + 0.45 * (y / mh)      # mais densa em baixo, como o vale
			g2 = f * vy
			lpx[x, y] = (int(r * (1 - g2) + 150 * g2), int(g * (1 - g2) + 158 * g2),
			             int(b * (1 - g2) + 186 * g2), a)
camada01 = largo.resize((2048, int(mh * 2048 / largo.size[0])), Image.Resampling.LANCZOS)
guardar(camada01, 'layers', '01_far_sky_castle')

# ------------------------------------------------------- elementos ---------
# Peças de painel PINTADO -> silhueta por coluna + margens dissolvidas.
PINTADOS = {
	'arvore':       (8, 390, 273, 570),
	'floresta':     (275, 390, 575, 570),
	'arco':         (578, 389, 712, 569),
	'arco_partido': (710, 389, 916, 569),
	'cascata':      (900, 389, 1200, 570),
	'torres':       (1205, 389, 1528, 570),
}
for nome, caixa in PINTADOS.items():
	p = IM.crop(caixa)
	p = silhueta_topo(p, tol=24 if nome in ('floresta', 'arvore') else 30)
	p = esbater_lados(p, 0.30 if nome in ('floresta', 'cascata', 'torres') else 0.18)
	p = esbater_baixo(p, 0.26 if nome in ('floresta', 'cascata', 'torres') else 0.12)
	guardar(limpar_alfa(p), 'elementos', nome, list(caixa))

# Peças sobre carvão -> flood-fill (já dava bom recorte) + limpeza da franja.
CARVAO = {
	'vinhas':   (9, 584, 98, 710),
	'raizes':   (104, 584, 278, 710),
	'lanterna': (399, 584, 448, 710),
	'cristais': (723, 584, 937, 710),
	'ramos':    (1130, 584, 1527, 710),
	'ramo_curvo': (960, 584, 1125, 700),
}
for nome, caixa in CARVAO.items():
	p = matte_carvao(IM.crop(caixa))
	guardar(limpar_alfa(p, 3, 0.6), 'elementos', nome, list(caixa))

# ------------------------------------------------------- terreno HD --------
# Recortes NATIVOS 1:1 das colunas de rocha da prancha (linha 4). Sem upscale:
# o `corpo` desfocado era um Lanczos de fonte pequena.
CORPO = (486, 846, 646, 1006)
corpo = IM.crop(CORPO).convert('RGBA')
corpo = arrefecer(corpo, valor=0.80)
corpo = costurar_y(costurar_x(corpo, 0.20), 0.20)
guardar(corpo, 'terrain_hd', 'corpo', list(CORPO))

# Capa: o lábio musgoso da plataforma flutuante (linha 4, 1ª peça). O recorte
# começa ACIMA do lábio (y 703, o lábio está a 714) e traz o carvão do fundo,
# que vira alfa -- é o que dá SILHUETA à plataforma. Sem isto o bloco é um
# rectângulo, que foi o que o review viu ("tiras de fotografia coladas").
# A altura é escolhida para o lábio cair nos 8 px de `SUPERFICIE` quando o
# `plataforma.gd` desenha a capa a 56 px: 11 px de 74 -> 8,3 px de 56.
TOPO = (24, 703, 300, 777)
topo = IM.crop(TOPO).convert('RGBA')
# NÃO se usa aqui o flood-fill do carvão: o miolo da plataforma é quase tão
# escuro como o fundo da prancha e o preenchimento comia o corpo todo,
# deixando só um fio de musgo a flutuar (medido no 2º ensaio da 12E). O céu
# por cima do lábio tira-se pelo perfil de corte, em baixo.
topo = arrefecer(topo, valor=0.92)
# o lábio da prancha é uma linha a régua; morde-se com ruído para a silhueta
# não voltar a ler-se como aresta de tile.
tw, th = topo.size
tp = topo.load()
for x in range(tw):
	corte = 11 + int(3.0 * math.sin(x / 9.0) + 2.0 * math.sin(x / 3.3 + 1.2))
	for y in range(th):
		if y < corte - 1:
			tp[x, y] = tp[x, y][:3] + (0,)
		elif y < corte + 1:
			tp[x, y] = tp[x, y][:3] + (int(tp[x, y][3] * 0.5),)
topo = limpar_alfa(topo, 3, 0.5)
topo = costurar_x(topo, 0.22)
# fio de luar no lábio: as 5 primeiras linhas sobem de valor
tpx = topo.load()
for y in range(min(6, topo.size[1])):
	f = 1.0 + (0.55 * (1.0 - y / 6.0))
	for x in range(topo.size[0]):
		r, g, b, a = tpx[x, y]
		tpx[x, y] = (min(255, int(r * f)), min(255, int(g * f)), min(255, int(b * f * 1.06)), a)
guardar(topo, 'terrain_hd', 'topo', list(TOPO))

# corte lateral e franja de baixo, da mesma rocha (coerência de material)
LADO = (660, 850, 700, 1014)
lado = arrefecer(IM.crop(LADO).convert('RGBA'), valor=0.72)
guardar(costurar_y(lado, 0.22), 'terrain_hd', 'lado', list(LADO))

BASE = (300, 940, 560, 1010)
base = arrefecer(IM.crop(BASE).convert('RGBA'), valor=0.62)
base = costurar_x(base, 0.22)
guardar(esbater_baixo(base, 0.35), 'terrain_hd', 'base', list(BASE))

# poça de corrupção (linha 4, painel magenta) -> superfície do pântano
POCA = (1052, 726, 1300, 1016)
poca = IM.crop(POCA).convert('RGBA')
guardar(costurar_x(poca, 0.20), 'terrain_hd', 'corrupcao', list(POCA))

# eixo de luz volumétrica (linha 4, último painel) -> VFX de profundidade
EIXO = (1310, 726, 1528, 1016)
eixo = IM.crop(EIXO).convert('RGBA')
epx = eixo.load()
for y in range(eixo.size[1]):
	for x in range(eixo.size[0]):
		r, g, b, _ = epx[x, y]
		epx[x, y] = (r, g, b, min(255, int((r + g + b) / 3 * 1.15)))
guardar(esbater_lados(eixo, 0.30), 'elementos', 'eixo_luz', list(EIXO))

# ------------------------------------------------------- verificação -------
folha = Image.new('RGBA', (1200, 900), (22, 24, 32, 255))
x = y = 8; linha = 0
folha.paste(camada01.resize((1180, int(camada01.size[1] * 1180 / camada01.size[0]))), (8, 8), camada01.resize((1180, int(camada01.size[1] * 1180 / camada01.size[0]))))
y = 8 + int(camada01.size[1] * 1180 / camada01.size[0]) + 8
for nome in list(PINTADOS) + list(CARVAO) + ['eixo_luz']:
	p = Image.open(KIT / 'elementos' / (nome + '.png'))
	p.thumbnail((170, 150))
	if x + p.size[0] > 1190:
		x = 8; y += 160
	folha.paste(p, (x, y), p)
	x += p.size[0] + 8
y += 165; x = 8
for nome in ('corpo', 'topo', 'lado', 'base', 'corrupcao'):
	p = Image.open(KIT / 'terrain_hd' / (nome + '.png'))
	p.thumbnail((180, 160))
	folha.paste(p, (x, y), p)
	x += p.size[0] + 8
guardar(folha, 'preview', 'verificacao_12e')

man = dict(
	execucao='9H.12E L1 (reparação de produção)',
	autoridade=str(AUTORIDADE.relative_to(RAIZ)).replace('\\', '/'),
	sha256=sha,
	fonte_px=list(IM.size),
	direitos='Derivado da autoridade aprovada pelo Game Master na 9H.12D. Sem assets externos.',
	metodo='silhueta por coluna + margens dissolvidas + limpeza de alfa; terreno em recorte NATIVO 1:1 costurado; camada 01 única (sem repetição de landmark).',
	ativos=registos,
)
for base_dir in (KIT / 'manifests', WORK / 'manifests'):
	base_dir.mkdir(parents=True, exist_ok=True)
	with open(base_dir / 'manifest.json', 'w', encoding='utf-8', newline='\n') as f:
		json.dump(man, f, ensure_ascii=False, indent=1)
print('9H.12E: %d ativos gravados' % len(registos))
