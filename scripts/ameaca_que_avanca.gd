class_name AmeacaQueAvanca
extends Area2D
## A AMEAÇA QUE AVANÇA -- uma parede de morte que atravessa a sala a passo
## constante e não se combate: ou se anda, ou se leva. Nível 65.
##
## É a máquina que o Paulo aceitou fundir: a torre a desabar (N29), a
## avalanche (N42) e a queda longa (N65) eram três nomes para a mesma
## regra. Aqui ela é UMA, com `direcao` e `velocidade` a dar-lhe as caras.
##
## Anti-softlock, e é o ponto delicado desta:
##  - **morre no fim do percurso** (`distancia`), para não seguir a Koliani
##    pelo resto da jornada -- uma ameaça eterna tornava impossível tudo o
##    que viesse a seguir;
##  - **não é sólida** e não empurra: magoa por contacto, com recarga;
##  - **arranca com atraso** (`espera`), para dar tempo de a ler antes de
##    ela morder. Uma parede que já vem a andar quando o ecrã abre não é
##    tensão, é uma morte de graça.
##
## Constrói o próprio corpo e o próprio visual: não precisa de cena.

## Sentido da marcha (normalizado). (1,0) = da esquerda para a direita.
@export var direcao := Vector2(1.0, 0.0)
@export var velocidade := 150.0
## Quanto anda antes de desaparecer, em px.
@export var distancia := 1200.0
## Segundos parada antes de arrancar -- o tempo de a ver chegar.
@export var espera := 1.2
@export var tamanho := Vector2(90.0, 640.0)
@export var dano := 24
@export var recarga := 0.9
@export var cor := Color(0.42, 0.06, 0.52)

var _andado := 0.0
var _cd := 0.0
var _espera := 0.0
var _t := 0.0
var _franjas: Array[Polygon2D] = []


func _ready() -> void:
	_espera = espera
	var col := CollisionShape2D.new()
	var f := RectangleShape2D.new()
	f.size = tamanho
	col.shape = f
	add_child(col)
	monitoring = true
	# a Koliani vive na layer 2 (ver `Armadilha`)
	collision_layer = 0
	collision_mask = 2
	_montar_visual()


func _montar_visual() -> void:
	var h := tamanho * 0.5
	var massa := Polygon2D.new()
	massa.polygon = PackedVector2Array([
		Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	massa.color = Color(cor.r, cor.g, cor.b, 0.88)
	add_child(massa)
	# a frente rasgada, do lado para onde vai: e' o que se le' de longe
	var frente := Polygon2D.new()
	var pts := PackedVector2Array()
	var lado := signf(direcao.x) if direcao.x != 0.0 else 1.0
	var n := 9
	for i in n + 1:
		var t := float(i) / float(n)
		var yy := lerpf(-h.y, h.y, t)
		pts.append(Vector2(lado * (h.x + (18.0 if i % 2 == 0 else 40.0)), yy))
	pts.append(Vector2(lado * h.x, h.y))
	pts.append(Vector2(lado * h.x, -h.y))
	frente.polygon = pts
	frente.color = Color(cor.r * 1.4, cor.g * 1.6, cor.b * 1.3, 0.7)
	add_child(frente)
	_franjas.append(frente)


func _physics_process(dt: float) -> void:
	_t += dt
	_cd = maxf(0.0, _cd - dt)
	# a frente respira: diz que está viva mesmo enquanto espera
	for f in _franjas:
		f.scale.x = 1.0 + 0.14 * sin(_t * 6.0)
	if _espera > 0.0:
		_espera -= dt
		return
	var passo := velocidade * dt
	_andado += passo
	position += direcao.normalized() * passo
	if _andado >= distancia:
		queue_free()
		return
	if _cd > 0.0:
		return
	for c in get_overlapping_bodies():
		if c.has_method("receber_dano"):
			c.receber_dano(dano, signf(direcao.x) if direcao.x != 0.0 else 1.0)
			_cd = recarga
			break
