class_name ChefeNoivaDoEclipse
extends ChefeBase
## Região V / nível 25 -- A Noiva do Eclipse (fecha a Cidade Corrompida).
## Rainha antiga sacrificada por Zeriko para abrir o Abismo; luta porque
## está presa, não porque quer. Chefe emocional -- a história está na
## pista `praca_o_que_ela_diz`.
##   * ANEIS  -- lança anéis de sombra que se abrem em coroa.
##   * ECLIPSE-- o céu escurece e um instante depois vem uma nova radial
##     (salta-se / afasta-se do centro).
##   * CONVIDADOS -- levanta 2 convidados espectrais (DemonioBase).
## Depois de ANEIS / ECLIPSE baixa o véu e o sol negro do peito fica à
## mostra (EXPOSTA -- a marca do sacrifício, dano a dobrar).
## Fase 2 (< 50% vida): o véu queima -- ela deixa de magoar ao toque (não
## é a inimiga), mas a corrupção que a prende ataca mais: eclipses
## seguidos e mais convidados.

const CONVIDADO := preload("res://scenes/actors/DemonioBase.tscn")
const ANEL_VEL := 220.0

enum Fase { DORME, DECIDE, ANEIS_TEL, ANEIS, ECLIPSE_TEL, ECLIPSE_ESCURO, ECLIPSE_NOVA, CONV_TEL, CONV, EXPOSTA }

@export var dist_deteta := 660.0
@export var altura_voo := 200.0
@export var altura_exposta := 100.0
@export var dur_tel := 0.6
@export var dur_exposta := 1.5
@export var dano_anel := 14
@export var dano_nova := 20

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposta := false
var _ciclos := 0
var _vida_max := 420
var _chao_cache := 0.0
var _alvo_y := 0.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 820)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_alvo_y = _origem.y
	_mostrar_nucleo(false)
	falas_intro = [
		{ "quem": "boss.noiva_do_eclipse", "texto": "dlg.noiva.intro.1" },
		{ "quem": "boss.noiva_do_eclipse", "texto": "dlg.noiva.intro.2" },
	]
	falas_fim = [
		{ "quem": "boss.noiva_do_eclipse", "texto": "dlg.noiva.win.1" },
	]


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite:
		_sprite.position.y = sin(_pulso * 1.7) * (7.0 if not _exposta else 2.0)
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
	global_position.x = lerpf(global_position.x, _x_koliani(), clampf(dt * 1.0, 0.0, 1.0))
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
					0: _ir(Fase.ANEIS_TEL)
					1: _ir(Fase.ECLIPSE_TEL)
					_: _ir(Fase.CONV_TEL)
		Fase.ANEIS_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_aneis()
				_ir(Fase.ANEIS)
		Fase.ANEIS:
			if _t >= 0.5:
				_ir(Fase.EXPOSTA)
		Fase.ECLIPSE_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_ir(Fase.ECLIPSE_ESCURO)
		Fase.ECLIPSE_ESCURO:
			if _t < dt:
				Som.toca("grito", -10.0, 0.5)
				_abanar_camera(2.0)
			if _t >= (0.5 if not _fase2 else 0.35):
				_nova()
				_ir(Fase.ECLIPSE_NOVA)
		Fase.ECLIPSE_NOVA:
			if _t >= 0.5:
				_ir(Fase.EXPOSTA)
		Fase.CONV_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_convidados()
				_ir(Fase.CONV)
		Fase.CONV:
			if _t >= 0.5:
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


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 380.0


## --- ataques ---------------------------------------------------------

func _aneis() -> void:
	Som.toca("projetil", -8.0, 0.6)
	var n := 3 if _fase2 else 2
	var base := _vetor_para_koliani().normalized()
	if base.length() < 0.5:
		base = Vector2(_direcao, 0)
	for i in n:
		_anel(base.rotated((i - (n - 1) * 0.5) * 0.3))


func _anel(dir: Vector2) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.global_position = global_position + Vector2(0, 6)
	pai.add_child(a)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 12.0
	forma.shape = cs
	a.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.3, 0.16, 0.4, 0.0)
	var pts := PackedVector2Array()
	for k in 12:
		var ang := TAU * float(k) / 12.0
		pts.append(Vector2(cos(ang), sin(ang)) * 12.0)
	poly.polygon = pts
	a.add_child(poly)
	var dano := dano_anel
	a.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(dano, signf(dir.x))
		a.queue_free())
	var t := a.create_tween()
	t.tween_property(poly, "modulate:a", 0.9, 0.1)
	t.parallel().tween_property(a, "global_position", a.global_position + dir * 1200.0, 1200.0 / ANEL_VEL)
	t.parallel().tween_property(a, "scale", Vector2(2.0, 2.0), 1200.0 / ANEL_VEL)
	t.tween_callback(a.queue_free)


func _nova() -> void:
	Som.toca("grito", -4.0, 0.8)
	_abanar_camera(7.0)
	var pai := get_parent()
	if pai == null:
		return
	var n := 12
	for i in n:
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / n)
		var o := Area2D.new()
		o.collision_layer = 0
		o.collision_mask = 2
		o.global_position = global_position
		pai.add_child(o)
		var forma := CollisionShape2D.new()
		var cs := CircleShape2D.new()
		cs.radius = 10.0
		forma.shape = cs
		o.add_child(forma)
		var poly := Polygon2D.new()
		poly.color = Color(0.55, 0.3, 0.7, 0.9)
		poly.polygon = PackedVector2Array([Vector2(-8, 0), Vector2(0, -8), Vector2(8, 0), Vector2(0, 8)])
		o.add_child(poly)
		var dano := int(round(dano_nova * (1.1 if _fase2 else 1.0)))
		o.body_entered.connect(func(b: Node) -> void:
			if b is Koliani:
				b.receber_dano(dano, signf(dir.x))
			o.queue_free())
		var t := o.create_tween()
		t.tween_property(o, "global_position", o.global_position + dir * 620.0, 1.2)
		t.tween_callback(o.queue_free)


func _convidados() -> void:
	Som.toca("invocar", -9.0, 0.6)
	var pai := get_parent()
	if pai == null:
		return
	var n := 3 if _fase2 else 2
	for i in n:
		var c := CONVIDADO.instantiate()
		c.especie = "esqueleto"
		c.vida = 22
		c.dano_contacto = 14
		c.velocidade = 66.0
		c.alcance_patrulha = 340.0
		c.cor_estilhacos = Color(0.4, 0.28, 0.5)
		c.cor_rim = Color(0.6, 0.4, 0.75)
		var x := global_position.x + (i - (n - 1) * 0.5) * 90.0
		c.global_position = Vector2(x, _chao_y(x) - 20.0)
		pai.add_child(c)
		c.get_tree().create_timer(10.0).timeout.connect(func() -> void:
			if is_instance_valid(c) and not c._morto:
				c.soltar_estilhacos()
				c.queue_free())


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -8.0, 0.7)
	_abanar_camera(8.0)
	dur_tel *= 0.8
	dur_exposta *= 0.88
	# o véu queima -- ela deixa de magoar ao toque (não é a inimiga)
	dano_contacto = 0
	var area := get_node_or_null("AreaContacto") as Area2D
	if area:
		area.set_deferred("monitoring", false)
	if _sprite:
		_sprite.modulate = Color(1.3, 1.2, 1.4)
		create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.4)


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
			_sprite.modulate = Color(1.2, 1.1, 1.3)
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
