extends RefCounted
## Sorteio puro: 50% Essência, 20% arma, 15% armadura, 15% atributo.
## Categorias esgotadas convertem-se em Essência; nunca dá duplicados.
const EQUIP := preload("res://scripts/equipamento.gd")
const MELH := preload("res://scripts/melhorias.gd")

static func sortear(indice: int, armas: Array, armaduras: Array,
		melhorias: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var moeda := {"tipo": "essencia", "valor": 35 + mini(maxi(indice, 0), 99) * 3}
	var dado := rng.randi_range(0, 99)
	if dado < 50:
		return moeda
	var candidatos: Array[Dictionary] = []
	if dado < 85:
		var arma := dado < 70
		for item: Dictionary in (EQUIP.ARMAS if arma else EQUIP.ARMADURAS):
			if int(item.nivel) <= indice + 1 and item.id not in (armas if arma else armaduras):
				candidatos.append({"tipo": "arma" if arma else "armadura", "id": item.id, "nome": item.nome})
	else:
		for id: String in MELH.ORDEM:
			if int(melhorias.get(id, 0)) < MELH.max_rank(id):
				candidatos.append({"tipo": "melhoria", "id": id})
	return moeda if candidatos.is_empty() else candidatos[rng.randi_range(0, candidatos.size() - 1)]
