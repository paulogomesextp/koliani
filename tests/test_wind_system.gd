class_name TestesWindSystem
extends RefCounted
## Testes determinísticos da força externa. A integração Area2D/Player vive
## em `run_wind_system.gd`, que usa as cenas reais no motor.

const MovimentoScript := preload("res://scripts/movimento.gd")


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	var dt := 0.1

	_verificar_vetor(falhas, MovimentoScript.aplicar_forca_externa(
		Vector2(12.0, -30.0), Vector2.ZERO, 0.0, dt), Vector2(12.0, -30.0),
		"A: sem vento preserva a velocidade baseline")
	_verificar_vetor(falhas, MovimentoScript.aplicar_forca_externa(
		Vector2.ZERO, Vector2(100.0, 0.0), 300.0, dt), Vector2(10.0, 0.0),
		"B: vento horizontal fraco")
	_verificar_vetor(falhas, MovimentoScript.aplicar_forca_externa(
		Vector2.ZERO, Vector2(1000.0, 0.0), 300.0, dt), Vector2(100.0, 0.0),
		"C: vento horizontal forte")
	_verificar_vetor(falhas, MovimentoScript.aplicar_forca_externa(
		Vector2(-200.0, 0.0), Vector2(500.0, 0.0), 300.0, dt), Vector2(-150.0, 0.0),
		"D: vento oposto ao movimento soma força sem apagar o input")
	_verificar_vetor(falhas, MovimentoScript.aplicar_forca_externa(
		Vector2.ZERO, Vector2(0.0, -1000.0), 700.0, dt), Vector2(0.0, -100.0),
		"E: updraft usa a mesma força externa configurável")
	_verificar_vetor(falhas, MovimentoScript.aplicar_forca_externa(
		Vector2(0.0, -470.0), Vector2(0.0, -800.0), 700.0, dt), Vector2(0.0, -550.0),
		"F: salto dentro da zona preserva o impulso e recebe vento")
	_verificar_vetor(falhas, MovimentoScript.aplicar_forca_externa(
		Vector2(720.0, 0.0), Vector2(-900.0, 0.0), 400.0, dt), Vector2(630.0, 0.0),
		"I: dash dentro da zona não é substituído pelo vento")

	var composta := MovimentoScript.aplicar_forca_externa(
		Vector2.ZERO, Vector2(400.0, 0.0), 300.0, dt)
	composta = MovimentoScript.aplicar_forca_externa(
		composta, Vector2(0.0, -600.0), 500.0, dt)
	_verificar_vetor(falhas, composta, Vector2(40.0, -60.0),
		"K: duas influências independentes compõem-se")
	_verificar_vetor(falhas, MovimentoScript.aplicar_forca_externa(
		Vector2(75.0, -20.0), Vector2.ZERO, 300.0, dt), Vector2(75.0, -20.0),
		"L: sem influência não existe força residual")
	_verificar_vetor(falhas, MovimentoScript.aplicar_forca_externa(
		Vector2(300.0, 0.0), Vector2(1000.0, 0.0), 320.0, dt), Vector2(320.0, 0.0),
		"limite de velocidade atua só no sentido do vento")

	return falhas


static func _verificar_vetor(falhas: Array[String], obtido: Vector2,
		esperado: Vector2, mensagem: String) -> void:
	if not obtido.is_equal_approx(esperado):
		falhas.append("%s: esperado %s, obtido %s" % [mensagem, esperado, obtido])
