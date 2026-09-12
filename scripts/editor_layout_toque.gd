extends Control
## EDITOR DE LAYOUT DE TOQUE (Execution 9H). Abre-se em Opções -> EDITAR
## LAYOUT, e só existe onde há toque (telemóvel, tablet, Web/PWA): num PC
## com teclado não serve para nada e não aparece.
##
## Mostra os controlos REAIS (a mesma `ControlosTacteis`, em
## `modo_edicao`) e deixa:
##
##   arrastar     um controlo para onde se quiser
##   − / +        mudar o tamanho do que está selecionado
##   GUARDAR      escreve `user://layout_toque.json`
##   REPOR        volta ao layout de fábrica
##   FECHAR       sai sem gravar
##
## O que NÃO faz: nada disto toca no jogo de PC. O `ControlosTacteis` já só
## existe no telemóvel; o layout é um ficheiro à parte do save e das opções,
## e um ficheiro em falta ou estragado dá o layout de fábrica.
##
## PORQUE É QUE OS CONTROLOS NÃO RESPONDEM AQUI: em `modo_edicao` o
## `_input` deles devolve logo. Se não devolvesse, arrastar o botão de
## Saltar fazia a Koliani saltar por baixo do editor.

signal fechado

const FUNDO := Color(0.035, 0.016, 0.028, 0.88)

var _controlos: ControlosTacteis
var _dedo := -1
var _agarrado := ""
var _dica: Label
var _menos: Button
var _mais: Button
var _guardar: Button
var _repor: Button
var _fechar: Button
var _titulo: Label
var _aviso: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Frontend9H.vestir(self)

	var fundo := ColorRect.new()
	fundo.color = FUNDO
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)

	_controlos = ControlosTacteis.new()
	_controlos.modo_edicao = true
	_controlos.layout = LayoutToque.carregar()
	_controlos.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_controlos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_controlos)

	_titulo = Label.new()
	Frontend9H.cabecalho(_titulo, 26)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_titulo.offset_top = 18.0
	_titulo.offset_bottom = 54.0
	_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_titulo)

	_dica = Label.new()
	Frontend9H.corpo(_dica, 15, Frontend9H.TEXTO_APAGADO)
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dica.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_dica.offset_top = 56.0
	_dica.offset_bottom = 104.0
	_dica.offset_left = 120.0
	_dica.offset_right = -120.0
	_dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dica)

	var barra := HBoxContainer.new()
	barra.add_theme_constant_override("separation", 14)
	barra.alignment = BoxContainer.ALIGNMENT_CENTER
	barra.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	barra.offset_left = -320.0
	barra.offset_right = 320.0
	barra.offset_top = 108.0
	barra.offset_bottom = 156.0
	add_child(barra)

	_menos = _botao(barra, func() -> void: _redimensionar(-0.008))
	_mais = _botao(barra, func() -> void: _redimensionar(0.008))
	_guardar = _botao(barra, _ao_guardar)
	_repor = _botao(barra, _ao_repor)
	_fechar = _botao(barra, _ao_fechar)

	_aviso = Label.new()
	Frontend9H.corpo(_aviso, 15, Frontend9H.VERDE_ESTADO)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_aviso.offset_left = -300.0
	_aviso.offset_right = 300.0
	_aviso.offset_top = 160.0
	_aviso.offset_bottom = 186.0
	_aviso.modulate.a = 0.0
	_aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_aviso)

	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	_traduzir()
	_guardar.grab_focus()


func _botao(pai: Node, ao_premir: Callable) -> Button:
	var b := Button.new()
	Frontend9H.botao_placa(b, 17)
	b.custom_minimum_size = Vector2(0, 46)
	b.pressed.connect(ao_premir)
	pai.add_child(b)
	return b


func _traduzir() -> void:
	_titulo.text = Textos.t("layout.title")
	_dica.text = Textos.t("layout.hint")
	_menos.text = Textos.t("layout.smaller")
	_mais.text = Textos.t("layout.bigger")
	_guardar.text = Textos.t("layout.save")
	_repor.text = Textos.t("layout.reset")
	_fechar.text = Textos.t("layout.close")


# ── arrastar ─────────────────────────────────────────────────────────────

func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch:
		var t := evento as InputEventScreenTouch
		if t.pressed:
			_agarrar(t.index, t.position)
		elif t.index == _dedo:
			_largar()
		accept_event()
	elif evento is InputEventScreenDrag and (evento as InputEventScreenDrag).index == _dedo:
		_arrastar((evento as InputEventScreenDrag).position)
		accept_event()
	elif evento is InputEventMouseButton:
		var m := evento as InputEventMouseButton
		if m.button_index == MOUSE_BUTTON_LEFT:
			if m.pressed:
				_agarrar(-2, m.position)
			else:
				_largar()
			accept_event()
	elif evento is InputEventMouseMotion and _dedo == -2:
		_arrastar((evento as InputEventMouseMotion).position)
		accept_event()


func _agarrar(index: int, pos: Vector2) -> void:
	var qual := _controlos.controlo_em(pos)
	if qual == "":
		return
	_dedo = index
	_agarrado = qual
	_controlos.selecionado = qual
	_controlos.queue_redraw()
	Som.toca("apanhar", -16.0, 1.2)


func _arrastar(pos: Vector2) -> void:
	if _agarrado == "":
		return
	_controlos.mover_controlo(_agarrado, pos)


func _largar() -> void:
	_dedo = -1


func _redimensionar(delta: float) -> void:
	if _controlos.selecionado == "":
		return
	_controlos.redimensionar(_controlos.selecionado, delta)


# ── gravar / repor / fechar ──────────────────────────────────────────────

func _ao_guardar() -> void:
	if LayoutToque.guardar(_controlos.layout_actual()):
		_piscar(Textos.t("layout.saved"))
		Som.toca("porta", -10.0, 1.15)


func _ao_repor() -> void:
	LayoutToque.apagar()
	_controlos.repor_layout()
	_controlos.selecionado = ""
	Som.toca("carrossel", -12.0, 0.9)


func _ao_fechar() -> void:
	fechado.emit()
	queue_free()


func _piscar(txt: String) -> void:
	_aviso.text = txt
	_aviso.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.1)
	t.tween_property(_aviso, "modulate:a", 0.0, 0.5)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_ao_fechar()
