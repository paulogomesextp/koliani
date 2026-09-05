class_name BlocoEmpurravel
extends CharacterBody2D
## Caixa que se **empurra** para chegar onde não se chega de outra maneira.
##
## Duas linhas do catálogo do Paulo de uma vez ("mover caixas para alcançar
## locais" e "objetos para colocar em pedestais"): a caixa é o degrau, e a
## `PlacaPeso` que vem a seguir neste ficheiro é o pedestal.
##
## É um `CharacterBody2D` e não um `RigidBody2D` de propósito: com física a
## sério a caixa saltava, rodava e acabava sempre por cair no líquido
## mortal. Aqui só faz duas coisas -- é empurrada na horizontal e cai a
## direito -- e por isso nunca faz nada que o nível não previu.
##
## Anti-softlock: a caixa **volta ao sítio** se cair fora do mundo ou se for
## empurrada para lá do limite da sala (`limite_x`), senão um empurrão a
## mais deixava o nível por acabar.

@export var tamanho := Vector2(44.0, 44.0)
## Quanto é que ela a empurra por segundo (a Koliani anda a ~240).
@export var vel_empurrao := 105.0
## Meia largura da zona onde a caixa pode viver, à volta do sítio inicial.
@export var limite_x := 900.0
@export var cor := Color(0.42, 0.32, 0.22)

const GRAVIDADE := 1400.0

var _casa := Vector2.ZERO
var _sensor: Area2D


func _ready() -> void:
	add_to_group("blocos")
	collision_layer = 1        # é chão: ela pode subir para cima da caixa
	collision_mask = 1         # só o mundo -- não empurra inimigos
	_casa = global_position
	_montar()


func _montar() -> void:
	var col := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = tamanho
	col.shape = r
	add_child(col)

	var hx := tamanho.x * 0.5
	var hy := tamanho.y * 0.5
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)])
	vis.color = cor
	add_child(vis)
	# as duas cintas de ferro: sem elas é um quadrado castanho e não se lê
	# como caixa
	for dy in [-hy * 0.42, hy * 0.42]:
		var cinta := Polygon2D.new()
		cinta.polygon = PackedVector2Array([
			Vector2(-hx, dy - 3.0), Vector2(hx, dy - 3.0),
			Vector2(hx, dy + 3.0), Vector2(-hx, dy + 3.0)])
		cinta.color = cor.darkened(0.4)
		add_child(cinta)

	# quem empurra é ELA, e a Koliani está na layer 2
	_sensor = Area2D.new()
	_sensor.collision_layer = 0
	_sensor.collision_mask = 2
	var sc := CollisionShape2D.new()
	var sr := RectangleShape2D.new()
	sr.size = Vector2(tamanho.x + 22.0, tamanho.y * 0.8)
	sc.shape = sr
	_sensor.add_child(sc)
	add_child(_sensor)


func _physics_process(dt: float) -> void:
	velocity.x = 0.0
	# ⚠ NÃO se lê a `velocity` dela. Quando ela encosta à caixa o
	# `move_and_slide` zera-lhe a componente x no mesmo frame -- a caixa
	# via velocidade zero e nunca andava. É a DIREÇÃO PEDIDA que conta, e
	# essa está no `InputMap` (o mesmo sítio de onde vem o joystick do
	# telemóvel, portanto isto funciona igual nos dois).
	var pedida := 0.0
	if InputMap.has_action("mover_direita"):
		pedida = Input.get_axis("mover_esquerda", "mover_direita")
	for c in _sensor.get_overlapping_bodies():
		var n := c as Node2D
		if n == null or not n.is_in_group("koliani"):
			continue
		# só empurra quem está encostado ao lado certo e a pedir para lá
		var dx: float = global_position.x - n.global_position.x
		if absf(dx) > tamanho.x * 0.35 and signf(dx) == signf(pedida) 				and absf(pedida) > 0.4:
			velocity.x = signf(dx) * vel_empurrao
	if not is_on_floor():
		velocity.y += GRAVIDADE * dt
	else:
		velocity.y = 0.0
	move_and_slide()

	# a rede: fora do mundo ou empurrada de mais, volta a casa
	if absf(global_position.x - _casa.x) > limite_x \
			or global_position.y > _casa.y + 1400.0:
		global_position = _casa
		velocity = Vector2.ZERO
