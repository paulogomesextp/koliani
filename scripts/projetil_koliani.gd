class_name ProjetilKoliani
extends Area2D
## Projétil mágico da Koliani (habilidade "projetil"). Anda em linha reta
## numa das 8 direções, magoa inimigos com o mesmo dano do ataque corpo a
## corpo, e desfaz-se contra inimigos, contra o cenário, ou ao fim de algum
## tempo. Custo/energia é gerido em `koliani.gd`.

const VELOCIDADE := 540.0
const TEX_IMPACTO := preload("res://assets/sprites/impacto.svg")

var dano := 25
var _dir := Vector2.RIGHT
var _tempo_de_vida := 2.2


## `direcao` é um dos 8 vetores (cima/baixo/lados/diagonais); `dano_` vem
## do `Koliani.DANO_ATAQUE` para o projétil bater igual à espada.
func lancar(direcao: Vector2, dano_: int) -> void:
	_dir = direcao.normalized()
	dano = dano_
	rotation = _dir.angle()


func _ready() -> void:
	body_entered.connect(_ao_bater)


func _physics_process(dt: float) -> void:
	global_position += _dir * VELOCIDADE * dt
	_tempo_de_vida -= dt
	if _tempo_de_vida <= 0.0:
		queue_free()


func _ao_bater(corpo: Node) -> void:
	if corpo.has_method("receber_dano") and not (corpo is Koliani):
		corpo.receber_dano(dano, signf(_dir.x) if _dir.x != 0.0 else 0.0)
		Som.toca("acerto", -9.0)
	_estoirar()


func _estoirar() -> void:
	var s := Sprite2D.new()
	s.texture = TEX_IMPACTO
	s.global_position = global_position
	s.rotation = randf() * TAU
	s.scale = Vector2(0.22, 0.22)
	s.z_index = 40
	var pai := get_parent()
	if pai:
		pai.add_child(s)
		var t := s.create_tween()
		t.set_parallel(true)
		t.tween_property(s, "scale", Vector2(1.05, 1.05), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(s, "modulate:a", 0.0, 0.14)
		t.chain().tween_callback(s.queue_free)
	queue_free()
