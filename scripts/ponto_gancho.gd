class_name PontoGancho
extends Area2D
## TREPADEIRA onde a Koliani se engata e BALANÇA. Nível 53, Jardim das
## Almas -- o "gancho" que o Paulo não quis cortar da lista dos grandes.
##
## **Não há botão novo.** Ela engata ao passar por aqui NO AR e larga com
## o botão de saltar, que já tem. Num telemóvel, um botão a mais é um
## polegar a mais, e este jogo joga-se com dois.
##
## Só engata no ar de propósito: a passar por baixo a pé não acontece
## nada, e por isso uma trepadeira pendurada por cima de um caminho normal
## nunca estraga esse caminho.
##
## A física do balanço vive em `Movimento.balanco` (pura, testada); a
## Koliani trata do estado em `engatar()` / `largar_gancho()`. Este nó só
## decide QUANDO se engata e desenha a corda.
##
## Constrói a própria área e o próprio visual: não precisa de cena.

## Comprimento da corda, em px. 0 = a distância a que ela chegou.
@export var comprimento := 130.0
## Raio da bolsa de engate.
@export var raio := 34.0
@export var cor := Color(0.36, 0.52, 0.26)

var _corda: Line2D
var _presa: Node2D


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
	body_entered.connect(_ao_tocar)
	_montar_visual()


func _montar_visual() -> void:
	# a trepadeira pendurada, no comprimento certo: vê-se ao que se chega
	# antes de saltar, que é o mínimo para isto ser justo
	_corda = Line2D.new()
	_corda.points = PackedVector2Array([
		Vector2.ZERO, Vector2(0.0, maxf(40.0, comprimento))])
	_corda.width = 4.0
	_corda.default_color = Color(cor.r, cor.g, cor.b, 0.85)
	add_child(_corda)
	for i in 5:
		var folha := Polygon2D.new()
		var yy := 22.0 + float(i) * (maxf(40.0, comprimento) - 30.0) / 5.0
		var lado := 1.0 if i % 2 == 0 else -1.0
		folha.polygon = PackedVector2Array([
			Vector2(0.0, yy), Vector2(lado * 13.0, yy - 7.0),
			Vector2(lado * 9.0, yy + 6.0)])
		folha.color = Color(cor.r * 1.2, cor.g * 1.15, cor.b, 0.8)
		add_child(folha)
	# o nó de engate, no topo: é o ponto à volta do qual ela roda
	var no := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 10:
		var a := TAU * float(k) / 10.0
		pts.append(Vector2(cos(a), sin(a)) * 9.0)
	no.polygon = pts
	no.color = Color(0.72, 0.55, 0.30)
	add_child(no)


func _ao_tocar(corpo: Node) -> void:
	if not corpo.has_method("engatar"):
		return
	# só no ar: a passar por baixo a pé não acontece nada
	if corpo.has_method("is_on_floor") and corpo.call("is_on_floor"):
		return
	_presa = corpo as Node2D
	corpo.call("engatar", global_position, comprimento)


func _process(_dt: float) -> void:
	# a corda acompanha-a enquanto estiver pendurada; solta, volta a
	# pender a direito
	if _corda == null:
		return
	var alvo := Vector2(0.0, maxf(40.0, comprimento))
	if _presa and is_instance_valid(_presa) and bool(_presa.get("_gancho_ativo")):
		alvo = to_local(_presa.global_position)
	elif _presa:
		_presa = null
	_corda.points = PackedVector2Array([Vector2.ZERO, alvo])
