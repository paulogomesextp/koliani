extends CanvasLayer
## HUD: barra de vida + vidas (sempre visíveis) e os botões de toque
## (`Toque`), que só aparecem em ecrã táctil / ao primeiro toque -- assim
## no desktop joga-se com teclado sem os botões por cima.

@onready var _barra_vida: ProgressBar = $Vida/Barra
@onready var _label_vidas: Label = $Vidas/Label
@onready var _toque: Control = $Toque


func _ready() -> void:
	if _toque:
		_toque.visible = DisplayServer.is_touchscreen_available()
	EstadoJogo.vidas_mudaram.connect(_atualizar_vidas)
	_atualizar_vidas(EstadoJogo.vidas)
	var koliani := get_tree().get_first_node_in_group("koliani")
	if koliani and koliani.has_signal("vida_mudou"):
		koliani.vida_mudou.connect(_atualizar_barra_vida)


func _input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch and _toque and not _toque.visible:
		_toque.visible = true


func _atualizar_barra_vida(atual: int, maximo: int) -> void:
	if _barra_vida:
		_barra_vida.max_value = maximo
		_barra_vida.value = atual


func _atualizar_vidas(vidas: int) -> void:
	if _label_vidas:
		_label_vidas.text = "x%d" % vidas
