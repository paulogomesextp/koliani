extends Node
## Testes da Koliani 3D (Regiao I). Correr ISOLADO (mexe no EstadoJogo):
##   python tools/godot_isolado.py --sandbox <dir> -- --path . res://tests/r3d/TestesR3D.tscn
## Sai com 0 se tudo passar. Cada asserção imprime "R3D_TESTE ok|FALHA <nome>".

const CENAS := Nivel3D.CENAS
var _falhas := 0
var _ok := 0


func _ready() -> void:
	Koliani3D.recarregar_na_morte = false
	Nivel3D.trocar_cena = false
	Nivel3D.qa_auto = true
	_correr.call_deferred()


func _verificar(cond: bool, nome: String, extra := "") -> void:
	if cond:
		_ok += 1
		print("R3D_TESTE ok    ", nome)
	else:
		_falhas += 1
		print("R3D_TESTE FALHA ", nome, "  ", extra)


func _esperar(seg: float) -> void:
	var fim := Time.get_ticks_msec() + int(seg * 1000.0)
	while Time.get_ticks_msec() < fim:
		await get_tree().physics_frame


func _correr() -> void:
	await _teste_jogador()
	await _teste_niveis()
	await _teste_progressao()
	await _teste_chefe()
	print("R3D_TESTES total ok=%d falhas=%d" % [_ok, _falhas])
	get_tree().quit(0 if _falhas == 0 else 1)


## --- Arena plana de teste -------------------------------------------------
func _arena() -> Node3D:
	var a := Node3D.new()
	add_child(a)
	var chao := StaticBody3D.new()
	var f := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(80, 1, 80)
	f.shape = b
	f.position.y = -0.5
	chao.add_child(f)
	a.add_child(chao)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 4, -8)
	a.add_child(cam)
	cam.look_at(Vector3.ZERO)
	cam.make_current()
	return a


func _teste_jogador() -> void:
	var a := _arena()
	var k := Koliani3D.new()
	k.controlo_externo = true
	a.add_child(k)
	k.global_position = Vector3(0, 0.05, 0)
	await _esperar(0.4)
	_verificar(k.is_in_group("koliani"), "jogador: grupo koliani (HUD)")
	_verificar(k.has_signal("vida_mudou") and k.has_signal("morreu"), "jogador: sinais da HUD")
	_verificar(k.is_on_floor(), "jogador: nasce no chao")
	_verificar(k.modelo != null and _contar_malhas(k.modelo) > 40, "jogador: modelo 3D construido", str(_contar_malhas(k.modelo)))
	# movimento
	var p0 := k.global_position
	k.entrada_mov = Vector2(0, 1)
	await _esperar(1.0)
	k.entrada_mov = Vector2.ZERO
	var dist := Vector2(k.global_position.x - p0.x, k.global_position.z - p0.z).length()
	_verificar(dist > 4.5 and dist < 8.0, "jogador: corre ~6,6 m/s", "dist=%.2f" % dist)
	await _esperar(0.3)
	# salto: altura do apice
	var y0 := k.global_position.y
	var ymax := y0
	k.bot_saltar()
	for i in 60:
		await get_tree().physics_frame
		ymax = maxf(ymax, k.global_position.y)
	_verificar(ymax - y0 > 1.6 and ymax - y0 < 2.6, "jogador: salto ~2 m", "h=%.2f" % (ymax - y0))
	await _esperar(0.6)
	_verificar(k.is_on_floor(), "jogador: aterra")
	# ataque num goblin
	var g := Inimigo3D.new()
	g.tipo = "goblin"
	a.add_child(g)
	var frente := Vector3(sin(k.get("_rumo")), 0, cos(k.get("_rumo")))
	g.global_position = k.global_position + frente * 1.4
	g.set_physics_process(false)
	await _esperar(0.2)
	g.set_physics_process(false)
	var v0 := g.vida
	for i in 4:
		k.bot_atacar()
		await _esperar(0.3)
	_verificar(g.vida < v0 or g.morto, "jogador: espada fere o inimigo", "vida %d->%d" % [v0, g.vida])
	# dano + i-frames
	var vi := k.vida
	k.receber_dano(30, k.global_position + Vector3(1, 0, 0))
	_verificar(k.vida == vi - 30, "jogador: recebe dano")
	k.receber_dano(30, k.global_position + Vector3(1, 0, 0))
	_verificar(k.vida == vi - 30, "jogador: i-frames (0,6 s)")
	await _esperar(0.8)
	# morte
	k.receber_dano(999, k.global_position)
	_verificar(k.esta_morta(), "jogador: morre a 0 de vida")
	await _esperar(0.3)
	a.queue_free()
	await _esperar(0.2)


## --- Niveis: carregam, entrada valida, saida existe, sem greybox -----------
func _teste_niveis() -> void:
	for i in CENAS.size():
		EstadoJogo.indice_nivel = i
		Nivel3D.limpar_checkpoint()
		var cena: PackedScene = load(CENAS[i])
		_verificar(cena != null, "N%02d: cena carrega" % (i + 1))
		if cena == null:
			continue
		var n := cena.instantiate() as Nivel3D
		add_child(n)
		await _esperar(1.2)
		_verificar(n.koliani != null and n.koliani.is_on_floor(), "N%02d: entrada valida (Koliani no chao)" % (i + 1),
			str(n.koliani.global_position if n.koliani else "-"))
		_verificar(n.portal != null, "N%02d: saida existe" % (i + 1))
		_verificar(n.rota_bot.size() >= 5, "N%02d: rota definida" % (i + 1))
		var inimigos := get_tree().get_nodes_in_group("inimigos3d").size()
		_verificar(inimigos >= 3 or i == 4, "N%02d: inimigos presentes" % (i + 1), str(inimigos))
		var greybox := _procurar_greybox(n)
		_verificar(greybox.is_empty(), "N%02d: sem greybox visivel" % (i + 1), str(greybox.slice(0, 5)))
		var malhas := _contar_malhas(n)
		_verificar(malhas > 40, "N%02d: arte (malhas desenhadas)" % (i + 1), str(malhas))
		n.queue_free()
		await _esperar(0.3)


## Primitivas de construcao a vista ou sem material = greybox.
func _procurar_greybox(no: Node) -> Array:
	var r: Array = []
	for f in no.get_children():
		if f is MeshInstance3D and f.is_visible_in_tree():
			var m: Mesh = f.mesh
			if m is BoxMesh or m is CapsuleMesh or m is SphereMesh or m is CylinderMesh or m is PrismMesh or m is TorusMesh:
				r.append("%s:%s" % [f.name, m.get_class()])
			elif m != null and f.material_override == null and m.surface_get_material(0) == null:
				r.append("%s:sem-material" % f.name)
		if f is CSGShape3D:
			r.append("%s:CSG" % f.name)
		r.append_array(_procurar_greybox(f))
	return r


func _contar_malhas(no: Node) -> int:
	var c := 0
	for f in no.get_children():
		if f is MeshInstance3D or f is MultiMeshInstance3D:
			c += 1
		c += _contar_malhas(f)
	return c


## --- Progressao: N01->N02->...->N05->(N06) e save --------------------------
func _teste_progressao() -> void:
	EstadoJogo.concluidos.clear()
	for i in 5:
		EstadoJogo.indice_nivel = i
		var cena: PackedScene = load(CENAS[i])
		var n := cena.instantiate() as Nivel3D
		add_child(n)
		await _esperar(0.3)
		n.concluir()
		_verificar(i in EstadoJogo.concluidos, "progressao: N%02d marcado concluido" % (i + 1))
		_verificar(EstadoJogo.indice_nivel == i + 1, "progressao: N%02d -> N%02d" % [i + 1, i + 2])
		_verificar(EstadoJogo.nivel_desbloqueado(i + 1), "progressao: N%02d desbloqueado" % (i + 2))
		n.queue_free()
		await _esperar(0.2)
	_verificar(EstadoJogo.regiao_esta_concluida(0), "progressao: Regiao I concluida")
	# save: grava e volta a ler sem perder nada (o 3D usa o mesmo save)
	EstadoJogo.desbloquear_habilidade("salto_duplo")
	var antes: Dictionary = EstadoJogo.para_dicionario()
	_verificar(EstadoJogo.guardar(), "save: grava")
	_verificar(EstadoJogo.carregar(), "save: volta a carregar")
	var depois: Dictionary = EstadoJogo.para_dicionario()
	_verificar(JSON.stringify(antes.get("concluidos")) == JSON.stringify(depois.get("concluidos")), "save: niveis concluidos preservados")
	_verificar(EstadoJogo.tem_habilidade("salto_duplo"), "save: habilidade do chefe preservada")
	_verificar(Nivel3D.caminho_para(5, "x2d") == "x2d", "progressao: N06 continua 2D")
	_verificar(Nivel3D.caminho_para(0, "x2d") == CENAS[0], "progressao: N01 abre a versao 3D")


## --- Chefe -----------------------------------------------------------------
func _teste_chefe() -> void:
	EstadoJogo.indice_nivel = 4
	var a := _arena()
	var c := ChefeCoracao3D.new()
	a.add_child(c)
	var k := Koliani3D.new()
	k.controlo_externo = true
	k.invulneravel_debug = true
	a.add_child(k)
	k.global_position = Vector3(0, 0.05, -20)
	var sinais := {"inicio": false, "vida": 0, "morte": false}
	c.combate_iniciado.connect(func(_x: Node) -> void: sinais["inicio"] = true)
	c.vida_mudou.connect(func(_a: int, _b: int) -> void: sinais["vida"] += 1)
	c.derrotado.connect(func() -> void: sinais["morte"] = true)
	await _esperar(0.3)
	_verificar(c.is_in_group("chefes"), "chefe: grupo chefes (barra da HUD)")
	_verificar(not sinais["inicio"], "chefe: dorme ate' a Koliani entrar")
	k.global_position = Vector3(0, 0.05, -9)
	await _esperar(0.4)
	_verificar(sinais["inicio"], "chefe: combate comeca ao entrar na arena")
	# casca resiste
	var v0 := c.vida
	c.receber_dano(100, k.global_position)
	_verificar(v0 - c.vida == 5, "chefe: casca fechada deixa passar 5 %", str(v0 - c.vida))
	# ataques ao longo do tempo (com aviso)
	await _esperar(14.0)
	var e: Dictionary = c.estatisticas
	_verificar(int(e["raizes"]) >= 1, "chefe: ataque RAIZES", str(e))
	_verificar(int(e["pulso"]) >= 1, "chefe: ataque PULSO", str(e))
	_verificar(int(e["brotos"]) >= 1 or int(e["exposto"]) >= 1, "chefe: BROTOS/EXPOSTO", str(e))
	# janela aberta = dano total
	c.call("_abrir", 1.0)
	v0 = c.vida
	c.receber_dano(100, k.global_position)
	_verificar(v0 - c.vida == 100, "chefe: nucleo exposto leva dano total")
	# fase 2 a 50 %
	c.vida = c.vida_max / 2 + 10
	c.receber_dano(50, k.global_position)
	_verificar(c.fase2(), "chefe: fase 2 abaixo de 50 %")
	# nao e' invulneravel: morre
	c.call("_abrir", 1.0)
	c.receber_dano(99999, k.global_position)
	_verificar(c.morto and sinais["morte"], "chefe: morre e emite derrotado")
	_verificar(int(sinais["vida"]) >= 3, "chefe: barra de vida atualizada")
	a.queue_free()
	await _esperar(0.3)
