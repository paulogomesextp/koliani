extends SceneTree
## BANCADA DE UM VAO -- mede com a Koliani REAL se um salto concreto de um
## nivel se faz, e com que tecla. Serve o `verifica_alcance.gd`: onde o crivo
## estatico diz "inalcancavel", isto diz se e' o nivel ou o crivo que esta'
## errado, e da' o numero para o crivo aprender (em vez de se alargar um
## limite a olho).
##
## Nao mexe na cena: tira so' os inimigos (mede-se o movimento, nao a luta)
## e teleporta a Koliani para a plataforma de partida. Varre o MOMENTO da
## partida (0 .. `varrer` s, passo 0,1 s) para apanhar a fase das rajadas
## pulsadas e das plataformas moveis -- o que conta e' haver UMA fase em que
## uma pessoa com timing perfeito passa, e quantas das fases passam.
##
## Uso (sempre isolado):
##   python tools/godot_isolado.py -- --headless --fixed-fps 60 --path . \
##     --script res://tools/bench_vao.gd -- cena=<Nome> nivel=<1..100> \
##     kit=dash,salto_duplo parte=<x>,<y> salto=<x> alvo=<no'|porta> \
##     [estrategia=duplo|dash_duplo|simples] [varrer=<s>] [sentido=1|-1]
##
## `alvo=medir` nao procura alvo: da' o percurso horizontal da ORIGEM da
## Koliani desde que sai do chao ate' voltar a' mesma altura (o vao borda a
## borda que isso cobre e' um pouco maior: o corpo tem largura). `vento=off`
## desliga as `WindZone` da cena; `vento_int=<n>` troca-lhes a intensidade
## (para medir o alcance contra ventos mais fortes na mesma geometria).
##
## `alvo` e' o NOME do no' onde tem de aterrar (serve para plataformas
## moveis: conta a colisao com esse corpo), ou `porta` (conta tocar na area
## da Porta, 48x96 -- a porta muda de cena ao toque, mesmo no ar).

const DT := 1.0 / 60.0

var _estado: Node
var _p := {}
var _info := ""


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := String(a).split("=", true, 1)
		if kv.size() == 2:
			_p[kv[0]] = kv[1]
	await process_frame
	_estado = root.get_node_or_null("/root/EstadoJogo")
	if _estado == null or not _p.has("cena"):
		print("uso: cena=<Nome> nivel=<n> kit=a,b parte=x,y salto=x alvo=<no|porta>")
		quit(2)
		return
	_estado.set("modo_dev", false)
	_estado.set("indice_nivel", int(_p.get("nivel", "1")) - 1)
	_estado.set("checkpoint", Vector2.ZERO)
	var kit: Array = String(_p.get("kit", "")).split(",", false)
	(_estado.get("habilidades") as Array).assign(kit)
	(_estado.get("habilidades_suspensas") as Array).clear()
	_estado.set("vidas", 99)
	change_scene_to_file("res://scenes/levels/%s.tscn" % _p["cena"])
	await _esperar(0.8)
	var estrategias: Array = String(_p.get("estrategia", "simples,duplo,dash_duplo")).split(",")
	var varrer := float(_p.get("varrer", "3.2"))
	for e in estrategias:
		var passam: Array[String] = []
		var falhas := {}
		var tentativas := 0
		var t0 := 0.0
		while t0 <= varrer + 0.001:
			tentativas += 1
			var r := await _tentar(String(e), t0)
			if r == "ok":
				passam.append("%.1f" % t0)
				print("      ok t0=%.1f  %s" % [t0, _info])
			else:
				falhas[r] = int(falhas.get(r, 0)) + 1
			t0 += 0.1
		print("[%s] %-10s passa em %d/%d fases %s" % [_p["cena"], e, passam.size(),
			tentativas, ("(t0=" + ",".join(passam) + ")") if not passam.is_empty() else ""])
		for f in falhas:
			print("      %2dx %s" % [int(falhas[f]), f])
	_soltar()
	quit(0)


func _tentar(estrategia: String, espera: float) -> String:
	_soltar()
	for n in get_nodes_in_group("inimigos"):
		n.queue_free()
	if _p.has("vento_int"):
		for z in get_nodes_in_group("zonas_vento"):
			z.set("intensidade", float(_p["vento_int"]))
	if _p.get("vento", "") == "off":
		for z in get_nodes_in_group("zonas_vento"):
			z.set("ativa", false)
	var k := _koliani()
	if k == null:
		k = await _nova_koliani()
		if k == null:
			return "sem Koliani"
	var parte := String(_p["parte"]).split(",")
	k.global_position = Vector2(float(parte[0]), float(parte[1]))
	k.call("reset_physics_interpolation")
	k.set("velocity", Vector2.ZERO)
	await _esperar(0.3 + espera)
	k = _koliani()
	if k == null:
		return "morreu antes de partir"
	var id_k := k.get_instance_id()
	var sentido := int(_p.get("sentido", "1"))
	var dir := "mover_direita" if sentido > 0 else "mover_esquerda"
	var salto_x := float(_p["salto"])
	var alvo := String(_p["alvo"])
	var y_limite := float(parte[1]) + 260.0
	# 1. correr ate' a beira
	Input.action_press(dir)
	var t := 0.0
	var dash_feito := false
	while true:
		await physics_frame
		k = _koliani()
		if _id(k) != id_k:
			return "morreu a correr"
		t += DT
		if t > 6.0:
			return "nao chegou a' beira"
		var x := k.global_position.x * sentido
		if estrategia == "dash_duplo" and not dash_feito and x >= salto_x * sentido - 70.0:
			Input.action_press("dash")
			dash_feito = true
			continue
		if dash_feito:
			Input.action_release("dash")
		if x >= salto_x * sentido or (dash_feito and not bool(k.call("is_on_floor"))):
			break
	# 2. salto (+ duplo no topo do arco), segurando a direcao
	Input.action_press("saltar")
	var duplo := estrategia != "simples"
	var saiu := false
	var t_ar := 0.0
	var ultimo := k.global_position
	var x_saida := 0.0
	var y_saida := 0.0
	while true:
		await physics_frame
		k = _koliani()
		if _id(k) != id_k:
			return "morreu no ar (ultima pos. %.0f,%.0f)" % [ultimo.x, ultimo.y]
		ultimo = k.global_position
		t_ar += DT
		if t_ar > 5.0:
			return "5 s no ar"
		var p := k.global_position
		var v: Vector2 = k.get("velocity")
		var chao := bool(k.call("is_on_floor"))
		if not chao and not saiu:
			saiu = true
			x_saida = p.x
			y_saida = p.y
		if alvo == "medir" and saiu and v.y > 0.0 and p.y >= y_saida:
			_soltar()
			return "alcance %.0f" % absf(p.x - x_saida)
		if alvo == "porta" and _toca_porta(p):
			_soltar()
			return "ok"
		if duplo and saiu and v.y > -30.0:
			Input.action_release("saltar")
			await physics_frame
			Input.action_press("saltar")
			duplo = false
			continue
		if p.y > y_limite:
			_soltar()
			return "caiu no vao (x=%.0f)" % p.x
		if saiu and chao:
			_soltar()
			var onde := _chao_de(k)
			if onde == alvo:
				_info = "sai x=%.0f, aterra x=%.0f" % [x_saida, p.x]
				return "ok"
			return "aterrou em %s" % onde
	return "?"


func _toca_porta(p: Vector2) -> bool:
	var porta := current_scene.get_node_or_null("Porta") as Node2D
	if porta == null:
		return false
	# area da porta 48x96 (centro +2 em y); corpo da Koliani ~ 24x48
	return absf(p.x - porta.global_position.x) < 24.0 + 12.0 \
		and absf(p.y - (porta.global_position.y + 2.0)) < 48.0 + 24.0


func _chao_de(k: CharacterBody2D) -> String:
	for i in k.get_slide_collision_count():
		var c := k.get_slide_collision(i)
		if c.get_normal().y < -0.5:
			var o := c.get_collider() as Node
			return String(o.name) if o else "?"
	return "?"


func _koliani() -> CharacterBody2D:
	var k := get_first_node_in_group("koliani") as CharacterBody2D
	if k == null or k.is_queued_for_deletion() or not k.is_inside_tree():
		return null
	return k


func _nova_koliani() -> CharacterBody2D:
	var t := 0.0
	while t < 10.0:
		await process_frame
		t += DT
		var k := _koliani()
		if k != null:
			await _esperar(0.3)
			return _koliani()
	return null


func _id(n: Object) -> int:
	return n.get_instance_id() if is_instance_valid(n) else 0


func _esperar(segundos: float) -> void:
	var t := 0.0
	while t < segundos:
		await physics_frame
		t += DT


func _soltar() -> void:
	for a in ["mover_direita", "mover_esquerda", "saltar", "dash", "atacar"]:
		Input.action_release(a)
