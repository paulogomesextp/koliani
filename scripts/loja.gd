class_name Loja
extends Control
## MENU DA LOJA (cosméticos). Sobreposto ao menu principal, na mesma
## linguagem do Frontend9H (carmesim sobre carvão). Só LÊ o catálogo
## (`LojaCatalogo`) e chama `EstadoJogo.comprar_item/equipar_item` -- nenhuma
## regra de preço ou de saldo vive aqui.
##
## Topo: saldos. Esquerda: categorias. Centro: itens. Direita: detalhe.
## Fecha em BACK ou Esc; o foco fica confinado à Loja.

signal fechado

const KOLI := "k"
const VERA := "v"

var _cat := "destaques"
var _sel := ""
var _lbl_k: Label
var _lbl_v: Label
var _botoes_cat := {}
var _grelha: GridContainer
var _cartoes := {}
var _det_nome: Label
var _det_desc: Label
var _det_estado: Label
var _det_req: Label
var _det_aviso: Label
var _det_preview: PanelContainer
var _det_ph: Label
var _btn_k: Button
var _btn_v: Button
var _btn_eq: Button
var _voltar: Button
var _titulo: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Frontend9H.vestir(self)
	_montar()
	EstadoJogo.moedas_loja_mudaram.connect(_refrescar)
	EstadoJogo.item_loja_equipado.connect(func(_c: String, _i: String) -> void: _refrescar())
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	get_viewport().gui_focus_changed.connect(_foco_mudou)
	_traduzir()
	_escolher_categoria("destaques")
	_botoes_cat["destaques"].grab_focus()


func _montar() -> void:
	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(Frontend9H.CARVAO.r, Frontend9H.CARVAO.g, Frontend9H.CARVAO.b, 1.0)
	add_child(fundo)
	add_child(Frontend9H.vinheta())

	_titulo = Label.new()
	_por(_titulo, 0.0, 26.0, 1280.0, 64.0)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Frontend9H.cabecalho(_titulo, 34)
	add_child(_titulo)
	var orn := Frontend9H.separador()
	_por(orn, 490.0, 68.0, 300.0, 14.0)
	add_child(orn)

	# saldos (topo, à direita)
	_lbl_k = Label.new()
	_por(_lbl_k, 760.0, 30.0, 236.0, 28.0)
	_lbl_k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Frontend9H.corpo(_lbl_k, 18, Frontend9H.OSSO)
	add_child(_lbl_k)
	_lbl_v = Label.new()
	_por(_lbl_v, 1004.0, 30.0, 236.0, 28.0)
	_lbl_v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Frontend9H.corpo(_lbl_v, 18, Frontend9H.CARMESIM_CLARO)
	add_child(_lbl_v)

	# categorias
	var nav := VBoxContainer.new()
	_por(nav, 40.0, 110.0, 230.0, 400.0)
	nav.add_theme_constant_override("separation", 10)
	add_child(nav)
	for c: String in LojaCatalogo.CATEGORIAS:
		var b := Button.new()
		b.name = "Cat_" + c
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, 44)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		Frontend9H.botao_placa(b, 16)
		b.pressed.connect(_escolher_categoria.bind(c))
		nav.add_child(b)
		_botoes_cat[c] = b

	# grelha de itens (centro)
	var rolo := ScrollContainer.new()
	_por(rolo, 300.0, 110.0, 520.0, 500.0)
	rolo.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolo.follow_focus = true
	add_child(rolo)
	_grelha = GridContainer.new()
	_grelha.columns = 2
	_grelha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grelha.add_theme_constant_override("h_separation", 14)
	_grelha.add_theme_constant_override("v_separation", 14)
	rolo.add_child(_grelha)

	# detalhe (direita)
	var painel := PanelContainer.new()
	_por(painel, 846.0, 100.0, 394.0, 520.0)
	var sb := Frontend9H.painel_liso()
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	painel.add_theme_stylebox_override("panel", sb)
	add_child(painel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	painel.add_child(col)

	_det_preview = PanelContainer.new()
	_det_preview.custom_minimum_size = Vector2(0, 130)
	var pv := StyleBoxFlat.new()
	pv.bg_color = Color(0.08, 0.04, 0.07, 1.0)
	pv.border_color = Color(Frontend9H.CARMESIM.r, Frontend9H.CARMESIM.g, Frontend9H.CARMESIM.b, 0.45)
	pv.set_border_width_all(1)
	_det_preview.add_theme_stylebox_override("panel", pv)
	col.add_child(_det_preview)
	_det_ph = Label.new()
	_det_ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_det_ph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Frontend9H.capitular(_det_ph, 12, Frontend9H.TEXTO_APAGADO)
	_det_preview.add_child(_det_ph)

	_det_nome = Label.new()
	_det_nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Frontend9H.cabecalho(_det_nome, 22)
	col.add_child(_det_nome)
	_det_estado = Label.new()
	Frontend9H.capitular(_det_estado, 14, Frontend9H.CARMESIM_CLARO)
	_det_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(_det_estado)
	_det_desc = Label.new()
	_det_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Frontend9H.corpo(_det_desc, 15)
	col.add_child(_det_desc)
	_det_req = Label.new()
	_det_req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Frontend9H.corpo(_det_req, 14, Color(1.0, 0.62, 0.45))
	col.add_child(_det_req)
	var mola := Control.new()
	mola.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(mola)
	_det_aviso = Label.new()
	_det_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Frontend9H.corpo(_det_aviso, 13, Frontend9H.TEXTO_APAGADO)
	col.add_child(_det_aviso)
	_btn_k = Button.new()
	_btn_v = Button.new()
	_btn_eq = Button.new()
	_btn_k.name = "ComprarK"
	_btn_v.name = "ComprarV"
	_btn_eq.name = "Equipar"
	for b: Button in [_btn_k, _btn_v, _btn_eq]:
		b.custom_minimum_size = Vector2(0, 42)
		Frontend9H.botao_placa(b, 16)
		col.add_child(b)
	_btn_k.pressed.connect(func() -> void: _comprar(KOLI))
	_btn_v.pressed.connect(func() -> void: _comprar(VERA))
	_btn_eq.pressed.connect(_equipar)

	_voltar = Button.new()
	_voltar.name = "Voltar"
	_por(_voltar, 40.0, 640.0, 230.0, 46.0)
	Frontend9H.botao_placa(_voltar, 20)
	_voltar.pressed.connect(_fechar)
	add_child(_voltar)


func _por(no: Control, x: float, y: float, w: float, h: float) -> void:
	Frontend9H.por(no, Rect2(x, y, w, h))


func _traduzir() -> void:
	_titulo.text = Frontend9H.espacar(Textos.t("shop.title"), 1)
	_voltar.text = Textos.t("options.back")
	for c: String in _botoes_cat:
		(_botoes_cat[c] as Button).text = Textos.t("shop.cat." + c)
	_refrescar()


func _escolher_categoria(c: String) -> void:
	_cat = c
	for k: String in _botoes_cat:
		(_botoes_cat[k] as Button).set_pressed_no_signal(k == c)
	for f in _grelha.get_children():
		f.queue_free()
	_cartoes.clear()
	var itens := LojaCatalogo.da_categoria(c)
	if itens.is_empty():
		var vazio := Label.new()
		Frontend9H.corpo(vazio, 16, Frontend9H.TEXTO_APAGADO)
		vazio.text = Textos.t("shop.empty")
		_grelha.add_child(vazio)
	for it: Dictionary in itens:
		var id := str(it["id"])
		var b := Button.new()
		b.name = "Item_" + id
		b.custom_minimum_size = Vector2(250, 92)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		Frontend9H.botao_placa(b, 15)
		b.pressed.connect(func() -> void: _selecionar(id))
		b.focus_entered.connect(func() -> void: _selecionar(id))
		_grelha.add_child(b)
		_cartoes[id] = b
	_sel = str(itens[0]["id"]) if not itens.is_empty() else ""
	_ligar_foco()
	_refrescar()


## Foco explícito: categorias em coluna (com o BACK no fim, em ciclo), itens
## à direita da categoria ativa, e o regresso à esquerda. A pesquisa
## geométrica do motor não chegava ao nav a partir da grelha.
func _ligar_foco() -> void:
	var cats: Array = []
	for c: String in LojaCatalogo.CATEGORIAS:
		cats.append(_botoes_cat[c])
	var seq: Array = cats + [_voltar]
	for i in seq.size():
		var b: Control = seq[i]
		b.focus_neighbor_top = b.get_path_to(seq[(i - 1 + seq.size()) % seq.size()])
		b.focus_neighbor_bottom = b.get_path_to(seq[(i + 1) % seq.size()])
	var primeiro: Control = _cartoes.get(_sel)
	for b: Control in seq:
		b.focus_neighbor_right = b.get_path_to(primeiro) if primeiro else NodePath()
	var ordem: Array = _cartoes.values()
	var cols := _grelha.columns
	for i in ordem.size():
		var it: Control = ordem[i]
		it.focus_neighbor_left = it.get_path_to(_botoes_cat[_cat]) if i % cols == 0 			else it.get_path_to(ordem[i - 1])
		it.focus_neighbor_right = it.get_path_to(ordem[i + 1]) if i % cols == 0 and i + 1 < ordem.size() 			else it.get_path_to(_btn_k)
		it.focus_neighbor_top = it.get_path_to(ordem[i - cols]) if i - cols >= 0 else it.get_path_to(it)
		it.focus_neighbor_bottom = it.get_path_to(ordem[i + cols]) if i + cols < ordem.size() else it.get_path_to(it)
	for b: Button in [_btn_k, _btn_v, _btn_eq]:
		if primeiro:
			b.focus_neighbor_left = b.get_path_to(primeiro)


func _selecionar(id: String) -> void:
	if id == _sel:
		return
	_sel = id
	_refrescar()


func _texto_precos(it: Dictionary) -> String:
	var partes := []
	if LojaCatalogo.preco(it, KOLI) >= 0:
		partes.append("%d K" % LojaCatalogo.preco(it, KOLI))
	if LojaCatalogo.preco(it, VERA) >= 0:
		partes.append("%d V" % LojaCatalogo.preco(it, VERA))
	return "  ·  ".join(partes)


func _refrescar() -> void:
	if _lbl_k == null:
		return
	_lbl_k.text = "%s  %d" % [Textos.t("shop.kolicoins"), EstadoJogo.kolicoins]
	_lbl_v.text = "%s  %d" % [Textos.t("shop.veracoins"), EstadoJogo.veracoins]
	for id: String in _cartoes:
		var b: Button = _cartoes[id]
		var it := LojaCatalogo.item(id)
		var est := EstadoJogo.estado_item_loja(id)
		var linha2 := Textos.t("shop.state." + est)
		if est == "disponivel" or est == "bloqueado":
			linha2 += "   " + _texto_precos(it)
		b.text = Textos.t("shop.item.%s.name" % id) + "\n" + linha2
		b.add_theme_color_override("font_color", _cor_estado(est))
		b.add_theme_color_override("font_hover_color", _cor_estado(est))
		b.add_theme_color_override("font_focus_color", Frontend9H.OSSO)
		b.set_pressed_no_signal(id == _sel)
	_detalhe()


func _cor_estado(est: String) -> Color:
	match est:
		"equipado":
			return Frontend9H.VERDE_ESTADO
		"adquirido":
			return Frontend9H.OSSO
		"bloqueado":
			return Frontend9H.TEXTO_APAGADO
	return Frontend9H.TEXTO


func _detalhe() -> void:
	var vazio := _sel == ""
	for b: Button in [_btn_k, _btn_v, _btn_eq]:
		b.visible = false
	_det_ph.text = ""
	_det_req.text = ""
	_det_aviso.text = ""
	if vazio:
		_det_nome.text = Textos.t("shop.pick")
		_det_estado.text = ""
		_det_desc.text = ""
		return
	var it := LojaCatalogo.item(_sel)
	var est := EstadoJogo.estado_item_loja(_sel)
	_det_nome.text = Textos.t("shop.item.%s.name" % _sel)
	_det_desc.text = Textos.t("shop.item.%s.desc" % _sel)
	_det_estado.text = Textos.t("shop.state." + est)
	if bool(it["placeholder"]):
		_det_ph.text = Textos.t("shop.placeholder")
	var r := int(it["regiao"])
	if r >= 0 and EstadoJogo.item_bloqueado(_sel):
		_det_req.text = Textos.tf("shop.requires_region", [Textos.t(
			str(EstadoJogo.REGIOES[r]["chave"]))])
	var aceites := LojaCatalogo.moedas_aceites(it)
	if est == "disponivel" or est == "bloqueado":
		for moeda in aceites:
			var btn := _btn_k if moeda == KOLI else _btn_v
			var p := LojaCatalogo.preco(it, moeda)
			btn.text = Textos.tf("shop.buy_k" if moeda == KOLI else "shop.buy_v", [p])
			btn.visible = true
			btn.disabled = est == "bloqueado" or EstadoJogo.saldo_loja(moeda) < p
		if aceites.size() > 1:
			_det_aviso.text = Textos.t("shop.either")
		elif est == "disponivel" and (_btn_k.disabled and _btn_k.visible or _btn_v.disabled and _btn_v.visible):
			_det_aviso.text = Textos.tf("shop.no_funds", [Textos.t(
				"shop.kolicoins" if aceites[0] == KOLI else "shop.veracoins")])
	elif (est == "adquirido" or est == "equipado") and str(it["categoria"]) in LojaCatalogo.EQUIPAVEIS:
		_btn_eq.visible = true
		_btn_eq.text = Textos.t("shop.equipped" if est == "equipado" else "shop.equip")
		_btn_eq.disabled = est == "equipado"
	_det_aviso.text += ("\n" if _det_aviso.text != "" else "") + Textos.t("shop.cosmetic_only")


func _comprar(moeda: String) -> void:
	if _sel == "":
		return
	var r: Dictionary = EstadoJogo.comprar_item(_sel, moeda)
	Som.toca("ui_confirmar" if r["ok"] else "ui_voltar", -8.0)
	_refrescar()
	_refocar()


func _equipar() -> void:
	if _sel != "" and EstadoJogo.equipar_item(_sel):
		Som.toca("ui_confirmar", -8.0)
	_refrescar()
	_refocar()


## Depois de comprar/equipar o botão que tinha o foco pode ter desaparecido
## ou ficado desativado: devolve o foco a algo dentro da Loja.
func _refocar() -> void:
	var f := get_viewport().gui_get_focus_owner()
	if f == null or not f.is_visible_in_tree() or (f is Button and (f as Button).disabled):
		var alvo: Button = _cartoes.get(_sel, _botoes_cat[_cat])
		alvo.grab_focus()


func _foco_mudou(no: Control) -> void:
	if is_inside_tree() and not is_ancestor_of(no) and not is_queued_for_deletion():
		var alvo: Button = _cartoes.get(_sel, _botoes_cat[_cat])
		alvo.grab_focus()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		_fechar()
		get_viewport().set_input_as_handled()


func _fechar() -> void:
	Som.toca("menu_painel", -12.0, 0.92)
	fechado.emit()
	queue_free()
