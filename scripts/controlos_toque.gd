extends CanvasLayer
## HUD de toque para telemóvel. Cada TouchScreenButton do HUD tem uma
## `action` associada no editor (mover_esquerda, mover_direita, saltar,
## atacar, dash, rolar) e o próprio Godot injeta a InputAction -- este
## script só trata de esconder os controlos quando se joga com teclado
## (útil no export Web em desktop para testar).

@onready var _barra_vida: ProgressBar = $Vida/Barra
@onready var _label_vidas: Label = $Vidas/Label


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()
	EstadoJogo.vidas_mudaram.connect(_atualizar_vidas)
	_atualizar_vidas(EstadoJogo.vidas)
	var koliani := get_tree().get_first_node_in_group("koliani")
	if koliani and koliani.has_signal("vida_mudou"):
		koliani.vida_mudou.connect(_atualizar_barra_vida)


func _input(evento: InputEvent) -> void:
	# mostra os botões de toque só quando o dispositivo tem ecrã táctil;
	# se aparecer input de teclado, mantém escondido
	if evento is InputEventScreenTouch and not visible:
		visible = true


func _atualizar_barra_vida(atual: int, maximo: int) -> void:
	if _barra_vida:
		_barra_vida.max_value = maximo
		_barra_vida.value = atual


func _atualizar_vidas(vidas: int) -> void:
	if _label_vidas:
		_label_vidas.text = "x%d" % vidas
