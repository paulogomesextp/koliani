extends CanvasLayer
## Menu de pausa. Abre/fecha com a ação `pausa` (tecla P ou Esc no PC, ou o
## botão do HUD) e também fecha com `ui_cancel`. Põe a árvore em pausa
## (`get_tree().paused`) e oferece duas saídas -- **Mapa de níveis** e
## **Menu principal** -- além de Continuar. Em HARDCORE (sem mapa) o botão
## do mapa dá lugar a "Recomeçar no checkpoint".
##
## O diário usa o mesmo esquema -- só um deles segura a pausa de cada vez
## (ambos só abrem se a árvore ainda não estiver em pausa).

const CENA_MENU := "res://scenes/ui/MenuInicial.tscn"
const CENA_MAPA := "res://scenes/ui/MapaMundo.tscn"

@onready var _titulo: Label = $Painel/Coluna/Titulo
@onready var _continuar: Button = $Painel/Coluna/Continuar
@onready var _mapa: Button = $Painel/Coluna/Mapa
@onready var _recomecar: Button = $Painel/Coluna/Recomecar
@onready var _menu: Button = $Painel/Coluna/Menu


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_continuar.pressed.connect(_fechar)
	_mapa.pressed.connect(_ao_mapa)
	_recomecar.pressed.connect(_ao_recomecar)
	_menu.pressed.connect(_ao_menu)
	# HARDCORE é linear e não tem Mapa do Mundo -> troca o botão.
	var hardcore: bool = EstadoJogo.hardcore
	_mapa.visible = not hardcore
	_recomecar.visible = hardcore
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	_traduzir()


func _traduzir() -> void:
	_titulo.text = Textos.t("pause.title")
	_continuar.text = Textos.t("pause.resume")
	_mapa.text = Textos.t("pause.level_map")
	_recomecar.text = Textos.t("pause.restart_checkpoint")
	_menu.text = Textos.t("pause.main_menu")


func _process(_dt: float) -> void:
	# em _process (não em _input) para apanhar também o TouchScreenButton do
	# HUD, que sinaliza a ação sem gerar um InputEvent que propague.
	# Se o ecrã de equipamento (HUD) estiver aberto, é ele que trata o Esc.
	if get_tree().paused and not visible:
		return
	var alternar := Input.is_action_just_pressed("pausa")
	if visible:
		if alternar or Input.is_action_just_pressed("ui_cancel"):
			_fechar()
	elif alternar and not get_tree().paused:
		_abrir()


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


## Sai para o Mapa do Mundo sem guardar progresso do nível (o nível recomeça
## do início da próxima vez).
func _ao_mapa() -> void:
	get_tree().paused = false
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_MAPA))


func _ao_menu() -> void:
	get_tree().paused = false
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_MENU))
