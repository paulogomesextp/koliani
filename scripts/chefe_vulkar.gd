class_name ChefeVulkar
extends ChefeGenerico
## Vulkar, Cavaleiro das Cinzas (nível 31). Boss próprio: investida em
## chamas e chuva de brasas; a arena fica perigosa durante a segunda fase.

var _pulso := 0.0
var _brasas_t := 0.0
var _fase2 := false

func _ready() -> void:
	# Vulkar tem silhueta desenhada por código. Desliga o rig da cena base
	# antes do super: ChefeBase monta o AnimatedSprite quando `rig` existe.
	rig = ""
	textura = null
	super._ready()
	var corpo := get_node_or_null("Sprite/Corpo") as Sprite2D
	if corpo:
		corpo.visible = false
	var anim := get_node_or_null("Sprite/Anim") as AnimatedSprite2D
	if anim:
		anim.visible = false
	queue_redraw()

func _process(dt: float) -> void:
	# Rede de segurança da arena do nível 31: se a física perder a plataforma
	# durante a primeira frame, repõe o cavaleiro sobre o chão em vez de o
	# marcar como derrotado antes de o jogador o conseguir ver.
	if global_position.y > 660.0 and not _ja_derrotado:
		global_position.y = 630.0
		velocity.y = 0.0
	_pulso += dt
	_brasas_t += dt
	if not _fase2 and _vida_maxima > 0 and float(vida) / _vida_maxima < 0.5:
		_fase2 = true
	if _brasas_t > (0.8 if _fase2 else 1.35):
		_brasas_t = 0.0
		_largar_brasa()
	queue_redraw()

func _draw() -> void:
	var brilho := 0.12 + 0.08 * sin(_pulso * 8.0)
	var fogo := Color(1.0, 0.22 + brilho, 0.04, 0.95)
	var metal := Color(0.16, 0.12, 0.15, 1)
	var cinza := Color(0.34, 0.27, 0.3, 1)
	# silhueta humanoide própria: elmo, ombreiras, couraça, capa e espada
	draw_polygon(PackedVector2Array([Vector2(-24,-72),Vector2(24,-72),Vector2(30,-46),Vector2(18,-34),Vector2(-18,-34),Vector2(-30,-46)]), PackedColorArray([metal]))
	draw_circle(Vector2(0,-51), 15, cinza)
	draw_rect(Rect2(-22,-38,44,48), metal)
	draw_colored_polygon(PackedVector2Array([Vector2(-22,-32),Vector2(-40,-22),Vector2(-31,-5),Vector2(-18,-14)]), cinza)
	draw_colored_polygon(PackedVector2Array([Vector2(22,-32),Vector2(40,-22),Vector2(31,-5),Vector2(18,-14)]), cinza)
	draw_line(Vector2(18,-20), Vector2(58,-70), Color(0.95,0.8,0.55), 6)
	draw_colored_polygon(PackedVector2Array([Vector2(-20,10),Vector2(20,10),Vector2(34,55),Vector2(0,42),Vector2(-34,55)]), Color(0.22,0.05,0.04,0.95))
	for x in [-26.0, 26.0]:
		draw_circle(Vector2(x, 47), 7, fogo)

func _largar_brasa() -> void:
	var pai := get_parent()
	if pai == null: return
	var brasa := Area2D.new()
	brasa.collision_layer = 0
	brasa.collision_mask = 2
	brasa.global_position = global_position + Vector2(randf_range(-28,28), 20)
	var forma := CollisionShape2D.new()
	var cir := CircleShape2D.new(); cir.radius = 9.0; forma.shape = cir
	brasa.add_child(forma); pai.add_child(brasa)
	var p := Polygon2D.new(); p.polygon = PackedVector2Array([Vector2(0,-10),Vector2(8,0),Vector2(0,10),Vector2(-8,0)]); p.color = Color(1,0.3,0.04,0.95); brasa.add_child(p)
	brasa.body_entered.connect(func(alvo: Node) -> void:
		if alvo.is_in_group("koliani"): alvo.receber_dano(12 if _fase2 else 8, 0.0); brasa.queue_free())
	var t := brasa.create_tween()
	t.tween_property(brasa, "global_position:y", global_position.y + 420.0, 1.1)
	t.tween_callback(brasa.queue_free)
