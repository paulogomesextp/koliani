class_name Coletavel
extends Area2D
## Item apanhável no mundo: quando a Koliani lhe toca, desbloqueia uma
## habilidade permanente e desaparece, mostrando uma FAIXA "SKILL" por cima.
##
## O sistema de PISTAS foi retirado do jogo a pedido do Paulo (ago 2026):
## um coletável que só dava pista (`habilidade_id` vazio) já nem aparece.
## `pista_id` fica no `@export` só para as cenas antigas não darem erro.
##
## Se a habilidade já foi obtida numa sessão anterior, nem chega a aparecer
## -- evita apanhar duas vezes o mesmo objeto ao reentrar no nível.

signal apanhado(pista_id: String, habilidade_id: String)

## Mantido por compatibilidade com as cenas antigas -- IGNORADO (o Diário
## de pistas saiu do jogo).
@export var pista_id := ""
## Id da habilidade a desbloquear (ex.: "salto_duplo"; vazio = nenhuma).
@export var habilidade_id := ""

@onready var _visual: Node2D = $Visual
@onready var _luz: PointLight2D = $Luz

var _t := 0.0


func _ready() -> void:
	if _ja_obtido():
		queue_free()
		return
	body_entered.connect(_ao_entrar)
	_montar_visual()


## Verdadeiro se este coletável não tem NADA de novo para dar. Sem
## habilidade a desbloquear (ex.: era só uma pista) -> nunca aparece.
func _ja_obtido() -> bool:
	if habilidade_id == "":
		return true
	return EstadoJogo.tem_habilidade(habilidade_id)


# --- visual ---------------------------------------------------------

func _montar_visual() -> void:
	if _visual == null:
		return
	for c in _visual.get_children():
		c.queue_free()
	_faixa_skill()
	_pintar_luz(Color(0.55, 1.0, 0.85), 1.9)


func _pintar_luz(cor: Color, energia: float) -> void:
	if _luz:
		_luz.color = cor
		_luz.energy = energia


func _poly(pts: PackedVector2Array, cor: Color, z := 0) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = cor
	p.z_index = z
	_visual.add_child(p)
	return p


## Gema do coletável (habilidade nova). Já teve uma faixa/placa "SKILL" a
## flutuar por cima -- o Paulo achou que lia como uma caixa solta em cima
## das plataformas e pediu para tirar; fica só a gema, com o brilho da luz
## a dizer "isto apanha-se".
func _faixa_skill() -> void:
	# gema pequena na base -- dá "corpo" ao coletável ao nível do chão
	var gema := PackedVector2Array([
		Vector2(0, -6), Vector2(5, 2), Vector2(0, 9), Vector2(-5, 2)])
	_poly(gema, Color(0.05, 0.12, 0.10), 0)
	var gema_in := PackedVector2Array()
	for v in gema:
		gema_in.append(v * 0.66)
	_poly(gema_in, Color(0.7, 1.0, 0.9), 1)


func _process(dt: float) -> void:
	_t += dt
	if _visual:
		_visual.position.y = sin(_t * 2.4) * 4.0
		var s := 1.0 + 0.06 * sin(_t * 4.0)
		_visual.scale = Vector2(s, s)
	if _luz:
		_luz.energy = 1.9 * (0.85 + 0.15 * sin(_t * 5.0))
	var faixa := _visual.get_node_or_null("Faixa") if _visual else null
	if faixa:
		faixa.scale = Vector2.ONE * (1.0 + 0.05 * sin(_t * 4.0))


func _ao_entrar(corpo: Node) -> void:
	if not (corpo is Koliani):
		return
	if habilidade_id != "":
		EstadoJogo.desbloquear_habilidade(habilidade_id)
	Som.toca("apanhar", -6.0)
	apanhado.emit(pista_id, habilidade_id)
	queue_free()
