extends SceneTree
## Verifica, nos 100 niveis, que a Koliani nao nasce nem chega ENTALADA.
##
## Duas medicoes, cada nivel montado com o SEU indice real -- a jornada e'
## semeada com `hash("jornada4|idx")`, portanto carregar a cena com o indice
## 0 gera outro nivel e a medicao nao vale nada:
##
##   1. SPAWN -- o corpo dela (20x44) no ponto de partida da jornada: dentro
##      do cenario, ou com parede dos dois lados.
##   2. CHEGADA DE PORTAL -- o ponto para onde cada portal de entrada a manda.
##      Mede-se o destino CRU (o que o `portal.gd` calcularia sem defesa) e o
##      que o `_lugar_livre` devolve. O relatorio do Paulo -- "quando apanhamos
##      o primeiro portal, onde nascemos e' entre 2 plataformas e a Koliani
##      fica presa" (4 set 2026) -- eram 7 chegadas cruas em 36 a cair dentro
##      da geometria. Este script existe para isso nao voltar.
##
##   godot --headless --script res://tools/verifica_portais.gd
##
## Sai != 0 se sobrar alguma posicao entalada DEPOIS da correccao.

## Quanto e' que a chegada sobe acima do portal parceiro (igual ao
## `Portal.SUBIDA` -- se mudar la', muda aqui).
const SUBIDA := 20.0


func _bate(k: CharacterBody2D, pos: Vector2) -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = (k.get_node("CollisionShape2D") as CollisionShape2D).shape
	q.transform = Transform2D(0.0, pos)
	q.collision_mask = 1
	q.collide_with_areas = false
	q.exclude = [k.get_rid()]
	return not k.get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()


func _init() -> void:
	await process_frame
	# em `--script` os autoloads nao existem como identificador
	var EJ := root.get_node("EstadoJogo")
	var spawns_maus := 0
	var crus_maus := 0
	var sobra := 0
	var portais := 0

	for idx in EJ.NIVEIS.size():
		EJ.indice_nivel = idx
		EJ.checkpoint = Vector2.ZERO
		var linha: Variant = EJ.NIVEIS[idx]
		var cena: String = linha[0] if linha is Array else linha
		await process_frame
		change_scene_to_file(cena)
		for _i in 12:
			await process_frame
		var k := get_first_node_in_group("koliani") as CharacterBody2D
		if k == null:
			print("SEM KOLIANI  n%d  %s" % [idx + 1, cena])
			continue

		var p := k.global_position
		if _bate(k, p) or (_bate(k, p + Vector2(-26.0, 0.0)) and _bate(k, p + Vector2(26.0, 0.0))):
			spawns_maus += 1
			sobra += 1
			print("SPAWN PRESO  n%-3d %-28s %s" % [idx + 1, cena.get_file(), p])

		for pt in get_nodes_in_group("portais"):
			if pt.so_saida:
				continue
			var alvo = pt._parceiro()
			if alvo == null:
				print("PORTAL SEM PAR  n%-3d %s" % [idx + 1, pt.id])
				continue
			portais += 1
			var cru: Vector2 = alvo.global_position + Vector2(0.0, -SUBIDA)
			if not _bate(k, cru):
				continue
			crus_maus += 1
			var livre: Vector2 = pt._lugar_livre(k, cru)
			var ok := not _bate(k, livre)
			if not ok:
				sobra += 1
			print("%s  n%-3d %-26s %-11s cru=%s -> %s" % [
				"chegada salva  " if ok else "CHEGADA PRESA  ",
				idx + 1, cena.get_file(), pt.id, cru, livre])

	print("\n%d/%d chegadas de portal cairiam dentro do cenario; %d spawns presos." % [
		crus_maus, portais, spawns_maus])
	if sobra > 0:
		print("FALHOU -- %d posicoes ainda entaladas depois da correccao." % sobra)
		quit(1)
	print("OK -- nenhuma posicao entalada depois da correccao.")
	quit(0)
