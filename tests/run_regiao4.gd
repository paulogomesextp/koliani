extends Node
## Corredor RAPIDO so' da Regiao IV (N16-N19 + pistao/valvula): corre em ~20 s em
## vez dos ~15 min da suite inteira. NAO substitui `run_tests.tscn` (o CI corre
## esse); serve para iterar no N19.
##
##   python tools/godot_isolado.py -- --headless --path . res://tests/run_regiao4.tscn


func _ready() -> void:
	await get_tree().process_frame
	var falhas: Array[String] = []
	var blocos := {
		"N16": TestesRegion04N16.executar(),
		"N17": TestesRegion04N17.executar(),
		"N18": TestesRegion04N18.executar(),
		"pistao/valvula": TestesRegion04PistaoValvula.executar(),
		"N19": TestesRegion04N19.executar(),
		"i18n": TestesI18nSemDuplicadas.executar(),
	}
	blocos["contacto real"] = await TestesRegion04PistaoValvula.contacto(self)
	for nome in blocos:
		var f: Array[String] = blocos[nome]
		print("[regiao4] %s: %d falha(s)" % [nome, f.size()])
		falhas.append_array(f)
	for f in falhas:
		print("FALHOU: ", f)
	print("[regiao4] total %d falha(s)" % falhas.size())
	get_tree().quit(1 if falhas.size() > 0 else 0)
