class_name ChefeVoltaris
extends ChefeBase
## Região III / nível 13 -- Voltaris, o Mago Morto-Vivo da Torre da
## Tempestade. Não se aproxima: TELEPORTA-SE entre pontos altos da arena
## (lampejo + trovão) e ataca de longe:
##   * RAIOS   -- invoca `RaioTempestade` num padrão previsível sobre a
##     Koliani (fase 2: mais colunas, mais juntas).
##   * CLONES  -- larga clones elétricos (DemonioBase rápido, pouca vida,
##     tom ciano, vida curta).
## Depois de cada ataque fica a recarregar o cajado (EXPOSTO): o orbe do
## cajado abre-se -- janela de dano, a dobrar.
##
## O TRUQUE do nível: armar um `ParaRaios` (bater-lhe) e deixar uma
## descarga cair perto dele -- o pára-raios devolve a carga a Voltaris,
## que leva dano MESMO com a guarda fechada e fica atordoado (EXPOSTO).
## Fase 2 (< 50% vida): teleporta mais, padrões mais densos, mais clones.

const RAIO := preload("res://scenes/actors/RaioTempestade.tscn")
const CLONE := preload("res://scenes/actors/DemonioBase.tscn")

enum Fase { DORME, DECIDE, SOME, SURGE, RAIOS_TEL, RAIOS, CLONES_TEL, CLONES, EXPOSTO }

@export var dist_deteta := 640.0
@export var altura_voo := 190.0
@export var dur_tel := 0.55
@export var dur_exposto := 1.5
@export var alcance_x := 380.0

var _fase: Fase = Fase.DORME
var _t := 0.0
var _pulso := 0.0
var _fase2 := false
var _exposto := false
var _ciclos := 0
var _vida_max := 380
var _chao_cache := 0.0
var _prox: Fase = Fase.RAIOS_TEL
var _stagger := 0.0

@onready var _nucleo: Node2D = get_node_or_null("Sprite/Nucleo")


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 510)
	_vida_max = vida
	velocidade = 0.0
	alcance_patrulha = 0.0
	_mostrar_nucleo(false)


func _process(dt: float) -> void:
	super._process(dt)
	_pulso += dt
	if _sprite:
		_sprite.position.y = sin(_pulso * 2.5) * (5.0 if not _exposto else 2.0)
	if _nucleo and _exposto:
		var p := 1.0 + 0.18 * sin(_pulso * 9.0)
		_nucleo.scale = Vector2(p, p)


func _physics_process(dt: float) -> void:
	_ataque_forte = maxf(0.0, _ataque_forte - dt)
	_stagger = maxf(0.0, _stagger - dt)
	if _chao_cache <= 0.0:
		_chao_cache = _chao_y(global_position.x)
	if not _fase2 and not _ja_derrotado and vida <= int(_vida_max * 0.5):
		_entrar_fase2()
	_encarar_koliani()

	# atordoamento do pára-raios: cai já para EXPOSTO
	if _stagger > 0.0 and _fase not in [Fase.EXPOSTO, Fase.SOME, Fase.SURGE]:
		_ir(Fase.EXPOSTO)

	match _fase:
		Fase.DORME:
			global_position.y = lerpf(global_position.y, _chao_cache - altura_voo, clampf(dt * 3.0, 0.0, 1.0))
			if _ve_koliani():
				provocar()
				_ir(Fase.DECIDE)
		Fase.DECIDE:
			if _t >= 0.28:
				_escolher()
		Fase.SOME:
			if _t < dt:
				_esvair(true)
			if _t >= 0.22:
				_teleportar()
				_ir(Fase.SURGE)
		Fase.SURGE:
			if _t < dt:
				_esvair(false)
				Som.toca("raio", -8.0, 1.5)
			if _t >= 0.22:
				_ir(_prox)
		Fase.RAIOS_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_invocar_raios()
				_ir(Fase.RAIOS)
		Fase.RAIOS:
			if _t >= (1.1 if _fase2 else 0.9):
				_ir(Fase.EXPOSTO)
		Fase.CLONES_TEL:
			_piscar(true)
			if _t >= dur_tel:
				_piscar(false)
				_largar_clones()
				_ir(Fase.CLONES)
		Fase.CLONES:
			if _t >= 0.5:
				_ir(Fase.EXPOSTO)
		Fase.EXPOSTO:
			global_position.y = lerpf(global_position.y, _chao_cache - altura_voo, clampf(dt * 2.5, 0.0, 1.0))
			if not _exposto:
				_exposto = true
				_mostrar_nucleo(true)
			var dur: float = dur_exposto + (0.7 if _stagger > 0.0 else 0.0)
			if _t >= dur:
				_exposto = false
				_mostrar_nucleo(false)
				_ciclos += 1
				_ir(Fase.SOME)
	_t += dt


## --- máquina de estados ------------------------------------------------

func _ir(f: Fase) -> void:
	_fase = f
	_t = 0.0


func _escolher() -> void:
	_prox = Fase.CLONES_TEL if _ciclos % 3 == 2 else Fase.RAIOS_TEL
	_ir(Fase.SOME)


func _ve_koliani() -> bool:
	var d := _vetor_para_koliani()
	return d != Vector2.ZERO and absf(d.x) <= dist_deteta and absf(d.y) <= 360.0


## --- teleporte -------------------------------------------------------

func _esvair(a_sair: bool) -> void:
	if _sprite == null:
		return
	Som.toca("raio", -12.0, 0.5 if a_sair else 0.9)
	create_tween().tween_property(_sprite, "modulate:a", 0.1 if a_sair else 1.0, 0.18)


func _teleportar() -> void:
	var lado := -1.0 if randf() < 0.5 else 1.0
	var x := clampf(_x_koliani() + lado * randf_range(220.0, 360.0), _origem.x - alcance_x, _origem.x + alcance_x)
	_chao_cache = _chao_y(x)
	global_position = Vector2(x, _chao_cache - altura_voo)
	_encarar_koliani()


## --- ataques ---------------------------------------------------------

func _invocar_raios() -> void:
	var pai := get_parent()
	if pai == null:
		return
	Som.toca("raio", -8.0, 1.4)
	var n := 4 if _fase2 else 3
	var passo := 90.0 if _fase2 else 130.0
	var alvo := _x_koliani()
	for i in n:
		var x := alvo + (i - (n - 1) * 0.5) * passo + randf_range(-12.0, 12.0)
		var r := RAIO.instantiate()
		r.automatico = false
		r.dano = 24
		r.aviso = 0.7 if not _fase2 else 0.55
		r.global_position = Vector2(x, _chao_y(x))
		pai.add_child(r)
		r.cair(r.aviso + i * 0.12)


func _largar_clones() -> void:
	Som.toca("invocar", -8.0, 0.7)
	var pai := get_parent()
	if pai == null:
		return
	var n := 2 if _fase2 else 1
	for i in n:
		var c := CLONE.instantiate()
		c.vida = 20
		c.dano_contacto = 14
		c.velocidade = 96.0
		c.alcance_patrulha = 320.0
		c.cor_estilhacos = Color(0.5, 0.85, 1.0)
		c.cor_rim = Color(0.6, 0.95, 1.0)
		var x := global_position.x + (i * 2 - 1) * 60.0
		c.global_position = Vector2(x, _chao_y(x) - 20.0)
		pai.add_child(c)
		c.get_tree().create_timer(8.0).timeout.connect(func() -> void:
			if is_instance_valid(c) and not c._morto:
				c.soltar_estilhacos()
				c.queue_free())


## --- fase 2 --------------------------------------------------------

func _entrar_fase2() -> void:
	_fase2 = true
	Som.toca("chefe_cai", -8.0, 0.7)
	_abanar_camera(8.0)
	dur_tel *= 0.75
	dur_exposto *= 0.85


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
	if _sprite:
		_sprite.modulate.a = 1.0
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
		Som.toca("bloqueio", -9.0, 0.7)
		if _sprite:
			var m := _sprite.modulate
			_sprite.modulate = Color(0.7, 0.9, 1.2, m.a)
			create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1, m.a), 0.12)
		return
	super.receber_dano(int(round(quantidade * 2.0)), dir_empurrao, critico)


## Chamado pelo `ParaRaios`: passa a guarda e atordoa.
func receber_dano_ignorando_guarda(quantidade: int, dir_empurrao: float = 0.0, critico := false) -> void:
	if _ja_derrotado:
		return
	provocar()
	_stagger = 1.0
	_abanar_camera(5.0)
	if _sprite:
		_sprite.modulate = Color(1.6, 1.8, 2.0)
		create_tween().tween_property(_sprite, "modulate", Color(1, 1, 1), 0.2)
	super.receber_dano(int(round(quantidade * 1.5)), dir_empurrao, critico)


## --- utilitários --------------------------------------------------

func _x_koliani() -> float:
	var k := _obter_koliani()
	return k.global_position.x if k else global_position.x


func _chao_y(x: float) -> float:
	var mundo := get_world_2d()
	if mundo == null:
		return _origem.y + 120.0
	var de := Vector2(x, _origem.y - 60.0)
	var q := PhysicsRayQueryParameters2D.create(de, de + Vector2(0.0, 700.0), 1)
	q.exclude = [self]
	var hit := mundo.direct_space_state.intersect_ray(q)
	return (hit["position"].y as float) if hit else _origem.y + 260.0


func _abanar_camera(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)
