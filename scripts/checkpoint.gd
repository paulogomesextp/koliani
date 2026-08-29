class_name Checkpoint
extends Area2D
## Guarda a posição de reaparecimento. A Koliani reaparece aqui enquanto
## tiver vidas; ao ficar sem vidas a campanha reinicia (ver
## `EstadoJogo.reiniciar_campanha`).

@onready var _luz: Node2D = $Luz

var _ativo := false


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	if EstadoJogo.checkpoint.is_equal_approx(global_position):
		_ativar()


func _ao_entrar(corpo: Node) -> void:
	if corpo is Koliani and not _ativo:
		_ativar()
		EstadoJogo.definir_checkpoint(global_position)
		Som.toca("selo", -12.0)


func _ativar() -> void:
	_ativo = true
	if _luz:
		_luz.visible = true
