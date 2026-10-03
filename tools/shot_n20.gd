extends SceneTree
## Fotografa o N20: leva a Koliani a (x, y), opcionalmente espera que o
## Guardiao chegue a uma fase (p.ex. GOLPE_TEL, CHAMAS, ERUPCAO_TEL; as de
## fase 2 forcam a vida a 49 %) e grava o PNG. Janela real:
##   python tools/godot_isolado.py -- --window --screen 1 --path . \
##     --script res://tools/shot_n20.gd -- <saida.png> <x> [fase] [kx_relativo_ao_boss]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0] if args.size() > 0 else "user://shot.png"
	var x: float = float(args[1]) if args.size() > 1 else 170.0
	var fase: String = args[2] if args.size() > 2 else ""
	var cena := "res://scenes/levels/O_Abismo.tscn"
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es:
		es.modo_teste = true
		es.indice_nivel = int(es.NIVEIS.find(cena))
		es.checkpoint = Vector2.ZERO
	RelogioFornalha.manual = -1.0
	change_scene_to_file(cena)
	await process_frame
	await process_frame
	var k := get_first_node_in_group("koliani")
	var chefe := current_scene.get_node_or_null("Chefe")
	k.set("_invulneravel", 999.0)
	k.global_position = Vector2(x, 560.0)
	var pos: Vector2 = k.global_position
	if fase != "" and chefe:
		if fase in ["INVEST_TEL", "INVEST", "ERUPCAO_TEL", "ERUPCAO", "TRANSFORMA"]:
			chefe.vida = int(float(chefe.vida_maxima_luta()) * 0.49)
			if fase.begins_with("ERUPCAO"):
				chefe.set("_ciclos", 4)
			elif fase.begins_with("INVEST"):
				chefe.set("_ciclos", 2)
		elif fase.begins_with("CHAMAS"):
			chefe.set("_ciclos", 2)
		elif fase.begins_with("ONDA"):
			chefe.set("_ciclos", 1)
		pos = Vector2(chefe.global_position.x - 230.0, 560.0)
		if args.size() > 3:
			pos.x = chefe.global_position.x + float(args[3])
		for _i in 900:
			await physics_frame
			k.global_position = pos
			k.velocity = Vector2.ZERO
			if chefe.fase_atual() == fase:
				break
		await create_timer(0.25).timeout
	else:
		for _i in 20:
			await process_frame
		await create_timer(0.6).timeout
	var img := get_root().get_texture().get_image()
	img.save_png(saida)
	print("shot -> ", saida, " | fase=", chefe.fase_atual() if chefe else "-")
	quit()
