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
## plataforma da outra (0.5 = pisa-se em alternância). Pouco antes de
## desligar, o visual pisca a avisar.

## Segundos de um ciclo completo (sólida + fantasma).
@export var periodo := 2.4
## Desfasamento 0..1 dentro do ciclo (0.5 = em contratempo).
@export var fase := 0.0
## true = começa sólida na primeira metade do ciclo; false = ao contrário.
@export var comeca_solida := true
## Janela (segundos) de piscar antes de cada troca de estado.
@export var aviso := 0.4

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


## Fração 0..1 dentro do ciclo, com a fase aplicada.
func _frac() -> float:
	var t := Time.get_ticks_msec() / 1000.0
	return fmod(t / maxf(0.1, periodo) + fase, 1.0)


func _calcula_solida() -> bool:
	var primeira_metade := _frac() < 0.5
	return primeira_metade if comeca_solida else not primeira_metade


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
		Som.toca("selo" if solida else "onda", -22.0, 1.6 if solida else 1.2)


## A arena desmorona (Coração Putrefacto, fase 3): a plataforma parte-se de
## vez -- desliga a colisão, esvai-se e liberta-se.
func desmoronar() -> void:
	if _caiu:
		return
	_caiu = true
	if _col:
		_col.set_deferred("disabled", true)
	Som.toca("onda", -14.0, 0.8)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.35)
	t.parallel().tween_property(self, "position:y", position.y + 40.0, 0.35)
	t.tween_callback(queue_free)


## Faz o visual pulsar nos últimos `aviso` segundos antes da próxima troca.
func _piscar_se_perto_da_troca() -> void:
	var vis := get_node_or_null("Visual") as CanvasItem
	if vis == null:
		return
	var f := _frac()
	# distância (em segundos) até ao próximo limite (0.5 ou 1.0)
	var prox := 0.5 - fmod(f, 0.5)
	var seg := prox * periodo
	if seg <= aviso:
		var base := 1.0 if _solida_agora else 0.16
		vis.modulate.a = base + 0.5 * absf(sin(Time.get_ticks_msec() * 0.02))
