class_name Espelho
extends StaticBody2D
## Espelho do Salão dos Espelhos (Região VI / nível 27). Inteiro bloqueia
## a passagem (layer "mundo"). Um golpe/projétil da Koliani (entra por
## `receber_dano`; está também na layer 4) parte-o: deixa de bloquear e
## SOLTA um reflexo -- uma sombra da Koliani (DemonioBase recolorido) que
## anda até ela. Uma vez.

const REFLEXO := preload("res://scenes/actors/DemonioBase.tscn")

@export var vida_reflexo := 26
@export var dano_reflexo := 14

var _partido := false

@onready var _corpo: CanvasItem = get_node_or_null("Corpo")
@onready var _col: CollisionShape2D = get_node_or_null("Col")


func _ready() -> void:
	add_to_group("espelhos")


func receber_dano(_quantidade: int = 0, _dir: float = 0.0) -> void:
	if _partido:
		return
	_partido = true
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(4.0)
	var p := CPUParticles2D.new()
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 24
	p.lifetime = 0.7
	p.spread = 180.0
	p.gravity = Vector2(0, 600)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 260.0
	p.color = Color(0.7, 0.5, 1.0)
	add_child(p)
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)
	if _col:
		_col.set_deferred("disabled", true)
	if _corpo:
		create_tween().tween_property(_corpo, "modulate:a", 0.12, 0.25)
	_soltar_reflexo()


func _soltar_reflexo() -> void:
	var pai := get_parent()
	if pai == null:
		return
	var r := REFLEXO.instantiate()
	r.especie = "esqueleto"
	r.vida = vida_reflexo
	r.dano_contacto = dano_reflexo
	r.velocidade = 96.0
	r.alcance_patrulha = 400.0
	r.cor_estilhacos = Color(0.55, 0.4, 0.85)
	r.cor_rim = Color(0.7, 0.5, 1.0)
	r.global_position = global_position + Vector2(0, 30)
	pai.add_child(r)
	if r.has_node("Sprite"):
		(r.get_node("Sprite") as CanvasItem).modulate = Color(0.55, 0.4, 0.9, 0.92)
	r.get_tree().create_timer(14.0).timeout.connect(func() -> void:
		if is_instance_valid(r) and not r._morto:
			r.soltar_estilhacos()
			r.queue_free())
