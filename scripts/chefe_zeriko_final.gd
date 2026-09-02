class_name ChefeZerikoFinal
extends ChefeBase
## Nível 30 -- ZERIKO, no seu trono. O chefe final: NÃO é só um mago
## gigante. QUATRO fases, cada uma uma cara diferente da coisa que ele é:
##   F1 O MAGO      (100%-75%) -- teleporta, salvas de projéteis, meteoros.
##   F2 O REI       (75%-50%)  -- ergue o trono corrompido (garras de
##      RaizPerigo em roda) e esconde-se atrás; larga cavaleiros.
##   F3 A COISA DO ABISMO (50%-25%) -- o chão vira sombra: tentáculos
##      irrompem (RaizPerigo) e um olho abre-se e varre um feixe.
##   F4 O QUE RESTA (25%-0%)  -- despido até magia crua: pequeno, rápido,
##      pestaneja de um lado ao outro com golpes de magia e, no fim, uma
##      nova que enche a arena (há um sítio seguro: junto dele).
## Núcleo magenta sempre; janelas EXPOSTO depois dos ataques (dano x2).

const PROJ := preload("res://scenes/actors/ProjetilZeriko.tscn")
const RAIZ := preload("res://scenes/actors/RaizPerigo.tscn")
const CAVALEIRO := preload("res://scenes/actors/DemonioBase.tscn")

enum Fase {
	DORME,
	D1, M1_TEL, M1_SALVA, M1_METEOROS_TEL, M1_METEOROS, E1, MUDA2,
	D2, R2_TEL, R2_CAVS, R2_TRONO_TEL, R2_TRONO, E2, MUDA3,
	D3, A3_TENT_TEL, A3_TENT, A3_OLHO_TEL, A3_OLHO, E3, MUDA4,
	D4, Q4_TP, Q4_GOLPE, Q4_NOVA_TEL, Q4_NOVA, E4,
}

@export var dist_deteta := 800.0
@export var altura_voo := 200.0
@export var dur_tel := 0.5
@export var dur_exposto := 1.15

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _forma := 1
var _exposto := false
var _ciclos := 0
var _vida_max := 900
var _chao_cache := 0.0
var _base := Vector2.ZERO
var _olho_ang0 := 0.0
var _olho_ang1 := 0.0
var _feixe: Line2D
var _feixe_area: Area2D

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 1200)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_base = global_position
	_chao_cache = _chao_y(_base.x)
	_mostrar_nucleo(false)
	falas_intro = [
		{ "quem": "boss.zeriko", "texto": "dlg.zeriko.intro.1" },
		{ "quem": "boss.zeriko", "texto": "dlg.zeriko.intro.2" },
	]
	falas_fim = [
		{ "quem": "boss.zeriko", "texto": "dlg.zeriko.win.1" },
		{ "quem": "boss.zeriko", "texto": "dlg.zeriko.win.2" },
	]


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite:
		_sprite.position.y = sin(_pulso * 2.0) * (6.0 if _forma != 2 else 1.0)
	if _nucleo and _exposto:
		var p := 1.0 + 0.2 * sin(_pulso * 10.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	# transições de forma por limiar
	if _forma == 1 and vida <= int(_vida_max * 0.75) and _fase != Fase.MUDA2:
		_ir(Fase.MUDA2)
	elif _forma == 2 and vida <= int(_vida_max * 0.5) and _fase != Fase.MUDA3:
		_ir(Fase.MUDA3)
	elif _forma == 3 and vida <= int(_vida_max * 0.25) and _fase != Fase.MUDA4:
		_ir(Fase.MUDA4)

	var alvo_y := _chao_cache - altura_voo
	if _forma != 2:
		global_position.y = lerpf(global_position.y, alvo_y, clampf(dt * 3.0, 0.0, 1.0))
	_encarar_koliani()

	match _fase:
		Fase.DORME:
			if _ve_koliani():
				provocar()
				_ir(Fase.D1)
		# ---------- F1 O MAGO ----------
		Fase.D1:
			global_position.x = lerpf(global_position.x, _x_koliani(), clampf(dt * 1.0, 0.0, 1.0))
			if _t >= 0.24:
				_ir(Fase.M1_TEL if _ciclos % 2 == 0 else Fase.M1_METEOROS_TEL)
		Fase.M1_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_teleportar(randf_range(180.0, 320.0))
				_salva()
				_ir(Fase.M1_SALVA)
		Fase.M1_SALVA:
			if _t >= 0.5:
				_ir(Fase.E1)
		Fase.M1_METEOROS_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_ir(Fase.M1_METEOROS)
		Fase.M1_METEOROS:
			if fmod(_t, 0.28) < dt:
				_meteoro()
			if _t >= 1.4:
				_ir(Fase.E1)
		Fase.E1:
			_janela(Fase.D1)
		Fase.MUDA2:
			if _t < dt:
				_mudar(2)
			if _t >= 1.0:
				_ir(Fase.D2)
		# ---------- F2 O REI ----------
		Fase.D2:
			global_position = global_position.lerp(_base, clampf(dt * 3.0, 0.0, 1.0))
			if _t >= 0.24:
				match _ciclos % 3:
					0: _ir(Fase.R2_TRONO_TEL)
					1: _ir(Fase.R2_CAVS)
					_: _ir(Fase.R2_TRONO_TEL)
		Fase.R2_CAVS:
			if _t < dt:
				_cavaleiros()
			if _t >= 0.6:
				_ir(Fase.E2)
		Fase.R2_TRONO_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_trono_de_garras()
				_ir(Fase.R2_TRONO)
		Fase.R2_TRONO:
			if _t >= 1.3:
				_ir(Fase.E2)
		Fase.E2:
			_janela(Fase.D2)
		Fase.MUDA3:
			if _t < dt:
				_mudar(3)
			if _t >= 1.0:
				_ir(Fase.D3)
		# ---------- F3 A COISA DO ABISMO ----------
		Fase.D3:
			global_position.x = lerpf(global_position.x, _x_koliani(), clampf(dt * 0.8, 0.0, 1.0))
			if _t >= 0.22:
				_ir(Fase.A3_TENT_TEL if _ciclos % 2 == 0 else Fase.A3_OLHO_TEL)
		Fase.A3_TENT_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_tentaculos()
				_ir(Fase.A3_TENT)
		Fase.A3_TENT:
			if _t >= 1.2:
				_ir(Fase.E3)
		Fase.A3_OLHO_TEL:
			if _t < dt:
				_preparar_olho()
			_piscar(true)
			if _t >= dur_tel + 0.2:
				_piscar(false)
				_disparar_olho()
				_ir(Fase.A3_OLHO)
		Fase.A3_OLHO:
			var f := clampf(_t / 0.8, 0.0, 1.0)
			_atualizar_olho(lerpf(_olho_ang0, _olho_ang1, f))
			if _t >= 0.8:
				_terminar_olho()
				_ir(Fase.E3)
		Fase.E3:
			_janela(Fase.D3)
		Fase.MUDA4:
			if _t < dt:
				_mudar(4)
			if _t >= 1.0:
				_ir(Fase.D4)
		# ---------- F4 O QUE RESTA ----------
		Fase.D4:
			if _t >= 0.16:
				match _ciclos % 3:
					0, 1: _ir(Fase.Q4_TP)
					_: _ir(Fase.Q4_NOVA_TEL)
		Fase.Q4_TP:
			if _t < dt and _sprite:
				create_tween().tween_property(_sprite, "modulate:a", 0.1, 0.1)
			if _t >= 0.16:
				_teleportar(70.0)
				if _sprite:
					create_tween().tween_property(_sprite, "modulate:a", 1.0, 0.1)
				_ir(Fase.Q4_GOLPE)
		Fase.Q4_GOLPE:
			if _t < dt:
				_golpe_magia()
			if _t >= 0.3:
				_ir(Fase.E4)
		Fase.Q4_NOVA_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_nova_final()
				_ir(Fase.Q4_NOVA)
		Fase.Q4_NOVA:
			if _t >= 0.7:
				_ir(Fase.E4)
		Fase.E4:
			_janela(Fase.D4)
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


func _janela(volta: Fase) -> void:
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
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 460.0


## --- F1 ----------------------------------------------------------

func _salva() -> void:
	Som.toca("feixe_vil", -6.0, 0.8)
	var pai := get_parent()
	if pai == null:
		return
	var n := 5 + _forma
	for i in n:
		var ang := PI * 0.15 + PI * 0.7 * float(i) / float(n - 1)
		var dir := Vector2.DOWN.rotated(ang - PI * 0.5)
		var p := PROJ.instantiate()
		p.dano = 14
		pai.add_child(p)
		p.global_position = global_position + Vector2(0, 10)
		if p.has_method("lancar"):
			p.lancar(dir)


func _meteoro() -> void:
	var pai := get_parent()
	if pai == null:
		return
	Som.toca("meteoro", -5.0, 1.0)
	var x := _x_koliani() + randf_range(-180.0, 180.0)
	var chao := _chao_y(x)
	var m := Area2D.new()
	m.collision_layer = 0
	m.collision_mask = 2
	m.monitoring = false
	m.global_position = Vector2(x + 100.0, chao - 520.0)
	pai.add_child(m)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 16.0
	forma.shape = cs
	m.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.6, 0.32, 0.9, 1.0)
	poly.polygon = PackedVector2Array([Vector2(-14, 0), Vector2(0, -14), Vector2(14, 0), Vector2(0, 14)])
	m.add_child(poly)
	var marca := Polygon2D.new()
	marca.color = Color(0.7, 0.4, 1.0, 0.4)
	marca.polygon = PackedVector2Array([Vector2(-24, 0), Vector2(24, 0), Vector2(18, 8), Vector2(-18, 8)])
	marca.global_position = Vector2(x, chao - 4.0)
	pai.add_child(marca)
	m.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(18, signf(b.global_position.x - m.global_position.x)))
	var t := m.create_tween()
	t.tween_interval(0.4)
	t.tween_callback(func() -> void: m.monitoring = true)
	t.tween_property(m, "global_position", Vector2(x, chao - 6.0), 0.3).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void:
		_abanar_camera(3.0)
		for c in m.get_overlapping_bodies():
			if c is Koliani:
				c.receber_dano(18, 0.0))
	t.tween_property(poly, "modulate:a", 0.0, 0.25)
	t.parallel().tween_property(marca, "modulate:a", 0.0, 0.25)
	t.tween_callback(func() -> void:
		marca.queue_free()
		m.queue_free())


## --- F2 ----------------------------------------------------------

func _cavaleiros() -> void:
	Som.toca("invocar", -8.0, 0.6)
	var pai := get_parent()
	if pai == null:
		return
	for i in 2:
		var c := CAVALEIRO.instantiate()
		c.especie = "esqueleto"
		c.vida = 30
		c.dano_contacto = 16
		c.velocidade = 90.0
		c.alcance_patrulha = 360.0
		var x := _base.x + (i * 2 - 1) * 140.0
		c.global_position = Vector2(x, _chao_y(x) - 20.0)
		pai.add_child(c)


func _trono_de_garras() -> void:
	Som.toca("esmagar", -6.0, 0.7)
	_abanar_camera(6.0)
	var pai := get_parent()
	if pai == null:
		return
	var alvo := _x_koliani()
	for i in 5:
		var x := alvo + (i - 2) * 110.0
		var r := RAIZ.instantiate()
		r.dano = 18
		r.atraso = 0.4 + i * 0.06
		r.global_position = Vector2(x, _chao_y(x))
		pai.add_child(r)
		if r.has_method("avisar"):
			r.avisar(18, r.atraso, 60.0)


## --- F3 ----------------------------------------------------------

func _tentaculos() -> void:
	Som.toca("onda", -5.0, 0.6)
	_abanar_camera(7.0)
	var pai := get_parent()
	if pai == null:
		return
	var alvo := _x_koliani()
	for i in 6:
		var x := alvo + (i - 3) * 90.0 + randf_range(-20.0, 20.0)
		var r := RAIZ.instantiate()
		r.dano = 16
		r.atraso = 0.3 + (i % 3) * 0.12
		r.altura = 100.0
		r.global_position = Vector2(x, _chao_y(x))
		pai.add_child(r)
		if r.has_method("avisar"):
			r.avisar(16, r.atraso, 40.0)


func _preparar_olho() -> void:
	Som.toca("olho_carregar", -6.0, 0.9)
	var k := _obter_koliani()
	var alvo := k.global_position if k else global_position + Vector2(200, 60)
	var meio := (alvo - global_position).angle()
	_olho_ang0 = meio - 0.6
	_olho_ang1 = meio + 0.6
	_feixe = Line2D.new()
	_feixe.width = 2.0
	_feixe.default_color = Color(1.0, 0.3, 0.9, 0.5)
	_feixe.points = PackedVector2Array([Vector2.ZERO, Vector2(1600, 0)])
	_feixe.rotation = _olho_ang0
	add_child(_feixe)


func _disparar_olho() -> void:
	Som.toca("feixe_vil", -4.0, 0.9)
	_abanar_camera(4.0)
	if _feixe:
		_feixe.width = 9.0
		_feixe.default_color = Color(1.0, 0.35, 0.95, 0.95)
	_feixe_area = Area2D.new()
	_feixe_area.collision_layer = 0
	_feixe_area.collision_mask = 2
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(1600, 18)
	forma.shape = rs
	forma.position = Vector2(800, 0)
	_feixe_area.add_child(forma)
	add_child(_feixe_area)


func _atualizar_olho(ang: float) -> void:
	if is_instance_valid(_feixe):
		_feixe.rotation = ang
	if is_instance_valid(_feixe_area):
		_feixe_area.rotation = ang
		for b in _feixe_area.get_overlapping_bodies():
			if b is Koliani:
				b.receber_dano(22, signf(cos(ang)))


func _terminar_olho() -> void:
	if is_instance_valid(_feixe):
		var fx := _feixe
		_feixe = null
		var t := fx.create_tween()
		t.tween_property(fx, "modulate:a", 0.0, 0.2)
		t.tween_callback(fx.queue_free)
	if is_instance_valid(_feixe_area):
		_feixe_area.queue_free()
		_feixe_area = null


## --- F4 ----------------------------------------------------------

func _golpe_magia() -> void:
	Som.toca("golpe_pesado", -6.0, 1.3)
	var k := _obter_koliani()
	if k == null:
		return
	var d := _vetor_para_koliani()
	if d.length() <= 96.0:
		k.receber_dano(16, signf(d.x))


func _nova_final() -> void:
	Som.toca("esmagar", -3.0, 0.7)
	_abanar_camera(9.0)
	var pai := get_parent()
	if pai == null:
		return
	# anel que se expande a partir DELE -- o sitio seguro e' junto ao Zeriko
	var anel := Area2D.new()
	anel.collision_layer = 0
	anel.collision_mask = 2
	anel.monitoring = false
	anel.global_position = global_position
	pai.add_child(anel)
	var forma := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 30.0
	forma.shape = cs
	anel.add_child(forma)
	var linha := Line2D.new()
	linha.width = 6.0
	linha.default_color = Color(1.0, 0.35, 0.95, 0.9)
	linha.closed = true
	var pts := PackedVector2Array()
	for i in 28:
		pts.append(Vector2(cos(TAU * i / 28.0), sin(TAU * i / 28.0)) * 30.0)
	linha.points = pts
	anel.add_child(linha)
	anel.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(26, signf(b.global_position.x - anel.global_position.x)))
	var t := anel.create_tween()
	t.tween_interval(0.15)
	t.tween_callback(func() -> void: anel.monitoring = true)
	t.tween_property(anel, "scale", Vector2(24, 24), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(linha, "modulate:a", 0.0, 0.7)
	t.tween_callback(anel.queue_free)


## --- transições de forma / dano ---------------------------------

func _teleportar(afasta: float) -> void:
	var lado := -1.0 if randf() < 0.5 else 1.0
	var x := clampf(_x_koliani() + lado * afasta, _base.x - 420.0, _base.x + 420.0)
	_chao_cache = _chao_y(x)
	global_position = Vector2(x, _chao_cache - altura_voo)
	_encarar_koliani()


func _mudar(n: int) -> void:
	_forma = n
	Som.toca("chefe_cai", -4.0, 0.6)
	Som.toca("mudar_forma", -5.0, 0.5)
	_abanar_camera(12.0)
	dur_tel *= 0.88
	dur_exposto *= 0.92
	var p := CPUParticles2D.new()
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 48
	p.lifetime = 0.8
	p.spread = 180.0
	p.gravity = Vector2(0, 300)
	p.initial_velocity_min = 100.0
	p.initial_velocity_max = 360.0
	p.color = Color(0.8, 0.35, 1.0)
	add_sibling(p)
	p.get_tree().create_timer(1.4).timeout.connect(p.queue_free)
	if _sprite:
		var esc := 1.15 - 0.12 * (n - 1)  # encolhe a cada forma; F4 e' pequeno
		create_tween().tween_property(_sprite, "scale", Vector2(esc, esc), 0.5)
	if _corpo:
		_corpo.frame = clampi(n - 1, 0, 1)


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
			luz.energy = 1.8 if v else 0.14
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


func _cair_derrotado() -> void:
	_terminar_olho()
	super._cair_derrotado()


## --- utilitários --------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return _base.y + 40.0
	var de := Vector2(x, _base.y - 80.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 760.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else _base.y + 40.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)
