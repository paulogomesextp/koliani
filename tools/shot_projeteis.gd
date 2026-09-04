extends SceneTree
## Bancada dos PROJECTEIS: poe lado a lado o tiro da Koliani, o Kamehameha,
## a bola do Zeriko e o portal de fim de nivel, sobre fundo escuro, e grava
## um PNG. Serve para ver a arte sem ter de jogar ate' la'.
##
##   Godot --window --screen 1 --resolution 1280x720 \
##     --script res://tools/shot_projeteis.gd -- <saida.png> [segundos]

## O tiro da Koliani deixou de sortear formas: e' o laser roxo do pack
## Wenrexa, um so' sprite (ver `ProjetilKoliani.CORPO`). A coluna que ficou
## a -1 em cada peca era o indice da forma a forcar -- ja' nao serve, mas
## fica para o caso de voltar a haver variantes.
const PECAS := [
	["res://scenes/actors/ProjetilKoliani.tscn", "laser da Koliani", Vector2(230, 220), -1],
	["res://scenes/actors/KamehamehaKoliani.tscn", "kamehameha", Vector2(660, 400), -1],
	["res://scenes/actors/ProjetilZeriko.tscn", "bola do Zeriko", Vector2(1070, 220), -1],
	["res://scenes/actors/Porta.tscn", "portal de fim", Vector2(700, 570), -1],
]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0] if args.size() > 0 else "user://projeteis.png"
	var segundos: float = float(args[1]) if args.size() > 1 else 1.0

	var raiz := Node2D.new()
	var fundo := ColorRect.new()
	fundo.color = Color(0.05, 0.03, 0.09)
	fundo.size = Vector2(1280, 720)
	raiz.add_child(fundo)
	root.add_child(raiz)
	current_scene = raiz
	await process_frame

	for peca: Array in PECAS:
		# suporte proprio: assim a etiqueta anda sempre colada a' peca
		var suporte := Node2D.new()
		suporte.position = peca[2]
		raiz.add_child(suporte)
		var no := (load(peca[0]) as PackedScene).instantiate() as Node2D
		suporte.add_child(no)
		# os projecteis andam sozinhos no `_physics_process`; congela-os para
		# ficarem no sitio o tempo do retrato (a animacao do sprite continua).
		# SO' DEPOIS do add_child -- ao entrar na arvore o GDScript volta a
		# ligar os callbacks que o script define, e apagava este pedido.
		no.set_physics_process(false)
		var etiqueta := Label.new()
		etiqueta.text = peca[1]
		etiqueta.position = Vector2(-70, 70)
		suporte.add_child(etiqueta)

	var t := 0.0
	while t < segundos:
		t += 1.0 / 60.0
		await process_frame

	await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(saida)
	print("shot -> ", saida)
	quit()
