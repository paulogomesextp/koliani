class_name ProjetilZeriko
extends Area2D
## Bola de energia que o Zeriko lança. Anda em linha reta, magoa a Koliani
## ao toque e desfaz-se contra a Koliani, contra o cenário, ou ao fim de
## algum tempo.

## Roxo do pack das balas, para o estalo do impacto casar com a bola.
const COR := Color(0.9, 0.42, 1.0)

@export var velocidade := 300.0
@export var dano := 16

var _dir := Vector2.RIGHT
var _tempo_de_vida := 4.0
var _t := 0.0

@onready var _corpo: Sprite2D = $Corpo


func lancar(direcao: Vector2) -> void:
	_dir = direcao.normalized()


func _ready() -> void:
	body_entered.connect(_ao_bater)


func _physics_process(dt: float) -> void:
	global_position += _dir * velocidade * dt
	_t += dt
	if _corpo:
		_corpo.frame = int(_t * 22.0) % 8   # o anel roxo tem 8 frames
	_tempo_de_vida -= dt
	if _tempo_de_vida <= 0.0:
		_estoirar()


func _ao_bater(corpo: Node) -> void:
	if corpo is Koliani:
		corpo.receber_dano(dano, signf(_dir.x))
	_estoirar()


func _estoirar() -> void:
	Impacto.rebentar(self, global_position, COR, 1.8)
	queue_free()
