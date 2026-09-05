class_name ZonaAfunda
extends Area2D
## Areia (ou neve) que **afunda**: enquanto ela lá está pesa mais e anda
## mais devagar. Sai-se saltando -- mas o salto de lá de dentro é mais
## curto, e é isso que faz a decisão.
##
## ⚠ A primeira versão empurrava-lhe a posição para baixo (`position.y +=`).
## Não funciona, e a bancada provou-o: pousada em chão sólido não há para
## onde afundar, e o `move_and_slide` dela desfaz o empurrão no mesmo
## frame. O afundamento sente-se pelo PESO, que é a mesma conta -- quanto
## se salta e quanto se demora a cair -- e usa os ganchos que já existem e
## já estão provados (`definir_grav_escala`, o mesmo da `ZonaGravidade`).
##
## Linha do catálogo do Paulo que faltava ("neve ou areia que afunda").
## Irmã da `ZonaGelo`, que muda o atrito, e da `ZonaGravidade`, que muda o
## peso: esta puxa para baixo com o tempo.
##
## Não mata. Uma coisa que afunda até matar é um líquido mortal, e esses já
## existem -- e um poço que mata sem aviso lê-se como bug.
##
## Constrói a própria área e o próprio visual.

@export var tamanho := Vector2(320.0, 90.0)
## Quanto pesa lá dentro (1.0 = normal). O tecto do `definir_grav_escala`
## é 1.5.
@export var peso := 1.45
## Quanto lhe fica da aceleração horizontal lá dentro.
@export var escala_acel := 0.55
@export var cor := Color(0.78, 0.68, 0.44, 0.34)

var _dentro: Array[Node2D] = []


func _ready() -> void:
	add_to_group("zonas_afunda")
	var col := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = tamanho
	col.shape = forma
	add_child(col)
	# a Koliani vive na layer 2 -- sem isto a área ficava com a máscara de
	# omissão (o mundo) e nunca lhe tocava
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)
	_montar_visual()


func _montar_visual() -> void:
	var hx := tamanho.x * 0.5
	var hy := tamanho.y * 0.5
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)])
	vis.color = cor
	add_child(vis)
	# a linha de superfície, ondulada: é o que diz "isto não é chão"
	var sup := Line2D.new()
	sup.width = 3.0
	sup.default_color = Color(cor.r, cor.g, cor.b, 0.8)
	var pts := PackedVector2Array()
	var n := int(tamanho.x / 16.0)
	for i in n + 1:
		var x := -hx + float(i) * 16.0
		pts.append(Vector2(x, -hy + (2.0 if i % 2 == 0 else -2.0)))
	sup.points = pts
	add_child(sup)


func _ao_entrar(corpo: Node) -> void:
	var n := corpo as Node2D
	if n == null or not n.is_in_group("koliani"):
		return
	if n not in _dentro:
		_dentro.append(n)
	if n.has_method("definir_acel_escala"):
		n.call("definir_acel_escala", escala_acel)
	if n.has_method("definir_grav_escala"):
		n.call("definir_grav_escala", peso)


func _ao_sair(corpo: Node) -> void:
	var n := corpo as Node2D
	if n == null:
		return
	_dentro.erase(n)
	if n.has_method("definir_acel_escala"):
		n.call("definir_acel_escala", 1.0)
	if n.has_method("definir_grav_escala"):
		n.call("definir_grav_escala", 1.0)
