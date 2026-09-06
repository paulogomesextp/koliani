extends Node2D
## Abre por proximidade: funciona com toque e teclado sem botão novo.
signal recolhido
const SAQUE := preload("res://scripts/saque_chefe.gd")
var _aberto := false
var _painel: CanvasLayer

func _ready() -> void:
	z_index = 5
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-29, -34, 58, 34), Color("251832"))
	draw_rect(Rect2(-29, -34, 58, 34), Color("e9b962"), false, 3)
	draw_rect(Rect2(-31, -45 if _aberto else -39, 62, 12), Color("704186"))
	draw_rect(Rect2(-5, -27, 10, 14), Color("ffe7a1"))

func _process(_dt: float) -> void:
	if _aberto:
		return
	var kol := get_tree().get_first_node_in_group("koliani") as Node2D
	if kol and kol.global_position.distance_to(global_position + Vector2(0, -22)) < 90:
		_abrir.call_deferred()

func _abrir() -> void:
	if _aberto:
		return
	_aberto = true
	queue_redraw()
	var estado := get_node("/root/EstadoJogo")
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var premio := SAQUE.sortear(estado.indice_nivel, estado.armas,
		estado.armaduras, estado.melhorias, rng)
	var textos := get_node("/root/Textos")
	var descricao: String
	match premio.tipo:
		"arma", "armadura":
			estado._conceder_um(premio)
			descricao = textos.t(premio.nome)
		"melhoria":
			var rank: int = estado.rank_melhoria(premio.id) + 1
			estado.melhorias[premio.id] = rank
			estado.melhoria_comprada.emit(premio.id, rank)
			descricao = textos.t("chest.stat") + " " + textos.t("shrine." + premio.id)
		_:
			estado.ganhar_essencia(premio.valor)
			descricao = "+%d " % int(premio.valor) + textos.t("chest.essence")
	estado.guardar()
	get_node("/root/Som").toca("apanhar", -6.0)
	_mostrar(descricao)

func _mostrar(descricao: String) -> void:
	var textos := get_node("/root/Textos")
	_painel = CanvasLayer.new()
	_painel.layer = 110
	add_child(_painel)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painel.add_child(centro)
	var caixa := PanelContainer.new()
	caixa.custom_minimum_size = Vector2(360, 180)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("251832")
	estilo.border_color = Color("e9b962")
	estilo.set_border_width_all(3)
	estilo.set_content_margin_all(22)
	caixa.add_theme_stylebox_override("panel", estilo)
	centro.add_child(caixa)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 18)
	caixa.add_child(coluna)
	for texto: String in [textos.t("chest.title"), descricao]:
		var label := Label.new()
		label.text = texto
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 24)
		coluna.add_child(label)
	var botao := Button.new()
	botao.text = textos.t("chest.continue")
	botao.custom_minimum_size.y = 56
	coluna.add_child(botao)
	botao.pressed.connect(func() -> void:
		_painel.queue_free()
		recolhido.emit(), CONNECT_ONE_SHOT)
	botao.grab_focus()
