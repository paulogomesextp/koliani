class_name Torreta
extends Node2D
## "Mob" de parede que MANDA FOGO: telegrafa (a boca acende) e cospe uma
## `BolaFogo` na direção `direcao`, em ciclo. Mecânica de cenário para os
## corredores/gauntlets antes do chefe. Visual em código -- boca de pedra
## + brasa que pulsa.

const BOLA := preload("res://scenes/actors/BolaFogo.tscn")

## Direção do tiro (será normalizada). (1,0) = para a direita.
@export var direcao := Vector2(1.0, 0.0)
@export var intervalo := 2.6
## Aviso (boca a acender) antes de cada tiro.
@export var telegrafo := 0.55
@export var fase := 0.0
@export var dano := 16
@export var vel_bola := 235.0

var _prox := 0.0
var _brasa: PointLight2D
var _boca: Polygon2D


func _ready() -> void:
	add_to_group("torretas")
	_prox = maxf(0.3, intervalo) + fase
	_montar_visual()


func _montar_visual() -> void:
	var dir := direcao.normalized()
	var ang := dir.angle()
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-9, -9), Vector2(4, -8), Vector2(9, 0), Vector2(4, 8), Vector2(-9, 9)])
	base.color = Color(0.16, 0.15, 0.19)
	base.rotation = ang
	add_child(base)

	var aro := Polygon2D.new()
	aro.polygon = PackedVector2Array([
		Vector2(2, -6), Vector2(10, -5), Vector2(12, 0), Vector2(10, 5), Vector2(2, 6)])
	aro.color = Color(0.3, 0.27, 0.33)
	aro.rotation = ang
	add_child(aro)

	_boca = Polygon2D.new()
	_boca.polygon = PackedVector2Array([Vector2(6, -4), Vector2(12, 0), Vector2(6, 4)])
	_boca.color = Color(1.0, 0.4, 0.12, 0.0)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_boca.material = m
	_boca.rotation = ang
	add_child(_boca)

	_brasa = PointLight2D.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 96
	tex.height = 96
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	_brasa.texture = tex
	_brasa.color = Color(1.0, 0.5, 0.18)
	_brasa.energy = 0.0
	_brasa.position = dir * 10.0
	_brasa.scale = Vector2(0.5, 0.5)
	add_child(_brasa)


func _process(dt: float) -> void:
	_prox -= dt
	var carga := clampf(1.0 - _prox / maxf(0.05, telegrafo), 0.0, 1.0) if _prox < telegrafo else 0.0
	if _brasa:
		_brasa.energy = 2.6 * carga
	if _boca:
		_boca.color.a = 0.9 * carga
	if _prox <= 0.0:
		_disparar()
		_prox = maxf(0.6, intervalo)


func _disparar() -> void:
	var dir := direcao.normalized()
	var b := BOLA.instantiate()
	b.velocidade = dir * vel_bola
	b.dano = dano
	get_parent().add_child(b)
	b.global_position = global_position + dir * 12.0
	Som.toca("projetil", -16.0, 0.8)
