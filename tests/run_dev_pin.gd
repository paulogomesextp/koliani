extends SceneTree
## PIN de entrada Dev: rejeição/cancelamento não alteram a campanha.
var _falhas := 0

func _init() -> void:
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	await process_frame
	var estado := root.get_node("EstadoJogo")
	estado.modo_teste = true
	var antes: Dictionary = estado.para_dicionario().duplicate(true)
	var menu: Control = load("res://scenes/ui/MenuInicial.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var dev: Button = menu.get("_dev")
	_checar(dev.visible, "botão disponível em release QA")
	dev.pressed.emit()
	_checar(not estado.modo_dev, "abrir PIN não ativa Dev")
	var campo: LineEdit = menu.get("_pin_campo")
	_checar(campo.secret and campo.max_length == 4, "PIN oculto de quatro dígitos")
	campo.text = "980"
	campo.text_submitted.emit(campo.text)
	_checar(not estado.modo_dev and menu.get("_pin_erro").visible, "zero inicial obrigatório")
	campo.text = "0000"
	menu.get("_pin_entrar").pressed.emit()
	_checar(not estado.modo_dev and menu.get("_pin_erro").visible, "PIN errado bloqueado")
	if "--capturar-pin" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Temp/koliani_dev_pin.png")
	menu.get("_pin_cancelar").pressed.emit()
	_checar(menu.get("_pin_painel") == null and not dev.disabled, "cancelar repõe menu")
	_checar(estado.para_dicionario() == antes, "cancelar/erro preservam campanha")
	dev.pressed.emit()
	var cancelar := InputEventAction.new()
	cancelar.action = "ui_cancel"
	cancelar.pressed = true
	menu.call("_input", cancelar)
	_checar(menu.get("_pin_painel") == null and not estado.modo_dev, "Esc cancela")
	dev.pressed.emit()
	campo = menu.get("_pin_campo")
	for idioma in ["en", "pt", "es", "fr", "de", "zh"]:
		var catalogo: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/i18n/%s.json" % idioma))
		for chave in ["dev.pin_title", "dev.pin_placeholder", "dev.pin_enter", "dev.pin_cancel", "dev.pin_invalid"]:
			_checar(catalogo.has(chave) and not String(catalogo[chave]).is_empty(), "tradução " + idioma + " " + chave)
	campo.text = "0989"
	menu.get("_pin_entrar").pressed.emit()
	_checar(not estado.modo_dev, "PIN anterior deixou de autorizar")
	campo.text = "0980"
	campo.text_submitted.emit(campo.text)
	_checar(estado.modo_dev, "PIN correto ativa sandbox")
	estado.desativar_modo_dev()
	_checar(estado.para_dicionario() == antes, "sair Dev restaura campanha")
	print("DEV PIN resultado: falhas=%d" % _falhas)
	quit(0 if _falhas == 0 else 1)

func _checar(ok: bool, mensagem: String) -> void:
	if not ok:
		_falhas += 1
		push_error("DEV PIN: " + mensagem)
