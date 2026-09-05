@tool
class_name PlataformaOlhar
extends "res://scripts/plataforma.gd"
## Plataforma que só existe enquanto a Koliani está VIRADA para ela. Nível
## 86, Primeiro Vazio.
##
## Irmã da `PlataformaEspectral` (que solidifica com a magia): aqui o que a
## segura é o olhar dela, e como ela olha sempre para onde anda, avançar
## acende o caminho à frente e apaga o que fica atrás. Virar-se para trás é
## o que faz o chão desaparecer debaixo dos pés -- é essa a mecânica, e é
## por isso que os patamares de entrada e de saída da câmara são sólidos
## normais.
##
## Nunca pode ser um softlock: virar-se é grátis e imediato, e a plataforma
## volta no mesmo frame em que ela olha outra vez.

## Alpha do contorno quando está apagada.
@export var alpha_apagada := 0.16
## Segundos que ainda aguenta depois de ela desviar o olhar -- a folga que
## torna isto jogável em vez de traiçoeiro.
@export var carencia := 0.35

var _solida := true
var _restante := 0.0

@onready var _col: CollisionShape2D = get_node_or_null("Col")


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	_aplicar_olhar(true)


func _process(dt: float) -> void:
	if Engine.is_editor_hint():
		return
	if _a_olhar():
		_restante = carencia
		if not _solida:
			_aplicar_olhar(true)
		return
	_restante -= dt
	if _restante <= 0.0 and _solida:
		_aplicar_olhar(false)


## A Koliani está virada para esta plataforma? Sem Koliani na cena a
## plataforma fica SÓLIDA -- o contrário deixava o nível intransponível
## enquanto ela não nascesse.
func _a_olhar() -> bool:
	var k := get_tree().get_first_node_in_group("koliani")
	if k == null:
		return true
	var v: Variant = k.get("_olha_para")
	if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
		return true
	var d: float = global_position.x - (k as Node2D).global_position.x
	var olha := float(v)
	# em cima dela (|d| pequeno) conta sempre como olhada: senão o chão
	# fugia-lhe por baixo dos pés a meio de um passo
	if absf(d) < 60.0:
		return true
	return (olha > 0.0 and d > 0.0) or (olha < 0.0 and d < 0.0)


## `_aplicar_olhar` e nao `_aplicar`: a `Plataforma` ja' tem um `_aplicar()`
## sem argumentos (redesenha os tiles) e o GDScript nao deixa mudar a
## assinatura de um metodo do pai.
func _aplicar_olhar(solida: bool) -> void:
	_solida = solida
	if _col:
		_col.set_deferred("disabled", not solida)
	var vis := get_node_or_null("Visual") as CanvasItem
	if vis:
		create_tween().tween_property(vis, "modulate:a",
			1.0 if solida else alpha_apagada, 0.1)
