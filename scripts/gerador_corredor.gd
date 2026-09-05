class_name GeradorCorredor
extends Node2D
## JORNADA -- constrói a maior parte de cada nível. Em vez de um chão por
## onde se anda em frente, há um LÍQUIDO MORTAL em toda a extensão (lava /
## ácido / água podre / trevas, conforme a região) e uma ESPINHA de
## plataformas por cima -- pequenas, muito espaçadas, com perigos nos vãos.
## Cair = morte e volta ao checkpoint. Obriga a saltar, subir, descer e a
## passar pelos obstáculos. O chefe fica SEMPRE no fim (geometria à mão).
##
## Anti-softlock (sem chão de rede, é preciso cuidado):
##  - a espinha é SEMPRE contínua: cada plataforma está ao alcance de salto
##    da anterior (Δx <= ~195, subida <= ~115; descer é livre);
##  - plataformas móveis da espinha voltam sempre a um ponto fixo alcançável;
##  - nada BLOQUEIA -- os perigos só magoam/matam e ciclam;
##  - checkpoint a cada 2 plataformas da espinha (morrer custa pouco);
##  - a última câmara é uma passadeira sólida lisa que encosta ao nível.
## `corredor = false` na cena raiz desliga (o último nível nunca o tem).

# Curva de dificuldade (1 set 2026, 2.ª passagem): o Nível 1 ainda ia dos
# 6200px -- longo demais para um nível "básico, ~1 minuto" como o Paulo
# pediu. Desce para 1800px (uns 10-15s só de travessia da jornada, mais a
# sala clássica a seguir) e cresce mais depressa por nível para o topo da
# campanha continuar com o mesmo fôlego de antes.
@export var comprimento_base := 2600.0
@export var por_nivel := 1250.0
@export var comprimento_max := 40000.0
@export var especie_inimigo := ""
@export var entrada_fresca := true
@export var otimizar_visibilidade := true

const PLAT := preload("res://scenes/actors/Plataforma.tscn")
const ESPINHOS := preload("res://scenes/actors/Espinhos.tscn")
const DEMONIO := preload("res://scenes/actors/DemonioBase.tscn")
const SERRA := preload("res://scenes/actors/Serra.tscn")
const FOGO := preload("res://scenes/actors/Fogo.tscn")
const GUILHOTINA := preload("res://scenes/actors/Guilhotina.tscn")
const TORRETA := preload("res://scenes/actors/Torreta.tscn")
const PLAT_FLUT := preload("res://scenes/actors/PlataformaFlutuante.tscn")
const PLAT_RITMO := preload("res://scenes/actors/PlataformaRitmada.tscn")
const PLAT_CORRENTE := preload("res://scenes/actors/PlataformaCorrente.tscn")
const TUMULO := preload("res://scenes/actors/TumuloElevador.tscn")
const ZONA_GRAV := preload("res://scenes/actors/ZonaGravidade.tscn")
const CORRENTE_AR := preload("res://scenes/actors/CorrenteAr.tscn")
const PENDULO := preload("res://scenes/actors/PenduloLamina.tscn")
const PEDRA := preload("res://scenes/actors/PedraQueda.tscn")
const PORTAL := preload("res://scenes/actors/Portal.tscn")
const PLAT_QUEBRA := preload("res://scenes/actors/PlataformaQuebra.tscn")
const TRAMPOLIM := preload("res://scenes/actors/Trampolim.tscn")
const IMPULSOR := preload("res://scenes/actors/Impulsor.tscn")
const AGUA := preload("res://scenes/actors/AguaVenenosa.tscn")
const RAIZ := preload("res://scenes/actors/RaizPerigo.tscn")
const TEIA := preload("res://scenes/actors/TeiaPrende.tscn")
const GOTA := preload("res://scenes/actors/GotaAcida.tscn")
const RAIO := preload("res://scenes/actors/RaioTempestade.tscn")
const CHECKPOINT := preload("res://scripts/checkpoint.gd")
# --- peças de PUZZLE (2 set 2026): o Paulo pediu "muito mais mecânicas
# diferentes, puzzles". Estas são as que já existiam nos níveis à mão e que
# a jornada nunca tinha usado.
const ALAVANCA := preload("res://scenes/actors/Alavanca.tscn")
const PORTA_TRANCADA := preload("res://scenes/actors/PortaTrancada.tscn")
const PAREDE_FRAGIL := preload("res://scenes/actors/ParedeFragil.tscn")
const PAREDE_MOVEL := preload("res://scenes/actors/ParedeMovel.tscn")
const SINO := preload("res://scenes/actors/SinoTorre.tscn")
const VELA := preload("res://scenes/actors/Vela.tscn")
const PLAT_LUZ := preload("res://scenes/actors/PlataformaLuz.tscn")
const ESPELHO := preload("res://scenes/actors/Espelho.tscn")
const ESSENCIA := preload("res://scenes/actors/Essencia.tscn")
## Três actores que já estavam no repo e que nenhuma câmara usava -- é de
## graça: arte, física e som já feitos, só faltava a sala onde entram.
const PLAT_ESPECTRAL := preload("res://scenes/actors/PlataformaEspectral.tscn")
const VITRAL := preload("res://scenes/actors/Vitral.tscn")
const PARA_RAIOS := preload("res://scenes/actors/ParaRaios.tscn")
## Correnteza lateral -- actor novo (5 set 2026). Só script: constrói a
## própria área, como o `CHECKPOINT`.
const CORRENTE_LAT := preload("res://scripts/corrente_lateral.gd")

## Líquido mortal por região: [cor, brasas]. floresta=água podre, prisão=ácido,
## torres=??? (usa trevas), catacumbas=trevas, cidade=ácido citrino,
## castelo=lava.
## Cor do "chão mortal" por região. Ocupa um terço do ecrã na jornada, por
## isso NÃO pode ser tinta chapada e berrante: os tons ficam escuros e
## dessaturados (a linha de água acesa do `AguaVenenosa` é que dá a leitura
## do perigo) e puxados para o luar/magenta do key_art.
const LIQUIDO := {
	0: [Color(0.13, 0.28, 0.15, 0.94), false],   # água podre
	1: [Color(0.26, 0.42, 0.14, 0.93), false],   # ácido
	2: [Color(0.06, 0.05, 0.12, 0.96), false],   # trevas / vazio
	3: [Color(0.05, 0.03, 0.09, 0.97), false],   # trevas do abismo
	4: [Color(0.34, 0.40, 0.12, 0.93), false],   # ácido citrino
	5: [Color(0.62, 0.22, 0.08, 0.94), true],    # lava
	# --- niveis 31-100 (docs/plano_niveis_31_100.md) ---------------------
	6: [Color(0.74, 0.28, 0.05, 0.95), true],    # VII magma vivo das Terras Queimadas
	7: [Color(0.03, 0.10, 0.16, 0.96), false],   # VIII agua negra do Mar dos Mortos
	8: [Color(0.30, 0.52, 0.66, 0.92), false],   # IX agua gelada por baixo do gelo
	9: [Color(0.42, 0.32, 0.16, 0.94), false],   # X areia movedica do deserto
	10: [Color(0.16, 0.34, 0.14, 0.94), false],  # XI seiva das plantas dos Jardins
	11: [Color(0.10, 0.22, 0.30, 0.95), false],  # XII oleo de maquina da Cidade
	12: [Color(0.08, 0.09, 0.20, 0.90), false],  # XIII o vazio por baixo do Ceu Partido
	13: [Color(0.30, 0.16, 0.34, 0.92), false],  # XIV a nevoa dos Sonhos
	14: [Color(0.13, 0.18, 0.15, 0.94), false],  # XV a bruma das campas
	15: [Color(0.42, 0.05, 0.09, 0.96), false],  # XVI o Mar Vermelho
	16: [Color(0.55, 0.10, 0.02, 0.96), true],   # XVII a lava do Inferno
	17: [Color(0.05, 0.04, 0.09, 0.88), false],  # XVIII o proprio Vazio
	18: [Color(0.24, 0.14, 0.08, 0.94), false],  # XIX a lama da Guerra
	19: [Color(0.34, 0.10, 0.34, 0.94), false],  # XX o que resta da magia
}

## Tipos de "flavour" de câmara (o que se semeia à volta da espinha).
const POOL_REGIAO := {
	0: ["saltos", "serras", "pendulos", "ritmo", "trampolim", "gruta", "portal",
		"alavanca", "segredo"],
	1: ["saltos", "correntes", "elevador", "quebra", "guilhotinas", "serras", "portal",
		"crossfire", "espinhos", "alavanca", "prensa", "velas", "segredo"],
	2: ["vento", "saltos", "gravidade", "pendulos", "trampolim", "ritmo", "portal",
		"ferry", "sinos", "alavanca", "segredo"],
	3: ["gruta", "pedras", "elevador", "quebra", "guilhotinas", "pendulos", "portal",
		"ferry", "espinhos", "velas", "prensa", "alavanca", "segredo", "sinos"],
	4: ["saltos", "impulso", "serras", "fogo", "trampolim", "guilhotinas", "portal",
		"crossfire", "prensa", "alavanca", "espelhos", "segredo"],
	5: ["pendulos", "fogo", "guilhotinas", "ritmo", "quebra", "gravidade", "portal",
		"crossfire", "ferry", "espelhos", "sinos", "prensa", "alavanca", "segredo",
		"velas"],
	# VII Terras Queimadas: tudo o que arde, cede ou lanca. A regiao onde
	# o chao deixa de ser de confianca -- `quebra` e `fogo` sao o tema.
	6: ["fogo", "quebra", "impulso", "trampolim", "pedras", "crossfire", "portal",
		"serras", "espinhos", "prensa", "ferry", "alavanca", "segredo"],
	# VIII Mar dos Mortos: nada assenta. O tema é FLUTUAR -- plataformas
	# que se movem, gravidade fraca, correntes de ar (aqui, de água). Sem
	# `fogo` e sem `quebra`: debaixo de água não arde nem se estilhaça.
	7: ["gravidade", "ferry", "ritmo", "impulso", "trampolim", "elevador",
		"correntes", "crossfire", "portal", "pendulos", "vento", "alavanca",
		"segredo"],
	# IX Reino do Gelo: o gelo PARTE-SE e o vento EMPURRA. `espelhos` é a
	# assinatura -- os cristais das cavernas -- e `pedras` são estalactites
	# de gelo a cair. Sem `fogo` (não há nada a arder numa montanha de neve).
	8: ["vento", "quebra", "espelhos", "pedras", "saltos", "trampolim",
		"elevador", "espinhos", "crossfire", "portal", "alavanca", "segredo"],
	# X Deserto dos Esquecidos: templos cheios de ARMADILHAS. `crossfire`
	# é a assinatura (as estátuas que disparam do plano) e `pedras` são as
	# dunas que desabam. Sem `gravidade` e sem `vento` -- aqui o ar está
	# parado, o que mata é o que está construído.
	9: ["crossfire", "espinhos", "serras", "prensa", "pedras", "guilhotinas",
		"saltos", "gruta", "ferry", "portal", "alavanca", "segredo"],
	# XI Jardins do Rei: tudo BALANÇA -- trepadeiras, ramos, pontes de
	# folhagem. `pendulos` de assinatura. Nada de maquinaria: este jardim
	# foi plantado, não construído.
	10: ["pendulos", "trampolim", "saltos", "ritmo", "velas", "espinhos",
		"ferry", "gruta", "portal", "alavanca", "segredo"],
	# XII Cidade das Maquinas: o oposto. Nada balança -- tudo ANDA, com
	# `correntes` de assinatura (as correias). É a única região com todas
	# as câmaras de máquina ao mesmo tempo.
	11: ["correntes", "elevador", "impulso", "ritmo", "prensa", "serras",
		"guilhotinas", "crossfire", "quebra", "portal", "alavanca", "segredo"],
	# XIII Ceu Partido: não há chão -- só o que passa. `ferry` de
	# assinatura (as ilhas que se movem), mais `vento` e `gravidade`.
	12: ["ferry", "vento", "gravidade", "saltos", "trampolim", "elevador",
		"pendulos", "ritmo", "portal", "alavanca", "segredo"],
	# XIV Reino dos Sonhos: a regra é não haver regra. `portal` de
	# assinatura -- entra-se aqui e sai-se noutro sítio.
	13: ["portal", "espelhos", "gravidade", "quebra", "velas", "saltos",
		"pendulos", "ritmo", "gruta", "alavanca", "segredo"],
	# XV Cidade dos Mortos: `sinos` de assinatura -- a badalada torna
	# sólida a ponte fantasma, que é a mecânica-imagem da região inteira.
	14: ["sinos", "velas", "gruta", "pendulos",
		"guilhotinas", "espinhos", "ferry", "elevador", "portal",
		"alavanca", "segredo"],
	# XVI Mar Vermelho: a maré. `ritmo` de assinatura -- tudo aqui sobe e
	# desce a compasso.
	15: ["ritmo", "ferry", "quebra", "gravidade", "pendulos", "espinhos",
		"crossfire", "serras", "portal", "alavanca", "segredo"],
	# XVII Inferno: paredes que esmagam. `prensa` de assinatura -- e é a
	# única região onde o `fogo` volta com tudo desde o Castelo (nível 30).
	16: ["prensa", "fogo", "guilhotinas", "serras", "espinhos", "crossfire",
		"pedras", "quebra", "portal", "alavanca", "segredo"],
	# XVIII O Vazio: nada é permanente. `elevador` de assinatura -- o chão
	# que aparece e desaparece. Pool curta de propósito: a região tem de
	# se sentir VAZIA, e uma pool grande enche a jornada de coisas.
	17: ["elevador", "gravidade", "portal", "espelhos", "saltos", "quebra",
		"alavanca", "segredo"],
	# XIX Guerra dos Reinos: cerco. `pedras` de assinatura (o que as
	# catapultas mandam) mais tudo o que fere -- é a região mais densa.
	18: ["pedras", "crossfire", "espinhos", "serras", "guilhotinas", "prensa",
		"fogo", "correntes", "ferry", "portal", "alavanca", "segredo"],
	# XX O Ultimo Caminho: `velas` de assinatura -- acender uma luz para o
	# caminho aparecer é a imagem da região inteira (são memórias).
	19: ["velas", "sinos", "espelhos", "saltos", "trampolim", "gruta",
		"ritmo", "portal", "alavanca", "segredo"],
}

## MECÂNICA DE ESTREIA POR NÍVEL -- pedido do Paulo (5 set 2026):
##
##   "o meu objetivo é tornar o jogo mais variado e menos repetitivo, 100
##    níveis a fazer a mesma coisa e o mesmo padrão cansa o player"
##
## O que fazia os 100 níveis saberem ao mesmo NÃO era só faltarem mecânicas:
## era o SORTEIO. Cada nível tirava câmaras à sorte da pool da sua região --
## e os 5 níveis de uma região partilham a mesma pool --, com o
## `TIER_FLAVOUR` a abrir tipos por patamar de dificuldade. Resultado: dois
## níveis seguidos podiam sair quase iguais, e do 30 em diante (dif = 1)
## TODOS viam exatamente o mesmo saco.
##
## A regra nova, em três linhas:
##  1. cada nível ESTREIA uma mecânica -- ela entra GARANTIDAMENTE na
##     jornada desse nível (ver `_estreia_por_fazer`);
##  2. nenhuma mecânica aparece ANTES do nível onde estreia -- é isto que
##     substitui o `TIER_FLAVOUR`, e é o que faz o nível 3 não poder sair
##     igual ao 12;
##  3. as estreias RECENTES pesam mais na escolha (`_pool_permitida`), para
##     o nível 60 não voltar a saber ao 20 só porque a essa altura já se
##     libertou tudo.
##
## `grau` é a dureza da estreia, decidida com o Paulo: **mansa até ao nível
## 30, dura a partir do 2.º acto**. Traduz-se em quantas vezes a mecânica
## aparece e se se respira a seguir:
##   0 mansa   -- uma vez, e um `descanso` logo a seguir (é o tutorial dela)
##   1 normal  -- duas vezes
##   2 dura    -- três vezes, encadeadas
##
## CORTES decididos pelo Paulo (5 set 2026), dos 14 "grandes" da proposta:
##   - **Nadar** (N37) -- fora. A bolsa de gravidade baixa fica no lugar
##     dele: flutuar e cair devagar é o que a água faz ao corpo, e não
##     precisa de física nova na Koliani.
##   - **Gravidade a rodar 90°** (N90) -- fora. Era o mais caro da lista
##     (câmara, controlos e geometria toda de lado) e o N67, inverter a
##     gravidade à vontade, dá quase o mesmo espanto por uma mudança de
##     sinal. Esse fica.
##   - **Perseguidor invisível** (N89) -- fora, e não foi por preço: só é
##     justo se o jogador ouvir, e o jogo joga-se no telemóvel, muitas vezes
##     sem som. Uma coisa que mata sem aviso lê-se como bug.
##
## ⚠ As linhas marcadas `# ~` são PROVISÓRIAS: repetem uma câmara que já
## estreou porque o actor próprio dessa mecânica ainda não existe. São a
## lista de trabalho -- a proposta completa está em
## `docs/mecanicas_por_nivel.md`, com os 14 "grandes" que faltam construir.
## Trocar uma linha `# ~` por uma mecânica nova é o passo seguinte e não
## mexe em mais nada.
const MECANICA_DO_NIVEL := [
	# --- niveis 1-5  (Regiao 1) ---
	{"cam": "saltos", "grau": 0},
	{"cam": "gruta", "grau": 0},
	{"cam": "trampolim", "grau": 0},
	{"cam": "espinhos", "grau": 0},
	{"cam": "ritmo", "grau": 1},
	# --- niveis 6-10  (Regiao 2) ---
	{"cam": "alavanca", "grau": 0},
	{"cam": "fogo", "grau": 0},
	{"cam": "guilhotinas", "grau": 0},
	{"cam": "arena", "grau": 0},
	{"cam": "prensa", "grau": 1},
	# --- niveis 11-15  (Regiao 3) ---
	{"cam": "sinos", "grau": 0},
	{"cam": "vento", "grau": 0},
	{"cam": "serras", "grau": 0},
	{"cam": "gravidade", "grau": 0},
	{"cam": "torre", "grau": 1},
	# --- niveis 16-20  (Regiao 4) ---
	{"cam": "elevador", "grau": 0},
	{"cam": "quebra", "grau": 0},
	{"cam": "velas", "grau": 0},
	{"cam": "pedras", "grau": 0},
	{"cam": "poco", "grau": 1},
	# --- niveis 21-25  (Regiao 5) ---
	{"cam": "cripta", "grau": 0},
	{"cam": "pendulos", "grau": 0},
	{"cam": "ferry", "grau": 0},
	{"cam": "segredo", "grau": 0},
	{"cam": "pilares", "grau": 1},
	# --- niveis 26-30  (Regiao 6) ---
	{"cam": "crossfire", "grau": 0},
	{"cam": "espelhos", "grau": 0},
	{"cam": "forquilha", "grau": 0},
	{"cam": "impulso", "grau": 0},
	{"cam": "portal", "grau": 1},
	# --- niveis 31-35  (Regiao 7) ---
	{"cam": "correntes", "grau": 1},
	{"cam": "corredor", "grau": 1},
	{"cam": "fogo", "grau": 1},  # ~
	{"cam": "bombas", "grau": 1},
	{"cam": "lava_sobe", "grau": 1},
	# --- niveis 36-40  (Regiao 8) ---
	{"cam": "mare", "grau": 1},
	{"cam": "grav_baixa", "grau": 1},
	{"cam": "ritmo", "grau": 1},  # ~
	{"cam": "tapete", "grau": 1},
	{"cam": "gravidade", "grau": 1},  # ~
	# --- niveis 41-45  (Regiao 9) ---
	{"cam": "vento", "grau": 1},  # ~
	{"cam": "chuva", "grau": 1},
	{"cam": "vitral", "grau": 1},
	{"cam": "espectral", "grau": 1},
	{"cam": "espelhos", "grau": 1},  # ~
	# --- niveis 46-50  (Regiao 10) ---
	{"cam": "areia", "grau": 1},
	{"cam": "placa", "grau": 1},
	{"cam": "serras", "grau": 1},  # ~
	{"cam": "prensa", "grau": 1},  # ~
	{"cam": "queda", "grau": 1},
	# --- niveis 51-55  (Regiao 11) ---
	{"cam": "pendulos", "grau": 1},  # ~
	{"cam": "velas", "grau": 1},  # ~
	{"cam": "gruta", "grau": 1},  # ~
	{"cam": "portal", "grau": 1},  # ~
	{"cam": "pendulos", "grau": 1},  # ~
	# --- niveis 56-60  (Regiao 12) ---
	{"cam": "correntes", "grau": 1},  # ~
	{"cam": "elevador", "grau": 1},  # ~
	{"cam": "guilhotinas", "grau": 1},  # ~
	{"cam": "circuito", "grau": 1},
	{"cam": "correntes", "grau": 1},  # ~
	# --- niveis 61-65  (Regiao 13) ---
	{"cam": "orbita", "grau": 1},
	{"cam": "para_raios", "grau": 1},
	{"cam": "vento", "grau": 1},  # ~
	{"cam": "grav_baixa", "grau": 2},  # ~
	{"cam": "ferry", "grau": 1},  # ~
	# --- niveis 66-70  (Regiao 14) ---
	{"cam": "portal", "grau": 2},  # ~
	{"cam": "quebra", "grau": 2},  # ~
	{"cam": "velas", "grau": 2},  # ~
	{"cam": "ritmo", "grau": 2},  # ~
	{"cam": "portal", "grau": 2},  # ~
	# --- niveis 71-75  (Regiao 15) ---
	{"cam": "sinos", "grau": 2},  # ~
	{"cam": "gruta", "grau": 2},  # ~
	{"cam": "sinos", "grau": 2},  # ~
	{"cam": "guilhotinas", "grau": 2},  # ~
	{"cam": "sinos", "grau": 2},  # ~
	# --- niveis 76-80  (Regiao 16) ---
	{"cam": "espinhos", "grau": 2},  # ~
	{"cam": "serras", "grau": 2},  # ~
	{"cam": "alavanca", "grau": 2},  # ~
	{"cam": "segredo", "grau": 2},  # ~
	{"cam": "ritmo", "grau": 2},  # ~
	# --- niveis 81-85  (Regiao 17) ---
	{"cam": "prensa", "grau": 2},  # ~
	{"cam": "fogo", "grau": 2},  # ~
	{"cam": "pedras", "grau": 2},  # ~
	{"cam": "prensa", "grau": 2},  # ~
	{"cam": "anel", "grau": 2},
	# --- niveis 86-90  (Regiao 18) ---
	{"cam": "elevador", "grau": 2},  # ~
	{"cam": "gravidade", "grau": 2},  # ~
	{"cam": "elevador", "grau": 2},  # ~
	{"cam": "espectral", "grau": 2},  # ~
	{"cam": "elevador", "grau": 2},  # ~
	# --- niveis 91-95  (Regiao 19) ---
	{"cam": "pedras", "grau": 2},  # ~
	{"cam": "crossfire", "grau": 2},  # ~
	{"cam": "espinhos", "grau": 2},  # ~
	{"cam": "serras", "grau": 2},  # ~
	{"cam": "horda", "grau": 2},
	# --- niveis 96-100  (Regiao 20) ---
	{"cam": "trampolim", "grau": 2},  # ~
	{"cam": "velas", "grau": 2},  # ~
	{"cam": "saltos", "grau": 2},  # ~
	{"cam": "trampolim", "grau": 2},  # ~
	{"cam": "velas", "grau": 2},  # ~
]


## Nível (0-based) em que cada câmara ESTREIA. Derivado da tabela, uma vez.
## Uma câmara que não esteja na tabela (torre/poço/descanso e as `TIER_EXTRA`,
## que são escolhidas por outros ramos) devolve 0 -- sempre disponível.
static var _estreia_cache: Dictionary = {}

static func nivel_de_estreia(cam: String) -> int:
	if _estreia_cache.is_empty():
		for i in MECANICA_DO_NIVEL.size():
			var c: String = MECANICA_DO_NIVEL[i]["cam"]
			if not _estreia_cache.has(c):
				_estreia_cache[c] = i
	return int(_estreia_cache.get(cam, 0))


## Câmaras que não vivem na pool de nenhuma região (são escolhidas por outro
## ramo do `_construir`), mas que o forçador de VARIEDADE também pode puxar.
const TIER_EXTRA := {
	"cripta": 0.08, "arena": 0.12, "forquilha": 0.18, "corredor": 0.28,
}
## Fallback quando a região ainda não libertou nada (níveis muito baixos).
const FLAVOUR_SUAVE := ["saltos", "gruta", "trampolim"]

## TODAS as câmaras que `_flavour()` sabe construir. Tem de conter todos os
## valores de `POOL_REGIAO`, `ASSINATURA` e `FLAVOUR_SUAVE` -- um teste em
## `tests/run_tests.gd` garante isso (foi assim que "pedras" andou a gerar
## um vão morto silencioso durante semanas). As câmaras "torre"/"poco"/
## "pilares"/"descanso"/"forquilha"/"arena"/"corredor"/"cripta" também
## entram aqui embora sejam escolhidas por outro caminho no `_construir`.
const CAMARAS_FLAVOUR := [
	"saltos", "serras", "pendulos", "ritmo", "trampolim", "gruta", "quebra",
	"correntes", "elevador", "vento", "gravidade", "guilhotinas", "fogo",
	"impulso", "portal", "torre", "poco", "pilares", "descanso", "forquilha",
	"arena", "corredor", "cripta", "crossfire", "ferry", "pedras", "espinhos",
	"alavanca", "velas", "sinos", "prensa", "espelhos", "segredo",
	# --- estreias novas (5 set 2026) ------------------------------------
	"lava_sobe", "mare", "espectral", "vitral", "para_raios", "bombas",
	"queda", "tapete", "orbita", "areia", "grav_baixa", "placa",
	"circuito", "anel", "horda", "chuva",
]

## Câmara "assinatura" de cada região -- no acto do meio da jornada aparece
## com mais frequência para o bioma ter identidade própria (se a dificuldade
## já a libertou). Índice = região.
const ASSINATURA := {
	0: "trampolim",    # Floresta -- ricochete
	1: "guilhotinas",  # Prisão -- execuções
	2: "vento",        # Torres -- correntes de ar
	3: "gruta",        # Catacumbas -- túneis escuros
	4: "impulso",      # Cidade -- máquinas
	5: "fogo",         # Castelo -- lava
	6: "quebra",       # Terras Queimadas -- a madeira arde e cede
	7: "gravidade",    # Mar dos Mortos -- tudo flutua
	8: "espelhos",     # Reino do Gelo -- os cristais
	9: "crossfire",    # Deserto -- as estatuas que disparam
	10: "pendulos",    # Jardins do Rei -- as trepadeiras
	11: "correntes",   # Cidade das Maquinas -- as correias
	12: "ferry",       # Ceu Partido -- as ilhas que passam
	13: "portal",      # Reino dos Sonhos -- entra aqui, sai ali
	14: "sinos",       # Cidade dos Mortos -- a ponte fantasma
	15: "ritmo",       # Mar Vermelho -- a mare
	16: "prensa",      # Inferno -- as paredes que esmagam
	17: "elevador",    # O Vazio -- o chao que aparece e desaparece
	18: "pedras",      # Guerra dos Reinos -- o cerco
	19: "velas",       # O Ultimo Caminho -- acender a memoria
}

## Toque de assinatura do NÍVEL (a gimmick do `docs/niveis.md`) espalhado
## pela jornada -- só nos níveis onde há um perigo TELEGRAFADO que NÃO
## bloqueia nem obriga a nada (a rota da espinha é exatamente a mesma).
## Frequência baixa, escala com `intens`. Afinar/desligar aqui ao playtest;
## nível sem entrada = só forma (`PERFIL`) + assinatura de região.
const ASSIN_NIVEL := {
	0: "raizes",   # n1  Caminho das Raízes -- raízes que irrompem do chão
	2: "teias",    # n3  Ninho da Viúva Negra -- teias que prendem
	3: "acido",    # n4  A Árvore que Chora -- lágrimas ácidas a pingar
	12: "raio",    # n13 Torre da Tempestade -- raios em coluna, padrão previsível
}

## PERFIL DE FORMA por nível (redesenho pedido pelo Paulo, 2 set 2026): cada
## um dos 30 níveis tem uma "cara" própria em vez de todos correrem iguais
## com só a tendência vertical a alternar em ciclo `_idx % 3`. Cada entrada:
##   v -- verticalidade: -1 desce / 0 horizontal / +1 sobe
##   f -- foco de câmaras (enviesa a seleção, sem quebrar região/tier):
##        "salto"    plataformas e vãos (saltos/trampolim/forquilha)
##        "combate"  arenas e criptas cheias de inimigos
##        "maquina"  plataformas móveis (elevador/correntes/impulso/ritmo/quebra)
##        "vertical" torres e poços com mais frequência
##        "gauntlet" corredores de perigo (serras/guilhotinas/fogo/pêndulos/crossfire)
##        "misto"    sem enviesamento (a seleção normal)
##   a -- abertura da banda vertical: 0.8 apertado / 1.0 normal / 1.22 amplo
## O arco de cada região: intro suave -> aperta -> nível do chefe mais duro.
## Os comentários seguem a ordem REAL de `EstadoJogo.NIVEIS` (re-derivado
## 2 set 2026 -- a 1.ª versão do patch tinha os nomes deslizados). Cada
## triplo foi escolhido pela gimmick do nível em `docs/niveis.md`.
const PERFIL := [
	# --- Região I  Floresta Putrefacta (0-4) : introdução, suave ----------
	{"v": 0, "f": "salto", "a": 1.15},    # 0  Caminho das Raízes -- tutorial de salto
	{"v": 0, "f": "salto", "a": 1.1},     # 1  Pântano dos Sussurros -- ilhas sobre água mortal
	{"v": 1, "f": "vertical", "a": 1.15}, # 2  Ninho da Viúva Negra -- teia vertical
	{"v": 1, "f": "vertical", "a": 1.05}, # 3  A Árvore que Chora -- labirinto no tronco
	{"v": 0, "f": "maquina", "a": 0.9},   # 4  Coração da Floresta (chefe) -- cenário rítmico
	# --- Região II  Prisão dos Condenados (5-9) : apertado, execuções -----
	{"v": 0, "f": "maquina", "a": 0.95},  # 5  Portão dos Condenados -- correntes móveis
	{"v": -1, "f": "maquina", "a": 0.85}, # 6  Fornalha dos Pecadores -- plataformas sobre lava
	{"v": 0, "f": "gauntlet", "a": 0.8},  # 7  Corredor das Execuções -- guilhotinas e lâminas
	{"v": 0, "f": "combate", "a": 0.9},   # 8  Ala dos Mortos -- irmãos fantasma
	{"v": 1, "f": "vertical", "a": 0.95}, # 9  A Cela Zero (chefe) -- labirinto vertical
	# --- Região III  Torres Esquecidas (10-14) : verticalidade, banda ampla
	{"v": 1, "f": "maquina", "a": 1.15},  # 10 Torre dos Sinos -- plataformas que mudam
	{"v": 1, "f": "salto", "a": 1.22},    # 11 Torre dos Ventos -- correntes de ar, saltos longos
	{"v": 1, "f": "gauntlet", "a": 1.15}, # 12 Torre da Tempestade -- raios em padrão
	{"v": 1, "f": "maquina", "a": 1.22},  # 13 Observatório Lunar -- gravidade variável
	{"v": 1, "f": "combate", "a": 1.0},   # 14 O Pico Esquecido (chefe) -- Vyrak
	# --- Região IV  Catacumbas do Abismo (15-19) : túneis apertados, a descer
	{"v": -1, "f": "maquina", "a": 0.9},  # 15 Cemitério dos Reis -- túmulos elevadores
	{"v": 0, "f": "gauntlet", "a": 0.8},  # 16 Galeria dos Ossos -- corredores de osso
	{"v": -1, "f": "combate", "a": 0.85}, # 17 Cripta das Mil Velas -- luz e escuridão
	{"v": 0, "f": "maquina", "a": 0.95},  # 18 Templo da Serpente -- paredes móveis
	{"v": -1, "f": "vertical", "a": 1.22},# 19 O Abismo (chefe) -- grande queda no escuro
	# --- Região V  Cidade Corrompida (20-24) : máquinas, ritmo urbano ----
	{"v": 0, "f": "combate", "a": 1.0},   # 20 Vila dos Sem-Rosto -- inimigos disfarçados
	{"v": 1, "f": "maquina", "a": 1.0},   # 21 Mercado da Carne -- correntes, caixas, carrinhos
	{"v": 0, "f": "gauntlet", "a": 1.0},  # 22 Trem dos Mortos -- corrida sobre o comboio
	{"v": 1, "f": "combate", "a": 1.05},  # 23 Catedral da Corrupção -- Bispo Púrpura
	{"v": 0, "f": "maquina", "a": 0.95},  # 24 Praça do Eclipse (chefe) -- realidade/corrupção
	# --- Região VI  Castelo de Zeriko (25-29) : tudo, clímax -------------
	{"v": 0, "f": "gauntlet", "a": 0.85}, # 25 Portões de Zeriko -- corredor de cavaleiros
	{"v": 0, "f": "combate", "a": 0.95},  # 26 Salão dos Espelhos -- Kolianis sombrias
	{"v": 0, "f": "salto", "a": 1.0},     # 27 Banquete dos Imortais -- mesa gigante
	{"v": 1, "f": "vertical", "a": 1.15}, # 28 Torre do Coração Negro -- plataformas que pulsam
	{"v": 0, "f": "misto", "a": 1.0},     # 29 O Trono de Zeriko (sem jornada)
	# --- Regiao VII  Terras Queimadas (30-34) : o chao arde e cede -------
	{"v": 0, "f": "gauntlet", "a": 1.0},  # 30 Estrada das Cinzas -- floresta a arder
	{"v": -1, "f": "maquina", "a": 0.9},  # 31 Rio de Magma -- a lava sobe e desce
	{"v": 0, "f": "maquina", "a": 0.85},  # 32 A Forja dos Demonios -- correias e martelos
	{"v": 1, "f": "vertical", "a": 1.2},  # 33 Vulcao do Rei Morto -- subida pelo interior
	{"v": 1, "f": "salto", "a": 1.15},    # 34 O Ceu em Chamas -- pedacos de ceu a cair
	# --- Regiao VIII  Mar dos Mortos (35-39) : nada assenta -------------
	{"v": 0, "f": "gauntlet", "a": 1.1},  # 35 Porto dos Afogados -- pontoes a boiar
	{"v": -1, "f": "salto", "a": 1.25},   # 36 Cidade Submersa -- gravidade fraca
	{"v": 0, "f": "maquina", "a": 0.95},  # 37 Palacio das Sereias -- a agua sobe e desce
	{"v": -1, "f": "combate", "a": 0.85}, # 38 Ossario das Baleias -- caverna de ossos
	{"v": 1, "f": "vertical", "a": 1.0},  # 39 Abismo Oceanico -- descida ao escuro
	# --- Regiao IX  Reino do Gelo (40-44) : o chao parte-se -------------
	{"v": 0, "f": "gauntlet", "a": 1.05}, # 40 Floresta Congelada -- mata gelada
	{"v": 1, "f": "vertical", "a": 1.2},  # 41 Montanha dos Ventos -- subida a pique
	{"v": -1, "f": "salto", "a": 0.9},    # 42 Cavernas Cristalinas -- cristais
	{"v": 0, "f": "combate", "a": 1.0},   # 43 Castelo Congelado -- parado no tempo
	{"v": 1, "f": "maquina", "a": 1.1},   # 44 Coracao do Inverno -- a montanha por dentro
	# --- Regiao X  Deserto dos Esquecidos (45-49) : armadilhas ----------
	{"v": 0, "f": "gauntlet", "a": 1.2},  # 45 Mar de Areia -- dunas abertas
	{"v": 0, "f": "gauntlet", "a": 0.9},  # 46 Templo Sem Nome -- corredor de armadilhas
	{"v": -1, "f": "salto", "a": 1.1},    # 47 Vale dos Escorpioes -- sobre o vazio
	{"v": 0, "f": "maquina", "a": 0.95},  # 48 Cidade Enterrada -- ruinas tapadas
	{"v": 1, "f": "combate", "a": 0.85},  # 49 Piramide Negra -- camaras apertadas
	# --- Regiao XI  Jardins do Rei (50-54) : tudo balanca ---------------
	{"v": 0, "f": "gauntlet", "a": 1.05}, # 50 Jardim das Rosas Negras
	{"v": 0, "f": "maquina", "a": 0.8},   # 51 Labirinto Verde -- sebes apertadas
	{"v": 1, "f": "salto", "a": 1.15},    # 52 Jardim das Almas -- copas altas
	{"v": -1, "f": "combate", "a": 0.9},  # 53 Estufa Maldita -- por dentro do vidro
	{"v": 1, "f": "vertical", "a": 1.2},  # 54 Arvore do Rei -- subir a arvore
	# --- Regiao XII  Cidade das Maquinas (55-59) : tudo anda ------------
	{"v": 0, "f": "maquina", "a": 1.0},   # 55 Distrito das Engrenagens
	{"v": 0, "f": "gauntlet", "a": 1.3},  # 56 Linha 13 -- perseguicao, o mais longo
	{"v": 0, "f": "combate", "a": 0.9},   # 57 Fabrica dos Homunculos -- em serie
	{"v": 1, "f": "vertical", "a": 1.15}, # 58 Torre Electrica -- subida
	{"v": -1, "f": "maquina", "a": 0.95}, # 59 Coracao da Maquina -- por dentro
	# --- Regiao XIII  Ceu Partido (60-64) : nao ha' chao ----------------
	{"v": 1, "f": "salto", "a": 1.3},     # 60 Ilhas Flutuantes -- vaos largos
	{"v": 1, "f": "gauntlet", "a": 1.1},  # 61 Templo do Trovao
	{"v": 0, "f": "combate", "a": 1.0},   # 62 Cidade dos Anjos Mortos
	{"v": 1, "f": "salto", "a": 1.25},    # 63 Lua Quebrada -- fragmentos
	{"v": 1, "f": "salto", "a": 1.35},    # 64 O Fim do Ceu -- so' plataformas
	# --- Regiao XIV  Reino dos Sonhos (65-69) : sem regras --------------
	{"v": 0, "f": "maquina", "a": 0.9},   # 65 Vila dos Sonhos
	{"v": -1, "f": "salto", "a": 1.1},    # 66 Mundo Invertido
	{"v": 0, "f": "combate", "a": 0.75},  # 67 Quarto das Criancas -- apertado
	{"v": -1, "f": "gauntlet", "a": 0.95},# 68 Pesadelo
	{"v": 1, "f": "vertical", "a": 1.15}, # 69 A Mente -- subir por dentro
	# --- Regiao XV  Cidade dos Mortos (70-74) --------------------------
	{"v": 0, "f": "gauntlet", "a": 1.2},  # 70 Avenida dos Mortos -- avenida
	{"v": 0, "f": "maquina", "a": 1.25},  # 71 Cemiterio Infinito -- sem fim
	{"v": 1, "f": "vertical", "a": 1.0},  # 72 Catedral Fantasma -- naves altas
	{"v": 0, "f": "combate", "a": 0.9},   # 73 Palacio dos Reis Mortos
	{"v": -1, "f": "combate", "a": 0.8},  # 74 Trono da Morte -- fecha-se
	# --- Regiao XVI  Mar Vermelho (75-79) : a mare ---------------------
	{"v": 0, "f": "salto", "a": 1.15},    # 75 Margem do Sangue
	{"v": -1, "f": "gauntlet", "a": 1.05},# 76 Serpentes do Mar
	{"v": 0, "f": "maquina", "a": 1.1},   # 77 Navio da Condenacao -- conves
	{"v": 1, "f": "vertical", "a": 1.0},  # 78 Fortaleza Kraken
	{"v": -1, "f": "combate", "a": 0.85}, # 79 Coracao Vermelho -- por dentro
	# --- Regiao XVII  Inferno (80-84) ----------------------------------
	{"v": 0, "f": "gauntlet", "a": 1.0},  # 80 Portao Infernal
	{"v": 0, "f": "combate", "a": 1.1},   # 81 Cidade dos Demonios
	{"v": -1, "f": "maquina", "a": 1.05}, # 82 Rio das Almas -- correntes
	{"v": 1, "f": "combate", "a": 0.9},   # 83 Palacio de Sangue
	{"v": 0, "f": "gauntlet", "a": 0.85}, # 84 Trono Infernal
	# --- Regiao XVIII  O Vazio (85-89) : nada e' permanente ------------
	{"v": 1, "f": "salto", "a": 1.4},     # 85 Primeiro Vazio -- vaos enormes
	{"v": -1, "f": "salto", "a": 1.35},   # 86 Segundo Vazio
	{"v": 0, "f": "maquina", "a": 0.7},   # 87 Labirinto Impossivel -- apertado
	{"v": 1, "f": "salto", "a": 1.3},     # 88 A Coisa Atras do Mundo
	{"v": -1, "f": "combate", "a": 0.9},  # 89 Centro do Vazio
	# --- Regiao XIX  Guerra dos Reinos (90-94) : cerco -----------------
	{"v": 0, "f": "gauntlet", "a": 1.35}, # 90 Campo de Batalha -- o mais aberto
	{"v": 1, "f": "salto", "a": 1.2},     # 91 Ceu em Guerra
	{"v": 1, "f": "vertical", "a": 1.05}, # 92 Cerco ao Castelo -- muralha
	{"v": 1, "f": "vertical", "a": 1.1},  # 93 Torre da Corrupcao
	{"v": 0, "f": "combate", "a": 0.8},   # 94 Os Cem Guerreiros -- resistencia
	# --- Regiao XX  O Ultimo Caminho (95-99) : memorias ----------------
	{"v": 0, "f": "salto", "a": 1.1},     # 95 O Reino Antes da Corrupcao
	{"v": 1, "f": "vertical", "a": 1.0},  # 96 O Primeiro Castelo
	{"v": -1, "f": "combate", "a": 0.85}, # 97 O Coracao de Zeriko
	{"v": 1, "f": "salto", "a": 1.25},    # 98 O Fim de Tudo -- tudo a cair
	{"v": 0, "f": "combate", "a": 0.7},   # 99 O Ultimo Salto -- so' os dois
]

## Que câmaras conta cada foco. Cruzado depois com região+tier em
## `_camara_do_foco` -- o foco só enviesa, nunca fura as regras.
const FOCO_CAMARAS := {
	"salto": ["saltos", "trampolim", "forquilha", "velas"],
	"combate": ["arena", "cripta", "espelhos"],
	"maquina": ["elevador", "correntes", "impulso", "ritmo", "quebra", "gravidade",
		"prensa", "alavanca", "sinos"],
	"gauntlet": ["corredor", "serras", "guilhotinas", "fogo", "pendulos", "crossfire",
		"espinhos", "prensa"],
}

## Câmaras que puxam pelo jogador -- a seguir a uma destas vem sempre um
## `descanso` (o ritmo tensão/alívio da pegada Dead Cells).
const INTENSAS := [
	"guilhotinas", "serras", "pendulos", "fogo", "quebra", "crossfire", "ferry",
	"pedras", "espinhos", "corredor", "arena", "prensa", "espelhos", "sinos",
]


var _chao_y := 0.0     # topo do líquido mortal
var _idx := 0
var _dif := 0.0
var _regiao := 0
var _esp := "goblin"
var _rng := RandomNumberGenerator.new()
var _cont_i := 0

## Espaço mínimo (px) entre checkpoints da jornada. Antes havia um a cada
## ~2 plataformas (~380 px) -- eram MUITOS. Passa a haver um a cada ~4000 px
## (~90% menos); o do início e o de antes do chefe são sempre postos.
const DIST_CHECKPOINT := 3000.0
var _ultimo_check_x := -1.0e9

## Perigo-no-vão em RAJADAS de um só tipo (pêndulo OU serra OU fogo), não
## um sorteio novo a cada vão -- era isso que fazia a jornada sentir-se
## "tudo misturado sem lógica" a dificuldade alta (um vão de pêndulo, o
## seguinte de serra, o seguinte de fogo, sem padrão nenhum). Agora cada
## rajada dura vários vãos seguidos antes de trocar de mecânica.
var _perigo_tipo := -1
var _perigo_restante := 0

## Ritmo (pegada Dead Cells): alterna câmaras de TENSÃO (gauntlets, torres)
## com câmaras de ALÍVIO (`descanso` -- plataforma larga limpa + checkpoint).
var _camaras := 0
var _pos_intenso := false

## VARIEDADE DE MECÂNICAS (pedido do Paulo, 2 set 2026: "meta muito mais
## mecânicas diferentes por nível"). Guarda os tipos de câmara já usados
## NESTE nível; de `CICLO_VARIEDADE` em `CICLO_VARIEDADE` câmaras força-se
## uma que ainda não apareceu. Como a jornada cresce com o número do nível,
## um nível tardio tem câmaras que cheguem para esgotar a pool da região --
## ou seja, quanto mais alto o nível, mais mecânicas DIFERENTES se veem.
var _tipos_usados := {}
## Mecânica que ESTREIA neste nível (ver `MECANICA_DO_NIVEL`) e quantas
## câmaras dela faltam colocar. Enquanto for > 0 a jornada obriga-se a
## metê-la -- é isso que faz de cada nível um nível com assunto próprio.
var _estreia_cam := ""
var _estreia_por_fazer := 0
var _estreia_grau := 0
## A família de câmara VERTICAL deste nível: "torre", "poco" ou "pilares".
## Uma só por nível -- ver o ramo vertical em `_construir`.
var _vertical_do_nivel := "torre"
## A sala ESPECIAL deste nível: "arena", "corredor", "cripta" ou "forquilha".
## Uma só por nível. `_dif_especial` é o mínimo de dificuldade que ela pede
## (uma arena de combate no nível 1 não faz sentido).
var _especial_do_nivel := "forquilha"
var _dif_especial := 0.0
## Câmaras que faltam até se voltar a FORÇAR uma mecânica nova. É uma
## contagem decrescente e não `_camaras % N` -- com o módulo, os níveis de
## foco "vertical" (que enchem as câmaras pares com torres/poços e as
## ímpares com descansos) ficavam presos na paridade errada e nunca
## chegavam a estrear mecânica nenhuma.
var _falta_nova := 0
const CICLO_VARIEDADE := 2

## Subida máxima (px) de um degrau para o seguinte -- um salto + duplo salto
## da Koliani. Nenhuma plataforma da jornada fica mais alta que isto face à
## anterior (descer é livre). Descer/cair pode ser muito mais.
const SUBIDA_MAX := 104.0
## Topo da banda vertical jogável (definido em `_construir`). Quanto maior a
## dificuldade, mais alto -> jornadas com torres e poços a sério, não só uma
## fita de plataformas quase em linha.
var _teto_y := 0.0

## Tendência vertical da jornada deste nível (pedido do Paulo: nem todos os
## níveis a subir sempre) -- alterna de forma PREVISÍVEL pelos 30 níveis em
## vez de à sorte (senão podiam calhar vários seguidos da mesma):
## -1 desce (começa perto do topo, vagueia para baixo), 0 quase horizontal
## (banda estreita a meio), +1 sobe (começa perto do chão, vagueia para
## cima). Só afeta a Jornada -- a sala clássica no fim é desenhada à mão, e
## a "passadeira final" (ver fim de `_construir`) traz sempre a espinha de
## volta perto do chão antes de lá chegar, seja qual for a tendência.
var _tendencia := 0
## Foco de câmaras e abertura da banda vertical deste nível (ver `PERFIL`).
var _foco := "misto"
var _abertura := 1.0


## SEGUNDO ACTO (níveis 31-100, `docs/plano_niveis_31_100.md`).
##
## A curva de dificuldade e a de comprimento foram escritas para uma
## campanha de 30 níveis: `_idx / 29` e `base + 1250 * _idx` limitados a 1.0
## e a 40000 px. Assim que a campanha passou dos 30, TODOS os níveis novos
## nasciam já no máximo dos dois -- o nível 31, logo a seguir a derrotar o
## Zeriko e a entrar numa região nova, era tão longo e tão duro como o
## nível 30, e os 70 seguintes eram iguais entre si.
##
## A resposta é a de qualquer jogo por actos: a região nova RECOMEÇA mais
## abaixo e volta a subir, mais alto do que o acto anterior. Os níveis 1-30
## não mudam um único valor -- é tudo `_idx > 29`.
##
## Os dois pontos de partida (0.72 de dificuldade, 14000 px) são um palpite
## fundamentado: 0.72 é a dureza do nível ~21 e 14000 px o comprimento do
## nível ~10. Falta playtestar e afinar.
const ATO2_INICIO := 30
const ATO2_DIF_INICIAL := 0.72
const ATO2_COMP_INICIAL := 14000.0


func _dificuldade(idx: int) -> float:
	if idx < ATO2_INICIO:
		return clampf(float(idx) / 29.0, 0.0, 1.0)
	var n := float(EstadoJogo.NIVEIS.size() - 1 - ATO2_INICIO)
	var t: float = 0.0 if n <= 0.0 else clampf(float(idx - ATO2_INICIO) / n, 0.0, 1.0)
	return ATO2_DIF_INICIAL + (1.0 - ATO2_DIF_INICIAL) * t


func _comprimento(idx: int) -> float:
	if idx < ATO2_INICIO:
		return clampf(comprimento_base + por_nivel * float(idx),
			comprimento_base, comprimento_max)
	var n := float(EstadoJogo.NIVEIS.size() - 1 - ATO2_INICIO)
	var t: float = 0.0 if n <= 0.0 else clampf(float(idx - ATO2_INICIO) / n, 0.0, 1.0)
	return ATO2_COMP_INICIAL + (comprimento_max - ATO2_COMP_INICIAL) * t


func _ready() -> void:
	call_deferred("_construir")


func _construir() -> void:
	var kol := get_tree().get_first_node_in_group("koliani")
	if kol == null:
		return
	_idx = EstadoJogo.indice_nivel
	_dif = _dificuldade(_idx)
	_regiao = maxi(0, EstadoJogo.regiao_atual())
	_rng.seed = hash("jornada4|%d" % _idx)
	_esp = especie_inimigo if especie_inimigo != "" else _especie_do_nivel()
	# PERFIL DE FORMA deste nível (redesenho 2 set 2026): tendência vertical,
	# foco de câmaras e abertura da banda -- cada nível com a sua "cara".
	var perf: Dictionary = PERFIL[clampi(_idx, 0, PERFIL.size() - 1)]
	_tendencia = int(perf.get("v", 0))
	_foco = String(perf.get("f", "misto"))
	_abertura = float(perf.get("a", 1.0))
	# a mecânica que este nível estreia, e quantas vezes ela aparece
	var mec: Dictionary = MECANICA_DO_NIVEL[clampi(_idx, 0, MECANICA_DO_NIVEL.size() - 1)]
	_estreia_cam = String(mec.get("cam", ""))
	_estreia_grau = int(mec.get("grau", 0))
	_estreia_por_fazer = 1 + _estreia_grau
	# a "cara" vertical do nível: torres, poços ou pilares -- nunca os três
	_vertical_do_nivel = ["torre", "poco", "pilares"][_idx % 3]
	# a sala especial: ciclo de 4 com passo 2, para não entrar em fase com o
	# ciclo de 3 das verticais (assim o padrão só se repete de 24 em 24)
	_especial_do_nivel = ["forquilha", "arena", "cripta", "corredor"][(_idx / 2) % 4]
	_dif_especial = {"forquilha": 0.18, "arena": 0.12,
		"cripta": 0.0, "corredor": 0.28}.get(_especial_do_nivel, 0.0)

	var ancora: Vector2 = EstadoJogo.jornada_ancora_para(
		_idx, func() -> Vector2: return (kol as Node2D).global_position)
	_chao_y = ancora.y + 92.0
	_teto_y = _chao_y - lerpf(640.0, 1320.0, _dif) * _abertura

	var comp: float = _comprimento(_idx)
	var x0 := ancora.x - comp

	# --- líquido mortal em toda a extensão -----------------------------
	var liq: Array = LIQUIDO.get(_regiao, LIQUIDO[0])
	var agua := AGUA.instantiate()
	agua.name = "LiquidoMortal"
	agua.largura = comp + 900.0
	agua.altura = 460.0
	agua.cor = liq[0]
	agua.brasas = liq[1]
	agua.position = Vector2((x0 + ancora.x) * 0.5, _chao_y + 230.0)
	add_child(agua)

	# parede de fundo (não se sai pela esquerda). É o "fim do mundo": tem de
	# ler como maciço de rocha, não como uma parede a partir/trepar com
	# espaço do outro lado, e não como a laje escura chapada que era até
	# aqui -- um único retângulo de 260x760 com um `modulate` roxo.
	#
	# O que a faz ler como rocha é a SILHUETA: três lajes encavalitadas, de
	# larguras e alturas diferentes e com o topo em degrau, cada uma com o
	# terreno da região (que já traz capa/franja/lados próprios). Quanto
	# mais atrás, mais escura e mais dessaturada -- é a perspectiva aérea
	# que separa os planos.
	#
	# O escalonamento tem de ser em ALTURA e não só em profundidade: uma lasca
	# atrás de outra mais alta não se vê de todo. Cada uma pára onde a
	# seguinte começa, portanto a face recua um degrau de cada vez à medida
	# que sobe -- é isso que se vê da plataforma de partida, e não os topos
	# (esses ficam sempre fora do ecrã, e ainda bem: é o fim do mundo).
	#
	# O "pé" mantém a pegada da parede antiga (aresta direita encostada à
	# plataforma de partida, topo bem acima dela): o degrau não pode abrir
	# buraco por onde se saia do nível pela esquerda.
	#
	#   lasca = (aresta direita, largura, topo em Y, tom)
	var base_y := _chao_y + 320.0        # todas afundam no líquido
	var lascas := [
		[x0 + 20.0, 200.0, _chao_y - 300.0, Color(0.58, 0.54, 0.70)],
		[x0 - 10.0, 210.0, _chao_y - 620.0, Color(0.44, 0.40, 0.57)],
		[x0 - 140.0, 220.0, _chao_y - 780.0, Color(0.33, 0.29, 0.45)],
		[x0 - 270.0, 240.0, _chao_y - 920.0, Color(0.24, 0.21, 0.34)],
	]
	for i in lascas.size():
		var l: Array = lascas[i]
		var topo_y: float = l[2]
		var lasca := PLAT.instantiate()
		add_child(lasca)
		lasca.tamanho = Vector2(l[1], base_y - topo_y)
		lasca.position = Vector2(l[0] - l[1] * 0.5, (topo_y + base_y) * 0.5)
		lasca.modulate = l[3]
		lasca.z_index = -3 - i        # atrás da acção e umas das outras

	var casca := get_parent().get_node_or_null("Casca")
	if casca and casca.has_method("abrir_esquerda"):
		casca.abrir_esquerda(x0 - 160.0)
		# masmorra FECHADA: o tecto (`topo`) e' uma parede solida fixa, que
		# nada aqui em cima sabia -- a jornada podia mandar a espinha de
		# plataformas mais alto do que a sala permite, e o tecto bloqueava
		# o caminho por completo (bug: "parede a impedir de subir", nivel
		# incompletavel). Reaperta a banda vertical à altura real da sala.
		var topo_casca: Variant = casca.get("topo")
		if topo_casca != null:
			_teto_y = maxf(_teto_y, float(topo_casca) + 110.0)

	var atm := get_tree().get_first_node_in_group("atmosfera")
	if atm and atm.has_method("atualizar_extensao"):
		var largura_atual: float = atm.get("largura_nivel")
		atm.atualizar_extensao(maxf(largura_atual, comp + 3200.0), x0 - 400.0)

	# --- espinha de plataformas --------------------------------------
	var pool: Array = _pool_permitida()
	var x := x0 + 40.0
	var y := _chao_y - 150.0
	if _tendencia == -1:
		y = _teto_y + 160.0    # nível "a descer" -- começa lá em cima
	elif _tendencia == 1:
		y = _chao_y - 90.0     # nível "a subir" -- começa mesmo perto do chão

	# plataforma de partida (larga) + Koliani em cima
	var par := _novo_container(x)
	_plat(par, Vector2(x + 70.0, y), Vector2(190.0, 20.0), 46.0)
	if entrada_fresca:
		var inicio := Vector2(x + 40.0, y - 40.0)
		(kol as Node2D).global_position = inicio
		if "velocity" in kol:
			kol.velocity = Vector2.ZERO
		kol.set("_pos_inicial", inicio)
		EstadoJogo.definir_checkpoint(inicio)
	_checkpoint(x + 40.0, y, true)
	x += 240.0

	var passos := 0
	var ant_flavour := ""
	# quão longe ficam as câmaras de flavour umas das outras (passos da
	# espinha): muito espaçadas no Nível 1, coladas no Nível 30.
	var espaco_flavour := int(round(lerpf(7.0, 3.4, _dif)))
	var prox_flavour := espaco_flavour + _rng.randi() % 3
	# de 2 em 2/3 câmaras força-se uma VERTICAL (torre/poço/pilares); os
	# níveis de foco "vertical" (ver PERFIL) fazem-no com o dobro da cadência
	var passo_vert := 1 if _foco == "vertical" else 2
	var flavs_ate_vertical := passo_vert
	# altitude-alvo que vagueia por toda a banda vertical -> a espinha sobe e
	# desce em vagas longas em vez de ondular sempre à mesma altura
	var banda := _chao_y - _teto_y
	var alvo_y := _novo_alvo_y(banda)
	var passos_alvo := 4 + _rng.randi() % 4
	while x < ancora.x - 900.0:
		if passos % 10 == 0:
			par = _novo_container(x)
		# --- estrutura em 3 ACTOS (arco de um bioma tipo Dead Cells) -------
		# prog = 0 (início da jornada) .. 1 (encosta ao nível). `intens`
		# escala a densidade de perigos/inimigos: intro suave -> meio a
		# apertar -> alívio antes da rampa final para o chefe.
		var prog := clampf((x - x0) / maxf(1.0, comp), 0.0, 1.0)
		var intens := 1.0
		if prog < 0.28:
			intens = lerpf(0.35, 1.0, prog / 0.28)
		elif prog < 0.82:
			intens = lerpf(1.0, 1.28, (prog - 0.28) / 0.54)
		else:
			intens = 0.5
		# nova altitude-alvo de tempos a tempos
		if passos >= passos_alvo:
			passos_alvo = passos + 4 + _rng.randi() % 5
			alvo_y = _novo_alvo_y(banda)
		# --- passo da espinha: caminha para a altitude-alvo, mas NUNCA sobe
		#     mais que um salto de cada vez (descer/cair pode ser muito mais) ---
		var passo_y := clampf((alvo_y - y) * 0.5 + _rng.randf_range(-32.0, 32.0),
			-SUBIDA_MAX, 300.0)
		y = clampf(y + passo_y, _teto_y, _chao_y - 66.0)
		# plataformas mais largas e ligadas (pedido do Paulo, 2 set 2026):
		# menos "saltar de pedra em pedra minúscula", mais chão que dá para
		# pousar -- o desafio vem de mecânicas (perigo no vão, espinhos por
		# cima), não da precisão do salto em si.
		var w := _rng.randf_range(100.0, 160.0)
		var movel := _dif > 0.33 and _rng.randf() < (0.04 + 0.12 * _dif) * intens
		if movel:
			_plat_movel_spine(par, Vector2(x, y), w)
		else:
			_plat(par, Vector2(x, y), Vector2(w, 18.0))
			# chão plano mas mecanicamente exigente: espinhos numa ponta,
			# sempre com espaço livre do outro lado para pousar/pogar.
			if w > 130.0 and _rng.randf() < (0.08 + 0.22 * _dif) * intens:
				var esp := ESPINHOS.instantiate()
				esp.largura = 2
				var lado := -1.0 if _rng.randf() < 0.5 else 1.0
				esp.position = Vector2(x + lado * (w * 0.5 - 20.0), y)
				par.add_child(esp)
		# 2.º piso: às vezes uma plataforma logo por cima = rota alternativa
		if _rng.randf() < 0.12 and y - 210.0 > _teto_y:
			_plat(par, Vector2(x + _rng.randf_range(-28.0, 28.0),
				y - _rng.randf_range(150.0, 205.0)), Vector2(_rng.randf_range(56.0, 82.0), 16.0))
		# perigo no vão a seguir (não bloqueia a aterragem)
		if passos > 0 and _rng.randf() < (0.05 + 0.5 * _dif) * intens:
			_perigo_no_vao(par, x, y)
		# checkpoint a cada 2 plataformas
		if passos % 2 == 0:
			_checkpoint(x, y)
		# inimigo ocasional na plataforma
		if _rng.randf() < (0.06 + 0.34 * _dif) * intens:
			_inimigo_em(par, Vector2(x, y - 30.0))
		# decoração: os props de CHÃO vêm agora da própria Plataforma
		# (`plataforma.gd::_decorar`, com semente vinda da posição)
		if passos % 6 == 0:
			_coluna_fundo(par, x + _rng.randf_range(-120.0, 120.0))
		# toque de assinatura do nível (gimmick do docs/niveis.md)
		if passos > 1:
			_assinatura_nivel(par, x, y, intens)

		# --- câmara de tempos a tempos: alterna TENSÃO e ALÍVIO ---
		passos += 1
		if passos >= prox_flavour:
			prox_flavour = passos + espaco_flavour + _rng.randi() % 3
			var f: String
			_camaras += 1
			flavs_ate_vertical -= 1
			var sig: String = ASSINATURA.get(_regiao, "")
			var foco_f: String = _camara_do_foco()
			# de X em X câmaras, uma MECÂNICA AINDA NÃO VISTA neste nível
			var nova: String = ""
			_falta_nova -= 1
			if prog < 0.82 and _falta_nova <= 0:
				nova = _camara_nova(pool)
			if prog > 0.82:
				# ACTO 3: alívio antes da rampa final -> quase só descansos
				f = "descanso" if _rng.randf() < 0.8 else pool[_rng.randi() % pool.size()]
				_pos_intenso = false
			# A ESTREIA DO NÍVEL manda: entra no acto do meio e, a partir de
			# meia jornada, deixa de esperar pela sorte -- senão havia níveis
			# a acabar sem terem mostrado a sua própria mecânica.
			elif _estreia_por_fazer > 0 and prog >= 0.18 \
					and (prog >= 0.5 or _rng.randf() < 0.45):
				f = _estreia_cam
				_estreia_por_fazer -= 1
				# mansa (grau 0) = aparece sozinha e respira-se a seguir;
				# dura (grau 2) = encadeia-se com o que vier
				_pos_intenso = _estreia_grau == 0
			elif _pos_intenso:
				f = "descanso"          # logo a seguir a uma câmara puxada -> respira
				_pos_intenso = false
			elif nova != "":
				f = nova                # mecânica NOVA antes de repetir as velhas
				_falta_nova = CICLO_VARIEDADE
				_pos_intenso = f in INTENSAS
			elif flavs_ate_vertical <= 0:
				flavs_ate_vertical = passo_vert + _rng.randi() % 2
				# UMA só família vertical por nível (`_vertical_do_nivel`).
				# Antes sorteava-se entre as três a cada vez, portanto TODOS
				# os níveis tinham torres E poços E pilares -- era a maior
				# fatia do que dois níveis seguidos tinham em comum.
				f = _vertical_do_nivel
				_pos_intenso = true
			# FOCO do nível (ver PERFIL): no acto do meio, ~metade das câmaras
			# são da família do foco -> o nível ganha uma "cara" (plataformas /
			# combate / máquinas / gauntlet) em vez de sair tudo à sorte.
			elif foco_f != "" and prog >= 0.16 and prog <= 0.84 and _rng.randf() < 0.5:
				f = foco_f
				_pos_intenso = f in INTENSAS
			elif _camaras % 4 == 0:
				f = "descanso"
			# câmaras "tom" novas (crossfire/ferry/pedras/espinhos) -- ramo
			# próprio e ALTO na cadeia: a pool uniforme e os ramos de
			# arena/torre/descanso engoliam-nas quase sempre. `pool` já vem
			# filtrado por região+tier em `_pool_permitida()`.
			elif prog < 0.82 and _tem_tom_novo(pool) and _rng.randf() < 0.32:
				f = _escolher_tom_novo(pool)
				_pos_intenso = true
			elif prog >= 0.28 and prog <= 0.82 and sig != "" \
					and nivel_de_estreia(sig) <= _idx \
					and _rng.randf() < 0.3:
				f = sig                 # ACTO 2: a assinatura do bioma
				_pos_intenso = sig in ["guilhotinas", "fogo"]
			# UMA sala especial por nível (`_especial_do_nivel`), não as
			# quatro. Antes sorteava-se arena E corredor E cripta E
			# forquilha em todos os níveis, portanto todos tinham um pouco
			# de tudo -- a seguir às verticais, era a maior fatia do que dois
			# níveis seguidos tinham em comum. As famílias que faltarem a um
			# nível continuam a entrar pelo FOCO dele (ver `FOCO_CAMARAS`).
			elif prog < 0.82 and _dif > _dif_especial 					and _rng.randf() < 0.2:
				f = _especial_do_nivel
				_pos_intenso = true
			else:
				f = pool[_rng.randi() % pool.size()]
				if f == ant_flavour:
					f = pool[(_rng.randi() + 1) % pool.size()]
				_pos_intenso = f in INTENSAS
			ant_flavour = f
			_tipos_usados[f] = true
			var res := _flavour(par, f, x, y)
			x = res.x
			y = res.y
			alvo_y = y  # a espinha continua da altura onde a câmara acabou
			continue

		x += _rng.randf_range(148.0, 188.0)

	# --- passadeira final sólida até ao nível feito à mão ---
	par = _novo_container(x)
	var yf := clampf(y, _chao_y - 200.0, _chao_y - 80.0)
	var passar := PLAT.instantiate()
	add_child(passar)
	passar.position = Vector2((x + ancora.x + 200.0) * 0.5, yf + 30.0)
	passar.tamanho = Vector2(ancora.x + 400.0 - x + 200.0, 44.0)
	passar.altura_visual = 110.0
	_checkpoint(x + 60.0, yf, true)  # sempre um antes do chefe
	_inimigo_em(par, Vector2(x + 240.0, yf - 30.0))


# --- infra --------------------------------------------------------------

## Nova altitude-alvo para a espinha ir vagueando, respeitando a
## `_tendencia` deste nível: -1 puxa para perto do chão (nível "a
## descer"), +1 puxa para perto do teto (nível "a subir"), 0 fica numa
## banda estreita a meio (nível quase horizontal).
func _novo_alvo_y(banda: float) -> float:
	match _tendencia:
		1:
			return _chao_y - _rng.randf_range(banda * 0.55, banda * 0.92)
		-1:
			return _chao_y - _rng.randf_range(140.0, banda * 0.42)
		_:
			return _chao_y - _rng.randf_range(banda * 0.32, banda * 0.52)


## Quantos níveis para trás contam como "estreia recente" -- essas câmaras
## entram duas vezes na pool, portanto saem com o dobro da probabilidade.
## É o que impede o nível 60 de saber ao nível 20: a pool cresce, mas o peso
## anda com o jogador.
const JANELA_RECENTE := 8

## A pool de flavour da região atual, filtrada pelo que JÁ ESTREOU até este
## nível (ver `MECANICA_DO_NIVEL`) e com peso extra nas estreias recentes.
## Se a região ainda não tem nada disponível (níveis baixos numa região
## "dura"), cai nas câmaras suaves.
func _pool_permitida() -> Array:
	var base: Array = POOL_REGIAO.get(_regiao, POOL_REGIAO[0])
	var out: Array = []
	for f: String in base:
		var e := nivel_de_estreia(f)
		if e > _idx:
			continue          # ainda não estreou -- não pode aparecer
		out.append(f)
		if _idx - e < JANELA_RECENTE:
			out.append(f)     # estreia recente: pesa a dobrar
	return out if out.size() >= 2 else FLAVOUR_SUAVE.duplicate()


## Câmaras "tom" recentes que compensam ter um ramo próprio na seleção
## (senão nunca calhavam). Só as que a região tem na pool.
const TONS_NOVOS := ["crossfire", "ferry", "pedras", "espinhos"]

func _tem_tom_novo(pool: Array) -> bool:
	for t in TONS_NOVOS:
		if t in pool:
			return true
	return false


## Uma câmara que ainda NÃO apareceu neste nível (pool da região já filtrada
## por tier + as câmaras "extra" que não vivem em pool nenhuma). `""` quando
## já se viu tudo o que este nível pode dar -- aí a seleção normal segue.
func _camara_nova(pool: Array) -> String:
	var opc: Array = []
	for c: String in pool:
		if not _tipos_usados.has(c):
			opc.append(c)
	for c: String in TIER_EXTRA:
		if not _tipos_usados.has(c) and _dif + 0.0001 >= float(TIER_EXTRA[c]):
			opc.append(c)
	return opc[_rng.randi() % opc.size()] if not opc.is_empty() else ""


func _escolher_tom_novo(pool: Array) -> String:
	var opc: Array = []
	for t in TONS_NOVOS:
		if t in pool:
			opc.append(t)
	return opc[_rng.randi() % opc.size()]


## Uma câmara da família do FOCO deste nível (ver `PERFIL`), já cruzada com
## a região e o tier. `""` = a família ainda não tem nada disponível ->
## a seleção normal decide. "vertical" trata-se pela cadência das câmaras
## torre/poço/pilares, não por aqui.
func _camara_do_foco() -> String:
	if _foco == "misto" or _foco == "vertical":
		return ""
	var pool: Array = _pool_permitida()
	var opc: Array = []
	for c: String in FOCO_CAMARAS.get(_foco, []):
		if c in pool:
			opc.append(c)                       # câmara da região, já libertada
		elif c == "arena":
			opc.append(c)                       # sempre construível
		elif c == "cripta" and _dif > 0.08:
			opc.append(c)
		elif c == "corredor" and _dif > 0.28:
			opc.append(c)
		elif c == "forquilha" and _dif > 0.18:
			opc.append(c)
	return opc[_rng.randi() % opc.size()] if not opc.is_empty() else ""


func _novo_container(x: float) -> Node2D:
	_cont_i += 1
	var c := Node2D.new()
	c.name = "Cam_%d" % _cont_i
	add_child(c)
	if otimizar_visibilidade and DisplayServer.get_name() != "headless":
		var en := VisibleOnScreenEnabler2D.new()
		en.process_mode = Node.PROCESS_MODE_ALWAYS
		en.rect = Rect2(x - 1100.0, _chao_y - 1800.0, 3400.0, 2500.0)
		c.add_child(en)
	return c


func _plat(par: Node2D, pos: Vector2, tam: Vector2, alt_vis := 0.0) -> void:
	var p := PLAT.instantiate()
	p.position = pos
	p.tamanho = tam
	if alt_vis > 0.0:
		p.altura_visual = alt_vis
	par.add_child(p)


## Segmento móvel da espinha: uma PlataformaFlutuante com deriva PEQUENA (não
## se afasta ao ponto de a plataforma seguinte ficar fora de alcance).
func _plat_movel_spine(par: Node2D, pos: Vector2, w: float) -> void:
	var pf := PLAT_FLUT.instantiate()
	pf.largura = w + 24.0
	pf.balanco = 10.0
	pf.periodo = _rng.randf_range(2.2, 3.0)
	pf.deriva = _rng.randf_range(50.0, 90.0)
	pf.periodo_deriva = _rng.randf_range(3.0, 4.4)
	pf.position = pos
	par.add_child(pf)


## Perigo num vão (pêndulo, serra ou fogo) -- posicionado ENTRE plataformas,
## acima do líquido, sem tapar a aterragem. Vem em rajadas de um só tipo
## (ver `_perigo_tipo`/`_perigo_restante`) em vez de sortear tipo novo a
## cada vão.
func _perigo_no_vao(par: Node2D, x: float, y: float) -> void:
	if _perigo_restante <= 0:
		_perigo_tipo = _rng.randi() % 3
		_perigo_restante = 3 + _rng.randi() % 3  # rajada de 3-5 vãos seguidos
	_perigo_restante -= 1
	match _perigo_tipo:
		0:
			var pe := PENDULO.instantiate()
			var comp := _rng.randf_range(150.0, 210.0)
			pe.comprimento = comp
			pe.periodo = _rng.randf_range(1.9, 2.7) - 0.35 * _dif
			pe.amplitude_graus = 46.0 + 20.0 * _dif
			pe.dano = 8 + int(20.0 * _dif)
			pe.fase = _rng.randf()
			pe.position = Vector2(x + 95.0, y - comp - 30.0)
			par.add_child(pe)
		1:
			var s := SERRA.instantiate()
			s.position = Vector2(x + 95.0, y - 20.0)
			s.percurso = Vector2(0.0, -_rng.randf_range(80.0, 130.0 + 40.0 * _dif))
			s.tempo = _rng.randf_range(1.1, 1.7)
			par.add_child(s)
		2:
			var f := FOGO.instantiate()
			f.position = Vector2(x + 95.0, y + 6.0)
			f.intervalo = 2.3 - 0.6 * _dif
			f.dur_ativa = 0.8 + 0.5 * _dif
			f.fase = _rng.randf() * 1.5
			par.add_child(f)


## Catálogo de decoração da região (`tools/gerar_deco.py`), lido uma vez.
## Antes daqui saíam sempre os MESMOS três props do 0x72 (caixa, crânio,
## coluna) em todas as seis regiões -- era metade da razão de a jornada
## parecer igual do nível 1 ao 30.
var _deco_cache: Dictionary = {}


func _bioma_atual() -> String:
	var atm := get_tree().get_first_node_in_group("atmosfera")
	if atm and "bioma" in atm:
		return String(atm.bioma)
	return "floresta"


## Props da região com o assento `onde` ("chao" ou "parede").
func _props(onde: String) -> Array:
	var bioma := _bioma_atual()
	var chave := "%s|%s" % [bioma, onde]
	if _deco_cache.has(chave):
		return _deco_cache[chave]
	var cat: Dictionary = {}
	var cam := "res://assets/sprites/pixel/deco/deco.json"
	if FileAccess.file_exists(cam):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(cam))
		if d is Dictionary:
			cat = d
	var fora: Array = []
	var lista: Variant = cat.get(bioma, [])
	if lista is Array:
		for p in lista:
			if p is Dictionary and p.get("onde", "") == onde:
				fora.append("res://assets/sprites/pixel/deco/%s/%s.png" % [bioma, p["nome"]])
	_deco_cache[chave] = fora
	return fora


## Toque de assinatura do nível na jornada (ver `ASSIN_NIVEL`). Só perigos
## telegrafados que NÃO bloqueiam nem obrigam a nada -- a espinha continua
## a ser a rota, isto é tempero por cima. ~10-22% das plataformas.
func _assinatura_nivel(par: Node2D, x: float, y: float, intens: float) -> void:
	var tipo: String = ASSIN_NIVEL.get(_idx, "")
	if tipo == "":
		return
	if _rng.randf() > 0.10 + 0.10 * clampf(intens, 0.0, 1.2):
		return
	match tipo:
		"raizes":
			var r := RAIZ.instantiate()
			r.auto = true
			r.intervalo = _rng.randf_range(2.2, 3.2)
			r.fase = _rng.randf() * 2.4
			r.dano = 9 + int(7.0 * _dif)
			r.position = Vector2(x + _rng.randf_range(-32.0, 32.0), y)
			par.add_child(r)
		"teias":
			var t := TEIA.instantiate()
			t.permanente = true
			t.largura = _rng.randf_range(84.0, 122.0)
			t.dur_preso = 0.55
			t.position = Vector2(x + _rng.randf_range(-18.0, 18.0), y - 6.0)
			par.add_child(t)
		"acido":
			var g := GOTA.instantiate()
			g.automatico = true
			g.intervalo = _rng.randf_range(2.4, 3.6)
			g.dano = 9 + int(8.0 * _dif)
			g.altura_queda = 240.0
			g.position = Vector2(x + _rng.randf_range(-26.0, 26.0),
				y - _rng.randf_range(140.0, 220.0))
			par.add_child(g)
		"raio":
			var l := RAIO.instantiate()
			l.automatico = true
			l.periodo = _rng.randf_range(2.6, 3.8)
			l.fase = _rng.randf() * 2.4
			l.dano = 15 + int(11.0 * _dif)
			l.position = Vector2(x + _rng.randf_range(-12.0, 12.0), y)
			par.add_child(l)


## Volume alto a subir do líquido, atrás dos atores (profundidade): coluna,
## árvore morta, casario, estátua -- o que a região tiver. Antes era sempre
## a MESMA coluna do 0x72, em todos os níveis das seis regiões.
func _coluna_fundo(par: Node2D, x: float) -> void:
	var lista := _props("parede")
	if lista.is_empty():
		return
	var cam: String = lista[_rng.randi() % lista.size()]
	var tex: Texture2D = load(cam) if ResourceLoader.exists(cam) else null
	if tex == null:
		return
	# tudo à mesma ALTURA aparente (~260-460 px): os packs vêm a resoluções
	# muito diferentes e sem isto uma casa ficava do tamanho de uma vela
	var alvo := _rng.randf_range(260.0, 460.0)
	var esc: float = clampf(alvo / maxf(1.0, float(tex.get_height())), 0.8, 7.0)
	var s := Sprite2D.new()
	s.texture = tex
	s.scale = Vector2(esc if _rng.randf() < 0.5 else -esc, esc)
	s.z_index = -3
	# recuado: mais escuro e mais azul, para ficar mesmo atrás da acção
	s.modulate = Color(0.58, 0.56, 0.72, _rng.randf_range(0.70, 0.92))
	s.position = Vector2(x, _chao_y - float(tex.get_height()) * esc * 0.5 + 34.0)
	par.add_child(s)


func _inimigo_em(par: Node2D, pos: Vector2, elite := false) -> void:
	var d := DEMONIO.instantiate()
	d.especie = _especie_aleatoria()
	d.position = pos
	d.alcance_patrulha = _rng.randf_range(40.0, 90.0)
	# ELITE de arena (curva de dificuldade): a partir do meio da campanha as
	# salas de combate da jornada trazem um bicho grande que aguenta e bate.
	if elite:
		d.elite = true
		d.scale = Vector2(1.35, 1.35)
		d.vida = 90 + int(140.0 * _dif)
		d.dano_contacto = 12 + int(14.0 * _dif)
		d.comportamento = "carga" if _rng.randf() < 0.5 else "saltador"
		d.alcance_patrulha = 120.0
		par.add_child(d)
		return
	# n21 Vila dos Sem-Rosto (gimmick: "alguns NPCs são inimigos disfarçados")
	# -- metade dos bichos da jornada ficam dormentes e só se revelam de perto.
	if _idx == 20 and _rng.randf() < 0.5:
		d.dormente = true
	# comportamento próprio -- cada bicho uma ameaça (pegada Dead Cells)
	var r := _rng.randf()
	if d.especie == "olho" or d.especie == "abutre":
		if _dif > 0.08 and r < 0.7:
			d.comportamento = "voador"   # o olho e o abutre voam e mergulham
	elif _dif > 0.15 and r < 0.18 + 0.26 * _dif:
		var opcoes := ["saltador", "carga"]
		if _dif > 0.22:
			opcoes.append("cuspidor")
		if _dif > 0.3:
			opcoes.append("trepador")
		if _dif > 0.35:
			opcoes.append("escudeiro")
		var esc: String = opcoes[_rng.randi() % opcoes.size()]
		d.comportamento = esc
		if esc == "trepador":
			d.position.y -= _rng.randf_range(120.0, 170.0)  # colado mais acima
	par.add_child(d)


const ESP_REGIAO := {
	0: ["goblin", "mushroom", "lodo", "besouro", "gosma"],
	1: ["esqueleto", "chort", "orc", "imp", "mastim"],
	2: ["xamane", "wogol", "olho", "abutre", "imp"],
	3: ["esqueleto", "necromante", "chort", "ogro", "gosma"],
	4: ["orc", "abobora", "xamane", "raptor", "mastim"],
	5: ["demonio_grande", "ogro", "chort", "olho", "raptor"],
	6: ["imp", "chort", "demonio_grande", "abobora", "mastim"],
	7: ["esqueleto", "gosma", "lodo", "wogol", "olho"],
	8: ["mastim", "abutre", "besouro", "esqueleto", "raptor"],
	9: ["raptor", "besouro", "ogro", "necromante", "abobora"],
	10: ["mushroom", "goblin", "lodo", "gosma", "olho"],
	11: ["besouro", "wogol", "chort", "esqueleto", "imp"],
	12: ["abutre", "olho", "xamane", "wogol", "imp"],
	13: ["abobora", "wogol", "gosma", "mushroom", "olho"],
	14: ["esqueleto", "necromante", "wogol", "chort", "abobora"],
	15: ["lodo", "gosma", "raptor", "esqueleto", "olho"],
	16: ["imp", "chort", "demonio_grande", "wogol", "ogro"],
	17: ["gosma", "olho", "wogol", "xamane", "lodo"],
	18: ["orc", "ogro", "abutre", "necromante", "esqueleto"],
	19: ["goblin", "esqueleto", "chort", "demonio_grande", "olho"],
}

## A "cara" de cada NÍVEL (pedido do Paulo: não repetir o mesmo monstro em
## todos os níveis). Dentro de uma região não há assinaturas repetidas, e as
## 19 espécies aparecem todas ao longo da campanha. É o bicho que mais se vê
## na jornada desse nível; o resto vem da pool da região.
const ESP_ASSINATURA := [
	"goblin", "mushroom", "besouro", "gosma", "lodo",              # I  Floresta
	"esqueleto", "imp", "chort", "mastim", "orc",                  # II Prisão
	"xamane", "abutre", "olho", "wogol", "imp",                    # III Torres
	"necromante", "esqueleto", "gosma", "wogol", "ogro",           # IV Catacumbas
	"abobora", "orc", "mastim", "raptor", "xamane",                # V  Cidade
	"demonio_grande", "chort", "raptor", "ogro", "olho",           # VI Castelo
	"imp", "chort", "mastim", "abobora", "demonio_grande",         # VII Terras Queimadas
	"esqueleto", "gosma", "olho", "lodo", "wogol",                 # VIII Mar dos Mortos
	"mastim", "abutre", "besouro", "esqueleto", "raptor",          # IX Reino do Gelo
	"raptor", "ogro", "besouro", "necromante", "xamane",           # X Deserto dos Esquecidos
	"mushroom", "goblin", "olho", "lodo", "gosma",                 # XI Jardins do Rei
	"besouro", "esqueleto", "wogol", "chort", "imp",               # XII Cidade das Maquinas
	"abutre", "xamane", "wogol", "olho", "imp",                    # XIII Ceu Partido
	"abobora", "wogol", "gosma", "mushroom", "olho",               # XIV Reino dos Sonhos
	"esqueleto", "necromante", "wogol", "chort", "abobora",        # XV Cidade dos Mortos
	"lodo", "raptor", "esqueleto", "gosma", "olho",                # XVI Mar Vermelho
	"imp", "chort", "wogol", "demonio_grande", "ogro",             # XVII Inferno
	"gosma", "olho", "wogol", "xamane", "lodo",                    # XVIII O Vazio
	"orc", "abutre", "ogro", "necromante", "esqueleto",            # XIX Guerra dos Reinos
	"goblin", "esqueleto", "chort", "demonio_grande", "olho",      # XX O Ultimo Caminho
]


func _especie_aleatoria() -> String:
	var assinatura: String = ESP_ASSINATURA[clampi(_idx, 0, ESP_ASSINATURA.size() - 1)]
	if _rng.randf() < 0.45:
		return assinatura
	var lista: Array = ESP_REGIAO.get(_regiao, [assinatura])
	return lista[_rng.randi() % lista.size()]


## `forcar` ignora o espaçamento mínimo (início da jornada e antes do chefe).
func _checkpoint(x: float, y: float, forcar := false) -> void:
	if not forcar and absf(x - _ultimo_check_x) < DIST_CHECKPOINT:
		return
	_ultimo_check_x = x
	var ck := Area2D.new()
	ck.name = "JornadaCheck_%d" % roundi(x)
	ck.collision_layer = 16
	ck.collision_mask = 2
	ck.position = Vector2(x, y - 46.0)
	var cf := CollisionShape2D.new()
	var rc := RectangleShape2D.new()
	rc.size = Vector2(52.0, 96.0)
	cf.shape = rc
	ck.add_child(cf)
	ck.set_script(CHECKPOINT)
	add_child(ck)


func _especie_do_nivel() -> String:
	for d in get_tree().get_nodes_in_group("inimigos"):
		if "especie" in d:
			return d.especie
	return "goblin"


# --- câmaras de flavour (avançam a espinha) --------------------------------
## Cada uma recebe o (x, y) da última plataforma da espinha e devolve o
## (x, y) da última que ela própria pôs -- a espinha continua daí.

func _flavour(par: Node2D, tipo: String, x: float, y: float) -> Vector2:
	# diagnóstico: `MAPA_CAMARAS=1 godot ...` lista as câmaras geradas em cada
	# nível (usado por tools/mapa_camaras.gd para saber onde ver cada uma).
	if OS.has_environment("MAPA_CAMARAS"):
		print("CAMARA idx=%d tipo=%s x=%.0f" % [_idx, tipo, x])
	match tipo:
		"saltos": return _f_saltos(par, x, y)
		"serras": return _f_serras(par, x, y)
		"pendulos": return _f_pendulos(par, x, y)
		"ritmo": return _f_ritmo(par, x, y)
		"trampolim": return _f_trampolim(par, x, y)
		"gruta": return _f_gruta(par, x, y)
		"quebra": return _f_quebra(par, x, y)
		"correntes": return _f_correntes(par, x, y)
		"elevador": return _f_elevador(par, x, y)
		"vento": return _f_vento(par, x, y)
		"gravidade": return _f_gravidade(par, x, y)
		"guilhotinas": return _f_guilhotinas(par, x, y)
		"fogo": return _f_fogo(par, x, y)
		"impulso": return _f_impulso(par, x, y)
		"portal": return _f_portal(par, x, y)
		"torre": return _f_torre(par, x, y)
		"poco": return _f_poco(par, x, y)
		"pilares": return _f_pilares(par, x, y)
		"descanso": return _f_descanso(par, x, y)
		"forquilha": return _f_forquilha(par, x, y)
		"arena": return _f_arena(par, x, y)
		"corredor": return _f_corredor(par, x, y)
		"cripta": return _f_cripta(par, x, y)
		"crossfire": return _f_crossfire(par, x, y)
		"ferry": return _f_ferry(par, x, y)
		"pedras": return _f_pedras(par, x, y)
		"espinhos": return _f_espinhos(par, x, y)
		"alavanca": return _f_alavanca(par, x, y)
		"velas": return _f_velas(par, x, y)
		"sinos": return _f_sinos(par, x, y)
		"prensa": return _f_prensa(par, x, y)
		"espelhos": return _f_espelhos(par, x, y)
		"segredo": return _f_segredo(par, x, y)
		"lava_sobe": return _f_lava_sobe(par, x, y)
		"mare": return _f_mare(par, x, y)
		"espectral": return _f_espectral(par, x, y)
		"vitral": return _f_vitral(par, x, y)
		"para_raios": return _f_para_raios(par, x, y)
		"bombas": return _f_bombas(par, x, y)
		"queda": return _f_queda(par, x, y)
		"tapete": return _f_tapete(par, x, y)
		"orbita": return _f_orbita(par, x, y)
		"areia": return _f_areia(par, x, y)
		"grav_baixa": return _f_grav_baixa(par, x, y)
		"placa": return _f_placa(par, x, y)
		"circuito": return _f_circuito(par, x, y)
		"anel": return _f_anel(par, x, y)
		"horda": return _f_horda(par, x, y)
		"chuva": return _f_chuva(par, x, y)
	# tipo sem handler -> não deve acontecer (pool/assinatura mal configurada).
	# Avisa em vez de gerar um vão morto silencioso e cai num `descanso`.
	push_warning("GeradorCorredor: câmara '%s' sem _f_ correspondente" % tipo)
	return _f_descanso(par, x, y)


## FERRY: um fosso largo sobre o líquido atravessado por UMA plataforma que
## anda sempre de um lado ao outro (`TumuloElevador` com curso horizontal).
## Salta-se para cima dela, atravessa-se em pé a desviar de 2 lâminas
## penduradas a meio, e sai-se do outro lado. O beat "a viagem".
func _f_ferry(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 200.0, _chao_y - 140.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(96.0, 16.0))                 # cais de embarque
	var vao := _rng.randf_range(620.0, 880.0) + 220.0 * _dif
	# a balsa
	var tu := TUMULO.instantiate()
	tu.auto = true
	tu.curso = Vector2(vao, 0.0)
	tu.velocidade = 96.0 + 30.0 * _dif
	tu.largura = 128.0
	tu.position = Vector2(x + 90.0, cy)
	par.add_child(tu)
	# 2 lâminas penduradas a meio do fosso (desviar em pé, agachar não chega)
	for f in 2:
		var px := x + 90.0 + vao * lerpf(0.34, 0.7, float(f))
		var comp := _rng.randf_range(160.0, 210.0)
		var pe := PENDULO.instantiate()
		pe.comprimento = comp
		pe.periodo = _rng.randf_range(1.9, 2.6) - 0.3 * _dif
		pe.amplitude_graus = 44.0 + 18.0 * _dif
		pe.dano = 8 + int(18.0 * _dif)
		pe.fase = 0.5 * float(f)
		pe.position = Vector2(px, cy - comp - 24.0)
		par.add_child(pe)
	_coluna_fundo(par, x + 90.0 + vao * 0.5)
	# cais de desembarque -- sólido e largo
	x += 90.0 + vao + _rng.randf_range(60.0, 96.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## ESPINHOS: o caminho abre em duas calhas até se voltar a juntar. A calha
## BAIXA é um tapete de espinhos (`Espinhos`, grupo "pogavel") -- quem
## domina o POGO (Fase 1) atravessa aos ressaltos; a calha ALTA é uma fila
## de plataformas limpas, o caminho justo. Falhar o pogo custa vida + uma
## queda curta para a plataforma por baixo dos espinhos (não é o líquido).
func _f_espinhos(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 220.0, _chao_y - 150.0)
	var n := 4 + int(_dif * 2.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(104.0, 16.0))          # boca da forquilha
	# calha BAIXA -- tapete de espinhos com uma plataforma por baixo de cada
	var lx := x
	var by := cy + 66.0
	for _i in n:
		lx += _rng.randf_range(122.0, 150.0)
		_plat(par, Vector2(lx, by), Vector2(98.0, 14.0))
		var sp := ESPINHOS.instantiate()
		sp.largura = 6
		sp.position = Vector2(lx, by)
		par.add_child(sp)
	# calha ALTA -- plataformas limpas (o caminho justo). Sobe em degraus
	# que respeitam SUBIDA_MAX (o 1.º salto a partir da boca não pode ser
	# mais que um salto+duplo) até uma altura de cruzeiro sobre os espinhos.
	var hx := x
	var hy := cy
	var hy_alvo: float = maxf(_teto_y + 40.0, cy - _rng.randf_range(150.0, 180.0))
	for _i in n:
		hx += _rng.randf_range(150.0, 176.0)
		hy = maxf(hy_alvo, hy - SUBIDA_MAX)
		_plat(par, Vector2(hx, hy), Vector2(84.0, 15.0))
	# reencontro
	var jx: float = maxf(lx, hx) + _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(jx, cy), Vector2(126.0, 18.0))
	_checkpoint(jx, cy, true)
	return Vector2(jx, cy)


## PEDRAS (assinatura das Catacumbas): corre-se por um beiral sem tecto a
## desviar de uma saraivada de pedras que caem -- umas por proximidade,
## outras em ciclo (ritmo). Nada de tecto baixo (isso é a `gruta`) nem
## parede interior (isso é a `cripta`): é só movimento em frente e leitura
## das que já tremem.
func _f_pedras(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 150.0, _chao_y - 100.0)
	var n := 5 + int(_dif * 3.0)
	for i in n:
		x += _rng.randf_range(150.0, 178.0)
		cy = clampf(cy + _rng.randf_range(-30.0, 30.0), _teto_y + 120.0, _chao_y - 90.0)
		_plat(par, Vector2(x, cy), Vector2(92.0, 16.0))
		var pd := PEDRA.instantiate()
		pd.chao_y = cy - 8.0
		pd.dano = 8 + int(18.0 * _dif)
		if i % 3 == 1:
			pd.automatico = true                       # uma em cada três em ciclo
			pd.periodo = _rng.randf_range(2.4, 3.4) - 0.5 * _dif
			pd.fase = _rng.randf() * 2.0
		else:
			pd.raio_gatilho = 82.0                     # as outras por proximidade
		pd.aviso = 0.6 - 0.2 * _dif
		pd.position = Vector2(x + _rng.randf_range(-16.0, 16.0), cy - _rng.randf_range(150.0, 220.0))
		par.add_child(pd)
		if i % 2 == 0:
			_checkpoint(x, cy)
	x += _rng.randf_range(150.0, 178.0)
	_plat(par, Vector2(x, cy), Vector2(104.0, 18.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


## FOGO CRUZADO: lanço recto de plataformas com torretas montadas em ambos
## os lados a cuspir fogo horizontal ATRAVÉS do caminho, a alturas
## alternadas. Passa-se salto a salto no intervalo dos tiros -- é leitura de
## padrão, não plataforma difícil. Ritmo Dead Cells: pressão à distância.
func _f_crossfire(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 160.0, _chao_y - 150.0)
	var n := 4 + int(_dif * 3.0)
	var x_ini := x
	for i in n:
		x += _rng.randf_range(150.0, 178.0)
		# a espinha desta câmara ondula pouco (o desafio é o fogo, não o salto)
		cy = clampf(cy + _rng.randf_range(-26.0, 26.0), _teto_y + 150.0, _chao_y - 130.0)
		_plat(par, Vector2(x, cy), Vector2(84.0, 16.0))
		# uma torreta por passo, a alternar de lado; dispara na horizontal,
		# a uma altura ligeiramente acima/abaixo da plataforma -> o feixe
		# cruza a linha de salto.
		var esq := i % 2 == 0
		var tr := TORRETA.instantiate()
		tr.direcao = Vector2(1.0 if esq else -1.0, 0.0)
		tr.intervalo = 2.7 - 0.8 * _dif
		tr.telegrafo = 0.6 - 0.18 * _dif
		tr.dano = 6 + int(16.0 * _dif)
		tr.vel_bola = 210.0 + 70.0 * _dif
		tr.fase = 0.5 * float(i)
		tr.position = Vector2(x + (-118.0 if esq else 118.0),
			cy - 30.0 + (18.0 if i % 4 < 2 else -34.0))
		par.add_child(tr)
		if i % 2 == 0:
			_checkpoint(x, cy)
	# saída sólida e limpa (para não cair logo a seguir ao último feixe)
	x += _rng.randf_range(150.0, 180.0)
	_plat(par, Vector2(x, cy), Vector2(104.0, 18.0))
	_checkpoint(x, cy)
	_coluna_fundo(par, (x_ini + x) * 0.5)
	return Vector2(x, cy)


## CRIPTA: sala fechada com uma parede interior baixa a saltar por cima (ou
## contornar pela plataforma alta) + pedras que caem. Navegação vertical curta.
func _f_cripta(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 150.0, _chao_y - 96.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x + 130.0, cy), Vector2(280.0, 22.0), 42.0)          # chão da sala
	_plat(par, Vector2(x + 130.0, cy - 40.0), Vector2(24.0, 64.0))          # parede interior baixa
	_plat(par, Vector2(x + 130.0, cy - 104.0), Vector2(92.0, 16.0))         # rota alta alternativa
	for i in 2:
		var pd := PEDRA.instantiate()
		pd.chao_y = cy - 8.0
		pd.dano = 8 + int(16.0 * _dif)
		pd.raio_gatilho = 78.0
		pd.position = Vector2(x + 70.0 + 120.0 * float(i), cy - 130.0)
		par.add_child(pd)
	_checkpoint(x + 40.0, cy, true)
	if _dif > 0.2:
		_inimigo_em(par, Vector2(x + 224.0, cy - 30.0))
	x += 280.0 + _rng.randf_range(150.0, 176.0)
	var ny: float = maxf(_teto_y + 40.0, cy - _rng.randf_range(-30.0, SUBIDA_MAX))
	_plat(par, Vector2(x, ny), Vector2(100.0, 18.0))
	return Vector2(x, ny)


## ARENA de combate: chão sólido largo por cima do líquido, vários inimigos
## (comportamentos variados), checkpoint. "Limpa a sala" -- ritmo Dead Cells.
func _f_arena(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 120.0, _chao_y - 88.0)
	x += _rng.randf_range(150.0, 178.0)
	var larg := _rng.randf_range(430.0, 560.0)
	_plat(par, Vector2(x + larg * 0.5, cy), Vector2(larg, 26.0), 48.0)
	_coluna_fundo(par, x + 40.0)
	_coluna_fundo(par, x + larg - 40.0)
	_checkpoint(x + 44.0, cy, true)
	var n := 3 + int(_dif * 4.0)
	for i in n:
		var ex := x + 80.0 + (larg - 160.0) * (float(i) / float(maxi(1, n - 1)))
		# a partir do meio da campanha, um dos bichos da arena é ELITE
		_inimigo_em(par, Vector2(ex, cy - 30.0), _dif > 0.42 and i == n / 2)
	x += larg + _rng.randf_range(148.0, 176.0)
	var ny: float = maxf(_teto_y + 40.0, cy - _rng.randf_range(-40.0, SUBIDA_MAX))
	_plat(par, Vector2(x, ny), Vector2(104.0, 18.0))
	_checkpoint(x, ny)
	return Vector2(x, ny)


## CORREDOR apertado: tecto baixo (bater com a cabeça se saltar) + serras em
## calha no ritmo. Passa-se a correr/rolar, não a saltar.
func _f_corredor(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _chao_y - 260.0, _chao_y - 120.0)
	var n := 4 + int(_dif * 3.0)
	for i in n:
		x += _rng.randf_range(150.0, 176.0)
		_plat(par, Vector2(x, cy), Vector2(96.0, 16.0))
		_plat(par, Vector2(x, cy - 96.0), Vector2(120.0, 22.0))   # tecto baixo
		var s := SERRA.instantiate()
		s.position = Vector2(x - 84.0, cy - _rng.randf_range(40.0, 62.0))
		s.percurso = Vector2(150.0, 0.0)
		s.tempo = _rng.randf_range(1.1, 1.7)
		par.add_child(s)
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


## --- ritmo: alívio e bifurcação -----------------------------------------

## ALÍVIO: plataforma larga e LIMPA (zero perigos), checkpoint garantido e
## um pouco de vista (colunas ao fundo). O respiro entre gauntlets.
func _f_descanso(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 90.0, _chao_y - 88.0)
	x += _rng.randf_range(150.0, 182.0)
	_plat(par, Vector2(x + 150.0, cy), Vector2(330.0, 24.0), 44.0)
	_checkpoint(x + 40.0, cy, true)
	_coluna_fundo(par, x + 70.0)
	_coluna_fundo(par, x + 240.0)
	x += 330.0
	return Vector2(x, cy)


## FORQUILHA: o caminho abre em dois e volta a juntar-se. Rota ALTA curta e
## com perigos; rota BAIXA mais longa e segura. Ambas as pontas alcançam o
## reencontro (de cima desce-se; de baixo é <= um salto).
func _f_forquilha(par: Node2D, x: float, y: float) -> Vector2:
	var passo := _rng.randf_range(156.0, 176.0)
	var n := 3
	_plat(par, Vector2(x + 60.0, y), Vector2(120.0, 18.0))  # partida à altura da espinha
	var bx := x + 60.0
	var hy := y
	for i in n:
		hy = maxf(_teto_y + 40.0, hy - _rng.randf_range(72.0, SUBIDA_MAX))
		_plat(par, Vector2(bx + passo * float(i + 1), hy), Vector2(72.0, 15.0))
		if i < n - 1 and _rng.randf() < 0.5 + 0.3 * _dif:
			_perigo_no_vao(par, bx + passo * float(i + 1), hy)
	var ly: float = minf(y + 190.0, _chao_y - 82.0)
	for i in n:
		_plat(par, Vector2(bx + passo * float(i + 1), ly), Vector2(90.0, 16.0))
	var jx := bx + passo * float(n + 1)
	var jy: float = clampf(hy + 90.0, ly - 96.0, ly - 40.0)
	_plat(par, Vector2(jx, jy), Vector2(130.0, 18.0))
	_checkpoint(jx, jy)
	return Vector2(jx, jy)


## --- câmaras VERTICAIS (dão altura a sério à jornada) ---------------------

## Torre: subida em ziguezague apertado que ganha MUITA altura (net
## +700..+1200). Δx pequeno, Δy = sempre <= um salto.
func _f_torre(par: Node2D, x: float, y: float) -> Vector2:
	var n := 7 + int(_dif * 5.0)
	var cy := y
	for i in n:
		x += _rng.randf_range(62.0, 106.0)
		cy = maxf(_teto_y, cy - _rng.randf_range(84.0, SUBIDA_MAX))
		_plat(par, Vector2(x, cy), Vector2(_rng.randf_range(58.0, 80.0), 16.0))
		if i > 0 and i < n - 1 and _rng.randf() < 0.16 + 0.4 * _dif:
			_perigo_no_vao(par, x, cy)
		if i % 3 == 0:
			_coluna_fundo(par, x + _rng.randf_range(-90.0, 90.0))
		if cy <= _teto_y + 12.0:
			break
	_checkpoint(x, cy)
	x += _rng.randf_range(140.0, 178.0)
	_plat(par, Vector2(x, cy), Vector2(104.0, 18.0))  # varanda do topo
	return Vector2(x, cy)


## Poço: desce por um funil até rente ao líquido mortal, checkpoint no
## fundo, e volta a subir pela parede oposta. Tenso.
func _f_poco(par: Node2D, x: float, y: float) -> Vector2:
	var fundo_y := _chao_y - 82.0
	var cy := y
	for _i in 4:
		x += _rng.randf_range(118.0, 156.0)
		cy = minf(fundo_y, cy + _rng.randf_range(150.0, 240.0))
		_plat(par, Vector2(x, cy), Vector2(_rng.randf_range(70.0, 96.0), 16.0))
	_checkpoint(x, cy)
	if _rng.randf() < 0.5 + 0.4 * _dif:
		_perigo_no_vao(par, x, cy)
	var alvo := maxf(_teto_y + 120.0, y - _rng.randf_range(140.0, 380.0))
	for _i in 6:
		x += _rng.randf_range(70.0, 116.0)
		cy = maxf(alvo, cy - _rng.randf_range(86.0, SUBIDA_MAX))
		_plat(par, Vector2(x, cy), Vector2(_rng.randf_range(58.0, 80.0), 16.0))
		if cy <= alvo + 6.0:
			break
	x += _rng.randf_range(148.0, 182.0)
	_plat(par, Vector2(x, cy), Vector2(100.0, 18.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


## Pilares: colunas altas (SÓ VISUAIS -- nunca colidem, senão cortavam o
## caminho) com uma plataforma SÓLIDA no cimo; salta-se de topo em topo com
## o vazio lá em baixo.
func _f_pilares(par: Node2D, x: float, y: float) -> Vector2:
	var n := 3 + _rng.randi() % 3
	var cy := y
	for i in n:
		x += _rng.randf_range(150.0, 184.0)
		cy = clampf(cy - _rng.randf_range(-96.0, SUBIDA_MAX), _teto_y + 40.0, _chao_y - 150.0)
		_coluna_fundo(par, x)  # o "pilar" é só um sprite de fundo, não bloqueia
		_plat(par, Vector2(x, cy), Vector2(_rng.randf_range(74.0, 100.0), 16.0))  # o topo (sólido)
		if i > 0 and _rng.randf() < 0.24 + 0.36 * _dif:
			_perigo_no_vao(par, x, cy)
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


## Salta-plataformas em ziguezague apertado (sobe e desce muito).
func _f_saltos(par: Node2D, x: float, y: float) -> Vector2:
	var n := 5 + int(_dif * 3.0)
	var cy := y
	for i in n:
		x += _rng.randf_range(158.0, 190.0)
		var d := _rng.randf_range(-140.0, 96.0)
		cy = clampf(cy - d, _chao_y - 470.0, _chao_y - 70.0)
		var quebra := i > 0 and i < n - 1 and _rng.randf() < 0.12 + 0.28 * _dif
		if quebra:
			var q := PLAT_QUEBRA.instantiate()
			q.tamanho = Vector2(78.0, 16.0)
			q.position = Vector2(x, cy)
			par.add_child(q)
		else:
			_plat(par, Vector2(x, cy), Vector2(_rng.randf_range(64.0, 88.0), 16.0))
		if _rng.randf() < 0.08 + 0.42 * _dif:
			_perigo_no_vao(par, x, cy)
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


## Corredor de serras: plataformas com serras horizontais em calha por baixo
## e por cima -- passa-se a saltar no ritmo.
func _f_serras(par: Node2D, x: float, y: float) -> Vector2:
	var n := 4 + int(_dif * 2.0)
	var cy := clampf(y, _chao_y - 300.0, _chao_y - 150.0)
	for i in n:
		x += _rng.randf_range(170.0, 200.0)
		_plat(par, Vector2(x, cy), Vector2(84.0, 16.0))
		var s := SERRA.instantiate()
		s.position = Vector2(x - 90.0, cy - _rng.randf_range(38.0, 58.0))
		s.percurso = Vector2(150.0, 0.0)
		s.tempo = _rng.randf_range(1.2, 1.8)
		par.add_child(s)
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


func _f_pendulos(par: Node2D, x: float, y: float) -> Vector2:
	var n := 4 + int(_dif * 2.0)
	var cy := clampf(y, _chao_y - 320.0, _chao_y - 130.0)
	for i in n:
		x += _rng.randf_range(150.0, 178.0)
		_plat(par, Vector2(x, cy), Vector2(72.0, 16.0))
		var comp := _rng.randf_range(170.0, 230.0)
		var pe := PENDULO.instantiate()
		pe.comprimento = comp
		pe.periodo = _rng.randf_range(1.8, 2.6) - 0.3 * _dif
		pe.amplitude_graus = 48.0 + 18.0 * _dif
		pe.dano = 8 + int(20.0 * _dif)
		pe.fase = float(i) / float(n)
		pe.position = Vector2(x + 82.0, cy - comp - 26.0)
		par.add_child(pe)
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


## Plataformas rítmicas (aparecem/somem) -- tem de se ir sem parar.
func _f_ritmo(par: Node2D, x: float, y: float) -> Vector2:
	var n := 5 + int(_dif * 3.0)
	var cy := clampf(y, _chao_y - 360.0, _chao_y - 140.0)
	# plataforma fixa de partida
	_plat(par, Vector2(x + 90.0, cy), Vector2(80.0, 16.0))
	x += 90.0
	for i in n:
		x += _rng.randf_range(150.0, 176.0)
		cy = clampf(cy - _rng.randf_range(-90.0, 80.0), _chao_y - 420.0, _chao_y - 110.0)
		var pr := PLAT_RITMO.instantiate()
		pr.tamanho = Vector2(88.0, 16.0)
		pr.periodo = _rng.randf_range(2.0, 2.8)
		pr.fase = fmod(0.28 * float(i), 1.0)
		pr.position = Vector2(x, cy)
		par.add_child(pr)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(90.0, 16.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


func _f_trampolim(par: Node2D, x: float, y: float) -> Vector2:
	var cy := y
	for i in 3:
		x += _rng.randf_range(150.0, 175.0)
		cy = clampf(cy + 40.0, _chao_y - 200.0, _chao_y - 70.0)  # desce um pouco
		_plat(par, Vector2(x, cy), Vector2(84.0, 16.0))
		var tr := TRAMPOLIM.instantiate()
		tr.impulso = 800.0 + 15.0 * float(i)  # ~1.5x a altura do duplo salto
		tr.position = Vector2(x, cy - 18.0)
		par.add_child(tr)
		# plataforma alta de aterragem
		x += _rng.randf_range(150.0, 180.0)
		cy = clampf(cy - _rng.randf_range(150.0, 210.0), _chao_y - 480.0, _chao_y - 120.0)
		_plat(par, Vector2(x, cy), Vector2(90.0, 16.0))
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


## Gruta apertada: tecto baixo, tem de se descer para um túnel e voltar a
## subir; estalactites que caem.
func _f_gruta(par: Node2D, x: float, y: float) -> Vector2:
	var cy := y
	# desce ao túnel
	x += 165.0; cy = clampf(cy + 130.0, _chao_y - 160.0, _chao_y - 74.0)
	_plat(par, Vector2(x, cy), Vector2(90.0, 16.0))
	_plat(par, Vector2(x, cy - 90.0), Vector2(150.0, 26.0))   # tecto do túnel
	for i in 3:
		x += _rng.randf_range(150.0, 172.0)
		_plat(par, Vector2(x, cy), Vector2(80.0, 16.0))
		_plat(par, Vector2(x, cy - 88.0), Vector2(120.0, 24.0))  # tecto
		var pd := PEDRA.instantiate()
		pd.chao_y = _chao_y
		pd.dano = 8 + int(18.0 * _dif)
		pd.raio_gatilho = 70.0
		pd.position = Vector2(x, cy - 78.0)
		par.add_child(pd)
	_checkpoint(x, cy)
	# volta a subir
	x += 165.0; cy = clampf(cy - 120.0, _chao_y - 300.0, _chao_y - 120.0)
	_plat(par, Vector2(x, cy), Vector2(90.0, 16.0))
	return Vector2(x, cy)


func _f_quebra(par: Node2D, x: float, y: float) -> Vector2:
	var n := 6 + int(_dif * 4.0)
	var cy := clampf(y, _chao_y - 300.0, _chao_y - 130.0)
	_plat(par, Vector2(x + 80.0, cy), Vector2(70.0, 16.0))
	x += 80.0
	for i in n:
		x += _rng.randf_range(140.0, 168.0)
		cy = clampf(cy - _rng.randf_range(-70.0, 60.0), _chao_y - 380.0, _chao_y - 110.0)
		var q := PLAT_QUEBRA.instantiate()
		q.tamanho = Vector2(92.0, 16.0)
		q.atraso = 0.72 - 0.3 * _dif
		q.position = Vector2(x, cy)
		par.add_child(q)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(90.0, 16.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


func _f_correntes(par: Node2D, x: float, y: float) -> Vector2:
	var n := 3 + int(_dif * 2.0)
	var cy := clampf(y, _chao_y - 260.0, _chao_y - 150.0)
	for i in n:
		x += _rng.randf_range(175.0, 205.0)
		var pc := PLAT_CORRENTE.instantiate()
		pc.modo = "pendulo" if i % 2 == 0 else "vertical"
		pc.amplitude = 26.0 if pc.modo == "pendulo" else _rng.randf_range(50.0, 80.0)
		pc.periodo = _rng.randf_range(2.4, 3.2)
		pc.fase = _rng.randf_range(0.0, 2.0)
		pc.comprimento = _rng.randf_range(110.0, 160.0)
		pc.largura = 110.0
		pc.position = Vector2(x, cy)
		par.add_child(pc)
		if i % 2 == 0:
			_checkpoint(x, cy)
	x += _rng.randf_range(175.0, 200.0)
	_plat(par, Vector2(x, cy), Vector2(90.0, 16.0))
	return Vector2(x, cy)


func _f_elevador(par: Node2D, x: float, y: float) -> Vector2:
	var cy := clampf(y, _chao_y - 160.0, _chao_y - 90.0)
	for i in 3:
		x += _rng.randf_range(180.0, 210.0)
		var tu := TUMULO.instantiate()
		tu.curso = Vector2(0.0, -_rng.randf_range(160.0, 260.0))
		tu.velocidade = _rng.randf_range(70.0, 100.0)
		tu.auto = true
		tu.largura = 120.0
		tu.position = Vector2(x, cy)
		par.add_child(tu)
		_plat(par, Vector2(x + 100.0, cy - _rng.randf_range(150.0, 240.0)), Vector2(90.0, 16.0))
	x += 150.0
	_plat(par, Vector2(x, cy), Vector2(90.0, 16.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


func _f_vento(par: Node2D, x: float, y: float) -> Vector2:
	x += 150.0
	var cy := clampf(y, _chao_y - 140.0, _chao_y - 80.0)
	_plat(par, Vector2(x, cy), Vector2(90.0, 16.0))
	var ca := CORRENTE_AR.instantiate()
	ca.position = Vector2(x + 150.0, cy - 240.0)
	ca.scale = Vector2(3.2, 5.0)
	par.add_child(ca)
	# plataformas empilhadas para lá da coluna
	for i in 4:
		_plat(par, Vector2(x + 110.0 + float(i % 2) * 150.0, cy - 100.0 - float(i) * 105.0), Vector2(96.0, 16.0))
	x += 340.0
	cy = clampf(cy - 300.0, _chao_y - 460.0, _chao_y - 160.0)
	_plat(par, Vector2(x, cy), Vector2(100.0, 16.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


func _f_gravidade(par: Node2D, x: float, y: float) -> Vector2:
	var n := 4 + int(_dif * 2.0)
	var cy := y
	var zg := ZONA_GRAV.instantiate()
	if zg.get_node_or_null("Col") == null:
		var cs := CollisionShape2D.new()
		cs.name = "Col"
		var r := RectangleShape2D.new()
		r.size = Vector2(n * 240.0, 560.0)
		cs.shape = r
		zg.add_child(cs)
	zg.escala = 0.4
	zg.position = Vector2(x + n * 120.0, _chao_y - 280.0)
	par.add_child(zg)
	for i in n:
		x += _rng.randf_range(200.0, 250.0)   # gaps maiores (grav lunar)
		cy = clampf(cy - _rng.randf_range(-180.0, 150.0), _chao_y - 470.0, _chao_y - 90.0)
		_plat(par, Vector2(x, cy), Vector2(74.0, 16.0))
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


func _f_guilhotinas(par: Node2D, x: float, y: float) -> Vector2:
	var n := 3 + int(_dif * 2.0)
	var cy := clampf(y, _chao_y - 280.0, _chao_y - 150.0)
	for i in n:
		x += _rng.randf_range(160.0, 186.0)
		_plat(par, Vector2(x, cy), Vector2(86.0, 16.0))
		var g := GUILHOTINA.instantiate()
		g.automatico = true
		g.periodo = _rng.randf_range(2.0, 2.8) - 0.4 * _dif
		g.atraso = 0.72 - 0.28 * _dif
		g.fase = 0.5 * float(i)
		g.altura_queda = 190.0
		g.dano = 10 + int(20.0 * _dif)
		g.position = Vector2(x + 90.0, cy - 210.0)
		par.add_child(g)
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


func _f_fogo(par: Node2D, x: float, y: float) -> Vector2:
	var n := 4 + int(_dif * 2.0)
	var cy := clampf(y, _chao_y - 260.0, _chao_y - 130.0)
	for i in n:
		x += _rng.randf_range(158.0, 184.0)
		_plat(par, Vector2(x, cy), Vector2(84.0, 16.0))
		var f := FOGO.instantiate()
		f.position = Vector2(x, cy + 4.0)
		f.intervalo = 1.9 - 0.4 * _dif
		f.dur_ativa = 1.0 + 0.4 * _dif
		f.fase = 0.5 * float(i)
		par.add_child(f)
		if i == n / 2:
			var tr := TORRETA.instantiate()
			tr.direcao = Vector2(-1.0, 0.0)
			tr.intervalo = 2.9 - 0.7 * _dif
			tr.dano = 6 + int(16.0 * _dif)
			tr.position = Vector2(x + 120.0, cy - 40.0)
			par.add_child(tr)
		if i % 2 == 0:
			_checkpoint(x, cy)
	return Vector2(x, cy)


func _f_impulso(par: Node2D, x: float, y: float) -> Vector2:
	var cy := clampf(y, _chao_y - 300.0, _chao_y - 150.0)
	_plat(par, Vector2(x + 90.0, cy), Vector2(90.0, 16.0))
	var imp := IMPULSOR.instantiate()
	imp.direcao = 1.0
	imp.vel_alvo = 440.0 + 60.0 * _dif
	imp.largura = 620.0
	imp.altura = 130.0
	imp.position = Vector2(x + 90.0 + 340.0, cy)
	par.add_child(imp)
	# ilhotas no meio da rajada
	_plat(par, Vector2(x + 90.0 + 260.0, cy), Vector2(60.0, 14.0))
	_plat(par, Vector2(x + 90.0 + 440.0, cy), Vector2(60.0, 14.0))
	x += 90.0 + 640.0
	_plat(par, Vector2(x, cy), Vector2(100.0, 16.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


## Fosso mais largo com DUAS rotas: plataformas suspensas OU um par de
## portais (entrada no caminho, saída em plataforma sólida do outro lado).
func _f_portal(par: Node2D, x: float, y: float) -> Vector2:
	var cy := clampf(y, _chao_y - 240.0, _chao_y - 140.0)
	_plat(par, Vector2(x + 70.0, cy), Vector2(80.0, 16.0))
	var idp := "jorn_%d" % _cont_i
	var pa := PORTAL.instantiate()
	pa.id = idp + "_a"
	pa.destino_id = idp + "_b"
	pa.position = Vector2(x + 70.0, cy - 28.0)
	par.add_child(pa)
	# rota de plataformas suspensas (Δx ~180)
	for i in 3:
		x += _rng.randf_range(168.0, 190.0)
		_plat(par, Vector2(x, cy - _rng.randf_range(-30.0, 40.0)), Vector2(70.0, 14.0))
		if _rng.randf() < 0.1 + 0.5 * _dif:
			_perigo_no_vao(par, x, cy)
	x += _rng.randf_range(168.0, 190.0)
	_plat(par, Vector2(x, cy), Vector2(100.0, 16.0))
	var pb := PORTAL.instantiate()
	pb.id = idp + "_b"
	pb.destino_id = idp + "_a"
	pb.so_saida = true
	pb.position = Vector2(x, cy - 28.0)
	par.add_child(pb)
	_checkpoint(x, cy)
	return Vector2(x, cy)


# =====================  CÂMARAS DE PUZZLE  ==============================
# (2 set 2026 -- o Paulo pediu "muito mais mecânicas diferentes, puzzles".)
# Regra de ouro de todas: a maneira de abrir caminho está SEMPRE do lado de
# cá do obstáculo e não se gasta -- a jornada não tem chão de rede, um
# puzzle que se pudesse "queimar" seria um softlock.


## PORTÃO E INTERRUPTOR: uma grade tranca o átrio e a alavanca que a abre
## está num poleiro do lado de cá. `so_liga` = uma vez aberta fica aberta.
## A ombreira por cima da grade fica a mais de um salto duplo do poleiro,
## senão saltava-se o portão por cima e não valia nada.
func _f_alavanca(par: Node2D, x: float, y: float) -> Vector2:
	if _chao_y - 96.0 - _teto_y < 460.0:
		return _f_descanso(par, x, y)          # sem pé-direito para a grade
	var cy: float = clampf(y, _teto_y + 400.0, _chao_y - 96.0)
	var alt: float = clampf(cy - _teto_y - 60.0, 300.0, 360.0)
	x += _rng.randf_range(150.0, 176.0)
	var id := "jorn_%d_%d" % [_idx, _cont_i]
	var topo := cy - 12.0
	_plat(par, Vector2(x + 160.0, cy), Vector2(350.0, 24.0), 46.0)
	_checkpoint(x + 40.0, cy, true)
	_plat(par, Vector2(x + 60.0, cy - 112.0), Vector2(120.0, 16.0))
	var al := ALAVANCA.instantiate()
	al.id = id
	al.so_liga = true
	al.position = Vector2(x + 60.0, cy - 142.0)
	par.add_child(al)   # ANTES da grade -- a porta liga-se às alavancas que
	                    # já estiverem na árvore quando ela entrar
	var pt := PORTA_TRANCADA.instantiate()
	pt.id = id
	pt.tamanho = Vector2(26.0, alt)
	pt.position = Vector2(x + 300.0, topo - alt * 0.5)
	par.add_child(pt)
	_plat(par, Vector2(x + 300.0, topo - alt - 34.0), Vector2(210.0, 30.0))
	_coluna_fundo(par, x + 170.0)
	if _dif > 0.4:
		_inimigo_em(par, Vector2(x + 210.0, cy - 30.0))
	x += 340.0 + _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


## ACENDER A VELA: as `PlataformaLuz` só são sólidas enquanto houver uma
## `Vela` acesa dentro do raio. A câmara ensina primeiro (vela acesa +
## plataforma sólida) e só depois pede (vela APAGADA num poleiro sólido,
## ponte apagada por cima do líquido; tocar-lhe acende-a e a ponte aparece).
## O raio de cada plataforma é medido para a vela do puzzle -- a vela do
## exemplo fica longe de mais para as manter acesas de borla.
func _f_velas(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 150.0, _chao_y - 96.0)
	x += _rng.randf_range(150.0, 176.0)
	# --- exemplo: vela acesa, plataforma de luz sólida ---
	_plat(par, Vector2(x, cy), Vector2(150.0, 18.0))
	_checkpoint(x, cy, true)
	_vela_em(par, Vector2(x + 46.0, cy - 54.0), true)
	x += _rng.randf_range(152.0, 172.0)
	_plat_luz(par, Vector2(x, cy - 24.0), Vector2(120.0, 16.0), 250.0)
	# --- o puzzle: vela apagada + ponte apagada ---
	x += _rng.randf_range(152.0, 172.0)
	_plat(par, Vector2(x, cy), Vector2(160.0, 18.0))
	var vx := x + 52.0
	_vela_em(par, Vector2(vx, cy - 54.0), false)
	var n := 3 + int(_dif * 2.0)
	for i in n:
		x += _rng.randf_range(150.0, 168.0)
		var py := cy - 26.0 - 14.0 * float(i % 2)
		_plat_luz(par, Vector2(x, py), Vector2(104.0, 16.0), absf(x - vx) + 60.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(140.0, 18.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


## BADALADA: a ponte por cima do vão está FANTASMA (atravessa-se, não se
## pisa). O sino fica na plataforma de entrada, ao alcance do golpe ou do
## tiro -- badalada, a ponte fica sólida (e os bichos gelam). Pode tocar-se
## as vezes que forem precisas.
func _f_sinos(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 200.0, _chao_y - 96.0)
	x += _rng.randf_range(150.0, 176.0)
	var grupo := "sino_jorn_%d_%d" % [_idx, _cont_i]
	_plat(par, Vector2(x, cy), Vector2(180.0, 20.0), 40.0)
	_checkpoint(x, cy, true)
	var si := SINO.instantiate()
	si.alterna_grupo = grupo
	si.congelar_inimigos = 2.6
	si.position = Vector2(x + 44.0, cy - 60.0)
	par.add_child(si)
	var n := 3 + int(_dif * 3.0)
	for i in n:
		x += _rng.randf_range(150.0, 170.0)
		var py := cy - 30.0 - 16.0 * float(i % 2)
		_plat_fantasma(par, Vector2(x, py), Vector2(104.0, 16.0), grupo)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(140.0, 18.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


## PRENSAS: um salão comprido varrido por paredes que deslizam de um lado ao
## outro, desfasadas. Não esmagam contra tecto nenhum (não há tecto) -- ou se
## espera o buraco, ou se salta a parede; quem se deixa empurrar cai ao
## líquido. Espinhos no chão a meio para o tempo não ser de borla.
func _f_prensa(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 240.0, _chao_y - 96.0)
	x += _rng.randf_range(150.0, 176.0)
	var larg: float = 480.0 + 160.0 * _dif
	_plat(par, Vector2(x + larg * 0.5, cy), Vector2(larg, 24.0), 46.0)
	_checkpoint(x + 44.0, cy, true)
	var n := 2 + int(_dif * 2.4)
	for i in n:
		var px := x + larg * ((float(i) + 0.7) / float(n + 1))
		var pm := PAREDE_MOVEL.instantiate()
		pm.tamanho = Vector2(26.0, 160.0)
		pm.curso = Vector2(larg / float(n + 1) * 0.9, 0.0)
		pm.periodo = 3.4 - 1.1 * _dif
		pm.fase = fmod(0.37 * float(i) + 0.2, 1.0)
		pm.position = Vector2(px, cy - 92.0)
		par.add_child(pm)
		if i > 0 and _dif > 0.5:
			var esp := ESPINHOS.instantiate()
			esp.largura = 2
			esp.position = Vector2(px - 40.0, cy - 12.0)
			par.add_child(esp)
	_coluna_fundo(par, x + larg * 0.5)
	x += larg + _rng.randf_range(148.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


## ESPELHOS: o corredor está tapado por espelhos altos. Cada um parte-se com
## um golpe (ou um tiro) e larga um reflexo -- avança-se a partir vidro e a
## despachar sombras. Sempre partíveis, nunca dependem de habilidade.
func _f_espelhos(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 200.0, _chao_y - 96.0)
	x += _rng.randf_range(150.0, 176.0)
	var n := 2 + int(_dif * 2.0)
	var larg: float = 200.0 + 150.0 * float(n)
	_plat(par, Vector2(x + larg * 0.5, cy), Vector2(larg, 24.0), 46.0)
	_checkpoint(x + 44.0, cy, true)
	for i in n:
		var es := ESPELHO.instantiate()
		es.vida_reflexo = 22 + int(30.0 * _dif)
		es.dano_reflexo = 10 + int(12.0 * _dif)
		es.position = Vector2(x + 150.0 + 150.0 * float(i), cy - 102.0)
		par.add_child(es)
	_coluna_fundo(par, x + larg - 40.0)
	x += larg + _rng.randf_range(148.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


## PAREDE RACHADA: a espinha passa a direito por baixo; encostada ao fim do
## salão há uma alcova selada por uma `ParedeFragil` com essência lá dentro.
## Só se abre com a habilidade "partir_paredes" (nível 4) -- e por isso NUNCA
## está no caminho, é só recompensa para quem repara e já a tem.
func _f_segredo(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 240.0, _chao_y - 96.0)
	x += _rng.randf_range(150.0, 176.0)
	var larg := 400.0
	_plat(par, Vector2(x + larg * 0.5, cy), Vector2(larg, 24.0), 46.0)
	_checkpoint(x + 44.0, cy, true)
	# alcova: tecto + parede do fundo, tapada à entrada pela parede rachada
	var ax := x + larg - 110.0
	_plat(par, Vector2(ax + 30.0, cy - 190.0), Vector2(210.0, 20.0))
	_plat(par, Vector2(ax + 130.0, cy - 96.0), Vector2(24.0, 168.0))
	var pf := PAREDE_FRAGIL.instantiate()
	pf.position = Vector2(ax - 60.0, cy - 92.0)
	par.add_child(pf)
	var es := ESSENCIA.instantiate()
	es.valor = 20 + int(38.0 * _dif)
	es.espalhar = false
	es.position = Vector2(ax + 40.0, cy - 46.0)
	par.add_child(es)
	if _dif > 0.35:
		_inimigo_em(par, Vector2(x + 120.0, cy - 30.0))
	x += larg + _rng.randf_range(148.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy)
	return Vector2(x, cy)


## --- peças das câmaras de puzzle ---------------------------------------

func _vela_em(par: Node2D, pos: Vector2, acesa: bool) -> void:
	var v := VELA.instantiate()
	v.acesa = acesa
	v.position = pos
	par.add_child(v)


## Plataforma que só é sólida com uma vela acesa a menos de `raio`.
func _plat_luz(par: Node2D, pos: Vector2, tam: Vector2, raio: float) -> void:
	var p := PLAT_LUZ.instantiate()
	p.raio_luz = raio
	p.position = pos
	p.tamanho = tam
	par.add_child(p)


## Plataforma normal que ENTRA fantasma (atravessa-se) e fica sólida à
## primeira badalada do sino do mesmo `grupo` -- ver `SinoTorre._alternar`.
func _plat_fantasma(par: Node2D, pos: Vector2, tam: Vector2, grupo: String) -> void:
	var p := PLAT.instantiate()
	p.position = pos
	p.tamanho = tam
	par.add_child(p)
	p.add_to_group(grupo)
	var col := p.get_node_or_null("Col") as CollisionShape2D
	if col:
		col.set_deferred("disabled", true)
	var vis := p.get_node_or_null("Visual") as CanvasItem
	if vis:
		vis.modulate.a = 0.16


# ── ESTREIAS NOVAS (5 set 2026) ──────────────────────────────────────────
#
# Dezasseis camaras construidas so' com pecas que ja' existiam. Cada uma e'
# a ESTREIA de um nivel (ver `MECANICA_DO_NIVEL`): no nivel dela aparece
# sozinha e manda no espaco. Nenhuma precisou de arte nova.
#
# Regra que todas seguem, como as antigas: recebem (x, y) da espinha,
# constroem para a DIREITA e devolvem onde a espinha continua. Nunca deixam
# um vao maior que um salto+duplo -- ver `SUBIDA_MAX` e `tools/verifica_alcance.gd`.


## LAVA QUE SOBE: uma subida curta com o liquido mortal a trepar atras. Nao
## se pode parar. O liquido e' o mesmo `AguaVenenosa` do fundo do nivel, so'
## que este sobe em ciclo -- e' a diferenca entre "ha' lava ali em baixo" e
## "a lava vem ai'".
func _f_lava_sobe(par: Node2D, x: float, y: float) -> Vector2:
	var n := 4 + int(_dif * 2.0)
	var base_y: float = clampf(y, _teto_y + 320.0, _chao_y - 120.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, base_y), Vector2(120.0, 18.0))
	var largura := float(n) * 168.0 + 260.0

	var lava := AGUA.instantiate()
	lava.largura = largura
	lava.altura = 300.0
	var liq: Array = LIQUIDO.get(_regiao, LIQUIDO[0])
	lava.cor = liq[0]
	lava.brasas = true
	lava.position = Vector2(x + largura * 0.5 - 100.0, base_y + 280.0)
	par.add_child(lava)
	# sobe ate' tapar a fiada de baixo e volta a descer -- em ciclo, para
	# quem chegar atrasado apanhar a mare' cheia na mesma
	var subida: float = 210.0 + 60.0 * _dif
	var tl := create_tween().set_loops()
	tl.tween_interval(1.2)
	tl.tween_property(lava, "position:y", lava.position.y - subida, 2.6) \
		.set_trans(Tween.TRANS_SINE)
	tl.tween_interval(0.8)
	tl.tween_property(lava, "position:y", lava.position.y, 2.0) \
		.set_trans(Tween.TRANS_SINE)

	var cy := base_y
	for _i in n:
		x += _rng.randf_range(150.0, 174.0)
		cy = maxf(_teto_y + 60.0, cy - _rng.randf_range(58.0, SUBIDA_MAX))
		_plat(par, Vector2(x, cy), Vector2(96.0, 16.0))
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## MARE: o liquido sobe e desce devagar sobre uma fiada BAIXA de
## plataformas. Ha' sempre caminho -- o que muda e' quando. Ensina a
## esperar, que e' a coisa que a jornada nunca pedia.
func _f_mare(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 240.0, _chao_y - 170.0)
	var n := 4 + int(_dif * 2.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(120.0, 18.0))
	var x0 := x
	var by := cy + 96.0
	for _i in n:
		x += _rng.randf_range(140.0, 168.0)
		_plat(par, Vector2(x, by), Vector2(92.0, 15.0))
	var largura := x - x0 + 300.0

	var mar := AGUA.instantiate()
	mar.largura = largura
	mar.altura = 260.0
	var liq: Array = LIQUIDO.get(_regiao, LIQUIDO[0])
	mar.cor = liq[0]
	mar.brasas = liq[1]
	mar.position = Vector2((x0 + x) * 0.5, by + 190.0)
	par.add_child(mar)
	var tm := create_tween().set_loops()
	tm.tween_property(mar, "position:y", by - 40.0, 3.2).set_trans(Tween.TRANS_SINE)
	tm.tween_interval(0.6)
	tm.tween_property(mar, "position:y", mar.position.y, 3.2).set_trans(Tween.TRANS_SINE)

	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## ESPECTRAL: as plataformas so' sao solidas uns segundos depois de pisadas.
## Usa a `PlataformaEspectral`, que estava no repo sem nenhuma camara a
## chamar. Nao se pode voltar atras -- e' a travessia so' para a frente.
func _f_espectral(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 150.0, _chao_y - 150.0)
	var n := 4 + int(_dif * 3.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(120.0, 18.0))
	for _i in n:
		x += _rng.randf_range(142.0, 166.0)
		cy = clampf(cy + _rng.randf_range(-52.0, 52.0), _teto_y + 90.0, _chao_y - 130.0)
		var pe := PLAT_ESPECTRAL.instantiate()
		pe.segundos_solida = lerpf(3.6, 1.9, _dif)
		pe.aviso = 0.7
		pe.position = Vector2(x, cy)
		par.add_child(pe)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## VITRAL: uma parede de vidro colorido corta o caminho e a ponte do outro
## lado esta' FANTASMA. Partir o vitral deixa entrar a luz e a ponte fica
## solida. E' o unico sitio da jornada onde ATACAR e' a forma de avancar.
func _f_vitral(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 200.0, _chao_y - 160.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(150.0, 18.0))
	var grupo := "vitral_luz_%d" % _camaras

	var vt := VITRAL.instantiate()
	vt.grupo_luz = grupo
	vt.cor_luz = _cor_luz_regiao()
	vt.position = Vector2(x + 118.0, cy - 70.0)
	par.add_child(vt)

	# a ponte que a luz acende: entra fantasma, fica solida ao partir o vidro
	var bx := x
	for _i in 3:
		bx += _rng.randf_range(146.0, 168.0)
		_plat_fantasma(par, Vector2(bx, cy - 20.0), Vector2(96.0, 16.0), grupo)
	# ...e um caminho de recurso por baixo, para o vitral nunca ser um muro:
	# quem nao perceber que ha' que lhe bater passa por baixo, com espinhos
	var lx := x
	for _i in 3:
		lx += _rng.randf_range(140.0, 162.0)
		_plat(par, Vector2(lx, cy + 92.0), Vector2(90.0, 14.0))
		var sp := ESPINHOS.instantiate()
		sp.largura = 4
		sp.position = Vector2(lx, cy + 92.0)
		par.add_child(sp)

	x = maxf(bx, lx) + _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## PARA-RAIOS: um corredor com descargas em coluna e uma haste de metal ao
## meio. Bater na haste ARMA-a e a descarga seguinte vai para la' em vez de
## ir para a Koliani. Usa o `ParaRaios`, que so' o chefe da tempestade usava.
func _f_para_raios(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 200.0, _chao_y - 150.0)
	var n := 3 + int(_dif * 2.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(140.0, 18.0))
	for i in n:
		x += _rng.randf_range(152.0, 176.0)
		_plat(par, Vector2(x, cy), Vector2(104.0, 16.0))
		var pr := PARA_RAIOS.instantiate()
		pr.dur_armado = lerpf(4.0, 2.4, _dif)
		pr.position = Vector2(x, cy - 8.0)
		par.add_child(pr)
		var rt := RAIO.instantiate()
		if "fase" in rt:
			rt.fase = float(i) * 0.9
		rt.position = Vector2(x + 74.0, cy - 150.0)
		par.add_child(rt)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## BOMBAS: chuva de fogo. Torretas viradas para BAIXO no tecto cospem bolas
## de fogo sobre a travessia -- o perigo vem de cima e anda, ao contrario
## dos espinhos, que estao sempre no mesmo sitio.
func _f_bombas(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 260.0, _chao_y - 150.0)
	var n := 4 + int(_dif * 2.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(120.0, 18.0))
	for i in n:
		x += _rng.randf_range(146.0, 172.0)
		_plat(par, Vector2(x, cy), Vector2(100.0, 16.0))
		if i % 2 == 0:
			var t := TORRETA.instantiate()
			t.direcao = Vector2(0.0, 1.0)
			t.intervalo = lerpf(3.0, 1.7, _dif)
			t.telegrafo = 0.6
			t.fase = float(i) * 0.7
			t.vel_bola = 190.0
			t.position = Vector2(x + 40.0, cy - 210.0)
			par.add_child(t)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## QUEDA: o nivel e' a descida. Uma coluna aberta com beirais alternados e
## laminas nos vaos -- desce-se de propria vontade e o perigo esta' no
## caminho, nao no fundo.
func _f_queda(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 120.0, _teto_y + 260.0)
	var n := 4 + int(_dif * 2.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(140.0, 18.0))
	var lado := 1.0
	for i in n:
		cy = minf(_chao_y - 130.0, cy + _rng.randf_range(120.0, 165.0))
		x += 74.0 * lado + _rng.randf_range(30.0, 60.0)
		_plat(par, Vector2(x, cy), Vector2(112.0, 16.0))
		if i % 2 == 1:
			var pd := PENDULO.instantiate()
			pd.position = Vector2(x + 78.0, cy - 96.0)
			par.add_child(pd)
		lado = -lado
	x += _rng.randf_range(160.0, 190.0)
	_plat(par, Vector2(x, cy), Vector2(150.0, 20.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## TAPETE: um troco comprido com uma CORRENTEZA a empurrar para tras
## (`CorrenteLateral`, actor novo). Anda-se contra a corrente -- o mesmo
## salto deixa de chegar onde chegava, e parar e' recuar.
func _f_tapete(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 150.0, _chao_y - 140.0)
	var n := 3 + int(_dif * 2.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(120.0, 18.0))
	var x0 := x
	for _i in n:
		x += 168.0
		_plat(par, Vector2(x, cy), Vector2(160.0, 16.0))
	# a correnteza por cima do chao todo -- empurra CONTRA a marcha
	var cl := CorrenteLateral.new()
	cl.tamanho = Vector2(x - x0 + 120.0, 150.0)
	cl.empurrao = -lerpf(520.0, 900.0, _dif)
	cl.position = Vector2((x0 + x) * 0.5, cy - 70.0)
	par.add_child(cl)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## ORBITA: ilhas que andam em CIRCULO. A `PlataformaFlutuante` ja' sabia
## balancar (y) e derivar (x); com os dois ao mesmo periodo e um quarto de
## fase de diferenca, anda em roda. Espera-se pela ilha certa.
func _f_orbita(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 220.0, _chao_y - 160.0)
	var n := 3 + int(_dif * 1.5)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(120.0, 18.0))
	for i in n:
		x += _rng.randf_range(180.0, 210.0)
		var pf := PLAT_FLUT.instantiate()
		pf.largura = 104.0
		pf.balanco = 62.0
		pf.deriva = 62.0
		pf.periodo = 3.4
		pf.periodo_deriva = 3.4          # mesmo periodo -> circulo
		pf.fase = float(i) * 0.6
		pf.position = Vector2(x, cy)
		par.add_child(pf)
	x += _rng.randf_range(180.0, 210.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## AREIA: um poco onde se PESA mais -- a `ZonaGravidade` ao contrario (1.5
## em vez de 0.42). Cai-se depressa e sai-se a custo, com espinhos no fundo
## a dizer que nao se pode ficar.
func _f_areia(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 200.0, _chao_y - 220.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	var largura := 300.0 + 90.0 * _dif
	var fundo := cy + 150.0
	var poco_x0 := x + 80.0
	var poco_x1 := poco_x0 + largura

	var zg := ZONA_GRAV.instantiate()
	zg.escala = 1.5                      # o tecto do `definir_grav_escala`
	zg.position = Vector2((poco_x0 + poco_x1) * 0.5, cy + 70.0)
	_esticar_zona(zg, Vector2(largura, 300.0))
	par.add_child(zg)

	# fundo do poco: pisavel, mas com espinhos -- da' para respirar um
	# instante e nao da' para ficar
	var fx := poco_x0 + 30.0
	while fx < poco_x1 - 60.0:
		_plat(par, Vector2(fx, fundo), Vector2(96.0, 14.0))
		var sp := ESPINHOS.instantiate()
		sp.largura = 5
		sp.position = Vector2(fx, fundo)
		par.add_child(sp)
		fx += 150.0

	# escada de saida JA' FORA da bolsa (a partir de `poco_x1`): a 1.5 de
	# gravidade um salto sozinho sobe ~53 px, e nao se pode contar com o
	# salto duplo para sair de um sitio onde e' obrigatorio sair.
	var sy := fundo
	var sx: float = maxf(fx, poco_x1)
	while sy > cy:
		sx += _rng.randf_range(132.0, 152.0)
		sy = maxf(cy, sy - 60.0)
		_plat(par, Vector2(sx, sy), Vector2(100.0, 15.0))
	x = sx + _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## GRAVIDADE BAIXA: uma bolsa onde o salto muda de escala, com vaos que so'
## se atravessam la' dentro. E' a mesma `ZonaGravidade` do Observatorio, mas
## aqui e' ela que DESENHA o espaco em vez de ser um enfeite.
func _f_grav_baixa(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 260.0, _chao_y - 150.0)
	var n := 3 + int(_dif * 2.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(120.0, 18.0))
	var x0 := x
	var largura := float(n) * 250.0 + 200.0

	var zg := ZONA_GRAV.instantiate()
	zg.escala = 0.25
	zg.position = Vector2(x0 + largura * 0.5, cy - 40.0)
	_esticar_zona(zg, Vector2(largura, 520.0))
	par.add_child(zg)

	# vaos que so' se atravessam LA' DENTRO. 210 px e' o tecto: a 0.25 de
	# gravidade o salto sobe ~315 px e paira o triplo do tempo, mas o vao
	# tem de continuar a caber caso a bolsa falhe -- 210 ainda se faz com
	# salto duplo a gravidade normal.
	for _i in n:
		x += _rng.randf_range(190.0, 210.0)
		cy = clampf(cy - _rng.randf_range(20.0, 90.0), _teto_y + 80.0, _chao_y - 150.0)
		_plat(par, Vector2(x, cy), Vector2(94.0, 16.0))
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## PLACA DE PRESSAO: uma alavanca no chao, no caminho, que FECHA uma grade
## a' frente (`invertida`). Ensina que nem tudo o que se pode carregar se
## deve carregar -- e ha' sempre a volta por cima.
func _f_placa(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 220.0, _chao_y - 150.0)
	var id := "placa_%d" % _camaras
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(150.0, 18.0))

	x += _rng.randf_range(150.0, 172.0)
	_plat(par, Vector2(x, cy), Vector2(120.0, 18.0))
	var al := ALAVANCA.instantiate()
	al.id = id
	al.so_liga = true
	al.position = Vector2(x, cy - 14.0)
	par.add_child(al)

	var gx := x + _rng.randf_range(300.0, 350.0)
	var pt := PORTA_TRANCADA.instantiate()
	pt.id = id
	pt.invertida = true                  # carregar FECHA
	pt.tamanho = Vector2(24.0, 150.0)
	pt.position = Vector2(gx, cy - 76.0)
	par.add_child(pt)
	_plat(par, Vector2(gx, cy), Vector2(120.0, 18.0))

	# a volta por cima: quem carregou na placa passa por aqui
	var hy: float = maxf(_teto_y + 60.0, cy - 150.0)
	var hx := x
	for _i in 3:
		hx += _rng.randf_range(140.0, 164.0)
		_plat(par, Vector2(hx, hy), Vector2(92.0, 15.0))

	x = maxf(gx, hx) + _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(130.0, 18.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## CIRCUITO: tres alavancas, uma grade que so' abre com as TRES. Sao
## desvios curtos a partir da linha principal -- procura-se, nao se decora.
func _f_circuito(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 240.0, _chao_y - 150.0)
	var id := "circuito_%d" % _camaras
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(140.0, 18.0))

	for i in 3:
		x += _rng.randf_range(160.0, 190.0)
		var ay := cy - float(i % 2) * 120.0
		_plat(par, Vector2(x, ay), Vector2(114.0, 16.0))
		if ay < cy:
			_plat(par, Vector2(x - 78.0, cy), Vector2(90.0, 15.0))   # degrau
		var al := ALAVANCA.instantiate()
		al.id = id
		al.so_liga = true
		al.position = Vector2(x, ay - 14.0)
		par.add_child(al)

	var gx := x + _rng.randf_range(190.0, 230.0)
	var pt := PORTA_TRANCADA.instantiate()
	pt.id = id
	pt.exige_todas = true
	pt.tamanho = Vector2(24.0, 150.0)
	pt.position = Vector2(gx, cy - 76.0)
	par.add_child(pt)
	_plat(par, Vector2(gx, cy), Vector2(130.0, 18.0))
	_checkpoint(gx, cy, true)
	return Vector2(gx, cy)


## ANEL: uma arena redonda sobre liquido, sem cantos onde encostar. Luta-se
## a andar a' roda -- o oposto do corredor, onde se luta de costas para a
## parede.
func _f_anel(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 260.0, _chao_y - 180.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(120.0, 18.0))
	var cx := x + 330.0
	var raio := 250.0

	var liq: Array = LIQUIDO.get(_regiao, LIQUIDO[0])
	var lava := AGUA.instantiate()
	lava.largura = raio * 2.4
	lava.altura = 240.0
	lava.cor = liq[0]
	lava.brasas = true
	lava.position = Vector2(cx, cy + 190.0)
	par.add_child(lava)

	# oito ilhas em roda: da' para dar a volta toda sem tocar no liquido
	var n := 8
	for i in n:
		var a := TAU * float(i) / float(n)
		var px := cx + cos(a) * raio
		var py := cy + sin(a) * raio * 0.36
		_plat(par, Vector2(px, py), Vector2(112.0, 16.0))
	_plat(par, Vector2(cx, cy - 20.0), Vector2(120.0, 16.0))    # ilha do meio
	for i in 2 + int(_dif * 2.0):
		var a2 := TAU * float(i) / 3.0
		_inimigo_em(par, Vector2(cx + cos(a2) * raio * 0.7, cy - 40.0), i == 0)

	x = cx + raio + _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(140.0, 18.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## HORDA: a saida esta' trancada e a alavanca que a abre esta' do outro lado
## da sala. Nao ha' contador -- ha' um caminho, e ele esta' cheio.
func _f_horda(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 220.0, _chao_y - 150.0)
	var id := "horda_%d" % _camaras
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(150.0, 18.0))
	var x0 := x

	var largura := 620.0 + 160.0 * _dif
	_plat(par, Vector2(x + largura * 0.5, cy + 34.0), Vector2(largura, 24.0), 120.0)
	for i in 4 + int(_dif * 4.0):
		_inimigo_em(par, Vector2(x0 + 140.0 + float(i) * (largura / 6.0), cy - 40.0),
			i % 4 == 0)
	# duas varandas, para nao ser so' um chao raso
	for k in 2:
		_plat(par, Vector2(x0 + 190.0 + float(k) * 300.0, cy - 140.0), Vector2(120.0, 15.0))

	var ax := x0 + largura - 60.0
	var al := ALAVANCA.instantiate()
	al.id = id
	al.so_liga = true
	al.position = Vector2(ax, cy + 20.0)
	par.add_child(al)

	var gx := x0 + largura + 90.0
	var pt := PORTA_TRANCADA.instantiate()
	pt.id = id
	pt.tamanho = Vector2(24.0, 150.0)
	pt.position = Vector2(gx, cy - 42.0)
	par.add_child(pt)

	x = gx + _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(140.0, 18.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## CHUVA: um beiral comprido com o tecto a desfazer-se. As pedras armam-se
## a' passagem e caem a' frente -- corre-se a ler o tecto, nao o chao.
func _f_chuva(par: Node2D, x: float, y: float) -> Vector2:
	var cy: float = clampf(y, _teto_y + 240.0, _chao_y - 140.0)
	var n := 5 + int(_dif * 4.0)
	x += _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(140.0, 18.0))
	var x0 := x
	var largura := float(n) * 132.0 + 200.0
	_plat(par, Vector2(x0 + largura * 0.5, cy + 30.0), Vector2(largura, 22.0), 110.0)
	for i in n:
		var px := x0 + 120.0 + float(i) * 132.0 + _rng.randf_range(-24.0, 24.0)
		var pq := PEDRA.instantiate()
		pq.chao_y = cy + 18.0
		pq.raio_gatilho = 150.0
		pq.position = Vector2(px, cy - _rng.randf_range(210.0, 260.0))
		par.add_child(pq)
	x = x0 + largura + _rng.randf_range(150.0, 176.0)
	_plat(par, Vector2(x, cy), Vector2(140.0, 18.0))
	_checkpoint(x, cy, true)
	return Vector2(x, cy)


## Estica uma `ZonaGravidade` para cobrir `tam` (e o Fundo com ela).
##
## ⚠ O no' de colisao da cena chama-se **CollisionShape2D**, nao "Col" -- a
## primeira versao destas camaras procurava "Col", nunca redimensionava, e a
## bolsa ficava com os 300x300 de omissao. Na camara `grav_baixa` isso era
## um SOFTLOCK: os vaos de 230 px so' se atravessam com a gravidade baixa,
## e fora da bolsa nao ha' salto que la' chegue.
func _esticar_zona(zg: Node2D, tam: Vector2) -> void:
	var col := zg.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		var forma := RectangleShape2D.new()
		forma.size = tam
		col.shape = forma
	var fundo := zg.get_node_or_null("Fundo") as Control
	if fundo:
		fundo.size = tam
		fundo.position = -tam * 0.5
	var contorno := zg.get_node_or_null("Contorno") as Line2D
	if contorno:
		var h := tam * 0.5
		contorno.points = PackedVector2Array([
			Vector2(-h.x, -h.y), Vector2(h.x, -h.y),
			Vector2(h.x, h.y), Vector2(-h.x, h.y), Vector2(-h.x, -h.y)])


## Cor de luz da regiao atual -- o vitral tinge-se com ela em vez de ser
## sempre roxo.
func _cor_luz_regiao() -> Color:
	var liq: Array = LIQUIDO.get(_regiao, LIQUIDO[0])
	var c: Color = liq[0]
	return Color(c.r * 0.5 + 0.5, c.g * 0.4 + 0.4, c.b * 0.5 + 0.5)
