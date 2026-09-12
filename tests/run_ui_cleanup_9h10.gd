extends Node
## Verificação dirigida: fila, prioridade do diálogo, margens e arte funcional.
var falhas := 0

func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		push_error("9H.10: " + mensagem)

func _ready() -> void:
	call_deferred("provar")

func provar() -> void:
	var hud = load("res://scenes/ui/HUD.tscn").instantiate()
	get_tree().root.add_child(hud)
	await get_tree().process_frame
	verificar(hud.get_node_or_null("LegendaControlos") == null, "legenda permanente ativa")
	hud._placa_tutorial("Tutorial", "Texto de teste")
	hud._aviso(Textos.t("hud.checkpoint"), "ico_checkpoint", "info")
	await get_tree().process_frame
	await get_tree().process_frame
	verificar(hud._fila_notificacoes.size() == 1, "toast não esperou pelo tutorial")
	verificar(hud._notificacao.position.y >= hud._cab_nivel.position.y + hud._cab_nivel.size.y, "notificação sobre o cabeçalho")
	var balao := Balao.new()
	get_tree().root.add_child(balao)
	balao.visible = true
	balao._posicionar()
	await get_tree().process_frame
	verificar(not hud._notificacao.visible, "diálogo sobrepôs tutorial")
	verificar(not hud._notificacao_tween.is_running(), "tutorial perdeu tempo durante diálogo")
	verificar(balao._painel.position.y >= 160.0, "diálogo sobre cabeçalho")
	balao.visible = false
	await get_tree().process_frame
	verificar(hud._notificacao.visible, "tutorial não regressou")
	hud._notificacao_tween.custom_step(12.0)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	verificar(hud._fila_notificacoes.is_empty(), "toast não saiu da fila")
	verificar(is_instance_valid(hud._notificacao), "toast perdido")
	hud._notificacao_tween.custom_step(3.0)
	await get_tree().process_frame
	await get_tree().process_frame
	var copia: Array[String] = EstadoJogo.habilidades.duplicate()
	EstadoJogo.habilidades.erase("escalar_paredes")
	var item = load("res://scenes/actors/Coletavel.tscn").instantiate()
	item.habilidade_id = "escalar_paredes"
	item.position = Vector2(2, 300)
	get_tree().root.add_child(item)
	await get_tree().process_frame
	for esc in [0.5, 1.0, 2.0]:
		item.scale = Vector2.ONE * esc
		for x in [2.0, get_tree().root.get_visible_rect().size.x - 2.0]:
			item.position.x = x
			item._process(0.0)
			var faixa: Node2D = item._visual.get_node("Faixa")
			var trans := faixa.get_global_transform_with_canvas()
			var margem := 44.0 * trans.x.length()
			verificar(trans.origin.x - margem >= 0 and trans.origin.x + margem <= get_tree().root.get_visible_rect().size.x, "SKILL cortado")
	EstadoJogo.habilidades = copia
	var porta = load("res://scenes/actors/Porta.tscn").instantiate()
	get_tree().root.add_child(porta)
	verificar(porta.get_node_or_null("VorticeArte") != null and not porta.get_node("Vortice").visible, "porta manteve hexágono")
	verificar(porta.get_node("CollisionShape2D").shape != null and porta.body_entered.is_connected(porta._ao_entrar), "porta perdeu função")
	var ess = load("res://scenes/actors/Essencia.tscn").instantiate()
	get_tree().root.add_child(ess)
	verificar(ess.get_node_or_null("Nucleo/CristalEssencia") != null, "Essência sem cristal aprovado")
	for no in [hud, balao, item, porta, ess]:
		no.queue_free()
	await get_tree().process_frame
	print("9H.10: %d falhas" % falhas)
	get_tree().quit(0 if falhas == 0 else 1)
