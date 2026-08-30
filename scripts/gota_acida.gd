class_name GotaAcida
extends Area2D
## Lágrima ácida da Região I -- nível 04 "A Árvore que Chora". Pende de um
## galho (ou do teto), incha como telegrafo, larga-se, cai e ao bater no
## chão deixa uma POÇA ácida que magoa por um instante.
##
## Mecânica partilhada / reutilizável como perigo de gotejar:
##   * `automatico = true`  -> goteja sozinha em ciclo (perigo de cenário).
##   * `automatico = false` -> fica quieta; a Entrevane pousa-a sobre a
##     Koliani e chama `cair()` uma vez (depois liberta-se).
##
## O escudo erguido bloqueia a gota de frente (vem de cima -> conta como
## empurrão para baixo; ver Koliani.receber_dano).

@export var dano := 16
## Distância máxima da queda quando não há chão por baixo (raycast falha).
@export var altura_queda := 340.0
## Segundos entre gotas no modo automático.
@export var intervalo := 2.6
## Telegrafo: quanto tempo a gota incha antes de se largar.
@export var atraso_inchar := 0.7
## Quanto tempo a poça no chão continua a magoar.
@export var dur_poca := 1.1
@export var automatico := false
@export var cor := Color(0.78, 0.86, 0.32, 1.0)

var _ocupado := false

@onready var _fonte: Node2D = $Fonte


func _ready() -> void:
	monitoring = false  # o dano vem da gota que cai, não desta âncora
	if _fonte:
		_fonte.scale = Vector2(0.5, 0.5)
	if automatico:
		# arranque desfasado para as gotas do cenário não caírem em uníssono
		await get_tree().create_timer(randf_range(0.0, intervalo)).timeout
		_ciclo_automatico()
	else:
		# rede de segurança: se ninguém chamar cair(), some passado um pouco
		get_tree().create_timer(8.0).timeout.connect(func() -> void:
			if not _ocupado:
				queue_free())


func _ciclo_automatico() -> void:
	while is_instance_valid(self):
		await cair()
		await get_tree().create_timer(intervalo).timeout


## Faz um ciclo: incha (telegrafo) -> larga -> cai -> poça. No modo não
## automático liberta-se no fim.
func cair(atraso_: float = -1.0) -> void:
	if _ocupado:
		return
	_ocupado = true
	if atraso_ >= 0.0:
		atraso_inchar = atraso_

	if _fonte:
		var t := create_tween()
		t.tween_property(_fonte, "scale", Vector2(1.15, 1.35), atraso_inchar * 0.7) \
			.set_trans(Tween.TRANS_SINE)
		t.tween_property(_fonte, "scale", Vector2(1.3, 1.5), atraso_inchar * 0.3)
		await t.finished
	else:
		await get_tree().create_timer(atraso_inchar).timeout

	if not is_instance_valid(self):
		return
	_largar()
	if _fonte:
		create_tween().tween_property(_fonte, "scale", Vector2(0.5, 0.5), 0.25)

	if not automatico:
		await get_tree().create_timer(dur_poca + 0.6).timeout
		if is_instance_valid(self):
			queue_free()
		return
	_ocupado = false


## --- queda -----------------------------------------------------------

func _largar() -> void:
	var pai := get_parent()
	if pai == null:
		return
	Som.toca("projetil", -16.0, 1.4)
	var origem := global_position
	var destino_y := _chao_y(origem.x)

	var gota := Area2D.new()
	gota.collision_layer = 0
	gota.collision_mask = 2
	gota.global_position = origem
	pai.add_child(gota)

	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(12, 20)
	forma.shape = rs
	gota.add_child(forma)

	var pinga := Polygon2D.new()
	pinga.color = cor
	pinga.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(5, 2), Vector2(3, 9), Vector2(-3, 9), Vector2(-5, 2),
	])
	gota.add_child(pinga)

	var luz := PointLight2D.new()
	luz.texture = _tex_luz()
	luz.energy = 0.5
	luz.color = cor
	luz.scale = Vector2(0.35, 0.5)
	gota.add_child(luz)

	var atingiu := [false]
	gota.body_entered.connect(func(corpo: Node) -> void:
		if atingiu[0]:
			return
		if corpo is Koliani:
			atingiu[0] = true
			corpo.receber_dano(dano, 0.0)  # vem de cima -> escudo bloqueia
			# add_child/monitoring durante o flush de física -> diferir
			_salpicar.call_deferred(pai, Vector2(gota.global_position.x, gota.global_position.y))
			gota.queue_free())

	var dist: float = maxf(40.0, destino_y - origem.y)
	var dur: float = clampf(dist / 900.0, 0.18, 0.5)
	var t := gota.create_tween()
	t.tween_property(gota, "global_position:y", destino_y, dur) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void:
		if not atingiu[0]:
			_salpicar(pai, Vector2(gota.global_position.x, destino_y))
		if is_instance_valid(gota):
			gota.queue_free())


func _salpicar(pai: Node, pos: Vector2) -> void:
	if not is_instance_valid(pai):
		return
	Som.toca("onda", -20.0, 1.7)
	var poca := Area2D.new()
	poca.collision_layer = 0
	poca.collision_mask = 2
	poca.global_position = pos
	pai.add_child(poca)

	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(58, 16)
	forma.shape = rs
	forma.position = Vector2(0, -6)
	poca.add_child(forma)

	var mancha := Polygon2D.new()
	mancha.color = Color(cor.r, cor.g, cor.b, 0.7)
	mancha.polygon = PackedVector2Array([
		Vector2(-30, 0), Vector2(-18, -8), Vector2(4, -10), Vector2(24, -6),
		Vector2(31, 0), Vector2(16, 4), Vector2(-14, 4),
	])
	poca.add_child(mancha)

	# magoa quem já lá está e quem entrar durante a janela ativa
	var fim := Time.get_ticks_msec() + int(dur_poca * 1000.0)
	poca.body_entered.connect(func(corpo: Node) -> void:
		if corpo is Koliani and Time.get_ticks_msec() < fim:
			corpo.receber_dano(dano, signf(corpo.global_position.x - pos.x)))
	# "quem já lá estava" só se pode consultar depois de um frame de física
	await get_tree().physics_frame
	if is_instance_valid(poca):
		for c in poca.get_overlapping_bodies():
			if c is Koliani:
				c.receber_dano(dano, signf(c.global_position.x - pos.x))

	if not is_instance_valid(poca):
		return
	var t := poca.create_tween()
	t.tween_interval(dur_poca)
	t.tween_property(mancha, "modulate:a", 0.0, 0.35)
	t.tween_callback(poca.queue_free)


## --- utilitários ---------------------------------------------------

func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return global_position.y + altura_queda
	var de := Vector2(x, global_position.y + 8.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, altura_queda), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else global_position.y + altura_queda


static var _luz_cache: GradientTexture2D


func _tex_luz() -> GradientTexture2D:
	if _luz_cache:
		return _luz_cache
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 96
	tex.height = 96
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	_luz_cache = tex
	return tex
