extends SceneTree
## Captura do HUD em jogo (cena Main com o nível N, HUD por cima).
## Uso: Godot --resolution 1280x720 --script res://tools/shot_hud_jogo.gd -- <nivel 1-100> <saida.png> [dano]
## `dano` > 0 tira vida a' Koliani e acende o aviso de checkpoint, para ver estados.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var nivel := int(args[0]) if args.size() > 0 else 1
	var saida: String = args[1] if args.size() > 1 else "user://hud.png"
	var dano := int(args[2]) if args.size() > 2 else 0
	await process_frame
	var es := root.get_node("/root/EstadoJogo")
	es.indice_nivel = nivel - 1
	es.checkpoint = Vector2.ZERO
	change_scene_to_file("res://scenes/Main.tscn")
	for _i in 4:
		await process_frame
	var k := get_first_node_in_group("koliani")
	if k and dano > 0:
		k.set("_invulneravel", 0.0)
		k.receber_dano(dano, 1.0) if k.has_method("receber_dano") else null
	await create_timer(1.6).timeout
	get_root().get_texture().get_image().save_png(saida)
	print("shot -> ", saida)
	quit()
