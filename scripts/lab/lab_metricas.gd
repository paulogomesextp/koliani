class_name LabMetricas
extends Node
## COMBAT LAB v1 -- registo de eventos (golpes, hits, energia, perfect dodge, mortes). Os actores
## do lab chamam `get_tree().call_group("lab_metricas", "registar", nome, dados)`.

var eventos: Array[Dictionary] = []
var imprimir := false


func _ready() -> void:
	add_to_group("lab_metricas")


func registar(nome: String, dados := {}) -> void:
	var e := {"t": Time.get_ticks_msec() / 1000.0, "nome": nome, "d": dados}
	eventos.append(e)
	if imprimir:
		print("[LAB] %s %s" % [nome, str(dados)])


func limpar() -> void:
	eventos.clear()


func contar(nome: String) -> int:
	var n := 0
	for e in eventos:
		if e["nome"] == nome:
			n += 1
	return n


func soma(nome: String, campo: String) -> float:
	var s := 0.0
	for e in eventos:
		if e["nome"] == nome:
			s += float((e["d"] as Dictionary).get(campo, 0.0))
	return s


func soma_energia_por_fonte() -> Dictionary:
	var r := {}
	for e in eventos:
		if e["nome"] == "energia":
			var f: String = (e["d"] as Dictionary)["fonte"]
			r[f] = float(r.get(f, 0.0)) + float((e["d"] as Dictionary)["ganho"])
	return r


func resumo() -> String:
	var linhas: Array[String] = []
	linhas.append("golpes lab: %d | hits: %d | PD: %d | dano total: %d" % [
		contar("golpe"), contar("hit"), contar("perfect_dodge"), int(soma("hit", "dano"))])
	linhas.append("energia por fonte: %s" % str(soma_energia_por_fonte()))
	for e in eventos:
		if e["nome"] == "morreu":
			linhas.append("morreu %s ttk=%.2fs" % [e["d"]["alvo"], float(e["d"]["ttk"])])
	return "\n".join(linhas)
