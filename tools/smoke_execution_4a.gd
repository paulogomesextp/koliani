extends Node
## Smoke dirigido da Execution 4A. Não altera níveis nem pretende provar feel.

const AMOSTRAS := [
	{"indice": 0, "id": "L1"},
	{"indice": 4, "id": "L5"},
	{"indice": 11, "id": "L12"},
	{"indice": 30, "id": "L31"},
]

var _falhas: Array[String] = []


func _ready() -> void:
	call_deferred("_correr")


func _correr() -> void:
	var estado := get_node_or_null("/root/EstadoJogo")
	if estado == null:
		_falhar("EstadoJogo ausente")
		_terminar()
		return
	estado.modo_teste = true
	estado.modo_dev = true
	estado.vidas = 999
	var filtro := _filtro_niveis()
	for amostra in AMOSTRAS:
		if not filtro.is_empty() and not filtro.has(amostra["id"]):
			continue
		estado.indice_nivel = amostra["indice"]
		estado.iniciar_sessao_nivel(true)
		if estado.has_method("_limpar_jornada_ancora"):
			estado._limpar_jornada_ancora()
		var caminho: String = estado.NIVEIS[amostra["indice"]]
		var packed := load(caminho) as PackedScene
		if packed == null:
			_falhar("%s não carregou: %s" % [amostra["id"], caminho])
			continue
		var cena := packed.instantiate()
		add_child(cena)
		for _i in 24:
			await get_tree().physics_frame
		var k := _koliani_de(cena)
		if k == null:
			_falhar("%s sem spawn da Koliani" % amostra["id"])
		else:
			_validar_level_session(cena, estado, amostra["id"])
			_validar_camera(k, amostra["id"])
			if amostra["indice"] == 0:
				await _validar_movimento_integrado(k)
		print("SMOKE %s: %s" % [amostra["id"], caminho])
		cena.queue_free()
		await get_tree().process_frame
	estado.modo_teste = false
	_terminar()


func _filtro_niveis() -> Array[String]:
	var resultado: Array[String] = []
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--nivel="):
			resultado.append(argumento.trim_prefix("--nivel=").to_upper())
	return resultado


func _koliani_de(cena: Node) -> CharacterBody2D:
	for no in get_tree().get_nodes_in_group("koliani"):
		if no is CharacterBody2D and cena.is_ancestor_of(no):
			return no
	return null


func _validar_camera(k: CharacterBody2D, id: String) -> void:
	var cam := k.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		_falhar("%s sem Camera2D" % id)
		return
	for valor in [cam.offset.x, cam.offset.y, cam.zoom.x, cam.zoom.y]:
		if is_nan(valor) or is_inf(valor):
			_falhar("%s: câmara gerou valor inválido" % id)
			return


func _validar_level_session(cena: Node, estado: Node, id: String) -> void:
	if not estado.level_session.get("active", false):
		_falhar("%s sem level session ativa" % id)
		return
	var vistos: Array[String] = []
	for no in get_tree().get_nodes_in_group("checkpoints"):
		if not (no is Node2D) or not cena.is_ancestor_of(no) \
				or no.is_queued_for_deletion():
			continue
		var checkpoint_id := str(no.get("checkpoint_id"))
		if checkpoint_id == "" or checkpoint_id in vistos:
			_falhar("%s tem checkpoint sem stable ID único" % id)
		vistos.append(checkpoint_id)


func _validar_movimento_integrado(k: CharacterBody2D) -> void:
	var spawn := k.global_position
	var x0 := k.global_position.x
	Input.action_press("mover_direita")
	for _i in 30:
		await get_tree().physics_frame
	Input.action_release("mover_direita")
	print("L1 RUN: dx=%.1f pos=%s chão=%s vel=%s" % [
		k.global_position.x - x0, k.global_position, k.is_on_floor(), k.velocity])
	if k.global_position.x - x0 < 40.0:
		_falhar("L1: corrida integrada não avançou 40 px")

	k.global_position = spawn
	k.velocity = Vector2.ZERO
	k.call("_desencravar")
	for _i in 8:
		await get_tree().physics_frame
	var y0 := k.global_position.y
	var y_min := y0
	Input.action_press("saltar")
	for _i in 8:
		await get_tree().physics_frame
		y_min = minf(y_min, k.global_position.y)
	Input.action_release("saltar")
	for _i in 28:
		await get_tree().physics_frame
		y_min = minf(y_min, k.global_position.y)
	print("L1 JUMP: ganho=%.1f y0=%.1f ymin=%.1f chão=%s vel=%s" % [
		y0 - y_min, y0, y_min, k.is_on_floor(), k.velocity])
	if y0 - y_min < 18.0:
		_falhar("L1: salto integrado não ganhou 18 px")

	k.global_position = spawn
	k.velocity = Vector2.ZERO
	k.call("_desencravar")
	for _i in 8:
		await get_tree().physics_frame
	var dash_x := k.global_position.x
	Input.action_press("dash")
	await get_tree().physics_frame
	Input.action_release("dash")
	for _i in 10:
		await get_tree().physics_frame
	print("L1 DASH: dx=%.1f chão=%s vel=%s" % [
		k.global_position.x - dash_x, k.is_on_floor(), k.velocity])
	if absf(k.global_position.x - dash_x) < 55.0:
		_falhar("L1: dash deixou de percorrer 55 px")


func _falhar(mensagem: String) -> void:
	_falhas.append(mensagem)
	printerr("FALHOU: ", mensagem)


func _terminar() -> void:
	if _falhas.is_empty():
		print("SMOKE EXECUTION 4A: PASS")
		get_tree().quit(0)
	else:
		printerr("SMOKE EXECUTION 4A: %d falha(s)" % _falhas.size())
		get_tree().quit(1)
