class_name ChefeIrmaosCondenados
extends ChefeBase
## Região II / nível 09 -- Os Irmãos Condenados. Dois fantasmas de forçado
## ligados por uma corrente de alma:
##   * IRMÃO PERTO (o corpo deste nó) -- arremete corpo-a-corpo (LUNGE).
##   * IRMÃO LONGE (um Node2D-fantasma que o script move e desenha) --
##     mantém-se a distância e atira dardos de alma (BOLTS).
## A corrente entre os dois é uma `Line2D` atualizada a cada frame.
##
## Depois de cada combo os DOIS param, etéreos deixam de o ser por instantes
## (estado EXPOSTO): única janela de dano, à vida partilhada, a dobrar.
##
## Aos 50% da vida partilhada, o IRMÃO LONGE "morre": a corrente chicoteia
## de volta, o IRMÃO PERTO absorve-lhe a alma (cresce, fica mais rápido) e
## ganha os dardos de alma além do arremesso -- e passa a lançá-los em
## leque. É a fase 2.

const DARDO_VEL := 300.0

enum Fase { DORME, DECIDE, LUNGE_TEL, LUNGE, VOLTA, BOLTS_TEL, BOLTS, EXPOSTO,
	DECIDE2, LUNGE2_TEL, LUNGE2, VOLTA2, LEQUE_TEL, LEQUE, EXPOSTO2 }

@export var dist_deteta := 540.0
@export var altura_voo := 130.0
@export var dur_tel := 0.6
@export var dur_exposto := 1.4
@export var dur_lunge := 0.34
@export var dano_lunge := 20
@export var dano_dardo := 14
@export var raio_orbita := 190.0

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _exposto := false
var _fase2 := false
var _ciclos := 0
var _vida_max := 420
var _chao_cache := 0.0
var _base_x := 0.0
var _lunge_de := Vector2.ZERO
var _lunge_para := Vector2.ZERO
var _orb := 0.0

var _longe: Node2D
var _longe_sprite: Sprite2D
var _corrente: Line2D
var _longe_vivo := true

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 440)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_base_x = global_position.x
	_mostrar_nucleo(false)
	call_deferred("_montar_irmao_longe")


func _montar_irmao_longe() -> void:
	var pai := get_parent()
	if pai == null:
		return
	_corrente = Line2D.new()
	_corrente.width = 3.0
	_corrente.default_color = Color(0.55, 0.95, 0.8, 0.5)
	_corrente.z_index = -1
	pai.add_child(_corrente)

	_longe = Node2D.new()
	_longe.global_position = global_position + Vector2(-raio_orbita, -40.0)
	pai.add_child(_longe)
	_longe_sprite = Sprite2D.new()
	_longe_sprite.texture = _corpo.texture if _corpo else null
	_longe_sprite.hframes = 4
	_longe_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_longe_sprite.modulate = Color(0.7, 1.0, 0.9, 0.92)
	_longe.add_child(_longe_sprite)

	var luz := PointLight2D.new()
	luz.texture = _tex_luz()
	luz.energy = 0.6
	luz.color = Color(0.5, 1.0, 0.8)
	luz.scale = Vector2(0.9, 0.9)
	_longe.add_child(luz)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(44, 84)
	forma.shape = rs
	area.add_child(forma)
	area.body_entered.connect(func(c: Node) -> void:
		if c is Koliani and _longe_vivo:
			c.receber_dano(dano_contacto, signf(c.global_position.x - _longe.global_position.x)))
	_longe.add_child(area)


func _exit_tree() -> void:
	for n in [_longe, _corrente]:
		if is_instance_valid(n):
			n.queue_free()


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite:
		_sprite.position.y = sin(_pulso * 2.3) * (5.0 if not _exposto else 2.0)
	if _nucleo and _exposto:
		var p := 1.0 + 0.18 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)
	_atualizar_irmao_longe(dt)


func _atualizar_irmao_longe(dt: float) -> void:
	if not _longe_vivo or not is_instance_valid(_longe):
		if is_instance_valid(_corrente):
			_corrente.visible = false
		return
	_orb += dt * (0.8 if not _exposto else 0.2)
	var centro := global_position + Vector2(0, -20)
	var alvo := centro + Vector2(cos(_orb) * raio_orbita, sin(_orb * 0.7) * raio_orbita * 0.4 - 30.0)
	_longe.global_position = _longe.global_position.lerp(alvo, clampf(dt * 2.5, 0.0, 1.0))
	if _longe_sprite:
		_longe_sprite.position.y = sin(_pulso * 2.0 + 1.0) * 5.0
		var dir := signf((_obter_koliani().global_position.x - _longe.global_position.x)) if _obter_koliani() else 1.0
		_longe_sprite.scale.x = dir if dir != 0.0 else 1.0
	if is_instance_valid(_corrente):
		_corrente.visible = true
		var pts := PackedVector2Array()
		var a := global_position + Vector2(0, -14)
		var b := _longe.global_position + Vector2(0, -6)
		for i in 9:
			var f := float(i) / 8.0
			var sag := sin(f * PI) * 14.0
			pts.append(a.lerp(b, f) + Vector2(0, sag))
		_corrente.points = pts


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(_base_x)
	var alvo_y := _chao_cache - altura_voo
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_um_morre()

	match _fase:
		Fase.DORME:
			global_position.y = lerpf(global_position.y, alvo_y, clampf(dt * 3.0, 0.0, 1.0))
			_encarar_koliani()
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE, Fase.DECIDE2:
			global_position.x = lerpf(global_position.x, _base_x, clampf(dt * 3.0, 0.0, 1.0))
			global_position.y = lerpf(global_position.y, alvo_y, clampf(dt * 3.0, 0.0, 1.0))
			_encarar_koliani()
			if _t >= 0.3:
				_escolher()
		Fase.LUNGE_TEL, Fase.LUNGE2_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_lunge_de = global_position
				var k := _obter_koliani()
				_lunge_para = (k.global_position + Vector2(0, -20)) if k else global_position
				Som.toca("investida", -7.0, 0.9)
				_ataque_forte = dur_lunge + 0.1
				_ir(Fase.LUNGE2 if _fase == Fase.LUNGE2_TEL else Fase.LUNGE)
		Fase.LUNGE, Fase.LUNGE2:
			var f := clampf(_t / dur_lunge, 0.0, 1.0)
			global_position = _lunge_de.lerp(_lunge_para, f)
			if _t >= dur_lunge:
				_ir(Fase.VOLTA2 if _fase == Fase.LUNGE2 else Fase.VOLTA)
		Fase.VOLTA, Fase.VOLTA2:
			var destino := Vector2(_base_x, alvo_y)
			global_position = global_position.lerp(destino, clampf(dt * 4.0, 0.0, 1.0))
			if _t >= 0.28:
				_ir(Fase.EXPOSTO2 if _fase == Fase.VOLTA2 else Fase.EXPOSTO)
		Fase.BOLTS_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_dardo_do_longe()
				_ir(Fase.BOLTS)
		Fase.BOLTS:
			if _t >= 0.45:
				_ir(Fase.EXPOSTO)
		Fase.LEQUE_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_leque_de_dardos()
				_ir(Fase.LEQUE)
		Fase.LEQUE:
			if _t >= 0.5:
				_ir(Fase.EXPOSTO2)
		Fase.EXPOSTO, Fase.EXPOSTO2:
			global_position.y = lerpf(global_position.y, alvo_y, clampf(dt * 3.0, 0.0, 1.0))
			if not _exposto:
				_exposto = true
				_mostrar_nucleo(true)
			if _t >= dur_exposto:
				_exposto = false
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.DECIDE2 if _fase2 else Fase.DECIDE)
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


func _escolher() -> void:
	if _fase2:
		# leque e arremesso à vez, arremesso mais frequente de perto
		var perto := absf(_vetor_para_koliani().x) < 200.0
		if _ciclos % 2 == 0 or perto:
			_ir(Fase.LUNGE2_TEL)
		else:
			_ir(Fase.LEQUE_TEL)
	else:
		# perto -> o irmão perto arremete; longe -> o irmão longe atira
		if _ciclos % 2 == 0:
			_ir(Fase.LUNGE_TEL)
		else:
			_ir(Fase.BOLTS_TEL)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 320.0


## --- ataques ---------------------------------------------------------

func _dardo_do_longe() -> void:
	if not _longe_vivo or not is_instance_valid(_longe):
		return
	_disparar_dardo(_longe.global_position, _dir_dardo_para_koliani(_longe.global_position))


func _leque_de_dardos() -> void:
	Som.toca("projetil", -9.0, 0.7)
	var base := _dir_dardo_para_koliani(global_position)
	for a in [-0.34, 0.0, 0.34]:
		_disparar_dardo(global_position + Vector2(0, -16), base.rotated(a))


func _dir_dardo_para_koliani(de: Vector2) -> Vector2:
	var k := _obter_koliani()
	if k == null:
		return Vector2(_direcao, 0)
	return (k.global_position + Vector2(0, -16) - de).normalized()


func _disparar_dardo(de: Vector2, dir: Vector2) -> void:
	var pai := get_parent()
	if pai == null:
		return
	Som.toca("projetil", -10.0, 0.9)
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
	poly.color = Color(0.5, 1.0, 0.8, 0.95)
	poly.polygon = PackedVector2Array([Vector2(-8, 0), Vector2(0, -7), Vector2(8, 0), Vector2(0, 7)])
	d.add_child(poly)
	var luz := PointLight2D.new()
	luz.texture = _tex_luz()
	luz.energy = 0.7
	luz.color = Color(0.5, 1.0, 0.8)
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


## --- transição de fase (um irmão morre) ------------------------------

func _um_morre() -> void:
	_fase2 = true
	_longe_vivo = false
	Som.toca("chefe_cai", -6.0, 0.9)
	Som.toca("conquista", -10.0, 1.4)
	_abanar_camera(8.0)
	dur_tel *= 0.7
	dur_exposto *= 0.82
	raio_orbita = 90.0
	# o irmão longe desfaz-se
	if is_instance_valid(_longe):
		var estilhacos := CPUParticles2D.new()
		estilhacos.global_position = _longe.global_position
		estilhacos.emitting = true
		estilhacos.one_shot = true
		estilhacos.explosiveness = 1.0
		estilhacos.amount = 30
		estilhacos.lifetime = 0.6
		estilhacos.direction = Vector2.UP
		estilhacos.spread = 180.0
		estilhacos.gravity = Vector2(0, 300)
		estilhacos.initial_velocity_min = 80.0
		estilhacos.initial_velocity_max = 240.0
		estilhacos.color = Color(0.5, 1.0, 0.8)
		get_parent().add_child(estilhacos)
		estilhacos.get_tree().create_timer(1.2).timeout.connect(estilhacos.queue_free)
		var lg := _longe
		_longe = null
		var tw := lg.create_tween()
		tw.tween_property(lg, "modulate:a", 0.0, 0.4)
		tw.tween_callback(lg.queue_free)
	# o irmão perto absorve a alma -> cresce
	if _sprite:
		create_tween().tween_property(_sprite, "scale", Vector2(1.16, 1.16), 0.5).set_trans(Tween.TRANS_BACK)
	_ir(Fase.DECIDE2)


## --- núcleo / dano -------------------------------------------------

func _piscar(ligado: bool) -> void:
	super._piscar(ligado)
	if _corpo and not _exposto:
		_corpo.frame = 2 if ligado else 0
	if _longe_sprite and _longe_vivo:
		_longe_sprite.frame = 2 if ligado else 0


func _mostrar_nucleo(v: bool) -> void:
	_exposto = v
	_pulso = 0.0
	if _corpo:
		_corpo.frame = 3 if v else 0
	if _longe_sprite and _longe_vivo:
		_longe_sprite.frame = 3 if v else 0
		_longe_sprite.modulate = Color(1.4, 1.6, 1.5, 0.95) if v else Color(0.7, 1.0, 0.9, 0.92)
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
		Som.toca("bloqueio", -9.0, 0.8)
		if _sprite:
			_sprite.modulate = Color(0.7, 1.0, 0.85)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao)


## --- utilitários --------------------------------------------------

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
