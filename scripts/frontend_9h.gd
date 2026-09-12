class_name Frontend9H
extends RefCounted
## Kit do FRONTEND de produção (Execution 9H), derivado das pranchas
## aprovadas pelo Game Master em `work/production_art_gate/10_menu_rebrand/`
## por `tools/produzir_frontend_9h.py` -> `assets/ui/frontend_9h/`.
##
## A 9F vestiu os menus com o material da prancha 09 (ouro/ciano): era o
## que havia. A 10_menu_rebrand mudou a direção do frontend para
## **carmesim sobre carvão**, com as molduras em losango e a tipografia
## serifada do logótipo. Este kit é essa direção; o `UIProducao` fica para
## o que continua igual dentro do jogo (barras da HUD, toasts, ícones de
## habilidade).
##
## O PALCO. As pranchas são composições fechadas a 16:9: a arte e a UI
## estão presas uma à outra. Se o ecrã não for 16:9 e se esticar a arte, a
## UI sai do sítio e o logótipo deforma. Por isso todo o ecrã do frontend
## se monta dentro de `palco()`: um `AspectRatioContainer` 16:9 onde a arte
## e a UI partilham as MESMAS coordenadas de 1280x720, com a própria arte
## desfocada e escurecida a encher as barras que sobram.

const DIR := "res://assets/ui/frontend_9h/"

## Medidas do palco. São as da prancha reduzidas a 1280x720 (as pranchas
## têm 1672x941, que é 16:9); tudo o que se posiciona no frontend usa
## estas coordenadas e o `AspectRatioContainer` trata do resto.
const PALCO := Vector2(1280.0, 720.0)
const DA_PRANCHA := 1280.0 / 1672.0   ## converter uma medida da prancha

## Paleta do rebrand (carmesim sobre carvão).
const CARMESIM := Color(0.886, 0.133, 0.235)
const CARMESIM_CLARO := Color(1.0, 0.39, 0.42)
const BRASA := Color(0.62, 0.09, 0.14)
const OSSO := Color(0.992, 0.965, 0.953)      ## o branco do logótipo
const TEXTO := Color(0.88, 0.855, 0.862)
const TEXTO_APAGADO := Color(0.58, 0.545, 0.565)
const CARVAO := Color(0.043, 0.024, 0.043)
const CONTORNO := Color(0.02, 0.008, 0.016)
const VERDE_ESTADO := Color(0.42, 0.92, 0.66)

## Margens das nine-patch, em px da textura FINAL (2x). Vêm do manifesto da
## ferramenta; ficam aqui em constante para o jogo não ler JSON no arranque.
const MARGENS := {
	"placa_selecionada": [110, 26, 110, 26],
	"painel_detalhe": [70, 60, 70, 60],
	"botao_jogar": [90, 26, 90, 26],
	"aba_atual": [36, 28, 36, 28],
	"aba_bloqueada": [36, 28, 36, 28],
	"ficha_nivel": [30, 14, 30, 14],
}

static var _cache := {}
static var _tema: Theme


static func textura(nome: String) -> Texture2D:
	if _cache.has(nome):
		return _cache[nome]
	var cam := DIR + nome + ".png"
	var tex: Texture2D = load(cam) if ResourceLoader.exists(cam) else null
	_cache[nome] = tex
	return tex


## `true` quando o kit está importado.
static func disponivel() -> bool:
	return textura("fundo_menu") != null


## `margens` (opcional) substitui as margens da nine-patch. É preciso nas
## peças da HUD: um selo de 56x46 não cabe nas margens de 30 px de cada lado
## do losango, e o que se via era a peça esmagada.
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
	sb.content_margin_left = m[0] * 0.45 if conteudo.x < 0 else conteudo.x
	sb.content_margin_top = m[1] * 0.5 if conteudo.y < 0 else conteudo.y
	sb.content_margin_right = m[2] * 0.45 if conteudo.z < 0 else conteudo.z
	sb.content_margin_bottom = m[3] * 0.5 if conteudo.w < 0 else conteudo.w
	sb.modulate_color = tinta
	return sb


# --- palco -----------------------------------------------------------------

## Monta o palco 16:9 dentro de `raiz` e devolve o `Control` de 1280x720
## onde a UI se põe. `arte` é o nome do fundo ("fundo_menu"/"fundo_seletor").
##
## Estrutura: barras (arte desfocada, escura) -> AspectRatioContainer ->
## Palco(Control) -> Arte + (a UI que o chamador acrescentar).
static func palco(raiz: Control, arte: String) -> Control:
	raiz.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var tex := textura(arte)

	var chao := ColorRect.new()
	chao.name = "Chao"
	chao.color = CARVAO
	chao.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(chao)

	# as barras: a mesma arte a encher, desfocada e escura -- é o que o
	# cinema faz, e evita a barra preta morta num telemóvel 20:9
	if tex != null:
		var barras := TextureRect.new()
		barras.name = "Barras"
		barras.texture = tex
		barras.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		barras.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		barras.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		barras.mouse_filter = Control.MOUSE_FILTER_IGNORE
		barras.modulate = Color(0.30, 0.26, 0.32, 1.0)
		barras.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		raiz.add_child(barras)

	var razao := AspectRatioContainer.new()
	razao.name = "Razao"
	razao.ratio = 16.0 / 9.0
	razao.stretch_mode = AspectRatioContainer.STRETCH_FIT
	razao.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	razao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(razao)

	var p := Control.new()
	p.name = "Palco"
	p.clip_contents = true
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	razao.add_child(p)

	if tex != null:
		var a := TextureRect.new()
		a.name = "Arte"
		a.texture = tex
		a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		a.stretch_mode = TextureRect.STRETCH_SCALE
		a.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		a.mouse_filter = Control.MOUSE_FILTER_IGNORE
		a.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		p.add_child(a)
	return p


## Escala do palco em relação às coordenadas de 1280x720 (para converter
## um toque do ecrã em coordenadas do palco).
static func escala_palco(p: Control) -> float:
	return maxf(p.size.x, 1.0) / PALCO.x


## Coloca um `Control` num retângulo dado em coordenadas do palco.
static func por(no: Control, r: Rect2) -> void:
	no.set_anchors_preset(Control.PRESET_TOP_LEFT)
	no.anchor_left = r.position.x / PALCO.x
	no.anchor_top = r.position.y / PALCO.y
	no.anchor_right = r.end.x / PALCO.x
	no.anchor_bottom = r.end.y / PALCO.y
	no.offset_left = 0.0
	no.offset_top = 0.0
	no.offset_right = 0.0
	no.offset_bottom = 0.0


## Véu escuro sob uma coluna de UI. A própria prancha escurece a zona dos
## botões; aqui isso é um gradiente, e é ele que segura a legibilidade
## quando o ecrã é claro.
static func veu(de: Vector2, ate: Vector2, forca := 0.55) -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.28, 0.72, 1.0])
	g.colors = PackedColorArray([
		Color(CARVAO.r, CARVAO.g, CARVAO.b, 0.0),
		Color(CARVAO.r, CARVAO.g, CARVAO.b, forca),
		Color(CARVAO.r, CARVAO.g, CARVAO.b, forca),
		Color(CARVAO.r, CARVAO.g, CARVAO.b, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 256
	gt.height = 8
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	var tr := TextureRect.new()
	tr.name = "Veu"
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	por(tr, Rect2(de, ate - de))
	return tr


## Vinheta do palco (a prancha tem os cantos fechados).
static func vinheta() -> TextureRect:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	g.colors = PackedColorArray([
		Color(0, 0, 0, 0), Color(0, 0, 0, 0.10), Color(0.01, 0.004, 0.012, 0.78)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 256
	gt.height = 256
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.04, 0.04)
	var tr := TextureRect.new()
	tr.name = "Vinheta"
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


# --- tipografia ------------------------------------------------------------

## Rótulo de menu: letra grande, clara, com sombra funda. É assim que a
## prancha escreve "Novo Jogo" -- sem caixa à volta.
static func rotulo_menu(b: Button, tamanho := 26) -> void:
	b.add_theme_font_size_override("font_size", tamanho)
	b.add_theme_color_override("font_color", TEXTO)
	b.add_theme_color_override("font_hover_color", OSSO)
	b.add_theme_color_override("font_focus_color", OSSO)
	b.add_theme_color_override("font_pressed_color", CARMESIM_CLARO)
	b.add_theme_color_override("font_hover_pressed_color", CARMESIM_CLARO)
	b.add_theme_color_override("font_disabled_color", TEXTO_APAGADO)
	b.add_theme_color_override("font_outline_color", CONTORNO)
	b.add_theme_constant_override("outline_size", 7)
	# `flat` NAO desliga a placa: desliga o desenho da stylebox do Button.
	# Quem quiser placa (as abas, o JOGAR) repoe `flat = false` a seguir --
	# foi assim que as abas sairam invisiveis na 1.a montagem do mapa.
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	# O destaque NAO e' uma stylebox. A placa da prancha tem 144 px de alto e
	# molduras de 26 em cima e em baixo: numa nine-patch de 46 px de altura os
	# dois cantos sobrepunham-se e a placa desaparecia (visto na 2.a foto).
	# Quem a desenha e' o `realce()`, um no' so', que escorrega entre entradas.
	for estado in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
	b.mouse_filter = Control.MOUSE_FILTER_STOP


## Capitular espaçada (o "FLORESTA SAGRADA" e o "PREMIR ENTER" da prancha).
static func capitular(l: Label, tamanho := 16, cor := TEXTO_APAGADO) -> void:
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", CONTORNO)
	l.add_theme_constant_override("outline_size", 5)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


## Espaça as letras como a prancha (não há `letter_spacing` em `Label`).
static func espacar(txt: String, espacos := 1) -> String:
	var e := " ".repeat(espacos)
	var fora := PackedStringArray()
	for c in txt.to_upper():
		fora.append(c)
	return e.join(fora)


## Cabeçalho de ecrã: serifa grande, cor de osso, contorno fundo.
static func cabecalho(l: Label, tamanho := 34) -> void:
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", OSSO)
	l.add_theme_color_override("font_outline_color", CONTORNO)
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_shadow_color", Color(BRASA.r, BRASA.g, BRASA.b, 0.5))
	l.add_theme_constant_override("shadow_outline_size", 18)
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 0)


static func corpo(l: Label, tamanho := 17, cor := TEXTO) -> void:
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", CONTORNO)
	l.add_theme_constant_override("outline_size", 5)


# --- ornamentos ------------------------------------------------------------

## Separador de menu (linha com losango) esticado à largura pedida.
static func separador(nome := "separador_menu") -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = textura(nome)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return tr


## Botão COM fundo visível em repouso (barras de ferramentas, diálogos).
##
## NÃO usa a placa da prancha: a placa tem 800x144 e margens de 110 px de
## cada lado, e num botão de 90 px de largura as duas pontas em losango
## sobrepõem-se -- o que se vê são lascas da pintura (visto na 1.ª barra do
## editor de layout). A placa é a autoridade do REALCE DE MENU, e é só lá
## que faz sentido. Aqui vale a mesma paleta, em caixa lisa: carvão, fio de
## carmesim, cantos cortados.
static func botao_placa(b: Button, tamanho := 17) -> void:
	rotulo_menu(b, tamanho)
	b.flat = false
	b.add_theme_stylebox_override("normal", _caixa_lisa(0.30))
	b.add_theme_stylebox_override("hover", _caixa_lisa(0.95))
	b.add_theme_stylebox_override("focus", _caixa_lisa(0.95))
	b.add_theme_stylebox_override("pressed", _caixa_lisa(1.0, true))
	b.add_theme_stylebox_override("hover_pressed", _caixa_lisa(1.0, true))
	b.add_theme_stylebox_override("disabled", _caixa_lisa(0.14))


static func _caixa_lisa(forca: float, cheia := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(CARMESIM.r * 0.30, CARMESIM.g * 0.12, CARMESIM.b * 0.16,
		0.92 if cheia else 0.72)
	sb.border_color = Color(CARMESIM.r, CARMESIM.g, CARMESIM.b, clampf(forca, 0.0, 1.0))
	sb.set_border_width_all(1)
	sb.border_width_top = 2
	sb.set_corner_radius_all(3)
	sb.corner_radius_top_left = 0
	sb.corner_radius_bottom_right = 0
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	sb.shadow_color = Color(BRASA.r, BRASA.g, BRASA.b, 0.22 * forca)
	sb.shadow_size = int(8.0 * forca)
	return sb


## A placa da prancha como realce ÚNICO, que escorrega até à entrada com
## foco. Um nó só: não há dois destaques a discutir (rato contra comando) e
## o movimento entre entradas é a vida que o menu tinha a menos.
static func realce() -> TextureRect:
	var tr := TextureRect.new()
	tr.name = "Realce"
	tr.texture = textura("placa_selecionada")
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.set_anchors_preset(Control.PRESET_TOP_LEFT)
	return tr


static func imagem(nome: String, tinta := Color.WHITE) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = textura(nome)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.modulate = tinta
	return tr


# --- tema geral ------------------------------------------------------------

## Tema dos ecrãs do frontend: botões com a placa de losango da prancha,
## painéis com a moldura do cartão de nível.
static func tema() -> Theme:
	if _tema != null:
		return _tema
	var t := Theme.new()
	var pad := Vector4(40, 5, 40, 5)
	var vazio := StyleBoxEmpty.new()
	vazio.content_margin_left = 40
	vazio.content_margin_right = 40
	vazio.content_margin_top = 5
	vazio.content_margin_bottom = 5
	var placa := caixa("placa_selecionada", pad)
	var premido := caixa("placa_selecionada", pad, Color(1.25, 0.9, 0.95))
	t.set_stylebox("normal", "Button", vazio)
	t.set_stylebox("hover", "Button", placa)
	t.set_stylebox("focus", "Button", placa)
	t.set_stylebox("pressed", "Button", premido)
	t.set_stylebox("hover_pressed", "Button", premido)
	t.set_stylebox("disabled", "Button", vazio)
	t.set_color("font_color", "Button", TEXTO)
	t.set_color("font_hover_color", "Button", OSSO)
	t.set_color("font_focus_color", "Button", OSSO)
	t.set_color("font_pressed_color", "Button", CARMESIM_CLARO)
	t.set_color("font_disabled_color", "Button", TEXTO_APAGADO)
	t.set_color("font_outline_color", "Button", CONTORNO)
	t.set_constant("outline_size", "Button", 7)
	t.set_font_size("font_size", "Button", 22)

	var painel := caixa("painel_detalhe", Vector4(34, 28, 34, 28))
	t.set_stylebox("panel", "PanelContainer", painel)
	t.set_stylebox("panel", "Panel", painel)
	t.set_color("font_color", "Label", TEXTO)
	t.set_color("font_outline_color", "Label", CONTORNO)
	t.set_constant("outline_size", "Label", 5)

	# cursores (volume): calha fina carmesim
	var calha := StyleBoxFlat.new()
	calha.bg_color = Color(0.10, 0.05, 0.08, 0.92)
	calha.border_color = Color(CARMESIM.r, CARMESIM.g, CARMESIM.b, 0.55)
	calha.set_border_width_all(1)
	calha.set_content_margin_all(6)
	calha.set_corner_radius_all(3)
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = CARMESIM
	cheio.set_corner_radius_all(3)
	cheio.set_content_margin_all(6)
	t.set_stylebox("slider", "HSlider", calha)
	t.set_stylebox("grabber_area", "HSlider", cheio)
	t.set_stylebox("grabber_area_highlight", "HSlider", cheio)

	var sep := StyleBoxLine.new()
	sep.color = Color(CARMESIM.r, CARMESIM.g, CARMESIM.b, 0.4)
	sep.thickness = 1
	t.set_stylebox("separator", "HSeparator", sep)
	t.set_constant("separation", "HSeparator", 10)
	_tema = t
	return t


## Veste um ecrã inteiro no kit 9H (tema + limpeza dos overrides antigos).
static func vestir(raiz: Control) -> void:
	if not disponivel():
		UIProducao.vestir_ecra(raiz)
		return
	raiz.theme = tema()
	raiz.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	UIProducao.limpar_overrides(raiz)


static func _recurso() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.03, 0.05, 0.94)
	sb.set_border_width_all(2)
	sb.border_color = CARMESIM
	sb.set_content_margin_all(12)
	return sb
