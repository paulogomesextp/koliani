extends SceneTree
## Lista, por ordem, as camaras que a jornada de UM nivel constroi.
## E' o diagnostico para saber PORQUE e' que dois builds do mesmo nivel
## diferem -- a geometria e' consequencia da sequencia de camaras.
##   godot --headless --path . --script res://tools/camaras_do_nivel.gd -- <indice>
func _init() -> void:
	OS.set_environment("MAPA_CAMARAS", "1")
	Engine.time_scale = 0.0
	await process_frame
	var e := root.get_node("/root/EstadoJogo")
	e.modo_teste = true
	var i := int(OS.get_cmdline_user_args()[0])
	e.indice_nivel = i
	e.iniciar_sessao_nivel(true)
	var c: Node = load(e.NIVEIS[i]).instantiate()
	root.add_child(c)
	for _f in 90:
		await process_frame
	var g: Node = c.get("_gerador")
	if g == null:
		print("SEM GERADOR"); quit(1); return
	var mapa: Array = g.get("_mapa_camaras")
	var nomes: Array[String] = []
	for m in mapa:
		nomes.append(String(m[0]))
	print("NIVEL %d CAMARAS: %s" % [i, ",".join(nomes)])
	quit(0)
