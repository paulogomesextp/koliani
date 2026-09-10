extends Node
## Sonda de desempenho (WINDOWS PERFORMANCE GATE, Execution 8.1).
##
## Corre o runtime REAL (`scenes/Main.tscn` com os autoloads todos vivos, ou
## o `MenuInicial.tscn`) como filho desta sonda e mede o tempo de cada frame
## mais os monitores do `Performance`. Escreve um JSON em `user://perf/`.
##
## Nao e um teste: nao afirma nada, so mede. As conclusoes sao tiradas fora.
##
##   godot --rendering-driver opengl3 --screen 1 --resolution 1152x648 \
##       res://tools/perf_gate.tscn -- <nivel|menu> <segundos> <etiqueta> [flags]
##
## flags:
##   --novsync   desliga o VSync (mede o custo real de CPU/GPU, sem tecto)
##   --idle      so parada (sem input sintetico)
##   --sem-<x>   isolamento: desliga o subsistema `x` antes de medir
##                 (atmosfera, particulas, luzes, hud, parallax, inimigos)

## Frames iniciais deitados fora: carregamento da cena, primeiro `draw` de
## cada shader, `--import` preguicoso. Sem isto a media vem envenenada pelo
## arranque e escondia justamente o que queremos ver.
const AQUECIMENTO := 1.5

var _nivel := 0
var _menu := false
var _segundos := 8.0
var _etiqueta := "sem-nome"
var _idle := false
var _frente := false
var _saltar := false
var _spawn_x := INF
var _ultimo_real_us := 0
var _cap_fps := 0
var _desligar: Array[String] = []

## A morte da Koliani faz `reload_current_scene()` (koliani.gd), e a cena
## actual e' ESTA sonda -- ou seja, morrer reinicia a medicao. O `SceneTree`
## sobrevive ao reload, por isso o estado vive nos metas dele e a medicao
## continua de onde ia. As recargas ficam contadas: sao stutter real.
const META := "perf_gate_estado"

var _t := 0.0
var _amostras: Array[float] = []
var _fase := "aquecimento"
var _fases := {}  # etiqueta -> Array[float]
var _monitores := {}
var _recargas := 0
var _alvo: Node = null
var _arranque_ms := 0
## `--ciclar=N`: recarrega o nivel de N em N segundos. Serve para a prova de
## acumulacao (entrar -> jogar -> recarregar -> repetir) da seccao 10.
var _ciclar := 0.0
var _prox_ciclo := 0.0
var _x_anterior := INF
var _desloc: Array[float] = []
var _movendo := false
## Contagem de nos/objectos no fim de cada ciclo -- se subir de forma
## monotona, ha' fuga.
var _por_ciclo: Array = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		if args[0] == "menu":
			_menu = true
		else:
			_nivel = int(args[0])
	if args.size() > 1:
		_segundos = float(args[1])
	if args.size() > 2:
		_etiqueta = args[2]
	for a in args:
		if a == "--novsync":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		elif a == "--idle":
			_idle = true
		elif a == "--frente":
			_frente = true
		elif a == "--saltar":
			_saltar = true
		elif a.begins_with("--capfps="):
			_cap_fps = int(a.get_slice("=", 1))
		elif a.begins_with("--ciclar="):
			_ciclar = float(a.get_slice("=", 1))
		elif a.begins_with("--sem-"):
			_desligar.append(a.substr(6))

	Engine.max_fps = _cap_fps
	_arranque_ms = Time.get_ticks_msec()
	_recuperar_estado()
	_guardar_save_real()
	print("PERF_GATE inicio | etiqueta=%s | nivel=%d | menu=%s | segundos=%.1f | vsync=%d | desligar=%s | recarga=%d" % [
		_etiqueta, _nivel, str(_menu), _segundos,
		DisplayServer.window_get_vsync_mode(), str(_desligar), _recargas])

	if _menu:
		_alvo = load("res://scenes/ui/MenuInicial.tscn").instantiate()
		add_child(_alvo)
	else:
		EstadoJogo.indice_nivel = _nivel
		EstadoJogo.iniciar_sessao_nivel(true)
		_alvo = load("res://scenes/Main.tscn").instantiate()
		add_child(_alvo)

	if not _desligar.is_empty():
		await get_tree().process_frame
		await get_tree().process_frame
		_aplicar_isolamento()


## A sonda corre o jogo A SERIO, e o jogo grava. Sem isto, medir estragava o
## save do jogador (o `indice_nivel` ficava onde a ultima medicao parou). O
## save real e' posto de lado no arranque e repousto no fim.
const SAVE_REAL := "user://progresso.json"
const SAVE_GUARDADO := "user://perf/progresso_real.bak"


func _guardar_save_real() -> void:
	if _recargas > 0:  # so' na primeira encarnacao
		return
	DirAccess.make_dir_recursive_absolute("user://perf")
	if FileAccess.file_exists(SAVE_REAL):
		DirAccess.copy_absolute(SAVE_REAL, SAVE_GUARDADO)


func _repor_save_real() -> void:
	if not FileAccess.file_exists(SAVE_GUARDADO):
		return
	DirAccess.copy_absolute(SAVE_GUARDADO, SAVE_REAL)
	DirAccess.remove_absolute(SAVE_GUARDADO)
	print("PERF_GATE save do jogador reposto")


## Retoma o que ficou de uma encarnacao anterior desta sonda (a Koliani
## morreu e o `reload_current_scene` deitou a cena fora). Sem isto a medicao
## nunca chegava ao fim: reiniciava a cada morte, em ciclo.
func _recuperar_estado() -> void:
	var arvore := get_tree()
	if not arvore.has_meta(META):
		return
	var e: Dictionary = arvore.get_meta(META)
	if e.get("etiqueta", "") != _etiqueta:
		return
	_t = e.get("t", 0.0)
	_amostras.assign(e.get("amostras", []))
	_fases = e.get("fases", {})
	_monitores = e.get("monitores", {})
	_recargas = int(e.get("recargas", 0)) + 1
	_fase = e.get("fase", "aquecimento")
	_arranque_ms = int(e.get("arranque_ms", Time.get_ticks_msec()))
	_por_ciclo = e.get("por_ciclo", [])
	_prox_ciclo = e.get("prox_ciclo", 0.0)
	# o `_x_anterior` NAO se recupera: a cena nova poe a Koliani noutro sitio
	# e o salto de posicao contaria como um avanco gigante.
	_desloc.assign(e.get("desloc", []))


func _guardar_estado() -> void:
	get_tree().set_meta(META, {
		"etiqueta": _etiqueta, "t": _t, "amostras": _amostras,
		"fases": _fases, "monitores": _monitores,
		"recargas": _recargas, "fase": _fase, "arranque_ms": _arranque_ms,
		"por_ciclo": _por_ciclo, "prox_ciclo": _prox_ciclo,
		"desloc": _desloc,
	})


## Isolamento controlado (seccao 23 do briefing): desliga UM subsistema para
## medir a diferenca. E temporario e so para diagnostico -- nunca fica.
func _aplicar_isolamento() -> void:
	var contados := {}
	for alvo in _desligar:
		var n := 0
		match alvo:
			"atmosfera":
				for a in get_tree().get_nodes_in_group("atmosfera"):
					(a as CanvasItem).visible = false
					(a as Node).process_mode = Node.PROCESS_MODE_DISABLED
					n += 1
			"parallax":
				n = _esconder_por_tipo(_alvo, "Parallax2D") + _esconder_por_tipo(_alvo, "ParallaxLayer")
			"particulas":
				n = _desligar_particulas(_alvo)
			"luzes":
				n = _esconder_por_tipo(_alvo, "PointLight2D") \
					+ _esconder_por_tipo(_alvo, "DirectionalLight2D")
			"hud":
				for c in _alvo.get_children():
					if c is CanvasLayer:
						(c as CanvasLayer).visible = false
						n += 1
			"inimigos":
				for e in get_tree().get_nodes_in_group("inimigos"):
					if not (e as Node).is_in_group("chefes"):
						(e as Node).process_mode = Node.PROCESS_MODE_DISABLED
						if e is CanvasItem:
							(e as CanvasItem).visible = false
						n += 1
		contados[alvo] = n
	print("PERF_GATE isolamento aplicado: %s" % str(contados))


func _esconder_por_tipo(raiz: Node, tipo: String) -> int:
	var n := 0
	if raiz.is_class(tipo) and raiz is CanvasItem:
		(raiz as CanvasItem).visible = false
		return 1
	for f in raiz.get_children():
		n += _esconder_por_tipo(f, tipo)
	return n


func _desligar_particulas(raiz: Node) -> int:
	var n := 0
	if raiz is GPUParticles2D:
		(raiz as GPUParticles2D).emitting = false
		(raiz as GPUParticles2D).visible = false
		n = 1
	elif raiz is CPUParticles2D:
		(raiz as CPUParticles2D).emitting = false
		(raiz as CPUParticles2D).visible = false
		n = 1
	for f in raiz.get_children():
		n += _desligar_particulas(f)
	return n


func _process(dt: float) -> void:
	_t += dt
	# Buraco medido a' PAREDE (imune ao time_scale) e impresso JA', para
	# ficar intercalado com as linhas de carregamento do `--verbose` --
	# e' assim que se ve o que estava a carregar no instante do engasgo.
	var _ag := Time.get_ticks_usec()
	if _ultimo_real_us > 0:
		var _g := (_ag - _ultimo_real_us) / 1000.0
		if _g > 25.0:
			print(">>> PERF_GAP %.0f ms (time_scale=%.2f, t=%.1fs)" % [_g, Engine.time_scale, _t])
	_ultimo_real_us = _ag

	# Rede de seguranca: se por alguma razao o tempo de jogo nunca chegar ao
	# fim (pausa, `time_scale`, mortes em cadeia), a sonda sai na mesma em vez
	# de ficar pendurada a comer CPU.
	if Time.get_ticks_msec() - _arranque_ms > int((AQUECIMENTO + _segundos) * 6000.0) + 30000:
		print("PERF_GATE aviso: limite de tempo de parede atingido")
		_terminar()
		return

	if _t < AQUECIMENTO:
		return

	var nova_fase := _fase_do_momento()
	if nova_fase != _fase:
		_fase = nova_fase
		_largar_tudo()
	_conduzir(dt)
	if not _fases.has(_fase):
		_fases[_fase] = []
	(_fases[_fase] as Array).append(dt)
	_amostras.append(dt)
	_amostrar_monitores()
	_medir_suavidade()
	_guardar_estado()

	if _t >= AQUECIMENTO + _segundos:
		_terminar()
		return

	if _ciclar > 0.0 and _t >= _prox_ciclo:
		_prox_ciclo = _t + _ciclar
		_por_ciclo.append({
			"t": _t,
			"nos": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			"objetos": Performance.get_monitor(Performance.OBJECT_COUNT),
			"orfaos": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
			"mem": Performance.get_monitor(Performance.MEMORY_STATIC),
			"tex_mem": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		})
		_largar_tudo()
		_guardar_estado()
		get_tree().reload_current_scene()


## Guiao de actividade: parada -> a andar -> a andar e a bater. Sem isto
## media-se sempre o caso mais barato (a Koliani quieta) e a queda de frames
## que o Game Master ve em jogo nunca aparecia.
func _fase_do_momento() -> String:
	if _menu or _idle:
		return "idle"
	var d := _t - AQUECIMENTO
	var terco := _segundos / 3.0
	if d < terco:
		return "parada"
	elif d < terco * 2.0:
		return "movimento"
	return "combate"


func _largar_tudo() -> void:
	for a in ["mover_direita", "mover_esquerda", "atacar", "saltar"]:
		if InputMap.has_action(a):
			Input.action_release(a)


## Input sintetico sem corrotinas: uma corrotina a dormir num `await` morre
## mal a Koliani morre (o `reload` liberta esta sonda) e deixa accoes presas.
## Um relogio no `_process` nao tem esse problema.
var _ciclo := 0.0


func _conduzir(dt: float) -> void:
	if _menu or _idle:
		return
	_ciclo += dt
	_movendo = _fase != "parada"
	if _fase == "parada":
		return

	# `--frente`: atravessa o nivel a serio (e morre pelo caminho, o que a
	# persistencia aguenta). E' o unico modo que chega aos inimigos, as VFX e
	# as zonas carregadas do nivel -- o vaivem so' mede a area do spawn.
	# `--saltar`: fica no spawn e so' salta. E' o repro do Paulo -- "no nivel 1
	# fica no spawn e salta varias vezes, ao fim de alguns saltos congela".
	if _saltar:
		# salto duplo (dois toques) + vaivem: e' o repro do Paulo, e e' o que
		# gera mais aterragens, logo mais sons de passo pela primeira vez.
		var c := fmod(_ciclo, 0.9)
		_premir("saltar", c < 0.09 or (c > 0.20 and c < 0.29))
		# Vaivem CURTO e preso ao spawn. O Paulo: "faca esse teste em cima da
		# plataforma, sem cair" -- e tinha razao: a cair, ela morria, a cena
		# recarregava, e os ~1,95 s da recarga contavam como engasgo e
		# escondiam o que se queria medir.
		var esq := fmod(_ciclo, 1.0) < 0.5
		_premir("mover_direita", esq)
		_premir("mover_esquerda", not esq)
		var k := get_tree().get_first_node_in_group("koliani") as Node2D
		if k:
			if _spawn_x == INF:
				_spawn_x = k.global_position.x
			# nao a deixa sair da plataforma do spawn
			if absf(k.global_position.x - _spawn_x) > 110.0:
				k.global_position.x = _spawn_x
				k.reset_physics_interpolation()
		return

	if _frente:
		_premir("mover_direita", true)
		_premir("saltar", fmod(_ciclo, 0.9) < 0.14)
		if _fase == "combate":
			_premir("atacar", fmod(_ciclo, 0.34) < 0.09)
		return

	# Vaivem em vez de "sempre em frente": prende-a perto do spawn e evita que
	# caia no pantano mortal a cada poucos segundos. Continua a exercitar
	# movimento, camara, animacao e viragem -- que e' o que se quer medir.
	var meio := fmod(_ciclo, 2.4) < 1.2
	_premir("mover_direita", meio)
	_premir("mover_esquerda", not meio)
	_premir("saltar", fmod(_ciclo, 1.1) < 0.12)
	if _fase == "combate":
		_premir("atacar", fmod(_ciclo, 0.34) < 0.09)


func _premir(accao: String, ligado: bool) -> void:
	if not InputMap.has_action(accao):
		return
	if ligado and not Input.is_action_pressed(accao):
		Input.action_press(accao)
	elif not ligado and Input.is_action_pressed(accao):
		Input.action_release(accao)


## JUDDER: o ecra actualiza a 165 Hz mas a fisica corre a 60 Hz. Sem
## interpolacao de fisica, a posicao DESENHADA da Koliani so muda nos ticks
## de fisica -- os outros frames repetem a mesma posicao. Mede-se aqui a
## fraccao de frames desenhados em que ela nao andou nada: se for alta, o
## movimento anda aos saltos mesmo com os FPS altos, e e' isso que se le
## como "frame drop".
func _medir_suavidade() -> void:
	var k := get_tree().get_first_node_in_group("koliani") as Node2D
	if k == null:
		return
	var x := k.global_position.x
	if _x_anterior != INF:
		var d := absf(x - _x_anterior)
		# so' conta enquanto ela anda mesmo (senao "parada" contava tudo)
		if _movendo or d > 0.0001:
			_desloc.append(d)
	_x_anterior = x


func _resumo_suavidade() -> Dictionary:
	if _desloc.size() < 30:
		return {}
	var parados := 0
	var soma := 0.0
	for d in _desloc:
		if d < 0.0001:
			parados += 1
		soma += d
	var n := _desloc.size()
	var media := soma / n
	# desvio relativo do avanco por frame: 0 = perfeitamente suave
	var var_soma := 0.0
	for d in _desloc:
		var_soma += (d - media) * (d - media)
	return {
		"frames_medidos": n,
		"frames_sem_avanco_pc": 100.0 * parados / n,
		"avanco_medio_px": media,
		"desvio_relativo": (sqrt(var_soma / n) / media) if media > 0.0 else 0.0,
	}


func _amostrar_monitores() -> void:
	var m := {
		"fps": Performance.TIME_FPS,
		"process_ms": Performance.TIME_PROCESS,
		"physics_ms": Performance.TIME_PHYSICS_PROCESS,
		"draw_calls": Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME,
		"prims": Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME,
		"video_mem": Performance.RENDER_VIDEO_MEM_USED,
		"tex_mem": Performance.RENDER_TEXTURE_MEM_USED,
		"mem_static": Performance.MEMORY_STATIC,
		"objetos": Performance.OBJECT_COUNT,
		"nos": Performance.OBJECT_NODE_COUNT,
		"orfaos": Performance.OBJECT_ORPHAN_NODE_COUNT,
		"fis_activos": Performance.PHYSICS_2D_ACTIVE_OBJECTS,
		"fis_pares": Performance.PHYSICS_2D_COLLISION_PAIRS,
	}
	for chave in m:
		var v := Performance.get_monitor(m[chave])
		if not _monitores.has(chave):
			_monitores[chave] = {"soma": 0.0, "n": 0, "max": -INF, "min": INF, "ultimo": 0.0}
		var r: Dictionary = _monitores[chave]
		r["soma"] += v
		r["n"] += 1
		r["max"] = maxf(r["max"], v)
		r["min"] = minf(r["min"], v)
		r["ultimo"] = v


func _resumo(amostras: Array) -> Dictionary:
	if amostras.is_empty():
		return {}
	var ord := amostras.duplicate()
	ord.sort()
	var soma := 0.0
	for v in ord:
		soma += v
	var n := ord.size()
	var media: float = soma / n
	# Frames "perdidos": acima de 20 ms ja se nota num alvo de 60 Hz (16,7 ms);
	# acima de 33 ms e um frame inteiro comido.
	var acima20 := 0
	var acima33 := 0
	var acima50 := 0
	for v in ord:
		if v > 0.020:
			acima20 += 1
		if v > 0.033:
			acima33 += 1
		if v > 0.050:
			acima50 += 1
	return {
		"frames": n,
		"fps_medio": 1.0 / media if media > 0.0 else 0.0,
		"ms_medio": media * 1000.0,
		"ms_p50": ord[int(n * 0.50)] * 1000.0,
		"ms_p95": ord[mini(int(n * 0.95), n - 1)] * 1000.0,
		"ms_p99": ord[mini(int(n * 0.99), n - 1)] * 1000.0,
		"ms_max": ord[n - 1] * 1000.0,
		"fps_1pc_low": 1.0 / ord[mini(int(n * 0.99), n - 1)],
		"frames_acima_20ms": acima20,
		"frames_acima_33ms": acima33,
		"frames_acima_50ms": acima50,
		"pc_acima_33ms": 100.0 * acima33 / n,
	}


func _terminar() -> void:
	set_process(false)
	_largar_tudo()
	get_tree().remove_meta(META)
	_repor_save_real()

	var out := {
		"etiqueta": _etiqueta,
		"nivel": _nivel,
		"menu": _menu,
		"desligado": _desligar,
		"recargas_por_morte": _recargas,
		"por_ciclo": _por_ciclo,
		"vsync": DisplayServer.window_get_vsync_mode(),
		"suavidade": _resumo_suavidade(),
		"physics_tps": Engine.physics_ticks_per_second,
		"interpolacao_fisica": ProjectSettings.get_setting(
			"physics/common/physics_interpolation", false),
		"ecra_hz": DisplayServer.screen_get_refresh_rate(
			DisplayServer.window_get_current_screen()),
		"total": _resumo(_amostras),
		"fases": {},
		"monitores": {},
	}
	for f in _fases:
		out["fases"][f] = _resumo(_fases[f])
	for k in _monitores:
		var r: Dictionary = _monitores[k]
		out["monitores"][k] = {
			"medio": r["soma"] / maxf(r["n"], 1.0),
			"max": r["max"],
			"min": r["min"],
			"fim": r["ultimo"],
		}

	var dir := "user://perf"
	DirAccess.make_dir_recursive_absolute(dir)
	var caminho := "%s/%s.json" % [dir, _etiqueta]
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(out, "  "))
		f.close()

	print("PERF_GATE_JSON_INICIO")
	print(JSON.stringify(out, "  "))
	print("PERF_GATE_JSON_FIM")
	print("PERF_GATE ficheiro: ", ProjectSettings.globalize_path(caminho))
	get_tree().quit(0)
