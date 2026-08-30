class_name PlataformaQuebra
extends StaticBody2D
## Plataforma que ESBOROA quando a Koliani lhe pisa: estremece um instante,
## cai, e volta a formar-se passado um tempo. Mecânica de plataforma
## partilhada dos percursos -- obriga a não parar. Anti-softlock: quem a
## semeia põe-na SEMPRE sobre chão seguro ou como atalho opcional.
##
## @export tamanho / atraso / respawn

@export var tamanho := Vector2(90.0, 18.0) : set = _set_tamanho
## Segundos a estremecer antes de cair.
@export var atraso := 0.45
## Segundos até voltar a formar-se.
@export var respawn := 2.6

enum { FIRME, TREME, IDA, FORA }

var _estado := FIRME
var _t := 0.0
var _base := Vector2.ZERO
var _col: CollisionShape2D
var _vis: Polygon2D
var _borda: Line2D
var _deteta: Area2D


func _ready() -> void:
	add_to_group("plataformas_quebra")
	collision_layer = 1
	collision_mask = 0
	_base = position
	_montar()


func _montar() -> void:
	_col = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = tamanho
	_col.shape = r
	add_child(_col)

	var hw := tamanho.x * 0.5
	var hh := tamanho.y * 0.5
	_vis = Polygon2D.new()
	_vis.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)])
	_vis.color = Color(0.32, 0.29, 0.34)
	add_child(_vis)
	# "fissuras"
	var fiss := Line2D.new()
	fiss.points = PackedVector2Array([
		Vector2(-hw * 0.5, -hh), Vector2(-hw * 0.2, hh * 0.3),
		Vector2(hw * 0.1, -hh * 0.4), Vector2(hw * 0.5, hh)])
	fiss.width = 1.5
	fiss.default_color = Color(0.12, 0.1, 0.14, 0.8)
	add_child(fiss)
	_borda = Line2D.new()
	_borda.points = _vis.polygon
	_borda.closed = true
	_borda.width = 2.0
	_borda.default_color = Color(0.5, 0.42, 0.5, 0.7)
	add_child(_borda)

	_deteta = Area2D.new()
	_deteta.collision_layer = 0
	_deteta.collision_mask = 2
	var cs := CollisionShape2D.new()
	var rr := RectangleShape2D.new()
	rr.size = Vector2(tamanho.x, tamanho.y + 26.0)
	cs.shape = rr
	cs.position = Vector2(0, -13.0)
	_deteta.add_child(cs)
	_deteta.body_entered.connect(_ao_pisar)
	add_child(_deteta)


func _set_tamanho(v: Vector2) -> void:
	tamanho = v
	if is_node_ready():
		for c in [_col, _vis, _borda, _deteta]:
			if c:
				c.queue_free()
		_montar()


func _ao_pisar(corpo: Node) -> void:
	if _estado == FIRME and corpo is Koliani:
		_estado = TREME
		_t = 0.0


func _process(dt: float) -> void:
	match _estado:
		TREME:
			_t += dt
			position = _base + Vector2(randf_range(-2.0, 2.0), randf_range(-1.0, 1.0))
			if _borda:
				_borda.default_color.a = 0.7 + 0.3 * sin(_t * 40.0)
			if _t >= atraso:
				_estado = IDA
				_t = 0.0
				_col.set_deferred("disabled", true)
		IDA:
			_t += dt
			position.y += 220.0 * _t
			modulate.a = maxf(0.0, 1.0 - _t * 2.2)
			if _t >= 0.5:
				_estado = FORA
				_t = 0.0
				visible = false
		FORA:
			_t += dt
			if _t >= respawn:
				_estado = FIRME
				position = _base
				modulate.a = 1.0
				visible = true
				if _borda:
					_borda.default_color.a = 0.7
				_col.set_deferred("disabled", false)
