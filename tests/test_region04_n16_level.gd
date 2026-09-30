class_name TestesRegion04N16
extends RefCounted
## Contrato estrutural do N16 -- "Entrada da Fornalha", 1.o nivel da Regiao IV
## (Fornalha). Nivel AUTORAL gerado por `tools/construir_n16_entrada.py`.
## Contrato de arte: docs/art_direction/regions/region_04/. Desenho e
## medicoes: docs/nivel_autoral_n16.md.
##
## Prova, com o salto REAL da Koliani, que os vaos entre as ilhas de pedra
## sobre a lava cabem no salto duplo.

const CENA := "res://scenes/levels/Cemiterio_dos_Reis.tscn"
const INDICE_N16 := 15
const N12 := preload("res://tests/test_region03_n12_level.gd")
const ESPECIES := ["trabalhador_corrompido", "arqueiro_da_fornalha", "operario_blindado"]


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var cena := load(CENA) as PackedScene
	_verificar(falhas, cena != null, "N16: cena carrega")
	if cena == null:
		return falhas
	var raiz := cena.instantiate()

	_verificar(falhas, raiz.get("corredor") == false, "N16: sem jornada procedural")
	_verificar(falhas, raiz.get("alongar_plataformas") == false, "N16: sem esticao automatico")
	_verificar(falhas, raiz.get("checkpoints_autorais") == true, "N16: checkpoints autorais")
	_verificar(falhas, String(raiz.get("mecanica_anunciada")) == "piso_quente",
		"N16: anuncia o piso quente")
	_verificar(falhas, raiz.get_node_or_null("Porta") != null, "N16: tem porta")
	_verificar(falhas, EstadoJogo.NIVEIS[INDICE_N16] == CENA, "N16: indice 15 aponta para esta cena")
	_verificar(falhas, CatalogoCampanha.CHEFE_KEY[INDICE_N16] == "guard.operario_blindado",
		"N16: a HUD diz Operario Blindado")
	var atm := raiz.get_node_or_null("Atmosfera")
	_verificar(falhas, atm != null and String(atm.get("bioma")) == "fornalha", "N16: bioma fornalha")
	_verificar(falhas, atm != null and String(atm.get("fundo_pack")) == "fornalha", "N16: fundo fornalha")

	var especies := {}
	var n := {"piso": 0, "jato": 0, "lava": 0, "carrinho": 0, "segredo": 0, "check": 0}
	for filho in raiz.get_children():
		var e: Variant = filho.get("especie")
		if e != null and String(filho.scene_file_path).ends_with("/DemonioBase.tscn"):
			especies[String(e)] = true
		var sc: Script = filho.get_script()
		var sp := sc.resource_path if sc else ""
		if sp.ends_with("piso_quente.gd"):
			n.piso += 1
		elif sp.ends_with("jato_fornalha.gd"):
			n.jato += 1
		elif sp.ends_with("lava_fornalha.gd"):
			n.lava += 1
		elif String(filho.name).begins_with("Carrinho") and sp.ends_with("plataforma_corrente.gd"):
			n.carrinho += 1
		if String(filho.name).begins_with("EssenciaSegredo"):
			n.segredo += 1
		if String(filho.name).begins_with("Check"):
			n.check += 1
	for e in ESPECIES:
		_verificar(falhas, especies.has(e), "N16: falta o inimigo `%s`" % e)
	_verificar(falhas, n.piso >= 3, "N16: pisos quentes (>= 3), ha' %d" % n.piso)
	_verificar(falhas, n.jato >= 2, "N16: jatos de fogo (>= 2), ha' %d" % n.jato)
	_verificar(falhas, n.lava >= 3, "N16: lagos de lava (>= 3), ha' %d" % n.lava)
	_verificar(falhas, n.carrinho >= 2, "N16: carrinhos de minerio (>= 2), ha' %d" % n.carrinho)
	_verificar(falhas, n.segredo == 2, "N16: 2 essencias secretas, ha' %d" % n.segredo)
	_verificar(falhas, n.check >= 4, "N16: checkpoints (>= 4), ha' %d" % n.check)

	# --- vaos entre as ilhas da primeira lava cabem no salto duplo -----------
	var alc := N12.alcance_salto_duplo() - 12.0
	for par in [["ChaoA", "Pedra1"], ["Pedra1", "Pedra2"], ["Pedra2", "ChaoB"]]:
		var a := N12._caixa(raiz, par[0])
		var b := N12._caixa(raiz, par[1])
		_verificar(falhas, not a.is_empty() and not b.is_empty(), "N16: faltam %s/%s" % par)
		if a.is_empty() or b.is_empty():
			continue
		var vao := N12._vao(a, b)
		_verificar(falhas, vao <= alc, "N16: vao %s->%s = %.0f > alcance %.0f" % [par[0], par[1], vao, alc])
		_verificar(falhas, absf(float(a.topo) - float(b.topo)) <= 118.0,
			"N16: degrau %s->%s demasiado alto" % par)
	# --- paredes dos lagos: quem cai na lava nao passa por baixo das lajes -----
	for muro in ["MuroA", "MuroB1", "MuroB2", "MuroC1", "MuroD"]:
		var m := N12._caixa(raiz, muro)
		_verificar(falhas, not m.is_empty() and float(m.base) >= 740.0,
			"N16: %s devia fechar o vao ate' ao fundo do lago" % muro)
	raiz.free()
	return falhas


static func _verificar(falhas: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		falhas.append(msg)
