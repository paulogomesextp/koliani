extends Control
## QA visual da colecao Relíquias do Coração Podre na Loja, em janela real.
## Estados: tudo bloqueado -> Regiao I concluida -> pack parcial -> pack completo.
## Grava PNGs em <user>/qa_colecao/. ESCREVE no save: correr por
## `tools/correr_qa_cosmeticos.ps1` (APPDATA isolado, saldo ja' semeado).

var falhas := 0
var _dir := ""
var _loja: Node


func _check(c: bool, m: String) -> void:
	print(("PASS   " if c else "FALHOU ") + m)
	if not c:
		falhas += 1


func _foto(nome: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_dir + nome + ".png")


func _abrir(cat: String, id: String) -> void:
	if _loja:
		_loja.free()
	_loja = Loja.new()
	add_child(_loja)
	await get_tree().create_timer(0.3).timeout
	_loja._escolher_categoria(cat)
	_loja._selecionar(id)
	await get_tree().create_timer(0.2).timeout


func _texto_cortado() -> Array:
	# um Label/Button "cortado" = texto mais largo/alto que a area disponivel
	var cortados := []
	for n in _loja.find_children("*", "Button", true, false):
		var b := n as Button
		var f := b.get_theme_font("font")
		var sz := b.get_theme_font_size("font_size")
		var linhas := b.text.split("\n")
		var alt := float(linhas.size()) * f.get_height(sz)
		var larg := 0.0
		for l in linhas:
			larg = maxf(larg, f.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x)
		if larg > b.size.x - 12.0 or alt > b.size.y - 4.0:
			cortados.append("%s (%.0fx%.0f em %.0fx%.0f)" % [b.name, larg, alt, b.size.x, b.size.y])
	for n in _loja.find_children("*", "Label", true, false):
		var l := n as Label
		if l.text == "" or not l.is_visible_in_tree():
			continue
		if l.get_line_count() > 1 and l.get_visible_line_count() < l.get_line_count():
			cortados.append("label cortada: " + l.text.left(30))
	return cortados


func _ready() -> void:
	_dir = OS.get_user_data_dir() + "/qa_colecao/"
	DirAccess.make_dir_recursive_absolute(_dir)
	await get_tree().create_timer(0.4).timeout
	var ids := ["skin_coracao_podre", "efeito_rasto_esporos", "hud_moldura_raizes", "pack_coracao_podre"]
	# 1. antes da Regiao I
	await _abrir("destaques", "pack_coracao_podre")
	await _foto("c01_destaques_bloqueado")
	for id: String in ids:
		_check(EstadoJogo.estado_item_loja(id) == "bloqueado", "bloqueado antes da Regiao I: " + id)
	_check(_loja._btn_k.disabled and _loja._btn_v.disabled, "pack bloqueado: botoes de compra desativados")
	_check(_loja._det_req.text != "", "pack bloqueado: mostra o requisito da Regiao I (%s)" % _loja._det_req.text)
	_check(_texto_cortado().is_empty(), "sem texto cortado (destaques bloqueado) %s" % str(_texto_cortado()))
	for cat_id in [["skins", "skin_coracao_podre"], ["efeitos", "efeito_rasto_esporos"], ["hud_checkpoint", "hud_moldura_raizes"]]:
		await _abrir(cat_id[0], cat_id[1])
		await _foto("c02_%s_bloqueado" % cat_id[0])
		_check(_texto_cortado().is_empty(), "sem texto cortado (%s) %s" % [cat_id[0], str(_texto_cortado())])
	# 2. Regiao I concluida: disponiveis, com saldo
	for i in 5:
		EstadoJogo.marcar_nivel_concluido(i)
	await _abrir("packs", "pack_coracao_podre")
	await _foto("c03_pack_disponivel_nenhum")
	_check(EstadoJogo.estado_item_loja("pack_coracao_podre") == "disponivel", "pack disponivel apos Regiao I")
	_check(not _loja._btn_k.disabled or EstadoJogo.kolicoins < 1300, "pack: botao K coerente com saldo (K=%d)" % EstadoJogo.kolicoins)
	_check(_loja._btn_k.text.contains("1300") and _loja._btn_v.text.contains("300"), "pack: precos 1300 K / 300 V (%s | %s)" % [_loja._btn_k.text, _loja._btn_v.text])
	_check(_texto_cortado().is_empty(), "sem texto cortado (pack) %s" % str(_texto_cortado()))
	await _abrir("skins", "skin_coracao_podre")
	await _foto("c04_skin_disponivel")
	_check(_loja._btn_k.visible == false and _loja._btn_v.text.contains("240"), "skin: so V 240")
	await _abrir("efeitos", "efeito_rasto_esporos")
	await _foto("c05_efeito_disponivel")
	await _abrir("hud_checkpoint", "hud_moldura_raizes")
	await _foto("c06_hud_disponivel")
	# 3. parcial: compra so' a skin
	EstadoJogo.modo_teste = true
	EstadoJogo.dev_dar_veracoins(300)
	EstadoJogo.modo_teste = false
	_check(EstadoJogo.comprar_item("skin_coracao_podre", "v")["ok"], "compra da skin por V")
	await _abrir("packs", "pack_coracao_podre")
	await _foto("c07_pack_parcial")
	_check(_loja._btn_k.text.contains("625") and _loja._btn_v.text.contains("135"), "pack parcial: 625 K / 135 V (%s | %s)" % [_loja._btn_k.text, _loja._btn_v.text])
	_check(_loja._det_aviso.text.contains("1") , "pack parcial: progresso visivel (%s)" % _loja._det_aviso.text.replace("\n", " / "))
	_check(_texto_cortado().is_empty(), "sem texto cortado (pack parcial) %s" % str(_texto_cortado()))
	# 4. completo
	EstadoJogo.ganhar_kolicoins(2000, false)
	_loja._comprar("k")
	await get_tree().create_timer(0.3).timeout
	await _foto("c08_pack_completo")
	_check(EstadoJogo.estado_item_loja("pack_coracao_podre") == "completo", "pack completo")
	_check(not _loja._btn_k.visible and not _loja._btn_v.visible and not _loja._btn_eq.visible, "pack completo: sem botao de compra")
	_check(not _loja._det_estado.text.is_empty(), "pack completo: estado visivel (%s)" % _loja._det_estado.text)
	await _abrir("skins", "skin_coracao_podre")
	await _foto("c09_skin_adquirida")
	_check(_loja._btn_eq.visible and not EstadoJogo.item_equipado("skin_coracao_podre"), "skin do pack adquirida e NAO auto-equipada")
	print("QA COLECAO: %s (%d falhas)" % ["PASS" if falhas == 0 else "FAIL", falhas])
	get_tree().quit(0 if falhas == 0 else 1)
