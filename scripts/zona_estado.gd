class_name ZonaEstado
extends Area2D
## Bolsa que deixa um ESTADO na Koliani: veneno (nível 48, Vale dos
## Escorpiões) ou frio (nível 45, Coração do Inverno).
##
## O que a torna diferente de uma armadilha é continuar depois de se sair:
## a `Armadilha` magoa enquanto se toca, esta marca. Sair da nuvem não
## resolve nada -- é isso que faz o jogador andar a contar segundos em vez
## de contar golpes.
##
## Renova enquanto ela lá estiver dentro (a Koliani é que trata de não
## somar estados em cima uns dos outros). Constrói a própria área e o
## próprio visual: não precisa de cena.

@export_enum("veneno", "frio") var tipo := "veneno"
@export var tamanho := Vector2(220.0, 120.0)
## Segundos de estado deixados a cada renovação.
@export var duracao := 4.0
## Dano por tique, só no veneno.
@export var dano_tick := 4
## Quão devagar fica, só no frio (1 = normal).
@export var escala_frio := 0.35

var _dentro: Array[Node] = []
var _cd := 0.0
var _nevoa: ColorRect


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
		if not (c in _dentro):
			_dentro.append(c)
		_marcar(c))
	body_exited.connect(func(c: Node) -> void:
		_dentro.erase(c))
	_montar_visual()


func _cor() -> Color:
	return Color(0.45, 0.95, 0.35) if tipo == "veneno" else Color(0.6, 0.86, 1.0)


func _montar_visual() -> void:
	var c := _cor()
	_nevoa = ColorRect.new()
	_nevoa.color = Color(c.r, c.g, c.b, 0.17)
	_nevoa.size = tamanho
	_nevoa.position = -tamanho * 0.5
	_nevoa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_nevoa)
	# bolsas a subir devagar: dizem "isto é ar, não é chão" -- sem elas a
	# nuvem lia-se como uma plataforma pintada
	var n := maxi(3, int(tamanho.x / 70.0))
	for i in n:
		var b := Polygon2D.new()
		var pts := PackedVector2Array()
		var r := randf_range(9.0, 17.0)
		for k in 8:
			var a := TAU * float(k) / 8.0
			pts.append(Vector2(cos(a), sin(a) * 0.8) * r)
		b.polygon = pts
		b.color = Color(c.r, c.g, c.b, 0.22)
		var x := -tamanho.x * 0.5 + tamanho.x * (float(i) + 0.5) / float(n)
		b.position = Vector2(x, tamanho.y * 0.4)
		add_child(b)
		var t := b.create_tween().set_loops()
		t.tween_interval(0.2 * float(i))
		t.tween_property(b, "position:y", -tamanho.y * 0.45, randf_range(2.2, 3.4))
		t.tween_property(b, "position:y", tamanho.y * 0.4, 0.01)


func _marcar(c: Node) -> void:
	if tipo == "veneno" and c.has_method("envenenar"):
		c.envenenar(duracao, dano_tick)
	elif tipo == "frio" and c.has_method("congelar_parcial"):
		c.congelar_parcial(duracao, escala_frio)


func _physics_process(dt: float) -> void:
	if _dentro.is_empty():
		return
	# renova de meio em meio segundo enquanto ela não sair: uma bolsa que
	# só marcasse à entrada resolvia-se a atravessá-la a correr
	_cd -= dt
	if _cd > 0.0:
		return
	_cd = 0.5
	for c in _dentro:
		_marcar(c)
