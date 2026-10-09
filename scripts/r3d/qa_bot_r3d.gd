extends Node
## QA da Koliani 3D: um bot joga N01..N05 pelo fluxo REAL (Main.tscn -> nivel
## 3D -> portal -> avancar_nivel -> Main.tscn). Correr SEMPRE isolado:
##   python tools/godot_isolado.py --sandbox <dir> -- --path . res://scenes/r3d/QA_R3D.tscn -- \
##       --nivel=1 [--ate=5] [--capturas=<dir>] [--god] [--limite=600]
## Escreve "QA_R3D PASS nivel=N t=..s" / "QA_R3D FALHA ..." e sai com 0/1.

var nivel_ini := 1
var nivel_fim := 1
var dir_fotos := ""
var god := false
var limite := 600.0
var _t := 0.0
var _t_nivel := 0.0
var _nivel_atual := -1
var _wp := 0
var _melhor_d := INF
var _sem_progresso := 0.0
var _fotos_tiradas := {}
var _resultado := {}
var _salto_t := 0.0
var _ataque_t := 0.0
var _a_terminar := false
var _mortes := 0
var _foto_t := 0.0
var _foto_n := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--nivel="):
			nivel_ini = int(a.get_slice("=", 1))
			nivel_fim = nivel_ini
		elif a.begins_with("--ate="):
			nivel_fim = int(a.get_slice("=", 1))
		elif a.begins_with("--capturas="):
			dir_fotos = a.get_slice("=", 1)
		elif a == "--god":
			god = true
		elif a.begins_with("--limite="):
			limite = float(a.get_slice("=", 1))
	# save isolado (sandbox): campanha limpa, so' com os niveis anteriores feitos
	EstadoJogo.indice_nivel = nivel_ini - 1
	for i in nivel_ini - 1:
		if i not in EstadoJogo.concluidos:
			EstadoJogo.concluidos.append(i)
	EstadoJogo.vidas = 9
	Nivel3D.limpar_checkpoint()
	Nivel3D.qa_auto = true
	print("QA_R3D inicio niveis %d..%d god=%s" % [nivel_ini, nivel_fim, god])
	var bot := duplicate_bot()
	bot.name = "QABotR3D"
	get_tree().root.add_child.call_deferred(bot)
	queue_free.call_deferred()
	get_tree().change_scene_to_file.call_deferred("res://scenes/Main.tscn")


## Builds exportados (sem "path override"): `Koliani.exe -- --nivel=1 --ate=5
## --qa-r3d [--capturas=dir]` -- o menu salta para o nivel e o Nivel3D chama isto.
static func instalar_se_pedido(arvore: SceneTree) -> void:
	var args := OS.get_cmdline_user_args()
	if not ("--qa-r3d" in args) or arvore.root.has_node("QABotR3D"):
		return
	var b := Bot.new()
	b.name = "QABotR3D"
	for a in args:
		if a.begins_with("--nivel="):
			b.nivel_ini = int(a.get_slice("=", 1))
			b.nivel_fim = maxi(b.nivel_fim, b.nivel_ini)
		elif a.begins_with("--ate="):
			b.nivel_fim = int(a.get_slice("=", 1))
		elif a.begins_with("--capturas="):
			b.dir_fotos = a.get_slice("=", 1)
		elif a.begins_with("--limite="):
			b.limite = float(a.get_slice("=", 1))
		elif a == "--god":
			b.god = true
	Nivel3D.qa_auto = true
	EstadoJogo.vidas = 9
	print("QA_R3D (build) niveis %d..%d" % [b.nivel_ini, b.nivel_fim])
	arvore.root.add_child.call_deferred(b)


## Prova do FRONT-END real: Menu -> botao Niveis -> Seletor (Regiao I) ->
## confirmar N01 com `ui_accept` -> gameplay 3D. Grava 3 capturas e sai.
static func instalar_ui_se_pedido(arvore: SceneTree) -> void:
	var args := OS.get_cmdline_user_args()
	if not ("--qa-r3d-ui" in args) or arvore.root.has_node("QAUiR3D"):
		return
	var u := UiBot.new()
	u.name = "QAUiR3D"
	for a in args:
		if a.begins_with("--capturas="):
			u.dir = a.get_slice("=", 1)
	arvore.root.add_child.call_deferred(u)


class UiBot:
	extends Node
	var dir := ""
	var _passo := 0
	var _t := 0.0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _aceitar() -> void:
		for p in [true, false]:
			var ev := InputEventKey.new()
			ev.keycode = KEY_ENTER
			ev.physical_keycode = KEY_ENTER
			ev.pressed = p
			Input.parse_input_event(ev)

	func _foto(n: String) -> void:
		if dir != "":
			get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, n])

	func _process(dt: float) -> void:
		_t += dt
		var cena := get_tree().current_scene
		if cena == null:
			return
		var nome := str(cena.scene_file_path)
		match _passo:
			0:
				if nome.ends_with("MenuInicial.tscn") and _t > 2.0:
					_foto("ui_1_menu")
					var botoes: Dictionary = cena.get("_botoes")
					print("QA_R3D_UI menu ok; a carregar em Niveis")
					(botoes["niveis"] as Button).pressed.emit()
					_passo = 1
					_t = 0.0
			1:
				if nome.ends_with("MapaMundo.tscn") and _t > 2.5:
					_foto("ui_2_seletor")
					var sel: Node = cena.get("_seletor")
					sel.call("configurar", 0, true)
					print("QA_R3D_UI seletor ok; a confirmar N01")
					_aceitar()
					_passo = 10
					_t = 0.0
			10:
				# o seletor abre primeiro a REGIAO (carrossel) e depois o nivel
				if _t > 1.2:
					_foto("ui_2b_regiao_I")
					_aceitar()
					_passo = 2
					_t = 0.0
			2:
				var n3d := false
				for f in cena.get_children():
					if f is Nivel3D:
						n3d = true
				if n3d and _t > 3.5:
					_foto("ui_3_n01_3d")
					var cam := get_viewport().get_camera_3d()
					var kk := get_tree().get_first_node_in_group("koliani") as Node3D
					print("QA_R3D_UI camara=%s koliani=%s" % [cam.global_position if cam else "-", kk.global_position if kk else "-"])
					print("QA_R3D_UI OK Menu -> Niveis -> N01 3D (indice=%d)" % EstadoJogo.indice_nivel)
					get_tree().quit(0)
				elif _t > 20.0:
					print("QA_R3D_UI FALHA cena=%s" % nome)
					get_tree().quit(1)


## O bot vive na raiz (sobrevive as trocas de cena).
func duplicate_bot() -> Node:
	var b := Bot.new()
	b.nivel_ini = nivel_ini
	b.nivel_fim = nivel_fim
	b.dir_fotos = dir_fotos
	b.god = god
	b.limite = limite
	return b


class Bot:
	extends Node
	var nivel_ini := 1
	var nivel_fim := 1
	var dir_fotos := ""
	var god := false
	var limite := 600.0
	var _t := 0.0
	var _t_nivel := 0.0
	var _nivel: Nivel3D
	var _idx := -1
	var _wp := 0
	var _melhor := INF
	var _parado := 0.0
	var _salto_seg := 0.0
	var _ataque_cd := 0.0
	var _fotos := 0
	var _proxima_foto := 2.0
	var _fim := false
	var _mortes := 0
	var _vivo_ant := true
	var _registo: Array[String] = []
	var _pos_ant := Vector3.INF
	var _fps_soma := 0.0
	var _fps_n := 0
	var _fps_min := 9999.0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _physics_process(dt: float) -> void:
		if _fim:
			return
		_t += dt
		if _t > limite:
			_terminar(false, "limite de tempo global (%ds) no nivel %d wp=%d" % [int(limite), EstadoJogo.indice_nivel + 1, _wp])
			return
		var cena := get_tree().current_scene
		if cena == null:
			return
		var n: Nivel3D = null
		for f in cena.get_children():
			if f is Nivel3D:
				n = f
		if n == null:
			if EstadoJogo.indice_nivel + 1 > nivel_fim and _idx >= 0:
				_registo.append("QA_R3D PASS nivel=%d t=%.1fs mortes=%d fps_med=%.0f fps_min=%.0f" % [_idx + 1, _t_nivel,
					_mortes, _fps_soma / maxf(_fps_n, 1), _fps_min])
				_terminar(true, "cadeia concluida")
			return
		if n != _nivel:
			if _nivel != null or _idx >= 0:
				pass
			_nivel = n
			if EstadoJogo.indice_nivel != _idx:
				if _idx >= 0:
					_registo.append("QA_R3D PASS nivel=%d t=%.1fs mortes=%d fps_med=%.0f fps_min=%.0f" % [_idx + 1, _t_nivel,
						_mortes, _fps_soma / maxf(_fps_n, 1), _fps_min])
					print(_registo[_registo.size() - 1])
					if EstadoJogo.indice_nivel + 1 > nivel_fim or EstadoJogo.indice_nivel >= 5:
						_terminar(true, "cadeia concluida")
						return
				_idx = EstadoJogo.indice_nivel
				_t_nivel = 0.0
				_fps_soma = 0.0
				_fps_n = 0
				_fps_min = 9999.0
				_mortes = 0
				_fotos = 0
				_proxima_foto = 2.5
				print("QA_R3D a jogar nivel %d (%d pontos de rota)" % [_idx + 1, n.rota_bot.size()])
			_wp = _wp_inicial(n)
			_melhor = INF
			_parado = 0.0
		_t_nivel += dt
		if _t_nivel > 2.0:
			var f := Engine.get_frames_per_second()
			_fps_soma += f
			_fps_n += 1
			_fps_min = minf(_fps_min, f)
		var k := n.koliani
		if k == null or not is_instance_valid(k):
			return
		k.controlo_externo = true
		k.invulneravel_debug = god
		if k.esta_morta():
			if _vivo_ant:
				_mortes += 1
				print("QA_R3D morte nivel=%d wp=%d pos=%s" % [_idx + 1, _wp, k.global_position])
			_vivo_ant = false
			return
		_vivo_ant = true
		# respawn (teleporte): recomecar no ponto da rota mais proximo
		if _pos_ant != Vector3.INF and k.global_position.distance_to(_pos_ant) > 3.0:
			_wp = _wp_inicial(n)
			_melhor = INF
		_pos_ant = k.global_position
		_fotografar(n, k, dt)
		_conduzir(n, k, dt)

	func _wp_inicial(n: Nivel3D) -> int:
		# depois de um respawn no checkpoint, recomecar no ponto mais proximo
		var k := n.koliani
		if k == null:
			return 0
		var melhor := 0
		var md := INF
		for i in n.rota_bot.size():
			var d: float = (n.rota_bot[i]["p"] as Vector3).distance_to(k.global_position)
			if d < md:
				md = d
				melhor = i
		return melhor

	func _conduzir(n: Nivel3D, k: Koliani3D, dt: float) -> void:
		_ataque_cd -= dt
		_salto_seg -= dt
		var chefe := get_tree().get_first_node_in_group("chefes")
		if chefe is ChefeCoracao3D and bool(chefe.get("_combate")):
			_modo_chefe(chefe, k)
			_parado = 0.0
			return
		if _salto_seg <= 0.0 and _salto_seg > -dt * 1.5:
			pass
		# inimigo perto -> combater
		var alvo := _inimigo_perto(k, 3.2)
		if alvo:
			var d := alvo.global_position - k.global_position
			d.y = 0.0
			k.entrada_mov = _para_entrada(d.normalized() * (0.4 if d.length() > 1.6 else 0.0))
			if _ataque_cd <= 0.0:
				k.bot_atacar()
				_ataque_cd = 0.16
			_parado = 0.0
			return
		if _wp >= n.rota_bot.size():
			k.entrada_mov = Vector2.ZERO
			return
		var w: Dictionary = n.rota_bot[_wp]
		var p: Vector3 = w["p"]
		var dd := p - k.global_position
		var dh := Vector2(dd.x, dd.z).length()
		# pontos de "atacar": esperar que a zona fique limpa
		if w["atacar"]:
			var perto := _inimigo_perto(k, 9.0)
			if perto:
				var d2 := perto.global_position - k.global_position
				d2.y = 0.0
				k.entrada_mov = _para_entrada(d2.normalized())
				_parado = 0.0
				return
		var chegou := dh < (0.55 if w["salto"] else 0.9)
		if chegou and w["salto"] and not k.is_on_floor():
			k.entrada_mov = Vector2.ZERO
			return
		if chegou:
			if w["salto"]:
				k.bot_saltar()
			_wp += 1
			_melhor = INF
			_parado = 0.0
			return
		# a meio de um salto: continuar para o proximo ponto
		var dirv := Vector3(dd.x, 0, dd.z).normalized()
		if _wp > 0 and n.rota_bot[_wp - 1]["salto"] and not k.is_on_floor():
			dirv = Vector3(dd.x, 0, dd.z).normalized()
		k.entrada_mov = _para_entrada(dirv)
		if dh < _melhor - 0.05:
			_melhor = dh
			_parado = 0.0
		else:
			_parado += dt
			if _parado > 7.0:
				_terminar(false, "BLOQUEADO nivel=%d wp=%d alvo=%s pos=%s" % [_idx + 1, _wp, p, k.global_position])

	## Luta com o Coracao: salta as ondas, sai das marcas de raiz, rebenta os
	## brotos e so' bate no nucleo exposto (como um jogador que leu o chefe).
	var _fotos_chefe := 0
	var _t_chefe := 0.0

	func _foto(nome: String) -> void:
		if dir_fotos == "":
			return
		var c := "%s/%s.png" % [dir_fotos, nome]
		get_viewport().get_texture().get_image().save_png(c)
		print("QA_R3D foto ", c)

	func _modo_chefe(chefe: ChefeCoracao3D, k: Koliani3D) -> void:
		_t_chefe += get_physics_process_delta_time()
		if _fotos_chefe == 0 and _t_chefe > 3.0:
			_fotos_chefe = 1
			_foto("n05_chefe_1")
		elif _fotos_chefe == 1 and chefe.esta_exposto() and _t_chefe > 8.0:
			_fotos_chefe = 2
			_foto("n05_chefe_2_exposto")
		elif _fotos_chefe == 2 and chefe.fase2() and chefe.get("_ondas").size() > 0:
			_fotos_chefe = 3
			_foto("n05_chefe_3_fase2")
		var c := chefe.global_position
		var kp := k.global_position
		var rel := Vector3(kp.x - c.x, 0, kp.z - c.z)
		var dist := maxf(rel.length(), 0.01)
		var dir := rel / dist
		for o in chefe.get("_ondas"):
			var r: float = o["r"]
			if r < dist + 0.2 and dist - r < 1.9 and k.is_on_floor():
				k.bot_saltar()
		for m in chefe.get("_marcas"):
			if m["saiu"]:
				continue
			var mp: Vector3 = m["pos"]
			var fuga := Vector3(kp.x - mp.x, 0, kp.z - mp.z)
			if fuga.length() < float(m["raio"]) + 1.0:
				if fuga.length() < 0.1:
					fuga = dir.cross(Vector3.UP)
				var tang := dir.cross(Vector3.UP) * (1.0 if fuga.dot(dir.cross(Vector3.UP)) >= 0.0 else -1.0)
				k.entrada_mov = _para_entrada((fuga.normalized() + tang).normalized())
				return
		var alvo := c + dir * 7.0
		var ataca := false
		var broto: Node3D = null
		var md := INF
		for b in get_tree().get_nodes_in_group("alvos3d"):
			if b is Node3D and not bool(b.get("morto")):
				var dd := (b as Node3D).global_position.distance_to(kp)
				if dd < md:
					md = dd
					broto = b
		if broto:
			var bp := broto.global_position
			alvo = bp + Vector3(kp.x - bp.x, 0, kp.z - bp.z).normalized() * 1.2
			ataca = md < 2.2
		elif chefe.esta_exposto():
			alvo = c + dir * 3.6
			ataca = dist < 4.9
		var mv := alvo - kp
		mv.y = 0.0
		k.entrada_mov = _para_entrada(mv.normalized()) if mv.length() > 0.4 else Vector2.ZERO
		if ataca and _ataque_cd <= 0.0:
			k.bot_atacar()
			_ataque_cd = 0.16

	func _inimigo_perto(k: Node3D, r: float) -> Node3D:
		var melhor: Node3D = null
		var md := r
		for g in ["inimigos3d", "alvos3d", "chefes"]:
			for e in get_tree().get_nodes_in_group(g):
				if not (e is Node3D) or bool(e.get("morto")):
					continue
				if e.has_method("bot_pode_atacar") and not e.call("bot_pode_atacar"):
					continue
				var d: Vector3 = (e as Node3D).global_position - k.global_position
				if absf(d.y) > 2.2:
					continue
				var h := Vector2(d.x, d.z).length() - float(e.get("raio_corpo") if e.get("raio_corpo") != null else 0.5)
				if h < md:
					md = h
					melhor = e
		return melhor

	## mundo -> entrada relativa a camara
	func _para_entrada(w: Vector3) -> Vector2:
		var cam := get_viewport().get_camera_3d()
		if cam == null:
			return Vector2(w.x, -w.z)
		var f := -cam.global_transform.basis.z
		f.y = 0.0
		f = f.normalized()
		var r := cam.global_transform.basis.x
		r.y = 0.0
		r = r.normalized()
		return Vector2(w.dot(r), w.dot(f))

	func _fotografar(n: Nivel3D, k: Node3D, dt: float) -> void:
		if dir_fotos == "" or _fotos >= 3:
			return
		var marcas := [0.18, 0.5, 0.85]
		var prog := float(_wp) / maxf(n.rota_bot.size(), 1)
		if prog >= marcas[_fotos] and _t_nivel > 2.0:
			var img := get_viewport().get_texture().get_image()
			var c := "%s/n%02d_%d.png" % [dir_fotos, _idx + 1, _fotos + 1]
			img.save_png(c)
			print("QA_R3D foto ", c)
			_fotos += 1

	func _terminar(ok: bool, msg: String) -> void:
		_fim = true
		print("QA_R3D %s %s" % ["OK" if ok else "FALHA", msg])
		for r in _registo:
			print(r)
		get_tree().paused = false
		Engine.time_scale = 1.0
		get_tree().quit(0 if ok else 1)
