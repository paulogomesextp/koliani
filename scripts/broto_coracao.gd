class_name BrotoCoracao
extends Area2D
## Broto do Coracao Putrefacto (N5): alvo de POGO authored. Nao magoa. Cresce em ~0,7 s e so' depois
## e' pogavel (grupo `pogavel`, layer 6). Ressaltar nele (BAIXO+ATAQUE por cima) rebenta-o e avisa o
## Coracao (`estourou`). Se ninguem lhe toca, murcha quando a janela fecha.
## Visual: PLACEHOLDER por poligonos -- APPROVED ART ASSET MISSING (broto).

signal estourou

var _pronto := false
var _corpo := Polygon2D.new()
var _nucleo := Polygon2D.new()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(44.0, 50.0)
	forma.shape = rs
	forma.position = Vector2(0.0, -25.0)
	add_child(forma)
	_corpo.polygon = PackedVector2Array([Vector2(-20, 0), Vector2(-24, -24), Vector2(-12, -46), Vector2(0, -54),
		Vector2(12, -46), Vector2(24, -24), Vector2(20, 0)])
	_corpo.color = Color(0.32, 0.5, 0.24, 1.0)
	add_child(_corpo)
	_nucleo.polygon = PackedVector2Array([Vector2(-7, -30), Vector2(0, -42), Vector2(7, -30), Vector2(0, -20)])
	_nucleo.color = Color(1.0, 0.55, 1.0, 1.0)
	add_child(_nucleo)
	scale = Vector2(0.15, 0.15)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(_amadurecer)


func _amadurecer() -> void:
	_pronto = true
	add_to_group("pogavel")
	set_collision_layer_value(6, true)


func _process(_dt: float) -> void:
	if _pronto:
		# pronto: o nucleo pisca -- "isto e' para bater"
		_nucleo.color = Color(1.0, 0.55, 1.0, 0.6 + 0.4 * sin(Time.get_ticks_msec() / 90.0))


## Chamado pela Koliani quando o ataque descendente (Pogo) acerta aqui.
func pogo_acertado() -> void:
	if not _pronto:
		return
	_pronto = false
	remove_from_group("pogavel")
	set_collision_layer_value(6, false)
	Impacto.rebentar(self, global_position + Vector2(0.0, -30.0), Color(1.0, 0.55, 1.0), 2.0)
	estourou.emit()
	queue_free()


func murchar() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	_pronto = false
	remove_from_group("pogavel")
	set_collision_layer_value(6, false)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(queue_free)
