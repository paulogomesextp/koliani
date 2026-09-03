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
#   rig      -- rig ANIMADO de `bosses_anim/rigs.json`
#               (`tools/importar_chefes_animados.py`). Ate' 3 set 2026
#               nenhum chefe do jogo animava: a folha antiga sao quatro
#               POSES, nao uma animacao. So' ha' cinco rigs -- os packs
#               gratuitos que estavam no repo -- portanto a regiao VII usa
#               os cinco e as regioes seguintes precisam de packs novos.
#   fim      -- como acaba o nivel:
#               "chefe"    -> ChefeGenerico + porta selada ate' ele cair
#               "guardiao" -> um ELITE sela a porta. Pedido do Paulo
#                  ("nao precisa ter um boss todos os niveis"): a campanha
#                  31-100 tem UM chefe por regiao, o ultimo dos cinco, e
#                  guardioes nos outros quatro. Da' clima'x ao nivel sem
#                  gastar um chefe, e sao 14 chefes novos em vez de 70 --
#                  cada um pode ser trabalhado a serio.
#   especie  -- so' para "guardiao": a especie do elite (DemonioBase)
NIVEIS = [
    # --- VII  TERRAS QUEIMADAS (31-35) -- a magia purpura queima o reino --
    ("Estrada_das_Cinzas", 30, "floresta", "guardiao", 0, 260, (1.0, 0.45, 0.15),
     "imp", "Floresta a arder: o chao cede. Guardiao: um imp de cinzas."),
    ("Rio_de_Magma", 31, "catacumbas", "guardiao", 0, 300, (1.0, 0.36, 0.10),
     "chort", "Rio de lava e pedra vulcanica. Guardiao: um chort do magma."),
    ("A_Forja_dos_Demonios", 32, "castelo", "guardiao", 0, 340, (1.0, 0.55, 0.20),
     "ogro", "Correias, martelos e metal derretido. Guardiao: o ferreiro."),
    ("Vulcao_do_Rei_Morto", 33, "catacumbas", "guardiao", 0, 380, (1.0, 0.30, 0.12),
     "demonio_grande", "Subida pelo interior do vulcao. Guardiao: a besta do vulcao."),
    # o CHEFE da regiao: A Estrela Caida, 1.o a sugerir que a ameaca e'
    # maior que o Zeriko (docs/plano_niveis_31_100.md)
    ("O_Ceu_em_Chamas", 34, "castelo", "chefe", 4, 640, (1.0, 0.72, 0.35),
     "feiticeiro", "Topo do vulcao, o ceu a cair. A Estrela Caida."),
    # --- VIII  MAR DOS MORTOS (36-40) -- o reino que a agua engoliu ------
    # Contraponto directo a' VII: onde aquela era brasa e ar seco, esta e'
    # azul-esverdeado, funda e sem ar. E' a primeira regiao em que o
    # liquido mortal deixa de ser "lava ou acido" e passa a ser agua negra.
    ("Porto_dos_Afogados", 35, "prisao", "guardiao", 0, 400, (0.40, 0.90, 0.95),
     "esqueleto", "Navios partidos e pontoes a boiar. Guardiao: um afogado."),
    ("Cidade_Submersa", 36, "cidade", "guardiao", 0, 440, (0.32, 0.82, 1.00),
     "gosma", "Ruas debaixo de agua, gravidade fraca. Guardiao: uma gosma."),
    ("Palacio_das_Sereias_Mortas", 37, "castelo", "guardiao", 0, 480, (0.50, 0.94, 0.90),
     "wogol", "Estatuas que se mexem quando a agua sobe. Guardiao: uma delas."),
    ("Ossario_das_Baleias", 38, "catacumbas", "guardiao", 0, 520, (0.62, 0.96, 0.88),
     "lodo", "Caverna dentro de um esqueleto de baleia. Guardiao: o lodo."),
    # o CHEFE da regiao: A Mae do Abismo -- entidade colossal de tentaculos
    # (docs/plano_niveis_31_100.md)
    ("Abismo_Oceanico", 39, "catacumbas", "chefe", 3, 720, (0.26, 0.70, 1.00),
     "horror", "Fundo do mar, quase sem luz. A Mae do Abismo."),
    # --- IX  REINO DO GELO (41-45) -- o branco depois do azul-tinta ------
    # A VIII era funda e escura; esta e' o contrario: neve, muita luz e
    # pouca cor. E' a primeira regiao CLARA do jogo -- depois de trinta e
    # cinco niveis de noite, a mudanca sente-se so' por isso.
    ("Floresta_Congelada", 40, "torres", "guardiao", 0, 560, (0.72, 0.94, 1.00),
     "mastim", "Mata gelada, chao escorregadio. Guardiao: um cao de gelo."),
    ("Montanha_dos_Ventos", 41, "torres", "guardiao", 0, 600, (0.80, 0.96, 1.00),
     "abutre", "Subida a pique com vento. Guardiao: o abutre da ventania."),
    ("Cavernas_Cristalinas", 42, "catacumbas", "guardiao", 0, 640, (0.66, 0.90, 1.00),
     "besouro", "Cristais como plataformas. Guardiao: um besouro de cristal."),
    ("Castelo_Congelado", 43, "castelo", "guardiao", 0, 680, (0.86, 0.98, 1.00),
     "esqueleto", "Castelo parado no tempo. Guardiao: uma sentinela gelada."),
    # o CHEFE da regiao: Ymiria, a Deusa do Inverno
    ("Coracao_do_Inverno", 44, "torres", "chefe", 4, 800, (0.62, 0.88, 1.00),
     "sacerdotisa_gelo", "Centro da montanha. Ymiria, a Deusa do Inverno."),
]

MODELO_CHEFE = '''[gd_scene load_steps=8 format=3 uid="uid://bkoliani{uid}"]

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
cor = Color({liq[0]}, {liq[1]}, {liq[2]}, {liq[3]})
brasas = {brasas}

[node name="ChaoChefe" parent="." instance=ExtResource("7_pl")]
position = Vector2(760, 700)
tamanho = Vector2(1000, 60)
altura_visual = 110.0

[node name="Chefe" parent="." instance=ExtResource("4_chefe")]
position = Vector2(1020, 616)
arquetipo = {arquetipo}
vida = {vida}
cor_rim = Color({rim[0]}, {rim[1]}, {rim[2]}, 1)
rig = "{rig}"
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

# Nivel SEM chefe: acaba num GUARDIAO -- um elite do `DemonioBase` que sela
# a porta ate' cair. O `nivel_com_chefe.gd` liga-se ao `tree_exited` do no'
# chamado `Guardiao`.
MODELO_GUARDIAO = '''[gd_scene load_steps=8 format=3 uid="uid://bkoliani{uid}"]

; REGIAO {regiao_num} / nivel {n} -- {titulo}.
; {nota}
;
; NIVEL SEM CHEFE. A regiao tem um chefe so' -- o ultimo dos cinco --
; e este acaba num GUARDIAO (elite) que sela a porta ate' cair.
;
; CENA GERADA por `tools/gerar_niveis_31_100.py` -- NAO editar a' mao.
; O bloco `Atmosfera` e' reescrito por `tools/afinar_atmosfera.py`.

[ext_resource type="PackedScene" uid="uid://bkolianiactor01" path="res://scenes/actors/Koliani.tscn" id="1_kol"]
[ext_resource type="PackedScene" uid="uid://bkolianiporta01" path="res://scenes/actors/Porta.tscn" id="2_porta"]
[ext_resource type="Script" path="res://scripts/checkpoint.gd" id="3_chk"]
[ext_resource type="PackedScene" uid="uid://bdemoniobase01" path="res://scenes/actors/DemonioBase.tscn" id="4_dem"]
[ext_resource type="Script" path="res://scripts/nivel_com_chefe.gd" id="5_niv"]
[ext_resource type="PackedScene" uid="uid://bkolianiatmosfera01" path="res://scenes/fx/Atmosfera.tscn" id="6_atm"]
[ext_resource type="PackedScene" uid="uid://bkolianiplataforma01" path="res://scenes/actors/Plataforma.tscn" id="7_pl"]
[ext_resource type="PackedScene" uid="uid://bkolianiaguavenenosa01" path="res://scenes/actors/AguaVenenosa.tscn" id="8_liq"]

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
cor = Color({liq[0]}, {liq[1]}, {liq[2]}, {liq[3]})
brasas = {brasas}

[node name="ChaoChefe" parent="." instance=ExtResource("7_pl")]
position = Vector2(760, 700)
tamanho = Vector2(1000, 60)
altura_visual = 110.0

[node name="Guardiao" parent="." instance=ExtResource("4_dem")]
position = Vector2(1020, 630)
scale = Vector2(1.5, 1.5)
elite = true
especie = "{especie}"
vida = {vida}
dano_contacto = 26
comportamento = "carga"
alcance_patrulha = 150.0
cor_rim = Color({rim[0]}, {rim[1]}, {rim[2]}, 1)

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
    "Porto_dos_Afogados": "Porto dos Afogados",
    "Cidade_Submersa": "Cidade Submersa",
    "Palacio_das_Sereias_Mortas": "Palacio das Sereias Mortas",
    "Ossario_das_Baleias": "Ossario das Baleias",
    "Abismo_Oceanico": "Abismo Oceanico",
    "Floresta_Congelada": "Floresta Congelada",
    "Montanha_dos_Ventos": "Montanha dos Ventos",
    "Cavernas_Cristalinas": "Cavernas Cristalinas",
    "Castelo_Congelado": "Castelo Congelado",
    "Coracao_do_Inverno": "Coracao do Inverno",
}

# Liquido mortal da arena do chefe, por REGIAO (indice0 // 5). Sem isto o
# modelo punha lava laranja em todas -- e no Mar dos Mortos a agua negra
# lida como lava era o erro mais obvio do nivel.
LIQUIDO_REGIAO = {
    6: ((0.74, 0.28, 0.05, 0.95), "true"),    # VII magma vivo
    7: ((0.03, 0.10, 0.16, 0.96), "false"),   # VIII agua negra do abismo
    8: ((0.30, 0.52, 0.66, 0.92), "false"),   # IX agua gelada por baixo do gelo
}


def main() -> int:
    seco = "--dry-run" in sys.argv
    for ficheiro, idx0, bioma, fim, arq, vida, rim, rig, nota in NIVEIS:
        n = idx0 + 1
        texto = (MODELO_CHEFE if fim == "chefe" else MODELO_GUARDIAO).format(
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
            rig=rig,
            especie=rig,
            liq=LIQUIDO_REGIAO.get(idx0 // 5, ((0.74, 0.28, 0.05, 0.95), "true"))[0],
            brasas=LIQUIDO_REGIAO.get(idx0 // 5, ((0, 0, 0, 0), "true"))[1],
            extra=AFINACAO.get(arq, "") if fim == "chefe" else "",
        )
        cam = os.path.join(DEST, ficheiro + ".tscn")
        print("  %-24s n%-3d %-8s vida=%-4d %-14s %s" % (
            ficheiro, n, fim, vida, rig, "(dry-run)" if seco else ""))
        if not seco:
            with open(cam, "w", encoding="utf-8", newline="\n") as f:
                f.write(texto)
    print("%d niveis" % len(NIVEIS))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
