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
## Cor do rasto de partículas quando morre.
@export var cor_estilhacos := Color(0.7, 0.25, 0.45)

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
		soltar_estilhacos()
		queue_free()
	else:
		piscar_dano()


## Flash branco curto ao levar dano (feedback de acerto).
func piscar_dano() -> void:
	if _sprite == null:
		return
	_sprite.modulate = Color(2.2, 2.2, 2.2)
	var t := create_tween()
	t.tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)


## Larga um pequeno rebentamento de partículas na posição da morte. O nó
## das partículas fica no pai (o demónio vai ser libertado a seguir) e
## auto-liberta-se quando acaba.
func soltar_estilhacos() -> void:
	var pai := get_parent()
	if pai == null:
		return
	var p := CPUParticles2D.new()
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 16
	p.lifetime = 0.5
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 350)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 240.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.color = cor_estilhacos
	pai.add_child(p)
	p.get_tree().create_timer(1.0).timeout.connect(p.queue_free)
