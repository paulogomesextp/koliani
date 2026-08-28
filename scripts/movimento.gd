class_name Movimento
extends RefCounted
## Logica PURA do movimento da Koliani -- sem nós, sem física do Godot,
## só matemática. Fica separada de `koliani.gd` para poder ser testada com
## `godot --headless` (ver tests/test_movimento.gd).
##
## Cobre as manhas que dão a "pegada" tipo Dead Cells:
##  - coyote time (saltar logo depois de sair da plataforma)
##  - jump buffer (carregar em saltar um pouco antes de aterrar)
##  - corte de salto (largar o botão a meio encurta o pulo)
##  - saltos extra no ar (salto duplo) quando `saltos_max` > 1 -- a
##    habilidade permanente "salto_duplo" liga isto em `koliani.gd`

const GRAVIDADE := 1400.0
const VEL_MAX_QUEDA := 1100.0
const VEL_CORRIDA := 240.0
const ACEL_CHAO := 2000.0
const ACEL_AR := 1200.0
const FORCA_SALTO := 470.0
const COYOTE := 0.10          # segundos
const BUFFER_SALTO := 0.12    # segundos
const CORTE_SALTO := 0.45     # fração da velocidade vertical mantida ao largar

## Estado mutável passado de frame para frame.
class Estado:
	var velocidade := Vector2.ZERO
	var coyote_restante := 0.0
	var buffer_restante := 0.0
	var no_chao := false
	## Saltos já gastos desde que saiu do chão (o 1.º salto conta mesmo
	## quando é feito no coyote time). Volta a 0 ao tocar no chão.
	var saltos_dados := 0


## `saltos_max` = quantos saltos a Koliani pode encadear no ar antes de
## voltar a tocar no chão (1 = normal, 2 = salto duplo).
static func passo(e: Estado, direcao: float, saltar_premido: bool, saltar_a_segurar: bool, no_chao: bool, dt: float, saltos_max: int = 1) -> Estado:
	# temporizadores
	if no_chao:
		e.coyote_restante = COYOTE
		e.saltos_dados = 0
	else:
		e.coyote_restante = maxf(0.0, e.coyote_restante - dt)
	e.buffer_restante = maxf(0.0, e.buffer_restante - dt)
	if saltar_premido:
		e.buffer_restante = BUFFER_SALTO

	# horizontal
	var alvo := direcao * VEL_CORRIDA
	var acel := ACEL_CHAO if no_chao else ACEL_AR
	e.velocidade.x = move_toward(e.velocidade.x, alvo, acel * dt)

	# quem sai da plataforma a andar (sem saltar) e deixa o coyote expirar
	# perde o "salto do chão": o próximo salto no ar já é o 2.º
	if not no_chao and e.coyote_restante <= 0.0 and e.saltos_dados == 0:
		e.saltos_dados = 1

	# salto: 1.º usa buffer + coyote; os seguintes só enquanto houver
	# saltos_max por gastar (salto duplo)
	var pode_saltar_chao := e.coyote_restante > 0.0 and e.saltos_dados == 0
	var pode_saltar_ar := e.saltos_dados > 0 and e.saltos_dados < saltos_max
	if e.buffer_restante > 0.0 and (pode_saltar_chao or pode_saltar_ar):
		e.velocidade.y = -FORCA_SALTO
		e.buffer_restante = 0.0
		e.coyote_restante = 0.0
		e.saltos_dados += 1

	# gravidade
	if not no_chao:
		e.velocidade.y = minf(VEL_MAX_QUEDA, e.velocidade.y + GRAVIDADE * dt)

	# corte de salto
	if e.velocidade.y < 0.0 and not saltar_a_segurar:
		e.velocidade.y *= CORTE_SALTO

	e.no_chao = no_chao
	return e
