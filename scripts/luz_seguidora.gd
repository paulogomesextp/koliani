extends Node2D
## Luz fraca que segue a Koliani -- dá o "quase sem luz" de O Abismo
## (Região IV / nível 20) sem mexer na câmara nem na Koliani. Pôr uma
## instância de LuzSeguidora.tscn no nível; ela cola-se ao nó do grupo
## "koliani" a cada frame.

@export var suave := 14.0

var _alvo: Node2D


func _ready() -> void:
	# Persegue a Koliani no `_process`, a 165 Hz. Interpolada, a luz ficava um
	# tick atrás do que ela própria acabou de calcular -- atraso a dobrar.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(dt: float) -> void:
	if not is_instance_valid(_alvo):
		_alvo = get_tree().get_first_node_in_group("koliani")
		if _alvo:
			global_position = _alvo.global_position
		return
	global_position = global_position.lerp(_alvo.global_position, clampf(dt * suave, 0.0, 1.0))
