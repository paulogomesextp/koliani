extends SceneTree
## As três câmaras novas (`peso`, `caixas`, `atoleiro`) fazem MESMO o que
## dizem?
##
## Que os actores nascem no nível já é o `verifica_mecanicas.gd` que diz.
## Isto é o passo a seguir, e é o que apanha a classe de bug que já custou
## uma sessão inteira: a peça está lá, com a máscara certa, e mesmo assim
## não acontece nada.
##
## Uso: Godot --headless --script res://tools/verifica_camaras_novas.gd

const PLAT_PESO := preload("res://scripts/plataforma_peso.gd")
const BLOCO := preload("res://scripts/bloco_empurravel.gd")
const PLACA := preload("res://scripts/placa_peso.gd")
const AFUNDA := preload("res://scripts/zona_afunda.gd")

## Um boneco que responde aos ganchos das zonas e GUARDA o que lhe pediram.
## Sem isto não havia como provar que a `ZonaAfunda` faz alguma coisa: ela
## não mexe na posição, mexe no peso.
const ESPIA := preload("res://tools/_espia_corpo.gd")

var _falhas := 0


func _init() -> void:
	await process_frame
	await _plataforma_desce_com_peso()
	await _caixa_empurra_se_e_a_placa_liga()
	await _atoleiro_afunda()
	print("\n=== CAMARAS NOVAS: %s ===" % (
		"TUDO OK" if _falhas == 0 else "%d FALHA(S)" % _falhas))
	quit(1 if _falhas else 0)


func _ok(nome: String, condicao: bool, detalhe: String) -> void:
	print("  %-34s %s  %s" % [nome, "OK " if condicao else "<<<", detalhe])
	if not condicao:
		_falhas += 1


## Um corpo qualquer na layer 2 (a da Koliani) serve de peso -- não é
## preciso a Koliani inteira, e assim a bancada não depende dos autoloads.
func _peso_falso(pai: Node, onde: Vector2) -> CharacterBody2D:
	var c := CharacterBody2D.new()
	c.set_script(ESPIA)
	c.collision_layer = 2
	c.collision_mask = 1
	c.add_to_group("koliani")
	var col := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(24.0, 48.0)
	col.shape = r
	c.add_child(col)
	pai.add_child(c)
	c.global_position = onde
	return c


func _mundo() -> Node2D:
	var n := Node2D.new()
	root.add_child(n)
	return n


## ⚠ Um `queue_free()` + UM `process_frame` não chega: o chão da bancada
## anterior ainda estava na física quando a seguinte começava, e a medição
## dava zero porque ela já estava pousada antes de começar a cair. Espera-se
## até a árvore o largar mesmo.
func _limpar(m: Node) -> void:
	m.queue_free()
	for _i in 4:
		await process_frame
	await physics_frame


func _plataforma_desce_com_peso() -> void:
	var m := _mundo()
	var pp := PLAT_PESO.new()
	pp.curso = 90.0
	pp.vel_desce = 60.0
	pp.position = Vector2(0.0, 0.0)
	m.add_child(pp)
	await process_frame
	var y0: float = pp.position.y
	# sem peso não pode andar
	await create_timer(0.5).timeout
	_ok("peso: parada sem ninguem em cima", is_equal_approx(pp.position.y, y0),
		"y=%.1f (era %.1f)" % [pp.position.y, y0])
	# com peso desce
	var k := _peso_falso(m, Vector2(0.0, -34.0))
	await create_timer(1.0).timeout
	var desceu: float = pp.position.y - y0
	_ok("peso: desce com ela em cima", desceu > 20.0, "desceu %.0f px" % desceu)
	# tirado o peso, volta a subir
	k.queue_free()
	await create_timer(1.2).timeout
	_ok("peso: volta a subir quando sai", pp.position.y < y0 + desceu - 10.0,
		"y=%.1f (esteve a %.1f)" % [pp.position.y, y0 + desceu])
	await _limpar(m)


func _caixa_empurra_se_e_a_placa_liga() -> void:
	var m := _mundo()
	# chão, senão a caixa cai para sempre
	var chao := StaticBody2D.new()
	chao.collision_layer = 1
	var cc := CollisionShape2D.new()
	var cr := RectangleShape2D.new()
	cr.size = Vector2(900.0, 40.0)
	cc.shape = cr
	chao.add_child(cc)
	m.add_child(chao)
	chao.global_position = Vector2(0.0, 40.0)

	var caixa := BLOCO.new()
	caixa.vel_empurrao = 120.0
	m.add_child(caixa)
	caixa.global_position = Vector2(0.0, -2.0)
	var placa := PLACA.new()
	placa.id = "bancada"
	m.add_child(placa)
	placa.global_position = Vector2(480.0, 20.0)
	await process_frame
	await process_frame
	_ok("caixas: a placa comeca desligada", not bool(placa.ligada), "")

	# ela encosta-se do lado esquerdo e PEDE para a direita. A caixa lê o
	# `InputMap`, não a velocidade dela -- ver o porquê no `bloco_empurravel`.
	var k := _peso_falso(m, Vector2(-40.0, -4.0))
	var x0: float = caixa.global_position.x
	Input.action_press("mover_direita")
	for _i in 90:
		k.velocity.x = 200.0
		k.move_and_slide()
		await physics_frame
	Input.action_release("mover_direita")
	var andou: float = caixa.global_position.x - x0
	_ok("caixas: a caixa e' empurrada", andou > 30.0,
		"andou %.0f px (ela ficou em x=%.0f, corpos no sensor: %d)" % [
			andou, k.global_position.x, 0])

	# e a placa liga com peso em cima
	var k2 := _peso_falso(m, Vector2(480.0, -10.0))
	await create_timer(0.4).timeout
	_ok("caixas: a placa liga com peso", bool(placa.ligada), "")
	k2.queue_free()
	await create_timer(0.7).timeout
	_ok("caixas: a placa solta quando sai", not bool(placa.ligada), "")
	await _limpar(m)


func _atoleiro_afunda() -> void:
	var m := _mundo()
	var za := AFUNDA.new()
	za.tamanho = Vector2(300.0, 120.0)
	m.add_child(za)
	za.global_position = Vector2(0.0, 0.0)
	await process_frame

	# entra na areia
	var k := _peso_falso(m, Vector2(0.0, 0.0))
	# ⚠ `body_entered` nao chega no frame em que o corpo aparece: sem estas
	# esperas a bancada media o ANTES e dizia que a zona nao fazia nada
	for _i in 4:
		await physics_frame
	var _grav: float = k.get("grav_escala")
	var _acel: float = k.get("acel_escala")
	_ok("atoleiro: pesa mais la' dentro", is_equal_approx(_grav, za.peso),
		"grav_escala = %.2f (esperava %.2f)" % [_grav, za.peso])
	_ok("atoleiro: anda mais devagar", is_equal_approx(_acel, za.escala_acel),
		"acel_escala = %.2f (esperava %.2f)" % [_acel, za.escala_acel])

	# e sai dela
	k.global_position = Vector2(900.0, 0.0)
	for _i in 4:
		await physics_frame
	var limpo: bool = is_equal_approx(float(k.get("grav_escala")), 1.0) 		and is_equal_approx(float(k.get("acel_escala")), 1.0)
	_ok("atoleiro: repoe ao sair", limpo,
		"grav=%.2f acel=%.2f" % [k.get("grav_escala"), k.get("acel_escala")])
	await _limpar(m)
