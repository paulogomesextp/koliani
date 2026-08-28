class_name Coletavel
extends Area2D
## Item apanhável no mundo: quando a Koliani lhe toca, regista uma pista
## sobre a mãe e/ou desbloqueia uma habilidade permanente, e desaparece.
##
## Se já tinha sido apanhado numa sessão anterior (a pista/habilidade já
## está em `EstadoJogo`), nem chega a aparecer -- evita apanhar duas vezes
## o mesmo objeto ao voltar a entrar no nível.

signal apanhado(pista_id: String, habilidade_id: String)

## Id da pista a registar (vazio = não regista pista).
@export var pista_id := ""
## Id da habilidade a desbloquear (ex.: "salto_duplo"; vazio = nenhuma).
@export var habilidade_id := ""

@onready var _visual: Node2D = $Visual


func _ready() -> void:
	if _ja_obtido():
		queue_free()
		return
	body_entered.connect(_ao_entrar)


## Verdadeiro só se este coletável não tem nada de novo para dar.
func _ja_obtido() -> bool:
	var falta_pista := pista_id != "" and not EstadoJogo.pistas.has(pista_id)
	var falta_habilidade := habilidade_id != "" and not EstadoJogo.tem_habilidade(habilidade_id)
	if falta_pista or falta_habilidade:
		return false
	# nada por dar (ou o coletável está mal configurado, sem ids)
	return true


func _process(dt: float) -> void:
	# leve balanço/rotação para chamar o olho, à falta de sprite animado
	if _visual:
		_visual.rotation += dt * 1.5
		_visual.position.y = sin(float(Time.get_ticks_msec()) / 400.0) * 4.0


func _ao_entrar(corpo: Node) -> void:
	if not (corpo is Koliani):
		return
	if pista_id != "":
		EstadoJogo.registar_pista(pista_id)
	if habilidade_id != "":
		EstadoJogo.desbloquear_habilidade(habilidade_id)
	apanhado.emit(pista_id, habilidade_id)
	queue_free()
