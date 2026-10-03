#!/usr/bin/env python3
"""Gera `scenes/levels/Torre_da_Tempestade.tscn` -- N13 "Mecanismos Antigos".

Mesma ideia do `tools/construir_n12_galerias.py`: a cena e' AUTORAL, mas as
coordenadas dependem umas das outras (o topo de uma laje, o curso de um
elevador, o furo no tecto por onde ele passa), por isso escreve-se aqui, por
TOPO e bordas, e o `.tscn` sai gerado.

EDITAR AQUI e voltar a correr; nao editar o `.tscn` a mao:
    python tools/construir_n13_mecanismos.py

Contrato: docs/art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md
(N13 -- LOCKED). Desenho e medicoes: docs/nivel_autoral_n13.md.

A torre por dentro, em TRES ANDARES de maquinaria empilhados (como o mapa do
N13 no `layout_usage.png`): o andar de baixo corre para a direita, o do meio
volta para a esquerda, o de cima corre outra vez para a direita ate' ao
nucleo. Cada andar e' separado do seguinte por uma laje GROSSA (250 px) --
so' se sobe pelos elevadores de contrapeso, depois de cada porta.

Mobilidade que a Koliani ja' tem no N13 (e que o desenho tem de respeitar):
salto duplo (~246 px de altura, ~350 de alcance), dash e ESCALAR PAREDES
(recompensa do N10). Por isso:
  * nenhum tecto fica ao alcance de uma superficie por baixo de um furo;
  * as travessias "so' com mecanismo" tem vaos de 400+ px OU tecto baixo
    (110 px de folga: nao ha' arco de salto);
  * cada fosso tem espinhos no fundo e degraus de servico dos dois lados --
    cair custa vida, nunca prende o jogador.
"""
from __future__ import annotations

import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "scenes", "levels", "Torre_da_Tempestade.tscn")

# Paleta LOCKED da regiao (as cores de `Plataforma` sao ignoradas pelo visual
# pixel-art, mas ficam coerentes).
PEDRA = "cor_base = Color(0.24, 0.2, 0.26, 1)\ncor_topo = Color(0.5, 0.44, 0.54, 1)"

# ---------------------------------------------------------------- andares
# Y do CHAO de cada andar e do TECTO (face de baixo da laje de cima).
Y1, T1 = 950.0, 510.0        # andar de baixo  (A e B)
Y2, T2 = 260.0, -180.0       # andar do meio   (C)
Y3, T3 = -430.0, -870.0      # andar de cima   (D, nucleo)
TOPO_TORRE = -1100.0
LARG = 3600.0
FUNDO_FOSSO = 180.0          # profundidade dos fossos (espinhos no fundo)

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
    ("PackedScene", "uid://bkolianiplataquebra01", "res://scenes/actors/PlataformaQuebra.tscn", "quebra"),
    ("PackedScene", "uid://bkolianiessencia01", "res://scenes/actors/Essencia.tscn", "ess"),
    ("PackedScene", "uid://bkolianitumuloelev16", "res://scenes/actors/TumuloElevador.tscn", "elev"),
    ("Script", None, "res://scripts/elevador_coluna.gd", "elevcol"),
    ("PackedScene", "uid://bkolianiserra01", "res://scenes/actors/Serra.tscn", "serra"),
    ("PackedScene", "uid://bkolianiespinhos01", "res://scenes/actors/Espinhos.tscn", "espinhos"),
    ("PackedScene", "uid://bkolianialavanca01", "res://scenes/actors/Alavanca.tscn", "alav"),
    ("PackedScene", "uid://bkolianiportatrancada01", "res://scenes/actors/PortaTrancada.tscn", "grade"),
    ("PackedScene", "uid://bkolianiplatcorrente06", "res://scenes/actors/PlataformaCorrente.tscn", "pcorr"),
    ("Script", None, "res://scripts/plataforma_roda.gd", "roda"),
    ("Script", None, "res://scripts/mecanismo_sinos.gd", "mecsin"),
    ("Script", None, "res://scripts/engrenagem_deco.gd", "gira"),
    ("Script", None, "res://scripts/arena_selada.gd", "arena"),
]
# texturas da prancha aprovada (`tools/gerar_props_prancha.py`,
# `tools/gerar_props_n12_prancha.py`, `tools/gerar_props_n13_prancha.py`)
TEXTURAS = [
    "vitral_alto", "sino_m", "sino_g", "coluna_igreja", "coluna_dupla",
    "arco_grande", "corrente_t", "lanterna_eco", "candelabro", "estatua_anjo",
    "pedra_memoria", "relogio_antigo", "tocha", "lampiao_t", "urna", "livros",
    "p_parede", "p_parede_vitral", "p_vitral_dourado", "p_rosacea",
    "p_vitral_pequeno", "p_passarela", "p_suporte", "p_estrutura_vertical",
    "p_lamina_pendular", "p_particulas_luz", "p_poeira_ar", "p_brilho_sino",
    "p_raios_luz", "p_neblina", "p_heras", "p_detritos", "p_poeira_chao",
    # N13 -- maquinas (level_mechanics.png, coluna N13, e o atlas)
    "m_roda", "m_sino_padrao", "m_mecanismo_central", "m_ponte_movel",
    "m_engrenagem", "m_contrapeso", "m_engrenagem_mortal", "m_corrente_peso",
    "m_lamina_pendulo", "m_alavanca", "m_interruptor", "m_mecanismo_sino",
    "m_porta", "m_elevador", "m_ponte_reconfig", "m_plat_rotativa",
    "m_tex_metal", "m_tex_bronze", "m_tex_madeira", "m_tex_correntes",
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
                 f"region_rect = Rect2(0, 0, {w:g}, {h:g})\nmodulate = Color(0.3, 0.3, 0.44, 1)",
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

# ======================================================================
#  RAIZ + ATMOSFERA
# ======================================================================
no("Torre_da_Tempestade",
   f'script = ExtResource("{ID["niv"]}")\ncorredor = false\n'
   "alongar_plataformas = false\ncheckpoints_autorais = true\n"
   'mecanica_anunciada = "engrenagens"\nestreia_x_autoral = 1300.0',
   tipo="Node2D", pai="")
nos[0] = nos[0].replace(' parent=""', "")

# os valores sao os de `tools/afinar_atmosfera.py` (linha Torre_da_Tempestade)
# -- correr esse tool depois deste nao muda nada
no("Atmosfera", """cor_ambiente = Color(1, 0.92, 0.8, 1)
cor_fundo = Color(0.07, 0.06, 0.12, 1)
cor_silhueta = Color(0.12, 0.1, 0.16, 1)
cor_luz = Color(1, 0.72, 0.38, 1)
cor_poeira = Color(1, 0.86, 0.62, 1)
densidade_poeira = 2.2
bioma = "torres"
largura_nivel = 3600.0
fundo_pack = "torre_ecos"
tinta_fundo = Color(1.04, 0.92, 0.94, 1)
neblina_fundo = 0.28
dessaturar_fundo = 0.2
seed_ambiente = 1444
luzes_horizonte = true""", inst="atm")

# ======================================================================
#  A CASCA DA TORRE -- paredes de fora e as lajes entre andares
# ======================================================================
com("""
A CASCA: paredes exteriores a toda a altura e as lajes GROSSAS entre andares
(250 px -- o chao de um andar e' o tecto do de baixo). Os furos nas lajes
sao os pocos dos elevadores, SEMPRE depois de uma porta.
""")
casca("ParedeOeste", -260, 0, TOPO_TORRE, 1160)
casca("ParedeLeste", LARG, LARG + 260, TOPO_TORRE, 1160)
casca("Telhado", 0, LARG, TOPO_TORRE, T3)

# ======================================================================
#  INTERIOR -- a parede do fundo de cada andar (so' visual)
# ======================================================================
com("""
INTERIOR DA TORRE -- "o coracao da torre" das pranchas (`layout_usage.png`,
set pieces e faixa de paleta do N13): cantaria azul-noite, pilares, e em
cada vao entre pilares OU uma janela gotica com a lua a entrar, OU uma
maquina de ouro velho a rodar (engrenagens em sentidos opostos, como numa
caixa de velocidades) com correntes douradas a pender. Chamas nos pilares
com brilho pintado (sem PointLight2D -- sao dezenas).
""")
ANDARES = [(Y1, T1), (Y2, T2), (Y3, T3)]
PILARES = [0, 620, 1240, 1960, 2640, 3220, 3600]
for j, (chao, tecto) in enumerate(ANDARES):
    mosaico(f"ParedeFundo{j}", "corpo_te", 0, tecto, LARG, chao + FUNDO_FOSSO + 20, z=-12,
            mod=PAREDE)
    for i, x in enumerate(PILARES[1:-1], start=1):
        mosaico(f"Pilar{j}_{i}", "p_parede", x - 34, tecto, x + 34, chao,
                esc=1.1, z=-9, mod=PILAR)
        pendurado(f"Misula{j}_{i}", "p_suporte", x, tecto - 4, esc=1.05, z=-8, mod=PILAR)
        assente(f"Tocha{j}_{i}", "tocha", x, tecto + 170, esc=1.1, z=-7)
        fx(f"BrilhoTocha{j}_{i}", "p_brilho_sino", x, tecto + 120, esc=0.9, z=-7,
           mod="Color(1, 0.62, 0.3, 0.45)")
    # sombra que desce do tecto (o topo de cada andar e' o mais escuro; a
    # luz vive junto ao chao, como na faixa de paleta da prancha)
    no(f"SombraTecto{j}", f"position = {v(0, tecto)}\ncentered = false\n"
                          f"scale = {v(LARG / 64.0, 220 / 64.0)}\n"
                          'texture = SubResource("tex_sombra")\nz_index = -8', tipo="Sprite2D")
    # friso de metal dourado a correr por baixo do tecto de cada andar
    mosaico(f"FrisoTecto{j}", "m_tex_metal", 0, tecto, LARG, tecto + 14, esc=0.5, z=-7,
            mod="Color(0.7, 0.56, 0.42, 1)")

# o que vai em cada vao (andar, indice do vao entre PILARES): "j" janela,
# "m" maquina de fundo, "" nada (o vao tem um set piece proprio a' frente)
VAOS = {
    (0, 0): "j", (0, 1): "m", (0, 2): "", (0, 3): "j", (0, 4): "m", (0, 5): "c",
    (1, 0): "j", (1, 1): "m", (1, 2): "m", (1, 3): "j", (1, 4): "", (1, 5): "j",
    (2, 0): "j", (2, 1): "j", (2, 2): "j", (2, 3): "", (2, 4): "j", (2, 5): "",
}
n_vao = 0
for (j, k), tipo in VAOS.items():
    chao, tecto = ANDARES[j]
    a, b = PILARES[k], PILARES[k + 1]
    x = (a + b) / 2.0
    if tipo == "j":
        t = "p_vitral_dourado" if (j + k) % 2 == 0 else "p_parede_vitral"
        esc = 250.0 / TAM_TEX[t][1]
        pendurado(f"Janela{n_vao}", t, x, tecto + 50, esc=esc, z=-10,
                  mod="Color(0.72, 0.8, 1, 0.95)")
        assente(f"ArcoJanela{n_vao}", "arco_grande", x, tecto + 50 + 250 + 26,
                esc=1.75, z=-11, mod="Color(0.42, 0.44, 0.7, 1)")
        fx(f"RaiosJanela{n_vao}", "p_raios_luz", x + 40, tecto + 330, esc=1.4, z=-9,
           mod="Color(0.62, 0.74, 1, 0.32)")
    elif tipo == "m":
        gira(f"MaquinaFundo{n_vao}", "m_roda" if k % 2 else "m_engrenagem",
             x, tecto + 170, 1.0, 0.14 if (j + k) % 2 else -0.14, z=-10,
             mod="Color(0.62, 0.5, 0.38, 1)")
        gira(f"MaquinaFundoB{n_vao}", "m_engrenagem" if k % 2 else "m_roda",
             x + 150, tecto + 290, 0.62, -0.23 if (j + k) % 2 else 0.23, z=-10,
             mod="Color(0.55, 0.44, 0.34, 1)")
        corrente(f"CorrenteFundoA{n_vao}", x - 150, tecto + 14, chao - 120, z=-10,
                 mod="Color(0.7, 0.56, 0.36, 0.9)")
        corrente(f"CorrenteFundoB{n_vao}", x - 110, tecto + 14, chao - 200, z=-10,
                 mod="Color(0.7, 0.56, 0.36, 0.9)")
    elif tipo == "c":
        for d in (-60, 60):
            corrente(f"CorrenteFundoC{n_vao}_{d}", x + d, tecto + 14, chao - 60, z=-10,
                     mod="Color(0.7, 0.56, 0.36, 0.9)")
    n_vao += 1

# --------------------------------------------------------- andar de baixo
com("""
===================  ANDAR 1 -- A) INTRODUCAO  e  B) SALAS DE ENGRENAGENS ===
""")
laje("Chao1", 0, 1150, Y1, 1160)
laje("Chao2a", 1950, 2350, Y1, 1160)
laje("Chao2b", 2750, 3600, Y1, 1160)
# laje entre andar 1 e 2, em pedacos: os fossos do andar 2 (pontes 2300-2950,
# ponte movel 1440-2000) cavam-na por cima; o furo do elevador 1 fica entre
# 3290 e a parede.
laje("Laje12a", 0, 1440, Y2, T1)
laje("Laje12b", 2000, 2300, Y2, T1)
laje("Laje12c", 2950, 3290, Y2, T1)

com("""
A) Introducao aos mecanismos. Sala segura, sem inimigos: a PRIMEIRA ALAVANCA
abre a PRIMEIRA PORTA de bronze -- a relacao le-se de uma vez (a porta esta'
a' vista da alavanca, a corrente dourada liga-as pelo tecto).
""")
no("Koliani", f"position = {v(150, Y1 - 40)}\nusar_prototipo_premium = true\n"
              "usar_golden_set = true", inst="kol")
check("CheckInicio", 280, Y1)
alavanca("AlavancaA", 660, Y1, "a")
grade("PortaA", 1080, Y1, T1, "a")
# a casa de maquinas da sala A: painel de bronze por tras da alavanca, com a
# grande roda a girar e a corrente que sobe para a porta
assente("MecanismoSinoA", "m_mecanismo_sino", 330, Y1, esc=0.9, z=-3,
        mod="Color(0.85, 0.82, 0.9, 1)")
assente("CandelabroA", "candelabro", 560, Y1, esc=1.2, z=-1)
luz("LuzA", 600, Y1 - 60, 0.6, OURO, (2.2, 1.4))
pendurado("LampiaoA", "lampiao_t", 900, T1 + 14, esc=1.4, z=-2)
assente("RelogioA", "relogio_antigo", 180, Y1, esc=1.5, z=-3, mod="Color(0.8, 0.78, 0.9, 1)")

com("""
SALA DAS ENGRENAGENS (set piece). Fosso largo (800 px, fora de qualquer
salto) com espinhos e uma SERRA-ENGRENAGEM a rolar no fundo. Atravessa-se
nos BRACOS de duas engrenagens em cruz que rodam devagar: sobe-se num braco
quando esta' em baixo e salta-se antes de ele subir. Por cima, colada ao
tecto, a prateleira do SEGREDO 1 -- so' se chega do cimo de um braco.
""")
fosso("FossoEngr", 1150, 1950, Y1, 1160, espinhar=False)
# espinhos em dois troços: junto ao poleiro fica chao limpo, para quem cai
# poder trepar a coluna de volta (escalar_paredes) sem pagar duas vezes
espinhos("FossoEngrEspinhosE", 1230, 1454, Y1 + FUNDO_FOSSO)
espinhos("FossoEngrEspinhosD", 1666, 1870, Y1 + FUNDO_FOSSO)
# o mesmo ritmo das engrenagens canonicas (`gerador_corredor._f_engrenagens`,
# N56): cruz de 200 px, volta em ~5 s, eixo 40 px acima do chao, e um
# POLEIRO entre as duas para respirar
for nome, x, f in [("RodaA1", 1340, 0.0), ("RodaA2", 1780, 0.37)]:
    no(nome, f"position = {v(x, Y1 - 40)}\nscript = ExtResource(\"{ID['roda']}\")\n"
             f"amplitude_graus = 0.0\nperiodo = 5.0\nfase = {f:g}\ncomprimento = 200.0\n"
             f"espessura = 18.0\nbracos = 2\ntextura_roda = {tex('m_engrenagem')}\n"
             f"textura_braco = {tex('m_tex_metal')}", tipo="AnimatableBody2D")
laje("PoleiroEngr", 1514, 1606, Y1, 1160)
no("SerraFosso", f"position = {v(1300, Y1 + FUNDO_FOSSO - 34)}\npercurso = {v(500, 0)}\n"
                 f"tempo = 2.6\ntextura = {tex('m_engrenagem_mortal')}\nescala_textura = 0.42\n"
                 "giro_por_seg = 5.0", inst="serra")
# a roda grande da prancha "Sala das engrenagens", em ouro, ao centro do
# fosso, com duas rodas pequenas engrenadas nela
gira("EngrenFundoB1", "m_roda", 1555, 640, 1.1, 0.1, z=-10, mod="Color(0.5, 0.4, 0.3, 1)")
gira("EngrenFundoB2", "m_engrenagem", 1340, 590, 0.62, -0.19, z=-10)
gira("EngrenFundoB3", "m_engrenagem", 1775, 600, 0.62, -0.19, z=-10)
corrente("CorrenteEngrE", 1200, T1 + 14, 900, z=-10, mod="Color(0.7, 0.56, 0.36, 0.9)")
corrente("CorrenteEngrD", 1910, T1 + 14, 880, z=-10, mod="Color(0.7, 0.56, 0.36, 0.9)")
plat("Segredo1", 1420, 1500, 660, h=22)
ess("EssenciaSegredo1", 1455, 660, 20)
assente("UrnaSegredo1", "urna", 1490, 660, esc=1.1, z=-1)
luz("LuzSegredo1", 1460, 630, 0.35, ROXO, (0.9, 0.8))
luz("LuzEngr", 1550, 900, 0.3, OURO, (3.0, 1.6))

com("""
B) Alavancas multiplas: a PORTA B so' abre com as DUAS alavancas (uma no
chao, outra numa varanda). Entre elas, o PISO QUE COLAPSA por cima de um
fosso, com duas LAMINAS EM PENDULO a varrer a passagem. Autómato do Sino a
guardar a porta.
""")
check("CheckA", 2030, Y1)
alavanca("AlavancaB1", 2230, Y1, "b")
fosso("FossoQuebra", 2350, 2750, Y1, 1160)
for i, e in enumerate([2350, 2450, 2550, 2650], start=1):
    quebra(f"PisoQuebra{i}", e, e + 100, Y1)
no("PenduloB1", f"position = {v(2470, T1 + 4)}\ncomprimento = 300.0\namplitude_graus = 52.0\n"
                f"periodo = 2.4\ndano = 20\ntextura_haste = {tex('m_tex_correntes')}\n"
                f"textura_lamina = {tex('m_lamina_pendulo')}\nescala_lamina = 0.55", inst="pend")
no("PenduloB2", f"position = {v(2640, T1 + 4)}\ncomprimento = 300.0\namplitude_graus = 52.0\n"
                f"periodo = 2.4\nfase = 0.5\ndano = 20\ntextura_haste = {tex('m_tex_correntes')}\n"
                f"textura_lamina = {tex('m_lamina_pendulo')}\nescala_lamina = 0.55",
   inst="pend")
plat("VarandaB", 2900, 3080, 780, h=24)
alavanca("AlavancaB2", 3000, 780, "b")
heras("HerasVarandaB", 2930, 780 + 24, esc=0.7)
grade("PortaB", 3240, Y1, T1, "b", extra="exige_todas = true")
inimigo("AutomatoB", 3050, Y1 - 55, "automato_do_sino", "escudeiro", 110, 20, 120,
        "Color(1.0, 0.78, 0.45, 1)", escala=1.2)
pendurado("LampiaoB1", "lampiao_t", 2150, T1 + 14, esc=1.4, z=-2)
luz("LuzB", 2150, 640, 0.55, OURO, (2.0, 1.6))
assente("CandelabroB", "candelabro", 3140, Y1, esc=1.2, z=-1)

com("""
1.o ELEVADOR DE CONTRAPESO (peso): a plataforma sobe pela laje, o
contrapeso de bronze desce do outro lado da roldana. Depois da porta B.
""")
elevador("Elevador1", 3395, 190, Y1 - 26, Y2, False, 1.0)
luz("LuzRoldana1", 3395, Y2 - 150, 0.5, OURO, (1.3, 1.1))

# --------------------------------------------------------- andar do meio
com("""
===================  ANDAR 2 -- C) SINOS E PLATAFORMAS  (volta para oeste) ==
""")
# laje entre andar 2 e 3: furo do elevador 2 entre 180 e 520 (o contrapeso
# desce pelo lado direito do poco), fosso do D1
# entre 800 e 1200
laje("Laje23a", 0, 180, Y3, T2)
laje("Laje23b", 520, 800, Y3, T2)
laje("Laje23c", 1200, LARG, Y3, T2)
check("CheckB", 3150, Y2)

com("""
C1 -- PONTES RECONFIGURAVEIS. Fosso de 650 px sob um TECTO BAIXO (110 px de
folga: nao ha' arco de salto nem salto duplo). A meio, um pilar com uma
alavanca: pisa-la troca as pontes -- a da direita some-se, a da esquerda
aparece. Um Espirito do Eco anda por cima do fosso.
""")
fosso("FossoPontes", 2300, 2950, Y2, T1, espinhar=False)
# chao limpo junto ao pilar: quem cai com a ponte errada trepa o pilar ate'
# a' alavanca e volta a trocar (nunca fica preso do lado de la')
espinhos("FossoPontesEspinhosE", 2380, 2515, Y2 + FUNDO_FOSSO)
espinhos("FossoPontesEspinhosD", 2735, 2870, Y2 + FUNDO_FOSSO)
laje("PilarPontes", 2575, 2675, Y2, Y2 + FUNDO_FOSSO)
# o tecto baixo DESCE do tecto do andar (nao e' uma laje solta: por cima dela
# nao ha' onde pisar)
laje("TetoBaixo", 2240, 3010, T2, Y2 - 110, escurecer=False)
# o miolo escurece de cima para baixo (a massa recua; so' a aresta le')
no("TetoBaixoMassa", f"position = {v(2240, T2)}\ncentered = false\n"
                     f"scale = {v(770 / 64.0, (Y2 - 150 - T2) / 64.0)}\n"
                     'texture = SubResource("tex_massa_cima")\nz_index = 1', tipo="Sprite2D")
# a aresta do tecto baixo e' uma VIGA de maquina (metal dourado), nao pedra
mosaico("VigaTetoBaixo", "m_tex_metal", 2240, Y2 - 132, 3010, Y2 - 110, esc=0.5, z=1,
        mod="Color(0.62, 0.5, 0.4, 1)")
plat("PonteDireita", 2675, 2950, Y2, h=20, av=18, inst="eco",
     extra='grupo_alternar = "pontes_c1"\ncomeca_solida = true\nalpha_fantasma = 0.22')
plat("PonteEsquerda", 2300, 2575, Y2, h=20, av=18, inst="eco",
     extra='grupo_alternar = "pontes_c1"\nalpha_fantasma = 0.22')
alavanca("AlavancaPontes", 2625, Y2, "pontes_c1",
         extra='alterna_grupo = "pontes_c1"', so_liga=False)
for i, x in enumerate([2340, 2500, 2700, 2860]):
    pendurado(f"PonteReconf{i}", "m_ponte_reconfig", x + 40, Y2 - 110 - 2, esc=0.9, z=-3,
              mod="Color(0.8, 0.72, 0.64, 1)")
inimigo("EspiritoC1", 2620, Y2 - 60, "espirito_do_eco", "voador", 45, 14, 180,
        "Color(0.6, 0.75, 1.0, 1)")

com("""
C2 -- PONTE MOVEL (set piece): uma laje num carro que corre num trilho do
tecto, de um lado ao outro de um fosso de 560 px. Por cima, correntes com
peso a baloicar. Construto Vitral do outro lado.
""")
fosso("FossoMovel", 1440, 2000, Y2, T1)
no("PonteMovel", f"position = {v(1720, Y2 + 9)}\nmodo = \"horizontal\"\namplitude = 190.0\n"
                 "periodo = 5.2\ncomprimento = 300.0\nlargura = 150.0\npele_terreno = true\n"
                 f"ancora_no_trilho = true\ntextura_corrente = {tex('m_tex_correntes')}",
   inst="pcorr")
mosaico("TrilhoMovel", "m_tex_metal", 1440, T2 + 6, 2000, T2 + 28, esc=0.5, z=-2,
        mod="Color(0.85, 0.7, 0.5, 1)")
no("PesoC1", f"position = {v(1600, T2 + 28)}\ncomprimento = 190.0\namplitude_graus = 40.0\n"
             f"periodo = 2.8\ndano = 16\ntextura = {tex('m_corrente_peso')}", inst="pend")
no("PesoC2", f"position = {v(1860, T2 + 28)}\ncomprimento = 190.0\namplitude_graus = 40.0\n"
             f"periodo = 2.8\nfase = 0.5\ndano = 16\ntextura = {tex('m_corrente_peso')}",
   inst="pend")
solto("PonteMovelPintada", "m_ponte_movel", 1720, T2 + 110, esc=1.3, z=-9,
      mod="Color(0.5, 0.44, 0.46, 1)")

com("""
C3 -- a alavanca C numa prateleira alta (330 px acima do chao, fora do
salto duplo): so' se chega do braco de uma engrenagem. Construto Vitral a
patrulhar. SEGREDO 2 por tras da engrenagem, do lado do tecto.
""")
inimigo("ConstrutoC3", 1100, Y2 - 60, "construto_vitral", "carga", 120, 20, 200,
        "Color(0.62, 0.72, 1.0, 1)", escala=1.2)
no("RodaC", f"position = {v(1200, 110)}\nscript = ExtResource(\"{ID['roda']}\")\n"
            "amplitude_graus = 0.0\nperiodo = 5.0\ncomprimento = 200.0\nespessura = 18.0\n"
            f"bracos = 2\ntextura_roda = {tex('m_roda')}\n"
            f"textura_braco = {tex('m_tex_metal')}", tipo="AnimatableBody2D")
plat("PrateleiraC", 880, 1040, Y2 - 330, h=22)
alavanca("AlavancaC", 960, Y2 - 330, "c")
plat("Segredo2", 1360, 1450, Y2 - 340, h=22)
ess("EssenciaSegredo2", 1405, Y2 - 340, 25)
luz("LuzSegredo2", 1405, Y2 - 370, 0.35, ROXO, (0.9, 0.8))
grade("PortaC", 620, Y2, T2, "c")
check("CheckC", 1380, Y2)
pendurado("LampiaoC1", "lampiao_t", 820, T2 + 14, esc=1.4, z=-2)
luz("LuzC", 900, 20, 0.55, OURO, (2.0, 1.6))

com("""
2.o ELEVADOR (vaivem continuo): ensina a esperar em vez de chamar.
""")
elevador("Elevador2", 310, 240, Y2 - 26, Y3, True, 1.0)
luz("LuzRoldana2", 310, Y3 - 150, 0.5, OURO, (1.3, 1.1))
assente("UrnaE2", "urna", 520, Y2, esc=1.3, z=-1)

# --------------------------------------------------------- andar de cima
com("""
===================  ANDAR 3 -- D) NUCLEO CENTRAL  (elemento chave)  =========
""")
check("CheckD", 560, Y3)

com("""
D1 -- piso que colapsa sobre um fosso, duas laminas em pendulo e dois
Espiritos do Eco a atravessar.
""")
fosso("FossoD1", 800, 1200, Y3, T2)
for i, e in enumerate([800, 900, 1000, 1100], start=1):
    quebra(f"PisoD{i}", e, e + 100, Y3)
no("PenduloD1", f"position = {v(900, T3 + 4)}\ncomprimento = 320.0\namplitude_graus = 50.0\n"
                f"periodo = 2.2\ndano = 20\ntextura_haste = {tex('m_tex_correntes')}\n"
                f"textura_lamina = {tex('m_lamina_pendulo')}\nescala_lamina = 0.55", inst="pend")
no("PenduloD2", f"position = {v(1100, T3 + 4)}\ncomprimento = 320.0\namplitude_graus = 50.0\n"
                f"periodo = 2.2\nfase = 0.5\ndano = 20\ntextura_haste = {tex('m_tex_correntes')}\n"
                f"textura_lamina = {tex('m_lamina_pendulo')}\nescala_lamina = 0.55",
   inst="pend")
inimigo("EspiritoD1", 1000, Y3 - 170, "espirito_do_eco", "voador", 45, 14, 200,
        "Color(0.6, 0.75, 1.0, 1)")
inimigo("EspiritoD2", 1500, Y3 - 200, "espirito_do_eco", "voador", 45, 14, 160,
        "Color(0.6, 0.75, 1.0, 1)")

com("""
D2 -- NUCLEO CENTRAL. O MECANISMO DE 3 SINOS: com a Koliani perto, ele toca
o PADRAO (os sinos brilham e soam por ordem). Toca-los pela mesma ordem
liga o nucleo e abre a porta do guardiao. Errar apaga tudo e o eco repete.
Sino pequeno a' esquerda, grande ao centro (em cima de um estrado), medio
a' direita. SEGREDO 3 por cima do estrado.
""")
check("CheckNucleo", 1380, Y3)
NUC_X = 2080
no("Nucleo", f"position = {v(NUC_X, -690)}\nscript = ExtResource(\"{ID['mecsin']}\")\n"
             'id = "nucleo"\nsinos = [NodePath("../SinoP"), NodePath("../SinoG"), '
             'NodePath("../SinoM")]\nordem = PackedInt32Array(1, 0, 2)\nraio_eco = 700.0\n'
             f"textura_mecanismo = {tex('p_rosacea')}\nescala_mecanismo = 1.3",
   inst="alav")
# o set piece "Mecanismo central" da prancha: a grande roda dourada com o
# vitral azul no cubo (acende-se a' medida que o padrao entra), por tras
# dos tres sinos pendurados de uma trave de metal dourado
gira("RodaNucleo", "m_roda", NUC_X, -690, 1.25, 0.06, z=-10, mod="Color(0.6, 0.48, 0.36, 1)")
gira("RodaNucleoFora", "m_engrenagem", NUC_X, -690, 1.6, -0.035, z=-11,
     mod="Color(0.34, 0.28, 0.26, 1)")
mosaico("TraveSinos", "m_tex_metal", 1600, T3 + 70, 2560, T3 + 92, esc=0.5, z=-2,
        mod="Color(0.9, 0.74, 0.52, 1)")
plat("Estrado", NUC_X - 110, NUC_X + 110, Y3 - 130, h=30, av=40)
plat("DegrauEstrado", NUC_X - 230, NUC_X - 140, Y3 - 60, h=22)
for nome, x, y, e, t in [("SinoP", 1680, Y3 - 62, 0.62, "m_sino_padrao"),
                         ("SinoG", NUC_X, Y3 - 205, 0.8, "m_sino_padrao"),
                         ("SinoM", 2480, Y3 - 66, 0.7, "m_sino_padrao")]:
    no(nome, f"position = {v(x, y)}\nscale = {v(e, e)}\nso_congela = true\n"
             f'alterna_grupo = ""\ntextura = {tex(t)}', inst="sino")
    corrente(f"Corrente{nome}", x, T3 + 80, y - 70 * e, z=-3)
    fx(f"Brilho{nome}", "p_brilho_sino", x, y - 10, esc=1.0, z=-1,
       mod="Color(1, 0.85, 0.6, 0.45)")
plat("Segredo3", 2270, 2390, Y3 - 240, h=22)
ess("EssenciaSegredo3", 2330, Y3 - 240, 30)
assente("MemorialSegredo3", "pedra_memoria", 2370, Y3 - 240, esc=1.2, z=-1)
luz("LuzSegredo3", 2330, Y3 - 320, 0.35, ROXO, (0.9, 0.8))
luz("LuzNucleo", NUC_X, -600, 0.4, OURO, (3.0, 2.0))
grade("PortaNucleo", 2860, Y3, T3, "nucleo")

com("""D3 -- sala final: B4 (plano N1-N20, DEC-012, 3 out 2026) -- o 3.o nivel da
regiao acaba num ENCONTRO, nao num guardiao. O Construto Vitral elite fica,
com um Espirito do Eco e um Automato do Sino, numa sala que FECHA (grade da
esquerda junto a' PortaNucleo); a porta esta' dentro -> sela_porta. Deixa de
se chamar `Guardiao` (era o que o `nivel_com_chefe` lia).""")
no("ArenaFinal", f'position = {v(3210, Y3 - 130)}\nscript = ExtResource("{ID["arena"]}")\n'
                 f"tamanho = {v(700, 260)}\naltura_grade = 340.0\n"
                 'grupo_inimigos = "arena_n13_final"\ncor_grade = Color(0.62, 0.66, 0.95, 0.95)\n'
                 "sela_porta = true", tipo="Area2D")
inimigo("EliteConstruto", 3250, Y3 - 80, "construto_vitral", "carga", 280, 24, 180,
        "Color(0.62, 0.72, 1.0, 1)", elite=True, escala=1.6, grupos=["arena_n13_final"])
inimigo("EspiritoFinal", 3050, Y3 - 160, "espirito_do_eco", "voador", 70, 12, 160,
        "Color(0.6, 0.75, 1.0, 1)", grupos=["arena_n13_final"])
inimigo("AutomatoFinal", 3420, Y3 - 60, "automato_do_sino", "escudeiro", 110, 18, 60,
        "Color(1.0, 0.78, 0.45, 1)", grupos=["arena_n13_final"])
assente("EstatuaArena1", "estatua_anjo", 2980, Y3, esc=1.7, z=-3)
assente("EstatuaArena2", "estatua_anjo", 3520, Y3, esc=1.7, z=-3, flip=True)
pendurado("VitralArena", "vitral_alto", 3250, T3 + 30, esc=2.4, z=-6,
          mod="Color(0.85, 0.9, 1, 0.9)")
luz("LuzArena", 3250, Y3 - 60, 0.7, OURO, (3.0, 1.7))
no("Porta", f'position = {v(3500, Y3 + 6)}\npista_ao_atravessar = ""', inst="porta")

# ======================================================================
#  VIDA DA TORRE -- heras, entulho, poeira (so' visual)
# ======================================================================
for nome, t, x, y, e in [
        ("DetritosA", "p_detritos", 40, Y1, 0.55), ("PoeiraA", "p_poeira_chao", 900, Y1, 0.55),
        ("DetritosB", "p_detritos", 3560, Y1, 0.5), ("PoeiraC", "p_poeira_chao", 3300, Y2, 0.55),
        ("DetritosC", "p_detritos", 60, Y2, 0.5), ("PoeiraD", "p_poeira_chao", 400, Y3, 0.55),
        ("DetritosD", "p_detritos", 3560, Y3, 0.5)]:
    assente(nome, t, x, y, esc=e, z=0, mod="Color(0.8, 0.8, 0.95, 1)")
for nome, x, y, e in [("NeblinaEngr", 1550, Y1 + 120, 3.0), ("NeblinaQuebra", 2550, Y1 + 120, 2.6),
                      ("NeblinaPontes", 2620, Y2 + 130, 2.6), ("NeblinaMovel", 1720, Y2 + 130, 2.6),
                      ("NeblinaD1", 1000, Y3 + 130, 2.4)]:
    fx(nome, "p_neblina", x, y, esc=e, z=1, mod="Color(0.7, 0.6, 0.8, 0.4)")

# ======================================================================
#  PRIMEIRO PLANO -- silhuetas escuras a' frente de tudo (profundidade)
# ======================================================================
com("""
Primeiro plano: correntes e pilares em silhueta, quase pretos, a' frente da
Koliani (z alto). Dao a profundidade das pranchas. Nunca por cima de uma
alavanca, sino, porta ou fosso -- so' onde nao ha' nada para ler.
""")
FRENTE = "Color(0.07, 0.06, 0.1, 1)"
for nome, x, j in [("FrenteCorrenteA", 250, 0), ("FrenteCorrenteB", 2080, 0),
                   ("FrenteCorrenteC", 3150, 1), ("FrenteCorrenteD", 1200 - 300, 1),
                   ("FrenteCorrenteE", 620 - 150, 2), ("FrenteCorrenteF", 3000, 2)]:
    chao, tecto = ANDARES[j]
    corrente(nome, x, tecto, chao - 90, z=6, mod=FRENTE)
    corrente(nome + "b", x + 26, tecto, chao - 150, z=6, mod=FRENTE)
for nome, x, j in [("FrentePilarA", 1960, 0), ("FrentePilarB", 1240, 1), ("FrentePilarC", 1240, 2)]:
    chao, tecto = ANDARES[j]
    mosaico(nome, "p_parede", x - 30, tecto, x + 30, chao + 40, esc=1.3, z=6, mod=FRENTE)

# ======================================================================
#  ADERECOS DE CHAO -- a oficina da torre
# ======================================================================
for nome, t, x, y, e in [
        ("LivrosA", "livros", 470, Y1, 1.2), ("UrnaA", "urna", 820, Y1, 1.2),
        ("LanternaB", "lanterna_eco", 2060, Y1, 1.4), ("LivrosB", "livros", 2800, Y1, 1.2),
        ("UrnaC", "urna", 3450, Y2, 1.2), ("LanternaC", "lanterna_eco", 2080, Y2, 1.4),
        ("LivrosC", "livros", 1300, Y2, 1.1), ("RelogioC", "relogio_antigo", 760, Y2, 1.4),
        ("LanternaD", "lanterna_eco", 1330, Y3, 1.4), ("UrnaD", "urna", 2700, Y3, 1.2)]:
    assente(nome, t, x, y, esc=e, z=-1)
# engrenagens soltas / pecas de maquina no chao
for nome, x, y, e, r in [("PecaA", 930, Y1, 0.22, 0.4), ("PecaB", 3090, Y1, 0.2, 1.1),
                         ("PecaC", 2200, Y2, 0.24, 0.2), ("PecaD", 600, Y3, 0.2, 0.9),
                         ("PecaE", 2760, Y3, 0.22, 0.3)]:
    no(nome, f"position = {v(x, y - 216 * e / 2 + 6)}\nscale = {v(e, e)}\nrotation = {r:g}\n"
             f"texture = {tex('m_engrenagem')}\nz_index = -1\nmodulate = Color(0.8, 0.66, 0.5, 1)",
       tipo="Sprite2D")
# heras nas arestas dos tectos, junto aos pocos
for nome, x, y, e, f in [("HerasPoco1", 3270, T1, 0.8, True), ("HerasPoco2", 540, T2, 0.8, False),
                         ("HerasEngr", 1180, T1, 0.7, False), ("HerasNucleo", 2980, T3, 0.8, True),
                         ("HerasPontes", 2270, Y2 - 110, 0.6, False)]:
    heras(nome, x, y, esc=e, flip=f)

# ---------------------------------------------------------------- escrever
corpo_nos = "\n".join(nos)
linhas_ext = [l for l in linhas_ext if 'ExtResource("%s")' % l.split(' id="')[1][:-2] in corpo_nos]
cab = f'[gd_scene load_steps={len(linhas_ext) + 11 + len(SUBS_EXTRA)} format=3 uid="uid://bkolianitorretempestade13"]'
topo = """
; REGIAO III / nivel 13 -- MECANISMOS ANTIGOS (`level.n12`), "O Coracao da Torre".
; O nome do ficheiro fica: muda-lo partia saves e checkpoints.
;
; GERADO por `tools/construir_n13_mecanismos.py` -- editar la', nao aqui.
; Desenho, medicoes e o que ficou por decidir: `docs/nivel_autoral_n13.md`.
;
; Nivel AUTORAL (`corredor = false`): a jornada procedural e a sala do
; Voltaris (chefe de tempestade, fora do contrato LOCKED) sairam. Tres
; andares de maquinaria (A-D do contrato):
;   A) Introducao     -- 1.a alavanca abre a 1.a porta de bronze;
;   B) Engrenagens    -- sala das engrenagens (bracos que rodam sobre um
;                        fosso com serra), alavancas multiplas, piso que
;                        colapsa, laminas em pendulo, elevador de contrapeso;
;   C) Sinos e plat.  -- pontes reconfiguraveis sob tecto baixo, ponte movel
;                        num trilho, correntes com peso, alavanca so' do
;                        braco de uma engrenagem, 2.o elevador;
;   D) Nucleo central -- o mecanismo de 3 sinos (padrao) abre a sala do
;                        GUARDIAO (Construto Vitral elite).
; 3 segredos, 6 checkpoints; inimigos: Autómato do Sino, Construto Vitral,
; Espirito do Eco.
"""
subs = "\n".join(SUBS_EXTRA) + """
[sub_resource type="RectangleShape2D" id="rs_chk"]
size = Vector2(44, 96)

[sub_resource type="CanvasItemMaterial" id="mat_add"]
blend_mode = 1

[sub_resource type="Gradient" id="grad_massa"]
offsets = PackedFloat32Array(0, 0.35, 1)
colors = PackedColorArray(0.02, 0.02, 0.05, 0.25, 0.02, 0.02, 0.05, 0.78, 0.01, 0.01, 0.03, 0.9)

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
