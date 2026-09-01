@tool
class_name PlataformaRitmada
extends "res://scripts/plataforma.gd"
## Plataforma que aparece e desaparece ao ritmo da "batida da floresta"
## (Região I / nível 05 -- Coração da Floresta). Mecânica partilhada:
## reaproveita `Plataforma` (tiles pixel-art, colisão, API `tamanho`) e só
## acrescenta o pulsar.
##
## Todas as instâncias usam o MESMO relógio (`Time.get_ticks_msec`), por
## isso batem em sincronia sem precisarem de um maestro. `fase` desfasa uma
## plataforma da outra. Pouco antes de desligar, o visual pisca a avisar.
##
## Timing: por omissão o ciclo é `periodo` a meio (sólida) e a meio
## (fantasma). Pôr `solida_seg > 0` dá controlo assimétrico -- ex.: 5 s
## sólida + `fantasma_seg` de fantasma -- para plataformas que ficam bem
## fixas antes de se esvaírem.

## Ciclo simétrico (segundos): metade sólida, metade fantasma. Só conta se
## `solida_seg` == 0.
@export var periodo := 2.4
## Segundos SÓLIDA por ciclo (0 = usa `periodo` / 2). Com > 0, o ciclo passa
## a ser `solida_seg` + `fantasma_seg`.
@export var solida_seg := 0.0
## Segundos FANTASMA por ciclo (só quando `solida_seg` > 0).
@export var fantasma_seg := 1.6
## Desfasamento 0..1 dentro do ciclo (0.5 = em contratempo).
@export var fase := 0.0
## true = começa sólida no arranque do ciclo; false = ao contrário.
@export var comeca_solida := true
## Janela (segundos) de piscar antes de cada troca de estado.
@export var aviso := 0.5

var _solida_agora := true
var _caiu := false

@onready var _col: CollisionShape2D = get_node_or_null("Col")


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	add_to_group("plataformas_ritmadas")
	_aplicar_estado(_calcula_solida(), true)


func _process(_dt: float) -> void:
	if Engine.is_editor_hint() or _caiu:
		return
	var quer := _calcula_solida()
	if quer != _solida_agora:
		_aplicar_estado(quer, false)
	else:
		_piscar_se_perto_da_troca()


func _dur_solida() -> float:
	return solida_seg if solida_seg > 0.0 else periodo * 0.5


func _dur_fantasma() -> float:
	return fantasma_seg if solida_seg > 0.0 else periodo * 0.5


func _ciclo() -> float:
	return maxf(0.2, _dur_solida() + _dur_fantasma())


## Segundos decorridos dentro do ciclo actual (já com a `fase` aplicada).
func _t_no_ciclo() -> float:
	var t := Time.get_ticks_msec() / 1000.0
	return fmod(t + fase * _ciclo(), _ciclo())


func _calcula_solida() -> bool:
	var solida := _t_no_ciclo() < _dur_solida()
	return solida if comeca_solida else not solida


func _aplicar_estado(solida: bool, imediato: bool) -> void:
	_solida_agora = solida
	if _col:
		_col.set_deferred("disabled", not solida)
	var vis := get_node_or_null("Visual") as CanvasItem
	if vis:
		var alvo := 1.0 if solida else 0.16
		if imediato:
			vis.modulate.a = alvo
		else:
			create_tween().tween_property(vis, "modulate:a", alvo, 0.12)
	if not imediato:


## A arena desmorona (Coração Putrefacto, fase 3): a plataforma parte-se de
## vez -- desliga a colisão, esvai-se e liberta-se.
func desmoronar() -> void:
	if _caiu:
		return
	_caiu = true
	if _col:
		_col.set_deferred("disabled", true)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.35)
	t.parallel().tween_property(self, "position:y", position.y + 40.0, 0.35)
	t.tween_callback(queue_free)


## Faz o visual pulsar nos últimos `aviso` segundos antes da próxima troca.
func _piscar_se_perto_da_troca() -> void:
	var vis := get_node_or_null("Visual") as CanvasItem
	if vis == null:
		return
	var restante := _dur_solida() - _t_no_ciclo() if _solida_agora \
		else _ciclo() - _t_no_ciclo()
	if restante <= aviso:
		var base := 1.0 if _solida_agora else 0.16
		vis.modulate.a = base + 0.5 * absf(sin(Time.get_ticks_msec() * 0.02))
