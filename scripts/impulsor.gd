class_name Impulsor
extends Area2D
## Rajada horizontal / tapete de impulso: enquanto a Koliani está lá dentro
## é acelerada para o lado `direcao` até `vel_alvo`. Serve para travessias
## rápidas e para atravessar vãos largos nos percursos. Não magoa. Visual
## em código (setas + partículas). A colisão (retângulo) vem por `@export`.
##
## @export direcao / vel_alvo / largura / altura

## +1 = empurra para a direita.
@export var direcao := 1.0
@export var vel_alvo := 430.0
@export var largura := 260.0 : set = _set_dim
@export var altura := 120.0 : set = _set_dim

var _dentro: Array[Node] = []
var _t := 0.0
var _setas: Node2D
var _col: CollisionShape2D


func _ready() -> void:
	add_to_group("impulsores")
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(func(c: Node) -> void:
		if c is Koliani and c not in _dentro:
			_dentro.append(c))
	body_exited.connect(func(c: Node) -> void:
		_dentro.erase(c))
	_montar()


func _montar() -> void:
	_col = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(largura, altura)
	_col.shape = r
	add_child(_col)

	_setas = Node2D.new()
	add_child(_setas)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var n := maxi(2, int(largura / 60.0))
	for i in n:
		var seta := Polygon2D.new()
		seta.polygon = PackedVector2Array([
			Vector2(-8, -9), Vector2(8, 0), Vector2(-8, 9), Vector2(-3, 0)])
		seta.color = Color(0.6, 0.9, 1.0, 0.5)
		seta.material = m
		seta.position = Vector2(-largura * 0.5 + 30.0 + float(i) * (largura / float(n)), 0.0)
		seta.scale.x = signf(direcao) if direcao != 0.0 else 1.0
		_setas.add_child(seta)


func _set_dim(v: float) -> void:
	v = v  # (setter partilhado)
	if is_node_ready() and _col and _col.shape is RectangleShape2D:
		(_col.shape as RectangleShape2D).size = Vector2(largura, altura)


func _physics_process(dt: float) -> void:
	_t += dt
	if _setas:
		var desl := fmod(_t * 90.0, largura / maxf(1.0, float(_setas.get_child_count())))
		_setas.position.x = signf(direcao) * desl * 0.4
	for k in _dentro:
		if is_instance_valid(k) and "velocity" in k:
			k.velocity.x = move_toward(k.velocity.x, signf(direcao) * vel_alvo, 1400.0 * dt)
