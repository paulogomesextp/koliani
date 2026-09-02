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
## Segundos de aviso (marca no chao a acender e a pulsar) antes de irromper.
## O telegrafo cresce, deita farrapos de luz e pulsa depressa no fim -- da'
## sempre para ver onde a raiz vai nascer e sair de cima.
@export var atraso := 0.9
## Segundos que fica de fora depois de irromper.
@export var dur_ativa := 1.0
## Altura do espinho (cresce para cima a partir da base).
@export var altura := 78.0
## MODO CENARIO (nivel 1 -- "raizes que crescem e desaparecem"): em vez de
## esperar por `avisar()`, cicla sozinha para sempre. `intervalo` = pausa
## recolhida entre irrupcoes; `fase` desencontra uma fila de raizes.
@export var auto := false
@export var intervalo := 2.6
@export var fase := 0.0

@onready var _forma: CollisionShape2D = $CollisionShape2D
@onready var _visual: Node2D = $Visual
@onready var _racha: Node2D = $Racha
@onready var _luz_aviso: PointLight2D = $Racha/LuzAviso if has_node("Racha/LuzAviso") else null
@onready var _motes: CPUParticles2D = $Racha/Motes if has_node("Racha/Motes") else null

var _dir_empurrao := 0.0
var _iniciado := false


func _ready() -> void:
	monitoring = false
	_visual.scale.y = 0.0
	_visual.visible = false
	if _racha:
		_racha.visible = false
	body_entered.connect(_ao_tocar)
	if auto:
		_iniciado = true
		_loop_auto()
		return
	# rede de seguranca: se ninguem chamar avisar(), desaparece
	get_tree().create_timer(6.0).timeout.connect(func():
		if not _iniciado:
			queue_free())


## MODO CENARIO: telegrafo -> irrompe -> recolhe -> pausa, em ciclo eterno.
func _loop_auto() -> void:
	if fase > 0.0:
		await get_tree().create_timer(fase).timeout
	while is_instance_valid(self):
		await _telegrafar()
		if not is_instance_valid(self):
			return
		_apagar_racha()
		_visual.visible = true
		monitoring = true
		var tc := create_tween()
		tc.tween_property(_visual, "scale:y", 1.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tc.finished
		if not is_instance_valid(self):
			return
		for c in get_overlapping_bodies():
			_ao_tocar(c)
		await get_tree().create_timer(dur_ativa).timeout
		if not is_instance_valid(self):
			return
		monitoring = false
		var tr := create_tween()
		tr.tween_property(_visual, "scale:y", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tr.finished
		if not is_instance_valid(self):
			return
		_visual.visible = false
		await get_tree().create_timer(intervalo).timeout


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
	await _telegrafar()
	if is_instance_valid(self):
		_irromper()


## Telegrafo do sitio onde a raiz vai nascer: a marca no chao acende e
## cresce ao longo de quase toda a `atraso`, a luz sobe, deita farrapos, e
## nos ultimos instantes pulsa depressa ("vai JA"). Consome o tempo de
## aviso -- quem chama nao precisa de esperar mais.
func _telegrafar() -> void:
	if _racha == null:
		await get_tree().create_timer(atraso).timeout
		return
	_racha.visible = true
	_racha.modulate.a = 0.0
	_racha.scale = Vector2(0.35, 0.35)
	if _motes:
		_motes.emitting = true
	var crescer: float = maxf(0.08, atraso * 0.8)
	var t := create_tween().set_parallel(true)
	t.tween_property(_racha, "modulate:a", 1.0, maxf(0.05, atraso * 0.35))
	t.tween_property(_racha, "scale", Vector2(1.15, 1.0), crescer) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _luz_aviso:
		t.tween_property(_luz_aviso, "energy", 1.7, maxf(0.05, atraso * 0.85))
	await t.finished
	if not is_instance_valid(self):
		return
	# rajada final de pulsos rapidos -- so' se ainda houver janela util
	if atraso >= 0.35:
		var p := create_tween().set_loops(3)
		p.tween_property(_racha, "modulate:a", 0.3, 0.06)
		p.tween_property(_racha, "modulate:a", 1.0, 0.06)
		await p.finished


func _apagar_racha() -> void:
	if _racha:
		_racha.visible = false
		_racha.modulate.a = 0.0
	if _luz_aviso:
		_luz_aviso.energy = 0.0
	if _motes:
		_motes.emitting = false


func _irromper() -> void:
	_apagar_racha()
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
