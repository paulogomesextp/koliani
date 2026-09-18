extends SceneTree
## Camara de prova da Regiao II: carrega um nivel e grava varios PNGs em
## pontos pedidos, sem tocar em nada da cena (so' move a Koliani, como o
## `shot_plataforma.gd` ja' fazia). Para o N10 sabe tambem esperar por uma
## FASE do chefe antes de disparar.
##
## Uso:
##   godot --path . --resolution 1280x720 --script res://tools/shot_r2.gd -- \
##     <cena> <pasta_saida> <prefixo> <pontos>
##   <pontos> = "nome@x,y;nome@x,y;..."  ou  "nome#FASE" (espera a fase)
##   Um ponto sem @ nem # dispara onde a Koliani nascer.

var _ref_y := 600.0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var cena: String = args[0]
	var pasta: String = args[1]
	var prefixo: String = args[2]
	var pontos: String = args[3] if args.size() > 3 else "inicio"
	var espera: float = float(args[4]) if args.size() > 4 else 0.9
	DirAccess.make_dir_recursive_absolute(pasta)
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es:
		var i := int(es.NIVEIS.find(cena))
		if i >= 0:
			es.indice_nivel = i
		es.checkpoint = Vector2.ZERO
		es.vidas = 99
	change_scene_to_file(cena)
	for _i in 8:
		await process_frame
	var kol := get_first_node_in_group("koliani")
	if kol:
		_ref_y = kol.global_position.y
	var chefe: Node = null
	if current_scene:
		chefe = current_scene.get_node_or_null("Chefe")
		if chefe == null:
			chefe = current_scene.get_node_or_null("Guardiao")
	for p in pontos.split(";", false):
		# reapanhar a Koliani a cada ponto: se ela morreu (cair num vao), a
		# cena recarregou e a referencia antiga esta' morta -- as fotos
		# seguintes saiam todas do checkpoint, iguais umas as outras.
		if kol == null or not is_instance_valid(kol) or not kol.is_inside_tree():
			kol = get_first_node_in_group("koliani")
			if current_scene:
				chefe = current_scene.get_node_or_null("Chefe")
				if chefe == null:
					chefe = current_scene.get_node_or_null("Guardiao")
		var nome := p
		if "#" in p:
			var par := p.split("#")
			nome = par[0]
			await _esperar_fase(chefe, kol, par[1])
		elif "@" in p:
			var par2 := p.split("@")
			nome = par2[0]
			var xy := par2[1].split(",")
			if kol:
				var px := float(xy[0])
				# so' X? procurar o chao debaixo desse X -- a jornada e'
				# gerada em runtime e ninguem sabe a altura dela de cor.
				var py: float = float(xy[1]) if xy.size() > 1 \
					else _chao_em(px, _ref_y)
				kol.global_position = Vector2(px, py)
				if kol.has_method("reset_physics_interpolation"):
					kol.reset_physics_interpolation()
				for _i in 10:
					await process_frame
		await create_timer(espera).timeout
		var img := get_root().get_texture().get_image()
		var saida := "%s/%s_%s.png" % [pasta, prefixo, nome]
		img.save_png(saida)
		print("shot -> ", saida)
	quit()


## Empurra a Koliani para a arena e espera que o chefe entre na fase pedida.
func _esperar_fase(chefe: Node, kol: Node, fase: String) -> void:
	if chefe == null:
		return
	var alvo := _valor_da_fase(chefe, fase)
	var limite := 2600
	while limite > 0:
		limite -= 1
		await process_frame
		if kol and is_instance_valid(kol) and is_instance_valid(chefe):
			# ficar ao alcance para o chefe acordar e ciclar os ataques
			var dx: float = chefe.global_position.x - kol.global_position.x
			if absf(dx) > 170.0:
				kol.global_position.x += signf(dx) * 3.0
		if alvo >= 0 and is_instance_valid(chefe) and int(chefe.get("_fase")) == alvo:
			return


## Y de spawn seguro sobre a plataforma que cubra este X. NAO a mais alta --
## isso punha a Koliani em cima do TECTO da CascaMasmorra, e as fotos saiam
## todas iguais, do lado de fora do nivel. A referencia e' a altura a que ela
## nasce: a plataforma boa e' a que estiver mais perto disso.
func _chao_em(x: float, ref := 600.0) -> float:
	var melhor := INF
	var melhor_d := INF
	var pilha: Array = [current_scene]
	while not pilha.is_empty():
		var n: Node = pilha.pop_back()
		if n == null:
			continue
		for c in n.get_children():
			pilha.append(c)
		if not (n is StaticBody2D):
			continue
		var sb := n as StaticBody2D
		if (sb.collision_layer & 1) == 0:
			continue
		for c in sb.get_children():
			if not (c is CollisionShape2D):
				continue
			var cs := c as CollisionShape2D
			if cs.disabled or not (cs.shape is RectangleShape2D):
				continue
			var r := (cs.shape as RectangleShape2D).size
			var t := cs.global_transform
			var mx := r.x * 0.5 * t.get_scale().x
			var my := r.y * 0.5 * t.get_scale().y
			if x < t.origin.x - mx or x > t.origin.x + mx:
				continue
			if my > 500.0:      # paredes/tectos da casca nao contam
				continue
			var topo: float = t.origin.y - my
			var d: float = absf(topo - ref)
			if d < melhor_d:
				melhor_d = d
				melhor = topo
	return (melhor - 60.0) if melhor < INF else (ref - 60.0)


func _valor_da_fase(chefe: Node, nome: String) -> int:
	var s: Script = chefe.get_script()
	if s == null:
		return -1
	for c in s.get_script_constant_map().values():
		if c is Dictionary and (c as Dictionary).has(nome):
			return int((c as Dictionary)[nome])
	return -1
