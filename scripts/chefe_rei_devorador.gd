class_name ChefeReiDevorador
extends ChefeBase
## Região VI / nível 28 -- O Rei Devorador do Banquete dos Imortais. Rei
## glutão à cabeceira de uma mesa gigante:
##   * GARFADA -- avança e espeta o garfo.
##   * PRATOS  -- atira pratos giratórios num leque.
##   * SERVOS  -- chama 2-3 servos (DemonioBase).
##   * DEVORAR -- se houver um inimigo comum perto (grupo "inimigos", não
##     chefe), agarra-o, come-o e RECUPERA vida. Matar os servos longe
##     dele evita que se cure.
## Depois de GARFADA / DEVORAR arrota, empanturrado (EXPOSTO -- a barriga,
## dano a dobrar).
## Fase 2 (< 50% vida): cresce, a mesa (grupo "mesa_banquete") sacode,
## mais servos, alcance de DEVORAR maior, tudo mais rápido.

const SERVO := preload("res://scenes/actors/DemonioBase.tscn")
const PRATO_VEL := 320.0

enum Fase { DORME, DECIDE, GARFADA_TEL, GARFADA, PRATOS_TEL, PRATOS, SERVOS_TEL, SERVOS, DEVORAR, EXPOSTO }

@export var dist_deteta := 560.0
@export var vel_avanco := 170.0
@export var dur_tel := 0.55
@export var dur_exposto := 1.4
@export var dano_garfo := 22
@export var dano_prato := 14
@export var alcance_devorar := 170.0
@export var cura_devorar := 40

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposto := false
var _ciclos := 0
var _vida_max := 560
var _chao_cache := 0.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 860)
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
			var dx := _vetor_para_koliani().x
			if absf(dx) > 130.0:
				velocity.x = signf(dx) * vel_avanco
			else:
				velocity.x = 0.0
			if _t >= 0.28:
				_escolher()
		Fase.GARFADA_TEL:
			velocity.x = 0.0
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				Som.toca("investida", -6.0, 0.9)
				_ataque_forte = 0.3
				_ir(Fase.GARFADA)
		Fase.GARFADA:
			velocity.x = _direcao * vel_avanco * 1.4
			if _t < 0.06:
				_garfo()
			if _t >= 0.4:
				velocity.x = 0.0
				_ir(Fase.EXPOSTO)
		Fase.PRATOS_TEL:
			velocity.x = 0.0
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_pratos()
				_ir(Fase.PRATOS)
		Fase.PRATOS:
			if _t >= 0.4:
				_ir(Fase.EXPOSTO)
		Fase.SERVOS_TEL:
			velocity.x = 0.0
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_servos()
				_ir(Fase.SERVOS)
		Fase.SERVOS:
			if _t >= 0.5:
				_ir(Fase.EXPOSTO)
		Fase.DEVORAR:
			velocity.x = 0.0
			if _t < dt:
				_devorar()
			if _t >= 0.6:
				_ir(Fase.EXPOSTO)
		Fase.EXPOSTO:
			velocity.x = 0.0
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
	# se houver comida por perto, DEVORA
	if _presa_perto() != null:
		_ir(Fase.DEVORAR)
		return
	var dx := absf(_vetor_para_koliani().x)
	match _ciclos % 3:
		0: _ir(Fase.GARFADA_TEL if dx < 200.0 else Fase.PRATOS_TEL)
		1: _ir(Fase.PRATOS_TEL)
		_: _ir(Fase.SERVOS_TEL)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 320.0


func _presa_perto() -> Node:
	var alcance := alcance_devorar * (1.4 if _fase2 else 1.0)
	for e in get_tree().get_nodes_in_group("inimigos"):
		if e == self or not is_instance_valid(e):
			continue
		if (e as Node).is_in_group("chefes"):
			continue
		if "_morto" in e and e._morto:
			continue
		if (e as Node2D).global_position.distance_to(global_position) <= alcance:
			return e
	return null


## --- ataques ---------------------------------------------------------

func _garfo() -> void:
	Som.toca("golpe_pesado", -7.0, 0.8)
	var k := _obter_koliani()
	if k == null:
		return
	var d := _vetor_para_koliani()
	if absf(d.x) <= 110.0 and absf(d.y) <= 74.0 and signf(d.x) == _direcao:
		k.receber_dano(int(round(dano_garfo * (1.15 if _fase2 else 1.0))), _direcao)


func _pratos() -> void:
	Som.toca("projetil", -8.0, 0.7)
	var base := _vetor_para_koliani().normalized()
	if base.length() < 0.5:
		base = Vector2(_direcao, -0.1).normalized()
	var n := 4 if _fase2 else 3
	for i in n:
		_prato(base.rotated((i - (n - 1) * 0.5) * 0.26))


func _prato(dir: Vector2) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var p := Area2D.new()
	p.collision_layer = 0
	p.collision_mask = 2
	p.global_position = global_position + Vector2(0, -20) + dir * 24.0
	pai.add_child(p)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 11.0
	forma.shape = cs
	p.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.92, 0.9, 0.86, 1.0)
	var pts := PackedVector2Array()
	for k in 10:
		var a := TAU * float(k) / 10.0
		pts.append(Vector2(cos(a), sin(a) * 0.5) * 12.0)
	poly.polygon = pts
	p.add_child(poly)
	var dano := dano_prato
	p.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(dano, signf(dir.x))
		p.queue_free())
	var t := p.create_tween()
	t.tween_property(p, "global_position", p.global_position + dir * 1400.0, 1400.0 / PRATO_VEL)
	t.parallel().tween_method(func(v: float) -> void: poly.rotation = v, 0.0, TAU * 6.0, 1400.0 / PRATO_VEL)
	t.tween_callback(p.queue_free)


func _servos() -> void:
	Som.toca("invocar", -9.0, 0.6)
	var pai := get_parent()
	if pai == null:
		return
	var n := 3 if _fase2 else 2
	for i in n:
		var srv := SERVO.instantiate()
		srv.especie = "goblin"
		srv.vida = 24
		srv.dano_contacto = 14
		srv.velocidade = 84.0
		srv.alcance_patrulha = 320.0
		var x := global_position.x + (i - (n - 1) * 0.5) * 90.0 - _direcao * 120.0
		srv.global_position = Vector2(x, _chao_y(x) - 20.0)
		pai.add_child(srv)


func _devorar() -> void:
	var presa := _presa_perto()
	if presa == null:
		return
	Som.toca("chefe_cai", -10.0, 0.5)
	Som.toca("conquista", -14.0, 0.7)
	# "come" o servo
	if presa.has_method("soltar_estilhacos"):
		presa.soltar_estilhacos()
	presa.queue_free()
	# recupera vida
	vida = mini(_vida_max, vida + int(round(cura_devorar * (1.3 if _fase2 else 1.0))))
	if _sprite:
		_sprite.modulate = Color(1.0, 1.3, 1.0)
		create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.25)


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -8.0, 0.7)
	_abanar_camera(8.0)
	dur_tel *= 0.8
	dur_exposto *= 0.85
	if _sprite:
		create_tween().tween_property(_sprite, "scale", Vector2(1.12, 1.12), 0.4)
	for m in get_tree().get_nodes_in_group("mesa_banquete"):
		if not is_instance_valid(m):
			continue
		var tw := (m as Node).create_tween().set_loops(0)
		tw.tween_property(m, "position:y", (m as Node2D).position.y + 5.0, 0.14)
		tw.tween_property(m, "position:y", (m as Node2D).position.y - 5.0, 0.14)


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
			_sprite.modulate = Color(1.2, 1.1, 1.0)
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
