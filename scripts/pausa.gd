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

@onready var _titulo: Label = $Painel/Coluna/Titulo
@onready var _continuar: Button = $Painel/Coluna/Continuar
@onready var _opcoes_btn: Button = $Painel/Coluna/Opcoes
@onready var _mapa: Button = $Painel/Coluna/Mapa
@onready var _recomecar: Button = $Painel/Coluna/Recomecar
@onready var _menu: Button = $Painel/Coluna/Menu

## Instância do ecrã de Opções sobreposto (ou null). Enquanto existe, é ele
## que trata o Esc -- o menu de pausa por baixo fica congelado.
var _opcoes_inst: Control = null
var _painel: PanelContainer
var _palco: Control
var _realce: TextureRect
var _realce_tween: Tween


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_continuar.pressed.connect(_fechar)
	_opcoes_btn.pressed.connect(_abrir_opcoes)
	_mapa.pressed.connect(_ao_mapa)
	_recomecar.pressed.connect(_ao_recomecar)
	_menu.pressed.connect(_ao_menu)
	_mapa.visible = true
	_recomecar.visible = false
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	_traduzir()
	_montar_frontend()
	for b: Button in [_continuar, _opcoes_btn, _mapa, _menu]:
		Frontend9H.rotulo_menu(b, 26)
		b.custom_minimum_size = Vector2(0, 46)
		b.mouse_entered.connect(b.grab_focus)
		b.focus_entered.connect(func() -> void: _mover_realce(b))
		b.resized.connect(func() -> void:
			if b.has_focus():
				_mover_realce(b))
	var botoes := [_continuar, _opcoes_btn, _mapa, _menu]
	for i in botoes.size():
		botoes[i].focus_neighbor_top = botoes[i].get_path_to(botoes[posmod(i - 1, botoes.size())])
		botoes[i].focus_neighbor_bottom = botoes[i].get_path_to(botoes[(i + 1) % botoes.size()])


## A mesma prancha e os mesmos componentes do menu inicial, sem a caixa antiga.
func _montar_frontend() -> void:
	_painel = $Painel
	$Fundo.hide()
	var raiz := Control.new()
	raiz.name = "FrontendPausa"
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(raiz)
	_palco = Frontend9H.palco(raiz, "fundo_menu")
	Frontend9H.vestir(raiz)
	_palco.add_child(Frontend9H.veu(Vector2(475, 0), Vector2(1135, 720), 0.5))
	_palco.add_child(Frontend9H.vinheta())
	_realce = Frontend9H.realce()
	_realce.modulate.a = 0.0
	_palco.add_child(_realce)
	_painel.reparent(_palco)
	_painel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	Frontend9H.por(_painel, Rect2(640, 260, 330, 330))
	var coluna := _titulo.get_parent() as VBoxContainer
	coluna.add_theme_constant_override("separation", 0)
	Frontend9H.capitular(_titulo, 20, Frontend9H.TEXTO_APAGADO)
	_ornamentar()
	for b: Button in [_opcoes_btn, _mapa, _menu]:
		var sep := Frontend9H.separador()
		sep.custom_minimum_size = Vector2(0, 12)
		coluna.add_child(sep)
		coluna.move_child(sep, b.get_index())
	var rodape := Frontend9H.separador("ornamento_rodape")
	Frontend9H.por(rodape, Rect2(600, 604, 410, 20))
	_palco.add_child(rodape)


func _mover_realce(botao: Button) -> void:
	await get_tree().process_frame
	if not is_instance_valid(botao) or not botao.is_inside_tree():
		return
	var posicao := botao.global_position - _palco.global_position - Vector2(12, 5)
	var tamanho := botao.size + Vector2(24, 10)
	if _realce_tween and _realce_tween.is_valid():
		_realce_tween.kill()
	if _realce.modulate.a < 0.05:
		_realce.position = posicao
		_realce.size = tamanho
		_realce.modulate.a = 1.0
		return
	_realce_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_realce_tween.tween_property(_realce, "position", posicao, 0.17)
	_realce_tween.tween_property(_realce, "size", tamanho, 0.17)


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


func _traduzir() -> void:
	_titulo.text = Textos.t("pause.title")
	_continuar.text = Textos.t("pause.resume")
	_opcoes_btn.text = Textos.t("pause.options")
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
	if _opcoes_inst != null:
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
	# Menu silencioso; a faixa do nível fica suspensa, sem voltar ao início.
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
	_painel.visible = false
	_realce.visible = false


func _ao_fechar_opcoes() -> void:
	_opcoes_inst = null
	if visible:
		_painel.visible = true
		_realce.visible = true
		_continuar.grab_focus()


func _ao_recomecar() -> void:
	Musica.pausa(false)
	get_tree().paused = false
	Transicao.fechar_e(get_tree().reload_current_scene)


## Sai para o Mapa do Mundo sem guardar progresso do nível (o nível recomeça
## do início da próxima vez).
func _ao_mapa() -> void:
	Musica.pausa(false)
	get_tree().paused = false
	EstadoJogo.abandonar_sessao_nivel()
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_MAPA))


func _ao_menu() -> void:
	Musica.pausa(false)
	get_tree().paused = false
	EstadoJogo.abandonar_sessao_nivel()
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_MENU))
