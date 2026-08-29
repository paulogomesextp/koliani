extends CanvasLayer
## Cartão de fim de campanha (provisório). Aparece quando se atravessa a
## última porta; o jogo fica em pausa e um toque em saltar/atacar volta ao
## menu inicial. Substituir por uma cena de final a sério quando o mundo 4
## (Castelo de Zeriko) existir.

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS

	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.02, 0.05, 0.94)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var texto := Label.new()
	texto.text = "A última porta cede.\nKoliani encontra a mãe.\n\n— fim do que existe por agora —\n\n(saltar / atacar: voltar ao menu)"
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto.add_theme_color_override("font_color", Color(0.95, 0.85, 0.98))
	add_child(texto)

	get_tree().paused = true


func _process(_dt: float) -> void:
	if Input.is_action_just_pressed("saltar") or Input.is_action_just_pressed("atacar"):
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/ui/MenuInicial.tscn")
