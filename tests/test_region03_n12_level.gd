class_name TestesRegion03N12
extends RefCounted
## Contrato estrutural do N12 -- "Galerias Verticais", 2.o nivel da Regiao III
## (Torre dos Ecos). Nivel AUTORAL gerado por `tools/construir_n12_galerias.py`.
## Contrato: docs/art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md
## (N12, LOCKED). Desenho e medicoes: docs/nivel_autoral_n12.md.
##
## O que isto prova e o crivo de alcance nao: que os PORTOES (elevadores,
## sinos, vitral, coluna de ar, degraus quebradicos) sao mesmo precisos --
## medido com o salto REAL da Koliani (`Movimento`, salto duplo + mantle) e
## com o `escalar_paredes` que ela ja' tem (uma face de parede ao alcance
## da cabeca e' um atalho, porque ela sobe qualquer parede).
## Nao certifica sensacao nem substitui jogar.

const CENA := "res://scenes/levels/Torre_dos_Ventos.tscn"
const INDICE_N12 := 11
## Altura da Koliani (px) -- a cabeca fica isto acima dos pes.
const ALTURA_CORPO := 44.0
## O mantle (`koliani.gd::MANTLE_ALTURA`) sobe um rebordo ate' tanto acima
## dos pes -- soma-se ao salto quando o alvo e' um TOPO.
const MANTLE := 32.0
## Folga minima pedida a cada portao, alem do alcance medido.
const FOLGA := 12.0


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var cena := load(CENA) as PackedScene
	_verificar(falhas, cena != null, "N12: cena carrega")
	if cena == null:
		return falhas
	var raiz := cena.instantiate()

	# --- nivel autoral, sem jornada, sem chefe ---------------------------
	_verificar(falhas, raiz.get("corredor") == false, "N12: sem jornada procedural")
	_verificar(falhas, raiz.get("alongar_plataformas") == false,
		"N12: sem esticao automatico (os portoes dependem das medidas exactas)")
	_verificar(falhas, raiz.get("checkpoints_autorais") == true, "N12: checkpoints autorais")
	_verificar(falhas, raiz.get_node_or_null("Chefe") == null,
		"N12: SEM chefe -- o unico chefe da regiao e' o Vyrak (N15)")
	for filho in raiz.get_children():
		var f := String(filho.scene_file_path)
		_verificar(falhas, not f.contains("/Chefe"),
			"N12: %s instancia um chefe (%s)" % [filho.name, f.get_file()])
		_verificar(falhas, not f.ends_with("/Fogo.tscn"), "N12: fogo herdado em %s" % filho.name)
		var hab = filho.get("habilidade_id")
		_verificar(falhas, hab == null or String(hab) == "",
			"N12: %s concede uma habilidade -- a regiao so' concede no chefe" % filho.name)

	# --- guardiao: Autómato do Sino elite, sela a porta -----------------
	var g := raiz.get_node_or_null("Guardiao")
	_verificar(falhas, g != null, "N12: fecha com um Guardiao")
	if g:
		_verificar(falhas, bool(g.get("elite")), "N12: o Guardiao e' elite")
		_verificar(falhas, String(g.get("especie")) == "automato_do_sino",
			"N12: o Guardiao e' o Autómato do Sino (inimigo principal do contrato)")
	_verificar(falhas, CatalogoCampanha.CHEFE_KEY[INDICE_N12] == "guard.automato_do_sino",
		"N12: a HUD/carrossel diz 'Guardiao: Autómato do Sino' (e' `%s`)" % CatalogoCampanha.CHEFE_KEY[INDICE_N12])
	_verificar(falhas, Textos.t("guard.automato_do_sino") != "guard.automato_do_sino",
		"N12: nome do guardiao em i18n")
	_verificar(falhas, EstadoJogo.NIVEIS[INDICE_N12] == CENA, "N12: indice 11 aponta para esta cena")

	# --- identidade da regiao -------------------------------------------
	var atm := raiz.get_node_or_null("Atmosfera")
	_verificar(falhas, atm != null and String(atm.get("bioma")) == "torres", "N12: bioma torres")
	_verificar(falhas, atm != null and String(atm.get("fundo_pack")) == "torre_ecos", "N12: fundo torre_ecos")
	for m in ["mec.elevador_coluna.nome", "mec.elevador_coluna.txt"]:
		_verificar(falhas, Textos.t(m) != m, "N12: texto i18n `%s`" % m)
	_verificar(falhas, String(raiz.get("mecanica_anunciada")) == "elevador_coluna",
		"N12: anuncia o elevador de coluna (e nao as 'lajes de tumulo' do N16)")

	# --- inimigos principais do contrato --------------------------------
	var especies := {}
	for filho in raiz.get_children():
		var e: Variant = filho.get("especie")
		if e != null and String(filho.scene_file_path).ends_with("/DemonioBase.tscn"):
			especies[String(e)] = true
	for e in ["gargula_vitral", "automato_do_sino", "monge_das_correntes"]:
		_verificar(falhas, especies.has(e), "N12: falta o inimigo principal `%s`" % e)

	# --- mecanicas do contrato -----------------------------------------
	var n_elev := 0
	var n_quebra := 0
	var n_ritmo := 0
	var n_ar := 0
	var n_serra := 0
	var n_pend := 0
	var n_vento := 0
	for filho in raiz.get_children():
		var f := String(filho.scene_file_path)
		if f.ends_with("/TumuloElevador.tscn"):
			n_elev += 1
			_verificar(falhas, String((filho.get_script() as Script).resource_path).ends_with("elevador_coluna.gd"),
				"N12: %s devia vestir o ElevadorColuna (corrente + roldana)" % filho.name)
		elif f.ends_with("/PlataformaQuebra.tscn"):
			n_quebra += 1
			_verificar(falhas, bool(filho.get("pele_terreno")),
				"N12: %s devia usar a pele de terreno (nao a laje lisa)" % filho.name)
		elif f.ends_with("/PlataformaRitmada.tscn"):
			n_ritmo += 1
		elif f.ends_with("/CorrenteAr.tscn"):
			n_ar += 1
		elif f.ends_with("/Serra.tscn"):
			n_serra += 1
		elif f.ends_with("/PenduloLamina.tscn"):
			n_pend += 1
		elif f.ends_with("/WindZone.tscn"):
			n_vento += 1
	_verificar(falhas, n_elev >= 2, "N12: 2 elevadores de coluna (peso + vaivem), ha' %d" % n_elev)
	_verificar(falhas, n_quebra >= 4, "N12: escadas quebradas (>= 4 degraus), ha' %d" % n_quebra)
	_verificar(falhas, n_ritmo >= 3, "N12: plataformas que desaparecem (>= 3), ha' %d" % n_ritmo)
	_verificar(falhas, n_ar >= 1 and n_vento >= 1, "N12: seccao de vento (coluna de ar + vento contra)")
	_verificar(falhas, n_serra + n_pend >= 2, "N12: laminas rapidas (>= 2)")

	# --- segredos e checkpoints ----------------------------------------
	var segredos := 0
	for filho in raiz.get_children():
		if String(filho.name).begins_with("EssenciaSegredo"):
			segredos += 1
	_verificar(falhas, segredos == 3, "N12: 3 segredos (contrato), ha' %d" % segredos)
	var checks := 0
	for filho in raiz.get_children():
		if filho is Area2D and String(filho.name).begins_with("Check"):
			checks += 1
	_verificar(falhas, checks >= 5, "N12: >= 5 checkpoints, ha' %d" % checks)

	# --- PORTOES: medidos com o salto real --------------------------------
	var h := alcance_salto_duplo()
	_verificar(falhas, h > 200.0 and h < 300.0,
		"N12: o salto duplo medido (%.0f px) saiu do intervalo esperado" % h)
	var alcance_topo := h + MANTLE + FOLGA
	# [baixo, cima, o que o portao ensina]
	var portoes := [
		["ChaoBase", "A2", "elevador 1"],
		["A2", "A3", "sino A"],
		["R3", "R4", "elevador 2"],
		["PonteAlta", "C1", "coluna de ar"],
		["Rede", "D1", "queda controlada"],
		["VarandaD", "GaleriaSuperior", "sino B"],
		["D1", "GaleriaSuperior", "sino B"],
		["PisoPoco", "Patamar1", "escadas"],
	]
	for p in portoes:
		var a := _caixa(raiz, String(p[0]))
		var b := _caixa(raiz, String(p[1]))
		if a.is_empty() or b.is_empty():
			falhas.append("N12: portao %s -- falta %s ou %s" % [p[2], p[0], p[1]])
			continue
		var vao := _vao(a, b)
		var subida: float = a.topo - b.topo
		if vao <= 240.0:
			_verificar(falhas, subida > alcance_topo,
				"N12: portao '%s' salta-se (%s -> %s sobe %.0f, alcance %.0f)" % [
					p[2], p[0], p[1], subida, alcance_topo])
		# a face de `b` so' se agarra (escalar_paredes) se a cabeca la' chegar
		if vao <= 60.0:
			var cabeca: float = a.topo - h - ALTURA_CORPO
			_verificar(falhas, cabeca > b.base + FOLGA * 0.5,
				"N12: portao '%s' escala-se pela face de %s (cabeca a %.0f, face ate' %.0f)" % [
					p[2], p[1], cabeca, b.base])

	# vitral: o tecto (Rede) nao deixa saltar por cima dele a partir do R4
	var r4 := _caixa(raiz, "R4")
	var rede := _caixa(raiz, "Rede")
	var vit := raiz.get_node_or_null("VitralGalerias") as Node2D
	if not r4.is_empty() and not rede.is_empty() and vit:
		var alt_vit: float = 132.0 * vit.scale.y
		var topo_vit: float = vit.position.y - alt_vit * 0.5
		var pes_max: float = maxf(r4.topo - h, rede.base + ALTURA_CORPO)
		_verificar(falhas, pes_max > topo_vit + 8.0,
			"N12: salta-se por cima do vitral (pes a %.0f, topo do vitral %.0f)" % [pes_max, topo_vit])
		_verificar(falhas, rede.esq - (vit.position.x + 14.0 * vit.scale.x) < ALTURA_CORPO * 0.5,
			"N12: ha' uma fresta entre o vitral e a Rede por onde se passa")

	# --- ensino sem pressao: nenhum inimigo perto dos elementos novos ----
	var ensino := {
		"Elevador1": (raiz.get_node("Elevador1") as Node2D).position,
		"SinoA": (raiz.get_node("SinoA") as Node2D).position,
		"PonteA3": (raiz.get_node("PonteA3") as Node2D).position,
		"Elevador2": (raiz.get_node("Elevador2") as Node2D).position,
	}
	for filho in raiz.get_children():
		if not String(filho.scene_file_path).ends_with("/DemonioBase.tscn"):
			continue
		for k in ensino:
			var d := (filho as Node2D).position.distance_to(ensino[k])
			_verificar(falhas, d >= 140.0,
				"N12: %s a %.0f px de %s (ensino devia ser sem pressao)" % [filho.name, d, k])

	raiz.free()
	return falhas


## Subida maxima (px) de um salto duplo com o botao seguro, segundo salto no
## melhor frame -- a mesma logica pura que a Koliani corre (`Movimento`).
static func alcance_salto_duplo() -> float:
	const DT := 1.0 / 60.0
	var melhor := 0.0
	for frame_2o in range(4, 60):
		var e := Movimento.Estado.new()
		Movimento.passo(e, 0.0, false, false, true, DT, 2)
		Movimento.passo(e, 0.0, true, true, false, DT, 2)
		var y := 0.0
		var min_y := 0.0
		for i in 180:
			var carrega := (i == frame_2o)
			Movimento.passo(e, 0.0, carrega, true, false, DT, 2)
			y += e.velocidade.y * DT
			min_y = minf(min_y, y)
			if e.velocidade.y > 0.0 and i > frame_2o:
				break
		melhor = maxf(melhor, -min_y)
	return melhor


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


static func _vao(a: Dictionary, b: Dictionary) -> float:
	if b.esq > a.dir:
		return b.esq - a.dir
	if a.esq > b.dir:
		return a.esq - b.dir
	return 0.0


static func _verificar(falhas: Array[String], cond: bool, msg: String) -> void:
	if not cond:
		falhas.append(msg)
