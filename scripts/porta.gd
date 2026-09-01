class_name Porta
extends Area2D
## Porta de fim de nível. Marca o nível como concluído e SEGUE DIRETO para o
## nível seguinte (com banner "Avançou para o Nível N" ao entrar). Na última
## porta, com a campanha toda feita, dispara `fim_da_campanha`. O Mapa do
## Mundo continua acessível pelo menu de pausa e pelo menu inicial.

signal fim_da_campanha

const CENA_JOGO := "res://scenes/Main.tscn"

@export var pista_ao_atravessar := ""  # id opcional de pista sobre a mãe

var _t := 0.0
@onready var _anel_e: Node = get_node_or_null("Vortice/AnelExterno")
@onready var _anel_i: Node = get_node_or_null("Vortice/AnelInterno")
@onready var _luz: PointLight2D = get_node_or_null("PointLight2D")


func _ready() -> void:
	body_entered.connect(_ao_entrar)


func _process(dt: float) -> void:
	# vórtice: anéis a rodar em sentidos opostos + luz a pulsar
	_t += dt
	if _anel_e:
		_anel_e.rotation += dt * 1.1
	if _anel_i:
		_anel_i.rotation -= dt * 1.7
	if _luz:
		_luz.energy = 1.7 + 0.35 * sin(_t * 3.0)


func _ao_entrar(corpo: Node) -> void:
	if not (corpo is Koliani):
		return
	if pista_ao_atravessar != "":
		EstadoJogo.registar_pista(pista_ao_atravessar)
	Som.toca("transicao", -3.0)
	var i := EstadoJogo.indice_nivel
	EstadoJogo.marcar_nivel_concluido(i)

	# normal e hardcore: seguem linear para o nível seguinte, sem passar
	# pelo mapa. Só a última porta (campanha feita) é que termina o jogo.
	if EstadoJogo.ha_proximo_nivel():
		EstadoJogo.avancar_nivel()
		get_tree().change_scene_to_file(CENA_JOGO)
	else:
		fim_da_campanha.emit()
