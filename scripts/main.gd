extends Node2D
## Cena de arranque (`scenes/Main.tscn`, definida em project.godot como
## main_scene). Carrega o nível atual da campanha e cola-lhe o HUD por
## cima. Trocar de nível = mudar `EstadoJogo.indice_nivel` e voltar a esta
## cena (é o que a Porta faz).

const CENA_HUD := preload("res://scenes/ui/HUD.tscn")
const CENA_DIARIO := preload("res://scenes/ui/Diario.tscn")
const FIM_CAMPANHA := preload("res://scripts/fim_campanha.gd")


func _ready() -> void:
	Musica.ambiente(EstadoJogo.indice_nivel)
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

	# `godot --path . -- --foto[=ficheiro]`: tira uma captura e sai (dev).
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--foto"):
			var alvo := a.get_slice("=", 1) if "=" in a else "user://foto.png"
			_tirar_foto(alvo)


func _procurar_porta(no: Node) -> Porta:
	if no is Porta:
		return no
	for filho in no.get_children():
		var r := _procurar_porta(filho)
		if r:
			return r
	return null


## Atalhos de depuração -- só em builds de debug (editor / export-debug).
## F1..F4: salta para o mundo 1..4. F5: dá todas as habilidades.
## F6: +3 vidas. F9: apaga o save e recomeça.
func _unhandled_input(evento: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if not (evento is InputEventKey and evento.pressed and not evento.echo):
		return
	match evento.keycode:
		KEY_F1, KEY_F2, KEY_F3, KEY_F4:
			var i: int = int(evento.keycode) - KEY_F1
			if i < EstadoJogo.NIVEIS.size():
				EstadoJogo.indice_nivel = i
				EstadoJogo.checkpoint = Vector2.ZERO
				get_tree().change_scene_to_file("res://scenes/Main.tscn")
		KEY_F5:
			for h in ["salto_duplo", "dash_aereo", "partir_paredes"]:
				EstadoJogo.desbloquear_habilidade(h)
			print("DEBUG: todas as habilidades desbloqueadas")
		KEY_F6:
			EstadoJogo.vidas += 3
			EstadoJogo.vidas_mudaram.emit(EstadoJogo.vidas)
			print("DEBUG: +3 vidas (", EstadoJogo.vidas, ")")
		KEY_F9:
			EstadoJogo.reiniciar_campanha()
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
			print("DEBUG: save apagado, campanha reiniciada")


func _tirar_foto(caminho: String) -> void:
	await get_tree().create_timer(0.8).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(caminho)
	print("FOTO guardada: ", ProjectSettings.globalize_path(caminho))
	get_tree().quit(0)


func _ao_fim_da_campanha() -> void:
	print("FIM: Koliani liberta a mãe de Zeriko.")
	var fim := CanvasLayer.new()
	fim.set_script(FIM_CAMPANHA)
	add_child(fim)
