extends Node
## 9H.17 F -- a pausa num nivel A SERIO (Main + nivel + HUD + Pausa), que e'
## onde o Game Master disse que o Escape nao abre. Em isolamento a Pausa
## responde as duas teclas; se aqui nao responder, o culpado esta' na cena.

func _ready() -> void:
	provar.call_deferred()

func _tecla(codigo: Key) -> void:
	for premida in [true, false]:
		var e := InputEventKey.new()
		e.physical_keycode = codigo
		e.pressed = premida
		Input.parse_input_event(e)
		for _i in 3:
			await get_tree().process_frame

func provar() -> void:
	EstadoJogo.indice_nivel = 0
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	for _i in 90:
		await get_tree().process_frame
	var pausa: Node = null
	for f in main.get_children():
		if f.get_script() != null and String(f.get_script().resource_path).ends_with("pausa.gd"):
			pausa = f
	if pausa == null:
		print("SEM PAUSA na cena")
		get_tree().quit(2)
		return
	print("pausa na cena: visivel=%s  arvore_pausada=%s" % [pausa.visible, get_tree().paused])
	await _tecla(KEY_ESCAPE)
	print("ESCAPE -> visivel=%s  pausada=%s" % [pausa.visible, get_tree().paused])
	var esc_ok: bool = pausa.visible
	pausa.visible = false
	get_tree().paused = false
	pausa.set("_cd", 0.0)
	await get_tree().create_timer(0.6, true, false, true).timeout
	await _tecla(KEY_P)
	print("P      -> visivel=%s" % pausa.visible)
	print("RESULTADO: escape=%s" % ("ABRE" if esc_ok else "NAO ABRE"))
	get_tree().paused = false
	get_tree().quit(0 if esc_ok else 1)
