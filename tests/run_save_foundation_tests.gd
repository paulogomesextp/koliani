extends "res://tests/run_tests.gd"
## Runner dirigido da Execution 3A. Reutiliza exatamente os mesmos testes que
## entram na suite completa, mas permite iteração sem repetir toda a baseline.


func _correr_tudo() -> void:
	teste_save_fresh_write_load()
	teste_save_roundtrip_campos()
	teste_save_legacy_migration()
	teste_save_migration_sequencial()
	teste_save_v2_migration_progressao()
	teste_save_v4_migration_remove_hardcore()
	teste_save_primary_corrupto_backup_valido()
	teste_save_escrita_nova_invalida_preserva_anterior()
	teste_save_temp_invalido_nao_promovido()
	teste_save_versao_futura_preservada()
	teste_save_migration_invalida_rejeitada()
	if _falhas.is_empty():
		print("OK -- save foundation: 11 testes passaram")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			printerr("FALHOU: ", falha)
		printerr("%d falha(s)" % _falhas.size())
		get_tree().quit(1)
