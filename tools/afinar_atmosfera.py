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
