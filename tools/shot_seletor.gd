extends SceneTree
## Smoke-shot do carrossel de NIVEIS (`SeletorNiveis`), para o rever sem ter
## de jogar. Irmao do `shot_equip.gd`.
##
## `tudo_desbloqueado` (por omissao 1) desliga o bloqueio, senao o carrossel
## so' deixa ver ate' a' fronteira do save.
##
## Uso (PRECISA de janela -- em `--headless` o renderer dummy nao desenha):
##   Godot --window --screen 1 --script res://tools/shot_seletor.gd -- \
##       <saida.png> [indice] [tudo_desbloqueado 0|1]

const CENA := "res://scenes/ui/SeletorNiveis.tscn"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0] if args.size() > 0 else "user://seletor.png"
	var indice: int = int(args[1]) if args.size() > 1 else 0
	var tudo: bool = (args.size() < 3) or args[2] == "1"

	await process_frame
	await process_frame
	var no := (load(CENA) as PackedScene).instantiate()
	get_root().add_child(no)
	no.set_anchors_preset(Control.PRESET_FULL_RECT)
	no.configurar(indice, not tudo)
	for _i in 40:
		await process_frame
	await create_timer(0.6).timeout
	var img := get_root().get_texture().get_image()
	img.save_png(saida)
	print("shot -> ", saida)
	quit()
