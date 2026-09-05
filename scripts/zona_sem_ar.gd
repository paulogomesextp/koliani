class_name ZonaSemAr
extends Area2D
## AR LIMITADO. Nível 38, Palácio das Sereias Mortas.
##
## Lá dentro ela aguenta `folego` segundos e depois começa a afogar-se --
## dano de `intervalo` em `intervalo` até sair ou até tocar numa bolsa de
## ar (`BolhaAr`, no grupo "ar"). Tocar numa bolsa enche o fôlego outra
## vez.
##
## O que a torna diferente de tudo o resto é o relógio ser DELA e não do
## cenário: nada aqui cicla, nada telegrafa. O aviso é o próprio contador,
## por isso ele tem de se ver -- há uma barra por cima dela a esvaziar.
##
## Anti-softlock: o dano é lento e sair é sempre possível (a zona não
## bloqueia nada). Uma travessia falhada custa vida, nunca a passagem.
##
## Constrói a própria área e o próprio visual: não precisa de cena.

@export var tamanho := Vector2(600.0, 300.0)
## Segundos que ela aguenta antes de começar a perder vida.
@export var folego := 5.0
@export var intervalo := 0.9
@export var dano := 8
@export var cor := Color(0.20, 0.42, 0.58, 0.22)

var _dentro: Array[Node] = []
var _resta := 0.0
var _cd := 0.0
var _calha: ColorRect
var _barra: ColorRect
var _alvo: Node2D


func _ready() -> void:
	var col := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = tamanho
	col.shape = forma
	add_child(col)
	monitoring = true
	# a Koliani vive na layer 2 (ver `Armadilha`)
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(func(c: Node) -> void:
		if not (c in _dentro):
			_dentro.append(c)
		_alvo = c as Node2D
		_resta = folego
		_cd = 0.0)
	body_exited.connect(func(c: Node) -> void:
		_dentro.erase(c)
		if _dentro.is_empty():
			_alvo = null
			_mostrar(false))
	_montar_visual()


func _montar_visual() -> void:
	var agua := ColorRect.new()
	agua.color = cor
	agua.size = tamanho
	agua.position = -tamanho * 0.5
	agua.mouse_filter = Control.MOUSE_FILTER_IGNORE
	agua.z_index = -2
	add_child(agua)
	# a barra do fôlego. Sem contador à vista, ficar sem ar lê-se como dano
	# vindo do nada -- e essa é a definição de injustiça.
	_calha = ColorRect.new()
	_calha.color = Color(0.06, 0.08, 0.12, 0.85)
	_calha.size = Vector2(64.0, 7.0)
	_calha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_calha.visible = false
	add_child(_calha)
	_barra = ColorRect.new()
	_barra.color = Color(0.45, 0.85, 1.0)
	_barra.size = Vector2(60.0, 5.0)
	_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra.visible = false
	add_child(_barra)


func _mostrar(v: bool) -> void:
	if _calha:
		_calha.visible = v
	if _barra:
		_barra.visible = v


## Está em cima de alguma bolsa de ar? (nós do grupo "ar", que é o que a
## câmara semeia -- ver `_f_ar` no gerador)
func _tem_ar(c: Node2D) -> bool:
	for b in get_tree().get_nodes_in_group("ar"):
		if b is Node2D and c.global_position.distance_to(b.global_position) < 64.0:
			return true
	return false


func _physics_process(dt: float) -> void:
	if _dentro.is_empty() or _alvo == null or not is_instance_valid(_alvo):
		return
	_mostrar(true)
	if _tem_ar(_alvo):
		_resta = folego
	else:
		_resta = maxf(0.0, _resta - dt)
	var p := to_local(_alvo.global_position) + Vector2(-32.0, -62.0)
	if _calha:
		_calha.position = p
	if _barra:
		_barra.position = p + Vector2(2.0, 1.0)
		_barra.size.x = 60.0 * (_resta / maxf(0.1, folego))
		_barra.color = Color(0.45, 0.85, 1.0) if _resta > folego * 0.3 \
			else Color(1.0, 0.4, 0.35)
	if _resta > 0.0:
		return
	_cd -= dt
	if _cd > 0.0:
		return
	_cd = intervalo
	if _alvo.has_method("receber_dano"):
		_alvo.receber_dano(dano, 0.0)
