extends Node2D
## Script para o nó raiz de um mundo com chefe: a `Porta` para o mundo
## seguinte fica selada (`monitoring = false` + tom escuro) até o nó
## `Chefe` emitir `derrotado`. Se não houver `Chefe`, a porta abre já.
##
## Podia prepender um CORREDOR DE APROXIMAÇÃO (ver `gerador_corredor.gd`),
## mas está DESLIGADO por omissão: gerava paredes/portas impossíveis e
## softlocks nos playtests (a Koliani ficava presa sem saber o que fazer).
## Pôr `corredor = true` numa cena para o voltar a experimentar nesse nível.

const GERADOR := preload("res://scripts/gerador_corredor.gd")

## Prepende o corredor de aproximação escalável (ver nota acima -- off).
@export var corredor := false

@onready var _porta: Area2D = $Porta
@onready var _chefe: Node = get_node_or_null("Chefe")


func _ready() -> void:
	if corredor and EstadoJogo.indice_nivel < EstadoJogo.NIVEIS.size() - 1:
		var g := Node2D.new()
		g.name = "CorredorAproximacao"
		g.set_script(GERADOR)
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
