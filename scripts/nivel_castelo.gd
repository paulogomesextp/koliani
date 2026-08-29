extends Node2D
## Nó raiz do mundo 4 (Castelo de Zeriko). Não tem porta para o mundo
## seguinte -- quando o `Zeriko` cai, a jaula ilumina-se e arranca a cena
## final (`cena_final.gd`, libertação da Aurora).

const CENA_FINAL := preload("res://scripts/cena_final.gd")

@onready var _zeriko: Node = get_node_or_null("Zeriko")
@onready var _lanterna: Node2D = get_node_or_null("LanternaJaula")


func _ready() -> void:
	if _zeriko and _zeriko.has_signal("derrotado"):
		_zeriko.derrotado.connect(_ao_cair_zeriko)


func _ao_cair_zeriko() -> void:
	if _lanterna:
		var luz := _lanterna.get_node_or_null("Luz") as PointLight2D
		if luz:
			luz.energy = 3.2
		var silhueta := _lanterna.get_node_or_null("Silhueta") as CanvasItem
		if silhueta:
			silhueta.modulate = Color(1, 0.95, 1, 1)
	EstadoJogo.registar_pista("castelo_aurora_livre")
	var fim := CanvasLayer.new()
	fim.set_script(CENA_FINAL)
	add_child(fim)
