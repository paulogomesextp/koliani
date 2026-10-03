class_name ArenaSelada
extends Area2D
## SALA QUE FECHA ATÉ LIMPAR (`mec.arena`, DEC-013). Quando a Koliani entra
## na área, sobem duas grades (esquerda/direita) e só descem quando TODOS os
## inimigos do encontro morrem. Opt-in por colocação: não mexe em nenhum
## sistema global, só existe onde um nível a pôr.
##
## Os inimigos do encontro são os filhos `DemonioBase` deste nó (é o que o
## gerador do nível escreve) mais os que estiverem no grupo `grupo_inimigos`.
## Morrer recarrega a cena (`koliani.gd::_morrer`), por isso a arena não
## guarda estado: renasce aberta, com os inimigos todos, como o resto.
##
## Inimigo que cai ao vazio/sai da árvore conta como morto -- uma arena nunca
## pode ficar fechada para sempre (softlock). Por segurança extra, se passar
## `limite_seg` com a grade fechada, ela abre na mesma.

signal fechou
signal abriu

## Retângulo da sala (px, centrado no nó): a área de entrada e as grades.
@export var tamanho := Vector2(560.0, 260.0)
## Altura das grades (a partir do chão da sala, para cima).
@export var altura_grade := 220.0
## Inimigos extra (fora dos filhos) por grupo. Vazio = só os filhos.
@export var grupo_inimigos := ""
## Rede de segurança contra softlock (s). 0 = sem limite.
@export var limite_seg := 90.0
## Cor das barras (luz fria da Torre dos Ecos por omissão).
@export var cor_grade := Color(0.62, 0.66, 0.95, 0.95)

var _inimigos: Array[int] = []  # instance_id: objeto libertado == null mente
var _fechada := false
var _concluida := false
var _grades: Array[StaticBody2D] = []
var _tempo := 0.0


func _ready() -> void:
	collision_layer = 16   # triggers
	collision_mask = 2     # jogador
	monitorable = false
	var forma := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	# a entrada só conta já DENTRO da sala (margem para as grades não
	# fecharem em cima dela)
	r.size = Vector2(maxf(40.0, tamanho.x - 120.0), tamanho.y)
	forma.shape = r
	add_child(forma)
	for c in get_children():
		if c is DemonioBase:
			_inimigos.append(c.get_instance_id())
	if grupo_inimigos != "":
		for c in get_tree().get_nodes_in_group(grupo_inimigos):
			if c is DemonioBase and not _inimigos.has(c.get_instance_id()):
				_inimigos.append(c.get_instance_id())
	for lado in [-1.0, 1.0]:
		_grades.append(_criar_grade(lado))
	body_entered.connect(_ao_entrar)


func _criar_grade(lado: float) -> StaticBody2D:
	var g := StaticBody2D.new()
	g.name = "GradeEsq" if lado < 0.0 else "GradeDir"
	g.collision_layer = 1  # mundo
	g.collision_mask = 0
	g.position = Vector2(lado * tamanho.x * 0.5, tamanho.y * 0.5 - altura_grade * 0.5)
	var col := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(24.0, altura_grade)
	col.shape = r
	col.disabled = true
	g.add_child(col)
	var vis := Node2D.new()
	vis.name = "Barras"
	for i in 3:
		var b := Polygon2D.new()
		var x := -9.0 + i * 9.0
		b.polygon = PackedVector2Array([Vector2(x - 2, -altura_grade * 0.5), Vector2(x + 2, -altura_grade * 0.5),
			Vector2(x + 2, altura_grade * 0.5), Vector2(x - 2, altura_grade * 0.5)])
		b.color = cor_grade
		vis.add_child(b)
	vis.visible = false
	g.add_child(vis)
	add_child(g)
	return g


func _vivos() -> int:
	var n := 0
	for id in _inimigos:
		var o := instance_from_id(id)
		if o != null and is_instance_valid(o) and o.is_inside_tree() \
				and not (o.get("vida") != null and int(o.get("vida")) <= 0):
			n += 1
	return n


func _ao_entrar(corpo: Node2D) -> void:
	if _fechada or _concluida or not corpo.is_in_group("koliani"):
		return
	if _vivos() == 0:
		_concluida = true
		return
	_fechar()


func _fechar() -> void:
	_fechada = true
	_tempo = 0.0
	for g in _grades:
		(g.get_child(0) as CollisionShape2D).set_deferred("disabled", false)
		var vis: Node2D = g.get_node("Barras")
		vis.visible = true
		vis.modulate.a = 0.0
		create_tween().tween_property(vis, "modulate:a", 1.0, 0.18)
	Som.toca("portao_fecha", -6.0)
	fechou.emit()


func _abrir() -> void:
	_fechada = false
	_concluida = true
	for g in _grades:
		(g.get_child(0) as CollisionShape2D).set_deferred("disabled", true)
		var vis: Node2D = g.get_node("Barras")
		var tw := create_tween()
		tw.tween_property(vis, "modulate:a", 0.0, 0.3)
		tw.tween_callback(func(): vis.visible = false)
	Som.toca("portao_abre", -6.0)
	abriu.emit()


func _physics_process(delta: float) -> void:
	if not _fechada:
		return
	_tempo += delta
	if _vivos() == 0 or (limite_seg > 0.0 and _tempo >= limite_seg):
		_abrir()


## Para testes/QA: está a bloquear a passagem agora?
func esta_fechada() -> bool:
	return _fechada
