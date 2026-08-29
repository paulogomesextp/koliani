extends CanvasLayer
## Menu de pausa. Abre/fecha com a ação `pausa` (tecla P ou o botão do HUD)
## e com `ui_cancel` (Esc) enquanto está aberto. Põe a árvore em pausa
## (`get_tree().paused`) e oferece: continuar, recomeçar no checkpoint e
## sair. O diário usa o mesmo esquema -- só um deles segura a pausa de cada
## vez (ambos só abrem se a árvore ainda não estiver em pausa).

const CENA_MENU := "res://scenes/ui/MenuInicial.tscn"

@onready var _titulo: Label = $Painel/Coluna/Titulo
@onready var _continuar: Button = $Painel/Coluna/Continuar
@onready var _recomecar: Button = $Painel/Coluna/Recomecar
@onready var _menu: Button = $Painel/Coluna/Menu
@onready var _sair: Button = $Painel/Coluna/Sair


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_continuar.pressed.connect(_fechar)
	_recomecar.pressed.connect(_ao_recomecar)
	_menu.pressed.connect(_ao_menu)
	_sair.pressed.connect(_ao_sair)
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	_traduzir()


func _traduzir() -> void:
	_titulo.text = Textos.t("pause.title")
	_continuar.text = Textos.t("pause.resume")
	_recomecar.text = Textos.t("pause.restart_checkpoint")
	_menu.text = Textos.t("pause.main_menu")
	_sair.text = Textos.t("pause.quit")


func _process(_dt: float) -> void:
	# em _process (não em _input) para apanhar também o TouchScreenButton do
	# HUD, que sinaliza a ação sem gerar um InputEvent que propague
	if Input.is_action_just_pressed("pausa"):
		if visible:
			_fechar()
		elif not get_tree().paused:
			_abrir()
	elif visible and Input.is_action_just_pressed("ui_cancel"):
		_fechar()


func _abrir() -> void:
	visible = true
	get_tree().paused = true
	_continuar.grab_focus()


func _fechar() -> void:
	visible = false
	get_tree().paused = false


func _ao_recomecar() -> void:
	get_tree().paused = false
	Transicao.fechar_e(get_tree().reload_current_scene)


func _ao_menu() -> void:
	get_tree().paused = false
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_MENU))


func _ao_sair() -> void:
	get_tree().paused = false
	get_tree().quit()
