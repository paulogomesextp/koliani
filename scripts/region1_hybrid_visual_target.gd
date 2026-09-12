@tool
extends Node2D
## Execution 9C — ambiente de produção da Região I (Floresta Corrompida).
##
## Só apresentação: não cria corpos, áreas nem colisões, e não mexe na
## geometria. Liga o kit (`regiao1_kit.gd`) para as plataformas do nível e
## monta a profundidade aprovada na prancha 08:
##
##   camada 4  BackgroundApproved08  panorama + Heart Tree   (fator 0.12)
##   camada 3  Camada3Distante       serra, cascatas, arcos  (fator 0.26)
##   camada 2  Camada2Floresta       árvores e ruínas        (fator 0.46)
##             NevoaMedia            névoa entre 2 e o jogo  (fator 0.6)
##   jogo      plataformas do kit, NevoaChao por trás delas
##   camada 1  PrimeiroPlano         vegetação em silhueta   (fator 1.15)
##
## O parallax é feito à mão (posição da camada = desvio da câmara × (1 − f)):
## com a câmara na `referencia`, cada peça fica exactamente onde foi pousada.
## `ativo = false` é o interruptor de rollback.

const Kit := preload("res://scripts/regiao1_kit.gd")

@export var ativo := true
## Execution 8 montava só o panorama em L2–L5. Desde a 9C os cinco níveis
## montam o kit inteiro; fica para compatibilidade das cenas antigas.
@export var apenas_panorama_aprovado := false
## Variante de cenário da 08: 1–2 entrada, 3 ruínas, 4 cascatas, 5 Heart Tree.
@export_range(1, 5) var perfil := 1
@export var limite_esquerdo := -2550.0
@export var limite_direito := 3850.0
## Câmara de referência (centro do ecrã) em que as camadas ficam no sítio.
@export var referencia := Vector2(1900.0, 560.0)

const COR_SHADOWBLADE := Color("bb8cff")
const COR_SHADOWBLADE_NUCLEO := Color("f1e5ff")
## Execution 9H: o panorama passou a vir em DOBRO (Lanczos + máscara de
## desfoque, `tools/nitidez_panorama_9h.py`) e desenha-se a 1,5x em vez de
## 3x. A geometria no mundo é a mesma (2 x 1,5 = 3); o que muda é que metade
## da ampliação deixou de ser feita pelo filtro bilinear do GPU -- era essa
## a razão de o fundo parecer desfocado.
const TEX_BACKGROUND_APPROVED := preload("res://assets/art/regions/region_01_forest/production/backgrounds/region1_panorama_heart_tree_x2.png")
const TEX_BACKGROUND_LEFT := preload("res://assets/art/regions/region_01_forest/production/backgrounds/region1_panorama_left_cap_x2.png")
const TEX_BACKGROUND_RIGHT := preload("res://assets/art/regions/region_01_forest/production/backgrounds/region1_panorama_right_cap_x2.png")
## Fator a que o panorama já vem ampliado no disco.
const PANORAMA_HD := 2.0
## Coluna da Heart Tree dentro do panorama (px da textura de origem; 08:
## x≈450 − 18), convertida para os píxeis da textura em dobro.
const HEART_TREE_X := 432.0 * PANORAMA_HD

var _camadas: Array = []          # [Node2D, fator Vector2]
var _particulas: CPUParticles2D
var _restauro_hud: Array[Dictionary] = []
var _hud_aplicado := false


class AssinaturaLamina:
	extends Node2D
	var alvo: Node
	var limite_esquerdo := -300.0
	var limite_direito := 1250.0
	var pulso := 0.0
	var luz: PointLight2D

	func _ready() -> void:
		z_index = 8
		luz = PointLight2D.new()
		luz.texture = _textura_luz()
		luz.color = Color("c49cff")
		luz.energy = 1.15
		luz.scale = Vector2(0.72, 0.58)
		luz.position = Vector2(18, -7)
		add_child(luz)
		visible = false

	func _process(dt: float) -> void:
		if alvo == null or not is_instance_valid(alvo):
			visible = false
			return
		pulso += dt
		var valor_restante: Variant = alvo.get("_ataque_restante")
		var restante := float(valor_restante) \
			if typeof(valor_restante) in [TYPE_FLOAT, TYPE_INT] else 0.0
		visible = restante > 0.0 and alvo.global_position.x >= limite_esquerdo \
			and alvo.global_position.x <= limite_direito
		if visible:
			luz.energy = 1.0 + sin(pulso * 18.0) * 0.18
			queue_redraw()

	func _draw() -> void:
		var centro := Vector2(11, -8)
		draw_arc(centro, 38.0, -1.28, 1.12, 28,
			Color(0.62, 0.30, 1.0, 0.23), 11.0, true)
		draw_arc(centro, 36.0, -1.25, 1.08, 28,
			Color("bb8cff"), 5.0, true)
		draw_arc(centro, 34.0, -1.20, 1.02, 28,
			Color("f1e5ff"), 1.7, true)
		draw_circle(Vector2(38, -27), 4.2, Color("f1e5ff"))

	func _textura_luz() -> GradientTexture2D:
		var grad := Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
		grad.colors = PackedColorArray([
			Color(1, 1, 1, 0.95), Color(0.75, 0.45, 1, 0.32), Color(0.5, 0.2, 1, 0),
		])
		var tex := GradientTexture2D.new()
		tex.gradient = grad
		tex.width = 192
		tex.height = 192
		tex.fill = 1
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		return tex


func _enter_tree() -> void:
	# No _enter_tree (e não no _ready) porque as plataformas do nível fazem o
	# `_ready` antes de este nó acabar o dele, e perguntam pelo grupo nessa hora.
	if ativo:
		add_to_group(Kit.GRUPO)


func _ready() -> void:
	if not ativo:
		visible = false
		set_process(false)
		return
	set_meta("visual_target_5c", true)
	set_meta("region1_kit_9c", true)
	set_meta("intervalo_target", Vector2(limite_esquerdo, limite_direito))
	var p := Kit.perfil_de(self)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9000 + perfil
	_montar_background(p)
	_montar_heart_tree()
	_montar_camada3(p, rng)
	_montar_camada2(p, rng)
	_montar_nevoa(p)
	_montar_corrupcao(p)
	if Engine.is_editor_hint():
		set_process(false)
		return
	_esconder_legado.call_deferred()
	_montar_primeiro_plano.call_deferred()
	if perfil == 1:
		_ligar_shadowblade.call_deferred()


func _exit_tree() -> void:
	_restaurar_skin_hud()


func _process(_dt: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var c := cam.get_screen_center_position()
	var desvio := c - referencia
	for par: Array in _camadas:
		var n: Node2D = par[0]
		var f: Vector2 = par[1]
		n.position = desvio * (Vector2.ONE - f)
	if _particulas:
		_particulas.global_position = c


## Camada nova sob este nó, com parallax. Não é interpolada: a posição é
## escrita no `_process` a partir da câmara (interpolada, ficava um tick
## atrás e nadava contra o cenário — o mesmo caso da `Poeira`).
func _camada(nome: String, z: int, fator: Vector2) -> Node2D:
	var camada := Node2D.new()
	camada.name = nome
	camada.z_index = z
	camada.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(camada)
	_camadas.append([camada, fator])
	return camada


func _montar_background(p: Dictionary) -> void:
	var camada := _camada("BackgroundApproved08", -30, Vector2(0.12, 0.08))
	camada.set_meta("approved_source", "08_REGION_I_ART_KIT_BACKGROUNDS_PARALLAX_v1_0.png")
	camada.set_meta("derivation", "crop lossless (18,97,952,247) + mirrored edge caps")
	# 18% mais escuro: a camada mais funda recua, e o magenta da Heart Tree
	# deixa de concorrer com a corrupção do plano de jogo
	camada.modulate = Kit.tinta(p) * Color(0.82, 0.82, 0.82, 1.0)
	# Escala 3x no MUNDO (a 4x da 6A, vezes o zoom 1,4 da câmara, a prancha
	# desfocava), mas metade dela já vem feita no disco: 3 / PANORAMA_HD.
	# A Heart Tree fica a meio do nível com a câmara na referência; os caps
	# são as extremidades espelhadas, encostadas pixel a pixel.
	var e := 3.0 / PANORAMA_HD
	var x0 := referencia.x - HEART_TREE_X * e
	var y0 := 170.0
	var fim := x0 + TEX_BACKGROUND_APPROVED.get_width() * e
	var le := TEX_BACKGROUND_LEFT.get_width() * e
	var ld := TEX_BACKGROUND_RIGHT.get_width() * e
	_sprite_aprovado(camada, TEX_BACKGROUND_APPROVED, Vector2(x0, y0), Vector2(e, e))
	_sprite_aprovado(camada, TEX_BACKGROUND_LEFT, Vector2(x0, y0), Vector2(-e, e))
	_sprite_aprovado(camada, TEX_BACKGROUND_LEFT, Vector2(x0 - le * 2.0, y0), Vector2(e, e))
	_sprite_aprovado(camada, TEX_BACKGROUND_RIGHT, Vector2(fim + ld, y0), Vector2(-e, e))
	_sprite_aprovado(camada, TEX_BACKGROUND_RIGHT, Vector2(fim + ld, y0), Vector2(e, e))


func _montar_heart_tree() -> void:
	var camada := Node2D.new()
	camada.name = "LandmarkHeartTreeApproved08"
	camada.z_index = -18
	camada.set_meta("baked_into", "BackgroundApproved08")
	camada.set_meta("production_status", "approved_crop")
	add_child(camada)


## Camada 3 da 08: serra contínua, com cascatas e arcos de ruína pousados
## nela. Quantos de cada, conforme a variante do nível.
func _montar_camada3(p: Dictionary, rng: RandomNumberGenerator) -> void:
	var camada := _camada("Camada3Distante", -26, Vector2(0.26, 0.16))
	camada.modulate = Color(0.86, 0.9, 1.0, 0.82)
	var serra := Kit.tex("fundo/fundo_montanhas.png")
	var chao := 700.0
	if serra:
		# A serra assenta 60 px abaixo do chão das peças: o fundo a direito da
		# tira fica atrás da floresta. As cópias sobrepõem-se 24 px (as pontas
		# da tira têm contorno, e a 2 px via-se a costura) e a região corta a
		# coluna de contorno de cada lado.
		var e := 2.2
		var corte := 3.0
		var w := (serra.get_width() - corte * 2.0) * e
		var x := referencia.x - 3200.0
		var i := 0
		while x < referencia.x + 3200.0:
			var s := _sprite_fundo(camada, serra, Vector2(x, chao + 60.0 - serra.get_height() * e), e,
				i % 2 == 1)
			s.region_enabled = true
			s.region_rect = Rect2(corte, 0.0, serra.get_width() - corte * 2.0, serra.get_height())
			if i % 2 == 1:
				s.position.x = x + w
			s.set_meta("peca", "serra")
			x += w - 24.0
			i += 1
	var pecas := [
		["fundo/fundo_cascata.png", float(p["cascatas"]) * 7.0],
		["fundo/fundo_colunas_cascata.png", float(p["cascatas"]) * 5.0],
		["fundo/fundo_arco_ruina.png", float(p["ruinas"]) * 7.0],
	]
	for peca: Array in pecas:
		var t := Kit.tex(peca[0])
		if t == null:
			continue
		var n := int(round(peca[1]))
		for k in n:
			var e := rng.randf_range(1.8, 2.2)
			var x := referencia.x - 2600.0 + (5200.0 / float(maxi(1, n))) * (float(k) + rng.randf_range(0.1, 0.9))
			_sprite_fundo(camada, t, Vector2(x, chao + 30.0 - t.get_height() * e), e,
				rng.randf() < 0.5)


## Camada 2 da 08: floresta e ruínas a média distância. Silhuetas escuras,
## espaçadas — a camada dá profundidade, não enche o ecrã.
func _montar_camada2(p: Dictionary, rng: RandomNumberGenerator) -> void:
	var camada := _camada("Camada2Floresta", -22, Vector2(0.46, 0.3))
	# alfa 0,6: silhueta escura inteira atrás de pedra escura apagava a aresta
	camada.modulate = Color(1, 1, 1, 0.6)
	var arvores := ["fundo/fundo_arvores_par.png", "fundo/fundo_arvore_a.png",
		"fundo/fundo_arvore_b.png"]
	var chao := 860.0
	var x := referencia.x - 2800.0
	while x < referencia.x + 2800.0:
		var t := Kit.tex(arvores[rng.randi() % arvores.size()])
		if t:
			var e := rng.randf_range(2.0, 2.4)
			_sprite_fundo(camada, t, Vector2(x, chao - t.get_height() * e), e, rng.randf() < 0.5)
			x += t.get_width() * e * rng.randf_range(0.9, 1.6)
		else:
			x += 400.0
	# ruínas e cascatas da prancha 10 (graduadas), mais perto e mais escuras
	var extra := [
		["props/ruina.png", float(p["ruinas"]) * 5.0],
		["props/cascata.png", float(p["cascatas"]) * 4.0],
	]
	for peca: Array in extra:
		var t := Kit.tex(peca[0])
		if t == null:
			continue
		var n := int(round(peca[1]))
		for k in n:
			var e := rng.randf_range(2.0, 2.6)
			var px := referencia.x - 2400.0 + (4800.0 / float(maxi(1, n))) * (float(k) + rng.randf_range(0.1, 0.9))
			var s := _sprite_fundo(camada, t, Vector2(px, chao + 10.0 - t.get_height() * e), e,
				rng.randf() < 0.5)
			s.modulate = Color(0.62, 0.68, 0.84)
			s.z_index = -1


func _montar_nevoa(p: Dictionary) -> void:
	var t := Kit.tex("atmosfera/nevoa.png")
	if t == null:
		return
	var densidade: float = p["nevoa"]
	# névoa média: entre a floresta e o plano de jogo
	var media := _camada("NevoaMedia", -20, Vector2(0.6, 0.4))
	var s := _faixa(media, t, Vector2(referencia.x - 3600.0, 470.0), Vector2(7200.0, t.get_height()), 3.0)
	s.modulate = Color(1, 1, 1, 0.34 * densidade)
	# névoa do chão: ATRÁS do terreno (z −6), por isso nunca tapa uma aresta
	var chao := Node2D.new()
	chao.name = "NevoaChao"
	chao.z_index = -6
	add_child(chao)
	var s2 := _faixa(chao, t, Vector2(limite_esquerdo - 800.0, 600.0),
		Vector2((limite_direito - limite_esquerdo + 1600.0) / 2.0, t.get_height()), 2.0)
	s2.modulate = Color(0.9, 0.95, 1.0, 0.26 * densidade)
	var tw := create_tween().set_loops()
	tw.tween_property(s2, "position:x", s2.position.x + 60.0, 9.0)
	tw.tween_property(s2, "position:x", s2.position.x, 9.0)


## Partículas de corrupção (a faísca da 08). Coladas ao centro do ecrã.
func _montar_corrupcao(p: Dictionary) -> void:
	var t := Kit.tex("corrupcao/faisca_corrupcao.png")
	if t == null:
		return
	var intensidade: float = p["corrupcao"]
	_particulas = CPUParticles2D.new()
	_particulas.name = "ParticulasCorrupcao"
	_particulas.z_index = -3
	_particulas.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_particulas.texture = t
	_particulas.amount = int(8.0 + 22.0 * intensidade)
	_particulas.lifetime = 6.0
	_particulas.preprocess = 4.0
	_particulas.lifetime_randomness = 0.5
	_particulas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particulas.emission_rect_extents = Vector2(520.0, 300.0)
	_particulas.direction = Vector2(0.2, -1.0)
	_particulas.spread = 50.0
	_particulas.gravity = Vector2(2.0, -4.0)
	_particulas.initial_velocity_min = 3.0
	_particulas.initial_velocity_max = 10.0
	_particulas.scale_amount_min = 0.6
	_particulas.scale_amount_max = 1.3
	var rampa := Gradient.new()
	rampa.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	rampa.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.85),
		Color(1, 1, 1, 0.6), Color(1, 1, 1, 0)])
	_particulas.color_ramp = rampa
	add_child(_particulas)


## Camada 1 da 08: a vegetação em silhueta à frente de tudo. Fica abaixo do
## fundo visual das plataformas e abaixo da superfície das poças mortais —
## enquadra o ecrã por baixo sem tapar pouso, arestas nem perigos.
func _montar_primeiro_plano() -> void:
	if not is_inside_tree():
		return
	var t := Kit.tex("fundo/frente_vegetacao.png")
	if t == null:
		return
	# Assenta 40 px abaixo da superfície da poça mortal mais alta: a linha do
	# perigo e todas as arestas de pouso ficam sempre por cima dela.
	var topo := INF
	for n in get_parent().get_children():
		if n is Node2D and "altura" in n and "largura" in n and n.has_method("_set_altura"):
			topo = minf(topo, n.position.y - float(n.altura) * 0.5 + 40.0)
	if topo == INF:
		topo = 830.0
	var camada := _camada("PrimeiroPlano", 12, Vector2(1.15, 1.0))
	camada.set_meta("topo_mundo", topo)
	var e := 2.4
	var w := t.get_width() * e
	var x := limite_esquerdo - 1200.0
	var i := 0
	while x < limite_direito + 1600.0:
		var s := _sprite_fundo(camada, t, Vector2(x, topo), e, i % 2 == 1)
		s.modulate = Color(1, 1, 1, 0.94)
		x += w - 4.0
		i += 1


## Esconde o fundo LEGADO da Atmosfera (pack CC0 + silhuetas por código). O
## céu em degradé (`Ceu`), a grade, a vinheta e a poeira ficam.
func _esconder_legado() -> void:
	var atm := get_tree().get_first_node_in_group("atmosfera")
	if atm == null:
		return
	var escondidos: Array[String] = []
	var par := atm.get_node_or_null("Parallax")
	if par:
		for c in par.get_children():
			if c.name != "Ceu" and c is CanvasItem:
				c.visible = false
				escondidos.append("Parallax/%s" % c.name)
	for nome in ["FrenteAmbiente", "Raios"]:
		var n := atm.get_node_or_null(nome) as CanvasItem
		if n:
			n.visible = false
			escondidos.append(nome)
	set_meta("legado_escondido", escondidos)


func _ligar_shadowblade() -> void:
	if not ativo or not is_inside_tree():
		return
	var koliani := get_tree().get_first_node_in_group("koliani")
	if koliani == null:
		return
	var assinatura := AssinaturaLamina.new()
	assinatura.name = "HybridShadowbladeSignature"
	assinatura.alvo = koliani
	assinatura.limite_esquerdo = limite_esquerdo
	assinatura.limite_direito = limite_direito
	koliani.add_child(assinatura)


func _restaurar_skin_hud() -> void:
	if not _hud_aplicado:
		return
	for dados in _restauro_hud:
		var barra: ProgressBar = dados.get("barra")
		if barra == null or not is_instance_valid(barra):
			continue
		barra.add_theme_stylebox_override("background", dados["background"])
		barra.add_theme_stylebox_override("fill", dados["fill"])
		barra.modulate = dados["modulate"]
	_restauro_hud.clear()
	_hud_aplicado = false


const SHADER_NITIDEZ := preload("res://assets/shaders/nitidez_fundo.gdshader")

## Máscara de desfoque no pixel do ECRÃ (ver `nitidez_fundo.gdshader`).
## `ampliacao` é a escala a que a peça vai ser desenhada: quanto mais se
## amplia, mais macia fica, e mais força precisa. Sem tecto não é: acima de
## ~0,8 a aresta ganha halo branco e a pintura parece recortada.
static func _nitidez(s: Sprite2D, ampliacao: float) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_NITIDEZ
	mat.set_shader_parameter("forca", clampf(0.30 * ampliacao + 0.20, 0.35, 1.05))
	mat.set_shader_parameter("raio", 1.30)
	s.material = mat


func _sprite_fundo(camada: Node2D, t: Texture2D, pos: Vector2, e: float,
		espelho: bool) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = t
	s.centered = false
	s.scale = Vector2(-e if espelho else e, e)
	s.position = pos + (Vector2(t.get_width() * e, 0.0) if espelho else Vector2.ZERO)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_nitidez(s, e)
	camada.add_child(s)
	return s


func _faixa(camada: Node2D, t: Texture2D, pos: Vector2, tam: Vector2, e: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = t
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	s.region_enabled = true
	s.region_rect = Rect2(Vector2.ZERO, tam)
	s.scale = Vector2(e, e)
	s.position = pos
	_nitidez(s, e)
	camada.add_child(s)
	return s


func _sprite_aprovado(camada: Node2D, textura: Texture2D, pos: Vector2,
		escala: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = textura
	s.centered = false
	s.position = pos
	s.scale = escala
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_nitidez(s, maxf(absf(escala.x), absf(escala.y)))
	camada.add_child(s)
	return s
