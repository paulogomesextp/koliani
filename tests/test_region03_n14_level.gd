class_name TestesRegion03N14
extends RefCounted
## Contrato estrutural do N14 -- "Campanario", 4.o nivel da Regiao III (Torre
## dos Ecos). Nivel AUTORAL gerado por `tools/construir_n14_campanario.py`.
## Contrato: docs/art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md
## (N14, LOCKED). Desenho e medicoes: docs/nivel_autoral_n14.md.
##
## Prova, com o salto REAL da Koliani, que os portoes do campanario nao se
## saltam nem se escalam: a coluna de ar da camara dos sinos fica longe das
## paredes, os baloicos atravessam um vao sem paredes, a laje C3 fica acima
## do salto (e da face) e o chao da sala do sino gigante esta' preso a'
## parede leste. A logica dos sinos (plataformas temporizadas, corrente que
## muda de direcao) prova-se em fisica no `run_tests.gd`
## (`teste_r3_n14_sinos`), e os portoes no crivo em `teste_r3_n14_portoes_no_crivo`.

const CENA := "res://scenes/levels/Observatorio_Lunar.tscn"
const INDICE_N14 := 13
const LARG := 3400.0
const ALTURA_CORPO := 44.0
const MANTLE := 32.0
const FOLGA := 12.0
## Alcance horizontal do salto duplo + dash, por largo (px).
const ALCANCE_HORIZONTAL := 480.0
const N12 := preload("res://tests/test_region03_n12_level.gd")


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var cena := load(CENA) as PackedScene
	_verificar(falhas, cena != null, "N14: cena carrega")
	if cena == null:
		return falhas
	var raiz := cena.instantiate()

	# --- nivel autoral, sem jornada, sem chefe ---------------------------
	_verificar(falhas, raiz.get("corredor") == false, "N14: sem jornada procedural")
	_verificar(falhas, raiz.get("alongar_plataformas") == false,
		"N14: sem esticao automatico (os portoes dependem das medidas exactas)")
	_verificar(falhas, raiz.get("checkpoints_autorais") == true, "N14: checkpoints autorais")
	_verificar(falhas, raiz.get_node_or_null("Chefe") == null,
		"N14: SEM chefe -- o unico chefe da regiao e' o Vyrak (N15)")
	for filho in raiz.get_children():
		var f := String(filho.scene_file_path)
		_verificar(falhas, not f.contains("/Chefe"),
			"N14: %s instancia um chefe (%s)" % [filho.name, f.get_file()])
		var hab = filho.get("habilidade_id")
		_verificar(falhas, hab == null or String(hab) == "",
			"N14: %s concede uma habilidade -- a regiao so' concede no chefe" % filho.name)

	# --- guardiao: Monge das Correntes elite ------------------------------
	var g := raiz.get_node_or_null("Guardiao")
	_verificar(falhas, g != null, "N14: fecha com um Guardiao")
	if g:
		_verificar(falhas, bool(g.get("elite")), "N14: o Guardiao e' elite")
		_verificar(falhas, String(g.get("especie")) == "monge_das_correntes",
			"N14: o Guardiao e' o Monge das Correntes (inimigo principal do contrato)")
	_verificar(falhas, CatalogoCampanha.CHEFE_KEY[INDICE_N14] == "guard.monge_das_correntes",
		"N14: a HUD/carrossel diz 'Guardiao: Monge das Correntes' (e' `%s`)" % CatalogoCampanha.CHEFE_KEY[INDICE_N14])
	_verificar(falhas, Textos.t("guard.monge_das_correntes") != "guard.monge_das_correntes",
		"N14: nome do guardiao em i18n")
	_verificar(falhas, EstadoJogo.NIVEIS[INDICE_N14] == CENA, "N14: indice 13 aponta para esta cena")

	# --- identidade da regiao -------------------------------------------
	var atm := raiz.get_node_or_null("Atmosfera")
	_verificar(falhas, atm != null and String(atm.get("bioma")) == "torres", "N14: bioma torres")
	_verificar(falhas, atm != null and String(atm.get("fundo_pack")) == "torre_ecos", "N14: fundo torre_ecos")
	_verificar(falhas, String(raiz.get("mecanica_anunciada")) == "vento",
		"N14: anuncia o vento (a mecanica que o canone lhe da')")

	# --- inimigos principais do contrato --------------------------------
	var especies := {}
	for filho in raiz.get_children():
		var e: Variant = filho.get("especie")
		if e != null and String(filho.scene_file_path).ends_with("/DemonioBase.tscn"):
			especies[String(e)] = true
	for e in ["monge_das_correntes", "sino_flutuante", "corvo_do_sino"]:
		_verificar(falhas, especies.has(e), "N14: falta o inimigo principal `%s`" % e)

	# --- mecanicas, unicos e hazards do contrato --------------------------
	var n := {"sino": 0, "temporizada": 0, "balanco": 0, "orbita": 0, "ar": 0, "vento": 0,
		"corrente": 0, "queda": 0, "cruz": 0, "gigante": 0}
	for filho in raiz.get_children():
		var f := String(filho.scene_file_path)
		var sc: Script = filho.get_script()
		var sp := sc.resource_path if sc else ""
		if f.ends_with("/SinoTorre.tscn"):
			n.sino += 1
			_verificar(falhas, filho.get("textura") != null,
				"N14: o sino %s devia usar a arte aprovada" % filho.name)
		elif f.ends_with("/PlataformaSino.tscn"):
			if float(filho.get("duracao_solida")) > 0.0:
				n.temporizada += 1
				_verificar(falhas, filho.get("textura_suporte") != null,
					"N14: %s devia usar a plataforma temporizada da prancha" % filho.name)
		elif sp.ends_with("plataforma_balanco.gd"):
			n.balanco += 1
			_verificar(falhas, filho.get("textura_corrente") != null,
				"N14: %s devia estar pendurado nas correntes da prancha" % filho.name)
		elif sp.ends_with("plataforma_orbita.gd"):
			n.orbita += 1
			_verificar(falhas, filho.get("textura_disco") != null,
				"N14: %s devia ser a plataforma circular da prancha" % filho.name)
		elif sp.ends_with("elevador_coluna.gd"):
			if String(filho.get("grupo_sino")) != "":
				n.corrente += 1
		elif f.ends_with("/CorrenteAr.tscn"):
			n.ar += 1
			_verificar(falhas, filho.get("pele") != null,
				"N14: %s devia usar o updraft da prancha" % filho.name)
		elif sp.ends_with("corrente_lateral.gd"):
			n.vento += 1
			_verificar(falhas, filho.get("pele") != null,
				"N14: %s devia usar o vento da prancha" % filho.name)
		elif f.ends_with("/PedraQueda.tscn"):
			n.queda += 1
			_verificar(falhas, filho.get("textura") != null,
				"N14: %s devia ser o sino em queda da prancha" % filho.name)
		elif f.ends_with("/Serra.tscn"):
			n.cruz += 1
			_verificar(falhas, filho.get("textura") != null,
				"N14: %s devia ser a lamina em cruz da prancha" % filho.name)
		elif f.ends_with("/PenduloLamina.tscn") and String(filho.name) == "SinoGigante":
			n.gigante += 1
	_verificar(falhas, n.sino >= 5, "N14: sinos em sequencia (>= 5), ha' %d" % n.sino)
	_verificar(falhas, n.temporizada >= 6, "N14: plataformas temporizadas (>= 6), ha' %d" % n.temporizada)
	_verificar(falhas, n.balanco >= 3, "N14: plataformas grandes em oscilacao (>= 3), ha' %d" % n.balanco)
	_verificar(falhas, n.orbita >= 3, "N14: a roda de plataformas circulares (>= 3), ha' %d" % n.orbita)
	_verificar(falhas, n.ar >= 2, "N14: vento vertical (>= 2 colunas), ha' %d" % n.ar)
	_verificar(falhas, n.vento >= 1, "N14: vento que empurra")
	_verificar(falhas, n.corrente >= 1, "N14: a corrente que muda de direcao ao som do sino")
	_verificar(falhas, n.queda >= 3, "N14: sinos em queda (>= 3), ha' %d" % n.queda)
	_verificar(falhas, n.cruz >= 2, "N14: laminas em cruz (>= 2), ha' %d" % n.cruz)
	_verificar(falhas, n.gigante == 1, "N14: o sino gigante em movimento (elemento chave)")

	# --- segredos e checkpoints ----------------------------------------
	var segredos := 0
	var checks := 0
	for filho in raiz.get_children():
		if String(filho.name).begins_with("EssenciaSegredo"):
			segredos += 1
		if filho is Area2D and String(filho.name).begins_with("Check"):
			checks += 1
	_verificar(falhas, segredos == 3, "N14: 3 segredos (contrato), ha' %d" % segredos)
	_verificar(falhas, checks >= 5, "N14: >= 5 checkpoints, ha' %d" % checks)

	# --- PORTOES: medidos com o salto real e contra o escalar paredes ------
	var h := N12.alcance_salto_duplo()
	var alcance_topo := h + MANTLE + FOLGA
	# B) a coluna de ar da camara: longe das duas paredes (nao se chega a ela
	# a escalar e saltar), e so' as plataformas da 3.a sequencia la' levam
	var ar := N12._caixa(raiz, "ArCamara")
	if ar.is_empty():
		falhas.append("N14: falta a coluna de ar da camara (ArCamara)")
	else:
		_verificar(falhas, ar.esq - 2260.0 > ALCANCE_HORIZONTAL - 60.0,
			"N14: a coluna de ar esta' perto da parede oeste da camara (%.0f px)" % (ar.esq - 2260.0))
		_verificar(falhas, LARG - ar.dir > ALCANCE_HORIZONTAL,
			"N14: a coluna de ar salta-se da parede leste (%.0f px)" % (LARG - ar.dir))
	# C) os baloicos atravessam um vao aberto, largo demais para o salto
	var c1 := N12._caixa(raiz, "LajeC1")
	var c2 := N12._caixa(raiz, "LajeC2")
	if c1.is_empty() or c2.is_empty():
		falhas.append("N14: faltam as lajes C1/C2 dos baloicos")
	else:
		_verificar(falhas, N12._vao(c1, c2) > ALCANCE_HORIZONTAL * 1.5,
			"N14: o vao dos baloicos salta-se (vao %.0f)" % N12._vao(c1, c2))
	# C3) a roda: a laje C3 fica acima do salto, e a face nao se agarra
	var c3 := N12._caixa(raiz, "LajeC3")
	if not c2.is_empty() and not c3.is_empty():
		_verificar(falhas, c2.topo - c3.topo > alcance_topo,
			"N14: a laje C3 salta-se da C2 (sobe %.0f, alcance %.0f)" % [c2.topo - c3.topo, alcance_topo])
		var cabeca: float = c2.topo - h - ALTURA_CORPO
		_verificar(falhas, cabeca > c3.base + FOLGA * 0.5,
			"N14: a laje C3 escala-se pela face (cabeca a %.0f, face ate' %.0f)" % [cabeca, c3.base])
	# D) o chao da sala do sino gigante: preso a' parede leste (nao se contorna
	# a escalar) e acima do salto da laje C3
	var d := N12._caixa(raiz, "ChaoD")
	if d.is_empty():
		falhas.append("N14: falta o chao da sala do sino gigante (ChaoD)")
	else:
		_verificar(falhas, d.dir >= LARG - 1.0, "N14: o chao D tem de estar preso a' parede leste")
		if not c3.is_empty():
			_verificar(falhas, c3.topo - d.topo > alcance_topo,
				"N14: o chao D salta-se da laje C3 (sobe %.0f)" % (c3.topo - d.topo))
			_verificar(falhas, d.esq > c3.dir,
				"N14: a laje C3 fica por baixo do chao D (a face dele era uma escada)")

	# --- o sino gigante: por cima do Guardiao, alcanca o chao da sala ------
	var sg := raiz.get_node_or_null("SinoGigante") as Node2D
	if sg and g and not d.is_empty():
		_verificar(falhas, absf(sg.position.x - (g as Node2D).position.x) < 500.0,
			"N14: o sino gigante devia baloicar por cima do Guardiao")
		var fundo := sg.position.y + float(sg.get("comprimento")) + float((sg.get("area_lamina") as Vector2).y) * 0.5
		_verificar(falhas, fundo > d.topo - 150.0,
			"N14: o sino gigante nao desce ate' a' altura da Koliani (fundo %.0f)" % fundo)

	raiz.free()
	return falhas


static func _verificar(falhas: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		falhas.append(msg)
