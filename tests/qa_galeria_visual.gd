extends Control
## QA visual da GALERIA DE CONCEITOS em janela real: a Loja com o item
## comprado (botão VER), a Galeria aberta a partir dela, uma página de região,
## uma página fechada, o zoom, e o fecho com Esc de volta à Loja.
## PNGs em <user>/qa_galeria/. ESCREVE no save: correr isolado
## (`tools/correr_qa_cosmeticos.ps1` ou `tools/godot_isolado.py --sandbox`).

var falhas := 0
var _dir := ""


func _check(c: bool, m: String) -> void:
	print(("PASS   " if c else "FALHOU ") + m)
	if not c:
		falhas += 1


func _foto(nome: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_dir + nome + ".png")


func _tecla(acao: String) -> void:
	var ev := InputEventAction.new()
	ev.action = acao
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)
	await get_tree().create_timer(0.3).timeout


func _ready() -> void:
	_dir = OS.get_user_data_dir() + "/qa_galeria/"
	DirAccess.make_dir_recursive_absolute(_dir)
	await get_tree().create_timer(0.4).timeout
	for i in 5:   # Região I concluída: abre a Região II, a III fica fechada
		EstadoJogo.marcar_nivel_concluido(i)
	EstadoJogo.ganhar_kolicoins(20000, false)
	if not EstadoJogo.item_adquirido(Galeria.ITEM):
		_check(EstadoJogo.comprar_item(Galeria.ITEM, "k")["ok"], "compra da Galeria por K")
	var l := Loja.new()
	add_child(l)
	await get_tree().create_timer(0.3).timeout
	l._escolher_categoria("extras")
	l._selecionar(Galeria.ITEM)
	await get_tree().create_timer(0.3).timeout
	await _foto("loja_galeria")
	_check(l._det_img.visible, "Loja: preview real da Galeria")
	_check(l._btn_eq.visible and not l._btn_eq.disabled and l._btn_eq.text == Textos.t("shop.view"),
		"Loja: botao VER no item comprado")
	l._btn_eq.pressed.emit()
	await get_tree().create_timer(0.5).timeout
	var g: Galeria = null
	for f in l.get_children():
		if f is Galeria:
			g = f
	_check(g != null, "VER abre a Galeria por cima da Loja")
	if g == null:
		get_tree().quit(1)
		return
	await _foto("galeria_00_key_art")
	await _tecla("ui_right")
	_check(g.pagina == 1, "seta direita muda de pagina")
	await _foto("galeria_01_koliani")
	await _tecla("ui_right")
	await _foto("galeria_02_regiao_ii")
	_check(g.get_node("Vista/Imagem").visible, "Regiao II aberta depois da I")
	g.ampliar(Galeria.ZOOM_TOQUE, g.get_node("Vista").size * 0.5)
	await _foto("galeria_02_zoom")
	var im: Control = g.get_node("Vista/Imagem")
	_check(im.size.x > g.get_node("Vista").size.x, "zoom amplia a imagem")
	g.ir(4)
	await _foto("galeria_04_chefe_ii")
	g.ir(5)
	await _foto("galeria_05_fechada")
	_check(not im.visible and g.get_node("Vista/Cadeado").text != "", "Regiao III fechada mostra o cadeado")
	await _tecla("ui_cancel")
	_check(not is_instance_valid(g) or g.is_queued_for_deletion(), "Esc fecha a Galeria")
	_check(is_instance_valid(l) and not l.is_queued_for_deletion(), "Esc na Galeria nao fecha a Loja")
	var f := get_viewport().gui_get_focus_owner()
	_check(f != null and l.is_ancestor_of(f), "foco volta para a Loja")
	await _foto("loja_depois")
	print("QA GALERIA: %s (%d falhas)" % ["PASS" if falhas == 0 else "FAIL", falhas])
	get_tree().quit(0 if falhas == 0 else 1)
