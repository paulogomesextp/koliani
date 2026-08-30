class_name AguaVenenosa
extends Armadilha
## Poça de água/lodo venenoso -- morte instantânea ao toque. Mecânica
## partilhada da região I (Pântano dos Sussurros) e reutilizável como
## "fosso líquido" noutros biomas (lava, ácido) trocando só as cores.
##
## Uso: instanciar, pousar em `global_position` (o centro da poça) e pôr
## `largura`/`altura` em pixéis. A forma de colisão e a superfície visual
## (Polygon2D translúcido com uma ondulação lenta) montam-se sozinhas.

@export var largura := 320.0 : set = _set_largura
@export var altura := 120.0 : set = _set_altura
## Cor da superfície (a metade de cima é mais clara).
@export var cor := Color(0.3, 0.62, 0.36, 0.9) : set = _set_cor

var _forma: CollisionShape2D
var _sup: Polygon2D
var _rim: Polygon2D
var _luz: PointLight2D
var _t := 0.0


func _pronto() -> void:
	dano = 999  # >= vida máxima da Koliani -> _morrer()
	_forma = $CollisionShape2D
	_sup = $Superficie
	_rim = get_node_or_null("Rebordo")
	_luz = get_node_or_null("Luz")
	_reconstruir()


func _process(dt: float) -> void:
	if _sup == null:
		return
	_t += dt
	# ondulação lenta da superfície (só visual)
	var onda := sin(_t * 1.6) * 2.0
	_sup.position.y = onda
	_sup.color.a = cor.a * (0.9 + 0.1 * sin(_t * 2.3))
	if _rim:
		_rim.position.y = onda
		_rim.modulate.a = 0.6 + 0.4 * sin(_t * 2.0 + 1.0)
	if _luz:
		_luz.energy = 0.7 + 0.15 * sin(_t * 2.6)


func _set_largura(v: float) -> void:
	largura = maxf(16.0, v)
	if is_node_ready():
		_reconstruir()


func _set_altura(v: float) -> void:
	altura = maxf(16.0, v)
	if is_node_ready():
		_reconstruir()


func _set_cor(v: Color) -> void:
	cor = v
	if is_node_ready():
		_reconstruir()


func _reconstruir() -> void:
	if _forma == null or _sup == null:
		return
	var r := RectangleShape2D.new()
	r.size = Vector2(largura, altura)
	_forma.shape = r
	_forma.position = Vector2.ZERO
	var hw := largura * 0.5
	var hh := altura * 0.5
	_sup.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh),
	])
	_sup.color = cor
	# gradiente simples: topo aceso (veneno luminoso), fundo mais escuro
	_sup.vertex_colors = PackedColorArray([
		cor.lightened(0.45), cor.lightened(0.45),
		cor.darkened(0.25), cor.darkened(0.25),
	])
	# rebordo aceso na linha de água -- deixa o perigo bem visível no escuro
	if _rim:
		_rim.polygon = PackedVector2Array([
			Vector2(-hw, -hh - 3.0), Vector2(hw, -hh - 3.0),
			Vector2(hw, -hh + 5.0), Vector2(-hw, -hh + 5.0),
		])
		_rim.color = Color(cor.lightened(0.6).r, cor.lightened(0.6).g, cor.lightened(0.6).b, 0.9)
	if _luz:
		_luz.position = Vector2(0.0, -hh)
