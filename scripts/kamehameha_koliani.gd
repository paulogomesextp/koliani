class_name KamehamehaKoliani
extends Area2D
## Kamehameha roxo da Koliani (habilidade "projetil"). Anda depressa numa
## das 8 direções, ATRAVESSA inimigos (magoa cada um uma só vez) e desfaz-se
## contra o cenário ou ao fim do tempo. Custo/energia gerido em `koliani.gd`.

const VELOCIDADE := 900.0
const TEX_IMPACTO := preload("res://assets/sprites/impacto.svg")

var dano := 75
var _dir := Vector2.RIGHT
var _tempo_de_vida := 1.1
var _t := 0.0
## Inimigos já atingidos, para não bater duas vezes no mesmo.
var _atingidos: Dictionary = {}

@onready var _luz: PointLight2D = $Luz


## `direcao` é um dos 8 vetores; `dano_` vem do `Koliani._dano_kamehameha()`.
func lancar(direcao: Vector2, dano_: int) -> void:
	_dir = direcao.normalized()
	dano = dano_
	rotation = _dir.angle()


func _ready() -> void:
	body_entered.connect(_ao_bater)


func _physics_process(dt: float) -> void:
	global_position += _dir * VELOCIDADE * dt
	_t += dt
	if _luz:
		_luz.energy = 2.7 + 0.6 * sin(_t * 26.0)
	_tempo_de_vida -= dt
	if _tempo_de_vida <= 0.0:
		_estoirar()


func _ao_bater(corpo: Node) -> void:
	if corpo is Koliani:
		return
	if corpo.has_method("receber_dano"):
		# atravessa: magoa e segue em frente (uma vez por inimigo)
		if _atingidos.has(corpo):
			return
		_atingidos[corpo] = true
		corpo.receber_dano(dano, signf(_dir.x) if _dir.x != 0.0 else 0.0)
		Som.toca("acerto", -6.0)
		return
	# cenário -> parte-se
	_estoirar()


func _estoirar() -> void:
	var s := Sprite2D.new()
	s.texture = TEX_IMPACTO
	s.global_position = global_position
	s.rotation = randf() * TAU
	s.scale = Vector2(0.4, 0.4)
	s.modulate = Color(0.8, 0.6, 1.0)
	s.z_index = 40
	var pai := get_parent()
	if pai:
		pai.add_child(s)
		var t := s.create_tween()
		t.set_parallel(true)
		t.tween_property(s, "scale", Vector2(2.2, 2.2), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(s, "modulate:a", 0.0, 0.18)
		t.chain().tween_callback(s.queue_free)
	queue_free()
