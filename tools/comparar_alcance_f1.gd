extends SceneTree
## F1 passagem 1 -- ACESSIBILIDADE dos 100 níveis com a envolvente de salto
## ANTES vs DEPOIS da mudança de física.
##
## O `verifica_alcance.gd` usa números fixos (vão 210, subida 118) e por isso
## NÃO reage a uma mudança do salto. Este mede o que interessa a uma mudança de
## física: com a envolvente REAL medida pela bancada (`tools/bench_movimento_f1`,
## experiência `envolvente`: vão máximo por subida, a correr, botão segurado),
## que plataformas passam a ser alcançáveis, quantos saltos de espinha se
## poupam até à porta e se algum nível ganha um atalho grave.
##
## Regime por nível: salto simples até ao nível 5 (contrato da Região I),
## salto duplo depois. Plataformas móveis entram como AABB parada, igual nas
## duas envolventes, por isso o modelo é comparável (não é uma prova de
## jogabilidade, é um detetor de DIFERENÇAS).
##
##   godot --headless --path . --script res://tools/comparar_alcance_f1.gd -- <saida.json>

const CRIVO := preload("res://tools/verifica_alcance.gd")

## dy (subida topo->topo; negativo = descida) -> vão máximo entre bordas, px.
## Medidos: `docs/qa/f1_movimento/f1_envolvente_antes_depois.json`.
const ANTES_S := {-140.0: 220.0, -60.0: 200.0, 0.0: 180.0, 40.0: 170.0, 64.0: 160.0,
	80.0: 150.0, 100.0: 140.0, 120.0: 130.0, 140.0: 110.0}
const DEPOIS_S := {-140.0: 280.0, -60.0: 250.0, 0.0: 230.0, 40.0: 220.0, 64.0: 210.0,
	80.0: 200.0, 100.0: 200.0, 120.0: 190.0, 140.0: 180.0, 160.0: 170.0, 180.0: 150.0,
	200.0: 130.0}
const ANTES_D := {-140.0: 330.0, -60.0: 310.0, 0.0: 300.0, 64.0: 280.0, 100.0: 260.0,
	140.0: 250.0, 180.0: 230.0}
const DEPOIS_D := {-140.0: 430.0, -60.0: 410.0, 0.0: 390.0, 64.0: 370.0, 100.0: 360.0,
	140.0: 340.0, 180.0: 330.0, 200.0: 320.0}
const NIVEL_SALTO_DUPLO := 5
const MARGEM_PONTA := 26.0
const QUEDA_MAX := 520.0


func _gap_max(tab: Dictionary, dy: float) -> float:
	var ks: Array = tab.keys()
	ks.sort()
	if dy > float(ks[-1]):
		return -1.0
	if dy <= float(ks[0]):
		# descida mais funda que a medida: extrapola pela inclinação dos 2 pontos mais fundos
		var k0f: float = ks[0]
		var k1f: float = ks[1]
		var decl := (float(tab[k0f]) - float(tab[k1f])) / (k1f - k0f)
		return float(tab[k0f]) + decl * (k0f - dy)
	for i in range(1, ks.size()):
		if dy <= float(ks[i]):
			var k0: float = ks[i - 1]
			var k1: float = ks[i]
			var t := (dy - k0) / (k1 - k0)
			return lerpf(float(tab[k0]), float(tab[k1]), t)
	return -1.0


func _aresta(a: Dictionary, b: Dictionary, tab: Dictionary) -> bool:
	var a_esq := float(a.esq)
	var a_dir := float(a.dir)
	var b_esq := float(b.esq)
	var b_dir := float(b.dir)
	var vao := 0.0
	if b_esq > a_dir:
		vao = b_esq - a_dir
	elif a_esq > b_dir:
		vao = a_esq - b_dir
	var dsub := float(a.topo) - float(b.topo)
	if dsub < -QUEDA_MAX:
		return false
	var g := _gap_max(tab, dsub)
	if g < 0.0 or vao > g:
		return false
	if dsub > 0.0:
		if b_esq - a_esq < MARGEM_PONTA and a_dir - b_dir < MARGEM_PONTA:
			return false
	return true


## BFS; devolve [dist por índice (-1 = inalcançável)]. `pai` recebe o pai de cada nó.
func _bfs(plats: Array, i0: int, tab: Dictionary, pai: Array = []) -> Array:
	var dist: Array = []
	dist.resize(plats.size())
	dist.fill(-1)
	pai.resize(plats.size())
	pai.fill(-1)
	dist[i0] = 0
	var fila: Array = [i0]
	while not fila.is_empty():
		var a: int = fila.pop_front()
		for b in plats.size():
			if dist[b] >= 0 or b == a:
				continue
			if _aresta(plats[a], plats[b], tab):
				dist[b] = dist[a] + 1
				pai[b] = a
				fila.append(b)
	return dist


func _init() -> void:
	await process_frame
	var estado: Node = root.get_node_or_null("EstadoJogo")
	if estado == null:
		print("SEM EstadoJogo")
		quit(2)
		return
	var args := OS.get_cmdline_user_args()
	var saida := String(args[0]) if args.size() > 0 else "res://work/comparar_alcance_f1.json"
	var niveis: Array = estado.NIVEIS
	var linhas: Array = []
	var graves: Array = []
	var tot_novas := 0
	for n in niveis.size():
		var cena := String(niveis[n])
		if cena.get_file() == "O_Trono_de_Zeriko.tscn":
			continue
		var packed: PackedScene = load(cena)
		if packed == null:
			continue
		estado.indice_nivel = n
		estado.checkpoint = Vector2.ZERO
		var raiz := packed.instantiate()
		root.add_child(raiz)
		for _i in 8:
			await process_frame
		var plats: Array = []
		CRIVO._recolher(raiz, plats)
		var kol := get_first_node_in_group("koliani") as Node2D
		var porta := raiz.get_node_or_null("Porta") as Node2D
		if plats.is_empty() or kol == null:
			raiz.queue_free()
			await process_frame
			continue
		var i0: int = CRIVO._plat_mais_perto(plats, kol.global_position + Vector2(0, 20))
		var iP := -1
		if porta:
			iP = CRIVO._plat_mais_perto(plats, porta.global_position + Vector2(0, 20))
		var duplo := n >= NIVEL_SALTO_DUPLO
		var tab_a: Dictionary = ANTES_D if duplo else ANTES_S
		var tab_d: Dictionary = DEPOIS_D if duplo else DEPOIS_S
		var d_a: Array = _bfs(plats, i0, tab_a) if i0 >= 0 else []
		var pai_d: Array = []
		var d_d: Array = _bfs(plats, i0, tab_d, pai_d) if i0 >= 0 else []
		var alc_a := 0
		var alc_d := 0
		var novas: Array = []
		for i in d_a.size():
			if d_a[i] >= 0:
				alc_a += 1
			if d_d[i] >= 0:
				alc_d += 1
			if d_a[i] < 0 and d_d[i] >= 0:
				novas.append(i)
			if d_a[i] >= 0 and d_d[i] < 0:
				graves.append("[%d] REGRESSAO: %s deixou de ser alcancavel" % [n + 1, plats[i].nome])
		# 1.ª aresta nova (a mais perto do spawn): onde a física nova abre caminho
		var primeira := ""
		var melhor_d := 1000000
		for i in novas:
			if d_d[i] < melhor_d and pai_d[i] >= 0:
				melhor_d = d_d[i]
				var A2: Dictionary = plats[pai_d[i]]
				var B2: Dictionary = plats[i]
				var vao2 := maxf(maxf(float(B2.esq) - float(A2.dir), float(A2.esq) - float(B2.dir)), 0.0)
				primeira = "%s@(%.0f,%.0f) -> %s@(%.0f,%.0f) vao=%.0f subida=%.0f" % [
					A2.nome, float(A2.cx), float(A2.topo), B2.nome, float(B2.cx), float(B2.topo),
					vao2, float(A2.topo) - float(B2.topo)]
		if primeira != "" and (n < 5 or novas.size() > 40):
			graves.append("[%d] 1.a aresta nova (%d plat. novas): %s" % [n + 1, novas.size(), primeira])
		var h_a: int = d_a[iP] if iP >= 0 and not d_a.is_empty() else -2
		var h_d: int = d_d[iP] if iP >= 0 and not d_d.is_empty() else -2
		var linha := {"nivel": n + 1, "cena": cena.get_file(), "regime": "duplo" if duplo else "simples",
			"plataformas": plats.size(), "alcancadas_antes": alc_a, "alcancadas_depois": alc_d,
			"novas": novas.size(), "primeira_aresta_nova": primeira, "saltos_ate_porta_antes": h_a, "saltos_ate_porta_depois": h_d}
		linhas.append(linha)
		tot_novas += novas.size()
		# atalho grave: menos de metade dos saltos até à porta (com pelo menos 6 antes)
		if h_a >= 6 and h_d >= 0 and float(h_d) < float(h_a) * 0.5:
			graves.append("[%d] ATALHO: saltos ate a porta %d -> %d" % [n + 1, h_a, h_d])
		if h_a < 0 and h_d >= 0:
			graves.append("[%d] PORTA passou de inalcancavel a alcancavel" % [n + 1])
			# arestas do caminho novo que a envolvente ANTIGA não fazia
			var no := iP
			while no != i0 and no >= 0:
				var pa: int = pai_d[no]
				if pa < 0:
					break
				if not _aresta(plats[pa], plats[no], tab_a):
					var A: Dictionary = plats[pa]
					var B: Dictionary = plats[no]
					var vao_e := maxf(float(B.esq) - float(A.dir), float(A.esq) - float(B.dir))
					graves.append("      aresta nova: %s@(%.0f,%.0f) -> %s@(%.0f,%.0f)  vao=%.0f  subida=%.0f" % [
						A.nome, float(A.cx), float(A.topo), B.nome, float(B.cx), float(B.topo),
						maxf(vao_e, 0.0), float(A.topo) - float(B.topo)])
				no = pa
		if h_a >= 0 and h_d < 0:
			graves.append("[%d] REGRESSAO: PORTA deixou de ser alcancavel" % [n + 1])
		raiz.queue_free()
		await process_frame
	var f := FileAccess.open(saida, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"niveis": linhas, "sinais": graves, "novas_total": tot_novas}, "  "))
		f.close()
	var mais := 0
	for l in linhas:
		if int(l["novas"]) > 0:
			mais += 1
	print("=== ACESSIBILIDADE F1: %d niveis medidos | %d com plataformas novas alcancaveis (%d no total) | %d sinais" % [
		linhas.size(), mais, tot_novas, graves.size()])
	for g in graves:
		print("  ", g)
	quit(0)
