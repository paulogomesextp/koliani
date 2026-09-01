class_name PedraQueda
extends Node2D
## Estalactite / pedra que se solta do tecto quando a Koliani passa por
## baixo (ou em ciclo, se `automatico`). Telegrafa (treme + poeira), cai
## depressa, magoa quem apanhar (Area2D), esfarela no chao. Nunca bloqueia
## a passagem -- e' um projetil de cenario, perfeito para grutas.
##
## @export chao_y / raio_gatilho / dano / aviso / automatico / periodo

## Y (global) onde a pedra se despedaca.
@export var chao_y := 120.0
## Distancia horizontal a que a passagem da Koliani a arma.
@export var raio_gatilho := 70.0
@export var dano := 22
## Segundos de aviso (a tremer) antes de largar.
@export var aviso := 0.55
## Repor-se e cair outra vez em ciclo (perigo permanente da gruta).
@export var automatico := false
@export var periodo := 3.4
@export var fase := 0.0
## Tamanho da pedra (raio aproximado, px).
@export var tam := 16.0

const GRAV := 1500.0

enum { PENDURADA, AVISO, CAI, MORTA }

var _estado := PENDURADA
var _vy := 0.0
var _t := 0.0
var _y0 := 0.0
var _x0 := 0.0
var _shake := 0.0
var _corpo: Polygon2D
var _area: Area2D
var _poeira: CPUParticles2D
var _koliani: Node2D


func _ready() -> void:
	add_to_group("pedras_queda")
	_y0 = position.y
	_x0 = position.x
	_montar_visual()
	if fase > 0.0:
		_t = -fase


func _montar_visual() -> void:
	# raiz no tecto
	var raiz := Polygon2D.new()
	raiz.polygon = PackedVector2Array([
		Vector2(-tam * 0.9, -tam * 1.2), Vector2(tam * 0.9, -tam * 1.2),
		Vector2(tam * 0.4, -tam * 0.2), Vector2(-tam * 0.4, -tam * 0.2)])
	raiz.color = Color(0.13, 0.12, 0.15)
	raiz.name = "Raiz"
	add_child(raiz)

	_corpo = Polygon2D.new()
	_corpo.polygon = PackedVector2Array([
		Vector2(-tam, -tam * 0.6), Vector2(-tam * 0.3, -tam), Vector2(tam * 0.6, -tam * 0.7),
		Vector2(tam, tam * 0.1), Vector2(tam * 0.2, tam), Vector2(-tam * 0.7, tam * 0.6)])
	_corpo.color = Color(0.28, 0.26, 0.3)
	add_child(_corpo)
	var aresta := Line2D.new()
	aresta.points = _corpo.polygon
	aresta.closed = true
	aresta.width = 2.0
	aresta.default_color = Color(0.5, 0.45, 0.55, 0.7)
	_corpo.add_child(aresta)

	_poeira = CPUParticles2D.new()
	_poeira.emitting = false
	_poeira.amount = 10
	_poeira.one_shot = true
	_poeira.lifetime = 0.6
	_poeira.explosiveness = 0.85
	_poeira.direction = Vector2(0, 1)
	_poeira.spread = 55.0
	_poeira.gravity = Vector2(0, 400)
	_poeira.initial_velocity_min = 20.0
	_poeira.initial_velocity_max = 80.0
	_poeira.color = Color(0.55, 0.5, 0.55, 0.8)
	add_child(_poeira)

	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2
	_area.monitoring = false
	var cs := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = tam * 0.8
	cs.shape = forma
	_area.add_child(cs)
	_area.body_entered.connect(_ao_tocar)
	add_child(_area)


func _fisica_koliani() -> Node2D:
	if not is_instance_valid(_koliani):
		_koliani = get_tree().get_first_node_in_group("koliani")
	return _koliani


func _physics_process(dt: float) -> void:
	match _estado:
		PENDURADA:
			var k := _fisica_koliani()
			var arma := false
			if k and absf(k.global_position.x - global_position.x) < raio_gatilho \
					and k.global_position.y > global_position.y - 20.0:
				arma = true
			if automatico:
				_t += dt
				if _t >= periodo:
					arma = true
			if arma:
				_estado = AVISO
				_t = 0.0
		AVISO:
			_t += dt
			_shake = 2.2
			position.x = _x0 + randf_range(-_shake, _shake)
			position.y = _y0 + randf_range(-_shake, _shake)
			if _t >= aviso:
				_estado = CAI
				_vy = 40.0
				position.x = _x0
				_area.monitoring = true
		CAI:
			_vy = minf(_vy + GRAV * dt, 1400.0)
			position.y += _vy * dt
			if global_position.y >= chao_y:
				_esfarelar()
		MORTA:
			if automatico:
				_t += dt
				if _t >= periodo:
					_repor()


func _ao_tocar(corpo: Node) -> void:
	if _estado == CAI and corpo is Koliani:
		var dir := signf(corpo.global_position.x - global_position.x)
		corpo.receber_dano(dano, dir if dir != 0.0 else 1.0)


func _esfarelar() -> void:
	_estado = MORTA
	_t = 0.0
	_area.monitoring = false
	if _corpo:
		_corpo.visible = false
	if _poeira:
		_poeira.position = to_local(Vector2(global_position.x, chao_y))
		_poeira.restart()


func _repor() -> void:
	_estado = PENDURADA
	_t = 0.0
	_vy = 0.0
	position = Vector2(_x0, _y0)
	if _corpo:
		_corpo.visible = true
