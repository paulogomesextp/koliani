extends Node
## Valida todos os checkpoints pelo contrato real (grupo "checkpoints").
##
## No nível 5, além da geometria em vários instantes, executa o percurso
## checkpoint ativado -> morte -> reload -> física estabilizada -> andar e
## saltar. Isto inclui os checkpoints autorais CheckInicio/CheckMeio/
## CheckReencontro, sem depender do nome.
##
## Uso:
## Godot --headless --script res://tools/verifica_spawn_livre.gd

const INDICE_NIVEL := 4
const ALTURA_SPAWN := 40.0
const SAIDA_MINIMA := 64.0
const PE_DIREITO_MINIMO := 96.0
const QUEDA_MAX_CHAO := 150.0
const FPS := 60

var _falhas := 0
var _estado: Node


func _init() -> void:
	call_deferred("_correr")


func _correr() -> void:
	await get_tree().process_frame
	_estado = get_tree().root.get_node_or_null("/root/EstadoJogo")
	if _estado == null:
		print("SEM EstadoJogo")
		get_tree().quit(1)
		return
	_estado.modo_teste = true
	_estado.indice_nivel = INDICE_NIVEL
	_estado.checkpoint = Vector2.ZERO
	_estado.vidas = 999
	if _estado.has_method("_limpar_jornada_ancora"):
		_estado._limpar_jornada_ancora()

	var cena := await _carregar_nivel()
	if cena == null:
		get_tree().quit(1)
		return
	var declarados := _checks_da_cena(cena)
	var nomes_declarados: Array[String] = []
	for ck in declarados:
		nomes_declarados.append(String(ck.name))
	print("DECLARADOS PELO CONTRATO: %s" %
		[", ".join(nomes_declarados)])
	for _i in 24:
		await get_tree().process_frame
	var checks := _checks_da_cena(cena)
	print("ATIVOS APOS REDUCAO: %d checkpoints: %s" % [
		checks.size(), ", ".join(checks.map(func(c): return str(c.name)))])
	for nome in ["CheckInicio", "CheckMeio", "CheckReencontro"]:
		if not nomes_declarados.has(nome):
			_falhar("%s autoral nao foi enumerado semanticamente" % nome)
	if checks.is_empty():
		_falhar("nenhum checkpoint encontrado pelo grupo")
	else:
		var ids: Array[String] = []
		for i in checks.size():
			var id := str(checks[i].get("checkpoint_id"))
			var esperado := "checkpoint_level_005_%02d" % (i + 1)
			if id != esperado:
				_falhar("checkpoint %d sem stable ID esperado: %s" % [i + 1, id])
			if id in ids:
				_falhar("stable checkpoint ID duplicado: %s" % id)
			ids.append(id)
		await _validar_ciclo_temporal(cena, checks)

	var descritores: Array[Dictionary] = []
	for ck in checks:
		descritores.append({
			"nome": String(ck.name),
			"id": str(ck.get("checkpoint_id")),
			"pos": ck.global_position,
		})
	for desc in descritores:
		cena = get_tree().current_scene
		var ck := _encontrar_check(cena, desc)
		if ck == null:
			_falhar("%s desapareceu antes da simulacao" % desc["nome"])
			continue
		cena = await _morte_e_respawn(cena, ck)
		if cena == null:
			break

	print("\n=== SPAWN NIVEL 5: %s ===" %
		("TUDO OK" if _falhas == 0 else "%d FALHA(S)" % _falhas))
	_estado.modo_teste = false
	get_tree().quit(1 if _falhas else 0)


func _carregar_nivel() -> Node:
	var packed := load(_estado.NIVEIS[INDICE_NIVEL]) as PackedScene
	if packed == null:
		_falhar("cena do nivel 5 nao carregou")
		return null
	var cena := packed.instantiate()
	get_tree().root.add_child(cena)
	get_tree().current_scene = cena
	await get_tree().process_frame
	return cena


func _checks_da_cena(cena: Node) -> Array[Node2D]:
	var checks: Array[Node2D] = []
	for n in get_tree().get_nodes_in_group("checkpoints"):
		if n is Node2D and cena.is_ancestor_of(n) and not n.is_queued_for_deletion():
			checks.append(n)
	checks.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	return checks


func _encontrar_check(cena: Node, desc: Dictionary) -> Node2D:
	for ck in _checks_da_cena(cena):
		if str(ck.get("checkpoint_id")) == str(desc["id"]):
			return ck
	return null


func _duracao_temporal(cena: Node) -> float:
	var ciclo := 0.0
	for n in get_tree().get_nodes_in_group("plataformas_flutuantes"):
		if cena.is_ancestor_of(n):
			ciclo = maxf(ciclo, maxf(float(n.get("periodo")),
				float(n.get("periodo_deriva"))))
	for n in get_tree().get_nodes_in_group("plataformas_ritmadas"):
		if cena.is_ancestor_of(n):
			var solida := float(n.get("solida_seg"))
			var total := float(n.get("periodo"))
			if solida > 0.0:
				total = solida + float(n.get("fantasma_seg"))
			ciclo = maxf(ciclo, total)
	return maxf(ciclo, 0.25)


func _validar_ciclo_temporal(cena: Node, checks: Array[Node2D]) -> void:
	var k := get_tree().get_first_node_in_group("koliani") as CharacterBody2D
	if k == null:
		_falhar("nivel 5 sem Koliani")
		return
	var ciclo := _duracao_temporal(cena)
	var amostras := maxi(1, ceili(ciclo * FPS / 10.0))
	for amostra in amostras:
		for _frame in 10:
			await get_tree().physics_frame
		for ck in checks:
			_validar_instante(k, ck, amostra)
	print("CICLO TEMPORAL: %.2f s, %d amostras" % [ciclo, amostras])


func _validar_instante(k: CharacterBody2D, ck: Node2D, amostra: int) -> void:
	var pos := ck.global_position + Vector2(0.0, -ALTURA_SPAWN)
	var t := k.global_transform
	t.origin = pos
	if k.test_move(t, Vector2.ZERO):
		_falhar("%s amostra %d: spawn inicial sobrepoe geometria"
			% [ck.name, amostra])
	var chao := _chao_abaixo(k, pos)
	if chao.is_empty():
		_falhar("%s amostra %d: sem chao valido" % [ck.name, amostra])
	if _overlap_letal(k, pos):
		_falhar("%s amostra %d: overlap letal imediato" % [ck.name, amostra])
	var esq := _quanto_anda(k, pos, -1.0)
	var dir := _quanto_anda(k, pos, 1.0)
	var teto := _pe_direito(k, pos)
	if maxf(esq, dir) < SAIDA_MINIMA:
		_falhar("%s amostra %d: sem saida lateral (E %.0f, D %.0f)"
			% [ck.name, amostra, esq, dir])
	if teto < PE_DIREITO_MINIMO:
		_falhar("%s amostra %d: folga vertical %.0f px"
			% [ck.name, amostra, teto])


func _morte_e_respawn(cena: Node, ck: Node2D) -> Node:
	var nome := String(ck.name)
	var alvo := ck.global_position
	var k := get_tree().get_first_node_in_group("koliani") as CharacterBody2D
	if k == null:
		_falhar("%s: Koliani ausente antes da morte" % nome)
		return null
	ck.set("_ativo", false)
	ck.call("_ao_entrar", k)
	if not _estado.checkpoint.is_equal_approx(alvo):
		_falhar("%s: ativacao nao guardou o checkpoint" % nome)
		return cena
	var anterior := cena
	k.call("_morrer")
	for _i in 180:
		await get_tree().process_frame
		if get_tree().current_scene != null and get_tree().current_scene != anterior:
			break
	if get_tree().current_scene == null or get_tree().current_scene == anterior:
		_falhar("%s: morte nao recarregou a cena" % nome)
		return null
	for _i in 20:
		await get_tree().physics_frame
	k = get_tree().get_first_node_in_group("koliani") as CharacterBody2D
	if k == null:
		_falhar("%s: sem Koliani depois do respawn" % nome)
		return get_tree().current_scene
	var esperado := alvo + Vector2(0.0, -ALTURA_SPAWN)
	if k.global_position.distance_to(esperado) > 170.0:
		_falhar("%s: respawn afastou-se %.0f px do checkpoint"
			% [nome, k.global_position.distance_to(esperado)])
	var origem := k.global_position
	var andou := await _tentar_andar(k, 1.0)
	if andou < 32.0:
		k.global_position = origem
		k.velocity = Vector2.ZERO
		for _i in 3:
			await get_tree().physics_frame
		andou = await _tentar_andar(k, -1.0)
	if andou < 32.0:
		_falhar("%s: respawn nao permite movimento (%.0f px)" % [nome, andou])
	# Movimento e salto são contratos independentes do respawn. Regressar à
	# origem evita que a caminhada de prova termine por acaso sob um teto baixo.
	k.global_position = origem
	k.velocity = Vector2.ZERO
	k.call("_desencravar")
	for _i in 3:
		await get_tree().physics_frame
	var saltou := await _tentar_saltar(k)
	if saltou < 38.0:
		_falhar("%s: respawn nao permite salto (%.0f px)" % [nome, saltou])
	print("  %-28s respawn + saida %.0f px + salto %.0f px OK"
		% [nome, andou, saltou])
	return get_tree().current_scene


func _tentar_andar(k: CharacterBody2D, lado: float) -> float:
	var inicio := k.global_position
	var acao := "mover_direita" if lado > 0.0 else "mover_esquerda"
	Input.action_press(acao)
	for _i in 30:
		await get_tree().physics_frame
	Input.action_release(acao)
	return absf(k.global_position.x - inicio.x)


func _tentar_saltar(k: CharacterBody2D) -> float:
	for _i in 20:
		await get_tree().physics_frame
	var inicio := k.global_position.y
	var minimo := inicio
	Input.action_press("saltar")
	for _i in 12:
		await get_tree().physics_frame
		minimo = minf(minimo, k.global_position.y)
	Input.action_release("saltar")
	for _i in 45:
		await get_tree().physics_frame
		minimo = minf(minimo, k.global_position.y)
	return inicio - minimo


func _chao_abaixo(k: CharacterBody2D, pos: Vector2) -> Dictionary:
	var q := PhysicsRayQueryParameters2D.create(
		pos, pos + Vector2(0.0, QUEDA_MAX_CHAO), 1)
	q.collide_with_areas = false
	q.exclude = [k]
	return k.get_world_2d().direct_space_state.intersect_ray(q)


func _overlap_letal(k: CharacterBody2D, pos: Vector2) -> bool:
	var forma := RectangleShape2D.new()
	forma.size = Vector2(20.0, 44.0)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = forma
	q.transform = Transform2D(0.0, pos)
	q.collision_mask = 0xffffffff
	q.collide_with_areas = true
	q.collide_with_bodies = false
	for hit in k.get_world_2d().direct_space_state.intersect_shape(q, 32):
		var col: Object = hit.get("collider")
		if col is Armadilha and col.get("ativa"):
			return true
	return false


func _quanto_anda(k: CharacterBody2D, pos: Vector2, lado: float) -> float:
	var t := k.global_transform
	var d := 0.0
	while d < 200.0:
		t.origin = pos + Vector2(lado * (d + 8.0), 0.0)
		if k.test_move(t, Vector2.ZERO):
			return d
		d += 8.0
	return d


func _pe_direito(k: CharacterBody2D, pos: Vector2) -> float:
	var t := k.global_transform
	var d := 0.0
	while d < 160.0:
		t.origin = pos + Vector2(0.0, -(d + 8.0))
		if k.test_move(t, Vector2.ZERO):
			return d
		d += 8.0
	return d


func _falhar(msg: String) -> void:
	_falhas += 1
	printerr("FALHOU: ", msg)
