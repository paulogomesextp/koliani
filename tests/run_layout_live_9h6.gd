extends SceneTree
## Exercita o editor e a instância ativa, incluindo jogo pausado e persistência real.
var falhas := 0

func verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		push_error("9H.6: " + mensagem)

func _initialize() -> void:
	call_deferred("provar")

func provar() -> void:
	var existia := LayoutToque.existe()
	var copia := LayoutToque.carregar()
	var ativo := ControlosTacteis.new()
	ativo.size = Vector2(1280, 720)
	root.add_child(ativo)
	var editor = (load("res://scripts/editor_layout_toque.gd") as Script).new()
	root.add_child(editor)
	await process_frame
	var previa: ControlosTacteis = editor.get("_controlos")
	previa.size = ativo.size
	previa.repor_layout()
	var padrao := ativo.layout_actual().duplicate(true)
	paused = true
	for qual in ["joy", "pausa", "saltar", "atacar", "defender", "lancar", "dash"]:
		previa.mover_controlo(qual, Vector2(640, 360))
		verificar(ativo.layout == previa.layout, "drag não chegou ao ativo: " + qual)
		previa.redimensionar(qual, 0.008)
		verificar(ativo.layout == previa.layout, "resize não chegou ao ativo: " + qual)
		verificar(is_equal_approx(ativo._raio_de(qual), previa._raio_de(qual)), "raio ativo antigo: " + qual)
	verificar(ativo._joy_base == Vector2(640, 360), "joystick ativo não remediu posição")
	editor._ao_guardar()
	verificar(LayoutToque.existe(), "save não persistiu")
	verificar(is_equal_approx(float(LayoutToque.carregar()["joystick"]["x"]), 0.5), "save relido errado")
	previa.mover_controlo("joy", Vector2(350, 350))
	editor._ao_fechar()
	verificar(is_equal_approx(ativo._joy_base.x, 640), "FECHAR não desfez edição não guardada")
	var editor_reset = (load("res://scripts/editor_layout_toque.gd") as Script).new()
	root.add_child(editor_reset)
	await process_frame
	editor_reset._ao_repor()
	verificar(ativo.layout.is_empty(), "REPOR não chegou ao ativo")
	verificar(not LayoutToque.existe(), "REPOR não apagou persistência")
	verificar(ativo.layout_actual() == padrao, "REPOR não remediu defaults imediatamente")
	verificar(is_instance_valid(ativo), "teste exigiu recriar ativo")
	editor_reset._ao_fechar()
	paused = false
	if existia:
		LayoutToque.guardar(copia)
	else:
		LayoutToque.apagar()
	ativo.queue_free()
	await process_frame
	print("PASS: layout live drag/resize/save/REPOR/FECHAR, mesma instância e jogo pausado" if falhas == 0 else "FAIL: layout live")
	quit(0 if falhas == 0 else 1)
