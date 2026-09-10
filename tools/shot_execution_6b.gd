extends SceneTree
## Capturas reais da Execution 6B: personagem corrigida e vistas do Level 1.

const SAIDA := "res://work/execution_6b/preview/shots"
const FRAMES_RUN := [2, 3, 4, 5, 6, 7, 8]
const PONTOS_LEVEL := [
	["level_opening", -2250.0],
	["level_traversal", -1500.0],
	["level_platforms", 650.0],
	["level_heart_tree", 900.0],
	["level_enemies", 1450.0],
	["level_ruins", 2150.0],
	["level_corruption", 2750.0],
	["level_exit", 3350.0],
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	await process_frame
	var estado := root.get_node_or_null("/root/EstadoJogo")
	if estado == null:
		printerr("6B SHOT: EstadoJogo indisponível")
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
		printerr("6B SHOT: Koliani indisponível")
		quit(1)
		return
	var cam := koliani.get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.position_smoothing_enabled = false
	koliani.set_physics_process(false)
	koliani.set_process(false)
	var corpo := koliani.get_node("Sprite/Corpo") as AnimatedSprite2D
	# Passo2 é uma superfície estática sem checkpoint/prop sobre a personagem;
	# evita que um elemento do cenário contamine a leitura dos pés.
	var pos := _ponto_seguro(koliani, 880.0)
	koliani.global_position = pos
	koliani.velocity = Vector2.ZERO
	for _i in 8:
		await process_frame
	for frame in FRAMES_RUN:
		corpo.pause()
		corpo.animation = &"run"
		corpo.frame = frame
		await _guardar("koliani_run_%02d" % (frame + 1))
	corpo.animation = &"idle"
	corpo.frame = 0
	await _guardar("koliani_idle")
	for dados in PONTOS_LEVEL:
		koliani.global_position = _ponto_seguro(koliani, float(dados[1]))
		koliani.velocity = Vector2.ZERO
		corpo.animation = &"idle"
		corpo.frame = 0
		for _i in 8:
			await process_frame
		await _guardar(dados[0])
	print("EXECUTION 6B REAL RENDER: PASS")
	quit(0)


func _ponto_seguro(koliani: CharacterBody2D, x: float) -> Vector2:
	var espaco := koliani.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(Vector2(x, 120.0), Vector2(x, 880.0), 1)
	query.exclude = [koliani.get_rid()]
	var hit := espaco.intersect_ray(query)
	if hit.is_empty():
		return Vector2(x, 620.0)
	return Vector2(x, float(hit.position.y) - 24.0)


func _guardar(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var imagem := root.get_texture().get_image()
	var caminho := "%s/%s.png" % [SAIDA, nome]
	if imagem.save_png(ProjectSettings.globalize_path(caminho)) != OK:
		printerr("6B SHOT: falha a guardar ", caminho)
		quit(1)
		return
	print("shot -> ", caminho)
