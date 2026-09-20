extends SceneTree
## Conta PointLight2D num nivel construido -- o jogo e' mobile a 60fps e
## espalhar luzes por uma jornada de dezenas de milhares de px tem custo.
func _init() -> void:
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
	print("NIVEL %d: %d PointLight2D" % [i, _contar(c)])
	quit(0)

func _contar(n: Node) -> int:
	var t := 1 if n is PointLight2D else 0
	for f in n.get_children():
		t += _contar(f)
	return t
