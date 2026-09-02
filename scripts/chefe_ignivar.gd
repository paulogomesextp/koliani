class_name ChefeIgnivar
extends ChefeBase
## Região II / nível 07 -- Ignivar, o Ferreiro Maldito. Um gigante de ferro
## e escória com um braço em martelo e um núcleo de forja no peito. Fica
## junto à bigorna e alterna três ataques:
##   * MARTELO -- ergue o braço e baixa-o com um baque: onda de choque
##     rasteira (só magoa a Koliani no chão ao alcance) -- salta por cima.
##   * FORJA   -- malha na bigorna e atira uma lâmina em brasa na horizontal.
##   * BRASAS  -- lança brasas que sobem e chovem sobre a Koliani (reutiliza
##     `GotaAcida` recolorida a laranja: gota + poça que magoa).
## A seguir a cada ataque volta-se para a forja: a fenda das costas abre-se
## (EXPOSTO) -- única janela de dano, a dobrar.
## Fase 2 (< 50% vida): "derrete a arena" -- alarga as poças de lava do
## grupo "lava_fornalha", telégrafos mais curtos, mais brasas.

const BRASA := preload("res://scenes/actors/GotaAcida.tscn")

enum Fase { DORME, DECIDE, MARTELO_TEL, MARTELO_BAQUE, FORJA_TEL, FORJA, BRASAS_TEL, BRASAS, EXPOSTO }

@export var dist_deteta := 440.0
@export var dur_tel := 0.6
@export var dur_baque := 0.34
@export var dur_exposto := 1.35
@export var raio_onda := 300.0
@export var dano_onda := 22
@export var dano_lamina := 16
@export var dano_brasa := 16
@export var vel_lamina := 460.0

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _onda_feita := false
var _fase2 := false
var _nucleo_exposto := false
var _ciclos := 0
var _vida_max := 440
var _chao_cache := 0.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 400)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	if _nucleo and _nucleo_exposto:
		_pulso += dt
		var p := 1.0 + 0.16 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(global_position.x)
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_entrar_fase2()

	match _fase:
		Fase.DORME:
			if not is_on_floor():
				velocity.y += GRAVIDADE * dt
				move_and_slide()
			if _ve_koliani():
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_encarar_koliani()
			if _t >= 0.25:
				_escolher()
		Fase.MARTELO_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				velocity.y = -220.0
				Som.toca("investida", -9.0, 0.7)
				_ir(Fase.MARTELO_BAQUE)
		Fase.MARTELO_BAQUE:
			velocity.x = 0.0
			if not is_on_floor():
				velocity.y += GRAVIDADE * dt
			move_and_slide()
			if is_on_floor() and _t > 0.06 and not _onda_feita:
				_onda_feita = true
				_baque()
			if _onda_feita and _t >= dur_baque:
				_ir(Fase.EXPOSTO)
		Fase.FORJA_TEL:
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_forjar_lamina()
				_ir(Fase.FORJA)
		Fase.FORJA:
			if _t >= 0.4:
				_ir(Fase.EXPOSTO)
		Fase.BRASAS_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_lancar_brasas()
				_ir(Fase.BRASAS)
		Fase.BRASAS:
			if _t >= 0.5:
				_ir(Fase.EXPOSTO)
		Fase.EXPOSTO:
			velocity.x = 0.0
			if not is_on_floor():
				velocity.y += GRAVIDADE * dt
				move_and_slide()
			if not _nucleo_exposto:
				_mostrar_nucleo(true)
			if _t >= dur_exposto:
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.DECIDE)
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0
	_onda_feita = false


func _escolher() -> void:
	var dx := absf(_vetor_para_koliani().x)
	# perto -> martelo; a meia distância -> lâmina; a cada 3.º ciclo -> brasas
	if _ciclos % 3 == 2:
		_ir(Fase.BRASAS_TEL)
	elif dx <= raio_onda * 0.7:
		_ir(Fase.MARTELO_TEL)
	else:
		_ir(Fase.FORJA_TEL)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 260.0


## --- ataques ---------------------------------------------------------

func _baque() -> void:
	Som.toca("esmagar", -5.0)
	_abanar_camera(5.0)
	var k := _obter_koliani()
	if k and absf(_vetor_para_koliani().x) <= raio_onda and k.is_on_floor():
		k.receber_dano(int(round(dano_onda * (1.15 if _fase2 else 1.0))), _dir_para_koliani())
	_particulas_onda()


func _forjar_lamina() -> void:
	var pai := get_parent()
	if pai == null:
		return
	Som.toca("chama", -8.0, 1.4)
	var dir := _dir_para_koliani()
	var lamina := Area2D.new()
	lamina.collision_layer = 0
	lamina.collision_mask = 2
	lamina.global_position = global_position + Vector2(dir * 42.0, -18.0)
	pai.add_child(lamina)

	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(34, 12)
	forma.shape = rs
	lamina.add_child(forma)

	var poly := Polygon2D.new()
	poly.color = Color(1.0, 0.5, 0.12, 1.0)
	poly.polygon = PackedVector2Array([Vector2(-17, 0), Vector2(6, -6), Vector2(17, 0), Vector2(6, 6)])
	poly.scale.x = dir
	lamina.add_child(poly)

	var luz := PointLight2D.new()
	luz.texture = _tex_luz()
	luz.energy = 0.7
	luz.color = Color(1.0, 0.55, 0.2)
	luz.scale = Vector2(0.5, 0.4)
	lamina.add_child(luz)

	var dano := int(round(dano_lamina * (1.15 if _fase2 else 1.0)))
	lamina.body_entered.connect(func(corpo: Node) -> void:
		if corpo is Koliani:
			corpo.receber_dano(dano, dir))

	var t := lamina.create_tween()
	t.tween_property(lamina, "global_position:x", global_position.x + dir * 1400.0, 1400.0 / vel_lamina)
	t.parallel().tween_method(func(v: float) -> void: poly.rotation = v, 0.0, TAU * 6.0, 1400.0 / vel_lamina)
	t.tween_callback(lamina.queue_free)


func _lancar_brasas() -> void:
	Som.toca("chama", -9.0, 0.8)
	var pai := get_parent()
	if pai == null:
		return
	var n := 5 if _fase2 else 3
	var alvo := _x_koliani()
	for i in n:
		var x := alvo + (i - (n - 1) * 0.5) * 88.0 + randf_range(-16.0, 16.0)
		var g := BRASA.instantiate()
		g.automatico = false
		g.dano = dano_brasa
		g.cor = Color(1.0, 0.55, 0.18, 1.0)
		g.global_position = Vector2(x, _chao_cache - 200.0)
		pai.add_child(g)
		g.cair(0.12 + i * 0.12)


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -9.0, 0.7)
	_abanar_camera(7.0)
	dur_tel *= 0.72
	dur_exposto *= 0.85
	# "derrete a arena": a lava do grupo "lava_fornalha" SOBE até ao nível
	# do chão e alarga -- fica perigosa mesmo por baixo dos pés.
	for p in get_tree().get_nodes_in_group("lava_fornalha"):
		if not is_instance_valid(p):
			continue
		var tw := (p as Node).create_tween()
		tw.tween_property(p, "position:y", (p as Node2D).position.y - 175.0, 1.4) \
			.set_trans(Tween.TRANS_SINE)
		if "largura" in p:
			p.largura = p.largura * 1.35


## --- núcleo / dano -------------------------------------------------

func _piscar(ligado: bool) -> void:
	super._piscar(ligado)
	if _corpo and not _nucleo_exposto:
		_corpo.frame = 2 if ligado else 0


func _mostrar_nucleo(v: bool) -> void:
	_nucleo_exposto = v
	_pulso = 0.0
	if _corpo:
		_corpo.frame = 3 if v else 0
	if _nucleo == null:
		return
	_nucleo.scale = Vector2.ONE * (1.0 if v else 0.4)
	var luz: PointLight2D = _nucleo.get_node_or_null("Luz")
	if luz:
		luz.energy = 1.6 if v else 0.14
	var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
	if brilho:
		brilho.visible = v


func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false) -> void:
	if _ja_derrotado:
		return
	provocar()
	if not _nucleo_exposto:
		Som.toca("bloqueio", -9.0, 0.6)
		if _sprite:
			_sprite.modulate = Color(0.75, 0.7, 0.6)
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
		return global_position.y + 40.0
	var de := Vector2(x, global_position.y - 40.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 420.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else global_position.y + 40.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)


func _particulas_onda() -> void:
	var p := CPUParticles2D.new()
	p.global_position = global_position + Vector2(0, 34)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 26
	p.lifetime = 0.5
	p.direction = Vector2(_dir_para_koliani(), -0.2)
	p.spread = 26.0
	p.gravity = Vector2(0, 900)
	p.initial_velocity_min = 160.0
	p.initial_velocity_max = 360.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color = Color(1.0, 0.55, 0.2)
	add_sibling(p)
	p.get_tree().create_timer(1.0).timeout.connect(p.queue_free)


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
