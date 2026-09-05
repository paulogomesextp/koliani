extends SceneTree
## Lista o que existe num troco de X de um nivel -- com a JORNADA ja'
## construida. E' a ferramenta para responder a "o que e' que esta' aqui?"
## quando o `bot_gauntlet.gd` diz que parou em tal sitio: sem ela, a unica
## maneira era fotografar e olhar.
##
## Uso: godot --headless --script res://tools/ver_zona.gd -- <cena> <x0> <x1> [indice]
##
## Exemplo (o que ha' entre x=-1300 e x=-200 no nivel 1):
##   ... -- res://scenes/levels/Floresta_Putrefata.tscn -1300 -200 0

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var cena: String = a[0]
	var x0 := float(a[1])
	var x1 := float(a[2])
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es:
		es.indice_nivel = int(a[3]) if a.size() > 3 else 0
		es.checkpoint = Vector2.ZERO
	var raiz: Node = (load(cena) as PackedScene).instantiate()
	root.add_child(raiz)
	for _i in 14:
		await process_frame
	var lista: Array = []
	_juntar(raiz, lista, x0, x1)
	lista.sort_custom(func(p, q): return p[0] < q[0])
	for l in lista:
		print("x=%7.0f y=%7.0f  %-22s %s" % [l[0], l[1], l[2], l[3]])
	print("-- %d nos entre x=%.0f e x=%.0f" % [lista.size(), x0, x1])
	quit(0)


func _juntar(n: Node, fora: Array, x0: float, x1: float) -> void:
	if n is Node2D:
		var p: Vector2 = (n as Node2D).global_position
		if p.x >= x0 and p.x <= x1:
			var tam := ""
			if "tamanho" in n:
				tam = str(n.get("tamanho"))
			fora.append([p.x, p.y, n.get_class(), "%s %s" % [n.name, tam]])
	for f in n.get_children():
		_juntar(f, fora, x0, x1)
