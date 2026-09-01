class_name ZonaGravidade
extends Area2D
## Bolsa de "gravidade lunar" do Observatório Lunar (Região III / nível 14).
## Enquanto a Koliani está lá dentro, a gravidade dela passa a `escala`
## (salto alto, queda lenta); ao sair volta a 1. Mecânica partilhada e
## reutilizável -- ver `Koliani.definir_grav_escala`.

@export var escala := 0.42

@onready var _poeira: CPUParticles2D = get_node_or_null("Poeira")


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)


func _ao_entrar(corpo: Node) -> void:
	if corpo is Koliani and corpo.has_method("definir_grav_escala"):
		corpo.definir_grav_escala(escala)


func _ao_sair(corpo: Node) -> void:
	if corpo is Koliani and corpo.has_method("definir_grav_escala"):
		corpo.definir_grav_escala(1.0)
