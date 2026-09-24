extends Control
## QA visual dos cosmeticos da Loja em JANELA REAL (renderer verdadeiro).
## Aciona a Loja real com eventos de rato/teclado sinteticos e grava PNGs.
## ESCREVE no save: correr por `tools/correr_qa_cosmeticos.ps1` (APPDATA isolado).

var falhas: Array[String] = []
var _dir := ""


func _check(c: bool, m: String) -> void:
	print(("PASS   " if c else "FALHOU ") + m)
	if not c:
		falhas.append(m)


func _foto(nome: String, rect := Rect2()) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if rect.size != Vector2.ZERO:
		img = img.get_region(Rect2i(rect))
		img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	img.save_png(_dir + nome + ".png")


func _rato(pos: Vector2, clicar := true) -> void:
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	get_viewport().push_input(m)
	await get_tree().process_frame
	if clicar:
		for down in [true, false]:
			var b := InputEventMouseButton.new()
			b.button_index = MOUSE_BUTTON_LEFT
			b.pressed = down
			b.position = pos
			b.global_position = pos
			get_viewport().push_input(b)
			await get_tree().process_frame
	await get_tree().process_frame


func _clicar(c: Control) -> void:
	await _rato(c.get_global_rect().get_center())


func _tecla(ac: String) -> void:
	for down in [true, false]:
		var e := InputEventAction.new()
		e.action = ac
		e.pressed = down
		Input.parse_input_event(e)
		await get_tree().process_frame
	await get_tree().process_frame


func _ready() -> void:
	_dir = OS.get_user_data_dir() + "/qa_cosm/"
	DirAccess.make_dir_recursive_absolute(_dir)
	print("SAIDA: ", _dir)
	await get_tree().create_timer(0.5).timeout
	await _loja()
	await _niveis()
	print("QA COSMETICOS: %s (%d falhas)" % ["PASS" if falhas.is_empty() else "FAIL", falhas.size()])
	get_tree().quit(0 if falhas.is_empty() else 1)


func _loja() -> void:
	_check(EstadoJogo.kolicoins == 2000 and EstadoJogo.veracoins == 300,
		"saldo semeado K=%d V=%d" % [EstadoJogo.kolicoins, EstadoJogo.veracoins])
	var l := Loja.new()
	add_child(l)
	await get_tree().create_timer(0.4).timeout
	await _foto("loja_01_aberta")
	var foco_ok := func() -> bool:
		var f := get_viewport().gui_get_focus_owner()
		return f != null and l.is_ancestor_of(f)
	_check(foco_ok.call(), "foco inicial dentro da Loja")
	for c in ["skins", "efeitos", "hud_checkpoint", "extras", "packs", "destaques", "skins"]:
		await _clicar(l._botoes_cat[c])
		_check(l._cat == c, "rato: categoria " + c)
	await _foto("loja_02_skins")
	await _rato(l._cartoes["skin_carmesim"].get_global_rect().get_center(), false)
	await _clicar(l._cartoes["skin_carmesim"])
	_check(l._sel == "skin_carmesim", "rato: selecionar Carmesim")
	await _foto("loja_03_carmesim_sel")
	var k0: int = EstadoJogo.kolicoins
	await _clicar(l._btn_k)
	_check(EstadoJogo.item_adquirido("skin_carmesim") and EstadoJogo.kolicoins == k0 - 300,
		"rato: comprar Carmesim com K (%d->%d)" % [k0, EstadoJogo.kolicoins])
	_check(EstadoJogo.estado_item_loja("skin_carmesim") == "adquirido", "estado adquirido apos compra")
	await _foto("loja_04_comprado")
	await _clicar(l._btn_eq)
	_check(EstadoJogo.item_equipado("skin_carmesim"), "rato: equipar Carmesim")
	await _foto("loja_05_equipado")
	await _clicar(l._cartoes["skin_luar"])
	_check(not l._btn_k.visible and l._btn_v.visible and not l._btn_v.disabled, "Luar so aceita V (botao K escondido)")
	var v0: int = EstadoJogo.veracoins
	await _clicar(l._btn_v)
	_check(EstadoJogo.item_adquirido("skin_luar") and EstadoJogo.veracoins == v0 - 150,
		"rato: comprar Luar com V (%d->%d)" % [v0, EstadoJogo.veracoins])
	await _clicar(l._btn_eq)
	_check(EstadoJogo.item_equipado("skin_luar") and not EstadoJogo.item_equipado("skin_carmesim"),
		"rato: equipar Luar troca o slot")
	await _clicar(l._botoes_cat["efeitos"])
	await _clicar(l._cartoes["efeito_rasto_brasa"])
	_check(not l._btn_k.disabled and not l._btn_v.disabled, "brasa aceita K e V (escolha de moeda)")
	var k1: int = EstadoJogo.kolicoins
	await _clicar(l._btn_k)
	_check(EstadoJogo.kolicoins == k1 - 500, "rato: brasa paga em K (%d->%d)" % [k1, EstadoJogo.kolicoins])
	await _clicar(l._btn_eq)
	_check(EstadoJogo.item_equipado("efeito_rasto_brasa"), "rato: equipar Brasa")
	await _clicar(l._botoes_cat["hud_checkpoint"])
	await _clicar(l._cartoes["hud_moldura_osso"])
	await _clicar(l._btn_v)
	await _clicar(l._btn_eq)
	_check(EstadoJogo.item_equipado("hud_moldura_osso"), "rato: equipar Osso (pago em V)")
	await _clicar(l._botoes_cat["packs"])
	await _clicar(l._cartoes["pack_regiao_i"])
	var est: String = EstadoJogo.estado_item_loja("pack_regiao_i")
	print("INFO pack regional estado=", est, " regiao0 concluida=", EstadoJogo.regiao_esta_concluida(0))
	_check(est == ("disponivel" if EstadoJogo.regiao_esta_concluida(0) else "bloqueado"),
		"pack regional coerente com progressao (%s)" % est)
	if est == "bloqueado":
		_check(l._btn_k.disabled and l._btn_v.disabled, "pack bloqueado: comprar desativado")
	await _foto("loja_06_pack")
	# --- TECLADO
	await _clicar(l._botoes_cat["skins"])
	l._botoes_cat["skins"].grab_focus()
	await get_tree().process_frame
	var ok_foco := true
	var seq := ["ui_down", "ui_right", "ui_right", "ui_left", "ui_up", "ui_accept", "ui_left",
		"ui_down", "ui_down", "ui_right", "ui_right", "ui_right", "ui_up", "ui_left"]
	for a in seq:
		await _tecla(a)
		ok_foco = ok_foco and foco_ok.call()
	_check(ok_foco, "teclado: foco nunca sai da Loja em %d navegacoes" % seq.size())
	l._cartoes["skin_koliani_base"].grab_focus()
	await get_tree().process_frame
	_check(l._sel == "skin_koliani_base", "teclado: foco no item seleciona-o")
	l._btn_eq.grab_focus()
	await _tecla("ui_accept")
	_check(EstadoJogo.item_equipado("skin_koliani_base"), "teclado: equipar Classic (default) via Enter")
	await _foto("loja_07_teclado")
	var fechou := [false]
	l.fechado.connect(func() -> void: fechou[0] = true)
	await _tecla("ui_cancel")
	await get_tree().create_timer(0.2).timeout
	_check(fechou[0], "teclado: Esc fecha a Loja")


func _niveis() -> void:
	for t in ["dash", "salto_duplo", "projetil"]:
		EstadoJogo.desbloquear_habilidade(t)
	EstadoJogo.desequipar_categoria("efeitos")
	EstadoJogo.desequipar_categoria("hud_checkpoint")
	for s in ["skin_koliani_base", "skin_carmesim", "skin_luar"]:
		EstadoJogo.equipar_item(s)
		await _nivel_foto(s)
	EstadoJogo.equipar_item("skin_koliani_base")
	EstadoJogo.equipar_item("efeito_rasto_brasa")
	EstadoJogo.equipar_item("hud_moldura_osso")
	await _nivel_foto("osso_brasa", true)
	EstadoJogo.desequipar_categoria("hud_checkpoint")
	EstadoJogo.desequipar_categoria("efeitos")
	await _nivel_foto("default_final", false, true)


func _nivel_foto(nome: String, dash := false, so_checkpoint := false) -> void:
	var cena: PackedScene = load("res://scenes/Main.tscn")
	var n := cena.instantiate()
	add_child(n)
	await get_tree().create_timer(1.5).timeout
	var k := get_tree().get_first_node_in_group("koliani")
	_check(k != null, nome + ": Koliani presente")
	if k == null:
		n.queue_free()
		return
	print("INFO ", nome, " modulate corpo=", k._corpo.modulate, " tinta_skin=", CosmeticosVisuais.tinta_skin())
	await _foto("nivel_" + nome)
	var c: Vector2 = k.get_global_transform_with_canvas().origin
	await _foto("nivel_" + nome + "_zoom", Rect2(c - Vector2(60, 90), Vector2(120, 120)))
	if nome == "osso_brasa":
		# mesma instancia, mesmo ponto: rasto de brasa ligado/desligado alternados
		var p0: Vector2 = k.global_position
		var res := {}
		for ligado in [true, false, true, false]:
			if ligado:
				EstadoJogo.equipar_item("efeito_rasto_brasa")
			else:
				EstadoJogo.desequipar_categoria("efeitos")
			k.global_position = p0
			k.velocity = Vector2.ZERO
			await get_tree().create_timer(0.8).timeout
			var x0: float = k.global_position.x
			Input.action_press("dash")
			await get_tree().create_timer(0.08).timeout
			Input.action_release("dash")
			await get_tree().create_timer(0.5).timeout
			var d: float = snappedf(k.global_position.x - x0, 0.01)
			print("INFO dash brasa=", ligado, " deslocamento=", d)
			res[ligado] = d if not res.has(ligado) or res[ligado] == d else -1.0
		_check(res[true] == res[false] and res[true] > 0.0, "dash: distancia igual com/sem rasto de brasa (%s)" % str(res))
		EstadoJogo.equipar_item("efeito_rasto_brasa")
	if so_checkpoint:
		await _checkpoint_foto(nome)
	if dash:
		var pico := 0
		Input.action_press("mover_direita")
		for r in 6:
			Input.action_press("dash")
			await get_tree().create_timer(0.08).timeout
			Input.action_release("dash")
			for f in 12:
				await get_tree().process_frame
				pico = maxi(pico, k.get_parent().find_children("RastoDash", "Sprite2D", false, false).size())
				if r == 0 and f == 4:
					await _foto("nivel_" + nome + "_dash")
			await get_tree().create_timer(0.6).timeout
		Input.action_release("mover_direita")
		print("INFO dash: pico de rastos=", pico)
		_check(pico > 0, "dash cria rastos")
		await get_tree().create_timer(0.6).timeout
		var restam: int = k.get_parent().find_children("RastoDash", "Sprite2D", false, false).size()
		_check(restam == 0, "nenhum rasto preso apos dashes (restam %d)" % restam)
		var cps := get_tree().get_nodes_in_group("checkpoints")
		if not cps.is_empty():
			k.global_position = cps[0].global_position
			await get_tree().create_timer(1.5).timeout
			var cp: Node2D = cps[0]
			var cor0: Color = cp._chama.color_ramp.colors[1]
			print("INFO checkpoints=", cps.size(), " pos=", cp.global_position, " ativo=", cp._ativo, " chama_emitting=", cp._chama.emitting, " rampa[1]=", cor0)
			_check(cp._ativo and cp._chama.emitting, "checkpoint ativa e chama acesa com moldura equipada")
			await _foto("nivel_" + nome + "_checkpoint")
			var cc: Vector2 = cp.get_global_transform_with_canvas().origin
			await _foto("nivel_" + nome + "_checkpoint_zoom", Rect2(cc - Vector2(70, 110), Vector2(140, 140)))
	n.queue_free()
	await get_tree().create_timer(0.5).timeout


func _checkpoint_foto(nome: String) -> void:
	var k := get_tree().get_first_node_in_group("koliani")
	var cps := get_tree().get_nodes_in_group("checkpoints")
	if cps.is_empty():
		return
	k.global_position = cps[0].global_position
	await get_tree().create_timer(1.5).timeout
	var cp: Node2D = cps[0]
	print("INFO checkpoint default rampa[1]=", cp._chama.color_ramp.colors[1])
	var cc: Vector2 = cp.get_global_transform_with_canvas().origin
	await _foto("nivel_" + nome + "_checkpoint_zoom", Rect2(cc - Vector2(70, 110), Vector2(140, 140)))
