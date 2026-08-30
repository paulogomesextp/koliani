class_name SinoTorre
extends StaticBody2D
## Sino da Torre dos Sinos (Região III / nível 11). Mecânica partilhada:
## bater-lhe (golpe ou projétil da Koliani -- ambos chamam `receber_dano`)
## faz a BADALADA:
##   * alterna o estado de todas as plataformas do grupo "sino_alterna"
##     (colisão + visual): as que estavam sólidas somem, as fantasma
##     ficam sólidas -- o cenário "muda ao som do sino";
##   * gela por uns segundos os inimigos comuns (grupo "inimigos", exceto
##     "chefes") -- ver `DemonioBase.congelar`.
## `recarga` evita disparar várias vezes com o mesmo golpe.
##
## Está na layer 4 (como os inimigos) só para o hitbox/projétil da Koliani
## lhe acertarem; não colide com ninguém fisicamente.

@export var congelar_inimigos := 2.6
@export var recarga := 0.5
## Grupo das plataformas que este sino alterna. Sinos diferentes podem
## controlar secções diferentes.
@export var alterna_grupo := "sino_alterna"
## true = este sino só gela inimigos, não mexe em plataformas nenhumas
## (útil para não baralhar outras secções).
@export var so_congela := false

var _cd := 0.0

@onready var _badalo: Node2D = get_node_or_null("Badalo")


func _ready() -> void:
	add_to_group("sinos")


func _process(dt: float) -> void:
	if _cd > 0.0:
		_cd -= dt


func receber_dano(_quantidade: int = 0, _dir: float = 0.0) -> void:
	if _cd > 0.0:
		return
	_cd = recarga
	tocar()


func tocar() -> void:
	Som.toca("selo", -6.0, 0.65)
	Som.toca("onda", -12.0, 0.5)
	if _badalo:
		var t := create_tween()
		t.tween_property(_badalo, "rotation", 0.5, 0.06)
		t.tween_property(_badalo, "rotation", -0.4, 0.12)
		t.tween_property(_badalo, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	_onda()
	if not so_congela:
		for p in get_tree().get_nodes_in_group(alterna_grupo):
			_alternar(p)
	for e in get_tree().get_nodes_in_group("inimigos"):
		if (e as Node).is_in_group("chefes"):
			continue
		if e.has_method("congelar"):
			e.congelar(congelar_inimigos)
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(3.0)


func _alternar(p: Node) -> void:
	var col := p.get_node_or_null("Col") as CollisionShape2D
	if col == null:
		return
	var vai_ficar_solida := col.disabled  # estava desligada -> passa a sólida
	col.set_deferred("disabled", not col.disabled)
	var vis := p.get_node_or_null("Visual") as CanvasItem
	if vis:
		create_tween().tween_property(vis, "modulate:a", 1.0 if vai_ficar_solida else 0.16, 0.14)


func _onda() -> void:
	var anel := Line2D.new()
	anel.width = 3.0
	anel.default_color = Color(0.8, 0.85, 1.0, 0.7)
	anel.closed = true
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		pts.append(Vector2(cos(a), sin(a)) * 10.0)
	anel.points = pts
	add_child(anel)
	var t := anel.create_tween()
	t.tween_property(anel, "scale", Vector2(14, 14), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(anel, "modulate:a", 0.0, 0.5)
	t.tween_callback(anel.queue_free)
