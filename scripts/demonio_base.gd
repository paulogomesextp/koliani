class_name DemonioBase
extends CharacterBody2D
## Inimigo base: anda de um lado para o outro numa plataforma, vira quando
## bate numa parede ou chega à beira do alcance, e magoa a Koliani por
## contacto (via a Area2D "AreaContacto"). Classe-pai dos demónios
## especificos de cada mundo -- o agente "gaming" herda daqui.

const GRAVIDADE := 1400.0

@export var velocidade := 60.0
@export var vida := 50
@export var dano_contacto := 15
@export var alcance_patrulha := 120.0

@onready var _origem := global_position
@onready var _sprite: Node2D = $Sprite
@onready var _area_contacto: Area2D = $AreaContacto

var _direcao := 1.0


func _ready() -> void:
	if _area_contacto:
		_area_contacto.body_entered.connect(_ao_tocar)


func _physics_process(dt: float) -> void:
	velocity.x = _direcao * velocidade
	if not is_on_floor():
		velocity.y += GRAVIDADE * dt
	move_and_slide()

	if is_on_wall() or absf(global_position.x - _origem.x) > alcance_patrulha:
		_virar()


func _virar() -> void:
	_direcao *= -1.0
	if _sprite:
		_sprite.scale.x = _direcao


func _ao_tocar(corpo: Node) -> void:
	if corpo is Koliani:
		corpo.receber_dano(dano_contacto, signf(corpo.global_position.x - global_position.x))


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	vida -= quantidade
	global_position.x += dir_empurrao * 8.0
	if vida <= 0:
		queue_free()
