class_name ParedeMovel
extends AnimatableBody2D
## Parede que desliza de um lado ao outro num ciclo (Templo da Serpente,
## Região IV / nível 19 -- "paredes móveis e passagens secretas").
## `AnimatableBody2D` com `sync_to_physics` -> empurra/carrega a Koliani.
## Bloqueia na layer "mundo". `curso` = deslocamento total; `periodo` =
## segundos de ida-e-volta; `fase` = desfasamento inicial (0..1).

@export var tamanho := Vector2(28.0, 180.0) : set = _set_tamanho
@export var curso := Vector2(180.0, 0.0)
@export var periodo := 3.0
@export var fase := 0.0

var _base := Vector2.ZERO
var _t := 0.0

@onready var _col: CollisionShape2D = $Col
@onready var _vis: ColorRect = $Visual


func _ready() -> void:
	add_to_group("paredes_moveis")
	sync_to_physics = true
	_base = global_position
	_t = fase * periodo
	_aplicar_tamanho()


func _physics_process(dt: float) -> void:
	_t += dt
	var f := 0.5 - 0.5 * cos(_t * TAU / maxf(0.2, periodo))
	global_position = _base + curso * f


func _set_tamanho(v: Vector2) -> void:
	tamanho = v
	if is_node_ready():
		_aplicar_tamanho()


func _aplicar_tamanho() -> void:
	if _col:
		var r := RectangleShape2D.new()
		r.size = tamanho
		_col.shape = r
	if _vis:
		_vis.offset_left = -tamanho.x * 0.5
		_vis.offset_right = tamanho.x * 0.5
		_vis.offset_top = -tamanho.y * 0.5
		_vis.offset_bottom = tamanho.y * 0.5
