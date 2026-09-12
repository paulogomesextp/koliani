extends SceneTree
## Smoke visual do L1 em quatro pontos do nível; renderer real, sem foco.
## Não substitui o percurso humano -- serve para caçar seams e repetição de
## landmark, que só se vêem quando a câmara ANDA.
const SAIDA := "res://work/production_art_gate/9H12E_astra_production/preview/"
const PONTOS := [
	["a_spawn", 320.0, 640.0], ["b_meio", 1450.0, 620.0],
	["c_alto", 2450.0, 540.0], ["d_chefe", 3500.0, 640.0],
]

func _init() -> void:
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	if DisplayServer.get_screen_count() > 1:
		root.position = DisplayServer.screen_get_position(1) + DisplayServer.screen_get_size(1) - Vector2i(200, 140)
	await process_frame
	var estado := root.get_node("EstadoJogo")
	estado.indice_nivel = 0
	estado.checkpoint = Vector2.ZERO
	change_scene_to_file("res://scenes/Main.tscn")
	await create_timer(1.8).timeout
	var jogador := get_first_node_in_group("koliani") as CharacterBody2D
	assert(jogador != null, "L1 não abriu")
	var alvo := current_scene.find_child("Region1HybridVisualTarget", true, false)
	assert(alvo != null and alvo.get_node_or_null("HybridL1_ceu") != null, "Passe L1 não montado")
	jogador.set_physics_process(false)
	for p: Array in PONTOS:
		jogador.global_position = Vector2(p[1], p[2])
		await create_timer(0.7).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(SAIDA + "l1_" + str(p[0]) + ".png")
	print("L1 HYBRID 12E: ", PONTOS.size(), " capturas; percurso humano não testado")
	quit()
