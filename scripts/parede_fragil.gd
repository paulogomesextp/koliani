class_name ParedeFragil
extends StaticBody2D
## Parede rachada que só se parte quando a Koliani lhe dá um golpe E já tem
## a habilidade permanente "partir_paredes". Sem a habilidade é uma parede
## normal (bloqueia na layer `mundo`). Costuma esconder um `Coletavel`.

signal partida

@onready var _detetor: Area2D = $Detetor


func _process(_dt: float) -> void:
	if not EstadoJogo.tem_habilidade("partir_paredes"):
		return
	if _detetor == null:
		return
	for a in _detetor.get_overlapping_areas():
		# a HitboxAtaque da Koliani só tem monitoring ligado durante o golpe
		if a.name == "HitboxAtaque" and a.monitoring and a.get_parent() is Koliani:
			_partir()
			return


func _partir() -> void:
	partida.emit()
	var pai := get_parent()
	if pai:
		var p := CPUParticles2D.new()
		p.global_position = global_position
		p.emitting = true
		p.one_shot = true
		p.explosiveness = 1.0
		p.amount = 22
		p.lifetime = 0.6
		p.spread = 180.0
		p.gravity = Vector2(0, 500)
		p.initial_velocity_min = 40.0
		p.initial_velocity_max = 260.0
		p.scale_amount_min = 2.0
		p.scale_amount_max = 4.0
		p.color = Color(0.5, 0.5, 0.55)
		pai.add_child(p)
		p.get_tree().create_timer(1.2).timeout.connect(p.queue_free)
	queue_free()
