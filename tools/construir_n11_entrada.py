#!/usr/bin/env python3
"""Gera `scenes/levels/Torre_dos_Sinos.tscn` -- N11 "Entrada dos Ecos".

Refeito de raiz (DEC-014, 3 out 2026): a cena anterior tinha ~1 000 px, acabava
em 31 s e lia-se como placeholder (sinos e plataformas oscilantes sem textura
-> poligonos amarelos/lilases). Este gerador segue o pipeline do N12
(`tools/construir_n12_galerias.py`): plataformas dadas por TOPO + bordas,
props recortados da prancha aprovada da Regiao III, nada de Polygon2D de cor
solida como arte final.

EDITAR AQUI e voltar a correr; nao editar o `.tscn` a mao:
    python tools/construir_n11_entrada.py

Contrato: docs/art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md
(N11 -- "Aprende a ouvir"). Desenho e medicoes: docs/nivel_autoral_n11.md.

Papel na regiao (DEC-012): 1.o nivel = TEACH, acaba num desafio de travessia,
SEM guardiao. 4 encontros desenhados (DEC-013: o 2.o fecha ate' limpar).
"""
from __future__ import annotations

import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "scenes", "levels", "Torre_dos_Sinos.tscn")

# Coordenadas de desenho == mundo (o chao da entrada a 900; `Y_MORTE` = 1200).
PEDRA = "cor_base = Color(0.24, 0.2, 0.26, 1)\ncor_topo = Color(0.5, 0.44, 0.54, 1)"

EXT = [
    ("PackedScene", "uid://bkolianiactor01", "res://scenes/actors/Koliani.tscn", "kol"),
    ("PackedScene", "uid://bdemoniobase01", "res://scenes/actors/DemonioBase.tscn", "dem"),
    ("PackedScene", "uid://bkolianiporta01", "res://scenes/actors/Porta.tscn", "porta"),
    ("Script", None, "res://scripts/checkpoint.gd", "chk"),
    ("Script", None, "res://scripts/nivel_com_chefe.gd", "niv"),
    ("Script", None, "res://scripts/arena_selada.gd", "arena"),
    ("PackedScene", "uid://bkolianiatmosfera01", "res://scenes/fx/Atmosfera.tscn", "atm"),
    ("PackedScene", "uid://bkolianiplataforma01", "res://scenes/actors/Plataforma.tscn", "pl"),
    ("PackedScene", "uid://bkolianisinotorre11", "res://scenes/actors/SinoTorre.tscn", "sino"),
    ("PackedScene", "uid://bkolianiaguavenenosa01", "res://scenes/actors/AguaVenenosa.tscn", "vazio"),
    ("PackedScene", "uid://bkolianiplatsino11", "res://scenes/actors/PlataformaSino.tscn", "eco"),
    ("PackedScene", "uid://bkolianipendulolamina01", "res://scenes/actors/PenduloLamina.tscn", "pend"),
    ("PackedScene", "uid://bkolianiplataquebra01", "res://scenes/actors/PlataformaQuebra.tscn", "quebra"),
    ("PackedScene", "uid://bkolianiplatcorrente06", "res://scenes/actors/PlataformaCorrente.tscn", "pcorr"),
    ("PackedScene", "uid://bkolianiespinhos01", "res://scenes/actors/Espinhos.tscn", "espinhos"),
    ("PackedScene", "uid://bkolianiessencia01", "res://scenes/actors/Essencia.tscn", "ess"),
    ("PackedScene", "uid://bkolianitumuloelev16", "res://scenes/actors/TumuloElevador.tscn", "elev"),
    ("Script", None, "res://scripts/elevador_coluna.gd", "elevcol"),
]
TEXTURAS = [
    "vitral_alto", "sino_m", "sino_g", "sino_partido", "coluna_igreja", "coluna_dupla",
    "arco_grande", "corrente_t", "lanterna_eco", "candelabro", "estatua_anjo", "flamula",
    "pedra_memoria", "gargula", "tocha", "urna", "livros",
    "p_parede", "p_passarela", "p_suporte", "p_vitral_dourado", "p_parede_vitral",
    "p_rosacea", "p_vitral_pequeno", "p_lamina_pendular", "p_particulas_luz",
    "p_brilho_sino", "p_raios_luz", "p_neblina", "p_heras", "p_detritos", "p_poeira_chao",
    "m_tex_correntes",
]
for t in TEXTURAS:
    EXT.append(("Texture2D", None, f"res://assets/sprites/pixel/deco/torres/{t}.png", "t_" + t))
EXT.append(("Texture2D", None, "res://assets/sprites/pixel/terreno/torre_ecos/corpo.png", "t_corpo_te"))

ID = {}
linhas_ext = []
for i, (tipo, uid, cam, chave) in enumerate(EXT, start=1):
    rid = f"{i}_{chave}"
    ID[chave] = rid
    u = f' uid="{uid}"' if uid else ""
    linhas_ext.append(f'[ext_resource type="{tipo}"{u} path="{cam}" id="{rid}"]')

nos: list[str] = []


def com(texto: str) -> None:
    for l in texto.strip("\n").split("\n"):
        nos.append("; " + l if l else ";")


def no(nome: str, corpo: str, tipo: str | None = None, inst: str | None = None,
       pai: str = ".", grupos: list[str] | None = None) -> None:
    cab = f'[node name="{nome}"'
    if tipo:
        cab += f' type="{tipo}"'
    cab += f' parent="{pai}"'
    if inst:
        cab += f' instance=ExtResource("{ID[inst]}")'
    if grupos:
        cab += " groups=[" + ", ".join(f'"{g}"' for g in grupos) + "]"
    cab += "]"
    nos.append(cab)
    if corpo:
        nos.append(corpo.strip("\n"))
    nos.append("")


def v(x: float, y: float) -> str:
    return f"Vector2({x:g}, {y:g})"


def tex(t: str) -> str:
    return f'ExtResource("{ID["t_" + t]}")'


PL: dict[str, dict] = {}


def plat(nome: str, esq: float, dir: float, topo: float, h: float = 22.0,
         av: float | None = None, inst: str = "pl", extra: str = "") -> None:
    PL[nome] = {"esq": esq, "dir": dir, "topo": topo}
    if av is None:
        av = 34.0 if h <= 30 else 0.0
    corpo = f"position = {v((esq + dir) / 2.0, topo + h / 2.0)}\ntamanho = {v(dir - esq, h)}"
    if inst in ("pl", "eco"):
        corpo += f"\naltura_visual = {av:g}\n{PEDRA}"
    if extra:
        corpo += "\n" + extra
    no(nome, corpo, inst=inst)


def quebra(nome: str, esq: float, dir: float, topo: float) -> None:
    PL[nome] = {"esq": esq, "dir": dir, "topo": topo}
    no(nome, f"position = {v((esq + dir) / 2, topo + 9)}\ntamanho = {v(dir - esq, 18)}\n"
             "pele_terreno = true", inst="quebra")


def ess(nome: str, x: float, topo: float, valor: int) -> None:
    no(nome, f"position = {v(x, topo - 36)}\nvalor = {valor}", inst="ess")


def check(nome: str, x: float, topo: float) -> None:
    no(nome, f"position = {v(x, topo - 34)}\ncollision_layer = 16\ncollision_mask = 2\n"
             f'script = ExtResource("{ID["chk"]}")', tipo="Area2D")
    no("CollisionShape2D", 'shape = SubResource("rs_chk")', tipo="CollisionShape2D", pai=nome)


def espinhos(nome: str, esq: float, dir: float, chao: float) -> None:
    no(nome, f"position = {v((esq + dir) / 2, chao)}\nlargura = {int((dir - esq) // 16)}",
       inst="espinhos")


def inimigo(nome: str, x: float, y: float, especie: str, comp: str, vida: int,
            dano: int, patrulha: float, rim: str, elite: bool = False,
            escala: float = 1.0, grupos: list[str] | None = None) -> None:
    c = f"position = {v(x, y)}\n"
    if escala != 1.0:
        c += f"scale = {v(escala, escala)}\n"
    if elite:
        c += "elite = true\n"
    c += (f'especie = "{especie}"\nvida = {vida}\ndano_contacto = {dano}\n'
          f'comportamento = "{comp}"\nalcance_patrulha = {patrulha:g}\ncor_rim = {rim}')
    no(nome, c, inst="dem", grupos=grupos)


def _tam_png(caminho: str) -> tuple:
    with open(caminho, "rb") as f:
        cab = f.read(24)
    return int.from_bytes(cab[16:20], "big"), int.from_bytes(cab[20:24], "big")


TAM_TEX = {t: _tam_png(os.path.join(RAIZ, "assets/sprites/pixel/deco/torres", f"{t}.png"))
           for t in TEXTURAS}


def assente(nome: str, t: str, x: float, base_y: float, esc: float = 2.0,
            z: int = -2, mod: str = "", flip: bool = False) -> None:
    h = TAM_TEX[t][1] * esc
    c = (f"position = {v(x, base_y - h / 2.0 + 2.0)}\nscale = {v(esc, esc)}\n"
         f"texture = {tex(t)}\nz_index = {z}")
    if flip:
        c += "\nflip_h = true"
    if mod:
        c += f"\nmodulate = {mod}"
    no(nome, c, tipo="Sprite2D")


def pendurado(nome: str, t: str, x: float, topo_y: float, esc: float = 2.0,
              z: int = -2, mod: str = "") -> None:
    h = TAM_TEX[t][1] * esc
    c = (f"position = {v(x, topo_y + h / 2.0)}\nscale = {v(esc, esc)}\n"
         f"texture = {tex(t)}\nz_index = {z}")
    if mod:
        c += f"\nmodulate = {mod}"
    no(nome, c, tipo="Sprite2D")


def corrente(nome: str, x: float, y0: float, y1: float, z: int = -3,
             mod: str = "Color(0.95, 0.8, 0.5, 0.9)") -> None:
    c = (f"position = {v(x - 5, y0)}\ntexture_repeat = 2\ntexture = {tex('corrente_t')}\n"
         f"centered = false\nregion_enabled = true\nregion_rect = Rect2(0, 0, 10, {y1 - y0:g})\n"
         f"z_index = {z}\nmodulate = {mod}")
    no(nome, c, tipo="Sprite2D")


def luz(nome: str, x: float, y: float, energia: float, cor: str, esc: tuple) -> None:
    no(nome, f'position = {v(x, y)}\ntexture = SubResource("tex_luz")\n'
             f"energy = {energia:g}\ncolor = {cor}\nscale = {v(*esc)}", tipo="PointLight2D")


def mosaico(nome: str, t: str, x0: float, y0: float, x1: float, y1: float,
            esc: float = 1.0, z: int = -9, mod: str = "") -> None:
    w, h = (x1 - x0) / esc, (y1 - y0) / esc
    c = (f"position = {v(x0, y0)}\nscale = {v(esc, esc)}\ncentered = false\n"
         f"texture = {tex(t)}\ntexture_repeat = 2\n"
         f"region_enabled = true\nregion_rect = Rect2(0, 0, {w:g}, {h:g})\nz_index = {z}")
    if mod:
        c += f"\nmodulate = {mod}"
    no(nome, c, tipo="Sprite2D")


def fx(nome: str, t: str, x: float, y: float, esc: float = 1.0, z: int = 2,
       mod: str = "Color(1, 1, 1, 0.8)") -> None:
    no(nome, f"position = {v(x, y)}\nscale = {v(esc, esc)}\ntexture = {tex(t)}\n"
             f'z_index = {z}\nmodulate = {mod}\nmaterial = SubResource("mat_add")', tipo="Sprite2D")


def heras(nome: str, x: float, topo_y: float, esc: float = 0.8) -> None:
    pendurado(nome, "p_heras", x, topo_y - 6, esc=esc, z=1, mod="Color(0.78, 0.84, 1, 1)")


def sino(nome: str, x: float, y: float, grupo: str, esc: float = 1.3) -> None:
    """Sino de jogo COM textura (o antigo N11 nao tinha -> poligono amarelo)."""
    no(nome, f"position = {v(x, y)}\nscale = {v(esc, esc)}\nalterna_grupo = \"{grupo}\"\n"
             f"textura = {tex('sino_m')}", inst="sino")
    corrente(f"Corrente{nome}", x, y - 190, y - 32)
    fx(f"Brilho{nome}", "p_brilho_sino", x, y - 15, esc=1.0, z=-1, mod="Color(1, 0.85, 0.6, 0.55)")


def ponte_eco(prefixo: str, degraus: list, grupo: str) -> None:
    for i, (e, t) in enumerate(degraus, start=1):
        plat(f"{prefixo}{i}", e, e + 100, t, h=20, av=16, inst="eco",
             extra=f'grupo_alternar = "{grupo}"')


OURO = "Color(1.0, 0.76, 0.45, 1)"
LUA = "Color(0.55, 0.7, 1.0, 1)"
ROXO = "Color(0.72, 0.5, 1.0, 1)"
RIM_ACOLITO = "Color(1.0, 0.72, 0.45, 1)"
RIM_SINO = "Color(1.0, 0.85, 0.6, 1)"
RIM_ARQ = "Color(0.55, 0.4, 0.8, 1)"
RIM_SENT = "Color(0.6, 0.65, 0.85, 1)"
LARGURA = 6800.0

# ======================================================================
#  RAIZ
# ======================================================================
no("Torre_dos_Sinos",
   f'script = ExtResource("{ID["niv"]}")\ncorredor = false\n'
   "alongar_plataformas = false\ncheckpoints_autorais = true\nestreia_x_autoral = 640.0",
   tipo="Node2D", pai="")
nos[0] = nos[0].replace(' parent=""', "")

no("Atmosfera", f"""cor_ambiente = Color(0.9, 0.92, 1, 1)
cor_fundo = Color(0.05, 0.06, 0.14, 1)
cor_silhueta = Color(0.09, 0.1, 0.2, 1)
cor_luz = Color(1, 0.78, 0.48, 1)
cor_poeira = Color(1, 0.9, 0.72, 1)
densidade_poeira = 1.1
bioma = "torres"
largura_nivel = {LARGURA:g}
fundo_pack = "torre_ecos"
tinta_fundo = Color(0.88, 0.94, 1.16, 1)
neblina_fundo = 0.3
dessaturar_fundo = 0.18
seed_ambiente = 1370
luzes_horizonte = true""", inst="atm")

# ======================================================================
#  FACHADA DA TORRE -- parede do fundo (so' visual)
# ======================================================================
com("""
FACHADA -- o N11 e' a ENTRADA: comeca ao ar livre (panorama do pack ao
fundo) e vai entrando na torre. Pilares de cantaria a toda a altura, com
arcadas, vitrais e tochas; escurecidos para recuar. Nada aqui colide.
""")
PILARES = [1900, 2700, 3500, 4300, 5100, 5900]
PILAR = "Color(0.34, 0.37, 0.6, 1)"
PAREDE = "Color(0.13, 0.14, 0.25, 1)"
TOPO_NAVE, BASE_NAVE = -400.0, 1000.0
mosaico("ParedeNave", "corpo_te", 1900, TOPO_NAVE, LARGURA + 80, 60, z=-11, mod=PAREDE)
for i, x in enumerate(PILARES):
    mosaico(f"PilarNave{i}", "p_parede", x - 40, TOPO_NAVE, x + 40, BASE_NAVE, esc=1.18, z=-9,
            mod=PILAR)
    pendurado(f"MisulaNave{i}", "p_suporte", x, 60, esc=1.15, z=-8, mod=PILAR)
    assente(f"TochaNave{i}", "tocha", x, 230, esc=1.0, z=-8)
for i in range(len(PILARES) - 1):
    a, b = PILARES[i] + 40, PILARES[i + 1] - 40
    mosaico(f"ArcadaNave{i}", "p_passarela", a, -164, b, 60, esc=1.4, z=-10,
            mod="Color(0.32, 0.35, 0.6, 1)")
    xm = (a + b) / 2
    t = "p_vitral_dourado" if i % 2 == 0 else "p_parede_vitral"
    pendurado(f"VitralNave{i}", t, xm, -360, esc=1.5, z=-8, mod="Color(0.78, 0.84, 1, 0.95)")
    fx(f"RaiosNave{i}", "p_raios_luz", xm + 40, -40, esc=1.5, z=-7, mod="Color(0.7, 0.8, 1, 0.4)")
for i, x in enumerate(PILARES[1:-1], start=1):
    assente(f"RosaceaNave{i}", "p_rosacea", x, -200, esc=1.2, z=-8,
            mod="Color(0.72, 0.78, 1, 0.9)")

com("""Cair ao fundo = morte (o vazio da torre). As seccoes de ensino tem rede.""")
no("Vazio", f"position = {v(LARGURA / 2, 1270)}\nlargura = {LARGURA + 400:g}\naltura = 340.0\n"
            "cor = Color(0.05, 0.04, 0.11, 0.97)", inst="vazio")

# ======================================================================
#  A) ENTRADA E TUTORIAL -- o sino da entrada (landmark) e o 1.o sino
# ======================================================================
com("""
===================  A) ENTRADA DA TORRE  (ensinar)  ===================
Sem inimigos. O GRANDE SINO DA ENTRADA (landmark) pende da arcada, partido
o badalo -- algo ja' caiu desta torre. Espinhos simples no chao (vocabulario
antigo, so' para reintroduzir o hazard). O PRIMEIRO SINO de jogo esta' ao pe'
do vao: tocar-lhe faz a ponte de eco aparecer. Rede por baixo do vao inteiro:
errar custa 3 s, nao a vida. A margem de la' fica 280 px acima da rede
(acima do salto duplo, ~250) -- sem a ponte so' se volta para tras.
""")
plat("ChaoEntrada", -40, 760, 900, h=60, av=130)
mosaico("ArcoEntradaFundo", "p_passarela", 120, 520, 700, 760, esc=1.4, z=-10,
        mod="Color(0.3, 0.33, 0.56, 1)")
assente("ColunaEntrada1", "coluna_igreja", 110, 900, esc=1.8, z=-3, mod="Color(0.72, 0.74, 0.92, 1)")
assente("ColunaEntrada2", "coluna_igreja", 720, 900, esc=1.8, z=-3, mod="Color(0.72, 0.74, 0.92, 1)")
corrente("CorrenteSinoEntrada", 420, 300, 520, z=-4)
pendurado("SinoDaEntrada", "sino_g", 420, 516, esc=2.6, z=-3)
fx("BrilhoSinoEntrada", "p_brilho_sino", 420, 640, esc=2.0, z=-2, mod="Color(1, 0.85, 0.6, 0.5)")
luz("LuzSinoEntrada", 420, 640, 0.7, OURO, (2.6, 2.0))
assente("SinoPartidoEntrada", "sino_partido", 250, 900, esc=2.0, z=-1)
espinhos("EspinhosEntrada", 520, 568, 900)
ess("EssenciaEspinhos", 544, 860, 10)
sino("SinoEntrada", 690, 846, "sino_entrada")
ponte_eco("PonteEntrada", [(790, 880), (910, 870), (1030, 860)], "sino_entrada")
plat("RedeEntrada", 760, 1160, 1040, h=26)
assente("UrnaRede", "urna", 960, 1040, esc=1.4, z=-1)

com("""SEGREDO 1 -- alcova por cima da ponte, so' se ve ao chegar ao A2 e
olhar para tras. Sobe-se do A2 (60 px) para a esquerda.""")
plat("Segredo1", 1020, 1110, 700, h=22)
ess("EssenciaSegredo1", 1065, 700, 20)
assente("MemorialSegredo1", "pedra_memoria", 1095, 700, esc=1.3, z=-1)
luz("LuzSegredo1", 1065, 670, 0.35, ROXO, (0.9, 0.8))

# ======================================================================
#  ENCONTRO 1 -- Acolito + Sentinela (patrulha + escudo)
# ======================================================================
com("""
===================  ENCONTRO 1: o atrio  ===================
Acolito do Eco (orbes) atras de uma Sentinela da Torre (escudo a' frente):
a Sentinela obriga a passar-lhe por cima (pogo) ou pelas costas, enquanto o
Acolito pressiona a distancia. Chao largo e seguro. Os dois ficam a mais de
140 px do muro de escalada (regra do GM de 28 set: nada durante a 1.a
escalada).
""")
plat("Atrio", 1120, 1780, 760, h=60, av=120)
assente("ColunaAtrio1", "coluna_dupla", 1300, 760, esc=1.7, z=-3, mod="Color(0.72, 0.74, 0.92, 1)")
assente("ArcoAtrio", "arco_grande", 1580, 760, esc=1.9, z=-4, mod="Color(0.7, 0.72, 0.9, 1)")
assente("CandelabroAtrio", "candelabro", 1440, 760, esc=1.4, z=-1)
luz("LuzAtrio", 1440, 700, 0.55, OURO, (2.0, 1.2))
inimigo("SentinelaAtrio", 1380, 720, "sentinela_da_torre", "escudeiro", 70, 16, 90, RIM_SENT)
inimigo("AcolitoAtrio", 1580, 720, "acolito_do_eco", "cuspidor", 55, 14, 60, RIM_ACOLITO)

# ======================================================================
#  PRIMEIRA ESCALADA -- `escalar_paredes` (concedida no N10)
# ======================================================================
com("""
PRIMEIRA ESCALADA: muro de 290 px (acima do salto duplo, ~250) assente no
chao do atrio -- cair a meio custa nada. So' se sobe agarrado a' parede, a
habilidade que o boss do N10 deu. Em cima, um degrau de 30 px para a
muralha das passarelas.
""")
plat("ParedeSubida", 1760, 2080, 470, h=290, av=0)
assente("LanternaMuro", "lanterna_eco", 2020, 470, esc=1.5, z=-1)
luz("LuzMuro", 2020, 420, 0.5, OURO, (1.4, 1.1))
heras("HerasMuro", 1790, 470 + 40, esc=0.9)
plat("Muralha", 2080, 2440, 440, h=340, av=0)
assente("LanternaMuralha", "lanterna_eco", 2380, 440, esc=1.6, z=-1)
luz("LuzMuralha", 2380, 390, 0.5, OURO, (1.4, 1.1))

# ======================================================================
#  B) GALERIAS INICIAIS -- passarelas externas
# ======================================================================
com("""
===================  B) PASSARELAS EXTERNAS  (desenvolver)  ===========
Correntes moveis em vaivem (devagar, legiveis) sobre o vazio, depois uma
passarela QUEBRADA (os degraus voltam em 2,6 s) e uma LAMINA DE SINO LENTA a
guardar o patamar. Um Sino Flutuante cruza o vao alto -- nunca em cima de
uma aterragem.
""")
no("CorrenteMovel1", f"position = {v(2560, 449)}\nmodo = \"horizontal\"\namplitude = 50.0\n"
                     f"periodo = 3.4\ncomprimento = 200.0\nlargura = 120.0\npele_terreno = true\n"
                     f"textura_corrente = {tex('m_tex_correntes')}", inst="pcorr")
no("CorrenteMovel2", f"position = {v(2790, 429)}\nmodo = \"vertical\"\namplitude = 40.0\n"
                     f"periodo = 3.0\nfase = 0.5\ncomprimento = 180.0\nlargura = 120.0\n"
                     f"pele_terreno = true\ntextura_corrente = {tex('m_tex_correntes')}", inst="pcorr")
inimigo("SinoFlutuanteVao", 2700, 290, "sino_flutuante", "voador", 45, 12, 90, RIM_SINO)
quebra("Passarela1", 2930, 3020, 420)
quebra("Passarela2", 3060, 3150, 420)
plat("PatamarLamina", 3190, 3480, 420, h=30)
no("LaminaSinoLenta", f"position = {v(3335, 240)}\ncomprimento = 130.0\namplitude_graus = 52.0\n"
                      f"periodo = 3.4\ndano = 16\ntextura = {tex('p_lamina_pendular')}", inst="pend")
heras("HerasPatamar", 3450, 420 + 30)

# ======================================================================
#  ENCONTRO 2 -- ARENA QUE FECHA (DEC-013)
# ======================================================================
com("""
===================  ENCONTRO 2: a galeria selada  ===================
`mec.arena`: ao entrar, sobem duas grades; so' descem quando os quatro
morrem. Combina o que o nivel ja' ensinou: Sentinela (escudo) + Acolito
ELITE + Acolito (orbes) no chao e um Arqueiro das Sombras na varanda interior (alcance). A
varanda tambem e' o caminho do Segredo 2. CheckC mesmo antes da grade.
""")
GAL_E, GAL_D, GAL_T = 3560, 4160, 420
plat("GaleriaSelada", 3500, GAL_D + 20, GAL_T, h=60, av=120)
plat("VarandaArena", 3760, 3920, 320, h=22)
no("ArenaGaleria", f"position = {v((GAL_E + GAL_D) / 2, GAL_T - 130)}\n"
                   f'script = ExtResource("{ID["arena"]}")\ntamanho = {v(GAL_D - GAL_E, 260)}\n'
                   'altura_grade = 220.0\ngrupo_inimigos = "arena_n11"', tipo="Area2D")
G = ["arena_n11"]
inimigo("SentinelaArena", 3700, GAL_T - 40, "sentinela_da_torre", "escudeiro", 70, 16, 80, RIM_SENT, grupos=G)
inimigo("EliteAcolito", 3980, GAL_T - 50, "acolito_do_eco", "cuspidor", 120, 20, 70, RIM_ACOLITO,
        elite=True, escala=1.3, grupos=G)
inimigo("AcolitoArena2", 4070, GAL_T - 40, "acolito_do_eco", "patrulha", 55, 14, 60, RIM_ACOLITO, grupos=G)
inimigo("ArqueiroArena", 3840, 280, "arqueiro_das_sombras", "cuspidor", 50, 14, 40, RIM_ARQ, grupos=G)
assente("EstatuaArena1", "estatua_anjo", 3580, GAL_T, esc=1.6, z=-3)
assente("EstatuaArena2", "estatua_anjo", 4100, GAL_T, esc=1.6, z=-3, flip=True)
assente("VitralArena", "vitral_alto", 3840, GAL_T - 140, esc=2.4, z=-5, mod="Color(0.85, 0.9, 1, 0.9)")
luz("LuzArena", 3840, GAL_T - 40, 0.65, OURO, (3.0, 1.6))
com("""SEGREDO 2 -- por cima da varanda (100 px; a varanda esta' 100 acima do chao), depois de limpar a sala.""")
plat("Segredo2", 3880, 3970, 220, h=22)
ess("EssenciaSegredo2", 3925, 220, 25)
assente("LivrosSegredo2", "livros", 3950, 220, esc=1.3, z=-1)
luz("LuzSegredo2", 3925, 190, 0.35, ROXO, (0.9, 0.8))

# ======================================================================
#  ENCONTRO 3 -- o poco do elevador, sob fogo
# ======================================================================
com("""
===================  ENCONTRO 3: o poco do elevador  ===================
ELEVADOR DE COLUNA (peso): sobe com a Koliani em cima, desce quando ela
sai. Assenta no patio (degrau de 26 px) e sobe 300 px. Ensina-se
primeiro em seguranca -- o patio por baixo e' chao -- e com pressao: um
Arqueiro das Sombras no topo dispara para o poco e um Sino Flutuante
patrulha o caminho. Quem preferir pode escalar a parede do poco.
""")
com("""O patio continua por baixo do topo do poco ate' a' sala: e' a REDE da
luta com o Arqueiro (cair do topo devolve ao elevador, nao ao vazio).""")
plat("Patio", 4180, 5300, 420, h=60, av=120)
assente("GargulaPatio", "gargula", 4320, 420, esc=1.4, z=-1)
E_X, E_W, E_BASE, E_CURSO = 4630.0, 140.0, 394.0, -300.0
no("ElevadorPoco", f'position = {v(E_X, E_BASE + 8)}\nscript = ExtResource("{ID["elevcol"]}")\n'
                   f"curso = {v(0, E_CURSO)}\nvelocidade = 95.0\nlargura = {E_W:g}\n"
                   "altura_ancora = 150.0", inst="elev")
luz("LuzRoldana", E_X, E_BASE + E_CURSO - 140, 0.55, OURO, (1.3, 1.1))
plat("TopoEscada", 4700, 5180, 120, h=40, av=90)
inimigo("SinoFlutuanteEscada", 4560, 240, "sino_flutuante", "voador", 45, 12, 90, RIM_SINO)
inimigo("ArqueiroEscada", 5120, 80, "arqueiro_das_sombras", "cuspidor", 50, 14, 30, RIM_ARQ)
heras("HerasTopo", 4730, 120 + 40, esc=0.8)
assente("FlamulaTopo", "flamula", 5060, 60, esc=1.6, z=-3)

# ======================================================================
#  C) SALA DO GRANDE SINO -- desafio final de travessia (sem guardiao)
# ======================================================================
com("""
===================  C) SALA DO GRANDE SINO  (testar)  =================
Encontro 4: dois Acolitos e uma Sentinela no chao da sala. O SINO desta
sala fica no FUNDO, atras deles: alem de erguer a ponte final, GELA os
inimigos 2,6 s -- quem passar por eles (dash/pogo) e o tocar ganha a luta
(ensina a ler o sino como ferramenta). Longe da luta para um golpe perdido
nao o desligar. A ponte final cruza um vao sem rede, com uma lamina lenta a
meio: e' o exame do nivel.
DEC-012: o 1.o nivel da regiao nao tem guardiao.
""")
plat("SalaSino", 5240, 5900, 120, h=60, av=120)
corrente("CorrenteGrandeSino", 5560, -460, -296, z=-4)
com("""O grande sino pende ALTO e mais escuro: e' o landmark, nao pode competir
com a leitura da luta que acontece por baixo.""")
pendurado("GrandeSino", "sino_g", 5560, -300, esc=2.6, z=-3, mod="Color(0.8, 0.78, 0.9, 1)")
fx("BrilhoGrandeSino", "p_brilho_sino", 5560, -150, esc=2.0, z=-2, mod="Color(1, 0.85, 0.6, 0.5)")
luz("LuzGrandeSino", 5560, -120, 0.6, OURO, (3.4, 2.2))
inimigo("SentinelaSala", 5420, 80, "sentinela_da_torre", "escudeiro", 80, 18, 90, RIM_SENT)
inimigo("AcolitoSala1", 5600, 80, "acolito_do_eco", "cuspidor", 60, 14, 60, RIM_ACOLITO)
inimigo("AcolitoSala2", 5700, 80, "acolito_do_eco", "patrulha", 60, 14, 60, RIM_ACOLITO)
sino("SinoSala", 5860, 66, "sino_final")
ponte_eco("PonteFinal", [(5960, 120), (6110, 110), (6260, 100)], "sino_final")
no("LaminaPonteFinal", f"position = {v(6160, -70)}\ncomprimento = 130.0\namplitude_graus = 48.0\n"
                       f"periodo = 3.6\nfase = 0.4\ndano = 16\ntextura = {tex('p_lamina_pendular')}",
   inst="pend")
plat("Saida", 6400, 6700, 100, h=60, av=120)
assente("EstatuaSaida", "estatua_anjo", 6640, 100, esc=1.7, z=-3, flip=True)
luz("LuzSaida", 6560, 50, 0.6, LUA, (2.0, 1.6))

# ======================================================================
#  VIDA DA TORRE -- detritos, poeira, neblina (so' visual)
# ======================================================================
for nome, t, x, y, e in [
        ("DetritosEntrada", "p_detritos", 30, 900, 0.55), ("PoeiraAtrio", "p_poeira_chao", 1220, 760, 0.6),
        ("DetritosMuralha", "p_detritos", 2410, 440, 0.45), ("PoeiraGaleria", "p_poeira_chao", 3600, 420, 0.55),
        ("DetritosSala", "p_detritos", 5870, 120, 0.5)]:
    assente(nome, t, x, y, esc=e, z=0, mod="Color(0.8, 0.82, 1, 1)")
fx("NeblinaEntrada", "p_neblina", 900, 980, esc=3.0, z=1, mod="Color(0.6, 0.7, 1, 0.3)")
fx("NeblinaVao", "p_neblina", 2800, 700, esc=3.2, z=1, mod="Color(0.6, 0.7, 1, 0.3)")
fx("NeblinaPonte", "p_neblina", 6150, 380, esc=3.0, z=1, mod="Color(0.6, 0.7, 1, 0.3)")
fx("LuzVitralArena", "p_particulas_luz", 3840, 240, esc=1.2, z=3, mod="Color(0.8, 0.7, 1, 0.6)")

# ======================================================================
#  Koliani, checkpoints, porta
# ======================================================================
no("Koliani", f"position = {v(140, 860)}\nusar_prototipo_premium = true\nusar_golden_set = true\n"
   "combate_hitstop_v2 = true", inst="kol")
com("""Cinco checkpoints, nenhum em plataforma movel/fantasma/quebradica.""")
check("CheckInicio", 300, 900)
check("CheckAtrio", 1200, 760)
check("CheckMuralha", 2160, 440)
check("CheckGaleria", 3525, 420)
check("CheckSala", 5280, 120)
no("Porta", f'position = {v(6600, 106)}\npista_ao_atravessar = ""', inst="porta")

# ---------------------------------------------------------------- escrever
corpo_nos = "\n".join(nos)
linhas_ext = [l for l in linhas_ext if 'ExtResource("%s")' % l.split(' id="')[1][:-2] in corpo_nos]
cab = f'[gd_scene load_steps={len(linhas_ext) + 5} format=3 uid="uid://bkolianitorresinos11"]'
topo = """
; REGIAO III / nivel 11 -- ENTRADA DOS ECOS (`level.n10`), "O Primeiro
; Chamamento". O nome do ficheiro fica: muda-lo partia saves e checkpoints.
;
; GERADO por `tools/construir_n11_entrada.py` -- editar la', nao aqui.
; Desenho, medicoes e o que ficou por decidir: `docs/nivel_autoral_n11.md`.
;
; Refeito de raiz (DEC-014, 3 out 2026). Estrutura: A) entrada + 1.o sino
; (com rede) -> Encontro 1 (atrio) -> 1.a escalada -> B) passarelas
; externas (correntes moveis, passarela quebrada, lamina lenta) -> Encontro 2
; (galeria SELADA ate' limpar, DEC-013) -> Encontro 3 (poco do elevador
; com arqueiro) -> C) sala do grande sino (Encontro 4 + ponte final). Sem
; guardiao (DEC-012). 2 segredos, 5 checkpoints, ~6 700 px.
"""
subs = """
[sub_resource type="RectangleShape2D" id="rs_chk"]
size = Vector2(44, 96)

[sub_resource type="CanvasItemMaterial" id="mat_add"]
blend_mode = 1

[sub_resource type="Gradient" id="grad_luz"]
offsets = PackedFloat32Array(0, 1)
colors = PackedColorArray(1, 1, 1, 1, 1, 1, 1, 0)

[sub_resource type="GradientTexture2D" id="tex_luz"]
gradient = SubResource("grad_luz")
width = 256
height = 256
fill = 1
fill_from = Vector2(0.5, 0.5)
fill_to = Vector2(1, 0.5)
"""
with open(SAIDA, "w", encoding="utf-8", newline="\n") as f:
    f.write(cab + "\n" + topo + "\n" + "\n".join(linhas_ext) + "\n" + subs + "\n"
            + "\n".join(nos).rstrip() + "\n")
print("escrito", SAIDA, "--", sum(1 for n in nos if n.startswith("[node")), "nos")
