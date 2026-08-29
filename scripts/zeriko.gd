class_name Zeriko
extends ChefeBase
## Chefe final (mundo 4). Não patrulha: aparece num de vários pontos,
## dispara em direção à Koliani, desaparece e reaparece noutro ponto.
## Abaixo de metade da vida entra na 2.ª fase (espera mais curta, dois
## projéteis por disparo).
##
## Os pontos de aparição são os `Marker2D` filhos de um nó irmão chamado
## `PontosZeriko`; se não existir, usa uns offsets à volta da posição
## inicial.

enum Fase { SURGE, ATACA, SOME, ESPERA }

const PROJETIL := preload("res://scenes/actors/ProjetilZeriko.tscn")

@export var dur_surge := 0.35
@export var dur_ataca := 0.5
@export var dur_some := 0.3
@export var dur_espera := 0.8

var _fase: Fase = Fase.SURGE
var _t := 0.0
var _pontos: Array[Vector2] = []
var _idx := 0
var _vida_max := 1
var _disparou := false


func _ready() -> void:
	super._ready()
	vida = maxi(vida, 360)
	_vida_max = vida
	modulate.a = 0.0

	var cont := get_parent().get_node_or_null("PontosZeriko")
	if cont:
		for m in cont.get_children():
			if m is Node2D:
				_pontos.append(m.global_position)
	if _pontos.is_empty():
		var o := global_position
		_pontos = [o, o + Vector2(-280, -30), o + Vector2(280, -30), o + Vector2(0, -140)]
	global_position = _pontos[0]


func _fase_2() -> bool:
	return vida <= _vida_max / 2


func _physics_process(dt: float) -> void:
	match _fase:
		Fase.SURGE:
			modulate.a = minf(1.0, modulate.a + dt / dur_surge)
			_encarar_koliani()
			if _t >= dur_surge:
				_ir_para(Fase.ATACA)
		Fase.ATACA:
			_piscar(true)
			if not _disparou:
				_disparou = true
				_disparar()
			if _t >= dur_ataca:
				_piscar(false)
				_ir_para(Fase.SOME)
		Fase.SOME:
			modulate.a = maxf(0.0, modulate.a - dt / dur_some)
			if _t >= dur_some:
				_ir_para(Fase.ESPERA)
		Fase.ESPERA:
			var espera := dur_espera * (0.5 if _fase_2() else 1.0)
			if _t >= espera:
				_teleportar()
				_ir_para(Fase.SURGE)
	_t += dt


func _ir_para(f: Fase) -> void:
	_fase = f
	_t = 0.0
	_disparou = false


func _teleportar() -> void:
	if _pontos.size() < 2:
		return
	var salto := 1 + (randi() % (_pontos.size() - 1))
	_idx = (_idx + salto) % _pontos.size()
	global_position = _pontos[_idx]


func _disparar() -> void:
	var k := _obter_koliani()
	if k == null:
		return
	var base_dir := k.global_position - global_position
	var n := 2 if _fase_2() else 1
	for i in n:
		var p := PROJETIL.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position
		var ang := deg_to_rad(13.0 * (float(i) - (n - 1) / 2.0))
		p.lancar(base_dir.rotated(ang))
