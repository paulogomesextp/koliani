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


## 9H.17 CONTINUATION -- A TEIA PASSOU A SER UMA TEIA.
##
## O comentario antigo prometia "losango + fios" e so desenhava o losango: um
## Polygon2D chapado, cinzento, a 50% de alfa. Com o resto da Regiao I ainda
## em pixel-art isso passava; depois do passe Hybrid ficou a ler-se como o
## que era -- arte de prototipo colada por cima de arte de producao. E a
## unica coisa do plano de jogo do L3 que ainda o fazia.
##
## Agora: a membrana fica (muito mais fraca, e o que da o corpo pegajoso) e
## por cima vao os FIOS que faltavam -- raios do centro ate ao rebordo e duas
## voltas concentricas a liga-los, como uma teia de lencol. E so desenho:
## a colisao continua a ser o mesmo RectangleShape2D de `largura` x 40 em
## (0, -14), e nao ha um unico numero de jogo tocado aqui.
const TEIA_SILK := Color(0.88, 0.91, 0.98)
const TEIA_RAIOS := 7          ## raios de cada lado do centro
const TEIA_VOLTAS := [0.46, 0.80]   ## fracoes do raio onde passam as voltas

func _montar() -> void:
	var hw := largura * 0.5
	var r := RectangleShape2D.new()
	r.size = Vector2(largura, 40.0)
	_forma.shape = r
	_forma.position = Vector2(0.0, -14.0)
	# membrana: o mesmo losango, agora so uma veladura
	_visual.polygon = PackedVector2Array([
		Vector2(-hw, -2), Vector2(0, -34), Vector2(hw, -2), Vector2(0, 8),
	])
	_visual.color = Color(TEIA_SILK.r, TEIA_SILK.g, TEIA_SILK.b, 0.16)
	_montar_fios(hw)


## Os fios, como filhos do `Visual` -- assim herdam o `modulate:a` que o
## telegrafo e o desaparecimento ja animam, e nao ha um segundo tween a
## manter em sincronia.
func _montar_fios(hw: float) -> void:
	for velho in _visual.get_children():
		velho.queue_free()
	var centro := Vector2(0.0, -13.0)
	# o rebordo do losango, parametrizado: `_rebordo(t)` com t de -1 (ponta
	# esquerda) a 1 (ponta direita), passando pelo cimo em t = 0
	var rebordo := func(t: float) -> Vector2:
		var x := t * hw
		var y: float = lerpf(-34.0, -2.0, absf(t))
		if absf(t) > 0.999:
			y = -2.0
		return Vector2(x, y)
	var fio := func(pontos: PackedVector2Array, largura_fio: float,
			alfa: float) -> void:
		var l := Line2D.new()
		l.points = pontos
		l.width = largura_fio
		l.default_color = Color(TEIA_SILK.r, TEIA_SILK.g, TEIA_SILK.b, alfa)
		l.joint_mode = Line2D.LINE_JOINT_ROUND
		l.begin_cap_mode = Line2D.LINE_CAP_ROUND
		l.end_cap_mode = Line2D.LINE_CAP_ROUND
		_visual.add_child(l)
	# raios
	var ts: Array[float] = []
	for i in range(-TEIA_RAIOS, TEIA_RAIOS + 1):
		ts.append(float(i) / float(TEIA_RAIOS))
	for t in ts:
		fio.call(PackedVector2Array([centro, rebordo.call(t)]), 1.4, 0.60)
	# voltas concentricas: uma linha quebrada que salta de raio em raio
	for v: float in TEIA_VOLTAS:
		var volta := PackedVector2Array()
		for t in ts:
			volta.append(centro.lerp(rebordo.call(t), v))
		fio.call(volta, 1.2, 0.50)
	# e a base, a fechar o lencol contra o chao
	fio.call(PackedVector2Array([
		rebordo.call(-1.0), Vector2(0.0, 8.0), rebordo.call(1.0)]), 1.2, 0.45)
