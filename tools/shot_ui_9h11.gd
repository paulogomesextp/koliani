extends SceneTree
## 9H.11 -- fotografa os ecrãs de UI (Pausa / Santuário) para revisão visual.
## `godot --screen 1 --resolution 1280x720 --script res://tools/shot_ui_9h11.gd -- <qual> <saida.png>`

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var qual: String = a[0] if a.size() > 0 else "pausa"
	var saida: String = a[1] if a.size() > 1 else "user://ui.png"
	await process_frame
	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.08, 0.06, 0.1)
	root.add_child(fundo)
	if qual == "pausa":
		var p: Node = load("res://scenes/ui/Pausa.tscn").instantiate()
		root.add_child(p)
		(p as CanvasLayer).visible = true
		p.get_node("Painel").visible = true
	elif qual == "hud":
		var h: Node = load("res://scenes/ui/HUD.tscn").instantiate()
		root.add_child(h)
		for i in 10:
			await process_frame
		if h.has_method("_ao_combate_chefe"):
			h.call("_ao_combate_chefe", null)
	else:
		var s: Control = load("res://scenes/ui/Santuario.tscn").instantiate()
		root.add_child(s)
	for i in 40:
		await process_frame
	var img := root.get_texture().get_image()
	img.save_png(saida)
	print("gravado: ", saida)
	quit()
