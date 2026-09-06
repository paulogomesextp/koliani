class_name ChefeOceanico
extends ChefeGenerico
## Bosses próprios do lote VII/VIII: formas e ataques de água/energia.
@export_enum("estrela", "capitao", "leviata", "nereia", "devorador", "abismo") var forma := "estrela"
var _t := 0.0
var _cd := 0.0

func _ready() -> void:
	textura = null; super._ready()
	var c := get_node_or_null("Sprite/Corpo") as Sprite2D
	if c: c.visible = false
	queue_redraw()

func _process(dt: float) -> void:
	_t += dt; _cd -= dt
	if _cd <= 0.0: _cd = 0.7 if forma in ["abismo","leviata"] else 1.25; _onda()
	queue_redraw()

func _draw() -> void:
	var c := Color("ffb52e") if forma == "estrela" else Color("36c9d2") if forma in ["capitao","nereia"] else Color("8d5cff")
	if forma == "estrela":
		var pts:=PackedVector2Array(); for i in 10: var a=-PI/2.0+TAU*i/10.0; var r=52.0 if i%2==0 else 22.0; pts.append(Vector2(cos(a),sin(a))*r); draw_colored_polygon(pts,c)
	elif forma == "leviata":
		draw_ellipse(Vector2.ZERO,Vector2(72,36),c); draw_circle(Vector2(-28,-4),10,Color.WHITE); draw_circle(Vector2(28,-4),10,Color.WHITE)
	elif forma == "abismo":
		draw_circle(Vector2.ZERO,48,Color("140c2b")); for i in 6: draw_circle(Vector2(cos(i)*34,sin(i)*34),9,c)
	else:
		draw_circle(Vector2(0,-35),24,Color("17243b")); draw_colored_polygon(PackedVector2Array([Vector2(-34,-16),Vector2(34,-16),Vector2(25,55),Vector2(-25,55)]),Color("17243b")); draw_line(Vector2(18,-5),Vector2(65,-45),c,7)

func draw_ellipse(centro:Vector2, raio:Vector2, cor:Color) -> void:
	var p:=PackedVector2Array(); for i in 24: var a=TAU*i/24.0; p.append(centro+Vector2(cos(a)*raio.x,sin(a)*raio.y)); draw_colored_polygon(p,cor)

func _onda() -> void:
	var k:=get_tree().get_first_node_in_group("koliani"); if k==null or global_position.distance_to(k.global_position)>900: return
	var p:=get_parent(); if p==null:return
	var a:=Area2D.new(); a.collision_layer=0; a.collision_mask=2; a.global_position=global_position+Vector2(0,30); p.add_child(a)
	var s:=CollisionShape2D.new(); var r:=CircleShape2D.new(); r.radius=14; s.shape=r; a.add_child(s)
	var q:=Polygon2D.new(); q.polygon=PackedVector2Array([Vector2(-14,0),Vector2(0,-14),Vector2(14,0),Vector2(0,14)]); q.color=Color("57e3ef"); a.add_child(q)
	a.body_entered.connect(func(b:Node)->void: if b.is_in_group("koliani"): b.receber_dano(15,0.0); a.queue_free())
	var tw:=a.create_tween(); tw.tween_property(a,"global_position",a.global_position+Vector2(_dir_para_koliani()*500,0),1.0); tw.tween_callback(a.queue_free)
