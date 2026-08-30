class_name CorrenteAr
extends Area2D
## Corrente de ar ascendente da Torre dos Ventos (Região III / nível 12).
## Enquanto a Koliani está lá dentro, é empurrada para cima até uma
## velocidade-alvo (`Koliani.soprar_para_cima`) -- serve para alcançar
## plataformas suspensas altas. Mecânica partilhada e reutilizável.

@export var forca := 3200.0
@export var vel_alvo := 520.0

@onready var _poeira: CPUParticles2D = get_node_or_null("Poeira")

var _dentro: Array[Node] = []


func _ready() -> void:
	add_to_group("correntes_ar")
	body_entered.connect(func(c: Node) -> void:
		if c is Koliani and c not in _dentro:
			_dentro.append(c))
	body_exited.connect(func(c: Node) -> void:
		_dentro.erase(c))


func _physics_process(_dt: float) -> void:
	for k in _dentro:
		if is_instance_valid(k) and k.has_method("soprar_para_cima"):
			k.soprar_para_cima(forca, vel_alvo)
