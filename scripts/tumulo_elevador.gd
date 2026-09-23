class_name TumuloElevador
extends AnimatableBody2D
## Laje de túmulo que funciona como elevador (Região IV / nível 16 --
## Cemitério dos Reis). `AnimatableBody2D` com `sync_to_physics` -> carrega
## a Koliani. Sobe (percorre `curso`) enquanto ela está em cima e volta ao
## sítio quando ela sai. `auto = true` = vaivém contínuo entre os dois
## extremos (elevador de mão dupla). Grupo "tumulos".

## Deslocamento total a partir da base (px). Negativo em y = sobe.
@export var curso := Vector2(0.0, -200.0)
@export var velocidade := 90.0
## true = anda sempre entre base e base+curso; false = só com peso em cima.
@export var auto := false
@export var largura := 150.0 : set = _set_largura

## O laco de MARCHA e' partilhado por todos os elevadores do nivel: uma
## camara com tres tumulos a subir nao sao tres motores, e' um mecanismo.
const LACO_MARCHA := "mecanismo_ciclo"
## Abaixo disto (px) considera-se parado. Sem margem, o `move_toward` a
## chegar ao destino oscilava entre "anda" e "para" e o laco piscava.
const PARADO := 1.5

var _base := Vector2.ZERO
var _dir := 1.0        # 1 = a ir para base+curso ; -1 = a voltar
var _peso := 0
var _som: Node
var _andava := false

@onready var _forma: CollisionShape2D = $Col
@onready var _visual: Polygon2D = $Visual
@onready var _deteta: Area2D = $Deteta


func _ready() -> void:
	add_to_group("tumulos")
	sync_to_physics = true
	_base = global_position
	_som = get_node_or_null("/root/Som")
	_reconstruir()
	_deteta.body_entered.connect(func(c: Node) -> void:
		if c is Koliani:
			_peso += 1)
	_deteta.body_exited.connect(func(c: Node) -> void:
		if c is Koliani:
			_peso = maxi(0, _peso - 1))


func _physics_process(dt: float) -> void:
	var alvo: Vector2
	if auto:
		if global_position.distance_to(_base) < 2.0:
			_dir = 1.0
		elif global_position.distance_to(_base + curso) < 2.0:
			_dir = -1.0
		alvo = (_base + curso) if _dir > 0.0 else _base
	else:
		alvo = (_base + curso) if _peso > 0 else _base
	# "anda" e' ter para onde ir, e nao "mexeu-se desde a linha anterior".
	# Com `sync_to_physics = true` o `AnimatableBody2D` so' aplica a
	# transformada no passo de fisica seguinte, por isso ler `global_position`
	# logo a seguir a` atribuicao devolve a POSICAO ANTIGA -- media-se sempre
	# deslocamento zero e o laco nunca arrancava, com a laje a subir a' vista.
	_som_marcha(global_position.distance_to(alvo) > PARADO)
	global_position = global_position.move_toward(alvo, velocidade * dt)


## START / LOOP / STOP -- os tres eventos que a Fase 4 pede, e so' esses.
## Nao ha' "ACTIVATE" nem "COMPLETE" separados porque a mecanica nao os tem:
## a laje ou anda ou nao anda, e chegar ao topo nao e' um evento (volta a
## descer assim que a Koliani sai).
func _som_marcha(anda: bool) -> void:
	if anda == _andava or _som == null:
		return
	_andava = anda
	if anda:
		if _som.has_method("toca"):
			_som.call("toca", "mecanismo", -15.0, 0.80, 0.03,
				0.5, "elevador_%d" % get_instance_id())
		if _som.has_method("laco"):
			_som.call("laco", LACO_MARCHA, -24.0, 0.35)
	else:
		_parar_marcha()


## O batente no fim do curso + fechar o laco. Nunca deixa o laco aberto: e'
## chamado tanto ao parar como ao sair da arvore, e o `Som` so' fecha o canal
## quando o ULTIMO elevador o larga.
func _parar_marcha() -> void:
	if _som == null:
		return
	if _som.has_method("toca"):
		_som.call("toca", "mecanismo", -17.0, 0.62, 0.03,
			0.5, "elevador_fim_%d" % get_instance_id())
	if not _som.has_method("parar_laco"):
		return
	if is_inside_tree():
		for outro in get_tree().get_nodes_in_group("tumulos"):
			if outro != self and is_instance_valid(outro) and outro.get("_andava"):
				return
	_som.call("parar_laco", LACO_MARCHA, 0.3)


func _exit_tree() -> void:
	if _andava:
		_andava = false
		_parar_marcha()


func _set_largura(v: float) -> void:
	largura = maxf(48.0, v)
	if is_node_ready():
		_reconstruir()


func _reconstruir() -> void:
	if _forma == null or _visual == null or _deteta == null:
		return
	var hw := largura * 0.5
	var r := RectangleShape2D.new()
	r.size = Vector2(largura, 26.0)
	_forma.shape = r
	_forma.position = Vector2(0.0, 5.0)
	_visual.polygon = PackedVector2Array([
		Vector2(-hw, -12), Vector2(hw, -12),
		Vector2(hw - 6, 18), Vector2(-hw + 6, 18),
	])
	var d := _deteta.get_node_or_null("Forma") as CollisionShape2D
	if d:
		var dr := RectangleShape2D.new()
		dr.size = Vector2(largura - 12.0, 20.0)
		d.shape = dr
		d.position = Vector2(0.0, -18.0)
