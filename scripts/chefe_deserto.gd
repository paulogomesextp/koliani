class_name ChefeDeserto
extends ChefeGenerico
## Chefes proprios da Regiao X: areia, ruinas e a maldicao do sol morto.
@export_enum("dune_stalker", "sandstone_colossus", "scorpion_empress", "sun_mummy", "forgotten_god") var forma := "dune_stalker"
var _deserto_t := 0.0
var _cd := 0.0
var _n := 0
func _ready() -> void:
	rig = {"dune_stalker": "naga_zeraph", "sandstone_colossus": "golem_pedra",
		"scorpion_empress": "rainha_aracnidea", "sun_mummy": "rei_ossario",
		"forgotten_god": "monge_terra"}.get(forma, "golem_pedra")
	textura = null
	super._ready()
func _process(dt: float) -> void:
	_deserto_t += dt; _cd -= dt
	if _cd <= 0.0:
		_cd = {"dune_stalker":1.0,"sandstone_colossus":1.6,"scorpion_empress":1.15,"sun_mummy":1.35,"forgotten_god":1.8}.get(forma,1.2)
		_n += 1; _mecanica()
	queue_redraw()
func _draw() -> void:
	var cor: Color = {"dune_stalker":Color("f2c56a"),"sandstone_colossus":Color("d9a85d"),"scorpion_empress":Color("ed8c3b"),"sun_mummy":Color("ffe09a"),"forgotten_god":Color("d08cff")}.get(forma,Color.WHITE)
	if fmod(_deserto_t,1.2)<0.55: draw_arc(Vector2(0,42),44,PI,TAU,20,Color(cor,0.4),2)
	if forma == "forgotten_god":
		for i in 4:
			var p:=Vector2(cos(_deserto_t+i*TAU/4.0),sin(_deserto_t+i*TAU/4.0))*52.0
			draw_circle(p,3,Color(cor,0.7))
func _mecanica() -> void:
	var k:=get_tree().get_first_node_in_group("koliani")
	if k==null or global_position.distance_to(k.global_position)>900:return
	match forma:
		"dune_stalker":
			for x in [-48.0,0.0,48.0]: _proj(global_position+Vector2(x,38),Vector2(_dir_para_koliani()*230.0,-40))
		"sandstone_colossus":
			_proj(global_position+Vector2(0,-55),Vector2(0,300))
			_proj(global_position+Vector2(-70,20),Vector2(-120,0)); _proj(global_position+Vector2(70,20),Vector2(120,0))
		"scorpion_empress":
			for i in 3: _proj(global_position+Vector2(0,-20),Vector2(_dir_para_koliani()*240.0,(i-1)*70.0))
		"sun_mummy":
			for i in 4: _proj(global_position+Vector2((i-1.5)*45,0),Vector2(0,250))
		"forgotten_god":
			for i in 6:
				var v:=Vector2(cos(TAU*i/6.0),sin(TAU*i/6.0))*220.0
				_proj(global_position,v)
func _proj(pos:Vector2, vel:Vector2)->void:
	var p:=get_parent(); if p==null:return
	var a:=Area2D.new(); a.collision_layer=0; a.collision_mask=2; a.global_position=pos; p.add_child(a)
	var cs:=CollisionShape2D.new(); var sh:=CircleShape2D.new(); sh.radius=11; cs.shape=sh; a.add_child(cs)
	var q:=Polygon2D.new(); q.polygon=PackedVector2Array([Vector2(0,-13),Vector2(10,0),Vector2(0,13),Vector2(-10,0)]); q.color=Color("f2b84b") if forma!="forgotten_god" else Color("c58cff"); a.add_child(q)
	a.body_entered.connect(func(b:Node)->void: if b.is_in_group("koliani"): b.receber_dano(18,0.0); a.queue_free())
	var tw:=a.create_tween(); tw.tween_property(a,"global_position",pos+vel,1.0); tw.tween_callback(a.queue_free)
