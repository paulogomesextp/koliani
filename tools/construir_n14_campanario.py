#!/usr/bin/env python3
"""Gera `scenes/levels/Observatorio_Lunar.tscn` -- N14 "Campanario".

Mesma ideia do `tools/construir_n13_mecanismos.py`: a cena e' AUTORAL, mas
as coordenadas dependem umas das outras (o topo de uma laje, o curso de um
elevador, a coluna de ar que sai pelo furo do tecto), por isso escreve-se
aqui, por TOPO e bordas, e o `.tscn` sai gerado.

EDITAR AQUI e voltar a correr; nao editar o `.tscn` a mao:
    python tools/construir_n14_campanario.py

Contrato: docs/art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md
(N14 -- LOCKED). Desenho e medicoes: docs/nivel_autoral_n14.md.

A SUBIDA ao campanario, de baixo para cima:
  A) a base da torre (interior): sinos em queda, o primeiro baloico sobre
     um fosso, Monges das Correntes;
  B) a camara dos sinos (interior): tres sinos EM SEQUENCIA acendem
     plataformas temporizadas ate' a' coluna de ar que sai pelo tecto;
  C) o ar livre, por cima dos telhados: coluna de ar, baloicos grandes
     contra o vento, a roda de plataformas circulares com laminas em cruz
     no cubo, e a corrente que muda de direcao ao som do sino;
  D) a sala do sino gigante, no alto: o sino enorme a baloicar por cima do
     Guardiao (Monge das Correntes elite).

Mobilidade que a Koliani ja' tem no N14 (e que o desenho tem de respeitar):
salto duplo (~246 px de altura, ~350 de alcance), dash e ESCALAR PAREDES
sem limite (qualquer face e' uma escada). Por isso os portoes ficam LONGE
das paredes (a coluna de ar da camara B a 480 px de cada uma), o ar livre
nao tem paredes, e o chao da sala D e' fino e preso a' parede leste.
"""
from __future__ import annotations

import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "scenes", "levels", "Observatorio_Lunar.tscn")

# Paleta LOCKED da regiao (as cores de `Plataforma` sao ignoradas pelo visual
# pixel-art, mas ficam coerentes).
PEDRA = "cor_base = Color(0.24, 0.25, 0.32, 1)\ncor_topo = Color(0.52, 0.54, 0.66, 1)"

# ---------------------------------------------------------------- alturas
YA, TA, RA = 1000.0, 460.0, 200.0      # base: chao, tecto, telhado da base
TB, RB = 150.0, -150.0                  # camara dos sinos: tecto e telhado
YD, TD = -1300.0, -1900.0               # sala do sino gigante: chao e tecto
TOPO_TORRE = -2150.0
LARG = 3400.0
FUNDO_FOSSO = 180.0

EXT = [
    ("PackedScene", "uid://bkolianiactor01", "res://scenes/actors/Koliani.tscn", "kol"),
    ("PackedScene", "uid://bdemoniobase01", "res://scenes/actors/DemonioBase.tscn", "dem"),
    ("PackedScene", "uid://bkolianiporta01", "res://scenes/actors/Porta.tscn", "porta"),
    ("Script", None, "res://scripts/checkpoint.gd", "chk"),
    ("Script", None, "res://scripts/nivel_com_chefe.gd", "niv"),
    ("PackedScene", "uid://bkolianiatmosfera01", "res://scenes/fx/Atmosfera.tscn", "atm"),
    ("PackedScene", "uid://bkolianiplataforma01", "res://scenes/actors/Plataforma.tscn", "pl"),
    ("PackedScene", "uid://bkolianisinotorre11", "res://scenes/actors/SinoTorre.tscn", "sino"),
    ("PackedScene", "uid://bkolianiplatsino11", "res://scenes/actors/PlataformaSino.tscn", "eco"),
    ("PackedScene", "uid://bkolianipendulolamina01", "res://scenes/actors/PenduloLamina.tscn", "pend"),
    ("PackedScene", "uid://bkolianiessencia01", "res://scenes/actors/Essencia.tscn", "ess"),
    ("PackedScene", "uid://bkolianitumuloelev16", "res://scenes/actors/TumuloElevador.tscn", "elev"),
    ("Script", None, "res://scripts/elevador_coluna.gd", "elevcol"),
    ("Script", None, "res://scripts/plataforma_balanco.gd", "balanco"),
    ("Script", None, "res://scripts/plataforma_orbita.gd", "orbita"),
    ("PackedScene", "uid://bkolianiserra01", "res://scenes/actors/Serra.tscn", "serra"),
    ("PackedScene", "uid://bkolianiespinhos01", "res://scenes/actors/Espinhos.tscn", "espinhos"),
    ("PackedScene", "uid://bkolianicorrentear12", "res://scenes/actors/CorrenteAr.tscn", "ar"),
    ("Script", None, "res://scripts/corrente_lateral.gd", "vento"),
    ("PackedScene", "uid://bkolianipedraqueda01", "res://scenes/actors/PedraQueda.tscn", "queda"),
    ("Script", None, "res://scripts/engrenagem_deco.gd", "gira"),
]
# texturas da prancha aprovada (`tools/gerar_props_prancha.py`,
# `tools/gerar_props_n12_prancha.py`, `tools/gerar_props_n13_prancha.py`,
# `tools/gerar_props_n14_prancha.py`)
TEXTURAS = [
    "vitral_alto", "sino_m", "sino_g", "coluna_dupla", "arco_grande", "corrente_t",
    "lanterna_eco", "candelabro", "estatua_anjo", "pedra_memoria", "tocha", "lampiao_t",
    "urna", "livros", "velas", "balaustrada", "gargula", "flamula", "janela_gotica",
    "p_parede", "p_parede_vitral", "p_vitral_dourado", "p_rosacea", "p_suporte",
    "p_torre_lateral", "p_estrutura_vertical", "p_brilho_sino", "p_raios_luz",
    "p_neblina", "p_heras", "p_detritos", "p_poeira_chao", "p_particulas_luz",
    "m_engrenagem", "m_roda", "m_tex_metal", "m_tex_madeira", "m_tex_correntes",
    # N14 -- campanario (level_mechanics.png, coluna N14)
    "c_sino_sequencia", "c_plat_oscilante", "c_updraft", "c_plat_temporizada",
    "c_sino_gigante", "c_plat_circular", "c_corrente_muda", "c_sino_queda", "c_vento",
    "c_laminas_cruz",
]
for t in TEXTURAS:
    EXT.append(("Texture2D", None, f"res://assets/sprites/pixel/deco/torres/{t}.png", "t_" + t))
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


def tex(t: str) -> str:
    return f'ExtResource("{ID["t_" + t]}")'


# ---------------------------------------------------------------- geometria
PL: dict[str, dict] = {}


def plat(nome: str, esq: float, dir: float, topo: float, h: float = 22.0,
         av: float | None = None, inst: str = "pl", extra: str = "") -> None:
    cx = (esq + dir) / 2.0
    cy = topo + h / 2.0
    PL[nome] = {"esq": esq, "dir": dir, "topo": topo}
    if av is None:
        av = 34.0 if h <= 30 else 0.0
    corpo = f"position = {v(cx, cy)}\ntamanho = {v(dir - esq, h)}"
    if inst in ("pl", "eco"):
        corpo += f"\naltura_visual = {av:g}\n{PEDRA}"
    if extra:
        corpo += "\n" + extra
    no(nome, corpo, inst=inst)


def laje(nome: str, esq: float, dir: float, topo: float, base: float,
         escurecer: bool = True) -> None:
    """Laje grossa de pedra (chao de um andar = tecto do de baixo). O miolo
    escurece para baixo (como as massas de pedra do Dead Cells): so' a capa
    de cima e a aresta de baixo leem como pedra trabalhada, o resto recua."""
    plat(nome, esq, dir, topo, h=base - topo, av=0)
    if escurecer and base - topo > 180 and dir - esq >= 300:
        caixa_de_engrenagens(nome, esq, dir, topo + 80, topo + 165)
    if escurecer and base - topo > 90:
        y0, y1 = topo + 34, base - 10
        no(f"{nome}Massa", f"position = {v(esq, y0)}\ncentered = false\n"
                           f"scale = {v((dir - esq) / 64.0, (y1 - y0) / 64.0)}\n"
                           'texture = SubResource("tex_massa")\nz_index = 1', tipo="Sprite2D")


SUBS_EXTRA: list[str] = []


def casca(nome: str, esq: float, dir: float, topo: float, base: float) -> None:
    """Casca da torre (paredes de fora e telhado): corpo solido SEM ser
    `Plataforma` -- nao e' sitio onde se pise, e o crivo de alcance nao a
    deve contar como ilha. Visual: a cantaria do pack, escurecida."""
    rid = f"rs_{nome}"
    SUBS_EXTRA.append(f'[sub_resource type="RectangleShape2D" id="{rid}"]\n'
                      f"size = {v(dir - esq, base - topo)}\n")
    no(nome, f"position = {v((esq + dir) / 2, (topo + base) / 2)}", tipo="StaticBody2D")
    no("Col", f'shape = SubResource("{rid}")', tipo="CollisionShape2D", pai=nome)
    w, h = dir - esq, base - topo
    no("Visual", f"position = {v(-w / 2, -h / 2)}\ncentered = false\n"
                 f"texture = {tex('corpo_te')}\ntexture_repeat = 2\nregion_enabled = true\n"
                 f"region_rect = Rect2(0, 0, {w:g}, {h:g})\nmodulate = Color(0.4, 0.4, 0.58, 1)",
       tipo="Sprite2D", pai=nome)
    no("Massa", f"position = {v(-w / 2, -h / 2)}\ncentered = false\n"
                f"scale = {v(w / 64.0, h / 64.0)}\n"
                'texture = SubResource("tex_massa")', tipo="Sprite2D", pai=nome)


def caixa_de_engrenagens(nome: str, esq: float, dir: float, y0: float, y1: float) -> None:
    """Dentro das lajes grossas, uma faixa aberta onde se ve' a CAIXA DE
    ENGRENAGENS da torre a trabalhar (como os cortes das pranchas): recesso
    escuro, carris de metal dourado em cima e em baixo, engrenagens a rodar
    em sentidos alternados. So' visual; fica por cima do escurecimento."""
    x0, x1 = esq + 40, dir - 40
    mosaico(f"{nome}Caixa", "corpo_te", x0, y0, x1, y1, z=2, mod="Color(0.07, 0.07, 0.12, 1)")
    for k, (ya, yb) in enumerate([(y0 - 8, y0 + 2), (y1 - 2, y1 + 8)]):
        mosaico(f"{nome}Carril{k}", "m_tex_metal", x0 - 6, ya, x1 + 6, yb, esc=0.4, z=3,
                mod="Color(0.62, 0.5, 0.38, 1)")
    n = max(1, int((x1 - x0) // 170))
    passo = (x1 - x0) / n
    for i in range(n):
        x = x0 + passo * (i + 0.5)
        t = "m_engrenagem" if i % 2 == 0 else "m_roda"
        e = 0.46 if t == "m_engrenagem" else 0.5
        gira(f"{nome}Engr{i}", t, x, (y0 + y1) / 2, e, 0.5 if i % 2 == 0 else -0.5, z=2,
             mod="Color(0.5, 0.4, 0.3, 1)")


def quebra(nome: str, esq: float, dir: float, topo: float) -> None:
    PL[nome] = {"esq": esq, "dir": dir, "topo": topo}
    no(nome, f"position = {v((esq + dir) / 2, topo + 9)}\ntamanho = {v(dir - esq, 18)}\n"
             "pele_terreno = true", inst="quebra")


def espinhos(nome: str, esq: float, dir: float, chao: float) -> None:
    n = int((dir - esq) // 16)
    no(nome, f"position = {v((esq + dir) / 2, chao)}\nlargura = {n}", inst="espinhos")


def fosso(nome: str, esq: float, dir: float, topo: float, base: float,
          espinhar: bool = True) -> None:
    """Fosso entre duas lajes: fundo com espinhos + degrau de servico de cada
    lado (sair custa vida, nunca prende). `base` = face de baixo da laje (o
    fundo do fosso vai ate' la', para o tecto do andar de baixo nao ter
    degraus)."""
    fundo = topo + FUNDO_FOSSO
    laje(f"{nome}Fundo", esq, dir, fundo, base)
    meio = topo + FUNDO_FOSSO / 2.0
    plat(f"{nome}DegrauE", esq, esq + 70, meio, h=20, av=20)
    plat(f"{nome}DegrauD", dir - 70, dir, meio, h=20, av=20)
    if espinhar:
        espinhos(f"{nome}Espinhos", esq + 80, dir - 80, fundo)


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


def _tam_png(caminho: str) -> tuple:
    with open(caminho, "rb") as f:
        cab = f.read(24)
    return int.from_bytes(cab[16:20], "big"), int.from_bytes(cab[20:24], "big")


TAM_TEX = {t: _tam_png(os.path.join(RAIZ, "assets/sprites/pixel/deco/torres", f"{t}.png"))
           for t in TEXTURAS}
TAM_TEX["corpo_te"] = _tam_png(os.path.join(RAIZ, "assets/sprites/pixel/terreno/torre_ecos/corpo.png"))


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
              z: int = -2, mod: str = "", flip: bool = False) -> None:
    h = TAM_TEX[t][1] * esc
    c = (f"position = {v(x, topo_y + h / 2.0)}\nscale = {v(esc, esc)}\n"
         f"texture = {tex(t)}\nz_index = {z}")
    if flip:
        c += "\nflip_h = true"
    if mod:
        c += f"\nmodulate = {mod}"
    no(nome, c, tipo="Sprite2D")


def solto(nome: str, t: str, x: float, y: float, esc: float = 1.0, z: int = -2,
          mod: str = "", flip: bool = False) -> None:
    c = f"position = {v(x, y)}\nscale = {v(esc, esc)}\ntexture = {tex(t)}\nz_index = {z}"
    if flip:
        c += "\nflip_h = true"
    if mod:
        c += f"\nmodulate = {mod}"
    no(nome, c, tipo="Sprite2D")


def corrente(nome: str, x: float, y0: float, y1: float, z: int = -3,
             mod: str = "Color(0.95, 0.8, 0.5, 0.95)", grossa: bool = True) -> None:
    """Corrente dourada da prancha (`m_tex_correntes`) a pender de y0 a y1."""
    t = "m_tex_correntes" if grossa else "corrente_t"
    w = TAM_TEX[t][0]
    esc = 0.7 if grossa else 1.0
    c = (f"position = {v(x - w * esc / 2, y0)}\nscale = {v(esc, esc)}\ntexture_repeat = 2\n"
         f"texture = {tex(t)}\ncentered = false\n"
         f"region_enabled = true\nregion_rect = Rect2(0, 0, {w}, {(y1 - y0) / esc:g})\n"
         f"z_index = {z}\nmodulate = {mod}")
    no(nome, c, tipo="Sprite2D")


def luz(nome: str, x: float, y: float, energia: float, cor: str, esc: tuple) -> None:
    no(nome, f'position = {v(x, y)}\ntexture = SubResource("tex_luz")\n'
             f"energy = {energia:g}\ncolor = {cor}\nscale = {v(*esc)}", tipo="PointLight2D")


def mosaico(nome: str, t: str, x0: float, y0: float, x1: float, y1: float,
            esc: float = 1.0, z: int = -9, mod: str = "", add: bool = False) -> None:
    w, h = (x1 - x0) / esc, (y1 - y0) / esc
    c = (f"position = {v(x0, y0)}\nscale = {v(esc, esc)}\ncentered = false\n"
         f"texture = {tex(t)}\n"
         f"texture_repeat = 2\nregion_enabled = true\nregion_rect = Rect2(0, 0, {w:g}, {h:g})\n"
         f"z_index = {z}")
    if mod:
        c += f"\nmodulate = {mod}"
    if add:
        c += '\nmaterial = SubResource("mat_add")'
    no(nome, c, tipo="Sprite2D")


def fx(nome: str, t: str, x: float, y: float, esc: float = 1.0, z: int = 2,
       mod: str = "Color(1, 1, 1, 0.8)", rot: float = 0.0) -> None:
    c = (f"position = {v(x, y)}\nscale = {v(esc, esc)}\ntexture = {tex(t)}\n"
         f'z_index = {z}\nmodulate = {mod}\nmaterial = SubResource("mat_add")')
    if rot:
        c += f"\nrotation = {rot:g}"
    no(nome, c, tipo="Sprite2D")


def heras(nome: str, x: float, topo_y: float, esc: float = 0.8, flip: bool = False) -> None:
    pendurado(nome, "p_heras", x, topo_y - 6, esc=esc, z=1, mod="Color(0.78, 0.84, 1, 1)",
              flip=flip)


def gira(nome: str, t: str, x: float, y: float, esc: float, vel: float, z: int = -8,
         mod: str = "Color(0.42, 0.34, 0.3, 1)") -> None:
    """Engrenagem de fundo a rodar devagar (so' visual)."""
    no(nome, f"position = {v(x, y)}\nscale = {v(esc, esc)}\ntexture = {tex(t)}\n"
             f"z_index = {z}\nmodulate = {mod}\n"
             f'script = ExtResource("{ID["gira"]}")\nvelocidade = {vel:g}', tipo="Sprite2D")


def alavanca(nome: str, x: float, chao: float, ident: str, extra: str = "",
             so_liga: bool = True) -> None:
    c = (f"position = {v(x, chao - 16)}\nid = \"{ident}\"\nso_liga = {str(so_liga).lower()}\n"
         f"textura = {tex('m_alavanca')}\nescala_textura = 0.42")
    if extra:
        c += "\n" + extra
    no(nome, c, inst="alav")


def grade(nome: str, x: float, chao: float, tecto: float, ident: str, extra: str = "") -> None:
    """Porta de bronze da prancha do chao ao tecto (nao se salta por cima)."""
    h = chao - tecto
    c = (f"position = {v(x, chao - h / 2)}\nid = \"{ident}\"\ntamanho = {v(52, h)}\n"
         f"textura = {tex('m_tex_bronze')}\ntextura_moldura = {tex('m_tex_metal')}\n"
         "escala_textura = 0.5")
    if extra:
        c += "\n" + extra
    no(nome, c, inst="grade")
    # a maquina da porta: a roda que a iça, presa ao tecto, e as colunas de
    # cantaria que a emolduram (so' visual, por tras)
    gira(f"{nome}Roda", "m_engrenagem", x, tecto + 30, 0.36, 0.0, z=-3,
         mod="Color(0.85, 0.7, 0.55, 1)")
    for lado in (-1, 1):
        mosaico(f"{nome}Ombreira{'E' if lado < 0 else 'D'}", "p_parede",
                x + lado * 44 - 14, tecto, x + lado * 44 + 14, chao, esc=0.9, z=-4,
                mod="Color(0.5, 0.48, 0.66, 1)")


def elevador(nome: str, x: float, largura: float, base: float, topo: float, auto: bool,
             lado: float) -> None:
    extra = "auto = true\nvelocidade = 85.0" if auto else "velocidade = 110.0"
    no(nome, f'position = {v(x, base + 8)}\nscript = ExtResource("{ID["elevcol"]}")\n'
             f"curso = {v(0, topo - base)}\n{extra}\nlargura = {largura:g}\n"
             "altura_ancora = 150.0\n"
             f"textura_contrapeso = {tex('m_contrapeso')}\nescala_contrapeso = 0.55\n"
             f"lado_contrapeso = {lado:g}", inst="elev")


OURO = "Color(1.0, 0.74, 0.42, 1)"
LUA = "Color(0.55, 0.7, 1.0, 1)"
ROXO = "Color(0.72, 0.5, 1.0, 1)"
PAREDE = "Color(0.2, 0.21, 0.36, 1)"
PILAR = "Color(0.46, 0.46, 0.7, 1)"
METAL = "Color(0.36, 0.3, 0.3, 1)"       # casas das maquinas, bem recuadas
ENGR = "Color(0.62, 0.5, 0.4, 1)"        # engrenagens do fundo: ouro velho



def laje(nome: str, esq: float, dir: float, topo: float, base: float,
         escurecer: bool = True, maquina: bool = False) -> None:
    """Laje grossa de pedra. O miolo escurece para baixo (so' a capa e a
    aresta leem); `maquina` abre a faixa da caixa de engrenagens (so' onde
    o campanario tem maquinaria por baixo do chao)."""
    plat(nome, esq, dir, topo, h=base - topo, av=0)
    if maquina and base - topo > 180 and dir - esq >= 300:
        caixa_de_engrenagens(nome, esq, dir, topo + 80, topo + 165)
    if escurecer and base - topo > 90:
        y0, y1 = topo + 34, base - 10
        no(f"{nome}Massa", f"position = {v(esq, y0)}\ncentered = false\n"
                           f"scale = {v((dir - esq) / 64.0, (y1 - y0) / 64.0)}\n"
                           'texture = SubResource("tex_massa")\nz_index = 1', tipo="Sprite2D")


def sino_seq(nome: str, x: float, y: float, grupo: str, esc: float = 0.5) -> None:
    """Sino que se toca (golpe ou projetil): o "sino em sequencia" da
    prancha, pendurado da sua corrente, com o brilho por tras."""
    no(nome, f"position = {v(x, y)}\nalterna_grupo = \"{grupo}\"\n"
             f"textura = {tex('c_sino_sequencia')}\nscale = {v(esc, esc)}", inst="sino")
    fx(f"Brilho{nome}", "p_brilho_sino", x, y + 4, esc=0.9, z=-1,
       mod="Color(1, 0.82, 0.55, 0.5)")


def temporizada(nome: str, esq: float, dir: float, topo: float, grupo: str,
                dur: float) -> None:
    """Plataforma temporizada da prancha: fantasma ate' o sino do grupo a
    acender; fica solida `dur` segundos, pisca, e apaga-se."""
    plat(nome, esq, dir, topo, h=20, av=18, inst="eco",
         extra=f'grupo_alternar = "{grupo}"\nduracao_solida = {dur:g}\nalpha_fantasma = 0.2\n'
               f"textura_suporte = {tex('c_plat_temporizada')}\nescala_suporte = "
               f"{(dir - esq) / 120.0 * 0.62:.3f}")


def balanco(nome: str, x: float, topo_repouso: float, comprimento: float, amp: float,
            periodo: float, fase: float, largura: float = 180.0) -> None:
    """Baloico grande: `x`, `topo_repouso` = a laje no fundo do arco."""
    no(nome, f"position = {v(x, topo_repouso + 8)}\nscript = ExtResource(\"{ID['balanco']}\")\n"
             f"largura = {largura:g}\ncomprimento = {comprimento:g}\namplitude_graus = {amp:g}\n"
             f"periodo = {periodo:g}\nfase = {fase:g}\n"
             f"textura_corrente = {tex('m_tex_correntes')}", inst="elev")


def queda(nome: str, x: float, y: float, chao: float, esc: float = 0.5) -> None:
    """Sino em queda: pendurado por uma corrente curta, cai quando a
    Koliani passa por baixo."""
    no(nome, f"position = {v(x, y)}\nchao_y = {chao:g}\nraio_gatilho = 80.0\ndano = 22\n"
             f"aviso = 0.6\ntam = 28.0\ntextura = {tex('c_sino_queda')}\n"
             f"escala_textura = {esc:g}", inst="queda")


def cruz(nome: str, x: float, y: float, percurso: tuple, tempo: float, esc: float) -> None:
    """Laminas em cruz da prancha, a girar (e a correr o `percurso`)."""
    no(nome, f"position = {v(x, y)}\npercurso = {v(*percurso)}\ntempo = {tempo:g}\n"
             f"textura = {tex('c_laminas_cruz')}\nescala_textura = {esc:g}\ngiro_por_seg = 2.4",
       inst="serra")


def ar(nome: str, esq: float, dir: float, topo: float, base: float) -> None:
    no(nome, f"position = {v((esq + dir) / 2, (topo + base) / 2)}\n"
             f"tamanho = {v(dir - esq, base - topo)}\nforca = 3200.0\nvel_alvo = 520.0\n"
             f"pele = {tex('c_updraft')}\nvel_pele = 110.0", inst="ar")


def sino_balanca(nome: str, t: str, x: float, topo_y: float, esc: float, amp: float,
                 per: float, fase: float = 0.0, z: int = -8,
                 mod: str = "Color(0.75, 0.7, 0.72, 1)") -> None:
    """Sino de cenario pendurado a balancar devagar (so' visual): o no' fica
    no ponto de suspensao; o sprite pende dele."""
    h = TAM_TEX[t][1] * esc
    no(nome, f"position = {v(x, topo_y)}\nscale = {v(esc, esc)}\ntexture = {tex(t)}\n"
             f"centered = false\noffset = {v(-TAM_TEX[t][0] / 2, 0)}\nz_index = {z}\n"
             f"modulate = {mod}\nscript = ExtResource(\"{ID['gira']}\")\n"
             f"balanco_graus = {amp:g}\nperiodo_balanco = {per:g}\nfase_balanco = {fase:g}",
       tipo="Sprite2D")


def trave(nome: str, x0: float, x1: float, y: float, h: float = 22.0, z: int = -3,
          mod: str = "Color(0.62, 0.5, 0.42, 1)") -> None:
    """Trave de madeira do campanario com cintas de metal dourado."""
    mosaico(nome, "m_tex_madeira", x0, y, x1, y + h, esc=0.5, z=z, mod=mod)
    for k, (ya, yb) in enumerate([(y - 3, y + 2), (y + h - 2, y + h + 3)]):
        mosaico(f"{nome}Cinta{k}", "m_tex_metal", x0, ya, x1, yb, esc=0.3, z=z,
                mod="Color(0.8, 0.64, 0.44, 1)")


OURO = "Color(1.0, 0.74, 0.42, 1)"
LUA = "Color(0.55, 0.7, 1.0, 1)"
ROXO = "Color(0.72, 0.5, 1.0, 1)"
PAREDE = "Color(0.3, 0.31, 0.52, 1)"
PILAR = "Color(0.46, 0.46, 0.7, 1)"
FRENTE = "Color(0.07, 0.06, 0.1, 1)"
LONGE = "Color(0.2, 0.24, 0.42, 1)"      # silhuetas da torre ao longe (ar livre)

# ======================================================================
#  RAIZ + ATMOSFERA
# ======================================================================
no("Observatorio_Lunar",
   f'script = ExtResource("{ID["niv"]}")\ncorredor = false\n'
   "alongar_plataformas = false\ncheckpoints_autorais = true\n"
   'mecanica_anunciada = "vento"\nestreia_x_autoral = 2600.0',
   tipo="Node2D", pai="")
nos[0] = nos[0].replace(' parent=""', "")

# os valores sao os de `tools/afinar_atmosfera.py` (linha Observatorio_Lunar)
# -- correr esse tool depois deste nao muda nada
no("Atmosfera", """cor_ambiente = Color(0.92, 0.95, 1.06, 1)
cor_fundo = Color(0.05, 0.07, 0.17, 1)
cor_silhueta = Color(0.09, 0.12, 0.24, 1)
cor_luz = Color(0.96, 0.88, 0.66, 1)
cor_poeira = Color(1, 0.98, 0.88, 1)
densidade_poeira = 2.6
bioma = "torres"
largura_nivel = 3400.0
fundo_pack = "torre_ecos"
tinta_fundo = Color(0.86, 0.94, 1.24, 1)
neblina_fundo = 0.4
dessaturar_fundo = 0.16
seed_ambiente = 1481
luzes_horizonte = true""", inst="atm")

# ======================================================================
#  A CASCA -- paredes de fora, lajes, telhados
# ======================================================================
com("""
A CASCA: as paredes de fora a toda a altura (escalaveis -- os portoes ficam
longe delas), a laje da base (o telhado dela e' o terraco de onde se volta
a subir), a laje da camara dos sinos com o FURO da coluna de ar, e a coroa
do campanario por cima da sala do sino gigante.
""")
casca("ParedeOeste", -260, 0, TOPO_TORRE, 1300)
casca("ParedeLeste", LARG, LARG + 260, TOPO_TORRE, 1300)
casca("Coroa", 1640, LARG, TOPO_TORRE, TD)
# a face de fora da torre, onde se ve' do ar livre: cunhal de cantaria clara
# nas arestas e janelas acesas do campanario (so' visual)
for lado, x0, x1 in (("Oeste", -26, 14), ("Leste", LARG - 14, LARG + 26)):
    mosaico(f"Cunhal{lado}", "p_parede", x0, TOPO_TORRE, x1, RB, esc=0.9, z=1,
            mod="Color(0.5, 0.5, 0.74, 1)")
for i, y in enumerate([-560, -1000, -1640]):
    pendurado(f"JanelaFora{i}", "janela_gotica", LARG + 130, y, esc=2.0, z=1,
              mod="Color(0.85, 0.8, 1, 1)")
    fx(f"BrilhoJanelaFora{i}", "p_brilho_sino", LARG + 130, y + 76, esc=0.8, z=1,
       mod="Color(1, 0.7, 0.4, 0.35)")
assente("GargulaLeste", "gargula", LARG + 40, -1200, esc=1.6, z=2, flip=True)
# a parede entre a base e a camara dos sinos, por cima da passagem
casca("ParedeCamara", 2200, 2260, RB, TA)

# chao do rés-do-chao (base + camara), com o fosso do primeiro baloico
laje("ChaoA1", 0, 1250, YA, 1300)
laje("ChaoA2", 1750, LARG, YA, 1300)
# tecto da base = terraco (telhado) por cima dela
laje("TelhadoA", 0, 2200, RA, TA, maquina=True)
# tecto da camara = telhado da camara, com o furo da coluna de ar
laje("TelhadoB1", 2260, 2730, RB, TB)
laje("TelhadoB2", 2870, LARG, RB, TB)
# o terraco da base continua por cima da parede da camara ate' ao furo
plat("TelhadoBParede", 2200, 2260, RB, h=20, av=0)

# ======================================================================
#  INTERIOR -- a parede do fundo da base e da camara (so' visual)
# ======================================================================
com("""
INTERIOR (base e camara dos sinos): cantaria azul-noite, pilares, janelas
goticas com a lua a entrar, sinos de bronze pendurados a balancar devagar
nas traves do campanario. Chamas com brilho pintado (sem PointLight2D).
""")
mosaico("ParedeFundoA", "corpo_te", 0, TA, 2260, YA + FUNDO_FOSSO + 20, z=-12, mod=PAREDE)
mosaico("ParedeFundoB", "corpo_te", 2260, TB, LARG, YA + 20, z=-12, mod=PAREDE)
for i, x in enumerate([420, 900, 1250, 1750, 2200]):
    mosaico(f"PilarA{i}", "p_parede", x - 34, TA, x + 34, YA, esc=1.1, z=-9, mod=PILAR)
    pendurado(f"MisulaA{i}", "p_suporte", x, TA - 4, esc=1.05, z=-8, mod=PILAR)
    if x not in (1250, 1750):
        assente(f"TochaA{i}", "tocha", x, TA + 170, esc=1.1, z=-7)
        fx(f"BrilhoTochaA{i}", "p_brilho_sino", x, TA + 120, esc=0.9, z=-7,
           mod="Color(1, 0.62, 0.3, 0.45)")
for i, x in enumerate([2830, LARG - 34]):
    mosaico(f"PilarB{i}", "p_parede", x - 34, TB, x + 34, YA, esc=1.1, z=-9, mod=PILAR)
no("SombraTectoA", f"position = {v(0, TA)}\ncentered = false\n"
                   f"scale = {v(2260 / 64.0, 200 / 64.0)}\n"
                   'texture = SubResource("tex_sombra")\nz_index = -8', tipo="Sprite2D")
no("SombraTectoB", f"position = {v(2260, TB)}\ncentered = false\n"
                   f"scale = {v((LARG - 2260) / 64.0, 260 / 64.0)}\n"
                   'texture = SubResource("tex_sombra")\nz_index = -8', tipo="Sprite2D")
mosaico("FrisoTectoA", "m_tex_metal", 0, TA, 2260, TA + 14, esc=0.5, z=-7,
        mod="Color(0.7, 0.56, 0.42, 1)")
mosaico("FrisoTectoB", "m_tex_metal", 2260, TB, LARG, TB + 14, esc=0.5, z=-7,
        mod="Color(0.7, 0.56, 0.42, 1)")
# janelas goticas da base, com a lua a entrar
for i, x in enumerate([660, 1500, 1980]):
    t = "p_vitral_dourado" if i % 2 == 0 else "p_parede_vitral"
    esc = 250.0 / TAM_TEX[t][1]
    pendurado(f"JanelaA{i}", t, x, TA + 60, esc=esc, z=-10, mod="Color(0.72, 0.8, 1, 0.95)")
    assente(f"ArcoJanelaA{i}", "arco_grande", x, TA + 60 + 250 + 26, esc=1.75, z=-11,
            mod="Color(0.42, 0.44, 0.7, 1)")
    fx(f"RaiosJanelaA{i}", "p_raios_luz", x + 40, TA + 330, esc=1.4, z=-9,
       mod="Color(0.62, 0.74, 1, 0.3)")

# ======================================================================
#  A) A BASE DO CAMPANARIO
# ======================================================================
com("""
===================  A) CHEGADA AO CAMPANARIO  ===============================
A base da torre: por cima, os sinos da torre pendurados das traves. Dois
SINOS EM QUEDA no corredor (tremem e caem quando se passa por baixo), um
Monge das Correntes, e o PRIMEIRO BALOICO sobre um fosso de 500 px (fora do
salto duplo): a laje grande a baloicar em duas correntes ensina a mecanica
com seguranca -- cair custa vida, nunca prende.
""")
no("Koliani", f"position = {v(150, YA - 40)}\nusar_prototipo_premium = true\n"
              "usar_golden_set = true", inst="kol")
check("CheckInicio", 300, YA)
# a trave dos sinos da base, com tres sinos de bronze a balancar
trave("TraveSinosA", 120, 1180, TA + 40)
for nome, t, x, e, a, p, f in [("SinoBaseA1", "sino_g", 260, 1.0, 5.0, 4.6, 0.0),
                               ("SinoBaseA2", "sino_m", 560, 1.1, 6.0, 3.9, 0.3)]:
    corrente(f"Corrente{nome}", x, TA + 62, TA + 120, z=-9, mod="Color(0.7, 0.56, 0.36, 0.9)")
    sino_balanca(nome, t, x, TA + 118, e, a, p, f)
# o sino gigante da prancha, com a trave e os contrapesos, ao fundo da base
assente("SinoGiganteFundoA", "c_sino_gigante", 1500, YA - 40, esc=1.25, z=-11,
        mod="Color(0.45, 0.42, 0.55, 1)")
luz("LuzInicio", 330, YA - 80, 0.55, OURO, (2.2, 1.4))
assente("CandelabroA", "candelabro", 480, YA, esc=1.2, z=-1)
assente("VelasA", "velas", 110, YA, esc=1.3, z=-1)

queda("SinoQuedaA1", 760, TA + 70, YA)
queda("SinoQuedaA2", 1060, TA + 70, YA)
for nome, x in [("CorrenteQuedaA1", 760), ("CorrenteQuedaA2", 1060)]:
    corrente(nome, x, TA + 14, TA + 44, z=-2)
inimigo("MongeA1", 980, YA - 50, "monge_das_correntes", "escudeiro", 90, 18, 140,
        "Color(1.0, 0.78, 0.45, 1)", escala=1.15)
inimigo("SinoFlutuanteA", 620, YA - 260, "sino_flutuante", "voador", 50, 14, 160,
        "Color(1.0, 0.82, 0.5, 1)")

com("""
O PRIMEIRO BALOICO: a laje pende de uma trave colada ao tecto; nos extremos
fica a 16 px da borda do fosso e 110 px acima do chao (sobe-se de um salto).
SEGREDO 1 por cima do meio do fosso: so' do baloico (ou de um salto duplo
bem medido da borda).
""")
fosso("FossoA", 1250, 1750, YA, 1300)
trave("TraveBalancoA", 1360, 1640, TA + 20)
balanco("BalancoA", 1500, 915, 412, 20, 4.2, 0.0)
plat("Segredo1", 1450, 1550, 780, h=22)
ess("EssenciaSegredo1", 1500, 780, 20)
assente("UrnaSegredo1", "urna", 1535, 780, esc=1.0, z=-1)
luz("LuzSegredo1", 1500, 750, 0.35, ROXO, (0.9, 0.8))
check("CheckA", 1850, YA)
inimigo("MongeA2", 2050, YA - 50, "monge_das_correntes", "escudeiro", 90, 18, 110,
        "Color(1.0, 0.78, 0.45, 1)", escala=1.15)
luz("LuzFossoA", 1500, 900, 0.4, OURO, (2.6, 1.6))
assente("CandelabroA2", "candelabro", 2140, YA, esc=1.2, z=-1)

# ======================================================================
#  B) A CAMARA DOS SINOS
# ======================================================================
com("""
===================  B) SINOS EM SEQUENCIA  ==================================
A camara dos sinos (1140 x 850 px). A saida e' o FURO no tecto, com uma
COLUNA DE AR a sair por ele -- a 480 px de cada parede e 670 px acima do
chao: nem de um salto, nem a escalar. Tres sinos EM SEQUENCIA: cada badalada
acende o seu lance de PLATAFORMAS TEMPORIZADAS (6-7 s, piscam antes de se
apagarem):
  sino 1 (no chao)       -> 4 degraus ate' ao patamar leste;
  sino 2 (patamar leste) -> 1 degrau ate' ao patamar alto;
  sino 3 (patamar alto)  -> 2 degraus ate' a' coluna de ar.
Os patamares ficam na parede leste (escalavel: nao sao portoes); o portao e'
o ultimo lance -- do patamar alto a' coluna sao 380 px e 130 de subida.
""")
check("CheckB", 2340, YA)
sino_seq("Sino1", 2400, YA - 110, "seq1")
for nome, e, d, t in [("Seq1a", 2460, 2580, 920), ("Seq1b", 2660, 2780, 850),
                      ("Seq1c", 2860, 2980, 780), ("Seq1d", 3060, 3180, 710)]:
    temporizada(nome, e, d, t, "seq1", 7.0)
plat("PatamarB1", 3240, LARG, 640, h=26)
sino_seq("Sino2", 3300, 575, "seq2")
temporizada("Seq2a", 3080, 3200, 550, "seq2", 6.0)
plat("PatamarB2", 3240, LARG, 460, h=26)
sino_seq("Sino3", 3330, 395, "seq3")
temporizada("Seq3a", 3040, 3140, 420, "seq3", 6.0)
temporizada("Seq3b", 2880, 2980, 380, "seq3", 6.0)
com("""A COLUNA DE AR pelo furo do tecto: leva ao telhado da camara (ar livre).""")
ar("ArCamara", 2740, 2860, -330, 330)
fx("RaiosFuro", "p_raios_luz", 2800, 240, esc=1.3, z=-6, mod="Color(0.7, 0.8, 1, 0.45)")
luz("LuzFuro", 2800, 200, 0.6, LUA, (1.6, 2.4))
inimigo("SinoFlutuanteB", 2700, 760, "sino_flutuante", "voador", 50, 14, 220,
        "Color(1.0, 0.82, 0.5, 1)")
# a camara por dentro: rosacea alta, vitrais, traves com sinos a balancar
solto("RosaceaB", "p_rosacea", 2560, 360, esc=1.2, z=-10, mod="Color(0.8, 0.85, 1, 0.95)")
fx("BrilhoRosaceaB", "p_brilho_sino", 2560, 360, esc=2.2, z=-10, mod="Color(0.6, 0.7, 1, 0.3)")
for i, x in enumerate([3080, 3280]):
    pendurado(f"VitralB{i}", "vitral_alto", x, 200, esc=2.0, z=-10,
              mod="Color(0.8, 0.86, 1, 0.9)")
trave("TraveSinosB", 2280, 2700, 560, z=-9, mod="Color(0.45, 0.38, 0.34, 1)")
for nome, t, x, e, a, p, f in [("SinoCamara1", "sino_g", 2360, 0.9, 4.0, 5.2, 0.1),
                               ("SinoCamara2", "sino_m", 2620, 1.0, 5.0, 4.4, 0.6)]:
    corrente(f"Corrente{nome}", x, 582, 610, z=-10, mod="Color(0.6, 0.5, 0.34, 0.9)")
    sino_balanca(nome, t, x, 606, e, a, p, f, z=-10, mod="Color(0.55, 0.52, 0.6, 1)")
luz("LuzCamara", 2400, YA - 120, 0.5, OURO, (2.2, 1.5))
luz("LuzPatamares", 3300, 520, 0.45, OURO, (1.8, 2.0))
assente("VelasB", "velas", 2300, YA, esc=1.2, z=-1)
assente("CandelabroB", "candelabro", 3330, YA, esc=1.2, z=-1)
heras("HerasPatamar", 3260, 640 + 26, esc=0.6)

# ======================================================================
#  C) AR LIVRE -- por cima dos telhados
# ======================================================================
com("""
===================  C) PLATAFORMAS DINAMICAS E VENTO  =======================
O ar livre por cima dos telhados: o panorama da torre ao fundo, e nada onde
trepar. Cair aqui e' voltar ao terraco da base (a parede da camara sobe-se a
escalar ate' ao telhado dela) -- custa o caminho, nunca prende.
  C1 -- COLUNA DE AR (updraft) do telhado a' primeira laje pendurada;
  C2 -- dois BALOICOS GRANDES em fases opostas, contra o VENTO que empurra
        para tras, e LAMINAS EM CRUZ a subir e descer entre eles;
  C3 -- a RODA de plataformas circulares (laminas em cruz no cubo) leva de
        baixo para cima; SEGREDO 2 fora da roda, a oeste;
  C4 -- a CORRENTE QUE MUDA DE DIRECAO: o elevador so' anda ao som do sino.
""")
check("CheckC", 3100, RB)
# balaustradas e gargulas nos telhados
for i, x in enumerate(range(60, 2200, 124)):
    assente(f"BalaustradaA{i}", "balaustrada", x, RA, esc=1.0, z=-3,
            mod="Color(0.62, 0.64, 0.86, 1)")
for i, x in enumerate([2300, 2420, 2540, 2660, 2940, 3060, 3180, 3300]):
    assente(f"BalaustradaB{i}", "balaustrada", x, RB, esc=1.0, z=-3,
            mod="Color(0.62, 0.64, 0.86, 1)")
for nome, x, y, f in [("GargulaA1", 40, RA, False), ("GargulaA2", 2150, RA, True),
                      ("GargulaB1", 2230, RB, False), ("GargulaB2", 3370, RB, True)]:
    assente(nome, "gargula", x, y, esc=1.5, z=-2, flip=f)
for nome, x, y in [("FlamulaA", 1100, RA - 200), ("FlamulaB", 3200, RB - 210)]:
    corrente(f"Mastro{nome}", x - 20, y - 20, y + 190, z=-4, mod="Color(0.5, 0.42, 0.34, 1)")
    solto(nome, "flamula", x, y + 60, esc=1.4, z=-4)
# a torre ao longe: agulhas e torres laterais em silhueta azul (profundidade)
for i, (x, y, e, t) in enumerate([(300, 160, 3.2, "p_torre_lateral"),
                                  (820, 60, 2.6, "p_estrutura_vertical"),
                                  (1300, 120, 3.6, "p_torre_lateral"),
                                  (2000, 60, 2.8, "p_estrutura_vertical"),
                                  (2600, -200, 3.0, "p_torre_lateral"),
                                  (3150, -260, 2.6, "p_estrutura_vertical")]):
    assente(f"AgulhaLonge{i}", t, x, y, esc=e, z=-13, mod=LONGE)

ar("ArC1", 2310, 2430, -600, RB)
plat("LajeC1", 2120, 2300, -560, h=30)
# a laje pende da estrutura do campanario por cima (o chao da sala D)
corrente("CorrenteLajeC1a", 2140, YD + 60, -560, z=-3)
corrente("CorrenteLajeC1b", 2280, YD + 60, -560, z=-3)

com("""C2 -- os baloicos grandes (a trave pende do chao da sala do sino
gigante e de uma agulha da torre).""")
trave("TraveBaloicos", 1300, 2020, -892, h=24)
corrente("CorrenteTrave1", 1990, YD + 60, -892, z=-4)
mosaico("AgulhaTrave", "p_parede", 1276, -1260, 1316, -868, esc=0.9, z=-5,
        mod="Color(0.4, 0.4, 0.6, 1)")
pendurado("RemateAgulha", "p_suporte", 1296, -1284, esc=1.0, z=-5, mod=PILAR)
balanco("BalancoC1", 1880, -588, 292, 26, 4.4, 0.0)
balanco("BalancoC2", 1420, -588, 292, 26, 4.4, 0.5)
no("VentoC2", f"position = {v(1640, -690)}\nscript = ExtResource(\"{ID['vento']}\")\n"
              f"tamanho = {v(940, 260)}\nempurrao = 700.0\nvel_max = 200.0\n"
              f"pele = {tex('c_vento')}\nvel_pele = 180.0\nalfa_pele = 0.24", tipo="Area2D")
cruz("CruzC2", 1650, -900, (0, 190), 1.8, 0.5)
inimigo("CorvoC2", 1700, -820, "corvo_do_sino", "voador", 45, 14, 260,
        "Color(0.8, 0.7, 1.0, 1)")
plat("LajeC2", 960, 1180, -560, h=30)
corrente("CorrenteLajeC2a", 990, -1280, -560, z=-4)
corrente("CorrenteLajeC2b", 1150, -1280, -560, z=-4)
check("CheckC2", 1070, -560)
queda("SinoQuedaC2", 1120, -780, -560)
corrente("CorrenteQuedaC2", 1120, -1280, -800, z=-4)

com("""C3 -- A RODA: tres plataformas circulares a girar a' volta de um cubo
com LAMINAS EM CRUZ. Sobe-se no ponto de baixo (a 112 px da laje C2) e a
roda leva para a direita e para cima; do ponto de cima salta-se para a laje
C3. SEGREDO 2 por cima, a oeste do ponto de cima.""")
CUBO = (935.0, -854.0)
# a roda gigante por tras das plataformas: aro no raio delas, a rodar com
# elas (uma volta em 10 s, anti-horario)
gira("RodaFundoC3", "m_roda", CUBO[0], CUBO[1], 2.15, -0.6283, z=-6, mod="Color(0.62, 0.5, 0.4, 0.8)")
for i in range(3):
    no(f"RodaC3_{i}", f"position = {v(*CUBO)}\nscript = ExtResource(\"{ID['orbita']}\")\n"
                      f"largura = 130.0\nraio = 190.0\nperiodo = 10.0\nfase = {i / 3.0:.4f}\n"
                      f"sentido = -1.0\ntextura_disco = {tex('c_plat_circular')}\n"
                      f"escala_disco = 0.7\ntextura_corrente = {tex('m_tex_correntes')}",
       inst="elev")
cruz("CruzCubo", CUBO[0], CUBO[1], (0, 0), 1.0, 0.55)
corrente("CorrenteCubo", CUBO[0], -1280, CUBO[1] - 40, z=-7)
inimigo("CorvoC3", 700, -1000, "corvo_do_sino", "voador", 45, 14, 200,
        "Color(0.8, 0.7, 1.0, 1)")
plat("Segredo2", 650, 760, -1150, h=22)
ess("EssenciaSegredo2", 705, -1150, 25)
corrente("CorrenteSegredo2", 705, -1280, -1150, z=-4)
luz("LuzSegredo2", 705, -1180, 0.35, ROXO, (0.9, 0.8))

com("""C4 -- A CORRENTE QUE MUDA DE DIRECAO: a laje C3 acaba num elevador de
corrente que nao sobe com peso -- anda ao som do SINO (um em baixo, outro la'
em cima no chao da sala D). Do cimo passa-se para a sala do sino gigante.
A laje C3 fica 320 px abaixo do chao fino da sala D: nem o salto nem a face
chegam la'.""")
plat("LajeC3", 1205, 1430, -920, h=30)
corrente("CorrenteLajeC3a", 1230, -1280, -920, z=-4)
corrente("CorrenteLajeC3b", 1400, -1280, -920, z=-4)
queda("SinoQuedaC3", 1320, -1130, -920)
no("CorrenteD", f"position = {v(1540, -912)}\nscript = ExtResource(\"{ID['elevcol']}\")\n"
                f"curso = {v(0, -380)}\nvelocidade = 120.0\nlargura = 180.0\n"
                f"altura_ancora = 140.0\ngrupo_sino = \"corrente_d\"", inst="elev")
sino_seq("SinoCorrente1", 1500, -990, "corrente_d", esc=0.42)
sino_seq("SinoCorrente2", 1665, YD - 70, "corrente_d", esc=0.42)
solto("CorrenteMudaPintada", "c_corrente_muda", 1540, -1060, esc=0.9, z=-8,
      mod="Color(0.5, 0.46, 0.6, 1)")
luz("LuzCorrente", 1540, -1000, 0.45, OURO, (1.6, 1.6))

# ======================================================================
#  D) A SALA DO SINO GIGANTE
# ======================================================================
com("""
===================  D) SALA DO SINO GIGANTE  (elemento chave)  ==============
O cimo do campanario: chao FINO (60 px, preso a' parede leste -- quem sobe a
parede leste pelo lado de fora fica debaixo dele), arcos abertos para o ceu,
e ao centro o SINO GIGANTE a baloicar da coroa. A boca do sino passa a 130 px
da cabeca da Koliani: so' magoa quem salta na hora errada -- e e' ai' que o
GUARDIAO (Monge das Correntes elite) a obriga a lutar. SEGREDO 3 na varanda
do arco oeste.
""")
plat("ChaoD", 1640, LARG, YD, h=60, av=60)
check("CheckD", 1780, YD)
# por baixo do chao fino: as vigas do campanario e sinos pendurados
trave("VigaChaoD", 1640, LARG, YD + 60, h=26, z=-2, mod="Color(0.4, 0.34, 0.3, 1)")
for i, x in enumerate([1900, 2600, 3200]):
    corrente(f"CorrenteSinoBaixo{i}", x, YD + 86, YD + 170, z=-3)
    sino_balanca(f"SinoBaixoD{i}", "sino_m", x, YD + 166, 0.9, 4.0, 4.0 + i * 0.5, i * 0.3,
                 z=-3, mod="Color(0.7, 0.66, 0.7, 1)")
# a parede do fundo: pilares e arcos abertos para o ceu (o panorama ve-se)
for i, x in enumerate([1700, 2200, 2800, 3340]):
    mosaico(f"PilarD{i}", "p_parede", x - 34, TD, x + 34, YD, esc=1.1, z=-9, mod=PILAR)
for i, x in enumerate([1950, 2500, 3070]):
    assente(f"ArcoD{i}", "arco_grande", x, YD, esc=3.1, z=-10, mod="Color(0.5, 0.52, 0.78, 1)")
    fx(f"LuarArcoD{i}", "p_raios_luz", x + 30, YD - 250, esc=1.8, z=-9,
       mod="Color(0.62, 0.74, 1, 0.25)")
mosaico("FrisoCoroa", "m_tex_metal", 1640, TD, LARG, TD + 16, esc=0.5, z=-7,
        mod="Color(0.8, 0.64, 0.46, 1)")
no("SombraCoroa", f"position = {v(1640, TD)}\ncentered = false\n"
                  f"scale = {v((LARG - 1640) / 64.0, 220 / 64.0)}\n"
                  'texture = SubResource("tex_sombra")\nz_index = -8', tipo="Sprite2D")
# o SINO GIGANTE: trave dourada da coroa e o sino a baloicar (magoa)
trave("TraveSinoGigante", 2200, 2800, TD + 20, h=30, z=-4)
no("SinoGigante", f"position = {v(2500, TD + 36)}\ncomprimento = 370.0\namplitude_graus = 26.0\n"
                  f"periodo = 4.8\ndano = 26\ntextura_haste = {tex('m_tex_correntes')}\n"
                  f"textura_lamina = {tex('c_sino_sequencia')}\nescala_lamina = 1.5\n"
                  f"area_lamina = {v(160, 150)}", inst="pend")
# os sinos gigantes da prancha (com trave e contrapesos) ao fundo, a' volta
assente("SinoGiganteFundoD1", "c_sino_gigante", 1960, YD, esc=1.5, z=-11,
        mod="Color(0.5, 0.46, 0.6, 1)")
assente("SinoGiganteFundoD2", "c_sino_gigante", 3080, YD, esc=1.5, z=-11,
        mod="Color(0.5, 0.46, 0.6, 1)")
luz("LuzSinoGigante", 2500, YD - 260, 0.7, OURO, (3.2, 2.2))
luz("LuzArenaD", 2900, YD - 80, 0.55, OURO, (2.6, 1.5))
inimigo("Guardiao", 2900, YD - 80, "monge_das_correntes", "escudeiro", 300, 24, 220,
        "Color(1.0, 0.78, 0.45, 1)", elite=True, escala=1.6)
inimigo("CorvoD", 2300, YD - 260, "corvo_do_sino", "voador", 45, 14, 240,
        "Color(0.8, 0.7, 1.0, 1)")
plat("VarandaArco", 1700, 1780, YD - 110, h=20)
plat("Segredo3", 1820, 1920, YD - 220, h=22)
ess("EssenciaSegredo3", 1870, YD - 220, 30)
assente("MemorialSegredo3", "pedra_memoria", 1905, YD - 220, esc=1.1, z=-1)
luz("LuzSegredo3", 1870, YD - 250, 0.35, ROXO, (0.9, 0.8))
for nome, x in [("VelasD1", 2080), ("VelasD2", 3200)]:
    assente(nome, "velas", x, YD, esc=1.3, z=-1)
assente("CandelabroD", "candelabro", 2700, YD, esc=1.3, z=-1)
assente("EstatuaD", "estatua_anjo", 3330, YD, esc=1.6, z=-3, flip=True)
no("Porta", f'position = {v(3250, YD + 6)}\npista_ao_atravessar = ""', inst="porta")

# ======================================================================
#  VIDA -- neblina, poeira, heras (so' visual) e primeiro plano
# ======================================================================
for nome, x, y, e in [("NeblinaFossoA", 1500, YA + 120, 2.6), ("NeblinaTelhadoA", 800, RA - 20, 3.4),
                      ("NeblinaTelhadoB", 2900, RB - 20, 3.0), ("NeblinaC2", 1600, -450, 3.6),
                      ("NeblinaC3", 900, -700, 3.0), ("NeblinaD", 2500, YD + 20, 3.2)]:
    # banco de neblina: o degrade radial esticado (o recorte `p_neblina` da
    # prancha tem a aresta de baixo dura e via-se o rectangulo no ar livre)
    no(nome, f"position = {v(x, y)}\nscale = {v(e * 0.36, e * 0.12)}\n"
             'texture = SubResource("tex_luz")\nz_index = 1\n'
             'modulate = Color(0.55, 0.6, 0.9, 0.22)\nmaterial = SubResource("mat_add")',
       tipo="Sprite2D")
for nome, t, x, y, e in [("DetritosA", "p_detritos", 40, YA, 0.55),
                         ("PoeiraA", "p_poeira_chao", 900, YA, 0.55),
                         ("PoeiraB", "p_poeira_chao", 2600, YA, 0.55),
                         ("DetritosD", "p_detritos", 3360, YD, 0.5)]:
    assente(nome, t, x, y, esc=e, z=0, mod="Color(0.8, 0.8, 0.95, 1)")
for nome, t, x, y, e in [("LivrosA", "livros", 1900, YA, 1.2), ("UrnaA", "urna", 30, YA, 1.2),
                         ("LanternaB", "lanterna_eco", 3000, YA, 1.4),
                         ("UrnaB", "urna", 3370, YA, 1.1),
                         ("LanternaTelhado", "lanterna_eco", 3300, RB, 1.3),
                         ("LanternaD", "lanterna_eco", 1760, YD, 1.3)]:
    assente(nome, t, x, y, esc=e, z=-1)
com("""
Primeiro plano: correntes em silhueta, quase pretas, a' frente da Koliani
(z alto), so' onde nao ha' nada para ler.
""")
for nome, x, y0, y1 in [("FrenteCorrenteA", 200, TA, YA - 120), ("FrenteCorrenteB", 2250, TA, YA - 160),
                        ("FrenteCorrenteC", 3380, TB, 480), ("FrenteCorrenteD", 560, -1500, -300),
                        ("FrenteCorrenteE", 3380, TD, YD - 120)]:
    corrente(nome, x, y0, y1, z=6, mod=FRENTE)
    corrente(nome + "b", x + 26, y0, y1 - 70, z=6, mod=FRENTE)
mosaico("FrentePilarA", "p_parede", 1180, TA, 1230, YA + 40, esc=1.3, z=6, mod=FRENTE)

# ---------------------------------------------------------------- escrever
corpo_nos = "\n".join(nos)
linhas_ext = [l for l in linhas_ext if 'ExtResource("%s")' % l.split(' id="')[1][:-2] in corpo_nos]
cab = f'[gd_scene load_steps={len(linhas_ext) + 11 + len(SUBS_EXTRA)} format=3 uid="uid://bkolianiobservatorio14"]'
topo = """
; REGIAO III / nivel 14 -- CAMPANARIO (`level.n13`), "O Peso dos Ecos".
; O nome do ficheiro fica: muda-lo partia saves e checkpoints.
;
; GERADO por `tools/construir_n14_campanario.py` -- editar la', nao aqui.
; Desenho, medicoes e o que ficou por decidir: `docs/nivel_autoral_n14.md`.
;
; Nivel AUTORAL (`corredor = false`): a jornada procedural, as bolsas de
; gravidade lunar e a Sacerdotisa Lunar (chefe fora do contrato LOCKED)
; sairam. A subida ao campanario (A-D do contrato):
;   A) Chegada        -- sinos em queda, o primeiro baloico sobre um fosso;
;   B) Sinos em seq.  -- 3 sinos acendem plataformas temporizadas ate' a'
;                        coluna de ar que sai pelo furo do tecto;
;   C) Ar livre       -- coluna de ar, baloicos grandes contra o vento,
;                        laminas em cruz, a roda de plataformas circulares,
;                        a corrente que muda de direcao ao som do sino;
;   D) Sino gigante   -- o sino enorme a baloicar sobre o GUARDIAO (Monge
;                        das Correntes elite).
; 3 segredos, 7 checkpoints; inimigos: Monge das Correntes, Sino Flutuante,
; Corvo do Sino.
"""
subs = "\n".join(SUBS_EXTRA) + """
[sub_resource type="RectangleShape2D" id="rs_chk"]
size = Vector2(44, 96)

[sub_resource type="CanvasItemMaterial" id="mat_add"]
blend_mode = 1

[sub_resource type="Gradient" id="grad_massa"]
offsets = PackedFloat32Array(0, 0.35, 1)
colors = PackedColorArray(0.02, 0.02, 0.05, 0.15, 0.02, 0.02, 0.05, 0.5, 0.01, 0.01, 0.03, 0.68)

[sub_resource type="GradientTexture2D" id="tex_massa"]
gradient = SubResource("grad_massa")
width = 64
height = 64
fill_from = Vector2(0, 0)
fill_to = Vector2(0, 1)

[sub_resource type="Gradient" id="grad_massa_cima"]
offsets = PackedFloat32Array(0, 0.7, 1)
colors = PackedColorArray(0.01, 0.01, 0.03, 0.92, 0.02, 0.02, 0.05, 0.75, 0.02, 0.02, 0.05, 0.2)

[sub_resource type="GradientTexture2D" id="tex_massa_cima"]
gradient = SubResource("grad_massa_cima")
width = 64
height = 64
fill_from = Vector2(0, 0)
fill_to = Vector2(0, 1)

[sub_resource type="Gradient" id="grad_sombra"]
offsets = PackedFloat32Array(0, 1)
colors = PackedColorArray(0.01, 0.01, 0.04, 0.7, 0.01, 0.01, 0.04, 0)

[sub_resource type="GradientTexture2D" id="tex_sombra"]
gradient = SubResource("grad_sombra")
width = 64
height = 64
fill_from = Vector2(0, 0)
fill_to = Vector2(0, 1)

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
