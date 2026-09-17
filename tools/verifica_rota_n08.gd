extends SceneTree
## PROCESS 11 -- percorre o N08 (Ilhas Suspensas) com a Koliani REAL, em
## progressão normal: sem modo Dev, sem voo, sem imunidade, só com o kit que
## a campanha dá ANTES do N08 (dash, salto duplo, dash aéreo, escalar
## paredes). O planar vem exclusivamente da `ZonaPlanar` da cena.
##
## Uso:
##   Godot --headless --path . --script res://tools/verifica_rota_n08.gd -- [modo]
## modos:
##   rota      (omissão) spawn -> chão da arena, vão a vão, e prova de morte
##             e respawn na fogueira do meio a meio do caminho
##   sem_planar      contrafactual por vão com a `ZonaPlanar` desligada e
##                   salto duplo sempre (tem de falhar nalgum vão)
##   sem_planar_dash o mesmo, com dash aéreo no topo do 2.º arco
##
## É um INDÍCIO de jogabilidade, não um playtest: as teclas são as de uma
## pessoa (segurar saltar, novo toque para o salto duplo, largar a direção
## por cima da ilha), mas o timing é perfeito. Não luta com o chefe.
##
## ⚠ Em `--script` os autoloads não existem como identificador: tudo o que
## lhes toca é por `get_node("/root/...")` e `get()/call()`.

const CENA := "res://scenes/levels/Corredor_das_Execucoes.tscn"
const KIT_N08 := ["dash", "salto_duplo", "dash_aereo", "escalar_paredes"]
const DT := 1.0 / 60.0

## Cada vão: de onde se salta, a ilha-alvo e como se atravessa.
##   salto_x   -- x a partir do qual salta (na beira)
##   x0/x1/topo -- a ilha onde tem de aterrar
##   duplo     -- usa o salto duplo no topo do arco
##   corrente  -- fica na coluna (sem direção) até subir acima de `subir_ate`
##   contra    -- espera na beira pela pausa da `RajadaContra`
const VAOS := [
	{"nome": "ensaio", "salto_x": 440.0, "x0": 740.0, "x1": 1000.0, "topo": 750.0, "duplo": false},
	{"nome": "pedra", "salto_x": 985.0, "x0": 1180.0, "x1": 1260.0, "topo": 820.0, "duplo": false},
	{"nome": "cadeia", "salto_x": 1248.0, "x0": 1640.0, "x1": 1900.0, "topo": 900.0, "duplo": true},
	{"nome": "corrente", "salto_x": 1885.0, "x0": 2170.0, "x1": 2440.0, "topo": 560.0, "duplo": false,
		"corrente": true, "entrar_x": 2030.0, "subir_ate": 610.0},
	{"nome": "elite", "salto_x": 2425.0, "x0": 2560.0, "x1": 2880.0, "topo": 600.0, "duplo": false},
	{"nome": "meio", "salto_x": 2865.0, "x0": 2960.0, "x1": 3240.0, "topo": 600.0, "duplo": false},
	{"nome": "a_favor", "salto_x": 3225.0, "x0": 3880.0, "x1": 4160.0, "topo": 680.0, "duplo": true},
	{"nome": "contra", "salto_x": 4145.0, "x0": 4400.0, "x1": 4640.0, "topo": 700.0, "duplo": true,
		"contra": true},
	{"nome": "arena", "salto_x": 4625.0, "x0": 5000.0, "x1": 5560.0, "topo": 760.0, "duplo": true},
]

var _estado: Node
var _mortes := 0
var _relato: Array[String] = []


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var modo: String = args[0] if args.size() > 0 else "rota"
	await process_frame
	_estado = root.get_node_or_null("/root/EstadoJogo")
	if _estado == null:
		print("SEM EstadoJogo"); quit(2); return
	_preparar_estado()
	change_scene_to_file(CENA)
	var k := await _esperar_koliani(0)
	if k == null:
		print("SEM Koliani"); quit(2); return
	await _esperar(0.6)
	if modo.begins_with("sem_planar"):
		# CONTRAFACTUAL por vão: cada vão começa na sua ilha de partida
		# (teleporte ENTRE vãos, nunca durante), sempre com salto duplo e,
		# em `sem_planar_dash`, com dash aéreo no topo do arco. Mede quais
		# vãos o planar torna possíveis -- não é uma rota jogável.
		var so: String = args[1] if args.size() > 1 else ""
		var passaveis := await _medir_sem_planar(modo == "sem_planar_dash", so)
		_soltar_tudo()
		for linha in _relato:
			print(linha)
		print("RESULTADO %s: %d/%d vaos passaveis sem planar" % [
			modo, passaveis, VAOS.size()])
		quit(0 if passaveis < VAOS.size() else 1)
		return
	var ok := await _percorrer(modo)
	_soltar_tudo()
	for linha in _relato:
		print(linha)
	print("RESULTADO rota: %s  mortes=%d" % ["CHEGOU A ARENA" if ok else "NAO CHEGOU", _mortes])
	quit(0 if ok else 1)


func _preparar_estado() -> void:
	_estado.set("modo_dev", false)
	_estado.set("indice_nivel", 7)
	_estado.set("checkpoint", Vector2.ZERO)
	(_estado.get("habilidades") as Array).assign(KIT_N08)
	(_estado.get("habilidades_suspensas") as Array).clear()
	_estado.set("vidas", 99)
	if _estado.has_method("_limpar_jornada_ancora"):
		_estado.call("_limpar_jornada_ancora")


## `so` = nome de um vão para o medir sozinho ("" = todos em sequência).
func _medir_sem_planar(com_dash: bool, so := "") -> int:
	var passaveis := 0
	var partida_topo := 650.0
	for i in VAOS.size():
		var v: Dictionary = (VAOS[i] as Dictionary).duplicate()
		if so != "" and v["nome"] != so:
			partida_topo = float(v["topo"])
			continue
		v["duplo"] = true
		v["dash"] = com_dash
		var k := _koliani()
		var id_k := k.get_instance_id()
		for z in get_nodes_in_group("zonas_planar"):
			z.set("ativa", false)
		_soltar_tudo()
		k.global_position = Vector2(float(v["salto_x"]) - 70.0, partida_topo - 30.0)
		k.call("reset_physics_interpolation")
		k.set("velocity", Vector2.ZERO)
		await _esperar(0.5)
		var r: String = await _atravessar(v)
		_relato.append("  [%s] %-9s %s" % ["passa" if r == "ok" else "nao  ", v["nome"],
			"" if r == "ok" else r])
		if r == "ok":
			passaveis += 1
		if _id(_koliani()) != id_k:
			await _esperar_koliani(id_k)
			await _esperar(0.4)
		partida_topo = float(v["topo"])
	return passaveis


func _percorrer(modo: String) -> bool:
	var i := 0
	var provou_respawn := false
	while i < VAOS.size():
		var v: Dictionary = VAOS[i]
		var r: String = await _atravessar(v)
		if r == "ok":
			_relato.append("  [ok] %-9s" % v["nome"])
			i += 1
			# a meio do caminho: provar morte + respawn na fogueira do meio
			if modo == "rota" and v["nome"] == "meio" and not provou_respawn:
				provou_respawn = true
				if not await _provar_respawn():
					return false
			continue
		_relato.append("  [FALHA] %-9s %s" % [v["nome"], r])
		return false
	return true


## Um vão, do chão de partida à ilha-alvo. Devolve "ok" ou o motivo.
func _atravessar(v: Dictionary) -> String:
	var k := _koliani()
	var t := 0.0
	# 1. correr até à beira (na rede do ensaio também serve para voltar)
	Input.action_press("mover_direita")
	while true:
		await physics_frame
		k = _koliani()
		if k == null:
			return "Koliani desapareceu"
		t += DT
		if t > 12.0:
			return "não chegou à beira (x=%.0f)" % k.global_position.x
		if bool(k.call("is_on_floor")) and k.global_position.x >= float(v["salto_x"]):
			break
		if v.get("contra", false) and k.global_position.x >= float(v["salto_x"]) - 90.0:
			Input.action_release("mover_direita")
			if bool(k.call("is_on_floor")):
				break
	# 2. vento contra: espera a pausa (as setas apagam-se) e parte logo
	if v.get("contra", false):
		var zona := current_scene.get_node_or_null("RajadaContra")
		var espera := 0.0
		# espera que a rajada esteja LIGADA e depois que desligue: assim
		# parte no início da pausa, como quem lê as setas
		while zona and float(zona.call("multiplicador_atual")) <= 0.0 and espera < 4.0:
			await physics_frame; espera += DT
		while zona and float(zona.call("multiplicador_atual")) > 0.0 and espera < 8.0:
			await physics_frame; espera += DT
		Input.action_press("mover_direita")
		# volta a correr até à beira, que o travão a deixou atrás
		while _koliani() and _koliani().global_position.x < float(v["salto_x"]):
			await physics_frame
	# 3. salta e segura (planar)
	Input.action_press("saltar")
	var duplo_feito := not bool(v.get("duplo", false))
	var dash_por_fazer := false
	var subiu := false
	var t_ar := 0.0
	var saiu_do_chao := false
	var x_morte := k.global_position.x
	var id_ar := k.get_instance_id()
	while true:
		await physics_frame
		var atual := _koliani()
		if _id(atual) != id_ar:
			_mortes += 1
			return "morreu (caiu perto de x=%.0f)" % x_morte
		t_ar += DT
		if t_ar > 10.0:
			return "10 s no ar/sem aterrar (x=%.0f y=%.0f)" % [k.global_position.x, k.global_position.y]
		var p := k.global_position
		x_morte = p.x
		var vel: Vector2 = k.get("velocity")
		var no_chao := bool(k.call("is_on_floor"))
		if not no_chao:
			saiu_do_chao = true
		# salto duplo no topo do arco: novo toque, e volta a segurar
		if not duplo_feito and saiu_do_chao and vel.y > -30.0:
			Input.action_release("saltar")
			await physics_frame
			Input.action_press("saltar")
			duplo_feito = true
			dash_por_fazer = bool(v.get("dash", false))
			continue
		# dash aéreo (só no contrafactual): no topo do 2.º arco
		if dash_por_fazer and vel.y > -30.0 and t_ar > 0.45:
			Input.action_press("dash")
			await physics_frame
			Input.action_release("dash")
			dash_por_fazer = false
			continue
		# direção: corrente = ficar na coluna até subir; senão largar por
		# cima da ilha para não passar do fim dela
		var ir := true
		if v.get("corrente", false) and not subiu:
			if p.x >= float(v["entrar_x"]):
				ir = false
			if p.y <= float(v["subir_ate"]):
				subiu = true
		if p.x >= float(v["x0"]) + 24.0:
			ir = false
		if ir:
			Input.action_press("mover_direita")
		else:
			Input.action_release("mover_direita")
		if OS.has_environment("BOT_VERBOSE") and int(t_ar / DT) % 6 == 0:
			print("    %-9s t=%.2f x=%.0f y=%.0f vx=%.0f vy=%.0f planar=%s ventos=%d" % [
				v["nome"], t_ar, p.x, p.y, vel.x, vel.y,
				str(k.call("esta_a_planar")), int(k.call("quantidade_ventos_ativos"))])
		if saiu_do_chao and no_chao:
			# a origem dela fica ~24 px acima do topo da plataforma onde pisa
			var topo := p.y + 24.0
			if p.x >= float(v["x0"]) - 10.0 and p.x <= float(v["x1"]) + 10.0 \
					and absf(topo - float(v["topo"])) < 20.0:
				Input.action_release("saltar")
				await _esperar(0.12)
				return "ok"
			Input.action_release("saltar")
			return "aterrou fora do alvo (x=%.0f topo≈%.0f)" % [p.x, topo]
	return "?"


## Deixa-se cair no abismo a seguir à fogueira do meio e confirma que
## reaparece lá, sem vento nem planar residuais e com a zona a conceder de
## novo o planar.
func _provar_respawn() -> bool:
	var k := _koliani()
	var id_k := k.get_instance_id()
	Input.action_release("saltar")
	Input.action_press("mover_direita")
	var t := 0.0
	while _id(_koliani()) == id_k and t < 8.0:
		await physics_frame
		t += DT
	Input.action_release("mover_direita")
	if _id(_koliani()) == id_k:
		_relato.append("  [FALHA] respawn: não morreu ao cair")
		return false
	_mortes += 1
	var novo := await _esperar_koliani(id_k)
	await _esperar(0.5)
	novo = _koliani()
	if novo == null:
		_relato.append("  [FALHA] respawn: sem Koliani depois do reload")
		return false
	var p := novo.global_position
	var ventos := int(novo.call("quantidade_ventos_ativos"))
	var planar := int(novo.call("quantidade_planar_contextual"))
	var planando := bool(novo.call("esta_a_planar"))
	var perto := absf(p.x - 3160.0) < 120.0
	_relato.append("  [%s] respawn   x=%.0f y=%.0f ventos=%d planar_ctx=%d a_planar=%s" % [
		"ok" if (perto and ventos == 0 and planar == 1 and not planando) else "FALHA",
		p.x, p.y, ventos, planar, str(planando)])
	return perto and ventos == 0 and planar == 1 and not planando


func _id(n: Object) -> int:
	return n.get_instance_id() if is_instance_valid(n) else 0


func _koliani() -> Node2D:
	var k := get_first_node_in_group("koliani") as Node2D
	if k == null or k.is_queued_for_deletion():
		return null
	return k


## `antiga_id` = instance_id da Koliani que morreu (0 = nenhuma). Passa-se o
## id e nao o no': depois do reload o no' antigo ja' foi libertado.
func _esperar_koliani(antiga_id: int) -> Node2D:
	var t := 0.0
	while t < 10.0:
		await process_frame
		t += DT
		var k := _koliani()
		if k != null and k.get_instance_id() != antiga_id and k.is_inside_tree():
			await physics_frame
			await physics_frame
			return k
	return null


func _esperar(segundos: float) -> void:
	var t := 0.0
	while t < segundos:
		await physics_frame
		t += DT


func _soltar_tudo() -> void:
	for a in ["mover_direita", "mover_esquerda", "saltar", "dash", "atacar"]:
		Input.action_release(a)
