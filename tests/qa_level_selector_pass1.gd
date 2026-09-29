extends Node
## QA focada do Pass 1. Corre como cena para preservar o contexto dos
## autoloads do jogo: `godot --headless --path . res://tests/qa_level_selector_pass1.tscn`.

var falhas: Array[String] = []
var _selecionado := -1

func _ready() -> void:
	var save_antes: Dictionary = EstadoJogo.para_dicionario()
	var indice_antes := EstadoJogo.indice_nivel
	var concluidos_save_antes: Array = EstadoJogo.concluidos.duplicate()
	EstadoJogo.indice_nivel = 0
	EstadoJogo.concluidos.clear()
	var selector: SeletorNiveis = load("res://scenes/ui/SeletorNiveis.tscn").instantiate()
	selector.size = Vector2(1280, 720)
	selector.escolhido.connect(func(i: int) -> void: _selecionado = i)
	add_child(selector)
	await get_tree().process_frame
	selector.configurar(0, true)
	await get_tree().process_frame
	_check(selector.get("_region_cards").size() == 20, "20 regiões presentes")
	_check(selector.get("_level_cards").size() == 5, "5 níveis na vista regional")
	var todos: Array = []
	for regiao in EstadoJogo.REGIOES:
		_check(regiao["niveis"].size() == 5, "cada região tem 5 níveis")
		for indice in regiao["niveis"]:
			todos.append(int(indice))
	_check(todos.size() == 100 and todos.min() == 0 and todos.max() == 99 and todos.duplicate().size() == 100,
		"N01-N100 mapeados uma vez, sem duplicados")
	for r in 20:
		_check(int(EstadoJogo.REGIOES[r]["niveis"][4]) == r * 5 + 4, "boss N%03d" % (r * 5 + 5))
	selector.call("_abrir_regiao", 0)
	await get_tree().process_frame
	_check(selector.get("_vista_regioes") == false, "seleção de região abre níveis")
	selector.call("_voltar_premido")
	var evento_teclado := InputEventAction.new()
	evento_teclado.action = "ui_right"
	evento_teclado.pressed = true
	evento_teclado.strength = 1.0
	selector.call("_unhandled_input", evento_teclado)
	_check(int(selector.get("_regiao")) == 1, "teclado navega entre regiões")
	selector.call("_selecionar_regiao", 0)
	selector.call("_confirmar")
	_check(selector.get("_vista_regioes") == false, "controller confirma região")
	_check(selector.call("_estado_nivel", 0) == "CURRENT", "CURRENT visível")
	_check(selector.call("_estado_nivel", 99) == "LOCKED", "LOCKED visível")
	var concluidos_antes: Array = EstadoJogo.concluidos.duplicate()
	EstadoJogo.concluidos.append(1)
	_check(selector.call("_estado_nivel", 1) == "COMPLETED", "COMPLETED visível")
	EstadoJogo.concluidos = concluidos_antes
	selector.call("_mudar_regiao", -1)
	selector.call("_selecionar_nivel", 0)
	selector.call("_confirmar")
	_check(_selecionado == 0, "UNLOCKED abre o nível")
	selector.get("_level_cards")[0].emit_signal("pressed")
	_check(int(selector.get("_sel")) == 0, "mouse seleciona um nível")
	selector.call("_selecionar_nivel", 4)
	selector.call("_confirmar")
	_check(_selecionado == 0, "LOCKED não abre")
	selector.call("_voltar_premido")
	_check(selector.get("_vista_regioes") == true, "voltar regressa às regiões")
	EstadoJogo.indice_nivel = indice_antes
	EstadoJogo.concluidos = concluidos_save_antes
	var save_depois: Dictionary = EstadoJogo.para_dicionario()
	_check(save_antes == save_depois, "selector não altera save")
	selector.queue_free()
	await get_tree().process_frame
	if falhas.is_empty():
		print("QA LEVEL SELECTOR PASS 1: PASS")
	else:
		for falha in falhas:
			push_error("QA LEVEL SELECTOR: " + falha)
		get_tree().quit(1)
		return
	get_tree().quit(0)

func _check(condicao: bool, descricao: String) -> void:
	if not condicao:
		falhas.append(descricao)
