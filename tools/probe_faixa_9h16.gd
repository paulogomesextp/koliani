extends SceneTree
func _init() -> void:
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	if DisplayServer.get_screen_count() > 1:
		root.position = DisplayServer.screen_get_position(1) + Vector2i(60, 60)
	await process_frame
	var estado := root.get_node("EstadoJogo")
	estado.indice_nivel = 0
	estado.checkpoint = Vector2.ZERO
	change_scene_to_file("res://scenes/Main.tscn")
	await create_timer(4.0).timeout   # mesmo instante da captura que mostra a faixa
	var liq := current_scene.find_child("LiquidoMortal", true, false) as Node2D
	if liq == null:
		print("SEM LIQUIDO"); quit(); return
	var cam := get_first_node_in_group("koliani") as Node2D
	print("KOLIANI_Y=", cam.global_position.y, " LIQ_Y=", liq.global_position.y)
	print("BASE  ", await _amostra())
	for f in liq.get_children():
		if not (f is CanvasItem) or not (f as CanvasItem).visible:
			continue
		(f as CanvasItem).visible = false
		await create_timer(0.35).timeout
		print("SEM %-22s %s" % [f.name, await _amostra()])
		(f as CanvasItem).visible = true
		await create_timer(0.15).timeout
	liq.visible = false
	await create_timer(0.35).timeout
	print("SEM LIQUIDO INTEIRO   ", await _amostra())
	quit()

func _amostra() -> String:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var soma := Color(0, 0, 0)
	var n := 0
	for x in range(300, 1000, 40):
		for y in range(640, 700, 10):
			soma += img.get_pixel(x, y)
			n += 1
	return "rgb(%.3f, %.3f, %.3f)" % [soma.r / n, soma.g / n, soma.b / n]
