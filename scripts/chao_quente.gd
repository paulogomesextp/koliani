class_name ChaoQuente
extends Area2D
## O CHÃO QUEIMA QUEM FICA PARADO. Nível 82, Cidade dos Demónios.
##
## Enquanto a Koliani se mexe, não acontece nada. Ao fim de `paciencia`
## segundos quase parada em cima da placa, ela acende e passa a queimar de
## `intervalo` em `intervalo`. Sair, ou simplesmente andar, apaga-a outra
## vez -- não é uma armadilha de reflexos, é uma sala que não deixa pensar
## de pé.
##
## Constrói a própria área e o próprio visual: não precisa de cena.

@export var tamanho := Vector2(320.0, 26.0)
@export var dano := 12
## Segundos quase parada antes de acender.
@export var paciencia := 1.1
## Segundos entre queimaduras, já acesa.
@export var intervalo := 0.7
## Acima desta velocidade horizontal conta como "a mexer-se".
@export var vel_parada := 26.0
@export var cor := Color(1.0, 0.42, 0.12)

var _dentro: Array[Node] = []
var _quieto := 0.0
var _cd := 0.0
var _brasa: ColorRect
var _placa: ColorRect


func _ready() -> void:
	var col := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = tamanho
	col.shape = forma
	add_child(col)
	monitoring = true
	# A Koliani vive na layer 2 (ver `Armadilha`): sem isto a area ficava
	# com a mascara de omissao (layer 1, o mundo) e NUNCA a apanhava.
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(func(c: Node) -> void:
		if c is CharacterBody2D and not (c in _dentro):
			_dentro.append(c))
	body_exited.connect(func(c: Node) -> void:
		_dentro.erase(c)
		if _dentro.is_empty():
			_quieto = 0.0
			_pintar(0.0))

	_placa = ColorRect.new()
	_placa.color = Color(0.16, 0.10, 0.09, 0.85)
	_placa.size = tamanho
	_placa.position = -tamanho * 0.5
	_placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_placa)
	# a brasa por cima: a opacidade dela É o aviso, e cresce com o tempo
	# parada. Uma placa que acendesse de repente lia-se como injustiça.
	_brasa = ColorRect.new()
	_brasa.color = Color(cor.r, cor.g, cor.b, 0.0)
	_brasa.size = tamanho
	_brasa.position = -tamanho * 0.5
	_brasa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_brasa)


func _pintar(q: float) -> void:
	if _brasa:
		_brasa.color = Color(cor.r, cor.g, cor.b, clampf(q, 0.0, 1.0) * 0.75)


func _physics_process(dt: float) -> void:
	if _dentro.is_empty():
		return
	var mexeu := false
	for c in _dentro:
		var corpo := c as CharacterBody2D
		if corpo and absf(corpo.velocity.x) > vel_parada:
			mexeu = true
	if mexeu:
		_quieto = maxf(0.0, _quieto - dt * 2.0)   # arrefece a dobrar
		_cd = 0.0
		_pintar(_quieto / maxf(0.01, paciencia))
		return
	_quieto += dt
	_pintar(_quieto / maxf(0.01, paciencia))
	if _quieto < paciencia:
		return
	_cd -= dt
	if _cd > 0.0:
		return
	_cd = intervalo
	for c in _dentro:
		if c.has_method("receber_dano"):
			c.receber_dano(dano, 0.0)
