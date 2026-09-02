extends SceneTree
## Verificador ESTATICO de alcance para os niveis feitos a mao. Instancia a
## cena, apanha todas as plataformas solidas + o spawn da Koliani + a Porta,
## e faz um grafo de "da' para saltar de A para B" com regras generosas
## (salto duplo da Koliani). Diz se a Porta e' alcancavel do spawn e lista
## as plataformas orfas (ilhas a que nao se chega).
##   Godot --headless --script res://tools/verifica_alcance.gd -- <cena.tscn>
##
## Regras (aproximadas, a favor da seguranca):
##   * vao horizontal entre bordas <= 210 px
##   * subida <= 118 px (salto + duplo); descer e' livre ate' 520 px
## Nao modela tectos nem plataformas moveis -- e' um crivo de "ilha morta".

const VAO_MAX := 210.0
const SUBIDA_MAX := 118.0
const QUEDA_MAX := 520.0

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("uso: -- <cena.tscn>"); quit(2); return
	await process_frame
	var cena: PackedScene = load(args[0])
	if cena == null:
		print("SEM CENA ", args[0]); quit(2); return
	# o `_alongar_nivel` do nivel_com_chefe.gd estica o nivel conforme o
	# `EstadoJogo.indice_nivel` -- sem isto herdava-se o indice do save da
	# maquina e verificava-se o nivel esticado como se fosse o N30.
	var estado: Node = root.get_node_or_null("EstadoJogo")
	if estado:
		var i := int(estado.NIVEIS.find(args[0]))
		estado.indice_nivel = maxi(i, 0)
		estado.checkpoint = Vector2.ZERO
		if i < 0:
			print("(aviso: cena fora de EstadoJogo.NIVEIS -- a verificar como N1)")
	var raiz := cena.instantiate()
	# esta ferramenta verifica a SALA FEITA À MÃO -- desliga a jornada
	# procedural, que traz plataformas móveis que o crivo estático não
	# modela (dariam órfãs falsas).
	if "corredor" in raiz:
		raiz.corredor = false
	root.add_child(raiz)
	for _i in 8:
		await process_frame

	# --- apanha plataformas (AABB do topo) ---
	var plats: Array = []
	_recolher(raiz, plats)
	if plats.is_empty():
		print("SEM PLATAFORMAS"); quit(2); return

	# --- spawn e porta ---
	var kol := get_first_node_in_group("koliani") as Node2D
	var porta := raiz.get_node_or_null("Porta") as Node2D
	if kol == null or porta == null:
		print("falta Koliani (%s) ou Porta (%s)" % [kol != null, porta != null]); quit(2); return

	var i_spawn := _plat_mais_perto(plats, kol.global_position + Vector2(0, 20))
	var i_porta := _plat_mais_perto(plats, porta.global_position + Vector2(0, 20))
	if i_spawn < 0 or i_porta < 0:
		print("spawn ou porta sem plataforma por baixo"); quit(2); return

	# --- grafo de alcance ---
	var n := plats.size()
	var adj: Array = []
	for i in n:
		adj.append([])
	for i in n:
		for j in n:
			if i == j:
				continue
			if _da_para_saltar(plats[i], plats[j]):
				adj[i].append(j)

	# BFS do spawn
	var vis := {}
	var fila := [i_spawn]
	vis[i_spawn] = true
	while not fila.is_empty():
		var a: int = int(fila.pop_front())
		for b in adj[a]:
			if not vis.has(b):
				vis[b] = true
				fila.append(b)

	var orfas: Array = []
	for i in n:
		if not vis.has(i):
			var pi: Dictionary = plats[i]
			orfas.append("%s@(%.0f,%.0f)" % [pi.nome, float(pi.cx), float(pi.topo)])

	var ok_porta: bool = vis.has(i_porta)
	print("cena=%s  plataformas=%d  spawn=#%d  porta=#%d  porta_alcancavel=%s" % [
		args[0].get_file(), n, i_spawn, i_porta, str(ok_porta)])
	if not orfas.is_empty():
		print("  ORFAS (%d): %s" % [orfas.size(), ", ".join(orfas)])
	if not ok_porta:
		# diz qual o degrau que falta: plataforma alcancada mais a' direita
		var melhor := -1
		var melhor_x := -1.0e9
		for i in vis.keys():
			var pk: Dictionary = plats[i]
			if float(pk.cx) > melhor_x:
				melhor_x = float(pk.cx)
				melhor = i
		var pm: Dictionary = plats[melhor]
		print("  <<< PORTA INALCANCAVEL -- para nos ~x=%.0f (%s)" % [float(pm.cx), pm.nome])
	quit(0 if (ok_porta and orfas.is_empty()) else 1)


func _recolher(no: Node, out: Array) -> void:
	for f in no.get_children():
		var e: Script = f.get_script()
		var s := ""
		if e:
			s = e.resource_path
		if s.ends_with("plataforma.gd") or s.ends_with("plataforma_ritmada.gd") \
				or s.ends_with("plataforma_quebra.gd") or s.ends_with("plataforma_espectral.gd") \
				or s.ends_with("plataforma_luz.gd"):
			var tv: Variant = f.get("tamanho")
			var tam: Vector2 = tv if tv != null else Vector2(200, 40)
			var p := f as Node2D
			out.append({
				"nome": String(f.name),
				"cx": p.global_position.x,
				"topo": p.global_position.y - tam.y * 0.5,
				"esq": p.global_position.x - tam.x * 0.5,
				"dir": p.global_position.x + tam.x * 0.5,
			})
		_recolher(f, out)


func _plat_mais_perto(plats: Array, pos: Vector2) -> int:
	var melhor := -1
	var melhor_d := 1.0e9
	for i in plats.size():
		var p: Dictionary = plats[i]
		var esq := float(p.esq); var dir := float(p.dir); var topo := float(p.topo)
		if pos.x < esq - 30.0 or pos.x > dir + 30.0:
			continue
		var d: float = absf(topo - pos.y)
		if topo >= pos.y - 40.0 and d < melhor_d:
			melhor_d = d
			melhor = i
	return melhor


func _da_para_saltar(a: Dictionary, b: Dictionary) -> bool:
	var a_esq := float(a.esq); var a_dir := float(a.dir); var a_topo := float(a.topo)
	var b_esq := float(b.esq); var b_dir := float(b.dir); var b_topo := float(b.topo)
	# vao horizontal entre bordas mais proximas
	var vao := 0.0
	if b_esq > a_dir:
		vao = b_esq - a_dir
	elif a_esq > b_dir:
		vao = a_esq - b_dir
	if vao > VAO_MAX:
		return false
	var dsub := a_topo - b_topo   # >0 => b esta' ACIMA de a
	if dsub > SUBIDA_MAX:
		return false
	if dsub < -QUEDA_MAX:
		return false
	return true
