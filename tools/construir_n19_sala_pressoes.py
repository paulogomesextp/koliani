#!/usr/bin/env python3
"""Gera `scenes/levels/Templo_da_Serpente.tscn` -- N19 "Sala das Pressoes".

O nome do ficheiro e' LEGADO (era o Templo da Serpente; o indice 18 de
`EstadoJogo.NIVEIS`): mudá-lo partia saves; o que o jogador le' e' a chave
`level.n18`. EDITAR AQUI e voltar a correr (nunca no `.tscn`):
    python tools/construir_n19_sala_pressoes.py

Contrato LOCKED: `docs/art_direction/regions/region_04/level_mechanics.png`
(coluna N19 "Sala das Pressoes -- ritmo, tempo, sobrevivencia": jatos de fogo
telegraficos, pistoes esmagadores, valvulas de pressao, plataformas
sincronizadas) + `layout_usage.png` (A jatos e timing, B plataformas de
precisao, C pressao variavel, D saida para o nucleo; 3 segredos, combate 50%).
Desenho, medicoes e o que ficou por decidir: docs/nivel_autoral_n19.md.

Eixo Y para baixo. Chao principal em CH=600. Todos os ciclos contam desde o
arranque do nivel (`relogio_local`): reaparecer repete SEMPRE o mesmo ritmo, e
pistoes, jatos e plataformas ficam em sincronia exacta (mesmo relogio).

Este ficheiro tambem verifica, ao gerar, que cada travessia critica tem uma
janela segura (modelo puro dos ciclos, o mesmo que o teste do Godot repete com
os scripts reais): se uma travessia ficar apertada demais, a geracao falha.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from r4_lib import BRASA, Cena, RAIZ, v  # noqa: E402

SAIDA = os.path.join(RAIZ, "scenes", "levels", "Templo_da_Serpente.tscn")
c = Cena("Templo_da_Serpente", "uid://bkolianitemploserpente19")

SOMBRA = "Color(0.42, 0.34, 0.36, 1)"
FORNO_LUZ = "Color(1.0, 0.56, 0.22, 1)"
GELO = "Color(0.45, 0.8, 1.0, 1)"      # valvulas das PLATAFORMAS
FOGO = "Color(1.0, 0.5, 0.2, 1)"       # valvulas dos PERIGOS
CH = 600.0
LARG = 6740.0

# ---------------------------------------------------------------------------
#  MODELO PURO DOS CICLOS (espelha scripts/pistao_fornalha.gd e jato_fornalha.gd)
# ---------------------------------------------------------------------------
VEL = 240.0           # corrida da Koliani (px/s)
MEIA_KOLIANI = 14.0   # meia largura do corpo


class Pistao:
    def __init__(self, x, rep, aviso, ext, perm, ret, fase, larg=78.0):
        self.x, self.rep, self.aviso, self.ext, self.perm, self.ret = x, rep, aviso, ext, perm, ret
        self.fase, self.larg = fase, larg
        self.meia = larg * 0.86 * 0.5 + MEIA_KOLIANI
        self.ciclo = rep + aviso + ext + perm + ret

    def frac(self, t):
        p = (t + self.fase) % self.ciclo
        if p < self.rep + self.aviso:
            return 0.0
        p -= self.rep + self.aviso
        if p < self.ext:
            k = p / self.ext
            return k * k
        p -= self.ext
        if p < self.perm:
            return 1.0
        p -= self.perm
        k = min(max(p / self.ret, 0.0), 1.0)
        return 1.0 - k * k * (3.0 - 2.0 * k)

    def perigo(self, t):
        return self.frac(t) > 0.25


class Jato:
    def __init__(self, x, interv, aviso, dur, fase):
        self.x, self.interv, self.aviso, self.dur, self.fase = x, interv, aviso, dur, fase
        self.meia = 23.0 + MEIA_KOLIANI
        self.ciclo = interv + aviso + dur

    def perigo(self, t):
        return (t + self.fase) % self.ciclo >= self.interv + self.aviso


H = {}   # nome -> Pistao/Jato


def janela(hazards, x0, x1, horizonte=70.0, dt=0.02):
    """Maior janela contigua (s) de instantes de PARTIDA em que uma travessia a
    velocidade constante de x0 a x1 nao toca em nenhum perigo."""
    hs = [H[n] for n in hazards]
    sentido = 1.0 if x1 >= x0 else -1.0
    dur = abs(x1 - x0) / VEL
    n = int(horizonte / dt)
    seguro = []
    for i in range(n):
        t0 = i * dt
        ok = True
        j = 0.0
        while j <= dur:
            x = x0 + sentido * VEL * j
            for h in hs:
                if abs(x - h.x) < h.meia and h.perigo(t0 + j):
                    ok = False
                    break
            if not ok:
                break
            j += dt
        seguro.append(ok)
    melhor = atual = 0
    for s in seguro + seguro[:200]:     # volta ao principio (periodico)
        atual = atual + 1 if s else 0
        melhor = max(melhor, atual)
    return min(melhor, n) * dt


CRUZAMENTOS = []   # (nome, hazards, x0, x1, min_janela_s)


def pis(nome, x, fase=0.0, rep=2.2, aviso=0.9, ext=0.22, perm=0.8, ret=0.7, grupo="",
        retoma=-1.0, efeito="pausa", chao=CH):
    H[nome] = Pistao(x, rep, aviso, ext, perm, ret, fase)
    c.pistao(nome, x, chao, rep=rep, aviso=aviso, ext=ext, perm=perm, ret=ret, fase=fase,
             grupo=grupo, fase_retoma=retoma, efeito=efeito)
    # a cabeca (o pistao) pendura de uma corrente do tecto
    c.corrente("Corr" + nome, x, chao - 640, chao - 345, z=-7, mod="Color(0.7, 0.5, 0.4, 0.8)")


def jat(nome, x, y, alcance, interv, aviso, dur, fase=0.0, grupo="", retoma=-1.0):
    H[nome] = Jato(x, interv, aviso, dur, fase)
    c.jato_n19(nome, x, y, alcance, interv, aviso, dur, fase=fase, grupo=grupo, fase_retoma=retoma)


def pit(nome, esq, dir_, fundo=720.0):
    """Fosso de lava (nao letal: 20 de dano e da' para sair) com os muros que
    fecham o vao sob as pontas do chao (o defeito que o N16/N18 ensinaram)."""
    c.lava(nome, esq, dir_, CH + 40, prof=fundo - (CH + 40))
    c.plat("Fundo" + nome, esq, dir_, fundo, h=40, av=60)
    c.plat("Muro" + nome + "a", esq - 40, esq, CH, h=790 - CH, av=0)
    c.plat("Muro" + nome + "b", dir_, dir_ + 40, CH, h=790 - CH, av=0)


# ======================================================================
#  RAIZ + ATMOSFERA
# ======================================================================
c.no("Templo_da_Serpente",
     f'script = ExtResource("{c.script("res://scripts/nivel_com_chefe.gd")}")\n'
     "corredor = false\ncandeeiros = false\nalongar_plataformas = false\ncheckpoints_autorais = true\n"
     'mecanica_anunciada = "pistao"\nestreia_x_autoral = 480.0',
     tipo="Node2D", pai="")
c.nos[0] = c.nos[0].replace(' parent=""', "")
c.no("Atmosfera", f"""cor_ambiente = Color(1.0, 0.8, 0.72, 1)
cor_fundo = Color(0.1, 0.03, 0.02, 1)
cor_silhueta = Color(0.16, 0.06, 0.04, 1)
cor_luz = Color(1, 0.55, 0.26, 1)
cor_poeira = Color(1, 0.58, 0.26, 1)
densidade_poeira = 1.6
bioma = "fornalha"
largura_nivel = {LARG:g}
fundo_pack = "fornalha"
tinta_fundo = Color(1.0, 0.84, 0.78, 1)
neblina_fundo = 0.16
dessaturar_fundo = 0.0
seed_ambiente = 1901
luzes_horizonte = true""", inst=c.cena("res://scenes/fx/Atmosfera.tscn"))

# ======================================================================
#  A) PRESSAO VISIVEL  (0-1500)
# ======================================================================
c.com("""
===================  A) PRESSAO VISIVEL  ===============================
So' chao, pistoes e (no fim) um jato -- nada de inimigos, lava ou valvulas.
A1: um pistao LENTO (6,4 s de ciclo, 1 s de aviso), sozinho e a' vista de quem
nasce. A2: dois pistoes em CONTRATEMPO com uma ilha segura no meio (um fecha
quando o outro abre). A3: pistao + jato no mesmo relogio -- a primeira vez que
se le' a maquina inteira. CP1 so' depois, em chao seguro.
""")
c.plat("ChaoA", 0, 1500, CH, h=70, av=130)
c.assente("PortaoForja", "r4_portao_forja", 150, CH, esc=1.25, z=-6)
c.fx("BrilhoPortao", "r4_brasas", 150, CH - 40, esc=1.6, z=-5, mod="Color(1, 0.6, 0.3, 0.7)")
c.assente("ColunaA1", "r4_coluna", 40, CH, esc=1.3, z=-4, mod=SOMBRA)
c.assente("ColunaA2", "r4_coluna", 330, CH, esc=1.3, z=-4, mod=SOMBRA)
c.luz("LuzPortao", 150, CH - 60, 0.9, FORNO_LUZ, (2.4, 1.6))
c.assente("CaixaA", "r4_caixa", 400, CH, esc=0.7, z=-1)
c.assente("TuboA1", "r4_tubo_reto", 700, CH - 120, esc=0.9, z=-5, mod=SOMBRA)

pis("PistaoA1", 560, fase=0.6, rep=3.0, aviso=1.0, ext=0.25, perm=1.1, ret=1.0)
CRUZAMENTOS.append(("A1", ["PistaoA1"], 440, 700, 2.5))
c.assente("ValvulaDecA", "r4_valvula_int", 690, CH, esc=0.45, z=-2, mod=SOMBRA)

pis("PistaoA2", 800)
pis("PistaoA3", 1010, fase=2.41)
CRUZAMENTOS.append(("A2a", ["PistaoA2"], 700, 905, 1.5))
CRUZAMENTOS.append(("A2b", ["PistaoA3"], 905, 1105, 1.5))
c.assente("GrelhaA", "r4_grelha_incandescente", 905, CH, esc=0.5, z=-1)
c.assente("ManometroA", "r4_eng_media", 905, CH - 250, esc=0.7, z=-6, mod="Color(0.8, 0.6, 0.5, 0.9)")

pis("PistaoA4", 1200)
jat("JatoA", 1385, CH, 230, 2.0, 0.8, 2.02, fase=0.62)
CRUZAMENTOS.append(("A3a", ["PistaoA4"], 1105, 1292, 1.5))
CRUZAMENTOS.append(("A3b", ["JatoA"], 1292, 1470, 1.2))
c.assente("PilarJatoA", "r4_tubo_reto", 1385, CH + 40, esc=0.6, z=-3, mod=SOMBRA)
c.assente("MaquinaA", "r4_maquina", 1330, CH, esc=0.9, z=-4, mod=SOMBRA)
c.check("CheckA1", 1465, CH)
c.fumo("FumoA", 700, CH + 10, 900, n=10)

# ======================================================================
#  B) PRIMEIRA VALVULA  (1500-2900)
# ======================================================================
c.com("""
===================  B) A PRIMEIRA VALVULA  ============================
O corredor B1 (dois pistoes DESENCONTRADOS + um jato quase sempre aceso) esta'
a' vista antes da valvula V1, que desliga o conjunto 10 s: causa e efeito. A
`StepB1` (plataforma que so' existe com a valvula aberta) leva ao SEGREDO 1:
a maquina mudou e o jogador atento repara. B2: um fosso com 3 plataformas
ritmadas em onda; a valvula V2 mantem-nas SOLIDAS 9 s. Ninguem e' obrigado a
usar as valvulas -- so' sai mais caro sem elas.
""")
c.plat("ChaoB1", 1500, 2440, CH, h=70, av=130)
c.valvula("ValvulaB1", 1620, CH, "b1", janela=10.0, aviso_fim=2.0, cor=FOGO)
c.assente("ColunaB1", "r4_coluna", 1560, CH, esc=1.2, z=-4, mod=SOMBRA)
c.assente("TuboV1", "r4_tubo_l", 1670, CH - 130, esc=0.6, z=-5, mod=SOMBRA)
c.luz("LuzV1", 1620, CH - 50, 0.7, "Color(1.0, 0.5, 0.25, 1)", (1.4, 1.1))

c.com("""SEGREDO 1 -- a StepB1 so' existe com a valvula V1 aberta (10 s): sobe-se
para a alcova a 175 px. Regresso: cair para o chao.""")
c.ritmada("StepB1", 1745, 1805, 510, solida=4.0, fantasma=1.0, grupo="b1", efeito="so_aberta",
          aviso=0.8)
c.plat("SegredoA", 1835, 1915, 425, h=22, av=40)
c.ess("EssenciaSegredoA", 1875, 425, 25)
c.assente("CaixasSegA", "r4_caixa", 1895, 425, esc=0.45, z=-1)

pis("PistaoB1", 2060, fase=0.0, grupo="b1", retoma=0.0)
pis("PistaoB2", 2170, fase=2.41, grupo="b1", retoma=1.4)
jat("JatoB", 2300, CH, 230, 0.6, 0.6, 3.62, fase=0.3, grupo="b1", retoma=0.0)
CRUZAMENTOS.append(("B1", ["PistaoB1", "PistaoB2", "JatoB"], 1985, 2360, 0.0))   # sem valvula: dificil
c.assente("PilarJatoB", "r4_tubo_reto", 2300, CH + 40, esc=0.6, z=-3, mod=SOMBRA)
c.assente("MaquinaB", "r4_maquina", 2110, CH, esc=0.9, z=-4, mod=SOMBRA)
c.fumo("FumoB1", 2150, CH + 10, 600, n=10)

c.valvula("ValvulaB2", 2390, CH, "b2", janela=9.0, aviso_fim=2.0, cor=GELO)
c.assente("ColunaB2", "r4_coluna", 2420, CH, esc=1.2, z=-4, mod=SOMBRA)
pit("LavaB2", 2440, 2900)
# NB: a Koliani mede 20 px de largura -- nenhuma fresta entre 14 e 34 px (entala);
# aqui 40 / 36 / 48 px
for i, (e, d) in enumerate([(2480, 2580), (2616, 2716), (2752, 2852)]):
    c.ritmada(f"RitmadaB{i + 1}", e, d, CH, solida=1.2, fantasma=2.4, fase=[0.0, 0.75, 0.5][i],
              grupo="b2", efeito="solida", aviso=0.5)
c.fumo("FumoLavaB2", 2670, CH + 30, 460)
c.fx("QuedaB2", "r4_queda_lava", 2670, CH - 110, esc=1.3, z=-6, mod="Color(1, 0.7, 0.45, 0.8)")
c.assente("MarcadorLavaB", "r4_lava_eruptiva", 2670, 720, esc=0.9, z=-6, mod="Color(1, 0.7, 0.5, 0.8)")

# ======================================================================
#  C) MAQUINA SINCRONIZADA  (2900-4700)
# ======================================================================
c.com("""
===================  C) MAQUINA SINCRONIZADA  ==========================
C1: V3 (laranja = PERIGOS) desliga dois pistoes desencontrados e um jato 8 s.
CP3 so' depois. C2 (travessia em movimento): fosso de 670 px com 4 ritmadas e
uma ilha segura; V4 (azul = PLATAFORMAS) segura-as 11 s, mas o pistao sobre a
RC2 e o jato do fundo do fosso continuam a bater: ritmada -> pistao -> ilha ->
jato -> ritmada. SEGREDO 2: com V4 aberta aparece uma escada ate' uma alcova.
C4: pequeno encontro (arqueiro + trabalhador) com a coluna como abrigo. CP4 a'
entrada da Sala das Pressoes.
""")
c.plat("ChaoC0", 2900, 3640, CH, h=70, av=130)
c.check("CheckB2", 2960, CH)
c.assente("CaldeiraC", "r4_caldeira", 3010, CH, esc=0.9, z=-5, mod=SOMBRA)
c.valvula("ValvulaC1", 3080, CH, "c1", janela=8.0, aviso_fim=2.0, cor=FOGO)
c.assente("BandeiraC", "r4_bandeira", 3000, CH - 260, esc=1.0, z=-3)
pis("PistaoC1", 3230, fase=0.0, grupo="c1", retoma=0.0)
pis("PistaoC2", 3320, fase=2.41, grupo="c1", retoma=1.4)
jat("JatoC1", 3450, CH, 230, 0.6, 0.6, 3.62, fase=0.0, grupo="c1", retoma=0.0)
CRUZAMENTOS.append(("C1", ["PistaoC1", "PistaoC2", "JatoC1"], 3150, 3520, 0.0))
c.assente("PilarJatoC", "r4_tubo_reto", 3450, CH + 40, esc=0.6, z=-3, mod=SOMBRA)
c.assente("MaquinaC", "r4_maquina", 3270, CH, esc=0.9, z=-4, mod=SOMBRA)
c.fumo("FumoC1", 3300, CH + 10, 700, n=10)
c.check("CheckC3", 3540, CH)

c.valvula("ValvulaC2", 3600, CH, "c2", janela=11.0, aviso_fim=2.0, cor=GELO)
pit("LavaC2", 3640, 4350)
for nome, e, d in [("RitmadaC1", 3680, 3760), ("RitmadaC2", 3796, 3886), ("RitmadaC3", 4112, 4192),
                   ("RitmadaC4", 4228, 4308)]:
    c.ritmada(nome, e, d, CH, solida=1.2, fantasma=2.4,
              fase={"RitmadaC1": 0.0, "RitmadaC2": 0.75, "RitmadaC3": 0.5, "RitmadaC4": 0.25}[nome],
              grupo="c2", efeito="solida", aviso=0.5)
pis("PistaoC3", 3866, fase=1.5)                               # sobre a RC2 (nao governado)
c.plat("IlhaC", 3922, 4004, CH, h=22, av=34)
jat("JatoC2", 4058, 720, 300, 1.6, 0.8, 2.42, fase=0.0)       # sobe do fundo do fosso
CRUZAMENTOS.append(("C2a", ["PistaoC3"], 3796, 3960, 1.0))
CRUZAMENTOS.append(("C2b", ["JatoC2"], 3960, 4150, 1.0))
c.fumo("FumoLavaC2", 3995, CH + 30, 700, n=14)
c.fx("QuedaC2", "r4_queda_lava", 3995, CH - 110, esc=1.3, z=-6, mod="Color(1, 0.7, 0.45, 0.8)")

c.com("""SEGREDO 2 -- a StepC so' existe com a valvula V4 aberta: escada ate' a alcova
(425). Regresso: cair para a RC1/RC2 (ou para o fosso, que e' nao letal).""")
c.ritmada("StepC", 3672, 3727, 510, solida=4.0, fantasma=1.0, grupo="c2", efeito="so_aberta", aviso=0.8)
c.plat("SegredoB", 3734, 3794, 425, h=22, av=40)
c.ess("EssenciaSegredoB", 3764, 425, 25)

c.plat("ChaoC3", 4350, 4900, CH, h=70, av=130)
c.assente("ColunaC3", "r4_coluna", 4560, CH, esc=1.8, z=-1, mod=SOMBRA)
c.plat("PlatArqC", 4660, 4780, CH - 100, h=24, av=40)
c.inimigo("ArqueiroC", 4720, CH - 100 - 50, "arqueiro_da_fornalha", "cuspidor", 30, 10, 40)
c.inimigo("TrabalhadorC", 4470, CH - 50, "trabalhador_corrompido", "patrulha", 40, 12, 40)
c.check("CheckC4", 4850, CH)
c.assente("FornoC", "r4_forno", 4380, CH, esc=1.0, z=-5)
c.luz("LuzFornoC", 4380, CH - 70, 0.9, FORNO_LUZ, (2.2, 1.6))

# ======================================================================
#  D) SALA DAS PRESSOES  (4900-5700)
# ======================================================================
c.com("""
===================  D) SALA DAS PRESSOES  =============================
Entrada segura com a valvula principal V5 e uma vista da sala inteira. Sem a
valvula: pistoes DESENCONTRADOS, jato aceso, plataformas em onda. Com V5
(12 s): as ritmadas ficam solidas, o jato adormece e os pistoes ENTRAM EM FASE
(abrem e fecham juntos, deixando uma so' janela larga). Pistao -> ritmada ->
ilha -> jato -> ritmadas -> dois pistoes -> saida, com ilhas seguras entre os
blocos criticos. SEGREDO 3: V5 faz aparecer a StepD ate' uma alcova sobre o
fosso (esperar na entrada em vez de correr).
""")
c.plat("ChaoD0", 4900, 5160, CH, h=70, av=130)
D0 = 5160
c.valvula("ValvulaD", 5040, CH, "d", janela=12.0, aviso_fim=2.0, cor=GELO)
c.assente("ColunaD0", "r4_coluna", 4930, CH, esc=1.3, z=-4, mod=SOMBRA)

c.com("""SEGREDO 3 -- StepD (so' com V5 aberta) -> alcova SegredoC sobre o fosso.""")
c.ritmada("StepD", 5090, 5150, 510, solida=5.0, fantasma=1.0, grupo="d", efeito="so_aberta", aviso=0.8)
c.plat("SegredoC", 5170, 5250, 425, h=22, av=40)
c.ess("EssenciaSegredoC", 5210, 425, 40)

pit("LavaD", D0, 5972)
# bloco D-a: pistao sobre a RD2
c.ritmada("RitmadaD1", 5200, 5280, CH, solida=1.4, fantasma=2.2, fase=0.0, grupo="d")
c.ritmada("RitmadaD2", 5316, 5406, CH, solida=1.4, fantasma=2.2, fase=0.5, grupo="d")
pis("PistaoD1", 5380, fase=0.0, rep=3.2, grupo="d", retoma=0.0, efeito="ressincroniza")
c.plat("IlhaD1", 5442, 5527, CH, h=22, av=34)
# bloco D-b: jato no vao
jat("JatoD1", 5583, 720, 300, 1.4, 0.8, 3.62, fase=0.0, grupo="d", retoma=0.0)
c.ritmada("RitmadaD3", 5640, 5720, CH, solida=1.4, fantasma=2.2, fase=0.0, grupo="d")
# bloco D-c: dois pistoes adjacentes, em contratempo (sem valvula) / em fase (com)
c.ritmada("RitmadaD4", 5756, 5826, CH, solida=1.4, fantasma=2.2, fase=0.5, grupo="d")
c.ritmada("RitmadaD5", 5862, 5932, CH, solida=1.4, fantasma=2.2, fase=0.0, grupo="d")
pis("PistaoD2", 5791, fase=0.0, rep=3.2, grupo="d", retoma=0.0, efeito="ressincroniza")
pis("PistaoD3", 5897, fase=2.91, rep=3.2, grupo="d", retoma=0.0, efeito="ressincroniza")
c.fumo("FumoLavaD", 5566, CH + 30, 800, n=14)
c.fx("QuedaD", "r4_queda_lava", 5566, CH - 110, esc=1.4, z=-6, mod="Color(1, 0.7, 0.45, 0.8)")
c.assente("MarcadorLavaD", "r4_lava_eruptiva", 5566, 720, esc=1.4, z=-6, mod="Color(1, 0.7, 0.5, 0.8)")
c.assente("MaquinaD1", "r4_maquina", 5300, CH - 160, esc=1.6, z=-8, mod="Color(0.7, 0.5, 0.45, 0.8)")

c.com("""
MARCO VISUAL do nivel: a GRANDE RODA DE PRESSAO (sala de controlo, 'manometros
gigantes' da prancha) a girar devagar por tras do fosso da Sala das Pressoes,
com uma roda menor em contra-rotacao e as estruturas que a seguram.
""")
def roda(nome, x, y, esc, tex, graus, mod):
    """Roda decorativa que gira devagar (`GiraDevagar`), so' pintura."""
    corpo = "\n".join([f"position = {v(x, y)}", f"scale = {v(esc, esc)}",
                       f'texture = ExtResource("{c.tex(tex)}")', "z_index = -9",
                       f"modulate = {mod}", f"graus_por_seg = {graus:g}"])
    c.com_script(nome, "Sprite2D", "res://scripts/gira_devagar.gd", corpo)


roda("RodaPressao", 5560, CH - 330, 2.3, "r4_eng_grande", 2.5, "Color(0.85, 0.52, 0.42, 0.85)")
roda("RodaPressaoMenor", 5190, CH - 430, 1.3, "r4_eng_media", -5.0, "Color(0.8, 0.5, 0.4, 0.8)")
c.fx("BrilhoRodaPressao", "r4_brasas", 5560, CH - 330, esc=3.2, z=-8, mod="Color(1, 0.5, 0.2, 0.3)")
c.assente("EstruturaD1", "r4_estrutura", 5100, CH + 40, esc=1.7, z=-7, mod="Color(0.34, 0.27, 0.29, 0.6)")
c.assente("EstruturaD2", "r4_estrutura", 6000, CH + 40, esc=1.7, z=-7, mod="Color(0.34, 0.27, 0.29, 0.6)")
c.corrente("CorrenteRoda1", 5420, CH - 700, CH - 560, z=-8, mod="Color(0.7, 0.5, 0.4, 0.8)")
c.corrente("CorrenteRoda2", 5700, CH - 700, CH - 560, z=-8, mod="Color(0.7, 0.5, 0.4, 0.8)")


# ======================================================================
#  ARENA DO GUARDIAO
# ======================================================================
ARE0 = 5972
c.com("""
===================  ARENA DO GUARDIAO  ================================
Chao a 600, 740 px. ILHA | PISTAO | ILHA(Guardiao) | PISTAO | ILHA(porta). Os
dois pistoes alternam (nunca batem juntos) e as tres ilhas (>= 130 px) ficam
sempre seguras. A valvula V7, na ilha da esquerda, desliga-os 8 s: a arena
fica favoravel, mas ninguem e' obrigado a usa-la. Guardiao = Lanca-Chamas elite
(PLACEHOLDER: das quatro especies do contrato N19 nenhuma esta' extraida --
DECISAO DE CANON PENDENTE DO PAULO).
""")
c.plat("ChaoArena", ARE0, 6712, CH, h=70, av=130)
c.check("CheckD5", 6022, CH)
# a V7 fica numa laje a 80 px do chao (um salto): e' preciso QUERER usa-la; ao
# passar a correr por baixo nao se abre sozinha
c.plat("PlatValvulaArena", 6057, 6167, 520, h=22, av=34)
c.valvula("ValvulaArena", 6112, 520, "arena", janela=8.0, aviso_fim=2.0, cor=FOGO)
pis("PistaoArena1", 6262, fase=0.0, grupo="arena", retoma=0.0)
pis("PistaoArena2", 6522, fase=2.41, grupo="arena", retoma=1.4)
CRUZAMENTOS.append(("Arena1", ["PistaoArena1"], 6172, 6352, 1.5))
CRUZAMENTOS.append(("Arena2", ["PistaoArena2"], 6412, 6612, 1.5))
c.inimigo("GuardiaoN19", 6392, CH - 70, "lanca_chamas", "patrulha", 230, 20, 60,
          elite=True, escala=1.6)
c.assente("ColunaArena1", "r4_coluna", 6002, CH, esc=1.3, z=-4, mod=SOMBRA)
c.assente("ArcoArena", "r4_arco_gotico", 6392, CH, esc=1.8, z=-7, mod=SOMBRA)
c.assente("PortaoSaida", "r4_portao_forja", 6662, CH, esc=1.2, z=-6)
c.luz("LuzPortaoSaida", 6662, CH - 80, 1.0, FORNO_LUZ, (2.6, 1.8))
c.fx("BrilhoPortaoSaida", "r4_brasas", 6662, CH - 40, esc=1.5, z=-5, mod="Color(1, 0.6, 0.3, 0.7)")
c.fumo("FumoArena", 6322, CH + 10, 800, n=10)

# ======================================================================
#  Koliani e porta
# ======================================================================
c.no("Koliani", f"position = {v(170, CH - 40)}\nusar_prototipo_premium = true\n"
                "usar_golden_set = true", inst=c.ator("kol"))
c.no("Porta", f"position = {v(6662, CH - 6)}\npista_ao_atravessar = \"\"", inst=c.ator("porta"))

CAB = """
; REGIAO IV / nivel 19 -- SALA DAS PRESSOES (`level.n18`), "Resiste ou recua".
; O nome do ficheiro fica (era o Templo da Serpente): mudá-lo partia saves.
;
; GERADO por `tools/construir_n19_sala_pressoes.py` -- editar la', nao aqui.
; Desenho, medicoes e o que ficou por decidir: `docs/nivel_autoral_n19.md`.
;
; Nivel AUTORAL (`corredor = false`). Contrato: `region_04/level_mechanics.png`
; (N19) + `layout_usage.png`: A jatos e timing (aqui: pistoes), B plataformas de
; precisao + valvulas, C seccao com pressao variavel, D saida para o nucleo.
; 3 segredos, 5 checkpoints, Guardiao (nao chefe) na arena dos pistoes.
"""


def verificar():
    """Falha a geracao se uma travessia critica nao der folga (modelo puro)."""
    print("--- janelas seguras (s) por travessia, sem valvula ---")
    mau = []
    for nome, hs, x0, x1, minimo in CRUZAMENTOS:
        w = janela(hs, x0, x1)
        print(f"  {nome:6s} {x0:5.0f}->{x1:5.0f}  janela {w:5.2f} s  (min {minimo})")
        if w < minimo:
            mau.append((nome, w, minimo))
    if mau:
        raise SystemExit(f"travessias apertadas: {mau}")


if __name__ == "__main__":
    verificar()
    c.escrever(SAIDA, CAB)
