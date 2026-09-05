extends SceneTree
## A Koliani consegue nascer num checkpoint MAU sem ficar entalada?
##
## O softlock que o Paulo apanhou no nível 5 (5 set 2026): reaparecer no
## checkpoint punha-a entre o chão e uma plataforma logo por cima, e dali
## não saía -- nem morrendo, porque voltava exactamente ao mesmo sítio.
##
## ⚠ A primeira versão desta bancada media a coisa errada: punha o
## checkpoint DENTRO de uma plataforma e exigia que ela não ficasse
## sobreposta. Passava sempre, mesmo com as duas redes desligadas -- as
## plataformas da jornada são finas e ela cai através delas. Sobrepor não é
## o problema.
##
## O que prende é um BOLSO: chão por baixo, tecto por cima e paredes dos
## dois lados. Aqui percorrem-se TODOS os checkpoints de cada nível e, de
## cada um, mede-se quanto é que ela consegue andar para os lados e quanta
## altura tem por cima. Preso = não anda para lado nenhum e não tem pé
## direito para saltar.
##
## Uso: Godot --headless --script res://tools/verifica_spawn_livre.gd

## O mesmo salto que o `koliani.gd` dá ao nascer num checkpoint.
const ALTURA_SPAWN := 40.0
## Andar menos do que isto para AMBOS os lados é estar num bolso...
const SAIDA_MINIMA := 64.0
## ... a não ser que tenha céu por cima para saltar dele.
const PE_DIREITO_MINIMO := 96.0

var _falhas := 0


func _init() -> void:
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	if es == null:
		print("SEM EstadoJogo"); quit(1); return
	# ⚠ `falhas += await _num_nivel(...)` NAO devolve o `return` da corrotina
	# -- soma `true`, portanto dava 5 FALHAS com 5 OKs impressos. O contador
	# e' um campo, e quem conta e' quem mede.
	for idx in [0, 4, 12, 20, 40, 55, 67, 80]:
		await _num_nivel(es, idx)

	print("
=== SPAWN: %s ===" % ("TUDO OK" if _falhas == 0 else "%d FALHA(S)" % _falhas))
	quit(1 if _falhas else 0)


func _num_nivel(es: Node, idx: int) -> void:
	es.indice_nivel = idx
	es.checkpoint = Vector2.ZERO
	if es.has_method("_limpar_jornada_ancora"):
		es._limpar_jornada_ancora()
	var raiz := (load(es.NIVEIS[idx]) as PackedScene).instantiate()
	root.add_child(raiz)
	for _i in 14:
		await process_frame
	var k := get_first_node_in_group("koliani") as CharacterBody2D
	if k == null:
		print("  [%2d] SEM Koliani" % idx)
		_falhas += 1
		raiz.queue_free(); await process_frame
		return

	var checks: Array[Node2D] = []
	_colher_checks(raiz, checks)
	var presos: Array[String] = []
	var pior := 99999.0
	for ck in checks:
		# onde ela nasceria: o mesmo que o `koliani.gd` faz
		var pos: Vector2 = ck.global_position + Vector2(0.0, -ALTURA_SPAWN)
		var esq := _quanto_anda(k, pos, -1.0)
		var dir := _quanto_anda(k, pos, 1.0)
		var teto := _pe_direito(k, pos)
		var saida: float = maxf(esq, dir)
		pior = minf(pior, saida)
		if saida < SAIDA_MINIMA and teto < PE_DIREITO_MINIMO:
			presos.append("x=%.0f (anda %.0f px, tecto a %.0f)" % [
				ck.global_position.x, saida, teto])
	print("  [%2d] %-26s %3d checkpoints, pior saida %.0f px  %s" % [
		idx, raiz.name, checks.size(), pior,
		"OK" if presos.is_empty() else "<<< PRESO EM " + ", ".join(presos)])
	if not presos.is_empty():
		_falhas += 1
	raiz.queue_free()
	await process_frame


## Quanto é que ela anda para um lado a partir de `pos`, em píxeis, até
## bater em geometria. Passo de 8 px e tecto de 200: mais do que isso já
## não é um bolso.
func _quanto_anda(k: CharacterBody2D, pos: Vector2, lado: float) -> float:
	var t := k.global_transform
	var d := 0.0
	while d < 200.0:
		t.origin = pos + Vector2(lado * (d + 8.0), 0.0)
		if k.test_move(t, Vector2.ZERO):
			return d
		d += 8.0
	return d


## Céu por cima do ponto: até onde ela pode subir antes de bater.
func _pe_direito(k: CharacterBody2D, pos: Vector2) -> float:
	var t := k.global_transform
	var d := 0.0
	while d < 160.0:
		t.origin = pos + Vector2(0.0, -(d + 8.0))
		if k.test_move(t, Vector2.ZERO):
			return d
		d += 8.0
	return d


func _colher_checks(n: Node, fora: Array[Node2D]) -> void:
	if n is Node2D and String(n.name).begins_with("JornadaCheck_"):
		fora.append(n as Node2D)
	for f in n.get_children():
		_colher_checks(f, fora)


## Uma plataforma da jornada, a meio dela -- e devolve o CENTRO do corpo,
## que é o sítio mais fundo possível.
func _uma_plataforma(n: Node) -> Vector2:
	var todas: Array[Node2D] = []
	_colher(n, todas)
	if todas.is_empty():
		return Vector2.INF
	return todas[todas.size() / 2].global_position


func _colher(n: Node, fora: Array[Node2D]) -> void:
	if n is StaticBody2D and n.get_parent() != null \
			and String(n.get_parent().name).begins_with("Corredor"):
		fora.append(n as Node2D)
	for f in n.get_children():
		_colher(f, fora)
