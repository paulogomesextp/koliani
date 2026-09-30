class_name ShopItemCard
extends Button
## Cartão puramente visual da Loja. Recebe dados já resolvidos pela Loja e
## emite apenas o id escolhido; não conhece preços, saves nem ownership.

signal item_ativado(id: String)

var item_id := ""
var _raridade := "comum"
var _estado := "disponivel"
var _selecionado := false
var _preview: TextureRect
var _placeholder: Label
var _nome: Label
var _raridade_label: Label
var _estado_label: Label
var _tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(150, 158)
	clip_contents = false
	text = ""
	toggle_mode = true
	ShopTheme.vestir_botao(self, ShopTheme.CARMESIM, 13)
	_montar()
	pressed.connect(func() -> void: item_ativado.emit(item_id))
	mouse_entered.connect(_animar.bind(true))
	mouse_exited.connect(_animar.bind(false))
	focus_entered.connect(_animar.bind(true))
	focus_exited.connect(_animar.bind(false))
	resized.connect(func() -> void: pivot_offset = size * 0.5)


func _montar() -> void:
	var margem := MarginContainer.new()
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margem.add_theme_constant_override("margin_left", 7)
	margem.add_theme_constant_override("margin_top", 7)
	margem.add_theme_constant_override("margin_right", 7)
	margem.add_theme_constant_override("margin_bottom", 7)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 3)
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margem.add_child(coluna)

	var palco := PanelContainer.new()
	palco.custom_minimum_size = Vector2(0, 76)
	palco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	palco.add_theme_stylebox_override("panel", ShopTheme.painel(Color(0.28, 0.20, 0.28, 0.75), 0.93))
	palco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(palco)

	_preview = TextureRect.new()
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	palco.add_child(_preview)

	_placeholder = Label.new()
	_placeholder.text = "◇"
	_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ShopTheme.vestir_label(_placeholder, 34, Color(ShopTheme.CARMESIM.r, ShopTheme.CARMESIM.g, ShopTheme.CARMESIM.b, 0.45), 2)
	palco.add_child(_placeholder)

	_nome = Label.new()
	_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nome.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_nome.custom_minimum_size.y = 20
	_nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ShopTheme.vestir_label(_nome, 13, ShopTheme.OSSO, 3)
	coluna.add_child(_nome)

	_raridade_label = Label.new()
	_raridade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_raridade_label.custom_minimum_size.y = 17
	_raridade_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ShopTheme.vestir_label(_raridade_label, 10, ShopTheme.OSSO, 2)
	coluna.add_child(_raridade_label)

	_estado_label = Label.new()
	_estado_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_estado_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_estado_label.custom_minimum_size.y = 22
	_estado_label.add_theme_stylebox_override("normal", _placa_estado(ShopTheme.APAGADO))
	_estado_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ShopTheme.vestir_label(_estado_label, 10, ShopTheme.TEXTO, 2)
	coluna.add_child(_estado_label)


func configurar(id: String, nome: String, raridade: String, estado: String,
		preview: Texture2D, texto_raridade: String, texto_estado: String) -> void:
	item_id = id
	_raridade = raridade
	_estado = estado
	_nome.text = nome
	_raridade_label.text = "◆  " + texto_raridade
	_raridade_label.add_theme_color_override("font_color", ShopTheme.raridade(raridade))
	_estado_label.text = ("▣  " if estado == "bloqueado" else "") + texto_estado
	_estado_label.add_theme_color_override("font_color", ShopTheme.estado(estado))
	_estado_label.add_theme_stylebox_override("normal", _placa_estado(ShopTheme.estado(estado)))
	_preview.texture = preview
	_preview.visible = preview != null
	_placeholder.visible = preview == null
	_aplicar_estilo()


func atualizar_estado(estado: String, texto_estado: String) -> void:
	_estado = estado
	_estado_label.text = ("▣  " if estado == "bloqueado" else "") + texto_estado
	_estado_label.add_theme_color_override("font_color", ShopTheme.estado(estado))
	_estado_label.add_theme_stylebox_override("normal", _placa_estado(ShopTheme.estado(estado)))
	_aplicar_estilo()


func selecionar(valor: bool) -> void:
	_selecionado = valor
	set_pressed_no_signal(valor)
	_aplicar_estilo()


func _aplicar_estilo() -> void:
	var cor := ShopTheme.raridade(_raridade)
	var base := cor if _selecionado or _estado == "equipado" else ShopTheme.CARMESIM
	add_theme_stylebox_override("normal", ShopTheme.placa(base, 0.72 if _selecionado else 0.28, _selecionado))
	add_theme_stylebox_override("hover", ShopTheme.placa(base, 0.92, true))
	add_theme_stylebox_override("focus", ShopTheme.placa(base, 1.0, true))
	add_theme_stylebox_override("pressed", ShopTheme.placa(base, 1.0, true))
	modulate = Color(0.64, 0.64, 0.68) if _estado == "bloqueado" else Color.WHITE


func _animar(dentro: bool) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE * (1.018 if dentro else 1.0), 0.10)
	z_index = 3 if dentro else 0


func _placa_estado(cor: Color) -> StyleBoxFlat:
	var placa := ShopTheme.placa(cor, 0.5)
	placa.set_content_margin_all(0)
	return placa
