class_name TestesRegion04N18
extends RefCounted
## Contrato estrutural do N18 -- "Camara da Lava", 3.o nivel de desenvolvimento
## da Regiao IV (Fornalha). Nivel AUTORAL gerado por
## `tools/construir_n18_camara.py`. Contrato de arte LOCKED:
## docs/art_direction/regions/region_04/ (N18: "o nivel sobe junto" -- lava que
## sobe, plataformas temporarias, jatos). Desenho: docs/nivel_autoral_n18.md.
##
## Prova, com o salto REAL da Koliani, que os vaos entre plataformas fixas e
## entre as pontas dos carrinhos e as lajes cabem no salto duplo; que a lava que
## sobe nunca toca as pedras de observacao; e que as duas faixas quentes da
## arena nunca ardem ao mesmo tempo.

const CENA := "res://scenes/levels/Cripta_das_Mil_Velas.tscn"
const INDICE_N18 := 17
const N12 := preload("res://tests/test_region03_n12_level.gd")
const ESPECIES := ["trabalhador_corrompido", "arqueiro_da_fornalha", "sentinela_de_pressao"]


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var cena := load(CENA) as PackedScene
	_verificar(falhas, cena != null, "N18: cena carrega")
	if cena == null:
		return falhas
	var raiz := cena.instantiate()

	_verificar(falhas, raiz.get("corredor") == false, "N18: sem jornada procedural")
	_verificar(falhas, raiz.get("alongar_plataformas") == false, "N18: sem esticao automatico")
	_verificar(falhas, raiz.get("checkpoints_autorais") == true, "N18: checkpoints autorais")
	_verificar(falhas, String(raiz.get("mecanica_anunciada")) == "lava_sobe",
		"N18: anuncia a lava que sobe")
	_verificar(falhas, raiz.get_node_or_null("Porta") != null, "N18: tem porta")
	_verificar(falhas, EstadoJogo.NIVEIS[INDICE_N18] == CENA, "N18: indice 17 aponta para esta cena")
	_verificar(falhas, CatalogoCampanha.CHEFE_KEY[INDICE_N18] == "guard.sentinela_de_pressao",
		"N18: a HUD diz Sentinela de Pressao (Guardiao, nao chefe)")
	var atm := raiz.get_node_or_null("Atmosfera")
	_verificar(falhas, atm != null and String(atm.get("bioma")) == "fornalha", "N18: bioma fornalha")

	var especies := {}
	var elites := 0
	var n := {"piso": 0, "jato": 0, "lava": 0, "lava_sobe": 0, "carrinho": 0, "quebra": 0,
		"elevador": 0, "segredo": 0, "check": 0}
	for filho in raiz.get_children():
		var e: Variant = filho.get("especie")
		if e != null and String(filho.scene_file_path).ends_with("/DemonioBase.tscn"):
			especies[String(e)] = true
			if filho.get("elite") == true:
				elites += 1
		var sc: Script = filho.get_script()
		var sp := sc.resource_path if sc else ""
		if sp.ends_with("piso_quente.gd"):
			n.piso += 1
		elif sp.ends_with("jato_fornalha.gd"):
			n.jato += 1
		elif sp.ends_with("lava_fornalha.gd"):
			n.lava += 1
			if float(filho.get("sobe_amplitude")) > 0.0:
				n.lava_sobe += 1
		elif sp.ends_with("elevador_coluna.gd"):
			n.elevador += 1
		elif String(filho.name).begins_with("Carrinho") and sp.ends_with("plataforma_corrente.gd"):
			n.carrinho += 1
		elif String(filho.scene_file_path).ends_with("/PlataformaQuebra.tscn"):
			n.quebra += 1
		if String(filho.name).begins_with("EssenciaSegredo"):
			n.segredo += 1
		if String(filho.name).begins_with("Check"):
			n.check += 1
	for e in ESPECIES:
		_verificar(falhas, especies.has(e), "N18: falta o inimigo `%s`" % e)
	_verificar(falhas, elites == 1, "N18: um (so') Guardiao elite, ha' %d" % elites)
	_verificar(falhas, not _tem_chefe(raiz), "N18: nao pode ter chefe")
	_verificar(falhas, n.piso >= 5, "N18: pisos quentes (>= 5), ha' %d" % n.piso)
	_verificar(falhas, n.jato >= 5, "N18: jatos (>= 5), ha' %d" % n.jato)
	_verificar(falhas, n.lava_sobe >= 2, "N18: lavas que sobem (>= 2), ha' %d" % n.lava_sobe)
	_verificar(falhas, n.carrinho >= 2, "N18: carrinhos (>= 2), ha' %d" % n.carrinho)
	_verificar(falhas, n.quebra >= 6, "N18: lajes que cedem (>= 6), ha' %d" % n.quebra)
	_verificar(falhas, n.elevador >= 3, "N18: elevadores (>= 3), ha' %d" % n.elevador)
	_verificar(falhas, n.segredo == 3, "N18: 3 essencias secretas, ha' %d" % n.segredo)
	var muros := 0
	for filho in raiz.get_children():
		if String(filho.name).begins_with("Muro"):
			muros += 1
	_verificar(falhas, muros >= 10, "N18: muros dos fossos (>= 10), ha' %d" % muros)
	_verificar(falhas, n.check == 5, "N18: 5 checkpoints, ha' %d" % n.check)

	# --- vaos entre plataformas fixas cabem no salto duplo --------------------
	var alc := N12.alcance_salto_duplo() - 12.0
	for par in [["ChaoA", "PedraA1"], ["PedraA1", "PedraA2"], ["PedraA2", "ChaoB1"],
			["LedgeC1", "PlatC2"],
			["PlatD1", "SaltoD1"], ["SaltoD1", "SaltoD2"], ["SaltoD2", "SegredoC"],
			["ChaoD1", "Laje5"], ["Laje5", "Laje6"], ["Laje6", "PedraD3"],
			["Laje1", "Laje2"], ["Laje2", "ChaoB3"], ["Laje3", "Laje4"], ["Laje4", "PedraEspera"]]:
		var a := _caixa(raiz, par[0])
		var b := _caixa(raiz, par[1])
		_verificar(falhas, not a.is_empty() and not b.is_empty(), "N18: faltam %s/%s" % par)
		if a.is_empty() or b.is_empty():
			continue
		var vao := N12._vao(a, b)
		_verificar(falhas, vao <= alc, "N18: vao %s->%s = %.0f > alcance %.0f" % [par[0], par[1], vao, alc])
		_verificar(falhas, absf(float(a.topo) - float(b.topo)) <= 125.0,
			"N18: degrau %s->%s demasiado alto" % par)

	# --- carrinho B2: margens e refugio entre as colunas de fogo --------------
	var cb2 := raiz.get_node_or_null("CarrinhoB2") as Node2D
	_verificar(falhas, cb2 != null, "N18: falta o CarrinhoB2")
	if cb2:
		var amp := float(cb2.get("amplitude"))
		var meia := float(cb2.get("largura")) * 0.5
		var folga_dir: float = float(_caixa(raiz, "Laje1").esq - (cb2.position.x + amp + meia))
		var folga_esq: float = float((cb2.position.x - amp - meia) - _caixa(raiz, "ChaoB2").dir)
		_verificar(falhas, folga_dir <= alc and folga_dir > 0.0,
			"N18: carrinho B2 -> Laje1: folga %.0f" % folga_dir)
		_verificar(falhas, folga_esq <= alc and folga_esq > 0.0,
			"N18: ChaoB2 -> carrinho B2: folga %.0f" % folga_esq)
		for jn in ["JatoB1", "JatoB2"]:
			var j := raiz.get_node(jn) as Node2D
			var ponta_esq := cb2.position.x - amp + meia
			var ponta_dir := cb2.position.x + amp - meia
			_verificar(falhas, j.position.x - 23.0 > ponta_esq and j.position.x + 23.0 < ponta_dir,
				"N18: %s tem de ficar entre as pontas do carrinho (refugio a bordo)" % jn)

	# --- a lava A nunca toca as pedras de observacao --------------------------
	var lava_a := raiz.get_node_or_null("LavaA")
	_verificar(falhas, lava_a != null, "N18: falta a LavaA")
	if lava_a:
		var topo_lava := 1e9
		var viu_aviso := false
		for i in 1400:
			var t := float(i) * 0.02
			var sup: float = (lava_a.position.y - float(lava_a.get("altura")) * 0.5) \
				- float(lava_a.call("elevacao_em", t))
			topo_lava = minf(topo_lava, sup)
			if lava_a.call("em_aviso_em", t):
				viu_aviso = true
		_verificar(falhas, topo_lava > float(_caixa(raiz, "PedraA1").topo) + 5.0,
			"N18: a lava A (%.0f) toca a pedra A1" % topo_lava)
		_verificar(falhas, topo_lava > float(_caixa(raiz, "PedraA2").topo) + 5.0,
			"N18: a lava A (%.0f) toca a pedra A2" % topo_lava)
		_verificar(falhas, viu_aviso, "N18: a lava A tem fase de AVISO")

	# --- arena: duas faixas quentes nunca ao mesmo tempo -----------------------
	var p1 := raiz.get_node_or_null("PisoArena1")
	var p2 := raiz.get_node_or_null("PisoArena2")
	_verificar(falhas, p1 != null and p2 != null, "N18: faltam os pisos da arena")
	if p1 and p2:
		var sobrepoe := 0
		var q1 := 0
		var q2 := 0
		for i in 3000:
			var t := float(i) * 0.01
			var h1: bool = int(p1.call("estado_em", t)) == PisoQuente.Estado.QUENTE
			var h2: bool = int(p2.call("estado_em", t)) == PisoQuente.Estado.QUENTE
			q1 += int(h1)
			q2 += int(h2)
			if h1 and h2:
				sobrepoe += 1
		_verificar(falhas, sobrepoe == 0, "N18: as faixas da arena ardem juntas %d ticks" % sobrepoe)
		_verificar(falhas, q1 > 0 and q2 > 0, "N18: as duas faixas da arena tem de arder")
	raiz.free()
	return falhas


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


static func _verificar(falhas: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		falhas.append(msg)
