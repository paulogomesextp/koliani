class_name ChefeGhorak
extends ChefeBase
## Regiao I / nivel 01 -- Ghorak, o Guardiao Raiz. Guerreiro de tronco,
## ossos e raizes. Dois ataques:
##   * ESMAGA -- ergue-se, baixa com um baque -> onda rasteira (so magoa
##     quem esta no chao ao alcance) + uma raiz irrompe sob os pes da
##     Koliani.
##   * SEMEIA -- planta uma fila de raizes a varrer o chao ate a Koliani.
## A seguir a qualquer ataque fica EXPOSTO por um instante: o nucleo purpura
## do peito abre-se e SO nessa janela e' que leva dano (a dobrar). Fora
## disso, a casca de raiz e osso aguenta os golpes.
## A meio da vida entra em fase 2: telegrafos mais curtos, mais raizes, e a
## arena e' tomada por raizes de fundo.

const RAIZ := preload("res://scenes/actors/RaizPerigo.tscn")

enum Fase { DORME, DECIDE, ESMAGA_TEL, ESMAGA_BAQUE, SEMEIA, EXPOSTO }

@export var dist_deteta := 380.0
@export var vel_passo := 34.0
@export var dur_tel := 0.6
@export var dur_baque := 0.32
@export var dur_semeia := 0.66
@export var dur_exposto := 1.3
@export var raio_onda := 300.0
@export var dano_onda := 22
@export var dano_raiz := 18

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _onda_feita := false
var _fase2 := false
var _nucleo_exposto := false
var _ciclos := 0
var _vida_max := 420

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 250)
	_vida_max = vida
	velocidade = vel_passo
	alcance_patrulha = maxf(alcance_patrulha, 120.0)
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	if _nucleo and _nucleo_exposto:
		_pulso += dt
		var p := 1.0 + 0.16 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_entrar_fase2()

	match _fase:
		Fase.DORME:
			super._physics_process(dt)  # patrulha lenta (DemonioBase)
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_travar(dt)
			_encarar_koliani()
			if _t >= 0.22:
				_escolher()
		Fase.ESMAGA_TEL:
			_travar(dt)
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				velocity.y = -240.0  # pequeno salto antes do baque
				Som.toca("investida", -10.0, 0.8)
				_ir(Fase.ESMAGA_BAQUE)
		Fase.ESMAGA_BAQUE:
			velocity.x = move_toward(velocity.x, 0.0, 1400.0 * dt)
			if not is_on_floor():
				velocity.y += GRAVIDADE * dt
			move_and_slide()
			if is_on_floor() and _t > 0.06 and not _onda_feita:
				_onda_feita = true
				_baque()
			if _onda_feita and _t >= dur_baque:
				_ir(Fase.EXPOSTO)
		Fase.SEMEIA:
			_travar(dt)
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_semeia:
				_piscar(false)
				_semear()
				_ir(Fase.EXPOSTO)
		Fase.EXPOSTO:
			_travar(dt)
			if not _nucleo_exposto:
				_mostrar_nucleo(true)
			if _t >= dur_exposto:
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.DECIDE)
	_t += dt


## --- maquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0
	_onda_feita = false


func _escolher() -> void:
	var dx := absf(_vetor_para_koliani().x)
	# perto -> esmaga; longe -> semeia. Na fase 2 alterna para variar.
	var esmaga := dx <= raio_onda * 0.75
	if _fase2 and _ciclos % 2 == 1:
		esmaga = not esmaga
	_ir(Fase.ESMAGA_TEL if esmaga else Fase.SEMEIA)


func _travar(dt: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1000.0 * dt)
	if not is_on_floor():
		velocity.y += GRAVIDADE * dt
	move_and_slide()


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 220.0


## --- ataques ---------------------------------------------------------

func _baque() -> void:
	Som.toca("esmagar", -5.0)
	_abanar_camera(5.0)
	var k := _obter_koliani()
	if k and absf((k.global_position - global_position).x) <= raio_onda and k.is_on_floor():
		k.receber_dano(dano_onda, signf(k.global_position.x - global_position.x))
	_particulas_onda()
	_plantar_em(_x_koliani(), 0.28)
	if _fase2:
		_plantar_em(_x_koliani() + signf(_dir_para_koliani()) * 96.0, 0.44)


func _semear() -> void:
	Som.toca("praga", -8.0)
	var origem := global_position.x
	var alvo := _x_koliani() + signf(_x_koliani() - origem) * 44.0
	var passos := 5 if _fase2 else 4
	for i in passos:
		var f := float(i) / float(passos - 1)
		_plantar_em(lerpf(origem, alvo, f), 0.12 + f * 0.5)


func _plantar_em(x: float, atraso: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var r := RAIZ.instantiate()
	pai.add_child(r)
	r.global_position = Vector2(x, _chao_y(x))
	r.avisar(int(round(dano_raiz * (1.15 if _fase2 else 1.0))), atraso)


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -9.0, 0.7)  # rugido grave
	_abanar_camera(7.0)
	dur_tel *= 0.7
	dur_semeia *= 0.7
	dur_exposto *= 0.82
	velocidade = vel_passo * 1.25
	_raizes_de_fundo()


func _raizes_de_fundo() -> void:
	var pai := get_parent()
	if pai == null:
		return
	for i in 7:
		var x := global_position.x - 700.0 + i * 200.0 + randf_range(-40.0, 40.0)
		var raiz := Polygon2D.new()
		raiz.color = Color(0.06, 0.1, 0.04, 0.92)
		var h := randf_range(130.0, 250.0)
		raiz.polygon = PackedVector2Array([
			Vector2(-14, 0), Vector2(-6, -h * 0.5), Vector2(-9, -h * 0.8),
			Vector2(0, -h), Vector2(8, -h * 0.75), Vector2(6, -h * 0.4), Vector2(15, 0),
		])
		raiz.global_position = Vector2(x, _chao_y(x))
		raiz.z_index = -5
		raiz.scale.y = 0.0
		pai.add_child(raiz)
		var t := raiz.create_tween()
		t.tween_interval(i * 0.05)
		t.tween_property(raiz, "scale:y", 1.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## --- nucleo / dano -------------------------------------------------

## Telegrafo -> frame 2 (bracos erguidos) da tira pixel-art.
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
	_nucleo.scale = Vector2.ONE * (1.0 if v else 0.5)
	var luz: PointLight2D = _nucleo.get_node_or_null("Luz")
	if luz:
		luz.energy = 1.6 if v else 0.15
	var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
	if brilho:
		brilho.visible = v


func receber_dano(quantidade: int, dir_empurrao: float = 0.0, critico := false) -> void:
	if _ja_derrotado:
		return
	provocar()
	if not _nucleo_exposto:
		# casca de raiz e osso -- o golpe nao passa
		Som.toca("bloqueio", -9.0, 0.65)
		global_position.x += dir_empurrao * 1.0
		if _sprite:
			_sprite.modulate = Color(0.62, 0.72, 0.6)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		return
	# nucleo a' vista -> dano a dobrar (recompensa a paciencia)
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao, critico)


## --- utilitarios --------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _chao_y(x: float) -> float:
	var espaco := get_world_2d().direct_space_state
	var de := Vector2(x, global_position.y - 60.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 280.0), 1)
	q.exclude = [self]
	var hit := espaco.intersect_ray(q)
	return (hit["position"].y as float) if hit else global_position.y + 34.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)


func _particulas_onda() -> void:
	var p := CPUParticles2D.new()
	p.global_position = global_position + Vector2(0, 30)
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 28
	p.lifetime = 0.55
	p.direction = Vector2(1, -0.15)
	p.spread = 22.0
	p.gravity = Vector2(0, 900)
	p.initial_velocity_min = 160.0
	p.initial_velocity_max = 360.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color = Color(0.4, 0.6, 0.28)
	add_sibling(p)
	p.get_tree().create_timer(1.0).timeout.connect(p.queue_free)
