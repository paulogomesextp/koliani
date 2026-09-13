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
	# 9H.17 CONTINUATION: a auditoria da 9H.7 conta as pecas de identidade de
	# cada nivel (ruinas no L3, cascatas no L4, corrupcao no L5). No legado ela
	# adivinhava pelo nome do ficheiro; aqui cada peca diz o que e.
	s.set_meta("peca", nome)
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
## 9H.17 CONTINUATION -- a Regiao I inteira passa a Hybrid.
##
## O Game Master viu o que a medicao confirma: com o L1 e o L2 ja' compostos
## de recortes nativos, os tres niveis que ainda vinham do panorama de
## 952x247 esticado 3x criavam um degrau de qualidade DENTRO da mesma regiao.
## Nao e' so' o fundo: `plataforma.gd` liga o corpo organico (9H.17 I3) por
## `serve()`, por isso o L3/L4/L5 tambem tinham o bloco rectangular em
## mosaico enquanto o L1/L2 tinham silhueta irregular.
##
## Nao sao tres copias do L1. O manifesto `data/regiao1/remaster.json` ja'
## declarava a identidade de cada nivel, e e' ela que manda na composicao:
##
##   L3 ruinas_da_viuva     ruinas 0,85  lanternas 0,60  cascatas 0,20
##   L4 cascatas_da_seiva   cascatas 0,90  corrupcao 0,60  ruinas 0,35
##   L5 coracao_corrompido  corrupcao 1,80  densidade 1,45  lanternas 0,12
##
## Os numeros escolhem o plano dominante de cada um: o L3 e' arcos e luz de
## lanterna, o L4 e' quedas de seiva, o L5 e' mata cerrada e corrupcao quase
## sem luz. As pecas `lanterna` e `cristais` do kit 9H.12E nunca tinham sido
## usadas -- sao exactamente o vocabulario que faltava para os separar.
const PERFIL_L3 := 3
const PERFIL_L4 := 4
const PERFIL_L5 := 5


## Este perfil monta-se com o passe Hybrid?
static func serve(perfil: int) -> bool:
	return perfil >= PERFIL_L1 and perfil <= PERFIL_L5


static func montar(alvo: Node2D) -> void:
	var perfil: int = int(alvo.get("perfil"))
	match perfil:
		PERFIL_L2:
			_montar_l2(alvo)
			return
		PERFIL_L3:
			_montar_l3(alvo)
			return
		PERFIL_L4:
			_montar_l4(alvo)
			return
		PERFIL_L5:
			_montar_l5(alvo)
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


## O plano mais fundo, comum aos cinco niveis: UMA pintura, sem repeticao.
## O parallax de 0,12 faz uma imagem de 2048 px cobrir um nivel de 6400 px,
## por isso ha uma lua e um castelo, e nao nove. `altura` e `y` dizem quanto
## ceu se ve -- numa ruina aberta ve-se muito, num pantano quase nada.
static func _ceu(alvo: Node2D, nome: String, altura: float, y: float,
		tinta: Color) -> void:
	var ref_x: float = alvo.referencia.x
	var camada: Node2D = alvo._camada(nome, -30, Vector2(F_CEU, FY))
	camada.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var pintura := Sprite2D.new()
	pintura.texture = tex("layers/01_far_sky_castle")
	pintura.centered = false
	var esc := altura / float(pintura.texture.get_height())
	pintura.scale = Vector2(esc, esc)
	pintura.position = Vector2(
		_x_camada(ref_x, F_CEU, ref_x) - pintura.texture.get_width() * esc * 0.5, y)
	pintura.modulate = tinta
	_nitidez(pintura)
	camada.add_child(pintura)


## Peca aditiva (luz). Serve as lanternas e os eixos: o que emite soma-se ao
## que esta por tras em vez de o tapar.
static func _luz(camada: Node2D, nome: String, ref_x: float, f: float,
		mundo_x: float, y: float, escala: float, tinta: Color) -> Sprite2D:
	var s := _peca(camada, nome, ref_x, f, mundo_x, y, escala, tinta)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = mat
	return s


## ARRANJO DO L3 -- Ninho da Viuva Negra / `ruinas_da_viuva`.
##
## O manifesto poe `ruinas` em 0,85 e `lanternas` em 0,60, os valores mais
## altos da regiao, e `cascatas` em 0,20, o mais baixo. A composicao obedece:
## o plano que define o nivel e o das RUINAS (seis pecas contra as quatro do
## L1 e as duas do L2), a agua quase desaparece, e as lanternas -- a peca do
## kit que nunca fora usada -- penduram-se entre os arcos. Sao a unica fonte
## quente do ecra, e e o contraste delas com a pedra fria que da ao nivel
## uma luz que nem o L1 nem o L2 tem.
static func _montar_l3(alvo: Node2D) -> void:
	var ref_x: float = alvo.referencia.x

	# ceu alto e aberto: uma ruina nao tem copa a tapar o luar
	_ceu(alvo, "HybridL3_ceu", 880.0, 48.0, Color(0.44, 0.45, 0.60, 1.0))

	# --- 02 a torre da viuva ao longe, e uma so queda de agua -------------
	var longe: Node2D = alvo._camada("HybridL3_longe", -27, Vector2(F_SERRA, FY))
	var t2 := Color(0.40, 0.40, 0.54, 0.82)
	_peca(longe, "torres", ref_x, F_SERRA, 1150.0, 235.0, 1.45, t2)
	_peca(longe, "torres", ref_x, F_SERRA, 3300.0, 262.0, 1.00, t2, true)
	_peca(longe, "cascata", ref_x, F_SERRA, 2300.0, 300.0, 0.95,
		Color(0.38, 0.40, 0.54, 0.55))

	# --- 03 mata rala: aqui a pedra ganhou a arvore ----------------------
	var mata: Node2D = alvo._camada("HybridL3_mata", -24, Vector2(F_FLORESTA, FY))
	var t3 := Color(0.32, 0.31, 0.42, 0.88)
	var mata_x := [-100.0, 980.0, 2080.0, 3050.0, 3820.0]
	for i in mata_x.size():
		var nome: String = "arvore" if i % 2 == 0 else "floresta"
		_peca(mata, nome, ref_x, F_FLORESTA, mata_x[i], 340.0 + float(i % 3) * 24.0,
			1.35 + float(i % 2) * 0.2, t3, i % 2 == 1)

	# --- 04 RUINAS: o plano dominante -------------------------------------
	var ruinas: Node2D = alvo._camada("HybridL3_ruinas", -21, Vector2(F_RUINAS, FY))
	var t4 := Color(0.40, 0.38, 0.50, 0.94)
	# CATORZE pecas de ruina em ~4000 px (uma cada ~285 px de mundo, tres a
	# quatro no ecra de cada vez). E a densidade que o L3 ja tinha no sistema
	# de densidades da 9H.7 -- abaixo disto a identidade "ruinas" nao se le a
	# atravessar o nivel, que foi a queixa que fez nascer aquele limiar.
	# Altura, escala e espelho variam em passos diferentes para as pecas nao
	# lerem como uma fila.
	var arcos := [
		["arco", 160.0, 398.0, 1.35, false], ["arco_partido", 460.0, 424.0, 1.05, true],
		["arco", 860.0, 390.0, 1.50, true], ["arco_partido", 1180.0, 416.0, 1.20, false],
		["arco", 1520.0, 402.0, 1.30, false], ["arco_partido", 1840.0, 428.0, 1.10, true],
		["arco", 2180.0, 394.0, 1.45, true], ["arco_partido", 2500.0, 420.0, 1.25, false],
		["arco", 2860.0, 400.0, 1.25, false], ["arco_partido", 3180.0, 430.0, 1.00, true],
		["arco", 3560.0, 396.0, 1.40, true], ["arco_partido", 3860.0, 418.0, 1.15, false],
		["arco", -180.0, 408.0, 1.20, true], ["arco_partido", 2760.0, 436.0, 0.95, false],
	]
	for a in arcos:
		_peca(ruinas, a[0], ref_x, F_RUINAS, a[1], a[2], a[3], t4, a[4])
	# teias: as vinhas do kit lidas como teia, agarradas aos arcos
	_peca(ruinas, "vinhas", ref_x, F_RUINAS, 1180.0, 360.0, 1.30, t4)
	_peca(ruinas, "vinhas", ref_x, F_RUINAS, 3220.0, 366.0, 1.15, t4, true)

	# --- lanternas: `lanternas` 0,60, a assinatura do nivel ---------------
	# Ligeiramente a frente das ruinas (0,66) para a luz nao colar a pedra.
	var luzes: Node2D = alvo._camada("HybridL3_lanternas", -19, Vector2(0.66, FY))
	var quente := Color(1.0, 0.78, 0.44, 0.60)
	for lx in [420.0, 1340.0, 2020.0, 2700.0, 3400.0]:
		_luz(luzes, "lanterna", ref_x, 0.66, lx, 372.0, 1.25, quente)

	# --- eixos de luz: frios, para as lanternas se destacarem -------------
	var eixos: Node2D = alvo._camada("HybridL3_eixos", -18, Vector2(0.70, FY))
	for par in [[760.0, 0.17], [1900.0, 0.14], [3100.0, 0.16]]:
		_luz(eixos, "eixo_luz", ref_x, 0.70, par[0], 118.0, 2.0,
			Color(0.74, 0.78, 1.0, par[1]))

	# --- 05 primeiro plano: teia densa, que e o que faz um ninho ----------
	var frente: Node2D = alvo._camada("HybridL3_frente", 9, Vector2(F_FRENTE, FY))
	var t5 := Color(0.19, 0.18, 0.25, 0.95)
	var frente_pecas := [
		["vinhas", 240.0, 140.0, 2.0, false], ["vinhas", 700.0, 146.0, 1.7, true],
		["ramos", 1250.0, 158.0, 1.5, false], ["vinhas", 1800.0, 138.0, 1.9, false],
		["ramo_curvo", 2350.0, 162.0, 1.55, true], ["vinhas", 2950.0, 144.0, 1.8, true],
		["ramos", 3600.0, 156.0, 1.4, true],
	]
	for p in frente_pecas:
		_peca(frente, p[0], ref_x, F_FRENTE, p[1], p[2], p[3], t5, p[4])


## ARRANJO DO L4 -- A Arvore que Chora / `cascatas_da_seiva`.
##
## `cascatas` 0,90 -- o valor mais alto da regiao -- e uma tinta quase neutra
## e quente (1,158 / 1,143 / 1,039), ao contrario do azul do L1 e do verde do
## L2. E o unico nivel ambar da Regiao I: o que cai nao e agua, e seiva,
## e por isso as quedas sao douradas e os eixos de luz tambem. As raizes do
## kit entram como canais por onde a seiva desce.
static func _montar_l4(alvo: Node2D) -> void:
	var ref_x: float = alvo.referencia.x

	_ceu(alvo, "HybridL4_ceu", 910.0, 74.0, Color(0.60, 0.50, 0.39, 1.0))

	# --- 02 CASCATAS: o plano dominante, em escalas muito diferentes ------
	# Escalas de 0,95 a 1,70 para as quedas nao lerem como a mesma peca em fila.
	var longe: Node2D = alvo._camada("HybridL4_longe", -27, Vector2(F_SERRA, FY))
	var t2 := Color(0.56, 0.47, 0.37, 0.84)
	var quedas := [
		[-160.0, 296.0, 1.20, true], [180.0, 286.0, 1.45, false],
		[640.0, 312.0, 0.95, true], [1020.0, 278.0, 1.60, false],
		[1480.0, 304.0, 1.10, true], [1880.0, 272.0, 1.70, false],
		[2340.0, 300.0, 1.05, true], [2760.0, 284.0, 1.50, false],
	]
	for q in quedas:
		_peca(longe, "cascata", ref_x, F_SERRA, q[0], q[1], q[2], t2, q[3])
	# Seis quedas mais perto, no plano da mata: sao estas que dao a escala --
	# uma cortina de seiva so se le como grande quando ha uma pequena atras.
	# Catorze ao todo, a densidade que a auditoria da 9H.7 exige ao L4.
	var perto: Node2D = alvo._camada("HybridL4_quedas", -25, Vector2(F_FLORESTA, FY))
	var t2b := Color(0.72, 0.57, 0.38, 0.82)
	var quedas_perto := [
		[420.0, 330.0, 1.35, false], [1240.0, 344.0, 1.15, true],
		[2060.0, 326.0, 1.55, false], [2620.0, 350.0, 1.05, true],
		[3180.0, 332.0, 1.40, false], [3720.0, 346.0, 1.20, true],
	]
	for q in quedas_perto:
		_peca(perto, "cascata", ref_x, F_FLORESTA, q[0], q[1], q[2], t2b, q[3])

	# --- 03 mata media ----------------------------------------------------
	var mata: Node2D = alvo._camada("HybridL4_mata", -24, Vector2(F_FLORESTA, FY))
	var t3 := Color(0.42, 0.35, 0.28, 0.90)
	for i in 6:
		var nome: String = "floresta" if i % 2 == 0 else "arvore"
		_peca(mata, nome, ref_x, F_FLORESTA, -180.0 + float(i) * 760.0,
			326.0 + float(i % 3) * 26.0, 1.5 + float(i % 2) * 0.22, t3, i % 3 == 2)

	# --- 04 raizes que canalizam a seiva, e poucas ruinas -----------------
	var ruinas: Node2D = alvo._camada("HybridL4_ruinas", -21, Vector2(F_RUINAS, FY))
	var t4 := Color(0.46, 0.37, 0.28, 0.92)
	_peca(ruinas, "raizes", ref_x, F_RUINAS, 520.0, 424.0, 1.55, t4)
	_peca(ruinas, "raizes", ref_x, F_RUINAS, 1640.0, 430.0, 1.30, t4, true)
	_peca(ruinas, "raizes", ref_x, F_RUINAS, 2980.0, 420.0, 1.60, t4)
	_peca(ruinas, "arco_partido", ref_x, F_RUINAS, 1150.0, 408.0, 1.15, t4, true)
	_peca(ruinas, "arco_partido", ref_x, F_RUINAS, 3400.0, 414.0, 1.25, t4)

	# --- eixos: dourados, a luz a atravessar a seiva ----------------------
	var eixos: Node2D = alvo._camada("HybridL4_eixos", -18, Vector2(0.70, FY))
	for par in [[640.0, 0.26], [1820.0, 0.30], [3040.0, 0.24]]:
		_luz(eixos, "eixo_luz", ref_x, 0.70, par[0], 112.0, 2.1,
			Color(1.0, 0.86, 0.58, par[1]))

	# --- 05 primeiro plano: ramos pesados, poucos vaos --------------------
	var frente: Node2D = alvo._camada("HybridL4_frente", 9, Vector2(F_FRENTE, FY))
	var t5 := Color(0.22, 0.17, 0.12, 0.95)
	var frente_pecas := [
		["ramos", 200.0, 152.0, 1.6, false], ["ramo_curvo", 880.0, 164.0, 1.7, true],
		["vinhas", 1520.0, 140.0, 1.8, false], ["ramos", 2200.0, 156.0, 1.5, true],
		["ramo_curvo", 2900.0, 160.0, 1.6, false], ["vinhas", 3560.0, 142.0, 1.7, true],
	]
	for p in frente_pecas:
		_peca(frente, p[0], ref_x, F_FRENTE, p[1], p[2], p[3], t5, p[4])


## ARRANJO DO L5 -- Coracao da Floresta / `coracao_corrompido`.
##
## `corrupcao` 1,80 e `densidade` 1,45 (os maximos da regiao) contra
## `lanternas` 0,12 (o minimo): mata cerrada, quase sem luz, e a cor puxada
## ao magenta pela tinta do manifesto (1,18 / 0,85 / 0,938). Os `cristais` do
## kit -- a outra peca por estrear -- sao a corrupcao cristalizada.
##
## O LANDMARK. O L5 traz `landmark_visto_em = 3060`: a 9H.7 poe-no na cena
## para o jogador NAO chegar ao chefe sem ver a Heart Tree. Isso vivia na
## coluna pintada do panorama de 952 px, e `_montar_heart_tree()` e so um
## no vazio com a meta `baked_into`. Trocar o panorama pelo Hybrid sem mais
## nada APAGAVA o landmark -- e essa era a unica razao real para o L5 nao
## servir. Aqui a Heart Tree volta como peca propria, ancorada para ficar ao
## centro do ecra quando a camara passa em 3060, com o halo por tras.
const L5_LANDMARK_FALLBACK := 3060.0

static func _montar_l5(alvo: Node2D) -> void:
	var ref_x: float = alvo.referencia.x
	var landmark: float = float(alvo.get("landmark_visto_em"))
	if is_zero_approx(landmark):
		landmark = L5_LANDMARK_FALLBACK

	# o ceu mais escuro e mais fechado da regiao, puxado ao magenta
	_ceu(alvo, "HybridL5_ceu", 960.0, 104.0, Color(0.40, 0.31, 0.44, 1.0))

	# --- 02 a Heart Tree corrompida, e uma ruina longe --------------------
	var longe: Node2D = alvo._camada("HybridL5_longe", -27, Vector2(F_SERRA, FY))
	var t2 := Color(0.34, 0.28, 0.42, 0.84)
	_peca(longe, "torres", ref_x, F_SERRA, 420.0, 268.0, 1.05, t2)
	# halo primeiro, para a arvore ficar por cima dele
	_luz(longe, "eixo_luz", ref_x, F_SERRA, landmark, 150.0, 2.6,
		Color(0.86, 0.34, 0.70, 0.30))
	var arvore := _peca(longe, "arvore", ref_x, F_SERRA, landmark, 176.0, 2.60,
		Color(0.52, 0.30, 0.48, 0.96))
	arvore.name = "LandmarkHeartTree"

	# --- 03 mata cerrada: `densidade` 1,45, nove pecas --------------------
	var mata: Node2D = alvo._camada("HybridL5_mata", -24, Vector2(F_FLORESTA, FY))
	var t3 := Color(0.26, 0.21, 0.32, 0.94)
	for i in 9:
		var nome: String = "floresta" if i % 3 != 1 else "arvore"
		_peca(mata, nome, ref_x, F_FLORESTA, -240.0 + float(i) * 470.0,
			296.0 + float(i % 4) * 20.0, 1.65 + float(i % 2) * 0.3, t3, i % 2 == 1)

	# --- 04 raizes do coracao e cristais de corrupcao ---------------------
	var ruinas: Node2D = alvo._camada("HybridL5_ruinas", -21, Vector2(F_RUINAS, FY))
	var t4 := Color(0.30, 0.24, 0.36, 0.94)
	_peca(ruinas, "raizes", ref_x, F_RUINAS, 260.0, 418.0, 1.70, t4)
	_peca(ruinas, "raizes", ref_x, F_RUINAS, 1480.0, 424.0, 1.85, t4, true)
	_peca(ruinas, "raizes", ref_x, F_RUINAS, 2740.0, 416.0, 1.60, t4)
	_peca(ruinas, "arco_partido", ref_x, F_RUINAS, 900.0, 410.0, 1.20, t4, true)
	# DOZE cristais: `corrupcao` 1,80 e o maximo da regiao, e a auditoria da
	# 9H.7 pede >= 12 no L5 justamente porque com dois ou tres o ecra do chefe
	# ficava vazio. Metade fica no plano das ruinas e metade num plano mais
	# perto, para a corrupcao ter profundidade em vez de ser um friso.
	var magenta := Color(0.86, 0.36, 0.72, 0.50)
	var fundos := [
		[240.0, 446.0, 1.15], [880.0, 436.0, 1.45], [1560.0, 450.0, 1.05],
		[2200.0, 438.0, 1.35], [2840.0, 448.0, 1.20], [3380.0, 440.0, 1.50],
	]
	for c in fundos:
		_luz(ruinas, "cristais", ref_x, F_RUINAS, c[0], c[1], c[2], magenta)
	var perto: Node2D = alvo._camada("HybridL5_corrupcao", -20, Vector2(0.78, FY))
	var magenta_perto := Color(0.94, 0.42, 0.80, 0.62)
	var pertos := [
		[560.0, 474.0, 1.30], [1220.0, 486.0, 1.05], [1880.0, 470.0, 1.55],
		[2520.0, 482.0, 1.20], [3060.0, 466.0, 1.40], [3600.0, 480.0, 1.10],
	]
	for c in pertos:
		_luz(perto, "cristais", ref_x, 0.78, c[0], c[1], c[2], magenta_perto)

	# --- eixos: dois, fracos e magenta (`lanternas` 0,12) -----------------
	var eixos: Node2D = alvo._camada("HybridL5_eixos", -18, Vector2(0.70, FY))
	for par in [[1200.0, 0.12], [2600.0, 0.10]]:
		_luz(eixos, "eixo_luz", ref_x, 0.70, par[0], 130.0, 2.0,
			Color(0.92, 0.56, 0.86, par[1]))

	# --- 05 primeiro plano: o mais fechado da regiao, quase negro ---------
	var frente: Node2D = alvo._camada("HybridL5_frente", 9, Vector2(F_FRENTE, FY))
	var t5 := Color(0.13, 0.10, 0.17, 0.96)
	var frente_pecas := [
		["ramos", 140.0, 150.0, 1.7, false], ["vinhas", 620.0, 136.0, 2.0, true],
		["ramo_curvo", 1140.0, 158.0, 1.8, false], ["ramos", 1700.0, 148.0, 1.6, true],
		["vinhas", 2240.0, 134.0, 1.9, false], ["ramo_curvo", 2800.0, 156.0, 1.7, true],
		["ramos", 3320.0, 150.0, 1.55, false],
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
