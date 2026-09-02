class_name Santuario
extends Control
## O SANTUÁRIO -- ecrã de MELHORIAS permanentes. Gasta-se Essência
## (`EstadoJogo.essencia`) para subir ranks das melhorias de `melhorias.gd`.
## Aberto entre níveis (botão no SeletorNiveis / na Pausa).
##
## Sinal `fechado` quando se recua.

signal fechado

const M := preload("res://scripts/melhorias.gd")

## Resumo do efeito de cada melhoria (fallback; i18n = "shrine.<id>.ef").
const EFEITO_TXT := {
	"vitalidade": "+20 vida máxima por nível",
	"forca": "+12% dano por nível",
	"foco": "+28% regeneração de Energia por nível",
	"agilidade": "+0.06 s de i-frames no rolamento por nível",
	"furia": "+0.22 ao multiplicador de crítico por nível",
	"escudo_runico": "+1 carga de bloqueio do escudo por nível",
}
const NOME_TXT := {
	"vitalidade": "Vitalidade", "forca": "Força", "foco": "Foco",
	"agilidade": "Agilidade", "furia": "Fúria", "escudo_runico": "Escudo Rúnico",
}

var _ess_label: Label
var _cartoes: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_montar()
	EstadoJogo.essencia_mudou.connect(func(_n: int) -> void: _refrescar())
	EstadoJogo.melhoria_comprada.connect(func(_i: String, _r: int) -> void: _refrescar())


func _montar() -> void:
	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.04, 0.03, 0.07, 0.96)
	add_child(fundo)

	var titulo := Label.new()
	titulo.anchor_left = 0.5
	titulo.anchor_right = 0.5
	titulo.offset_left = -260.0
	titulo.offset_right = 260.0
	titulo.offset_top = 30.0
	titulo.offset_bottom = 68.0
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", Color(0.97, 0.92, 1.0))
	titulo.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.03))
	titulo.add_theme_constant_override("outline_size", 5)
	titulo.text = _t("shrine.title", "SANTUÁRIO")
	add_child(titulo)

	_ess_label = Label.new()
	_ess_label.anchor_left = 0.5
	_ess_label.anchor_right = 0.5
	_ess_label.offset_left = -160.0
	_ess_label.offset_right = 160.0
	_ess_label.offset_top = 74.0
	_ess_label.offset_bottom = 104.0
	_ess_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ess_label.add_theme_font_size_override("font_size", 22)
	_ess_label.add_theme_color_override("font_color", Color(1.0, 0.82, 1.0))
	_ess_label.add_theme_color_override("font_outline_color", Color(0.05, 0.01, 0.06))
	_ess_label.add_theme_constant_override("outline_size", 4)
	add_child(_ess_label)

	var grelha := GridContainer.new()
	grelha.columns = 3
	grelha.anchor_left = 0.5
	grelha.anchor_right = 0.5
	grelha.anchor_top = 0.0
	grelha.grow_horizontal = Control.GROW_DIRECTION_BOTH
	grelha.offset_top = 128.0
	grelha.offset_left = -570.0
	grelha.offset_right = 570.0
	grelha.add_theme_constant_override("h_separation", 22)
	grelha.add_theme_constant_override("v_separation", 22)
	add_child(grelha)

	for id: String in M.ORDEM:
		var c := _fazer_cartao(id)
		grelha.add_child(c["raiz"])
		_cartoes.append(c)

	var voltar := Button.new()
	voltar.text = _t("sel.back", "‹ Voltar")
	voltar.focus_mode = Control.FOCUS_NONE
	voltar.anchor_left = 0.5
	voltar.anchor_right = 0.5
	voltar.anchor_top = 1.0
	voltar.anchor_bottom = 1.0
	voltar.offset_left = -90.0
	voltar.offset_right = 90.0
	voltar.offset_top = -66.0
	voltar.offset_bottom = -26.0
	voltar.add_theme_font_size_override("font_size", 17)
	voltar.add_theme_color_override("font_color", Color(1, 0.9, 1))
	var sbv := StyleBoxFlat.new()
	sbv.bg_color = Color(0.12, 0.07, 0.15, 0.9)
	sbv.set_corner_radius_all(8)
	sbv.set_border_width_all(1)
	sbv.border_color = Color(0.7, 0.5, 0.7, 0.7)
	for e in ["normal", "hover", "pressed", "focus"]:
		voltar.add_theme_stylebox_override(e, sbv)
	voltar.pressed.connect(func() -> void: fechado.emit())
	add_child(voltar)

	_refrescar()


func _fazer_cartao(id: String) -> Dictionary:
	var cor: Color = M.cor(id)
	var raiz := PanelContainer.new()
	raiz.custom_minimum_size = Vector2(360, 176)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.11, 0.95)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = Color(cor.r, cor.g, cor.b, 0.4)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	raiz.add_theme_stylebox_override("panel", sb)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 7)
	raiz.add_child(col)

	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 10)
	col.add_child(topo)
	var ic := Label.new()
	ic.text = M.icone(id)
	ic.add_theme_font_size_override("font_size", 30)
	ic.add_theme_color_override("font_color", cor.lightened(0.15))
	topo.add_child(ic)
	var nome := Label.new()
	nome.text = _t("shrine.%s" % id, NOME_TXT.get(id, id)).to_upper()
	nome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nome.add_theme_font_size_override("font_size", 19)
	nome.add_theme_color_override("font_color", Color(0.98, 0.95, 1))
	topo.add_child(nome)

	var pips := Label.new()
	pips.name = "Pips"
	pips.add_theme_font_size_override("font_size", 15)
	pips.add_theme_color_override("font_color", cor.lightened(0.2))
	col.add_child(pips)

	var ef := Label.new()
	ef.text = _t("shrine.%s.ef" % id, EFEITO_TXT.get(id, ""))
	ef.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ef.custom_minimum_size = Vector2(320, 0)
	ef.add_theme_font_size_override("font_size", 13)
	ef.add_theme_color_override("font_color", Color(0.78, 0.74, 0.84))
	col.add_child(ef)

	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 12)
	col.add_child(linha)
	var custo := Label.new()
	custo.name = "Custo"
	custo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	custo.add_theme_font_size_override("font_size", 15)
	custo.add_theme_color_override("font_color", Color(1.0, 0.84, 1.0))
	linha.add_child(custo)
	var comprar := Button.new()
	comprar.name = "Comprar"
	comprar.text = _t("shrine.buy", "MELHORAR")
	comprar.focus_mode = Control.FOCUS_NONE
	comprar.custom_minimum_size = Vector2(126, 36)
	comprar.add_theme_font_size_override("font_size", 15)
	var sbc := StyleBoxFlat.new()
	sbc.bg_color = Color(cor.r * 0.4, cor.g * 0.4, cor.b * 0.4, 0.95)
	sbc.set_corner_radius_all(8)
	sbc.set_border_width_all(2)
	sbc.border_color = cor
	var sbd := sbc.duplicate() as StyleBoxFlat
	sbd.bg_color = Color(0.1, 0.09, 0.12, 0.7)
	sbd.border_color = Color(0.4, 0.4, 0.44, 0.5)
	comprar.add_theme_stylebox_override("normal", sbc)
	comprar.add_theme_stylebox_override("hover", sbc)
	comprar.add_theme_stylebox_override("pressed", sbc)
	comprar.add_theme_stylebox_override("disabled", sbd)
	comprar.add_theme_color_override("font_color", Color(1, 0.94, 1))
	comprar.add_theme_color_override("font_color_disabled", Color(0.5, 0.48, 0.54))
	comprar.pressed.connect(_comprar.bind(id))
	linha.add_child(comprar)

	return {"raiz": raiz, "id": id, "pips": pips, "custo": custo, "comprar": comprar, "cor": cor}


func _comprar(id: String) -> void:
	if EstadoJogo.comprar_melhoria(id):
		Som.toca("conquista", -8.0, 1.15)
	else:
		Som.toca("dano", -18.0, 0.8)


func _refrescar() -> void:
	if _ess_label:
		_ess_label.text = "✦ %d" % EstadoJogo.essencia
	for c in _cartoes:
		var id: String = c["id"]
		var rank := EstadoJogo.rank_melhoria(id)
		var mx := M.max_rank(id)
		var p := ""
		for i in mx:
			p += "●  " if i < rank else "○  "
		(c["pips"] as Label).text = p.strip_edges()
		var custo := EstadoJogo.custo_melhoria(id)
		var bt := c["comprar"] as Button
		var lc := c["custo"] as Label
		if custo < 0:
			lc.text = _t("shrine.max", "NO MÁXIMO")
			bt.disabled = true
		else:
			lc.text = "✦ %d" % custo
			bt.disabled = not EstadoJogo.pode_comprar_melhoria(id)


func _t(chave: String, fallback: String) -> String:
	var v := Textos.t(chave)
	return v if v != chave else fallback


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		accept_event()
		fechado.emit()
