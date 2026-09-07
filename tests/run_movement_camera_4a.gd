extends Node

const Testes4A := preload("res://tests/test_movimento_camera_4a.gd")


func _ready() -> void:
	var falhas: Array[String] = Testes4A.executar()
	if falhas.is_empty():
		print("OK -- targeted Movement + Camera 4A")
		get_tree().quit(0)
		return
	for falha in falhas:
		printerr("FALHOU: ", falha)
	printerr("%d falha(s)" % falhas.size())
	get_tree().quit(1)
