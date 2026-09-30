extends SceneTree
## Matriz real de skins/combos/espelhos; apenas geometria visual, sem gameplay.
var casos := 0
func _init() -> void:
	call_deferred("executar")

func executar() -> void:
	root.size = Vector2i(1280,720)
	var ej := root.get_node("EstadoJogo")
	ej.modo_teste = true
	ej.indice_nivel = 0
	var palco := Node2D.new()
	root.add_child(palco)
	var fundo := ColorRect.new()
	fundo.size = Vector2(1280,720)
	fundo.color = Color("201a29")
	palco.add_child(fundo)
	var ids := ["skin_koliani_base","skin_carmesim","skin_luar"]
	ids.append_array(CosmeticosVisuais.DIR_SKIN.keys())
	for id in ids:
		ej.cosmeticos_equipados["skins"] = id
		if not id in ej.itens_comprados:
			ej.itens_comprados.append(id)
		var k = load("res://scenes/actors/Koliani.tscn").instantiate()
		k.usar_golden_set = true
		k.position = Vector2(640,420)
		palco.add_child(k)
		k.set_physics_process(false)
		k.set_process(false)
		k.get_node("Camera2D").enabled = false
		var corpo: AnimatedSprite2D = k.get_node("Sprite/Corpo")
		var colisao: Rect2 = k.get_node("CollisionShape2D").shape.get_rect()
		for sentido in [-1.0,1.0]:
			for grav in [-1.0,1.0]:
				for passo in 4:
					k._olha_para = sentido
					k._sinal_grav = grav
					k._combo_passo = passo
					k._ataque_dur = k.DUR_COMBO[passo]
					k._ataque_no_ar = false
					corpo.animation = k._anim_ataque()
					corpo.stop()
					corpo.frame = 2
					k.get_node("Sprite").scale = Vector2(sentido,grav)
					k._disparar_vfx_golpe()
					var arco: AnimatedSprite2D = k._vfx_combo if k._vfx_combo else k._slash_vfx
					arco.stop()
					arco.frame = mini(2,arco.sprite_frames.get_frame_count(arco.animation)-1)
					var margem: float = arco.position.x*sentido + VfxPosicionamento.minimo_frontal(arco,sentido)
					var ponta := VfxPosicionamento.frente_espada(corpo,k._anim_ataque())
					assert(margem >= ponta+1.99, "Arco sobre espada/corpo: " + id)
					assert(colisao == k.get_node("CollisionShape2D").shape.get_rect())
					casos += 1
					if grav == 1.0 and passo == 0:
						k._animar_aura()
						await process_frame
						await RenderingServer.frame_post_draw
						root.get_texture().get_image().save_png("res://work/shadowblade_fidelity/espada_%s_%s.png" % [id,"esq" if sentido < 0 else "dir"])
		k.queue_free()
		await process_frame
	# Modelos anteriores usam luz de golpe; provar deslocacao sem novo arco baked.
	for modo in ["legado","premium","piloto"]:
		var k = load("res://scenes/actors/Koliani.tscn").instantiate()
		k.usar_prototipo_premium = modo == "premium"
		k.usar_piloto_visual_5g = modo == "piloto"
		palco.add_child(k)
		k.set_physics_process(false)
		k.set_process(false)
		for sentido in [-1.0,1.0]:
			k._olha_para = sentido
			k._flash_golpe()
			assert(k._luz_golpe.position.x >= VfxPosicionamento.frente_espada(k._corpo,k._anim_ataque())+1.99)
			casos += 1
		k.queue_free()
		await process_frame
	print("QA VFX ESPADA: %d casos, 9 skins, 4 golpes, 2 sentidos, 2 gravidades + 3 modelos anteriores" % casos)
	palco.queue_free()
	await process_frame
	VfxSkin._cache.clear()
	VfxPosicionamento._limites.clear()
	quit()
