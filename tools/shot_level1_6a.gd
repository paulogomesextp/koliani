extends SceneTree
## Captura multiponto real do Level 1 e monta as duas folhas de revisão 6A.

const SAIDA := "res://work/execution_6a/preview"
const PONTOS := [
	["01_spawn", -2250.0],
	["02_early_traversal", -1500.0],
	["03_platforms_closeup", 650.0],
	["04_heart_tree", 900.0],
	["05_enemy_encounter", 1450.0],
	["06_mid_level", 2150.0],
	["07_atmospheric_section", 2750.0],
	["08_near_exit", 3350.0],
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA + "/shots"))
	await process_frame
	if OS.get_cmdline_user_args().has("--compose-only"):
		var existentes: Array[Image] = []
		for dados in PONTOS:
			var imagem := Image.load_from_file("%s/shots/%s.png" % [SAIDA, dados[0]])
			if imagem == null or imagem.is_empty():
				printerr("6A SHOT: captura existente indisponível: ", dados[0])
				quit(1)
				return
			existentes.append(imagem)
		if not _montar_review(existentes) or not _montar_before_after(existentes[2]):
			quit(1)
			return
		print("LEVEL 1 6A COMPOSIÇÃO: PASS — review + before/after")
		quit(0)
		return
	var estado := root.get_node_or_null("/root/EstadoJogo")
	if estado == null:
		printerr("6A SHOT: EstadoJogo indisponível")
		quit(1)
		return
	estado.indice_nivel = 0
	estado.checkpoint = Vector2.ZERO
	estado.set("modo_dev", false)
	estado.mecanicas_explicadas["saltos"] = true
	change_scene_to_file("res://scenes/Main.tscn")
	for _i in 120:
		await process_frame
	await create_timer(0.5).timeout

	var koliani := get_first_node_in_group("koliani") as CharacterBody2D
	if koliani == null:
		printerr("6A SHOT: Koliani indisponível")
		quit(1)
		return
	var cam := koliani.get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.position_smoothing_enabled = false
	koliani.set_physics_process(false)
	koliani.set_process(false)

	var imagens: Array[Image] = []
	var pontos_captura: Array = [PONTOS[0]] \
		if OS.get_cmdline_user_args().has("--refresh-spawn") else PONTOS
	for dados in pontos_captura:
		var pos := _ponto_seguro(float(dados[1]))
		koliani.global_position = pos
		koliani.velocity = Vector2.ZERO
		for _i in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		var imagem := root.get_texture().get_image()
		var caminho := "%s/shots/%s.png" % [SAIDA, dados[0]]
		if imagem.save_png(ProjectSettings.globalize_path(caminho)) != OK:
			printerr("6A SHOT: falha a guardar ", caminho)
			quit(1)
			return
		imagens.append(imagem)
		print("shot -> ", caminho, " @ ", pos)

	if OS.get_cmdline_user_args().has("--refresh-spawn"):
		imagens.clear()
		for dados in PONTOS:
			var existente := Image.load_from_file("%s/shots/%s.png" % [SAIDA, dados[0]])
			if existente == null or existente.is_empty():
				printerr("6A SHOT: captura existente indisponível: ", dados[0])
				quit(1)
				return
			imagens.append(existente)
	if not _montar_review(imagens):
		quit(1)
		return
	if not _montar_before_after(imagens[2]):
		quit(1)
		return
	print("LEVEL 1 6A CAPTURAS: PASS — 8 pontos + review + before/after")
	quit(0)


func _ponto_seguro(x: float) -> Vector2:
	var mundo: PhysicsDirectSpaceState2D = current_scene.get_world_2d().direct_space_state
	var consulta := PhysicsRayQueryParameters2D.create(Vector2(x, -300), Vector2(x, 1100), 1)
	var hit: Dictionary = mundo.intersect_ray(consulta)
	if hit.is_empty():
		return Vector2(x, 560)
	return Vector2(x, float(hit.position.y) - 52.0)


func _montar_review(imagens: Array[Image]) -> bool:
	var folha := Image.create_empty(2560, 720, false, Image.FORMAT_RGBA8)
	folha.fill(Color("07111d"))
	for i in imagens.size():
		var mini := imagens[i].duplicate()
		mini.resize(640, 360, Image.INTERPOLATE_LANCZOS)
		mini.convert(Image.FORMAT_RGBA8)
		folha.blit_rect(mini, Rect2i(Vector2i.ZERO, mini.get_size()),
			Vector2i((i % 4) * 640, (i / 4) * 360))
	var caminho := ProjectSettings.globalize_path(SAIDA + "/level1_6a_review.png")
	var erro := folha.save_png(caminho)
	if erro != OK:
		printerr("6A SHOT: falha review: ", error_string(erro))
		return false
	return true


func _montar_before_after(depois: Image) -> bool:
	var antes := Image.load_from_file(SAIDA + "/before_current.png")
	if antes == null or antes.is_empty():
		printerr("6A SHOT: before_current.png indisponível")
		return false
	antes.convert(Image.FORMAT_RGBA8)
	var depois_rgba := depois.duplicate()
	depois_rgba.convert(Image.FORMAT_RGBA8)
	var folha := Image.create_empty(2560, 720, false, Image.FORMAT_RGBA8)
	folha.fill(Color.BLACK)
	folha.blit_rect(antes, Rect2i(Vector2i.ZERO, antes.get_size()), Vector2i.ZERO)
	folha.blit_rect(depois_rgba, Rect2i(Vector2i.ZERO, depois_rgba.get_size()), Vector2i(1280, 0))
	var caminho := ProjectSettings.globalize_path(SAIDA + "/level1_before_after.png")
	var erro := folha.save_png(caminho)
	if erro != OK:
		printerr("6A SHOT: falha before/after: ", error_string(erro))
		return false
	return true
