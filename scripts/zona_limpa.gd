class_name ZonaLimpa
extends Area2D
## "Zona temporariamente limpa" da Regiao XII (prancha: "areas seguras
## limitadas, criadas por mecanismos ou eventos"). Um ponto de ar respiravel
## no meio do solo contaminado: quem estiver dentro perde o veneno e, enquanto
## aqui ficar, nao o apanha (o `SoloToxico` testa a mesma sobreposicao, mas a
## zona limpa limpa depois e por isso ganha). Com `duracao > 0` a zona gasta-se:
## apaga-se ao fim de `duracao` s de ocupacao e reacende-se sozinha apos
## `recarga` s -- e' o que uma valvula de purga faz.

@export var largura := 200.0 : set = _set_largura
@export var altura := 120.0
@export var duracao := 0.0
@export var recarga := 6.0
@export var textura: Texture2D

var _forma: CollisionShape2D
var _halo: Sprite2D
var _luz: PointLight2D
var _gasto := 0.0
var _apagada := 0.0


func _set_largura(v: float) -> void:
	largura = maxf(40.0, v)
	if is_node_ready():
		_reconstruir()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_forma = CollisionShape2D.new()
	add_child(_forma)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_halo = Sprite2D.new()
	_halo.material = mat
	_halo.z_index = 1
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([Color(0.6, 1.0, 0.95, 0.0), Color(0.45, 0.95, 0.85, 0.12),
		Color(0.7, 1.0, 0.95, 0.3)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 8
	gt.height = 64
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	_halo.texture = gt
	_halo.centered = false
	add_child(_halo)
	_luz = PointLight2D.new()
	_luz.color = Color(0.55, 1.0, 0.9)
	_luz.energy = 0.35
	var g2 := Gradient.new()
	g2.offsets = PackedFloat32Array([0.0, 1.0])
	g2.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var t2 := GradientTexture2D.new()
	t2.gradient = g2
	t2.width = 128
	t2.height = 128
	t2.fill = GradientTexture2D.FILL_RADIAL
	t2.fill_from = Vector2(0.5, 0.5)
	t2.fill_to = Vector2(1, 0.5)
	_luz.texture = t2
	add_child(_luz)
	_reconstruir()


func _reconstruir() -> void:
	if _forma == null:
		return
	var r := RectangleShape2D.new()
	r.size = Vector2(largura, altura)
	_forma.shape = r
	_forma.position = Vector2(0, -altura * 0.5)
	_halo.scale = Vector2(largura / 8.0, altura / 64.0)
	_halo.position = Vector2(-largura * 0.5, -altura)
	_luz.position = Vector2(0, -altura * 0.35)
	_luz.scale = Vector2(largura / 128.0 * 1.3, altura / 128.0 * 1.4)


func ativa() -> bool:
	return _apagada <= 0.0


func _process(dt: float) -> void:
	if _apagada > 0.0:
		_apagada -= dt
		if _apagada <= 0.0:
			_gasto = 0.0
	var t := Time.get_ticks_msec() * 0.001
	var viva := ativa()
	var pulso := 0.5 + 0.5 * sin(t * 2.0)
	_halo.modulate = Color(1, 1, 1, (0.55 + 0.3 * pulso) if viva else 0.06)
	_luz.energy = (0.3 + 0.12 * pulso) if viva else 0.03
	if not viva:
		return
	var alguem := false
	for c in get_overlapping_bodies():
		if c is Koliani and c.has_method("limpar_veneno"):
			c.limpar_veneno()
			alguem = true
	if alguem and duracao > 0.0:
		_gasto += dt
		if _gasto >= duracao:
			_apagada = recarga
