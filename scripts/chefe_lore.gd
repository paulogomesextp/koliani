class_name ChefeLore
extends ChefeGenerico
## Bosses 51-100: identidade visual por sprite e padrao de arena por regiao.
@export var forma := "boss"
var _lore_t := 0.0
var _lore_cd := 0.0
var _lore_n := 0
func _ready() -> void:
	rig = ""
	textura = load("res://assets/sprites/pixel/bosses/%s.png" % forma) as Texture2D
	super._ready()
	var c := get_node_or_null("Sprite/Corpo") as Sprite2D
	if c: c.visible=true; c.texture=textura; c.scale=Vector2(1.2,1.2)
	var a := get_node_or_null("Sprite/Anim") as AnimatedSprite2D
	if a: a.visible=false
func _process(dt:float)->void:
	_lore_t+=dt; _lore_cd-=dt
	if _lore_cd<=0.0:
		_lore_cd=1.0+float(int(forma.hash())%9)/10.0; _lore_n+=1; _lore_attack()
	queue_redraw()
func _draw()->void:
	var col:=Color.from_hsv(float(abs(forma.hash())%360)/360.0,0.55,1.0)
	if fmod(_lore_t,1.3)<0.5: draw_arc(Vector2(0,42),44,PI,TAU,18,Color(col,0.35),2)
func _lore_attack()->void:
	var k:=get_tree().get_first_node_in_group("koliani"); if k==null:return
	var p:=get_parent(); if p==null:return
	var mode: int =abs(forma.hash())%4
	for i in (3 if mode==0 else 5 if mode==1 else 2 if mode==2 else 6):
		var pos:=global_position+Vector2((i-2)*34.0,-20.0 if mode==1 else 24.0)
		var vel:Vector2
		if mode==0: vel=Vector2(_dir_para_koliani()*260.0,(i-1)*42.0)
		elif mode==1: vel=Vector2(0,260.0)
		elif mode==2: vel=Vector2(_dir_para_koliani()*360.0,0)
		else: vel=(k.global_position-global_position).normalized()*250.0
		_projectile(p,pos,vel)
func _projectile(p:Node,pos:Vector2,vel:Vector2)->void:
	var a:=Area2D.new(); a.collision_layer=0; a.collision_mask=2; a.global_position=pos; p.add_child(a)
	var cs:=CollisionShape2D.new(); var sh:=CircleShape2D.new(); sh.radius=10; cs.shape=sh; a.add_child(cs)
	var q:=Polygon2D.new(); q.polygon=PackedVector2Array([Vector2(0,-12),Vector2(9,0),Vector2(0,12),Vector2(-9,0)]); q.color=Color.from_hsv(float(abs(forma.hash())%360)/360.0,0.5,1); a.add_child(q)
	a.body_entered.connect(func(b:Node)->void: if b.is_in_group("koliani"): b.receber_dano(18,0.0); a.queue_free())
	var tw:=a.create_tween(); tw.tween_property(a,"global_position",pos+vel,1.0); tw.tween_callback(a.queue_free)
