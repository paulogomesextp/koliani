class_name ChefeCapitaoNegro
extends ChefeBase
## Região VI / nível 26 -- O Capitão Negro dos Portões de Zeriko. Twist: não
## luta como os chefes anteriores -- luta como uma PERSONAGEM, telégrafos
## curtos e ataques muito mais rápidos. Espada e escudo enormes.
##   * COMBO  -- 4 golpes rápidos em avanço (6 na fase 2).
##   * BASH   -- investida com o escudo (empurra + dano).
##   * GUARDA -- ergue o escudo: os golpes de frente são bloqueados e
##     devolvidos (contra-ataque curto). Dura pouco.
##   * MERGULHO-- salta e cai com um golpe de cima; racha o chão ao aterrar.
## Recuperação depois de COMBO / MERGULHO = EXPOSTO (o elmo/peito, x2).
## Fase 2 (< 50% vida): o escudo estilhaça, pega na espada com as duas
## mãos -- ainda mais rápido, combo de 6, e um rodopio (varredura 360).

enum Fase { DORME, DECIDE, COMBO_TEL, COMBO, BASH_TEL, BASH, GUARDA, MERGULHO_TEL, MERGULHO, RODOPIO_TEL, RODOPIO, EXPOSTO }

@export var dist_deteta := 620.0
@export var vel_avanco := 200.0
@export var vel_bash := 620.0
@export var dur_tel := 0.34
@export var dur_exposto := 1.05
@export var dur_guarda := 1.0
@export var dano_golpe := 16
@export var dano_bash := 20
@export var dano_mergulho := 24

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposto := false
var _ciclos := 0
var _golpes := 0
var _vida_max := 480
var _chao_cache := 0.0
var _bash_dir := 1.0
var _mergulho_alvo := 0.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 780)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _nucleo and _exposto:
		var p := 1.0 + 0.18 * sin(_pulso * 10.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(global_position.x)
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_virar_fase2()

	if not is_on_floor() and _fase not in [Fase.MERGULHO]:
		velocity.y += GRAVIDADE * dt
	elif is_on_floor():
		velocity.y = 0.0
	if _fase not in [Fase.COMBO, Fase.BASH, Fase.MERGULHO, Fase.RODOPIO]:
		velocity.x = move_toward(velocity.x, 0.0, 1400.0 * dt)

	match _fase:
		Fase.DORME:
			_encarar_koliani()
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_encarar_koliani()
			# aproxima-se depressa
			var dx := _vetor_para_koliani().x
			if absf(dx) > 110.0:
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
			var passo := 0.11
			var maxg := 6 if _fase2 else 4
			if _t >= passo * (_golpes + 1) and _golpes < maxg:
				_golpes += 1
				_golpe_frontal(dano_golpe)
			if _t >= passo * maxg + 0.12:
				_ir(Fase.EXPOSTO)
		Fase.BASH_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_bash_dir = _dir_para_koliani()
				Som.toca("investida", -5.0, 1.0)
				_ataque_forte = 0.3
				_ir(Fase.BASH)
		Fase.BASH:
			velocity.x = _bash_dir * vel_bash
			if _t < 0.05:
				_golpe_frontal(dano_bash, 100.0)
			if _t >= 0.3:
				_ir(Fase.DECIDE)
		Fase.GUARDA:
			_encarar_koliani()
			velocity.x = _dir_para_koliani() * 70.0
			if _corpo and not _fase2:
				_corpo.frame = 2
			if _t >= dur_guarda:
				if _corpo:
					_corpo.frame = 0
				_ir(Fase.DECIDE)
		Fase.MERGULHO_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_mergulho_alvo = _x_koliani()
				velocity.y = -420.0
				velocity.x = signf(_mergulho_alvo - global_position.x) * 220.0
				Som.toca("investida", -5.0, 0.8)
				_ir(Fase.MERGULHO)
		Fase.MERGULHO:
			velocity.y += GRAVIDADE * 1.3 * dt
			if is_on_floor() and _t > 0.1:
				_racha_chao()
				_ir(Fase.EXPOSTO)
		Fase.RODOPIO_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_rodopio()
				_ir(Fase.RODOPIO)
		Fase.RODOPIO:
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

	move_and_slide()
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


func _escolher() -> void:
	var dx := absf(_vetor_para_koliani().x)
	if _fase2 and _ciclos % 4 == 3:
		_ir(Fase.RODOPIO_TEL)
	elif _ciclos % 3 == 1 and not _fase2:
		_ir(Fase.GUARDA)
	elif dx > 260.0:
		_ir(Fase.BASH_TEL if randf() < 0.5 else Fase.MERGULHO_TEL)
	elif _ciclos % 2 == 0:
		_ir(Fase.COMBO_TEL)
	else:
		_ir(Fase.MERGULHO_TEL)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 320.0


## --- ataques ---------------------------------------------------------

func _golpe_frontal(dano: int, alcance := 84.0) -> void:
	Som.toca("demonio_ataque", -8.0, 1.2)
	var k := _obter_koliani()
	if k == null:
		return
	var d := _vetor_para_koliani()
	if absf(d.x) <= alcance and absf(d.y) <= 74.0 and signf(d.x) == _direcao:
		k.receber_dano(int(round(dano * (1.15 if _fase2 else 1.0))), _direcao)


func _racha_chao() -> void:
	Som.toca("onda", -5.0, 0.8)
	_abanar_camera(6.0)
	var k := _obter_koliani()
	if k and absf(_vetor_para_koliani().x) <= 160.0 and k.is_on_floor():
		k.receber_dano(int(round(dano_mergulho * (1.15 if _fase2 else 1.0))), _dir_para_koliani())
	var p := CPUParticles2D.new()
	p.global_position = global_position + Vector2(0, 34)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 22
	p.lifetime = 0.5
	p.spread = 30.0
	p.direction = Vector2.UP
	p.gravity = Vector2(0, 900)
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 300.0
	p.color = Color(0.7, 0.4, 0.9)
	add_sibling(p)
	p.get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func _rodopio() -> void:
	Som.toca("investida", -5.0, 1.4)
	var pai := get_parent()
	if pai == null:
		return
	var g := Area2D.new()
	g.collision_layer = 0
	g.collision_mask = 2
	g.global_position = global_position + Vector2(0, -20)
	pai.add_child(g)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 90.0
	forma.shape = cs
	g.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.7, 0.4, 1.0, 0.4)
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a), sin(a)) * 90.0)
	poly.polygon = pts
	g.add_child(poly)
	var dano := int(round(18 * 1.15))
	var t := g.create_tween()
	t.tween_callback(func() -> void:
		for b in g.get_overlapping_bodies():
			if b is Koliani:
				b.receber_dano(dano, signf(b.global_position.x - g.global_position.x)))
	t.tween_property(poly, "modulate:a", 0.0, 0.4)
	t.tween_callback(g.queue_free)


## --- fase 2 --------------------------------------------------------

func _virar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -6.0, 0.8)
	Som.toca("onda", -8.0, 0.7)
	_abanar_camera(8.0)
	dur_tel *= 0.8
	dur_exposto *= 0.85
	dur_guarda *= 0.6


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


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	if _ja_derrotado:
		return
	provocar()
	if _fase == Fase.GUARDA and signf(dir_empurrao) == -_direcao:
		Som.toca("bloqueio", -6.0, 1.0)
		if _sprite:
			_sprite.modulate = Color(1.5, 1.5, 1.7)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		# contra-ataque curto
		var k := _obter_koliani()
		if k and absf(_vetor_para_koliani().x) <= 90.0:
			k.receber_dano(10, -_direcao)
		return
	if not _exposto:
		Som.toca("bloqueio", -9.0, 0.6)
		if _sprite:
			_sprite.modulate = Color(1.3, 1.2, 1.4)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao)


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
