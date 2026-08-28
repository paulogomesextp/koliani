extends Node2D
## Cena de arranque (`scenes/Main.tscn`, definida em project.godot como
## main_scene). Carrega o nível atual da campanha e cola-lhe o HUD por
## cima. Trocar de nível = mudar `EstadoJogo.indice_nivel` e voltar a esta
## cena (é o que a Porta faz).

const CENA_HUD := preload("res://scenes/ui/HUD.tscn")


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


func _procurar_porta(no: Node) -> Porta:
	if no is Porta:
		return no
	for filho in no.get_children():
		var r := _procurar_porta(filho)
		if r:
			return r
	return null


func _ao_fim_da_campanha() -> void:
	# Final provisório: cartão de fim por cima do jogo. Uma cena de final a
	# sério (Koliani liberta a mãe, Zeriko cai) fica para quando os mundos
	# 2-4 existirem.
	print("FIM: Koliani liberta a mãe de Zeriko.")

	var camada := CanvasLayer.new()
	camada.layer = 20
	add_child(camada)

	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.02, 0.05, 0.94)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(fundo)

	var texto := Label.new()
	texto.text = "A última porta cede.\nKoliani encontra a mãe.\n\n— fim do que existe por agora —"
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto.add_theme_color_override("font_color", Color(0.95, 0.85, 0.98))
	camada.add_child(texto)

	get_tree().paused = true
