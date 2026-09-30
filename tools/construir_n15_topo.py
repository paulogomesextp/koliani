#!/usr/bin/env python3
"""Gera `scenes/levels/O_Pico_Esquecido.tscn` -- N15 "O Topo dos Ecos".

Mesma ideia do `tools/construir_n14_campanario.py`: a cena e' AUTORAL, mas as
coordenadas dependem umas das outras (o topo de uma laje, o curso de um
elevador, os degraus que o sino celestial ergue ate' a' arena), por isso
escreve-se aqui, por TOPO e bordas, e o `.tscn` sai gerado.

EDITAR AQUI e voltar a correr; nao editar o `.tscn` a mao:
    python tools/construir_n15_topo.py

Contrato: docs/art_direction/regions/region_03/REGION03_VISUAL_GAMEPLAY_CONTRACT.md
(N15 -- LOCKED). Desenho e medicoes: docs/nivel_autoral_n15.md.

A SUBIDA FINAL, de baixo para cima, toda ao ar livre (sem paredes onde
trepar -- a Koliani ja' escala qualquer face):
  A) ascensao final: terraco da base, o fosso de pedras em colapso com vento,
     o 1.o sino que acende os degraus temporizados ate' a' laje alta;
  B) plataformas e ultimos desafios: a cadeia dos ECOS DE MEMORIA (plataformas
     que pulsam) sob FEIXES DE LUZ e vento; os degraus em colapso;
  C) caminho para a arena: a coluna de ar ate' ao ALTAR DOS SINOS e os tres
     FRAGMENTOS DE ECO (elevador, baloicos com vento, coluna de ar); com os tres,
     o SINO CELESTIAL ergue a escada de ecos ate' a arena;
  D) arena -- Vyrak, A Voz dos Ecos: chao largo, plataformas da fase 1 e as
     da fase 2 (que so' se erguem no ritual aos 50 %).
"""
from __future__ import annotations

import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "scenes", "levels", "O_Pico_Esquecido.tscn")

# Paleta LOCKED da regiao (as cores de `Plataforma` sao ignoradas pelo visual
# pixel-art, mas ficam coerentes).
PEDRA = "cor_base = Color(0.24, 0.25, 0.32, 1)\ncor_topo = Color(0.52, 0.54, 0.66, 1)"

# ---------------------------------------------------------------- alturas
YA = 1000.0                             # terraco da base
YARENA = -1180.0                        # chao da arena de Vyrak
LARG = 3700.0
FUNDO_FOSSO = 180.0

EXT = [
    ("PackedScene", "uid://bkolianiactor01", "res://scenes/actors/Koliani.tscn", "kol"),
    ("PackedScene", "uid://bdemoniobase01", "res://scenes/actors/DemonioBase.tscn", "dem"),
    ("PackedScene", "uid://bkolianiporta01", "res://scenes/actors/Porta.tscn", "porta"),
    ("Script", None, "res://scripts/checkpoint.gd", "chk"),
    ("Script", None, "res://scripts/nivel_com_chefe.gd", "niv"),
    ("PackedScene", "uid://bkolianichefevyrak15", "res://scenes/actors/ChefeVyrak.tscn", "chefe"),
    ("PackedScene", "uid://bkolianiplatritmada05", "res://scenes/actors/PlataformaRitmada.tscn", "ritm"),
    ("PackedScene", "uid://bkolianiplataquebra01", "res://scenes/actors/PlataformaQuebra.tscn", "quebra"),
    ("PackedScene", "uid://bkolianiraiotemp13", "res://scenes/actors/RaioTempestade.tscn", "raio"),
    ("Script", None, "res://scripts/fragmento_eco.gd", "fragmento"),
    ("Script", None, "res://scripts/plataforma_fase2.gd", "fase2"),
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
    # N15 -- topo dos ecos (level_mechanics.png, coluna N15)
    "f_sinos", "f_plat_dinamica", "f_ecos_memoria", "f_vento", "f_destrutiveis",
    "f_plat_final", "f_sinos_celestiais", "f_fragmentos", "f_colapso", "f_feixes",
    "f_instavel", "f_queda_vento", "f_destrocos", "m_contrapeso",
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

# ---------------------------------------------------------------- helpers N15
SUBS_EXTRA.append('[sub_resource type="CircleShape2D" id="rs_frag"]\nradius = 30.0\n')
ARENA_GRUPO = "arena"
CEU = "Color(0.62, 0.68, 1.0, 1)"


def ritmada(nome: str, esq: float, dir: float, topo: float, fase: float,
            solida: float = 2.2, fantasma: float = 1.4) -> None:
    PL[nome] = {"esq": esq, "dir": dir, "topo": topo}
    esc = (dir - esq) / TAM_TEX["f_ecos_memoria"][0] * 1.25
    no(nome, f"position = {v((esq + dir) / 2, topo + 10)}\ntamanho = {v(dir - esq, 20)}\n"
             f"altura_visual = 18\n{PEDRA}\nsolida_seg = {solida:g}\nfantasma_seg = {fantasma:g}\n"
             f"fase = {fase:g}\naviso = 0.6\ntextura_eco = {tex('f_ecos_memoria')}\n"
             f"escala_eco = {esc:.3f}", inst="ritm")


def raio(nome: str, x: float, y: float, periodo: float, fase: float, altura: float = 560.0) -> None:
    no(nome, f"position = {v(x, y)}\nautomatico = true\nperiodo = {periodo:g}\nfase = {fase:g}\n"
             f"aviso = 0.9\naltura = {altura:g}\nlargura = 54.0\ndano = 22\n"
             f"textura_feixe = {tex('f_feixes')}\ncor_feixe = Color(0.75, 0.8, 1.0, 0.85)",
       inst="raio")


def fragmento(nome: str, x: float, y: float) -> None:
    no(nome, f'position = {v(x, y)}\nscript = ExtResource("{ID["fragmento"]}")\n'
             f"textura = {tex('f_fragmentos')}\nescala_textura = 0.42", tipo="Area2D")
    no("CollisionShape2D", 'shape = SubResource("rs_frag")', tipo="CollisionShape2D", pai=nome)
    fx(f"Halo{nome}", "p_brilho_sino", x, y, esc=0.9, z=-1, mod="Color(0.6, 0.5, 1.0, 0.55)")
    luz(f"Luz{nome}", x, y, 0.6, ROXO, (0.9, 0.9))


def degrau_arena(nome: str, esq: float, dir: float, topo: float) -> None:
    """Degrau da escada de ecos: fantasma ate' o sino celestial soar."""
    PL[nome] = {"esq": esq, "dir": dir, "topo": topo}
    esc = (dir - esq) / TAM_TEX["f_instavel"][0] * 1.1
    no(nome, f"position = {v((esq + dir) / 2, topo + 11)}\ntamanho = {v(dir - esq, 22)}\n"
             f"altura_visual = 18\n{PEDRA}\ngrupo_alternar = \"{ARENA_GRUPO}\"\nalpha_fantasma = 0.22\n"
             f"textura_suporte = {tex('f_instavel')}\nescala_suporte = {esc:.3f}", inst="eco")


def final_fase2(nome: str, esq: float, dir: float, topo: float) -> None:
    """Plataforma final (multiplas fases): ergue-se no ritual de Vyrak."""
    esc = (dir - esq) / TAM_TEX["f_plat_dinamica"][0] * 1.15
    no(nome, f"position = {v((esq + dir) / 2, topo + 12)}\ntamanho = {v(dir - esq, 24)}\n"
             f"altura_visual = 20\n{PEDRA}\nalpha_fantasma = 0.24\n"
             f'script = ExtResource("{ID["fase2"]}")\n'
             f"textura_suporte = {tex('f_plat_dinamica')}\nescala_suporte = {esc:.3f}", inst="eco")


def vento_lateral(nome: str, x0: float, y0: float, x1: float, y1: float, empurrao: float,
                  vmax: float, alfa: float = 0.22) -> None:
    no(nome, f"position = {v((x0 + x1) / 2, (y0 + y1) / 2)}\n"
             f"script = ExtResource(\"{ID['vento']}\")\n"
             f"tamanho = {v(x1 - x0, y1 - y0)}\nempurrao = {empurrao:g}\nvel_max = {vmax:g}\n"
             f"pele = {tex('c_vento')}\nvel_pele = {180 if empurrao > 0 else -180}\nalfa_pele = {alfa:g}",
       tipo="Area2D")


def pedra_solta(nome: str, t: str, x: float, y: float, esc: float = 1.0, z: int = -2,
                mod: str = "Color(0.85, 0.85, 1.0, 1)") -> None:
    solto(nome, t, x, y, esc=esc, z=z, mod=mod)


def ilha_de_fundo(nome: str, x: float, y: float, esc: float = 2.0) -> None:
    """Fragmento de torre a flutuar ao longe (silhueta azul, profundidade)."""
    assente(nome, "p_torre_lateral", x, y, esc=esc, z=-13, mod=LONGE)

# ======================================================================
#  RAIZ + ATMOSFERA
# ======================================================================
no("O_Pico_Esquecido",
   f'script = ExtResource("{ID["niv"]}")\ncorredor = false\n'
   "alongar_plataformas = false\ncheckpoints_autorais = true\n"
   'mecanica_anunciada = "vento"\nestreia_x_autoral = 1400.0',
   tipo="Node2D", pai="")
nos[0] = nos[0].replace(' parent=""', "")

# os valores sao os de `tools/afinar_atmosfera.py` (linha O_Pico_Esquecido)
no("Atmosfera", """cor_ambiente = Color(0.9, 0.86, 1.04, 1)
cor_fundo = Color(0.05, 0.05, 0.14, 1)
cor_silhueta = Color(0.09, 0.09, 0.2, 1)
cor_luz = Color(0.86, 0.6, 1, 1)
cor_poeira = Color(0.92, 0.76, 1, 1)
densidade_poeira = 2.2
bioma = "torres"
largura_nivel = 3700.0
fundo_pack = "torre_ecos"
tinta_fundo = Color(0.52, 0.55, 0.95, 1)
neblina_fundo = 0.5
dessaturar_fundo = 0.3
seed_ambiente = 1518
luzes_horizonte = true""", inst="atm")

# ======================================================================
#  A) ASCENSAO FINAL
# ======================================================================
com("""
===================  A) ASCENSAO FINAL  ======================================
O terraco da base da ultima agulha da Torre dos Ecos, em plena noite. Dois
sinos em queda, uma Sentinela a cuspir, um Acolito; o FOSSO de pedras em
colapso com vento contra; o terraco da outra margem e o 1.o sino: badala-o e
acendem-se 4 degraus temporizados (7 s) ate' a' laje alta.
""")
no("Koliani", f"position = {v(150, YA - 40)}\nusar_prototipo_premium = true\n"
              "usar_golden_set = true", inst="kol")
check("CheckInicio", 300, YA)
laje("ChaoA", 0, 1250, YA, 1300)
casca("ParapeitoOeste", -70, 0, YA - 130, 1300)
fosso_x0, fosso_x1 = 1250.0, 1750.0
laje("TerracoB", fosso_x1, 2500, YA, 1300)
# o fosso: pedras em colapso sobre espinhos, com vento contra (empurra para oeste)
for i, (e, d) in enumerate([(1328, 1420), (1494, 1586), (1660, 1752)]):
    quebra(f"PedraColapso{i}", e, d, YA)
espinhos("EspinhosFosso", 1262, 1738, YA + 172)
vento_lateral("VentoFosso", fosso_x0, YA - 190, fosso_x1, YA + 10, -520, 190, alfa=0.2)
check("CheckA", 1850, YA)

queda("SinoQuedaA1", 560, YA - 330, YA)
queda("SinoQuedaA2", 1010, YA - 330, YA)
inimigo("AcolitoA", 780, YA - 50, "acolito_do_eco", "carga", 70, 16, 150,
        "Color(0.75, 0.6, 1.0, 1)")
inimigo("SentinelaA", 1130, YA - 60, "sentinela_da_torre", "cuspidor", 80, 16, 60,
        "Color(0.75, 0.75, 1.0, 1)")
inimigo("SinoFlutuanteA", 1980, YA - 300, "sino_flutuante", "voador", 50, 14, 200,
        "Color(1.0, 0.82, 0.5, 1)")

com("""O 1.o SINO acende os degraus (7 s cada badalada): 4 lances de 100 px ate'
a laje alta -- a soma (500 px) esta' muito alem do salto duplo, por isso e' um
portao a serio. O sino fica junto ao pe' da escada.""")
sino_seq("Sino1", 2400, YA - 110, "seq1", esc=0.62)
for nome, e, d, t in [("Seq1a", 2560, 2680, YA - 100), ("Seq1b", 2760, 2880, YA - 200),
                      ("Seq1c", 2960, 3080, YA - 300), ("Seq1d", 3160, 3280, YA - 400)]:
    temporizada(nome, e, d, t, "seq1", 7.0)
LAJE_B1 = YA - 500.0          # 500
plat("LajeB1", 3340, LARG, LAJE_B1, h=34)
casca("ParapeitoLeste", LARG, LARG + 60, LAJE_B1 - 120, LAJE_B1 + 300)
check("CheckB1", 3450, LAJE_B1)

# ======================================================================
#  B) PLATAFORMAS E ULTIMOS DESAFIOS
# ======================================================================
com("""
===================  B) ECOS DE MEMORIA  =====================================
Da laje alta para oeste: a cadeia dos ECOS DE MEMORIA -- seis plataformas
ilusorias que pulsam (solidas 2,2 s, fantasmas 1,4 s, desfasadas) -- sob FEIXES
DE LUZ que caem a cada duas plataformas e com vento contra. Um Arqueiro das
Sombras e uma Gargula Vitral guardam a laje alta. SEGREDO 1 por cima da cadeia.
""")
inimigo("ArqueiroB", 3520, LAJE_B1 - 130, "arqueiro_das_sombras", "voador", 55, 14, 130,
        "Color(0.8, 0.7, 1.0, 1)")
inimigo("GargulaB", 3560, LAJE_B1 - 50, "gargula_vitral", "escudeiro", 100, 18, 90,
        "Color(0.7, 0.85, 1.0, 1)", escala=1.1)
ECOS = [(3060, 3160, 480), (2840, 2940, 440), (2620, 2720, 400), (2400, 2500, 360),
        (2180, 2280, 320), (1960, 2060, 280)]
for i, (e, d, t) in enumerate(ECOS):
    ritmada(f"Eco{i + 1}", e, d, t, fase=(i * 0.21) % 1.0)
raio("FeixeB1", 2890, 440, 3.6, 0.0)
raio("FeixeB2", 2450, 360, 3.6, 1.8)
raio("FeixeB3", 2010, 280, 3.9, 0.9)
vento_lateral("VentoB", 1950, 60, 3200, 560, 420, 175, alfa=0.2)
plat("Segredo1", 2120, 2200, 170, h=22)
ess("EssenciaSegredo1", 2160, 170, 20)
assente("UrnaSegredo1", "urna", 2185, 170, esc=0.9, z=-1)
luz("LuzSegredo1", 2160, 140, 0.35, ROXO, (0.9, 0.8))

LAJE_B2 = 240.0
plat("LajeB2", 1450, 1800, LAJE_B2, h=34)
check("CheckB2", 1530, LAJE_B2)
inimigo("AutomatoB", 1680, LAJE_B2 - 55, "automato_do_sino", "escudeiro", 110, 20, 110,
        "Color(1.0, 0.78, 0.45, 1)", escala=1.1)
inimigo("EspiritoB", 1600, LAJE_B2 - 240, "espirito_do_eco", "voador", 50, 14, 200,
        "Color(0.6, 0.8, 1.0, 1)")

com("""Degraus em COLAPSO (elementos destrutiveis): quatro pedras que cedem ao
pisar e voltam ao fim de uns segundos -- nao se pode parar.""")
for i, (e, d, t) in enumerate([(1300, 1390, 170), (1140, 1230, 100), (980, 1070, 30),
                               (820, 910, -40)]):
    quebra(f"Colapso{i + 1}", e, d, t)

# ======================================================================
#  C) CAMINHO PARA A ARENA
# ======================================================================
LAJE_C1 = -110.0
plat("LajeC1", 440, 740, LAJE_C1, h=34)
check("CheckC1", 500, LAJE_C1)
inimigo("ConstrutoC", 600, LAJE_C1 - 200, "construto_vitral", "voador", 55, 14, 150,
        "Color(0.7, 0.85, 1.0, 1)")
inimigo("SentinelaC", 690, LAJE_C1 - 60, "sentinela_da_torre", "cuspidor", 80, 16, 40,
        "Color(0.75, 0.75, 1.0, 1)")
plat("Segredo2", 190, 290, LAJE_C1 - 105, h=22)
ess("EssenciaSegredo2", 230, LAJE_C1 - 105, 25)
assente("MemorialSegredo2", "pedra_memoria", 275, LAJE_C1 - 105, esc=1.0, z=-1)
luz("LuzSegredo2", 230, LAJE_C1 - 140, 0.35, ROXO, (0.9, 0.8))

ALTAR = -700.0
com("""A coluna de ar leva ao ALTAR DOS SINOS (800 px de largura), o moyeu do
fim do nivel: tres caminhos saem dele, cada um para um FRAGMENTO DE ECO.""")
ar("ArAltar", 800, 920, ALTAR + 10, LAJE_C1)
plat("Altar", 980, 1780, ALTAR, h=34)
check("CheckAltar", 1050, ALTAR)
inimigo("EspiritoAltar", 1400, ALTAR - 220, "espirito_do_eco", "voador", 50, 14, 260,
        "Color(0.6, 0.8, 1.0, 1)")
inimigo("CorvoAltar", 1200, ALTAR - 260, "corvo_do_sino", "voador", 45, 14, 260,
        "Color(0.8, 0.7, 1.0, 1)")
inimigo("MongeAltar", 1600, ALTAR - 55, "monge_das_correntes", "escudeiro", 110, 18, 100,
        "Color(1.0, 0.78, 0.45, 1)", escala=1.15)

com("""O SINO CELESTIAL: surdo ate' os tres fragmentos estarem recolhidos.
Depois, uma badalada ergue a ESCADA DE ECOS (5 degraus de 96 px) ate' ao
chao da arena -- 480 px que nem o salto duplo nem nada mais vencem.""")
no("SinoCelestial", f"position = {v(1400, ALTAR - 100)}\nalterna_grupo = \"{ARENA_GRUPO}\"\n"
                    f"textura = {tex('f_sinos_celestiais')}\nscale = {v(0.95, 0.95)}\n"
                    "fragmentos_necessarios = 3", inst="sino")
fx("BrilhoSinoCelestial", "p_brilho_sino", 1400, ALTAR - 100, esc=1.3, z=-1,
   mod="Color(0.7, 0.6, 1.0, 0.45)")
for i, (e, d, t) in enumerate([(1250, 1350, -796), (1400, 1500, -892), (1550, 1650, -988),
                               (1700, 1800, -1084)]):
    degrau_arena(f"Degrau{i + 1}", e, d, t)

com("""Os TRES FRAGMENTOS DE ECO (todos a menos de um ecra do sino; sao
recolhidos por contacto e nao persistem -- morrer volta ao altar):
  F1 norte  -- elevador de vaivem do altar ate' a plataforma N;
  F2 este   -- dois baloicos contra o vento ate' a plataforma E;
  F3 nordeste -- da plataforma E, ecos de memoria ate' a plataforma NE.""")
SAT_N = ALTAR - 130.0
elevador("ElevadorF1", 1690, 150, ALTAR, SAT_N, True, 1.0)
plat("SatN", 1840, 2100, SAT_N, h=30)
fragmento("FragmentoN", 1970, SAT_N - 54)
assente("AltarFragN", "pedra_memoria", 1970, SAT_N, esc=1.0, z=-1)
for nome, x, fase in [("BalancoE1", 1990, 0.0), ("BalancoE2", 2300, 0.5)]:
    balanco(nome, x, ALTAR + 28, 292, 26, 4.4, fase)
vento_lateral("VentoE", 1780, ALTAR - 240, 2560, ALTAR + 60, -560, 200)
plat("SatE", 2570, 2820, ALTAR, h=30)
fragmento("FragmentoE", 2690, ALTAR - 54)
assente("AltarFragE", "pedra_memoria", 2690, ALTAR, esc=1.0, z=-1)
inimigo("CorvoE", 2300, ALTAR - 330, "corvo_do_sino", "voador", 45, 14, 260,
        "Color(0.8, 0.7, 1.0, 1)")
com("""F3 -- da plataforma E, tres ECOS DE MEMORIA (plataformas ilusorias que
pulsam) e um feixe de luz ate' a plataforma NE. Tudo a mais de 330 px por
baixo do chao da arena: nenhuma face dele se alcanca a saltar.""")
SAT_NE = ALTAR - 100.0
for i, (e, d, t) in enumerate([(2870, 2970, ALTAR - 40), (3030, 3130, ALTAR - 70)]):
    ritmada(f"EcoF3_{i + 1}", e, d, t, fase=0.3 * i)
raio("FeixeF3", 3080, ALTAR - 70, 3.6, 1.2, altura=420.0)
plat("SatNE", 3190, 3450, SAT_NE, h=30)
fragmento("FragmentoNE", 3320, SAT_NE - 54)
assente("AltarFragNE", "pedra_memoria", 3320, SAT_NE, esc=1.0, z=-1)
inimigo("ArqueiroNE", 3350, SAT_NE - 130, "arqueiro_das_sombras", "voador", 55, 14, 110,
        "Color(0.8, 0.7, 1.0, 1)")
plat("Segredo3", 2590, 2670, ALTAR - 100, h=22)
ess("EssenciaSegredo3", 2630, ALTAR - 100, 30)
luz("LuzSegredo3", 2630, ALTAR - 135, 0.35, ROXO, (0.9, 0.8))

# ======================================================================
#  D) ARENA -- VYRAK
# ======================================================================
com("""
===================  D) ARENA DE VYRAK  ======================================
O cimo da agulha: um chao largo aberto ao ceu, a lua por cima. Fase 1: duas
plataformas laterais; aos 50 % o ritual de Vyrak ergue as plataformas da
fase 2 (`PlataformaFase2`). SEGREDO 4 num patamar alto do lado esquerdo.
""")
ARENA_X0, ARENA_X1 = 1810.0, 3200.0
plat("ArenaChao", ARENA_X0, ARENA_X1, YARENA, h=50, av=50)
casca("ParapeitoArena", ARENA_X1, ARENA_X1 + 60, YARENA - 220, YARENA + 50)
check("CheckArena", 1900, YARENA)
no("Chefe", f"position = {v(2500, YARENA - 120)}", inst="chefe")
no("Porta", f'position = {v(3110, YARENA + 6)}\npista_ao_atravessar = ""', inst="porta")
plat("PlatF1a", 1960, 2130, YARENA - 110, h=22)
plat("PlatF1b", 2880, 3050, YARENA - 110, h=22)
final_fase2("Fase2a", 2190, 2350, YARENA - 160)
final_fase2("Fase2b", 2650, 2810, YARENA - 160)
final_fase2("Fase2c", 2420, 2580, YARENA - 290)
plat("Segredo4", 2170, 2250, YARENA - 220, h=22)
ess("EssenciaSegredo4", 2210, YARENA - 220, 35)
luz("LuzSegredo4", 2210, YARENA - 255, 0.35, ROXO, (0.9, 0.8))
luz("LuzArena", 2500, YARENA - 160, 0.9, ROXO, (4.2, 2.4))

# ======================================================================
#  ARTE -- so' visual
# ======================================================================
ESCURO = "Color(0.3, 0.32, 0.5, 1)"
MUITO_ESCURO = "Color(0.16, 0.17, 0.3, 1)"


def veu(nome: str, x: float, y: float, ex: float, ey: float, a: float = 0.5) -> None:
    """Veu escuro e macio por tras do percurso: o fundo do pack e' vivo
    demais e as plataformas finas perdiam-se contra ele."""
    no(nome, f"position = {v(x, y)}\nscale = {v(ex, ey)}\ntexture = SubResource(\"tex_luz\")\n"
             f"z_index = -11\nmodulate = Color(0.015, 0.02, 0.09, {a:g})", tipo="Sprite2D")


def bruma(nome: str, x: float, y: float, ex: float, ey: float, a: float = 0.22,
          cor: str = "0.55, 0.6, 0.95") -> None:
    no(nome, f"position = {v(x, y)}\nscale = {v(ex, ey)}\ntexture = SubResource(\"tex_luz\")\n"
             f"z_index = 1\nmodulate = Color({cor}, {a:g})\nmaterial = SubResource(\"mat_add\")",
       tipo="Sprite2D")


def sombra_de(nome: str, esq: float, dir: float, topo: float, alt: float = 130.0) -> None:
    no(nome, f"position = {v(esq - 10, topo + 6)}\ncentered = false\n"
             f"scale = {v((dir - esq + 20) / 64.0, alt / 64.0)}\n"
             'texture = SubResource("tex_sombra")\nz_index = -1', tipo="Sprite2D")


def correntes_ao_ceu(nome: str, x0: float, x1: float, topo: float, alto: float = 620.0) -> None:
    """Duas correntes a subir da plataforma para a bruma (prendem-na ao nada,
    como nas pranchas -- a bruma engole o fim delas)."""
    for k, x in enumerate((x0, x1)):
        corrente(f"{nome}{k}", x, topo - alto, topo, z=-4, mod="Color(0.78, 0.66, 0.46, 0.9)")
    bruma(f"{nome}Bruma", (x0 + x1) / 2, topo - alto, 1.6, 0.9, a=0.3, cor="0.3, 0.36, 0.7")


def ruina_pendurada(nome: str, x: float, topo: float, esc: float = 1.1, t: str = "f_colapso",
                    mod: str = ESCURO, flip: bool = False) -> None:
    pendurado(nome, t, x, topo + 6, esc=esc, z=-2, mod=mod, flip=flip)


def base_arcadas(prefixo: str, x0: float, x1: float, topo: float, base: float,
                 passo: float = 250.0) -> None:
    """Face da laje de pedra: arcadas em baixo-relevo, escuras, com uma janela
    acesa entre duas (a torre tem vida por dentro)."""
    n = int((x1 - x0) // passo)
    for i in range(n):
        x = x0 + passo * (i + 0.5)
        assente(f"{prefixo}Arco{i}", "arco_grande", x, base - 14, esc=1.3, z=2,
                mod="Color(0.22, 0.24, 0.42, 0.85)")
        if i % 2 == 0:
            fx(f"{prefixo}Janela{i}", "p_brilho_sino", x, topo + 110, esc=0.55, z=2,
               mod="Color(1, 0.66, 0.34, 0.4)")


# -------- vazio azul-noite por tras do percurso (legibilidade das plataformas)
veu("VeuA", 1300, 780, 14, 5.0, 0.42)
veu("VeuB", 2900, 420, 14, 6.0, 0.5)
veu("VeuB2", 2000, 160, 12, 5.0, 0.5)
veu("VeuC", 900, -300, 9, 7.0, 0.5)
veu("VeuAltar", 1800, -800, 15, 7.0, 0.5)
veu("VeuArena", 2500, -1250, 14, 6.0, 0.4)

# -------- A: o terraco da base
base_arcadas("ArcaA", 0, 1250, YA, 1300)
base_arcadas("ArcaB", 1750, 2500, YA, 1300)
for i, x in enumerate(range(60, 1240, 124)):
    assente(f"BalaustradaA{i}", "balaustrada", x, YA, esc=1.0, z=-3, mod="Color(0.62, 0.64, 0.86, 1)")
for i, x in enumerate(range(1790, 2500, 124)):
    assente(f"BalaustradaB{i}", "balaustrada", x, YA, esc=1.0, z=-3, mod="Color(0.62, 0.64, 0.86, 1)")
assente("GargulaA", "gargula", 40, YA, esc=1.6, z=-2)
assente("GargulaB", "gargula", 2470, YA, esc=1.6, z=-2, flip=True)
assente("CandelabroA1", "candelabro", 330, YA, esc=1.25, z=-1)
assente("EstatuaA", "estatua_anjo", 880, YA, esc=1.7, z=-3, mod=ESCURO)
assente("ColunaQuebradaA", "f_colapso", 1215, YA, esc=1.25, z=-2, mod=ESCURO)
assente("ColunaQuebradaB", "f_colapso", 1790, YA, esc=1.25, z=-2, mod=ESCURO, flip=True)
assente("DestrocosA", "f_destrocos", 430, YA, esc=0.9, z=0)
assente("DestrocosB", "f_destrocos", 1010, YA, esc=0.8, z=0, flip=True)
assente("DestrocosC", "f_destrocos", 2180, YA, esc=0.9, z=0)
assente("TochaA1", "tocha", 620, YA, esc=1.2, z=-2)
assente("TochaA2", "tocha", 1140, YA, esc=1.2, z=-2)
assente("TochaB1", "tocha", 1960, YA, esc=1.2, z=-2)
assente("VelasB", "velas", 2300, YA, esc=1.25, z=-1)
assente("LivrosA", "livros", 240, YA, esc=1.2, z=-1)
for nome, x, y in [("Luz1", 330, YA - 90), ("Luz2", 1140, YA - 90), ("Luz3", 1960, YA - 90),
                   ("Luz4", 2330, YA - 90)]:
    luz(nome + "A", x, y, 0.5, OURO, (2.2, 1.4))
    fx("Brilho" + nome, "p_brilho_sino", x, y - 10, esc=0.8, z=-2, mod="Color(1, 0.62, 0.3, 0.42)")
# o fosso: destrocos no fundo, vento pintado
fx("VentoPintadoFosso", "f_queda_vento", 1500, YA - 60, esc=1.6, z=1, mod="Color(0.7, 0.8, 1.0, 0.3)", rot=1.5708)
assente("DestrutivelFosso", "f_destrutiveis", 1505, YA + 150, esc=1.2, z=-3, mod=ESCURO)
bruma("BrumaFosso", 1500, YA + 140, 4.6, 1.3, a=0.35)
# as pedras em colapso: nome de aviso pintado por baixo
no("AbismoFosso", f"position = {v(fosso_x0, YA + 20)}\ncentered = false\n"
                  f"scale = {v((fosso_x1 - fosso_x0) / 64.0, 280 / 64.0)}\n"
                  'texture = SubResource("tex_massa")\nz_index = -5\nmodulate = Color(0.4, 0.4, 0.6, 1)',
   tipo="Sprite2D")
# escada temporizada: sombra e bruma
for nome, e, d, t in [("Seq1a", 2560, 2680, YA - 100), ("Seq1b", 2760, 2880, YA - 200),
                      ("Seq1c", 2960, 3080, YA - 300), ("Seq1d", 3160, 3280, YA - 400)]:
    sombra_de(f"Sombra{nome}", e, d, t, 90)
bruma("BrumaEscada", 2900, YA - 60, 4.0, 1.2, a=0.26)
# o sino do pe' da escada e o seu altar
assente("PedraSino1", "pedra_memoria", 2360, YA, esc=1.0, z=-1)
corrente("CorrenteSino1", 2400, YA - 430, YA - 160, z=-4)
fx("BrilhoSino1Luz", "p_brilho_sino", 2400, YA - 110, esc=1.1, z=-2, mod="Color(1, 0.82, 0.55, 0.5)")

# -------- B: laje alta e ecos
correntes_ao_ceu("CeuB1", 3380, 3660, LAJE_B1)
sombra_de("SombraLajeB1", 3340, LARG, LAJE_B1, 150)
ruina_pendurada("RuinaB1", 3500, LAJE_B1 + 30, esc=1.4)
assente("CandelabroB1", "candelabro", 3640, LAJE_B1, esc=1.2, z=-1)
assente("GargulaB1", "gargula", 3350, LAJE_B1, esc=1.4, z=-2)
luz("LuzB1", 3500, LAJE_B1 - 90, 0.5, OURO, (2.0, 1.3))
for i, (e, d, t) in enumerate(ECOS):
    sombra_de(f"SombraEco{i}", e, d, t, 70)
    corrente(f"CorrenteEco{i}", (e + d) / 2, t - 420 - (i % 2) * 120, t, z=-4,
             mod="Color(0.6, 0.55, 0.85, 0.75)")
    luz(f"LuzEco{i}", (e + d) / 2, t + 40, 0.45, ROXO, (0.9, 0.7))
bruma("BrumaEcos", 2500, 120, 9.0, 1.6, a=0.22, cor="0.45, 0.4, 0.9")
for i, x in enumerate([3020, 2600, 2180]):
    fx(f"VentoPintadoB{i}", "f_vento", x, 250 - i * 20, esc=1.4, z=1, mod="Color(0.7, 0.8, 1.0, 0.3)")
for i, (nome, x, t) in enumerate([("FeixeMarca1", 2890, 440), ("FeixeMarca2", 2450, 360),
                                  ("FeixeMarca3", 2010, 280)]):
    fx(f"Rastro{nome}", "p_brilho_sino", x, t - 4, esc=0.5, z=-1, mod="Color(0.7, 0.8, 1.0, 0.35)")
sombra_de("SombraSegredo1", 2120, 2200, 170, 60)
correntes_ao_ceu("CeuB2", 1480, 1770, LAJE_B2, 560)
sombra_de("SombraLajeB2", 1450, 1800, LAJE_B2, 150)
ruina_pendurada("RuinaB2", 1630, LAJE_B2 + 30, esc=1.5)
assente("CandelabroB2", "candelabro", 1470, LAJE_B2, esc=1.2, z=-1)
assente("UrnaB2", "urna", 1770, LAJE_B2, esc=1.0, z=-1)
luz("LuzB2", 1625, LAJE_B2 - 90, 0.5, OURO, (2.0, 1.3))
for i, (e, d, t) in enumerate([(1300, 1390, 170), (1140, 1230, 100), (980, 1070, 30), (820, 910, -40)]):
    assente(f"EscombroColapso{i}", "f_destrocos", (e + d) / 2, t, esc=0.5, z=0)
    sombra_de(f"SombraColapso{i}", e, d, t, 60)

# -------- C: laje de baixo, coluna de ar e o altar
correntes_ao_ceu("CeuC1", 470, 710, LAJE_C1, 600)
sombra_de("SombraLajeC1", 440, 740, LAJE_C1, 150)
ruina_pendurada("RuinaC1", 590, LAJE_C1 + 30, esc=1.4, flip=True)
assente("UrnaC1", "urna", 450, LAJE_C1, esc=1.0, z=-1)
luz("LuzC1", 590, LAJE_C1 - 90, 0.5, OURO, (2.0, 1.3))
sombra_de("SombraSegredo2", 190, 290, LAJE_C1 - 105, 60)
fx("VentoPintadoAltar", "f_vento", 860, -400, esc=2.6, z=1, mod="Color(0.7, 0.8, 1.0, 0.3)")
bruma("BrumaAltar", 860, -300, 2.2, 3.0, a=0.15)
# o altar dos sinos: a plataforma final pendurada por baixo, correntes e sinos
pendurado("AltarEstrutura", "f_plat_final", 1380, ALTAR + 22, esc=2.0, z=-1, mod="Color(0.85, 0.85, 1.0, 1)")
sombra_de("SombraAltar", 980, 1780, ALTAR, 130)
for k, x in enumerate([1010, 1270, 1490, 1750]):
    corrente(f"CorrenteAltar{k}", x, ALTAR - 780 - (k % 2) * 100, ALTAR, z=-4)
bruma("BrumaAltarTopo", 1380, ALTAR - 780, 7.0, 1.2, a=0.3, cor="0.3, 0.36, 0.7")
for k, (x, e, a) in enumerate([(1180, 0.95, 4.0), (1600, 1.0, 5.0)]):
    corrente(f"CorrenteSinoAltar{k}", x, ALTAR - 440, ALTAR - 350, z=-5, mod="Color(0.6, 0.5, 0.34, 0.9)")
    sino_balanca(f"SinoAltar{k}", "sino_g", x, ALTAR - 350, e, a, 4.4 + k, 0.2 * k, z=-5,
                 mod="Color(0.6, 0.56, 0.68, 1)")
assente("CandelabroAltar1", "candelabro", 1030, ALTAR, esc=1.3, z=-1)
assente("CandelabroAltar2", "candelabro", 1740, ALTAR, esc=1.3, z=-1)
assente("EstatuaAltar", "estatua_anjo", 1160, ALTAR, esc=1.6, z=-3, mod=ESCURO)
luz("LuzAltar", 1400, ALTAR - 120, 0.9, ROXO, (3.4, 2.0))
luz("LuzAltarOuro", 1100, ALTAR - 90, 0.5, OURO, (2.0, 1.3))
# satelites
for nome, e, d, t in [("SatN", 1840, 2100, SAT_N), ("SatE", 2570, 2820, ALTAR),
                      ("SatNE", 3190, 3450, SAT_NE)]:
    sombra_de(f"Sombra{nome}", e, d, t, 100)
    ruina_pendurada(f"Ruina{nome}", (e + d) / 2, t + 30, esc=1.1, flip=(nome == "SatE"))
    correntes_ao_ceu(f"Ceu{nome}", e + 25, d - 25, t, 480)
    luz(f"Luz{nome}", (e + d) / 2, t - 60, 0.45, ROXO, (1.3, 1.0))
bruma("BrumaE", 2300, ALTAR - 40, 6.0, 1.6, a=0.22)
sombra_de("SombraSegredo3", 2590, 2670, ALTAR - 100, 60)
for i, (e, d, t) in enumerate([(2870, 2970, ALTAR - 40), (3030, 3130, ALTAR - 70)]):
    sombra_de(f"SombraEcoF3{i}", e, d, t, 70)
    luz(f"LuzEcoF3{i}", (e + d) / 2, t + 40, 0.45, ROXO, (0.9, 0.7))

# -------- D: a arena
LUA_X, LUA_Y = 2500.0, YARENA - 820.0
no("LuaDisco", f"position = {v(LUA_X, LUA_Y)}\nscale = {v(1.5, 1.5)}\ntexture = SubResource(\"tex_lua\")\n"
               "z_index = -12\nmodulate = Color(0.82, 0.88, 1.0, 0.95)", tipo="Sprite2D")
no("LuaHalo", f"position = {v(LUA_X, LUA_Y)}\nscale = {v(9, 9)}\ntexture = SubResource(\"tex_luz\")\n"
              "z_index = -12\nmodulate = Color(0.55, 0.5, 1.0, 0.42)\nmaterial = SubResource(\"mat_add\")",
   tipo="Sprite2D")
no("LuaRaios", f"position = {v(LUA_X, LUA_Y + 130)}\nscale = {v(3.4, 3.4)}\ntexture = {tex('p_raios_luz')}\n"
               "z_index = -11\nmodulate = Color(0.6, 0.7, 1.0, 0.35)\nmaterial = SubResource(\"mat_add\")",
   tipo="Sprite2D")
# as ruinas da agulha: arcos e pilares a emoldurar o ceu
for i, x in enumerate([1900, 2500, 3100]):
    assente(f"ArcoArena{i}", "arco_grande", x, YARENA, esc=3.6, z=-10, mod="Color(0.34, 0.36, 0.6, 1)")
for i, x in enumerate([1830, 2200, 2800, 3180]):
    mosaico(f"PilarArena{i}", "p_parede", x - 34, YARENA - 760, x + 34, YARENA, esc=1.1, z=-9,
            mod="Color(0.34, 0.34, 0.54, 1)")
    pendurado(f"RemateArena{i}", "p_suporte", x, YARENA - 790, esc=1.05, z=-8, mod=PILAR)
for i, x in enumerate([2080, 2920]):
    pendurado(f"VitralArena{i}", "vitral_alto", x, YARENA - 560, esc=2.6, z=-10,
              mod="Color(0.75, 0.8, 1, 0.95)")
    fx(f"RaiosVitralArena{i}", "p_raios_luz", x + 40, YARENA - 150, esc=1.8, z=-9,
       mod="Color(0.62, 0.74, 1, 0.3)")
assente("EstatuaArenaE", "estatua_anjo", 1900, YARENA, esc=2.0, z=-3, mod=ESCURO)
assente("EstatuaArenaD", "estatua_anjo", 3130, YARENA, esc=2.0, z=-3, mod=ESCURO, flip=True)
assente("CandelabroArena1", "candelabro", 2000, YARENA, esc=1.5, z=-2)
assente("CandelabroArena2", "candelabro", 3000, YARENA, esc=1.5, z=-2)
for i, x in enumerate([2260, 2740]):
    sino_balanca(f"SinoArena{i}", "sino_g", x, YARENA - 690, 1.4, 3.0, 5.6 + i, 0.3 * i, z=-8,
                 mod="Color(0.6, 0.56, 0.68, 1)")
    corrente(f"CorrenteSinoArena{i}", x, YARENA - 980, YARENA - 690, z=-9, mod="Color(0.7, 0.56, 0.36, 0.9)")
pendurado("ChaoArenaEstrutura", "f_plat_final", 2520, YARENA + 40, esc=2.8, z=-2, mod="Color(0.82, 0.82, 1.0, 1)")
sombra_de("SombraArena", ARENA_X0, ARENA_X1, YARENA, 170)
for k, x in enumerate([1900, 2250, 2800, 3150]):
    corrente(f"CorrenteArena{k}", x, YARENA + 60, YARENA + 520, z=-4, mod="Color(0.7, 0.58, 0.4, 0.8)")
    ruina_pendurada(f"RuinaArena{k}", x, YARENA + 60, esc=0.9, flip=(k % 2 == 1))
bruma("BrumaArenaBaixo", 2500, YARENA + 260, 7.0, 1.6, a=0.32, cor="0.3, 0.36, 0.7")
bruma("BrumaArena", 2500, YARENA - 40, 8.0, 0.8, a=0.16, cor="0.55, 0.45, 1.0")
no("CirculoRuna", f"position = {v(2500, YARENA - 3)}\nscale = {v(9.5, 0.45)}\ntexture = SubResource(\"tex_luz\")\n"
                  "z_index = 0\nmodulate = Color(0.6, 0.45, 1.0, 0.45)\nmaterial = SubResource(\"mat_add\")",
   tipo="Sprite2D")
for nome, e, d, t in [("PlatF1a", 1960, 2130, YARENA - 110), ("PlatF1b", 2880, 3050, YARENA - 110),
                      ("Segredo4", 2170, 2250, YARENA - 220)]:
    sombra_de(f"Sombra{nome}", e, d, t, 70)
assente("DestrocosArena1", "f_destrocos", 1990, YARENA, esc=0.9, z=0)
assente("DestrocosArena2", "f_destrocos", 3090, YARENA, esc=0.8, z=0, flip=True)
luz("LuzArenaEsq", 1950, YARENA - 100, 0.5, OURO, (2.4, 1.4))
luz("LuzArenaDir", 3050, YARENA - 100, 0.5, OURO, (2.4, 1.4))
luz("LuzLua", LUA_X, LUA_Y, 0.6, LUA, (5.0, 3.0))

# -------- silhuetas de torres ao longe, a varias alturas
for i, (x, y, e, t) in enumerate([(200, 1000, 3.0, "p_torre_lateral"), (1000, 1000, 2.6, "p_estrutura_vertical"),
                                  (2000, 1000, 3.4, "p_torre_lateral"), (2900, 1000, 2.8, "p_estrutura_vertical"),
                                  (3500, 520, 3.0, "p_torre_lateral"), (700, 300, 2.6, "p_estrutura_vertical"),
                                  (2400, 560, 2.6, "p_estrutura_vertical"), (250, -400, 3.0, "p_torre_lateral"),
                                  (1500, -300, 2.8, "p_estrutura_vertical"), (3400, -300, 3.2, "p_torre_lateral"),
                                  (800, -1000, 2.8, "p_estrutura_vertical"), (3500, -900, 3.0, "p_estrutura_vertical"),
                                  (500, -1300, 3.4, "p_torre_lateral")]):
    assente(f"AgulhaLonge{i}", t, x, y, esc=e, z=-13, mod=LONGE)
for nome, x, y, e in [("NeblinaC", 600, -150, 3.0), ("NeblinaB", 3200, 300, 3.4),
                      ("NeblinaA", 2000, 1100, 4.0), ("NeblinaTopo", 1500, -1000, 3.6)]:
    bruma(nome, x, y, e * 0.36, e * 0.12, a=0.2)
com("""Primeiro plano: correntes em silhueta, quase pretas, a' frente da Koliani.""")
for nome, x, y0, y1 in [("FrenteA", 160, YA - 900, YA - 200), ("FrenteB", 2560, YA - 820, YA - 380),
                        ("FrenteC", 3390, -300, 100), ("FrenteD", 700, -1100, -500),
                        ("FrenteE", 3250, YARENA - 900, YARENA - 400)]:
    corrente(nome, x, y0, y1, z=6, mod=FRENTE)
    corrente(nome + "b", x + 26, y0, y1 - 70, z=6, mod=FRENTE)

# ---------------------------------------------------------------- escrever
corpo_nos = "\n".join(nos)
linhas_ext = [l for l in linhas_ext if 'ExtResource("%s")' % l.split(' id="')[1][:-2] in corpo_nos]
cab = f'[gd_scene load_steps={len(linhas_ext) + 13 + len(SUBS_EXTRA)} format=3 uid="uid://bkolianipico15"]'
topo = """
; REGIAO III / nivel 15 -- O TOPO DOS ECOS (`level.n14`), "A Verdade".
; O nome do ficheiro fica: muda-lo partia saves e checkpoints.
;
; GERADO por `tools/construir_n15_topo.py` -- editar la', nao aqui.
; Desenho, medicoes e o que ficou por decidir: `docs/nivel_autoral_n15.md`.
;
; Nivel AUTORAL (`corredor = false`), ao ar livre:
;   A) Ascensao final   -- pedras em colapso sobre o fosso, sinos em queda,
;                          o 1.o sino e os degraus temporizados;
;   B) Ecos de memoria  -- plataformas que pulsam sob feixes de luz, vento;
;   C) Caminho p/ arena -- altar dos sinos, 3 fragmentos de eco, sino
;                          celestial e escada de ecos;
;   D) Arena            -- VYRAK, A VOZ DOS ECOS (chefe final da regiao).
; 4 segredos, 7 checkpoints; inimigos: todos os da regiao.
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

[sub_resource type="Gradient" id="grad_lua"]
offsets = PackedFloat32Array(0, 0.9, 1)
colors = PackedColorArray(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0)

[sub_resource type="GradientTexture2D" id="tex_lua"]
gradient = SubResource("grad_lua")
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
