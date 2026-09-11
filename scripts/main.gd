extends Node2D
## Cena de jogo (`scenes/Main.tscn`). A `main_scene` do projeto é o
## `MenuInicial.tscn`, que carrega esta a seguir a "Continuar"/"Novo jogo"
## (ou logo, com `-- --jogar`). Carrega o nível atual da campanha e cola-lhe
## o HUD por cima. Trocar de nível = mudar `EstadoJogo.indice_nivel` e
## voltar a esta cena (é o que a Porta faz).

const CENA_HUD := preload("res://scenes/ui/HUD.tscn")
const CENA_PAUSA := preload("res://scenes/ui/Pausa.tscn")
const CENA_DEV_BARRA := preload("res://scenes/ui/DevBarra.tscn")
const FIM_CAMPANHA := preload("res://scripts/fim_campanha.gd")


func _ready() -> void:
	# Retoma a sessão v4 do mesmo nível ou inicia uma nova no spawn seguro.
	# A cena resolverá o checkpoint ID para uma posição runtime válida.
	EstadoJogo.iniciar_sessao_nivel()
	# rede de seguranca das `ZonaSemPoder` (nivel 98): elas devolvem a
	# habilidade a' saida e no `_exit_tree`, mas se alguma coisa correr mal
	# a meio, o nivel seguinte comeca limpo na mesma.
	EstadoJogo.devolver_habilidades_todas()
	Engine.time_scale = 1.0  # rede de segurança: nunca começar um nível "congelado"
	get_tree().paused = false
	Musica.ambiente(EstadoJogo.indice_nivel)
	var caminho := EstadoJogo.caminho_nivel_atual()
	var cena_nivel: PackedScene = load(caminho)
	if cena_nivel == null:
		push_error("Nível não encontrado: %s" % caminho)
		return
	var nivel := cena_nivel.instantiate()
	add_child(nivel)
	var boss_id := "boss_level_005" if EstadoJogo.indice_nivel == 4 else "none"
	print("RUNTIME TRACE | build=%s | main_scene=res://scenes/Main.tscn | level_id=level_%03d | level_scene=%s | player_scene=res://scenes/actors/Koliani.tscn | boss_id=%s" % [
		str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		EstadoJogo.indice_nivel + 1, caminho, boss_id])
	_validar_recovery_session.call_deferred(nivel)

	var porta := _procurar_porta(nivel)
	if porta:
		porta.fim_da_campanha.connect(_ao_fim_da_campanha)

	add_child(CENA_HUD.instantiate())
	# O Diário de pistas foi retirado do jogo a pedido do Paulo (ago 2026).
	# `scenes/ui/Diario.tscn` / `scripts/diario*.gd` ficam no repo, dormentes.
	add_child(CENA_PAUSA.instantiate())
	if EstadoJogo.modo_dev and OS.is_debug_build():
		add_child(CENA_DEV_BARRA.instantiate())

	# acabou de passar de nível (a Porta chamou `avancar_nivel`)
	if EstadoJogo.anunciar_avanco:
		EstadoJogo.anunciar_avanco = false
		_anunciar_avanco()

	# `godot --path . -- --foto[=ficheiro]`: tira uma captura e sai (dev).
	var estado_foto := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--foto-estado="):
			estado_foto = a.get_slice("=", 1)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--foto"):
			if a.begins_with("--foto-estado="):
				continue
			var alvo := a.get_slice("=", 1) if "=" in a else "user://foto.png"
			_tirar_foto(alvo, estado_foto)
			break


func _procurar_porta(no: Node) -> Porta:
	if no is Porta:
		return no
	for filho in no.get_children():
		var r := _procurar_porta(filho)
		if r:
			return r
	return null


func _validar_recovery_session(nivel: Node) -> void:
	# Checkpoints esperam pela redução existente antes de fixar IDs. Depois
	# disso, confirma inclusive o caso de um ID sintaticamente válido mas já
	# inexistente; a campanha permanece intacta e a sessão volta ao `_start`.
	for _i in 8:
		await get_tree().process_frame
	if not is_instance_valid(nivel) or not nivel.is_inside_tree():
		return
	var ids: Array[String] = []
	for no in get_tree().get_nodes_in_group("checkpoints"):
		if no is Node2D and nivel.is_ancestor_of(no) \
				and not no.is_queued_for_deletion():
			var checkpoint_id := str(no.get("checkpoint_id"))
			if checkpoint_id != "" and checkpoint_id not in ids:
				ids.append(checkpoint_id)
	EstadoJogo.validar_checkpoints_disponiveis(ids)


## Atalhos de depuração -- só em builds de debug (editor / export-debug).
## F1..F4: salta para o mundo 1..4. F5: dá todas as habilidades.
## F6: +3 vidas. F9: apaga o save e recomeça.
func _unhandled_input(evento: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if not (evento is InputEventKey and evento.pressed and not evento.echo):
		return
	# usa o physical_keycode (posição da tecla) -- mais fiável que keycode
	match evento.physical_keycode:
		KEY_F1, KEY_F2, KEY_F3, KEY_F4:
			var i: int = int(evento.physical_keycode) - KEY_F1
			if i < EstadoJogo.NIVEIS.size():
				EstadoJogo.indice_nivel = i
				EstadoJogo.iniciar_sessao_nivel(true)
				_toast_debug("mundo %d" % (i + 1))
				await get_tree().create_timer(0.35).timeout
				get_tree().change_scene_to_file("res://scenes/Main.tscn")
		KEY_F5:
			for h in EstadoJogo.HABILIDADES_TODAS:
				EstadoJogo.desbloquear_habilidade(h)
			_toast_debug("habilidades todas")
		KEY_F6:
			EstadoJogo.vidas += 3
			EstadoJogo.vidas_mudaram.emit(EstadoJogo.vidas)
			_toast_debug("+3 vidas  (%d)" % EstadoJogo.vidas)
		KEY_F9:
			EstadoJogo.reiniciar_campanha()
			_toast_debug("save apagado -- recomecar")
			await get_tree().create_timer(0.35).timeout
			get_tree().change_scene_to_file("res://scenes/Main.tscn")


## Banner grande "Avançou para o Nível N" ao entrar num nível novo por ter
## atravessado a Porta. Aparece, aguenta ~1.6 s e esvai-se.
func _anunciar_avanco() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 40
	camada.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(camada)

	var l := Label.new()
	l.text = Textos.tf("hud.advanced", [EstadoJogo.indice_nivel + 1])
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 60)
	l.add_theme_color_override("font_color", Color(1, 0.93, 1))
	l.add_theme_color_override("font_outline_color", Color(0.24, 0.03, 0.3))
	l.add_theme_constant_override("outline_size", 12)
	l.modulate.a = 0.0
	l.scale = Vector2(0.92, 0.92)
	l.pivot_offset = Vector2(640, 360)
	camada.add_child(l)

	var t := create_tween()
	t.tween_property(l, "modulate:a", 1.0, 0.3)
	t.parallel().tween_property(l, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(1.5)
	t.tween_property(l, "modulate:a", 0.0, 0.6)
	t.tween_callback(camada.queue_free)


func _toast_debug(txt: String) -> void:
	print("DEBUG: ", txt)
	var camada := CanvasLayer.new()
	camada.layer = 26
	camada.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(camada)
	var l := Label.new()
	l.text = "  " + txt + "  "
	l.position = Vector2(20, 92)
	l.add_theme_color_override("font_color", Color(0.1, 0.05, 0.12))
	l.add_theme_font_size_override("font_size", 18)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(1, 0.82, 0.4, 0.92)
	estilo.set_corner_radius_all(4)
	estilo.content_margin_top = 3
	estilo.content_margin_bottom = 3
	l.add_theme_stylebox_override("normal", estilo)
	camada.add_child(l)
	var t := create_tween()
	t.tween_interval(1.6)
	t.tween_property(l, "modulate:a", 0.0, 0.5)
	t.tween_callback(camada.queue_free)


func _tirar_foto(caminho: String, estado := "") -> void:
	await get_tree().create_timer(0.55).timeout
	var koliani := get_tree().get_first_node_in_group("koliani") as Node2D
	if estado == "combate" and koliani:
		Input.action_press("atacar")
		await get_tree().create_timer(0.12).timeout
		Input.action_release("atacar")
		await get_tree().create_timer(0.08).timeout
	elif estado == "boss" and koliani:
		var boss := get_tree().get_first_node_in_group("chefes") as Node2D
		if boss:
			koliani.global_position = boss.global_position + Vector2(-210.0, -42.0)
			koliani.set("velocity", Vector2.ZERO)
			await get_tree().create_timer(0.45).timeout
	elif estado == "golden" and koliani:
		await _prova_golden_set(caminho, koliani)
		get_tree().quit(0)
		return
	elif estado == "pacote" and koliani:
		await _prova_pacote_9b4(caminho, koliani)
		get_tree().quit(0)
		return
	else:
		await get_tree().create_timer(0.25).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(caminho)
	print("FOTO guardada: ", ProjectSettings.globalize_path(caminho))
	get_tree().quit(0)


## Execution 9B.3: prova do Golden Set no runtime real (export incluído). Conduz
## a Koliani pelos estados cobertos com o input normal e fotografa cada um; ao
## lado grava um JSON com a animação e o recurso do frame que estava MESMO a ser
## desenhado -- é isso que prova que o jogo usa o Golden Set, não o PNG.
func _prova_golden_set(caminho: String, koliani: Node2D) -> void:
	var base := caminho.get_basename()
	var registo: Array = []
	# rede de segurança: a prova nunca pendura o processo
	get_tree().create_timer(25.0, true, false, true).timeout.connect(func() -> void: get_tree().quit(3))
	var corpo_k := koliani as CharacterBody2D
	for _i in 120:  # nasce no ar: espera pelo chão antes de fotografar o idle
		await get_tree().physics_frame
		if corpo_k.is_on_floor():
			break
	await get_tree().create_timer(0.5).timeout
	await _foto_golden(base, "1_idle", koliani, registo)
	# ataque no chão de partida (antes de andar, para não depender do nível)
	Input.action_press("atacar")
	await get_tree().create_timer(0.05).timeout
	Input.action_release("atacar")
	await _foto_golden(base, "2_attack", koliani, registo)
	await get_tree().create_timer(0.05).timeout
	await _foto_golden(base, "3_attack_late", koliani, registo)
	await get_tree().create_timer(0.5).timeout
	Input.action_press("mover_direita")
	await get_tree().create_timer(0.3).timeout
	await _foto_golden(base, "4_run", koliani, registo)
	Input.action_release("mover_direita")
	await get_tree().create_timer(0.5).timeout
	# salto na vertical, no mesmo chão
	Input.action_press("saltar")
	await get_tree().create_timer(0.05).timeout
	await _foto_golden(base, "5_jump_start", koliani, registo)
	# jump_loop só aparece entre o fim do jump_start (4/12 s) e o início da
	# descida: espera que esteja MESMO a ser desenhado (máx. 1 s).
	var corpo_anim := koliani.get("_corpo") as AnimatedSprite2D
	for _i in 60:
		await get_tree().process_frame
		if corpo_anim and corpo_anim.animation == &"jump_loop":
			break
	await _foto_golden(base, "6_air", koliani, registo)
	Input.action_release("saltar")
	for _i in 120:  # espera pela descida (máx. 2 s)
		await get_tree().physics_frame
		if float(koliani.get("velocity").y) * float(koliani.get("_sinal_grav")) > 60.0:
			break
	await _foto_golden(base, "7_fall", koliani, registo)
	print("PROVA GOLDEN SET: ", ProjectSettings.globalize_path(base + "_registo.json"))


## Execution 9B.4: prova do pacote completo. As habilidades entram só em memória
## (nada é gravado). Dash, roll, defesa, agachar, salto duplo, dano e morte vão
## pelo input/código normal do jogo; parede e rebordo precisam de geometria que
## o início do L1 não tem, por isso são FORÇADOS (física parada, flags visuais)
## -- a etiqueta diz "forcado" e o registo guarda isso.
func _prova_pacote_9b4(caminho: String, koliani: Node2D) -> void:
	var base := caminho.get_basename()
	var registo: Array = []
	get_tree().create_timer(40.0, true, false, true).timeout.connect(func() -> void: get_tree().quit(3))
	for h in ["dash", "salto_duplo", "escudo"]:
		if not EstadoJogo.habilidades.has(h):
			EstadoJogo.habilidades.append(h)
	var ck := koliani as CharacterBody2D
	var corpo := koliani.get("_corpo") as AnimatedSprite2D
	for _i in 120:
		await get_tree().physics_frame
		if ck.is_on_floor():
			break
	await get_tree().create_timer(0.5).timeout
	await _foto_golden(base, "01_idle", koliani, registo)
	Input.action_press("mirar_baixo")
	await get_tree().create_timer(0.15).timeout
	await _foto_golden(base, "02_crouch", koliani, registo)
	Input.action_release("mirar_baixo")
	Input.action_press("defender")
	await get_tree().create_timer(0.15).timeout
	await _foto_golden(base, "03_defesa", koliani, registo)
	Input.action_release("defender")
	await get_tree().create_timer(0.3).timeout
	Input.action_press("rolar")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("rolar")
	await _foto_golden(base, "04_roll", koliani, registo)
	await get_tree().create_timer(0.07).timeout
	await _foto_golden(base, "05_roll_late", koliani, registo)
	await get_tree().create_timer(0.8).timeout
	Input.action_press("mover_direita")
	await get_tree().create_timer(0.35).timeout
	await _foto_golden(base, "06_run", koliani, registo)
	Input.action_press("dash")
	await get_tree().create_timer(0.07).timeout
	Input.action_release("dash")
	await _foto_golden(base, "07_dash", koliani, registo)
	Input.action_release("mover_direita")
	await get_tree().create_timer(0.6).timeout
	Input.action_press("saltar")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("saltar")
	await get_tree().create_timer(0.2).timeout
	Input.action_press("saltar")
	await get_tree().create_timer(0.08).timeout
	Input.action_release("saltar")
	await _foto_golden(base, "08_djump", koliani, registo)
	for _i in 180:
		await get_tree().physics_frame
		if ck.is_on_floor():
			break
	await get_tree().create_timer(0.4).timeout
	# forçados: parede e rebordo
	koliani.set_physics_process(false)
	koliani.set("_escalando", true)
	await get_tree().create_timer(0.1).timeout
	await _foto_golden(base, "09_wallslide_forcado", koliani, registo)
	koliani.set("_escalando", false)
	koliani.set("_borda", true)
	await get_tree().create_timer(0.1).timeout
	await _foto_golden(base, "10_borda_forcado", koliani, registo)
	koliani.set("_borda", false)
	koliani.set_physics_process(true)
	await get_tree().create_timer(0.3).timeout
	koliani.set("_invulneravel", 0.0)
	koliani.call("receber_dano", 1, -1.0)
	await get_tree().create_timer(0.06).timeout
	await _foto_golden(base, "11_hurt", koliani, registo)
	await get_tree().create_timer(0.5).timeout
	koliani.set("_invulneravel", 0.0)
	koliani.call("receber_dano", 999, -1.0)
	await get_tree().create_timer(0.1).timeout
	await _foto_golden(base, "12_morte", koliani, registo)
	print("PROVA PACOTE 9B.4: ", ProjectSettings.globalize_path(base + "_registo.json"))


func _foto_golden(base: String, etiqueta: String, koliani: Node2D, registo: Array) -> void:
	await RenderingServer.frame_post_draw
	var corpo := koliani.get("_corpo") as AnimatedSprite2D
	var vfx := koliani.get("_slash_vfx") as AnimatedSprite2D
	var anim := String(corpo.animation) if corpo else ""
	var tex: Texture2D = corpo.sprite_frames.get_frame_texture(anim, corpo.frame) if corpo and corpo.sprite_frames else null
	var caminho := "%s_%s.png" % [base, etiqueta]
	get_viewport().get_texture().get_image().save_png(caminho)
	var ecra := koliani.get_global_transform_with_canvas().origin
	registo.append({"etiqueta": etiqueta, "animacao": anim, "frame": corpo.frame if corpo else -1,
		"textura": tex.resource_path if tex else "", "escala": [corpo.scale.x, corpo.scale.y] if corpo else [],
		"offset": [corpo.offset.x, corpo.offset.y] if corpo else [],
		"vfx_visivel": vfx != null and vfx.visible,
		"vfx_frame": vfx.frame if vfx else -1,
		"no_chao": (koliani as CharacterBody2D).is_on_floor(),
		"ecra": [ecra.x, ecra.y], "foto": caminho})
	# grava a cada foto: se algo interromper a prova, o que já se provou fica
	var f := FileAccess.open(base + "_registo.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(registo, "  "))


func _ao_fim_da_campanha() -> void:
	print("FIM: Koliani liberta a mãe de Zeriko.")
	var fim := CanvasLayer.new()
	fim.set_script(FIM_CAMPANHA)
	add_child(fim)
