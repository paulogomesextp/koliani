extends Control
## Barra do HUD moderna, desenhada à mão: vidro escuro, enchimento arredondado
## com brilho no topo, "rasto" claro que esvazia atrás quando se perde valor
## e número opcional por cima. Usada pela vida e pela energia da Koliani.

@export var cor := Color(0.9, 0.18, 0.26)
@export var cor_baixa := Color(1.0, 0.45, 0.4)   ## pulsa a esta cor com pouco valor
@export var mostrar_numero := true
@export var tamanho_letra := 14
## Fracções (0..1) onde se desenha um traço de divisão (custo do Especial).
@export var marcas: Array[float] = []

var max_value := 100.0
var value := 100.0
var _rasto := 100.0          ## valor do rasto (>= value ao perder, == value ao ganhar)
var _espera := 0.0
var _pisca := 0.0


func definir(atual: float, maximo: float) -> void:
	max_value = maxf(maximo, 1.0)
	atual = clampf(atual, 0.0, max_value)
	if atual < value:
		_espera = 0.45
	value = atual
	_rasto = maxf(_rasto, value)
	queue_redraw()


func fracao() -> float:
	return clampf(value / max_value, 0.0, 1.0)


func _process(dt: float) -> void:
	var mudou := false
	if _rasto > value:
		if _espera > 0.0:
			_espera -= dt
		else:
			_rasto = maxf(value, _rasto - max_value * 0.9 * dt)
		mudou = true
	if fracao() < 0.3 and value > 0.0:
		_pisca += dt
		mudou = true
	if mudou:
		queue_redraw()


func _caixa(cor_bg: Color, raio: float, borda := 0.0, cor_borda := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = cor_bg
	sb.set_corner_radius_all(int(raio))
	sb.anti_aliasing = true
	if borda > 0.0:
		sb.set_border_width_all(int(borda))
		sb.border_color = cor_borda
	return sb


func _draw() -> void:
	var h := size.y
	var r := h * 0.5
	draw_style_box(_caixa(Color(0.03, 0.02, 0.06, 0.8), r, 1, Color(1, 1, 1, 0.16)),
		Rect2(Vector2.ZERO, size))
	var m := 2.0   # margem interior
	var util := Vector2(size.x - m * 2.0, h - m * 2.0)
	var f_rasto := clampf(_rasto / max_value, 0.0, 1.0)
	if _rasto > value + 0.01:
		draw_style_box(_caixa(Color(1.0, 0.86, 0.72, 0.9), util.y * 0.5),
			Rect2(Vector2(m, m), Vector2(maxf(util.y, util.x * f_rasto), util.y)))
	var f := fracao()
	if f > 0.0:
		var c := cor
		if f < 0.3:
			c = cor.lerp(cor_baixa, 0.5 + 0.5 * sin(_pisca * 9.0))
		var larg := maxf(util.y, util.x * f)
		draw_style_box(_caixa(c, util.y * 0.5), Rect2(Vector2(m, m), Vector2(larg, util.y)))
		# brilho de vidro no terço de cima
		draw_style_box(_caixa(Color(1, 1, 1, 0.22), util.y * 0.25),
			Rect2(Vector2(m + 2.0, m + 1.0), Vector2(maxf(0.0, larg - 4.0), util.y * 0.38)))
	for mf in marcas:
		var x := m + util.x * mf
		draw_line(Vector2(x, m + 1.0), Vector2(x, h - m - 1.0), Color(0.03, 0.02, 0.06, 0.8), 2.0)
	if mostrar_numero:
		var fonte := ThemeDB.fallback_font
		var txt := "%d / %d" % [ceili(value), ceili(max_value)]
		var tam := fonte.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_letra)
		var pos := Vector2((size.x - tam.x) * 0.5, (h + tamanho_letra * 0.72) * 0.5)
		draw_string_outline(fonte, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_letra, 4, Color(0.02, 0.01, 0.04, 0.95))
		draw_string(fonte, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho_letra, Color(1, 0.97, 0.98))
