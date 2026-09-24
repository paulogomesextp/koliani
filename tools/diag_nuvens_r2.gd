extends SceneTree
## Mede o contributo REAL do mar de nuvens: grava dois PNG do mesmo
## instante, um com a camada `Meio` visivel e outro sem ela. A diferenca
## entre os dois e' exactamente o que as nuvens poem no ecra.
## Uso: --script res://tools/diag_nuvens_r2.gd -- <cena> <prefixo>

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var cena: String = args[0]
	var pref: String = args[1]
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es:
		var i := int(es.NIVEIS.find(cena))
		if i >= 0:
			es.indice_nivel = i
		es.checkpoint = Vector2.ZERO
	change_scene_to_file(cena)
	for _i in 40:
		await process_frame

	var atm := get_first_node_in_group("atmosfera")
	var nuv: Node = null
	for c in atm.get_node("Parallax").get_children():
		for n in c.get_children():
			if n is Sprite2D and n.texture and \
					n.texture.resource_path.ends_with("nuvens.png"):
				nuv = n
	if nuv == null:
		print("SEM CAMADA DE NUVENS"); quit(1); return

	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("%s_com.png" % pref)
	nuv.visible = false
	for _i in 3:
		await process_frame
	img = root.get_viewport().get_texture().get_image()
	img.save_png("%s_sem.png" % pref)
	print("OK ", pref)
	quit(0)
