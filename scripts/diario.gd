extends CanvasLayer
## Ecrã de diário das pistas. Abre/fecha com a ação `diario` (tecla I /
## Tab, ou o botão do HUD) e pausa o jogo enquanto está aberto. Lista as
## pistas de `EstadoJogo.pistas` com os textos de `DiarioPistas`.

@onready var _lista: VBoxContainer = $Painel/Margem/Coluna/Scroll/Lista
@onready var _contador: Label = $Painel/Margem/Coluna/Cabecalho/Contador
@onready var _titulo: Label = $Painel/Margem/Coluna/Cabecalho/Titulo
@onready var _fechar_btn: Button = $Painel/Margem/Coluna/Cabecalho/Fechar


func _ready() -> void:
	visible = false
	# funciona com o jogo em pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _fechar_btn:
		_fechar_btn.pressed.connect(_fechar)
		_fechar_btn.resized.connect(func() -> void: _fechar_btn.pivot_offset = _fechar_btn.size / 2.0)
		_fechar_btn.mouse_entered.connect(func() -> void: _animar_escala(_fechar_btn, 1.05))
		_fechar_btn.mouse_exited.connect(func() -> void: _animar_escala(_fechar_btn, 1.0))
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	_traduzir()


func _animar_escala(botao: Button, alvo: float) -> void:
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(botao, "scale", Vector2(alvo, alvo), 0.16)


func _traduzir() -> void:
	if _titulo:
		_titulo.text = Textos.t("journal.title")
	if _fechar_btn:
		_fechar_btn.text = Textos.t("journal.close")
	if visible:
		_reconstruir()


var _cd := 0.0


func _process(dt: float) -> void:
	# em _process (não em _input) para apanhar também o TouchScreenButton do
	# HUD, que sinaliza a ação sem gerar um InputEvent que propague
	_cd = maxf(0.0, _cd - dt)
	if _cd > 0.0:
		return
	if Input.is_action_just_pressed("diario"):
		_alternar()
	elif visible and Input.is_action_just_pressed("ui_cancel"):
		_fechar()


func _alternar() -> void:
	if visible:
		_fechar()
	elif not get_tree().paused:
		# não abrir por cima de outra coisa que já segura a pausa (menu de pausa)
		_abrir()


func _abrir() -> void:
	_cd = 0.35
	_reconstruir()
	visible = true
	get_tree().paused = true


func _fechar() -> void:
	_cd = 0.35
	visible = false
	get_tree().paused = false


func _reconstruir() -> void:
	for filho in _lista.get_children():
		filho.queue_free()

	var entradas := DiarioPistas.entradas(EstadoJogo.pistas)
	_contador.text = Textos.tf("journal.counter", [entradas.size(), DiarioPistas.total_no_jogo()])

	if entradas.is_empty():
		var vazio := Label.new()
		vazio.text = Textos.t("journal.empty")
		vazio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista.add_child(vazio)
		return

	for e in entradas:
		var chave_titulo: String = e["titulo"]
		var texto_titulo := Textos.t(chave_titulo) if chave_titulo.begins_with("clue.") else chave_titulo
		var chave_corpo: String = e["texto"]
		var texto_corpo := Textos.t(chave_corpo) if chave_corpo != "" else Textos.t("journal.unwritten")

		var titulo := Label.new()
		titulo.text = "%s  —  %s" % [texto_titulo, Textos.t(e["mundo"])]
		titulo.add_theme_color_override("font_color", Color(0.96, 0.7, 0.95))
		_lista.add_child(titulo)

		var corpo := Label.new()
		corpo.text = texto_corpo
		corpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		corpo.add_theme_color_override("font_color", Color(0.86, 0.83, 0.9))
		_lista.add_child(corpo)

		var espaco := Control.new()
		espaco.custom_minimum_size = Vector2(0, 14)
		_lista.add_child(espaco)
