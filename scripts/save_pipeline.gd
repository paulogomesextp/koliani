class_name SavePipeline
extends RefCounted
## Gravação do progresso FORA da thread principal (Execution 8.1D).
##
## O contrato de integridade não muda: quem escreve continua a ser
## `SaveFoundation.escrever_seguro()` -- TEMP + verificação + backup validado +
## promoção + releitura final. O que muda é ONDE corre. Antes o jogo parava
## ~2 s a cada checkpoint e a cada dano; agora a thread principal só tira um
## instantâneo imutável e sai.
##
## COALESCÊNCIA (last-write-wins). No máximo há:
##   1 escrita ATIVA (a que o worker está a fazer)
## + 1 instantâneo PENDENTE (o último pedido que chegou entretanto).
## Um pedido novo SUBSTITUI o pendente -- nunca cresce uma fila de disco. O
## pendente é sempre o estado mais recente do jogador, por isso o que acaba
## no disco é sempre o último pedido, nunca um mais velho. Os instantâneos
## intermédios que forem substituídos NÃO chegam ao disco: são estados que já
## foram ultrapassados pelo jogo, e o save é um retrato, não um diário.
##
## THREAD SAFETY. O worker só toca em:
##   - o Dictionary do instantâneo, que é um deep copy feito na thread
##     principal e a partir daí é dele;
##   - `SaveFoundation` / `ProgressionIDs`, que são `static` e sem estado
##     mutável partilhado (o cache do manifesto é aquecido na thread
##     principal antes de o worker nascer e é protegido por Mutex);
##   - FileAccess/DirAccess próprios, criados e fechados dentro da thread.
## NUNCA toca em SceneTree, em Nodes nem no estado vivo do EstadoJogo.
##
## PLATAFORMAS. Onde não há threads (export Web/PWA, `thread_support=false`),
## `pedir()` grava logo em modo síncrono -- exatamente o comportamento e o
## contrato de antes desta Execution.

const _SAVE := preload("res://scripts/save_foundation.gd")

var _primary: String
var _backup: String
var _temp: String
var _total_niveis: int

var _mutex := Mutex.new()
var _semaforo := Semaphore.new()
var _thread: Thread = null

# --- guardados pelo _mutex -------------------------------------------------
var _pendente: Dictionary = {}
var _tem_pendente := false
var _a_gravar := false
var _sair := false
var _pedidos := 0
var _escritas := 0
var _coalescidos := 0
var _pendentes_max := 0
var _ultimo_erro := ""
var _ultima_mensagem := ""
var _falhas := 0
var _erro_ja_avisado := ""
var _duracao_ultima_ms := 0.0
var _duracao_pior_ms := 0.0
# ---------------------------------------------------------------------------


func _init(primary: String, backup: String, temp: String, total_niveis: int) -> void:
	_primary = primary
	_backup = backup
	_temp = temp
	_total_niveis = total_niveis
	if OS.can_use_threads():
		_thread = Thread.new()
		_thread.start(_ciclo_worker, Thread.PRIORITY_LOW)


func tem_thread() -> bool:
	return _thread != null


## Chamado pela thread principal. Recebe um instantâneo JÁ imutável (ver
## `EstadoJogo.instantaneo()`), guarda-o como pendente e volta logo.
func pedir(instantaneo: Dictionary) -> bool:
	if _thread == null:
		return _gravar(instantaneo).get("ok", false)
	_mutex.lock()
	_pedidos += 1
	if _tem_pendente:
		_coalescidos += 1
	_pendente = instantaneo
	_tem_pendente = true
	var em_voo := (1 if _tem_pendente else 0) + (1 if _a_gravar else 0)
	_pendentes_max = maxi(_pendentes_max, em_voo)
	_mutex.unlock()
	_semaforo.post()
	return true


## True enquanto houver escrita a decorrer ou instantâneo por gravar.
func ativo() -> bool:
	if _thread == null:
		return false
	_mutex.lock()
	var v := _a_gravar or _tem_pendente
	_mutex.unlock()
	return v


## Espera que a fila esvazie SEM matar a thread. Usada nas transições em que
## se quer a certeza de que o disco tem o estado (mudança de nível, saída).
## Limite: 1 escrita ativa + 1 pendente, por construção da coalescência.
func esvaziar(limite_ms := 8000) -> bool:
	if _thread == null:
		return true
	var fim := Time.get_ticks_msec() + limite_ms
	while ativo():
		if Time.get_ticks_msec() > fim:
			push_warning("SavePipeline: esvaziar() excedeu %d ms" % limite_ms)
			return false
		OS.delay_msec(2)
	return true


## Fecho ordeiro: drena o que falta e junta a thread. Idempotente.
func parar() -> void:
	if _thread == null:
		return
	_mutex.lock()
	_sair = true
	_mutex.unlock()
	_semaforo.post()
	_thread.wait_to_finish()
	_thread = null


func estado() -> Dictionary:
	_mutex.lock()
	var d := {
		"pedidos": _pedidos,
		"escritas": _escritas,
		"coalescidos": _coalescidos,
		"pendentes_max": _pendentes_max,
		"falhas": _falhas,
		"ultimo_erro": _ultimo_erro,
		"ultima_mensagem": _ultima_mensagem,
		"duracao_ultima_ms": _duracao_ultima_ms,
		"duracao_pior_ms": _duracao_pior_ms,
		"a_gravar": _a_gravar,
		"tem_pendente": _tem_pendente,
		"com_thread": true,
	}
	_mutex.unlock()
	return d


## --- daqui para baixo corre NA THREAD DE FUNDO ----------------------------

func _ciclo_worker() -> void:
	while true:
		_semaforo.wait()
		# Drena tudo o que houver antes de voltar a dormir. Um pedido que
		# chegue a meio de uma escrita é apanhado nesta mesma volta.
		while true:
			_mutex.lock()
			var tinha := _tem_pendente
			var instantaneo: Dictionary = _pendente
			_pendente = {}
			_tem_pendente = false
			_a_gravar = tinha
			_mutex.unlock()
			if not tinha:
				break
			_gravar(instantaneo)
			_mutex.lock()
			_a_gravar = false
			_mutex.unlock()
		_mutex.lock()
		var sair := _sair
		_mutex.unlock()
		if sair:
			break


## O ÚNICO sítio que escreve. Igual em fundo e em modo síncrono -- é por isso
## que o contrato de integridade não se divide em dois caminhos.
func _gravar(instantaneo: Dictionary) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var resultado := _SAVE.escrever_seguro(
		instantaneo, _primary, _backup, _temp, _total_niveis)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	var ok: bool = resultado.get("ok", false)
	var erro := str(resultado.get("error", ""))
	var mensagem := str(resultado.get("message", ""))

	_mutex.lock()
	_escritas += 1
	_duracao_ultima_ms = ms
	_duracao_pior_ms = maxf(_duracao_pior_ms, ms)
	_ultimo_erro = erro
	_ultima_mensagem = mensagem
	var avisar := false
	if not ok:
		_falhas += 1
		# Não spammar: um código de erro novo avisa uma vez; a repetição do
		# mesmo erro fica só na contagem.
		if _erro_ja_avisado != erro:
			_erro_ja_avisado = erro
			avisar = true
	else:
		_erro_ja_avisado = ""
	_mutex.unlock()

	if avisar:
		push_warning("Nao consegui gravar o progresso (%s): %s" % [erro, mensagem])
	return resultado
