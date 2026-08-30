class_name PenduloLamina
extends Node2D
## Lamina pendular: uma foice presa a um eixo no tecto que varre um arco.
## Mecanica de cenario partilhada dos gauntlets de aproximacao -- obriga a
## cronometrar o salto. So' magoa por contacto (Area2D na lamina); nunca
## bloqueia a passagem. Visual todo em codigo.
##
## @export comprimento / amplitude_graus / periodo / fase / dano

@export var comprimento := 150.0
@export var amplitude_graus := 68.0
@export var periodo := 2.2
@export var fase := 0.0
@export var dano := 20

var _t := 0.0
var _braco: Node2D
var _lamina_area: Area2D
var _glint: Polygon2D
var _luz: PointLight2D


func _ready() -> void:
	_t = fase * periodo
	_montar_visual()


func _montar_visual() -> void:
	# eixo no tecto
	var eixo := Polygon2D.new()
	eixo.polygon = PackedVector2Array([
		Vector2(-7, -6), Vector2(7, -6), Vector2(7, 4), Vector2(-7, 4)])
	eixo.color = Color(0.14, 0.13, 0.16)
	add_child(eixo)
	var perno := Polygon2D.new()
	perno.polygon = _circulo(4.0)
	perno.color = Color(0.4, 0.37, 0.44)
	add_child(perno)

	_braco = Node2D.new()
	add_child(_braco)

	var corrente := Line2D.new()
	corrente.points = PackedVector2Array([Vector2.ZERO, Vector2(0, comprimento - 18.0)])
	corrente.width = 4.0
	corrente.default_color = Color(0.28, 0.26, 0.3)
	_braco.add_child(corrente)

	# foice / lamina no fundo do braco
	var lamina := Polygon2D.new()
	lamina.position = Vector2(0, comprimento)
	lamina.polygon = PackedVector2Array([
		Vector2(-34, -6), Vector2(0, -18), Vector2(34, -6),
		Vector2(30, 6), Vector2(0, 14), Vector2(-30, 6)])
	lamina.color = Color(0.75, 0.78, 0.86)
	_braco.add_child(lamina)

	var fio := Line2D.new()
	fio.position = Vector2(0, comprimento)
	fio.points = PackedVector2Array([Vector2(-34, -6), Vector2(0, -18), Vector2(34, -6)])
	fio.width = 2.0
	fio.default_color = Color(1, 1, 1, 0.9)
	_braco.add_child(fio)

	_glint = Polygon2D.new()
	_glint.position = Vector2(0, comprimento)
	_glint.polygon = PackedVector2Array([Vector2(-6, -12), Vector2(6, -12), Vector2(0, 10)])
	_glint.color = Color(1, 1, 1, 0.0)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glint.material = m
	_braco.add_child(_glint)

	_luz = PointLight2D.new()
	_luz.position = Vector2(0, comprimento)
	_luz.texture = _tex_luz()
	_luz.color = Color(0.9, 0.95, 1.0)
	_luz.energy = 0.0
	_luz.scale = Vector2(0.4, 0.4)
	_braco.add_child(_luz)

	_lamina_area = Area2D.new()
	_lamina_area.collision_layer = 0
	_lamina_area.collision_mask = 2
	_lamina_area.position = Vector2(0, comprimento)
	var cs := CollisionShape2D.new()
	var forma := CapsuleShape2D.new()
	forma.radius = 14.0
	forma.height = 60.0
	cs.shape = forma
	cs.rotation = PI / 2.0
	_lamina_area.add_child(cs)
	_lamina_area.body_entered.connect(_ao_tocar)
	_braco.add_child(_lamina_area)


func _circulo(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * float(i) / 10.0
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	return pts


static var _TEX: GradientTexture2D

func _tex_luz() -> GradientTexture2D:
	if _TEX == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		_TEX = GradientTexture2D.new()
		_TEX.gradient = g
		_TEX.width = 128
		_TEX.height = 128
		_TEX.fill = GradientTexture2D.FILL_RADIAL
		_TEX.fill_from = Vector2(0.5, 0.5)
		_TEX.fill_to = Vector2(1.0, 0.5)
	return _TEX


func _physics_process(dt: float) -> void:
	_t += dt
	var w := TAU / maxf(0.3, periodo)
	var ang := deg_to_rad(amplitude_graus) * sin(_t * w)
	if _braco:
		_braco.rotation = ang
	# brilho no ponto mais rapido (a passar pelo fundo)
	var vel := absf(cos(_t * w))
	if _glint:
		_glint.color.a = 0.15 + 0.5 * vel
	if _luz:
		_luz.energy = 0.3 + 1.1 * vel


func _ao_tocar(corpo: Node) -> void:
	if corpo is Koliani:
		var dir := signf(corpo.global_position.x - global_position.x)
		if dir == 0.0:
			dir = 1.0
		corpo.receber_dano(dano, dir)
