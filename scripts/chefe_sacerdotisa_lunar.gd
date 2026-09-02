class_name ChefeSacerdotisaLunar
extends ChefeBase
## Região III / nível 14 -- A Sacerdotisa Lunar do Observatório. Paira no
## alto, rodeada de luas falsas, e ataca pela lua:
##   * LUAS FALSAS -- arremessa crescentes que perseguem um pouco e depois
##     seguem a direito.
##   * MARÉ LUNAR  -- alivia a gravidade da Koliani (`definir_grav_escala`)
##     durante uns segundos E faz chover METEOROS púrpura em pontos
##     telegrafados -- flutua-se para dentro deles se não se tiver cuidado.
## Depois de cada ataque "ajoelha-se à lua" (desce, o disco lunar das
## costas abre-se: EXPOSTA, dano a dobrar). Fora disso o véu de luar
## absorve os golpes.
## Fase 2 (< 50% vida): a lua fica vermelha -- maré mais forte e mais
## longa, mais meteoros, crescentes aos pares.

const CRESCENTE_VEL := 250.0

enum Fase { DORME, DECIDE, LUAS_TEL, LUAS, MARE_TEL, MARE, EXPOSTA }

@export var dist_deteta := 640.0
@export var altura_voo := 200.0
@export var altura_exposta := 96.0
@export var dur_tel := 0.6
@export var dur_exposta := 1.5
@export var dur_mare := 3.0
@export var dano_crescente := 15
@export var dano_meteoro := 20

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposta := false
var _ciclos := 0
var _vida_max := 380
var _chao_cache := 0.0
var _alvo_y := 0.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")
@onready var _luas: Node2D = get_node_or_null("Sprite/Luas")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 540)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_alvo_y = _origem.y
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite:
		_sprite.position.y = sin(_pulso * 2.0) * (6.0 if not _exposta else 2.0)
	if _luas:
		_luas.rotation += dt * (0.8 if not _fase2 else 1.5)
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
	_encarar_koliani()

	match _fase:
		Fase.DORME:
			_alvo_y = _chao_cache - altura_voo
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_alvo_y = _chao_cache - altura_voo
			if _t >= 0.3:
				_escolher()
		Fase.LUAS_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_lancar_luas()
				_ir(Fase.LUAS)
		Fase.LUAS:
			if _t >= 0.5:
				_ir(Fase.EXPOSTA)
		Fase.MARE_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_mare_lunar()
				_ir(Fase.MARE)
		Fase.MARE:
			# meteoros em vagas durante a maré
			if fmod(_t, 0.5) < dt:
				_meteoro()
			if _t >= (dur_mare * (1.35 if _fase2 else 1.0)):
				_repor_gravidade()
				_ir(Fase.EXPOSTA)
		Fase.EXPOSTA:
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


func _escolher() -> void:
	if _ciclos % 2 == 1:
		_ir(Fase.MARE_TEL)
	else:
		_ir(Fase.LUAS_TEL)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 380.0


## --- ataques ---------------------------------------------------------

func _lancar_luas() -> void:
	Som.toca("gelo", -8.0, 0.7)
	var n := 4 if _fase2 else 2
	var base := _dir_para_koliani_vec()
	for i in n:
		var ang := (i - (n - 1) * 0.5) * 0.28
		_crescente(base.rotated(ang))


func _crescente(dir: Vector2) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var c := Area2D.new()
	c.collision_layer = 0
	c.collision_mask = 2
	c.global_position = global_position + Vector2(0, 6)
	pai.add_child(c)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 10.0
	forma.shape = cs
	c.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.85, 0.85, 1.0, 0.9)
	poly.polygon = PackedVector2Array([Vector2(-10, -7), Vector2(3, -10), Vector2(9, 0), Vector2(3, 10), Vector2(-10, 7), Vector2(-3, 0)])
	c.add_child(poly)
	var luz := PointLight2D.new()
	luz.texture = _tex_luz()
	luz.energy = 0.6
	luz.color = Color(0.8, 0.82, 1.0)
	luz.scale = Vector2(0.35, 0.35)
	c.add_child(luz)
	var dano := int(round(dano_crescente * (1.1 if _fase2 else 1.0)))
	# curva a meio para o sítio da Koliani (uma "perseguição" leve, barata):
	# ponto de controlo puxado na direção dela no momento do disparo.
	var k := _obter_koliani()
	var meio := c.global_position + dir * 400.0
	if k:
		meio = meio.lerp(k.global_position, 0.4)
	var fim := meio + (meio - c.global_position).normalized() * 900.0
	poly.rotation = dir.angle()
	c.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(dano, signf(dir.x))
		c.queue_free())
	var t := c.create_tween()
	t.tween_property(c, "global_position", meio, 400.0 / CRESCENTE_VEL).set_trans(Tween.TRANS_SINE)
	t.tween_property(c, "global_position", fim, 900.0 / CRESCENTE_VEL)
	t.tween_callback(c.queue_free)


func _mare_lunar() -> void:
	Som.toca("gelo", -8.0, 0.5)
	_abanar_camera(4.0)
	var k := _obter_koliani()
	if k and k.has_method("definir_grav_escala"):
		k.definir_grav_escala(0.22 if _fase2 else 0.32)


func _repor_gravidade() -> void:
	var k := _obter_koliani()
	if k and k.has_method("definir_grav_escala"):
		k.definir_grav_escala(1.0)


func _meteoro() -> void:
	var pai := get_parent()
	if pai == null:
		return
	var k := _obter_koliani()
	var alvo_x := (k.global_position.x if k else global_position.x) + randf_range(-140.0, 140.0)
	var chao := _chao_y(alvo_x)
	# marca no chão
	var marca := Polygon2D.new()
	marca.color = Color(0.75, 0.4, 1.0, 0.5)
	marca.polygon = PackedVector2Array([Vector2(-26, 0), Vector2(26, 0), Vector2(20, 8), Vector2(-20, 8)])
	marca.global_position = Vector2(alvo_x, chao - 4.0)
	pai.add_child(marca)

	var m := Area2D.new()
	m.collision_layer = 0
	m.collision_mask = 2
	m.monitoring = false
	m.global_position = Vector2(alvo_x + 120.0, chao - 520.0)
	pai.add_child(m)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 18.0
	forma.shape = cs
	m.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.6, 0.32, 0.9, 1.0)
	poly.polygon = PackedVector2Array([Vector2(-16, 0), Vector2(0, -16), Vector2(16, 0), Vector2(0, 16)])
	m.add_child(poly)
	var luz := PointLight2D.new()
	luz.texture = _tex_luz()
	luz.energy = 0.8
	luz.color = Color(0.7, 0.4, 1.0)
	luz.scale = Vector2(0.5, 0.5)
	m.add_child(luz)
	var dano := int(round(dano_meteoro * (1.15 if _fase2 else 1.0)))
	m.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(dano, signf(b.global_position.x - m.global_position.x)))
	var t := m.create_tween()
	t.tween_interval(0.5)
	t.tween_callback(func() -> void: m.monitoring = true)
	t.tween_property(m, "global_position", Vector2(alvo_x, chao - 6.0), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void:
		_abanar_camera(3.0)
		for c in m.get_overlapping_bodies():
			if c is Koliani:
				c.receber_dano(dano, signf(c.global_position.x - m.global_position.x)))
	t.tween_property(poly, "modulate:a", 0.0, 0.25)
	t.parallel().tween_property(marca, "modulate:a", 0.0, 0.25)
	t.tween_callback(func() -> void:
		marca.queue_free()
		m.queue_free())


func _dir_para_koliani_vec() -> Vector2:
	var d := _vetor_para_koliani()
	return d.normalized() if d.length() > 1.0 else Vector2(_direcao, 0.2).normalized()


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -8.0, 0.7)
	_abanar_camera(8.0)
	dur_tel *= 0.75
	dur_exposta *= 0.85
	var disco := get_node_or_null("Sprite/Luas") as CanvasItem
	if disco:
		disco.modulate = Color(1.4, 0.5, 0.5)


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


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	if _ja_derrotado:
		return
	provocar()
	if not _exposta:
		Som.toca("bloqueio", -9.0, 0.7)
		if _sprite:
			_sprite.modulate = Color(1.2, 1.2, 1.4)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao)


func _cair_derrotado() -> void:
	_repor_gravidade()
	super._cair_derrotado()


func _exit_tree() -> void:
	_repor_gravidade()


## --- utilitários --------------------------------------------------

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
