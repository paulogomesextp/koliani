extends SceneTree
## 9H.16 E4 -- prova de que os sons novos das mecanicas existem E disparam.
func _init() -> void:
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	if DisplayServer.get_screen_count() > 1:
		root.position = DisplayServer.screen_get_position(1) + Vector2i(60, 60)
	await process_frame
	var som := root.get_node("Som")
	for chave in ["raiz_irrompe", "raiz_aviso", "plataforma_surge"]:
		var st = som.call("_stream", chave)
		print("STREAM %-18s %s" % [chave, "OK" if st != null else "EM FALTA"])
		assert(st != null, "sem stream para " + chave)

	var estado := root.get_node("EstadoJogo")
	estado.indice_nivel = 0
	estado.checkpoint = Vector2.ZERO
	change_scene_to_file("res://scenes/Main.tscn")
	await create_timer(2.6).timeout
	# conta vozes a tocar enquanto uma raiz faz um ciclo completo
	var raiz: Node2D = null
	for n in _todos(current_scene):
		if n is Area2D and n.has_method("avisar") and bool(n.get("auto")):
			raiz = n
			break
	print("RAIZ_AUTO=", raiz != null)
	var ritmadas := 0
	for n in _todos(current_scene):
		if n.has_method("desmoronar"):
			ritmadas += 1
	print("PLATAFORMAS_RITMADAS=", ritmadas)
	var ouvidos := {}
	for _f in range(900):
		await process_frame
		for p in som.get_children():
			if p is AudioStreamPlayer and p.playing and p.stream != null:
				ouvidos[p.stream.resource_path.get_file()] = true
	print("TOCARAM=", ouvidos.keys())
	for chave in ["raiz_irrompe.wav", "raiz_aviso.wav", "plataforma_surge.wav"]:
		assert(ouvidos.has(chave), "nao tocou: " + chave)
	quit()

func _todos(n: Node) -> Array[Node]:
	var fora: Array[Node] = [n]
	for f in n.get_children():
		fora.append_array(_todos(f))
	return fora
