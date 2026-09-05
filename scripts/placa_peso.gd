class_name PlacaPeso
extends Alavanca
## Placa de pressão: fica ligada enquanto tiver **peso** em cima -- a
## Koliani ou, melhor ainda, um `BlocoEmpurravel`.
##
## É o "pedestal" do catálogo do Paulo, e é a razão de ser da caixa: a placa
## que se solta assim que ela sai obriga a lá pôr outra coisa.
##
## Herda da `Alavanca` DE PROPÓSITO. A `PortaTrancada` liga-se ao grupo
## "alavancas" e testa `a is Alavanca`; herdar dá-lhe o `id`, o sinal
## `mudou` e a porta sem tocar numa linha do outro lado.
##
## `so_liga = true` continua a funcionar: nesse caso a primeira vez que
## alguma coisa lhe pousa em cima é definitiva.

## Espera este tanto antes de se soltar. Sem isto, ela a saltar em cima da
## placa fazia a porta piscar.
@export var atraso_soltar := 0.25

var _placa: Polygon2D
var _vazia_ha := 0.0


func _ready() -> void:
	add_to_group("alavancas")
	_montar_placa()
	# A área é a PRÓPRIA placa, e não uma filha. Com uma área filha, a
	# `Area2D` que a `Alavanca` traz por herança ficava sem uso e com a
	# máscara de omissão (layer 1) -- o `verifica_mecanicas.gd` acusou-a, e
	# com razão: uma área morta na árvore é uma armadilha para quem vier a
	# seguir. Aqui não se liga o `body_entered` da `Alavanca` (o `_ready`
	# dela não corre): o que interessa é quem está EM CIMA, agora.
	collision_layer = 0
	collision_mask = 3   # 1 = o mundo (a caixa) + 2 = a Koliani
	var col := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(64.0, 26.0)
	col.shape = r
	col.position = Vector2(0.0, -14.0)
	add_child(col)
	_pintar()


func _montar_placa() -> void:
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-34, 0), Vector2(34, 0), Vector2(30, 10), Vector2(-30, 10)])
	base.color = Color(0.16, 0.14, 0.2)
	add_child(base)
	_placa = Polygon2D.new()
	_placa.polygon = PackedVector2Array([
		Vector2(-28, -8), Vector2(28, -8), Vector2(24, 0), Vector2(-24, 0)])
	_placa.color = COR_OFF
	add_child(_placa)


func _process(dt: float) -> void:
	var peso := false
	for c in get_overlapping_bodies():
		# pelo GRUPO e não pelo tipo: `is Koliani` arrastava o `koliani.gd`,
		# que fala com autoloads e não compila em `--script`
		if c is BlocoEmpurravel or (c is Node and c.is_in_group("koliani")):
			peso = true
			break
	if peso:
		_vazia_ha = 0.0
		if not ligada:
			_mudar(true)
	elif ligada and not so_liga:
		_vazia_ha += dt
		if _vazia_ha >= atraso_soltar:
			_mudar(false)


func _mudar(v: bool) -> void:
	ligada = v
	# `Som` pelo caminho e não pelo IDENTIFICADOR: um actor que toque num
	# autoload pelo nome não compila em `--script`, e a bancada passava a
	# dizer "falhou a compilar" em vez de medir a placa.
	var som := get_node_or_null("/root/Som")
	if som and som.has_method("toca"):
		som.call("toca", "selo", -12.0, 1.15 if v else 0.85)
	_pintar()
	mudou.emit(ligada)


func _pintar() -> void:
	if _placa == null:
		return
	_placa.color = COR_ON if ligada else COR_OFF
	# afunda 5 px quando carregada: é o que se lê à distância
	_placa.position.y = 5.0 if ligada else 0.0
