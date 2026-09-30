extends SceneTree
## QA IN-GAME da skin (precisa de janela/Xvfb, renderer real):
##   xvfb-run -a python tools/godot_isolado.py -- --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tools/qa_shadowblade_ingame.gd -- <skin_id> <pasta_saida> [cenarios,csv] [sentido] [cena]
## Equipa a skin, carrega a sala de treino e conduz a Koliani com input real
## (correr, saltar, atacar, dash, rolar...) nos DOIS sentidos, gravando tiras de
## recortes x3 centrados nela. Nao altera nada do jogo.
const CROP := 132
const ESC := 3
var _k: Node2D
var _saida := ""
var _n_vfx_max := 0


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var skin: String = a[0] if a.size() > 0 else "skin_shadowblade"
	_saida = a[1] if a.size() > 1 else "/tmp/qa_skin"
	var so: PackedStringArray = (a[2] if a.size() > 2 else "idle,run,jump,djump,attack,dash,roll,land,pogo").split(",")
	var sentidos: Array = [1, -1] if a.size() <= 3 else [int(a[3])]
	var cena: String = a[4] if a.size() > 4 else "res://scenes/levels/Floresta_Putrefata.tscn"
	DirAccess.make_dir_recursive_absolute(_saida)
	await process_frame
	var ej := root.get_node("/root/EstadoJogo")
	if skin != "":
		ej.itens_comprados.append(skin)
		ej.cosmeticos_equipados["skins"] = skin
	for h in ["dash", "salto_duplo", "rolar"]:
		if not h in ej.habilidades:
			ej.habilidades.append(h)
	ej.checkpoint = Vector2.ZERO
	var ind := int(ej.NIVEIS.find(cena))
	if ind >= 0:
		ej.indice_nivel = ind
	change_scene_to_file(cena)
	for _i in 30:
		await process_frame
	_k = get_first_node_in_group("koliani")
	var x0 := _k.global_position.x
	var y0 := _k.global_position.y
	for d in sentidos:
		for cen in so:
			_k.global_position = Vector2(x0 + (0.0 if d > 0 else 300.0), y0)
			_k.velocity = Vector2.ZERO
			await _soltar()
			await _esperar(20)
			# vira-a para o sentido pedido com um toque
			await _premir("mover_direita" if d > 0 else "mover_esquerda", 3)
			await _esperar(12)
			await call("_cen_" + cen, d)
			await _soltar()
			await _esperar(30)
	print("qa_ingame: fim; max VFX de skin vivos = ", _n_vfx_max)
	quit()


func _esperar(n: int) -> void:
	for _i in n:
		await physics_frame


func _premir(acao: String, n: int) -> void:
	Input.action_press(acao)
	await _esperar(n)
	Input.action_release(acao)


func _soltar() -> void:
	for a in ["mover_esquerda", "mover_direita", "saltar", "atacar", "dash", "rolar", "mirar_baixo"]:
		Input.action_release(a)
	await physics_frame


func _vfx_vivos() -> int:
	var n := 0
	for c in _k.get_parent().get_children():
		if str(c.name).begins_with("SkinVFX"):
			n += 1
	_n_vfx_max = maxi(_n_vfx_max, n)
	return n


## Captura `n` recortes, um a cada `passo` frames fisicos, e grava a tira.
func _tira(nome: String, d: int, n: int, passo: int, antes: Callable = Callable()) -> void:
	var quadros: Array[Image] = []
	for i in n:
		if antes.is_valid():
			antes.call(i)
		await RenderingServer.frame_post_draw
		var img := root.get_viewport().get_texture().get_image()
		# O renderer pode devolver RGB8; o recorte usa RGBA8.
		img.convert(Image.FORMAT_RGBA8)
		var c: Vector2 = _k.get_global_transform_with_canvas().origin + Vector2(0, -20)
		var r := Rect2i(int(c.x) - CROP / 2, int(c.y) - CROP / 2, CROP, CROP)
		r = r.intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
		var rec := Image.create(CROP, CROP, false, Image.FORMAT_RGBA8)
		rec.fill(Color(0.1, 0.07, 0.14))
		rec.blit_rect(img, r, Vector2i(0, 0))
		rec.resize(CROP * ESC, CROP * ESC, Image.INTERPOLATE_NEAREST)
		quadros.append(rec)
		_vfx_vivos()
		await _esperar(passo)
	var por_linha := 8
	var linhas := ceili(float(n) / por_linha)
	var folha := Image.create(mini(n, por_linha) * CROP * ESC, linhas * CROP * ESC, false, Image.FORMAT_RGBA8)
	for i in n:
		folha.blit_rect(quadros[i], Rect2i(0, 0, CROP * ESC, CROP * ESC),
			Vector2i((i % por_linha) * CROP * ESC, (i / por_linha) * CROP * ESC))
	folha.save_png("%s/%s_%s.png" % [_saida, nome, "dir" if d > 0 else "esq"])


func _cen_idle(d: int) -> void:
	await _tira("idle", d, 4, 6)


func _cen_run(d: int) -> void:
	Input.action_press("mover_direita" if d > 0 else "mover_esquerda")
	await _esperar(40)
	await _tira("run", d, 16, 3)


func _cen_jump(d: int) -> void:
	Input.action_press("mover_direita" if d > 0 else "mover_esquerda")
	await _esperar(10)
	Input.action_press("saltar")
	await _esperar(2)
	await _tira("jump", d, 16, 4)


func _cen_djump(d: int) -> void:
	Input.action_press("mover_direita" if d > 0 else "mover_esquerda")
	Input.action_press("saltar")
	await _esperar(3)
	Input.action_release("saltar")
	await _esperar(16)
	Input.action_press("saltar")
	await _esperar(2)
	Input.action_release("saltar")
	await _tira("djump", d, 12, 3)


func _cen_attack(d: int) -> void:
	await _tira("attack", d, 16, 2, func(i: int) -> void:
		if i == 0:
			Input.action_press("atacar")
		elif i == 1:
			Input.action_release("atacar"))


func _cen_dash(d: int) -> void:
	await _tira("dash", d, 12, 1, func(i: int) -> void:
		if i == 0:
			Input.action_press("dash")
		elif i == 1:
			Input.action_release("dash"))


func _cen_roll(d: int) -> void:
	Input.action_press("mover_direita" if d > 0 else "mover_esquerda")
	await _tira("roll", d, 12, 2, func(i: int) -> void:
		if i == 0:
			Input.action_press("rolar")
		elif i == 1:
			Input.action_release("rolar"))


func _cen_land(d: int) -> void:
	# queda forte: sobe 380 px e cai
	_k.global_position.y -= 380.0
	_k.velocity = Vector2.ZERO
	await _tira("land", d, 16, 4)


func _cen_pogo(d: int) -> void:
	_k.global_position.y -= 120.0
	_k.velocity = Vector2.ZERO
	await _esperar(6)
	Input.action_press("mirar_baixo")
	Input.action_press("atacar")
	await _esperar(2)
	Input.action_release("atacar")
	await _tira("pogo", d, 12, 3, func(i: int) -> void:
		if i == 6 and VfxSkin.pasta() != "":
			VfxSkin.tocar(_k, "pogo_impact", _k.global_position + Vector2(0, 24)))
