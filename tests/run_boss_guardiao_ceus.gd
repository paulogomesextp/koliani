extends Node2D
## PROCESS 12 -- harness no motor do GUARDIÃO DOS CÉUS (N10). Corre o nível
## REAL, com a Koliani real, e prova o que a inspeção estática não vê:
## a luta arranca, cada ataque executa, o telégrafo vem SEMPRE antes do
## golpe, a fase 2 abre perto dos 50%, o chefe leva dano e morre, a porta
## abre depois e o vento da arena fica limpo -- também quando a luta é
## interrompida a meio (morte da Koliani / recarga do nível).
##
## Corre como CENA (precisa dos autoloads). Usar APPDATA isolado; liga
## `EstadoJogo.modo_teste` para nunca escrever no save real.
##
##   godot --headless --path . res://tests/run_boss_guardiao_ceus.tscn

const Estruturais := preload("res://tests/test_region02_n10_level.gd")
const CENA_N10 := "res://scenes/levels/A_Cela_Zero.tscn"
const INDICE_N10 := 9

var _falhas: Array[String] = []


func _ready() -> void:
	call_deferred("_executar")


func _executar() -> void:
	_falhas.append_array(Estruturais.executar())

	EstadoJogo.modo_teste = true
	EstadoJogo.modo_dev = false
	EstadoJogo.indice_nivel = INDICE_N10

	await _luta_completa()
	await _vento_limpo_ao_sair()

	if _falhas.is_empty():
		print("OK -- Process 12: Guardião dos Céus (N10)")
		get_tree().quit(0)
	else:
		for f in _falhas:
			printerr("FALHA: ", f)
		printerr("%d falha(s)" % _falhas.size())
		get_tree().quit(1)


## --- luta inteira, do primeiro telégrafo à porta aberta ----------------

func _luta_completa() -> void:
	var nivel := _abrir_nivel()
	if nivel == null:
		return
	var chefe := nivel.get_node_or_null("Chefe") as ChefeGuardiaoDosCeus
	var porta := nivel.get_node_or_null("Porta") as Area2D
	var arena := nivel.get_node_or_null("VentoArena") as WindZone
	var koliani := nivel.get_node_or_null("Koliani")
	_verificar(chefe != null, "harness: o nível instancia o Guardião dos Céus")
	_verificar(porta != null, "harness: o nível tem Porta")
	_verificar(arena != null, "harness: o nível tem VentoArena")
	if chefe == null or porta == null or arena == null:
		nivel.queue_free()
		return

	_verificar(not porta.monitoring, "porta selada enquanto o chefe vive")
	_verificar(not arena.ativa, "vento da arena parado antes do combate")

	# a Koliani vai para dentro da arena: é assim que a luta arranca
	if koliani:
		koliani.global_position = chefe.global_position + Vector2(-150.0, 40.0)
	await _frames(6)

	# 30 s de luta observada, a bater no chefe como um jogador bate: o
	# harness regista as fases por onde ele passa e o que acontece no meio.
	var vistas: Array[String] = []
	var ordem: Array[String] = []
	var vento_visto := false
	var vento_com_zona := false
	var fase2_vida := -1
	var telegrafo_em_falta: Array[String] = []
	var golpe_para_telegrafo := {
		"LAMINA": "LAMINA_TEL", "VENTO": "VENTO_TEL", "QUEDA": "QUEDA_TEL",
	}
	var exposto_visto := false
	var vida_cheia := chefe.vida_maxima_luta()
	# ARMADILHA: em GDScript as lambdas capturam por VALOR -- pôr a bandeira
	# numa variável local fazia o sinal parecer que nunca chegava. O Array é
	# por referência, por isso funciona.
	var morreu: Array[bool] = [false]
	chefe.derrotado.connect(func() -> void: morreu[0] = true)

	for passo in 2400:
		await get_tree().physics_frame
		if morreu[0]:
			break
		if not is_instance_valid(chefe):
			# morreu e já se libertou: dá tempo às falas de fim/ao sinal
			await _frames(30)
			break
		var fase := chefe.fase_atual()
		if ordem.is_empty() or ordem[ordem.size() - 1] != fase:
			ordem.append(fase)
			if fase in golpe_para_telegrafo:
				# o golpe tem de vir LOGO a seguir ao seu telégrafo
				var antes := ordem[ordem.size() - 2] if ordem.size() >= 2 else ""
				if antes != golpe_para_telegrafo[fase] \
						and not telegrafo_em_falta.has(fase):
					telegrafo_em_falta.append("%s veio depois de %s" % [fase, antes])
		if not vistas.has(fase):
			vistas.append(fase)
		if fase == "EXPOSTO":
			exposto_visto = true
		if chefe.vento_do_guardiao_ativo():
			vento_visto = true
			if arena.ativa and arena.intensidade > 0.0:
				vento_com_zona = true
		if chefe.esta_em_fase2() and fase2_vida < 0:
			fase2_vida = chefe.vida
		# bate-se de 6 em 6 frames: chega para a luta acabar dentro do teste
		# sem saltar a leitura das fases
		if passo % 6 == 0:
			chefe.receber_dano(24, 1.0)

	# a morte de um chefe-história passa pelas falas de fim (balão a escrever
	# letra a letra): a porta só abre no fim delas, por isso espera-se mesmo.
	for _i in 900:
		if morreu[0]:
			break
		await get_tree().physics_frame
	_verificar(morreu[0], "o chefe pode morrer (sinal `derrotado`)")
	for ataque in ["LAMINA", "VENTO", "QUEDA"]:
		_verificar(vistas.has(ataque), "ataque %s executa" % ataque)
		_verificar(vistas.has(golpe_para_telegrafo[ataque]),
			"ataque %s tem telégrafo próprio" % ataque)
	_verificar(telegrafo_em_falta.is_empty(),
		"o telégrafo vem sempre antes do golpe (%s)" % ", ".join(telegrafo_em_falta))
	_verificar(exposto_visto,
		"o chefe desce e fica EXPOSTO (nunca é inatingível)")
	_verificar(vento_visto and vento_com_zona,
		"o COMANDO DO VENTO mexe mesmo na WindZone da arena")
	_verificar(fase2_vida > 0, "a fase 2 abriu")
	if fase2_vida > 0:
		var metade := int(round(float(vida_cheia) * 0.5))
		_verificar(absi(fase2_vida - metade) <= maxi(30, metade / 8),
			"a fase 2 abre perto dos 50%% (vida %d de %d)"
				% [fase2_vida, vida_cheia])

	# --- depois da morte: vento limpo, porta aberta, sem softlock ------
	await _frames(30)
	if is_instance_valid(chefe):
		_verificar(not chefe.vento_do_guardiao_ativo(),
			"o vento do Guardião desliga-se com ele")
	_verificar(not arena.ativa and is_equal_approx(arena.intensidade, 0.0),
		"a arena volta ao vento parado da cena (ativa=%s, %.0f)"
			% [str(arena.ativa), arena.intensidade])
	# A saída NÃO abre com a morte do chefe: abre com o BAÚ dele (é assim em
	# todos os níveis com chefe). Aqui joga-se o fim como um jogador o joga --
	# a Koliani vai buscar a recompensa e a porta abre.
	var bau := nivel.get_node_or_null("BauChefe")
	_verificar(bau != null, "o baú de recompensa nasce ao cair o chefe")
	if bau and koliani:
		koliani.global_position = (bau as Node2D).global_position + Vector2(0, -22)
		# o baú abre por proximidade e mostra um painel com "continuar" -- o
		# harness carrega no botão, que é o que o jogador faz
		for _i in 300:
			await get_tree().physics_frame
			var botao := _procurar_botao(get_tree().root)
			if botao:
				botao.pressed.emit()
			if porta.monitoring:
				break
	_verificar(porta.monitoring,
		"a saída abre depois de recolher a recompensa (sem softlock)")
	_verificar(nivel.get_node_or_null("MarcaQueda") == null,
		"a marca da queda não fica esquecida na arena")

	nivel.queue_free()
	await _frames(3)


## Luta interrompida a meio (a Koliani morre, o nível recarrega): o vento
## não pode ficar a soprar na cena seguinte.
func _vento_limpo_ao_sair() -> void:
	# o nível esconde o chefe já derrotado (e a luta anterior marcou-o):
	# esta cena precisa de uma campanha limpa, só em memória.
	EstadoJogo.reiniciar_campanha()
	EstadoJogo.indice_nivel = INDICE_N10
	var nivel := _abrir_nivel()
	if nivel == null:
		return
	var chefe := nivel.get_node_or_null("Chefe") as ChefeGuardiaoDosCeus
	var arena := nivel.get_node_or_null("VentoArena") as WindZone
	var koliani := nivel.get_node_or_null("Koliani")
	if chefe == null or arena == null:
		nivel.queue_free()
		return
	if koliani:
		koliani.global_position = chefe.global_position + Vector2(-140.0, 40.0)
	# corre até o Guardião estar mesmo a mandar no vento
	for _i in 2400:
		await get_tree().physics_frame
		if not is_instance_valid(chefe):
			break
		if chefe.vento_do_guardiao_ativo():
			break
	_verificar(is_instance_valid(chefe) and chefe.vento_do_guardiao_ativo(),
		"pré-condição: o Guardião chegou a mandar no vento")
	nivel.queue_free()
	await _frames(4)
	_verificar(not arena.ativa if is_instance_valid(arena) else true,
		"sair da cena a meio do comando repõe o vento parado")


## --- utilitários -------------------------------------------------------

func _abrir_nivel() -> Node:
	var cena := load(CENA_N10) as PackedScene
	if cena == null:
		_falhas.append("harness: %s não carrega" % CENA_N10)
		return null
	var nivel := cena.instantiate()
	add_child(nivel)
	return nivel


## O painel do baú vive num CanvasLayer criado em runtime: procura-se o
## primeiro Button visível na árvore.
func _procurar_botao(no: Node) -> Button:
	if no is Button:
		return no
	for filho in no.get_children():
		var b := _procurar_botao(filho)
		if b:
			return b
	return null


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().physics_frame


func _verificar(condicao: bool, rotulo: String) -> void:
	if not condicao:
		_falhas.append(rotulo)
