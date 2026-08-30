class_name SeletorEquip
extends Control
## Ecrã de escolha de arma ou armadura. Mostra sempre os 15 itens do tipo;
## os que ainda não se ganharam aparecem a cinzento com o nível a que
## desbloqueiam ("Nv 7"). Tocar num item que já se tem equipa-o.
##
## Aberto pelo menu de Pausa (`configurar("arma")` ou `"armadura"`), corre
## com a árvore em pausa. Sinal `fechado` quando se recua.

signal fechado

const COR_ARMA := Color(0.95, 0.55, 0.45)
const COR_ARMADURA := Color(0.5, 0.7, 0.95)
const TIRA_ARMAS := preload("res://assets/sprites/pixel/gear/armas.png")
const TIRA_ARMADURAS := preload("res://assets/sprites/pixel/gear/armaduras.png")
const CELULA := Vector2(18, 26)

var _tipo := "arma"
var _grelha: GridContainer
var _titulo: Label
var _cor: Color


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_montar()
	EstadoJogo.equipamento_mudou.connect(func(_t: String, _i: String) -> void: _preencher())


func configurar(tipo: String) -> void:
	_tipo = tipo
	_cor = COR_ARMA if tipo == "arma" else COR_ARMADURA
	if _titulo:
		_titulo.text = Textos.t("gear.title.weapons" if tipo == "arma" else "gear.title.armor")
		_titulo.add_theme_color_override("font_color", _cor)
	_preencher()


# --- construção ------------------------------------------------------

func _montar() -> void:
	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.02, 0.01, 0.03, 0.94)
	add_child(fundo)

	_titulo = Label.new()
	_titulo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_titulo.position = Vector2(-200, 22)
	_titulo.custom_minimum_size = Vector2(400, 0)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.add_theme_font_size_override("font_size", 26)
	_titulo.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.03))
	_titulo.add_theme_constant_override("outline_size", 6)
	add_child(_titulo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.offset_top = 64.0
	centro.offset_bottom = -76.0
	add_child(centro)

	_grelha = GridContainer.new()
	_grelha.columns = 5
	_grelha.add_theme_constant_override("h_separation", 12)
	_grelha.add_theme_constant_override("v_separation", 12)
	centro.add_child(_grelha)

	var voltar := Button.new()
	voltar.name = "Voltar"
	voltar.focus_mode = Control.FOCUS_NONE
	voltar.text = Textos.t("gear.back")
	voltar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	voltar.position = Vector2(-80, -58)
	voltar.custom_minimum_size = Vector2(160, 42)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.06, 0.16, 0.95)
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.85, 0.4, 0.82)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	for e in ["normal", "hover", "pressed", "focus"]:
		voltar.add_theme_stylebox_override(e, sb)
	voltar.add_theme_color_override("font_color", Color(1, 0.88, 0.98))
	voltar.pressed.connect(func() -> void: fechado.emit())
	add_child(voltar)


func _preencher() -> void:
	if _grelha == null:
		return
	for c in _grelha.get_children():
		c.queue_free()
	var lista: Array = Equipamento.ARMAS if _tipo == "arma" else Equipamento.ARMADURAS
	for item: Dictionary in lista:
		_grelha.add_child(_fazer_cartao(item))
	# comando/teclado: pôr o foco num cartão para dar para navegar sem rato
	call_deferred("_focar_cartao")


func _focar_cartao() -> void:
	if _grelha == null:
		return
	var equip := EstadoJogo.arma_equipada if _tipo == "arma" else EstadoJogo.armadura_equipada
	var primeiro: Control = null
	for c in _grelha.get_children():
		var b := c as Button
		if b == null or b.disabled or b.focus_mode == Control.FOCUS_NONE:
			continue
		if primeiro == null:
			primeiro = b
		if str(b.get_meta("id", "")) == equip:
			b.grab_focus()
			return
	if primeiro:
		primeiro.grab_focus()


func _fazer_cartao(item: Dictionary) -> Control:
	var id: String = item["id"]
	var tem: bool = EstadoJogo.tem_arma(id) if _tipo == "arma" else EstadoJogo.tem_armadura(id)
	var equipada: bool = (EstadoJogo.arma_equipada if _tipo == "arma" else EstadoJogo.armadura_equipada) == id

	var b := Button.new()
	b.focus_mode = Control.FOCUS_ALL if tem else Control.FOCUS_NONE
	b.set_meta("id", id)
	b.custom_minimum_size = Vector2(196, 116)
	b.disabled = not tem
	b.clip_text = false
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(2)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	if not tem:
		sb.bg_color = Color(0.07, 0.07, 0.08, 0.9)
		sb.border_color = Color(0.22, 0.22, 0.26, 0.9)
	elif equipada:
		sb.bg_color = _cor.darkened(0.55)
		sb.bg_color.a = 0.95
		sb.border_color = Color(1, 0.9, 0.55)
		sb.set_border_width_all(3)
	else:
		sb.bg_color = Color(0.1, 0.08, 0.13, 0.95)
		sb.border_color = _cor
	for e in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(e, sb)

	# imagem do item como fundo do cartão (esbatida; cinza se ainda bloqueada)
	var idx := Equipamento.indice_arma(id) if _tipo == "arma" else Equipamento.indice_armadura(id)
	var fundo_img := TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = TIRA_ARMAS if _tipo == "arma" else TIRA_ARMADURAS
	at.region = Rect2(idx * CELULA.x, 0, CELULA.x, CELULA.y)
	fundo_img.texture = at
	fundo_img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fundo_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fundo_img.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tem:
		fundo_img.modulate = Color(1, 1, 1, 0.5)
	else:
		fundo_img.modulate = Color(0.4, 0.4, 0.45, 0.32)  # dessaturado + escuro
	b.add_child(fundo_img)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(col)

	var nome := Label.new()
	nome.text = Textos.t(item["nome"])
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nome.add_theme_font_size_override("font_size", 15)
	nome.add_theme_color_override("font_color", Color(0.97, 0.94, 1) if tem else Color(0.5, 0.5, 0.56))
	col.add_child(nome)

	var stat := Label.new()
	stat.add_theme_font_size_override("font_size", 12)
	stat.add_theme_color_override("font_color", _cor if tem else Color(0.45, 0.45, 0.5))
	if _tipo == "arma":
		stat.text = Textos.tf("gear.stat.dmg", [int(item["dano"])])
	else:
		var partes: Array[String] = []
		if int(item["vida_bonus"]) > 0:
			partes.append(Textos.tf("gear.stat.hp", [int(item["vida_bonus"])]))
		if float(item["reducao"]) > 0.0:
			partes.append(Textos.tf("gear.stat.armor", [int(round(float(item["reducao"]) * 100.0))]))
		stat.text = "   ·   ".join(partes) if not partes.is_empty() else "—"
	col.add_child(stat)

	var estado := Label.new()
	estado.add_theme_font_size_override("font_size", 12)
	if not tem:
		estado.text = Textos.tf("gear.locked", [int(item["nivel"])])
		estado.add_theme_color_override("font_color", Color(0.6, 0.6, 0.66))
	elif equipada:
		estado.text = Textos.t("gear.equipped")
		estado.add_theme_color_override("font_color", Color(1, 0.9, 0.55))
	else:
		estado.text = Textos.t("gear.equip")
		estado.add_theme_color_override("font_color", Color(0.7, 1, 0.8))
	col.add_child(estado)

	if tem and not equipada:
		b.pressed.connect(func() -> void:
			if _tipo == "arma":
				EstadoJogo.equipar_arma(id)
			else:
				EstadoJogo.equipar_armadura(id)
			Som.toca("apanhar", -12.0, 1.1))
	return b


func _unhandled_input(evento: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if evento.is_action_pressed("pausa") or evento.is_action_pressed("ui_cancel"):
		fechado.emit()
		get_viewport().set_input_as_handled()
