extends RefCounted
## Execution 9C — kit de ambiente da Região I (Floresta Corrompida).
##
## As peças saem de `tools/produzir_kit_regiao1_9c.py`: recortes sem perdas
## das pranchas aprovadas 08 (autoridade da região) e 10 (tileset estrutural,
## graduado para a noite da 08). Aqui só se MONTA: nenhuma forma é desenhada
## por código.
##
## Quem liga o kit é o nó `Region1HybridVisualTarget` de cada nível da Região
## I, que entra no grupo `GRUPO`. Sem esse nó (os outros 95 níveis, que também
## usam o bioma "floresta") nada muda.

const DIR := "res://assets/art/regions/region_01_forest/production/kit_9c"
const GRUPO := "regiao1_kit"

## Variantes de cenário da prancha 08 ("Entrada da Floresta" nos níveis 1-2,
## "Ruínas Antigas" no 3, "Cascatas e Abismos" no 4, "Heart Tree Próximo" no
## 5). A identidade é a mesma; muda a mistura.
const Remaster := preload("res://scripts/regiao1_remaster.gd")

## Execution 9H.11. O QA viu o L2 melhor vestido do que o 1, o 3 e o 5, e o
## L5 a ler-se como "o L1 com outro tom". Duas alavancas, sem arte nova:
##   * `densidade` -- quantos props cabem num metro de plataforma. O L2 é a
##     referência (1.0); 1 e 3 estavam a meia dose, o 5 sobe a 1.45.
##   * o L5 é o CLÍMAX: `corrupcao` 1.0 -> 1.8 (o cristal domina o sorteio) e
##     `lanternas` 0.2 -> 0.12 (a luz quente da entrada já não chega aqui).
## O L1 e o L3 sobem em lanternas em vez de corrupção: é o mesmo bosque, mais
## habitado, não mais podre.

## Tinta do panorama por mood: razão média-da-variante / média-do-panorama,
## medida na 08 pelo produtor (`kit_9c_manifest.json`, `tintas_por_mood_08`),
## aplicada a 35%. As tiras de mood são mais claras e quentes do que o
## panorama; a 100% puxavam a noite para o crepúsculo.
##   entrada [1.18, 1.143, 0.85]  ruinas [1.18, 1.052, 0.85]
##   cascatas [1.158, 1.143, 1.039]  coracao [1.18, 0.85, 0.938]


static func tinta(perfil: Dictionary) -> Color:
	var canais: Array = perfil["tinta"]
	var t := Color(canais[0], canais[1], canais[2])
	return Color.WHITE.lerp(t, float(perfil["forca_tinta"]))

## Props de chão: [ficheiro, peso base, chave do perfil que o multiplica,
## escala mín, escala máx]. As rochas e raízes da prancha têm quase a altura
## da Koliani; a meia escala leem-se como detalhe e não como obstáculo.
const PROPS_CHAO := [
	["props/plantas.png", 1.0, "", 0.55, 0.75],
	["props/cogumelos.png", 0.8, "", 0.55, 0.7],
	["props/rocha.png", 0.6, "", 0.45, 0.6],
	["props/raizes.png", 0.7, "", 0.5, 0.65],
	["props/planta_luminosa.png", 0.5, "corrupcao", 0.55, 0.7],
	["props/lanterna.png", 1.0, "lanternas", 0.7, 0.8],
	["props/tocha.png", 0.6, "lanternas", 0.7, 0.8],
	["corrupcao/cristal_corrupcao_a.png", 1.2, "corrupcao", 0.8, 1.0],
	["corrupcao/cristal_corrupcao_b.png", 1.0, "corrupcao", 0.8, 1.0],
	["corrupcao/cristal_corrupcao_c.png", 1.0, "corrupcao", 0.8, 1.0],
	["corrupcao/cristal_corrupcao_d.png", 1.0, "corrupcao", 0.9, 1.1],
]
## O QUE PENDE POR BAIXO DE UM BLOCO. 9H.17 H -- eram SO' VINHAS, e o Game
## Master apanhou o resultado: "vegetacao a flutuar por baixo da plataforma e
## uma laje de rocha por cima", que nao faz sentido nenhum. Por baixo de um
## bloco o que se agarra e' ESTRUTURA -- raiz e rocha -- e a folhagem e'
## minoria, a cair da aresta. A vegetacao vive em cima (`PROPS_CHAO`).
const PROPS_PENDURA := ["props/raizes.png", "props/raizes.png", "props/vinha_a.png"]
const PROPS_PENDURA_GROSSA := ["props/raizes.png", "props/raizes.png",
	"props/rocha.png", "props/vinha_a.png", "props/vinha_b.png", "props/vinha_longa.png"]

const PASSO_DECO := 170.0
const MAX_DECO := 9

static var _cache := {}
static var _brilho: GradientTexture2D = null


static func tex(rel: String) -> Texture2D:
	if not _cache.has(rel):
		var cam := "%s/%s" % [DIR, rel]
		_cache[rel] = load(cam) if ResourceLoader.exists(cam) else null
	return _cache[rel]


## Execution 9H.7 -- as peças de FUNDO também vêm ampliadas no disco
## (`<nome>_hd_x3.png`, Lanczos + máscara de desfoque de
## `tools/nitidez_fundo_9h7.py`). O fundo desenhava-se com filtro bilinear a
## 2,5x-3,6x no pixel do ecrã, e ampliação bilinear é interpolação: era isso
## que o Game Master via desfocado. Quem monta divide a escala por `HD` e
## desenha ~1:1; a geometria no mundo fica igual (3 x e/3 = e).
const HD := 3

## A peça em HD, ou `null` se não houver (aí desenha-se a original como antes).
static func tex_hd(rel: String) -> Texture2D:
	var chave := "hd:" + rel
	if not _cache.has(chave):
		var cam := "%s/%s_hd_x%d.png" % [DIR, rel.trim_suffix(".png"), HD]
		_cache[chave] = load(cam) if ResourceLoader.exists(cam) else null
	return _cache[chave]


## O nó que ligou o kit neste nível, ou null (kit desligado).
static func alvo(no: Node) -> Node:
	if no == null or not no.is_inside_tree():
		return null
	return no.get_tree().get_first_node_in_group(GRUPO)


static func perfil_de(kit: Node) -> Dictionary:
	var n := 1
	if kit != null and "perfil" in kit:
		n = int(kit.perfil)
	return Remaster.perfil(clampi(n, 1, 5))


## Execution 9H.12D -- TERRENO HD. O corpo era `terreno_corpo.png` de 30x75
## repetido ~35 vezes por plataforma: a 30 px de período vê-se a grelha, não a
## rocha, e era isso que fazia o chão ler-se como mosaico pobre contra um
## fundo pintado. O kit HD (`tools/gerar_terreno_hd_regiao1.py`, das pranchas
## de 1254 px que estavam a ser reduzidas a 32 px) sobe o período para 384/512
## e traz antialiasing, como a direcção HYBRID CINEMATIC 2D pede.
##
## `ALTURA_*` são as alturas DESENHADAS de cada peça: a capa e a franja
## passaram a ter corpo em vez de serem tiras de 32/24 px. Nada disto toca em
## colisões -- quem as define é `tamanho` da plataforma.
const HD_CORPO := "terreno/terreno_corpo_hd.png"
const HD_TOPO := "terreno/terreno_topo_hd.png"
const HD_LADO := "terreno/terreno_lado_hd.png"
const HD_BASE := "terreno/terreno_base_hd.png"
const ALTURA_TOPO := 56.0
const ALTURA_BASE := 34.0
const LARGURA_LADO := 26.0


## A peça grande, ou a antiga se o kit HD ainda não foi produzido.
static func terreno(rel_hd: String, rel_legado: String) -> Texture2D:
	var t := tex(rel_hd)
	return t if t != null else tex(rel_legado)


## Capa: a variante com erva alta entra numa em cada três plataformas.
static func topo(rng: RandomNumberGenerator) -> Texture2D:
	var hd := tex(HD_TOPO)
	if hd != null:
		return hd
	if rng.randf() < 0.34:
		var t := tex("terreno/terreno_topo_erva.png")
		if t:
			return t
	return tex("terreno/terreno_topo.png")


## Espalha props de chão pela superfície. Mesma regra do legado: uma faixa por
## prop, semente da posição, nada no primeiro/último palmo da plataforma.
static func decorar(vis: Node, largura: float, y0: float, rng: RandomNumberGenerator,
		perfil: Dictionary) -> void:
	if largura < 110.0:
		return
	var dens := maxf(0.35, float(perfil.get("densidade", 1.0)))
	var quantos: int = mini(MAX_DECO, int(largura * dens / PASSO_DECO))
	if quantos <= 0:
		quantos = 1 if rng.randf() < 0.55 * dens else 0
	var margem := 30.0
	var util := largura - margem * 2.0
	if util <= 0.0 or quantos <= 0:
		return
	var total := 0.0
	var pesos: Array[float] = []
	for p: Array in PROPS_CHAO:
		var w: float = p[1] * (float(perfil.get(p[2], 1.0)) if p[2] != "" else 1.0)
		pesos.append(w)
		total += w
	var faixa := util / float(quantos)
	for i in quantos:
		var sorteio := rng.randf() * total
		var escolha: Array = PROPS_CHAO[0]
		for k in PROPS_CHAO.size():
			sorteio -= pesos[k]
			if sorteio <= 0.0:
				escolha = PROPS_CHAO[k]
				break
		var t := tex(escolha[0])
		if t == null:
			continue
		var s := Sprite2D.new()
		s.texture = t
		s.centered = false
		var e := rng.randf_range(escolha[3], escolha[4])
		s.scale = Vector2(e if rng.randf() < 0.5 else -e, e)
		var cx := -largura * 0.5 + margem + faixa * (float(i) + rng.randf_range(0.15, 0.85))
		# enterra 3 px na capa: os props nunca parecem colados por cima
		s.position = Vector2(cx, y0 - t.get_height() * e + 3.0)
		if s.scale.x < 0.0:
			s.position.x += t.get_width() * e
		s.z_index = -1                 # atrás da Koliani e dos inimigos
		vis.add_child(s)
		if String(escolha[0]).contains("lanterna") or String(escolha[0]).contains("tocha"):
			_brilho_quente(vis, s, t, e)


## A luz das lanternas: um halo aditivo, não uma PointLight2D. Não recolore a
## Koliani (uma luz de canvas tingia-lhe a pele ao passar) e custa um quad.
static func _brilho_quente(vis: Node, s: Sprite2D, t: Texture2D, e: float) -> void:
	var h := Sprite2D.new()
	h.texture = brilho()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	h.material = mat
	h.modulate = Color(1.0, 0.62, 0.26, 0.42)
	h.scale = Vector2(1.5, 1.5)
	var cx := s.position.x + (t.get_width() * absf(s.scale.x) * 0.5) * (1.0 if s.scale.x > 0.0 else -1.0)
	h.position = Vector2(cx, s.position.y + t.get_height() * e * 0.3)
	h.z_index = -1
	h.set_meta("regiao1_lanterna", true)
	vis.add_child(h)


static func brilho() -> GradientTexture2D:
	if _brilho == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.28), Color(1, 1, 1, 0)])
		_brilho = GradientTexture2D.new()
		_brilho.gradient = g
		_brilho.width = 96
		_brilho.height = 96
		_brilho.fill = GradientTexture2D.FILL_RADIAL
		_brilho.fill_from = Vector2(0.5, 0.5)
		_brilho.fill_to = Vector2(1.0, 0.5)
	return _brilho


## Vinhas por baixo, atrás do terreno (o ponto de agarre fica escondido).
static func pendurar(vis: Node, largura: float, y_base: float, grossa: bool,
		rng: RandomNumberGenerator) -> void:
	if largura < 90.0:
		return
	var lista: Array = PROPS_PENDURA_GROSSA if grossa else PROPS_PENDURA
	var quantos: int = mini(3, int(largura / 300.0))
	if not grossa:
		quantos = 1 if rng.randf() < 0.5 else 0
	elif quantos <= 0:
		quantos = 1 if rng.randf() < 0.5 else 0
	if quantos <= 0:
		return
	var margem := 40.0 if grossa else 18.0
	var util := largura - margem * 2.0
	if util <= 0.0:
		return
	var faixa := util / float(quantos)
	for i in quantos:
		var t := tex(lista[rng.randi() % lista.size()])
		if t == null:
			continue
		var s := Sprite2D.new()
		s.texture = t
		s.centered = false
		var e := rng.randf_range(0.8, 1.1) if grossa else rng.randf_range(0.6, 0.85)
		s.scale = Vector2(e if rng.randf() < 0.5 else -e, e)
		var cx := -largura * 0.5 + margem + faixa * (float(i) + rng.randf_range(0.1, 0.9))
		# `y_base` e' o labio VISIVEL do bloco, nao o fundo da colisao. A peca
		# entra 16..26 px para dentro dele: ficando atras do terreno
		# (`z_index = -2`), o sitio onde foi colada nunca se ve' e a raiz
		# parece nascer de dentro da rocha.
		#
		# 9H.17 H -- era aqui que estava a "vegetacao a flutuar". A ancora
		# usava o fundo da COLISAO, e a franja de baixo mais a capa descem
		# ~30 px abaixo dele: a peca ficava tapada 32 px e so' reaparecia ja'
		# longe da pedra, sem nada que a ligasse. Escondida de mais e' tao
		# mau como escondida de menos.
		s.position = Vector2(cx, y_base - rng.randf_range(16.0, 26.0))
		if s.scale.x < 0.0:
			s.position.x += t.get_width() * e
		s.z_index = -2
		vis.add_child(s)


## Gradiente vertical opaco->transparente, para o trabalho de VALOR nos
## blocos altos de terreno (9H.11). Não é arte nova: é o mesmo material do
## kit lido com outra luz. Um só recurso partilhado por todas as plataformas.
static var _vertical: GradientTexture2D = null

static func gradiente_vertical() -> GradientTexture2D:
	if _vertical != null:
		return _vertical
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.22, 1.0])
	g.colors = PackedColorArray([
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.18), Color(1, 1, 1, 0.62)])
	_vertical = GradientTexture2D.new()
	_vertical.gradient = g
	_vertical.fill_from = Vector2(0, 0)
	_vertical.fill_to = Vector2(0, 1)
	_vertical.width = 4
	_vertical.height = 128
	return _vertical
