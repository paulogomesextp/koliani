class_name TestesGlideRegiao02
extends RefCounted
## PROCESS 11 -- contrato determinístico do planar (glide) sobre o
## `Movimento` puro. A integração com `ZonaPlanar`/`WindZone`/Koliani reais
## (contexto, dash, dano, morte, respawn, cena) vive em
## `run_glide_region02.gd`, que corre no motor.

const MovimentoScript := preload("res://scripts/movimento.gd")
const DT := 1.0 / 60.0


static func executar() -> Array[String]:
	var falhas: Array[String] = []

	# A -- salto normal sem planar: sobe com a força do salto e a queda
	# passa o tecto do planar (não há nada a travar)
	var a := _novo_no_chao()
	a = MovimentoScript.passo(a, 0.0, true, true, true, DT, 1)
	_verificar(falhas, is_equal_approx(a.velocidade.y, -MovimentoScript.FORCA_SALTO),
		"A: salto normal sai com FORCA_SALTO (obtido %.1f)" % a.velocidade.y)
	var queda_livre := _cair(false, 1.0)
	_verificar(falhas, queda_livre.velocidade.y > MovimentoScript.VEL_PLANAR * 2.0,
		"A: sem planar a queda passa largamente o tecto do planar (%.1f)" % queda_livre.velocidade.y)

	# B -- ativar a meio da queda prende logo a velocidade ao tecto
	var b := _cair(false, 0.5)
	_verificar(falhas, b.velocidade.y > MovimentoScript.VEL_PLANAR,
		"B: pré-condição -- já cai depressa antes de planar")
	b = MovimentoScript.passo(b, 0.0, false, true, false, DT, 1, 1.0, 1.0, true)
	_verificar(falhas, is_equal_approx(b.velocidade.y, MovimentoScript.VEL_PLANAR),
		"B: ativar planar em queda prende a velocidade a VEL_PLANAR (obtido %.1f)" % b.velocidade.y)

	# C -- planar nunca cria subida: segurado durante 5 s a partir do topo do
	# arco, a velocidade vertical nunca fica negativa
	var c := _novo_no_ar(Vector2(0.0, 0.0))
	var menor_vy := INF
	for _i in int(5.0 / DT):
		c = MovimentoScript.passo(c, 1.0, false, true, false, DT, 1, 1.0, 1.0, true)
		menor_vy = minf(menor_vy, c.velocidade.y)
	_verificar(falhas, menor_vy >= 0.0,
		"C: planar não gera subida (menor vy %.2f)" % menor_vy)
	# ...e a subida de um salto não é prolongada: planar só atua a descer
	var c2 := _novo_no_ar(Vector2(0.0, -MovimentoScript.FORCA_SALTO))
	var c3 := _novo_no_ar(Vector2(0.0, -MovimentoScript.FORCA_SALTO))
	c2 = MovimentoScript.passo(c2, 0.0, false, true, false, DT, 1, 1.0, 1.0, true)
	c3 = MovimentoScript.passo(c3, 0.0, false, true, false, DT, 1, 1.0, 1.0, false)
	_verificar(falhas, is_equal_approx(c2.velocidade.y, c3.velocidade.y),
		"C: a subir, planar e sem planar dão a mesma velocidade")

	# D -- a gravidade continua a atuar: a partir do repouso no ar, com
	# planar, a queda acelera até ao tecto (não fica parada no ar)
	var d := _novo_no_ar(Vector2.ZERO)
	d = MovimentoScript.passo(d, 0.0, false, true, false, DT, 1, 1.0, 1.0, true)
	_verificar(falhas, d.velocidade.y > 0.0 and d.velocidade.y < MovimentoScript.VEL_PLANAR,
		"D: gravidade continua funcional sob planar (vy %.2f)" % d.velocidade.y)

	# E -- largar o botão devolve a queda normal no frame seguinte
	var e := _cair(true, 1.0)
	_verificar(falhas, is_equal_approx(e.velocidade.y, MovimentoScript.VEL_PLANAR),
		"E: pré-condição -- em planar estável")
	var e2 := MovimentoScript.passo(e, 0.0, false, false, false, DT, 1, 1.0, 1.0, false)
	_verificar(falhas, e2.velocidade.y > MovimentoScript.VEL_PLANAR,
		"E: largar planar volta a acelerar a queda (vy %.2f)" % e2.velocidade.y)

	# H -- vento + planar: a força externa soma-se DEPOIS do tecto. Um vento
	# lateral muda só o x; o tecto do planar mantém-se no frame seguinte
	var h := _cair(true, 1.0)
	var h_vel := MovimentoScript.aplicar_forca_externa(
		h.velocidade, Vector2(2000.0, 0.0), 420.0, DT)
	_verificar(falhas, h_vel.x > h.velocidade.x and is_equal_approx(h_vel.y, h.velocidade.y),
		"H: vento lateral em planar empurra só na horizontal")
	# vento contra 1600: mais forte do que a aceleração aérea (1350) mas não do
	# que a viragem no ar (1800) -- a segurar em frente o planar ENCALHA à
	# volta de vx 0; sem direção recua até velocidade_max
	var hc := _novo_no_ar(Vector2(MovimentoScript.VEL_CORRIDA, MovimentoScript.VEL_PLANAR))
	for _i in int(1.5 / DT):
		hc = MovimentoScript.passo(hc, 1.0, false, true, false, DT, 1, 1.0, 1.0, true)
		hc.velocidade = MovimentoScript.aplicar_forca_externa(
			hc.velocidade, Vector2(-1600.0, 0.0), 150.0, DT)
	_verificar(falhas, absf(hc.velocidade.x) <= 40.0,
		"H: rajada contra (1600) anula o avanço a segurar em frente (vx %.1f)" % hc.velocidade.x)
	for _i in int(1.0 / DT):
		hc = MovimentoScript.passo(hc, 0.0, false, true, false, DT, 1, 1.0, 1.0, true)
		hc.velocidade = MovimentoScript.aplicar_forca_externa(
			hc.velocidade, Vector2(-1600.0, 0.0), 150.0, DT)
	_verificar(falhas, hc.velocidade.x < -140.0 and hc.velocidade.x >= -150.0 - 0.01,
		"H: sem direção a rajada contra faz recuar até velocidade_max (vx %.1f)" % hc.velocidade.x)
	_verificar(falhas, is_equal_approx(hc.velocidade.y, MovimentoScript.VEL_PLANAR),
		"H: o vento lateral não mexe no tecto do planar")

	# I -- corrente ascendente + planar: só a força externa sobe, e com teto
	var i := _cair(true, 0.5)
	var menor_i := INF
	for _k in int(3.0 / DT):
		i = MovimentoScript.passo(i, 0.0, false, true, false, DT, 1, 1.0, 1.0, true)
		i.velocidade = MovimentoScript.aplicar_forca_externa(
			i.velocidade, Vector2(0.0, -2600.0), 340.0, DT)
		menor_i = minf(menor_i, i.velocidade.y)
	_verificar(falhas, menor_i < 0.0 and menor_i >= -340.0 - 0.01,
		"I: updraft levanta o planar mas respeita velocidade_max (menor vy %.1f)" % menor_i)
	# e o mesmo updraft, com planar e SEM updraft, deixa de subir
	for _k in int(1.0 / DT):
		i = MovimentoScript.passo(i, 0.0, false, true, false, DT, 1, 1.0, 1.0, true)
	_verificar(falhas, is_equal_approx(i.velocidade.y, MovimentoScript.VEL_PLANAR),
		"I: fora da corrente volta ao tecto do planar (vy %.1f)" % i.velocidade.y)

	# N -- múltiplas ativações: ligar/desligar 20 vezes nunca acumula nada
	var n := _cair(false, 0.6)
	for ciclo in 20:
		var ligado := ciclo % 2 == 0
		for _k in 6:
			n = MovimentoScript.passo(n, 0.0, false, ligado, false, DT, 1, 1.0, 1.0, ligado)
		if ligado and not is_equal_approx(n.velocidade.y, MovimentoScript.VEL_PLANAR):
			falhas.append("N: ciclo %d ligado não ficou no tecto (%.1f)" % [ciclo, n.velocidade.y])
		if not ligado and n.velocidade.y <= MovimentoScript.VEL_PLANAR:
			falhas.append("N: ciclo %d desligado não voltou a acelerar (%.1f)" % [ciclo, n.velocidade.y])

	# F (parte pura) -- aterrar com o botão seguro: no chão o planar não faz
	# nada e o salto seguinte sai inteiro
	var f := _cair(true, 1.0)
	f = MovimentoScript.passo(f, 0.0, false, true, true, DT, 2, 1.0, 1.0, true)
	f.velocidade.y = 0.0
	f = MovimentoScript.passo(f, 0.0, true, true, true, DT, 2, 1.0, 1.0, true)
	_verificar(falhas, is_equal_approx(f.velocidade.y, -MovimentoScript.FORCA_SALTO),
		"F: depois de aterrar a planar o salto sai inteiro (%.1f)" % f.velocidade.y)
	_verificar(falhas, f.saltos_dados == 1,
		"F: aterrar repõe os saltos (saltos_dados %d)" % f.saltos_dados)

	return falhas


static func _novo_no_chao() -> MovimentoScript.Estado:
	var e := MovimentoScript.Estado.new()
	e.no_chao = true
	e.coyote_restante = MovimentoScript.COYOTE
	return e


static func _novo_no_ar(vel: Vector2) -> MovimentoScript.Estado:
	var e := MovimentoScript.Estado.new()
	e.velocidade = vel
	e.saltos_dados = 1
	return e


## Cai `segundos` a partir do repouso no ar, com ou sem planar.
static func _cair(planar: bool, segundos: float) -> MovimentoScript.Estado:
	var e := _novo_no_ar(Vector2.ZERO)
	for _i in int(segundos / DT):
		e = MovimentoScript.passo(e, 0.0, false, planar, false, DT, 1, 1.0, 1.0, planar)
	return e


static func _verificar(falhas: Array[String], condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas.append(mensagem)
