extends Control
## QA visual A/B da Rootbound Frame em janela real: HUD e checkpoint (apagado /
## aceso) com e sem o cosmetico, e o preview na Loja.
## PNGs em <user>/qa_rootbound/. ESCREVE no save: correr por
## `tools/correr_qa_cosmeticos.ps1` (APPDATA isolado, saldo ja' semeado).

var falhas := 0
var _dir := ""


func _check(c: bool, m: String) -> void:
	print(("PASS   " if c else "FALHOU ") + m)
	if not c:
		falhas += 1


func _foto(nome: String, rect := Rect2(), fator := 1) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if rect.size != Vector2.ZERO:
		img = img.get_region(Rect2i(rect).intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	if fator > 1:
		img.resize(img.get_width() * fator, img.get_height() * fator, Image.INTERPOLATE_NEAREST)
	img.save_png(_dir + nome + ".png")


func _nivel() -> Node:
	EstadoJogo.abandonar_sessao_nivel()   # fogueiras apagadas: as fases anteriores podem ter acendido alguma
	var n: Node = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	add_child(n)
	await get_tree().create_timer(1.5).timeout
	return n


## Pixels claros (luma > 0.45) na janela da chama: mede o brilho/forma da chama
## sem depender da cor (o cenario e' escuro, por isso a chama destaca-se).
func _claros(img: Image, r: Rect2i) -> int:
	r = r.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var n := 0
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if img.get_pixel(x, y).get_luminance() > 0.45:
				n += 1
	return n


func _fogueira(nome: String) -> void:
	# a fogueira 1: Koliani ao lado (nao em cima) para se ver apagada; depois acende
	var k := get_tree().get_first_node_in_group("koliani")
	var cps := get_tree().get_nodes_in_group("checkpoints")
	var cp: Node2D = cps[0]
	k.global_position = cp.global_position + Vector2(-230.0, -10.0)
	k.velocity = Vector2.ZERO
	await get_tree().create_timer(1.2).timeout
	var cc: Vector2 = cp.get_global_transform_with_canvas().origin
	var reg := Rect2(cc - Vector2(90, 110), Vector2(180, 190))
	await _foto(nome + "_apagado", reg, 3)
	var janela := Rect2(cc - Vector2(30, 70), Vector2(60, 76))
	var l_off := _claros(get_viewport().get_texture().get_image(), Rect2i(janela))
	k.global_position = cp.global_position
	await get_tree().create_timer(1.6).timeout
	k.global_position = cp.global_position + Vector2(-230.0, -10.0)
	await get_tree().create_timer(0.8).timeout
	cc = cp.get_global_transform_with_canvas().origin
	reg = Rect2(cc - Vector2(90, 110), Vector2(180, 190))
	await _foto(nome + "_aceso", reg, 3)
	janela = Rect2(cc - Vector2(30, 70), Vector2(60, 76))
	var l_on := _claros(get_viewport().get_texture().get_image(), Rect2i(janela))
	print("INFO pixels claros na chama %s: apagado=%d aceso=%d" % [nome, l_off, l_on])
	_check(l_on >= l_off + 60, "fogueira %s: aceso tem muito mais pixels claros que apagado (valor, sem depender da cor)" % nome)


func _hud(nome: String) -> void:
	await _foto(nome + "_hud_cheio")
	await _foto(nome + "_hud_canto_baixo", Rect2(0, 560, 420, 160), 2)
	await _foto(nome + "_hud_canto_cima", Rect2(0, 0, 420, 110), 2)


func _ready() -> void:
	_dir = OS.get_user_data_dir() + "/qa_rootbound/"
	DirAccess.make_dir_recursive_absolute(_dir)
	await get_tree().create_timer(0.4).timeout
	# a conta de teste ja' tem a Regiao I? (semeada sem progresso) -- dar posse
	for i in 5:
		EstadoJogo.marcar_nivel_concluido(i)
	EstadoJogo.ganhar_kolicoins(2000, false)
	EstadoJogo.desequipar_categoria("hud_checkpoint")
	# --- A: default
	var n := await _nivel()
	await _hud("A_default")
	await _fogueira("A_default")
	n.queue_free()
	await get_tree().create_timer(0.5).timeout
	# --- B: Rootbound
	if not EstadoJogo.item_adquirido("hud_moldura_raizes"):   # fases anteriores podem ja' ter dado o pack
		_check(EstadoJogo.comprar_item("hud_moldura_raizes", "k")["ok"], "compra da Rootbound Frame por K")
	_check(EstadoJogo.equipar_item("hud_moldura_raizes"), "equipar Rootbound Frame")
	n = await _nivel()
	await _hud("B_rootbound")
	var koliani := get_tree().get_first_node_in_group("koliani")
	var hud := get_tree().get_first_node_in_group("hud_9f")
	var disco: Panel = hud._arma_disco
	var sb := disco.get_theme_stylebox("panel") as StyleBoxTexture
	_check(sb != null and str(sb.texture.resource_path).contains("rootbound_frame"), "HUD: disco da arma usa a nine-patch Rootbound")
	_check(disco.size == Vector2(64, 64), "HUD: disco mantem 64x64 (layout intacto)")
	var img := get_viewport().get_texture().get_image()
	_check(koliani != null, "Koliani presente")
	await _fogueira("B_rootbound")
	var cp: Node = get_tree().get_nodes_in_group("checkpoints")[0]
	_check(cp._rb_brilho != null and not cp._rb_brilho.visible, "fogueira Rootbound: brilho fungico apagado quando acesa")
	_check(cp._chama.amount == 34 and cp._nucleo_k.x > 1.0, "fogueira Rootbound: chama maior quando acesa (forma, nao so' cor)")
	n.queue_free()
	await get_tree().create_timer(0.5).timeout
	# --- Loja: cartao + preview
	var l := Loja.new()
	add_child(l)
	await get_tree().create_timer(0.3).timeout
	l._escolher_categoria("hud_checkpoint")
	l._selecionar("hud_moldura_raizes")
	await get_tree().create_timer(0.3).timeout
	await _foto("C_loja_rootbound_detalhe")
	_check(l._det_img.visible and l._det_ph.text == "", "Loja: preview real e sem 'ART PENDING' no Rootbound Frame")
	l._selecionar("hud_moldura_osso")
	await get_tree().create_timer(0.2).timeout
	_check(not l._det_img.visible and l._det_ph.text != "", "Loja: outro item continua com placeholder")
	l._escolher_categoria("skins")
	l._selecionar("skin_coracao_podre")
	await get_tree().create_timer(0.2).timeout
	_check(not l._det_img.visible and l._det_ph.text.contains("PENDING"), "Loja: Rotwood Mantle continua ART PENDING (%s)" % l._det_ph.text)
	l._escolher_categoria("efeitos")
	l._selecionar("efeito_rasto_esporos")
	await get_tree().create_timer(0.2).timeout
	_check(not l._det_img.visible and l._det_ph.text.contains("PENDING"), "Loja: Spore Wake continua ART PENDING")
	l.queue_free()
	# --- restaurar default
	EstadoJogo.desequipar_categoria("hud_checkpoint")
	_check(not CosmeticosVisuais.raizes_equipado(), "desequipar restaura o default")
	print("QA ROOTBOUND: %s (%d falhas)" % ["PASS" if falhas == 0 else "FAIL", falhas])
	get_tree().quit(0 if falhas == 0 else 1)
