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
	teste_estado_pistas_sem_duplicados()
	teste_estado_habilidade_sem_duplicados()
	teste_estado_nivel_atual_e_caminho_valido()
	teste_estado_save_ida_e_volta()
	teste_estado_ha_progresso()
	teste_estado_hardcore()
	teste_estado_regioes_e_conclusao()
	teste_estado_mapa_desbloqueio()
	teste_estado_modo_dev()

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
		_ok(k.begins_with("boss."), "chave de chefe mal formada: '%s'" % k)
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


## Equipamento: 15 armas + 15 armaduras; os níveis de desbloqueio alternam
## (arma nos ímpares, armadura nos pares); `recompensa_do_nivel` mapeia o
## índice do nível para o item certo; e o en.json tem os nomes todos.
func teste_equipamento_dados() -> void:
	_ok(Equipamento.ARMAS.size() == 15, "deviam ser 15 armas")
	_ok(Equipamento.ARMADURAS.size() == 15, "deviam ser 15 armaduras")
	for i in Equipamento.ARMAS.size():
		_ok(int(Equipamento.ARMAS[i]["nivel"]) == 2 * i + 1,
			"a arma %d devia desbloquear no nível %d" % [i, 2 * i + 1])
		_ok(int(Equipamento.ARMADURAS[i]["nivel"]) == 2 * i + 2,
			"a armadura %d devia desbloquear no nível %d" % [i, 2 * i + 2])
		# dano das armas sobe; vida_bonus das armaduras sobe
		if i > 0:
			_ok(int(Equipamento.ARMAS[i]["dano"]) >= int(Equipamento.ARMAS[i - 1]["dano"]),
				"o dano das armas devia ser não-decrescente")
			_ok(int(Equipamento.ARMADURAS[i]["vida_bonus"]) >= int(Equipamento.ARMADURAS[i - 1]["vida_bonus"]),
				"o vida_bonus das armaduras devia ser não-decrescente")

	var r0 := Equipamento.recompensa_do_nivel(0)
	_ok(r0.get("tipo") == "arma" and r0.get("id") == Equipamento.ARMAS[0]["id"],
		"acabar o nível 1 (idx 0) dá a 1.ª arma")
	var r1 := Equipamento.recompensa_do_nivel(1)
	_ok(r1.get("tipo") == "armadura" and r1.get("id") == Equipamento.ARMADURAS[0]["id"],
		"acabar o nível 2 (idx 1) dá a 1.ª armadura")
	var r28 := Equipamento.recompensa_do_nivel(28)
	_ok(r28.get("tipo") == "arma" and r28.get("id") == Equipamento.ARMAS[14]["id"],
		"acabar o nível 29 (idx 28) dá a 15.ª arma")
	var r29 := Equipamento.recompensa_do_nivel(29)
	_ok(r29.get("tipo") == "armadura" and r29.get("id") == Equipamento.ARMADURAS[14]["id"],
		"acabar o nível 30 (idx 29) dá a 15.ª armadura")
	_ok(Equipamento.recompensa_do_nivel(99).is_empty(), "índice fora de alcance não dá nada")

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

	e.marcar_nivel_concluido(0)  # nível 1 -> 1.ª arma, equipada
	_ok(e.armas.size() == 1, "acabar o nível 1 dá 1 arma")
	_ok(e.arma_equipada == Equipamento.ARMAS[0]["id"], "a arma nova é equipada logo")
	_ok(e.dano_ataque() == int(Equipamento.ARMAS[0]["dano"]), "dano_ataque segue a arma equipada")

	e.marcar_nivel_concluido(1)  # nível 2 -> 1.ª armadura
	_ok(e.armaduras.size() == 1, "acabar o nível 2 dá 1 armadura")
	_ok(e.armadura_equipada == Equipamento.ARMADURAS[0]["id"], "armadura nova equipada")

	e.marcar_nivel_concluido(0)  # repetir não duplica
	_ok(e.armas.size() == 1, "reconcluir o nível não duplica o prémio")

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
	e.perder_vida()
	e.perder_vida()
	e.perder_vida()
	_ok(e.sem_vidas(), "3 vidas perdidas deviam deixar sem_vidas() verdadeiro")
	e.free()


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
	e.avancar_nivel()  # so avanca se houver proximo; nao pode ir fora dos limites
	_ok(e.indice_nivel >= 0 and e.indice_nivel < e.NIVEIS.size(),
		"indice_nivel devia manter-se dentro dos limites de NIVEIS")
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
	_ok(e.REGIOES.size() == 6, "a campanha-alvo tem 6 regiões (docs/niveis.md)")
	# todo o nível de NIVEIS tem de estar nalguma região
	for i in e.NIVEIS.size():
		_ok(e.regiao_do_nivel(i) >= 0, "o nível %d devia pertencer a uma região" % i)

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
