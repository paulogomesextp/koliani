extends SceneTree
## Captura visual da arquitectura da Regiao II sem teletransportar a Koliani.
##
## O `shot_r2.gd` move a personagem para provar o enquadramento jogavel. Num
## vao do N08 ela cai e a cena recarrega antes da fotografia; isso torna-o
## inadequado para fotografar uma cascata que existe precisamente no vazio.
## Aqui a Camera2D e' destacada temporariamente e colocada na coordenada
## pedida. Nao altera a cena guardada nem serve como prova de percurso.
##
## Uso:
##   godot --path . --resolution 1280x720 \
##     --script res://tools/shot_arquitetura_regiao02.gd -- \
##     <cena> <saida.png> <x> <y>


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 4:
		push_error("uso: -- <cena> <saida.png> <x> <y>")
		quit(2)
		return
	var cena: String = args[0]
	var saida: String = args[1]
	var alvo := Vector2(float(args[2]), float(args[3]))
	await process_frame
	var estado := root.get_node_or_null("/root/EstadoJogo")
	if estado:
		var indice := int(estado.NIVEIS.find(cena))
		if indice >= 0:
			estado.indice_nivel = indice
			estado.checkpoint = Vector2.ZERO
	change_scene_to_file(cena)
	for _i in 12:
		await process_frame
	var cam := root.get_viewport().get_camera_2d()
	if cam == null or current_scene == null:
		push_error("camara ou cena em falta")
		quit(3)
		return
	cam.reparent(current_scene, true)
	cam.position_smoothing_enabled = false
	cam.global_position = alvo
	cam.reset_physics_interpolation()
	for _i in 6:
		await process_frame
	DirAccess.make_dir_recursive_absolute(saida.get_base_dir())
	root.get_texture().get_image().save_png(saida)
	print("shot arquitectura -> ", saida, " @ ", alvo)
	quit(0)
