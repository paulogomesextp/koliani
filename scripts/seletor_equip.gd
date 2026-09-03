class_name SeletorEquip
extends Control
## Ecrã de escolha de arma ou armadura, em CARROSSEL (pedido do Paulo, 3 set
## 2026: "nos menus de arma e de escudo, fazer como selecção de níveis em
## carrossel, e dar uma preview da koliani com essa arma ou equipamento
## equipado e os stats que cada um dá").
##
## Um cartão por item, com a **Koliani lá dentro** a usar o item: o mesmo rig
## do jogo, com o `equipamento.gdshader` a pintar-lhe o fio da lâmina / as
## placas da armadura na cor deste item (ver `koliani.gd::_aplicar_equipamento`).
## O outro canal fica na cor do que está equipado, para se ver o conjunto.
##
## Mostra sempre TODOS os itens do tipo; os que ainda não se ganharam ficam a
## cinzento com o nível que os desbloqueia. Ao lado dos números vai a
## **diferença** para o que está vestido -- é isso que faz decidir.
##
## Aberto pelo menu de Pausa (`configurar("arma")` ou `"armadura"`), corre com
## a árvore em pausa. Sinal `fechado` quando se recua.

signal fechado

const COR_ARMA := Color(0.95, 0.55, 0.45)
const COR_ARMADURA := Color(0.5, 0.7, 0.95)
const TIRA_ARMAS := preload("res://assets/sprites/pixel/gear/armas.png")
const TIRA_ARMADURAS := preload("res://assets/sprites/pixel/gear/armaduras.png")
## As duas tiras NÃO têm a mesma célula: `armas.png` é 640x32 (20 lâminas de
## 32x32) e `armaduras.png` é 270x26 (15 peças de 18x26). Até 4 set 2026 os
## cartões cortavam as duas a 18x26 e as armas saíam em pedaços.
const CELULA_ARMA := Vector2(32, 32)
const CELULA_ARMADURA := Vector2(18, 26)

## Medidas do carrossel -- as mesmas proporções do `SeletorNiveis`.
const CARTAO := Vector2(300, 386)
const PASSO := 336.0          # cartão + intervalo
const DUR := 0.26
const ART_FRAC := 0.62        # fração do cartão ocupada pela preview

## Preview da Koliani: o rig actual, só o `idle`.
const PREVIEW_TIRA := "res://assets/sprites/pixel/koliani_cavaleiro/idle.png"
const PREVIEW_FRAMES := 4
const PREVIEW_FPS := 6.0
const PREVIEW_ESCALA := 3.0

var _tipo := "arma"
var _cor: Color
var _titulo: Label
var _faixa: Control
var _cartoes: Array[Dictionary] = []
var _sel := 0
var _pronto := false
var _equipar: Button
var _dica: Label
var _contagem: Label
var _arrastar_base := 0.0
var _arrastando := false
## SpriteFrames da preview, partilhado por todos os cartões (é sempre a
## mesma tira -- o que muda de cartão para cartão é só o material).
var _frames_preview: SpriteFrames


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_cor = COR_ARMA
	_montar()
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	EstadoJogo.equipamento_mudou.connect(func(_t: String, _i: String) -> void: _refrescar())
	resized.connect(_reposicionar.bind(true))
	get_viewport().size_changed.connect(_reposicionar.bind(true))
	call_deferred("_reposicionar", true)


func configurar(tipo: String) -> void:
	_tipo = tipo
	_cor = COR_ARMA if tipo == "arma" else COR_ARMADURA
	_reconstruir()


# --- construção ------------------------------------------------------

func _montar() -> void:
	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.02, 0.01, 0.03, 0.94)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)

	_titulo = Label.new()
	_titulo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_titulo.position = Vector2(-220, 14)
	_titulo.custom_minimum_size = Vector2(440, 0)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.add_theme_font_size_override("font_size", 26)
	_titulo.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.03))
	_titulo.add_theme_constant_override("outline_size", 6)
	add_child(_titulo)

	_contagem = Label.new()
	_contagem.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_contagem.position = Vector2(-220, 46)
	_contagem.custom_minimum_size = Vector2(440, 0)
	_contagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_contagem.add_theme_font_size_override("font_size", 13)
	_contagem.add_theme_color_override("font_color", Color(0.72, 0.68, 0.8))
	add_child(_contagem)

	_faixa = Control.new()
	_faixa.name = "Faixa"
	_faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_faixa)

	_montar_seta("<", -1, true)
	_montar_seta(">", 1, false)
	_montar_rodape()
	_pronto = true
	_reconstruir()


## Frames da preview -- uma só instância para todos os cartões.
func _montar_frames_preview() -> void:
	if _frames_preview != null:
		return
	var tex: Texture2D = load(PREVIEW_TIRA)
	if tex == null:
		return
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", PREVIEW_FPS)
	sf.set_animation_loop("default", true)
	var fw := tex.get_width() / float(PREVIEW_FRAMES)
	for i in PREVIEW_FRAMES:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * fw, 0, fw, tex.get_height())
		sf.add_frame("default", at)
	_frames_preview = sf


func _lista() -> Array:
	return Equipamento.ARMAS if _tipo == "arma" else Equipamento.ARMADURAS


func _reconstruir() -> void:
	if not _pronto:
		return
	for c: Dictionary in _cartoes:
		(c["raiz"] as Node).queue_free()
	_cartoes.clear()
	_montar_frames_preview()
	var lista := _lista()
	for i in lista.size():
		var c := _fazer_cartao(i, lista[i])
		_faixa.add_child(c["raiz"] as Node)
		_cartoes.append(c)
	# arranca no item equipado (senão no primeiro)
	_sel = maxi(0, _indice_equipado())
	_traduzir()
	_refrescar()
	call_deferred("_reposicionar", true)


func _indice_equipado() -> int:
	var id := EstadoJogo.arma_equipada if _tipo == "arma" else EstadoJogo.armadura_equipada
	return Equipamento.indice_arma(id) if _tipo == "arma" else Equipamento.indice_armadura(id)


func _fazer_cartao(i: int, item: Dictionary) -> Dictionary:
	var art_h := CARTAO.y * ART_FRAC

	var raiz := Control.new()
	raiz.custom_minimum_size = CARTAO
	raiz.size = CARTAO
	raiz.pivot_offset = CARTAO * 0.5
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP

	var painel := Panel.new()
	painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(painel)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.05, 0.1, 0.98)
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(2)
	sb.border_color = Color(_cor.r, _cor.g, _cor.b, 0.4)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 16
	sb.shadow_offset = Vector2(0, 8)
	var sb_sel := sb.duplicate() as StyleBoxFlat
	sb_sel.set_border_width_all(3)
	sb_sel.border_color = _cor.lightened(0.2)
	sb_sel.shadow_color = Color(_cor.r, _cor.g, _cor.b, 0.42)
	sb_sel.shadow_size = 22
	sb_sel.shadow_offset = Vector2.ZERO
	painel.add_theme_stylebox_override("panel", sb)

	# --- zona da preview -------------------------------------------------
	var clip := Control.new()
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.position = Vector2(3, 3)
	clip.size = Vector2(CARTAO.x - 6, art_h)
	raiz.add_child(clip)

	# clarão por trás da Koliani, na cor do item
	var halo := TextureRect.new()
	halo.set_anchors_preset(Control.PRESET_FULL_RECT)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cor_item: Color = Equipamento.cor_arma(i) if _tipo == "arma" else Equipamento.cor_armadura(i)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(cor_item.r, cor_item.g, cor_item.b, 0.34),
		Color(0.05, 0.03, 0.09, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.62)
	gt.fill_to = Vector2(1.0, 1.05)
	halo.texture = gt
	halo.stretch_mode = TextureRect.STRETCH_SCALE
	clip.add_child(halo)

	# a Koliani, com o shader a vestir-lhe este item
	var koli: AnimatedSprite2D = null
	var mat: ShaderMaterial = null
	if _frames_preview:
		koli = AnimatedSprite2D.new()
		koli.sprite_frames = _frames_preview
		koli.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		koli.scale = Vector2(PREVIEW_ESCALA, PREVIEW_ESCALA)
		koli.position = Vector2((CARTAO.x - 6) * 0.5, art_h * 0.60)
		var sh: Shader = load("res://assets/shaders/equipamento.gdshader")
		if sh:
			mat = ShaderMaterial.new()
			mat.shader = sh
			koli.material = mat
		clip.add_child(koli)
		koli.play("default")

	# o asset do item, grande, no canto
	# NB: a arma indexa a tira pela posição na lista; a armadura NÃO -- a tira
	# tem as 15 originais e só 10 estão em jogo (ver `celula_armadura`).
	var celula: int = i if _tipo == "arma" else Equipamento.celula_armadura(item["id"])
	var cel: Vector2 = CELULA_ARMA if _tipo == "arma" else CELULA_ARMADURA
	var icone := TextureRect.new()
	icone.name = "Icone"
	var at := AtlasTexture.new()
	at.atlas = TIRA_ARMAS if _tipo == "arma" else TIRA_ARMADURAS
	at.region = Rect2(maxi(0, celula) * cel.x, 0, cel.x, cel.y)
	icone.texture = at
	icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.size = Vector2(cel.x * 2.8, cel.y * 2.8)
	icone.position = Vector2(CARTAO.x - 6 - icone.size.x - 10, art_h - icone.size.y - 10)
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(icone)

	# scrim -> o texto lê-se por cima da preview
	var scrim := TextureRect.new()
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g2 := Gradient.new()
	g2.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	g2.colors = PackedColorArray([Color(0.05, 0.04, 0.09, 0.0),
		Color(0.06, 0.04, 0.1, 0.5), Color(0.06, 0.04, 0.1, 0.98)])
	var gt2 := GradientTexture2D.new()
	gt2.gradient = g2
	gt2.fill_from = Vector2(0.5, 0.0)
	gt2.fill_to = Vector2(0.5, 1.0)
	scrim.texture = gt2
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	clip.add_child(scrim)

	# --- badge do número --------------------------------------------------
	var badge := Label.new()
	badge.text = "%02d" % (i + 1)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.size = Vector2(42, 28)
	badge.position = Vector2(12, 12)
	badge.add_theme_font_size_override("font_size", 15)
	badge.add_theme_color_override("font_color", Color(0.06, 0.04, 0.08))
	var sbb := StyleBoxFlat.new()
	sbb.bg_color = _cor
	sbb.set_corner_radius_all(8)
	badge.add_theme_stylebox_override("normal", sbb)
	raiz.add_child(badge)

	# --- pastilha de estado ----------------------------------------------
	var pill := Label.new()
	pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_theme_font_size_override("font_size", 12)
	pill.size = Vector2(112, 26)
	pill.position = Vector2(CARTAO.x - 12 - 112, 13)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(pill)

	# --- informação -------------------------------------------------------
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 5)
	info.position = Vector2(18, art_h + 2)
	info.size = Vector2(CARTAO.x - 36, CARTAO.y - art_h - 14)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var nome := Label.new()
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nome.custom_minimum_size = Vector2(CARTAO.x - 36, 0)
	nome.add_theme_font_size_override("font_size", 21)
	nome.add_theme_color_override("font_color", Color(0.98, 0.95, 1))
	nome.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.03))
	nome.add_theme_constant_override("outline_size", 4)
	info.add_child(nome)

	var stat := Label.new()
	stat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stat.custom_minimum_size = Vector2(CARTAO.x - 36, 0)
	stat.add_theme_font_size_override("font_size", 14)
	info.add_child(stat)

	var delta := Label.new()
	delta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	delta.custom_minimum_size = Vector2(CARTAO.x - 36, 0)
	delta.add_theme_font_size_override("font_size", 13)
	info.add_child(delta)
	raiz.add_child(info)

	raiz.gui_input.connect(_cartao_input.bind(i))

	return {
		"raiz": raiz, "indice": i, "id": str(item["id"]), "item": item,
		"painel": painel, "sb_normal": sb, "sb_sel": sb_sel, "em_destaque": false,
		"pill": pill, "nome": nome, "stat": stat, "delta": delta,
		"koli": koli, "mat": mat, "icone": icone, "halo": halo,
	}


func _montar_seta(txt: String, dir: int, esquerda: bool) -> void:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 34)
	b.add_theme_color_override("font_color", Color(0.97, 0.9, 1))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.06, 0.14, 0.85)
	sb.set_corner_radius_all(36)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.7, 0.45, 0.8, 0.75)
	sb.shadow_color = Color(0.6, 0.3, 0.7, 0.25)
	sb.shadow_size = 6
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.24, 0.12, 0.28, 0.95)
	sb_hover.border_color = Color(0.95, 0.55, 0.92, 1)
	sb_hover.shadow_color = Color(0.9, 0.4, 0.85, 0.5)
	sb_hover.shadow_size = 14
	b.add_theme_stylebox_override("normal", sb)
	for e in ["hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(e, sb_hover)
	b.anchor_top = 0.5
	b.anchor_bottom = 0.5
	b.offset_top = -36.0
	b.offset_bottom = 36.0
	if esquerda:
		b.anchor_left = 0.0
		b.anchor_right = 0.0
		b.offset_left = 14.0
		b.offset_right = 86.0
	else:
		b.anchor_left = 1.0
		b.anchor_right = 1.0
		b.offset_left = -86.0
		b.offset_right = -14.0
	b.pivot_offset = Vector2(36, 36)
	b.pressed.connect(_mover.bind(dir))
	add_child(b)


func _montar_rodape() -> void:
	_dica = Label.new()
	_dica.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_dica.position = Vector2(-260, -92)
	_dica.custom_minimum_size = Vector2(520, 0)
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dica.add_theme_font_size_override("font_size", 13)
	_dica.add_theme_color_override("font_color", Color(0.72, 0.68, 0.8))
	add_child(_dica)

	_equipar = Button.new()
	_equipar.focus_mode = Control.FOCUS_NONE
	_equipar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_equipar.position = Vector2(-186, -62)
	_equipar.custom_minimum_size = Vector2(180, 46)
	_estilo_botao(_equipar, true)
	_equipar.pressed.connect(_confirmar)
	add_child(_equipar)

	var voltar := Button.new()
	voltar.name = "Voltar"
	voltar.focus_mode = Control.FOCUS_NONE
	voltar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	voltar.position = Vector2(12, -62)
	voltar.custom_minimum_size = Vector2(160, 46)
	_estilo_botao(voltar, false)
	voltar.pressed.connect(func() -> void: fechado.emit())
	add_child(voltar)


func _estilo_botao(b: Button, principal: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.08, 0.2, 0.95) if principal else Color(0.1, 0.07, 0.13, 0.9)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.95, 0.55, 0.92) if principal else Color(0.55, 0.4, 0.62)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	var sb_off := sb.duplicate() as StyleBoxFlat
	sb_off.bg_color = Color(0.08, 0.07, 0.09, 0.85)
	sb_off.border_color = Color(0.28, 0.26, 0.32)
	for e in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(e, sb)
	b.add_theme_stylebox_override("disabled", sb_off)
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", Color(1, 0.92, 0.99))
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.43, 0.5))


# --- estado ----------------------------------------------------------

func _tem(id: String) -> bool:
	return EstadoJogo.tem_arma(id) if _tipo == "arma" else EstadoJogo.tem_armadura(id)


func _equipado_id() -> String:
	return EstadoJogo.arma_equipada if _tipo == "arma" else EstadoJogo.armadura_equipada


## Preenche os textos, pinta a preview e acerta o botão. Corre de novo
## sempre que se equipa alguma coisa (o "EQUIPADO" muda de cartão e as
## diferenças passam a ser contra o item novo).
func _refrescar() -> void:
	if not _pronto or _cartoes.is_empty():
		return
	var equip := _equipado_id()
	var tenho := 0
	# o canal do OUTRO tipo é sempre o que está vestido, para se ver o conjunto
	var outro_i: int = Equipamento.indice_armadura(EstadoJogo.armadura_equipada) if _tipo == "arma" \
		else Equipamento.indice_arma(EstadoJogo.arma_equipada)
	for c: Dictionary in _cartoes:
		var item: Dictionary = c["item"]
		var id: String = c["id"]
		var i: int = c["indice"]
		var tem := _tem(id)
		var e := id == equip
		if tem:
			tenho += 1
		var nome := c["nome"] as Label
		nome.text = Textos.t(item["nome"])
		nome.add_theme_color_override("font_color",
			Color(0.98, 0.95, 1) if tem else Color(0.55, 0.54, 0.6))
		var stat := c["stat"] as Label
		stat.text = _texto_stats(item)
		stat.add_theme_color_override("font_color", _cor if tem else Color(0.45, 0.45, 0.5))
		_pintar_delta(c["delta"] as Label, item, e, tem)
		_pintar_pill(c["pill"] as Label, item, e, tem)
		# a preview veste este item; o outro slot fica no que está equipado
		var mat := c["mat"] as ShaderMaterial
		if mat:
			var i_arma: int = i if _tipo == "arma" else outro_i
			var i_armadura: int = outro_i if _tipo == "arma" else i
			mat.set_shader_parameter("cor_arma", Equipamento.cor_arma(i_arma))
			mat.set_shader_parameter("peso_arma", 1.0 if i_arma >= 0 else 0.0)
			mat.set_shader_parameter("cor_armadura", Equipamento.cor_armadura(i_armadura))
			mat.set_shader_parameter("peso_armadura", 1.0 if i_armadura >= 0 else 0.0)
		var koli := c["koli"] as AnimatedSprite2D
		if koli:
			koli.modulate = Color(1.1, 1.08, 1.16) if tem else Color(0.3, 0.29, 0.36)
		(c["icone"] as TextureRect).modulate = Color(1, 1, 1) if tem else Color(0.34, 0.34, 0.4, 0.7)
		(c["halo"] as TextureRect).modulate = Color(1, 1, 1) if tem else Color(0.35, 0.35, 0.4)
	if _contagem:
		_contagem.text = Textos.tf("sel.count", [tenho, _cartoes.size()])
	_atualizar_botao()


func _texto_stats(item: Dictionary) -> String:
	if _tipo == "arma":
		return Textos.tf("gear.stat.dmg", [int(item["dano"])])
	var partes: Array[String] = []
	if int(item["vida_bonus"]) > 0:
		partes.append(Textos.tf("gear.stat.hp", [int(item["vida_bonus"])]))
	if float(item["reducao"]) > 0.0:
		partes.append(Textos.tf("gear.stat.armor", [int(round(float(item["reducao"]) * 100.0))]))
	return "   -   ".join(partes) if not partes.is_empty() else "--"


## "+12 DMG" / "-3% dmg cut" contra o que está vestido -- é a linha que faz
## decidir. No item já equipado não há nada a comparar.
func _pintar_delta(lbl: Label, item: Dictionary, equipada: bool, tem: bool) -> void:
	if equipada or not tem:
		lbl.text = ""
		return
	var eq_id := _equipado_id()
	var eq: Dictionary = Equipamento.arma(eq_id) if _tipo == "arma" else Equipamento.armadura(eq_id)
	if eq.is_empty():
		lbl.text = ""
		return
	var partes: Array[String] = []
	var bom := true
	if _tipo == "arma":
		var d := int(item["dano"]) - int(eq["dano"])
		if d == 0:
			lbl.text = ""
			return
		bom = d > 0
		partes.append("%s%d %s" % ["+" if d > 0 else "-", absi(d), Textos.t("gear.d.dmg")])
	else:
		var dv := int(item["vida_bonus"]) - int(eq["vida_bonus"])
		var dr := int(round((float(item["reducao"]) - float(eq["reducao"])) * 100.0))
		if dv != 0:
			partes.append("%s%d %s" % ["+" if dv > 0 else "-", absi(dv), Textos.t("gear.d.hp")])
		if dr != 0:
			partes.append("%s%d%% %s" % ["+" if dr > 0 else "-", absi(dr), Textos.t("gear.d.armor")])
		if partes.is_empty():
			lbl.text = ""
			return
		bom = (dv + dr) > 0
	lbl.text = "  -  ".join(partes)
	lbl.add_theme_color_override("font_color",
		Color(0.55, 0.95, 0.62) if bom else Color(0.95, 0.5, 0.5))


func _pintar_pill(pill: Label, item: Dictionary, equipada: bool, tem: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(13)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	if equipada:
		pill.text = Textos.t("gear.equipped")
		sb.bg_color = Color(0.98, 0.82, 0.35, 0.92)
		pill.add_theme_color_override("font_color", Color(0.1, 0.06, 0.02))
	elif tem:
		pill.text = Textos.t("gear.equip")
		sb.bg_color = Color(_cor.r, _cor.g, _cor.b, 0.32)
		pill.add_theme_color_override("font_color", Color(0.98, 0.95, 1))
	else:
		pill.text = Textos.tf("gear.locked", [int(item["nivel"])])
		sb.bg_color = Color(0.12, 0.12, 0.15, 0.9)
		pill.add_theme_color_override("font_color", Color(0.62, 0.62, 0.68))
	pill.add_theme_stylebox_override("normal", sb)


func _atualizar_botao() -> void:
	if _equipar == null or _cartoes.is_empty():
		return
	var c: Dictionary = _cartoes[_sel]
	var tem := _tem(c["id"])
	var e: bool = c["id"] == _equipado_id()
	_equipar.disabled = not tem or e
	_equipar.text = Textos.t("gear.equipped") if e else Textos.t("gear.equip")


func _traduzir() -> void:
	if _titulo:
		_titulo.text = Textos.t("gear.title.weapons" if _tipo == "arma" else "gear.title.armor")
		_titulo.add_theme_color_override("font_color", _cor)
	if _dica:
		_dica.text = Textos.t("gear.hint")
	var voltar := find_child("Voltar", true, false) as Button
	if voltar:
		voltar.text = Textos.t("gear.back")


# --- carrossel -------------------------------------------------------

func _reposicionar(instantaneo: bool) -> void:
	if not _pronto or _cartoes.is_empty() or size.x < 200.0:
		return
	var centro := size * 0.5
	for i in _cartoes.size():
		var raiz := _cartoes[i]["raiz"] as Control
		var alvo := Vector2(centro.x - CARTAO.x * 0.5 + (i - _sel) * PASSO,
			centro.y - CARTAO.y * 0.5 + 6.0)
		var dist: int = absi(i - _sel)
		var escala := 1.0
		var alpha := 1.0
		if dist == 1:
			escala = 0.82
			alpha = 0.55
			alvo.y += 16.0
		elif dist >= 2:
			escala = 0.7
			alpha = 0.0
			alvo.y += 24.0
		var destaque := dist == 0
		if destaque != _cartoes[i]["em_destaque"]:
			_cartoes[i]["em_destaque"] = destaque
			var painel := _cartoes[i]["painel"] as Panel
			painel.add_theme_stylebox_override("panel",
				_cartoes[i]["sb_sel"] if destaque else _cartoes[i]["sb_normal"])
		raiz.mouse_filter = Control.MOUSE_FILTER_STOP if dist <= 1 else Control.MOUSE_FILTER_IGNORE
		# os cartões que não se veem não animam a Koliani
		var koli := _cartoes[i]["koli"] as AnimatedSprite2D
		if koli:
			if dist <= 1 and not koli.is_playing():
				koli.play("default")
			elif dist > 1 and koli.is_playing():
				koli.stop()
		if instantaneo:
			raiz.position = alvo
			raiz.scale = Vector2(escala, escala)
			raiz.modulate.a = alpha
		else:
			var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			t.tween_property(raiz, "position", alvo, DUR)
			t.tween_property(raiz, "scale", Vector2(escala, escala), DUR)
			t.tween_property(raiz, "modulate:a", alpha, DUR)
		raiz.z_index = 10 - dist
	_atualizar_botao()


func _mover(dir: int) -> void:
	_ir_para(_sel + dir)


func _ir_para(indice: int) -> void:
	var novo := clampi(indice, 0, _cartoes.size() - 1)
	if novo == _sel:
		return
	_sel = novo
	Som.toca("carrossel", -12.0, randf_range(0.97, 1.05))
	_reposicionar(false)


func _confirmar() -> void:
	if _cartoes.is_empty():
		return
	var c: Dictionary = _cartoes[_sel]
	var id: String = c["id"]
	if not _tem(id) or id == _equipado_id():
		Som.toca("dano", -18.0, 0.8)
		var raiz := c["raiz"] as Control
		var x := raiz.position.x
		var t := create_tween()
		t.tween_property(raiz, "position:x", x + 8, 0.04)
		t.tween_property(raiz, "position:x", x - 8, 0.04)
		t.tween_property(raiz, "position:x", x, 0.04)
		return
	if _tipo == "arma":
		EstadoJogo.equipar_arma(id)
	else:
		EstadoJogo.equipar_armadura(id)
	Som.toca("apanhar", -10.0, 1.1)


func _cartao_input(evento: InputEvent, indice: int) -> void:
	if evento is InputEventMouseButton and evento.pressed \
			and (evento as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if indice == _sel:
			_confirmar()
		else:
			_ir_para(indice)


## Arrastar com o dedo -- um cartão por cada `PASSO * 0.45` percorridos.
func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventScreenDrag:
		_arrastar((evento as InputEventScreenDrag).position.x)
	elif evento is InputEventMouseMotion and _arrastando:
		_arrastar((evento as InputEventMouseMotion).position.x)
	elif evento is InputEventScreenTouch:
		var t := evento as InputEventScreenTouch
		_arrastando = t.pressed
		_arrastar_base = t.position.x
	elif evento is InputEventMouseButton:
		var m := evento as InputEventMouseButton
		if m.button_index == MOUSE_BUTTON_LEFT:
			_arrastando = m.pressed
			_arrastar_base = m.position.x


func _arrastar(x: float) -> void:
	if absf(x - _arrastar_base) > PASSO * 0.45:
		_ir_para(_sel + (-1 if x > _arrastar_base else 1))
		_arrastar_base = x


func _unhandled_input(evento: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if evento.is_action_pressed("pausa") or evento.is_action_pressed("ui_cancel"):
		fechado.emit()
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("ui_left"):
		_mover(-1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("ui_right"):
		_mover(1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("ui_accept"):
		_confirmar()
		get_viewport().set_input_as_handled()
