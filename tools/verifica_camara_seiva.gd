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
	await _andar_ate(k, 2670.0)
	await _saltar_ate(k, 2770.0)
	var degrau := k.is_on_floor() and absf(k.global_position.x - 2770.0) < 45.0 and k.global_position.y < 640.0
	await _saltar_ate(k, 2860.0)
	var reencontro := k.is_on_floor() and k.global_position.y < 587.0
	await _saltar_ate(k, 3070.0)
	await _andar_ate(k, 3170.0)
	var arena := k.is_on_floor() and k.global_position.x > 3150.0
	print("Câmara: fechada=", fechada, " abriu=", abriu, " entrou=", entrou, " recolheu=", recolheu, " saiu=", saiu)
	print("Percurso: degrau=", degrau, " reencontro=", reencontro, " arena=", arena, " posição=", k.global_position)
	quit(0 if fechada and abriu and entrou and recolheu and saiu and degrau and reencontro and arena else 1)

func _andar_ate(k: CharacterBody2D, x: float) -> void:
	Input.action_press("mover_direita")
	for i in 180:
		await physics_frame
		if k.global_position.x >= x:
			break
	Input.action_release("mover_direita")
	await create_timer(0.2).timeout

func _saltar_ate(k: CharacterBody2D, x: float) -> void:
	Input.action_press("saltar")
	await _andar_ate(k, x)
	Input.action_release("saltar")
	await create_timer(0.5).timeout
