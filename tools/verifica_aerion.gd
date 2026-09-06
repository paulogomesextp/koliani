extends SceneTree
## Regressão: Aerion media o chão antes da sincronização da física e
## guardava o valor de recurso (494), embora a arena estivesse a 240.
## Uso: Godot --headless --script res://tools/verifica_aerion.gd

var falhas := 0

func _init() -> void:
	await process_frame
	var estado := root.get_node("EstadoJogo")
	estado.modo_teste = true
	estado.indice_nivel = 11
	estado.checkpoint = Vector2.ZERO
	var cena: PackedScene = load("res://scenes/levels/Torre_dos_Ventos.tscn")
	var nivel := cena.instantiate()
	root.add_child(nivel)
	await create_timer(0.5).timeout
	var chefe := nivel.get_node("Chefe")
	_verificar(is_equal_approx(float(chefe.get("_chao_cache")), 240.0),
		"chão real da arena, sem guardar o valor provisório")
	_verificar(chefe.position.y < 240.0, "Aerion paira acima da plataforma")
	# Congela a jogadora na arena para medir o pisão completo sem danos
	# nem mortes alterarem a cena durante a bancada.
	var kol := get_first_node_in_group("koliani")
	kol.set_physics_process(false)
	kol.set("collision_layer", 0)
	kol.position = Vector2(650, 210)
	chefe.set("_fase", 8)  # STOMP_TEL
	chefe.set("_t", 0.0)
	await create_timer(1.5).timeout
	_verificar(is_equal_approx(chefe.position.y, 196.0),
		"pisão termina sobre o chão real da arena")
	nivel.queue_free()
	await create_timer(0.2).timeout
	# Coordenadas negativas são válidas: o sinal de Y não indica falha.
	estado.checkpoint = Vector2.ZERO
	var alto := cena.instantiate()
	alto.set("corredor", false)
	alto.set("alongar_plataformas", false)
	alto.position.y = -600.0
	root.add_child(alto)
	await create_timer(0.5).timeout
	var chefe_alto := alto.get_node("Chefe")
	_verificar(is_equal_approx(float(chefe_alto.get("_chao_cache")), -360.0),
		"arena acima da origem também tem altura válida")
	alto.queue_free()
	await create_timer(0.2).timeout
	print("Aerion: %d falhas" % falhas)
	quit(0 if falhas == 0 else 1)

func _verificar(condicao: bool, descricao: String) -> void:
	print("%s: %s" % ["OK" if condicao else "FALHOU", descricao])
	if not condicao:
		falhas += 1
