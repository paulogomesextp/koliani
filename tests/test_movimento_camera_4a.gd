class_name TestMovimentoCamera4A
extends RefCounted
## Contratos técnicos da Execution 4A. Não tentam medir diversão/feel.

const DT := 1.0 / 60.0
const CameraMovimento := preload("res://scripts/camera_tremor.gd")


static func executar() -> Array[String]:
	var falhas: Array[String] = []
	_testar_run(falhas)
	_testar_salto_queda_ar(falhas)
	_testar_aterragem(falhas)
	_testar_camera(falhas)
	return falhas


static func _ok(condicao: bool, mensagem: String, falhas: Array[String]) -> void:
	if not condicao:
		falhas.append("4A: " + mensagem)


static func _testar_run(falhas: Array[String]) -> void:
	var e := Movimento.Estado.new()
	Movimento.passo(e, 1.0, false, false, true, DT)
	_ok(e.velocidade.x > 0.0, "o arranque responde no primeiro frame", falhas)
	for i in 7:
		Movimento.passo(e, 1.0, false, false, true, DT)
	_ok(is_equal_approx(e.velocidade.x, Movimento.VEL_CORRIDA),
		"a corrida converge para a velocidade máxima", falhas)

	e.velocidade.x = Movimento.VEL_CORRIDA
	for i in 6:
		Movimento.passo(e, 0.0, false, false, true, DT)
	_ok(e.velocidade.x > 0.0 and e.velocidade.x < 40.0,
		"a paragem desacelera sem gelo nem snap", falhas)

	e.velocidade.x = Movimento.VEL_CORRIDA
	Movimento.passo(e, -1.0, false, false, true, DT)
	_ok(e.velocidade.x < Movimento.VEL_CORRIDA,
		"a viragem reage no primeiro frame", falhas)
	for i in 9:
		Movimento.passo(e, -1.0, false, false, true, DT)
	_ok(e.velocidade.x < 0.0,
		"a viragem atravessa zero sem atraso artificial", falhas)


static func _testar_salto_queda_ar(falhas: Array[String]) -> void:
	var coyote := Movimento.Estado.new()
	Movimento.passo(coyote, 0.0, false, false, true, DT)
	Movimento.passo(coyote, 0.0, true, true, false, DT)
	_ok(coyote.velocidade.y < 0.0, "coyote time continua funcional", falhas)

	var buffer := Movimento.Estado.new()
	Movimento.passo(buffer, 0.0, true, true, false, DT)
	Movimento.passo(buffer, 0.0, false, true, true, DT)
	_ok(buffer.velocidade.y < 0.0 and buffer.buffer_restante == 0.0,
		"jump buffer dispara ao tocar no chão", falhas)

	var corte := Movimento.Estado.new()
	corte.velocidade.y = -Movimento.FORCA_SALTO
	Movimento.passo(corte, 0.0, false, false, false, DT)
	_ok(corte.velocidade.y > -Movimento.FORCA_SALTO * 0.6,
		"jump cut produz salto curto distinto", falhas)

	var subida := Movimento.aplicar_gravidade(-100.0, DT)
	var queda := Movimento.aplicar_gravidade(100.0, DT)
	_ok(queda - 100.0 > subida + 100.0,
		"a gravidade de queda é mais decisiva que a subida", falhas)

	var ar := Movimento.Estado.new()
	for i in 6:
		Movimento.passo(ar, 1.0, false, true, false, DT)
	_ok(ar.velocidade.x > 100.0 and ar.velocidade.x < Movimento.VEL_CORRIDA,
		"o controlo aéreo é forte mas não instantâneo", falhas)


static func _testar_aterragem(falhas: Array[String]) -> void:
	_ok(Movimento.tier_aterragem(179.0) == 0, "queda mínima não dá landing", falhas)
	_ok(Movimento.tier_aterragem(180.0) == 1, "landing leve", falhas)
	_ok(Movimento.tier_aterragem(430.0) == 2, "landing média", falhas)
	_ok(Movimento.tier_aterragem(760.0) == 3, "landing pesada", falhas)


static func _testar_camera(falhas: Array[String]) -> void:
	var cam := CameraMovimento.new()
	var r := Vector2.ZERO
	for i in 120:
		r = cam.passo_seguimento(DT, 1.0, Vector2(240.0, 0.0), 0.0, true)
	_ok(r.x > CameraMovimento.LOOK_AHEAD_X * 0.9,
		"look-ahead horizontal converge", falhas)

	for i in 3:
		r = cam.passo_seguimento(DT, -1.0, Vector2(-240.0, 0.0), 0.0, true)
	_ok(r.x > CameraMovimento.LOOK_AHEAD_X * 0.8,
		"micro-input de direção não provoca chicote", falhas)
	for i in 5:
		r = cam.passo_seguimento(DT, -1.0, Vector2(-240.0, 0.0), 0.0, true)
	_ok(r.x > CameraMovimento.LOOK_AHEAD_X * 0.9,
		"reversal espera confirmação sem deslocar o enquadramento", falhas)
	var antes_reversal := r.x
	r = cam.passo_seguimento(DT, -1.0, Vector2(-240.0, 0.0), 0.0, true)
	_ok(r.x < antes_reversal and antes_reversal - r.x < 16.0,
		"reversal começa sem snap horizontal", falhas)
	var anterior_x := r.x
	for i in 120:
		r = cam.passo_seguimento(DT, -1.0, Vector2(-240.0, 0.0), 0.0, true)
		_ok(r.x <= anterior_x and anterior_x - r.x < 16.0,
			"reversal horizontal é monotónico e sem whip", falhas)
		anterior_x = r.x
	_ok(r.x < -CameraMovimento.LOOK_AHEAD_X * 0.9,
		"mudança sustentada converge para o novo lado", falhas)

	for i in 120:
		r = cam.passo_seguimento(DT, 0.0, Vector2.ZERO, 0.0, true)
	_ok(absf(r.x) < 0.1,
		"input neutro converge sem oscilação", falhas)

	for i in 90:
		r = cam.passo_seguimento(DT, 0.0, Vector2(0.0, -180.0), -30.0, false)
	_ok(absf(-30.0 + r.y) < 1.0,
		"hop pequeno fica dentro da deadzone vertical", falhas)

	var cam_queda := CameraMovimento.new()
	var queda := Vector2.ZERO
	for i in 90:
		queda = cam_queda.passo_seguimento(
			DT, 0.0, Vector2(0.0, 500.0), 80.0, false)
	var antes_limiar := queda.y
	queda = cam_queda.passo_seguimento(
		DT, 0.0, Vector2(0.0, 500.0), 86.0, false)
	_ok(queda.y > antes_limiar and queda.y - antes_limiar < 1.0,
		"entrada no fall framing progride sem salto vertical", falhas)
	for i in 90:
		queda = cam_queda.passo_seguimento(
			DT, 0.0, Vector2(0.0, 720.0), 250.0, false)
	_ok(queda.y > 60.0, "queda significativa mostra espaço abaixo", falhas)
	var antes_aterragem := queda.y
	queda = cam_queda.passo_seguimento(DT, 0.0, Vector2.ZERO, 0.0, true)
	_ok(queda.y < antes_aterragem and antes_aterragem - queda.y < 8.0,
		"aterragem inicia recenter sem snap vertical", falhas)
	var anterior_y := queda.y
	for i in 90:
		queda = cam_queda.passo_seguimento(DT, 0.0, Vector2.ZERO, 0.0, true)
		_ok(queda.y >= 0.0 and queda.y <= anterior_y,
			"recenter após aterragem é monotónico e sem overshoot", falhas)
		anterior_y = queda.y
	_ok(absf(queda.y) < 0.1, "aterragem recentra suavemente", falhas)
	cam_queda.free()

	cam.definir_intensidade_tremor(CameraMovimento.IntensidadeTremor.DESLIGADO)
	_ok(cam.fator_tremor() == 0.0, "tremor Off", falhas)
	cam.definir_intensidade_tremor(CameraMovimento.IntensidadeTremor.REDUZIDO)
	_ok(cam.fator_tremor() > 0.0 and cam.fator_tremor() < 1.0,
		"tremor Reduced", falhas)
	cam.definir_intensidade_tremor(CameraMovimento.IntensidadeTremor.COMPLETO)
	_ok(cam.fator_tremor() == 1.0, "tremor Full", falhas)
	cam.free()
