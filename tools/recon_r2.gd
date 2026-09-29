extends SceneTree
## Inventario do que EXISTE mesmo num nivel depois de construido (a jornada
## de aproximacao e' gerada em runtime, portanto ler o `.tscn` nao chega).
## Despeja JSON: extensao, spawn, porta, superficies, inimigos por especie,
## zonas de vento, perigos, props e luzes.
##
## Uso: godot --headless --path . --script res://tools/recon_r2.gd -- <cena> <saida.json>

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var cena: String = args[0]
	var saida: String = args[1]
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es:
		var i := int(es.NIVEIS.find(cena))
		if i >= 0:
			es.indice_nivel = i
		es.checkpoint = Vector2.ZERO
	change_scene_to_file(cena)
	for _i in 8:
		await process_frame

	var d := {"cena": cena}
	var kol := get_first_node_in_group("koliani")
	if kol:
		d["spawn"] = [kol.global_position.x, kol.global_position.y]
	var raiz := current_scene
	var porta: Node = raiz.get_node_or_null("Porta") if raiz else null
	if porta:
		d["porta"] = [porta.global_position.x, porta.global_position.y]

	var x0 := INF
	var x1 := -INF
	var y0 := INF
	var y1 := -INF
	var n_sup := 0
	var tipos := {}
	var especies := {}
	var ventos := []
	var checkpoints := 0
	var luzes := 0
	var pilha: Array = [raiz]
	while not pilha.is_empty():
		var n: Node = pilha.pop_back()
		if n == null:
			continue
		for c in n.get_children():
			pilha.append(c)
		var cls := n.get_class()
		tipos[cls] = int(tipos.get(cls, 0)) + 1
		if n is Light2D:
			luzes += 1
		if n is Node2D:
			var p: Vector2 = (n as Node2D).global_position
			if n is StaticBody2D and ((n as StaticBody2D).collision_layer & 1) != 0:
				n_sup += 1
				x0 = minf(x0, p.x)
				x1 = maxf(x1, p.x)
				y0 = minf(y0, p.y)
				y1 = maxf(y1, p.y)
		if n.is_in_group("inimigos"):
			var e := "chefe" if not ("especie" in n) else String(n.especie)
			if "especie" in n and String(n.especie) == "":
				e = "chefe"
			especies[e] = int(especies.get(e, 0)) + 1
		if n is WindZone:
			var w := n as WindZone
			ventos.append({
				"nome": String(w.name),
				"pos": [w.global_position.x, w.global_position.y],
				"dir": [w.direcao.x, w.direcao.y],
				"intensidade": w.intensidade, "vmax": w.velocidade_max,
				"tam": [w.tamanho.x, w.tamanho.y],
				"ativa": w.ativa, "modo": int(w.modo),
			})
		if n.get_script() != null and String(n.get_script().resource_path).ends_with("checkpoint.gd"):
			checkpoints += 1
	d["extensao"] = [x0, x1, y0, y1]
	d["largura_px"] = x1 - x0
	d["superficies"] = n_sup
	d["inimigos"] = especies
	d["ventos"] = ventos
	d["checkpoints"] = checkpoints
	d["luzes"] = luzes
	var filtrados := {}
	for k in tipos:
		if int(tipos[k]) >= 3:
			filtrados[k] = tipos[k]
	d["tipos_de_no"] = filtrados
	d["total_nos"] = _contar(raiz)
	var f := FileAccess.open(saida, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d, "  "))
		f.close()
	print("RECON ", JSON.stringify(d))
	quit()


func _contar(n: Node) -> int:
	var t := 1
	for c in n.get_children():
		t += _contar(c)
	return t
