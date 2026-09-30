#!/usr/bin/env python3
"""Biblioteca dos construtores dos niveis da Regiao IV (Fornalha, N16-N20).

Mesmo metodo dos `construir_n1X_*.py` da Regiao III (cena AUTORAL escrita por
codigo: cada plataforma e' dada pelo TOPO e pelas bordas, que e' como o crivo
de alcance e o jogador a leem), mas com o boilerplate -- recursos externos,
nos, plataformas, inimigos, props assentes, luzes -- arrumado aqui para os
cinco niveis o partilharem. Cada `construir_nXX_*.py` so' descreve o nivel.

Uso:
    from r4_lib import Cena
    c = Cena("Cemiterio_dos_Reis", "uid://...", DY=0)
    c.plat("ChaoA", 0, 900, 600, h=60)
    ...
    c.escrever(cabecalho="...")
"""
from __future__ import annotations

import os
import re

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DECO = "assets/sprites/pixel/deco/fornalha"

# Paleta de cores (prancha): laranja, vermelho, preto, metal queimado.
BRASA = "Color(1.0, 0.52, 0.16, 1)"
OURO = "Color(1.0, 0.74, 0.36, 1)"
LAVA = "Color(1.0, 0.36, 0.1, 1)"
METAL = "Color(0.52, 0.5, 0.6, 1)"
PEDRA = "cor_base = Color(0.2, 0.16, 0.16, 1)\ncor_topo = Color(0.42, 0.3, 0.26, 1)"

ATORES = {
    "kol": "Koliani", "dem": "DemonioBase", "porta": "Porta",
    "atm": None, "pl": "Plataforma", "ess": "Essencia",
    "quebra": "PlataformaQuebra", "ritmo": "PlataformaRitmada",
    "corr": "PlataformaCorrente", "flut": "PlataformaFlutuante",
    "peso": "PlataformaPeso", "elev": "TumuloElevador",
    "serra": "Serra", "pend": "PenduloLamina", "alavanca": "Alavanca",
    "porta_tr": "PortaTrancada", "vento": "WindZone", "ar": "CorrenteAr",
    "impulsor": "Impulsor", "parede_frag": "ParedeFragil",
    "pedra_queda": "PedraQueda", "coletavel": "Coletavel",
}


def _uid_cena(caminho: str) -> str | None:
    try:
        with open(os.path.join(RAIZ, caminho), encoding="utf-8") as f:
            m = re.search(r'uid="(uid://[^"]+)"', f.readline())
            return m.group(1) if m else None
    except OSError:
        return None


def _tam_png(caminho: str) -> tuple[int, int]:
    with open(os.path.join(RAIZ, caminho), "rb") as f:
        cab = f.read(24)
    return int.from_bytes(cab[16:20], "big"), int.from_bytes(cab[20:24], "big")


def v(x: float, y: float) -> str:
    return f"Vector2({x:g}, {y:g})"


class Cena:
    def __init__(self, nome: str, uid: str, dy: float = 0.0) -> None:
        self.nome, self.uid, self.dy = nome, uid, dy
        self.ext: dict[str, tuple] = {}
        self.ordem: list[str] = []
        self.nos: list[str] = []
        self.PL: dict[str, dict] = {}
        self._tam: dict[str, tuple] = {}
        self._n_luz = 0

    # ------------------------------------------------------------ recursos
    def _ext(self, chave: str, tipo: str, caminho: str, uid: str | None = None) -> str:
        if chave not in self.ext:
            self.ext[chave] = (tipo, caminho, uid)
            self.ordem.append(chave)
        return f"{len(self.ordem) and self.ordem.index(chave) + 1}_{chave}"

    def ator(self, chave: str) -> str:
        nome = ATORES[chave]
        cam = f"res://scenes/actors/{nome}.tscn"
        return self._ext("a_" + chave, "PackedScene", cam, _uid_cena(cam[6:]))

    def cena(self, caminho_res: str) -> str:
        return self._ext("c_" + os.path.basename(caminho_res), "PackedScene",
                         caminho_res, _uid_cena(caminho_res[6:]))

    def script(self, caminho_res: str) -> str:
        return self._ext("s_" + os.path.basename(caminho_res), "Script", caminho_res)

    def tex(self, nome: str) -> str:
        """Textura do kit da Fornalha (`r4_*.png`) -> id de recurso."""
        cam = f"{DECO}/{nome}.png"
        self._tam[nome] = _tam_png(cam)
        return self._ext("t_" + nome, "Texture2D", "res://" + cam)

    def tam(self, nome: str) -> tuple[int, int]:
        self.tex(nome)
        return self._tam[nome]

    def tex_res(self, caminho_res: str) -> str:
        return self._ext("tr_" + os.path.basename(caminho_res), "Texture2D", caminho_res)

    # --------------------------------------------------------------- nos
    def com(self, texto: str) -> None:
        for l in texto.strip("\n").split("\n"):
            self.nos.append("; " + l if l else ";")

    def no(self, nome: str, corpo: str = "", tipo: str | None = None,
           inst: str | None = None, pai: str = ".") -> None:
        cab = f'[node name="{nome}"'
        if tipo:
            cab += f' type="{tipo}"'
        cab += f' parent="{pai}"'
        if inst:
            cab += f' instance=ExtResource("{inst}")'
        cab += "]"
        self.nos.append(cab)
        if corpo:
            self.nos.append(corpo.strip("\n"))
        self.nos.append("")

    def com_script(self, nome: str, tipo: str, script_res: str, corpo: str = "") -> None:
        """No' de codigo puro (Area2D/Node2D) com um script das mecanicas novas."""
        # o `script` TEM de vir antes das propriedades do script: lidas antes,
        # o Godot larga-as em silencio (o no' ainda e' um Area2D simples)
        self.no(nome, f'script = ExtResource("{self.script(script_res)}")\n{corpo.strip()}',
                tipo=tipo)

    def piso_quente(self, nome: str, x: float, topo: float, larg: float, frio: float = 2.4,
                    aviso: float = 1.0, quente: float = 1.6, fase: float = 0.0) -> None:
        self.com_script(nome, "Area2D", "res://scripts/piso_quente.gd",
                        f"position = {v(x, topo)}\nlargura = {larg:g}\nfrio_seg = {frio:g}\n"
                        f"aviso_seg = {aviso:g}\nquente_seg = {quente:g}\nfase = {fase:g}\n"
                        f'textura_brilho = ExtResource("{self.tex("r4_piso_quente")}")')

    def jato(self, nome: str, x: float, y: float, alcance: float = 220.0, intervalo: float = 2.2,
             aviso: float = 0.8, dur: float = 1.4, fase: float = 0.0, invertido: bool = False) -> None:
        self.com_script(nome, "Area2D", "res://scripts/jato_fornalha.gd",
                        f"position = {v(x, y)}\nalcance = {alcance:g}\nintervalo = {intervalo:g}\n"
                        f"aviso_seg = {aviso:g}\ndur_ativa = {dur:g}\nfase = {fase:g}\n"
                        f"invertido = {str(invertido).lower()}\n"
                        f'textura_jato = ExtResource("{self.tex("r4_jato_fogo")}")\n'
                        f'textura_bocal = ExtResource("{self.tex("r4_piso_quente")}")')

    def lava(self, nome: str, esq: float, dir: float, topo: float, prof: float = 80.0,
             letal: bool = False, dano: int = 22) -> None:
        """Poca de lava: `topo` = linha da superficie; `prof` = altura."""
        self.no(nome, f"position = {v((esq + dir) / 2, topo + prof / 2)}\nlargura = {dir - esq:g}\n"
                      f"altura = {prof:g}\ncor = Color(1.0, 0.34, 0.08, 0.93)\nbrasas = true\n"
                      f"letal = {str(letal).lower()}\ndano_lava = {dano}\n"
                      f'textura_lava = ExtResource("{self.tex("r4_lava_estatica")}")\n'
                      "z_index = -1",
                inst=self.ator_lava())

    def ator_lava(self) -> str:
        """`AguaVenenosa.tscn` com o script `LavaFornalha` por cima (como o
        `ElevadorColuna` faz com o `TumuloElevador`)."""
        return self.cena("res://scenes/actors/LavaFornalha.tscn")

    # ---------------------------------------------------------- geometria
    def plat(self, nome: str, esq: float, dir: float, topo: float, h: float = 22.0,
             av: float | None = None, inst: str = "pl", extra: str = "") -> None:
        cx, cy = (esq + dir) / 2.0, topo + h / 2.0
        self.PL[nome] = {"esq": esq, "dir": dir, "topo": topo}
        if av is None:
            av = 34.0 if h <= 30 else 0.0
        corpo = f"position = {v(cx, cy)}\ntamanho = {v(dir - esq, h)}"
        if inst in ("pl", "ritmo"):
            corpo += f"\naltura_visual = {av:g}\n{PEDRA}"
        if extra:
            corpo += "\n" + extra
        self.no(nome, corpo, inst=self.ator(inst))

    def quebra(self, nome: str, esq: float, dir: float, topo: float,
               atraso: float = 0.6, respawn: float = 2.6) -> None:
        self.PL[nome] = {"esq": esq, "dir": dir, "topo": topo}
        self.no(nome, f"position = {v((esq + dir) / 2, topo + 9)}\ntamanho = {v(dir - esq, 18)}\n"
                      f"atraso = {atraso:g}\nrespawn = {respawn:g}\npele_terreno = true",
                inst=self.ator("quebra"))

    def ess(self, nome: str, x: float, topo: float, valor: int) -> None:
        self.no(nome, f"position = {v(x, topo - 36)}\nvalor = {valor}", inst=self.ator("ess"))

    def check(self, nome: str, x: float, topo: float) -> None:
        self.no(nome, f"position = {v(x, topo - 34)}\ncollision_layer = 16\ncollision_mask = 2\n"
                      f'script = ExtResource("{self.script("res://scripts/checkpoint.gd")}")',
                tipo="Area2D")
        self.no("CollisionShape2D", 'shape = SubResource("rs_chk")', tipo="CollisionShape2D", pai=nome)

    def inimigo(self, nome: str, x: float, y: float, especie: str, comp: str, vida: int,
                dano: int, patrulha: float, rim: str = BRASA, elite: bool = False,
                escala: float = 1.0, extra: str = "") -> None:
        c = f"position = {v(x, y)}\n"
        if escala != 1.0:
            c += f"scale = {v(escala, escala)}\n"
        if elite:
            c += "elite = true\n"
        c += (f'especie = "{especie}"\nvida = {vida}\ndano_contacto = {dano}\n'
              f'comportamento = "{comp}"\nalcance_patrulha = {patrulha:g}\ncor_rim = {rim}')
        if extra:
            c += "\n" + extra
        self.no(nome, c, inst=self.ator("dem"))

    # ------------------------------------------------------------- props
    def assente(self, nome: str, tex: str, x: float, base_y: float, esc: float = 1.0,
                z: int = -2, mod: str = "", flip: bool = False) -> None:
        """Prop assente: `base_y` = topo da superficie onde pousa."""
        h = self.tam(tex)[1] * esc
        c = (f"position = {v(x, base_y - h / 2.0 + 2.0)}\nscale = {v(esc, esc)}\n"
             f'texture = ExtResource("{self.tex(tex)}")\nz_index = {z}')
        if flip:
            c += "\nflip_h = true"
        if mod:
            c += f"\nmodulate = {mod}"
        self.no(nome, c, tipo="Sprite2D")

    def pendurado(self, nome: str, tex: str, x: float, topo_y: float, esc: float = 1.0,
                  z: int = -2, mod: str = "") -> None:
        h = self.tam(tex)[1] * esc
        c = (f"position = {v(x, topo_y + h / 2.0)}\nscale = {v(esc, esc)}\n"
             f'texture = ExtResource("{self.tex(tex)}")\nz_index = {z}')
        if mod:
            c += f"\nmodulate = {mod}"
        self.no(nome, c, tipo="Sprite2D")

    def corrente(self, nome: str, x: float, y0: float, y1: float, z: int = -3,
                 mod: str = "Color(0.9, 0.62, 0.4, 0.9)", esc: float = 0.22) -> None:
        """Corrente a pender de `y0` ate' `y1` (mosaico vertical do elo da prancha)."""
        w, h = self.tam("r4_corrente")
        comp = (y1 - y0) / esc
        c = (f"position = {v(x - w * esc / 2, y0)}\nscale = {v(esc, esc)}\ntexture_repeat = 2\n"
             f'texture = ExtResource("{self.tex("r4_corrente")}")\ncentered = false\n'
             f"region_enabled = true\nregion_rect = Rect2(0, 0, {w}, {comp:g})\n"
             f"z_index = {z}\nmodulate = {mod}")
        self.no(nome, c, tipo="Sprite2D")

    def luz(self, nome: str, x: float, y: float, energia: float, cor: str, esc: tuple,
            pai: str = ".") -> None:
        self._n_luz += 1
        self.no(nome, f'position = {v(x, y)}\ntexture = SubResource("tex_luz")\n'
                      f"energy = {energia:g}\ncolor = {cor}\nscale = {v(*esc)}",
                tipo="PointLight2D", pai=pai)

    def mosaico(self, nome: str, tex: str, x0: float, y0: float, x1: float, y1: float,
                esc: float = 1.0, z: int = -9, mod: str = "", add: bool = False) -> None:
        w, h = (x1 - x0) / esc, (y1 - y0) / esc
        c = (f"position = {v(x0, y0)}\nscale = {v(esc, esc)}\ncentered = false\n"
             f'texture = ExtResource("{self.tex(tex)}")\ntexture_repeat = 2\n'
             f"region_enabled = true\nregion_rect = Rect2(0, 0, {w:g}, {h:g})\nz_index = {z}")
        if mod:
            c += f"\nmodulate = {mod}"
        if add:
            c += '\nmaterial = SubResource("mat_add")'
        self.no(nome, c, tipo="Sprite2D")

    def fx(self, nome: str, tex: str, x: float, y: float, esc: float = 1.0, z: int = 2,
           mod: str = "Color(1, 1, 1, 0.8)", rot: float = 0.0, sx: float | None = None) -> None:
        """Pintura de luz (brasas, jato, lava) em blend ADD."""
        c = (f"position = {v(x, y)}\nscale = {v(sx if sx is not None else esc, esc)}\n"
             f'texture = ExtResource("{self.tex(tex)}")\nz_index = {z}\nmodulate = {mod}\n'
             'material = SubResource("mat_add")')
        if rot:
            c += f"\nrotation = {rot:g}"
        self.no(nome, c, tipo="Sprite2D")

    def brasas(self, nome: str, x: float, y: float, larg: float, n: int = 22, z: int = 3) -> None:
        """Fagulhas a subir de uma linha (chao quente, forno, lava)."""
        self.no(nome, f"position = {v(x, y)}\nz_index = {z}\namount = {n}\nlifetime = 2.2\n"
                      "preprocess = 2.0\nlocal_coords = false\nemission_shape = 3\n"
                      f"emission_rect_extents = Vector2({larg / 2:g}, 4)\n"
                      "direction = Vector2(0, -1)\nspread = 22.0\ngravity = Vector2(0, -34)\n"
                      "initial_velocity_min = 20.0\ninitial_velocity_max = 70.0\n"
                      "scale_amount_min = 1.6\nscale_amount_max = 3.6\n"
                      'color_ramp = SubResource("ramp_brasa")', tipo="CPUParticles2D")

    def fumo(self, nome: str, x: float, y: float, larg: float, n: int = 12, z: int = 1) -> None:
        self.no(nome, f"position = {v(x, y)}\nz_index = {z}\namount = {n}\nlifetime = 4.0\n"
                      "preprocess = 4.0\nlocal_coords = false\nemission_shape = 3\n"
                      f"emission_rect_extents = Vector2({larg / 2:g}, 4)\n"
                      "direction = Vector2(0, -1)\nspread = 14.0\ngravity = Vector2(6, -14)\n"
                      "initial_velocity_min = 8.0\ninitial_velocity_max = 24.0\n"
                      "scale_amount_min = 9.0\nscale_amount_max = 20.0\n"
                      'color_ramp = SubResource("ramp_fumo")', tipo="CPUParticles2D")

    # ---------------------------------------------------------- escrita
    def escrever(self, saida: str, cabecalho: str) -> None:
        dy = self.dy
        if dy:
            def desl(linha: str) -> str:
                if linha.startswith("position = Vector2("):
                    x, y = linha[len("position = Vector2("):-1].split(",")
                    return f"position = Vector2({float(x):g}, {float(y) + dy:g})"
                return linha
            self.nos = ["\n".join(desl(x) for x in l.split("\n")) for l in self.nos]
        corpo = "\n".join(self.nos)
        ids: dict[str, str] = {}
        for i, ch in enumerate(self.ordem, start=1):
            ids[ch] = f"{i}_{ch}"
        linhas = []
        for ch in self.ordem:
            tipo, cam, uid = self.ext[ch]
            if f'ExtResource("{ids[ch]}")' not in corpo:
                continue
            u = f' uid="{uid}"' if uid else ""
            linhas.append(f'[ext_resource type="{tipo}"{u} path="{cam}" id="{ids[ch]}"]')
        cab = f'[gd_scene load_steps={len(linhas) + 6} format=3 uid="{self.uid}"]'
        subs = '''
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

[sub_resource type="Gradient" id="ramp_brasa"]
offsets = PackedFloat32Array(0, 0.4, 1)
colors = PackedColorArray(1, 0.9, 0.45, 0, 1, 0.5, 0.14, 0.95, 0.5, 0.1, 0.04, 0)

[sub_resource type="Gradient" id="ramp_fumo"]
offsets = PackedFloat32Array(0, 0.3, 1)
colors = PackedColorArray(0.2, 0.17, 0.17, 0, 0.26, 0.2, 0.2, 0.28, 0.12, 0.1, 0.1, 0)
'''
        with open(saida, "w", encoding="utf-8", newline="\n") as f:
            f.write(cab + "\n" + cabecalho + "\n" + "\n".join(linhas) + "\n" + subs + "\n"
                    + corpo.rstrip() + "\n")
        print("escrito", saida, "--", sum(1 for n in self.nos if n.startswith("[node")), "nos")
