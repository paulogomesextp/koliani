class_name ChefeReiOssario
extends ChefeBase
## Região IV / nível 16 -- O Rei Ossário. Rei morto-vivo montado num cavalo
## esquelético. Enquanto montado:
##   * CARGA   -- galopa de um lado ao outro da arena (dano ao contacto);
##     ao travar fica a EXPOSTO (o rei descai na sela -- dano a dobrar).
##   * LANÇAS  -- arremessa lanças espectrais na direção da Koliani.
##   * CONVOCA -- levanta soldados esqueléticos (DemonioBase, vida curta).
## Fase 2 (< 50% vida): o cavalo desfaz-se -- o rei combate a pé, mais
## rápido: golpe triplo em avanço, muro de ossos à frente, mais soldados.

const LANCA_VEL := 380.0
const SOLDADO := preload("res://scenes/actors/DemonioBase.tscn")

enum Fase {
	DORME, DECIDE, CARGA_TEL, CARGA, TRAVA, LANCAS_TEL, LANCAS, CONVOCA_TEL, CONVOCA, EXPOSTO,
	DESMONTA, DECIDE2, TRIPLO_TEL, TRIPLO, MURO_TEL, MURO, EXPOSTO2,
}

@export var dist_deteta := 620.0
@export var vel_carga := 460.0
@export var vel_pe := 150.0
@export var dur_tel := 0.55
@export var dur_exposto := 1.4
@export var dano_carga := 24
@export var dano_lanca := 15
@export var dano_golpe := 18
@export var dano_muro := 20

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _pe := false
var _exposto := false
var _ciclos := 0
var _golpes := 0
var _vida_max := 500
var _chao_cache := 0.0
var _base_x := 0.0
var _carga_dir := 1.0
var _lim_esq := 0.0
var _lim_dir := 0.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 560)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_base_x = global_position.x
	_lim_esq = _base_x - 420.0
	_lim_dir = _base_x + 420.0
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _nucleo and _exposto:
		var p := 1.0 + 0.18 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(_base_x)
	if not _pe and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_ir(Fase.DESMONTA)

	if not is_on_floor():
		velocity.y += GRAVIDADE * dt
	else:
		velocity.y = 0.0
	velocity.x = 0.0

	match _fase:
		Fase.DORME:
			_encarar_koliani()
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_encarar_koliani()
			if _t >= 0.3:
				match _ciclos % 3:
					0: _ir(Fase.CARGA_TEL)
					1: _ir(Fase.LANCAS_TEL)
					_: _ir(Fase.CONVOCA_TEL)
		Fase.CARGA_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_carga_dir = _dir_para_koliani()
				Som.toca("investida", -6.0, 0.7)
				_ataque_forte = 1.2
				_ir(Fase.CARGA)
		Fase.CARGA:
			velocity.x = _carga_dir * vel_carga
			if (global_position.x <= _lim_esq and _carga_dir < 0.0) \
					or (global_position.x >= _lim_dir and _carga_dir > 0.0):
				_ir(Fase.TRAVA)
		Fase.TRAVA:
			velocity.x = -_carga_dir * 60.0 * (1.0 - clampf(_t / 0.25, 0.0, 1.0))
			if _t >= 0.25:
				_ir(Fase.EXPOSTO)
		Fase.LANCAS_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_lancas()
				_ir(Fase.LANCAS)
		Fase.LANCAS:
			if _t >= 0.4:
				_ir(Fase.EXPOSTO)
		Fase.CONVOCA_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_convocar(2)
				_ir(Fase.CONVOCA)
		Fase.CONVOCA:
			if _t >= 0.5:
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
		# --- fase 2 (a pé) --------------------------------------
		Fase.DESMONTA:
			if _t < dt:
				_desmontar()
			if _t >= 0.8:
				_ir(Fase.DECIDE2)
		Fase.DECIDE2:
			_encarar_koliani()
			# aproxima-se a pé
			var dx := _vetor_para_koliani().x
			if absf(dx) > 90.0:
				velocity.x = signf(dx) * vel_pe
			if _t >= 0.3:
				_ir(Fase.TRIPLO_TEL if _ciclos % 2 == 0 else Fase.MURO_TEL)
		Fase.TRIPLO_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel * 0.8:
				_piscar(false)
				_golpes = 0
				_ir(Fase.TRIPLO)
		Fase.TRIPLO:
			velocity.x = _direcao * vel_pe * 0.7
			if _t >= 0.14 * (_golpes + 1) and _golpes < 3:
				_golpes += 1
				_golpe_frontal(dano_golpe)
			if _t >= 0.6:
				_ir(Fase.EXPOSTO2)
		Fase.MURO_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_muro_de_ossos()
				_ir(Fase.MURO)
		Fase.MURO:
			if _t >= 0.5:
				_ir(Fase.EXPOSTO2)
		Fase.EXPOSTO2:
			velocity.x = 0.0
			if not _exposto:
				_exposto = true
				_mostrar_nucleo(true)
			if _t >= dur_exposto * 0.9:
				_exposto = false
				_mostrar_nucleo(false)
				_ciclos += 1
				if _ciclos % 3 == 2:
					_convocar(2)
				_ir(Fase.DECIDE2)

	move_and_slide()
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	if f == Fase.DESMONTA:
		_pe = true
	_fase = f
	_t = 0.0


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 300.0


## --- ataques ---------------------------------------------------------

func _lancas() -> void:
	Som.toca("investida", -8.0, 1.3)
	var pai := get_parent()
	if pai == null:
		return
	var base := _vetor_para_koliani().normalized()
	if base.length() < 0.5:
		base = Vector2(_direcao, 0)
	for a in [-0.18, 0.0, 0.18]:
		_lanca(base.rotated(a))


func _lanca(dir: Vector2) -> void:
	var pai := get_parent()
	var l := Area2D.new()
	l.collision_layer = 0
	l.collision_mask = 2
	l.global_position = global_position + Vector2(0, -20) + dir * 26.0
	pai.add_child(l)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(30, 8)
	forma.shape = rs
	l.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.85, 0.86, 0.7, 0.95)
	poly.polygon = PackedVector2Array([Vector2(-15, 0), Vector2(9, -4), Vector2(15, 0), Vector2(9, 4)])
	poly.rotation = dir.angle()
	l.add_child(poly)
	var dano := dano_lanca
	l.body_entered.connect(func(c: Node) -> void:
		if c is Koliani:
			c.receber_dano(dano, signf(dir.x))
		l.queue_free())
	var t := l.create_tween()
	t.tween_property(l, "global_position", l.global_position + dir * 1400.0, 1400.0 / LANCA_VEL)
	t.tween_callback(l.queue_free)


func _convocar(n: int) -> void:
	Som.toca("demonio_ataque", -8.0, 0.6)
	var pai := get_parent()
	if pai == null:
		return
	for i in n:
		var s := SOLDADO.instantiate()
		s.especie = "esqueleto"
		s.vida = 26
		s.dano_contacto = 14
		s.velocidade = 78.0
		s.alcance_patrulha = 300.0
		s.cor_estilhacos = Color(0.8, 0.78, 0.62)
		var x := global_position.x + (i * 2 - 1) * 70.0
		s.global_position = Vector2(x, _chao_y(x) - 20.0)
		pai.add_child(s)
		s.get_tree().create_timer(10.0).timeout.connect(func() -> void:
			if is_instance_valid(s) and not s._morto:
				s.soltar_estilhacos()
				s.queue_free())


func _golpe_frontal(dano: int) -> void:
	Som.toca("demonio_ataque", -7.0, 1.0)
	var k := _obter_koliani()
	if k == null:
		return
	var d := _vetor_para_koliani()
	if absf(d.x) <= 80.0 and absf(d.y) <= 70.0 and signf(d.x) == _direcao:
		k.receber_dano(dano, _direcao)


func _muro_de_ossos() -> void:
	Som.toca("onda", -6.0, 0.7)
	_abanar_camera(4.0)
	var pai := get_parent()
	if pai == null:
		return
	var dir := _dir_para_koliani()
	var m := Area2D.new()
	m.collision_layer = 0
	m.collision_mask = 2
	m.monitoring = false
	var x := global_position.x + dir * 90.0
	m.global_position = Vector2(x, _chao_y(x))
	pai.add_child(m)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(40, 90)
	forma.shape = rs
	forma.position = Vector2(0, -45)
	m.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.82, 0.8, 0.64, 1.0)
	poly.polygon = PackedVector2Array([Vector2(-18, 0), Vector2(-12, -80), Vector2(0, -50), Vector2(12, -84), Vector2(18, 0)])
	poly.scale.y = 0.0
	m.add_child(poly)
	var dano := dano_muro
	var t := m.create_tween()
	t.tween_property(poly, "scale:y", 1.0, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(func() -> void: m.monitoring = true)
	t.tween_callback(func() -> void:
		for c in m.get_overlapping_bodies():
			if c is Koliani:
				c.receber_dano(dano, dir))
	t.tween_interval(0.6)
	t.tween_callback(func() -> void: m.monitoring = false)
	t.tween_property(poly, "scale:y", 0.0, 0.2)
	t.tween_callback(m.queue_free)


## --- transição de fase ---------------------------------------------

func _desmontar() -> void:
	Som.toca("chefe_cai", -6.0, 0.7)
	_abanar_camera(8.0)
	dur_tel *= 0.75
	dur_exposto *= 0.85
	dano_contacto = int(round(dano_contacto * 0.8))  # sem cavalo, o contacto pesa menos
	var p := CPUParticles2D.new()
	p.global_position = global_position + Vector2(0, 10)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 30
	p.lifetime = 0.7
	p.spread = 120.0
	p.direction = Vector2(-_direcao, -0.3)
	p.gravity = Vector2(0, 700)
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 240.0
	p.color = Color(0.82, 0.8, 0.64)
	add_sibling(p)
	p.get_tree().create_timer(1.2).timeout.connect(p.queue_free)
	if _corpo:
		_corpo.frame = 1
	_convocar(2)


## --- núcleo / dano -------------------------------------------------

func _frame_base() -> int:
	return 1 if _pe else 0


func _piscar(ligado: bool) -> void:
	super._piscar(ligado)
	if _corpo and not _exposto:
		_corpo.frame = 2 if ligado else _frame_base()


func _mostrar_nucleo(v: bool) -> void:
	_exposto = v
	_pulso = 0.0
	if _corpo:
		_corpo.frame = 3 if v else _frame_base()
	if _nucleo:
		_nucleo.scale = Vector2.ONE * (1.0 if v else 0.4)
		var luz: PointLight2D = _nucleo.get_node_or_null("Luz")
		if luz:
			luz.energy = 1.6 if v else 0.12
		var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
		if brilho:
			brilho.visible = v


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	if _ja_derrotado:
		return
	provocar()
	if not _exposto:
		Som.toca("bloqueio", -9.0, 0.6)
		if _sprite:
			_sprite.modulate = Color(1.2, 1.2, 1.0)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao)


## --- utilitários --------------------------------------------------

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
