class_name AguaVenenosa
extends Armadilha
## Poça de água/lodo venenoso -- morte instantânea ao toque. Mecânica
## partilhada da região I (Pântano dos Sussurros) e reutilizável como
## "fosso líquido" noutros biomas (lava, ácido) trocando só as cores.
##
## Uso: instanciar, pousar em `global_position` (o centro da poça) e pôr
## `largura`/`altura` em pixéis. A forma de colisão e a superfície visual
## (Polygon2D translúcido com uma ondulação lenta) montam-se sozinhas.

@export var largura := 320.0 : set = _set_largura
@export var altura := 120.0 : set = _set_altura
## Cor da superfície (a metade de cima é mais clara).
@export var cor := Color(0.3, 0.62, 0.36, 0.9) : set = _set_cor
## Variante "lava": brasas a subir + superfície mais quente/luminosa
## (Fornalha dos Pecadores). Sem isto é a poça de veneno normal.
@export var brasas := false

## Comprimento de uma vaga da linha de água. O perfil é construído com uma
## vaga a mais de cada lado, para o `_process` o poder deslizar sem que as
## pontas descubram o fosso.
const VAGA := 168.0
## Quantos segmentos tem cada vaga (mais = onda mais lisa, mais vértices).
const SEG_VAGA := 6

var _forma: CollisionShape2D
var _sup: Polygon2D
var _rim: Polygon2D
## Faixa de degradê logo abaixo da linha de água: leva a cor do perigo a
## esbater-se no escuro. Sem ela, um fosso alto (o "Vazio" das torres, o
## abismo das catacumbas) lia-se como um retângulo preto chapado.
var _faixa: Polygon2D
var _luz: PointLight2D
## Energia de repouso da luz da linha de água (o `_process` pulsa à volta
## dela). Fica aqui porque muda com a variante `brasas`.
var _luz_base := 0.45
var _t := 0.0


var _brasas_no: CPUParticles2D


func _pronto() -> void:
	dano = 999  # >= vida máxima da Koliani -> _morrer()
	_forma = $CollisionShape2D
	_sup = $Superficie
	_rim = get_node_or_null("Rebordo")
	_luz = get_node_or_null("Luz")
	if not brasas:
		_faixa = Polygon2D.new()
		_faixa.name = "Faixa"
		add_child(_faixa)
		move_child(_faixa, _sup.get_index() + 1)  # entre a Superficie e o Rebordo
	if brasas:
		_montar_brasas()
	else:
		_montar_bruma()
	_reconstruir()


## Brasas que sobem da lava (só na variante `brasas`).
func _montar_brasas() -> void:
	_brasas_no = CPUParticles2D.new()
	_brasas_no.amount = 34
	_brasas_no.lifetime = 2.6
	_brasas_no.local_coords = false
	_brasas_no.direction = Vector2(0, -1)
	_brasas_no.spread = 18.0
	_brasas_no.gravity = Vector2(0, -46)
	_brasas_no.initial_velocity_min = 20.0
	_brasas_no.initial_velocity_max = 70.0
	_brasas_no.scale_amount_min = 1.5
	_brasas_no.scale_amount_max = 3.5
	_brasas_no.color = Color(1.0, 0.6, 0.2, 0.9)
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	ramp.colors = PackedColorArray([
		Color(1.0, 0.85, 0.4, 0.0), Color(1.0, 0.55, 0.15, 0.9), Color(0.5, 0.1, 0.05, 0.0),
	])
	_brasas_no.color_ramp = ramp
	add_child(_brasas_no)


## Bruma tóxica lenta a subir da linha de água (variante veneno/ácido). Dá
## vida à superfície -- sem isto lê-se como um retângulo pintado.
func _montar_bruma() -> void:
	_brasas_no = CPUParticles2D.new()
	_brasas_no.amount = 30
	_brasas_no.lifetime = 3.4
	_brasas_no.local_coords = false
	_brasas_no.direction = Vector2(0, -1)
	_brasas_no.spread = 26.0
	_brasas_no.gravity = Vector2(0, -16)
	_brasas_no.initial_velocity_min = 8.0
	_brasas_no.initial_velocity_max = 26.0
	_brasas_no.scale_amount_min = 2.5
	_brasas_no.scale_amount_max = 6.0
	var c := cor.lightened(0.3)
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	ramp.colors = PackedColorArray([
		Color(c.r, c.g, c.b, 0.0), Color(c.r, c.g, c.b, 0.42), Color(c.r, c.g, c.b, 0.0),
	])
	_brasas_no.color_ramp = ramp
	add_child(_brasas_no)


func _process(dt: float) -> void:
	if _sup == null:
		return
	_t += dt
	# A onda em si é geometria FIXA (construída uma vez em `_reconstruir`,
	# uma vaga a mais de cada lado); animar é só deslizá-la na horizontal
	# dentro de um comprimento de onda. Sai muito mais barato do que
	# reconstruir 90 vértices por frame numa poça de 4000 px.
	var desl := fmod(_t * 14.0, VAGA)
	var onda := sin(_t * 1.6) * 2.0
	_sup.position = Vector2(-desl, onda)
	if _rim:
		_rim.position = Vector2(-desl, onda)
		_rim.modulate.a = 0.7 + 0.3 * sin(_t * 2.0 + 1.0)
	if _faixa:
		_faixa.position.y = onda
	if _luz:
		_luz.energy = _luz_base * (1.0 + 0.2 * sin(_t * 2.6))


## Perfil da linha de água: da esquerda para a direita, com uma vaga a mais
## de cada lado. Duas frequências (uma vaga larga + uma ondulação curta em
## contratempo) para o olho não apanhar o período.
func _perfil(hw: float, hh: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var x0 := -hw - VAGA
	var x1 := hw + VAGA
	var passo := VAGA / float(SEG_VAGA)
	var x := x0
	while x < x1 + passo * 0.5:
		var f := minf(x, x1) / VAGA * TAU
		var y := sin(f) * 3.2 + sin(f * 2.37 + 1.1) * 1.8
		pts.append(Vector2(minf(x, x1), -hh + y))
		x += passo
	return pts


func _set_largura(v: float) -> void:
	largura = maxf(16.0, v)
	if is_node_ready():
		_reconstruir()


func _set_altura(v: float) -> void:
	altura = maxf(16.0, v)
	if is_node_ready():
		_reconstruir()


func _set_cor(v: Color) -> void:
	cor = v
	if is_node_ready():
		_reconstruir()


func _reconstruir() -> void:
	if _forma == null or _sup == null:
		return
	var r := RectangleShape2D.new()
	r.size = Vector2(largura, altura)
	_forma.shape = r
	_forma.position = Vector2.ZERO
	var hw := largura * 0.5
	var hh := altura * 0.5

	# --- a LINHA DE ÁGUA deixa de ser uma linha ---------------------------
	# Estas poças chegam a ter 4200 px de largura: a aresta a direito lia-se
	# como uma fita de plástico colada ao ecrã, e era o que mais destoava em
	# todos os níveis. Agora o topo é uma onda (duas frequências, para não
	# marcar o período), construída com uma vaga a mais de cada lado para o
	# `_process` a poder deslizar sem descobrir as pontas.
	var topo := _perfil(hw, hh)

	var pol := topo.duplicate()
	pol.append(Vector2(hw + VAGA, hh))
	pol.append(Vector2(-hw - VAGA, hh))
	_sup.polygon = pol

	# CORPO do líquido: fica ESCURO e dessaturado (senão o verde do ácido
	# lia-se como relva). Só a linha de água (`_rim`) é que dá o perigo.
	# A lava é a exceção -- essa brilha mesmo.
	var c_topo: Color
	var c_baixo: Color
	if brasas:
		c_topo = cor.lightened(0.2)
		c_baixo = cor.darkened(0.72)
		_sup.color = cor
	else:
		var escuro := Color(cor.r, cor.g, cor.b).darkened(0.62)
		escuro = escuro.lerp(Color(0.03, 0.03, 0.05), 0.5)   # puxa para o vazio
		c_topo = escuro.lightened(0.10)
		c_baixo = escuro.darkened(0.78)
		_sup.color = escuro
	var cores := PackedColorArray()
	for _i in topo.size():
		cores.append(c_topo)
	cores.append(c_baixo)
	cores.append(c_baixo)
	_sup.vertex_colors = cores
	# faixa de degradê por baixo da linha de água: a cor do perigo esbate-se
	# no escuro em vez de o fosso ser um retângulo preto chapado. Quanto mais
	# fundo o fosso, mais alta a faixa (até 260px).
	if _faixa:
		# Halo curto por baixo da linha de água: o perigo tinge os primeiros
		# palmos e depois é escuro. Era daqui que vinha a "barra chapada" --
		# tinha 300 px de altura e alfa até 0.85, e numa poça larga tomava um
		# terço do ecrã. Agora é curto e discreto: quem dá o aviso é a linha.
		var fundura: float = clampf(altura / 420.0, 0.3, 1.0)
		var fh: float = clampf(altura * 0.30, 56.0, 130.0)
		_faixa.polygon = PackedVector2Array([
			Vector2(-hw, -hh), Vector2(hw, -hh),
			Vector2(hw, -hh + fh), Vector2(-hw, -hh + fh),
		])
		var t_cor := cor.lightened(0.15 + 0.2 * fundura)
		t_cor.a = 0.16 + 0.16 * fundura
		var baixo := Color(t_cor.r, t_cor.g, t_cor.b, 0.0)
		_faixa.color = Color(1, 1, 1, 1)
		_faixa.vertex_colors = PackedColorArray([t_cor, t_cor, baixo, baixo])
	# espuma acesa a acompanhar a onda -- é ela que diz "não caias aqui"
	if _rim:
		var esp := PackedVector2Array()
		for p in topo:
			esp.append(p + Vector2(0.0, -3.0))
		for i in range(topo.size() - 1, -1, -1):
			esp.append(topo[i] + Vector2(0.0, 8.0))
		_rim.polygon = esp
		var rc := cor.lightened(0.4) if brasas else cor.lightened(0.7)
		_rim.color = Color(rc.r, rc.g, rc.b, 0.6 if brasas else 0.95)
		_rim.vertex_colors = PackedColorArray()
	if _luz:
		_luz.position = Vector2(0.0, -hh)
		# a luz da linha de agua toma a COR DO LIQUIDO (vinha sempre verde do
		# .tscn) e fica fraca -- serve para marcar a superficie, nao para
		# pintar o fundo do ecra
		_luz.color = cor.lightened(0.35)
		_luz_base = 0.45
		if brasas:
			_luz_base = 0.9
			_luz.color = Color(1.0, 0.5, 0.18)
			_luz.scale = Vector2(clampf(largura / 150.0, 1.6, 5.0), 1.8)
	if _brasas_no:
		_brasas_no.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		_brasas_no.emission_rect_extents = Vector2(hw, 6.0)
		_brasas_no.position = Vector2(0.0, -hh)
