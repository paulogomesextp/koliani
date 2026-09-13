extends Control
## Menu inicial (é a cena que a intro abre, e a `main_scene` quando não há
## intro). Execution 9H: refeito sobre a prancha aprovada
## `10_menu_rebrand/01_main_menu_approved` -- arte limpa por baixo
## (`fundo_menu`, a prancha com a UI pintada retirada) e a UI viva por cima,
## nas coordenadas da própria prancha.
##
## Entradas, na ordem da prancha:
##
##   CONTINUAR        retoma a sessão/checkpoint (só com progresso)
##   NOVO JOGO        campanha nova (pede confirmação se há save)
##   SELECIONAR NÍVEL abre o Mapa do Mundo
##   OPÇÕES           volume, idioma, layout de toque
##   SAIR
##
## Todo o texto vem do `Textos`. O canto inferior direito tem a versão e o
## crédito, como o Game Master pediu; os textos que ele mandou tirar dos
## cantos de baixo não voltaram.
##
## Atalhos de dev (a seguir a `--`):
##   --jogar / --foto[=...]   salta o menu e arranca já em Main.tscn
##   --nivel=N                salta o menu e arranca no nível N
##   --devmode                salta o menu e arranca em DEVELOPER MODE

const CENA_JOGO := "res://scenes/Main.tscn"
const CENA_MAPA := "res://scenes/ui/MapaMundo.tscn"
const CENA_OPCOES := preload("res://scenes/ui/Opcoes.tscn")

## Medidas da prancha, já em coordenadas do palco (1280x720). O eixo da
## coluna é o mesmo do logótipo: x=805.
const EIXO := 805.0
const LARG_COLUNA := 330.0
const Y_COLUNA := 280.0
const ALT_BOTAO := 46.0
const ALT_SEPARADOR := 12.0
const Y_RODAPE := 604.0

var _palco: Control
var _coluna: VBoxContainer
var _aviso: Label
var _premir: Label
var _versao: Label
var _credito: Label
var _dev: Button
var _realce: TextureRect
var _botoes := {}          # chave -> Button
var _armado := ""          # "" ou "novo" -- botão à espera de confirmação
## O foco inicial não toca nada: um "ding" a abrir o menu soa a erro.
var _pronto_para_som := false


func _ready() -> void:
	print("RUNTIME TRACE | build=%s | main_scene=%s | frontend=9H" % [
		str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		str(ProjectSettings.get_setting("application/run/main_scene", "?"))])

	# Voltar ao menu repõe a sessão legítima em memória, sem escrever saves.
	if EstadoJogo.modo_dev:
		EstadoJogo.desativar_modo_dev()

	if _tratar_atalhos_dev():
		return

	Frontend9H.vestir(self)
	_montar()
	Musica.menu()
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	_traduzir()
	_focar_principal()
	_pronto_para_som = true
	_agendar_prova_runtime()


# ── montagem ─────────────────────────────────────────────────────────────

func _montar() -> void:
	_palco = Frontend9H.palco(self, "fundo_menu")
	# a prancha escurece a coluna dos botões; aqui isso é um véu, e é ele
	# que segura a legibilidade quando a arte por baixo é clara
	_palco.add_child(Frontend9H.veu(Vector2(EIXO - 330.0, 0.0), Vector2(EIXO + 330.0, 720.0), 0.5))
	_palco.add_child(Frontend9H.vinheta())

	# 9H.17 E: o Game Master congelou o menu com o logotipo SOZINHO. O
	# subtitulo ("FLORESTA SAGRADA") saiu, e com ele as duas riscas que o
	# ladeavam -- sem texto no meio ficavam dois tracos orfaos a meio do ar.
	# A chave `menu.tagline` fica nos 6 i18n (nao se mexe nas chaves por um
	# rotulo que pode voltar).

	_realce = Frontend9H.realce()
	_realce.modulate.a = 0.0
	_palco.add_child(_realce)

	_coluna = VBoxContainer.new()
	_coluna.add_theme_constant_override("separation", 0)
	_coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Frontend9H.por(_coluna, Rect2(EIXO - LARG_COLUNA * 0.5, Y_COLUNA, LARG_COLUNA, 320.0))
	_palco.add_child(_coluna)

	var chaves := ["continuar", "novo", "niveis", "opcoes", "sair"]
	for i in chaves.size():
		if i > 0:
			var caixa := CenterContainer.new()
			caixa.custom_minimum_size = Vector2(0, ALT_SEPARADOR)
			caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var s := Frontend9H.separador()
			s.custom_minimum_size = Vector2(LARG_COLUNA * 0.9, ALT_SEPARADOR)
			s.modulate = Color(1, 1, 1, 0.8)
			caixa.add_child(s)
			_coluna.add_child(caixa)
		var b := Button.new()
		b.name = chaves[i].capitalize()
		b.custom_minimum_size = Vector2(0, ALT_BOTAO)
		Frontend9H.rotulo_menu(b, 26)
		# o destaque é a PLACA da prancha, e quem a desenha é o foco: sem
		# isto o rato ficava com uma placa e o comando com outra
		b.mouse_entered.connect(b.grab_focus)
		b.focus_entered.connect(func() -> void:
			_mover_realce(b)
			if _pronto_para_som:
				Som.toca("ui_mover", -13.0, randf_range(0.97, 1.04)))
		b.pressed.connect(func() -> void: Som.toca("ui_confirmar", -8.0))
		b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
		_coluna.add_child(b)
		_botoes[chaves[i]] = b

	_botoes["continuar"].pressed.connect(_ao_continuar)
	_botoes["novo"].pressed.connect(_ao_novo)
	_botoes["niveis"].pressed.connect(_ao_niveis)
	_botoes["opcoes"].pressed.connect(_abrir_opcoes)
	_botoes["sair"].pressed.connect(_ao_sair)

	_aviso = Label.new()
	Frontend9H.corpo(_aviso, 15, Color(1.0, 0.62, 0.45))
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.visible = false
	_aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Frontend9H.por(_aviso, Rect2(EIXO - 300.0, Y_RODAPE + 18.0, 600.0, 40.0))
	_palco.add_child(_aviso)

	# 9H.17 D -- A ENTRADA DE DESENVOLVIMENTO. Ela ja' ca' estava; o que nao
	# estava era VISIVEL. Vivia atras de `OS.is_debug_build()`, e a build que
	# o Game Master abre e' de RELEASE -- por isso, do lado dele, o modo Dev
	# simplesmente nao existia. Um export de release nao deixa de ser uma
	# build de QA so' porque foi exportado sem debug.
	#
	# Passa a mandar um interruptor proprio, `koliani/qa/entrada_dev`, para a
	# visibilidade nao depender de como a build foi exportada. Fica LIGADO
	# aqui; a apresentacao publica final exporta com ele desligado.
	#
	# E sai do meio para o canto INFERIOR ESQUERDO: e' para se encontrar, nao
	# para competir com a coluna dos botoes nem com o logotipo.
	_dev = Button.new()
	_dev.visible = EstadoJogo.entrada_dev_disponivel()
	Frontend9H.rotulo_menu(_dev, 13)
	_dev.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_dev.add_theme_color_override("font_color", Color(0.78, 0.66, 0.34, 0.62))
	_dev.add_theme_color_override("font_hover_color", Color(1.0, 0.86, 0.46, 1.0))
	_dev.pressed.connect(_ao_dev_mode)
	Frontend9H.por(_dev, Rect2(22.0, 676.0, 190.0, 26.0))
	_palco.add_child(_dev)

	var orn := Frontend9H.separador("ornamento_rodape")
	Frontend9H.por(orn, Rect2(EIXO - 205.0, Y_RODAPE, 410.0, 20.0))
	_palco.add_child(orn)

	_premir = Label.new()
	Frontend9H.capitular(_premir, 14, Frontend9H.TEXTO_APAGADO)
	_premir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Frontend9H.por(_premir, Rect2(EIXO - 250.0, Y_RODAPE + 22.0, 500.0, 26.0))
	_palco.add_child(_premir)

	_versao = Label.new()
	Frontend9H.corpo(_versao, 14, Frontend9H.TEXTO_APAGADO)
	_versao.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_versao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Frontend9H.por(_versao, Rect2(1000.0, 624.0, 262.0, 22.0))
	_palco.add_child(_versao)

	_credito = Label.new()
	Frontend9H.corpo(_credito, 13, Frontend9H.TEXTO_APAGADO)
	_credito.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_credito.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Frontend9H.por(_credito, Rect2(1000.0, 645.0, 262.0, 22.0))
	_palco.add_child(_credito)

	var orn2 := Frontend9H.separador()
	orn2.modulate = Color(1, 1, 1, 0.5)
	Frontend9H.por(orn2, Rect2(1140.0, 668.0, 120.0, 14.0))
	_palco.add_child(orn2)

	_folhas()


## Folhas vermelhas a atravessar o ecrã, como as da prancha. É o único
## movimento do menu: a arte é uma composição fechada e mexê-la inteira
## (o "Ken Burns" que aqui estava) tirava o logótipo do sítio.
func _folhas() -> void:
	var p := CPUParticles2D.new()
	p.name = "Folhas"
	p.amount = 22
	p.lifetime = 9.0
	p.preprocess = 6.0
	p.position = Vector2(0, -30)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(700, 10)
	p.direction = Vector2(0.55, 1)
	p.spread = 22.0
	p.gravity = Vector2(14, 26)
	p.initial_velocity_min = 26.0
	p.initial_velocity_max = 58.0
	p.angular_velocity_min = -70.0
	p.angular_velocity_max = 70.0
	p.scale_amount_min = 1.6
	p.scale_amount_max = 3.4
	p.color = Color(0.78, 0.10, 0.16, 0.62)
	var folha := Control.new()
	folha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	folha.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	folha.add_child(p)
	_palco.add_child(folha)
	folha.resized.connect(func() -> void:
		p.position = Vector2(folha.size.x * 0.5, -30.0)
		p.emission_rect_extents = Vector2(folha.size.x * 0.6, 10.0))


## Leva a placa até ao botão com foco. A primeira vez salta (senão via-se a
## placa a vir do canto superior esquerdo no arranque).
func _mover_realce(botao: Button) -> void:
	if _realce == null or not botao.is_inside_tree():
		return
	await get_tree().process_frame
	if not is_instance_valid(botao) or not botao.is_inside_tree():
		return
	var alvo := Rect2(botao.position + _coluna.position - Vector2(12, 5),
		botao.size + Vector2(24, 10))
	if _realce.modulate.a < 0.05:
		_realce.position = alvo.position
		_realce.size = alvo.size
		_realce.modulate.a = 1.0
		return
	var t := create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(_realce, "position", alvo.position, 0.17)
	t.tween_property(_realce, "size", alvo.size, 0.17)


func _focar_principal() -> void:
	var principal: Button = _botoes["continuar"] if EstadoJogo.ha_progresso() else _botoes["novo"]
	principal.grab_focus()


# ── texto ────────────────────────────────────────────────────────────────

func _traduzir() -> void:
	var ha := EstadoJogo.ha_progresso()
	_botoes["continuar"].visible = ha
	_botoes["continuar"].text = Textos.t("menu.continue")
	_botoes["novo"].text = Textos.t("menu.new_game")
	_botoes["niveis"].text = Textos.t("menu.select_level")
	_botoes["opcoes"].text = Textos.t("menu.options")
	_botoes["sair"].text = Textos.t("menu.quit")
	_dev.text = Textos.t("menu.dev_mode")
	var toque := DisplayServer.is_touchscreen_available()
	_premir.text = Frontend9H.espacar(
		Textos.t("menu.tap_play" if toque else "menu.press_enter"), 1)
	_versao.text = "v" + str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	_credito.text = Textos.t("menu.developed_by")
	if _armado == "novo":
		_botoes["novo"].text += Textos.t("menu.confirm_suffix")
		_aviso.text = Textos.t("menu.warn_new_game")


# ── ações ────────────────────────────────────────────────────────────────

func _ao_continuar() -> void:
	_repor_botoes()
	_entrar_campanha()


func _ao_novo() -> void:
	if EstadoJogo.ha_progresso() and _armado != "novo":
		_armar("novo", _botoes["novo"], Textos.t("menu.warn_new_game"))
		return
	_repor_botoes()
	EstadoJogo.reiniciar_campanha()
	_entrar_campanha()


func _ao_niveis() -> void:
	_repor_botoes()
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_MAPA))


func _armar(qual: String, botao: Button, texto: String) -> void:
	_repor_botoes()
	_armado = qual
	botao.text = botao.text + Textos.t("menu.confirm_suffix")
	_aviso.text = texto
	_aviso.visible = true
	_premir.visible = false
	botao.grab_focus()


func _repor_botoes() -> void:
	_armado = ""
	_botoes["novo"].text = Textos.t("menu.new_game")
	_aviso.visible = false
	_premir.visible = true


func _abrir_opcoes() -> void:
	_repor_botoes()
	var o := CENA_OPCOES.instantiate()
	o.tree_exited.connect(func() -> void:
		if is_inside_tree():
			_botoes["opcoes"].grab_focus())
	add_child(o)


func _ao_dev_mode() -> void:
	if not EstadoJogo.entrada_dev_disponivel():
		return
	_repor_botoes()
	EstadoJogo.ativar_modo_dev()
	_ir_jogar()


## SAIR. `get_tree().quit()` fecha o executável de Windows e a app de
## Android. Na WEB não fecha nada -- o Godot corre dentro de um separador e
## não é ele que manda nele. O `window.close()` só é permitido numa janela
## que o próprio script abriu, e uma PWA não conta (experimentado no Chrome).
## Então o QUIT faz o que PODE: tenta fechar e, se a janela ficar, apaga a
## página e desliga o motor.
const JS_FECHAR := "(function(){try{window.close();}catch(e){}setTimeout(function(){if(window.closed||!document.body)return;document.body.innerHTML=\"<div style='position:fixed;inset:0;display:flex;align-items:center;justify-content:center;flex-direction:column;gap:1rem;background:#0b0509;color:#fdf6f3;font:600 5vmin/1.4 -apple-system,system-ui,sans-serif;text-align:center;padding:8vmin'>KOLIANI<span style='font-size:3.4vmin;font-weight:400;color:#94838a'>The game is closed. You can close this tab.</span></div>\";},260);})();"


func _ao_sair() -> void:
	Som.toca("ui_voltar", -8.0)
	if OS.has_feature("web"):
		JavaScriptBridge.eval(JS_FECHAR, true)
		await get_tree().create_timer(0.45).timeout
	get_tree().quit()


## Entrada normal na campanha: retoma a sessão se houver, senão abre o mapa.
func _entrar_campanha() -> void:
	var destino := CENA_JOGO if EstadoJogo.level_session.get("active", false) else CENA_MAPA
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(destino))


func _ir_jogar() -> void:
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_JOGO))


# ── dev / prova ──────────────────────────────────────────────────────────

## Devolve true se um atalho de dev tratou o arranque (e já não há menu).
func _tratar_atalhos_dev() -> bool:
	var saltar := false
	var devmode := false
	var nivel := -1
	for a in OS.get_cmdline_user_args():
		if a == "--jogar" or a == "--foto" or a.begins_with("--foto="):
			saltar = true
		elif a == "--devmode" and EstadoJogo.entrada_dev_disponivel():
			saltar = true
			devmode = true
		elif a.begins_with("--nivel="):
			saltar = true
			nivel = int(a.get_slice("=", 1)) - 1
	if not saltar:
		return false
	if devmode:
		EstadoJogo.ativar_modo_dev()
	if nivel >= 0:
		EstadoJogo.indice_nivel = clampi(nivel, 0, EstadoJogo.NIVEIS.size() - 1)
		EstadoJogo.iniciar_sessao_nivel(true)
	_ir_jogar()
	return true


## Prova invisível do export: fotografa as cenas reais do fluxo normal.
func _agendar_prova_runtime() -> void:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--foto-menu="):
			_tirar_foto_menu.call_deferred(argumento.get_slice("=", 1))
			return
		if argumento.begins_with("--foto-mapa="):
			get_tree().change_scene_to_file.call_deferred(CENA_MAPA)
			return
		# 9H.1: prova do SELETOR com a pele da região, no export real.
		#   --foto-seletor=<png>@<indice do nível>
		if argumento.begins_with("--foto-seletor="):
			var arg := argumento.get_slice("=", 1)
			var cam := arg.get_slice("@", 0)
			var idx := int(arg.get_slice("@", 1)) if "@" in arg else 0
			_tirar_foto_seletor.call_deferred(cam, idx)
			return


## Abre o `SeletorNiveis` como o jogo o abre (mesma cena, mesma
## `configurar`) e fotografa-o. `indice` escolhe a região: 0 = Região I
## (pele de floresta), 20 = Região V (apresentação neutra).
func _tirar_foto_seletor(caminho: String, indice: int) -> void:
	var cena: PackedScene = load("res://scenes/ui/SeletorNiveis.tscn")
	var no: Control = cena.instantiate()
	add_child(no)
	no.set_anchors_preset(Control.PRESET_FULL_RECT)
	no.configurar(indice, false)
	for _i in 40:
		await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	var imagem := get_viewport().get_texture().get_image()
	imagem.save_png(caminho)
	print("PROVA RUNTIME SELETOR: ", caminho, " regiao ", EstadoJogo.regiao_do_nivel(indice) + 1)
	get_tree().quit(0)


func _tirar_foto_menu(caminho: String) -> void:
	await get_tree().create_timer(1.0).timeout
	var imagem := get_viewport().get_texture().get_image()
	imagem.save_png(caminho)
	print("PROVA RUNTIME MENU: ", caminho)
	get_tree().quit(0)
