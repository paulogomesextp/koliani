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
	"escalar_paredes": "hud.ability.escalar_paredes",
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

## Disco da arma atual (canto inferior-esquerdo, sobre as barras).
var _arma_disco: Panel
var _arma_label: Label

## Botões WEAPONS / ARMOR por cima da barra de vida + o ecrã que abrem.
const CENA_SELETOR_EQUIP := preload("res://scenes/ui/SeletorEquip.tscn")
var _btn_armas: Button
var _btn_armaduras: Button
var _seletor_equip: SeletorEquip
## Selo "UPGRADE AVAILABLE" por cima do botão WEAPONS / ARMOR quando há no
## inventário algo melhor do que o que está equipado.
var _selo_arma: Label
var _selo_armadura: Label

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

	_montar_disco_arma()
	_montar_botoes_equip()
	_montar_selos_upgrade()
	EstadoJogo.equipamento_mudou.connect(func(_t: String, _i: String) -> void:
		_atualizar_disco_arma()
		_atualizar_selos_upgrade())
	EstadoJogo.equipamento_ganho.connect(_ao_equipamento_ganho)
	Textos.idioma_mudou.connect(func(_l: String) -> void:
		_traduzir_equip()
		_atualizar_selos_upgrade())
	_atualizar_disco_arma()
	_traduzir_equip()
	_atualizar_selos_upgrade()

	_montar_contador_essencia()
	EstadoJogo.essencia_mudou.connect(_atualizar_essencia)
	_atualizar_essencia(EstadoJogo.essencia)

	_montar_legenda_controlos()
	_montar_cabecalho_nivel()
	Textos.idioma_mudou.connect(func(_l: String) -> void:
		_encher_legenda()
		_encher_cabecalho_nivel())


## Dois botões pequenos (WEAPONS / ARMOR) por cima da barra de vida.
func _montar_botoes_equip() -> void:
	_btn_armas = _fazer_botao_equip("arma")
	_btn_armaduras = _fazer_botao_equip("armadura")
	add_child(_btn_armas)
	add_child(_btn_armaduras)


func _fazer_botao_equip(tipo: String) -> Button:
	var b := Button.new()
	b.name = "Btn_" + tipo
	b.focus_mode = Control.FOCUS_NONE
	b.anchor_left = 0.0
	b.anchor_right = 0.0
	b.anchor_top = 1.0
	b.anchor_bottom = 1.0
	b.offset_left = 92.0 if tipo == "arma" else 192.0
	b.offset_right = b.offset_left + 96.0
	b.offset_top = -110.0
	b.offset_bottom = -86.0
	b.add_theme_font_size_override("font_size", 11)
	b.add_theme_color_override("font_color", Color(1, 0.88, 0.98))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.05, 0.11, 0.92)
	sb.set_corner_radius_all(4)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.85, 0.4, 0.82, 0.9)
	for e in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(e, sb)
	b.pressed.connect(_abrir_equip.bind(tipo))
	return b


## --- selo "UPGRADE AVAILABLE" -------------------------------------

func _montar_selos_upgrade() -> void:
	_selo_arma = _fazer_selo(92.0)
	_selo_armadura = _fazer_selo(192.0)
	add_child(_selo_arma)
	add_child(_selo_armadura)


func _fazer_selo(x: float) -> Label:
	var l := Label.new()
	l.anchor_top = 1.0
	l.anchor_bottom = 1.0
	l.offset_left = x - 2.0
	l.offset_right = x + 94.0
	l.offset_top = -134.0
	l.offset_bottom = -114.0
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", Color(0.15, 0.05, 0.02))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.82, 0.3, 0.95)
	sb.set_corner_radius_all(4)
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	l.add_theme_stylebox_override("normal", sb)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.visible = false
	return l


## Há no inventário uma arma/armadura melhor (índice mais alto na lista de
## poder) do que a equipada?
func _ha_upgrade(tipo: String) -> bool:
	if tipo == "arma":
		var eq := Equipamento.indice_arma(EstadoJogo.arma_equipada)
		for id in EstadoJogo.armas:
			if Equipamento.indice_arma(id) > eq:
				return true
	else:
		var eq := Equipamento.indice_armadura(EstadoJogo.armadura_equipada)
		for id in EstadoJogo.armaduras:
			if Equipamento.indice_armadura(id) > eq:
				return true
	return false


func _atualizar_selos_upgrade() -> void:
	for par in [[_selo_arma, "arma"], [_selo_armadura, "armadura"]]:
		var l: Label = par[0]
		if l == null:
			continue
		l.text = Textos.t("hud.upgrade_available")
		var mostra := _ha_upgrade(par[1])
		if mostra and not l.visible:
			l.visible = true
			l.modulate.a = 0.0
			var t := l.create_tween().set_loops()
			t.tween_property(l, "modulate:a", 1.0, 0.5)
			t.tween_property(l, "modulate:a", 0.55, 0.5)
			l.set_meta("tw", t)
		elif not mostra and l.visible:
			l.visible = false
			var tw = l.get_meta("tw", null)
			if tw and is_instance_valid(tw):
				tw.kill()


func _traduzir_equip() -> void:
	if _btn_armas:
		_btn_armas.text = Textos.t("gear.menu.weapons")
	if _btn_armaduras:
		_btn_armaduras.text = Textos.t("gear.menu.armor")
	_atualizar_disco_arma()


func _abrir_equip(tipo: String) -> void:
	if _seletor_equip and is_instance_valid(_seletor_equip):
		return
	_seletor_equip = CENA_SELETOR_EQUIP.instantiate()
	add_child(_seletor_equip)
	_seletor_equip.configurar(tipo)
	_seletor_equip.fechado.connect(_fechar_equip)
	get_tree().paused = true


func _fechar_equip() -> void:
	if _seletor_equip and is_instance_valid(_seletor_equip):
		_seletor_equip.queue_free()
	_seletor_equip = null
	get_tree().paused = false


# --- disco da arma atual + troca ------------------------------------

func _montar_disco_arma() -> void:
	_arma_disco = Panel.new()
	_arma_disco.custom_minimum_size = Vector2(64, 64)
	_arma_disco.size = Vector2(64, 64)
	_arma_disco.anchor_top = 1.0
	_arma_disco.anchor_bottom = 1.0
	_arma_disco.offset_left = 20.0
	_arma_disco.offset_right = 84.0
	_arma_disco.offset_top = -84.0
	_arma_disco.offset_bottom = -20.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.04, 0.09, 0.96)
	sb.set_corner_radius_all(32)
	sb.set_border_width_all(3)
	sb.border_color = Color(0.85, 0.4, 0.82, 0.95)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 8
	_arma_disco.add_theme_stylebox_override("panel", sb)
	add_child(_arma_disco)

	_arma_label = Label.new()
	_arma_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_arma_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_arma_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_arma_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_arma_label.add_theme_font_size_override("font_size", 22)
	_arma_label.add_theme_color_override("font_color", Color(1, 0.9, 0.98))
	_arma_disco.add_child(_arma_label)
	# o disco só mostra a arma equipada -- trocar de arma faz-se no menu WEAPONS


func _atualizar_disco_arma() -> void:
	if _arma_disco == null:
		return
	# sem arma -> disco discreto (punhos)
	if EstadoJogo.arma_equipada == "":
		_arma_label.text = "✊"
		_arma_disco.modulate.a = 0.6
		return
	_arma_disco.modulate.a = 1.0
	var wi := Equipamento.indice_arma(EstadoJogo.arma_equipada)
	var sb := _arma_disco.get_theme_stylebox("panel") as StyleBoxFlat
	if sb and wi >= 0:
		sb.border_color = Equipamento.cor_arma(wi)
	var nome := Textos.t(Equipamento.arma(EstadoJogo.arma_equipada).get("nome", ""))
	# iniciais da arma (placeholder até haver ícone pixel)
	var ini := ""
	for palavra in nome.split(" ", false):
		if palavra.length() > 0 and palavra[0].to_upper() != palavra[0].to_lower():
			ini += palavra[0].to_upper()
		if ini.length() >= 2:
			break
	_arma_label.text = ini if ini != "" else nome.substr(0, 2)


func _ao_equipamento_ganho(tipo: String, id: String) -> void:
	var item: Dictionary = Equipamento.arma(id) if tipo == "arma" else Equipamento.armadura(id)
	var nome := Textos.t(item.get("nome", id))
	_aviso(Textos.tf("hud.gear_weapon" if tipo == "arma" else "hud.gear_armor", [nome]))
	_atualizar_selos_upgrade()


# --- barra de vida do chefe ------------------------------------------

func _montar_barra_chefe() -> void:
	_chefe_caixa = Control.new()
	_chefe_caixa.name = "BarraChefe"
	_chefe_caixa.anchor_left = 0.5
	_chefe_caixa.anchor_right = 0.5
	_chefe_caixa.anchor_top = 1.0
	_chefe_caixa.anchor_bottom = 1.0
	_chefe_caixa.offset_left = -380.0
	_chefe_caixa.offset_right = 380.0
	_chefe_caixa.offset_top = -104.0
	_chefe_caixa.offset_bottom = -52.0
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


# --- legenda dos controlos (topo do ecrã) --------------------------

## Contador de ESSÊNCIA no canto sup. direito (✦ 1234). Pisa e treme quando
## sobe.
var _ess_label: Label

func _montar_contador_essencia() -> void:
	var caixa := PanelContainer.new()
	caixa.name = "Essencia"
	caixa.anchor_left = 1.0
	caixa.anchor_right = 1.0
	caixa.anchor_top = 0.0
	caixa.anchor_bottom = 0.0
	caixa.offset_left = -168.0
	caixa.offset_right = -18.0
	caixa.offset_top = 16.0
	caixa.offset_bottom = 48.0
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.pivot_offset = Vector2(75, 16)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.04, 0.1, 0.78)
	sb.set_corner_radius_all(9)
	sb.set_border_width_all(1)
	sb.border_color = Color(1.0, 0.5, 0.95, 0.5)
	sb.content_margin_left = 12
	sb.content_margin_right = 14
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	caixa.add_theme_stylebox_override("panel", sb)
	add_child(caixa)

	_ess_label = Label.new()
	_ess_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ess_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ess_label.add_theme_font_size_override("font_size", 18)
	_ess_label.add_theme_color_override("font_color", Color(1.0, 0.86, 1.0))
	_ess_label.add_theme_color_override("font_outline_color", Color(0.05, 0.01, 0.06))
	_ess_label.add_theme_constant_override("outline_size", 4)
	caixa.add_child(_ess_label)


func _atualizar_essencia(total: int) -> void:
	if _ess_label == null:
		return
	_ess_label.text = "✦ %d" % total
	var caixa := _ess_label.get_parent() as Control
	if caixa:
		var t := create_tween()
		t.tween_property(caixa, "scale", Vector2(1.14, 1.14), 0.06)
		t.tween_property(caixa, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _montar_legenda_controlos() -> void:
	# em ecrã táctil os botões de toque já mostram tudo
	if DisplayServer.is_touchscreen_available():
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

func _montar_cabecalho_nivel() -> void:
	_cab_nivel = VBoxContainer.new()
	_cab_nivel.name = "CabecalhoNivel"
	_cab_nivel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_cab_nivel.position = Vector2(12.0, 8.0)
	_cab_nivel.custom_minimum_size = Vector2(420.0, 0.0)
	_cab_nivel.add_theme_constant_override("separation", 1)
	_cab_nivel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cab_nivel)
	_encher_cabecalho_nivel()


func _encher_cabecalho_nivel() -> void:
	if _cab_nivel == null:
		return
	for c in _cab_nivel.get_children():
		c.queue_free()
	var i: int = EstadoJogo.indice_nivel
	# nº do nível + nome
	_cab_nivel.add_child(_linha_cab(
		Textos.tf("map.level", [i + 1]), 13, Color(0.78, 0.7, 0.86), true))
	_cab_nivel.add_child(_linha_cab(
		Textos.t(CatalogoCampanha.chave_nivel(i)), 17, Color(1, 0.95, 1), false))
	# nome do chefe, se houver
	var ck := CatalogoCampanha.chave_chefe(i)
	if ck != "":
		_cab_nivel.add_child(_linha_cab(
			Textos.tf("sel.boss", [Textos.t(ck)]), 13, Color(0.98, 0.7, 0.72), true))


func _linha_cab(txt: String, tam: int, cor: Color, pequeno: bool) -> Label:
	var l := Label.new()
	l.text = txt if not pequeno else txt.to_upper()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0.03, 0.01, 0.05))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


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
