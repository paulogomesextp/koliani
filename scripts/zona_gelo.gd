class_name ZonaGelo
extends Area2D
## CHÃO ESCORREGADIO. Nível 41, Floresta Congelada.
##
## Irmã da `ZonaGravidade` (que muda o peso): esta muda o ATRITO. Enquanto
## a Koliani está lá dentro, a aceleração horizontal dela passa a `escala`
## -- e como a travagem usa a mesma aceleração, custa a arrancar e custa a
## parar, que são as duas metades da sensação de gelo. Ao sair volta a 1.
##
## Nunca desce abaixo de 0.15 (a `Koliani.definir_acel_escala` trava lá):
## mais do que isso e ela deixava de conseguir mudar de sentido a tempo de
## seja o que for, e o gelo passava de mecânica a castigo.
##
## Constrói a própria área e o próprio visual: não precisa de cena.

@export var tamanho := Vector2(320.0, 60.0)
@export var escala := 0.3
@export var cor := Color(0.62, 0.86, 1.0, 0.20)


func _ready() -> void:
	var col := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = tamanho
	col.shape = forma
	add_child(col)
	# A Koliani vive na layer 2 (ver `Armadilha`): sem isto a area ficava
	# com a mascara de omissao (layer 1, o mundo) e NUNCA a apanhava.
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)
	_montar_visual()


## A placa e os brilhos. Sem isto o gelo era invisível e o jogador só
## sentia que os controlos tinham partido -- que é como se lê uma mecânica
## que não se vê.
func _montar_visual() -> void:
	var placa := ColorRect.new()
	placa.color = cor
	placa.size = tamanho
	placa.position = -tamanho * 0.5
	placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(placa)
	var topo := ColorRect.new()
	topo.color = Color(0.86, 0.96, 1.0, 0.55)
	topo.size = Vector2(tamanho.x, 3.0)
	topo.position = Vector2(-tamanho.x * 0.5, -tamanho.y * 0.5)
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(topo)
	var n := int(tamanho.x / 90.0)
	for i in n:
		var risco := Line2D.new()
		var x := -tamanho.x * 0.5 + tamanho.x * (float(i) + 0.5) / float(maxi(1, n))
		var y := -tamanho.y * 0.5 + 6.0
		risco.points = PackedVector2Array([
			Vector2(x - 14.0, y + 3.0), Vector2(x + 14.0, y)])
		risco.width = 2.0
		risco.default_color = Color(1, 1, 1, 0.35)
		add_child(risco)


func _ao_entrar(corpo: Node) -> void:
	if corpo.has_method("definir_acel_escala"):
		corpo.definir_acel_escala(escala)


func _ao_sair(corpo: Node) -> void:
	if corpo.has_method("definir_acel_escala"):
		corpo.definir_acel_escala(1.0)
