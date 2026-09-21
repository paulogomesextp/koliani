class_name Essencia
extends Area2D
## Mote de ESSÊNCIA -- a moeda mágica. Largado por inimigos ao morrer e
## posto em caches nas alcovas dos níveis. Salta para fora, espera um
## instante e depois voa para a Koliani; ao tocá-la soma ao total e some.
##
## Uso: instanciar, `valor = N`, `global_position = ...`, add_child.

@export var valor := 1
## Impulso inicial para fora (0 = fica quieto, para caches).
@export var espalhar := true

const VIDA := 14.0
const VEL_HOMING := 520.0
const ATRACAO := 3000.0

var _vel := Vector2.ZERO
var _t := 0.0
var _atraso := 0.0
var _koli: Node2D
var _apanhado := false

## Execution 9G: brilho de recolha da prancha 07 (só na Região I).
const Vfx9G := preload("res://scripts/vfx_regiao1.gd")

@onready var _nucleo: Polygon2D = $Nucleo
@onready var _halo: Polygon2D = $Halo
@onready var _luz: PointLight2D = $Luz


func _ready() -> void:
	# O cristal de Essência da prancha 09 já identifica esta moeda no HUD.
	var cristal := UIProducao.textura("ico_cristal")
	if cristal:
		_nucleo.self_modulate.a = 0.0
		_halo.visible = false
		var arte := Sprite2D.new()
		arte.name = "CristalEssencia"
		arte.texture = cristal
		arte.scale = Vector2.ONE * (14.0 / cristal.get_height())
		arte.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_nucleo.add_child(arte)
	# `set_deferred` e nao atribuicao directa: a essencia nasce DENTRO do
	# `receber_dano` do bicho, que corre a meio do passo de fisica -- ligar
	# o `monitoring` ali dava "Can't change this state while flushing
	# queries" e a moeda ficava sem area nenhuma.
	set_deferred("monitoring", true)
	collision_layer = 0
	collision_mask = 2   # a Koliani está na layer 2
	body_entered.connect(_ao_tocar)
	_atraso = randf_range(0.35, 0.55)
	if espalhar:
		_vel = Vector2(randf_range(-1.0, 1.0), randf_range(-1.4, -0.4)).normalized() \
			* randf_range(120.0, 240.0)
	# tamanho pelo valor (motes grandes valem mais)
	var esc := clampf(0.7 + 0.02 * float(valor), 0.7, 1.8)
	scale = Vector2(esc, esc)
	get_tree().create_timer(VIDA).timeout.connect(func() -> void:
		if is_instance_valid(self) and not _apanhado:
			_esvair())


func _physics_process(dt: float) -> void:
	if _apanhado:
		return
	# Caches e drops são actores do mundo: fora do viewport não simulam
	# gravidade/homing e não podem auto-recolher nem tocar SFX.
	if not Som.actor_visivel(self):
		return
	_t += dt
	_koli = get_tree().get_first_node_in_group("koliani")
	if _t >= _atraso and _koli:
		var para := (_koli.global_position + Vector2(0, -16) - global_position)
		var d := para.length()
		_vel = _vel.move_toward(para.normalized() * VEL_HOMING, ATRACAO * dt)
		if d < 18.0:
			_apanhar()
			return
	else:
		_vel = _vel.move_toward(Vector2.ZERO, 260.0 * dt)
		_vel.y += 320.0 * dt   # gravidadezinha antes do homing
	global_position += _vel * dt
	if _nucleo:
		_nucleo.rotation += dt * 6.0
	if _luz:
		_luz.energy = 0.9 + 0.35 * sin(_t * 12.0)


func _ao_tocar(corpo: Node) -> void:
	if corpo.is_in_group("koliani"):
		_apanhar()


func _apanhar() -> void:
	if _apanhado:
		return
	_apanhado = true
	EstadoJogo.ganhar_essencia(valor)
	if Vfx9G.ativo(self):
		Vfx9G.tocar(self, "pickup", global_position, 0.7, 0.0, false, false, 38, 0.28)
	Som.toca("apanhar", -14.0, randf_range(1.15, 1.4))
	set_deferred("monitoring", false)
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "scale", scale * 1.9, 0.12)
	t.tween_property(self, "modulate:a", 0.0, 0.12)
	t.chain().tween_callback(queue_free)


func _esvair() -> void:
	_apanhado = true
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.4)
	t.tween_callback(queue_free)
