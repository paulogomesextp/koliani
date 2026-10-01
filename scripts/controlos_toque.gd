extends CanvasLayer
## HUD: barra de vida + vidas (sempre visíveis) e os botões de toque
## (`Toque`), que só aparecem em ecrã táctil / ao primeiro toque. Mostra
## também avisos curtos ao ganhar habilidade ou encontrar pista.

## chave de tradução do nome de cada habilidade (ver assets/i18n)
const NOME_HABILIDADE := {
	"salto_duplo": "hud.ability.salto_duplo",
	"dash": "hud.ability.dash",
	"dash_aereo": "hud.ability.dash_aereo",
	"partir_paredes": "hud.ability.partir_paredes",
	"escudo": "hud.ability.escudo",
	"projetil": "hud.ability.projetil",
	"especial": "hud.ability.especial",
	"escalar_paredes": "hud.ability.escalar_paredes",
}

const BarraHud := preload("res://scripts/barra_hud.gd")

@onready var _toque: Control = $Toque

## Bloco de estado da Koliani (canto sup. esquerdo): retrato, vida, energia, vidas.
var _vitais: Control
var _barra_vida: Control
var _barra_energia: Control
var _label_vidas: Label
var _retrato: Control
var _vida_anterior := -1

## Barra de vida do chefe (construída em runtime, ao fundo do ecrã).
var _chefe_caixa: Control
var _chefe_nome: Label
var _chefe_barra: ProgressBar
var _chefe_fim := false
var _chefe_tween: Tween


## Legenda dos controlos, no topo do ecrã (só sem ecrã táctil -- em táctil
## os botões de toque já bastam). Cada linha: [chave i18n, ação no InputMap].
const LEGENDA_CONTROLOS := [
	["hud.controls.move", "mover_direita"],
	["hud.controls.jump", "saltar"],
	["hud.controls.attack", "atacar"],
	["hud.controls.dash", "dash"],
	["hud.controls.roll", "rolar"],
	["hud.controls.guard", "defender"],
	["hud.controls.throw", "lancar"],
	["hud.controls.pause", "pausa"],
]
var _legenda_caixa: HBoxContainer
var _cab_nivel: VBoxContainer


func _ready() -> void:
	add_to_group("hud_9f")   # toasts de feedback (ex.: checkpoint.gd)
	$Versao.text = "v" + str(ProjectSettings.get_setting("application/config/version", ""))
	if _toque:
		_toque.visible = DisplayServer.is_touchscreen_available()
	# a barra de Energia só aparece depois de apanhar a habilidade "projetil"
	if _barra_energia:
		_barra_energia.get_parent().visible = EstadoJogo.tem_habilidade("projetil") or EstadoJogo.tem_habilidade("especial")
	EstadoJogo.vidas_mudaram.connect(_atualizar_vidas)
	EstadoJogo.habilidade_desbloqueada.connect(_ao_habilidade)
	EstadoJogo.pista_encontrada.connect(_ao_pista)
	EstadoJogo.mecanica_estreou.connect(_ao_mecanica)
	_montar_vitais()
	_atualizar_vidas(EstadoJogo.vidas)
	var koliani := get_tree().get_first_node_in_group("koliani")
	if koliani and koliani.has_signal("vida_mudou"):
		koliani.vida_mudou.connect(_atualizar_barra_vida)
	if koliani and koliani.has_signal("energia_mudou"):
		koliani.energia_mudou.connect(_atualizar_energia)
	if koliani and koliani.has_signal("energia_insuficiente"):
		koliani.energia_insuficiente.connect(_piscar_energia)
	_montar_barra_chefe()
	var chefe := get_tree().get_first_node_in_group("chefes")
	if chefe and chefe.has_signal("combate_iniciado"):
		chefe.combate_iniciado.connect(_ao_combate_chefe)
		chefe.vida_mudou.connect(_atualizar_barra_chefe)
		chefe.derrotado.connect(_ao_chefe_derrotado)
		chefe.tree_exited.connect(_ao_chefe_derrotado)

	_montar_contador_moedas()
	EstadoJogo.moedas_loja_mudaram.connect(_atualizar_moedas)
	_atualizar_moedas()

	_arrumar_para_toque()
	_montar_legenda_controlos()
	_montar_cabecalho_nivel()
	Textos.idioma_mudou.connect(func(_l: String) -> void:
		_encher_legenda()
		_encher_cabecalho_nivel())


# --- barra de vida do chefe ------------------------------------------

func _montar_barra_chefe() -> void:
	_chefe_caixa = Control.new()
	_chefe_caixa.name = "BarraChefe"
	_chefe_caixa.anchor_left = 0.5
	_chefe_caixa.anchor_right = 0.5
	_chefe_caixa.anchor_top = 1.0
	_chefe_caixa.anchor_bottom = 1.0
	# 600 de largura (era 760): a 760 a placa passava por cima da barra de
	# vida e dos botoes WEAPONS/ARMOR, que vivem no mesmo canto.
	_chefe_caixa.offset_left = -300.0
	_chefe_caixa.offset_right = 300.0
	# a placa cresceu: leva a caveira + o nome numa linha e a barra noutra
	_chefe_caixa.offset_top = -124.0
	_chefe_caixa.offset_bottom = -44.0
	_chefe_caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chefe_caixa.modulate.a = 0.0
	_chefe_caixa.visible = false
	add_child(_chefe_caixa)

	# placa de pedra tocada a sangue por trás de tudo (`UI.painel`)
	var placa := PanelContainer.new()
	placa.set_anchors_preset(Control.PRESET_FULL_RECT)
	placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# 9H.11: a moldura pintada `painel_detalhe` tem 70 px de margem de cada
	# lado -- numa placa de 60 px de alto as quinas encontram-se e o que se
	# via eram lascas da pintura à volta da barra. Caixa lisa da mesma
	# família (ver `Frontend9H.painel_liso`).
	var sb_chefe := Frontend9H.painel_liso(0.80)
	sb_chefe.content_margin_left = 26
	sb_chefe.content_margin_right = 26
	sb_chefe.content_margin_top = 10
	sb_chefe.content_margin_bottom = 12
	sb_chefe.shadow_size = 14
	placa.add_theme_stylebox_override("panel", sb_chefe)
	_chefe_caixa.add_child(placa)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa.add_child(col)

	var titulo := HBoxContainer.new()
	titulo.alignment = BoxContainer.ALIGNMENT_CENTER
	titulo.add_theme_constant_override("separation", 7)
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(titulo)
	titulo.add_child(UI.icone("ico_caveira", 16, Color(1, 0.8, 0.8)))

	_chefe_nome = Label.new()
	_chefe_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chefe_nome.add_theme_font_size_override("font_size", 16)
	_chefe_nome.add_theme_color_override("font_color", Color(0.98, 0.86, 0.86))
	_chefe_nome.add_theme_color_override("font_outline_color", Color(0.05, 0.01, 0.02))
	_chefe_nome.add_theme_constant_override("outline_size", 5)
	titulo.add_child(_chefe_nome)

	_chefe_barra = ProgressBar.new()
	_chefe_barra.custom_minimum_size = Vector2(0, 30)
	_chefe_barra.show_percentage = false
	_chefe_barra.min_value = 0.0
	_chefe_barra.max_value = 1.0
	_chefe_barra.value = 1.0
	col.add_child(_chefe_barra)
	UIProducao.vestir_barra(_chefe_barra, "chefe")


func _ao_combate_chefe(chefe: Node) -> void:
	var nome := ""
	var i: int = EstadoJogo.indice_nivel
	if i >= 0 and i < CatalogoCampanha.CHEFE_KEY.size():
		nome = Textos.t(CatalogoCampanha.CHEFE_KEY[i])
	if _chefe_nome:
		_chefe_nome.text = nome.to_upper()
	if _chefe_caixa:
		_chefe_caixa.visible = true
		var t := create_tween()
		t.tween_property(_chefe_caixa, "modulate:a", 1.0, 0.4)


func _atualizar_barra_chefe(atual: int, maximo: int) -> void:
	if not _chefe_barra or _chefe_fim:
		return
	var alvo: float = clampf(float(atual) / float(maxi(maximo, 1)), 0.0, 1.0)
	if _chefe_tween and _chefe_tween.is_valid():
		_chefe_tween.kill()
	_chefe_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_chefe_tween.tween_property(_chefe_barra, "value", alvo, 0.25)


func _ao_chefe_derrotado() -> void:
	if _chefe_fim or not _chefe_caixa or not _chefe_caixa.visible:
		return
	_chefe_fim = true
	if _chefe_tween and _chefe_tween.is_valid():
		_chefe_tween.kill()
	var t := create_tween()
	t.tween_property(_chefe_barra, "value", 0.0, 0.2)
	t.parallel().tween_property(_chefe_caixa, "modulate:a", 0.0, 0.5)
	t.tween_callback(func() -> void: _chefe_caixa.visible = false)


# --- legenda dos controlos (topo do ecrã) --------------------------

## Contador de KOLICOINS (a moeda da Loja, ganha a jogar) no canto sup.
## direito: pastilha de vidro com uma moeda de ouro desenhada à mão. Pisa e
## treme quando sobe.
var _moedas_label: Label
var _moedas_caixa: PanelContainer
var _moedas_total := -1

func _montar_contador_moedas() -> void:
	var caixa := PanelContainer.new()
	caixa.name = "Kolicoins"
	_moedas_caixa = caixa
	caixa.anchor_left = 1.0
	caixa.anchor_right = 1.0
	caixa.offset_top = 14.0
	caixa.offset_right = -16.0
	caixa.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_theme_stylebox_override("panel", _vidro(20, Vector4(10, 5, 16, 5)))
	add_child(caixa)

	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(linha)

	var moeda := Control.new()
	moeda.custom_minimum_size = Vector2(26, 26)
	moeda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moeda.draw.connect(func() -> void:
		var c := Vector2(13, 13)
		moeda.draw_circle(c, 12.0, Color(0.62, 0.38, 0.08))
		moeda.draw_circle(c, 10.6, Color(0.98, 0.78, 0.28))
		moeda.draw_arc(c, 7.4, 0.0, TAU, 28, Color(0.72, 0.46, 0.1), 1.6, true)
		moeda.draw_circle(c + Vector2(-3.5, -4.0), 2.4, Color(1, 0.96, 0.78, 0.8)))
	linha.add_child(moeda)

	_moedas_label = Label.new()
	_moedas_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_moedas_label.custom_minimum_size.x = 36
	_moedas_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_moedas_label.add_theme_font_size_override("font_size", 19)
	_moedas_label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.7))
	_moedas_label.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.04))
	_moedas_label.add_theme_constant_override("outline_size", 4)
	linha.add_child(_moedas_label)


func _atualizar_moedas() -> void:
	if _moedas_label == null:
		return
	var total: int = EstadoJogo.kolicoins
	_moedas_label.text = "%d" % total
	if _moedas_total >= 0 and total > _moedas_total and _moedas_caixa and is_inside_tree():
		_moedas_caixa.pivot_offset = _moedas_caixa.size * 0.5
		var t := create_tween()
		t.tween_property(_moedas_caixa, "scale", Vector2(1.14, 1.14), 0.06)
		t.tween_property(_moedas_caixa, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_moedas_total = total


## Caixa de "vidro" escuro e arredondado: a base de todas as peças do HUD novo.
func _vidro(raio: int, margens := Vector4(12, 6, 12, 6), cor_borda := Color(1, 1, 1, 0.14)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.02, 0.07, 0.72)
	sb.set_corner_radius_all(raio)
	sb.set_border_width_all(1)
	sb.border_color = cor_borda
	sb.anti_aliasing = true
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.content_margin_left = margens.x
	sb.content_margin_top = margens.y
	sb.content_margin_right = margens.z
	sb.content_margin_bottom = margens.w
	return sb


# --- bloco de estado da Koliani (canto sup. esquerdo) ---------------

const VITAIS_TAM := Vector2(330.0, 84.0)

func _montar_vitais() -> void:
	var cor_regiao := EstadoJogo.cor_regiao_do_nivel(EstadoJogo.indice_nivel)
	_vitais = Control.new()
	_vitais.name = "Vitais"
	_vitais.position = Vector2(16.0, 14.0)
	_vitais.size = VITAIS_TAM
	_vitais.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vitais)

	# retrato redondo: o rosto da Koliani (com a skin equipada) numa moldura
	# com o aro na cor da região
	var disco := Panel.new()
	disco.name = "Retrato"
	disco.position = Vector2(0, 0)
	disco.size = Vector2(76, 76)
	disco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.05, 0.13, 0.95)
	sb.set_corner_radius_all(38)
	sb.anti_aliasing = true
	disco.add_theme_stylebox_override("panel", sb)
	disco.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_vitais.add_child(disco)
	_retrato = disco
	var tex := _textura_retrato()
	if tex:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.position = Vector2(-4, -2)
		tr.size = Vector2(84, 84)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		disco.add_child(tr)
	var aro := Control.new()
	aro.set_anchors_preset(Control.PRESET_FULL_RECT)
	aro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aro.draw.connect(func() -> void:
		aro.draw_arc(Vector2(38, 38), 36.0, 0.0, TAU, 56, Color(0.02, 0.01, 0.05, 0.9), 5.0, true)
		aro.draw_arc(Vector2(38, 38), 36.0, 0.0, TAU, 56, cor_regiao.lightened(0.25), 3.0, true))
	_vitais.add_child(aro)

	# insígnia das vidas, a morder o canto do retrato
	var insignia := Control.new()
	insignia.position = Vector2(48, 50)
	insignia.size = Vector2(34, 30)
	insignia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vitais.add_child(insignia)
	var fundo := Panel.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_theme_stylebox_override("panel", _vidro(15, Vector4(0, 0, 0, 0), Color(1, 0.6, 0.65, 0.5)))
	insignia.add_child(fundo)
	var ic := UIProducao.icone("ico_coracao", 14)
	ic.position = Vector2(5, 8)
	insignia.add_child(ic)
	_label_vidas = Label.new()
	_label_vidas.position = Vector2(20, 3)
	_label_vidas.size = Vector2(14, 24)
	_label_vidas.add_theme_font_size_override("font_size", 15)
	_label_vidas.add_theme_color_override("font_color", Color(1, 0.92, 0.94))
	_label_vidas.add_theme_color_override("font_outline_color", Color(0.05, 0.01, 0.02))
	_label_vidas.add_theme_constant_override("outline_size", 4)
	insignia.add_child(_label_vidas)

	# barra de vida (larga) e de energia (fina) ao lado do retrato
	_barra_vida = BarraHud.new()
	_barra_vida.name = "BarraVida"
	_barra_vida.position = Vector2(88, 12)
	_barra_vida.size = Vector2(238, 24)
	_barra_vida.cor = Color(0.9, 0.17, 0.27)
	_vitais.add_child(_barra_vida)

	_barra_energia = BarraHud.new()
	_barra_energia.name = "BarraEnergia"
	_barra_energia.position = Vector2(88, 42)
	_barra_energia.size = Vector2(176, 12)
	_barra_energia.cor = Color(0.33, 0.62, 1.0)
	_barra_energia.cor_baixa = Color(0.33, 0.62, 1.0)
	_barra_energia.mostrar_numero = false
	# cada terço e' um uso do Especial (custo 33 de 99)
	_barra_energia.marcas.assign([1.0 / 3.0, 2.0 / 3.0])
	_vitais.add_child(_barra_energia)


## Primeiro fotograma de `idle` do corpo da Koliani (segue a skin equipada).
func _textura_retrato() -> Texture2D:
	var k := get_tree().get_first_node_in_group("koliani")
	var corpo := k.get_node_or_null("Sprite/Corpo") as AnimatedSprite2D if k else null
	if corpo == null or corpo.sprite_frames == null:
		return null
	var anim: StringName = "idle" if corpo.sprite_frames.has_animation("idle") else corpo.animation
	var tex := corpo.sprite_frames.get_frame_texture(anim, 0)
	if tex == null:
		return null
	# recorte da cabeça e ombros (o fotograma é 128x128, a figura ocupa o meio)
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(41, 31, 46, 46)
	return at


func _montar_legenda_controlos() -> void:
	# Ajuda opcional; não ocupa permanentemente o HUD de produção.
	if not ProjectSettings.get_setting("koliani/ui/mostrar_legenda_controlos", false) or DisplayServer.is_touchscreen_available():
		return
	var faixa := Control.new()
	faixa.name = "LegendaControlos"
	faixa.anchor_right = 1.0
	faixa.offset_top = 6.0
	faixa.offset_bottom = 34.0
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(faixa)

	_legenda_caixa = HBoxContainer.new()
	_legenda_caixa.set_anchors_preset(Control.PRESET_FULL_RECT)
	_legenda_caixa.alignment = BoxContainer.ALIGNMENT_CENTER
	_legenda_caixa.add_theme_constant_override("separation", 12)
	_legenda_caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faixa.add_child(_legenda_caixa)
	_encher_legenda()


func _encher_legenda() -> void:
	if _legenda_caixa == null:
		return
	for c in _legenda_caixa.get_children():
		c.queue_free()
	for par: Array in LEGENDA_CONTROLOS:
		_legenda_caixa.add_child(_item_legenda(Textos.t(par[0]), _tecla_de(par[0], par[1])))


## Um par "tecla + rótulo" da legenda.
func _item_legenda(rotulo: String, tecla: String) -> Control:
	var it := HBoxContainer.new()
	it.add_theme_constant_override("separation", 4)
	it.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var chip := Label.new()
	chip.text = tecla
	chip.add_theme_font_size_override("font_size", 12)
	chip.add_theme_color_override("font_color", Color(0.08, 0.04, 0.1))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.85, 0.78, 0.92, 0.92)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	chip.add_theme_stylebox_override("normal", sb)
	it.add_child(chip)

	var txt := Label.new()
	txt.text = rotulo
	txt.add_theme_font_size_override("font_size", 12)
	txt.add_theme_color_override("font_color", Color(0.92, 0.86, 0.98))
	txt.add_theme_color_override("font_outline_color", Color(0.03, 0.01, 0.05))
	txt.add_theme_constant_override("outline_size", 3)
	it.add_child(txt)
	return it


## Nome curto da tecla ligada a uma ação (lê o InputMap, por isso segue
## remapeamentos). "move" mostra o par esquerda/direita.
func _tecla_de(chave_rotulo: String, accao: String) -> String:
	if chave_rotulo == "hud.controls.move":
		return "%s / %s" % [_primeira_tecla("mover_esquerda"), _primeira_tecla("mover_direita")]
	return _primeira_tecla(accao)


func _primeira_tecla(accao: String) -> String:
	for ev in InputMap.action_get_events(accao):
		if ev is InputEventKey:
			var kc: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
			return OS.get_keycode_string(kc as Key)
	return "—"


# --- cabeçalho do nível (canto superior esquerdo) -----------------
#
# É o INDICADOR DE NÍVEL. Eram três `Label` soltas sobre o cenário -- com um
# fundo claro por trás não se liam, e não diziam onde é que o jogador estava
# na campanha. Agora é uma placa de pedra (`UI.painel`) com:
#
#   selo   -- o número do nível, na cor da região
#   linha  -- nome da região + a que passo dela vai (3 / 5)
#   linha  -- nome do nível
#   linha  -- ☠ chefe (ou guardião) que sela a porta
#   pastilhas -- um traço por nível da região, o de agora aceso
#
# A cor da região (`EstadoJogo.REGIOES[r].cor`) tinge a placa toda: cada uma
# das 20 regiões tem o seu tom, e nota-se a passagem de uma para a outra.

var _cab_pastilhas: HBoxContainer

func _montar_cabecalho_nivel() -> void:
	# pastilha de vidro centrada no topo; cresce para os dois lados
	_cab_nivel = VBoxContainer.new()
	_cab_nivel.name = "CabecalhoNivel"
	_cab_nivel.anchor_left = 0.5
	_cab_nivel.anchor_right = 0.5
	_cab_nivel.offset_top = 12.0
	_cab_nivel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_cab_nivel.add_theme_constant_override("separation", 1)
	_cab_nivel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cab_nivel)
	_encher_cabecalho_nivel()


func _encher_cabecalho_nivel() -> void:
	if _cab_nivel == null:
		return
	for c in _cab_nivel.get_children():
		_cab_nivel.remove_child(c)
		c.queue_free()
	var i: int = EstadoJogo.indice_nivel
	var cor := EstadoJogo.cor_regiao_do_nivel(i)
	var passo: Array[int] = EstadoJogo.passo_na_regiao(i)

	var placa := PanelContainer.new()
	placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa.add_theme_stylebox_override("panel", _vidro(22, Vector4(8, 6, 22, 8),
		cor.lightened(0.2) * Color(1, 1, 1, 0.55)))
	_cab_nivel.add_child(placa)

	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa.add_child(linha)

	# selo com o número "região-passo", na cor da região
	var selo := PanelContainer.new()
	selo.custom_minimum_size = Vector2(52, 40)
	selo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = cor.darkened(0.35)
	sb.set_corner_radius_all(16)
	sb.anti_aliasing = true
	sb.set_border_width_all(1)
	sb.border_color = cor.lightened(0.4)
	selo.add_theme_stylebox_override("panel", sb)
	linha.add_child(selo)
	var num := Label.new()
	num.text = "%d-%d" % [EstadoJogo.regiao_do_nivel(i) + 1, passo[0]] if passo[1] > 0 else "%02d" % (i + 1)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.add_theme_font_size_override("font_size", 19)
	num.add_theme_color_override("font_color", Color(1, 0.97, 1))
	num.add_theme_color_override("font_outline_color", Color(0.04, 0.01, 0.06))
	num.add_theme_constant_override("outline_size", 4)
	selo.add_child(num)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_child(col)

	# nome do nível, e por baixo a região + passo dela
	col.add_child(_linha_cab(Textos.t(CatalogoCampanha.chave_nivel(i)), 18, Color(1, 0.96, 1)))
	var regiao := Textos.t(EstadoJogo.chave_regiao_do_nivel(i)).to_upper()
	if passo[1] > 0:
		regiao += "  ·  " + Textos.tf("hud.region_step", [passo[0], passo[1]])
	col.add_child(_linha_cab(regiao, 11, cor.lightened(0.45)))

	# pastilhas: um traço por nível da região (feito, agora, por fazer)
	_cab_pastilhas = HBoxContainer.new()
	_cab_pastilhas.add_theme_constant_override("separation", 3)
	_cab_pastilhas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cab_pastilhas.custom_minimum_size.y = 8
	col.add_child(_cab_pastilhas)
	for n in passo[1]:
		var p := ColorRect.new()
		p.custom_minimum_size = Vector2(20, 3)
		p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var feito := n < passo[0] - 1
		p.color = Color(1, 0.95, 0.8) if n == passo[0] - 1 else (
			cor.lightened(0.2) * Color(1, 1, 1, 0.75) if feito else Color(1, 1, 1, 0.16))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cab_pastilhas.add_child(p)


func _linha_cab(txt: String, tam: int, cor: Color, maiusculas := false) -> Label:
	var l := Label.new()
	l.text = txt.to_upper() if maiusculas else txt
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0.03, 0.01, 0.05))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch and _toque and not _toque.visible:
		_toque.visible = true
		_arrumar_para_toque()


func _atualizar_barra_vida(atual: int, maximo: int) -> void:
	if _barra_vida:
		_barra_vida.definir(atual, maximo)
	# a levar dano: o retrato fica vermelho por um instante
	if _vida_anterior >= 0 and atual < _vida_anterior and _retrato and is_inside_tree():
		var t := create_tween()
		_retrato.modulate = Color(1.0, 0.35, 0.35)
		t.tween_property(_retrato, "modulate", Color.WHITE, 0.4)
	_vida_anterior = atual


func _atualizar_energia(atual: float, maximo: float) -> void:
	if _barra_energia:
		_barra_energia.definir(atual, maximo)


func _atualizar_vidas(vidas: int) -> void:
	if _label_vidas:
		_label_vidas.text = "%d" % vidas


func _ao_habilidade(id: String) -> void:
	var nome: String = Textos.t(NOME_HABILIDADE.get(id, id))
	_aviso(Textos.tf("hud.new_ability", [nome]),
		UIProducao.ICONE_HABILIDADE.get(id, ""), "habilidade")


func _ao_pista(_id: String, total: int) -> void:
	_aviso(Textos.tf("hud.clue_found", [total]))


## Segundos que a explicação da mecânica fica no ecrã. Pedido do Paulo:
## 5 s no primeiro pedido, 10 s no segundo -- a placa passou a aparecer a
## meio da acção (quando a mecânica entra no ecrã) e a 5 s não dava para a
## ler sem deixar de jogar.
const TUTORIAL_SEGUNDOS := 10.0
## Largura da placa. Era 560 quando a placa vivia ao MEIO do ecrã. Desde a
## 9H.16 C vive no canto superior-esquerdo, fora da zona de acção: aí uma
## caixa larga voltaria a invadir o meio, por isso encolheu para 380 -- o
## texto ganha uma linha ou duas, mas nunca tapa a Koliani.
const TUTORIAL_LARGURA := 380.0


## A mecânica deste nível estreia aqui: diz o nome e como funciona.
##
## O texto vive nos 6 `assets/i18n` sob `mec.<cam>.nome` / `mec.<cam>.txt`.
## Uma câmara sem entrada não mostra nada (melhor sem aviso do que com uma
## chave em bruto no ecrã) -- há um teste a garantir que não falta nenhuma.
func _ao_mecanica(cam: String) -> void:
	var chave_nome := "mec.%s.nome" % cam
	var chave_txt := "mec.%s.txt" % cam
	if cam == "saltos" and not EstadoJogo.tem_habilidade("salto_duplo"):
		chave_txt = "mec.saltos.txt_basico"
	var nome := Textos.t(chave_nome)
	var txt := Textos.t(chave_txt)
	if nome == chave_nome or txt == chave_txt:
		push_warning("HUD: mecânica '%s' sem texto de tutorial" % cam)
		return
	_placa_tutorial(nome, txt)


func _placa_tutorial(nome: String, txt: String) -> void:
	_enfileirar_notificacao({"nome": nome, "txt": txt, "tutorial": true})


func _criar_tutorial(nome: String, txt: String) -> PanelContainer:
	var largura := minf(TUTORIAL_LARGURA, get_viewport().get_visible_rect().size.x - 48.0)
	var caixa := PanelContainer.new()
	caixa.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	caixa.add_theme_stylebox_override("panel", UIProducao.caixa("caixa_dialogo",
		Vector4(18, 12, 18, 14)))
	caixa.size = Vector2(largura, 0.0)
	# Semitransparente: lê-se, mas deixa ver o jogo por baixo.
	caixa.modulate.a = 0.9
	# Não bloqueia input (o toque atravessa para os controlos).
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	caixa.add_child(col)

	var l_nome := Label.new()
	l_nome.text = nome
	l_nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l_nome.add_theme_color_override("font_color", UIProducao.OURO)
	l_nome.add_theme_color_override("font_outline_color", Color(0.05, 0.01, 0.06))
	l_nome.add_theme_constant_override("outline_size", 4)
	l_nome.add_theme_font_size_override("font_size", 18)
	col.add_child(l_nome)

	var l_txt := Label.new()
	l_txt.text = txt
	l_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_txt.custom_minimum_size.x = largura - 56.0
	l_txt.add_theme_color_override("font_color", Color(0.94, 0.88, 1))
	l_txt.add_theme_color_override("font_outline_color", Color(0.05, 0.01, 0.06))
	l_txt.add_theme_constant_override("outline_size", 3)
	l_txt.add_theme_font_size_override("font_size", 15)
	col.add_child(l_txt)

	return caixa


## Toast de feedback (prancha 09, secção 8): moldura + ícone + texto
## dinâmico, centrado no topo. `estilo` "info" (azul) ou "habilidade".
func _aviso(txt: String, icone := "", estilo := "info") -> void:
	_enfileirar_notificacao({"txt": txt, "icone": icone, "estilo": estilo})


## Um único slot para tutorial/toast; falas dos chefes têm prioridade.
var _fila_notificacoes: Array[Dictionary] = []
var _notificacao: Control
var _notificacao_tween: Tween
var _fila_ativa := false
var _notificacao_suspensa := false


## Segundos que uma placa de tutorial espera por uma pausa no combate.
const ESPERA_COMBATE := 6.0
## Distância (px) a que um inimigo vivo já conta como "estou em combate".
const RAIO_COMBATE := 460.0


## Verdadeiro quando há um chefe em cena ou um inimigo vivo perto da
## Koliani -- momento em que uma caixa grande é estorvo, não ajuda.
func _em_combate() -> bool:
	if not is_inside_tree():
		return false
	if not get_tree().get_nodes_in_group("chefes").is_empty():
		return true
	var k := get_tree().get_first_node_in_group("koliani") as Node2D
	if k == null:
		return false
	for no in get_tree().get_nodes_in_group("inimigos"):
		var d := no as Node2D
		if d == null or bool(d.get("_morto")):
			continue
		if d.global_position.distance_to(k.global_position) < RAIO_COMBATE:
			return true
	return false


func _dialogo_visivel() -> bool:
	for balao in get_tree().get_nodes_in_group("dialogo_ui"):
		if balao.visible:
			return true
	return false


func _enfileirar_notificacao(dados: Dictionary) -> void:
	if not is_inside_tree():
		return
	_fila_notificacoes.append(dados)
	if not _fila_ativa:
		_consumir_notificacoes()


func _consumir_notificacoes() -> void:
	_fila_ativa = true
	while not _fila_notificacoes.is_empty():
		while _dialogo_visivel():
			await get_tree().process_frame
			if not is_inside_tree():
				return
		var dados: Dictionary = _fila_notificacoes.pop_front()
		var tutorial: bool = dados.get("tutorial", false)
		# "Durante combate: sem banners grandes." A placa da mecânica espera
		# que o combate acalme -- mas no máximo `ESPERA_COMBATE` segundos,
		# senão numa arena longa a explicação nunca chegava a aparecer.
		if tutorial:
			var esperou := 0.0
			while _em_combate() and esperou < ESPERA_COMBATE:
				await get_tree().process_frame
				if not is_inside_tree():
					return
				esperou += get_process_delta_time()
		_notificacao = _criar_tutorial(dados.nome, dados.txt) if tutorial else UIProducao.toast(dados.txt, dados.icone, dados.estilo)
		if not tutorial:
			var texto: Label = _notificacao.get_child(0).get_child(_notificacao.get_child(0).get_child_count() - 1)
			# 9H.16 C: era `larg - 168` (1112 px em 1280!) -- uma faixa que
			# atravessava o ecrã todo. No canto, o toast tem de ser estreito.
			texto.custom_minimum_size.x = minf(texto.get_minimum_size().x,
				get_viewport().get_visible_rect().size.x * 0.30)
			texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_notificacao.modulate.a = 0.92
		_notificacao.name = "NotificacaoAtiva"
		_notificacao_suspensa = false
		add_child(_notificacao)
		await get_tree().process_frame
		# A Porta pode substituir a cena no mesmo frame. A continuação da
		# fila não pode usar o viewport do HUD que acabou de sair da árvore.
		if not is_inside_tree() or not is_instance_valid(_notificacao):
			return
		_notificacao.reset_size()
		_posicionar_notificacao()
		_notificacao_tween = _notificacao.create_tween()
		_notificacao_tween.tween_interval(TUTORIAL_SEGUNDOS - 0.6 if tutorial else 1.8)
		_notificacao_tween.tween_property(_notificacao, "modulate:a", 0.0, 0.6)
		await _notificacao_tween.finished
		if not is_inside_tree() or not is_instance_valid(_notificacao):
			return
		_notificacao.queue_free()
		_notificacao = null
		await get_tree().process_frame
		if not is_inside_tree():
			return
	_fila_ativa = false


## 9H.16 C -- a placa vivia CENTRADA a meio do ecrã (`(larg - size.x) * 0.5`
## a y >= 160): em 1280x720 isso é exactamente por cima da Koliani, dos
## inimigos e das plataformas onde se aterra. Passa a encostar ao canto
## SUPERIOR-ESQUERDO, debaixo do cabeçalho do nível, e nunca entra na banda
## central da acção (`FRACAO_ACAO` da largura, ao centro).
const MARGEM_SEGURA := 24.0
## Metade da banda central que a notificação não pode invadir (fracção da
## largura do ecrã). 0.34 => os 34% do meio ficam sempre livres.
const FRACAO_ACAO := 0.34


func _posicionar_notificacao() -> void:
	if not is_inside_tree() or not is_instance_valid(_notificacao):
		return
	var ecra := get_viewport().get_visible_rect().size
	var topo := MARGEM_SEGURA
	if _cab_nivel:
		topo = maxf(topo, _cab_nivel.position.y + _cab_nivel.size.y + 10.0)
	if _vitais:
		topo = maxf(topo, _vitais.position.y + _vitais.size.y + 10.0)
	# Nunca tapar o HUD de baixo (barras/equipamento) nem sair do ecrã.
	topo = minf(topo, maxf(MARGEM_SEGURA, ecra.y - _notificacao.size.y - 200.0))
	var esquerda := MARGEM_SEGURA
	# Se ainda assim a caixa fosse larga ao ponto de entrar no meio do ecrã,
	# encolhe-se a caixa -- não se empurra para o centro.
	var limite := ecra.x * (0.5 - FRACAO_ACAO * 0.5) - MARGEM_SEGURA
	if _notificacao.size.x > limite and limite > 160.0:
		_notificacao.size.x = limite
	_notificacao.position = Vector2(roundf(esquerda), roundf(topo))


func _process(_dt: float) -> void:
	if not is_instance_valid(_notificacao):
		return
	var suspensa := _dialogo_visivel()
	_notificacao.visible = not suspensa
	_posicionar_notificacao()
	if suspensa != _notificacao_suspensa and _notificacao_tween and _notificacao_tween.is_valid():
		if suspensa:
			_notificacao_tween.pause()
		else:
			_notificacao_tween.play()
		_notificacao_suspensa = suspensa


## Com os controlos de toque ligados o canto de baixo à esquerda é do
## JOYSTICK; o bloco de estado vive no topo, por isso não há nada a arrumar.
func _arrumar_para_toque() -> void:
	pass


## Sem Energia para o Especial: a barra pisca em vermelho.
func _piscar_energia() -> void:
	if _barra_energia == null or not is_inside_tree():
		return
	var t := create_tween()
	_barra_energia.modulate = Color(1.0, 0.35, 0.35)
	t.tween_property(_barra_energia, "modulate", Color(1, 1, 1), 0.35)
