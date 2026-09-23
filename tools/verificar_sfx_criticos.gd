extends SceneTree
## Prova dirigida dos quatro roteamentos corrigidos no SFX Overhaul.
## Conta as vozes reais do autoload `Som` e confirma o stream atribuido.

var _falhas := 0
var _som: Node


func _init() -> void:
	await process_frame
	_som = root.get_node_or_null("Som")
	_verificar(_som != null, "autoload Som ausente")
	if _som == null:
		quit(1)
		return
	_verificar_catalogo()
	await _provar_portal()
	await _provar_checkpoint()
	await _provar_ui()
	await _provar_morte_inimigo()
	await _provar_derrota_chefe()
	await _provar_morte_koliani()
	print("SFX CRITICOS FINAL falhas=%d" % _falhas)
	quit(0 if _falhas == 0 else 1)


func _verificar_catalogo() -> void:
	var ausentes: Array[String] = []
	for chave in _som.CAMINHOS:
		if _som.call("_stream", chave) == null:
			ausentes.append(str(chave))
	_verificar(ausentes.is_empty(), "streams ausentes: %s" % str(ausentes))
	print("SFX CATALOGO chaves=%d ausentes=%d" % [_som.CAMINHOS.size(), ausentes.size()])


func _provar_portal() -> void:
	var cena := Node2D.new()
	root.add_child(cena)
	current_scene = cena
	var entrada = load("res://scenes/actors/Portal.tscn").instantiate()
	var saida = load("res://scenes/actors/Portal.tscn").instantiate()
	saida.id = "portal_b"
	saida.so_saida = true
	saida.global_position = Vector2(300, 0)
	cena.add_child(entrada)
	cena.add_child(saida)
	var k = load("res://scenes/actors/Koliani.tscn").instantiate()
	k.global_position = Vector2(-200, 0)
	cena.add_child(k)
	await process_frame
	var antes := _contador()
	entrada.call("_ao_entrar", k)
	_verificar(_avanco(antes) == 1, "portal nao disparou exactamente uma voz")
	_verificar(_ultimo_stream() == "portal_jump.mp3", "portal nao usa o asset aprovado")
	print("SFX PORTAL vozes=1 stream=%s" % _ultimo_stream())
	cena.queue_free()
	current_scene = null
	await process_frame


func _provar_checkpoint() -> void:
	root.get_node("EstadoJogo").call("reiniciar_campanha")
	var cena := Node2D.new()
	root.add_child(cena)
	current_scene = cena
	var k = load("res://scenes/actors/Koliani.tscn").instantiate()
	k.global_position = Vector2(-200, 0)
	cena.add_child(k)
	var checkpoint = load("res://scripts/checkpoint.gd").new()
	checkpoint.checkpoint_id = "checkpoint_level_001_01"
	cena.add_child(checkpoint)
	await process_frame
	var antes := _contador()
	checkpoint.call("_ao_entrar", k)
	_verificar(_avanco(antes) == 1, "checkpoint nao disparou exactamente uma voz")
	_verificar(_ultimo_stream() == "checkpoint_sword_cut.mp3", "checkpoint usa stream errado")
	print("SFX CHECKPOINT vozes=1 stream=%s" % _ultimo_stream())
	cena.queue_free()
	current_scene = null
	await process_frame


func _provar_ui() -> void:
	var cena := Node.new()
	root.add_child(cena)
	current_scene = cena
	var menu = load("res://scenes/ui/MenuInicial.tscn").instantiate()
	cena.add_child(menu)
	await process_frame
	var opcoes: Button = menu.get("_botoes").get("opcoes")
	var antes := _contador()
	opcoes.focus_entered.emit()
	_verificar(_avanco(antes) == 1 and _ultimo_stream() == "ui_hover.mp3",
		"movimento de UI nao disparou uma voz ui_mover")
	antes = _contador()
	opcoes.pressed.emit()
	_verificar(_avanco(antes) == 1 and _ultimo_stream() == "ui_confirm.mp3",
		"confirmacao de UI nao disparou uma voz ui_confirmar")
	print("SFX UI mover=1 confirmar=1")
	cena.queue_free()
	current_scene = null
	await process_frame


func _provar_morte_koliani() -> void:
	var cena := Node2D.new()
	root.add_child(cena)
	current_scene = cena
	var k = load("res://scenes/actors/Koliani.tscn").instantiate()
	cena.add_child(k)
	await process_frame
	k.vida = 1
	k._invulneravel = 0.0
	var antes := _contador()
	k.call("receber_dano", 1)
	_verificar(_avanco(antes) == 1, "morte da Koliani empilhou dano+morte")
	_verificar(_ultimo_stream() == "koliani_death.wav", "morte da Koliani usa stream errado")
	print("SFX MORTE KOLIANI vozes=1 stream=%s" % _ultimo_stream())
	cena.queue_free()
	current_scene = null
	await process_frame


func _provar_morte_inimigo() -> void:
	var cena := Node2D.new()
	root.add_child(cena)
	current_scene = cena
	var inimigo = load("res://scenes/actors/DemonioBase.tscn").instantiate()
	cena.add_child(inimigo)
	await process_frame
	inimigo.vida = 1
	var antes := _contador()
	inimigo.call("receber_dano", 1)
	_verificar(_avanco(antes) == 1, "morte do inimigo empilhou dano+morte")
	_verificar(_ultimo_stream().ends_with("_morte.ogg"), "morte do inimigo usa stream errado")
	print("SFX MORTE INIMIGO vozes=1 stream=%s" % _ultimo_stream())
	cena.queue_free()
	current_scene = null
	await process_frame


func _provar_derrota_chefe() -> void:
	var cena := Node2D.new()
	root.add_child(cena)
	current_scene = cena
	var chefe = load("res://scenes/actors/ChefeGhorak.tscn").instantiate()
	cena.add_child(chefe)
	await process_frame
	var antes := _contador()
	chefe.call("_tocar_som_derrota")
	_verificar(_avanco(antes) == 1, "chefe_cai e conquista ainda arrancam juntos")
	_verificar(_ultimo_stream() == "chefe_cai.wav", "queda do chefe usa stream errado")
	await create_timer(0.5).timeout
	_verificar(_avanco(antes) == 2, "conquista nao disparou uma vez depois da queda")
	_verificar(_ultimo_stream() == "conquista.wav", "recompensa do chefe usa stream errado")
	print("SFX CHEFE vozes=2 sequencia=chefe_cai.wav>conquista.wav atraso=0.45s")
	cena.queue_free()
	current_scene = null
	await process_frame


func _avanco(antes: int) -> int:
	return _contador() - antes


func _contador() -> int:
	return int(_som.get("_ordem"))


func _ultimo_stream() -> String:
	var i := posmod(int(_som.get("_idx")) - 1, int(_som.VOZES))
	var pool: Array = _som.get("_pool")
	var p := pool[i] as AudioStreamPlayer
	return p.stream.resource_path.get_file() if p and p.stream else ""


func _verificar(ok: bool, mensagem: String) -> void:
	if not ok:
		_falhas += 1
		push_error("SFX CRITICOS: " + mensagem)
