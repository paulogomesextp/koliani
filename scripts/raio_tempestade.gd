class_name RaioTempestade
extends Node2D
## Descarga vertical da Torre da Tempestade (Região III / nível 13).
## Telegrafa (um risco luminoso desce do céu e um alvo acende no chão),
## depois CAI: uma coluna de dano instantâneo. `automatico = true` repete
## em ciclo (padrão previsível: `periodo` + `fase`); Voltaris chama
## `cair(atraso)` para as disparar à mão.
##
## Se houver um `ParaRaios` ARMADO dentro de `raio_atrai` px, o relâmpago
## desvia-se para ele e o pára-raios devolve a carga ao chefe.

@export var dano := 26
@export var largura := 46.0
@export var altura := 620.0
@export var aviso := 0.8
@export var periodo := 3.0
@export var fase := 0.0
@export var automatico := false
@export var raio_atrai := 150.0

var _ocupado := false

@onready var _tel: Line2D = $Telegrafo
@onready var _alvo: Node2D = $Alvo
@onready var _bolt: Line2D = $Bolt
@onready var _area: Area2D = $Area
@onready var _forma: CollisionShape2D = $Area/CollisionShape2D


func _ready() -> void:
	add_to_group("raios_tempestade")
	_bolt.visible = false
	_tel.visible = false
	_area.monitoring = false
	(_forma.shape as RectangleShape2D).size = Vector2(largura, altura)
	_forma.position = Vector2(0, -altura * 0.5 + 8.0)
	_bolt.points = PackedVector2Array([Vector2(0, -altura), Vector2(-6, -altura * 0.6), Vector2(5, -altura * 0.3), Vector2(0, 0)])
	_tel.points = _bolt.points
	if automatico:
		_loop()


func _loop() -> void:
	await get_tree().create_timer(fase + randf_range(0.0, 0.3)).timeout
	while is_instance_valid(self):
		await cair()
		await get_tree().create_timer(periodo).timeout


func cair(atraso: float = -1.0) -> void:
	if _ocupado:
		return
	_ocupado = true
	var espera: float = aviso if atraso < 0.0 else atraso

	_tel.visible = true
	_alvo.visible = true
	# TELEGRAFO -- o ar a carregar. Esta armadilha tem mesmo as tres fases que
	# a Fase 5 do briefing distingue, e por isso ganha dois sons (o aviso e a
	# descarga): `aviso` e' quase um segundo de nada, e uma coluna de 26 de
	# dano nao pode cair so' com pisca-pisca a avisar.
	#
	# `raio.wav` NAO servia: e' o ataque do Voltaris e do Vyrak (6 callsites
	# de chefe) e dura 5,6 s. `raio_aviso`/`raio_cai` sao proprios.
	_tocar("raio_aviso", -17.0, 1.0)
	var tw := create_tween().set_loops(int(maxf(2.0, espera / 0.14)))
	tw.tween_property(_tel, "modulate:a", 0.85, 0.14)
	tw.tween_property(_tel, "modulate:a", 0.2, 0.14)
	await get_tree().create_timer(espera).timeout
	if not is_instance_valid(self):
		return
	_tel.visible = false

	var para := _para_raios_armado()
	if para:
		para.descarregar_no_chefe()
		_faisca(Color(0.7, 0.9, 1.0))
		# Desviado para o para-raios: o raio CAI na mesma, so' que noutro
		# sitio. Mesmo evento, mais abafado e mais grave -- diz "escapaste".
		_tocar("raio_cai", -14.0, 0.82)
		_ocupado = false
		return

	_bolt.visible = true
	_bolt.modulate.a = 1.0
	_area.monitoring = true
	_abanar(4.0)
	# ACTIVATION. Prioridade MEDIA: o pool tem 8 vozes e um raio nao pode ser
	# comido por passos, mas tambem nao pode cortar a morte do jogador.
	_tocar("raio_cai", -8.0, 1.0, Som.Prioridade.MEDIA)
	for c in _area.get_overlapping_bodies():
		if c is Koliani:
			c.receber_dano(dano, signf(c.global_position.x - global_position.x))
	var t := create_tween()
	t.tween_interval(0.09)
	t.tween_callback(func() -> void: _area.monitoring = false)
	t.tween_property(_bolt, "modulate:a", 0.0, 0.3)
	t.tween_callback(func() -> void:
		_bolt.visible = false
		_alvo.visible = false
		_ocupado = false)


func _para_raios_armado() -> Node:
	for p in get_tree().get_nodes_in_group("para_raios"):
		if not is_instance_valid(p):
			continue
		if p.has_method("esta_armado") and p.esta_armado() \
				and absf((p as Node2D).global_position.x - global_position.x) <= raio_atrai:
			return p
	return null


func _faisca(cor: Color) -> void:
	var p := CPUParticles2D.new()
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 18
	p.lifetime = 0.4
	p.spread = 180.0
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 220.0
	p.color = cor
	add_child(p)
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)


func _abanar(f: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("bater"):
		cam.bater(f)


## Toca com cooldown por instancia: `automatico = true` repete de `periodo`
## em `periodo`, e varios raios no mesmo nivel devem poder soar cada um o seu.
func _tocar(nome: String, db: float, pitch: float,
		prioridade := Som.Prioridade.NORMAL) -> void:
	Som.toca(nome, db, pitch, 0.05, maxf(0.4, aviso * 0.5),
		"%s_%d" % [nome, get_instance_id()], prioridade)
