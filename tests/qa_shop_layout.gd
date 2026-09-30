extends Control
## QA dirigido da composição da Loja. Corre com userdata isolada, fotografa o
## renderer real e valida estrutura/seleção nas resoluções suportadas.

var _falhas := 0


func _check(condicao: bool, mensagem: String) -> void:
	print(("PASS   " if condicao else "FALHOU ") + mensagem)
	if not condicao:
		_falhas += 1


func _ready() -> void:
	var loja := Loja.new()
	add_child(loja)
	await get_tree().create_timer(0.35).timeout
	# Exercita troca de tab e regressa ao Featured para a captura de referência.
	loja._escolher_categoria("skins")
	loja._escolher_categoria("destaques")
	loja._selecionar("skin_anjo")
	await get_tree().create_timer(0.20).timeout
	var nomes := ["Header", "Navigation", "FeaturedHero", "CatalogScroll", "ItemDetails", "Footer"]
	for nome in nomes:
		var no := loja.find_child(nome, true, false) as Control
		_check(no != null and no.is_visible_in_tree() and no.size.x > 0 and no.size.y > 0,
			"estrutura visível: " + nome)
	var conteudo := loja.find_child("Content", true, false) as Control
	var hero := loja.find_child("FeaturedHero", true, false) as Control
	var detalhe := loja.find_child("ItemDetails", true, false) as Control
	_check(hero.size.y >= conteudo.size.y * 0.38, "Hero domina >=38% da altura do conteúdo")
	_check(detalhe.size.y >= conteudo.size.y - 2.0, "painel de detalhe permanece fixo")
	_check(loja._grelha.columns == 5, "catálogo desktop usa cinco colunas")
	_check(loja._det_nome.text == Textos.t("shop.item.skin_anjo.name"), "seleção atualiza detalhe")
	_check(loja._hero_nome.text == loja._det_nome.text, "seleção atualiza Hero")
	_check(loja._det_img.visible and loja._hero_img.visible, "preview real reutilizado no Hero e detalhe")
	_check(loja._cartoes.has("skin_anjo") and loja._cartoes["skin_anjo"].button_pressed,
		"cartão selecionado destacado")
	var viewport := get_viewport_rect()
	for nome in nomes:
		var no := loja.find_child(nome, true, false) as Control
		var ret := no.get_global_rect()
		_check(ret.position.x >= -1.0 and ret.position.y >= -1.0 and ret.end.x <= viewport.end.x + 1.0
			and ret.end.y <= viewport.end.y + 1.0, "%s dentro do viewport" % nome)
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var saida := args[0]
		DirAccess.make_dir_recursive_absolute(saida.get_base_dir())
		var erro := get_viewport().get_texture().get_image().save_png(saida)
		_check(erro == OK, "captura gravada: " + saida)
	# Fluxos reais pela UI, sem gravar no disco (o runner isola igualmente
	# userdata). O estado inicial serve de referência para o round-trip.
	EstadoJogo.modo_teste = true
	loja._escolher_categoria("skins")
	loja._selecionar("skin_anjo")
	loja._comprar("v")
	_check(EstadoJogo.item_adquirido("skin_anjo"), "GET grátis concede ownership")
	loja._equipar()
	_check(EstadoJogo.item_equipado("skin_anjo") and loja._btn_eq.disabled,
		"equipar atualiza slot e botão")
	loja._selecionar("skin_celestial")
	loja._comprar("v")
	loja._equipar()
	_check(EstadoJogo.item_equipado("skin_celestial") and not EstadoJogo.item_equipado("skin_anjo"),
		"trocar equipado conserva um único slot")
	var salvo := EstadoJogo.para_dicionario()
	EstadoJogo.de_dicionario(JSON.parse_string(JSON.stringify(salvo)))
	_check(EstadoJogo.item_adquirido("skin_anjo") and EstadoJogo.item_equipado("skin_celestial"),
		"round-trip de save conserva ownership/equip")
	loja._fechar()
	await get_tree().process_frame
	loja = Loja.new()
	add_child(loja)
	await get_tree().process_frame
	loja._escolher_categoria("skins")
	loja._selecionar("skin_celestial")
	_check(loja._det_estado.text == Textos.t("shop.state.equipado"), "fechar/reabrir conserva estado")
	loja._escolher_categoria("extras")
	loja._selecionar(Galeria.ITEM)
	loja._comprar("k")
	_check(loja._btn_eq.visible and not loja._btn_eq.disabled, "Galeria adquirida mantém botão ativo")
	loja._equipar()
	_check(loja.get_child(loja.get_child_count() - 1) is Galeria, "VER abre Galeria")
	loja.get_child(loja.get_child_count() - 1).free()
	loja._escolher_categoria("packs")
	loja._selecionar("pack_coracao_podre")
	_check(loja._btn_k.disabled and not loja._det_req.text.is_empty(), "item bloqueado mostra requisito")
	for categoria: String in LojaCatalogo.CATEGORIAS:
		loja._escolher_categoria(categoria)
		await get_tree().process_frame
		_check(loja._cartoes.size() == LojaCatalogo.da_categoria(categoria).size(), "tab: " + categoria)
	loja._fechar()
	await get_tree().process_frame
	print("QA SHOP LAYOUT: %s (%d falhas)" % ["PASS" if _falhas == 0 else "FAIL", _falhas])
	get_tree().quit(0 if _falhas == 0 else 1)
