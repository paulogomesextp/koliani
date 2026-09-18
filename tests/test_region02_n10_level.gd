class_name TestesRegion02N10
extends RefCounted
## Contrato estrutural do PROCESS 12 (N10 -- exame final da Região II +
## Guardião dos Céus). Não certifica sensação nem substitui jogar: trava a
## identidade do chefe, o vento do exame, a arena, as fogueiras, a porta e a
## recompensa. O comportamento da luta (dano, morte, fase 2, telégrafos,
## limpeza do vento) vive no harness `tests/run_boss_guardiao_ceus.gd`.

const CENA := "res://scenes/levels/A_Cela_Zero.tscn"
const CHEFE_NOVO := "res://scenes/actors/ChefeGuardiaoDosCeus.tscn"
const CHEFE_ANTIGO := "res://scenes/actors/ChefePrimeiroPrisioneiro.tscn"
const INDICE_N10 := 9


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var cena := load(CENA) as PackedScene
	_verificar(falhas, cena != null, "N10: cena carrega")
	if cena == null:
		return falhas
	var raiz := cena.instantiate()

	# --- sala do exame, não jornada procedural -------------------------
	_verificar(falhas, raiz.get("corredor") == false,
		"N10: exame feito à mão (sem jornada procedural)")
	_verificar(falhas, raiz.get("alongar_plataformas") == false,
		"N10: vãos medidos -- o esticão automático não mexe no exame")
	_verificar(falhas, raiz.get("mecanica_anunciada") == "vento",
		"N10: anuncia a mecânica da região (vento)")

	for nome in ["Koliani", "Porta", "Chefe", "ColProjetil", "Acido", "EliteOrc"]:
		_verificar(falhas, raiz.get_node_or_null(nome) != null, "N10: %s presente" % nome)

	# --- identidade do chefe -------------------------------------------
	var chefe := raiz.get_node_or_null("Chefe")
	if chefe:
		_verificar(falhas, chefe.scene_file_path == CHEFE_NOVO,
			"N10: o chefe final é o Guardião dos Céus (%s)" % chefe.scene_file_path)
		_verificar(falhas, chefe is ChefeGuardiaoDosCeus,
			"N10: o nó Chefe é um ChefeGuardiaoDosCeus")
		_verificar(falhas, not (chefe is ChefePrimeiroPrisioneiro),
			"N10: o Primeiro Prisioneiro deixou de ser o chefe final")
	for filho in raiz.get_children():
		if filho.scene_file_path == CHEFE_ANTIGO:
			falhas.append("N10: %s ainda instancia o chefe antigo" % filho.name)

	_verificar(falhas,
		CatalogoCampanha.CHEFE_KEY[INDICE_N10] == "boss.guardiao_dos_ceus",
		"N10: o carrossel anuncia o Guardião dos Céus")
	_verificar(falhas, Textos.t("boss.guardiao_dos_ceus") != "boss.guardiao_dos_ceus",
		"N10: o nome do chefe tem texto em i18n")

	# --- exame de vento -------------------------------------------------
	var zonas: Array[WindZone] = []
	for filho in raiz.get_children():
		if filho is WindZone:
			zonas.append(filho)
	_verificar(falhas, zonas.size() >= 4,
		"N10: as três leituras de vento do exame + a arena (%d zonas)" % zonas.size())

	var favor: WindZone = null
	var corrente: WindZone = null
	var contra: WindZone = null
	var arena: WindZone = null
	for z in zonas:
		match z.name:
			"RajadaFavor": favor = z
			"CorrenteEsq": corrente = z
			"RajadaContra": contra = z
			"VentoArena": arena = z

	_verificar(falhas, favor != null and favor.direcao.x > 0.0 and favor.intensidade > 0.0,
		"N10: rajada A FAVOR na entrada")

	# GATE 2 (Super-Process A2) -- a rajada nao pode soprar para la' do chao.
	# Media antes: x 180-620 com o `ChaoInicio` a acabar em 540, ou seja 80 px
	# de vento por cima do vazio, a empurrar para uma queda mortal antes de
	# haver onde pousar.
	var chao_inicio := raiz.get_node_or_null("ChaoInicio") as Node2D
	if favor != null and chao_inicio != null:
		var fim_vento: float = favor.position.x + favor.tamanho.x * 0.5
		var fim_chao: float = chao_inicio.position.x \
			+ (chao_inicio.get("tamanho") as Vector2).x * 0.5
		_verificar(falhas, fim_vento <= fim_chao + 1.0,
			"N10: a rajada a favor acaba em x=%.0f e o chao em x=%.0f --"
			% [fim_vento, fim_chao]
			+ " o vento nao pode empurrar para alem do chao que existe")

	# GATE 2 -- a saliencia de recuperacao debaixo do vao `L1`->`R1`, onde
	# estavam 99% das mortes do nivel (76% so' em x~700). Sem ela, falhar o
	# primeiro salto do ziguezague e' morte instantanea de vida cheia.
	var resgate := raiz.get_node_or_null("ChaoResgate") as Node2D
	_verificar(falhas, resgate != null,
		"N10: falta a saliencia de recuperacao do fundo do poco")
	if resgate != null:
		var r_tam := resgate.get("tamanho") as Vector2
		var r0: float = resgate.position.x - r_tam.x * 0.5
		var r1: float = resgate.position.x + r_tam.x * 0.5
		var topo: float = resgate.position.y - r_tam.y * 0.5
		var acido := raiz.get_node_or_null("Acido") as Node2D
		_verificar(falhas, r0 <= 600.0 and r1 >= 820.0,
			"N10: a saliencia (x %.0f-%.0f) tem de cobrir a faixa das mortes"
			% [r0, r1] + " medida (x 600-820)")
		if acido != null:
			var sup: float = acido.position.y - float(acido.get("altura")) * 0.5
			_verificar(falhas, topo < sup - 40.0,
				"N10: a saliencia (topo y=%.0f) tem de ficar acima da linha"
				% topo + " do acido (y=%.0f)" % sup)
	_verificar(falhas, corrente != null and corrente.direcao.y < 0.0
		and corrente.intensidade > 1400.0,
		"N10: corrente ASCENDENTE capaz de levantar")
	_verificar(falhas, contra != null and contra.direcao.x < 0.0
		and contra.modo == WindZone.Modo.PULSADO and contra.intervalo_pulso > 0.0,
		"N10: rajada CONTRA pulsada (há sempre uma pausa para passar)")

	# a arena nasce PARADA: é o Guardião que acorda o vento, e só depois de
	# o anunciar. Sem isto o combate começava com vento que ninguém pediu.
	_verificar(falhas, arena != null and not arena.ativa,
		"N10: o vento da arena começa parado")
	if arena and chefe:
		var ret := Rect2(arena.position - arena.tamanho * 0.5, arena.tamanho)
		_verificar(falhas, ret.has_point(chefe.position),
			"N10: o vento da arena cobre o chefe")

	# formas PRÓPRIAS por zona (o bug conhecido das zonas que partilham a
	# forma faria o exame inteiro com o tamanho da última)
	var formas: Array[RID] = []
	for z in zonas:
		var c := z.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if c == null or c.shape == null:
			falhas.append("N10: %s sem forma de colisão" % z.name)
			continue
		if c.shape.get_rid() in formas:
			falhas.append("N10: %s partilha a forma de colisão com outra zona" % z.name)
		formas.append(c.shape.get_rid())

	# --- progressão: fogueiras, porta e recompensa ----------------------
	var checks := 0
	for filho in raiz.get_children():
		if filho.name.begins_with("Check"):
			checks += 1
	_verificar(falhas, checks >= 2, "N10: fogueiras preservadas (%d)" % checks)
	var col := raiz.get_node_or_null("ColProjetil")
	if col:
		_verificar(falhas, col.get("habilidade_id") == "projetil",
			"N10: recompensa de progressão 'projetil' preservada")
	# ninguém sai do N10 com planar permanente (isso é do N63)
	for filho in raiz.get_children():
		if filho.get("habilidade_id") == "planar":
			falhas.append("N10: %s dava a habilidade permanente planar" % filho.name)

	# --- Koliani canónica ----------------------------------------------
	var k := raiz.get_node_or_null("Koliani")
	if k:
		_verificar(falhas, k.get("usar_golden_set") == true,
			"N10: Koliani canónica (Golden Set)")
		_verificar(falhas, k.get("usar_prototipo_premium") == true,
			"N10: Koliani canónica (protótipo premium)")

	_paleta_do_guardiao(falhas)
	raiz.free()
	return falhas


## O contrato do Guardião (L3) PROÍBE por escrito "a paleta ciano/branco-gelo
## do `monge_celeste` (`#a8ebff`)". O audit encontrou-a em cinco sítios do
## `chefe_guardiao_dos_ceus.gd` -- incluindo o projéctil das PENAS CORTANTES,
## o ataque que dá nome ao chefe. Aconteceu porque o rig foi redesenhado para
## violeta-índigo e os ataques ficaram com a paleta do rig antigo; sem um
## teste, volta a acontecer à próxima vez que alguém mexer numa cor.
##
## "Gelo" aqui é: azul dominante, muito claro, e com o vermelho bem abaixo do
## azul. A família violeta do contrato (`#d495fd`, `#c68af9`) tem o vermelho
## ALTO, portanto passa; `#a8ebff` e `#b8ebff` não.
static func _paleta_do_guardiao(falhas: Array[String]) -> void:
	var f := FileAccess.open(
		"res://scripts/chefe_guardiao_dos_ceus.gd", FileAccess.READ)
	if f == null:
		falhas.append("N10: não consegui ler o script do Guardião")
		return
	var src := f.get_as_text()
	f.close()
	var re := RegEx.new()
	re.compile("Color\\(\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*,\\s*([0-9.]+)")
	var achadas := 0
	for m in re.search_all(src):
		var r := float(m.get_string(1))
		var g := float(m.get_string(2))
		var b := float(m.get_string(3))
		if b >= 0.9 and g >= 0.85 and b - r >= 0.15:
			achadas += 1
			falhas.append(
				"N10: o Guardião usa a paleta gelo que o contrato L3 proíbe"
				+ " -- Color(%.2f, %.2f, %.2f)" % [r, g, b])
	if achadas == 0:
		return


static func _verificar(falhas: Array[String], condicao: bool, rotulo: String) -> void:
	if not condicao:
		falhas.append(rotulo)
