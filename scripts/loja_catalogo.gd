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

## Raridades, da mais comum para a mais rara (a ordem É o peso). Influenciam a
## ordenação (mais raro primeiro), o traço de cor do cartão e o detalhe.
const RARIDADES := ["comum", "raro", "epico", "lendario"]

## Pack dinâmico: preço = PACK_PERCENT % da soma dos equivalentes dos itens EM FALTA,
## arredondado ao passo da moeda e limitado pelo teto do pack (`k`/`v`).
## Os equivalentes (`k_eq`/`v_eq`) são só cálculo interno -- nunca mostrados.
const PACK_PERCENT := 70
const PACK_PASSO_K := 25
const PACK_PASSO_V := 5

## Campos de um item:
##  id, categoria, k (preço em Kolicoins ou -1), v (preço em Veracoins ou -1),
##  regiao (índice 0..19 da região que tem de estar concluída, ou -1),
##  inicial (já vem adquirido), destaque, preview (textura ou "" = placeholder),
##  placeholder (true = apresentação neutra só para QA, NÃO é arte final),
##  efeito ("cosmetico"), raridade (uma de RARIDADES).
##  Packs: `contem` (ids) e `k`/`v` = TETO do preço; os itens contidos levam
##  `k_eq`/`v_eq` (equivalentes para o cálculo do pack).
## Texto: chaves i18n `shop.item.<id>.name` e `shop.item.<id>.desc`.
const ITENS := [
	{"id": "skin_koliani_base", "categoria": "skins", "k": -1, "v": -1, "regiao": -1, "raridade": "comum",
		"inicial": true, "destaque": false, "preview": "", "placeholder": true, "efeito": "cosmetico"},
	{"id": "skin_carmesim", "categoria": "skins", "k": 300, "v": -1, "regiao": -1, "raridade": "comum",
		"inicial": false, "destaque": true, "preview": "", "placeholder": true, "efeito": "cosmetico"},
	{"id": "skin_luar", "categoria": "skins", "k": -1, "v": 150, "regiao": -1, "raridade": "epico",
		"inicial": false, "destaque": true, "preview": "", "placeholder": true, "efeito": "cosmetico"},
	{"id": "efeito_rasto_brasa", "categoria": "efeitos", "k": 500, "v": 120, "regiao": -1, "raridade": "raro",
		"inicial": false, "destaque": true, "preview": "", "placeholder": true, "efeito": "cosmetico"},
	{"id": "hud_moldura_osso", "categoria": "hud_checkpoint", "k": 250, "v": 60, "regiao": -1, "raridade": "comum",
		"inicial": false, "destaque": false, "preview": "", "placeholder": true, "efeito": "cosmetico"},
	{"id": "extra_galeria_conceitos", "categoria": "extras", "k": 400, "v": -1, "regiao": -1, "raridade": "comum",
		"inicial": false, "destaque": false, "preview": "", "placeholder": true, "efeito": "cosmetico"},
	# --- Coleção Região I: Relíquias do Coração Podre (Heartrot Relics) ------
	{"id": "skin_coracao_podre", "categoria": "skins", "k": -1, "v": 240, "regiao": 0, "raridade": "epico",
		"k_eq": 960, "v_eq": 240,
		"inicial": false, "destaque": true, "preview": "", "placeholder": true, "efeito": "cosmetico"},
	{"id": "efeito_rasto_esporos", "categoria": "efeitos", "k": 600, "v": 120, "regiao": 0, "raridade": "raro",
		"k_eq": 600, "v_eq": 120,
		"inicial": false, "destaque": false, "preview": "", "placeholder": true, "efeito": "cosmetico"},
	{"id": "hud_moldura_raizes", "categoria": "hud_checkpoint", "k": 300, "v": -1, "regiao": 0, "raridade": "raro",
		"k_eq": 300, "v_eq": 75,
		"inicial": false, "destaque": false, "preview": "", "placeholder": true, "efeito": "cosmetico"},
	{"id": "pack_coracao_podre", "categoria": "packs", "k": 1300, "v": 300, "regiao": 0, "raridade": "lendario",
		"contem": ["skin_coracao_podre", "efeito_rasto_esporos", "hud_moldura_raizes"],
		"inicial": false, "destaque": true, "preview": "", "placeholder": true, "efeito": "cosmetico"},
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


## Itens de uma categoria. "destaques" = os marcados como destaque. Ordem: os
## iniciais primeiro e depois do mais raro para o mais comum (estável).
static func da_categoria(cat: String) -> Array:
	var fora := []
	for it: Dictionary in ITENS:
		if cat == "destaques":
			if it["destaque"]:
				fora.append(it)
		elif it["categoria"] == cat:
			fora.append(it)
	var pos := {}
	for i in ITENS.size():
		pos[ITENS[i]["id"]] = i
	fora.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a["inicial"]) != bool(b["inicial"]):
			return bool(a["inicial"])
		var ra := RARIDADES.find(a["raridade"])
		var rb := RARIDADES.find(b["raridade"])
		if ra != rb:
			return ra > rb
		return pos[a["id"]] < pos[b["id"]])
	return fora


static func preco(it: Dictionary, moeda: String) -> int:
	return int(it.get(moeda, -1))


static func e_pack(it: Dictionary) -> bool:
	return it.has("contem")


## Preço do pack para o jogador: só os itens EM FALTA (`tem` diz se um id já é
## dele). -1 se não falta nada ou o pack não aceita a moeda.
static func preco_pack(it: Dictionary, moeda: String, tem: Callable) -> int:
	var teto := preco(it, moeda)
	if teto < 0:
		return -1
	var soma := 0
	for id: String in it["contem"]:
		if not bool(tem.call(id)):
			soma += int(item(id).get("k_eq" if moeda == KOLICOINS else "v_eq", 0))
	if soma <= 0:
		return -1
	var passo := PACK_PASSO_K if moeda == KOLICOINS else PACK_PASSO_V
	# aritmética inteira: arredonda ao passo (metade para cima), sem ambiguidades de float
	var p := maxi(passo, (soma * PACK_PERCENT + passo * 50) / (passo * 100) * passo)
	return mini(p, teto)


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
static func validar(itens: Array = ITENS) -> Array[String]:
	var erros: Array[String] = []
	var ids := {}
	for it: Dictionary in itens:
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
		if not (str(it.get("raridade", "")) in RARIDADES):
			erros.append("raridade desconhecida em " + id)
		if it.has("contem"):
			if it["categoria"] != "packs" or k < 0 or v < 0:
				erros.append("pack mal formado (categoria/tetos K e V): " + id)
			for c in it["contem"]:
				var ci := item(str(c))
				if ci.is_empty() or ci.has("contem"):
					erros.append("pack %s contem item invalido: %s" % [id, str(c)])
				elif int(ci.get("k_eq", 0)) <= 0 or int(ci.get("v_eq", 0)) <= 0:
					erros.append("item de pack sem equivalentes k_eq/v_eq: " + str(c))
		elif it["categoria"] == "packs":
			erros.append("pack sem `contem`: " + id)
	return erros
