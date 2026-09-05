extends SceneTree
## Diz em que X de que nivel esta' uma camara -- para se poder ir la' ver.
##
## Constroi a jornada de cada nivel com `MAPA_CAMARAS` ligado e apanha o
## `x` de cada camara. Sem isto, para fotografar uma camara nova era
## preciso adivinhar o sitio (a jornada tem ate' 40 000 px) e as fotos
## saiam todas do mesmo pedaco de chao.
##
## Uso:
##   godot --headless --script res://tools/onde_esta_camara.gd -- <tipo> [tipo...]
##   godot --headless --script res://tools/onde_esta_camara.gd -- --todas
##
## Escreve tambem `user://camaras.txt` com uma linha por camara achada:
##   <tipo> <indice_nivel> <x>

func _init() -> void:
	var pedidos := OS.get_cmdline_user_args()
	var todas := pedidos.is_empty() or pedidos[0] == "--todas"
	OS.set_environment("MAPA_CAMARAS", "1")
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es == null:
		print("sem EstadoJogo"); quit(1); return

	# a camara so' se anuncia por `print`, portanto e' preciso apanhar o
	# stdout... o que nao da'. Em vez disso lemos do NO': o gerador guarda
	# o mapa em `_mapa_camaras` quando a variavel de ambiente esta' ligada.
	var achados: Array = []
	for idx in es.NIVEIS.size():
		es.indice_nivel = idx
		es.checkpoint = Vector2.ZERO
		es._limpar_jornada_ancora()
		var cena: PackedScene = load(es.NIVEIS[idx])
		if cena == null:
			continue
		var raiz := cena.instantiate()
		root.add_child(raiz)
		for _i in 10:
			await process_frame
		var ger := _achar(raiz, "CorredorAproximacao")
		if ger:
			var mapa: Variant = ger.get("_mapa_camaras")
			if mapa is Array:
				for e in mapa:
					var tipo: String = str(e[0])
					if todas or tipo in pedidos:
						achados.append([tipo, idx, float(e[1])])
		raiz.queue_free()
		await process_frame

	var txt := ""
	for a in achados:
		print("%-14s nivel %3d  x=%8.0f" % [a[0], a[1] + 1, a[2]])
		txt += "%s %d %.0f\n" % [a[0], a[1], a[2]]
	var f := FileAccess.open("user://camaras.txt", FileAccess.WRITE)
	if f:
		f.store_string(txt)
		f.close()
		print("-- %d camaras -> %s" % [achados.size(),
			ProjectSettings.globalize_path("user://camaras.txt")])
	quit(0)


func _achar(n: Node, nome: String) -> Node:
	if n.name == nome:
		return n
	for f in n.get_children():
		var r := _achar(f, nome)
		if r:
			return r
	return null
