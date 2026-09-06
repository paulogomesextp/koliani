class_name ChefeElemental
extends ChefeGenerico
## Variantes próprias para o lote VII: magma, forja e dragão de lava.
@export_enum("magma", "forja", "dragao") var forma := "magma"
var _tempo := 0.0
var _cd := 0.0

func _ready() -> void:
	rig = {"magma": "golem_pedra", "forja": "cavaleiro_fogo", "dragao": "vyrak"}.get(forma, "golem_pedra")
	textura = null
	super._ready()

func _process(dt: float) -> void:
	_tempo += dt; _cd -= dt
	if _cd <= 0.0:
		_cd = 1.0 if forma == "dragao" else 1.35
		_ataque_elemental()

func _ataque_elemental() -> void:
	var k := get_tree().get_first_node_in_group("koliani")
	if k == null or global_position.distance_to(k.global_position) > 760.0: return
	var pai := get_parent(); if pai == null: return
	var a := Area2D.new(); a.collision_layer=0; a.collision_mask=2; a.global_position=global_position+Vector2(randf_range(-28,28),20); pai.add_child(a)
	var s:=CollisionShape2D.new(); var r:=CircleShape2D.new(); r.radius=11; s.shape=r; a.add_child(s)
	var p:=Polygon2D.new(); p.polygon=PackedVector2Array([Vector2(0,-12),Vector2(10,8),Vector2(0,14),Vector2(-10,8)]); p.color=Color("ff541e"); a.add_child(p)
	a.body_entered.connect(func(b:Node)->void: if b.is_in_group("koliani"): b.receber_dano(14,0.0); a.queue_free())
	var tw:=a.create_tween(); tw.tween_property(a,"global_position",a.global_position+Vector2(randf_range(-160,160),380),1.0); tw.tween_callback(a.queue_free)
