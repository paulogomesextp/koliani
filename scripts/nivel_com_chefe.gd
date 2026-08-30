extends Node2D
## Script para o nó raiz de um mundo com chefe:
##  - a `Porta` para o mundo seguinte fica selada (`monitoring = false` +
##    tom escuro) até o nó `Chefe` emitir `derrotado`;
##  - prepende uma JORNADA DE APROXIMAÇÃO longa e temática (ver
##    `gerador_corredor.gd`) para que o chefe fique SEMPRE no fim do nível.
##
## `corredor = false` na cena desliga a jornada nesse nível. O último nível
## da campanha (o trono do Zeriko) nunca a tem.

const GERADOR := preload("res://scripts/gerador_corredor.gd")

## Prepende a jornada de aproximação (grande, cresce com o número do nível).
@export var corredor := true

## Entrada "fresca" no nível (não é um respawn num checkpoint a meio). É
## capturado em `_enter_tree`, ANTES de a Koliani correr o seu `_ready` (que
## define um checkpoint implícito no ponto de spawn) -- só assim se
## distingue "acabei de entrar" de "morri e voltei ao checkpoint".
var _entrada_fresca := true

@onready var _porta: Area2D = $Porta
@onready var _chefe: Node = get_node_or_null("Chefe")


func _enter_tree() -> void:
	_entrada_fresca = EstadoJogo.checkpoint == Vector2.ZERO


func _ready() -> void:
	if corredor and EstadoJogo.indice_nivel < EstadoJogo.NIVEIS.size() - 1:
		var g := Node2D.new()
		g.name = "CorredorAproximacao"
		g.set_script(GERADOR)
		g.set("entrada_fresca", _entrada_fresca)
		add_child(g)

	if _porta == null:
		return
	if _chefe and _chefe.has_signal("derrotado"):
		_selar(true)
		_chefe.derrotado.connect(_abrir)
	else:
		_selar(false)


func _selar(selada: bool) -> void:
	_porta.monitoring = not selada
	_porta.modulate = Color(0.34, 0.34, 0.4) if selada else Color(1, 1, 1)


func _abrir() -> void:
	_selar(false)
