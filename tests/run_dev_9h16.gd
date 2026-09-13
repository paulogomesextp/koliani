extends SceneTree
## Prova de isolamento em memória e das três rotas de save no sandbox.

func _initialize() -> void:
	provar.call_deferred()

func provar() -> void:
	var e = load("res://scripts/estado_jogo.gd").new()
	e.modo_teste = true
	root.add_child(e)
	var base := "user://prova_dev_9h16.json"
	e.indice_nivel = 2
	e.essencia = 42
	e.checkpoint = Vector2(120, 90)
	var normal: Dictionary = e.para_dicionario().duplicate(true)
	assert(e.guardar_em(base, base + ".bak", base + ".tmp"))
	var bytes := FileAccess.get_file_as_bytes(base)
	e.ativar_modo_dev()
	assert(e.modo_dev and e.habilidades.size() == e.HABILIDADES_TODAS.size())
	assert(e.armas.size() == Equipamento.ARMAS.size())
	assert(e.armaduras.size() == Equipamento.ARMADURAS.size())
	for id in Melhorias.CATALOGO:
		assert(e.rank_melhoria(id) == Melhorias.max_rank(id))
	for i in [0, 19, 49, 99]:
		e.indice_nivel = i
		e.iniciar_sessao_nivel(true)
		e.ganhar_essencia(99)
		e.marcar_nivel_concluido(i)
		e.marcar_chefe_derrotado_por_nivel(i)
		e.equipar_arma(Equipamento.ARMAS[0]["id"])
		assert(not e.guardar())
		assert(not e.guardar_em(base, base + ".bak", base + ".tmp"))
		assert(FileAccess.get_file_as_bytes(base) == bytes)
	# Ativação repetida não pode substituir o snapshot legítimo.
	e.ativar_modo_dev()
	e.desativar_modo_dev()
	assert(not e.modo_dev and e.para_dicionario() == normal)
	assert(not e.nivel_desbloqueado(19) and not e.nivel_desbloqueado(49)
		and not e.nivel_desbloqueado(99))
	assert(e.checkpoint == Vector2(120, 90))
	assert(FileAccess.get_file_as_bytes(base) == bytes)
	var outro = load("res://scripts/estado_jogo.gd").new()
	outro.modo_teste = true
	root.add_child(outro)
	assert(outro.carregar_de(base, base + ".bak"))
	assert(outro.para_dicionario() == normal and not outro.modo_dev)
	for caminho in [base, base + ".bak", base + ".tmp"]:
		if FileAccess.file_exists(caminho):
			DirAccess.remove_absolute(caminho)
	print("9H16 DEV ISOLAMENTO: PASS; L1/L20/L50/L100; snapshot e bytes intactos")
	e.free()
	outro.free()
	await process_frame
	quit(0)
