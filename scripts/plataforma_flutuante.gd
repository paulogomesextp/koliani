class_name PlataformaFlutuante
extends AnimatableBody2D
## Plataforma que baloiça (seno vertical) e opcionalmente deriva na
## horizontal. `AnimatableBody2D` com `sync_to_physics` -> carrega a Koliani
## quando ela vai em cima. Mecânica partilhada da região I (Pântano), útil
## em qualquer bioma com vazio/líquido por baixo.
##
## A Morvanna (chefe do nível 02) "apaga" estas plataformas: chama
## `desvanecer()` / `reaparecer()`. Todas entram no grupo
## "plataformas_flutuantes".

@export var largura := 150.0 : set = _set_largura
## Amplitude e período do baloiço vertical (px / segundos).
@export var balanco := 10.0
@export var periodo := 2.6
## Deriva horizontal: distância total do vaivém (0 = fica no sítio).
@export var deriva := 0.0
@export var periodo_deriva := 4.0
## Desfasamento inicial (segundos) -- para plataformas vizinhas não
## baloiçarem todas em fase.
@export var fase := 0.0
@export var cor_topo := Color(0.4, 0.36, 0.28)
@export var cor_base := Color(0.16, 0.13, 0.1)

var _base := Vector2.ZERO
var _t := 0.0
var _apagada := false

@onready var _forma: CollisionShape2D = $Col
@onready var _visual: Polygon2D = $Visual


func _ready() -> void:
	add_to_group("plataformas_flutuantes")
	sync_to_physics = true
	_base = global_position
	_t = fase
	_reconstruir()


func _physics_process(dt: float) -> void:
	_t += dt
	var dx := 0.0
	if deriva != 0.0:
		dx = sin(_t * TAU / periodo_deriva) * deriva * 0.5
	var dy := sin(_t * TAU / periodo) * balanco
	global_position = _base + Vector2(dx, dy)


## A Morvanna apaga a plataforma por uns segundos (fade + sem colisão).
func desvanecer(segundos: float) -> void:
	if _apagada:
		return
	_apagada = true
	_forma.set_deferred("disabled", true)
	var t := create_tween()
	t.tween_property(_visual, "modulate:a", 0.12, 0.25)
	t.tween_interval(maxf(0.1, segundos))
	t.tween_callback(reaparecer)


func reaparecer() -> void:
	_apagada = false
	_forma.set_deferred("disabled", false)
	create_tween().tween_property(_visual, "modulate:a", 1.0, 0.3)


func _set_largura(v: float) -> void:
	largura = maxf(32.0, v)
	if is_node_ready():
		_reconstruir()


func _reconstruir() -> void:
	if _forma == null or _visual == null:
		return
	var hw := largura * 0.5
	var r := RectangleShape2D.new()
	r.size = Vector2(largura, 24.0)
	_forma.shape = r
	_forma.position = Vector2(0.0, 4.0)
	_visual.polygon = PackedVector2Array([
		Vector2(-hw, -10), Vector2(hw, -10),
		Vector2(hw - 8, 16), Vector2(-hw + 8, 16),
	])
	_visual.vertex_colors = PackedColorArray([cor_topo, cor_topo, cor_base, cor_base])
