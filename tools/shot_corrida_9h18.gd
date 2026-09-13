extends Node2D
## Tira de contacto da CORRIDA, montada pelo jogo (Execution 9H.18).
##
## Nao le' os PNG da pasta: instancia a Koliani, deixa o `_montar_frames()`
## correr e fotografa a animacao `run` tal como o jogo a monta -- ja' com o
## `run_native` se ele existir, com a escala e o offset do contrato visual e
## com o `speed_scale` da cadencia por velocidade. E' a diferenca entre
## provar a ARTE e provar o JOGO.
##
## Precisa de janela (nesta maquina o headless da' um renderer dummy e sai
## tudo preto):
##
##   Godot..._console.exe --path . --screen 1 \
##       --script res://tools/shot_corrida_9h18.gd -- <saida.png>

const KOLIANI := preload("res://scenes/actors/Koliani.tscn")
const CELULA := Vector2i(128, 128)
const ZOOM := 3


func _ready() -> void:
	var saida := "user://corrida.png"
	for a in OS.get_cmdline_user_args():
		if a.ends_with(".png"):
			saida = a
	# ATENCAO: a `Koliani.tscn` em bruto NAO vem com o Golden Set -- cai no
	# rig `shadowblade` (5 frames de run). O Golden e' ligado nivel a nivel
	# (`usar_golden_set` em L1..L5). Sem esta linha fotografa-se o rig
	# errado, e foi o que aconteceu a` primeira.
	var k: Node2D = KOLIANI.instantiate()
	k.set("usar_golden_set", true)
	add_child(k)
	await get_tree().process_frame
	var corpo := k.find_child("Corpo", true, false) as AnimatedSprite2D
	if corpo == null or corpo.sprite_frames == null:
		push_error("sem AnimatedSprite2D montado")
		get_tree().quit(1)
		return
	var sf := corpo.sprite_frames
	var n := sf.get_frame_count("run")
	print("run: %d frames, %.2f fps, loop=%s"
		% [n, sf.get_animation_speed("run"), sf.get_animation_loop("run")])
	for nome in ["idle", "run", "run_start", "run_brake", "turn",
			"jump_start", "fall", "dash"]:
		if sf.has_animation(nome):
			print("  %-11s %2d frames @ %5.2f fps"
				% [nome, sf.get_frame_count(nome), sf.get_animation_speed(nome)])
	var img := Image.create(CELULA.x * ZOOM * n, CELULA.y * ZOOM,
		false, Image.FORMAT_RGBA8)
	img.fill(Color(0.10, 0.09, 0.13, 1.0))
	for i in n:
		var tex := sf.get_frame_texture("run", i)
		if tex == null:
			continue
		var f := tex.get_image()
		f.convert(Image.FORMAT_RGBA8)
		f.resize(f.get_width() * ZOOM, f.get_height() * ZOOM,
			Image.INTERPOLATE_NEAREST)
		img.blend_rect(f, Rect2i(Vector2i.ZERO, f.get_size()),
			Vector2i(i * CELULA.x * ZOOM, 0))
	# linha do chao: o contrato poe os pes em y=103 da celula
	for x in img.get_width():
		img.set_pixel(x, 103 * ZOOM, Color(0.9, 0.3, 0.45, 1.0))
	img.save_png(saida)
	print("gravado: %s" % saida)
	get_tree().quit(0)
