extends SceneTree
## Contrato dirigido do Prompt 5: identidade da Koliani sem alterar gameplay.
## Corrida com renderer real: godot --path . --script res://tools/verificar_sfx_koliani.gd

var _falhas := 0
var _som: Node


func _init() -> void:
	await process_frame
	_som = root.get_node_or_null("Som")
	_checar(_som != null, "autoload Som em falta")
	if _som == null:
		quit(1)
		return
	_som.call("definir_semente_teste", 20260921)
	var estado := root.get_node("EstadoJogo")
	estado.call("reiniciar_campanha")
	estado.habilidades.append_array(["dash", "salto_duplo", "escudo", "projetil"])
	estado.indice_nivel = 0
	change_scene_to_file("res://scenes/Main.tscn")
	for _i in 45:
		await physics_frame
	var k := get_first_node_in_group("koliani")
	_checar(k != null, "Koliani em falta")
	if k == null:
		quit(1)
		return
	_catalogo()
	_movimento(k)
	await _espada(k)
	_escudo(k)
	await _saltos(k)
	await _dano(k)
	print("SFX KOLIANI PROMPT 5 falhas=%d" % _falhas)
	quit(0 if _falhas == 0 else 1)


func _catalogo() -> void:
	var faltas: Array[String] = []
	var sfx_bus := AudioServer.get_bus_index("SFX")
	var opcoes: Node = root.get_node("Opcoes")
	_checar(sfx_bus >= 0 and is_equal_approx(AudioServer.get_bus_volume_db(sfx_bus),
		opcoes.SFX_MIX_DB + linear_to_db(clampf(opcoes.vol_efeitos, 0.001, 1.0))),
		"bus SFX nao aplica o headroom global aprovado")
	for chave in _som.CAMINHOS:
		if _som.call("_stream", chave) == null:
			faltas.append(chave)
	_checar(faltas.is_empty(), "streams ausentes: %s" % str(faltas))
	var novos := ["koliani_salto", "salto_duplo", "aterrar", "aterrar_medio",
		"aterrar_pesado", "dash", "rolamento", "parede", "agarrar",
		"passo1", "passo2", "passo3", "ataque", "ataque2", "ataque3",
		"ataque_forte", "acerto", "acerto_v2", "acerto_v3",
		"acerto_critico", "lancar", "pisao_koliani", "escudo_ativar",
		"escudo_impacto", "energia_impacto", "dano", "dano_pesado", "morte_koliani"]
	var caminhos: Array[String] = []
	for chave in novos:
		var caminho: String = _som.CAMINHOS[chave]
		_checar(caminho.begins_with("res://assets/audio/koliani_signature/")
			or (chave == "dash" and caminho == "res://assets/audio/approved/koliani_dash_wind_magic_5.wav"),
			"asset fora da familia: %s" % chave)
		if chave != "salto_duplo":
			_checar(not caminhos.has(caminho), "duas chaves partilham stream: %s" % chave)
		caminhos.append(caminho)
	_checar(_som.CAMINHOS["salto_duplo"] == _som.CAMINHOS["koliani_salto"],
		"double jump nao usa exactamente o stream do jump")
	_checar(_som.CAMINHOS["salto"] != _som.CAMINHOS["koliani_salto"],
		"salto dos inimigos foi alterado")
	_checar(_som.CAMINHOS["bloqueio"] != _som.CAMINHOS["escudo_impacto"],
		"bloqueio dos inimigos foi alterado")
	print("KOLIANI CATALOGO %d originais, missing=%d" % [novos.size(), faltas.size()])


func _saltos(k: Node) -> void:
	# Input verdadeiro: primeiro salto e duplo nao podem disparar duas vozes.
	k._ataque_restante = 0.0
	k._avanco_restante = 0.0
	k.velocity = Vector2.ZERO
	k._mov.velocidade = Vector2.ZERO
	print("KOLIANI SALTO inicio no_chao=%s saltos=%d" % [str(k.is_on_floor()), k._mov.saltos_dados])
	var antes := _contador()
	Input.action_press("saltar")
	await physics_frame
	await physics_frame
	Input.action_release("saltar")
	print("KOLIANI SALTO primeiro vozes=%d stream=%s saltos=%d" % [
		_contador() - antes, _ultimo_stream(), k._mov.saltos_dados])
	for i in _som.VOZES:
		if _som.get("_ordem_vozes")[i] > antes:
			print("  voz %d %s" % [i, (_som.get("_pool")[i] as AudioStreamPlayer).stream.resource_path.get_file()])
	_checar(_contar_stream_desde(antes, "koliani_jump.wav") == 1
		and _ultimo_stream() == "koliani_jump.wav",
		"jump nao disparou exactamente uma voz propria")
	for _i in 3:
		await physics_frame
	antes = _contador()
	Input.action_press("saltar")
	await physics_frame
	await physics_frame
	Input.action_release("saltar")
	print("KOLIANI SALTO segundo vozes=%d stream=%s saltos=%d" % [
		_contador() - antes, _ultimo_stream(), k._mov.saltos_dados])
	_checar(_contar_stream_desde(antes, "koliani_jump.wav") == 1
		and _ultimo_stream() == "koliani_jump.wav",
		"double jump nao reutilizou exactamente o stream do jump")
	print("KOLIANI SALTO jump=1 double=1 mesma_assinatura=true")


func _movimento(k: Node) -> void:
	var antes := _contador()
	k.call("_sfx_dash")
	_checar(_contador() - antes == 1 and _ultimo_stream() == "koliani_dash_wind_magic_5.wav",
		"dash sem identidade propria")
	for chave in ["aterrar", "aterrar_medio", "aterrar_pesado",
			"rolamento", "parede", "agarrar", "passo1", "passo2", "passo3"]:
		_checar(_som.call("_stream", chave) != null, "movimento sem stream: %s" % chave)
	_checar(_som.CAMINHOS["aterrar"] != _som.CAMINHOS["aterrar_medio"]
		and _som.CAMINHOS["aterrar_medio"] != _som.CAMINHOS["aterrar_pesado"],
		"tiers de aterragem ainda partilham o asset")
	print("KOLIANI MOVIMENTO dash=1 aterragem=3 roll/wall/grab/passos carregados")


func _espada(k: Node) -> void:
	var seq: Array[String] = []
	k._combo_passo = -1
	for _i in 4:
		k._combo_janela = 1.0
		k._ataque_restante = 0.0
		var antes := _contador()
		k.call("_iniciar_ataque")
		_checar(_contador() - antes == 1, "passo do combo disparou numero errado de vozes")
		seq.append(_ultimo_stream())
	_checar(seq == ["shadowblade_swing_1.wav", "shadowblade_swing_2.wav",
		"shadowblade_swing_3.wav", "shadowblade_finisher.wav"],
		"combo nao tem quatro vozes: %s" % str(seq))
	_checar(_som.CAMINHOS["acerto"] != _som.CAMINHOS["acerto_critico"],
		"critico ainda reutiliza impacto comum")
	_checar(_som.CAMINHOS["lancar"] != _som.CAMINHOS["ataque"],
		"energia de projetil reutiliza golpe")
	_checar(_som.CAMINHOS["energia_impacto"] != _som.CAMINHOS["acerto"],
		"impacto de energia reutiliza impacto de espada")
	var e = load("res://scenes/actors/DemonioBase.tscn").instantiate()
	e.especie = "goblin"
	current_scene.add_child(e)
	e.global_position = k.global_position + Vector2(35, 0)
	await process_frame
	e.vida = 10000
	k._alvos_atingidos_ataque.clear()
	k._pos_roll_t = 1.0
	var antes := _contador()
	k.call("_ao_acertar_corpo", e)
	_checar(_contador() > antes and _ultimo_stream() == "shadowblade_critical.wav",
		"critico real nao usa stream proprio")
	e.queue_free()
	var impactos: Array[String] = []
	_som.call("definir_semente_teste", 20260921)
	for _i in 6:
		_som.call("toca", "acerto", -8.0, 1.0, 0.0)
		impactos.append(_ultimo_stream())
	for i in range(1, impactos.size()):
		_checar(impactos[i] != impactos[i - 1], "impacto repetido sem variacao")
	print("KOLIANI SHADOWBLADE combo=4 impactos=3 anti-repeticao=6 critico=real")


func _escudo(k: Node) -> void:
	var antes := _contador()
	k.call("_sfx_ativar_escudo")
	_checar(_contador() - antes == 1 and _ultimo_stream() == "shadow_shield_on.wav",
		"escudo ativacao falhou")
	antes = _contador()
	k.call("_ao_bloquear")
	k.call("_ao_bloquear")
	_checar(_contador() - antes == 1 and _ultimo_stream() == "shadow_shield_hit.wav",
		"escudo impacto/cooldown falhou")
	print("KOLIANI ESCUDO ativacao!=impacto cooldown=preservado")


func _dano(k: Node) -> void:
	k._invulneravel = 0.0
	k._defendendo = false
	k.vida = 100
	var antes := _contador()
	k.call("receber_dano", 1)
	_checar(_contador() - antes == 1 and _ultimo_stream() == "koliani_hurt.wav",
		"hurt leve falhou")
	await create_timer(0.15).timeout
	k._invulneravel = 0.0
	var vida_max: int = int(k.call("_vida_max"))
	k.vida = vida_max * 2
	antes = _contador()
	# Usa a vida máxima atual para continuar pesado mesmo com armadura/bónus.
	k.call("receber_dano", vida_max)
	_checar(_contador() - antes == 1 and _ultimo_stream() == "koliani_hurt_heavy.wav",
		"hurt pesado falhou")
	k._invulneravel = 0.0
	k.vida = 1
	antes = _contador()
	k.call("receber_dano", 999)
	_checar(_contador() - antes == 1 and _ultimo_stream() == "koliani_death.wav",
		"fatal voltou a empilhar hurt + death")
	print("KOLIANI DANO leve=1 pesado=1 fatal=death sem hurt")


func _contador() -> int:
	return int(_som.get("_ordem"))


func _contar_stream_desde(ordem: int, nome: String) -> int:
	var total := 0
	for i in _som.VOZES:
		if _som.get("_ordem_vozes")[i] <= ordem:
			continue
		var p := (_som.get("_pool") as Array)[i] as AudioStreamPlayer
		if p.stream != null and p.stream.resource_path.get_file() == nome:
			total += 1
	return total


func _ultimo_stream() -> String:
	var i := posmod(int(_som.get("_idx")) - 1, int(_som.VOZES))
	var p := (_som.get("_pool") as Array)[i] as AudioStreamPlayer
	return p.stream.resource_path.get_file() if p and p.stream else ""


func _checar(ok: bool, mensagem: String) -> void:
	if not ok:
		_falhas += 1
		push_error("SFX KOLIANI: " + mensagem)
