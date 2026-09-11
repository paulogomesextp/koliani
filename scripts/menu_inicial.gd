extends Control
## Menu inicial (é a `main_scene` do projeto). Formas de jogar:
##
##   NEW GAME       campanha nova, do mundo 1 (apaga o save se existir)
##   LOAD GAME      retoma o save (só aparece se houver progresso)
##   OPTIONS        volume (música / efeitos) e idioma
##
## NEW GAME pede confirmação quando há um save por cima.
## Todo o texto vem do `Textos` (idioma por omissão: inglês).
##
## Em modo normal, NEW GAME / LOAD GAME abrem o **Mapa do Mundo**
## (`MapaMundo.tscn`) para escolher o nível.
##
## Atalhos de dev (a seguir a `--`):
##   --jogar / --foto[=...]   salta o menu e arranca já em Main.tscn
##   --nivel=N                salta o menu e arranca no mundo N (1..4)
##   --devmode                salta o menu e arranca em DEVELOPER MODE

const CENA_JOGO := "res://scenes/Main.tscn"
const CENA_MAPA := "res://scenes/ui/MapaMundo.tscn"
const CENA_OPCOES := preload("res://scenes/ui/Opcoes.tscn")

@onready var _arte: TextureRect = $Arte
@onready var _subtitulo: Label = $Centro/Subtitulo
@onready var _novo: Button = $Centro/NovoJogo
@onready var _load: Button = $Centro/LoadGame
@onready var _opcoes: Button = $Centro/Opcoes
@onready var _espaco_dev: Control = $Centro/EspacoDev
@onready var _dev: Button = $Centro/DevMode
@onready var _aviso: Label = $Centro/Aviso
@onready var _sair: Button = $Centro/Sair
@onready var _versao: Label = $Versao

# "" (nada) ou "novo" -- qual o botão à espera de confirmação
var _armado := ""


func _ready() -> void:
	_versao.text = "v" + str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	print("RUNTIME TRACE | build=%s | main_scene=res://scenes/ui/MenuInicial.tscn" %
		str(ProjectSettings.get_setting("application/config/version", "0.0.0")))
	# A entrada de desenvolvimento pertence ao editor/export-debug. O export
	# release mantém os atalhos de captura, mas nunca oferece um caminho normal
	# para BOSS TEST / TESTAR OUTRO NÍVEL / FLYMODE.
	var permitir_dev := OS.is_debug_build()
	_espaco_dev.visible = permitir_dev
	_dev.visible = permitir_dev

	# voltar ao menu sai do "DEV MODE" -- recarrega o save real do disco
	# (o sandbox de dev nunca é gravado, por isso o progresso fica intacto).
	if EstadoJogo.modo_dev:
		EstadoJogo.modo_dev = false
		if FileAccess.file_exists(EstadoJogo.CAMINHO_SAVE):
			EstadoJogo.carregar()
		else:
			EstadoJogo.reiniciar_campanha()

	if _tratar_atalhos_dev():
		return

	Musica.menu()  # tema próprio do menu (por baixo do título)
	_aviso.visible = false
	_deriva_arte()  # leve "Ken Burns" no fundo (key art)

	_novo.pressed.connect(_ao_novo)
	_load.pressed.connect(_entrar_campanha)
	_opcoes.pressed.connect(_abrir_opcoes)
	_dev.pressed.connect(_ao_dev_mode)
	_sair.pressed.connect(_ao_sair)

	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	_traduzir()
	# Execution 9F: botões e título no kit de produção (prancha 09)
	UIProducao.vestir_ecra(self)
	UIProducao.titulo($Centro/Titulo, 68)
	$Centro/Titulo.add_theme_color_override("font_shadow_color", Color(0.55, 0.22, 0.75, 0.45))
	var principal := _load if EstadoJogo.ha_progresso() else _novo
	_destacar_botao_principal(principal)
	_preparar_hover_animado()
	principal.grab_focus()
	_agendar_prova_runtime()


## Dá destaque visual (mais saturado, com glow) ao botão de ação principal
## do momento -- LOAD GAME se há progresso, senão NEW GAME.
##
## Com o kit de produção (9F) o destaque é a MOLDURA DE OURO do botão
## selecionado da prancha 09 -- o foco já a desenha; aqui só sobe a letra.
func _destacar_botao_principal(botao: Button) -> void:
	botao.add_theme_font_size_override("font_size", 22)
	botao.custom_minimum_size.y = 58.0


## Pequena resposta de escala ao passar/focar o rato em cada botão --
## substitui a mudança de cor estática por algo com mais vida.
func _preparar_hover_animado() -> void:
	for b: Button in [_novo, _load, _opcoes, _sair]:
		b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
		b.mouse_entered.connect(func() -> void: _animar_escala(b, 1.035))
		b.mouse_exited.connect(func() -> void: _animar_escala(b, 1.0))
		b.focus_entered.connect(func() -> void: _animar_escala(b, 1.035))
		b.focus_exited.connect(func() -> void: _animar_escala(b, 1.0))
	if _dev.visible:
		_dev.resized.connect(func() -> void: _dev.pivot_offset = _dev.size / 2.0)
		_dev.mouse_entered.connect(func() -> void: _animar_escala(_dev, 1.035))
		_dev.mouse_exited.connect(func() -> void: _animar_escala(_dev, 1.0))
		_dev.focus_entered.connect(func() -> void: _animar_escala(_dev, 1.035))
		_dev.focus_exited.connect(func() -> void: _animar_escala(_dev, 1.0))


func _animar_escala(botao: Button, alvo: float) -> void:
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(botao, "scale", Vector2(alvo, alvo), 0.18)


## (Re)escreve todo o texto do menu no idioma atual.
## SAIR. `get_tree().quit()` fecha o executável de Windows e a app de
## Android. Na WEB não fecha nada -- o Godot corre dentro de um separador e
## não é ele que manda nele.
##
## A primeira tentativa foi o `window.close()`, contando com o browser o
## aceitar numa app instalada. O Paulo foi experimentar no Chrome e não
## fechou: o `close()` só é permitido numa janela que o próprio script
## abriu, e uma PWA não conta. Não há maneira de o contornar -- é a regra
## do browser, e é assim de propósito.
##
## Então o QUIT faz o que PODE fazer, e faz até ao fim: tenta fechar, e se
## a janela ficar, apaga a página e desliga o motor. A app fica desligada,
## que era o pedido; o que sobra é um separado vazio a dizer que pode ser
## fechado -- e isso só o dedo dele é que pode fazer.
const JS_FECHAR := "(function(){try{window.close();}catch(e){}setTimeout(function(){if(window.closed||!document.body)return;document.body.innerHTML=\"<div style='position:fixed;inset:0;display:flex;align-items:center;justify-content:center;flex-direction:column;gap:1rem;background:#0d0814;color:#ece6f7;font:600 5vmin/1.4 -apple-system,system-ui,sans-serif;text-align:center;padding:8vmin'>KOLIANI<span style='font-size:3.4vmin;font-weight:400;color:#8d7ea9'>The game is closed. You can close this tab.</span></div>\";},260);})();"


func _ao_sair() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(JS_FECHAR, true)
		# dá tempo ao `close()` de acontecer antes de se matar o motor: se a
		# janela fechar mesmo, nunca se chega a ver a página apagada
		await get_tree().create_timer(0.45).timeout
	get_tree().quit()


func _traduzir() -> void:
	_subtitulo.text = Textos.t("game.subtitle")
	_novo.text = Textos.t("menu.new_game")
	_opcoes.text = Textos.t("menu.options")
	_dev.text = Textos.t("menu.dev_mode")
	_sair.text = Textos.t("menu.quit")

	var ha := EstadoJogo.ha_progresso()
	_load.visible = ha
	if ha:
		var txt := Textos.tf("menu.load_world", [EstadoJogo.indice_nivel + 1])
		_load.text = txt

	# se um botão estava "armado" para confirmar, repõe o aviso/sufixo
	if _armado == "novo":
		_novo.text += Textos.t("menu.confirm_suffix")
		_aviso.text = Textos.t("menu.warn_new_game")


## Devolve true se um atalho de dev tratou o arranque (e já não há menu).
func _tratar_atalhos_dev() -> bool:
	var saltar := false
	var devmode := false
	var nivel := -1
	for a in OS.get_cmdline_user_args():
		if a == "--jogar" or a == "--foto" or a.begins_with("--foto="):
			saltar = true
		elif a == "--devmode" and OS.is_debug_build():
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


## Prova invisível do export: fotografa as cenas reais do fluxo normal. Não
## ativa modo dev nem reconstrói UI fora do produto.
func _agendar_prova_runtime() -> void:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--foto-menu="):
			_tirar_foto_menu.call_deferred(argumento.get_slice("=", 1))
			return
		if argumento.begins_with("--foto-mapa="):
			get_tree().change_scene_to_file.call_deferred(CENA_MAPA)
			return


func _tirar_foto_menu(caminho: String) -> void:
	await get_tree().create_timer(0.8).timeout
	var imagem := get_viewport().get_texture().get_image()
	imagem.save_png(caminho)
	print("PROVA RUNTIME MENU: ", caminho)
	get_tree().quit(0)


## Deriva muito lenta do fundo (a `Arte` é maior que o ecrã, sobra folga).
func _deriva_arte() -> void:
	if _arte == null:
		return
	var base := _arte.position
	var t := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_arte, "position", base + Vector2(46, -30), 24.0)
	t.tween_property(_arte, "position", base + Vector2(-40, 24), 26.0)
	t.tween_property(_arte, "position", base, 22.0)


func _abrir_opcoes() -> void:
	_repor_botoes()
	var o := CENA_OPCOES.instantiate()
	# 9F: ao fechar, o foco volta ao menu -- sem isto o teclado/comando
	# ficavam sem botão nenhum (↓/↑ não faziam nada)
	o.tree_exited.connect(func() -> void:
		if is_inside_tree():
			_opcoes.grab_focus())
	add_child(o)


## "DEVELOPER MODE": sandbox de testes (habilidades todas, energia
## infinita, sem perder vida) a partir do nível 1. Não mexe no save real; a
## barra "TESTAR OUTRO NÍVEL" (dev_barra.gd) troca de nível dentro do jogo.
func _ao_dev_mode() -> void:
	if not OS.is_debug_build():
		return
	_repor_botoes()
	EstadoJogo.ativar_modo_dev()
	_ir_jogar()


func _ao_novo() -> void:
	if _precisa_confirmar("novo"):
		_armar("novo", _novo, Textos.t("menu.warn_new_game"))
		return
	_comecar_campanha()


## Há um save por cima e este botão ainda não foi confirmado?
func _precisa_confirmar(qual: String) -> bool:
	return EstadoJogo.ha_progresso() and _armado != qual


func _armar(qual: String, botao: Button, texto: String) -> void:
	_repor_botoes()
	_armado = qual
	botao.text = botao.text + Textos.t("menu.confirm_suffix")
	_aviso.text = texto
	_aviso.visible = true
	botao.grab_focus()


func _repor_botoes() -> void:
	_armado = ""
	_novo.text = Textos.t("menu.new_game")
	_aviso.visible = false


func _comecar_campanha() -> void:
	EstadoJogo.reiniciar_campanha()
	_entrar_campanha()


## Entrada normal na campanha: abre o Mapa do Mundo para escolher o nível.
func _entrar_campanha() -> void:
	# Fechar a aplicação preserva a sessão: LOAD regressa ao último checkpoint
	# seguro. Sem sessão ativa, o fluxo normal continua a abrir o mapa.
	var destino := CENA_JOGO if EstadoJogo.level_session.get("active", false) else CENA_MAPA
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(destino))


## Salto direto para o jogo -- usado só pelos atalhos de dev (--jogar/--nivel).
func _ir_jogar() -> void:
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_JOGO))
