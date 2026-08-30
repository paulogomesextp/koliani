@tool
class_name PlataformaEspectral
extends "res://scripts/plataforma.gd"
## Plataforma que só existe quando a Koliani usa magia (Região II / nível 09
## -- Ala dos Mortos). Fora disso é um contorno ténue e atravessável; ao
## ouvir `Koliani.magia_lancada` solidifica e ilumina-se por
## `segundos_solida`, depois esvai-se outra vez (com um aviso a piscar no
## fim). Mecânica partilhada: reaproveita `Plataforma` (tiles, colisão, API
## `tamanho`) e só acrescenta o fantasma.
##
## Se a Koliani ainda não tem a habilidade "projetil", a plataforma fica
## permanentemente sólida -- o nível nunca fica intransponível.

## Quanto tempo fica sólida a cada lançamento de magia.
@export var segundos_solida := 3.2
## Janela final (segundos) em que pisca a avisar que vai desaparecer.
@export var aviso := 0.7
## Alpha do contorno quando está "fantasma".
@export var alpha_fantasma := 0.14

var _restante := 0.0
var _solida := false
var _sempre := false

@onready var _col: CollisionShape2D = get_node_or_null("Col")


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	add_to_group("plataformas_espectrais")
	_sempre = not EstadoJogo.tem_habilidade("projetil")
	if _sempre:
		_aplicar_estado(true)
		return
	_aplicar_estado(false)
	var k := get_tree().get_first_node_in_group("koliani")
	if k and k.has_signal("magia_lancada"):
		k.magia_lancada.connect(_ao_lancar_magia)


func _process(dt: float) -> void:
	if Engine.is_editor_hint() or _sempre:
		return
	if _restante <= 0.0:
		return
	_restante -= dt
	if _restante <= 0.0:
		_aplicar_estado(false)
		return
	var vis := get_node_or_null("Visual") as CanvasItem
	if vis and _restante <= aviso:
		vis.modulate.a = 0.35 + 0.55 * absf(sin(Time.get_ticks_msec() * 0.02))


func _ao_lancar_magia() -> void:
	_restante = segundos_solida
	if not _solida:
		_aplicar_estado(true)


func _aplicar_estado(solida: bool) -> void:
	_solida = solida
	if _col:
		_col.set_deferred("disabled", not solida)
	var vis := get_node_or_null("Visual") as CanvasItem
	if vis:
		create_tween().tween_property(vis, "modulate:a", 1.0 if solida else alpha_fantasma, 0.12)
	if solida:
		Som.toca("selo", -20.0, 1.5)
