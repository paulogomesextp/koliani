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
	teste_tremor_impulso_e_decaimento()
	teste_diario_entradas_e_fallback()
	teste_diario_tem_todas_as_pistas_dos_niveis()
	teste_i18n_en_tem_as_chaves_das_pistas()
	teste_i18n_ficheiros_validos()
	teste_estado_tres_mortes_sem_vidas()
	teste_estado_pistas_sem_duplicados()
	teste_estado_habilidade_sem_duplicados()
	teste_estado_nivel_atual_e_caminho_valido()
	teste_estado_save_ida_e_volta()
	teste_estado_ha_progresso()
	teste_estado_hardcore()

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
	var copia := _novo_estado()
	copia.de_dicionario(e.para_dicionario())
	_ok(copia.vidas == e.vidas, "vidas deviam sobreviver ao ida-e-volta do dicionario")
	_ok(copia.pistas == e.pistas, "pistas deviam sobreviver ao ida-e-volta do dicionario")
	_ok(copia.habilidades == e.habilidades, "habilidades deviam sobreviver ao ida-e-volta")
	e.free()
	copia.free()


## O menu inicial usa isto para decidir se mostra "Continuar". Um arranque
## limpo (campanha reiniciada) não conta como progresso; desbloquear uma
## habilidade ou avançar de mundo já conta.
func teste_estado_ha_progresso() -> void:
	var e := _novo_estado()  # reiniciar_campanha() já gravou um save limpo
	_ok(not e.ha_progresso(), "arranque limpo não devia contar como progresso")
	e.desbloquear_habilidade("salto_duplo")
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
