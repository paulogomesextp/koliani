class_name TestesRegion04N17
extends RefCounted
## Contrato estrutural do N17 -- "Entrada da Fornalha", 1.o nivel da Regiao IV
## (Fornalha). Nivel AUTORAL gerado por `tools/construir_n17_entrada.py`.
## Contrato de arte: docs/art_direction/regions/region_04/. Desenho e
## medicoes: docs/nivel_autoral_n17.md.
##
## Prova, com o salto REAL da Koliani, que os vaos entre as ilhas de pedra
## sobre a lava cabem no salto duplo.

const CENA := "res://scenes/levels/Galeria_dos_Ossos.tscn"
const INDICE_N17 := 16
const N12 := preload("res://tests/test_region03_n12_level.gd")
const ESPECIES := ["trabalhador_corrompido", "arqueiro_da_fornalha", "lanca_chamas",
	"drone_de_lava", "automato_de_fundicao"]


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var cena := load(CENA) as PackedScene
	_verificar(falhas, cena != null, "N17: cena carrega")
	if cena == null:
		return falhas
	var raiz := cena.instantiate()

	_verificar(falhas, raiz.get("corredor") == false, "N17: sem jornada procedural")
	_verificar(falhas, raiz.get("alongar_plataformas") == false, "N17: sem esticao automatico")
	_verificar(falhas, raiz.get("checkpoints_autorais") == true, "N17: checkpoints autorais")
	_verificar(falhas, raiz.get_node_or_null("Porta") != null, "N17: tem porta")
	_verificar(falhas, EstadoJogo.NIVEIS[INDICE_N17] == CENA, "N17: indice 16 aponta para esta cena")
	_verificar(falhas, CatalogoCampanha.CHEFE_KEY[INDICE_N17] == "guard.automato_de_fundicao",
		"N17: a HUD diz Automato de Fundicao")
	var atm := raiz.get_node_or_null("Atmosfera")
	_verificar(falhas, atm != null and String(atm.get("bioma")) == "fornalha", "N17: bioma fornalha")
	_verificar(falhas, atm != null and String(atm.get("fundo_pack")) == "fornalha", "N17: fundo fornalha")

	var especies := {}
	var n := {"piso": 0, "jato": 0, "lava": 0, "carrinho": 0, "segredo": 0, "check": 0,
		"elevador": 0, "laje": 0}
	for filho in raiz.get_children():
		var e: Variant = filho.get("especie")
		if e != null and String(filho.scene_file_path).ends_with("/DemonioBase.tscn"):
			especies[String(e)] = true
		var sc: Script = filho.get_script()
		var sp := sc.resource_path if sc else ""
		var f := String(filho.scene_file_path)
		if sp.ends_with("piso_quente.gd"):
			n.piso += 1
		elif sp.ends_with("jato_fornalha.gd"):
			n.jato += 1
		elif sp.ends_with("lava_fornalha.gd"):
			n.lava += 1
		elif sp.ends_with("elevador_coluna.gd"):
			n.elevador += 1
			_verificar(falhas, filho.get("textura_corrente") != null,
				"N17: %s devia usar a corrente da prancha" % filho.name)
		elif f.ends_with("/PlataformaQuebra.tscn"):
			n.laje += 1
		elif String(filho.name).begins_with("Carrinho") and sp.ends_with("plataforma_corrente.gd"):
			n.carrinho += 1
		if String(filho.name).begins_with("EssenciaSegredo"):
			n.segredo += 1
		if String(filho.name).begins_with("Check"):
			n.check += 1
	for e in ESPECIES:
		_verificar(falhas, especies.has(e), "N17: falta o inimigo `%s`" % e)
	_verificar(falhas, n.piso >= 3, "N17: pisos quentes (>= 3), ha' %d" % n.piso)
	_verificar(falhas, n.jato >= 2, "N17: jatos de fogo (>= 2), ha' %d" % n.jato)
	_verificar(falhas, n.lava >= 3, "N17: pocas de lava (>= 3), ha' %d" % n.lava)
	_verificar(falhas, n.elevador == 2, "N17: 2 elevadores de corrente, ha' %d" % n.elevador)
	_verificar(falhas, n.carrinho >= 2, "N17: carrinhos de minerio (>= 2), ha' %d" % n.carrinho)
	_verificar(falhas, n.laje >= 5, "N17: lajes que desabam (>= 5), ha' %d" % n.laje)
	_verificar(falhas, n.segredo == 3, "N17: 3 essencias secretas, ha' %d" % n.segredo)
	_verificar(falhas, n.check >= 4, "N17: checkpoints (>= 4), ha' %d" % n.check)

	# --- vaos entre as ilhas da primeira lava cabem no salto duplo -----------
	var alc := N12.alcance_salto_duplo() - 12.0
	# poca A: as lajes que desabam estao a <= alcance umas das outras
	var cadeia := ["ChaoA", "LajeA1", "LajeA2", "LajeA3", "ChaoB"]
	for i in cadeia.size() - 1:
		var a := N12._caixa(raiz, cadeia[i])
		var b := N12._caixa(raiz, cadeia[i + 1])
		_verificar(falhas, not a.is_empty() and not b.is_empty(), "N17: faltam %s/%s" % [cadeia[i], cadeia[i + 1]])
		if a.is_empty() or b.is_empty():
			continue
		_verificar(falhas, N12._vao(a, b) <= alc, "N17: vao %s->%s maior que o salto" % [cadeia[i], cadeia[i + 1]])
	# o elevador 1 leva a' galeria alta: topo do curso a <= 118 px da galeria A
	var ga := N12._caixa(raiz, "GaleriaA")
	var e1 := raiz.get_node_or_null("Elevador1") as Node2D
	_verificar(falhas, e1 != null and not ga.is_empty(), "N17: Elevador1 e GaleriaA")
	if e1 != null and not ga.is_empty():
		var topo_fim: float = e1.position.y + float(e1.get("curso").y) - 8.0
		_verificar(falhas, absf(topo_fim - float(ga.topo)) <= 12.0,
			"N17: o elevador 1 devia parar rente a' galeria A (%.0f vs %.0f)" % [topo_fim, ga.topo])
	# paredes/degraus das pocas fecham o vao sob as lajes
	for muro in ["MuroLavaAE", "MuroLavaAD", "MuroLavaGrandeE", "MuroLavaGrandeD"]:
		var m := N12._caixa(raiz, muro)
		_verificar(falhas, not m.is_empty() and float(m.base) >= 940.0,
			"N17: %s devia fechar o vao ate' ao fundo da poca" % muro)
	raiz.free()
	return falhas


static func _verificar(falhas: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		falhas.append(msg)
