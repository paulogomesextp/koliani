class_name TestesRegion04N19
extends RefCounted
## Contrato estrutural do N19 -- "Sala das Pressoes", 4.o nivel (3.o de
## desenvolvimento) da Regiao IV (Fornalha). Nivel AUTORAL gerado por
## `tools/construir_n19_sala_pressoes.py`; contrato de arte LOCKED:
## docs/art_direction/regions/region_04/ (N19: jatos de fogo telegraficos,
## pistoes esmagadores, valvulas de pressao, plataformas sincronizadas).
## Desenho: docs/nivel_autoral_n19.md.
##
## Prova, com os SCRIPTS REAIS dos perigos e o salto REAL da Koliani, que: ha'
## 5 checkpoints e 3 segredos; cada valvula governa alvos e nenhum alvo fica
## para la' de um checkpoint que a preceda (a cena recarrega ao morrer e as
## valvulas voltam ao arranque); os vaos cabem no salto duplo; cada travessia
## critica tem uma janela segura; os pistoes da arena nunca batem juntos e as
## ilhas ficam livres; o ciclo repete-se igual a cada reaparecer.

const CENA := "res://scenes/levels/Templo_da_Serpente.tscn"
const INDICE_N19 := 18
const N12 := preload("res://tests/test_region03_n12_level.gd")
const ESPECIES := ["trabalhador_corrompido", "arqueiro_da_fornalha", "lanca_chamas"]
const VEL := 240.0
const MEIA_KOLIANI := 14.0


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var cena := load(CENA) as PackedScene
	_v(falhas, cena != null, "N19: cena carrega")
	if cena == null:
		return falhas
	RelogioFornalha.manual = 0.0
	var raiz := cena.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(raiz)

	_estrutura(falhas, raiz)
	_valvulas_e_checkpoints(falhas, raiz)
	_geometria(falhas, raiz)
	_pistoes_apoiados(falhas, raiz)
	_janelas(falhas, raiz)
	_retomas(falhas, raiz)
	_arena(falhas, raiz)

	(Engine.get_main_loop() as SceneTree).root.remove_child(raiz)
	raiz.free()
	_reaparecer_igual(falhas, cena)
	RelogioFornalha.manual = -1.0
	return falhas


# ------------------------------------------------------------- estrutura
static func _estrutura(falhas: Array[String], raiz: Node) -> void:
	_v(falhas, raiz.get("corredor") == false, "N19: sem jornada procedural")
	_v(falhas, raiz.get("alongar_plataformas") == false, "N19: sem esticao automatico")
	_v(falhas, raiz.get("checkpoints_autorais") == true, "N19: checkpoints autorais")
	_v(falhas, String(raiz.get("mecanica_anunciada")) == "pistao", "N19: anuncia os pistoes")
	_v(falhas, raiz.get_node_or_null("Porta") != null, "N19: tem porta")
	_v(falhas, raiz.get_node_or_null("Koliani") != null, "N19: tem Koliani")
	_v(falhas, EstadoJogo.NIVEIS[INDICE_N19] == CENA, "N19: indice 18 aponta para esta cena")
	_v(falhas, CatalogoCampanha.CHEFE_KEY[INDICE_N19] == "guard.lanca_chamas",
		"N19: a HUD diz Lanca-Chamas (Guardiao, nao chefe)")
	var atm := raiz.get_node_or_null("Atmosfera")
	_v(falhas, atm != null and String(atm.get("bioma")) == "fornalha", "N19: bioma fornalha")

	var n := {"pistao": 0, "jato": 0, "valvula": 0, "ritmada": 0, "so_aberta": 0, "segredo": 0, "check": 0,
		"muro": 0, "lava": 0}
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
		if String(filho.scene_file_path).ends_with("/PlataformaRitmada.tscn"):
			n.ritmada += 1
			if String(filho.get("efeito_valvula")) == "so_aberta":
				n.so_aberta += 1
		if String(filho.scene_file_path).ends_with("/LavaFornalha.tscn"):
			n.lava += 1
		if String(filho.name).begins_with("EssenciaSegredo"):
			n.segredo += 1
		if String(filho.name).begins_with("Check"):
			n.check += 1
		if String(filho.name).begins_with("Muro"):
			n.muro += 1
		var e: Variant = filho.get("especie")
		if e != null and String(filho.scene_file_path).ends_with("/DemonioBase.tscn"):
			especies[String(e)] = true
			if filho.get("elite") == true:
				elites += 1
	for e in especies:
		_v(falhas, ESPECIES.has(e), "N19: especie `%s` fora das extraidas da Regiao IV" % e)
	_v(falhas, elites == 1, "N19: um (so') Guardiao elite, ha' %d" % elites)
	_v(falhas, not _tem_chefe(raiz), "N19: nao pode ter chefe")
	_v(falhas, n.pistao >= 12, "N19: pistoes (>= 12), ha' %d" % n.pistao)
	_v(falhas, n.jato >= 5, "N19: jatos (>= 5), ha' %d" % n.jato)
	_v(falhas, n.valvula == 6, "N19: 6 valvulas, ha' %d" % n.valvula)
	_v(falhas, n.ritmada >= 14, "N19: plataformas ritmadas (>= 14), ha' %d" % n.ritmada)
	_v(falhas, n.so_aberta == 3, "N19: 3 plataformas que so' existem com a valvula (segredos), ha' %d" % n.so_aberta)
	_v(falhas, n.segredo == 3, "N19: 3 essencias secretas, ha' %d" % n.segredo)
	_v(falhas, n.check == 5, "N19: 5 checkpoints, ha' %d" % n.check)
	_v(falhas, n.lava >= 3, "N19: fossos de lava (>= 3), ha' %d" % n.lava)
	_v(falhas, n.muro >= 6, "N19: muros dos fossos (>= 6), ha' %d" % n.muro)
	for nome in ["ArqueiroC", "TrabalhadorC", "GuardiaoN19"]:
		_v(falhas, raiz.get_node_or_null(nome) != null, "N19: falta o inimigo %s" % nome)


# ----------------------------------------- valvulas, alvos e checkpoints
static func _valvulas_e_checkpoints(falhas: Array[String], raiz: Node) -> void:
	var cps: Array[float] = []
	for filho in raiz.get_children():
		if String(filho.name).begins_with("Check"):
			cps.append((filho as Node2D).position.x)
	cps.sort()
	var valvulas: Array[Node2D] = []
	var alvos: Array[Node2D] = []
	for filho in raiz.get_children():
		var sc: Script = filho.get_script()
		if sc and sc.resource_path.ends_with("valvula_fornalha.gd"):
			valvulas.append(filho)
		elif filho.get("grupo_valvula") != null and String(filho.get("grupo_valvula")) != "":
			alvos.append(filho)
	var grupos_valvula := {}
	for v in valvulas:
		var g := String(v.get("grupo"))
		_v(falhas, not grupos_valvula.has(g), "N19: duas valvulas no grupo `%s`" % g)
		grupos_valvula[g] = v
	for a in alvos:
		var g := String(a.get("grupo_valvula"))
		_v(falhas, grupos_valvula.has(g), "N19: o alvo %s aponta para o grupo `%s` sem valvula" % [a.name, g])
		if not grupos_valvula.has(g):
			continue
		var v: Node2D = grupos_valvula[g]
		# NENHUM checkpoint entre a valvula e o alvo (ao morrer a valvula fecha)
		for cx in cps:
			var lo := minf(v.position.x, a.position.x)
			var hi := maxf(v.position.x, a.position.x)
			_v(falhas, not (cx > lo and cx < hi),
				"N19: checkpoint em x=%.0f entre a valvula %s e o alvo %s: depois de morrer a valvula ja' nao estaria aberta"
					% [cx, v.name, a.name])
		_v(falhas, a.is_in_group("valvula_" + g), "N19: %s nao esta' no grupo `valvula_%s`" % [a.name, g])
	for v in valvulas:
		var g := String(v.get("grupo"))
		var n_alvos := 0
		for a in alvos:
			if String(a.get("grupo_valvula")) == g:
				n_alvos += 1
		_v(falhas, n_alvos >= 1, "N19: a valvula %s nao governa nada" % v.name)
		_v(falhas, bool(v.get("aberta")) == false, "N19: a valvula %s nao arranca fechada" % v.name)
		# assenta num chao e nunca dentro da pista de um perigo
		var chao := _chao_sob(raiz, v.position.x, v.position.y)
		_v(falhas, chao != "", "N19: a valvula %s nao assenta em nenhum chao" % v.name)
		for a in raiz.get_children():
			var sc: Script = a.get_script()
			var sp := sc.resource_path if sc else ""
			if sp.ends_with("pistao_fornalha.gd") or sp.ends_with("jato_fornalha.gd"):
				var meia := 80.0 if sp.ends_with("pistao_fornalha.gd") else 60.0
				_v(falhas, absf((a as Node2D).position.x - v.position.x) > meia,
					"N19: a valvula %s esta' dentro da pista de %s" % [v.name, a.name])
	# cada pistao ligado a valvula retoma com o aviso inteiro por correr
	for a in alvos:
		var sc: Script = a.get_script()
		if sc and sc.resource_path.ends_with("pistao_fornalha.gd"):
			_v(falhas, float(a.call("aviso_restante_a_partir_de", a.call("fase_efetiva_retoma"))) >= 0.7,
				"N19: %s retoma sem o aviso inteiro" % a.name)


static func _chao_sob(raiz: Node, x: float, y: float) -> String:
	for filho in raiz.get_children():
		var t: Variant = filho.get("tamanho")
		if t == null or not (filho is Node2D):
			continue
		var tam: Vector2 = t
		var p := (filho as Node2D).position
		if absf(p.y - tam.y * 0.5 - y) < 4.0 and x > p.x - tam.x * 0.5 and x < p.x + tam.x * 0.5:
			return String(filho.name)
	return ""


# ------------------------------------------------------------- geometria
static func _geometria(falhas: Array[String], raiz: Node) -> void:
	var alc := N12.alcance_salto_duplo() - 12.0
	_v(falhas, alc > 200.0, "N19: salto duplo medido %.0f fora do esperado" % alc)
	# vaos horizontais entre plataformas consecutivas dos fossos e das ilhas
	var pares := [
		["ChaoB1", "RitmadaB1"], ["RitmadaB1", "RitmadaB2"], ["RitmadaB2", "RitmadaB3"],
		["RitmadaB3", "ChaoC0"],
		["ChaoC0", "RitmadaC1"], ["RitmadaC1", "RitmadaC2"], ["RitmadaC2", "IlhaC"],
		["IlhaC", "RitmadaC3"], ["RitmadaC3", "RitmadaC4"], ["RitmadaC4", "ChaoC3"],
		["ChaoD0", "RitmadaD1"], ["RitmadaD1", "RitmadaD2"], ["RitmadaD2", "IlhaD1"],
		["IlhaD1", "RitmadaD3"], ["RitmadaD3", "RitmadaD4"], ["RitmadaD4", "RitmadaD5"],
		["RitmadaD5", "ChaoArena"],
		# segredos: degraus e saltos curtos
		["ChaoB1", "StepB1"], ["StepB1", "SegredoA"],
		["RitmadaC1", "StepC"], ["StepC", "SegredoB"],
		["ChaoD0", "StepD"], ["StepD", "SegredoC"],
	]
	for par in pares:
		var a := _caixa(raiz, par[0])
		var b := _caixa(raiz, par[1])
		_v(falhas, not a.is_empty() and not b.is_empty(), "N19: faltam %s/%s" % par)
		if a.is_empty() or b.is_empty():
			continue
		var vao := N12._vao(a, b)
		_v(falhas, vao <= alc, "N19: vao %s->%s = %.0f > alcance %.0f" % [par[0], par[1], vao, alc])
		_v(falhas, absf(float(a.topo) - float(b.topo)) <= 125.0, "N19: degrau %s->%s demasiado alto" % par)
	# NENHUMA fresta entre 13 e 33 px entre superficies do chao (a Koliani mede 20 px:
	# nessas frestas entala-se quando uma plataforma ritmada volta a ser solida)
	var topos: Array = []
	for filho in raiz.get_children():
		var tam: Variant = filho.get("tamanho")
		if tam == null or not (filho is Node2D):
			continue
		var nome := String(filho.name)
		if nome.begins_with("Muro") or nome.begins_with("Fundo") or nome.begins_with("Step"):
			continue
		var box := _caixa(raiz, nome)
		if absf(float(box.topo) - 600.0) < 1.0:
			topos.append(box)
	topos.sort_custom(func(a, b): return float(a.esq) < float(b.esq))
	for i in range(1, topos.size()):
		var fresta := float(topos[i].esq) - float(topos[i - 1].dir)
		_v(falhas, fresta <= 12.0 or fresta >= 34.0,
			"N19: fresta de %.0f px entre superficies (entala a Koliani) em x=%.0f" % [fresta, float(topos[i].esq)])
	# cada fosso e' nao letal e sai-se a saltar; tem os muros que fecham o vao
	for lava in ["LavaB2", "LavaC2", "LavaD"]:
		var l := raiz.get_node_or_null(lava) as Node2D
		_v(falhas, l != null, "N19: falta %s" % lava)
		if l == null:
			continue
		_v(falhas, l.get("letal") == false, "N19: o fosso %s nao devia ser letal" % lava)
		var fundo := _caixa(raiz, "Fundo" + lava)
		_v(falhas, not fundo.is_empty() and float(fundo.topo) - 600.0 <= N12.alcance_salto_duplo() - 12.0,
			"N19: o fosso %s e' fundo demais para sair a saltar" % lava)
		_v(falhas, raiz.get_node_or_null("Muro" + lava + "a") != null
			and raiz.get_node_or_null("Muro" + lava + "b") != null,
			"N19: faltam os muros do fosso %s" % lava)
	# os segredos nao ficam dentro da pista de nenhum pistao/jato
	for seg in ["SegredoA", "SegredoB", "SegredoC"]:
		var s := _caixa(raiz, seg)
		for a in raiz.get_children():
			var sc: Script = a.get_script()
			var sp := sc.resource_path if sc else ""
			if sp.ends_with("pistao_fornalha.gd") or sp.ends_with("jato_fornalha.gd"):
				var ax := (a as Node2D).position.x
				var meia := 62.0 if sp.ends_with("pistao_fornalha.gd") else 44.0
				_v(falhas, ax + meia < float(s.esq) or ax - meia > float(s.dir),
					"N19: o segredo %s esta' na pista de %s" % [seg, a.name])


## Cada pistao bate numa superficie (topo ~ chao do pistao) e nada fica a meio.
static func _pistoes_apoiados(falhas: Array[String], raiz: Node) -> void:
	for a in raiz.get_children():
		var sc: Script = a.get_script()
		if not (sc and sc.resource_path.ends_with("pistao_fornalha.gd")):
			continue
		var base_y: float = (a as Node2D).position.y + float(a.get("curso"))
		var x := (a as Node2D).position.x
		var encontrou := false
		for p in raiz.get_children():
			var t: Variant = p.get("tamanho")
			if t == null or not (p is Node2D) or String(p.name).begins_with("Muro"):
				continue
			var tam: Vector2 = t
			var pos := (p as Node2D).position
			var topo := pos.y - tam.y * 0.5
			if x > pos.x - tam.x * 0.5 - 1.0 and x < pos.x + tam.x * 0.5 + 1.0 and absf(topo - base_y) < 3.0:
				encontrou = true
		_v(falhas, encontrou, "N19: o pistao %s nao bate em nenhuma superficie (base y=%.0f)" % [a.name, base_y])


# --------------------------------------------------------------- janelas
## Maior janela (s) de PARTIDA para atravessar de x0 a x1 a velocidade de corrida
## sem tocar em perigo (scripts reais, relogio desde o arranque).
static func _janela(raiz: Node, nomes: Array, x0: float, x1: float) -> float:
	var dur := absf(x1 - x0) / VEL
	var sentido := 1.0 if x1 >= x0 else -1.0
	var hs: Array = []
	for n in nomes:
		hs.append(raiz.get_node(n))
	var dt := 0.02
	var passos := int(70.0 / dt)
	var melhor := 0
	var atual := 0
	var seguro: Array[bool] = []
	for i in passos:
		var t0 := float(i) * dt
		var ok := true
		var j := 0.0
		while j <= dur and ok:
			var x := x0 + sentido * VEL * j
			for h in hs:
				var tl := t0 + j
				if absf(x - (h as Node2D).position.x) < _meia(h) and _perigo(h, tl):
					ok = false
					break
			j += dt
		seguro.append(ok)
	for i in passos + 200:
		if seguro[i % passos]:
			atual += 1
			melhor = maxi(melhor, atual)
		else:
			atual = 0
	return minf(float(melhor), float(passos)) * dt


static func _meia(h: Node) -> float:
	if h.get_script().resource_path.ends_with("pistao_fornalha.gd"):
		return float(h.get("largura")) * 0.86 * 0.5 + MEIA_KOLIANI
	return 23.0 + MEIA_KOLIANI


static func _perigo(h: Node, t: float) -> bool:
	if h.get_script().resource_path.ends_with("pistao_fornalha.gd"):
		return bool(h.call("perigoso_em", t))
	return int(h.call("estado_em", t)) == JatoFornalha.Estado.ATIVO


static func _janelas(falhas: Array[String], raiz: Node) -> void:
	# [nome, perigos, x0, x1, janela minima (s)] -- sem valvula: o desenho da' folga
	var cruzamentos := [
		["A1", ["PistaoA1"], 440.0, 700.0, 2.5],
		["A2a", ["PistaoA2"], 700.0, 905.0, 1.5],
		["A2b", ["PistaoA3"], 905.0, 1105.0, 1.5],
		["A3a", ["PistaoA4"], 1105.0, 1292.0, 1.5],
		["A3b", ["JatoA"], 1292.0, 1470.0, 1.2],
		["C2a", ["PistaoC3"], 3796.0, 3960.0, 1.0],
		["C2b", ["JatoC2"], 3960.0, 4150.0, 1.0],
		["Arena1", ["PistaoArena1"], 6172.0, 6352.0, 1.5],
		["Arena2", ["PistaoArena2"], 6412.0, 6612.0, 1.5],
	]
	for c in cruzamentos:
		var w := _janela(raiz, c[1], c[2], c[3])
		_v(falhas, w >= float(c[4]), "N19: a travessia %s tem janela %.2f s (< %.1f s)" % [c[0], w, c[4]])
	# B1 e C1 sao PORTAS DE VALVULA: sem valvula a janela de uma corrida e' (quase)
	# nula; e' o que faz a valvula valer a pena. Se isto passasse a dar folga, a
	# valvula era enfeite.
	var b1 := _janela(raiz, ["PistaoB1", "PistaoB2", "JatoB"], 1985.0, 2360.0)
	var c1 := _janela(raiz, ["PistaoC1", "PistaoC2", "JatoC1"], 3150.0, 3520.0)
	_v(falhas, b1 < 0.6, "N19: B1 devia ser porta da valvula V1 (janela %.2f s sem ela)" % b1)
	_v(falhas, c1 < 0.6, "N19: C1 devia ser porta da valvula V3 (janela %.2f s sem ela)" % c1)
	# D: as duas pistas coladas, DESENCONTRADAS (sem valvula) vs EM FASE (com ela)
	var pd2 := raiz.get_node("PistaoD2")
	var pd3 := raiz.get_node("PistaoD3")
	var sem_valvula := _janela(raiz, ["PistaoD2", "PistaoD3"], 5726.0, 5960.0)
	var fase2_orig: float = pd2.get("fase")
	var fase3_orig: float = pd3.get("fase")
	pd2.set("fase", pd2.get("fase_retoma"))
	pd3.set("fase", pd3.get("fase_retoma"))
	var com_valvula := _janela(raiz, ["PistaoD2", "PistaoD3"], 5726.0, 5960.0)
	pd2.set("fase", fase2_orig)
	pd3.set("fase", fase3_orig)
	_v(falhas, com_valvula >= 2.5 and com_valvula > sem_valvula + 1.5,
		"N19: a valvula V5 devia abrir uma janela larga nos pistoes de D (sem %.2f s, com %.2f s)"
			% [sem_valvula, com_valvula])


## O que a valvula devolve ao fechar: jatos retomam no repouso, com o aviso
## inteiro antes do primeiro fogo; plataformas retomam solidas.
static func _retomas(falhas: Array[String], raiz: Node) -> void:
	for a in raiz.get_children():
		var sc: Script = a.get_script()
		if not (sc and sc.resource_path.ends_with("jato_fornalha.gd")):
			continue
		if String(a.get("grupo_valvula")) == "":
			continue
		var fase := float(a.get("fase"))
		var fr: float = float(a.get("fase_retoma")) if float(a.get("fase_retoma")) >= 0.0 else fase
		# o jato retoma na posicao `fr` do ciclo: quanto falta ate' ao primeiro ATIVO?
		var t := 0.0
		while t < 20.0 and int(a.call("estado_em", t - fase + fr)) != JatoFornalha.Estado.ATIVO:
			t += 0.01
		_v(falhas, int(a.call("estado_em", fr - fase)) == JatoFornalha.Estado.DORME,
			"N19: o jato %s retoma fora do repouso" % a.name)
		_v(falhas, t >= 1.0, "N19: o jato %s acende %.2f s depois de retomar (< 1 s de aviso)" % [a.name, t])
	for a in raiz.get_children():
		if String(a.scene_file_path).ends_with("/PlataformaRitmada.tscn") and String(a.get("grupo_valvula")) != "":
			a.call("valvula_mudou", true)
			_v(falhas, bool(a.call("_calcula_solida")) or String(a.get("efeito_valvula")) != "so_aberta",
				"N19: %s nao fica solida ao abrir" % a.name)
			a.call("valvula_mudou", false)
			if String(a.get("efeito_valvula")) == "solida":
				_v(falhas, bool(a.call("_calcula_solida")), "N19: %s retoma fantasma (queda surpresa)" % a.name)
				var restante: float = float(a.call("_dur_solida")) - float(a.call("_t_no_ciclo"))
				_v(falhas, restante >= float(a.call("_dur_solida")) - 0.2,
					"N19: %s retoma sem o periodo solido inteiro" % a.name)
			a.call("valvula_mudou", false)


## Arena: nunca os dois pistoes ao mesmo tempo; as tres ilhas sao livres; o
## Guardiao nao nasce numa pista; a porta e a valvula ficam fora das pistas.
static func _arena(falhas: Array[String], raiz: Node) -> void:
	var p1 := raiz.get_node("PistaoArena1")
	var p2 := raiz.get_node("PistaoArena2")
	var juntos := 0
	var t := 0.0
	while t < 40.0:
		if p1.call("perigoso_em", t) and p2.call("perigoso_em", t):
			juntos += 1
		t += 0.02
	_v(falhas, juntos == 0, "N19: os pistoes da arena batem juntos %d vezes" % juntos)
	var x1: float = p1.position.x
	var x2: float = p2.position.x
	var m1 := _meia(p1)
	var m2 := _meia(p2)
	var ilha_centro := (x2 - m2) - (x1 + m1)
	_v(falhas, ilha_centro >= 130.0, "N19: a ilha do meio da arena tem %.0f px (< 130)" % ilha_centro)
	var chao := _caixa(raiz, "ChaoArena")
	_v(falhas, float(chao.esq) + 130.0 <= x1 - m1, "N19: a ilha da esquerda da arena e' curta")
	_v(falhas, float(chao.dir) - 130.0 >= x2 + m2, "N19: a ilha da direita da arena e' curta")
	var g := raiz.get_node("GuardiaoN19") as Node2D
	_v(falhas, g.position.x - 60.0 > x1 + m1 and g.position.x + 60.0 < x2 - m2,
		"N19: o Guardiao nasce encostado a uma pista")
	var porta := raiz.get_node("Porta") as Node2D
	_v(falhas, porta.position.x > x2 + m2 + 60.0, "N19: a porta esta' dentro da pista do pistao")
	var v7 := raiz.get_node("ValvulaArena") as Node2D
	_v(falhas, v7.position.x < x1 - m1 - 40.0, "N19: a valvula da arena esta' demasiado perto da pista")


## Reaparecer repete o ritmo: duas instancias, em instantes absolutos diferentes,
## tem os mesmos estados no mesmo instante RELATIVO ao arranque; nada arranca
## aberto, parado ou a meio da pancada.
static func _reaparecer_igual(falhas: Array[String], cena: PackedScene) -> void:
	var raiz_t := (Engine.get_main_loop() as SceneTree).root
	var assinaturas: Array = []
	for arranque in [0.0, 123.457]:
		RelogioFornalha.manual = arranque
		var r := cena.instantiate()
		raiz_t.add_child(r)
		var sig: Array = []
		for passo in [0.0, 1.3, 2.9, 5.0, 8.4]:
			RelogioFornalha.manual = arranque + passo
			var linha := ""
			for filho in r.get_children():
				var sc: Script = filho.get_script()
				var sp := sc.resource_path if sc else ""
				if sp.ends_with("pistao_fornalha.gd"):
					linha += "p%d" % int(filho.call("estado_em", float(filho.call("_tempo"))))
				elif sp.ends_with("jato_fornalha.gd"):
					var tt: float = float(filho.call("_ahora")) + float(filho.get("_desloc"))
					linha += "j%d" % int(filho.call("estado_em", tt))
				elif String(filho.scene_file_path).ends_with("/PlataformaRitmada.tscn"):
					linha += "r%d" % int(filho.call("_calcula_solida"))
			sig.append(linha)
		for filho in r.get_children():
			if filho.get("aberta") == true or filho.get("pausado") == true:
				falhas.append("N19: %s arrancou aberto/parado" % filho.name)
		assinaturas.append(sig)
		raiz_t.remove_child(r)
		r.free()
	_v(falhas, assinaturas[0] == assinaturas[1], "N19: reaparecer nao repete o ritmo (estados diferentes)")


# ------------------------------------------------------------ utilitarios
static func _tem_chefe(raiz: Node) -> bool:
	for filho in raiz.get_children():
		if filho is ChefeBase:
			return true
	return false


static func _caixa(raiz: Node, nome: String) -> Dictionary:
	var n := raiz.get_node_or_null(nome) as Node2D
	if n == null:
		return {}
	var t: Variant = n.get("tamanho")
	if t == null:
		return {}
	var tam: Vector2 = t
	return {"esq": n.position.x - tam.x * 0.5, "dir": n.position.x + tam.x * 0.5,
		"topo": n.position.y - tam.y * 0.5, "base": n.position.y + tam.y * 0.5}


static func _v(falhas: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		falhas.append(msg)
