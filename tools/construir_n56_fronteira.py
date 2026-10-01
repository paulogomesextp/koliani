#!/usr/bin/env python3
"""Gera `scenes/levels/Distrito_das_Engrenagens.tscn` -- N56 "Fronteira Corrompida".

O nome do ficheiro e' LEGADO (era o Distrito das Engrenagens, Cidade das
Maquinas): mudá-lo partia saves; o que o jogador le' e' a chave `level.n55`.

EDITAR AQUI e voltar a correr (nao editar o `.tscn` a mao):
    python tools/construir_n56_fronteira.py

Contrato: `docs/art_direction/regions/region_12/master_production_board.png`
(cartao do N56: "primeiro contacto com o terreno toxico, solo seguro vs.
contaminado, nuvens de veneno fracas, ruinas de postos de fronteira").
Desenho e medicoes: docs/nivel_autoral_n56.md.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from r12_lib import (FERRUGEM, LUZ_FOGO, LUZ_LIMPA, LUZ_VENENO, RAIZ, RIM_VERDE, SOMBRA,  # noqa: E402
                     Cena, v)

SAIDA = os.path.join(RAIZ, "scenes", "levels", "Distrito_das_Engrenagens.tscn")
c = Cena("Distrito_das_Engrenagens", "uid://bkolianidistritodasengrenagens56")
CH = 600.0      # linha do chao principal
BX = 700.0      # fundo do pantano (100 abaixo do chao)
BAIXO = 680.0   # chao da descida (80 abaixo)

c.no("Distrito_das_Engrenagens",
     f'script = ExtResource("{c.script("res://scripts/nivel_com_chefe.gd")}")\n'
     "corredor = false\ncandeeiros = false\nalongar_plataformas = false\ncheckpoints_autorais = true\n"
     'mecanica_anunciada = "solo_toxico"\nestreia_x_autoral = 520.0',
     tipo="Node2D", pai="")
c.nos[0] = c.nos[0].replace(' parent=""', "")
c.atmosfera("", "terras_n56", 4700.0, 5601)

# ======================================================================
#  A) CHEGADA A FRONTEIRA (ensinar: solo contaminado, e que se salta por cima)
# ======================================================================
c.com("""
===================  A) CHEGADA A FRONTEIRA  =============================
Chao largo e seguro; cercas e uma bandeira rasgada do posto. A meio, a
PRIMEIRA poca de solo contaminado (240 px): cabe num salto, e quem a
atravessa a andar so' fica envenenado -- nao leva dano de impacto.
Dois ratos pestilentos a guardar o resto.
""")
c.plat("ChaoA", 0, 1150, CH, h=180, av=520)
c.assente("CercaA1", "r12_cerca", 70, CH, esc=0.85, z=-3)
c.assente("PalicadaA", "r12_palicada", 230, CH, esc=1.0, z=-4, mod=SOMBRA)
c.assente("BandeiraA", "r12_bandeira", 330, CH, esc=1.0, z=-3)
c.assente("ArvoreA1", "r12_arvore_morta_g", 130, CH, esc=1.3, z=-6, mod=SOMBRA)
c.assente("OssosA", "r12_ossos", 450, CH, esc=0.5, z=-1)
c.assente("BarrilA", "r12_barril", 480, CH, esc=0.6, z=-1)
c.luz("LuzBandeiraA", 330, CH - 140, 0.5, LUZ_VENENO, (2.2, 1.4))
c.check("CheckInicio", 380, CH)

c.com("""SOLO CONTAMINADO 1 (240 px, 520-760). Cabe num salto simples.""")
c.solo_toxico("SoloA", 520, 760, CH, veneno=2.0)
c.assente("PlacaAviso", "r12_poste", 495, CH, esc=0.8, z=-2)
c.assente("EstacasA", "r12_estacas", 790, CH, esc=0.7, z=-2, mod=SOMBRA)
c.fx("BolhasA", "r12_bolhas", 640, CH - 14, esc=0.5, z=2, mod="Color(0.7, 1, 0.5, 0.8)")
c.inimigo("RatoA1", 330, CH - 22, "rato_pestilento", "patrulha", 18, 10, 110, rim=RIM_VERDE)
c.inimigo("RatoA2", 900, CH - 22, "rato_pestilento", "patrulha", 18, 10, 120, rim=RIM_VERDE)
c.assente("ArvoreA2", "r12_arvore_morta_p", 960, CH, esc=1.2, z=-6, mod=SOMBRA)
c.assente("CercaA2", "r12_cerca", 1050, CH, esc=0.85, z=-3)
c.gas("GasA", 640, CH - 10, 260, n=8)

# ======================================================================
#  B) POSTO DE FRONTEIRA EM RUINAS (pantano raso, tabuas, primeira nuvem)
# ======================================================================
c.com("""
===================  B) POSTO DE FRONTEIRA EM RUINAS  ====================
O chao acaba num pantano raso (100 px abaixo, todo contaminado) atravessado
por tres TABUAS de um passadico partido. Uma NUVEM DE VENENO fraca vai e vem
a' altura dos pes sobre as tabuas: espera-se a nuvem passar. Quem cai fica
envenenado e sai pelo degrau do outro lado. Uma Mosca Acida guarda o ar.
""")
c.plat("PantanoB", 1150, 1860, BX, h=120, av=480)
c.plat("MuroB1", 1130, 1160, CH, h=200, av=0)
c.solo_toxico("SoloPantanoB", 1160, 1860, BX, veneno=2.6)
c.plat("DegrauB", 1760, 1860, 650, h=60, av=480)
c.plat("TabuaB1", 1240, 1360, CH + 4, h=22, av=34)
c.plat("TabuaB2", 1450, 1560, CH - 24, h=22, av=34)
c.plat("TabuaB3", 1650, 1760, CH + 4, h=22, av=34)
c.assente("PassarelaB", "r12_passarela", 1300, CH + 4, esc=0.9, z=-2, mod=SOMBRA)
c.assente("PonteB", "r12_ponte", 1705, CH + 4, esc=0.9, z=-2, mod=SOMBRA)
c.assente("ArvoreB", "r12_arvore_morta_g", 1580, BX, esc=1.5, z=-6, mod=SOMBRA)
c.assente("MoinhoB", "r12_moinho", 1500, BX, esc=1.7, z=-8, mod="Color(0.4, 0.46, 0.4, 1)")
c.fx("PocaB", "r12_poca_toxica", 1500, BX - 10, esc=2.6, z=-1, mod="Color(0.5, 1, 0.4, 0.45)")
c.nuvem("NuvemB", 1500, CH - 70, larg=240, alt=120, amplitude=170, periodo=7.0)
c.inimigo("MoscaB", 1480, CH - 190, "mosca_acida", "voador", 22, 10, 160, rim=RIM_VERDE)
c.check("CheckB", 1190, CH)
c.gas("GasB", 1500, BX - 4, 700, n=14)

c.plat("ChaoB", 1860, 2330, CH, h=200, av=520)
c.assente("CasasB", "r12_casas", 2090, CH, esc=1.35, z=-5, mod=SOMBRA)
c.assente("RuinasB", "r12_ruinas", 2230, CH, esc=1.2, z=-4, mod=SOMBRA)
c.assente("BandeiraB", "r12_bandeira", 1990, CH, esc=1.0, z=-3)
c.assente("CarrocaB", "r12_carroca", 2150, CH, esc=0.7, z=-1)
c.assente("CranioB", "r12_cranios", 2290, CH, esc=0.5, z=-1)
c.inimigo("RatoB", 2080, CH - 22, "rato_pestilento", "patrulha", 18, 10, 120, rim=RIM_VERDE)
c.zona_limpa("LimpaB", 1990, CH, larg=200, alt=140)
c.assente("ValvulaLimpaB", "r12_valvula_ativa", 1990, CH, esc=0.55, z=-1, mod="Color(0.8, 1, 0.85, 1)")
c.luz("LuzLimpaB", 1990, CH - 70, 0.4, LUZ_LIMPA, (2.0, 1.4))

# ======================================================================
#  C) DESCIDA AO PANTANO (solo alternado, zona limpa, segredo)
# ======================================================================
c.com("""
===================  C) DESCIDA AO PANTANO  ==============================
O chao desce 80 px. Duas poças de solo contaminado alternam com ilhas de
terra firme; no meio, uma ZONA LIMPA onde o veneno passa. Uma Mosca Acida
patrulha a' altura do salto. SEGREDO 1 numa palafita alta sobre a segunda poca.
""")
c.plat("ChaoC", 2330, 3420, BAIXO, h=160, av=520)
c.plat("MuroC0", 2310, 2340, CH, h=180, av=0)
c.assente("ArvoreC1", "r12_arvore_morta_g", 2400, BAIXO, esc=1.4, z=-6, mod=SOMBRA)
c.solo_toxico("SoloC1", 2480, 2750, BAIXO, veneno=2.4)
c.assente("FungosC1", "r12_fungos_g", 2560, BAIXO, esc=0.9, z=-3)
c.assente("PlantaC1", "r12_planta_toxica", 2660, BAIXO, esc=0.6, z=-2)
c.inimigo("RatoC1", 2430, BAIXO - 22, "rato_pestilento", "patrulha", 18, 10, 90, rim=RIM_VERDE)
c.zona_limpa("LimpaC", 2900, BAIXO, larg=220, alt=140)
c.assente("SantuarioC", "r12_santuario", 2900, BAIXO, esc=0.8, z=-3, mod="Color(0.62, 0.78, 0.66, 1)")
c.luz("LuzLimpaC", 2900, BAIXO - 80, 0.45, LUZ_LIMPA, (2.2, 1.6))
c.check("CheckC", 2830, BAIXO)
c.solo_toxico("SoloC2", 3040, 3330, BAIXO, veneno=2.4)
c.assente("FungosC2", "r12_fungos_p", 3110, BAIXO, esc=0.9, z=-3)
c.assente("BarrilC", "r12_barril", 3395, BAIXO, esc=0.55, z=-1)
c.inimigo("MoscaC", 3150, BAIXO - 190, "mosca_acida", "voador", 22, 10, 170, rim=RIM_VERDE)
c.nuvem("NuvemC", 3200, BAIXO - 90, larg=200, alt=110, amplitude=100, periodo=6.0, fase=1.5)
c.com("""SEGREDO 1: palafita a 130 px sobre a poca 2; degrau intermedio a 70 px.""")
c.plat("DegrauSeg1", 3010, 3090, BAIXO - 75, h=22, av=34)
c.plat("SegredoA", 3170, 3300, BAIXO - 140, h=22, av=34)
c.ess("EssenciaSegredoA", 3235, BAIXO - 140, 25)
c.assente("EstacasSegA", "r12_estacas", 3290, BAIXO - 140, esc=0.4, z=-1)
c.gas("GasC", 2900, BAIXO - 4, 1000, n=16)

# ======================================================================
#  D) SAIDA: SUBIDA PARA O POSTO E O ESPREITADOR FUNGICO
# ======================================================================
c.com("""
===================  D) A SAIDA DA FRONTEIRA  ============================
O chao volta a subir (degraus de 40 px) ate' ao posto da saida. Cogumelos
gigantes escondem o ESPREITADOR FUNGICO (elite) que guarda o portao; uma
ultima nuvem fraca e um rato fecham o caminho. Checkpoint antes da emboscada.
""")
c.plat("RampaD1", 3420, 3560, 640, h=160, av=520)
c.plat("RampaD2", 3560, 3700, CH, h=200, av=520)
c.plat("ChaoD", 3700, 4640, CH, h=200, av=520)
c.check("CheckD", 3780, CH)
c.assente("CercaD1", "r12_cerca", 3740, CH, esc=0.85, z=-3)
c.assente("ArvoreD", "r12_arvore_morta_g", 3880, CH, esc=1.4, z=-6, mod=SOMBRA)
c.assente("FungosD1", "r12_fungos_g", 4010, CH, esc=1.1, z=-3)
c.assente("FungosD2", "r12_fungos_g", 4250, CH, esc=1.0, z=-3, flip=True)
c.assente("PlantaD", "r12_planta_toxica", 4130, CH, esc=0.6, z=-2)
c.assente("PalicadaD", "r12_palicada", 4400, CH, esc=1.0, z=-4, mod=SOMBRA)
c.assente("BandeiraD", "r12_bandeira", 4330, CH, esc=1.1, z=-3)
c.assente("CasasD", "r12_casas", 4530, CH, esc=1.4, z=-6, mod=SOMBRA)
c.assente("EstatuaD", "r12_estatua", 3960, CH, esc=0.5, z=-7, mod=SOMBRA)
c.solo_toxico("SoloD", 4020, 4180, CH, veneno=2.2)
c.nuvem("NuvemD", 3880, CH - 60, larg=200, alt=110, amplitude=110, periodo=6.5, fase=3.0)
c.inimigo("RatoD", 3860, CH - 22, "rato_pestilento", "patrulha", 18, 10, 90, rim=RIM_VERDE)
c.inimigo("EspreitadorGuardiao", 4260, CH - 56, "espreitador_fungico", "patrulha", 170, 18, 80,
          rim=RIM_VERDE, elite=True, escala=1.2)
c.luz("LuzPortaD", 4500, CH - 90, 0.9, LUZ_VENENO, (2.4, 1.6))
c.gas("GasD", 4100, CH - 4, 800, n=10)

c.com("""SEGREDO 2: sobre as casas ruinas do fim, por escadas de tabuas.""")
c.plat("TabuaSeg2a", 4380, 4470, CH - 90, h=22, av=34)
c.plat("SegredoB", 4560, 4640, CH - 170, h=22, av=34)
c.ess("EssenciaSegredoB", 4600, CH - 170, 25)

# ======================================================================
#  VIDA DA FRONTEIRA (so' visual)
# ======================================================================
c.esporos("EsporosA", 700, CH - 120, 1000, n=16)
c.esporos("EsporosC", 2900, BAIXO - 120, 1200, n=18)
c.esporos("EsporosD", 4100, CH - 120, 1000, n=14)

# ======================================================================
#  Koliani e porta
# ======================================================================
c.no("Koliani", f"position = {v(170, CH - 40)}\nusar_prototipo_premium = true\n"
                "usar_golden_set = true", inst=c.ator("kol"))
c.no("Porta", f"position = {v(4500, CH - 6)}\npista_ao_atravessar = \"\"", inst=c.ator("porta"))

CAB = """
; REGIAO XII / nivel 56 -- FRONTEIRA CORROMPIDA (`level.n55`), "o primeiro contacto".
; O nome do ficheiro fica (era o Distrito das Engrenagens): mudá-lo partia saves.
;
; GERADO por `tools/construir_n56_fronteira.py` -- editar la', nao aqui.
; Desenho, medicoes e o que ficou por decidir: `docs/nivel_autoral_n56.md`.
;
; Nivel AUTORAL (`corredor = false`). Contrato: cartao do N56 de
; `region_12/master_production_board.png`: A chegada (primeira poca de solo
; contaminado), B posto de fronteira em ruinas (pantano raso, tabuas, nuvem
; de veneno fraca), C descida ao pantano (zona limpa, segredo), D saida
; (Espreitador Fungico elite). 2 segredos, 4 checkpoints.
"""
c.escrever(SAIDA, CAB)
