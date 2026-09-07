extends "res://tests/run_tests.gd"
## Runner dirigido da Execution 3B.


func _correr_tudo() -> void:
	teste_progression_ids_niveis_e_bosses()
	teste_progression_ids_habilidades_e_coletaveis()
	teste_progression_ids_idempotencia_boss_e_recompensa()
	teste_progression_ids_invalidos()
	teste_progression_ids_resilientes_a_renames()
	teste_save_v2_migration_progressao()
	if _falhas.is_empty():
		print("OK -- progression IDs: 6 testes passaram")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			printerr("FALHOU: ", falha)
		printerr("%d falha(s)" % _falhas.size())
		get_tree().quit(1)
