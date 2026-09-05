class_name Serpente
extends Node2D
## SERPENTE DO MAR: um obstáculo COMPRIDO em movimento contínuo. Nível 77.
##
## A diferença para tudo o resto que magoa na jornada é a forma: uma serra
## é um ponto, uma guilhotina é uma linha vertical, uma prensa é uma
## parede. Esta é uma CURVA que atravessa a sala inteira e que nunca está
## duas vezes no mesmo sítio -- não se decora, lê-se.
##
## São `n` anéis a seguir o mesmo caminho com atraso entre eles (como uma
## cauda a seguir a cabeça). O caminho é uma onda: horizontal ao longo de
## `curso`, vertical em seno. Cada anel magoa por contacto e nenhum é
## sólido -- nunca bloqueia a passagem, é a lei da jornada.
##
## Constrói o próprio corpo e o próprio visual: não precisa de cena.

## Comprimento do percurso horizontal, em px.
@export var curso := 620.0
## Altura da onda, em px.
@export var onda := 90.0
## Segundos de uma travessia completa (ida). Volta no mesmo tempo.
@export var periodo := 4.0
## Quantos anéis (o primeiro é a cabeça).
@export var aneis := 7
## Distância entre anéis, em fração do percurso.
@export var atraso := 0.045
@export var dano := 18
@export var cor := Color(0.30, 0.62, 0.42)

var _t := 0.0
var _partes: Array[Area2D] = []
var _cd := 0.0


func _ready() -> void:
	for i in maxi(2, aneis):
		var a := Area2D.new()
		# a Koliani vive na layer 2 (ver `Armadilha`)
		a.collision_layer = 0
		a.collision_mask = 2
		var col := CollisionShape2D.new()
		var f := CircleShape2D.new()
		f.radius = 15.0 if i > 0 else 19.0
		col.shape = f
		a.add_child(col)
		_montar_anel(a, i)
		add_child(a)
		_partes.append(a)
	_colocar()


func _montar_anel(a: Area2D, i: int) -> void:
	var r := 15.0 if i > 0 else 19.0
	var corpo := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 10:
		var ang := TAU * float(k) / 10.0
		pts.append(Vector2(cos(ang), sin(ang)) * r)
	corpo.polygon = pts
	# a cauda vai escurecendo: dá o sentido da marcha sem precisar de setas
	var f := 1.0 - 0.5 * float(i) / float(maxi(1, aneis))
	corpo.color = Color(cor.r * f, cor.g * f, cor.b * f)
	a.add_child(corpo)
	if i == 0:
		for lado in [-1.0, 1.0]:
			var olho := Polygon2D.new()
			var op := PackedVector2Array()
			for k in 6:
				var ang := TAU * float(k) / 6.0
				op.append(Vector2(cos(ang), sin(ang)) * 3.0
					+ Vector2(6.0, lado * 6.0))
			olho.polygon = op
			olho.color = Color(1.0, 0.85, 0.3)
			a.add_child(olho)
	else:
		# barbatana dorsal em cada anel do corpo
		var bar := Polygon2D.new()
		bar.polygon = PackedVector2Array([
			Vector2(-6.0, -r), Vector2(6.0, -r), Vector2(0.0, -r - 9.0)])
		bar.color = Color(cor.r * 0.6, cor.g * 0.6, cor.b * 0.6)
		a.add_child(bar)


## Posição no percurso para uma fração `u` de 0 a 1 (e volta).
func _ponto(u: float) -> Vector2:
	var v := fmod(maxf(u, 0.0), 2.0)
	var ida := v if v <= 1.0 else 2.0 - v
	return Vector2(lerpf(-curso * 0.5, curso * 0.5, ida),
		sin(ida * TAU * 1.5) * onda)


func _colocar() -> void:
	var base := _t / maxf(0.1, periodo)
	for i in _partes.size():
		_partes[i].position = _ponto(base - atraso * float(i))


func _physics_process(dt: float) -> void:
	_t += dt
	_cd = maxf(0.0, _cd - dt)
	_colocar()
	if _cd > 0.0:
		return
	for a in _partes:
		for c in a.get_overlapping_bodies():
			if c.has_method("receber_dano"):
				c.receber_dano(dano,
					signf(c.global_position.x - a.global_position.x))
				_cd = 0.7
				return
