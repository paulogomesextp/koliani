extends "res://tests/run_tests.gd"
## Runner dirigido da Execution 3C.


func _correr_tudo() -> void:
	teste_level_session_begin()
	teste_level_session_stable_checkpoint_identity()
	teste_level_session_checkpoint_activation_repeated()
	teste_level_session_death_respawn_contract()
	teste_level_session_save_close_load()
	teste_level_session_invalid_checkpoint_fallback()
	teste_level_session_level_completion()
	teste_level_session_boss_persistence()
	teste_level_session_reward_idempotence()
	teste_save_v3_migration_level_session()
	teste_save_v4_migration_remove_hardcore()
	if _falhas.is_empty():
		print("OK -- level session: 11 testes passaram")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			printerr("FALHOU: ", falha)
		printerr("%d falha(s)" % _falhas.size())
		get_tree().quit(1)
