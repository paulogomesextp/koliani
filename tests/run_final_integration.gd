extends SceneTree
## Integração técnica: personagem e nível reais, sem substituir recursos em memória.
const OUT := "C:/Projetos/koliani/work/run_final_integration/"
var actor: CharacterBody2D
var corpo: AnimatedSprite2D
var dados: Array = []
var falhas: Array[String] = []
var fase := ""

func _initialize() -> void:
	call_deferred("_executar")

func _ok(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)

func _passos(n: int, nome: String) -> void:
	fase = nome
	for i in n:
		await physics_frame
		await process_frame
		dados.append({"fase": fase, "x": actor.position.x, "y": actor.position.y,
			"vx": actor.velocity.x, "vy": actor.velocity.y, "chao": actor.is_on_floor(),
			"anim": str(corpo.animation), "frame": corpo.frame, "facing": actor.get("_olha_para"),
			"scale": str(corpo.scale), "offset": str(corpo.offset)})
		if nome == "plataforma_run" and i == n - 1 and DisplayServer.get_name() != "headless":
			root.get_texture().get_image().save_png(OUT + "run_in_level.png")

func _anims(nome: String) -> Array:
	var resultado: Array = []
	for v in dados:
		if v.fase == nome and not v.anim in resultado:
			resultado.append(v.anim)
	return resultado

func _executar() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var baseline := "--baseline" in OS.get_cmdline_user_args()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.get_node("EstadoJogo").set("modo_teste", true)
	root.get_node("EstadoJogo").set("modo_dev", true)
	var nivel: Node2D = load("res://scenes/levels/Floresta_Putrefata.tscn").instantiate()
	root.add_child(nivel)
	current_scene = nivel
	await process_frame
	actor = nivel.get_node("Koliani")
	corpo = actor.get_node("Sprite/Corpo")
	actor.position = Vector2(150, 500)
	actor.reset_physics_interpolation()
	await _passos(60, "idle")
	var sf := corpo.sprite_frames
	var recursos := {}
	for anim in sf.get_animation_names():
		var paths: Array = []
		for i in sf.get_frame_count(anim):
			paths.append(sf.get_frame_texture(anim, i).resource_path)
		recursos[anim] = {"paths": paths, "fps": sf.get_animation_speed(anim), "loop": sf.get_animation_loop(anim)}
	_ok(sf.get_frame_count("run") == 10, "RUN deve ter dez frames")
	_ok(is_equal_approx(sf.get_animation_speed("run"), 13.333333), "FPS da RUN alterado")
	_ok(sf.get_animation_loop("run"), "RUN sem loop")
	_ok(corpo.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Filtro não é Nearest")
	if not baseline:
		for i in 10:
			var p := "res://assets/sprites/koliani_golden_set/frames/run_final/run_%03d.png" % (i + 1)
			_ok(sf.get_frame_texture("run", i).resource_path == p, "Ordem ou referência incorreta: " + p)
			_ok(sf.get_frame_texture("run", i).get_size() == Vector2(128, 128), "Dimensão RUN incorreta")
	Input.action_press("mover_direita", 0.3)
	await _passos(170, "arranque_corrida")
	Input.action_release("mover_direita")
	await _passos(60, "paragem")
	Input.action_press("mover_direita", 0.3)
	await _passos(60, "retoma")
	Input.action_release("mover_direita")
	Input.action_press("mover_esquerda", 0.3)
	await _passos(100, "inversao")
	Input.action_release("mover_esquerda")
	Input.action_press("mover_direita", 0.3)
	await _passos(60, "antes_salto")
	Input.action_press("saltar")
	await _passos(8, "salto")
	Input.action_release("saltar")
	await _passos(140, "queda_aterragem_corrida")
	Input.action_release("mover_direita")
	await _passos(40, "paragem_final")
	actor.position = Vector2(2000, 240)
	actor.velocity = Vector2.ZERO
	actor.reset_physics_interpolation()
	await _passos(60, "plataforma_idle")
	Input.action_press("mover_direita", 0.15)
	await _passos(120, "plataforma_run")
	Input.action_release("mover_direita")
	await _passos(40, "plataforma_paragem")
	_ok("idle" in _anims("idle"), "IDLE inicial não observado")
	_ok("run_start" in _anims("arranque_corrida") and "run" in _anims("arranque_corrida"), "IDLE→RUN não observado")
	_ok("idle" in _anims("paragem"), "RUN→IDLE não observado")
	var inverteu := false
	for v in dados:
		if v.fase == "inversao" and v.anim == "run" and v.vx < 0 and v.facing == -1:
			inverteu = true
	_ok(inverteu, "Inversão não observada")
	_ok("jump_start" in _anims("salto"), "RUN→JUMP não observado")
	_ok("fall" in _anims("queda_aterragem_corrida") and "land" in _anims("queda_aterragem_corrida") and "run" in _anims("queda_aterragem_corrida"), "FALL→LAND→RUN não observado")
	var frames: Array = []
	for v in dados:
		_ok(v.scale == "(1.0, 1.0)" and v.offset == "(0.0, -18.0)", "Escala ou offset alterado")
		if v.anim == "run" and not v.frame in frames:
			frames.append(v.frame)
	_ok(frames.size() == 10, "Dez frames não observados em deslocamento")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + ("baseline" if baseline else "integrated") + ".png")
	var resultado := {"dados": dados, "recursos": recursos, "falhas": falhas,
		"collision": str(actor.get_node("CollisionShape2D").shape.size),
		"mask": actor.collision_mask, "layer": actor.collision_layer}
	if not baseline and FileAccess.file_exists(OUT + "baseline.json"):
		var anterior: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT + "baseline.json"))
		for anim in recursos:
			if anim != "run":
				_ok(recursos[anim] == anterior.recursos[anim], "Outra animação alterada: " + anim)
		for chave in ["collision", "mask", "layer"]:
			_ok(resultado[chave] == anterior[chave], "Colisão alterada: " + chave)
		_ok(dados.size() == anterior.dados.size(), "Quantidade de amostras diferente")
		for i in mini(dados.size(), anterior.dados.size()):
			for chave in ["x", "y", "vx", "vy"]:
				_ok(absf(float(dados[i][chave]) - float(anterior.dados[i][chave])) < 0.001, "Trajetória diferente: %d/%s" % [i, chave])
			for chave in ["anim", "frame", "chao", "facing", "scale", "offset"]:
				_ok(dados[i][chave] == anterior.dados[i][chave], "Transição ou contrato diferente: %d/%s" % [i, chave])
	FileAccess.open(OUT + ("baseline" if baseline else "integrated") + ".json", FileAccess.WRITE).store_string(JSON.stringify(resultado, "\t"))
	print("RUN_FINAL_RESULT ", JSON.stringify({"baseline": baseline, "falhas": falhas, "frames": frames}))
	nivel.queue_free()
	current_scene = null
	for i in 5:
		await process_frame
	quit(0 if falhas.is_empty() else 1)
