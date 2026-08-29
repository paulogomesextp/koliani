extends Node2D
## Cena de arranque (`scenes/Main.tscn`, definida em project.godot como
## main_scene). Carrega o nível atual da campanha e cola-lhe o HUD por
## cima. Trocar de nível = mudar `EstadoJogo.indice_nivel` e voltar a esta
## cena (é o que a Porta faz).

const CENA_HUD := preload("res://scenes/ui/HUD.tscn")
const CENA_DIARIO := preload("res://scenes/ui/Diario.tscn")
const FIM_CAMPANHA := preload("res://scripts/fim_campanha.gd")


func _ready() -> void:
	var caminho := EstadoJogo.caminho_nivel_atual()
	var cena_nivel: PackedScene = load(caminho)
	if cena_nivel == null:
		push_error("Nível não encontrado: %s" % caminho)
		return
	var nivel := cena_nivel.instantiate()
	add_child(nivel)

	var porta := _procurar_porta(nivel)
	if porta:
		porta.fim_da_campanha.connect(_ao_fim_da_campanha)

	add_child(CENA_HUD.instantiate())
	add_child(CENA_DIARIO.instantiate())


func _procurar_porta(no: Node) -> Porta:
	if no is Porta:
		return no
	for filho in no.get_children():
		var r := _procurar_porta(filho)
		if r:
			return r
	return null


func _ao_fim_da_campanha() -> void:
	print("FIM: Koliani liberta a mãe de Zeriko.")
	var fim := CanvasLayer.new()
	fim.set_script(FIM_CAMPANHA)
	add_child(fim)
