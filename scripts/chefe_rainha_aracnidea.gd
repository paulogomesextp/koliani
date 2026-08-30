class_name ChefeRainhaAracnidea
extends ChefeBase
## Região I / nível 03 -- A Rainha Aracnídea. Aranha colossal com rosto
## humano. Anda pesado pela arena e alterna três ataques:
##   * CUSPIR    -- lança uma mancha de teia (`TeiaPrende`) onde a Koliani
##                  está: quem lá pisar fica preso uns segundos.
##   * OVOS      -- larga ovos que eclodem em aranhas pequenas (herdam de
##                  DemonioBase; pouca vida).
##   * INVESTIDA -- telegrafa e arremete na horizontal contra a Koliani.
## Depois de cada ataque o **rosto humano** (nó `Nucleo`) abre-se: só nessa
## janela EXPOSTA é que leva dano (a dobrar). Fora disso a carapaça aguenta.
## Fase 2 (< 50% vida): telégrafos mais curtos, mais ovos, e parte um par de
## plataformas da arena (grupo "plataformas_ninho").

const ARANHA := preload("res://scenes/actors/DemonioBase.tscn")
const TEIA := preload("res://scenes/actors/TeiaPrende.tscn")

enum Fase { DORME, DECIDE, CUSPIR_TEL, CUSPIR, OVOS_TEL, OVOS, INVESTIDA_TEL, INVESTIDA, EXPOSTA }

@export var dist_deteta := 420.0
@export var vel_passo := 40.0
@export var vel_investida := 380.0
@export var dur_tel := 0.6
@export var dur_investida := 0.5
@export var dur_exposta := 1.4
@export var dur_preso_teia := 0.8

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _nucleo_exposto := false
var _ciclos := 0
var _vida_max := 380

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 380)
	_vida_max = vida
	velocidade = vel_passo
	alcance_patrulha = maxf(alcance_patrulha, 140.0)
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	if _nucleo and _nucleo_exposto:
		_pulso += dt
		var p := 1.0 + 0.16 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_entrar_fase2()

	match _fase:
		Fase.DORME:
			super._physics_process(dt)  # patrulha (DemonioBase)
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			_travar(dt)
			_encarar_koliani()
			if _t >= 0.25:
				_escolher()
		Fase.CUSPIR_TEL:
			_travar(dt)
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_cuspir()
				_ir(Fase.EXPOSTA)
		Fase.OVOS_TEL:
			_travar(dt)
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_por_ovos()
				_ir(Fase.EXPOSTA)
		Fase.INVESTIDA_TEL:
			_travar(dt)
			_encarar_koliani()
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				velocity.x = _dir_para_koliani() * vel_investida
				_ataque_forte = dur_investida + 0.2
				Som.toca("investida", -8.0)
				_ir(Fase.INVESTIDA)
		Fase.INVESTIDA:
			velocity.x = move_toward(velocity.x, 0.0, 520.0 * dt)
			if not is_on_floor():
				velocity.y += GRAVIDADE * dt
			move_and_slide()
			if is_on_wall() or _t >= dur_investida:
				_ir(Fase.EXPOSTA)
		Fase.EXPOSTA:
			_travar(dt)
			if not _nucleo_exposto:
				_mostrar_nucleo(true)
			if _t >= dur_exposta:
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.DECIDE)
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


func _escolher() -> void:
	var dx := absf(_vetor_para_koliani().x)
	# perto -> investida; médio -> cuspir; a alternar com ovos
	if _ciclos % 3 == 2:
		_ir(Fase.OVOS_TEL)
	elif dx <= 220.0:
		_ir(Fase.INVESTIDA_TEL)
	else:
		_ir(Fase.CUSPIR_TEL)


func _travar(dt: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * dt)
	if not is_on_floor():
		velocity.y += GRAVIDADE * dt
	move_and_slide()


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 240.0


## --- ataques ---------------------------------------------------------

func _cuspir() -> void:
	Som.toca("projetil", -8.0, 0.7)
	var pai := get_parent()
	if pai == null:
		return
	var x := _x_koliani()
	var teia := TEIA.instantiate()
	pai.add_child(teia)
	teia.global_position = Vector2(x, _chao_y(x))
	teia.largura = 130.0
	teia.lancar(0.35, dur_preso_teia * (1.2 if _fase2 else 1.0))


func _por_ovos() -> void:
	Som.toca("demonio_ataque", -9.0, 0.7)
	var pai := get_parent()
	if pai == null:
		return
	var n := 3 if _fase2 else 2
	for i in n:
		var x := global_position.x + (i - (n - 1) * 0.5) * 84.0
		_ovo_em(x, 0.7 + i * 0.15)


func _ovo_em(x: float, eclosao: float) -> void:
	var pai := get_parent()
	if pai == null:
		return
	var ovo := Polygon2D.new()
	ovo.color = Color(0.86, 0.84, 0.7, 0.95)
	ovo.polygon = PackedVector2Array([Vector2(-9, 4), Vector2(-7, -8), Vector2(0, -14), Vector2(7, -8), Vector2(9, 4), Vector2(0, 10)])
	ovo.global_position = Vector2(x, _chao_y(x) - 8.0)
	pai.add_child(ovo)
	var t := ovo.create_tween()
	var abanoes := maxi(1, int(round(eclosao / 0.4)))
	for _i in abanoes:
		t.tween_property(ovo, "scale", Vector2(1.25, 0.85), 0.2).set_trans(Tween.TRANS_SINE)
		t.tween_property(ovo, "scale", Vector2(0.9, 1.15), 0.2).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func() -> void:
		if not is_instance_valid(ovo):
			return
		var aranha := ARANHA.instantiate()
		aranha.vida = 16
		aranha.dano_contacto = 12
		aranha.velocidade = 88.0
		aranha.alcance_patrulha = 240.0
		aranha.cor_estilhacos = Color(0.2, 0.18, 0.24)
		aranha.cor_rim = Color(0.8, 0.85, 0.95)
		aranha.scale = Vector2(0.62, 0.62)
		aranha.global_position = ovo.global_position
		pai.add_child(aranha)
		ovo.queue_free())


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -9.0, 0.7)
	_abanar_camera(7.0)
	dur_tel *= 0.7
	dur_exposta *= 0.85
	velocidade = vel_passo * 1.2
	# parte um par de plataformas da arena
	var plats := get_tree().get_nodes_in_group("plataformas_ninho")
	for i in plats.size():
		if i % 2 == 0 and is_instance_valid(plats[i]):
			var p: Node = plats[i]
			var tw := p.create_tween()
			tw.tween_property(p, "modulate:a", 0.0, 0.4)
			tw.tween_callback(p.queue_free)


## --- núcleo / dano -------------------------------------------------

## Telegrafo -> frame 2 (patas da frente erguidas) da tira pixel-art.
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
		luz.energy = 1.6 if v else 0.12
	var brilho: CanvasItem = _nucleo.get_node_or_null("Brilho")
	if brilho:
		brilho.visible = v


func receber_dano(quantidade: int, dir_empurrao: float = 0.0) -> void:
	if _ja_derrotado:
		return
	provocar()
	if not _nucleo_exposto:
		Som.toca("bloqueio", -9.0, 0.65)
		global_position.x += dir_empurrao * 1.0
		if _sprite:
			_sprite.modulate = Color(0.7, 0.68, 0.75)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.12)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao)


## --- utilitários --------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _chao_y(x: float) -> float:
	var espaco := get_world_2d().direct_space_state
	var de := Vector2(x, global_position.y - 60.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 300.0), 1)
	q.exclude = [self]
	var hit := espaco.intersect_ray(q)
	return (hit["position"].y as float) if hit else global_position.y + 40.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)
