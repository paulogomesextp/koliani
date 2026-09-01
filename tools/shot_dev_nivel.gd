extends SceneTree
## Screenshot de um nível em MODO DEV (todas as habilidades), no índice certo
## para a jornada gerar como no jogo. Grava vários PNGs ao longo da jornada.
##   Godot --window --screen 1 --script res://tools/shot_dev_nivel.gd -- \
##       <indice_0based> <prefixo_saida> [n_shots] [passo_x]
## NB: o autoload EstadoJogo é acedido por /root/EstadoJogo (o identificador
## global não existe em modo --script).

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var idx: int = int(args[0]) if args.size() > 0 else 8
	var pref: String = args[1] if args.size() > 1 else "user://devshot"
	var n: int = int(args[2]) if args.size() > 2 else 5
	var passo: float = float(args[3]) if args.size() > 3 else 1600.0
	var zoom: float = float(args[4]) if args.size() > 4 else 1.4

	await process_frame
	var estado: Node = get_root().get_node("/root/EstadoJogo")
	estado.ativar_modo_dev()
	estado.indice_nivel = idx
	estado.checkpoint = Vector2.ZERO
	estado._limpar_jornada_ancora()
	change_scene_to_file(estado.NIVEIS[idx])
	for _i in 30:
		await process_frame
	await create_timer(0.6).timeout

	var k := get_first_node_in_group("koliani")
	if k == null:
		print("sem koliani"); quit(); return
	var cam := k.get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.zoom = Vector2(zoom, zoom)  # < 1 afasta p/ ver a verticalidade
		cam.position_smoothing_enabled = false
	var base_x: float = (k as Node2D).global_position.x
	var base_y: float = (k as Node2D).global_position.y
	for s in n:
		(k as Node2D).global_position = Vector2(base_x + passo * float(s), base_y - 40.0)
		if "velocity" in k:
			k.velocity = Vector2.ZERO
		for _j in 16:
			await process_frame
		await create_timer(0.25).timeout
		var img := get_root().get_texture().get_image()
		var fn := "%s_%02d.png" % [pref, s]
		img.save_png(fn)
		print("shot -> ", fn, "  x=", (k as Node2D).global_position.x)
	quit()
