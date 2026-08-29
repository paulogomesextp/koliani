extends Control
## Menu inicial (é a `main_scene` do projeto). Três formas de jogar:
##
##   NEW GAME       campanha nova, do mundo 1 (apaga o save se existir)
##   LOAD GAME      retoma o save (só aparece se houver progresso)
##   HARDCORE MODE  campanha nova com tempo limite por mundo -- se o tempo
##                  esgotar num mundo é Game Over e recomeça do início
##
## NEW GAME / HARDCORE MODE pedem confirmação quando há um save por cima.
##
## Atalhos de dev (a seguir a `--`):
##   --jogar         salta o menu e arranca já em Main.tscn (retoma o save)
##   --foto[=...]    idem (o main.gd trata da captura)
##   --nivel=N       salta o menu e arranca no mundo N (1..4)
##   --hardcore      salta o menu e arranca uma campanha hardcore nova

const CENA_JOGO := "res://scenes/Main.tscn"

@onready var _novo: Button = $Centro/NovoJogo
@onready var _load: Button = $Centro/LoadGame
@onready var _hardcore: Button = $Centro/Hardcore
@onready var _aviso: Label = $Centro/Aviso
@onready var _sair: Button = $Centro/Sair

# "" (nada), "novo" ou "hardcore" -- qual o botão à espera de confirmação
var _armado := ""


func _ready() -> void:
	if _tratar_atalhos_dev():
		return

	Musica.ambiente(0)  # drone de ambiente por baixo do título
	_aviso.visible = false

	var ha := EstadoJogo.ha_progresso()
	_load.visible = ha
	if ha:
		var extra := "  ·  Hardcore" if EstadoJogo.hardcore else ""
		_load.text = "LOAD GAME  —  mundo %d%s" % [EstadoJogo.indice_nivel + 1, extra]

	_novo.pressed.connect(_ao_novo)
	_load.pressed.connect(_ir_jogar)
	_hardcore.pressed.connect(_ao_hardcore)
	_sair.pressed.connect(func() -> void: get_tree().quit())

	(_load if ha else _novo).grab_focus()


## Devolve true se um atalho de dev tratou o arranque (e já não há menu).
func _tratar_atalhos_dev() -> bool:
	var saltar := false
	var hardcore := false
	var nivel := -1
	for a in OS.get_cmdline_user_args():
		if a == "--jogar" or a.begins_with("--foto"):
			saltar = true
		elif a == "--hardcore":
			saltar = true
			hardcore = true
		elif a.begins_with("--nivel="):
			saltar = true
			nivel = int(a.get_slice("=", 1)) - 1
	if not saltar:
		return false
	if hardcore:
		EstadoJogo.hardcore = true
		EstadoJogo.reiniciar_campanha()
	if nivel >= 0:
		EstadoJogo.indice_nivel = clampi(nivel, 0, EstadoJogo.NIVEIS.size() - 1)
		EstadoJogo.checkpoint = Vector2.ZERO
	_ir_jogar()
	return true


func _ao_novo() -> void:
	if _precisa_confirmar("novo"):
		_armar("novo", _novo, "NEW GAME apaga o progresso guardado.")
		return
	_comecar_campanha(false)


func _ao_hardcore() -> void:
	if _precisa_confirmar("hardcore"):
		_armar("hardcore", _hardcore,
			"HARDCORE MODE apaga o progresso e liga o tempo limite por mundo.")
		return
	_comecar_campanha(true)


## Há um save por cima e este botão ainda não foi confirmado?
func _precisa_confirmar(qual: String) -> bool:
	return EstadoJogo.ha_progresso() and _armado != qual


func _armar(qual: String, botao: Button, texto: String) -> void:
	_repor_botoes()
	_armado = qual
	botao.text = botao.text + "  —  confirmar"
	_aviso.text = texto
	_aviso.visible = true
	botao.grab_focus()


func _repor_botoes() -> void:
	_armado = ""
	_novo.text = "NEW GAME"
	_hardcore.text = "HARDCORE MODE"
	_aviso.visible = false


func _comecar_campanha(hardcore: bool) -> void:
	EstadoJogo.hardcore = hardcore
	EstadoJogo.reiniciar_campanha()
	_ir_jogar()


func _ir_jogar() -> void:
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_JOGO))
