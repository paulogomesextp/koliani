class_name Equipamento
extends RefCounted
## DADOS PUROS das 15 armas + 15 armaduras da campanha. Sem lógica de jogo,
## sem autoloads -- é uma tabela, testável com `--script`.
##
## Progresso: ao acabar cada nível ganha-se UM equipamento. Níveis ímpares
## (1, 3, 5, ...) dão a arma seguinte; níveis pares (2, 4, ...) a armadura
## seguinte. Ver `EstadoJogo.conceder_recompensa()`.
##
## Efeito no jogo (ver koliani.gd / EstadoJogo):
##   arma     -> `dano` = dano do ataque corpo-a-corpo da Koliani.
##   armadura -> `vida_bonus` soma à vida máxima; `reducao` (0..1) corta o
##               dano recebido.
## Ícone: chave em `assets/sprites/pixel/gear/<id>.png` (gerado por
## `tools/gerar_sprites.gd`).

## id -> { nome: chave i18n, dano: int, nivel: int (nível que a desbloqueia, 1-based) }
# NB: dano das armas DUPLICADO a pedido do Paulo (ago 2026) -- a espada
# e os tiros passaram a bater o dobro. Curva mantida (não-decrescente).
const ARMAS: Array[Dictionary] = [
	{ "id": "lamina_gasta",         "nome": "gear.w.lamina_gasta",         "dano": 48, "nivel": 1 },
	{ "id": "foice_do_pantano",     "nome": "gear.w.foice_do_pantano",     "dano": 54, "nivel": 3 },
	{ "id": "garra_da_viuva",       "nome": "gear.w.garra_da_viuva",       "dano": 60, "nivel": 5 },
	{ "id": "espinho_da_arvore",    "nome": "gear.w.espinho_da_arvore",    "dano": 66, "nivel": 7 },
	{ "id": "martelo_do_carcereiro","nome": "gear.w.martelo_do_carcereiro","dano": 74, "nivel": 9 },
	{ "id": "forjaluz",             "nome": "gear.w.forjaluz",             "dano": 80, "nivel": 11 },
	{ "id": "badalo_de_bronze",     "nome": "gear.w.badalo_de_bronze",     "dano": 86, "nivel": 13 },
	{ "id": "lanca_da_tempestade",  "nome": "gear.w.lanca_da_tempestade",  "dano": 92, "nivel": 15 },
	{ "id": "crescente_lunar",      "nome": "gear.w.crescente_lunar",      "dano": 98, "nivel": 17 },
	{ "id": "presa_de_vyrak",       "nome": "gear.w.presa_de_vyrak",       "dano": 104, "nivel": 19 },
	{ "id": "cetro_de_osso",        "nome": "gear.w.cetro_de_osso",        "dano": 108, "nivel": 21 },
	{ "id": "cutelo_real",          "nome": "gear.w.cutelo_real",          "dano": 112, "nivel": 23 },
	{ "id": "gladio_purpura",       "nome": "gear.w.gladio_purpura",       "dano": 116, "nivel": 25 },
	{ "id": "fio_do_eclipse",       "nome": "gear.w.fio_do_eclipse",       "dano": 120, "nivel": 27 },
	{ "id": "estilhaco_de_zeriko",  "nome": "gear.w.estilhaco_de_zeriko",  "dano": 128, "nivel": 29 },
]

## id -> { nome, vida_bonus: int, reducao: float 0..1, nivel: int }
const ARMADURAS: Array[Dictionary] = [
	{ "id": "trapos_de_viajante",    "nome": "gear.a.trapos_de_viajante",    "vida_bonus": 0,   "reducao": 0.00, "nivel": 2 },
	{ "id": "couro_do_pantano",      "nome": "gear.a.couro_do_pantano",      "vida_bonus": 10,  "reducao": 0.03, "nivel": 4 },
	{ "id": "casca_de_teia",         "nome": "gear.a.casca_de_teia",         "vida_bonus": 18,  "reducao": 0.05, "nivel": 6 },
	{ "id": "casaco_de_seiva",       "nome": "gear.a.casaco_de_seiva",       "vida_bonus": 25,  "reducao": 0.07, "nivel": 8 },
	{ "id": "malha_do_carcereiro",   "nome": "gear.a.malha_do_carcereiro",   "vida_bonus": 35,  "reducao": 0.09, "nivel": 10 },
	{ "id": "placas_de_brasa",       "nome": "gear.a.placas_de_brasa",       "vida_bonus": 45,  "reducao": 0.11, "nivel": 12 },
	{ "id": "manto_dos_sinos",       "nome": "gear.a.manto_dos_sinos",       "vida_bonus": 52,  "reducao": 0.13, "nivel": 14 },
	{ "id": "arnes_da_tempestade",   "nome": "gear.a.arnes_da_tempestade",   "vida_bonus": 60,  "reducao": 0.15, "nivel": 16 },
	{ "id": "veu_lunar",             "nome": "gear.a.veu_lunar",             "vida_bonus": 68,  "reducao": 0.17, "nivel": 18 },
	{ "id": "escamas_de_vyrak",      "nome": "gear.a.escamas_de_vyrak",      "vida_bonus": 78,  "reducao": 0.19, "nivel": 20 },
	{ "id": "couraca_de_osso",       "nome": "gear.a.couraca_de_osso",       "vida_bonus": 88,  "reducao": 0.21, "nivel": 22 },
	{ "id": "avental_do_acougueiro", "nome": "gear.a.avental_do_acougueiro", "vida_bonus": 95,  "reducao": 0.23, "nivel": 24 },
	{ "id": "batina_purpura",        "nome": "gear.a.batina_purpura",        "vida_bonus": 102, "reducao": 0.25, "nivel": 26 },
	{ "id": "vestido_do_eclipse",    "nome": "gear.a.vestido_do_eclipse",    "vida_bonus": 110, "reducao": 0.27, "nivel": 28 },
	{ "id": "egide_de_aurora",       "nome": "gear.a.egide_de_aurora",       "vida_bonus": 120, "reducao": 0.30, "nivel": 30 },
]


static func arma(id: String) -> Dictionary:
	for a in ARMAS:
		if a["id"] == id:
			return a
	return {}


static func armadura(id: String) -> Dictionary:
	for a in ARMADURAS:
		if a["id"] == id:
			return a
	return {}


## Índice (0-based) do item na sua lista, ou -1. Serve para o `frame` da
## tira de sprites e para as cores por tier.
static func indice_arma(id: String) -> int:
	for i in ARMAS.size():
		if ARMAS[i]["id"] == id:
			return i
	return -1


static func indice_armadura(id: String) -> int:
	for i in ARMADURAS.size():
		if ARMADURAS[i]["id"] == id:
			return i
	return -1


## Cor dominante de cada lâmina da tira `gear/armas.png` (extraída do pack
## `thewisehedgehog` por `tools/extrair_armas.gd`). O brilho e os efeitos do
## golpe (`koliani.gd::_cor_golpe`) seguem esta cor -- cada arma acende com
## a sua.
const COR_ARMA: Array[Color] = [
	Color(0.53, 0.55, 0.46),  # 0  lâmina gasta      -- aço esverdeado
	Color(0.55, 0.69, 0.48),  # 1  foice do pântano  -- verde
	Color(0.72, 0.28, 0.30),  # 2  garra da viúva    -- sangue
	Color(0.49, 0.64, 0.30),  # 3  espinho da árvore -- verde-seiva
	Color(0.45, 0.48, 0.58),  # 4  martelo carcereiro-- aço frio
	Color(0.95, 0.52, 0.20),  # 5  forjaluz          -- brasa
	Color(0.90, 0.72, 0.36),  # 6  badalo de bronze  -- ouro
	Color(0.24, 0.70, 0.85),  # 7  lança tempestade  -- relâmpago ciano
	Color(0.26, 0.56, 0.80),  # 8  crescente lunar   -- azul-luar
	Color(0.80, 0.82, 0.88),  # 9  presa de Vyrak    -- osso claro
	Color(0.85, 0.40, 0.66),  # 10 cetro de osso     -- coral magenta
	Color(0.78, 0.80, 0.86),  # 11 cutelo real       -- aço-névoa
	Color(0.62, 0.42, 0.85),  # 12 gládio púrpura    -- roxo
	Color(0.86, 0.88, 0.96),  # 13 fio do eclipse    -- branco-asa
	Color(0.70, 0.45, 0.95),  # 14 estilhaço Zeriko  -- prisma roxo
]

## Cor da arma i -- da tira real (`COR_ARMA`), com um toque de brilho.
## Fora de alcance cai numa rampa aço->magenta.
static func cor_arma(i: int) -> Color:
	if i >= 0 and i < COR_ARMA.size():
		return (COR_ARMA[i] as Color).lerp(Color(1, 1, 1), 0.1)
	return Color(0.62, 0.62, 0.68).lerp(Color(0.95, 0.25, 0.9), clampf(float(i) / 14.0, 0.0, 1.0))


## Tinta subtil da armadura i aplicada ao corpo da Koliani.
static func cor_armadura(i: int) -> Color:
	return Color(0.78, 0.73, 0.64).lerp(Color(0.5, 0.45, 0.95), clampf(float(i) / 14.0, 0.0, 1.0))


## Recompensa por acabar o nível `indice` (0-based). Devolve
## `{ tipo: "arma"|"armadura", id: String }` ou `{}` se fora de alcance.
static func recompensa_do_nivel(indice: int) -> Dictionary:
	if indice < 0:
		return {}
	if indice % 2 == 0:
		var w := indice / 2
		if w < ARMAS.size():
			return { "tipo": "arma", "id": ARMAS[w]["id"] }
	else:
		var a := (indice - 1) / 2
		if a < ARMADURAS.size():
			return { "tipo": "armadura", "id": ARMADURAS[a]["id"] }
	return {}
