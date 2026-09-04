extends SceneTree
## Bancada da HUD: carrega um nivel, poe a HUD no estado que se quer ver e
## grava um PNG. Serve para conferir a arte da interface (`assets/ui/`, ver
## `tools/gerar_ui.py`) sem ter de jogar ate' la'.
##
## PRECISA DE JANELA -- nesta maquina o renderer `dummy` do `--headless`
## devolve PNG pretos:
##
##   Godot..._console.exe --window --screen 1 \
##       --script res://tools/shot_hud.gd -- <indice_nivel> <saida.png> [chefe]
##
##   indice_nivel -- 0..99. Manda o cabecalho de nivel (regiao, cor, passo).
##   chefe        -- "chefe" mostra tambem a barra do chefe, a meia vida.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var indice: int = int(args[0]) if args.size() > 0 else 0
	var saida: String = args[1] if args.size() > 1 else "user://hud.png"
	var com_chefe := args.size() > 2 and args[2] == "chefe"

	await process_frame
	var estado := root.get_node_or_null("EstadoJogo")
	if estado:
		estado.indice_nivel = clampi(indice, 0, estado.NIVEIS.size() - 1)
		estado.essencia = 1240
		estado.vidas = 5
		# LIMPAR O CHECKPOINT. Ele fica gravado do save anterior, que e' de
		# outro nivel: a Koliani nascia dentro do liquido mortal e o PNG saia
		# com a barra de vida a zero (parecia arte partida, era a personagem
		# a morrer no primeiro frame).
		estado.checkpoint = Vector2.ZERO
		# habilidades todas, para a barra de Energia aparecer no retrato
		for h in estado.HABILIDADES_TODAS:
			estado.desbloquear_habilidade(h)
	# a HUD nao vive no `.tscn` do nivel -- quem lha cola por cima e' a
	# `Main.tscn` (ver `scripts/main.gd`). Carregar so' o nivel dava um PNG
	# sem interface nenhuma.
	change_scene_to_file("res://scenes/Main.tscn")
	for _i in 6:
		await process_frame
	await create_timer(0.8).timeout

	if com_chefe:
		var hud := _achar_hud()
		var chefe := get_first_node_in_group("chefes")
		if hud and chefe:
			hud._ao_combate_chefe(chefe)
			hud._atualizar_barra_chefe(46, 100)
		await create_timer(0.6).timeout

	var img := get_root().get_texture().get_image()
	img.save_png(saida)
	print("shot -> ", saida)
	quit()


func _achar_hud() -> Node:
	for n in get_nodes_in_group("hud"):
		return n
	# a HUD nao esta' em grupo: procura-se pelo script
	return _procurar(root)


func _procurar(n: Node) -> Node:
	if n is CanvasLayer and n.has_method("_ao_combate_chefe"):
		return n
	for f in n.get_children():
		var r := _procurar(f)
		if r:
			return r
	return null
