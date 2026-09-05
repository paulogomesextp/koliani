extends SceneTree
## Corredor de testes headless, sem dependencias externas (sem GUT).
##
##   godot --headless --script res://tests/run_tests.gd
##
## Sai com codigo 1 se algum teste falhar -- o CI (.github/workflows/ci.yml)
## usa isso para marcar o build como vermelho. Acrescenta testes novos como
## metodos `teste_*` e chama-os em `_correr_tudo`.
##
## NOTA: em modo `--script` os autoloads (EstadoJogo) NAO existem como
## identificador global, por isso os testes do estado instanciam
## `estado_jogo.gd` diretamente com `load(...).new()`.

const EstadoJogoScript := preload("res://scripts/estado_jogo.gd")
const DT := 1.0 / 60.0

var _falhas: Array[String] = []


func _initialize() -> void:
	call_deferred("_correr_tudo")


func _correr_tudo() -> void:
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
	teste_catalogo_campanha()
	teste_equipamento_dados()
	teste_equipamento_estado()
	teste_estado_tres_mortes_sem_vidas()
	teste_estado_vida_por_nivel()
	teste_estado_reiniciar_run()
	teste_estado_pistas_sem_duplicados()
	teste_estado_habilidade_sem_duplicados()
	teste_estado_nivel_atual_e_caminho_valido()
	teste_estado_save_ida_e_volta()
	teste_estado_ha_progresso()
	teste_estado_hardcore()
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

	if _falhas.is_empty():
		print("OK -- todos os testes passaram")
		quit(0)
	else:
		for f in _falhas:
			printerr("FALHOU: ", f)
		printerr("%d falha(s)" % _falhas.size())
		quit(1)


func _ok(condicao: bool, mensagem: String) -> void:
	if not condicao:
		_falhas.append(mensagem)


## Instancia estado_jogo.gd fora da arvore (nao chama _ready, logo nao le o
## save do disco), poe modo_teste (nao grava nada no disco) e reinicia a
## campanha para um ponto conhecido.
func _novo_estado() -> Node:
	var e: Node = EstadoJogoScript.new()
	e.modo_teste = true
	e.reiniciar_campanha()
	return e


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
	# no hardcore as vidas são o limite do run -- não crescem
	var h := _novo_estado()
	h.hardcore = true
	var antes_h: int = h.vidas
	h.avancar_nivel()
	_ok(h.vidas == antes_h, "no hardcore passar de nível NÃO dá vida")
	e.free()
	h.free()


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
	e.registar_pista("carta_da_mae")
	e.registar_pista("carta_da_mae")
	_ok(e.pistas.size() == 1, "registar a mesma pista duas vezes nao devia duplicar")
	e.free()


func teste_estado_habilidade_sem_duplicados() -> void:
	var e := _novo_estado()
	e.desbloquear_habilidade("salto_duplo")
	e.desbloquear_habilidade("salto_duplo")
	_ok(e.habilidades.size() == 1, "desbloquear a mesma habilidade duas vezes nao devia duplicar")
	_ok(e.tem_habilidade("salto_duplo"), "tem_habilidade devia ser verdadeiro apos desbloquear")
	e.free()


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
	e.registar_pista("pista_x")
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


## Modo hardcore: a flag sobrevive ao save, `reiniciar_campanha()` NÃO lhe
## mexe (o Game Over recomeça já em hardcore), e o tempo por mundo é
## positivo e limitado aos 4 mundos.
func teste_estado_hardcore() -> void:
	var e := _novo_estado()
	_ok(not e.hardcore, "arranque normal não é hardcore")
	e.hardcore = true
	e.reiniciar_campanha()
	_ok(e.hardcore, "reiniciar_campanha() não deve desligar o hardcore")

	# o tempo restante conta através das mortes (fica no EstadoJogo), mas
	# reinicia ao mudar de mundo ou recomeçar
	e.hardcore_tempo_restante = 42.0
	e.avancar_nivel()
	_ok(e.hardcore_tempo_restante < 0.0, "mudar de mundo repõe o relógio hardcore")
	e.hardcore_tempo_restante = 20.0
	e.reiniciar_campanha()
	_ok(e.hardcore_tempo_restante < 0.0, "reiniciar a campanha repõe o relógio hardcore")

	var copia := _novo_estado()
	e.hardcore_tempo_restante = 33.0
	copia.de_dicionario(e.para_dicionario())
	_ok(copia.hardcore, "a flag hardcore devia sobreviver ao save")
	_ok(is_equal_approx(copia.hardcore_tempo_restante, 33.0),
		"o tempo restante hardcore devia sobreviver ao save")

	e.indice_nivel = 0
	var t0: float = e.tempo_hardcore_nivel()
	e.indice_nivel = 99  # fora dos limites -> usa o último mundo
	var tn: float = e.tempo_hardcore_nivel()
	_ok(t0 > 0.0 and tn > 0.0, "o tempo hardcore de cada mundo é positivo")
	_ok(tn == e.TEMPO_HARDCORE[e.TEMPO_HARDCORE.size() - 1],
		"índice fora dos limites cai no tempo do último mundo")
	e.free()
	copia.free()


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
# Estes testes leem os .gd como TEXTO em vez de os `preload`: em modo
# `--script` os autoloads (EstadoJogo) nao existem, e `koliani.gd` /
# `demonio_base.gd` / `checkpoint.gd` referem-nos, logo nem compilam aqui.
# O que interessa e' apanhar o erro tipico: mudar um nome ou um numero de
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
func _tira_bate_certo(caminho: String, n: int, quem: String) -> int:
	if not FileAccess.file_exists(caminho):
		_ok(false, "%s: falta a tira %s" % [quem, caminho])
		return 0
	var img := Image.load_from_file(caminho)
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
	var n_niveis: int = _novo_estado().NIVEIS.size()
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
		var img := Image.load_from_file(caminho)
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
## Le'-se do CODIGO-FONTE, nao da classe: tocar em `GeradorCorredor` pelo
## nome obriga a compilar o script, que usa autoloads -- e em `--script` os
## autoloads nao existem, portanto o teste passaria EM SILENCIO sem medir
## nada. Mesma armadilha do `verifica_jornada.gd`.
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

	# Os dois tectos vêm do `chefe_base.gd` -- lidos da FONTE, não do
	# `ChefeBase.` directo: em `--script` os autoloads (`Som`, `EstadoJogo`)
	# não existem, e tocar na classe puxava a cadeia toda e enchia o log de
	# "Compile Error: Identifier not found".
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
		var img := Image.load_from_file(
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
