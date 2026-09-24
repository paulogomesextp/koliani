class_name LojaCatalogo
extends RefCounted
## CATÁLOGO CENTRAL DA LOJA. Todos os preços, categorias e requisitos vivem
## aqui -- a UI só lê. Nada aqui altera gameplay: a loja vende COSMÉTICOS
## (skins, efeitos, molduras de HUD, fogueiras, extras, packs).
##
## REGRA DE DESIGN (fixa): Veracoins NÃO compram vantagem de jogo -- nada de
## vida, dano, cooldown, buffs, progressão paga ou desbloqueio de níveis.
## O campo `efeito` de um item é SEMPRE "cosmetico"; `LojaCatalogo.validar()`
## e os testes recusam qualquer outro valor.
##
## Moedas:
##  - KOLICOINS ("k")  -- ganham-se a jogar níveis (`EstadoJogo`);
##  - VERACOINS ("v")  -- premium; no futuro comprada com dinheiro real (ainda
##    NÃO existe pagamento nenhum).
## Um preço < 0 significa "não aceita esta moeda".

const KOLICOINS := "k"
const VERACOINS := "v"

## Ordem de apresentação das categorias. "destaques" é derivada (itens com
## `destaque = true`), não guarda itens próprios.
const CATEGORIAS := ["destaques", "skins", "efeitos", "hud_checkpoint", "extras", "packs"]

## Categorias com um único item equipado de cada vez (o slot é a categoria).
const EQUIPAVEIS := ["skins", "efeitos", "hud_checkpoint"]

## BALANCE_PLACEHOLDER -- valores provisórios, a balancear mais tarde.
const KOLICOINS_POR_NIVEL := 25
const KOLICOINS_POR_EXAME_REGIONAL := 100

## Campos de um item:
##  id, categoria, k (preço em Kolicoins ou -1), v (preço em Veracoins ou -1),
##  regiao (índice 0..19 da região que tem de estar concluída, ou -1),
##  inicial (já vem adquirido), destaque, preview (textura ou "" = placeholder),
##  placeholder (true = apresentação neutra só para QA, NÃO é arte final),
##  efeito ("cosmetico").
## Texto: chaves i18n `shop.item.<id>.name` e `shop.item.<id>.desc`.
const ITENS := [
	{"id": "skin_koliani_base", "categoria": "skins", "k": -1, "v": -1, "regiao": -1,
		"inicial": true, "destaque": false, "preview": "", "placeholder": true, "efeito": "cosmetico"},
	{"id": "skin_carmesim", "categoria": "skins", "k": 300, "v": -1, "regiao": -1,
		"inicial": false, "destaque": true, "preview": "", "placeholder": true, "efeito": "cosmetico"},
	{"id": "skin_luar", "categoria": "skins", "k": -1, "v": 150, "regiao": -1,
		"inicial": false, "destaque": true, "preview": "", "placeholder": true, "efeito": "cosmetico"},
	{"id": "efeito_rasto_brasa", "categoria": "efeitos", "k": 500, "v": 120, "regiao": -1,
		"inicial": false, "destaque": true, "preview": "", "placeholder": true, "efeito": "cosmetico"},
	{"id": "hud_moldura_osso", "categoria": "hud_checkpoint", "k": 250, "v": 60, "regiao": -1,
		"inicial": false, "destaque": false, "preview": "", "placeholder": true, "efeito": "cosmetico"},
	{"id": "extra_galeria_conceitos", "categoria": "extras", "k": 400, "v": -1, "regiao": -1,
		"inicial": false, "destaque": false, "preview": "", "placeholder": true, "efeito": "cosmetico"},
	{"id": "pack_regiao_i", "categoria": "packs", "k": 800, "v": 200, "regiao": 0,
		"inicial": false, "destaque": false, "preview": "", "placeholder": true, "efeito": "cosmetico"},
]


static func todos() -> Array:
	return ITENS


static func item(id: String) -> Dictionary:
	for it: Dictionary in ITENS:
		if it["id"] == id:
			return it
	return {}


static func existe(id: String) -> bool:
	return not item(id).is_empty()


## Itens de uma categoria. "destaques" = os marcados como destaque.
static func da_categoria(cat: String) -> Array:
	var fora := []
	for it: Dictionary in ITENS:
		if cat == "destaques":
			if it["destaque"]:
				fora.append(it)
		elif it["categoria"] == cat:
			fora.append(it)
	return fora


static func preco(it: Dictionary, moeda: String) -> int:
	return int(it.get(moeda, -1))


## Moedas que o item aceita, por ordem (Kolicoins primeiro).
static func moedas_aceites(it: Dictionary) -> Array:
	var m := []
	for moeda in [KOLICOINS, VERACOINS]:
		if preco(it, moeda) >= 0:
			m.append(moeda)
	return m


## Coleção regional futura: `regiao` (0..19) exige essa região concluída.
## Devolve os itens que uma região desbloqueia.
static func da_regiao(regiao: int) -> Array:
	var fora := []
	for it: Dictionary in ITENS:
		if int(it["regiao"]) == regiao:
			fora.append(it)
	return fora


## Lista de erros do catálogo (vazia = válido).
static func validar() -> Array[String]:
	var erros: Array[String] = []
	var ids := {}
	for it: Dictionary in ITENS:
		var id := str(it.get("id", ""))
		if id == "":
			erros.append("item sem id")
			continue
		if ids.has(id):
			erros.append("id duplicado: " + id)
		ids[id] = true
		if not (str(it.get("categoria", "")) in CATEGORIAS) or it["categoria"] == "destaques":
			erros.append("categoria invalida em " + id)
		if str(it.get("efeito", "")) != "cosmetico":
			erros.append("item com efeito de gameplay: " + id)
		var k := preco(it, KOLICOINS)
		var v := preco(it, VERACOINS)
		if not bool(it.get("inicial", false)) and k < 0 and v < 0:
			erros.append("sem preco em nenhuma moeda: " + id)
		if k == 0 or v == 0:
			erros.append("preco zero em " + id)
		var r := int(it.get("regiao", -1))
		if r < -1 or r > 19:
			erros.append("regiao fora de -1..19 em " + id)
	return erros
