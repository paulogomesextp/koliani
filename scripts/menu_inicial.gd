extends Control
## Menu inicial (é a `main_scene` do projeto). Formas de jogar:
##
##   NEW GAME       campanha nova, do mundo 1 (apaga o save se existir)
##   LOAD GAME      retoma o save (só aparece se houver progresso)
##   HARDCORE MODE  campanha nova com tempo limite por mundo -- se o tempo
##                  esgotar num mundo é Game Over e recomeça do início
##   OPTIONS        volume (música / efeitos) e idioma
##
## NEW GAME / HARDCORE MODE pedem confirmação quando há um save por cima.
## Todo o texto vem do `Textos` (idioma por omissão: inglês).
##
## Em modo normal, NEW GAME / LOAD GAME abrem o **Mapa do Mundo**
## (`MapaMundo.tscn`) para escolher o nível; HARDCORE vai direto ao jogo.
##
## Atalhos de dev (a seguir a `--`):
##   --jogar / --foto[=...]   salta o menu e arranca já em Main.tscn
##   --nivel=N                salta o menu e arranca no mundo N (1..4)
##   --hardcore               salta o menu e arranca uma campanha hardcore
##   --devmode                salta o menu e arranca em DEVELOPER MODE

const CENA_JOGO := "res://scenes/Main.tscn"
const CENA_MAPA := "res://scenes/ui/MapaMundo.tscn"
const CENA_OPCOES := preload("res://scenes/ui/Opcoes.tscn")

@onready var _arte: TextureRect = $Arte
@onready var _subtitulo: Label = $Centro/Subtitulo
@onready var _novo: Button = $Centro/NovoJogo
@onready var _load: Button = $Centro/LoadGame
@onready var _hardcore: Button = $Centro/Hardcore
@onready var _opcoes: Button = $Centro/Opcoes
@onready var _dev: Button = $Centro/DevMode
@onready var _aviso: Label = $Centro/Aviso
@onready var _sair: Button = $Centro/Sair
@onready var _versao: Label = $Versao

# "" (nada), "novo" ou "hardcore" -- qual o botão à espera de confirmação
var _armado := ""


func _ready() -> void:
	_versao.text = "v" + str(ProjectSettings.get_setting("application/config/version", "0.0.0"))

	# voltar ao menu sai do "DEV MODE" -- recarrega o save real do disco
	# (o sandbox de dev nunca é gravado, por isso o progresso fica intacto).
	if EstadoJogo.modo_dev:
		EstadoJogo.modo_dev = false
		if FileAccess.file_exists(EstadoJogo.CAMINHO_SAVE):
			EstadoJogo.carregar()
		else:
			EstadoJogo.reiniciar_campanha()

	# voltar ao menu depois de uma sessão HARDCORE: a vista do menu
	# (LOAD / NEW GAME) é a do modo normal -- volta ao save normal (o do
	# hardcore fica no seu próprio ficheiro, intacto).
	if EstadoJogo.hardcore:
		EstadoJogo.hardcore = false
		EstadoJogo.carregar()

	if _tratar_atalhos_dev():
		return

	Musica.menu()  # tema próprio do menu (por baixo do título)
	_aviso.visible = false
	_deriva_arte()  # leve "Ken Burns" no fundo (key art)

	_novo.pressed.connect(_ao_novo)
	_load.pressed.connect(_entrar_campanha)
	_hardcore.pressed.connect(_ao_hardcore)
	_opcoes.pressed.connect(_abrir_opcoes)
	_dev.pressed.connect(_ao_dev_mode)
	_sair.pressed.connect(_ao_sair)

	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	_traduzir()
	# caveira a seguir a "HARDCORE MODE" (a fonte do jogo não tem o glifo ☠,
	# por isso é um ícone desenhado em código, alinhado à direita do texto)
	_hardcore.icon = _tex_caveira()
	_hardcore.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hardcore.expand_icon = false
	_hardcore.add_theme_constant_override("h_separation", 10)
	var principal := _load if EstadoJogo.ha_progresso() else _novo
	_destacar_botao_principal(principal)
	_preparar_hover_animado()
	principal.grab_focus()


## Dá destaque visual (mais saturado, com glow) ao botão de ação principal
## do momento -- LOAD GAME se há progresso, senão NEW GAME.
func _destacar_botao_principal(botao: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.17, 0.06, 0.21, 0.95)
	normal.set_border_width_all(2)
	normal.border_width_top = 3
	normal.border_color = Color(0.85, 0.35, 0.85, 0.85)
	normal.set_corner_radius_all(10)
	normal.shadow_color = Color(0.75, 0.25, 0.75, 0.35)
	normal.shadow_size = 10
	normal.content_margin_left = 22.0
	normal.content_margin_right = 22.0
	normal.content_margin_top = 15.0
	normal.content_margin_bottom = 15.0

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.34, 0.15, 0.4, 0.98)
	hover.border_color = Color(1, 0.55, 0.95, 1)
	hover.shadow_size = 18
	hover.shadow_color = Color(0.95, 0.4, 0.9, 0.55)

	botao.add_theme_stylebox_override("normal", normal)
	botao.add_theme_stylebox_override("hover", hover)
	botao.add_theme_stylebox_override("focus", hover)
	botao.add_theme_stylebox_override("pressed", hover)
	botao.add_theme_font_size_override("font_size", 22)


## Pequena resposta de escala ao passar/focar o rato em cada botão --
## substitui a mudança de cor estática por algo com mais vida.
func _preparar_hover_animado() -> void:
	for b: Button in [_novo, _load, _hardcore, _opcoes, _dev, _sair]:
		b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
		b.mouse_entered.connect(func() -> void: _animar_escala(b, 1.035))
		b.mouse_exited.connect(func() -> void: _animar_escala(b, 1.0))
		b.focus_entered.connect(func() -> void: _animar_escala(b, 1.035))
		b.focus_exited.connect(func() -> void: _animar_escala(b, 1.0))


func _animar_escala(botao: Button, alvo: float) -> void:
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(botao, "scale", Vector2(alvo, alvo), 0.18)


## Caveira pixel-art minúscula (bone + 2 órbitas + nariz + dentes) para o
## botão do modo hardcore.
func _tex_caveira() -> ImageTexture:
	var img := Image.create(18, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var osso := Color(0.94, 0.92, 0.84)
	var buraco := Color(0.05, 0.02, 0.07)
	# crânio
	for y in range(1, 12):
		for x in range(2, 16):
			var canto := (y <= 1 and (x < 4 or x > 13)) \
				or (x <= 2 and y > 9) or (x >= 15 and y > 9)
			if not canto:
				img.set_pixel(x, y, osso)
	# maxilar + dentes
	for y in range(12, 17):
		for x in range(4, 14):
			if y < 14 or x % 2 == 0:
				img.set_pixel(x, y, osso)
	# órbitas
	for y in range(4, 8):
		for x in range(4, 8):
			img.set_pixel(x, y, buraco)
		for x in range(10, 14):
			img.set_pixel(x, y, buraco)
	# nariz
	for p in [Vector2i(9, 8), Vector2i(8, 10), Vector2i(9, 10), Vector2i(10, 10), Vector2i(9, 9)]:
		img.set_pixel(p.x, p.y, buraco)
	return ImageTexture.create_from_image(img)


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
	_hardcore.text = Textos.t("menu.hardcore")
	_opcoes.text = Textos.t("menu.options")
	_dev.text = Textos.t("menu.dev_mode")
	_sair.text = Textos.t("menu.quit")

	var ha := EstadoJogo.ha_progresso()
	_load.visible = ha
	if ha:
		var txt := Textos.tf("menu.load_world", [EstadoJogo.indice_nivel + 1])
		if EstadoJogo.hardcore:
			txt += Textos.t("menu.hardcore_tag")
		_load.text = txt

	# se um botão estava "armado" para confirmar, repõe o aviso/sufixo
	if _armado == "novo":
		_novo.text += Textos.t("menu.confirm_suffix")
		_aviso.text = Textos.t("menu.warn_new_game")
	elif _armado == "hardcore":
		_hardcore.text += Textos.t("menu.confirm_suffix")
		_aviso.text = Textos.t("menu.warn_hardcore")


## Devolve true se um atalho de dev tratou o arranque (e já não há menu).
func _tratar_atalhos_dev() -> bool:
	var saltar := false
	var hardcore := false
	var devmode := false
	var nivel := -1
	for a in OS.get_cmdline_user_args():
		if a == "--jogar" or a.begins_with("--foto"):
			saltar = true
		elif a == "--hardcore":
			saltar = true
			hardcore = true
		elif a == "--devmode":
			saltar = true
			devmode = true
		elif a.begins_with("--nivel="):
			saltar = true
			nivel = int(a.get_slice("=", 1)) - 1
	if not saltar:
		return false
	if hardcore:
		EstadoJogo.hardcore = true
		EstadoJogo.reiniciar_campanha()
	if devmode:
		EstadoJogo.ativar_modo_dev()
	if nivel >= 0:
		EstadoJogo.indice_nivel = clampi(nivel, 0, EstadoJogo.NIVEIS.size() - 1)
		EstadoJogo.checkpoint = Vector2.ZERO
	_ir_jogar()
	return true


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
	add_child(CENA_OPCOES.instantiate())


## "DEVELOPER MODE": sandbox de testes (habilidades todas, energia
## infinita, sem perder vida) a partir do nível 1. Não mexe no save real; a
## barra "TESTAR OUTRO NÍVEL" (dev_barra.gd) troca de nível dentro do jogo.
func _ao_dev_mode() -> void:
	_repor_botoes()
	EstadoJogo.ativar_modo_dev()
	_ir_jogar()


func _ao_novo() -> void:
	if _precisa_confirmar("novo"):
		_armar("novo", _novo, Textos.t("menu.warn_new_game"))
		return
	_comecar_campanha(false)


## HARDCORE MODE: campanha com tempo limite por mundo. NÃO tem save -- é
## sempre do zero e perder é game over (é esse o conceito). Como não grava,
## também nunca toca no progresso do modo normal, por isso já não precisa
## de confirmação.
func _ao_hardcore() -> void:
	_repor_botoes()
	EstadoJogo.hardcore = true
	EstadoJogo.reiniciar_campanha()
	_entrar_campanha()


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
	_hardcore.text = Textos.t("menu.hardcore")
	_aviso.visible = false


func _comecar_campanha(hardcore: bool) -> void:
	EstadoJogo.hardcore = hardcore
	EstadoJogo.reiniciar_campanha()
	_entrar_campanha()


## Entrada normal na campanha: modo normal abre o Mapa do Mundo (escolher
## nível); hardcore vai direto ao jogo (corre linear).
func _entrar_campanha() -> void:
	var destino := CENA_JOGO if EstadoJogo.hardcore else CENA_MAPA
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(destino))


## Salto direto para o jogo -- usado só pelos atalhos de dev (--jogar/--nivel).
func _ir_jogar() -> void:
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_JOGO))
