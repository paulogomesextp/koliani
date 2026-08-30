class_name ChefeNagaZeraph
extends ChefeBase
## Região IV / nível 19 -- Naga Zeraph, a guardiã do Templo da Serpente.
## Meio-mulher meio-serpente, ergue-se do chão do templo:
##   * CUSPE  -- lança três jactos de veneno em arco.
##   * COBRAS -- levanta serpentes (DemonioBase rápido) do chão.
##   * TROCA  -- troca de lugar com uma estátua da arena (grupo
##     "estatuas_naga"); se não houver, teleporta para perto da Koliani.
##   * POCA   -- transforma um pedaço do chão numa poça de veneno que magoa
##     por contacto durante uns segundos.
## Depois de CUSPE / POCA ergue-se a sibilar (EXPOSTA -- o ventre à mostra,
## dano a dobrar).
## Fase 2 (< 50% vida): mais cobras, poças maiores e mais duradouras,
## troca mais vezes, cuspe mais aberto.

const COBRA := preload("res://scenes/actors/DemonioBase.tscn")
const CUSPE_VEL := 300.0

enum Fase { DORME, DECIDE, CUSPE_TEL, CUSPE, COBRAS_TEL, COBRAS, TROCA_TEL, TROCA, POCA_TEL, POCA, EXPOSTA }

@export var dist_deteta := 620.0
@export var dur_tel := 0.6
@export var dur_exposta := 1.4
@export var dano_cuspe := 15
@export var dano_cobra := 14
@export var dano_poca := 10
@export var dur_poca := 5.0

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposta := false
var _ciclos := 0
var _vida_max := 420
var _chao_cache := 0.0
var _base := Vector2.ZERO

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 640)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_base = global_position
	_chao_cache = global_position.y
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite:
		_sprite.position.y = sin(_pulso * 2.2) * (4.0 if not _exposta else 1.5)
	if _nucleo and _exposta:
		var p := 1.0 + 0.18 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_entrar_fase2()
	_encarar_koliani()

	match _fase:
		Fase.DORME:
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			if _t >= 0.3:
				_escolher()
		Fase.CUSPE_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_cuspir()
				_ir(Fase.CUSPE)
		Fase.CUSPE:
			if _t >= 0.4:
				_ir(Fase.EXPOSTA)
		Fase.COBRAS_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_levantar_cobras()
				_ir(Fase.COBRAS)
		Fase.COBRAS:
			if _t >= 0.5:
				_ir(Fase.EXPOSTA)
		Fase.TROCA_TEL:
			_piscar(true)
			if _t >= dur_tel * 0.7:
				_piscar(false)
				_trocar_com_estatua()
				_ir(Fase.TROCA)
		Fase.TROCA:
			if _t >= 0.25:
				_ir(Fase.DECIDE)
		Fase.POCA_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_poca_veneno()
				_ir(Fase.POCA)
		Fase.POCA:
			if _t >= 0.4:
				_ir(Fase.EXPOSTA)
		Fase.EXPOSTA:
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


func _escolher() -> void:
	var op := _ciclos % 4
	if _fase2 and _ciclos % 3 == 2:
		op = 2  # troca mais vezes
	match op:
		0: _ir(Fase.CUSPE_TEL)
		1: _ir(Fase.COBRAS_TEL)
		2: _ir(Fase.TROCA_TEL)
		_: _ir(Fase.POCA_TEL)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 340.0


## --- ataques ---------------------------------------------------------

func _cuspir() -> void:
	Som.toca("projetil", -8.0, 0.7)
	var base := _vetor_para_koliani().normalized()
	if base.length() < 0.5:
		base = Vector2(_direcao, -0.1).normalized()
	var esp := 0.34 if _fase2 else 0.22
	for a in [-esp, 0.0, esp]:
		_jacto(base.rotated(a))


func _jacto(dir: Vector2) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var j := Area2D.new()
	j.collision_layer = 0
	j.collision_mask = 2
	j.global_position = global_position + Vector2(0, -26) + dir * 24.0
	pai.add_child(j)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 7.0
	forma.shape = cs
	j.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.5, 0.85, 0.3, 0.95)
	poly.polygon = PackedVector2Array([Vector2(-7, 0), Vector2(0, -7), Vector2(7, 0), Vector2(0, 7)])
	j.add_child(poly)
	var dano := dano_cuspe
	j.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(dano, signf(dir.x))
		j.queue_free())
	# arco simples: sobe até um ponto e depois desce para lá do alvo
	var origem := j.global_position
	var apex := origem + dir * 260.0 + Vector2(0, -70.0)
	var fim := apex + Vector2(dir.x, 0.9).normalized() * 700.0
	var t := j.create_tween()
	t.tween_property(j, "global_position", apex, 260.0 / CUSPE_VEL).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(j, "global_position", fim, 700.0 / CUSPE_VEL).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_callback(j.queue_free)


func _levantar_cobras() -> void:
	Som.toca("demonio_ataque", -8.0, 0.7)
	var pai := get_parent()
	if pai == null:
		return
	var n := 3 if _fase2 else 2
	for i in n:
		var c := COBRA.instantiate()
		c.especie = "esqueleto"
		c.vida = 20
		c.dano_contacto = dano_cobra
		c.velocidade = 120.0
		c.alcance_patrulha = 340.0
		c.cor_estilhacos = Color(0.4, 0.7, 0.3)
		c.cor_rim = Color(0.55, 0.95, 0.45)
		var x := _x_koliani() + (i - (n - 1) * 0.5) * 90.0
		c.global_position = Vector2(x, _chao_y(x) - 20.0)
		pai.add_child(c)
		c.get_tree().create_timer(9.0).timeout.connect(func() -> void:
			if is_instance_valid(c) and not c._morto:
				c.soltar_estilhacos()
				c.queue_free())


func _trocar_com_estatua() -> void:
	Som.toca("onda", -9.0, 1.4)
	var estatuas := get_tree().get_nodes_in_group("estatuas_naga")
	var destino: Vector2
	if estatuas.is_empty():
		var lado := -1.0 if randf() < 0.5 else 1.0
		destino = Vector2(_x_koliani() + lado * 200.0, global_position.y)
	else:
		var e: Node2D = estatuas[randi() % estatuas.size()]
		destino = e.global_position
		e.global_position = global_position
	global_position = destino
	_encarar_koliani()


func _poca_veneno() -> void:
	Som.toca("onda", -7.0, 0.6)
	var pai := get_parent()
	if pai == null:
		return
	var x := _x_koliani() + randf_range(-40.0, 40.0)
	var chao := _chao_y(x)
	var largura := 180.0 if _fase2 else 130.0
	var p := Area2D.new()
	p.collision_layer = 0
	p.collision_mask = 2
	p.global_position = Vector2(x, chao - 6.0)
	pai.add_child(p)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(largura, 20.0)
	forma.shape = rs
	p.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.35, 0.7, 0.25, 0.0)
	poly.polygon = PackedVector2Array([Vector2(-largura * 0.5, 10), Vector2(-largura * 0.5 + 8, -8), Vector2(largura * 0.5 - 8, -8), Vector2(largura * 0.5, 10)])
	p.add_child(poly)
	var luz := PointLight2D.new()
	luz.texture = _tex_luz()
	luz.energy = 0.35
	luz.color = Color(0.4, 0.9, 0.3)
	luz.scale = Vector2(largura / 90.0, 0.4)
	p.add_child(luz)
	var dano := dano_poca
	var dur: float = dur_poca * (1.5 if _fase2 else 1.0)
	p.create_tween().tween_property(poly, "modulate:a", 0.85, 0.2)
	# dano por ticks enquanto a poça existe
	var timer := Timer.new()
	timer.wait_time = 0.6
	timer.autostart = true
	p.add_child(timer)
	timer.timeout.connect(func() -> void:
		for b in p.get_overlapping_bodies():
			if b is Koliani:
				b.receber_dano(dano, 0.0))
	get_tree().create_timer(dur).timeout.connect(func() -> void:
		if is_instance_valid(p):
			var tw := p.create_tween()
			tw.tween_property(poly, "modulate:a", 0.0, 0.3)
			tw.tween_callback(p.queue_free))


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -8.0, 0.7)
	_abanar_camera(7.0)
	dur_tel *= 0.78
	dur_exposta *= 0.88


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
			luz.energy = 1.6 if v else 0.12
		var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
		if brilho:
			brilho.visible = v


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	if _ja_derrotado:
		return
	provocar()
	if not _exposta:
		Som.toca("bloqueio", -9.0, 0.7)
		if _sprite:
			_sprite.modulate = Color(1.1, 1.3, 1.0)
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
		return _base.y + 40.0
	var de := Vector2(x, _base.y - 60.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 640.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else _base.y + 40.0


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
