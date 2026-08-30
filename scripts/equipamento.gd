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
const ARMAS: Array[Dictionary] = [
	{ "id": "lamina_gasta",         "nome": "gear.w.lamina_gasta",         "dano": 24, "nivel": 1 },
	{ "id": "foice_do_pantano",     "nome": "gear.w.foice_do_pantano",     "dano": 27, "nivel": 3 },
	{ "id": "garra_da_viuva",       "nome": "gear.w.garra_da_viuva",       "dano": 30, "nivel": 5 },
	{ "id": "espinho_da_arvore",    "nome": "gear.w.espinho_da_arvore",    "dano": 33, "nivel": 7 },
	{ "id": "martelo_do_carcereiro","nome": "gear.w.martelo_do_carcereiro","dano": 37, "nivel": 9 },
	{ "id": "forjaluz",             "nome": "gear.w.forjaluz",             "dano": 40, "nivel": 11 },
	{ "id": "badalo_de_bronze",     "nome": "gear.w.badalo_de_bronze",     "dano": 43, "nivel": 13 },
	{ "id": "lanca_da_tempestade",  "nome": "gear.w.lanca_da_tempestade",  "dano": 46, "nivel": 15 },
	{ "id": "crescente_lunar",      "nome": "gear.w.crescente_lunar",      "dano": 49, "nivel": 17 },
	{ "id": "presa_de_vyrak",       "nome": "gear.w.presa_de_vyrak",       "dano": 52, "nivel": 19 },
	{ "id": "cetro_de_osso",        "nome": "gear.w.cetro_de_osso",        "dano": 54, "nivel": 21 },
	{ "id": "cutelo_real",          "nome": "gear.w.cutelo_real",          "dano": 56, "nivel": 23 },
	{ "id": "gladio_purpura",       "nome": "gear.w.gladio_purpura",       "dano": 58, "nivel": 25 },
	{ "id": "fio_do_eclipse",       "nome": "gear.w.fio_do_eclipse",       "dano": 60, "nivel": 27 },
	{ "id": "estilhaco_de_zeriko",  "nome": "gear.w.estilhaco_de_zeriko",  "dano": 64, "nivel": 29 },
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
