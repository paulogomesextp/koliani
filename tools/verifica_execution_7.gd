extends SceneTree
## Gate técnico dirigido da Execution 7. Carrega apenas a Região I, verifica
## topologia, progressão permitida, inimigos/checkpoints e chama o crivo de
## alcance existente. Não substitui playtest humano nem validação de device.

const CRIVO := preload("res://tools/verifica_alcance.gd")
const LEVELS := [
	"res://scenes/levels/Floresta_Putrefata.tscn",
	"res://scenes/levels/Pantano_dos_Sussurros.tscn",
	"res://scenes/levels/Ninho_da_Viuva_Negra.tscn",
	"res://scenes/levels/A_Arvore_que_Chora.tscn",
	"res://scenes/levels/Coracao_da_Floresta.tscn",
]

var _falhas: Array[String] = []


func _init() -> void:
	call_deferred("_correr")


func _ok(condicao: bool, mensagem: String) -> void:
	if not condicao:
		_falhas.append(mensagem)


func _correr() -> void:
	await process_frame
	var estado := root.get_node_or_null("EstadoJogo")
	var bosses_antes: Array[String] = []
	var recompensas_antes: Array[String] = []
	if estado:
		# O gate tem de medir o estado inicial do nível, independentemente do save
		# local do jogador. Restauramos a memória antes de terminar e não gravamos.
		bosses_antes.assign(estado.bosses_derrotados)
		recompensas_antes.assign(estado.recompensas_reclamadas)
		estado.bosses_derrotados.erase("boss_level_005")
		estado.recompensas_reclamadas.erase("reward_boss_chest_level_005")
		estado.modo_teste = true
	for i in LEVELS.size():
		await _verificar_nivel(i)
	if estado:
		estado.bosses_derrotados.assign(bosses_antes)
		estado.recompensas_reclamadas.assign(recompensas_antes)
		estado.modo_teste = false
	if _falhas.is_empty():
		print("EXECUTION 7 TARGETED: PASS -- combate/progressao, inimigos, L1-L5 e boss")
		quit(0)
	else:
		for falha in _falhas:
			printerr("EXECUTION 7 FALHOU: ", falha)
		quit(1)


func _verificar_nivel(indice: int) -> void:
	var caminho: String = LEVELS[indice]
	var cena: PackedScene = load(caminho)
	_ok(cena != null, "L%d sem cena carregável" % (indice + 1))
	if cena == null:
		return
	var estado := root.get_node_or_null("EstadoJogo")
	if estado:
		estado.indice_nivel = indice
		estado.checkpoint = Vector2.ZERO
	var nivel := cena.instantiate()
	# O gate mede a sala autoral. A jornada procedural tem verificador próprio.
	if "corredor" in nivel:
		nivel.corredor = false
	if "alongar_plataformas" in nivel:
		nivel.alongar_plataformas = false
	root.add_child(nivel)
	for _frame in 8:
		await process_frame

	var koliani := _descendente_grupo(nivel, "koliani")
	var porta := nivel.get_node_or_null("Porta")
	_ok(koliani != null, "L%d sem Koliani" % (indice + 1))
	_ok(porta != null, "L%d sem saída" % (indice + 1))
	if indice < 4:
		var guardiao := nivel.get_node_or_null("Guardiao")
		_ok(guardiao != null
			and nivel.get_node_or_null("Chefe") == null,
			"L%d devia terminar em Guardiao" % (indice + 1))
		if guardiao and porta:
			_ok(not porta.monitoring, "L%d devia iniciar com saída selada" % (indice + 1))
			guardiao.queue_free()
			for _frame in 3:
				await process_frame
			_ok(porta.monitoring, "L%d guardião não libertou a saída" % (indice + 1))
			_ok(nivel.get_node_or_null("BauChefe") == null,
				"L%d guardião criou recompensa de boss regional" % (indice + 1))
	else:
		var boss := nivel.get_node_or_null("Chefe")
		var script_boss: Script = boss.get_script() if boss else null
		_ok(script_boss != null and script_boss.resource_path.ends_with("chefe_coracao_putrefacto.gd"),
			"L5 devia usar o Coração Putrefacto canónico")
		_ok(boss != null and boss.has_signal("derrotado"),
			"boss regional sem contrato de derrota")

	var checkpoints := _descendentes_grupo(nivel, "checkpoints")
	_ok(not checkpoints.is_empty(), "L%d sem checkpoints" % (indice + 1))
	var ids := {}
	for checkpoint in checkpoints:
		var id := str(checkpoint.get("checkpoint_id"))
		_ok(id.begins_with("checkpoint_level_%03d_" % (indice + 1)),
			"L%d checkpoint sem stable ID: %s" % [indice + 1, id])
		_ok(not ids.has(id), "L%d checkpoint duplicado: %s" % [indice + 1, id])
		ids[id] = true

	var inimigos := _descendentes_grupo(nivel, "inimigos")
	_ok(not inimigos.is_empty(), "L%d sem encontro inimigo/guardião" % (indice + 1))
	for inimigo in inimigos:
		if inimigo == nivel.get_node_or_null("Guardiao") or inimigo == nivel.get_node_or_null("Chefe"):
			continue
		_ok(inimigo.has_method("receber_dano"),
			"L%d inimigo sem contrato de dano" % (indice + 1))
		_ok(int(inimigo.get("vida")) > 0 and int(inimigo.get("dano_contacto")) > 0,
			"L%d inimigo com vida/dano inválidos" % (indice + 1))
		if koliani is Node2D and inimigo is Node2D:
			_ok((inimigo as Node2D).global_position.distance_to(koliani.global_position) >= 120.0,
				"L%d inimigo demasiado perto do spawn" % (indice + 1))
		for checkpoint in checkpoints:
			if inimigo is Node2D and checkpoint is Node2D:
				_ok((inimigo as Node2D).global_position.distance_to(checkpoint.global_position) >= 96.0,
					"L%d inimigo ameaça checkpoint sem margem" % (indice + 1))

	nivel.queue_free()
	await process_frame
	var alcance: Dictionary = await CRIVO.medir(self, caminho, indice)
	_ok(not alcance.has("erro"), "L%d alcance sem medição: %s" % [indice + 1, alcance.get("erro", "")])
	_ok(bool(alcance.get("ok_porta", false)), "L%d porta inalcançável no crivo" % (indice + 1))


func _descendente_grupo(raiz: Node, grupo: String) -> Node:
	for no in get_nodes_in_group(grupo):
		if raiz.is_ancestor_of(no):
			return no
	return null


func _descendentes_grupo(raiz: Node, grupo: String) -> Array[Node]:
	var resultado: Array[Node] = []
	for no in get_nodes_in_group(grupo):
		if raiz.is_ancestor_of(no):
			resultado.append(no)
	return resultado
