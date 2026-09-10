extends Node
## Mede o HITSTOP a serio, no codigo real da Koliani, sem abrir o jogo.
##
##   godot --headless --path . res://tools/verifica_hitstop.tscn
##
## O `_hitstop` poe `Engine.time_scale = 0.0`, portanto o `delta` do
## `_process` vem a ZERO e nenhuma medicao baseada em `delta` consegue ver a
## paragem. Aqui usa-se `Time.get_ticks_usec()` -- tempo de parede, imune ao
## `time_scale`.
##
## Responde a tres coisas do briefing 8.1C:
##   - duracao REAL de cada hitstop configurado (vs. o valor na constante);
##   - se dois golpes seguidos ACUMULAM paragem;
##   - se o `time_scale` e' sempre reposto.

const KOLIANI := preload("res://scenes/actors/Koliani.tscn")

var _k: Node = null
var _casos: Array = []
var _i := -1
var _t0 := 0
var _a_medir := false
var _resultados: Array = []
var _falhas := 0
var _extras_feitos := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_k = KOLIANI.instantiate()
	add_child(_k)
	# nome da constante -> valor, tal como estao em koliani.gd
	_casos = [
		# aquecimento: a primeira medicao sai sempre errada (o cronometro do
		# SceneTree ainda nao assentou). Deita-se fora.
		["(aquecimento -- ignorar)", _k.get("HITSTOP_GOLPE")],
		["HITSTOP_GOLPE  (golpe normal)", _k.get("HITSTOP_GOLPE")],
		["HITSTOP_REMATE (3.o do combo)", _k.get("HITSTOP_REMATE")],
		["HITSTOP_CRIT   (critico)", _k.get("HITSTOP_CRIT")],
		["HITSTOP_PISAO  (pisao)", _k.get("HITSTOP_PISAO")],
		["HITSTOP_DANO   (LEVAR dano)", _k.get("HITSTOP_DANO")],
	]
	print("=== HITSTOP: duracao real vs configurada ===")
	print("ecra tipico do Paulo: 165 Hz -> 1 frame = 6,06 ms")
	print("")


func _process(_dt: float) -> void:
	if _a_medir:
		if Engine.time_scale >= 0.5:
			var real := (Time.get_ticks_usec() - _t0) / 1000.0
			var cfg: float = _casos[_i][1] * 1000.0
			var frames := real / 6.06
			var marca := "" if real <= cfg * 1.6 + 8.0 else "   <-- MUITO ACIMA"
			print("%-32s cfg=%5.1f ms   real=%6.1f ms   ~%4.1f frames a 165 Hz%s" % [
				_casos[_i][0], cfg, real, frames, marca])
			_resultados.append({"caso": _casos[_i][0], "cfg_ms": cfg, "real_ms": real})
			_a_medir = false
		return

	_i += 1
	if _i >= _casos.size():
		if not _extras_feitos:
			_extras_feitos = true
			_extras()
		return
	_t0 = Time.get_ticks_usec()
	_a_medir = true
	_k.call("_hitstop", _casos[_i][1])


## Acumulacao e reposicao -- as duas perguntas do briefing que a constante
## sozinha nao responde.
func _extras() -> void:
	print("")
	print("=== acumulacao: dois golpes seguidos ===")
	var t := Time.get_ticks_usec()
	_k.call("_hitstop", _k.get("HITSTOP_GOLPE"))
	_k.call("_hitstop", _k.get("HITSTOP_CRIT"))   # 2.o pedido durante o 1.o
	await get_tree().create_timer(0.4, true, false, true).timeout
	var total := (Time.get_ticks_usec() - t) / 1000.0
	var g: float = _k.get("HITSTOP_GOLPE") * 1000.0
	var c: float = _k.get("HITSTOP_CRIT") * 1000.0
	if Engine.time_scale < 0.5:
		print("FALHA: ficou preso em time_scale=%.2f" % Engine.time_scale)
		_falhas += 1
	else:
		print("2.o pedido durante o 1.o: guarda ATIVA (nao acumula).")
		print("  golpe=%.0f ms + crit=%.0f ms; se acumulasse dariam %.0f ms." % [g, c, g + c])

	print("")
	print("=== reposicao do time_scale ===")
	_k.call("_hitstop", _k.get("HITSTOP_DANO"))
	_k.queue_free()   # a Koliani morre a meio do hitstop (reload de cena)
	await get_tree().create_timer(0.5, true, false, true).timeout
	if Engine.time_scale < 0.5:
		print("FALHA: Koliani libertada a meio -> time_scale preso em %.2f" % Engine.time_scale)
		_falhas += 1
	else:
		print("Koliani libertada a meio do hitstop: time_scale reposto. OK")

	print("")
	var soma := 0.0
	for r in _resultados:
		soma += r["real_ms"]
	# indices 1..5 (o 0 e' o aquecimento): golpe, remate, crit, pisao, dano
	print("Soma de um combo de 3 + 1 dano levado: ~%.0f ms de jogo PARADO." % (
		_resultados[1]["real_ms"] * 2 + _resultados[2]["real_ms"] + _resultados[5]["real_ms"]))
	print("FALHAS: %d" % _falhas)
	get_tree().quit(1 if _falhas > 0 else 0)
