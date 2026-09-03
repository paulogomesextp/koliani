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
##
## Desde 3 set 2026 nem todo o nível tem chefe (pedido do Paulo). Os que
## acabam num GUARDIÃO -- um elite que sela a porta -- levam uma chave
## `guard.*` em vez de `boss.*`; o carrossel usa isso para dizer
## "Guardião: X" em vez de "Chefe: X".
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
	"guard.imp_cinzas",           # 30 Estrada das Cinzas
	"guard.chort_magma",          # 31 Rio de Magma
	"guard.ferreiro",  # 32 A Forja dos Demonios
	"guard.besta_vulcao",         # 33 Vulcao do Rei Morto
	"boss.estrela_caida",    # 34 O Ceu em Chamas
	# --- Regiao VIII  Mar dos Mortos ---
	# Como na VII: um chefe por regiao (o ultimo) e guardioes nos outros
	# quatro. Os nomes grandes do plano (Capitao Afogado, Leviata, Rainha
	# Nereia, o Devorador) ficam por gastar para quando estes niveis
	# ganharem chefe a serio -- ver docs/plano_niveis_31_100.md.
	"guard.afogado",         # 35 Porto dos Afogados
	"guard.gosma_salgada",   # 36 Cidade Submersa
	"guard.estatua_viva",    # 37 Palacio das Sereias Mortas
	"guard.lodo_abissal",    # 38 Ossario das Baleias
	"boss.mae_do_abismo",    # 39 Abismo Oceanico
	# --- Regiao IX  Reino do Gelo ---
	"guard.cao_de_gelo",        # 40 Floresta Congelada
	"guard.abutre_ventania",    # 41 Montanha dos Ventos
	"guard.besouro_cristal",    # 42 Cavernas Cristalinas
	"guard.sentinela_gelada",   # 43 Castelo Congelado
	"boss.ymiria",              # 44 Coracao do Inverno
	# --- Regiao X  Deserto dos Esquecidos ---
	"guard.lagarto_dunas",      # 45 Mar de Areia
	"guard.colosso_arenito",    # 46 Templo Sem Nome
	"guard.escorpiao_areia",    # 47 Vale dos Escorpioes
	"guard.mumia",              # 48 Cidade Enterrada
	"boss.deus_esquecido",      # 49 Piramide Negra
	# --- Regiao XI  Jardins do Rei ---
	"guard.roseira_viva",       # 50 Jardim das Rosas Negras
	"guard.jardineiro_perdido", # 51 Labirinto Verde
	"guard.alma_errante",       # 52 Jardim das Almas
	"guard.trepadeira",         # 53 Estufa Maldita
	"boss.rei_botanico",        # 54 Arvore do Rei
	# --- Regiao XII  Cidade das Maquinas ---
	"guard.automato",           # 55 Distrito das Engrenagens
	"guard.foguista",           # 56 Linha 13
	"guard.homunculo",          # 57 Fabrica dos Homunculos
	"guard.bobina_viva",        # 58 Torre Electrica
	"boss.maquina_rei",         # 59 Coracao da Maquina
	# --- Regiao XIII  Ceu Partido ---
	"guard.guarda_nuvens",      # 60 Ilhas Flutuantes
	"guard.servo_do_trovao",    # 61 Templo do Trovao
	"guard.anjo_corrompido",    # 62 Cidade dos Anjos Mortos
	"guard.olho_lunar",         # 63 Lua Quebrada
	"boss.astronomo",           # 64 O Fim do Ceu
	# --- Regiao XIV  Reino dos Sonhos ---
	"guard.sonhador",           # 65 Vila dos Sonhos
	"guard.reflexo",            # 66 Mundo Invertido
	"guard.boneca",             # 67 Quarto das Criancas Mortas
	"guard.medo",               # 68 Pesadelo
	"boss.outra_koliani",       # 69 A Mente
	# --- Regiao XV  Cidade dos Mortos ---
	"guard.colecionador",       # 70 Avenida dos Mortos
	"guard.coveiro",            # 71 Cemiterio Infinito
	"guard.santo_corrompido",   # 72 Catedral Fantasma
	"guard.rei_morto",          # 73 Palacio dos Reis Mortos
	"boss.morte",               # 74 Trono da Morte
	# --- Regiao XVI  Mar Vermelho ---
	"guard.afogado_vermelho",   # 75 Margem do Sangue
	"guard.serpente_vermelha",  # 76 Serpentes do Mar
	"guard.almirante_morto",    # 77 Navio da Condenacao
	"guard.tentaculo",          # 78 Fortaleza Kraken
	"boss.o_mar",               # 79 Coracao Vermelho
	# --- Regiao XVII  Inferno ---
	"guard.sentinela_inferno",  # 80 Portao Infernal
	"guard.duque_infernal",     # 81 Cidade dos Demonios
	"guard.barqueiro",          # 82 Rio das Almas
	"guard.princesa_demonio",   # 83 Palacio de Sangue
	"boss.rei_demonios",        # 84 Trono Infernal
	# --- Regiao XVIII  O Vazio ---
	"guard.sombra",             # 85 Primeiro Vazio
	"guard.nada",               # 86 Segundo Vazio
	"guard.paradoxo",           # 87 Labirinto Impossivel
	"guard.observador",         # 88 A Coisa Atras do Mundo
	"boss.entidade",            # 89 Centro do Vazio
	# --- Regiao XIX  Guerra dos Reinos ---
	"guard.general_caos",       # 90 Campo de Batalha
	"guard.dragao_primordial",  # 91 Ceu em Guerra
	"guard.ultimo_cavaleiro",   # 92 Cerco ao Castelo
	"guard.arauto_final",       # 93 Torre da Corrupcao
	"boss.campeao",             # 94 Os Cem Guerreiros
	# --- Regiao XX  O Ultimo Caminho (quatro chefes: e' o final) ---
	"guard.zeriko_jovem",       # 95 O Reino Antes da Corrupcao
	"boss.primeiro_rei",        # 96 O Primeiro Castelo
	"boss.zeriko_absoluto",     # 97 O Coracao de Zeriko
	"boss.entidade_purpura",    # 98 O Fim de Tudo
	"boss.zeriko_homem",        # 99 O Ultimo Salto
]


## Chave i18n do nome do nível `indice` (`level.n00`..`level.n99`).
static func chave_nivel(indice: int) -> String:
	return "level.n%02d" % indice


## Chave i18n do nome do chefe (ou guardião) do nível, ou "" fora de alcance.
static func chave_chefe(indice: int) -> String:
	if indice < 0 or indice >= CHEFE_KEY.size():
		return ""
	return CHEFE_KEY[indice]


## O nível `indice` acaba num CHEFE (true) ou num guardião (false)?
static func tem_chefe(indice: int) -> bool:
	return chave_chefe(indice).begins_with("boss.")
