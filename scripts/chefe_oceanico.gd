class_name ChefeOceanico
extends ChefeGenerico
## Bosses próprios do lote VII/VIII: formas e ataques de água/energia.
@export_enum("estrela", "capitao", "leviata", "nereia", "devorador", "abismo") var forma := "estrela"
var _tempo_ataque := 0.0
var _cd := 0.0

func _ready() -> void:
	rig = {"estrela": "feiticeiro", "capitao": "rei_devorador", "leviata": "demonio_lodo", "nereia": "sacerdotisa",
		"devorador": "rei_devorador", "abismo": "horror"}.get(forma, "rei_devorador")
	textura = null
	super._ready()

func _process(dt: float) -> void:
	_tempo_ataque += dt; _cd -= dt
	if _cd <= 0.0: _cd = 0.7 if forma in ["abismo","leviata"] else 1.25; _onda()

func _onda() -> void:
	var k:=get_tree().get_first_node_in_group("koliani"); if k==null or global_position.distance_to(k.global_position)>900: return
	var p:=get_parent(); if p==null:return
	var a:=Area2D.new(); a.collision_layer=0; a.collision_mask=2; a.global_position=global_position+Vector2(0,30); p.add_child(a)
	var s:=CollisionShape2D.new(); var r:=CircleShape2D.new(); r.radius=14; s.shape=r; a.add_child(s)
	var q:=Polygon2D.new(); q.polygon=PackedVector2Array([Vector2(-14,0),Vector2(0,-14),Vector2(14,0),Vector2(0,14)]); q.color=Color("57e3ef"); a.add_child(q)
	a.body_entered.connect(func(b:Node)->void: if b.is_in_group("koliani"): b.receber_dano(15,0.0); a.queue_free())
	var tw:=a.create_tween(); tw.tween_property(a,"global_position",a.global_position+Vector2(_dir_para_koliani()*500,0),1.0); tw.tween_callback(a.queue_free)
