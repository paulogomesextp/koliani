extends SceneTree
## Folha de contacto da campanha: um screenshot de CADA um dos 30 níveis,
## montados numa grelha 6x5 (uma linha por região). Serve para ver de
## relance se alguma região está escura de mais, se um fundo destoa ou se um
## nível ficou partido, sem ter de jogar os trinta.
##
##   Godot --screen 1 --script res://tools/folha_de_contacto.gd -- \
##       <saida.png> [zoom] [avanco_x]
##
## `avanco_x` = quanto se anda para dentro da jornada antes do retrato
## (por omissão 2400 px, já longe da plataforma de partida).
## NB: precisa de janela (não corre em --headless).

const COLS := 5     # 5 níveis por região
const CEL_W := 320
const CEL_H := 180


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0] if args.size() > 0 else "user://folha.png"
	var zoom: float = float(args[1]) if args.size() > 1 else 1.4
	var avanco: float = float(args[2]) if args.size() > 2 else 2400.0

	await process_frame
	var estado: Node = get_root().get_node("/root/EstadoJogo")
	estado.ativar_modo_dev()
	var niveis: Array = estado.NIVEIS
	var linhas := int(ceil(float(niveis.size()) / float(COLS)))
	var folha := Image.create(CEL_W * COLS, CEL_H * linhas, false, Image.FORMAT_RGBA8)
	folha.fill(Color(0.04, 0.03, 0.06, 1.0))

	for idx in niveis.size():
		estado.indice_nivel = idx
		estado.checkpoint = Vector2.ZERO
		estado._limpar_jornada_ancora()
		change_scene_to_file(niveis[idx])
		for _i in 30:
			await process_frame
		await create_timer(0.5).timeout
		var k := get_first_node_in_group("koliani") as Node2D
		if k:
			var cam := k.get_node_or_null("Camera2D") as Camera2D
			if cam:
				cam.zoom = Vector2(zoom, zoom)
				cam.position_smoothing_enabled = false
			k.global_position.x += avanco
			k.global_position.y -= 40.0
			if "velocity" in k:
				k.velocity = Vector2.ZERO
			for _j in 16:
				await process_frame
		await create_timer(0.35).timeout
		var img := get_root().get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)  # o viewport vem em RGB8 -> blit_rect exige o mesmo formato
		img.resize(CEL_W, CEL_H, Image.INTERPOLATE_BILINEAR)
		folha.blit_rect(img, Rect2i(0, 0, CEL_W, CEL_H),
			Vector2i((idx % COLS) * CEL_W, (idx / COLS) * CEL_H))
		print("  %2d/%d  %s" % [idx + 1, niveis.size(), String(niveis[idx]).get_file()])

	folha.save_png(saida)
	print("folha -> ", saida)
	quit()
