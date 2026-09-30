extends SceneTree
## Comparação REAL do corpo: mesmo canvas/frame/posição/escala, efeitos ocultos.
var saida := "res://work/shadowblade_fidelity"
var palco: Node2D
var filme := false
var fotogramas := 0

func aguardar(n: int) -> void:
	for i in n:
		await physics_frame
		if filme:
			fotogramas += 1
			if fotogramas % 3 == 0:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(saida + "/movimento_%03d.png" % (fotogramas / 3))

func _init() -> void:
	call_deferred("normal_ingame" if "--ingame" in OS.get_cmdline_user_args() else "executar")

func executar() -> void:
	root.size = Vector2i(1280, 720)
	var ej := root.get_node("EstadoJogo")
	ej.modo_teste = true
	palco = Node2D.new()
	root.add_child(palco)
	var fundo := ColorRect.new()
	fundo.color = Color("201a29")
	fundo.size = Vector2(1280, 720)
	palco.add_child(fundo)
	var poses := {"idle": 0, "run": 3, "jump_loop": 1, "dash": 1, "roll": 2, "attack": 2}
	var capturas := []
	var contratos := []
	for id in ["skin_koliani_base", "skin_shadowblade"]:
		ej.cosmeticos_equipados["skins"] = id
		if not id in ej.itens_comprados:
			ej.itens_comprados.append(id)
		var sombra: bool = id == "skin_shadowblade"
		assert(is_equal_approx(VfxSkin.forca_glow_corpo(), 0.55 if sombra else 1.0))
		assert(VfxSkin.mascara_luz_corpo() == (0 if sombra else 1))
		var k = load("res://scenes/actors/Koliani.tscn").instantiate()
		k.usar_golden_set = true
		k.position = Vector2(640, 420)
		palco.add_child(k)
		k.set_physics_process(false)
		k.set_process(false)
		k.get_node("Camera2D").enabled = false
		var corpo: AnimatedSprite2D = k.get_node("Sprite/Corpo")
		VfxSkin.atualizar_aura(k, corpo, 0.0, 0.5)
		assert((corpo.get_parent().get_node_or_null("ShadowbladeAura") != null) == sombra)
		# Isolar corpo sem modificar shader/escala/offset da skin.
		for filho in k.get_node("Sprite").get_children():
			if filho != corpo and filho is CanvasItem:
				filho.visible = false
		if k.get_node_or_null("SlashVFX"):
			k.get_node("SlashVFX").visible = false
		contratos.append({"id": id, "escala": str(corpo.scale), "offset": str(corpo.offset),
			"posicao": str(corpo.position), "filter": corpo.texture_filter,
			"colisao": str(k.get_node("CollisionShape2D").shape.get_rect())})
		for nome in poses:
			corpo.animation = nome
			corpo.stop()
			corpo.frame = poses[nome]
			await process_frame
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			img.convert(Image.FORMAT_RGBA8)
			img.save_png(saida + "/%s_%s_sem_vfx.png" % [id, nome])
			capturas.append(img.get_region(Rect2i(576, 320, 128, 128)))
		if sombra:
			ej.cosmeticos_equipados["skins"] = "skin_koliani_base"
			VfxSkin.atualizar_aura(k, corpo, 0.0, 0.5)
			await process_frame
			assert(corpo.get_parent().get_node_or_null("ShadowbladeAura") == null)
		k.queue_free()
		await process_frame
	var folha := Image.create(6 * 128, 2 * 128, false, Image.FORMAT_RGBA8)
	for i in capturas.size():
		folha.blit_rect(capturas[i], Rect2i(0, 0, 128, 128), Vector2i((i % 6) * 128, (i / 6) * 128))
	folha.save_png(saida + "/comparacao_renderer_1x.png")
	folha.resize(6 * 384, 2 * 384, Image.INTERPOLATE_NEAREST)
	folha.save_png(saida + "/comparacao_renderer_3x.png")
	var f := FileAccess.open(saida + "/contratos_renderer.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(contratos, "\t"))
	f.close()
	print("QA SHADOWBLADE: 12 capturas reais sem VFX, seis poses, escala/offset registados")
	ej.cosmeticos_equipados["skins"] = "skin_koliani_base"
	assert(is_equal_approx(VfxSkin.forca_glow_corpo(), 1.0))
	assert(VfxSkin.mascara_luz_corpo() == 1)
	print("QA SHADOWBLADE: perfil visual base / premium / regresso a base validado")
	palco.queue_free()
	await process_frame
	quit()

func normal_ingame() -> void:
	filme = "--filme" in OS.get_cmdline_user_args()
	root.size = Vector2i(1280, 720)
	var ej := root.get_node("EstadoJogo")
	ej.modo_teste = true
	ej.modo_dev = true
	ej.cosmeticos_equipados["skins"] = "skin_shadowblade"
	if not "skin_shadowblade" in ej.itens_comprados:
		ej.itens_comprados.append("skin_shadowblade")
	ej.habilidades_suspensas.clear()
	for h in ["dash", "dash_aereo", "rolar", "salto_duplo"]:
		if not h in ej.habilidades:
			ej.habilidades.append(h)
	ej.indice_nivel = 0
	ej.checkpoint = Vector2.ZERO
	change_scene_to_file("res://scenes/levels/Floresta_Putrefata.tscn")
	await aguardar(45)
	await gravar_normal("idle")
	Input.action_press("mover_direita")
	await aguardar(25)
	await gravar_normal("run")
	Input.action_press("saltar")
	await aguardar(8)
	await gravar_normal("jump")
	Input.action_release("saltar")
	Input.action_press("dash")
	await aguardar(3)
	await gravar_normal("dash")
	Input.action_release("dash")
	Input.action_release("mover_direita")
	await aguardar(60)
	Input.action_press("rolar")
	await aguardar(8)
	await gravar_normal("roll")
	Input.action_release("rolar")
	await aguardar(25)
	Input.action_press("atacar")
	await aguardar(5)
	await gravar_normal("attack")
	Input.action_release("atacar")
	print("QA SHADOWBLADE: seis capturas no nivel real, input real, VFX normais; modo dev exclusivo do arnes")
	# Deixar terminar os efeitos temporarios antes de destruir a cena do arnes.
	await create_timer(1.0).timeout
	current_scene.queue_free()
	await process_frame
	VfxSkin._cache.clear()
	await process_frame
	quit()

func gravar_normal(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(saida + "/ingame_" + nome + ".png")
	var k = get_first_node_in_group("koliani")
	print("CAPTURA NORMAL %s animacao=%s frame=%d" % [nome, k.get_node("Sprite/Corpo").animation, k.get_node("Sprite/Corpo").frame])
