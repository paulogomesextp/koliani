extends SceneTree
## Diagnóstico do "seam" entre a Jornada e a geometria feita à mão / Casca.
## Uso: Godot --headless --script res://tools/diag_seam.gd -- <idx>

func _init() -> void:
	await process_frame
	var es := root.get_node("/root/EstadoJogo")
	var idx := 5
	var ua := OS.get_cmdline_user_args()
	if ua.size() > 0:
		idx = int(ua[0])
	es.indice_nivel = idx
	es.checkpoint = Vector2.ZERO
	es._limpar_jornada_ancora()
	var raiz := (load(es.NIVEIS[idx]) as PackedScene).instantiate()
	root.add_child(raiz)
	for _i in 14:
		await process_frame

	var kol := get_first_node_in_group("koliani") as Node2D
	var ger := raiz.get_node_or_null("CorredorAproximacao")
	var casca := raiz.get_node_or_null("Casca")
	print("idx=%d  koliani=%s" % [idx, str(kol.global_position) if kol else "?"])
	if casca:
		print("Casca: esquerda=%.0f topo=%.0f largura=%.0f chao_y=%.0f" % [
			casca.esquerda, casca.topo, casca.largura, casca.get("chao_y")])
		for nome in ["ParedeEsq", "ParedeDir", "Tecto", "ChaoFundo"]:
			var n := casca.get_node_or_null(nome)
			if n:
				print("  %s @ %s" % [nome, str(n.global_position)])
	# StaticBody / Area perto de uma faixa X
	var alvo_x := kol.global_position.x + 300.0 if ger == null else _seam_x(raiz)
	print("--- corpos com |x - %.0f| < 400 e |y - %.0f| < 260 ---" % [alvo_x, kol.global_position.y])
	_varre(raiz, alvo_x, kol.global_position.y)
	quit(0)


func _seam_x(raiz: Node) -> float:
	# ponto onde a jornada encontra o nível: ~ x da Porta menos o resto
	var p := raiz.get_node_or_null("Porta")
	var c := raiz.get_node_or_null("Chefe")
	var xs := []
	if p is Node2D: xs.append((p as Node2D).global_position.x)
	if c is Node2D: xs.append((c as Node2D).global_position.x)
	# heurística: o seam anda perto de x=0 (spawn original)
	return 0.0


func _varre(n: Node, ax: float, ay: float) -> void:
	if n is CollisionObject2D and n is Node2D:
		var gp: Vector2 = (n as Node2D).global_position
		if absf(gp.x - ax) < 400.0 and absf(gp.y - ay) < 300.0:
			var tam := "?"
			for ch in n.get_children():
				if ch is CollisionShape2D and ch.shape is RectangleShape2D:
					tam = str((ch.shape as RectangleShape2D).size)
			print("  %-22s %s  @ %s  tam=%s  layer=%d" % [
				n.name, n.get_class(), str(gp), tam, (n as CollisionObject2D).collision_layer])
	for c in n.get_children():
		_varre(c, ax, ay)
