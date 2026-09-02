class_name ChefeMaquinistaInfernal
extends ChefeBase
## Região V / nível 23 -- O Maquinista Infernal. Luta no último vagão do
## Trem dos Mortos. Atarracado, pá de carvão, uma fornalha às costas:
##   * PA      -- varre a pá (arco corpo-a-corpo) e atira brasas (GotaAcida
##     recolorida de laranja).
##   * VAPOR   -- venta um jacto de vapor rente ao vagão (faixa de dano
##     telegrafada).
##   * APITO   -- silvo: pequena onda + levanta dois guarda-freios
##     (DemonioBase).
## Depois de PA / VAPOR baixa-se a atear a fornalha (EXPOSTO -- o núcleo
## das costas à mostra, dano a dobrar).
## Fase 2 (< 50% vida): "o próprio trem ataca" -- chuva de brasas do fumeiro
## e os vagões do grupo "vagoes_trem" sacodem; tudo mais rápido.

const BRASA := preload("res://scenes/actors/GotaAcida.tscn")
const GUARDA := preload("res://scenes/actors/DemonioBase.tscn")

enum Fase { DORME, DECIDE, PA_TEL, PA, VAPOR_TEL, VAPOR, APITO_TEL, APITO, EXPOSTO }

@export var dist_deteta := 540.0
@export var dur_tel := 0.6
@export var dur_exposto := 1.5
@export var dano_pa := 20
@export var dano_brasa := 14
@export var dano_vapor := 16

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposto := false
var _ciclos := 0
var _vida_max := 500
var _chao_cache := 0.0
var _brasas_acc := 0.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 720)
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
	if _fase2:
		_brasas_acc += dt
		if _brasas_acc >= 0.7:
			_brasas_acc = 0.0
			_brasa_do_fumeiro()

	match _fase:
		Fase.DORME:
			_encarar_koliani()
			if _ve_koliani():
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_encarar_koliani()
			if _t >= 0.3:
				match _ciclos % 3:
					0: _ir(Fase.PA_TEL)
					1: _ir(Fase.VAPOR_TEL)
					_: _ir(Fase.APITO_TEL)
		Fase.PA_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_pa_de_carvao()
				_ir(Fase.PA)
		Fase.PA:
			if _t >= 0.45:
				_ir(Fase.EXPOSTO)
		Fase.VAPOR_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_vapor()
				_ir(Fase.VAPOR)
		Fase.VAPOR:
			if _t >= 0.6:
				_ir(Fase.EXPOSTO)
		Fase.APITO_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_apito()
				_ir(Fase.APITO)
		Fase.APITO:
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
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 300.0


## --- ataques ---------------------------------------------------------

func _pa_de_carvao() -> void:
	Som.toca("engrenagem", -6.0, 0.8)
	var dir := _dir_para_koliani()
	# arco corpo-a-corpo
	var k := _obter_koliani()
	if k:
		var d := _vetor_para_koliani()
		if absf(d.x) <= 100.0 and absf(d.y) <= 74.0 and signf(d.x) == dir:
			k.receber_dano(int(round(dano_pa * (1.1 if _fase2 else 1.0))), dir)
	# brasas
	var pai := get_parent()
	if pai == null:
		return
	var n := 4 if _fase2 else 3
	var alvo := (k.global_position.x if k else global_position.x)
	for i in n:
		var x := alvo + (i - (n - 1) * 0.5) * 90.0 + randf_range(-14.0, 14.0)
		var g := BRASA.instantiate()
		g.automatico = false
		g.dano = dano_brasa
		g.cor = Color(1.0, 0.55, 0.18, 1.0)
		g.global_position = Vector2(x, _chao_cache - 220.0)
		pai.add_child(g)
		g.cair(0.12 + i * 0.1)


func _vapor() -> void:
	Som.toca("engrenagem", -6.0, 1.4)
	var pai := get_parent()
	if pai == null:
		return
	var dir := _dir_para_koliani()
	var v := Area2D.new()
	v.collision_layer = 0
	v.collision_mask = 2
	v.monitoring = false
	v.global_position = global_position + Vector2(dir * 40.0, -24.0)
	pai.add_child(v)
	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(30, 40)
	forma.shape = rs
	v.add_child(forma)
	var poly := Polygon2D.new()
	poly.color = Color(0.9, 0.9, 0.95, 0.5)
	poly.polygon = PackedVector2Array([Vector2(-15, 20), Vector2(-10, -20), Vector2(12, -16), Vector2(16, 22)])
	v.add_child(poly)
	var dano := int(round(dano_vapor * (1.1 if _fase2 else 1.0)))
	v.body_entered.connect(func(b: Node) -> void:
		if b is Koliani:
			b.receber_dano(dano, dir))
	var t := v.create_tween()
	t.tween_callback(func() -> void: v.monitoring = true)
	t.tween_property(v, "global_position:x", global_position.x + dir * 600.0, 0.9)
	t.parallel().tween_property(v, "scale", Vector2(2.4, 1.5), 0.9)
	t.parallel().tween_property(poly, "modulate:a", 0.0, 0.9)
	t.tween_callback(v.queue_free)


func _apito() -> void:
	Som.toca("selo", -4.0, 0.4)
	_abanar_camera(5.0)
	var k := _obter_koliani()
	if k and absf(_vetor_para_koliani().x) <= 220.0:
		k.receber_dano(8, _dir_para_koliani())
	var pai := get_parent()
	if pai == null:
		return
	for i in 2:
		var g := GUARDA.instantiate()
		g.especie = "goblin"
		g.vida = 24
		g.dano_contacto = 14
		g.velocidade = 90.0
		g.alcance_patrulha = 320.0
		var x := global_position.x + (i * 2 - 1) * 70.0
		g.global_position = Vector2(x, _chao_y(x) - 20.0)
		pai.add_child(g)
		g.get_tree().create_timer(10.0).timeout.connect(func() -> void:
			if is_instance_valid(g) and not g._morto:
				g.soltar_estilhacos()
				g.queue_free())


func _brasa_do_fumeiro() -> void:
	var pai := get_parent()
	if pai == null:
		return
	var k := _obter_koliani()
	var x := (k.global_position.x if k else global_position.x) + randf_range(-200.0, 200.0)
	var g := BRASA.instantiate()
	g.automatico = false
	g.dano = dano_brasa
	g.cor = Color(1.0, 0.5, 0.15, 1.0)
	g.global_position = Vector2(x, _chao_cache - 260.0)
	pai.add_child(g)
	g.cair(0.15)


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -8.0, 0.7)
	_abanar_camera(8.0)
	dur_tel *= 0.78
	dur_exposto *= 0.85
	# "o proprio trem ataca": os vagoes sacodem
	for v in get_tree().get_nodes_in_group("vagoes_trem"):
		if not is_instance_valid(v):
			continue
		var tw := (v as Node).create_tween().set_loops(0)
		tw.tween_property(v, "position:y", (v as Node2D).position.y + 6.0, 0.12)
		tw.tween_property(v, "position:y", (v as Node2D).position.y - 6.0, 0.12)


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


func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false) -> void:
	if _ja_derrotado:
		return
	provocar()
	if not _exposto:
		Som.toca("bloqueio", -9.0, 0.5)
		if _sprite:
			_sprite.modulate = Color(1.2, 1.1, 1.0)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao, critico)


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
