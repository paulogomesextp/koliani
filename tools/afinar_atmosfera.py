#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Da a CADA UM dos 30 niveis o seu ceu e a sua luz.

Ate' aqui cada regiao alternava entre DOIS fundos (A B A B A) e os cinco
niveis partilhavam a graduacao -- por isso e' que "parecia tudo igual"
mesmo depois de mudar de nivel. Aqui ha' uma linha por nivel: pack de
fundo, luz-chave, ceu, neblina, po'.

REGRA (3 set 2026): **um pack NUNCA aparece em duas regioes**. A primeira
versao espalhou os treze packs por variedade dentro de cada regiao, e o
resultado foi o contrario do pretendido -- o `luar` acabou em 5 das 6
regioes, o `igreja` em 4, e a Regiao VI (o Castelo de Zeriko, o climax)
nao tinha fundo nenhum so' dela: usava as paredes da prisao em dois dos
seus cinco niveis. Identidade ENTRE regioes vale mais do que variedade
dentro de uma: e' a mudanca de regiao que o jogador tem de sentir. A
variedade dentro da regiao passa a vir da tinta/luz-chave, que continua a
ser diferente em cada um dos 30 niveis.

  I   floresta, pantano          IV  caverna, gruta
  II  prisao, masmorra           V   vilanoite, cidade, horror
  III montanhas, rochoso         VI  castelo_velho, igreja, luar

O pack `corredores` era uma copia byte a byte do `prisao` (dois nomes para
a mesma imagem) e foi apagado. A II e a IV ficaram com um pack so', e por
isso ganharam `masmorra` e `gruta`, montados de material CC0 que ja' estava
descarregado e por usar (ver `tools/gerar_fundos.py`).

Reescreve o bloco de propriedades do no `Atmosfera` de cada
`scenes/levels/*.tscn`. So' mexe nas chaves da tabela -- `bioma`,
`largura_nivel`, `extensao_esquerda` e o que mais la' esteja fica intacto.

  python tools/afinar_atmosfera.py            # aplica
  python tools/afinar_atmosfera.py --dry-run  # so' diz o que faria
"""

from __future__ import annotations

import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NIVEIS_DIR = os.path.join(RAIZ, "scenes", "levels")

# Por nivel:
#   pack     -- entrada de PACKS em atmosfera.gd
#   amb      -- CanvasModulate (tom geral; >0.9 = quase sem perder luz)
#   fundo    -- ceu por tras de tudo (o degrade sai daqui)
#   silh     -- silhuetas geradas por codigo
#   luz      -- cor dos raios/feixes -- a LUZ-CHAVE do nivel
#   po       -- cor das particulas de ambiente
#   dens     -- densidade do po'
#   tinta    -- por que cor se multiplica o pack de fundo
#   neb      -- profundidade atmosferica (0 = camadas todas iguais)
#   des      -- quanto se tira da cor propria do pack antes da tinta
#   horiz    -- brilho quente no horizonte (fogo/lava ao longe)
#
# A ideia da progressao: I verde-doente -> II azul-ferro -> III prata-frio
# -> IV osso-violeta -> V ameixa-rosa -> VI magenta do Zeriko. Dentro de
# cada regiao, cada nivel puxa a luz-chave para um lado diferente.
TABELA = [
    # ---- I  Floresta Putrefacta -------------------------------------
    ("Floresta_Putrefata",     "floresta",      (.86,.92,.86), (.05,.09,.09), (.09,.15,.09), (.62,1.0,.72), (.72,1.0,.86), 1.5, (.82,.94,1.02), .30, .26, False),
    ("Pantano_dos_Sussurros",  "pantano",       (.80,.90,.84), (.05,.10,.09), (.07,.14,.11), (.46,.92,.76), (.62,1.0,.88), 2.2, (.76,1.00,.96), .50, .24, False),
    ("Ninho_da_Viuva_Negra",   "floresta",       (.84,.80,.90), (.07,.05,.10), (.11,.08,.15), (.86,.56,1.0), (.92,.72,1.0), 1.8, (.94,.78,1.08), .38, .30, False),
    ("A_Arvore_que_Chora",     "pantano",          (.90,.88,.92), (.09,.04,.11), (.10,.06,.12), (1.0,.44,.86),  (1.0,.72,.92), 1.6, (1.00,.86,1.00), .22, .10, False),
    ("Coracao_da_Floresta",    "pantano",       (.82,.88,.84), (.08,.05,.10), (.10,.14,.09), (.94,.42,1.0),  (.90,.66,1.0), 2.0, (.90,.84,1.06), .44, .36, False),
    # ---- II Prisao dos Condenados -----------------------------------
    ("Prisao_dos_Condenados",  "prisao",        (.80,.84,.96), (.04,.06,.12), (.07,.09,.16), (.60,.68,1.0),  (.72,.84,1.0), 1.2, (.70,.82,1.14), .44, .56, False),
    ("Fornalha_dos_Pecadores", "masmorra",        (.98,.86,.78), (.13,.05,.04), (.18,.08,.06), (1.0,.58,.26),  (1.0,.76,.44), 2.4, (1.14,.72,.62), .28, .44, True),
    ("Corredor_das_Execucoes", "prisao",    (.82,.88,.98), (.04,.07,.11), (.07,.11,.16), (.62,.84,1.0),  (.78,.92,1.0), 1.0, (.72,.90,1.16), .38, .58, False),
    ("Ala_dos_Mortos",         "masmorra", (.84,.92,.90), (.04,.09,.09), (.06,.13,.12), (.48,1.0,.86),  (.66,1.0,.92), 1.8, (.80,1.04,1.00), .40, .28, False),
    ("A_Cela_Zero",            "prisao",        (.76,.76,.94), (.05,.04,.11), (.08,.07,.15), (.74,.44,1.0),  (.82,.62,1.0), 1.4, (.78,.70,1.20), .50, .60, False),
    # ---- III Torres --------------------------------------------------
    ("Torre_dos_Sinos",        "montanhas",     (.96,.90,.86), (.09,.07,.11), (.14,.11,.14), (1.0,.74,.46),  (1.0,.88,.68), 1.1, (1.06,.90,.94), .30, .22, True),
    ("Torre_dos_Ventos",       "rochoso",       (.92,.92,.96), (.06,.07,.12), (.10,.12,.18), (.96,.86,.64),  (1.0,.96,.84), 1.9, (.94,.94,1.06), .34, .26, False),
    ("Torre_da_Tempestade",    "montanhas",        (.86,.90,1.0), (.04,.06,.13), (.07,.10,.18), (.70,.88,1.0),  (.80,.94,1.0), 2.3, (.74,.88,1.20), .46, .34, False),
    ("Observatorio_Lunar",     "rochoso",          (.94,.94,1.0), (.07,.06,.14), (.10,.10,.18), (.88,.90,1.0),  (.94,.96,1.0), 1.3, (.90,.92,1.14), .18, .16, False),
    ("O_Pico_Esquecido",       "montanhas",     (.90,.90,.98), (.06,.06,.13), (.10,.11,.19), (.78,.58,1.0),  (.88,.78,1.0), 2.0, (.86,.86,1.16), .40, .30, False),
    # ---- IV Catacumbas ----------------------------------------------
    ("Cemiterio_dos_Reis",     "caverna",          (.88,.88,.92), (.07,.04,.10), (.11,.09,.13), (.86,.70,.78),  (.96,.88,.90), 1.4, (1.00,.84,.96), .26, .14, False),
    ("Galeria_dos_Ossos",      "gruta",       (.90,.88,.84), (.07,.06,.07), (.13,.12,.10), (.92,.86,.66),  (1.0,.96,.80), 1.6, (1.04,.94,.86), .34, .26, False),
    ("Cripta_das_Mil_Velas",   "caverna",        (.98,.90,.80), (.10,.06,.07), (.15,.10,.09), (1.0,.80,.48),  (1.0,.90,.62), 2.1, (1.10,.86,.80), .30, .30, True),
    ("Templo_da_Serpente",     "gruta", (.84,.92,.84), (.04,.09,.07), (.07,.14,.10), (.56,.92,.50),  (.72,1.0,.66), 1.7, (.78,1.06,.86), .38, .22, False),
    ("O_Abismo",               "gruta",       (.76,.74,.92), (.04,.03,.10), (.07,.06,.14), (.52,.34,.88),  (.70,.56,1.0), 2.4, (.72,.64,1.18), .52, .34, False),
    # ---- V  Cidade Corrompida ---------------------------------------
    ("Vila_dos_Sem_Rosto",     "vilanoite",     (.94,.86,.90), (.09,.05,.10), (.13,.09,.14), (1.0,.62,.72),  (1.0,.82,.88), 1.3, (1.06,.84,.98), .28, .18, True),
    ("Mercado_da_Carne",       "cidade",        (.96,.82,.86), (.11,.04,.07), (.16,.07,.10), (1.0,.46,.54),  (1.0,.70,.74), 1.9, (1.12,.74,.86), .32, .30, False),
    ("Trem_dos_Mortos",        "horror",        (.92,.84,.86), (.08,.05,.08), (.12,.08,.11), (1.0,.58,.50),  (1.0,.78,.70), 2.5, (1.08,.80,.88), .44, .28, True),
    ("Catedral_da_Corrupcao",  "vilanoite",        (.90,.82,.98), (.07,.04,.12), (.11,.07,.17), (.80,.46,1.0),  (.90,.68,1.0), 1.5, (.94,.76,1.16), .36, .32, False),
    ("Praca_do_Eclipse",       "cidade",          (.92,.82,.96), (.09,.03,.12), (.13,.06,.16), (.88,.52,1.0),  (.96,.72,1.0), 1.4, (1.02,.76,1.10), .24, .12, False),
    # ---- VI Castelo de Zeriko ---------------------------------------
    ("Portoes_de_Zeriko",      "luar",    (.90,.80,.96), (.08,.03,.12), (.12,.06,.17), (1.0,.44,.96),  (1.0,.70,1.0), 1.6, (1.00,.72,1.16), .34, .34, True),
    ("Salao_dos_Espelhos",     "castelo_velho", (.92,.86,.98), (.06,.05,.13), (.10,.09,.18), (1.0,.52,.96),  (1.0,.78,1.0), 1.2, (.96,.80,1.18), .28, .20, False),
    ("Banquete_dos_Imortais",  "igreja",        (.96,.84,.92), (.10,.04,.10), (.15,.07,.14), (1.0,.56,.88),  (1.0,.78,.96), 1.8, (1.08,.78,1.04), .32, .28, True),
    ("Torre_do_Coracao_Negro", "castelo_velho",    (.86,.74,.96), (.06,.02,.12), (.10,.05,.17), (1.0,.36,.96),  (1.0,.64,1.0), 2.2, (.92,.64,1.20), .46, .36, False),
    ("O_Trono_de_Zeriko",      "luar",          (.98,.80,1.0), (.11,.02,.13), (.16,.05,.18), (1.0,.32,1.0),  (1.0,.62,1.0), 2.0, (1.10,.68,1.14), .16, .08, True),
    # ---- VII  Terras Queimadas (31-35) ------------------------------
    # A regiao onde o reino arde. Nao ha' packs de fundo por atribuir --
    # a regra "um pack nunca em duas regioes" vale para as seis regioes de
    # 1-30, que consomem os doze packs que existem. Da' VII em diante os
    # packs SAO reaproveitados, e a identidade da regiao tem de vir toda da
    # tinta e da luz-chave: laranja/brasa em todos os cinco, contra o
    # verde/azul/violeta de tudo o que veio antes. Enquanto nao houver arte
    # propria (14 regioes x ~2 packs), e' o melhor que se consegue.
    ("Estrada_das_Cinzas",     "floresta",      (.98,.84,.72), (.16,.06,.03), (.20,.09,.05), (1.0,.52,.18),  (1.0,.66,.30), 3.0, (1.20,.66,.42), .34, .52, True),
    ("Rio_de_Magma",           "caverna",       (1.0,.80,.66), (.19,.05,.02), (.24,.08,.03), (1.0,.42,.10),  (1.0,.58,.22), 3.4, (1.26,.58,.34), .30, .56, True),
    ("A_Forja_dos_Demonios",   "masmorra",      (.96,.82,.74), (.14,.06,.05), (.19,.09,.06), (1.0,.62,.24),  (1.0,.74,.38), 2.6, (1.16,.70,.50), .36, .46, True),
    ("Vulcao_do_Rei_Morto",    "rochoso",       (1.0,.76,.62), (.21,.04,.02), (.26,.07,.03), (1.0,.36,.08),  (1.0,.52,.18), 3.8, (1.30,.52,.30), .26, .60, True),
    ("O_Ceu_em_Chamas",        "horror",        (1.0,.88,.76), (.24,.08,.04), (.28,.11,.06), (1.0,.72,.34),  (1.0,.84,.50), 3.2, (1.24,.80,.56), .22, .38, True),
    # ---- VIII  Mar dos Mortos (36-40) -------------------------------
    # O contraponto da VII: onde aquela era brasa e ar seco, esta e' agua.
    # Verde-azulado a descer para azul-tinta no ultimo nivel, po' denso (a
    # materia em suspensao faz o "debaixo de agua" sem shader nenhum) e
    # horizonte APAGADO em todos -- no fundo do mar nao ha' brilho quente
    # ao longe. Packs reaproveitados, como na VII; a identidade e' a tinta.
    ("Porto_dos_Afogados",     "vilanoite",     (.78,.92,.96), (.03,.09,.14), (.05,.13,.18), (.42,.90,.98),  (.62,.94,1.0), 3.4, (.56,.94,1.10), .40, .44, False),
    ("Cidade_Submersa",        "cidade",        (.74,.90,.98), (.02,.08,.15), (.04,.12,.20), (.34,.84,1.0),  (.54,.90,1.0), 4.0, (.48,.88,1.16), .46, .50, False),
    ("Palacio_das_Sereias_Mortas", "igreja",    (.82,.96,.96), (.03,.10,.13), (.06,.15,.18), (.52,.96,.92),  (.72,1.0,.96), 3.0, (.62,1.0,1.04), .36, .40, False),
    ("Ossario_das_Baleias",    "gruta",         (.86,.96,.92), (.04,.10,.11), (.07,.14,.15), (.64,.98,.90),  (.80,1.0,.92), 3.6, (.72,1.02,.98), .42, .46, False),
    ("Abismo_Oceanico",        "caverna",       (.62,.80,.98), (.01,.04,.10), (.02,.07,.14), (.26,.70,1.0),  (.44,.80,1.0), 4.4, (.36,.76,1.20), .54, .58, False),
    # ---- IX  Reino do Gelo (41-45) ----------------------------------
    # A PRIMEIRA regiao clara do jogo. Depois de trinta e cinco niveis de
    # noite, o `amb` sobe para perto de 1 e o `des` sobe muito (a neve e'
    # branca: tira-se quase toda a cor propria do pack antes de tintar).
    # O po' denso faz de NEVE a cair. Horizonte apagado em todos menos no
    # ultimo, onde um brilho frio no fundo faz de aurora.
    # Packs: nenhum destes cinco e' usado pela VII nem pela VIII.
    ("Floresta_Congelada",     "pantano",       (.84,.97,1.22), (.34,.42,.56), (.46,.54,.68), (.80,.96,1.0),  (.96,1.0,1.0), 4.6, (1.06,1.16,1.38), .22, .74, False),
    ("Montanha_dos_Ventos",    "montanhas",     (.88,1.0,1.24), (.42,.50,.64), (.54,.62,.76), (.88,.98,1.0),  (1.0,1.0,1.0), 5.0, (1.12,1.20,1.36), .18, .70, False),
    ("Cavernas_Cristalinas",   "prisao",        (.80,.95,1.24), (.26,.34,.50), (.36,.45,.62), (.72,.92,1.0),  (.90,.98,1.0), 4.2, (1.00,1.12,1.42), .26, .78, False),
    ("Castelo_Congelado",      "castelo_velho", (.86,.99,1.26), (.38,.46,.60), (.50,.58,.72), (.92,1.0,1.0),  (1.0,1.0,1.0), 3.8, (1.10,1.18,1.34), .20, .72, False),
    ("Coracao_do_Inverno",     "luar",          (.78,.93,1.26), (.22,.30,.48), (.32,.41,.60), (.70,.90,1.0),  (.92,.99,1.0), 5.2, (1.02,1.14,1.44), .28, .76, True),
    # ---- X  Deserto dos Esquecidos (46-50) --------------------------
    # A IX era clara e FRIA; esta e' a mesma luz alta, mas QUENTE. Nao se
    # confunde com a VII (escura, com brasa a arder ao longe): aqui e' dia
    # aberto -- ceu de areia, `amb` puxado ao vermelho e ao amarelo, e o
    # horizonte quente ligado em todos (o calor a tremer ao longe).
    # A Piramide Negra sai da paleta de proposito: e' onde a magia purpura
    # do Zeriko volta a aparecer, e o roxo no meio do ocre e' o aviso.
    ("Mar_de_Areia",           "rochoso",       (1.20,1.02,.72), (.52,.40,.24), (.62,.50,.32), (1.0,.86,.48),  (1.0,.92,.66), 4.8, (1.32,1.10,.72), .20, .68, True),
    ("Templo_Sem_Nome",        "masmorra",      (1.14,.98,.72), (.40,.30,.19), (.50,.39,.26), (1.0,.82,.44),  (1.0,.90,.62), 3.6, (1.26,1.04,.70), .26, .62, True),
    ("Vale_dos_Escorpioes",    "montanhas",     (1.22,1.00,.66), (.48,.35,.20), (.58,.44,.27), (1.0,.78,.36),  (1.0,.88,.56), 4.4, (1.36,1.06,.62), .22, .88, True),
    ("Cidade_Enterrada",       "cidade",        (1.16,1.00,.74), (.44,.34,.22), (.54,.43,.30), (1.0,.84,.50),  (1.0,.92,.68), 4.0, (1.28,1.08,.74), .24, .64, True),
    ("Piramide_Negra",         "horror",        (1.02,.80,1.10), (.18,.10,.24), (.26,.16,.33), (.86,.56,1.0),  (.96,.72,1.0), 3.4, (1.14,.78,1.28), .34, .58, False),
    # ---- XI  Jardins do Rei (51-55) ---------------------------------
    # Verde CULTIVADO -- nao a floresta doente da Regiao I, que era
    # amarelo-doente: aqui a cor e' saudavel, quase bonita, e e' isso que
    # faz medo. O `amb` puxa o verde acima de 1; o po' e' polen.
    # O primeiro nivel sai da paleta a vermelho (as rosas negras) e o
    # ultimo abre para dourado (a arvore ao sol).
    ("Jardim_das_Rosas_Negras","floresta",      (.96,.88,.94), (.16,.05,.10), (.22,.08,.14), (.90,.30,.52),  (1.0,.60,.74), 3.6, (1.06,.66,.80), .30, .52, False),
    ("Labirinto_Verde",        "pantano",       (.86,1.14,.88), (.06,.16,.08), (.10,.23,.12), (.52,.95,.50),  (.76,1.0,.70), 4.2, (.72,1.24,.72), .26, .56, False),
    ("Jardim_das_Almas",       "gruta",         (.94,1.10,.92), (.10,.18,.14), (.15,.25,.20), (.80,.95,.62),  (.92,1.0,.78), 5.0, (.90,1.18,.82), .34, .60, True),
    ("Estufa_Maldita",         "igreja",        (.88,1.16,.86), (.08,.19,.09), (.13,.26,.14), (.62,.98,.44),  (.84,1.0,.66), 4.6, (.76,1.28,.66), .28, .62, False),
    ("Arvore_do_Rei",          "luar",          (1.04,1.10,.82), (.16,.20,.08), (.23,.28,.13), (.70,1.0,.48),  (1.0,1.0,.62), 4.0, (1.02,1.20,.62), .24, .58, True),
    # ---- XII  Cidade das Maquinas (56-60) ---------------------------
    # A regiao mais FRIA de cor do jogo inteiro, e de proposito: vem logo
    # a seguir ao verde vivo dos Jardins. Aco azul, electricidade ciano,
    # zero verde e zero laranja. Sem horizonte quente -- aqui nao ha' sol.
    ("Distrito_das_Engrenagens","masmorra",     (.72,.94,1.18), (.05,.11,.18), (.09,.17,.26), (.55,.85,1.0),  (.72,.94,1.0), 3.8, (.66,.96,1.34), .32, .66, False),
    ("Linha_13",               "prisao",        (.76,.96,1.16), (.06,.12,.19), (.10,.18,.27), (.60,.90,1.0),  (.78,.96,1.0), 4.4, (.70,.98,1.30), .36, .64, False),
    ("Fabrica_dos_Homunculos", "cidade",        (.80,.98,1.14), (.07,.13,.20), (.11,.19,.28), (.70,.95,1.0),  (.86,.98,1.0), 4.0, (.76,1.00,1.28), .30, .62, False),
    ("Torre_Electrica",        "rochoso",       (.68,.92,1.22), (.04,.10,.20), (.08,.16,.29), (.50,.92,1.0),  (.68,.96,1.0), 4.8, (.60,.94,1.40), .38, .70, False),
    ("Coracao_da_Maquina",     "castelo_velho", (.64,.90,1.24), (.03,.08,.17), (.07,.14,.25), (.45,.88,1.0),  (.62,.94,1.0), 4.2, (.56,.92,1.42), .42, .72, False),
    # ---- XIII  Ceu Partido (61-65) ----------------------------------
    # Indigo de noite alta com estrelas. A regiao mais ESCURA de fundo e a
    # mais CLARA de luz-chave ao mesmo tempo: e' o contraste que faz o
    # "estar acima das nuvens". O po' e' poeira de estrelas -- muito denso.
    ("Ilhas_Flutuantes",       "montanhas",     (.82,.84,1.14), (.06,.07,.20), (.11,.13,.28), (.62,.70,1.0),  (.84,.88,1.0), 5.4, (.72,.78,1.34), .44, .60, False),
    ("Templo_do_Trovao",       "rochoso",       (.92,.94,1.16), (.09,.10,.22), (.14,.16,.30), (.80,.86,1.0),  (.94,.96,1.0), 4.6, (.86,.90,1.30), .38, .56, False),
    ("Cidade_dos_Anjos_Mortos","igreja",        (.98,.97,1.12), (.11,.12,.24), (.17,.18,.32), (.92,.90,1.0),  (1.0,.98,1.0), 4.0, (.96,.94,1.24), .34, .52, True),
    ("Lua_Quebrada",           "luar",          (.88,.90,1.18), (.07,.08,.21), (.12,.14,.29), (.74,.80,1.0),  (.90,.92,1.0), 5.0, (.80,.84,1.36), .42, .64, False),
    ("O_Fim_do_Ceu",           "horror",        (.78,.82,1.20), (.04,.05,.18), (.08,.10,.26), (.56,.68,1.0),  (.78,.84,1.0), 5.8, (.66,.74,1.40), .50, .68, False),
    # ---- XIV  Reino dos Sonhos (66-70) ------------------------------
    # Pastel LILAS. Nao e' o magenta do Zeriko (esse e' saturado e duro):
    # aqui a cor esta' lavada, como uma fotografia velha. E' a unica regiao
    # em que a neblina e' alta E o po' e' claro -- tudo parece longe.
    ("Vila_dos_Sonhos",        "vilanoite",     (1.04,.86,1.10), (.16,.10,.20), (.22,.15,.27), (.92,.66,.96),  (1.0,.86,1.0), 4.2, (1.12,.82,1.20), .52, .54, False),
    ("Mundo_Invertido",        "cidade",        (.96,.82,1.16), (.13,.09,.22), (.19,.14,.29), (.80,.60,1.0),  (.94,.80,1.0), 4.6, (1.00,.78,1.28), .56, .58, False),
    ("Quarto_das_Criancas_Mortas","pantano",    (1.10,.90,1.06), (.19,.12,.19), (.25,.17,.25), (1.0,.72,.86),  (1.0,.90,.96), 3.8, (1.20,.88,1.10), .48, .50, False),
    ("Pesadelo",               "gruta",         (.88,.70,1.14), (.10,.05,.19), (.15,.09,.25), (.70,.40,.94),  (.86,.64,1.0), 5.0, (.90,.62,1.30), .60, .62, False),
    ("A_Mente",                "masmorra",      (1.00,.80,1.18), (.14,.08,.23), (.20,.13,.30), (.86,.56,1.0),  (.98,.78,1.0), 4.4, (1.06,.74,1.32), .54, .56, True),
    # ---- XV  Cidade dos Mortos (71-75) ------------------------------
    # Verde-osso: cinzento com um resto de verde, a cor de vela apagada.
    # E' o negativo da XI (verde vivo) -- a mesma familia de cor, sem vida.
    ("Avenida_dos_Mortos",     "prisao",        (.86,1.00,.90), (.08,.12,.10), (.13,.18,.15), (.72,.92,.80),  (.88,1.0,.92), 4.4, (.80,1.04,.88), .40, .64, False),
    ("Cemiterio_Infinito",     "castelo_velho", (.82,.98,.88), (.06,.10,.08), (.11,.16,.13), (.66,.88,.76),  (.84,.98,.88), 4.8, (.74,1.00,.84), .46, .68, False),
    ("Catedral_Fantasma",      "igreja",        (.92,1.02,.94), (.10,.14,.12), (.16,.21,.18), (.84,.96,.88),  (.94,1.0,.96), 4.0, (.88,1.06,.92), .36, .60, True),
    ("Palacio_dos_Reis_Mortos","caverna",       (.98,1.00,.84), (.12,.13,.08), (.18,.19,.13), (.94,.90,.62),  (1.0,.98,.76), 3.6, (1.02,1.00,.74), .34, .58, True),
    ("Trono_da_Morte",         "floresta",      (.78,.98,.84), (.04,.08,.06), (.09,.14,.11), (.60,.96,.72),  (.80,1.0,.84), 5.2, (.68,1.02,.78), .50, .70, False),
    # ---- XVI  Mar Vermelho (76-80) ----------------------------------
    # Vermelho a serio -- nao ha' nada assim em nenhuma outra regiao. O
    # verde e o azul vao ao chao no `amb`, e o horizonte quente esta'
    # ligado nos cinco: o mar inteiro brilha.
    ("Margem_do_Sangue",       "pantano",       (1.22,.62,.62), (.24,.04,.06), (.31,.07,.09), (1.0,.30,.32),  (1.0,.60,.58), 4.2, (1.34,.52,.52), .32, .66, True),
    ("Serpentes_do_Mar",       "gruta",         (1.24,.56,.58), (.20,.03,.05), (.27,.06,.08), (1.0,.24,.28),  (1.0,.54,.54), 4.6, (1.38,.46,.48), .38, .70, True),
    ("Navio_da_Condenacao",    "prisao",        (1.18,.66,.64), (.22,.05,.06), (.29,.08,.10), (.96,.36,.34),  (1.0,.66,.60), 4.0, (1.30,.58,.54), .34, .62, True),
    ("Fortaleza_Kraken",       "cidade",        (1.16,.60,.68), (.19,.04,.08), (.26,.07,.12), (.90,.28,.40),  (1.0,.58,.66), 4.4, (1.28,.50,.62), .36, .68, True),
    ("Coracao_Vermelho",       "horror",        (1.28,.50,.54), (.26,.02,.05), (.33,.05,.08), (1.0,.20,.26),  (1.0,.50,.52), 5.0, (1.42,.40,.44), .42, .72, True),
    # ---- XVII  Inferno (81-85) --------------------------------------
    # Tambem e' laranja, como a VII, mas por outra razao: a VII e' laranja
    # MEDIO em tudo (o reino a arder ao longe); esta e' PRETA com nucleos
    # brancos de fogo. O fundo vai quase a zero e a luz-chave quase a um --
    # e' o contraste, nao a cor, que faz o inferno.
    ("Portao_Infernal",        "castelo_velho", (1.16,.78,.52), (.07,.02,.01), (.13,.04,.02), (1.0,.52,.10),  (1.0,.70,.26), 4.0, (1.30,.62,.28), .30, .70, True),
    ("Cidade_dos_Demonios",    "vilanoite",     (1.20,.72,.46), (.09,.02,.01), (.15,.04,.02), (1.0,.44,.08),  (1.0,.64,.22), 4.4, (1.34,.54,.22), .28, .72, True),
    ("Rio_das_Almas",          "caverna",       (1.12,.82,.58), (.06,.03,.02), (.11,.05,.03), (1.0,.60,.16),  (1.0,.76,.34), 4.8, (1.26,.70,.34), .36, .68, True),
    ("Palacio_de_Sangue",      "igreja",        (1.22,.66,.48), (.10,.01,.03), (.16,.03,.05), (1.0,.34,.14),  (1.0,.58,.28), 3.8, (1.36,.48,.26), .26, .74, True),
    ("Trono_Infernal",         "horror",        (1.26,.68,.40), (.11,.01,.00), (.17,.03,.01), (1.0,.38,.06),  (1.0,.60,.18), 4.2, (1.40,.50,.18), .32, .76, True),
    # ---- XVIII  O Vazio (86-90) -------------------------------------
    # A unica regiao QUASE SEM COR do jogo. `des` a 0.95 mata a cor propria
    # do pack e sobra silhueta; a tinta e' cinzenta, a luz-chave e' um
    # branco-violeta so'. Nada de horizonte -- nao ha' longe, aqui.
    ("Primeiro_Vazio",         "rochoso",       (.90,.88,1.00), (.03,.02,.05), (.06,.05,.09), (.86,.80,1.0),  (.94,.92,1.0), 2.4, (.90,.88,1.06), .58, .95, False),
    ("Segundo_Vazio",          "montanhas",     (.92,.90,1.00), (.02,.02,.04), (.05,.04,.08), (.90,.86,1.0),  (.96,.94,1.0), 2.0, (.92,.90,1.04), .62, .95, False),
    ("Labirinto_Impossivel",   "masmorra",      (.88,.86,1.00), (.03,.03,.06), (.07,.06,.10), (.82,.76,1.0),  (.92,.90,1.0), 2.8, (.88,.86,1.08), .56, .95, False),
    ("A_Coisa_Atras_do_Mundo", "gruta",         (.94,.92,1.00), (.02,.02,.05), (.05,.05,.09), (.94,.90,1.0),  (.98,.96,1.0), 2.2, (.94,.92,1.05), .64, .95, False),
    ("Centro_do_Vazio",        "horror",        (.86,.82,1.00), (.01,.01,.03), (.04,.03,.07), (.78,.70,1.0),  (.90,.86,1.0), 3.0, (.86,.82,1.10), .68, .95, False),
    # ---- XIX  Guerra dos Reinos (91-95) -----------------------------
    # Fumo e aco: castanho-cinzento dessaturado com AMBAR so' no horizonte.
    # E' o que a separa do Inferno, que e' preto-e-fogo: aqui ha' luz do
    # dia, so' que passada por fumo. A Torre da Corrupcao (94) sai da
    # paleta para magenta -- e' o aviso de que o Zeriko volta.
    ("Campo_de_Batalha",       "cidade",        (1.06,.94,.78), (.20,.15,.10), (.27,.21,.15), (1.0,.74,.44),  (1.0,.88,.66), 5.4, (1.14,.98,.74), .40, .62, True),
    ("Ceu_em_Guerra",          "montanhas",     (1.04,.92,.76), (.22,.17,.12), (.29,.23,.17), (1.0,.68,.38),  (1.0,.84,.60), 5.0, (1.12,.96,.70), .44, .64, True),
    ("Cerco_ao_Castelo",       "castelo_velho", (1.02,.94,.82), (.18,.14,.10), (.25,.20,.15), (.96,.78,.50),  (1.0,.90,.70), 4.6, (1.10,1.00,.80), .38, .60, True),
    ("Torre_da_Corrupcao",     "horror",        (1.00,.80,1.06), (.16,.08,.20), (.22,.13,.27), (.92,.60,.90),  (1.0,.78,.96), 4.2, (1.06,.76,1.16), .42, .58, False),
    ("Os_Cem_Guerreiros",      "rochoso",       (1.08,.92,.72), (.19,.14,.09), (.26,.20,.14), (1.0,.70,.32),  (1.0,.86,.58), 5.2, (1.16,.96,.66), .36, .66, True),
    # ---- XX  O Ultimo Caminho (96-100) ------------------------------
    # A unica regiao em que cada nivel tem a SUA cor: sao memorias, nao um
    # sitio. 96 e' o dourado do reino antes de tudo (o unico nivel quente e
    # feliz do jogo inteiro), 97 e' pedra ao sol, 98 e' carmim por dentro do
    # Zeriko, 99 e' o magenta a rebentar, e 100 e' a madrugada -- luz alta,
    # quase sem cor, o oposto exacto do nivel 1.
    ("O_Reino_Antes_da_Corrupcao","floresta",   (1.10,1.06,.82), (.30,.26,.14), (.38,.33,.19), (1.0,.92,.60),  (1.0,.98,.78), 3.4, (1.18,1.12,.78), .24, .48, True),
    ("O_Primeiro_Castelo",     "montanhas",     (1.08,1.00,.82), (.26,.22,.14), (.34,.29,.19), (1.0,.86,.52),  (1.0,.94,.74), 3.8, (1.16,1.06,.78), .28, .52, True),
    ("O_Coracao_de_Zeriko",    "caverna",       (1.14,.62,.86), (.18,.03,.09), (.25,.06,.14), (1.0,.24,.62),  (1.0,.56,.80), 4.6, (1.28,.52,.86), .40, .66, False),
    ("O_Fim_de_Tudo",          "horror",        (1.16,.70,1.16), (.16,.04,.18), (.23,.08,.25), (1.0,.30,1.0),  (1.0,.64,1.0), 5.6, (1.30,.62,1.30), .46, .60, True),
    ("O_Ultimo_Salto",         "luar",          (1.10,1.08,1.04), (.44,.42,.44), (.54,.52,.55), (1.0,.94,.86),  (1.0,.98,.96), 3.0, (1.16,1.14,1.12), .18, .82, True),
]

CHAVES = [
    "cor_ambiente", "cor_fundo", "cor_silhueta", "cor_luz", "cor_poeira",
    "densidade_poeira", "bioma", "largura_nivel", "fundo_pack", "tinta_fundo",
    "neblina_fundo", "dessaturar_fundo", "seed_ambiente", "luzes_horizonte",
    "extensao_esquerda",
]
# as que esta tabela manda (as outras ficam como estao na cena)
MEUS = {
    "cor_ambiente", "cor_fundo", "cor_silhueta", "cor_luz", "cor_poeira",
    "densidade_poeira", "fundo_pack", "tinta_fundo", "neblina_fundo",
    "dessaturar_fundo", "seed_ambiente", "luzes_horizonte",
}


def cor(c) -> str:
    return "Color(%s, 1)" % ", ".join(("%g" % round(v, 3)) for v in c)


def main() -> int:
    seco = "--dry-run" in sys.argv
    for i, linha in enumerate(TABELA):
        nome, pack, amb, fundo, silh, luz, po, dens, tinta, neb, des, horiz = linha
        cam = os.path.join(NIVEIS_DIR, nome + ".tscn")
        if not os.path.exists(cam):
            print("  ! sem cena:", nome)
            continue
        s = open(cam, encoding="utf-8").read()
        m = re.search(r'(\[node name="Atmosfera"[^\]]*\]\r?\n)((?:[a-z_]+ = .*\r?\n)*)', s)
        if not m:
            print("  ! sem no Atmosfera:", nome)
            continue

        # o que a cena ja' tinha e nao e' meu (bioma, largura_nivel, ...)
        antigos = {}
        for lin in m.group(2).splitlines():
            mm = re.match(r"([a-z_]+) = (.*)", lin.strip())
            if mm and mm.group(1) not in MEUS:
                antigos[mm.group(1)] = mm.group(2)

        novos = {
            "cor_ambiente": cor(amb), "cor_fundo": cor(fundo),
            "cor_silhueta": cor(silh), "cor_luz": cor(luz), "cor_poeira": cor(po),
            "densidade_poeira": "%g" % dens, "fundo_pack": '"%s"' % pack,
            "tinta_fundo": cor(tinta), "neblina_fundo": "%g" % neb,
            "dessaturar_fundo": "%g" % des, "seed_ambiente": str(1000 + i * 37),
        }
        if horiz:
            novos["luzes_horizonte"] = "true"
        novos.update(antigos)

        corpo = "".join("%s = %s\n" % (k, novos[k]) for k in CHAVES if k in novos)
        s2 = s[:m.start(2)] + corpo + s[m.end(2):]
        print("%2d %-24s %-14s neb=%-4s des=%-4s%s" % (
            i, nome[:24], pack, neb, des, "  [horizonte]" if horiz else ""))
        if not seco and s2 != s:
            open(cam, "w", encoding="utf-8", newline="") .write(s2)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
