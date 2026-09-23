extends SceneTree
## Prova dirigida do Prompt 2: player, familias inimigas, projeteis, cooldown,
## variacao deterministica e prioridade do pool. Corre com renderer real.

var _falhas := 0
var _som: Node
var _estado: Node


func _init() -> void:
	await process_frame
	_som = root.get_node("Som")
	_estado = root.get_node("EstadoJogo")
	_som.call("definir_semente_teste", 20260920)
	_estado.call("reiniciar_campanha")
	_estado.habilidades.append_array(["dash", "dash_aereo", "escudo", "projetil"])
	_estado.indice_nivel = 0
	change_scene_to_file("res://scenes/Main.tscn")
	for _i in 45:
		await physics_frame
	var k = get_first_node_in_group("koliani")
	_checar(k != null, "Koliani ausente")
	if k == null:
		quit(1)
		return
	await _player(k)
	await _inimigos()
	await _projeteis(k)
	await _boss_base()
	_pool_prioridade()
	print("SFX COMBATE FINAL falhas=%d" % _falhas)
	quit(0 if _falhas == 0 else 1)


func _player(k: Node) -> void:
	var sequencia: Array[String] = []
	var antes := _contador()
	k._combo_passo = -1
	for _i in 4:
		k._combo_janela = 1.0
		k.call("_iniciar_ataque")
		sequencia.append(_ultimo_stream())
	_checar(_contador() - antes == 4, "combo nao disparou quatro vozes")
	_checar(sequencia == ["shadowblade_swing_1.wav", "shadowblade_swing_2.wav",
		"shadowblade_swing_3.wav", "shadowblade_finisher.wav"],
		"sequencia do combo errada: %s" % str(sequencia))

	antes = _contador()
	k.call("_sfx_dash")
	_checar(_contador() - antes == 1
		and _ultimo_stream() == "koliani_dash_wind_magic_5.wav",
		"dash nao disparou uma vez")

	# Ativacao e impacto usam agora materiais proprios.
	antes = _contador()
	k.call("_sfx_ativar_escudo")
	_checar(_contador() - antes == 1 and _ultimo_stream() == "shadow_shield_on.wav",
		"ativacao do escudo nao disparou uma vez")
	var p_ativacao := _ultimo_player()
	_checar(is_equal_approx(p_ativacao.volume_db, -18.0) and p_ativacao.pitch_scale > 0.9,
		"perfil de ativacao do escudo incorreto")
	antes = _contador()
	k.call("_ao_bloquear")
	k.call("_ao_bloquear")
	_checar(_contador() - antes == 1, "cooldown do impacto de escudo falhou")
	var p_impacto := _ultimo_player()
	_checar(_ultimo_stream() == "shadow_shield_hit.wav"
		and is_equal_approx(p_impacto.volume_db, -11.0),
		"impacto do escudo nao se distingue da ativacao")

	k._invulneravel = 0.0
	k._defendendo = false
	k.vida = 50
	antes = _contador()
	k.call("receber_dano", 1)
	_checar(_contador() - antes == 1 and _ultimo_stream() == "koliani_hurt.wav",
		"hurt do player nao disparou uma vez")
	print("SFX PLAYER combo=%s dash=1 shield=ativacao+impacto hurt=1" % str(sequencia))


func _inimigos() -> void:
	var referencia := get_first_node_in_group("koliani") as Node2D
	var representantes := {
		"humano": "goblin", "morto": "esqueleto", "gosma": "gosma",
		"besta": "mastim", "insecto": "besouro", "voador": "abutre",
		"grande": "ogro",
	}
	var vistos: Array[String] = []
	for familia in representantes:
		var e = load("res://scenes/actors/DemonioBase.tscn").instantiate()
		e.especie = representantes[familia]
		if referencia != null:
			e.global_position = referencia.global_position
		current_scene.add_child(e)
		e.set_physics_process(false)
		await process_frame
		e.call("_voz", "ataque")
		vistos.append(_ultimo_stream())
		e.queue_free()
		await process_frame
	for familia in representantes:
		_checar(vistos.has("mob_%s_ataque.ogg" % familia),
			"familia sem voz distinta: %s (%s)" % [familia, str(vistos)])

	var e = load("res://scenes/actors/DemonioBase.tscn").instantiate()
	e.especie = "goblin"
	if referencia != null:
		e.global_position = referencia.global_position
	current_scene.add_child(e)
	e.set_physics_process(false)
	await process_frame
	e.call("_voz", "dano")
	var pitch_a := _ultimo_player().pitch_scale
	# Margem sobre o cooldown de 140 ms para não depender do agendamento da frame.
	await create_timer(0.20).timeout
	e.call("_voz", "dano")
	var pitch_b := _ultimo_player().pitch_scale
	_checar(not is_equal_approx(pitch_a, pitch_b), "anti-repeticao A/B nao mudou pitch")
	var antes := _contador()
	e.call("_voz", "dano")
	_checar(_contador() - antes == 0, "cooldown da voz hurt inimiga falhou")
	e.vida = 1
	antes = _contador()
	e.call("receber_dano", 1)
	_checar(_contador() - antes == 1 and _ultimo_stream() == "mob_humano_morte.ogg",
		"fatal inimigo voltou a empilhar hurt+morte")
	print("SFX INIMIGOS familias=%s hurt_pitch=%.3f>%.3f fatal=1" % [str(vistos), pitch_a, pitch_b])


func _projeteis(k: Node) -> void:
	var antes := _contador()
	k.call("_lancar_projetil")
	_checar(_contador() - antes == 1 and _ultimo_stream() == "shadowblade_energy_cast.wav",
		"projetil de energia do player sem categoria lancar")

	var e = load("res://scenes/actors/DemonioBase.tscn").instantiate()
	e.especie = "gosma"
	e.comportamento = "cuspidor"
	e.global_position = (k as Node2D).global_position
	current_scene.add_child(e)
	await process_frame
	e._windup = 0.001
	e._dive_dir = Vector2.RIGHT
	antes = _contador()
	e.call("_physics_process", 0.01)
	_checar(_contador() - antes == 1 and _ultimo_stream() == "praga.ogg",
		"projetil organico ainda usa projetil generico")
	print("SFX PROJETEIS energia=lancar.ogg organico=praga.ogg")


func _boss_base() -> void:
	var chefe = current_scene.find_child("Guardiao", true, false)
	_checar(chefe != null, "boss base ausente no L1")
	if chefe == null:
		return
	chefe._sfx_dano_cd = 0.0
	var antes := _contador()
	chefe.call("receber_dano", 1)
	chefe.call("receber_dano", 1)
	_checar(_contador() - antes == 1 and _ultimo_stream() == "mob_grande_dano.ogg",
		"boss hurt base/cooldown falhou")
	print("SFX BOSS BASE hurt=mob_grande_dano.ogg cooldown=0.22s")


func _pool_prioridade() -> void:
	for p in _som.get("_pool"):
		(p as AudioStreamPlayer).stop()
	for _i in int(_som.VOZES):
		_som.call("toca", "morte_koliani", -6.0, 1.0, 0.0, 0.0, "",
			int(_som.Prioridade.ALTA))
	var antes := _contador()
	var tocou: bool = _som.call("toca", "passo1", -24.0, 1.0, 0.0)
	_checar(not tocou and _contador() == antes,
		"evento normal cortou voz de prioridade alta")
	print("SFX POOL vozes=%d high_protegida=true" % int(_som.VOZES))


func _contador() -> int:
	return int(_som.get("_ordem"))


func _ultimo_player() -> AudioStreamPlayer:
	var i := posmod(int(_som.get("_idx")) - 1, int(_som.VOZES))
	return (_som.get("_pool") as Array)[i] as AudioStreamPlayer


func _ultimo_stream() -> String:
	var p := _ultimo_player()
	return p.stream.resource_path.get_file() if p and p.stream else ""


func _checar(ok: bool, mensagem: String) -> void:
	if not ok:
		_falhas += 1
		push_error("SFX COMBATE: " + mensagem)
