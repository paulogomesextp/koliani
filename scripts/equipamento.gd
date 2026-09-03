class_name Equipamento
extends RefCounted
## DADOS PUROS das 20 armas + 10 armaduras da campanha. Sem lógica de jogo,
## sem autoloads -- é uma tabela, testável com `--script`.
##
## CADÊNCIA (pedido do Paulo, 3 set 2026, quando a campanha passou a 100
## níveis): **uma arma a cada 5 níveis** (5, 10, 15, ... 100) e **uma
## armadura a cada 10** (10, 20, ... 100). Nos múltiplos de 10 caem as duas.
## Antes era um item por nível -- com 30 níveis dava 15+15; com 100 seria
## uma chuva de equipamento e nenhum drop valia nada.
## Ver `recompensas_do_nivel()` e `EstadoJogo.conceder_recompensa()`.
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
	{ "id": "lamina_gasta",         "nome": "gear.w.lamina_gasta",          "dano": 48, "nivel": 5 },
	{ "id": "foice_do_pantano",     "nome": "gear.w.foice_do_pantano",      "dano": 54, "nivel": 10 },
	{ "id": "garra_da_viuva",       "nome": "gear.w.garra_da_viuva",        "dano": 60, "nivel": 15 },
	{ "id": "espinho_da_arvore",    "nome": "gear.w.espinho_da_arvore",     "dano": 66, "nivel": 20 },
	{ "id": "martelo_do_carcereiro", "nome": "gear.w.martelo_do_carcereiro", "dano": 74, "nivel": 25 },
	{ "id": "forjaluz",             "nome": "gear.w.forjaluz",              "dano": 80, "nivel": 30 },
	{ "id": "badalo_de_bronze",     "nome": "gear.w.badalo_de_bronze",      "dano": 86, "nivel": 35 },
	{ "id": "lanca_da_tempestade",  "nome": "gear.w.lanca_da_tempestade",   "dano": 92, "nivel": 40 },
	{ "id": "crescente_lunar",      "nome": "gear.w.crescente_lunar",       "dano": 98, "nivel": 45 },
	{ "id": "presa_de_vyrak",       "nome": "gear.w.presa_de_vyrak",        "dano": 104, "nivel": 50 },
	{ "id": "cetro_de_osso",        "nome": "gear.w.cetro_de_osso",         "dano": 108, "nivel": 55 },
	{ "id": "cutelo_real",          "nome": "gear.w.cutelo_real",           "dano": 112, "nivel": 60 },
	{ "id": "gladio_purpura",       "nome": "gear.w.gladio_purpura",        "dano": 116, "nivel": 65 },
	{ "id": "fio_do_eclipse",       "nome": "gear.w.fio_do_eclipse",        "dano": 120, "nivel": 70 },
	{ "id": "estilhaco_de_zeriko",  "nome": "gear.w.estilhaco_de_zeriko",   "dano": 128, "nivel": 75 },
	# Depois do Zeriko (nível 30) a campanha continua mais 70 níveis:
	# estas cinco são as das regiões XVI-XX. A `ultima_lamina` é a do
	# duelo final -- branca, sem magia nenhuma.
	{ "id": "mare_escarlate",       "nome": "gear.w.mare_escarlate",        "dano": 140, "nivel": 80 },
	{ "id": "brasa_do_inferno",     "nome": "gear.w.brasa_do_inferno",      "dano": 152, "nivel": 85 },
	{ "id": "fio_do_vazio",         "nome": "gear.w.fio_do_vazio",          "dano": 166, "nivel": 90 },
	{ "id": "juramento_de_guerra",  "nome": "gear.w.juramento_de_guerra",   "dano": 182, "nivel": 95 },
	{ "id": "ultima_lamina",        "nome": "gear.w.ultima_lamina",         "dano": 200, "nivel": 100 },
]

## id -> { nome, vida_bonus: int, reducao: float 0..1, nivel: int,
##         celula: int (frame na tira `gear/armaduras.png`, que tem 15) }
##
## São 10 e a tira tem 15: as cinco que ficaram de fora (casaco de seiva,
## manto dos sinos, véu lunar, avental do açougueiro, vestido do eclipse)
## saíram quando a cadência passou a uma armadura por cada 10 níveis --
## 15 armaduras precisariam de 150. A arte delas continua na tira, por
## isso `celula` não é o índice na lista.
const ARMADURAS: Array[Dictionary] = [
	{ "id": "trapos_de_viajante", "nome": "gear.a.trapos_de_viajante",  "vida_bonus":   0, "reducao": 0.00, "nivel":  10, "celula":  0 },
	{ "id": "couro_do_pantano",   "nome": "gear.a.couro_do_pantano",    "vida_bonus":  10, "reducao": 0.03, "nivel":  20, "celula":  1 },
	{ "id": "casca_de_teia",      "nome": "gear.a.casca_de_teia",       "vida_bonus":  20, "reducao": 0.06, "nivel":  30, "celula":  2 },
	{ "id": "malha_do_carcereiro", "nome": "gear.a.malha_do_carcereiro", "vida_bonus":  35, "reducao": 0.09, "nivel":  40, "celula":  4 },
	{ "id": "placas_de_brasa",    "nome": "gear.a.placas_de_brasa",     "vida_bonus":  48, "reducao": 0.12, "nivel":  50, "celula":  5 },
	{ "id": "arnes_da_tempestade", "nome": "gear.a.arnes_da_tempestade", "vida_bonus":  62, "reducao": 0.15, "nivel":  60, "celula":  7 },
	{ "id": "escamas_de_vyrak",   "nome": "gear.a.escamas_de_vyrak",    "vida_bonus":  78, "reducao": 0.19, "nivel":  70, "celula":  9 },
	{ "id": "couraca_de_osso",    "nome": "gear.a.couraca_de_osso",     "vida_bonus":  92, "reducao": 0.22, "nivel":  80, "celula": 10 },
	{ "id": "batina_purpura",     "nome": "gear.a.batina_purpura",      "vida_bonus": 106, "reducao": 0.26, "nivel":  90, "celula": 12 },
	{ "id": "egide_de_aurora",    "nome": "gear.a.egide_de_aurora",     "vida_bonus": 120, "reducao": 0.30, "nivel": 100, "celula": 14 },
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
	Color(0.85, 0.24, 0.32),  # 15 maré escarlate    -- sangue do mar
	Color(1.00, 0.48, 0.14),  # 16 brasa do inferno  -- fogo vivo
	Color(0.72, 0.70, 0.80),  # 17 fio do vazio      -- cinzento sem cor
	Color(0.86, 0.62, 0.34),  # 18 juramento guerra  -- bronze gasto
	Color(0.94, 0.95, 1.00),  # 19 última lâmina     -- branco, sem magia
]

## Cor da arma i -- da tira real (`COR_ARMA`), com um toque de brilho.
## Fora de alcance cai numa rampa aço->magenta.
static func cor_arma(i: int) -> Color:
	if i >= 0 and i < COR_ARMA.size():
		return (COR_ARMA[i] as Color).lerp(Color(1, 1, 1), 0.1)
	return Color(0.62, 0.62, 0.68).lerp(Color(0.95, 0.25, 0.9), clampf(float(i) / 19.0, 0.0, 1.0))


## Tinta subtil da armadura i aplicada ao corpo da Koliani.
static func cor_armadura(i: int) -> Color:
	return Color(0.78, 0.73, 0.64).lerp(Color(0.5, 0.45, 0.95), clampf(float(i) / 9.0, 0.0, 1.0))


## Recompensas por acabar o nível `indice` (0-based). Devolve uma LISTA de
## `{ tipo: "arma"|"armadura", id: String }` -- pode vir vazia (a maioria dos
## níveis), com um item, ou com DOIS: nos múltiplos de 10 cai uma arma e uma
## armadura ao mesmo tempo.
static func recompensas_do_nivel(indice: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if indice < 0:
		return out
	var n := indice + 1              # 1-based: o nível que se acabou
	if n % NIVEIS_POR_ARMA == 0:
		var w: int = n / NIVEIS_POR_ARMA - 1
		if w < ARMAS.size():
			out.append({ "tipo": "arma", "id": ARMAS[w]["id"] })
	if n % NIVEIS_POR_ARMADURA == 0:
		var a: int = n / NIVEIS_POR_ARMADURA - 1
		if a < ARMADURAS.size():
			out.append({ "tipo": "armadura", "id": ARMADURAS[a]["id"] })
	return out


## De quantos em quantos níveis cai cada tipo (a cadência do Paulo).
const NIVEIS_POR_ARMA := 5
const NIVEIS_POR_ARMADURA := 10


## Célula da tira `gear/armaduras.png` (15 frames) da armadura `id`, ou -1.
## NÃO é o índice na lista: a tira tem a arte das 15 originais.
static func celula_armadura(id: String) -> int:
	var a := armadura(id)
	return int(a.get("celula", -1)) if not a.is_empty() else -1
