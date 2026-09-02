class_name ChefeBispoPurpura
extends ChefeBase
## Região V / nível 24 -- O Bispo Púrpura da Catedral da Corrupção. Paira
## junto ao altar e canaliza a magia púrpura de Zeriko:
##   * CRUZES  -- crava cruzes acesas em pontos telegrafados do chão; um
##     instante depois explodem (rebentamento radial).
##   * MAOS    -- mãos espectrais irrompem sob os pés da Koliani.
##   * ANJOS   -- invoca 1-2 anjos corrompidos (DemonioBase "olho").
## Depois de CRUZES / MAOS ergue o turíbulo para "abençoar" (EXPOSTO -- o
## relicário do peito à mostra, dano a dobrar).
## Fase 2 (< 50% vida): mais cruzes, mãos mais rápidas, 3 anjos.

const ANJO := preload("res://scenes/actors/DemonioBase.tscn")

enum Fase { DORME, DECIDE, DESCE, CRUZES_TEL, CRUZES, MAOS_TEL, MAOS, ANJOS_TEL, ANJOS, EXPOSTO, SOBE }

@export var dist_deteta := 640.0
@export var altura_voo := 210.0
@export var altura_exposta := 96.0
@export var dur_tel := 0.6
@export var dur_exposta := 1.45
@export var dano_cruz := 20
@export var dano_mao := 18

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposta := false
var _ciclos := 0
var _vida_max := 440
var _chao_cache := 0.0
var _alvo_y := 0.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 750)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_alvo_y = _origem.y
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite:
		_sprite.position.y = sin(_pulso * 1.9) * (6.0 if not _exposta else 2.0)
	if _nucleo and _exposta:
		var p := 1.0 + 0.18 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(global_position.x)
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_entrar_fase2()

	global_position.y = lerpf(global_position.y, _alvo_y, clampf(dt * 3.0, 0.0, 1.0))
	global_position.x = lerpf(global_position.x, _x_koliani(), clampf(dt * 1.2, 0.0, 1.0))
	_encarar_koliani()

	match _fase:
		Fase.DORME:
			_alvo_y = _chao_cache - altura_voo
			if _ve_koliani():
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_alvo_y = _chao_cache - altura_voo
			if _t >= 0.3:
				match _ciclos % 3:
					0: _ir(Fase.CRUZES_TEL)
					1: _ir(Fase.MAOS_TEL)
					_: _ir(Fase.ANJOS_TEL)
		Fase.CRUZES_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_cruzes()
				_ir(Fase.CRUZES)
		Fase.CRUZES:
			if _t >= 0.6:
				_ir(Fase.EXPOSTO)
		Fase.MAOS_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_maos()
				_ir(Fase.MAOS)
		Fase.MAOS:
			if _t >= 0.6:
				_ir(Fase.EXPOSTO)
		Fase.ANJOS_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_anjos()
				_ir(Fase.ANJOS)
		Fase.ANJOS:
			if _t >= 0.5:
				_ir(Fase.DECIDE)
		Fase.EXPOSTO:
			_alvo_y = _chao_cache - altura_exposta
			if not _exposta:
				_exposta = true
				_mostrar_nucleo(true)
			if _t >= dur_exposta:
				_exposta = false
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.DECIDE)
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 380.0


## --- ataques ---------------------------------------------------------

func _cruzes() -> void:
	Som.toca("chefe_magia", -7.0, 0.7)
	var pai := get_parent()
	if pai == null:
		return
	var n := 4 if _fase2 else 3
	var alvo := _x_koliani()
	for i in n:
		var x := alvo + (i - (n - 1) * 0.5) * 110.0 + randf_range(-16.0, 16.0)
		_cruz(x, 0.1 + i * 0.1)


func _cruz(x: float, atraso: float) -> void:
	var pai := get_parent()
	var chao := _chao_y(x)
	var c := Area2D.new()
	c.collision_layer = 0
	c.collision_mask = 2
	c.monitoring = false
	c.global_position = Vector2(x, chao - 30.0)
	pai.add_child(c)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 46.0
	forma.shape = cs
	c.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.7, 0.4, 1.0, 0.9)
	poly.polygon = PackedVector2Array([Vector2(-4, -28), Vector2(4, -28), Vector2(4, -8), Vector2(20, -8), Vector2(20, 0), Vector2(4, 0), Vector2(4, 28), Vector2(-4, 28), Vector2(-4, 0), Vector2(-20, 0), Vector2(-20, -8), Vector2(-4, -8)])
	c.add_child(poly)
	var luz := PointLight2D.new()
	luz.texture = _tex_luz()
	luz.energy = 0.7
	luz.color = Color(0.7, 0.4, 1.0)
	luz.scale = Vector2(0.6, 0.6)
	c.add_child(luz)
	var dano := int(round(dano_cruz * (1.1 if _fase2 else 1.0)))
	var t := c.create_tween()
	t.tween_interval(atraso + 0.5)
	t.tween_callback(func() -> void:
		c.monitoring = true
		_abanar_camera(3.0)
		Som.toca("esmagar", -7.0, 1.1)
		for b in c.get_overlapping_bodies():
			if b is Koliani:
				b.receber_dano(dano, signf(b.global_position.x - c.global_position.x)))
	t.parallel().tween_property(poly, "scale", Vector2(2.2, 2.2), 0.18)
	t.tween_property(poly, "modulate:a", 0.0, 0.25)
	t.tween_callback(c.queue_free)


func _maos() -> void:
	Som.toca("chefe_magia", -8.0, 1.4)
	var pai := get_parent()
	if pai == null:
		return
	var n := 3 if _fase2 else 2
	var alvo := _x_koliani()
	for i in n:
		var x := alvo + (i - (n - 1) * 0.5) * 90.0 + randf_range(-14.0, 14.0)
		_mao(x, 0.1 + i * 0.14)


func _mao(x: float, atraso: float) -> void:
	var pai := get_parent()
	var chao := _chao_y(x)
	var m := Area2D.new()
	m.collision_layer = 0
	m.collision_mask = 2
	m.monitoring = false
	m.global_position = Vector2(x, chao)
	pai.add_child(m)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(24, 60)
	forma.shape = rs
	forma.position = Vector2(0, -30)
	m.add_child(forma)
	var garra := Polygon2D.new()
	garra.color = Color(0.4, 0.2, 0.55, 0.92)
	garra.polygon = PackedVector2Array([Vector2(-11, 0), Vector2(-8, -40), Vector2(-2, -28), Vector2(0, -54), Vector2(2, -28), Vector2(8, -40), Vector2(11, 0)])
	garra.scale.y = 0.0
	m.add_child(garra)
	var dano := int(round(dano_mao * (1.15 if _fase2 else 1.0)))
	var t := m.create_tween()
	t.tween_interval(atraso)
	t.tween_callback(func() -> void: m.monitoring = true)
	t.tween_property(garra, "scale:y", 1.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(func() -> void:
		for b in m.get_overlapping_bodies():
			if b is Koliani:
				b.receber_dano(dano, signf(b.global_position.x - m.global_position.x)))
	t.tween_interval(0.4)
	t.tween_callback(func() -> void: m.monitoring = false)
	t.tween_property(garra, "scale:y", 0.0, 0.18)
	t.tween_callback(m.queue_free)


func _anjos() -> void:
	Som.toca("invocar", -8.0, 0.6)
	var pai := get_parent()
	if pai == null:
		return
	var n := 3 if _fase2 else 2
	for i in n:
		var a := ANJO.instantiate()
		a.especie = "olho"
		a.vida = 22
		a.dano_contacto = 14
		a.velocidade = 100.0
		a.alcance_patrulha = 340.0
		a.cor_estilhacos = Color(0.6, 0.4, 0.85)
		a.cor_rim = Color(0.75, 0.5, 1.0)
		var x := global_position.x + (i - (n - 1) * 0.5) * 90.0
		a.global_position = Vector2(x, _chao_y(x) - 30.0)
		pai.add_child(a)
		a.get_tree().create_timer(10.0).timeout.connect(func() -> void:
			if is_instance_valid(a) and not a._morto:
				a.soltar_estilhacos()
				a.queue_free())


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -8.0, 0.7)
	_abanar_camera(7.0)
	dur_tel *= 0.78
	dur_exposta *= 0.88


## --- núcleo / dano -------------------------------------------------

func _piscar(ligado: bool) -> void:
	super._piscar(ligado)
	if _corpo and not _exposta:
		_corpo.frame = 2 if ligado else 0


func _mostrar_nucleo(v: bool) -> void:
	_exposta = v
	_pulso = 0.0
	if _corpo:
		_corpo.frame = 3 if v else 0
	if _nucleo:
		_nucleo.scale = Vector2.ONE * (1.0 if v else 0.4)
		var luz: PointLight2D = _nucleo.get_node_or_null("Luz")
		if luz:
			luz.energy = 1.7 if v else 0.12
		var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
		if brilho:
			brilho.visible = v


func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false) -> void:
	if _ja_derrotado:
		return
	provocar()
	if not _exposta:
		Som.toca("bloqueio", -9.0, 0.7)
		if _sprite:
			_sprite.modulate = Color(1.2, 1.0, 1.3)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao, critico)


## --- utilitários --------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return _origem.y + 200.0
	var de := Vector2(x, _origem.y - 60.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 760.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else _origem.y + 300.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)


static var _luz_cache: GradientTexture2D

func _tex_luz() -> GradientTexture2D:
	if _luz_cache:
		return _luz_cache
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 64
	tex.height = 64
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	_luz_cache = tex
	return tex
