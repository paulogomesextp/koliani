class_name ProjetilZeriko
extends Area2D
## Bola de energia que o Zeriko lança. Anda em linha reta, magoa a Koliani
## ao toque e desfaz-se contra a Koliani, contra o cenário, ou ao fim de
## algum tempo.

@export var velocidade := 300.0
@export var dano := 16

var _dir := Vector2.RIGHT
var _tempo_de_vida := 4.0


func lancar(direcao: Vector2) -> void:
	_dir = direcao.normalized()


func _ready() -> void:
	body_entered.connect(_ao_bater)


func _physics_process(dt: float) -> void:
	global_position += _dir * velocidade * dt
	rotation += dt * 6.0
	_tempo_de_vida -= dt
	if _tempo_de_vida <= 0.0:
		queue_free()


func _ao_bater(corpo: Node) -> void:
	if corpo is Koliani:
		corpo.receber_dano(dano, signf(_dir.x))
	queue_free()
