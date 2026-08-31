extends Node2D
## Montagem de ambiente reutilizável -- a "profundidade tipo Dead Cells".
## Junta, num só nó instanciável:
##   - `Modulacao` (CanvasModulate, tom do bioma)
##   - `Parallax` com 4 camadas de silhuetas GERADAS por código a partir do
##     `bioma` (fundo -> primeiro plano), para o cenário nunca ficar vazio
##   - `Raios` -- feixes de luz volumétrica (Polygon2D aditivos)
##   - `Poeira` -- partículas de ambiente que seguem a câmara
##   - `Vinheta` + `Grade` (vinheta radial + shader de contraste/sat/bloom)
##
## Cada mundo instancia `scenes/fx/Atmosfera.tscn` e afina cor + `bioma`
## pelos `@export`. Os `ColorRect`/`Polygon2D` estáticos que a cena traz são
## placeholders -- o gerador substitui-os.

@export var cor_ambiente := Color(0.6, 0.6, 0.66)
@export var cor_fundo := Color(0.05, 0.06, 0.09)
@export var cor_silhueta := Color(0.1, 0.12, 0.17)
@export var cor_luz := Color(0.6, 0.7, 0.95)
@export var cor_poeira := Color(0.8, 0.9, 1.0)
@export_range(0.0, 3.0) var densidade_poeira := 1.0
## Forma das silhuetas: floresta | prisao | torres | catacumbas | cidade |
## castelo. Qualquer outro valor cai em "floresta".
@export var bioma := "floresta"
## Nome de uma pasta em `assets/sprites/pixel/backgrounds/` (packs CC0
## Ansimuz). Se preenchido, o fundo passam a ser as CAMADAS pixel-art desse
## pack em vez das silhuetas geradas por código. Ver `PACKS`.
@export var fundo_pack := ""
## Até onde gerar cenário de fundo (o nível mais largo anda pelos ~3400).
@export var largura_nivel := 3400.0
## Até onde gerar cenário de fundo para a ESQUERDA (x negativo). A JORNADA de
## aproximação (gerador_corredor.gd) pode começar dezenas de milhares de
## pixels antes da área "clássica" do nível -- sem isto o fundo só cobre a
## margem original e a jornada fica vazia (preta).
@export var extensao_esquerda := -1400.0
@export var seed_ambiente := 0
## Faixa de brilho quente no horizonte + pontos de luz a tremeluzir nas
## ruínas (tochas ao longe). Ligar em biomas com fogo/lava (Fornalha).
@export var luzes_horizonte := false

const CHAO := 900.0  # base das silhuetas, bem abaixo do chão jogável

const BG_DIR := "res://assets/sprites/pixel/backgrounds"

## Packs de fundo pixel-art (Ansimuz, CC0). Cada entrada:
##   [ficheiro, camada_parallax, y_da_base(px), escala]
## camada: "Fundo" (mais lenta) -> "Longe" -> "Meio" -> "Perto" (mais rápida)
const PACKS := {
	"floresta": [
		["back.png", "Fundo", 900.0, 3.8],
		["middle.png", "Longe", 1180.0, 3.6],
		["front.png", "Meio", 1250.0, 3.8],
	],
	"pantano": [
		["back.png", "Fundo", 900.0, 4.0],
		["mid1.png", "Longe", 890.0, 3.6],
		["mid2.png", "Meio", 905.0, 3.6],
		["trees.png", "Perto", 950.0, 3.8],
	],
	"corredores": [
		["back.png", "Fundo", 860.0, 4.2],
		["far.png", "Longe", 870.0, 4.2],
		["middle.png", "Meio", 885.0, 4.2],
		["near.png", "Perto", 915.0, 4.2],
	],
	# Região II -- Prisão dos Condenados (ansimuz "Cold Corridors", CC0).
	"prisao": [
		["back.png", "Fundo", 900.0, 4.4],
		["far.png", "Longe", 915.0, 4.4],
		["middle.png", "Meio", 940.0, 4.2],
		["near.png", "Perto", 980.0, 4.0],
	],
	# Região IV -- Catacumbas do Abismo (ansimuz "Caverns", CC0).
	"caverna": [
		["background.png", "Fundo", 940.0, 4.6],
		["back-walls.png", "Longe", 980.0, 3.4],
		["back-walls.png", "Meio", 1080.0, 2.6],
	],
	"rochoso": [
		["back.png", "Fundo", 850.0, 3.8],
		["middle.png", "Meio", 895.0, 4.0],
		["near.png", "Perto", 945.0, 4.2],
	],
	"montanhas": [
		["sky.png", "Fundo", 300.0, 6.0],
		["far.png", "Longe", 840.0, 4.6],
		["mid.png", "Meio", 880.0, 4.4],
		["trees.png", "Perto", 940.0, 4.4],
	],
}

var _poeira: CPUParticles2D
var _ceu_layer: ParallaxLayer
var _ceu_tex: Sprite2D


func _ready() -> void:
	var modulacao := get_node_or_null("Modulacao") as CanvasModulate
	if modulacao:
		modulacao.color = cor_ambiente

	_montar_ceu()
	_gerar_parallax()

	var raios := get_node_or_null("Raios")
	if raios:
		for p in raios.get_children():
			if p is Polygon2D:
				p.color = Color(cor_luz.r, cor_luz.g, cor_luz.b, p.color.a)

	_poeira = get_node_or_null("Poeira") as CPUParticles2D
	if _poeira:
		_poeira.color = cor_poeira
		_poeira.amount = int(maxf(1.0, _poeira.amount * densidade_poeira))


func _process(_dt: float) -> void:
	if _poeira:
		var cam := get_viewport().get_camera_2d()
		if cam:
			_poeira.global_position = cam.get_screen_center_position()


## --- geração do cenário de fundo ---------------------------------------

## Chamado pelo `gerador_corredor.gd` quando a JORNADA de aproximação
## estica o nível bem além da `largura_nivel`/`extensao_esquerda` originais
## -- sem isto o fundo fica só desenhado na área "clássica" do nível e a
## jornada (que pode começar dezenas de milhares de pixels antes) fica sem
## fundo (vazio/preto).
func atualizar_extensao(nova_largura: float, nova_esquerda: float) -> void:
	var mudou := false
	if nova_largura > largura_nivel:
		largura_nivel = nova_largura
		mudou = true
	if nova_esquerda < extensao_esquerda:
		extensao_esquerda = nova_esquerda
		mudou = true
	if mudou:
		_gerar_parallax()


## Remove tudo o que `_gerar_parallax` já gerou antes (marcado com o meta
## "gerado"), para a função poder ser chamada de novo em segurança.
func _limpar_gerado() -> void:
	for caminho in ["Parallax/Fundo", "Parallax/Longe", "Parallax/Meio", "Parallax/Perto"]:
		var layer := get_node_or_null(caminho) as Node2D
		if layer == null:
			continue
		for n in layer.get_children():
			if n.has_meta("gerado"):
				n.free()


func _gerar_parallax() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d|%s" % [seed_ambiente, bioma])
	_limpar_gerado()

	# pack pixel-art: camadas reais em vez das silhuetas geradas
	if fundo_pack != "" and PACKS.has(fundo_pack):
		_montar_fundo_pack(rng)
		if luzes_horizonte:
			_brilho_horizonte(rng)
		return

	# nome da camada -> [escurecer, passo_x, h_min, h_max, alpha]
	var camadas := {
		"Parallax/Fundo": [0.55, 210.0, 240.0, 430.0, 1.0],
		"Parallax/Longe": [0.34, 160.0, 300.0, 520.0, 1.0],
		"Parallax/Meio": [0.05, 130.0, 320.0, 560.0, 1.0],
		"Parallax/Perto": [0.60, 240.0, 340.0, 600.0, 0.65],
	}
	for caminho: String in camadas:
		var layer := get_node_or_null(caminho) as Node2D
		if layer == null:
			continue
		for n in layer.get_children():
			if n.name in ["Fundo", "Bruma"]:
				continue
			n.free()
		var cfg: Array = camadas[caminho]
		var cor: Color = cor_silhueta.darkened(cfg[0]).lerp(cor_fundo, 0.12)
		var perto := caminho.ends_with("Perto")
		var passo: float = cfg[1]
		var x := extensao_esquerda
		while x < largura_nivel + 400.0:
			var h := rng.randf_range(cfg[2], cfg[3])
			var larg := rng.randf_range(passo * 0.7, passo * 1.5)
			for poly in _formas(bioma, perto, rng, larg, h):
				var p2 := Polygon2D.new()
				p2.polygon = poly
				p2.color = Color(cor.r, cor.g, cor.b, cfg[4])
				p2.position = Vector2(x, 0.0)
				p2.set_meta("gerado", true)
				layer.add_child(p2)
			x += rng.randf_range(passo * 0.55, passo * 1.1)

	_faixa_rasteira(rng)

	if luzes_horizonte:
		_brilho_horizonte(rng)


## Fundo do "céu" (gradiente vertical) fixo relativamente à CÂMARA (não ao
## mundo): uma `ParallaxLayer` com `motion_scale = 0` dentro do próprio
## `ParallaxBackground` -- não dá para usar um `CanvasLayer` normal aqui
## porque o `ParallaxBackground` tem prioridade de desenho especial e fica
## sempre atrás de QUALQUER `CanvasLayer`, mesmo com layer muito negativo.
## As silhuetas/sprites das outras camadas continuam a dar sensação de
## profundidade normalmente, mas o céu em si não pode depender de
## coordenadas do mundo: a JORNADA de aproximação (gerador_corredor.gd) pode
## levar a câmara a dezenas de milhares de pixels da origem, distância a que
## o parallax tradicional (motion_scale baixo na camada "Fundo") deixa de
## cobrir a área visível -- o cenário "foge" da câmara em vez de a
## acompanhar, e o resultado era um buraco preto no ecrã.
func _montar_ceu() -> void:
	var parallax := get_node_or_null("Parallax") as ParallaxBackground
	if parallax == null:
		return
	if _ceu_layer == null:
		_ceu_layer = ParallaxLayer.new()
		_ceu_layer.name = "Ceu"
		_ceu_layer.motion_scale = Vector2.ZERO
		parallax.add_child(_ceu_layer)
		parallax.move_child(_ceu_layer, 0)  # primeiro filho -> desenhado atrás dos outros
		_ceu_tex = Sprite2D.new()
		_ceu_tex.centered = true
		_ceu_tex.scale = Vector2(1000.0, 8.0)  # cobre qualquer zoom/resolução razoável
		_ceu_layer.add_child(_ceu_tex)

	var base := get_node_or_null("Parallax/Fundo/Fundo") as ColorRect
	if base:
		base.visible = false  # o novo céu substitui este "slab" placeholder

	var grad := Gradient.new()
	grad.colors = PackedColorArray([cor_fundo.lerp(cor_luz, 0.16), cor_fundo.darkened(0.4)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 4
	tex.height = 512
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.0, 0.0)
	tex.fill_to = Vector2(0.0, 1.0)
	_ceu_tex.texture = tex


## Banda de mato/entulho colada ao fundo do ecrã, em qualquer bioma, para a
## base nunca ficar pelada.
func _faixa_rasteira(rng: RandomNumberGenerator) -> void:
	var layer := get_node_or_null("Parallax/Perto") as Node2D
	if layer == null:
		return
	var cor := cor_silhueta.darkened(0.62).lerp(cor_fundo, 0.1)
	var x := extensao_esquerda
	while x < largura_nivel + 400.0:
		var w := rng.randf_range(70.0, 190.0)
		var hh := rng.randf_range(34.0, 104.0)
		var p := Polygon2D.new()
		p.polygon = PackedVector2Array([
			Vector2(0, CHAO), Vector2(w * 0.18, CHAO - hh * 0.8),
			Vector2(w * 0.5, CHAO - hh), Vector2(w * 0.82, CHAO - hh * 0.7),
			Vector2(w, CHAO),
		])
		p.color = Color(cor.r, cor.g, cor.b, 0.7)
		p.position = Vector2(x, 0.0)
		p.set_meta("gerado", true)
		layer.add_child(p)
		x += rng.randf_range(60.0, 150.0)


## Constrói o fundo a partir de um pack pixel-art (`fundo_pack`): a textura
## repete-se horizontalmente por `ParallaxLayer.motion_mirroring` (nativo do
## Godot) em vez de gerar cópias manuais -- o mirroring cobre corretamente
## qualquer distância que a câmara alcance (incluindo a JORNADA de
## aproximação, que pode ir a dezenas de milhares de pixels da origem, onde
## posicionar cópias "à mão" ao longo de x0..x1 deixa de bater certo com a
## posição real na tela por causa do motion_scale baixo desta camada).
func _montar_fundo_pack(_rng: RandomNumberGenerator) -> void:
	for item: Array in PACKS[fundo_pack]:
		var tex: Texture2D = load("%s/%s/%s" % [BG_DIR, fundo_pack, item[0]])
		if tex == null:
			continue
		var layer := get_node_or_null("Parallax/%s" % item[1]) as ParallaxLayer
		if layer == null:
			continue
		# fora as silhuetas geradas desta camada (deixa sky/bruma)
		for n in layer.get_children():
			if not (n.name in ["Fundo", "Bruma"]):
				n.free()
		var esc: float = item[3]
		var y_base: float = item[2]
		var tw := float(tex.get_width()) * esc
		var th := float(tex.get_height()) * esc
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.centered = false
		spr.scale = Vector2(esc, esc)
		spr.position = Vector2(0.0, y_base - th)
		spr.set_meta("gerado", true)
		layer.add_child(spr)
		layer.motion_mirroring = Vector2(tw, 0.0)


## Faixa de brilho quente colada ao horizonte + tochas distantes a
## tremeluzir entre as ruínas. Aditivo (Polygon2D + Light2D leves).
func _brilho_horizonte(rng: RandomNumberGenerator) -> void:
	var longe := get_node_or_null("Parallax/Longe") as Node2D
	var meio := get_node_or_null("Parallax/Meio") as Node2D
	if longe == null:
		return
	# banda de calor ao longo da linha do horizonte
	var banda := Polygon2D.new()
	banda.name = "BrilhoHorizonte"
	var y := CHAO - 40.0
	banda.polygon = PackedVector2Array([
		Vector2(extensao_esquerda, y - 220.0), Vector2(largura_nivel + 900.0, y - 220.0),
		Vector2(largura_nivel + 900.0, y + 40.0), Vector2(extensao_esquerda, y + 40.0),
	])
	var quente := Color(cor_luz.r, cor_luz.g * 0.7, cor_luz.b * 0.4, 1.0)
	banda.vertex_colors = PackedColorArray([
		Color(quente.r, quente.g, quente.b, 0.0), Color(quente.r, quente.g, quente.b, 0.0),
		Color(quente.r, quente.g, quente.b, 0.5), Color(quente.r, quente.g, quente.b, 0.5),
	])
	banda.set_meta("gerado", true)
	longe.add_child(banda)
	longe.move_child(banda, 1)
	# tochas distantes (pontos aditivos que tremeluzem)
	var alvo := meio if meio else longe
	var x := extensao_esquerda + 1000.0
	while x < largura_nivel + 300.0:
		var ty := CHAO - rng.randf_range(120.0, 380.0)
		var ponto := Polygon2D.new()
		var r := rng.randf_range(5.0, 11.0)
		var circ := PackedVector2Array()
		for i in 10:
			var a := TAU * float(i) / 10.0
			circ.append(Vector2(cos(a) * r, sin(a) * r))
		ponto.polygon = circ
		ponto.color = Color(1.0, 0.62, 0.28, rng.randf_range(0.5, 0.85))
		ponto.position = Vector2(x + rng.randf_range(-60.0, 60.0), ty)
		ponto.set_meta("gerado", true)
		alvo.add_child(ponto)
		var tw := ponto.create_tween().set_loops()
		var base_a := ponto.color.a
		tw.tween_property(ponto, "modulate:a", 0.35, rng.randf_range(0.5, 1.1))
		tw.tween_property(ponto, "modulate:a", 1.0, rng.randf_range(0.5, 1.1))
		x += rng.randf_range(260.0, 520.0)


## --- kits de silhueta por bioma --------------------------------------

func _formas(b: String, perto: bool, rng: RandomNumberGenerator, larg: float, h: float) -> Array:
	match b:
		"prisao", "catacumbas":
			return _forma_pilar(rng, larg, h, b == "prisao")
		"torres":
			return _forma_torre(rng, larg, h)
		"cidade":
			return _forma_telhado(rng, larg, h)
		"castelo":
			return _forma_arco(rng, larg, h)
		_:
			return _forma_arvore(rng, larg, h, perto)


func _forma_arvore(rng: RandomNumberGenerator, larg: float, h: float, perto: bool) -> Array:
	var tw: float = larg * rng.randf_range(0.1, 0.18)
	var th: float = h * rng.randf_range(0.55, 0.75)
	var tronco := PackedVector2Array([
		Vector2(-tw, CHAO), Vector2(-tw * 0.6, CHAO - th),
		Vector2(tw * 0.6, CHAO - th), Vector2(tw, CHAO),
	])
	# copa: anel de pontos à volta do topo, com ruído (folhagem caída)
	var cx := 0.0
	var cy: float = CHAO - h * rng.randf_range(0.7, 0.85)
	var rx: float = larg * rng.randf_range(0.42, 0.6)
	var ry: float = h * rng.randf_range(0.26, 0.4)
	var copa := PackedVector2Array()
	var n := 14
	for i in n:
		var a: float = TAU * float(i) / float(n)
		var rr := 1.0 + rng.randf_range(-0.22, 0.16)
		var drip := 1.0
		if sin(a) > 0.2:  # parte de baixo cai mais (ramos pendentes)
			drip = rng.randf_range(1.1, 1.7)
		copa.append(Vector2(cx + cos(a) * rx * rr, cy + sin(a) * ry * rr * drip))
	if perto and rng.randf() < 0.5:
		return [copa]  # arbusto denso em primeiro plano
	return [tronco, copa]


func _forma_pilar(rng: RandomNumberGenerator, larg: float, h: float, com_jaula: bool) -> Array:
	var w: float = larg * rng.randf_range(0.16, 0.26)
	var col := PackedVector2Array([
		Vector2(-w, CHAO), Vector2(-w * 0.82, CHAO - h),
		Vector2(w * 0.82, CHAO - h), Vector2(w, CHAO),
	])
	var cap := PackedVector2Array([
		Vector2(-w * 1.35, CHAO - h), Vector2(-w * 1.1, CHAO - h - h * 0.08),
		Vector2(w * 1.1, CHAO - h - h * 0.08), Vector2(w * 1.35, CHAO - h),
	])
	var res := [col, cap]
	if com_jaula and rng.randf() < 0.4:
		var jy: float = CHAO - h * rng.randf_range(0.55, 0.8)
		var jw := w * 0.9
		var jh := jw * 1.4
		var ox := w * (1.0 if rng.randf() < 0.5 else -1.0) * 2.2
		res.append(PackedVector2Array([
			Vector2(ox - jw, jy), Vector2(ox + jw, jy),
			Vector2(ox + jw, jy + jh), Vector2(ox - jw, jy + jh),
		]))
		res.append(PackedVector2Array([  # corrente
			Vector2(ox - 3, CHAO - h - h * 0.08), Vector2(ox + 3, CHAO - h - h * 0.08),
			Vector2(ox + 3, jy), Vector2(ox - 3, jy),
		]))
	return res


func _forma_torre(rng: RandomNumberGenerator, larg: float, h: float) -> Array:
	var wb: float = larg * rng.randf_range(0.28, 0.4)
	var wt: float = wb * rng.randf_range(0.5, 0.72)
	var corpo := PackedVector2Array([
		Vector2(-wb, CHAO), Vector2(-wt, CHAO - h * 0.86),
		Vector2(-wt * 1.25, CHAO - h * 0.86), Vector2(-wt * 1.25, CHAO - h),
		Vector2(-wt * 0.55, CHAO - h), Vector2(-wt * 0.55, CHAO - h * 0.92),
		Vector2(wt * 0.55, CHAO - h * 0.92), Vector2(wt * 0.55, CHAO - h),
		Vector2(wt * 1.25, CHAO - h), Vector2(wt * 1.25, CHAO - h * 0.86),
		Vector2(wt, CHAO - h * 0.86), Vector2(wb, CHAO),
	])
	return [corpo]


func _forma_telhado(rng: RandomNumberGenerator, larg: float, h: float) -> Array:
	var w: float = larg * rng.randf_range(0.34, 0.5)
	var bh: float = h * rng.randf_range(0.5, 0.78)
	var caixa := PackedVector2Array([
		Vector2(-w, CHAO), Vector2(-w, CHAO - bh),
		Vector2(w, CHAO - bh), Vector2(w, CHAO),
	])
	var beira := w * rng.randf_range(1.0, 1.16)
	var pico: float = CHAO - bh - h * rng.randf_range(0.2, 0.4)
	var telhado := PackedVector2Array([
		Vector2(-beira, CHAO - bh), Vector2(0, pico), Vector2(beira, CHAO - bh),
	])
	var res := [caixa, telhado]
	if rng.randf() < 0.5:  # chaminé
		var cxx := w * rng.randf_range(-0.5, 0.5)
		res.append(PackedVector2Array([
			Vector2(cxx - 6, CHAO - bh - h * 0.1), Vector2(cxx + 6, CHAO - bh - h * 0.1),
			Vector2(cxx + 6, pico - h * 0.06), Vector2(cxx - 6, pico - h * 0.06),
		]))
	return res


func _forma_arco(rng: RandomNumberGenerator, larg: float, h: float) -> Array:
	var w: float = larg * rng.randf_range(0.3, 0.44)
	var ombro: float = CHAO - h * rng.randf_range(0.45, 0.6)
	var pts := PackedVector2Array()
	pts.append(Vector2(-w, CHAO))
	pts.append(Vector2(-w, ombro))
	# curva até ao bico (arco ogival)
	var passos := 6
	for i in passos + 1:
		var f := float(i) / float(passos)
		var xx: float = lerpf(-w * 0.86, 0.0, f)
		var yy: float = lerpf(ombro, CHAO - h, f * f)
		pts.append(Vector2(xx, yy))
	for i in passos + 1:
		var f := float(i) / float(passos)
		var xx: float = lerpf(0.0, w * 0.86, f)
		var yy: float = lerpf(CHAO - h, ombro, 1.0 - (1.0 - f) * (1.0 - f))
		pts.append(Vector2(xx, yy))
	pts.append(Vector2(w, ombro))
	pts.append(Vector2(w, CHAO))
	return [pts]
