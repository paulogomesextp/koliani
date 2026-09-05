class_name Fogueiras
extends RefCounted
## Lógica pura das fogueiras (checkpoints) de um nível -- sem cena e sem
## autoloads, para o corredor de testes a poder carregar (o `checkpoint.gd`
## usa o `EstadoJogo`, e em `--script` os autoloads não existem à compilação).

## De `pos`, qual a fogueira mais perto da `arena` do chefe: essa é a
## ÚLTIMA do nível, a que arranca a música de combate ao ser acesa (pedido
## do Paulo, 5 set 2026 -- antes a cama de chefe só entrava ao 1.º golpe).
## Devolve o índice, ou -1 se não houver nenhuma. Ganha só uma; em empate
## fica a primeira, que é melhor que tocar a música em duas fogueiras.
static func indice_da_do_chefe(pos: Array[Vector2], arena: Vector2) -> int:
	var melhor := -1
	var menor := INF
	for i in pos.size():
		var d := pos[i].distance_squared_to(arena)
		if d < menor:
			menor = d
			melhor = i
	return melhor
