#!/usr/bin/env python3
"""Gera `scenes/levels/Galeria_dos_Ossos.tscn` -- N17 "Fundicao".

O nome do ficheiro e' LEGADO (era a Galeria dos Ossos); o jogador le' a chave
`level.n16`. EDITAR AQUI e voltar a correr (nao editar o `.tscn` a mao):
    python tools/construir_n17_fundicao.py

Contrato: `docs/art_direction/regions/region_04/level_mechanics.png` (coluna
N17) + `layout_usage.png`: ameacas de lava, plataformas moveis, elevadores de
corrente, rotas a varios niveis, estruturas em colapso; 3 segredos.
Desenho e medicoes: docs/nivel_autoral_n17.md.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from r4_lib import BRASA, Cena, RAIZ, v  # noqa: E402

SAIDA = os.path.join(RAIZ, "scenes", "levels", "Galeria_dos_Ossos.tscn")
c = Cena("Galeria_dos_Ossos", "uid://bkolianigaleriaossos17")

SOMBRA = "Color(0.42, 0.34, 0.36, 1)"
FORNO_LUZ = "Color(1.0, 0.56, 0.22, 1)"
VIVO = "Color(1, 0.7, 0.45, 0.8)"
LOW = 800.0     # chao da fundicao
HIGH = 500.0    # galeria alta (300 px acima)
LAVA_TOPO = LOW + 40
FUNDO = 920.0   # fundo das pocas (a lava fica entre LAVA_TOPO e FUNDO)

c.no("Galeria_dos_Ossos",
     f'script = ExtResource("{c.script("res://scripts/nivel_com_chefe.gd")}")\n'
     "corredor = false\ncandeeiros = false\nalongar_plataformas = false\ncheckpoints_autorais = true\n"
     'mecanica_anunciada = "elevador_coluna"\nestreia_x_autoral = 1930.0',
     tipo="Node2D", pai="")
c.nos[0] = c.nos[0].replace(' parent=""', "")
c.no("Atmosfera", """cor_ambiente = Color(1.0, 0.84, 0.78, 1)
cor_fundo = Color(0.09, 0.03, 0.03, 1)
cor_silhueta = Color(0.14, 0.06, 0.05, 1)
cor_luz = Color(1, 0.6, 0.3, 1)
cor_poeira = Color(1, 0.62, 0.3, 1)
densidade_poeira = 1.8
bioma = "fornalha"
largura_nivel = 5200.0
fundo_pack = "fornalha"
tinta_fundo = Color(1.0, 0.88, 0.82, 1)
neblina_fundo = 0.14
dessaturar_fundo = 0.0
seed_ambiente = 1701
luzes_horizonte = true""", inst=c.cena("res://scenes/fx/Atmosfera.tscn"))


def poca(nome, esq, dir_, muro_esq=True, muro_dir=True):
    """Poca de lava rasa com fundo e paredes que fecham o vao sob as lajes
    vizinhas (licao do N16: sem elas, andar pelo fundo leva ao vazio)."""
    c.lava(nome, esq, dir_, LAVA_TOPO, prof=FUNDO - LAVA_TOPO)
    c.plat("Fundo" + nome, esq, dir_, FUNDO, h=40, av=60)
    c.fumo("Fumo" + nome, (esq + dir_) / 2, LOW + 30, dir_ - esq)
    # degraus de saida (60 px + 60 px em vez de um muro de 120): cair na poca
    # nao pode ser uma armadilha -- licao do bot casual no N17
    if muro_esq:
        c.plat("Degrau" + nome + "E", esq, esq + 70, FUNDO - 60, h=60, av=0)
    if muro_dir:
        c.plat("Degrau" + nome + "D", dir_ - 70, dir_, FUNDO - 60, h=60, av=0)
    if muro_esq:
        c.plat("Muro" + nome + "E", esq - 40, esq, LOW, h=160, av=0)
    if muro_dir:
        c.plat("Muro" + nome + "D", dir_, dir_ + 40, LOW, h=160, av=0)


# ======================================================================
#  A) SALAO DE ENTRADA + PRIMEIRA POCA COM LAJES QUE DESABAM
# ======================================================================
c.com("""
===================  A) SALAO DA FUNDICAO  ==============================
Chao largo; Trabalhador e Lanca-chamas; checkpoint. A seguir a 1.a poca de
lava, atravessada por LAJES QUE DESABAM (0,6 s depois de pisadas, voltam
passados 2,6 s) -- nao se pode parar.
""")
c.plat("ChaoA", 0, 900, LOW, h=70, av=130)
c.assente("PortaoForja", "r4_portao_forja", 150, LOW, esc=1.25, z=-6)
c.fx("BrilhoPortao", "r4_brasas", 150, LOW - 40, esc=1.6, z=-5, mod="Color(1, 0.6, 0.3, 0.7)")
c.assente("ColunaA1", "r4_coluna", 40, LOW, esc=1.3, z=-4, mod=SOMBRA)
c.assente("ColunaA2", "r4_coluna", 300, LOW, esc=1.3, z=-4, mod=SOMBRA)
c.assente("MaquinaA", "r4_maquina", 520, LOW, esc=1.0, z=-4, mod=SOMBRA)
c.assente("BigornaA", "r4_bigorna", 420, LOW, esc=0.7, z=-1)
c.assente("CaldeiraoA", "r4_caldeirao", 760, LOW, esc=0.8, z=-2)
c.assente("BandeiraA", "r4_bandeira", 40, LOW - 240, esc=1.0, z=-3)
c.luz("LuzPortao", 150, LOW - 60, 0.9, FORNO_LUZ, (2.4, 1.6))
c.luz("LuzCaldeiraoA", 760, LOW - 40, 0.8, FORNO_LUZ, (1.6, 1.1))
c.check("CheckInicio", 330, LOW)
c.inimigo("TrabalhadorA", 620, LOW - 50, "trabalhador_corrompido", "patrulha", 40, 12, 110)
c.inimigo("LancaA", 800, LOW - 55, "lanca_chamas", "patrulha", 50, 14, 60)

poca("LavaA", 900, 1500)
for nome, x0, x1 in (("LajeA1", 960, 1070), ("LajeA2", 1160, 1270), ("LajeA3", 1360, 1470)):
    c.quebra(nome, x0, x1, LOW)
c.assente("PistaoA", "r4_pistao_v", 1200, LOW - 20, esc=1.0, z=-6, mod=SOMBRA)
c.fx("QuedaLavaA", "r4_queda_lava", 1200, LOW - 130, esc=1.3, z=-6, mod=VIVO)
c.assente("TuboLavaA", "r4_tubo_lava", 1200, LOW - 300, esc=1.0, z=-5, mod=SOMBRA)

# ======================================================================
#  B) FORNO + ELEVADOR DE CORRENTE PARA A GALERIA ALTA
# ======================================================================
c.com("""
===================  B) FORNO E ELEVADOR  ================================
Chao do forno com piso quente e um Lanca-chamas; no fim, o ELEVADOR DE
CORRENTE (sobe com o peso) leva 300 px ate' a galeria alta.
""")
c.plat("ChaoB", 1500, 2350, LOW, h=70, av=130)
c.check("CheckB", 1570, LOW)
c.assente("FornoB", "r4_forno", 1660, LOW, esc=1.3, z=-5)
c.luz("LuzFornoB", 1660, LOW - 70, 1.0, FORNO_LUZ, (2.6, 1.8))
c.brasas("BrasasFornoB", 1660, LOW - 120, 100, n=14)
c.piso_quente("PisoQuenteB", 1830, LOW, 240, fase=0.0)
c.brasas("BrasasPisoB", 1830, LOW - 6, 240, n=12)
c.inimigo("LancaB", 1700, LOW - 55, "lanca_chamas", "patrulha", 50, 14, 50)
c.assente("ColunaB1", "r4_coluna", 1540, LOW, esc=1.3, z=-4, mod=SOMBRA)
c.assente("ArcoB", "r4_arco_gotico", 2200, LOW, esc=1.7, z=-7, mod=SOMBRA)
# o elevador e' a cena do TumuloElevador com o script ElevadorColuna por cima
ELEV_X = 2080.0
c.no("Elevador1", f'script = ExtResource("{c.script("res://scripts/elevador_coluna.gd")}")\n'
     f"position = {v(ELEV_X, LOW + 8)}\ncurso = {v(0, -300)}\nvelocidade = 95.0\nlargura = 150.0\n"
     "altura_ancora = 150.0\ncor_pedra = Color(0.22, 0.17, 0.17, 1)\ncor_friso = Color(1, 0.45, 0.15, 1)\n"
     f'textura_corrente = ExtResource("{c.tex("r4_corrente_fina")}")\n'
     f'textura_roldana = ExtResource("{c.tex("r4_eng_media")}")\nescala_roldana = 0.22',
     inst=c.ator("elev"))
c.luz("LuzRoldana1", ELEV_X, HIGH - 170, 0.7, FORNO_LUZ, (1.4, 1.2))

# ======================================================================
#  C) GALERIA ALTA SOBRE A POCA GRANDE (carrinhos + jatos) / ROTA BAIXA
# ======================================================================
c.com("""
===================  C) A POCA GRANDE  ===================================
ROTA ALTA: galeria A (Arqueiro) -> dois CARRINHOS DE MINERIO num trilho do
tecto, com dois JATOS DE FOGO nos intervalos (avisam 0,9 s) -> galeria B.
ROTA BAIXA: cair na poca magoa (22 por toque) mas o fundo e' andavel e as
paredes escalam-se: sai-se do outro lado, para o salao inferior.
""")
c.plat("GaleriaA", 2130, 2400, HIGH, h=26, av=40)
c.inimigo("ArqueiroA", 2320, HIGH - 50, "arqueiro_da_fornalha", "cuspidor", 30, 10, 40)
c.check("CheckAlto", 2160, HIGH)
c.assente("ColunaGA", "r4_coluna", 2150, HIGH, esc=0.9, z=-4, mod=SOMBRA)
poca("LavaGrande", 2350, 3150)
for nome, cx, amp, per, fase in (("Carrinho1", 2530, 80, 4.2, 0.0), ("Carrinho2", 2800, 90, 4.8, 2.1)):
    c.no(nome, f"position = {v(cx, HIGH + 9)}\nmodo = \"horizontal\"\namplitude = {amp}.0\n"
         f"periodo = {per}\nfase = {fase}\ncomprimento = 160.0\nlargura = 120.0\npele_terreno = true\n"
         f"ancora_no_trilho = true\ntextura_corrente = ExtResource(\"{c.tex('r4_corrente_fina')}\")",
         inst=c.ator("corr"))
c.mosaico("TrilhoG", "r4_trilho_minerio", 2400, HIGH - 160 - 14, 3020, HIGH - 160 + 14, esc=0.45, z=-2,
          mod="Color(0.85, 0.7, 0.6, 1)")
# jatos de TETO (invertido) nos pontos de transferencia: queimam quem salta
# entre lajes, nunca quem viaja em cima do carrinho
c.jato("Jato1", 2665, HIGH - 175, alcance=175, intervalo=3.0, aviso=0.9, dur=1.3, fase=0.0, invertido=True)
c.jato("Jato2", 2445, HIGH - 175, alcance=175, intervalo=3.0, aviso=0.9, dur=1.3, fase=1.5, invertido=True)
c.fx("QuedaLavaG", "r4_queda_lava", 2750, LOW - 130, esc=1.5, z=-6, mod=VIVO)
c.assente("TuboLavaG", "r4_tubo_lava", 2750, HIGH - 230, esc=1.0, z=-5, mod=SOMBRA)
c.plat("GaleriaB", 3020, 3380, HIGH, h=26, av=40)
c.assente("EstruturaGB", "r4_estrutura", 3200, HIGH, esc=0.9, z=-4, mod=SOMBRA)
c.inimigo("DroneG", 2750, HIGH - 170, "drone_de_lava", "voador", 30, 10, 140)

c.com("""
SEGREDO 1 -- alcova por cima da galeria A (110 px acima; so' se ve' quem
olha para cima). SEGREDO 2 -- saliencia a meio da poca, 200 px abaixo dos
carrinhos: cai-se dos carrinhos e volta-se com salto duplo.
""")
c.plat("DegrauSegA", 2200, 2260, HIGH - 100, h=22, av=40)
c.plat("SegredoA", 2290, 2400, HIGH - 190, h=22, av=40)
c.ess("EssenciaSegredoA", 2345, HIGH - 190, 25)
c.assente("BigornaSegA", "r4_bigorna", 2370, HIGH - 190, esc=0.4, z=-1)
c.plat("SegredoB", 2640, 2730, LOW - 100, h=22, av=40)
c.ess("EssenciaSegredoB", 2685, LOW - 100, 25)
c.plat("DegrauSegB", 2540, 2600, LOW - 40, h=22, av=40)

# ======================================================================
#  SALAO INFERIOR + ELEVADOR 2 (vaivem)
# ======================================================================
c.com("""
===================  D) SALAO INFERIOR  =================================
Quem desce (pelo elevador de vaivem) ou sai da poca chega aqui: piso quente
em fase oposta, Trabalhador, Drone. Segredo 3 numa alcova por cima.
""")
c.plat("ChaoC", 3150, 3950, LOW, h=70, av=130)
ELEV2_X = 3450.0
c.no("Elevador2", f'script = ExtResource("{c.script("res://scripts/elevador_coluna.gd")}")\n'
     f"position = {v(ELEV2_X, HIGH + 8)}\ncurso = {v(0, 300)}\nvelocidade = 80.0\nauto = true\nlargura = 130.0\n"
     "altura_ancora = 170.0\ncor_pedra = Color(0.22, 0.17, 0.17, 1)\ncor_friso = Color(1, 0.45, 0.15, 1)\n"
     f'textura_corrente = ExtResource("{c.tex("r4_corrente_fina")}")\n'
     f'textura_roldana = ExtResource("{c.tex("r4_eng_media")}")\nescala_roldana = 0.22',
     inst=c.ator("elev"))
c.check("CheckC", 3560, LOW)
c.piso_quente("PisoQuenteC", 3730, LOW, 220, fase=1.7)
c.brasas("BrasasPisoC", 3730, LOW - 6, 220, n=10)
c.com("""B1 (plano N1-N20, 3 out 2026; vida dos inimigos dos encontros selados
proposta para 2-3 golpes -- a espada tira 42-95 -- a afinar em playtest) -- SALAO SELADO (DEC-013): quem chega ao
salao inferior fica la' ate' limpar Trabalhador + Lanca-Chamas + Drone, com
o piso quente a ritmar e o elevador de vaivem a passar por dentro.""")
c.arena("ArenaSalao", 3150, 3950, LOW, "arena_n17d")
c.inimigo("TrabalhadorC", 3250, LOW - 50, "trabalhador_corrompido", "patrulha", 110, 12, 70,
          grupos=["arena_n17d"])
c.inimigo("LancaC", 3650, LOW - 55, "lanca_chamas", "patrulha", 120, 14, 60, grupos=["arena_n17d"])
c.inimigo("DroneC", 3800, LOW - 170, "drone_de_lava", "voador", 70, 10, 120, grupos=["arena_n17d"])
c.assente("MaquinaC", "r4_maquina", 3290, LOW, esc=1.0, z=-4, mod=SOMBRA)
c.assente("CaldeiraC", "r4_caldeira", 3860, LOW, esc=1.0, z=-5)
c.luz("LuzCaldeiraC", 3860, LOW - 60, 0.9, FORNO_LUZ, (2.2, 1.6))
c.plat("SegredoC", 3780, 3890, LOW - 110, h=22, av=40)
c.ess("EssenciaSegredoC", 3835, LOW - 110, 25)
c.assente("CaixasSegC", "r4_caixa", 3860, LOW - 110, esc=0.5, z=-1)

# ======================================================================
#  E) ESCADA QUEBRADICA + ARENA DO GUARDIAO
# ======================================================================
c.com("""
===================  E) SAIDA PARA AS CAMARAS  ==========================
Ultima poca: duas lajes que desabam em escada (800 -> 740) e a arena alta
(700): piso quente, jatos desencontrados e o AUTOMATO DE FUNDICAO elite a
guardar o portao.
""")
poca("LavaE", 3950, 4260, muro_esq=False, muro_dir=False)
c.plat("MuroLavaEE", 3910, 3950, LOW, h=160, av=0)
c.quebra("LajeE1", 4010, 4100, LOW)
c.quebra("LajeE2", 4150, 4235, LOW - 55)
c.plat("ChaoE", 4260, 5150, LOW - 100, h=70, av=130)
c.com("""Fim do mundo a toda a altura (ver N16): com a sala do Automato selada a
porta desliga-se; sem parede, quem a passasse caia do fim do nivel.""")
c.plat("MuroFimE", 5150, 5230, LOW - 1500, h=1470, av=0)
c.plat("MuroLavaED", 4260, 4300, LOW - 100, h=260, av=0)
c.check("CheckE", 4330, LOW - 100)
c.piso_quente("PisoQuenteE", 4480, LOW - 100, 220, fase=0.6)
c.brasas("BrasasPisoE", 4480, LOW - 106, 220, n=10)
c.jato("Jato3", 4700, LOW - 100, alcance=210, intervalo=2.8, aviso=0.8, dur=1.2, fase=0.0)
c.jato("Jato4", 4860, LOW - 100, alcance=210, intervalo=2.8, aviso=0.8, dur=1.2, fase=1.4)
c.assente("FornoE", "r4_fornalha", 4380, LOW - 100, esc=1.1, z=-5)
c.luz("LuzFornoE", 4380, LOW - 170, 0.9, FORNO_LUZ, (2.2, 1.6))
c.assente("PrensaE", "r4_prensa", 4790, LOW - 100, esc=1.0, z=-6, mod=SOMBRA)
c.assente("BandeiraE1", "r4_bandeira", 4440, LOW - 400, esc=1.0, z=-3)
c.assente("BandeiraE2", "r4_bandeira", 5060, LOW - 400, esc=1.0, z=-3)
c.com("""B1: a arena do Automato FECHA (e a porta so' abre) quando ele e o
Trabalhador que o acompanha caem -- antes dava para passar por ele a correr.""")
c.arena("ArenaGuardiao", 4300, 5150, LOW - 100, "arena_n17e", sela_porta=True)
c.inimigo("AutomatoGuardiao", 4960, LOW - 100 - 60, "automato_de_fundicao", "patrulha", 340, 18, 60,
          elite=True, escala=1.2, grupos=["arena_n17e"])
c.inimigo("TrabalhadorE", 4600, LOW - 100 - 50, "trabalhador_corrompido", "carga", 110, 12, 80,
          grupos=["arena_n17e"])
c.assente("PortaoSaida", "r4_portao_forja", 5100, LOW - 100, esc=1.2, z=-6)
c.luz("LuzPortaoSaida", 5100, LOW - 180, 1.0, FORNO_LUZ, (2.6, 1.8))
c.fx("BrilhoPortaoSaida", "r4_brasas", 5100, LOW - 140, esc=1.5, z=-5, mod="Color(1, 0.6, 0.3, 0.7)")

# ======================================================================
#  VIDA DA FUNDICAO (so' visual)
# ======================================================================
for i, x in enumerate([600, 1300, 2000, 2900, 3600, 4500]):
    c.corrente(f"CorrenteTeto{i}", x, HIGH - 500, HIGH - 250, z=-7, mod="Color(0.7, 0.5, 0.4, 0.8)")
c.fumo("FumoA", 450, LOW + 10, 700, n=10)
c.fumo("FumoE", 4700, LOW - 90, 700, n=10)

c.no("Koliani", f"position = {v(170, LOW - 40)}\nusar_prototipo_premium = true\n"
                "usar_golden_set = true", inst=c.ator("kol"))
c.no("Porta", f"position = {v(5100, LOW - 106)}\npista_ao_atravessar = \"\"", inst=c.ator("porta"))

CAB = """
; REGIAO IV / nivel 17 -- FUNDICAO (`level.n16`).
; O nome do ficheiro fica (era a Galeria dos Ossos): mudá-lo partia saves.
;
; GERADO por `tools/construir_n17_fundicao.py` -- editar la', nao aqui.
; Desenho, medicoes e o que ficou por decidir: `docs/nivel_autoral_n17.md`.
;
; Nivel AUTORAL (`corredor = false`). Contrato: `region_04/level_mechanics.png`
; (N17): lajes que desabam, elevador de corrente, carrinhos e jatos sobre a
; poca grande (rota alta) com rota baixa pela lava, salao inferior, arena do
; Automato de Fundicao. 3 segredos, 5 checkpoints.
"""
c.escrever(SAIDA, CAB)
