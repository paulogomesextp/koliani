extends SceneTree
## Contratos reais das quatro skins; saves só na sandbox do runner.
const IDS := ["skin_anjo", "skin_demonio", "skin_abadia_afogada", "skin_celestial"]
var falhas := 0
var palco: Node2D

func _init() -> void:
	call_deferred("executar")

func verificar(ok: bool, texto: String) -> void:
	print(("PASS " if ok else "FALHOU ") + texto)
	if not ok:
		falhas += 1

func executar() -> void:
	root.size = Vector2i(1280, 720)
	var ej := root.get_node("EstadoJogo")
	# Demonstração do EXE exportado, exclusivamente em sandbox explícita.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--demo="):
			var id := arg.get_slice("=", 1)
			if not id in IDS or not "/work/skins_premium_20261001/qa_export/" in OS.get_user_data_dir().replace("\\", "/"):
				push_error("Demo recusada fora da sandbox de export.")
				quit(97)
				return
			if not id in ej.itens_comprados:
				ej.itens_comprados.append(id)
			ej.cosmeticos_equipados["skins"] = id
			ej.indice_nivel = 0
			ej.checkpoint = Vector2.ZERO
			verificar(ej.guardar(), "demo isolada gravada: " + id)
			print("DEMO USERDIR: " + OS.get_user_data_dir())
			quit(0 if falhas == 0 else 1)
			return
	ej.modo_teste = true
	var antes: Dictionary = ej.para_dicionario().duplicate(true)
	palco = Node2D.new()
	root.add_child(palco)
	var fundo := ColorRect.new()
	fundo.size = Vector2(1280, 720)
	fundo.color = Color("201a29")
	palco.add_child(fundo)
	var contrato := {}
	var capturas: Array[Image] = []
	for id: String in ["skin_koliani_base"] + IDS:
		ej.cosmeticos_equipados["skins"] = id
		if not id in ej.itens_comprados:
			ej.itens_comprados.append(id)
		var k: Node2D = load("res://scenes/actors/Koliani.tscn").instantiate()
		k.usar_golden_set = true
		k.position = Vector2(640, 420)
		palco.add_child(k)
		k.set_physics_process(false)
		k.set_process(false)
		k.get_node("Camera2D").enabled = false
		var corpo: AnimatedSprite2D = k.get_node("Sprite/Corpo")
		var dados := {"scale": corpo.scale, "offset": corpo.offset,
			"colisao": k.get_node("CollisionShape2D").shape.get_rect()}
		for anim: StringName in corpo.sprite_frames.get_animation_names():
			dados[anim] = [corpo.sprite_frames.get_frame_count(anim),
				corpo.sprite_frames.get_animation_speed(anim), corpo.sprite_frames.get_animation_loop(anim)]
		if id == "skin_koliani_base":
			contrato = dados
		else:
			verificar(dados == contrato, id + ": animações, tempos, pivô e colisão iguais à base")
			verificar(not VfxSkin.perfil().is_empty(), id + ": perfil próprio")
			for slot in ["vfx_slash_basic", "double_jump_ring", "land_impact", "pogo_impact", "particulas"]:
				var n := 4 if slot == "particulas" else 6
				var frames := VfxSkin.frames(slot, n)
				verificar(frames != null and frames.get_frame_count("fx") == n, id + ": " + slot)
			verificar(VfxSkin.forca_glow_corpo() == 0.55 and VfxSkin.mascara_luz_corpo() == 0,
				id + ": corpo nítido, brilho separado")
		k._animar_aura()
		var aura := corpo.get_parent().get_node_or_null("ShadowbladeAura")
		verificar((aura != null) == (id != "skin_koliani_base"), id + ": aura correta")
		for sentido in [-1, 1]:
			k.get_node("Sprite").scale.x = sentido
			corpo.animation = "attack"
			corpo.stop()
			corpo.frame = 2
			k._animar_aura()
			if aura:
				verificar(aura.halo.texture == corpo.sprite_frames.get_frame_texture("attack", 2),
					id + ": aura acompanha frame/espelho")
			await process_frame
			await RenderingServer.frame_post_draw
			var imagem := root.get_texture().get_image()
			imagem.convert(Image.FORMAT_RGBA8)
			capturas.append(imagem.get_region(Rect2i(548, 296, 184, 184)))
			ej.cosmeticos_equipados["skins"] = "skin_koliani_base"
			k._animar_aura()
			await process_frame
			verificar(corpo.get_parent().get_node_or_null("ShadowbladeAura") == null,
				id + ": desequipar elimina aura")
			ej.cosmeticos_equipados["skins"] = id
			k._animar_aura()
			aura = corpo.get_parent().get_node_or_null("ShadowbladeAura")
		k.queue_free()
		await process_frame
	var folha := Image.create(184 * 2, 184 * 5, false, Image.FORMAT_RGBA8)
	for i in capturas.size():
		folha.blit_rect(capturas[i], Rect2i(0, 0, 184, 184), Vector2i((i % 2) * 184, (i / 2) * 184))
	folha.resize(736, 1840, Image.INTERPOLATE_NEAREST)
	folha.save_png("res://work/skins_premium_20261001/comparacao_renderer.png")
	palco.queue_free()
	await process_frame
	# Compras pela UI; mesmas regras e sem escrever o save real.
	ej.de_dicionario(antes)
	var loja: Node = load("res://scripts/loja.gd").new()
	root.add_child(loja)
	await process_frame
	for id: String in IDS:
		loja._selecionar(id)
		if not ej.item_adquirido(id):
			loja._comprar("v")
		verificar(ej.item_adquirido(id), id + ": obter pela loja")
		loja._equipar()
		verificar(ej.item_equipado(id), id + ": equipar pela loja")
		verificar(loja._det_img.texture == CosmeticosVisuais.preview_loja(id), id + ": preview real")
		var dados: Dictionary = ej.para_dicionario()
		ej.de_dicionario(JSON.parse_string(JSON.stringify(dados)))
		verificar(ej.item_equipado(id), id + ": persistência JSON")
		await process_frame
	loja.queue_free()
	await process_frame
	ej.de_dicionario(antes)
	VfxSkin._cache.clear()
	CosmeticosVisuais._cache_arte.clear()
	await process_frame
	print("QA SKINS PREMIUM: %s (%d falhas)" % ["PASS" if falhas == 0 else "FALHOU", falhas])
	quit(0 if falhas == 0 else 1)
