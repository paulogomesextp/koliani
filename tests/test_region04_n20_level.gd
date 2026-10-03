class_name TestesRegion04N20
extends RefCounted
## Contrato estrutural do N20 -- "Nucleo da Fornalha", 5.o nivel da Regiao IV:
## EXAME CUMULATIVO + GUARDIAO DA FORNALHA (unico boss da regiao). Nivel
## AUTORAL gerado por `tools/construir_n20_nucleo.py`; contrato LOCKED:
## docs/art_direction/regions/region_04/ (level_mechanics.png, boss_pack.png).
## Desenho: docs/nivel_autoral_n20.md.
##
## Prova, com os SCRIPTS REAIS e o salto REAL da Koliani: estrutura (cena,
## Koliani, Porta, Chefe, corredor=false), 6 checkpoints com um imediatamente
## antes do boss e nenhum entre uma valvula e os seus alvos, 2 segredos, vaos
## dentro do envelope do salto duplo, nenhuma fresta que entale (13-33 px),
## pistoes apoiados, janelas seguras, a arena (chao continuo, refugios dentro
## do alcance de UM salto e fora da faixa do boss, muro) e que o ciclo se repete
## igual a cada reaparecer.

const CENA := "res://scenes/levels/O_Abismo.tscn"
const INDICE_N20 := 19
const N12 := preload("res://tests/test_region03_n12_level.gd")
const N19 := preload("res://tests/test_region04_n19_level.gd")
const ESPECIES := ["trabalhador_corrompido", "arqueiro_da_fornalha", "operario_blindado"]
const VEL := 240.0


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var cena := load(CENA) as PackedScene
	_v(falhas, cena != null, "N20: cena carrega")
	if cena == null:
		return falhas
	RelogioFornalha.manual = 0.0
	var raiz := cena.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)

	_estrutura(falhas, raiz)
	_checkpoints_e_valvulas(falhas, raiz)
	_geometria(falhas, raiz)
	N19._pistoes_apoiados(falhas, raiz)
	_janelas(falhas, raiz)
	_arena(falhas, raiz)
	_manifesto(falhas)

	raiz.queue_free()
	RelogioFornalha.manual = -1.0
	return falhas


static func _estrutura(falhas: Array[String], raiz: Node) -> void:
	_v(falhas, bool(raiz.get("corredor")) == false, "N20: corredor = false (nivel feito a mao)")
	_v(falhas, raiz.get_node_or_null("Koliani") != null, "N20: tem Koliani")
	_v(falhas, raiz.get_node_or_null("Porta") != null, "N20: tem Porta")
	var chefe := raiz.get_node_or_null("Chefe")
	_v(falhas, chefe != null and chefe is ChefeGuardiaoDaFornalha, "N20: o Chefe e' o Guardiao da Fornalha")
	_v(falhas, raiz.get_node_or_null("Guardiao") == null, "N20: sem Guardiao normal (so' o boss)")
	var atm := raiz.get_node_or_null("Atmosfera")
	_v(falhas, atm != null and String(atm.get("bioma")) == "fornalha", "N20: bioma fornalha")
	_v(falhas, EstadoJogo.NIVEIS[INDICE_N20] == CENA, "N20: o indice 19 de NIVEIS e' esta cena")
	var larg: float = float(atm.get("largura_nivel")) if atm else 0.0
	_v(falhas, larg >= 5000.0 and larg <= 6500.0, "N20: largura %.0f px fora de 5000-6500" % larg)

	var n := {"pistao": 0, "jato": 0, "valvula": 0, "ritmada": 0, "so_aberta": 0, "segredo": 0,
		"check": 0, "lava": 0, "sobe": 0, "piso": 0, "carrinho": 0}
	var especies := {}
	var elites := 0
	for filho in raiz.get_children():
		var sc: Script = filho.get_script()
		var sp := sc.resource_path if sc else ""
		if sp.ends_with("pistao_fornalha.gd"):
			n.pistao += 1
		elif sp.ends_with("jato_fornalha.gd"):
			n.jato += 1
		elif sp.ends_with("valvula_fornalha.gd"):
			n.valvula += 1
		elif sp.ends_with("piso_quente.gd"):
			n.piso += 1
		elif sp.ends_with("checkpoint.gd"):
			n.check += 1
		elif filho is LavaFornalha:
			n.lava += 1
			if float(filho.get("sobe_amplitude")) > 0.0:
				n.sobe += 1
		elif String(filho.name).begins_with("Carrinho"):
			n.carrinho += 1
		elif sp.ends_with("plataforma_ritmada.gd") or String(filho.scene_file_path).ends_with("PlataformaRitmada.tscn"):
			n.ritmada += 1
			if String(filho.get("efeito_valvula")) == "so_aberta":
				n.so_aberta += 1
		if String(filho.name).begins_with("Segredo"):
			n.segredo += 1
		if filho is DemonioBase and not (filho is ChefeBase):
			especies[String(filho.get("especie"))] = true
			if bool(filho.get("elite")):
				elites += 1
	_v(falhas, n.check == 6, "N20: 6 checkpoints (%d)" % n.check)
	_v(falhas, n.segredo == 2, "N20: 2 segredos (%d)" % n.segredo)
	_v(falhas, n.so_aberta == 2, "N20: 2 plataformas de segredo ligadas a valvulas (%d)" % n.so_aberta)
	_v(falhas, n.valvula == 2 and n.pistao == 3 and n.jato == 3, "N20: valvulas/pistoes/jatos %s" % str(n))
	_v(falhas, n.sobe >= 1 and n.carrinho >= 1 and n.piso >= 2, "N20: revisao A/B (lava que sobe, carrinho, pisos) %s" % str(n))
	_v(falhas, elites == 1, "N20: um elite (Operario) na aproximacao (%d)" % elites)
	for e in especies:
		_v(falhas, ESPECIES.has(e), "N20: especie `%s` nao e' canonica da Regiao IV extraida" % e)


## Nenhum checkpoint entre uma valvula e os seus alvos; um CP imediatamente
## antes do boss (dentro da arena, a esquerda da faixa do chefe).
static func _checkpoints_e_valvulas(falhas: Array[String], raiz: Node) -> void:
	var cps: Array[float] = []
	for filho in raiz.get_children():
		if String(filho.name).begins_with("Check"):
			cps.append((filho as Node2D).position.x)
	cps.sort()
	var valvulas := {}
	var alvos: Array[Node2D] = []
	for filho in raiz.get_children():
		var sc: Script = filho.get_script()
		if sc and sc.resource_path.ends_with("valvula_fornalha.gd"):
			valvulas[String(filho.get("grupo"))] = filho
		elif filho.get("grupo_valvula") != null and String(filho.get("grupo_valvula")) != "":
			alvos.append(filho)
	for a in alvos:
		var g := String(a.get("grupo_valvula"))
		_v(falhas, valvulas.has(g), "N20: alvo %s aponta para o grupo `%s` sem valvula" % [a.name, g])
		if not valvulas.has(g):
			continue
		var vx: float = (valvulas[g] as Node2D).position.x
		for cx in cps:
			_v(falhas, not (cx > minf(vx, a.position.x) and cx < maxf(vx, a.position.x)),
				"N20: checkpoint x=%.0f entre a valvula `%s` e %s" % [cx, g, a.name])
	for g in valvulas:
		var n_alvos := 0
		for a in alvos:
			if String(a.get("grupo_valvula")) == g:
				n_alvos += 1
		_v(falhas, n_alvos >= 1, "N20: a valvula `%s` nao governa nada" % g)
		_v(falhas, bool(valvulas[g].get("aberta")) == false, "N20: a valvula `%s` nao arranca fechada" % g)
	# o checkpoint do boss
	var boss := raiz.get_node_or_null("Chefe") as Node2D
	var chk := raiz.get_node_or_null("CheckBoss") as Node2D
	_v(falhas, chk != null and boss != null and chk.position.x < boss.position.x - 400.0,
		"N20: CheckBoss existe e fica bem antes do boss (morrer no boss nao repete o exame)")
	var maior_anterior := -1.0
	for cx in cps:
		if cx < (chk.position.x if chk else 0.0):
			maior_anterior = cx
	_v(falhas, chk != null and chk.position.x - maior_anterior > 600.0,
		"N20: o CheckBoss e' o primeiro da arena (o anterior fica no exame)")
	var chao_arena := _plat(raiz, "ChaoArena")
	if chk and not chao_arena.is_empty():
		_v(falhas, chk.position.x >= chao_arena.esq and chk.position.x <= chao_arena.esq + 120.0,
			"N20: o CheckBoss esta' a' entrada da arena")


static func _plat(raiz: Node, nome: String) -> Dictionary:
	var p := raiz.get_node_or_null(nome) as Node2D
	if p == null:
		return {}
	var t: Vector2 = p.get("tamanho")
	return {"esq": p.position.x - t.x * 0.5, "dir": p.position.x + t.x * 0.5,
		"topo": p.position.y - t.y * 0.5}


static func _geometria(falhas: Array[String], raiz: Node) -> void:
	var alc := N12.alcance_salto_duplo() - 12.0
	_v(falhas, alc > 200.0, "N20: salto duplo medido %.0f fora do esperado" % alc)
	var pares := [
		["ChaoA", "PedraB1"], ["ChaoB2", "ChaoC0"],
		["ChaoC0", "RitmadaC1"], ["RitmadaC1", "RitmadaC2"], ["RitmadaC2", "IlhaC"],
		["IlhaC", "RitmadaC3"], ["RitmadaC3", "RitmadaC4"], ["RitmadaC4", "ChaoC1"],
		["RitmadaC1", "StepC"], ["StepC", "SegredoA"],
		["ChaoC1", "ChaoD"], ["ChaoD", "StepD"], ["StepD", "SegredoB"], ["ChaoD", "ChaoArena"],
	]
	for par in pares:
		var a := _plat(raiz, par[0])
		var b := _plat(raiz, par[1])
		if a.is_empty() or b.is_empty():
			_v(falhas, false, "N20: plataforma em falta no par %s" % str(par))
			continue
		var vao: float = maxf(float(b.esq) - float(a.dir), float(a.esq) - float(b.dir))
		var sobe: float = float(a.topo) - float(b.topo)
		if vao > 0.0:
			# fendas que entalam: 13-33 px (a Koliani mede 20)
			_v(falhas, vao < 13.0 or vao > 33.0, "N20: fresta de %.0f px entre %s e %s" % [vao, par[0], par[1]])
			_v(falhas, vao <= alc, "N20: vao de %.0f px > %.0f entre %s e %s" % [vao, alc, par[0], par[1]])
		_v(falhas, sobe <= 122.0 * 1.9, "N20: subida de %.0f px entre %s e %s" % [sobe, par[0], par[1]])


static func _janelas(falhas: Array[String], raiz: Node) -> void:
	# [nome, perigos, x0, x1, janela minima (s)]
	var cruz := [
		["C-a", ["PistaoC"], 2596.0, 2760.0, 1.0],
		["C-b", ["JatoC"], 2760.0, 2950.0, 1.0],
	]
	for c in cruz:
		var w := N19._janela(raiz, c[1], c[2], c[3])
		_v(falhas, w >= float(c[4]), "N20: travessia %s com janela %.2f s (< %.2f)" % [c[0], w, c[4]])
	# porta de valvula: sem a valvula quase nao ha janela (senao a valvula era enfeite)
	var w := N19._janela(raiz, ["PistaoD1", "PistaoD2", "JatoD"], 3885.0, 4250.0)
	_v(falhas, w < 0.6, "N20: o corredor D nao devia dar folga sem valvula (%.2f s)" % w)


static func _arena(falhas: Array[String], raiz: Node) -> void:
	var chao := _plat(raiz, "ChaoArena")
	var re := _plat(raiz, "RefugioE")
	var rd := _plat(raiz, "RefugioD")
	var boss := raiz.get_node_or_null("Chefe")
	if chao.is_empty() or re.is_empty() or rd.is_empty() or boss == null:
		_v(falhas, false, "N20: arena incompleta")
		return
	_v(falhas, chao.dir - chao.esq >= 1000.0, "N20: arena de pelo menos 1000 px")
	var faixa_esq := float(boss.get("faixa_esq"))
	var faixa_dir := float(boss.get("faixa_dir"))
	_v(falhas, faixa_dir - faixa_esq >= 400.0, "N20: faixa do boss com espaco de manobra")
	for r in [re, rd]:
		_v(falhas, chao.topo - r.topo > 60.0 and chao.topo - r.topo <= 118.0,
			"N20: refugio a %.0f px do chao (UM salto: <= 118)" % (chao.topo - r.topo))
		_v(falhas, r.dir <= faixa_esq or r.esq >= faixa_dir,
			"N20: o refugio tem de ficar FORA da faixa do boss (o corpo nao o atravessa)")
		_v(falhas, r.dir - r.esq >= 150.0, "N20: refugio largo (>=150 px)")
	_v(falhas, raiz.get_node_or_null("MuroArenaD") != null, "N20: muro a direita da arena")
	var porta := raiz.get_node("Porta") as Node2D
	_v(falhas, porta.position.x > faixa_dir and porta.position.x < chao.dir,
		"N20: a Porta fica na arena, depois da faixa do boss")
	_v(falhas, boss.position.x > faixa_esq and boss.position.x < faixa_dir, "N20: o boss nasce na sua faixa")


static func _manifesto(falhas: Array[String]) -> void:
	var m: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/level_manifest.json"))
	var ok := false
	if m is Dictionary:
		for l in (m as Dictionary)["levels"]:
			if String(l["level_id"]) == "level_020":
				ok = String(l["boss_ref"]["scene"]).ends_with("ChefeGuardiaoDaFornalha.tscn") \
					and String(l["runtime_scene"]) == CENA
	_v(falhas, ok, "N20: o manifesto aponta o level_020 para o Guardiao da Fornalha")
	_v(falhas, preload("res://scripts/nivel_com_chefe.gd").REGIAO_CONCLUIDA.get(INDICE_N20, "") == "region.4.complete",
		"N20: fecha a Regiao IV com o cartao region.4.complete")
	_v(falhas, not preload("res://scripts/nivel_com_chefe.gd").HABILIDADE_DO_CHEFE.has(INDICE_N20),
		"N20: nenhuma habilidade inventada (o contrato nao define uma)")
	for k in ["boss.guardiao_da_fornalha", "dlg.guardiao_fornalha.intro.1", "dlg.guardiao_fornalha.intro.2",
			"dlg.guardiao_fornalha.win.1", "region.4.complete", "level.n19"]:
		_v(falhas, Textos.t(k) != k, "N20: chave i18n `%s` existe" % k)
	_v(falhas, Textos.t("level.n19") != "The Abyss", "N20: level.n19 ja' nao e' 'The Abyss'")


static func _v(falhas: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		falhas.append(msg)
