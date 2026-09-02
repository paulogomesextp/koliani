class_name ChefeSinoVivo
extends ChefeBase
## Região III / nível 11 -- O Sino Vivo. Uma criatura presa dentro de um
## sino de bronze colossal que paira no cimo da Torre dos Sinos. Baloiça
## como um pêndulo e ataca por SOM:
##   * BADALADA -- baloiça com força e larga um anel de choque que corre
##     rente ao chão (salta-se por cima).
##   * GRITO    -- dispara crescentes sónicos na direção da Koliani (fase 2:
##     em roda, 360°).
##   * QUEDA    -- sobe e despenca-se sobre a Koliani; baque radial e fica
##     preso um instante (EXPOSTO) -- o badalo/rosto à vista, dano a dobrar.
## Fase 2 (< 50% vida): fendas no bronze, badaladas aos pares, telégrafos
## curtos.

const CRESCENTE_VEL := 300.0

enum Fase { DORME, DECIDE, BADALA_TEL, BADALA, GRITO_TEL, GRITO, QUEDA_SOBE, QUEDA_CAI, EXPOSTO }

@export var dist_deteta := 560.0
@export var altura_base := 150.0
@export var balanco := 0.32
@export var dur_tel := 0.6
@export var dur_exposto := 1.45
@export var dano_onda := 20
@export var dano_crescente := 15
@export var dano_baque := 24

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposto := false
var _ciclos := 0
var _vida_max := 400
var _chao_cache := 0.0
var _base := Vector2.ZERO
var _alvo_queda := 0.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 540)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_base = global_position
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite and _fase not in [Fase.QUEDA_SOBE, Fase.QUEDA_CAI, Fase.EXPOSTO]:
		_sprite.rotation = sin(_pulso * 2.0) * balanco * (1.0 if not _fase2 else 1.4)
	if _nucleo and _exposto:
		var p := 1.0 + 0.18 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(_base.x)
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_entrar_fase2()

	match _fase:
		Fase.DORME:
			if _ve_koliani():
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			global_position = global_position.lerp(_base, clampf(dt * 4.0, 0.0, 1.0))
			if _t >= 0.3:
				_escolher()
		Fase.BADALA_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_badalada()
				_ir(Fase.BADALA)
		Fase.BADALA:
			if _t >= (0.7 if _fase2 else 0.45):
				_ir(Fase.EXPOSTO)
		Fase.GRITO_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_grito()
				_ir(Fase.GRITO)
		Fase.GRITO:
			if _t >= 0.5:
				_ir(Fase.EXPOSTO)
		Fase.QUEDA_SOBE:
			var alvo := Vector2(_x_koliani(), _chao_cache - altura_base - 120.0)
			global_position = global_position.lerp(alvo, clampf(dt * 3.5, 0.0, 1.0))
			if _t >= 0.55:
				_alvo_queda = _chao_cache - 30.0
				Som.toca("sino_ataque", -6.0, 0.6)
				_ir(Fase.QUEDA_CAI)
		Fase.QUEDA_CAI:
			global_position.y = move_toward(global_position.y, _alvo_queda, 1500.0 * dt)
			if absf(global_position.y - _alvo_queda) < 4.0:
				_baque_radial()
				_ir(Fase.EXPOSTO)
		Fase.EXPOSTO:
			global_position.y = lerpf(global_position.y, _chao_cache - altura_base, clampf(dt * 2.2, 0.0, 1.0))
			if not _exposto:
				_exposto = true
				_mostrar_nucleo(true)
			if _t >= dur_exposto:
				_exposto = false
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.DECIDE)
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


func _escolher() -> void:
	match _ciclos % 3:
		0: _ir(Fase.BADALA_TEL)
		1: _ir(Fase.GRITO_TEL)
		_: _ir(Fase.QUEDA_SOBE)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 360.0


## --- ataques ---------------------------------------------------------

func _badalada() -> void:
	Som.toca("sino_ataque", -5.0, 0.55)
	_abanar_camera(5.0)
	var n := 2 if _fase2 else 1
	for i in n:
		_onda_rasteira(1.0, i * 0.22)
		_onda_rasteira(-1.0, i * 0.22 + 0.1)


func _onda_rasteira(dir: float, atraso: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var onda := Area2D.new()
	onda.collision_layer = 0
	onda.collision_mask = 2
	onda.monitoring = false
	onda.global_position = Vector2(_base.x, _chao_cache - 16.0)
	pai.add_child(onda)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(30, 40)
	forma.shape = rs
	onda.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.75, 0.82, 1.0, 0.55)
	poly.polygon = PackedVector2Array([Vector2(-14, 18), Vector2(-6, -18), Vector2(6, -18), Vector2(14, 18)])
	onda.add_child(poly)
	var dano := int(round(dano_onda * (1.1 if _fase2 else 1.0)))
	onda.body_entered.connect(func(c: Node) -> void:
		if c is Koliani:
			c.receber_dano(dano, dir))
	var t := onda.create_tween()
	t.tween_interval(atraso)
	t.tween_callback(func() -> void: onda.monitoring = true)
	t.tween_property(onda, "global_position:x", _base.x + dir * 1200.0, 1200.0 / 520.0)
	t.parallel().tween_property(poly, "modulate:a", 0.0, 1200.0 / 520.0)
	t.tween_callback(onda.queue_free)


func _grito() -> void:
	Som.toca("sino_ataque", -7.0, 0.9)
	var pai := get_parent()
	if pai == null:
		return
	if _fase2:
		for i in 8:
			_crescente(Vector2.RIGHT.rotated(TAU * float(i) / 8.0))
	else:
		var base := _dir_para_koliani_vec()
		for a in [-0.3, 0.0, 0.3]:
			_crescente(base.rotated(a))


func _crescente(dir: Vector2) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var c := Area2D.new()
	c.collision_layer = 0
	c.collision_mask = 2
	c.global_position = global_position + Vector2(0, 10)
	pai.add_child(c)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 10.0
	forma.shape = cs
	c.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.8, 0.86, 1.0, 0.85)
	poly.polygon = PackedVector2Array([Vector2(-10, -6), Vector2(4, -10), Vector2(10, 0), Vector2(4, 10), Vector2(-10, 6), Vector2(-4, 0)])
	poly.rotation = dir.angle()
	c.add_child(poly)
	var dano := int(round(dano_crescente * (1.1 if _fase2 else 1.0)))
	c.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(dano, signf(dir.x))
		c.queue_free())
	var t := c.create_tween()
	t.tween_property(c, "global_position", c.global_position + dir * 1200.0, 1200.0 / CRESCENTE_VEL)
	t.tween_callback(c.queue_free)


func _baque_radial() -> void:
	Som.toca("sino_ataque", -5.0, 0.7)
	_abanar_camera(7.0)
	var k := _obter_koliani()
	if k and absf(k.global_position.x - global_position.x) <= 150.0 and k.is_on_floor():
		k.receber_dano(int(round(dano_baque * (1.1 if _fase2 else 1.0))), signf(k.global_position.x - global_position.x))
	_onda_rasteira(1.0, 0.02)
	_onda_rasteira(-1.0, 0.02)


func _dir_para_koliani_vec() -> Vector2:
	var d := _vetor_para_koliani()
	return d.normalized() if d.length() > 1.0 else Vector2(_direcao, -0.2).normalized()


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -8.0, 0.7)
	_abanar_camera(8.0)
	dur_tel *= 0.72
	dur_exposto *= 0.85


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
		Som.toca("bloqueio", -7.0, 0.5)
		if _sprite:
			_sprite.modulate = Color(1.3, 1.25, 1.0)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		_raspao(quantidade, dir_empurrao)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao, critico)


## --- utilitários --------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return _origem.y + 120.0
	var de := Vector2(x, _origem.y - 40.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 700.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else _origem.y + 240.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)
