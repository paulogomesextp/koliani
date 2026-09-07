extends Node
## Confirma no Godot real que as 100 cenas runtime do manifesto carregam.


func _ready() -> void:
	var ficheiro := FileAccess.open("res://data/level_manifest.json", FileAccess.READ)
	if ficheiro == null:
		printerr("LEVEL SCENES: FAIL — manifesto inacessível")
		get_tree().quit(1)
		return
	var dados: Variant = JSON.parse_string(ficheiro.get_as_text())
	if not dados is Dictionary or not dados.has("levels"):
		printerr("LEVEL SCENES: FAIL — manifesto inválido")
		get_tree().quit(1)
		return
	var falhas: Array[String] = []
	for nivel: Dictionary in dados["levels"]:
		var caminho: String = nivel.get("runtime_scene", "")
		var cena: Resource = load(caminho)
		if not cena is PackedScene:
			falhas.append("%s: %s" % [nivel.get("level_id", "?"), caminho])
	if falhas.is_empty():
		print("LEVEL SCENES: PASS — 100/100 cenas carregáveis")
		get_tree().quit(0)
	else:
		printerr("LEVEL SCENES: FAIL — %d cena(s)" % falhas.size())
		for falha in falhas:
			printerr("- " + falha)
		get_tree().quit(1)
