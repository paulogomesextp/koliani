extends Node
## Mede quanto custa GRAVAR o save, na thread principal.
##
##   godot --headless --path . res://tools/verifica_gravar.tscn
##
## O Paulo: "cada vez que levo um projetil de um mob, ou passo num
## checkpoint, fico com freeze". As duas coisas gravam:
## `EstadoJogo.ativar_checkpoint()` chama `guardar()`, e `perder_vida()`
## tambem. O `guardar()` faz escrita segura -- TEMP + flush + backup +
## rename -- tudo sincrono, na thread principal. No Windows, com o antivirus
## a inspeccionar cada escrita em %APPDATA%, isso custa caro.

func _ready() -> void:
	# NAO mexer no save real do jogador: grava para caminhos proprios.
	var base := "user://perf/bench_save"
	DirAccess.make_dir_recursive_absolute("user://perf")
	var primary := base + ".json"
	var backup := base + ".bak"
	var temp := base + ".tmp"

	print("=== custo de gravar o save (thread principal) ===")
	var tempos: Array[float] = []
	for i in 12:
		var t := Time.get_ticks_usec()
		EstadoJogo.guardar_em(primary, backup, temp)
		var ms := (Time.get_ticks_usec() - t) / 1000.0
		tempos.append(ms)
		print("  grava #%2d: %8.1f ms   (~%.1f frames a 165 Hz)" % [
			i + 1, ms, ms / 6.06])

	tempos.sort()
	var soma := 0.0
	for x in tempos:
		soma += x
	print("")
	print("mediana=%.1f ms   media=%.1f ms   pior=%.1f ms" % [
		tempos[tempos.size() / 2], soma / tempos.size(), tempos[tempos.size() - 1]])
	print("")
	print("Cada checkpoint e cada vida perdida paga isto, de uma vez, no frame.")
	get_tree().quit(0)
