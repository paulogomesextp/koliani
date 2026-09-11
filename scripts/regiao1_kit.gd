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
const PERFIS := {
	1: {"mood": "entrada", "corrupcao": 0.25, "nevoa": 0.55, "ruinas": 0.25, "cascatas": 0.3, "lanternas": 0.35},
	2: {"mood": "entrada", "corrupcao": 0.35, "nevoa": 0.95, "ruinas": 0.2, "cascatas": 0.45, "lanternas": 0.3},
	3: {"mood": "ruinas", "corrupcao": 0.5, "nevoa": 0.6, "ruinas": 0.85, "cascatas": 0.2, "lanternas": 0.45},
	4: {"mood": "cascatas", "corrupcao": 0.6, "nevoa": 0.75, "ruinas": 0.35, "cascatas": 0.9, "lanternas": 0.3},
	5: {"mood": "coracao", "corrupcao": 1.0, "nevoa": 0.6, "ruinas": 0.4, "cascatas": 0.3, "lanternas": 0.2},
}

## Tinta do panorama por mood: razão média-da-variante / média-do-panorama,
## medida na 08 pelo produtor (`kit_9c_manifest.json`, `tintas_por_mood_08`),
## aplicada a 35%. As tiras de mood são mais claras e quentes do que o
## panorama; a 100% puxavam a noite para o crepúsculo.
##   entrada [1.18, 1.143, 0.85]  ruinas [1.18, 1.052, 0.85]
##   cascatas [1.158, 1.143, 1.039]  coracao [1.18, 0.85, 0.938]
const FORCA_TINTA := 0.35
const TINTAS := {
	"entrada": Color(1.18, 1.143, 0.85),
	"ruinas": Color(1.18, 1.052, 0.85),
	"cascatas": Color(1.158, 1.143, 1.039),
	"coracao": Color(1.18, 0.85, 0.938),
}


static func tinta(perfil: Dictionary) -> Color:
	var t: Color = TINTAS.get(perfil.get("mood", "entrada"), Color.WHITE)
	return Color.WHITE.lerp(t, FORCA_TINTA)

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
const PROPS_PENDURA := ["props/vinha_a.png", "props/vinha_b.png"]
const PROPS_PENDURA_GROSSA := ["props/vinha_a.png", "props/vinha_b.png", "props/vinha_longa.png"]

const PASSO_DECO := 170.0
const MAX_DECO := 9

static var _cache := {}
static var _brilho: GradientTexture2D = null


static func tex(rel: String) -> Texture2D:
	if not _cache.has(rel):
		var cam := "%s/%s" % [DIR, rel]
		_cache[rel] = load(cam) if ResourceLoader.exists(cam) else null
	return _cache[rel]


## O nó que ligou o kit neste nível, ou null (kit desligado).
static func alvo(no: Node) -> Node:
	if no == null or not no.is_inside_tree():
		return null
	return no.get_tree().get_first_node_in_group(GRUPO)


static func perfil_de(kit: Node) -> Dictionary:
	var n := 1
	if kit != null and "perfil" in kit:
		n = int(kit.perfil)
	return PERFIS.get(n, PERFIS[1])


## Capa: a variante com erva alta entra numa em cada três plataformas.
static func topo(rng: RandomNumberGenerator) -> Texture2D:
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
	var quantos: int = mini(MAX_DECO, int(largura / PASSO_DECO))
	if quantos <= 0:
		quantos = 1 if rng.randf() < 0.55 else 0
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
		s.position = Vector2(cx, y_base - rng.randf_range(6.0, 14.0))
		if s.scale.x < 0.0:
			s.position.x += t.get_width() * e
		s.z_index = -2
		vis.add_child(s)
