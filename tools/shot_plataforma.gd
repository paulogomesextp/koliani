extends SceneTree
## Smoke-shot: carrega um nivel, opcionalmente move a Koliani para um X,
## espera `segundos` e grava um PNG do ecra.
## Uso: Godot --window ... --script res://tools/shot_plataforma.gd -- \
##        <cena> <saida> [segundos] [koliani_x] [koliani_y]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var cena: String = args[0] if args.size() > 0 else "res://scenes/levels/Floresta_Putrefata.tscn"
	var saida: String = args[1] if args.size() > 1 else "user://shot.png"
	var segundos: float = float(args[2]) if args.size() > 2 else 0.5
	var kx: float = float(args[3]) if args.size() > 3 else -1.0
	var ky: float = float(args[4]) if args.size() > 4 else -1.0
	await process_frame
	change_scene_to_file(cena)
	await process_frame
	await process_frame
	if kx >= 0.0:
		var k := get_first_node_in_group("koliani")
		if k:
			k.global_position.x = kx
			if ky >= 0.0:
				k.global_position.y = ky
			for _i in 8:
				await process_frame
	await create_timer(segundos).timeout
	var img := get_root().get_texture().get_image()
	img.save_png(saida)
	print("shot -> ", saida)
	quit()
