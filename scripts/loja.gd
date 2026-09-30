class_name Loja
extends Control
## Loja de cosméticos: apresentação dark-gothic sobre o catálogo/estado
## existentes. Este ficheiro só lê `LojaCatalogo` e `CosmeticosVisuais` e
## chama as operações públicas de `EstadoJogo`; nenhuma regra económica vive
## na UI.

signal fechado

const KOLI := "k"
const VERA := "v"

var _cat := "destaques"
var _sel := ""
var _lbl_k: Label
var _lbl_v: Label
var _botoes_cat := {}
var _grelha: GridContainer
var _rolo: ScrollContainer
var _cartoes := {}
var _det_nome: Label
var _det_raridade: Label
var _det_desc: Label
var _det_estado: Label
var _det_req: Label
var _det_aviso: Label
var _det_preview: PanelContainer
var _det_ph: Label
var _det_img: TextureRect
var _btn_k: Button
var _btn_v: Button
var _btn_eq: Button
var _voltar: Button
var _titulo: Label
var _marca: Label
var _hero_nome: Label
var _hero_raridade: Label
var _hero_estado: Label
var _hero_desc: Label
var _hero_img: TextureRect
var _hero_ph: Label
var _hero_botao: Button
var _hero_tag: Label
var _area_esquerda: VBoxContainer
var _painel_detalhe: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Frontend9H.vestir(self)
	_montar()
	EstadoJogo.moedas_loja_mudaram.connect(_refrescar)
	EstadoJogo.item_loja_equipado.connect(func(_c: String, _i: String) -> void: _refrescar())
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	get_viewport().gui_focus_changed.connect(_foco_mudou)
	get_viewport().size_changed.connect(_ajustar_responsivo)
	_traduzir()
	_escolher_categoria("destaques")
	_botoes_cat["destaques"].grab_focus()
	call_deferred("_ajustar_responsivo")


func _montar() -> void:
	_montar_fundo()
	var margem := MarginContainer.new()
	margem.name = "MargemSegura"
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margem.add_theme_constant_override("margin_left", 24)
	margem.add_theme_constant_override("margin_top", 15)
	margem.add_theme_constant_override("margin_right", 24)
	margem.add_theme_constant_override("margin_bottom", 14)
	add_child(margem)
	var pagina := VBoxContainer.new()
	pagina.name = "ShopLayout"
	pagina.add_theme_constant_override("separation", 9)
	margem.add_child(pagina)
	_montar_header(pagina)
	_montar_tabs(pagina)
	var conteudo := HBoxContainer.new()
	conteudo.name = "Content"
	conteudo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	conteudo.add_theme_constant_override("separation", 13)
	pagina.add_child(conteudo)
	_area_esquerda = VBoxContainer.new()
	_area_esquerda.name = "FeaturedAndCatalog"
	_area_esquerda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_area_esquerda.size_flags_stretch_ratio = 3.25
	_area_esquerda.add_theme_constant_override("separation", 10)
	conteudo.add_child(_area_esquerda)
	_montar_hero(_area_esquerda)
	_montar_catalogo(_area_esquerda)
	_painel_detalhe = _montar_detalhe()
	_painel_detalhe.name = "ItemDetails"
	_painel_detalhe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_painel_detalhe.size_flags_stretch_ratio = 1.0
	_painel_detalhe.custom_minimum_size.x = 270
	conteudo.add_child(_painel_detalhe)
	var rodape := HBoxContainer.new()
	rodape.name = "Footer"
	rodape.custom_minimum_size.y = 42
	pagina.add_child(rodape)
	_voltar = Button.new()
	_voltar.name = "Voltar"
	_voltar.custom_minimum_size = Vector2(154, 40)
	_voltar.alignment = HORIZONTAL_ALIGNMENT_LEFT
	ShopTheme.vestir_botao(_voltar, ShopTheme.CARMESIM, 14)
	_voltar.pressed.connect(_fechar)
	rodape.add_child(_voltar)


func _montar_fundo() -> void:
	var fundo := Control.new()
	fundo.name = "ShopBackground"
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	var textura := TextureRect.new()
	textura.name = "BackgroundTexture"
	textura.texture = Frontend9H.textura("fundo_menu")
	textura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	textura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	textura.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	textura.modulate = Color(0.48, 0.42, 0.48, 1.0)
	textura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(textura)
	var escuro := ColorRect.new()
	escuro.name = "DarkOverlay"
	escuro.color = Color(0.018, 0.008, 0.015, 0.66)
	escuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(escuro)
	var ambiente := Control.new()
	ambiente.name = "AmbientFX"
	ambiente.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ambiente.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(ambiente)
	for lado in [0, 1]:
		var brasa := ColorRect.new()
		brasa.color = Color(0.65, 0.015, 0.045, 0.11)
		brasa.anchor_top = 0.0
		brasa.anchor_bottom = 1.0
		brasa.anchor_left = 0.0 if lado == 0 else 0.985
		brasa.anchor_right = 0.015 if lado == 0 else 1.0
		brasa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ambiente.add_child(brasa)
	var vinheta := Frontend9H.vinheta()
	vinheta.name = "Vignette"
	vinheta.modulate = Color(0.45, 0.30, 0.36, 0.88)
	fundo.add_child(vinheta)


func _montar_header(pai: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.name = "Header"
	header.custom_minimum_size.y = 60
	header.add_theme_constant_override("separation", 14)
	pai.add_child(header)
	var marca_box := HBoxContainer.new()
	marca_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marca_box.size_flags_stretch_ratio = 1.0
	marca_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	header.add_child(marca_box)
	var sigilo := Label.new()
	sigilo.text = "◇"
	sigilo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ShopTheme.vestir_label(sigilo, 30, ShopTheme.CARMESIM_CLARO, 4)
	marca_box.add_child(sigilo)
	_marca = Label.new()
	_marca.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ShopTheme.vestir_label(_marca, 17, ShopTheme.OSSO, 4)
	marca_box.add_child(_marca)
	var titulo_box := VBoxContainer.new()
	titulo_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo_box.size_flags_stretch_ratio = 1.0
	titulo_box.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(titulo_box)
	_titulo = Label.new()
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ShopTheme.vestir_label(_titulo, 31, ShopTheme.OSSO, 6)
	_titulo.add_theme_color_override("font_shadow_color", Color(0.8, 0.02, 0.08, 0.42))
	_titulo.add_theme_constant_override("shadow_outline_size", 12)
	titulo_box.add_child(_titulo)
	var orn := Frontend9H.separador()
	orn.custom_minimum_size = Vector2(240, 10)
	orn.modulate = Color(ShopTheme.CARMESIM_CLARO.r, ShopTheme.CARMESIM_CLARO.g, ShopTheme.CARMESIM_CLARO.b, 0.72)
	titulo_box.add_child(orn)
	var moedas := HBoxContainer.new()
	moedas.name = "Currencies"
	moedas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	moedas.size_flags_stretch_ratio = 1.0
	moedas.alignment = BoxContainer.ALIGNMENT_END
	moedas.add_theme_constant_override("separation", 15)
	header.add_child(moedas)
	_lbl_k = _criar_moeda(moedas, ShopTheme.OURO)
	_lbl_v = _criar_moeda(moedas, ShopTheme.CARMESIM_CLARO)


func _criar_moeda(pai: HBoxContainer, cor: Color) -> Label:
	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(146, 39)
	painel.add_theme_stylebox_override("panel", ShopTheme.placa(cor, 0.34))
	pai.add_child(painel)
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ShopTheme.vestir_label(label, 13, cor, 3)
	painel.add_child(label)
	return label


func _montar_tabs(pai: VBoxContainer) -> void:
	var nav_painel := PanelContainer.new()
	nav_painel.name = "Navigation"
	nav_painel.custom_minimum_size.y = 44
	nav_painel.add_theme_stylebox_override("panel", ShopTheme.painel(Color(0.34, 0.15, 0.20, 0.75), 0.86))
	pai.add_child(nav_painel)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 1)
	nav_painel.add_child(nav)
	for c: String in LojaCatalogo.CATEGORIAS:
		var b := Button.new()
		b.name = "Cat_" + c
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 42
		ShopTheme.vestir_botao(b, ShopTheme.CARMESIM, 12)
		b.pressed.connect(_escolher_categoria.bind(c))
		nav.add_child(b)
		_botoes_cat[c] = b


func _montar_hero(pai: VBoxContainer) -> void:
	var painel := PanelContainer.new()
	painel.name = "FeaturedHero"
	painel.custom_minimum_size.y = 232
	painel.add_theme_stylebox_override("panel", ShopTheme.painel(ShopTheme.OURO, 0.87, 2))
	pai.add_child(painel)
	var margem := MarginContainer.new()
	for lado in ["left", "right"]:
		margem.add_theme_constant_override("margin_" + lado, 19)
	margem.add_theme_constant_override("margin_top", 13)
	margem.add_theme_constant_override("margin_bottom", 13)
	painel.add_child(margem)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 12)
	margem.add_child(linha)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_stretch_ratio = 0.95
	copy.add_theme_constant_override("separation", 4)
	linha.add_child(copy)
	_hero_tag = Label.new()
	ShopTheme.vestir_label(_hero_tag, 11, ShopTheme.OURO, 3)
	copy.add_child(_hero_tag)
	_hero_nome = Label.new()
	_hero_nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hero_nome.max_lines_visible = 2
	ShopTheme.vestir_label(_hero_nome, 27, ShopTheme.OSSO, 5)
	copy.add_child(_hero_nome)
	_hero_raridade = Label.new()
	ShopTheme.vestir_label(_hero_raridade, 12, ShopTheme.OURO, 3)
	copy.add_child(_hero_raridade)
	_hero_estado = Label.new()
	ShopTheme.vestir_label(_hero_estado, 11, ShopTheme.TEXTO, 2)
	copy.add_child(_hero_estado)
	_hero_desc = Label.new()
	_hero_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hero_desc.max_lines_visible = 3
	_hero_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ShopTheme.vestir_label(_hero_desc, 13, ShopTheme.TEXTO, 3)
	copy.add_child(_hero_desc)
	_hero_botao = Button.new()
	_hero_botao.custom_minimum_size = Vector2(170, 36)
	_hero_botao.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_hero_botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
	ShopTheme.vestir_botao(_hero_botao, ShopTheme.CARMESIM, 12)
	_hero_botao.pressed.connect(_focar_detalhe)
	copy.add_child(_hero_botao)
	var palco := PanelContainer.new()
	palco.name = "FeaturedPreview"
	palco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	palco.size_flags_stretch_ratio = 1.35
	palco.add_theme_stylebox_override("panel", ShopTheme.painel(Color(0.43, 0.25, 0.20, 0.68), 0.46))
	linha.add_child(palco)
	_hero_img = TextureRect.new()
	_hero_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hero_img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hero_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	palco.add_child(_hero_img)
	_hero_ph = Label.new()
	_hero_ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hero_ph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hero_ph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ShopTheme.vestir_label(_hero_ph, 12, ShopTheme.APAGADO, 3)
	palco.add_child(_hero_ph)


func _montar_catalogo(pai: VBoxContainer) -> void:
	_rolo = ScrollContainer.new()
	_rolo.name = "CatalogScroll"
	_rolo.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rolo.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_rolo.follow_focus = true
	_rolo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pai.add_child(_rolo)
	_grelha = GridContainer.new()
	_grelha.name = "ItemGrid"
	_grelha.columns = 5
	_grelha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grelha.add_theme_constant_override("h_separation", 8)
	_grelha.add_theme_constant_override("v_separation", 8)
	_rolo.add_child(_grelha)


func _montar_detalhe() -> PanelContainer:
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", ShopTheme.painel(ShopTheme.CARMESIM, 0.93, 2))
	var margem := MarginContainer.new()
	for lado in ["left", "right"]:
		margem.add_theme_constant_override("margin_" + lado, 18)
	margem.add_theme_constant_override("margin_top", 17)
	margem.add_theme_constant_override("margin_bottom", 17)
	painel.add_child(margem)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 7)
	margem.add_child(col)
	_det_preview = PanelContainer.new()
	_det_preview.custom_minimum_size = Vector2(0, 152)
	_det_preview.add_theme_stylebox_override("panel", ShopTheme.painel(Color(0.36, 0.18, 0.24, 0.78), 0.55))
	col.add_child(_det_preview)
	_det_ph = Label.new()
	_det_ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_det_ph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_det_ph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ShopTheme.vestir_label(_det_ph, 11, ShopTheme.APAGADO, 3)
	_det_preview.add_child(_det_ph)
	_det_img = TextureRect.new()
	_det_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_det_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_det_img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_det_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_det_preview.add_child(_det_img)
	_det_nome = Label.new()
	_det_nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_det_nome.max_lines_visible = 2
	ShopTheme.vestir_label(_det_nome, 23, ShopTheme.OSSO, 5)
	col.add_child(_det_nome)
	_det_raridade = Label.new()
	ShopTheme.vestir_label(_det_raridade, 12, ShopTheme.OSSO, 3)
	col.add_child(_det_raridade)
	var separador := HSeparator.new()
	separador.add_theme_stylebox_override("separator", _separador(ShopTheme.CARMESIM))
	col.add_child(separador)
	_det_estado = Label.new()
	ShopTheme.vestir_label(_det_estado, 12, ShopTheme.CARMESIM_CLARO, 3)
	col.add_child(_det_estado)
	_det_desc = Label.new()
	_det_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_det_desc.max_lines_visible = 5
	ShopTheme.vestir_label(_det_desc, 13, ShopTheme.TEXTO, 3)
	col.add_child(_det_desc)
	_det_req = Label.new()
	_det_req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_det_req.max_lines_visible = 2
	ShopTheme.vestir_label(_det_req, 11, Color(1.0, 0.60, 0.38), 3)
	col.add_child(_det_req)
	var mola := Control.new()
	mola.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(mola)
	_det_aviso = Label.new()
	_det_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_det_aviso.max_lines_visible = 4
	ShopTheme.vestir_label(_det_aviso, 10, ShopTheme.APAGADO, 2)
	col.add_child(_det_aviso)
	_btn_k = Button.new()
	_btn_v = Button.new()
	_btn_eq = Button.new()
	_btn_k.name = "ComprarK"
	_btn_v.name = "ComprarV"
	_btn_eq.name = "Equipar"
	for b: Button in [_btn_k, _btn_v, _btn_eq]:
		b.custom_minimum_size = Vector2(0, 38)
		ShopTheme.vestir_botao(b, ShopTheme.CARMESIM, 12)
		col.add_child(b)
	_btn_k.pressed.connect(func() -> void: _comprar(KOLI))
	_btn_v.pressed.connect(func() -> void: _comprar(VERA))
	_btn_eq.pressed.connect(_equipar)
	return painel


func _separador(cor: Color) -> StyleBoxLine:
	var linha := StyleBoxLine.new()
	linha.color = Color(cor.r, cor.g, cor.b, 0.45)
	linha.thickness = 1
	return linha


func _traduzir() -> void:
	if _titulo == null:
		return
	_marca.text = Frontend9H.espacar(Textos.t("shop.brand"), 1)
	_titulo.text = Frontend9H.espacar(Textos.t("shop.title"), 1)
	_voltar.text = "←  " + Textos.t("options.back")
	_hero_tag.text = "◆  " + Textos.t("shop.cat.destaques")
	_hero_botao.text = Textos.t("shop.view") + "  →"
	for c: String in _botoes_cat:
		(_botoes_cat[c] as Button).text = Textos.t("shop.cat." + c)
	_refrescar()


func _escolher_categoria(c: String) -> void:
	_cat = c
	for k: String in _botoes_cat:
		var tab := _botoes_cat[k] as Button
		tab.set_pressed_no_signal(k == c)
		var intensidade := 0.95 if k == c else 0.28
		tab.add_theme_stylebox_override("normal", ShopTheme.placa(ShopTheme.CARMESIM, intensidade, k == c))
	for filho in _grelha.get_children():
		filho.queue_free()
	_cartoes.clear()
	var itens := LojaCatalogo.da_categoria(c)
	if itens.is_empty():
		var vazio := Label.new()
		vazio.text = Textos.t("shop.empty")
		ShopTheme.vestir_label(vazio, 14, ShopTheme.APAGADO, 3)
		_grelha.add_child(vazio)
	for it: Dictionary in itens:
		var id := str(it["id"])
		var cartao := ShopItemCard.new()
		cartao.name = "Item_" + id
		cartao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cartao.item_ativado.connect(_selecionar)
		cartao.focus_entered.connect(_selecionar.bind(id))
		_grelha.add_child(cartao)
		var est := EstadoJogo.estado_item_loja(id)
		cartao.configurar(id, Textos.t("shop.item.%s.name" % id), str(it["raridade"]), est,
			CosmeticosVisuais.preview_loja(id), Textos.t("shop.rarity." + str(it["raridade"])),
			Textos.t("shop.state." + est))
		_cartoes[id] = cartao
	_sel = str(itens[0]["id"]) if not itens.is_empty() else ""
	_ligar_foco()
	_refrescar()
	_rolo.scroll_vertical = 0


func _ligar_foco() -> void:
	var cats: Array = []
	for c: String in LojaCatalogo.CATEGORIAS:
		cats.append(_botoes_cat[c])
	for i in cats.size():
		var tab: Control = cats[i]
		tab.focus_neighbor_left = tab.get_path_to(cats[(i - 1 + cats.size()) % cats.size()])
		tab.focus_neighbor_right = tab.get_path_to(cats[(i + 1) % cats.size()])
	var primeiro: Control = _cartoes.get(_sel)
	for tab: Control in cats:
		tab.focus_neighbor_bottom = tab.get_path_to(primeiro) if primeiro else NodePath()
	var ordem: Array = _cartoes.values()
	var cols := _grelha.columns
	var acao: Control = _botoes_cat[_cat]
	for botao: Button in [_btn_k, _btn_v, _btn_eq]:
		if botao.visible and not botao.disabled:
			acao = botao
			break
	for i in ordem.size():
		var item: Control = ordem[i]
		item.focus_neighbor_left = item.get_path_to(ordem[i - 1]) if i % cols != 0 else item.get_path_to(_voltar)
		item.focus_neighbor_right = item.get_path_to(ordem[i + 1]) if i % cols != cols - 1 and i + 1 < ordem.size() else item.get_path_to(acao)
		item.focus_neighbor_top = item.get_path_to(ordem[i - cols]) if i - cols >= 0 else item.get_path_to(_botoes_cat[_cat])
		item.focus_neighbor_bottom = item.get_path_to(ordem[i + cols]) if i + cols < ordem.size() else item.get_path_to(_voltar)
	for b: Button in [_btn_k, _btn_v, _btn_eq]:
		if primeiro:
			b.focus_neighbor_left = b.get_path_to(primeiro)
	_voltar.focus_neighbor_top = _voltar.get_path_to(ordem[ordem.size() - 1]) if not ordem.is_empty() else NodePath()


func _selecionar(id: String) -> void:
	if id == "" or not _cartoes.has(id):
		return
	_sel = id
	_refrescar()


func _texto_precos(it: Dictionary) -> String:
	var partes := []
	var id := str(it["id"])
	if LojaCatalogo.gratis and (EstadoJogo.preco_loja(id, KOLI) == 0 or EstadoJogo.preco_loja(id, VERA) == 0):
		return Textos.t("shop.free")
	if EstadoJogo.preco_loja(id, KOLI) >= 0:
		partes.append("%d K" % EstadoJogo.preco_loja(id, KOLI))
	if EstadoJogo.preco_loja(id, VERA) >= 0:
		partes.append("%d V" % EstadoJogo.preco_loja(id, VERA))
	return "  ·  ".join(partes)


func _refrescar() -> void:
	if _lbl_k == null:
		return
	_lbl_k.text = "◆  %s  %d" % [Textos.t("shop.kolicoins"), EstadoJogo.kolicoins]
	_lbl_v.text = "◇  %s  %d" % [Textos.t("shop.veracoins"), EstadoJogo.veracoins]
	for id: String in _cartoes:
		var cartao := _cartoes[id] as ShopItemCard
		var est := EstadoJogo.estado_item_loja(id)
		var item := LojaCatalogo.item(id)
		cartao.configurar(id, Textos.t("shop.item.%s.name" % id), str(item["raridade"]), est,
			CosmeticosVisuais.preview_loja(id), Textos.t("shop.rarity." + str(item["raridade"])),
			Textos.t("shop.state." + est))
		cartao.selecionar(id == _sel)
	_detalhe()
	_hero()
	_ligar_foco()


func _hero() -> void:
	if _sel == "":
		_hero_nome.text = ""
		_hero_raridade.text = ""
		_hero_estado.text = ""
		_hero_desc.text = ""
		_hero_img.visible = false
		_hero_ph.text = Textos.t("shop.pick")
		return
	var it := LojaCatalogo.item(_sel)
	var arte := CosmeticosVisuais.preview_loja(_sel)
	_hero_nome.text = Textos.t("shop.item.%s.name" % _sel)
	_hero_raridade.text = "◆  " + Textos.t("shop.rarity." + str(it["raridade"]))
	_hero_raridade.add_theme_color_override("font_color", ShopTheme.raridade(str(it["raridade"])))
	var estado := EstadoJogo.estado_item_loja(_sel)
	_hero_estado.text = Textos.t("shop.state." + estado)
	_hero_estado.add_theme_color_override("font_color", ShopTheme.estado(estado))
	_hero_desc.text = Textos.t("shop.item.%s.desc" % _sel)
	_hero_img.texture = arte
	_hero_img.visible = arte != null
	_hero_ph.visible = arte == null
	_hero_ph.text = Textos.t("shop.placeholder") if arte == null else ""


func _detalhe() -> void:
	for b: Button in [_btn_k, _btn_v, _btn_eq]:
		b.visible = false
	_det_ph.text = ""
	_det_img.visible = false
	_det_raridade.text = ""
	_det_req.text = ""
	_det_aviso.text = ""
	if _sel == "":
		_det_nome.text = Textos.t("shop.pick")
		_det_estado.text = ""
		_det_desc.text = ""
		return
	var it := LojaCatalogo.item(_sel)
	var est := EstadoJogo.estado_item_loja(_sel)
	_det_nome.text = Textos.t("shop.item.%s.name" % _sel)
	_det_desc.text = Textos.t("shop.item.%s.desc" % _sel)
	_det_estado.text = Textos.t("shop.state." + est)
	_det_estado.add_theme_color_override("font_color", ShopTheme.estado(est))
	_det_raridade.text = "◆  " + Textos.t("shop.rarity." + str(it["raridade"]))
	_det_raridade.add_theme_color_override("font_color", ShopTheme.raridade(str(it["raridade"])))
	var arte := CosmeticosVisuais.preview_loja(_sel)
	if arte != null:
		_det_img.texture = arte
		_det_img.visible = true
	else:
		_det_ph.text = Textos.t("shop.placeholder")
	var r := int(it["regiao"])
	if r >= 0 and EstadoJogo.item_bloqueado(_sel):
		_det_req.text = Textos.tf("shop.requires_region", [Textos.t(str(EstadoJogo.REGIOES[r]["chave"]))])
	var aceites := LojaCatalogo.moedas_aceites(it)
	if est == "disponivel" or est == "bloqueado":
		for moeda in aceites:
			var btn := _btn_k if moeda == KOLI else _btn_v
			var preco := EstadoJogo.preco_loja(_sel, moeda)
			if preco < 0 or (preco == 0 and (_btn_k.visible or _btn_v.visible)):
				continue
			btn.text = Textos.tf("shop.buy_k" if moeda == KOLI else "shop.buy_v", [preco]) if preco > 0 else Textos.t("shop.buy_free")
			btn.visible = true
			btn.disabled = est == "bloqueado" or EstadoJogo.saldo_loja(moeda) < preco
		if aceites.size() > 1 and not LojaCatalogo.gratis:
			_det_aviso.text = Textos.t("shop.either")
		elif est == "disponivel" and (_btn_k.disabled and _btn_k.visible or _btn_v.disabled and _btn_v.visible):
			_det_aviso.text = Textos.tf("shop.no_funds", [Textos.t("shop.kolicoins" if aceites[0] == KOLI else "shop.veracoins")])
	elif (est == "adquirido" or est == "equipado") and str(it["categoria"]) in LojaCatalogo.EQUIPAVEIS:
		_btn_eq.visible = true
		_btn_eq.text = Textos.t("shop.equipped" if est == "equipado" else "shop.equip")
		_btn_eq.disabled = est == "equipado"
	elif est == "adquirido" and _sel == Galeria.ITEM:
		_btn_eq.visible = true
		_btn_eq.disabled = false
		_btn_eq.text = Textos.t("shop.view")
	if LojaCatalogo.e_pack(it):
		var dele := 0
		for conteudo: String in it["contem"]:
			if EstadoJogo.item_adquirido(conteudo):
				dele += 1
		var linha := Textos.tf("shop.pack_progress", [dele, it["contem"].size()])
		if dele > 0 and dele < it["contem"].size():
			linha += "\n" + Textos.t("shop.pack_missing")
		_det_aviso.text = linha + ("\n" + _det_aviso.text if _det_aviso.text != "" else "")
	_det_aviso.text += ("\n" if _det_aviso.text != "" else "") + Textos.t("shop.cosmetic_only")


func _focar_detalhe() -> void:
	for b: Button in [_btn_k, _btn_v, _btn_eq]:
		if b.visible and not b.disabled:
			b.grab_focus()
			return
	var alvo: ShopItemCard = _cartoes.get(_sel)
	if alvo:
		alvo.grab_focus()


func _comprar(moeda: String) -> void:
	if _sel == "":
		return
	var resultado: Dictionary = EstadoJogo.comprar_item(_sel, moeda)
	Som.toca("ui_confirmar" if resultado["ok"] else "ui_voltar", -8.0)
	_refrescar()
	_refocar()


func _equipar() -> void:
	if _sel == Galeria.ITEM:
		_abrir_galeria()
		return
	if _sel != "" and EstadoJogo.equipar_item(_sel):
		Som.toca("ui_confirmar", -8.0)
	_refrescar()
	_refocar()


func _abrir_galeria() -> void:
	Som.toca("menu_painel", -12.0)
	var galeria := Galeria.new()
	galeria.fechado.connect(func() -> void: _cartoes.get(_sel, _botoes_cat[_cat]).grab_focus())
	add_child(galeria)


func _refocar() -> void:
	var foco := get_viewport().gui_get_focus_owner()
	if foco == null or not foco.is_visible_in_tree() or (foco is Button and (foco as Button).disabled):
		var alvo: Button = _cartoes.get(_sel, _botoes_cat[_cat])
		alvo.grab_focus()


func _foco_mudou(no: Control) -> void:
	if no == null:
		return
	if is_inside_tree() and not is_ancestor_of(no) and not is_queued_for_deletion():
		var alvo: Button = _cartoes.get(_sel, _botoes_cat[_cat])
		alvo.grab_focus()


func _ajustar_responsivo() -> void:
	if _grelha == null:
		return
	var largura := _area_esquerda.size.x
	var colunas := 5 if largura >= 760.0 else (4 if largura >= 610.0 else 3)
	if _grelha.columns != colunas:
		_grelha.columns = colunas
		_ligar_foco()
	var pequena := get_viewport_rect().size.y <= 720.0
	_det_preview.custom_minimum_size.y = 128 if pequena else 152
	# O Hero mantém a proporção da referência em viewports maiores, sem
	# encolher todo o texto para resolver a responsividade.
	var hero := find_child("FeaturedHero", true, false) as Control
	if hero:
		hero.custom_minimum_size.y = maxf(212.0, _painel_detalhe.size.y * 0.43)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		_fechar()
		get_viewport().set_input_as_handled()


func _fechar() -> void:
	Som.toca("menu_painel", -12.0, 0.92)
	fechado.emit()
	queue_free()
