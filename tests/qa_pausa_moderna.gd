extends SceneTree
## UI e áudio da pausa com userdata isolada; não altera a campanha real.
var falhas := 0

func _init() -> void:
	call_deferred("executar")

func verificar(valor: bool, mensagem: String) -> void:
	print(("PASS " if valor else "FALHOU ") + mensagem)
	if not valor:
		falhas += 1

func executar() -> void:
	var musica := root.get_node("Musica")
	var estado := root.get_node("EstadoJogo")
	estado.modo_teste = true
	musica.ambiente(0)
	await create_timer(0.3).timeout
	var pausa: Node = load("res://scenes/ui/Pausa.tscn").instantiate()
	root.add_child(pausa)
	await process_frame
	Input.warp_mouse(Vector2(10, 10))
	await process_frame
	pausa._abrir()
	await create_timer(0.4).timeout
	verificar(paused and pausa.visible, "abrir pausa suspende o jogo")
	verificar((not musica._p.playing or musica._p.stream_paused)
		and (not musica._p2.playing or musica._p2.stream_paused),
		"camas suspensas sem música de fundo")
	verificar(not musica._pausa_p.playing, "faixa específica da pausa não toca")
	var tempo: float = musica._p.get_playback_position()
	await create_timer(0.3).timeout
	verificar(absf(musica._p.get_playback_position() - tempo) < 0.1,
		"posição da música preservada durante a pausa")
	var botoes := [pausa._continuar, pausa._opcoes_btn, pausa._mapa, pausa._menu]
	for botao: Button in botoes:
		verificar(botao.flat and botao.get_theme_stylebox("normal") is StyleBoxEmpty,
			"rótulo do menu inicial: " + botao.name)
		verificar(root.get_visible_rect().encloses(botao.get_global_rect()),
			"botão dentro do viewport: " + botao.name)
	verificar(pausa._palco.get_node("Arte").texture == Frontend9H.textura("fundo_menu"),
		"mesma prancha do menu inicial")
	verificar(pausa._continuar.has_focus(), "foco inicial em continuar")
	pausa._mapa.grab_focus()
	await create_timer(0.3).timeout
	verificar(pausa._realce.get_global_rect().encloses(pausa._mapa.get_global_rect()),
		"realce único acompanha o foco")
	if not DisplayServer.get_name() == "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://pausa_moderna.png")
	pausa._abrir_opcoes()
	await process_frame
	verificar(paused and not pausa._painel.visible, "opções mantêm pausa")
	pausa._opcoes_inst.queue_free()
	await process_frame
	await process_frame
	verificar(paused and pausa._painel.visible, "fechar opções restaura menu")
	pausa._fechar()
	await process_frame
	verificar(not paused and not musica._p.stream_paused, "continuar repõe jogo e áudio")
	verificar(musica._p.get_playback_position() >= tempo - 0.1,
		"continuar não reinicia a faixa")
	pausa._abrir()
	await process_frame
	pausa._fechar()
	musica.parar()
	pausa.queue_free()
	await process_frame
	print("QA PAUSA MODERNA: %s (%d falhas)" % ["PASS" if falhas == 0 else "FALHOU", falhas])
	quit(0 if falhas == 0 else 1)
