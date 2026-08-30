class_name TeiaPrende
extends Area2D
## Mancha de teia pegajosa. Mecânica partilhada da Região I (Ninho da Viúva
## Negra) e da Rainha Aracnídea: telegrafa, assenta no chão e, enquanto lá
## estiver, PRENDE a Koliani (`Koliani.prender`) — ela não anda nem salta
## até se soltar. Some sozinha passado `dur_ativa`.
##
## Uso: instanciar, pousar em `global_position` (centro da mancha) e chamar
## `lancar(atraso, dur_preso)`. O escudo erguido protege de ficar presa.

@export var largura := 120.0
@export var atraso := 0.35
@export var dur_ativa := 3.5
## true = teia fixa do cenário (fica sempre ativa, sem telegrafo nem
## auto-destruição). Usada nas cenas de nível; a Rainha Aracnídea deixa
## `false` e chama `lancar()`.
@export var permanente := false
## Quanto tempo a Koliani fica presa de cada vez que toca na teia.
@export var dur_preso := 0.7
## Dano leve ao ficar presa (0 = só prende).
@export var dano := 0

@onready var _forma: CollisionShape2D = $CollisionShape2D
@onready var _visual: Polygon2D = $Visual

var _ativa := false
var _iniciado := false


func _ready() -> void:
	monitoring = false
	_montar()
	_visual.modulate.a = 0.0
	body_entered.connect(_ao_tocar)
	if permanente:
		_iniciado = true
		_ativa = true
		monitoring = true
		_visual.modulate.a = 0.85
		return
	get_tree().create_timer(6.0).timeout.connect(func() -> void:
		if not _iniciado:
			queue_free())


func lancar(atraso_: float = -1.0, dur_preso_: float = -1.0) -> void:
	if _iniciado:
		return
	_iniciado = true
	if atraso_ >= 0.0:
		atraso = atraso_
	if dur_preso_ >= 0.0:
		dur_preso = dur_preso_
	var t := create_tween()
	t.tween_property(_visual, "modulate:a", 0.35, atraso * 0.6)
	t.tween_property(_visual, "modulate:a", 0.9, atraso * 0.4)
	t.tween_callback(func() -> void:
		_ativa = true
		monitoring = true
		_prender_presentes())
	t.tween_interval(dur_ativa)
	t.tween_callback(func() -> void:
		_ativa = false
		monitoring = false)
	t.tween_property(_visual, "modulate:a", 0.0, 0.4)
	t.tween_callback(queue_free)


func _process(_dt: float) -> void:
	# enquanto a teia está ativa, quem lá estiver continua preso
	if _ativa:
		_prender_presentes()


func _prender_presentes() -> void:
	for c in get_overlapping_bodies():
		if c is Koliani:
			c.prender(dur_preso)


func _ao_tocar(corpo: Node) -> void:
	if _ativa and corpo is Koliani:
		corpo.prender(dur_preso)
		if dano > 0:
			corpo.receber_dano(dano)


func _montar() -> void:
	var hw := largura * 0.5
	var r := RectangleShape2D.new()
	r.size = Vector2(largura, 40.0)
	_forma.shape = r
	_forma.position = Vector2(0.0, -14.0)
	# malha simples de teia (losango + fios)
	_visual.polygon = PackedVector2Array([
		Vector2(-hw, -2), Vector2(0, -34), Vector2(hw, -2), Vector2(0, 8),
	])
	_visual.color = Color(0.85, 0.88, 0.95, 0.5)
