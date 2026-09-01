class_name RaizPerigo
extends Area2D
## Espinho de raiz que irrompe do chao. Mecanica partilhada da regiao I
## (Floresta Putrefacta): o Ghorak semeia estes sob os pes da Koliani, e
## niveis futuros usam-nos como perigo/plataforma temporaria.
##
## Uso: instanciar, pousar em `global_position` (a base, ao nivel do chao)
## e chamar `avisar(dano, atraso)`. Telegrafa com uma racha no chao, depois
## irrompe, magoa quem toca, fica um instante e recolhe-se sozinho.

@export var dano := 16
## Segundos de aviso (racha a pulsar) antes de irromper.
@export var atraso := 0.45
## Segundos que fica de fora depois de irromper.
@export var dur_ativa := 1.0
## Altura do espinho (cresce para cima a partir da base).
@export var altura := 78.0

@onready var _forma: CollisionShape2D = $CollisionShape2D
@onready var _visual: Node2D = $Visual
@onready var _racha: Node2D = $Racha

var _dir_empurrao := 0.0
var _iniciado := false


func _ready() -> void:
	monitoring = false
	_visual.scale.y = 0.0
	_visual.visible = false
	body_entered.connect(_ao_tocar)
	# rede de seguranca: se ninguem chamar avisar(), desaparece
	get_tree().create_timer(6.0).timeout.connect(func():
		if not _iniciado:
			queue_free())


## Arranca o ciclo telegrafo -> irrompe -> recolhe. `empurrao` e' o sentido
## em que atira a Koliani (para o escudo poder bloquear de frente).
func avisar(dano_: int = -1, atraso_: float = -1.0, empurrao: float = 0.0) -> void:
	if _iniciado:
		return
	_iniciado = true
	if dano_ >= 0:
		dano = dano_
	if atraso_ >= 0.0:
		atraso = atraso_
	_dir_empurrao = empurrao
	_pulsar_racha()
	await get_tree().create_timer(atraso).timeout
	if is_instance_valid(self):
		_irromper()


func _pulsar_racha() -> void:
	if _racha == null:
		return
	_racha.visible = true
	var t := create_tween().set_loops()
	t.tween_property(_racha, "modulate:a", 0.85, 0.12)
	t.tween_property(_racha, "modulate:a", 0.25, 0.12)


func _irromper() -> void:
	if _racha:
		_racha.visible = false
	_visual.visible = true
	monitoring = true
	var t := create_tween()
	t.tween_property(_visual, "scale:y", 1.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# quem ja estava em cima leva na mesma
	t.tween_callback(func():
		for c in get_overlapping_bodies():
			_ao_tocar(c))
	t.tween_interval(dur_ativa)
	t.tween_callback(func(): monitoring = false)
	t.tween_property(_visual, "scale:y", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)


func _ao_tocar(corpo: Node) -> void:
	if not monitoring:
		return
	if corpo is Koliani:
		var dir := _dir_empurrao
		if dir == 0.0:
			dir = signf(corpo.global_position.x - global_position.x)
		corpo.receber_dano(dano, dir)
