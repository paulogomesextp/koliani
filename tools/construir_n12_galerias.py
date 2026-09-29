#!/usr/bin/env python3
"""Gera `scenes/levels/Torre_dos_Ventos.tscn` -- N12 "Galerias Verticais".

A cena e' AUTORAL (desenhada a mao, seccao a seccao), mas tem ~120 nos com
coordenadas que dependem umas das outras (topo de uma plataforma = altura do
salto a partir da anterior). Escreve-la a mao no `.tscn` era garantir que um
ajuste num degrau desalinhava tres outros. Aqui cada plataforma e' dada pelo
TOPO e pelas bordas esquerda/direita -- que e' como o crivo de alcance
(`tools/verifica_alcance.gd`) e o jogador a leem -- e a posicao/tamanho do
no' calculam-se.

EDITAR AQUI e voltar a correr; nao editar o `.tscn` a mao:
    python tools/construir_n12_galerias.py

Contrato: docs/art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md
(N12 -- LOCKED). Desenho e medicoes: docs/nivel_autoral_n12.md.
"""
from __future__ import annotations

import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "scenes", "levels", "Torre_dos_Ventos.tscn")

# COORDENADAS DE DESENHO vs. MUNDO. Desenha-se com o chao da base a y=2400 e
# o topo da torre perto de y=0 (numeros positivos, faceis de ler e de somar),
# mas a Koliani MORRE abaixo de `koliani.gd::Y_MORTE` (1200) -- e' o "fosso
# sem fundo" global. Por isso, ao escrever, TODAS as `position` descem DY:
# o chao da base fica a 1000 e a arena a -1400. Os comentarios deste ficheiro
# (e o docs/nivel_autoral_n12.md) falam em coordenadas de DESENHO.
DY = -1400.0

# Paleta LOCKED da regiao (pedra antiga; as cores de `Plataforma` sao ignoradas
# pelo visual pixel-art, mas mantem-se coerentes com o N11).
PEDRA = "cor_base = Color(0.24, 0.2, 0.26, 1)\ncor_topo = Color(0.5, 0.44, 0.54, 1)"

EXT = [
    ("PackedScene", "uid://bkolianiactor01", "res://scenes/actors/Koliani.tscn", "kol"),
    ("PackedScene", "uid://bdemoniobase01", "res://scenes/actors/DemonioBase.tscn", "dem"),
    ("PackedScene", "uid://bkolianiporta01", "res://scenes/actors/Porta.tscn", "porta"),
    ("Script", None, "res://scripts/checkpoint.gd", "chk"),
    ("Script", None, "res://scripts/nivel_com_chefe.gd", "niv"),
    ("PackedScene", "uid://bkolianiatmosfera01", "res://scenes/fx/Atmosfera.tscn", "atm"),
    ("PackedScene", "uid://bkolianiplataforma01", "res://scenes/actors/Plataforma.tscn", "pl"),
    ("PackedScene", "uid://bkolianisinotorre11", "res://scenes/actors/SinoTorre.tscn", "sino"),
    ("PackedScene", "uid://bkolianiaguavenenosa01", "res://scenes/actors/AguaVenenosa.tscn", "vazio"),
    ("PackedScene", "uid://bkolianiplatsino11", "res://scenes/actors/PlataformaSino.tscn", "eco"),
    ("PackedScene", "uid://bkolianipendulolamina01", "res://scenes/actors/PenduloLamina.tscn", "pend"),
    ("PackedScene", "uid://bkolianiplataquebra01", "res://scenes/actors/PlataformaQuebra.tscn", "quebra"),
    ("PackedScene", "uid://bkolianiplatritmada05", "res://scenes/actors/PlataformaRitmada.tscn", "ritmo"),
    ("PackedScene", "uid://bkolianiessencia01", "res://scenes/actors/Essencia.tscn", "ess"),
    ("PackedScene", "uid://bkolianitumuloelev16", "res://scenes/actors/TumuloElevador.tscn", "elev"),
    ("Script", None, "res://scripts/elevador_coluna.gd", "elevcol"),
    ("PackedScene", "uid://bkolianicorrentear12", "res://scenes/actors/CorrenteAr.tscn", "ar"),
    ("PackedScene", None, "res://scenes/actors/WindZone.tscn", "vento"),
    ("PackedScene", "uid://bkolianivitral24", "res://scenes/actors/Vitral.tscn", "vitral"),
    ("PackedScene", "uid://bkolianiserra01", "res://scenes/actors/Serra.tscn", "serra"),
]
# texturas: props da prancha aprovada (`tools/gerar_props_prancha.py` e
# `tools/gerar_props_n12_prancha.py`). Os props antigos ainda geometricos do
# catalogo (velas, janela_gotica, balaustrada, arco_pequeno, memorial) NAO
# entram no N12.
TEXTURAS = [
    "vitral_alto", "vitral_partido", "sino_m", "sino_g", "coluna_igreja",
    "coluna_dupla", "arco_grande", "corrente_t",
    "lanterna_eco", "candelabro", "estatua_anjo", "flamula",
    "pedra_memoria", "gargula",
    "relogio_antigo", "tocha", "sino_partido", "livros", "urna", "lampiao_t",
    # pecas da prancha so' do N12 (`tools/gerar_props_n12_prancha.py`)
    "p_parede", "p_parede_gasta", "p_parede_vitral", "p_torre_lateral",
    "p_parede_destruida", "p_vitral_dourado", "p_rosacea", "p_vitral_pequeno",
    "p_plat_corrente", "p_updraft", "p_estrutura_vertical", "p_passarela",
    "p_suporte", "p_lamina_pendular", "p_lamina_rotativa", "p_particulas_luz",
    "p_poeira_ar", "p_brilho_sino", "p_raios_luz", "p_neblina", "p_heras",
    "p_detritos", "p_poeira_chao",
]
for t in TEXTURAS:
    EXT.append(("Texture2D", None, f"res://assets/sprites/pixel/deco/torres/{t}.png", "t_" + t))
# miolo do terreno da prancha (feito para repetir sem costura): parede da nave
EXT.append(("Texture2D", None, "res://assets/sprites/pixel/terreno/torre_ecos/corpo.png",
            "t_corpo_te"))

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
       pai: str = ".") -> None:
    cab = f'[node name="{nome}"'
    if tipo:
        cab += f' type="{tipo}"'
    cab += f' parent="{pai}"'
    if inst:
        cab += f' instance=ExtResource("{ID[inst]}")'
    cab += "]"
    nos.append(cab)
    if corpo:
        nos.append(corpo.strip("\n"))
    nos.append("")


def v(x: float, y: float) -> str:
    return f"Vector2({x:g}, {y:g})"


# ---------------------------------------------------------------- geometria
# Plataformas por TOPO + bordas. Guardam-se para o resto do script (luzes,
# inimigos, checkpoints) poder ancorar-se nelas por nome.
PL: dict[str, dict] = {}


def plat(nome: str, esq: float, dir: float, topo: float, h: float = 22.0,
         av: float | None = None, inst: str = "pl", extra: str = "") -> None:
    cx = (esq + dir) / 2.0
    cy = topo + h / 2.0
    PL[nome] = {"esq": esq, "dir": dir, "topo": topo}
    if av is None:
        av = 34.0 if h <= 30 else 0.0
    corpo = f"position = {v(cx, cy)}\ntamanho = {v(dir - esq, h)}"
    if inst in ("pl", "eco", "ritmo"):
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


def inimigo(nome: str, x: float, y: float, especie: str, comp: str, vida: int,
            dano: int, patrulha: float, rim: str, elite: bool = False,
            escala: float = 1.0) -> None:
    c = f"position = {v(x, y)}\n"
    if escala != 1.0:
        c += f"scale = {v(escala, escala)}\n"
    if elite:
        c += "elite = true\n"
    c += (f'especie = "{especie}"\nvida = {vida}\ndano_contacto = {dano}\n'
          f'comportamento = "{comp}"\nalcance_patrulha = {patrulha:g}\ncor_rim = {rim}')
    no(nome, c, inst="dem")


# tamanho real de cada PNG (lido do disco: os props mudam quando se regeram
# a partir da prancha -- `tools/gerar_props_prancha.py`)
def _tam_png(caminho: str) -> tuple:
    with open(caminho, "rb") as f:
        cab = f.read(24)
    return int.from_bytes(cab[16:20], "big"), int.from_bytes(cab[20:24], "big")


TAM_TEX = {t: _tam_png(os.path.join(RAIZ, "assets/sprites/pixel/deco/torres", f"{t}.png"))
           for t in TEXTURAS}


def assente(nome: str, tex: str, x: float, base_y: float, esc: float = 2.0,
            z: int = -2, mod: str = "", flip: bool = False) -> None:
    """Prop assente numa superficie: `base_y` = topo da plataforma."""
    h = TAM_TEX[tex][1] * esc
    c = (f"position = {v(x, base_y - h / 2.0 + 2.0)}\nscale = {v(esc, esc)}\n"
         f'texture = ExtResource("{ID["t_" + tex]}")\nz_index = {z}')
    if flip:
        c += "\nflip_h = true"
    if mod:
        c += f"\nmodulate = {mod}"
    no(nome, c, tipo="Sprite2D")


def pendurado(nome: str, tex: str, x: float, topo_y: float, esc: float = 2.0,
              z: int = -2, mod: str = "") -> None:
    """Prop pendurado: `topo_y` = onde fica preso (topo do sprite)."""
    h = TAM_TEX[tex][1] * esc
    c = (f"position = {v(x, topo_y + h / 2.0)}\nscale = {v(esc, esc)}\n"
         f'texture = ExtResource("{ID["t_" + tex]}")\nz_index = {z}')
    if mod:
        c += f"\nmodulate = {mod}"
    no(nome, c, tipo="Sprite2D")


def corrente(nome: str, x: float, y0: float, y1: float, z: int = -3,
             mod: str = "Color(0.95, 0.8, 0.5, 0.9)") -> None:
    """Corrente dourada a pender de `y0` ate' `y1` (mosaico vertical)."""
    comp = y1 - y0
    c = (f"position = {v(x - 5, y0)}\ntexture_repeat = 2\n"
         f'texture = ExtResource("{ID["t_corrente_t"]}")\ncentered = false\n'
         f"region_enabled = true\nregion_rect = Rect2(0, 0, 10, {comp:g})\n"
         f"z_index = {z}\nmodulate = {mod}")
    no(nome, c, tipo="Sprite2D")


def luz(nome: str, x: float, y: float, energia: float, cor: str, esc: tuple,
        pai: str = ".") -> None:
    no(nome, f'position = {v(x, y)}\ntexture = SubResource("tex_luz")\n'
             f"energy = {energia:g}\ncolor = {cor}\nscale = {v(*esc)}",
       tipo="PointLight2D", pai=pai)


def mosaico(nome: str, tex: str, x0: float, y0: float, x1: float, y1: float,
            esc: float = 1.0, z: int = -9, mod: str = "", add: bool = False) -> None:
    """Textura repetida a encher o retangulo (x0,y0)-(x1,y1) do mundo."""
    w, h = (x1 - x0) / esc, (y1 - y0) / esc
    c = (f"position = {v(x0, y0)}\nscale = {v(esc, esc)}\ncentered = false\n"
         f'texture = ExtResource("{ID["t_" + tex]}")\ntexture_repeat = 2\n'
         f"region_enabled = true\nregion_rect = Rect2(0, 0, {w:g}, {h:g})\nz_index = {z}")
    if mod:
        c += f"\nmodulate = {mod}"
    if add:
        c += '\nmaterial = SubResource("mat_add")'
    no(nome, c, tipo="Sprite2D")


def fx(nome: str, tex: str, x: float, y: float, esc: float = 1.0, z: int = 2,
       mod: str = "Color(1, 1, 1, 0.8)", rot: float = 0.0) -> None:
    """Efeito pintado da prancha (raios de luz, poeira, particulas) em ADD."""
    c = (f"position = {v(x, y)}\nscale = {v(esc, esc)}\n"
         f'texture = ExtResource("{ID["t_" + tex]}")\nz_index = {z}\nmodulate = {mod}\n'
         'material = SubResource("mat_add")')
    if rot:
        c += f"\nrotation = {rot:g}"
    no(nome, c, tipo="Sprite2D")


def heras(nome: str, x: float, topo_y: float, esc: float = 0.8, flip: bool = False) -> None:
    """Heras a pender da aresta de baixo de uma plataforma (a' frente dela)."""
    pendurado(nome, "p_heras", x, topo_y - 6, esc=esc, z=1,
              mod="Color(0.78, 0.84, 1, 1)")
    if flip:
        nos[-2] += "\nflip_h = true"


OURO = "Color(1.0, 0.76, 0.45, 1)"
LUA = "Color(0.55, 0.7, 1.0, 1)"
ROXO = "Color(0.72, 0.5, 1.0, 1)"

# ======================================================================
#  CABECALHO / RAIZ
# ======================================================================
no("Torre_dos_Ventos",
   f'script = ExtResource("{ID["niv"]}")\ncorredor = false\n'
   "alongar_plataformas = false\ncheckpoints_autorais = true\n"
   'mecanica_anunciada = "elevador_coluna"\nestreia_x_autoral = 835.0',
   tipo="Node2D", pai="")
nos[0] = nos[0].replace(' parent=""', "")

no("Atmosfera", """cor_ambiente = Color(0.88, 0.9, 1.04, 1)
cor_fundo = Color(0.04, 0.05, 0.13, 1)
cor_silhueta = Color(0.08, 0.09, 0.2, 1)
cor_luz = Color(1, 0.8, 0.52, 1)
cor_poeira = Color(1, 0.9, 0.74, 1)
densidade_poeira = 1.3
bioma = "torres"
largura_nivel = 3000.0
fundo_pack = "torre_ecos"
tinta_fundo = Color(0.84, 0.9, 1.18, 1)
neblina_fundo = 0.32
dessaturar_fundo = 0.18
seed_ambiente = 1412
luzes_horizonte = true""", inst="atm")

# ======================================================================
#  NAVE DA TORRE -- a parede do fundo
# ======================================================================
com("""
NAVE DA TORRE -- a parede do fundo, SO' visual, atras de tudo. O panorama
do pack `torre_ecos` (prancha) e' o ceu e a cidade la' fora; isto e' a
torre por dentro, como nas pranchas "Galerias com vitrais" / "Poco
vertical": pilares de cantaria a toda a altura, arcadas de galeria a cada
andar (o ceu ve-se pelos vaos), vitrais com raios de luz de lua a cair.
Tudo recortado da prancha aprovada (`tools/gerar_props_n12_prancha.py`),
escurecido para recuar e nao competir com o que se pisa.
""")
# fora dos pontos de leitura do jogo (sinos 1250/1830, elevadores 835/1030,
# coluna de ar 710, vitral 792, sino da arena 2630)
PILARES = [-40, 560, 1480, 2230, 3040]
TOPO_NAVE, BASE_NAVE = -700.0, 2520.0
ANDARES = [2400, 1740, 1060, 380, -300]      # linhas de galeria (desenho)
PILAR = "Color(0.34, 0.37, 0.6, 1)"
ARCADA = "Color(0.32, 0.35, 0.6, 1)"
PAREDE = "Color(0.13, 0.14, 0.25, 1)"   # sombra: o ornamento e' que da' a leitura

# parede de cada andar ACIMA da arcada (a arcada deixa ver o ceu; por cima
# dela e' torre fechada, com os vitrais) -- sem isto metade de cada ecra
# era ceu liso
for j, y in enumerate(ANDARES[1:], start=1):
    y_topo = ANDARES[j + 1] if j + 1 < len(ANDARES) else TOPO_NAVE
    mosaico(f"ParedeNave{j}", "corpo_te", -120, y_topo, 3140, y - 224,
            esc=1.0, z=-11, mod=PAREDE)

for i, x in enumerate(PILARES):
    # tochas nos pilares, uma por andar: os pontos de ouro quente da prancha.
    # SEM PointLight2D (nem nos vitrais da nave): sao dezenas, e luzes 2D sao
    # o que mais pesa no telemovel -- a chama e os raios pintados chegam.
    for j, y in enumerate(ANDARES):
        assente(f"TochaNave{i}_{j}", "tocha", x, y - 250, esc=1.0, z=-8)
    mosaico(f"PilarNave{i}", "p_parede", x - 40, TOPO_NAVE, x + 40, BASE_NAVE,
            esc=1.18, z=-9, mod=PILAR)
    for j, y in enumerate(ANDARES):
        # capitel/misula a segurar a galeria em cada andar
        pendurado(f"MisulaNave{i}_{j}", "p_suporte", x, y - 150, esc=1.15, z=-8,
                  mod=PILAR)
# arcadas: uma por vao e por andar (ceu pelos vaos)
for j, y in enumerate(ANDARES[1:], start=1):
    for i in range(len(PILARES) - 1):
        x0, x1 = PILARES[i] + 40, PILARES[i + 1] - 40
        mosaico(f"ArcadaNave{j}_{i}", "p_passarela", x0, y - 224, x1, y,
                esc=1.4, z=-10, mod=ARCADA)
# vitrais altos entre os pilares (dois modelos da prancha, alternados), com
# os raios de lua a cair deles. Vaos largos levam dois.
n_jan = 0
for j, y in enumerate(ANDARES):
    for i in range(len(PILARES) - 1):
        a, b = PILARES[i], PILARES[i + 1]
        n = 2 if b - a > 780 else 1
        for k in range(n):
            x = a + (b - a) * (k + 1) / (n + 1)
            topo_jan = y - 600 if j == 0 else y - 520
            tex = "p_vitral_dourado" if (i + j + k) % 2 == 0 else "p_parede_vitral"
            esc = 1.6
            pendurado(f"VitralNave{n_jan}", tex, x, topo_jan, esc=esc, z=-8,
                      mod="Color(0.78, 0.84, 1, 0.95)")
            h = TAM_TEX[tex][1] * esc
            # arco de pedra com friso dourado a emoldurar o vitral
            assente(f"ArcoNave{n_jan}", "arco_grande", x, topo_jan + h + 24, esc=2.15, z=-9,
                    mod="Color(0.5, 0.52, 0.78, 1)")
            fx(f"RaiosNave{n_jan}", "p_raios_luz", x + 46, topo_jan + h + 56, esc=1.5, z=-7,
               mod="Color(0.7, 0.8, 1, 0.4)")
            n_jan += 1
# rosaceas sobre cada pilar, a meio da parede de cada andar
for j, y in enumerate(ANDARES[1:], start=1):
    for i, x in enumerate(PILARES[1:-1], start=1):
        assente(f"RosaceaNave{j}_{i}", "p_rosacea", x, y - 330, esc=1.2, z=-8,
                mod="Color(0.72, 0.78, 1, 0.9)")

com("""Cair ao fundo do poco = morte. Tudo o resto tem rede por baixo.""")
no("Vazio", "position = Vector2(1450, 2780)\nlargura = 3600.0\naltura = 340.0\n"
            "cor = Color(0.05, 0.04, 0.11, 0.97)", inst="vazio")

# ======================================================================
#  A) BASE DAS GALERIAS -- ENSINO (sem inimigos, sem vazio por baixo)
# ======================================================================
com("""
===================  A) BASE DAS GALERIAS  (ensinar)  ==================
Chao largo, sem inimigos. Primeiro ELEVADOR DE COLUNA: a roldana ve-se la'
em cima antes de subir. O bloco A2 fecha o poco pela direita -- o unico
caminho e' subir na plataforma (440 px, fora do alcance do salto duplo).
""")
plat("ChaoBase", 0, 2140, 2400, h=60, av=130)
assente("ColunaBase1", "coluna_igreja", 90, 2400, esc=1.6, z=-3,
        mod="Color(0.72, 0.74, 0.92, 1)")
assente("VitralBase", "vitral_alto", 330, 2250, esc=2.6, z=-4,
        mod="Color(0.85, 0.9, 1, 0.95)")
luz("LuzVitralBase", 330, 2080, 0.55, LUA, (1.6, 2.4))
assente("ColunaBase2", "coluna_igreja", 560, 2400, esc=1.6, z=-3,
        mod="Color(0.72, 0.74, 0.92, 1)")
assente("SinoPartidoBase", "sino_partido", 230, 2400, esc=2.0, z=-1)
assente("VelasBase", "candelabro", 470, 2400, esc=1.1, z=-1)
luz("LuzVelasBase", 470, 2360, 0.5, OURO, (1.4, 1.0))

# Elevador 1 -- peso (sobe com a Koliani em cima, desce quando ela sai).
# Assenta NO chao (degrau de 26 px), nao num buraco.
E1_X, E1_W, E1_BASE, E1_CURSO = 835.0, 150.0, 2374.0, -334.0
no("Elevador1", f'position = {v(E1_X, E1_BASE + 8)}\nscript = ExtResource("{ID["elevcol"]}")\n'
                f"curso = {v(0, E1_CURSO)}\nvelocidade = 95.0\nlargura = {E1_W:g}\n"
                "altura_ancora = 150.0", inst="elev")
luz("LuzRoldana1", E1_X, E1_BASE + E1_CURSO - 150 + 8, 0.55, OURO, (1.3, 1.1))

com("""
A2: galeria FINA a 360 px do chao (fora do alcance do salto duplo, ~250
px, e SEM face de parede para escalar -- `escalar_paredes` ja' existe e
uma parede alta aqui tornava o elevador opcional). Por baixo, o salao
inferior (ChaoBase2). A2 continua para a direita por baixo da ponte do
sino: e' a REDE do ensino do sino (cair da ponte = aterrar aqui).
""")
assente("ColunaSalao1", "coluna_dupla", 1180, 2400, esc=1.7, z=-3,
        mod="Color(0.72, 0.74, 0.92, 1)")
assente("ColunaSalao2", "coluna_dupla", 1700, 2400, esc=1.7, z=-3,
        mod="Color(0.72, 0.74, 0.92, 1)")
assente("ArcoSalao", "arco_grande", 1440, 2400, esc=1.9, z=-4,
        mod="Color(0.7, 0.72, 0.9, 1)")
assente("UrnaSalao", "urna", 1960, 2400, esc=1.5, z=-1)
plat("A2", 910, 2140, 2040, h=30)
assente("CandelabroA2", "candelabro", 1020, 2040, esc=1.6, z=-1)
luz("LuzCandA2", 1020, 1980, 0.5, OURO, (1.5, 1.1))

com("""
SEGREDO 1 -- a alcova da roldana. So' se chega saltando do elevador JA' em
cima (20 px de vao, 100 de subida). Do chao nao se ve o que la' esta'.
""")
plat("Segredo1", 620, 730, 1940)
ess("EssenciaSegredo1", 675, 1940, 20)
assente("MemorialSegredo1", "pedra_memoria", 705, 1940, esc=1.6, z=-1)
luz("LuzSegredo1", 675, 1910, 0.35, ROXO, (0.9, 0.8))

com("""
PRIMEIRO SINO DE SINCRONIZACAO. Tocar-lhe faz aparecer a ponte S1-S3 (tres
degraus fantasma, grupo `sino_sync_a`). Tocar outra vez desfaz: e' o
retry. Por baixo da ponte esta' o A2 inteiro -- errar custa 3 s, nao a vida.
""")
no("SinoA", f"position = {v(1250, 1985)}\nscale = {v(1.3, 1.3)}\n"
            'alterna_grupo = "sino_sync_a"\n'
            f'textura = ExtResource("{ID["t_sino_m"]}")', inst="sino")
luz("LuzSinoA", 1250, 1970, 0.6, OURO, (1.3, 1.2))
corrente("CorrenteSinoA", 1250, 1780, 1950)
for i, (e, t) in enumerate([(1330, 1950), (1460, 1860), (1590, 1770)], start=1):
    plat(f"PonteA{i}", e, e + 100, t, h=20, av=16, inst="eco",
         extra='grupo_alternar = "sino_sync_a"')

plat("A3", 1720, 2140, 1660, h=24, av=60)
assente("VitralA3", "vitral_alto", 1850, 1600, esc=2.3, z=-4,
        mod="Color(0.85, 0.9, 1, 0.95)")
luz("LuzVitralA3", 1850, 1450, 0.5, LUA, (1.4, 2.2))
assente("FlamulaA3", "flamula", 2100, 1580, esc=1.8, z=-3)

# ======================================================================
#  B) ASCENSAO -- DESENVOLVER (escadas quebradas, ritmo, 2.o elevador)
# ======================================================================
com("""
===================  B) ASCENSAO POR PLATAFORMAS  (desenvolver)  ===========
Monge das Correntes na galeria A3 (longe da aterragem da ponte: 280 px).
""")
inimigo("MongeA3", 2000, 1610, "monge_das_correntes", "carga", 70, 16, 80,
        "Color(0.85, 0.7, 0.45, 1)")

com("""
ESCADAS QUEBRADAS -- degraus `PlataformaQuebra` em ziguezague num poco com
rede (PisoPoco) por baixo. Os degraus voltam (respawn 2,6 s).
""")
quebra("Degrau1", 2170, 2260, 1570)
quebra("Degrau2", 2300, 2390, 1490)
plat("Patamar1", 2420, 2580, 1410, h=30)
quebra("Degrau3", 2290, 2380, 1330)
quebra("Degrau4", 2150, 2240, 1250)
plat("R2", 1960, 2130, 1170, h=30)
plat("PisoPoco", 2140, 2760, 1770, h=40, av=90)
inimigo("GargulaPoco", 2560, 1600, "gargula_vitral", "voador", 50, 14, 90,
        "Color(0.6, 0.7, 1.0, 1)")
corrente("CorrentePoco1", 2280, 1190, 1760, z=-4)
corrente("CorrentePoco2", 2470, 1190, 1760, z=-4)
assente("ColunaPoco", "coluna_dupla", 2700, 1770, esc=1.6, z=-4,
        mod="Color(0.7, 0.72, 0.9, 1)")
luz("LuzPoco", 2400, 1720, 0.5, OURO, (2.2, 1.2))

com("""
LAMINA DE SINO RAPIDA a guardar o lado direito do Patamar1 -- e o vitral do
SEGREDO 2 que la' esta'. Quem so' quer subir usa a ponta esquerda do
patamar, fora do arco.
""")
no("LaminaPatamar", f"position = {v(2530, 1280)}\ncomprimento = 90.0\n"
                    "amplitude_graus = 58.0\nperiodo = 1.5\ndano = 18\n"
                    f'textura = ExtResource("{ID["t_p_lamina_pendular"]}")', inst="pend")
no("VitralSegredo", f"position = {v(2600, 1344)}\n"
                    'grupo_luz = "vitral_segredo"\ncor_luz = Color(0.55, 0.7, 1.0, 1)\n'
                    f'textura_inteiro = ExtResource("{ID["t_vitral_alto"]}")\n'
                    f'textura_partido = ExtResource("{ID["t_vitral_partido"]}")', inst="vitral")
plat("Segredo2", 2620, 2760, 1410, h=30)
com("""Tecto da alcova: o vitral encosta-lhe, nao se salta por cima dele.""")
plat("TectoSegredo2", 2590, 2780, 1236, h=40)
ess("EssenciaSegredo2", 2700, 1410, 25)
assente("UrnaSegredo2", "urna", 2740, 1410, esc=1.5, z=-1)
assente("LivrosSegredo2", "livros", 2650, 1410, esc=1.5, z=-1)
luz("LuzSegredo2", 2690, 1370, 0.35, ROXO, (0.9, 0.8))

com("""R2: patamar seguro no topo das escadas. CheckB.""")
assente("LanternaR2", "lanterna_eco", 2100, 1170, esc=1.6, z=-1)
luz("LuzR2", 2100, 1120, 0.55, OURO, (1.4, 1.1))

com("""
PLATAFORMAS QUE DESAPARECEM -- tres `PlataformaRitmada` em fase escalonada
(0 / 0,8 / 1,6 s). Aviso de 0,5 s antes de sumirem. Rede (Balcao) por
baixo das duas primeiras: cair devolve ao R2, nao ao fundo.
""")
for i, (e, t, f) in enumerate([(1780, 1170, 0.0), (1600, 1160, 0.8), (1420, 1150, 1.6)], start=1):
    plat(f"Ritmo{i}", e, e + 100, t, h=22, inst="ritmo",
         extra=f"periodo = 2.4\nfantasma_seg = 1.0\nfase = {f:g}\naviso = 0.5")
plat("Balcao", 1640, 1900, 1280, h=26)

plat("R3", 1100, 1340, 1130, h=30)
assente("GargulaR3", "gargula", 1320, 1130, esc=1.5, z=-1)

com("""
2.o ELEVADOR -- vaivem continuo (`auto`), mais lento. Ensina a ESPERAR
pelo elevador em vez de o chamar. Leva ao R4, onde esta' o vitral.
""")
E2_X, E2_W, E2_BASE, E2_CURSO = 1030.0, 130.0, 1130.0, -400.0
no("Elevador2", f'position = {v(E2_X, E2_BASE + 8)}\nscript = ExtResource("{ID["elevcol"]}")\n'
                f"curso = {v(0, E2_CURSO)}\nvelocidade = 80.0\nauto = true\n"
                f"largura = {E2_W:g}\naltura_ancora = 120.0", inst="elev")
luz("LuzRoldana2", E2_X, E2_BASE + E2_CURSO - 120, 0.5, OURO, (1.2, 1.0))

com("""
R4 + VITRAL INTERACTIVO: parti-lo (golpe ou tiro) deixa entrar a luz e
REVELA a ponte de eco L1-L3 (grupo `vitral_n12`). Sem o partir, o vitral e'
parede e a ponte e' fantasma.
""")
plat("R4", 780, 960, 730, h=30)
no("VitralGalerias", f"position = {v(792, 644)}\nscale = {v(1.3, 1.3)}\n"
                     'grupo_luz = "vitral_n12"\ncor_luz = Color(0.72, 0.5, 1.0, 1)\n'
                     f'textura_inteiro = ExtResource("{ID["t_vitral_alto"]}")\n'
                     f'textura_partido = ExtResource("{ID["t_vitral_partido"]}")', inst="vitral")
for i, (e, t) in enumerate([(630, 660), (490, 590), (350, 520)], start=1):
    plat(f"PonteLuz{i}", e, e + 100, t, h=20, av=16, inst="eco",
         extra='grupo_alternar = "vitral_n12"\nalpha_fantasma = 0.1')
plat("VarandaOeste", 300, 760, 830, h=30)
assente("JanelaVaranda", "p_vitral_pequeno", 520, 810, esc=1.6, z=-4,
        mod="Color(0.8, 0.86, 1, 0.9)")
luz("LuzVaranda", 520, 700, 0.4, LUA, (1.3, 1.5))

# ======================================================================
#  C) VENTO E QUEDA CONTROLADA
# ======================================================================
com("""
===================  C) SECCAO DE VENTO E QUEDA CONTROLADA  ============
R5 (galeria oeste alta, CheckC) -> Ponte alta (Monge) -> COLUNA DE AR
ascendente -> C1 no alto -> descida por degraus quebradicos com VENTO
CONTRA a empurrar para tras. Rede por baixo encostada a' coluna: cair
devolve ao ar, nao ao inicio.
""")
plat("R5", 40, 300, 440, h=30)
assente("EstatuaR5", "estatua_anjo", 110, 440, esc=1.7, z=-2)
luz("LuzR5", 110, 330, 0.45, LUA, (1.2, 1.6))
plat("PonteAlta", 340, 640, 380, h=26)
inimigo("MongePonte", 520, 330, "monge_das_correntes", "carga", 70, 16, 70,
        "Color(0.85, 0.7, 0.45, 1)")
no("ColunaDeAr", f"position = {v(710, 95)}\ntamanho = {v(100, 710)}\n"
                 "forca = 3000.0\nvel_alvo = 460.0\n"
                 f'pele = ExtResource("{ID["t_p_updraft"]}")', inst="ar")
plat("C1", 780, 980, -140, h=30)
assente("SinoGrandeC1", "sino_g", 880, -140, esc=1.4, z=-2)
com("""SEGREDO 3 -- no cimo da coluna, do lado de la'. Sobe-se ate' ao fim do
ar e salta-se para a esquerda.""")
plat("Segredo3", 560, 650, -300)
ess("EssenciaSegredo3", 605, -300, 30)
assente("MemorialSegredo3", "pedra_memoria", 620, -300, esc=1.3, z=-1)
luz("LuzSegredo3", 605, -330, 0.35, ROXO, (0.9, 0.8))

no("VentoContra", f"position = {v(1270, -60)}\ndirecao = Vector2(-1, 0)\n"
                  "intensidade = 1300.0\nvelocidade_max = 140.0\n"
                  f"tamanho = {v(520, 360)}\nmostrar_guia = false", inst="vento")
com("""O vento contra le-se por rajadas de poeira de luz a varrer para a
esquerda (em vez das setas-guia genericas da WindZone).""")
no("RajadasVento", f"position = {v(1270, -60)}\nz_index = 3\namount = 70\nlifetime = 1.4\n"
   "preprocess = 2.0\nemission_shape = 3\nemission_rect_extents = Vector2(260, 170)\n"
   "direction = Vector2(-1, 0)\nspread = 4.0\ngravity = Vector2(0, 0)\n"
   "initial_velocity_min = 300.0\ninitial_velocity_max = 460.0\n"
   "scale_amount_min = 2.0\nscale_amount_max = 4.0\n"
   "color = Color(0.72, 0.84, 1, 0.35)", tipo="CPUParticles2D")
fx("NeblinaVento1", "p_neblina", 1120, -120, esc=2.2, z=2, mod="Color(0.7, 0.8, 1, 0.45)")
fx("NeblinaVento2", "p_neblina", 1400, 10, esc=2.0, z=2, mod="Color(0.7, 0.8, 1, 0.4)")
quebra("Queda1", 1040, 1130, -60)
quebra("Queda2", 1190, 1280, 20)
quebra("Queda3", 1340, 1430, 100)
plat("Rede", 810, 1470, 560, h=26)

# ======================================================================
#  D) CHEGADA AS GALERIAS SUPERIORES -- TESTE + GUARDIAO
# ======================================================================
com("""
===================  D) GALERIAS SUPERIORES  (testar)  =================
D1: Autómato do Sino (tanque, escudo a' frente -- fraco nas COSTAS) e o 2.o
sino de sincronizacao MESMO ao lado dele: tocar o sino ergue a ponte E
gela o Autómato 2,6 s. Ponte B com LAMINA VERTICAL RAPIDA (serra) a cortar
o salto entre B2 e B3. Rede (Varanda) por baixo, devolve ao D1.
""")
plat("D1", 1480, 1860, 180, h=40, av=100)
inimigo("AutomatoD1", 1740, 125, "automato_do_sino", "escudeiro", 110, 20, 60,
        "Color(1.0, 0.78, 0.45, 1)", escala=1.2)
inimigo("GargulaD1", 1640, 40, "gargula_vitral", "voador", 50, 14, 100,
        "Color(0.6, 0.7, 1.0, 1)")
no("SinoB", f"position = {v(1830, 128)}\nscale = {v(1.3, 1.3)}\n"
            'alterna_grupo = "sino_sync_b"\n'
            f'textura = ExtResource("{ID["t_sino_m"]}")', inst="sino")
corrente("CorrenteSinoB", 1830, -60, 96)
luz("LuzSinoB", 1830, 110, 0.6, OURO, (1.3, 1.2))
for i, (e, t) in enumerate([(1900, 130), (2040, 80), (2180, 40)], start=1):
    plat(f"PonteB{i}", e, e + 90, t, h=20, av=16, inst="eco",
         extra='grupo_alternar = "sino_sync_b"')
no("LaminaVertical", f"position = {v(2155, 140)}\npercurso = {v(0, -170)}\ntempo = 0.8\n"
                     f'textura = ExtResource("{ID["t_p_lamina_rotativa"]}")\nescala_textura = 0.42',
   inst="serra")
plat("VarandaD", 1880, 2280, 400, h=26)

com("""Arena do GUARDIAO -- laje continua unica, sem plataformas secundarias.""")
plat("GaleriaSuperior", 2300, 2960, 0, h=60, av=150)
assente("EstatuaArena1", "estatua_anjo", 2360, 0, esc=1.8, z=-3)
assente("EstatuaArena2", "estatua_anjo", 2900, 0, esc=1.8, z=-3, flip=True)
pendurado("SinoArena", "sino_g", 2630, -330, esc=2.0, z=-3)
corrente("CorrenteArena", 2630, -520, -326, z=-4)
assente("VitralArena1", "vitral_alto", 2480, -40, esc=2.6, z=-5,
        mod="Color(0.85, 0.9, 1, 0.9)")
assente("VitralArena2", "vitral_alto", 2780, -40, esc=2.6, z=-5,
        mod="Color(0.85, 0.9, 1, 0.9)")
luz("LuzVitralArena1", 2480, -220, 0.5, LUA, (1.4, 2.4))
luz("LuzVitralArena2", 2780, -220, 0.5, LUA, (1.4, 2.4))
luz("LuzArena", 2630, -30, 0.7, OURO, (3.2, 1.7))
inimigo("Guardiao", 2660, -70, "automato_do_sino", "escudeiro", 260, 24, 150,
        "Color(1.0, 0.72, 0.4, 1)", elite=True, escala=1.6)

# ======================================================================
#  VIDA DA TORRE -- heras, detritos, poeira e brilhos (so' visual)
# ======================================================================
com("""
Detalhe da prancha ("Vegetacao e detritos", "FX e particulas"): heras a
pender das galerias, entulho nos cantos, poeira de luz junto aos vitrais e
brilho dourado nos sinos. Nada em cima de onde se aterra.
""")
# heras: aresta de baixo das lajes (topo + altura da plataforma)
for nome, x, y, e, f in [
        ("HerasA2a", 960, 2040 + 30, 0.9, False), ("HerasA2b", 1990, 2040 + 30, 0.75, True),
        ("HerasA3", 2090, 1660 + 24, 0.8, False), ("HerasPatamar", 2560, 1410 + 30, 0.7, True),
        ("HerasR3", 1130, 1130 + 30, 0.8, False), ("HerasBalcao", 1870, 1280 + 26, 0.7, True),
        ("HerasVaranda", 330, 830 + 30, 0.9, False), ("HerasVaranda2", 700, 830 + 30, 0.7, True),
        ("HerasPonteAlta", 380, 380 + 26, 0.75, True), ("HerasRede", 1440, 560 + 26, 0.8, False),
        ("HerasD1", 1500, 180 + 40, 0.9, False), ("HerasVarandaD", 2250, 400 + 26, 0.7, True),
        ("HerasArena", 2330, 0 + 60, 1.0, False), ("HerasR5", 60, 440 + 30, 0.8, True)]:
    heras(nome, x, y, esc=e, flip=f)
# entulho e poeira no chao, junto a' parede/cantos
for nome, tex, x, y, e in [
        ("DetritosBase", "p_detritos", 40, 2400, 0.55), ("PoeiraBase", "p_poeira_chao", 2060, 2400, 0.6),
        ("DetritosPoco", "p_detritos", 2730, 1770, 0.5), ("PoeiraPoco", "p_poeira_chao", 2200, 1770, 0.55),
        ("DetritosR5", "p_detritos", 270, 440, 0.45), ("PoeiraArena", "p_poeira_chao", 2340, 0, 0.55),
        ("DetritosC1", "p_detritos", 960, -140, 0.45)]:
    assente(nome, tex, x, y, esc=e, z=0, mod="Color(0.8, 0.82, 1, 1)")
# poeira de luz a flutuar nos raios dos vitrais de jogo e brilho nos sinos
fx("LuzVitralGalerias", "p_particulas_luz", 800, 560, esc=1.3, z=3, mod="Color(0.8, 0.7, 1, 0.7)")
fx("LuzVitralSegredo", "p_particulas_luz", 2600, 1280, esc=1.0, z=3, mod="Color(0.7, 0.8, 1, 0.6)")
fx("BrilhoSinoA", "p_brilho_sino", 1250, 1970, esc=1.0, z=-1, mod="Color(1, 0.85, 0.6, 0.55)")
fx("BrilhoSinoB", "p_brilho_sino", 1830, 112, esc=1.0, z=-1, mod="Color(1, 0.85, 0.6, 0.55)")
fx("BrilhoSinoArena", "p_brilho_sino", 2630, -250, esc=1.6, z=-2, mod="Color(1, 0.85, 0.6, 0.5)")
fx("PoeiraArCol", "p_poeira_ar", 700, -250, esc=1.8, z=-1, mod="Color(0.75, 0.8, 1, 0.35)")
fx("NeblinaPoco", "p_neblina", 2450, 1740, esc=3.0, z=1, mod="Color(0.6, 0.7, 1, 0.35)")
fx("NeblinaBase1", "p_neblina", 700, 2380, esc=3.2, z=1, mod="Color(0.6, 0.7, 1, 0.3)")
fx("NeblinaBase2", "p_neblina", 1650, 2385, esc=3.0, z=1, mod="Color(0.6, 0.7, 1, 0.3)")

# ======================================================================
#  Koliani, checkpoints, porta
# ======================================================================
no("Koliani", f"position = {v(160, 2360)}\nusar_prototipo_premium = true\n"
              "usar_golden_set = true", inst="kol")
com("""
checkpoints_autorais = true: cinco, intencionais. Nenhum em plataforma
movel, fantasma ou quebradica; cada um antes de um passo novo.
""")
check("CheckInicio", 300, 2400)
check("CheckA", 1000, 2040)
check("CheckB", 2040, 1170)
check("CheckC", 170, 440)
check("CheckD", 1530, 180)
no("Porta", f'position = {v(2900, 6)}\npista_ao_atravessar = ""', inst="porta")

# ---------------------------------------------------------------- escrever
def _deslocar(linha: str) -> str:
    if not linha.startswith("position = Vector2("):
        return linha
    x, y = linha[len("position = Vector2("):-1].split(",")
    return f"position = Vector2({float(x):g}, {float(y) + DY:g})"


nos = [_deslocar(l) if "\n" not in l else "\n".join(_deslocar(x) for x in l.split("\n"))
       for l in nos]
corpo_nos = "\n".join(nos)
usados = [l for l in linhas_ext if 'ExtResource("%s")' % l.split(' id="')[1][:-2] in corpo_nos]
linhas_ext = usados
cab = f'[gd_scene load_steps={len(linhas_ext) + 5} format=3 uid="uid://bkolianitorreventos12"]'
topo = """
; REGIAO III / nivel 12 -- GALERIAS VERTICAIS (`level.n11`), "A Ascensao".
; O nome do ficheiro fica: muda-lo partia saves e checkpoints.
;
; GERADO por `tools/construir_n12_galerias.py` -- editar la', nao aqui.
; Desenho, medicoes e o que ficou por decidir: `docs/nivel_autoral_n12.md`.
;
; Nivel AUTORAL (`corredor = false`): a jornada procedural e a sala antiga
; do Aerion (chefe de vento sem lugar no contrato LOCKED da Regiao III)
; sairam. Estrutura do contrato (A-D), lida como ensinar/desenvolver/testar:
;   A) Base das galerias  -- elevador de coluna (peso) + 1.o sino de
;                            sincronizacao, tudo com rede, sem inimigos;
;   B) Ascensao           -- escadas quebradas, lamina rapida, plataformas
;                            que desaparecem, elevador em vaivem, VITRAL que
;                            revela a ponte de eco;
;   C) Vento e queda      -- coluna de ar ascendente + descida por degraus
;                            quebradicos contra o vento;
;   D) Galerias superiores-- Autómato + 2.o sino (ponte + gelar) + lamina
;                            vertical rapida, e o GUARDIAO (Autómato do Sino
;                            elite) a selar a porta.
; 3 segredos, 5 checkpoints, inimigos principais do contrato: Gargula
; Vitral, Autómato do Sino, Monge das Correntes.
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
