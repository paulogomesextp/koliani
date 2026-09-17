@tool
extends StaticBody2D
## Plataforma reutilizavel com TERRENO em camadas (packs CC0 -- ver
## assets/sprites/pixel/CREDITS.md). Define `tamanho` e o resto -- colisao e
## visual -- ajusta-se sozinho. `@tool` para dar para ver no editor.
##
## Ate' 3 set 2026 isto era um `NinePatchRect` com um padrao "seamless"
## recolorido: a 4000 px de largura lia-se como um rectangulo chapado, e as
## 6 regioes eram a mesma laje em 6 tons. Agora cada regiao tem o seu
## material (um pack DIFERENTE por regiao, `tools/gerar_terreno.py`) e o
## terreno monta-se em camadas, que e' o que o faz ler como terreno:
##
##   Capa   -- aresta iluminada + silhueta irregular a sobressair do topo
##   Corpo  -- o miolo do material, em mosaico com deslocamento por plataforma
##   Sombra -- degrade que enterra o fundo da plataforma no escuro
##   Lados  -- o corte lateral lascado
##   Franja -- a rocha a esfarelar-se por baixo
##   Pendura -- o que PENDE por baixo: raizes, correntes, estalactites. Sem
##              isto toda a plataforma acaba a direito e le'-se como uma laje
##              a flutuar; e' o que mais aproxima a silhueta de Dead Cells.
##
## Tudo isto vive dentro do no `Visual` (Node2D), porque meia duzia de
## scripts (plataforma_ritmada/espectral/luz, gerador_corredor, vitral...)
## fazem `get_node("Visual").modulate` para desvanecer a plataforma inteira.
##
## O bioma nao se poe plataforma a plataforma: le-se do no do grupo
## "atmosfera" (o raiz de Atmosfera.tscn). Sem esse no, cai em "floresta".

const DIR_TERRENO := "res://assets/sprites/pixel/terreno"
## Execution 9C: na Região I o terreno e os props vêm do kit de produção
## derivado das pranchas aprovadas (ver `regiao1_kit.gd`). Fora dela, o legado.
const Kit := preload("res://scripts/regiao1_kit.gd")
const HybridL1 := preload("res://scripts/l1_hybrid_9h12e.gd")

## Linha da superficie dentro de `topo.png` -- a capa assenta com esta linha
## em cima do topo da colisao, e o que fica acima e' balanco (ver
## `tools/gerar_terreno.py`, constante `folga`).
const SUPERFICIE := 8.0

const BIOMAS := [
	"floresta", "prisao", "torres", "catacumbas", "cidade", "castelo",
	# Regiao II -- Desfiladeiro dos Ventos. Tem material proprio
	# (`tools/gerar_terreno_regiao02.py`) porque o `prisao` era tijolo de
	# cela e o `torres` ja' e' da Regiao III.
	"desfiladeiro",
]

@export var tamanho := Vector2(200.0, 40.0) : set = _set_tamanho
## Altura do visual (0 = igual a colisao). Maior => "slab" de chao grosso
## que desce por baixo da superficie, sem mexer na colisao.
@export var altura_visual := 0.0 : set = _set_altura_visual
## Mantidas por compatibilidade com as cenas de nivel antigas -- o visual
## e agora pixel-art, portanto estas cores sao ignoradas.
@export var cor_base := Color(0.15, 0.21, 0.11)
@export var cor_topo := Color(0.42, 0.62, 0.28)

## Densidade da decoracao: um prop por cada N px de largura. Baixo demais e
## a plataforma fica uma montra; alto demais e volta a ler-se como uma laje.
## (270/5 deixava as plataformas de chao -- que vao a 2000+ px -- com cinco
## props perdidos numa extensao enorme.)
const PASSO_DECO := 190.0
const MAX_DECO := 9

## O mesmo para o que pende por baixo, mas bem mais espacado: uma cortina de
## correntes de lado a lado seria ruido.
const PASSO_PENDURA := 360.0
const MAX_PENDURA := 3
## A espinha da jornada e' toda de degraus de 18 px, e e' precisamente dela
## que se ve' o fundo por baixo -- e' onde a pendura mais faz falta. Mas de um
## degrau fino nao pende uma corrente de 12 elos: so' pecas curtas, uma de
## cada vez.
## 9H.17 H: 16 px deixava pendurar coisas de uma tabua sem corpo nenhum --
## a peca era maior do que o bloco de onde saia. O passe Hybrid do L1 ja'
## usava 34 (`l1_hybrid_9h12e.decorar`); a Regiao I passa a usar o mesmo.
const PENDURA_ALT_MIN := 34.0
## Acima disto a plataforma tem corpo a serio (slab de chao, lasca de rocha).
const PENDURA_ALT_GROSSA := 34.0
## Altura maxima (px) de um prop pendurado num degrau fino.
const PENDURA_H_MAX_FINA := 120.0
## E' preciso limitar tambem a LARGURA: uma estalactite de 115 px debaixo de
## um degrau de 140 le'-se como um pano pendurado, nao como pedra. Fracao
## maxima da largura do degrau que o prop pode ocupar.
const PENDURA_W_MAX_FRAC := 0.45

static var _cache_tex := {}
static var _grad_sombra: GradientTexture2D = null
static var _catalogo: Dictionary = {}       # bioma -> [ {nome, onde, w, h} ]


func _ready() -> void:
	_aplicar()


func _set_tamanho(v: Vector2) -> void:
	tamanho = v
	_aplicar()


func _set_altura_visual(v: float) -> void:
	altura_visual = v
	_aplicar()


## Nome do bioma a usar (do no do grupo "atmosfera"), ou "floresta".
func _nome_bioma() -> String:
	var atm := get_tree().get_first_node_in_group("atmosfera") if is_inside_tree() else null
	if atm and "bioma" in atm and BIOMAS.has(atm.bioma):
		return atm.bioma
	return "floresta"


static func _tex(bioma: String, peca: String) -> Texture2D:
	var chave := "%s/%s" % [bioma, peca]
	if not _cache_tex.has(chave):
		var cam := "%s/%s/%s.png" % [DIR_TERRENO, bioma, peca]
		_cache_tex[chave] = load(cam) if ResourceLoader.exists(cam) else null
	return _cache_tex[chave]


## Degrade transparente -> preto: enterra o fundo da plataforma no escuro.
## E' o truque que faz a plataforma ler como um bloco com volume e nao como
## um autocolante -- em Dead Cells o terreno so' tem luz no primeiro palmo.
static func _sombra() -> GradientTexture2D:
	if _grad_sombra == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.34, 1.0])
		g.colors = PackedColorArray([
			Color(0, 0, 0, 0.0), Color(0.02, 0.01, 0.04, 0.28), Color(0.01, 0.0, 0.02, 0.82),
		])
		_grad_sombra = GradientTexture2D.new()
		_grad_sombra.gradient = g
		_grad_sombra.width = 8
		_grad_sombra.height = 128
		_grad_sombra.fill_from = Vector2(0, 0)
		_grad_sombra.fill_to = Vector2(0, 1)
	return _grad_sombra


## Sprite em mosaico: `regiao` maior que a textura => a textura repete-se.
## O `desloc` desencontra o mosaico de plataforma para plataforma, senao o
## mesmo tijolo cai sempre no mesmo sitio ao longo do nivel.
func _mosaico(tex: Texture2D, pos: Vector2, tam: Vector2, desloc: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(desloc, tam)
	s.position = pos
	return s


## Semente estavel por posicao -- a mesma plataforma fica sempre igual entre
## sessoes (e entre o editor e o jogo), mas duas plataformas nunca coincidem.
func _semente() -> int:
	var ix := int(position.x)
	var iy := int(position.y)
	return absi(ix * 73856093 ^ iy * 19349663) % 100003


func _aplicar() -> void:
	if not is_node_ready():
		return

	var cs := get_node_or_null("Col") as CollisionShape2D
	if cs:
		var r := RectangleShape2D.new()
		r.size = tamanho
		cs.shape = r

	var vis := get_node_or_null("Visual")
	if vis == null:
		return
	for f in vis.get_children():
		f.queue_free()

	var bioma := _nome_bioma()
	var largura: float = tamanho.x
	var alt: float = maxf(tamanho.y, altura_visual)
	var x0 := -largura * 0.5
	var y0 := -tamanho.y * 0.5              # topo da COLISAO (onde se pousa)

	var rng := RandomNumberGenerator.new()
	rng.seed = _semente()
	var dx := float(rng.randi_range(0, 191))
	var dy := float(rng.randi_range(0, 191))

	var kit := Kit.alvo(self)
	# 9H.17 H: o corpo HD e os remates organicos passam a servir tambem o L2.
	# Era o L2 que o Game Master via com "uma laje de rocha por cima e
	# vegetacao a flutuar por baixo": o bloco do kit 9C e' um rectangulo
	# chapado, e a capa de 56 px em cima de uma colisao de 18 le'-se como uma
	# laje pousada. O corpo `terrain_hd` tem silhueta, e o `rematar_bordas`
	# quebra-lhe as pontas com raizes.
	var hybrid_l1: bool = kit != null and HybridL1.serve(int(kit.get("perfil")))
	vis.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if hybrid_l1 else CanvasItem.TEXTURE_FILTER_PARENT_NODE
	var corpo: Texture2D = Kit.terreno(Kit.HD_CORPO, "terreno/terreno_corpo.png") if kit else _tex(bioma, "corpo")
	if hybrid_l1:
		corpo = HybridL1.tex("terrain_hd/corpo")
	if corpo == null:                        # terreno por gerar -> nao pinta nada
		return

	# 9H.17 I3 -- CORPO ORGANICO. Nos perfis Hybrid o bloco deixa de ser um
	# mosaico de `corpo.png` com uma capa por cima: passa a ser a peca
	# `terrain_hd/plataforma.png`, que ja' estava produzida e nunca tinha
	# sido usada, em tres fatias (ponta / meio repetido / ponta espelhada).
	# Traz silhueta irregular, vegetacao EM CIMA e barriga de raiz por baixo
	# -- as tres coisas que o review pedia. As camadas antigas (miolo,
	# sombra, valor, lados, franja, capa, rim) nao entram: eram elas que
	# faziam o rectangulo.
	if hybrid_l1 and HybridL1.corpo_organico(vis, largura, y0, alt):
		HybridL1.decorar(vis, largura, y0, alt, rng)
		return

	# 1. miolo
	vis.add_child(_mosaico(corpo, Vector2(x0, y0), Vector2(largura, alt), Vector2(dx, dy)))

	# 2. sombra de profundidade (por cima do miolo, por baixo de tudo o resto)
	var som := Sprite2D.new()
	som.texture = _sombra()
	som.centered = false
	som.position = Vector2(x0, y0)
	som.scale = Vector2(largura / 8.0, alt / 128.0)
	vis.add_child(som)

	# 2b. VALOR (9H.11, só Região I): um gradiente escuro que afunda a base do
	# bloco. Sem ele, um bloco alto é a mesma amostra repetida 8x e lê-se como
	# uma mancha chapada -- era isto que o QA via nos L1/L3/L5. O gradiente dá
	# o degradê de cima para baixo que a prancha tem e que o mosaico perde.
	if kit and alt >= 40.0:
		var val := Sprite2D.new()
		val.texture = Kit.gradiente_vertical()
		val.centered = false
		val.position = Vector2(x0, y0)
		val.scale = Vector2(largura / 4.0, alt / 128.0)
		# a sombra do bloco tinge-se de violeta com a CORRUPÇÃO do perfil: no
		# L1 a rocha é neutra, no L5 está tomada. É o que faz o clímax da
		# região não ser "o L1 com outro céu".
		var corr := clampf(float(Kit.perfil_de(kit).get("corrupcao", 0.0)) / 1.8, 0.0, 1.0)
		val.modulate = Color(0.06, 0.05, 0.10).lerp(Color(0.20, 0.03, 0.24), corr)
		val.modulate.a = 0.9 + 0.08 * corr
		vis.add_child(val)

	# 3. cortes laterais
	# (o lado do kit tem o contorno na coluna 10: fica 2 px para fora da colisao)
	var lado: Texture2D = Kit.terreno(Kit.HD_LADO, "terreno/terreno_lado.png") if kit else _tex(bioma, "lado")
	if hybrid_l1:
		lado = HybridL1.tex("terrain_hd/lado")
	if lado:
		var lw: float = Kit.LARGURA_LADO if kit else 16.0
		var le := _mosaico(lado, Vector2(x0 - 12.0, y0), Vector2(lw, alt), Vector2(0, dy))
		vis.add_child(le)
		var ld := _mosaico(lado, Vector2(largura * 0.5 + 12.0, y0), Vector2(lw, alt), Vector2(0, dy))
		ld.scale.x = -1.0
		vis.add_child(ld)

	# 4. franja de baixo -- so' quando a plataforma tem corpo que valha a pena
	var base: Texture2D = Kit.terreno(Kit.HD_BASE, "terreno/terreno_base.png") if kit else _tex(bioma, "base")
	if hybrid_l1:
		base = HybridL1.tex("terrain_hd/base")
	if base and alt >= 26.0:
		# a franja do kit comeca 12 px acima do fim do bloco (sao as pedras
		# arredondadas de baixo, nao um remate solto)
		var yb := y0 + alt - (12.0 if kit else 0.0)
		var bh: float = Kit.ALTURA_BASE if kit else 24.0
		vis.add_child(_mosaico(base, Vector2(x0, yb), Vector2(largura, bh), Vector2(dx, 0)))

	# 5. a capa, por cima de tudo (e a sobressair para cima do plano de pouso)
	var topo: Texture2D = Kit.topo(rng) if kit else _tex(bioma, "topo")
	if hybrid_l1:
		topo = HybridL1.tex("terrain_hd/topo")
	if topo:
		var th: float = Kit.ALTURA_TOPO if kit else 32.0
		vis.add_child(_mosaico(topo, Vector2(x0, y0 - SUPERFICIE), Vector2(largura, th), Vector2(dx, 0)))

	# 5b. RIM-LIGHT (9H.11, só Região I): fio de luar frio no lábio da capa. É
	# o que separa o topo do bloco do fundo quando os dois estão no mesmo
	# valor -- a leitura da silhueta que faltava aos blocos altos.
	if kit and topo:
		var rim := Sprite2D.new()
		rim.texture = Kit.gradiente_vertical()
		rim.centered = false
		rim.position = Vector2(x0, y0 - SUPERFICIE + 14.0)
		rim.scale = Vector2(largura / 4.0, -14.0 / 128.0)
		var mat_rim := CanvasItemMaterial.new()
		mat_rim.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		rim.material = mat_rim
		rim.modulate = Color(0.42, 0.50, 0.82, 0.34)
		vis.add_child(rim)

	# 6. o que POUSA em cima -- cogumelos, lapides, caixotes, cristais...
	# 7. o que PENDE por baixo -- raizes, correntes, estalactites
	if kit:
		if hybrid_l1:
			HybridL1.decorar(vis, largura, y0, alt, rng)
			return
		Kit.decorar(vis, largura, y0, rng, Kit.perfil_de(kit))
		# 9H.17 H -- o LABIO VISIVEL, e nao o fundo da colisao. A capa desce
		# ate' `y0 - SUPERFICIE + ALTURA_TOPO` e a franja ate' `y0 + alt +
		# ALTURA_BASE - 12`: num degrau de 18 px de colisao isso sao mais 30
		# px de pedra desenhada. Pendurar pelo fundo da colisao punha a peca
		# a nascer 30 px acima do sitio onde a pedra acaba -- e o que se via
		# era a ponta solta, a flutuar debaixo de uma laje.
		var labio: float = y0 + alt
		if alt >= 26.0:
			labio = maxf(labio, y0 + alt + Kit.ALTURA_BASE - 12.0)
		labio = maxf(labio, y0 - SUPERFICIE + Kit.ALTURA_TOPO)
		if alt >= PENDURA_ALT_MIN:
			Kit.pendurar(vis, largura, labio, alt >= PENDURA_ALT_GROSSA, rng)
		return
	_decorar(vis, bioma, largura, y0, rng)
	if alt >= PENDURA_ALT_MIN:
		_pendurar(vis, bioma, largura, y0 + alt, alt >= PENDURA_ALT_GROSSA, rng)


## Os props da regiao que assentam num sitio ("chao" / "parede" / "pendurado").
static func _props_de(bioma: String, onde: String) -> Array:
	var r: Array = []
	for p in _props(bioma):
		if p is Dictionary and p.get("onde", "") == onde:
			r.append(p)
	return r


## Catalogo de props da regiao (`tools/gerar_deco.py`), lido uma vez.
static func _props(bioma: String) -> Array:
	if _catalogo.is_empty():
		var cam := "res://assets/sprites/pixel/deco/deco.json"
		if FileAccess.file_exists(cam):
			var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(cam))
			if d is Dictionary:
				_catalogo = d
		if _catalogo.is_empty():
			_catalogo = {"_": []}     # marca como "ja' tentei", nao volta ao disco
	var l: Variant = _catalogo.get(bioma, [])
	return l if l is Array else []


## Espalha props de chao pela superficie da plataforma.
##
## O objectivo nao e' encher: e' que duas plataformas nunca tenham a mesma
## coisa em cima. Por isso a semente vem da posicao (ver `_semente`) e cada
## prop leva escala e espelho proprios.
func _decorar(vis: Node, bioma: String, largura: float, y0: float, rng: RandomNumberGenerator) -> void:
	if largura < 110.0:
		return
	var chao := _props_de(bioma, "chao")
	if chao.is_empty():
		return

	var quantos: int = mini(MAX_DECO, int(largura / PASSO_DECO))
	if quantos <= 0:
		quantos = 1 if rng.randf() < 0.55 else 0     # ledges curtas: as vezes
	var margem := 30.0
	var util := largura - margem * 2.0
	if util <= 0.0:
		return

	for i in quantos:
		var p: Dictionary = chao[rng.randi() % chao.size()]
		var cam := "res://assets/sprites/pixel/deco/%s/%s.png" % [bioma, p["nome"]]
		var tex: Texture2D = load(cam) if ResourceLoader.exists(cam) else null
		if tex == null:
			continue
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		var e := rng.randf_range(0.86, 1.14)
		s.scale = Vector2(e if rng.randf() < 0.5 else -e, e)
		# a faixa de cada prop, com folga, para nao se empilharem todos a meio
		var faixa := util / float(maxi(1, quantos))
		var cx := -largura * 0.5 + margem + faixa * (float(i) + rng.randf_range(0.15, 0.85))
		# enterra 3 px na capa: os props nunca devem parecer colados por cima
		s.position = Vector2(cx, y0 - tex.get_height() * e + 3.0)
		if s.scale.x < 0.0:
			s.position.x += tex.get_width() * e
		s.z_index = -1                 # atras da Koliani e dos inimigos
		vis.add_child(s)


## Pendura props por baixo da plataforma (`y_base` = o fundo do visual).
##
## Ao contrario dos de chao, estes entram ATRAS do terreno (`z_index = -2`):
## o topo do prop fica escondido pela franja, e portanto nunca se ve' onde e'
## que ele foi colado. E' o que faz a raiz parecer nascer de dentro da rocha
## em vez de estar pousada na aresta.
func _pendurar(vis: Node, bioma: String, largura: float, y_base: float,
		grossa: bool, rng: RandomNumberGenerator) -> void:
	if largura < 90.0:
		return
	var lista := _props_de(bioma, "pendurado")
	if not grossa:
		# degrau fino: so' pecas curtas E estreitas (musgo, colmeia, corrente
		# pequena) -- uma estalactite de 300 px a sair de uma tabua de 18 nao
		# cola, e uma de 115 debaixo de um degrau de 140 tapa-o todo
		var w_max := largura * PENDURA_W_MAX_FRAC
		var curtos: Array = []
		for p in lista:
			if float(p.get("h", 999.0)) <= PENDURA_H_MAX_FINA 					and float(p.get("w", 999.0)) <= w_max:
				curtos.append(p)
		lista = curtos
	if lista.is_empty():
		return

	var quantos: int = mini(MAX_PENDURA, int(largura / PASSO_PENDURA))
	if not grossa:
		# nos degraus e' um toque, nao uma cortina: no maximo um, e nem sempre
		quantos = 1 if rng.randf() < 0.5 else 0
	elif quantos <= 0:
		quantos = 1 if rng.randf() < 0.4 else 0     # plataformas curtas: as vezes
	if quantos <= 0:
		return

	var margem := 44.0 if grossa else 20.0
	var util := largura - margem * 2.0
	if util <= 0.0:
		return
	var faixa := util / float(quantos)

	for i in quantos:
		var p: Dictionary = lista[rng.randi() % lista.size()]
		var cam := "res://assets/sprites/pixel/deco/%s/%s.png" % [bioma, p["nome"]]
		var tex: Texture2D = load(cam) if ResourceLoader.exists(cam) else null
		if tex == null:
			continue
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		var e := rng.randf_range(0.80, 1.20) if grossa else rng.randf_range(0.55, 0.85)
		s.scale = Vector2(e if rng.randf() < 0.5 else -e, e)
		var cx := -largura * 0.5 + margem + faixa * (float(i) + rng.randf_range(0.1, 0.9))
		# enterra na franja -- o ponto de agarre nunca fica a' vista. Num
		# degrau fino ha' menos onde enterrar.
		var fundura := rng.randf_range(10.0, 22.0) if grossa else rng.randf_range(5.0, 10.0)
		s.position = Vector2(cx, y_base - fundura)
		if s.scale.x < 0.0:
			s.position.x += tex.get_width() * e
		s.z_index = -2                 # ATRAS do terreno e dos actores
		vis.add_child(s)
