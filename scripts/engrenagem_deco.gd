extends Sprite2D
## Engrenagem de cenario (N13, "sala das engrenagens"): so' gira. As
## vizinhas giram em sentidos opostos e a velocidades na razao dos tamanhos,
## como dentes engatados -- e' o que faz a sala ler-se como UMA maquina.

## Radianos por segundo (negativo = sentido contrario).
@export var velocidade := 0.3


func _process(dt: float) -> void:
	rotation += velocidade * dt
