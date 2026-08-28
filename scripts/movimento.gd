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


static func passo(e: Estado, direcao: float, saltar_premido: bool, saltar_a_segurar: bool, no_chao: bool, dt: float) -> Estado:
	# temporizadores
	if no_chao:
		e.coyote_restante = COYOTE
	else:
		e.coyote_restante = maxf(0.0, e.coyote_restante - dt)
	e.buffer_restante = maxf(0.0, e.buffer_restante - dt)
	if saltar_premido:
		e.buffer_restante = BUFFER_SALTO

	# horizontal
	var alvo := direcao * VEL_CORRIDA
	var acel := ACEL_CHAO if no_chao else ACEL_AR
	e.velocidade.x = move_toward(e.velocidade.x, alvo, acel * dt)

	# salto (buffer + coyote)
	if e.buffer_restante > 0.0 and e.coyote_restante > 0.0:
		e.velocidade.y = -FORCA_SALTO
		e.buffer_restante = 0.0
		e.coyote_restante = 0.0

	# gravidade
	if not no_chao:
		e.velocidade.y = minf(VEL_MAX_QUEDA, e.velocidade.y + GRAVIDADE * dt)

	# corte de salto
	if e.velocidade.y < 0.0 and not saltar_a_segurar:
		e.velocidade.y *= CORTE_SALTO

	e.no_chao = no_chao
	return e
