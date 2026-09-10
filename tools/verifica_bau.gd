extends SceneTree
const SAQUE := preload("res://scripts/saque_chefe.gd")
const IDS := preload("res://scripts/progression_ids.gd")
var falhas := 0

func _init() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var indice_nivel := int(args[0]) if not args.is_empty() else 11
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var tipos := {}
	for i in 1000:
		var r := SAQUE.sortear(99, [], [], {}, rng)
		tipos[r.tipo] = true
		var inicial := SAQUE.sortear(0, [], [], {}, rng)
		if inicial.tipo in ["arma", "armadura"]:
			falhas += 1
	_ok(tipos.size() == 4, "as quatro categorias podem sair")
	var armas: Array = []
	var armaduras: Array = []
	var melhorias := {}
	for a: Dictionary in SAQUE.EQUIP.ARMAS:
		armas.append(a.id)
	for a: Dictionary in SAQUE.EQUIP.ARMADURAS:
		armaduras.append(a.id)
	for id: String in SAQUE.MELH.ORDEM:
		melhorias[id] = SAQUE.MELH.max_rank(id)
	var esgotado := true
	for i in 200:
		esgotado = esgotado and SAQUE.sortear(99, armas, armaduras, melhorias, rng).tipo == "essencia"
	_ok(esgotado, "inventário completo e atributos no máximo dão Essência")
	var estado := root.get_node("EstadoJogo")
	estado.modo_teste = true
	estado.indice_nivel = indice_nivel
	estado.checkpoint = Vector2.ZERO
	# Mede o ciclo inicial do boss sem depender do progresso persistido local.
	# O processo corre em modo de teste e termina sem gravar este estado isolado.
	var boss_id := IDS.boss_id_do_indice(indice_nivel)
	var reward_id := IDS.reward_id_bau_chefe(IDS.level_id_do_indice(indice_nivel))
	estado.bosses_derrotados.erase(boss_id)
	estado.recompensas_reclamadas.erase(reward_id)
	change_scene_to_file("res://scenes/Main.tscn")
	await create_timer(0.4).timeout
	var chefe := get_first_node_in_group("chefes")
	_ok(chefe != null, "boss nasce no estado inicial isolado")
	if chefe == null:
		print("Baú: %d falhas" % falhas)
		quit(1)
		return
	var nivel := chefe.get_parent()
	chefe.set_physics_process(false)
	chefe.derrotado.emit()
	chefe.derrotado.emit()
	await create_timer(0.2).timeout
	var bau := nivel.get_node_or_null("BauChefe")
	_ok(bau != null, "derrotar o chefe cria o baú")
	_ok(not nivel.get_node("Porta").monitoring, "saída espera pela recolha")
	bau._abrir()
	var saldo := JSON.stringify(estado.para_dicionario())
	bau._abrir()
	_ok(saldo == JSON.stringify(estado.para_dicionario()), "abrir duas vezes não duplica o prémio")
	_ok(bau.get("_painel") != null, "mostra a recompensa")
	bau.recolhido.emit()
	_ok(nivel.get_node("Porta").monitoring, "recolher liberta a saída")
	# Recriar a cena (death/reload/session reset) não pode recriar o boss nem
	# o baú já reclamado; apenas recompõe a porta aberta.
	reload_current_scene()
	await create_timer(0.5).timeout
	var nivel_recarregado := current_scene.get_child(0)
	var boss_recriado := false
	for no in get_nodes_in_group("chefes"):
		if nivel_recarregado.is_ancestor_of(no):
			boss_recriado = true
	_ok(not boss_recriado, "boss permanente não reaparece após reload")
	_ok(nivel_recarregado.get_node_or_null("BauChefe") == null,
		"reward reclamado não recria baú após session reset")
	_ok(nivel_recarregado.get_node("Porta").monitoring,
		"reload recompõe saída aberta para boss/reward permanentes")
	print("Baú: %d falhas" % falhas)
	quit(0 if falhas == 0 else 1)

func _ok(condicao: bool, descricao: String) -> void:
	print("%s: %s" % ["OK" if condicao else "FALHOU", descricao])
	if not condicao:
		falhas += 1
