extends CanvasLayer
## Game Over do modo hardcore: o tempo do mundo esgotou-se. Pausa a árvore,
## mostra o cartão e -- a um toque em saltar/atacar -- recomeça a campanha
## do mundo 1 (mantém o hardcore ligado). Instanciado pelo
## `relogio_hardcore.gd` quando o relógio chega a zero.

var _t := 0.0
var _pronto := false


func _ready() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS

	var fundo := ColorRect.new()
	fundo.color = Color(0.06, 0.01, 0.02, 0.96)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var texto := Label.new()
	texto.text = "GAME OVER\n\nO tempo esgotou-se.\nA campanha recomeça do início.\n\n(saltar / atacar)"
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto.add_theme_constant_override("line_spacing", 8)
	texto.add_theme_color_override("font_color", Color(1, 0.7, 0.62))
	add_child(texto)

	get_tree().paused = true
	Som.toca("dano", -2.0)


func _process(dt: float) -> void:
	_t += dt
	if not _pronto:
		# pequena folga para ignorar o toque que vinha do jogo
		_pronto = _t >= 0.4
		return
	if Input.is_action_just_pressed("saltar") or Input.is_action_just_pressed("atacar"):
		get_tree().paused = false
		EstadoJogo.reiniciar_campanha()  # não mexe no hardcore -> continua hardcore
		Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file("res://scenes/Main.tscn"))
