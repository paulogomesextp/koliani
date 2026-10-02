class_name TestesRegion04PistaoValvula
extends RefCounted
## Componentes reutilizaveis do N19 (Sala das Pressoes, Regiao IV):
## `PistaoFornalha` e `ValvulaFornalha`, mais os ganchos OPT-IN que o
## `JatoFornalha` e a `PlataformaRitmada` ganharam para a valvula.
##
## Tudo medido por funcoes puras do ciclo e por bancada com o tempo dado a mao
## (`passo(dt, t)`): nada depende de relogio real.

const DT := 1.0 / 60.0


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	_ciclo_do_pistao(falhas)
	_telegrafo_e_dano(falhas)
	_fases_e_alternancia(falhas)
	_valvula_e_alvos(falhas)
	_valvulas_independentes(falhas)
	_omissoes_inalteradas(falhas)
	return falhas


static func _no_arvore(n: Node) -> void:
	(Engine.get_main_loop() as SceneTree).root.add_child(n)


static func _novo_pistao() -> PistaoFornalha:
	var p := PistaoFornalha.new()
	_no_arvore(p)
	return p


# ------------------------------------------------------------------ ciclo
static func _ciclo_do_pistao(falhas: Array[String]) -> void:
	var p := PistaoFornalha.new()
	var c := p.ciclo()
	_v(falhas, absf(c - (p.repouso_seg + p.aviso_seg + p.extensao_seg + p.permanece_seg + p.retracao_seg)) < 1e-6,
		"pistao: o ciclo e' a soma dos cinco tempos")
	# ordem dos estados ao longo do ciclo
	var ordem: Array[int] = []
	var t := 0.0
	while t < c:
		var e := p.estado_em(t)
		if ordem.is_empty() or ordem[-1] != e:
			ordem.append(e)
		t += 0.01
	_v(falhas, ordem == [PistaoFornalha.Estado.RETRAIDO, PistaoFornalha.Estado.AVISO,
		PistaoFornalha.Estado.EXTENDENDO, PistaoFornalha.Estado.ESTENDIDO,
		PistaoFornalha.Estado.RETRAINDO], "pistao: ordem dos estados %s" % [ordem])
	# o curso nunca sai de [0,1], comeca e acaba a 0, chega a 1
	var maximo := 0.0
	var salto_max := 0.0
	var ant := p.curso_em(0.0)
	t = 0.0
	while t < c * 2.0:
		var f := p.curso_em(t)
		maximo = maxf(maximo, f)
		salto_max = maxf(salto_max, absf(f - ant))
		_v(falhas, f >= 0.0 and f <= 1.0, "pistao: curso fora de [0,1] em t=%.2f" % t)
		ant = f
		t += 0.005
	_v(falhas, absf(p.curso_em(0.0)) < 1e-6, "pistao: arranca recolhido")
	_v(falhas, absf(maximo - 1.0) < 1e-3, "pistao: nunca chega ao fim do curso")
	# sem teletransporte: a cabeca nunca anda mais de ~0,35 do curso em 5 ms
	_v(falhas, salto_max < 0.35, "pistao: salto da cabeca %.2f numa amostra (teleporte)" % salto_max)
	# o ciclo e' periodico
	for x in [0.3, 1.7, 3.1, 4.4]:
		_v(falhas, absf(p.curso_em(x) - p.curso_em(x + c)) < 1e-5, "pistao: ciclo nao periodico em t=%.1f" % x)
	# a caixa da cabeca acompanha o curso (face em `f*curso`)
	var cx := p.caixa_cabeca(1.0)
	_v(falhas, absf(cx.end.y - p.curso) < 1e-3 and absf(cx.size.x - p.largura) < 1e-3,
		"pistao: caixa da cabeca a fundo = %s" % [cx])
	p.direcao = Vector2.RIGHT
	var cr := p.caixa_cabeca(1.0)
	_v(falhas, absf(cr.end.x - p.curso) < 1e-3 and absf(cr.size.y - p.largura) < 1e-3,
		"pistao: caixa horizontal = %s" % [cr])
	p.free()


## Nunca magoa sem aviso: entre o repouso e a primeira pancada ha' >= 0,7 s.
static func _telegrafo_e_dano(falhas: Array[String]) -> void:
	var p := PistaoFornalha.new()
	_v(falhas, p.aviso_seg >= 0.7, "pistao: aviso por omissao %.2f s < 0,7 s" % p.aviso_seg)
	var c := p.ciclo()
	var t := 0.0
	var ultimo_seguro := -1.0
	var violacoes := 0
	var dt := 0.005
	while t < c * 2.0:
		var perigo := p.perigoso_em(t)
		if not perigo:
			ultimo_seguro = t
		elif p.perigoso_em(t - dt):
			pass
		else:
			# primeiro instante perigoso: o AVISO tem de ter durado >= aviso_seg
			var e0 := p.estado_em(t - p.aviso_seg - p.extensao_seg * 0.5)
			if e0 == PistaoFornalha.Estado.ESTENDIDO or e0 == PistaoFornalha.Estado.RETRAINDO:
				violacoes += 1
		t += dt
	_v(falhas, violacoes == 0, "pistao: perigo sem o aviso inteiro antes (%d)" % violacoes)
	# nenhum instante perigoso fora de EXTENDENDO/ESTENDIDO/RETRAINDO
	t = 0.0
	while t < c:
		var e := p.estado_em(t)
		if e == PistaoFornalha.Estado.RETRAIDO or e == PistaoFornalha.Estado.AVISO:
			_v(falhas, not p.perigoso_em(t), "pistao: perigoso em repouso/aviso (t=%.2f)" % t)
		t += 0.02
	p.free()

	# bancada no no' vivo: o dano liga e desliga com a cabeca, sem sobrar estado
	var q := _novo_pistao()
	q.relogio_local = true
	q.reiniciar()
	var estados_perigo := 0
	var t0 := 0.0
	var ligou_cedo := false
	while t0 < q.ciclo() * 1.5:
		q.passo(DT, t0)
		if q.ativa and q._frac <= PistaoFornalha.LIMIAR_PERIGO:
			ligou_cedo = true
		if (not q.ativa) and q._frac > PistaoFornalha.LIMIAR_PERIGO:
			ligou_cedo = true
		if q.ativa:
			estados_perigo += 1
			var forma: Rect2 = q.caixa_cabeca(q._frac)
			_v(falhas, absf((q.get_node("Zona") as CollisionShape2D).position.y - (forma.position.y + forma.size.y * 0.5)) < 0.5,
				"pistao: a zona de dano nao acompanha a cabeca")
		t0 += DT
	_v(falhas, not ligou_cedo, "pistao: o dano nao coincide com a cabeca")
	_v(falhas, estados_perigo > 0, "pistao: nunca chegou a ficar perigoso")
	q.free()


## Duas fases: nunca perigosos ao mesmo tempo; e a fase nao muda a duracao.
static func _fases_e_alternancia(falhas: Array[String]) -> void:
	var a := PistaoFornalha.new()
	var b := PistaoFornalha.new()
	b.fase = a.ciclo() * 0.5
	var juntos := 0
	var t := 0.0
	var pa := 0.0
	var pb := 0.0
	while t < a.ciclo() * 2.0:
		var xa := a.perigoso_em(t)
		var xb := b.perigoso_em(t)
		if xa and xb:
			juntos += 1
		pa += float(xa)
		pb += float(xb)
		t += 0.01
	_v(falhas, juntos == 0, "pistoes em meia-fase perigosos ao mesmo tempo %d vezes" % juntos)
	_v(falhas, absf(pa - pb) < 3.0 and pa > 0.0, "a fase mudou a duracao do perigo (%.0f vs %.0f)" % [pa, pb])
	a.free()
	b.free()


# ---------------------------------------------------------------- valvula
static func _alvos_de_teste(grupo: String) -> Dictionary:
	var p := _novo_pistao()
	p.grupo_valvula = grupo
	p.add_to_group("valvula_" + grupo)
	p.fase = 0.0
	p.fase_retoma = 0.5
	p.reiniciar()
	var j := JatoFornalha.new()
	j.grupo_valvula = grupo
	j.relogio_local = true
	j.fase = 0.4
	j.fase_retoma = 0.4
	_no_arvore(j)
	var r := (load("res://scenes/actors/PlataformaRitmada.tscn") as PackedScene).instantiate() as PlataformaRitmada
	r.grupo_valvula = grupo
	r.efeito_valvula = "solida"
	r.relogio_local = true
	r.solida_seg = 1.0
	r.fantasma_seg = 2.0
	r.fase = 0.0
	_no_arvore(r)
	var v := ValvulaFornalha.new()
	v.grupo = grupo
	v.modo = "temporaria"
	v.janela_seg = 5.0
	v.aviso_fim_seg = 1.0
	v.mostrar_ligacoes = false
	_no_arvore(v)
	return {"p": p, "j": j, "r": r, "v": v}


static func _valvula_e_alvos(falhas: Array[String]) -> void:
	var s := _alvos_de_teste("t_a")
	var p: PistaoFornalha = s.p
	var j: JatoFornalha = s.j
	var r: PlataformaRitmada = s.r
	var v: ValvulaFornalha = s.v
	_v(falhas, not v.aberta and not p.pausado and not j.pausado, "valvula: arranca fechada")
	_v(falhas, v.alvos().size() == 3, "valvula: devia ligar 3 alvos, ligou %d" % v.alvos().size())

	# leva o pistao a meio da pancada e abre a valvula: recolhe SEM saltar
	var t := p.ciclo() * 0.0
	var alvo_t := p.repouso_seg + p.aviso_seg + p.extensao_seg + 0.1
	p._desloc = 0.0
	p.fase = 0.0
	while t < alvo_t:
		p.passo(DT, t)
		t += DT
	_v(falhas, p._frac > 0.9, "valvula: bancada nao pos o pistao em baixo (%.2f)" % p._frac)
	v.activar()
	_v(falhas, v.aberta, "valvula: tocar nao abriu")
	_v(falhas, p.pausado and j.pausado and r._valvula_aberta, "valvula: nao avisou os tres alvos")
	var maior_salto := 0.0
	var antes := p._frac
	var n := 0
	while p._frac > 0.0 and n < 600:
		p.passo(DT, t)
		t += DT
		maior_salto = maxf(maior_salto, absf(antes - p._frac))
		antes = p._frac
		n += 1
	_v(falhas, p._frac == 0.0 and n * DT <= p.retracao_seg + 0.1,
		"valvula: o pistao nao recolheu a tempo (%d passos)" % n)
	_v(falhas, maior_salto <= DT / p.retracao_seg + 1e-4, "valvula: o pistao saltou %.3f num passo" % maior_salto)
	# enquanto aberta: parado e inofensivo, ao longo de 4 s
	var perigo := false
	for i in 240:
		p.passo(DT, t)
		t += DT
		perigo = perigo or p.ativa
	_v(falhas, not perigo and p.estado == PistaoFornalha.Estado.RETRAIDO,
		"valvula: pistao pausado voltou a ser perigoso")
	_v(falhas, j.estado == JatoFornalha.Estado.DORME or j.pausado, "valvula: jato nao parou")
	_v(falhas, r._calcula_solida(), "valvula: a plataforma ritmada nao ficou solida")

	# a janela fecha sozinha (temporaria): 5 s de _process
	for i in int(v.janela_seg / DT) + 12:
		v._process(DT)
	_v(falhas, not v.aberta, "valvula: a janela temporaria nao fechou")
	_v(falhas, not j.pausado and not r._valvula_aberta, "valvula: os alvos nao foram avisados do fecho")
	# o pistao retoma no instante em que acaba de recolher, na fase de retoma
	p.passo(DT, t)
	_v(falhas, not p.pausado, "valvula: o pistao nao retomou")
	_v(falhas, p.aviso_restante_a_partir_de(p.fase_efetiva_retoma()) >= p.aviso_seg,
		"valvula: ao retomar o pistao nao da' o aviso inteiro")
	# o jato retoma no repouso (DORME) com o intervalo por correr
	_v(falhas, j.estado_em(0.0 + j.fase_retoma - j.fase) == JatoFornalha.Estado.DORME,
		"valvula: o jato retomou fora do repouso")
	# a plataforma ritmada retoma SOLIDA (comeca_solida) com o periodo todo
	_v(falhas, r._calcula_solida(), "valvula: a plataforma retomou fantasma (queda surpresa)")

	# alterna / uma_vez
	var v2 := ValvulaFornalha.new()
	v2.grupo = "t_a"
	v2.modo = "alterna"
	v2.mostrar_ligacoes = false
	_no_arvore(v2)
	v2.activar()
	_v(falhas, v2.aberta, "valvula alterna: 1.o toque devia abrir")
	v2._cooldown = 0.0
	v2.activar()
	_v(falhas, not v2.aberta, "valvula alterna: 2.o toque devia fechar")
	v2.modo = "uma_vez"
	v2._cooldown = 0.0
	v2.activar()
	v2._cooldown = 0.0
	v2.activar()
	_v(falhas, v2.aberta, "valvula uma_vez: devia ficar aberta")
	# reset
	v2.reiniciar()
	p.reiniciar()
	_v(falhas, not v2.aberta and not p.pausado and p._frac == 0.0, "reset: ficou estado residual")
	for n2 in [p, j, r, v, v2]:
		n2.free()


## Duas valvulas, dois grupos: abrir uma nao mexe no outro.
static func _valvulas_independentes(falhas: Array[String]) -> void:
	var a := _alvos_de_teste("t_b1")
	var b := _alvos_de_teste("t_b2")
	(a.v as ValvulaFornalha).activar()
	_v(falhas, (a.p as PistaoFornalha).pausado and not (b.p as PistaoFornalha).pausado,
		"grupos: a valvula 1 mexeu no pistao do grupo 2")
	_v(falhas, (a.r as PlataformaRitmada)._valvula_aberta and not (b.r as PlataformaRitmada)._valvula_aberta,
		"grupos: a valvula 1 mexeu na plataforma do grupo 2")
	(b.v as ValvulaFornalha).activar()
	_v(falhas, (b.j as JatoFornalha).pausado and (a.j as JatoFornalha).pausado, "grupos: ambos abertos")
	for grupo in [a, b]:
		for k in ["p", "j", "r", "v"]:
			(grupo[k] as Node).free()


## Os ganchos sao OPT-IN: sem `grupo_valvula` nada muda.
static func _omissoes_inalteradas(falhas: Array[String]) -> void:
	var j := JatoFornalha.new()
	_v(falhas, j.grupo_valvula == "" and not j.relogio_local and j.fase_retoma < 0.0,
		"jato: omissoes dos ganchos da valvula mudaram")
	# o ciclo do jato e' o de sempre
	j.intervalo = 2.4
	j.aviso_seg = 0.8
	j.dur_ativa = 1.2
	_v(falhas, j.estado_em(0.0) == JatoFornalha.Estado.DORME and j.estado_em(2.5) == JatoFornalha.Estado.AVISO
		and j.estado_em(3.5) == JatoFornalha.Estado.ATIVO, "jato: o ciclo mudou")
	j.free()
	var r := (load("res://scenes/actors/PlataformaRitmada.tscn") as PackedScene).instantiate() as PlataformaRitmada
	_v(falhas, r.grupo_valvula == "" and not r.relogio_local, "ritmada: omissoes dos ganchos mudaram")
	_v(falhas, r._desloc_s == 0.0 and not r._valvula_aberta, "ritmada: estado de valvula por omissao")
	r.free()
	var p := PistaoFornalha.new()
	_v(falhas, p.grupo_valvula == "", "pistao: sem grupo por omissao")
	p.free()


## CONTACTO REAL com a Koliani: o pistao so' fere depois do aviso inteiro, fere
## por contacto da cabeca (nao antes) e uma valvula aberta faz parar o dano.
## Assincrono (precisa de frames de fisica): `await` no corredor, que passa o no'
## onde se pendura o cenario.
static func contacto(host: Node) -> Array[String]:
	var falhas: Array[String] = []
	RelogioFornalha.manual = 0.0
	var chao := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(900, 40)
	cs.shape = rs
	chao.add_child(cs)
	chao.position = Vector2(300, 620)       # topo em y=600
	host.add_child(chao)
	var k: Koliani = preload("res://scenes/actors/Koliani.tscn").instantiate()
	k.position = Vector2(300, 570)
	host.add_child(k)
	var p := PistaoFornalha.new()
	p.position = Vector2(300, 600.0 - 230.0)
	p.repouso_seg = 0.4
	p.aviso_seg = 0.8
	p.extensao_seg = 0.22
	p.permanece_seg = 0.8
	p.retracao_seg = 0.7
	p.grupo_valvula = "t_contacto"
	host.add_child(p)
	var v := ValvulaFornalha.new()
	v.grupo = "t_contacto"
	v.mostrar_ligacoes = false
	v.position = Vector2(700, 600)
	host.add_child(v)
	var fisica := host.get_tree()
	# deixa a Koliani assentar no chao
	for i in 20:
		await fisica.physics_frame
	var dt := 1.0 / 60.0
	var vida0: int = k.vida
	_v(falhas, absf(k.global_position.y - 578.0) < 24.0, "contacto: a Koliani nao assentou no chao (y=%.0f)" % k.global_position.y)
	# 1) durante o repouso e o aviso (1,2 s) NAO ha' dano, mesmo debaixo do pistao
	var dano_cedo := false
	RelogioFornalha.manual = 0.0
	for i in int(1.15 / dt):
		RelogioFornalha.manual += dt
		await fisica.physics_frame
		if k.vida < vida0:
			dano_cedo = true
	_v(falhas, not dano_cedo, "contacto: o pistao feriu durante o repouso/aviso")
	# 2) a cabeca chega e fere dentro de 0,5 s
	var t_dano := -1.0
	for i in int(0.8 / dt):
		RelogioFornalha.manual += dt
		await fisica.physics_frame
		if k.vida < vida0 and t_dano < 0.0:
			t_dano = RelogioFornalha.manual
	_v(falhas, t_dano >= 1.2 and t_dano <= 1.2 + 0.22 + 0.25,
		"contacto: o dano chegou em t=%.2f (esperado entre 1,2 e ~1,7 s)" % t_dano)
	_v(falhas, k.vida == vida0 - p.dano, "contacto: dano %d != %d" % [vida0 - k.vida, p.dano])
	# 3) valvula aberta: o pistao recolhe e deixa de ferir por muito que se espere
	k.set("_invulneravel", 0.0)
	var vida1: int = k.vida
	v.activar()
	var dano_depois := false
	for i in int(6.0 / dt):
		RelogioFornalha.manual += dt
		if i > int(0.9 / dt):
			k.set("_invulneravel", 0.0)
		await fisica.physics_frame
		if i > int(0.9 / dt) and k.vida < vida1:
			dano_depois = true
	_v(falhas, p.pausado and p.estado == PistaoFornalha.Estado.RETRAIDO, "contacto: o pistao nao ficou parado com a valvula aberta")
	_v(falhas, not dano_depois, "contacto: o pistao feriu com a valvula aberta")
	host.remove_child(k)
	k.queue_free()
	for n in [p, v, chao]:
		host.remove_child(n)
		n.queue_free()
	RelogioFornalha.manual = -1.0
	return falhas


static func _v(falhas: Array[String], cond: bool, msg: String) -> void:
	if not cond and msg != "":
		falhas.append(msg)
