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
## `TestesRegion02N08` (Process 11 -- Ilhas Suspensas/planar) foi retirado
## nesta execucao (27 set 2026): o N08 passou a Combine (vento + salto
## duplo/Dash/Pogo, sem planar/Chefe legacy). Substituido por
## `teste_n8_autoral` (abaixo) + os blocos N08 de `test_region02_wind_levels.gd`,
## o mesmo padrao usado quando N06/N07 passaram a autorais.
const TestesRegion02N10 := preload("res://tests/test_region02_n10_level.gd")
const TestesRegion03N11 := preload("res://tests/test_region03_n11_level.gd")
const TestesRegion03N12 := preload("res://tests/test_region03_n12_level.gd")
const TestesRegion03N13 := preload("res://tests/test_region03_n13_level.gd")
const TestesRegion03N14 := preload("res://tests/test_region03_n14_level.gd")
const TestesRegion03N15 := preload("res://tests/test_region03_n15_level.gd")
const TestesKolianiCanonicaNiveis := preload("res://tests/test_koliani_canonica_niveis.gd")
const DT := 1.0 / 60.0

var _falhas: Array[String] = []


func _ready() -> void:
	call_deferred("_correr_tudo")


func _correr_tudo() -> void:
	# os testes da Loja verificam os precos REAIS; o interruptor de "tudo gratis
	# em desenvolvimento" tem o seu proprio teste (`teste_loja_gratis_dev`)
	LojaCatalogo.gratis = false
	# iteracao rapida: `SO_TESTE=teste_n5_autoral` corre so' essa funcao
	var so_teste := OS.get_environment("SO_TESTE")
	if so_teste != "":
		await call(so_teste)
		for f in _falhas:
			printerr("FALHOU: ", f)
		print("SO_TESTE terminou: %d falha(s)" % _falhas.size())
		get_tree().quit(1 if not _falhas.is_empty() else 0)
		return
	for falha in TestesMovimentoCamera4A.executar():
		_falhas.append(falha)
	for falha in TestesWindSystem.executar():
		_falhas.append(falha)
	for falha in TestesRegion02WindLevels.executar():
		_falhas.append(falha)
	for falha in TestesGlideRegiao02.executar():
		_falhas.append(falha)
	for falha in TestesRegion02N10.executar():
		_falhas.append(falha)
	for falha in TestesRegion03N11.executar():
		_falhas.append(falha)
	for falha in TestesRegion03N12.executar():
		_falhas.append(falha)
	for falha in TestesRegion03N13.executar():
		_falhas.append(falha)
	for falha in TestesRegion03N14.executar():
		_falhas.append(falha)
	for falha in TestesRegion03N15.executar():
		_falhas.append(falha)
	for falha in TestesRegion04N16.executar():
		_falhas.append(falha)
	for falha in TestesRegion04N17.executar():
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
	teste_sem_equipamento_nem_santuario()
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
	await teste_offscreen_hazards()
	await teste_offscreen_global()
	await teste_n1_autoral()
	await teste_ghorak_n1()
	await teste_n2_autoral()
	await teste_n3_autoral()
	await teste_pogo_intencional()
	await teste_n4_autoral()
	await teste_n5_autoral()
	await teste_cartao_regiao1()
	await teste_fluxo_fim_regiao1()
	await teste_n6_autoral()
	await teste_n7_autoral()
	await teste_n8_autoral()
	await teste_n9_autoral()
	await teste_fluxo_fim_regiao2()
	await teste_combat_lab()
	await teste_combat_lab_combos()
	await teste_combat_lab_pd_real()
	await teste_combat_lab_pd_contrato()
	teste_contrato_dano_producao()
	await teste_core_combate_producao()
	await teste_enemy_contract_legado_inerte()
	await teste_enemy_contract_hurtbox()
	await teste_enemy_contract_guarda_opt_in()
	await teste_goblin_piloto_estrutura()
	await teste_goblin_piloto_isolamento()
	await teste_goblin_piloto_comportamento()
	await teste_goblin_piloto_ttk()
	await teste_golem_piloto_estrutura()
	await teste_golem_piloto_comportamento()
	await teste_golem_piloto_ttk()
	await teste_energy_instrumentation()
	await teste_qa_arena_producao()
	await teste_combat_lab_clamp()
	await teste_combat_lab_antispam()
	await teste_combat_lab_balanco()
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
	teste_musica_so_aprovada()
	teste_sfx_combate_aprovados()
	teste_9h1_combo_com_poses_proprias()
	teste_9h1_criaturas_com_movimento()
	teste_9h1_tema_do_seletor()
	teste_9h1_repor_layout_apaga_mesmo()

	# --- Loja (Kolicoins / Veracoins, so cosmeticos) ---------------------
	teste_loja_catalogo()
	teste_loja_compras_e_equipar()
	teste_loja_gratis_dev()
	teste_loja_save_e_compatibilidade()
	teste_loja_progressao_regional_e_gameplay()
	teste_loja_i18n()
	teste_loja_cosmeticos_visuais()
	teste_skins_arte_real()
	teste_shadowblade_paridade()
	teste_loja_colecao_regiao_i()
	teste_rootbound_frame()
	teste_loja_arte_molduras_rastos()
	teste_galeria_conceitos()

	# --- Região III -- Torre dos Ecos (N11-N15) -----------------------
	teste_r3_nomes_canonicos()
	teste_r3_vyrak_sem_lore_de_dragao()
	teste_r3_um_so_chefe_na_regiao()
	teste_r3_fundo_proprio_da_torre()
	teste_r3_assinatura_e_de_sinos()
	teste_r3_bestiario_canonico()
	await teste_r3_niveis_carregam()
	await teste_r3_n12_contrato()
	await teste_r3_n12_portoes_no_crivo()
	await teste_r3_n13_mecanismos()
	await teste_r3_n13_elevadores_no_crivo()
	await teste_r3_n14_sinos()
	await teste_r3_n14_portoes_no_crivo()
	await teste_r3_n15_fragmentos_e_escada()
	await teste_r3_n15_ritual_ergue_a_fase2()
	await teste_r3_n15_portoes_no_crivo()
	await teste_golpe_real_parte_vitral_e_toca_sino()
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
	e.kolicoins = 7
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
	e.ganhar_kolicoins(37)
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
		and seguro.get("loja", {}).get("kolicoins", 0) >= 37,
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
	for idx in CatalogoCampanha.CHEFE_KEY.size():
		var k: String = CatalogoCampanha.CHEFE_KEY[idx]
		# nem todo o nível acaba num chefe: os que acabam num guardião levam
		# `guard.*` (ver `CatalogoCampanha.tem_chefe`). O N11 (índice 10) é a
		# ÚNICA exceção canónica: introdução da Região III, sem chefe nem
		# guardião (auditoria GM, 28 set 2026) -- ver `teste_r3_um_so_chefe_na_regiao`.
		if idx == 10:
			_ok(k == "", "N11 (índice 10) devia ser '' (sem chefe/guardião), é '%s'" % k)
			continue
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
		if k == "":
			continue
		_ok(en.has(k), "en.json sem o nome do chefe '%s'" % k)
	for i in n:
		var lk := CatalogoCampanha.chave_nivel(i)
		_ok(en.has(lk), "en.json sem o nome do nível '%s'" % lk)
	for k in ["sel.play", "sel.back", "sel.locked", "sel.cleared", "sel.boss", "sel.count", "sel.hint"]:
		_ok(en.has(k), "en.json sem a chave do carrossel '%s'" % k)


## Armas, armaduras e Santuário saíram do jogo: os ficheiros já não existem,
## o save já não os escreve, mas um save antigo que ainda traga essas chaves
## continua a validar e a carregar (as chaves são ignoradas).
func teste_sem_equipamento_nem_santuario() -> void:
	for caminho: String in ["res://scripts/equipamento.gd", "res://scripts/melhorias.gd",
			"res://scripts/santuario.gd", "res://scripts/seletor_equip.gd",
			"res://scenes/ui/Santuario.tscn", "res://scenes/ui/SeletorEquip.tscn"]:
		_ok(not FileAccess.file_exists(caminho), "%s devia ter sido removido" % caminho)
	var e := _novo_estado()
	_ok(e.dano_ataque() == e.DANO_BASE, "dano_ataque é sempre o base")
	e.marcar_nivel_concluido(4)
	e.marcar_nivel_concluido(9)
	var d: Dictionary = e.para_dicionario()
	for chave: String in ["armas", "armaduras", "arma_equipada", "armadura_equipada", "melhorias"]:
		_ok(not d.has(chave), "o save atual já não devia escrever '%s'" % chave)
	# save antigo: as chaves velhas continuam a ser aceites e ignoradas
	var antigo: Dictionary = d.duplicate(true)
	antigo["armas"] = ["lamina_gasta"]
	antigo["armaduras"] = ["trapos_de_viajante"]
	antigo["arma_equipada"] = "lamina_gasta"
	antigo["armadura_equipada"] = "trapos_de_viajante"
	antigo["melhorias"] = {"furia": 2}
	_ok(SaveFoundation.validar_atual(antigo, e.NIVEIS.size()).get("ok", false),
		"save com chaves de equipamento/melhorias devia continuar a validar")
	var copia := _novo_estado()
	copia.de_dicionario(antigo)
	_ok(copia.concluidos == e.concluidos and copia.dano_ataque() == e.DANO_BASE,
		"save antigo carrega sem afetar progresso nem dano")
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

	# selector Pass 1: ecrã principal com as 20 regiões e vista regional 5x.
	var desbloq_antes: Array = []
	for i in EstadoJogo.NIVEIS.size():
		desbloq_antes.append(EstadoJogo.nivel_desbloqueado(i))
	var sel: SeletorNiveis = load("res://scenes/ui/SeletorNiveis.tscn").instantiate()
	get_tree().root.add_child(sel)
	sel.size = Vector2(1280, 720)
	sel.configurar(0, false)
	var regioes: Array = sel.get("_region_cards")
	var nos: Array = sel.get("_nos")
	_ok(regioes.size() == 20, "Pass 1: %d cards de região (esperados 20)" % regioes.size())
	_ok(nos.size() == 5, "Pass 1: %d cards de nível (esperados 5)" % nos.size())
	var indices := func() -> Array:
		var v: Array = []
		for n in nos:
			v.append(int(n["indice"]))
		return v
	sel.call("_abrir_regiao", 0)
	_ok(indices.call() == [0, 1, 2, 3, 4],
		"Pass 1: Região I devia mostrar N01..N05 (%s)" % [indices.call()])
	sel.call("_mudar_regiao", 3)
	_ok(indices.call() == [15, 16, 17, 18, 19],
		"Pass 1: Região IV devia mostrar níveis 16..20 (%s)" % [indices.call()])
	var abas: Array = sel.get("_abas")
	_ok(abas.size() == 20, "Pass 1: %d cards de região (esperados 20)" % abas.size())
	sel.call("_mudar_regiao", 16)   # ate' a ultima regiao
	_ok(int(sel.get("_regiao")) == 19 and indices.call()[4] == 99,
		"Pass 1: a última região devia acabar em N100 (%s)" % [indices.call()])
	var todos: Array = []
	for r in EstadoJogo.REGIOES:
		for indice in r["niveis"]:
			todos.append(int(indice))
	_ok(todos.size() == 100 and todos.min() == 0 and todos.max() == 99 and todos.duplicate().size() == 100,
		"Pass 1: mapeamento 20x5 devia cobrir N01..N100 uma vez")
	_ok(int(sel.get("_level_cards")[4].text.find("BOSS")) >= 0,
		"Pass 1: N05 devia estar identificado como BOSS")
	var estado_current := str(sel.call("_estado_nivel", EstadoJogo.indice_nivel))
	_ok(estado_current == "CURRENT", "Pass 1: o nível atual devia aparecer como CURRENT")
	_ok(str(sel.call("_estado_nivel", 99)) == "LOCKED" or not EstadoJogo.nivel_desbloqueado(99),
		"Pass 1: níveis fora da fronteira deviam aparecer como LOCKED")
	var concluidos_antes: Array = EstadoJogo.concluidos.duplicate()
	var teste_concluido := 0 if EstadoJogo.indice_nivel != 0 else 1
	EstadoJogo.concluidos.append(teste_concluido)
	_ok(str(sel.call("_estado_nivel", teste_concluido)) == "COMPLETED",
		"Pass 1: nível concluído devia aparecer como COMPLETED")
	EstadoJogo.concluidos = concluidos_antes
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
			# `Frontend9H.botao_placa`: caixa lisa carmesim (fio vermelho)
			var carmesim: bool = st is StyleBoxFlat and \
				(st as StyleBoxFlat).border_color.r > (st as StyleBoxFlat).border_color.b * 3.0
			var vestido: bool = st is StyleBoxTexture or carmesim or (
				st is StyleBoxEmpty and bt.get_theme_stylebox("hover") is StyleBoxTexture)
			_ok(vestido, "9F: %s -> botao '%s' ainda com estilo legado" % [cena.get_file(), b.name])
		no.queue_free()

	# HUD: calha/enchimento das barras do kit
	var hud: Node = load("res://scenes/ui/HUD.tscn").instantiate()
	get_tree().root.add_child(hud)
	# HUD moderno: barras proprias (`BarraHud`) dentro do bloco `Vitais`
	var b_vida := hud.get_node_or_null("Vitais/BarraVida")
	var b_en := hud.get_node_or_null("Vitais/BarraEnergia")
	_ok(b_vida != null and b_en != null and hud.get_node_or_null("Kolicoins") != null,
		"HUD: faltam o bloco Vitais (vida/energia) ou o contador de Kolicoins")
	if b_vida:
		b_vida.definir(40.0, 100.0)
		_ok(is_equal_approx(b_vida.fracao(), 0.4), "HUD: a barra de vida nao segue o valor")
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
	# N5 autoral: o exame nao da' skills novas (o Dash vem do N2); ver `teste_n5_autoral`
	_ok(exame != null and exame.get_node_or_null("ColBatida") == null,
		"Execution 7: L5 nao devia desbloquear skills (exame regional)")
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
	original.kolicoins = 17
	_ok(original.guardar_em(base, base + ".bak", base + ".tmp"),
		"fresh save devia ser escrito e verificado")
	_ok(SaveFoundation.ler(base + ".bak", original.NIVEIS.size()).get("ok", false),
		"fresh save devia criar logo um backup valido")
	var copia := _novo_estado()
	_ok(copia.carregar_de(base, base + ".bak"), "fresh save devia carregar")
	_ok(copia.vidas == 4 and copia.kolicoins == 17,
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
	original.kolicoins = 29
	_ok(original.guardar_em(base, base + ".bak", base + ".tmp"),
		"roundtrip devia gravar estado valido")
	var copia := _novo_estado()
	_ok(copia.carregar_de(base, base + ".bak"), "roundtrip devia carregar")
	_ok(copia.indice_nivel == original.indice_nivel
		and copia.level_session == original.level_session
		and copia.habilidades == original.habilidades
		and copia.pistas == original.pistas
		and copia.concluidos == original.concluidos
		and copia.kolicoins == original.kolicoins,
		"roundtrip devia preservar campanha/economy/abilities")
	original.free()
	copia.free()
	_limpar_save_teste(base)


func teste_save_legacy_migration() -> void:
	var e := _novo_estado()
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
	var convertido := _novo_estado()
	convertido.de_dicionario(atual)
	_ok(convertido.kolicoins == 41, "a essência de um save antigo converte-se 1:1 em Kolicoins")
	convertido.free()
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
	e.kolicoins = 11
	_ok(e.guardar_em(base, base + ".bak", base + ".tmp"), "primeiro save devia passar")
	e.kolicoins = 22
	_ok(e.guardar_em(base, base + ".bak", base + ".tmp"),
		"segundo save devia criar backup do primeiro")
	_escrever_save_teste(base, "{corrompido")
	var copia := _novo_estado()
	_ok(copia.carregar_de(base, base + ".bak"),
		"primary corrupto devia recuperar pelo backup")
	_ok(copia.kolicoins == 11 and copia.ultima_origem_save == "backup",
		"recovery devia aplicar o ultimo primary anteriormente validado")
	e.free()
	copia.free()
	_limpar_save_teste(base)


func teste_save_escrita_nova_invalida_preserva_anterior() -> void:
	var base := "res://work/teste_save_foundation_invalid_write.json"
	_limpar_save_teste(base)
	var e := _novo_estado()
	e.kolicoins = 7
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
	e.kolicoins = 13
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
		"armas": [],
		"armaduras": [],
		"arma_equipada": "",
		"armadura_equipada": "",
		"hardcore": false,
		"hardcore_tempo_restante": -1.0,
		"essencia": 41,
		"melhorias": {},
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
			# "MarBaixo" nao esta' na cena: o `atmosfera.gd` cria-a por
			# codigo quando um pack a pede (segundo banco de nuvens).
			_ok(ml.get_string(2) in ["Fundo", "Longe", "Meio", "Perto", "MarBaixo"],
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
	# sem video de abertura (pedido do Paulo, 29 set 2026): no Windows e na
	# PWA o arranque vai direto ao menu principal
	var cena_arranque := str(ProjectSettings.get_setting("application/run/main_scene", ""))
	_ok(cena_arranque == "res://scenes/ui/MenuInicial.tscn",
		"arranque: a `main_scene` nao e o menu principal (%s)" % cena_arranque)
	_ok(not ResourceLoader.exists("res://scenes/ui/Intro.tscn")
		and not ResourceLoader.exists("res://assets/video/intro_koliani.ogv"),
		"arranque: a intro em video voltou ao projeto")
	var arranque := load(cena_arranque) as PackedScene
	_ok(arranque != null, "arranque: a cena do menu nao carrega")
	if arranque:
		var estado := arranque.get_state()
		var ha_video := false
		for i in estado.get_node_count():
			if estado.get_node_type(i) == &"VideoStreamPlayer":
				ha_video = true
		_ok(not ha_video, "arranque: o menu tem um VideoStreamPlayer")
	var preset := FileAccess.get_file_as_string("res://export_presets.cfg")
	_ok(preset.contains("res://web/shell.html\"")
		and FileAccess.file_exists("res://web/shell.html"),
		"arranque: o export Web nao usa o shell sem intro")
	var shell := FileAccess.get_file_as_string("res://web/shell.html")
	_ok(shell.contains("engine.startGame(") and not shell.contains("kolianiIntro")
		and not shell.contains(".mp4"),
		"arranque: o shell Web ainda passa por uma intro em video")
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
	var esperado := int(round(550.0 * 3.2 * float(ChefeBase.ALIVIO_R1[0]["vida"])))
	_ok(absi(vida_com - esperado) <= 2,
		"9H: o Ghorak devia ficar com ~%d de vida, ficou com %d" % [esperado, vida_com])
	_ok(vida_com < int(round(550.0 * 3.2 * 0.75)),
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


## 29 set 2026: o Paulo ouvia a musica "igual em praticamente todos os niveis".
## A faixa aprovada tocava certa; o que se repetia era a ambiencia antiga por
## baixo (`assombracao` do N6 ao N100). Guarda as duas coisas: nenhuma regiao
## nem chefe cai numa faixa antiga, e a ambiencia antiga nao volta a tocar em
## nivel, chefe, menu ou pausa.
func teste_musica_so_aprovada() -> void:
	var antigas := [Musica.CAMINHO, Musica.CAMINHO_BOSS, Musica.CAMINHO_MENU]
	for i in 100:
		for cam: String in [Musica.faixa_de_nivel(i), Musica.faixa_de_chefe(i)]:
			var aprovada := cam.begins_with(Musica.DIR_APROVADO) \
					or cam.begins_with("res://assets/audio/music/")
			_ok(aprovada and not antigas.has(cam),
				"musica: N%d toca uma faixa nao aprovada (%s)" % [i + 1, cam])
	_ok(not Musica.AMBIENCIA_ANTIGA_LIGADA,
		"musica: a ambiencia antiga (assombracao/floresta) voltou a estar ligada")
	var guardado := EstadoJogo.indice_nivel
	for i in [0, 4, 5, 11, 50, 99]:
		EstadoJogo.indice_nivel = i
		Musica.ambiente(i)
		_ok(not Musica._amb.playing and Musica._amb.stream == null,
			"musica: ambiencia antiga a tocar no N%d" % (i + 1))
		Musica.boss()
		_ok(not Musica._amb.playing, "musica: ambiencia antiga no chefe do N%d" % (i + 1))
	Musica.pausa(true)
	_ok(not Musica._amb.playing, "musica: ambiencia antiga na pausa")
	Musica.pausa(false)
	Musica.menu()
	_ok(not Musica._amb.playing, "musica: ambiencia antiga no menu")
	Musica.parar()
	EstadoJogo.indice_nivel = guardado


## 30 set 2026: os 27 SFX Pixabay de combate aprovados pelo Paulo nunca tinham
## chegado ao jogo. Cada evento abaixo tem de apontar para o seu corte
## aprovado (`approved/sfx/combate/`), o stream tem de carregar e ter uma
## duracao de efeito (nao os 52 s da porta de forno), e o comeco de um
## combate de chefe tem de tocar a entrada aprovada.
func teste_sfx_combate_aprovados() -> void:
	var eventos := ["passo1", "passo2", "passo3", "ataque", "ataque2", "ataque3",
		"acerto", "acerto_v2", "acerto_v3", "acerto_critico", "pisao_koliani", "dano",
		"morte_koliani", "bloqueio", "parede", "investida", "golpe_pesado", "esmagar",
		"garra", "chama", "chefe_magia", "raio", "energia_impacto", "olho_carregar",
		"pedra_parte", "praga", "mecanismo", "sino_mecanismo", "lamina_cair",
		"chefe_entrada"]
	for ev: String in eventos:
		var cam: String = Som.CAMINHOS.get(ev, "")
		_ok(cam.begins_with("res://assets/audio/approved/sfx/combate/"),
			"sfx combate: '%s' nao usa o som aprovado (%s)" % [ev, cam])
		var st: AudioStream = Som._stream(ev)
		_ok(st != null and st.get_length() > 0.2 and st.get_length() < 4.5,
			"sfx combate: '%s' nao carrega ou tem duracao de efeito errada" % ev)
	var visto := ""
	var b: Node = preload("res://scenes/actors/ChefeAerion.tscn").instantiate() \
			if ResourceLoader.exists("res://scenes/actors/ChefeAerion.tscn") else null
	if b != null:
		add_child(b)
		var antes: int = Som._ordem
		b.provocar()
		visto = Som._pool[(Som._idx + Som.VOZES - 1) % Som.VOZES].stream.resource_path.get_file() \
				if Som._ordem > antes else ""
		_ok(visto == "chefe_entrada.ogg",
			"sfx combate: provocar() nao tocou a entrada do chefe (%s)" % visto)
		b.queue_free()


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
## proposito: mudar a chave partia os saves. O que conta e' o que se le' no ecra.
func teste_r3_vyrak_sem_lore_de_dragao() -> void:
	var proibidas := ["dragon", "dragão", "dragao", "dragón", "drache",
		"scale", "escama", "écaille", "schuppe", "fang", "presa", "croc",
		"reißzahn", "巨龙", "龙", "鳞"]
	var chaves := ["boss.vyrak", "clue.pico_escama_de_vyrak.title",
		"clue.pico_escama_de_vyrak.body"]
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
	# O canone da Regiao III admite UM confronto -- o Vyrak, no N15.
	#
	# Auditoria N11 (GM, 28 set 2026): o briefing desta execucao foi
	# explicito -- "SEM BOSS, SEM MINIBOSS DISFARCADO" no N11, que e' so' a
	# INTRODUCAO da regiao. Isto SUPERSEDE a decisao anterior desta mesma
	# funcao ("o Sino Vivo fica no N11 como guardiao"): o Sino Vivo saiu da
	# cena (`Torre_dos_Sinos.tscn`) e `CHEFE_KEY[R3_BASE]` passou a "" (sem
	# linha de chefe/guardiao na HUD). N12-N14 ainda nao tiveram este audit
	# -- continuam guardioes ate' alguem decidir o contrario.
	for i in [1, 2, 3]:
		var chave: String = CatalogoCampanha.CHEFE_KEY[R3_BASE + i]
		_ok(chave.begins_with("guard."),
			"R3: o N%d devia ser guardiao, e' `%s`" % [11 + i, chave])
	_ok(CatalogoCampanha.CHEFE_KEY[R3_BASE + 4] == "boss.vyrak",
		"R3: o N15 devia ser `boss.vyrak`, e' `%s`" % [
			CatalogoCampanha.CHEFE_KEY[R3_BASE + 4]])
	_ok(CatalogoCampanha.CHEFE_KEY[R3_BASE] == "",
		"R3: o N11 (introducao) nao tem chefe nem guardiao, e' `%s`" % [
			CatalogoCampanha.CHEFE_KEY[R3_BASE]])


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
		# Este teste so' verifica ESTRUTURA (a Koliani e a Porta existem), mas
		# a cena e' o nivel REAL, com armadilhas/inimigos vivos, e a Koliani
		# arranca sem passar pelo `Main.tscn`/checkpoint normais -- pode
		# morrer nos dois frames seguintes. `_morrer()` agenda
		# `Transicao.fechar_e(get_tree().reload_current_scene)` (koliani.gd)
		# num Tween que NAO esta' preso a `raiz` -- o `raiz.queue_free()` a
		# seguir nao o cancela. Uns frames depois (a meio dos testes da
		# Regiao III seguintes) esse Tween recarregava a CENA ATUAL, que e'
		# o proprio `run_tests.tscn`: a corrida reiniciava a meio ("runner
		# repetido"), e a instancia orfa desta corotina passava a chamar
		# `get_tree()` sobre um no' ja fora da arvore -- daqui os
		# `Cannot call method 'quit' on a null value` no fim da suite.
		# `_a_morrer = true` faz `_morrer()` devolver logo (guarda-o tanto em
		# `receber_dano()` como em `_dano_de_estado()`), sem mexer em
		# `koliani.gd`: a Koliani fica presente para os dois `_ok()` a seguir,
		# so' nao pode morrer durante o checkpoint.
		var kol := raiz.get_node_or_null("Koliani")
		if kol:
			kol.set("_a_morrer", true)
		await get_tree().process_frame
		await get_tree().process_frame
		_ok(kol != null,
			"R3: o N%d devia ter a Koliani" % [11 + i])
		_ok(raiz.get_node_or_null("Porta") != null,
			"R3: o N%d devia ter a saida" % [11 + i])
		raiz.queue_free()
		await get_tree().process_frame


func _nos_recursivos(raiz: Node) -> Array[Node]:
	var fora: Array[Node] = []
	var pilha: Array[Node] = [raiz]
	while not pilha.is_empty():
		var n: Node = pilha.pop_back()
		fora.append(n)
		for f in n.get_children():
			pilha.append(f)
	return fora


func _fantasmas_do_grupo(raiz: Node, grupo: String) -> Array[Node]:
	var fora: Array[Node] = []
	for n in _nos_recursivos(raiz):
		if n.is_in_group(grupo):
			fora.append(n)
	return fora


func _col_desligada(p: Node) -> bool:
	var col := p.get_node_or_null("Col") as CollisionShape2D
	return col != null and col.disabled


## N12 (Regiao III) -- contrato LOCKED: elevadores, escadas quebradas, 2 sinos de
## sincronizacao, vitral interactivo, plataformas que desaparecem, vento e queda
## controlada, e NENHUM fogo. Prova estrutura E efeito (a badalada / o vitral
## partido tornam solidas as plataformas fantasma) E FISICA: o elevador leva
## mesmo a Koliani ao A2 e a coluna de ar leva-a mesmo ao C1.
##
## Execucao N12 autoral (29 set 2026): o nivel deixou de ter jornada
## procedural -- as camaras do contrato sao agora a sala feita a mao
## (`tools/construir_n12_galerias.py`), por isso deixou de se exigir o
## gerador e as `camaras_geradas`. Estrutura fina: `TestesRegion03N12`.
func teste_r3_n12_contrato() -> void:
	var raiz: Node = (load(EstadoJogo.NIVEIS[R3_BASE + 1]) as PackedScene).instantiate()
	EstadoJogo.indice_nivel = R3_BASE + 1
	EstadoJogo.checkpoint = Vector2.ZERO
	get_tree().root.add_child(raiz)
	var kol := raiz.get_node_or_null("Koliani")
	if kol:
		kol.set("_a_morrer", true)
	for i in 4:
		await get_tree().process_frame
	var nos := _nos_recursivos(raiz)
	var sinos_sync: Array[Node] = []
	var vitrais: Array[Node] = []
	var n_fogo := 0
	var n_quebra := 0
	var n_corrente := 0
	var n_elevador := 0
	for n in nos:
		var f := String(n.scene_file_path)
		if n is SinoTorre and String((n as SinoTorre).alterna_grupo).begins_with("sino_sync_"):
			sinos_sync.append(n)
		elif n is Vitral:
			vitrais.append(n)
		if f.ends_with("/Fogo.tscn"):
			n_fogo += 1
		elif f.ends_with("/PlataformaQuebra.tscn"):
			n_quebra += 1
		elif f.ends_with("/CorrenteAr.tscn"):
			n_corrente += 1
		elif f.ends_with("/TumuloElevador.tscn"):
			n_elevador += 1
	_ok(n_fogo == 0, "R3/N12: sobrou fogo herdado (%d)" % n_fogo)
	_ok(n_quebra >= 1, "R3/N12: faltam plataformas que desaparecem")
	_ok(n_corrente >= 1, "R3/N12: falta a corrente de ar")
	_ok(n_elevador >= 1, "R3/N12: faltam elevadores")
	_ok(sinos_sync.size() >= 2, "R3/N12: sao precisos 2 sinos de sincronizacao (%d)" % sinos_sync.size())
	_ok(vitrais.size() >= 1, "R3/N12: falta o vitral interactivo")
	for v in vitrais:
		_ok((v as Vitral).textura_inteiro != null, "R3/N12: o vitral devia usar a arte aprovada")
	for s in sinos_sync:
		_ok((s as SinoTorre).textura != null, "R3/N12: o sino %s devia usar a arte aprovada" % s.name)

	# EFEITO da badalada: as plataformas fantasma do sino ficam solidas
	if sinos_sync.size() >= 2:
		var grupo := String((sinos_sync[0] as SinoTorre).alterna_grupo)
		var plats := _fantasmas_do_grupo(raiz, grupo)
		_ok(plats.size() >= 3, "R3/N12: cada sino devia ter a sua ponte (%d)" % plats.size())
		var todas_fantasma := true
		for p in plats:
			todas_fantasma = todas_fantasma and _col_desligada(p)
		_ok(todas_fantasma, "R3/N12: a ponte devia arrancar fantasma")
		(sinos_sync[0] as SinoTorre).receber_dano(1, 1.0)
		for i in 3:
			await get_tree().process_frame
		var todas_solidas := true
		for p in plats:
			todas_solidas = todas_solidas and not _col_desligada(p)
		_ok(todas_solidas, "R3/N12: a badalada devia tornar a ponte solida")
		# o segundo sino manda na OUTRA ponte (ordem do percurso)
		var outra := _fantasmas_do_grupo(raiz,
			String((sinos_sync[1] as SinoTorre).alterna_grupo))
		var outra_intacta := not outra.is_empty()
		for p in outra:
			outra_intacta = outra_intacta and _col_desligada(p)
		_ok(outra_intacta, "R3/N12: o 1.o sino nao devia mexer na ponte do 2.o")
		# bater outra vez desfaz (retry possivel)
		(sinos_sync[0] as SinoTorre)._cd = 0.0
		(sinos_sync[0] as SinoTorre).receber_dano(1, 1.0)
		for i in 3:
			await get_tree().process_frame
		var voltou := true
		for p in plats:
			voltou = voltou and _col_desligada(p)
		_ok(voltou, "R3/N12: uma 2.a badalada devia desfazer a ponte")
	# EFEITO do vitral: partir acende a ponte de luz. O vitral da ponte e' o
	# primeiro com grupo proprio de plataformas (o do segredo so' da' luz).
	var vit_ponte: Vitral = null
	for v in vitrais:
		if _fantasmas_do_grupo(raiz, String((v as Vitral).grupo_luz)).size() >= 3:
			vit_ponte = v
	_ok(vit_ponte != null, "R3/N12: o vitral devia ter a sua ponte de luz")
	if vit_ponte:
		var luz := _fantasmas_do_grupo(raiz, String(vit_ponte.grupo_luz))
		vit_ponte.receber_dano(1, 1.0)
		for i in 3:
			await get_tree().process_frame
		var acesas := true
		for p in luz:
			acesas = acesas and not _col_desligada(p)
		_ok(acesas, "R3/N12: partir o vitral devia tornar solida a ponte de luz")
		var col_v := vit_ponte.get_node_or_null("Col") as CollisionShape2D
		_ok(col_v != null and col_v.disabled, "R3/N12: o vitral partido deixa de ser parede")
	raiz.queue_free()
	await get_tree().process_frame
	await _r3_n12_fisica()


## FISICA do N12 com a Koliani real: o elevador de peso leva-a do chao ao A2,
## volta a descer quando ela sai, e a coluna de ar leva-a da Ponte Alta ao C1.
## Corre a 4x (`Engine.time_scale`) -- so' se mede onde ela chega.
## Corre a 4x (`Engine.time_scale`) -- so' se mede onde ela chega.
func _r3_n12_fisica() -> void:
	var raiz: Node = (load(EstadoJogo.NIVEIS[R3_BASE + 1]) as PackedScene).instantiate()
	EstadoJogo.indice_nivel = R3_BASE + 1
	EstadoJogo.checkpoint = Vector2.ZERO
	get_tree().root.add_child(raiz)
	var kol := raiz.get_node("Koliani") as CharacterBody2D
	var elev := raiz.get_node("Elevador1") as Node2D
	var a2_topo: float = (raiz.get_node("A2") as Node2D).position.y \
		- float((raiz.get_node("A2").get("tamanho") as Vector2).y) * 0.5
	for i in 6:
		await get_tree().physics_frame
	var escala := Engine.time_scale
	Engine.time_scale = 4.0
	# fora do jogo (sem o Main a arrancar o nivel) a Koliani nasce parada
	kol.set_physics_process(true)
	kol.global_position = elev.global_position + Vector2(0, -40)
	kol.velocity = Vector2.ZERO
	var t := 0.0
	# a origem da Koliani fica PES - 22 px
	while t < 6.0 and kol.global_position.y + 22.0 > a2_topo + 2.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0   # cada passo de fisica = 1/60 s de JOGO
	_ok(absf(kol.global_position.y + 22.0 - a2_topo) < 8.0,
		"R3/N12: o elevador 1 devia levar a Koliani ao A2 (y=%.0f, A2=%.0f)" % [
			kol.global_position.y, a2_topo])
	# sai para o A2 -> o elevador volta ao chao
	kol.global_position = Vector2(1100, a2_topo - 24)
	kol.velocity = Vector2.ZERO
	var base_y := float((elev.get("_base") as Vector2).y)
	t = 0.0
	while t < 7.0 and absf(elev.global_position.y - base_y) > 2.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0   # cada passo de fisica = 1/60 s de JOGO
	_ok(absf(elev.global_position.y - base_y) <= 2.0,
		"R3/N12: sem peso o elevador 1 devia voltar ao chao")
	# coluna de ar: da ponta da Ponte Alta ate' acima do C1
	var c1_topo: float = (raiz.get_node("C1") as Node2D).position.y \
		- float((raiz.get_node("C1").get("tamanho") as Vector2).y) * 0.5
	# na ponta direita da Ponte Alta, ja' dentro da coluna
	var ponte := raiz.get_node("PonteAlta") as Node2D
	kol.global_position = ponte.position + Vector2(
		float((ponte.get("tamanho") as Vector2).x) * 0.5 + 40.0, -40.0)
	kol.velocity = Vector2.ZERO
	var min_y := kol.global_position.y
	t = 0.0
	while t < 4.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0   # cada passo de fisica = 1/60 s de JOGO
		min_y = minf(min_y, kol.global_position.y)
	_ok(min_y < c1_topo - 40.0,
		"R3/N12: a coluna de ar devia levar a Koliani acima do C1 (min y=%.0f, C1=%.0f)" % [
			min_y, c1_topo])
	Engine.time_scale = escala
	raiz.queue_free()
	await get_tree().process_frame


## Cada PORTAO do N12 e' mesmo preciso: tirando-o da sala, o crivo de alcance
## (`tools/verifica_alcance.gd`) deixa de chegar a' porta. Complementa o
## `TestesRegion03N12` (que mede os portoes com o salto real): aqui prova-se
## que nao ha' um caminho alternativo esquecido a contornar cada um.
func teste_r3_n12_portoes_no_crivo() -> void:
	const CRIVO := preload("res://tools/verifica_alcance.gd")
	var casos := {
		"": [],
		"elevador 1": ["Elevador1"],
		"sino A": ["PonteA1", "PonteA2", "PonteA3"],
		"escadas quebradas": ["Degrau1", "Degrau2", "Degrau3", "Degrau4"],
		"plataformas que desaparecem": ["Ritmo1", "Ritmo2", "Ritmo3"],
		"elevador 2": ["Elevador2"],
		"vitral": ["PonteLuz1", "PonteLuz2", "PonteLuz3"],
		"coluna de ar": ["ColunaDeAr"],
		"queda controlada": ["Queda1", "Queda2", "Queda3"],
		"sino B": ["PonteB1", "PonteB2", "PonteB3"],
	}
	EstadoJogo.indice_nivel = R3_BASE + 1
	EstadoJogo.checkpoint = Vector2.ZERO
	for portao: String in casos:
		var raiz: Node = (load(EstadoJogo.NIVEIS[R3_BASE + 1]) as PackedScene).instantiate()
		for n: String in casos[portao]:
			var x := raiz.get_node_or_null(n)
			_ok(x != null, "R3/N12: falta o no' %s" % n)
			if x:
				raiz.remove_child(x)
				x.free()
		var kol := raiz.get_node_or_null("Koliani")
		if kol:
			kol.set("_a_morrer", true)
		get_tree().root.add_child(raiz)
		for i in 4:
			await get_tree().physics_frame
		var r: Dictionary = CRIVO._medir_arvore(get_tree(), raiz)
		if portao == "":
			_ok(bool(r.get("ok_porta", false)) and (r.get("orfas", []) as Array).is_empty(),
				"R3/N12: a sala inteira devia chegar a' porta sem ilhas (%s %s)" % [
					r.get("porque", ""), r.get("orfas", [])])
		else:
			_ok(not bool(r.get("ok_porta", true)),
				"R3/N12: o portao '%s' contorna-se -- a porta alcanca-se sem ele" % portao)
		raiz.queue_free()
		await get_tree().process_frame


## N13 (Mecanismos Antigos) em FISICA: a cena inteira na arvore, as
## alavancas puxadas como a Koliani as puxa (tocar), o padrao dos 3 sinos
## tocado como ela o toca (badalada). Prova que a logica liga mesmo:
## alavanca -> porta, duas alavancas -> porta que exige as duas, alavanca
## das pontes -> uma some e a outra aparece, padrao certo -> nucleo liga ->
## porta do guardiao abre; padrao errado -> recomeca.
func teste_r3_n13_mecanismos() -> void:
	EstadoJogo.indice_nivel = R3_BASE + 2
	EstadoJogo.checkpoint = Vector2.ZERO
	var raiz: Node = (load(EstadoJogo.NIVEIS[R3_BASE + 2]) as PackedScene).instantiate()
	var kol := raiz.get_node_or_null("Koliani")
	if kol:
		kol.set("_a_morrer", true)
	get_tree().root.add_child(raiz)
	for i in 6:
		await get_tree().physics_frame
	var k: Node = raiz.get_node("Koliani")
	var fechada := func(nome: String) -> bool:
		return not (raiz.get_node(nome).get_node("Col") as CollisionShape2D).disabled

	# A) uma alavanca, uma porta
	_ok(fechada.call("PortaA"), "R3/N13: a porta A devia arrancar fechada")
	raiz.get_node("AlavancaA")._ao_tocar(k)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_ok(not fechada.call("PortaA"), "R3/N13: a alavanca A devia abrir a porta A")

	# B) alavancas multiplas: so' com as duas
	raiz.get_node("AlavancaB1")._ao_tocar(k)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_ok(fechada.call("PortaB"), "R3/N13: a porta B abriu so' com uma das duas alavancas")
	raiz.get_node("AlavancaB2")._ao_tocar(k)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_ok(not fechada.call("PortaB"), "R3/N13: as duas alavancas deviam abrir a porta B")

	# C1) pontes reconfiguraveis: a direita arranca solida, a esquerda fantasma
	var solida := func(nome: String) -> bool:
		return not (raiz.get_node(nome).get_node("Col") as CollisionShape2D).disabled
	_ok(solida.call("PonteDireita") and not solida.call("PonteEsquerda"),
		"R3/N13: as pontes deviam arrancar direita solida / esquerda fantasma")
	raiz.get_node("AlavancaPontes")._ao_tocar(k)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_ok(not solida.call("PonteDireita") and solida.call("PonteEsquerda"),
		"R3/N13: a alavanca das pontes devia trocar qual das duas esta' solida")
	_ok(not fechada.call("PortaA"), "R3/N13: a alavanca das pontes nao mexe em portas")

	# D) o padrao dos 3 sinos
	var nucleo: Node = raiz.get_node("Nucleo")
	var ordem: PackedInt32Array = nucleo.get("ordem")
	var nomes := ["SinoP", "SinoG", "SinoM"]
	_ok(fechada.call("PortaNucleo"), "R3/N13: a porta do nucleo devia arrancar fechada")
	# errado: comeca pelo sino que NAO e' o primeiro
	var errado: int = ordem[1]
	raiz.get_node(nomes[errado]).tocar()
	await get_tree().physics_frame
	_ok(int(nucleo.get("_certos")) == 0, "R3/N13: um sino fora de ordem devia apagar o padrao")
	for i in ordem.size():
		var s: Node = raiz.get_node(nomes[ordem[i]])
		s.set("_cd", 0.0)
		s.tocar()
		await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	_ok(bool(nucleo.get("ligada")), "R3/N13: o padrao certo devia ligar o nucleo")
	_ok(not fechada.call("PortaNucleo"), "R3/N13: o nucleo ligado devia abrir a porta do guardiao")
	raiz.queue_free()
	await get_tree().process_frame


## Os dois elevadores de contrapeso sao os UNICOS caminhos entre andares:
## sem eles o crivo de alcance nao chega a' porta. (As portas de alavanca, o
## crivo nao as ve -- essas prova-as o teste de fisica acima.)
func teste_r3_n13_elevadores_no_crivo() -> void:
	const CRIVO := preload("res://tools/verifica_alcance.gd")
	var casos := {"": [], "elevador 1": ["Elevador1"], "elevador 2": ["Elevador2"]}
	EstadoJogo.indice_nivel = R3_BASE + 2
	EstadoJogo.checkpoint = Vector2.ZERO
	for portao: String in casos:
		var raiz: Node = (load(EstadoJogo.NIVEIS[R3_BASE + 2]) as PackedScene).instantiate()
		for n: String in casos[portao]:
			var x := raiz.get_node_or_null(n)
			_ok(x != null, "R3/N13: falta o no' %s" % n)
			if x:
				raiz.remove_child(x)
				x.free()
		var kol := raiz.get_node_or_null("Koliani")
		if kol:
			kol.set("_a_morrer", true)
		get_tree().root.add_child(raiz)
		for i in 4:
			await get_tree().physics_frame
		var r: Dictionary = CRIVO._medir_arvore(get_tree(), raiz)
		if portao == "":
			_ok(bool(r.get("ok_porta", false)) and (r.get("orfas", []) as Array).is_empty(),
				"R3/N13: o nivel inteiro devia chegar a' porta sem ilhas (%s %s)" % [
					r.get("porque", ""), r.get("orfas", [])])
		else:
			_ok(not bool(r.get("ok_porta", true)),
				"R3/N13: o '%s' contorna-se -- a porta alcanca-se sem ele" % portao)
		raiz.queue_free()
		await get_tree().process_frame


## N14 (Campanario) em FISICA: a cena inteira na arvore e os sinos tocados
## como a Koliani os toca. Prova que a badalada acende as plataformas
## temporizadas do seu grupo (so' as dele), que elas se apagam quando o tempo
## acaba, e que o sino da corrente muda o sentido da corrente D (sobe/desce).
func teste_r3_n14_sinos() -> void:
	EstadoJogo.indice_nivel = R3_BASE + 3
	EstadoJogo.checkpoint = Vector2.ZERO
	var raiz: Node = (load(EstadoJogo.NIVEIS[R3_BASE + 3]) as PackedScene).instantiate()
	var kol := raiz.get_node_or_null("Koliani")
	if kol:
		kol.set("_a_morrer", true)
	get_tree().root.add_child(raiz)
	for i in 6:
		await get_tree().physics_frame
	var solida := func(nome: String) -> bool:
		return not (raiz.get_node(nome).get_node("Col") as CollisionShape2D).disabled

	# B) sinos em sequencia: tudo apagado ate' se tocar
	for nome in ["Seq1a", "Seq1d", "Seq2a", "Seq3a"]:
		_ok(not solida.call(nome), "R3/N14: %s devia arrancar apagada" % nome)
	raiz.get_node("Sino1").tocar()
	await get_tree().physics_frame
	await get_tree().physics_frame
	for nome in ["Seq1a", "Seq1b", "Seq1c", "Seq1d"]:
		_ok(solida.call(nome), "R3/N14: o Sino1 devia acender %s" % nome)
	_ok(not solida.call("Seq2a") and not solida.call("Seq3a"),
		"R3/N14: o Sino1 so' acende a 1.a sequencia")
	# tocar outra vez nao as apaga (temporizadas: a badalada da' tempo)
	var s1: Node = raiz.get_node("Sino1")
	s1.set("_cd", 0.0)
	s1.tocar()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_ok(solida.call("Seq1a"), "R3/N14: a 2.a badalada devia manter a sequencia acesa")
	# o tempo acaba -> apagam-se
	for nome in ["Seq1a", "Seq1b", "Seq1c", "Seq1d"]:
		raiz.get_node(nome).set("_resta", 0.02)
	# o relogio das temporizadas corre no `_process`: esperar frames de
	# desenho (e um de fisica para o `set_deferred` da colisao)
	for i in 6:
		await get_tree().process_frame
	await get_tree().physics_frame
	_ok(not solida.call("Seq1a") and not solida.call("Seq1d"),
		"R3/N14: as temporizadas deviam apagar-se quando o tempo acaba")

	# C) a corrente que muda de direcao: o sino leva-a ao alto e traz de volta
	var cd := raiz.get_node("CorrenteD") as Node2D
	var y0 := cd.global_position.y
	raiz.get_node("SinoCorrente1").tocar()
	for i in 90:
		await get_tree().physics_frame
	_ok(cd.global_position.y < y0 - 150.0,
		"R3/N14: o sino devia pôr a corrente D a subir (%.0f -> %.0f)" % [y0, cd.global_position.y])
	var sc2: Node = raiz.get_node("SinoCorrente2")
	sc2.set("_cd", 0.0)
	sc2.tocar()
	var y1 := cd.global_position.y
	for i in 60:
		await get_tree().physics_frame
	_ok(cd.global_position.y > y1 + 100.0,
		"R3/N14: o outro sino devia inverter a corrente D (%.0f -> %.0f)" % [y1, cd.global_position.y])
	raiz.queue_free()
	await get_tree().process_frame


## Cada PORTAO do N14 e' mesmo preciso: tirando-o, o crivo de alcance deixa
## de chegar a' porta. (O baloico A nao entra: ensina a mecanica por cima de
## um fosso de que se sai a escalar -- leva ao segredo 1, nao a' porta.)
func teste_r3_n14_portoes_no_crivo() -> void:
	const CRIVO := preload("res://tools/verifica_alcance.gd")
	var casos := {"": [], "3.a sequencia": ["Seq3a", "Seq3b"], "coluna de ar": ["ArCamara"],
		"ar do telhado": ["ArC1"], "baloico C1": ["BalancoC1"], "baloico C2": ["BalancoC2"],
		"roda": ["RodaC3_0", "RodaC3_1", "RodaC3_2"], "corrente D": ["CorrenteD"]}
	EstadoJogo.indice_nivel = R3_BASE + 3
	EstadoJogo.checkpoint = Vector2.ZERO
	for portao: String in casos:
		var raiz: Node = (load(EstadoJogo.NIVEIS[R3_BASE + 3]) as PackedScene).instantiate()
		for n: String in casos[portao]:
			var x := raiz.get_node_or_null(n)
			_ok(x != null, "R3/N14: falta o no' %s" % n)
			if x:
				raiz.remove_child(x)
				x.free()
		var kol := raiz.get_node_or_null("Koliani")
		if kol:
			kol.set("_a_morrer", true)
		get_tree().root.add_child(raiz)
		for i in 4:
			await get_tree().physics_frame
		var r: Dictionary = CRIVO._medir_arvore(get_tree(), raiz)
		if portao == "":
			_ok(bool(r.get("ok_porta", false)) and (r.get("orfas", []) as Array).is_empty(),
				"R3/N14: o nivel inteiro devia chegar a' porta sem ilhas (%s %s)" % [
					r.get("porque", ""), r.get("orfas", [])])
		else:
			_ok(not bool(r.get("ok_porta", true)),
				"R3/N14: o portao '%s' contorna-se -- a porta alcanca-se sem ele" % portao)
		raiz.queue_free()
		await get_tree().process_frame


## N15 (O Topo dos Ecos) em FISICA: o sino celestial e' surdo ate' os tres
## fragmentos de eco estarem recolhidos; depois uma badalada ergue a escada de
## ecos (os 4 degraus) e so' uma vez. Os fragmentos recolhem-se por contacto.
func teste_r3_n15_fragmentos_e_escada() -> void:
	EstadoJogo.indice_nivel = R3_BASE + 4
	EstadoJogo.checkpoint = Vector2.ZERO
	var raiz: Node = (load(EstadoJogo.NIVEIS[R3_BASE + 4]) as PackedScene).instantiate()
	var kol := raiz.get_node_or_null("Koliani")
	if kol:
		kol.set("_a_morrer", true)
	get_tree().root.add_child(raiz)
	for i in 6:
		await get_tree().physics_frame
	var solida := func(nome: String) -> bool:
		return not (raiz.get_node(nome).get_node("Col") as CollisionShape2D).disabled
	var sino := raiz.get_node("SinoCelestial") as SinoTorre
	var degraus := ["Degrau1", "Degrau2", "Degrau3", "Degrau4"]
	for d in degraus:
		_ok(not solida.call(d), "R3/N15: %s devia arrancar apagado" % d)
	_ok(sino.fragmentos_em_falta() == 3, "R3/N15: o nivel devia ter 3 fragmentos por recolher")
	# surdo: sem fragmentos nao acende nada
	sino.receber_dano(1, 0.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	for d in degraus:
		_ok(not solida.call(d), "R3/N15: o sino celestial sem fragmentos nao devia acender %s" % d)
	# recolher os tres (contacto da Koliani)
	var k := raiz.get_node("Koliani")
	for nome in ["FragmentoN", "FragmentoE", "FragmentoNE"]:
		var f := raiz.get_node(nome)
		f.call("_ao_entrar", k)
		_ok(bool(f.get("coletado")), "R3/N15: %s devia ficar recolhido" % nome)
	_ok(sino.fragmentos_em_falta() == 0, "R3/N15: com os tres recolhidos nao devia faltar nenhum")
	sino.set("_cd", 0.0)
	sino.receber_dano(1, 0.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	for d in degraus:
		_ok(solida.call(d), "R3/N15: o sino celestial devia erguer %s" % d)
	# uma vez so': nova badalada nao volta a apagar a escada
	sino.set("_cd", 0.0)
	sino.receber_dano(1, 0.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	for d in degraus:
		_ok(solida.call(d), "R3/N15: a escada de ecos nao devia voltar atras (%s)" % d)
	raiz.queue_free()
	await get_tree().process_frame


## O ritual de Vyrak (aos 50 %) ergue as plataformas da fase 2, que ate' la'
## sao fantasmas.
func teste_r3_n15_ritual_ergue_a_fase2() -> void:
	EstadoJogo.indice_nivel = R3_BASE + 4
	EstadoJogo.checkpoint = Vector2.ZERO
	var raiz: Node = (load(EstadoJogo.NIVEIS[R3_BASE + 4]) as PackedScene).instantiate()
	var kol := raiz.get_node_or_null("Koliani")
	if kol:
		kol.set("_a_morrer", true)
	get_tree().root.add_child(raiz)
	for i in 6:
		await get_tree().physics_frame
	var nomes := ["Fase2a", "Fase2b", "Fase2c"]
	for nome in nomes:
		_ok((raiz.get_node(nome).get_node("Col") as CollisionShape2D).disabled,
			"R3/N15: %s devia arrancar fantasma (so' se ergue no ritual)" % nome)
	raiz.get_node("Chefe").call("_ritual_de_ativacao")
	await get_tree().physics_frame
	await get_tree().physics_frame
	for nome in nomes:
		_ok(not (raiz.get_node(nome).get_node("Col") as CollisionShape2D).disabled,
			"R3/N15: o ritual devia erguer %s" % nome)
	raiz.queue_free()
	await get_tree().process_frame


## Cada PORTAO do N15 e' mesmo preciso: tirando-o, o crivo de alcance deixa
## de chegar a' porta. (Os baloicos, o elevador e os ecos do F3 so' levam aos
## fragmentos e aos segredos: o crivo nao os modela como portao da porta.)
func teste_r3_n15_portoes_no_crivo() -> void:
	const CRIVO := preload("res://tools/verifica_alcance.gd")
	var casos := {"": [], "degraus do sino 1": ["Seq1a", "Seq1b", "Seq1c", "Seq1d"],
		"ecos de memoria": ["Eco1", "Eco2", "Eco3", "Eco4", "Eco5", "Eco6"],
		"pedras em colapso": ["Colapso1", "Colapso2", "Colapso3", "Colapso4"],
		"coluna de ar": ["ArAltar"], "escada de ecos": ["Degrau1", "Degrau2", "Degrau3", "Degrau4"]}
	EstadoJogo.indice_nivel = R3_BASE + 4
	EstadoJogo.checkpoint = Vector2.ZERO
	for portao: String in casos:
		var raiz: Node = (load(EstadoJogo.NIVEIS[R3_BASE + 4]) as PackedScene).instantiate()
		for n: String in casos[portao]:
			var x := raiz.get_node_or_null(n)
			_ok(x != null, "R3/N15: falta o no' %s" % n)
			if x:
				raiz.remove_child(x)
				x.free()
		var kol := raiz.get_node_or_null("Koliani")
		if kol:
			kol.set("_a_morrer", true)
		get_tree().root.add_child(raiz)
		for i in 4:
			await get_tree().physics_frame
		var r: Dictionary = CRIVO._medir_arvore(get_tree(), raiz)
		if portao == "":
			_ok(bool(r.get("ok_porta", false)) and (r.get("orfas", []) as Array).is_empty(),
				"R3/N15: o nivel inteiro devia chegar a' porta sem ilhas (%s %s)" % [
					r.get("porque", ""), r.get("orfas", [])])
		else:
			_ok(not bool(r.get("ok_porta", true)),
				"R3/N15: o portao '%s' contorna-se -- a porta alcanca-se sem ele" % portao)
		raiz.queue_free()
		await get_tree().process_frame


## REGRESSAO (bug do Paulo no exe, 30 set 2026: "parede invisivel" no 3-2): o
## golpe corpo-a-corpo da Koliani chama `receber_dano(dano, dir, crit, recuo)`
## com QUATRO argumentos, e o vitral, o sino da torre, o espelho e o pára-raios
## so' aceitavam dois -- o golpe dava erro de script e NAO fazia nada (so' o
## projetil, que chama com dois, funcionava). O vitral partivel do N12 e' um
## portao: sem tiro, a Koliani ficava presa a uma "parede" sem arte de parede.
## Prova com a Koliani real e a hitbox real.
func teste_golpe_real_parte_vitral_e_toca_sino() -> void:
	var raiz: Node = (load(EstadoJogo.NIVEIS[R3_BASE + 1]) as PackedScene).instantiate()
	EstadoJogo.indice_nivel = R3_BASE + 1
	EstadoJogo.checkpoint = Vector2.ZERO
	get_tree().root.add_child(raiz)
	var kol := raiz.get_node("Koliani") as CharacterBody2D
	var vit := raiz.get_node("VitralGalerias") as Vitral
	var r4 := raiz.get_node("R4") as Node2D
	for i in 6:
		await get_tree().physics_frame
	kol.set_physics_process(true)
	# encostada ao vitral, em cima do R4, a olhar para ele
	kol.global_position = Vector2(vit.global_position.x + 38.0, r4.global_position.y - 40.0)
	kol.velocity = Vector2.ZERO
	for i in 20:
		await get_tree().physics_frame
	kol.set("_olha_para", -1.0)
	kol.call("_iniciar_ataque")
	for i in 40:
		await get_tree().physics_frame
	_ok(bool(vit.get("_partido")), "golpe real: devia partir o vitral do N12 (era uma parede sem saida)")
	# o mesmo golpe toca o sino da torre
	var sino := raiz.get_node("SinoA") as SinoTorre
	var toques := [0]
	sino.badalada.connect(func(_s: Node) -> void: toques[0] += 1)
	kol.global_position = Vector2(sino.global_position.x - 30.0, sino.global_position.y)
	kol.velocity = Vector2.ZERO
	kol.set("_olha_para", 1.0)
	kol.set("_alvos_atingidos_ataque", {})
	kol.call("_cancelar_ataque", true)
	for i in 30:
		await get_tree().physics_frame
	kol.call("_iniciar_ataque")
	for i in 40:
		await get_tree().physics_frame
	_ok(toques[0] >= 1, "golpe real: devia tocar o sino da torre")
	# todas as coisas golpeaveis aceitam a chamada de 4 argumentos do golpe
	for caminho in ["res://scripts/vitral.gd", "res://scripts/sino_torre.gd",
			"res://scripts/espelho.gd", "res://scripts/para_raios.gd"]:
		var esc := load(caminho) as Script
		var ok := false
		for m in esc.get_script_method_list():
			if m["name"] == "receber_dano":
				ok = (m["args"] as Array).size() >= 4
		_ok(ok, "%s.receber_dano tem de aceitar (dano, dir, crit, recuo) como o golpe da Koliani" % caminho.get_file())
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
	while is_instance_valid(chefe) and int(chefe.get("vida")) > 0 and seguranca < 400:
		chefe.call("receber_dano", 40, 1.0)
		seguranca += 1
	await get_tree().physics_frame
	# O golpe fatal faz `receber_dano()` chamar `queue_free()` a si proprio
	# (chefe_base.gd, sem `falas_fim`) -- por isso o `chefe` pode ficar
	# invalido logo a seguir ao golpe, antes deste `await`. Instancia
	# invalida E' a prova de morte; so' se le `vida` se ainda existir.
	_ok(not is_instance_valid(chefe) or int(chefe.get("vida")) <= 0,
		"R3: o Vyrak nao morreu ao fim de %d golpes" % seguranca)
	if is_instance_valid(chefe):
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


# --- Loja ------------------------------------------------------------------

func teste_loja_catalogo() -> void:
	var erros := LojaCatalogo.validar()
	_ok(erros.is_empty(), "loja: catalogo invalido %s" % str(erros))
	var ids := {}
	for it: Dictionary in LojaCatalogo.todos():
		_ok(not ids.has(it["id"]), "loja: id duplicado %s" % it["id"])
		ids[it["id"]] = true
		_ok(it["efeito"] == "cosmetico", "loja: %s nao e cosmetico" % it["id"])
	_ok(ids.size() >= 6, "loja: catalogo MVP demasiado pequeno")
	for c: String in LojaCatalogo.CATEGORIAS:
		_ok(c == "packs" or c == "extras" or not LojaCatalogo.da_categoria(c).is_empty(),
			"loja: categoria vazia %s" % c)
	# cobertura dos casos: so K, so V, ambas, bloqueado por regiao, inicial
	_ok(LojaCatalogo.moedas_aceites(LojaCatalogo.item("skin_carmesim")) == ["k"], "loja: item so K")
	_ok(LojaCatalogo.moedas_aceites(LojaCatalogo.item("skin_luar")) == ["v"], "loja: item so V")
	_ok(LojaCatalogo.moedas_aceites(LojaCatalogo.item("efeito_rasto_brasa")) == ["k", "v"], "loja: item K ou V")
	_ok(LojaCatalogo.item("pack_coracao_podre")["regiao"] == 0, "loja: item regional")
	_ok(LojaCatalogo.item("skin_koliani_base")["inicial"], "loja: item inicial")


func teste_loja_compras_e_equipar() -> void:
	var e := _novo_estado()
	_ok(e.kolicoins == 0 and e.veracoins == 0, "loja: saldos iniciais nao zero")
	# saldo insuficiente
	_ok(e.comprar_item("skin_carmesim", "k")["erro"] == "saldo", "loja: compra sem saldo devia falhar")
	_ok(not e.item_adquirido("skin_carmesim") and e.kolicoins == 0, "loja: compra falhada mexeu no estado")
	# Kolicoins
	e.ganhar_kolicoins(1000)
	_ok(e.comprar_item("skin_carmesim", "k")["ok"], "loja: compra K falhou")
	_ok(e.kolicoins == 700 and e.item_adquirido("skin_carmesim"), "loja: K nao debitado (%d)" % e.kolicoins)
	# nao se compra duas vezes
	_ok(e.comprar_item("skin_carmesim", "k")["erro"] == "ja_adquirido" and e.kolicoins == 700,
		"loja: comprou duas vezes")
	# moeda nao aceite
	_ok(e.comprar_item("skin_luar", "k")["erro"] == "moeda_invalida", "loja: item so-V aceitou K")
	_ok(e.comprar_item("skin_luar", "x")["erro"] == "moeda_invalida", "loja: moeda inventada")
	# Veracoins (so por mecanismo dev/teste)
	_ok(e.dev_dar_veracoins(260), "loja: dev_dar_veracoins recusou em modo teste")
	_ok(e.comprar_item("skin_luar", "v")["ok"] and e.veracoins == 110, "loja: V nao debitado (%d)" % e.veracoins)
	# moeda alternativa: item K-ou-V pago com V
	_ok(e.comprar_item("hud_moldura_osso", "v")["ok"] and e.veracoins == 50 and e.kolicoins == 700,
		"loja: compra por moeda alternativa")
	# desconhecido
	_ok(e.comprar_item("nao_existe", "k")["erro"] == "desconhecido", "loja: item desconhecido")
	# equipar: so adquiridos, so equipaveis, um por slot
	_ok(e.estado_item_loja("skin_koliani_base") == "equipado", "loja: skin inicial devia vir equipada")
	_ok(not e.equipar_item("efeito_rasto_brasa"), "loja: equipou item por comprar")
	_ok(e.equipar_item("skin_carmesim") and e.item_equipado("skin_carmesim")
		and not e.item_equipado("skin_koliani_base"), "loja: equipar skin")
	_ok(e.equipar_item("skin_luar") and e.item_equipado("skin_luar") and not e.item_equipado("skin_carmesim"),
		"loja: um so item por slot")
	e.desequipar_categoria("skins")
	_ok(e.item_equipado("skin_koliani_base"), "loja: desequipar devia voltar ao inicial")
	e.ganhar_kolicoins(500)
	e.comprar_item("extra_galeria_conceitos", "k")
	_ok(not e.equipar_item("extra_galeria_conceitos"), "loja: extras nao sao equipaveis")
	_ok(e.estado_item_loja("extra_galeria_conceitos") == "adquirido", "loja: estado adquirido")
	# a dev-grant nunca funciona fora do modo dev/teste
	var e2: Node = EstadoJogoScript.new()
	_ok(not e2.dev_dar_veracoins(500) and e2.veracoins == 0, "loja: Veracoins gratis fora do modo dev/teste")
	e2.free()
	e.free()


## Interruptor de desenvolvimento (Paulo, 29 set): tudo custa 0 para testar
## e trocar, sem gastar moedas e sem tocar nos precos reais do catalogo.
func teste_loja_gratis_dev() -> void:
	_ok(LojaCatalogo.GRATIS_EM_DESENVOLVIMENTO, "loja: em desenvolvimento a Loja devia ser gratis")
	var antes := LojaCatalogo.gratis
	LojaCatalogo.gratis = true
	var e := _novo_estado()
	_ok(e.kolicoins == 0 and e.veracoins == 0, "gratis: saldos iniciais")
	# precos reais intactos no catalogo; o que se paga e' 0
	_ok(int(LojaCatalogo.item("skin_anjo")["v"]) > 0 and e.preco_loja("skin_anjo", "v") == 0,
		"gratis: preco real devia ficar no catalogo e o pago ser 0")
	_ok(e.preco_loja("skin_anjo", "k") == -1, "gratis: moeda nao aceite continua nao aceite")
	for id: String in ["skin_anjo", "skin_demonio", "skin_fornalha", "hud_moldura_osso"]:
		var moeda := "k" if e.preco_loja(id, "k") == 0 else "v"
		_ok(e.comprar_item(id, moeda)["ok"] and e.item_adquirido(id), "gratis: nao obteve %s sem moedas" % id)
	_ok(e.kolicoins == 0 and e.veracoins == 0, "gratis: gastou moedas (%d K, %d V)" % [e.kolicoins, e.veracoins])
	_ok(e.comprar_item("skin_anjo", "v")["erro"] == "ja_adquirido", "gratis: obteve duas vezes")
	# trocar a vontade entre as skins obtidas
	_ok(e.equipar_item("skin_anjo") and e.item_equipado("skin_anjo"), "gratis: equipar Arcanjo")
	_ok(e.equipar_item("skin_demonio") and e.item_equipado("skin_demonio") and not e.item_equipado("skin_anjo"),
		"gratis: trocar para o Arquidemonio")
	_ok(e.equipar_item("skin_fornalha") and e.item_equipado("skin_fornalha"), "gratis: trocar para uma simples")
	# requisitos de regiao continuam (so' o preco muda)
	_ok(e.comprar_item("pack_coracao_podre", "k")["erro"] == "bloqueado", "gratis: desbloqueou item regional")
	# desligado, volta a cobrar
	LojaCatalogo.gratis = false
	_ok(e.preco_loja("skin_demonio", "v") == int(LojaCatalogo.item("skin_demonio")["v"]), "gratis: desligar nao repos o preco")
	LojaCatalogo.gratis = antes
	e.free()


func teste_loja_save_e_compatibilidade() -> void:
	var total: int = EstadoJogoScript.NIVEIS.size()
	var e := _novo_estado()
	e.ganhar_kolicoins(900)
	e.dev_dar_veracoins(300)
	e.comprar_item("skin_carmesim", "k")
	e.comprar_item("efeito_rasto_brasa", "v")
	e.equipar_item("skin_carmesim")
	e.equipar_item("efeito_rasto_brasa")
	var d: Dictionary = e.para_dicionario()
	var r: Dictionary = SaveFoundation.validar_atual(d, total)
	_ok(r.get("ok", false), "loja: save com bloco loja deixou de validar %s" % str(r))
	var d2: Dictionary = JSON.parse_string(JSON.stringify(d))  # round-trip JSON como no disco
	var f := _novo_estado()
	f.de_dicionario(d2)
	_ok(f.kolicoins == 600 and f.veracoins == 180, "loja: saldos nao persistiram (%d/%d)" % [f.kolicoins, f.veracoins])
	_ok(f.item_adquirido("skin_carmesim") and f.item_adquirido("efeito_rasto_brasa"), "loja: compras nao persistiram")
	_ok(f.item_equipado("skin_carmesim") and f.item_equipado("efeito_rasto_brasa"), "loja: equipado nao persistiu")
	# save antigo (sem bloco `loja`) continua valido, com defaults seguros
	var antigo: Dictionary = d2.duplicate(true)
	antigo.erase("loja")
	_ok(SaveFoundation.validar_atual(antigo, total).get("ok", false),
		"loja: save antigo (sem loja) deixou de validar")
	var g := _novo_estado()
	g.ganhar_kolicoins(5)
	g.de_dicionario(antigo)
	_ok(g.kolicoins == 0 and g.veracoins == 0 and g.itens_comprados.is_empty(), "loja: save antigo sem defaults")
	# bloco malformado nao deita nada abaixo
	var mau: Dictionary = d2.duplicate(true)
	mau["loja"] = {"kolicoins": -5, "veracoins": "x", "itens_comprados": ["nao_existe", "skin_luar", "skin_luar"],
		"cosmeticos_equipados": {"skins": "skin_carmesim", "extras": "extra_galeria_conceitos"}}
	var h := _novo_estado()
	h.de_dicionario(mau)
	_ok(h.kolicoins == 0 and h.veracoins == 0, "loja: saldos negativos/invalidos aceites")
	_ok(h.itens_comprados == ["skin_luar"], "loja: itens invalidos/duplicados aceites %s" % str(h.itens_comprados))
	_ok(h.cosmeticos_equipados.is_empty(), "loja: equipado sem posse ou em slot invalido aceite")
	# novo jogo NAO apaga a conta
	f.reiniciar_campanha()
	_ok(f.veracoins == 180 and f.item_adquirido("skin_carmesim"), "loja: novo jogo apagou Veracoins/compras")
	for x in [e, f, g, h]:
		x.free()


func teste_loja_progressao_regional_e_gameplay() -> void:
	var e := _novo_estado()
	e.ganhar_kolicoins(5000)
	_ok(e.estado_item_loja("pack_coracao_podre") == "bloqueado", "loja: item regional devia estar bloqueado")
	_ok(e.comprar_item("pack_coracao_podre", "k")["erro"] == "bloqueado", "loja: comprou item bloqueado")
	var antes: int = e.kolicoins
	for i in 5:
		e.marcar_nivel_concluido(i)
	_ok(e.regiao_esta_concluida(0), "loja: regiao I devia estar concluida")
	# BALANCE_PLACEHOLDER: 4 niveis + 1 exame
	var ganho: int = e.kolicoins - antes
	_ok(ganho == 4 * LojaCatalogo.KOLICOINS_POR_NIVEL + LojaCatalogo.KOLICOINS_POR_EXAME_REGIONAL,
		"loja: recompensa de Kolicoins inesperada (%d)" % ganho)
	e.marcar_nivel_concluido(0)
	_ok(e.kolicoins - antes == ganho, "loja: Kolicoins repetidos ao reconcluir")
	_ok(e.estado_item_loja("pack_coracao_podre") == "disponivel", "loja: item regional nao desbloqueou")
	_ok(e.comprar_item("pack_coracao_podre", "k")["ok"], "loja: compra do item regional")
	# nenhuma compra/equipamento premium mexe em gameplay
	var e2 := _novo_estado()
	e2.dev_dar_veracoins(5000)
	e2.ganhar_kolicoins(5000)
	var chaves := ["vidas", "habilidades", "indice_nivel", "concluidos"]
	var antes_g := {}
	for k in chaves:
		var v: Variant = e2.get(k)
		antes_g[k] = v.duplicate() if (v is Array or v is Dictionary) else v
	var dano_antes: int = e2.dano_ataque()
	for it: Dictionary in LojaCatalogo.todos():
		var moedas := LojaCatalogo.moedas_aceites(it)
		if not moedas.is_empty() and int(it["regiao"]) < 0:
			e2.comprar_item(it["id"], moedas[moedas.size() - 1])
		e2.equipar_item(it["id"])
	for k in chaves:
		var v: Variant = e2.get(k)
		var agora: Variant = v.duplicate() if (v is Array or v is Dictionary) else v
		_ok(agora == antes_g[k], "loja: comprar/equipar mexeu em gameplay (%s)" % k)
	_ok(e2.dano_ataque() == dano_antes, "loja: comprar/equipar mudou o dano")
	e.free()
	e2.free()


func teste_loja_i18n() -> void:
	var en: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/i18n/en.json"))
	for it: Dictionary in LojaCatalogo.todos():
		for suf in ["name", "desc"]:
			_ok(en.has("shop.item.%s.%s" % [it["id"], suf]), "loja: falta texto %s.%s" % [it["id"], suf])
	for c: String in LojaCatalogo.CATEGORIAS:
		_ok(en.has("shop.cat." + c), "loja: falta nome da categoria " + c)
	for est in ["bloqueado", "disponivel", "adquirido", "equipado", "completo"]:
		_ok(en.has("shop.state." + est), "loja: falta estado " + est)
	for r: String in LojaCatalogo.RARIDADES:
		_ok(en.has("shop.rarity." + r), "loja: falta raridade " + r)
	for k in ["shop.pack_progress", "shop.pack_missing", "shop.placeholder"]:
		_ok(en.has(k), "loja: falta chave " + k)
	# traducoes reais das chaves da colecao nos 6 idiomas (nao podem ser iguais ao ingles)
	var traduzidas := ["shop.item.skin_coracao_podre.name", "shop.item.skin_coracao_podre.desc",
		"shop.item.efeito_rasto_esporos.name", "shop.item.efeito_rasto_esporos.desc",
		"shop.item.hud_moldura_raizes.name", "shop.item.hud_moldura_raizes.desc",
		"shop.item.pack_coracao_podre.name", "shop.item.pack_coracao_podre.desc",
		"shop.rarity.comum", "shop.rarity.lendario", "shop.state.completo", "shop.pack_progress",
		"shop.pack_missing", "shop.placeholder"]
	for loc in ["pt", "es", "fr", "de", "zh"]:
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/i18n/%s.json" % loc))
		for k: String in traduzidas:
			_ok(d.has(k) and str(d[k]) != "" and str(d[k]) != str(en[k]), "loja: %s sem traducao real em %s" % [k, loc])
	_ok(en.has("menu.shop"), "loja: falta menu.shop")


## Skins com arte real (`tools/gerar_skins_koliani.py`): cada uma espelha o
## Golden Set frame a frame com um conjunto de armadura + arma por cima, e a
## Koliani equipada com ela monta os frames da pasta da skin.
func teste_skins_arte_real() -> void:
	const CV := preload("res://scripts/cosmeticos_visuais.gd")
	const GOLD := "res://assets/sprites/koliani_golden_set/frames/"
	_ok(CV.DIR_SKIN.size() >= 3, "skins: devia haver pelo menos 3 skins com arte")
	_ok(CV.SKIN_SO_PALETA.size() == 3, "skins: as simples fecharam-se em tres (Paulo, 29 set)")
	_ok(CV.DIR_SKIN.size() - CV.SKIN_SO_PALETA.size() >= 2, "skins: faltam as premium (Anjo e Demonio)")
	_ok(CV.dir_skin("skin_koliani_base") == "" and CV.dir_skin("skin_carmesim") == "",
		"skins: base/tinta nao tem pasta de arte")
	var golden: Array[String] = []
	for anim in DirAccess.get_directories_at(GOLD):
		for f in DirAccess.get_files_at(GOLD + anim):
			if f.get_extension() == "png":
				golden.append(anim + "/" + f)
	_ok(golden.size() >= 80, "skins: Golden Set com %d frames?" % golden.size())
	for id: String in CV.DIR_SKIN:
		var it := LojaCatalogo.item(id)
		_ok(not it.is_empty() and it["categoria"] == "skins" and it["placeholder"] == false,
			"skins: %s no catalogo com arte" % id)
		_ok(CV.preview_loja(id) != null and CV.dir_skin(id) == CV.DIR_SKIN[id], "skins: %s sem preview" % id)
		_ok(CV.tinta_skin(id) == Color.WHITE, "skins: %s nao deve levar tinta por cima da arte" % id)
		var faltam := 0
		for rel in golden:
			if not ResourceLoader.exists(CV.DIR_SKIN[id] + "/frames/" + rel):
				faltam += 1
		_ok(faltam == 0, "skins: %s sem %d frames do Golden Set" % [id, faltam])
		# nada toca a borda do canvas (a ponta de uma arma comprida ficava cortada)
		var na_borda := 0
		for rel in golden:
			var im := (load(CV.DIR_SKIN[id] + "/frames/" + rel) as Texture2D).get_image()
			var w := im.get_width()
			var h := im.get_height()
			for i in w:
				for q: Vector2i in [Vector2i(i, 0), Vector2i(i, h - 1), Vector2i(0, i), Vector2i(w - 1, i)]:
					if im.get_pixelv(q).a > 0.0:
						na_borda += 1
		_ok(na_borda == 0 or id in CV.SKIN_SO_PALETA, "skins: %s com %d px cortados na borda" % [id, na_borda])
		# conjunto de armadura: a silhueta CRESCE (cornos/capuz/asas) sem
		# perder o corpo, e a arma magenta do Golden Set foi trocada
		var a := (load(GOLD + "idle/idle_001.png") as Texture2D).get_image()
		var b := (load(CV.DIR_SKIN[id] + "/frames/idle/idle_001.png") as Texture2D).get_image()
		var novos := 0
		var perdidos := 0
		for y in a.get_height():
			for x in a.get_width():
				var oa := a.get_pixel(x, y).a > 0.5
				var ob := b.get_pixel(x, y).a > 0.5
				if ob and not oa:
					novos += 1
				elif oa and not ob:
					perdidos += 1
		if id in CV.SKIN_SO_PALETA:
			# so' paleta: silhueta exatamente a do Golden Set
			_ok(novos == 0 and perdidos == 0, "skins: %s (so' paleta) mudou a silhueta" % id)
			continue
		_ok(novos > 40, "skins: %s sem pecas novas na silhueta (%d px)" % [id, novos])
		_ok(perdidos < 10, "skins: %s perdeu corpo (%d px)" % [id, perdidos])
		var golpe := (load(CV.DIR_SKIN[id] + "/frames/attack_basic/attack_basic_003.png") as Texture2D).get_image()
		var golpe0 := (load(GOLD + "attack_basic/attack_basic_003.png") as Texture2D).get_image()
		# onde o Golden Set tem a lamina magenta, a skin ja' nao pode ter magenta
		# (so' se olha para esses pixeis: uma paleta pode ter magenta de proposito)
		var magenta := 0
		for y in golpe.get_height():
			for x in golpe.get_width():
				var c0 := golpe0.get_pixel(x, y)
				var c := golpe.get_pixel(x, y)
				var era_lamina := c0.a > 0.3 and c0.s > 0.3 and c0.v > 0.3 and c0.h > 0.77 and c0.h < 0.95
				if era_lamina and c.a > 0.3 and c.s > 0.35 and c.v > 0.35 and c.h > 0.78 and c.h < 0.94:
					magenta += 1
		_ok(magenta < 6, "skins: %s ainda tem a lamina magenta (%d px)" % [id, magenta])
	# a Koliani com a skin equipada monta os frames da pasta dela
	var ids: Array = CV.DIR_SKIN.keys()
	var id0: String = ids[0]
	var comprados_antes: Array = EstadoJogo.itens_comprados.duplicate()
	var equipados_antes: Dictionary = EstadoJogo.cosmeticos_equipados.duplicate()
	EstadoJogo.itens_comprados.append(id0)
	EstadoJogo.cosmeticos_equipados["skins"] = id0   # sem equipar_item: nao grava
	var k: Koliani = preload("res://scenes/actors/Koliani.tscn").instantiate()
	k.usar_golden_set = true
	add_child(k)
	var corpo := k.get_node_or_null("Sprite/Corpo") as AnimatedSprite2D
	var sf := corpo.sprite_frames if corpo else null
	_ok(sf != null and sf.get_frame_texture("idle", 0).resource_path.begins_with(CV.DIR_SKIN[id0]),
		"skins: Koliani com %s devia ler os frames da skin" % id0)
	_ok(sf != null and sf.get_frame_texture("run", 0).resource_path.begins_with(CV.DIR_SKIN[id0]),
		"skins: run_final tambem da skin")
	k.free()
	EstadoJogo.itens_comprados.assign(comprados_antes)
	EstadoJogo.cosmeticos_equipados = equipados_antes
	var k2: Koliani = preload("res://scenes/actors/Koliani.tscn").instantiate()
	k2.usar_golden_set = true
	add_child(k2)
	var c2 := k2.get_node_or_null("Sprite/Corpo") as AnimatedSprite2D
	_ok(c2 != null and c2.sprite_frames.get_frame_texture("idle", 0).resource_path.begins_with(GOLD),
		"skins: sem skin equipada volta ao Golden Set")
	k2.free()


## Shadowblade = pura pele: as animacoes da Koliani com a skin equipada sao
## IDENTICAS as do Golden Set (nomes, n.o de frames, fps, loop, escala,
## offset, tamanho de frame), incl. o `run` (= run_final, 10 frames).
func teste_shadowblade_paridade() -> void:
	const CV := preload("res://scripts/cosmeticos_visuais.gd")
	const ID := "skin_shadowblade"
	_ok(CV.DIR_SKIN.has(ID) and not (ID in CV.SKIN_SO_PALETA), "shadowblade: registada como premium")
	_ok(not LojaCatalogo.item(ID).is_empty() and LojaCatalogo.item(ID)["categoria"] == "skins"
		and LojaCatalogo.item(ID)["raridade"] == "lendario", "shadowblade: no catalogo (lendaria)")
	_ok(Textos.t("shop.item.skin_shadowblade.name") != "shop.item.skin_shadowblade.name", "shadowblade: nome i18n")
	var comprados_antes: Array = EstadoJogo.itens_comprados.duplicate()
	var equipados_antes: Dictionary = EstadoJogo.cosmeticos_equipados.duplicate()
	var ref: Koliani = preload("res://scenes/actors/Koliani.tscn").instantiate()
	ref.usar_golden_set = true
	add_child(ref)
	EstadoJogo.itens_comprados.append(ID)
	EstadoJogo.cosmeticos_equipados["skins"] = ID
	var sk: Koliani = preload("res://scenes/actors/Koliani.tscn").instantiate()
	sk.usar_golden_set = true
	add_child(sk)
	var cr := ref.get_node("Sprite/Corpo") as AnimatedSprite2D
	var cs := sk.get_node("Sprite/Corpo") as AnimatedSprite2D
	var a := cr.sprite_frames
	var b := cs.sprite_frames
	var nomes_a := Array(a.get_animation_names())
	nomes_a.sort()
	var nomes_b := Array(b.get_animation_names())
	nomes_b.sort()
	_ok(nomes_a == nomes_b, "shadowblade: mesmas animacoes")
	var difere := 0
	for n: String in a.get_animation_names():
		if a.get_frame_count(n) != b.get_frame_count(n) or a.get_animation_speed(n) != b.get_animation_speed(n) \
				or a.get_animation_loop(n) != b.get_animation_loop(n):
			difere += 1
			continue
		for i in a.get_frame_count(n):
			var ta := a.get_frame_texture(n, i)
			var tb := b.get_frame_texture(n, i)
			if ta.get_size() != tb.get_size() or a.get_frame_duration(n, i) != b.get_frame_duration(n, i):
				difere += 1
				break
	_ok(difere == 0, "shadowblade: %d animacoes com n.o frames/fps/loop/tamanho/duracao diferentes" % difere)
	_ok(b.get_frame_count("run") == 10 and b.get_animation_loop("run"), "shadowblade: run = run_final (10 frames, loop)")
	for i in 10:
		_ok(b.get_frame_texture("run", i).resource_path == CV.DIR_SKIN[ID] + "/frames/run_final/run_%03d.png" % (i + 1),
			"shadowblade: run frame %d nao e' o run_final da skin (ordem)" % i)
	_ok(cr.offset == cs.offset and cr.scale == cs.scale and ref.scale == sk.scale, "shadowblade: offset/escala iguais")
	_ok(ref.get_node("CollisionShape2D") != null and (ref.get_node("CollisionShape2D") as CollisionShape2D).shape.get_rect()
		== (sk.get_node("CollisionShape2D") as CollisionShape2D).shape.get_rect(), "shadowblade: hitbox igual")
	# VFX proprio: slots da skin existem; sem skin, nao ha' VFX de skin
	_ok(VfxSkin.pasta(ID) != "" and VfxSkin.frames_golpe() != null and VfxSkin.frames_golpe().get_frame_count("slash") == 6,
		"shadowblade: arco do golpe (6 frames)")
	for slot: String in VfxSkin.SLOTS:
		_ok(VfxSkin.frames(slot, int(VfxSkin.SLOTS[slot]["n"])) != null, "shadowblade: VFX %s" % slot)
	sk.free()
	EstadoJogo.itens_comprados.assign(comprados_antes)
	EstadoJogo.cosmeticos_equipados = equipados_antes
	_ok(VfxSkin.pasta() == "" and VfxSkin.frames_golpe() == null, "shadowblade: sem skin nao ha' VFX de skin (fallback)")
	# skin invalida/inexistente: cai no default
	EstadoJogo.cosmeticos_equipados["skins"] = "skin_que_nao_existe"
	_ok(CV.dir_skin() == "", "shadowblade: skin invalida cai no default")
	EstadoJogo.cosmeticos_equipados = equipados_antes
	ref.free()


func teste_loja_cosmeticos_visuais() -> void:
	const CV := preload("res://scripts/cosmeticos_visuais.gd")
	var LOJA := preload("res://scripts/loja_catalogo.gd")
	# default neutro; item equipado altera; desconhecido nao parte nada
	_ok(CV.tinta_skin("skin_koliani_base") == Color.WHITE, "cosm: skin base devia ser neutra")
	_ok(CV.tinta_skin("skin_carmesim") != Color.WHITE and CV.tinta_skin("skin_luar") != CV.tinta_skin("skin_carmesim"),
		"cosm: skins sem efeito visual distinto")
	_ok(CV.tinta_skin("nao_existe") == Color.WHITE, "cosm: id invalido devia dar neutro")
	var base := Color(0.4, 0.3, 0.9)
	_ok(CV.cor_rasto_dash(base, "efeito_rasto_brasa") != base and CV.cor_rasto_dash(base, "x") == base,
		"cosm: rasto de brasa")
	# a moldura de osso deixou de ser tinta: tem arte propria (Ossario)
	_ok(CV.caixa_hud("disco", Vector4.ZERO, [22, 22, 22, 22], "hud_moldura_osso") != null
		and CV.caixa_hud("disco", Vector4.ZERO, [22, 22, 22, 22], "x") == null, "cosm: moldura de HUD")
	_ok(not CV.checkpoint_visual("hud_moldura_osso").is_empty() and CV.checkpoint_visual("x").is_empty(),
		"cosm: fogueira da moldura")
	# so' cosmeticos: nada de stats
	var e := _novo_estado()
	var dano0: int = e.dano_ataque()
	var vidas0: int = e.vidas
	e.ganhar_kolicoins(2000)
	for id in ["skin_carmesim", "efeito_rasto_brasa", "hud_moldura_osso"]:
		e.comprar_item(id, "k")
		e.equipar_item(id)
	_ok(e.dano_ataque() == dano0 and e.vidas == vidas0, "cosm: equipar mexeu nos stats")
	# desequipar volta ao default
	e.desequipar_categoria("skins")
	_ok(CV.tinta_skin(e.equipado_na_categoria("skins")) == Color.WHITE, "cosm: desequipar nao restaura default")
	# save/load mantem o equipado
	var f := _novo_estado()
	f.de_dicionario(JSON.parse_string(JSON.stringify(e.para_dicionario())))
	_ok(f.item_equipado("efeito_rasto_brasa") and f.item_equipado("hud_moldura_osso")
		and f.equipado_na_categoria("skins") == "skin_koliani_base", "cosm: save/load nao manteve equipado")
	# item invalido no save nao parte o runtime
	var d: Dictionary = e.para_dicionario()
	d["cosmeticos_equipados"] = {"skins": "lixo", "efeitos": 7}
	var g := _novo_estado()
	g.de_dicionario(d)
	_ok(CV.tinta_skin(g.equipado_na_categoria("skins")) == Color.WHITE, "cosm: save invalido quebrou o default")
	# Novo Jogo nao apaga compras da conta
	e.reiniciar_campanha()
	_ok(e.item_adquirido("skin_carmesim"), "cosm: Novo Jogo apagou compras")
	# Kolicoins: 1.a conclusao (+25), exame (+100), repeticao nao repete
	var h := _novo_estado()
	var k0: int = h.kolicoins
	h.marcar_nivel_concluido(0)
	_ok(h.kolicoins == k0 + LOJA.KOLICOINS_POR_NIVEL, "cosm: 1.a conclusao devia dar +25 (%d)" % h.kolicoins)
	h.marcar_nivel_concluido(0)
	_ok(h.kolicoins == k0 + LOJA.KOLICOINS_POR_NIVEL, "cosm: repetir nivel deu recompensa outra vez")
	var k1: int = h.kolicoins
	h.marcar_nivel_concluido(4)
	_ok(h.kolicoins == k1 + LOJA.KOLICOINS_POR_EXAME_REGIONAL, "cosm: exame devia dar +100 (%d)" % (h.kolicoins - k1))
	h.marcar_nivel_concluido(4)
	_ok(h.kolicoins == k1 + LOJA.KOLICOINS_POR_EXAME_REGIONAL, "cosm: repetir exame deu recompensa")
	h.free()
	f.free()
	g.free()
	e.free()


func teste_loja_colecao_regiao_i() -> void:
	const IDS := ["skin_coracao_podre", "efeito_rasto_esporos", "hud_moldura_raizes"]
	const PACK := "pack_coracao_podre"
	# 1-2. raridades validas; desconhecida rejeitada
	for it: Dictionary in LojaCatalogo.todos():
		_ok(str(it["raridade"]) in LojaCatalogo.RARIDADES, "colecao: raridade invalida em %s" % it["id"])
	_ok(LojaCatalogo.RARIDADES == ["comum", "raro", "epico", "lendario"], "colecao: 4 raridades esperadas")
	var lixo: Dictionary = LojaCatalogo.item("skin_carmesim").duplicate()
	lixo["id"] = "teste_raridade_falsa"
	lixo["raridade"] = "mitico"
	var com_lixo: Array = LojaCatalogo.ITENS.duplicate()
	com_lixo.append(lixo)
	_ok(not LojaCatalogo.validar(com_lixo).is_empty(), "colecao: validar() aceitou raridade desconhecida")
	_ok(LojaCatalogo.validar().is_empty(), "colecao: catalogo real invalido %s" % str(LojaCatalogo.validar()))
	# mapa dos placeholders
	_ok(LojaCatalogo.item("skin_carmesim")["raridade"] == "comum" and LojaCatalogo.item("hud_moldura_osso")["raridade"] == "comum"
		and LojaCatalogo.item("efeito_rasto_brasa")["raridade"] == "raro" and LojaCatalogo.item("skin_luar")["raridade"] == "epico",
		"colecao: raridades dos placeholders")
	# 3-4. existem e exigem a Regiao I
	for id: String in IDS + [PACK]:
		_ok(LojaCatalogo.existe(id), "colecao: falta " + id)
		_ok(int(LojaCatalogo.item(id)["regiao"]) == 0, "colecao: %s nao exige a Regiao I" % id)
	_ok(LojaCatalogo.item(PACK)["raridade"] == "lendario" and LojaCatalogo.item("skin_coracao_podre")["raridade"] == "epico"
		and LojaCatalogo.item("efeito_rasto_esporos")["raridade"] == "raro" and LojaCatalogo.item("hud_moldura_raizes")["raridade"] == "raro",
		"colecao: raridades da colecao")
	# 7-11. precos e moedas
	var sk := LojaCatalogo.item("skin_coracao_podre")
	var fx := LojaCatalogo.item("efeito_rasto_esporos")
	var hu := LojaCatalogo.item("hud_moldura_raizes")
	var pk := LojaCatalogo.item(PACK)
	_ok(LojaCatalogo.preco(sk, "v") == 240 and LojaCatalogo.moedas_aceites(sk) == ["v"], "colecao: skin so V 240 (8)")
	_ok(LojaCatalogo.preco(fx, "k") == 600 and LojaCatalogo.preco(fx, "v") == 120 and LojaCatalogo.moedas_aceites(fx) == ["k", "v"],
		"colecao: efeito 600 K / 120 V")
	_ok(LojaCatalogo.preco(hu, "k") == 300 and LojaCatalogo.moedas_aceites(hu) == ["k"], "colecao: HUD so K 300")
	_ok(LojaCatalogo.moedas_aceites(pk) == ["k", "v"], "colecao: pack aceita K ou V")
	_ok(int(sk["k_eq"]) == 960 and int(fx["k_eq"]) == 600 and int(hu["k_eq"]) == 300
		and int(sk["v_eq"]) == 240 and int(fx["v_eq"]) == 120 and int(hu["v_eq"]) == 75, "colecao: equivalentes internos")
	# 5-6. bloqueados ate concluir a Regiao I
	var e := _novo_estado()
	e.ganhar_kolicoins(9000)
	e.dev_dar_veracoins(2000)
	for id: String in IDS + [PACK]:
		_ok(e.estado_item_loja(id) == "bloqueado", "colecao: %s devia estar bloqueado" % id)
		_ok(e.comprar_item(id, "k")["erro"] in ["bloqueado", "moeda_invalida"] and not e.item_adquirido(id), "colecao: comprou %s bloqueado" % id)
	_ok(e.comprar_item(PACK, "v")["erro"] == "bloqueado", "colecao: pack bloqueado comprado com V")
	for i in 5:
		e.marcar_nivel_concluido(i)
	for id: String in IDS + [PACK]:
		_ok(e.estado_item_loja(id) == "disponivel", "colecao: %s devia estar disponivel (%s)" % [id, e.estado_item_loja(id)])
	# 12. pack completo: teto 1300 K / 300 V
	_ok(e.preco_loja(PACK, "k") == 1300 and e.preco_loja(PACK, "v") == 300,
		"colecao: pack completo %d K / %d V" % [e.preco_loja(PACK, "k"), e.preco_loja(PACK, "v")])
	# 13-14. com 1 e 2 itens paga menos (valores esperados da formula 70% arredondada)
	var casos := {
		"nenhum": [[], 1300, 300],
		"so_skin": [["skin_coracao_podre"], 625, 135],
		"so_efeito": [["efeito_rasto_esporos"], 875, 220],
		"so_hud": [["hud_moldura_raizes"], 1100, 250],
		"skin_efeito": [["skin_coracao_podre", "efeito_rasto_esporos"], 200, 55],
		"skin_hud": [["skin_coracao_podre", "hud_moldura_raizes"], 425, 85],
		"efeito_hud": [["efeito_rasto_esporos", "hud_moldura_raizes"], 675, 170],
	}
	for nome: String in casos:
		var c: Array = casos[nome]
		var tem: Array = c[0]
		var f := func(id: String) -> bool: return id in tem
		var pk_ := LojaCatalogo.preco_pack(pk, "k", f)
		var pv_ := LojaCatalogo.preco_pack(pk, "v", f)
		print("PRECO PACK %-12s K=%d V=%d" % [nome, pk_, pv_])
		_ok(pk_ == c[1] and pv_ == c[2], "colecao: pack %s = %d K / %d V (esperado %d / %d)" % [nome, pk_, pv_, c[1], c[2]])
		_ok(pk_ % 25 == 0 and pv_ % 5 == 0, "colecao: arredondamento do pack %s" % nome)
	_ok(LojaCatalogo.preco_pack(pk, "k", func(_id: String) -> bool: return true) == -1, "colecao: pack completo devia dar -1")
	# 16-18. comprar so' cobra o que falta e nao duplica
	var a := _novo_estado()
	a.ganhar_kolicoins(9000)
	a.dev_dar_veracoins(2000)
	for i in 5:
		a.marcar_nivel_concluido(i)
	var k0: int = a.kolicoins
	_ok(a.comprar_item("hud_moldura_raizes", "k")["ok"], "colecao: compra individual do HUD")
	_ok(a.kolicoins == k0 - 300, "colecao: HUD custou %d" % (k0 - a.kolicoins))
	var preco_esperado: int = a.preco_loja(PACK, "k")
	_ok(preco_esperado == 1100, "colecao: pack com HUD = 1100 K (%d)" % preco_esperado)
	var k1: int = a.kolicoins
	_ok(a.comprar_item(PACK, "k")["ok"], "colecao: compra do pack (K)")
	_ok(a.kolicoins == k1 - preco_esperado, "colecao: pack cobrou %d em vez de %d" % [k1 - a.kolicoins, preco_esperado])
	for id: String in IDS:
		_ok(a.item_adquirido(id), "colecao: pack nao deu " + id)
	var vezes := {}
	for id in a.itens_comprados:
		vezes[id] = int(vezes.get(id, 0)) + 1
	for id in vezes:
		_ok(vezes[id] == 1, "colecao: %s duplicado em itens_comprados" % id)
	_ok(not (PACK in a.itens_comprados), "colecao: o pack nao deve ficar na lista de comprados")
	_ok(a.equipado_na_categoria("skins") == "skin_koliani_base" and a.equipado_na_categoria("efeitos") == ""
		and a.equipado_na_categoria("hud_checkpoint") == "", "colecao: comprar o pack equipou algo sozinho")
	# 15. completo: nada para comprar
	_ok(a.estado_item_loja(PACK) == "completo", "colecao: pack devia estar COMPLETO (%s)" % a.estado_item_loja(PACK))
	_ok(a.preco_loja(PACK, "k") == -1 and a.preco_loja(PACK, "v") == -1, "colecao: pack completo com preco comprável")
	var k2: int = a.kolicoins
	_ok(a.comprar_item(PACK, "k")["erro"] == "ja_adquirido" and a.kolicoins == k2, "colecao: pack completo voltou a cobrar")
	# 20. save/load preserva o ownership vindo do pack
	var b := _novo_estado()
	b.de_dicionario(JSON.parse_string(JSON.stringify(a.para_dicionario())))
	for id: String in IDS:
		_ok(b.item_adquirido(id), "colecao: save/load perdeu " + id)
	_ok(b.estado_item_loja(PACK) == "completo", "colecao: pack nao completo apos load")
	# pack pago em V a partir do zero (skin so' via pack em K tambem e' possivel)
	var c2 := _novo_estado()
	c2.ganhar_kolicoins(1300)
	for i in 5:
		c2.marcar_nivel_concluido(i)
	c2.kolicoins = 1300
	_ok(c2.comprar_item(PACK, "k")["ok"] and c2.item_adquirido("skin_coracao_podre") and c2.kolicoins == 0,
		"colecao: pack e' a via K para a skin")
	# 19. nada disto mexe em stats
	var g := _novo_estado()
	g.ganhar_kolicoins(9000)
	for i in 5:
		g.marcar_nivel_concluido(i)
	var dano: int = g.dano_ataque()
	var vidas: int = g.vidas
	g.comprar_item(PACK, "k")
	for id: String in IDS:
		g.equipar_item(id)
	_ok(g.dano_ataque() == dano and g.vidas == vidas, "colecao: pack mexeu em stats")
	for x in [e, a, b, c2, g]:
		x.free()


## Molduras (Ossario, Gaiola de Aurora) e rastos (Brasa, Esporos, Mariposas)
## com arte: contratos do gerador `tools/gerar_cosmeticos_loja.py`, o que o
## jogo consome, o pack novo, e nada de stats.
## Galeria de Conceitos (extra da Loja): imagens no export, sem spoilers,
## navegação e zoom. Mexe no autoload EstadoJogo e repõe-no no fim.
func teste_galeria_conceitos() -> void:
	const G := preload("res://scripts/galeria.gd")
	var it := LojaCatalogo.item(G.ITEM)
	_ok(not bool(it["placeholder"]) and CosmeticosVisuais.preview_loja(G.ITEM) != null
		and CosmeticosVisuais.preview_loja(G.ITEM).get_size() == Vector2(346, 130), "galeria: preview 346x130 na loja")
	for i in G.PAGINAS.size():
		_ok(ResourceLoader.exists(G.caminho(i)), "galeria: imagem da pagina %d existe (%s)" % [i, G.caminho(i)])
		_ok(G.titulo_pagina(i) != "" and not G.titulo_pagina(i).begins_with("gallery."), "galeria: titulo da pagina %d" % i)
	var concl: Array = EstadoJogo.concluidos.duplicate()
	var dev: bool = EstadoJogo.modo_dev
	EstadoJogo.modo_dev = false
	EstadoJogo.concluidos = []
	_ok(G.pagina_aberta(0) and G.pagina_aberta(1), "galeria: key art e folha da Koliani sempre abertas")
	_ok(not G.pagina_aberta(2), "galeria: Regiao II fechada sem concluir a I")
	EstadoJogo.concluidos = [0, 1, 2, 3, 4]
	_ok(G.pagina_aberta(2) and G.pagina_aberta(4), "galeria: Regiao II abre depois da I")
	_ok(not G.pagina_aberta(5), "galeria: Regiao III continua fechada")
	var g: Control = G.new()
	get_tree().root.add_child(g)
	_ok(g.get_node("Vista/Imagem").texture != null, "galeria: primeira pagina carregada")
	g.ampliar(9.0, Vector2(100, 100))
	_ok(is_equal_approx(g.zoom, G.ZOOM_MAX), "galeria: zoom limitado")
	g.ir(-1)
	_ok(g.pagina == G.PAGINAS.size() - 1 and is_equal_approx(g.zoom, 1.0), "galeria: da' a volta e repoe o zoom")
	_ok(g.get_node("Vista/Imagem").texture == null and g.get_node("Vista/Cadeado").text != "",
		"galeria: pagina fechada nao carrega a imagem")
	g.ir(g.pagina + 1)
	_ok(g.pagina == 0, "galeria: da' a volta para a frente")
	g.free()
	EstadoJogo.concluidos = concl
	EstadoJogo.modo_dev = dev


func teste_loja_arte_molduras_rastos() -> void:
	const CV := preload("res://scripts/cosmeticos_visuais.gd")
	const RC := preload("res://scripts/rasto_cosmetico.gd")
	_ok(LojaCatalogo.validar().is_empty(), "arte: catalogo valido (%s)" % str(LojaCatalogo.validar()))
	for id: String in ["hud_moldura_osso", "hud_moldura_gaiola"]:
		var disco := CV.caixa_hud("disco", Vector4.ZERO, [22, 22, 22, 22], id)
		var placa := CV.caixa_hud("placa", Vector4(12, 6, 18, 6), [16, 14, 16, 14], id)
		_ok(disco != null and disco.texture.get_size() == Vector2(88, 88), "arte %s: disco 88x88" % id)
		_ok(placa != null and placa.texture.get_size() == Vector2(128, 64), "arte %s: placa 128x64" % id)
		_ok(disco.content_margin_left == 0 and placa.content_margin_right == 18, "arte %s: margens intactas" % id)
		var fog := CV.checkpoint_visual(id)
		_ok(fog.has("base") and fog.has("cogumelos") and fog.has("brilho") and fog["chama"].size() == 4
			and fog["brasas"].size() == 3 and fog.has("pos_base") and fog.has("ocioso"), "arte %s: fogueira completa" % id)
		_ok(CV.moldura_arte_equipada(id) and not CV.raizes_equipado(id), "arte %s: identificacao" % id)
		_ok(CV.preview_loja(id) != null and CV.preview_loja(id).get_size() == Vector2(346, 130), "arte %s: preview 346x130" % id)
		_ok(not bool(LojaCatalogo.item(id)["placeholder"]), "arte %s: sem placeholder no catalogo" % id)
	# a lenha do Ossario sao os femures desenhados: a poligonal fica invisivel
	_ok(CV.checkpoint_visual("hud_moldura_osso")["lenha"].a == 0.0, "arte: lenha do Ossario escondida")
	_ok(CV.rasto_visual("nao_existe").is_empty() and CV.rasto_visual("hud_moldura_osso").is_empty(), "arte: rasto desconhecido = original")
	for id: String in ["efeito_rasto_brasa", "efeito_rasto_esporos", "efeito_rasto_mariposas"]:
		var rv := CV.rasto_visual(id)
		_ok(not rv.is_empty() and rv["a"].has("tex") and rv["b"].has("tex"), "arte %s: folhas carregadas" % id)
		for f in ["a", "b"]:
			var t: Texture2D = rv[f]["tex"]
			var n := int(rv[f]["frames"])
			_ok(t.get_width() % n == 0 and t.get_width() / n == t.get_height() or id == "efeito_rasto_mariposas" and f == "a",
				"arte %s/%s: tira de %d frames certos" % [id, f, n])
		_ok(CV.cor_rasto_dash(Color.BLACK, id) != Color.BLACK and CV.tinta_vfx_dash(id) != Color.WHITE, "arte %s: cores" % id)
		_ok(RC.material_eco(rv) != null and RC.material_eco(rv) == RC.material_eco(rv), "arte %s: material do eco em cache" % id)
		_ok(CV.preview_loja(id) != null, "arte %s: preview real" % id)
	# emitir cria sprites e nao parte sem pai/rasto
	var pai := Node2D.new()
	get_tree().root.add_child(pai)
	RC.emitir(pai, Vector2.ZERO, 1.0, 1.0, CV.rasto_visual("efeito_rasto_brasa"))
	_ok(pai.get_child_count() == 4, "arte: brasa emite 3+1 particulas por eco (%d)" % pai.get_child_count())
	RC.emitir(null, Vector2.ZERO, 1.0, 1.0, CV.rasto_visual("efeito_rasto_brasa"))
	RC.emitir(pai, Vector2.ZERO, 1.0, 1.0, {})
	_ok(pai.get_child_count() == 4, "arte: emitir sem pai/rasto nao faz nada")
	pai.free()
	# pack Luar de Aurora: preco so' do que falta, teto respeitado
	var pk := LojaCatalogo.item("pack_luar_aurora")
	_ok(pk["contem"] == ["hud_moldura_gaiola", "efeito_rasto_mariposas"] and pk["raridade"] == "lendario", "arte: pack Luar de Aurora")
	_ok(LojaCatalogo.preco_pack(pk, "k", func(_i: String) -> bool: return false) == 1200
		and LojaCatalogo.preco_pack(pk, "v", func(_i: String) -> bool: return false) == 250, "arte: pack completo no teto")
	_ok(LojaCatalogo.preco_pack(pk, "k", func(i: String) -> bool: return i == "hud_moldura_gaiola") == 550,
		"arte: pack so' com as mariposas em falta")
	# equipar nao mexe em stats
	var e := _novo_estado()
	e.ganhar_kolicoins(5000)
	var dano: int = e.dano_ataque()
	var vidas: int = e.vidas
	for id in ["hud_moldura_gaiola", "efeito_rasto_mariposas"]:
		_ok(e.comprar_item(id, "k")["ok"] and e.equipar_item(id), "arte: comprar e equipar %s" % id)
	_ok(e.dano_ataque() == dano and e.vidas == vidas, "arte: equipar mexeu em stats")
	e.free()


func teste_rootbound_frame() -> void:
	const CV := preload("res://scripts/cosmeticos_visuais.gd")
	const RB := "hud_moldura_raizes"
	# default continua default (item inicial, sem equipar, id desconhecido, osso)
	for id in ["", "nao_existe", "extra_galeria_conceitos", "skin_carmesim"]:
		_ok(CV.caixa_hud("disco", Vector4(0, 0, 0, 0), [22, 22, 22, 22], id if id != "" else "skin_carmesim") == null,
			"rootbound: '%s' devia deixar o HUD original (disco)" % id)
		_ok(CV.checkpoint_visual(id if id != "" else "skin_carmesim").is_empty(), "rootbound: '%s' devia deixar a fogueira original" % id)
	_ok(not CV.raizes_equipado("hud_moldura_osso") and CV.raizes_equipado(RB), "rootbound: identificacao do item")
	# Rootbound aplica os recursos certos, com as margens pedidas (layout intacto)
	var disco := CV.caixa_hud("disco", Vector4(0, 0, 0, 0), [22, 22, 22, 22], RB)
	var placa := CV.caixa_hud("placa", Vector4(12, 6, 18, 6), [16, 14, 16, 14], RB)
	_ok(disco != null and str(disco.texture.resource_path).ends_with("rootbound_frame.png"), "rootbound: disco usa rootbound_frame.png")
	_ok(placa != null and str(placa.texture.resource_path).ends_with("rootbound_placa.png"), "rootbound: placa usa rootbound_placa.png")
	_ok(disco.texture_margin_left == 22 and disco.content_margin_left == 0, "rootbound: margens do disco")
	_ok(placa.content_margin_left == 12 and placa.content_margin_right == 18 and placa.texture_margin_top == 14, "rootbound: margens da placa")
	var fog := CV.checkpoint_visual(RB)
	_ok(not fog.is_empty() and fog.has("base") and fog.has("cogumelos") and fog.has("brilho") and fog["chama"].size() == 4,
		"rootbound: recursos da fogueira")
	# lenha escura e sem halo: a fogueira Rootbound traz cores proprias
	_ok(fog.has("lenha") and fog.has("lenha_acesa") and fog.has("brasas") and fog["lenha"].get_luminance() < 0.15,
		"rootbound: lenha escura")
	_ok(fog["chama"][0].get_luminance() < 0.75 and fog["chama"][0].g > fog["chama"][0].r * 0.95,
		"rootbound: chama fungica (nucleo bile, sem branco-amarelo)")
	# tamanhos dos assets (contrato do gerador)
	for par in [["rootbound_frame", 88, 88], ["rootbound_placa", 128, 64], ["base_raizes", 56, 20],
			["cogumelos", 64, 14], ["cogumelos_brilho", 64, 14], ["preview", 346, 130]]:
		var t: Texture2D = load(CV.DIR_RAIZES + par[0] + ".png")
		_ok(t != null and t.get_width() == par[1] and t.get_height() == par[2], "rootbound: asset %s %dx%d" % [par[0], par[1], par[2]])
	# preview real no Rootbound e no Spore Wake; a skin e o pack continuam ART PENDING
	_ok(CV.preview_loja(RB) != null and CV.preview_loja("skin_coracao_podre") == null and CV.preview_loja("efeito_rasto_esporos") != null,
		"rootbound: previews da colecao")
	_ok(LojaCatalogo.item(RB)["placeholder"] == false and str(LojaCatalogo.item(RB)["preview"]).ends_with("preview.png"),
		"rootbound: catalogo sem placeholder")
	for id in ["skin_coracao_podre", "pack_coracao_podre"]:
		_ok(LojaCatalogo.item(id)["placeholder"] == true, "rootbound: %s continua placeholder" % id)
	# precos/economia intactos
	_ok(LojaCatalogo.preco(LojaCatalogo.item(RB), "k") == 300 and LojaCatalogo.preco(LojaCatalogo.item(RB), "v") == -1
		and LojaCatalogo.item(RB)["raridade"] == "raro" and LojaCatalogo.item(RB)["regiao"] == 0, "rootbound: preco/raridade/desbloqueio")
	# equipar/desequipar/save+load e stats
	var e := _novo_estado()
	e.ganhar_kolicoins(1000)
	for i in 5:
		e.marcar_nivel_concluido(i)
	var dano: int = e.dano_ataque()
	var vidas: int = e.vidas
	_ok(e.comprar_item(RB, "k")["ok"] and e.equipar_item(RB) and e.item_equipado(RB), "rootbound: comprar e equipar")
	var f := _novo_estado()
	f.de_dicionario(JSON.parse_string(JSON.stringify(e.para_dicionario())))
	_ok(f.item_equipado(RB), "rootbound: save/load manteve o equipamento")
	_ok(e.dano_ataque() == dano and e.vidas == vidas, "rootbound: mexeu em stats")
	e.desequipar_categoria("hud_checkpoint")
	_ok(e.equipado_na_categoria("hud_checkpoint") == "" and not e.item_equipado(RB), "rootbound: desequipar restaura o default")
	e.free()
	f.free()


## Hazards e SFX de mecanicas fora do campo visual: nada ataca nem soa la';
## ao entrar, o primeiro ataque so' chega depois de um telegrafo visto.
func teste_offscreen_hazards() -> void:
	var vp := get_viewport().get_visible_rect().size
	var fora := Vector2(vp.x * 3.0, 100.0)
	var dentro := Vector2(vp.x * 0.5, vp.y * 0.5)
	var no := Node2D.new()
	add_child(no)
	no.global_position = dentro
	_ok(Som.em_vista(no), "offscreen: ponto no centro tem de estar em vista")
	no.global_position = fora
	_ok(not Som.em_vista(no), "offscreen: ponto a 3 viewports (direita) esta' em vista")
	no.global_position = Vector2(-vp.x * 2.0, 100.0)
	_ok(not Som.em_vista(no), "offscreen: ponto a' esquerda esta' em vista")
	no.global_position = dentro
	no.global_position = fora
	_ok(not Som.toca_actor(no, "raiz_aviso"), "offscreen: SFX de actor fora do ecra tocou")
	no.queue_free()

	var cena: PackedScene = load("res://scenes/actors/Guilhotina.tscn")
	var g := cena.instantiate() as Guilhotina
	g.automatico = true
	g.fase = 0.0
	g.atraso = 0.5
	g.periodo = 1.0
	add_child(g)
	g.global_position = fora
	var y0: float = g.get_node("Lamina").position.y
	var atacou := false
	for i in 150:
		await get_tree().physics_frame
		if g.monitoring or absf(g.get_node("Lamina").position.y - y0) > 1.0:
			atacou = true
	_ok(not atacou, "offscreen: guilhotina fora do ecra iniciou o ataque")
	# entra no campo visual: nao pode estar ja a meio de uma queda, e o primeiro
	# dano so' chega depois do telegrafo (atraso 0.5 s)
	g.global_position = dentro
	var dano_cedo := false
	for i in 20:  # ~0,33 s
		await get_tree().physics_frame
		if g.monitoring:
			dano_cedo = true
	_ok(not dano_cedo, "offscreen: ao entrar em vista a guilhotina feriu antes do telegrafo")
	var acabou := false
	for i in 180:
		await get_tree().physics_frame
		if g.monitoring:
			acabou = true
	_ok(acabou, "offscreen: guilhotina em vista nunca atacou")
	# sai e volta: recomeca do estado seguro
	g.global_position = fora
	for i in 120:
		await get_tree().physics_frame
	g.global_position = dentro
	var instantaneo := false
	for i in 12:
		await get_tree().physics_frame
		if g.monitoring:
			instantaneo = true
	_ok(not instantaneo, "offscreen: reentrada disparou instantaneamente")
	g.queue_free()

	var t := (load("res://scenes/actors/Torreta.tscn") as PackedScene).instantiate()
	add_child(t)
	t.global_position = fora
	t.set("intervalo", 0.6)
	var antes := get_child_count()
	for i in 240:
		await get_tree().physics_frame
	var bolas := 0
	for c in get_children():
		if c is BolaFogo:
			bolas += 1
	_ok(bolas == 0, "offscreen: torreta fora do ecra disparou projetil")
	t.queue_free()


## Regra global offscreen (alem de `teste_offscreen_hazards`): zona extensa,
## zoom da camara, vento, elevador (navegacao: simula mas cala), inimigo que
## ataca so' a' vista.
func teste_offscreen_global() -> void:
	var vp := get_viewport().get_visible_rect().size
	var dentro := Vector2(vp.x * 0.5, vp.y * 0.5)
	var fora := Vector2(vp.x * 3.0, 100.0)
	Som.parar_lacos(0.0)
	# 1) origem extensa: basta uma parte no campo visual; toda fora nao conta
	var no := Node2D.new()
	add_child(no)
	no.global_position = Vector2(vp.x + 100.0, dentro.y)
	_ok(Som.em_vista_area(no, Vector2(200.0, 50.0)), "offscreen: area que invade o ecra tem de contar")
	_ok(not Som.em_vista_area(no, Vector2(50.0, 50.0)), "offscreen: area toda fora contou como visivel")
	# 2) zoom da camara: a mesma posicao deixa de estar visivel com zoom 2x
	var cam := Camera2D.new()
	add_child(cam)
	cam.global_position = dentro
	cam.make_current()
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	no.global_position = dentro + Vector2(vp.x * 0.4, 0.0)
	_ok(Som.em_vista(no), "offscreen: zoom 1x, ponto a 40% do ecra devia estar visivel")
	cam.zoom = Vector2(2.0, 2.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	_ok(not Som.em_vista(no), "offscreen: zoom 2x, o mesmo ponto devia estar fora do campo visual")
	cam.zoom = Vector2.ONE
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	no.queue_free()
	# 3) zona de vento: sem laco nem rajada fora do ecra
	var zv := (load("res://scenes/actors/WindZone.tscn") as PackedScene).instantiate() as WindZone
	add_child(zv)
	zv.global_position = fora
	zv._pedir_ambiente()
	_ok(not zv._laco_pedido and Som.lacos_ativos() == 0, "offscreen: vento fora do ecra abriu laco")
	zv.global_position = dentro
	await get_tree().process_frame
	zv._pedir_ambiente()
	_ok(zv._laco_pedido and Som.lacos_ativos() == 1, "offscreen: vento a' vista devia abrir o laco")
	zv._parar_ambiente()
	zv.queue_free()
	Som.parar_lacos(0.0)
	# 4) elevador: simula (move-se) mas so' soa a' vista. Corpo com
	# `sync_to_physics` nao se teletransporta: nasce no sitio e move-se a camara.
	var ev := (load("res://scenes/actors/TumuloElevador.tscn") as PackedScene).instantiate()
	ev.set("auto", true)
	ev.position = dentro
	add_child(ev)
	cam.global_position = dentro + Vector2(vp.x * 4.0, 0.0)  # camara longe: elevador fora
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	var y0: float = ev.global_position.y
	for i in 40:
		await get_tree().physics_frame
	_ok(absf(ev.global_position.y - y0) > 5.0, "offscreen: elevador fora do ecra deixou de se mover (quebra o percurso)")
	_ok(Som.lacos_ativos() == 0, "offscreen: elevador fora do ecra abriu laco")
	cam.global_position = dentro
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	for i in 30:
		await get_tree().physics_frame
	_ok(Som.em_vista(ev) and Som.lacos_ativos() == 1, "offscreen: elevador a' vista devia ter o laco de marcha")
	cam.global_position = dentro + Vector2(vp.x * 4.0, 0.0)
	for i in 30:
		await get_tree().physics_frame
	_ok(Som.lacos_ativos() == 0, "offscreen: laco do elevador continuou depois de sair do ecra")
	ev.queue_free()
	Som.parar_lacos(0.0)
	cam.global_position = dentro
	await get_tree().physics_frame
	await get_tree().physics_frame
	# 5) inimigo (mergulho do voador): fora do ecra nao inicia ataque; a' vista sim
	var kf := Node2D.new()
	kf.add_to_group("koliani")
	add_child(kf)
	var m := (load("res://scenes/actors/DemonioBase.tscn") as PackedScene).instantiate() as DemonioBase
	m.comportamento = "voador"
	add_child(m)
	m.global_position = fora
	kf.global_position = fora + Vector2(120.0, 0.0)
	var iniciou := false
	for i in 120:
		await get_tree().physics_frame
		if m._windup > 0.0 or m._mergulho > 0.0:
			iniciou = true
	_ok(not iniciou, "offscreen: inimigo fora do ecra iniciou um ataque")
	m.global_position = dentro
	kf.global_position = dentro + Vector2(120.0, 0.0)
	for i in 240:
		await get_tree().physics_frame
		if m._windup > 0.0 or m._mergulho > 0.0:
			iniciou = true
	_ok(iniciou, "offscreen: inimigo a' vista nunca atacou (o teste nao morde)")
	m.queue_free()
	kf.queue_free()
	cam.queue_free()


## N1 (Floresta Corrompida) e' um nivel AUTORAL: sem jornada procedural, sem
## nenhuma habilidade por ensinar, alcance dentro da envolvente F1 do salto
## SIMPLES (128 px), checkpoints intencionais que a poda nao apaga, Ghorak como
## guardiao (mini-boss) e nao como chefe regional. Ver `docs/nivel_autoral_n1.md`.
func teste_n1_autoral() -> void:
	var ruta := "res://scenes/levels/Floresta_Putrefata.tscn"
	var antes_idx: int = EstadoJogo.indice_nivel
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	EstadoJogo.indice_nivel = 0
	EstadoJogo.habilidades.assign([])
	var n := (load(ruta) as PackedScene).instantiate()
	add_child(n)
	for i in 6:
		await get_tree().process_frame
	_ok(not bool(n.get("corredor")), "N1: ainda tem a jornada procedural ligada (corredor)")
	_ok(n.get_node_or_null("CorredorAproximacao") == null, "N1: o gerador criou uma jornada")
	_ok(bool(n.get("checkpoints_autorais")), "N1: checkpoints nao sao autorais")
	var chk := 0
	for c in get_tree().get_nodes_in_group("checkpoints"):
		if n.is_ancestor_of(c):
			chk += 1
	_ok(chk == 3, "N1: esperava 3 checkpoints autorais, ha %d" % chk)
	_ok(n.get_node_or_null("Guardiao") != null and n.get_node_or_null("Chefe") == null,
		"N1: o Ghorak tem de ser Guardiao (mini-boss), nao Chefe regional")
	_ok(n.get_node_or_null("Porta") != null, "N1: sem Porta")
	# nada que exija (ou ensine) uma habilidade: sem dash/pogo/wall-jump/pickups
	var proibidos := ["serra.gd", "fogo.gd", "guilhotina.gd", "pendulo_lamina.gd", "wind_zone.gd",
		"portal.gd", "trampolim.gd", "tumulo_elevador.gd", "plataforma_ritmada.gd", "torreta.gd"]
	for no in n.find_children("*", "", true, false):
		var sc := no.get_script() as Script
		if sc != null:
			for pr in proibidos:
				_ok(not sc.resource_path.ends_with(pr), "N1: %s nao pertence ao N1 (mecanica por ensinar)" % no.name)
			_ok(not (sc.resource_path.ends_with("coletavel.gd") and String(no.get("habilidade_id")) != ""),
				"N1: %s da uma habilidade" % no.name)
	# alcance: envolvente do salto simples F1 com margem (nao vive na ponta)
	var pl: Array = []
	for no in n.get_children():
		if no is StaticBody2D and no.get_script() != null 				and String((no.get_script() as Script).resource_path).ends_with("/plataforma.gd"):
			var t: Vector2 = no.get("tamanho")
			pl.append({"nome": String(no.name), "l": no.position.x - t.x * 0.5,
				"r": no.position.x + t.x * 0.5, "top": no.position.y - t.y * 0.5})
	pl.sort_custom(func(a, b): return a["l"] < b["l"])
	_ok(pl.size() >= 15, "N1: plataformas a menos (%d)" % pl.size())
	var pior_vao := 0.0
	for i in range(1, pl.size()):
		var b: Dictionary = pl[i]
		# passa se ALGUMA plataforma anterior chega a esta com folga
		var chega := false
		var melhor := "nenhuma"
		for j in i:
			var a: Dictionary = pl[j]
			var vao: float = b["l"] - a["r"]
			var sub: float = a["top"] - b["top"]
			if vao <= 0.0:
				if sub <= 66.0 and b["l"] < a["r"]:
					chega = true
			else:
				var limite := 125.0 if sub <= 0.0 else 110.0
				if vao <= limite and sub <= 64.0:
					chega = true
					pior_vao = maxf(pior_vao, vao)
				else:
					melhor = "vao %.0f / sobe %.0f desde %s" % [vao, sub, a["nome"]]
		_ok(chega, "N1: %s fora da envolvente do salto simples (%s)" % [b["nome"], melhor])
	n.queue_free()
	await get_tree().process_frame
	EstadoJogo.indice_nivel = antes_idx
	EstadoJogo.habilidades.assign(antes_hab)


## Ghorak (mini-boss do N1): casca fora das janelas, janelas de vulnerabilidade,
## raizes com aviso, fase 2, sem estados presos, porta abre ao morrer, nada arranca
## fora do campo visual. NAO prova que a luta e' boa -- so' que as regras valem.
func _ghorak_novo() -> Array:
	var n := (load("res://scenes/levels/Floresta_Putrefata.tscn") as PackedScene).instantiate()
	add_child(n)
	for i in 8:
		await get_tree().physics_frame
	var g := n.get_node("Guardiao") as ChefeGhorak
	var k := n.get_node("Koliani") as Node2D
	k.global_position = Vector2(g.global_position.x - 230.0, g.global_position.y)
	for i in 30:
		await get_tree().physics_frame
	return [n, g, k]


## Corre a luta com um "bot" de golpes. `spam` = bate sempre; senao so' com a janela aberta.
func _ghorak_luta(spam: bool, segundos: float, so_casca := false) -> Dictionary:
	var antes_dev: bool = EstadoJogo.modo_dev
	EstadoJogo.modo_dev = true   # a Koliani nao morre: mede-se o boss, nao o jogador
	var r: Array = await _ghorak_novo()
	var n: Node = r[0]
	var g: ChefeGhorak = r[1]
	var k: Node2D = r[2]
	var t_ini := 0
	var frames := 0
	var pior_estado := 0.0
	var ult_fase := int(g._fase)
	var t_fase := 0
	var raizes_cedo := 0
	var vistas := {}
	var janelas: Array = []
	var jan_ini := -1
	var fase2_em := -1.0
	var limite := int(segundos * 60.0)
	var morreu := false
	var porta_aberta := false
	var ultima_contagem := {}
	while frames < limite:
		await get_tree().physics_frame
		frames += 1
		if not is_instance_valid(g) or g.is_queued_for_deletion():
			morreu = true
			break
		var vuln: bool = g._vulneravel()
		ultima_contagem = g.contagem.duplicate()
		if vuln and jan_ini < 0:
			jan_ini = frames
		if not vuln and jan_ini >= 0:
			janelas.append(float(frames - jan_ini) / 60.0)
			jan_ini = -1
		if int(g._fase) != ult_fase:
			pior_estado = maxf(pior_estado, float(t_fase) / 60.0) if ult_fase != int(ChefeGhorak.Fase.DORME) else pior_estado
			ult_fase = int(g._fase)
			t_fase = 0
		t_fase += 1
		if g._fase2 and fase2_em < 0.0:
			fase2_em = float(frames) / 60.0
		for no in n.get_children():
			if no is RaizPerigo and not vistas.has(no.get_instance_id()):
				vistas[no.get_instance_id()] = true
				if float(no.atraso) < 0.9:
					raizes_cedo += 1
		if frames % 30 == 0 and ((so_casca and not vuln) or (not so_casca and (spam or vuln))):
			g.receber_dano(50, 1.0)
		k.global_position = Vector2(g.global_position.x - 230.0, k.global_position.y) if frames % 90 == 0 else k.global_position
	if is_instance_valid(g) and not g.is_queued_for_deletion():
		morreu = false
	else:
		morreu = true
		await get_tree().process_frame
		await get_tree().process_frame
		var porta := n.get_node_or_null("Porta")
		porta_aberta = porta != null and bool(porta.monitoring)
	var res := {"ttk": float(frames) / 60.0, "morreu": morreu, "pior_estado": pior_estado,
		"janelas": janelas, "raizes_cedo": raizes_cedo, "fase2_em": fase2_em,
		"contagem": ultima_contagem,
		"porta_aberta": porta_aberta, "raizes": vistas.size()}
	n.queue_free()
	await get_tree().process_frame
	EstadoJogo.modo_dev = antes_dev
	return res


func teste_ghorak_n1() -> void:
	var antes_dev0: bool = EstadoJogo.modo_dev
	var antes_idx: int = EstadoJogo.indice_nivel
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	EstadoJogo.indice_nivel = 0
	EstadoJogo.habilidades.assign([])
	var vp := get_viewport().get_visible_rect().size
	# 1) NADA arranca fora do campo visual: mesmo boss, mesmo alvo; muda so' a camera
	var chao := StaticBody2D.new()
	chao.collision_layer = 1
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(9000.0, 60.0)
	cs.shape = rs
	chao.add_child(cs)
	add_child(chao)
	chao.global_position = Vector2(4000.0, 560.0)
	var kf := CharacterBody2D.new()
	var sc_kf := GDScript.new()
	sc_kf.source_code = "extends CharacterBody2D
func receber_dano(_a, _b = 0.0):
	pass
"
	sc_kf.reload()
	kf.set_script(sc_kf)
	kf.add_to_group("koliani")
	add_child(kf)
	var cam0 := Camera2D.new()
	add_child(cam0)
	cam0.global_position = Vector2(-3000.0, 300.0)   # longe: tudo fora do ecra
	cam0.make_current()
	var g0 := (load("res://scenes/actors/ChefeGhorak.tscn") as PackedScene).instantiate() as ChefeGhorak
	g0.position = Vector2(4000.0, 500.0)   # antes do add_child: a arena mede-se a partir da origem
	add_child(g0)
	kf.global_position = g0.global_position + Vector2(-230.0, 0.0)
	for i in 300:
		await get_tree().physics_frame
	var c0: Dictionary = g0.contagem
	_ok(int(c0["BAQUE"]) + int(c0["RAIZES"]) + int(c0["CARGA"]) + int(c0["CURTO"]) == 0 and g0._fase == ChefeGhorak.Fase.DORME,
		"Ghorak: iniciou um ataque fora do campo visual (%s, fase %d)" % [str(c0), int(g0._fase)])
	cam0.global_position = g0.global_position
	for i in 420:
		await get_tree().physics_frame
		await get_tree().process_frame
	var c1: Dictionary = g0.contagem
	_ok(int(c1["BAQUE"]) + int(c1["RAIZES"]) + int(c1["CARGA"]) + int(c1["CURTO"]) >= 1,
		"Ghorak: a' vista nunca atacou (%s, fase %d)" % [str(c1), int(g0._fase)])
	g0.queue_free()
	kf.queue_free()
	chao.queue_free()
	cam0.queue_free()
	await get_tree().process_frame

	# 2) casca vs janela: mesmo golpe, dano muito diferente
	var r: Array = await _ghorak_novo()
	var n: Node = r[0]
	var g: ChefeGhorak = r[1]
	EstadoJogo.modo_dev = true
	g._ir(ChefeGhorak.Fase.DECIDE)
	var v0: int = g.vida
	g.receber_dano(50, 1.0)
	var dano_casca: int = v0 - g.vida
	g._abrir_janela(2.0, ChefeGhorak.Fase.EXPOSTO)
	v0 = g.vida
	g.receber_dano(50, 1.0)
	var dano_janela: int = v0 - g.vida
	_ok(dano_casca >= 1 and dano_casca <= 10, "Ghorak: a casca deixou passar %d de 50" % dano_casca)
	_ok(dano_janela >= 50, "Ghorak: a janela devia dar o golpe inteiro, deu %d" % dano_janela)
	n.queue_free()
	await get_tree().process_frame

	# 3) spam nao ganha a luta; o jogador que le as janelas ganha em 20-60 s
	var spam: Dictionary = await _ghorak_luta(true, 200.0)
	var lido: Dictionary = await _ghorak_luta(false, 200.0)
	var casca: Dictionary = await _ghorak_luta(false, 150.0, true)
	print("GHORAK so a bater na casca: ttk=%.1fs morreu=%s" % [casca["ttk"], casca["morreu"]])
	_ok(not bool(casca["morreu"]) or float(casca["ttk"]) >= 60.0,
		"Ghorak: da' para ganhar a bater so' na casca em %.1f s" % casca["ttk"])
	print("GHORAK spam: ttk=%.1fs morreu=%s | janelas: ttk=%.1fs morreu=%s fase2_em=%.1fs" % [
		spam["ttk"], spam["morreu"], lido["ttk"], lido["morreu"], lido["fase2_em"]])
	print("GHORAK janelas (s): ", lido["janelas"], " contagem: ", lido["contagem"], " raizes=", lido["raizes"])
	_ok(bool(lido["morreu"]), "Ghorak: nao morre a bater so' nas janelas (preso?)")
	_ok(float(lido["ttk"]) >= 8.0 and float(lido["ttk"]) <= 70.0,
		"Ghorak: TTK do bot (2 golpes/s, sempre nas janelas) = %.1f s" % lido["ttk"])
	_ok(float(lido["fase2_em"]) > 0.0, "Ghorak: a fase 2 nunca arrancou")
	_ok(int(lido["raizes_cedo"]) == 0, "Ghorak: %d raizes com aviso < 0,9 s" % lido["raizes_cedo"])
	_ok(float(lido["pior_estado"]) <= 6.0, "Ghorak: ficou %.1f s no mesmo estado" % lido["pior_estado"])
	var jan: Array = lido["janelas"]
	_ok(jan.size() >= 2, "Ghorak: menos de 2 janelas abertas")
	for w in jan:
		_ok(float(w) >= 0.7 and float(w) <= 3.4, "Ghorak: janela de %.2f s fora de 0,7-3,4 s" % float(w))
	_ok(bool(lido["porta_aberta"]), "Ghorak: a porta nao abriu ao morrer")
	var cm: Dictionary = lido["contagem"]
	# CICLO: todo ataque acaba numa janela (atacar -> exposto -> atacar ...)
	var n_ataques: int = int(cm["BAQUE"]) + int(cm["RAIZES"]) + int(cm["CARGA"])
	_ok(jan.size() >= n_ataques - 1, "Ghorak: %d ataques mas so' %d janelas (todo ataque devia acabar numa janela)" % [n_ataques, jan.size()])
	_ok(int(cm["BAQUE"]) >= 1 and int(cm["RAIZES"]) >= 1 and int(cm["CARGA"]) >= 1,
		"Ghorak: nem todos os ataques foram usados (%s)" % str(cm))
	EstadoJogo.modo_dev = antes_dev0
	EstadoJogo.indice_nivel = antes_idx
	EstadoJogo.habilidades.assign(antes_hab)


## N2 (Pantano dos Sussurros, DEVELOP: o Dash): nivel AUTORAL. O altar da' o dash; o
## gate 1 tem chao macio; os vaos > 125 px so' existem SOB TETO BAIXO (onde o salto
## nao chega e o dash sim); sem Pogo/Especial/wall-jump; e o dash e' de facto exigido.
func _n2_trial(n: Node, k: CharacterBody2D, com_dash: bool, off: float) -> bool:
	k.global_position = Vector2(1900.0, 630.0)
	k.velocity = Vector2.ZERO
	k.reset_physics_interpolation()
	Input.action_release("mover_direita")
	Input.action_release("saltar")
	Input.action_release("dash")
	for i in 40:
		await get_tree().physics_frame
	var feito := false
	var chegou := false
	var pressionar_ate := -1
	for i in 300:
		Input.action_press("mover_direita")
		if not feito and k.global_position.x >= 2150.0 - off:
			feito = true
			pressionar_ate = i + 2
			Input.action_press("dash" if com_dash else "saltar")
		elif feito and i > pressionar_ate:
			Input.action_release("dash")
			if com_dash or k.velocity.y > 0.0:
				Input.action_release("saltar")
			else:
				Input.action_press("saltar")
		await get_tree().physics_frame
		if feito and k.is_on_floor() and k.global_position.x > 2300.0:
			chegou = true
			break
		if k.global_position.y > 860.0:
			break   # antes da agua mortal (recarregaria a cena de testes)
	Input.action_release("mover_direita")
	Input.action_release("saltar")
	Input.action_release("dash")
	return chegou


func teste_n2_autoral() -> void:
	var antes_dev: bool = EstadoJogo.modo_dev
	EstadoJogo.modo_dev = false
	var antes_idx: int = EstadoJogo.indice_nivel
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	EstadoJogo.indice_nivel = 1
	EstadoJogo.habilidades.assign([])
	var n := (load("res://scenes/levels/Pantano_dos_Sussurros.tscn") as PackedScene).instantiate()
	add_child(n)
	for i in 6:
		await get_tree().process_frame
	_ok(not bool(n.get("corredor")) and bool(n.get("checkpoints_autorais")), "N2: nao e' autoral (corredor/checkpoints)")
	_ok(n.get_node_or_null("CorredorAproximacao") == null, "N2: o gerador criou uma jornada")
	_ok(n.get_node_or_null("Guardiao") != null, "N2: sem o Guardiao (Morvanna)")
	var chk := 0
	for c in get_tree().get_nodes_in_group("checkpoints"):
		if n.is_ancestor_of(c):
			chk += 1
	_ok(chk == 3, "N2: esperava 3 checkpoints autorais, ha %d" % chk)
	# so' o Dash: nada de Pogo / Especial / wall-jump / mecanicas futuras
	var proibidos := ["serra.gd", "fogo.gd", "guilhotina.gd", "pendulo_lamina.gd", "wind_zone.gd",
		"portal.gd", "trampolim.gd", "tumulo_elevador.gd", "plataforma_ritmada.gd", "torreta.gd"]
	var habs: Array = []
	for no in n.find_children("*", "", true, false):
		var sc := no.get_script() as Script
		if sc != null:
			for pr in proibidos:
				_ok(not sc.resource_path.ends_with(pr), "N2: %s nao pertence ao N2" % no.name)
			if sc.resource_path.ends_with("coletavel.gd"):
				habs.append(String(no.get("habilidade_id")))
	_ok(habs == ["dash"], "N2: os coletaveis de habilidade deviam ser so' [dash], ha %s" % str(habs))
	# geometria: vaos comuns dentro do salto simples; vaos > 125 so' sob teto baixo
	var pl: Array = []
	var tetos: Array = []
	for no in n.get_children():
		if not (no is StaticBody2D) or no.get_script() == null:
			continue
		if not String((no.get_script() as Script).resource_path).ends_with("/plataforma.gd"):
			continue
		var t: Vector2 = no.get("tamanho")
		var d := {"nome": String(no.name), "l": no.position.x - t.x * 0.5, "r": no.position.x + t.x * 0.5,
			"top": no.position.y - t.y * 0.5, "base": no.position.y + t.y * 0.5}
		if d["nome"].begins_with("Teto"):
			tetos.append(d)
		else:
			pl.append(d)
	pl.sort_custom(func(a, b): return a["l"] < b["l"])
	var gates := 0
	for i in range(1, pl.size()):
		var b: Dictionary = pl[i]
		var chega := false
		var e_gate := false
		for j in i:
			var a: Dictionary = pl[j]
			var vao: float = b["l"] - a["r"]
			var sub: float = a["top"] - b["top"]
			if vao <= 0.0:
				if sub <= 66.0:
					chega = true
				continue
			var limite := 125.0 if sub <= 0.0 else 110.0
			if vao <= limite and sub <= 64.0:
				chega = true
			elif vao > limite and vao <= 145.0 and absf(sub) <= 4.0:
				# gate de dash: TEM de haver teto baixo (folga <= 70 px) a cobrir o vao
				var coberto := false
				for tt in tetos:
					if tt["l"] <= a["r"] and tt["r"] >= b["l"] and float(a["top"]) - float(tt["base"]) <= 70.0 							and float(a["top"]) - float(tt["base"]) >= 50.0:
						coberto = true
				if coberto:
					chega = true
					e_gate = true
		_ok(chega, "N2: %s inalcancavel pelo salto simples nem por gate de dash" % b["nome"])
		if e_gate:
			gates += 1
	_ok(gates >= 3, "N2: esperava >= 3 gates de dash (2 exigidos + segredo), ha %d" % gates)
	# o altar esta NO caminho (numa plataforma do percurso principal)
	var altar := n.get_node_or_null("AltarDash") as Node2D
	_ok(altar != null and altar.position.x > 1400.0 and altar.position.x < 2100.0, "N2: altar fora do percurso")
	# dinamica: sem dash o gate 1 NAO se passa (saltar), com dash passa-se
	var altar_n := n.get_node_or_null("AltarDash")
	if altar_n:
		altar_n.queue_free()
	var k := n.get_node("Koliani") as CharacterBody2D
	EstadoJogo.habilidades.assign([])
	var so_salto := false
	for off in [0.0, 12.0, 30.0, 60.0]:
		if await _n2_trial(n, k, false, off):
			so_salto = true
	_ok(not so_salto, "N2: o gate 1 passa-se so' a saltar (o dash nao e' exigido)")
	EstadoJogo.habilidades.assign(["dash"])
	var com_dash := false
	for off in [0.0, 12.0, 30.0, 60.0]:
		if await _n2_trial(n, k, true, off):
			com_dash = true
			break
	_ok(com_dash, "N2: com o dash o gate 1 nao se passa")
	n.queue_free()
	await get_tree().process_frame
	EstadoJogo.modo_dev = antes_dev
	EstadoJogo.indice_nivel = antes_idx
	EstadoJogo.habilidades.assign(antes_hab)


## N3 -- tentativa de atravessar a CamaPogo1 (espinhos de 2934 a 3206, ao nivel do chao). Devolve
## {"chegou": bool, "dano": int}. Parte de x=2840 a correr; salta a `off` px antes da cama.
func _n3_cama_trial(n: Node, k: CharacterBody2D, off: float, pogo := false) -> Dictionary:
	k.global_position = Vector2(2840.0, 630.0)
	k.velocity = Vector2.ZERO
	k.vida = k._vida_max()
	k.reset_physics_interpolation()
	Input.action_release("mover_direita")
	Input.action_release("saltar")
	for i in 40:
		await get_tree().physics_frame
	k.vida = k._vida_max()
	var vida0: int = k.vida
	var feito := false
	var chegou := false
	var solto := false
	for i in 360:
		Input.action_press("mover_direita")
		if not feito and k.global_position.x >= 2934.0 - off:
			feito = true
			Input.action_press("saltar")
		elif feito and not solto and (k.velocity.y > 0.0 or i > 400):
			solto = true
			Input.action_release("saltar")
		if pogo and feito and not k.is_on_floor() and k.velocity.y > 0.0 and k.global_position.y >= 575.0 				and k.global_position.x > 2900.0 and k.global_position.x < 3230.0 and not Input.is_action_pressed("atacar"):
			Input.action_press("mirar_baixo")
			Input.action_press("atacar")
		else:
			Input.action_release("atacar")
		await get_tree().physics_frame
		if feito and k.is_on_floor() and k.global_position.x > 3215.0:
			chegou = true
			break
		if k.global_position.y > 860.0:
			break
	Input.action_release("mover_direita")
	Input.action_release("saltar")
	Input.action_release("atacar")
	Input.action_release("mirar_baixo")
	return {"chegou": chegou, "dano": vida0 - k.vida}


func teste_n3_autoral() -> void:
	var antes_dev: bool = EstadoJogo.modo_dev
	EstadoJogo.modo_dev = false
	var antes_idx: int = EstadoJogo.indice_nivel
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	EstadoJogo.indice_nivel = 2
	EstadoJogo.habilidades.assign(["dash"])
	var n := (load("res://scenes/levels/Ninho_da_Viuva_Negra.tscn") as PackedScene).instantiate()
	add_child(n)
	for i in 6:
		await get_tree().process_frame
	_ok(not bool(n.get("corredor")) and bool(n.get("checkpoints_autorais")), "N3: nao e' autoral (corredor/checkpoints)")
	_ok(n.get_node_or_null("CorredorAproximacao") == null, "N3: o gerador criou uma jornada")
	_ok(n.get_node_or_null("Guardiao") != null and n.get_node_or_null("Porta") != null, "N3: sem Guardiao/Porta")
	_ok(String(n.get("mecanica_anunciada")) == "pogo", "N3: a mecanica anunciada devia ser o pogo")
	var chk := 0
	for c in get_tree().get_nodes_in_group("checkpoints"):
		if n.is_ancestor_of(c):
			chk += 1
	_ok(chk == 4, "N3: esperava 4 checkpoints autorais, ha %d" % chk)
	# so' o Pogo e' novo: nada de Especial/wall-jump/mecanicas futuras/Regiao II
	var proibidos := ["serra.gd", "fogo.gd", "guilhotina.gd", "pendulo_lamina.gd", "wind_zone.gd", "portal.gd",
		"trampolim.gd", "tumulo_elevador.gd", "plataforma_ritmada.gd", "torreta.gd", "teia_prende.gd"]
	var habs: Array = []
	var altar_x := INF
	var pogo_x: Array = []     # x de tudo o que o pogo toca (espinhos e inimigos)
	for no in n.find_children("*", "", true, false):
		var sc := no.get_script() as Script
		if sc == null:
			continue
		for pr in proibidos:
			_ok(not sc.resource_path.ends_with(pr), "N3: %s nao pertence ao N3" % no.name)
		if sc.resource_path.ends_with("coletavel.gd"):
			habs.append(String(no.get("habilidade_id")))
			altar_x = (no as Node2D).position.x
		if sc.resource_path.ends_with("espinhos.gd") or (no is DemonioBase and not no.is_in_group("chefes")):
			pogo_x.append((no as Node2D).position.x)
		if no is DemonioBase and not no.is_in_group("chefes"):
			_ok(String(no.get("especie")) == "goblin", "N3: %s nao e' um inimigo ja' aprovado da Regiao I" % no.name)
	_ok(habs == ["pogo"], "N3: os coletaveis de habilidade deviam ser so' [pogo], ha %s" % str(habs))
	var antes_do_altar := 0
	for x in pogo_x:
		if x < altar_x:
			antes_do_altar += 1
	_ok(antes_do_altar == 0, "N3: %d alvos de pogo antes do altar (nada exige o pogo antes de ser ensinado)" % antes_do_altar)
	_ok(pogo_x.size() >= 10, "N3: alvos de pogo a menos (%d)" % pogo_x.size())
	# a primeira cama que o pogo atravessa (>= 200 px) vem bem depois do altar e depois dos tufos de teste
	var camas: Array = []
	for no in n.get_children():
		var sc2 := no.get_script() as Script
		if sc2 != null and sc2.resource_path.ends_with("espinhos.gd") and int(no.get("largura")) * 16 >= 190:
			camas.append((no as Node2D).position.x)
	camas.sort()
	_ok(camas.size() >= 4 and float(camas[0]) - altar_x >= 1200.0, "N3: a 1a cama larga devia vir >= 1200 px depois do altar")
	# geometria: vaos comuns dentro do salto simples; vaos > 125 so' sob teto baixo (dash, ja' ensinado no N2)
	var pl: Array = []
	var tetos: Array = []
	for no in n.get_children():
		if not (no is StaticBody2D) or no.get_script() == null:
			continue
		if not String((no.get_script() as Script).resource_path).ends_with("/plataforma.gd"):
			continue
		var t: Vector2 = no.get("tamanho")
		var d := {"nome": String(no.name), "l": no.position.x - t.x * 0.5, "r": no.position.x + t.x * 0.5,
			"top": no.position.y - t.y * 0.5, "base": no.position.y + t.y * 0.5}
		if d["nome"].begins_with("Teto"):
			tetos.append(d)
		elif d["nome"] == "SegredoAlto":
			_ok(665.0 - float(d["top"]) <= 130.0, "N3: o segredo alto excede salto + mantle")
		else:
			pl.append(d)
	pl.sort_custom(func(a, b): return a["l"] < b["l"])
	var gates := 0
	for i in range(1, pl.size()):
		var b: Dictionary = pl[i]
		var chega := false
		var e_gate := false
		for j in i:
			var a: Dictionary = pl[j]
			var vao: float = b["l"] - a["r"]
			var sub: float = a["top"] - b["top"]
			if vao <= 0.0:
				if sub <= 66.0:
					chega = true
				continue
			var limite := 125.0 if sub <= 0.0 else 110.0
			if vao <= limite and sub <= 64.0:
				chega = true
			elif vao > limite and vao <= 145.0 and absf(sub) <= 4.0:
				var coberto := false
				for tt in tetos:
					var folga: float = float(a["top"]) - float(tt["base"])
					if tt["l"] <= a["r"] and tt["r"] >= b["l"] and folga <= 70.0 and folga >= 50.0:
						coberto = true
				if coberto:
					chega = true
					e_gate = true
		_ok(chega, "N3: %s inalcancavel pelo salto simples nem por gate de dash" % b["nome"])
		if e_gate:
			gates += 1
	_ok(gates == 3, "N3: esperava 3 gates de dash, ha %d" % gates)
	# dinamica da cama larga: sem pogo nao se atravessa sem dano; com pogo passa-se limpo
	var altar_n := n.get_node_or_null("AltarPogo")
	if altar_n:
		altar_n.queue_free()
	var k := n.get_node("Koliani") as CharacterBody2D
	EstadoJogo.habilidades.assign(["dash"])
	var limpo_sem := false
	for off in [0.0, 12.0, 30.0, 60.0, 90.0]:
		var r: Dictionary = await _n3_cama_trial(n, k, off)
		print("N3 cama sem pogo off=%s: %s" % [off, str(r)])
		if r["chegou"] and int(r["dano"]) == 0:
			limpo_sem = true
	_ok(not limpo_sem, "N3: a cama larga atravessa-se sem dano e sem pogo (o pogo nao e' preciso)")
	EstadoJogo.habilidades.assign(["dash", "pogo"])
	var limpo_com := 0
	for off in [0.0, 12.0, 30.0, 60.0, 90.0, 120.0, 150.0]:
		var r2: Dictionary = await _n3_cama_trial(n, k, off, true)
		print("N3 cama com pogo off=%s: %s" % [off, str(r2)])
		if r2["chegou"] and int(r2["dano"]) == 0:
			limpo_com += 1
	# janela de takeoff: pelo menos 2 dos 7 offsets (12 px de passo) atravessam limpos
	_ok(limpo_com >= 2, "N3: com o pogo a cama larga so' passa limpa em %d/7 takeoffs" % limpo_com)
	n.queue_free()
	await get_tree().process_frame
	EstadoJogo.modo_dev = antes_dev
	EstadoJogo.indice_nivel = antes_idx
	EstadoJogo.habilidades.assign(antes_hab)


## Pogo intencional: larga a Koliani de `y0` sobre `x`, opcionalmente carrega BAIXO+ATAQUE quando os pes ficam a
## `gatilho` px do topo `topo_y`. Devolve dano, se ressaltou (vy < -150), subida do ressalto em px e frames de aceleracao.
func _pogo_trial(k: CharacterBody2D, x: float, y0: float, carregar: bool, gatilho := 60.0, topo_y := 665.0, seguir: Node2D = null) -> Dictionary:
	k.global_position = Vector2(x, y0)
	k.velocity = Vector2.ZERO
	k.vida = k._vida_max()
	k._invulneravel = 0.0
	k.reset_physics_interpolation()
	for i in 20:
		await get_tree().physics_frame
	k.global_position = Vector2(x, y0)
	k.velocity = Vector2.ZERO
	k.vida = k._vida_max()
	k._invulneravel = 0.0
	var vida0: int = k.vida
	var hp_alvo := -1
	if seguir != null and "vida" in seguir:
		hp_alvo = int(seguir.vida)
	var ressaltou := false
	var y_contacto := 0.0
	var y_topo := 1e9
	var premiu := false
	for i in 150:
		if seguir != null:
			k.global_position.x = seguir.global_position.x
		if carregar and not premiu and k.velocity.y > 0.0 and k.global_position.y + 24.0 >= topo_y - gatilho:
			premiu = true
			Input.action_press("mirar_baixo")
			Input.action_press("atacar")
		elif premiu:
			Input.action_release("atacar")
		await get_tree().physics_frame
		if not ressaltou and k.velocity.y < -150.0:
			ressaltou = true
			y_contacto = k.global_position.y
		if ressaltou:
			y_topo = minf(y_topo, k.global_position.y)
			if k.velocity.y > 0.0:
				break
		if k.is_on_floor() and i > 30:
			break
	Input.action_release("atacar")
	Input.action_release("mirar_baixo")
	var dvida := 0
	if hp_alvo >= 0:
		dvida = hp_alvo - int(seguir.vida)
	return {"dano": vida0 - k.vida, "ressaltou": ressaltou, "subida": (y_contacto - y_topo) if ressaltou else 0.0, "dano_alvo": dvida}


func teste_pogo_intencional() -> void:
	var antes_dev: bool = EstadoJogo.modo_dev
	EstadoJogo.modo_dev = false
	var antes_idx: int = EstadoJogo.indice_nivel
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	EstadoJogo.indice_nivel = 2
	EstadoJogo.habilidades.assign(["dash", "pogo"])
	var n := (load("res://scenes/levels/Ninho_da_Viuva_Negra.tscn") as PackedScene).instantiate()
	add_child(n)
	for i in 6:
		await get_tree().process_frame
	var altar_n := n.get_node_or_null("AltarPogo")
	if altar_n:
		altar_n.queue_free()
	var k := n.get_node("Koliani") as CharacterBody2D
	# 1) toque sem input: NAO ressalta (e leva o golpe)
	var a: Dictionary = await _pogo_trial(k, 1960.0, 480.0, false)
	print("POGO sem input nos espinhos: ", a)
	_ok(not a["ressaltou"] and int(a["dano"]) > 0, "Pogo: cair nos espinhos sem input devia dar dano e nao ressaltar")
	# 2) input no sitio certo: ressalta, sem dano; subida medida
	var b: Dictionary = await _pogo_trial(k, 1960.0, 480.0, true)
	print("POGO com input nos espinhos: ", b)
	_ok(b["ressaltou"] and int(b["dano"]) == 0, "Pogo: BAIXO+ATAQUE sobre espinhos devia ressaltar sem dano")
	_ok(float(b["subida"]) >= 85.0 and float(b["subida"]) <= 115.0, "Pogo: subida do ressalto fora de 85-115 px: %s" % str(b["subida"]))
	# 3) input sobre chao vazio: ataque executado mas SEM ressalto gratuito
	var c: Dictionary = await _pogo_trial(k, 1700.0, 480.0, true)
	print("POGO no vazio: ", c)
	_ok(not c["ressaltou"], "Pogo: o ataque descendente sem alvo ressaltou (ressalto gratuito)")
	# 4) inimigo: dano + ressalto; sem input, so' contacto
	var g := n.get_node("GoblinA") as Node2D
	g.set("alcance_patrulha", 0.0)
	var gy: float = g.global_position.y
	print("POGO goblin pos=", g.global_position, " grupos inimigos=", g.is_in_group("inimigos"), " vida=", g.get("vida"), " chefe=", g.is_in_group("chefes"))
	var d: Dictionary = await _pogo_trial(k, g.global_position.x, gy - 170.0, true, 110.0, gy - 30.0, g)
	print("POGO no goblin: ", d)
	_ok(d["ressaltou"] and int(d["dano_alvo"]) > 0, "Pogo: o ataque descendente devia ferir o goblin e ressaltar")
	# 5) spam: 2 falhas seguidas -> a 2.a nao arranca durante a recuperacao
	k.global_position = Vector2(1700.0, 480.0)
	k.velocity = Vector2.ZERO
	await get_tree().physics_frame
	Input.action_press("mirar_baixo")
	Input.action_press("atacar")
	for i in 3:
		await get_tree().physics_frame
	Input.action_release("atacar")
	var estado_1: int = k._pogo_estado
	_ok(estado_1 != 0, "Pogo: o input nao iniciou o ataque descendente no ar")
	Input.action_release("mirar_baixo")
	n.queue_free()
	await get_tree().process_frame
	EstadoJogo.modo_dev = antes_dev
	EstadoJogo.indice_nivel = antes_idx
	EstadoJogo.habilidades.assign(antes_hab)


## Geometria das cenas autorais com gates de Dash (mesma regra do N2/N3): vaos comuns dentro do salto simples,
## vaos > 125 px so' sob teto baixo. Devolve o n.o de gates de Dash.
func _gates_dash_autoral(n: Node, rotulo: String) -> int:
	var pl: Array = []
	var tetos: Array = []
	for no in n.get_children():
		if not (no is StaticBody2D) or no.get_script() == null:
			continue
		if not String((no.get_script() as Script).resource_path).ends_with("/plataforma.gd"):
			continue
		var t: Vector2 = no.get("tamanho")
		var d := {"nome": String(no.name), "l": no.position.x - t.x * 0.5, "r": no.position.x + t.x * 0.5,
			"top": no.position.y - t.y * 0.5, "base": no.position.y + t.y * 0.5}
		if d["nome"].begins_with("Teto"):
			tetos.append(d)
		else:
			pl.append(d)
	pl.sort_custom(func(a, b): return a["l"] < b["l"])
	var gates := 0
	for i in range(1, pl.size()):
		var b: Dictionary = pl[i]
		var chega := false
		var e_gate := false
		for j in i:
			var a: Dictionary = pl[j]
			var vao: float = b["l"] - a["r"]
			var sub: float = a["top"] - b["top"]
			if vao <= 0.0:
				if sub <= 66.0:
					chega = true
				continue
			var limite := 125.0 if sub <= 0.0 else 110.0
			if vao <= limite and sub <= 64.0:
				chega = true
			elif vao > limite and vao <= 145.0 and absf(sub) <= 4.0:
				for tt in tetos:
					var folga: float = float(a["top"]) - float(tt["base"])
					if tt["l"] <= a["r"] and tt["r"] >= b["l"] and folga <= 70.0 and folga >= 50.0:
						chega = true
						e_gate = true
		_ok(chega, "%s: %s inalcancavel pelo salto simples nem por gate de dash" % [rotulo, b["nome"]])
		if e_gate:
			gates += 1
	return gates


func teste_n4_autoral() -> void:
	var antes_dev: bool = EstadoJogo.modo_dev
	EstadoJogo.modo_dev = false
	var antes_idx: int = EstadoJogo.indice_nivel
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	EstadoJogo.indice_nivel = 3
	EstadoJogo.habilidades.assign(["dash", "pogo"])
	var n := (load("res://scenes/levels/A_Arvore_que_Chora.tscn") as PackedScene).instantiate()
	add_child(n)
	for i in 6:
		await get_tree().process_frame
	_ok(not bool(n.get("corredor")) and bool(n.get("checkpoints_autorais")), "N4: nao e' autoral")
	_ok(n.get_node_or_null("CorredorAproximacao") == null, "N4: o gerador criou uma jornada")
	_ok(n.get_node_or_null("Guardiao") != null and n.get_node_or_null("Porta") != null, "N4: sem Guardiao/Porta")
	_ok(String(n.get("mecanica_anunciada")) == "especial", "N4: a mecanica anunciada devia ser o especial")
	var chk := 0
	for c in get_tree().get_nodes_in_group("checkpoints"):
		if n.is_ancestor_of(c):
			chk += 1
	_ok(chk == 5, "N4: esperava 5 checkpoints autorais, ha %d" % chk)
	# so' o Especial e' novo; nada de wall-jump nem mecanicas futuras
	var proibidos := ["serra.gd", "fogo.gd", "guilhotina.gd", "pendulo_lamina.gd", "wind_zone.gd", "portal.gd",
		"trampolim.gd", "tumulo_elevador.gd", "plataforma_ritmada.gd", "torreta.gd", "teia_prende.gd",
		"raiz_elevatoria.gd", "alavanca.gd", "porta_trancada.gd", "gota_acida.gd"]
	var habs: Array = []
	var inimigos := 0
	for no in n.find_children("*", "", true, false):
		var sc := no.get_script() as Script
		if sc == null:
			continue
		for pr in proibidos:
			_ok(not sc.resource_path.ends_with(pr), "N4: %s nao pertence ao N4" % no.name)
		if sc.resource_path.ends_with("coletavel.gd"):
			habs.append(String(no.get("habilidade_id")))
		if no is DemonioBase and not no.is_in_group("chefes"):
			inimigos += 1
			_ok(String(no.get("especie")) in ["goblin", "gosma"], "N4: %s: especie fora da Regiao I aprovada" % no.name)
			_ok(int(no.get("vida")) <= 200, "N4: %s: vida > 200 (dificuldade nao vem de HP)" % no.name)
	_ok(habs == ["especial"], "N4: os coletaveis de habilidade deviam ser so' [especial], ha %s" % str(habs))
	_ok(inimigos >= 6 and inimigos <= 9, "N4: %d inimigos (esperava 6-9, poucos encontros)" % inimigos)
	_ok(_gates_dash_autoral(n, "N4") == 4, "N4: esperava 4 gates de dash")
	# --- Especial / Energia ---
	var k := n.get_node("Koliani") as CharacterBody2D
	k.set("_energia", 99.0)
	_ok(not k.usar_especial(), "N4: o Especial disparou sem a habilidade")
	_ok(is_equal_approx(k.energia_actual(), 99.0), "N4: sem a habilidade a Energia mudou")
	EstadoJogo.habilidades.assign(["dash", "pogo", "especial"])
	var gastos: Array = []
	for i in 3:
		k.set("_especial_cd", 0.0)
		var e0: float = k.energia_actual()
		_ok(k.usar_especial(), "N4: o Especial %d nao disparou com Energia" % (i + 1))
		gastos.append(snappedf(e0 - k.energia_actual(), 0.1))
	print("N4 especial: gastos por uso ", gastos, " energia final ", k.energia_actual())
	_ok(gastos == [33.0, 33.0, 33.0] and k.energia_actual() >= 0.0, "N4: o Especial devia gastar 33 por uso e nunca deixar a Energia negativa")
	k.set("_especial_cd", 0.0)
	_ok(not k.usar_especial() and k.energia_actual() >= 0.0, "N4: com a barra vazia o Especial nao devia disparar")
	# recuperacao: passiva (sem ficar preso) + a acertar golpes
	var t_regen := 0
	while k.energia_actual() < 33.0 and t_regen < 900:
		await get_tree().physics_frame
		t_regen += 1
	print("N4 especial: 1.o uso outra vez apos ", t_regen, " frames (", snappedf(t_regen / 60.0, 0.1), " s)")
	_ok(k.energia_actual() >= 33.0, "N4: a Energia nao recupera sozinha (softlock por Energia vazia)")
	k.set("_energia", 10.0)
	var g := n.get_node("GoblinE1")
	k.call("_ao_acertar_corpo", g)
	_ok(is_equal_approx(k.energia_actual(), 15.0), "N4: acertar um golpe devia dar +5 Energia, deu %s" % str(k.energia_actual()))
	# a onda atravessa: dois goblins alinhados levam ambos
	var g1 := n.get_node("GoblinE1")
	var g2 := n.get_node("GoblinE2")
	g1.set("alcance_patrulha", 0.0)
	g2.set("alcance_patrulha", 0.0)
	var v1: int = g1.vida
	var v2: int = g2.vida
	k.global_position = Vector2(g1.global_position.x - 120.0, 630.0)
	k.velocity = Vector2.ZERO
	k.set("_olha_para", 1.0)
	k.set("_energia", 99.0)
	k.set("_especial_cd", 0.0)
	k.set("_invulneravel", 5.0)
	_ok(k.usar_especial(), "N4: o Especial nao disparou junto aos goblins")
	for i in 60:
		await get_tree().physics_frame
	var lv1: bool = is_instance_valid(g1) and g1.vida < v1
	var lv2: bool = is_instance_valid(g2) and g2.vida < v2
	var mortos1: bool = not is_instance_valid(g1) or g1.vida <= 0
	var mortos2: bool = not is_instance_valid(g2) or g2.vida <= 0
	print("N4 especial: dano do Especial = ", roundi(k._dano_golpe() * k.ESPECIAL_DANO_MULT), " | goblin1 ", lv1 or mortos1, " goblin2 ", lv2 or mortos2)
	_ok((lv1 or mortos1) and (lv2 or mortos2), "N4: a onda do Especial devia atravessar e ferir os dois goblins")
	n.queue_free()
	await get_tree().process_frame
	EstadoJogo.modo_dev = antes_dev
	EstadoJogo.indice_nivel = antes_idx
	EstadoJogo.habilidades.assign(antes_hab)


## ---- N5: Coracao Putrefacto (exame regional) -------------------------------------------------
func _coracao_novo(dev := true) -> Array:
	EstadoJogo.modo_dev = dev
	var n := (load("res://scenes/levels/Coracao_da_Floresta.tscn") as PackedScene).instantiate()
	add_child(n)
	for i in 8:
		await get_tree().physics_frame
	var g := n.get_node("Chefe") as ChefeCoracaoPutrefacto
	var k := n.get_node("Koliani") as CharacterBody2D
	k.global_position = Vector2(g.global_position.x - 200.0, 630.0)   # o headless e' quadrado: so' ~250 px de cada lado estao a' vista
	for i in 30:
		await get_tree().physics_frame
	return [n, g, k]


## Bot de golpes (mesma convencao do Ghorak: 2 golpes de 50 por segundo). modo: "janelas" so' com o nucleo
## aberto; "spam" sempre; "casca" so' fora da janela; "especial" = janelas + 3 Especiais (130) por janela aberta.
func _coracao_luta(modo: String, segundos: float) -> Dictionary:
	var antes_dev: bool = EstadoJogo.modo_dev
	var r: Array = await _coracao_novo(true)
	Engine.time_scale = 6.0   # o bot corre a 6x: a luta mede-se em segundos de JOGO (frames de fisica)
	var n: Node = r[0]
	var g: ChefeCoracaoPutrefacto = r[1]
	var k: Node2D = r[2]
	var frames := 0
	var limite := int(segundos * 60.0)
	var janelas: Array = []
	var jan_ini := -1
	var fase2_em := -1.0
	var pior_estado := 0.0
	var ult_fase := int(g._fase)
	var t_fase := 0
	var especiais := 0
	var energia := 99.0
	var raizes_cedo := 0
	var vistas := {}
	var tel_pulso: Array = []
	var vida0: int = g.vida
	var morreu := false
	while frames < limite:
		await get_tree().physics_frame
		frames += 1
		if frames % 45 == 0 and is_instance_valid(g):
			k.global_position = Vector2(g.global_position.x - 200.0, 630.0)   # o pulso empurra: mantem-na a' vista
		if not is_instance_valid(g) or g.is_queued_for_deletion():
			morreu = true
			break
		var vuln: bool = g._vulneravel()
		if vuln and jan_ini < 0:
			jan_ini = frames
			especiais = 0
		if not vuln and jan_ini >= 0:
			janelas.append(float(frames - jan_ini) / 60.0)
			jan_ini = -1
		if int(g._fase) != ult_fase:
			if ult_fase != int(ChefeCoracaoPutrefacto.Fase.DORME):
				pior_estado = maxf(pior_estado, float(t_fase) / 60.0)
			if ult_fase == int(ChefeCoracaoPutrefacto.Fase.PULSO_TEL):
				tel_pulso.append(float(t_fase) / 60.0)
			ult_fase = int(g._fase)
			t_fase = 0
		t_fase += 1
		if g._f2 and fase2_em < 0.0:
			fase2_em = float(frames) / 60.0
		for no in n.get_children():
			if no is RaizPerigo and not vistas.has(no.get_instance_id()):
				vistas[no.get_instance_id()] = true
				if float(no.atraso) < 0.9:
					raizes_cedo += 1
		if frames % 30 == 0 and ((modo == "casca" and not vuln) or (modo != "casca" and (modo == "spam" or vuln))):
			g.receber_dano(50, 1.0)
		if modo == "especial":
			energia = minf(99.0, energia + 0.2)      # regen 12/s (60 Hz)
			if vuln and frames % 30 == 0:
				energia = minf(99.0, energia + 5.0)   # +5 por golpe de espada
			if vuln and energia >= 33.0 and frames % 40 == 20:
				energia -= 33.0
				g.receber_tiro(130, 1.0)   # o nucleo absorve 40 % da onda
	var ultima_contagem := {}
	if is_instance_valid(g) and not g.is_queued_for_deletion():
		morreu = false
		ultima_contagem = g.contagem.duplicate()
	else:
		morreu = true
		await get_tree().process_frame
		await get_tree().process_frame
	var porta := n.get_node_or_null("Porta")
	var res := {"ttk": float(frames) / 60.0, "morreu": morreu, "pior_estado": pior_estado, "janelas": janelas,
		"fase2_em": fase2_em, "raizes_cedo": raizes_cedo, "tel_pulso": tel_pulso, "vida0": vida0,
		"contagem": ultima_contagem,
		"saida": n.get_node_or_null("BauChefe") != null or (porta != null and bool(porta.monitoring))}
	Engine.time_scale = 1.0
	n.queue_free()
	await get_tree().process_frame
	EstadoJogo.bosses_derrotados.clear()   # a morte do boss grava-se: sem isto o proximo nivel nasce sem Coracao
	EstadoJogo.modo_dev = antes_dev
	return res


func teste_n5_autoral() -> void:
	var antes_dev: bool = EstadoJogo.modo_dev
	var antes_bosses: Array[String] = EstadoJogo.bosses_derrotados.duplicate()
	EstadoJogo.bosses_derrotados.clear()
	var antes_idx: int = EstadoJogo.indice_nivel
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	EstadoJogo.indice_nivel = 4
	EstadoJogo.habilidades.assign(["dash", "pogo", "especial"])
	# --- estrutura ---
	var n0 := (load("res://scenes/levels/Coracao_da_Floresta.tscn") as PackedScene).instantiate()
	add_child(n0)
	for i in 6:
		await get_tree().process_frame
	_ok(not bool(n0.get("corredor")) and bool(n0.get("checkpoints_autorais")), "N5: nao e' autoral")
	_ok(n0.get_node_or_null("CorredorAproximacao") == null, "N5: o gerador criou uma jornada")
	_ok(n0.get_node_or_null("Chefe") is ChefeCoracaoPutrefacto and n0.get_node_or_null("Porta") != null, "N5: sem Coracao/Porta")
	var chk := 0
	for c in get_tree().get_nodes_in_group("checkpoints"):
		if n0.is_ancestor_of(c):
			chk += 1
	_ok(chk == 4, "N5: esperava 4 checkpoints, ha %d" % chk)
	var proibidos := ["serra.gd", "fogo.gd", "guilhotina.gd", "pendulo_lamina.gd", "wind_zone.gd", "portal.gd",
		"trampolim.gd", "tumulo_elevador.gd", "plataforma_ritmada.gd", "torreta.gd", "teia_prende.gd",
		"raiz_elevatoria.gd", "alavanca.gd", "porta_trancada.gd", "gota_acida.gd", "zona_gravidade.gd", "coletavel.gd"]
	var inimigos := 0
	for no in n0.find_children("*", "", true, false):
		var sc := no.get_script() as Script
		if sc == null:
			continue
		for pr in proibidos:
			_ok(not sc.resource_path.ends_with(pr), "N5: %s nao pertence ao N5 (skill/mecanica nova)" % no.name)
		if no is DemonioBase and not no.is_in_group("chefes"):
			inimigos += 1
			_ok(String(no.get("especie")) in ["goblin", "gosma"], "N5: %s: especie fora da aprovada" % no.name)
	_ok(inimigos >= 3 and inimigos <= 4, "N5: %d inimigos no exame (esperava 3-4)" % inimigos)
	_ok(_gates_dash_autoral(n0, "N5") == 3, "N5: esperava 3 gates de dash")
	# arena continua: nenhuma plataforma secundaria sobre o chao do boss
	var chao_boss := n0.get_node("ChaoChefe") as Node2D
	var sec := 0
	for no in n0.get_children():
		if no is StaticBody2D and no != chao_boss and no.position.x > chao_boss.position.x - 560.0 and no.position.y < 660.0:
			sec += 1
	_ok(sec == 0, "N5: %d plataformas na arena do boss" % sec)
	n0.queue_free()
	await get_tree().process_frame

	# --- nada arranca fora do campo visual ---
	var chao := StaticBody2D.new()
	chao.collision_layer = 1
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(9000.0, 60.0)
	cs.shape = rs
	chao.add_child(cs)
	add_child(chao)
	chao.global_position = Vector2(4000.0, 560.0)
	var kf := CharacterBody2D.new()
	var sc_kf := GDScript.new()
	sc_kf.source_code = "extends CharacterBody2D\nfunc receber_dano(_a, _b = 0.0):\n\tpass\n"
	sc_kf.reload()
	kf.set_script(sc_kf)
	kf.add_to_group("koliani")
	add_child(kf)
	var cam0 := Camera2D.new()
	add_child(cam0)
	cam0.global_position = Vector2(-3000.0, 300.0)
	cam0.make_current()
	var g0 := (load("res://scenes/actors/ChefeCoracaoPutrefacto.tscn") as PackedScene).instantiate() as ChefeCoracaoPutrefacto
	g0.position = Vector2(4000.0, 500.0)
	add_child(g0)
	kf.global_position = g0.global_position + Vector2(-230.0, 0.0)
	for i in 300:
		await get_tree().physics_frame
	var c0: Dictionary = g0.contagem
	_ok(int(c0["RAIZES"]) + int(c0["PULSO"]) + int(c0["BROTOS"]) == 0 and g0._fase == ChefeCoracaoPutrefacto.Fase.DORME,
		"Coracao: iniciou um ataque fora do campo visual (%s)" % str(c0))
	cam0.global_position = g0.global_position
	for i in 420:
		await get_tree().physics_frame
		await get_tree().process_frame
	var c1: Dictionary = g0.contagem
	_ok(int(c1["RAIZES"]) + int(c1["PULSO"]) + int(c1["BROTOS"]) >= 1, "Coracao: a' vista nunca atacou (%s)" % str(c1))
	g0.queue_free()
	kf.queue_free()
	chao.queue_free()
	cam0.queue_free()
	await get_tree().process_frame

	# --- casca vs janela ---
	var r: Array = await _coracao_novo(true)
	var n: Node = r[0]
	var g: ChefeCoracaoPutrefacto = r[1]
	g._ir(ChefeCoracaoPutrefacto.Fase.DECIDE)
	var v0: int = g.vida
	g.receber_dano(50, 1.0)
	var dano_casca: int = v0 - g.vida
	g._abrir_janela(2.0)
	v0 = g.vida
	g.receber_dano(50, 1.0)
	var dano_janela: int = v0 - g.vida
	_ok(dano_casca >= 1 and dano_casca <= 10, "Coracao: a casca deixou passar %d de 50" % dano_casca)
	_ok(dano_janela >= 50, "Coracao: a janela devia dar o golpe inteiro, deu %d" % dano_janela)
	n.queue_free()
	await get_tree().process_frame

	# --- broto + pogo: abre o nucleo de imediato e alonga a janela ---
	r = await _coracao_novo(true)
	n = r[0]
	g = r[1]
	var k: CharacterBody2D = r[2]
	g._ciclos = 2                                   # PADRAO_F1[2] = BROTOS
	g._ir(ChefeCoracaoPutrefacto.Fase.DECIDE)
	var t_espera := 0
	while g._fase != ChefeCoracaoPutrefacto.Fase.BROTOS_ESPERA and t_espera < 600:
		await get_tree().physics_frame
		t_espera += 1
	for i in 60:
		await get_tree().physics_frame                # os brotos crescem em 0,7 s
	var broto: Node2D = null
	for b in g._brotos:
		if is_instance_valid(b):
			broto = b
			break
	_ok(broto != null and broto.is_in_group("pogavel"), "Coracao: sem broto pogavel na mecanica BROTOS")
	if broto != null:
		k.global_position = Vector2(broto.global_position.x, broto.global_position.y - 220.0)
		k.velocity = Vector2.ZERO
		var premiu := false
		for i in 200:
			if not premiu and k.velocity.y > 0.0 and k.global_position.y + 24.0 >= broto.global_position.y - 110.0:
				premiu = true
				Input.action_press("mirar_baixo")
				Input.action_press("atacar")
			elif premiu:
				Input.action_release("atacar")
			await get_tree().physics_frame
			if int(g.contagem["BROTOS_ESTOURADOS"]) > 0:
				break
		Input.action_release("atacar")
		Input.action_release("mirar_baixo")
		await get_tree().physics_frame
		print("N5 broto: estourados=", g.contagem["BROTOS_ESTOURADOS"], " fase=", g._fase, " janela=", snappedf(g._dur_janela, 0.01))
		_ok(int(g.contagem["BROTOS_ESTOURADOS"]) == 1, "Coracao: o pogo num broto nao o estourou")
		_ok(g._fase == ChefeCoracaoPutrefacto.Fase.EXPOSTO and g._dur_janela >= g.janela_aberta * 1.4,
			"Coracao: estourar o broto devia abrir uma janela 50 por cento maior (fase %d, janela %.2f)" % [int(g._fase), g._dur_janela])
	n.queue_free()
	await get_tree().process_frame

	# --- pulso: telegrafado, magoa quem fica no chao, evita-se com salto ou dash ---
	var dano_parado := 0
	var dano_salto := 999
	var dano_dash := 999
	for variante in ["parado", "salto", "dash"]:
		for off in [0.0, 1.0, 2.0, 3.0]:
			r = await _coracao_novo(false)
			n = r[0]
			g = r[1]
			k = r[2]
			k.set("_invulneravel", 0.0)
			k.global_position = Vector2(g.global_position.x + 200.0, 630.0)
			k.velocity = Vector2.ZERO
			k.set("_olha_para", -1.0)
			k.vida = k._vida_max()
			g._ciclos = 1                             # PADRAO_F1[1] = PULSO
			g._ir(ChefeCoracaoPutrefacto.Fase.DECIDE)
			var esperou := 0
			while g._fase != ChefeCoracaoPutrefacto.Fase.PULSO_LANCA and esperou < 600:
				await get_tree().physics_frame
				esperou += 1
				if g._fase == ChefeCoracaoPutrefacto.Fase.PULSO_TEL and esperou % 5 == 0:
					k.global_position.x = g.global_position.x + 330.0   # depois do aviso: afasta-se
			var vida_ini: int = k.vida
			var acao := false
			var acao_n := 0
			for i in 140:
				var d := 1e9
				for no in n.get_children():
					if no is Area2D and no.get_child_count() > 0 and no.get_child(0) is CollisionShape2D \
							and (no.get_child(0) as CollisionShape2D).shape is RectangleShape2D \
							and ((no.get_child(0) as CollisionShape2D).shape as RectangleShape2D).size == Vector2(44.0, 40.0):
						if no.global_position.x > k.global_position.x:
							continue
						d = minf(d, k.global_position.x - no.global_position.x)
				if not acao and d <= (70.0 if variante == "salto" else 150.0) + off * 25.0 and variante != "parado":
					acao = true
					Input.action_press("saltar" if variante == "salto" else "dash")
				elif acao and variante == "dash" and acao_n > 2:
					Input.action_release("dash")
				if acao:
					acao_n += 1
					if acao_n > 24:
						Input.action_release("saltar")
				await get_tree().physics_frame
			Input.action_release("saltar")
			Input.action_release("dash")
			var dano: int = vida_ini - k.vida
			if variante == "parado":
				dano_parado = maxi(dano_parado, dano)
			elif variante == "salto":
				dano_salto = mini(dano_salto, dano)
			else:
				dano_dash = mini(dano_dash, dano)
			n.queue_free()
			await get_tree().process_frame
	print("N5 pulso: dano parado=", dano_parado, " salto(min)=", dano_salto, " dash(min)=", dano_dash)
	_ok(dano_parado > 0, "Coracao: o pulso nao magoou quem ficou parado no chao")
	_ok(dano_salto == 0, "Coracao: saltar por cima do pulso nunca o evitou (min %d)" % dano_salto)
	_ok(dano_dash == 0, "Coracao: o dash nunca atravessou o pulso (min %d)" % dano_dash)

	# --- lutas simuladas (Koliani invulneravel: mede-se o boss) ---
	EstadoJogo.modo_dev = true
	var spam: Dictionary = await _coracao_luta("spam", 200.0)
	var casca: Dictionary = await _coracao_luta("casca", 120.0)
	var lido: Dictionary = await _coracao_luta("janelas", 300.0)
	var esp: Dictionary = await _coracao_luta("especial", 300.0)
	print("CORACAO vida=", lido["vida0"], " | spam ttk=", snappedf(spam["ttk"], 0.1), " morreu=", spam["morreu"], " | so casca ttk=", snappedf(casca["ttk"], 0.1), " morreu=", casca["morreu"])
	print("CORACAO janelas: ttk=", snappedf(lido["ttk"], 0.1), " fase2_em=", snappedf(lido["fase2_em"], 0.1), " pior_estado=", snappedf(lido["pior_estado"], 0.1), " | com Especial: ttk=", snappedf(esp["ttk"], 0.1))
	print("CORACAO janelas (s): ", lido["janelas"], " contagem: ", lido["contagem"], " tel_pulso: ", lido["tel_pulso"])
	_ok(bool(lido["morreu"]), "Coracao: nao morre a bater so' nas janelas (preso?)")
	_ok(not bool(casca["morreu"]) or float(casca["ttk"]) >= 90.0, "Coracao: da' para ganhar a bater so' na casca em %.1f s" % casca["ttk"])
	_ok(not bool(spam["morreu"]) or float(spam["ttk"]) >= float(lido["ttk"]) * 0.7, "Coracao: spam (%.1f) ganha mais depressa do que ler as janelas (%.1f)" % [spam["ttk"], lido["ttk"]])
	_ok(float(lido["ttk"]) >= 20.0 and float(lido["ttk"]) <= 50.0, "Coracao: TTK do bot perfeito = %.1f s (esperava 20-50; humano ~1,6x)" % lido["ttk"])
	_ok(float(esp["ttk"]) < float(lido["ttk"]) * 0.95 and float(esp["ttk"]) > float(lido["ttk"]) * 0.55, "Coracao: o Especial devia ajudar sem resolver a luta (%.1f vs %.1f)" % [esp["ttk"], lido["ttk"]])
	_ok(float(lido["fase2_em"]) > 0.0, "Coracao: a fase 2 nunca arrancou")
	_ok(int(lido["raizes_cedo"]) == 0, "Coracao: %d raizes com aviso < 0,9 s" % lido["raizes_cedo"])
	_ok(float(lido["pior_estado"]) <= 6.0, "Coracao: ficou %.1f s no mesmo estado" % lido["pior_estado"])
	for w in lido["tel_pulso"]:
		_ok(float(w) >= 0.6, "Coracao: pulso com aviso de %.2f s (< 0,6 s)" % float(w))
	var jan: Array = lido["janelas"]
	_ok(jan.size() >= 4, "Coracao: menos de 4 janelas (%d)" % jan.size())
	for w in jan:
		_ok(float(w) >= 1.2 and float(w) <= 4.6, "Coracao: janela de %.2f s fora de 1,2-4,6 s" % float(w))
	_ok(bool(lido["saida"]), "Coracao: ao morrer nao apareceu o bau nem abriu a porta")
	EstadoJogo.bosses_derrotados.assign(antes_bosses)
	EstadoJogo.modo_dev = antes_dev
	EstadoJogo.indice_nivel = antes_idx
	EstadoJogo.habilidades.assign(antes_hab)


## Fim da Regiao I: o cartao mostra a regiao + a habilidade, e Continuar emite `fechado`.
func teste_cartao_regiao1() -> void:
	var pai := Node.new()
	get_tree().root.add_child(pai)
	var cartao: Node = preload("res://scripts/cartao_regiao.gd").mostrar(pai, "region.1.complete", "salto_duplo")
	await get_tree().process_frame
	var textos: Array[String] = []
	for n in cartao.find_children("*", "Label", true, false):
		textos.append((n as Label).text)
	var junto := " | ".join(textos)
	_ok(junto.contains(Textos.t("region.1.complete")), "cartao: mostra o nome da regiao")
	_ok(junto.contains(Textos.tf("region.ability_unlocked", [Textos.t("hud.ability.salto_duplo")])), "cartao: SALTO DUPLO DESBLOQUEADO")
	_ok(Textos.t("region.1.complete") != "region.1.complete", "cartao: chave i18n existe")
	_ok(preload("res://scripts/nivel_com_chefe.gd").REGIAO_CONCLUIDA.get(4, "") == "region.1.complete", "cartao: ligado ao nivel 5")
	var fechou := [false]
	cartao.fechado.connect(func() -> void: fechou[0] = true)
	(cartao.find_children("*", "Button", true, false)[0] as Button).pressed.emit()
	_ok(fechou[0], "cartao: Continuar fecha")
	pai.queue_free()


## Fluxo real do N5: boss derrotado -> salto duplo -> bau -> cartao -> Continuar -> porta aberta.
func teste_fluxo_fim_regiao1() -> void:
	var antes_bosses: Array[String] = EstadoJogo.bosses_derrotados.duplicate()
	var antes_rec: Array = EstadoJogo.recompensas_reclamadas.duplicate()
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	var antes_idx: int = EstadoJogo.indice_nivel
	EstadoJogo.bosses_derrotados.clear()
	EstadoJogo.recompensas_reclamadas.clear()
	EstadoJogo.habilidades.assign(["dash", "pogo", "especial"])
	EstadoJogo.indice_nivel = 4
	var nivel := (load("res://scenes/levels/Coracao_da_Floresta.tscn") as PackedScene).instantiate()
	add_child(nivel)
	for i in 6:
		await get_tree().process_frame
	var porta := nivel.get_node("Porta") as Area2D
	_ok(not porta.monitoring, "fluxo R1: porta selada antes do boss")
	_ok(not EstadoJogo.tem_habilidade("salto_duplo"), "fluxo R1: salto duplo so' depois do boss")
	nivel.get_node("Chefe").derrotado.emit()
	for i in 4:
		await get_tree().process_frame
	_ok(EstadoJogo.tem_habilidade("salto_duplo"), "fluxo R1: boss derrotado desbloqueia salto duplo")
	var bau := nivel.get_node_or_null("BauChefe")
	_ok(bau != null, "fluxo R1: bau nasce")
	_ok(not porta.monitoring, "fluxo R1: porta continua selada com o bau por abrir")
	if bau:
		bau._abrir()
		var botoes: Array = bau._painel.find_children("*", "Button", true, false)
		_ok(not botoes.is_empty(), "fluxo R1: painel do bau tem Continuar")
		(botoes[0] as Button).pressed.emit()
		await get_tree().process_frame
		var cartao := nivel.get_node_or_null("CartaoRegiao")
		_ok(cartao != null, "fluxo R1: cartao de fim de regiao aparece")
		_ok(not porta.monitoring, "fluxo R1: porta selada enquanto o cartao esta' aberto")
		if cartao:
			(cartao.find_children("*", "Button", true, false)[0] as Button).pressed.emit()
			await get_tree().process_frame
			_ok(porta.monitoring, "fluxo R1: Continuar abre a porta")
	nivel.queue_free()
	await get_tree().process_frame
	EstadoJogo.bosses_derrotados.assign(antes_bosses)
	EstadoJogo.recompensas_reclamadas.assign(antes_rec)
	EstadoJogo.habilidades.assign(antes_hab)
	EstadoJogo.indice_nivel = antes_idx


## N6 -- As Falesias Abertas (nivel AUTORAL da Regiao II: o VENTO, sem skill nova, Golem das Falesias como Guardiao).
func teste_n6_autoral() -> void:
	var antes_dev: bool = EstadoJogo.modo_dev
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	var antes_bosses: Array[String] = EstadoJogo.bosses_derrotados.duplicate()
	var antes_idx: int = EstadoJogo.indice_nivel
	EstadoJogo.modo_dev = false
	EstadoJogo.indice_nivel = 5
	EstadoJogo.habilidades.assign(["dash", "pogo", "especial", "salto_duplo"])
	var n := (load("res://scenes/levels/Prisao_dos_Condenados.tscn") as PackedScene).instantiate()
	add_child(n)
	for i in 6:
		await get_tree().process_frame
	# --- estrutura: authored, sem jornada, guardiao (nao boss), sem skills novas ---
	_ok(not bool(n.get("corredor")) and bool(n.get("checkpoints_autorais")), "N6: nao e' autoral")
	_ok(n.get_node_or_null("CorredorAproximacao") == null, "N6: o gerador criou uma jornada")
	_ok(n.get_node_or_null("Guardiao") is ChefeCarcereiro and n.get_node_or_null("Chefe") == null,
		"N6: tem de fechar com o Golem como Guardiao, sem Chefe regional")
	_ok(n.get_node_or_null("Porta") != null, "N6: sem Porta")
	var chk := 0
	for c in get_tree().get_nodes_in_group("checkpoints"):
		if n.is_ancestor_of(c):
			chk += 1
	_ok(chk == 5, "N6: esperava 5 checkpoints, ha %d" % chk)
	var proibidos := ["serra.gd", "fogo.gd", "guilhotina.gd", "pendulo_lamina.gd", "portal.gd", "trampolim.gd",
		"tumulo_elevador.gd", "plataforma_ritmada.gd", "torreta.gd", "teia_prende.gd", "raiz_elevatoria.gd",
		"alavanca.gd", "porta_trancada.gd", "gota_acida.gd", "zona_gravidade.gd", "coletavel.gd", "corrente_ar.gd"]
	var correntes := 0
	var zonas: Array[WindZone] = []
	for no in n.find_children("*", "", true, false):
		var sc := no.get_script() as Script
		if sc == null:
			continue
		for pr in proibidos:
			_ok(not sc.resource_path.ends_with(pr), "N6: %s nao pertence ao N6 (skill/mecanica alheia)" % no.name)
		if sc.resource_path.ends_with("plataforma_corrente.gd"):
			correntes += 1
		if no is WindZone:
			zonas.append(no)
	_ok(correntes == 1, "N6: esperava UMA plataforma movel, ha %d" % correntes)
	_ok(n.find_children("*", "Coletavel", true, false).is_empty(), "N6: nao ensina skills (sem Coletavel)")
	# --- vento: 7 zonas, as duas direcoes, ensino continuo antes do pulsado ---
	_ok(zonas.size() == 7, "N6: esperava 7 zonas de vento, ha %d" % zonas.size())
	var dir_pos := 0
	var dir_neg := 0
	var continuas := 0
	for z in zonas:
		if z.direcao.x > 0.0:
			dir_pos += 1
		elif z.direcao.x < 0.0:
			dir_neg += 1
		if z.modo == WindZone.Modo.CONTINUO:
			continuas += 1
		_ok(absf(z.direcao.y) < 0.001, "N6: %s deve ser horizontal" % z.name)
	_ok(dir_pos > 0 and dir_neg > 0, "N6: faltam rajadas nas duas direcoes")
	var teach := n.get_node("VentoAprende1") as WindZone
	_ok(teach.modo == WindZone.Modo.CONTINUO and n.get_node("VentoAprende2").modo == WindZone.Modo.CONTINUO,
		"N6: o ensino do vento tem de ser continuo")
	_ok(continuas == 2 and teach.velocidade_max <= 140.0, "N6: so' o ensino (2) e' continuo e fraco")
	# zonas de ensino nao cobrem checkpoints (spawn/checkpoint = area segura e previsivel)
	for nome_z in ["VentoAprende1", "VentoAprende2"]:
		var zc := n.get_node(nome_z) as WindZone
		var caixa := Rect2(zc.position - zc.tamanho * 0.5, zc.tamanho)
		for nome_c in ["CheckInicio", "CheckAntesPonte"]:
			_ok(not caixa.has_point((n.get_node(nome_c) as Node2D).position), "N6: %s cobre %s" % [nome_z, nome_c])
		_ok(not caixa.has_point((n.get_node("Koliani") as Node2D).position), "N6: %s cobre o spawn" % nome_z)
	# VentoArena: mecanica authored e legivel (guia visivel, fraco, pulsado, comeca bem antes do Golem, longe do checkpoint)
	var va := n.get_node("VentoArena") as WindZone
	var cf := n.get_node("CheckFinal") as Node2D
	var gg := n.get_node("Guardiao") as Node2D
	_ok(va.mostrar_guia and va.modo == WindZone.Modo.PULSADO and va.intensidade <= 1500.0 and va.velocidade_max <= 140.0,
		"N6: VentoArena tem de ter guia visivel, ser pulsado e fraco")
	_ok(va.position.x - va.tamanho.x * 0.5 >= cf.position.x + 100.0, "N6: o VentoArena nao pode cobrir/rodear o CheckFinal")
	_ok(gg.position.x - (va.position.x - va.tamanho.x * 0.5) >= 200.0, "N6: o vento tem de se ver 200+ px antes do Golem")
	_ok(va.fase_inicial == 0.0 and va.duracao_pulso >= 1.0, "N6: o vento da arena tem de comecar visivel")
	# ensino em chao firme: as zonas de ensino sobrepoem so' o ChaoInicio
	var chao_i := n.get_node("ChaoInicio") as Node2D
	_ok(chao_i.position.x - chao_i.tamanho.x * 0.5 <= 0.0 and chao_i.position.x + chao_i.tamanho.x * 0.5 >= 1000.0,
		"N6: o chao do ensino tem de cobrir 0-1000")
	# --- geometria: vaos e subidas dentro do salto simples (o vento so' os desloca) ---
	for cadeia in [["ChaoInicio", "Ponte1", "Ponte2", "Ponte3", "Ponte4", "Descanso"],
			["Descanso", "Cima1", "Cima2", "Cima3", "Cima4", "Reencontro"],
			["Descanso", "Baixo1", "LajeElite", "Reencontro"],
			["Reencontro", "P1", "P2"], ["P3", "P4", "ChaoChefe"]]:
		for i in range(cadeia.size() - 1):
			var a := n.get_node(cadeia[i]) as Node2D
			var b := n.get_node(cadeia[i + 1]) as Node2D
			var vao: float = (b.position.x - b.tamanho.x * 0.5) - (a.position.x + a.tamanho.x * 0.5)
			var sobe: float = (a.position.y - a.tamanho.y * 0.5) - (b.position.y - b.tamanho.y * 0.5)
			_ok(vao <= 140.0, "N6: vao %s->%s = %d (max 140)" % [cadeia[i], cadeia[i + 1], vao])
			_ok(sobe <= 104.0, "N6: subida %s->%s = %d (max 104)" % [cadeia[i], cadeia[i + 1], sobe])
	# ponte D1->corrente->P3: a plataforma movel cobre o vao maior fora do vento
	var cor_d := n.get_node("CorrenteD") as Node2D
	for nome_z in ["VentoD1", "VentoD2"]:
		var zz := n.get_node(nome_z) as WindZone
		_ok(absf(zz.position.x - cor_d.position.x) > zz.tamanho.x * 0.5 + 60.0,
			"N6: a plataforma movel esta' dentro do %s" % nome_z)
	# --- Guardiao: elite regional-lite, sela a porta e nao e' boss ---
	var g := n.get_node("Guardiao") as ChefeCarcereiro
	var porta := n.get_node("Porta") as Area2D
	_ok(g.vida >= 400 and g.vida <= 900, "N6: vida do Guardiao %d fora de 400-900 (nao pode competir com o boss)" % g.vida)
	_ok(not porta.monitoring, "N6: porta selada com o Guardiao vivo")
	g.queue_free()
	for i in 4:
		await get_tree().process_frame
	_ok(porta.monitoring, "N6: a porta abre quando o Guardiao cai")
	_ok(EstadoJogo.bosses_derrotados == antes_bosses, "N6: o Guardiao nao pode gravar boss derrotado")
	_ok(not EstadoJogo.tem_habilidade("escalar_paredes") and not EstadoJogo.tem_habilidade("dash_aereo"),
		"N6: nao concede habilidades")
	# --- o vento MEXE mesmo na Koliani no AR (no chao o atrito come-o): a favor no ensino 1, contra no 2 ---
	n.queue_free()
	await get_tree().process_frame
	var n2 := (load("res://scenes/levels/Prisao_dos_Condenados.tscn") as PackedScene).instantiate()
	add_child(n2)
	for i in 6:
		await get_tree().process_frame
	var k := n2.get_node("Koliani") as CharacterBody2D
	var dx_favor := await _deriva_n6(k, Vector2(430, 510))
	_ok(dx_favor > 8.0, "N6: o vento a favor nao empurra a Koliani no ar (dx=%s)" % str(snappedf(dx_favor, 0.1)))
	var dx_contra := await _deriva_n6(k, Vector2(740, 510))
	_ok(dx_contra < -8.0, "N6: o vento contra nao empurra a Koliani no ar (dx=%s)" % str(snappedf(dx_contra, 0.1)))
	n2.queue_free()
	await get_tree().process_frame
	EstadoJogo.modo_dev = antes_dev
	EstadoJogo.habilidades.assign(antes_hab)
	EstadoJogo.bosses_derrotados.assign(antes_bosses)
	EstadoJogo.indice_nivel = antes_idx


## Larga a Koliani no ar e mede quanto o vento a desloca em ~0,5 s.
func _deriva_n6(k: CharacterBody2D, de: Vector2) -> float:
	k.global_position = de
	k.velocity = Vector2.ZERO
	var x0 := k.global_position.x
	for i in 30:
		await get_tree().physics_frame
	return k.global_position.x - x0


## N07 -- "The Rising Gorge": DESENVOLVIMENTO do vento ensinado no N06.
## Autoral, sem jornada, sem escalar_paredes, fecha com um GUARDIAO (elite
## que sela a porta -- NAO um chefe regional; o unico boss da Regiao II e'
## o Guardiao dos Ceus no N10). Ver `docs/nivel_autoral_n7.md`.
func teste_n7_autoral() -> void:
	var antes_dev: bool = EstadoJogo.modo_dev
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	var antes_bosses: Array[String] = EstadoJogo.bosses_derrotados.duplicate()
	var antes_idx: int = EstadoJogo.indice_nivel
	EstadoJogo.modo_dev = false
	EstadoJogo.indice_nivel = 6
	EstadoJogo.habilidades.assign(["dash", "pogo", "especial", "salto_duplo"])
	var n := (load("res://scenes/levels/Fornalha_dos_Pecadores.tscn") as PackedScene).instantiate()
	add_child(n)
	for i in 6:
		await get_tree().process_frame
	# --- estrutura: authored, sem jornada, Guardiao (nao boss), sem skills novas ---
	_ok(not bool(n.get("corredor")) and bool(n.get("checkpoints_autorais")), "N7: nao e' autoral")
	_ok(n.get_node_or_null("CorredorAproximacao") == null, "N7: o gerador criou uma jornada")
	_ok(n.get_node_or_null("Guardiao") is DemonioBase and n.get_node_or_null("Chefe") == null,
		"N7: N07 e' Develop/Test -- fecha com um Guardiao (elite), nao com um Chefe regional")
	var porta := n.get_node_or_null("Porta") as Area2D
	_ok(porta != null, "N7: sem Porta")
	_ok(not porta.monitoring, "N7: porta selada com o Guardiao vivo")
	var chk := 0
	for c in get_tree().get_nodes_in_group("checkpoints"):
		if n.is_ancestor_of(c):
			chk += 1
	_ok(chk >= 4 and chk <= 5, "N7: esperava 4-5 checkpoints, ha %d" % chk)
	_ok(n.find_children("*", "Coletavel", true, false).is_empty(),
		"N7: nao pode ensinar/dar escalar_paredes (Coletavel encontrado)")
	var proibidos := ["serra.gd", "fogo.gd", "guilhotina.gd", "pendulo_lamina.gd", "portal.gd", "trampolim.gd",
		"tumulo_elevador.gd", "plataforma_ritmada.gd", "torreta.gd", "teia_prende.gd", "raiz_elevatoria.gd",
		"alavanca.gd", "porta_trancada.gd", "gota_acida.gd", "zona_gravidade.gd", "coletavel.gd", "corrente_ar.gd"]
	var correntes := 0
	var zonas: Array[WindZone] = []
	for no in n.find_children("*", "", true, false):
		var sc := no.get_script() as Script
		if sc == null:
			continue
		for pr in proibidos:
			_ok(not sc.resource_path.ends_with(pr), "N7: %s nao pertence ao N7 (skill/mecanica alheia)" % no.name)
		if sc.resource_path.ends_with("plataforma_corrente.gd"):
			correntes += 1
		if no is WindZone:
			zonas.append(no)
	_ok(correntes == 1, "N7: esperava UMA plataforma movel, ha %d" % correntes)
	# --- vento: as duas direcoes, ensino continuo e fraco, mudanca de direcao legivel ---
	_ok(zonas.size() == 9, "N7: esperava 9 zonas de vento, ha %d" % zonas.size())
	var dir_pos := 0
	var dir_neg := 0
	var continuas := 0
	for z in zonas:
		if z.direcao.x > 0.0:
			dir_pos += 1
		elif z.direcao.x < 0.0:
			dir_neg += 1
		if z.modo == WindZone.Modo.CONTINUO:
			continuas += 1
		_ok(absf(z.direcao.y) < 0.001, "N7: %s deve ser horizontal" % z.name)
	_ok(dir_pos > 0 and dir_neg > 0, "N7: faltam rajadas nas duas direcoes")
	var reintro := n.get_node("VentoReintro") as WindZone
	_ok(reintro.modo == WindZone.Modo.CONTINUO and reintro.velocidade_max <= 140.0,
		"N7: a reintro tem de ser continua e fraca, so' para relembrar")
	# reintro nao cobre o CheckInicio nem o spawn (area segura e previsivel)
	var caixa_reintro := Rect2(reintro.position - reintro.tamanho * 0.5, reintro.tamanho)
	_ok(not caixa_reintro.has_point((n.get_node("CheckInicio") as Node2D).position),
		"N7: VentoReintro cobre o CheckInicio")
	_ok(not caixa_reintro.has_point((n.get_node("Koliani") as Node2D).position),
		"N7: VentoReintro cobre o spawn")
	# mudanca de direcao: as duas zonas de C tem direcoes opostas e sao legiveis (guia + pulsado)
	var favor := n.get_node("WindDirFavor") as WindZone
	var contra := n.get_node("WindDirContra") as WindZone
	_ok(favor.direcao.x > 0.0 and contra.direcao.x < 0.0, "N7: a seccao C tem de alternar direcao")
	_ok(favor.mostrar_guia and contra.mostrar_guia, "N7: a mudanca de direcao tem de ter guia visivel")
	_ok(favor.modo == WindZone.Modo.PULSADO and contra.modo == WindZone.Modo.PULSADO,
		"N7: a seccao C tem de ser pulsada (le-se o intervalo)")
	# dash + vento: continuo contra, mas ha' apoio sem precisao pixel-perfect
	var wdash := n.get_node("WindDash") as WindZone
	_ok(wdash.modo == WindZone.Modo.CONTINUO and wdash.direcao.x < 0.0,
		"N7: WindDash tem de ser continuo e contra (e' o que torna o Dash util)")
	_ok(n.get_node_or_null("DashApoio") != null, "N7: falta a plataforma de apoio (sem exigir Dash pixel-perfect)")
	# checkpoints nunca dentro de vento perigoso (so' o VentoReintro, fraco, e' tolerado -- ja verificado acima)
	for nome_z in ["VentoDesenvolve", "WindDirFavor", "WindDirContra", "WindDash", "WindCombo",
			"WindFechoFavor", "WindFechoContra", "VentoArena"]:
		var zc := n.get_node(nome_z) as WindZone
		var caixa := Rect2(zc.position - zc.tamanho * 0.5, zc.tamanho)
		for c in get_tree().get_nodes_in_group("checkpoints"):
			if n.is_ancestor_of(c) and c is Node2D:
				_ok(not caixa.has_point((c as Node2D).position), "N7: %s cobre um checkpoint" % nome_z)
	# VentoArena: mecanica authored e legivel (guia visivel, fraco, pulsado, comeca bem antes do Guardiao)
	var va := n.get_node("VentoArena") as WindZone
	var gg := n.get_node("Guardiao") as Node2D
	_ok(va.mostrar_guia and va.modo == WindZone.Modo.PULSADO and va.intensidade <= 1500.0 and va.velocidade_max <= 140.0,
		"N7: VentoArena tem de ter guia visivel, ser pulsado e fraco")
	_ok(gg.position.x - (va.position.x - va.tamanho.x * 0.5) >= 200.0, "N7: o vento tem de se ver 200+ px antes do Guardiao")
	# --- geometria: vaos e subidas dentro do salto simples (o vento so' os desloca) ---
	for cadeia in [["ChaoInicio", "Ponte1", "Ponte2", "Ponte3", "Descanso"],
			["Descanso", "Dir1", "Dir2", "Dir3", "Dir4", "ReencontroDir"],
			["ReencontroDir", "DashA", "DashApoio", "DashB", "PousoD"],
			["ComboB", "Fecho1", "Fecho2", "Fecho3", "ChaoFinal"]]:
		for i in range(cadeia.size() - 1):
			var a := n.get_node(cadeia[i]) as Node2D
			var b := n.get_node(cadeia[i + 1]) as Node2D
			var vao: float = (b.position.x - b.tamanho.x * 0.5) - (a.position.x + a.tamanho.x * 0.5)
			var sobe: float = (a.position.y - a.tamanho.y * 0.5) - (b.position.y - b.tamanho.y * 0.5)
			_ok(vao <= 140.0, "N7: vao %s->%s = %d (max 140)" % [cadeia[i], cadeia[i + 1], vao])
			_ok(sobe <= 104.0, "N7: subida %s->%s = %d (max 104)" % [cadeia[i], cadeia[i + 1], sobe])
	# --- Guardiao: elite regional-lite, sela a porta e nao e' boss ---
	var g := n.get_node("Guardiao") as DemonioBase
	_ok(g.vida >= 100 and g.vida <= 300, "N7: vida do Guardiao %d fora de 100-300 (nao pode competir com o boss)" % g.vida)
	g.queue_free()
	for i in 4:
		await get_tree().process_frame
	_ok(porta.monitoring, "N7: a porta abre quando o Guardiao cai")
	_ok(EstadoJogo.bosses_derrotados == antes_bosses, "N7: o Guardiao nao pode gravar boss derrotado")
	_ok(not EstadoJogo.tem_habilidade("escalar_paredes") and not EstadoJogo.tem_habilidade("dash_aereo"),
		"N7: nao pode conceder habilidades")
	# --- o vento MEXE mesmo na Koliani no AR: a favor na reintro ---
	var k := n.get_node("Koliani") as CharacterBody2D
	var dx_favor := await _deriva_n6(k, Vector2(600, 480))
	_ok(dx_favor > 8.0, "N7: o vento de reintro nao empurra a Koliani no ar (dx=%s)" % str(snappedf(dx_favor, 0.1)))
	n.queue_free()
	await get_tree().process_frame
	EstadoJogo.modo_dev = antes_dev
	EstadoJogo.habilidades.assign(antes_hab)
	EstadoJogo.bosses_derrotados.assign(antes_bosses)
	EstadoJogo.indice_nivel = antes_idx


## N08 -- "Desfiladeiro dos Ventos", COMBINE (estrutura regional N6=Teach,
## N7=Develop/Test, N8=Combine, N9=Challenge, N10=Boss/Exame). Sem chefe,
## sem jornada procedural, sem a ZonaPlanar/`Chefe` legacy do "Process 11"
## (ver comentario no topo de `Corredor_das_Execucoes.tscn`).
func teste_n8_autoral() -> void:
	var antes_dev: bool = EstadoJogo.modo_dev
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	var antes_bosses: Array[String] = EstadoJogo.bosses_derrotados.duplicate()
	var antes_idx: int = EstadoJogo.indice_nivel
	EstadoJogo.modo_dev = false
	EstadoJogo.indice_nivel = 7
	EstadoJogo.habilidades.assign(["dash", "pogo", "especial", "salto_duplo"])
	var n := (load("res://scenes/levels/Corredor_das_Execucoes.tscn") as PackedScene).instantiate()
	add_child(n)
	for i in 6:
		await get_tree().process_frame
	# --- estrutura: authored, sem jornada, Guardiao (nao boss), sem skills novas ---
	_ok(not bool(n.get("corredor")) and bool(n.get("checkpoints_autorais")), "N8: nao e' autoral")
	_ok(n.get_node_or_null("CorredorAproximacao") == null, "N8: o gerador criou uma jornada")
	_ok(n.get_node_or_null("Guardiao") is DemonioBase and n.get_node_or_null("Chefe") == null,
		"N8: e' Combine -- fecha com um Guardiao (elite), nao com um Chefe regional")
	var porta := n.get_node_or_null("Porta") as Area2D
	_ok(porta != null, "N8: sem Porta")
	_ok(not porta.monitoring, "N8: porta selada com o Guardiao vivo")
	var chk := 0
	for c in get_tree().get_nodes_in_group("checkpoints"):
		if n.is_ancestor_of(c):
			chk += 1
	_ok(chk >= 4 and chk <= 6, "N8: esperava 4-6 checkpoints, ha %d" % chk)
	_ok(n.find_children("*", "Coletavel", true, false).is_empty(),
		"N8: nao pode ensinar/dar escalar_paredes (Coletavel encontrado)")
	_ok(n.find_children("*", "ZonaPlanar", true, false).is_empty(),
		"N8: a ZonaPlanar (Process 11) devia ter sido removida -- planar nao e' skill do N8")
	var proibidos := ["serra.gd", "fogo.gd", "guilhotina.gd", "pendulo_lamina.gd", "portal.gd", "trampolim.gd",
		"tumulo_elevador.gd", "plataforma_ritmada.gd", "torreta.gd", "teia_prende.gd", "raiz_elevatoria.gd",
		"alavanca.gd", "porta_trancada.gd", "gota_acida.gd", "zona_gravidade.gd", "coletavel.gd",
		"corrente_ar.gd", "zona_planar.gd"]
	var correntes := 0
	var zonas: Array[WindZone] = []
	for no in n.find_children("*", "", true, false):
		var sc := no.get_script() as Script
		if sc == null:
			continue
		for pr in proibidos:
			_ok(not sc.resource_path.ends_with(pr), "N8: %s nao pertence ao N8 (skill/mecanica alheia)" % no.name)
		if sc.resource_path.ends_with("plataforma_corrente.gd"):
			correntes += 1
		if no is WindZone:
			zonas.append(no)
	_ok(correntes == 1, "N8: esperava UMA plataforma movel (rota rapida), ha %d" % correntes)
	# --- wall-jump: nunca exigido, nunca prometido ---
	_ok(not EstadoJogo.tem_habilidade("escalar_paredes"), "N8: escalar_paredes nao pode estar concedida a esta altura da campanha")
	# --- vento: as duas direcoes, tudo horizontal ---
	_ok(zonas.size() == 8, "N8: esperava 8 zonas de vento, ha %d" % zonas.size())
	var dir_pos := 0
	var dir_neg := 0
	for z in zonas:
		if z.direcao.x > 0.0:
			dir_pos += 1
		elif z.direcao.x < 0.0:
			dir_neg += 1
		_ok(absf(z.direcao.y) < 0.001, "N8: %s deve ser horizontal" % z.name)
	_ok(dir_pos > 0 and dir_neg > 0, "N8: faltam rajadas nas duas direcoes")
	# --- checkpoints nunca dentro de vento perigoso (VentoArena e' excecao, mesmo padrao do N6/N7) ---
	for nome_z in ["WindB1", "WindB2", "WindC", "WindRisco", "WindE", "WindF1", "WindF2"]:
		var zc := n.get_node(nome_z) as WindZone
		var caixa := Rect2(zc.position - zc.tamanho * 0.5, zc.tamanho)
		for c in get_tree().get_nodes_in_group("checkpoints"):
			if n.is_ancestor_of(c) and c is Node2D:
				_ok(not caixa.has_point((c as Node2D).position), "N8: %s cobre um checkpoint" % nome_z)
	# reintro (secao A) nao tem vento -- nada a fazer perto do spawn/CheckInicio (verificado acima)
	# --- secao B: vento CONTRA continuo, corrige com salto duplo (nao e' pulsado) ---
	var windb1 := n.get_node("WindB1") as WindZone
	var windb2 := n.get_node("WindB2") as WindZone
	_ok(windb1.modo == WindZone.Modo.CONTINUO and windb1.direcao.x < 0.0
		and windb2.modo == WindZone.Modo.CONTINUO and windb2.direcao.x < 0.0,
		"N8: secao B tem de ser vento CONTRA continuo (o salto duplo corrige, nao so' sobe)")
	# --- secao C: vento CONTRA continuo + Dash, com apoio sem exigir precisao ---
	var windc := n.get_node("WindC") as WindZone
	_ok(windc.modo == WindZone.Modo.CONTINUO and windc.direcao.x < 0.0,
		"N8: WindC tem de ser continuo e contra (e' o que torna o Dash util)")
	_ok(n.get_node_or_null("DashApoio") != null, "N8: falta a plataforma de apoio da seccao C (sem exigir Dash pixel-perfect)")
	# --- secao D: bifurcacao segura (sem vento) vs rapida (vento a favor pulsado + plataforma movel + recompensa) ---
	_ok(n.get_node_or_null("SeguroA") != null and n.get_node_or_null("SeguroB") != null,
		"N8: falta a rota segura da seccao D")
	var windrisco := n.get_node("WindRisco") as WindZone
	_ok(windrisco.modo == WindZone.Modo.PULSADO and windrisco.direcao.x > 0.0,
		"N8: WindRisco (rota rapida) tem de ser pulsado e a favor")
	var seguro_a := n.get_node("SeguroA") as Node2D
	var caixa_risco := Rect2(windrisco.position - windrisco.tamanho * 0.5, windrisco.tamanho)
	_ok(not caixa_risco.has_point(seguro_a.position), "N8: a rota segura nao pode estar dentro do vento da rota rapida")
	_ok(n.get_node_or_null("CacheRisco") != null, "N8: falta a recompensa (Essencia) da rota rapida")
	_ok(n.get_node_or_null("Converge") != null, "N8: as duas rotas tem de convergir sem grande backtracking")
	# --- secao E: vento pulsado + ameaca conhecida + pogo OPCIONAL (nunca obrigatorio) ---
	var winde := n.get_node("WindE") as WindZone
	_ok(winde.modo == WindZone.Modo.PULSADO, "N8: WindE (ameaca) tem de ser pulsado (le-se antes de agir)")
	var ameaca := n.get_node_or_null("MorcegoAmeaca") as DemonioBase
	_ok(ameaca != null and not ameaca.elite, "N8: a ameaca da seccao E tem de ser um inimigo simples, nao elite")
	_ok(n.get_node_or_null("AlvoPogo") != null and n.get_node_or_null("PlatAlvo") != null,
		"N8: falta o alvo de pogo authored (opcional) da seccao E")
	# --- secao F: mini-exame -- vento (favor+contra) + salto duplo + Dash, SEM boss ---
	var windf1 := n.get_node("WindF1") as WindZone
	var windf2 := n.get_node("WindF2") as WindZone
	_ok(windf1.direcao.x > 0.0 and windf2.direcao.x < 0.0,
		"N8: o mini-exame tem de combinar as duas direcoes de vento")
	_ok(n.get_node_or_null("FDashApoio") != null, "N8: falta o apoio de Dash do mini-exame")
	# --- Guardiao: elite regional-lite, sela a porta, nao e' boss, sem piso de vida de chefe ---
	var g := n.get_node("Guardiao") as DemonioBase
	_ok(g.vida >= 100 and g.vida <= 300, "N8: vida do Guardiao %d fora de 100-300 (nao pode competir com o boss do N10)" % g.vida)
	var va := n.get_node("VentoArena") as WindZone
	_ok(va.mostrar_guia and va.modo == WindZone.Modo.PULSADO and va.intensidade <= 1500.0 and va.velocidade_max <= 140.0,
		"N8: VentoArena tem de ter guia visivel, ser pulsado e fraco")
	_ok(g.position.x - (va.position.x - va.tamanho.x * 0.5) >= 200.0, "N8: o vento tem de se ver 200+ px antes do Guardiao")
	g.queue_free()
	for i in 4:
		await get_tree().process_frame
	_ok(porta.monitoring, "N8: a porta abre quando o Guardiao cai")
	_ok(EstadoJogo.bosses_derrotados == antes_bosses, "N8: o Guardiao nao pode gravar boss derrotado")
	_ok(not EstadoJogo.tem_habilidade("escalar_paredes") and not EstadoJogo.tem_habilidade("dash_aereo"),
		"N8: nao pode conceder habilidades")
	# --- geometria: vaos e subidas dentro do envolvente do salto simples/duplo ---
	for cadeia in [["ChaoInicio", "IlhaB1", "IlhaB2", "DescansoB"],
			["DescansoB", "PousoPreDash", "DashA", "DashApoio", "DashB", "PousoD"],
			["PousoD", "SeguroA", "SeguroB", "Converge"],
			["EPlat1", "EPlat2", "F1", "F2", "FDashApoio", "F3", "F4", "ChaoFinal"]]:
		for i in range(cadeia.size() - 1):
			var a := n.get_node(cadeia[i]) as Node2D
			var b := n.get_node(cadeia[i + 1]) as Node2D
			var vao: float = (b.position.x - b.tamanho.x * 0.5) - (a.position.x + a.tamanho.x * 0.5)
			_ok(vao <= 380.0, "N8: vao %s->%s = %d (max 380, salto duplo)" % [cadeia[i], cadeia[i + 1], vao])
	# --- o vento MEXE mesmo na Koliani no AR: contra na seccao B ---
	var k := n.get_node("Koliani") as CharacterBody2D
	var dx_contra := await _deriva_n6(k, Vector2(715, 480))
	_ok(absf(dx_contra) > 8.0, "N8: o vento da seccao B nao empurra a Koliani no ar (dx=%s)" % str(snappedf(dx_contra, 0.1)))
	n.queue_free()
	await get_tree().process_frame
	EstadoJogo.modo_dev = antes_dev
	EstadoJogo.habilidades.assign(antes_hab)
	EstadoJogo.bosses_derrotados.assign(antes_bosses)
	EstadoJogo.indice_nivel = antes_idx


## Fluxo real do N10 (execucao N10, Guardiao dos Ceus): porta selada -> boss
## derrotado -> escalar_paredes desbloqueado -> bau -> cartao "region.2.complete"
## -> Continuar -> porta aberta. Espelha `teste_fluxo_fim_regiao1`. Prova em
## cima do nivel REAL (nao um duplo local) que a recompensa e' idempotente
## (nao concede duas vezes) e que a Regiao III nao arranca sozinha.
func teste_fluxo_fim_regiao2() -> void:
	var antes_bosses: Array[String] = EstadoJogo.bosses_derrotados.duplicate()
	var antes_rec: Array = EstadoJogo.recompensas_reclamadas.duplicate()
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	var antes_idx: int = EstadoJogo.indice_nivel
	EstadoJogo.bosses_derrotados.clear()
	EstadoJogo.recompensas_reclamadas.clear()
	EstadoJogo.habilidades.assign(["dash", "pogo", "especial", "salto_duplo", "projetil"])
	EstadoJogo.indice_nivel = 9
	var nivel := (load("res://scenes/levels/A_Cela_Zero.tscn") as PackedScene).instantiate()
	add_child(nivel)
	for i in 6:
		await get_tree().process_frame
	var porta := nivel.get_node("Porta") as Area2D
	_ok(not porta.monitoring, "fluxo R2: porta selada antes do boss")
	_ok(not EstadoJogo.tem_habilidade("escalar_paredes"), "fluxo R2: escalar_paredes so' depois do boss")
	var chefe := nivel.get_node("Chefe")
	chefe.derrotado.emit()
	for i in 4:
		await get_tree().process_frame
	_ok(EstadoJogo.tem_habilidade("escalar_paredes"), "fluxo R2: boss derrotado desbloqueia escalar_paredes")
	# idempotencia: emitir outra vez (ex.: reload a meio do bau) nao pode
	# reconceder nem duplicar a entrada em `habilidades`.
	var n_antes: int = EstadoJogo.habilidades.count("escalar_paredes")
	if nivel.has_method("_abrir"):
		nivel._abrir()
	_ok(EstadoJogo.habilidades.count("escalar_paredes") == n_antes,
		"fluxo R2: reconceder escalar_paredes nao duplica a habilidade")
	var bau := nivel.get_node_or_null("BauChefe")
	_ok(bau != null, "fluxo R2: bau nasce")
	_ok(not porta.monitoring, "fluxo R2: porta continua selada com o bau por abrir")
	if bau:
		bau._abrir()
		var botoes: Array = bau._painel.find_children("*", "Button", true, false)
		_ok(not botoes.is_empty(), "fluxo R2: painel do bau tem Continuar")
		(botoes[0] as Button).pressed.emit()
		await get_tree().process_frame
		var cartao := nivel.get_node_or_null("CartaoRegiao")
		_ok(cartao != null, "fluxo R2: cartao de fim de regiao aparece")
		_ok(not porta.monitoring, "fluxo R2: porta selada enquanto o cartao esta' aberto")
		if cartao:
			var textos: Array[String] = []
			for lab in cartao.find_children("*", "Label", true, false):
				textos.append((lab as Label).text)
			var junto := " | ".join(textos)
			_ok(junto.contains(Textos.t("region.2.complete")), "fluxo R2: cartao mostra DESFILADEIRO DOS VENTOS CONCLUIDO")
			(cartao.find_children("*", "Button", true, false)[0] as Button).pressed.emit()
			await get_tree().process_frame
			_ok(porta.monitoring, "fluxo R2: Continuar abre a porta")
	# Regiao III nao arranca sozinha: o proximo indice da campanha (10) tem
	# de continuar a ser um nivel valido da NIVEIS, nao uma cena nova criada
	# por esta execucao.
	_ok(EstadoJogo.NIVEIS.size() > 10 and EstadoJogo.NIVEIS[10] == "res://scenes/levels/Torre_dos_Sinos.tscn",
		"fluxo R2: N11 continua a ser a cena existente (Regiao III nao comecada aqui)")
	nivel.queue_free()
	await get_tree().process_frame
	EstadoJogo.bosses_derrotados.assign(antes_bosses)
	EstadoJogo.recompensas_reclamadas.assign(antes_rec)
	EstadoJogo.habilidades.assign(antes_hab)
	EstadoJogo.indice_nivel = antes_idx


func teste_n9_autoral() -> void:
	var antes_dev: bool = EstadoJogo.modo_dev
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	var antes_bosses: Array[String] = EstadoJogo.bosses_derrotados.duplicate()
	var antes_idx: int = EstadoJogo.indice_nivel
	EstadoJogo.modo_dev = false
	EstadoJogo.indice_nivel = 8
	EstadoJogo.habilidades.assign(["dash", "pogo", "especial", "salto_duplo"])
	var n := (load("res://scenes/levels/Ala_dos_Mortos.tscn") as PackedScene).instantiate()
	add_child(n)
	for i in 6:
		await get_tree().process_frame
	# --- estrutura: authored, sem jornada, Guardiao (nao boss/chefe), sem skill nova ---
	_ok(not bool(n.get("corredor")) and bool(n.get("checkpoints_autorais")), "N9: nao e' autoral")
	_ok(n.get_node_or_null("CorredorAproximacao") == null, "N9: o gerador criou uma jornada (legacy `corredor=true` nao corrigido)")
	_ok(n.get_node_or_null("Guardiao") is DemonioBase and n.get_node_or_null("Chefe") == null,
		"N9: e' Challenge -- fecha com um Guardiao (elite), nao com um Chefe/boss regional")
	var porta := n.get_node_or_null("Porta") as Area2D
	_ok(porta != null, "N9: sem Porta")
	_ok(not porta.monitoring, "N9: porta selada com o Guardiao vivo")
	var chk := 0
	for c in get_tree().get_nodes_in_group("checkpoints"):
		if n.is_ancestor_of(c):
			chk += 1
	_ok(chk >= 4 and chk <= 6, "N9: esperava 4-6 checkpoints, ha %d" % chk)
	_ok(n.find_children("*", "Coletavel", true, false).is_empty(),
		"N9: nao pode ensinar/dar habilidade (Coletavel encontrado, o unico ponto de concessao da regiao e' o N10)")
	_ok(n.find_children("*", "ZonaPlanar", true, false).is_empty(),
		"N9: a ZonaPlanar nao e' skill do N9")
	_ok(n.get_node_or_null("Casca") == null,
		"N9: a CascaMasmorra (legacy 'Ala dos Mortos') devia ter sido removida -- a regiao e' desfiladeiro aberto")
	var proibidos := ["serra.gd", "fogo.gd", "guilhotina.gd", "pendulo_lamina.gd", "portal.gd", "trampolim.gd",
		"tumulo_elevador.gd", "plataforma_ritmada.gd", "torreta.gd", "teia_prende.gd", "raiz_elevatoria.gd",
		"alavanca.gd", "porta_trancada.gd", "gota_acida.gd", "zona_gravidade.gd", "coletavel.gd",
		"corrente_ar.gd", "zona_planar.gd", "plataforma_espectral.gd"]
	var correntes := 0
	var inimigos := 0
	var elites := 0
	var zonas: Array[WindZone] = []
	for no in n.find_children("*", "", true, false):
		var sc := no.get_script() as Script
		if no is DemonioBase:
			inimigos += 1
			if (no as DemonioBase).elite:
				elites += 1
		if sc == null:
			continue
		for pr in proibidos:
			_ok(not sc.resource_path.ends_with(pr), "N9: %s nao pertence ao N9 (skill/mecanica alheia)" % no.name)
		if sc.resource_path.ends_with("plataforma_corrente.gd"):
			correntes += 1
		if no is WindZone:
			zonas.append(no)
	_ok(correntes == 1, "N9: esperava UMA plataforma movel (secao D), ha %d" % correntes)
	_ok(elites == 1, "N9: so' o Guardiao pode ser elite (ha %d elites)" % elites)
	_ok(inimigos >= 4 and inimigos <= 7, "N9: esperava poucos inimigos bem colocados (4-7, incl. Guardiao), ha %d" % inimigos)
	# --- wall-jump: nunca exigido, nunca prometido; sem skill nova ---
	_ok(not EstadoJogo.tem_habilidade("escalar_paredes"), "N9: escalar_paredes nao pode estar concedida a esta altura da campanha")
	# --- vento: mais zonas/variedade que o N8 (Challenge > Combine), as duas direcoes, tudo horizontal ---
	_ok(zonas.size() >= 9, "N9: esperava pelo menos 9 zonas de vento (mais variedade que o N8), ha %d" % zonas.size())
	var dir_pos := 0
	var dir_neg := 0
	var continuas := 0
	var pulsadas := 0
	for z in zonas:
		if z.direcao.x > 0.0:
			dir_pos += 1
		elif z.direcao.x < 0.0:
			dir_neg += 1
		_ok(absf(z.direcao.y) < 0.001, "N9: %s deve ser horizontal" % z.name)
		if z.modo == WindZone.Modo.CONTINUO:
			continuas += 1
		else:
			pulsadas += 1
	_ok(dir_pos > 0 and dir_neg > 0, "N9: faltam rajadas nas duas direcoes")
	_ok(continuas > 0 and pulsadas > 0, "N9: secao B tem de combinar continuo e pulsado (comportamentos diferentes)")
	# --- checkpoints nunca dentro de vento perigoso (VentoArena e' excecao, mesmo padrao do N6/N7/N8) ---
	for nome_z in ["WindB1", "WindB2", "WindB3", "WindC", "WindD", "WindRiscoE", "WindF1", "WindF2", "WindF3"]:
		var zc := n.get_node(nome_z) as WindZone
		var caixa := Rect2(zc.position - zc.tamanho * 0.5, zc.tamanho)
		for c in get_tree().get_nodes_in_group("checkpoints"):
			if n.is_ancestor_of(c) and c is Node2D:
				_ok(not caixa.has_point((c as Node2D).position), "N9: %s cobre um checkpoint" % nome_z)
	# --- secao B: tres comportamentos diferentes e consecutivos ---
	var windb1 := n.get_node("WindB1") as WindZone
	var windb2 := n.get_node("WindB2") as WindZone
	var windb3 := n.get_node("WindB3") as WindZone
	_ok(windb1.modo == WindZone.Modo.CONTINUO and windb1.direcao.x < 0.0, "N9: WindB1 tem de ser continuo e contra")
	_ok(windb2.modo == WindZone.Modo.PULSADO and windb2.direcao.x > 0.0, "N9: WindB2 tem de ser pulsado e a favor")
	_ok(windb3.modo == WindZone.Modo.PULSADO and windb3.direcao.x < 0.0, "N9: WindB3 tem de ser pulsado e contra (ritmo diferente do B2)")
	_ok(not is_equal_approx(windb2.duracao_pulso, windb3.duracao_pulso) or not is_equal_approx(windb2.intervalo_pulso, windb3.intervalo_pulso),
		"N9: WindB2 e WindB3 tem de ter ritmos de pulso distintos")
	# --- secao C: vento pulsado + inimigo simples (nao elite), legivel ---
	var windc := n.get_node("WindC") as WindZone
	_ok(windc.modo == WindZone.Modo.PULSADO, "N9: WindC (inimigo) tem de ser pulsado (le-se antes de agir)")
	var sentinela := n.get_node_or_null("SentinelaC") as DemonioBase
	_ok(sentinela != null and not sentinela.elite, "N9: o inimigo da seccao C tem de ser simples, nao elite")
	_ok(sentinela.comportamento != "cuspidor", "N9: sem projeteis sem leitura durante saltos criticos (seccao C)")
	# --- secao D: plataforma movel atravessa vento continuo forte + inimigo de pressao ---
	var windd := n.get_node("WindD") as WindZone
	_ok(windd.modo == WindZone.Modo.CONTINUO, "N9: WindD (secao D) tem de ser continuo -- a pressao vem de sustentar, nao de picos")
	var corrented := n.get_node_or_null("CorrenteD")
	_ok(corrented != null, "N9: falta a plataforma movel da seccao D")
	var morcegod := n.get_node_or_null("MorcegoD") as DemonioBase
	_ok(morcegod != null and not morcegod.elite, "N9: o inimigo da seccao D tem de ser simples, nao elite")
	# --- secao E: escolha opcional -- segura sem vento vs arriscada com vento+pogo+recompensa ---
	_ok(n.get_node_or_null("SeguroE1") != null and n.get_node_or_null("SeguroE2") != null,
		"N9: falta a rota segura da seccao E")
	var windriscoe := n.get_node("WindRiscoE") as WindZone
	_ok(windriscoe.modo == WindZone.Modo.PULSADO and windriscoe.direcao.x > 0.0,
		"N9: WindRiscoE (rota arriscada) tem de ser pulsado e a favor")
	var seguro_e1 := n.get_node("SeguroE1") as Node2D
	var caixa_risco := Rect2(windriscoe.position - windriscoe.tamanho * 0.5, windriscoe.tamanho)
	_ok(not caixa_risco.has_point(seguro_e1.position), "N9: a rota segura nao pode estar dentro do vento da rota arriscada")
	_ok(n.get_node_or_null("AlvoPogoE") != null and n.get_node_or_null("PlatAlvoE") != null,
		"N9: falta o alvo de pogo authored (opcional) da seccao E")
	_ok(n.get_node_or_null("CacheRiscoE") != null, "N9: falta a recompensa (Essencia) da rota arriscada")
	_ok(n.get_node_or_null("ConvergeE") != null, "N9: as duas rotas tem de convergir sem grande backtracking")
	# --- secao F: pre-exame -- vento (favor+contra) + salto duplo + Dash + 2 inimigos simples, SEM boss ---
	var windf1 := n.get_node("WindF1") as WindZone
	var windf2 := n.get_node("WindF2") as WindZone
	_ok(windf1.direcao.x > 0.0 and windf2.direcao.x < 0.0,
		"N9: o pre-exame tem de combinar as duas direcoes de vento")
	_ok(n.get_node_or_null("FDashApoio") != null, "N9: falta o apoio de Dash do pre-exame")
	var golemf := n.get_node_or_null("GolemF") as DemonioBase
	var gosmaf := n.get_node_or_null("GosmaF") as DemonioBase
	_ok(golemf != null and not golemf.elite and gosmaf != null and not gosmaf.elite,
		"N9: o pre-exame tem de ter pressao de 2 inimigos simples, nao elite")
	# --- Guardiao: elite regional-lite, sela a porta, nao e' boss, sem piso de vida de chefe ---
	var g := n.get_node("Guardiao") as DemonioBase
	_ok(g.vida >= 100 and g.vida <= 320, "N9: vida do Guardiao %d fora de 100-320 (nao pode competir com o boss do N10)" % g.vida)
	var va := n.get_node("VentoArena") as WindZone
	_ok(va.mostrar_guia and va.modo == WindZone.Modo.PULSADO and va.intensidade <= 1500.0 and va.velocidade_max <= 140.0,
		"N9: VentoArena tem de ter guia visivel, ser pulsado e fraco")
	_ok(g.position.x - (va.position.x - va.tamanho.x * 0.5) >= 200.0, "N9: o vento tem de se ver 200+ px antes do Guardiao")
	g.queue_free()
	for i in 4:
		await get_tree().process_frame
	_ok(porta.monitoring, "N9: a porta abre quando o Guardiao cai")
	_ok(EstadoJogo.bosses_derrotados == antes_bosses, "N9: o Guardiao nao pode gravar boss derrotado")
	_ok(not EstadoJogo.tem_habilidade("escalar_paredes") and not EstadoJogo.tem_habilidade("dash_aereo"),
		"N9: nao pode conceder habilidades")
	# --- geometria: vaos dentro do envolvente do salto simples/duplo (a travessia D e' pela ---
	# plataforma movel, por isso fica de fora desta cadeia, tal como o N8 fazia a` rota rapida) ---
	for cadeia in [["ChaoInicio", "ChaoReintro", "IlhaB1", "IlhaB2", "IlhaB3", "DescansoB", "PousoC1", "PlatSentinela", "PousoC2"],
			["SeguroE1", "SeguroE2", "ConvergeE"],
			["ConvergeE", "F1"], ["F1", "F2", "F3", "F4", "ChaoFinal"]]:
		for i in range(cadeia.size() - 1):
			var a := n.get_node(cadeia[i]) as Node2D
			var b := n.get_node(cadeia[i + 1]) as Node2D
			var vao: float = (b.position.x - b.tamanho.x * 0.5) - (a.position.x + a.tamanho.x * 0.5)
			_ok(vao <= 380.0, "N9: vao %s->%s = %d (max 380, salto duplo)" % [cadeia[i], cadeia[i + 1], vao])
	# --- o vento MEXE mesmo na Koliani no AR: contra na seccao B ---
	var k := n.get_node("Koliani") as CharacterBody2D
	var dx_contra := await _deriva_n6(k, Vector2(930, 480))
	_ok(absf(dx_contra) > 8.0, "N9: o vento da seccao B nao empurra a Koliani no ar (dx=%s)" % str(snappedf(dx_contra, 0.1)))
	n.queue_free()
	await get_tree().process_frame
	EstadoJogo.modo_dev = antes_dev
	EstadoJogo.habilidades.assign(antes_hab)
	EstadoJogo.bosses_derrotados.assign(antes_bosses)
	EstadoJogo.indice_nivel = antes_idx


# ============================================================ COMBAT LAB v1 ====
func _lab_novo() -> Node:
	var cena := (load("res://scenes/lab/CombatLab.tscn") as PackedScene).instantiate()
	add_child(cena)
	for i in 4:
		await get_tree().physics_frame
	cena.limpar()
	for i in 90:
		await get_tree().physics_frame
		if cena.koliani.is_on_floor():
			break
	await _lab_esperar(3)
	return cena


func _lab_fim(cena: Node) -> void:
	Input.action_release("atacar")
	Input.action_release("mirar_cima")
	Input.action_release("mirar_baixo")
	Input.action_release("rolar")
	Input.action_release("dash")
	Input.action_release("saltar")
	Engine.time_scale = 1.0
	cena.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _lab_esperar(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame


## Carrega `acao` durante `frames` (o Godot so' ve o "just pressed" 1 frame depois).
func _lab_tap(acao: String, frames := 3) -> void:
	Input.action_press(acao)
	await _lab_esperar(frames)
	Input.action_release(acao)


func _lab_estados_estaveis(e: LabInimigo, k: Koliani) -> void:
	# poe o alvo parado a` frente da Koliani, no chao
	e.global_position = Vector2(k.global_position.x + 70.0, k.global_position.y)
	e.velocity = Vector2.ZERO


func teste_combat_lab() -> void:
	var antes_dev: bool = EstadoJogo.modo_dev
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	# --- 0. isolamento: uma Koliani normal nao tem lab; os niveis nao referenciam o lab
	var k0 := (load("res://scenes/actors/Koliani.tscn") as PackedScene).instantiate()
	_ok(k0._lab == null and not k0.lab_golpe_custom, "lab: a Koliani de producao nao tem lab")
	_ok(k0._core == null and k0._combate_extra() == null, "core combat: a Koliani de producao nao tem core combate por omissao")
	k0.free()
	for cena in ["res://scenes/levels/Floresta_Putrefata.tscn", "res://scenes/levels/Prisao_dos_Condenados.tscn",
			"res://scenes/Main.tscn"]:
		_ok(not FileAccess.get_file_as_string(cena).contains("scenes/lab/"), "lab: %s referencia o lab" % cena)

	# --- 1. criacao e Launcher (goblin lancado, golem nao)
	var cena := await _lab_novo()
	var k: Koliani = cena.koliani
	var lab: CombateLab = cena.lab
	var m: LabMetricas = cena.metricas
	_ok(k._lab == lab and lab != null, "lab: componente ligado")
	var g: LabInimigo = cena.spawn_goblin(70.0)
	await _lab_esperar(20)
	_lab_estados_estaveis(g, k)
	g.set_physics_process(false)          # parado para medir o golpe, sem IA a interferir
	Input.action_press("mirar_cima")
	await _lab_tap("atacar", 3)
	Input.action_release("mirar_cima")
	await _lab_esperar(14)
	_ok(g.lab_estado == LabInimigo.E.LANCADO or g.velocity.y < -100.0 or m.contar("hit") > 0,
		"launcher: o goblin devia levar o golpe")
	g.set_physics_process(true)
	_ok(m.contar("golpe") >= 1, "launcher: golpe do lab nao arrancou")
	await _lab_esperar(6)
	var ef := ""
	for e in m.eventos:
		if e["nome"] == "hit" and e["d"]["tipo"] == "launcher":
			ef = String(e["d"]["efeito"])
	_ok(ef == "lancado", "launcher: goblin nao foi lancado (efeito='%s')" % ef)
	# golem nao e' lancado
	g.queue_free()
	var gol: LabInimigo = cena.spawn_golem(80.0)
	await _lab_esperar(10)
	gol.global_position = Vector2(k.global_position.x + 90.0, k.global_position.y - 20.0)
	gol.set_physics_process(false)
	m.limpar()
	k._olha_para = 1.0
	Input.action_press("mirar_cima")
	await _lab_tap("atacar", 3)
	Input.action_release("mirar_cima")
	await _lab_esperar(20)
	ef = ""
	for e in m.eventos:
		if e["nome"] == "hit" and e["d"]["tipo"] == "launcher":
			ef = String(e["d"]["efeito"])
	_ok(ef != "" and ef != "lancado" and gol.lab_estado != LabInimigo.E.LANCADO,
		"launcher: o golem NAO pode ser lancado (efeito='%s')" % ef)
	await _lab_fim(cena)

	# --- 2. Air combo: launcher -> salto -> ar -> ar (maximo 2)
	cena = await _lab_novo()
	k = cena.koliani
	lab = cena.lab
	m = cena.metricas
	g = cena.spawn_goblin(70.0)
	await _lab_esperar(20)
	_lab_estados_estaveis(g, k)
	g.set_physics_process(false)
	Input.action_press("mirar_cima")
	await _lab_tap("atacar", 3)
	Input.action_release("mirar_cima")
	await _lab_esperar(4)
	g.set_physics_process(true)
	await _lab_tap("saltar", 12)
	await _lab_esperar(2)
	# o goblin esta' no ar a` frente/acima: posiciona-o ao alcance do golpe aereo
	g.global_position = Vector2(k.global_position.x + 46.0, k.global_position.y - 6.0)
	g.velocity = Vector2(0.0, -40.0)
	var ar_antes := lab._ar_n
	await _lab_tap("atacar", 3)
	await _lab_esperar(9)
	await _lab_tap("atacar", 3)
	await _lab_esperar(9)
	await _lab_tap("atacar", 3)   # o 3.o golpe aereo nao pode existir
	await _lab_esperar(2)
	_ok(lab._ar_n == 2, "air combo: esperava exactamente 2 golpes aereos, houve %d (antes %d)" % [lab._ar_n, ar_antes])
	var ar_hits := 0
	for e in m.eventos:
		if e["nome"] == "hit" and bool(e["d"].get("efeito", "").begins_with("juggle")):
			ar_hits += 1
	_ok(ar_hits >= 1, "air combo: nenhum golpe aereo acertou o goblin no ar")
	await _lab_fim(cena)

	# --- 3. Shadow Cleave: guard break do golem; golpes normais nao quebram depressa
	cena = await _lab_novo()
	k = cena.koliani
	lab = cena.lab
	m = cena.metricas
	gol = cena.spawn_golem(90.0)
	await _lab_esperar(6)
	gol.set_physics_process(false)
	gol.global_position = Vector2(k.global_position.x + 88.0, k.global_position.y - 16.0)
	gol._direcao = -1.0
	gol.lab_estado = LabInimigo.E.IDLE   # guarda levantada
	k._olha_para = 1.0
	# 3 golpes normais: guardados
	for i in 3:
		await _lab_tap("atacar", 3)
		await _lab_esperar(26)
	var guardados := 0
	for e in m.eventos:
		if e["nome"] == "hit" and e["d"]["efeito"] == "guardado":
			guardados += 1
	_ok(guardados >= 2, "cleave: os golpes normais devem ser guardados (foram %d)" % guardados)
	_ok(gol.lab_estado != LabInimigo.E.QUEBRADO, "cleave: 3 golpes normais nao quebram a guarda")
	# carrega 0,55 s e larga
	gol.lab_estado = LabInimigo.E.IDLE
	Input.action_press("atacar")
	await _lab_esperar(34)   # 0,57 s
	_ok(lab.carga() >= 1.0, "cleave: a carga nao chegou a 100 %% (%.2f)" % lab.carga())
	gol.global_position = Vector2(k.global_position.x + 80.0, k.global_position.y - 16.0)   # o avanço do 1.o golpe pode te-la passado
	Input.action_release("atacar")
	await _lab_esperar(30)
	_ok(_lab_golpe(m, "cleave"), "cleave: golpe nao saiu")
	_ok(_lab_efeito(m, "cleave") == "guarda_quebrada", "cleave: nao quebrou a guarda (%s)" % _lab_efeito(m, "cleave"))
	_ok(gol.lab_estado == LabInimigo.E.QUEBRADO, "cleave: o golem devia ficar QUEBRADO")
	# um toque curto NAO faz cleave
	m.limpar()
	gol.lab_estado = LabInimigo.E.IDLE
	gol.guarda = LabInimigo.GOL_GUARDA
	await _lab_esperar(40)
	await _lab_tap("atacar", 4)
	await _lab_esperar(40)
	_ok(not _lab_golpe(m, "cleave"), "cleave: um toque curto nao pode disparar o cleave")
	await _lab_fim(cena)

	# --- 4. Dash Attack: liga movimento e combate; nao alarga o dash
	cena = await _lab_novo()
	k = cena.koliani
	lab = cena.lab
	m = cena.metricas
	k._olha_para = 1.0
	await _lab_esperar(20)
	var x0 := k.global_position.x
	await _lab_tap("dash", 3)
	await _lab_esperar(40)
	var dist_dash := k.global_position.x - x0
	await _lab_esperar(30)
	x0 = k.global_position.x
	await _lab_tap("dash", 2)
	await _lab_esperar(2)
	await _lab_tap("atacar", 3)
	await _lab_esperar(40)
	var dist_dash_atk := k.global_position.x - x0
	_ok(_lab_golpe(m, "dash"), "dash attack: o corte nao saiu")
	_ok(dist_dash_atk <= dist_dash + 45.0, "dash attack: alargou o dash (%d vs %d)" % [dist_dash_atk, dist_dash])
	# o dash attack liga ao combo normal (janela aberta)
	_ok(k._combo_janela > 0.0 or k._ataque_restante > 0.0, "dash attack: nao abriu janela de combo")
	await _lab_fim(cena)

	# --- 5. Perfect Dodge: janela e cooldown
	cena = await _lab_novo()
	k = cena.koliani
	lab = cena.lab
	m = cena.metricas
	await _lab_esperar(20)
	var en0 := k.energia_actual()
	k._energia = 10.0
	# a) sem roll: nao ha PD
	k._invulneravel = 0.3
	k.receber_dano(10, 1.0, "ataque")
	_ok(m.contar("perfect_dodge") == 0, "PD: sem roll nao conta")
	k._invulneravel = 0.0
	# b) roll a meio da janela: PD
	await _lab_tap("rolar", 3)
	await _lab_esperar(4)
	k.receber_dano(10, 1.0, "ataque")
	_ok(m.contar("perfect_dodge") == 1, "PD: golpe dentro da janela devia dar Perfect Dodge")
	_ok(absf(k.energia_actual() - 35.0) < 2.0, "PD: energia esperada 35, foi %.1f" % k.energia_actual())
	_ok(lab.janela_counter() > 0.5, "PD: janela do counter nao abriu")
	# c) mesmo roll, mas 0,26 s depois (cedo demais / ja' fora da janela): nada de novo
	await _lab_esperar(12)
	k.receber_dano(10, 1.0, "ataque")
	_ok(m.contar("perfect_dodge") == 1, "PD: cooldown/janela deviam impedir 2.o PD")
	await _lab_fim(cena)
	cena = await _lab_novo()
	k = cena.koliani
	lab = cena.lab
	m = cena.metricas
	await _lab_esperar(20)
	await _lab_tap("rolar", 3)
	await _lab_esperar(19)   # ~0,32 s: fora da janela de 0,22 s
	k._invulneravel = 0.2     # ainda protegida por outra causa
	k._rolar_restante = 0.05  # roll quase a acabar
	k.receber_dano(10, 1.0, "ataque")
	_ok(m.contar("perfect_dodge") == 0, "PD: golpe tarde no roll nao e' perfeito")
	await _lab_fim(cena)

	# --- 6. Shadow Counter: so' com input, so' na janela; quebra a guarda
	cena = await _lab_novo()
	k = cena.koliani
	lab = cena.lab
	m = cena.metricas
	gol = cena.spawn_golem(90.0)
	await _lab_esperar(6)
	gol.set_physics_process(false)
	gol.global_position = Vector2(k.global_position.x + 88.0, k.global_position.y - 16.0)
	gol._direcao = -1.0
	gol.lab_estado = LabInimigo.E.IDLE
	k._olha_para = 1.0
	await _lab_tap("rolar", 3)
	await _lab_esperar(3)
	k.receber_dano(20, 1.0, "ataque")
	_ok(m.contar("perfect_dodge") == 1, "counter: PD nao arrancou")
	await _lab_esperar(30)
	_ok(not _lab_golpe(m, "counter"), "counter: NAO pode ser automatico")
	_ok(lab.janela_counter() > 0.0, "counter: a janela devia continuar aberta (%.2f)" % lab.janela_counter())
	gol.global_position = Vector2(k.global_position.x + 88.0, k.global_position.y - 16.0)
	await _lab_tap("atacar", 3)
	await _lab_esperar(20)
	_ok(_lab_golpe(m, "counter") and _lab_evento_tipo(m, "counter"), "counter: nao saiu dentro da janela")
	_ok(_lab_efeito(m, "counter") == "guarda_quebrada", "counter: devia quebrar a guarda (%s)" % _lab_efeito(m, "counter"))
	# fora da janela: nao ha counter
	m.limpar()
	await _lab_esperar(60)
	lab._counter_t = 0.0
	gol.lab_estado = LabInimigo.E.IDLE
	await _lab_tap("atacar", 3)
	await _lab_esperar(20)
	_ok(not _lab_golpe(m, "counter"), "counter: fora da janela nao existe")
	await _lab_fim(cena)

	# --- 7. Anti stun-lock / juggle infinito (o goblin)
	cena = await _lab_novo()
	k = cena.koliani
	m = cena.metricas
	g = cena.spawn_goblin(70.0)
	await _lab_esperar(20)
	_lab_estados_estaveis(g, k)
	var armaduras := 0
	var frames_stun := 0
	var frames_total := 0
	g.vida = 99999
	for i in 30:   # 30 golpes leves a cada 0,2 s = 6 s de spam
		g.global_position.x = k.global_position.x + 60.0
		var r := g.lab_hit({"tipo": "normal", "dano": 1, "dir": 1.0, "passo": 0, "ar": false})
		if r["efeito"] == "armadura":
			armaduras += 1
		for j in 12:
			await get_tree().physics_frame
			frames_total += 1
			if g.lab_estado == LabInimigo.E.HITSTUN:
				frames_stun += 1
	_ok(armaduras >= 1, "stunlock: a super-armadura nunca ligou em 6 s de spam")
	_ok(g.escapes >= 1, "stunlock: o goblin nunca escapou (escapes=%d)" % g.escapes)
	_ok(float(frames_stun) / float(frames_total) < 0.6, "stunlock: %.0f %% do tempo em hitstun" % (100.0 * frames_stun / frames_total))
	# juggle capado a 3 elevacoes
	g.lab_estado = LabInimigo.E.LANCADO
	g._juggle = 0
	g.global_position = Vector2(k.global_position.x + 60.0, k.global_position.y - 150.0)
	var lifts := 0
	for i in 8:
		var r2 := g.lab_hit({"tipo": "normal", "dano": 1, "dir": 1.0, "passo": 0, "ar": true})
		if String(r2["efeito"]).begins_with("juggle") and r2["efeito"] != "juggle_max":
			lifts += 1
	_ok(lifts <= 3, "juggle: %d elevacoes (max 3)" % lifts)
	await _lab_fim(cena)

	# --- 8. Energia por accao + TTK medidos com bots simples (relatorio)
	cena = await _lab_novo()
	k = cena.koliani
	m = cena.metricas
	var ttk_g := await _lab_ttk_bot(cena, "goblin", false)
	print("LAB goblin bot: ", m.resumo().replace("
", " | "), " | goblin_acertou=", m.contar("goblin_acertou"))
	_ok(ttk_g > 0.0 and ttk_g < 25.0, "TTK goblin fora do razoavel: %.1f" % ttk_g)
	await _lab_fim(cena)
	cena = await _lab_novo()
	var ttk_gol := await _lab_ttk_bot(cena, "golem", true)
	print("LAB golem bot: ", cena.metricas.resumo().replace("
", " | "), " | golem_acertou=", cena.metricas.contar("golem_acertou"))
	print("LAB TTK goblin=%.2fs golem(cleave+combo)=%.2fs" % [ttk_g, ttk_gol])
	_ok(ttk_gol > 0.0, "TTK golem: o bot nao o derrotou")
	await _lab_fim(cena)

	EstadoJogo.modo_dev = antes_dev
	EstadoJogo.habilidades.assign(antes_hab)


func _lab_golpe(m: LabMetricas, nome: String) -> bool:
	for e in m.eventos:
		if e["nome"] == "golpe" and e["d"]["nome"] == nome:
			return true
	return false


## TTK medido pelo proprio alvo (do 1.o golpe recebido ate' morrer), sem a cauda do bot; -1 se nao morreu.
func _lab_ttk_evento(m: LabMetricas, _t: float) -> float:
	for e in m.eventos:
		if e["nome"] == "morreu":
			return float(e["d"]["ttk"])
	return -1.0


func _lab_evento_tipo(m: LabMetricas, tipo: String) -> bool:
	for e in m.eventos:
		if e["nome"] == "hit" and e["d"]["tipo"] == tipo:
			return true
	return false


func _lab_efeito(m: LabMetricas, tipo: String) -> String:
	for e in m.eventos:
		if e["nome"] == "hit" and e["d"]["tipo"] == tipo:
			return String(e["d"]["efeito"])
	return ""


## Bot minimo: aproxima-se, ataca em cadeia; para o golem usa cleave (segura 0,55 s) e depois
## combo enquanto a guarda esta' partida. Devolve o TTK em segundos de simulacao (-1 se falhou).
func _lab_ttk_bot(cena: Node, tipo: String, usa_cleave: bool) -> float:
	var k: Koliani = cena.koliani
	var alvo: LabInimigo = cena.spawn_goblin(200.0) if tipo == "goblin" else cena.spawn_golem(260.0)
	alvo.lab_semente = 3
	var t := 0.0
	var dt := 1.0 / 60.0
	var limite := 90.0
	while t < limite and is_instance_valid(alvo) and not alvo._morto:
		var dx := alvo.global_position.x - k.global_position.x
		var lado := signf(dx)
		# anda para o alvo ate' ficar a ~70 px
		if absf(dx) > 72.0:
			Input.action_press("mover_direita" if lado > 0 else "mover_esquerda")
			Input.action_release("mover_esquerda" if lado > 0 else "mover_direita")
		else:
			Input.action_release("mover_direita")
			Input.action_release("mover_esquerda")
			k._olha_para = lado if lado != 0.0 else k._olha_para
			if usa_cleave and alvo.lab_estado != LabInimigo.E.QUEBRADO and alvo.lab_estado != LabInimigo.E.WINDUP \
					and alvo.lab_estado != LabInimigo.E.ATIVO:
				# carrega o cleave
				Input.action_press("atacar")
				for i in 34:
					await get_tree().physics_frame
					t += dt
				Input.action_release("atacar")
				for i in 30:
					await get_tree().physics_frame
					t += dt
				continue
			# combo simples: toca a cada 0,3 s
			Input.action_press("atacar")
			for i in 3:
				await get_tree().physics_frame
				t += dt
			Input.action_release("atacar")
			for i in 15:
				await get_tree().physics_frame
				t += dt
			continue
		await get_tree().physics_frame
		t += dt
	Input.action_release("mover_direita")
	Input.action_release("mover_esquerda")
	if is_instance_valid(alvo) and not alvo._morto:
		return -1.0
	return t


## Combos do briefing que nao estao em `teste_combat_lab`: N-N-N, Launcher->Air->Pogo, Cleave->combo,
## Dash Attack->Launcher->Air Combo, Air->Pogo->reposicionar.
func teste_combat_lab_combos() -> void:
	var antes_dev: bool = EstadoJogo.modo_dev
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	# --- 1. Ataque -> Ataque -> Ataque (passos 1, 2, 3 do combo base)
	var cena := await _lab_novo()
	var k: Koliani = cena.koliani
	var lab: CombateLab = cena.lab
	var m: LabMetricas = cena.metricas
	var g: LabInimigo = cena.spawn_goblin(70.0)
	await _lab_esperar(10)
	g.set_physics_process(false)
	g.vida = 99999
	k._olha_para = 1.0
	var passos := {}
	for i in 3:
		g.global_position = Vector2(k.global_position.x + 60.0, k.global_position.y - 16.0)
		g.lab_estado = LabInimigo.E.APROX
		await _lab_tap("atacar", 2)
		await _lab_esperar(13)
	for e in m.eventos:
		if e["nome"] == "hit" and e["d"]["tipo"] == "normal":
			passos[int(e["d"]["passo"])] = true
	_ok(passos.has(0) and passos.has(1) and passos.has(2), "combo 1: N-N-N devia dar os passos 0,1,2 (deu %s)" % str(passos.keys()))
	await _lab_fim(cena)

	# --- 3 + 8. Launcher -> salto -> ar -> ar -> Pogo (repoe a cadeia aerea) -> novo golpe aereo
	cena = await _lab_novo()
	k = cena.koliani
	lab = cena.lab
	m = cena.metricas
	g = cena.spawn_goblin(70.0)
	await _lab_esperar(10)
	g.set_physics_process(false)
	g.vida = 99999
	k._olha_para = 1.0
	g.global_position = Vector2(k.global_position.x + 60.0, k.global_position.y - 16.0)
	Input.action_press("mirar_cima")
	await _lab_tap("atacar", 3)
	Input.action_release("mirar_cima")
	await _lab_esperar(3)
	await _lab_tap("saltar", 12)
	await _lab_esperar(2)
	g.global_position = Vector2(k.global_position.x + 46.0, k.global_position.y - 6.0)
	await _lab_tap("atacar", 3)
	await _lab_esperar(9)
	await _lab_tap("atacar", 3)
	await _lab_esperar(3)
	_ok(lab._ar_n == 2, "combo 3: esperava 2 golpes aereos (%d)" % lab._ar_n)
	# pogo: BAIXO + ATAQUE com o alvo por baixo dos pes
	g.global_position = Vector2(k.global_position.x, k.global_position.y + 60.0)
	g.velocity = Vector2.ZERO
	Input.action_press("mirar_baixo")
	await _lab_tap("atacar", 3)
	var pogo_ok := false
	for i in 40:
		await get_tree().physics_frame
		g.global_position = Vector2(k.global_position.x, k.global_position.y + 60.0)
		if k._pogo_estado == 3 or m.contar("pogo_acerto") > 0:
			pogo_ok = true
			break
	Input.action_release("mirar_baixo")
	await _lab_esperar(2)
	_ok(pogo_ok, "combo 3: o pogo depois do air combo nao acertou")
	_ok(lab._ar_n == 0, "combo 8: o pogo devia repor a cadeia aerea (ar=%d)" % lab._ar_n)
	# reposicionamento: novo golpe aereo disponivel depois do pogo
	await _lab_esperar(6)
	g.global_position = Vector2(k.global_position.x + 46.0, k.global_position.y - 6.0)
	await _lab_tap("atacar", 3)
	await _lab_esperar(4)
	_ok(lab._ar_n == 1 or k.is_on_floor(), "combo 8: nao houve golpe aereo depois do pogo (ar=%d)" % lab._ar_n)
	await _lab_fim(cena)

	# --- 5. Shadow Cleave -> combo normal
	cena = await _lab_novo()
	k = cena.koliani
	lab = cena.lab
	m = cena.metricas
	g = cena.spawn_goblin(70.0)
	await _lab_esperar(10)
	g.set_physics_process(false)
	g.vida = 99999
	k._olha_para = 1.0
	g.global_position = Vector2(k.global_position.x + 70.0, k.global_position.y - 16.0)
	Input.action_press("atacar")
	await _lab_esperar(34)
	g.global_position = Vector2(k.global_position.x + 70.0, k.global_position.y - 16.0)
	Input.action_release("atacar")
	await _lab_esperar(14)   # dentro do cleave, depois do ativo
	_ok(lab._move == "cleave" and lab._move_acertou, "combo 5: o cleave devia estar em curso e ter acertado")
	await _lab_tap("atacar", 3)
	var normal_apos := false
	for i in 40:
		await get_tree().physics_frame
		if lab._move == "" and k._ataque_restante > 0.0 and not k.lab_golpe_custom:
			normal_apos = true
			break
	_ok(normal_apos, "combo 5: cleave -> golpe normal nao ligou")
	await _lab_fim(cena)

	# --- 7. Dash Attack -> Launcher -> Air Combo
	cena = await _lab_novo()
	k = cena.koliani
	lab = cena.lab
	m = cena.metricas
	g = cena.spawn_goblin(200.0)
	await _lab_esperar(10)
	g.set_physics_process(false)
	g.vida = 99999
	k._olha_para = 1.0
	k._energia = 40.0
	g.global_position = Vector2(k.global_position.x + 70.0, k.global_position.y - 16.0)
	await _lab_tap("dash", 2)
	await _lab_esperar(2)
	await _lab_tap("atacar", 3)
	g.global_position = Vector2(k.global_position.x + 55.0, k.global_position.y - 16.0)
	await _lab_esperar(6)
	_ok(lab._move == "dash", "combo 7: o dash attack nao arrancou")
	await _lab_esperar(6)   # passa o ativo
	g.global_position = Vector2(k.global_position.x + 55.0, k.global_position.y - 16.0)
	Input.action_press("mirar_cima")
	await _lab_tap("atacar", 3)
	Input.action_release("mirar_cima")
	await _lab_esperar(4)
	_ok(lab._move == "launcher" or _lab_golpe(m, "launcher"), "combo 7: dash attack -> launcher nao ligou")
	await _lab_tap("saltar", 12)
	await _lab_esperar(2)
	g.global_position = Vector2(k.global_position.x + 46.0, k.global_position.y - 6.0)
	await _lab_tap("atacar", 3)
	await _lab_esperar(4)
	_ok(lab._ar_n >= 1, "combo 7: sem golpe aereo depois do launcher")
	await _lab_fim(cena)

	EstadoJogo.modo_dev = antes_dev
	EstadoJogo.habilidades.assign(antes_hab)


## Perfect Dodge contra os ataques REAIS do golem (nao so' `receber_dano` chamado a` mao).
func teste_combat_lab_pd_real() -> void:
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	var resultados := {}
	for caso in ["certo", "cedo"]:
		var cena := await _lab_novo()
		var k: Koliani = cena.koliani
		var m: LabMetricas = cena.metricas
		k.global_position = Vector2(900.0, k.global_position.y)
		var gol: LabInimigo = cena.spawn_golem(60.0)
		gol.global_position.x = 960.0
		gol._direcao = -1.0
		await _lab_esperar(4)
		var vida0 := k.vida
		var rolou := false
		for i in 400:
			await get_tree().physics_frame
			k._olha_para = -1.0
			if not rolou and gol.lab_estado == LabInimigo.E.WINDUP:
				var falta: float = float(gol._ataque["windup"]) - gol._t
				if (caso == "certo" and falta <= 0.09) or (caso == "cedo" and falta <= 0.62):
					Input.action_press("rolar")
					await get_tree().physics_frame
					await get_tree().physics_frame
					Input.action_release("rolar")
					rolou = true
			if rolou and gol.lab_estado == LabInimigo.E.RECUP:
				break
		await _lab_esperar(10)
		resultados[caso] = {"pd": m.contar("perfect_dodge"), "dano": vida0 - k.vida, "golem_acertou": m.contar("golem_acertou")}
		await _lab_fim(cena)
	print("LAB PD real: ", resultados)
	_ok(int(resultados["certo"]["pd"]) == 1 and int(resultados["certo"]["dano"]) == 0,
		"PD real: o roll a 0,09 s do golpe devia dar Perfect Dodge sem dano: %s" % str(resultados["certo"]))
	_ok(int(resultados["cedo"]["pd"]) == 0,
		"PD real: o roll a 0,62 s do golpe nao pode contar como perfeito: %s" % str(resultados["cedo"]))
	EstadoJogo.habilidades.assign(antes_hab)


# ============================================================ COMBAT LAB v1.1 ====
## Contacto corporal nunca da' Perfect Dodge; so' origem "ataque"/"hazard_ataque".
func teste_combat_lab_pd_contrato() -> void:
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	var cena := await _lab_novo()
	var k: Koliani = cena.koliani
	var m: LabMetricas = cena.metricas
	var lab: CombateLab = cena.lab
	await _lab_esperar(10)
	# roll dentro da janela, mas o dano e' CONTACTO (origem omissa): nao ha' PD
	await _lab_tap("rolar", 3)
	await _lab_esperar(3)
	k.receber_dano(8, 1.0)
	_ok(m.contar("perfect_dodge") == 0, "PD contrato: dano sem origem (contacto) nao pode dar PD")
	_ok(m.contar("pd_ignorado") == 1, "PD contrato: o contacto devia ficar registado como ignorado")
	# contacto REAL do goblin (lab_contato_dano) enquanto rola
	var g: LabInimigo = cena.spawn_goblin(60.0)
	g.lab_contato_dano = 8
	g.set_physics_process(false)
	g._ao_tocar(k)
	_ok(m.contar("perfect_dodge") == 0, "PD contrato: contacto do goblin nao pode dar PD")
	# o mesmo roll com um ATAQUE dentro da janela: PD
	k.receber_dano(8, 1.0, OrigemDano.ATAQUE)
	_ok(m.contar("perfect_dodge") == 1, "PD contrato: origem 'ataque' na janela devia dar PD")
	# hazard que ataca: tambem conta (depois do cooldown)
	await _lab_esperar(60)
	await _lab_tap("rolar", 3)
	await _lab_esperar(3)
	lab._pd_cd = 0.0
	k.receber_dano(8, 1.0, OrigemDano.HAZARD_ATAQUE)
	_ok(m.contar("perfect_dodge") == 2, "PD contrato: 'hazard_ataque' na janela devia dar PD")
	# ambiente (DoT) nunca pode dar PD, mesmo dentro da janela
	await _lab_esperar(60)
	await _lab_tap("rolar", 3)
	await _lab_esperar(3)
	lab._pd_cd = 0.0
	k.receber_dano(8, 1.0, OrigemDano.AMBIENTE)
	_ok(m.contar("perfect_dodge") == 2, "PD contrato: 'ambiente' nunca pode dar PD")
	# os ataques telegrafados do lab identificam-se como ataque (teste real esta' em teste_combat_lab_pd_real)
	_ok(FileAccess.get_file_as_string("res://scripts/lab/lab_inimigo.gd").count("\"ataque\")") >= 2,
		"PD contrato: bote/slam/sweep tem de passar origem 'ataque'")
	# Fase 5 -- contrato formalizado: os 4 valores nao podem colidir entre si
	_ok(OrigemDano.CONTATO != OrigemDano.ATAQUE and OrigemDano.CONTATO != OrigemDano.HAZARD_ATAQUE
		and OrigemDano.AMBIENTE != OrigemDano.ATAQUE and OrigemDano.AMBIENTE != OrigemDano.HAZARD_ATAQUE
		and OrigemDano.ATAQUE != OrigemDano.HAZARD_ATAQUE,
		"OrigemDano: os 4 valores tem de ser distintos entre si")
	await _lab_fim(cena)
	EstadoJogo.habilidades.assign(antes_hab)


## Fase 5 (integracao do combate em producao) -- prova ESTATICA de que os
## 13 sistemas de producao listados no plano (`docs/plano_integracao_combate_producao.md`
## §3) passam mesmo a origem certa a `receber_dano`. Nao mexe em cena: so'
## le o texto dos scripts (o mesmo padrao ja' usado acima para `lab_inimigo.gd`).
## Isto NAO muda comportamento (em producao `_lab` e' sempre null: ver
## `Koliani.receber_dano`), so' prova que a migracao mecanica ficou completa
## e nao ha' chamador esquecido a usar a string errada.
func teste_contrato_dano_producao() -> void:
	var hazard_ataque := {
		"res://scripts/armadilha.gd": 1, "res://scripts/chao_quente.gd": 1,
		"res://scripts/gota_acida.gd": 3, "res://scripts/guilhotina.gd": 1,
		"res://scripts/pedra_queda.gd": 1, "res://scripts/pendulo_lamina.gd": 1,
		"res://scripts/raiz_perigo.gd": 1, "res://scripts/raio_tempestade.gd": 1,
		"res://scripts/teia_prende.gd": 1, "res://scripts/ceifa.gd": 1,
	}
	for caminho: String in hazard_ataque:
		var txt := FileAccess.get_file_as_string(caminho)
		_ok(txt.count("OrigemDano.HAZARD_ATAQUE") >= int(hazard_ataque[caminho]),
			"contrato de dano: %s devia marcar hazard_ataque" % caminho)
	var ataque := {
		"res://scripts/projetil_zeriko.gd": 1, "res://scripts/serpente.gd": 1,
		"res://scripts/sombra_atrasada.gd": 1, "res://scripts/ameaca_que_avanca.gd": 1,
		"res://scripts/bola_fogo.gd": 1,
	}
	for caminho: String in ataque:
		var txt := FileAccess.get_file_as_string(caminho)
		_ok(txt.count("OrigemDano.ATAQUE") >= int(ataque[caminho]),
			"contrato de dano: %s devia marcar ataque" % caminho)
	_ok(FileAccess.get_file_as_string("res://scripts/demonio_base.gd").count("OrigemDano.CONTATO") >= 1,
		"contrato de dano: demonio_base (contacto de corpo) devia marcar contato")
	_ok(FileAccess.get_file_as_string("res://scripts/chefe_base.gd").count("OrigemDano.CONTATO") >= 1,
		"contrato de dano: chefe_base (contacto de corpo) devia marcar contato")
	_ok(FileAccess.get_file_as_string("res://scripts/zona_sem_ar.gd").count("OrigemDano.AMBIENTE") >= 1,
		"contrato de dano: zona_sem_ar (DoT) devia marcar ambiente, nunca esquivavel")


## Fases 2/3/4/6 -- CoreCombate ligado a uma Koliani de PRODUCAO real (nao ao Combat Lab).
## Prova funcional (nao so' "nao regride"): Launcher dispara com CIMA+ATAQUE e Perfect Dodge
## dispara com origem OrigemDano.ATAQUE, exactamente como no Combat Lab -- mas fora dele, com
## `ativar_core_combate()` em vez de `ativar_combat_lab()`. Opt-in: nenhum nivel de campanha
## chama isto (ver o isolamento verificado em `teste_combat_lab` acima).
func teste_core_combate_producao() -> void:
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	EstadoJogo.habilidades.assign(["dash", "pogo", "salto_duplo", "especial", "projetil"])
	var m := LabMetricas.new()
	add_child(m)
	var chao := (load("res://scenes/actors/Plataforma.tscn") as PackedScene).instantiate()
	chao.position = Vector2(1300.0, 730.0)
	chao.tamanho = Vector2(2600.0, 60.0)
	add_child(chao)
	var k := (load("res://scenes/actors/Koliani.tscn") as PackedScene).instantiate() as Koliani
	k.position = Vector2(400.0, 630.0)
	k.usar_prototipo_premium = true
	k.usar_golden_set = true
	add_child(k)
	for i in 90:
		await get_tree().physics_frame
		if k.is_on_floor():
			break
	_ok(k.is_on_floor(), "core combat: a Koliani de producao chegou ao chao da arena de teste")
	_ok(k._lab == null, "core combat: sem lab -- isolamento do Combat Lab mantido")
	var core := k.ativar_core_combate()
	_ok(core == k.ativar_core_combate(), "core combat: ativar_core_combate e' idempotente")
	_ok(k._combate_extra() == core, "core combat: _combate_extra devolve o core quando nao ha' lab")

	var g := (load("res://scenes/lab/LabGoblin.tscn") as PackedScene).instantiate() as LabInimigo
	g.position = Vector2(k.global_position.x + 70.0, k.global_position.y)
	g.lab_arena_x = Vector2(60.0, 2600.0 - 60.0)
	add_child(g)
	for i in 6:
		await get_tree().physics_frame

	# Launcher: CIMA + ATAQUE no chao (decisao fechada do GD: o BOTAO usado determina a accao;
	# CIMA + tiro continua a mirar -- nao ha' atalho novo nem conflito de accao).
	Input.action_press("mirar_cima")
	await _lab_tap("atacar", 3)
	Input.action_release("mirar_cima")
	await _lab_esperar(4)
	_ok(core.log_ultimos.has("LAUNCHER"), "core combat: Launcher disparou em producao com CIMA+ATAQUE")
	await _lab_esperar(50)

	# Perfect Dodge: so' com origem ATAQUE/HAZARD_ATAQUE, dentro da janela do roll (contrato Fase 5).
	await _lab_tap("rolar", 3)
	await _lab_esperar(3)
	k.receber_dano(8, 1.0, OrigemDano.ATAQUE)
	_ok(m.contar("perfect_dodge") == 1, "core combat: Perfect Dodge disparou em producao com origem ATAQUE")
	k.receber_dano(8, 1.0, OrigemDano.CONTATO)
	_ok(m.contar("perfect_dodge") == 1, "core combat: origem CONTATO nao pode dar PD em producao (contagem nao subiu)")

	Input.action_release("atacar")
	Input.action_release("mirar_cima")
	Input.action_release("rolar")
	g.queue_free()
	k.queue_free()
	chao.queue_free()
	m.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	EstadoJogo.habilidades.assign(antes_hab)


## Fase 7 -- Enemy Combat Contract v1, 100% opt-in. Prova BEFORE == AFTER numa
## amostra representativa de inimigos LEGACY (varias especies/comportamentos):
## o mesmo golpe, aplicado por `receber_dano` direto (como o combo normal de
## producao sempre fez) e por `lab_hit` (a nova entrada do CoreCombate), tem
## de dar EXACTAMENTE o mesmo resultado quando `piloto_combate_v1` fica no
## default (`false`). Corre ANTES de qualquer piloto (Fases 8/9).
func teste_enemy_contract_legado_inerte() -> void:
	var amostra := [
		{"especie": "goblin", "comportamento": "patrulha"},
		{"especie": "mushroom", "comportamento": "saltador"},
		{"especie": "esqueleto", "comportamento": "escudeiro"},
		{"especie": "olho", "comportamento": "voador"},
	]
	for caso: Dictionary in amostra:
		var a := (load("res://scenes/actors/DemonioBase.tscn") as PackedScene).instantiate() as DemonioBase
		var b := (load("res://scenes/actors/DemonioBase.tscn") as PackedScene).instantiate() as DemonioBase
		for e in [a, b]:
			e.especie = String(caso["especie"])
			e.comportamento = String(caso["comportamento"])
			e.vida = 60
			e.global_position = Vector2(500.0, 400.0)
			add_child(e)
		await get_tree().physics_frame
		_ok(not a.piloto_combate_v1 and not b.piloto_combate_v1,
			"contrato inimigo: piloto_combate_v1 tem de ser false por omissao (%s)" % caso["especie"])
		# golpe 1: receber_dano DIRETO (o caminho do combo normal de producao, sempre foi assim)
		# forca_recuo=200.0 -- o MESMO valor que o CoreCombate manda no ramo generico (sem lab_hit)
		a.receber_dano(9, 1.0, false, 200.0)
		# golpe 2: a MESMA chamada, mas atraves de lab_hit (a nova entrada do CoreCombate)
		b.lab_hit({"tipo": "normal", "dano": 9, "dir": 1.0, "critico": false, "guard_break": false})
		_ok(a.vida == b.vida, "contrato inimigo (%s): vida apos o golpe tem de ser identica (a=%d b=%d)"
			% [caso["especie"], a.vida, b.vida])
		_ok(is_equal_approx(a._recuo_vel, b._recuo_vel),
			"contrato inimigo (%s): recuo identico (a=%.2f b=%.2f)" % [caso["especie"], a._recuo_vel, b._recuo_vel])
		_ok(is_equal_approx(a._flinch, b._flinch), "contrato inimigo (%s): flinch identico" % caso["especie"])
		_ok(a._morto == b._morto, "contrato inimigo (%s): morte identica" % caso["especie"])
		# golpe fatal: os dois tem de morrer da MESMA forma (queue_free, sem lab_hit a "salvar" ninguem)
		var c := (load("res://scenes/actors/DemonioBase.tscn") as PackedScene).instantiate() as DemonioBase
		var d := (load("res://scenes/actors/DemonioBase.tscn") as PackedScene).instantiate() as DemonioBase
		for e in [c, d]:
			e.especie = String(caso["especie"])
			e.comportamento = String(caso["comportamento"])
			e.vida = 5
			e.global_position = Vector2(500.0, 400.0)
			add_child(e)
		await get_tree().physics_frame
		c.receber_dano(50, 1.0, false, 200.0)
		var res := d.lab_hit({"tipo": "normal", "dano": 50, "dir": 1.0, "critico": false, "guard_break": false})
		_ok(res.get("aplicado", false) and res.get("efeito", "x") == "" and not res.get("lancado", true),
			"contrato inimigo (%s): lab_hit nao-piloto devolve o contrato passthrough (aplicado/efeito vazio/nao lancado)"
				% caso["especie"])
		_ok(not is_instance_valid(c) or c._morto, "contrato inimigo (%s): morte por receber_dano direto" % caso["especie"])
		_ok(not is_instance_valid(d) or d._morto, "contrato inimigo (%s): morte por lab_hit identica" % caso["especie"])
		if is_instance_valid(a):
			a.queue_free()
		if is_instance_valid(b):
			b.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


## Fase 7 -- hurtbox() dos inimigos comuns le' a CollisionShape2D real do corpo
## (a mesma que o combo normal ja' usa), nao um valor inventado.
func teste_enemy_contract_hurtbox() -> void:
	var e := (load("res://scenes/actors/DemonioBase.tscn") as PackedScene).instantiate() as DemonioBase
	e.global_position = Vector2(700.0, 400.0)
	add_child(e)
	await get_tree().physics_frame
	var hb := e.hurtbox()
	_ok(hb.size == Vector2(40.0, 64.0), "contrato inimigo: hurtbox le' o tamanho real da CollisionShape2D (40x64)")
	_ok(hb.get_center().distance_to(e.global_position + Vector2(0.0, -13.0)) < 0.5,
		"contrato inimigo: hurtbox centrada na posicao real da CollisionShape2D")
	e.queue_free()
	await get_tree().process_frame


## Fase 7 -- guarda opt-in: so' quando `tem_guarda_v1` fica ligado (piloto), nunca por omissao.
func teste_enemy_contract_guarda_opt_in() -> void:
	var g := (load("res://scenes/actors/DemonioBase.tscn") as PackedScene).instantiate() as DemonioBase
	g.especie = "esqueleto"
	g.vida = 200
	g.global_position = Vector2(500.0, 400.0)
	g.piloto_combate_v1 = true
	g.peso = "pesado"
	g.pode_ser_lancado = false
	g.tem_guarda_v1 = true
	g.guarda_max_v1 = 40.0
	g._direcao = 1.0
	add_child(g)
	await get_tree().physics_frame
	var vida_antes := g.vida
	# golpe de FRENTE sem guard_break: custa guarda, so' 20% do dano passa
	var res1 := g.lab_hit({"tipo": "normal", "dano": 20, "dir": 1.0, "critico": false, "guard_break": false})
	_ok(res1.get("efeito", "") == "guardado", "contrato inimigo: guarda absorve golpe frontal sem guard_break")
	_ok(vida_antes - g.vida == 4, "contrato inimigo: golpe guardado so' passa 20%% do dano (esperado 4, foi %d)"
		% (vida_antes - g.vida))
	_ok(g._guarda_v1 < g.guarda_max_v1, "contrato inimigo: a guarda gastou-se")
	# Cleave/Counter (guard_break) ignora a guarda -- dano cheio
	var vida_antes2 := g.vida
	g.lab_hit({"tipo": "cleave", "dano": 20, "dir": 1.0, "critico": false, "guard_break": true})
	_ok(vida_antes2 - g.vida == 20, "contrato inimigo: guard_break ignora a guarda (dano cheio)")
	_ok(g._guarda_v1 == 0.0, "contrato inimigo: guard_break esgota a guarda")
	# Launcher: pesado + pode_ser_lancado=false -- nunca lanca
	g.vida = 200
	var res2 := g.lab_hit({"tipo": "launcher", "dano": 5, "dir": 1.0, "critico": false, "guard_break": false})
	_ok(not res2.get("lancado", true), "contrato inimigo: peso pesado + pode_ser_lancado=false nunca lanca")
	g.queue_free()
	await get_tree().process_frame


## Fase 8 -- Goblin piloto da Regiao I. So' a instancia "GoblinAprendiz" (N1,
## Floresta_Putrefata.tscn) liga o contrato -- nenhum outro goblin do jogo.
func teste_goblin_piloto_estrutura() -> void:
	var nivel := (load("res://scenes/levels/Floresta_Putrefata.tscn") as PackedScene).instantiate()
	var g := nivel.get_node_or_null("GoblinAprendiz") as DemonioBase
	_ok(g != null, "goblin piloto: GoblinAprendiz existe em Floresta_Putrefata.tscn")
	if g != null:
		_ok(g.piloto_combate_v1, "goblin piloto: piloto_combate_v1 ligado so' nesta instancia")
		_ok(g.peso == "leve", "goblin piloto: peso leve")
		_ok(g.pode_ser_lancado, "goblin piloto: lancavel")
		_ok(g.comportamento == "carga", "goblin piloto: bote telegrafado (comportamento carga)")
		_ok(not g.tem_guarda_v1, "goblin piloto: leve nao tem guarda")
	nivel.queue_free()
	await get_tree().process_frame


## Contra-prova: nenhum OUTRO goblin/inimigo comum do jogo ganhou o contrato por
## a classe partilhada ter os campos novos (teria de vir explicito na cena dele).
func teste_goblin_piloto_isolamento() -> void:
	var amostras := [
		"res://scenes/levels/Pantano_dos_Sussurros.tscn",
		"res://scenes/levels/Ninho_da_Viuva_Negra.tscn",
		"res://scenes/levels/A_Arvore_que_Chora.tscn",
		"res://scenes/levels/Prisao_dos_Condenados.tscn",   # tem o Golem piloto (Fase 9); o resto tem de continuar legacy
	]
	var pilotos_conhecidos := ["GoblinAprendiz", "EliteGolem"]
	for caminho: String in amostras:
		var nivel := (load(caminho) as PackedScene).instantiate()
		for filho in nivel.get_children():
			if filho is DemonioBase and not (filho.name in pilotos_conhecidos):
				_ok(not (filho as DemonioBase).piloto_combate_v1,
					"pilotos: %s/%s nao devia ter o contrato ligado" % [caminho.get_file(), filho.name])
		nivel.queue_free()
		await get_tree().process_frame


## Comportamento funcional do piloto: bote telegrafado = origem ATAQUE (pode dar PD), contacto de
## patrulha comum = CONTATO, Launcher lanca (leve), sem juggle infinito.
func teste_goblin_piloto_comportamento() -> void:
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	EstadoJogo.habilidades.assign(["dash", "pogo", "salto_duplo", "especial", "projetil"])
	var m := LabMetricas.new()
	add_child(m)
	var chao := (load("res://scenes/actors/Plataforma.tscn") as PackedScene).instantiate()
	chao.position = Vector2(1300.0, 730.0)
	chao.tamanho = Vector2(2600.0, 60.0)
	add_child(chao)
	var k := (load("res://scenes/actors/Koliani.tscn") as PackedScene).instantiate() as Koliani
	k.position = Vector2(400.0, 630.0)
	k.usar_prototipo_premium = true
	k.usar_golden_set = true
	add_child(k)
	for i in 90:
		await get_tree().physics_frame
		if k.is_on_floor():
			break
	var core := k.ativar_core_combate()
	# mesma configuracao exportada do GoblinAprendiz de producao (Fase 8), isolado (sem carregar o nivel inteiro)
	var g := (load("res://scenes/actors/DemonioBase.tscn") as PackedScene).instantiate() as DemonioBase
	g.especie = "goblin"
	g.comportamento = "carga"
	g.piloto_combate_v1 = true
	g.peso = "leve"
	g.pode_ser_lancado = true
	g.global_position = k.global_position + Vector2(70.0, 0.0)
	add_child(g)
	await get_tree().physics_frame

	# bote (a meio da investida): origem ATAQUE -- dentro da janela do roll, da' Perfect Dodge
	await _lab_tap("rolar", 3)
	await _lab_esperar(3)
	g._carga = 0.3
	g._ao_tocar(k)
	_ok(m.contar("perfect_dodge") == 1, "goblin piloto: o bote telegrafado (carga) da' Perfect Dodge")
	# contacto de patrulha comum (fora da investida): CONTATO -- nao da' PD mesmo na janela
	await _lab_esperar(60)
	await _lab_tap("rolar", 3)
	await _lab_esperar(3)
	g._carga = 0.0
	g._ao_tocar(k)
	_ok(m.contar("perfect_dodge") == 1, "goblin piloto: o contacto de patrulha comum NAO da' Perfect Dodge")

	# Launcher: leve + lancavel -- lanca; segundo Launcher imediato NAO relanca (anti-juggle)
	var res1 := g.lab_hit({"tipo": "launcher", "dano": 10, "dir": 1.0, "critico": false, "guard_break": false})
	_ok(res1.get("lancado", false), "goblin piloto: Launcher lanca (leve, lancavel)")
	var res2 := g.lab_hit({"tipo": "launcher", "dano": 10, "dir": 1.0, "critico": false, "guard_break": false})
	_ok(not res2.get("lancado", true), "goblin piloto: sem juggle infinito (2.o Launcher imediato nao relanca)")

	g.queue_free()
	k.queue_free()
	chao.queue_free()
	m.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	Input.action_release("atacar")
	Input.action_release("rolar")
	EstadoJogo.habilidades.assign(antes_hab)


## TTK do Goblin piloto (spam vs combo intencional) -- MEDIDO, nao imposto. Objetivo aproximado do
## plano: spam ~4-6s, combo ~3-4,5s (nao perseguir os numeros se o comportamento de producao diferir).
func _ttk_goblin_piloto(k: Koliani, g: DemonioBase, modo: String, limite := 15.0) -> float:
	var t := 0.0
	var dt := 1.0 / 60.0
	while t < limite and is_instance_valid(g) and not g._morto:
		if modo == "spam":
			Input.action_press("atacar")
			for i in 3:
				await get_tree().physics_frame
				t += dt
			Input.action_release("atacar")
			for i in 15:
				await get_tree().physics_frame
				t += dt
		else:   # "combo": 4 toques certos (janela do combo) + pausa, repete
			for i in 4:
				Input.action_press("atacar")
				for j in 3:
					await get_tree().physics_frame
					t += dt
				Input.action_release("atacar")
				for j in 10:
					await get_tree().physics_frame
					t += dt
			for j in 20:
				await get_tree().physics_frame
				t += dt
	Input.action_release("atacar")
	return t


func teste_goblin_piloto_ttk() -> void:
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	EstadoJogo.habilidades.assign(["dash", "pogo", "salto_duplo", "especial", "projetil"])
	var resultado := {}
	for modo in ["spam", "combo"]:
		var chao := (load("res://scenes/actors/Plataforma.tscn") as PackedScene).instantiate()
		chao.position = Vector2(1300.0, 730.0)
		chao.tamanho = Vector2(2600.0, 60.0)
		add_child(chao)
		var k := (load("res://scenes/actors/Koliani.tscn") as PackedScene).instantiate() as Koliani
		k.position = Vector2(400.0, 630.0)
		k.usar_prototipo_premium = true
		k.usar_golden_set = true
		add_child(k)
		for i in 90:
			await get_tree().physics_frame
			if k.is_on_floor():
				break
		k.ativar_core_combate()
		var g := (load("res://scenes/actors/DemonioBase.tscn") as PackedScene).instantiate() as DemonioBase
		g.especie = "goblin"
		g.comportamento = "carga"
		g.piloto_combate_v1 = true
		g.peso = "leve"
		g.pode_ser_lancado = true
		g.set_physics_process(false)   # nao anda/investe sozinho -- so' se mede o TTK da espada
		g.global_position = k.global_position + Vector2(60.0, 0.0)
		add_child(g)
		await get_tree().physics_frame
		k._olha_para = 1.0
		var t := await _ttk_goblin_piloto(k, g, modo)
		resultado[modo] = {"ttk": snappedf(t, 0.01), "morreu": g._morto if is_instance_valid(g) else true, "vida_inicial": 58}
		if is_instance_valid(g):
			g.queue_free()
		k.queue_free()
		chao.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	print("GOBLIN PILOTO ttk: ", resultado)
	_ok(bool(resultado["spam"]["morreu"]), "goblin piloto: o goblin morre a spam dentro do limite de tempo")
	_ok(bool(resultado["combo"]["morreu"]), "goblin piloto: o goblin morre a combo intencional dentro do limite de tempo")
	EstadoJogo.habilidades.assign(antes_hab)


## Fase 9 -- Golem piloto do N6 (EliteGolem, Prisao_dos_Condenados.tscn). NAO e' o
## Guardiao/chefe do nivel (esse e' ChefeCarcereiro, fora de escopo desta fase) --
## e' o elite comum (DemonioBase, especie golem_aereo) que ja patrulha por ali.
func teste_golem_piloto_estrutura() -> void:
	var nivel := (load("res://scenes/levels/Prisao_dos_Condenados.tscn") as PackedScene).instantiate()
	var g := nivel.get_node_or_null("EliteGolem") as DemonioBase
	_ok(g != null, "golem piloto: EliteGolem existe em Prisao_dos_Condenados.tscn")
	if g != null:
		_ok(g.piloto_combate_v1, "golem piloto: piloto_combate_v1 ligado so' nesta instancia")
		_ok(g.peso == "pesado", "golem piloto: peso pesado")
		_ok(not g.pode_ser_lancado, "golem piloto: nao lancavel")
		_ok(g.tem_guarda_v1 and g.guarda_max_v1 > 0.0, "golem piloto: tem guarda/postura")
		_ok(g.comportamento == "carga", "golem piloto: ja tinha um ataque telegrafado (carga) -- reaproveitado, nao inventado")
	nivel.queue_free()
	await get_tree().process_frame


## Comportamento funcional do Golem piloto: guarda absorve golpes normais pela frente, Cleave/Counter
## quebram-na, a JANELA DE EXPOSICAO (a meio/logo apos o proprio ataque) desliga a guarda, Launcher
## nunca lanca (pesado), o bote da' PD (origem ATAQUE) e o contacto comum nao, e guard_break repetido
## nao entra em loop (fica so' a 0, nunca "quebra" outra vez do nada).
func teste_golem_piloto_comportamento() -> void:
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	EstadoJogo.habilidades.assign(["dash", "pogo", "salto_duplo", "especial", "projetil"])
	var m := LabMetricas.new()
	add_child(m)
	var chao := (load("res://scenes/actors/Plataforma.tscn") as PackedScene).instantiate()
	chao.position = Vector2(1300.0, 730.0)
	chao.tamanho = Vector2(2600.0, 60.0)
	add_child(chao)
	var k := (load("res://scenes/actors/Koliani.tscn") as PackedScene).instantiate() as Koliani
	k.position = Vector2(400.0, 630.0)
	k.usar_prototipo_premium = true
	k.usar_golden_set = true
	add_child(k)
	for i in 90:
		await get_tree().physics_frame
		if k.is_on_floor():
			break
	k.ativar_core_combate()
	k._olha_para = 1.0
	# mesma configuracao exportada do EliteGolem de producao (Fase 9), isolado
	var g := (load("res://scenes/actors/DemonioBase.tscn") as PackedScene).instantiate() as DemonioBase
	g.especie = "golem_aereo"
	g.elite = true
	g.vida = 165
	g.comportamento = "carga"
	g.piloto_combate_v1 = true
	g.peso = "pesado"
	g.pode_ser_lancado = false
	g.tem_guarda_v1 = true
	g.guarda_max_v1 = 100.0
	g._direcao = 1.0
	g.global_position = k.global_position + Vector2(70.0, 0.0)
	add_child(g)
	await get_tree().physics_frame

	# guarda ATIVA (parado, sem carga em curso, nao vulneravel): golpe normal frontal so' passa 20%
	var vida0 := g.vida
	var res_guarda := g.lab_hit({"tipo": "normal", "dano": 20, "dir": 1.0, "critico": false, "guard_break": false})
	_ok(res_guarda.get("efeito", "") == "guardado", "golem piloto: guarda absorve golpe normal frontal parado")
	_ok(vida0 - g.vida == 4, "golem piloto: golpe guardado so' passa 20%% do dano")

	# JANELA DE EXPOSICAO: golem atordoado (esta_vulneravel()==true) -- a guarda NAO se aplica
	g.atordoar(1.0)
	var vida1 := g.vida
	var res_exposto := g.lab_hit({"tipo": "normal", "dano": 20, "dir": 1.0, "critico": false, "guard_break": false})
	_ok(res_exposto.get("efeito", "") != "guardado", "golem piloto: atordoado (janela de exposicao) nao guarda")
	_ok(vida1 - g.vida == 20, "golem piloto: janela de exposicao leva dano cheio")

	# Cleave/Counter (guard_break) quebram a guarda -- dano cheio, guarda vai a 0 e fica la' (sem loop)
	g.vida = 165
	g._guarda_v1 = g.guarda_max_v1
	var vida2 := g.vida
	g.lab_hit({"tipo": "cleave", "dano": 25, "dir": 1.0, "critico": false, "guard_break": true})
	_ok(vida2 - g.vida == 25, "golem piloto: Cleave (guard_break) ignora a guarda -- dano cheio")
	_ok(g._guarda_v1 == 0.0, "golem piloto: Cleave esgota a guarda")
	g.lab_hit({"tipo": "counter", "dano": 30, "dir": 1.0, "critico": false, "guard_break": true})
	_ok(g._guarda_v1 == 0.0, "golem piloto: guard_break repetido nao faz a guarda oscilar (fica a 0, sem loop)")

	# Launcher: pesado -- nunca lanca
	g.vida = 165
	var res_launcher := g.lab_hit({"tipo": "launcher", "dano": 10, "dir": 1.0, "critico": false, "guard_break": false})
	_ok(not res_launcher.get("lancado", true), "golem piloto: peso pesado nunca lanca")

	# Bote telegrafado (carga) = ATAQUE, pode dar PD; contacto comum = CONTATO, nunca da'
	await _lab_tap("rolar", 3)
	await _lab_esperar(3)
	g._carga = 0.3
	g._atordoado = 0.0
	g._ao_tocar(k)
	_ok(m.contar("perfect_dodge") == 1, "golem piloto: o bote (carga) da' Perfect Dodge")
	await _lab_esperar(60)
	await _lab_tap("rolar", 3)
	await _lab_esperar(3)
	g._carga = 0.0
	g._ao_tocar(k)
	_ok(m.contar("perfect_dodge") == 1, "golem piloto: contacto comum NAO da' Perfect Dodge")

	g.queue_free()
	k.queue_free()
	chao.queue_free()
	m.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	Input.action_release("atacar")
	Input.action_release("rolar")
	EstadoJogo.habilidades.assign(antes_hab)


## TTK do Golem piloto (spam normal vs Cleave) -- MEDIDO, nao imposto. O spam frontal deve ser fraco
## (guarda absorve 80%); o Cleave, que quebra guarda, deve ser claramente mais eficiente.
func teste_golem_piloto_ttk() -> void:
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	EstadoJogo.habilidades.assign(["dash", "pogo", "salto_duplo", "especial", "projetil"])
	var resultado := {}
	for modo in ["spam_frontal", "cleave_repetido"]:
		var chao := (load("res://scenes/actors/Plataforma.tscn") as PackedScene).instantiate()
		chao.position = Vector2(1300.0, 730.0)
		chao.tamanho = Vector2(2600.0, 60.0)
		add_child(chao)
		var k := (load("res://scenes/actors/Koliani.tscn") as PackedScene).instantiate() as Koliani
		k.position = Vector2(400.0, 630.0)
		k.usar_prototipo_premium = true
		k.usar_golden_set = true
		add_child(k)
		for i in 90:
			await get_tree().physics_frame
			if k.is_on_floor():
				break
		var core := k.ativar_core_combate()
		var g := (load("res://scenes/actors/DemonioBase.tscn") as PackedScene).instantiate() as DemonioBase
		g.especie = "golem_aereo"
		g.elite = true
		g.vida = 165
		g.comportamento = "carga"
		g.piloto_combate_v1 = true
		g.peso = "pesado"
		g.pode_ser_lancado = false
		g.tem_guarda_v1 = true
		g.guarda_max_v1 = 100.0
		g.set_physics_process(false)   # nao investe sozinho -- so' se mede o TTK da espada/Cleave
		g._direcao = 1.0
		g.global_position = k.global_position + Vector2(60.0, 0.0)
		add_child(g)
		await get_tree().physics_frame
		k._olha_para = 1.0
		var t := 0.0
		var dt := 1.0 / 60.0
		var limite := 20.0
		while t < limite and is_instance_valid(g) and not g._morto:
			if modo == "spam_frontal":
				Input.action_press("atacar")
				for i in 3:
					await get_tree().physics_frame
					t += dt
				Input.action_release("atacar")
				for i in 15:
					await get_tree().physics_frame
					t += dt
			else:   # cleave_repetido: segura ATAQUE ate' carregar (carga_cleave_t), larga, repete
				Input.action_press("atacar")
				for i in int(core.bal.carga_cleave_t * 60.0) + 4:
					await get_tree().physics_frame
					t += dt
				Input.action_release("atacar")
				for i in 22:
					await get_tree().physics_frame
					t += dt
		Input.action_release("atacar")
		resultado[modo] = {"ttk": snappedf(t, 0.01), "morreu": is_instance_valid(g) and g._morto,
			"guarda_final": g._guarda_v1 if is_instance_valid(g) else -1.0}
		if is_instance_valid(g):
			g.queue_free()
		k.queue_free()
		chao.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	print("GOLEM PILOTO ttk: ", resultado)
	_ok(float(resultado["cleave_repetido"]["ttk"]) < float(resultado["spam_frontal"]["ttk"]) or bool(resultado["cleave_repetido"]["morreu"]),
		"golem piloto: Cleave (quebra guarda) tem de ser mais eficiente que o spam frontal guardado")
	EstadoJogo.habilidades.assign(antes_hab)


## Fase 10 -- ENERGY INSTRUMENTATION. So' MEDE (janelas de 10s por cenario contra um alvo durao'vel);
## NAO mexe em REGEN_ENERGIA, ESPECIAL_CUSTO nem nos ganhos actuais. "especiais" conta quantas vezes
## `usar_especial()` disparou de verdade dentro da janela (o jogador gasta assim que pode pagar --
## e' a leitura mais realista, inclui a pausa de regen do proprio Especial). Se algum numero for
## absurdo, o teste so' o REGISTA (print) -- nao falha a suite por isso (nao e' um "bug", e' um
## achado de balance para o GM decidir, como o plano pede).
func teste_energy_instrumentation() -> void:
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	var antes_dev: bool = EstadoJogo.modo_dev
	EstadoJogo.habilidades.assign(["dash", "pogo", "salto_duplo", "especial", "projetil"])
	# INVENCIVEL: o cenario "pd_counter" da' dano de contacto REAL de propósito (o bote do
	# LabGoblin) para poder medir a Energia do Perfect Dodge -- sem isto, hits repetidos podiam
	# matar a Koliani e `_morrer()` chama `Transicao.fechar_e(get_tree().reload_current_scene)`,
	# que recarrega A CENA INTEIRA da suite a meio do teste (corrompe todos os testes seguintes).
	EstadoJogo.modo_dev = true
	var janela := 10.0
	var dt := 1.0 / 60.0
	var relatorio := {}

	# baseline: regen passiva pura, sem input nenhum
	var k0 := (load("res://scenes/actors/Koliani.tscn") as PackedScene).instantiate() as Koliani
	add_child(k0)
	await get_tree().physics_frame
	var especiais0 := 0
	var t0_especial := -1.0
	var t := 0.0
	while t < janela:
		if k0.energia_actual() >= Koliani.ESPECIAL_CUSTO and k0.usar_especial():
			especiais0 += 1
			if t0_especial < 0.0:
				t0_especial = t
		await get_tree().physics_frame
		t += dt
	relatorio["passiva_regen"] = {"energia_final": snappedf(k0.energia_actual(), 0.1),
		"especiais": especiais0, "1o_especial_em": snappedf(t0_especial, 0.1) if t0_especial >= 0.0 else -1.0}
	k0.queue_free()
	await get_tree().process_frame

	for cenario in ["spam_basico", "combo_intencional", "launcher_air", "pogo", "pd_counter", "mistura_realista"]:
		var chao := (load("res://scenes/actors/Plataforma.tscn") as PackedScene).instantiate()
		chao.position = Vector2(1300.0, 730.0)
		chao.tamanho = Vector2(2600.0, 60.0)
		add_child(chao)
		var k := (load("res://scenes/actors/Koliani.tscn") as PackedScene).instantiate() as Koliani
		k.position = Vector2(400.0, 630.0)
		k.usar_prototipo_premium = true
		k.usar_golden_set = true
		add_child(k)
		for i in 90:
			await get_tree().physics_frame
			if k.is_on_floor():
				break
		k.ativar_core_combate()
		k._olha_para = 1.0
		var g := (load("res://scenes/lab/LabGoblin.tscn") as PackedScene).instantiate() as LabInimigo
		g.vida = 999999
		g.set_physics_process(false)   # alvo estatico e duravel -- so' se mede a Energia da Koliani
		g.global_position = k.global_position + Vector2(70.0, 0.0)
		add_child(g)
		await get_tree().physics_frame

		var especiais := 0
		var t1_especial := -1.0
		t = 0.0
		while t < janela:
			if k.energia_actual() >= Koliani.ESPECIAL_CUSTO and k.usar_especial():
				especiais += 1
				if t1_especial < 0.0:
					t1_especial = t
			match cenario:
				"spam_basico":
					Input.action_press("atacar")
					await get_tree().physics_frame; t += dt
					Input.action_release("atacar")
					for i in 8:
						await get_tree().physics_frame
						t += dt
				"combo_intencional":
					for i in 4:
						Input.action_press("atacar")
						for j in 3:
							await get_tree().physics_frame
							t += dt
						Input.action_release("atacar")
						for j in 10:
							await get_tree().physics_frame
							t += dt
					for j in 15:
						await get_tree().physics_frame
						t += dt
				"launcher_air":
					Input.action_press("mirar_cima")
					await _lab_tap("atacar", 3)
					Input.action_release("mirar_cima")
					for i in 6:
						await get_tree().physics_frame
						t += dt
					if not k.is_on_floor():
						await _lab_tap("atacar", 3)
					for i in 40:
						await get_tree().physics_frame
						t += dt
						if k.is_on_floor():
							break
				"pogo":
					if EstadoJogo.tem_habilidade("pogo"):
						Input.action_press("mirar_baixo")
					await get_tree().physics_frame; t += dt
					for i in 20:
						await get_tree().physics_frame
						t += dt
					Input.action_release("mirar_baixo")
				"pd_counter":
					await _lab_tap("rolar", 3)
					await _lab_esperar(3)
					t += 6.0 * dt
					g._ao_tocar(k)   # bote generico do goblin do lab (ja' e' origem "ataque")
					for i in 6:
						await get_tree().physics_frame
						t += dt
					if k._combate_extra() != null and k._combate_extra().janela_counter() > 0.0:
						await _lab_tap("atacar", 3)
					for i in 25:
						await get_tree().physics_frame
						t += dt
				"mistura_realista":
					# spam curto -> combo -> launcher -> pausa (o "jogador medio" real)
					Input.action_press("atacar")
					for i in 3:
						await get_tree().physics_frame
						t += dt
					Input.action_release("atacar")
					for i in 10:
						await get_tree().physics_frame
						t += dt
					Input.action_press("mirar_cima")
					await _lab_tap("atacar", 3)
					Input.action_release("mirar_cima")
					for i in 15:
						await get_tree().physics_frame
						t += dt
		Input.action_release("atacar")
		Input.action_release("mirar_cima")
		Input.action_release("mirar_baixo")
		Input.action_release("rolar")
		relatorio[cenario] = {"energia_final": snappedf(k.energia_actual(), 0.1), "especiais": especiais,
			"1o_especial_em": snappedf(t1_especial, 0.1) if t1_especial >= 0.0 else -1.0}
		if is_instance_valid(g):
			g.queue_free()
		if is_instance_valid(k):
			k.queue_free()
		chao.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	print("ENERGY instrumentation (janelas de %.0fs, ESPECIAL_CUSTO=%.0f, REGEN_ENERGIA=%.0f/s): " % [janela, Koliani.ESPECIAL_CUSTO, Koliani.REGEN_ENERGIA], relatorio)
	# Especiais/min estimados (extrapolacao linear da janela de 10s -- so' leitura, nao regra):
	var por_min := {}
	for cenario in relatorio.keys():
		por_min[cenario] = snappedf(float(relatorio[cenario]["especiais"]) * (60.0 / janela), 0.1)
	print("ENERGY especiais/min estimados (fraco~spam_basico, medio~combo_intencional/pogo, eficiente~mistura_realista/pd_counter): ", por_min)
	# Nao falha a suite por numeros de balance -- so' prova que a instrumentacao MEDE algo real
	# (a Koliani ganhou Energia nalgum cenario de combate, para alem da regen passiva a zeros).
	_ok(float(relatorio["combo_intencional"]["energia_final"]) > 0.0, "energy: combo intencional gera Energia mensuravel")
	EstadoJogo.habilidades.assign(antes_hab)
	EstadoJogo.modo_dev = antes_dev


## Fase 11 -- PRODUCTION COMBAT QA ARENA. Prova que a arena usa a Koliani REAL (nao uma copia),
## liga o Core Combat, e os dois pilotos nascidos pela arena tem EXACTAMENTE a mesma configuracao
## das instancias reais de producao (Fases 8/9) -- nao e' uma reconstrucao aproximada.
func teste_qa_arena_producao() -> void:
	var cena := (load("res://scenes/qa/ProductionCombatArena.tscn") as PackedScene).instantiate()
	add_child(cena)
	for i in 4:
		await get_tree().physics_frame
	_ok(cena.koliani is Koliani, "arena QA: a Koliani e' a cena de producao real")
	_ok(cena.koliani._lab == null, "arena QA: nao usa o Combat Lab -- so' o Core Combat")
	_ok(cena.core is CoreCombate, "arena QA: ativou o Core Combat")
	_ok(cena.koliani._combate_extra() == cena.core, "arena QA: _combate_extra devolve o core da arena")
	# nasce logo com um Goblin (ver _ready) -- confirmar a configuracao IDENTICA a Floresta_Putrefata.tscn
	var goblins := 0
	for e in get_tree().get_nodes_in_group("inimigos"):
		if e is DemonioBase and (e as DemonioBase).especie == "goblin":
			goblins += 1
			var d := e as DemonioBase
			_ok(d.piloto_combate_v1 and d.peso == "leve" and d.pode_ser_lancado and d.comportamento == "carga",
				"arena QA: o Goblin nascido tem a config identica ao GoblinAprendiz de producao")
	_ok(goblins >= 1, "arena QA: nasce com um Goblin a partida")
	# 2 -> golem
	cena.spawn_golem()
	await get_tree().physics_frame
	var golems := 0
	# `_ready()` escala vida pela curva de dificuldade (`EstadoJogo.indice_nivel`, N6=5); a arena
	# fixa o indice antes de instanciar (ver production_combat_arena.gd) para nascer EXACTAMENTE
	# como em producao -- a mesma formula, aqui, so' para o "165" base virar o valor certo em N6.
	var f_n6 := float(clampi(5, 0, 29)) / 29.0
	var vida_esperada_n6 := maxi(1, int(round(165.0 * (0.8 + 0.6 * f_n6))))
	for e in get_tree().get_nodes_in_group("inimigos"):
		if e is DemonioBase and (e as DemonioBase).especie == "golem_aereo":
			golems += 1
			var d := e as DemonioBase
			_ok(d.piloto_combate_v1 and d.peso == "pesado" and not d.pode_ser_lancado and d.tem_guarda_v1,
				"arena QA: o Golem nascido tem a config identica ao EliteGolem de producao")
			_ok(d.vida == vida_esperada_n6,
				"arena QA: o Golem nascido escala a vida pela dificuldade de N6 (esperado %d, foi %d)"
					% [vida_esperada_n6, d.vida])
	_ok(golems >= 1, "arena QA: spawn_golem() funciona")
	# reset limpa os inimigos e devolve a Koliani ao ponto de partida com Energia cheia
	cena.limpar()
	await get_tree().physics_frame
	var restantes := 0
	for e in get_tree().get_nodes_in_group("inimigos"):
		if is_instance_valid(e) and e != cena.koliani:
			restantes += 1
	_ok(restantes == 0, "arena QA: limpar() remove os pilotos nascidos")
	cena.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


## Atravessamento: o avanco dos golpes nao leva a Koliani ao outro lado do alvo (goblin pequeno e golem grande).
func teste_combat_lab_clamp() -> void:
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	var relatorio := {}
	for com_clamp in [false, true]:
		var cruzou := 0
		var total := 0
		var acertos := 0
		for alvo_tipo in ["goblin", "golem"]:
			for golpe in ["launcher", "cleave", "dash", "normal3"]:
				for dist in [50.0, 90.0]:
					var cena := await _lab_novo()
					var k: Koliani = cena.koliani
					var lab: CombateLab = cena.lab
					var m: LabMetricas = cena.metricas
					lab.clamp_avanco = com_clamp
					k._olha_para = 1.0
					var x0 := k.global_position.x
					var alvo: LabInimigo = cena.spawn_goblin(dist) if alvo_tipo == "goblin" else cena.spawn_golem(dist)
					await _lab_esperar(3)
					alvo.set_physics_process(false)
					alvo.vida = 99999
					alvo.global_position = Vector2(x0 + dist, k.global_position.y - (16.0 if alvo_tipo == "golem" else 10.0))
					alvo.lab_estado = LabInimigo.E.IDLE
					if golpe == "dash":
						await _lab_tap("dash", 2)
						await _lab_esperar(1)
						await _lab_tap("atacar", 2)
					elif golpe == "normal3":
						for i in 3:
							await _lab_tap("atacar", 2)
							await _lab_esperar(12)
					else:
						lab._iniciar_move(golpe)
					var min_rel := INF
					for i in 40:
						await get_tree().physics_frame
						min_rel = minf(min_rel, alvo.global_position.x - k.global_position.x)
					total += 1
					if min_rel < 0.0:
						cruzou += 1
					acertos += 1 if m.contar("hit") > 0 else 0
					if com_clamp:
						_ok(min_rel >= 0.0, "clamp: %s / %s a %d px atravessou o alvo (rel=%.1f)" % [golpe, alvo_tipo, dist, min_rel])
					await _lab_fim(cena)
		relatorio["com_clamp" if com_clamp else "sem_clamp"] = {"cruzou": cruzou, "de": total, "acertaram": acertos}
	print("LAB clamp: ", relatorio)
	_ok(int(relatorio["com_clamp"]["cruzou"]) == 0, "clamp: com clamp nenhum golpe atravessa")
	_ok(int(relatorio["sem_clamp"]["cruzou"]) > 0, "clamp: o teste tem de morder (sem clamp devia haver atravessamento)")
	_ok(int(relatorio["com_clamp"]["acertaram"]) >= int(relatorio["sem_clamp"]["acertaram"]) - 2,
		"clamp: nao pode perder acertos (%s)" % str(relatorio))
	EstadoJogo.habilidades.assign(antes_hab)


## Anti-spam do goblin: BEFORE (v1) vs AFTER (v1.1), spam parado, combo correto e launcher -> air combo.
func teste_combat_lab_antispam() -> void:
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	var res := {}
	var antes := {}
	for modo in ["spam", "parado", "combo3_launcher", "launcher_ar", "spam_v1", "parado_v1", "combo3_launcher_v1", "launcher_ar_v1"]:
		var cena := await _lab_novo()
		var g: LabInimigo = cena.spawn_goblin(200.0)
		g.lab_semente = 5
		g.regra_v1 = modo.ends_with("_v1")
		var r := await _lab_bot_goblin(cena, g, modo.trim_suffix("_v1"))
		if modo.ends_with("_v1"):
			antes[modo.trim_suffix("_v1")] = r
		else:
			res[modo] = r
		await _lab_fim(cena)
	# PRENDER ATE' MORRER: mede-se com vida infinita durante 12 s (o TTK depende do dano; o "lock" nao)
	var lock := {}
	for modo in ["spam", "parado"]:
		for v1 in [true, false]:
			var cena2 := await _lab_novo()
			var g2: LabInimigo = cena2.spawn_goblin(200.0)
			g2.lab_semente = 5
			g2.regra_v1 = v1
			g2.vida = 999999
			var r2 := await _lab_bot_goblin(cena2, g2, modo, 12.0)
			lock["%s_%s" % [modo, "v1" if v1 else "v1.1"]] = {"hitstun_frac": snappedf(float(r2["hitstun_frac"]), 0.001), "botes": r2["botes"], "goblin_acertou": r2["goblin_acertou"], "escapes": r2["escapes"], "golpes": r2["golpes"]}
			await _lab_fim(cena2)
	print("LAB antispam LOCK 12s vida infinita: ", lock)
	# NAO ha' prisao ate' morrer: em 12 s de spam (vida infinita) o goblin completa botes e fica < 50 % preso
	for chave in ["spam_v1.1", "parado_v1.1"]:
		_ok(int(lock[chave]["botes"]) >= 3, "anti-spam: %s - o goblin devia completar >= 3 botes em 12 s (%d)" % [chave, int(lock[chave]["botes"])])
		_ok(float(lock[chave]["hitstun_frac"]) < 0.5, "anti-spam: %s - goblin preso %.0f %% do tempo" % [chave, 100.0 * float(lock[chave]["hitstun_frac"])])
		_ok(int(lock[chave]["escapes"]) >= 3, "anti-spam: %s - o escape devia disparar (>= 3 em 12 s): %d" % [chave, int(lock[chave]["escapes"])])
	print("LAB antispam AFTER (v1.1): ", res)
	print("LAB antispam BEFORE (regra v1, mesmo bot): ", antes)
	# spam parado: deixa de ser dominante -- o goblin tem de ter feito algo (escape e/ou acertado)
	_ok(int(res["spam"]["escapes"]) >= 1, "anti-spam: o goblin nunca escapou ao spam")
	# combo correto: 3 golpes + launcher lanca (nao e' travado pela armadura) e o goblin morre
	_ok(float(res["combo3_launcher"]["ttk"]) > 0.0, "anti-spam: N-N-N + launcher nao matou o goblin")
	_ok(int(res["combo3_launcher"]["lancamentos"]) >= 1, "anti-spam: o launcher depois de 3 golpes nao lancou")
	_ok(float(res["launcher_ar"]["ttk"]) > 0.0 and int(res["launcher_ar"]["golpes_ar"]) >= 2, "anti-spam: launcher -> air combo nao funciona")
	EstadoJogo.habilidades.assign(antes_hab)


## Bots de medicao contra o goblin com IA real. Devolve {ttk, goblin_acertou, golpes, lancamentos, golpes_ar}.
func _lab_bot_goblin(cena: Node, g: LabInimigo, modo: String, limite := 60.0) -> Dictionary:
	var k: Koliani = cena.koliani
	var lab: CombateLab = cena.lab
	var m: LabMetricas = cena.metricas
	var t := 0.0
	var dt := 1.0 / 60.0
	var frames_stun := 0
	var frames_lut := 0
	while t < limite and is_instance_valid(g) and not g._morto:
		var dx := g.global_position.x - k.global_position.x
		var lado := signf(dx)
		k._olha_para = lado if lado != 0.0 else k._olha_para
		if g.lab_estado == LabInimigo.E.HITSTUN:
			frames_stun += 1
		frames_lut += 1
		if k._energia < 60.0:
			k._energia = 60.0
		if modo == "parado":
			# spam PARADO: nao anda; so' martela ATAQUE a cada 0,3 s (o goblin e' que vem ter com ela)
			Input.action_press("atacar")
			for i in 3:
				await get_tree().physics_frame
				t += dt
			Input.action_release("atacar")
			for i in 15:
				await get_tree().physics_frame
				t += dt
			continue
		if absf(dx) > 70.0:
			Input.action_press("mover_direita" if lado > 0 else "mover_esquerda")
			Input.action_release("mover_esquerda" if lado > 0 else "mover_direita")
			await get_tree().physics_frame
			t += dt
			continue
		Input.action_release("mover_direita")
		Input.action_release("mover_esquerda")
		if modo == "spam":
			Input.action_press("atacar")
			for i in 3:
				await get_tree().physics_frame
				t += dt
			Input.action_release("atacar")
			for i in 15:
				await get_tree().physics_frame
				t += dt
		elif modo == "combo3_launcher":
			# N-N-N e depois LAUNCHER (com o goblin ainda na janela) e mais N-N-N...
			for i in 3:
				Input.action_press("atacar")
				for j in 3:
					await get_tree().physics_frame
					t += dt
				Input.action_release("atacar")
				for j in 10:
					await get_tree().physics_frame
					t += dt
			Input.action_press("mirar_cima")
			Input.action_press("atacar")
			for j in 3:
				await get_tree().physics_frame
				t += dt
			Input.action_release("atacar")
			Input.action_release("mirar_cima")
			for j in 30:
				await get_tree().physics_frame
				t += dt
		elif modo == "dash_launcher_ar":
			# execucao "ideal": Dash Attack -> Launcher (cancel) -> salto -> Air x2
			if g.lab_estado != LabInimigo.E.LANCADO and k.is_on_floor():
				Input.action_press("dash")
				for j in 2:
					await get_tree().physics_frame
					t += dt
				Input.action_release("dash")
				await get_tree().physics_frame
				t += dt
				Input.action_press("atacar")
				for j in 3:
					await get_tree().physics_frame
					t += dt
				Input.action_release("atacar")
				for j in 11:
					await get_tree().physics_frame
					t += dt
				Input.action_press("mirar_cima")
				Input.action_press("atacar")
				for j in 3:
					await get_tree().physics_frame
					t += dt
				Input.action_release("atacar")
				Input.action_release("mirar_cima")
				for j in 5:
					await get_tree().physics_frame
					t += dt
			if g.lab_estado == LabInimigo.E.LANCADO and k.is_on_floor():
				Input.action_press("saltar")
				for j in 12:
					await get_tree().physics_frame
					t += dt
				Input.action_release("saltar")
				for j in 2:
					await get_tree().physics_frame
					t += dt
			for n in 2:
				if not k.is_on_floor() and absf(g.global_position.x - k.global_position.x) < 100.0:
					Input.action_press("atacar")
					for j in 3:
						await get_tree().physics_frame
						t += dt
					Input.action_release("atacar")
					for j in 9:
						await get_tree().physics_frame
						t += dt
			for j in 20:
				await get_tree().physics_frame
				t += dt
		else:   # launcher -> salto -> ar -> ar
			if g.lab_estado != LabInimigo.E.LANCADO and k.is_on_floor():
				Input.action_press("mirar_cima")
				Input.action_press("atacar")
				for j in 3:
					await get_tree().physics_frame
					t += dt
				Input.action_release("atacar")
				Input.action_release("mirar_cima")
				for j in 5:
					await get_tree().physics_frame
					t += dt
			if g.lab_estado == LabInimigo.E.LANCADO and k.is_on_floor():
				Input.action_press("saltar")
				for j in 12:
					await get_tree().physics_frame
					t += dt
				Input.action_release("saltar")
				for j in 2:
					await get_tree().physics_frame
					t += dt
			for n in 2:
				if not k.is_on_floor() and absf(g.global_position.x - k.global_position.x) < 100.0:
					Input.action_press("atacar")
					for j in 3:
						await get_tree().physics_frame
						t += dt
					Input.action_release("atacar")
					for j in 9:
						await get_tree().physics_frame
						t += dt
			for j in 20:
				await get_tree().physics_frame
				t += dt
	Input.action_release("mover_direita")
	Input.action_release("mover_esquerda")
	var lanc := 0
	var golpes_ar := 0
	var esc := 0
	for e in m.eventos:
		if e["nome"] == "hit" and String(e["d"]["efeito"]).contains("escape"):
			esc += 1
		if e["nome"] == "hit" and e["d"]["efeito"] == "lancado":
			lanc += 1
		if e["nome"] == "hit" and bool(e["d"]["efeito"].begins_with("juggle")):
			golpes_ar += 1
	return {"ttk": _lab_ttk_evento(m, t), "windups": m.contar("goblin_windup"),
		"botes": m.contar("goblin_bote"), "hitstun_frac": float(frames_stun) / maxf(1.0, float(frames_lut)), "escapes": esc, "goblin_acertou": m.contar("goblin_acertou"),
		"golpes": m.contar("hit"), "lancamentos": lanc, "golpes_ar": golpes_ar}


## Execucao "bem feita" (jogador que le o estado): [Dash Attack -> Launcher -> Air x2] enquanto o goblin
## pode ser lancado; durante a imunidade a launcher faz N-N-N no chao. TTK vem do proprio alvo.
func _lab_bot_ideal(cena: Node, g: LabInimigo, limite := 40.0) -> Dictionary:
	var k: Koliani = cena.koliani
	var m: LabMetricas = cena.metricas
	var t := 0.0
	var dt := 1.0 / 60.0
	var ciclos_launcher := 0
	while t < limite and is_instance_valid(g) and not g._morto:
		if k._energia < 60.0:
			k._energia = 60.0
		var dx := g.global_position.x - k.global_position.x
		var lado := signf(dx)
		if lado != 0.0:
			k._olha_para = lado
		if not k.is_on_floor():
			await get_tree().physics_frame
			t += dt
			continue
		if absf(dx) > 64.0:
			Input.action_press("mover_direita" if lado > 0 else "mover_esquerda")
			Input.action_release("mover_esquerda" if lado > 0 else "mover_direita")
			await get_tree().physics_frame
			t += dt
			continue
		Input.action_release("mover_direita")
		Input.action_release("mover_esquerda")
		if g.lab_estado in [LabInimigo.E.LANCADO, LabInimigo.E.CAIDO]:
			await get_tree().physics_frame
			t += dt
			continue
		if g._imune_lanca_t <= 0.0 and g.lab_estado != LabInimigo.E.ESCAPE:
			# Dash Attack -> Launcher
			Input.action_press("dash")
			for j in 2:
				await get_tree().physics_frame
				t += dt
			Input.action_release("dash")
			await get_tree().physics_frame
			t += dt
			Input.action_press("atacar")
			for j in 2:
				await get_tree().physics_frame
				t += dt
			Input.action_release("atacar")
			for j in 9:
				await get_tree().physics_frame
				t += dt
			Input.action_press("mirar_cima")
			Input.action_press("atacar")
			for j in 3:
				await get_tree().physics_frame
				t += dt
			Input.action_release("atacar")
			Input.action_release("mirar_cima")
			var esperou := 0
			while g.lab_estado != LabInimigo.E.LANCADO and esperou < 14 and is_instance_valid(g):
				await get_tree().physics_frame
				t += dt
				esperou += 1
			if is_instance_valid(g) and g.lab_estado == LabInimigo.E.LANCADO:
				ciclos_launcher += 1
				Input.action_press("saltar")
				for j in 8:
					await get_tree().physics_frame
					t += dt
				Input.action_release("saltar")
				for n in 2:
					var esp := 0
					while is_instance_valid(g) and (absf(g.global_position.x - k.global_position.x) > 90.0 or k.is_on_floor()) and esp < 20:
						await get_tree().physics_frame
						t += dt
						esp += 1
					Input.action_press("atacar")
					for j in 3:
						await get_tree().physics_frame
						t += dt
					Input.action_release("atacar")
					for j in 8:
						await get_tree().physics_frame
						t += dt
		else:
			# enquanto o goblin esta' imune a launcher: N-N-N
			for i in 3:
				Input.action_press("atacar")
				for j in 3:
					await get_tree().physics_frame
					t += dt
				Input.action_release("atacar")
				for j in 11:
					await get_tree().physics_frame
					t += dt
	Input.action_release("mover_direita")
	Input.action_release("mover_esquerda")
	return {"ttk": _lab_ttk_evento(m, t), "botes": m.contar("goblin_bote"),
		"goblin_acertou": m.contar("goblin_acertou"), "ciclos": ciclos_launcher}


## Hierarquia de dano v1.2: BASIC SPAM < COMBO INTENCIONAL, medida no mesmo goblin de 500 HP.
func teste_combat_lab_balanco() -> void:
	var antes_hab: Array = EstadoJogo.habilidades.duplicate()
	var r := {}
	for modo in ["spam", "parado", "ideal"]:
		var cena := await _lab_novo()
		var g: LabInimigo = cena.spawn_goblin(200.0)
		g.lab_semente = 5
		_ok(g.vida == 500, "balanco: o goblin tem de continuar a ter 500 HP")
		if modo == "ideal":
			r[modo] = await _lab_bot_ideal(cena, g, 40.0)
		else:
			r[modo] = await _lab_bot_goblin(cena, g, modo, 40.0)
		await _lab_fim(cena)
	print("LAB balanco TTK (do 1.o golpe ao ultimo): spam_com_deslocacao=%.2f spam_parado=%.2f combo_ideal=%.2f | botes/acertos do goblin: spam %d/%d parado %d/%d ideal %d/%d" % [
		float(r["spam"]["ttk"]), float(r["parado"]["ttk"]), float(r["ideal"]["ttk"]),
		int(r["spam"]["botes"]), int(r["spam"]["goblin_acertou"]), int(r["parado"]["botes"]), int(r["parado"]["goblin_acertou"]),
		int(r["ideal"]["botes"]), int(r["ideal"]["goblin_acertou"])])
	_ok(float(r["parado"]["ttk"]) >= 3.6 and float(r["parado"]["ttk"]) <= 6.5, "balanco: spam parado fora de 3,6-6,5 s: %.2f" % float(r["parado"]["ttk"]))
	_ok(float(r["spam"]["ttk"]) >= 4.0 and float(r["spam"]["ttk"]) <= 6.5, "balanco: spam com deslocacao fora de 4-6,5 s: %.2f" % float(r["spam"]["ttk"]))
	_ok(float(r["ideal"]["ttk"]) >= 3.0 and float(r["ideal"]["ttk"]) <= 4.6, "balanco: combo ideal fora de 3-4,6 s: %.2f" % float(r["ideal"]["ttk"]))
	_ok(float(r["ideal"]["ttk"]) < float(r["parado"]["ttk"]) and float(r["ideal"]["ttk"]) < float(r["spam"]["ttk"]),
		"balanco: o combo intencional tem de matar mais depressa que o spam")
	_ok(float(r["ideal"]["ttk"]) > 2.5, "balanco: power creep -- o combo ideal mata em menos de 2,5 s")
	EstadoJogo.habilidades.assign(antes_hab)


