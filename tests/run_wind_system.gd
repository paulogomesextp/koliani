extends Node2D
## Harness Godot real do WindZone + Koliani. Cobre enter/exit, transição entre
## zonas e limpeza no respawn; a matemática dirigida cobre os restantes casos.

const Testes := preload("res://tests/test_wind_system.gd")
const CenaKoliani := preload("res://scenes/actors/Koliani.tscn")
const CenaWindZone := preload("res://scenes/actors/WindZone.tscn")

var _falhas: Array[String] = []


func _ready() -> void:
	call_deferred("_executar")


func _executar() -> void:
	_falhas.append_array(Testes.executar())

	var direita := CenaWindZone.instantiate() as WindZone
	direita.name = "VentoDireita"
	direita.direcao = Vector2.RIGHT
	direita.intensidade = 900.0
	direita.velocidade_max = 320.0
	direita.tamanho = Vector2(300.0, 300.0)
	add_child(direita)

	var esquerda := CenaWindZone.instantiate() as WindZone
	esquerda.name = "VentoEsquerda"
	esquerda.position = Vector2(500.0, 0.0)
	esquerda.direcao = Vector2.LEFT
	esquerda.intensidade = 700.0
	esquerda.velocidade_max = 260.0
	esquerda.tamanho = Vector2(300.0, 300.0)
	add_child(esquerda)

	var koliani := CenaKoliani.instantiate() as Koliani
	koliani.position = Vector2.ZERO
	add_child(koliani)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	_verificar(koliani.quantidade_ventos_ativos() == 1,
		"G: entrar na zona regista exatamente uma influência")
	_verificar(koliani.aceleracao_vento_resultante().x > 0.0,
		"G: a zona direita entrega força positiva ao player real")

	koliani.position = Vector2(500.0, 0.0)
	koliani.reset_physics_interpolation()
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	_verificar(koliani.quantidade_ventos_ativos() == 1,
		"H/K: sair da primeira e entrar na segunda não deixa duas zonas presas")
	_verificar(koliani.aceleracao_vento_resultante().x < 0.0,
		"K: transição entre zonas troca a direção da força")

	koliani.recuperar_no_checkpoint(Vector2(900.0, 100.0))
	_verificar(koliani.quantidade_ventos_ativos() == 0,
		"J/L: respawn limpa imediatamente influências anteriores")
	_verificar(koliani.velocity.is_zero_approx(),
		"J: respawn repõe velocity e estado interno sem força residual")

	if _falhas.is_empty():
		print("OK -- Region II reusable WindZone (A-L)")
		get_tree().quit(0)
		return
	for falha in _falhas:
		printerr("FALHOU: ", falha)
	printerr("%d falha(s)" % _falhas.size())
	get_tree().quit(1)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		_falhas.append(mensagem)
