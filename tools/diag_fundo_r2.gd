extends SceneTree
## Diagnostico do pipeline de fundo: onde e' que cada camada do `fundo_pack`
## fica, com que tinta chega, e se a camara a chega sequer a ver.
## Uso: Godot --script res://tools/diag_fundo_r2.gd -- <cena>

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var cena: String = args[0]
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es:
		var i := int(es.NIVEIS.find(cena))
		if i >= 0:
			es.indice_nivel = i
		es.checkpoint = Vector2.ZERO
	change_scene_to_file(cena)
	for _i in 6:
		await process_frame

	var atm := get_first_node_in_group("atmosfera")
	if atm == null:
		print("SEM ATMOSFERA"); quit(1); return
	var cam := get_first_node_in_group("koliani")
	var vis := Rect2()
	if cam:
		var vp := root.get_viewport().get_visible_rect().size
		vis = Rect2(cam.global_position - vp * 0.5, vp)
	print("== %s ==" % cena.get_file())
	print("  camara (aprox, centrada na Koliani): ", vis)
	var par := atm.get_node_or_null("Parallax")
	if par == null:
		print("  SEM Parallax"); quit(0); return
	for camada in par.get_children():
		for n in camada.get_children():
			if not (n is Sprite2D):
				continue
			var sp := n as Sprite2D
			if sp.texture == null:
				continue
			var r := Rect2(sp.global_position,
				sp.texture.get_size() * sp.scale)
			var tinta := "-"
			var ganho := "-"
			if sp.material is ShaderMaterial:
				var m := sp.material as ShaderMaterial
				tinta = str(m.get_shader_parameter("tinta"))
				ganho = str(m.get_shader_parameter("ganho"))
			print("  %-8s %-14s rect=%s  z=%d  mod=%s  tinta=%s ganho=%s  VE-SE=%s" % [
				camada.name, sp.texture.resource_path.get_file(), str(r),
				sp.z_index, str(sp.modulate), tinta, ganho,
				str(vis.intersects(r))])
	quit(0)
