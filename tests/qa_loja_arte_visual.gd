extends Control
## QA visual das MOLDURAS e RASTOS com arte da Loja (Ossário, Gaiola de
## Aurora, Brasa, Esporos, Mariposas Lunares) em janela real: HUD, fogueira
## apagada/acesa, a Koliani a meio do dash, e o detalhe na Loja.
## PNGs em <user>/qa_loja_arte/. ESCREVE no save: correr isolado
## (`tools/correr_qa_cosmeticos.ps1` ou `tools/godot_isolado.py --sandbox`).

const MOLDURAS := ["hud_moldura_osso", "hud_moldura_gaiola"]
const RASTOS := ["efeito_rasto_brasa", "efeito_rasto_esporos", "efeito_rasto_mariposas"]

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
	EstadoJogo.abandonar_sessao_nivel()
	var n: Node = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	add_child(n)
	await get_tree().create_timer(1.5).timeout
	return n


func _garantir(id: String) -> void:
	if not EstadoJogo.item_adquirido(id):
		_check(EstadoJogo.comprar_item(id, "k")["ok"], "compra de %s por K" % id)
	_check(EstadoJogo.equipar_item(id), "equipar %s" % id)


func _fogueira(nome: String) -> void:
	var k := get_tree().get_first_node_in_group("koliani")
	var cp: Node2D = get_tree().get_nodes_in_group("checkpoints")[0]
	k.global_position = cp.global_position + Vector2(-230.0, -10.0)
	k.velocity = Vector2.ZERO
	await get_tree().create_timer(1.2).timeout
	var cc: Vector2 = cp.get_global_transform_with_canvas().origin
	await _foto(nome + "_apagado", Rect2(cc - Vector2(90, 110), Vector2(180, 190)), 3)
	k.global_position = cp.global_position
	await get_tree().create_timer(1.6).timeout
	k.global_position = cp.global_position + Vector2(-230.0, -10.0)
	await get_tree().create_timer(0.8).timeout
	cc = cp.get_global_transform_with_canvas().origin
	await _foto(nome + "_aceso", Rect2(cc - Vector2(90, 110), Vector2(180, 190)), 3)
	_check(cp._rb_brilho != null and not cp._rb_brilho.visible, "fogueira %s: brilho de 'apagada' some ao acender" % nome)


func _dash(nome: String) -> int:
	var k: Node2D = get_tree().get_first_node_in_group("koliani")
	var cp: Node2D = get_tree().get_nodes_in_group("checkpoints")[0]
	k.global_position = cp.global_position + Vector2(-260.0, -10.0)
	k.velocity = Vector2.ZERO
	await get_tree().create_timer(0.9).timeout
	# câmara lenta: sob Xvfb o render é lento e o dash (0,16 s) acabava
	# entre dois frames desenhados
	Engine.time_scale = 0.1
	Input.action_press("dash")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("dash")
	await get_tree().create_timer(0.09).timeout
	var cc: Vector2 = k.get_global_transform_with_canvas().origin
	await _foto(nome + "_dash", Rect2(cc - Vector2(250, 110), Vector2(320, 160)), 3)
	var q := _contar(get_tree().root, "/rastos/")
	await get_tree().create_timer(0.25).timeout
	Engine.time_scale = 1.0
	cc = k.get_global_transform_with_canvas().origin
	await _foto(nome + "_dash_depois", Rect2(cc - Vector2(250, 110), Vector2(320, 160)), 3)
	return q


## Sprites vivos do rasto: `/rastos/` = partículas (pela textura), `#eco` =
## ecos com o shader de silhueta. (Nomes não servem: o Godot renomeia os
## irmãos repetidos para "@Sprite2D@N".)
func _contar(no: Node, o_que: String) -> int:
	var n := 0
	if no is Sprite2D:
		var s := no as Sprite2D
		if o_que == "#eco":
			n = 1 if s.material is ShaderMaterial and s.texture and not s.texture.resource_path.contains("/rastos/") else 0
		elif s.texture and s.texture.resource_path.contains(o_que):
			n = 1
	for f in no.get_children():
		n += _contar(f, o_que)
	return n


func _ready() -> void:
	_dir = OS.get_user_data_dir() + "/qa_loja_arte/"
	DirAccess.make_dir_recursive_absolute(_dir)
	await get_tree().create_timer(0.4).timeout
	for i in 5:
		EstadoJogo.marcar_nivel_concluido(i)
	EstadoJogo.ganhar_kolicoins(20000, false)
	EstadoJogo.desbloquear_habilidade("dash")
	# --- molduras
	for id: String in MOLDURAS:
		_garantir(id)
		var n := await _nivel()
		await _foto(id + "_hud_cheio")
		await _foto(id + "_hud_canto_baixo", Rect2(0, 560, 420, 160), 2)
		await _foto(id + "_hud_canto_cima", Rect2(0, 0, 420, 110), 2)
		var hud := get_tree().get_first_node_in_group("hud_9f")
		var sb := (hud._arma_disco as Panel).get_theme_stylebox("panel") as StyleBoxTexture
		_check(sb != null and str(sb.texture.resource_path).contains(
			"ossario" if id == "hud_moldura_osso" else "gaiola_aurora"), "HUD %s: disco com a nine-patch da moldura" % id)
		_check((hud._arma_disco as Panel).size == Vector2(64, 64), "HUD %s: disco mantem 64x64" % id)
		await _fogueira(id)
		n.queue_free()
		await get_tree().create_timer(0.5).timeout
	EstadoJogo.desequipar_categoria("hud_checkpoint")
	# --- rastos
	var sem := 0
	EstadoJogo.desequipar_categoria("efeitos")
	var n0 := await _nivel()
	sem = await _dash("A_default")
	n0.queue_free()
	await get_tree().create_timer(0.5).timeout
	_check(sem == 0, "dash sem rasto equipado: nenhuma particula cosmetica")
	for id: String in RASTOS:
		_garantir(id)
		var n := await _nivel()
		var q := await _dash(id)
		print("INFO %s: %d particulas vivas a meio do dash" % [id, q])
		_check(q > 0, "dash %s: emite particulas pixel-art" % id)
		n.queue_free()
		await get_tree().create_timer(0.5).timeout
	EstadoJogo.desequipar_categoria("efeitos")
	# --- Loja: detalhe com preview real
	var l := Loja.new()
	add_child(l)
	await get_tree().create_timer(0.3).timeout
	for par in [["hud_checkpoint", "hud_moldura_gaiola"], ["hud_checkpoint", "hud_moldura_osso"],
			["efeitos", "efeito_rasto_mariposas"], ["efeitos", "efeito_rasto_brasa"],
			["efeitos", "efeito_rasto_esporos"], ["packs", "pack_luar_aurora"]]:
		l._escolher_categoria(par[0])
		l._selecionar(par[1])
		await get_tree().create_timer(0.3).timeout
		await _foto("loja_" + par[1])
		_check(l._det_img.visible and l._det_ph.text == "", "Loja: preview real em %s" % par[1])
	l.queue_free()
	print("QA LOJA ARTE: %s (%d falhas)" % ["PASS" if falhas == 0 else "FAIL", falhas])
	get_tree().quit(0 if falhas == 0 else 1)
