extends SceneTree
## Bot anti-softlock: larga a Koliani no início do nível e leva-a para a
## direita até à Porta. Se houver um sítio de onde ela NUNCA sai, diz onde.
##
## Uso: Godot --window --script res://tools/bot_gauntlet.gd -- <cena> [segundos] [indice]
##
## ── Porque é que ele mentia (5 set 2026) ─────────────────────────────
## A versão anterior dava "POSSIVEL SOFTLOCK" no Nível 1, a 150 px do
## spawn, num nível que se joga bem. Eram duas coisas, e nenhuma era o
## nível:
##
##  1. **a definição estava errada.** Contava o maior tempo PARADO e
##     falhava acima de 9 s -- mas uma paragem que se resolve não é um
##     softlock, é um bot atrapalhado. O que define um softlock é ele
##     nunca mais passar dali. Agora só falha se o sítio onde parou mais
##     tempo for também o sítio onde a corrida ACABOU.
##  2. **o bot saltava por relógio**, num ciclo fixo de 0.7 s, batesse ou
##     não numa parede. Agora salta porque está preso, não porque o
##     relógio deu a hora -- e ao fim de um segundo e meio recua para
##     ganhar balanço, que é o que uma pessoa faz.
##
## Continua a não ser prova de que um nível é bom, nem sequer de que é
## atravessável: é um **indício**. O que ele encontra tem de se ir ver com
## `tools/ver_zona.gd` antes de lhe chamar softlock -- e o que ele ainda
## falha, medido a 5 set 2026, são as escadas da espinha com ~173 px de
## vão e 104 px de subida (o Nível 11 tem uma logo no início). Um jogador
## faz esse salto; ele não, e por isso um aviso dele não é um veredicto.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var cena: String = args[0] if args.size() > 0 else "res://scenes/levels/Prisao_dos_Condenados.tscn"
	var limite: float = float(args[1]) if args.size() > 1 else 180.0
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es:
		es.checkpoint = Vector2.ZERO
		es.indice_nivel = int(args[2]) if args.size() > 2 else 8
		# simula um jogador com o kit permanente já ganho
		es.habilidades.assign(["salto_duplo", "dash_aereo", "escalar_paredes",
			"projetil", "escudo", "planar"])
		# só nos interessa a TRAVESSIA -- sem dano, o bot só pára se estiver
		# geometricamente bloqueado (softlock).
		es.modo_dev = true
	change_scene_to_file(cena)
	await process_frame
	await process_frame
	var k := get_first_node_in_group("koliani") as Node2D
	if k == null:
		print("SEM Koliani"); quit(1); return

	var alvo_x := _alvo_x(k)
	await create_timer(0.5).timeout
	var x_ini := k.global_position.x
	var x_ant := x_ini
	var melhor_x := x_ini
	var parado := 0.0
	var t := 0.0
	var pior_parado := 0.0
	var pior_x := x_ini
	var salto_t := 0.0
	var recuo := 0.0
	var mortes := 0
	var segurar := 0.0
	var duplo := false
	var ataque_t := 0.0
	var relato := 0.0
	## `BOT_VERBOSE=1` conta onde ela esta' de segundo a segundo -- e' o que
	## diz a diferenca entre "o nivel tranca" e "o bot nao sabe passar".
	var verboso := OS.has_environment("BOT_VERBOSE")
	Input.action_press("mover_direita")

	while t < limite:
		var dt := 1.0 / 60.0
		await physics_frame
		k = get_first_node_in_group("koliani") as Node2D
		if k == null:
			continue
		t += dt
		salto_t += dt

		# --- os saltos: ver o vão, e usar o SEGUNDO salto --------------
		# Duas coisas que faltavam, e as duas custaram o mesmo: o bot corria
		# a direito para dentro do primeiro fosso (só saltava depois de já
		# estar preso) e, quando saltava, nunca usava o salto duplo. A
		# espinha da jornada é desenhada para vãos de ~180 px, que um salto
		# só não faz -- 161 px é tudo o que ele dá.
		var no_chao := k.has_method("is_on_floor") and bool(k.call("is_on_floor"))
		if no_chao:
			duplo = false
		var espaco := k.get_world_2d().direct_space_state
		var vao := false
		if no_chao:
			# 34 px e nao 56: saltar cedo demais desperdica meio salto. A
			# espinha tem vaos de 173 px com 104 px de subida, e esses so'
			# se fazem a saltar DA BEIRA.
			var o1: Vector2 = k.global_position + Vector2(34.0, -10.0)
			var q1 := PhysicsRayQueryParameters2D.create(o1, o1 + Vector2(0.0, 110.0), 1)
			q1.exclude = [k]
			vao = espaco.intersect_ray(q1).is_empty()
		var sem_chao := false
		if not no_chao:
			var o2: Vector2 = k.global_position + Vector2(20.0, 0.0)
			var q2 := PhysicsRayQueryParameters2D.create(o2, o2 + Vector2(0.0, 170.0), 1)
			q2.exclude = [k]
			sem_chao = espaco.intersect_ray(q2).is_empty()
		var vy: float = k.velocity.y if "velocity" in k else 0.0

		if segurar > 0.0:
			segurar -= dt
			if segurar <= 0.0:
				Input.action_release("saltar")

		if recuo > 0.0:
			recuo -= dt
			Input.action_release("mover_direita")
			Input.action_press("mover_esquerda")
			if recuo <= 0.0:
				Input.action_release("mover_esquerda")
				Input.action_press("mover_direita")
				salto_t = 0.0
		else:
			var quer := false
			if no_chao and (vao or parado > 0.25) and salto_t > 0.45:
				quer = true
			elif not no_chao and not duplo and vy > 20.0 and sem_chao:
				quer = true            # o segundo salto, a meio da queda
				duplo = true
			if quer and segurar <= 0.0:
				Input.action_press("saltar")
				segurar = 0.45
				salto_t = 0.0
			# preso a sério: recua meio segundo para ganhar balanço
			if parado > 1.6 and salto_t > 1.2:
				recuo = 0.45
				salto_t = 0.0

		# BATER e ATIRAR quando está preso. Há salas em que a passagem se
		# abre com um golpe (o sino da Torre dos Sinos torna a ponte
		# sólida; os espelhos partem-se; as paredes frágeis caem) -- e o
		# bot antigo NUNCA atacava, por isso ficava lá para sempre e
		# chamava-lhe softlock. Alterna golpe e tiro: um deles chega ao
		# que estiver longe.
		ataque_t += dt
		if parado > 1.0 and ataque_t > 0.5:
			ataque_t = 0.0
			if int(t) % 2 == 0:
				Input.action_press("atacar")
			else:
				Input.action_press("lancar")
		elif ataque_t > 0.12:
			Input.action_release("atacar")
			Input.action_release("lancar")

		# dash: só quando está preso no chão. Tentou-se dar-lho no AR para
		# esticar os saltos e foi PIOR (4256 -> 2051 px de travessia): o
		# dash zera a velocidade vertical e ela cai a direito no fim dele.
		if no_chao and parado > 1.0 and salto_t > 0.12 and salto_t < 0.20:
			Input.action_press("dash")
		else:
			Input.action_release("dash")

		if verboso:
			relato += dt
			if relato >= 1.0:
				relato = 0.0
				print("    t=%5.1f  x=%7.0f  y=%7.0f  parado=%4.1f  chao=%s" % [
					t, k.global_position.x, k.global_position.y, parado,
					str(k.call("is_on_floor")) if k.has_method("is_on_floor") else "?"])
		var x := k.global_position.x
		# um salto para trás de mais de 800 px é uma MORTE (voltou ao
		# checkpoint). Uma coisa é ela ficar parada contra geometria; outra
		# é cair sempre no mesmo vão -- não são o mesmo problema e não
		# podem dar o mesmo aviso.
		if x < x_ant - 800.0:
			mortes += 1
		x_ant = x
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
	Input.action_release("mover_esquerda")
	Input.action_release("saltar")
	Input.action_release("dash")
	Input.action_release("atacar")
	Input.action_release("lancar")

	var chegou: bool = melhor_x >= alvo_x - 80.0
	# SOFTLOCK = o sítio onde parou mais tempo é também onde a corrida
	# acabou. Uma paragem que se resolve não conta: passou-se dali.
	var preso_no_fim: bool = not chegou and parado > 8.0 and mortes == 0
	print("cena=%s  x_ini=%.0f  melhor_x=%.0f  alvo_x=%.0f  chegou=%s" % [
		cena.get_file(), x_ini, melhor_x, alvo_x, str(chegou)])
	print("  avancou %.0f px em %.0fs; maior paragem %.1fs perto de x=%.0f%s" % [
		melhor_x - x_ini, t, pior_parado, pior_x,
		"  (resolvida)" if not preso_no_fim else ""])
	if preso_no_fim:
		print("  <<< NAO PASSOU DAQUI: %.1fs parado em x=%.0f, vivo e sem morrer."
			% [parado, melhor_x])
		print("   Ver com `tools/ver_zona.gd` antes de lhe chamar softlock -- o bot")
		print("   ainda falha escadas de ~173 px com 104 px de subida.")
	elif not chegou and mortes > 0:
		print("  (nao chegou: morreu %d vezes -- ha' um vao que ele nao faz perto de x=%.0f."
			% [mortes, melhor_x])
		print("   Isto NAO e' softlock: e' o bot a falhar um salto, ou o vao a ser apertado.)")
	elif not chegou:
		print("  (nao chegou ao fim em %.0fs -- pode ser so' falta de tempo)" % limite)
	quit(0 if (chegou and not preso_no_fim) else 2)


## O x da Porta do nível. Procura-a em TODA a árvore -- na versão anterior
## só olhava para os filhos diretos da cena, e a Porta da jornada vive
## dentro do contentor do corredor.
func _alvo_x(k: Node2D) -> float:
	var achado := _procurar(get_current_scene(), "Porta")
	if achado:
		return achado.global_position.x
	var chefes := get_nodes_in_group("chefes")
	if not chefes.is_empty():
		return (chefes[0] as Node2D).global_position.x
	return k.global_position.x + 4000.0


func _procurar(n: Node, nome: String) -> Node2D:
	if n == null:
		return null
	for f in n.get_children():
		if f.name == nome and f is Node2D:
			return f as Node2D
		var r := _procurar(f, nome)
		if r:
			return r
	return null
