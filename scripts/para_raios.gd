class_name ParaRaios
extends StaticBody2D
## Pára-raios de metal da Torre da Tempestade (nível 13). Bater-lhe (golpe
## ou projétil da Koliani -- entra por `receber_dano`, está na layer 4)
## ARMA-o por `dur_armado` segundos. Enquanto armado, a próxima descarga
## (`RaioTempestade`) que caísse por perto desvia-se para cá e o pára-raios
## devolve a carga ao chefe mais próximo (grupo "chefes"), dano forte.
## Reutilizável: qualquer nível de tempestade pode usá-lo.

@export var dur_armado := 3.0
@export var dano_no_chefe := 34

var _armado := 0.0

@onready var _ponta: Node2D = get_node_or_null("Ponta")


func _ready() -> void:
	add_to_group("para_raios")


func _process(dt: float) -> void:
	if _armado > 0.0:
		_armado -= dt
		if _ponta:
			_ponta.modulate = Color(0.7, 0.95, 1.0).lerp(Color(1, 1, 1), 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.02))
		if _armado <= 0.0 and _ponta:
			_ponta.modulate = Color(1, 1, 1)


func receber_dano(_quantidade: int = 0, _dir: float = 0.0) -> void:
	_armado = dur_armado


func esta_armado() -> bool:
	return _armado > 0.0


## Chamado pelo `RaioTempestade` quando desvia a descarga para aqui.
func descarregar_no_chefe() -> void:
	_armado = 0.0
	if _ponta:
		_ponta.modulate = Color(1, 1, 1)
	var chefe := _chefe_mais_perto()
	if chefe == null:
		return
	var alvo: Vector2 = (chefe as Node2D).global_position
	var origem := global_position + Vector2(0, -60)
	var bolt := Line2D.new()
	bolt.width = 4.0
	bolt.default_color = Color(0.8, 0.95, 1.0, 0.95)
	var pts := PackedVector2Array()
	for i in 7:
		var f := float(i) / 6.0
		pts.append(origem.lerp(alvo, f) + Vector2(randf_range(-10, 10), randf_range(-10, 10)))
	bolt.points = pts
	get_tree().current_scene.add_child(bolt)
	var t := bolt.create_tween()
	t.tween_property(bolt, "modulate:a", 0.0, 0.35)
	t.tween_callback(bolt.queue_free)
	var dir := signf(alvo.x - origem.x)
	if chefe.has_method("receber_dano_ignorando_guarda"):
		chefe.receber_dano_ignorando_guarda(dano_no_chefe, dir)
	elif chefe.has_method("receber_dano"):
		chefe.receber_dano(dano_no_chefe, dir)
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(5.0)


func _chefe_mais_perto() -> Node:
	var melhor: Node = null
	var d := INF
	for c in get_tree().get_nodes_in_group("chefes"):
		if not is_instance_valid(c):
			continue
		var dd: float = (c as Node2D).global_position.distance_to(global_position)
		if dd < d:
			d = dd
			melhor = c
	return melhor
