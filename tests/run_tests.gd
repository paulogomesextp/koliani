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
const DT := 1.0 / 60.0

var _falhas: Array[String] = []


func _ready() -> void:
	call_deferred("_correr_tudo")


func _correr_tudo() -> void:
	for falha in TestesMovimentoCamera4A.executar():
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
	teste_catalogo_campanha()
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
	teste_paineis_nao_trazem_o_vizinho()
	teste_sala_labirinto_deterministica()

	if _falhas.is_empty():
		print("OK -- todos os testes passaram")
		get_tree().quit(0)
	else:
		for f in _falhas:
			printerr("FALHOU: ", f)
		printerr("%d falha(s)" % _falhas.size())
		get_tree().quit(1)


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


## CONTROLOS DE TOQUE. Duas coisas que o Paulo pediu a 5 set 2026:
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
	_ok(Koliani.NUM_COMBO == 3, "Execution 7: combate base devia ter combo de 3 golpes")
	_ok(Koliani.DUR_COMBO.size() == 3
		and Koliani.ATAQUE_ATIVO_INICIO.size() == 3
		and Koliani.ATAQUE_ATIVO_FIM.size() == 3,
		"Execution 7: cada golpe devia ter duração e janela ativa próprias")
	for i in 3:
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

	# TODAS as camaras que o jogo sabe construir tem de estrear em algum
	# nivel -- uma camara que exista e nunca estreie e' trabalho parado.
	# (o `descanso` fica de fora: e' o alivio entre camaras, nao uma estreia)
	var estreadas: Dictionary = {}
	for c in mec:
		estreadas[c] = true
	for c: String in cams:
		if c == "descanso":
			continue
		_ok(estreadas.has(c),
			"a camara '%s' existe mas nunca estreia em nivel nenhum" % c)

	# e os primeiros 32 niveis estreiam 32 coisas diferentes: sem isto o
	# jogo voltava a abrir tudo de uma vez logo no inicio
	var primeiras: Dictionary = {}
	for k in range(0, 32):
		primeiras[mec[k]] = true
	_ok(primeiras.size() == 32,
		"os primeiros 32 niveis estreiam so' %d camaras distintas" % primeiras.size())


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
		var k: float = minf(alvo_h / float(r.size.y), alvo_w / float(r.size.x))
		var largura := r.size.x * k * esc
		var altura := r.size.y * k * esc
		# A banda vem dos nove rigs que já cá estavam antes de 3 set 2026:
		# o mais pequeno media 52x125 e o maior 150x200. Fora disto o chefe
		# ou não se lê como chefe, ou não cabe na plataforma da arena.
		_ok(largura <= 175.0,
			"%s: rig '%s' sai com %d px de largo (máx 175) -- baixar escala_visual"
				% [f, rig, int(largura)])
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
