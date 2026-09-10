extends SceneTree
## Produção determinística dos assets aprovados da Execution 6A.
## Apenas faz crops lossless de regiões previamente verificadas; não pinta,
## infere pixels, remove fundos nem altera as pranchas de autoridade.

const FONTE_08 := "res://Koliani_1.0_Master_Package_v2/references/approved/08_REGION_I_ART_KIT_BACKGROUNDS_PARALLAX_v1_0.png"
const SAIDA_BACKGROUND := "res://assets/art/regions/region_01_forest/production/backgrounds/region1_panorama_heart_tree.png"
const SAIDA_LEFT := "res://assets/art/regions/region_01_forest/production/backgrounds/region1_panorama_left_cap.png"
const SAIDA_RIGHT := "res://assets/art/regions/region_01_forest/production/backgrounds/region1_panorama_right_cap.png"
const RECORTE_BACKGROUND := Rect2i(18, 97, 952, 247)


func _init() -> void:
	var fonte := Image.load_from_file(FONTE_08)
	if fonte == null or fonte.is_empty():
		printerr("6A ASSET GATE: fonte 08 indisponível")
		quit(1)
		return
	if fonte.get_width() != 1536 or fonte.get_height() != 1024:
		printerr("6A ASSET GATE: dimensões inesperadas em 08")
		quit(1)
		return
	var recorte := fonte.get_region(RECORTE_BACKGROUND)
	if recorte.is_empty() or recorte.get_width() != 952 or recorte.get_height() != 247:
		printerr("6A ASSET GATE: crop inválido")
		quit(1)
		return
	if not _guardar(recorte, SAIDA_BACKGROUND):
		quit(1)
		return
	if not _guardar(recorte.get_region(Rect2i(0, 0, 320, 247)), SAIDA_LEFT):
		quit(1)
		return
	if not _guardar(recorte.get_region(Rect2i(630, 0, 322, 247)), SAIDA_RIGHT):
		quit(1)
		return
	print("6A ASSET PRODUCED: ", SAIDA_BACKGROUND)
	print("6A ASSET PRODUCED: ", SAIDA_LEFT)
	print("6A ASSET PRODUCED: ", SAIDA_RIGHT)
	print("source=", FONTE_08, " crop=", RECORTE_BACKGROUND, " size=", recorte.get_size())
	quit(0)


func _guardar(imagem: Image, caminho: String) -> bool:
	var caminho_absoluto := ProjectSettings.globalize_path(caminho)
	DirAccess.make_dir_recursive_absolute(caminho_absoluto.get_base_dir())
	var erro := imagem.save_png(caminho_absoluto)
	if erro != OK:
		printerr("6A ASSET GATE: falha a gravar ", caminho, ": ", error_string(erro))
		return false
	return true
