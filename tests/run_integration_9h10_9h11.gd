extends Node
## Smoke do lote integrado: níveis reais, HUD, Pause e Santuário sem compras.
var falhas := 0
var saida := "C:/Projetos/koliani/work/integration_9h10_9h11"

func verificar(ok: bool, mensagem: String) -> void:
	if not ok:
		falhas += 1
		push_error("Integração 9H.10/11: " + mensagem)

func esperar() -> void:
	for i in 30:
		await get_tree().process_frame

func foto(nome: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(saida.path_join(nome + ".png"))

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	provar.call_deferred()

func provar() -> void:
	var menu = load("res://scenes/ui/MenuInicial.tscn").instantiate()
	get_tree().root.add_child(menu)
	await esperar()
	await foto("menu_runtime")
	menu.queue_free()
	await get_tree().process_frame
	for idx in [0, 2, 4]:
		EstadoJogo.indice_nivel = idx
		EstadoJogo.checkpoint = Vector2.ZERO
		EstadoJogo._limpar_jornada_ancora()
		var nivel = load("res://scenes/Main.tscn").instantiate()
		get_tree().root.add_child(nivel)
		await esperar()
		verificar(get_tree().get_first_node_in_group("koliani") != null, "L%d sem jogador" % (idx + 1))
		verificar(nivel.find_child("Region1HybridVisualTarget", true, false) != null, "L%d sem identidade visual" % (idx + 1))
		await foto("L%d_runtime" % (idx + 1))
		var hud = nivel.find_child("HUD", true, false)
		verificar(hud != null, "HUD ausente")
		if hud:
			verificar(hud.get_node_or_null("LegendaControlos") == null, "control strip ativo por defeito")
			verificar(hud.get_node("Versao").text == "v" + str(ProjectSettings.get_setting("application/config/version")), "versão do HUD desatualizada")
			var boss = get_tree().get_first_node_in_group("chefes")
			if boss:
				hud._ao_combate_chefe(boss)
				await esperar()
				var estilo = hud._chefe_barra.get_theme_stylebox("fill")
				verificar(estilo is StyleBoxFlat and estilo.bg_color.r > estilo.bg_color.g * 3, "barra do boss perdeu carmesim")
				await foto("L%d_boss_hud" % (idx + 1))
		var pausa = nivel.find_child("Pausa", true, false)
		verificar(pausa != null, "Pause ausente")
		if pausa:
			pausa._abrir()
			await esperar()
			verificar(get_tree().paused and pausa.visible, "Pause não abriu")
			var painel: Control = pausa.get_node("Painel")
			verificar(painel.get_theme_stylebox("panel") is StyleBoxFlat, "Pause perdeu Frontend9H")
			var botao: Control = pausa.get_node("Painel/Coluna/Menu")
			verificar(painel.get_global_rect().encloses(botao.get_global_rect()), "botão Menu transborda Pause")
			await foto("L%d_pause" % (idx + 1))
			pausa._abrir_santuario()
			await esperar()
			verificar(pausa._santuario_inst != null and pausa._santuario_inst._cartoes.size() == 6, "Santuário incompleto")
			await foto("L%d_santuario" % (idx + 1))
			pausa._santuario_inst.queue_free()
			await esperar()
			pausa._fechar()
			verificar(not get_tree().paused, "Pause não retomou")
		nivel.queue_free()
		await esperar()
	print("Integração 9H.10/11: %d falhas" % falhas)
	get_tree().quit(0 if falhas == 0 else 1)
