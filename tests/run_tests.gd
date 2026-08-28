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
	teste_estado_tres_mortes_sem_vidas()
	teste_estado_pistas_sem_duplicados()
	teste_estado_habilidade_sem_duplicados()
	teste_estado_nivel_atual_e_caminho_valido()
	teste_estado_save_ida_e_volta()

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
## save do disco) e reinicia a campanha para um ponto conhecido.
func _novo_estado() -> Node:
	var e: Node = EstadoJogoScript.new()
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
