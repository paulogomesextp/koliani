extends Control
## Mapa da campanha (modo normal -- NOVO JOGO / CONTINUAR). Mostra o
## carrossel `SeletorNiveis` com os 30 níveis: cada cartão traz a região, o
## nome do nível e o nome do chefe. Deixa escolher qualquer nível já
## alcançado (`nivel_desbloqueado`). O modo HARDCORE não passa por aqui
## (corre linear).
##
## Ao acabar um nível, a Porta traz de volta a este mapa (ver porta.gd).

const CENA_JOGO := "res://scenes/Main.tscn"
const CENA_MENU := "res://scenes/ui/MenuInicial.tscn"
const CENA_SELETOR := preload("res://scenes/ui/SeletorNiveis.tscn")

@onready var _titulo: Label = $Titulo

var _seletor: SeletorNiveis


func _ready() -> void:
	Musica.menu()
	_seletor = CENA_SELETOR.instantiate()
	add_child(_seletor)
	_seletor.escolhido.connect(_entrar)
	_seletor.cancelado.connect(_voltar_menu)
	_seletor.configurar(clampi(EstadoJogo.indice_nivel, 0, EstadoJogo.NIVEIS.size() - 1), true)
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	_traduzir()
	_agendar_prova_runtime()


func _traduzir() -> void:
	_titulo.text = Textos.t("map.title")


func _entrar(indice: int) -> void:
	EstadoJogo.indice_nivel = indice
	# Escolher no mapa é entrada deliberadamente fresca, não recovery.
	EstadoJogo.iniciar_sessao_nivel(true)
	if _seletor:
		_seletor.set_process_unhandled_input(false)
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_JOGO))


func _voltar_menu() -> void:
	if _seletor:
		_seletor.set_process_unhandled_input(false)
	Transicao.fechar_e(func() -> void: get_tree().change_scene_to_file(CENA_MENU))


## Captura o seletor real quando o export é lançado pelo gate da Execution 8.
func _agendar_prova_runtime() -> void:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--foto-mapa="):
			_tirar_foto_mapa.call_deferred(argumento.get_slice("=", 1))
			return


func _tirar_foto_mapa(caminho: String) -> void:
	await get_tree().create_timer(0.8).timeout
	var imagem := get_viewport().get_texture().get_image()
	imagem.save_png(caminho)
	print("PROVA RUNTIME MAPA: ", caminho)
	get_tree().quit(0)
