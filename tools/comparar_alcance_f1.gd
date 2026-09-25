extends SceneTree
## F1 passagens 1 e 2 -- ACESSIBILIDADE dos 100 níveis com a envolvente de salto
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
const P2_S := {-140.0: 260.0, -60.0: 240.0, 0.0: 220.0, 40.0: 200.0, 64.0: 190.0,
	80.0: 190.0, 100.0: 180.0, 120.0: 160.0, 140.0: 150.0}
const P2_D := {-140.0: 420.0, -60.0: 390.0, 0.0: 380.0, 64.0: 350.0, 100.0: 340.0,
	140.0: 330.0, 180.0: 310.0, 200.0: 300.0}
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
	var sinais: Array = []
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
		var tab_l: Dictionary = ANTES_D if duplo else ANTES_S
		var tab_1: Dictionary = DEPOIS_D if duplo else DEPOIS_S
		var tab_2: Dictionary = P2_D if duplo else P2_S
		var d_l: Array = _bfs(plats, i0, tab_l) if i0 >= 0 else []
		var d_1: Array = _bfs(plats, i0, tab_1) if i0 >= 0 else []
		var d_2: Array = _bfs(plats, i0, tab_2) if i0 >= 0 else []
		var nov1 := 0
		var nov2 := 0
		var perdas2 := 0
		for i in d_l.size():
			if d_l[i] < 0 and d_1[i] >= 0:
				nov1 += 1
			if d_l[i] < 0 and d_2[i] >= 0:
				nov2 += 1
			if d_l[i] >= 0 and d_2[i] < 0:
				perdas2 += 1
		var h_l: int = d_l[iP] if iP >= 0 and not d_l.is_empty() else -2
		var h_1: int = d_1[iP] if iP >= 0 and not d_1.is_empty() else -2
		var h_2: int = d_2[iP] if iP >= 0 and not d_2.is_empty() else -2
		linhas.append({"nivel": n + 1, "cena": cena.get_file(), "regime": "duplo" if duplo else "simples",
			"plataformas": plats.size(), "novas_p1": nov1, "novas_p2": nov2, "perdidas_p2": perdas2,
			"saltos_porta_legado": h_l, "saltos_porta_p1": h_1, "saltos_porta_p2": h_2})
		if perdas2 > 0:
			sinais.append("[%d] REGRESSAO p2: %d plataformas deixaram de ser alcancaveis" % [n + 1, perdas2])
		if h_l < 0 and h_2 >= 0:
			sinais.append("[%d] PORTA so alcancavel a saltar na p2 (legado: nao)" % [n + 1])
		if h_l >= 0 and h_2 < 0:
			sinais.append("[%d] REGRESSAO p2: PORTA deixou de ser alcancavel" % [n + 1])
		if h_l >= 6 and h_2 >= 0 and float(h_2) < float(h_l) * 0.5:
			sinais.append("[%d] ATALHO p2: saltos ate a porta %d -> %d" % [n + 1, h_l, h_2])
		raiz.queue_free()
		await process_frame
	var f := FileAccess.open(saida, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"niveis": linhas, "sinais": sinais}, "  "))
		f.close()
	var c1 := 0
	var c2 := 0
	var t1 := 0
	var t2 := 0
	var p1 := 0
	var p2 := 0
	for l in linhas:
		if int(l["novas_p1"]) > 0:
			c1 += 1
		if int(l["novas_p2"]) > 0:
			c2 += 1
		t1 += int(l["novas_p1"])
		t2 += int(l["novas_p2"])
		if int(l["saltos_porta_legado"]) < 0 and int(l["saltos_porta_p1"]) >= 0:
			p1 += 1
		if int(l["saltos_porta_legado"]) < 0 and int(l["saltos_porta_p2"]) >= 0:
			p2 += 1
	print("=== ACESSIBILIDADE F1 (%d niveis, referencia = legado pre-F1)" % linhas.size())
	print("    passagem 1: %d niveis com plataformas novas (%d), %d portas so a saltar" % [c1, t1, p1])
	print("    passagem 2: %d niveis com plataformas novas (%d), %d portas so a saltar" % [c2, t2, p2])
	for sn in sinais:
		print("  ", sn)
	quit(0)
