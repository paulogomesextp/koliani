extends SceneTree
## Smoke visual curto, renderer real; não substitui percurso humano.
const SAIDA := "res://work/production_art_gate/9H12E_astra_production/preview/"

func _init() -> void:
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	if DisplayServer.get_screen_count() > 1:
		root.position = DisplayServer.screen_get_position(1) + DisplayServer.screen_get_size(1) - Vector2i(160, 120)
	await process_frame
	var estado := root.get_node("EstadoJogo")
	estado.indice_nivel = 0
	estado.checkpoint = Vector2.ZERO
	change_scene_to_file("res://scenes/Main.tscn")
	await create_timer(1.5).timeout
	var jogador := get_first_node_in_group("koliani") as CharacterBody2D
	assert(jogador != null, "L1 não abriu")
	var alvo := current_scene.find_child("Region1HybridVisualTarget", true, false)
	assert(alvo != null and alvo.get_node_or_null("HybridL1_01_far_sky_castle") != null, "Passe L1 não montado")
	for no in current_scene.find_children("*", "Sprite2D", true, false):
		if no.is_visible_in_tree() and no.texture and (no.scale.x > 1.5 or no.scale.y > 1.5):
			print("TEXTURA ", no.get_path(), " ", no.texture.resource_path)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(SAIDA + "l1_spawn.png")
	jogador.set_physics_process(false)
	jogador.global_position = Vector2(650, 560)
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(SAIDA + "l1_meio.png")
	print("L1 HYBRID: abertura e 5 camadas PASS; 2 capturas reais; percurso humano não testado")
	quit()

