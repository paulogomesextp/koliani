extends Node
## Bancada de combate (Execution 8.1C — COMBAT FREEZE GATE).
##
## Mede a PARAGEM REAL do jogo em cada contacto de combate. O `_hitstop` põe
## `Engine.time_scale = 0.0`, portanto o `delta` do `_process` vem a zero e
## nenhuma medição baseada em `delta` consegue ver a paragem -- daí usar-se
## `Time.get_ticks_usec()`, que é tempo de parede e ignora o `time_scale`.
##
##   godot --screen 1 --resolution 1280x720 res://tools/bench_combate.tscn \
##       -- <nivel> <etiqueta> [--sem-hitstop]
##
## Fases, para separar o que o briefing manda separar:
##   ar       -- ataca o vazio (nenhum inimigo perto)     -> MISS
##   acerto   -- colada a um inimigo, ataca em série      -> DANO DADO
##   receber  -- colada a um inimigo, NÃO ataca           -> DANO RECEBIDO
##
## Escreve `user://perf/<etiqueta>.json`.

const DUR_FASE := 7.0
const AQUECIMENTO := 2.5

var _nivel := 0
var _etiqueta := "combate"
var _sem_hitstop := false
var _chefe := false

var _t0 := 0
var _fase := "aquecimento"
var _fase_t := 0.0
var _fases := ["acerto", "receber"]
var _idx := -1

var _ultimo_us := 0
var _em_paragem := false
var _paragem_ini := 0
var _paragens: Array = []          # {fase, ms}
var _buracos: Array = []           # {fase, ms, time_scale} -- frames longos
var _koliani: Node = null
var _vida_ant := -1
var _dano_dado := 0
var _dano_levado := 0
var _ataques := 0
var _ancora := Vector2.ZERO


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_nivel = int(args[0])
	if args.size() > 1:
		_etiqueta = args[1]
	for a in args:
		if a == "--sem-hitstop":
			_sem_hitstop = true
		elif a == "--chefe":
			_chefe = true

	# A bancada TEM de continuar a medir mesmo com a árvore em pausa (diálogo
	# de chefe, menu). Com o modo herdado, uma pausa parava a própria medição
	# e a bancada ficava pendurada para sempre.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_t0 = Time.get_ticks_usec()
	_ultimo_us = _t0
	EstadoJogo.indice_nivel = _nivel
	EstadoJogo.iniciar_sessao_nivel(true)
	add_child(load("res://scenes/Main.tscn").instantiate())
	print("BENCH inicio | nivel=%d | etiqueta=%s | sem_hitstop=%s" % [
		_nivel, _etiqueta, str(_sem_hitstop)])


func _relogio() -> float:
	return (Time.get_ticks_usec() - _t0) / 1_000_000.0


func _process(_dt: float) -> void:
	var agora := Time.get_ticks_usec()
	var real_ms := (agora - _ultimo_us) / 1000.0
	_ultimo_us = agora

	# --- deteção da paragem global --------------------------------------
	var parado := Engine.time_scale < 0.5
	if parado and not _em_paragem:
		_em_paragem = true
		_paragem_ini = agora
	elif not parado and _em_paragem:
		_em_paragem = false
		_paragens.append({
			"fase": _fase, "ms": (agora - _paragem_ini) / 1000.0,
		})

	# Buraco = frame de parede longo. Registado com o `time_scale` do momento
	# para separar "parou por hitstop" de "engasgou por outra razão".
	if real_ms > 20.0 and _fase != "aquecimento":
		_buracos.append({
			"fase": _fase, "ms": real_ms, "time_scale": Engine.time_scale,
		})

	if _relogio() < AQUECIMENTO:
		return

	if _koliani == null or not is_instance_valid(_koliani):
		_koliani = get_tree().get_first_node_in_group("koliani")
		if _koliani == null:
			return
		if _sem_hitstop:
			_koliani.set_meta("bench_sem_hitstop", true)
		_vida_ant = int(_koliani.get("vida"))

	# contabiliza dano levado (a vida dela desceu)
	var v := int(_koliani.get("vida"))
	if v < _vida_ant:
		_dano_levado += 1
	# Se ela morrer, o `reload_current_scene` deita fora ESTA bancada e a
	# medição reinicia em ciclo. Aqui interessa o hitstop de levar dano, não
	# a sobrevivência dela -- por isso mantém-se de pé à força.
	if v < 50:
		_koliani.set("vida", 999)
		v = 999
	_vida_ant = v

	# rede de segurança de tempo de parede
	if _relogio() > AQUECIMENTO + DUR_FASE * _fases.size() + 25.0:
		print("BENCH aviso: limite de tempo de parede")
		_terminar()
		return

	# `--sem-hitstop`: cancela a paragem global todos os frames. E' o
	# isolamento da seccao 4 -- se o engasgo desaparecer, o hitstop esta'
	# provado; se ficar, a causa e' outra (VFX/SFX/primeira utilizacao).
	if _sem_hitstop and Engine.time_scale < 0.5:
		Engine.time_scale = 1.0

	_fase_t += real_ms / 1000.0
	if _idx < 0 or _fase_t >= DUR_FASE:
		_idx += 1
		_fase_t = 0.0
		_largar()
		if _idx >= _fases.size():
			_terminar()
			return
		_fase = _fases[_idx]
		_preparar_fase()

	# Cola-a ao alvo TODOS os frames. Sem isto ela recuava com o knockback,
	# caía da plataforma e a cena recarregava em ciclo -- que foi o que o
	# Paulo viu na janela de debug.
	if _ancora != Vector2.ZERO and _koliani is Node2D:
		var k2 := _koliani as Node2D
		if k2.global_position.distance_to(_ancora) > 90.0:
			k2.global_position = _ancora
			k2.set("velocity", Vector2.ZERO)
			k2.reset_physics_interpolation()

	_conduzir()


## "acerto"/"receber" precisam de um inimigo COLADO -- senão mede-se o vazio.
## Encostar a Koliani ao bicho é a única forma fiável de garantir contacto sem
## depender do desenho do nível.
func _preparar_fase() -> void:
	if _fase == "ar":
		return
	var alvo: Node2D = null
	var melhor := INF
	# `--chefe`: vai direito ao chefe. O Paulo: "está na plataforma na mesa,
	# tem que dar spawn no boss" -- o chefe existe na cena desde o início mas
	# fica DORMENTE até ela chegar à arena, por isso o "inimigo mais perto"
	# apanhava um bicho qualquer do caminho em vez dele.
	var grupo := "chefes" if _chefe else "inimigos"
	for e in get_tree().get_nodes_in_group(grupo):
		if not is_instance_valid(e) or not (e as Node2D).is_inside_tree():
			continue
		var d: float = (e as Node2D).global_position.distance_to(
			(_koliani as Node2D).global_position)
		if d < melhor:
			melhor = d
			alvo = e as Node2D
	if alvo:
		# acordar: dormente, o bicho/chefe não reage nem contra-ataca
		if alvo.get("dormente") != null and bool(alvo.get("dormente")):
			alvo.set("dormente", false)
		var afast := -120.0 if _chefe else -38.0
		(_koliani as Node2D).global_position = alvo.global_position + Vector2(afast, -10.0)
		_ancora = (_koliani as Node2D).global_position
		if _koliani.has_method("reset_physics_interpolation"):
			_koliani.reset_physics_interpolation()
	print("BENCH fase=%s  alvo=%s a %.0fpx" % [
		_fase, str(alvo.name) if alvo else "NENHUM", melhor])


func _conduzir() -> void:
	var c := _relogio()
	match _fase:
		"ar", "acerto":
			var bate := fmod(c, 0.40) < 0.10
			_premir("atacar", bate)
			if bate:
				_ataques += 1
		"receber":
			_premir("atacar", false)


func _premir(a: String, on: bool) -> void:
	if not InputMap.has_action(a):
		return
	if on and not Input.is_action_pressed(a):
		Input.action_press(a)
	elif not on and Input.is_action_pressed(a):
		Input.action_release(a)


func _largar() -> void:
	for a in ["atacar", "mover_direita", "mover_esquerda", "saltar"]:
		if InputMap.has_action(a):
			Input.action_release(a)


func _resumo(fase: String) -> Dictionary:
	var ms: Array[float] = []
	for p in _paragens:
		if p["fase"] == fase:
			ms.append(p["ms"])
	var bur := 0
	for b in _buracos:
		if b["fase"] == fase:
			bur += 1
	if ms.is_empty():
		return {"paragens": 0, "buracos_frame": bur}
	ms.sort()
	var soma := 0.0
	for x in ms:
		soma += x
	return {
		"paragens": ms.size(),
		"ms_media": soma / ms.size(),
		"ms_min": ms[0],
		"ms_max": ms[ms.size() - 1],
		"ms_total": soma,
		"buracos_frame": bur,
	}


func _terminar() -> void:
	set_process(false)
	_largar()
	Engine.time_scale = 1.0
	var out := {
		"etiqueta": _etiqueta,
		"nivel": _nivel,
		"sem_hitstop": _sem_hitstop,
		"contra_chefe": _chefe,
		"interpolacao": ProjectSettings.get_setting(
			"physics/common/physics_interpolation", false),
		"ataques_enviados": _ataques,
		"vezes_que_levou_dano": _dano_levado,
		"por_fase": {},
		"paragens_todas": _paragens,
		"buracos": _buracos,
	}
	for f in _fases:
		out["por_fase"][f] = _resumo(f)

	DirAccess.make_dir_recursive_absolute("user://perf")
	var f2 := FileAccess.open("user://perf/%s.json" % _etiqueta, FileAccess.WRITE)
	if f2:
		f2.store_string(JSON.stringify(out, "  "))
		f2.close()
	print("BENCH_JSON_INICIO")
	print(JSON.stringify(out, "  "))
	print("BENCH_JSON_FIM")
	get_tree().quit(0)
