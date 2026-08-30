class_name ChefeAcougueiroReal
extends ChefeBase
## Região V / nível 22 -- O Açougueiro Real do Mercado da Carne. Gigante de
## avental com dois cutelos:
##   * CUTELO   -- baixa os dois cutelos: duas linhas de choque rasteiras
##     (uma para cada lado). A seguir fica a arrancá-los do chão (EXPOSTO --
##     o ventre à mostra, dano a dobrar).
##   * ARREMESSO-- atira um cutelo giratório que vai e volta (bumerangue).
##   * GANCHO   -- telegrafa uma faixa; quem lá estiver leva um puxão + dentada.
## CADA GOLPE que ele leva (em EXPOSTO) muda a arena: sobe/baixa uma
## `Plataforma` do grupo "acougue_moveis".
## Fase 2 (< 50% vida): dois cutelos no arremesso, linhas mais largas,
## a arena muda mais a cada golpe, tudo mais rápido.

const CUTELO_VEL := 360.0

enum Fase { DORME, DECIDE, CUTELO_TEL, CUTELO, ARREMESSO_TEL, ARREMESSO, GANCHO_TEL, GANCHO, EXPOSTO }

@export var dist_deteta := 560.0
@export var dur_tel := 0.6
@export var dur_exposto := 1.5
@export var dano_linha := 22
@export var dano_cutelo := 18
@export var dano_gancho := 20

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposto := false
var _ciclos := 0
var _vida_max := 560
var _chao_cache := 0.0
var _moveis_estado := {}

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 690)
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
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_entrar_fase2()

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
					0: _ir(Fase.CUTELO_TEL)
					1: _ir(Fase.ARREMESSO_TEL)
					_: _ir(Fase.GANCHO_TEL)
		Fase.CUTELO_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_cutelada()
				_ir(Fase.CUTELO)
		Fase.CUTELO:
			if _t >= 0.5:
				_ir(Fase.EXPOSTO)
		Fase.ARREMESSO_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_arremessar()
				_ir(Fase.ARREMESSO)
		Fase.ARREMESSO:
			if _t >= 0.4:
				_ir(Fase.EXPOSTO)
		Fase.GANCHO_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_gancho()
				_ir(Fase.GANCHO)
		Fase.GANCHO:
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
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 320.0


## --- ataques ---------------------------------------------------------

func _cutelada() -> void:
	Som.toca("onda", -5.0, 0.7)
	_abanar_camera(6.0)
	_linha_choque(1.0)
	_linha_choque(-1.0)


func _linha_choque(dir: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var o := Area2D.new()
	o.collision_layer = 0
	o.collision_mask = 2
	o.monitoring = false
	o.global_position = Vector2(global_position.x + dir * 30.0, _chao_cache - 16.0)
	pai.add_child(o)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(34, 40)
	forma.shape = rs
	o.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.85, 0.3, 0.3, 0.55)
	poly.polygon = PackedVector2Array([Vector2(-16, 18), Vector2(-8, -18), Vector2(8, -18), Vector2(16, 18)])
	o.add_child(poly)
	var dano := int(round(dano_linha * (1.1 if _fase2 else 1.0)))
	var largo := 1400.0 if _fase2 else 1100.0
	o.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(dano, dir))
	var t := o.create_tween()
	t.tween_callback(func() -> void: o.monitoring = true)
	t.tween_property(o, "global_position:x", global_position.x + dir * largo, largo / 520.0)
	t.parallel().tween_property(poly, "modulate:a", 0.0, largo / 520.0)
	t.tween_callback(o.queue_free)


func _arremessar() -> void:
	Som.toca("investida", -6.0, 1.2)
	var n := 2 if _fase2 else 1
	for i in n:
		_cutelo_bumerangue(i * 0.12)


func _cutelo_bumerangue(atraso: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var dir := _dir_para_koliani()
	var c := Area2D.new()
	c.collision_layer = 0
	c.collision_mask = 2
	c.global_position = global_position + Vector2(dir * 30.0, -20.0)
	pai.add_child(c)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 12.0
	forma.shape = cs
	c.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.82, 0.84, 0.9, 1.0)
	poly.polygon = PackedVector2Array([Vector2(-14, -6), Vector2(10, -12), Vector2(14, 4), Vector2(0, 14), Vector2(-12, 8)])
	c.add_child(poly)
	var dano := dano_cutelo
	c.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(dano, dir))
	var longe := c.global_position + Vector2(dir * 460.0, 0)
	var t := c.create_tween()
	t.tween_interval(atraso)
	t.tween_property(c, "global_position", longe, 460.0 / CUTELO_VEL)
	t.tween_property(c, "global_position", global_position + Vector2(0, -20), 460.0 / CUTELO_VEL)
	t.parallel().tween_method(func(v: float) -> void: poly.rotation = v, 0.0, TAU * 8.0, 460.0 / CUTELO_VEL)
	t.tween_callback(c.queue_free)


func _gancho() -> void:
	Som.toca("investida", -6.0, 0.7)
	var pai := get_parent()
	if pai == null:
		return
	var dir := _dir_para_koliani()
	var g := Area2D.new()
	g.collision_layer = 0
	g.collision_mask = 2
	g.global_position = global_position + Vector2(dir * 60.0, -24.0)
	pai.add_child(g)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(360, 24)
	forma.shape = rs
	forma.position = Vector2(dir * 180.0, 0)
	g.add_child(forma)
	var linha := Line2D.new()
	linha.width = 3.0
	linha.default_color = Color(0.7, 0.7, 0.75, 0.9)
	linha.points = PackedVector2Array([Vector2.ZERO, Vector2(dir * 360.0, 0)])
	g.add_child(linha)
	var dano := int(round(dano_gancho * (1.1 if _fase2 else 1.0)))
	var t := g.create_tween()
	t.tween_callback(func() -> void:
		for b in g.get_overlapping_bodies():
			if b is Koliani:
				b.receber_dano(dano, -dir))
	t.tween_property(linha, "modulate:a", 0.0, 0.3)
	t.tween_callback(g.queue_free)


## --- arena que muda a cada golpe -------------------------------------

func _remexer_arena() -> void:
	var moveis := get_tree().get_nodes_in_group("acougue_moveis")
	if moveis.is_empty():
		return
	var quantos := 2 if _fase2 else 1
	for i in quantos:
		var p: Node2D = moveis[randi() % moveis.size()]
		if not is_instance_valid(p):
			continue
		var subiu: bool = _moveis_estado.get(p, false)
		var dy := 90.0 if subiu else -90.0
		_moveis_estado[p] = not subiu
		var tw := p.create_tween()
		tw.tween_property(p, "position:y", p.position.y + dy, 0.4).set_trans(Tween.TRANS_SINE)
		Som.toca("selo", -14.0, 1.2)


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -8.0, 0.7)
	_abanar_camera(8.0)
	dur_tel *= 0.78
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


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	if _ja_derrotado:
		return
	provocar()
	if not _exposto:
		Som.toca("bloqueio", -9.0, 0.5)
		if _sprite:
			_sprite.modulate = Color(1.2, 1.0, 1.0)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao)
	if not _ja_derrotado:
		_remexer_arena()  # cada golpe muda a arquitetura da arena


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
