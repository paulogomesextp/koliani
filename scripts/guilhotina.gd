class_name Guilhotina
extends Area2D
## Lâmina de guilhotina que cai numa coluna -- mecânica partilhada da
## Região II (Corredor das Execuções). Telegrafa (a lâmina estremece e a
## calha acende), cai depressa, magoa quem estiver na coluna, e recolhe-se
## devagar. `automatico = true` repete em ciclo; a Dama da Guilhotina
## chama `cair(atraso)` para as fazer cair em conjunto.

@export var dano := 24
@export var altura_queda := 220.0
## Segundos de aviso antes de cair.
@export var atraso := 0.6
## Segundos entre quedas no modo automático.
@export var periodo := 3.2
## Desfasamento inicial (segundos).
@export var fase := 0.0
@export var automatico := false

var _ocupado := false
var _y0 := 0.0

@onready var _lamina: Node2D = $Lamina
@onready var _calha: Node2D = get_node_or_null("Calha")


func _ready() -> void:
	monitoring = false
	_y0 = _lamina.position.y
	body_entered.connect(_ao_tocar)
	if automatico:
		await get_tree().create_timer(fase + randf_range(0.0, 0.4)).timeout
		_ciclo()
	else:
		get_tree().create_timer(9.0).timeout.connect(func() -> void:
			if not _ocupado:
				queue_free())


func _ciclo() -> void:
	while is_instance_valid(self):
		await cair()
		await get_tree().create_timer(periodo).timeout


func cair(atraso_: float = -1.0) -> void:
	if _ocupado:
		return
	_ocupado = true
	if atraso_ >= 0.0:
		atraso = atraso_

	# telegrafo: a lâmina treme, a calha acende
	if _calha:
		var tc := create_tween().set_loops(int(maxf(2.0, atraso / 0.12)))
		tc.tween_property(_calha, "modulate:a", 0.9, 0.12)
		tc.tween_property(_calha, "modulate:a", 0.3, 0.12)
	var tt := create_tween().set_loops(int(maxf(2.0, atraso / 0.1)))
	tt.tween_property(_lamina, "position:x", 2.0, 0.05)
	tt.tween_property(_lamina, "position:x", -2.0, 0.05)
	await get_tree().create_timer(atraso).timeout
	if not is_instance_valid(self):
		return
	_lamina.position.x = 0.0

	# queda
	monitoring = true
	var t := create_tween()
	t.tween_property(_lamina, "position:y", _y0 + altura_queda, 0.09) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void:
		_abanar(3.0)
		for c in get_overlapping_bodies():
			_ao_tocar(c))
	t.tween_interval(0.35)
	t.tween_callback(func() -> void: monitoring = false)
	# recolhe devagar
	t.tween_property(_lamina, "position:y", _y0, 0.7).set_trans(Tween.TRANS_SINE)
	if _calha:
		t.parallel().tween_property(_calha, "modulate:a", 0.15, 0.4)
	t.tween_callback(func() -> void:
		_ocupado = false
		if not automatico and is_instance_valid(self):
			queue_free())


func _ao_tocar(corpo: Node) -> void:
	if monitoring and corpo is Koliani:
		corpo.receber_dano(dano, signf(corpo.global_position.x - global_position.x))


func _abanar(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)
