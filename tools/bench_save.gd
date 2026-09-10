extends Node
## Bancada do custo de gravar o progresso (Execution 8.1D/8.1E).
##
##   godot --headless --path . res://tools/bench_save.tscn
##
## Antes de a correr:
##   godot --headless --path . --check-only --script res://tools/bench_save.gd
## Um erro de parse NAO faz o motor estoirar -- ele fica a correr para sempre
## com o log vazio. O `--check-only` sai em segundos e diz logo. Custou duas
## corridas de 10 minutos na 8.1D; ver docs/execution_8_1d_*.md.
##
## Mede TEMPO DE PAREDE (`Time.get_ticks_usec`). O `delta` do motor mente
## quando a thread principal fica presa em I/O.
##
## Corre o mesmo trabalho duas vezes -- com o cache do manifesto DESLIGADO
## (comportamento pre-8.1E) e LIGADO -- dentro do mesmo processo. E' o teste
## de isolamento: se o tempo colapsa, a causa esta provada.

const _SAVE := preload("res://scripts/save_foundation.gd")
const _IDS := preload("res://scripts/progression_ids.gd")
const AMOSTRAS := 9
const LIMITE_SEGUNDOS := 240.0

var _estado: Node = null
var _t_arranque := 0.0


func _ready() -> void:
	_t_arranque = Time.get_ticks_msec() / 1000.0
	call_deferred("_correr")


func _process(_delta: float) -> void:
	# Trava de seguranca: uma bancada que se pendura nao volta a comer uma
	# sessao inteira.
	if Time.get_ticks_msec() / 1000.0 - _t_arranque > LIMITE_SEGUNDOS:
		printerr("BENCH ABORTADA: passou de %.0f s" % LIMITE_SEGUNDOS)
		get_tree().quit(2)


func _correr() -> void:
	_estado = (load("res://scripts/estado_jogo.gd") as GDScript).new()
	add_child(_estado)
	_estado.modo_teste = false
	_estado.vidas = 4
	_estado.essencia = 123
	# Um save realista: alguns niveis feitos, para o validador ter trabalho.
	for indice: int in [0, 1, 2, 3, 4]:
		_estado._registar_chefe_do_nivel_sem_guardar(indice)
		_estado._registar_recompensa_do_nivel_sem_guardar(indice)
		if indice not in _estado.concluidos:
			_estado.concluidos.append(indice)

	print("=========== EXECUTION 8.1E -- onde vao os ~2 s ===========")
	var antes := _medir("ANTES (cache do manifesto DESLIGADO)", false)
	var depois := _medir("DEPOIS (cache do manifesto LIGADO)", true)

	print("")
	print("=========== VEREDICTO ===========")
	var m_antes: float = antes["mediana"]
	var m_depois: float = depois["mediana"]
	print("guardar_em() mediana: %.1f ms -> %.1f ms  (%.1fx mais rapido)" % [
		m_antes, m_depois, m_antes / maxf(m_depois, 0.001)])
	print("leituras do manifesto por gravacao: %.0f -> %.0f" % [
		antes["leituras"], depois["leituras"]])
	print("parses do manifesto por gravacao:   %.0f -> %.0f" % [
		antes["parses"], depois["parses"]])
	print("chamadas identidades() por gravacao: %.0f -> %.0f" % [
		antes["identidades"], depois["identidades"]])
	get_tree().quit(0)


func _base() -> String:
	return "res://work/bench_save.json"


func _limpar() -> void:
	for sufixo: String in ["", ".bak", ".tmp", ".bak.tmp", ".tmp.restore"]:
		var caminho: String = _base() + sufixo
		if FileAccess.file_exists(caminho):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))


func _mediana(v: Array[float]) -> float:
	var c: Array[float] = v.duplicate()
	c.sort()
	return c[c.size() / 2]


func _medir(titulo: String, com_cache: bool) -> Dictionary:
	print("")
	print("--- %s ---" % titulo)
	_IDS.usar_cache(com_cache)
	if com_cache:
		_IDS.aquecer()
	_limpar()

	# --- total, e contadores POR GRAVACAO -------------------------------
	var amostras: Array[float] = []
	_IDS.zerar_diagnostico()
	for i: int in AMOSTRAS:
		_estado.essencia = 100 + i
		var t0 := Time.get_ticks_usec()
		_estado.guardar_em(_base(), _base() + ".bak", _base() + ".tmp")
		amostras.append((Time.get_ticks_usec() - t0) / 1000.0)
	var diag: Dictionary = _IDS.diagnostico()
	amostras.sort()
	var mediana := _mediana(amostras)
	print("TOTAL guardar_em(): mediana=%.1f ms  pior=%.1f ms  melhor=%.1f ms" % [
		mediana, amostras[-1], amostras[0]])
	var leituras := float(diag["leituras_disco"]) / float(AMOSTRAS)
	var parses := float(diag["parses_json"]) / float(AMOSTRAS)
	var chamadas := float(diag["chamadas_identidades"]) / float(AMOSTRAS)
	print("  por gravacao: identidades()=%.0f  leituras do disco=%.0f  parses JSON=%.0f" % [
		chamadas, leituras, parses])

	# --- etapas ----------------------------------------------------------
	var dados: Dictionary = _estado.para_dicionario()
	var total: int = _estado.NIVEIS.size()
	var texto := JSON.stringify(dados, "\t")

	print("  etapa A  para_dicionario()      = %.2f ms" % _cronometrar(
		func() -> void: _estado.para_dicionario(), 10))
	print("  etapa B  JSON.stringify         = %.2f ms" % _cronometrar(
		func() -> void: JSON.stringify(dados, "\t"), 10))
	print("  etapa C  identidades() (1x)     = %.3f ms" % _cronometrar(
		func() -> void: _IDS.identidades(), 40))
	print("  etapa D+E le+parseia manifesto  = %.3f ms" % _cronometrar(
		func() -> void: JSON.parse_string(
			FileAccess.get_file_as_string(_IDS.CAMINHO_MANIFESTO)), 40))
	print("  etapa F  processar()/validar    = %.1f ms" % _cronometrar(
		func() -> void: _SAVE.processar(dados, total), 5))
	print("  etapa G  escrita crua do TEMP   = %.2f ms" % _cronometrar(
		func() -> void: _escrever_cru(_base() + ".probe", texto), 10))
	print("  etapa H/I/J/M ler()+validar     = %.1f ms" % _cronometrar(
		func() -> void: _SAVE.ler(_base(), total), 5))
	print("  etapa L  renomear/apagar        = %.2f ms" % _cronometrar(
		func() -> void: _mexer_ficheiro(), 10))

	_limpar()
	if FileAccess.file_exists(_base() + ".probe"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_base() + ".probe"))
	return {
		"mediana": mediana, "pior": amostras[-1],
		"leituras": leituras, "parses": parses, "identidades": chamadas,
	}


func _cronometrar(f: Callable, repeticoes: int) -> float:
	var t0 := Time.get_ticks_usec()
	for i: int in repeticoes:
		f.call()
	return (Time.get_ticks_usec() - t0) / 1000.0 / float(repeticoes)


func _escrever_cru(caminho: String, texto: String) -> void:
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(texto)
	f.flush()
	f.close()


func _mexer_ficheiro() -> void:
	var a := _base() + ".mv1"
	var b := _base() + ".mv2"
	_escrever_cru(a, "x")
	DirAccess.rename_absolute(
		ProjectSettings.globalize_path(a), ProjectSettings.globalize_path(b))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(b))
