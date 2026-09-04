class_name UI
extends RefCounted
## Fábrica das peças de INTERFACE em pixel-art (`assets/ui/`).
##
## A HUD era toda `StyleBoxFlat` desenhada por código -- rectângulos lisos
## com um bordo de 1 px, que ao pé do jogo (pixel-art, luar, magenta) lia-se
## como um protótipo. As peças vêm agora do kit de HUD do pack anokolisa,
## recolorido para a paleta gótica por `tools/gerar_ui.py`.
##
## Aqui só se montam `StyleBoxTexture`/`TextureRect` a partir desses PNG.
## Sem lógica de jogo e sem autoloads: quem quiser uma caixa de pedra pede
## `UI.painel()` e mete-a no `theme_override_styles`.
##
## Regra do 3x: a arte já sai da ferramenta ampliada 3x (NEAREST), porque
## uma `NinePatchRect` não escala os cantos -- a 1x a moldura desaparecia
## num ecrã de 720. Por isso as margens daqui também são em px DA ARTE
## FINAL (já multiplicadas), não em px da folha original.

const DIR := "res://assets/ui/"

## a ferramenta amplia tudo 3x; as margens abaixo já contam com isso
const ESCALA := 3
## moldura da nine-patch dos painéis grandes (10 px na folha original)
const MARGEM_PAINEL := 10 * ESCALA
## moldura do selo 16x16 (5 px na folha original)
const MARGEM_SELO := 5 * ESCALA

## Altura MÁXIMA de uma barra. O enchimento tem 16 px de arte (48 na final)
## e uma `StyleBoxTexture` esticada para além da altura da sua textura não
## desenha nada -- a barra de Vida ficava vazia. Acima disto, gerar arte
## mais alta em `tools/gerar_ui.py` em vez de subir este número.
const ALTURA_MAX_BARRA := 16 * ESCALA

## Cores das barras (o enchimento é branco -- a cor entra por `modulate`).
const COR_VIDA := Color(0.86, 0.16, 0.22)
const COR_ENERGIA := Color(0.62, 0.34, 1.0)
const COR_CHEFE := Color(0.72, 0.08, 0.12)

## Cache: um `Texture2D` por ficheiro, para não voltar ao disco a cada HUD.
static var _cache := {}


## Textura de `assets/ui/<nome>.png` (ou `null` se a ferramenta não correu).
static func textura(nome: String) -> Texture2D:
	if _cache.has(nome):
		return _cache[nome]
	var caminho := DIR + nome + ".png"
	var tex: Texture2D = load(caminho) if ResourceLoader.exists(caminho) else null
	_cache[nome] = tex
	return tex


## Caixa de pedra (nine-patch). `tinta` multiplica-se por cima -- serve para
## escurecer a mesma placa sem gerar outro PNG.
static func painel(nome := "painel_pedra", tinta := Color.WHITE,
		margem_conteudo := 10.0) -> StyleBox:
	var tex := textura(nome)
	if tex == null:
		return _recurso(tinta)
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	var m: float = MARGEM_SELO if nome == "selo" else MARGEM_PAINEL
	sb.texture_margin_left = m
	sb.texture_margin_right = m
	sb.texture_margin_top = m
	sb.texture_margin_bottom = m
	sb.modulate_color = tinta
	sb.set_content_margin_all(margem_conteudo)
	return sb


## Calha (o buraco escuro por onde a barra corre).
static func calha() -> StyleBox:
	return painel("calha", Color.WHITE, 0.0)


## Veste uma `ProgressBar` com a calha escura e o enchimento de pixel-art.
##
## GOTCHA que custou uma tarde: o enchimento **não** é a stylebox "fill".
## Com uma `StyleBoxTexture` no "fill", a barra ficava EM BRANCO conforme a
## altura -- a de Energia (18 px) desenhava, a de Vida (26 px) não desenhava
## nada, nem em `STRETCH` nem em `TILE`, e uma `StyleBoxFlat` no mesmo sítio
## desenhava sempre. Aqui o enchimento é um `NinePatchRect` FILHO, que esta
## classe redimensiona: um nó real desenha-se igual em qualquer tamanho, e
## ainda dá para lhe mexer depois (piscar, mudar de cor).
##
## O padrão do enchimento REPETE-SE na horizontal em vez de esticar: a 24 px
## de largura, esticado para 280, o risco de brilho virava três traços
## gigantes.
static func vestir_barra(barra: ProgressBar, cor: Color) -> void:
	barra.add_theme_stylebox_override("background", calha())
	barra.add_theme_stylebox_override("fill", StyleBoxEmpty.new())
	var tex := textura("enchimento")
	if tex == null:
		barra.add_theme_stylebox_override("fill", _recurso(cor))
		return
	var ench := NinePatchRect.new()
	ench.name = "Enchimento"
	ench.texture = tex
	ench.patch_margin_top = 2 * ESCALA     # aresta viva + risco de brilho
	ench.patch_margin_bottom = 2 * ESCALA  # sombra de baixo
	ench.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	ench.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ench.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ench.modulate = cor
	barra.add_child(ench)
	barra.value_changed.connect(func(_v: float) -> void: ajustar_barra(barra))
	barra.resized.connect(func() -> void: ajustar_barra(barra))
	ajustar_barra(barra)


## Recuo do enchimento dentro da calha: a barra cheia deixa sempre ver a
## moldura de pedra à volta, em vez de a tapar e parecer um rectângulo solto.
const RECUO_BARRA := 3.0


## Põe o enchimento à medida do valor da barra. Chamar depois de mexer em
## `max_value` -- só o `value` é que avisa sozinho.
static func ajustar_barra(barra: ProgressBar) -> void:
	var ench := barra.get_node_or_null("Enchimento") as Control
	if ench == null:
		return
	var util := barra.size - Vector2(RECUO_BARRA, RECUO_BARRA) * 2.0
	ench.position = Vector2(RECUO_BARRA, RECUO_BARRA)
	ench.size = Vector2(roundf(maxf(util.x, 0.0) * barra.get_as_ratio()),
		maxf(util.y, 0.0))


## `TextureRect` com um ícone de `assets/ui/`, à `altura` pedida (mantém a
## proporção e fica nos píxeis inteiros -- nada de meio pixel).
static func icone(nome: String, altura: float, tinta := Color.WHITE) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = textura(nome)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.modulate = tinta
	var larg := altura
	if tr.texture:
		larg = altura * tr.texture.get_width() / float(tr.texture.get_height())
	tr.custom_minimum_size = Vector2(roundf(larg), altura)
	return tr


## Recurso para quando `assets/ui/` ainda não foi gerado (ou num teste
## headless sem importar): a caixa lisa de sempre, para nada rebentar.
static func _recurso(cor: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(cor.r * 0.5, cor.g * 0.5, cor.b * 0.5, 0.9)
	sb.set_corner_radius_all(3)
	sb.set_border_width_all(1)
	sb.border_color = cor
	return sb
