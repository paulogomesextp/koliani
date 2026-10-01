extends Sprite2D
## Engrenagem de cenario (N13, "sala das engrenagens"): so' gira. As
## vizinhas giram em sentidos opostos e a velocidades na razao dos tamanhos,
## como dentes engatados -- e' o que faz a sala ler-se como UMA maquina.

## Radianos por segundo (negativo = sentido contrario).
@export var velocidade := 0.3
## Opt-in (N14, sinos pendurados do campanario): em vez de girar, BALANCA
## `balanco_graus` para cada lado, com `periodo_balanco` segundos por ida e
## volta. 0 = gira como sempre.
@export var balanco_graus := 0.0
@export var periodo_balanco := 4.0
@export var fase_balanco := 0.0

var _t := 0.0


func _process(dt: float) -> void:
	if balanco_graus > 0.0:
		_t += dt
		rotation = deg_to_rad(balanco_graus) \
			* sin(TAU * (_t / maxf(0.3, periodo_balanco) + fase_balanco))
		return
	rotation += velocidade * dt
