class_name Vela
extends Area2D
## Vela da Cripta das Mil Velas (Região IV / nível 18). Quando ACESA
## ilumina as `PlataformaLuz` por perto (fá-las existir). Apaga-se por
## `apagar()` (a Freira Negra) e volta a acender-se quando a Koliani lhe
## toca (ou lhe dá um golpe -- ambos passam por aqui). Grupo "velas".

@export var acesa := true
## Tempo (s) que a Koliani tem de estar em contacto para reacender.
@export var demora_acender := 0.35

var _contacto := 0.0

@onready var _chama: CanvasItem = get_node_or_null("Chama")
@onready var _luz: PointLight2D = get_node_or_null("Luz")


func _ready() -> void:
	add_to_group("velas")
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)
	_aplicar(true)


func _process(dt: float) -> void:
	if not acesa and _contacto > 0.0:
		_contacto -= dt
		if _contacto <= 0.0:
			acender()
	if acesa and _chama:
		_chama.scale = Vector2.ONE * (1.0 + 0.12 * sin(Time.get_ticks_msec() * 0.012))


func _ao_entrar(c: Node) -> void:
	if c is Koliani and not acesa:
		_contacto = demora_acender


func _ao_sair(c: Node) -> void:
	if c is Koliani:
		_contacto = 0.0


func acender() -> void:
	if acesa:
		return
	acesa = true
	Som.toca("selo", -16.0, 1.6)
	_aplicar(false)


func apagar() -> void:
	if not acesa:
		return
	acesa = false
	_contacto = 0.0
	Som.toca("onda", -18.0, 0.8)
	_aplicar(false)


func _aplicar(imediato: bool) -> void:
	if _chama:
		if imediato:
			_chama.visible = acesa
			_chama.modulate.a = 1.0 if acesa else 0.0
		else:
			_chama.visible = true
			create_tween().tween_property(_chama, "modulate:a", 1.0 if acesa else 0.0, 0.12)
	if _luz:
		var alvo := 1.0 if acesa else 0.0
		if imediato:
			_luz.energy = alvo
		else:
			create_tween().tween_property(_luz, "energy", alvo, 0.15)
