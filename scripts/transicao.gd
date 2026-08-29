extends CanvasLayer
## Autoload "Transicao": fade a preto entre cenas (morte/reaparecer). Um
## ColorRect por cima de tudo. `fechar_e(acao)` escurece, corre `acao`
## (troca/recarrega a cena) e volta a clarear.

var _rect: ColorRect


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


func fechar_e(acao: Callable, dur := 0.22) -> void:
	var t := create_tween()
	t.tween_property(_rect, "color:a", 1.0, dur)
	t.tween_callback(acao)
	t.tween_property(_rect, "color:a", 0.0, dur)
