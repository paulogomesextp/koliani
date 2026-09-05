class_name Ceifa
extends Area2D
## CEIFA: uma linha que varre a arena de um lado ao outro, sempre à mesma
## altura. Nível 75, Trono da Morte.
##
## Não é um pêndulo (que descreve um arco e tem cantos onde não chega) nem
## uma prensa (que é sólida e empurra): é uma lâmina rasa que atravessa a
## sala INTEIRA e só se evita saltando por cima. Por isso nunca bloqueia --
## atravessa a Koliani e magoa, e volta a passar.
##
## Constrói a própria área e o próprio visual: não precisa de cena.

## Distância que percorre, em px (de ponta a ponta, centrada em `position`).
@export var curso := 600.0
@export var altura_lamina := 14.0
## Segundos de uma passagem completa (ida). Volta no mesmo tempo.
@export var periodo := 2.8
## Segundos parada em cada ponta -- é o telégrafo: dá para ver de que lado
## vem antes de arrancar.
@export var pausa := 0.55
@export var dano := 18
@export var cor := Color(0.86, 0.90, 1.0)

var _t := 0.0
var _lamina: Node2D
var _area_forma: CollisionShape2D
var _cd_dano := 0.0


func _ready() -> void:
	_area_forma = CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = Vector2(46.0, altura_lamina)
	_area_forma.shape = forma
	add_child(_area_forma)
	monitoring = true
	# A Koliani vive na layer 2 (ver `Armadilha`): sem isto a area ficava
	# com a mascara de omissao (layer 1, o mundo) e NUNCA a apanhava.
	collision_layer = 0
	collision_mask = 2

	_lamina = Node2D.new()
	_lamina.name = "Lamina"      # a bancada procura-a por nome
	add_child(_lamina)
	var corpo := Polygon2D.new()
	var h := altura_lamina * 0.5
	corpo.polygon = PackedVector2Array([
		Vector2(-23.0, -h), Vector2(23.0, -h * 0.4),
		Vector2(23.0, h * 0.4), Vector2(-23.0, h)])
	corpo.color = cor
	_lamina.add_child(corpo)
	var fio := Line2D.new()
	fio.points = PackedVector2Array([Vector2(-23.0, -h), Vector2(23.0, -h * 0.4)])
	fio.width = 2.0
	fio.default_color = Color(1, 1, 1, 0.9)
	_lamina.add_child(fio)
	# o rasto: diz de que lado ela vem antes de lá chegar
	var rasto := Line2D.new()
	rasto.points = PackedVector2Array([
		Vector2(-curso * 0.5, 0.0), Vector2(curso * 0.5, 0.0)])
	rasto.width = 2.0
	rasto.default_color = Color(cor.r, cor.g, cor.b, 0.16)
	rasto.z_index = -1
	add_child(rasto)
	_pos(0.0)


func _pos(u: float) -> void:
	var x := lerpf(-curso * 0.5, curso * 0.5, u)
	if _lamina:
		_lamina.position.x = x
	if _area_forma:
		_area_forma.position.x = x


func _physics_process(dt: float) -> void:
	_cd_dano = maxf(0.0, _cd_dano - dt)
	_t += dt
	var ciclo := (periodo + pausa) * 2.0
	var t := fmod(_t, ciclo)
	if t < periodo:
		_pos(t / periodo)
	elif t < periodo + pausa:
		_pos(1.0)
	elif t < periodo * 2.0 + pausa:
		_pos(1.0 - (t - periodo - pausa) / periodo)
	else:
		_pos(0.0)
	if _cd_dano > 0.0:
		return
	for c in get_overlapping_bodies():
		if c.has_method("receber_dano"):
			c.receber_dano(dano, signf(c.global_position.x - global_position.x))
			_cd_dano = 0.6
			break
