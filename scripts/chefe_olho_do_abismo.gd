class_name ChefeOlhoDoAbismo
extends ChefeBase
## Região IV / nível 20 -- O Olho do Abismo. Um olho flutuante sem corpo,
## quase invisível no escuro. Ataca:
##   * LASER    -- carrega um feixe e varre-o num arco (dano ao longo da
##     linha). A seguir fecha-se para recarregar (EXPOSTO -- a íris à
##     mostra, dano a dobrar).
##   * FALSAS   -- apaga por uns segundos as plataformas do grupo
##     "plat_falsas" (chão que não estava lá).
##   * CLONES   -- larga olhinhos que derivam até à Koliani e rebentam.
##   * INVERTER -- inverte os controlos da Koliani por uns segundos
##     (`Koliani.inverter_controlos`).
## Fase 2 (< 50% vida): laser em varredura dupla, mais clones, inversão
## mais longa, falsas apagadas mais tempo.

enum Fase { DORME, DECIDE, LASER_TEL, LASER, FALSAS_TEL, FALSAS, CLONES_TEL, CLONES, INV_TEL, INV, EXPOSTO }

@export var dist_deteta := 720.0
@export var altura_voo := 200.0
@export var dur_tel := 0.6
@export var dur_exposto := 1.4
@export var dur_laser := 0.7
@export var dano_laser := 20
@export var dano_clone := 14
@export var seg_inverso := 3.0
@export var seg_falsas := 2.2

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposto := false
var _ciclos := 0
var _vida_max := 400
var _chao_cache := 0.0
var _laser_ang0 := 0.0
var _laser_ang1 := 0.0
var _feixe: Line2D
var _feixe_area: Area2D

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 700)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_chao_cache = _chao_y(global_position.x)
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite:
		_sprite.position.y = sin(_pulso * 1.6) * 6.0
	if _nucleo and _exposto:
		var p := 1.0 + 0.2 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(global_position.x)
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_entrar_fase2()

	# paira a acompanhar a Koliani (menos no LASER)
	if _fase not in [Fase.LASER, Fase.LASER_TEL]:
		var alvo := Vector2(_x_koliani(), _chao_cache - altura_voo)
		global_position = global_position.lerp(alvo, clampf(dt * 1.8, 0.0, 1.0))
	_encarar_koliani()

	match _fase:
		Fase.DORME:
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			if _t >= 0.28:
				_escolher()
		Fase.LASER_TEL:
			if _t < dt:
				_preparar_laser()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_disparar_laser()
				_ir(Fase.LASER)
		Fase.LASER:
			var f := clampf(_t / dur_laser, 0.0, 1.0)
			var ang := lerpf(_laser_ang0, _laser_ang1, f)
			_atualizar_feixe(ang)
			if _t >= dur_laser:
				_terminar_laser()
				_ir(Fase.EXPOSTO)
		Fase.FALSAS_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_apagar_falsas()
				_ir(Fase.FALSAS)
		Fase.FALSAS:
			if _t >= 0.4:
				_ir(Fase.EXPOSTO)
		Fase.CLONES_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_largar_clones()
				_ir(Fase.CLONES)
		Fase.CLONES:
			if _t >= 0.4:
				_ir(Fase.EXPOSTO)
		Fase.INV_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_inverter()
				_ir(Fase.INV)
		Fase.INV:
			if _t >= 0.35:
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


func _escolher() -> void:
	match _ciclos % 4:
		0: _ir(Fase.LASER_TEL)
		1: _ir(Fase.CLONES_TEL)
		2: _ir(Fase.INV_TEL)
		_: _ir(Fase.FALSAS_TEL)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 420.0


## --- laser ---------------------------------------------------------

func _preparar_laser() -> void:
	Som.toca("olho_carregar", -7.0, 1.0)
	var k := _obter_koliani()
	var alvo := k.global_position if k else global_position + Vector2(_direcao * 200, 60)
	var meio := (alvo - global_position).angle()
	var largo := 0.7 if _fase2 else 0.45
	_laser_ang0 = meio - largo
	_laser_ang1 = meio + largo
	if randf() < 0.5 and not _fase2:
		var tmp := _laser_ang0
		_laser_ang0 = _laser_ang1
		_laser_ang1 = tmp
	# linha de aviso
	_feixe = Line2D.new()
	_feixe.width = 2.0
	_feixe.default_color = Color(1.0, 0.3, 0.35, 0.5)
	_feixe.points = PackedVector2Array([Vector2.ZERO, Vector2(1400, 0)])
	_feixe.rotation = _laser_ang0
	add_child(_feixe)


func _disparar_laser() -> void:
	Som.toca("feixe_vil", -5.0, 0.5)
	_abanar_camera(3.0)
	if _feixe:
		_feixe.width = 8.0
		_feixe.default_color = Color(1.0, 0.35, 0.4, 0.95)
	_feixe_area = Area2D.new()
	_feixe_area.collision_layer = 0
	_feixe_area.collision_mask = 2
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(1400, 16)
	forma.shape = rs
	forma.position = Vector2(700, 0)
	_feixe_area.add_child(forma)
	add_child(_feixe_area)


func _atualizar_feixe(ang: float) -> void:
	if is_instance_valid(_feixe):
		_feixe.rotation = ang
	if is_instance_valid(_feixe_area):
		_feixe_area.rotation = ang
		for b in _feixe_area.get_overlapping_bodies():
			if b is Koliani:
				b.receber_dano(int(round(dano_laser * (1.1 if _fase2 else 1.0))), signf(cos(ang)))


func _terminar_laser() -> void:
	if is_instance_valid(_feixe):
		var fx := _feixe
		_feixe = null
		var t := fx.create_tween()
		t.tween_property(fx, "modulate:a", 0.0, 0.2)
		t.tween_callback(fx.queue_free)
	if is_instance_valid(_feixe_area):
		_feixe_area.queue_free()
		_feixe_area = null


## --- outros ataques ----------------------------------------------

func _apagar_falsas() -> void:
	Som.toca("onda", -9.0, 1.2)
	var segundos := seg_falsas * (1.5 if _fase2 else 1.0)
	for p in get_tree().get_nodes_in_group("plat_falsas"):
		if not is_instance_valid(p):
			continue
		var col := p.get_node_or_null("Col") as CollisionShape2D
		if col == null:
			continue
		col.set_deferred("disabled", true)
		var vis := p.get_node_or_null("Visual") as CanvasItem
		if vis:
			create_tween().tween_property(vis, "modulate:a", 0.1, 0.12)
		p.get_tree().create_timer(segundos).timeout.connect(func() -> void:
			if not is_instance_valid(p):
				return
			var c2 := p.get_node_or_null("Col") as CollisionShape2D
			if c2:
				c2.set_deferred("disabled", false)
			var v2 := p.get_node_or_null("Visual") as CanvasItem
			if v2:
				create_tween().tween_property(v2, "modulate:a", 1.0, 0.15))


func _largar_clones() -> void:
	Som.toca("invocar", -9.0, 0.7)
	var pai := get_parent()
	if pai == null:
		return
	var n := 3 if _fase2 else 2
	for i in n:
		var c := Area2D.new()
		c.collision_layer = 0
		c.collision_mask = 2
		c.global_position = global_position + Vector2((i - (n - 1) * 0.5) * 40.0, 10.0)
		pai.add_child(c)
		var forma := CollisionShape2D.new()
		var cs := CircleShape2D.new()
		cs.radius = 10.0
		forma.shape = cs
		c.add_child(forma)
		var poly := Polygon2D.new()
		poly.color = Color(0.85, 0.85, 0.95, 0.95)
		poly.polygon = PackedVector2Array([Vector2(-10, 0), Vector2(0, -6), Vector2(10, 0), Vector2(0, 6)])
		c.add_child(poly)
		var iris := Polygon2D.new()
		iris.color = Color(0.5, 0.2, 0.6, 1.0)
		iris.polygon = PackedVector2Array([Vector2(-3, 0), Vector2(0, -3), Vector2(3, 0), Vector2(0, 3)])
		c.add_child(iris)
		var dano := dano_clone
		c.body_entered.connect(func(b: Node) -> void:
			if b is Koliani:
				b.receber_dano(dano, signf(b.global_position.x - c.global_position.x))
			c.queue_free())
		var k := _obter_koliani()
		var destino: Vector2 = (k.global_position if k else global_position) + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		var t := c.create_tween()
		t.tween_property(c, "global_position", destino, 0.9).set_trans(Tween.TRANS_SINE)
		t.tween_interval(0.2)
		t.tween_callback(c.queue_free)


func _inverter() -> void:
	Som.toca("bloqueio", -6.0, 0.5)
	_abanar_camera(4.0)
	var k := _obter_koliani()
	if k and k.has_method("inverter_controlos"):
		k.inverter_controlos(seg_inverso * (1.4 if _fase2 else 1.0))


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -8.0, 0.7)
	_abanar_camera(8.0)
	dur_tel *= 0.78
	dur_exposto *= 0.88


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
	if not _exposto:
		Som.toca("bloqueio", -9.0, 0.7)
		if _sprite:
			_sprite.modulate = Color(1.3, 1.2, 1.4)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao)


func _cair_derrotado() -> void:
	_terminar_laser()
	super._cair_derrotado()


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
