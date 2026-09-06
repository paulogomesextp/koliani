class_name ChefeGlacial
extends ChefeGenerico
## Chefes da Regiao IX: cada forma usa um sprite pixel art proprio e um padrao de ataque.
@export_enum("frostfang", "skyrend", "prism_scarab", "cryo_sentinel", "ymiria") var forma := "frostfang"
var _t := 0.0
var _cd := 0.0
var _ataque := 0

func _ready() -> void:
	rig = ""
	textura = load("res://assets/sprites/pixel/bosses/%s.png" % forma) as Texture2D
	super._ready()
	var corpo := get_node_or_null("Sprite/Corpo") as Sprite2D
	if corpo:
		corpo.visible = true
		corpo.texture = textura
		corpo.scale = Vector2(1.25, 1.25)
	var anim := get_node_or_null("Sprite/Anim") as AnimatedSprite2D
	if anim: anim.visible = false
	queue_redraw()

func _process(dt: float) -> void:
	_t += dt
	_cd -= dt
	if _cd <= 0.0:
		_cd = {"frostfang":1.1,"skyrend":1.35,"prism_scarab":1.55,"cryo_sentinel":1.8,"ymiria":1.0}.get(forma, 1.2)
		_ataque += 1
		_executar_mecanica()
	queue_redraw()

func _draw() -> void:
	# Runas de telegrapho e assinatura elemental sob o sprite.
	var cor := {"frostfang":Color("75e9ff"),"skyrend":Color("a9d9ff"),"prism_scarab":Color("9d8dff"),"cryo_sentinel":Color("c6f7ff"),"ymiria":Color("d5b5ff")}.get(forma,Color.WHITE)
	if fmod(_t, 1.0) < 0.5:
		draw_arc(Vector2(0,42), 42.0, PI, TAU, 18, Color(cor,0.35), 2.0)
	if forma == "cryo_sentinel":
		draw_arc(Vector2.ZERO, 48.0, _t, _t + PI * 0.8, 16, Color(cor,0.55), 3.0)
	elif forma == "ymiria":
		for i in 5:
			var a := _t * 0.8 + TAU * i / 5.0
			draw_circle(Vector2(cos(a), sin(a)) * 48.0, 3.0, Color(cor,0.65))

func _executar_mecanica() -> void:
	var k := get_tree().get_first_node_in_group("koliani")
	if k == null or global_position.distance_to(k.global_position) > 900.0: return
	match forma:
		"frostfang":
			# Investida deixa dois fragmentos de gelo no caminho.
			for side in [-1.0, 1.0]: _criar_fragmento(global_position + Vector2(side * 26.0, 24.0), Vector2(0, 18))
		"skyrend":
			# Rajada cai do ceu na posicao atual da Koliani.
			_criar_fragmento(Vector2(k.global_position.x, global_position.y - 260.0), Vector2(0, 360))
		"prism_scarab":
			# Tres espinhos cristalinos brotam em leque a partir do chao.
			for i in 3: _criar_fragmento(global_position + Vector2((i - 1) * 48.0, 42.0), Vector2(0, 130))
		"cryo_sentinel":
			# Feixe horizontal alterna o lado e obriga a saltar/agachar.
			var dir := -1.0 if _ataque % 2 == 0 else 1.0
			_criar_fragmento(global_position + Vector2(dir * 30.0, -20.0), Vector2(dir * 620.0, 0))
		"ymiria":
			# Orbita de cinco flocos que converge para a heroina.
			for i in 5:
				var a := TAU * i / 5.0
				_criar_fragmento(global_position + Vector2(cos(a), sin(a)) * 70.0, (k.global_position - global_position).normalized() * 210.0)

func _criar_fragmento(pos: Vector2, desloc: Vector2) -> void:
	var pai := get_parent()
	if pai == null: return
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.global_position = pos
	pai.add_child(a)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new(); sh.size = Vector2(18, 18)
	cs.shape = sh; a.add_child(cs)
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([Vector2(0,-13),Vector2(10,0),Vector2(0,13),Vector2(-10,0)])
	p.color = Color("9defff") if forma != "ymiria" else Color("d2a7ff")
	a.add_child(p)
	a.body_entered.connect(func(b: Node) -> void:
		if b.is_in_group("koliani"):
			b.receber_dano(16 if forma != "cryo_sentinel" else 22, 0.0)
			a.queue_free()
	)
	var destino := pos + desloc
	var tw := a.create_tween()
	tw.tween_property(a, "global_position", destino, 0.9)
	tw.tween_callback(a.queue_free)
