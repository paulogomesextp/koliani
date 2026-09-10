extends Node
## Verificação dirigida da integração visual da Execution 5G.

const CENA_LEVEL_1 := preload("res://scenes/levels/Floresta_Putrefata.tscn")
const CENAS_REGIAO_I := [
	preload("res://scenes/levels/Floresta_Putrefata.tscn"),
	preload("res://scenes/levels/Pantano_dos_Sussurros.tscn"),
	preload("res://scenes/levels/Ninho_da_Viuva_Negra.tscn"),
	preload("res://scenes/levels/A_Arvore_que_Chora.tscn"),
	preload("res://scenes/levels/Coracao_da_Floresta.tscn"),
]

var falhas: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	var level_1 := CENA_LEVEL_1.instantiate()
	# O target 5C não é objeto desta prova; desligá-lo evita que os seus efeitos
	# e partículas contaminem o diagnóstico da personagem.
	var target_5c := level_1.get_node_or_null("Region1HybridVisualTarget")
	if target_5c:
		target_5c.set("ativo", false)
	get_tree().root.add_child(level_1)
	for _i in 90:
		await get_tree().process_frame
	var koliani := level_1.get_node_or_null("Koliani")
	_ok(koliani != null, "Level 1 sem Koliani")
	if koliani:
		_ok(koliani.get("usar_piloto_visual_5g"), "piloto 5G não ativo no Level 1")
		_ok(koliani.get("usar_prototipo_premium"), "fallback 5B deixou de estar ativo")
		var corpo := koliani.get_node("Sprite/Corpo") as AnimatedSprite2D
		var sf := corpo.sprite_frames
		var esperadas := {
			"idle": 10, "run": 12, "turn": 4, "run_start": 6,
			"jump_start": 4, "jump_loop": 4, "fall": 4,
			"run_brake": 4, "land": 2, "aterrar": 2,
		}
		for nome: String in esperadas:
			_ok(sf.has_animation(nome), "animação em falta: " + nome)
			if sf.has_animation(nome):
				_ok(sf.get_frame_count(nome) == esperadas[nome],
					"contagem errada em %s" % nome)
		_ok(sf.get_frame_texture("run_brake", 0) == sf.get_frame_texture("run", 9),
			"run_brake não reutiliza run_10")
		_ok(sf.get_frame_texture("run_brake", 3) == sf.get_frame_texture("idle", 0),
			"run_brake não termina em idle_01")
		_ok(sf.get_frame_texture("land", 0) == sf.get_frame_texture("fall", 3),
			"land não começa em fall_04")
		_ok(sf.get_frame_texture("land", 1) == sf.get_frame_texture("idle", 0),
			"land não termina em idle_01")
		_ok(corpo.scale.is_equal_approx(Vector2(0.82, 0.82)), "escala visual 5G.1 incorreta")
		var pes_y := (90.0 - 48.0 + corpo.offset.y) * corpo.scale.y
		_ok(is_equal_approx(pes_y, 22.0), "baseline visual fora de y=22")
		var corpo_col := koliani.get_node("CollisionShape2D") as CollisionShape2D
		var hit_col := koliani.get_node("HitboxAtaque/CollisionShape2D") as CollisionShape2D
		_ok(corpo_col.shape.size == Vector2(20, 44), "colisão corporal alterada")
		_ok(hit_col.shape.size == Vector2(30, 34) and hit_col.position == Vector2(23, -4),
			"hitbox de ataque alterada")
		_ok(koliani.is_on_floor(), "Koliani não assentou no chão para a prova de estados")
		if koliani.is_on_floor():
			koliani.set_physics_process(false)
			koliani.set_process(false)
			koliani.velocity.x = 100.0
			koliani.call("_atualizar_anim")
			_ok(corpo.animation == &"run_start", "arranque não escolheu run_start")
			corpo.stop()
			koliani.call("_atualizar_anim")
			_ok(corpo.animation == &"run", "fim de run_start não passou a run")
			koliani.set("_olha_para", -1.0)
			koliani.call("_atualizar_anim")
			_ok(corpo.animation == &"turn", "mudança de direção não escolheu turn")
			corpo.stop()
			koliani.call("_atualizar_anim")
			_ok(corpo.animation == &"run", "fim de turn não regressou a run")
			koliani.velocity.x = 0.0
			koliani.call("_atualizar_anim")
			_ok(corpo.animation == &"run_brake", "paragem não escolheu run_brake")
			corpo.stop()
			koliani.call("_atualizar_anim")
			_ok(corpo.animation == &"idle", "fim de run_brake não regressou a idle")
			koliani.set("_piloto_5g_no_ar", true)
			koliani.call("_atualizar_anim")
			_ok(corpo.animation == &"land", "regresso do ar não escolheu land")
			koliani.global_position.y -= 100.0
			koliani.velocity = Vector2(0.0, -1.0)
			koliani.move_and_slide()
			_ok(not koliani.is_on_floor(), "preparação aérea não libertou o chão")
			koliani.velocity = Vector2(0.0, -100.0)
			koliani.set("_piloto_5g_no_ar", false)
			koliani.set("_djump_t", 0.0)
			var escolha := koliani.call("_anim_locomocao_piloto_5g", sf) as String
			_ok(escolha == "jump_start", "subida escolheu %s (vy=%.1f)" % [escolha, koliani.call("_vy")])
			corpo.play(escolha)
			corpo.stop()
			escolha = koliani.call("_anim_locomocao_piloto_5g", sf) as String
			_ok(escolha == "jump_loop", "fim de jump_start não passou a jump_loop")
			koliani.velocity.y = 100.0
			escolha = koliani.call("_anim_locomocao_piloto_5g", sf) as String
			_ok(escolha == "fall", "queda não escolheu fall")
	level_1.queue_free()
	await get_tree().process_frame

	for indice in range(1, CENAS_REGIAO_I.size()):
		var nivel_regiao := (CENAS_REGIAO_I[indice] as PackedScene).instantiate()
		var koliani_regiao := nivel_regiao.get_node_or_null("Koliani")
		_ok(koliani_regiao != null, "Level %d sem Koliani" % (indice + 1))
		if koliani_regiao:
			_ok(bool(koliani_regiao.get("usar_piloto_visual_5g")),
				"piloto 5G não ativo no Level %d" % (indice + 1))
			_ok(bool(koliani_regiao.get("usar_prototipo_premium")),
				"fallback premium não ativo no Level %d" % (indice + 1))
		nivel_regiao.free()
	_terminar()


func _ok(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)


func _terminar() -> void:
	if falhas.is_empty():
		print("EXECUTION 5G/8 TARGETED: PASS -- piloto ativo em L1-L5")
		get_tree().quit(0)
	else:
		for falha in falhas:
			printerr("FALHOU: ", falha)
		get_tree().quit(1)
