extends Node2D
## Cena de jogo (`scenes/Main.tscn`). A `main_scene` do projeto é o
## `MenuInicial.tscn`, que carrega esta a seguir a "Continuar"/"Novo jogo"
## (ou logo, com `-- --jogar`). Carrega o nível atual da campanha e cola-lhe
## o HUD por cima. Trocar de nível = mudar `EstadoJogo.indice_nivel` e
## voltar a esta cena (é o que a Porta faz).

const CENA_HUD := preload("res://scenes/ui/HUD.tscn")
const CENA_DIARIO := preload("res://scenes/ui/Diario.tscn")
const CENA_PAUSA := preload("res://scenes/ui/Pausa.tscn")
const CENA_DEV_BARRA := preload("res://scenes/ui/DevBarra.tscn")
const RELOGIO_HARDCORE := preload("res://scripts/relogio_hardcore.gd")
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
	add_child(CENA_PAUSA.instantiate())
	if EstadoJogo.modo_dev:
		add_child(CENA_DEV_BARRA.instantiate())

	if EstadoJogo.hardcore:
		var relogio := CanvasLayer.new()
		relogio.set_script(RELOGIO_HARDCORE)
		add_child(relogio)

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
	# usa o physical_keycode (posição da tecla) -- mais fiável que keycode
	match evento.physical_keycode:
		KEY_F1, KEY_F2, KEY_F3, KEY_F4:
			var i: int = int(evento.physical_keycode) - KEY_F1
			if i < EstadoJogo.NIVEIS.size():
				EstadoJogo.indice_nivel = i
				EstadoJogo.checkpoint = Vector2.ZERO
				_toast_debug("mundo %d" % (i + 1))
				await get_tree().create_timer(0.35).timeout
				get_tree().change_scene_to_file("res://scenes/Main.tscn")
		KEY_F5:
			for h in EstadoJogo.HABILIDADES_TODAS:
				EstadoJogo.desbloquear_habilidade(h)
			_toast_debug("habilidades todas")
		KEY_F6:
			EstadoJogo.vidas += 3
			EstadoJogo.vidas_mudaram.emit(EstadoJogo.vidas)
			_toast_debug("+3 vidas  (%d)" % EstadoJogo.vidas)
		KEY_F9:
			EstadoJogo.reiniciar_campanha()
			_toast_debug("save apagado -- recomecar")
			await get_tree().create_timer(0.35).timeout
			get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _toast_debug(txt: String) -> void:
	print("DEBUG: ", txt)
	var camada := CanvasLayer.new()
	camada.layer = 26
	camada.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(camada)
	var l := Label.new()
	l.text = "  " + txt + "  "
	l.position = Vector2(20, 92)
	l.add_theme_color_override("font_color", Color(0.1, 0.05, 0.12))
	l.add_theme_font_size_override("font_size", 18)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(1, 0.82, 0.4, 0.92)
	estilo.set_corner_radius_all(4)
	estilo.content_margin_top = 3
	estilo.content_margin_bottom = 3
	l.add_theme_stylebox_override("normal", estilo)
	camada.add_child(l)
	var t := create_tween()
	t.tween_interval(1.6)
	t.tween_property(l, "modulate:a", 0.0, 0.5)
	t.tween_callback(camada.queue_free)


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
