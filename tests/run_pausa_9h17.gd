extends Node
## 9H.17 F -- a pausa abre com P mas nao com Escape (nota de QA da 9H.16).
## O mapa de input TEM o Escape na accao `pausa`, por isso a causa esta' no
## caminho do evento, nao no mapa. Aqui manda-se a tecla a serio e ve-se.

const PAUSA := preload("res://scenes/ui/Pausa.tscn")

func _ready() -> void:
	provar.call_deferred()

func _tecla(codigo: Key) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = codigo
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	await get_tree().process_frame
	var s := InputEventKey.new()
	s.physical_keycode = codigo
	s.pressed = false
	Input.parse_input_event(s)
	await get_tree().process_frame

func provar() -> void:
	print("accao pausa tem %d eventos" % InputMap.action_get_events("pausa").size())
	for ev in InputMap.action_get_events("pausa"):
		if ev is InputEventKey:
			print("  tecla physical=%d (%s)" % [ev.physical_keycode,
				OS.get_keycode_string(ev.physical_keycode)])
	var p := PAUSA.instantiate()
	add_child(p)
	for _i in 10:
		await get_tree().process_frame
	print("visivel de inicio: %s" % p.visible)
	await _tecla(KEY_P)
	for _i in 4:
		await get_tree().process_frame
	print("depois de P      : %s" % p.visible)
	get_tree().paused = false
	p.visible = false
	# esperar o tempo morto (_cd = 0,35 s)
	await get_tree().create_timer(0.6, true, false, true).timeout
	await _tecla(KEY_ESCAPE)
	for _i in 4:
		await get_tree().process_frame
	print("depois de ESCAPE : %s" % p.visible)
	get_tree().paused = false
	get_tree().quit(0)
