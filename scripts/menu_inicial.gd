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
	_sair.pressed.connect(func() -> void: get_tree().quit())

	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	_traduzir()
	(_load if EstadoJogo.ha_progresso() else _novo).grab_focus()


## (Re)escreve todo o texto do menu no idioma atual.
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


func _ao_hardcore() -> void:
	if _precisa_confirmar("hardcore"):
		_armar("hardcore", _hardcore, Textos.t("menu.warn_hardcore"))
		return
	_comecar_campanha(true)


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
