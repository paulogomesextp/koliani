class_name TestesRegion03N11
extends RefCounted
## Contrato estrutural do N11 -- "Entrada dos Ecos", primeiro nível da
## Região III (TORRE DOS ECOS). Auditoria/reconstrução pedida pelo GM em
## 28 set 2026: nível AUTORAL introdutório, sem chefe, sem jornada
## procedural, que ensina `escalar_paredes` (concedida no N10) e a
## linguagem dos sinos. Não certifica sensação nem substitui jogar.

const CENA := "res://scenes/levels/Torre_dos_Sinos.tscn"
const INDICE_N11 := 10
const CHEFE_ANTIGO := "res://scenes/actors/ChefeSinoVivo.tscn"


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var cena := load(CENA) as PackedScene
	_verificar(falhas, cena != null, "N11: cena carrega")
	if cena == null:
		return falhas
	var raiz := cena.instantiate()

	# --- nível autoral, sem jornada procedural, sem boss -----------------
	_verificar(falhas, raiz.get("corredor") == false,
		"N11: sem jornada procedural (nível feito à mão)")
	_verificar(falhas, raiz.get("checkpoints_autorais") == true,
		"N11: checkpoints autorais (não se podam por distância)")
	_verificar(falhas, raiz.get_node_or_null("Chefe") == null,
		"N11: SEM chefe -- é introdução da região, Vyrak só aparece no N15")
	_verificar(falhas, raiz.get_node_or_null("Guardiao") == null,
		"N11: SEM guardião (miniboss disfarçado) -- também proibido pelo GM")
	for filho in raiz.get_children():
		_verificar(falhas, filho.scene_file_path != CHEFE_ANTIGO,
			"N11: %s ainda instancia o chefe antigo (Sino Vivo)" % filho.name)

	# a porta não pode ficar selada -- sem chefe/guardião, NivelComChefe
	# abre-a logo (`_selar(false)`); é só a saída do nível.
	var porta := raiz.get_node_or_null("Porta") as Area2D
	_verificar(falhas, porta != null, "N11: porta presente")

	# --- escalar_paredes já está disponível ao entrar no N11 -------------
	# (concedida, incondicional, ao vencer o chefe do N10 -- HABILIDADE_DO_CHEFE[9])
	var script_niv := load("res://scripts/nivel_com_chefe.gd")
	_verificar(falhas,
		script_niv.HABILIDADE_DO_CHEFE.get(9, "") == "escalar_paredes",
		"N11: escalar_paredes continua concedida no N10 (não alterado)")
	_verificar(falhas, Textos.t("mec.escalar_paredes.nome") != "mec.escalar_paredes.nome",
		"N11: texto i18n do tutorial de escalar_paredes existe")
	_verificar(falhas, Textos.t("mec.escalar_paredes.txt") != "mec.escalar_paredes.txt",
		"N11: texto i18n do tutorial de escalar_paredes (corpo) existe")
	# nenhum nó volta a CONCEDER a habilidade (isso já aconteceu no N10) --
	# um 2º coletável com o mesmo habilidade_id era só ruído/redundância.
	for filho in raiz.get_children():
		if filho.get("habilidade_id") == "escalar_paredes":
			falhas.append("N11: %s volta a conceder escalar_paredes (redundante, já vem do N10)" % filho.name)

	# --- primeiro obstáculo de escalada: zona segura, chão por baixo ------
	var parede := raiz.get_node_or_null("ParedeSubida") as Node2D
	_verificar(falhas, parede != null, "N11: existe um muro para a primeira escalada")
	var chao_inicio := raiz.get_node_or_null("ChaoInicio") as Node2D
	if parede != null and chao_inicio != null:
		var tam_p := parede.get("tamanho") as Vector2
		var tam_c := chao_inicio.get("tamanho") as Vector2
		var topo_muro: float = parede.position.y - tam_p.y * 0.5
		var base_muro: float = parede.position.y + tam_p.y * 0.5
		var topo_chao: float = chao_inicio.position.y - tam_c.y * 0.5
		# o muro tem de ser suficientemente alto para não ser um jump normal,
		# mas "pequeno" (o GM pediu "nenhuma escalada longa").
		var altura_escalada := base_muro - topo_muro
		_verificar(falhas, altura_escalada >= 120.0 and altura_escalada <= 320.0,
			"N11: a 1ª escalada é pequena (medida %.0f px, esperado 120-320)" % altura_escalada)
		# zona segura: o muro nasce em cima (ou muito perto) do chão de
		# entrada -- uma queda a meio da escalada não pode ser fatal.
		_verificar(falhas, base_muro >= topo_chao - 10.0,
			"N11: o muro assenta sobre/junto do chão de entrada (sem vazio por baixo)")
	# sem inimigos perto do muro (regra do GM: nenhum durante a 1ª escalada).
	# distância 2D (não só x): o nível é uma TORRE vertical, um inimigo dois
	# andares acima/abaixo não "interrompe" a escalada mesmo que o x seja
	# parecido.
	if parede != null:
		for filho in raiz.get_children():
			if filho is DemonioBase:
				var d: float = (filho as Node2D).position.distance_to(parede.position)
				_verificar(falhas, d > 140.0,
					"N11: %s está perto demais do muro de escalada (d=%.0f)" % [filho.name, d])

	# --- primeiro sino: efeito legível e imediato -------------------------
	var sino_baixo := raiz.get_node_or_null("SinoBaixo") as SinoTorre
	_verificar(falhas, sino_baixo != null, "N11: SinoBaixo presente (primeiro sino)")
	var eco_baixo := raiz.get_node_or_null("EcoBaixo")
	_verificar(falhas, eco_baixo != null, "N11: EcoBaixo presente (consequência visível do 1º sino)")
	if sino_baixo != null and eco_baixo != null:
		_verificar(falhas, eco_baixo.get("grupo_alternar") == sino_baixo.alterna_grupo,
			"N11: EcoBaixo está no mesmo grupo que o SinoBaixo alterna")
	if eco_baixo != null:
		var col_eco := eco_baixo.get_node_or_null("Col") as CollisionShape2D
		_verificar(falhas, col_eco != null and col_eco.disabled,
			"N11: EcoBaixo começa fantasma (sem colisão) até o sino tocar")
	# sem inimigos junto do primeiro sino (regra do GM) -- distância 2D pela
	# mesma razão do muro (torre vertical).
	if sino_baixo != null:
		for filho in raiz.get_children():
			if filho is DemonioBase:
				var d2: float = (filho as Node2D).position.distance_to(sino_baixo.position)
				_verificar(falhas, d2 > 140.0,
					"N11: %s está perto demais do 1º sino (d=%.0f)" % [filho.name, d2])

	# --- 2º sino + movimento (secção E) -----------------------------------
	var sino_alto := raiz.get_node_or_null("SinoAlto") as SinoTorre
	var eco_alto := raiz.get_node_or_null("EcoAlto")
	if sino_alto != null and eco_alto != null:
		_verificar(falhas, sino_alto.alterna_grupo != sino_baixo.alterna_grupo if sino_baixo else true,
			"N11: o 2º sino usa um grupo diferente do 1º (cada um legível por si)")
		_verificar(falhas, eco_alto.get("grupo_alternar") == sino_alto.alterna_grupo,
			"N11: EcoAlto está no grupo do SinoAlto")

	# --- plataformas oscilantes: trajetória legível, sem nada aleatório ---
	var oscilantes: Array[Node] = []
	for filho in raiz.get_children():
		if filho is PlataformaFlutuante:
			oscilantes.append(filho)
	_verificar(falhas, oscilantes.size() >= 2,
		"N11: pelo menos 2 plataformas oscilantes (introdução + progressão) -- achadas %d" % oscilantes.size())
	for p in oscilantes:
		_verificar(falhas, float(p.get("balanco")) > 0.0 and float(p.get("periodo")) > 0.5,
			"N11: %s tem baloiço e período legíveis (sem física aleatória)" % p.name)
	# nenhum inimigo pousado exatamente na aterragem de uma oscilante
	for p in oscilantes:
		for filho in raiz.get_children():
			if filho is DemonioBase:
				var d3: float = (filho.position as Vector2).distance_to(p.position)
				_verificar(falhas, d3 > 90.0,
					"N11: %s está em cima da aterragem de %s" % [filho.name, p.name])

	# --- checkpoints autorais: nunca em cima de plataforma móvel ----------
	var checks: Array[Node2D] = []
	for filho in raiz.get_children():
		if filho.name.begins_with("Check"):
			checks.append(filho as Node2D)
	_verificar(falhas, checks.size() >= 2, "N11: pelo menos 2 fogueiras autorais (achadas %d)" % checks.size())
	for c in checks:
		for p in oscilantes:
			var d4: float = c.position.distance_to(p.position)
			_verificar(falhas, d4 > 60.0,
				"N11: fogueira %s está em cima de uma plataforma oscilante (%s)" % [c.name, p.name])

	# --- correntes / identidade visual: bioma correto para a decoração ----
	var atm := raiz.get_node_or_null("Atmosfera")
	if atm:
		_verificar(falhas, str(atm.get("bioma")) == "torres",
			"N11: bioma 'torres' (o catálogo de deco tem correntes penduradas para ele)")
		_verificar(falhas, str(atm.get("fundo_pack")) == "torre_ecos",
			"N11: fundo com a identidade visual de eco da região")

	# --- elite fora das zonas de aprendizagem -----------------------------
	var elite := raiz.get_node_or_null("EliteAcolito")
	_verificar(falhas, elite != null, "N11: um elite (poucos inimigos, nível introdutório)")

	# --- nome do mundo / região --------------------------------------------
	_verificar(falhas, Textos.t("world.towers") != "world.towers",
		"N11: o nome da região (Torre dos Ecos) tem texto em i18n")

	# --- Koliani canónica ---------------------------------------------------
	var k := raiz.get_node_or_null("Koliani")
	if k:
		_verificar(falhas, k.get("usar_golden_set") == true, "N11: Koliani canónica (Golden Set)")
		_verificar(falhas, k.get("usar_prototipo_premium") == true, "N11: Koliani canónica (protótipo premium)")

	raiz.free()
	return falhas


static func _verificar(falhas: Array[String], condicao: bool, rotulo: String) -> void:
	if not condicao:
		falhas.append(rotulo)
