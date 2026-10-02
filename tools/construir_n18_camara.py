#!/usr/bin/env python3
"""Gera `scenes/levels/Cripta_das_Mil_Velas.tscn` -- N18 "Camara da Lava".

O nome do ficheiro e' LEGADO (era a Cripta das Mil Velas): mudá-lo partia
saves e checkpoints; o que o jogador le' e' a chave `level.n17`.

EDITAR AQUI e voltar a correr (nao editar o `.tscn` a mao):
    python tools/construir_n18_camara.py

Contrato LOCKED: `docs/art_direction/regions/region_04/level_mechanics.png`
(coluna N18 "O nivel sobe junto": lava que sobe, plataformas temporarias,
valvulas/jatos, queda sem retorno) + `layout_usage.png` (fluxo A-D, 3 segredos).
Desenho e medicoes: docs/nivel_autoral_n18.md.

Eixo Y para baixo. Chao principal em CH=600; o poco da lava e' fundo (760).
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from r4_lib import BRASA, Cena, RAIZ, v  # noqa: E402

SAIDA = os.path.join(RAIZ, "scenes", "levels", "Cripta_das_Mil_Velas.tscn")
c = Cena("Cripta_das_Mil_Velas", "uid://bkolianicripta18")

SOMBRA = "Color(0.42, 0.34, 0.36, 1)"
FORNO_LUZ = "Color(1.0, 0.56, 0.22, 1)"
CH = 600.0          # chao principal
ARENA = 450.0       # chao da arena do Guardiao (sobe 150 num elevador curto)
LARG = 6800.0


def carrinho(nome, centro, amp, periodo, larg, trilho_x0, trilho_x1):
    """Carrinho de minerio = PlataformaCorrente horizontal presa a um trilho."""
    c.no(nome, f'position = {v(centro, CH + 9)}\nmodo = "horizontal"\namplitude = {amp:g}\n'
         f"periodo = {periodo:g}\ncomprimento = 160.0\nlargura = {larg:g}\npele_terreno = true\n"
         f"ancora_no_trilho = true\n"
         f'textura_corrente = ExtResource("{c.tex("r4_corrente_fina")}")',
         inst=c.ator("corr"))
    c.mosaico("Trilho" + nome, "r4_trilho_minerio", trilho_x0, CH - 174, trilho_x1, CH - 146,
              esc=0.45, z=-2, mod="Color(0.85, 0.7, 0.6, 1)")


def lava_estatica(nome, esq, dir_, chao_topo=720.0):
    c.lava(nome, esq, dir_, CH + 40, prof=chao_topo - (CH + 40))
    c.plat("Fundo" + nome, esq, dir_, chao_topo, h=40, av=60)


def elevador(nome, x, base_topo, curso, larg=130.0, vel=85.0, ancora=130.0):
    c.no(nome, f'position = {v(x, base_topo + 8)}\n'
         f'script = ExtResource("{c.script("res://scripts/elevador_coluna.gd")}")\n'
         f"curso = {v(0, curso)}\nvelocidade = {vel:g}\nauto = true\nlargura = {larg:g}\n"
         f"altura_ancora = {ancora:g}\n"
         "cor_pedra = Color(0.2, 0.15, 0.15, 1)\ncor_friso = Color(1.0, 0.5, 0.18, 1)",
         inst=c.ator("elev"))


# ======================================================================
#  RAIZ + ATMOSFERA
# ======================================================================
c.no("Cripta_das_Mil_Velas",
     f'script = ExtResource("{c.script("res://scripts/nivel_com_chefe.gd")}")\n'
     "corredor = false\ncandeeiros = false\nalongar_plataformas = false\ncheckpoints_autorais = true\n"
     'mecanica_anunciada = "lava_sobe"\nestreia_x_autoral = 1180.0',
     tipo="Node2D", pai="")
c.nos[0] = c.nos[0].replace(' parent=""', "")
c.no("Atmosfera", f"""cor_ambiente = Color(1.0, 0.82, 0.74, 1)
cor_fundo = Color(0.1, 0.03, 0.02, 1)
cor_silhueta = Color(0.16, 0.06, 0.04, 1)
cor_luz = Color(1, 0.55, 0.26, 1)
cor_poeira = Color(1, 0.58, 0.26, 1)
densidade_poeira = 1.8
bioma = "fornalha"
largura_nivel = {LARG:g}
fundo_pack = "fornalha"
tinta_fundo = Color(1.0, 0.86, 0.8, 1)
neblina_fundo = 0.14
dessaturar_fundo = 0.0
seed_ambiente = 1801
luzes_horizonte = true""", inst=c.cena("res://scenes/fx/Atmosfera.tscn"))

# ======================================================================
#  A) O CHAO DITA O RITMO  (0-1480)
# ======================================================================
c.com("""
===================  A) O CHAO DITA O RITMO  ===========================
Chao frio e largo; DOIS pisos quentes desfasados (quando um esta' frio o
outro avisa) -- so' leitura, sem inimigos. Depois um JATO isolado (nunca
colado a um piso), o checkpoint e um Trabalhador. No fim a primeira LAVA QUE
SOBE: uma poca com duas pedras ACIMA da cota maxima -- da' para ver a lava
subir sem arriscar nada.
""")
c.plat("ChaoA", 0, 1130, CH, h=70, av=130)
c.assente("PortaoForja", "r4_portao_forja", 150, CH, esc=1.25, z=-6)
c.fx("BrilhoPortao", "r4_brasas", 150, CH - 40, esc=1.6, z=-5, mod="Color(1, 0.6, 0.3, 0.7)")
c.assente("ColunaA1", "r4_coluna", 40, CH, esc=1.3, z=-4, mod=SOMBRA)
c.assente("ColunaA2", "r4_coluna", 290, CH, esc=1.3, z=-4, mod=SOMBRA)
c.assente("BigornaA", "r4_bigorna", 340, CH, esc=0.7, z=-1)
c.luz("LuzPortao", 150, CH - 60, 0.9, FORNO_LUZ, (2.4, 1.6))
c.piso_quente("PisoA1", 470, CH, 180, fase=0.0)
c.piso_quente("PisoA2", 740, CH, 180, fase=2.5)
c.brasas("BrasasA1", 470, CH - 6, 180, n=10)
c.brasas("BrasasA2", 740, CH - 6, 180, n=10)
c.assente("GrelhaA", "r4_grelha_incandescente", 605, CH, esc=0.5, z=-1)
c.assente("ValvulaA", "r4_valvula_roda", 880, CH, esc=0.45, z=-1)
c.jato("JatoA", 940, CH, alcance=230, intervalo=2.4, aviso=0.8, dur=1.2, fase=1.2)
c.assente("CaixaA", "r4_caixa", 1100, CH, esc=0.7, z=-1)
c.check("CheckA1", 1030, CH)
c.inimigo("TrabalhadorA", 1075, CH - 50, "trabalhador_corrompido", "patrulha", 40, 12, 35)

c.com("""
LAVA QUE SOBE (A): 350 px. Superficie em repouso a 690 (90 abaixo do chao), sobe
110 px ate' 580 (20 acima do chao) em 2,6 s, fica 1,8 s, desce. As pedras estao
a 545/530, FORA do alcance da lava: observar custa zero. A linha de fusao
pisca no AVISO (1,2 s) antes de subir.
""")
LAVA_SOBE = ("sobe_amplitude = {a:g}\nsobe_espera = {e:g}\nsobe_aviso = 1.2\nsobe_subida = {s:g}\n"
             "sobe_topo = {t:g}\nsobe_desce = {d:g}\nsobe_fase = {f:g}\n")


def lava_sobe(nome, esq, dir_, base, chao_topo, amp, espera=3.0, sobe=2.6, topo=1.8, desce=2.4, fase=0.0):
    altura = (chao_topo - base) + amp
    c.no(nome, f"position = {v((esq + dir_) / 2, base + altura / 2)}\nlargura = {dir_ - esq:g}\n"
               f"altura = {altura:g}\ncor = Color(1.0, 0.34, 0.08, 0.93)\nbrasas = true\nletal = false\n"
               f"dano_lava = 20\ntextura_lava = ExtResource(\"{c.tex('r4_lava_estatica')}\")\nz_index = -1\n"
               + LAVA_SOBE.format(a=amp, e=espera, s=sobe, t=topo, d=desce, f=fase).strip(),
         inst=c.ator_lava())
    # o fundo cobre todo o curso da lava (o corpo da lava desce `amp` abaixo do fundo)
    c.plat("Fundo" + nome, esq, dir_, chao_topo, h=amp + 40, av=60)


lava_sobe("LavaA", 1130, 1480, 690, 720, 110)
c.plat("PedraA1", 1190, 1260, 545, h=40, av=70)
c.plat("PedraA2", 1340, 1410, 530, h=40, av=70)
c.assente("MarcadorLavaA", "r4_lava_eruptiva", 1305, 720, esc=0.9, z=-6, mod="Color(1, 0.7, 0.5, 0.85)")
c.assente("ColunaLavaA", "r4_coluna", 1140, CH, esc=1.0, z=-4, mod=SOMBRA)
c.assente("ColunaLavaB", "r4_coluna", 1470, CH, esc=1.0, z=-4, mod=SOMBRA)
c.fumo("FumoLavaA", 1305, 700, 330)

# ======================================================================
#  B) LINHA DE PRODUCAO  (1480-3300)
# ======================================================================
c.com("""
===================  B) LINHA DE PRODUCAO  =============================
B1 carrinho SIMPLES sobre lava estatica (sem inimigos, sem jatos). B2 carrinho
com DOIS jatos dessincronizados: nas pontas do curso o carrinho esta' fora das
colunas de fogo, por isso da' para esperar a bordo ou saltar de volta. B3 duas
LAJES QUE CEDEM (0,7 s) a seguir ao carrinho -- nao se pode ficar parado.
""")
c.plat("ChaoB1", 1480, 1620, CH, h=70, av=130)
c.assente("FornoB", "r4_forno", 1540, CH, esc=1.0, z=-5)
c.luz("LuzFornoB", 1540, CH - 70, 0.9, FORNO_LUZ, (2.2, 1.6))
lava_estatica("LavaB1", 1620, 1900)
carrinho("CarrinhoB1", 1760, 60, 5.0, 140, 1620, 1900)
c.fumo("FumoLavaB1", 1760, CH + 30, 280)
c.assente("TuboB1", "r4_tubo_lava", 1760, CH - 280, esc=0.9, z=-5, mod=SOMBRA)
c.fx("QuedaB1", "r4_queda_lava", 1760, CH - 110, esc=1.2, z=-6, mod="Color(1, 0.7, 0.45, 0.8)")

c.plat("ChaoB2", 1900, 2100, CH, h=70, av=130)
c.inimigo("TrabalhadorB", 2040, CH - 50, "trabalhador_corrompido", "patrulha", 40, 12, 30)
c.assente("ColunaB2", "r4_coluna", 1925, CH, esc=1.2, z=-4, mod=SOMBRA)
c.assente("MinerioB", "r4_minerio_pilha", 2070, CH, esc=0.7, z=-1)

lava_estatica("LavaB2", 2100, 2970)
carrinho("CarrinhoB2", 2370, 150, 7.0, 130, 2100, 2970)
c.jato("JatoB1", 2325, 720, alcance=300, intervalo=2.4, aviso=0.8, dur=1.2, fase=0.0)
c.jato("JatoB2", 2415, 720, alcance=300, intervalo=2.4, aviso=0.8, dur=1.2, fase=2.2)
c.assente("PilarJatoB1", "r4_tubo_reto", 2325, 760, esc=0.6, z=-3, mod=SOMBRA)
c.assente("PilarJatoB2", "r4_tubo_reto", 2415, 760, esc=0.6, z=-3, mod=SOMBRA)
c.fumo("FumoLavaB2", 2530, CH + 30, 800)
c.fx("QuedaB2", "r4_queda_lava", 2560, CH - 120, esc=1.3, z=-6, mod="Color(1, 0.7, 0.45, 0.8)")

c.com("""SEGREDO 1 -- o carrinho no extremo direito deixa a Koliani a 110 px da alcova
(salto duplo). Regresso: cair para a Laje 1.""")
c.plat("SegredoA", 2600, 2670, 490, h=22, av=40)
c.ess("EssenciaSegredoA", 2635, 490, 25)
c.assente("CaixasSegA", "r4_caixa", 2655, 490, esc=0.45, z=-1)

c.quebra("Laje1", 2650, 2740, CH, atraso=0.7, respawn=2.8)
c.quebra("Laje2", 2810, 2900, CH, atraso=0.7, respawn=2.8)

c.plat("ChaoB3", 2970, 3300, CH, h=70, av=130)
c.check("CheckB2", 3030, CH)
c.check("CheckC3", 3250, CH)
c.assente("CaldeiraB", "r4_caldeira", 3110, CH, esc=0.9, z=-5, mod=SOMBRA)
c.assente("BandeiraB", "r4_bandeira", 3000, CH - 260, esc=1.0, z=-3)
c.plat("PlatArqB", 3110, 3230, CH - 100, h=24, av=40)
c.inimigo("ArqueiroB", 3170, CH - 100 - 50, "arqueiro_da_fornalha", "cuspidor", 30, 10, 40)

# ======================================================================
#  C) POCO DA FORNALHA  (3300-4670)
# ======================================================================
c.com("""
===================  C) POCO DA FORNALHA  ==============================
Subida num poco industrial com a LAVA A SUBIR por baixo (repouso 740 -> topo
540, ciclo ~14 s). Elevador E1 SOBE (600 -> 300; vai ate' 210 = SEGREDO 2),
elevador E2 DESCE (300 -> 600). Jatos horizontais saem das paredes (emissor
sempre no ecra). No topo (y=300): patamar -> plataforma quente do meio (piso
cicla, zonas seguras nas pontas, 2 inimigos) -> lajes -> pedra de espera ->
E2 -> saida. Cair = lava no fundo (queda sem retorno): o checkpoint trata.
""")
POCO0, POCO1 = 3300, 4670
lava_sobe("LavaC", POCO0, POCO1, 740, 760, 200, espera=4.0, sobe=3.5, topo=2.0, desce=3.0, fase=0.0)
elevador("ElevadorE1", 3380, CH, -390, ancora=120)
c.luz("LuzRoldanaE1", 3380, CH - 390 - 120 + 8, 0.55, FORNO_LUZ, (1.3, 1.1))
c.jato("JatoParedeE1", 3300, 470, alcance=210, intervalo=2.6, aviso=0.9, dur=1.1, fase=0.0, rot=math.pi / 2)
c.assente("PistaoParede1", "r4_pistao_h", 3290, 495, esc=0.5, z=-4, mod=SOMBRA)

c.plat("LedgeC1", 3470, 3570, 300, h=24, av=40)
c.plat("SegredoB", 3480, 3550, 180, h=22, av=40)
c.ess("EssenciaSegredoB", 3515, 180, 25)
c.assente("BigornaSegB", "r4_bigorna", 3535, 180, esc=0.4, z=-1)

c.plat("PlatC2", 3650, 4030, 300, h=30, av=50)
c.piso_quente("PisoC2", 3840, 300, 140, fase=1.0)
c.brasas("BrasasC2", 3840, 294, 140, n=10)
c.inimigo("TrabalhadorC", 3700, 300 - 50, "trabalhador_corrompido", "patrulha", 40, 12, 35)
c.inimigo("SentinelaC", 3995, 300 - 55, "sentinela_de_pressao", "cuspidor", 50, 12, 0)
c.assente("ValvulaC", "r4_valvula_roda", 3990, 300, esc=0.4, z=-1)

c.quebra("Laje3", 4090, 4170, 300, atraso=0.7, respawn=2.8)
c.quebra("Laje4", 4240, 4320, 300, atraso=0.7, respawn=2.8)
c.plat("PedraEspera", 4370, 4470, 300, h=24, av=40)
elevador("ElevadorE2", 4560, 300, 300, larg=150, ancora=120)
c.luz("LuzRoldanaE2", 4560, 300 - 120 + 8, 0.55, FORNO_LUZ, (1.3, 1.1))
c.jato("JatoParedeE2", 4670, 430, alcance=220, intervalo=2.6, aviso=0.9, dur=1.1, fase=1.4, rot=-math.pi / 2)
c.assente("PistaoParede2", "r4_pistao_h", 4680, 455, esc=0.5, z=-4, mod=SOMBRA, flip=True)
c.assente("MarcadorLavaC", "r4_lava_eruptiva", 4000, 760, esc=1.4, z=-6, mod="Color(1, 0.7, 0.5, 0.8)")
c.fumo("FumoLavaC", 4000, 740, 1000, n=16)
for i, x in enumerate([3420, 3700, 4000, 4300, 4560]):
    c.corrente(f"CorrentePoco{i}", x, 40, 250, z=-7, mod="Color(0.7, 0.5, 0.4, 0.8)")

# ======================================================================
#  D) CAMARA DE PRESSAO  (4670-5870)
# ======================================================================
c.com("""
===================  D) CAMARA DE PRESSAO  =============================
Densa, nao longa: piso quente (decide quando SAIR) -> jato (decide quando
SALTAR) -> duas lajes sobre lava (decide quando ABANDONAR a plataforma) ->
pedra de espera -> elevador curto -> arena. SEGREDO 3 numa plataforma alta
sobre o fim da D1; 3 saltos opcionais, regresso directo a' pedra de espera
(antes do checkpoint do Guardiao).
""")
c.plat("ChaoD1", 4670, 5250, CH, h=70, av=130)
c.check("CheckD4", 4730, CH)
c.piso_quente("PisoD1", 4900, CH, 170, fase=0.0)
c.brasas("BrasasD1", 4900, CH - 6, 170, n=10)
c.jato("JatoD1", 5090, CH, alcance=240, intervalo=2.4, aviso=0.8, dur=1.2, fase=1.0)
c.assente("ColunaD1", "r4_coluna", 4690, CH, esc=1.3, z=-4, mod=SOMBRA)
c.assente("FornoD", "r4_fornalha", 4790, CH, esc=1.0, z=-5)
c.luz("LuzFornoD", 4790, CH - 70, 0.9, FORNO_LUZ, (2.2, 1.6))
c.assente("MaquinaD", "r4_maquina", 5170, CH, esc=0.9, z=-4, mod=SOMBRA)
c.assente("BandeiraD", "r4_bandeira", 5000, CH - 280, esc=1.0, z=-3)

c.com("""SEGREDO 3 -- PlatD1 (500) parece um poleiro; dai' 3 saltos curtos (420, 350, 330).""")
c.plat("PlatD1", 5150, 5230, 500, h=22, av=40)
c.plat("SaltoD1", 5300, 5360, 420, h=22, av=40)
c.plat("SaltoD2", 5420, 5480, 350, h=22, av=40)
c.plat("SegredoC", 5550, 5640, 330, h=22, av=40)
c.ess("EssenciaSegredoC", 5595, 330, 40)
c.assente("CarrinhoSegC", "r4_carrinho_minerio", 5620, 330, esc=0.45, z=-1)

lava_estatica("LavaD", 5250, 5590)
c.quebra("Laje5", 5300, 5380, CH, atraso=0.7, respawn=2.8)
c.quebra("Laje6", 5440, 5520, CH, atraso=0.7, respawn=2.8)
c.fumo("FumoLavaD", 5420, CH + 30, 340)
c.fx("QuedaD", "r4_queda_lava", 5420, CH - 120, esc=1.2, z=-6, mod="Color(1, 0.7, 0.45, 0.8)")

c.plat("PedraD3", 5590, 5690, CH, h=70, av=130)
elevador("ElevadorD", 5780, CH, -150, larg=120, vel=70, ancora=140)
c.luz("LuzRoldanaD", 5780, CH - 150 - 140 + 8, 0.55, FORNO_LUZ, (1.3, 1.1))

# ======================================================================
#  ARENA DO GUARDIAO (5870-6780)
# ======================================================================
c.com("""
===================  ARENA DO GUARDIAO  ================================
Chao a 450. SEGURO | QUENTE | SEGURO | QUENTE | SEGURO. As duas faixas quentes
ciclam em contra-fase (5 s de ciclo, desfasadas 2,5 s: nunca ardem as duas ao
mesmo tempo) e sao propriedade da ARENA -- nada no Guardiao as controla. Pontas
sempre seguras. Guardiao = Automato de Fundicao elite (a confirmar pelo Paulo).
""")
c.plat("ChaoArena", 5870, 6780, ARENA, h=70, av=130)
c.check("CheckD5", 5920, ARENA)
c.piso_quente("PisoArena1", 6125, ARENA, 230, fase=0.0)
c.piso_quente("PisoArena2", 6525, ARENA, 230, fase=2.5)
c.brasas("BrasasArena1", 6125, ARENA - 6, 230, n=12)
c.brasas("BrasasArena2", 6525, ARENA - 6, 230, n=12)
c.inimigo("GuardiaoN18", 6325, ARENA - 70, "automato_de_fundicao", "patrulha", 230, 20, 150,
          elite=True, escala=1.3)
c.assente("ColunaArena1", "r4_coluna", 5890, ARENA, esc=1.3, z=-4, mod=SOMBRA)
c.assente("ArcoArena", "r4_arco_gotico", 6325, ARENA, esc=1.8, z=-7, mod=SOMBRA)
c.assente("BandeiraArena1", "r4_bandeira", 6200, ARENA - 300, esc=1.0, z=-3)
c.assente("BandeiraArena2", "r4_bandeira", 6450, ARENA - 300, esc=1.0, z=-3)
c.assente("PortaoSaida", "r4_portao_forja", 6730, ARENA, esc=1.2, z=-6)
c.luz("LuzPortaoSaida", 6730, ARENA - 80, 1.0, FORNO_LUZ, (2.6, 1.8))
c.fx("BrilhoPortaoSaida", "r4_brasas", 6730, ARENA - 40, esc=1.5, z=-5, mod="Color(1, 0.6, 0.3, 0.7)")
for i, x in enumerate([600, 1700, 2650, 3350, 5000, 6100]):
    c.corrente(f"CorrenteTeto{i}", x, CH - 640, CH - 340, z=-7, mod="Color(0.7, 0.5, 0.4, 0.8)")
c.fumo("FumoA", 450, CH + 10, 700, n=10)
c.fumo("FumoArena", 6300, ARENA + 10, 800, n=10)

# ======================================================================
#  Koliani e porta
# ======================================================================
c.no("Koliani", f"position = {v(170, CH - 40)}\nusar_prototipo_premium = true\n"
                "usar_golden_set = true", inst=c.ator("kol"))
c.no("Porta", f"position = {v(6730, ARENA - 6)}\npista_ao_atravessar = \"\"", inst=c.ator("porta"))

CAB = """
; REGIAO IV / nivel 18 -- CAMARA DA LAVA (`level.n17`), "O nivel sobe junto".
; O nome do ficheiro fica (era a Cripta das Mil Velas): mudá-lo partia saves.
;
; GERADO por `tools/construir_n18_camara.py` -- editar la', nao aqui.
; Desenho, medicoes e o que ficou por decidir: `docs/nivel_autoral_n18.md`.
;
; Nivel AUTORAL (`corredor = false`). Contrato: `region_04/level_mechanics.png`
; (N18) + `layout_usage.png`: A introducao da subida da lava, B plataformas
; temporarias e valvulas/jatos (carrinhos), C salas de pressao e escape (poco
; com elevadores), D saida para a sala das pressoes. 3 segredos, 5 checkpoints,
; Guardiao (nao chefe) na arena de pisos ciclicos.
"""
c.escrever(SAIDA, CAB)
