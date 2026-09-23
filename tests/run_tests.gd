extends Node
## Corredor de testes headless, sem dependencias externas (sem GUT).
##
##   godot --headless --path . res://tests/run_tests.tscn
##
## Sai com codigo 1 se algum teste falhar -- o CI (.github/workflows/ci.yml)
## usa isso para marcar o build como vermelho. Acrescenta testes novos como
## metodos `teste_*` e chama-os em `_correr_tudo`.
##
## A cena de teste e' carregada pelo projeto para disponibilizar os mesmos
## autoloads e recursos que existem no jogo. Os testes do estado continuam a
## instanciar estado_jogo.gd diretamente para nao ler nem gravar o save real.

const EstadoJogoScript := preload("res://scripts/estado_jogo.gd")
const SaveFoundation := preload("res://scripts/save_foundation.gd")
const ProgressionIDs := preload("res://scripts/progression_ids.gd")
const LevelSession := preload("res://scripts/level_session.gd")
const TestesMovimentoCamera4A := preload("res://tests/test_movimento_camera_4a.gd")
const TestesWindSystem := preload("res://tests/test_wind_system.gd")
const TestesRegion02WindLevels := preload("res://tests/test_region02_wind_levels.gd")
const TestesGlideRegiao02 := preload("res://tests/test_glide_region02.gd")
const TestesRegion02N08 := preload("res://tests/test_region02_n08_level.gd")
const TestesRegion02N10 := preload("res://tests/test_region02_n10_level.gd")
const TestesKolianiCanonicaNiveis := preload("res://tests/test_koliani_canonica_niveis.gd")
const DT := 1.0 / 60.0

var _falhas: Array[String] = []


func _ready() -> void:
	call_deferred("_correr_tudo")


func _correr_tudo() -> void:
	for falha in TestesMovimentoCamera4A.executar():
		_falhas.append(falha)
	for falha in TestesWindSystem.executar():
		_falhas.append(falha)
	for falha in TestesRegion02WindLevels.executar():
		_falhas.append(falha)
	for falha in TestesGlideRegiao02.executar():
		_falhas.append(falha)
	for falha in TestesRegion02N08.executar():
		_falhas.append(falha)
	for falha in TestesRegion02N10.executar():
		_falhas.append(falha)
	for falha in TestesKolianiCanonicaNiveis.executar():
		_falhas.append(falha)
	teste_movimento_salto_com_coyote()
	teste_movimento_corte_de_salto()
	teste_movimento_anda_para_a_direita()
	teste_movimento_salto_duplo()
	teste_movimento_sem_habilidade_nao_ha_salto_duplo()
	teste_movimento_sair_da_borda_perde_primeiro_salto()
	teste_koliani_pode_rolar()
	teste_koliani_bloqueio_de_frente()
	teste_koliani_direcao_mira()
	teste_tremor_impulso_e_decaimento()
	teste_diario_entradas_e_fallback()
	teste_diario_tem_todas_as_pistas_dos_niveis()
	teste_i18n_en_tem_as_chaves_das_pistas()
	teste_i18n_ficheiros_validos()
	teste_tutorial_mecanica_tem_texto()
	teste_controlos_tacteis_fixos()
	teste_head_pwa_em_dia()
	teste_9f_buses_de_audio_estaticos()
	teste_9f_ui_producao()
	teste_catalogo_campanha()
	teste_9h17_contrato_de_mobilidade_regiao1()
	await teste_gate1_hitstop_nao_gera_nan()
	await teste_dev_barra_salto_nao_abre_seletor()
	await teste_dev_mode_sem_pin()
	await teste_9h17_novo_jogo_desarma_ao_sair()
	teste_equipamento_dados()
	teste_equipamento_estado()
	teste_estado_tres_mortes_sem_vidas()
	teste_estado_vida_por_nivel()
	teste_estado_reiniciar_run()
	teste_estado_pistas_sem_duplicados()
	teste_estado_habilidade_sem_duplicados()
	teste_progression_ids_niveis_e_bosses()
	teste_progression_ids_habilidades_e_coletaveis()
	teste_progression_ids_idempotencia_boss_e_recompensa()
	teste_progression_ids_invalidos()
	teste_progression_ids_resilientes_a_renames()
	teste_execution_7_combate_e_progressao_regiao1()
	teste_execution_7_guardioes_e_boss_regional()
	teste_execution_8_integracao_player_facing()
	teste_execution_9b4_pacote_golden_sem_legado()
	teste_execution_9c_kit_ambiente_regiao1()
	await teste_execution_9h7_fundo_regiao1()
	teste_execution_9d_inimigos_regiao1()
	teste_9d9e_crias_sem_goblin()
	teste_9e2_coracao_producao_e_fases()
	teste_9g_vfx_producao_regiao1()
	teste_9h_frontend_producao()
	await teste_9h_inimigos_com_vida()
	await teste_9h_chefes_regiao1_mais_faceis()
	teste_level_session_begin()
	teste_level_session_stable_checkpoint_identity()
	teste_level_session_checkpoint_activation_repeated()
	teste_level_session_death_respawn_contract()
	teste_level_session_save_close_load()
	teste_level_session_invalid_checkpoint_fallback()
	teste_level_session_level_completion()
	teste_level_session_boss_persistence()
	teste_level_session_reward_idempotence()
	teste_save_v3_migration_level_session()
	teste_save_v4_migration_remove_hardcore()
	teste_estado_nivel_atual_e_caminho_valido()
	teste_estado_save_ida_e_volta()
	teste_save_fresh_write_load()
	teste_save_roundtrip_campos()
	teste_save_legacy_migration()
	teste_save_migration_sequencial()
	teste_save_v2_migration_progressao()
	teste_save_primary_corrupto_backup_valido()
	teste_save_escrita_nova_invalida_preserva_anterior()
	teste_save_temp_invalido_nao_promovido()
	teste_save_versao_futura_preservada()
	teste_save_migration_invalida_rejeitada()
	teste_save_nao_repete_leitura_do_manifesto()
	teste_manifesto_cache_nao_altera_identidades()
	teste_estado_ha_progresso()
	teste_estado_regioes_e_conclusao()
	teste_estado_mapa_desbloqueio()
	teste_estado_modo_dev()
	teste_rig_da_koliani_tem_as_tiras_todas()
	teste_especies_dos_inimigos_existem()
	teste_packs_de_fundo_existem()
	teste_rigs_dos_chefes()
	teste_camas_de_musica()
	teste_fogueira_do_chefe()
	teste_sfx_existem()
	teste_regioes_tem_nome_e_cor()
	teste_pecas_de_ui_existem()
	teste_mecanica_por_nivel()
	teste_desbloqueio_nao_segue_a_apresentacao()
	teste_paineis_nao_trazem_o_vizinho()
	teste_sala_labirinto_deterministica()
	teste_9h1_trilha_de_producao()
	teste_9h1_combo_com_poses_proprias()
	teste_9h1_criaturas_com_movimento()
	teste_9h1_tema_do_seletor()
	teste_9h1_repor_layout_apaga_mesmo()

	# --- Região III -- Torre dos Ecos (N11-N15) -----------------------
	teste_r3_nomes_canonicos()
	teste_r3_vyrak_sem_lore_de_dragao()
	teste_r3_um_so_chefe_na_regiao()
	teste_r3_fundo_proprio_da_torre()
	teste_r3_assinatura_e_de_sinos()
	teste_r3_bestiario_canonico()
	await teste_r3_niveis_carregam()
	await teste_r3_vyrak_identidade()
	await teste_r3_vyrak_leva_dano_muda_de_fase_e_morre()

	if _falhas.is_empty():
		print("OK -- todos os testes passaram")
		get_tree().quit(0)
	else:
		for f in _falhas:
			printerr("FALHOU: ", f)
		printerr("%d falha(s)" % _falhas.size())
		get_tree().quit(1)


## Execution 8.1E. Uma gravacao chegava a ler e a parsear
## `data/level_manifest.json` 1312 vezes -- 2481 ms presos na thread
## principal a cada checkpoint e a cada dano. Este teste e' a trava: se
## alguem voltar a tirar o cache, ou puser o manifesto num caminho quente
## sem cache, isto acende.
func teste_save_nao_repete_leitura_do_manifesto() -> void:
	var base := "res://work/teste_manifesto_cache.json"
	_limpar_save_teste(base)
	ProgressionIDs.aquecer()
	ProgressionIDs.zerar_diagnostico()
	var e := _novo_estado()
	e.essencia = 7
	_ok(e.guardar_em(base, base + ".bak", base + ".tmp"),
		"cache do manifesto: a gravacao devia continuar a funcionar")
	var diag := ProgressionIDs.diagnostico()
	_ok(int(diag.get("leituras_disco", -1)) == 0,
		"uma gravacao nao devia ler o manifesto do disco (leu %s vezes)" % [
			diag.get("leituras_disco")])
	_ok(int(diag.get("parses_json", -1)) == 0,
		"uma gravacao nao devia parsear o manifesto (parseou %s vezes)" % [
			diag.get("parses_json")])
	# E prova que a assercao morde: sem cache, isto dispara aos milhares.
	ProgressionIDs.usar_cache(false)
	ProgressionIDs.zerar_diagnostico()
	e.guardar_em(base, base + ".bak", base + ".tmp")
	var sem_cache := ProgressionIDs.diagnostico()
	_ok(int(sem_cache.get("leituras_disco", 0)) > 100,
		"controlo: sem cache a gravacao TEM de reler o manifesto muitas vezes")
	ProgressionIDs.usar_cache(true)
	ProgressionIDs.aquecer()
	e.free()
	_limpar_save_teste(base)


## O cache so' vale se devolver exatamente o mesmo que o disco devolvia.
func teste_manifesto_cache_nao_altera_identidades() -> void:
	ProgressionIDs.usar_cache(false)
	var sem_cache := ProgressionIDs.identidades().duplicate(true)
	var manifesto_sem := ProgressionIDs.carregar_manifesto().duplicate(true)
	ProgressionIDs.usar_cache(true)
	ProgressionIDs.aquecer()
	var com_cache := ProgressionIDs.identidades()
	_ok(sem_cache == com_cache,
		"o cache do manifesto nao pode mudar uma unica identidade persistida")
	_ok(manifesto_sem == ProgressionIDs.carregar_manifesto(),
		"o cache do manifesto nao pode mudar o manifesto lido")
	# invalidar_cache() tem de voltar a dar o mesmo (caminho das ferramentas)
	ProgressionIDs.invalidar_cache()
	_ok(sem_cache == ProgressionIDs.identidades(),
		"invalidar_cache() devia reconstruir identidades identicas")


func _ok(condicao: bool, mensagem: String) -> void:
	if not condicao:
		_falhas.append(mensagem)


func teste_sala_labirinto_deterministica() -> void:
	var a := SalaLabirinto.descricao_logica(1100.0, 420.0, 0.4, 1701)
	var b := SalaLabirinto.descricao_logica(1100.0, 420.0, 0.4, 1701)
	_ok(a == b, "SalaLabirinto: a mesma seed deve gerar a mesma descricao")
	var prova := SalaLabirinto.validar_descricao(a)
	_ok(prova.get("passou", false),
		"SalaLabirinto invalida: %s" % [prova.get("erros", [])])
	var rotas: Dictionary = prova.get("rotas", {})
	for ordem in ["A_B", "B_A"]:
		var rota: Array = rotas.get(ordem, [])
		_ok(rota.has("A") and rota.has("B") and rota[-1] == "saida",
			"SalaLabirinto: rota %s nao prova as duas alavancas e a saida" % ordem)
	var fonte_gerador := _fonte("res://scripts/gerador_corredor.gd")
	_ok(not fonte_gerador.contains("preload(\"res://scripts/sala_labirinto.gd\")")
			and not fonte_gerador.contains("SalaLabirinto.new()"),
		"SalaLabirinto deve continuar desativada no gerador ativo")


## Instancia estado_jogo.gd fora da arvore (nao chama _ready, logo nao le o
## save do disco), poe modo_teste (nao grava nada no disco) e reinicia a
## campanha para um ponto conhecido.
func _novo_estado() -> Node:
	var e: Node = EstadoJogoScript.new()
	e.modo_teste = true
	e.reiniciar_campanha()
	return e


# --- Level Session / Checkpoint State (Execution 3C) --------------------

func teste_level_session_begin() -> void:
	var e := _novo_estado()
	e.iniciar_sessao_nivel(true)
	_ok(e.level_session == {
		"active": true,
		"level_id": "level_001",
		"checkpoint_id": "checkpoint_level_001_start",
	}, "nível válido devia iniciar uma level session coerente")
	e.free()


func teste_level_session_stable_checkpoint_identity() -> void:
	_ok(LevelSession.id_checkpoint("level_005", 3) == "checkpoint_level_005_03",
		"checkpoint persistido devia usar level ID e identidade estável")
	_ok(LevelSession.id_valido_para_nivel(
		"checkpoint_level_005_03", "level_005"),
		"stable checkpoint ID devia validar no próprio nível")
	_ok(not LevelSession.id_valido_para_nivel(
		"checkpoint_level_005_03", "level_006"),
		"checkpoint ID não devia atravessar níveis")


func teste_level_session_checkpoint_activation_repeated() -> void:
	var e := _novo_estado()
	e.indice_nivel = 4
	e.iniciar_sessao_nivel(true)
	var id := "checkpoint_level_005_03"
	var pos := Vector2(2660.0, 442.0)
	_ok(e.ativar_checkpoint(id, pos), "ativação devia aceitar checkpoint estável")
	var uma_vez: Dictionary = e.level_session.duplicate(true)
	_ok(e.ativar_checkpoint(id, pos), "ativação repetida devia ser segura")
	_ok(e.level_session == uma_vez and e.ponto_recuperacao() == pos,
		"ativação repetida devia ser idempotente")
	e.free()


func teste_level_session_death_respawn_contract() -> void:
	var e := _novo_estado()
	e.indice_nivel = 4
	e.iniciar_sessao_nivel(true)
	var id := "checkpoint_level_005_02"
	var pos := Vector2(1700.0, 636.0)
	e.ativar_checkpoint(id, pos)
	# Reload reconstrói a cena: a coordenada runtime desaparece e o ID volta
	# a resolvê-la quando a fogueira segura fica disponível.
	e.checkpoint = Vector2.ZERO
	_ok(e.registar_checkpoint_disponivel(id, pos),
		"reload devia resolver o checkpoint esperado pelo stable ID")
	_ok(e.ponto_recuperacao() == pos, "death/respawn devia regressar ao checkpoint")
	e.free()


func teste_level_session_save_close_load() -> void:
	var base := "res://work/teste_level_session_close_load.json"
	_limpar_save_teste(base)
	var e := _novo_estado()
	e.indice_nivel = 4
	e.iniciar_sessao_nivel(true)
	e.ativar_checkpoint("checkpoint_level_005_04", Vector2(3000.0, 500.0))
	_ok(e.guardar_em(base, base + ".bak", base + ".tmp"),
		"sessão válida devia ser gravada")
	var copia := _novo_estado()
	_ok(copia.carregar_de(base, base + ".bak"), "sessão devia carregar após close")
	_ok(copia.checkpoint == Vector2.ZERO,
		"load não devia confiar numa coordenada arbitrária")
	_ok(copia.checkpoint_id_session() == "checkpoint_level_005_04",
		"close/reopen devia preservar o último safe checkpoint ID")
	e.free(); copia.free()
	_limpar_save_teste(base)


func teste_level_session_invalid_checkpoint_fallback() -> void:
	var e := _novo_estado()
	e.indice_nivel = 4
	e.marcar_nivel_concluido(0)
	e.ganhar_essencia(37)
	var d: Dictionary = e.para_dicionario()
	d["level_session"] = {
		"active": true, "level_id": "level_005", "checkpoint_id": "invalido"}
	var processado := SaveFoundation.processar(d, e.NIVEIS.size())
	_ok(processado.get("ok", false),
		"checkpoint inválido não devia inutilizar campaign save válido")
	var seguro: Dictionary = processado.get("data", {})
	_ok(seguro.get("level_session", {}).get("checkpoint_id", "") \
		== "checkpoint_level_005_start", "checkpoint inválido devia usar fallback seguro")
	_ok(seguro.get("completed_level_ids", []) == ["level_001"] \
		and seguro.get("essencia", 0) == 37,
		"fallback de sessão não devia perder campaign progress")
	e.free()


func teste_level_session_level_completion() -> void:
	var e := _novo_estado()
	e.iniciar_sessao_nivel(true)
	e.ativar_checkpoint("checkpoint_level_001_01", Vector2(500.0, 300.0))
	e.avancar_nivel()
	_ok(0 in e.concluidos, "level completion devia manter progresso permanente")
	_ok(not e.level_session.get("active", false),
		"level completion devia terminar a sessão temporária antiga")
	e.free()


func teste_level_session_boss_persistence() -> void:
	var e := _novo_estado()
	e.indice_nivel = 4
	e.iniciar_sessao_nivel(true)
	e.marcar_chefe_derrotado_por_nivel(4)
	e.abandonar_sessao_nivel()
	var copia := _novo_estado()
	copia.de_dicionario(e.para_dicionario())
	_ok("boss_level_005" in copia.bosses_derrotados,
		"boss derrotado devia sobreviver a death/reload/session reset")
	e.free(); copia.free()


func teste_level_session_reward_idempotence() -> void:
	var e := _novo_estado()
	e.indice_nivel = 4
	e.iniciar_sessao_nivel(true)
	var reward_id := "reward_boss_chest_level_005"
	_ok(e.marcar_recompensa_reclamada(reward_id), "primeiro claim devia passar")
	e.abandonar_sessao_nivel()
	e.iniciar_sessao_nivel(true)
	_ok(not e.marcar_recompensa_reclamada(reward_id),
		"session reset não devia permitir duplicar boss chest reward")
	e.free()


func teste_save_v3_migration_level_session() -> void:
	var e := _novo_estado()
	e.indice_nivel = 4
	e.marcar_nivel_concluido(0)
	var v3: Dictionary = e.para_dicionario()
	v3["save_version"] = 3
	v3["checkpoint"] = [1700.0, 636.0]
	v3["hardcore"] = false
	v3["hardcore_tempo_restante"] = -1.0
	v3.erase("level_session")
	var resultado := SaveFoundation.processar(v3, e.NIVEIS.size())
	_ok(resultado.get("migrations", []) == [3, 4, 5],
		"v3 devia migrar sequencialmente por v4 para v5")
	var d: Dictionary = resultado.get("data", {})
	_ok(d.get("level_session", {}).get("checkpoint_id", "") \
		== "checkpoint_level_005_start",
		"coordenada legacy ambígua devia convergir para início seguro")
	_ok(d.get("completed_level_ids", []) == ["level_001"],
		"migration v3 não devia perder progresso permanente")
	_ok(not d.has("checkpoint"), "schema atual não devia persistir coordenada legacy")
	e.free()


func teste_save_v4_migration_remove_hardcore() -> void:
	var e := _novo_estado()
	e.indice_nivel = 4
	e.marcar_nivel_concluido(0)
	var v4: Dictionary = e.para_dicionario()
	v4["save_version"] = 4
	v4["hardcore"] = true
	v4["hardcore_tempo_restante"] = 37.5
	var resultado := SaveFoundation.processar(v4, e.NIVEIS.size())
	_ok(resultado.get("migrations", []) == [4, 5],
		"v4 devia migrar sequencialmente para v5")
	var atual: Dictionary = resultado.get("data", {})
	_ok(not atual.has("hardcore") and not atual.has("hardcore_tempo_restante"),
		"Hardcore legacy não devia chegar ao schema atual")
	_ok(atual.get("current_level_id") == "level_005"
		and atual.get("completed_level_ids", []) == ["level_001"],
		"remover Hardcore não devia perder progresso permanente")
	_ok(SaveFoundation.validar_atual(atual, e.NIVEIS.size()).get("ok", false),
		"save migrado sem Hardcore devia validar no schema atual")
	var roundtrip: Dictionary = e.para_dicionario()
	_ok(not roundtrip.has("hardcore") and not roundtrip.has("hardcore_tempo_restante"),
		"save atual não devia serializar estado Hardcore")
	e.free()


# --- Movimento (logica pura) -------------------------------------------------

func teste_movimento_salto_com_coyote() -> void:
	var e := Movimento.Estado.new()
	Movimento.passo(e, 0.0, false, false, true, DT)      # 1 frame no chao arma o coyote
	Movimento.passo(e, 0.0, true, true, false, DT)       # ja no ar, salta dentro do coyote
	_ok(e.velocidade.y < 0.0, "salto com coyote devia dar velocidade vertical negativa")


func teste_movimento_corte_de_salto() -> void:
	var e := Movimento.Estado.new()
	e.velocidade.y = -400.0
	Movimento.passo(e, 0.0, false, false, false, DT)     # nao segura o botao de saltar
	_ok(e.velocidade.y > -400.0, "largar o botao devia encurtar o salto (corte de salto)")


func teste_movimento_anda_para_a_direita() -> void:
	var e := Movimento.Estado.new()
	for i in 20:
		Movimento.passo(e, 1.0, false, false, true, DT)
	_ok(e.velocidade.x > 0.0, "input para a direita devia acelerar em x")
	_ok(e.velocidade.x <= Movimento.VEL_CORRIDA + 0.001, "nao devia passar a velocidade de corrida")


## CHAO ESCORREGADIO (nivel 41): `acel_escala` mexe nas DUAS metades --
## custa a arrancar e custa a parar --, porque a travagem usa a mesma
## aceleracao da arrancada. E' toda a mecanica do gelo num so' numero.
func teste_movimento_gelo_custa_a_arrancar_e_a_parar() -> void:
	var normal := Movimento.Estado.new()
	var gelo := Movimento.Estado.new()
	for i in 6:
		Movimento.passo(normal, 1.0, false, false, true, DT)
		Movimento.passo(gelo, 1.0, false, false, true, DT, 1, 1.0, 0.25)
	_ok(gelo.velocidade.x < normal.velocidade.x,
		"no gelo devia custar mais a ganhar velocidade (%.0f vs %.0f)"
			% [gelo.velocidade.x, normal.velocidade.x])
	# agora a travagem: larga-se o comando com as duas a' mesma velocidade
	normal.velocidade.x = Movimento.VEL_CORRIDA
	gelo.velocidade.x = Movimento.VEL_CORRIDA
	for i in 6:
		Movimento.passo(normal, 0.0, false, false, true, DT)
		Movimento.passo(gelo, 0.0, false, false, true, DT, 1, 1.0, 0.25)
	_ok(gelo.velocidade.x > normal.velocidade.x,
		"no gelo devia custar mais a parar (%.0f vs %.0f)"
			% [gelo.velocidade.x, normal.velocidade.x])
	# e nunca chega a zero: a 0.25 ainda se muda de sentido, so' demora
	var volta := Movimento.Estado.new()
	volta.velocidade.x = Movimento.VEL_CORRIDA
	for i in 120:
		Movimento.passo(volta, -1.0, false, false, true, DT, 1, 1.0, 0.25)
	_ok(volta.velocidade.x < 0.0,
		"mesmo no gelo tem de dar para inverter o sentido (vx = %.0f)"
			% volta.velocidade.x)


## PLANAR (nivel 63): a cair, com o botao a segurar, a queda prende-se a
## VEL_PLANAR. Nao e' voar -- ela continua a descer, so' que devagar.
func teste_movimento_planar_prende_a_queda() -> void:
	var livre := Movimento.Estado.new()
	var asa := Movimento.Estado.new()
	for i in 60:
		Movimento.passo(livre, 0.0, false, true, false, DT)
		Movimento.passo(asa, 0.0, false, true, false, DT, 1, 1.0, 1.0, true)
	_ok(livre.velocidade.y > Movimento.VEL_PLANAR + 50.0,
		"sem planar a queda devia disparar (%.0f)" % livre.velocidade.y)
	_ok(is_equal_approx(asa.velocidade.y, Movimento.VEL_PLANAR),
		"a planar a queda devia ficar presa a VEL_PLANAR (%.0f)" % asa.velocidade.y)
	_ok(asa.velocidade.y > 0.0, "planar e' cair devagar, nao subir")
	# e SO' a descer: a subir do salto, o planar nao pode segurar nada
	var sobe := Movimento.Estado.new()
	Movimento.passo(sobe, 0.0, false, false, true, DT, 1, 1.0, 1.0, true)
	Movimento.passo(sobe, 0.0, true, true, false, DT, 1, 1.0, 1.0, true)
	_ok(sobe.velocidade.y < 0.0, "o planar nao pode cortar o salto")


## GANCHO (nivel 53): a matematica do balanco. Tudo aqui e' puro -- o
## `Movimento` nao sabe o que e' uma trepadeira, so' sabe um pendulo.
func teste_gancho_balanca_como_pendulo() -> void:
	# largada de lado, sem comando: cai para o fundo do arco e passa por la'
	var th := 0.9
	var v := 0.0
	var passou := false
	for i in 200:
		var r := Movimento.balanco(th, v, 130.0, 0.0, DT)
		th = r[0]
		v = r[1]
		if absf(th) < 0.05:
			passou = true
			break
	_ok(passou, "o balanco devia cair para o fundo do arco (theta = %.2f)" % th)

	# o atrito existe: a amplitude de um balanco livre nao pode CRESCER
	th = 0.9
	v = 0.0
	var amp := 0.0
	for i in 2000:
		var r2 := Movimento.balanco(th, v, 130.0, 0.0, DT)
		th = r2[0]
		v = r2[1]
		amp = maxf(amp, absf(th))
	_ok(amp <= 0.92, "sem comando a amplitude nao pode crescer (%.2f de 0.90)" % amp)

	# e o comando dela empurra mesmo: a puxar sempre para o mesmo lado
	# ganha-se altura em relacao a um balanco livre
	var th_a := 0.2
	var v_a := 0.0
	var pico := 0.0
	for i in 400:
		var dir := signf(cos(th_a)) * signf(v_a) if v_a != 0.0 else 1.0
		var r3 := Movimento.balanco(th_a, v_a, 130.0, dir, DT)
		th_a = r3[0]
		v_a = r3[1]
		pico = maxf(pico, absf(th_a))
	_ok(pico > 0.35, "a bombar, o balanco devia subir (%.2f de 0.20)" % pico)


## E o que se ganha ao LARGAR: pela tangente, mais um empurrao para cima.
## E' isto que faz o balanco servir para atravessar.
func teste_gancho_largar_atira_pela_tangente() -> void:
	# no fundo do arco (theta = 0) a tangente e' horizontal: sai para a
	# frente, nao para cima
	var vf := Movimento.velocidade_ao_largar(0.0, 2.0, 130.0)
	_ok(vf.x > 200.0, "no fundo do arco devia sair para a frente (vx = %.0f)" % vf.x)
	_ok(vf.y < 0.0, "e sempre com um empurrao para cima (vy = %.0f)" % vf.y)
	# ao contrario, sai para tras
	var vt := Movimento.velocidade_ao_largar(0.0, -2.0, 130.0)
	_ok(vt.x < -200.0, "a balancar ao contrario devia sair para tras (vx = %.0f)" % vt.x)
	# e o ponto do balanco: theta = 0 e' pendurada A DIREITO por baixo
	var p := Movimento.ponto_do_balanco(Vector2(100.0, 50.0), 0.0, 130.0)
	_ok(is_equal_approx(p.x, 100.0) and is_equal_approx(p.y, 180.0),
		"theta = 0 devia po-la por baixo da ancora (%.0f, %.0f)" % [p.x, p.y])


## GRAVIDADE INVERTIDA (nivel 67): a mesma conta com um sinal. Nao ha' um
## segundo caminho de codigo -- e' este teste que o garante.
func teste_movimento_gravidade_invertida() -> void:
	# a cair: com sinal -1 a velocidade vertical fica NEGATIVA (sobe)
	var inv := Movimento.Estado.new()
	for i in 20:
		Movimento.passo(inv, 0.0, false, false, false, DT, 1, 1.0, 1.0, false, -1.0)
	_ok(inv.velocidade.y < -100.0,
		"invertida, devia cair PARA CIMA (vy = %.0f)" % inv.velocidade.y)

	# o salto tambem vira: empurra para BAIXO
	var salto := Movimento.Estado.new()
	Movimento.passo(salto, 0.0, false, false, true, DT, 1, 1.0, 1.0, false, -1.0)
	Movimento.passo(salto, 0.0, true, true, false, DT, 1, 1.0, 1.0, false, -1.0)
	_ok(salto.velocidade.y > 0.0,
		"invertida, o salto devia empurrar para baixo (vy = %.0f)" % salto.velocidade.y)

	# o corte de salto continua a valer -- do lado certo
	var corte := Movimento.Estado.new()
	Movimento.passo(corte, 0.0, false, false, true, DT, 1, 1.0, 1.0, false, -1.0)
	Movimento.passo(corte, 0.0, true, true, false, DT, 1, 1.0, 1.0, false, -1.0)
	var vy_antes := corte.velocidade.y
	Movimento.passo(corte, 0.0, false, false, false, DT, 1, 1.0, 1.0, false, -1.0)
	_ok(corte.velocidade.y < vy_antes,
		"invertida, largar o botao devia cortar o salto (%.0f -> %.0f)"
			% [vy_antes, corte.velocidade.y])

	# e a queda tem tecto dos dois lados
	var tecto := Movimento.Estado.new()
	for i in 400:
		Movimento.passo(tecto, 0.0, false, false, false, DT, 1, 1.0, 1.0, false, -1.0)
	_ok(tecto.velocidade.y >= -Movimento.VEL_MAX_QUEDA - 1.0,
		"invertida, a queda tem de ter tecto (vy = %.0f)" % tecto.velocidade.y)

	# o normal continua exatamente igual (a inversao nao pode mexer nele)
	var normal := Movimento.Estado.new()
	for i in 20:
		Movimento.passo(normal, 0.0, false, false, false, DT)
	_ok(is_equal_approx(normal.velocidade.y, -inv.velocidade.y),
		"a inversao devia ser SIMETRICA (%.0f vs %.0f)"
			% [normal.velocidade.y, inv.velocidade.y])


func teste_movimento_salto_duplo() -> void:
	var e := Movimento.Estado.new()
	Movimento.passo(e, 0.0, false, false, true, DT, 2)   # 1 frame no chao arma o coyote
	Movimento.passo(e, 0.0, true, true, false, DT, 2)    # 1.o salto (dentro do coyote)
	_ok(e.saltos_dados == 1, "o 1.o salto devia contar como 1 salto gasto")
	for i in 20:                                         # deixa a subida abrandar
		Movimento.passo(e, 0.0, false, true, false, DT, 2)
	var vy_antes := e.velocidade.y
	Movimento.passo(e, 0.0, true, true, false, DT, 2)    # 2.o salto, no ar
	_ok(e.velocidade.y < vy_antes, "o salto duplo devia voltar a impulsionar para cima")
	_ok(e.saltos_dados == 2, "apos o salto duplo deviam estar 2 saltos gastos")


func teste_movimento_sem_habilidade_nao_ha_salto_duplo() -> void:
	var e := Movimento.Estado.new()
	Movimento.passo(e, 0.0, false, false, true, DT)      # chao (saltos_max = 1 por omissao)
	Movimento.passo(e, 0.0, true, true, false, DT)       # 1.o salto
	for i in 8:
		Movimento.passo(e, 0.0, false, true, false, DT)
	var vy_antes := e.velocidade.y
	Movimento.passo(e, 0.0, true, true, false, DT)       # tenta 2.o salto sem habilidade
	_ok(e.velocidade.y > vy_antes, "sem salto duplo o 2.o salto no ar nao faz nada (so gravidade)")
	_ok(e.saltos_dados == 1, "sem salto duplo fica-se por 1 salto")


func teste_movimento_sair_da_borda_perde_primeiro_salto() -> void:
	var e := Movimento.Estado.new()
	Movimento.passo(e, 0.0, false, false, true, DT)      # no chao
	for i in 12:                                         # anda para lá da borda sem saltar
		Movimento.passo(e, 0.0, false, false, false, DT)
	_ok(e.saltos_dados == 1, "coyote expirado sem saltar gasta o salto do chao")
	var vy_antes := e.velocidade.y
	Movimento.passo(e, 0.0, true, true, false, DT, 2)    # com salto duplo ainda resta 1
	_ok(e.velocidade.y < vy_antes, "com salto duplo resta 1 salto no ar mesmo saindo da borda")


# --- Rolamento (predicado puro) ------------------------------------------

func teste_koliani_pode_rolar() -> void:
	_ok(Movimento.pode_rolar(0.0, true, 0.0, 0.0),
		"recarga pronta + no chao => pode rolar")
	_ok(not Movimento.pode_rolar(0.2, true, 0.0, 0.0),
		"recarga a decorrer => nao pode rolar")
	_ok(not Movimento.pode_rolar(0.0, false, 0.0, 0.0),
		"no ar => nao pode rolar")
	_ok(not Movimento.pode_rolar(0.0, true, 0.1, 0.0),
		"ja a rolar => nao encadeia")
	_ok(not Movimento.pode_rolar(0.0, true, 0.0, 0.1),
		"em dash => nao rola")


## O escudo bloqueia golpes que venham de frente (a Koliani virada para a
## fonte), deixa passar os das costas, e vale quando a direcao e' 0.
func teste_koliani_bloqueio_de_frente() -> void:
	# virada a' direita (+1): um golpe da direita empurra-a para a esquerda (-1) -> bloqueia
	_ok(Movimento.bloqueia_de_frente(-1.0, 1.0), "golpe de frente (da direita) devia ser bloqueado")
	# virada a' direita: golpe pelas costas empurra-a para a direita (+1) -> passa
	_ok(not Movimento.bloqueia_de_frente(1.0, 1.0), "golpe pelas costas nao devia ser bloqueado")
	# virada a' esquerda (-1): golpe da esquerda empurra-a para a direita (+1) -> bloqueia
	_ok(Movimento.bloqueia_de_frente(1.0, -1.0), "golpe de frente (da esquerda) devia ser bloqueado")
	_ok(not Movimento.bloqueia_de_frente(-1.0, -1.0), "golpe pelas costas (virada a' esquerda) passa")
	_ok(Movimento.bloqueia_de_frente(0.0, 1.0), "sem direcao conhecida o escudo vale")


## O projétil mágico sai numa das 8 direções conforme a mira; sem mira vai
## para onde a Koliani está virada.
func teste_koliani_direcao_mira() -> void:
	var r2 := sqrt(0.5)
	_ok(Movimento.direcao_mira(0.0, 0.0, 1.0) == Vector2.RIGHT, "sem mira -> para onde esta' virada (direita)")
	_ok(Movimento.direcao_mira(0.0, 0.0, -1.0) == Vector2.LEFT, "sem mira -> para onde esta' virada (esquerda)")
	_ok(Movimento.direcao_mira(0.0, -1.0, 1.0) == Vector2.UP, "mira em cima -> cima")
	_ok(Movimento.direcao_mira(0.0, 1.0, 1.0) == Vector2.DOWN, "mira em baixo -> baixo")
	var d := Movimento.direcao_mira(1.0, -1.0, 1.0)
	_ok(is_equal_approx(d.x, r2) and is_equal_approx(d.y, -r2), "mira diagonal cima-direita -> 45 graus normalizado")
	_ok(Movimento.direcao_mira(0.1, 0.0, -1.0) == Vector2.LEFT, "input abaixo da deadzone conta como sem mira")


# --- Tremor (screen shake, lógica pura) --------------------------------

func teste_tremor_impulso_e_decaimento() -> void:
	var t := Tremor.new()
	_ok(t.passo(DT) == Vector2.ZERO, "sem impulso nao ha deslocamento")
	t.bater(10.0)
	_ok(t.passo(DT).length() > 0.0, "apos bater() ha deslocamento")
	for i in 200:
		t.passo(DT)
	_ok(not t.ativo(), "o tremor decai ate parar")
	_ok(t.passo(DT) == Vector2.ZERO, "parado => deslocamento zero")


# --- Diário de pistas ----------------------------------------------------

func teste_diario_entradas_e_fallback() -> void:
	var lista := DiarioPistas.entradas(["floresta_sinal_da_porta", "id_desconhecido"])
	_ok(lista.size() == 2, "entradas devia devolver uma linha por id")
	_ok(lista[0]["titulo"] == "clue.floresta_sinal_da_porta.title", "id conhecido traz a chave do titulo")
	_ok(lista[0]["mundo"] == "world.forest", "id conhecido traz a chave do mundo")
	_ok(lista[0]["texto"] == "clue.floresta_sinal_da_porta.body", "id conhecido traz a chave do corpo")
	_ok(lista[1]["titulo"] == "id_desconhecido", "id sem pista cai no proprio id")
	_ok(lista[1]["texto"] == "", "id sem pista tem corpo vazio")
	_ok(DiarioPistas.total_no_jogo() >= 2, "total_no_jogo conta o dicionario")


## Toda a chave que o DiarioPistas usa tem de existir no en.json (fallback).
func teste_i18n_en_tem_as_chaves_das_pistas() -> void:
	var f := FileAccess.open("res://assets/i18n/en.json", FileAccess.READ)
	_ok(f != null, "en.json devia existir")
	if f == null:
		return
	var en: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	_ok(en is Dictionary, "en.json devia ser um objecto")
	if not (en is Dictionary):
		return
	for id: String in DiarioPistas.PISTAS:
		var p: Dictionary = DiarioPistas.PISTAS[id]
		for campo in ["mundo", "titulo", "texto"]:
			_ok(en.has(p[campo]), "en.json sem a chave '%s' (pista %s)" % [p[campo], id])


## O catálogo da campanha (nomes de nível/chefe para o carrossel de escolha)
## acompanha `EstadoJogo.NIVEIS`: uma chave de chefe por nível, todas bem
## formadas e únicas, e o en.json tem os textos de todas as chaves que o
## carrossel usa (level.n##, boss.* e sel.*).
func teste_catalogo_campanha() -> void:
	var e := _novo_estado()
	var n: int = e.NIVEIS.size()
	e.free()
	_ok(CatalogoCampanha.CHEFE_KEY.size() == n,
		"CatalogoCampanha.CHEFE_KEY devia ter uma entrada por nível (%d)" % n)
	var vistas := {}
	for k in CatalogoCampanha.CHEFE_KEY:
		# nem todo o nível acaba num chefe: os que acabam num guardião levam
		# `guard.*` (ver `CatalogoCampanha.tem_chefe`)
		_ok(k.begins_with("boss.") or k.begins_with("guard."),
			"chave de fim de nível mal formada: '%s'" % k)
		_ok(not vistas.has(k), "chave de chefe repetida: '%s'" % k)
		vistas[k] = true

	var f := FileAccess.open("res://assets/i18n/en.json", FileAccess.READ)
	_ok(f != null, "en.json devia existir")
	if f == null:
		return
	var en: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (en is Dictionary):
		_ok(false, "en.json devia ser um objecto")
		return
	for k in CatalogoCampanha.CHEFE_KEY:
		_ok(en.has(k), "en.json sem o nome do chefe '%s'" % k)
	for i in n:
		var lk := CatalogoCampanha.chave_nivel(i)
		_ok(en.has(lk), "en.json sem o nome do nível '%s'" % lk)
	for k in ["sel.play", "sel.back", "sel.locked", "sel.cleared", "sel.boss", "sel.count", "sel.hint"]:
		_ok(en.has(k), "en.json sem a chave do carrossel '%s'" % k)


## Equipamento: 20 armas (uma por cada 5 níveis) + 10 armaduras (uma por
## cada 10); as curvas sobem sempre; `recompensas_do_nivel` mapeia o índice
## do nível para o item certo -- e dá DOIS nos múltiplos de 10; e o en.json
## tem os nomes todos.
func teste_equipamento_dados() -> void:
	_ok(Equipamento.ARMAS.size() == 20, "deviam ser 20 armas")
	_ok(Equipamento.ARMADURAS.size() == 10, "deviam ser 10 armaduras")
	for i in Equipamento.ARMAS.size():
		_ok(int(Equipamento.ARMAS[i]["nivel"]) == Equipamento.NIVEIS_POR_ARMA * (i + 1),
			"a arma %d devia desbloquear no nível %d" % [i, Equipamento.NIVEIS_POR_ARMA * (i + 1)])
		if i > 0:
			_ok(int(Equipamento.ARMAS[i]["dano"]) >= int(Equipamento.ARMAS[i - 1]["dano"]),
				"o dano das armas devia ser não-decrescente")
	for i in Equipamento.ARMADURAS.size():
		_ok(int(Equipamento.ARMADURAS[i]["nivel"]) == Equipamento.NIVEIS_POR_ARMADURA * (i + 1),
			"a armadura %d devia desbloquear no nível %d" % [i, Equipamento.NIVEIS_POR_ARMADURA * (i + 1)])
		# a célula da tira tem de existir (a tira tem 15 frames)
		var cel := int(Equipamento.ARMADURAS[i]["celula"])
		_ok(cel >= 0 and cel < 15, "a armadura %d aponta para a célula %d, fora da tira" % [i, cel])
		if i > 0:
			_ok(int(Equipamento.ARMADURAS[i]["vida_bonus"]) >= int(Equipamento.ARMADURAS[i - 1]["vida_bonus"]),
				"o vida_bonus das armaduras devia ser não-decrescente")
			_ok(float(Equipamento.ARMADURAS[i]["reducao"]) >= float(Equipamento.ARMADURAS[i - 1]["reducao"]),
				"a redução das armaduras devia ser não-decrescente")
	# o último de cada tipo cai no nível 100: a campanha inteira está coberta
	_ok(int(Equipamento.ARMAS[19]["nivel"]) == 100, "a última arma é do nível 100")
	_ok(int(Equipamento.ARMADURAS[9]["nivel"]) == 100, "a última armadura é do nível 100")

	_ok(Equipamento.recompensas_do_nivel(0).is_empty(), "o nível 1 não dá equipamento")
	_ok(Equipamento.recompensas_do_nivel(3).is_empty(), "o nível 4 não dá equipamento")
	var r4 := Equipamento.recompensas_do_nivel(4)      # nível 5
	_ok(r4.size() == 1 and r4[0]["tipo"] == "arma" and r4[0]["id"] == Equipamento.ARMAS[0]["id"],
		"acabar o nível 5 dá só a 1.ª arma")
	var r9 := Equipamento.recompensas_do_nivel(9)      # nível 10
	_ok(r9.size() == 2, "acabar o nível 10 dá DOIS prémios (arma + armadura)")
	if r9.size() == 2:
		_ok(r9[0]["id"] == Equipamento.ARMAS[1]["id"], "o nível 10 dá a 2.ª arma")
		_ok(r9[1]["id"] == Equipamento.ARMADURAS[0]["id"], "o nível 10 dá a 1.ª armadura")
	var r99 := Equipamento.recompensas_do_nivel(99)    # nível 100
	_ok(r99.size() == 2 and r99[0]["id"] == Equipamento.ARMAS[19]["id"]
		and r99[1]["id"] == Equipamento.ARMADURAS[9]["id"],
		"acabar o nível 100 dá a última arma e a última armadura")
	_ok(Equipamento.recompensas_do_nivel(200).is_empty(), "índice fora de alcance não dá nada")

	var f := FileAccess.open("res://assets/i18n/en.json", FileAccess.READ)
	if f == null:
		_ok(false, "en.json devia existir")
		return
	var en: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	for a in Equipamento.ARMAS:
		_ok(en.has(a["nome"]), "en.json sem o nome da arma '%s'" % a["nome"])
	for a in Equipamento.ARMADURAS:
		_ok(en.has(a["nome"]), "en.json sem o nome da armadura '%s'" % a["nome"])
	for k in ["gear.menu.weapons", "gear.menu.armor", "gear.locked", "gear.equip", "gear.equipped"]:
		_ok(en.has(k), "en.json sem a chave de menu '%s'" % k)


## EstadoJogo: acabar um nível concede o equipamento e equipa-o; os helpers
## de stat refletem o equipado; `reiniciar_campanha` limpa; o save
## sobrevive ao ida-e-volta.
func teste_equipamento_estado() -> void:
	var e := _novo_estado()
	_ok(e.armas.is_empty() and e.armaduras.is_empty(), "arranque limpo: sem equipamento")
	_ok(e.dano_ataque() == e.DANO_BASE, "sem arma -> dano base")
	_ok(e.vida_bonus_armadura() == 0 and is_equal_approx(e.reducao_armadura(), 0.0),
		"sem armadura -> sem bónus")

	e.marcar_nivel_concluido(0)  # nível 1 -> nada (a cadência é de 5 em 5)
	_ok(e.armas.is_empty() and e.armaduras.is_empty(),
		"acabar o nível 1 já não dá equipamento")

	e.marcar_nivel_concluido(4)  # nível 5 -> 1.ª arma, equipada
	_ok(e.armas.size() == 1, "acabar o nível 5 dá 1 arma")
	_ok(e.arma_equipada == Equipamento.ARMAS[0]["id"], "a arma nova é equipada logo")
	_ok(e.dano_ataque() == int(Equipamento.ARMAS[0]["dano"]), "dano_ataque segue a arma equipada")

	e.marcar_nivel_concluido(9)  # nível 10 -> 2.ª arma E 1.ª armadura
	_ok(e.armas.size() == 2, "acabar o nível 10 dá também a arma seguinte")
	_ok(e.armaduras.size() == 1, "acabar o nível 10 dá a 1.ª armadura")
	_ok(e.armadura_equipada == Equipamento.ARMADURAS[0]["id"], "armadura nova equipada")

	e.marcar_nivel_concluido(4)  # repetir não duplica
	_ok(e.armas.size() == 2, "reconcluir o nível não duplica o prémio")

	var copia := _novo_estado()
	copia.de_dicionario(e.para_dicionario())
	_ok(copia.armas == e.armas and copia.armaduras == e.armaduras, "equipamento sobrevive ao save")
	_ok(copia.arma_equipada == e.arma_equipada, "arma equipada sobrevive ao save")

	e.reiniciar_campanha()
	_ok(e.armas.is_empty() and e.arma_equipada == "", "reiniciar_campanha limpa o equipamento")
	e.free()
	copia.free()


## Todos os idiomas existem, são JSON válido e têm exatamente o mesmo
## conjunto de chaves do inglês (sem traduções em falta nem chaves a mais).
func teste_i18n_ficheiros_validos() -> void:
	var locs := ["en", "pt", "es", "fr", "de", "zh"]
	var chaves_en := {}
	for loc in locs:
		var caminho := "res://assets/i18n/%s.json" % loc
		var f := FileAccess.open(caminho, FileAccess.READ)
		_ok(f != null, "falta o idioma %s (%s)" % [loc, caminho])
		if f == null:
			continue
		var d: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		_ok(d is Dictionary, "%s.json devia ser um objecto JSON" % loc)
		if not (d is Dictionary):
			continue
		if loc == "en":
			chaves_en = d
			continue
		for k: String in chaves_en:
			_ok(d.has(k), "%s.json sem a chave '%s'" % [loc, k])
		for k: String in d:
			_ok(chaves_en.has(k), "%s.json tem a chave a mais '%s'" % [loc, k])


## O `head_include` do export Web e' UMA string dentro do
## `export_presets.cfg` -- sem newlines. Escrever HTML e JavaScript assim
## a mao e' ilegivel, portanto o conteudo vive em `web/head_pwa.html` e
## `tools/gerar_head_web.py` e' que o achata para la'.
##
## Isto guarda o obvio: editar o `head_pwa.html`, esquecer a ferramenta, e
## o build sair na mesma com o `head_include` antigo -- sem ninguem dar por
## isso, porque o jogo compila e corre na mesma. E' a diferenca entre "o
## som do iPhone esta' corrigido" e "esta' corrigido no ficheiro".
func teste_head_pwa_em_dia() -> void:
	var fonte := _fonte("res://web/head_pwa.html")
	var cfg := _fonte("res://export_presets.cfg")
	if fonte == "" or cfg == "":
		return

	# o mesmo achatamento da ferramenta: fora os comentarios, uma linha so'
	var rc := RegEx.new()
	rc.compile("(?s)<!--.*?-->")
	var limpo := rc.sub(fonte, "", true)
	var partes: Array[String] = []
	for linha in limpo.split("
"):
		var l := linha.strip_edges()
		if l != "":
			partes.append(l)
	var esperado := " ".join(partes)

	_ok(not esperado.contains("\""),
		"o web/head_pwa.html tem aspas DUPLAS -- nao cabem no .cfg")

	var rh := RegEx.new()
	rh.compile("html/head_include=\"(.*)\"")
	var m := rh.search(cfg)
	_ok(m != null, "o preset Web nao tem `html/head_include`")
	if m == null:
		return
	_ok(m.get_string(1) == esperado,
		"o head_include esta DESACTUALIZADO (%d chars no .cfg, %d no head_pwa.html)"
			 % [m.get_string(1).length(), esperado.length()]
		+ " -- corre `python tools/gerar_head_web.py`")

	# e as tres coisas por que ele existe, uma a uma
	for peca in ["apple-mobile-web-app-capable", "viewport-fit=cover",
			"audioSession", "orientation:portrait"]:
		_ok(esperado.contains(peca),
			"o head do Web perdeu a peca '%s'" % peca)


## SILÊNCIO TOTAL NO WEB/PWA (Execution 9F). Não era o gesto nem o
## autoplay: com o AudioContext `running`, o pico no destino era 0.
## No Web o Godot 4.7.2 toca em modo *Sample* e espelha os buses em JS;
## o `GodotAudio.Bus.move()` do motor faz `splice(toIndex-1, ...)`, por
## isso um bus acrescentado em RUNTIME (`AudioServer.add_bus`) passava
## para a posição 0 e o `set_bus_send(.., "Master")` ligava o Master
## antigo ao bus novo -- um ciclo Master->SFX->Music->Master sem saída
## para o `AudioDestination`. Medido no grafo (docs/execution_9f_*).
##
## A correcção é os buses virem do `default_bus_layout.tres` (criados
## pelo motor no arranque, por ordem, sem `move`). Este teste morde se
## alguém apagar o layout ou voltar a precisar do `_criar_buses`.
func teste_9f_buses_de_audio_estaticos() -> void:
	var caminho := str(ProjectSettings.get_setting(
		"audio/buses/default_bus_layout", "res://default_bus_layout.tres"))
	_ok(ResourceLoader.exists(caminho),
		"9F: falta o layout de buses estatico (%s) -- no Web o audio fica MUDO" % caminho)
	var layout = load(caminho) if ResourceLoader.exists(caminho) else null
	_ok(layout is AudioBusLayout, "9F: %s nao e' um AudioBusLayout" % caminho)
	if layout is AudioBusLayout:
		for i in [1, 2]:
			var nome := "Music" if i == 1 else "SFX"
			_ok(str(layout.get("bus/%d/name" % i)) == nome,
				"9F: o bus %d do layout devia ser '%s'" % [i, nome])
			_ok(str(layout.get("bus/%d/send" % i)) == "Master",
				"9F: o bus '%s' tem de mandar para o Master" % nome)

	# no runtime: os buses ja' existem ANTES do Opcoes (nenhum add_bus)
	_ok(AudioServer.bus_count == 3,
		"9F: esperados 3 buses (Master/Music/SFX), ha' %d" % AudioServer.bus_count)
	_ok(AudioServer.get_bus_index("Music") == 1 and AudioServer.get_bus_index("SFX") == 2,
		"9F: Music/SFX fora da ordem do layout (%d/%d)"
			% [AudioServer.get_bus_index("Music"), AudioServer.get_bus_index("SFX")])
	for nome in ["Music", "SFX"]:
		var i := AudioServer.get_bus_index(nome)
		if i >= 0:
			_ok(AudioServer.get_bus_send(i) == &"Master",
				"9F: o bus '%s' manda para '%s'" % [nome, AudioServer.get_bus_send(i)])
	_ok(not AudioServer.is_bus_mute(0), "9F: o Master esta' mudo")
	_ok(is_equal_approx(AudioServer.get_bus_volume_db(0), 0.0),
		"9F: o Master nao esta' a 0 dB (%.1f)" % AudioServer.get_bus_volume_db(0))
	# o volume guardado continua a mandar (0 = mudo de proposito)
	_ok(AudioServer.is_bus_mute(1) == (Opcoes.vol_musica <= 0.001),
		"9F: o mute do Music nao segue as Opcoes")
	_ok(AudioServer.is_bus_mute(2) == (Opcoes.vol_efeitos <= 0.001),
		"9F: o mute do SFX nao segue as Opcoes")
	_ok(not bool(Opcoes.get("_criou_buses")),
		"9F: o Opcoes teve de criar buses em runtime -- no Web isso cala o jogo")

	# o export leva o audio e o desbloqueio por gesto continua no head
	var cfg := _fonte("res://export_presets.cfg")
	var rx := RegEx.new()
	rx.compile("(?s)name=\"Web\".*?exclude_filter=\"([^\"]*)\"")
	var m := rx.search(cfg)
	_ok(m != null, "9F: preset Web sem exclude_filter")
	if m:
		_ok(not m.get_string(1).contains("audio") and not m.get_string(1).contains("*.ogg"),
			"9F: o preset Web exclui audio (%s)" % m.get_string(1))
	var head := _fonte("res://web/head_pwa.html")
	for peca in [".resume(", "kolianiGodotAudioReady", "kolianiAudioDiag"]:
		_ok(head.contains(peca), "9F: o head do Web perdeu '%s'" % peca)
	for c in ["res://assets/audio/bg_menu.mp3", "res://assets/audio/musica/niveis/nivel_01.ogg",
			"res://assets/audio/carrossel.wav", "res://assets/audio/ataque.ogg"]:
		_ok(ResourceLoader.exists(c), "9F: falta o audio %s" % c)


## UI DE PRODUÇÃO (Execution 9F). O kit vem da prancha 09 por
## `tools/produzir_ui_9f.py`; aqui guarda-se que (1) as peças no disco são
## as do manifesto (SHA), (2) o tema usa-as, (3) o seletor comunica 20
## regiões × 5 níveis sem mexer no desbloqueio, e (4) HUD/pausa/opções já
## não desenham os estilos legados.
func teste_9f_ui_producao() -> void:
	var dir := "res://assets/ui/producao_9f/"
	var man: Variant = JSON.parse_string(_fonte(dir + "manifesto_ui_9f.json"))
	_ok(man is Dictionary, "9F: manifesto do kit de UI em falta")
	if not (man is Dictionary):
		return
	_ok(str(man.get("sha_autoridade", "")) == "264d6def7c961ea04635754ae91f33f81c891a6eae6eddaf0b1420f094a7aba9",
		"9F: o kit nao aponta a prancha 09 aprovada")
	var pecas: Dictionary = man.get("pecas", {})
	_ok(pecas.size() >= 19, "9F: kit com %d pecas (esperadas 19)" % pecas.size())
	for nome: String in pecas:
		var cam: String = dir + str(pecas[nome].get("ficheiro", ""))
		var bytes := FileAccess.get_file_as_bytes(cam)
		var h := HashingContext.new()
		h.start(HashingContext.HASH_SHA256)
		h.update(bytes)
		_ok(h.finish().hex_encode() == str(pecas[nome].get("sha256", "")),
			"9F: %s nao bate com o SHA do manifesto" % nome)
		_ok(ResourceLoader.exists(cam), "9F: %s nao importado" % cam)

	_ok(UIProducao.disponivel(), "9F: UIProducao sem texturas")
	var sb := UIProducao.tema().get_stylebox("normal", "Button")
	_ok(sb is StyleBoxTexture and (sb as StyleBoxTexture).texture.resource_path.begins_with(dir),
		"9F: o tema nao usa o botao do kit")

	# seletor (9H): mapa de regiao -- 5 nos por regiao, fichas "1-1".."20-5",
	# abas das 20 regioes, desbloqueio intacto
	var desbloq_antes: Array = []
	for i in EstadoJogo.NIVEIS.size():
		desbloq_antes.append(EstadoJogo.nivel_desbloqueado(i))
	var sel: SeletorNiveis = load("res://scenes/ui/SeletorNiveis.tscn").instantiate()
	get_tree().root.add_child(sel)
	sel.size = Vector2(1280, 720)
	sel.configurar(0, false)
	var nos: Array = sel.get("_nos")
	_ok(nos.size() == 5, "9H: %d nos no mapa (esperados 5)" % nos.size())
	var fichas := func() -> Array:
		var v: Array = []
		for n in nos:
			v.append((n["rotulo"] as Label).text)
		return v
	var indices := func() -> Array:
		var v: Array = []
		for n in nos:
			v.append(int(n["indice"]))
		return v
	_ok(indices.call() == [0, 1, 2, 3, 4],
		"9H: a regiao I devia mostrar os niveis 0..4 (%s)" % [indices.call()])
	_ok(fichas.call() == ["1-1", "1-2", "1-3", "1-4", "1-5"],
		"9H: fichas da regiao I erradas (%s)" % [fichas.call()])
	sel.call("_mudar_regiao", 3)
	_ok(indices.call() == [15, 16, 17, 18, 19],
		"9H: a regiao IV devia mostrar 15..19 (%s)" % [indices.call()])
	_ok(fichas.call() == ["4-1", "4-2", "4-3", "4-4", "4-5"],
		"9H: fichas da regiao IV erradas (%s)" % [fichas.call()])
	var titulo: Label = sel.get("_titulo_regiao")
	_ok(titulo != null and titulo.text.contains("IV"), "9H: cabecalho da regiao nao diz IV")
	var abas: Array = sel.get("_abas")
	_ok(abas.size() == 5, "9H: %d abas de regiao (esperadas 5)" % abas.size())
	sel.call("_mudar_regiao", 16)   # ate' a ultima regiao
	_ok(int(sel.get("_regiao")) == 19 and indices.call()[4] == 99,
		"9H: a ultima regiao devia acabar no nivel 100 (%s)" % [indices.call()])
	for i in EstadoJogo.NIVEIS.size():
		if EstadoJogo.nivel_desbloqueado(i) != desbloq_antes[i]:
			_ok(false, "9H: o seletor mexeu no desbloqueio do nivel %d" % i)
			break
	sel.queue_free()

	# ecras de menu: sem StyleBoxFlat legado nos botoes.
	# 9H.11: a Pausa passou do kit de ouro (9F) para a linguagem do menu
	# principal, onde uma ENTRADA DE MENU nao tem caixa em repouso -- a placa
	# em losango so' aparece no hover/foco. Por isso o "normal" pode ser vazio
	# desde que o realce venha de uma peca pintada de um dos kits.
	for cena in ["res://scenes/ui/Opcoes.tscn", "res://scenes/ui/Pausa.tscn"]:
		var no: Node = load(cena).instantiate()
		get_tree().root.add_child(no)
		for b in no.find_children("*", "Button", true, false):
			var bt := b as Button
			var st := bt.get_theme_stylebox("normal")
			var vestido: bool = st is StyleBoxTexture or (
				st is StyleBoxEmpty and bt.get_theme_stylebox("hover") is StyleBoxTexture)
			_ok(vestido, "9F: %s -> botao '%s' ainda com estilo legado" % [cena.get_file(), b.name])
		no.queue_free()

	# HUD: calha/enchimento das barras do kit
	var hud: Node = load("res://scenes/ui/HUD.tscn").instantiate()
	get_tree().root.add_child(hud)
	var calha := hud.get_node_or_null("Vida/Barra/CalhaMeio") as TextureRect
	_ok(calha != null and (calha.texture as AtlasTexture).atlas.resource_path == dir + "barra_vida_calha.png",
		"9F: a barra de vida da HUD nao usa a calha do kit")
	hud.queue_free()

##  - "os controlos do telefone movimenta-se ao utilizar, não pode
##    acontecer -- têm que ficar fixos": o aro do joystick era flutuante
##    (ia ter com o dedo). Agora não sai do sítio, e é isso que se mede.
##  - "falta um botão no UI de telefone para o dash".
##
## E, de caminho, que os botões não se sobreponham: cada um que entra
## empurra a arrumação, e dois círculos a tocarem-se são dois botões que
## disparam ao mesmo tempo -- o `_pousar` fica no primeiro que encontra.
func teste_controlos_tacteis_fixos() -> void:
	var c := ControlosTacteis.new()
	c.size = Vector2(1600.0, 720.0)
	c.call("_medir")
	var base: Vector2 = c.get("_joy_base")

	# um dedo LONGE do aro, mas dentro da metade do joystick
	var longe := Vector2(base.x + 260.0, base.y - 190.0)
	_ok(bool(c.call("_pousar", 0, longe)), "o joystick não agarrou o dedo")
	_ok(c.get("_joy_base") == base,
		"o aro do joystick MEXEU-SE (%s -> %s)" % [base, c.get("_joy_base")])
	_ok(Input.is_action_pressed("mover_direita"),
		"o dedo à direita do aro devia andar para a direita")
	c.call("_levantar", 0)
	_ok(not Input.is_action_pressed("mover_direita"), "não largou o mover_direita")

	# O EIXO DE CIMA/BAIXO É A MIRA. Sem isto os projéteis do telemóvel só
	# saíam na horizontal: `mirar_cima`/`mirar_baixo` só estavam no W e no S
	# do teclado, e no telemóvel não há nada que carregue numa tecla.
	c.call("_pousar", 1, Vector2(base.x + 20.0, base.y - 200.0))
	_ok(Input.is_action_pressed("mirar_cima"),
		"empurrar o joystick para CIMA devia apontar para cima")
	c.call("_levantar", 1)
	_ok(not Input.is_action_pressed("mirar_cima"), "não largou o mirar_cima")

	# e a zona morta vertical é maior: o polegar pousado não pode agachar
	c.call("_pousar", 2, Vector2(base.x + 200.0, base.y + 26.0))
	_ok(Input.is_action_pressed("mover_direita"), "o lado devia ler-se")
	_ok(not Input.is_action_pressed("mirar_baixo"),
		"26 px de queda do polegar não podem contar como apontar para baixo")
	c.call("_levantar", 2)

	# a mira ao meio (diagonal): é isto que dá o tiro a 45 graus
	var diag := Movimento.direcao_mira(1.0, -1.0, 1.0)
	_ok(is_equal_approx(diag.x, diag.y * -1.0) and diag.x > 0.6,
		"direita+cima devia dar 45 graus e deu %s" % diag)

	# o botão do dash existe e carrega mesmo a acção "dash"
	var accoes := {}
	for b: Dictionary in ControlosTacteis.BOTOES:
		accoes[String(b["accao"])] = true
	for a2 in ["dash", "saltar", "atacar", "defender", "lancar"]:
		_ok(accoes.has(a2), "os controlos de toque não têm botão para '%s'" % a2)

	# nenhum par de botões se toca
	var n: int = ControlosTacteis.BOTOES.size()
	for i in n:
		for j in range(i + 1, n):
			var si: Array = c.call("_sitio", ControlosTacteis.BOTOES[i])
			var sj: Array = c.call("_sitio", ControlosTacteis.BOTOES[j])
			var d: float = (si[0] as Vector2).distance_to(sj[0] as Vector2)
			# 1.15 é a folga com que o `_pousar` aceita um toque: o que não se pode
			# tocar são as ÁREAS SENSÍVEIS, não os círculos desenhados
			var soma := (float(si[1]) + float(sj[1])) * 1.15
			_ok(d > soma,
				"os botões '%s' e '%s' sobrepõem-se (%.0f px entre centros, precisam de %.0f)"
					% [ControlosTacteis.BOTOES[i]["accao"], ControlosTacteis.BOTOES[j]["accao"],
						d, soma])
	# TOCAR NO ECRA NAO PODE ATIRAR. O Godot emula um clique de rato a partir
	# de cada toque, e o `lancar` tinha o botao esquerdo ligado -- tocar em
	# qualquer sitio disparava. Com os controlos de toque a` vista, o rato sai
	# destas accoes.
	c.visible = true
	c.call("_so_com_botao")
	for accao in ControlosTacteis.SO_COM_BOTAO:
		for ev in InputMap.action_get_events(accao):
			_ok(not (ev is InputEventMouseButton),
				"'%s' ainda dispara com o rato -- no telemovel isso e' tocar no ecra" % accao)
	# FALHAR UM BOTAO POR POUCO vale o mais perto (pedido dele: num telemovel
	# o dedo TAPA o botao, e quem falha nao sabe que falhou).
	var s_salto: Array = c.call("_sitio", ControlosTacteis.BOTOES[4])
	var centro_salto: Vector2 = s_salto[0]
	var r_salto: float = s_salto[1]
	# 50 px para fora da borda: falhou, mas e' claramente o Salto
	c.call("_pousar", 3, centro_salto + Vector2(r_salto + 50.0, 0.0))
	_ok(Input.is_action_pressed("saltar"),
		"falhar o Salto por 50 px devia contar como Salto")
	c.call("_levantar", 3)

	# mas o meio do ecra nao pertence a botao nenhum
	var longe2 := Vector2(c.size.x * 0.62, c.size.y * 0.25)
	_ok(not bool(c.call("_pousar", 4, longe2)),
		"um toque no meio do ecra nao pode carregar num botao")
	for accao in ["saltar", "dash", "lancar", "atacar", "defender"]:
		_ok(not Input.is_action_pressed(accao),
			"o toque no meio do ecra carregou em '%s'" % accao)

	c.free()


## TUTORIAL DA MECÂNICA (pedido do Paulo, 5 set 2026: "quando uma mecânica
## aparece pela primeira vez, aparece uma mensagem a dizer como funciona").
##
## A HUD não mostra nada se faltar a chave -- o que é a decisão certa em
## jogo (melhor sem aviso do que com `mec.gancho.txt` no ecrã) e a errada
## para quem escreve os níveis: uma mecânica nova ficava calada e ninguém
## dava por isso. Isto conta-as: cada câmara que ESTREIA em algum nível tem
## de ter nome e texto no `en.json` (os outros 5 idiomas são garantidos pelo
## `teste_i18n_ficheiros_validos`, que exige as mesmas chaves em todos).
##
## Os textos geram-se com `python tools/gerar_textos_mecanicas.py`.
func teste_tutorial_mecanica_tem_texto() -> void:
	var ger := _fonte("res://scripts/gerador_corredor.gd")
	if ger == "":
		return
	var i := ger.find("const MECANICA_DO_NIVEL :=")
	var fim := ger.find("
]", i)
	var bloco := ger.substr(i, maxi(0, fim - i))
	var rn := RegEx.new()
	rn.compile('"cam": "([a-z_]+)"')
	var cams: Array[String] = []
	for m in rn.search_all(bloco):
		cams.append(m.get_string(1))
	var estado := _novo_estado()
	var n_niveis: int = estado.NIVEIS.size()
	estado.free()
	_ok(cams.size() == n_niveis,
		"MECANICA_DO_NIVEL tem %d entradas (deviam ser %d)" % [cams.size(), n_niveis])

	var en := _json_i18n("en")
	var vistas := {}
	for n in cams.size():
		var cam := cams[n]
		if vistas.has(cam):
			# não estreia aqui: é uma repetição, e essas não levam tutorial
			continue
		vistas[cam] = n
		_ok(en.has("mec.%s.nome" % cam),
			"nível %d: a mecânica '%s' estreia sem nome (mec.%s.nome)" % [n + 1, cam, cam])
		_ok(en.has("mec.%s.txt" % cam),
			"nível %d: a mecânica '%s' estreia sem explicação (mec.%s.txt)" % [n + 1, cam, cam])

	# e a estreia que o nível anuncia tem de ser mesmo a primeira vez
	var g := GeradorCorredor
	for n in cams.size():
		var esperado: String = cams[n] if int(vistas.get(cams[n], -1)) == n else ""
		_ok(g.estreia_do_nivel(n) == esperado,
			"estreia_do_nivel(%d) devia dar '%s' e deu '%s'"
				% [n, esperado, g.estreia_do_nivel(n)])
	_ok(g.estreia_do_nivel(-1) == "", "estreia_do_nivel(-1) devia dar \"\"")
	_ok(g.estreia_do_nivel(cams.size()) == "",
		"estreia_do_nivel(fora da tabela) devia dar \"\"")


## GATE 1 -- APRESENTAR UMA MECANICA NAO PODE MEXER NA GEOMETRIA DE NINGUEM.
##
## O que aconteceu, para nao voltar a acontecer: a `MECANICA_DO_NIVEL` fazia
## duas coisas ao mesmo tempo. Dizia que mecanica cada nivel APRESENTA e,
## por ser a primeira ocorrencia, decidia a partir de quando cada camara
## fica DISPONIVEL em TODAS as regioes. Dar a` Torre dos Ecos o `elevador`
## no N12 antecipava o desbloqueio de 15 para 11 -- e como o
## `_pool_permitida()` DUPLICA o peso de uma camara nos 8 niveis a seguir ao
## desbloqueio, o nivel 20 deixava de ter o elevador a pesar a dobrar,
## sorteava outra coisa e construia outra geometria. Doze niveis (20, 41-45,
## 51, 56-60) mudaram de forma sem ninguem ter pedido.
##
## Nao era consumo de sorteios -- era o CONTEUDO da pool. Por isso a
## correccao nao e' um `RandomNumberGenerator` a mais: e' separar as duas
## responsabilidades. A apresentacao vive na tabela; o desbloqueio vive no
## `DESBLOQUEIO_BASE` (calendario global, congelado) com antecipacao LOCAL
## por regiao no `DESBLOQUEIO_REGIAO`.
##
## Este teste falha com o comportamento antigo: la', `nivel_de_estreia`
## devolvia a posicao na tabela, portanto o `elevador` daria 11 e nao 15.
func teste_desbloqueio_nao_segue_a_apresentacao() -> void:
	var g := GeradorCorredor
	# calendario HISTORICO (o que o master publica). Congelado a` mao: e' o
	# contrato com as outras 19 regioes.
	var historico := {
		"sinos": 10, "vento": 11, "serras": 12, "gravidade": 13,
		"torre": 14, "elevador": 15, "espectral": 43, "engrenagens": 55,
	}
	for cam: String in historico:
		_ok(g.nivel_de_desbloqueio(cam) == int(historico[cam]),
			"GATE1: `%s` desbloqueia globalmente no %d, devia ser no %d"
			% [cam, g.nivel_de_desbloqueio(cam), historico[cam]])

	# a antecipacao da Regiao III e' LOCAL: mais nenhuma regiao a ve'
	for r in 20:
		if r == 2:
			continue
		for cam: String in ["elevador", "engrenagens", "espectral"]:
			_ok(g.nivel_de_desbloqueio(cam, r) == g.nivel_de_desbloqueio(cam),
				"GATE1: a regiao %d ve' `%s` a desbloquear no %d em vez do"
				% [r + 1, cam, g.nivel_de_desbloqueio(cam, r)]
				+ " calendario global (%d)" % g.nivel_de_desbloqueio(cam))

	# e dentro da Regiao III elas TE'M mesmo de estar disponiveis, senao o
	# canone (elevador no N12, engrenagens no N13, ilusorias no N15) nao
	# chega a acontecer
	for par in [["elevador", 11], ["engrenagens", 12], ["espectral", 14]]:
		var cam: String = par[0]
		var nivel: int = par[1]
		_ok(g.nivel_de_desbloqueio(cam, 2) <= nivel,
			"GATE1: `%s` nao esta' disponivel no nivel %d da Torre dos Ecos"
			% [cam, nivel + 1])

	# a apresentacao E' a posicao na tabela, e e' outra coisa
	_ok(g.nivel_de_apresentacao("elevador") == 11,
		"GATE1: o `elevador` devia APRESENTAR-SE no N12")
	_ok(g.nivel_de_apresentacao("elevador") != g.nivel_de_desbloqueio("elevador"),
		"GATE1: apresentacao e desbloqueio voltaram a ser a mesma coisa")


## Os ids que as cenas de nível usam (Porta.pista_ao_atravessar e
## Coletavel.pista_id) têm de ter texto em DiarioPistas -- senão aparecem
## no diário como "(pista por escrever)".
func teste_diario_tem_todas_as_pistas_dos_niveis() -> void:
	var ids := [
		"floresta_sinal_da_porta", "floresta_carta_rasgada",
		"prisao_carta_na_cela", "prisao_grito_nas_correntes",
		"torres_lanterna_de_zeriko", "torres_sussurro_da_mae",
		"castelo_aurora_livre",
	]
	for id in ids:
		_ok(DiarioPistas.PISTAS.has(id), "falta o texto da pista '%s' em DiarioPistas" % id)


# --- EstadoJogo ------------------------------------------------------

func teste_estado_tres_mortes_sem_vidas() -> void:
	var e := _novo_estado()
	for _i in e.VIDAS_INICIAIS - 1:
		e.perder_vida()
	_ok(not e.sem_vidas(), "com uma vida ainda não se está sem vidas")
	e.perder_vida()
	_ok(e.sem_vidas(), "gastar as VIDAS_INICIAIS deixa sem_vidas() verdadeiro")
	e.free()


## Pedido do Paulo (4 set 2026): cada nível passado dá +1 vida, e recomeçar
## o run repõe as vidas do PONTO onde ele vai, não as 5 do início.
func teste_estado_vida_por_nivel() -> void:
	var e := _novo_estado()
	var antes: int = e.vidas
	e.avancar_nivel()
	_ok(e.vidas == antes + e.VIDAS_POR_NIVEL, "passar de nível devia dar +1 vida")
	_ok(e.vidas_de_partida() == e.VIDAS_INICIAIS + e.VIDAS_POR_NIVEL,
		"vidas_de_partida conta os níveis já concluídos")
	e.free()


## Modo normal: gastar as vidas todas recomeça o nível actual com vidas
## cheias, mas mantém o progresso (níveis feitos, habilidades, pistas).
func teste_estado_reiniciar_run() -> void:
	var e := _novo_estado()
	e.marcar_nivel_concluido(0)          # chefe do nível 1 morto
	e.indice_nivel = 1                   # a jogar o nível 2
	e.desbloquear_habilidade("dash_aereo")
	e.definir_checkpoint(Vector2(500, 200))
	e.perder_vida(); e.perder_vida(); e.perder_vida()
	e.reiniciar_run()
	_ok(e.vidas == e.VIDAS_INICIAIS + e.VIDAS_POR_NIVEL,
		"reiniciar_run repõe as vidas do ponto onde ele vai (1 nível feito)")
	_ok(e.indice_nivel == 1, "reiniciar_run mantém o nível actual (2)")
	_ok(e.checkpoint == Vector2.ZERO, "reiniciar_run recomeça o nível do início")
	_ok(0 in e.concluidos, "reiniciar_run não apaga níveis concluídos")
	_ok(e.tem_habilidade("dash_aereo"), "reiniciar_run não apaga habilidades")
	# defensivo: sem nada concluído, não fica à frente do progresso
	var f := _novo_estado()
	f.indice_nivel = 4
	f.reiniciar_run()
	_ok(f.indice_nivel == 0, "sem chefe morto, reiniciar_run volta ao nível 1")
	e.free()
	f.free()


func teste_estado_pistas_sem_duplicados() -> void:
	var e := _novo_estado()
	e.registar_pista("floresta_sinal_da_porta")
	e.registar_pista("floresta_sinal_da_porta")
	_ok(e.pistas.size() == 1, "registar a mesma pista duas vezes nao devia duplicar")
	e.free()


func teste_estado_habilidade_sem_duplicados() -> void:
	var e := _novo_estado()
	e.desbloquear_habilidade("salto_duplo")
	e.desbloquear_habilidade("salto_duplo")
	_ok(e.habilidades.size() == 1, "desbloquear a mesma habilidade duas vezes nao devia duplicar")
	_ok(e.tem_habilidade("salto_duplo"), "tem_habilidade devia ser verdadeiro apos desbloquear")
	e.free()


func teste_progression_ids_niveis_e_bosses() -> void:
	var e := _novo_estado()
	e.marcar_nivel_concluido(0)
	e.marcar_nivel_concluido(0)
	var save: Dictionary = e.para_dicionario()
	_ok(save.get("current_level_id") == "level_001",
		"nível atual devia persistir pelo ID estável da Execution 2")
	_ok(save.get("completed_level_ids") == ["level_001"],
		"conclusão repetida devia persistir um único level ID")
	_ok(save.get("defeated_boss_ids") == [],
		"concluir L1 com guardião não devia persistir derrota de boss")
	_ok(not save.has("indice_nivel") and not save.has("concluidos"),
		"schema atual não devia persistir referências legacy de nível")
	e.free()


func teste_progression_ids_habilidades_e_coletaveis() -> void:
	var e := _novo_estado()
	e.desbloquear_habilidade("dash_aereo")
	e.desbloquear_habilidade("dash_aereo")
	e.registar_pista("floresta_sinal_da_porta")
	e.registar_pista("floresta_sinal_da_porta")
	var save: Dictionary = e.para_dicionario()
	_ok(save.get("ability_ids", []).count("ability_dash_aereo") == 1,
		"ability unlock repetido devia persistir um único stable ID")
	_ok(save.get("collectible_ids") == ["floresta_sinal_da_porta"],
		"collectible repetido devia persistir uma única identidade do catálogo")
	_ok(not save.has("habilidades") and not save.has("pistas"),
		"schema atual não devia persistir chaves legacy de abilities/collectibles")
	e.free()


func teste_progression_ids_idempotencia_boss_e_recompensa() -> void:
	var e := _novo_estado()
	_ok(e.marcar_chefe_derrotado_por_nivel(4), "primeiro boss defeat devia ser registado")
	_ok(not e.marcar_chefe_derrotado_por_nivel(4), "boss defeat repetido devia ser no-op")
	var reward_id := ProgressionIDs.reward_id_bau_chefe("level_005")
	_ok(e.marcar_recompensa_reclamada(reward_id), "primeira recompensa devia ser registada")
	_ok(not e.marcar_recompensa_reclamada(reward_id), "recompensa repetida devia ser no-op")
	_ok(e.bosses_derrotados == ["boss_level_005"]
		and e.recompensas_reclamadas == [reward_id],
		"boss/reward set-like não deviam conter duplicados")
	var copia := _novo_estado()
	copia.de_dicionario(e.para_dicionario())
	_ok(copia.recompensa_reclamada(reward_id)
		and not copia.marcar_recompensa_reclamada(reward_id),
		"reward ID devia continuar idempotente depois de save/load")
	e.free()
	copia.free()


func teste_progression_ids_invalidos() -> void:
	var e := _novo_estado()
	var invalido: Dictionary = e.para_dicionario()
	invalido["completed_level_ids"] = ["level_999"]
	_ok(SaveFoundation.validar_atual(invalido, e.NIVEIS.size()).get("error")
		== "invalid_progression_id", "level ID atual inválido devia ser rejeitado")
	invalido = e.para_dicionario()
	invalido["defeated_boss_ids"] = ["boss_por_nome_localizado"]
	_ok(SaveFoundation.validar_atual(invalido, e.NIVEIS.size()).get("error")
		== "invalid_progression_id", "boss ID atual inválido devia ser rejeitado")
	invalido = e.para_dicionario()
	invalido["ability_ids"] = ["dash_aereo"]
	_ok(SaveFoundation.validar_atual(invalido, e.NIVEIS.size()).get("error")
		== "invalid_progression_id", "ability key legacy devia ser rejeitada no schema atual")
	invalido = e.para_dicionario()
	invalido["collectible_ids"] = ["nome_do_node"]
	_ok(SaveFoundation.validar_atual(invalido, e.NIVEIS.size()).get("error")
		== "invalid_progression_id", "collectible ID inválido devia ser rejeitado")
	invalido = e.para_dicionario()
	invalido["claimed_reward_ids"] = ["reward_desconhecida"]
	_ok(SaveFoundation.validar_atual(invalido, e.NIVEIS.size()).get("error")
		== "invalid_progression_id", "reward ID inválido devia ser rejeitado")
	invalido = e.para_dicionario()
	invalido["ability_ids"] = ["ability_salto_duplo", "ability_salto_duplo"]
	_ok(SaveFoundation.validar_atual(invalido, e.NIVEIS.size()).get("error")
		== "duplicate_progression_id", "IDs set-like duplicados deviam ser rejeitados")
	invalido = e.para_dicionario()
	invalido["concluidos"] = [0]
	_ok(SaveFoundation.validar_atual(invalido, e.NIVEIS.size()).get("error")
		== "legacy_id_in_current", "campo legacy não migrado devia ser detetado")
	invalido = e.para_dicionario()
	invalido["completed_level_ids"] = ["level_005"]
	_ok(SaveFoundation.validar_atual(invalido, e.NIVEIS.size()).get("error")
		== "incompatible_progression_reference",
		"nível concluído sem boss/reward correspondentes devia ser rejeitado")
	e.free()


func teste_execution_7_combate_e_progressao_regiao1() -> void:
	# 9H.1: o combo passou de 3 para 4 golpes (o 4.º é o remate). Era 3
	# porque só havia arte para um golpe; agora cada passo tem tira própria.
	_ok(Koliani.NUM_COMBO == 4, "Execution 9H.1: combate base devia ter combo de 4 golpes")
	_ok(Koliani.DUR_COMBO.size() == Koliani.NUM_COMBO
		and Koliani.ATAQUE_ATIVO_INICIO.size() == Koliani.NUM_COMBO
		and Koliani.ATAQUE_ATIVO_FIM.size() == Koliani.NUM_COMBO
		and Koliani.AVANCO_VEL.size() == Koliani.NUM_COMBO
		and Koliani.AVANCO_DUR.size() == Koliani.NUM_COMBO
		and Koliani.TOM_COMBO.size() == Koliani.NUM_COMBO
		and Koliani.ARCO_COMBO.size() == Koliani.NUM_COMBO,
		"Execution 7: cada golpe devia ter duração e janela ativa próprias")
	for i in Koliani.NUM_COMBO:
		_ok(Koliani.ATAQUE_ATIVO_INICIO[i] > 0.0
			and Koliani.ATAQUE_ATIVO_INICIO[i] < Koliani.ATAQUE_ATIVO_FIM[i]
			and Koliani.ATAQUE_ATIVO_FIM[i] < 1.0,
			"Execution 7: golpe %d precisa de antecipação, ativo e recovery" % (i + 1))
		_ok(not Koliani.janela_ataque_ativa(i, 0.0)
			and Koliani.janela_ataque_ativa(i, 0.5)
			and not Koliani.janela_ataque_ativa(i, 1.0),
			"Execution 7: hitbox do golpe %d devia respeitar as três fases" % (i + 1))
	_ok(EstadoJogoScript.HABILIDADES_INICIAIS.is_empty(),
		"Execution 7: L1 devia começar apenas com run/jump/attack")
	_ok(ProgressionIDs.ability_id_da_chave_runtime("dash") == "ability_dash",
		"Execution 7: Dash precisava de stable ability ID")
	_ok(ProgressionIDs.ability_id_da_chave_runtime("pogo") == "ability_pogo",
		"Execution 7: pogo tardio precisava de gating persistível")


func teste_execution_7_guardioes_e_boss_regional() -> void:
	_ok(CatalogoCampanha.CHEFE_KEY.slice(0, 4).all(
		func(chave: String) -> bool: return chave.begins_with("guard.")),
		"Execution 7: HUD devia classificar L1-L4 como guardiões")
	_ok(CatalogoCampanha.tem_chefe(4),
		"Execution 7: HUD devia classificar L5 como boss regional")
	var manifesto := ProgressionIDs.carregar_manifesto()
	var entradas_regiao1: Array = manifesto.get("levels", []).slice(0, 5)
	_ok(entradas_regiao1.size() == 5
		and entradas_regiao1[0].get("encounter_role") == "guardian"
		and entradas_regiao1[3].get("encounter_role") == "guardian"
		and entradas_regiao1[4].get("encounter_role") == "regional_boss",
		"Execution 7: manifesto devia distinguir guardiões do boss regional")
	var caminhos := [
		"res://scenes/levels/Floresta_Putrefata.tscn",
		"res://scenes/levels/Pantano_dos_Sussurros.tscn",
		"res://scenes/levels/Ninho_da_Viuva_Negra.tscn",
		"res://scenes/levels/A_Arvore_que_Chora.tscn",
	]
	for caminho in caminhos:
		var cena: PackedScene = load(caminho)
		var nivel := cena.instantiate() if cena else null
		_ok(nivel != null and nivel.get_node_or_null("Guardiao") != null
			and nivel.get_node_or_null("Chefe") == null,
			"Execution 7: %s devia terminar em Guardiao" % caminho.get_file())
		if nivel:
			nivel.free()
	var l5: PackedScene = load("res://scenes/levels/Coracao_da_Floresta.tscn")
	var exame := l5.instantiate() if l5 else null
	_ok(exame != null and exame.get_node_or_null("Chefe") != null,
		"Execution 7: L5 devia manter o boss regional")
	_ok(exame != null and exame.get_node("ColBatida").habilidade_id == "dash",
		"Execution 7: L5 devia desbloquear Dash")
	if exame:
		exame.free()
	_ok(ChefeCoracaoPutrefacto.fase_por_vida(51, 100) == 1
		and ChefeCoracaoPutrefacto.fase_por_vida(50, 100) == 2,
		"Execution 7: Coração Putrefacto devia transitar de fase a 50%")
	var estado := _novo_estado()
	_ok(not estado.nivel_e_exame_regional(0) and not estado.nivel_e_exame_regional(3)
		and estado.nivel_e_exame_regional(4),
		"Execution 7: só o quinto nível devia ser exame regional")
	estado.marcar_nivel_concluido(0)
	_ok(estado.bosses_derrotados.is_empty() and estado.recompensas_reclamadas.is_empty(),
		"Execution 7: guardião não devia criar reward/boss state")
	estado.marcar_nivel_concluido(4)
	_ok(estado.bosses_derrotados == ["boss_level_005"]
		and estado.recompensas_reclamadas == ["reward_boss_chest_level_005"],
		"Execution 7: boss/reward de L5 deviam manter IDs estáveis")
	estado.free()


func teste_execution_8_integracao_player_facing() -> void:
	var caminhos := [
		"res://scenes/levels/Floresta_Putrefata.tscn",
		"res://scenes/levels/Pantano_dos_Sussurros.tscn",
		"res://scenes/levels/Ninho_da_Viuva_Negra.tscn",
		"res://scenes/levels/A_Arvore_que_Chora.tscn",
		"res://scenes/levels/Coracao_da_Floresta.tscn",
	]
	for i in caminhos.size():
		var cena := load(caminhos[i]) as PackedScene
		var nivel := cena.instantiate() if cena else null
		_ok(nivel != null, "Execution 8: L%d não carregou" % (i + 1))
		if nivel == null:
			continue
		var koliani := nivel.get_node_or_null("Koliani")
		# Execution 9B.3: o Golden Set aprovado substitui a 5G; o premium_v1 fica
		# só como fallback dos estados ainda sem arte de produção.
		_ok(koliani != null and bool(koliani.get("usar_golden_set"))
			and bool(koliani.get("usar_prototipo_premium"))
			and not bool(koliani.get("usar_piloto_visual_5g")),
			"Execution 9B.3: Golden Set não ativo em L%d" % (i + 1))
		var visual := nivel.get_node_or_null("Region1HybridVisualTarget")
		_ok(visual != null and bool(visual.get("ativo")),
			"Execution 8: panorama aprovado não ativo em L%d" % (i + 1))
		# Execution 9C: os cinco níveis montam o kit inteiro, cada um com a sua
		# variante de cenário da prancha 08.
		_ok(visual != null and not bool(visual.get("apenas_panorama_aprovado"))
			and int(visual.get("perfil")) == i + 1,
			"Execution 9C: L%d devia montar o kit com perfil %d" % [i + 1, i + 1])
		nivel.free()

	var menu := FileAccess.get_file_as_string("res://scripts/menu_inicial.gd")
	var main := FileAccess.get_file_as_string("res://scripts/main.gd")
	var dev := FileAccess.get_file_as_string("res://scripts/dev_barra.gd")
	# 9H: o menu foi refeito sobre a prancha aprovada e monta-se em código --
	# a defesa é a mesma, o nome da variável é que deixou de existir.
	# 9H.17 D: a defesa continua a ser a mesma -- em release as entradas de
	# developer mode estão fechadas -- mas deixou de ser escrita três vezes.
	# Havia três `OS.is_debug_build()` independentes (menu, barra Dev, atalhos
	# F1-F9) e isso teve duas consequências: o Game Master não encontrava o
	# modo Dev numa build de QA exportada em release, e quem o forçasse por
	# `--devmode` entrava SEM barra, ou seja sem FlyMode nem troca de nível.
	# Agora há um portão só, `EstadoJogo.entrada_dev_disponivel()`, e o que o
	# abre em release é um interruptor explícito que o export público desliga.
	var estado_src := FileAccess.get_file_as_string("res://scripts/estado_jogo.gd")
	_ok(estado_src.contains("static func entrada_dev_disponivel() -> bool:")
		and estado_src.contains("ProjectSettings.get_setting(\"koliani/qa/entrada_dev\", false)")
		and estado_src.contains("if OS.is_debug_build():"),
		"Execution 8: o portão do developer mode deixou de fechar por omissão em release")
	_ok(menu.contains("_dev.visible = EstadoJogo.entrada_dev_disponivel()")
		and menu.contains("--devmode\" and EstadoJogo.entrada_dev_disponivel()"),
		"Execution 8: menu release não fecha as entradas de developer mode")
	_ok(main.contains("EstadoJogo.modo_dev and EstadoJogo.entrada_dev_disponivel()")
		and main.contains("if not EstadoJogo.entrada_dev_disponivel():")
		and dev.contains("not EstadoJogo.entrada_dev_disponivel() or not EstadoJogo.modo_dev"),
		"Execution 8: DevBarra não tem defesa release em profundidade")


## Execution 9B.4: na Região I todos os estados da Koliani saem do Golden Set.
## Monta a Koliani do L1 a sério (o `_ready` constrói o SpriteFrames) e exige
## que TODAS as animações e TODOS os frames venham de `koliani_golden_set`.
## Execution 9C: na Região I o terreno sai do kit de produção (pranchas 08/10),
## não do terreno CC0; sem o nó do kit, a mesma plataforma volta ao legado
## (os outros 95 níveis também usam o bioma "floresta").
func teste_execution_9c_kit_ambiente_regiao1() -> void:
	var nivel := (load("res://scenes/levels/Floresta_Putrefata.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(nivel)
	var chao := nivel.get_node_or_null("ChaoInicio")
	var caminhos: Array[String] = []
	if chao:
		for f in chao.get_node("Visual").get_children():
			if f is Sprite2D and f.texture and f.texture.resource_path != "":
				caminhos.append(f.texture.resource_path)
	# 9H.17 CONTINUATION: o que esta asserção defende é que a Região I usa
	# arte de PRODUÇÃO e não o terreno pixel CC0 dos outros 95 níveis. O
	# caminho da produção mudou -- desde a 9H.17 I3 o corpo da plataforma sai
	# de `l1_hybrid_9h12e/terrain_hd/`, não do `kit_9c/` -- e o teste ficou a
	# medir um caminho que já ninguém escreve: acusava o L1 de ter voltado ao
	# legado precisamente enquanto ele passava a ter a melhor arte do jogo.
	# Os dentes da asserção continuam os mesmos: >= 4 peças de produção e
	# ZERO peças do terreno legado.
	var do_kit := caminhos.filter(func(c: String) -> bool:
		return c.contains("/kit_9c/") or c.contains("/l1_hybrid_9h12e/"))
	var legado := caminhos.filter(func(c: String) -> bool: return c.contains("pixel/terreno"))
	_ok(do_kit.size() >= 4 and legado.is_empty(),
		"Execution 9C: L1 não usa o terreno de produção (%s)" % str(caminhos))
	# O mesmo para a profundidade: o L1 deixou de montar as camadas da 08 --
	# monta as do passe Hybrid. O contrato é HAVER céu, plano médio e mata
	# separados por parallax, não como se chamam os nós.
	var alvo := nivel.get_node_or_null("Region1HybridVisualTarget")
	var legado_08 := alvo != null and alvo.get_node_or_null("Camada3Distante") != null \
		and alvo.get_node_or_null("Camada2Floresta") != null \
		and alvo.get_node_or_null("BackgroundApproved08") != null
	var hybrid := alvo != null and alvo.get_node_or_null("HybridL1_ceu") != null \
		and alvo.get_node_or_null("HybridL1_serra") != null \
		and alvo.get_node_or_null("HybridL1_mata") != null
	_ok(legado_08 or hybrid,
		"Execution 9C: faltam camadas de parallax no L1")
	nivel.free()

	var solta := (load("res://scenes/actors/Plataforma.tscn") as PackedScene).instantiate()
	solta.tamanho = Vector2(300, 40)
	get_tree().root.add_child(solta)
	var usa_legado := false
	for f in solta.get_node("Visual").get_children():
		if f is Sprite2D and f.texture and f.texture.resource_path.contains("pixel/terreno"):
			usa_legado = true
	_ok(usa_legado, "Execution 9C: fora da Região I a plataforma devia manter o terreno legado")
	solta.free()

	# As peças do kit estão todas no manifesto, com o SHA certo.
	var man: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/art/regions/region_01_forest/production/kit_9c/kit_9c_manifest.json"))
	_ok(man is Dictionary and (man["ativos"] as Array).size() >= 30,
		"Execution 9C: manifesto do kit em falta ou incompleto")


## Execution 9D: o manifesto de produção dos inimigos cobre TODOS os inimigos
## e guardiões de L1–L4 (o chefe do L5 é da 9E), e cada inimigo carrega a arte
## que o manifesto declara: produção se estiver PRODUCTION_INTEGRATED, legado
## caso contrário. Um inimigo integrado com um frame de fora da pasta de
## produção falha aqui -- é a guarda contra arte legada visível na Região I.
func teste_execution_9d_inimigos_regiao1() -> void:
	const Ini := preload("res://scripts/regiao1_inimigos.gd")
	var man: Dictionary = Ini.manifesto()
	var entradas: Dictionary = man.get("inimigos", {})
	_ok(not entradas.is_empty(), "9D: manifesto de produção dos inimigos em falta")
	for cam in ["res://scenes/levels/Floresta_Putrefata.tscn", "res://scenes/levels/Pantano_dos_Sussurros.tscn",
			"res://scenes/levels/Ninho_da_Viuva_Negra.tscn", "res://scenes/levels/A_Arvore_que_Chora.tscn",
			"res://scenes/levels/Coracao_da_Floresta.tscn"]:
		var nivel := (load(cam) as PackedScene).instantiate()
		get_tree().root.add_child(nivel)
		for no in nivel.get_children():
			if not (no is DemonioBase):
				continue
			var id: String = no.get("rig") if no.is_in_group("chefes") else no.get("especie")
			if id == "":
				continue
			_ok(entradas.has(id), "9D: %s/%s ('%s') fora do manifesto" % [cam.get_file(), no.name, id])
			var integrado: bool = entradas.get(id, {}).get("status", "") == Ini.INTEGRADO
			var anim := no.get_node_or_null("Sprite/Anim") as AnimatedSprite2D
			if anim == null or anim.sprite_frames == null:
				continue
			for a in anim.sprite_frames.get_animation_names():
				for i in anim.sprite_frames.get_frame_count(a):
					var t := anim.sprite_frames.get_frame_texture(a, i)
					var p := t.resource_path if t else ""
					if t is AtlasTexture:
						p = (t as AtlasTexture).atlas.resource_path
					_ok(Ini.e_producao(p) == integrado,
						"9D: %s/%s anim '%s' carrega %s (integrado=%s)" % [cam.get_file(), no.name, a, p, integrado])
		nivel.free()
	# Cada frame de uma entrada integrada existe e tem o SHA do manifesto --
	# um PNG trocado à mão (ou regerado sem atualizar o manifesto) falha aqui.
	for id: String in entradas:
		var e: Dictionary = entradas[id]
		if e.get("status", "") != Ini.INTEGRADO:
			continue
		for a: String in e.get("animacoes", {}):
			for f: Dictionary in e["animacoes"][a]["frames"]:
				var cam_f := Ini.caminho(String(f["ficheiro"]))
				var sha := FileAccess.get_sha256(cam_f)
				_ok(sha == String(f["sha256"]), "9D+9E: %s/%s SHA diferente do manifesto (%s)" % [id, a, cam_f])


## Execution 9D+9E: os clones da Morvanna e as crias da Rainha Aracnídea
## vestem a arte de produção DELES (identidade_visual), nunca a do goblin --
## que era a espécie por omissão e continua a ser, para o jogo não mudar.
func teste_9d9e_crias_sem_goblin() -> void:
	const Ini := preload("res://scripts/regiao1_inimigos.gd")
	for caso in [["res://scenes/levels/Pantano_dos_Sussurros.tscn", "clone_morvanna"],
			["res://scenes/levels/Ninho_da_Viuva_Negra.tscn", "cria_rainha"]]:
		var nivel := (load(caso[0]) as PackedScene).instantiate()
		get_tree().root.add_child(nivel)
		var chefe: Node = null
		for no in nivel.get_children():
			if no is ChefeMorvanna or no is ChefeRainhaAracnidea:
				chefe = no
		_ok(chefe != null, "9D+9E: chefe de %s não encontrado" % caso[0].get_file())
		if chefe == null:
			nivel.free()
			continue
		var antes := nivel.get_child_count()
		if chefe is ChefeMorvanna:
			chefe.call("_largar_clones")
		else:
			chefe.call("_ovo_em", chefe.global_position.x - 60.0, 0.4)
			for t in get_tree().get_processed_tweens():
				t.custom_step(5.0)  # o ovo eclode já
		var crias := 0
		for i in range(antes, nivel.get_child_count()):
			var c := nivel.get_child(i)
			if not (c is DemonioBase):
				continue
			crias += 1
			_ok(c.identidade_visual == caso[1], "9D+9E: cria sem identidade '%s'" % caso[1])
			_ok(c.especie == "goblin", "9D+9E: a espécie (jogo) da cria mudou -- só a arte devia mudar")
			var sf: SpriteFrames = (c.get_node("Sprite/Anim") as AnimatedSprite2D).sprite_frames
			for a in ["idle", "run", "hit", "dead"]:
				_ok(sf.has_animation(a), "9D+9E: %s sem '%s'" % [caso[1], a])
				var p := sf.get_frame_texture(a, 0).resource_path if sf.has_animation(a) else ""
				_ok(p.begins_with("%s/%s/" % [Ini.DIR, caso[1]]),
					"9D+9E: %s anim '%s' carrega %s (devia ser produção, nunca goblin)" % [caso[1], a, p])
		_ok(crias > 0, "9D+9E: %s não largou crias no teste" % caso[1])
		nivel.free()


## Execution 9E.2: o Coração Putrefacto do L5 desenha SÓ arte de produção (nem
## um frame do rig legado `bosses_anim/coracao_putrefacto`, folha estática
## escondida), e a fase 2 -- decidida pelo limiar de vida do jogo -- troca a
## forma contida pela intensificada.
func teste_9e2_coracao_producao_e_fases() -> void:
	const Ini := preload("res://scripts/regiao1_inimigos.gd")
	var nivel := (load("res://scenes/levels/Coracao_da_Floresta.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(nivel)
	var c := nivel.get_node_or_null("Chefe")
	_ok(c is ChefeCoracaoPutrefacto, "9E.2: Coração não encontrado no L5")
	if not (c is ChefeCoracaoPutrefacto):
		nivel.free()
		return
	var anim := c.get_node("Sprite/Anim") as AnimatedSprite2D
	var sf := anim.sprite_frames
	for a in ["idle", "hit", "idle_f2", "hit_f2", "dead"]:
		_ok(sf != null and sf.has_animation(a) and sf.get_frame_count(a) > 0, "9E.2: Coração sem '%s'" % a)
		if sf == null or not sf.has_animation(a):
			continue
		for i in sf.get_frame_count(a):
			var p := sf.get_frame_texture(a, i).resource_path
			_ok(Ini.e_producao(p) and p.contains("/bosses/coracao_putrefacto/production/"),
				"9E.2: Coração '%s' carrega %s (devia ser produção)" % [a, p])
			_ok(not p.contains("bosses_anim/coracao_putrefacto"), "9E.2: frame legado no Coração: %s" % p)
	var corpo := c.get_node_or_null("Sprite/Corpo") as CanvasItem
	_ok(corpo == null or not corpo.visible, "9E.2: folha legada do Coração visível")
	c.call("_atualizar_anim")
	_ok(anim.animation == "idle", "9E.2: fase 1 devia mostrar 'idle', mostra '%s'" % anim.animation)
	c.set("vida", int(c.get("_vida_max")) / 2 - 1)
	c.call("_atualiza_fase")
	c.call("_atualizar_anim")
	_ok(anim.animation == "idle_f2", "9E.2: fase 2 devia mostrar 'idle_f2', mostra '%s'" % anim.animation)
	var t2 := sf.get_frame_texture(anim.animation, 0).resource_path if sf.has_animation(anim.animation) else ""
	_ok(t2.contains("/phase_2/"), "9E.2: fase 2 com arte fora de phase_2: %s" % t2)
	_ok(c.get_node_or_null("Erupcao9E2") != null, "9E.2: sem erupção na transição de fase")
	nivel.free()


func teste_execution_9b4_pacote_golden_sem_legado() -> void:
	var cena := load("res://scenes/levels/Floresta_Putrefata.tscn") as PackedScene
	var nivel := cena.instantiate()
	var k := nivel.get_node_or_null("Koliani")
	_ok(k != null, "9B.4: Koliani não encontrada no L1")
	if k == null:
		nivel.free()
		return
	nivel.remove_child(k)
	nivel.free()
	add_child(k)
	var corpo := k.get("_corpo") as AnimatedSprite2D
	var sf := corpo.sprite_frames if corpo else null
	_ok(sf != null, "9B.4: SpriteFrames da Koliani não montado")
	if sf:
		for estado in ["idle", "run", "turn", "run_start", "run_brake", "jump", "jump_start",
				"jump_loop", "fall", "land", "aterrar", "attack", "attack2", "attack3", "attack4",
				"lancar", "dash", "roll", "hurt", "morte", "crouch", "wallslide", "borda",
				"djump", "defesa"]:
			_ok(sf.has_animation(estado) and sf.get_frame_count(estado) > 0,
				"9B.4: estado '%s' sem frames golden" % estado)
		var fora: Array[String] = []
		for anim in sf.get_animation_names():
			for i in sf.get_frame_count(anim):
				var tex := sf.get_frame_texture(anim, i)
				var p := tex.resource_path if tex else ""
				if not p.begins_with("res://assets/sprites/koliani_golden_set/"):
					fora.append("%s[%d]=%s" % [anim, i, p])
		_ok(fora.is_empty(), "9B.4: frames fora do Golden Set: %s" % str(fora))
	_ok(corpo != null and corpo.scale == Vector2.ONE and corpo.offset == Vector2(0.0, -18.0),
		"9B.4: contrato visual golden (escala 1, offset -18) não aplicado")
	k.free()


func teste_progression_ids_resilientes_a_renames() -> void:
	var antes := {
		"levels": [{"level_id": "level_001", "runtime_scene": "res://Antigo.tscn",
			"display_name": "Nome Antigo", "boss_ref": {"boss_id": "boss_level_001",
			"scene": "res://ChefeAntigo.tscn"}}]}
	var depois := antes.duplicate(true)
	depois["levels"][0]["runtime_scene"] = "res://Pasta/Novo.tscn"
	depois["levels"][0]["display_name"] = "Novo nome localizado"
	depois["levels"][0]["boss_ref"]["scene"] = "res://ChefeRenomeado.tscn"
	var ids_antes := ProgressionIDs.identidades_do_manifesto(antes)
	var ids_depois := ProgressionIDs.identidades_do_manifesto(depois)
	_ok(ids_antes == ids_depois,
		"renomear display/filename externo não devia alterar level/boss IDs persistentes")


func teste_estado_nivel_atual_e_caminho_valido() -> void:
	var e := _novo_estado()
	var caminho: String = e.caminho_nivel_atual()
	_ok(caminho.begins_with("res://"), "caminho do nivel atual devia comecar por res://")
	_ok(not e.anunciar_avanco, "arranque limpo nao anuncia avanco de nivel")
	e.avancar_nivel()  # so avanca se houver proximo; nao pode ir fora dos limites
	_ok(e.indice_nivel == 1, "avancar_nivel do nivel 1 leva ao nivel 2")
	_ok(e.anunciar_avanco, "avancar_nivel arma o banner 'Avancou para o Nivel N'")
	e.free()


func teste_estado_save_ida_e_volta() -> void:
	var e := _novo_estado()
	e.perder_vida()
	e.registar_pista("floresta_sinal_da_porta")
	e.desbloquear_habilidade("dash_aereo")
	e.marcar_nivel_concluido(0)
	var copia := _novo_estado()
	copia.de_dicionario(e.para_dicionario())
	_ok(copia.vidas == e.vidas, "vidas deviam sobreviver ao ida-e-volta do dicionario")
	_ok(copia.pistas == e.pistas, "pistas deviam sobreviver ao ida-e-volta do dicionario")
	_ok(copia.habilidades == e.habilidades, "habilidades deviam sobreviver ao ida-e-volta")
	_ok(copia.concluidos == e.concluidos, "niveis concluidos deviam sobreviver ao ida-e-volta")
	_ok(copia.nivel_esta_concluido(0), "o nivel 0 concluido devia continuar concluido apos o save")
	e.free()
	copia.free()


func teste_save_fresh_write_load() -> void:
	var base := "res://work/teste_save_foundation_fresh.json"
	_limpar_save_teste(base)
	var original := _novo_estado()
	original.vidas = 4
	original.essencia = 17
	_ok(original.guardar_em(base, base + ".bak", base + ".tmp"),
		"fresh save devia ser escrito e verificado")
	_ok(SaveFoundation.ler(base + ".bak", original.NIVEIS.size()).get("ok", false),
		"fresh save devia criar logo um backup valido")
	var copia := _novo_estado()
	_ok(copia.carregar_de(base, base + ".bak"), "fresh save devia carregar")
	_ok(copia.vidas == 4 and copia.essencia == 17,
		"fresh save devia preservar os dados no load")
	_ok(copia.ultima_origem_save == "primary", "fresh save devia vir do primary")
	original.free()
	copia.free()
	_limpar_save_teste(base)


func teste_save_roundtrip_campos() -> void:
	var base := "res://work/teste_save_foundation_roundtrip.json"
	_limpar_save_teste(base)
	var original := _novo_estado()
	original.indice_nivel = 3
	original.iniciar_sessao_nivel(true)
	original.ativar_checkpoint("checkpoint_level_004_02", Vector2(123.5, -42.0))
	original.habilidades.assign(["salto_duplo", "dash_aereo"])
	original.pistas.assign(["castelo_aurora_livre"])
	for indice in [0, 1, 2]:
		original.marcar_nivel_concluido(indice)
	original.armas.assign(["shadowblade"])
	original.arma_equipada = "shadowblade"
	original.essencia = 29
	original.melhorias = {"furia": 2}
	_ok(original.guardar_em(base, base + ".bak", base + ".tmp"),
		"roundtrip devia gravar estado valido")
	var copia := _novo_estado()
	_ok(copia.carregar_de(base, base + ".bak"), "roundtrip devia carregar")
	_ok(copia.indice_nivel == original.indice_nivel
		and copia.level_session == original.level_session
		and copia.habilidades == original.habilidades
		and copia.pistas == original.pistas
		and copia.concluidos == original.concluidos
		and copia.armas == original.armas
		and copia.arma_equipada == original.arma_equipada
		and copia.essencia == original.essencia
		and copia.melhorias == original.melhorias,
		"roundtrip devia preservar campanha/equipment/economy/abilities")
	original.free()
	copia.free()
	_limpar_save_teste(base)


func teste_save_legacy_migration() -> void:
	var e := _novo_estado()
	e.essencia = 41
	var legacy: Dictionary = _save_v2_do_estado(e)
	legacy.erase("save_version")
	legacy.erase("save_kind")
	var resultado := SaveFoundation.processar(legacy, e.NIVEIS.size())
	_ok(resultado.get("ok", false), "save legacy reconhecido devia migrar")
	var atual: Dictionary = resultado.get("data", {})
	_ok(atual.get("save_version") == SaveFoundation.CURRENT_SAVE_VERSION,
		"legacy migrado devia ficar na versao atual")
	_ok(atual.get("essencia") == 41,
		"migration legacy devia preservar progresso permanente")
	_ok(not atual.has("hardcore") and not atual.has("hardcore_tempo_restante"),
		"migration legacy não devia reativar Hardcore no schema atual")
	var arbitrario := SaveFoundation.processar({"foo": "bar"}, e.NIVEIS.size())
	_ok(arbitrario.get("error") == "invalid_legacy",
		"JSON arbitrario sem versao nao devia ser assumido como legacy")
	e.free()


func teste_save_migration_sequencial() -> void:
	var e := _novo_estado()
	var legacy: Dictionary = _save_v2_do_estado(e)
	legacy.erase("save_version")
	legacy.erase("save_kind")
	var resultado := SaveFoundation.processar(legacy, e.NIVEIS.size())
	_ok(resultado.get("migrations", []) == [0, 1, 2, 3, 4, 5],
		"pipeline legacy devia percorrer 0 -> 1 -> 2 -> 3 -> 4 -> 5 sem atalhos")
	e.free()


func teste_save_v2_migration_progressao() -> void:
	var e := _novo_estado()
	e.indice_nivel = 4
	e.habilidades.assign(["salto_duplo", "dash_aereo"])
	e.pistas.assign(["floresta_sinal_da_porta"])
	e.concluidos.assign([0, 4, 4])
	var resultado := SaveFoundation.processar(_save_v2_do_estado(e), e.NIVEIS.size())
	_ok(resultado.get("ok", false), "save v2 válido devia migrar para stable IDs")
	_ok(resultado.get("migrations", []) == [2, 3, 4, 5],
		"migration v2 devia passar sequencialmente por v3, v4 e v5")
	var atual: Dictionary = resultado.get("data", {})
	_ok(atual.get("current_level_id") == "level_005",
		"migration devia converter indice_nivel para level ID")
	_ok(atual.get("completed_level_ids") == ["level_001", "level_005"],
		"migration devia preservar conclusões e remover duplicados")
	_ok(atual.get("defeated_boss_ids") == ["boss_level_001", "boss_level_005"],
		"migration devia derivar boss IDs explícitos das conclusões v2")
	_ok(atual.get("claimed_reward_ids") == [
		"reward_boss_chest_level_001", "reward_boss_chest_level_005"],
		"níveis v2 concluídos deviam conservar a recompensa já reclamada")
	_ok(atual.get("ability_ids") == ["ability_salto_duplo", "ability_dash_aereo"],
		"migration devia converter abilities legacy sem mudar unlocks")
	_ok(atual.get("collectible_ids") == ["floresta_sinal_da_porta"],
		"migration devia preservar collectible IDs conhecidos")
	_ok(not atual.has("indice_nivel") and not atual.has("concluidos")
		and not atual.has("habilidades") and not atual.has("pistas"),
		"migration não devia deixar referências legacy no schema atual")
	e.free()


func teste_save_primary_corrupto_backup_valido() -> void:
	var base := "res://work/teste_save_foundation_recovery.json"
	_limpar_save_teste(base)
	var e := _novo_estado()
	e.essencia = 11
	_ok(e.guardar_em(base, base + ".bak", base + ".tmp"), "primeiro save devia passar")
	e.essencia = 22
	_ok(e.guardar_em(base, base + ".bak", base + ".tmp"),
		"segundo save devia criar backup do primeiro")
	_escrever_save_teste(base, "{corrompido")
	var copia := _novo_estado()
	_ok(copia.carregar_de(base, base + ".bak"),
		"primary corrupto devia recuperar pelo backup")
	_ok(copia.essencia == 11 and copia.ultima_origem_save == "backup",
		"recovery devia aplicar o ultimo primary anteriormente validado")
	e.free()
	copia.free()
	_limpar_save_teste(base)


func teste_save_escrita_nova_invalida_preserva_anterior() -> void:
	var base := "res://work/teste_save_foundation_invalid_write.json"
	_limpar_save_teste(base)
	var e := _novo_estado()
	e.essencia = 7
	_ok(e.guardar_em(base, base + ".bak", base + ".tmp"), "save base devia passar")
	var antes := FileAccess.get_file_as_string(base)
	var invalido: Dictionary = e.para_dicionario()
	invalido["vidas"] = -5
	var resultado := SaveFoundation.escrever_seguro(
		invalido, base, base + ".bak", base + ".tmp", e.NIVEIS.size())
	_ok(not resultado.get("ok", false), "nova escrita estruturalmente invalida devia falhar")
	_ok(FileAccess.get_file_as_string(base) == antes,
		"escrita invalida nao devia alterar o primary valido")
	_ok(SaveFoundation.ler(base, e.NIVEIS.size()).get("ok", false),
		"primary anterior devia continuar recuperavel")
	e.free()
	_limpar_save_teste(base)


func teste_save_temp_invalido_nao_promovido() -> void:
	var base := "res://work/teste_save_foundation_invalid_temp.json"
	_limpar_save_teste(base)
	var e := _novo_estado()
	e.essencia = 13
	_ok(e.guardar_em(base, base + ".bak", base + ".tmp"), "save base devia passar")
	var antes := FileAccess.get_file_as_string(base)
	_escrever_save_teste(base + ".tmp", "{temp incompleto")
	var resultado := SaveFoundation.promover_temp_validado(
		base, base + ".bak", base + ".tmp", e.NIVEIS.size())
	_ok(resultado.get("error") == "invalid_temp", "TEMP invalido devia ser rejeitado")
	_ok(FileAccess.get_file_as_string(base) == antes,
		"TEMP invalido nunca devia substituir o primary")
	e.free()
	_limpar_save_teste(base)


func teste_save_versao_futura_preservada() -> void:
	var base := "res://work/teste_save_foundation_future.json"
	_limpar_save_teste(base)
	var e := _novo_estado()
	var futuro: Dictionary = e.para_dicionario()
	futuro["save_version"] = SaveFoundation.CURRENT_SAVE_VERSION + 1
	var texto_futuro := JSON.stringify(futuro, "\t")
	_escrever_save_teste(base, texto_futuro)
	var leitura := SaveFoundation.ler(base, e.NIVEIS.size())
	_ok(leitura.get("error") == "future_version", "versao futura devia ser rejeitada")
	var resultado := SaveFoundation.escrever_seguro(
		e.para_dicionario(), base, base + ".bak", base + ".tmp", e.NIVEIS.size())
	_ok(resultado.get("error") == "future_version",
		"safe write nao devia substituir primary de versao futura")
	_ok(FileAccess.get_file_as_string(base) == texto_futuro,
		"save futuro devia permanecer byte a byte intacto")
	e.free()
	_limpar_save_teste(base)


func teste_save_migration_invalida_rejeitada() -> void:
	var base := "res://work/teste_save_foundation_invalid_migration.json"
	_limpar_save_teste(base)
	var e := _novo_estado()
	_ok(e.guardar_em(base, base + ".bak", base + ".tmp"),
		"save anterior da migration invalida devia ser valido")
	var antes := FileAccess.get_file_as_string(base)
	var v1: Dictionary = _save_v2_do_estado(e)
	v1["save_version"] = 1
	v1["save_kind"] = "estrutura_incompativel"
	var resultado := SaveFoundation.processar(v1, e.NIVEIS.size())
	_ok(resultado.get("error") == "invalid_migration",
		"migration que produz schema atual incompativel devia ser rejeitada")
	var escrita := SaveFoundation.escrever_seguro(
		v1, base, base + ".bak", base + ".tmp", e.NIVEIS.size())
	_ok(escrita.get("error") == "invalid_migration",
		"migration invalida nao devia entrar no safe write")
	_ok(FileAccess.get_file_as_string(base) == antes,
		"migration invalida devia preservar o primary valido anterior")
	e.free()
	_limpar_save_teste(base)


func _escrever_save_teste(caminho: String, texto: String) -> void:
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	_ok(f != null, "teste nao conseguiu escrever %s" % caminho)
	if f:
		f.store_string(texto)
		f.flush()
		f.close()


func _save_v2_do_estado(e: Node) -> Dictionary:
	return {
		"save_version": 2,
		"save_kind": SaveFoundation.SAVE_KIND,
		"vidas": e.vidas,
		"indice_nivel": e.indice_nivel,
		"checkpoint": [e.checkpoint.x, e.checkpoint.y],
		"habilidades": e.habilidades.duplicate(),
		"pistas": e.pistas.duplicate(),
		"concluidos": e.concluidos.duplicate(),
		"armas": e.armas.duplicate(),
		"armaduras": e.armaduras.duplicate(),
		"arma_equipada": e.arma_equipada,
		"armadura_equipada": e.armadura_equipada,
		"hardcore": false,
		"hardcore_tempo_restante": -1.0,
		"essencia": e.essencia,
		"melhorias": e.melhorias.duplicate(),
	}


func _limpar_save_teste(base: String) -> void:
	for sufixo: String in ["", ".bak", ".tmp", ".bak.tmp", ".tmp.restore"]:
		var caminho: String = base + sufixo
		if FileAccess.file_exists(caminho):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))


## O menu inicial usa isto para decidir se mostra "Continuar". Um arranque
## limpo (campanha reiniciada) não conta como progresso; desbloquear uma
## habilidade ou avançar de mundo já conta.
func teste_estado_ha_progresso() -> void:
	var e := _novo_estado()  # reiniciar_campanha() já gravou um save limpo
	_ok(not e.ha_progresso(), "arranque limpo não devia contar como progresso")
	e.desbloquear_habilidade("dash_aereo")  # o salto duplo é inicial, não conta
	_ok(e.ha_progresso(), "com uma habilidade desbloqueada já há progresso")
	e.reiniciar_campanha()
	_ok(not e.ha_progresso(), "reiniciar a campanha volta a 'sem progresso'")
	e.free()


## Regiões: cada nível da campanha pertence a uma região; concluir todos os
## níveis de uma região marca-a como concluída; `reiniciar_campanha()` limpa
## e `avancar_nivel()` vai marcando o nível de onde se sai.
func teste_estado_regioes_e_conclusao() -> void:
	var e := _novo_estado()
	# A campanha cresce (6 regiões nos níveis 1-30, 20 no plano dos 31-100),
	# por isso o teste não fixa o NÚMERO: o que tem de valer sempre é que as
	# regiões cubram todos os níveis, uma vez cada.
	_ok(e.REGIOES.size() >= 6, "a campanha tem pelo menos as 6 regiões de docs/niveis.md")
	var vistos := {}
	for r in e.REGIOES.size():
		for i: int in e.REGIOES[r]["niveis"]:
			_ok(not vistos.has(i),
				"o nível %d está em duas regiões (%s e %d)" % [i, str(vistos.get(i, -1)), r])
			vistos[i] = r
	for i in e.NIVEIS.size():
		_ok(e.regiao_do_nivel(i) >= 0, "o nível %d devia pertencer a uma região" % i)
	_ok(vistos.size() == e.NIVEIS.size(),
		"as regiões cobrem %d níveis mas NIVEIS tem %d" % [vistos.size(), e.NIVEIS.size()])

	_ok(not e.nivel_esta_concluido(0), "arranque limpo: nada concluído")
	_ok(not e.regiao_esta_concluida(0), "arranque limpo: nenhuma região concluída")

	var r0: int = e.regiao_do_nivel(0)
	var niveis_r0: Array = e.REGIOES[r0]["niveis"]
	e.marcar_nivel_concluido(0)
	e.marcar_nivel_concluido(0)  # idempotente
	_ok(e.concluidos.size() == 1, "marcar o mesmo nível duas vezes não duplica")
	_ok(e.nivel_esta_concluido(0), "o nível 0 ficou concluído")
	if niveis_r0.size() > 1:
		_ok(not e.regiao_esta_concluida(r0), "região com vários níveis não fecha só com o primeiro")
	# concluir todos os níveis da região fecha-a
	for idx in niveis_r0:
		e.marcar_nivel_concluido(idx)
	_ok(e.regiao_esta_concluida(r0), "concluir todos os níveis da região marca-a como concluída")

	# uma região sem níveis definidos nunca conta como concluída. Quando a
	# campanha já está toda distribuída (nenhuma região vazia) esta parte
	# não se aplica -- só se verifica se ainda houver alguma por construir.
	var vazia := -1
	for r in e.REGIOES.size():
		if (e.REGIOES[r]["niveis"] as Array).is_empty():
			vazia = r
			break
	if vazia >= 0:
		_ok(not e.regiao_esta_concluida(vazia), "região sem níveis não está concluída")

	# avancar_nivel marca o nível de partida
	e.reiniciar_campanha()
	_ok(e.concluidos.is_empty(), "reiniciar_campanha limpa os níveis concluídos")
	e.avancar_nivel()
	_ok(e.nivel_esta_concluido(0), "avancar_nivel marca o nível de onde se sai")
	_ok(e.indice_nivel == 1, "avancar_nivel avançou para o nível 1")
	e.free()


## "DEVELOPER MODE": liga o sandbox (todas as habilidades, muitas
## vidas, nível 1), NÃO grava no disco, e `reiniciar_campanha()` desliga-o.
func teste_estado_modo_dev() -> void:
	var e := _novo_estado()
	_ok(not e.modo_dev, "arranque normal não está em modo dev")
	e.ativar_modo_dev()
	_ok(e.modo_dev, "ativar_modo_dev liga a flag")
	_ok(e.indice_nivel == 0, "modo dev arranca no nível 1")
	for h in e.HABILIDADES_TODAS:
		_ok(e.tem_habilidade(h), "modo dev desbloqueia a habilidade '%s'" % h)
	_ok(e.vidas >= 3, "modo dev dá vidas de sobra")
	e.reiniciar_campanha()
	_ok(not e.modo_dev, "reiniciar_campanha desliga o modo dev")
	e.free()


## Mapa do Mundo: que níveis se podem escolher. O nível 0 está sempre
## aberto; concluir um nível abre o seguinte; um save linear antigo
## (indice_nivel à frente) não regride; tudo concluído = campanha feita.
func teste_estado_mapa_desbloqueio() -> void:
	var e := _novo_estado()
	_ok(e.nivel_desbloqueado(0), "o primeiro nível está sempre desbloqueado")
	_ok(not e.nivel_desbloqueado(1), "nível 1 bloqueado num arranque limpo")
	_ok(e.fronteira() == 0, "fronteira num arranque limpo é 0")
	_ok(not e.campanha_concluida(), "campanha não concluída no arranque")

	e.marcar_nivel_concluido(0)
	_ok(e.nivel_desbloqueado(1), "concluir o nível 0 desbloqueia o 1")
	_ok(not e.nivel_desbloqueado(2), "o nível 2 continua bloqueado")
	_ok(e.fronteira() == 1, "fronteira passa a 1")

	e.reiniciar_campanha()
	e.indice_nivel = 2  # save linear antigo, sem 'concluidos'
	_ok(e.nivel_desbloqueado(2), "um nível já alcançado pela campanha linear fica jogável")
	_ok(not e.nivel_desbloqueado(3), "mas não os que vêm depois")

	e.reiniciar_campanha()
	for i in e.NIVEIS.size():
		e.marcar_nivel_concluido(i)
	_ok(e.campanha_concluida(), "marcar todos os níveis conclui a campanha")
	_ok(e.nivel_desbloqueado(e.NIVEIS.size() - 1), "com tudo feito, o último nível é jogável")
	e.free()


# --- Assets: rig da Koliani, especies dos inimigos, packs de fundo ----------
# Estes testes leem os .gd como TEXTO para validar tabelas declarativas sem
# instanciar actores, efeitos ou estado de jogo. O que interessa e' apanhar o
# erro tipico: mudar um nome ou um numero de
# frames numa tabela e a tira deixar de bater certo com o PNG.

## Le um ficheiro de codigo do repo (ou "" se nao existir).
## Um dos `assets/i18n/*.json` como Dictionary (vazio se não der).
func _json_i18n(loc: String) -> Dictionary:
	var caminho := "res://assets/i18n/%s.json" % loc
	if not FileAccess.file_exists(caminho):
		_ok(false, "falta o ficheiro %s" % caminho)
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	return d if d is Dictionary else {}


func _fonte(caminho: String) -> String:
	if not FileAccess.file_exists(caminho):
		_ok(false, "falta o ficheiro %s" % caminho)
		return ""
	return FileAccess.get_file_as_string(caminho)


## Todos os pares "estado": [n_frames, ...] de um bloco `const NOME := {...}`.
func _tabela_frames(fonte: String, nome_const: String) -> Dictionary:
	var out := {}
	var i := fonte.find("const %s :=" % nome_const)
	if i < 0:
		return out
	var fim := fonte.find("\n}", i)
	var bloco := fonte.substr(i, maxi(0, fim - i))
	var re := RegEx.new()
	re.compile('"([a-z_]+)":\\s*\\[(\\d+),')
	for m in re.search_all(bloco):
		out[m.get_string(1)] = int(m.get_string(2))
	return out


## Confirma que a tira existe e que a largura da' um numero INTEIRO de
## frames; devolve a largura de UM frame (0 se falhou). Quem chama compara as
## larguras entre animacoes: todas as tiras do mesmo rig/especie tem de ter
## o frame do mesmo tamanho -- e' o que apanha um numero de frames errado
## (400 px tanto da' 4 frames de 100 como 5 de 80).
func _imagem_importada(caminho: String) -> Image:
	var textura := ResourceLoader.load(caminho, "Texture2D") as Texture2D
	return textura.get_image() if textura != null else null


func _tira_bate_certo(caminho: String, n: int, quem: String) -> int:
	if not FileAccess.file_exists(caminho):
		_ok(false, "%s: falta a tira %s" % [quem, caminho])
		return 0
	var img := _imagem_importada(caminho)
	if img == null:
		_ok(false, "%s: nao abriu %s" % [quem, caminho])
		return 0
	if n <= 0 or img.get_width() % n != 0:
		_ok(false, "%s: %s tem %d px de largura, que nao da' %d frames certos"
			% [quem, caminho.get_file(), img.get_width(), n])
		return 0
	return img.get_width() / n


func teste_rig_da_koliani_tem_as_tiras_todas() -> void:
	var src := _fonte("res://scripts/koliani.gd")
	if src == "":
		return
	var re := RegEx.new()
	re.compile('const RIG := "([a-z]+)"')
	var m := re.search(src)
	_ok(m != null, "koliani.gd: nao encontrei `const RIG`")
	if m == null:
		return
	var rig := m.get_string(1)
	var tabela := {"codigo": "_KOLI_ANIMS", "gothic": "_KOLI_ANIMS_GOTHIC",
		"cavaleiro": "_KOLI_ANIMS_CAVALEIRO", "nova": "_KOLI_ANIMS_NOVA",
		"shadowblade": "_KOLI_ANIMS_SHADOW"}
	var pasta := {"codigo": "koliani", "gothic": "koliani_gothic",
		"cavaleiro": "koliani_cavaleiro", "nova": "koliani_nova",
		"shadowblade": "koliani_shadowblade"}
	_ok(tabela.has(rig), "koliani.gd: RIG '%s' nao tem tabela de animacoes" % rig)
	if not tabela.has(rig):
		return
	var anims := _tabela_frames(src, tabela[rig])
	_ok(not anims.is_empty(), "koliani.gd: tabela %s vazia" % tabela[rig])
	# os estados que o `_atualizar_anim` usa sempre, em qualquer rig
	for obrigatorio in ["idle", "run", "jump", "fall", "attack"]:
		_ok(anims.has(obrigatorio),
			"rig '%s' nao tem o estado '%s'" % [rig, obrigatorio])
	var largura := 0
	for estado: String in anims:
		var fw := _tira_bate_certo(
			"res://assets/sprites/pixel/%s/%s.png" % [pasta[rig], estado],
			int(anims[estado]), "rig '%s'" % rig)
		if fw <= 0:
			continue
		if largura == 0:
			largura = fw
		else:
			_ok(fw == largura,
				"rig '%s': o frame de '%s' tem %d px e os outros tem %d -- o numero de frames na tabela esta' errado"
					% [rig, estado, fw, largura])


func teste_especies_dos_inimigos_existem() -> void:
	var src := _fonte("res://scripts/demonio_base.gd")
	if src == "":
		return
	# ESPECIES := { "nome": {"idle": 4, "run": 8, "hit": 4, "dead": 4}, ... }
	var re := RegEx.new()
	re.compile('"([a-z_]+)":\\s*\\{"idle": (\\d+), "run": (\\d+), "hit": (\\d+), "dead": (\\d+)\\}')
	var especies := {}
	for m in re.search_all(src):
		especies[m.get_string(1)] = {
			"idle": int(m.get_string(2)), "run": int(m.get_string(3)),
			"hit": int(m.get_string(4)), "dead": int(m.get_string(5)),
		}
	_ok(especies.size() >= 14, "demonio_base.gd: so' li %d especies" % especies.size())
	for esp: String in especies:
		var cfg: Dictionary = especies[esp]
		var largura := 0
		for anim: String in cfg:
			var fw := _tira_bate_certo(
				"res://assets/sprites/pixel/enemies/%s/%s.png" % [esp, anim],
				int(cfg[anim]), "especie '%s'" % esp)
			if fw <= 0:
				continue
			if largura == 0:
				largura = fw
			else:
				_ok(fw == largura,
					"especie '%s': o frame de '%s' tem %d px e os outros tem %d -- contagem de frames errada"
						% [esp, anim, fw, largura])

	# o gerador so' pode pedir especies que existam
	var ger := _fonte("res://scripts/gerador_corredor.gd")
	if ger == "":
		return
	var i := ger.find("const ESP_ASSINATURA :=")
	var fim := ger.find("]", i)
	var bloco := ger.substr(i, maxi(0, fim - i))
	var rn := RegEx.new()
	rn.compile('"([a-z_]+)"')
	var assinaturas: Array[String] = []
	for m in rn.search_all(bloco):
		assinaturas.append(m.get_string(1))
	var estado := _novo_estado()
	var n_niveis: int = estado.NIVEIS.size()
	estado.free()
	_ok(assinaturas.size() == n_niveis,
		"ESP_ASSINATURA tem %d entradas (deviam ser %d, uma por nível)"
			% [assinaturas.size(), n_niveis])
	for esp in assinaturas:
		_ok(especies.has(esp), "ESP_ASSINATURA pede a especie '%s', que nao existe" % esp)
	# dentro da mesma regiao (5 niveis) nao ha assinaturas repetidas -- e' o
	# pedido do Paulo: "nao repetir o mesmo monstro em cada nivel"
	for r in range(0, assinaturas.size() / 5):
		var fatia := assinaturas.slice(r * 5, r * 5 + 5)
		var unicos := {}
		for e in fatia:
			unicos[e] = true
		_ok(unicos.size() == fatia.size(),
			"regiao %d repete uma assinatura: %s" % [r + 1, str(fatia)])

	var j := ger.find("const ESP_REGIAO :=")
	var fim2 := ger.find("\n}", j)
	for m in rn.search_all(ger.substr(j, maxi(0, fim2 - j))):
		_ok(especies.has(m.get_string(1)),
			"ESP_REGIAO pede a especie '%s', que nao existe" % m.get_string(1))


## Cada região da campanha tem NOME traduzível e cor próprias, e o carrossel
## tem uma arte de fundo para todas.
##
## Foi assim que as 14 regiões novas (a 7.ª em diante) andaram a aparecer
## como "?" cinzento no ecrã de escolha de nível: as tabelas do
## `seletor_niveis.gd` tinham ficado com 6 entradas quando a campanha passou
## a 20. Agora o nome e a cor vivem em `EstadoJogo.REGIOES` e isto guarda-os.
func teste_regioes_tem_nome_e_cor() -> void:
	var e := _novo_estado()
	var en := _json_i18n("en")
	var chaves := {}
	for r in e.REGIOES.size():
		var reg: Dictionary = e.REGIOES[r]
		_ok(reg.has("chave"), "a região %d (%s) não tem chave i18n" % [r, reg.get("id", "?")])
		_ok(reg.has("cor"), "a região %d (%s) não tem cor" % [r, reg.get("id", "?")])
		var k: String = reg.get("chave", "")
		_ok(k.begins_with("world."), "a chave da região %d devia ser world.* (é '%s')" % [r, k])
		_ok(en.has(k), "en.json sem a chave da região %d ('%s')" % [r, k])
		_ok(not chaves.has(k), "duas regiões com a mesma chave '%s'" % k)
		chaves[k] = true
		_ok(e.chave_regiao_do_nivel(reg["niveis"][0]) == k,
			"chave_regiao_do_nivel não devolve '%s' para a região %d" % [k, r])
	# uma arte de fundo por região, e o ficheiro tem de existir
	var fundos: Array = SeletorNiveis.FUNDO_REGIAO
	_ok(fundos.size() == e.REGIOES.size(),
		"FUNDO_REGIAO tem %d entradas para %d regiões" % [fundos.size(), e.REGIOES.size()])
	for i in mini(fundos.size(), e.REGIOES.size()):
		_ok(ResourceLoader.exists(fundos[i]),
			"região %d: falta a arte de fundo %s" % [i, fundos[i]])
	# o passo dentro da região (o "3 / 5" do cabeçalho da HUD)
	var passo: Array[int] = e.passo_na_regiao(e.REGIOES[0]["niveis"][2])
	_ok(passo == [3, 5], "passo_na_regiao devia dar [3, 5], deu %s" % str(passo))
	e.free()


## As peças da interface (`assets/ui/`) estão geradas e importadas. Se
## faltarem, a HUD cai nas caixas lisas de recurso e ninguém dá por isso até
## ver o jogo -- correr `python tools/gerar_ui.py` e reimportar.
func teste_pecas_de_ui_existem() -> void:
	var pecas := [
		"painel_pedra", "painel_placa", "painel_chefe", "painel_madeira",
		"calha", "selo", "enchimento", "ico_caveira", "ico_losango",
		"ico_coracao", "ico_seta_esq", "ico_seta_dir",
	]
	for p: String in pecas:
		_ok(ResourceLoader.exists("res://assets/ui/%s.png" % p),
			"falta a peça de UI '%s' (correr tools/gerar_ui.py)" % p)
	# o enchimento tem de ser MAIS ALTO do que a barra mais alta da HUD --
	# esticado para além da textura, o Godot não desenha barra nenhuma
	var tex := load("res://assets/ui/enchimento.png") as Texture2D
	if tex:
		_ok(tex.get_height() >= UI.ALTURA_MAX_BARRA,
			"o enchimento tem %d px de altura, precisa de %d"
			% [tex.get_height(), UI.ALTURA_MAX_BARRA])


## Um painel de nine-patch tem de ser UM painel, nao um recorte que apanhou
## o vizinho. Na folha do kit os paineis vem colados uns aos outros,
## separados por uma risca preta -- e o `painel_madeira` estava recortado a
## 64x64 quando o quadrado dele e' 48x48, portanto trazia meia coluna e meia
## faixa do lado. No Godot isso desenha-se AOS BOCADOS: os botoes do rodape
## do seletor de niveis sairam como tres blocos soltos com buracos no meio.
##
## O que se mede: dentro da zona ESTICAVEL da nine-patch (entre as margens)
## nao pode haver uma coluna nem uma linha inteiramente escura -- e' isso, e
## so' isso, que uma divisoria entre paineis e'.
func teste_paineis_nao_trazem_o_vizinho() -> void:
	# a `calha` fica de fora de proposito: e' o buraco escuro por onde a
	# barra corre, quase preto de ponta a ponta, e qualquer medida de
	# "risca escura" acusa-a inteira.
	for nome: String in ["painel_pedra", "painel_placa", "painel_chefe",
			"painel_madeira"]:
		var caminho := "res://assets/ui/%s.png" % nome
		if not FileAccess.file_exists(caminho):
			continue   # a falta ja' e' reportada por `teste_pecas_de_ui_existem`
		var img := _imagem_importada(caminho)
		if img == null:
			_ok(false, "%s: nao abriu" % nome)
			continue
		var m := UI.MARGEM_PAINEL
		var l := img.get_width()
		var a := img.get_height()
		if l <= m * 2 or a <= m * 2:
			_ok(false, "%s tem %dx%d, mais pequeno que as duas margens (%d)"
				% [nome, l, a, m * 2])
			continue
		var maus := 0
		for x in range(m, l - m):
			if _risca_escura(img, x, m, a - m, true):
				maus += 1
		for y in range(m, a - m):
			if _risca_escura(img, y, m, l - m, false):
				maus += 1
		_ok(maus == 0,
			"%s tem %d risca(s) a atravessa'-lo no meio -- o recorte apanhou o painel do lado (ver PAINEL_* em tools/gerar_ui.py)"
				% [nome, maus])


## Uma linha/coluna e' "escura" se TODOS os seus pixels no troco medido sao
## quase pretos e opacos. `horizontal` = false mede uma linha.
func _risca_escura(img: Image, fixo: int, de: int, ate: int, vertical: bool) -> bool:
	for i in range(de, ate):
		var c := img.get_pixel(fixo, i) if vertical else img.get_pixel(i, fixo)
		if c.a < 0.9 or c.r > 0.14 or c.g > 0.14 or c.b > 0.14:
			return false
	return true


## A tabela `MECANICA_DO_NIVEL` e' a promessa de "uma mecanica nova por
## nivel" (pedido do Paulo, 5 set 2026: "100 niveis a fazer a mesma coisa e
## o mesmo padrao cansa o player"). O que se guarda aqui:
##
##  - ha' 100 entradas, uma por nivel;
##  - cada `cam` e' uma camara que o `_flavour()` sabe mesmo construir --
##    uma que ele nao conheca gera um vao morto SILENCIOSO (foi assim que a
##    camara "pedras" andou semanas a partir niveis sem ninguem dar por ela);
##  - dois niveis SEGUIDOS nunca estreiam a mesma coisa -- e' exatamente a
##    sensacao de "isto ja' joguei" que o pedido quer tirar;
##  - as 32 camaras estreiam todas nos primeiros 32 niveis, cada uma na sua
##    vez. Sem isto o jogo voltava a abrir tudo de uma vez.
##
## Le'-se do CODIGO-FONTE para medir a tabela declarativa completa sem
## construir uma jornada. A integracao em runtime fica em
## `verifica_jornada.gd`.
func teste_mecanica_por_nivel() -> void:
	var src := _fonte("res://scripts/gerador_corredor.gd")
	if src == "":
		return
	var cams := _lista_de_strings(src, "CAMARAS_FLAVOUR")
	_ok(not cams.is_empty(), "nao se conseguiu ler CAMARAS_FLAVOUR")

	var i := src.find("const MECANICA_DO_NIVEL :=")
	_ok(i >= 0, "falta a const MECANICA_DO_NIVEL")
	if i < 0:
		return
	var fim := src.find("\n]", i)
	var bloco := src.substr(i, fim - i)

	var mec: Array[String] = []
	var graus: Array[int] = []
	for linha in bloco.split("\n"):
		var l := linha.strip_edges()
		if not l.begins_with("{\"cam\""):
			continue
		var a := l.find("\"", 8) + 1
		var b := l.find("\"", a)
		mec.append(l.substr(a, b - a))
		var g := l.find("\"grau\":")
		graus.append(int(l.substr(g + 8, 2).strip_edges().trim_suffix("}").trim_suffix(",")))

	_ok(mec.size() == 100, "MECANICA_DO_NIVEL tem %d entradas, precisa de 100" % mec.size())

	for k in mec.size():
		_ok(mec[k] in cams,
			"nivel %d estreia '%s', que o _flavour() nao sabe construir" % [k + 1, mec[k]])
		_ok(graus[k] >= 0 and graus[k] <= 2,
			"nivel %d tem grau %d (so' 0, 1 ou 2)" % [k + 1, graus[k]])

	for k in range(1, mec.size()):
		_ok(mec[k] != mec[k - 1],
			"niveis %d e %d estreiam os dois '%s' -- seguidos nao pode"
				% [k, k + 1, mec[k]])

	# TODAS as camaras que o jogo sabe construir tem de ter um nivel onde
	# APARECEM -- uma camara que exista e nunca apareca e' trabalho parado.
	# (o `descanso` fica de fora: e' o alivio entre camaras, nao uma estreia)
	#
	# 20 set 2026: a regra passa a ser "ou e' apresentada num nivel, OU tem
	# desbloqueio fixo declarado". A `MECANICA_DO_NIVEL` fazia duas coisas ao
	# mesmo tempo -- dizia o que cada nivel apresenta E, por ser a primeira
	# ocorrencia, quando cada camara ficava disponivel em TODAS as regioes.
	# Dar a` Torre dos Ecos as mecanicas do canone obrigava a mexer no
	# calendario de desbloqueio de regioes que nada tem a ver com isto (a
	# melhor permutacao possivel ainda reconstruia dez niveis das Regioes VI
	# e VIII). O `DESBLOQUEIO_FIXO` prende o calendario dessas; o preco e'
	# ficarem sem o aviso de estreia. A lista tem de ser PEQUENA e explicita
	# -- e' por isso que o teste a le' do codigo em vez de a aceitar em
	# silencio, e falha se alguem la' despejar camaras para calar o teste.
	var estreadas: Dictionary = {}
	var estreadas_em: Dictionary = {}
	for k in mec.size():
		estreadas[mec[k]] = true
		if not estreadas_em.has(mec[k]):
			estreadas_em[mec[k]] = k
	# le'-se do CODIGO-FONTE, como o resto deste teste
	var fixas: Array[String] = []
	var fixas_niveis: Dictionary = {}
	var j := src.find("const DESBLOQUEIO_BASE :=")
	_ok(j >= 0, "falta a const DESBLOQUEIO_BASE")
	if j >= 0:
		var bf := src.substr(j, src.find("\n}", j) - j)
		for linha in bf.split("\n"):
			var l := linha.strip_edges()
			if not l.begins_with("\""):
				continue
			var nome := l.substr(1, l.find("\"", 1) - 1)
			fixas.append(nome)
			var dp := l.find(":")
			fixas_niveis[nome] = int(l.substr(dp + 1).strip_edges()
				.trim_suffix(",").strip_edges())
	_ok(fixas.size() <= 10,
		"DESBLOQUEIO_BASE tem %d entradas: e' o calendario congelado das"
			% fixas.size() + " que mudaram de lugar, nao uma gaveta")
	for c: String in cams:
		if c == "descanso":
			continue
		_ok(estreadas.has(c) or c in fixas,
			"a camara '%s' existe mas nunca aparece em nivel nenhum" % c)
	for c: String in fixas:
		_ok(c in cams,
			"DESBLOQUEIO_FIXO prende '%s', que nem sequer existe" % c)
		# uma camara PODE estar nas duas: o `DESBLOQUEIO_BASE` congela o
		# calendario GLOBAL de quem se apresenta noutro sitio. O que nao
		# pode e' apresentar-se no mesmo nivel em que desbloqueia -- ai' a
		# entrada nao serve para nada.
		_ok(fixas_niveis.get(c, -1) != estreadas_em.get(c, -2),
			"'%s' no DESBLOQUEIO_BASE prende o nivel onde ja' se apresenta"
			% c + " -- a entrada esta' a mais")

	# e os primeiros 32 niveis estreiam 32 coisas diferentes: sem isto o
	# jogo voltava a abrir tudo de uma vez logo no inicio
	#
	# 20 set 2026: passam a ser 31, e a excepcao e' NOMEADA. O `elevador` e'
	# a camara-assinatura do N12 ("elevador de coluna", canone da Torre dos
	# Ecos) E do N16 (Cemiterio dos Reis, tumulos elevadores). Quem joga
	# conhece o elevador no N12; o N16 usa-o sem o voltar a apresentar, que
	# e' o comportamento certo -- repetir o aviso era ruido. A lista de
	# repeticoes permitidas fica aqui, explicita: uma SEGUNDA repeticao
	# volta a falhar, e e' isso que impede isto de virar uma gaveta.
	const REPETIDAS_OK := ["elevador"]
	var contagem: Dictionary = {}
	for k in range(0, 32):
		contagem[mec[k]] = int(contagem.get(mec[k], 0)) + 1
	var repetidas: Array[String] = []
	for c: String in contagem:
		if int(contagem[c]) > 1:
			repetidas.append(c)
	repetidas.sort()
	_ok(repetidas == REPETIDAS_OK,
		"nos primeiros 32 niveis repetem-se %s; so' %s esta' justificada"
			% [str(repetidas), str(REPETIDAS_OK)])
	_ok(contagem.size() == 32 - REPETIDAS_OK.size(),
		"os primeiros 32 niveis apresentam %d camaras distintas, esperavam-se %d"
			% [contagem.size(), 32 - REPETIDAS_OK.size()])


## Todas as strings de um bloco `const NOME := [...]`.
func _lista_de_strings(fonte: String, nome_const: String) -> Array[String]:
	var out: Array[String] = []
	var i := fonte.find("const %s :=" % nome_const)
	if i < 0:
		return out
	var fim := fonte.find("\n]", i)
	for p in fonte.substr(i, fim - i).split("\""):
		if p.length() > 0 and p == p.to_lower() and not p.contains(","):
			out.append(p)
	return out


func teste_packs_de_fundo_existem() -> void:
	var src := _fonte("res://scripts/atmosfera.gd")
	if src == "":
		return
	var i := src.find("const PACKS :=")
	var fim := src.find("\n}", i)
	var bloco := src.substr(i, maxi(0, fim - i))
	# "pack": [ ["ficheiro.png", "Camada", y, esc], ... ]
	var packs: Array[String] = []
	var pack_atual := ""
	var re_pack := RegEx.new()
	re_pack.compile('^\\t"([a-z_]+)":')
	var re_lin := RegEx.new()
	re_lin.compile('\\["([\\w\\-.]+\\.png)", "(\\w+)"')
	for linha in bloco.split("\n"):
		var mp := re_pack.search(linha)
		if mp:
			pack_atual = mp.get_string(1)
			packs.append(pack_atual)
			continue
		var ml := re_lin.search(linha)
		if ml and pack_atual != "":
			var caminho := "res://assets/sprites/pixel/backgrounds/%s/%s" \
				% [pack_atual, ml.get_string(1)]
			_ok(FileAccess.file_exists(caminho),
				"pack '%s': falta %s" % [pack_atual, caminho])
			_ok(ml.get_string(2) in ["Fundo", "Longe", "Meio", "Perto"],
				"pack '%s': camada '%s' nao existe no Parallax"
					% [pack_atual, ml.get_string(2)])
	_ok(packs.size() >= 7, "atmosfera.gd: so' li %d packs" % packs.size())

	# nenhum nivel pode pedir um pack que nao esta na tabela
	var dir := DirAccess.open("res://scenes/levels")
	if dir == null:
		return
	var re_uso := RegEx.new()
	re_uso.compile('fundo_pack = "([a-z_]+)"')
	for f in dir.get_files():
		if not f.ends_with(".tscn"):
			continue
		var cena := FileAccess.get_file_as_string("res://scenes/levels/%s" % f)
		var mu := re_uso.search(cena)
		if mu:
			_ok(mu.get_string(1) in packs,
				"%s pede o fundo_pack '%s', que nao existe" % [f, mu.get_string(1)])


## Cada cena de chefe que declara um `rig` tem mesmo esse rig em disco, com
## as cinco tiras, o numero de frames certo e um tamanho que se le' como
## chefe no ecra.
##
## Porque e' que isto existe: a 3 set 2026 vinte chefes trocaram de boneco
## de uma so' vez (`tools/importar_chefes_animados.py` + 20 packs novos).
## Um `rig` mal escrito na cena nao rebenta -- o `ChefeBase._montar_rig` so'
## avisa e deixa o chefe com a folha estatica antiga, que e' exactamente o
## problema que se estava a resolver. E um rig LARGO e baixo, escalado so'
## pela altura, sai mais largo que a plataforma da arena.
func teste_rigs_dos_chefes() -> void:
	var cat: Variant = JSON.parse_string(
		_fonte("res://assets/sprites/pixel/bosses_anim/rigs.json"))
	_ok(cat is Dictionary and not (cat as Dictionary).is_empty(),
		"bosses_anim/rigs.json devia ser um catálogo com rigs")
	if not (cat is Dictionary):
		return

	var re_rig := RegEx.new()
	re_rig.compile('(?m)^rig = "([a-z_]+)"')
	var re_esc := RegEx.new()
	re_esc.compile('(?m)^escala_visual = ([0-9.]+)')

	# Os dois tectos vêm do `chefe_base.gd` e são lidos da FONTE para este
	# teste continuar focado nos dados dos rigs, sem instanciar chefes.
	var fonte_cb := _fonte("res://scripts/chefe_base.gd")
	var alvo_h := _constante_float(fonte_cb, "ALTURA_ALVO_CHEFE")
	var alvo_w := _constante_float(fonte_cb, "LARGURA_ALVO_CHEFE")
	_ok(alvo_h > 0.0 and alvo_w > 0.0,
		"chefe_base.gd: não li ALTURA_ALVO_CHEFE/LARGURA_ALVO_CHEFE")
	if alvo_h <= 0.0 or alvo_w <= 0.0:
		return

	var dir := DirAccess.open("res://scenes/actors")
	_ok(dir != null, "não abri res://scenes/actors")
	if dir == null:
		return
	var com_rig := 0
	for f in dir.get_files():
		if not f.begins_with("Chefe") or not f.ends_with(".tscn"):
			continue
		var src := _fonte("res://scenes/actors/%s" % f)
		var m := re_rig.search(src)
		if m == null:
			continue                      # sem rig: folha estática, tudo bem
		com_rig += 1
		var rig := m.get_string(1)
		_ok(cat.has(rig), "%s: rig '%s' não existe em rigs.json" % [f, rig])
		if not cat.has(rig):
			continue
		_ok(src.contains('[node name="Anim" type="AnimatedSprite2D" parent="Sprite"]'),
			"%s: declara rig mas não tem o nó Sprite/Anim que o recebe" % f)

		# as cinco tiras, e o frame do mesmo tamanho em todas
		var cfg: Dictionary = cat[rig]
		var estados: Dictionary = cfg.get("estados", {})
		_ok(estados.has("idle"), "%s: rig '%s' sem 'idle'" % [f, rig])
		var larg_frame := 0
		for estado: String in estados:
			var w := _tira_bate_certo(
				"res://assets/sprites/pixel/bosses_anim/%s/%s.png" % [rig, estado],
				int(estados[estado]), "%s/%s" % [rig, estado])
			if w <= 0:
				continue
			if larg_frame == 0:
				larg_frame = w
			_ok(w == larg_frame,
				"%s/%s: frame de %d px, mas o resto do rig tem %d"
					% [rig, estado, w, larg_frame])

		# tamanho no ecrã: o mesmo cálculo do `DemonioBase._normalizar_escala`
		# (altura-alvo com tecto de largura) vezes o `escala_visual` da cena.
		var img := _imagem_importada(
			"res://assets/sprites/pixel/bosses_anim/%s/idle.png" % rig)
		if img == null or larg_frame <= 0:
			continue
		var frame := img.get_region(Rect2i(0, 0, larg_frame, img.get_height()))
		var r := frame.get_used_rect()
		if r.size.y <= 0 or r.size.x <= 0:
			_ok(false, "%s: o frame idle do rig '%s' está vazio" % [f, rig])
			continue
		var me := re_esc.search(src)
		var esc := float(me.get_string(1)) if me else 1.3
		# Um chefe pode reescrever os alvos (`_altura_alvo`/`_largura_alvo`
		# são virtuais no `DemonioBase`). Até ao Super-Process A este teste
		# lia só as constantes do `ChefeBase` e media qualquer chefe com
		# override pelo número errado -- acusou o Guardião dos Céus de sair
		# com 54 px de alto quando na verdade sai com 160.
		var h_alvo := alvo_h
		var w_alvo := alvo_w
		var proprio := false
		var cam_script := _script_do_chefe(src)
		if cam_script != "":
			var fonte := _fonte(cam_script)
			var ph := _retorno_float(fonte, "_altura_alvo")
			var pw := _retorno_float(fonte, "_largura_alvo")
			if ph > 0.0:
				h_alvo = ph
				proprio = true
			if pw > 0.0:
				w_alvo = pw
				proprio = true
		var k: float = minf(h_alvo / float(r.size.y), w_alvo / float(r.size.x))
		var largura := r.size.x * k * esc
		var altura := r.size.y * k * esc
		# A banda vem dos nove rigs que já cá estavam antes de 3 set 2026:
		# o mais pequeno media 52x125 e o maior 150x200. Fora disto o chefe
		# ou não se lê como chefe, ou não cabe na plataforma da arena.
		#
		# EXCEÇÃO com alvos próprios: o Guardião dos Céus é o primeiro chefe
		# ALADO de asas abertas, e nele a largura É a silhueta -- o cânone
		# da Região II diz isso com todas as letras. O tecto sobe para 240,
		# que é o que ainda deixa 57% da plataforma da arena do N10 (560 px)
		# livre para a Koliani. Acima disso o chefe tapa a arena.
		var tecto := 240.0 if proprio else 175.0
		_ok(largura <= tecto,
			"%s: rig '%s' sai com %d px de largo (máx %d) -- baixar escala_visual"
				% [f, rig, int(largura), int(tecto)])
		_ok(altura >= 75.0,
			"%s: rig '%s' sai com %d px de alto (mín 75) -- lê-se como bicho comum"
				% [f, rig, int(altura)])
	_ok(com_rig >= 29, "esperava >= 29 chefes com rig animado, contei %d" % com_rig)


## `const NOME := 123.0` de um ficheiro .gd, ou 0.0 se não estiver lá.
func _constante_float(fonte: String, nome: String) -> float:
	var re := RegEx.new()
	re.compile("const %s := ([0-9.]+)" % nome)
	var m := re.search(fonte)
	return float(m.get_string(1)) if m else 0.0


## Caminho do script de um `Chefe*.tscn`, ou "" se não tiver.
func _script_do_chefe(src: String) -> String:
	var re := RegEx.new()
	re.compile('type="Script" path="(res://scripts/[^"]+)"')
	var m := re.search(src)
	return m.get_string(1) if m else ""


## O valor que `func <nome>() -> float: return X` devolve, ou 0.0 se o
## ficheiro não reescrever essa função.
func _retorno_float(fonte: String, nome: String) -> float:
	var re := RegEx.new()
	re.compile("func %s\\(\\) -> float:\\s*\\n\\treturn ([0-9.]+)" % nome)
	var m := re.search(fonte)
	return float(m.get_string(1)) if m else 0.0

## As camas de musica tocam SEMPRE em ciclo (`musica.gd` poe `loop = true`).
## Uma faixa curta de mais da' nas vistas por repetir de 8 em 8 segundos, e
## uma faixa com fade-out desaparece e volta a entrar a cada volta -- foi
## disso que o Paulo se queixou a 4 set 2026. As 40 sao construidas por
## `tools/preparar_musica.py`, que tem um `--verificar` que mede tambem o
## degrau na costura; aqui garante-se o que se consegue medir de dentro do
## Godot: que existem todas e que nenhuma e' curta de mais.
func teste_camas_de_musica() -> void:
	const DUR_MINIMA := 28.0
	var moldes := {
		"res://assets/audio/musica/niveis/nivel_%02d.ogg": "nivel",
		"res://assets/audio/musica/chefes/boss_%02d.ogg": "chefe",
	}
	for molde: String in moldes:
		for i in range(1, 21):
			var c: String = molde % i
			if not ResourceLoader.exists(c):
				_ok(false, "falta a cama %s" % c)
				continue
			var st: AudioStream = load(c)
			if st == null:
				_ok(false, "%s nao carrega como AudioStream" % c)
				continue
			_ok(st.get_length() >= DUR_MINIMA,
				"%s tem %.1f s (minimo %.0f) -- em ciclo isso repete de mais"
					% [c, st.get_length(), DUR_MINIMA])


## A cama do chefe passou a arrancar ao acender a fogueira que esta' ao pe'
## da arena (pedido do Paulo, 5 set 2026) -- antes so' entrava ao 1.o golpe.
## Quem decide qual e' a fogueira e' `Fogueiras.indice_da_do_chefe`.
## O que se guarda aqui e' o que da' para partir sem se dar por isso: ganhar
## a fogueira ERRADA punha musica de combate a meio do nivel.
func teste_fogueira_do_chefe() -> void:
	var arena := Vector2(3000.0, 600.0)
	var pos: Array[Vector2] = [
		Vector2(40.0, 600.0), Vector2(-4600.0, 520.0),
		Vector2(1400.0, 636.0), Vector2(2900.0, 610.0),
	]
	_ok(Fogueiras.indice_da_do_chefe(pos, arena) == 3,
		"a fogueira do chefe devia ser a mais perto da arena")
	# a ordem na arvore nao pode contar -- so' a distancia
	pos.reverse()
	_ok(Fogueiras.indice_da_do_chefe(pos, arena) == 0,
		"a escolha mudou so' por trocar a ordem das fogueiras")
	# nivel sem fogueiras: -1, e ninguem se marca (nao ha' musica de chefe)
	var vazio: Array[Vector2] = []
	_ok(Fogueiras.indice_da_do_chefe(vazio, arena) == -1,
		"sem fogueiras devia devolver -1")


## Todos os caminhos declarados em `Som.CAMINHOS` tem de existir. E' uma
## rede barata que apanha o caso classico: trocar a amostra de um som e
## mudar-lhe a extensao (o `ataque` passou de .wav a .ogg a 4 set 2026) e
## esquecer o outro lado -- o jogo nao estoira, simplesmente fica MUDO
## nesse som, que e' pior de apanhar.
func teste_sfx_existem() -> void:
	var caminhos: Dictionary = Som.CAMINHOS
	_ok(not caminhos.is_empty(), "Som.CAMINHOS esta' vazio")
	for nome: String in caminhos:
		var c: String = caminhos[nome]
		_ok(ResourceLoader.exists(c),
			"Som: o efeito '%s' aponta para %s, que nao existe" % [nome, c])


## Execution 9G -- VFX de produção da Região I (prancha 07).
## Execution 9H: o frontend (intro, menu, seletor, icone) sai das pranchas
## aprovadas e o texto todo vem do `Textos`.
## Execution 9H: os inimigos deixaram de ser imagem parada. A asserção mede
## o sprite ao longo de meio segundo: se a camada de vida for desligada (ou
## o `_process` voltar a sair cedo quando há `_anim`), a amplitude vai a
## zero e isto falha.
func teste_9h_inimigos_com_vida() -> void:
	var cena := load("res://scenes/actors/DemonioBase.tscn")
	if cena == null:
		_ok(false, "9H: falta a cena do demónio")
		return
	var d: Node = cena.instantiate()
	get_tree().root.add_child(d)
	await get_tree().process_frame
	var anim: Node2D = d.get_node_or_null("Sprite/Anim")
	var sprite: Node2D = d.get_node_or_null("Sprite")
	_ok(anim != null and sprite != null, "9H: o demónio não tem Sprite/Anim")
	if anim == null or sprite == null:
		d.queue_free()
		return
	var esc_min := INF
	var esc_max := -INF
	var y_min := INF
	var y_max := -INF
	for _i in 40:
		await get_tree().process_frame
		esc_min = minf(esc_min, anim.scale.y)
		esc_max = maxf(esc_max, anim.scale.y)
		y_min = minf(y_min, sprite.position.y)
		y_max = maxf(y_max, sprite.position.y)
	_ok(esc_max - esc_min > 0.004,
		"9H: o inimigo não respira (amplitude de escala %.4f)" % (esc_max - esc_min))
	_ok(y_max - y_min > 0.20,
		"9H: o inimigo não tem passada (amplitude vertical %.2f px)" % (y_max - y_min))
	d.queue_free()


func teste_9h_frontend_producao() -> void:
	_ok(Frontend9H.disponivel(), "9H: kit do frontend nao importado")
	for peca in ["fundo_menu", "fundo_seletor", "placa_selecionada", "painel_detalhe",
			"botao_jogar", "aba_atual", "anel_normal", "anel_atual", "anel_chefe",
			"ficha_nivel", "losango", "cadeado"]:
		_ok(Frontend9H.textura(peca) != null, "9H: falta a peca `%s` do kit" % peca)
	# a intro e' a cena de arranque, e o menu e' a que ela abre
	_ok(str(ProjectSettings.get_setting("application/run/main_scene", ""))
		== "res://scenes/ui/Intro.tscn", "9H: a `main_scene` nao e a intro")
	_ok(ResourceLoader.exists("res://assets/video/intro_koliani.ogv"),
		"9H: falta o video da intro em Ogg Theora")
	_ok(str(ProjectSettings.get_setting("application/config/icon", ""))
		== "res://icon.png", "9H: o icone do projeto nao e o do rebrand")
	# sem texto a` mao nos ecras novos
	for caminho in ["res://scripts/menu_inicial.gd", "res://scripts/seletor_niveis.gd",
			"res://scripts/editor_layout_toque.gd"]:
		if not ResourceLoader.exists(caminho):
			continue
		var fonte := FileAccess.get_file_as_string(caminho)
		_ok(not fonte.contains(".text = \"") or fonte.contains("Textos.t"),
			"9H: %s escreve texto a mao" % caminho)
	# as chaves novas existem nos 6 idiomas
	var chaves := ["menu.tagline", "menu.continue", "menu.select_level", "menu.press_enter",
		"menu.tap_play", "menu.developed_by", "selector.back_to_menu", "selector.play",
		"selector.state_available", "selector.quote_region_1", "options.touch_layout",
		"layout.title", "layout.save", "layout.reset"]
	for lang in ["en", "pt", "es", "fr", "de", "zh"]:
		var txt := FileAccess.get_file_as_string("res://assets/i18n/%s.json" % lang)
		var d: Variant = JSON.parse_string(txt)
		_ok(d is Dictionary, "9H: %s.json invalido" % lang)
		if d is Dictionary:
			for k in chaves:
				_ok((d as Dictionary).has(k), "9H: falta `%s` em %s.json" % [k, lang])


## Execution 9H: os chefes da Regiao I ficaram mais faceis, em rampa do 1-1
## ao 1-5, e o resto da campanha NAO mudou. A asserção morde: instancia o
## Ghorak (chefe do 1-1) e compara a vida final com a que ele teria sem o
## alivio -- se alguem puser os fatores a 1,0, isto falha.
func teste_9h_chefes_regiao1_mais_faceis() -> void:
	var fora := ChefeBase.alivio_regiao_i(5)
	_ok(is_equal_approx(float(fora["vida"]), 1.0) and is_equal_approx(float(fora["dano"]), 1.0),
		"9H: o alivio nao devia sair da Regiao I")
	var v_ant := 0.0
	var d_ant := 0.0
	for i in 5:
		var a := ChefeBase.alivio_regiao_i(i)
		_ok(float(a["vida"]) < 1.0 and float(a["dano"]) < 1.0,
			"9H: o nivel 1-%d devia levar alivio" % (i + 1))
		_ok(float(a["tel"]) >= 1.0 and float(a["exposto"]) >= 1.0,
			"9H: o nivel 1-%d devia telegrafar mais, nao menos" % (i + 1))
		_ok(float(a["vida"]) > v_ant and float(a["dano"]) > d_ant,
			"9H: a rampa da Regiao I devia subir do 1-1 ao 1-5")
		v_ant = float(a["vida"])
		d_ant = float(a["dano"])

	var antes := EstadoJogo.indice_nivel
	EstadoJogo.indice_nivel = 0
	var chefe: Node = load("res://scenes/actors/ChefeGhorak.tscn").instantiate()
	get_tree().root.add_child(chefe)
	await get_tree().process_frame
	await get_tree().process_frame
	var vida_com := int(chefe.get("vida"))
	var esperado := int(round(250.0 * 3.2 * float(ChefeBase.ALIVIO_R1[0]["vida"])))
	_ok(absi(vida_com - esperado) <= 2,
		"9H: o Ghorak devia ficar com ~%d de vida, ficou com %d" % [esperado, vida_com])
	_ok(vida_com < int(round(250.0 * 3.2 * 0.75)),
		"9H: o Ghorak do 1-1 continua com a vida antiga (%d)" % vida_com)
	_ok(float(chefe.get("dano_onda")) < 22.0,
		"9H: o dano por ataque do Ghorak nao desceu (%s)" % chefe.get("dano_onda"))
	_ok(float(chefe.get("dur_exposto")) > 0.9,
		"9H: a janela EXPOSTO do 1-1 devia ser mais generosa (%.2f s)" % chefe.get("dur_exposto"))
	chefe.queue_free()
	EstadoJogo.indice_nivel = antes


func teste_9g_vfx_producao_regiao1() -> void:
	const Vfx := preload("res://scripts/vfx_regiao1.gd")
	var m := Vfx.manifesto()
	_ok(String(m.get("status", "")) == "PRODUCTION_INTEGRATED",
		"9G: manifesto dos VFX não está PRODUCTION_INTEGRATED")
	var aut: Dictionary = m.get("autoridade", {})
	_ok(String(aut.get("sha256", "")) == "6564982d4ccfad84d0a5f6d0e73196785afcff7ac8cd218dd27f066f883fe8c6",
		"9G: os VFX não vêm da prancha 07 aprovada (SHA: %s)" % aut.get("sha256", ""))
	var fams: Dictionary = m.get("familias", {})
	_ok(fams.size() >= 14, "9G: só %d famílias de VFX no manifesto" % fams.size())
	for nome: String in fams:
		var fam: Dictionary = fams[nome]
		for fr: Dictionary in fam.get("frames", []):
			var caminho := "%s/%s" % [Vfx.DIR, fr["ficheiro"]]
			_ok(ResourceLoader.exists(caminho), "9G: falta o frame %s" % caminho)
			_ok(String(fr.get("estado", "")) != "FAIL",
				"9G: frame reprovado em produção: %s %s" % [fr["ficheiro"], fr.get("alertas", [])])
		var sf := Vfx.frames(nome)
		_ok(sf != null and sf.get_frame_count("fx") > 0, "9G: família '%s' sem frames" % nome)
		if sf == null:
			continue
		for i in sf.get_frame_count("fx"):
			var tex := sf.get_frame_texture("fx", i)
			var p := tex.resource_path if tex else ""
			_ok(p.begins_with(Vfx.DIR), "9G: '%s' carrega textura de fora da produção: %s" % [nome, p])

	# A CORRUPÇÃO tem de se ler diferente da Shadowblade (briefing 9G §4/§12).
	var lum_sb := _lum_media_9g(Vfx.frames("hit_sparks"))
	var lum_cor := _lum_media_9g(Vfx.frames("hit_sparks_corrupcao"))
	_ok(lum_cor < lum_sb * 0.85,
		"9G: a corrupção não é mais escura que a Shadowblade (%.3f vs %.3f)" % [lum_cor, lum_sb])

	# INTERRUPTOR: ligado na Região I, desligado fora dela.
	var l1 := (load("res://scenes/levels/Floresta_Putrefata.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(l1)
	var k1 := l1.get_node_or_null("Koliani")
	_ok(k1 != null and Vfx.ativo(k1), "9G: VFX de produção desligados na Região I")
	if k1:
		var fx := Vfx.tocar(k1, "hit_sparks", k1.global_position)
		_ok(fx != null and fx.sprite_frames.get_frame_texture("fx", 0).resource_path.begins_with(Vfx.DIR),
			"9G: o acerto na Região I não usa o VFX de produção")
		if fx:
			fx.queue_free()
	l1.free()
	var l6 := (load("res://scenes/levels/Prisao_dos_Condenados.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(l6)
	var k6 := l6.get_node_or_null("Koliani")
	_ok(k6 == null or not Vfx.ativo(k6), "9G: VFX da Região I ligados fora da Região I")
	l6.free()

	# o nome canónico da Região I nos 6 idiomas
	for loc in ["en", "pt", "es", "fr", "de", "zh"]:
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/i18n/%s.json" % loc))
		_ok(d is Dictionary, "9G: %s.json ilegível" % loc)
		if d is Dictionary:
			for chave in ["world.forest", "level.n00"]:
				var v := String((d as Dictionary).get(chave, ""))
				_ok(not v.to_lower().contains("rotting") and not v.to_lower().contains("putref"),
					"9G: '%s' em %s ainda é o nome velho: %s" % [chave, loc, v])
				_ok(v == String((d as Dictionary).get("world.forest", "")),
					"9G: '%s' em %s não bate com o nome da região" % [chave, loc])


## Luminância média dos píxeis visíveis de uma família de VFX.
func _lum_media_9g(sf: SpriteFrames) -> float:
	if sf == null:
		return 0.0
	var soma := 0.0
	var n := 0
	for i in sf.get_frame_count("fx"):
		var tex := sf.get_frame_texture("fx", i)
		if tex == null:
			continue
		var im := tex.get_image()
		for y in range(0, im.get_height(), 2):
			for x in range(0, im.get_width(), 2):
				var c := im.get_pixel(x, y)
				if c.a <= 0.3:
					continue
				soma += (0.3 * c.r + 0.59 * c.g + 0.11 * c.b) * c.a
				n += 1
	return soma / maxf(1.0, float(n))


## -- Execution 9H.1 -------------------------------------------------------

## A trilha de producao existe, esta' importada, toca em CICLO e esta'
## declarada com proveniencia. A asserção morde: se alguem apagar uma faixa
## ou lhe tirar o loop, isto falha.
func teste_9h1_trilha_de_producao() -> void:
	var man: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/audio/musica/producao/manifesto_trilha_9h1.json"))
	_ok(man is Dictionary, "9H.1: falta o manifesto da trilha de producao")
	if not (man is Dictionary):
		return
	var faixas: Dictionary = (man as Dictionary).get("faixas", {})
	_ok(faixas.size() >= 6, "9H.1: a trilha de producao devia ter 6 pecas")
	for chave in Musica.PRODUCAO:
		var cam: String = Musica.PRODUCAO[chave]
		_ok(ResourceLoader.exists(cam), "9H.1: falta a faixa %s" % cam)
		if not ResourceLoader.exists(cam):
			continue
		var st: AudioStream = load(cam)
		_ok(st != null and st.get_length() > 20.0,
			"9H.1: %s nao carrega ou e curta demais" % cam)
		if st is AudioStreamWAV:
			_ok((st as AudioStreamWAV).loop_mode != AudioStreamWAV.LOOP_DISABLED,
				"9H.1: %s sem loop -- uma cama de jogo toca em ciclo" % cam)
	for k in faixas:
		var f: Dictionary = faixas[k]
		_ok(String(f.get("origem", "")).begins_with("ORIGINAL"),
			"9H.1: faixa %s sem proveniencia declarada" % k)
		_ok(String(f.get("licenca", "")) != "", "9H.1: faixa %s sem licenca" % k)
	# encaminhamento: as camas continuam nos buses do 9F
	_ok(AudioServer.get_bus_index("Music") >= 0, "9H.1: bus Music desapareceu")
	_ok(AudioServer.get_bus_index("SFX") >= 0, "9H.1: bus SFX desapareceu")
	# A cama principal usa agora as seleções Pixabay aprovadas por região.
	# As peças originais continuam nas camadas de intensidade e pausa.
	_ok(Musica.faixa_de_nivel(0) == Musica.REGIAO_01_APROVADA,
		"9H.1: o nivel 1-1 devia usar Midnight Forest")
	_ok(not Musica.faixa_de_nivel(19).begins_with(Musica.DIR_PRODUCAO),
		"9H.1: fora da Regiao I a trilha nova nao se aplica")
	_ok(Musica.faixa_de_chefe(4) == Musica.BOSS_01_APROVADO,
		"9H.1: o chefe da Regiao I devia usar Gothic Candlelight")


## Os quatro golpes do combo tem TIRAS PROPRIAS. O que isto guarda nao e' a
## existencia dos ficheiros -- e' que `attack2/3/4` nao voltem a ser a MESMA
## sequencia de `attack`, que era o defeito que o Game Master apontou.
func teste_9h1_combo_com_poses_proprias() -> void:
	var k: Koliani = preload("res://scenes/actors/Koliani.tscn").instantiate()
	k.usar_golden_set = true
	add_child(k)
	var corpo := k.get_node_or_null("Sprite/Corpo") as AnimatedSprite2D
	_ok(corpo != null and corpo.sprite_frames != null, "9H.1: Koliani sem SpriteFrames")
	if corpo == null or corpo.sprite_frames == null:
		k.queue_free()
		return
	var sf := corpo.sprite_frames
	var tiras := {}
	for nome in ["attack", "attack2", "attack3", "attack4"]:
		_ok(sf.has_animation(nome), "9H.1: falta a tira %s" % nome)
		if not sf.has_animation(nome):
			continue
		_ok(sf.get_frame_count(nome) == 6, "9H.1: %s devia ter 6 frames" % nome)
		var ids: Array[String] = []
		for i in sf.get_frame_count(nome):
			var t := sf.get_frame_texture(nome, i)
			ids.append(t.resource_path if t != null else "")
		tiras[nome] = ids
	var nomes: Array = tiras.keys()
	for i in nomes.size():
		for j in range(i + 1, nomes.size()):
			_ok(tiras[nomes[i]] != tiras[nomes[j]],
				"9H.1: %s e %s sao a MESMA sequencia de frames" % [nomes[i], nomes[j]])
	_ok(Koliani.NUM_COMBO == 4 and Koliani.DUR_COMBO.size() == 4,
		"9H.1: o combo devia ter 4 passos")
	for i in 4:
		var nome := "attack" if i == 0 else "attack%d" % (i + 1)
		if not sf.has_animation(nome):
			continue
		var dur := sf.get_frame_count(nome) / maxf(0.001, sf.get_animation_speed(nome))
		_ok(absf(dur - float(Koliani.DUR_COMBO[i])) < 0.02,
			"9H.1: %s dura %.3f s mas o golpe dura %.3f s"
				% [nome, dur, float(Koliani.DUR_COMBO[i])])
	k.queue_free()


## Pasta dos inimigos de producao (o `regiao1_inimigos.gd` nao tem
## `class_name`, e num teste nao vale a pena carrega-lo so' para isto).
const DIR_INIMIGOS_9H1 := "res://assets/art/regions/region_01_forest/enemies/production"


## As criaturas da Regiao I tem ciclos DERIVADOS (nao uma pose por estado) e
## um estado de ataque que nao existia. Guarda tambem que o Coracao tem as
## duas fases com material proprio.
func teste_9h1_criaturas_com_movimento() -> void:
	var man: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/art/regions/region_01_forest/enemies/production/enemy_production_manifest.json"))
	_ok(man is Dictionary, "9H.1: manifesto dos inimigos ilegivel")
	if not (man is Dictionary):
		return
	var inimigos: Dictionary = (man as Dictionary).get("inimigos", {})
	_ok((man as Dictionary).has("execucao_9h1"),
		"9H.1: o manifesto nao declara o passe de movimento")
	for id in inimigos:
		var anims: Dictionary = (inimigos[id] as Dictionary).get("animacoes", {})
		for estado in anims:
			var spec: Dictionary = anims[estado]
			var frames: Array = spec.get("frames", [])
			var unicos := {}
			for f in frames:
				unicos[String((f as Dictionary).get("sha256", ""))] = true
				var ficheiro := String((f as Dictionary)["ficheiro"])
				var cam: String = ficheiro if ficheiro.begins_with("res://") 					else "%s/%s" % [DIR_INIMIGOS_9H1, ficheiro]
				_ok(ResourceLoader.exists(cam), "9H.1: falta o frame %s" % cam)
			if String(spec.get("origem", "")) == "DERIVED_9H1":
				_ok(frames.size() >= 7,
					"9H.1: %s/%s so tem %d frames" % [id, estado, frames.size()])
				_ok(unicos.size() >= 5,
					"9H.1: %s/%s tem %d frames mas so %d desenhos"
						% [id, estado, frames.size(), unicos.size()])
	for id in ["ghorak", "morvanna", "rainha_aracnidea", "entrevane"]:
		var anims: Dictionary = (inimigos.get(id, {}) as Dictionary).get("animacoes", {})
		for estado in ["idle", "run", "attack", "hit", "dead"]:
			_ok(anims.has(estado), "9H.1: o guardiao %s nao tem %s" % [id, estado])
	var coracao: Dictionary = (inimigos.get("coracao_putrefacto", {}) as Dictionary).get("animacoes", {})
	for estado in ["idle", "attack", "idle_f2", "attack_f2"]:
		_ok(coracao.has(estado), "9H.1: o Coracao nao tem %s" % estado)
	# as duas fases tem de ser MATERIAL DIFERENTE, nao a mesma tira
	var f1: Array = (coracao.get("idle", {}) as Dictionary).get("frames", [])
	var f2: Array = (coracao.get("idle_f2", {}) as Dictionary).get("frames", [])
	var sha1 := "a" if f1.is_empty() else String((f1[0] as Dictionary).get("sha256", "a"))
	var sha2 := "b" if f2.is_empty() else String((f2[0] as Dictionary).get("sha256", "b"))
	_ok(sha1 != sha2, "9H.1: as duas fases do Coracao sao o mesmo frame")


## O selector tem tema POR REGIAO, a Regiao I tem pele propria, as outras
## caem no neutro -- e os bloqueios nao mudaram com nada disto.
func teste_9h1_tema_do_seletor() -> void:
	_ok(TemaRegiao.tem_autoridade(0), "9H.1: a Regiao I devia ter pele propria")
	var estado := TemaRegiao.estado()
	_ok((estado["com_autoridade"] as Array).size() == 1,
		"9H.1: so a Regiao I tem autoridade visual -- nao se inventam as outras")
	_ok((estado["sem_autoridade"] as Array).size() == 19,
		"9H.1: as 19 regioes sem arte deviam estar marcadas")
	_ok(String(estado["nota"]) == TemaRegiao.SEM_AUTORIDADE,
		"9H.1: falta a marca REGION SELECTOR THEME AUTHORITY MISSING")
	for peca in ["fundo_seletor", "anel_normal", "anel_chefe", "painel_detalhe",
			"aba_atual", "botao_jogar", "ficha_nivel"]:
		var r1 := TemaRegiao.textura(peca, 0)
		var neutra := TemaRegiao.textura(peca, 4)
		_ok(r1 != null and neutra != null, "9H.1: falta a peca %s" % peca)
		_ok(r1 != neutra, "9H.1: %s e igual na Regiao I e numa regiao neutra" % peca)
	var t := TemaRegiao.do_indice(0)
	var p: Color = t["primaria"]
	_ok(p.g > p.r and p.g > p.b, "9H.1: a cor da Regiao I nao e verde")
	var a: Color = t["acento"]
	_ok(a.r > a.g and a.b > a.g, "9H.1: o acento da Regiao I nao e magenta")
	# estrutura igual para todas: 20 regioes x 5 niveis, bloqueios intactos
	_ok(EstadoJogo.REGIOES.size() == 20, "9H.1: deviam ser 20 regioes")
	for r in EstadoJogo.REGIOES.size():
		_ok((EstadoJogo.REGIOES[r]["niveis"] as Array).size() == 5,
			"9H.1: a regiao %d nao tem 5 niveis" % (r + 1))
		var d := TemaRegiao.do_indice(r)
		for campo in ["primaria", "primaria_clara", "acento", "veu", "trilho",
				"trilho_brilho", "motivo"]:
			_ok(d.has(campo), "9H.1: o tema da regiao %d nao tem %s" % [r + 1, campo])


## O REPOR do editor de layout tem de APAGAR o ficheiro, nao so' repor os
## controlos no ecra. Apanhado na prova do Web (9H.1): o ecra voltava ao
## sitio e o `layout_toque.json` ficava em IndexedDB com os valores antigos,
## portanto na recarga seguinte voltava tudo. A causa era `globalize_path()`
## no export Web.
func teste_9h1_repor_layout_apaga_mesmo() -> void:
	var antes := LayoutToque.existe()
	var copia := LayoutToque.carregar() if antes else {}
	var demo := {"joystick": {"x": 0.4, "y": 0.8, "r": 0.17},
		"botoes": {"saltar": {"x": 0.8, "y": 0.7, "r": 0.11}},
		"pausa": {"x": 0.97, "y": 0.14, "r": 0.04}}
	_ok(LayoutToque.guardar(demo), "9H.1: nao gravou o layout de teste")
	_ok(LayoutToque.existe(), "9H.1: o layout gravado devia existir")
	var relido := LayoutToque.carregar()
	_ok(relido.get("joystick", {}) == demo["joystick"],
		"9H.2: guardar e reler perdeu a posição do joystick")
	_ok(relido.get("botoes", {}) == demo["botoes"],
		"9H.2: guardar e reler perdeu o layout dos botões")
	_ok(LayoutToque.apagar(), "9H.1: `apagar()` devia devolver true")
	_ok(not LayoutToque.existe(),
		"9H.1: REPOR deixou o ficheiro no disco -- o layout voltava na recarga")
	_ok(LayoutToque.carregar().is_empty(),
		"9H.2: reler após REPOR devia devolver o layout de fábrica")
	if antes and not copia.is_empty():
		LayoutToque.guardar(copia)


## Execution 9H.7: NITIDEZ do fundo da Região I e CONTEÚDO dos 5 níveis.
##
## 9H.7B: a escala mede a composição, não a nitidez. Fontes pequenas
## ampliadas por Lanczos continuam interpoladas mesmo a ~1:1 no GPU.
## A pipeline conserva a fonte original com transições antialiasadas;
## a melhoria visual é comprovada separadamente no renderer/EXE L1 e L5.
##
## Conteúdo: cada nível tem de ter a sua variante da prancha 08 a LER. Mede-se
## pelas peças montadas: as ruínas no pico no L3 ("Ruínas Antigas"), as
## cascatas no pico no L4 ("Cascatas e Abismos") e a corrupção a subir até ao
## L5 ("Heart Tree Próximo"). A moldura do primeiro plano (vinhas) e os raios
## de luz volumétricos da prancha têm de estar montados nos cinco.
func teste_execution_9h7_fundo_regiao1() -> void:
	const ZOOM := 1.4        # camera_tremor.gd, ZOOM_BASE
	const LIMITE := 4.8      # limite da composição original, sem ampliar o quad
	var niveis := ["res://scenes/levels/Floresta_Putrefata.tscn",
		"res://scenes/levels/Pantano_dos_Sussurros.tscn",
		"res://scenes/levels/Ninho_da_Viuva_Negra.tscn",
		"res://scenes/levels/A_Arvore_que_Chora.tscn",
		"res://scenes/levels/Coracao_da_Floresta.tscn"]
	var corrupcao: Array[int] = []
	var ruinas: Array[int] = []
	var cascatas: Array[int] = []
	for i in niveis.size():
		var nivel := (load(niveis[i]) as PackedScene).instantiate()
		get_tree().root.add_child(nivel)
		# `_montar_primeiro_plano` (e com ele as vinhas) é `call_deferred`:
		# aguarda também os quatro frames dos checkpoints antes de libertar.
		for _frame in 8:
			await get_tree().process_frame
		var alvo := nivel.get_node_or_null("Region1HybridVisualTarget")
		_ok(alvo != null, "9H.7: L%d sem Region1HybridVisualTarget" % (i + 1))
		if alvo == null:
			nivel.free()
			continue
		# --- nitidez: nenhuma peça de fundo acima do limite -----------------
		var pior := 0.0
		var pior_nome := ""
		var em_fonte := 0
		for camada in alvo.get_children():
			if not camada is Node2D:
				continue
			for sp in camada.get_children():
				if not sp is Sprite2D or sp.texture == null:
					continue
				var amp: float = absf(sp.scale.x) * ZOOM
				if amp > pior:
					pior = amp
					pior_nome = "%s/%s" % [camada.name, sp.texture.resource_path.get_file()]
				if not sp.texture.resource_path.contains("_hd_x"):
					em_fonte += 1
					# EXCEÇÃO: um feixe de luz volumétrica é um gradiente em
					# blend aditivo -- não tem textura com grelha para
					# conservar, e a amostragem alinhada não lhe faz nada
					# senão tirar-lhe a suavidade. A regra é para ARTE
					# ampliada, não para luz.
					var soma := sp.material as CanvasItemMaterial
					if soma != null and soma.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD:
						continue
					var mat := sp.material as ShaderMaterial
					_ok(mat != null and mat.get_shader_parameter("conservar_texel") == true,
						"9H.7B: fonte ampliada sem amostragem nítida [L%d %s/%s]" % [
							i + 1, camada.name, sp.texture.resource_path.get_file()])
		_ok(pior <= LIMITE, "9H.7: L%d amplia %.2fx no ecrã em %s (máximo %.1f)"
			% [i + 1, pior, pior_nome, LIMITE])
		_ok(em_fonte >= 20, "9H.7B: L%d não conserva as fontes originais (%d)" % [i + 1, em_fonte])
		# --- conteúdo: moldura e efeitos da prancha montados ----------------
		# A moldura de vinhas do primeiro plano: nos perfis que montam o passe
		# Hybrid (9H.12E no L1, 9H.17 no L2) ela vem da camada `*_frente`, com
		# as peças nativas do kit, e não do `VinhasFrente` da prancha 08. O
		# que o teste guarda é que HÁ moldura -- não de que ficheiro veio.
		var frente_hybrid := alvo.get_node_or_null("HybridL%d_frente" % (i + 1))
		_ok(alvo.get_node_or_null("VinhasFrente") != null
				or (frente_hybrid != null and frente_hybrid.get_child_count() >= 4),
			"9H.7: L%d sem as vinhas do primeiro plano" % (i + 1))
		_ok(alvo.get_node_or_null("RaiosLuz") != null,
			"9H.7: L%d sem os raios de luz volumétricos da 08" % (i + 1))
		# --- conteúdo: quanto há de cada identidade -------------------------
		# 9H.17 CONTINUATION: a contagem deixou de depender do nome das camadas
		# do legado. A Regiao I inteira passou ao passe Hybrid, que monta
		# `HybridL*_ruinas` / `_longe` / `_quedas` / `_corrupcao` em vez de
		# `Camada3Distante` / `Camada2Floresta` / `Camada2Corrupcao` -- e com o
		# nome fixo esta auditoria media zero em todos os niveis e passava a
		# acusar o que nao havia. O CONTRATO nao muda (os limiares abaixo sao os
		# mesmos): muda so onde se procura. Ver `_contar_identidade`.
		corrupcao.append(_contar_identidade(alvo, "corrupcao"))
		ruinas.append(_contar_identidade(alvo, "ruinas"))
		cascatas.append(_contar_identidade(alvo, "cascatas"))
		nivel.free()
	# A corrupção sobe do L1 ao L5 (0,25 -> 1,0 nos perfis da 08). O mínimo
	# absoluto é o que impede a asserção de passar por vacuidade: com o L1 a
	# zero, "L5 > 2 x L1" é verdade com um único cristal no nível todo, e o
	# ecrã continuava vazio -- foi exactamente a queixa do Game Master.
	_ok(corrupcao[4] >= 12 and corrupcao[4] > corrupcao[0] * 2,
		"9H.7: a corrupção não escala L1->L5 ou é fraca no L5 (%s)" % str(corrupcao))
	# O L3 é o nível das ruínas e o L4 o das cascatas -- e ambos com peças
	# suficientes para se ler ao atravessar o nível, não uma ou duas.
	_ok(ruinas[2] == ruinas.max() and ruinas[2] >= 14,
		"9H.7: o L3 não é o nível das ruínas, ou tem poucas (%s)" % str(ruinas))
	_ok(cascatas[3] == cascatas.max() and cascatas[3] >= 14,
		"9H.7: o L4 não é o nível das cascatas, ou tem poucas (%s)" % str(cascatas))
	# As peças em HD estão no manifesto do produtor, com o SHA certo.
	var man: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/art/regions/region_01_forest/production/nitidez_9h7_manifest.json"))
	_ok(man is Dictionary and (man["pecas"] as Dictionary).size() >= 21,
		"9H.7: manifesto da nitidez em falta ou incompleto")
	# O shader repõe o `modulate` (ver `nitidez_fundo.gdshader`): sem isto o
	# fundo da Região I é desenhado sem a tinta de mood nem os alfas das
	# camadas, e foi metade do ar errado que o Game Master viu.
	var glsl := FileAccess.get_file_as_string("res://assets/shaders/nitidez_fundo.gdshader")
	_ok(glsl.contains("modulacao = COLOR") and glsl.contains("COLOR = c * modulacao"),
		"9H.7: o shader de nitidez voltou a atirar o modulate fora")


## Peças de identidade de um nível da Região I, em TODAS as camadas do alvo.
##
## Uma peça declara o que é na meta `peca` (o passe Hybrid, que a escreve em
## `_peca`); as camadas do legado não a têm e são reconhecidas pelo nome do
## ficheiro, como antes. Cada sprite conta UMA vez: a meta manda, e só quem
## não a tem cai na regra do nome.
const IDENTIDADE := {
	"corrupcao": [["cristais"], "cristal"],
	"ruinas": [["arco", "arco_partido", "torres"], "ruina"],
	"cascatas": [["cascata"], "cascata"],
}

func _contar_identidade(alvo: Node, categoria: String) -> int:
	var regra: Array = IDENTIDADE[categoria]
	var metas: Array = regra[0]
	var nome_legado: String = regra[1]
	var n := 0
	for camada in alvo.get_children():
		if not camada is Node2D:
			continue
		for sp in camada.get_children():
			if not sp is Sprite2D or sp.texture == null:
				continue
			if sp.has_meta("peca"):
				if metas.has(str(sp.get_meta("peca"))):
					n += 1
			elif sp.texture.resource_path.get_file().contains(nome_legado):
				n += 1
	return n


## Quantas peças de uma camada têm `parte` no nome do ficheiro da textura.
func _contar_pecas(camada: Node, parte: String) -> int:
	if camada == null:
		return 0
	var n := 0
	for sp in camada.get_children():
		if sp is Sprite2D and sp.texture != null 				and sp.texture.resource_path.get_file().contains(parte):
			n += 1
	return n


## 9H.17 CONTINUATION -- O NOVO JOGO NAO PODE APAGAR A CAMPANHA SOZINHO.
##
## A confirmacao em dois passos ja existia. O que nao existia era o FIM do
## estado armado: `_armado` so era limpo dentro das accoes, nunca ao navegar.
## Armava-se o NOVO JOGO, passeava-se pelo menu, e a campanha morria a`
## primeira tecla de volta -- sem segundo aviso. Foi assim que o QA desta
## sessao apagou o save do Game Master (reposto por hash a seguir).
##
## O que este teste guarda nao e a implementacao, e a GARANTIA: depois de
## sair do botao, uma unica confirmacao nunca chega para destruir nada.
func teste_9h17_novo_jogo_desarma_ao_sair() -> void:
	var menu = load("res://scenes/ui/MenuInicial.tscn").instantiate()
	get_tree().root.add_child(menu)
	await get_tree().process_frame
	# fingir que HA campanha guardada, sem tocar no ficheiro de save
	var indice_real: int = EstadoJogo.indice_nivel
	EstadoJogo.indice_nivel = 3
	_ok(EstadoJogo.ha_progresso(), "9H.17: o cenario do teste nao tem progresso")

	var botoes: Dictionary = menu.get("_botoes")
	var novo: Button = botoes["novo"]
	var opcoes: Button = botoes["opcoes"]

	# 1.o toque: arma, avisa, e NAO reinicia
	novo.grab_focus()
	await get_tree().process_frame
	novo.pressed.emit()
	await get_tree().process_frame
	_ok(str(menu.get("_armado")) == "novo",
		"9H.17: o NOVO JOGO nao pediu confirmacao com campanha guardada")
	_ok(EstadoJogo.indice_nivel == 3,
		"9H.17: o 1.o toque no NOVO JOGO ja apagou a campanha")

	# sair do botao TEM de desarmar -- e o arrependimento do jogador
	opcoes.grab_focus()
	await get_tree().process_frame
	_ok(str(menu.get("_armado")) == "",
		"9H.17: o NOVO JOGO fica armado depois de a seleccao sair do botao")

	# de volta: tem de voltar a pedir confirmacao, nao destruir
	novo.grab_focus()
	await get_tree().process_frame
	novo.pressed.emit()
	await get_tree().process_frame
	_ok(EstadoJogo.indice_nivel == 3,
		"9H.17: voltar ao NOVO JOGO apagou a campanha sem novo aviso")
	_ok(str(menu.get("_armado")) == "novo",
		"9H.17: o regresso ao NOVO JOGO nao voltou a armar")

	EstadoJogo.indice_nivel = indice_real
	menu.queue_free()


## 9H.17 C -- CONTRATO DE MOBILIDADE DA REGIAO I. Duas coisas que se partem
## caladas e so' aparecem a` 3.a hora de playtest:
##   1. o salto duplo tem de ter UMA porta de entrada na campanha (nao tinha
##      nenhuma: as `HABILIDADES_INICIAIS` foram esvaziadas e ninguem lhe deu
##      outra), e essa porta e' o chefe do nivel 5;
##   2. a Jornada dos niveis 1-5 tem de ser desenhada para o salto SIMPLES.
##      O tecto do salto duplo (104 px) esta' acima do tecto FISICO do salto
##      simples, medido em `tests/run_alcance_9h17.tscn` (entre 80 e 88 px).
func teste_9h17_contrato_de_mobilidade_regiao1() -> void:
	var estado := EstadoJogoScript.new()
	_ok(not estado.HABILIDADES_INICIAIS.has("salto_duplo"),
		"9H.17: o salto duplo nao pode vir de borla no arranque")
	estado.free()
	var niv := load("res://scripts/nivel_com_chefe.gd") as GDScript
	var tabela: Dictionary = niv.HABILIDADE_DO_CHEFE
	_ok(String(tabela.get(4, "")) == "salto_duplo",
		"9H.17: o chefe do nivel 5 (indice 4) deixou de dar o salto duplo")
	for i in 4:
		_ok(not tabela.has(i),
			"9H.17: o nivel %d larga uma habilidade e a Regiao I e' sem salto duplo" % (i + 1))
	# A Jornada: tecto por nivel, e a envolvente medida a bater certo com ela.
	var g := load("res://scripts/gerador_corredor.gd") as GDScript
	_ok(int(g.NIVEL_SALTO_DUPLO) == 5,
		"9H.17: o primeiro nivel que pode exigir salto duplo deixou de ser o 6")
	_ok(float(g.SUBIDA_SIMPLES) <= 64.0,
		"9H.17: o degrau da Regiao I passou dos 64 px (medido: falha aos 88)")
	_ok(float(g.SUBIDA_SIMPLES) < float(g.SUBIDA_MAX),
		"9H.17: o tecto do salto simples nao pode ser o do salto duplo")
	# A envolvente MEDIDA. Se alguem mexer nestes numeros sem voltar a correr
	# o `run_alcance_9h17.tscn`, e' aqui que se da' por isso.
	# (o 2.o argumento e' o TECTO em uso, e uma subida acima do tecto e' -1 --
	# por isso a tabela prova-se com o tecto aberto nos 80, o limite fisico)
	_ok(g.vao_possivel(0.0, 80.0) == 140.0
			and g.vao_possivel(64.0, 80.0) == 110.0
			and g.vao_possivel(72.0, 80.0) == 80.0
			and g.vao_possivel(80.0, 80.0) == 60.0
			and g.vao_possivel(88.0, 80.0) < 0.0
			and g.vao_possivel(120.0, g.SUBIDA_SIMPLES) < 0.0,
		"9H.17: a tabela da envolvente de salto deixou de bater com a medicao")


## GATE 1 -- o NaN do N06 (Super-Process A2, 18 set 2026).
##
## Em 3 das 9 runs do bot human-like no N06 a posicao da Koliani foi NaN em
## pelo menos um frame. A causa NAO era do nivel nem do vento: o `_hitstop`
## punha `Engine.time_scale = 0.0`, o Godot passa `physics_step * time_scale`
## ao servidor de fisica, e a integracao de um corpo cinematico
## (`AnimatableBody2D` com `sync_to_physics`) calcula-lhe a velocidade por
## `motion / passo`. Parada e com passo zero isso e' 0/0 = NaN; quem estiver
## EM CIMA le' essa velocidade em `move_and_slide()` e sai de la' com
## `global_position` a NaN.
##
## Este teste monta o caso minimo -- plataforma-corrente + Koliani em cima +
## a escala de tempo do hitstop -- e falha com o valor antigo (0.0).
## O ESPAÇO é `saltar` E `ui_accept`. Se um botão da barra Dev ficar com o
## foco (basta um clique de rato), cada salto volta a carregá-lo: abria o
## selector de níveis e o salto seguinte escolhia um nível -- em jogo lê-se
## como "no DEV MODE o espaço dá reset ao nível". Os botões que ficam por
## cima do jogo não podem aceitar foco.
func teste_dev_barra_salto_nao_abre_seletor() -> void:
	var antes := EstadoJogo.para_dicionario().duplicate(true)
	var era_dev := EstadoJogo.modo_dev
	if not era_dev:
		EstadoJogo.ativar_modo_dev()
	var barra := preload("res://scenes/ui/DevBarra.tscn").instantiate()
	add_child(barra)
	await get_tree().process_frame

	_ok(barra.get_node_or_null("BotaoTopo") != null,
		"DEV MODE: a barra Dev nao se montou -- o teste nao esta' a medir"
		+ " o caso que devia")
	for nome in ["BotaoTopo", "BotaoFlymode"]:
		var b := barra.get_node_or_null(nome) as Button
		if b == null:
			continue
		_ok(b.focus_mode == Control.FOCUS_NONE,
			"DEV MODE: `%s` aceita foco -- o ESPACO (saltar == ui_accept)"
			% nome + " volta a carregar nele em vez de saltar")

	# e com o painel fechado, um `ui_accept` sintetico nao pode abri-lo.
	# Se o botao ACEITAR foco, damo-lo primeiro -- e' exactamente o que um
	# clique de rato faz, e sem isso o teste nao reproduzia a queixa.
	var painel := barra.get("_painel") as Control
	# O PAINEL FICAR INVISIVEL NAO CHEGA COMO PROVA -- e' esse o ponto cego
	# que deixou a queixa viva depois de `7a4e586a`. O `SeletorNiveis` vive
	# dentro do painel e trata `ui_accept` no `_unhandled_input`, que em
	# Godot NAO se cala com `visible = false`. Resultado: o ESPACO confirmava
	# o nivel e recarregava-o com o painel invisivel o tempo todo, e o teste
	# passava. Agora vigia-se o SINAL, que e' o que leva mesmo a` troca de
	# cena (`_ir_para` -> `Transicao.fechar_e(change_scene_to_file)`).
	var escolheu := [false]
	var seletor := barra.get("_seletor") as Node
	_ok(seletor != null, "DEV MODE: a barra Dev nao montou o selector")
	if seletor:
		seletor.connect("escolhido", func(_i: int) -> void: escolheu[0] = true)
	var nivel_antes: int = EstadoJogo.indice_nivel
	var topo := barra.get_node_or_null("BotaoTopo") as Button
	if topo and topo.focus_mode != Control.FOCUS_NONE:
		topo.grab_focus()
		await get_tree().process_frame
	# tecla a serio (nao `Input.action_press`): so' um InputEventKey passa
	# pelo caminho de GUI que activa um botao com foco.
	for pressionada in [true, false]:
		var tecla := InputEventKey.new()
		tecla.physical_keycode = KEY_SPACE
		tecla.keycode = KEY_SPACE
		tecla.pressed = pressionada
		Input.parse_input_event(tecla)
		await get_tree().process_frame
		await get_tree().process_frame
	_ok(painel == null or not painel.visible,
		"DEV MODE: o ESPACO abriu o selector de niveis por cima do jogo")
	_ok(not escolheu[0],
		"DEV MODE: o ESPACO confirmou um nivel no selector ESCONDIDO -- e'"
		+ " isto que em jogo se le como `o espaco da' reset ao nivel`")
	_ok(EstadoJogo.indice_nivel == nivel_antes,
		"DEV MODE: o ESPACO mudou o nivel da sessao")
	# e uma troca de cena agendada pelo fade levaria o corredor de testes
	# atras -- se alguma chegou a ser pedida, corta-se aqui.
	var fade_dev: Tween = Transicao.get("_tween")
	if fade_dev and fade_dev.is_valid():
		fade_dev.kill()

	# se a falha acima acontecer, o painel deixou a arvore EM PAUSA e os
	# testes seguintes mediam um jogo parado -- nao deixar isso acontecer.
	get_tree().paused = false
	barra.queue_free()
	await get_tree().process_frame
	if not era_dev:
		EstadoJogo.desativar_modo_dev()
	_ok(EstadoJogo.para_dicionario() == antes,
		"DEV MODE: o teste da barra Dev mexeu no estado do jogo")


## DEV MODE SEM PIN (19 set 2026, pedido do Paulo). O botão do menu entrava
## num painel de quatro dígitos; agora entra em DEV MODE e ponto. A porta da
## build continua a ser `koliani/qa/entrada_dev` -- é esse interruptor que
## decide se o botão sequer existe, e é ele que fica `false` numa build de
## loja. Um PIN escrito no código-fonte de um jogo público nunca foi uma
## credencial; era atrito para quem desenvolve.
##
## Este teste guarda as duas metades: que ACTIVA já, e que não sobrou nada do
## painel (nó, campo de texto ou membro órfão). O harness dedicado
## `tests/run_dev_acesso.gd` cobre o mesmo com os catálogos i18n.
func teste_dev_mode_sem_pin() -> void:
	# o retrato da campanha tira-se com o Dev JA' desligado -- e' esse o
	# estado a que se volta no fim, aconteca o que acontecer no meio.
	var era_dev := EstadoJogo.modo_dev
	if era_dev:
		EstadoJogo.desativar_modo_dev()
	var antes := EstadoJogo.para_dicionario().duplicate(true)

	var menu: Control = preload("res://scenes/ui/MenuInicial.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	var dev := menu.get("_dev") as Button
	_ok(dev != null and dev.visible,
		"DEV MODE: o botão do menu devia estar visível numa build de QA")
	_ok(not EstadoJogo.modo_dev, "DEV MODE: o menu não pode entrar em Dev sozinho")

	# tudo o que interessa em `_ao_dev_mode` é síncrono: quando o `pressed`
	# volta, o modo dev já está ligado. Por isso NÃO se espera um frame aqui
	# -- esperar só daria tempo ao fade de trocar de cena.
	if dev != null:
		dev.pressed.emit()
	_ok(EstadoJogo.modo_dev,
		"DEV MODE: carregar no botão devia activar já, sem PIN nem painel")
	_ok(menu.find_child("AcessoDev", true, false) == null,
		"DEV MODE: nasceu um painel de acesso (`AcessoDev`) -- o PIN voltou")
	_ok(_sem_campo_de_texto(menu),
		"DEV MODE: o menu tem um campo de texto -- o PIN voltou")
	for membro in ["_pin_painel", "_pin_campo", "_pin_erro", "_pin_titulo",
			"_pin_entrar", "_pin_cancelar"]:
		_ok(menu.get(membro) == null, "DEV MODE: membro órfão do PIN: " + membro)

	# `_ao_dev_mode` acaba em `Transicao.fechar_e`, que ~0.22 s depois trocava
	# a cena -- e levava o corredor de testes com ela. Corta-se o fade aqui.
	var fade: Tween = Transicao.get("_tween")
	if fade and fade.is_valid():
		fade.kill()

	menu.queue_free()
	await get_tree().process_frame
	# o botao LIGOU o Dev, haja o que houver antes -- por isso desliga-se
	# sempre, e so' depois se compara. (Com `if not era_dev` ficava ligado
	# justamente no caso em que ja' estava, e a comparacao falhava.)
	EstadoJogo.desativar_modo_dev()
	_ok(EstadoJogo.para_dicionario() == antes,
		"DEV MODE: o teste do acesso Dev mexeu no estado do jogo")
	if era_dev:
		EstadoJogo.ativar_modo_dev()


## True se não há um único `LineEdit` na sub-árvore.
func _sem_campo_de_texto(no: Node) -> bool:
	if no is LineEdit:
		return false
	for f in no.get_children():
		if not _sem_campo_de_texto(f):
			return false
	return true


func teste_gate1_hitstop_nao_gera_nan() -> void:
	_ok(Koliani.HITSTOP_ESCALA_TEMPO > 0.0,
		"GATE 1: o hitstop nao pode pôr `Engine.time_scale` a zero"
		+ " (passo de fisica zero -> velocidade cinematica 0/0 = NaN)")

	var raiz := Node2D.new()
	add_child(raiz)
	var plat: Node2D = preload("res://scenes/actors/PlataformaCorrente.tscn").instantiate()
	plat.set("modo", "horizontal")
	plat.set("amplitude", 90.0)
	plat.set("periodo", 3.4)
	plat.set("largura", 120.0)
	plat.position = Vector2(0.0, 200.0)
	raiz.add_child(plat)
	var k: Koliani = preload("res://scenes/actors/Koliani.tscn").instantiate()
	k.position = Vector2(0.0, 150.0)
	raiz.add_child(k)

	# deixar assentar em cima da laje antes de mexer no tempo
	for _i in 40:
		await get_tree().physics_frame
	var pousada := k.is_on_floor()

	var antes := Engine.time_scale
	Engine.time_scale = Koliani.HITSTOP_ESCALA_TEMPO
	for _i in 8:
		await get_tree().physics_frame
	var p := k.global_position
	var v := k.velocity
	Engine.time_scale = antes

	_ok(pousada,
		"GATE 1: a Koliani nao chegou a pousar na plataforma -- o teste nao"
		+ " esta' a medir o caso que devia")
	_ok(is_finite(p.x) and is_finite(p.y),
		"GATE 1: posicao nao-finita depois do hitstop em cima de um"
		+ " `AnimatableBody2D`: %s" % str(p))
	_ok(is_finite(v.x) and is_finite(v.y),
		"GATE 1: velocidade nao-finita depois do hitstop em cima de um"
		+ " `AnimatableBody2D`: %s" % str(v))
	raiz.queue_free()


## =====================================================================
##  REGIÃO III -- TORRE DOS ECOS (N11-N15)
##
##  Contrato: docs/art_direction/regions/region_03/
##  REGION03_VISUAL_GAMEPLAY_CONTRACT.md
##
##  ARMADILHA: as chaves i18n `level.nXX` usam o indice 0-BASED de
##  `EstadoJogo.NIVEIS`. Os niveis N11-N15 que o jogador ve' sao as
##  chaves `level.n10` a `level.n14`. Quem mexer em `level.n11` a pensar
##  no N11 esta' a estragar o N12.
## =====================================================================

## Indice de `EstadoJogo.NIVEIS` do primeiro nivel da Regiao III (o N11).
const R3_BASE := 10


func _json_de(caminho: String) -> Dictionary:
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		_ok(false, "devia existir: %s" % caminho)
		return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (d is Dictionary):
		_ok(false, "devia ser um objecto JSON: %s" % caminho)
		return {}
	return d as Dictionary


func teste_r3_nomes_canonicos() -> void:
	# Os nomes vem das pranchas APPROVED e sao canone.
	var esperado := {
		"level.n10": "Entrance of Echoes",
		"level.n11": "Vertical Galleries",
		"level.n12": "Ancient Mechanisms",
		"level.n13": "The Belfry",
		"level.n14": "The Summit of Echoes",
		"boss.vyrak": "Vyrak, the Voice of Echoes",
	}
	var en: Dictionary = _json_de("res://assets/i18n/en.json")
	for chave: String in esperado:
		_ok(String(en.get(chave, "")) == String(esperado[chave]),
			"R3: `%s` devia ser \"%s\", esta' \"%s\"" % [
				chave, esperado[chave], en.get(chave, "")])
	# O Vyrak nao pode voltar a ser dragao: a prancha mostra um guardiao
	# humanoide de sinos, e o texto antigo do projeto e' que estava errado.
	_ok(not String(en.get("boss.vyrak", "")).to_lower().contains("dragon"),
		"R3: o Vyrak canonico nao e' um dragao")
	# As 6 linguas tem de ter as MESMAS chaves.
	var base := _json_de("res://assets/i18n/en.json").keys()
	for lang: String in ["pt", "es", "fr", "de", "zh"]:
		var d: Dictionary = _json_de("res://assets/i18n/%s.json" % lang)
		for chave: String in esperado:
			_ok(d.has(chave), "R3: falta `%s` no %s.json" % [chave, lang])
		_ok(d.size() == base.size(),
			"R3: %s.json tem %d chaves, o en.json tem %d" % [
				lang, d.size(), base.size()])


## O NOME do chefe ja' estava tratado; o que o jogador LE' a` volta dele nao
## estava. A pista do pico contava o Vyrak como dragao ("uma escama caida...
## o dragao deitou-se e deixou-a passar-lhe pelo pescoco") e o equipamento
## chamava-se Escamas e Presa -- anatomia de dragao, nas seis linguas. Nada
## disso e' o guardiao de sinos da prancha aprovada.
##
## As CHAVES continuam a chamar-se `...escama...` e `...presa...` de
## proposito: mudar a chave partia o `equipamento.gd` (que guarda o `id`
## separado) e os saves. O que conta e' o que se le' no ecra.
func teste_r3_vyrak_sem_lore_de_dragao() -> void:
	var proibidas := ["dragon", "dragão", "dragao", "dragón", "drache",
		"scale", "escama", "écaille", "schuppe", "fang", "presa", "croc",
		"reißzahn", "巨龙", "龙", "鳞"]
	var chaves := ["boss.vyrak", "clue.pico_escama_de_vyrak.title",
		"clue.pico_escama_de_vyrak.body", "gear.w.presa_de_vyrak",
		"gear.a.escamas_de_vyrak"]
	for lang: String in ["en", "pt", "es", "fr", "de", "zh"]:
		var d: Dictionary = _json_de("res://assets/i18n/%s.json" % lang)
		for chave: String in chaves:
			var texto := String(d.get(chave, "")).to_lower()
			_ok(not texto.is_empty(),
				"R3: `%s` vazio no %s.json" % [chave, lang])
			for palavra: String in proibidas:
				_ok(not texto.contains(palavra),
					"R3: `%s` no %s.json ainda apresenta o Vyrak como dragao"
					% [chave, lang] + " (encontrado: \"%s\")" % palavra)
	# E o nome tem de estar MESMO traduzido: as quatro linguas de fora do
	# en/pt ficaram com a string inglesa quando o chefe foi renomeado.
	var en2: Dictionary = _json_de("res://assets/i18n/en.json")
	for lang: String in ["pt", "es", "fr", "de", "zh"]:
		var d: Dictionary = _json_de("res://assets/i18n/%s.json" % lang)
		_ok(String(d.get("boss.vyrak", "")) != String(en2.get("boss.vyrak", "")),
			"R3: `boss.vyrak` no %s.json ficou por traduzir" % lang)


func teste_r3_um_so_chefe_na_regiao() -> void:
	# O canone da Regiao III admite UM confronto -- o Vyrak, no N15. Os
	# quatro encontros intermedios sao GUARDIOES, como na Regiao II.
	for i in 4:
		var chave: String = CatalogoCampanha.CHEFE_KEY[R3_BASE + i]
		_ok(chave.begins_with("guard."),
			"R3: o N%d devia ser guardiao, e' `%s`" % [11 + i, chave])
	_ok(CatalogoCampanha.CHEFE_KEY[R3_BASE + 4] == "boss.vyrak",
		"R3: o N15 devia ser `boss.vyrak`, e' `%s`" % [
			CatalogoCampanha.CHEFE_KEY[R3_BASE + 4]])
	# O Sino Vivo fica -- um chefe-sino numa torre de sinos e' canonico.
	_ok(CatalogoCampanha.CHEFE_KEY[R3_BASE] == "guard.sino_vivo",
		"R3: o Sino Vivo do N11 devia manter-se (como guardiao)")


func teste_r3_fundo_proprio_da_torre() -> void:
	# O `montanhas` tem uma camada `trees.png` de PINHEIROS: com ele, a
	# Torre dos Ecos renderizava como floresta. A regiao tem pack proprio.
	const ATM := preload("res://scripts/atmosfera.gd")
	_ok(ATM.PACKS.has("torre_ecos"), "R3: falta o pack `torre_ecos`")
	for item: Array in ATM.PACKS["torre_ecos"]:
		var cam := "res://assets/sprites/pixel/backgrounds/torre_ecos/%s" % item[0]
		_ok(ResourceLoader.exists(cam), "R3: falta a camada %s" % cam)
	for i in 5:
		var cena: PackedScene = load(EstadoJogo.NIVEIS[R3_BASE + i])
		var raiz: Node = cena.instantiate()
		var atm: Node = raiz.get_node_or_null("Atmosfera")
		_ok(atm != null and String(atm.get("fundo_pack")) == "torre_ecos",
			"R3: o N%d devia usar o pack `torre_ecos`, usa `%s`" % [
				11 + i, atm.get("fundo_pack") if atm else "<sem Atmosfera>"])
		_ok(atm != null and String(atm.get("bioma")) == "torres",
			"R3: o N%d devia ser do bioma `torres`" % [11 + i])
		raiz.free()


func teste_r3_assinatura_e_de_sinos() -> void:
	# `ASSINATURA[2]` era "vento" -- a assinatura da Regiao II. O canone
	# diz que o elemento central da Torre dos Ecos sao os SINOS.
	const GER := preload("res://scripts/gerador_corredor.gd")
	_ok(String(GER.ASSINATURA[2]) == "sinos",
		"R3: a camara de assinatura da regiao devia ser `sinos`, e' `%s`" % [
			GER.ASSINATURA[2]])
	_ok(GER.POOL_REGIAO[2].has("sinos"),
		"R3: `sinos` tem de estar na pool da regiao")


func teste_r3_niveis_carregam() -> void:
	# Apanha a falha de arranque real (o historico de "ecra preto" do N12).
	for i in 5:
		var caminho: String = EstadoJogo.NIVEIS[R3_BASE + i]
		_ok(ResourceLoader.exists(caminho), "R3: falta a cena do N%d" % [11 + i])
		var cena: PackedScene = load(caminho)
		_ok(cena != null, "R3: o N%d nao carrega" % [11 + i])
		var raiz: Node = cena.instantiate()
		get_tree().root.add_child(raiz)
		await get_tree().process_frame
		await get_tree().process_frame
		_ok(raiz.get_node_or_null("Koliani") != null,
			"R3: o N%d devia ter a Koliani" % [11 + i])
		_ok(raiz.get_node_or_null("Porta") != null,
			"R3: o N%d devia ter a saida" % [11 + i])
		raiz.queue_free()
		await get_tree().process_frame


func teste_r3_vyrak_identidade() -> void:
	var chefe: Node = load("res://scenes/actors/ChefeVyrak.tscn").instantiate()
	get_tree().root.add_child(chefe)
	await get_tree().process_frame
	_ok(String(chefe.get("rig")) == "vyrak",
		"R3: o Vyrak devia usar o rig `vyrak`")
	# A prancha poe-no a ~4x a Koliani (44 px). Ele tem alvos PROPRIOS
	# (como o Guardiao dos Ceus), por isso mede-se por ai' e nao pela
	# constante do `ChefeBase`.
	var altura := float(chefe.call("_altura_alvo"))
	_ok(altura / 44.0 >= 3.5,
		"R3: o Vyrak devia ler-se a ~4x a Koliani (%.0f px = %.2fx)" % [
			altura, altura / 44.0])
	_ok(float(chefe.get("escala_visual")) == 1.0,
		"R3: com alvos proprios o `escala_visual` deve ficar em 1.0")
	# O ciclo de combate da prancha tem DUAS fases, nao tres.
	_ok(ChefeVyrak.CICLO_F1.size() > 0 and ChefeVyrak.CICLO_F2.size() > 0,
		"R3: o Vyrak devia ter as duas rotacoes de ataque")
	# Os nove ataques nomeados na prancha existem todos.
	_ok(ChefeVyrak.ATAQUES.size() == 9,
		"R3: a prancha nomeia 9 ataques, ha' %d" % ChefeVyrak.ATAQUES.size())
	for a: int in ChefeVyrak.ATAQUES:
		var cfg: Dictionary = ChefeVyrak.ATAQUES[a]
		_ok(float(cfg["tel"]) >= 0.45,
			"R3: o ataque %d telegrafa menos de 0,45 s -- a prancha exige"
			% a + " janelas de reacao justas")
	# Os quatro da fase 2 so' podem sair na fase 2.
	for a: int in [ChefeVyrak.Atk.CHUVA_SINOS, ChefeVyrak.Atk.ESPIRAL,
			ChefeVyrak.Atk.PAREDE_ECO, ChefeVyrak.Atk.JULGAMENTO]:
		_ok(not ChefeVyrak.CICLO_F1.has(a),
			"R3: o ataque %d e' da fase 2 e esta' na rotacao da fase 1" % a)
	chefe.queue_free()
	await get_tree().process_frame


func teste_r3_vyrak_leva_dano_muda_de_fase_e_morre() -> void:
	# Harness tecnico: o bot nao consegue provar uma luta de chefe, por
	# isso prova-se aqui que o Vyrak e' atingivel, transita aos 50 % e
	# morre -- que e' o que separa "existe" de "funciona".
	var chefe: Node = load("res://scenes/actors/ChefeVyrak.tscn").instantiate()
	get_tree().root.add_child(chefe)
	await get_tree().process_frame
	var vida_max := int(chefe.get("vida"))
	_ok(vida_max > 0, "R3: o Vyrak devia arrancar com vida")

	chefe.call("receber_dano", 40, 1.0)
	await get_tree().process_frame
	_ok(int(chefe.get("vida")) < vida_max,
		"R3: o Vyrak devia levar dano (%d -> %d)" % [
			vida_max, chefe.get("vida")])

	# Bater-lhe ate' abaixo de metade tem de acender a fase 2.
	var seguranca := 0
	while int(chefe.get("vida")) > int(vida_max * 0.45) and seguranca < 400:
		chefe.call("receber_dano", 25, 1.0)
		seguranca += 1
	await get_tree().physics_frame
	await get_tree().physics_frame
	_ok(bool(chefe.get("_f2")),
		"R3: abaixo de 50 %% de vida o Vyrak devia estar na fase 2")

	# E tem de morrer -- um chefe que nao morre e' um softlock.
	seguranca = 0
	while int(chefe.get("vida")) > 0 and seguranca < 400:
		chefe.call("receber_dano", 40, 1.0)
		seguranca += 1
	await get_tree().physics_frame
	_ok(int(chefe.get("vida")) <= 0,
		"R3: o Vyrak nao morreu ao fim de %d golpes" % seguranca)
	chefe.queue_free()
	await get_tree().process_frame


func teste_r3_bestiario_canonico() -> void:
	# A auditoria mediu 0 dos 10 inimigos canonicos em N11-N15: a regiao
	# usava `xamane, wogol, olho, abutre, imp`, demonios genericos
	# herdados. Estes dez vem recortados da prancha APPROVED por
	# `tools/extrair_inimigos_regiao03.py`.
	const R3 := ["sentinela_da_torre", "acolito_do_eco", "automato_do_sino",
		"gargula_vitral", "sino_flutuante", "arqueiro_das_sombras",
		"monge_das_correntes", "espirito_do_eco", "construto_vitral",
		"corvo_do_sino"]
	for esp: String in R3:
		_ok(DemonioBase.ESPECIES.has(esp),
			"R3: a especie `%s` nao esta' registada" % esp)
		for anim: String in ["idle", "run", "attack", "hit", "dead"]:
			var cam := "res://assets/sprites/pixel/enemies/%s/%s.png" % [esp, anim]
			_ok(ResourceLoader.exists(cam), "R3: falta %s" % cam)

	const GER := preload("res://scripts/gerador_corredor.gd")
	# A pool da regiao nao pode ter nenhum demonio herdado.
	var pool: Array = GER.ESP_REGIAO[2]
	for esp: String in pool:
		_ok(R3.has(esp),
			"R3: `%s` na pool da regiao nao e' do bestiario canonico" % esp)
	# Cada um dos cinco niveis tem a sua assinatura, e sao cinco DIFERENTES
	# -- a prancha da' um inimigo principal distinto a cada nivel.
	var assin := {}
	for i in 5:
		var esp: String = GER.ESP_ASSINATURA[R3_BASE + i]
		_ok(R3.has(esp),
			"R3: a assinatura do N%d (`%s`) nao e' canonica" % [11 + i, esp])
		assin[esp] = true
	_ok(assin.size() == 5,
		"R3: os cinco niveis deviam ter assinaturas diferentes, ha' %d" % assin.size())

	# E os elites postos a' mao nas cinco cenas tambem. Os CHEFES ficam de
	# fora: vestem-se pelo `rig`, e a `especie` deles nunca chega ao ecra --
	# fica no "goblin" que e' o valor por omissao do `DemonioBase`.
	for i in 5:
		var raiz: Node = (load(EstadoJogo.NIVEIS[R3_BASE + i]) as PackedScene).instantiate()
		for n in raiz.get_children():
			if not ("especie" in n) or String(n.get("especie")) == "":
				continue
			if "rig" in n and String(n.get("rig")) != "":
				continue
			_ok(R3.has(String(n.get("especie"))),
				"R3: o elite `%s` do N%d usa `%s`, que nao e' da regiao"
				% [n.name, 11 + i, n.get("especie")])
		raiz.free()
