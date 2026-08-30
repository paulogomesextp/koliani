class_name Trampolim
extends Area2D
## Almofada de salto: a Koliani toca por cima e é atirada para cima com
## `impulso` (bem mais que um salto normal). Serve para subir entre patamares
## nos percursos. Devolve também o salto do ar. Visual em código.
##
## @export impulso / horizontal

## Velocidade vertical dada (px/s). Salto normal da Koliani = 470.
@export var impulso := 780.0
## Empurrão horizontal opcional (para atirar na diagonal para uma plataforma).
@export var horizontal := 0.0

var _cd := 0.0
var _t := 0.0
var _almofada: Polygon2D
var _base_y := 0.0


func _ready() -> void:
	add_to_group("trampolins")
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_ao_tocar)
	if get_node_or_null("Col") == null:
		var cs := CollisionShape2D.new()
		cs.name = "Col"
		var r := RectangleShape2D.new()
		r.size = Vector2(56.0, 20.0)
		cs.shape = r
		cs.position = Vector2(0, -8.0)
		add_child(cs)
	_montar()


func _montar() -> void:
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-30, 4), Vector2(30, 4), Vector2(24, 14), Vector2(-24, 14)])
	base.color = Color(0.18, 0.16, 0.2)
	add_child(base)
	_almofada = Polygon2D.new()
	_almofada.polygon = PackedVector2Array([
		Vector2(-28, -8), Vector2(28, -8), Vector2(30, 4), Vector2(-30, 4)])
	_almofada.color = Color(0.85, 0.35, 1.0)
	add_child(_almofada)
	_base_y = _almofada.position.y
	var risca := Line2D.new()
	risca.points = PackedVector2Array([Vector2(-26, -8), Vector2(26, -8)])
	risca.width = 3.0
	risca.default_color = Color(1, 1, 1, 0.8)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	risca.material = m
	_almofada.add_child(risca)


func _process(dt: float) -> void:
	_cd = maxf(0.0, _cd - dt)
	if _almofada:
		# recolhe depressa depois do impacto, volta devagar
		_almofada.position.y = move_toward(_almofada.position.y, _base_y, dt * 60.0)


func _ao_tocar(corpo: Node) -> void:
	if _cd > 0.0 or not (corpo is Koliani):
		return
	var k := corpo as Node2D
	# só se vier de cima / a cair (não a subir já depressa)
	if "velocity" in k and k.velocity.y < -60.0:
		return
	_cd = 0.25
	if "velocity" in k:
		k.velocity.y = -impulso
		if horizontal != 0.0:
			k.velocity.x = horizontal
	if k.has_method("devolver_saltos_ar"):
		k.devolver_saltos_ar()
	if _almofada:
		_almofada.position.y = _base_y + 8.0
	Som.toca("salto_duplo", -8.0, 0.8)
