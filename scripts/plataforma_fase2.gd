class_name PlataformaFase2
extends "res://scripts/plataforma_sino.gd"
## "Plataforma final (multiplas fases)" do N15: nasce fantasma na arena do
## Vyrak e so' se ergue no RITUAL DE ATIVACAO (aos 50 % de vida do chefe), quando
## ele chama `ativar_fase2()` a todo o grupo "plataformas_fase2". Fica solida ate'
## ao fim da luta. Herda da `PlataformaSino` (tiles, colisao, pele suspensa).

func _ready() -> void:
	grupo_alternar = "plataformas_fase2"
	super._ready()
	add_to_group("plataformas_fase2")


func ativar_fase2() -> void:
	_por_solida(true)
	var vis := get_node_or_null("Visual") as CanvasItem
	if vis:
		vis.modulate = Color(1.8, 1.5, 2.2, 1.0)
		create_tween().tween_property(vis, "modulate", Color.WHITE, 0.9)
