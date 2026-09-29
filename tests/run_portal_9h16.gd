extends Node
## Regressão de morte pelo callback da espada, recompensa e portal L1→L2.
## Campanha sintética: exige diretório de utilizador isolado com «9h16».
## Ghorak começa com 1 HP para isolar o golpe fatal; não prova a luta inteira.

var falhas := 0
var entradas := 0
var indice_callback := -1
var motes := 0
var recompensa := 0
var contar_motes := false
var acertos := 0
var porta: Porta

func _ready() -> void:
	provar.call_deferred()

func verificar(ok: bool, mensagem: String) -> void:
	if not ok:
		falhas += 1
		push_error("9H16 PORTAL: " + mensagem)

func quadros(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func mote_adicionado(no: Node) -> void:
	if contar_motes and no is Essencia:
		motes += 1
		recompensa += no.valor

func entrada(corpo: Node) -> void:
	entradas += 1
	indice_callback = EstadoJogo.indice_nivel
	# Reentrada hostil dentro do callback: não pode duplicar conclusão.
	porta._ao_entrar(corpo)
	porta._ao_entrar(corpo)

func provar() -> void:
	if not "9h16" in OS.get_user_data_dir().to_lower():
		push_error("9H16 PORTAL: recusa escrever num user dir não isolado")
		get_tree().quit(2)
		return
	print("9H16 PORTAL USER ", OS.get_user_data_dir())
	get_tree().node_added.connect(mote_adicionado)
	var casos := [0, 1, 2, 3]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--caso="):
			casos = [int(arg.get_slice("=", 1))]
	for caso in casos:
		await travessia(caso)
	print("9H16 PORTAL FINAL falhas=", falhas)
	get_tree().quit(0 if falhas == 0 else 1)

func travessia(caso: int) -> void:
	EstadoJogo.reiniciar_campanha()
	entradas = 0
	indice_callback = -1
	motes = 0
	recompensa = 0
	acertos = 0
	var main = load("res://scenes/Main.tscn").instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await quadros(40)
	var k: Koliani = get_tree().get_first_node_in_group("koliani")
	var g = main.find_child("Guardiao", true, false)
	porta = main.find_child("Porta", true, false)
	verificar(k != null and g != null and porta != null, "L1 sem jogador/guardião/porta")
	if k == null or g == null or porta == null:
		return
	verificar(not porta.monitoring, "porta abriu antes da derrota")
	g.vida = 1
	g.vida_mudou.connect(func(v: int, _maximo: int) -> void:
		if v <= 0:
			acertos += 1)
	# Setup anterior à prova. Daqui até à saída não há teleportes, remoção
	# do guardião nem chamada direta ao dano: ataque e travessia por input.
	k.global_position = g.global_position + Vector2(-55, 0)
	k.velocity = Vector2.ZERO
	k.reset_physics_interpolation()
	k._invulneravel = 1.0
	contar_motes = true
	Input.action_press("atacar")
	await quadros(10)
	Input.action_release("atacar")
	await quadros(3)
	contar_motes = false
	verificar(acertos == 1 and not is_instance_valid(g), "golpe fatal não derrotou Ghorak uma vez")
	verificar(motes == 7 and recompensa == 70, "recompensa perdeu/duplicou motes: %d/%d" % [motes, recompensa])
	verificar(porta.monitoring, "porta não abriu após a morte real")
	porta.body_entered.connect(entrada)
	# Normal/novo processo: andamento reduzido. Corrida: velocidade completa.
	# Caso 3 atravessa com efeitos de morte/recolha ainda ativos.
	if caso != 3:
		await quadros(80)
	if caso == 2:
		# Kit só da campanha sintética para exercitar o dash aéreo no trigger.
		EstadoJogo.habilidades.append_array(["dash", "dash_aereo"])
	Input.action_press("mover_direita", 0.45 if caso in [0, 4] else 1.0)
	var salto := false
	var dash := false
	var dash_executado := false
	for i in 500:
		await get_tree().physics_frame
		if is_instance_valid(k) and k._dash_restante > 0:
			dash_executado = true
		if EstadoJogo.indice_nivel == 1:
			break
		if caso == 2 and not salto and k.global_position.x > porta.global_position.x - 110:
			Input.action_press("saltar")
			salto = true
		elif salto:
			Input.action_release("saltar")
			if not dash:
				Input.action_press("dash")
				dash = true
			else:
				Input.action_release("dash")
	for acao in ["mover_direita", "saltar", "dash", "atacar"]:
		Input.action_release(acao)
	await quadros(120)
	verificar(entradas == 1 and indice_callback == 0, "reentrada/avanço durante callback")
	if caso == 2:
		verificar(dash_executado, "input dash não chegou a executar")
	verificar(EstadoJogo.indice_nivel == 1 and 0 in EstadoJogo.concluidos, "L2 não carregou")
	verificar(EstadoJogo.vidas == EstadoJogo.VIDAS_INICIAIS + 1, "recompensa de vida duplicada")
	var novo: Koliani = get_tree().get_first_node_in_group("koliani")
	verificar(novo != null and novo != k, "spawn L2 ausente ou jogador antigo")
	if novo:
		verificar(novo.vida > 0 and not novo._a_morrer and novo.is_on_floor(), "spawn L2 morto/sem chão")
	verificar(EstadoJogo.level_session.get("level_id") == "level_002", "sessão L2 inválida")
	var save = JSON.parse_string(FileAccess.get_file_as_string(EstadoJogo.CAMINHO_SAVE))
	verificar(save != null and save.get("current_level_id") == "level_002", "save perdeu destino")
	verificar(EstadoJogo.carregar() and EstadoJogo.indice_nivel == 1, "retoma perdeu destino")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("C:/Temp/koliani-9h16-caso%d.png" % caso)
	print("9H16 PORTAL caso=%d entradas=%d motes=%d recompensa=%d salto=%s dash_executado=%s falhas=%d" % [
		caso, entradas, motes, recompensa, salto, dash_executado, falhas])
	get_tree().current_scene.queue_free()
	get_tree().current_scene = null
	await quadros(5)
