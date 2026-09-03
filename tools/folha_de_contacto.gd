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
## (por omissão 2400 px, já longe da plataforma de partida). A Koliani é
## POUSADA na plataforma mais próxima desse X: até 3 set 2026 era só um
## `position.x += avanco`, e como a espinha da jornada é feita de degraus
## muito espaçados, em cerca de um terço dos níveis ela calhava num vão,
## caía os 0,6 s até ao retrato e a célula saía com ela sozinha no vazio.
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
			var alvo_x: float = k.global_position.x + avanco
			var pouso: Vector2 = _pouso_perto(get_root(), alvo_x)
			k.global_position = pouso if pouso != Vector2.INF 				else Vector2(alvo_x, k.global_position.y - 40.0)
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


## Ponto de pouso mais perto de `alvo_x`: o topo da plataforma cujo centro
## está mais próximo. `Vector2.INF` se não houver nenhuma.
static func _pouso_perto(raiz: Node, alvo_x: float) -> Vector2:
	var melhor := Vector2.INF
	var dist := INF
	for p in _plataformas(raiz):
		var d: float = absf(p.global_position.x - alvo_x)
		if d < dist:
			dist = d
			var tam: Vector2 = p.get("tamanho")
			melhor = Vector2(p.global_position.x, p.global_position.y - tam.y * 0.5 - 40.0)
	return melhor


static func _plataformas(n: Node, fora: Array[Node2D] = []) -> Array[Node2D]:
	var sc: Variant = n.get_script()
	if sc is Script and String((sc as Script).resource_path).ends_with("plataforma.gd"):
		fora.append(n as Node2D)
	for f in n.get_children():
		_plataformas(f, fora)
	return fora
