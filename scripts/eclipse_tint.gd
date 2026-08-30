extends Node
## Pulsa o tom do ecrã entre "realidade" e "corrupção" ao mesmo ritmo das
## `PlataformaRitmada` (Praça do Eclipse, nível 25). Usa o mesmo relógio
## partilhado (`Time.get_ticks_msec`) para bater em sincronia com elas.

@export var periodo := 3.0
@export var cor_real := Color(0.85, 0.82, 0.9, 1.0)
@export var cor_corrupto := Color(0.5, 0.3, 0.62, 1.0)

var _mod: CanvasModulate


func _ready() -> void:
	var atm := get_tree().get_first_node_in_group("atmosfera")
	if atm:
		_mod = atm.get_node_or_null("Modulacao") as CanvasModulate


func _process(_dt: float) -> void:
	if _mod == null:
		return
	var f := fmod(Time.get_ticks_msec() / 1000.0 / maxf(0.1, periodo), 1.0)
	var lerp_t := 0.5 - 0.5 * cos(f * TAU)
	_mod.color = cor_real.lerp(cor_corrupto, lerp_t)
