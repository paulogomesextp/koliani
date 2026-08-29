extends SceneTree
## Smoke-shot: carrega um nivel, espera uns frames e grava um PNG do ecra.
## Uso: Godot --window ... --script res://tools/shot_plataforma.gd -- <cena> <saida>

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var cena: String = args[0] if args.size() > 0 else "res://scenes/levels/Floresta_Putrefata.tscn"
	var saida: String = args[1] if args.size() > 1 else "user://shot.png"
	await process_frame
	change_scene_to_file(cena)
	for i in 30:
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(saida)
	print("shot -> ", saida)
	quit()
