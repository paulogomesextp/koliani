class_name ChefeElemental
extends ChefeGenerico
## Variantes próprias para o lote VII: magma, forja e dragão de lava.
@export_enum("magma", "forja", "dragao") var forma := "magma"
var _t := 0.0
var _cd := 0.0

func _ready() -> void:
	rig = ""
	textura = null
	super._ready()
	var corpo := get_node_or_null("Sprite/Corpo") as Sprite2D
	if corpo: corpo.visible = false
	var anim := get_node_or_null("Sprite/Anim") as AnimatedSprite2D
	if anim: anim.visible = false
	queue_redraw()

func _process(dt: float) -> void:
	_t += dt; _cd -= dt
	if _cd <= 0.0:
		_cd = 1.0 if forma == "dragao" else 1.35
		_ataque_elemental()
	queue_redraw()

func _draw() -> void:
	var c := Color("ff4a18") if forma == "magma" else Color("ff9b28") if forma == "forja" else Color("d92338")
	var esc := Color("35131c")
	if forma == "dragao":
		draw_colored_polygon(PackedVector2Array([Vector2(-58,20),Vector2(-30,-34),Vector2(0,-60),Vector2(30,-34),Vector2(58,20),Vector2(30,48),Vector2(-30,48)]), esc)
		draw_colored_polygon(PackedVector2Array([Vector2(-30,-34),Vector2(0,-92),Vector2(30,-34)]), c)
		draw_line(Vector2(0,-60), Vector2(62,-76), c, 8)
	else:
		draw_circle(Vector2(0,-42), 25, esc)
		draw_colored_polygon(PackedVector2Array([Vector2(-34,-22),Vector2(34,-22),Vector2(28,40),Vector2(-28,40)]), esc)
		draw_colored_polygon(PackedVector2Array([Vector2(-28,38),Vector2(28,38),Vector2(20,66),Vector2(-20,66)]), c)
		draw_circle(Vector2(-9,-45), 5, c); draw_circle(Vector2(9,-45), 5, c)
	if forma == "forja": draw_line(Vector2(22,-12),Vector2(72,-12),Color("ffe1a0"),10)

func _ataque_elemental() -> void:
	var k := get_tree().get_first_node_in_group("koliani")
	if k == null or global_position.distance_to(k.global_position) > 760.0: return
	var pai := get_parent(); if pai == null: return
	var a := Area2D.new(); a.collision_layer=0; a.collision_mask=2; a.global_position=global_position+Vector2(randf_range(-28,28),20); pai.add_child(a)
	var s:=CollisionShape2D.new(); var r:=CircleShape2D.new(); r.radius=11; s.shape=r; a.add_child(s)
	var p:=Polygon2D.new(); p.polygon=PackedVector2Array([Vector2(0,-12),Vector2(10,8),Vector2(0,14),Vector2(-10,8)]); p.color=Color("ff541e"); a.add_child(p)
	a.body_entered.connect(func(b:Node)->void: if b.is_in_group("koliani"): b.receber_dano(14,0.0); a.queue_free())
	var tw:=a.create_tween(); tw.tween_property(a,"global_position",a.global_position+Vector2(randf_range(-160,160),380),1.0); tw.tween_callback(a.queue_free)
