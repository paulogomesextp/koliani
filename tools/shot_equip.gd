extends SceneTree
## Smoke-shot do carrossel de equipamento (`SeletorEquip`), para o rever sem
## ter de jogar ate' la'.
##
## Uso (PRECISA de janela -- em `--headless` o renderer dummy nao desenha):
##   Godot --window --screen 1 --script res://tools/shot_equip.gd -- \
##       <arma|armadura> <saida.png> [indice] [tudo_desbloqueado 0|1]
##
## `tudo_desbloqueado` (por omissao 1) da' todos os itens a' Koliani, senao
## o ecra so' mostra cartoes trancados.

const CENA := "res://scenes/ui/SeletorEquip.tscn"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var tipo: String = args[0] if args.size() > 0 else "arma"
	var saida: String = args[1] if args.size() > 1 else "user://equip.png"
	var indice: int = int(args[2]) if args.size() > 2 else -1
	var tudo: bool = (args.size() < 4) or args[3] == "1"

	await process_frame
	await process_frame
	# em `--script` os autoloads nao existem como IDENTIFICADOR (so' pela
	# arvore) -- ver a mesma manha em `folha_de_contacto.gd`.
	var estado: Node = get_root().get_node("/root/EstadoJogo")
	if tudo and estado:
		for a: Dictionary in Equipamento.ARMAS:
			if not (a["id"] in estado.armas):
				estado.armas.append(a["id"])
		for a: Dictionary in Equipamento.ARMADURAS:
			if not (a["id"] in estado.armaduras):
				estado.armaduras.append(a["id"])
		estado.arma_equipada = Equipamento.ARMAS[2]["id"]
		estado.armadura_equipada = Equipamento.ARMADURAS[1]["id"]

	var cena: PackedScene = load(CENA)
	var no := cena.instantiate()
	get_root().add_child(no)
	no.set_anchors_preset(Control.PRESET_FULL_RECT)
	no.configurar(tipo)
	await process_frame
	if indice >= 0:
		no.call("_ir_para", indice)
	for _i in 40:
		await process_frame
	await create_timer(0.6).timeout
	var img := get_root().get_texture().get_image()
	img.save_png(saida)
	print("shot -> ", saida)
	quit()
