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


func _ready() -> void:
	_sld_musica.min_value = 0.0
	_sld_musica.max_value = 1.0
	_sld_musica.step = 0.05
	_sld_musica.value = Opcoes.vol_musica
	_sld_efeitos.min_value = 0.0
	_sld_efeitos.max_value = 1.0
	_sld_efeitos.step = 0.05
	_sld_efeitos.value = Opcoes.vol_efeitos
	_estilizar_slider(_sld_musica)
	_estilizar_slider(_sld_efeitos)

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

	_voltar.pressed.connect(_fechar)
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	_traduzir()
	_preparar_hover_animado()
	_voltar.grab_focus()


## Trilho/agarrador do slider na paleta roxa em vez do cinzento por omissão.
func _estilizar_slider(s: HSlider) -> void:
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.1, 0.07, 0.13, 0.9)
	fundo.set_corner_radius_all(6)
	fundo.content_margin_top = 6
	fundo.content_margin_bottom = 6
	fundo.set_border_width_all(1)
	fundo.border_color = Color(0.5, 0.3, 0.5, 0.5)
	var preenchido := fundo.duplicate() as StyleBoxFlat
	preenchido.bg_color = Color(0.6, 0.28, 0.65, 0.85)
	preenchido.border_color = Color(0.9, 0.5, 0.9, 0.7)
	s.add_theme_stylebox_override("slider", fundo)
	s.add_theme_stylebox_override("grabber_area", preenchido)
	s.add_theme_stylebox_override("grabber_area_highlight", preenchido)


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
	# realça o idioma atual
	for loc: String in _botoes_idioma:
		var b: Button = _botoes_idioma[loc]
		b.disabled = false
		b.text = Textos.NOMES[loc]
		_estilo_idioma(b, loc == Textos.idioma())


## Botão de idioma: estilo neutro por omissão, com glow quando é o ativo
## (substitui o "disabled" cinzento por omissão, que destoava do tema).
func _estilo_idioma(b: Button, ativo: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 14.0
	normal.content_margin_right = 14.0
	normal.content_margin_top = 8.0
	normal.content_margin_bottom = 8.0
	if ativo:
		normal.bg_color = Color(0.28, 0.12, 0.34, 0.98)
		normal.set_border_width_all(2)
		normal.border_color = Color(0.95, 0.5, 0.92, 0.95)
		normal.shadow_color = Color(0.85, 0.35, 0.85, 0.4)
		normal.shadow_size = 10
	else:
		normal.bg_color = Color(0.065, 0.04, 0.095, 0.85)
		normal.set_border_width_all(1)
		normal.border_color = Color(0.5, 0.3, 0.5, 0.5)
	var hover := normal.duplicate() as StyleBoxFlat
	if not ativo:
		hover.bg_color = Color(0.2, 0.1, 0.24, 0.95)
		hover.border_color = Color(0.85, 0.45, 0.85, 0.85)
	for e in ["normal", "focus"]:
		b.add_theme_stylebox_override(e, normal)
	for e in ["hover", "pressed"]:
		b.add_theme_stylebox_override(e, hover)
	b.add_theme_color_override("font_color", Color(1, 0.92, 1) if ativo else Color(0.85, 0.8, 0.9))


func _escolher_idioma(loc: String) -> void:
	Opcoes.definir_idioma(loc)


func _fechar() -> void:
	queue_free()
