extends SceneTree
## Teste com a Koliani real: embarque, transporte e regresso sem passageira.
func _init() -> void:
	await process_frame
	var estado := root.get_node("EstadoJogo")
	estado.indice_nivel = 3
	estado.checkpoint = Vector2.ZERO
	change_scene_to_file("res://scenes/levels/A_Arvore_que_Chora.tscn")
	await process_frame
	await process_frame
	var k: CharacterBody2D = get_first_node_in_group("koliani")
	var raiz: AnimatableBody2D = current_scene.get_node("RaizElevatoria")
	k.set("_invulneravel", 60.0)
	k.global_position = Vector2(1360, 570)
	k.velocity = Vector2.ZERO
	await create_timer(6.5).timeout
	var transportou := raiz.position.y < 325.0 and k.global_position.y < 320.0 and k.is_on_floor()
	print("Transporte: ", transportou, " raiz=", raiz.position, " Koliani=", k.global_position)
	if DisplayServer.get_name() != "headless":
		await process_frame
		root.get_texture().get_image().save_png("res://work/raiz-elevatoria-topo.png")
	k.global_position = Vector2(300, 620)
	k.velocity = Vector2.ZERO
	await create_timer(5.5).timeout
	var regressou := absf(raiz.position.y - 620.0) < 1.0
	print("Regresso: ", regressou)
	quit(0 if transportou and regressou else 1)
