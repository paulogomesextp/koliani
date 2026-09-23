extends CanvasLayer
## Menu de pausa. Abre/fecha com a ação `pausa` (tecla P ou Esc no PC, ou o
## botão do HUD) e também fecha com `ui_cancel`. Põe a árvore em pausa
## (`get_tree().paused`) e oferece duas saídas -- **Mapa de níveis** e
## **Menu principal** -- além de Continuar.
##
## O diário usa o mesmo esquema -- só um deles segura a pausa de cada vez
## (ambos só abrem se a árvore ainda não estiver em pausa).

const CENA_MENU := "res://scenes/ui/MenuInicial.tscn"
const CENA_MAPA := "res://scenes/ui/MapaMundo.tscn"
const CENA_OPCOES := preload("res://scenes/ui/Opcoes.tscn")
const CENA_SANTUARIO := preload("res://scenes/ui/Santuario.tscn")

@onready var _titulo: Label = $Painel/Coluna/Titulo
@onready var _continuar: Button = $Painel/Coluna/Continuar
@onready var _opcoes_btn: Button = $Painel/Coluna/Opcoes
@onready var _santuario_btn: Button = $Painel/Coluna/Santuario
@onready var _mapa: Button = $Painel/Coluna/Mapa
@onready var _recomecar: Button = $Painel/Coluna/Recomecar
@onready var _menu: Button = $Painel/Coluna/Menu

## Instância do ecrã de Opções sobreposto (ou null). Enquanto existe, é ele
## que trata o Esc -- o menu de pausa por baixo fica congelado.
var _opcoes_inst: Control = null
## Idem para o Santuário (melhorias permanentes).
var _santuario_inst: Control = null


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_continuar.pressed.connect(_fechar)
	_opcoes_btn.pressed.connect(_abrir_opcoes)
	_santuario_btn.pressed.connect(_abrir_santuario)
	_mapa.pressed.connect(_ao_mapa)
	_recomecar.pressed.connect(_ao_recomecar)
	_menu.pressed.connect(_ao_menu)
	_mapa.visible = true
	_recomecar.visible = false
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	_traduzir()
	# Execution 9H.11: o painel passa do kit de ouro/ciano da 9F para a
	# linguagem do menu principal (carmesim sobre carvão). O foco/hover
	# desenha a placa em losango, tal como no frontend.
	Frontend9H.vestir($Painel)
	($Painel as PanelContainer).add_theme_stylebox_override(
		"panel", Frontend9H.painel_liso())
	Frontend9H.cabecalho(_titulo, 32)
	_ornamentar()
	for b: Button in [_continuar, _opcoes_btn, _santuario_btn, _mapa, _recomecar, _menu]:
		b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
		b.mouse_entered.connect(func() -> void: _animar_escala(b, 1.03))
		b.mouse_exited.connect(func() -> void: _animar_escala(b, 1.0))
		b.focus_entered.connect(func() -> void: _animar_escala(b, 1.03))
		b.focus_exited.connect(func() -> void: _animar_escala(b, 1.0))


## Losango do frontend por baixo do título -- o mesmo ornamento que separa
## o logótipo das entradas no menu principal.
func _ornamentar() -> void:
	if not Frontend9H.disponivel():
		return
	var sep := Frontend9H.separador()
	sep.custom_minimum_size = Vector2(0, 12)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := _titulo.get_parent()
	# o losango substitui o HSeparator do .tscn (dois traços seguidos)
	var velho := col.get_node_or_null("Separador") as Control
	if velho:
		velho.visible = false
	col.add_child(sep)
	col.move_child(sep, _titulo.get_index() + 1)


func _animar_escala(botao: Button, alvo: float) -> void:
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(botao, "scale", Vector2(alvo, alvo), 0.16)


func _traduzir() -> void:
	_titulo.text = Textos.t("pause.title")
	_continuar.text = Textos.t("pause.resume")
	_opcoes_btn.text = Textos.t("pause.options")
	_santuario_btn.text = Textos.t("pause.shrine")
	_mapa.text = Textos.t("pause.level_map")
	_recomecar.text = Textos.t("pause.restart_checkpoint")
	_menu.text = Textos.t("pause.main_menu")


var _cd := 0.0


func _process(dt: float) -> void:
	# em _process (não em _input) para apanhar também o TouchScreenButton do
	# HUD, que sinaliza a ação sem gerar um InputEvent que propague.
	# Se o ecrã de equipamento (HUD) estiver aberto, é ele que trata o Esc.
	if get_tree().paused and not visible:
		return
	# Com as Opções sobrepostas, o Esc fecha-as a elas (opcoes_menu.gd), não
	# o menu de pausa.
	if _opcoes_inst != null or _santuario_inst != null:
		return
	# tempo morto após abrir/fechar -- um botão START "ressaltado" no comando
	# não fica a abrir e fechar o menu vezes sem conta (parecia um freeze)
	_cd = maxf(0.0, _cd - dt)
	if _cd > 0.0:
		return
	var alternar := Input.is_action_just_pressed("pausa")
	if visible:
		if alternar or Input.is_action_just_pressed("ui_cancel"):
			_fechar()
	elif alternar and not get_tree().paused:
		_abrir()


func _abrir() -> void:
	_cd = 0.35
	Som.toca("menu_painel", -12.0)
	visible = true
	get_tree().paused = true
	# 9H.1: a cama desce e entra a ambiência da pausa. NÃO se pára a música --
	# pará-la e recomeçá-la punha a faixa de volta ao princípio a cada pausa.
	Musica.pausa(true)
	_continuar.grab_focus()


func _fechar() -> void:
	_cd = 0.35
	Som.toca("menu_painel", -12.0, 0.92)
	visible = false
	get_tree().paused = false
	Musica.pausa(false)


## Sobrepõe o ecrã de Opções ao menu de pausa. Não mexe em
## `get_tree().paused` nem troca de cena -- o nível fica todo em memória, o
## progresso não se perde. Fecha em BACK/Esc (tratado pelo próprio Opcoes).
func _abrir_opcoes() -> void:
	if _opcoes_inst != null:
		return
	Som.toca("menu_painel", -12.0)
	_opcoes_inst = CENA_OPCOES.instantiate()
	_opcoes_inst.process_mode = Node.PROCESS_MODE_ALWAYS  # funciona em pausa
	_opcoes_inst.tree_exited.connect(_ao_fechar_opcoes)
	add_child(_opcoes_inst)
	$Painel.visible = false  # o Fundo do próprio Opcoes já escurece o ecrã


func _ao_fechar_opcoes() -> void:
	_opcoes_inst = null
	if visible:
		$Painel.visible = true
		_continuar.grab_focus()


## Sobrepõe o SANTUÁRIO (melhorias permanentes) ao menu de pausa. Como as
## Opções: não mexe na pausa nem troca de cena.
func _abrir_santuario() -> void:
	if _santuario_inst != null:
		return
	Som.toca("menu_painel", -12.0)
	_santuario_inst = CENA_SANTUARIO.instantiate()
	_santuario_inst.process_mode = Node.PROCESS_MODE_ALWAYS
	if _santuario_inst.has_signal("fechado"):
		_santuario_inst.fechado.connect(func() -> void:
			if is_instance_valid(_santuario_inst):
				_santuario_inst.queue_free())
	_santuario_inst.tree_exited.connect(_ao_fechar_santuario)
	add_child(_santuario_inst)
	$Painel.visible = false


func _ao_fechar_santuario() -> void:
	_santuario_inst = null
	if visible:
		$Painel.visible = true
		_santuario_btn.grab_focus()


func _ao_recomecar() -> void:
	get_tree().paused = false
	Transicao.fechar_e(get_tree().reload_current_scene)


## Sai para o Mapa do Mundo sem guardar progresso do nível (o nível recomeça
## do início da próxima vez).
func _ao_mapa() -> void:
	get_tree().paused = false
	EstadoJogo.abandonar_sessao_nivel()
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_MAPA))


func _ao_menu() -> void:
	get_tree().paused = false
	EstadoJogo.abandonar_sessao_nivel()
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_MENU))
