extends Node
## Regressão portal real/save/reentrada, tutorial por habilidade e scaffold L1–L5.
const Remaster := preload("res://scripts/regiao1_remaster.gd")
var falhas := 0
var entradas := 0
var indice_no_callback := -1
var portal_teste: Porta
var saida := "C:/Projetos/koliani/work/9h12a"

func verificar(ok: bool, mensagem: String) -> void:
	if not ok:
		falhas += 1
		push_error("9H.12A: " + mensagem)

func esperar(quadros := 8) -> void:
	for i in quadros:
		await get_tree().process_frame

func foto(nome: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(saida.path_join(nome + ".png"))

func _ready() -> void:
	provar.call_deferred()

func _reentrar(corpo: Node) -> void:
	entradas += 1
	indice_no_callback = EstadoJogo.indice_nivel
	portal_teste._ao_entrar(corpo)
	portal_teste._ao_entrar(corpo)

func provar() -> void:
	print("9H.12A: user isolado em ", OS.get_user_data_dir())
	EstadoJogo.reiniciar_campanha()
	var main = load("res://scenes/Main.tscn").instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await esperar(40)
	var k = get_tree().get_first_node_in_group("koliani")
	portal_teste = main.find_child("Porta", true, false)
	var estranho := Node.new()
	portal_teste._ao_entrar(estranho)
	verificar(not portal_teste._em_transicao, "portal aceitou corpo estranho")
	estranho.free()
	var guardiao = main.find_child("Guardiao", true, false)
	guardiao.queue_free()
	await esperar()
	verificar(portal_teste.monitoring, "porta não abriu após guardião")
	portal_teste.body_entered.connect(_reentrar)
	k.global_position = portal_teste.global_position + Vector2(-85, 0)
	k.velocity = Vector2.ZERO
	# Aproximação ao portal por input real; sem teleportes durante a travessia.
	Input.action_press("mover_direita")
	for i in 120:
		await get_tree().physics_frame
		if entradas > 0:
			break
	Input.action_release("mover_direita")
	await esperar(40)
	verificar(entradas == 1, "body_entered real não ocorreu uma única vez")
	verificar(indice_no_callback == 0, "progressão ainda executada dentro do callback físico")
	verificar(EstadoJogo.indice_nivel == 1 and 0 in EstadoJogo.concluidos, "L1 não concluiu/L2 não abriu")
	verificar(EstadoJogo.vidas == EstadoJogo.VIDAS_INICIAIS + 1, "reentrada duplicou recompensa de vidas")
	verificar(get_tree().current_scene != main, "cena antiga não foi substituída")
	verificar(get_tree().get_first_node_in_group("koliani") != null, "L2 sem jogador")
	verificar(EstadoJogo.level_session.get("level_id") == "level_002", "sessão L2 inválida")
	var save = JSON.parse_string(FileAccess.get_file_as_string(EstadoJogo.CAMINHO_SAVE))
	verificar(save["current_level_id"] == "level_002" and "level_001" in save["completed_level_ids"], "save perdeu conclusão/transição")
	verificar(EstadoJogo.carregar(), "save de transição não recarrega")
	verificar(EstadoJogo.indice_nivel == 1 and 0 in EstadoJogo.concluidos, "retoma mudou o progresso")
	await foto("portal_L2")
	get_tree().current_scene.queue_free()
	get_tree().current_scene = null
	await esperar()
	await provar_tutorial()
	await provar_scaffold()
	print("9H.12A: %d falhas; entradas portal=%d" % [falhas, entradas])
	get_tree().quit(0 if falhas == 0 else 1)

func provar_tutorial() -> void:
	verificar(not EstadoJogo.tem_habilidade("salto_duplo"), "L1 mudou o desbloqueio base")
	for idioma in Textos.IDIOMAS:
		Textos.definir_idioma(idioma)
		for com_duplo in [false, true]:
			EstadoJogo.habilidades.clear()
			if com_duplo:
				EstadoJogo.habilidades.append("salto_duplo")
			var hud = load("res://scenes/ui/HUD.tscn").instantiate()
			get_tree().root.add_child(hud)
			hud._ao_mecanica("saltos")
			await esperar()
			var esperado := Textos.t("mec.saltos.txt" if com_duplo else "mec.saltos.txt_basico")
			verificar(esperado != "mec.saltos.txt_basico", "tradução básica em falta")
			verificar(hud._notificacao.get_child(0).get_child(1).text == esperado, "tutorial não acompanha habilidade: " + idioma)
			hud.queue_free()
			await esperar()
	EstadoJogo.habilidades.clear()
	Textos.definir_idioma("en")

func provar_scaffold() -> void:
	var dados := Remaster.dados()
	verificar(dados["niveis"].size() == 5 and dados["slots"].size() == 6, "manifesto não cobre L1–L5/seis slots")
	for idx in 5:
		EstadoJogo.indice_nivel = idx
		EstadoJogo.checkpoint = Vector2.ZERO
		EstadoJogo._limpar_jornada_ancora()
		var main = load("res://scenes/Main.tscn").instantiate()
		get_tree().root.add_child(main)
		await esperar(30)
		var alvo = main.find_child("Region1HybridVisualTarget", true, false)
		var slots = alvo.get_node("RemasterRegiaoI")
		verificar(slots.get_child_count() == 6, "L%d slots incompletos" % (idx + 1))
		verificar(not Remaster.nivel(idx + 1)["plano_mapa"]["aplicar_geometria"], "plano alterou geometria")
		for camada in slots.get_children():
			verificar(camada.get_child_count() == 0, "arte nova ativada sem aprovação")
		verificar(main.find_child("Porta", true, false) != null, "porta perdida")
		verificar(get_tree().get_first_node_in_group("koliani") != null, "jogador perdido")
		await foto("L%d_scaffold" % (idx + 1))
		# A API aceita textura ilustrada com sampler linear e respeita parallax.
		var sprite = slots.adicionar("landmark_layers", {"textura": "res://icon.png", "posicao": [20, 30], "escala": [0.2, 0.2]})
		verificar(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "asset híbrido forçado a pixel art")
		slots.atualizar(Vector2(100, 50))
		verificar(slots._slots["landmark_layers"].position.is_equal_approx(Vector2(74, 42)), "parallax incorreto")
		sprite.queue_free()
		if idx == 0:
			var vfx = slots.adicionar("atmospheric_vfx", {"cena": "res://tests/remaster_vfx_fixture.tscn"})
			verificar(vfx is CPUParticles2D, "cena VFX não montou")
			vfx.queue_free()
			var corpo := StaticBody2D.new()
			verificar(not slots._apenas_visual(corpo), "slot visual aceita colisões")
			corpo.free()
		main.queue_free()
		await esperar()
