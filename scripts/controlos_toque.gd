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
	EstadoJogo.mecanica_estreou.connect(_ao_mecanica)
	_atualizar_vidas(EstadoJogo.vidas)
	var koliani := get_tree().get_first_node_in_group("koliani")
	if koliani and koliani.has_signal("vida_mudou"):
		koliani.vida_mudou.connect(_atualizar_barra_vida)
	if koliani and koliani.has_signal("energia_mudou"):
		koliani.energia_mudou.connect(_atualizar_energia)

	_vestir_barras()
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

	_arrumar_para_toque()
	_montar_legenda_controlos()
	_montar_cabecalho_nivel()
	Textos.idioma_mudou.connect(func(_l: String) -> void:
		_encher_legenda()
		_encher_cabecalho_nivel())


## Troca as caixas lisas das barras de Vida/Energia pela calha e pelo
## enchimento de pixel-art (`assets/ui/`), e põe um coração à frente da vida
## e outro no contador de vidas. As barras em si (posição, tamanho, sinais)
## continuam a vir do `HUD.tscn`.
func _vestir_barras() -> void:
	if _barra_vida:
		UI.vestir_barra(_barra_vida, UI.COR_VIDA)
	if _barra_energia:
		UI.vestir_barra(_barra_energia, UI.COR_ENERGIA)

	# o contador de vidas passa de "x3" a "♥ x3". O coração fica ao lado do
	# número, DENTRO da caixa `Vidas` -- à esquerda dela está o disco da arma,
	# e um ícone posto para fora ficava por baixo do disco.
	if _label_vidas:
		var ic := UI.icone("ico_coracao", 18)
		ic.name = "IconeVidas"
		ic.position = Vector2(0, 3)
		_label_vidas.get_parent().add_child(ic)
		_label_vidas.position.x = 28


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
	b.offset_top = -116.0
	b.offset_bottom = -92.0
	b.add_theme_font_size_override("font_size", 11)
	b.add_theme_color_override("font_color", Color(1, 0.88, 0.98))
	b.add_theme_color_override("font_hover_color", Color(1, 0.96, 1))
	b.add_theme_color_override("font_pressed_color", Color(1, 0.8, 0.96))
	# a mesma pedra da HUD, mais acesa quando o rato lá está
	b.add_theme_stylebox_override("normal", UI.painel("painel_pedra", Color(1, 0.9, 1, 0.94), 3.0))
	b.add_theme_stylebox_override("hover", UI.painel("painel_placa", Color(1, 0.9, 1), 3.0))
	b.add_theme_stylebox_override("pressed", UI.painel("painel_placa", Color(0.8, 0.6, 0.9), 3.0))
	b.add_theme_stylebox_override("focus", UI.painel("painel_pedra", Color(1, 0.9, 1, 0.94), 3.0))
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
	l.offset_top = -140.0
	l.offset_bottom = -120.0
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
	placa.add_theme_stylebox_override("panel", UI.painel("painel_chefe", Color(1, 1, 1, 0.96), 8.0))
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
	_chefe_barra.custom_minimum_size = Vector2(0, 26)
	_chefe_barra.show_percentage = false
	_chefe_barra.min_value = 0.0
	_chefe_barra.max_value = 1.0
	_chefe_barra.value = 1.0
	col.add_child(_chefe_barra)
	UI.vestir_barra(_chefe_barra, UI.COR_CHEFE)


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
	caixa.offset_left = -176.0
	caixa.offset_right = -18.0
	caixa.offset_top = 16.0
	caixa.offset_bottom = 54.0
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.pivot_offset = Vector2(79, 19)
	caixa.add_theme_stylebox_override("panel", UI.painel(
		"painel_pedra", Color(1.0, 0.86, 1.0, 0.94), 6.0))
	add_child(caixa)

	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 8)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(linha)
	linha.add_child(UI.icone("ico_losango", 18))

	_ess_label = Label.new()
	_ess_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ess_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ess_label.add_theme_font_size_override("font_size", 18)
	_ess_label.add_theme_color_override("font_color", Color(1.0, 0.86, 1.0))
	_ess_label.add_theme_color_override("font_outline_color", Color(0.05, 0.01, 0.06))
	_ess_label.add_theme_constant_override("outline_size", 4)
	linha.add_child(_ess_label)


func _atualizar_essencia(total: int) -> void:
	if _ess_label == null:
		return
	_ess_label.text = "%d" % total
	var caixa := _ess_label.get_parent().get_parent() as Control
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
	_cab_nivel = VBoxContainer.new()
	_cab_nivel.name = "CabecalhoNivel"
	_cab_nivel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_cab_nivel.position = Vector2(12.0, 8.0)
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

	# a placa: pedra tingida com a cor da região, mas escura -- é fundo de
	# texto, não pode competir com o cenário
	var placa := PanelContainer.new()
	placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa.add_theme_stylebox_override("panel", UI.painel(
		"painel_placa", Color(cor.r * 0.5 + 0.2, cor.g * 0.5 + 0.2, cor.b * 0.5 + 0.2, 0.94), 8.0))
	_cab_nivel.add_child(placa)

	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	placa.add_child(linha)

	# selo com o número do nível
	var selo := PanelContainer.new()
	selo.custom_minimum_size = Vector2(52, 52)
	selo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	selo.add_theme_stylebox_override("panel", UI.painel("selo", cor * 0.7, 2.0))
	linha.add_child(selo)
	var num := Label.new()
	num.text = "%02d" % (i + 1)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.add_theme_font_size_override("font_size", 24)
	num.add_theme_color_override("font_color", Color(1, 0.97, 1))
	num.add_theme_color_override("font_outline_color", Color(0.04, 0.01, 0.06))
	num.add_theme_constant_override("outline_size", 5)
	selo.add_child(num)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(col)

	# região + passo dentro dela
	var cabecalho := Textos.t(EstadoJogo.chave_regiao_do_nivel(i)).to_upper()
	if passo[1] > 0:
		cabecalho += "   ·   " + Textos.tf("hud.region_step", [passo[0], passo[1]])
	col.add_child(_linha_cab(cabecalho, 12, cor.lerp(Color.WHITE, 0.35), false))
	# nome do nível
	col.add_child(_linha_cab(Textos.t(CatalogoCampanha.chave_nivel(i)), 18,
		Color(1, 0.96, 1), false))
	# chefe (ou guardião), com caveira à frente
	var ck := CatalogoCampanha.chave_chefe(i)
	if ck != "":
		var lc := HBoxContainer.new()
		lc.add_theme_constant_override("separation", 5)
		lc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lc.add_child(UI.icone("ico_caveira", 13, Color(1, 0.72, 0.74)))
		var rotulo := "sel.boss" if CatalogoCampanha.tem_chefe(i) else "sel.guard"
		lc.add_child(_linha_cab(Textos.tf(rotulo, [Textos.t(ck)]), 12,
			Color(0.98, 0.72, 0.74), false))
		col.add_child(lc)

	# pastilhas: um traço por nível da região
	_cab_pastilhas = HBoxContainer.new()
	_cab_pastilhas.add_theme_constant_override("separation", 4)
	_cab_pastilhas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_cab_pastilhas)
	for n in passo[1]:
		var p := ColorRect.new()
		p.custom_minimum_size = Vector2(18, 4)
		var feito := n < passo[0] - 1
		p.color = cor if n == passo[0] - 1 else (
			cor * 0.55 if feito else Color(0.24, 0.2, 0.3, 0.9))
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
		_barra_vida.max_value = maximo
		_barra_vida.value = atual
		UI.ajustar_barra(_barra_vida)


func _atualizar_energia(atual: float, maximo: float) -> void:
	if _barra_energia:
		_barra_energia.max_value = maximo
		_barra_energia.value = atual
		UI.ajustar_barra(_barra_energia)


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


## Segundos que a explicação da mecânica fica no ecrã. Pedido do Paulo:
## "fica 5 segundos e desaparece".
const TUTORIAL_SEGUNDOS := 5.0
## Largura da placa. Uma linha comprida a meio do ecrã lê-se de relance; um
## bloco estreito e alto obriga a parar o jogo para o ler.
const TUTORIAL_LARGURA := 560.0


## A mecânica deste nível estreia aqui: diz o nome e como funciona.
##
## O texto vive nos 6 `assets/i18n` sob `mec.<cam>.nome` / `mec.<cam>.txt`.
## Uma câmara sem entrada não mostra nada (melhor sem aviso do que com uma
## chave em bruto no ecrã) -- há um teste a garantir que não falta nenhuma.
func _ao_mecanica(cam: String) -> void:
	var chave_nome := "mec.%s.nome" % cam
	var chave_txt := "mec.%s.txt" % cam
	var nome := Textos.t(chave_nome)
	var txt := Textos.t(chave_txt)
	if nome == chave_nome or txt == chave_txt:
		push_warning("HUD: mecânica '%s' sem texto de tutorial" % cam)
		return
	_placa_tutorial(nome, txt)


func _placa_tutorial(nome: String, txt: String) -> void:
	var caixa := PanelContainer.new()
	caixa.add_theme_stylebox_override("panel", UI.painel(
		"painel_placa", Color(1.0, 0.62, 1.0), 10.0))
	caixa.size = Vector2(TUTORIAL_LARGURA, 0.0)
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	caixa.add_child(col)

	var l_nome := Label.new()
	l_nome.text = nome
	l_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_nome.add_theme_color_override("font_color", Color(1, 0.86, 1))
	l_nome.add_theme_color_override("font_outline_color", Color(0.05, 0.01, 0.06))
	l_nome.add_theme_constant_override("outline_size", 4)
	l_nome.add_theme_font_size_override("font_size", 22)
	col.add_child(l_nome)

	var l_txt := Label.new()
	l_txt.text = txt
	l_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_txt.custom_minimum_size.x = TUTORIAL_LARGURA - 36.0
	l_txt.add_theme_color_override("font_color", Color(0.94, 0.88, 1))
	l_txt.add_theme_color_override("font_outline_color", Color(0.05, 0.01, 0.06))
	l_txt.add_theme_constant_override("outline_size", 3)
	l_txt.add_theme_font_size_override("font_size", 17)
	col.add_child(l_txt)

	add_child(caixa)
	# a altura só é conhecida depois de o texto ser medido
	await get_tree().process_frame
	var larg := get_viewport().get_visible_rect().size.x
	caixa.position = Vector2((larg - TUTORIAL_LARGURA) * 0.5, 78.0)

	caixa.modulate.a = 0.0
	var t := caixa.create_tween()
	t.tween_property(caixa, "modulate:a", 1.0, 0.35)
	t.tween_interval(TUTORIAL_SEGUNDOS - 0.95)
	t.tween_property(caixa, "modulate:a", 0.0, 0.6)
	t.tween_callback(caixa.queue_free)


func _aviso(txt: String) -> void:
	var l := Label.new()
	l.text = "  " + txt + "  "
	var larg := get_viewport().get_visible_rect().size.x
	l.position = Vector2(larg * 0.5 - 130.0, 68.0)
	l.add_theme_color_override("font_color", Color(1, 0.92, 1))
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.01, 0.06))
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_stylebox_override("normal", UI.painel(
		"painel_placa", Color(1.0, 0.62, 1.0), 8.0))
	add_child(l)
	var t := l.create_tween()
	t.tween_interval(1.8)
	t.tween_property(l, "modulate:a", 0.0, 0.6)
	t.tween_callback(l.queue_free)


## Com os controlos de toque ligados, o canto de baixo à esquerda é do
## JOYSTICK -- e era exactamente onde viviam as barras, o disco da arma e os
## botões de equipamento. Sobem todos acima do aro do stick.
##
## Sobem por deslocação e não por âncora nova: estas peças estão todas
## presas ao fundo (`anchor_top/bottom = 1.0`) com deslocamentos negativos,
## portanto tirar 230 a cada um mantém a arrumação entre elas.
const DESVIO_TOQUE := 230.0
var _desviado := false


func _arrumar_para_toque() -> void:
	if _desviado or _toque == null or not _toque.visible:
		return
	_desviado = true
	for n in [$Vida, $Energia, $Vidas, _arma_disco, _btn_armas, _btn_armaduras,
			_selo_arma, _selo_armadura]:
		if n is Control:
			n.offset_top -= DESVIO_TOQUE
			n.offset_bottom -= DESVIO_TOQUE
