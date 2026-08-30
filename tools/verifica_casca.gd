extends SceneTree
## Verifica que a CascaMasmorra de cada nivel se construiu e emoldura o
## nivel sem trancar a Koliani/Porta/Chefe. Uso:
##   Godot --headless --script res://tools/verifica_casca.gd

const NIVEIS := [
	"Prisao_dos_Condenados", "Fornalha_dos_Pecadores", "Corredor_das_Execucoes",
	"Ala_dos_Mortos", "A_Cela_Zero", "Cemiterio_dos_Reis", "Galeria_dos_Ossos",
	"Cripta_das_Mil_Velas", "Templo_da_Serpente", "O_Abismo",
]


func _init() -> void:
	await process_frame
	var falhas := 0
	for nome in NIVEIS:
		var cena: PackedScene = load("res://scenes/levels/%s.tscn" % nome)
		var raiz := cena.instantiate()
		get_root().add_child(raiz)
		await process_frame
		await process_frame
		falhas += _checa(nome, raiz)
		raiz.queue_free()
		await process_frame
	print("\n=== %s ===" % ("TUDO OK" if falhas == 0 else "%d FALHA(S)" % falhas))
	quit(1 if falhas else 0)


func _checa(nome: String, raiz: Node) -> int:
	var casca := raiz.get_node_or_null("Casca")
	if casca == null:
		print("  %-24s SEM No' Casca" % nome)
		return 1
	var paredes := {}
	for c in casca.get_children():
		if c is StaticBody2D:
			for sub in c.get_children():
				if sub is CollisionShape2D and sub.shape is RectangleShape2D:
					var tam: Vector2 = sub.shape.size
					paredes[c.name] = Rect2(c.global_position - tam * 0.5, tam)
	if paredes.size() < 3:
		print("  %-24s so' %d parede(s)" % [nome, paredes.size()])
		return 1

	# retangulo interior jogavel
	var esq: float = casca.esquerda
	var topo: float = casca.topo
	var interior := Rect2(esq, topo, casca.largura, casca.altura)

	var alvos := ["Koliani", "Porta", "Chefe"]
	var mau := 0
	var msg := []
	for a in alvos:
		var n := raiz.get_node_or_null(a)
		if n == null:
			continue
		var p: Vector2 = (n as Node2D).global_position
		# dentro do X do interior (o Y pode sair pelo fundo -- poco)
		if p.x < interior.position.x + 40.0 or p.x > interior.end.x - 40.0:
			msg.append("%s fora em X (%.0f)" % [a, p.x])
			mau += 1
		# nao pode estar DENTRO de uma parede
		for pn in paredes:
			if paredes[pn].has_point(p):
				msg.append("%s dentro da %s" % [a, pn])
				mau += 1
	var ts := "  %-24s Casca %.0fx%.0f  paredes=%s" % [
		nome, casca.largura, casca.altura, str(paredes.keys())]
	if mau == 0:
		print(ts + "  OK")
	else:
		print(ts + "  <<< " + ", ".join(msg))
	return 1 if mau else 0
