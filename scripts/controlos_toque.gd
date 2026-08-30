extends CanvasLayer
## HUD: barra de vida + vidas (sempre visíveis) e os botões de toque
## (`Toque`), que só aparecem em ecrã táctil / ao primeiro toque. Mostra
## também avisos curtos ao ganhar habilidade ou encontrar pista.

## chave de tradução do nome de cada habilidade (ver assets/i18n)
const NOME_HABILIDADE := {
	"salto_duplo": "hud.ability.salto_duplo",
	"dash_aereo": "hud.ability.dash_aereo",
	"partir_paredes": "hud.ability.partir_paredes",
	"escudo": "hud.ability.escudo",
	"projetil": "hud.ability.projetil",
}

@onready var _barra_vida: ProgressBar = $Vida/Barra
@onready var _barra_energia: ProgressBar = $Energia/Barra
@onready var _label_vidas: Label = $Vidas/Label
@onready var _toque: Control = $Toque

## Barra de vida do chefe (construída em runtime, ao fundo do ecrã).
var _chefe_caixa: Control
var _chefe_nome: Label
var _chefe_barra: ProgressBar
var _chefe_fim := false
var _chefe_tween: Tween


func _ready() -> void:
	if _toque:
		_toque.visible = DisplayServer.is_touchscreen_available()
	# a barra de Energia só aparece depois de apanhar a habilidade "projetil"
	if _barra_energia:
		_barra_energia.get_parent().visible = EstadoJogo.tem_habilidade("projetil")
	EstadoJogo.vidas_mudaram.connect(_atualizar_vidas)
	EstadoJogo.habilidade_desbloqueada.connect(_ao_habilidade)
	EstadoJogo.pista_encontrada.connect(_ao_pista)
	_atualizar_vidas(EstadoJogo.vidas)
	var koliani := get_tree().get_first_node_in_group("koliani")
	if koliani and koliani.has_signal("vida_mudou"):
		koliani.vida_mudou.connect(_atualizar_barra_vida)
	if koliani and koliani.has_signal("energia_mudou"):
		koliani.energia_mudou.connect(_atualizar_energia)

	_montar_barra_chefe()
	var chefe := get_tree().get_first_node_in_group("chefes")
	if chefe and chefe.has_signal("combate_iniciado"):
		chefe.combate_iniciado.connect(_ao_combate_chefe)
		chefe.vida_mudou.connect(_atualizar_barra_chefe)
		chefe.derrotado.connect(_ao_chefe_derrotado)
		chefe.tree_exited.connect(_ao_chefe_derrotado)


# --- barra de vida do chefe ------------------------------------------

func _montar_barra_chefe() -> void:
	_chefe_caixa = Control.new()
	_chefe_caixa.name = "BarraChefe"
	_chefe_caixa.anchor_left = 0.5
	_chefe_caixa.anchor_right = 0.5
	_chefe_caixa.anchor_top = 1.0
	_chefe_caixa.anchor_bottom = 1.0
	_chefe_caixa.offset_left = -420.0
	_chefe_caixa.offset_right = 420.0
	_chefe_caixa.offset_top = -66.0
	_chefe_caixa.offset_bottom = -14.0
	_chefe_caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chefe_caixa.modulate.a = 0.0
	_chefe_caixa.visible = false
	add_child(_chefe_caixa)

	_chefe_nome = Label.new()
	_chefe_nome.anchor_right = 1.0
	_chefe_nome.offset_bottom = 22.0
	_chefe_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chefe_nome.add_theme_font_size_override("font_size", 16)
	_chefe_nome.add_theme_color_override("font_color", Color(0.98, 0.86, 0.86))
	_chefe_nome.add_theme_color_override("font_outline_color", Color(0.05, 0.01, 0.02))
	_chefe_nome.add_theme_constant_override("outline_size", 5)
	_chefe_caixa.add_child(_chefe_nome)

	_chefe_barra = ProgressBar.new()
	_chefe_barra.anchor_right = 1.0
	_chefe_barra.offset_top = 24.0
	_chefe_barra.offset_bottom = 46.0
	_chefe_barra.show_percentage = false
	_chefe_barra.min_value = 0.0
	_chefe_barra.max_value = 1.0
	_chefe_barra.value = 1.0
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.05, 0.05, 0.06, 0.92)   # calha escura neutra
	fundo.set_corner_radius_all(3)
	fundo.set_border_width_all(2)
	fundo.border_color = Color(0.32, 0.06, 0.09, 0.95)
	_chefe_barra.add_theme_stylebox_override("background", fundo)
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = Color(0.46, 0.04, 0.07)         # vermelho escuro
	cheio.set_corner_radius_all(3)
	cheio.border_width_top = 2
	cheio.border_color = Color(0.75, 0.12, 0.16, 0.9)  # aresta viva por cima
	_chefe_barra.add_theme_stylebox_override("fill", cheio)
	_chefe_caixa.add_child(_chefe_barra)


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


func _input(evento: InputEvent) -> void:
	if evento is InputEventScreenTouch and _toque and not _toque.visible:
		_toque.visible = true


func _atualizar_barra_vida(atual: int, maximo: int) -> void:
	if _barra_vida:
		_barra_vida.max_value = maximo
		_barra_vida.value = atual


func _atualizar_energia(atual: float, maximo: float) -> void:
	if _barra_energia:
		_barra_energia.max_value = maximo
		_barra_energia.value = atual


func _atualizar_vidas(vidas: int) -> void:
	if _label_vidas:
		_label_vidas.text = "x%d" % vidas


func _ao_habilidade(id: String) -> void:
	if id == "projetil" and _barra_energia:
		_barra_energia.get_parent().visible = true
	var nome: String = Textos.t(NOME_HABILIDADE.get(id, id))
	_aviso(Textos.tf("hud.new_ability", [nome]))


func _ao_pista(_id: String, total: int) -> void:
	_aviso(Textos.tf("hud.clue_found", [total]))


func _aviso(txt: String) -> void:
	var l := Label.new()
	l.text = "  " + txt + "  "
	var larg := get_viewport().get_visible_rect().size.x
	l.position = Vector2(larg * 0.5 - 130.0, 68.0)
	l.add_theme_color_override("font_color", Color(1, 0.92, 1))
	l.add_theme_font_size_override("font_size", 20)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.55, 0.18, 0.5, 0.9)
	sb.set_corner_radius_all(5)
	sb.set_content_margin_all(6)
	l.add_theme_stylebox_override("normal", sb)
	add_child(l)
	var t := l.create_tween()
	t.tween_interval(1.8)
	t.tween_property(l, "modulate:a", 0.0, 0.6)
	t.tween_callback(l.queue_free)
