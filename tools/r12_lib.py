#!/usr/bin/env python3
"""Biblioteca dos construtores dos niveis da Regiao XII (Terras Envenenadas, N56-N60).

Mesmo metodo dos `construir_n1X_*.py` das Regioes III e IV (cena AUTORAL escrita
por codigo): reutiliza o `Cena` de `r4_lib.py` (plataformas pelo TOPO, props
assentes, luzes, inimigos) e muda so' a pasta do kit de arte
(`deco/terras_envenenadas`, `r12_*.png`) e acrescenta as mecanicas da regiao
(solo toxico, nuvem de veneno, zona limpa, respiro da praga).

Uso:
    from r12_lib import Cena, v, VERDE, ...
"""
from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import r4_lib  # noqa: E402
from r4_lib import RAIZ, v  # noqa: E402,F401

r4_lib.DECO = "assets/sprites/pixel/deco/terras_envenenadas"

VERDE = "Color(0.55, 1.0, 0.3, 1)"        # veneno
VENENO = "Color(0.62, 1.0, 0.4, 1)"
SOMBRA = "Color(0.52, 0.56, 0.5, 1)"      # o que recua no cenario
FERRUGEM = "Color(0.72, 0.5, 0.3, 1)"
LUZ_VENENO = "Color(0.55, 1.0, 0.35, 1)"
LUZ_FOGO = "Color(1.0, 0.55, 0.25, 1)"
LUZ_LIMPA = "Color(0.55, 1.0, 0.9, 1)"
RIM_VERDE = "Color(0.55, 1.0, 0.35, 1)"
PEDRA_TERRA = "cor_base = Color(0.2, 0.16, 0.12, 1)\ncor_topo = Color(0.4, 0.5, 0.2, 1)"
r4_lib.PEDRA = PEDRA_TERRA


class Cena(r4_lib.Cena):
    # -------------------------------------------------------- mecanicas
    def solo_toxico(self, nome: str, esq: float, dir: float, topo: float,
                    veneno: float = 2.4, dano: int = 2, forca: float = 1.0) -> None:
        """Faixa de solo contaminado POR CIMA de um chao: `topo` = linha do chao."""
        self.com_script(nome, "Area2D", "res://scripts/solo_toxico.gd",
                        f"position = {v((esq + dir) / 2, topo)}\nmodo = \"solo\"\nlargura = {dir - esq:g}\n"
                        f"veneno_seg = {veneno:g}\nveneno_dano = {dano}\nforca = {forca:g}\n"
                        f'textura = ExtResource("{self.tex("r12_poca_toxica")}")')

    def nuvem(self, nome: str, x: float, y: float, larg: float = 220.0, alt: float = 110.0,
              amplitude: float = 120.0, periodo: float = 6.0, fase: float = 0.0,
              forca: float = 0.55) -> None:
        self.com_script(nome, "Area2D", "res://scripts/solo_toxico.gd",
                        f"position = {v(x, y)}\nmodo = \"nuvem\"\nlargura = {larg:g}\naltura = {alt:g}\n"
                        f"amplitude = {amplitude:g}\nperiodo = {periodo:g}\nfase = {fase:g}\n"
                        f"veneno_seg = 2.0\nveneno_dano = 1\nforca = {forca:g}\n"
                        f'textura = ExtResource("{self.tex("r12_nuvem_veneno")}")')

    def zona_limpa(self, nome: str, x: float, topo: float, larg: float = 220.0, alt: float = 130.0,
                   duracao: float = 0.0, recarga: float = 6.0) -> None:
        self.com_script(nome, "Area2D", "res://scripts/zona_limpa.gd",
                        f"position = {v(x, topo)}\nlargura = {larg:g}\naltura = {alt:g}\n"
                        f"duracao = {duracao:g}\nrecarga = {recarga:g}")

    def respiro(self, nome: str, x: float, y: float, alcance: float = 220.0, intervalo: float = 2.4,
                aviso: float = 0.9, dur: float = 1.4, fase: float = 0.0, invertido: bool = False) -> None:
        self.com_script(nome, "Area2D", "res://scripts/respiro_praga.gd",
                        f"position = {v(x, y)}\nalcance = {alcance:g}\nintervalo = {intervalo:g}\n"
                        f"aviso_seg = {aviso:g}\ndur_ativa = {dur:g}\nfase = {fase:g}\n"
                        f"invertido = {str(invertido).lower()}\n"
                        f'textura_jato = ExtResource("{self.tex("r12_geiser")}")\n'
                        f'textura_bocal = ExtResource("{self.tex("r12_poca_toxica")}")')

    # -------------------------------------------------------- cenografia
    def atmosfera(self, cena_atm: str, pack: str, largura: float, seed: int,
                  ambiente: str = "Color(0.82, 0.95, 0.74, 1)",
                  fundo: str = "Color(0.04, 0.07, 0.05, 1)",
                  luz: str = "Color(0.62, 1.0, 0.5, 1)", poeira: float = 1.6,
                  tinta: str = "Color(0.95, 1.0, 0.9, 1)", neblina: float = 0.14) -> None:
        self.no("Atmosfera", f"""cor_ambiente = {ambiente}
cor_fundo = {fundo}
cor_silhueta = Color(0.07, 0.11, 0.08, 1)
cor_luz = {luz}
cor_poeira = Color(0.7, 1.0, 0.45, 1)
densidade_poeira = {poeira:g}
bioma = "terras_envenenadas"
largura_nivel = {largura:g}
fundo_pack = "{pack}"
tinta_fundo = {tinta}
neblina_fundo = {neblina:g}
dessaturar_fundo = 0.0
seed_ambiente = {seed}
luzes_horizonte = false""", inst=self.cena("res://scenes/fx/Atmosfera.tscn"))

    def gas(self, nome: str, x: float, y: float, larg: float, n: int = 14, z: int = 1,
            cor_ini: str = "0.3, 0.55, 0.18") -> None:
        """Veu de esporos/gas verde a subir devagar (so' visual)."""
        self.no(nome, f"position = {v(x, y)}\nz_index = {z}\namount = {n}\nlifetime = 5.0\n"
                      "preprocess = 5.0\nlocal_coords = false\nemission_shape = 3\n"
                      f"emission_rect_extents = Vector2({larg / 2:g}, 4)\n"
                      "direction = Vector2(0, -1)\nspread = 20.0\ngravity = Vector2(4, -10)\n"
                      "initial_velocity_min = 6.0\ninitial_velocity_max = 22.0\n"
                      "scale_amount_min = 10.0\nscale_amount_max = 26.0\n"
                      'color_ramp = SubResource("ramp_gas")', tipo="CPUParticles2D")

    def esporos(self, nome: str, x: float, y: float, larg: float, n: int = 18, z: int = 3) -> None:
        self.no(nome, f"position = {v(x, y)}\nz_index = {z}\namount = {n}\nlifetime = 3.2\n"
                      "preprocess = 3.0\nlocal_coords = false\nemission_shape = 3\n"
                      f"emission_rect_extents = Vector2({larg / 2:g}, 40)\n"
                      "direction = Vector2(0, -1)\nspread = 60.0\ngravity = Vector2(0, -6)\n"
                      "initial_velocity_min = 4.0\ninitial_velocity_max = 16.0\n"
                      "scale_amount_min = 1.2\nscale_amount_max = 2.8\n"
                      'color_ramp = SubResource("ramp_esporo")', tipo="CPUParticles2D")

    def escrever(self, saida: str, cabecalho: str) -> None:
        # rampas da regiao: acrescentadas ao bloco de sub-recursos da base
        super().escrever(saida, cabecalho)
        with open(saida, encoding="utf-8") as f:
            t = f.read()
        extra = '''
[sub_resource type="Gradient" id="ramp_gas"]
offsets = PackedFloat32Array(0, 0.3, 1)
colors = PackedColorArray(0.3, 0.55, 0.18, 0, 0.36, 0.62, 0.2, 0.3, 0.12, 0.25, 0.08, 0)

[sub_resource type="Gradient" id="ramp_esporo"]
offsets = PackedFloat32Array(0, 0.4, 1)
colors = PackedColorArray(0.8, 1, 0.5, 0, 0.7, 1, 0.4, 0.85, 0.3, 0.6, 0.15, 0)
'''
        marca = '[sub_resource type="Gradient" id="ramp_fumo"]'
        i = t.index(marca)
        j = t.index("\n[node", i) if "\n[node" in t[i:] else len(t)
        # inserir antes do primeiro [node ...]; o bloco de subs acaba ai'
        j = t.index("\n[node name=", i)
        t = t[:j] + "\n" + extra.strip("\n") + "\n" + t[j:]
        t = t.replace("load_steps=", "load_steps=", 1)
        with open(saida, "w", encoding="utf-8", newline="\n") as f:
            f.write(t)
