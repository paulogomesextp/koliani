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
	Som.toca("porta" if v else "selo", -8.0, 0.9)
	var alvo_y := _altura_fechada - tamanho.y - 6.0 if v else _altura_fechada
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "position:y", alvo_y, 0.45)
	if _barras:
		tw.parallel().tween_property(_barras, "modulate:a", 0.35 if v else 1.0, 0.35)
