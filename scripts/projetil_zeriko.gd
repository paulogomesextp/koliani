class_name ProjetilZeriko
extends Area2D
## Bola de energia que o Zeriko lança. Anda em linha reta, magoa a Koliani
## ao toque e desfaz-se contra a Koliani, contra o cenário, ou ao fim de
## algum tempo.

## Roxo do pack das balas, para o estalo do impacto casar com a bola.
const COR := Color(0.9, 0.42, 1.0)
## Execution 9G: na Região I o corpo é o "projectile" da prancha 07 na paleta
## de CORRUPÇÃO -- o tiro do Coração nunca se confunde com o dela.
const Vfx9G := preload("res://scripts/vfx_regiao1.gd")
var _corpo9g: AnimatedSprite2D

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
	if Vfx9G.ativo(self):
		_corpo9g = Vfx9G.novo("projectile_corrupcao", true)
		if _corpo9g:
			if _corpo:
				_corpo.visible = false
			_corpo9g.z_index = 39
			add_child(_corpo9g)
			_corpo9g.play("ciclo")


func _physics_process(dt: float) -> void:
	global_position += _dir * velocidade * dt
	_t += dt
	if _corpo and _corpo9g == null:
		_corpo.frame = int(_t * 22.0) % 8   # o anel roxo tem 8 frames
	_tempo_de_vida -= dt
	if _tempo_de_vida <= 0.0:
		_estoirar()


func _ao_bater(corpo: Node) -> void:
	if corpo is Koliani:
		corpo.receber_dano(dano, signf(_dir.x))
	_estoirar()


func _estoirar() -> void:
	if Vfx9G.ativo(self):
		Vfx9G.tocar(self, "hit_sparks_corrupcao", global_position, 0.8,
			randf_range(-0.3, 0.3), false, false, 40, 0.2)
		queue_free()
		return
	Impacto.rebentar(self, global_position, COR, 1.8)
	queue_free()
