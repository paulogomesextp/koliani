extends SceneTree
# Sonda do isolamento de save: imprime onde o Godot resolve `user://`.
# Usada por `tools/godot_isolado.py` (nao toca em nada, so' le o caminho).
func _init() -> void:
	print("KOLIANI_UDIR=", OS.get_user_data_dir())
	quit()
