extends Node
## Bancada runtime do combate base da Execution 7. Corre dentro de uma cena
## de projeto para ter os autoloads reais, mas põe EstadoJogo em modo de teste.

class AlvoTeste:
	extends Node2D
	var golpes := 0
	func receber_dano(_quantidade: int, _direcao: float = 0.0, _critico := false) -> void:
		golpes += 1
	func esta_vulneravel() -> bool:
		return false

var _falhas: Array[String] = []


func _ready() -> void:
	EstadoJogo.modo_teste = true
	var cena: PackedScene = load("res://scenes/actors/Koliani.tscn")
	var koliani: Koliani = cena.instantiate()
	add_child(koliani)
	var hitbox: Area2D = koliani.get_node("HitboxAtaque")
	_ok(not hitbox.monitoring, "hitbox devia começar desligada")

	koliani._combo_passo = 0
	koliani._ataque_dur = 0.18
	koliani._ataque_restante = 0.17
	koliani._atualizar_janela_ataque()
	_ok(not hitbox.monitoring, "antecipação não pode causar dano")
	koliani._ataque_restante = 0.09
	koliani._atualizar_janela_ataque()
	_ok(hitbox.monitoring, "janela ativa devia ligar a hitbox")
	koliani._ataque_restante = 0.01
	koliani._atualizar_janela_ataque()
	_ok(not hitbox.monitoring, "recovery devia desligar a hitbox")

	var alvo := AlvoTeste.new()
	add_child(alvo)
	koliani._alvos_atingidos_ataque.clear()
	koliani._ao_acertar_corpo(alvo)
	koliani._ao_acertar_corpo(alvo)
	_ok(alvo.golpes == 1, "o mesmo alvo recebeu dano duplicado no golpe")
	koliani._alvos_atingidos_ataque.clear()
	koliani._ao_acertar_corpo(alvo)
	_ok(alvo.golpes == 2, "um novo golpe devia poder voltar a acertar")

	koliani.velocity = Vector2(90.0, -210.0)
	var velocidade_antes := koliani.velocity
	koliani._combo_passo = 2
	koliani._combo_janela = 0.3
	koliani._iniciar_ataque()
	_ok(koliani._ataque_no_ar and koliani._combo_passo == 0
		and koliani._combo_janela == 0.0,
		"ataque aéreo devia ser singular e não encadear combo")
	_ok(koliani.velocity == velocidade_antes,
		"ataque aéreo não devia alterar gravidade/velocidade permanentemente")
	koliani._ataque_restante = 0.09
	koliani._atualizar_janela_ataque()
	koliani._cancelar_ataque(true)
	_ok(not hitbox.monitoring and koliani._ataque_restante == 0.0
		and koliani._combo_passo == 0,
		"cancelamento devia limpar hitbox e estado do combo")

	Engine.time_scale = 1.0
	EstadoJogo.modo_teste = false
	if _falhas.is_empty():
		print("EXECUTION 7 COMBAT RUNTIME: PASS -- hitbox, deduplicacao, aereo e cancel")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			printerr("EXECUTION 7 COMBAT FALHOU: ", falha)
		get_tree().quit(1)


func _ok(condicao: bool, mensagem: String) -> void:
	if not condicao:
		_falhas.append(mensagem)
