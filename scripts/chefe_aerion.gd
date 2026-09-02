class_name ChefeAerion
extends ChefeBase
## Região III / nível 12 -- Aerion, o Cavaleiro Alado da Torre dos Ventos.
## NUNCA pousa: paira sempre e desloca-se pelo ar.
##   * LANCAS   -- arremessa lanças aladas na direção da Koliani (leque de
##     5 na fase 2).
##   * TORNADO  -- larga tornados que correm pelo chão da arena: empurram
##     a Koliani (para cima + para o lado) e magoam ao contacto.
##   * INVESTIDA-- mergulha num arco a rasar o chão e volta a subir.
## Depois de LANCAS / INVESTIDA paira a recompor as asas (EXPOSTO -- o
## peito à mostra, dano a dobrar).
## Fase 2 (< 50% vida): três tornados, salvas de lanças em leque, mergulho
## duplo e mais rápido.

const LANCA_VEL := 240.0
## O Aerion não fica em cima da Koliani -- mantém este recuo lateral para ela
## ter espaço para ler os ataques e desviar.
const RECUO_LATERAL := 240.0

enum Fase { DORME, DECIDE, LANCAS_TEL, LANCAS, TORNADO_TEL, TORNADO, INVESTIDA_TEL, INVESTIDA, STOMP_TEL, STOMP, EXPOSTO }

@export var dist_deteta := 520.0
@export var altura_voo := 210.0
@export var dur_tel := 0.9
@export var dur_exposto := 2.0
## STOMP: de dois em dois ciclos o Aerion desce a pique, dá um pisão (duas
## ondas de choque rasteiras que se saltam) e FICA no chão, vulnerável,
## `dur_stomp` segundos -- a janela grande para lhe acertar.
@export var dur_stomp := 3.0
@export var stomp_vel := 1500.0
@export var dano_lanca := 9
@export var dano_tornado := 8
@export var dano_investida := 13
@export var dano_stomp := 14

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposto := false
var _ciclos := 0
var _vida_max := 400
var _chao_cache := 0.0
var _inv_de := Vector2.ZERO
var _inv_para := Vector2.ZERO
## Ponto onde a Koliani estava quando o telégrafo das LANCAS começou -- as
## lanças vão para AQUI, não para a posição actual, por isso correr durante
## o aviso desvia-as de verdade.
var _mira_lancas := Vector2.ZERO
var _stomp_x := 0.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 540)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_chao_cache = _chao_y(global_position.x)
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite:
		_sprite.position.y = sin(_pulso * 3.0) * 5.0
	if _nucleo and _exposto:
		var p := 1.0 + 0.18 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(global_position.x)
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_entrar_fase2()

	if _fase == Fase.DORME:
		# adormecido: fica junto à arena (paira ao de leve no sítio onde foi
		# posto), NÃO persegue a Koliani pelo nível fora
		global_position.x = lerpf(global_position.x, _origem.x, clampf(dt * 2.0, 0.0, 1.0))
		global_position.y = _chao_cache - altura_voo + sin(_pulso * 1.4) * 8.0
	elif _fase not in [Fase.INVESTIDA, Fase.STOMP_TEL, Fase.STOMP]:
		# em combate: paira ao LADO da Koliani, não em cima dela
		var kx := _x_koliani()
		var lado := signf(global_position.x - kx)
		if lado == 0.0:
			lado = 1.0
		var alvo := Vector2(kx + lado * RECUO_LATERAL, _chao_cache - altura_voo)
		global_position = global_position.lerp(alvo, clampf(dt * 1.4, 0.0, 1.0))
	_encarar_koliani()

	match _fase:
		Fase.DORME:
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			if _t >= 0.28:
				if _ciclos % 2 == 1:
					_ir(Fase.STOMP_TEL)   # pisão de dois em dois ciclos
				else:
					match (_ciclos / 2) % 3:
						0: _ir(Fase.LANCAS_TEL)
						1: _ir(Fase.TORNADO_TEL)
						_: _ir(Fase.INVESTIDA_TEL)
		Fase.LANCAS_TEL:
			if _t < dt:
				var kl := _obter_koliani()
				_mira_lancas = kl.global_position if kl else global_position + Vector2(_direcao * 220.0, 180.0)
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_lancas()
				_ir(Fase.LANCAS)
		Fase.LANCAS:
			if _t >= 0.5:
				_ir(Fase.EXPOSTO)
		Fase.TORNADO_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_tornados()
				_ir(Fase.TORNADO)
		Fase.TORNADO:
			if _t >= 0.5:
				_ir(Fase.DECIDE)
		Fase.INVESTIDA_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_inv_de = global_position
				var k := _obter_koliani()
				var kx := k.global_position.x if k else global_position.x
				_inv_para = Vector2(kx + signf(kx - global_position.x) * 200.0, _chao_cache - 40.0)
				Som.toca("investida", -6.0, 0.9)
				_ataque_forte = 0.5
				_ir(Fase.INVESTIDA)
		Fase.INVESTIDA:
			var f := clampf(_t / 0.5, 0.0, 1.0)
			var arco := -sin(f * PI) * 60.0
			global_position = _inv_de.lerp(_inv_para, f) + Vector2(0, arco)
			var k := _obter_koliani()
			if k and global_position.distance_to(k.global_position) <= 60.0:
				k.receber_dano(int(round(dano_investida * (1.1 if _fase2 else 1.0))), signf(k.global_position.x - global_position.x))
			if _t >= 0.5:
				_ir(Fase.EXPOSTO)   # sem mergulho duplo na fase 2
		Fase.STOMP_TEL:
			var kx3 := _x_koliani()
			global_position.x = lerpf(global_position.x, kx3, clampf(dt * 3.5, 0.0, 1.0))
			global_position.y = lerpf(global_position.y, _chao_cache - altura_voo - 20.0, clampf(dt * 3.5, 0.0, 1.0))
			_piscar(true)
			if _t >= dur_tel * 1.1:
				_piscar(false)
				_stomp_x = global_position.x
				Som.toca("investida", -5.0, 0.7)
				_ir(Fase.STOMP)
		Fase.STOMP:
			if not _exposto and global_position.y < _chao_cache - 46.0:
				global_position.x = _stomp_x
				global_position.y = minf(global_position.y + stomp_vel * dt, _chao_cache - 44.0)
			elif not _exposto:
				global_position = Vector2(_stomp_x, _chao_cache - 44.0)
				_stomp_impacto()
				_exposto = true
				_mostrar_nucleo(true)
				_t = 0.0
			else:
				global_position = Vector2(_stomp_x, _chao_cache - 44.0)
				if _t >= dur_stomp:
					_exposto = false
					_mostrar_nucleo(false)
					_ciclos += 1
					_ir(Fase.DECIDE)
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
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 420.0


## --- ataques ---------------------------------------------------------

func _lancas() -> void:
	Som.toca("gelo", -8.0, 1.3)
	# aponta para onde a Koliani ESTAVA no início do telégrafo -> correr
	# durante o aviso desvia mesmo
	var base := (_mira_lancas - global_position).normalized()
	if base.length() < 0.5:
		base = Vector2(_direcao, 0.4).normalized()
	var n := 4 if _fase2 else 3
	# leque largo: fica sempre um vão claro entre lanças para passar
	var esp := 0.30
	for i in n:
		_lanca(base.rotated((i - (n - 1) * 0.5) * esp))


func _lanca(dir: Vector2) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var l := Area2D.new()
	l.collision_layer = 0
	l.collision_mask = 2
	l.global_position = global_position + dir * 24.0
	pai.add_child(l)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(32, 8)
	forma.shape = rs
	l.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.85, 0.9, 1.0, 0.95)
	poly.polygon = PackedVector2Array([Vector2(-16, 0), Vector2(10, -4), Vector2(16, 0), Vector2(10, 4)])
	poly.rotation = dir.angle()
	l.add_child(poly)
	var dano := dano_lanca
	l.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(dano, signf(dir.x))
		l.queue_free())
	var t := l.create_tween()
	t.tween_property(l, "global_position", l.global_position + dir * 1500.0, 1500.0 / LANCA_VEL)
	t.tween_callback(l.queue_free)


func _tornados() -> void:
	Som.toca("grito", -7.0, 1.4)
	var pai := get_parent()
	if pai == null:
		return
	var n := 2 if _fase2 else 1
	for i in n:
		var lado := -1.0 if i % 2 == 0 else 1.0
		_tornado(lado, i * 0.35)


func _tornado(dir: float, atraso: float) -> void:
	var pai := get_parent()
	var x0 := _base_ou_koliani_x() - dir * 460.0
	var tor := Area2D.new()
	tor.collision_layer = 0
	tor.collision_mask = 2
	tor.monitoring = false
	tor.global_position = Vector2(x0, _chao_cache - 60.0)
	pai.add_child(tor)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(46, 120)
	forma.shape = rs
	tor.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.8, 0.88, 1.0, 0.5)
	poly.polygon = PackedVector2Array([Vector2(-8, 60), Vector2(-22, -60), Vector2(22, -60), Vector2(8, 60)])
	tor.add_child(poly)
	var dano := dano_tornado
	tor.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(dano, dir)
			if b.has_method("soprar_para_cima"):
				b.soprar_para_cima(650.0, 110.0))
	var t := tor.create_tween()
	t.tween_interval(atraso)
	t.tween_callback(func() -> void: tor.monitoring = true)
	t.tween_property(tor, "global_position:x", x0 + dir * 1200.0, 2.4)
	t.parallel().tween_method(func(v: float) -> void: poly.rotation = v, 0.0, TAU * 4.0, 2.4)
	t.tween_property(poly, "modulate:a", 0.0, 0.2)
	t.tween_callback(tor.queue_free)


## --- pisão (STOMP) -------------------------------------------------

func _stomp_impacto() -> void:
	Som.toca("chefe_cai", -3.0, 0.85)
	_abanar_camera(10.0)
	_onda_stomp(-1.0)
	_onda_stomp(1.0)


## Onda de choque rasteira que corre pelo chão a partir do ponto do pisão.
## Salta-se. Aparece dos dois lados.
func _onda_stomp(dir: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var o := Area2D.new()
	o.collision_layer = 0
	o.collision_mask = 2
	o.global_position = Vector2(_stomp_x + dir * 44.0, _chao_cache - 22.0)
	pai.add_child(o)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(56, 42)
	forma.shape = rs
	o.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.82, 0.9, 1.0, 0.6)
	poly.polygon = PackedVector2Array([Vector2(-28, 21), Vector2(-16, -21), Vector2(16, -21), Vector2(28, 21)])
	o.add_child(poly)
	var dano := dano_stomp
	o.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(dano, dir))
	var t := o.create_tween()
	t.tween_property(o, "global_position:x", _stomp_x + dir * 640.0, 0.55)
	t.parallel().tween_property(poly, "modulate:a", 0.0, 0.55)
	t.tween_callback(o.queue_free)


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -8.0, 0.7)
	_abanar_camera(7.0)
	dur_tel *= 0.9
	dur_exposto *= 0.95


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
	# leva SEMPRE dano. Exposto (janela EXPOSTO / pisão no chão) = a dobrar;
	# fora disso o manto espectral só abranda um pouco.
	var mult := 2.0 if _exposto else 0.85
	super.receber_dano(int(round(quantidade * mult)), dir_empurrao)
	if not _exposto and _sprite:
		_sprite.modulate = Color(1.2, 1.2, 1.35)
		create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.1)


## --- utilitários --------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _base_ou_koliani_x() -> float:
	return _x_koliani()


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
