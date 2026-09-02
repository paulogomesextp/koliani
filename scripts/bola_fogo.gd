class_name BolaFogo
extends Area2D
## Projétil de fogo -- viaja em linha reta e magoa a Koliani por contacto.
## Cuspido pela `Torreta` (mob de parede que "manda fogo"). Corpo = vórtice
## de fogo a girar (bdragon1727 "Free Effect and Bullet 16x16", folha
## laranja -> `assets/sprites/pixel/fx/bola_fogo.png`) + luz.

const TIRA := preload("res://assets/sprites/pixel/fx/bola_fogo.png")
const FRAMES := 6

@export var velocidade := Vector2(240.0, 0.0)
@export var dano := 16
## Segundos de vida antes de se apagar sozinho.
@export var duracao := 3.2

var _t := 0.0
var _corpo: Sprite2D
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
	_corpo = Sprite2D.new()
	_corpo.texture = TIRA
	_corpo.hframes = FRAMES
	_corpo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_corpo.material = m
	_corpo.scale = Vector2(1.6, 1.6)
	add_child(_corpo)

	_luz = PointLight2D.new()
	_luz.texture = _tex_luz()
	_luz.color = Color(1.0, 0.55, 0.2, 1.0)
	_luz.energy = 1.6
	_luz.scale = Vector2(0.5, 0.5)
	add_child(_luz)


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
	if _corpo:
		_corpo.frame = int(_t * 22.0) % FRAMES
	if _t >= duracao:
		_apagar()


func _ao_tocar(corpo: Node) -> void:
	if corpo is Koliani:
		corpo.receber_dano(dano, signf(velocidade.x if velocidade.x != 0.0 else 1.0))
		_apagar()


func _apagar() -> void:
	set_physics_process(false)
	monitoring = false
	Impacto.rebentar(self, global_position, Color(1.0, 0.6, 0.3), 1.4)
	var t := create_tween()
	t.set_parallel(true)
	if _corpo:
		t.tween_property(_corpo, "scale", Vector2(2.4, 2.4), 0.12)
	t.tween_property(self, "modulate:a", 0.0, 0.12)
	t.chain().tween_callback(queue_free)
