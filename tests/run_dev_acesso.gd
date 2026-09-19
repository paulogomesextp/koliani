extends SceneTree
## Acesso ao DEV MODE -- SEM PIN (19 set 2026).
##
## Este harness era o `run_dev_pin.gd`, que provava o contrário: que o botão
## abria um campo de quatro dígitos e que só o código certo autorizava. O
## Paulo mandou tirar o PIN, por isso o que aqui se guarda agora é o oposto
## -- carregar no botão entra em DEV MODE de imediato, sem painel, sem campo
## e sem validação -- mais o que NÃO pode ter mudado: a porta continua a ser
## o interruptor de build `koliani/qa/entrada_dev`, e a campanha legítima
## volta intacta ao sair do sandbox.
##
##   godot --headless --script res://tests/run_dev_acesso.gd
var _falhas := 0

func _init() -> void:
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	await process_frame
	var estado := root.get_node("EstadoJogo")
	estado.modo_teste = true
	var antes: Dictionary = estado.para_dicionario().duplicate(true)

	# 1. o botão só existe se a build o declarar. É ESTA a porta do Dev.
	_checar(estado.entrada_dev_disponivel(),
		"`koliani/qa/entrada_dev` devia estar ligado nesta build de QA")

	var menu: Control = load("res://scenes/ui/MenuInicial.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var dev: Button = menu.get("_dev")
	_checar(dev != null and dev.visible, "botão DEV MODE disponível em release QA")
	_checar(not estado.modo_dev, "o menu não entra em Dev sozinho")

	# 2. carregar no botão ACTIVA. Tudo o que interessa é síncrono: quando o
	#    `pressed` volta, o modo dev já está ligado.
	dev.pressed.emit()
	_checar(estado.modo_dev, "carregar no DEV MODE devia activar já, sem PIN")

	# 3. não nasceu painel nenhum, nem campo de texto nenhum.
	_checar(menu.find_child("AcessoDev", true, false) == null,
		"não pode existir painel de acesso (`AcessoDev`)")
	_checar(menu.find_child("PIN", true, false) == null,
		"não pode existir campo de PIN")
	_checar(_sem_line_edit(menu), "o menu não pode ter nenhum campo de texto")
	for membro in ["_pin_painel", "_pin_campo", "_pin_erro", "_pin_titulo",
			"_pin_entrar", "_pin_cancelar"]:
		_checar(menu.get(membro) == null, "membro órfão do PIN: " + membro)

	# 4. `_ao_dev_mode` acaba em `Transicao.fechar_e`, que ~0.22 s depois
	#    trocava a cena e levava este harness com ela. Corta-se aqui.
	var t: Tween = root.get_node("Transicao").get("_tween")
	if t and t.is_valid():
		t.kill()

	# 5. e o modo dev continua a ser um sandbox: sair repõe a campanha.
	estado.desativar_modo_dev()
	_checar(estado.para_dicionario() == antes,
		"sair do Dev devia restaurar a campanha byte a byte")

	# 6. nenhuma tradução órfã ficou para trás nos seis catálogos.
	for idioma in ["en", "pt", "es", "fr", "de", "zh"]:
		var catalogo: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://assets/i18n/%s.json" % idioma))
		for chave in catalogo:
			_checar(not String(chave).begins_with("dev.pin_"),
				"%s.json ainda tem a chave morta '%s'" % [idioma, chave])

	print("DEV ACESSO resultado: falhas=%d" % _falhas)
	quit(0 if _falhas == 0 else 1)


func _sem_line_edit(no: Node) -> bool:
	if no is LineEdit:
		return false
	for f in no.get_children():
		if not _sem_line_edit(f):
			return false
	return true


func _checar(ok: bool, mensagem: String) -> void:
	if not ok:
		_falhas += 1
		push_error("DEV ACESSO: " + mensagem)
