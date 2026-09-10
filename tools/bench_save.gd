extends Node
## Bancada do custo de gravar o progresso (Execution 8.1D).
##
##   godot --headless --path . res://tools/bench_save.tscn
##
## Mede TEMPO DE PAREDE (`Time.get_ticks_usec`) -- o `delta` do motor mente
## quando a thread principal fica presa em I/O. Ver
## docs/execution_8_1c_save_freeze.md.
##
## Mede tres coisas separadas:
##   1. `guardar_em()` sincrono   -- a baseline que engasgava o jogo;
##   2. o pedido `guardar()`      -- o que a thread principal paga agora;
##   3. a escrita em pano de fundo -- o que o worker leva a fazer o mesmo.

const _SAVE := preload("res://scripts/save_foundation.gd")
const _IDS := preload("res://scripts/progression_ids.gd")
const AMOSTRAS := 9

var _estado: Node = null


func _ready() -> void:
	call_deferred("_correr")


func _correr() -> void:
	_estado = (load("res://scripts/estado_jogo.gd") as GDScript).new()
	add_child(_estado)
	_estado.modo_teste = false
	_estado.vidas = 4
	_estado.essencia = 123

	_medir_sincrono()
	_medir_partes()
	await _medir_pedido()
	get_tree().quit(0)


func _base() -> String:
	return "res://work/bench_save.json"


func _limpar() -> void:
	for sufixo in ["", ".bak", ".tmp", ".bak.tmp", ".tmp.restore"]:
		var c := _base() + sufixo
		if FileAccess.file_exists(c):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(c))


func _mediana(v: Array[float]) -> float:
	var c: Array[float] = v.duplicate()
	c.sort()
	return c[c.size() / 2]


func _medir_sincrono() -> void:
	_limpar()
	var amostras: Array[float] = []
	for i in AMOSTRAS:
		_estado.essencia = 100 + i
		var t0 := Time.get_ticks_usec()
		_estado.guardar_em(_base(), _base() + ".bak", _base() + ".tmp")
		amostras.append((Time.get_ticks_usec() - t0) / 1000.0)
	amostras.sort()
	print("SINCRONO guardar_em(): mediana=%.1f ms  pior=%.1f ms  melhor=%.1f ms" % [
		_mediana(amostras), amostras[-1], amostras[0]])
	_limpar()


func _medir_partes() -> void:
	## Onde e' que os ~2 s se gastam. `escrever_seguro` faz seis validacoes
	## completas e cada validacao releem o manifesto dos 100 niveis do disco.
	var dados: Dictionary = _estado.para_dicionario()
	var total: int = _estado.NIVEIS.size()

	var t0 := Time.get_ticks_usec()
	for i in 20:
		_IDS.identidades()
	var por_identidades := (Time.get_ticks_usec() - t0) / 1000.0 / 20.0
	print("  parte: _IDS.identidades() (le+parseia o manifesto) = %.2f ms por chamada" % por_identidades)

	t0 = Time.get_ticks_usec()
	for i in 5:
		_SAVE.processar(dados, total)
	print("  parte: processar()/validar completo = %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0 / 5.0))

	t0 = Time.get_ticks_usec()
	for i in 5:
		JSON.stringify(dados, "\t")
	print("  parte: JSON.stringify = %.2f ms" % ((Time.get_ticks_usec() - t0) / 1000.0 / 5.0))

	_limpar()
	var texto := JSON.stringify(dados, "\t")
	t0 = Time.get_ticks_usec()
	for i in 5:
		var f := FileAccess.open(_base() + ".tmp", FileAccess.WRITE)
		f.store_string(texto)
		f.flush()
		f.close()
	print("  parte: escrita crua do TEMP no disco = %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0 / 5.0))
	_limpar()


func _medir_pedido() -> void:
	if not _estado.has_method("guardar"):
		return
	var assincrono: bool = _estado.get("save_assincrono") if _estado.has_method("save_ativo") else false
	if not _estado.has_method("save_ativo"):
		print("PEDIDO guardar(): ainda sincrono (pipeline de fundo por implementar)")
		return
	_estado.set("CAMINHO_SAVE_OVERRIDE", "")
	var amostras: Array[float] = []
	for i in AMOSTRAS:
		_estado.essencia = 200 + i
		var t0 := Time.get_ticks_usec()
		_estado.guardar()
		amostras.append((Time.get_ticks_usec() - t0) / 1000.0)
		while _estado.save_ativo():
			await get_tree().process_frame
	amostras.sort()
	print("PEDIDO guardar() (thread principal): mediana=%.2f ms  pior=%.2f ms" % [
		_mediana(amostras), amostras[-1]])
