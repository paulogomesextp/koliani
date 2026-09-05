extends SceneTree
## Fotografa um nível **com os controlos de toque ligados à força**, para se
## poder ver o joystick e os quatro botões sem ter um telemóvel à mão
## (`DisplayServer.is_touchscreen_available()` é falso num PC).
##
## Uso: Godot --window --screen 1 --resolution 1600x720 \
##        --script res://tools/shot_toque.gd -- <cena> <saida.png> [segundos]
##
## A resolução é o que interessa aqui: 1600x720 é o que o `expand` dá num
## telemóvel de 20:9, e é nessa forma que se vê se o zoom da câmara ficou
## igual ao do Windows e se os botões caem nos cantos certos.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var cena: String = args[0] if args.size() > 0 else "res://scenes/levels/Floresta_Putrefata.tscn"
	var saida: String = args[1] if args.size() > 1 else "user://shot_toque.png"
	var segundos: float = float(args[2]) if args.size() > 2 else 1.0
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es:
		var i := int(es.NIVEIS.find(cena))
		if i >= 0:
			es.indice_nivel = i
		es.checkpoint = Vector2.ZERO
		# com o kit todo: a barra de Energia e o disco da arma só aparecem
		# com as habilidades ganhas, e é com eles que a arrumação aperta
		es.habilidades.assign(["salto_duplo", "dash_aereo", "escalar_paredes",
			"projetil", "escudo", "planar"])
	# a HUD vem do `Main.tscn`, nao do nivel: carregar o nivel a' mao dava
	# uma foto sem HUD nenhuma (e sem controlos de toque, que e' o que se
	# quer ver aqui). O nivel escolhe-se pelo `indice_nivel`.
	change_scene_to_file("res://scenes/Main.tscn")
	await process_frame
	await process_frame
	await process_frame
	# a partir da RAIZ e não da cena: a HUD é um `CanvasLayer` que pode ser
	# filho do `main`, e não do nível
	var hud := _procurar(root, "Toque")
	if hud:
		hud.visible = true
		if hud.has_method("_medir"):
			hud.call("_medir")
		var pai := hud.get_parent()
		if pai and pai.has_method("_arrumar_para_toque"):
			pai.call("_arrumar_para_toque")
		print("controlos de toque: LIGADOS")
	else:
		print("AVISO: nao encontrei o no 'Toque' -- a foto sai sem controlos")
	await create_timer(segundos).timeout
	var img := get_root().get_texture().get_image()
	img.save_png(saida)
	print("shot -> %s  (%dx%d)" % [saida, img.get_width(), img.get_height()])
	quit()


func _procurar(n: Node, nome: String) -> Node:
	if n == null:
		return null
	for f in n.get_children():
		if f.name == nome:
			return f
		var r := _procurar(f, nome)
		if r:
			return r
	return null
