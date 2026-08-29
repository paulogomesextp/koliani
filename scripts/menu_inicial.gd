extends Control
## Menu inicial (é a `main_scene` do projeto). Mostra o título e leva ao
## jogo. "Continuar" só aparece se houver progresso guardado; "Novo jogo"
## pede confirmação antes de apagar um save existente.
##
## Atalhos de dev (a seguir a `--`):
##   --jogar        salta o menu e arranca já em Main.tscn
##   --foto[=...]   idem (o main.gd trata da captura)
##   --nivel=N      salta o menu e arranca no mundo N (1..4)
## Mantêm os fluxos de captura/headless a funcionar.

const CENA_JOGO := "res://scenes/Main.tscn"

@onready var _continuar: Button = $Centro/Continuar
@onready var _novo: Button = $Centro/NovoJogo
@onready var _aviso: Label = $Centro/Aviso
@onready var _sair: Button = $Centro/Sair

var _novo_armado := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--nivel="):
			EstadoJogo.indice_nivel = clampi(int(a.get_slice("=", 1)) - 1, 0, EstadoJogo.NIVEIS.size() - 1)
			EstadoJogo.checkpoint = Vector2.ZERO
			_ir_jogar()
			return
		if a == "--jogar" or a.begins_with("--foto"):
			_ir_jogar()
			return

	Musica.ambiente(0)  # drone de ambiente por baixo do título
	_aviso.visible = false
	var ha := EstadoJogo.ha_progresso()
	_continuar.visible = ha
	if ha:
		_continuar.text = "Continuar  —  mundo %d" % (EstadoJogo.indice_nivel + 1)
	_continuar.pressed.connect(_ir_jogar)
	_novo.pressed.connect(_ao_novo)
	_sair.pressed.connect(func() -> void: get_tree().quit())
	(_continuar if ha else _novo).grab_focus()


func _ao_novo() -> void:
	if EstadoJogo.ha_progresso() and not _novo_armado:
		_novo_armado = true
		_aviso.visible = true
		_aviso.text = "Isto apaga o progresso guardado."
		_novo.text = "Confirmar  —  recomeçar do início"
		_novo.grab_focus()
		return
	EstadoJogo.reiniciar_campanha()
	_ir_jogar()


func _ir_jogar() -> void:
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_JOGO))
