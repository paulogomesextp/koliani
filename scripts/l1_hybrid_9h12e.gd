extends RefCounted
## Passe visual exclusivo do perfil L1 (Hybrid Cinematic 2D). Só apresentação:
## não instancia física, não altera medidas, não toca em geometria.
##
## 9H.12E — REPARAÇÃO. O primeiro passe montava cinco canvases de 1920x950
## repetidos NOVE vezes cada um com `flip_h`. Consequências que o review viu:
## a lua e o castelo apareciam várias vezes, e como as camadas 03/04/05 eram
## recortes rectangulares via-se a aresta do rectângulo a meio do cenário.
##
## Agora:
##
## * a camada 01 é UMA pintura, uma só instância. Com parallax 0,12 num nível
##   de 6400 px a camada só percorre 6400 × 0,12 = 768 px — uma imagem de
##   2048 px cobre o nível inteiro. Uma lua, um castelo, zero repetição.
## * as outras camadas deixam de ser canvases: são ELEMENTOS com silhueta
##   orgânica (ver `tools/produzir_l1_hybrid_9h12e.py`), pousados um a um em
##   pontos do MUNDO escolhidos à mão. O castelo em silhueta entra uma vez.
## * separação atmosférica por profundidade: quanto mais longe, mais lavado,
##   mais azul e menos contraste. É o que impede o fundo de competir com o
##   plano de jogo.
##
## Âncora das camadas: uma peça que deve ser vista quando a câmara está em
## `mundo_x` fica, dentro da camada de fator f, em `ref.x·(1−f) + mundo_x·f`
## (é o inverso do `posição = desvio × (1 − f)` que o alvo escreve no
## `_process`). `_x_camada` faz essa conta — nunca pousar peças "a olho".

const DIR := "res://assets/art/regions/region_01_forest/production/l1_hybrid_9h12e/"

## Fatores de parallax por plano. O 05 passa de 1,0 para dar deslize à frente.
const F_CEU := 0.12
const F_SERRA := 0.26
const F_FLORESTA := 0.46
const F_RUINAS := 0.62
const F_FRENTE := 1.10
const FY := 0.08


static func tex(nome: String) -> Texture2D:
	return load(DIR + nome + ".png") as Texture2D


static func _x_camada(ref_x: float, f: float, mundo_x: float) -> float:
	return ref_x * (1.0 - f) + mundo_x * f


static func _peca(camada: Node2D, nome: String, ref_x: float, f: float,
		mundo_x: float, y: float, escala: float, tinta: Color,
		espelhar := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex("elementos/" + nome)
	s.centered = false
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	s.scale = Vector2(escala, escala)
	s.flip_h = espelhar
	s.modulate = tinta
	s.position = Vector2(_x_camada(ref_x, f, mundo_x) - s.texture.get_width() * escala * 0.5, y)
	camada.add_child(s)
	return s


static func montar(alvo: Node2D) -> void:
	var ref_x: float = alvo.referencia.x
	# VALOR POR PROFUNDIDADE. No 1º ensaio da 12E o fundo estava tão claro
	# como o plano de jogo e a cascata pintada ganhava à plataforma onde se
	# pousa. Cada plano desce de valor e sobe de azul à medida que afunda;
	# a rocha do terreno é o registo mais escuro do ecrã (`arrefecer`).

	# --- 01 céu / lua / castelo: UMA instância, sem repetição -------------
	var ceu: Node2D = alvo._camada("HybridL1_ceu", -30, Vector2(F_CEU, FY))
	ceu.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var pintura := Sprite2D.new()
	pintura.texture = tex("layers/01_far_sky_castle")
	pintura.centered = false
	var esc := 900.0 / float(pintura.texture.get_height())
	pintura.scale = Vector2(esc, esc)
	pintura.position = Vector2(
		_x_camada(ref_x, F_CEU, ref_x) - pintura.texture.get_width() * esc * 0.5, 60.0)
	pintura.modulate = Color(0.46, 0.50, 0.66, 1.0)   # o plano mais fundo: lavado E escuro
	ceu.add_child(pintura)

	# --- 02 serra e cascatas ---------------------------------------------
	var serra: Node2D = alvo._camada("HybridL1_serra", -27, Vector2(F_SERRA, FY))
	var t2 := Color(0.38, 0.42, 0.58, 0.82)
	# o castelo em silhueta entra UMA vez, e longe do castelo pintado da 01
	_peca(serra, "torres", ref_x, F_SERRA, 3250.0, 250.0, 1.25, t2)
	_peca(serra, "cascata", ref_x, F_SERRA, 420.0, 300.0, 1.35, t2)
	_peca(serra, "cascata", ref_x, F_SERRA, 2350.0, 285.0, 1.05, t2, true)

	# --- 03 floresta ------------------------------------------------------
	var mata: Node2D = alvo._camada("HybridL1_mata", -24, Vector2(F_FLORESTA, FY))
	var t3 := Color(0.30, 0.33, 0.46, 0.90)
	var mata_x := [-150.0, 620.0, 1330.0, 2050.0, 2780.0, 3520.0]
	for i in mata_x.size():
		var nome: String = "floresta" if i % 2 == 0 else "arvore"
		_peca(mata, nome, ref_x, F_FLORESTA, mata_x[i], 330.0 + (i % 3) * 26.0,
			1.5 + (i % 2) * 0.25, t3, i % 3 == 1)

	# --- 04 ruínas e arcos ------------------------------------------------
	var ruinas: Node2D = alvo._camada("HybridL1_ruinas", -21, Vector2(F_RUINAS, FY))
	var t4 := Color(0.34, 0.35, 0.48, 0.92)
	_peca(ruinas, "arco", ref_x, F_RUINAS, 260.0, 400.0, 1.3, t4)
	_peca(ruinas, "arco_partido", ref_x, F_RUINAS, 1480.0, 415.0, 1.15, t4)
	_peca(ruinas, "arco", ref_x, F_RUINAS, 2620.0, 395.0, 1.45, t4, true)
	_peca(ruinas, "arco_partido", ref_x, F_RUINAS, 3480.0, 420.0, 1.0, t4, true)

	# --- eixos de luz volumétrica (profundidade, entre 04 e o jogo) -------
	var eixos: Node2D = alvo._camada("HybridL1_eixos", -18, Vector2(0.70, FY))
	for par in [[520.0, 0.20], [1720.0, 0.15], [2980.0, 0.18]]:
		var e := _peca(eixos, "eixo_luz", ref_x, 0.70, par[0], 120.0, 2.0,
			Color(0.72, 0.80, 1.0, par[1]))
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		e.material = mat

	# --- 05 primeiro plano: ramos e vinhas no topo do ecrã ---------------
	# Escuro e alto: emoldura sem tapar a Koliani (que anda em y ≈ 560-900).
	var frente: Node2D = alvo._camada("HybridL1_frente", 9, Vector2(F_FRENTE, FY))
	var t5 := Color(0.20, 0.19, 0.27, 0.95)
	var frente_pecas := [
		["ramos", 180.0, 165.0, 1.5, false], ["vinhas", 900.0, 150.0, 1.7, false],
		["ramo_curvo", 1600.0, 160.0, 1.6, true], ["ramos", 2400.0, 158.0, 1.4, true],
		["vinhas", 3150.0, 150.0, 1.5, true], ["ramo_curvo", 3800.0, 168.0, 1.5, false],
	]
	for p in frente_pecas:
		_peca(frente, p[0], ref_x, F_FRENTE, p[1], p[2], p[3], t5, p[4])


## Props de uma plataforma, com ÂNCORA declarada. O primeiro passe pousava a
## lanterna no chão como se fosse um arbusto — e como a peça traz a corrente
## por cima, lia-se a flutuar. Cada tipo tem agora o seu suporte:
##
##   chão      cristais, raízes  -> base do sprite em cima da linha de pouso
##   pendurado lanterna, vinhas  -> topo do sprite no lábio de baixo do bloco
##
## Densidade contida: no máximo dois em cima e um pendurado por plataforma.
static func decorar(vis: Node, largura: float, y0: float, alt: float,
		rng: RandomNumberGenerator) -> void:
	if largura < 130.0:
		return
	var chao := ["cristais", "raizes"]
	var quantos: int = clampi(int(largura / 420.0), 1, 2)
	for i in quantos:
		var nome: String = chao[rng.randi_range(0, chao.size() - 1)]
		var escala := 0.30 if nome == "cristais" else 0.26
		var s := Sprite2D.new()
		s.texture = tex("elementos/" + nome)
		s.centered = false
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		s.scale = Vector2(escala, escala)
		s.flip_h = rng.randf() < 0.5
		# ÂNCORA DE CHÃO: a base assenta na linha de pouso (2 px enterrados).
		var fatia := largura / float(quantos + 1)
		s.position = Vector2(
			-largura * 0.5 + fatia * (i + 1) - s.texture.get_width() * escala * 0.5,
			y0 - s.texture.get_height() * escala + 2.0)
		vis.add_child(s)

	# ÂNCORA PENDURADA: só de blocos com corpo a sério, e presa ao lábio de
	# baixo. Numa borda de 18 px não pende uma lanterna com corrente.
	if alt < 34.0 or largura < 240.0:
		return
	var pendurado: String = "lanterna" if rng.randf() < 0.45 else "vinhas"
	var esc := 0.34 if pendurado == "lanterna" else 0.30
	var p := Sprite2D.new()
	p.texture = tex("elementos/" + pendurado)
	p.centered = false
	p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	p.scale = Vector2(esc, esc)
	p.flip_h = rng.randf() < 0.5
	var lado := 0.30 if rng.randf() < 0.5 else -0.30
	p.position = Vector2(largura * lado, y0 + alt - 6.0)
	vis.add_child(p)
	if pendurado == "lanterna":
		var luz := PointLight2D.new()
		luz.texture = _halo()
		luz.color = Color(1.0, 0.78, 0.48)
		luz.energy = 0.85
		luz.scale = Vector2(0.75, 0.75)
		luz.position = p.position + Vector2(
			p.texture.get_width() * esc * 0.5, p.texture.get_height() * esc * 0.72)
		vis.add_child(luz)


static var _halo_cache: GradientTexture2D = null

static func _halo() -> GradientTexture2D:
	if _halo_cache:
		return _halo_cache
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([
		Color(1, 0.92, 0.72, 0.95), Color(1, 0.72, 0.38, 0.34), Color(0.7, 0.4, 0.2, 0),
	])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 192
	t.height = 192
	t.fill = 1
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	_halo_cache = t
	return t
