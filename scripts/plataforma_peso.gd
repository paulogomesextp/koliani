class_name PlataformaPeso
extends AnimatableBody2D
## Plataforma que **desce com o peso dela** e volta a subir quando ela sai.
##
## Uma das linhas do catálogo do Paulo que ainda não existiam ("plataformas
## que sobem/descem com peso"). É a irmã lenta da `PlataformaQuebra`: aqui
## não se perde o chão, perde-se ALTURA -- e é isso que faz a decisão. Ficar
## em cima leva-a para baixo, e o salto de saída é cada vez mais alto.
##
## `AnimatableBody2D` e não `StaticBody2D`: assim a Koliani vai COM ela em
## vez de ficar para trás ou de a atravessar (o motor trata do arrasto), que
## é exactamente a razão pela qual a `Plataforma` móvel do jogo também é
## animável.
##
## Constrói o próprio corpo e o próprio visual -- não precisa de cena.

@export var tamanho := Vector2(120.0, 18.0)
## Quanto desce, no total, com ela em cima.
@export var curso := 90.0
## Píxeis por segundo a descer (com peso) e a subir (sem).
@export var vel_desce := 46.0
@export var vel_sobe := 30.0
@export var cor_base := Color(0.26, 0.22, 0.34)
@export var cor_topo := Color(0.58, 0.5, 0.72)

var _y0 := 0.0
var _carregada := false
var _sensor: Area2D


func _ready() -> void:
	add_to_group("plataformas_peso")
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = false   # movemo-la no `_physics_process`, à mão
	_y0 = position.y
	_montar()


func _montar() -> void:
	var col := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = tamanho
	col.shape = r
	add_child(col)

	var vis := Polygon2D.new()
	var hx := tamanho.x * 0.5
	var hy := tamanho.y * 0.5
	vis.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)])
	vis.color = cor_base
	add_child(vis)
	var topo := Polygon2D.new()
	topo.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, -hy + 5.0),
		Vector2(-hx, -hy + 5.0)])
	topo.color = cor_topo
	add_child(topo)
	# duas correntes desenhadas a subir: dizem "isto está pendurado" antes
	# de a plataforma se mexer pela primeira vez
	for lado in [-1.0, 1.0]:
		var fio := Line2D.new()
		fio.width = 2.0
		fio.default_color = cor_base.lightened(0.25)
		fio.points = PackedVector2Array([
			Vector2(lado * hx * 0.6, -hy), Vector2(lado * hx * 0.6, -hy - curso - 14.0)])
		fio.z_index = -1
		add_child(fio)

	# O sensor é uma Area2D na máscara da Koliani (layer 2). Não se usa
	# `get_colliding_bodies`: um `AnimatableBody2D` não reporta quem tem em
	# cima, e testar `is_on_floor` da Koliani daqui era pior.
	_sensor = Area2D.new()
	_sensor.collision_layer = 0
	_sensor.collision_mask = 2
	var sc := CollisionShape2D.new()
	var sr := RectangleShape2D.new()
	sr.size = Vector2(tamanho.x, 26.0)
	sc.shape = sr
	sc.position = Vector2(0.0, -tamanho.y * 0.5 - 13.0)
	_sensor.add_child(sc)
	add_child(_sensor)


func _physics_process(dt: float) -> void:
	_carregada = _sensor != null and not _sensor.get_overlapping_bodies().is_empty()
	var alvo: float = _y0 + (curso if _carregada else 0.0)
	var v: float = vel_desce if _carregada else vel_sobe
	position.y = move_toward(position.y, alvo, v * dt)
