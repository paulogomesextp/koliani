extends Node2D
## Teste dirigido da barreira central de SFX de actors.

func _ready() -> void:
	call_deferred("_verificar")


func _verificar() -> void:
	var actor := Node2D.new()
	add_child(actor)
	var camera := Camera2D.new()
	camera.position = Vector2.ZERO
	camera.enabled = true
	add_child(camera)
	await get_tree().process_frame

	var falhas: Array[String] = []
	actor.position = Vector2.ZERO
	if not Som.actor_visivel(actor):
		falhas.append("actor visivel rejeitado")
	if not Som.toca_actor(actor, "mob_humano_ataque", -30.0):
		falhas.append("one-shot visivel nao tocou")

	actor.position = Vector2(10000.0, 0.0)
	if Som.actor_visivel(actor):
		falhas.append("actor fora do viewport aceite")
	if Som.toca_actor(actor, "mob_humano_ataque", -30.0):
		falhas.append("one-shot fora do viewport tocou")

	actor.position = Vector2.ZERO
	if not Som.laco_actor(actor, "vento_ciclo", -30.0, 0.0):
		falhas.append("loop visivel nao iniciou")
	actor.position = Vector2(10000.0, 0.0)
	await get_tree().process_frame
	if Som.lacos_ativos() != 0:
		falhas.append("loop continuou fora do viewport")

	for falha in falhas:
		printerr("ACTOR SFX VISIBILITY FAIL: ", falha)
	print("ACTOR SFX VISIBILITY: %d falhas" % falhas.size())
	get_tree().quit(0 if falhas.is_empty() else 1)
