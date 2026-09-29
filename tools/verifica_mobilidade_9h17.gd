extends SceneTree
## CONTRATO DE MOBILIDADE (9H.17). O `verifica_alcance.gd` DESLIGA a jornada
## -- mede a sala feita a` mao. Este mede o nivel como ele e' jogado (jornada
## LIGADA) e com a envolvente do SALTO SIMPLES, medida na fisica do jogo em
## `tests/run_alcance_9h17.tscn`:
##
##   subida <=  0 px -> vao ate' 140 px     subida <= 72 px -> vao ate'  80 px
##   subida <= 64 px -> vao ate' 110 px     subida <= 80 px -> vao ate'  60 px
##   subida  >  80 px -> IMPOSSIVEL a qualquer vao
##
## Aplica-se uma margem: um nivel nao deve viver na ponta da envolvente.
##
##   Godot --headless --path . --script res://tools/verifica_mobilidade_9h17.gd -- <indice> [indice...]
##
## Crivo ESTATICO: nao modela plataformas moveis, trampolins nem impulsores,
## por isso um "sem caminho" aqui e' uma SUSPEITA a confirmar a jogar, e um
## "ha caminho" nao dispensa jogar. O que ele apanha a serio sao os degraus
## acima do tecto fisico -- esses nao ha' mobilidade que os salve.
const VA := preload("res://tools/verifica_alcance.gd")

## O grafo usa o limite MEDIDO puro: a pergunta dele e' "da' ou nao da'".
## A margem e' outra coisa -- um ALVO DE DESENHO. Um degrau que so' passa a
## raspar nao e' um bloqueio, e' um degrau mau, e vai para a lista dos
## APERTADOS em vez de reprovar o nivel. Confundir as duas coisas fazia o
## N1 reprovar por 2 px num salto que se faz.
const MARGEM := 1.0
const MARGEM_DESENHO := 0.85
## Tecto fisico absoluto do salto simples (medido: falha ja' aos 88).
const TECTO_SIMPLES := 80.0
const TECTO_DUPLO := 104.0
const QUEDA_MAX := 520.0
const MARGEM_PONTA := 26.0

static var tecto := TECTO_SIMPLES


## Vao maximo (px) para uma dada subida, com margem. `subida` > 0 = a subir.
static func vao_maximo(subida: float) -> float:
	if subida > tecto:
		return -1.0
	var bruto := 140.0
	if tecto <= TECTO_SIMPLES:
		# tabela medida do salto simples
		if subida > 72.0:
			bruto = 60.0
		elif subida > 64.0:
			bruto = 80.0
		elif subida > 0.0:
			bruto = 110.0
	else:
		# salto duplo: o crivo historico do projeto
		bruto = 210.0 if subida <= 0.0 else 195.0
	return bruto * MARGEM


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("uso: -- <indice> [indice...]")
		quit(2)
		return
	await process_frame
	var estado: Node = root.get_node_or_null("EstadoJogo")
	if estado == null:
		print("SEM EstadoJogo -- isto tem de correr com os autoloads")
		quit(2)
		return
	# "duplo" nos argumentos = medir com o tecto do salto duplo. E' o CONTROLO:
	# se o nivel tambem der "sem caminho" assim, o crivo esta' a mentir (nao
	# modela plataformas moveis) e nao serve de porteiro.
	var forcar_duplo := args.has("duplo")
	var mau := 0
	for a in args:
		if not a.is_valid_int():
			continue
		var idx := int(a)
		tecto = TECTO_DUPLO if (forcar_duplo or idx >= 5) else TECTO_SIMPLES
		var r: Dictionary = await _medir(idx, estado)
		if r.has("erro"):
			print("N%-3d ERRO %s" % [idx + 1, r["erro"]])
			mau += 1
			continue
		print("N%-3d %-30s plats=%3d tecto=%.0f porta=%s apertados=%d orfas=%d" % [
			idx + 1, String(estado.NIVEIS[idx]).get_file().get_basename().substr(0, 28),
			int(r.n), tecto, "OK" if bool(r.ok) else "SEM CAMINHO",
			int(r.apertados), int(r.orfas)])
		for linha: String in r.detalhe:
			print("      " + linha)
		if not bool(r.ok):
			mau += 1
	quit(1 if mau > 0 else 0)


func _medir(idx: int, estado: Node) -> Dictionary:
	var caminho: String = estado.NIVEIS[idx]
	var cena: PackedScene = load(caminho)
	if cena == null:
		return {"erro": "SEM CENA"}
	estado.indice_nivel = idx
	estado.checkpoint = Vector2.ZERO
	# o contrato e' sobre quem joga a serio: sem habilidades ganhas depois
	estado.habilidades.clear()
	estado.habilidades_suspensas.clear()
	var raiz := cena.instantiate()
	root.add_child(raiz)
	for _i in 3:
		await process_frame
	var plats: Array = []
	_recolher_tudo(raiz, plats)
	_ajudas.clear()
	_recolher_ajudas(raiz)
	var kol := get_first_node_in_group("koliani") as Node2D
	var porta := raiz.get_node_or_null("Porta") as Node2D
	if porta == null:
		for f in raiz.get_children():
			if f is Node2D and String(f.name).begins_with("Porta"):
				porta = f
	if plats.is_empty() or kol == null or porta == null:
		raiz.queue_free()
		await process_frame
		return {"erro": "plats=%d kol=%s porta=%s" % [plats.size(), kol != null, porta != null]}
	var r := _grafo(plats, kol, porta)
	raiz.queue_free()
	await process_frame
	return r


func _grafo(plats: Array, kol: Node2D, porta: Node2D) -> Dictionary:
	var n := plats.size()
	var i_spawn: int = VA._plat_mais_perto(plats, kol.global_position + Vector2(0, 20))
	var i_porta: int = VA._plat_mais_perto(plats, porta.global_position + Vector2(0, 20))
	if i_spawn < 0 or i_porta < 0:
		return {"erro": "spawn(%d) ou porta(%d) sem chao" % [i_spawn, i_porta]}
	var adj: Array = []
	for i in n:
		adj.append([])
	var impossiveis := 0
	var apertados := 0
	var detalhe: Array = []
	for i in n:
		for j in n:
			if i != j and _liga_com_ajudas(plats[i], plats[j]):
				adj[i].append(j)
				var sub: float = maxf(float(plats[i].topo) - float(plats[j].topo), 0.0)
				if _vao(plats[i], plats[j]) > vao_maximo(sub) * MARGEM_DESENHO:
					apertados += 1
	# degraus acima do tecto fisico: os que NUNCA se fazem
	for i in n:
		for j in n:
			if i == j:
				continue
			var subida: float = float(plats[i].topo) - float(plats[j].topo)
			if subida <= tecto or subida > 400.0:
				continue
			var vao := _vao(plats[i], plats[j])
			if vao > 60.0:
				continue
			impossiveis += 1
			if detalhe.size() < 6:
				detalhe.append("degrau IMPOSSIVEL %+.0f px (tecto %.0f) %s@x%.0f -> %s@x%.0f" % [
					subida, tecto, plats[i].nome, float(plats[i].cx),
					plats[j].nome, float(plats[j].cx)])
	var vis := {i_spawn: true}
	var fila := [i_spawn]
	while not fila.is_empty():
		var a: int = int(fila.pop_front())
		for b in adj[a]:
			if not vis.has(b):
				vis[b] = true
				fila.append(b)
	if not vis.has(i_porta):
		var melhor_x := -1.0e9
		var melhor := -1
		for i: int in vis.keys():
			if float(plats[i].cx) > melhor_x:
				melhor_x = float(plats[i].cx)
				melhor = i
		detalhe.append("PORTA INALCANCAVEL -- para em x=%.0f (%s, topo %.0f)" % [
			melhor_x, plats[melhor].nome, float(plats[melhor].topo)])
		# PORQUE e' que a frente para' ali: o degrau seguinte mais a` direita
		# de cada plataforma ja' alcancada, e por quantos px falha.
		var falhas: Array = []
		for i: int in vis.keys():
			var pa: Dictionary = plats[i]
			for j in n:
				var pb: Dictionary = plats[j]
				if vis.has(j) or float(pb.cx) <= float(pa.cx):
					continue
				var subida: float = float(pa.topo) - float(pb.topo)
				var vao := _vao(pa, pb)
				if vao > 260.0 or subida > 260.0:
					continue
				falhas.append({"x": float(pa.cx), "s": subida, "v": vao,
					"a": String(pa.nome), "b": String(pb.nome),
					"bx": float(pb.cx)})
		falhas.sort_custom(func(u: Dictionary, w: Dictionary) -> bool:
			return float(u.x) < float(w.x))
		var vistos := {}
		for f: Dictionary in falhas:
			var chave: String = String(f.a)
			if vistos.has(chave) or vistos.size() >= 8:
				continue
			vistos[chave] = true
			detalhe.append("  falha: %s@x%.0f -> %s@x%.0f  subida=%+.0f vao=%.0f (max %.0f)" % [
				f.a, float(f.x), f.b, float(f.bx), float(f.s), float(f.v),
				vao_maximo(maxf(float(f.s), 0.0))])
	return {"n": n, "ok": vis.has(i_porta), "impossiveis": impossiveis,
		"apertados": apertados, "orfas": n - vis.size(), "detalhe": detalhe}


## O `_recolher` do `verifica_alcance.gd` conhece 5 tipos de plataforma e
## NAO conhece a FLUTUANTE -- e a rota baixa do N2 e' feita de flutuantes.
## Sem elas o crivo dizia "sem caminho" numa rota que existe. Aqui apanham-se
## todas: qualquer script `plataforma*.gd`.
func _recolher_tudo(no: Node, out: Array) -> void:
	var e: Script = no.get_script()
	if e and e.resource_path.get_file().begins_with("plataforma"):
		var tv: Variant = no.get("tamanho")
		var tam: Vector2 = tv if tv != null else Vector2.ZERO
		if tam.x <= 1.0:
			# a flutuante define-se por `largura`/`altura`, nao por `tamanho`
			var lv: Variant = no.get("largura")
			tam = Vector2(float(lv) if lv != null else 120.0, 18.0)
		var p := no as Node2D
		if p != null:
			out.append({
				"nome": String(no.name), "cx": p.global_position.x,
				# uma plataforma que SE MEXE (ritmada, flutuante, de corrente)
				# vem ter connosco: o crivo estatico le-a parada e por isso
				# dava por impossivel um degrau que a mecanica dela resolve.
				"movel": e.resource_path.get_file() != "plataforma.gd",
				"topo": p.global_position.y - tam.y * 0.5,
				"esq": p.global_position.x - tam.x * 0.5,
				"dir": p.global_position.x + tam.x * 0.5,
				"base": p.global_position.y + tam.y * 0.5,
			})
	for f in no.get_children():
		_recolher_tudo(f, out)


func _liga_com_ajudas(a: Dictionary, b: Dictionary) -> bool:
	if _liga_est(a, b):
		return true
	var subida: float = float(a.topo) - float(b.topo)
	return subida > SUBIDA_TORRE and _vao(a, b) <= 210.0 and _tem_ajuda_entre(a, b)


static func _vao(a: Dictionary, b: Dictionary) -> float:
	if float(b.esq) > float(a.dir):
		return float(b.esq) - float(a.dir)
	if float(a.esq) > float(b.dir):
		return float(a.esq) - float(b.dir)
	return 0.0


## Trampolins, impulsores, elevadores e raizes elevatorias. Um degrau alto
## com um deles a` mao nao e' um bloqueio -- e' a mecanica dele a funcionar,
## e um crivo estatico nunca a sabera' simular. Sem isto o N3 aparecia
## trancado num poco que tem um trampolim no fundo.
var _ajudas: Array[Vector2] = []
const ALCANCE_AJUDA := 240.0
const SUBIDA_TORRE := 120.0

func _recolher_ajudas(no: Node) -> void:
	var e: Script = no.get_script()
	if e and e.resource_path.get_file() in ["trampolim.gd", "impulsor.gd",
			"tumulo_elevador.gd", "plataforma_corrente.gd", "raiz_elevatoria.gd"]:
		_ajudas.append((no as Node2D).global_position)
	for f in no.get_children():
		_recolher_ajudas(f)


func _tem_ajuda_entre(a: Dictionary, b: Dictionary) -> bool:
	var x0: float = minf(float(a.cx), float(b.cx)) - ALCANCE_AJUDA
	var x1: float = maxf(float(a.cx), float(b.cx)) + ALCANCE_AJUDA
	for pos in _ajudas:
		if pos.x >= x0 and pos.x <= x1 and pos.y <= float(a.base) + 80.0 				and pos.y >= float(b.topo) - 80.0:
			return true
	return false


static func _liga_est(a: Dictionary, b: Dictionary) -> bool:
	var subida: float = float(a.topo) - float(b.topo)   # >0 => b acima de a
	if subida < -QUEDA_MAX:
		return false
	if bool(b.get("movel", false)) and _vao(a, b) <= 210.0 and subida <= 150.0:
		return true
	var vmax := vao_maximo(maxf(subida, 0.0))
	if vmax < 0.0:
		return false
	if _vao(a, b) > vmax:
		return false
	# nao se sobe para cima de uma plataforma estando debaixo da barriga dela
	if subida > 0.0:
		var sobra_esq: float = float(b.esq) - float(a.esq)
		var sobra_dir: float = float(a.dir) - float(b.dir)
		if sobra_esq < MARGEM_PONTA and sobra_dir < MARGEM_PONTA:
			return false
	return true
