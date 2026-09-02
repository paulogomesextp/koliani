extends SceneTree
## Põe a Koliani ao pé do chefe de um nível e deixa a luta correr, a gravar
## o ecrã de X em X segundos. Serve para apanhar problemas que só aparecem
## DURANTE o combate (ecrã preto, câmara perdida, chefe fora da arena) e que
## um screenshot único não mostra.
##
##   Godot --window --screen 1 --script res://tools/testar_chefe.gd -- \
##       <indice_0based> <prefixo_saida> [n_shots] [seg_entre_shots] [zoom]
##
## Em cada disparo imprime também o estado da câmara e da modulação de
## ambiente -- é por aí que se percebe um "ficou tudo preto".

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var idx: int = int(args[0]) if args.size() > 0 else 6
	var pref: String = args[1] if args.size() > 1 else "user://chefe"
	var n: int = int(args[2]) if args.size() > 2 else 6
	var espera: float = float(args[3]) if args.size() > 3 else 3.0
	var zoom: float = float(args[4]) if args.size() > 4 else 0.9

	await process_frame
	var estado: Node = get_root().get_node("/root/EstadoJogo")
	estado.ativar_modo_dev()
	estado.indice_nivel = idx
	estado.checkpoint = Vector2.ZERO
	estado._limpar_jornada_ancora()
	change_scene_to_file(estado.NIVEIS[idx])
	for _i in 40:
		await process_frame
	await create_timer(0.8).timeout

	var k := get_first_node_in_group("koliani") as Node2D
	var chefe := get_first_node_in_group("chefes") as Node2D
	if k == null or chefe == null:
		print("falta koliani(%s) ou chefe(%s)" % [k != null, chefe != null]); quit(1); return
	var cam := k.get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.zoom = Vector2(zoom, zoom)
	var recuo: float = float(args[5]) if args.size() > 5 else 200.0
	var andar: bool = recuo > 400.0   # de longe, vai a andar para a direita
	k.global_position = chefe.global_position + Vector2(-recuo, -20.0)
	if "velocity" in k:
		k.velocity = Vector2.ZERO
	print("chefe=%s em %s" % [chefe.name, chefe.global_position])
	if not andar:
		# arranca a luta a sério (música + máquina de estados do chefe)
		if chefe.has_method("provocar"):
			chefe.provocar()
		if chefe.has_method("receber_dano"):
			chefe.receber_dano(40, 1.0)
		# FASE 2 já: é aí que os chefes largam os efeitos grandes
		if chefe.has_method("_entrar_fase2"):
			chefe.call("_entrar_fase2")
			print("fase2 forcada")

	for s in n:
		if andar:
			Input.action_press("mover_direita")
			await create_timer(espera).timeout
			Input.action_release("mover_direita")
			await create_timer(0.15).timeout
			var img2 := get_root().get_texture().get_image()
			var fn2 := "%s_%02d.png" % [pref, s]
			img2.save_png(fn2)
			print("shot %d -> %s  koliani=%s  chefe_vida=%s  %s"
				% [s, fn2, k.global_position if is_instance_valid(k) else "morta",
					chefe.get("vida") if is_instance_valid(chefe) else "?", _suspeitos()])
			continue
		# vai batendo, como um jogador faria -- é durante os ataques que os
		# efeitos de ecrã aparecem
		for _b in 3:
			Input.action_press("atacar")
			await create_timer(0.08).timeout
			Input.action_release("atacar")
			await create_timer(0.32).timeout
		await create_timer(espera).timeout
		var img := get_root().get_texture().get_image()
		var fn := "%s_%02d.png" % [pref, s]
		img.save_png(fn)
		var linha := "shot %d -> %s" % [s, fn]
		if cam and is_instance_valid(cam):
			linha += "  cam=%s zoom=%s" % [cam.get_screen_center_position(), cam.zoom]
		if is_instance_valid(chefe):
			linha += "  chefe=%s vida=%s" % [chefe.global_position, chefe.get("vida")]
		if is_instance_valid(k):
			linha += "  koliani=%s" % k.global_position
		print(linha, "  ", _suspeitos())
	quit()


## Nós que podem estar a tapar o ecrã: modulação de ambiente muito escura,
## CanvasLayers extra, ou algum CanvasItem enorme por cima de tudo.
func _suspeitos() -> String:
	var out := "pausado=%s time_scale=%.2f " % [str(paused), Engine.time_scale]
	var tr := get_root().get_node_or_null("Transicao")
	if tr:
		for f in (tr as Node).get_children():
			if f is ColorRect:
				out += "fade_alpha=%.2f " % (f as ColorRect).color.a
	var mod := get_first_node_in_group("atmosfera")
	if mod:
		var cm := (mod as Node).get_node_or_null("Modulacao") as CanvasModulate
		if cm:
			out += "ambiente=%s " % cm.color
	var camadas := 0
	for c in get_root().get_children():
		camadas += _contar_layers(c)
	out += "canvaslayers=%d" % camadas
	return out


func _contar_layers(no: Node) -> int:
	var n := 1 if no is CanvasLayer and no.visible else 0
	for f in no.get_children():
		n += _contar_layers(f)
	return n
