extends SceneTree
## Corredor de testes headless, sem dependencias externas (sem GUT).
##
##   godot --headless --script res://tests/run_tests.gd
##
## Sai com codigo 1 se algum teste falhar -- o CI (.github/workflows/ci.yml)
## usa isso para marcar o build como vermelho. Acrescenta testes novos como
## metodos `teste_*` e chama-os em `_correr_tudo`.

var _falhas: Array[String] = []


func _initialize() -> void:
	# adiado uma vez para garantir que os autoloads (EstadoJogo) ja estao
	# registados na arvore antes de os tocar
	call_deferred("_correr_tudo")


func _correr_tudo() -> void:
	teste_movimento_salto_com_coyote()
	teste_movimento_corte_de_salto()
	teste_movimento_anda_para_a_direita()
	teste_estado_tres_mortes_sem_vidas()
	teste_estado_pistas_sem_duplicados()
	teste_estado_habilidade_sem_duplicados()
	teste_estado_nivel_atual_e_caminho_valido()

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


# --- Movimento (logica pura) -------------------------------------------------

const DT := 1.0 / 60.0

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


# --- EstadoJogo ------------------------------------------------------

func teste_estado_tres_mortes_sem_vidas() -> void:
	EstadoJogo.reiniciar_campanha()
	EstadoJogo.perder_vida()
	EstadoJogo.perder_vida()
	EstadoJogo.perder_vida()
	_ok(EstadoJogo.sem_vidas(), "3 vidas perdidas deviam deixar sem_vidas() verdadeiro")


func teste_estado_pistas_sem_duplicados() -> void:
	EstadoJogo.reiniciar_campanha()
	EstadoJogo.registar_pista("carta_da_mae")
	EstadoJogo.registar_pista("carta_da_mae")
	_ok(EstadoJogo.pistas.size() == 1, "registar a mesma pista duas vezes nao devia duplicar")


func teste_estado_habilidade_sem_duplicados() -> void:
	EstadoJogo.reiniciar_campanha()
	EstadoJogo.desbloquear_habilidade("salto_duplo")
	EstadoJogo.desbloquear_habilidade("salto_duplo")
	_ok(EstadoJogo.habilidades.size() == 1, "desbloquear a mesma habilidade duas vezes nao devia duplicar")
	_ok(EstadoJogo.tem_habilidade("salto_duplo"), "tem_habilidade devia ser verdadeiro apos desbloquear")


func teste_estado_nivel_atual_e_caminho_valido() -> void:
	EstadoJogo.reiniciar_campanha()
	var caminho := EstadoJogo.caminho_nivel_atual()
	_ok(caminho.begins_with("res://"), "caminho do nivel atual devia comecar por res://")
	EstadoJogo.avancar_nivel()  # so avanca se houver proximo; nao pode ir fora dos limites
	_ok(EstadoJogo.indice_nivel >= 0 and EstadoJogo.indice_nivel < EstadoJogo.NIVEIS.size(),
		"indice_nivel devia manter-se dentro dos limites de NIVEIS")
