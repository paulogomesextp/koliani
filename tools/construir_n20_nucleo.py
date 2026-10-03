#!/usr/bin/env python3
"""Gera `scenes/levels/O_Abismo.tscn` -- N20 "Nucleo da Fornalha": exame
cumulativo da Regiao IV + GUARDIAO DA FORNALHA (unico boss da regiao).

O nome do ficheiro e' LEGADO (era O Abismo; indice 19 de `EstadoJogo.NIVEIS`).
EDITAR AQUI e voltar a correr (nunca no `.tscn`):
    python tools/construir_n20_nucleo.py

Contrato LOCKED: `docs/art_direction/regions/region_04/level_mechanics.png` e
`boss_pack.png`. Reutiliza blocos JA PROVADOS de N16-N19 (piso quente e jato,
lava que sobe, carrinho, valvula + ritmadas + pistoes). Os ciclos contam desde
o arranque (`relogio_local`). Verifica, ao gerar, que cada travessia critica
tem uma janela segura (modelo puro dos ciclos).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from r4_lib import BRASA, Cena, RAIZ, v  # noqa: E402

SAIDA = os.path.join(RAIZ, "scenes", "levels", "O_Abismo.tscn")
c = Cena("O_Abismo", "uid://bkolianiabismo20")

SOMBRA = "Color(0.42, 0.34, 0.36, 1)"
FORNO_LUZ = "Color(1.0, 0.56, 0.22, 1)"
GELO = "Color(0.45, 0.8, 1.0, 1)"      # valvulas das PLATAFORMAS
FOGO = "Color(1.0, 0.5, 0.2, 1)"       # valvulas dos PERIGOS
CH = 600.0
LARG = 5640.0

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



# ---- helpers do N18 (carrinho / lava que sobe) -----------------------------
def carrinho(nome, centro, amp, periodo, larg, trilho_x0, trilho_x1):
    c.no(nome, f'position = {v(centro, CH + 9)}\nmodo = "horizontal"\namplitude = {amp:g}\n'
         f"periodo = {periodo:g}\ncomprimento = 160.0\nlargura = {larg:g}\npele_terreno = true\n"
         f"ancora_no_trilho = true\n"
         f'textura_corrente = ExtResource("{c.tex("r4_corrente_fina")}")',
         inst=c.ator("corr"))
    c.mosaico("Trilho" + nome, "r4_trilho_minerio", trilho_x0, CH - 174, trilho_x1, CH - 146,
              esc=0.45, z=-2, mod="Color(0.85, 0.7, 0.6, 1)")


def lava_estatica(nome, esq, dir_, chao_topo=720.0):
    # com os muros sob as pontas do chao (sem eles da' para sair POR BAIXO do
    # chao e cair do mundo: o defeito que o N16/N18 ensinaram)
    pit(nome, esq, dir_, fundo=chao_topo)


LAVA_SOBE = ("sobe_amplitude = {a:g}\nsobe_espera = {e:g}\nsobe_aviso = 1.2\nsobe_subida = {s:g}\n"
             "sobe_topo = {t:g}\nsobe_desce = {d:g}\nsobe_fase = {f:g}\n")


def lava_sobe(nome, esq, dir_, base, chao_topo, amp, espera=3.0, sobe=2.6, topo=1.8, desce=2.4, fase=0.0):
    altura = (chao_topo - base) + amp
    c.no(nome, f"position = {v((esq + dir_) / 2, base + altura / 2)}\nlargura = {dir_ - esq:g}\n"
               f"altura = {altura:g}\ncor = Color(1.0, 0.34, 0.08, 0.93)\nbrasas = true\nletal = false\n"
               f"dano_lava = 20\ntextura_lava = ExtResource(\"{c.tex('r4_lava_estatica')}\")\nz_index = -1\n"
               + LAVA_SOBE.format(a=amp, e=espera, s=sobe, t=topo, d=desce, f=fase).strip(),
         inst=c.ator_lava())
    c.plat("Fundo" + nome, esq, dir_, chao_topo, h=amp + 40, av=60)
    c.plat("Muro" + nome + "a", esq - 40, esq, CH, h=790 - CH, av=0)
    c.plat("Muro" + nome + "b", dir_, dir_ + 40, CH, h=790 - CH, av=0)


# ======================================================================
#  RAIZ + ATMOSFERA
# ======================================================================
c.no("O_Abismo",
     f'script = ExtResource("{c.script("res://scripts/nivel_com_chefe.gd")}")\n'
     "corredor = false\ncandeeiros = false\nalongar_plataformas = false\ncheckpoints_autorais = true\n"
     'mecanica_anunciada = "lava_sobe"\nestreia_x_autoral = 900.0',
     tipo="Node2D", pai="")
c.nos[0] = c.nos[0].replace(' parent=""', "")
c.no("Atmosfera", f"""cor_ambiente = Color(1.0, 0.76, 0.66, 1)
cor_fundo = Color(0.12, 0.03, 0.02, 1)
cor_silhueta = Color(0.2, 0.06, 0.04, 1)
cor_luz = Color(1, 0.5, 0.2, 1)
cor_poeira = Color(1, 0.55, 0.22, 1)
densidade_poeira = 2.0
bioma = "fornalha"
largura_nivel = {LARG:g}
fundo_pack = "fornalha"
tinta_fundo = Color(1.0, 0.8, 0.72, 1)
neblina_fundo = 0.12
dessaturar_fundo = 0.0
seed_ambiente = 2001
luzes_horizonte = true""", inst=c.cena("res://scenes/fx/Atmosfera.tscn"))

# ======================================================================
#  A) REVISAO  (0-1130)  -- o que a regiao ja ensinou, sem reensinar
# ======================================================================
c.com("""
===================  A) REVISAO  =======================================
Dois pisos quentes desfasados e um jato isolado (N16), um Trabalhador, CP1.
Conhecido: aqui so' se confirma que se le' o chao. Sem inimigos de elite.
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
c.jato("JatoA", 940, CH, alcance=230, intervalo=2.4, aviso=0.8, dur=1.2, fase=1.2)
c.assente("CaixaA", "r4_caixa", 1100, CH, esc=0.7, z=-1)
c.check("CheckA1", 1030, CH)
c.inimigo("TrabalhadorA", 1075, CH - 50, "trabalhador_corrompido", "patrulha", 40, 12, 35)

# ======================================================================
#  B) ASCENSAO / CALOR  (1130-2100): lava que sobe + carrinho sobre lava
# ======================================================================
c.com("""
===================  B) ASCENSAO / CALOR  ==============================
A lava que SOBE (N18): poca de 350 px com duas pedras acima da cota maxima.
Depois o carrinho de minerio sobre lava estatica (N17) e um chao de descanso
com CP2. Nada de novo: so' as duas decisoes (esperar a lava / apanhar o
carrinho) seguidas.
""")
lava_sobe("LavaB1", 1130, 1480, 690, 720, 110)
c.plat("PedraB1", 1190, 1260, 545, h=40, av=70)
c.plat("PedraB2", 1340, 1410, 530, h=40, av=70)
c.assente("MarcadorLavaB", "r4_lava_eruptiva", 1305, 720, esc=0.9, z=-6, mod="Color(1, 0.7, 0.5, 0.85)")
c.fumo("FumoLavaB", 1305, 700, 330)
c.plat("ChaoB1", 1480, 1620, CH, h=70, av=130)
c.assente("FornoB", "r4_forno", 1540, CH, esc=1.0, z=-5)
c.luz("LuzFornoB", 1540, CH - 70, 0.9, FORNO_LUZ, (2.2, 1.6))
lava_estatica("LavaB2", 1620, 1900)
carrinho("CarrinhoB", 1760, 60, 5.0, 140, 1620, 1900)
c.fumo("FumoLavaB2", 1760, CH + 30, 280)
c.assente("TuboB", "r4_tubo_lava", 1760, CH - 280, esc=0.9, z=-5, mod=SOMBRA)
c.plat("ChaoB2", 1900, 2100, CH, h=70, av=130)
c.check("CheckB2", 1940, CH)
c.inimigo("TrabalhadorB", 2040, CH - 50, "trabalhador_corrompido", "patrulha", 40, 12, 30)
c.assente("ColunaB2", "r4_coluna", 1925, CH, esc=1.2, z=-4, mod=SOMBRA)

# ======================================================================
#  C) PRESSAO  (2100-3650): valvula + fosso de ritmadas, pistao e jato (N19)
# ======================================================================
c.com("""
===================  C) PRESSAO  =======================================
O fosso de 710 px do N19 (ritmada -> pistao -> ilha -> jato -> ritmada). A
valvula azul segura as plataformas 11 s; o pistao sobre a RC2 e o jato do
fundo continuam. SEGREDO 1 (StepC so' com a valvula aberta). Do outro lado,
chao largo com um Operario Blindado (elite) e um Arqueiro numa plataforma.
""")
c.plat("ChaoC0", 2100, 2440, CH, h=70, av=130)
c.check("CheckC0", 2135, CH)
c.assente("CaldeiraC", "r4_caldeira", 2180, CH, esc=0.9, z=-5, mod=SOMBRA)
c.assente("BandeiraC", "r4_bandeira", 2300, CH - 260, esc=1.0, z=-3)
c.valvula("ValvulaC", 2400, CH, "c", janela=11.0, aviso_fim=2.0, cor=GELO)
pit("LavaC", 2440, 3150)
for nome, e, d, f in [("RitmadaC1", 2480, 2560, 0.0), ("RitmadaC2", 2596, 2686, 0.75),
                      ("RitmadaC3", 2912, 2992, 0.5), ("RitmadaC4", 3028, 3108, 0.25)]:
    c.ritmada(nome, e, d, CH, solida=1.2, fantasma=2.4, fase=f, grupo="c", efeito="solida", aviso=0.5)
pis("PistaoC", 2666, fase=1.5)
c.plat("IlhaC", 2722, 2804, CH, h=22, av=34)
jat("JatoC", 2858, 720, 300, 1.8, 0.8, 1.7, fase=0.0)
CRUZAMENTOS.append(("C-a", ["PistaoC"], 2596, 2760, 1.0))
CRUZAMENTOS.append(("C-b", ["JatoC"], 2760, 2950, 1.0))
c.fumo("FumoLavaC", 2795, CH + 30, 700, n=14)
c.fx("QuedaC", "r4_queda_lava", 2795, CH - 110, esc=1.3, z=-6, mod="Color(1, 0.7, 0.45, 0.8)")
c.com("""SEGREDO 1 -- StepC (so' com a valvula C aberta) -> alcova a 175 px.""")
c.ritmada("StepC", 2472, 2527, 510, solida=4.0, fantasma=1.0, grupo="c", efeito="so_aberta", aviso=0.8)
c.plat("SegredoA", 2534, 2594, 425, h=22, av=40)
c.ess("EssenciaSegredoA", 2564, 425, 30)
c.plat("ChaoC1", 3150, 3650, CH, h=70, av=130)
c.check("CheckC3", 3190, CH)
c.assente("FornoC", "r4_forno", 3220, CH, esc=1.0, z=-5)
c.luz("LuzFornoC", 3220, CH - 70, 0.9, FORNO_LUZ, (2.2, 1.6))
c.plat("PlatArqC", 3330, 3450, CH - 100, h=24, av=40)
c.inimigo("ArqueiroC", 3390, CH - 100 - 50, "arqueiro_da_fornalha", "cuspidor", 30, 10, 40)
c.inimigo("OperarioC", 3560, CH - 62, "operario_blindado", "escudeiro", 170, 18, 60,
          elite=True, escala=1.25)
c.assente("ColunaC1", "r4_coluna", 3480, CH, esc=1.8, z=-1, mod=SOMBRA)

# ======================================================================
#  D) APROXIMACAO AO GUARDIAO  (3650-4300): maquinas + valvula (N19)
# ======================================================================
c.com("""
===================  D) APROXIMACAO  ===================================
Corredor de maquinas: dois pistoes desencontrados e um jato aceso. E' uma PORTA
DE VALVULA (sem a valvula quase nao ha janela; com ela, folga). O SEGREDO 2
(StepD) so' existe com a valvula aberta. Sem inimigos: o ultimo desafio de
precisao antes do Guardiao. CP5 na entrada da arena.
""")
c.plat("ChaoD", 3650, 4300, CH, h=70, av=130)
c.check("CheckD0", 3668, CH)
c.valvula("ValvulaD", 3700, CH, "d", janela=10.0, aviso_fim=2.0, cor=FOGO)
c.assente("ColunaD0", "r4_coluna", 3670, CH, esc=1.3, z=-4, mod=SOMBRA)
c.com("""SEGREDO 2 -- StepD (so' com a valvula D aberta) -> alcova sobre o corredor.""")
c.ritmada("StepD", 3745, 3800, 510, solida=4.0, fantasma=1.0, grupo="d", efeito="so_aberta", aviso=0.8)
c.plat("SegredoB", 3810, 3890, 425, h=22, av=40)
c.ess("EssenciaSegredoB", 3850, 425, 30)
pis("PistaoD1", 3960, fase=0.0, grupo="d", retoma=0.0)
pis("PistaoD2", 4070, fase=2.41, grupo="d", retoma=1.4)
jat("JatoD", 4190, CH, 230, 0.6, 0.6, 3.62, fase=0.0, grupo="d", retoma=0.0)
CRUZAMENTOS.append(("D", ["PistaoD1", "PistaoD2", "JatoD"], 3885, 4250, 0.0))
c.assente("PilarJatoD", "r4_tubo_reto", 4190, CH + 40, esc=0.6, z=-3, mod=SOMBRA)
c.assente("MaquinaD", "r4_maquina", 4010, CH, esc=0.9, z=-4, mod=SOMBRA)
c.fumo("FumoD", 4040, CH + 10, 700, n=10)

# ======================================================================
#  ARENA DO GUARDIAO DA FORNALHA  (4300-5600)
# ======================================================================
ARE0, ARE1 = 4300, 5600
FAIXA0, FAIXA1 = 4800, 5300
c.com("""
===================  ARENA  ============================================
Chao continuo de 1300 px. O Guardiao anda so' na FAIXA central (4800-5300);
as duas plataformas de refugio (110 px acima do chao, um salto simples) ficam
FORA dela, uma de cada lado, para o corpo nunca as atravessar. A ERUPCAO
acende o chao inteiro; so' as plataformas sao refugio. Muro a' direita: ninguem
sai da arena. CP5 a' entrada. Porta a' direita, selada ate' o boss cair.
""")
c.plat("ChaoArena", ARE0, ARE1, CH, h=70, av=130)
c.plat("MuroArenaD", ARE1, ARE1 + 40, -200, h=1000, av=0)
c.check("CheckBoss", 4350, CH)
c.plat("RefugioE", 4500, 4680, CH - 110, h=22, av=34)
c.plat("RefugioD", 5420, 5580, CH - 110, h=22, av=34)
c.assente("ColunaArena0", "r4_coluna", 4320, CH, esc=1.4, z=-4, mod=SOMBRA)
c.no("Chefe", f"position = {v(5100, CH - 75)}\nfaixa_esq = {FAIXA0:g}\nfaixa_dir = {FAIXA1:g}\n"
              f"lava_esq = {ARE0 + 20:g}\nlava_dir = {ARE1 - 20:g}",
     inst=c.cena("res://scenes/actors/ChefeGuardiaoDaFornalha.tscn"))
c.luz("LuzArena1", 4700, CH - 150, 0.9, FORNO_LUZ, (3.0, 1.8))
c.luz("LuzArena2", 5300, CH - 150, 0.9, FORNO_LUZ, (3.0, 1.8))
c.assente("PortaoSaida", "r4_portao_forja", 5540, CH, esc=1.2, z=-6)
c.luz("LuzPortaoSaida", 5540, CH - 80, 1.0, FORNO_LUZ, (2.6, 1.8))
c.fx("BrilhoPortaoSaida", "r4_brasas", 5540, CH - 40, esc=1.5, z=-5, mod="Color(1, 0.6, 0.3, 0.7)")
c.fumo("FumoArena", 5000, CH + 10, 1000, n=12)
c.brasas("BrasasArena", 5000, CH - 4, 1100, n=16)

c.com("""
MARCO VISUAL: o NUCLEO DE MAGMA -- uma engrenagem gigante a girar devagar por
tras da arena, com o brilho de lava, a MAQUINARIA GIGANTE e as correntes que
descem do tecto ate' ao nucleo. E' maior que a roda do N19 e e' o que se ve'
desde o corredor D: tudo conduz ao Guardiao.
""")


def roda(nome, x, y, esc, tex, graus, mod):
    corpo = "\n".join([f"position = {v(x, y)}", f"scale = {v(esc, esc)}",
                       f'texture = ExtResource("{c.tex(tex)}")', "z_index = -9",
                       f"modulate = {mod}", f"graus_por_seg = {graus:g}"])
    c.com_script(nome, "Sprite2D", "res://scripts/gira_devagar.gd", corpo)


roda("NucleoMagma", 5050, CH - 300, 4.2, "r4_eng_grande", 1.6, "Color(0.72, 0.38, 0.3, 0.5)")
roda("NucleoMagmaMenor", 4560, CH - 420, 1.8, "r4_eng_media", -4.0, "Color(0.8, 0.46, 0.36, 0.75)")
roda("NucleoMagmaMenor2", 5560, CH - 430, 1.5, "r4_eng_media", 4.0, "Color(0.8, 0.46, 0.36, 0.75)")
c.fx("BrilhoNucleo", "r4_brasas", 5050, CH - 300, esc=6.0, z=-8, mod="Color(1, 0.45, 0.15, 0.22)")
c.fx("BrilhoNucleo2", "r4_brasas", 5050, CH - 300, esc=3.2, z=-8, mod="Color(1, 0.7, 0.3, 0.26)")
c.assente("MaquinariaGigante1", "r4_maquina", 4800, CH, esc=2.4, z=-8, mod="Color(0.5, 0.36, 0.34, 0.8)")
c.assente("MaquinariaGigante2", "r4_fornalha", 5330, CH, esc=1.9, z=-8, mod="Color(0.5, 0.36, 0.34, 0.8)")
for i, x in enumerate([4620, 4880, 5220, 5480]):
    c.corrente(f"CorrenteNucleo{i}", x, -300, CH - 330, z=-8, mod="Color(0.7, 0.5, 0.4, 0.8)", esc=0.3)

# ======================================================================
#  Koliani e porta
# ======================================================================
c.no("Koliani", f"position = {v(170, CH - 40)}\nusar_prototipo_premium = true\n"
                "usar_golden_set = true", inst=c.ator("kol"))
c.no("Porta", f"position = {v(5540, CH - 6)}\npista_ao_atravessar = \"\"", inst=c.ator("porta"))

CAB = """
; REGIAO IV / nivel 20 -- NUCLEO DA FORNALHA (`level.n19`), EXAME CUMULATIVO +
; GUARDIAO DA FORNALHA (o unico boss da regiao).
; O nome do ficheiro fica (era O Abismo): muda-lo partia saves.
;
; GERADO por `tools/construir_n20_nucleo.py` -- editar la', nao aqui.
; Desenho, medicoes e decisoes: `docs/nivel_autoral_n20.md`.
;
; Contrato LOCKED `region_04/level_mechanics.png` (N20: combinacao de todas as
; mecanicas, maquinario em grande escala, acesso a arena) + `boss_pack.png`.
; A revisao, B lava que sobe + carrinho, C valvula + fosso de ritmadas, D
; corredor de maquinas, arena. 2 segredos, 6 checkpoints, `corredor = false`.
"""


def verificar():
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
