extends CanvasLayer
## Autoload "Transicao": fade a preto entre cenas (morte/reaparecer). Um
## ColorRect por cima de tudo. `fechar_e(acao)` escurece, corre `acao`
## (troca/recarrega a cena) e volta a clarear.

var _rect: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


func fechar_e(acao: Callable, dur := 0.22) -> void:
	# já há uma transição a decorrer -> ignora (a acção dela trata do
	# recarregar/trocar de cena). Sem isto, mortes rápidas empilhavam tweens
	# no mesmo ColorRect e ele ficava preso a preto.
	if _tween and _tween.is_valid():
		return
	_tween = create_tween()
	_tween.tween_property(_rect, "color:a", 1.0, dur)
	_tween.tween_callback(acao)
	_tween.tween_property(_rect, "color:a", 0.0, dur)
