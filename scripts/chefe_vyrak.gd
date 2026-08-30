class_name ChefeVyrak
extends ChefeBase
## Região III / nível 15 -- Vyrak, o Dragão das Sombras (fecha as Torres).
## Luta em três fases:
##   F1 (100%-66%) NO PICO: empoleirado, dá garradas e sopra uma nuvem de
##      sombra rasteira. Baixa a cabeça para rugir = EXPOSTO (núcleo do
##      peito, dano a dobrar).
##   F2 (66%-33%) VOA: parte o cimo da torre (as plataformas do grupo
##      "plataformas_pico" caem) e levanta voo -- passagens a rasar com
##      bolas de sombra, varridelas de cauda. Paira para rugir = EXPOSTO.
##   F3 (33%-0%) EM CIMA DELE: despenca-se meio-abatido, cabeça e peito
##      baixos e ao alcance -- o núcleo fica EXPOSTO o tempo todo (x2), mas
##      o dragão debate-se: garra + cauda alternadas e pulsos de sombra.
##      (A "arena em cima do dragão" literal fica para um polimento futuro.)

const BOLA_VEL := 300.0

enum Fase {
	DORME, DECIDE, GARRA_TEL, GARRA, SOPRO_TEL, SOPRO, EXPOSTO,
	F2_INICIO, DECIDE2, PASSAGEM_TEL, PASSAGEM, CAUDA_TEL, CAUDA, EXPOSTO2,
	F3_INICIO, DECIDE3, F3_GARRA_TEL, F3_GARRA, F3_CAUDA_TEL, F3_CAUDA, F3_NOVA_TEL, F3_NOVA,
}

@export var dist_deteta := 680.0
@export var altura_voo := 210.0
@export var dur_tel := 0.55
@export var dur_exposto := 1.45
@export var dano_garra := 22
@export var dano_sopro := 16
@export var dano_cauda := 20
@export var dano_bola := 15
@export var dano_nova := 18

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _ciclos := 0
var _vida_max := 560
var _f2 := false
var _f3 := false
var _exposto := false
var _chao_cache := 0.0
var _base_x := 0.0
var _passagem_dir := 1.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 620)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_base_x = global_position.x
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite and not _f3:
		_sprite.position.y = sin(_pulso * 2.0) * (5.0 if not _exposto else 2.0)
	if _nucleo and (_exposto or _f3):
		var p := (1.0 if _exposto else 0.6) + 0.16 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(_base_x)
	if not _f2 and not _ja_derrotado and vida <= int(_vida_max * 0.66):
		_ir(Fase.F2_INICIO)
	elif _f2 and not _f3 and not _ja_derrotado and vida <= int(_vida_max * 0.33):
		_ir(Fase.F3_INICIO)

	match _fase:
		Fase.DORME:
			global_position.y = lerpf(global_position.y, _chao_cache - 40.0, clampf(dt * 3.0, 0.0, 1.0))
			_encarar_koliani()
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_encarar_koliani()
			global_position.x = lerpf(global_position.x, _base_x, clampf(dt * 3.0, 0.0, 1.0))
			if _t >= 0.3:
				_ir(Fase.GARRA_TEL if _ciclos % 2 == 0 else Fase.SOPRO_TEL)
		Fase.GARRA_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				Som.toca("investida", -7.0, 0.8)
				_ataque_forte = 0.4
				_ir(Fase.GARRA)
		Fase.GARRA:
			global_position.x += _direcao * 260.0 * dt
			if _t < 0.05:
				_golpe_frontal(dano_garra, 120.0, 90.0)
			if _t >= 0.4:
				_ir(Fase.EXPOSTO)
		Fase.SOPRO_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_sopro()
				_ir(Fase.SOPRO)
		Fase.SOPRO:
			if _t >= 0.6:
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
		# --- F2 --------------------------------------------------
		Fase.F2_INICIO:
			if _t < dt:
				_partir_a_torre()
			if _t >= 0.9:
				_ir(Fase.DECIDE2)
		Fase.DECIDE2:
			global_position.y = lerpf(global_position.y, _chao_cache - altura_voo, clampf(dt * 2.5, 0.0, 1.0))
			_encarar_koliani()
			if _t >= 0.3:
				_ir(Fase.PASSAGEM_TEL if _ciclos % 2 == 0 else Fase.CAUDA_TEL)
		Fase.PASSAGEM_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_passagem_dir = _dir_para_koliani()
				global_position.x = _base_x - _passagem_dir * 520.0
				Som.toca("investida", -6.0, 0.7)
				_ir(Fase.PASSAGEM)
		Fase.PASSAGEM:
			global_position.x += _passagem_dir * 620.0 * dt
			if fmod(_t, 0.16) < dt:
				_bola_para_baixo()
			if absf(global_position.x - _base_x) > 540.0 and _t > 0.4:
				_ir(Fase.EXPOSTO2)
		Fase.CAUDA_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_cauda()
				_ir(Fase.CAUDA)
		Fase.CAUDA:
			if _t >= 0.5:
				_ir(Fase.EXPOSTO2)
		Fase.EXPOSTO2:
			global_position.x = lerpf(global_position.x, _base_x, clampf(dt * 3.0, 0.0, 1.0))
			global_position.y = lerpf(global_position.y, _chao_cache - altura_voo * 0.7, clampf(dt * 2.5, 0.0, 1.0))
			if not _exposto:
				_exposto = true
				_mostrar_nucleo(true)
			if _t >= dur_exposto * 0.9:
				_exposto = false
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.DECIDE2)
		# --- F3 --------------------------------------------------
		Fase.F3_INICIO:
			if _t < dt:
				_despencar()
			global_position.y = lerpf(global_position.y, _chao_cache - 20.0, clampf(dt * 4.0, 0.0, 1.0))
			if _t >= 0.8:
				_ir(Fase.DECIDE3)
		Fase.DECIDE3:
			_encarar_koliani()
			if _t >= 0.22:
				match _ciclos % 3:
					0: _ir(Fase.F3_GARRA_TEL)
					1: _ir(Fase.F3_CAUDA_TEL)
					_: _ir(Fase.F3_NOVA_TEL)
		Fase.F3_GARRA_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel * 0.7:
				_piscar(false)
				_golpe_frontal(dano_garra, 150.0, 100.0)
				_ir(Fase.F3_GARRA)
		Fase.F3_GARRA:
			if _t >= 0.35:
				_ciclos += 1
				_ir(Fase.DECIDE3)
		Fase.F3_CAUDA_TEL:
			_piscar(true)
			if _t >= dur_tel * 0.7:
				_piscar(false)
				_cauda()
				_ir(Fase.F3_CAUDA)
		Fase.F3_CAUDA:
			if _t >= 0.4:
				_ciclos += 1
				_ir(Fase.DECIDE3)
		Fase.F3_NOVA_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_nova()
				_ir(Fase.F3_NOVA)
		Fase.F3_NOVA:
			if _t >= 0.6:
				_ciclos += 1
				_ir(Fase.DECIDE3)
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	if f == Fase.F2_INICIO:
		_f2 = true
	elif f == Fase.F3_INICIO:
		_f3 = true
	_fase = f
	_t = 0.0


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 400.0


## --- ataques ---------------------------------------------------------

func _golpe_frontal(dano: int, alcance_x: float, alcance_y: float) -> void:
	Som.toca("demonio_ataque", -7.0, 0.8)
	var k := _obter_koliani()
	if k == null:
		return
	var d := _vetor_para_koliani()
	if absf(d.x) <= alcance_x and absf(d.y) <= alcance_y and signf(d.x) == _direcao:
		k.receber_dano(int(round(dano * (1.15 if _f3 else 1.0))), _direcao)


func _sopro() -> void:
	Som.toca("onda", -6.0, 0.7)
	var pai := get_parent()
	if pai == null:
		return
	var dir := _dir_para_koliani()
	var nuvem := Area2D.new()
	nuvem.collision_layer = 0
	nuvem.collision_mask = 2
	nuvem.global_position = global_position + Vector2(dir * 40.0, 20.0)
	pai.add_child(nuvem)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(40, 46)
	forma.shape = rs
	nuvem.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.35, 0.2, 0.5, 0.6)
	poly.polygon = PackedVector2Array([Vector2(-20, 22), Vector2(-14, -20), Vector2(16, -16), Vector2(22, 22)])
	nuvem.add_child(poly)
	var dano := dano_sopro
	nuvem.body_entered.connect(func(c: Node) -> void:
		if c is Koliani:
			c.receber_dano(dano, dir))
	var t := nuvem.create_tween()
	t.tween_property(nuvem, "global_position:x", global_position.x + dir * 520.0, 0.9)
	t.parallel().tween_property(nuvem, "scale", Vector2(2.2, 1.4), 0.9)
	t.parallel().tween_property(poly, "modulate:a", 0.0, 0.9)
	t.tween_callback(nuvem.queue_free)


func _cauda() -> void:
	Som.toca("investida", -6.0, 0.6)
	_abanar_camera(5.0)
	var pai := get_parent()
	if pai == null:
		return
	var lado := -_direcao
	var golpe := Area2D.new()
	golpe.collision_layer = 0
	golpe.collision_mask = 2
	golpe.global_position = global_position + Vector2(lado * 70.0, 10.0)
	pai.add_child(golpe)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(150, 48)
	forma.shape = rs
	golpe.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.3, 0.18, 0.42, 0.7)
	poly.polygon = PackedVector2Array([Vector2(-75, 20), Vector2(-60, -18), Vector2(70, -6), Vector2(75, 24)])
	golpe.add_child(poly)
	var dano := int(round(dano_cauda * (1.15 if _f3 else 1.0)))
	golpe.body_entered.connect(func(c: Node) -> void:
		if c is Koliani:
			c.receber_dano(dano, lado))
	var t := golpe.create_tween()
	t.tween_callback(func() -> void:
		for c in golpe.get_overlapping_bodies():
			if c is Koliani:
				c.receber_dano(dano, lado))
	t.tween_property(poly, "modulate:a", 0.0, 0.28)
	t.tween_callback(golpe.queue_free)


func _bola_para_baixo() -> void:
	var pai := get_parent()
	if pai == null:
		return
	var b := Area2D.new()
	b.collision_layer = 0
	b.collision_mask = 2
	b.global_position = global_position + Vector2(0, 20)
	pai.add_child(b)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 9.0
	forma.shape = cs
	b.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.5, 0.28, 0.7, 0.95)
	poly.polygon = PackedVector2Array([Vector2(-8, 0), Vector2(0, -8), Vector2(8, 0), Vector2(0, 8)])
	b.add_child(poly)
	var dano := dano_bola
	b.body_entered.connect(func(c: Node) -> void:
		if c is Koliani:
			c.receber_dano(dano, signf(c.global_position.x - b.global_position.x))
		b.queue_free())
	var t := b.create_tween()
	t.tween_property(b, "global_position", b.global_position + Vector2(randf_range(-60, 60), 460.0), 460.0 / BOLA_VEL)
	t.tween_callback(b.queue_free)


func _nova() -> void:
	Som.toca("onda", -5.0, 0.9)
	_abanar_camera(6.0)
	var pai := get_parent()
	if pai == null:
		return
	for i in 8:
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / 8.0)
		var o := Area2D.new()
		o.collision_layer = 0
		o.collision_mask = 2
		o.global_position = global_position + Vector2(0, -6)
		pai.add_child(o)
		var forma := CollisionShape2D.new()
		var cs := CircleShape2D.new()
		cs.radius = 9.0
		forma.shape = cs
		o.add_child(forma)
		var poly := Polygon2D.new()
		poly.color = Color(0.45, 0.25, 0.62, 0.9)
		poly.polygon = PackedVector2Array([Vector2(-8, 0), Vector2(0, -8), Vector2(8, 0), Vector2(0, 8)])
		o.add_child(poly)
		var dano := dano_nova
		o.body_entered.connect(func(c: Node) -> void:
			if c is Koliani:
				c.receber_dano(dano, signf(dir.x))
			o.queue_free())
		var t := o.create_tween()
		t.tween_property(o, "global_position", o.global_position + dir * 520.0, 1.3)
		t.tween_callback(o.queue_free)


## --- transições de fase ------------------------------------------------

func _partir_a_torre() -> void:
	Som.toca("chefe_cai", -6.0, 0.7)
	Som.toca("onda", -5.0, 0.6)
	_abanar_camera(10.0)
	for p in get_tree().get_nodes_in_group("plataformas_pico"):
		if not is_instance_valid(p):
			continue
		var tw := (p as Node).create_tween()
		tw.tween_property(p, "position:y", (p as Node2D).position.y + 400.0, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.8)
		tw.tween_callback((p as Node).queue_free)
	dano_contacto = int(round(dano_contacto * 1.1))


func _despencar() -> void:
	Som.toca("chefe_cai", -5.0, 0.6)
	_abanar_camera(12.0)
	dur_tel *= 0.7
	dano_contacto = int(round(dano_contacto * 1.1))
	_mostrar_nucleo(true)  # núcleo fica exposto o resto da luta
	_exposto = true


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
		Som.toca("bloqueio", -8.0, 0.6)
		if _sprite:
			_sprite.modulate = Color(1.3, 1.1, 1.4)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao)


## --- utilitários --------------------------------------------------

func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return _origem.y + 40.0
	var de := Vector2(x, _origem.y - 60.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 760.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else _origem.y + 40.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)
