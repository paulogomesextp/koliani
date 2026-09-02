class_name ChefeColossoOsseo
extends ChefeBase
## Região IV / nível 17 -- O Colosso Ósseo. Um gigante feito de centenas de
## esqueletos, quase imóvel, que domina a Galeria dos Ossos. Alterna:
##   * MARTELO -- baixa um maço de ossos: onda de choque rasteira (salta-se).
##   * GADANHA -- varre uma foice de osso a meia altura (rola-se por baixo
##     ou fica-se atrás dele).
##   * LANÇA   -- espeta uma lança de osso a direito, rápida e comprida.
##   * CHUVA   -- ossos caem do teto em pontos telegrafados.
## A seguir a cada ataque o peito abre-se (aglomerado de crânios = EXPOSTO,
## dano a dobrar).
## Cada vez que perde uma "camada" (75%, 50%, 25% da vida) REMODELA-SE: usa
## os ossos soltos para forjar armas novas -- telégrafos mais curtos, ordem
## dos ataques muda, e aos 50% larga dois cães de osso.

const CAO := preload("res://scenes/actors/DemonioBase.tscn")

enum Fase { DORME, DECIDE, MARTELO_TEL, MARTELO, GADANHA_TEL, GADANHA, LANCA_TEL, LANCA, CHUVA_TEL, CHUVA, EXPOSTO, REMODELA }

@export var dist_deteta := 520.0
@export var dur_tel := 0.7
@export var dur_exposto := 1.5
@export var raio_onda := 320.0
@export var dano_onda := 22
@export var dano_gadanha := 20
@export var dano_lanca := 18
@export var dano_osso := 14

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _camada := 0            # 0..3 -- sobe a cada remodelação
var _exposto := false
var _ciclos := 0
var _onda_feita := false
var _vida_max := 640
var _chao_cache := 0.0
var _proximo_limiar := 0.75

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 585)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _nucleo and _exposto:
		var p := 1.0 + 0.16 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(global_position.x)
	if not is_on_floor():
		velocity.y += GRAVIDADE * dt
		move_and_slide()
	if _fase != Fase.REMODELA and _proximo_limiar > 0.0 \
			and vida <= int(_vida_max * _proximo_limiar) and not _ja_derrotado:
		_ir(Fase.REMODELA)

	match _fase:
		Fase.DORME:
			if _ve_koliani():
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_encarar_koliani()
			if _t >= 0.28:
				_escolher()
		Fase.MARTELO_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= _tel():
				_piscar(false)
				_ir(Fase.MARTELO)
		Fase.MARTELO:
			if _t >= 0.2 and not _onda_feita:
				_onda_feita = true
				_baque()
			if _t >= 0.5:
				_ir(Fase.EXPOSTO)
		Fase.GADANHA_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= _tel():
				_piscar(false)
				_gadanha()
				_ir(Fase.GADANHA)
		Fase.GADANHA:
			if _t >= 0.4:
				_ir(Fase.EXPOSTO)
		Fase.LANCA_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= _tel() * 0.85:
				_piscar(false)
				_lanca()
				_ir(Fase.LANCA)
		Fase.LANCA:
			if _t >= 0.35:
				_ir(Fase.EXPOSTO)
		Fase.CHUVA_TEL:
			_piscar(true)
			if _t >= _tel():
				_piscar(false)
				_ir(Fase.CHUVA)
		Fase.CHUVA:
			if fmod(_t, 0.22) < dt:
				_osso_do_teto()
			if _t >= (1.3 + _camada * 0.2):
				_ir(Fase.EXPOSTO)
		Fase.EXPOSTO:
			if not _exposto:
				_exposto = true
				_mostrar_nucleo(true)
			if _t >= dur_exposto:
				_exposto = false
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.DECIDE)
		Fase.REMODELA:
			if _t < dt:
				_remodelar()
			if _t >= 1.0:
				_ir(Fase.DECIDE)
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0
	_onda_feita = false


func _tel() -> float:
	return dur_tel * (1.0 - 0.12 * _camada)


func _escolher() -> void:
	# a ordem das armas roda com a camada -> "armas novas"
	var op := (_ciclos + _camada) % 4
	match op:
		0: _ir(Fase.MARTELO_TEL)
		1: _ir(Fase.GADANHA_TEL)
		2: _ir(Fase.LANCA_TEL)
		_: _ir(Fase.CHUVA_TEL)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 320.0


## --- ataques ---------------------------------------------------------

func _baque() -> void:
	Som.toca("esmagar", -5.0, 0.8)
	_abanar_camera(6.0)
	var k := _obter_koliani()
	if k and absf(_vetor_para_koliani().x) <= raio_onda and k.is_on_floor():
		k.receber_dano(int(round(dano_onda * (1.0 + 0.08 * _camada))), _dir_para_koliani())
	_particulas(Vector2(0, 34), Color(0.82, 0.8, 0.64))


func _gadanha() -> void:
	Som.toca("golpe_pesado", -6.0, 0.7)
	var pai := get_parent()
	if pai == null:
		return
	var dir := _dir_para_koliani()
	var g := Area2D.new()
	g.collision_layer = 0
	g.collision_mask = 2
	g.global_position = global_position + Vector2(0, -30)
	pai.add_child(g)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(300, 30)
	forma.shape = rs
	forma.position = Vector2(dir * 150.0, 0)
	g.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.85, 0.83, 0.66, 0.85)
	poly.polygon = PackedVector2Array([Vector2(0, 0), Vector2(dir * 300.0, -18), Vector2(dir * 300.0, 14), Vector2(0, 16)])
	g.add_child(poly)
	var dano := int(round(dano_gadanha * (1.0 + 0.08 * _camada)))
	g.body_entered.connect(func(c: Node) -> void:
		if c is Koliani:
			c.receber_dano(dano, dir))
	var t := g.create_tween()
	t.tween_callback(func() -> void:
		for c in g.get_overlapping_bodies():
			if c is Koliani:
				c.receber_dano(dano, dir))
	t.tween_property(poly, "modulate:a", 0.0, 0.3)
	t.tween_callback(g.queue_free)


func _lanca() -> void:
	Som.toca("projetil", -6.0, 1.1)
	var pai := get_parent()
	if pai == null:
		return
	var dir := _dir_para_koliani()
	var l := Area2D.new()
	l.collision_layer = 0
	l.collision_mask = 2
	l.global_position = global_position + Vector2(dir * 40.0, -14.0)
	pai.add_child(l)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(44, 12)
	forma.shape = rs
	l.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.86, 0.84, 0.68, 1.0)
	poly.polygon = PackedVector2Array([Vector2(-22, 0), Vector2(14, -5), Vector2(22, 0), Vector2(14, 5)])
	poly.scale.x = dir
	l.add_child(poly)
	var dano := int(round(dano_lanca * (1.0 + 0.08 * _camada)))
	l.body_entered.connect(func(c: Node) -> void:
		if c is Koliani:
			c.receber_dano(dano, dir)
		l.queue_free())
	var t := l.create_tween()
	t.tween_property(l, "global_position:x", global_position.x + dir * 900.0, 0.55)
	t.tween_callback(l.queue_free)


func _osso_do_teto() -> void:
	var pai := get_parent()
	if pai == null:
		return
	var k := _obter_koliani()
	var x := (k.global_position.x if k else global_position.x) + randf_range(-160.0, 160.0)
	var o := Area2D.new()
	o.collision_layer = 0
	o.collision_mask = 2
	o.global_position = Vector2(x, _chao_cache - 400.0)
	pai.add_child(o)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 8.0
	forma.shape = cs
	o.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.84, 0.82, 0.66, 1.0)
	poly.polygon = PackedVector2Array([Vector2(-3, -10), Vector2(3, -10), Vector2(3, 10), Vector2(-3, 10)])
	o.add_child(poly)
	var dano := dano_osso
	o.body_entered.connect(func(c: Node) -> void:
		if c is Koliani:
			c.receber_dano(dano, signf(c.global_position.x - o.global_position.x))
		o.queue_free())
	var t := o.create_tween()
	t.tween_property(o, "global_position:y", _chao_cache - 6.0, 0.5)
	t.parallel().tween_method(func(v: float) -> void: poly.rotation = v, 0.0, TAU * 2.0, 0.5)
	t.tween_callback(o.queue_free)


## --- remodelação (perde uma camada) ---------------------------------

func _remodelar() -> void:
	_camada += 1
	_proximo_limiar = [0.75, 0.5, 0.25, -1.0][clampi(_camada, 0, 3)]
	Som.toca("chefe_cai", -7.0, 0.8)
	_abanar_camera(9.0)
	dur_exposto = maxf(0.9, dur_exposto - 0.12)
	_particulas(Vector2(0, -10), Color(0.8, 0.78, 0.62), 40)
	if _sprite:
		create_tween().tween_property(_sprite, "scale", Vector2.ONE * (1.0 - 0.06 * _camada), 0.4)
	if _camada == 2:
		_largar_caes()


func _largar_caes() -> void:
	var pai := get_parent()
	if pai == null:
		return
	for i in 2:
		var c := CAO.instantiate()
		c.especie = "esqueleto"
		c.vida = 24
		c.dano_contacto = 14
		c.velocidade = 120.0
		c.alcance_patrulha = 340.0
		var x := global_position.x + (i * 2 - 1) * 60.0
		c.global_position = Vector2(x, _chao_y(x) - 20.0)
		pai.add_child(c)
		c.get_tree().create_timer(11.0).timeout.connect(func() -> void:
			if is_instance_valid(c) and not c._morto:
				c.soltar_estilhacos()
				c.queue_free())


## --- núcleo / dano -------------------------------------------------

func _piscar(ligado: bool) -> void:
	super._piscar(ligado)
	if _corpo and not _exposto:
		_corpo.frame = 2 if ligado else 0


func _mostrar_nucleo(v: bool) -> void:
	_exposto = v
	_pulso = 0.0
	if _corpo:
		_corpo.frame = 3 if v else 0
	if _nucleo:
		_nucleo.scale = Vector2.ONE * (1.0 if v else 0.4)
		var luz: PointLight2D = _nucleo.get_node_or_null("Luz")
		if luz:
			luz.energy = 1.6 if v else 0.12
		var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
		if brilho:
			brilho.visible = v


func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false) -> void:
	if _ja_derrotado:
		return
	provocar()
	if not _exposto:
		Som.toca("bloqueio", -9.0, 0.5)
		if _sprite:
			_sprite.modulate = Color(1.2, 1.2, 1.0)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		_raspao(quantidade, dir_empurrao)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao, critico)


## --- utilitários --------------------------------------------------

func _particulas(desl: Vector2, cor: Color, n: int = 24) -> void:
	var p := CPUParticles2D.new()
	p.global_position = global_position + desl
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = n
	p.lifetime = 0.6
	p.spread = 120.0
	p.gravity = Vector2(0, 700)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 260.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = cor
	add_sibling(p)
	p.get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return _origem.y + 40.0
	var de := Vector2(x, _origem.y - 60.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 640.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else _origem.y + 40.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)
