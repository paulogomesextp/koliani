extends SceneTree
## Verifica folga dos volumes e fotografa as dez masmorras numa folha.
## O N08 (índice 7) saiu no Process 11: passou a Ilhas Suspensas, sem Casca.
const INDICES := [5, 6, 8, 9, 15, 16, 17, 18, 19]

func _init() -> void:
	await process_frame
	var estado := root.get_node("EstadoJogo")
	var falhas := 0
	var folha := Image.create(1600, 360, false, Image.FORMAT_RGB8)
	for i in INDICES.size():
		var indice: int = INDICES[i]
		estado.indice_nivel = indice
		estado.checkpoint = Vector2.ZERO
		change_scene_to_file(estado.NIVEIS[indice])
		await process_frame
		await physics_frame
		await physics_frame
		var casca := current_scene.get_node("Casca")
		var volumes := 0
		for parede in casca.get_children():
			if not str(parede.name).begins_with("Alvenaria"):
				continue
			volumes += 1
			var col: CollisionShape2D = parede.get_child(0)
			var tamanho: Vector2 = col.shape.size
			var ret := Rect2(parede.global_position - tamanho * 0.5, tamanho)
			for ator in current_scene.get_children():
				if not ator is Node2D or ator.get("tamanho") == null:
					continue
				var tam: Vector2 = ator.get("tamanho")
				var topo: Vector2 = ator.global_position - tam * 0.5
				var salto := Rect2(topo - Vector2(32, 180), Vector2(tam.x + 64, 180))
				if ret.intersects(salto):
					printerr("Nível ", indice + 1, ": teto invade salto de ", ator.name)
					falhas += 1
		if volumes == 0:
			falhas += 1
		print("Nível ", indice + 1, ": ", volumes, " volumes")
		if DisplayServer.get_name() != "headless":
			var k: Node2D = get_first_node_in_group("koliani")
			var alvo: Node2D = current_scene.get_node_or_null("ChaoMeio")
			if alvo:
				k.global_position = alvo.global_position - Vector2(0, 100)
			await create_timer(0.25).timeout
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			img.convert(Image.FORMAT_RGB8)
			img.resize(320, 180)
			folha.blit_rect(img, Rect2i(0, 0, 320, 180), Vector2i(i % 5 * 320, i / 5 * 180))
	if DisplayServer.get_name() != "headless":
		folha.save_png("res://work/interiores-masmorras.png")
	print("Folgas dos interiores: ", falhas, " falhas")
	quit(0 if falhas == 0 else 1)
