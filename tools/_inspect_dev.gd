extends SceneTree
func _init() -> void:
	await process_frame
	var e: Node = get_root().get_node_or_null("EstadoJogo")
	if e: e.ativar_modo_dev()
	if e: e.indice_nivel = 0
	if e: change_scene_to_file(e.NIVEIS[0])
	for i in 40: await process_frame
	var d := get_root().get_node_or_null("Main/DevBarra")
	if d == null: d = get_first_node_in_group("dev_barra")
	print("DEV ", d)
	if d:
		for n in d.get_children():
			if n is Button: print(n.name, " vis=", n.visible, " pos=", n.position, " size=", n.size, " text=", n.text)
	quit()
