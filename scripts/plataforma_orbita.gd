class_name PlataformaOrbita
extends "res://scripts/tumulo_elevador.gd"
## "Plataformas circulares em rotacao" do N14 -- Campanario (`docs/
## art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md`):
## uma plataforma redonda que gira a' volta de um CUBO, sempre deitada (como
## a cadeira de uma roda gigante), presa a ele por uma corrente. Varias com o
## mesmo cubo e fases desencontradas fazem a roda inteira.
##
## O no' fica no CUBO; a plataforma anda a `raio` px dele. Com `sentido` = -1
## sai do ponto de baixo para a DIREITA e sobe (anti-horario no ecra).
## Instancia-se a cena `TumuloElevador.tscn` com este script por cima.
##
## Para o crivo de alcance (`tools/verifica_alcance.gd`) e' um VAIVEM
## vertical: sobe-se no ponto de baixo e desce-se no de cima, que e' o que
## a roda faz a quem vai nela (`_base` = ponto de baixo, `curso` = ate' ao
## de cima, `auto`).

## Distancia do cubo ao topo da plataforma (px).
@export var raio := 190.0
## Segundos por volta.
@export var periodo := 9.0
## Fase inicial (0..1 de uma volta), a contar do ponto de baixo.
@export var fase := 0.0
## -1 = anti-horario no ecra (de baixo vai para a direita); 1 = horario.
@export var sentido := -1.0
## A plataforma redonda da prancha (disco com a corrente pendurada).
@export var textura_disco: Texture2D
@export var escala_disco := 0.7
## Corrente do cubo a' plataforma.
@export var textura_corrente: Texture2D

var _cubo := Vector2.ZERO
var _t := 0.0
var _raio_spr: Sprite2D


func _ready() -> void:
	super._ready()
	auto = true
	_cubo = global_position
	_base = _cubo + Vector2(0.0, raio)
	curso = Vector2(0.0, -2.0 * raio)
	_t = fase * periodo
	_vestir()
	_posicionar()


func _physics_process(dt: float) -> void:
	_t += dt
	_posicionar()


func _angulo() -> float:
	return PI * 0.5 + sentido * TAU * _t / maxf(0.5, periodo)


func _posicionar() -> void:
	var a := _angulo()
	global_position = _cubo + Vector2(cos(a), sin(a)) * raio
	if _raio_spr:
		# corrente do cubo ao centro da plataforma: +y do sprite -> (cos a, sin a)
		var r := a - PI * 0.5
		var w := float(_raio_spr.texture.get_width()) * _raio_spr.scale.x
		_raio_spr.rotation = r
		_raio_spr.global_position = _cubo - Vector2(cos(r), sin(r)) * w * 0.5


func _vestir() -> void:
	var vis := get_node_or_null("Visual") as Polygon2D
	var runa := get_node_or_null("Runa") as CanvasItem
	if runa:
		runa.visible = false
	if textura_disco and vis:
		# o disco pintado e' a plataforma inteira: o poligono fica so' de
		# sombra por baixo do aro
		vis.color = Color(0.05, 0.04, 0.08, 0.0)
		var d := Sprite2D.new()
		d.name = "Disco"
		d.texture = textura_disco
		var e := largura / (float(textura_disco.get_width()) * 0.92)
		e = maxf(e, escala_disco)
		d.scale = Vector2(e, e)
		# o aro do disco fica na zona de cima da pintura (~38 % da altura);
		# alinha-se o aro com o topo da colisao (y = -8)
		d.position = Vector2(0.0, -8.0 + float(textura_disco.get_height()) * e * 0.3)
		add_child(d)
	if textura_corrente:
		_raio_spr = Sprite2D.new()
		_raio_spr.name = "Raio"
		_raio_spr.texture = textura_corrente
		_raio_spr.top_level = true
		_raio_spr.centered = false
		_raio_spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		_raio_spr.region_enabled = true
		var esc := 0.6
		_raio_spr.scale = Vector2(esc, esc)
		_raio_spr.region_rect = Rect2(0.0, 0.0, float(textura_corrente.get_width()), raio / esc)
		_raio_spr.modulate = Color(0.95, 0.8, 0.55, 0.95)
		_raio_spr.z_index = -2
		add_child(_raio_spr)
