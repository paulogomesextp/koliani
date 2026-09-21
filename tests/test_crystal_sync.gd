extends Node2D
## Teste dirigido do saldo persistente e da recolha de Essência no mundo.

const ESSENCIA := preload("res://scenes/actors/Essencia.tscn")

func _ready() -> void:
	call_deferred("_verificar")


func _verificar() -> void:
	EstadoJogo.modo_teste = true
	EstadoJogo.essencia = 0
	var camera := Camera2D.new()
	camera.position = Vector2.ZERO
	camera.enabled = true
	add_child(camera)
	var jogador := Node2D.new()
	jogador.name = "JogadorTeste"
	jogador.add_to_group("koliani")
	add_child(jogador)
	var cache := ESSENCIA.instantiate() as Essencia
	cache.valor = 26
	cache.espalhar = false
	cache.global_position = Vector2(10000.0, 0.0)
	add_child(cache)
	await get_tree().create_timer(1.0).timeout

	var falhas: Array[String] = []
	if EstadoJogo.essencia != 0:
		falhas.append("cache fora do viewport alterou o saldo")
	if not is_instance_valid(cache):
		falhas.append("cache fora do viewport foi recolhido")

	EstadoJogo.sincronizar_essencia(26)
	if EstadoJogo.essencia != 26:
		falhas.append("sincronizacao nao actualizou o saldo")
	cache.global_position = Vector2(100.0, 100.0)
	await get_tree().create_timer(1.0).timeout
	if EstadoJogo.essencia != 52:
		falhas.append("recolha visivel nao adicionou a recompensa")

	for falha in falhas:
		printerr("CRYSTAL SYNC FAIL: ", falha)
	print("CRYSTAL SYNC: %d falhas" % falhas.size())
	get_tree().quit(0 if falhas.is_empty() else 1)
