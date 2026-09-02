extends SceneTree
## Screenshot de uma CÂMARA DE PUZZLE da jornada. Em vez de andar às cegas
## por x fixo (como o `shot_dev_nivel.gd`), procura na árvore a primeira
## peça do tipo pedido -- alavanca, sino, vela apagada, parede móvel,
## espelho, parede rachada -- leva lá a Koliani e grava o ecrã. É a maneira
## de rever de relance se um puzzle gerado está montado como devia.
##
##   Godot --window --screen 1 --script res://tools/shot_puzzle.gd -- \
##       <indice_0based> <peca> <saida.png> [zoom] [recuo_x]
##
## `peca`: alavanca | sino | vela | prensa | espelho | fragil
## `recuo_x`: quanto se fica ATRÁS da peça (por omissão 220 px, para a
## câmara apanhar o obstáculo e a solução no mesmo enquadramento).

const CLASSES := {
	"alavanca": "Alavanca",
	"sino": "SinoTorre",
	"vela": "Vela",
	"prensa": "ParedeMovel",
	"espelho": "Espelho",
	"fragil": "ParedeFragil",
}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var idx: int = int(args[0]) if args.size() > 0 else 0
	var peca: String = args[1] if args.size() > 1 else "alavanca"
	var saida: String = args[2] if args.size() > 2 else "user://puzzle.png"
	var zoom: float = float(args[3]) if args.size() > 3 else 0.9
	var recuo: float = float(args[4]) if args.size() > 4 else 220.0

	await process_frame
	var estado: Node = get_root().get_node("/root/EstadoJogo")
	estado.ativar_modo_dev()
	estado.indice_nivel = idx
	estado.checkpoint = Vector2.ZERO
	estado._limpar_jornada_ancora()
	change_scene_to_file(estado.NIVEIS[idx])
	for _i in 40:
		await process_frame
	await create_timer(0.8).timeout

	var k := get_first_node_in_group("koliani") as Node2D
	if k == null:
		print("sem koliani"); quit(1); return
	var alvo := _procurar(get_root(), String(CLASSES.get(peca, "Alavanca")), peca == "vela")
	if alvo == null:
		print("nao ha nenhuma peca '%s' no nivel %d" % [peca, idx + 1]); quit(1); return

	var cam := k.get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.zoom = Vector2(zoom, zoom)
		cam.position_smoothing_enabled = false
	k.global_position = alvo.global_position - Vector2(recuo, 40.0)
	if "velocity" in k:
		k.velocity = Vector2.ZERO
	for _j in 20:
		await process_frame
	await create_timer(0.4).timeout
	var img := get_root().get_texture().get_image()
	img.save_png(saida)
	print("puzzle '%s' do nivel %d em x=%.0f -> %s"
		% [peca, idx + 1, alvo.global_position.x, saida])
	quit()


## Primeira peça da classe pedida (a mais à esquerda). Para as velas só
## interessa uma APAGADA -- a acesa é o exemplo que ensina a regra.
func _procurar(no: Node, classe: String, so_apagada: bool) -> Node2D:
	var melhor: Node2D = null
	for f in no.get_children():
		if f is Node2D and f.get_class() != "" and f.is_class("Node2D"):
			var bate: bool = f.get_script() != null \
				and String(f.get_script().resource_path).get_file().get_basename() \
					== _slug(classe)
			if bate and so_apagada and "acesa" in f and bool(f.acesa):
				bate = false
			if bate and (melhor == null or (f as Node2D).global_position.x < melhor.global_position.x):
				melhor = f as Node2D
		var dentro := _procurar(f, classe, so_apagada)
		if dentro and (melhor == null or dentro.global_position.x < melhor.global_position.x):
			melhor = dentro
	return melhor


## "SinoTorre" -> "sino_torre" (o nome do ficheiro do script).
func _slug(classe: String) -> String:
	var out := ""
	for i in classe.length():
		var c := classe[i]
		if c == c.to_upper() and c != c.to_lower() and i > 0:
			out += "_"
		out += c.to_lower()
	return out
