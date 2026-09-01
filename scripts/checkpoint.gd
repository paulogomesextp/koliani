class_name Checkpoint
extends Area2D
## Guarda a posição de reaparecimento. A Koliani reaparece aqui enquanto
## tiver vidas; ao ficar sem vidas a campanha reinicia (ver
## `EstadoJogo.reiniciar_campanha`).
##
## Visual construído em código (ignora o `Visual`/`Luz` que a cena do nível
## traz): uma FOGUEIRA. Apagada é um monte de lenha fria; ao ser tocada
## pega fogo -- chama, brasas a subir e um halo AMARELO que treme. Pedido do
## Paulo (1 set 2026): o losango azul não lia como "ponto de regresso".

const COR_LENHA := Color(0.29, 0.19, 0.14)
const COR_LENHA_ACESA := Color(0.46, 0.29, 0.19)
const COR_PEDRA := Color(0.3, 0.3, 0.36)
const COR_LUZ := Color(1.0, 0.76, 0.32)

var _ativo := false
var _t := 0.0
var _base: Node2D
var _lenha: Node2D
var _chama: CPUParticles2D
var _brasas: CPUParticles2D
var _nucleo: Polygon2D
var _luz: PointLight2D


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	# esconde o visual antigo que vinha da cena do nível (poste + brilho)
	for nome in ["Visual", "Luz", "Brilho"]:
		var n := get_node_or_null(nome)
		if n and n is CanvasItem:
			(n as CanvasItem).visible = false
	_montar_visual()
	_pousar()
	if EstadoJogo.checkpoint.is_equal_approx(global_position):
		_ativar(true)


func _montar_visual() -> void:
	_base = Node2D.new()
	_base.name = "Fogueira"
	_base.z_index = -1  # a Koliani passa À FRENTE da fogueira
	add_child(_base)
	# --- pedras da roda (fica sempre visível, acesa ou não) --------------
	for i in 5:
		var a := PI * (0.12 + 0.76 * float(i) / 4.0)
		var pedra := Polygon2D.new()
		var r := 15.0
		var c := Vector2(cos(a) * r, 14.0 + sin(a) * 3.0)
		pedra.polygon = PackedVector2Array([
			c + Vector2(-4, 0), c + Vector2(-3, -4), c + Vector2(3, -4), c + Vector2(4, 1),
		])
		pedra.color = COR_PEDRA.darkened(0.1 * float(i % 2))
		_base.add_child(pedra)

	# --- lenha: três achas cruzadas -------------------------------------
	_lenha = Node2D.new()
	_base.add_child(_lenha)
	for ang in [-0.5, 0.35, 0.05]:
		var acha := Polygon2D.new()
		acha.polygon = PackedVector2Array([
			Vector2(-13, -2), Vector2(13, -2), Vector2(13, 3), Vector2(-13, 3),
		])
		acha.color = COR_LENHA
		acha.rotation = ang
		acha.position = Vector2(0.0, 11.0 - absf(ang) * 3.0)
		_lenha.add_child(acha)

	# --- chama (só emite depois de acesa) --------------------------------
	_chama = CPUParticles2D.new()
	_chama.amount = 26
	_chama.lifetime = 0.62
	_chama.emitting = false
	_chama.local_coords = false
	_chama.direction = Vector2(0, -1)
	_chama.spread = 12.0
	_chama.gravity = Vector2(0, -150)
	_chama.initial_velocity_min = 26.0
	_chama.initial_velocity_max = 62.0
	_chama.scale_amount_min = 2.5
	_chama.scale_amount_max = 6.0
	_chama.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_chama.emission_rect_extents = Vector2(7.0, 2.0)
	_chama.position = Vector2(0.0, 8.0)
	var rampa := Gradient.new()
	rampa.offsets = PackedFloat32Array([0.0, 0.25, 0.7, 1.0])
	rampa.colors = PackedColorArray([
		Color(1.0, 0.98, 0.72, 0.95), Color(1.0, 0.78, 0.26, 0.9),
		Color(0.92, 0.36, 0.1, 0.55), Color(0.35, 0.1, 0.05, 0.0),
	])
	_chama.color_ramp = rampa
	_base.add_child(_chama)

	# --- brasas que sobem devagar ---------------------------------------
	_brasas = CPUParticles2D.new()
	_brasas.amount = 10
	_brasas.lifetime = 1.8
	_brasas.emitting = false
	_brasas.local_coords = false
	_brasas.direction = Vector2(0, -1)
	_brasas.spread = 34.0
	_brasas.gravity = Vector2(0, -22)
	_brasas.initial_velocity_min = 12.0
	_brasas.initial_velocity_max = 34.0
	_brasas.scale_amount_min = 1.0
	_brasas.scale_amount_max = 2.0
	_brasas.position = Vector2(0.0, 4.0)
	var rb := Gradient.new()
	rb.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	rb.colors = PackedColorArray([
		Color(1.0, 0.9, 0.5, 0.0), Color(1.0, 0.72, 0.28, 0.9), Color(0.8, 0.3, 0.1, 0.0),
	])
	_brasas.color_ramp = rb
	_base.add_child(_brasas)

	# --- coração da chama (dá o "cheio" que as partículas não dão) -------
	_nucleo = Polygon2D.new()
	_nucleo.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(6, -4), Vector2(4, 6), Vector2(-4, 6), Vector2(-6, -4),
	])
	_nucleo.color = Color(1.0, 0.86, 0.45, 0.7)
	_nucleo.position = Vector2(0.0, 6.0)
	_nucleo.visible = false
	_base.add_child(_nucleo)

	_luz = PointLight2D.new()
	_luz.texture = _tex_luz()
	_luz.color = COR_LUZ
	_luz.energy = 0.0
	_luz.position = Vector2(0.0, 2.0)
	_luz.scale = Vector2(0.9, 0.9)
	_base.add_child(_luz)


## A fogueira tem de assentar no CHÃO, não ficar a pairar: o nó do
## checkpoint anda 46 px acima da plataforma (ver `gerador_corredor.gd`) e
## nos níveis à mão a altura varia. Um raio para baixo resolve os dois casos.
func _pousar() -> void:
	if _base == null:
		return
	var espaco := get_world_2d().direct_space_state
	var params := PhysicsRayQueryParameters2D.create(
		global_position, global_position + Vector2(0.0, 160.0), 1)
	params.collide_with_areas = false
	var hit := espaco.intersect_ray(params)
	var queda := 46.0
	if not hit.is_empty():
		queda = (hit["position"] as Vector2).y - global_position.y
	_base.position.y = maxf(0.0, queda) - 16.0


func _escalar(pts: PackedVector2Array, f: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in pts:
		out.append(v * f)
	return out


func _tex_luz() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 180
	t.height = 180
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


func _process(dt: float) -> void:
	if not _ativo:
		return
	_t += dt
	# tremor de fogo: duas ondas desencontradas + um salto pequeno ao acaso
	var bruxuleio := 0.16 * sin(_t * 9.3) + 0.09 * sin(_t * 21.7) + randf_range(-0.04, 0.04)
	if _luz:
		_luz.energy = 1.25 + bruxuleio
	if _nucleo:
		_nucleo.scale = Vector2(1.0 + bruxuleio * 0.5, 1.0 + bruxuleio * 0.9)
		_nucleo.modulate.a = 0.8 + bruxuleio


func _ao_entrar(corpo: Node) -> void:
	if corpo is Koliani and not _ativo:
		_ativar(false)
		EstadoJogo.definir_checkpoint(global_position)
		Som.toca("selo", -12.0)


func _ativar(instantaneo: bool) -> void:
	_ativo = true
	if _nucleo:
		_nucleo.visible = true
	if _chama:
		_chama.emitting = true
	if _brasas:
		_brasas.emitting = true
	if _lenha:
		# a lenha acesa aquece de cor
		for acha in _lenha.get_children():
			if acha is Polygon2D:
				if instantaneo:
					(acha as Polygon2D).color = COR_LENHA_ACESA
				else:
					create_tween().tween_property(acha, "color", COR_LENHA_ACESA, 0.3)
	if instantaneo:
		if _luz:
			_luz.energy = 1.25
			_luz.scale = Vector2(1.7, 1.7)
		return
	if _luz:
		# labareda: o fogo pega com um golpe de luz e depois assenta
		var tl := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tl.tween_property(_luz, "scale", Vector2(2.2, 2.2), 0.22)
		tl.parallel().tween_property(_luz, "energy", 1.9, 0.22)
		tl.tween_property(_luz, "scale", Vector2(1.7, 1.7), 0.3)
		tl.parallel().tween_property(_luz, "energy", 1.25, 0.3)
