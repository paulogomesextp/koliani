class_name Porta
extends Area2D
## Porta entre mundos. Quando a Koliani entra, avança para o próximo nível
## da sequência (`EstadoJogo.NIVEIS`). Se for a última porta, dispara o
## sinal `fim_da_campanha` para a cena principal tratar (libertar a mãe).

signal fim_da_campanha

@export var pista_ao_atravessar := ""  # id opcional de pista sobre a mãe


func _ready() -> void:
	body_entered.connect(_ao_entrar)


func _ao_entrar(corpo: Node) -> void:
	if not (corpo is Koliani):
		return
	if pista_ao_atravessar != "":
		EstadoJogo.registar_pista(pista_ao_atravessar)
	Som.toca("porta", -3.0)
	if EstadoJogo.ha_proximo_nivel():
		EstadoJogo.avancar_nivel()
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
	else:
		fim_da_campanha.emit()
