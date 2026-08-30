extends CanvasLayer
## Barra de topo do "DEVELOPER MODE". Só existe quando
## `EstadoJogo.modo_dev` está ligado (o `main.gd` só a instancia nesse
## caso). Mostra um botão "TESTAR OUTRO NÍVEL" no cimo do ecrã; carregar
## abre o carrossel `SeletorNiveis` com todos os níveis da campanha (sem
## respeitar bloqueios) -- escolher um recarrega o jogo nesse nível sem
## tocar no save real.

const CENA_JOGO := "res://scenes/Main.tscn"
const CENA_SELETOR := preload("res://scenes/ui/SeletorNiveis.tscn")

var _painel: Control
var _seletor: SeletorNiveis


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not EstadoJogo.modo_dev:
		queue_free()
		return
	_montar_botao_topo()
	_montar_painel()
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	_traduzir()


func _montar_botao_topo() -> void:
	var b := Button.new()
	b.name = "BotaoTopo"
	b.set_anchors_preset(Control.PRESET_CENTER_TOP)
	b.position = Vector2(-110, 6)
	b.custom_minimum_size = Vector2(220, 30)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.04, 0.11, 0.9)
	sb.border_color = Color(0.95, 0.7, 0.3, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", sb)
	b.pressed.connect(_abrir)
	add_child(b)


func _montar_painel() -> void:
	_painel = Control.new()
	_painel.name = "Painel"
	_painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_painel.visible = false
	add_child(_painel)

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.02, 0.01, 0.03, 0.9)
	_painel.add_child(fundo)

	var titulo := Label.new()
	titulo.name = "Titulo"
	titulo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	titulo.position = Vector2(-200, 26)
	titulo.custom_minimum_size = Vector2(400, 0)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	_painel.add_child(titulo)

	_seletor = CENA_SELETOR.instantiate()
	_painel.add_child(_seletor)
	_seletor.escolhido.connect(_ir_para)
	_seletor.cancelado.connect(_fechar)


func _traduzir() -> void:
	var bt := get_node_or_null("BotaoTopo") as Button
	if bt:
		bt.text = Textos.t("dev.test_level")
	if _painel:
		var titulo := _painel.find_child("Titulo", true, false) as Label
		if titulo:
			titulo.text = Textos.t("dev.title")


func _abrir() -> void:
	if _painel:
		_painel.visible = true
	if _seletor:
		_seletor.configurar(EstadoJogo.indice_nivel, false)
	get_tree().paused = true


func _fechar() -> void:
	if _painel:
		_painel.visible = false
	get_tree().paused = false


func _ir_para(i: int) -> void:
	get_tree().paused = false
	EstadoJogo.indice_nivel = clampi(i, 0, EstadoJogo.NIVEIS.size() - 1)
	EstadoJogo.checkpoint = Vector2.ZERO
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_JOGO))
