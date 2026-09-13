extends Node
## PROVA DE ALCANCE (9H.17): mede a ENVOLVENTE DE SALTO real da Koliani --
## com a fisica do jogo, nao com aritmetica -- para o contrato de mobilidade
## da Regiao I (salto SIMPLES, sem salto duplo).
##
## Monta uma sala minima: plataforma A (partida) e plataforma B a `dy` acima
## e com `vao` px de intervalo entre bordas. Um piloto sintetico corre para a
## direita, salta na ponta de A (segurando `saltar`, sem corte de salto) e
## diz se aterrou em B. Varre dy/vao e imprime a tabela.
##
## Corre como CENA (autoloads): so' assim a Koliani compila.
##   Godot --headless --path . res://tests/run_alcance_9h17.tscn

const KOLIANI := preload("res://scenes/actors/Koliani.tscn")
const PLAT := preload("res://scenes/actors/Plataforma.tscn")

const TOPO_A := 0.0
const LARG := 220.0
const ALT := 24.0

var _mundo: Node2D
var falhas := 0


func _ready() -> void:
	provar.call_deferred()


func _nova_sala(dy: float, vao: float) -> Node2D:
	var sala := Node2D.new()
	var a: Node2D = PLAT.instantiate()
	a.tamanho = Vector2(LARG, ALT)
	a.position = Vector2(0, TOPO_A + ALT * 0.5)
	sala.add_child(a)
	var b: Node2D = PLAT.instantiate()
	b.tamanho = Vector2(LARG, ALT)
	# borda esquerda de B = borda direita de A + vao
	var b_esq := LARG * 0.5 + vao
	b.position = Vector2(b_esq + LARG * 0.5, TOPO_A - dy + ALT * 0.5)
	sala.add_child(b)
	return sala


func _soltar_tudo() -> void:
	for a in ["mover_esquerda", "mover_direita", "saltar"]:
		Input.action_release(a)


## Devolve `true` se aterrou em B (mesmo topo de B, a` direita do vao).
func _tentar(dy: float, vao: float) -> bool:
	var sala := _nova_sala(dy, vao)
	_mundo.add_child(sala)
	var kol: CharacterBody2D = KOLIANI.instantiate()
	kol.position = Vector2(-LARG * 0.5 + 20.0, TOPO_A - 40.0)
	sala.add_child(kol)
	# assentar
	for _i in 40:
		await get_tree().physics_frame
	var ponta := LARG * 0.5
	var saltou := false
	var ok := false
	Input.action_press("mover_direita")
	for _i in 400:
		await get_tree().physics_frame
		if not saltou and kol.global_position.x >= ponta - 26.0:
			Input.action_press("saltar")
			saltou = true
		if saltou and kol.velocity.y > 0.0:
			Input.action_release("saltar")
		if saltou and kol.is_on_floor() and kol.global_position.x > ponta:
			# aterrou do outro lado: e' o topo de B?
			ok = absf(kol.global_position.y - (TOPO_A - dy)) < 30.0
			break
		if kol.global_position.y > TOPO_A + 400.0:
			break
	_soltar_tudo()
	sala.queue_free()
	await get_tree().process_frame
	return ok


func provar() -> void:
	_mundo = Node2D.new()
	add_child(_mundo)
	EstadoJogo.habilidades.clear()   # SEM salto duplo: contrato da Regiao I
	EstadoJogo.habilidades_suspensas.clear()
	print("=== ENVOLVENTE DE SALTO SIMPLES (sem salto duplo) ===")
	print("dy = subida em px (topo->topo); vao = intervalo entre bordas")
	var subidas := [76.0, 80.0, 88.0, 96.0, 104.0, 120.0]
	var vaos := [0.0, 30.0, 60.0]
	for dy: float in subidas:
		var linha := "dy=%3d : " % int(dy)
		for vao: float in vaos:
			var r: bool = await _tentar(dy, vao)
			linha += "vao%3d=%s  " % [int(vao), "OK " if r else "NAO"]
		print(linha)
	print("=== fim ===")
	get_tree().quit(0)
