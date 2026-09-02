extends SceneTree
## Verifica que a JORNADA de aproximacao (`gerador_corredor.gd`) se constroi
## em TODOS os niveis da campanha sem erros e deixa o chefe/Porta no fim:
##  - o no' `CorredorAproximacao` existe (menos no ultimo nivel);
##  - a Koliani foi reposicionada BEM a' esquerda da Porta e do Chefe;
##  - foram criados varios checkpoints (grupo implicito -- contamos os nos
##    `JornadaCheck_*`).
## Uso: Godot --headless --script res://tools/verifica_jornada.gd

func _init() -> void:
	await process_frame
	var es := root.get_node_or_null("/root/EstadoJogo")
	var falhas := 0
	for idx in es.NIVEIS.size():
		es.indice_nivel = idx
		es.checkpoint = Vector2.ZERO
		es._limpar_jornada_ancora()
		var caminho: String = es.NIVEIS[idx]
		var cena: PackedScene = load(caminho)
		if cena == null:
			print("  [%2d] SEM CENA %s" % [idx, caminho]); falhas += 1; continue
		var raiz := cena.instantiate()
		root.add_child(raiz)
		# deixa correr o _construir diferido + fisica a assentar
		for _i in 12:
			await process_frame
		falhas += _checa(idx, raiz)
		raiz.queue_free()
		await process_frame
	print("\n=== JORNADA: %s ===" % ("TUDO OK" if falhas == 0 else "%d FALHA(S)" % falhas))
	quit(1 if falhas else 0)


func _checa(idx: int, raiz: Node) -> int:
	var es := root.get_node("/root/EstadoJogo")
	var ultimo: bool = idx == es.NIVEIS.size() - 1
	# níveis feitos à mão (`corredor = false`) não prependem a jornada
	var mao: bool = raiz.get("corredor") == false
	var ger := raiz.get_node_or_null("CorredorAproximacao")
	if ger == null:
		if ultimo or mao:
			var etq := "ultimo" if ultimo else "sala a mao"
			print("  [%2d] %-26s (%s -- sem jornada, ok)" % [idx, raiz.name, etq])
			return 0
		print("  [%2d] %-26s SEM CorredorAproximacao" % [idx, raiz.name])
		return 1

	var kol := get_first_node_in_group("koliani") as Node2D
	if kol == null:
		print("  [%2d] %-26s SEM Koliani" % [idx, raiz.name]); return 1

	var alvo_x := INF
	for nome in ["Porta", "Chefe"]:
		var n := raiz.get_node_or_null(nome)
		if n is Node2D:
			alvo_x = minf(alvo_x, (n as Node2D).global_position.x)

	var checks := 0
	for c in ger.get_children():
		if c is Node and str(c.name).begins_with("JornadaCheck_"):
			checks += 1

	var kx := kol.global_position.x
	var mau := []
	if alvo_x != INF and kx > alvo_x - 3000.0:
		mau.append("Koliani a x=%.0f, perto de mais do alvo x=%.0f" % [kx, alvo_x])
	# checkpoints: desde a v0.9.16 (`DIST_CHECKPOINT` 4000 px na jornada +
	# `_reduzir_checkpoints` a manter so' ~20%, sempre o do inicio e um perto
	# do chefe) os `JornadaCheck_*` que sobram como filhos do gerador sao
	# MESMO poucos de proposito -- 1 nos niveis curtos, 2-3 no N30 (o de
	# perto do chefe fica muitas vezes com a Porta/sala, fora deste no'). O
	# invariante que ainda importa: a jornada nao pode ficar SEM nenhum.
	var dist_j := (alvo_x - kx) if alvo_x != INF else 0.0
	var min_checks: int = maxi(1, int(dist_j / 14000.0))
	if checks < min_checks:
		mau.append("so' %d checkpoints (esperava >= %d p/ %.0fpx)" % [checks, min_checks, dist_j])
	var linha := "  [%2d] %-26s  koliani_x=%.0f  alvo_x=%.0f  jornada=%.0fpx  checks=%d" % [
		idx, raiz.name, kx, alvo_x, dist_j, checks]
	if mau.is_empty():
		print(linha + "  OK")
		return 0
	print(linha + "  <<< " + ", ".join(mau))
	return 1
