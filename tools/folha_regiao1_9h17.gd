extends SceneTree
## FOLHA DE CONTACTO DA REGIAO I (9H.17 CONTINUATION).
##
## O passe Hybrid passou a servir os cinco niveis, e a pergunta que isso
## levanta -- "a Regiao I le-se como UMA regiao?" -- nao se responde com uma
## fotografia por nivel. Um unico ponto engana nos dois sentidos: o L4 a 65%
## do nivel esta atras de uma parede de plataformas e parece que nao tem
## fundo nenhum; o L5 a meio parece mais rico do que e'.
##
## Entao: CINCO niveis x QUATRO pontos, no renderer real, com a camara
## pousada onde o jogador vai mesmo estar. E o que permite comparar o L1 com
## o L3 sem ser de memoria.
##
## Uso (precisa de janela -- em `--headless` o renderer e' dummy e as
## capturas saem pretas; ver `docs/retomar_aqui.md`):
##
##   Godot_console.exe --path . --screen 1 --script res://tools/folha_regiao1_9h17.gd
const SAIDA := "res://work/9h17_regiao1/"
## x, y por ponto. O y e' generoso: a Koliani cai ate' pousar, e o que
## interessa e' a COLUNA do nivel, nao a plataforma exacta.
const PONTOS := [
	["a_spawn", 320.0, 620.0], ["b_cedo", 1250.0, 600.0],
	["c_meio", 2300.0, 580.0], ["d_chefe", 3350.0, 620.0],
]
const NIVEIS := [
	[0, "L1_floresta"], [1, "L2_pantano"], [2, "L3_ninho"],
	[3, "L4_arvore"], [4, "L5_coracao"],
]


func _init() -> void:
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	if DisplayServer.get_screen_count() > 1:
		root.position = DisplayServer.screen_get_position(1) \
			+ DisplayServer.screen_get_size(1) - Vector2i(200, 140)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	await process_frame
	var estado := root.get_node("EstadoJogo")
	var falhas := 0
	for n: Array in NIVEIS:
		estado.indice_nivel = int(n[0])
		estado.checkpoint = Vector2.ZERO
		change_scene_to_file("res://scenes/Main.tscn")
		await create_timer(1.8).timeout
		var jogador := get_first_node_in_group("koliani") as CharacterBody2D
		if jogador == null:
			push_error("9H.17: %s nao abriu" % n[1])
			falhas += 1
			continue
		var alvo := current_scene.find_child("Region1HybridVisualTarget", true, false)
		# a prova de que o passe montou MESMO neste nivel: a camada de ceu do
		# perfil. Sem isto a folha sai bonita e nao diz nada.
		var perfil := int(n[0]) + 1
		if alvo == null or alvo.get_node_or_null("HybridL%d_ceu" % perfil) == null:
			push_error("9H.17: passe Hybrid nao montado em %s" % n[1])
			falhas += 1
		jogador.set_physics_process(false)
		for p: Array in PONTOS:
			jogador.global_position = Vector2(p[1], p[2])
			jogador.set("velocity", Vector2.ZERO)
			await create_timer(0.7).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(
				SAIDA + "%s_%s.png" % [n[1], p[0]])
	print("9H.17 FOLHA REGIAO I: %d capturas, %d falhas"
		% [NIVEIS.size() * PONTOS.size(), falhas])
	quit(1 if falhas > 0 else 0)
