extends SceneTree
## Prova a ligação pelo fluxo Main, sem chamar ativar_core_combate no QA.
var k: Node
var core: Node

func _init() -> void:
	call_deferred("executar")

func esperar(n: int) -> void:
	for i in n:
		await physics_frame

func soltar() -> void:
	for acao in ["atacar", "mirar_cima", "mirar_baixo", "dash", "rolar", "saltar"]:
		Input.action_release(acao)
	await esperar(2)

func carregar(indice: int) -> void:
	var ej := root.get_node("EstadoJogo")
	ej.indice_nivel = indice
	ej.checkpoint = Vector2.ZERO
	change_scene_to_file("res://scenes/Main.tscn")
	# Main resolve checkpoints em oito frames; concluir antes de trocar de nível.
	for i in 12:
		await process_frame
	k = current_scene.find_child("Koliani", true, false)
	assert(k != null, "Koliani ausente em N%d" % (indice+1))
	core = k._core
	assert(core != null and k._lab == null, "Combate 1.2 desligado em N%d" % (indice+1))
	assert(k._combate_extra() == core)
	assert(k.ativar_core_combate() == core)
	assert(core.bal.base_dano_mult == [0.30, 0.35, 0.43, 0.60])
	assert(core.bal.ar_dano_mult == [1.40, 1.60])
	assert(not k.has_node("HybridShadowbladeSignature"))

func executar() -> void:
	root.size = Vector2i(1280,720)
	var ej := root.get_node("EstadoJogo")
	ej.modo_teste = true
	ej.habilidades.assign(["dash", "pogo", "salto_duplo", "especial", "projetil"])
	for indice in ([] if OS.get_environment("QA_SO_ACOES") == "1" else range(ej.NIVEIS.size())):
		await carregar(indice)
		print("QA COMBATE CAMPANHA: N%d núcleo único e valores 1.2" % (indice+1))
	for indice in [0, 5]:
		await carregar(indice)
		await validar_acoes()
		print("QA AÇÕES N%d: Launcher/Cleave/Dash/Air x2, PD/Counter" % (indice+1))
	print("QA COMBATE CAMPANHA: âmbito solicitado concluído; ações N1/N6, PD/Counter e tradução passaram")
	await esperar(70)
	current_scene.queue_free()
	k = null
	core = null
	await process_frame
	VfxSkin._cache.clear()
	VfxPosicionamento._limites.clear()
	await process_frame
	quit()

func validar_acoes() -> void:
	for i in 120:
		await physics_frame
		if k.is_on_floor():
			break
	assert(k.is_on_floor())
	# O comportamento nasce de input real no nível, não de um comando de QA ao Core.
	Input.action_press("mirar_cima")
	Input.action_press("atacar")
	await esperar(3)
	await soltar()
	assert(core.log_ultimos.has("LAUNCHER"))
	await esperar(38)
	Input.action_press("atacar")
	await esperar(40)
	Input.action_release("atacar")
	await esperar(2)
	assert(core.log_ultimos.has("CLEAVE"))
	await esperar(50)
	Input.action_press("dash")
	await esperar(2)
	Input.action_press("atacar")
	await esperar(2)
	await soltar()
	assert(core.log_ultimos.has("DASH"))
	await esperar(45)
	Input.action_press("saltar")
	await esperar(4)
	Input.action_release("saltar")
	Input.action_press("atacar")
	await esperar(3)
	Input.action_release("atacar")
	await esperar(15)
	Input.action_press("atacar")
	await esperar(3)
	await soltar()
	assert(core.log_ultimos.has("ar 2"), "Combo aéreo não encadeou no nível real")
	await esperar(70)
	# Perfect Dodge só responde à origem de ataque; contacto nunca abre Counter.
	k._rolar_restante = k.DUR_ROLAR - 0.04
	k._invulneravel = 0.2
	core._pd_cd = 0.0
	k.receber_dano(8, 1.0, "contato")
	assert(core.janela_counter() == 0.0)
	k.receber_dano(8, 1.0, "ataque")
	assert(core.janela_counter() > 0.0)
	assert(core._pd_flash.text == root.get_node("Textos").t("combat.perfect_dodge"))
	Input.action_press("atacar")
	await esperar(2)
	await soltar()
	assert(core.log_ultimos.has("COUNTER"))
