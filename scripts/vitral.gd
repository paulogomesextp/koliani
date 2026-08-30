class_name Vitral
extends StaticBody2D
## Vitral da Catedral da Corrupção (Região V / nível 24). Enquanto inteiro
## é uma parede colorida que bloqueia (layer "mundo"). Um golpe ou projétil
## da Koliani (entra por `receber_dano`, também está na layer 4) parte-o:
## a luz passa a entrar, as plataformas do grupo `grupo_luz` (que começam
## fantasma) ficam sólidas, e o vitral deixa de bloquear.
## Mudança de iluminação de uma vez -- não volta atrás.

@export var grupo_luz := "vitral_luz"
@export var cor_luz := Color(0.7, 0.4, 1.0)

var _partido := false

@onready var _corpo: CanvasItem = get_node_or_null("Corpo")
@onready var _col: CollisionShape2D = get_node_or_null("Col")
@onready var _luz: PointLight2D = get_node_or_null("Luz")


func _ready() -> void:
	add_to_group("vitrais")
	if _luz:
		_luz.energy = 0.0


func receber_dano(_quantidade: int = 0, _dir: float = 0.0) -> void:
	if _partido:
		return
	_partido = true
	Som.toca("onda", -6.0, 1.6)
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(4.0)
	# estilhaços
	var p := CPUParticles2D.new()
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 26
	p.lifetime = 0.7
	p.spread = 180.0
	p.gravity = Vector2(0, 600)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 260.0
	p.color = cor_luz
	add_child(p)
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)
	# a parede deixa de bloquear e some
	if _col:
		_col.set_deferred("disabled", true)
	if _corpo:
		create_tween().tween_property(_corpo, "modulate:a", 0.12, 0.25)
	# a luz passa a entrar
	if _luz:
		create_tween().tween_property(_luz, "energy", 1.1, 0.3)
	# as plataformas fantasma ficam sólidas
	for pl in get_tree().get_nodes_in_group(grupo_luz):
		if not is_instance_valid(pl):
			continue
		var c := pl.get_node_or_null("Col") as CollisionShape2D
		if c:
			c.set_deferred("disabled", false)
		var vis := pl.get_node_or_null("Visual") as CanvasItem
		if vis:
			create_tween().tween_property(vis, "modulate:a", 1.0, 0.2)
