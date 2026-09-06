extends SceneTree
## Verifica a grade e a recolha com a personagem real na câmara opcional.
func _init() -> void:
	await process_frame
	var estado := root.get_node("EstadoJogo")
	estado.indice_nivel = 3
	estado.checkpoint = Vector2.ZERO
	change_scene_to_file("res://scenes/levels/A_Arvore_que_Chora.tscn")
	await process_frame
	await process_frame
	var k: CharacterBody2D = get_first_node_in_group("koliani")
	var grade := current_scene.get_node("GradeSeiva")
	var alavanca := current_scene.get_node("AlavancaSeiva")
	var fechada: bool = not grade.get_node("Col").disabled
	k.set("_invulneravel", 60.0)
	k.global_position = Vector2(2330, 640)
	k.velocity = Vector2.ZERO
	await create_timer(0.8).timeout
	var abriu: bool = alavanca.ligada and grade.get_node("Col").disabled
	Input.action_press("mover_direita")
	await create_timer(1.0).timeout
	Input.action_release("mover_direita")
	var entrou := k.global_position.x > 2490.0
	var recolheu := not is_instance_valid(current_scene.get_node_or_null("ReservaSeiva"))
	if DisplayServer.get_name() != "headless":
		await process_frame
		root.get_texture().get_image().save_png("res://work/camara-seiva.png")
	Input.action_press("mover_esquerda")
	await create_timer(1.1).timeout
	Input.action_release("mover_esquerda")
	var saiu := k.global_position.x < 2440.0
	print("Câmara: fechada=", fechada, " abriu=", abriu, " entrou=", entrou, " recolheu=", recolheu, " saiu=", saiu)
	quit(0 if fechada and abriu and entrou and recolheu and saiu else 1)
