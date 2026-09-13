extends SceneTree
## 9H.16 D -- prova MEDIDA e DETERMINISTA da cadeia de espada.
##
## Nao se conduz o combo pelo teclado: os intervalos do arnes passavam a
## `JANELA_COMBO` (0,42 s) e a cadeia reiniciava a meio, pelo que cada
## corrida media passos diferentes. Aqui fixa-se `_combo_passo` e chama-se
## o acerto -- e' o mapeamento passo -> dano/recuo/estado que esta' em causa.
##
## Armadilha conhecida: NAO nomear classes do jogo (RaizPerigo, DemonioBase)
## neste ficheiro -- em `--script` isso arrasta os autoloads e o bench deixa
## de compilar em silencio.


func _init() -> void:
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	if DisplayServer.get_screen_count() > 1:
		root.position = DisplayServer.screen_get_position(1) + Vector2i(60, 60)
	await process_frame
	var estado := root.get_node("EstadoJogo")
	estado.indice_nivel = 0
	estado.checkpoint = Vector2.ZERO
	change_scene_to_file("res://scenes/Main.tscn")
	await create_timer(2.6).timeout

	var k := get_first_node_in_group("koliani") as CharacterBody2D
	assert(k != null, "L1 nao abriu")
	var alvo: CharacterBody2D = null
	for no in get_nodes_in_group("inimigos"):
		if no is CharacterBody2D and not no.is_in_group("chefes"):
			alvo = no
			break
	assert(alvo != null, "sem inimigo no L1")
	alvo.set("resistencia_recuo", 1.0)  # medir o padrao, nao o elite
	print("BASE dano_ataque=", estado.dano_ataque())

	# --- 1) cada passo do combo: dano, recuo e estado deixado ---
	var danos: Array[int] = []
	var recuos: Array[float] = []
	for passo in range(4):
		alvo.set("vida", 100000)
		alvo.set("_atordoado", 0.0)
		alvo.set("_sangrando", 0.0)
		alvo.set("_recuo_vel", 0.0)
		alvo.set("_recuo_t", 0.0)
		alvo.global_position = k.global_position + Vector2(0.0, -520.0)  # no ar: sem paredes
		alvo.set("velocity", Vector2.ZERO)
		await process_frame
		var v0: int = alvo.get("vida")
		k.set("_combo_passo", passo)
		k.set("_pos_roll_t", 0.0)
		var atingidos: Dictionary = k.get("_alvos_atingidos_ataque")
		atingidos.clear()
		k.call("_ao_acertar_corpo", alvo)
		await process_frame
		var dano: int = v0 - int(alvo.get("vida"))
		var rv: float = absf(float(alvo.get("_recuo_vel")))
		danos.append(dano)
		recuos.append(rv)
		print("PASSO%d dano=%d recuo_vel=%.0f atordoado=%.2f sangra=%.2f"
			% [passo + 1, dano, rv, float(alvo.get("_atordoado")), float(alvo.get("_sangrando"))])

	# As asserçoes TEM de morder: se a espada nao ligar, isto falha.
	assert(danos[0] > 0, "o golpe 1 nao fez dano -- a medicao nao vale nada")
	assert(danos[3] > danos[0] * 1.6, "o remate nao paga: %d vs %d" % [danos[3], danos[0]])
	assert(recuos[3] > recuos[0] * 3.0, "o remate nao empurra mais: %.0f vs %.0f" % [recuos[3], recuos[0]])

	# --- 2) a raiz da floresta tambem espeta INIMIGOS (D5) ---
	var raiz: Node2D = null
	for no in _todos(current_scene):
		if no is Area2D and no.has_method("avisar") and bool(no.get("auto")):
			raiz = no
			break
	if raiz == null:
		print("RAIZ_INIMIGO=SEM_RAIZ_AUTO")
	else:
		alvo.set("vida", 100000)
		var v1: int = alvo.get("vida")
		var tocou := false
		for _f in range(900):
			alvo.global_position = raiz.global_position + Vector2(0.0, -26.0)
			alvo.set("velocity", Vector2.ZERO)
			await process_frame
			if int(alvo.get("vida")) < v1:
				tocou = true
				break
		print("RAIZ_INIMIGO=", tocou, " dano=", v1 - int(alvo.get("vida")))
		assert(tocou, "a raiz nao espetou o inimigo -- a mecanica do L1 nao liga ao combate")
	quit()


func _todos(n: Node) -> Array[Node]:
	var fora: Array[Node] = [n]
	for f in n.get_children():
		fora.append_array(_todos(f))
	return fora
