#!/usr/bin/env python3
"""Gera `scenes/levels/Cemiterio_dos_Reis.tscn` -- N16 "Entrada da Fornalha".

O nome do ficheiro e' LEGADO (era o "Cemiterio dos Reis"): mudá-lo partia
saves e checkpoints; o que o jogador le' e' a chave `level.n15`.

EDITAR AQUI e voltar a correr (nao editar o `.tscn` a mao):
    python tools/construir_n16_entrada.py

Contrato: `docs/art_direction/regions/region_04/level_mechanics.png` (coluna
N16 "O calor comeca a falar") + `layout_usage.png` (fluxo A-D, 2 segredos).
Desenho e medicoes: docs/nivel_autoral_n16.md.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from r4_lib import BRASA, LAVA, METAL, OURO, Cena, RAIZ, v  # noqa: E402

SAIDA = os.path.join(RAIZ, "scenes", "levels", "Cemiterio_dos_Reis.tscn")
c = Cena("Cemiterio_dos_Reis", "uid://bkolianicemiterio16")

ROXO = "Color(0.74, 0.3, 0.5, 1)"
SOMBRA = "Color(0.42, 0.34, 0.36, 1)"     # metal/pedra que recua
FORNO_LUZ = "Color(1.0, 0.56, 0.22, 1)"
CH = 600.0                                   # linha do chao principal

# ======================================================================
#  RAIZ + ATMOSFERA
# ======================================================================
c.no("Cemiterio_dos_Reis",
     f'script = ExtResource("{c.script("res://scripts/nivel_com_chefe.gd")}")\n'
     "corredor = false\ncandeeiros = false\nalongar_plataformas = false\ncheckpoints_autorais = true\n"
     'mecanica_anunciada = "piso_quente"\nestreia_x_autoral = 430.0',
     tipo="Node2D", pai="")
c.nos[0] = c.nos[0].replace(' parent=""', "")
c.no("Atmosfera", """cor_ambiente = Color(1.0, 0.86, 0.8, 1)
cor_fundo = Color(0.09, 0.03, 0.03, 1)
cor_silhueta = Color(0.14, 0.06, 0.05, 1)
cor_luz = Color(1, 0.6, 0.3, 1)
cor_poeira = Color(1, 0.62, 0.3, 1)
densidade_poeira = 1.6
bioma = "fornalha"
largura_nivel = 4600.0
fundo_pack = "fornalha"
tinta_fundo = Color(1.0, 0.9, 0.85, 1)
neblina_fundo = 0.12
dessaturar_fundo = 0.0
seed_ambiente = 1601
luzes_horizonte = true""", inst=c.cena("res://scenes/fx/Atmosfera.tscn"))

# ======================================================================
#  A) ENTRADA  (ensinar: calor, piso que avisa, lava rasa)
# ======================================================================
c.com("""
===================  A) ENTRADA E TUTORIAL DO CALOR  ===================
O Portao da Forja atras de quem chega; chao largo e frio; UM piso quente
no meio do caminho, a mostrar o ciclo (frio / aviso / quente) com folga dos
dois lados; um Trabalhador Corrompido a guardar o fim da sala. A seguir, a
primeira lava: rasa, com degraus de pedra -- cair nela magoa, nao mata.
""")
c.plat("ChaoA", 0, 1000, CH, h=70, av=130)
c.assente("PortaoForja", "r4_portao_forja", 150, CH, esc=1.25, z=-6)
c.fx("BrilhoPortao", "r4_brasas", 150, CH - 40, esc=1.6, z=-5, mod="Color(1, 0.6, 0.3, 0.7)")
c.assente("ColunaA1", "r4_coluna", 40, CH, esc=1.3, z=-4, mod=SOMBRA)
c.assente("ColunaA2", "r4_coluna", 270, CH, esc=1.3, z=-4, mod=SOMBRA)
c.assente("BandeiraA1", "r4_bandeira", 40, CH - 220, esc=1.0, z=-3)
c.assente("BigornaA", "r4_bigorna", 350, CH, esc=0.7, z=-1)
c.assente("BraseiroA", "r4_grelha_incandescente", 600, CH, esc=0.55, z=-1)   # ao lado do piso
c.luz("LuzBraseiroA", 600, CH - 30, 0.8, FORNO_LUZ, (1.4, 1.0))
c.luz("LuzPortao", 150, CH - 60, 0.9, FORNO_LUZ, (2.4, 1.6))
c.assente("CaixaA", "r4_caixa", 880, CH, esc=0.7, z=-1)

c.com("""PISO QUENTE 1 (270 px): o primeiro. 2,4 s frio, 1,0 s a avisar, 1,6 s quente.
Atravessa-se de sobra no frio; a zona fria dos dois lados e' o refugio.""")
c.piso_quente("PisoQuente1", 565, CH, 270, fase=0.0)
c.brasas("BrasasPiso1", 565, CH - 6, 270, n=12)
c.inimigo("TrabalhadorA", 830, CH - 50, "trabalhador_corrompido", "patrulha", 40, 12, 110)
c.check("CheckInicio", 330, CH)

c.com("""
LAVA RASA 1 -- 400 px, com DOIS degraus de pedra a meio. A lava fica 40 px
abaixo do chao e o fundo da poca a 120: cair magoa (22 por toque, repetido)
mas sai-se a saltar. Ensina que a lava e' perigo, nao morte subita.
""")
c.lava("LavaA", 1000, 1400, CH + 40, prof=80)
c.plat("FundoLavaA", 1000, 1400, 720, h=40, av=60)
c.plat("Pedra1", 1070, 1160, CH, h=40, av=70)
c.plat("Pedra2", 1240, 1330, CH - 10, h=40, av=70)
c.assente("ColunaLavaA", "r4_coluna", 1010, CH, esc=1.0, z=-4, mod=SOMBRA)
c.assente("ColunaLavaB", "r4_coluna", 1385, CH, esc=1.0, z=-4, mod=SOMBRA)
c.fx("QuedaLavaA", "r4_queda_lava", 1200, CH - 130, esc=1.15, z=-6, mod="Color(1, 0.7, 0.45, 0.8)")
c.fumo("FumoLavaA", 1200, CH + 30, 380)

# ======================================================================
#  B) PRIMEIROS FORNOS E PLATAFORMAS SOBRE LAVA
# ======================================================================
c.com("""
===================  B) PRIMEIROS FORNOS  ===============================
Sala do forno: um Trabalhador a patrulhar e um ARQUEIRO da Fornalha numa
laje alta (100 px acima, dentro do salto). A seguir, o lago de lava: um
degrau fixo, o CARRINHO DE MINERIO num trilho do tecto (vai e vem) e o chao
do outro lado.
""")
c.plat("ChaoB", 1400, 1900, CH, h=70, av=130)
c.assente("FornoB", "r4_forno", 1560, CH, esc=1.25, z=-5)
c.luz("LuzFornoB", 1560, CH - 70, 1.0, FORNO_LUZ, (2.6, 1.8))
c.fx("ChamaFornoB", "r4_brasas", 1560, CH - 40, esc=1.5, z=-4, mod="Color(1, 0.6, 0.3, 0.8)")
c.brasas("BrasasFornoB", 1560, CH - 120, 100, n=14)
c.assente("ColunaB1", "r4_coluna", 1430, CH, esc=1.3, z=-4, mod=SOMBRA)
c.assente("ArcoB", "r4_arco_gotico", 1700, CH, esc=1.6, z=-7, mod=SOMBRA)
c.assente("BandeiraB", "r4_bandeira", 1660, CH - 280, esc=1.0, z=-3)
c.assente("CarrinhoB", "r4_carrinho_minerio", 1470, CH, esc=0.7, z=-1)
c.assente("MinerioB", "r4_minerio_pilha", 1850, CH, esc=0.8, z=-1)
c.plat("PlatArq", 1700, 1860, CH - 100, h=24, av=40)
c.inimigo("ArqueiroB", 1780, CH - 100 - 50, "arqueiro_da_fornalha", "cuspidor", 30, 10, 60)
c.inimigo("TrabalhadorB", 1560, CH - 50, "trabalhador_corrompido", "patrulha", 40, 12, 90)
c.check("CheckB", 1450, CH)

c.com("""LAGO DE LAVA 2 (520 px) -- lava rasa; degrau fixo + carrinho no trilho.""")
c.lava("LavaB", 1900, 2420, CH + 40, prof=80)
c.plat("FundoLavaB", 1900, 2420, 720, h=40, av=60)
c.plat("PlatL1", 1960, 2060, CH, h=40, av=70)
c.no("Carrinho", f"position = {v(2230, CH + 9)}\nmodo = \"horizontal\"\namplitude = 70.0\n"
     f"periodo = 4.2\ncomprimento = 160.0\nlargura = 120.0\npele_terreno = true\n"
     f"ancora_no_trilho = true\ntextura_corrente = ExtResource(\"{c.tex('r4_corrente_fina')}\")",
     inst=c.ator("corr"))
c.mosaico("TrilhoB", "r4_trilho_minerio", 1900, CH - 160 - 14, 2420, CH - 160 + 14, esc=0.45, z=-2,
          mod="Color(0.85, 0.7, 0.6, 1)")
c.assente("TuboLavaB", "r4_tubo_lava", 2150, CH - 290, esc=1.0, z=-5, mod=SOMBRA)
c.fx("QuedaLavaB", "r4_queda_lava", 2150, CH - 120, esc=1.35, z=-6, mod="Color(1, 0.7, 0.45, 0.85)")
c.fumo("FumoLavaB", 2160, CH + 30, 500)

c.com("""
SEGREDO 1 -- acima do lago: degrau a 110 px do degrau fixo, depois a laje do
segredo. So' se ve' quem olha para cima; o carrinho nao e' preciso.
""")
c.plat("DegrauSeg", 2100, 2170, CH - 110, h=22, av=40)
c.plat("SegredoA", 2230, 2340, CH - 200, h=22, av=40)
c.ess("EssenciaSegredoA", 2285, CH - 200, 25)
c.assente("FornoSegA", "r4_bigorna", 2305, CH - 200, esc=0.45, z=-1)

# ======================================================================
#  C) MAQUINAS SIMPLES + PASSAGEM INFERIOR
# ======================================================================
c.com("""
===================  C) AREA DE MAQUINAS SIMPLES  =======================
Segundo piso quente (outra fase: quando um esta' frio o outro vai a
avisar), Trabalhador e Arqueiro. No fim um vao de 90 px: cai-se na
PASSAGEM INFERIOR -- um tunel por baixo do chao com o SEGREDO 2 a oeste e
a saida em degraus para a sala dos jatos.
""")
c.plat("ChaoC", 2420, 3000, CH, h=70, av=130)
c.check("CheckC", 2470, CH)
c.piso_quente("PisoQuente2", 2710, CH, 280, fase=1.7)
c.brasas("BrasasPiso2", 2710, CH - 6, 280, n=12)
c.assente("ColunaC1", "r4_coluna", 2440, CH, esc=1.3, z=-4, mod=SOMBRA)
c.assente("MaquinaC", "r4_maquina", 2620, CH, esc=1.0, z=-4, mod=SOMBRA)
c.assente("CaldeiraC", "r4_caldeira", 2890, CH, esc=1.0, z=-5, mod=SOMBRA)
c.assente("BandeiraC", "r4_bandeira", 2540, CH - 260, esc=1.0, z=-3)
c.inimigo("TrabalhadorC", 2560, CH - 50, "trabalhador_corrompido", "patrulha", 40, 12, 80)
c.plat("PlatArqC", 2860, 3000, CH - 100, h=24, av=40)
c.inimigo("ArqueiroC", 2930, CH - 100 - 50, "arqueiro_da_fornalha", "cuspidor", 30, 10, 50)

c.com("""TUNEL (passagem inferior): chao a 800, tecto = barriga do ChaoC. Segredo 2
a oeste, vigiado por um Trabalhador. Saida: degrau T1 (700) -> ChaoC2.""")
c.plat("Tunel", 2440, 3090, 800, h=60, av=80)
c.plat("TunelT1", 3010, 3090, 700, h=30, av=40)
c.inimigo("TrabalhadorT", 2700, 800 - 50, "trabalhador_corrompido", "patrulha", 40, 12, 120)
c.plat("SegredoB", 2450, 2560, 800, h=30, av=40)
c.ess("EssenciaSegredoB", 2500, 800, 25)
c.assente("CaixasSegB", "r4_caixa", 2540, 800, esc=0.6, z=-1)
c.assente("CarrinhoSegB", "r4_carrinho_minerio", 2470, 800, esc=0.6, z=-1)
c.luz("LuzTunel", 2600, 740, 0.7, FORNO_LUZ, (2.0, 1.0))
c.luz("LuzTunel2", 2950, 740, 0.6, FORNO_LUZ, (1.6, 1.0))

c.com("""
SALA DOS JATOS: dois jatos de fogo desencontrados (meio ciclo). Entre eles
ha' chao seguro. Cada jato avisa 0,8 s: o bocal brilha e a chama cresce.
""")
c.plat("ChaoC2", 3090, 3500, CH, h=70, av=130)
c.jato("Jato1", 3230, CH, alcance=230, fase=0.0)
c.jato("Jato2", 3390, CH, alcance=230, fase=2.2)
c.assente("CanoJato1", "r4_valvula_roda", 3170, CH, esc=0.45, z=-1)
c.assente("PistaoC", "r4_pistao_h", 3450, CH, esc=0.7, z=-4, mod=SOMBRA)
c.assente("ArcoC", "r4_arco_a", 3310, CH, esc=1.6, z=-8, mod=SOMBRA)

c.com("""LAGO DE LAVA 3 (360 px): o carrinho de minerio do fim -- amplitude maior.""")
c.lava("LavaC", 3500, 3860, CH + 40, prof=80)
c.plat("FundoLavaC", 3500, 3860, 720, h=40, av=60)
c.no("Carrinho2", f"position = {v(3680, CH + 9)}\nmodo = \"horizontal\"\namplitude = 100.0\n"
     f"periodo = 4.6\ncomprimento = 160.0\nlargura = 130.0\npele_terreno = true\n"
     f"ancora_no_trilho = true\ntextura_corrente = ExtResource(\"{c.tex('r4_corrente_fina')}\")",
     inst=c.ator("corr"))
c.mosaico("TrilhoC", "r4_trilho_minerio", 3500, CH - 160 - 14, 3860, CH - 160 + 14, esc=0.45, z=-2,
          mod="Color(0.85, 0.7, 0.6, 1)")
c.fx("QuedaLavaC", "r4_queda_lava", 3680, CH - 120, esc=1.3, z=-6, mod="Color(1, 0.7, 0.45, 0.8)")
c.fumo("FumoLavaC", 3680, CH + 30, 340)

# ======================================================================
#  D) SAIDA PARA A FUNDICAO
# ======================================================================
c.com("""
===================  D) SAIDA PARA A FUNDICAO  ==========================
Checkpoint antes do guardiao. Piso quente a abrir a sala, e o OPERARIO
BLINDADO (elite, escudo a' frente -- fraco nas costas) a guardar o portao.
""")
c.plat("ChaoD", 3860, 4560, CH, h=70, av=130)
c.check("CheckD", 3930, CH)
c.piso_quente("PisoQuente3", 4120, CH, 220, fase=0.6)
c.brasas("BrasasPiso3", 4120, CH - 6, 220, n=10)
c.assente("ColunaD1", "r4_coluna", 3890, CH, esc=1.3, z=-4, mod=SOMBRA)
c.assente("FornoD", "r4_fornalha", 4010, CH, esc=1.1, z=-5)
c.luz("LuzFornoD", 4010, CH - 70, 0.9, FORNO_LUZ, (2.2, 1.6))
c.assente("BandeiraD1", "r4_bandeira", 4290, CH - 300, esc=1.0, z=-3)
c.assente("BandeiraD2", "r4_bandeira", 4480, CH - 300, esc=1.0, z=-3)
c.inimigo("OperarioGuardiao", 4360, CH - 60, "operario_blindado", "escudeiro", 170, 18, 70,
          elite=True, escala=1.25)
c.assente("PortaoSaida", "r4_portao_forja", 4500, CH, esc=1.2, z=-6)
c.luz("LuzPortaoSaida", 4500, CH - 80, 1.0, FORNO_LUZ, (2.6, 1.8))
c.fx("BrilhoPortaoSaida", "r4_brasas", 4500, CH - 40, esc=1.5, z=-5, mod="Color(1, 0.6, 0.3, 0.7)")

# ======================================================================
#  VIDA DA FORNALHA -- fumo, brasas e correntes (so' visual)
# ======================================================================
for i, x in enumerate([700, 1800, 2650, 3350, 4150]):
    c.corrente(f"CorrenteTeto{i}", x, CH - 620, CH - 330, z=-7, mod="Color(0.7, 0.5, 0.4, 0.8)")
c.fumo("FumoA", 450, CH + 10, 700, n=10)
c.fumo("FumoD", 4200, CH + 10, 700, n=10)

# ======================================================================
#  Koliani e porta
# ======================================================================
c.no("Koliani", f"position = {v(170, CH - 40)}\nusar_prototipo_premium = true\n"
                "usar_golden_set = true", inst=c.ator("kol"))
c.no("Porta", f"position = {v(4500, CH - 6)}\npista_ao_atravessar = \"\"", inst=c.ator("porta"))

CAB = """
; REGIAO IV / nivel 16 -- ENTRADA DA FORNALHA (`level.n15`), "O calor comeca a falar".
; O nome do ficheiro fica (era o Cemiterio dos Reis): mudá-lo partia saves.
;
; GERADO por `tools/construir_n16_entrada.py` -- editar la', nao aqui.
; Desenho, medicoes e o que ficou por decidir: `docs/nivel_autoral_n16.md`.
;
; Nivel AUTORAL (`corredor = false`). Contrato: `region_04/level_mechanics.png`
; (N16) + `layout_usage.png`: A entrada e tutorial (piso quente e lava rasa),
; B primeiros fornos e plataformas (carrinho de minerio sobre lava), C area
; de maquinas simples (segundo piso quente, jatos de fogo, passagem inferior),
; D saida para a fundicao (Operario Blindado elite a guardar o portao).
; 2 segredos, 4 checkpoints.
"""

c.com("""PAREDES DOS LAGOS: sem elas, quem cai na lava e anda ate' ao fim do chao do
lago passava por baixo do ChaoB/ChaoC2/ChaoD e caia no vazio (o bot experiente
caiu 3x em x=1630). Cada parede fecha o vao entre a barriga da laje e o fundo.
O lado leste do lago B fica aberto de proposito: dai' entra-se no tunel.""")
for nome, x0, x1 in (("MuroA", 960, 1000), ("MuroB1", 1400, 1440), ("MuroB2", 1860, 1900),
		("MuroC1", 3460, 3500), ("MuroD", 3860, 3900)):
	c.plat(nome, x0, x1, CH, h=160, av=0)

c.escrever(SAIDA, CAB)
