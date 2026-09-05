class_name Ariete
extends AnimatableBody2D
## ARÍETE: uma máquina de cerco que só anda enquanto a Koliani está
## encostada atrás dela a empurrar. Nível 93, Cerco ao Castelo.
##
## É a única cobertura da sala (as torretas disparam de frente), e por isso
## o problema não é acertar no tempo -- é decidir quanto tempo se fica atrás
## dela a ganhar terreno e quando se sai para tratar do resto. Ao chegar ao
## fim do curso arromba a porta: liga a `Alavanca` com o mesmo `id`, que é
## quem a `PortaTrancada` já sabe ouvir.
##
## Anti-softlock: o aríete NUNCA recua e nunca fica preso -- se ela se
## afastar, ele simplesmente pára onde está e espera. Não há estado em que
## a sala deixe de se poder acabar.
##
## Constrói o próprio corpo e o próprio visual: não precisa de cena.

## Liga-se à `Alavanca` com este id (que abre a `PortaTrancada`).
@export var id := "ariete_a"
## Quanto anda ao todo, em px.
@export var curso := 420.0
@export var velocidade := 58.0
@export var tamanho := Vector2(74.0, 62.0)
## Área atrás da máquina onde é preciso estar para a empurrar.
@export var zona_empurro := Vector2(70.0, 74.0)

var _andado := 0.0
var _empurrando := false
var _chegou := false
var _barra: Polygon2D


func _ready() -> void:
	var col := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = tamanho
	col.shape = forma
	add_child(col)
	_montar_visual()

	var zona := Area2D.new()
	zona.position = Vector2(-tamanho.x * 0.5 - zona_empurro.x * 0.5, 0.0)
	var zc := CollisionShape2D.new()
	var zf := RectangleShape2D.new()
	zf.size = zona_empurro
	zc.shape = zf
	zona.add_child(zc)
	add_child(zona)
	zona.body_entered.connect(func(c: Node) -> void:
		if c is CharacterBody2D and c.is_in_group("koliani"):
			_empurrando = true)
	zona.body_exited.connect(func(c: Node) -> void:
		if c is CharacterBody2D and c.is_in_group("koliani"):
			_empurrando = false)


func _montar_visual() -> void:
	var h := tamanho * 0.5
	var caixa := Polygon2D.new()
	caixa.polygon = PackedVector2Array([
		Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	caixa.color = Color(0.24, 0.19, 0.15)
	add_child(caixa)
	# o tronco à frente, ferrado: é o que diz "isto arromba"
	var tronco := Polygon2D.new()
	tronco.polygon = PackedVector2Array([
		Vector2(h.x, -9.0), Vector2(h.x + 40.0, -7.0),
		Vector2(h.x + 40.0, 7.0), Vector2(h.x, 9.0)])
	tronco.color = Color(0.33, 0.26, 0.19)
	add_child(tronco)
	var ferro := Polygon2D.new()
	ferro.polygon = PackedVector2Array([
		Vector2(h.x + 34.0, -8.0), Vector2(h.x + 46.0, -4.0),
		Vector2(h.x + 46.0, 4.0), Vector2(h.x + 34.0, 8.0)])
	ferro.color = Color(0.55, 0.56, 0.62)
	add_child(ferro)
	for lado in [-1.0, 1.0]:
		var roda := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 10:
			var a := TAU * float(i) / 10.0
			pts.append(Vector2(cos(a), sin(a)) * 13.0 + Vector2(lado * 22.0, h.y))
		roda.polygon = pts
		roda.color = Color(0.16, 0.14, 0.13)
		add_child(roda)
	# barra de progresso do cerco, por cima: sem ela não se percebe que
	# empurrar está a servir de alguma coisa
	var calha := Polygon2D.new()
	# o poligono nasce em x=0 e a calha e' que esta' deslocada: assim o
	# `scale.x` da barra enche da ESQUERDA para a direita, em vez de crescer
	# a partir do meio.
	var molde := PackedVector2Array([
		Vector2(0.0, -h.y - 16.0), Vector2(60.0, -h.y - 16.0),
		Vector2(60.0, -h.y - 10.0), Vector2(0.0, -h.y - 10.0)])
	calha.polygon = molde
	calha.position.x = -30.0
	calha.color = Color(0.1, 0.09, 0.12, 0.8)
	add_child(calha)
	_barra = Polygon2D.new()
	_barra.polygon = molde
	_barra.position.x = -30.0
	_barra.color = Color(1.0, 0.27, 0.94)
	_barra.scale.x = 0.0
	add_child(_barra)


func _physics_process(dt: float) -> void:
	if _chegou or not _empurrando:
		return
	var passo := minf(velocidade * dt, curso - _andado)
	_andado += passo
	position.x += passo
	if _barra:
		_barra.scale.x = _andado / maxf(1.0, curso)
	if _andado >= curso - 0.5:
		_arrombar()


## Abre a porta pela mao da alavanca do mesmo `id` -- e' quem a
## `PortaTrancada` ja' sabe ouvir, e assim o ariete nao precisa de saber
## nada sobre portas.
##
## Tudo aqui e' por NOME (`get`/`set`/`has_signal`) e o `Som` vai buscar-se
## a `/root`, de proposito: tocar em `Alavanca` ou em `Som` pelo
## identificador faria este script nao compilar em `--script`, e era a
## bancada (`tools/verifica_actores_novos.gd`) que ficava sem o poder
## testar. Mesma armadilha dos autoloads de sempre.
func _arrombar() -> void:
	_chegou = true
	var som := get_tree().root.get_node_or_null("/root/Som")
	if som and som.has_method("toca"):
		som.call("toca", "quebra", -6.0, 0.8)
	for a in get_tree().get_nodes_in_group("alavancas"):
		if str(a.get("id")) != id or bool(a.get("ligada")):
			continue
		a.set("ligada", true)
		if a.has_method("_aplicar"):
			a.call("_aplicar", false)
		if a.has_signal("mudou"):
			a.emit_signal("mudou", true)
