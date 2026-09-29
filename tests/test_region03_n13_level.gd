class_name TestesRegion03N13
extends RefCounted
## Contrato estrutural do N13 -- "Mecanismos Antigos", 3.o nivel da Regiao III
## (Torre dos Ecos). Nivel AUTORAL gerado por `tools/construir_n13_mecanismos.py`.
## Contrato: docs/art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md
## (N13, LOCKED). Desenho e medicoes: docs/nivel_autoral_n13.md.
##
## Prova, com o salto REAL da Koliani (o mesmo `alcance_salto_duplo` do N12),
## que cada travessia "so' com mecanismo" nao se salta: os fossos sao largos
## demais, o tecto baixo das pontes tira o arco do salto e a prateleira da
## alavanca C esta' fora do alcance (e da face da cabeca, que ela escala).
## A logica dos mecanismos (alavancas, pontes, padrao dos sinos) prova-se
## em fisica no `run_tests.gd` (`teste_r3_n13_mecanismos`).

const CENA := "res://scenes/levels/Torre_da_Tempestade.tscn"
const INDICE_N13 := 12
const ALTURA_CORPO := 44.0
const MANTLE := 32.0
const FOLGA := 12.0
## Alcance horizontal do salto duplo + dash, por largo (px). Um vao maior
## do que isto nao se atravessa sem o mecanismo.
const ALCANCE_HORIZONTAL := 480.0
const N12 := preload("res://tests/test_region03_n12_level.gd")


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var cena := load(CENA) as PackedScene
	_verificar(falhas, cena != null, "N13: cena carrega")
	if cena == null:
		return falhas
	var raiz := cena.instantiate()

	# --- nivel autoral, sem jornada, sem chefe ---------------------------
	_verificar(falhas, raiz.get("corredor") == false, "N13: sem jornada procedural")
	_verificar(falhas, raiz.get("alongar_plataformas") == false,
		"N13: sem esticao automatico (os portoes dependem das medidas exactas)")
	_verificar(falhas, raiz.get("checkpoints_autorais") == true, "N13: checkpoints autorais")
	_verificar(falhas, raiz.get_node_or_null("Chefe") == null,
		"N13: SEM chefe -- o unico chefe da regiao e' o Vyrak (N15)")
	for filho in raiz.get_children():
		var f := String(filho.scene_file_path)
		_verificar(falhas, not f.contains("/Chefe"),
			"N13: %s instancia um chefe (%s)" % [filho.name, f.get_file()])
		var hab = filho.get("habilidade_id")
		_verificar(falhas, hab == null or String(hab) == "",
			"N13: %s concede uma habilidade -- a regiao so' concede no chefe" % filho.name)

	# --- guardiao: Construto Vitral elite -------------------------------
	var g := raiz.get_node_or_null("Guardiao")
	_verificar(falhas, g != null, "N13: fecha com um Guardiao")
	if g:
		_verificar(falhas, bool(g.get("elite")), "N13: o Guardiao e' elite")
		_verificar(falhas, String(g.get("especie")) == "construto_vitral",
			"N13: o Guardiao e' o Construto Vitral (inimigo principal do contrato)")
	_verificar(falhas, CatalogoCampanha.CHEFE_KEY[INDICE_N13] == "guard.construto_vitral",
		"N13: a HUD/carrossel diz 'Guardiao: Construto Vitral' (e' `%s`)" % CatalogoCampanha.CHEFE_KEY[INDICE_N13])
	_verificar(falhas, Textos.t("guard.construto_vitral") != "guard.construto_vitral",
		"N13: nome do guardiao em i18n")
	_verificar(falhas, EstadoJogo.NIVEIS[INDICE_N13] == CENA, "N13: indice 12 aponta para esta cena")

	# --- identidade da regiao -------------------------------------------
	var atm := raiz.get_node_or_null("Atmosfera")
	_verificar(falhas, atm != null and String(atm.get("bioma")) == "torres", "N13: bioma torres")
	_verificar(falhas, atm != null and String(atm.get("fundo_pack")) == "torre_ecos", "N13: fundo torre_ecos")
	_verificar(falhas, String(raiz.get("mecanica_anunciada")) == "engrenagens",
		"N13: anuncia as engrenagens (a mecanica que o canone lhe da')")

	# --- inimigos principais do contrato --------------------------------
	var especies := {}
	for filho in raiz.get_children():
		var e: Variant = filho.get("especie")
		if e != null and String(filho.scene_file_path).ends_with("/DemonioBase.tscn"):
			especies[String(e)] = true
	for e in ["automato_do_sino", "construto_vitral", "espirito_do_eco"]:
		_verificar(falhas, especies.has(e), "N13: falta o inimigo principal `%s`" % e)

	# --- mecanicas e unicos do contrato ---------------------------------
	var n := {"roda": 0, "alavanca": 0, "grade": 0, "sino": 0, "eco": 0, "corrente": 0,
		"elev": 0, "quebra": 0, "pend": 0, "serra": 0, "espinhos": 0, "gira": 0}
	for filho in raiz.get_children():
		var f := String(filho.scene_file_path)
		var sc: Script = filho.get_script()
		var sp := sc.resource_path if sc else ""
		if sp.ends_with("plataforma_roda.gd"):
			n.roda += 1
			_verificar(falhas, filho.get("textura_roda") != null,
				"N13: %s devia usar a roda de engrenagem da prancha" % filho.name)
		elif sp.ends_with("engrenagem_deco.gd"):
			n.gira += 1
		elif f.ends_with("/Alavanca.tscn") and not sp.ends_with("mecanismo_sinos.gd"):
			n.alavanca += 1
			_verificar(falhas, filho.get("textura") != null,
				"N13: %s devia usar a alavanca da prancha" % filho.name)
		elif f.ends_with("/PortaTrancada.tscn"):
			n.grade += 1
			_verificar(falhas, filho.get("textura") != null,
				"N13: %s devia vestir o bronze da prancha" % filho.name)
		elif f.ends_with("/SinoTorre.tscn"):
			n.sino += 1
			_verificar(falhas, filho.get("textura") != null,
				"N13: o sino %s devia usar a arte aprovada" % filho.name)
		elif f.ends_with("/PlataformaSino.tscn"):
			n.eco += 1
		elif f.ends_with("/PlataformaCorrente.tscn"):
			n.corrente += 1
			_verificar(falhas, String(filho.get("modo")) == "horizontal",
				"N13: a ponte movel corre na horizontal")
		elif f.ends_with("/TumuloElevador.tscn"):
			n.elev += 1
			_verificar(falhas, sp.ends_with("elevador_coluna.gd"),
				"N13: %s devia vestir o ElevadorColuna" % filho.name)
			_verificar(falhas, filho.get("textura_contrapeso") != null,
				"N13: %s devia ter o contrapeso da prancha" % filho.name)
		elif f.ends_with("/PlataformaQuebra.tscn"):
			n.quebra += 1
		elif f.ends_with("/PenduloLamina.tscn"):
			n.pend += 1
		elif f.ends_with("/Serra.tscn"):
			n.serra += 1
			_verificar(falhas, filho.get("textura") != null,
				"N13: %s devia ser a engrenagem mortal da prancha" % filho.name)
		elif f.ends_with("/Espinhos.tscn"):
			n.espinhos += 1
	_verificar(falhas, n.roda >= 3, "N13: rodas de engrenagem (>= 3), ha' %d" % n.roda)
	_verificar(falhas, n.alavanca >= 5, "N13: alavancas multiplas (>= 5), ha' %d" % n.alavanca)
	_verificar(falhas, n.grade >= 4, "N13: portas de mecanismo (>= 4), ha' %d" % n.grade)
	_verificar(falhas, n.sino == 3, "N13: o mecanismo central tem 3 sinos, ha' %d" % n.sino)
	_verificar(falhas, n.eco >= 2, "N13: pontes reconfiguraveis (>= 2), ha' %d" % n.eco)
	_verificar(falhas, n.corrente >= 1, "N13: falta a ponte movel")
	_verificar(falhas, n.elev >= 2, "N13: 2 elevadores de contrapeso, ha' %d" % n.elev)
	_verificar(falhas, n.quebra >= 6, "N13: piso que colapsa (>= 6), ha' %d" % n.quebra)
	_verificar(falhas, n.pend >= 4, "N13: laminas em pendulo e correntes com peso (>= 4), ha' %d" % n.pend)
	_verificar(falhas, n.serra >= 1, "N13: engrenagem mortal")
	_verificar(falhas, n.gira >= 6, "N13: engrenagens giratorias no cenario (>= 6), ha' %d" % n.gira)
	var nucleo := raiz.get_node_or_null("Nucleo")
	_verificar(falhas, nucleo != null and String((nucleo.get_script() as Script).resource_path).ends_with("mecanismo_sinos.gd"),
		"N13: o mecanismo central de 3 sinos")
	if nucleo:
		_verificar(falhas, (nucleo.get("sinos") as Array).size() == 3, "N13: o nucleo liga 3 sinos")
		_verificar(falhas, String(nucleo.get("id")) == "nucleo", "N13: o nucleo abre a PortaNucleo")
	var pn := raiz.get_node_or_null("PortaNucleo")
	_verificar(falhas, pn != null and String(pn.get("id")) == "nucleo",
		"N13: a sala do guardiao fecha-se com a porta do nucleo")

	# --- segredos e checkpoints ----------------------------------------
	var segredos := 0
	var checks := 0
	for filho in raiz.get_children():
		if String(filho.name).begins_with("EssenciaSegredo"):
			segredos += 1
		if filho is Area2D and String(filho.name).begins_with("Check"):
			checks += 1
	_verificar(falhas, segredos == 3, "N13: 3 segredos (contrato), ha' %d" % segredos)
	_verificar(falhas, checks >= 5, "N13: >= 5 checkpoints, ha' %d" % checks)

	# --- TRAVESSIAS: medidas com o salto real -----------------------------
	var h := N12.alcance_salto_duplo()
	var alcance_topo := h + MANTLE + FOLGA
	# fossos que so' os mecanismos atravessam: [margem esquerda, direita, o que]
	for p in [["Chao1", "Chao2a", "engrenagens"], ["Laje12a", "Laje12b", "ponte movel"],
			["Laje23b", "Laje23c", "piso que colapsa D1"]]:
		var a := N12._caixa(raiz, String(p[0]))
		var b := N12._caixa(raiz, String(p[1]))
		if a.is_empty() or b.is_empty():
			falhas.append("N13: travessia %s -- falta %s ou %s" % [p[2], p[0], p[1]])
			continue
		if p[2] == "piso que colapsa D1":
			continue  # o piso colapsa POR CIMA do fosso -- basta que exista
		_verificar(falhas, N12._vao(a, b) > ALCANCE_HORIZONTAL,
			"N13: o fosso das %s salta-se (vao %.0f)" % [p[2], N12._vao(a, b)])
	# pontes reconfiguraveis: tecto baixo -- sem arco de salto
	var teto := N12._caixa(raiz, "TetoBaixo")
	var pd := N12._caixa(raiz, "PonteDireita")
	if not teto.is_empty() and not pd.is_empty():
		var folga: float = pd.topo - teto.base
		_verificar(falhas, folga < ALTURA_CORPO * 3.0,
			"N13: o tecto das pontes deixa saltar (folga %.0f)" % folga)
		_verificar(falhas, folga > ALTURA_CORPO + 20.0,
			"N13: o tecto das pontes esmaga a Koliani (folga %.0f)" % folga)
		_verificar(falhas, teto.esq <= pd.esq - 275.0 - 20.0 and teto.dir >= pd.dir + 40.0,
			"N13: o tecto baixo tem de cobrir as duas pontes e a entrada")
	# prateleira da alavanca C: fora do salto E da face (escalar_paredes)
	var chao_c := N12._caixa(raiz, "Laje12a")
	var prat := N12._caixa(raiz, "PrateleiraC")
	if not chao_c.is_empty() and not prat.is_empty():
		_verificar(falhas, chao_c.topo - prat.topo > alcance_topo,
			"N13: a prateleira C salta-se do chao (sobe %.0f, alcance %.0f)" % [
				chao_c.topo - prat.topo, alcance_topo])
		var cabeca: float = chao_c.topo - h - ALTURA_CORPO
		_verificar(falhas, cabeca > prat.base + FOLGA * 0.5,
			"N13: a prateleira C escala-se pela face (cabeca a %.0f, face ate' %.0f)" % [
				cabeca, prat.base])
	# os furos dos elevadores ficam DEPOIS das portas
	var pb := raiz.get_node_or_null("PortaB") as Node2D
	var e1 := raiz.get_node_or_null("Elevador1") as Node2D
	if pb and e1:
		_verificar(falhas, e1.position.x > pb.position.x + 60.0, "N13: o elevador 1 fica depois da porta B")
	var pc := raiz.get_node_or_null("PortaC") as Node2D
	var e2 := raiz.get_node_or_null("Elevador2") as Node2D
	if pc and e2:
		_verificar(falhas, e2.position.x < pc.position.x - 60.0, "N13: o elevador 2 fica depois da porta C")
	# as portas de mecanismo vao do chao ao tecto (nao se salta por cima)
	for nome in ["PortaA", "PortaB", "PortaC", "PortaNucleo"]:
		var p := raiz.get_node_or_null(nome) as Node2D
		if p == null:
			falhas.append("N13: falta %s" % nome)
			continue
		var tam: Vector2 = p.get("tamanho")
		_verificar(falhas, tam.y >= 430.0, "N13: %s nao chega ao tecto (%.0f px)" % [nome, tam.y])

	# --- ensino sem pressao: nenhum inimigo perto da 1.a alavanca e da 1.a
	# engrenagem ----------------------------------------------------------
	for filho in raiz.get_children():
		if not String(filho.scene_file_path).ends_with("/DemonioBase.tscn"):
			continue
		for k in ["AlavancaA", "RodaA1"]:
			var d := (filho as Node2D).position.distance_to((raiz.get_node(k) as Node2D).position)
			_verificar(falhas, d >= 400.0,
				"N13: %s a %.0f px de %s (ensino devia ser sem pressao)" % [filho.name, d, k])

	raiz.free()
	return falhas


static func _verificar(falhas: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		falhas.append(msg)
