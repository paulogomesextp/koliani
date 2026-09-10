extends SceneTree
## Evidência real da Região I para revisão humana. Captura o runtime através
## de Main/HUD e não altera cenas nem teleporta entre passos usados como prova
## de jogabilidade: estas imagens são apenas evidência visual representativa.

const SAIDA := "res://work/execution_7/review/shots"
const DUR_COMBO := [0.18, 0.2, 0.3]
const VISTAS := [
	[0, 1450.0, "level1_enemy"],
	[1, 1560.0, "level2_development"],
	[2, 2020.0, "level3_combination"],
	[3, 2400.0, "level4_challenge"],
	[4, 2660.0, "level5_preboss_dash"],
]
var _falhou := false


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	await process_frame
	var estado := root.get_node_or_null("/root/EstadoJogo")
	if estado == null:
		printerr("EXECUTION 7 SHOT: EstadoJogo indisponível")
		quit(1)
		return
	estado.modo_teste = true
	estado.reiniciar_campanha()
	estado.modo_dev = false
	for vista in VISTAS:
		await _carregar_nivel(int(vista[0]))
		var koliani := get_first_node_in_group("koliani") as CharacterBody2D
		if koliani == null:
			printerr("EXECUTION 7 SHOT: Koliani ausente em L", int(vista[0]) + 1)
			_falhou = true
			return
		_preparar_koliani(koliani, float(vista[1]))
		await _guardar(str(vista[2]))

	await _capturar_combate()
	if _falhou:
		quit(1)
		return
	await _capturar_boss()
	if _falhou:
		quit(1)
		return
	print("EXECUTION 7 REAL RENDER: PASS -- L1-L5, combate, boss fase 2 e reward")
	quit(0)


func _carregar_nivel(indice: int) -> void:
	var estado := root.get_node("/root/EstadoJogo")
	estado.indice_nivel = indice
	estado.checkpoint = Vector2.ZERO
	estado._limpar_jornada_ancora()
	change_scene_to_file("res://scenes/Main.tscn")
	for _i in 100:
		await process_frame
	await create_timer(0.25).timeout


func _preparar_koliani(koliani: CharacterBody2D, x: float) -> void:
	var cam := koliani.get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.position_smoothing_enabled = false
	koliani.global_position = _ponto_seguro(koliani, x)
	koliani.velocity = Vector2.ZERO
	koliani.set_physics_process(false)


func _capturar_combate() -> void:
	await _carregar_nivel(0)
	var koliani := get_first_node_in_group("koliani") as CharacterBody2D
	var inimigo := current_scene.find_child("EliteGoblin", true, false) as Node2D
	if koliani == null or inimigo == null:
		printerr("EXECUTION 7 SHOT: encontro de combate indisponível")
		_falhou = true
		return
	_preparar_koliani(koliani, inimigo.global_position.x - 58.0)
	inimigo.set_physics_process(false)
	for passo in 3:
		koliani.set("_combo_passo", passo)
		koliani.set("_ataque_dur", DUR_COMBO[passo])
		koliani.set("_ataque_restante", DUR_COMBO[passo] * 0.5)
		koliani.call("_atualizar_anim")
		await process_frame
		await _guardar("combat_combo_%d" % (passo + 1))
	var y_chao := koliani.global_position.y
	koliani.global_position.y -= 88.0
	koliani.set("_combo_passo", 0)
	koliani.set("_ataque_no_ar", true)
	koliani.set("_ataque_restante", DUR_COMBO[0] * 0.5)
	koliani.call("_atualizar_anim")
	await process_frame
	await _guardar("combat_aerial")
	koliani.global_position.y = y_chao
	koliani.set("_ataque_restante", 0.0)
	koliani.set("_dash_restante", 0.08)
	koliani.call("_atualizar_anim")
	await process_frame
	await _guardar("combat_dash")


func _capturar_boss() -> void:
	await _carregar_nivel(4)
	var koliani := get_first_node_in_group("koliani") as CharacterBody2D
	var boss := get_first_node_in_group("chefes") as Node2D
	if koliani == null or boss == null:
		printerr("EXECUTION 7 SHOT: boss regional indisponível")
		_falhou = true
		return
	_preparar_koliani(koliani, boss.global_position.x - 190.0)
	boss.set_physics_process(false)
	if boss.has_method("provocar"):
		boss.call("provocar")
	if boss.has_method("_mostrar_nucleo"):
		boss.call("_mostrar_nucleo", true)
	await _guardar("boss_phase1")
	var vmax := int(boss.get("_vida_max"))
	boss.set("vida", int(vmax * 0.5))
	if boss.has_method("_atualiza_fase"):
		boss.call("_atualiza_fase")
	if boss.has_method("_bater"):
		boss.call("_bater")
	await create_timer(0.08).timeout
	await _guardar("boss_phase2")
	if boss.has_method("receber_dano"):
		boss.call("receber_dano", 999999, 1.0, false)
	await create_timer(0.9).timeout
	var porta := current_scene.find_child("Porta", true, false) as Node2D
	if porta:
		_preparar_koliani(koliani, porta.global_position.x - 110.0)
	await _guardar("boss_reward")


func _ponto_seguro(koliani: CharacterBody2D, x: float) -> Vector2:
	var query := PhysicsRayQueryParameters2D.create(Vector2(x, 100.0), Vector2(x, 900.0), 1)
	query.exclude = [koliani.get_rid()]
	var hit := koliani.get_world_2d().direct_space_state.intersect_ray(query)
	return Vector2(x, 620.0) if hit.is_empty() else Vector2(x, float(hit.position.y) - 24.0)


func _guardar(nome: String) -> void:
	for _i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var imagem := root.get_texture().get_image()
	var caminho := "%s/%s.png" % [SAIDA, nome]
	if imagem.save_png(ProjectSettings.globalize_path(caminho)) != OK:
		printerr("EXECUTION 7 SHOT: falha a guardar ", caminho)
		_falhou = true
		return
	print("shot -> ", caminho)
