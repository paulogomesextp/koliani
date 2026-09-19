extends CanvasLayer
## Barra de topo do "DEVELOPER MODE". Só existe quando
## `EstadoJogo.modo_dev` está ligado (o `main.gd` só a instancia nesse
## caso). Mostra um botão "TESTAR OUTRO NÍVEL" no cimo do ecrã; carregar
## abre o carrossel `SeletorNiveis` com todos os níveis da campanha (sem
## respeitar bloqueios) -- escolher um recarrega o jogo nesse nível sem
## tocar no save real.

const CENA_JOGO := "res://scenes/Main.tscn"
const CENA_SELETOR := preload("res://scenes/ui/SeletorNiveis.tscn")

var _painel: Control
var _seletor: SeletorNiveis
## Execution 9H.18 Phase C: teclado de sons (tecla S). So' no modo Dev.
const CENA_SONS := preload("res://scripts/dev_sons.gd")
var _sons: Control


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not EstadoJogo.entrada_dev_disponivel() or not EstadoJogo.modo_dev:
		queue_free()
		return
	_montar_botao_topo()
	_montar_botao_flymode()
	var estado := Label.new()
	estado.name = "EstadoDev"
	estado.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	estado.position = Vector2(-234, 74)
	estado.add_theme_font_size_override("font_size", 13)
	estado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(estado)
	_montar_painel()
	_sons = CENA_SONS.new()
	add_child(_sons)
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	_traduzir()


## Comando: o botão SELECT (Back/View) abre/fecha o "TESTAR OUTRO NÍVEL"
## -- só no developer mode (a barra só existe aí).
func _input(evento: InputEvent) -> void:
	if not (evento is InputEventJoypadButton) or not evento.pressed or evento.echo:
		return
	if (evento as InputEventJoypadButton).button_index != JOY_BUTTON_BACK:
		return
	get_viewport().set_input_as_handled()
	if _painel and _painel.visible:
		_fechar()
	else:
		_abrir()


## Teclas do developer mode: F liga/desliga o FLYMODE, S abre o teclado de
## sons (Execution 9H.18 -- para se poder ouvir cada evento sem ter de o
## provocar em jogo).
func _unhandled_key_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey) or not evento.pressed or evento.echo:
		return
	match (evento as InputEventKey).keycode:
		KEY_F:
			get_viewport().set_input_as_handled()
			_alternar_flymode()
		KEY_S:
			get_viewport().set_input_as_handled()
			if _sons:
				_sons.alternar()


func _montar_botao_topo() -> void:
	var b := Button.new()
	b.name = "BotaoTopo"
	# Texto inicial para o botão já ter tamanho mesmo antes do autoload
	# Textos terminar de carregar a tradução.
	b.text = "TESTAR OUTRO NÍVEL"
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.position = Vector2(-234, 98)
	b.custom_minimum_size = Vector2(220, 30)
	b.add_theme_font_size_override("font_size", 13)
	# SEM FOCO (como o FLYMODE e o BOSS TEST, que ja' o tinham). O ESPACO e'
	# `saltar` E `ui_accept` ao mesmo tempo: se este botao ficasse com o foco
	# depois de um clique, cada salto voltava a carregar nele -- abria o
	# selector de niveis, e o salto seguinte escolhia um nivel, o que em jogo
	# se le como "o espaco da' reset ao nivel". Quem joga a comando tem o
	# atalho do botao SELECT em `_input`.
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.04, 0.11, 0.9)
	sb.border_color = Color(0.95, 0.7, 0.3, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", sb)
	b.pressed.connect(_abrir)
	# Controlos periféricos abaixo do contador de essências do HUD.
	add_child(b)


## Botão FLYMODE -- canto inferior esquerdo, MESMO por cima das barras de
## vida/energia. Alterna o voo livre da Koliani (ver `Koliani.alternar_voo`).
var _btn_fly: Button
var _btn_boss: Button

func _montar_botao_flymode() -> void:
	_btn_fly = Button.new()
	_btn_fly.name = "BotaoFlymode"
	_btn_fly.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_btn_fly.position = Vector2(-234, 134)
	_btn_fly.custom_minimum_size = Vector2(132, 28)
	_btn_fly.focus_mode = Control.FOCUS_NONE
	_btn_fly.add_theme_font_size_override("font_size", 13)
	_btn_fly.pressed.connect(_alternar_flymode)
	add_child(_btn_fly)
	_estilo_flymode(false)


func _montar_botao_testes() -> void:
	_btn_boss = Button.new()
	_btn_boss.name = "BotaoBossTest"
	_btn_boss.text = "BOSS TEST"
	_btn_boss.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_btn_boss.position = Vector2(14, -216)
	_btn_boss.custom_minimum_size = Vector2(132, 28)
	_btn_boss.focus_mode = Control.FOCUS_NONE
	_btn_boss.add_theme_font_size_override("font_size", 13)
	_btn_boss.pressed.connect(_teleportar_ao_boss)
	_estilo_botao_teste(_btn_boss)
	add_child(_btn_boss)


func _estilo_botao_teste(btn: Button) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.04, 0.11, 0.92)
	sb.border_color = Color(0.95, 0.7, 0.3, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	for e in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(e, sb)
	btn.add_theme_color_override("font_color", Color(1, 0.85, 0.4))


func _estilo_flymode(ativo: bool) -> void:
	if _btn_fly == null:
		return
	_btn_fly.text = Textos.t("dev.fly_on" if ativo else "dev.fly_off")
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.35, 0.18, 0.92) if ativo else Color(0.08, 0.04, 0.11, 0.9)
	sb.border_color = Color(0.5, 1.0, 0.55, 0.95) if ativo else Color(0.95, 0.7, 0.3, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	for e in ["normal", "hover", "pressed", "focus"]:
		_btn_fly.add_theme_stylebox_override(e, sb)
	_btn_fly.add_theme_color_override("font_color",
		Color(0.7, 1.0, 0.75) if ativo else Color(1, 0.85, 0.4))


func _alternar_flymode() -> void:
	var k := get_tree().get_first_node_in_group("koliani")
	if k == null or not k.has_method("alternar_voo"):
		return
	_estilo_flymode(bool(k.alternar_voo()))


func _teleportar_ao_boss() -> void:
	var k := get_tree().get_first_node_in_group("koliani") as Node2D
	var boss := get_tree().get_first_node_in_group("chefes") as Node2D
	if k == null or boss == null:
		return
	var escolhido: Node2D = null
	var melhor := INF
	for no in get_tree().get_nodes_in_group("checkpoints"):
		if not (no is Node2D) or (no as Node2D).global_position.x > boss.global_position.x + 20.0:
			continue
		var distancia := boss.global_position.x - (no as Node2D).global_position.x
		if distancia < melhor:
			melhor = distancia
			escolhido = no as Node2D
	if escolhido:
		k.global_position = escolhido.global_position + Vector2(0.0, -42.0)
		k.set("velocity", Vector2.ZERO)
		if "checkpoint_id" in escolhido:
			EstadoJogo.ativar_checkpoint(
				escolhido.get("checkpoint_id"), escolhido.global_position)
	else:
		k.global_position = boss.global_position + Vector2(-220.0, -42.0)
		k.set("velocity", Vector2.ZERO)


func _montar_painel() -> void:
	_painel = Control.new()
	_painel.name = "Painel"
	_painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_painel.visible = false
	# ESCONDER NAO CHEGA. Em Godot, `visible = false` cala o `_gui_input`,
	# mas NAO cala o `_unhandled_input` -- e o `SeletorNiveis` trata la'
	# dentro o `ui_accept`. Como o ESPACO e' `saltar` E `ui_accept` ao mesmo
	# tempo, e saltar nao consome o evento, cada salto em DEV MODE chegava ao
	# selector INVISIVEL, que confirmava o nivel seleccionado e o recarregava.
	# Em jogo lia-se exactamente como a queixa do playtest: "o espaco da'
	# reset ao nivel". Desligado, o painel e' mesmo como se nao estivesse ca'.
	_painel.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_painel)

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.02, 0.01, 0.03, 0.9)
	_painel.add_child(fundo)

	var titulo := Label.new()
	titulo.name = "Titulo"
	titulo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	titulo.position = Vector2(-200, 26)
	titulo.custom_minimum_size = Vector2(400, 0)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	_painel.add_child(titulo)

	_seletor = CENA_SELETOR.instantiate()
	_painel.add_child(_seletor)
	# E' PRECISO DESLIGAR O SELECTOR, NAO SO' O PAINEL: o `SeletorNiveis`
	# poe-se a si proprio em `PROCESS_MODE_ALWAYS` (precisa disso para
	# responder com o jogo em pausa), e `ALWAYS` ignora de proposito o estado
	# dos antepassados -- desligar o painel-pai nao lhe toca.
	_seletor.process_mode = Node.PROCESS_MODE_DISABLED
	_seletor.escolhido.connect(_ir_para)
	_seletor.cancelado.connect(_fechar)


func _traduzir() -> void:
	var estado := get_node_or_null("EstadoDev") as Label
	if estado:
		estado.text = Textos.t("dev.status") % (EstadoJogo.indice_nivel + 1)
	var bt := get_node_or_null("BotaoTopo") as Button
	if bt:
		bt.text = Textos.t("dev.test_level")
	var k := get_tree().get_first_node_in_group("koliani")
	_estilo_flymode(k != null and bool(k.get("_voando")))
	if _painel:
		var titulo := _painel.find_child("Titulo", true, false) as Label
		if titulo:
			titulo.text = Textos.t("dev.title")


func _abrir() -> void:
	if _painel:
		# volta a INHERIT (= ALWAYS, herdado desta barra), para o selector
		# continuar a responder com a arvore em pausa, como sempre respondeu.
		_painel.process_mode = Node.PROCESS_MODE_INHERIT
		_painel.visible = true
	if _seletor:
		_seletor.process_mode = Node.PROCESS_MODE_ALWAYS
		_seletor.configurar(EstadoJogo.indice_nivel, false)
	get_tree().paused = true


func _fechar() -> void:
	if _painel:
		_painel.visible = false
		_painel.process_mode = Node.PROCESS_MODE_DISABLED
	if _seletor:
		_seletor.process_mode = Node.PROCESS_MODE_DISABLED
	# Defesa em profundidade: se algum controlo do painel ficou com o foco,
	# o ESPACO seguinte era consumido por ele em vez de saltar.
	var focado := get_viewport().gui_get_focus_owner()
	if focado:
		focado.release_focus()
	get_tree().paused = false


func _ir_para(i: int) -> void:
	get_tree().paused = false
	EstadoJogo.indice_nivel = clampi(i, 0, EstadoJogo.NIVEIS.size() - 1)
	EstadoJogo.iniciar_sessao_nivel(true)
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_JOGO))
