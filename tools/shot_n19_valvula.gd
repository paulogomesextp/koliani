extends SceneTree
## Fotografa o N19 com uma valvula ABERTA: leva a Koliani a `valvula`, espera
## `segundos` e grava o PNG. Uso (isolado, janela real):
##   python tools/godot_isolado.py -- --window --screen 1 --path . \
##     --script res://tools/shot_n19_valvula.gd -- <valvula> <saida.png> [segundos] [camera_x]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var nome: String = args[0] if args.size() > 0 else "ValvulaB1"
	var saida: String = args[1] if args.size() > 1 else "user://shot.png"
	var segundos: float = float(args[2]) if args.size() > 2 else 1.0
	var cam_x: float = float(args[3]) if args.size() > 3 else -1.0
	var cena := "res://scenes/levels/Templo_da_Serpente.tscn"
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es:
		es.indice_nivel = int(es.NIVEIS.find(cena))
		es.checkpoint = Vector2.ZERO
	change_scene_to_file(cena)
	await process_frame
	await process_frame
	var v: Node2D = current_scene.get_node_or_null(nome)
	var k := get_first_node_in_group("koliani")
	if v == null or k == null:
		print("sem valvula/Koliani")
		quit(2)
		return
	k.set("_invulneravel", 99.0)
	k.global_position = v.global_position + Vector2(0, -30)
	for _i in 12:
		await process_frame
	if cam_x >= 0.0:
		k.global_position.x = cam_x
		k.global_position.y = v.global_position.y - 40.0
		k.set("velocity", Vector2.ZERO)
	await create_timer(segundos).timeout
	var img := get_root().get_texture().get_image()
	img.save_png(saida)
	print("shot -> ", saida, " | aberta=", v.get("aberta"))
	quit()
