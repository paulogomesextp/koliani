class_name Checkpoint
extends Area2D
## Guarda a posição de reaparecimento. A Koliani reaparece aqui enquanto
## tiver vidas; ao ficar sem vidas a campanha reinicia (ver
## `EstadoJogo.reiniciar_campanha`).
##
## Visual construído em código (ignora o `Visual`/`Luz` que a cena do nível
## traz): uma GEMA verde-platina FOSCA que, ao ser tocada, acende e fica a
## brilhar -- sinal de que há um novo ponto de regresso.

const COR_FOSCA := Color(0.36, 0.44, 0.4)
const COR_ACESA := Color(0.42, 1.0, 0.68)

var _ativo := false
var _t := 0.0
var _gema: Polygon2D
var _nucleo: Polygon2D
var _luz: PointLight2D


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	# esconde o visual antigo que vinha da cena do nível (poste + brilho)
	for nome in ["Visual", "Luz", "Brilho"]:
		var n := get_node_or_null(nome)
		if n and n is CanvasItem:
			(n as CanvasItem).visible = false
	_montar_visual()
	if EstadoJogo.checkpoint.is_equal_approx(global_position):
		_ativar(true)


func _montar_visual() -> void:
	var losango := PackedVector2Array([
		Vector2(0, -16), Vector2(9, -2), Vector2(0, 18), Vector2(-9, -2),
	])
	var contorno := Polygon2D.new()
	contorno.polygon = _escalar(losango, 1.18)
	contorno.color = Color(0.05, 0.1, 0.08)
	add_child(contorno)

	_gema = Polygon2D.new()
	_gema.polygon = losango
	_gema.color = COR_FOSCA
	add_child(_gema)

	# faceta / brilho interno
	var faceta := Polygon2D.new()
	faceta.polygon = PackedVector2Array([Vector2(0, -13), Vector2(4, -3), Vector2(0, 2), Vector2(-4, -3)])
	faceta.color = Color(1, 1, 1, 0.14)
	add_child(faceta)

	_nucleo = Polygon2D.new()
	_nucleo.polygon = _escalar(losango, 0.42)
	_nucleo.color = Color(0.95, 1.0, 0.98)
	_nucleo.visible = false
	add_child(_nucleo)

	_luz = PointLight2D.new()
	_luz.texture = _tex_luz()
	_luz.color = COR_ACESA
	_luz.energy = 0.18
	_luz.scale = Vector2(0.5, 0.5)
	add_child(_luz)


func _escalar(pts: PackedVector2Array, f: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in pts:
		out.append(v * f)
	return out


func _tex_luz() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 180
	t.height = 180
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


func _process(dt: float) -> void:
	if not _ativo:
		return
	_t += dt
	if _luz:
		_luz.energy = 1.15 + 0.25 * sin(_t * 4.0)
	if _nucleo:
		var s := 1.0 + 0.12 * sin(_t * 6.0)
		_nucleo.scale = Vector2(s, s)


func _ao_entrar(corpo: Node) -> void:
	if corpo is Koliani and not _ativo:
		_ativar(false)
		EstadoJogo.definir_checkpoint(global_position)
		Som.toca("selo", -12.0)


func _ativar(instantaneo: bool) -> void:
	_ativo = true
	if _nucleo:
		_nucleo.visible = true
	if instantaneo:
		if _gema:
			_gema.color = COR_ACESA
		if _luz:
			_luz.energy = 1.3
			_luz.scale = Vector2(1.0, 1.0)
		return
	if _gema:
		var tg := create_tween()
		tg.tween_property(_gema, "color", COR_ACESA, 0.25)
	if _luz:
		var tl := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tl.tween_property(_luz, "scale", Vector2(1.25, 1.25), 0.22)
		tl.parallel().tween_property(_luz, "energy", 1.5, 0.22)
		tl.tween_property(_luz, "scale", Vector2(1.0, 1.0), 0.18)
