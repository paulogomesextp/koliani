class_name BolaFogo
extends Area2D
## Projétil de fogo -- viaja em linha reta e magoa a Koliani por contacto.
## Cuspido pela `Torreta` (mob de parede que "manda fogo"). Visual todo em
## código: núcleo branco-quente + halo laranja + luz + rasto curto.

@export var velocidade := Vector2(240.0, 0.0)
@export var dano := 16
## Segundos de vida antes de se apagar sozinho.
@export var duracao := 3.2

var _t := 0.0
var _nucleo: Polygon2D
var _halo: Polygon2D
var _luz: PointLight2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # só a Koliani
	body_entered.connect(_ao_tocar)
	var cs := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 6.0
	cs.shape = forma
	add_child(cs)
	_montar_visual()


func _montar_visual() -> void:
	_halo = Polygon2D.new()
	_halo.polygon = _circulo(9.0)
	_halo.color = Color(1.0, 0.5, 0.15, 0.5)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_halo.material = m
	add_child(_halo)

	_nucleo = Polygon2D.new()
	_nucleo.polygon = _circulo(4.5)
	_nucleo.color = Color(1.0, 0.92, 0.7, 1.0)
	add_child(_nucleo)

	_luz = PointLight2D.new()
	_luz.texture = _tex_luz()
	_luz.color = Color(1.0, 0.55, 0.2, 1.0)
	_luz.energy = 1.6
	_luz.scale = Vector2(0.5, 0.5)
	add_child(_luz)


func _circulo(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * float(i) / 12.0
		pts.append(Vector2(cos(a), sin(a)) * r)
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
	position += velocidade * dt
	_t += dt
	if _nucleo:
		var p := 0.85 + 0.15 * sin(_t * 40.0)
		_nucleo.scale = Vector2(p, p)
	if _t >= duracao:
		_apagar()


func _ao_tocar(corpo: Node) -> void:
	if corpo is Koliani:
		corpo.receber_dano(dano, signf(velocidade.x if velocidade.x != 0.0 else 1.0))
		_apagar()


func _apagar() -> void:
	set_physics_process(false)
	monitoring = false
	var t := create_tween()
	t.set_parallel(true)
	if _nucleo:
		t.tween_property(_nucleo, "scale", Vector2(2.2, 2.2), 0.12)
	t.tween_property(self, "modulate:a", 0.0, 0.12)
	t.chain().tween_callback(queue_free)
