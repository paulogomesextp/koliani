extends SceneTree
## Verificador ESTATICO de alcance para os niveis feitos a mao. Instancia a
## cena, apanha todas as plataformas solidas + o spawn da Koliani + a Porta,
## e faz um grafo de "da' para saltar de A para B" com regras generosas
## (salto duplo da Koliani). Diz se a Porta e' alcancavel do spawn e lista
## as plataformas orfas (ilhas a que nao se chega).
##   Godot --headless --script res://tools/verifica_alcance.gd -- <cena.tscn>
##
## Para os 100 de uma vez (e no CI): `tools/verifica_alcance_todos.gd`, que
## chama o `medir()` daqui.
##
## Regras (aproximadas, a favor da seguranca):
##   * vao horizontal entre bordas <= 210 px
##   * subida <= 118 px (salto + duplo); descer e' livre ate' 520 px
##   * NAO se sobe para cima de uma plataforma estando debaixo dela
##   * onde a cena tem `ZonaPlanar`/`WindZone` contínua: vãos de planar,
##     rajada a favor e corrente ascendente (ver `_da_para_saltar`)
## Nao modela plataformas moveis nem vento pulsado -- e' um crivo de "ilha morta".

const VAO_MAX := 210.0
const SUBIDA_MAX := 118.0
const QUEDA_MAX := 520.0
## Quanto e' que `a` tem de sobrar para fora da sombra de `b` para se
## poder saltar da ponta em vez de bater com a cabeca na barriga dela.
const MARGEM_PONTA := 26.0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("uso: -- <cena.tscn>")
		quit(2)
		return
	await process_frame
	var estado: Node = root.get_node_or_null("EstadoJogo")
	var indice := -1
	if estado:
		indice = int(estado.NIVEIS.find(args[0]))
		if indice < 0:
			print("(aviso: cena fora de EstadoJogo.NIVEIS -- a verificar como N1)")
	var r: Dictionary = await medir(self, args[0], indice)
	if r.has("erro"):
		print(r["erro"])
		quit(2)
		return
	print("cena=%s  plataformas=%d  spawn=#%d  porta=#%d  porta_alcancavel=%s" % [
		String(args[0]).get_file(), int(r.n), int(r.i_spawn), int(r.i_porta),
		str(bool(r.ok_porta))])
	var orfas: Array = r.orfas
	if not orfas.is_empty():
		print("  ORFAS (%d): %s" % [orfas.size(), ", ".join(orfas)])
	if not bool(r.ok_porta):
		print("  <<< " + String(r.porque))
	quit(0 if (bool(r.ok_porta) and orfas.is_empty()) else 1)


## Mede uma cena. Devolve `{n, i_spawn, i_porta, ok_porta, orfas, porque}`,
## ou `{erro}` se a sala nao der para medir.
##
## `indice` e' o numero do nivel (0-based) ou -1: o `_alongar_nivel` do
## `nivel_com_chefe.gd` estica a sala conforme o `EstadoJogo.indice_nivel`,
## e sem o pousar aqui herdava-se o do save da maquina -- media-se o N12
## como se fosse o N30.
static func medir(st: SceneTree, caminho: String, indice: int) -> Dictionary:
	var cena: PackedScene = load(caminho)
	if cena == null:
		return {"erro": "SEM CENA " + caminho}
	var estado: Node = st.root.get_node_or_null("EstadoJogo")
	if estado:
		estado.indice_nivel = maxi(indice, 0)
		estado.checkpoint = Vector2.ZERO
	var raiz := cena.instantiate()
	# esta ferramenta verifica a SALA FEITA À MÃO -- desliga a jornada
	# procedural, que traz plataformas móveis que o crivo estático não
	# modela (dariam órfãs falsas).
	var tinha_jornada := true
	if "corredor" in raiz:
		tinha_jornada = bool(raiz.corredor)
		raiz.corredor = false
	# ...mas o `alongar_plataformas` SO' corre quando o `corredor` e' falso,
	# e no jogo a jornada esta' ligada em todos os niveis menos o trono.
	# Desligar a jornada aqui LIGAVA o esticao, e o crivo passava a medir uma
	# sala que ninguem joga: o chao do chefe corria 140 px, deixava de estar
	# por cima do poleiro, e o bug do nivel 12 (e antes o do 10) desaparecia
	# na medicao. So' nos niveis que TÊM jornada, portanto -- no trono o
	# esticao corre mesmo em jogo, e desliga-lo media outra sala inexistente.
	if tinha_jornada and "alongar_plataformas" in raiz:
		raiz.alongar_plataformas = false
	st.root.add_child(raiz)
	for _i in 8:
		await st.process_frame

	var resultado := _medir_arvore(st, raiz)
	raiz.queue_free()
	await st.process_frame
	return resultado


static func _medir_arvore(st: SceneTree, raiz: Node) -> Dictionary:
	# --- apanha plataformas (AABB do topo) ---
	var plats: Array = []
	_recolher(raiz, plats)
	if plats.is_empty():
		return {"erro": "SEM PLATAFORMAS"}

	# --- spawn e porta ---
	var kol := st.get_first_node_in_group("koliani") as Node2D
	var porta := raiz.get_node_or_null("Porta") as Node2D
	if kol == null or porta == null:
		return {"erro": "falta Koliani (%s) ou Porta (%s)" % [kol != null, porta != null]}

	var i_spawn := _plat_mais_perto(plats, kol.global_position + Vector2(0, 20))
	var i_porta := _plat_mais_perto(plats, porta.global_position + Vector2(0, 20))
	if i_spawn < 0 or i_porta < 0:
		return {"erro": "spawn ou porta sem plataforma por baixo"}

	# --- ar: planar contextual e vento (Região II, Process 11) ---
	var ar := _recolher_ar(raiz)

	# --- grafo de alcance ---
	var n := plats.size()
	var adj: Array = []
	for i in n:
		adj.append([])
	for i in n:
		for j in n:
			if i == j:
				continue
			if _da_para_saltar(plats[i], plats[j], ar):
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
	var porque := ""
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
		porque = "PORTA INALCANCAVEL -- para nos ~x=%.0f (%s)" % [float(pm.cx), pm.nome]
	return {
		"n": n, "i_spawn": i_spawn, "i_porta": i_porta,
		"ok_porta": ok_porta, "orfas": orfas, "porque": porque,
	}


static func _recolher(no: Node, out: Array) -> void:
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
				"base": p.global_position.y + tam.y * 0.5,
			})
		_recolher(f, out)


static func _plat_mais_perto(plats: Array, pos: Vector2) -> int:
	var melhor := -1
	var melhor_d := 1.0e9
	for i in plats.size():
		var p: Dictionary = plats[i]
		var esq := float(p.esq)
		var dir := float(p.dir)
		var topo := float(p.topo)
		if pos.x < esq - 30.0 or pos.x > dir + 30.0:
			continue
		var d: float = absf(topo - pos.y)
		if topo >= pos.y - 40.0 and d < melhor_d:
			melhor_d = d
			melhor = i
	return melhor


## PLANAR e VENTO (Process 11, N08). Regras conservadoras medidas com a
## Koliani real (`tools/verifica_rota_n08.gd`) e só ativas onde a cena tem
## `ZonaPlanar` / `WindZone`; sem elas o crivo é exatamente o de antes.
##   * planar: para uma plataforma ao mesmo nível ou abaixo, o vão cresce com
##     a descida. Medido: planar + duplo cobre 356 px a 0 de descida e 480 px
##     a 100; aqui usa-se 300 + descida, com teto 700.
##   * rajada a favor CONTÍNUA sobre o vão (com planar): +metade do troço
##     coberto, escalado pela intensidade (medido: 640 px com 620 de rajada
##     2000 passam com folga).
##   * corrente ascendente CONTÍNUA mais forte do que a queda: de uma
##     plataforma encostada à coluna (vão <= VAO_MAX) e não acima do topo
##     dela, chega-se a outra encostada (vão <= VAO_CORRENTE) cujo topo não
##     fique mais de `SOBE_ALEM_CORRENTE` acima do topo da coluna.
## Pulsos não contam: uma rajada que pode estar desligada não é caminho.
const VAO_PLANAR := 300.0
const VAO_PLANAR_TETO := 700.0
const VAO_CORRENTE := 150.0
const SOBE_ALEM_CORRENTE := 60.0
const QUEDA_REF := 1400.0 * 1.22   # Movimento.GRAVIDADE * GRAVIDADE_QUEDA


static func _recolher_ar(raiz: Node) -> Dictionary:
	var planar: Array[Rect2] = []
	var favor: Array[Dictionary] = []
	var sobe: Array[Rect2] = []
	var pilha: Array[Node] = [raiz]
	while not pilha.is_empty():
		var no: Node = pilha.pop_back()
		pilha.append_array(no.get_children())
		if no.is_in_group("zonas_planar") and bool(no.get("ativa")):
			var tp: Vector2 = no.get("tamanho")
			planar.append(Rect2((no as Node2D).global_position - tp * 0.5, tp))
		elif no.is_in_group("zonas_vento") and bool(no.get("ativa")) and int(no.get("modo")) == 0:
			var tv: Vector2 = no.get("tamanho")
			var ret := Rect2((no as Node2D).global_position - tv * 0.5, tv)
			var d: Vector2 = (no.get("direcao") as Vector2).normalized()
			var inten := float(no.get("intensidade"))
			if d.y < -0.5 and inten > QUEDA_REF:
				sobe.append(ret)
			elif absf(d.x) > 0.5:
				favor.append({"ret": ret, "sentido": signf(d.x), "intensidade": inten})
	return {"planar": planar, "favor": favor, "sobe": sobe}


static func _em_zona(zonas: Array, p: Vector2) -> bool:
	for r: Rect2 in zonas:
		if r.has_point(p):
			return true
	return false


static func _vao_entre(e0: float, d0: float, e1: float, d1: float) -> float:
	if e1 > d0:
		return e1 - d0
	if e0 > d1:
		return e0 - d1
	return 0.0


static func _da_para_saltar(a: Dictionary, b: Dictionary, ar: Dictionary = {}) -> bool:
	if _da_para_saltar_a_pe(a, b):
		return true
	if ar.is_empty():
		return false
	var a_topo := float(a.topo)
	var b_topo := float(b.topo)
	# corrente ascendente
	for col: Rect2 in ar.get("sobe", []):
		if _vao_entre(float(a.esq), float(a.dir), col.position.x, col.end.x) > VAO_MAX:
			continue
		if a_topo < col.position.y or a_topo > col.end.y + SUBIDA_MAX:
			continue
		if _vao_entre(float(b.esq), float(b.dir), col.position.x, col.end.x) > VAO_CORRENTE:
			continue
		if b_topo < col.position.y - SOBE_ALEM_CORRENTE:
			continue
		return true
	# planar (só para o mesmo nível ou abaixo)
	var queda := b_topo - a_topo
	if queda < 0.0:
		return false
	var para_direita := float(b.esq) > float(a.dir)
	var borda_a := float(a.dir) if para_direita else float(a.esq)
	var borda_b := float(b.esq) if para_direita else float(b.dir)
	var zonas_planar: Array = ar.get("planar", [])
	if not _em_zona(zonas_planar, Vector2(borda_a, a_topo - 30.0)) \
			or not _em_zona(zonas_planar, Vector2(float(b.cx), b_topo - 30.0)):
		return false
	var vao := _vao_entre(float(a.esq), float(a.dir), float(b.esq), float(b.dir))
	var limite := minf(VAO_PLANAR + queda, VAO_PLANAR_TETO)
	var sentido := 1.0 if para_direita else -1.0
	var x0 := minf(borda_a, borda_b)
	var x1 := maxf(borda_a, borda_b)
	for f: Dictionary in ar.get("favor", []):
		var r: Rect2 = f["ret"]
		var banda := a_topo - 60.0
		if float(f["sentido"]) != sentido or banda < r.position.y or banda > r.end.y:
			continue
		var cobre := maxf(0.0, minf(x1, r.end.x) - maxf(x0, r.position.x))
		limite += cobre * 0.5 * clampf(float(f["intensidade"]) / 1600.0, 0.0, 1.0)
	return vao <= limite


static func _da_para_saltar_a_pe(a: Dictionary, b: Dictionary) -> bool:
	var a_esq := float(a.esq)
	var a_dir := float(a.dir)
	var a_topo := float(a.topo)
	var b_esq := float(b.esq)
	var b_dir := float(b.dir)
	var b_topo := float(b.topo)
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
	# DEBAIXO DA BARRIGA. Nao se sobe para cima de uma plataforma estando por
	# baixo dela: o corpo dela e' tecto, e ha' que dar a volta pela ponta.
	# Sem esta regra o crivo dizia "alcancavel" e o nivel 10 e o 12 chegaram
	# ao Paulo com o chefe inacessivel -- as duas vezes com a mesma forma: um
	# poleiro pequeno debaixo do chao da arena.
	#
	# So' se rejeita quando NAO ha' saida: se `a` sobra para fora da sombra
	# de `b` mais do que `MARGEM_PONTA`, salta-se de la' e a aresta vale.
	if dsub > 0.0:
		var sobra_esq := b_esq - a_esq
		var sobra_dir := a_dir - b_dir
		if sobra_esq < MARGEM_PONTA and sobra_dir < MARGEM_PONTA:
			return false
	if dsub < -QUEDA_MAX:
		return false
	return true
