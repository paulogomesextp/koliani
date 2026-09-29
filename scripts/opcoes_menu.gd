extends Control
## Ecrã de Opções (sobreposto ao menu inicial). SOM: dois cursores para o
## volume da música e dos efeitos. LANGUAGE: um botão por idioma; ao
## escolher, o jogo todo passa a esse idioma na hora (o `Textos` emite
## `idioma_mudou` e cada ecrã volta a pedir os textos).
##
## Fecha em BACK ou Esc. Escreve as definições via `Opcoes` (que as grava
## em user://opcoes.json).

@onready var _titulo: Label = $Painel/Coluna/Titulo
@onready var _lbl_som: Label = $Painel/Coluna/Som
@onready var _lbl_musica: Label = $Painel/Coluna/Musica/Nome
@onready var _lbl_efeitos: Label = $Painel/Coluna/Efeitos/Nome
@onready var _sld_musica: HSlider = $Painel/Coluna/Musica/Cursor
@onready var _sld_efeitos: HSlider = $Painel/Coluna/Efeitos/Cursor
@onready var _lbl_idioma: Label = $Painel/Coluna/Idioma
@onready var _grelha: GridContainer = $Painel/Coluna/Idiomas
@onready var _voltar: Button = $Painel/Coluna/Voltar

var _botoes_idioma: Dictionary = {}
var _layout: Button
var _editor: Control


## Abre o editor de layout de toque por cima das Opções.
func _abrir_layout() -> void:
	if _editor != null and is_instance_valid(_editor):
		return
	_editor = (load("res://scripts/editor_layout_toque.gd") as Script).new()
	_editor.z_index = 50
	add_child(_editor)
	_editor.fechado.connect(func() -> void:
		_editor = null
		if is_inside_tree():
			_layout.grab_focus())


func _ready() -> void:
	_sld_musica.min_value = 0.0
	_sld_musica.max_value = 1.0
	_sld_musica.step = 0.05
	_sld_musica.value = Opcoes.vol_musica
	_sld_efeitos.min_value = 0.0
	_sld_efeitos.max_value = 1.0
	_sld_efeitos.step = 0.05
	_sld_efeitos.value = Opcoes.vol_efeitos

	_sld_musica.value_changed.connect(func(v: float) -> void: Opcoes.definir_musica(v))
	_sld_efeitos.value_changed.connect(func(v: float) -> void: Opcoes.definir_efeitos(v))
	# ao largar o cursor dos efeitos, toca um som para o jogador calibrar
	_sld_efeitos.drag_ended.connect(func(_c: bool) -> void: Som.toca("apanhar", -4.0))

	for loc in Textos.IDIOMAS:
		var b := Button.new()
		b.text = Textos.NOMES[loc]
		b.pressed.connect(_escolher_idioma.bind(loc))
		_grelha.add_child(b)
		_botoes_idioma[loc] = b

	# Execution 9H: EDITAR LAYOUT -- só onde há toque. Num PC com teclado a
	# entrada não aparece de todo (não há controlos de toque para arrumar).
	if DisplayServer.is_touchscreen_available() or OS.has_feature("web"):
		_layout = Button.new()
		_layout.pressed.connect(_abrir_layout)
		_grelha.get_parent().add_child(_layout)
		_grelha.get_parent().move_child(_layout, _voltar.get_index())

	_voltar.pressed.connect(_fechar)
	# Mesma linguagem do menu principal e da Pausa (kit 9H: carmesim sobre
	# carvão); o idioma ativo fica "premido" (carmesim).
	Frontend9H.vestir(self)
	($Painel as PanelContainer).add_theme_stylebox_override(
		"panel", Frontend9H.painel_liso())
	Frontend9H.cabecalho(_titulo, 32)
	Frontend9H.capitular(_lbl_som, 15, Frontend9H.CARMESIM_CLARO)
	Frontend9H.capitular(_lbl_idioma, 15, Frontend9H.CARMESIM_CLARO)
	_lbl_som.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_lbl_idioma.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	Frontend9H.corpo(_lbl_musica, 17)
	Frontend9H.corpo(_lbl_efeitos, 17)
	for s: String in ["Sep1", "Sep2"]:
		var velho: Node = $Painel/Coluna.get_node(s)
		var sep := Frontend9H.separador()
		sep.custom_minimum_size = Vector2(0, 12)
		sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		$Painel/Coluna.add_child(sep)
		$Painel/Coluna.move_child(sep, velho.get_index())
		velho.queue_free()
	# botões pequenos: caixa lisa carmesim (a placa em losango parte-se em
	# botões estreitos -- ver `Frontend9H.botao_placa`)
	Frontend9H.botao_placa(_voltar, 22)
	if _layout:
		Frontend9H.botao_placa(_layout, 17)
	for b: Button in _botoes_idioma.values():
		b.toggle_mode = true
		Frontend9H.botao_placa(b, 16)
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	_traduzir()
	_preparar_hover_animado()
	# o foco por teclado/comando não pode fugir para o menu que está atrás
	get_viewport().gui_focus_changed.connect(_foco_mudou)
	_ligar_foco()
	_voltar.grab_focus()


## Ordem vertical do foco: música, efeitos, grelha de idiomas, (layout), BACK.
func _ligar_foco() -> void:
	var idiomas: Array[Control] = []
	for c in _grelha.get_children():
		idiomas.append(c as Control)
	var cols := _grelha.columns
	var fim: Control = _layout if _layout else _voltar
	_sld_musica.focus_neighbor_top = _sld_musica.get_path_to(_voltar)
	_sld_musica.focus_neighbor_bottom = _sld_musica.get_path_to(_sld_efeitos)
	_sld_efeitos.focus_neighbor_top = _sld_efeitos.get_path_to(_sld_musica)
	_sld_efeitos.focus_neighbor_bottom = _sld_efeitos.get_path_to(idiomas[0])
	for i in idiomas.size():
		var b := idiomas[i]
		b.focus_neighbor_top = b.get_path_to(_sld_efeitos if i < cols else idiomas[i - cols])
		var abaixo: Control = fim if i + cols >= idiomas.size() else idiomas[i + cols]
		b.focus_neighbor_bottom = b.get_path_to(abaixo)
	if _layout:
		_layout.focus_neighbor_top = _layout.get_path_to(idiomas[idiomas.size() - 1])
		_layout.focus_neighbor_bottom = _layout.get_path_to(_voltar)
	_voltar.focus_neighbor_top = _voltar.get_path_to(
		_layout if _layout else idiomas[idiomas.size() - 1])
	_voltar.focus_neighbor_bottom = _voltar.get_path_to(_sld_musica)


func _foco_mudou(no: Control) -> void:
	if is_inside_tree() and not is_ancestor_of(no) and not is_queued_for_deletion():
		_voltar.grab_focus()


## Resposta de escala ao passar/focar o rato -- consistente com os outros ecrãs.
func _preparar_hover_animado() -> void:
	var todos: Array[Button] = [_voltar]
	for loc: String in _botoes_idioma:
		todos.append(_botoes_idioma[loc] as Button)
	for b in todos:
		b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
		b.mouse_entered.connect(func() -> void: _animar_escala(b, 1.05))
		b.mouse_exited.connect(func() -> void: _animar_escala(b, 1.0))


func _animar_escala(botao: Button, alvo: float) -> void:
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(botao, "scale", Vector2(alvo, alvo), 0.16)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		_fechar()
		get_viewport().set_input_as_handled()


func _traduzir() -> void:
	_titulo.text = Textos.t("options.title")
	_lbl_som.text = Textos.t("options.sound")
	_lbl_musica.text = Textos.t("options.music")
	_lbl_efeitos.text = Textos.t("options.effects")
	_lbl_idioma.text = Textos.t("options.language")
	_voltar.text = Textos.t("options.back")
	if _layout:
		_layout.text = Textos.t("options.touch_layout")
	# realça o idioma atual
	for loc: String in _botoes_idioma:
		var b: Button = _botoes_idioma[loc]
		b.disabled = false
		b.text = Textos.NOMES[loc]
		_estilo_idioma(b, loc == Textos.idioma())


## Botão de idioma: o ativo fica PREMIDO (a moldura de ouro do kit 9F).
func _estilo_idioma(b: Button, ativo: bool) -> void:
	b.set_pressed_no_signal(ativo)


func _escolher_idioma(loc: String) -> void:
	Opcoes.definir_idioma(loc)


func _fechar() -> void:
	Som.toca("menu_painel", -12.0, 0.92)
	queue_free()
