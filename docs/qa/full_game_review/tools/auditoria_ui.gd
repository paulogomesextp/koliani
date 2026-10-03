extends SceneTree
## QA da auditoria externa (NAO e' produto). Fotografa menu, loja, seletor,
## mapa e pausa+HUD num nivel. Uso: --window --screen 1 --resolution 1280x720
##   --script res://docs/qa/full_game_review/tools/auditoria_ui.gd -- <pasta_abs>

var _pasta := ""

func _foto(nome: String, frames := 40) -> void:
	for _i in frames:
		await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [_pasta, nome])
	print("AUDIT foto ", nome)

func _init() -> void:
	_pasta = OS.get_cmdline_user_args()[0]
	await process_frame
	change_scene_to_file("res://scenes/ui/MenuInicial.tscn")
	await _foto("01_menu_principal", 90)
	var menu := current_scene
	if menu.has_method("_abrir_loja"):
		menu.call("_abrir_loja")
		await _foto("02_loja", 60)
	change_scene_to_file("res://scenes/ui/SeletorNiveis.tscn")
	await _foto("03_seletor", 60)
	change_scene_to_file("res://scenes/ui/MapaMundo.tscn")
	await _foto("04_mapa_mundo", 60)
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es:
		es.indice_nivel = 11
		es.checkpoint = Vector2.ZERO
	change_scene_to_file("res://scenes/levels/Torre_dos_Ventos.tscn")
	await _foto("05_hud_n12", 90)
	var p := (load("res://scenes/ui/Pausa.tscn") as PackedScene).instantiate()
	current_scene.add_child(p)
	if p.has_method("abrir"):
		p.call("abrir")
	await _foto("06_pausa", 30)
	quit(0)
