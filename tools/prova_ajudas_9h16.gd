extends SceneTree
## 9H.16 C -- prova visual da UX das ajudas em 1280x720: dispara um toast e a
## placa de mecanica e fotografa o ecra, para se ver ONDE ficam. Nao rouba o
## foco (FLAG_NO_FOCUS) e escreve em `work/9h16/`.
const SAIDA := "res://work/9h16/"


func _init() -> void:
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	if DisplayServer.get_screen_count() > 1:
		root.position = DisplayServer.screen_get_position(1) + Vector2i(60, 60)
	await process_frame
	var estado := root.get_node("EstadoJogo")
	estado.indice_nivel = 0
	estado.checkpoint = Vector2.ZERO
	change_scene_to_file("res://scenes/Main.tscn")
	await create_timer(2.4).timeout
	var hud := get_first_node_in_group("hud_9f")
	assert(hud != null, "HUD 9F ausente")
	var jogador := get_first_node_in_group("koliani") as CharacterBody2D
	assert(jogador != null, "L1 nao abriu")

	# 1) toast curto (o do checkpoint)
	hud._aviso(root.get_node("Textos").t("hud.checkpoint"), "ico_checkpoint", "info")
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(SAIDA + "c_toast.png")
	print("TOAST pos=", _pos(hud), " size=", _tam(hud))

	await create_timer(2.4).timeout

	# 2) placa de mecanica (o banner grande de 10 s)
	print("EM_COMBATE=", hud._em_combate())
	hud._placa_tutorial("SALTOS", root.get_node("Textos").t("mec.saltos.txt"))
	await create_timer(7.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(SAIDA + "c_placa.png")
	var p := _pos(hud)
	var t := _tam(hud)
	print("PLACA pos=", p, " size=", t)
	var ecra := root.get_visible_rect().size
	print("ECRA=", ecra)
	# A caixa nao pode invadir a banda central (34% do meio).
	var meio_e := ecra.x * 0.33
	var meio_d := ecra.x * 0.67
	var invade := p.x < meio_d and (p.x + t.x) > meio_e
	print("INVADE_CENTRO=", invade)
	quit(1 if invade else 0)


func _pos(hud: Node) -> Vector2:
	var n := hud.get_node_or_null("NotificacaoAtiva") as Control
	return n.position if n else Vector2(-1, -1)


func _tam(hud: Node) -> Vector2:
	var n := hud.get_node_or_null("NotificacaoAtiva") as Control
	return n.size if n else Vector2(-1, -1)
