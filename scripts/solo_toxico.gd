class_name SoloToxico
extends Area2D
## "Solo contaminado" e "nuvens de veneno" da Regiao XII -- Terras Envenenadas
## (N56 em diante; `docs/art_direction/regions/region_12/master_production_board.png`,
## "ACUMULO DE VENENO": dano progressivo, reduzido em zonas limpas).
##
## Uma faixa de chao (a colisao e' a da `Plataforma` por baixo, que nao muda)
## ou uma nuvem que anda de um lado para o outro. Quem estiver la' dentro fica
## ENVENENADO (o estado que ja' existe na Koliani: dano em ticks, a tinta
## verde, passa com o tempo) -- nao leva dano de impacto, por isso o solo
## contaminado e' um preco a pagar por um atalho e nao uma armadilha de morte.
## Saltar por cima, ou parar na `ZonaLimpa`, sai a custo zero.
##
##   modo "solo"   a faixa pousa no chao: a origem e' o MEIO da superficie.
##   modo "nuvem"  um volume no ar, a oscilar `amplitude` px em `periodo` s.

@export_enum("solo", "nuvem") var modo := "solo" : set = _set_modo
@export var largura := 240.0 : set = _set_largura
@export var altura := 34.0
@export var amplitude := 0.0
@export var periodo := 5.0
@export var fase := 0.0
@export var veneno_seg := 2.4
@export var veneno_dano := 2
## Intensidade 0..1: a nuvem "fraca" do N56 so' envenena 1,2 s.
@export_range(0.2, 1.5) var forca := 1.0
@export var textura: Texture2D
@export var textura_bolhas: Texture2D

const REPETE := 0.5
var _forma: CollisionShape2D
var _pintura: Sprite2D
var _bolhas: CPUParticles2D
var _luz: PointLight2D
var _origem_x := 0.0
var _t_rep := 0.0


func _set_modo(v: String) -> void:
	modo = v
	if is_node_ready():
		_reconstruir()


func _set_largura(v: float) -> void:
	largura = maxf(24.0, v)
	if is_node_ready():
		_reconstruir()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_origem_x = position.x
	_forma = CollisionShape2D.new()
	_forma.name = "Zona"
	add_child(_forma)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_pintura = Sprite2D.new()
	_pintura.name = "Pintura"
	_pintura.material = mat
	_pintura.z_index = 2
	add_child(_pintura)
	_bolhas = CPUParticles2D.new()
	_bolhas.name = "Bolhas"
	_bolhas.local_coords = false
	_bolhas.direction = Vector2(0, -1)
	_bolhas.spread = 30.0
	_bolhas.gravity = Vector2(0, -18)
	_bolhas.initial_velocity_min = 8.0
	_bolhas.initial_velocity_max = 34.0
	_bolhas.scale_amount_min = 1.4
	_bolhas.scale_amount_max = 3.6
	_bolhas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_bolhas.z_index = 3
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	ramp.colors = PackedColorArray([Color(0.7, 1.0, 0.4, 0.0), Color(0.55, 1.0, 0.3, 0.8),
		Color(0.25, 0.6, 0.15, 0.0)])
	_bolhas.color_ramp = ramp
	add_child(_bolhas)
	_luz = PointLight2D.new()
	_luz.name = "Luz"
	_luz.color = Color(0.5, 1.0, 0.35)
	_luz.energy = 0.55
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 128
	gt.height = 128
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	_luz.texture = gt
	add_child(_luz)
	_reconstruir()


func _reconstruir() -> void:
	if _forma == null:
		return
	var r := RectangleShape2D.new()
	r.size = Vector2(largura, altura)
	_forma.shape = r
	if modo == "solo":
		_forma.position = Vector2(0, -altura * 0.5)
	else:
		_forma.position = Vector2.ZERO
	if textura:
		_pintura.texture = textura
		var e := largura / float(textura.get_width())
		if modo == "solo":
			_pintura.scale = Vector2(e, clampf(e, 0.5, 1.1))
			_pintura.position = Vector2(0, -float(textura.get_height()) * _pintura.scale.y * 0.36)
		else:
			_pintura.scale = Vector2(e, altura / float(textura.get_height()))
			_pintura.position = Vector2.ZERO
	_bolhas.emission_rect_extents = Vector2(largura * 0.46, 3.0)
	_bolhas.amount = clampi(int(largura / 22.0), 4, 24)
	_bolhas.lifetime = 1.6
	_bolhas.position = Vector2(0, -4.0) if modo == "solo" else Vector2(0, altura * 0.3)
	_luz.position = Vector2(0, -16.0) if modo == "solo" else Vector2.ZERO
	_luz.scale = Vector2(largura / 128.0 * 1.2, 0.8 if modo == "solo" else altura / 128.0 * 1.6)


func _process(dt: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	if modo == "nuvem" and amplitude > 0.0:
		position.x = _origem_x + sin((t + fase) * TAU / maxf(0.5, periodo)) * amplitude
	var pulso := 0.5 + 0.5 * sin(t * 2.2 + fase)
	if modo == "solo":
		_pintura.modulate = Color(0.75, 1.0, 0.55, 0.55 + 0.25 * pulso)
	else:
		_pintura.modulate = Color(0.8, 1.0, 0.5, (0.35 + 0.2 * pulso) * minf(1.0, forca))
	_t_rep -= dt
	if _t_rep <= 0.0:
		_t_rep = REPETE
		envenenar_presentes()


func envenenar_presentes() -> void:
	for c in get_overlapping_bodies():
		if c is Koliani and c.has_method("envenenar"):
			c.envenenar(veneno_seg * minf(1.0, forca), veneno_dano)
