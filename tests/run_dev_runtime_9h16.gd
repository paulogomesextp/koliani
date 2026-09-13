extends Node
## QA dirigido com input sintético; não substitui percurso humano no EXE.

func _ready() -> void:
	provar.call_deferred()

func quadros(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func provar() -> void:
	assert("9h16" in OS.get_user_data_dir().to_lower())
	var normal := EstadoJogo.para_dicionario().duplicate(true)
	EstadoJogo.ativar_modo_dev()
	for indice in [0, 19, 49, 99]:
		EstadoJogo.indice_nivel = indice
		EstadoJogo.iniciar_sessao_nivel(true)
		var cena = load("res://scenes/Main.tscn").instantiate()
		add_child(cena)
		await quadros(30)
		var k = get_tree().get_first_node_in_group("koliani")
		assert(k != null and k.vida == k._vida_max())
		assert(not k._voando)
		assert(k.alternar_voo())
		var antes: Vector2 = k.global_position
		Input.action_press("mover_direita")
		Input.action_press("mirar_cima")
		await quadros(8)
		Input.action_release("mover_direita")
		Input.action_release("mirar_cima")
		assert(k.global_position.x > antes.x and k.global_position.y < antes.y)
		assert(not k.alternar_voo())
		k._invulneravel = 0.0
		k.receber_dano(100000, -1.0)
		assert(k.vida == k._vida_max() and not k._a_morrer)
		assert(k._hurt_t > 0.0 and k._invulneravel > 0.0)
		await quadros(8)
		cena.queue_free()
		await quadros(3)
		print("9H16 DEV RUNTIME: L%d PASS input voo/dano/spawn" % (indice + 1))
	EstadoJogo.desativar_modo_dev()
	assert(EstadoJogo.para_dicionario() == normal)
	get_tree().quit(0)
