class_name Porta
extends Area2D
## Porta de fim de nível. Marca o nível como concluído e:
##   * modo normal   -> volta ao Mapa do Mundo para escolher o próximo nível
##                      (ou dispara `fim_da_campanha` na última porta com a
##                      campanha toda feita);
##   * modo hardcore  -> segue linear, mundo a mundo, sem passar pelo mapa.

signal fim_da_campanha

const CENA_JOGO := "res://scenes/Main.tscn"
const CENA_MAPA := "res://scenes/ui/MapaMundo.tscn"

@export var pista_ao_atravessar := ""  # id opcional de pista sobre a mãe


func _ready() -> void:
	body_entered.connect(_ao_entrar)


func _ao_entrar(corpo: Node) -> void:
	if not (corpo is Koliani):
		return
	if pista_ao_atravessar != "":
		EstadoJogo.registar_pista(pista_ao_atravessar)
	Som.toca("porta", -3.0)
	var i := EstadoJogo.indice_nivel
	EstadoJogo.marcar_nivel_concluido(i)

	if EstadoJogo.hardcore:
		if EstadoJogo.ha_proximo_nivel():
			EstadoJogo.avancar_nivel()
			get_tree().change_scene_to_file(CENA_JOGO)
		else:
			fim_da_campanha.emit()
		return

	if i >= EstadoJogo.NIVEIS.size() - 1 and EstadoJogo.campanha_concluida():
		fim_da_campanha.emit()
	else:
		get_tree().change_scene_to_file(CENA_MAPA)
