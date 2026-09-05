class_name Iman
extends Area2D
## ÍMAN: enquanto a Koliani está dentro do campo, é puxada para o núcleo --
## ou empurrada para longe dele, alternando em ciclo. Nível 60, Coração da
## Máquina.
##
## Irmão da `CorrenteLateral` (que empurra sempre para o mesmo lado): aqui o
## que interessa é o sentido MUDAR com o cenário parado, e o salto ter de
## ser dado no meio certo do ciclo. Como ela, não chama nada da Koliani --
## soma à `velocity` dela e o atrito dela trata do resto, portanto serve
## qualquer `CharacterBody2D`.
##
## Constrói a própria área e o próprio visual: não precisa de cena.

## Raio do campo, em px.
@export var raio := 190.0
## Aceleração no eixo, em px/s². Positivo = ATRAI para o núcleo.
@export var forca := 620.0
## Segundos de cada meio-ciclo (atrair / repelir). 0 = nunca inverte.
@export var periodo := 2.6
## Quanto o íman consegue impor sozinho, em px/s. Sem tecto, um campo
## grande acabava por atirar a Koliani sem ela poder fazer nada.
@export var vel_max := 260.0
@export var cor := Color(0.72, 0.55, 1.0, 0.14)

var _dentro: Array[Node] = []
var _t := 0.0
var _sinal := 1.0
var _nucleo: Polygon2D
var _aro: Line2D


func _ready() -> void:
	var col := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = raio
	col.shape = forma
	add_child(col)
	monitoring = true
	body_entered.connect(func(c: Node) -> void:
		if c is CharacterBody2D and not (c in _dentro):
			_dentro.append(c))
	body_exited.connect(func(c: Node) -> void:
		_dentro.erase(c))
	_montar_visual()


func _montar_visual() -> void:
	var disco := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		pts.append(Vector2(cos(a), sin(a)) * raio)
	disco.polygon = pts
	disco.color = cor
	add_child(disco)

	_aro = Line2D.new()
	var apts := PackedVector2Array()
	for i in 25:
		var a := TAU * float(i) / 24.0
		apts.append(Vector2(cos(a), sin(a)) * raio)
	_aro.points = apts
	_aro.width = 2.0
	_aro.default_color = Color(cor.r, cor.g, cor.b, 0.55)
	add_child(_aro)

	# o núcleo: a cor dele É o telégrafo do sentido (magenta puxa, azul
	# empurra). Sem isto o campo era invisível e a Koliani só sentia.
	_nucleo = Polygon2D.new()
	var npts := PackedVector2Array()
	for i in 12:
		var a := TAU * float(i) / 12.0
		npts.append(Vector2(cos(a), sin(a)) * 13.0)
	_nucleo.polygon = npts
	add_child(_nucleo)
	_pintar()


func _pintar() -> void:
	var c := Color(1.0, 0.27, 0.94) if _sinal > 0.0 else Color(0.4, 0.78, 1.0)
	if _nucleo:
		_nucleo.color = c
	if _aro:
		_aro.default_color = Color(c.r, c.g, c.b, 0.5)


func _physics_process(dt: float) -> void:
	if periodo > 0.0:
		_t += dt
		if _t >= periodo:
			_t = 0.0
			_sinal = -_sinal
			_pintar()
	for c in _dentro:
		var corpo := c as CharacterBody2D
		if corpo == null:
			continue
		var d := global_position - corpo.global_position
		if d.length() < 4.0:
			continue
		var dir := d.normalized() * _sinal
		var v := corpo.velocity + dir * forca * dt
		# o tecto aplica-se só ao que o íman acrescenta: o que ela ganhar
		# por cima disto continua a ser dela
		if v.length() > vel_max and v.length() > corpo.velocity.length():
			v = v.normalized() * maxf(vel_max, corpo.velocity.length())
		corpo.velocity = v
