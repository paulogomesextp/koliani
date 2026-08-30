class_name SeletorNiveis
extends Control
## Carrossel moderno de escolha de nível (estilo cover-flow): uma fila de
## cartões que desliza na horizontal, com o cartão do meio ampliado. Cada
## cartão mostra a região, o número (N / total), o nome do nível e o nome
## do chefe, mais o estado (concluído / trancado).
##
## Reutilizável:
##   - `MapaMundo` (modo normal): `configurar(indice, true)` -- respeita os
##     bloqueios; níveis por alcançar não entram.
##   - `DevBarra` (PAULITOS JENSATH DEV): `configurar(indice, false)` -- pode
##     saltar para qualquer nível.
##
## Sinais: `escolhido(indice)` quando se confirma um nível jogável;
## `cancelado` quando se recua (botão Voltar / ui_cancel).

signal escolhido(indice: int)
signal cancelado

## chave i18n do nome de cada região (mesmo mapa que o MapaMundo)
const WORLD_KEY := {
	"floresta": "world.forest", "prisao": "world.prison",
	"torres": "world.towers", "catacumbas": "world.catacombs",
	"cidade": "world.city", "castelo": "world.castle",
}
## cor de cada região (ordem de EstadoJogo.REGIOES) -- puxada do key art
const COR_REGIAO := [
	Color(0.46, 0.78, 0.34), Color(0.34, 0.74, 0.85),
	Color(0.96, 0.66, 0.32), Color(0.62, 0.55, 0.72),
	Color(0.82, 0.40, 0.52), Color(0.88, 0.34, 0.80),
]

const CARTAO := Vector2(336, 300)
const PASSO := 372.0          # cartão + intervalo
const DUR := 0.26

var _respeitar_bloqueio := true
var _sel := 0
var _faixa: Control
var _cartoes: Array[Dictionary] = []   # [{ raiz, indice, jogavel, nome, chefe, estado, pill }]
var _jogar: Button
var _dica: Label
var _arrastar_x := 0.0
var _arrastar_base := 0.0
var _arrastando := false
var _pronto := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_montar()
	Textos.idioma_mudou.connect(func(_l: String) -> void: _traduzir())
	resized.connect(_reposicionar.bind(true))
	get_viewport().size_changed.connect(_reposicionar.bind(true))
	call_deferred("_reposicionar", true)


## Ponto de entrada. `indice_inicial` = nível a mostrar centrado;
## `respeitar_bloqueio` = se true, só deixa confirmar níveis desbloqueados
## (modo normal) e arranca na fronteira se o índice pedido estiver trancado.
func configurar(indice_inicial: int, respeitar_bloqueio: bool) -> void:
	_respeitar_bloqueio = respeitar_bloqueio
	var alvo := clampi(indice_inicial, 0, EstadoJogo.NIVEIS.size() - 1)
	if respeitar_bloqueio and not EstadoJogo.nivel_desbloqueado(alvo):
		alvo = EstadoJogo.fronteira()
	_sel = alvo
	if _pronto:
		_reconstruir_estilos()
		_reposicionar(true)
		_traduzir()


# --- construção ----------------------------------------------------------

func _montar() -> void:
	_faixa = Control.new()
	_faixa.name = "Faixa"
	_faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_faixa)

	for i in EstadoJogo.NIVEIS.size():
		var c := _fazer_cartao(i)
		_faixa.add_child(c["raiz"])
		_cartoes.append(c)

	_montar_seta("‹", -1, true)
	_montar_seta("›", 1, false)
	_montar_rodape()
	_pronto = true
	_reconstruir_estilos()
	_reposicionar(true)
	_traduzir()


func _fazer_cartao(indice: int) -> Dictionary:
	var regiao := EstadoJogo.regiao_do_nivel(indice)
	var base: Color = COR_REGIAO[regiao] if regiao >= 0 and regiao < COR_REGIAO.size() else Color(0.6, 0.6, 0.7)

	var raiz := Control.new()
	raiz.custom_minimum_size = CARTAO
	raiz.size = CARTAO
	raiz.pivot_offset = CARTAO * 0.5
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP

	var painel := PanelContainer.new()
	painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(painel)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.12, 0.96)
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(3)
	sb.border_color = base
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 12
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	painel.add_theme_stylebox_override("panel", sb)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	painel.add_child(col)

	var faixa_reg := Label.new()
	faixa_reg.name = "Regiao"
	faixa_reg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	faixa_reg.add_theme_font_size_override("font_size", 14)
	faixa_reg.add_theme_color_override("font_color", Color(0.06, 0.04, 0.08))
	var sbr := StyleBoxFlat.new()
	sbr.bg_color = base
	sbr.set_corner_radius_all(6)
	sbr.content_margin_left = 12
	sbr.content_margin_right = 12
	sbr.content_margin_top = 3
	sbr.content_margin_bottom = 3
	faixa_reg.add_theme_stylebox_override("normal", sbr)
	col.add_child(faixa_reg)

	var num := Label.new()
	num.name = "Numero"
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.add_theme_font_size_override("font_size", 15)
	num.add_theme_color_override("font_color", base.lightened(0.15))
	col.add_child(num)

	var nome := Label.new()
	nome.name = "Nome"
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nome.custom_minimum_size = Vector2(CARTAO.x - 40, 0)
	nome.add_theme_font_size_override("font_size", 27)
	nome.add_theme_color_override("font_color", Color(0.97, 0.94, 1))
	nome.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.03))
	nome.add_theme_constant_override("outline_size", 5)
	col.add_child(nome)

	var chefe := Label.new()
	chefe.name = "Chefe"
	chefe.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chefe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chefe.custom_minimum_size = Vector2(CARTAO.x - 40, 0)
	chefe.add_theme_font_size_override("font_size", 16)
	chefe.add_theme_color_override("font_color", Color(0.86, 0.66, 0.92))
	col.add_child(chefe)

	var pill := Label.new()
	pill.name = "Pill"
	pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_theme_font_size_override("font_size", 13)
	col.add_child(pill)

	raiz.gui_input.connect(_cartao_input.bind(indice))

	return {
		"raiz": raiz, "indice": indice, "jogavel": true,
		"regiao": faixa_reg, "numero": num, "nome": nome,
		"chefe": chefe, "pill": pill, "base": base,
	}


func _montar_seta(txt: String, dir: int, esquerda: bool) -> void:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 40)
	b.add_theme_color_override("font_color", Color(0.95, 0.85, 1))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.06, 0.14, 0.85)
	sb.set_corner_radius_all(36)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.7, 0.45, 0.8, 0.8)
	for e in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(e, sb)
	b.anchor_top = 0.5
	b.anchor_bottom = 0.5
	b.offset_top = -36.0
	b.offset_bottom = 36.0
	if esquerda:
		b.anchor_left = 0.0
		b.anchor_right = 0.0
		b.offset_left = 14.0
		b.offset_right = 86.0
	else:
		b.anchor_left = 1.0
		b.anchor_right = 1.0
		b.offset_left = -86.0
		b.offset_right = -14.0
	b.pressed.connect(_mover.bind(dir))
	add_child(b)


func _montar_rodape() -> void:
	var barra := HBoxContainer.new()
	barra.anchor_left = 0.5
	barra.anchor_right = 0.5
	barra.anchor_top = 1.0
	barra.anchor_bottom = 1.0
	barra.offset_left = -170.0
	barra.offset_right = 170.0
	barra.offset_top = -86.0
	barra.offset_bottom = -42.0
	barra.alignment = BoxContainer.ALIGNMENT_CENTER
	barra.add_theme_constant_override("separation", 24)
	add_child(barra)

	var voltar := Button.new()
	voltar.name = "Voltar"
	voltar.focus_mode = Control.FOCUS_NONE
	voltar.custom_minimum_size = Vector2(150, 44)
	_estilo_botao_rodape(voltar)
	voltar.pressed.connect(func() -> void: cancelado.emit())
	barra.add_child(voltar)

	_jogar = Button.new()
	_jogar.name = "Jogar"
	_jogar.focus_mode = Control.FOCUS_NONE
	_jogar.custom_minimum_size = Vector2(150, 44)
	_estilo_botao_rodape(_jogar)
	_jogar.pressed.connect(_confirmar)
	barra.add_child(_jogar)

	_dica = Label.new()
	_dica.name = "Dica"
	_dica.anchor_left = 0.5
	_dica.anchor_right = 0.5
	_dica.anchor_top = 1.0
	_dica.anchor_bottom = 1.0
	_dica.offset_left = -380.0
	_dica.offset_right = 380.0
	_dica.offset_top = -34.0
	_dica.offset_bottom = -12.0
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dica.add_theme_font_size_override("font_size", 14)
	_dica.add_theme_color_override("font_color", Color(0.66, 0.6, 0.76, 0.75))
	add_child(_dica)


func _estilo_botao_rodape(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color(1, 0.88, 0.98))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.06, 0.16, 0.94)
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.85, 0.4, 0.82, 1)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	for e in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(e, sb)


# --- estado / layout ---------------------------------------------------

func _reconstruir_estilos() -> void:
	for c in _cartoes:
		var idx: int = c["indice"]
		var jog := (not _respeitar_bloqueio) or EstadoJogo.nivel_desbloqueado(idx)
		c["jogavel"] = jog
		var regiao := EstadoJogo.regiao_do_nivel(idx)
		var reg_id: String = EstadoJogo.REGIOES[regiao]["id"] if regiao >= 0 else "?"
		(c["regiao"] as Label).text = Textos.t(WORLD_KEY.get(reg_id, "world.unknown"))
		(c["numero"] as Label).text = Textos.tf("sel.count", [idx + 1, EstadoJogo.NIVEIS.size()])
		(c["nome"] as Label).text = _nome_nivel(idx)
		(c["chefe"] as Label).text = Textos.tf("sel.boss", [_nome_chefe(idx)])
		var pill := c["pill"] as Label
		if EstadoJogo.nivel_esta_concluido(idx):
			pill.text = Textos.t("sel.cleared")
			pill.add_theme_color_override("font_color", Color(0.6, 1, 0.7))
		elif not jog:
			pill.text = Textos.t("sel.locked")
			pill.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
		else:
			pill.text = ""


func _reposicionar(instantaneo: bool) -> void:
	if not _pronto or size.x < 200.0:
		return
	var centro := size * 0.5
	for i in _cartoes.size():
		var raiz := _cartoes[i]["raiz"] as Control
		var alvo_pos := Vector2(centro.x - CARTAO.x * 0.5 + (i - _sel) * PASSO, centro.y - CARTAO.y * 0.5)
		var dist: int = absi(i - _sel)
		var escala := 1.0
		var alpha := 1.0
		if dist == 1:
			escala = 0.84
			alpha = 0.68
		elif dist >= 2:
			escala = 0.72
			alpha = 0.0
		if not _cartoes[i]["jogavel"]:
			alpha *= 0.6
		raiz.mouse_filter = Control.MOUSE_FILTER_STOP if dist <= 1 else Control.MOUSE_FILTER_IGNORE
		if instantaneo:
			raiz.position = alvo_pos
			raiz.scale = Vector2(escala, escala)
			raiz.modulate.a = alpha
		else:
			var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			t.tween_property(raiz, "position", alvo_pos, DUR)
			t.tween_property(raiz, "scale", Vector2(escala, escala), DUR)
			t.tween_property(raiz, "modulate:a", alpha, DUR)
		raiz.z_index = 10 - dist
	if _jogar:
		_jogar.disabled = not _cartoes[_sel]["jogavel"]


func _traduzir() -> void:
	if not _pronto:
		return
	var voltar := find_child("Voltar", true, false) as Button
	if voltar:
		voltar.text = Textos.t("sel.back")
	if _jogar:
		_jogar.text = Textos.t("sel.play")
	if _dica:
		_dica.text = Textos.t("sel.hint")
	_reconstruir_estilos()


## Nome do nível: chave `level.n##` traduzida; se faltar, cai no nome do
## ficheiro da cena com underscores -> espaços.
func _nome_nivel(indice: int) -> String:
	var chave := CatalogoCampanha.chave_nivel(indice)
	var txt := Textos.t(chave)
	if txt != chave:
		return txt
	if indice >= 0 and indice < EstadoJogo.NIVEIS.size():
		return (EstadoJogo.NIVEIS[indice] as String).get_file().get_basename().replace("_", " ")
	return chave


func _nome_chefe(indice: int) -> String:
	var chave := CatalogoCampanha.chave_chefe(indice)
	return Textos.t(chave) if chave != "" else ""


# --- navegação -------------------------------------------------------

func _mover(dir: int) -> void:
	var novo := clampi(_sel + dir, 0, _cartoes.size() - 1)
	if novo == _sel:
		return
	_sel = novo
	Som.toca("apanhar", -17.0, 1.3)
	_reposicionar(false)


func _ir_para(indice: int) -> void:
	var novo := clampi(indice, 0, _cartoes.size() - 1)
	if novo == _sel:
		return
	_sel = novo
	Som.toca("apanhar", -17.0, 1.25)
	_reposicionar(false)


func _confirmar() -> void:
	var c: Dictionary = _cartoes[_sel]
	if not c["jogavel"]:
		Som.toca("dano", -18.0, 0.8)
		var raiz := c["raiz"] as Control
		var t := create_tween()
		t.tween_property(raiz, "position:x", raiz.position.x + 8, 0.04)
		t.tween_property(raiz, "position:x", raiz.position.x - 8, 0.04)
		t.tween_property(raiz, "position:x", raiz.position.x, 0.04)
		return
	Som.toca("porta", -6.0)
	escolhido.emit(c["indice"])


func _cartao_input(evento: InputEvent, indice: int) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		if indice == _cartoes[_sel]["indice"]:
			_confirmar()
		else:
			_ir_para(indice)


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed:
		match evento.button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				_mover(1)
			MOUSE_BUTTON_WHEEL_UP:
				_mover(-1)
			MOUSE_BUTTON_LEFT:
				_arrastando = true
				_arrastar_x = evento.position.x
				_arrastar_base = evento.position.x
	elif evento is InputEventMouseButton and not evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		if _arrastando:
			_arrastando = false
			var delta: float = evento.position.x - _arrastar_base
			if absf(delta) > 40.0:
				_mover(-signi(int(delta)))
	elif evento is InputEventMouseMotion and _arrastando:
		var d: float = evento.position.x - _arrastar_x
		if absf(d) > PASSO * 0.6:
			_mover(-signi(int(d)))
			_arrastar_x = evento.position.x


func _unhandled_input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento.is_action_pressed("mover_direita") or evento.is_action_pressed("ui_right"):
		_mover(1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("mover_esquerda") or evento.is_action_pressed("ui_left"):
		_mover(-1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("saltar") or evento.is_action_pressed("atacar") or evento.is_action_pressed("ui_accept"):
		_confirmar()
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("pausa") or evento.is_action_pressed("ui_cancel"):
		cancelado.emit()
		get_viewport().set_input_as_handled()
