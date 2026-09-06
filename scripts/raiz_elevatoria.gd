extends AnimatableBody2D
## Raiz que sobe com uma passageira e regressa vazia. Usa o terreno do bioma.
@export var tamanho := Vector2(64, 20)
@export var subida := 300.0
@export var velocidade := 80.0
@export var espera_regresso := 1.0
var _origem := Vector2.ZERO
var _espera := 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = false
	_origem = position
	var col := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = tamanho
	col.shape = forma
	add_child(col)
	# Reutiliza a montagem de arte sem deixar um segundo corpo físico.
	var terreno := preload("res://scenes/actors/Plataforma.tscn").instantiate()
	terreno.collision_layer = 0
	terreno.tamanho = tamanho
	terreno.altura_visual = 26.0
	add_child(terreno)
	terreno.get_node("Visual").reparent(self, false)
	terreno.queue_free()

func _physics_process(dt: float) -> void:
	var ocupada := false
	for corpo in get_tree().get_nodes_in_group("koliani"):
		if corpo is CharacterBody2D and corpo.is_on_floor():
			for i in corpo.get_slide_collision_count():
				var contacto: KinematicCollision2D = corpo.get_slide_collision(i)
				if contacto.get_collider() == self and contacto.get_normal().y < -0.7:
					ocupada = true
	if ocupada:
		_espera = espera_regresso
	else:
		_espera = maxf(0.0, _espera - dt)
	var alvo := _origem.y - subida if ocupada or _espera > 0.0 else _origem.y
	position.y = move_toward(position.y, alvo, velocidade * dt)
