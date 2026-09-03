#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Escreve as CENAS dos niveis 31-100 a partir de uma tabela.

Os 30 niveis da campanha 1-30 sao salas desenhadas a' mao, com 130 a 200
linhas de `.tscn` cada. Para os 70 de `docs/plano_niveis_31_100.md` isso
nao escala -- e nao e' preciso: com `corredor = true` (por omissao) o
`gerador_corredor.gd` constroi a JORNADA toda, que e' a maior parte do
nivel, e a cena so' precisa de:

    Atmosfera . liquido mortal . chao do chefe . o chefe . a Koliani .
    um checkpoint . a Porta

Ou seja, cada nivel novo e' UMA LINHA nesta tabela. O chefe e' o
`ChefeGenerico` (`scripts/chefe_generico.gd`) configurado por arquetipo.

AVISO HONESTO: um nivel destes e' uma jornada procedural tematica com um
chefe no fim, nao uma sala desenhada como as 29 da campanha original. E' a
troca assumida para 70 niveis caberem em tempo humano; qualquer um deles
pode ser reescrito a' mao depois, e ai' basta por `corredor = false`.

  python tools/gerar_niveis_31_100.py            # escreve
  python tools/gerar_niveis_31_100.py --dry-run  # so' diz o que faria

Depois de correr: `godot --headless --import` e
`python tools/afinar_atmosfera.py` (que da' a cada nivel o seu ceu).
"""

from __future__ import annotations

import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEST = os.path.join(RAIZ, "scenes", "levels")

# Um nivel = (ficheiro, indice0, regiao_id, arquetipo, vida, rim, sprite, nota)
#   indice0  -- indice em `EstadoJogo.NIVEIS` (0-based)
#   regiao_id-- `bioma` da Atmosfera. As 14 regioes novas ainda nao tem
#               terreno proprio (`tools/gerar_terreno.py` so' conhece 6);
#               ate' la' cada uma emprestada a mais parecida, e a
#               identidade vem da tinta/luz do `afinar_atmosfera.py`.
#   arquetipo-- indice em `ChefeGenerico.Arquetipo`:
#               0 INVESTIDA  1 ATIRADOR  2 SALTADOR  3 INVOCADOR  4 FEIXE
#   sprite   -- arte emprestada de um dos 29 chefes de 1-30 (placeholder
#               assumido: os 70 chefes novos nao tem arte)
NIVEIS = [
    # --- VII  TERRAS QUEIMADAS (31-35) -- a magia purpura queima o reino --
    ("Estrada_das_Cinzas", 30, "floresta", 0, 460, (1.0, 0.45, 0.15),
     "ignivar", "Floresta a arder: o chao cede. Vulkar, o Cavaleiro das Cinzas."),
    ("Rio_de_Magma", 31, "catacumbas", 0, 500, (1.0, 0.36, 0.10),
     "naga", "Rio de lava e pedra vulcanica. Magmora, serpente de magma."),
    ("A_Forja_dos_Demonios", 32, "castelo", 3, 540, (1.0, 0.55, 0.20),
     "maquinista", "Correias, martelos e metal derretido. O Mestre da Forja."),
    ("Vulcao_do_Rei_Morto", 33, "catacumbas", 1, 580, (1.0, 0.30, 0.12),
     "vyrak", "Subida pelo interior do vulcao. Dragorak, o Rei de Lava."),
    ("O_Ceu_em_Chamas", 34, "castelo", 4, 640, (1.0, 0.72, 0.35),
     "arauto", "Topo do vulcao, o ceu a cair. A Estrela Caida."),
]

MODELO = '''[gd_scene load_steps=9 format=3 uid="uid://bkoliani{uid}"]

; REGIAO {regiao_num} / nivel {n} -- {titulo}.
; {nota}
;
; CENA GERADA por `tools/gerar_niveis_31_100.py` -- NAO editar a' mao: o
; proximo `python tools/gerar_niveis_31_100.py` apaga o que aqui se puser.
; A JORNADA (`corredor = true`, `gerador_corredor.gd`) constroi tudo o que
; vem antes desta sala; aqui so' esta' a arena do chefe.
; O bloco `Atmosfera` e' reescrito por `tools/afinar_atmosfera.py`.

[ext_resource type="PackedScene" uid="uid://bkolianiactor01" path="res://scenes/actors/Koliani.tscn" id="1_kol"]
[ext_resource type="PackedScene" uid="uid://bkolianiporta01" path="res://scenes/actors/Porta.tscn" id="2_porta"]
[ext_resource type="Script" path="res://scripts/checkpoint.gd" id="3_chk"]
[ext_resource type="PackedScene" uid="uid://bkolianichefegenerico01" path="res://scenes/actors/ChefeGenerico.tscn" id="4_chefe"]
[ext_resource type="Script" path="res://scripts/nivel_com_chefe.gd" id="5_niv"]
[ext_resource type="PackedScene" uid="uid://bkolianiatmosfera01" path="res://scenes/fx/Atmosfera.tscn" id="6_atm"]
[ext_resource type="PackedScene" uid="uid://bkolianiplataforma01" path="res://scenes/actors/Plataforma.tscn" id="7_pl"]
[ext_resource type="PackedScene" uid="uid://bkolianiaguavenenosa01" path="res://scenes/actors/AguaVenenosa.tscn" id="8_liq"]
[ext_resource type="Texture2D" path="res://assets/sprites/pixel/bosses/{sprite}.png" id="9_tex"]

[sub_resource type="RectangleShape2D" id="rs_chk"]
size = Vector2(44, 96)

[node name="{ficheiro}" type="Node2D"]
script = ExtResource("5_niv")

[node name="Atmosfera" parent="." instance=ExtResource("6_atm")]
bioma = "{bioma}"
largura_nivel = 1800.0

[node name="LiquidoMortal" parent="." instance=ExtResource("8_liq")]
position = Vector2(700, 980)
largura = 2000.0
altura = 340.0
cor = Color(0.74, 0.28, 0.05, 0.95)
brasas = true

[node name="ChaoChefe" parent="." instance=ExtResource("7_pl")]
position = Vector2(760, 700)
tamanho = Vector2(1000, 60)
altura_visual = 110.0

[node name="Chefe" parent="." instance=ExtResource("4_chefe")]
position = Vector2(1020, 616)
arquetipo = {arquetipo}
vida = {vida}
cor_rim = Color({rim[0]}, {rim[1]}, {rim[2]}, 1)
textura = ExtResource("9_tex")
{extra}
[node name="Koliani" parent="." instance=ExtResource("1_kol")]
position = Vector2(360, 616)

[node name="CheckInicio" type="Area2D" parent="."]
position = Vector2(430, 632)
collision_layer = 16
collision_mask = 2
script = ExtResource("3_chk")

[node name="CollisionShape2D" type="CollisionShape2D" parent="CheckInicio"]
shape = SubResource("rs_chk")

[node name="Porta" parent="." instance=ExtResource("2_porta")]
position = Vector2(1210, 622)
pista_ao_atravessar = ""
'''

# Numeros por arquetipo que fazem cada um ler como o chefe que o plano
# descreve. Sem isto os cinco arquetipos sairiam todos com o ritmo por
# omissao e os 70 chefes sentir-se-iam iguais.
AFINACAO = {
    0: 'investidas_seguidas = 2\ndur_recupera = 0.7\n',       # INVESTIDA
    1: 'tiros_por_salva = 5\nleque_graus = 34.0\ndist_ideal = 300.0\n',  # ATIRADOR
    2: 'forca_salto = 470.0\nraio_onda = 340.0\n',            # SALTADOR
    3: 'lacaios_por_vez = 2\ndist_ideal = 280.0\n',           # INVOCADOR
    4: 'feixe_alcance = 700.0\ndist_ideal = 320.0\ndur_telegrafo = 0.55\n',  # FEIXE
}

TITULOS = {
    "Estrada_das_Cinzas": "Estrada das Cinzas",
    "Rio_de_Magma": "Rio de Magma",
    "A_Forja_dos_Demonios": "A Forja dos Demonios",
    "Vulcao_do_Rei_Morto": "Vulcao do Rei Morto",
    "O_Ceu_em_Chamas": "O Ceu em Chamas",
}


def main() -> int:
    seco = "--dry-run" in sys.argv
    for ficheiro, idx0, bioma, arq, vida, rim, sprite, nota in NIVEIS:
        n = idx0 + 1
        texto = MODELO.format(
            uid=ficheiro.lower().replace("_", "") + str(n),
            regiao_num=(idx0 // 5) + 1,
            n=n,
            titulo=TITULOS[ficheiro],
            nota=nota,
            ficheiro=ficheiro,
            bioma=bioma,
            arquetipo=arq,
            vida=vida,
            rim=rim,
            sprite=sprite,
            extra=AFINACAO.get(arq, ""),
        )
        cam = os.path.join(DEST, ficheiro + ".tscn")
        print("  %-24s n%-3d arquetipo=%d vida=%d %s" % (
            ficheiro, n, arq, vida, "(dry-run)" if seco else ""))
        if not seco:
            with open(cam, "w", encoding="utf-8", newline="\n") as f:
                f.write(texto)
    print("%d niveis" % len(NIVEIS))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
