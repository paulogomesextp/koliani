extends Node2D
## N20 -- harness do GUARDIAO DA FORNALHA. Corre o nivel REAL com a Koliani
## real e prova: spawn e HP; os cinco ataques executam, cada um com o seu
## telegrafo ANTES do golpe e nunca dano durante o telegrafo; EXPOSTO depois
## dos ataques; a fase 2 abre perto dos 50 %; a ERUPCAO nao magoa quem esta'
## num refugio (e magoa quem esta' no chao); TTK medido; o reset repoe tudo
## (vida, fase, historico, perigos); a morte abre bau -> cartao da Regiao IV ->
## porta, sem inventar habilidade.
##
## Corre como CENA (precisa dos autoloads), com `EstadoJogo.modo_teste`:
##   python tools/godot_isolado.py -- --headless --path . res://tests/run_boss_guardiao_fornalha.tscn

const Estruturais := preload("res://tests/test_region04_n20_level.gd")
const CENA_N20 := "res://scenes/levels/O_Abismo.tscn"
const INDICE_N20 := 19

var _falhas: Array[String] = []


func _ready() -> void:
	call_deferred("_executar")


func _executar() -> void:
	_falhas.append_array(Estruturais.executar())
	EstadoJogo.modo_teste = true
	EstadoJogo.modo_dev = false
	await _spawn_e_hp()
	await _luta_completa()
	await _erupcao(true)
	await _erupcao(false)
	await _reset()
	if _falhas.is_empty():
		print("OK -- N20: Guardiao da Fornalha")
		get_tree().quit(0)
	else:
		for f in _falhas:
			printerr("FALHA: ", f)
		printerr("%d falha(s)" % _falhas.size())
		get_tree().quit(1)


func _novo_nivel() -> Node:
	EstadoJogo.reiniciar_campanha()
	EstadoJogo.indice_nivel = INDICE_N20
	var cena := load(CENA_N20) as PackedScene
	if cena == null:
		_falhas.append("harness: %s nao carrega" % CENA_N20)
		return null
	var nivel := cena.instantiate()
	add_child(nivel)
	return nivel


func _spawn_e_hp() -> void:
	var nivel := _novo_nivel()
	if nivel == null:
		return
	await _frames(8)
	var chefe := nivel.get_node_or_null("Chefe") as ChefeGuardiaoDaFornalha
	_verificar(chefe != null, "spawn: o nivel instancia o Guardiao da Fornalha")
	if chefe:
		var base := 680.0
		_verificar(chefe.vida_maxima_luta() >= int(base * 3.5), "HP: vida %d da luta >= 3.5x a base" % chefe.vida_maxima_luta())
		_verificar(chefe.vida_maxima_luta() <= int(base * 5.0), "HP: vida %d nao e' esponja (<= 5x)" % chefe.vida_maxima_luta())
		_verificar(chefe.fase_atual() == "DORME" and not chefe.esta_em_fase2(), "spawn: arranca a dormir, fase 1")
		var anim := chefe.get_node_or_null("Sprite/Anim") as AnimatedSprite2D
		_verificar(anim != null and anim.visible and anim.sprite_frames != null, "arte: rig animado ligado")
		if anim and anim.sprite_frames:
			for n in ["idle", "run", "attack", "cast", "transform", "hit", "dead"]:
				_verificar(anim.sprite_frames.has_animation(n), "arte: animacao `%s` do rig" % n)
		var col := chefe.get_node("CollisionShape2D") as CollisionShape2D
		var area := chefe.get_node("AreaContacto/CollisionShape2D") as CollisionShape2D
		var ar: Vector2 = (area.shape as RectangleShape2D).size
		var cr: Vector2 = (col.shape as RectangleShape2D).size
		# hitbox <= arte visivel (idle ~ 1.2x a altura alvo de largura)
		_verificar(ar.x <= 240.0 and ar.y <= 170.0 + 12.0, "hitbox: contacto %s cabe na arte" % str(ar))
		_verificar(cr.x < ar.x and cr.y <= ar.y, "hitbox: corpo %s dentro do contacto" % str(cr))
		_verificar(chefe.dano_contacto > 0, "spawn: dano de contacto definido")
	var porta := nivel.get_node("Porta") as Area2D
	_verificar(not porta.monitoring, "porta selada enquanto o boss vive")
	nivel.queue_free()
	await _frames(3)


## Luta inteira, a bater como um jogador (so' nas janelas), a medir tudo.
func _luta_completa() -> void:
	var nivel := _novo_nivel()
	if nivel == null:
		return
	var chefe := nivel.get_node_or_null("Chefe") as ChefeGuardiaoDaFornalha
	var porta := nivel.get_node("Porta") as Area2D
	var koliani := nivel.get_node("Koliani") as Koliani
	await _frames(8)
	if chefe == null:
		nivel.queue_free()
		return
	var hab_antes := str(EstadoJogo.habilidades) if "habilidades" in EstadoJogo else ""
	var vida_cheia := chefe.vida_maxima_luta()
	var morreu: Array[bool] = [false]
	chefe.derrotado.connect(func() -> void: morreu[0] = true)
	var pos := Vector2(chefe.global_position.x - 170.0, chefe.global_position.y + 35.0)
	var vistas: Array[String] = []
	var ordem: Array[String] = []
	var dano_em: Dictionary = {}
	var fase2_vida := -1
	var exposto_apos := {}
	var anterior := ""
	var frames := 0
	var t_primeiro := -1
	for passo in 9000:
		await get_tree().physics_frame
		if morreu[0] or not is_instance_valid(chefe):
			break
		frames += 1
		koliani.global_position = pos
		koliani.velocity = Vector2.ZERO
		var fase := chefe.fase_atual()
		if koliani.vida < koliani.VIDA_MAXIMA:
			dano_em[fase] = int(dano_em.get(fase, 0)) + (koliani.VIDA_MAXIMA - koliani.vida)
			koliani.vida = koliani.VIDA_MAXIMA
		if ordem.is_empty() or ordem[ordem.size() - 1] != fase:
			ordem.append(fase)
			if not vistas.has(fase):
				vistas.append(fase)
			if fase == "EXPOSTO" and anterior != "":
				exposto_apos[anterior] = true
			anterior = fase
		if fase != "DORME" and t_primeiro < 0:
			t_primeiro = passo
		if chefe.esta_em_fase2() and fase2_vida < 0:
			fase2_vida = chefe.vida
		# golpes de jogador: 1 de 50 a cada 27 frames, so' em DECIDE/EXPOSTO e
		# so' quando o boss esta' ao alcance (~45 % do tempo de uma luta real)
		if (fase == "EXPOSTO" or fase == "DECIDE") and passo % 27 == 0:
			chefe.receber_dano(50, 1.0)
	for _i in 900:
		if morreu[0]:
			break
		await get_tree().physics_frame
	_verificar(morreu[0], "o boss pode morrer (sinal `derrotado`)")
	for f in ["GOLPE_TEL", "GOLPE", "ONDA_TEL", "ONDA", "CHAMAS_TEL", "CHAMAS", "INVEST_TEL", "INVEST",
			"ERUPCAO_TEL", "ERUPCAO", "TRANSFORMA", "EXPOSTO"]:
		_verificar(vistas.has(f), "fase %s executa" % f)
	# o golpe vem LOGO depois do seu telegrafo
	var pares := {"GOLPE": "GOLPE_TEL", "ONDA": "ONDA_TEL", "CHAMAS": "CHAMAS_TEL", "INVEST": "INVEST_TEL",
		"ERUPCAO": "ERUPCAO_TEL"}
	for i in ordem.size():
		if pares.has(ordem[i]):
			_verificar(i > 0 and ordem[i - 1] == pares[ordem[i]],
				"o telegrafo vem sempre antes do golpe (%s apos %s)" % [ordem[i], ordem[i - 1] if i > 0 else "-"])
	for f in dano_em:
		_verificar(not (f as String).ends_with("_TEL") and f != "DECIDE" and f != "TRANSFORMA",
			"nunca ha dano durante o telegrafo (dano %d em %s)" % [int(dano_em[f]), f])
	_verificar(dano_em.has("GOLPE") or dano_em.has("ONDA") or dano_em.has("CHAMAS"),
		"os ataques da fase 1 magoam de verdade quem fica no sitio")
	for f in ["GOLPE", "ONDA", "CHAMAS", "INVEST"]:
		_verificar(exposto_apos.has(f), "ha janela EXPOSTO depois de %s" % f)
	_verificar(fase2_vida > 0, "a fase 2 abriu")
	if fase2_vida > 0:
		var metade := int(round(float(vida_cheia) * 0.5))
		_verificar(absi(fase2_vida - metade) <= maxi(60, metade / 8),
			"a fase 2 abre perto dos 50%% (vida %d de %d)" % [fase2_vida, vida_cheia])
	var seg := float(frames - t_primeiro) / 60.0
	print("[boss] TTK com golpes so' nas janelas (~45%% do tempo, 1 golpe de 50 a cada 0,45 s): %.1f s; vida %d; DPS efetivo %.0f"
		% [seg, vida_cheia, float(vida_cheia) / maxf(seg, 1.0)])
	_verificar(seg >= 25.0 and seg <= 200.0, "TTK %.1f s fora de 25-200 s (nao e' sponge nem passeio)" % seg)
	print("[boss] dano por fase (Koliani parada a 170 px): ", dano_em)
	# depois da morte
	await _frames(20)
	_verificar(get_tree().get_nodes_in_group("marcas_guardiao").is_empty(), "nao ficam marcas na arena")
	_verificar(EstadoJogo.chefe_derrotado_por_nivel(INDICE_N20), "o boss fica registado como derrotado (save)")
	var bau := nivel.get_node_or_null("BauChefe")
	_verificar(bau != null, "o bau de recompensa nasce")
	if bau:
		koliani.global_position = (bau as Node2D).global_position + Vector2(0, -22)
		var cartao_texto := ""
		for _i in 400:
			await get_tree().physics_frame
			var botao := _procurar_botao(get_tree().root)
			if botao:
				cartao_texto = _textos(get_tree().root)
				botao.pressed.emit()
			if porta.monitoring:
				break
		_verificar(Textos.t("region.4.complete") in cartao_texto or porta.monitoring,
			"o cartao de fim de Regiao IV aparece")
	_verificar(porta.monitoring, "a saida abre depois da recompensa (sem softlock)")
	var hab_depois := str(EstadoJogo.habilidades) if "habilidades" in EstadoJogo else ""
	_verificar(hab_antes == hab_depois, "nenhuma habilidade inventada ao concluir a Regiao IV")
	nivel.queue_free()
	await _frames(3)


## A ERUPCAO: num refugio nao magoa; no chao magoa.
func _erupcao(no_refugio: bool) -> void:
	var nivel := _novo_nivel()
	if nivel == null:
		return
	var chefe := nivel.get_node_or_null("Chefe") as ChefeGuardiaoDaFornalha
	var koliani := nivel.get_node("Koliani") as Koliani
	await _frames(8)
	if chefe == null:
		nivel.queue_free()
		return
	var re := nivel.get_node("RefugioE") as Node2D
	var pos: Vector2
	if no_refugio:
		var t: Vector2 = re.get("tamanho")
		pos = Vector2(re.position.x, re.position.y - t.y * 0.5 - 22.0)
	else:
		pos = Vector2(4620.0, 600.0 - 24.0)
	koliani.global_position = pos
	chefe.vida = int(float(chefe.vida_maxima_luta()) * 0.49)   # fase 2
	chefe.set("_ciclos", 4)                                    # 5.o do padrao = erupcao
	var dano_erupcao_total := 0
	var vi_erupcao := false
	for _i in 2400:
		await get_tree().physics_frame
		if not is_instance_valid(chefe):
			break
		koliani.global_position = pos
		koliani.velocity = Vector2.ZERO
		var fase := chefe.fase_atual()
		if fase == "ERUPCAO":
			vi_erupcao = true
		if koliani.vida < koliani.VIDA_MAXIMA:
			if fase == "ERUPCAO" or fase == "ERUPCAO_TEL":
				dano_erupcao_total += koliani.VIDA_MAXIMA - koliani.vida
			koliani.vida = koliani.VIDA_MAXIMA
		if vi_erupcao and fase == "EXPOSTO":
			break
	_verificar(vi_erupcao, "a erupcao executa (refugio=%s)" % str(no_refugio))
	if no_refugio:
		_verificar(dano_erupcao_total == 0, "a erupcao NAO magoa quem esta' no refugio (dano %d)" % dano_erupcao_total)
	else:
		_verificar(dano_erupcao_total > 0, "a erupcao magoa quem fica no chao (dano %d)" % dano_erupcao_total)
	nivel.queue_free()
	await _frames(3)


## Reset: uma luta a meio e um nivel novo -> tudo de volta ao inicio.
func _reset() -> void:
	var nivel := _novo_nivel()
	if nivel == null:
		return
	var chefe := nivel.get_node("Chefe") as ChefeGuardiaoDaFornalha
	var koliani := nivel.get_node("Koliani") as Koliani
	await _frames(8)
	var vida_inicial := chefe.vida
	koliani.global_position = chefe.global_position + Vector2(-170, 35)
	var perigos := false
	for i in 1500:
		await get_tree().physics_frame
		koliani.vida = koliani.VIDA_MAXIMA
		koliani.global_position = chefe.global_position + Vector2(-170, 35)
		if i % 40 == 0:
			chefe.receber_dano(50, 1.0)
		if chefe.perigos_ativos() > 0:
			perigos = true
		if chefe.esta_em_fase2() and perigos:
			break
	_verificar(perigos, "reset: pre-condicao, o boss chegou a pôr perigos no mundo")
	_verificar(chefe.vida < vida_inicial, "reset: pre-condicao, o boss levou dano")
	nivel.queue_free()
	await _frames(4)
	_verificar(get_tree().get_nodes_in_group("marcas_guardiao").is_empty(), "reset: sem marcas esquecidas")
	var nivel2 := _novo_nivel()
	await _frames(8)
	var c2 := nivel2.get_node("Chefe") as ChefeGuardiaoDaFornalha
	_verificar(c2.vida == vida_inicial, "reset: vida cheia (%d vs %d)" % [c2.vida, vida_inicial])
	_verificar(c2.fase_atual() == "DORME" and not c2.esta_em_fase2() and not c2.esta_exposto(),
		"reset: fase 1, a dormir, nucleo escondido")
	_verificar(c2.historico.is_empty() and c2.perigos_ativos() == 0, "reset: sem historico nem perigos")
	_verificar(nivel2.get_node_or_null("LavaErupcao") == null, "reset: sem lava de erupcao")
	_verificar(not (nivel2.get_node("Porta") as Area2D).monitoring, "reset: porta selada")
	nivel2.queue_free()
	await _frames(3)


func _procurar_botao(no: Node) -> Button:
	if no is Button and (no as Button).visible:
		return no
	for filho in no.get_children():
		var b := _procurar_botao(filho)
		if b:
			return b
	return null


func _textos(no: Node) -> String:
	var s := ""
	if no is Label:
		s += (no as Label).text + " "
	elif no is RichTextLabel:
		s += (no as RichTextLabel).text + " "
	for filho in no.get_children():
		s += _textos(filho)
	return s


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().physics_frame


func _verificar(condicao: bool, rotulo: String) -> void:
	if not condicao:
		_falhas.append(rotulo)
