extends SceneTree
## Conta os CANDEEIROS/TOCHAS que o `nivel_com_chefe.gd::_iluminar` poe em
## cada nivel, e o maior VAO sem luz nenhuma ao longo do percurso.
##
## Como a jornada e' semeada com o INDICE REAL do nivel (`hash("jornada4|idx")`),
## carregar a cena com o indice errado gera outro nivel e a medicao nao vale
## nada -- por isso o indice e' posto no `EstadoJogo` antes de carregar (o
## mesmo cuidado do `tools/verifica_portais.gd`).
##
##   Godot --headless --script res://tools/verifica_luzes.gd -- [n_niveis]
##
## Com `n_niveis = 1` despeja tambem as coordenadas das luzes desse nivel --
## serve para apontar la' uma screenshot (`tools/shot_plataforma.gd`).
##
## Sai != 0 se algum nivel ficar sem luzes nenhumas.

## Acima disto o troco fica as escuras tempo de mais (a luz tem ~210 px de
## raio; `ESPACO_LUZ` e' 760, portanto vaos muito maiores sao buracos).
const VAO_MAXIMO := 3000.0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var quantos: int = int(args[0]) if args.size() > 0 else 0

	# em `--script` os autoloads nao existem como identificador, e antes do
	# primeiro `process_frame` nem sequer se lhes chega pela arvore
	await process_frame
	var estado := root.get_node_or_null("EstadoJogo")
	if estado == null:
		push_error("sem EstadoJogo -- os autoloads nao arrancaram")
		quit(1)
		return
	var niveis: Array = estado.get("NIVEIS")
	if quantos <= 0 or quantos > niveis.size():
		quantos = niveis.size()

	var maus := 0
	for i in quantos:
		estado.set("indice_nivel", i)
		var cena: String = niveis[i]["cena"] if niveis[i] is Dictionary else str(niveis[i])
		change_scene_to_file(cena)
		await process_frame
		await process_frame
		await process_frame
		await process_frame

		var luzes: Array[Node] = []
		var por_ver: Array[Node] = []
		if current_scene:
			por_ver.append(current_scene)
		while not por_ver.is_empty():
			var n: Node = por_ver.pop_back()
			for c in n.get_children():
				por_ver.append(c)
			if n.get_class() == "Node2D" and n.get_script() != null \
					and (n.get_script() as Script).resource_path.ends_with("candeeiro.gd"):
				luzes.append(n)

		var xs: Array[float] = []
		for l in luzes:
			xs.append((l as Node2D).global_position.x)
		xs.sort()
		var vao := 0.0
		for j in range(1, xs.size()):
			vao = maxf(vao, xs[j] - xs[j - 1])

		var marca := "ok "
		if luzes.is_empty():
			marca = "SEM"
			maus += 1
		elif vao > VAO_MAXIMO:
			marca = "vao"
		if quantos == 1:
			for l in luzes:
				var lp: Vector2 = (l as Node2D).global_position
				print("   luz %s  x=%.0f y=%.0f" % [l.get("tipo"), lp.x, lp.y])
		print("%s N%-3d %-34s luzes=%-3d  vao_max=%.0f  span=%.0f" % [
			marca, i + 1, cena.get_file(), luzes.size(), vao,
			(xs[-1] - xs[0]) if xs.size() > 1 else 0.0])

	print("--- niveis sem luz nenhuma: %d ---" % maus)
	quit(1 if maus > 0 else 0)
