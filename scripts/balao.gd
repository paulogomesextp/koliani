class_name Balao
extends CanvasLayer
## Balão de fala moderno para as cenas de história (chefes que falam). Caixa
## arredondada com cauda a apontar ao orador, nome de quem fala, revelação
## do texto letra a letra (typewriter) e indicador de "toca para continuar".
##
## Não instanciar à mão -- passar por `Dialogo.correr(falas)`
## (`await Dialogo.correr(...)`). Cada "fala" é um dicionário
## `{ "quem": <chave i18n>, "texto": <chave i18n> }`. Opcionalmente
## `{ "alvo": Node2D }` para a cauda apontar a esse nó do mundo.

signal terminado

const LARGURA := 560.0
const VEL_LETRAS := 46.0            # caracteres por segundo
const MARGEM_BAIXO := 70.0

var _falas: Array = []
var _i := 0
var _texto_alvo := ""
var _revelado := 0.0
var _a_escrever := false
var _pausar := true

var _painel: PanelContainer
var _nome: Label
var _corpo: RichTextLabel
var _dica: Label
var _cauda: Polygon2D
var _raiz: Control
var _alvo: Node2D


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()
	set_process(false)
	visible = false


## Corre a sequência de falas. `await` até ao fim. `pausar` = congela a
## árvore enquanto o balão está no ecrã (o balão corre à parte).
func reproduzir(falas: Array, pausar := true) -> void:
	_falas = falas
	_pausar = pausar
	if _falas.is_empty():
		terminado.emit()
		queue_free()
		return
	if _pausar:
		get_tree().paused = true
	visible = true
	set_process(true)
	_i = -1
	_avancar()
	await terminado
	if _pausar:
		get_tree().paused = false


# --- construção -------------------------------------------------------

func _montar() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.gui_input.connect(_ao_toque)
	add_child(_raiz)

	var sombra := ColorRect.new()
	sombra.set_anchors_preset(Control.PRESET_FULL_RECT)
	sombra.color = Color(0.02, 0.01, 0.03, 0.35)
	_raiz.add_child(sombra)

	_cauda = Polygon2D.new()
	_cauda.color = Color(0.12, 0.09, 0.17, 0.98)
	_raiz.add_child(_cauda)

	_painel = PanelContainer.new()
	_painel.anchor_left = 0.5
	_painel.anchor_right = 0.5
	_painel.anchor_top = 1.0
	_painel.anchor_bottom = 1.0
	_painel.offset_left = -LARGURA * 0.5
	_painel.offset_right = LARGURA * 0.5
	_painel.offset_top = -196.0 - MARGEM_BAIXO
	_painel.offset_bottom = -MARGEM_BAIXO
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.09, 0.17, 0.98)
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(3)
	sb.border_color = Color(0.86, 0.4, 0.82, 0.95)
	sb.shadow_color = Color(0.6, 0.2, 0.7, 0.35)
	sb.shadow_size = 16
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	_painel.add_theme_stylebox_override("panel", sb)
	_raiz.add_child(_painel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_painel.add_child(col)

	_nome = Label.new()
	_nome.add_theme_font_size_override("font_size", 18)
	_nome.add_theme_color_override("font_color", Color(1, 0.72, 0.95))
	col.add_child(_nome)

	var risca := HSeparator.new()
	col.add_child(risca)

	_corpo = RichTextLabel.new()
	_corpo.bbcode_enabled = true
	_corpo.fit_content = true
	_corpo.scroll_active = false
	_corpo.custom_minimum_size = Vector2(LARGURA - 44, 96)
	_corpo.add_theme_font_size_override("normal_font_size", 19)
	_corpo.add_theme_color_override("default_color", Color(0.96, 0.93, 1))
	col.add_child(_corpo)

	_dica = Label.new()
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dica.add_theme_font_size_override("font_size", 13)
	_dica.add_theme_color_override("font_color", Color(0.75, 0.6, 0.85, 0.8))
	col.add_child(_dica)


# --- sequência -------------------------------------------------------

func _avancar() -> void:
	_i += 1
	if _i >= _falas.size():
		set_process(false)
		visible = false
		terminado.emit()
		queue_free()
		return
	var fala: Dictionary = _falas[_i]
	_alvo = fala.get("alvo", null)
	_nome.text = Textos.t(fala.get("quem", "")).to_upper()
	_texto_alvo = Textos.t(fala.get("texto", ""))
	_revelado = 0.0
	_a_escrever = true
	_corpo.text = ""
	_dica.text = ""
	Som.toca("apanhar", -20.0, 1.4)


func _process(dt: float) -> void:
	if _a_escrever:
		_revelado = minf(_revelado + VEL_LETRAS * dt, float(_texto_alvo.length()))
		_corpo.text = _texto_alvo.substr(0, int(_revelado))
		if int(_revelado) >= _texto_alvo.length():
			_a_escrever = false
			_dica.text = Textos.t("dlg.tap")
	# pulsa a dica
	if not _a_escrever:
		_dica.modulate.a = 0.55 + 0.35 * sin(Time.get_ticks_msec() * 0.006)
	_atualizar_cauda()


func _atualizar_cauda() -> void:
	var topo_painel := _painel.global_position + Vector2(_painel.size.x * 0.5, _painel.size.y)
	var base := Vector2(get_viewport().get_visible_rect().size.x * 0.5, topo_painel.y)
	var ponta := base + Vector2(0, 34)
	if is_instance_valid(_alvo):
		var cam := _alvo.get_viewport().get_camera_2d()
		if cam:
			var p := _alvo.get_global_transform_with_canvas().origin
			ponta = Vector2(clampf(p.x, base.x - 120.0, base.x + 120.0), base.y + 30.0)
	_cauda.polygon = PackedVector2Array([
		base + Vector2(-22, -2), base + Vector2(22, -2), ponta,
	])


func _ao_toque(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		_passo()


func _input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento.is_action_pressed("saltar") or evento.is_action_pressed("atacar") or evento.is_action_pressed("ui_accept"):
		_passo()
		get_viewport().set_input_as_handled()


func _passo() -> void:
	if _a_escrever:
		_revelado = float(_texto_alvo.length())   # revela já a linha toda
	else:
		_avancar()
