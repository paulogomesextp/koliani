class_name ChefeArautoDeZeriko
extends ChefeBase
## Região VI / nível 29 -- O Arauto de Zeriko, braço direito do demónio.
## Uma luta, TRÊS FORMAS:
##   F1 CAVALEIRO (100%-66%) -- armadura e espada: golpes + investida.
##   F2 DEMÓNIO  (66%-33%) -- larga a armadura, cornos e garras: combo de
##      garras, sopro de fogo púrpura, salto.
##   F3 ENTIDADE (33%-0%) -- magia pura: flutua, teleporta, dardos em
##      padrão e novas radiais. Mal tem corpo.
## O núcleo magenta fica sempre; janelas EXPOSTO depois dos ataques
## (dano a dobrar). Ao cair -- a pista revela que Zeriko nunca esteve só.

const DARDO_VEL := 340.0

enum Fase {
	DORME,
	# F1
	D1, C1_GOLPE_TEL, C1_GOLPE, C1_INV_TEL, C1_INV, E1,
	MUDA_2,
	# F2
	D2, G2_TEL, G2, SOPRO_TEL, SOPRO, SALTO_TEL, SALTO, E2,
	MUDA_3,
	# F3
	D3, TP3, DARDOS_TEL, DARDOS, NOVA_TEL, NOVA, E3,
}

@export var dist_deteta := 680.0
@export var dur_tel := 0.5
@export var dur_exposto := 1.2
@export var altura_voo := 190.0

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _forma := 1
var _exposto := false
var _ciclos := 0
var _golpes := 0
var _vida_max := 640
var _chao_cache := 0.0
var _base_x := 0.0
var _inv_dir := 1.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 640)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_base_x = global_position.x
	_mostrar_nucleo(false)
	falas_intro = [
		{ "quem": "boss.arauto_de_zeriko", "texto": "dlg.arauto.intro.1" },
		{ "quem": "boss.arauto_de_zeriko", "texto": "dlg.arauto.intro.2" },
	]
	falas_fim = [
		{ "quem": "boss.arauto_de_zeriko", "texto": "dlg.arauto.win.1" },
	]


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite and _forma == 3:
		_sprite.position.y = sin(_pulso * 2.4) * 6.0
	if _nucleo and _exposto:
		var p := 1.0 + 0.2 * sin(_pulso * 10.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(_base_x)
	# transições de forma
	if _forma == 1 and vida <= int(_vida_max * 0.66) and _fase != Fase.MUDA_2:
		_ir(Fase.MUDA_2)
	elif _forma == 2 and vida <= int(_vida_max * 0.33) and _fase != Fase.MUDA_3:
		_ir(Fase.MUDA_3)

	if _forma < 3:
		if not is_on_floor() and _fase != Fase.SALTO:
			velocity.y += GRAVIDADE * dt
		elif is_on_floor():
			velocity.y = 0.0
		if _fase not in [Fase.C1_GOLPE, Fase.C1_INV, Fase.G2, Fase.SALTO]:
			velocity.x = move_toward(velocity.x, 0.0, 1400.0 * dt)

	match _fase:
		Fase.DORME:
			_encarar_koliani()
			if _ve_koliani():
				provocar()
				_ir(Fase.D1)
		# ---------- F1 CAVALEIRO ----------
		Fase.D1:
			_encarar_koliani()
			var dx := _vetor_para_koliani().x
			if absf(dx) > 130.0:
				velocity.x = signf(dx) * 170.0
			if _t >= 0.24:
				_ir(Fase.C1_GOLPE_TEL if absf(dx) < 220.0 else Fase.C1_INV_TEL)
		Fase.C1_GOLPE_TEL:
			_encarar_koliani(); _piscar(true)
			if _t >= dur_tel:
				_piscar(false); _golpes = 0
				_ir(Fase.C1_GOLPE)
		Fase.C1_GOLPE:
			velocity.x = _direcao * 150.0
			if _t >= 0.14 * (_golpes + 1) and _golpes < 3:
				_golpes += 1
				_golpe_frontal(16)
			if _t >= 0.6:
				_ir(Fase.E1)
		Fase.C1_INV_TEL:
			_encarar_koliani(); _piscar(true)
			if _t >= dur_tel:
				_piscar(false); _inv_dir = _dir_para_koliani()
				Som.toca("investida", -6.0, 1.0); _ataque_forte = 0.3
				_ir(Fase.C1_INV)
		Fase.C1_INV:
			velocity.x = _inv_dir * 560.0
			if _t < 0.05:
				_golpe_frontal(20, 96.0)
			if _t >= 0.3:
				_ir(Fase.E1)
		Fase.E1:
			_janela_exposto(Fase.D1)
		Fase.MUDA_2:
			if _t < dt:
				_mudar_forma(2)
			if _t >= 0.9:
				_ir(Fase.D2)
		# ---------- F2 DEMÓNIO ----------
		Fase.D2:
			_encarar_koliani()
			var dx2 := _vetor_para_koliani().x
			if absf(dx2) > 110.0:
				velocity.x = signf(dx2) * 210.0
			if _t >= 0.2:
				match _ciclos % 3:
					0: _ir(Fase.G2_TEL)
					1: _ir(Fase.SOPRO_TEL)
					_: _ir(Fase.SALTO_TEL)
		Fase.G2_TEL:
			_encarar_koliani(); _piscar(true)
			if _t >= dur_tel * 0.8:
				_piscar(false); _golpes = 0
				_ir(Fase.G2)
		Fase.G2:
			velocity.x = _direcao * 200.0
			if _t >= 0.1 * (_golpes + 1) and _golpes < 4:
				_golpes += 1
				_golpe_frontal(15, 90.0)
			if _t >= 0.55:
				_ir(Fase.E2)
		Fase.SOPRO_TEL:
			velocity.x = 0.0; _encarar_koliani(); _piscar(true)
			if _t >= dur_tel:
				_piscar(false); _sopro_fogo()
				_ir(Fase.SOPRO)
		Fase.SOPRO:
			if _t >= 0.7:
				_ir(Fase.E2)
		Fase.SALTO_TEL:
			_encarar_koliani(); _piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				velocity.y = -460.0
				velocity.x = signf(_x_koliani() - global_position.x) * 240.0
				_ir(Fase.SALTO)
		Fase.SALTO:
			velocity.y += GRAVIDADE * dt
			if is_on_floor() and _t > 0.12:
				_golpe_frontal(22, 130.0); _abanar_camera(5.0)
				_ir(Fase.E2)
		Fase.E2:
			_janela_exposto(Fase.D2)
		Fase.MUDA_3:
			if _t < dt:
				_mudar_forma(3)
			global_position.y = lerpf(global_position.y, _chao_cache - altura_voo, clampf(dt * 3.0, 0.0, 1.0))
			if _t >= 0.9:
				_ir(Fase.D3)
		# ---------- F3 ENTIDADE ----------
		Fase.D3:
			global_position.y = lerpf(global_position.y, _chao_cache - altura_voo, clampf(dt * 3.0, 0.0, 1.0))
			global_position.x = lerpf(global_position.x, _x_koliani(), clampf(dt * 1.0, 0.0, 1.0))
			_encarar_koliani()
			if _t >= 0.24:
				match _ciclos % 3:
					0: _ir(Fase.TP3)
					1: _ir(Fase.DARDOS_TEL)
					_: _ir(Fase.NOVA_TEL)
		Fase.TP3:
			if _t < dt and _sprite:
				create_tween().tween_property(_sprite, "modulate:a", 0.1, 0.14)
			if _t >= 0.22:
				var lado := -1.0 if randf() < 0.5 else 1.0
				var x := clampf(_x_koliani() + lado * randf_range(180.0, 300.0), _base_x - 360.0, _base_x + 360.0)
				_chao_cache = _chao_y(x)
				global_position = Vector2(x, _chao_cache - altura_voo)
				if _sprite:
					create_tween().tween_property(_sprite, "modulate:a", 1.0, 0.14)
				_ir(Fase.DARDOS_TEL)
		Fase.DARDOS_TEL:
			_encarar_koliani(); _piscar(true)
			if _t >= dur_tel * 0.8:
				_piscar(false); _dardos()
				_ir(Fase.DARDOS)
		Fase.DARDOS:
			if _t >= 0.4:
				_ir(Fase.E3)
		Fase.NOVA_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false); _nova()
				_ir(Fase.NOVA)
		Fase.NOVA:
			if _t >= 0.5:
				_ir(Fase.E3)
		Fase.E3:
			global_position.y = lerpf(global_position.y, _chao_cache - altura_voo, clampf(dt * 2.5, 0.0, 1.0))
			_janela_exposto(Fase.D3)

	if _forma < 3:
		move_and_slide()
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


func _janela_exposto(volta: Fase) -> void:
	if not _exposto:
		_exposto = true
		_mostrar_nucleo(true)
	if _t >= dur_exposto:
		_exposto = false
		_mostrar_nucleo(false)
		_ciclos += 1
		_ir(volta)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 380.0


## --- ataques comuns ------------------------------------------------

func _golpe_frontal(dano: int, alcance := 82.0) -> void:
	Som.toca("demonio_ataque", -8.0, 1.1)
	var k := _obter_koliani()
	if k == null:
		return
	var d := _vetor_para_koliani()
	if absf(d.x) <= alcance and absf(d.y) <= 74.0 and signf(d.x) == _direcao:
		k.receber_dano(dano, _direcao)


func _sopro_fogo() -> void:
	Som.toca("onda", -6.0, 0.7)
	var pai := get_parent()
	if pai == null:
		return
	var dir := _dir_para_koliani()
	var s := Area2D.new()
	s.collision_layer = 0
	s.collision_mask = 2
	s.global_position = global_position + Vector2(dir * 36.0, -20.0)
	pai.add_child(s)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(40, 44)
	forma.shape = rs
	s.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.7, 0.35, 1.0, 0.55)
	poly.polygon = PackedVector2Array([Vector2(-16, 20), Vector2(-10, -20), Vector2(14, -16), Vector2(18, 22)])
	s.add_child(poly)
	s.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(16, dir))
	var t := s.create_tween()
	t.tween_property(s, "global_position:x", global_position.x + dir * 520.0, 0.8)
	t.parallel().tween_property(s, "scale", Vector2(2.4, 1.5), 0.8)
	t.parallel().tween_property(poly, "modulate:a", 0.0, 0.8)
	t.tween_callback(s.queue_free)


func _dardos() -> void:
	Som.toca("projetil", -9.0, 0.7)
	var base := _dir_vec_para_koliani()
	for a in [-0.28, 0.0, 0.28]:
		_dardo(base.rotated(a))


func _dardo(dir: Vector2) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var d := Area2D.new()
	d.collision_layer = 0
	d.collision_mask = 2
	d.global_position = global_position + Vector2(0, -10)
	pai.add_child(d)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 8.0
	forma.shape = cs
	d.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.7, 0.35, 1.0, 0.95)
	poly.polygon = PackedVector2Array([Vector2(-8, 0), Vector2(0, -7), Vector2(8, 0), Vector2(0, 7)])
	d.add_child(poly)
	d.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(14, signf(dir.x))
		d.queue_free())
	var t := d.create_tween()
	t.tween_property(d, "global_position", d.global_position + dir * 1400.0, 1400.0 / DARDO_VEL)
	t.tween_callback(d.queue_free)


func _nova() -> void:
	Som.toca("onda", -4.0, 0.8)
	_abanar_camera(7.0)
	var pai := get_parent()
	if pai == null:
		return
	for i in 14:
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / 14.0)
		var o := Area2D.new()
		o.collision_layer = 0
		o.collision_mask = 2
		o.global_position = global_position
		pai.add_child(o)
		var forma := CollisionShape2D.new()
		var cs := CircleShape2D.new()
		cs.radius = 9.0
		forma.shape = cs
		o.add_child(forma)
		var poly := Polygon2D.new()
		poly.color = Color(0.6, 0.3, 1.0, 0.9)
		poly.polygon = PackedVector2Array([Vector2(-8, 0), Vector2(0, -8), Vector2(8, 0), Vector2(0, 8)])
		o.add_child(poly)
		o.body_entered.connect(func(b: Node) -> void:
			if b is Koliani:
				b.receber_dano(18, signf(dir.x))
			o.queue_free())
		var t := o.create_tween()
		t.tween_property(o, "global_position", o.global_position + dir * 640.0, 1.2)
		t.tween_callback(o.queue_free)


## --- transições de forma ------------------------------------------

func _mudar_forma(n: int) -> void:
	_forma = n
	Som.toca("chefe_cai", -5.0, 0.7)
	Som.toca("onda", -6.0, 0.6)
	_abanar_camera(10.0)
	dur_tel *= 0.85
	dur_exposto *= 0.9
	dano_contacto = int(round(dano_contacto * 1.1))
	var p := CPUParticles2D.new()
	p.global_position = global_position + Vector2(0, -20)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 36
	p.lifetime = 0.7
	p.spread = 180.0
	p.gravity = Vector2(0, 400)
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 300.0
	p.color = Color(0.7, 0.35, 1.0)
	add_sibling(p)
	p.get_tree().create_timer(1.3).timeout.connect(p.queue_free)
	if _corpo:
		_corpo.frame = 0
	if _sprite:
		var esc := 1.0 + 0.08 * (n - 1)
		create_tween().tween_property(_sprite, "scale", Vector2(esc, esc), 0.4)


## --- núcleo / dano -------------------------------------------------

func _piscar(ligado: bool) -> void:
	super._piscar(ligado)
	if _corpo and not _exposto:
		_corpo.frame = 2 if ligado else clampi(_forma - 1, 0, 1)


func _mostrar_nucleo(v: bool) -> void:
	_exposto = v
	_pulso = 0.0
	if _corpo:
		_corpo.frame = 3 if v else clampi(_forma - 1, 0, 1)
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
		Som.toca("bloqueio", -9.0, 0.6)
		if _sprite:
			_sprite.modulate = Color(1.3, 1.1, 1.4)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao)


## --- utilitários --------------------------------------------------

func _dir_vec_para_koliani() -> Vector2:
	var d := _vetor_para_koliani()
	return d.normalized() if d.length() > 1.0 else Vector2(_direcao, 0)


func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return _origem.y + 40.0
	var de := Vector2(x, _origem.y - 60.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 700.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else _origem.y + 40.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)
