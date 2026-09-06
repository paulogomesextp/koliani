extends Node
## Enquadra salas sem teletransportar a personagem nem interromper a física.
## Cada Rect2 delimita uma sala; fora delas a câmara segue normalmente.
@export var salas: Array[Rect2] = []
@export var margem_troca := 24.0
var _sala := -1

func _process(_dt: float) -> void:
	var k := get_tree().get_first_node_in_group("koliani") as Node2D
	if k == null:
		return
	var cam := k.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	var p := k.global_position
	# Pequena histerese evita oscilações quando se salta na fronteira.
	if _sala < 0 or not salas[_sala].grow(margem_troca).has_point(p):
		_sala = -1
		for i in salas.size():
			if salas[i].has_point(p):
				_sala = i
				break
	if _sala < 0:
		cam.position = Vector2.ZERO
		return
	var r := salas[_sala]
	var meia := cam.get_viewport_rect().size / cam.zoom * 0.5
	var centro := r.get_center()
	if r.size.x > meia.x * 2.0:
		centro.x = clampf(p.x, r.position.x + meia.x, r.end.x - meia.x)
	if r.size.y > meia.y * 2.0:
		centro.y = clampf(p.y, r.position.y + meia.y, r.end.y - meia.y)
	cam.global_position = centro
