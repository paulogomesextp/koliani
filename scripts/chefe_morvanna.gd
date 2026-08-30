class_name ChefeMorvanna
extends ChefeBase
## Região I / nível 02 -- Morvanna, a Bruxa do Pântano. Flutua sobre a água
## venenosa, longe do alcance da Koliani, e ataca de três formas:
##   * MÃOS   -- invoca mãos espectrais que telegrafam e irrompem sob os
##               pés da Koliani (dano ao toque).
##   * CLONES -- larga clones de lama que andam até à Koliani (herdam de
##               DemonioBase; pouca vida, desfazem-se sozinhos).
##   * APAGA  -- faz desaparecer metade das plataformas flutuantes por uns
##               segundos (a Koliani fica sem onde pisar sobre a água).
## Depois de cada ataque DESCE até ao nível das plataformas para "saborear"
## o medo (estado EXPOSTA): é a única janela em que leva dano -- e a dobrar.
## Fora disso o manto espectral absorve os golpes.
## Fase 2 (< 50% vida): telégrafos mais curtos, mais mãos, apaga mais tempo.

const CLONE := preload("res://scenes/actors/DemonioBase.tscn")

enum Fase { DORME, DECIDE, MAOS_TEL, MAOS, CLONES_TEL, CLONES, APAGA_TEL, APAGA, EXPOSTA }

@export var dist_deteta := 460.0
@export var altura_voo := 150.0
@export var altura_exposta := 26.0
@export var balanco := 12.0
@export var dur_tel := 0.62
@export var dur_maos := 0.7
@export var dur_apaga := 3.2
@export var dur_exposta := 1.5
@export var dano_mao := 18
@export var dano_clone := 14

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposta := false
var _ciclos := 0
var _alvo_y := 0.0
var _vida_max := 300

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 300)
	_vida_max = vida
	_alvo_y = _origem.y
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite:
		# baloiço de flutuação constante (some no chão, no EXPOSTA)
		var amp := balanco if not _exposta else balanco * 0.4
		_sprite.position.y = sin(_pulso * 2.2) * amp
	if _nucleo and _exposta:
		var p := 1.0 + 0.18 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_entrar_fase2()

	# glide suave até à altura-alvo do estado atual
	var y := global_position.y
	global_position.y = lerpf(y, _alvo_y, clampf(dt * 4.0, 0.0, 1.0))
	_encarar_koliani()

	match _fase:
		Fase.DORME:
			_alvo_y = _origem.y - altura_voo
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_alvo_y = _origem.y - altura_voo
			if _t >= 0.35:
				_escolher()
		Fase.MAOS_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_ir(Fase.MAOS)
		Fase.MAOS:
			if _t < dt:
				_lancar_maos()
			if _t >= dur_maos:
				_ir(Fase.EXPOSTA)
		Fase.CLONES_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_ir(Fase.CLONES)
		Fase.CLONES:
			if _t < dt:
				_largar_clones()
			if _t >= 0.5:
				_ir(Fase.EXPOSTA)
		Fase.APAGA_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_ir(Fase.APAGA)
		Fase.APAGA:
			if _t < dt:
				_apagar_plataformas()
			if _t >= 0.5:
				_ir(Fase.EXPOSTA)
		Fase.EXPOSTA:
			_alvo_y = _origem.y - altura_exposta
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
	# roda entre os três ataques; na fase 2 repete APAGA mais vezes
	var op := _ciclos % 3
	if _fase2 and _ciclos % 4 == 3:
		op = 2
	match op:
		0: _ir(Fase.MAOS_TEL)
		1: _ir(Fase.CLONES_TEL)
		_: _ir(Fase.APAGA_TEL)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta


## --- ataques ---------------------------------------------------------

func _lancar_maos() -> void:
	Som.toca("investida", -8.0, 1.5)
	_abanar_camera(3.0)
	var n := 3 if _fase2 else 2
	var alvo := _x_koliani()
	for i in n:
		var x := alvo + (i - (n - 1) * 0.5) * 96.0 + randf_range(-16.0, 16.0)
		_invocar_mao(x, 0.12 + i * 0.16)


func _invocar_mao(x: float, atraso: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var chao := _chao_y(x)
	var mao := Area2D.new()
	mao.collision_layer = 0
	mao.collision_mask = 2
	mao.global_position = Vector2(x, chao)
	mao.monitoring = false
	pai.add_child(mao)

	var forma := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(26, 66)
	forma.shape = rs
	forma.position = Vector2(0, -33)
	mao.add_child(forma)

	var garra := Polygon2D.new()
	garra.color = Color(0.12, 0.28, 0.22, 0.9)
	garra.polygon = PackedVector2Array([
		Vector2(-12, 0), Vector2(-9, -44), Vector2(-3, -30), Vector2(0, -58),
		Vector2(3, -30), Vector2(9, -44), Vector2(12, 0),
	])
	garra.scale.y = 0.0
	mao.add_child(garra)

	var racha := Polygon2D.new()
	racha.color = Color(0.5, 0.95, 0.7, 0.5)
	racha.polygon = PackedVector2Array([Vector2(-14, -1), Vector2(14, -1), Vector2(10, 2), Vector2(-10, 2)])
	mao.add_child(racha)

	var dano := int(round(dano_mao * (1.15 if _fase2 else 1.0)))
	var t := mao.create_tween()
	t.tween_property(racha, "modulate:a", 0.25, atraso * 0.5)
	t.tween_property(racha, "modulate:a", 1.0, atraso * 0.5)
	t.tween_callback(func() -> void: racha.visible = false)
	t.tween_callback(func() -> void: mao.monitoring = true)
	t.parallel().tween_property(garra, "scale:y", 1.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(func() -> void:
		for c in mao.get_overlapping_bodies():
			if c is Koliani:
				c.receber_dano(dano, signf(c.global_position.x - mao.global_position.x)))
	t.tween_interval(0.55)
	t.tween_callback(func() -> void: mao.monitoring = false)
	t.tween_property(garra, "scale:y", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(mao.queue_free)


func _largar_clones() -> void:
	Som.toca("demonio_ataque", -8.0, 0.7)
	var pai := get_parent()
	if pai == null:
		return
	var n := 2 if _fase2 else 1
	for i in n:
		var clone := CLONE.instantiate()
		clone.vida = 22
		clone.dano_contacto = dano_clone
		clone.velocidade = 74.0
		clone.alcance_patrulha = 260.0
		clone.cor_estilhacos = Color(0.3, 0.45, 0.28)
		clone.cor_rim = Color(0.45, 0.85, 0.55)
		var x := global_position.x + (i * 2 - 1) * 48.0
		clone.global_position = Vector2(x, _chao_y(x) - 20.0)
		pai.add_child(clone)
		# rede de segurança: não fica para sempre
		clone.get_tree().create_timer(9.0).timeout.connect(func() -> void:
			if is_instance_valid(clone) and not clone._morto:
				clone.soltar_estilhacos()
				clone.queue_free())


func _apagar_plataformas() -> void:
	Som.toca("onda", -7.0, 0.9)
	_abanar_camera(4.0)
	var plats := get_tree().get_nodes_in_group("plataformas_flutuantes")
	var segundos := dur_apaga * (1.4 if _fase2 else 1.0)
	for i in plats.size():
		# apaga uma sim, uma não -- sobra sempre onde pisar, mas mal
		if i % 2 == 0 and plats[i].has_method("desvanecer"):
			plats[i].desvanecer(segundos)


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -9.0, 0.7)
	_abanar_camera(6.0)
	dur_tel *= 0.7
	dur_exposta *= 0.85


## --- núcleo / dano -------------------------------------------------

func _mostrar_nucleo(v: bool) -> void:
	if _nucleo == null:
		return
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
		# manto espectral -- o golpe não passa
		Som.toca("bloqueio", -9.0, 0.8)
		if _sprite:
			_sprite.modulate = Color(0.6, 0.8, 0.7)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao)


## --- utilitários --------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _chao_y(x: float) -> float:
	var espaco := get_world_2d().direct_space_state
	var de := Vector2(x, _origem.y - 40.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 420.0), 1)
	q.exclude = [self]
	var hit := espaco.intersect_ray(q)
	return (hit["position"].y as float) if hit else _origem.y + 40.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)
