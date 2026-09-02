class_name ChefeKolianiSombria
extends ChefeBase
## Região VI / nível 27 -- Koliani Sombria, do Salão dos Espelhos. Um
## reflexo da Koliani: os mesmos movimentos, versões sombrias das
## habilidades, tudo a púrpura. Testa tudo o que o jogador aprendeu.
##   * COMBO   -- 3 golpes de espada em avanço.
##   * DASH    -- arremete como o dash da Koliani.
##   * ROLA    -- rola e sai com um golpe.
##   * PROJETIL-- lança projéteis sombrios num leque.
##   * SALTO   -- salta e cai com um golpe.
## Espelha: liga-se a `Koliani.magia_lancada` e devolve um projétil.
## Recuperação depois de COMBO / PROJETIL = EXPOSTO (o coração magenta,
## dano a dobrar).
## Fase 2 (< 50% vida): versões alternativas -- o dash vira um pestanejo
## (teleporta), o projétil persegue, o combo ganha um 4.º golpe em onda.

const PROJ_VEL := 380.0

enum Fase { DORME, DECIDE, COMBO_TEL, COMBO, DASH_TEL, DASH, ROLA_TEL, ROLA, PROJ_TEL, PROJ, SALTO_TEL, SALTO, ESPELHO_TEL, ESPELHO, EXPOSTO }

@export var dist_deteta := 640.0
@export var vel_avanco := 190.0
@export var vel_dash := 620.0
@export var vel_rola := 360.0
@export var dur_tel := 0.4
@export var dur_exposto := 1.1
@export var dano_golpe := 15
@export var dano_dash := 18
@export var dano_proj := 13

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposto := false
var _ciclos := 0
var _golpes := 0
var _vida_max := 440
var _chao_cache := 0.0
var _dash_dir := 1.0
var _koliani_lancou := 0.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 820)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_mostrar_nucleo(false)
	call_deferred("_ligar")


func _ligar() -> void:
	var k := _obter_koliani()
	if k and k.has_signal("magia_lancada") and not k.magia_lancada.is_connected(_ao_magia):
		k.magia_lancada.connect(_ao_magia)


func _ao_magia() -> void:
	_koliani_lancou = 1.4


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	_koliani_lancou = maxf(0.0, _koliani_lancou - dt)
	if _nucleo and _exposto:
		var p := 1.0 + 0.2 * sin(_pulso * 10.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(global_position.x)
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_virar_fase2()

	if not is_on_floor() and _fase != Fase.DASH:
		velocity.y += GRAVIDADE * dt
	elif is_on_floor() and _fase not in [Fase.SALTO]:
		velocity.y = 0.0
	if _fase not in [Fase.COMBO, Fase.DASH, Fase.ROLA]:
		velocity.x = move_toward(velocity.x, 0.0, 1400.0 * dt)

	match _fase:
		Fase.DORME:
			_encarar_koliani()
			if _ve_koliani():
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_encarar_koliani()
			var dx := _vetor_para_koliani().x
			if absf(dx) > 120.0:
				velocity.x = signf(dx) * vel_avanco
			if _t >= 0.18:
				_escolher()
		Fase.COMBO_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_golpes = 0
				_ir(Fase.COMBO)
		Fase.COMBO:
			velocity.x = _direcao * vel_avanco * 0.8
			var maxg := 4 if _fase2 else 3
			if _t >= 0.12 * (_golpes + 1) and _golpes < maxg:
				_golpes += 1
				if _golpes == 4:
					_onda_de_golpe()
				else:
					_golpe_frontal(dano_golpe)
			if _t >= 0.12 * maxg + 0.14:
				_ir(Fase.EXPOSTO)
		Fase.DASH_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_dash_dir = _dir_para_koliani()
				if _fase2:
					# pestanejo: teleporta para o lado da Koliani
					var x := clampf(_x_koliani() - _dash_dir * 80.0, _origem.x - 360.0, _origem.x + 360.0)
					global_position.x = x
					Som.toca("projetil", -10.0, 0.6)
				Som.toca("investida", -6.0, 1.0)
				_ataque_forte = 0.3
				_ir(Fase.DASH)
		Fase.DASH:
			velocity.x = _dash_dir * vel_dash
			velocity.y = 0.0
			if _t < 0.05:
				_golpe_frontal(dano_dash, 96.0)
			if _t >= 0.22:
				_ir(Fase.DECIDE)
		Fase.ROLA_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel * 0.7:
				_piscar(false)
				_ir(Fase.ROLA)
		Fase.ROLA:
			velocity.x = _direcao * vel_rola
			if _t >= 0.3:
				_golpe_frontal(dano_golpe, 90.0)
				_ir(Fase.EXPOSTO)
		Fase.PROJ_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_projeteis()
				_ir(Fase.PROJ)
		Fase.PROJ:
			if _t >= 0.35:
				_ir(Fase.EXPOSTO)
		Fase.SALTO_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				velocity.y = -440.0
				velocity.x = signf(_x_koliani() - global_position.x) * 200.0
				_ir(Fase.SALTO)
		Fase.SALTO:
			velocity.y += GRAVIDADE * dt
			if is_on_floor() and _t > 0.12:
				_golpe_frontal(dano_dash, 120.0)
				_abanar_camera(4.0)
				_ir(Fase.EXPOSTO)
		Fase.ESPELHO_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel * 0.7:
				_piscar(false)
				_disparar_proj(_dir_proj_para_koliani(), 1.0)
				_ir(Fase.ESPELHO)
		Fase.ESPELHO:
			if _t >= 0.3:
				_ir(Fase.EXPOSTO)
		Fase.EXPOSTO:
			velocity.x = move_toward(velocity.x, 0.0, 1400.0 * dt)
			if not _exposto:
				_exposto = true
				_mostrar_nucleo(true)
			if _t >= dur_exposto:
				_exposto = false
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.DECIDE)

	move_and_slide()
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


func _escolher() -> void:
	if _koliani_lancou > 0.0 and _ciclos % 2 == 1:
		_ir(Fase.ESPELHO_TEL)
		return
	var dx := absf(_vetor_para_koliani().x)
	match _ciclos % 4:
		0:
			_ir(Fase.COMBO_TEL if dx < 200.0 else Fase.DASH_TEL)
		1:
			_ir(Fase.PROJ_TEL)
		2:
			_ir(Fase.ROLA_TEL if dx < 240.0 else Fase.SALTO_TEL)
		_:
			_ir(Fase.SALTO_TEL if dx > 200.0 else Fase.COMBO_TEL)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 340.0


## --- ataques ---------------------------------------------------------

func _golpe_frontal(dano: int, alcance := 82.0) -> void:
	Som.toca("golpe_pesado", -8.0, 1.15)
	var k := _obter_koliani()
	if k == null:
		return
	var d := _vetor_para_koliani()
	if absf(d.x) <= alcance and absf(d.y) <= 74.0 and signf(d.x) == _direcao:
		k.receber_dano(int(round(dano * (1.12 if _fase2 else 1.0))), _direcao)


func _onda_de_golpe() -> void:
	Som.toca("onda", -6.0, 1.1)
	var pai := get_parent()
	if pai == null:
		return
	var o := Area2D.new()
	o.collision_layer = 0
	o.collision_mask = 2
	o.global_position = global_position + Vector2(_direcao * 30.0, -16.0)
	pai.add_child(o)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(30, 44)
	forma.shape = rs
	o.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.7, 0.4, 1.0, 0.6)
	poly.polygon = PackedVector2Array([Vector2(-14, 20), Vector2(-6, -20), Vector2(8, -18), Vector2(14, 22)])
	o.add_child(poly)
	var dir := _direcao
	o.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(16, dir))
	var t := o.create_tween()
	t.tween_property(o, "global_position:x", global_position.x + dir * 640.0, 0.5)
	t.parallel().tween_property(poly, "modulate:a", 0.0, 0.5)
	t.tween_callback(o.queue_free)


func _projeteis() -> void:
	Som.toca("projetil", -9.0, 0.7)
	var base := _dir_proj_para_koliani()
	var esp := 0.24
	for a in [-esp, 0.0, esp]:
		_disparar_proj(base.rotated(a), 1.15 if _fase2 else 1.0)


func _dir_proj_para_koliani() -> Vector2:
	var k := _obter_koliani()
	if k == null:
		return Vector2(_direcao, 0)
	return (k.global_position + Vector2(0, -16) - (global_position + Vector2(0, -16))).normalized()


func _disparar_proj(dir: Vector2, mult: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var p := Area2D.new()
	p.collision_layer = 0
	p.collision_mask = 2
	p.global_position = global_position + Vector2(0, -16)
	pai.add_child(p)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 8.0
	forma.shape = cs
	p.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.7, 0.35, 1.0, 0.95)
	poly.polygon = PackedVector2Array([Vector2(-8, 0), Vector2(0, -7), Vector2(8, 0), Vector2(0, 7)])
	p.add_child(poly)
	var luz := PointLight2D.new()
	luz.texture = _tex_luz()
	luz.energy = 0.6
	luz.color = Color(0.75, 0.4, 1.0)
	luz.scale = Vector2(0.35, 0.35)
	p.add_child(luz)
	var dano := int(round(dano_proj * mult))
	var homing: bool = _fase2
	p.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(dano, signf(dir.x))
		p.queue_free())
	if homing:
		var k := _obter_koliani()
		var meio := p.global_position + dir * 300.0
		if k:
			meio = meio.lerp(k.global_position, 0.45)
		var fim := meio + (meio - p.global_position).normalized() * 800.0
		var t := p.create_tween()
		t.tween_property(p, "global_position", meio, 300.0 / PROJ_VEL).set_trans(Tween.TRANS_SINE)
		t.tween_property(p, "global_position", fim, 800.0 / PROJ_VEL)
		t.tween_callback(p.queue_free)
	else:
		var t := p.create_tween()
		t.tween_property(p, "global_position", p.global_position + dir * 1400.0, 1400.0 / PROJ_VEL)
		t.tween_callback(p.queue_free)


## --- fase 2 --------------------------------------------------------

func _virar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -6.0, 0.8)
	_abanar_camera(8.0)
	dur_tel *= 0.82
	dur_exposto *= 0.85
	if _sprite:
		_sprite.modulate = Color(1.3, 1.0, 1.4)
		create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.4)


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
			luz.energy = 1.7 if v else 0.12
		var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
		if brilho:
			brilho.visible = v


func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false) -> void:
	if _ja_derrotado:
		return
	provocar()
	super.receber_dano(quantidade, dir_empurrao, critico)


## --- utilitários --------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


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
