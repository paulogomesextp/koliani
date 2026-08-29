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
	_voltar.grab_focus()


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
		b.disabled = (loc == Textos.idioma())
		b.text = Textos.NOMES[loc]


func _escolher_idioma(loc: String) -> void:
	Opcoes.definir_idioma(loc)


func _fechar() -> void:
	queue_free()
