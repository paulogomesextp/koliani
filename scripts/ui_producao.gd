class_name UIProducao
extends RefCounted
## Kit de UI de PRODUÇÃO (Execution 9F), derivado da prancha 09 aprovada
## por `tools/produzir_ui_9f.py` -> `assets/ui/producao_9f/`.
##
## Direção congelada: fantasia escura mínima -- grafite/preto, violeta,
## vermelho, ouro controlado. A prancha dá o material (botões com
## moldura, painel de ouro, calhas com gema, toasts, ícones); os rótulos
## são sempre dinâmicos (`Textos.t`), nunca pintados na imagem.
##
## Uso: `raiz.theme = UIProducao.tema()` num ecrã de menu põe todos os
## `Button`/`PanelContainer`/`HSlider` filhos no kit. As peças especiais
## (barras, toasts, cartões) têm funções próprias.
##
## As texturas vêm ampliadas 2x da prancha (pintura, não pixel-art):
## desenham-se com filtro LINEAR, ao contrário do resto do jogo.

const DIR := "res://assets/ui/producao_9f/"

## Paleta da prancha 09 (medida nas peças, não inventada).
const OURO := Color(0.96, 0.8, 0.46)
const OURO_CLARO := Color(1.0, 0.9, 0.62)
const CIANO := Color(0.46, 0.84, 0.94)
const TEXTO := Color(0.9, 0.92, 0.97)
const TEXTO_APAGADO := Color(0.55, 0.6, 0.7)
const CONTORNO := Color(0.02, 0.03, 0.06)

## Margens das nine-patch, em px da textura FINAL (2x). Medidas na
## ferramenta: pontas em losango dos botões, cantos das molduras.
const MARGENS := {
	"botao_normal": [18, 12, 18, 12],        # esq, cima, dir, baixo
	"botao_selecionado": [34, 16, 34, 16],
	"botao_desativado": [18, 12, 18, 12],
	"moldura_painel": [30, 30, 30, 30],
	"moldura_ornamentada": [30, 30, 30, 30],
	"caixa_dialogo": [30, 28, 30, 28],
	"toast_info": [22, 18, 22, 18],
	"toast_habilidade": [22, 18, 22, 18],
	"barra_vida_calha": [40, 12, 26, 12],
	"barra_energia_calha": [40, 12, 26, 12],
}

## Onde o enchimento corre dentro da calha (px da textura final): a gema
## ocupa a ponta esquerda, a seta a direita.
const CALHA_RECUO := {"esq": 36.0, "dir": 22.0, "cima": 9.0, "baixo": 9.0}

static var _cache := {}
static var _tema: Theme


static func textura(nome: String) -> Texture2D:
	if _cache.has(nome):
		return _cache[nome]
	var cam := DIR + nome + ".png"
	var tex: Texture2D = load(cam) if ResourceLoader.exists(cam) else null
	_cache[nome] = tex
	return tex


## `true` quando o kit está importado (fresh checkout sem `--import` não).
static func disponivel() -> bool:
	return textura("botao_normal") != null


## StyleBox nine-patch de uma peça do kit. `conteudo` = margem interior
## para o texto; `tinta` multiplica (estados apagados / realce).
## `margens` (opcional) substitui as margens da nine-patch -- para peças
## mais baixas que as margens de origem (botões de 24 px na HUD).
static func caixa(nome: String, conteudo := Vector4(-1, -1, -1, -1),
		tinta := Color.WHITE, margens: Array = []) -> StyleBox:
	var tex := textura(nome)
	if tex == null:
		return _recurso()
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	var m: Array = margens if margens.size() == 4 else MARGENS.get(nome, [16, 16, 16, 16])
	sb.texture_margin_left = m[0]
	sb.texture_margin_top = m[1]
	sb.texture_margin_right = m[2]
	sb.texture_margin_bottom = m[3]
	sb.content_margin_left = m[0] if conteudo.x < 0 else conteudo.x
	sb.content_margin_top = m[1] * 0.6 if conteudo.y < 0 else conteudo.y
	sb.content_margin_right = m[2] if conteudo.z < 0 else conteudo.z
	sb.content_margin_bottom = m[3] * 0.6 if conteudo.w < 0 else conteudo.w
	sb.modulate_color = tinta
	return sb


## O tema dos menus. Construído uma vez e partilhado.
static func tema() -> Theme:
	if _tema != null:
		return _tema
	var t := Theme.new()
	# a MESMA margem de conteúdo em todos os estados: com margens maiores no
	# ouro, o botão encolhia o texto ao ganhar foco ("Portug" em vez de
	# "Português" -- visto no Web, 9F)
	var pad := Vector4(26, 10, 26, 10)
	var normal := caixa("botao_normal", pad)
	var sel := caixa("botao_selecionado", pad)
	var premido := caixa("botao_selecionado", pad, Color(0.82, 0.78, 0.74))
	var desligado := caixa("botao_desativado", pad)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", sel)
	t.set_stylebox("hover_pressed", "Button", premido)
	t.set_stylebox("pressed", "Button", premido)
	t.set_stylebox("disabled", "Button", desligado)
	# o foco desenha POR CIMA do normal: é a moldura de ouro inteira, e é
	# ela que diz ao comando/teclado onde se está
	t.set_stylebox("focus", "Button", sel)
	t.set_color("font_color", "Button", TEXTO)
	t.set_color("font_hover_color", "Button", OURO_CLARO)
	t.set_color("font_focus_color", "Button", OURO_CLARO)
	t.set_color("font_pressed_color", "Button", OURO)
	t.set_color("font_hover_pressed_color", "Button", OURO)
	t.set_color("font_disabled_color", "Button", TEXTO_APAGADO)
	t.set_color("font_outline_color", "Button", CONTORNO)
	t.set_constant("outline_size", "Button", 4)
	t.set_font_size("font_size", "Button", 18)

	t.set_stylebox("panel", "PanelContainer", caixa("moldura_painel", Vector4(40, 34, 40, 34)))
	t.set_stylebox("panel", "Panel", caixa("moldura_painel", Vector4(40, 34, 40, 34)))

	t.set_color("font_color", "Label", TEXTO)
	t.set_color("font_outline_color", "Label", CONTORNO)
	t.set_constant("outline_size", "Label", 3)

	# cursor de volume: a calha de energia do kit, cheia com o enchimento
	var trilho := caixa("barra_energia_calha", Vector4(0, 10, 0, 10))
	var cheio := _enchimento_caixa("barra_energia_enchimento")
	t.set_stylebox("slider", "HSlider", trilho)
	t.set_stylebox("grabber_area", "HSlider", cheio)
	t.set_stylebox("grabber_area_highlight", "HSlider", cheio)

	var sep := StyleBoxLine.new()
	sep.color = Color(OURO.r, OURO.g, OURO.b, 0.35)
	sep.thickness = 1
	t.set_stylebox("separator", "HSeparator", sep)
	t.set_constant("separation", "HSeparator", 10)
	_tema = t
	return t


## Tira os overrides de estilo que os `.tscn` antigos põem nos botões,
## para o tema de produção passar a mandar. Só estilos e cores -- tamanhos
## de letra e margens de layout ficam.
static func limpar_overrides(raiz: Node) -> void:
	if raiz is PanelContainer:
		(raiz as Control).remove_theme_stylebox_override("panel")
	for n in raiz.find_children("*", "Button", true, false):
		var b := n as Button
		for e in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			b.remove_theme_stylebox_override(e)
		for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			b.remove_theme_color_override(c)
		b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	for n in raiz.find_children("*", "PanelContainer", true, false):
		(n as Control).remove_theme_stylebox_override("panel")
		(n as Control).texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	for n in raiz.find_children("*", "HSlider", true, false):
		for e in ["slider", "grabber_area", "grabber_area_highlight"]:
			(n as Control).remove_theme_stylebox_override(e)
		(n as Control).texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


## Aplica o tema a um ecrã inteiro: tema na raiz + limpeza dos overrides.
static func vestir_ecra(raiz: Control) -> void:
	if not disponivel():
		return
	raiz.theme = tema()
	raiz.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	limpar_overrides(raiz)


## Título de ecrã (PAUSE / OPTIONS / ...): ouro com contorno escuro.
static func titulo(l: Label, tamanho := 30) -> void:
	l.add_theme_color_override("font_color", OURO)
	l.add_theme_color_override("font_outline_color", CONTORNO)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_font_size_override("font_size", tamanho)


## Rótulo de secção (SOUND / LANGUAGE): o ciano das legendas da prancha.
static func seccao(l: Label, tamanho := 15) -> void:
	l.add_theme_color_override("font_color", CIANO)
	l.add_theme_font_size_override("font_size", tamanho)


# --- barras ----------------------------------------------------------------

## Veste uma `ProgressBar` com a calha de gema da prancha e o enchimento
## pintado (repetido na horizontal). `tipo` = "vida" | "energia" | "chefe".
## Mesmo método do `UI.vestir_barra` (enchimento num nó filho): uma
## `StyleBoxTexture` no "fill" desaparece conforme a altura.
static func vestir_barra(barra: ProgressBar, tipo: String) -> void:
	# Execution 9H.11: a barra do CHEFE deixa de reaproveitar a calha de ouro
	# da vida do jogador -- em combate as duas liam-se como a mesma coisa. O
	# chefe passa a ser uma lâmina carmesim sobre carvão (a linguagem do
	# frontend), sem gema e sem seta: larga, chata e de outra família.
	if tipo == "chefe":
		_vestir_barra_chefe(barra)
		return
	var base := "energia" if tipo == "energia" else "vida"
	var calha := textura("barra_%s_calha" % base)
	if calha == null:
		UI.vestir_barra(barra, UI.COR_ENERGIA if tipo == "energia" else UI.COR_VIDA)
		return
	barra.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	barra.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	barra.add_theme_stylebox_override("fill", StyleBoxEmpty.new())
	# Três pedaços com ESCALA UNIFORME (altura da barra / 44): uma nine-patch
	# desenha os cantos a 1:1 e, numa barra de 26 px, esmagava a gema.
	# Ordem de desenho: calha (meio, seta), enchimento, e a gema por cima.
	var tinta := Color(0.92, 0.8, 0.84) if tipo == "chefe" else Color.WHITE
	for peca in ["CalhaMeio", "CalhaDir"]:
		var tr := _pedaco_calha(base, peca, tinta)
		barra.add_child(tr)
	var ench := TextureRect.new()
	ench.name = "Enchimento"
	ench.texture = textura("barra_%s_enchimento" % base)
	ench.stretch_mode = TextureRect.STRETCH_TILE
	ench.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ench.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ench.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ench.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tipo == "chefe":
		ench.modulate = Color(0.78, 0.5, 0.55)   # sangue mais escuro que a vida
	barra.add_child(ench)
	barra.add_child(_pedaco_calha(base, "CalhaEsq", tinta))
	barra.value_changed.connect(func(_v: float) -> void: ajustar_barra(barra))
	barra.resized.connect(func() -> void: ajustar_barra(barra))
	ajustar_barra(barra)


## Largura (px da textura) da gema à esquerda e da seta à direita.
const CALHA_ESQ := 40.0
const CALHA_DIR := 26.0
const CALHA_ALT := 44.0


static func _pedaco_calha(base: String, nome: String, tinta: Color) -> TextureRect:
	var calha := textura("barra_%s_calha" % base)
	var a := AtlasTexture.new()
	a.atlas = calha
	var w := float(calha.get_width())
	match nome:
		"CalhaEsq":
			a.region = Rect2(0, 0, CALHA_ESQ, CALHA_ALT)
		"CalhaDir":
			a.region = Rect2(w - CALHA_DIR, 0, CALHA_DIR, CALHA_ALT)
		_:
			a.region = Rect2(CALHA_ESQ, 0, w - CALHA_ESQ - CALHA_DIR, CALHA_ALT)
	var tr := TextureRect.new()
	tr.name = nome
	tr.texture = a
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.modulate = tinta
	return tr


static func ajustar_barra(barra: ProgressBar) -> void:
	var ench := barra.get_node_or_null("Enchimento") as Control
	if ench == null:
		return
	var h := barra.size.y
	var k := maxf(h, 1.0) / CALHA_ALT
	var esq := CALHA_ESQ * k
	var dir := CALHA_DIR * k
	var meio := maxf(barra.size.x - esq - dir, 0.0)
	var n_esq := barra.get_node_or_null("CalhaEsq") as Control
	var n_meio := barra.get_node_or_null("CalhaMeio") as Control
	var n_dir := barra.get_node_or_null("CalhaDir") as Control
	if n_esq:
		n_esq.position = Vector2.ZERO
		n_esq.size = Vector2(esq, h)
	if n_meio:
		n_meio.position = Vector2(esq, 0)
		n_meio.size = Vector2(meio, h)
	if n_dir:
		n_dir.position = Vector2(esq + meio, 0)
		n_dir.size = Vector2(dir, h)
	# o enchimento corre por dentro da calha: começa sob a gema (que o tapa)
	var x0 := esq * 0.72
	var util := maxf(barra.size.x - x0 - CALHA_RECUO["dir"] * k, 0.0)
	var cima := CALHA_RECUO["cima"] * k
	ench.position = Vector2(x0, cima)
	ench.size = Vector2(roundf(util * barra.get_as_ratio()), maxf(h - cima * 2.0, 0.0))


static func _enchimento_caixa(nome: String) -> StyleBox:
	var tex := textura(nome)
	if tex == null:
		return _recurso()
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 6
	sb.texture_margin_right = 6
	sb.texture_margin_top = 6
	sb.texture_margin_bottom = 6
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


# --- ícones / toasts -------------------------------------------------------

static func icone(nome: String, altura: float, tinta := Color.WHITE) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = textura(nome)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.modulate = tinta
	var larg := altura
	if tr.texture:
		larg = altura * tr.texture.get_width() / float(tr.texture.get_height())
	tr.custom_minimum_size = Vector2(roundf(larg), altura)
	return tr


## Ícone de ladrilho de cada habilidade (prancha 09, secção 3). Habilidades
## sem ícone na prancha devolvem "" -- o toast fica só com o texto.
const ICONE_HABILIDADE := {
	"dash": "ico_dash",
	"salto_duplo": "ico_salto_duplo",
	"escudo": "ico_escudo",
	"projetil": "ico_ataque_especial",
	"kamehameha": "ico_ataque_especial",
}


## Toast de feedback (secção 8 da prancha): moldura + ícone opcional +
## texto dinâmico. `estilo` = "info" (azul) | "habilidade" (violeta).
static func toast(txt: String, icone_nome := "", estilo := "info") -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	p.add_theme_stylebox_override("panel", caixa("toast_" + estilo, Vector4(22, 12, 28, 12)))
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 14)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(linha)
	if icone_nome != "" and textura(icone_nome) != null:
		linha.add_child(icone(icone_nome, 40.0))
	var l := Label.new()
	l.text = txt
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 19)
	l.add_theme_color_override("font_color", OURO_CLARO if estilo == "habilidade" else TEXTO)
	l.add_theme_color_override("font_outline_color", CONTORNO)
	l.add_theme_constant_override("outline_size", 4)
	linha.add_child(l)
	return p


static func _recurso() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.11, 0.94)
	sb.set_border_width_all(2)
	sb.border_color = OURO
	sb.set_content_margin_all(12)
	return sb


## Barra do chefe: carvão + fio carmesim + enchimento em brasa. Não tem
## filhos (`Enchimento`/`Calha*`), por isso `ajustar_barra` ignora-a.
static func _vestir_barra_chefe(barra: ProgressBar) -> void:
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.05, 0.028, 0.043, 0.94)
	fundo.set_border_width_all(2)
	fundo.border_color = Color(0.886, 0.133, 0.235, 0.55)
	fundo.border_width_bottom = 3
	fundo.set_corner_radius_all(2)
	fundo.shadow_color = Color(0.02, 0.008, 0.016, 0.8)
	fundo.shadow_size = 6
	var ench := StyleBoxFlat.new()
	ench.bg_color = Color(0.72, 0.10, 0.17, 0.98)
	ench.set_corner_radius_all(1)
	ench.set_border_width_all(0)
	ench.border_width_top = 2
	ench.border_color = Color(1.0, 0.39, 0.42, 0.85)
	ench.set_expand_margin_all(-3.0)
	barra.add_theme_stylebox_override("background", fundo)
	barra.add_theme_stylebox_override("fill", ench)
