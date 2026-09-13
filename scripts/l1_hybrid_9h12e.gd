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


## AMOSTRAGEM. As pecas do Hybrid sao recortes a` resolucao da fonte
## (130-300 px) ampliados 1,1x a 2,0x -- exactamente o caso que a regra da
## 9H.7B cobre: fonte ampliada tem de ser amostrada alinhada a` grelha da
## fonte, com transicao de um pixel de ecra, em vez de um `linear` que a
## esborrata. O passe 9H.12E nasceu depois dessa regra e nunca a aplicou; as
## 23 falhas que a suite trazia no L1 eram isto, e nao um teste obsoleto.
const SHADER_NITIDEZ := preload("res://assets/shaders/nitidez_fundo.gdshader")

static func _nitidez(s: Sprite2D) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_NITIDEZ
	mat.set_shader_parameter("conservar_texel", true)
	mat.set_shader_parameter("reparar_borda", false)
	s.material = mat


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
	_nitidez(s)
	s.modulate = tinta
	s.position = Vector2(_x_camada(ref_x, f, mundo_x) - s.texture.get_width() * escala * 0.5, y)
	camada.add_child(s)
	return s


## 9H.17 G -- o passe deixou de ser exclusivo do L1. O Game Master viu o
## fundo do L2 "desfocado e de baixa qualidade", e a medicao explica porque:
## o L2 vivia do panorama `region1_panorama_heart_tree.png`, 952x247, esticado
## por todo o ecra. Nao ha' fonte nativa maior no repo -- o `_hd_x4` e' esse
## mesmo ficheiro reamostrado (erro medio 3,01/255 ao reduzi-lo; a energia de
## bordos cai de 1533 para 74), e o proprio manifesto da producao 9H.12E
## declara as camadas de 1920 como "camadas ampliadas de recortes, nao arte
## nativa". A resposta honesta e' NATIVE ART REQUIRED.
##
## O que da' para fazer com o que ha', e que e' o que o L1 ja' fazia: em vez
## de AMPLIAR uma tira pequena, COMPOR muitos recortes nativos (130-300 px)
## a` escala a que foram cortados. Mais informacao por pixel de ecra, sem
## emendas rectangulares e sem inventar nitidez que a fonte nao tem.
##
## O L2 nao e' o L1 com outro nome: e' um PANTANO. Mesmo vocabulario de
## pecas, arranjo e paleta proprios -- mais mata e vinhas, menos castelo e
## arcos, e um verde doentio no lugar do azul frio.
const PERFIL_L1 := 1
const PERFIL_L2 := 2


## Este perfil monta-se com o passe Hybrid?
static func serve(perfil: int) -> bool:
	return perfil == PERFIL_L1 or perfil == PERFIL_L2


static func montar(alvo: Node2D) -> void:
	var perfil: int = int(alvo.get("perfil"))
	if perfil == PERFIL_L2:
		_montar_l2(alvo)
		return
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
	_nitidez(pintura)
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


## ARRANJO DO L2 -- Pantano dos Sussurros. Mesmas pecas nativas do kit 9H.12E,
## outra composicao e outra luz. O ceu pintado entra uma vez (como no L1, o
## parallax de 0,12 faz uma imagem de 2048 px cobrir o nivel inteiro), mas
## puxado para o verde e mais baixo no ecra -- num pantano ve-se menos ceu.
## As torres do castelo saem: aqui nao ha' castelo, ha' mata. Os arcos
## partidos ficam, poucos e afundados, como ruinas a apodrecer na agua.
static func _montar_l2(alvo: Node2D) -> void:
	var ref_x: float = alvo.referencia.x

	# --- 01 ceu: o mesmo plano fundo, lavado e puxado ao verde-agua -------
	var ceu: Node2D = alvo._camada("HybridL2_ceu", -30, Vector2(F_CEU, FY))
	ceu.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var pintura := Sprite2D.new()
	pintura.texture = tex("layers/01_far_sky_castle")
	pintura.centered = false
	var esc := 940.0 / float(pintura.texture.get_height())
	pintura.scale = Vector2(esc, esc)
	pintura.position = Vector2(
		_x_camada(ref_x, F_CEU, ref_x) - pintura.texture.get_width() * esc * 0.5, 96.0)
	# mais verde e mais escuro que o L1: o pantano nao tem luar limpo
	pintura.modulate = Color(0.38, 0.50, 0.50, 1.0)
	_nitidez(pintura)
	ceu.add_child(pintura)

	# --- 02 cascatas ao longe (o pantano alimenta-se delas) --------------
	var longe: Node2D = alvo._camada("HybridL2_longe", -27, Vector2(F_SERRA, FY))
	var t2 := Color(0.32, 0.44, 0.46, 0.80)
	_peca(longe, "cascata", ref_x, F_SERRA, 760.0, 315.0, 1.30, t2)
	_peca(longe, "cascata", ref_x, F_SERRA, 2740.0, 300.0, 1.10, t2, true)

	# --- 03 mata cerrada: o plano que da' o carater ----------------------
	# Mais densa que no L1 (oito pecas contra seis) e mais baixa: as copas
	# fecham o ceu, que e' o que faz um pantano ser um pantano.
	var mata: Node2D = alvo._camada("HybridL2_mata", -24, Vector2(F_FLORESTA, FY))
	var t3 := Color(0.26, 0.36, 0.34, 0.92)
	for i in 8:
		var nome: String = "floresta" if i % 3 != 1 else "arvore"
		_peca(mata, nome, ref_x, F_FLORESTA, -200.0 + float(i) * 560.0,
			300.0 + float(i % 3) * 22.0, 1.6 + float(i % 2) * 0.3, t3, i % 2 == 1)

	# --- 04 ruinas afundadas: poucas, e baixas ---------------------------
	var ruinas: Node2D = alvo._camada("HybridL2_ruinas", -21, Vector2(F_RUINAS, FY))
	var t4 := Color(0.28, 0.34, 0.36, 0.90)
	_peca(ruinas, "arco_partido", ref_x, F_RUINAS, 640.0, 452.0, 1.10, t4)
	_peca(ruinas, "arco_partido", ref_x, F_RUINAS, 2260.0, 460.0, 1.25, t4, true)
	_peca(ruinas, "raizes", ref_x, F_RUINAS, 1500.0, 430.0, 1.5, t4)
	_peca(ruinas, "raizes", ref_x, F_RUINAS, 3300.0, 436.0, 1.3, t4, true)

	# --- eixos de luz: menos e mais verdes (a luz custa a entrar) --------
	var eixos: Node2D = alvo._camada("HybridL2_eixos", -18, Vector2(0.70, FY))
	for par in [[900.0, 0.13], [2500.0, 0.11]]:
		var e := _peca(eixos, "eixo_luz", ref_x, 0.70, par[0], 140.0, 2.0,
			Color(0.66, 0.86, 0.74, par[1]))
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		e.material = mat

	# --- 05 primeiro plano: vinhas a cair, que e' a moldura do pantano ---
	var frente: Node2D = alvo._camada("HybridL2_frente", 9, Vector2(F_FRENTE, FY))
	var t5 := Color(0.16, 0.20, 0.19, 0.95)
	var frente_pecas := [
		["vinhas", 120.0, 142.0, 1.8, false], ["ramos", 780.0, 155.0, 1.5, true],
		["vinhas", 1450.0, 138.0, 1.9, true], ["ramo_curvo", 2100.0, 160.0, 1.6, false],
		["vinhas", 2800.0, 145.0, 1.7, false], ["ramos", 3500.0, 158.0, 1.45, true],
	]
	for p in frente_pecas:
		_peca(frente, p[0], ref_x, F_FRENTE, p[1], p[2], p[3], t5, p[4])


## CORPO ORGANICO DA PLATAFORMA (9H.17 I3).
##
## O review disse que as pontas ajudaram mas que o MEIO continua a ler-se
## como um rectangulo repetido -- e lia mesmo: o corpo era `corpo.png`
## (128x128) em mosaico, e um mosaico de um rectangulo da' um rectangulo.
##
## A peca que faltava ja' estava produzida e nunca tinha sido usada:
## `terrain_hd/plataforma.png`, 290x275. Medida, tem tres bandas:
##
##   y   0.. 32   rebentos POR CIMA da superficie (musgo, corrupcao vermelha)
##   y  32..104   a laje solida -- a linha de pouso e' o topo dela, y=36
##   y 104..275   a barriga esfarrapada: raiz, rocha e estalactite
##
## Isso resolve de uma vez a silhueta irregular, a quebra do mosaico E a
## logica visual que o Game Master reclamou no L2: a vegetacao nasce EM CIMA
## e o que pende por baixo e' estrutura.
##
## Desenha-se em TRES FATIAS -- ponta esquerda, meio repetido, ponta direita
## (espelhada) -- para a peca servir de 56 a 660 px sem ser esticada.
const PLAT_SUPERFICIE := 36.0   ## linha de pouso dentro da fonte
const PLAT_SOLIDO := 68.0       ## altura da laje solida na fonte
const PLAT_CAP := 96.0          ## largura de cada ponta na fonte
const PLAT_MEIO_X := 96.0       ## banda repetivel: x de 96 a 194
const PLAT_MEIO_W := 98.0


## Devolve `false` se a peca nao existir (ai o chamador faz o mosaico antigo).
static func corpo_organico(vis: Node, largura: float, y0: float, alt: float) -> bool:
	var t := tex("terrain_hd/plataforma")
	if t == null or largura < 40.0:
		return false
	var h := float(t.get_height())
	# a laje solida da peca cobre o corpo do bloco; nunca tao pequena que os
	# rebentos de cima desaparecam, nem tao grande que a barriga tape o vao
	var esc: float = clampf(alt / PLAT_SOLIDO, 0.52, 1.45)
	var topo_y := y0 - PLAT_SUPERFICIE * esc
	var cap_w := PLAT_CAP * esc
	var meio_w := PLAT_MEIO_W * esc

	var fatia := func(rx: float, rw: float, x: float, espelhar: bool) -> void:
		var s := Sprite2D.new()
		s.texture = t
		s.centered = false
		s.region_enabled = true
		s.region_rect = Rect2(rx, 0.0, rw, h)
		s.scale = Vector2(esc, esc)
		s.flip_h = espelhar
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		s.z_index = -1              # atras da Koliani e dos inimigos
		s.position = Vector2(x, topo_y)
		_nitidez(s)
		vis.add_child(s)

	var x_esq := -largura * 0.5
	var x_dir := largura * 0.5
	# meio primeiro, para as pontas ficarem por cima da emenda
	var meio_x0 := x_esq + cap_w
	var meio_x1 := x_dir - cap_w
	var x := meio_x0
	while x < meio_x1 - 1.0 and meio_w > 4.0:
		fatia.call(PLAT_MEIO_X, minf(PLAT_MEIO_W, (meio_x1 - x) / esc), x, false)
		x += meio_w
	fatia.call(0.0, PLAT_CAP, x_esq, false)
	fatia.call(0.0, PLAT_CAP, x_dir - cap_w, true)
	return true


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
	rematar_bordas(vis, largura, y0, alt, rng)
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


## REMATE DAS PONTAS (9H.16 E1). O bloco e' um MOSAICO de `corpo`/`lado`/
## `base`/`topo`: mosaico de um retangulo da' um retangulo, e por isso as
## plataformas liam-se como LAJES -- duas arestas verticais a direito e uma
## barriga plana. O Game Master reportou exactamente isso.
##
## Nao se inventa silhueta com poligonos nem gradientes (regra E2): usa-se a
## arte JA' PRODUZIDA e por usar do mesmo passe -- `terrain_hd/raizes.png`
## (coluna de rocha com capa de musgo e bordo esfarrapado) nas pontas e
## `terrain_hd/rocha.png` (massa pendente a escorrer) na barriga.
##
## Regras: so' VISUAL (nao toca na colisao), sempre ABAIXO da linha de
## pouso -- a aresta onde se aterra tem de continuar a ler-se -- e com a
## ponta virada para fora. Fica atras do miolo (`z_index = -1`) para o
## mosaico continuar a mandar na leitura do corpo.
static func rematar_bordas(vis: Node, largura: float, y0: float, alt: float,
		rng: RandomNumberGenerator) -> void:
	# Tambem nas finas: uma borda de 18 px e' onde a laje mais se nota.
	if largura < 70.0 or alt < 14.0:
		return
	var tex_ponta := tex("terrain_hd/raizes")
	if tex_ponta == null:
		return
	# a peca e' mais alta do que larga; escala-se pela ALTURA do bloco, com
	# um pouco de folga para transbordar por baixo (e' o que quebra a barriga)
	var esc: float = clampf((alt * 1.35) / float(tex_ponta.get_height()), 0.08, 0.7)
	var lp := float(tex_ponta.get_width()) * esc
	for lado_i: float in [-1.0, 1.0]:
		var s := Sprite2D.new()
		s.texture = tex_ponta
		s.centered = false
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		s.scale = Vector2(esc, esc)
		s.flip_h = lado_i < 0.0
		s.z_index = -1
		# encosta a ponta ao topo do corpo, mordendo 18% para dentro
		var x := largura * 0.5 * lado_i
		if lado_i < 0.0:
			x -= lp * 0.82
		else:
			x -= lp * 0.18
		s.position = Vector2(x, y0 - 2.0)
		s.modulate = Color(1, 1, 1, 0.96)
		vis.add_child(s)

	# barriga: uma massa a pender, so' em blocos com corpo que se veja
	if alt < 40.0 or largura < 200.0:
		return
	var tex_barriga := tex("terrain_hd/rocha")
	if tex_barriga == null:
		return
	var eb: float = clampf((alt * 0.9) / float(tex_barriga.get_height()), 0.06, 0.6)
	var b := Sprite2D.new()
	b.texture = tex_barriga
	b.centered = false
	b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	b.scale = Vector2(eb, eb)
	b.flip_h = rng.randf() < 0.5
	b.z_index = -1
	b.position = Vector2(
		rng.randf_range(-0.22, 0.22) * largura - float(tex_barriga.get_width()) * eb * 0.5,
		y0 + alt * 0.45)
	b.modulate = Color(1, 1, 1, 0.9)
	vis.add_child(b)

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
