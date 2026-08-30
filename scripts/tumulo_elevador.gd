class_name TumuloElevador
extends AnimatableBody2D
## Laje de túmulo que funciona como elevador (Região IV / nível 16 --
## Cemitério dos Reis). `AnimatableBody2D` com `sync_to_physics` -> carrega
## a Koliani. Sobe (percorre `curso`) enquanto ela está em cima e volta ao
## sítio quando ela sai. `auto = true` = vaivém contínuo entre os dois
## extremos (elevador de mão dupla). Grupo "tumulos".

## Deslocamento total a partir da base (px). Negativo em y = sobe.
@export var curso := Vector2(0.0, -200.0)
@export var velocidade := 90.0
## true = anda sempre entre base e base+curso; false = só com peso em cima.
@export var auto := false
@export var largura := 150.0 : set = _set_largura

var _base := Vector2.ZERO
var _dir := 1.0        # 1 = a ir para base+curso ; -1 = a voltar
var _peso := 0

@onready var _forma: CollisionShape2D = $Col
@onready var _visual: Polygon2D = $Visual
@onready var _deteta: Area2D = $Deteta


func _ready() -> void:
	add_to_group("tumulos")
	sync_to_physics = true
	_base = global_position
	_reconstruir()
	_deteta.body_entered.connect(func(c: Node) -> void:
		if c is Koliani:
			_peso += 1)
	_deteta.body_exited.connect(func(c: Node) -> void:
		if c is Koliani:
			_peso = maxi(0, _peso - 1))


func _physics_process(dt: float) -> void:
	var alvo: Vector2
	if auto:
		if global_position.distance_to(_base) < 2.0:
			_dir = 1.0
		elif global_position.distance_to(_base + curso) < 2.0:
			_dir = -1.0
		alvo = (_base + curso) if _dir > 0.0 else _base
	else:
		alvo = (_base + curso) if _peso > 0 else _base
	global_position = global_position.move_toward(alvo, velocidade * dt)


func _set_largura(v: float) -> void:
	largura = maxf(48.0, v)
	if is_node_ready():
		_reconstruir()


func _reconstruir() -> void:
	if _forma == null or _visual == null or _deteta == null:
		return
	var hw := largura * 0.5
	var r := RectangleShape2D.new()
	r.size = Vector2(largura, 26.0)
	_forma.shape = r
	_forma.position = Vector2(0.0, 5.0)
	_visual.polygon = PackedVector2Array([
		Vector2(-hw, -12), Vector2(hw, -12),
		Vector2(hw - 6, 18), Vector2(-hw + 6, 18),
	])
	var d := _deteta.get_node_or_null("Forma") as CollisionShape2D
	if d:
		var dr := RectangleShape2D.new()
		dr.size = Vector2(largura - 12.0, 20.0)
		d.shape = dr
		d.position = Vector2(0.0, -18.0)
