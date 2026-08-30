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
const CENA_SELETOR_EQUIP := preload("res://scenes/ui/SeletorEquip.tscn")

@onready var _titulo: Label = $Painel/Coluna/Titulo
@onready var _continuar: Button = $Painel/Coluna/Continuar
@onready var _mapa: Button = $Painel/Coluna/Mapa
@onready var _recomecar: Button = $Painel/Coluna/Recomecar
@onready var _menu: Button = $Painel/Coluna/Menu

var _painel: Control
var _btn_armas: Button
var _btn_armaduras: Button
var _seletor: SeletorEquip


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_painel = $Painel
	_continuar.pressed.connect(_fechar)
	_mapa.pressed.connect(_ao_mapa)
	_recomecar.pressed.connect(_ao_recomecar)
	_menu.pressed.connect(_ao_menu)
	_montar_botoes_equip()
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
	if _btn_armas:
		_btn_armas.text = Textos.t("gear.menu.weapons")
	if _btn_armaduras:
		_btn_armaduras.text = Textos.t("gear.menu.armor")


## Dois botões "ARMAS" / "ARMADURAS" no menu de pausa (a seguir a Continuar).
func _montar_botoes_equip() -> void:
	var coluna := _continuar.get_parent()
	_btn_armas = _clonar_botao(_continuar, "BtnArmas")
	_btn_armaduras = _clonar_botao(_continuar, "BtnArmaduras")
	coluna.add_child(_btn_armas)
	coluna.move_child(_btn_armas, _continuar.get_index() + 1)
	coluna.add_child(_btn_armaduras)
	coluna.move_child(_btn_armaduras, _btn_armas.get_index() + 1)
	_btn_armas.pressed.connect(_abrir_equip.bind("arma"))
	_btn_armaduras.pressed.connect(_abrir_equip.bind("armadura"))


func _clonar_botao(modelo: Button, nome: String) -> Button:
	var b := Button.new()
	b.name = nome
	for e in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := modelo.get_theme_stylebox(e)
		if sb:
			b.add_theme_stylebox_override(e, sb)
	var fc := modelo.get_theme_color("font_color")
	b.add_theme_color_override("font_color", fc)
	var fs := modelo.get_theme_font_size("font_size")
	if fs > 0:
		b.add_theme_font_size_override("font_size", fs)
	b.custom_minimum_size = modelo.custom_minimum_size
	return b


func _abrir_equip(tipo: String) -> void:
	if _seletor and is_instance_valid(_seletor):
		return
	_painel.visible = false
	_seletor = CENA_SELETOR_EQUIP.instantiate()
	add_child(_seletor)
	_seletor.configurar(tipo)
	_seletor.fechado.connect(_fechar_equip)


func _fechar_equip() -> void:
	if _seletor and is_instance_valid(_seletor):
		_seletor.queue_free()
	_seletor = null
	_painel.visible = true


func _process(_dt: float) -> void:
	# em _process (não em _input) para apanhar também o TouchScreenButton do
	# HUD, que sinaliza a ação sem gerar um InputEvent que propague
	# com o ecrã de equipamento aberto é ele que trata o "voltar"
	if _seletor and is_instance_valid(_seletor):
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
