extends Node2D
## PROCESS 11 -- harness no motor: `ZonaPlanar` + `WindZone` + Koliani REAL,
## com input simulado. Cobre o que a matemática pura não vê: contexto por
## zona, dash, dano, respawn, morte (instância nova), mudança de cena e
## ausência de estado residual. A matemática fica em `test_glide_region02.gd`.
##
## Corre com o `EstadoJogo` do kit de chegada ao N08 (sem "planar"
## permanente, sem modo Dev). Usar APPDATA isolado (`tools/correr_testes.ps1`
## faz isso para a suite; aqui convém o mesmo).

const Testes := preload("res://tests/test_glide_region02.gd")
const CenaKoliani := preload("res://scenes/actors/Koliani.tscn")
const CenaZonaPlanar := preload("res://scenes/actors/ZonaPlanar.tscn")
const CenaWindZone := preload("res://scenes/actors/WindZone.tscn")
const KIT_N08 := ["dash", "salto_duplo", "dash_aereo", "escalar_paredes"]

var _falhas: Array[String] = []


func _ready() -> void:
	call_deferred("_executar")


func _executar() -> void:
	_falhas.append_array(Testes.executar())
	var habilidades_antes: Array = EstadoJogo.habilidades.duplicate()
	EstadoJogo.modo_dev = false
	EstadoJogo.indice_nivel = 7
	EstadoJogo.habilidades.assign(KIT_N08)
	EstadoJogo.habilidades_suspensas.clear()
	_verificar(not EstadoJogo.tem_habilidade("planar"),
		"pré-condição: sem planar permanente")

	# --- mundo: zona de planar à esquerda, corrente e rajada à direita, tudo
	# no ar (sem chão por baixo); a Koliani é largada lá dentro
	var zona := CenaZonaPlanar.instantiate() as ZonaPlanar
	zona.name = "ZonaPlanarTeste"
	zona.position = Vector2(0.0, 0.0)
	zona.tamanho = Vector2(1200.0, 4000.0)
	add_child(zona)

	var koliani := CenaKoliani.instantiate() as Koliani
	koliani.position = Vector2(-2000.0, -600.0)   # fora da zona
	add_child(koliani)
	await _frames(3)

	# B0 -- fora da zona não há planar (contexto, não habilidade)
	Input.action_press("saltar")
	await _frames(40)
	_verificar(koliani.quantidade_planar_contextual() == 0 and not koliani.pode_planar(),
		"contexto: fora da ZonaPlanar não concede planar")
	_verificar(koliani.velocity.y > Movimento.VEL_PLANAR + 50.0,
		"A: fora da zona, a segurar saltar, a queda é a normal (vy %.0f)" % koliani.velocity.y)

	# B -- dentro da zona, a cair e a segurar: prende a VEL_PLANAR
	_teleportar(koliani, Vector2(0.0, -1500.0))
	await _frames(40)
	_verificar(koliani.quantidade_planar_contextual() == 1 and koliani.pode_planar(),
		"B: dentro da ZonaPlanar concede planar (uma entrada)")
	_verificar(koliani.esta_a_planar() and is_equal_approx(koliani.velocity.y, Movimento.VEL_PLANAR),
		"B: planar ativo prende a queda (vy %.1f, a_planar=%s)" % [koliani.velocity.y, str(koliani.esta_a_planar())])
	# C/D -- 1 s a planar: nunca sobe, mas desce
	var y0 := koliani.global_position.y
	var menor_vy := INF
	for _i in 60:
		await get_tree().physics_frame
		menor_vy = minf(menor_vy, koliani.velocity.y)
	_verificar(menor_vy >= 0.0, "C: planar sem vento nunca sobe (menor vy %.1f)" % menor_vy)
	_verificar(koliani.global_position.y > y0 + 100.0,
		"D: a planar continua a cair (%.0f px em 1 s)" % (koliani.global_position.y - y0))
	# E -- largar o botão devolve a queda normal
	Input.action_release("saltar")
	await _frames(20)
	_verificar(not koliani.esta_a_planar() and koliani.velocity.y > Movimento.VEL_PLANAR + 50.0,
		"E: largar saltar restaura a queda (vy %.0f)" % koliani.velocity.y)

	# G -- dash a meio do planar: o dash manda (vy = 0, sem planar nesse
	# frame) e o planar volta sozinho quando o dash acaba
	_teleportar(koliani, Vector2(-300.0, -1500.0))
	Input.action_press("saltar")
	await _frames(40)
	Input.action_press("dash")
	# o input chega no frame seguinte e a velocidade do dash no outro a seguir
	await _frames(4)
	Input.action_release("dash")
	_verificar(is_zero_approx(koliani.velocity.y) and absf(koliani.velocity.x) > 500.0
		and not koliani.esta_a_planar(),
		"G: dash durante planar mantém o dash intacto (v=%s)" % str(koliani.velocity))
	await _frames(40)
	_verificar(koliani.esta_a_planar() and is_equal_approx(koliani.velocity.y, Movimento.VEL_PLANAR),
		"G: depois do dash o planar retoma (vy %.1f)" % koliani.velocity.y)

	# J -- dano a meio do planar: suspende durante o atordoamento (cai a
	# sério) e retoma depois, sem ficar preso
	koliani.receber_dano(1, 1.0)
	await _frames(8)
	_verificar(not koliani.esta_a_planar() and koliani.velocity.y > Movimento.VEL_PLANAR,
		"J: dano suspende o planar (vy %.0f)" % koliani.velocity.y)
	await _frames(40)
	_verificar(koliani.esta_a_planar() and is_equal_approx(koliani.velocity.y, Movimento.VEL_PLANAR),
		"J: passado o atordoamento o planar retoma (vy %.1f)" % koliani.velocity.y)

	# H -- vento lateral + planar, entrar e sair da zona de vento
	var rajada := CenaWindZone.instantiate() as WindZone
	rajada.name = "RajadaTeste"
	rajada.position = Vector2(2000.0, 0.0)
	rajada.direcao = Vector2.RIGHT
	rajada.intensidade = 2000.0
	rajada.velocidade_max = 420.0
	rajada.tamanho = Vector2(600.0, 4000.0)
	rajada.mostrar_guia = false
	add_child(rajada)
	var zona2 := CenaZonaPlanar.instantiate() as ZonaPlanar
	zona2.name = "ZonaPlanarVento"
	zona2.position = Vector2(2000.0, 0.0)
	zona2.tamanho = Vector2(1400.0, 4000.0)
	add_child(zona2)
	_teleportar(koliani, Vector2(2000.0, -1500.0))
	await _frames(50)
	_verificar(koliani.quantidade_ventos_ativos() == 1 and koliani.esta_a_planar(),
		"H: planar dentro de rajada (ventos=%d)" % koliani.quantidade_ventos_ativos())
	_verificar(koliani.velocity.x > 300.0 and is_equal_approx(koliani.velocity.y, Movimento.VEL_PLANAR),
		"H: rajada a favor leva o planar sem mexer no tecto (v=%s)" % str(koliani.velocity))
	# sair da rajada (ainda dentro da zona de planar): perde o vento, não o planar
	_teleportar(koliani, Vector2(2600.0, -1500.0))
	await _frames(40)
	_verificar(koliani.quantidade_ventos_ativos() == 0 and koliani.esta_a_planar(),
		"H: sair da rajada tira o vento e mantém o planar")
	# contra o vento (1600 < viragem no ar 1800): a segurar para a frente o
	# planar ENCALHA (não avança); sem segurar, recua até ao limite
	rajada.direcao = Vector2.LEFT
	rajada.intensidade = 1600.0
	rajada.velocidade_max = 150.0
	_teleportar(koliani, Vector2(1900.0, -1500.0))
	Input.action_press("mover_direita")
	await _frames(100)
	_verificar(absf(koliani.velocity.x) <= 40.0 and koliani.esta_a_planar(),
		"H: rajada contra anula o avanço de quem plana a segurar em frente (vx %.0f)" % koliani.velocity.x)
	Input.action_release("mover_direita")
	await _frames(60)
	_verificar(koliani.velocity.x < -140.0 and koliani.velocity.x >= -151.0 and koliani.esta_a_planar(),
		"H: sem segurar, a rajada contra faz recuar até velocidade_max (vx %.0f)" % koliani.velocity.x)

	# I -- corrente ascendente + planar: sobe com a corrente, com teto, e ao
	# sair por cima volta a planar a descer (sem subida infinita)
	rajada.direcao = Vector2.UP
	rajada.intensidade = 2600.0
	rajada.velocidade_max = 340.0
	rajada.tamanho = Vector2(600.0, 4000.0)
	_teleportar(koliani, Vector2(2000.0, -1500.0))
	await _frames(90)
	_verificar(koliani.velocity.y < 0.0 and koliani.velocity.y >= -341.0,
		"I: corrente levanta quem plana, com teto (vy %.0f)" % koliani.velocity.y)
	rajada.queue_free()
	await _frames(60)
	_verificar(koliani.quantidade_ventos_ativos() == 0 and koliani.esta_a_planar()
		and is_equal_approx(koliani.velocity.y, Movimento.VEL_PLANAR),
		"I/M: corrente libertada -> sem vento residual e de volta ao planar (vy %.1f)" % koliani.velocity.y)

	# N -- múltiplas ativações do botão
	var ok_n := true
	for ciclo in 12:
		if ciclo % 2 == 0:
			Input.action_press("saltar")
		else:
			Input.action_release("saltar")
		await _frames(12)
		var esperado := ciclo % 2 == 0
		if koliani.esta_a_planar() != esperado:
			ok_n = false
	_verificar(ok_n, "N: 12 ativações seguidas seguem o botão, sem ficar preso")
	Input.action_press("saltar")

	# M -- mudança de cena: a zona sai da árvore -> o contexto sai no mesmo
	# frame (sem esperar o TTL)
	_teleportar(koliani, Vector2(2000.0, -1500.0))
	await _frames(10)
	_verificar(koliani.quantidade_planar_contextual() == 1, "M: pré-condição, com contexto")
	remove_child(zona2)
	_verificar(koliani.quantidade_planar_contextual() == 0 and not koliani.pode_planar(),
		"M: zona fora da árvore retira o planar imediatamente")
	zona2.queue_free()
	await _frames(20)
	_verificar(not koliani.esta_a_planar() and koliani.velocity.y > Movimento.VEL_PLANAR,
		"M: sem zona a queda volta a ser normal")

	# F -- aterrar: chão por baixo, a segurar saltar; no chão não plana e o
	# salto seguinte sai inteiro
	var chao := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(600.0, 40.0)
	forma.shape = ret
	chao.add_child(forma)
	chao.position = Vector2(0.0, 400.0)
	add_child(chao)
	_teleportar(koliani, Vector2(0.0, 250.0))
	await _frames(90)
	_verificar(koliani.is_on_floor() and not koliani.esta_a_planar(),
		"F: aterrou com o botão seguro e não fica 'a planar' no chão")
	Input.action_release("saltar")
	await _frames(2)
	Input.action_press("saltar")
	await _frames(2)
	_verificar(koliani.velocity.y < -300.0,
		"F: salto seguinte sai inteiro depois de aterrar (vy %.0f)" % koliani.velocity.y)
	Input.action_release("saltar")
	await _frames(60)

	# L -- respawn: limpa contexto, vento e o estado de planar no mesmo
	# instante; a zona que contém a fogueira volta a conceder a seguir
	_teleportar(koliani, Vector2(0.0, -1500.0))
	Input.action_press("saltar")
	await _frames(40)
	_verificar(koliani.esta_a_planar(), "L: pré-condição, a planar")
	koliani.recuperar_no_checkpoint(Vector2(0.0, 360.0))
	_verificar(koliani.quantidade_planar_contextual() == 0 and not koliani.esta_a_planar()
		and koliani.quantidade_ventos_ativos() == 0 and koliani.velocity.is_zero_approx(),
		"L: respawn limpa planar, vento e velocidade")
	await _frames(3)
	_verificar(koliani.quantidade_planar_contextual() == 1,
		"L: a zona da fogueira volta a conceder no frame seguinte")
	Input.action_release("saltar")

	# K -- morte = cena recarregada = Koliani NOVA: nasce sem nenhum estado
	var nova := CenaKoliani.instantiate() as Koliani
	nova.position = Vector2(-2000.0, -600.0)
	koliani.queue_free()
	add_child(nova)
	await _frames(3)
	_verificar(nova.quantidade_planar_contextual() == 0 and not nova.esta_a_planar()
		and nova.quantidade_ventos_ativos() == 0,
		"K: instância nova (morte/reload) nasce sem planar nem vento")

	# O -- nada foi gravado nem desbloqueado
	_verificar(not EstadoJogo.tem_habilidade("planar") and not "planar" in EstadoJogo.habilidades,
		"O: planar contextual nunca vira habilidade permanente")
	# suspensão explícita desliga também o contexto
	EstadoJogo.habilidades_suspensas.append("planar")
	nova.global_position = Vector2(0.0, -1500.0)
	await _frames(3)
	_verificar(not nova.pode_planar(), "O: 'planar' suspenso desliga o contexto")
	EstadoJogo.habilidades_suspensas.clear()

	EstadoJogo.habilidades.assign(habilidades_antes)
	Input.action_release("saltar")
	if _falhas.is_empty():
		print("OK -- Region II N08 glide (A-O)")
		get_tree().quit(0)
		return
	for falha in _falhas:
		printerr("FALHOU: ", falha)
	printerr("%d falha(s)" % _falhas.size())
	get_tree().quit(1)


func _teleportar(k: Koliani, pos: Vector2) -> void:
	k.global_position = pos
	k.reset_physics_interpolation()
	k.velocity = Vector2.ZERO


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().physics_frame


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		_falhas.append(mensagem)
