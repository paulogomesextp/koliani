extends CanvasLayer
## Cartao curto de fim de regiao (vertical slice da Regiao I). Sem cinematica:
## painel na UI de sempre com "BOSS DERROTADO", a habilidade ganha (se houver),
## o nome da regiao concluida e um botao Continuar.
signal fechado

## Preenchido por `mostrar()`. `habilidade` = chave runtime ("" = nenhuma).
static func mostrar(pai: Node, chave_regiao: String, habilidade: String) -> Node:
	var cartao := (load("res://scripts/cartao_regiao.gd") as GDScript).new() as CanvasLayer
	cartao.name = "CartaoRegiao"
	cartao.set_meta("chave_regiao", chave_regiao)
	cartao.set_meta("habilidade", habilidade)
	pai.add_child(cartao)
	return cartao


func _ready() -> void:
	layer = 120
	var chave_regiao: String = get_meta("chave_regiao", "")
	var habilidade: String = get_meta("habilidade", "")
	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.02, 0.06, 0.82)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caixa := PanelContainer.new()
	caixa.custom_minimum_size = Vector2(520, 240)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("251832")
	estilo.border_color = Color("e9b962")
	estilo.set_border_width_all(3)
	estilo.set_content_margin_all(26)
	caixa.add_theme_stylebox_override("panel", estilo)
	centro.add_child(caixa)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 16)
	caixa.add_child(coluna)
	_linha(coluna, Textos.t("region.boss_defeated"), 22, Color("c9a7e8"))
	if habilidade != "":
		var nome: String = Textos.t("hud.ability." + habilidade)
		_linha(coluna, Textos.tf("region.ability_unlocked", [nome]), 26, Color("ffe7a1"))
		_linha(coluna, Textos.t("region.ability_kit"), 18, Color("d8d0e6"))
	_linha(coluna, Textos.t(chave_regiao), 32, Color("e9b962"))
	var botao := Button.new()
	botao.text = Textos.t("chest.continue")
	botao.custom_minimum_size.y = 56
	coluna.add_child(botao)
	botao.pressed.connect(func() -> void:
		fechado.emit()
		queue_free(), CONNECT_ONE_SHOT)
	botao.grab_focus()


func _linha(pai: Control, texto: String, tamanho: int, cor: Color) -> void:
	var label := Label.new()
	label.text = texto
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	pai.add_child(label)
