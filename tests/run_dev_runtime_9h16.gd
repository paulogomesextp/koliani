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
		if indice == 0:
			var barra = cena.get_node("DevBarra")
			barra._abrir()
			for alvo in range(100):
				barra._seletor.configurar(alvo, false)
				assert(barra._seletor._sel == alvo)
				assert(not barra._seletor._respeitar_bloqueio)
				assert(not barra._seletor._nome_nivel(alvo).is_empty())
			barra._fechar()
			print("9H16 DEV SELETOR: 100 niveis com nome e sem bloqueio PASS")
		assert(k != null and k.vida == k._vida_max())
		assert(k._vida_max() == k.VIDA_MAXIMA + EstadoJogo.vida_bonus_armadura())
		assert(not k._voando)
		if indice == 0 and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(
				"C:/Temp/koliani-9h16-b2-ui.png")
		assert(k.alternar_voo())
		var antes: Vector2 = k.global_position
		Input.action_press("mover_direita")
		Input.action_press("mirar_cima")
		await quadros(8)
		Input.action_release("mover_direita")
		Input.action_release("mirar_cima")
		assert(k.global_position.x > antes.x and k.global_position.y < antes.y)
		antes = k.global_position
		Input.action_press("mover_esquerda")
		Input.action_press("mirar_baixo")
		await quadros(8)
		Input.action_release("mover_esquerda")
		Input.action_release("mirar_baixo")
		assert(k.global_position.x < antes.x and k.global_position.y > antes.y)
		k._hurt_t = 0.0
		k._atualizar_anim()
		assert(k._corpo.animation == "idle")
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
	var seletor = load("res://scenes/ui/SeletorNiveis.tscn").instantiate()
	add_child(seletor)
	seletor.configurar(99, true)
	assert(seletor._respeitar_bloqueio and seletor._sel == EstadoJogo.fronteira())
	seletor.queue_free()
	await quadros(2)
	get_tree().quit(0)
