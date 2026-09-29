extends Node
## QA estrutural/funcional da Região I (N1-N5). Corre como cena (autoloads
## vivos). ESCREVE no save: correr por `tools/correr_qa_regiao1.ps1`, que
## isola o `user://`.

var falhas: Array[String] = []
var _boss_derrotado := false


func _check(cond: bool, msg: String) -> void:
	if not cond:
		falhas.append(msg)
		print("FALHOU: ", msg)


func _ready() -> void:
	_estatico()
	await _niveis()
	await _boss()
	_progressao_e_save()
	print("QA REGIAO I: %s (%d falhas)" % ["PASS" if falhas.is_empty() else "FAIL", falhas.size()])
	get_tree().quit(0 if falhas.is_empty() else 1)


func _deps_em_falta(caminho: String) -> Array:
	var em_falta := []
	for d in ResourceLoader.get_dependencies(caminho):
		var p: String = d.get_slice("::", 2) if "::" in d else d
		if p.begins_with("res://") and not ResourceLoader.exists(p):
			em_falta.append(p)
	return em_falta


func _estatico() -> void:
	var regiao: Dictionary = EstadoJogo.REGIOES[0]
	_check(regiao["niveis"] == [0, 1, 2, 3, 4], "Região I = N1-N5")
	for i in 5:
		var c: String = EstadoJogo.NIVEIS[i]
		_check(ResourceLoader.exists(c), "N%d cena existe: %s" % [i + 1, c])
		var f := _deps_em_falta(c)
		_check(f.is_empty(), "N%d dependências em falta: %s" % [i + 1, str(f)])
		var fn: String = Musica.faixa_de_nivel(i)
		var fc: String = Musica.faixa_de_chefe(i)
		_check(ResourceLoader.exists(fn), "N%d música de nível em falta: %s" % [i + 1, fn])
		_check(ResourceLoader.exists(fc), "N%d música de chefe em falta: %s" % [i + 1, fc])
		print("QA| N%d %s | musica=%s | boss=%s" % [i + 1, c.get_file(), fn.get_file(), fc.get_file()])
	for s in ["region_01_midnight_forest.mp3", "boss_01_gothic_candlelight.mp3"]:
		_check(ResourceLoader.exists("res://assets/audio/approved/" + s), "áudio aprovado em falta: " + s)
	_check(EstadoJogo.nivel_e_exame_regional(4) and not EstadoJogo.nivel_e_exame_regional(3),
		"só o N5 é exame regional")


func _porta_de(raiz: Node) -> Area2D:
	for n in raiz.find_children("*", "Area2D", true, false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("porta.gd"):
			return n
	return null


func _niveis() -> void:
	for i in 5:
		EstadoJogo.indice_nivel = i
		EstadoJogo.iniciar_sessao_nivel(true)
		var raiz: Node = (load(EstadoJogo.NIVEIS[i]) as PackedScene).instantiate()
		add_child(raiz)
		for _f in 14:
			await get_tree().process_frame
		var kol := get_tree().get_first_node_in_group("koliani")
		var cps := get_tree().get_nodes_in_group("checkpoints")
		var chefes := get_tree().get_nodes_in_group("chefes")
		var inim := get_tree().get_nodes_in_group("inimigos").size()
		_check(kol != null, "N%d sem Koliani" % [i + 1])
		_check(cps.size() >= 3, "N%d checkpoints=%d (<3)" % [i + 1, cps.size()])
		_check(chefes.size() >= 1, "N%d sem chefe" % [i + 1])
		_check(_porta_de(raiz) != null, "N%d sem Porta" % [i + 1])
		var ids := []
		for cp in cps:
			ids.append(cp.checkpoint_id)
		_check(not ("" in ids), "N%d checkpoint sem id %s" % [i + 1, str(ids)])
		print("QA| N%d instanciado: koliani=%s checkpoints=%d chefes=%d inimigos=%d" % [
			i + 1, kol != null, cps.size(), chefes.size(), inim])
		# checkpoint + respawn no último checkpoint
		if kol and cps.size() > 0:
			var alvo: Node2D = cps[0]
			for cp in cps:
				if cp.global_position.x > alvo.global_position.x:
					alvo = cp
			alvo._ao_entrar(kol)
			_check(EstadoJogo.checkpoint_id_session() == alvo.checkpoint_id,
				"N%d checkpoint não ficou ativo" % [i + 1])
			kol.global_position = alvo.global_position + Vector2(-600, -300)
			kol.recuperar_no_checkpoint(EstadoJogo.ponto_recuperacao())
			_check(kol.global_position.distance_to(alvo.global_position) < 80.0,
				"N%d respawn longe do checkpoint" % [i + 1])
		raiz.queue_free()
		for _f in 4:
			await get_tree().process_frame


func _progressao_e_save() -> void:
	EstadoJogo.concluidos.clear()
	EstadoJogo.indice_nivel = 0
	for i in 5:
		_check(EstadoJogo.nivel_desbloqueado(i), "N%d devia estar desbloqueado" % [i + 1])
		_check(i == 4 or not EstadoJogo.regiao_esta_concluida(0), "região concluída cedo")
		EstadoJogo.avancar_nivel()
		_check(EstadoJogo.nivel_esta_concluido(i), "N%d não ficou concluído" % [i + 1])
		_check(EstadoJogo.indice_nivel == i + 1,
			"avançar do N%d foi para %d" % [i + 1, EstadoJogo.indice_nivel])
	_check(EstadoJogo.regiao_esta_concluida(0), "concluir N5 não conclui a Região I")
	_check(EstadoJogo.nivel_desbloqueado(5) and not EstadoJogo.regiao_esta_concluida(1),
		"N6 devia abrir sem fechar a Região II")
	var d: Dictionary = EstadoJogo.para_dicionario()
	EstadoJogo.concluidos.clear()
	EstadoJogo.indice_nivel = 0
	EstadoJogo.de_dicionario(d)
	_check(EstadoJogo.regiao_esta_concluida(0) and EstadoJogo.indice_nivel == 5,
		"save/load (dicionário) perdeu a progressão (idx=%d)" % EstadoJogo.indice_nivel)
	EstadoJogo.guardar()
	EstadoJogo.concluidos.clear()
	EstadoJogo.indice_nivel = 0
	_check(EstadoJogo.carregar() and EstadoJogo.regiao_esta_concluida(0),
		"carregar do disco perdeu a Região I")
	var sel: SeletorNiveis = load("res://scenes/ui/SeletorNiveis.tscn").instantiate()
	sel.size = Vector2(1280, 720)
	add_child(sel)
	sel.configurar(0, true)
	_check(sel.get("_region_cards").size() == 20, "selector sem 20 regiões")
	sel.queue_free()


func _boss() -> void:
	EstadoJogo.indice_nivel = 4
	EstadoJogo.iniciar_sessao_nivel(true)
	var raiz: Node = (load(EstadoJogo.NIVEIS[4]) as PackedScene).instantiate()
	add_child(raiz)
	for _f in 6:
		await get_tree().process_frame
	var chefe := get_tree().get_first_node_in_group("chefes")
	_check(chefe != null, "N5 sem chefe")
	if chefe:
		chefe.derrotado.connect(func() -> void: _boss_derrotado = true)
		for _k in 60:
			if _boss_derrotado or not is_instance_valid(chefe):
				break
			chefe.receber_dano(9999, 1.0, true)
			await get_tree().create_timer(0.2).timeout
		_check(_boss_derrotado, "chefe do N5 não emitiu `derrotado` após dano massivo")
		for _f in 20:
			await get_tree().process_frame
		var porta := _porta_de(raiz)
		var bau := raiz.get_node_or_null("BauChefe")
		_check(bau != null, "N5: o baú do chefe não apareceu")
		_check(porta != null and not porta.monitoring,
			"N5: a porta devia ficar selada até o baú ser recolhido")
		if bau:
			bau.recolhido.emit()
			await get_tree().process_frame
			_check(porta.monitoring, "N5: a porta não abriu ao recolher o baú")
		_check(EstadoJogo.chefe_derrotado_por_nivel(4), "N5: chefe não ficou registado como derrotado")
	raiz.queue_free()
