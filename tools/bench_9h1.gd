extends Node
## Execution 9H.1 -- DESEMPENHO depois das animações novas, da trilha e do
## tema do seletor.
##
## Mede TEMPO DE PAREDE por frame (`Time.get_ticks_usec`), não o `delta` do
## motor: o `delta` é o que o motor *diz* que passou e esconde exactamente os
## engasgos que interessam (lição da Execution 8.1).
##
## Cenas medidas: menu, seletor (Região I, com pele própria), L1, L3, L5.
## Em cada uma: 60 frames a aquecer + 240 a medir, com vsync desligado.
##
## Uso: Godot --window --screen 1 --path . res://tools/bench_9h1.tscn -- <saida.md>

const AQUECER := 60
const MEDIR := 240

const CENAS := [
	["menu", "res://scenes/ui/MenuInicial.tscn", -1],
	["seletor Regiao I", "res://scenes/ui/SeletorNiveis.tscn", 0],
	["L1 Floresta Corrompida", "res://scenes/levels/Floresta_Putrefata.tscn", 0],
	["L3 Ninho da Viuva Negra", "res://scenes/levels/Ninho_da_Viuva_Negra.tscn", 2],
	["L5 Coracao da Floresta", "res://scenes/levels/Coracao_da_Floresta.tscn", 4],
]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_correr.call_deferred(args[0] if args.size() > 0 else "res://work/execution_9h1/bench.md")


func _correr(saida: String) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var linhas: Array[String] = []
	linhas.append("# Desempenho -- Execution 9H.1")
	linhas.append("")
	linhas.append("Tempo de PAREDE por frame, %d frames medidos depois de %d a aquecer,"
		% [MEDIR, AQUECER])
	linhas.append("vsync desligado. A sonda não joga: carrega a cena e deixa-a correr.")
	linhas.append("")
	linhas.append("| cena | média (ms) | p95 (ms) | pior (ms) |")
	linhas.append("| --- | ---: | ---: | ---: |")
	for c in CENAS:
		var nome: String = c[0]
		var cam: String = c[1]
		var nivel: int = c[2]
		if not ResourceLoader.exists(cam):
			linhas.append("| %s | -- | -- | CENA EM FALTA |" % nome)
			continue
		if nivel >= 0:
			EstadoJogo.indice_nivel = nivel
		var no := (load(cam) as PackedScene).instantiate()
		add_child(no)
		if no.has_method("configurar"):
			no.call("configurar", EstadoJogo.REGIOES[maxi(0, EstadoJogo.regiao_do_nivel(
				maxi(0, nivel)))]["niveis"][0], false)
		for _i in AQUECER:
			await get_tree().process_frame
		var amostras: Array[float] = []
		var ant := Time.get_ticks_usec()
		for _i in MEDIR:
			await get_tree().process_frame
			var agora := Time.get_ticks_usec()
			amostras.append((agora - ant) / 1000.0)
			ant = agora
		amostras.sort()
		var soma := 0.0
		for v in amostras:
			soma += v
		linhas.append("| %s | %.3f | %.3f | %.3f |" % [nome, soma / amostras.size(),
			amostras[int(amostras.size() * 0.95)], amostras[amostras.size() - 1]])
		print("%-26s media %.3f ms  p95 %.3f  pior %.3f" % [nome, soma / amostras.size(),
			amostras[int(amostras.size() * 0.95)], amostras[amostras.size() - 1]])
		no.queue_free()
		await get_tree().process_frame
	var f := FileAccess.open(saida, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(linhas) + "\n")
		f.close()
		print("bench -> ", ProjectSettings.globalize_path(saida))
	get_tree().quit(0)
