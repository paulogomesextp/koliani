extends SceneTree
## Tempo real, transicao visivel e isolamento entre anuncio e compra.
func _init() -> void:
	call_deferred("executar")

func captura(nome: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://work/shadowblade_fidelity/carrossel_"+nome+".png")

func executar() -> void:
	root.size = Vector2i(1920,1080)
	var ej := root.get_node("EstadoJogo")
	var textos := root.get_node("Textos")
	ej.modo_teste = true
	var saldo: int = ej.veracoins
	var loja = load("res://scripts/loja.gd").new()
	root.add_child(loja)
	await create_timer(0.35).timeout
	assert(loja._carrossel_ids.size() == 5)
	assert(is_equal_approx(loja._carrossel_timer.wait_time,5.0))
	assert(loja._hero_id == "skin_shadowblade")
	var selecionado: String = loja._sel
	loja._carrossel_timer.start()
	await create_timer(4.8).timeout
	assert(loja._hero_id == "skin_shadowblade")
	await captura("inicio")
	await loja._carrossel_timer.timeout
	await create_timer(0.12).timeout
	assert(loja._hero_linha.modulate.a > 0.0 and loja._hero_linha.modulate.a < 1.0)
	assert(loja._hero_botao.disabled)
	await captura("fade")
	await create_timer(0.55).timeout
	assert(loja._hero_id != "skin_shadowblade")
	assert(loja._sel == selecionado)
	assert(loja._det_nome.text == textos.t("shop.item.%s.name" % selecionado))
	assert(loja._hero_nome.text == textos.t("shop.item.%s.name" % loja._hero_id))
	assert(loja._hero_img.texture == CosmeticosVisuais.splash_loja(loja._hero_id))
	assert(is_equal_approx(loja._hero_linha.modulate.a,1.0))
	await captura(loja._hero_id)
	loja._focar_detalhe()
	assert(loja._sel == loja._hero_id)
	selecionado = loja._sel
	for i in 4:
		loja._avancar_carrossel()
		await create_timer(0.65).timeout
		assert(loja._sel == selecionado)
		assert(loja._hero_img.texture == CosmeticosVisuais.splash_loja(loja._hero_id))
		await captura(loja._hero_id)
	loja._avancar_carrossel()
	await create_timer(0.1).timeout
	loja._selecionar("skin_anjo")
	await create_timer(0.65).timeout
	assert(loja._hero_id == "skin_anjo" and loja._sel == "skin_anjo")
	assert(is_equal_approx(loja._hero_linha.modulate.a,1.0) and not loja._hero_botao.disabled)
	loja._escolher_categoria("extras")
	assert(loja._carrossel_timer.is_stopped())
	assert(loja._hero_id == loja._sel)
	loja._escolher_categoria("destaques")
	assert(not loja._carrossel_timer.is_stopped())
	loja._avancar_carrossel()
	await create_timer(0.1).timeout
	loja._fechar()
	await create_timer(0.7).timeout
	assert(not is_instance_valid(loja))
	assert(ej.veracoins == saldo)
	print("QA CARROSSEL: cinco artes; 5 segundos reais, fade, ciclo, Ver, compra preservada, selecao manual, tabs e fecho passaram")
	quit()
