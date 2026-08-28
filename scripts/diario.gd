extends CanvasLayer
## Ecrã de diário das pistas. Abre/fecha com a ação `diario` (tecla I /
## Tab, ou o botão do HUD) e pausa o jogo enquanto está aberto. Lista as
## pistas de `EstadoJogo.pistas` com os textos de `DiarioPistas`.

@onready var _lista: VBoxContainer = $Painel/Margem/Coluna/Scroll/Lista
@onready var _contador: Label = $Painel/Margem/Coluna/Cabecalho/Contador


func _ready() -> void:
	visible = false
	# funciona com o jogo em pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	var botao := get_node_or_null("Painel/Margem/Coluna/Cabecalho/Fechar")
	if botao:
		botao.pressed.connect(_fechar)


func _process(_dt: float) -> void:
	# em _process (não em _input) para apanhar também o TouchScreenButton do
	# HUD, que sinaliza a ação sem gerar um InputEvent que propague
	if Input.is_action_just_pressed("diario"):
		_alternar()
	elif visible and Input.is_action_just_pressed("ui_cancel"):
		_fechar()


func _alternar() -> void:
	if visible:
		_fechar()
	else:
		_abrir()


func _abrir() -> void:
	_reconstruir()
	visible = true
	get_tree().paused = true


func _fechar() -> void:
	visible = false
	get_tree().paused = false


func _reconstruir() -> void:
	for filho in _lista.get_children():
		filho.queue_free()

	var entradas := DiarioPistas.entradas(EstadoJogo.pistas)
	_contador.text = "%d / %d pistas" % [entradas.size(), DiarioPistas.total_no_jogo()]

	if entradas.is_empty():
		var vazio := Label.new()
		vazio.text = "Ainda não encontraste nenhuma pista.\nProcura pelos mundos."
		vazio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista.add_child(vazio)
		return

	for e in entradas:
		var titulo := Label.new()
		titulo.text = "%s  —  %s" % [e["titulo"], e["mundo"]]
		titulo.add_theme_color_override("font_color", Color(0.96, 0.7, 0.95))
		_lista.add_child(titulo)

		var corpo := Label.new()
		corpo.text = e["texto"]
		corpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		corpo.add_theme_color_override("font_color", Color(0.86, 0.83, 0.9))
		_lista.add_child(corpo)

		var espaco := Control.new()
		espaco.custom_minimum_size = Vector2(0, 14)
		_lista.add_child(espaco)
