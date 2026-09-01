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
##   - `DevBarra` (DEVELOPER MODE): `configurar(indice, false)` -- pode
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
## arte de fundo por região (o `back.png` do bioma) -- preview no cartão.
const FUNDO_REGIAO := [
	"res://assets/sprites/pixel/backgrounds/floresta/middle.png",
	"res://assets/sprites/pixel/backgrounds/corredores/middle.png",
	"res://assets/sprites/pixel/backgrounds/montanhas/trees.png",
	"res://assets/sprites/pixel/backgrounds/rochoso/middle.png",
	"res://assets/sprites/pixel/backgrounds/corredores/near.png",
	"res://assets/sprites/pixel/backgrounds/rochoso/near.png",
]

## Nome do ficheiro do retrato do chefe (assets/sprites/pixel/bosses/<x>.png,
## tira de 4 frames -- usa-se o frame 0) por índice de nível. "" = ainda sem
## pixel-art (fica só com o preview do bioma).
const RETRATO_CHEFE := [
	"ghorak", "morvanna", "rainha", "entrevane", "coracao",
	"", "ignivar", "dama", "irmaos", "primeiro",
	"sino", "aerion", "voltaris", "sacerdotisa", "vyrak",
	"rei_ossario", "colosso", "freira", "naga", "olho",
	"prefeito", "acougueiro", "maquinista", "bispo", "noiva",
	"capitao", "koliani_sombria", "devorador", "arauto", "zeriko",
]

const CARTAO := Vector2(336, 392)
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

## Barra de progresso da campanha + pastilhas de região (atalho de zona) --
## construídas em `_montar_topo`, atualizadas em `_reconstruir_estilos`.
var _prog_fill: ColorRect
var _prog_label: Label
var _regiao_pills: Array[Button] = []


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
	_montar_topo()
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
	raiz.clip_contents = true

	# preview: arte do bioma da região, esbatida e tingida com a cor da região
	if regiao >= 0 and regiao < FUNDO_REGIAO.size() and ResourceLoader.exists(FUNDO_REGIAO[regiao]):
		var arte := TextureRect.new()
		arte.texture = load(FUNDO_REGIAO[regiao])
		arte.set_anchors_preset(Control.PRESET_FULL_RECT)
		arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arte.modulate = Color(base.r * 0.5, base.g * 0.5, base.b * 0.5, 0.4)
		raiz.add_child(arte)

	var painel := PanelContainer.new()
	painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(painel)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.12, 0.6)
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(2)
	sb.border_color = Color(base.r, base.g, base.b, 0.55)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 10
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18

	# estilo do cartão em destaque (o do meio, selecionado) -- borda mais
	# viva, fundo mais saturado e glow colorido em vez da sombra neutra.
	var sb_sel := sb.duplicate() as StyleBoxFlat
	sb_sel.bg_color = Color(0.1, 0.07, 0.15, 0.8).lerp(base, 0.14)
	sb_sel.set_border_width_all(3)
	sb_sel.border_color = base.lightened(0.2)
	sb_sel.shadow_color = Color(base.r, base.g, base.b, 0.55)
	sb_sel.shadow_size = 26
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

	var retrato_tex := _retrato_chefe(indice)
	if retrato_tex:
		var retrato := TextureRect.new()
		retrato.name = "Retrato"
		retrato.texture = retrato_tex
		retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		retrato.custom_minimum_size = Vector2(120, 120)
		retrato.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		col.add_child(retrato)

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

	var premio := Label.new()
	premio.name = "Premio"
	premio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	premio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	premio.custom_minimum_size = Vector2(CARTAO.x - 40, 0)
	premio.add_theme_font_size_override("font_size", 13)
	premio.add_theme_color_override("font_color", Color(0.98, 0.86, 0.55))
	col.add_child(premio)

	var pill := Label.new()
	pill.name = "Pill"
	pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_theme_font_size_override("font_size", 13)
	col.add_child(pill)

	raiz.gui_input.connect(_cartao_input.bind(indice))

	return {
		"raiz": raiz, "indice": indice, "jogavel": true,
		"regiao": faixa_reg, "numero": num, "nome": nome,
		"chefe": chefe, "premio": premio, "pill": pill, "base": base,
		"painel": painel, "sb_normal": sb, "sb_sel": sb_sel, "em_destaque": false,
	}


## Frame 0 (repouso) da tira pixel-art de 4 frames do chefe do nível
## `indice`, ou null se ainda não houver retrato pixel-art para ele.
func _retrato_chefe(indice: int) -> Texture2D:
	if indice < 0 or indice >= RETRATO_CHEFE.size():
		return null
	var slug: String = RETRATO_CHEFE[indice]
	if slug == "":
		return null
	var caminho := "res://assets/sprites/pixel/bosses/%s.png" % slug
	if not ResourceLoader.exists(caminho):
		return null
	var folha: Texture2D = load(caminho)
	var atlas := AtlasTexture.new()
	atlas.atlas = folha
	atlas.region = Rect2(0, 0, folha.get_width() / 4.0, folha.get_height())
	return atlas


func _montar_seta(txt: String, dir: int, esquerda: bool) -> void:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 40)
	b.add_theme_color_override("font_color", Color(0.97, 0.9, 1))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.06, 0.14, 0.85)
	sb.set_corner_radius_all(36)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.7, 0.45, 0.8, 0.75)
	sb.shadow_color = Color(0.6, 0.3, 0.7, 0.25)
	sb.shadow_size = 6
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.24, 0.12, 0.28, 0.95)
	sb_hover.border_color = Color(0.95, 0.55, 0.92, 1)
	sb_hover.shadow_color = Color(0.9, 0.4, 0.85, 0.5)
	sb_hover.shadow_size = 14
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb_hover)
	b.add_theme_stylebox_override("pressed", sb_hover)
	b.add_theme_stylebox_override("focus", sb_hover)
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
	b.pivot_offset = Vector2(36, 36)
	b.mouse_entered.connect(func() -> void: _animar_escala(b, 1.1))
	b.mouse_exited.connect(func() -> void: _animar_escala(b, 1.0))
	b.pressed.connect(_mover.bind(dir))
	add_child(b)


func _animar_escala(no: Control, alvo: float) -> void:
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(no, "scale", Vector2(alvo, alvo), 0.15)


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
	_estilo_botao_rodape(voltar, false)
	voltar.pressed.connect(func() -> void: cancelado.emit())
	barra.add_child(voltar)

	_jogar = Button.new()
	_jogar.name = "Jogar"
	_jogar.focus_mode = Control.FOCUS_NONE
	_jogar.custom_minimum_size = Vector2(150, 44)
	_estilo_botao_rodape(_jogar, true)
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


## Cabeçalho moderno por cima do carrossel: pastilhas de região (atalho de
## zona -- salta logo para lá em vez de percorrer nível a nível) + barra
## fina com o progresso total da campanha.
func _montar_topo() -> void:
	var pastilhas := HBoxContainer.new()
	pastilhas.name = "Pastilhas"
	pastilhas.anchor_left = 0.5
	pastilhas.anchor_right = 0.5
	pastilhas.anchor_top = 0.0
	pastilhas.anchor_bottom = 0.0
	pastilhas.offset_top = 84.0
	pastilhas.offset_bottom = 114.0
	pastilhas.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pastilhas.alignment = BoxContainer.ALIGNMENT_CENTER
	pastilhas.add_theme_constant_override("separation", 8)
	pastilhas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pastilhas)

	for r in EstadoJogo.REGIOES.size():
		var cor: Color = COR_REGIAO[r] if r < COR_REGIAO.size() else Color(0.7, 0.7, 0.7)
		var b := Button.new()
		b.name = "Regiao%d" % r
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(30, 30)
		b.text = "%d" % (r + 1)
		b.add_theme_font_size_override("font_size", 13)
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(cor.r, cor.g, cor.b, 0.22)
		sb.set_corner_radius_all(15)
		sb.set_border_width_all(2)
		sb.border_color = Color(cor.r, cor.g, cor.b, 0.55)
		var sb_ativa := sb.duplicate() as StyleBoxFlat
		sb_ativa.bg_color = cor
		sb_ativa.border_color = cor.lightened(0.3)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb_ativa)
		b.add_theme_stylebox_override("pressed", sb_ativa)
		b.add_theme_stylebox_override("focus", sb)
		b.set_meta("sb_normal", sb)
		b.set_meta("sb_ativa", sb_ativa)
		b.pressed.connect(_ir_para_regiao.bind(r))
		pastilhas.add_child(b)
		_regiao_pills.append(b)

	var faixa_prog := Control.new()
	faixa_prog.name = "Progresso"
	faixa_prog.anchor_left = 0.5
	faixa_prog.anchor_right = 0.5
	faixa_prog.anchor_top = 0.0
	faixa_prog.anchor_bottom = 0.0
	faixa_prog.offset_left = -110.0
	faixa_prog.offset_right = 110.0
	faixa_prog.offset_top = 122.0
	faixa_prog.offset_bottom = 132.0
	faixa_prog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(faixa_prog)

	var trilho := ColorRect.new()
	trilho.color = Color(1, 1, 1, 0.12)
	trilho.set_anchors_preset(Control.PRESET_FULL_RECT)
	faixa_prog.add_child(trilho)

	_prog_fill = ColorRect.new()
	_prog_fill.color = Color(0.95, 0.5, 0.92, 0.9)
	_prog_fill.anchor_top = 0.0
	_prog_fill.anchor_bottom = 1.0
	_prog_fill.anchor_left = 0.0
	_prog_fill.anchor_right = 0.0
	faixa_prog.add_child(_prog_fill)

	_prog_label = Label.new()
	_prog_label.anchor_left = 0.5
	_prog_label.anchor_right = 0.5
	_prog_label.anchor_top = 0.0
	_prog_label.anchor_bottom = 0.0
	_prog_label.offset_left = -80.0
	_prog_label.offset_right = 80.0
	_prog_label.offset_top = 136.0
	_prog_label.offset_bottom = 152.0
	_prog_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prog_label.add_theme_font_size_override("font_size", 12)
	_prog_label.add_theme_color_override("font_color", Color(0.8, 0.76, 0.86, 0.85))
	_prog_label.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.03))
	_prog_label.add_theme_constant_override("outline_size", 3)
	add_child(_prog_label)


## Pastilha de região premida -- salta para o 1.º nível alcançável dessa
## região (ou o 1.º da região, em modo dev / sem bloqueios).
func _ir_para_regiao(regiao: int) -> void:
	if regiao < 0 or regiao >= EstadoJogo.REGIOES.size():
		return
	var niveis: Array = EstadoJogo.REGIOES[regiao]["niveis"]
	if niveis.is_empty():
		return
	var alvo: int = niveis[0]
	if _respeitar_bloqueio:
		for n in niveis:
			if EstadoJogo.nivel_desbloqueado(n):
				alvo = n
	Som.toca("apanhar", -17.0, 1.2)
	_ir_para(alvo)


func _estilo_botao_rodape(b: Button, principal: bool) -> void:
	b.add_theme_font_size_override("font_size", 16 if not principal else 17)
	b.add_theme_color_override("font_color", Color(1, 0.9, 1))
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	if principal:
		sb.bg_color = Color(0.2, 0.08, 0.24, 0.96)
		sb.set_border_width_all(2)
		sb.border_color = Color(0.95, 0.5, 0.92, 0.95)
		sb.shadow_color = Color(0.85, 0.35, 0.85, 0.4)
		sb.shadow_size = 12
	else:
		sb.bg_color = Color(0.1, 0.07, 0.13, 0.85)
		sb.set_border_width_all(1)
		sb.border_color = Color(0.6, 0.45, 0.62, 0.6)
	var sb_hover := sb.duplicate() as StyleBoxFlat
	if principal:
		sb_hover.bg_color = Color(0.32, 0.13, 0.36, 1)
		sb_hover.shadow_size = 20
	else:
		sb_hover.bg_color = Color(0.2, 0.13, 0.24, 0.95)
		sb_hover.border_color = Color(0.9, 0.55, 0.88, 0.9)
	for e in ["normal", "focus", "disabled"]:
		b.add_theme_stylebox_override(e, sb)
	for e in ["hover", "pressed"]:
		b.add_theme_stylebox_override(e, sb_hover)
	b.pivot_offset = b.custom_minimum_size / 2.0
	b.mouse_entered.connect(func() -> void: _animar_escala(b, 1.05))
	b.mouse_exited.connect(func() -> void: _animar_escala(b, 1.0))


# --- estado / layout ---------------------------------------------------

func _reconstruir_estilos() -> void:
	for c in _cartoes:
		var idx: int = c["indice"]
		var jog := (not _respeitar_bloqueio) or EstadoJogo.nivel_desbloqueado(idx)
		c["jogavel"] = jog
		var regiao := EstadoJogo.regiao_do_nivel(idx)
		var reg_id: String = EstadoJogo.REGIOES[regiao]["id"] if regiao >= 0 else "?"
		var nome_regiao := Textos.t(WORLD_KEY.get(reg_id, "world.unknown"))
		(c["regiao"] as Label).text = "%s  ·  %s" % [nome_regiao, _progresso_regiao(regiao)]
		(c["numero"] as Label).text = Textos.tf("sel.count", [idx + 1, EstadoJogo.NIVEIS.size()])
		(c["nome"] as Label).text = _nome_nivel(idx)
		(c["chefe"] as Label).text = Textos.tf("sel.boss", [_nome_chefe(idx)])
		(c["premio"] as Label).text = _texto_premio(idx)
		var pill := c["pill"] as Label
		if EstadoJogo.nivel_esta_concluido(idx):
			pill.text = Textos.t("sel.cleared")
			_estilo_pill(pill, Color(0.4, 0.85, 0.5))
		elif not jog:
			pill.text = Textos.t("sel.locked")
			_estilo_pill(pill, Color(0.85, 0.4, 0.42))
		else:
			pill.text = ""
			pill.remove_theme_stylebox_override("normal")
	_atualizar_topo()


## Atualiza a barra de progresso total + a pastilha de região em destaque
## (a do nível selecionado no carrossel).
func _atualizar_topo() -> void:
	var total := EstadoJogo.NIVEIS.size()
	var feitos := 0
	for i in total:
		if EstadoJogo.nivel_esta_concluido(i):
			feitos += 1
	if _prog_fill:
		_prog_fill.anchor_right = clampf(float(feitos) / maxf(1.0, float(total)), 0.0, 1.0)
	if _prog_label:
		_prog_label.text = Textos.tf("sel.count", [feitos, total])
	var regiao_atual := EstadoJogo.regiao_do_nivel(_sel)
	for r in _regiao_pills.size():
		var b := _regiao_pills[r]
		var ativa := r == regiao_atual
		b.add_theme_stylebox_override("normal", b.get_meta("sb_ativa") if ativa else b.get_meta("sb_normal"))


## "2 / 5" -- quantos níveis da região já estão concluídos, sobre o total.
func _progresso_regiao(regiao: int) -> String:
	if regiao < 0 or regiao >= EstadoJogo.REGIOES.size():
		return ""
	var niveis: Array = EstadoJogo.REGIOES[regiao]["niveis"]
	var feitos := 0
	for n in niveis:
		if EstadoJogo.nivel_esta_concluido(n):
			feitos += 1
	return "%d / %d" % [feitos, niveis.size()]


## Dá ao "Cleared" / "Locked" um fundo em badge em vez de só texto colorido.
func _estilo_pill(pill: Label, cor: Color) -> void:
	pill.add_theme_color_override("font_color", Color(0.05, 0.04, 0.06))
	var sb := StyleBoxFlat.new()
	sb.bg_color = cor
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	pill.add_theme_stylebox_override("normal", sb)


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
		var destaque := dist == 0
		if destaque != _cartoes[i]["em_destaque"]:
			_cartoes[i]["em_destaque"] = destaque
			var painel := _cartoes[i]["painel"] as PanelContainer
			painel.add_theme_stylebox_override("panel", _cartoes[i]["sb_sel"] if destaque else _cartoes[i]["sb_normal"])
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


## "Prémio: 🗡 Foice do Pântano" -- a arma/armadura que se ganha ao acabar
## este nível.
func _texto_premio(indice: int) -> String:
	var r: Dictionary = Equipamento.recompensa_do_nivel(indice)
	if r.is_empty():
		return ""
	var it: Dictionary = Equipamento.arma(r["id"]) if r["tipo"] == "arma" else Equipamento.armadura(r["id"])
	var icone := "🗡" if r["tipo"] == "arma" else "🛡"
	return Textos.tf("sel.reward", ["%s %s" % [icone, Textos.t(it.get("nome", ""))]])


# --- navegação -------------------------------------------------------

func _mover(dir: int) -> void:
	var novo := clampi(_sel + dir, 0, _cartoes.size() - 1)
	if novo == _sel:
		return
	_sel = novo
	Som.toca("apanhar", -17.0, 1.3)
	_reposicionar(false)
	_atualizar_topo()


func _ir_para(indice: int) -> void:
	var novo := clampi(indice, 0, _cartoes.size() - 1)
	if novo == _sel:
		return
	_sel = novo
	Som.toca("apanhar", -17.0, 1.25)
	_reposicionar(false)
	_atualizar_topo()


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
	# `visible` sozinho não chega: dentro da DevBarra o painel-pai está
	# escondido mas este nó continua com visible=true -> J/atacar trocava
	# de nível com o painel fechado.
	if not is_visible_in_tree():
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
