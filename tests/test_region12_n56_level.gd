class_name TestesRegion12N56
extends RefCounted
## Contrato estrutural do N56 -- "Fronteira Corrompida", 1.o nivel da Regiao XII
## (Terras Envenenadas). Nivel AUTORAL gerado por `tools/construir_n56_fronteira.py`.
## Contrato de arte: docs/art_direction/regions/region_12/. Desenho e medicoes:
## docs/nivel_autoral_n56.md.

const CENA := "res://scenes/levels/Distrito_das_Engrenagens.tscn"
const INDICE := 55
const N12 := preload("res://tests/test_region03_n12_level.gd")
const ESPECIES := ["rato_pestilento", "mosca_acida", "espreitador_fungico"]


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var cena := load(CENA) as PackedScene
	_ok(falhas, cena != null, "N56: cena carrega")
	if cena == null:
		return falhas
	var raiz := cena.instantiate()
	_ok(falhas, raiz.get("corredor") == false, "N56: sem jornada procedural")
	_ok(falhas, raiz.get("alongar_plataformas") == false, "N56: sem esticao automatico")
	_ok(falhas, raiz.get("checkpoints_autorais") == true, "N56: checkpoints autorais")
	_ok(falhas, String(raiz.get("mecanica_anunciada")) == "solo_toxico", "N56: anuncia o solo toxico")
	_ok(falhas, raiz.get_node_or_null("Porta") != null, "N56: tem porta")
	_ok(falhas, EstadoJogo.NIVEIS[INDICE] == CENA, "N56: indice 55 aponta para esta cena")
	_ok(falhas, CatalogoCampanha.CHEFE_KEY[INDICE] == "guard.espreitador_fungico",
		"N56: a HUD diz Espreitador Fungico")
	var atm := raiz.get_node_or_null("Atmosfera")
	_ok(falhas, atm != null and String(atm.get("bioma")) == "terras_envenenadas", "N56: bioma terras_envenenadas")
	_ok(falhas, atm != null and String(atm.get("fundo_pack")) == "terras_n56", "N56: fundo terras_n56")

	var especies := {}
	var n := {"solo": 0, "nuvem": 0, "limpa": 0, "segredo": 0, "check": 0}
	for filho in raiz.get_children():
		var e: Variant = filho.get("especie")
		if e != null and String(filho.scene_file_path).ends_with("/DemonioBase.tscn"):
			especies[String(e)] = true
		var sc: Script = filho.get_script()
		var sp := sc.resource_path if sc else ""
		if sp.ends_with("solo_toxico.gd"):
			if String(filho.get("modo")) == "nuvem":
				n.nuvem += 1
			else:
				n.solo += 1
		elif sp.ends_with("zona_limpa.gd"):
			n.limpa += 1
		if String(filho.name).begins_with("EssenciaSegredo"):
			n.segredo += 1
		if String(filho.name).begins_with("Check"):
			n.check += 1
	for e in ESPECIES:
		_ok(falhas, especies.has(e), "N56: falta o inimigo `%s`" % e)
	_ok(falhas, n.solo >= 4, "N56: poças de solo toxico (>= 4), ha' %d" % n.solo)
	_ok(falhas, n.nuvem >= 3, "N56: nuvens de veneno (>= 3), ha' %d" % n.nuvem)
	_ok(falhas, n.limpa >= 2, "N56: zonas limpas (>= 2), ha' %d" % n.limpa)
	_ok(falhas, n.segredo == 2, "N56: 2 essencias secretas, ha' %d" % n.segredo)
	_ok(falhas, n.check >= 4, "N56: checkpoints (>= 4), ha' %d" % n.check)

	# --- as tabuas sobre o pantano: vaos medidos com o salto duplo real -----
	var alc := N12.alcance_salto_duplo() - 12.0
	for par in [["ChaoA", "TabuaB1"], ["TabuaB1", "TabuaB2"], ["TabuaB2", "TabuaB3"],
			["TabuaB3", "ChaoB"], ["DegrauSeg1", "SegredoA"]]:
		var a := N12._caixa(raiz, par[0])
		var b := N12._caixa(raiz, par[1])
		_ok(falhas, not a.is_empty() and not b.is_empty(), "N56: faltam %s/%s" % par)
		if a.is_empty() or b.is_empty():
			continue
		_ok(falhas, N12._vao(a, b) <= alc, "N56: vao %s->%s = %.0f > alcance %.0f" % [par[0], par[1], N12._vao(a, b), alc])
		_ok(falhas, absf(float(a.topo) - float(b.topo)) <= 118.0, "N56: degrau %s->%s demasiado alto" % par)
	# --- o pantano nao deixa passar por baixo das lajes -----------------------
	var pantano := N12._caixa(raiz, "PantanoB")
	_ok(falhas, not pantano.is_empty() and float(pantano.base) >= 800.0, "N56: o fundo do pantano devia ir ate' 800")
	raiz.free()
	return falhas


static func _ok(falhas: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		falhas.append(msg)
