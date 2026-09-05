class_name SombraAtrasada
extends Area2D
## A SOMBRA DELA, com atraso. Nível 69, Pesadelo.
##
## Grava o caminho da Koliani e anda por ele `atraso` segundos depois.
## Nunca decide nada: tudo o que ela faz, a sombra repete -- e é isso que
## a torna diferente de um perseguidor. Não se despista, não se combate
## (atravessa-se), e o único jeito de a manter longe é **não voltar atrás**.
## Quem pára, apanha a própria decisão de há três segundos em cima.
##
## Anti-softlock: não é sólida (só magoa por contacto, com recarga) e
## desaparece com a câmara. Como copia a rota dela, nunca vai parar a um
## sítio onde ela não tenha estado -- não pode encurralá-la num canto que
## ela própria não tenha escolhido.
##
## Constrói o próprio corpo e o próprio visual: não precisa de cena.

## Segundos de atraso entre ela e a sombra.
@export var atraso := 3.0
@export var dano := 16
## Segundos entre dois toques -- sem isto, um encontrão custava a vida toda.
@export var recarga := 1.1
@export var raio := 16.0
@export var cor := Color(0.36, 0.10, 0.46)

var _rasto: Array[Vector2] = []
var _t_rasto: Array[float] = []
var _t := 0.0
var _cd := 0.0
var _corpo: Node2D
var _alvo: Node2D


func _ready() -> void:
	var col := CollisionShape2D.new()
	var f := CircleShape2D.new()
	f.radius = raio
	col.shape = f
	add_child(col)
	monitoring = true
	# a Koliani vive na layer 2 (ver `Armadilha`)
	collision_layer = 0
	collision_mask = 2
	_montar_visual()
	visible = false          # só aparece quando já há rasto para seguir


func _montar_visual() -> void:
	_corpo = Node2D.new()
	add_child(_corpo)
	var silhueta := Polygon2D.new()
	# uma silhueta humana grosseira: chega para se ler como "ela" sem
	# precisar de arte nenhuma, e o roxo escuro diz de quem é
	silhueta.polygon = PackedVector2Array([
		Vector2(-7, -26), Vector2(7, -26), Vector2(10, -6), Vector2(6, 20),
		Vector2(1, 6), Vector2(-4, 20), Vector2(-10, -6)])
	silhueta.color = Color(cor.r, cor.g, cor.b, 0.78)
	_corpo.add_child(silhueta)
	var cabeca := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 10:
		var a := TAU * float(k) / 10.0
		pts.append(Vector2(cos(a), sin(a)) * 8.0 + Vector2(0, -32))
	cabeca.polygon = pts
	cabeca.color = Color(cor.r, cor.g, cor.b, 0.78)
	_corpo.add_child(cabeca)
	for lado in [-1.0, 1.0]:
		var olho := Polygon2D.new()
		var op := PackedVector2Array()
		for k in 6:
			var a := TAU * float(k) / 6.0
			op.append(Vector2(cos(a), sin(a)) * 2.2 + Vector2(lado * 3.4, -33.0))
		olho.polygon = op
		olho.color = Color(1.0, 0.27, 0.94)
		_corpo.add_child(olho)


func _physics_process(dt: float) -> void:
	_t += dt
	_cd = maxf(0.0, _cd - dt)
	if _alvo == null or not is_instance_valid(_alvo):
		_alvo = get_tree().get_first_node_in_group("koliani") as Node2D
		if _alvo == null:
			return
	_rasto.append(_alvo.global_position)
	_t_rasto.append(_t)
	# atira fora o que já é mais velho do que o atraso (mais uma margem):
	# o rasto é uma fila, não um histórico
	while _t_rasto.size() > 2 and _t - _t_rasto[0] > atraso + 0.5:
		_rasto.remove_at(0)
		_t_rasto.remove_at(0)

	var alvo_t := _t - atraso
	if _t_rasto.is_empty() or alvo_t < _t_rasto[0]:
		return                    # ainda não há passado suficiente
	visible = true
	var i := 0
	while i < _t_rasto.size() - 1 and _t_rasto[i + 1] < alvo_t:
		i += 1
	global_position = _rasto[i]
	if _cd > 0.0:
		return
	for c in get_overlapping_bodies():
		if c.has_method("receber_dano"):
			c.receber_dano(dano, signf(c.global_position.x - global_position.x))
			_cd = recarga
			break
