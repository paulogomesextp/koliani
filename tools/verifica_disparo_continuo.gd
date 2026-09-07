extends SceneTree
## Exercita o botão real de toque, animação e plataformas com Koliani real.
var tiros := 0
var falhas := 0

func verificar(condicao: bool, nome: String) -> void:
	print("OK " if condicao else "FALHOU ", nome)
	if not condicao:
		falhas += 1

func frames(n: int) -> void:
	for i in n:
		await physics_frame
	await process_frame

func _init() -> void:
	await process_frame
	var estado := root.get_node("EstadoJogo")
	estado.indice_nivel = 0
	estado.checkpoint = Vector2.ZERO
	estado.desbloquear_habilidade("escudo")
	change_scene_to_file("res://scenes/levels/Level_Test.tscn")
	await process_frame
	for no in current_scene.get_children():
		if no.scene_file_path == "res://scenes/actors/DemonioBase.tscn":
			no.queue_free()
	await frames(40)
	var k: CharacterBody2D = get_first_node_in_group("koliani")
	k.set("_invulneravel", 60.0)
	var controlos := Control.new()
	controlos.set_script(load("res://scripts/controlos_tacteis.gd"))
	controlos.size = Vector2(1280, 720)
	var tela := CanvasLayer.new()
	current_scene.add_child(tela)
	tela.add_child(controlos)
	var botao: Dictionary = {}
	for b in controlos.get_script().get_script_constant_map()["BOTOES"]:
		if b.accao == "lancar":
			botao = b
	var centro: Vector2 = controlos.call("_sitio", botao)[0]
	node_added.connect(func(no: Node):
		if no.scene_file_path == "res://scenes/actors/ProjetilKoliani.tscn":
			tiros += 1)
	var toque := InputEventScreenTouch.new()
	toque.index = 9
	toque.position = centro
	toque.pressed = true
	controlos.call("_input", toque)
	await frames(2)
	verificar(tiros == 1, "toque dispara imediatamente")
	var corpo: AnimatedSprite2D = k.get("_corpo")
	verificar(corpo.animation == &"lancar" and corpo.is_playing(), "animação de lançamento")
	await frames(4)
	verificar(corpo.frame > 0, "poses avançam durante lançamento")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://work/disparo-continuo.png")
	await frames(34)
	verificar(tiros >= 4 and tiros <= 5, "hold repete sem rajada especial")
	toque.pressed = false
	controlos.call("_input", toque)
	var antes := tiros
	await frames(24)
	verificar(tiros == antes and not Input.is_action_pressed("lancar"), "largar interrompe disparos")
	verificar(corpo.animation != &"lancar", "animação termina após largar")
	Input.action_press("lancar")
	await frames(2)
	Input.action_release("lancar")
	verificar(tiros == antes + 1, "teclado também dispara ao premir")
	await frames(12)
	antes = tiros
	Input.action_press("defender")
	Input.action_press("lancar")
	await frames(24)
	verificar(tiros == antes, "defesa bloqueia disparo")
	Input.action_release("defender")
	Input.action_release("lancar")
	await frames(12)
	estado.desbloquear_habilidade("projetil")
	var espectral: Node2D = load("res://scenes/actors/PlataformaEspectral.tscn").instantiate()
	espectral.position = Vector2(950, 450)
	current_scene.add_child(espectral)
	await frames(2)
	verificar(not espectral.get("_solida"), "plataforma começa espectral")
	toque.pressed = true
	controlos.call("_input", toque)
	await frames(2)
	verificar(espectral.get("_solida"), "projétil ativa plataforma espectral")
	controlos.hide()
	antes = tiros
	await frames(20)
	verificar(tiros == antes and not Input.is_action_pressed("lancar"), "ocultar controlos liberta hold")
	verificar(not k.has_method("_lancar_kamehameha"), "feixe removido")
	print("Disparo contínuo: ", falhas, " falhas")
	quit(0 if falhas == 0 else 1)
