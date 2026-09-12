extends SceneTree
## Smoke-shot do EDITOR DE LAYOUT DE TOQUE (Execution 9H), para o rever sem
## ter de correr o jogo num telemovel. PRECISA de janela (`--window
## --screen 1`): em `--headless` o renderer dummy nao desenha.
##
##   Godot --window --screen 1 --script res://tools/shot_layout_9h.gd -- <saida.png> [accao]
##
## `accao` (opcional) e' o controlo a mostrar selecionado ("saltar", "dash",
## "joy", "pausa"...). Por omissao seleciona o Salto, que e' o maior.

const EDITOR := "res://scripts/editor_layout_toque.gd"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0] if args.size() > 0 else "user://layout.png"
	var accao: String = args[1] if args.size() > 1 else "saltar"
	await process_frame
	await process_frame
	var fundo := ColorRect.new()
	fundo.color = Color(0.06, 0.03, 0.05)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(fundo)
	var ed: Control = (load(EDITOR) as Script).new()
	get_root().add_child(ed)
	for _i in 12:
		await process_frame
	var c: ControlosTacteis = ed.get("_controlos")
	if c:
		c.selecionado = accao
		c.queue_redraw()
	for _i in 30:
		await process_frame
	await create_timer(0.5).timeout
	var img := get_root().get_texture().get_image()
	img.save_png(saida)
	print("shot -> ", saida)
	quit()
