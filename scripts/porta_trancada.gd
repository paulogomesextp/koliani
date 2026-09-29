class_name PortaTrancada
extends StaticBody2D
## Grade/porta trancada que bloqueia a passagem (layer "mundo") até as
## `Alavanca` com o mesmo `id` estarem na posição certa. Visual (barras)
## construído em código; ao abrir sobe e a colisão desliga.
##
## `exige_todas = true` -> só abre com TODAS as alavancas ligadas;
## `false` -> basta UMA. `invertida = true` -> fecha quando ligam (armadilha).

## Liga esta porta às `Alavanca` com o mesmo id.
@export var id := "porta_a"
## Tamanho da grade (px).
@export var tamanho := Vector2(24.0, 140.0)
@export var exige_todas := true
@export var invertida := false
## Opt-in: porta de material (N13) -- `textura` repete-se pelo painel (bronze
## da prancha), `textura_moldura` faz a moldura e as cintas (metal dourado).
## Nada e' esticado. Vazio = as barras de poligonos de sempre.
@export var textura: Texture2D
@export var textura_moldura: Texture2D
@export var escala_textura := 0.5

@onready var _col: CollisionShape2D = $Col

var _aberta := false
var _barras: Node2D
var _altura_fechada := 0.0


func _ready() -> void:
	_altura_fechada = position.y
	_montar_visual()
	# liga-se às alavancas do mesmo id
	for a in get_tree().get_nodes_in_group("alavancas"):
		if a is Alavanca and a.id == id:
			a.mudou.connect(_reavaliar)
	call_deferred("_reavaliar")


func _montar_visual() -> void:
	if _col == null:
		_col = CollisionShape2D.new()
		_col.name = "Col"
		add_child(_col)
	var forma := RectangleShape2D.new()
	forma.size = tamanho
	_col.shape = forma

	_barras = Node2D.new()
	add_child(_barras)
	if textura:
		_vestir()
		return
	var moldura := Polygon2D.new()
	var hw := tamanho.x * 0.5
	var hh := tamanho.y * 0.5
	moldura.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
	])
	moldura.color = Color(0.09, 0.08, 0.1)
	_barras.add_child(moldura)
	var n := maxi(2, int(tamanho.x / 8.0))
	for i in n:
		var x := lerpf(-hw + 3.0, hw - 3.0, float(i) / float(n - 1))
		var barra := Polygon2D.new()
		barra.polygon = PackedVector2Array([
			Vector2(x - 1.5, -hh + 2), Vector2(x + 1.5, -hh + 2),
			Vector2(x + 1.5, hh - 2), Vector2(x - 1.5, hh - 2),
		])
		barra.color = Color(0.5, 0.52, 0.58)
		_barras.add_child(barra)


## Grade levadica de material: fundo escuro, barras verticais de metal
## dourado, cintas de bronze e moldura -- le-se como grade (ve-se o outro
## lado por entre as barras), nao como parede.
func _vestir() -> void:
	var hw := tamanho.x * 0.5
	var hh := tamanho.y * 0.5
	var fundo := Polygon2D.new()
	fundo.polygon = PackedVector2Array([Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh)])
	fundo.color = Color(0.03, 0.03, 0.06, 0.55)
	_barras.add_child(fundo)
	var mold := textura_moldura if textura_moldura else textura
	var ouro := Color(1.15, 0.95, 0.68)
	# barras verticais (de 12 em 12 px), cada uma com ponta de lanca em baixo
	var n := maxi(2, int(tamanho.x / 12.0))
	for i in n:
		var x := lerpf(-hw + 5.0, hw - 5.0, float(i) / float(n - 1))
		_barras.add_child(_retangulo(mold, Rect2(x - 2.5, -hh, 5.0, tamanho.y - 6.0), ouro))
		var ponta := Polygon2D.new()
		ponta.polygon = PackedVector2Array([Vector2(x - 4, hh - 8), Vector2(x + 4, hh - 8),
			Vector2(x, hh + 4)])
		ponta.color = Color(0.95, 0.76, 0.46)
		_barras.add_child(ponta)
	# cintas horizontais de bronze de 80 em 80 px
	var m := maxi(1, int(tamanho.y / 80.0))
	for i in m:
		var y := lerpf(-hh, hh, float(i + 1) / float(m + 1))
		_barras.add_child(_retangulo(textura, Rect2(-hw, y - 5.0, tamanho.x, 10.0),
			Color(0.95, 0.82, 0.7)))
	# moldura (so' os lados e o topo -- em baixo sao as pontas)
	for r in [Rect2(-hw - 3, -hh, 6, tamanho.y), Rect2(hw - 3, -hh, 6, tamanho.y),
			Rect2(-hw - 3, -hh, tamanho.x + 6, 8)]:
		_barras.add_child(_retangulo(mold, r, Color(0.85, 0.7, 0.5)))


func _retangulo(tex: Texture2D, r: Rect2, cor: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end,
		Vector2(r.position.x, r.end.y)])
	p.texture = tex
	p.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	p.texture_scale = Vector2(1.0 / escala_textura, 1.0 / escala_textura)
	p.color = cor
	return p


func _reavaliar(_v := false) -> void:
	var ligadas := 0
	var total := 0
	for a in get_tree().get_nodes_in_group("alavancas"):
		if a is Alavanca and a.id == id:
			total += 1
			if a.ligada:
				ligadas += 1
	var condicao := (ligadas >= maxi(total, 1)) if exige_todas else (ligadas > 0)
	if invertida:
		condicao = not condicao
	_definir_aberta(condicao)


func _definir_aberta(v: bool) -> void:
	if v == _aberta:
		return
	_aberta = v
	if _col:
		_col.set_deferred("disabled", v)
	# `porta` e' a porta de FIM DE NIVEL (e o seletor de niveis) e `selo` e' o
	# checkpoint: uma grade a subir nao e' nem uma coisa nem outra. Os dois
	# sentidos existem mesmo na mecanica (a grade sobe e volta a descer), por
	# isso ha' dois ficheiros, com o varrimento de atrito em sentidos opostos.
	Som.toca("portao_abre" if v else "portao_fecha", -10.0, 1.0, 0.04)
	var alvo_y := _altura_fechada - tamanho.y - 6.0 if v else _altura_fechada
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "position:y", alvo_y, 0.45)
	if _barras:
		tw.parallel().tween_property(_barras, "modulate:a", 0.35 if v else 1.0, 0.35)
