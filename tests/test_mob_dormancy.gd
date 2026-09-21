extends Node2D
## Teste dirigido: um mob fora do ecrã não simula, não morre e não recompensa.

const MOB := preload("res://scenes/actors/DemonioBase.tscn")

func _ready() -> void:
	call_deferred("_verificar")


func _verificar() -> void:
	var camera := Camera2D.new()
	camera.position = Vector2.ZERO
	camera.enabled = true
	add_child(camera)
	var mob := MOB.instantiate() as DemonioBase
	mob.global_position = Vector2(10000.0, 0.0)
	add_child(mob)
	await get_tree().process_frame
	await get_tree().process_frame

	var falhas: Array[String] = []
	if mob.esta_ativado():
		falhas.append("mob fora do ecrã foi activado")
	if mob.velocity != Vector2.ZERO:
		falhas.append("mob dormente ganhou velocidade")
	if mob.collision_layer != 0:
		falhas.append("colisao do mob dormente ficou activa")
	var vida_inicial := mob.vida
	mob.receber_dano(999)
	if not is_instance_valid(mob) or mob.vida != vida_inicial:
		falhas.append("mob dormente recebeu dano/morreu")
	if get_tree().get_nodes_in_group("essencia").size() != 0:
		falhas.append("mob dormente largou recompensa")

	mob.global_position = Vector2(100.0, 100.0)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	if not mob.esta_ativado():
		falhas.append("mob nao activou ao entrar no ecrã")
	if mob.collision_layer == 0:
		falhas.append("colisao nao foi restaurada na activacao")
	var essencias_antes := get_tree().get_nodes_in_group("essencia").size()
	mob.vida = 1
	mob.receber_dano(1)
	await get_tree().process_frame
	var essencias_depois := 0
	for no in get_tree().current_scene.get_children():
		if no is Essencia:
			essencias_depois += 1
	if essencias_depois <= essencias_antes:
		falhas.append("mob activado nao largou recompensa ao morrer")

	for falha in falhas:
		printerr("MOB DORMANCY FAIL: ", falha)
	print("MOB DORMANCY: %d falhas" % falhas.size())
	get_tree().quit(0 if falhas.is_empty() else 1)
