extends SceneTree
## QA JOGADO do acesso Dev SEM PIN (19 set 2026) -- janela REAL, rato a
## serio, teclado a serio. Não é um screenshot nem uma leitura de código:
## clica-se no botão como um humano clica e vê-se o que acontece.
##
## Prova quatro coisas, por esta ordem:
##   1. o menu abre SEM painel de acesso e sem campo de texto nenhum;
##   2. UM clique de rato no DEV MODE entra em modo dev -- sem PIN;
##   3. o jogo carrega mesmo (a Koliani nasce) com a barra Dev montada;
##   4. depois de CLICAR no "TESTAR OUTRO NÍVEL" e fechar o painel, o
##      ESPAÇO volta a saltar -- não reabre o selector nem recarrega o
##      nível. (É a regressão de `7a4e586a`, revalidada ponta a ponta.)
##
## Uso:
##   xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x720 \
##     --path . --script res://tools/qa_dev_sem_pin.gd -- <pasta-de-fotos>

var _falhas := 0
var _fotos := "/tmp"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_fotos = args[0]
	await process_frame
	var estado := root.get_node("/root/EstadoJogo")
	estado.modo_teste = true

	# ── 1. o menu, sem porta nenhuma ──────────────────────────────────
	var menu: Control = load("res://scenes/ui/MenuInicial.tscn").instantiate()
	root.add_child(menu)
	for _i in 20:
		await process_frame
	_checar(_sem_line_edit(menu), "o menu tem um campo de texto")
	_checar(menu.find_child("AcessoDev", true, false) == null,
		"o menu montou um painel de acesso")
	var dev: Button = menu.get("_dev")
	_checar(dev != null and dev.visible, "botão DEV MODE visível")
	await _fotografar("01_menu_sem_pin.png")

	# ── 2. UM clique de rato a serio ──────────────────────────────────
	_clicar(dev)
	for _i in 6:
		await process_frame
	_checar(estado.modo_dev, "o clique no DEV MODE não activou o modo dev")
	_checar(menu.find_child("AcessoDev", true, false) == null,
		"apareceu um painel de PIN depois do clique")
	await _fotografar("02_logo_apos_clique.png")

	# ── 3. o jogo carrega mesmo ───────────────────────────────────────
	# o `_ao_dev_mode` acaba num fade de 0.22 s que troca para a Main.
	for _i in 120:
		await process_frame
	var koliani := get_first_node_in_group("koliani")
	_checar(koliani != null, "a Koliani não nasceu depois de entrar em Dev")
	var barra: Node = null
	for n in root.get_children():
		barra = n.find_child("DevBarra", true, false)
		if barra:
			break
	_checar(barra != null, "a barra Dev não apareceu no jogo")
	await _fotografar("03_jogo_em_dev_mode.png")
	if barra == null or koliani == null:
		_terminar()
		return

	# ── 4. o ESPAÇO depois de mexer na barra ──────────────────────────
	var topo := barra.get_node_or_null("BotaoTopo") as Button
	_checar(topo != null, "o botão TESTAR OUTRO NÍVEL não existe")
	if topo:
		_checar(topo.focus_mode == Control.FOCUS_NONE,
			"TESTAR OUTRO NÍVEL aceita foco -- o ESPAÇO volta a carregar nele")
		print("QA DEV passo: clicar no TESTAR OUTRO NIVEL")
		_clicar(topo)                      # abre o selector, como um humano
		for _i in 30:
			await process_frame
		await _fotografar("04_selector_aberto.png")
		print("QA DEV passo: fechar o selector")
		barra.call("_fechar")              # e fecha-o
		for _i in 20:
			await process_frame

	print("QA DEV passo: selector fechado; a saltar")
	var nivel_antes := koliani.get_instance_id()
	var pos_antes: Vector2 = koliani.global_position
	var dono := barra.get_viewport().gui_get_focus_owner()
	print("QA DEV: foco depois de fechar o selector = %s"
		% ("NINGUEM" if dono == null else str(dono.get_path())))
	for salto in 5:
		_tecla(KEY_SPACE, true)
		for _i in 4:
			await process_frame
		_tecla(KEY_SPACE, false)
		for _i in 10:
			await process_frame
		if not is_instance_valid(barra):
			_falhas += 1
			push_error("QA DEV: o salto %d trocou de cena -- a barra Dev"
				% (salto + 1) + " morreu, ou seja, o nivel recarregou")
			print("QA DEV resultado: falhas=%d" % _falhas)
			quit(1)
			return
	print("QA DEV passo: cinco saltos dados")
	var painel := barra.get("_painel") as Control
	_checar(painel == null or not painel.visible,
		"o ESPAÇO reabriu o selector de níveis")
	_checar(not paused, "o ESPAÇO deixou a árvore em pausa")
	var koliani_agora := get_first_node_in_group("koliani")
	_checar(koliani_agora != null
			and koliani_agora.get_instance_id() == nivel_antes,
		"o nível foi recarregado -- o ESPAÇO deu reset")
	await _fotografar("05_apos_cinco_saltos.png")
	print("QA DEV: saltos dados; Koliani em %s (antes %s)"
		% [str(koliani_agora.global_position if koliani_agora else Vector2.ZERO), str(pos_antes)])
	_terminar()


# ── utilitários ──────────────────────────────────────────────────────

func _clicar(botao: Button) -> void:
	var centro := botao.get_global_rect().get_center()
	for pressionado in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressionado
		e.position = centro
		e.global_position = centro
		Input.parse_input_event(e)


func _tecla(codigo: int, pressionada: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = codigo
	e.keycode = codigo
	e.pressed = pressionada
	Input.parse_input_event(e)


func _fotografar(nome: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(_fotos.path_join(nome))
	print("FOTO: ", _fotos.path_join(nome))


func _sem_line_edit(no: Node) -> bool:
	if no is LineEdit:
		return false
	for f in no.get_children():
		if not _sem_line_edit(f):
			return false
	return true


## As mensagens estão escritas como a QUEIXA que se quer nunca ver, por isso
## só se imprimem quando a asserção falha. O que se vê quando corre bem é a
## lista de passos, mais as fotos.
func _checar(ok: bool, mensagem: String) -> void:
	if not ok:
		_falhas += 1
		push_error("QA DEV: " + mensagem)


func _terminar() -> void:
	print("QA DEV resultado: falhas=%d" % _falhas)
	quit(0 if _falhas == 0 else 1)
