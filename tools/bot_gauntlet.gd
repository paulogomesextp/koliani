extends SceneTree
## Bot anti-softlock do gauntlet: larga a Koliani no início e mantém-na a
## andar para a direita (com saltos e um dash ocasional). De X em X segundos
## verifica que o X avançou; se ficar parado muito tempo, FALHA e diz onde.
## Uso: Godot --window --script res://tools/bot_gauntlet.gd -- <cena> [segundos]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var cena: String = args[0] if args.size() > 0 else "res://scenes/levels/Prisao_dos_Condenados.tscn"
	var limite: float = float(args[1]) if args.size() > 1 else 70.0
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es:
		es.checkpoint = Vector2.ZERO
		es.indice_nivel = int(args[2]) if args.size() > 2 else 8
		# simula um jogador com o kit permanente já ganho
		es.habilidades.assign(["salto_duplo", "dash_aereo", "escalar_paredes", "projetil", "escudo"])
		# só nos interessa a TRAVESSIA -- sem dano, o bot só pára se estiver
		# geometricamente bloqueado (softlock).
		es.modo_dev = true
	change_scene_to_file(cena)
	await process_frame
	await process_frame
	var k := get_first_node_in_group("koliani") as Node2D
	if k == null:
		print("SEM Koliani"); quit(1); return

	var alvo_x := k.global_position.x       # a Porta / fim do nível
	for n in get_current_scene().get_children():
		if n.name == "Porta":
			alvo_x = (n as Node2D).global_position.x

	await create_timer(0.5).timeout
	var x_ini := k.global_position.x
	var melhor_x := x_ini
	var parado := 0.0
	var t := 0.0
	var pior_parado := 0.0
	var pior_x := x_ini
	var salto_t := 0.0
	Input.action_press("mover_direita")

	while t < limite:
		var dt := 1.0 / 60.0
		await physics_frame
		k = get_first_node_in_group("koliani") as Node2D
		if k == null:
			continue
		t += dt
		salto_t += dt
		var ciclo := 1.4 if parado > 1.0 else 0.7   # preso -> saltos longos
		var hold := 0.34 if parado > 1.0 else 0.14
		if salto_t > ciclo:
			Input.action_press("saltar"); salto_t = 0.0
		elif salto_t > hold:
			Input.action_release("saltar")
		# dash a meio do salto quando está preso (passa muros/serras)
		if parado > 1.0 and salto_t > 0.16 and salto_t < 0.22:
			Input.action_press("dash")
		elif fmod(t, 2.1) < dt:
			Input.action_press("dash")
		else:
			Input.action_release("dash")

		var x := k.global_position.x
		if x > melhor_x + 6.0:
			melhor_x = x
			parado = 0.0
		else:
			parado += dt
			if parado > pior_parado:
				pior_parado = parado
				pior_x = k.global_position.x
		if x >= alvo_x - 40.0:
			break

	Input.action_release("mover_direita")
	Input.action_release("saltar")
	Input.action_release("dash")
	var chegou: bool = melhor_x >= alvo_x - 80.0
	var travado: bool = pior_parado > 9.0
	print("cena=%s  x_ini=%.0f  melhor_x=%.0f  alvo_x=%.0f  chegou=%s" % [
		cena.get_file(), x_ini, melhor_x, alvo_x, str(chegou)])
	print("  maior tempo parado=%.1fs perto de x=%.0f" % [pior_parado, pior_x])
	if travado:
		print("  <<< POSSIVEL SOFTLOCK perto de x=%.0f" % pior_x)
	quit(0 if (chegou and not travado) else 2)
