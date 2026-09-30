extends SceneTree
## Loja real: splash no destaque, sprite no detalhe, compra/equip/save isolados.
func _init() -> void:
	call_deferred("executar")

func executar() -> void:
	var ej := root.get_node("EstadoJogo")
	ej.modo_teste = true
	var categoria := LojaCatalogo.item("skin_shadowblade")
	assert(categoria["v"] == 500 and categoria["k"] == -1)
	var custo: int = ej.preco_loja("skin_shadowblade","v")
	var moedas = ej.veracoins
	for tamanho in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = tamanho
		var loja = load("res://scripts/loja.gd").new()
		root.add_child(loja)
		await create_timer(0.4).timeout
		assert(loja._sel == "skin_shadowblade")
		assert(loja._hero_img.texture == CosmeticosVisuais.splash_loja("skin_shadowblade"))
		assert(loja._det_img.texture == CosmeticosVisuais.preview_loja("skin_shadowblade"))
		assert(loja._hero_img.texture != loja._det_img.texture)
		assert(loja._hero_img.visible and loja._det_img.visible)
		assert(loja._hero_img.get_global_rect().end.x <= tamanho.x+1)
		assert(loja._det_img.get_global_rect().end.y <= tamanho.y+1)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://work/shadowblade_fidelity/loja_shadowblade_%d.png" % tamanho.x)
		loja.queue_free()
		await process_frame
	var loja = load("res://scripts/loja.gd").new()
	root.add_child(loja)
	loja._selecionar("skin_shadowblade")
	loja._comprar("v")
	assert(ej.item_adquirido("skin_shadowblade"))
	assert(ej.veracoins == moedas-custo)
	loja._equipar()
	assert(ej.item_equipado("skin_shadowblade"))
	var salvo: Dictionary = ej.para_dicionario()
	ej.de_dicionario(JSON.parse_string(JSON.stringify(salvo)))
	assert(ej.item_adquirido("skin_shadowblade") and ej.item_equipado("skin_shadowblade"))
	assert(CosmeticosVisuais.splash_loja("skin_fornalha") == CosmeticosVisuais.preview_loja("skin_fornalha"))
	loja.queue_free()
	await process_frame
	CosmeticosVisuais._cache_arte.clear()
	await process_frame
	print("QA SHADOWBLADE LOJA: 1280/1920, splash/sprite, adquirir/equipar/save e fallback passaram; economia preservada")
	quit()
