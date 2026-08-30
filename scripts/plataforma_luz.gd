@tool
class_name PlataformaLuz
extends "res://scripts/plataforma.gd"
## Plataforma que só existe enquanto houver uma `Vela` acesa dentro de
## `raio_luz` (Região IV / nível 18 -- Cripta das Mil Velas). Sem luz por
## perto: contorno ténue e atravessável. Mecânica partilhada: reaproveita
## `Plataforma` (tiles/colisão/API `tamanho`).

## Distância a que uma vela acesa a mantém sólida.
@export var raio_luz := 220.0
@export var alpha_escuro := 0.12

var _acesa_agora := false

@onready var _col: CollisionShape2D = get_node_or_null("Col")


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	add_to_group("plat_luz")
	_avaliar(true)


func _process(_dt: float) -> void:
	if Engine.is_editor_hint():
		return
	_avaliar(false)


func _avaliar(imediato: bool) -> void:
	var quer := _tem_luz()
	if quer == _acesa_agora and not imediato:
		return
	_acesa_agora = quer
	if _col:
		_col.set_deferred("disabled", not quer)
	var vis := get_node_or_null("Visual") as CanvasItem
	if vis:
		if imediato:
			vis.modulate.a = 1.0 if quer else alpha_escuro
		else:
			create_tween().tween_property(vis, "modulate:a", 1.0 if quer else alpha_escuro, 0.15)


func _tem_luz() -> bool:
	for v in get_tree().get_nodes_in_group("velas"):
		if not is_instance_valid(v):
			continue
		if v.acesa and (v as Node2D).global_position.distance_to(global_position) <= raio_luz:
			return true
	return false
