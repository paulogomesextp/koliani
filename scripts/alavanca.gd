class_name Alavanca
extends Area2D
## Alavanca de parede/chão. A Koliani toca -> muda de estado e avisa as
## `PortaTrancada` com o mesmo `id`. Visual construído em código (base +
## manípulo que baloiça de baixo para cima).
##
## `so_liga = true` -> uma vez ligada não volta a desligar (interruptor de
## um só sentido). Grupo "alavancas".

signal mudou(ligada: bool)

## Liga esta alavanca à(s) `PortaTrancada` com o mesmo id.
@export var id := "porta_a"
## Interruptor de um só sentido (não se pode voltar a desligar).
@export var so_liga := false
## Começa já ligada.
@export var ligada := false

const COR_OFF := Color(0.55, 0.5, 0.4)
const COR_ON := Color(0.5, 1.0, 0.7)

var _cooldown := 0.0
var _manipulo: Polygon2D
var _luz: PointLight2D
var _t := 0.0


func _ready() -> void:
	add_to_group("alavancas")
	body_entered.connect(_ao_tocar)
	_montar_visual()
	_aplicar(true)


func _montar_visual() -> void:
	# poste / base
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([Vector2(-4, 14), Vector2(4, 14), Vector2(4, 2), Vector2(-4, 2)])
	base.color = Color(0.2, 0.18, 0.16)
	add_child(base)
	var suporte := Polygon2D.new()
	suporte.polygon = PackedVector2Array([Vector2(-9, 16), Vector2(9, 16), Vector2(7, 14), Vector2(-7, 14)])
	suporte.color = Color(0.12, 0.11, 0.1)
	add_child(suporte)

	_manipulo = Polygon2D.new()
	_manipulo.polygon = PackedVector2Array([Vector2(-2, 2), Vector2(2, 2), Vector2(2, -18), Vector2(-2, -18)])
	_manipulo.color = COR_OFF
	add_child(_manipulo)
	var punho := Polygon2D.new()
	punho.polygon = PackedVector2Array([Vector2(-5, -22), Vector2(5, -22), Vector2(5, -16), Vector2(-5, -16)])
	punho.color = Color(0.75, 0.2, 0.2)
	_manipulo.add_child(punho)

	_luz = PointLight2D.new()
	_luz.texture = _tex_luz()
	_luz.color = COR_ON
	_luz.energy = 0.0
	_luz.scale = Vector2(0.5, 0.5)
	add_child(_luz)


func _tex_luz() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 140
	t.height = 140
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


func _process(dt: float) -> void:
	_cooldown = maxf(0.0, _cooldown - dt)
	if ligada and _luz:
		_t += dt
		_luz.energy = 0.9 + 0.25 * sin(_t * 5.0)


func _ao_tocar(corpo: Node) -> void:
	if not (corpo is Koliani) or _cooldown > 0.0:
		return
	if ligada and so_liga:
		return
	_cooldown = 0.6
	ligada = not ligada
	Som.toca("selo", -10.0, 1.15 if ligada else 0.85)
	_aplicar(false)
	mudou.emit(ligada)


func _aplicar(instantaneo: bool) -> void:
	if _manipulo == null:
		return
	var ang := deg_to_rad(-32.0) if ligada else deg_to_rad(32.0)
	var cor := COR_ON if ligada else COR_OFF
	var e := 1.0 if ligada else 0.0
	if instantaneo:
		_manipulo.rotation = ang
		_manipulo.color = cor
		if _luz:
			_luz.energy = e
		return
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_manipulo, "rotation", ang, 0.18)
	tw.parallel().tween_property(_manipulo, "color", cor, 0.18)
	if _luz:
		tw.parallel().tween_property(_luz, "energy", e, 0.2)
