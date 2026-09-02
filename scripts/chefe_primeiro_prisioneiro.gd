class_name ChefePrimeiroPrisioneiro
extends ChefeBase
## Região II / nível 10 -- O Primeiro Prisioneiro. O herói antigo que tentou
## derrotar Zeriko e ficou preso na Cela Zero. Empunha uma espada como a da
## Koliani e LUTA como ela: combo de três golpes, arremesso (dash) e uma
## GUARDA que apara os golpes de frente. IMITA-A: se a Koliani lançou magia
## há pouco, ele devolve um dardo.
##
## Janela de dano (EXPOSTA, dano a dobrar) = a recuperação depois de cada
## COMBO/DASH. Durante a GUARDA os golpes de frente são aparados.
##
## Fase 2 (< 50% vida): a armadura estilhaça e ele vira uma criatura de
## energia púrpura -- flutua, teleporta-se, atira dardos em leque e, de vez
## em quando, "reforma-se" (imóvel, núcleo bem aberto: janela longa).
##
## NOTA: os diálogos importantes desta luta ainda não têm sistema de texto
## no jogo -- ficam pela pista `cela_zero_o_primeiro` até haver um.

const DARDO_VEL := 320.0

enum Fase { DORME, DECIDE, COMBO_TEL, COMBO, DASH_TEL, DASH, GUARDA, ESPELHO_TEL, ESPELHO,
	EXPOSTA, DECIDE2, TP, LEQUE_TEL, LEQUE, REFORMA_TEL, REFORMA }

@export var dist_deteta := 560.0
@export var vel_combo := 150.0
@export var vel_dash := 520.0
@export var dur_tel := 0.5
@export var dur_exposta := 1.3
@export var dur_guarda := 1.6
@export var dano_golpe := 18
@export var dano_dash := 22
@export var dano_dardo := 14
@export var altura_voo := 120.0

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposta := false
var _ciclos := 0
var _golpes := 0
var _vida_max := 460
var _chao_cache := 0.0
var _base_x := 0.0
var _koliani_lancou := 0.0
var _dash_dir := 1.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 480)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_base_x = global_position.x
	_mostrar_nucleo(false)
	falas_intro = [
		{ "quem": "boss.primeiro_prisioneiro", "texto": "dlg.primeiro.intro.1" },
		{ "quem": "boss.primeiro_prisioneiro", "texto": "dlg.primeiro.intro.2" },
	]
	falas_fim = [
		{ "quem": "boss.primeiro_prisioneiro", "texto": "dlg.primeiro.win.1" },
	]
	call_deferred("_ligar_a_koliani")


func _ligar_a_koliani() -> void:
	var k := _obter_koliani()
	if k and k.has_signal("magia_lancada") and not k.magia_lancada.is_connected(_ao_magia_koliani):
		k.magia_lancada.connect(_ao_magia_koliani)


func _ao_magia_koliani() -> void:
	_koliani_lancou = 1.6


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	_koliani_lancou = maxf(0.0, _koliani_lancou - dt)
	if _fase2 and _sprite:
		_sprite.modulate = Color(1.15, 0.6, 1.35, 0.92 + 0.06 * sin(_pulso * 6.0))
	if _nucleo and (_exposta or _fase2):
		var p := (1.0 if _exposta else 0.55) + 0.16 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(_base_x)
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_virar_energia()

	if not is_on_floor() and not _fase2 and _fase not in [Fase.DASH]:
		velocity.y += GRAVIDADE * dt
	else:
		velocity.y = 0.0

	match _fase:
		Fase.DORME:
			_encarar_koliani()
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * dt)
			_encarar_koliani()
			if _t >= 0.28:
				_escolher()
		Fase.COMBO_TEL:
			velocity.x = 0.0
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_golpes = 0
				_ir(Fase.COMBO)
		Fase.COMBO:
			velocity.x = _direcao * vel_combo
			if _t >= 0.16 * (_golpes + 1) and _golpes < 3:
				_golpes += 1
				_golpe(dano_golpe)
			if _t >= 0.62:
				_ir(Fase.EXPOSTA)
		Fase.DASH_TEL:
			velocity.x = 0.0
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_dash_dir = _dir_para_koliani()
				Som.toca("investida", -6.0, 1.1)
				_ataque_forte = 0.4
				_ir(Fase.DASH)
		Fase.DASH:
			velocity.x = _dash_dir * vel_dash
			if _t < 0.04:
				_golpe(dano_dash, 70.0)
			if _t >= 0.34:
				velocity.x = 0.0
				_ir(Fase.EXPOSTA)
		Fase.GUARDA:
			_encarar_koliani()
			velocity.x = _dir_para_koliani() * 60.0
			if _corpo:
				_corpo.frame = 2
			if _t >= dur_guarda:
				if _corpo:
					_corpo.frame = 0
				_ir(Fase.DECIDE)
		Fase.ESPELHO_TEL:
			velocity.x = 0.0
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel * 0.8:
				_piscar(false)
				_dardo(global_position + Vector2(0, -14), _dir_dardo(global_position))
				_ir(Fase.ESPELHO)
		Fase.ESPELHO:
			if _t >= 0.4:
				_ir(Fase.EXPOSTA)
		Fase.EXPOSTA:
			velocity.x = move_toward(velocity.x, 0.0, 1200.0 * dt)
			if not _exposta:
				_exposta = true
				_mostrar_nucleo(true)
			if _t >= dur_exposta:
				_exposta = false
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.DECIDE)
		# --- fase 2 -------------------------------------------------
		Fase.DECIDE2:
			global_position.y = lerpf(global_position.y, _chao_cache - altura_voo, clampf(dt * 3.0, 0.0, 1.0))
			_encarar_koliani()
			if _t >= 0.24:
				_escolher2()
		Fase.TP:
			if _t < dt:
				if _sprite:
					create_tween().tween_property(_sprite, "modulate:a", 0.1, 0.14)
			if _t >= 0.2:
				var lado := -1.0 if randf() < 0.5 else 1.0
				var x := clampf(_x_koliani() + lado * randf_range(150.0, 260.0), _base_x - 340.0, _base_x + 340.0)
				_chao_cache = _chao_y(x)
				global_position = Vector2(x, _chao_cache - altura_voo)
				if _sprite:
					create_tween().tween_property(_sprite, "modulate:a", 0.92, 0.14)
				_ir(Fase.LEQUE_TEL)
		Fase.LEQUE_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel * 0.7:
				_piscar(false)
				var base := _dir_dardo(global_position + Vector2(0, -14))
				for a in [-0.3, 0.0, 0.3]:
					_dardo(global_position + Vector2(0, -14), base.rotated(a))
				_ir(Fase.LEQUE)
		Fase.LEQUE:
			if _t >= 0.45:
				_ir(Fase.EXPOSTA if _ciclos % 2 == 0 else Fase.DECIDE2)
		Fase.REFORMA_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_ir(Fase.REFORMA)
		Fase.REFORMA:
			if not _exposta:
				_exposta = true
				_mostrar_nucleo(true)
			if _t >= dur_exposta * 1.7:
				_exposta = false
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.DECIDE2)

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
	match _ciclos % 3:
		0:
			_ir(Fase.COMBO_TEL if dx < 220.0 else Fase.DASH_TEL)
		1:
			_ir(Fase.GUARDA)
		_:
			_ir(Fase.DASH_TEL)


func _escolher2() -> void:
	match _ciclos % 3:
		0: _ir(Fase.TP)
		1: _ir(Fase.LEQUE_TEL)
		_: _ir(Fase.REFORMA_TEL)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 320.0


## --- ataques ---------------------------------------------------------

func _golpe(dano: int, _empurrao := 40.0) -> void:
	Som.toca("demonio_ataque", -8.0, 1.1)
	var k := _obter_koliani()
	if k == null:
		return
	var d := _vetor_para_koliani()
	if absf(d.x) <= 82.0 and absf(d.y) <= 74.0 and signf(d.x) == _direcao:
		k.receber_dano(int(round(dano * (1.15 if _fase2 else 1.0))), _direcao)


func _dir_dardo(de: Vector2) -> Vector2:
	var k := _obter_koliani()
	if k == null:
		return Vector2(_direcao, 0)
	return (k.global_position + Vector2(0, -16) - de).normalized()


func _dardo(de: Vector2, dir: Vector2) -> void:
	var pai := get_parent()
	if pai == null:
		return
	Som.toca("projetil", -10.0, 1.0)
	var d := Area2D.new()
	d.collision_layer = 0
	d.collision_mask = 2
	d.global_position = de
	pai.add_child(d)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 8.0
	forma.shape = cs
	d.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.82, 0.4, 1.0, 0.95)
	poly.polygon = PackedVector2Array([Vector2(-9, 0), Vector2(0, -7), Vector2(9, 0), Vector2(0, 7)])
	d.add_child(poly)
	var luz := PointLight2D.new()
	luz.texture = _tex_luz()
	luz.energy = 0.7
	luz.color = Color(0.8, 0.4, 1.0)
	luz.scale = Vector2(0.35, 0.35)
	d.add_child(luz)
	var dano := int(round(dano_dardo * (1.15 if _fase2 else 1.0)))
	d.body_entered.connect(func(c: Node) -> void:
		if c is Koliani:
			c.receber_dano(dano, signf(dir.x))
		d.queue_free())
	var t := d.create_tween()
	t.tween_property(d, "global_position", de + dir * 1400.0, 1400.0 / DARDO_VEL)
	t.tween_callback(d.queue_free)


## --- transição de fase ---------------------------------------------

func _virar_energia() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -6.0, 0.8)
	Som.toca("grito", -8.0, 0.7)
	_abanar_camera(9.0)
	dur_tel *= 0.72
	dur_exposta *= 0.85
	dano_contacto = int(round(dano_contacto * 1.1))
	var p := CPUParticles2D.new()
	p.global_position = global_position + Vector2(0, -20)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 34
	p.lifetime = 0.7
	p.spread = 180.0
	p.direction = Vector2.UP
	p.gravity = Vector2(0, 500)
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 280.0
	p.color = Color(0.85, 0.45, 1.0)
	add_sibling(p)
	p.get_tree().create_timer(1.3).timeout.connect(p.queue_free)
	if _corpo:
		_corpo.frame = 3
	_ir(Fase.DECIDE2)


## --- núcleo / dano -------------------------------------------------

func _piscar(ligado: bool) -> void:
	super._piscar(ligado)
	if _corpo and not _exposta and not _fase2:
		_corpo.frame = 2 if ligado else 0


func _mostrar_nucleo(v: bool) -> void:
	_exposta = v
	_pulso = 0.0
	if _corpo:
		_corpo.frame = 3 if (v or _fase2) else 0
	if _nucleo:
		_nucleo.scale = Vector2.ONE * (1.0 if v else (0.5 if _fase2 else 0.35))
		var luz: PointLight2D = _nucleo.get_node_or_null("Luz")
		if luz:
			luz.energy = 1.7 if v else (0.5 if _fase2 else 0.12)
		var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
		if brilho:
			brilho.visible = v or _fase2


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	if _ja_derrotado:
		return
	provocar()
	# GUARDA: apara os golpes de frente
	if _fase == Fase.GUARDA and signf(dir_empurrao) == -_direcao:
		Som.toca("bloqueio", -7.0, 1.0)
		if _sprite:
			_sprite.modulate = Color(1.4, 1.4, 1.6)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		return
	if not _exposta:
		Som.toca("bloqueio", -9.0, 0.8)
		if _sprite:
			var m := _sprite.modulate
			_sprite.modulate = Color(1.3, 1.1, 1.4, m.a)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1, m.a), 0.12)
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
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 520.0), 1)
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
