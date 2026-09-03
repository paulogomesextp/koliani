class_name CatalogoCampanha
extends RefCounted
## DADOS PUROS da campanha para os ecrãs de escolha de nível (mapa do mundo
## e barra de dev): a chave i18n do nome do nível e do nome do chefe de cada
## índice de `EstadoJogo.NIVEIS`. Sem lógica de jogo e sem tocar em
## autoloads -- é só uma tabela de chaves, testável com `--script`.
##
## A ordem TEM de acompanhar `EstadoJogo.NIVEIS`. Ao acrescentar/remover um
## nível, mexer aqui e nos 6 `assets/i18n/*.json` (chaves `level.n##` e
## `boss.<slug>`). A resolução para texto (com recurso ao nome do ficheiro)
## vive no `seletor_niveis.gd`, que corre sempre dentro de uma cena.

## Chave i18n do chefe de cada nível (índice = índice em EstadoJogo.NIVEIS).
const CHEFE_KEY: Array[String] = [
	"boss.ghorak",               # 00 Floresta Putrefacta
	"boss.morvanna",             # 01 Pântano dos Sussurros
	"boss.rainha_aracnidea",     # 02 Ninho da Viúva Negra
	"boss.entrevane",            # 03 A Árvore que Chora
	"boss.coracao_putrefacto",   # 04 Coração da Floresta
	"boss.carcereiro",           # 05 Prisão dos Condenados
	"boss.ignivar",              # 06 Fornalha dos Pecadores
	"boss.dama_guilhotina",      # 07 Corredor das Execuções
	"boss.irmaos_condenados",    # 08 Ala dos Mortos
	"boss.primeiro_prisioneiro", # 09 A Cela Zero
	"boss.sino_vivo",            # 10 Torre dos Sinos
	"boss.aerion",               # 11 Torre dos Ventos
	"boss.voltaris",             # 12 Torre da Tempestade
	"boss.sacerdotisa_lunar",    # 13 Observatório Lunar
	"boss.vyrak",                # 14 O Pico Esquecido
	"boss.rei_ossario",          # 15 Cemitério dos Reis
	"boss.colosso_osseo",        # 16 Galeria dos Ossos
	"boss.freira_negra",         # 17 Cripta das Mil Velas
	"boss.naga_zeraph",          # 18 Templo da Serpente
	"boss.olho_do_abismo",       # 19 O Abismo
	"boss.prefeito_sem_rosto",   # 20 Vila dos Sem-Rosto
	"boss.acougueiro_real",      # 21 Mercado da Carne
	"boss.maquinista_infernal",  # 22 Trem dos Mortos
	"boss.bispo_purpura",        # 23 Catedral da Corrupção
	"boss.noiva_do_eclipse",     # 24 Praça do Eclipse
	"boss.capitao_negro",        # 25 Portões de Zeriko
	"boss.koliani_sombria",      # 26 Salão dos Espelhos
	"boss.rei_devorador",        # 27 Banquete dos Imortais
	"boss.arauto_de_zeriko",     # 28 Torre do Coração Negro
	"boss.zeriko",               # 29 O Trono de Zeriko
	# --- Regiao VII  Terras Queimadas ---
	"boss.vulkar",           # 30 Estrada das Cinzas
	"boss.magmora",          # 31 Rio de Magma
	"boss.mestre_da_forja",  # 32 A Forja dos Demonios
	"boss.dragorak",         # 33 Vulcao do Rei Morto
	"boss.estrela_caida",    # 34 O Ceu em Chamas
]


## Chave i18n do nome do nível `indice` (`level.n00`..`level.n99`).
static func chave_nivel(indice: int) -> String:
	return "level.n%02d" % indice


## Chave i18n do nome do chefe do nível `indice`, ou "" fora de alcance.
static func chave_chefe(indice: int) -> String:
	if indice < 0 or indice >= CHEFE_KEY.size():
		return ""
	return CHEFE_KEY[indice]
