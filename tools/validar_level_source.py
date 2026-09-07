#!/usr/bin/env python3
"""Valida a fonte de verdade dos níveis e a segurança do gerador."""

from __future__ import annotations

import argparse
import importlib.util
import os
import re
import sys
from collections import Counter

from level_contract import (
    carregar_manifesto,
    caminho_local,
    motivo_protecao,
    validar_pasta_staging,
)


RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGENS = {"authored", "generated", "hybrid"}
OWNERSHIPS = {"authored", "generated", "unknown"}


def falhar(erros: list[str], mensagem: str) -> None:
    erros.append(mensagem)


def cenas_estado_jogo() -> list[str]:
    caminho = os.path.join(RAIZ, "scripts", "estado_jogo.gd")
    texto = open(caminho, encoding="utf-8").read()
    bloco = texto.split("const NIVEIS := [", 1)[1].split("\n]", 1)[0]
    return re.findall(r'"(res://scenes/levels/[^\"]+\.tscn)"', bloco)


def boss_da_cena(caminho_res: str) -> str | None:
    texto = open(caminho_local(caminho_res), encoding="utf-8").read()
    recursos = {
        achado.group(2): achado.group(1)
        for achado in re.finditer(
            r'\[ext_resource[^\]]*path="([^"]+)" id="([^"]+)"\]', texto
        )
    }
    chefe = re.search(
        r'^\[node name="Chefe"[^\]]*instance=ExtResource\("([^"]+)"\)',
        texto,
        re.MULTILINE,
    )
    return recursos.get(chefe.group(1)) if chefe else None


def carregar_modulo(nome: str, ficheiro: str):
    caminho = os.path.join(RAIZ, "tools", ficheiro)
    spec = importlib.util.spec_from_file_location(nome, caminho)
    modulo = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(modulo)
    return modulo


def validar_source_of_truth() -> list[str]:
    erros: list[str] = []
    manifesto = carregar_manifesto()
    niveis = manifesto.get("levels", [])
    regioes = manifesto.get("regions", [])
    ids_nivel = [nivel.get("level_id") for nivel in niveis]
    ids_regiao = [regiao.get("region_id") for regiao in regioes]
    esperados_nivel = ["level_%03d" % n for n in range(1, 101)]
    esperados_regiao = ["region_%02d" % n for n in range(1, 21)]

    if len(niveis) != 100:
        falhar(erros, "manifesto não contém exatamente 100 níveis")
    if ids_nivel != esperados_nivel:
        falhar(erros, "IDs de nível estão ausentes, duplicados ou fora da ordem canónica")
    if len(set(ids_nivel)) != len(ids_nivel):
        falhar(erros, "existem level IDs duplicados")
    if len(regioes) != 20 or ids_regiao != esperados_regiao:
        falhar(erros, "regiões não correspondem exatamente a region_01–region_20")

    contagem_regiao = Counter(nivel.get("region_id") for nivel in niveis)
    cenas_runtime = cenas_estado_jogo()
    cenas_manifesto = [nivel.get("runtime_scene") for nivel in niveis]
    if cenas_manifesto != cenas_runtime:
        falhar(erros, "ordem/cenas do manifesto divergem de EstadoJogo.NIVEIS")

    bosses: set[str] = set()
    contratos = manifesto.get("generator_contracts", {})
    for indice, nivel in enumerate(niveis, 1):
        level_id = "level_%03d" % indice
        region_id = "region_%02d" % (((indice - 1) // 5) + 1)
        if nivel.get("region_id") != region_id:
            falhar(erros, "%s referencia região inválida" % level_id)
        if nivel.get("origin") not in ORIGENS:
            falhar(erros, "%s tem origin inválido" % level_id)
        if nivel.get("ownership") not in OWNERSHIPS:
            falhar(erros, "%s tem ownership inválido" % level_id)
        cena = nivel.get("runtime_scene", "")
        if not os.path.isfile(caminho_local(cena)):
            falhar(erros, "%s referencia cena inexistente" % level_id)
        boss = nivel.get("boss_ref")
        if boss is not None:
            boss_id = boss.get("boss_id", "")
            boss_scene = boss.get("scene", "")
            if not boss_id or boss_id in bosses:
                falhar(erros, "%s tem boss reference inválida/duplicada" % level_id)
            bosses.add(boss_id)
            if not os.path.isfile(caminho_local(boss_scene)):
                falhar(erros, "%s referencia boss scene inexistente" % level_id)
            if boss_da_cena(cena) != boss_scene:
                falhar(erros, "%s diverge da associação de boss da cena" % level_id)

        gerador = nivel.get("generator")
        if nivel.get("origin") == "generated":
            obrigatorios = {"identity", "version", "seed", "config_ref", "runtime_generator"}
            if not isinstance(gerador, dict) or not obrigatorios.issubset(gerador):
                falhar(erros, "%s não tem metadata completa do gerador" % level_id)
            elif gerador["identity"] not in contratos:
                falhar(erros, "%s referencia generator identity inválida" % level_id)
        if motivo_protecao(nivel) and nivel.get("auto_regenerate") is True:
            falhar(erros, "%s autoriza regeneração apesar de estar protegido" % level_id)

    for regiao in regioes:
        region_id = regiao.get("region_id")
        if contagem_regiao[region_id] != 5 or len(regiao.get("level_ids", [])) != 5:
            falhar(erros, "%s não contém exatamente cinco níveis" % region_id)
        declarados = [nivel["level_id"] for nivel in niveis if nivel["region_id"] == region_id]
        if regiao.get("level_ids") != declarados:
            falhar(erros, "%s diverge dos níveis declarados" % region_id)
    return erros


def validar_generator_safety() -> list[str]:
    erros: list[str] = []
    manifesto = carregar_manifesto()
    gerador = carregar_modulo("gerar_niveis_31_100", "gerar_niveis_31_100.py")
    atmosfera = carregar_modulo("afinar_atmosfera", "afinar_atmosfera.py")
    gerados = [nivel for nivel in manifesto["levels"] if nivel["origin"] == "generated"]
    if gerador.GENERATOR_ID not in manifesto["generator_contracts"]:
        falhar(erros, "identity do gerador não existe no manifesto")
    contrato = manifesto["generator_contracts"].get(gerador.GENERATOR_ID, {})
    if contrato.get("version") != gerador.GENERATOR_VERSION:
        falhar(erros, "versão do gerador diverge do manifesto")
    if len(gerador.NIVEIS) != 70:
        falhar(erros, "tabela do gerador não contém exatamente os níveis 31–100")
    if len(atmosfera.TABELA) != 100:
        falhar(erros, "tabela de atmosfera não contém exatamente 100 níveis")
    contrato_atmosfera = manifesto["generator_contracts"].get(atmosfera.GENERATOR_ID, {})
    if contrato_atmosfera.get("version") != atmosfera.GENERATOR_VERSION:
        falhar(erros, "versão do gerador de atmosfera diverge do manifesto")

    fonte_jornada = open(
        os.path.join(RAIZ, "scripts", "gerador_corredor.gd"), encoding="utf-8"
    ).read()
    if '_rng.seed = hash("jornada4|%d" % _idx)' not in fonte_jornada:
        falhar(erros, "seed/version jornada4 diverge do gerador runtime")

    por_indice = {dados[1]: dados for dados in gerador.NIVEIS}
    for nivel in gerados:
        indice = nivel["campaign_order"] - 1
        dados = por_indice.get(indice)
        if dados is None:
            falhar(erros, "%s não existe na tabela do gerador" % nivel["level_id"])
            continue
        if nivel["runtime_scene"].rsplit("/", 1)[-1] != dados[0] + ".tscn":
            falhar(erros, "%s diverge do filename do gerador" % nivel["level_id"])
        esperado_seed = "jornada4|%d" % indice
        if nivel["generator"].get("seed") != esperado_seed:
            falhar(erros, "%s tem seed diferente da jornada runtime" % nivel["level_id"])
        meta_atmosfera = nivel["generator"].get("atmosphere", {})
        if meta_atmosfera.get("identity") != atmosfera.GENERATOR_ID:
            falhar(erros, "%s não declara o gerador de atmosfera" % nivel["level_id"])
        if meta_atmosfera.get("version") != atmosfera.GENERATOR_VERSION:
            falhar(erros, "%s tem versão de atmosfera inválida" % nivel["level_id"])
        if meta_atmosfera.get("seed") != 1000 + indice * 37:
            falhar(erros, "%s tem seed de atmosfera inválida" % nivel["level_id"])
        if gerador.renderizar_nivel(dados) != gerador.renderizar_nivel(dados):
            falhar(erros, "%s não é determinístico com a mesma configuração" % nivel["level_id"])
        linha_atmosfera = atmosfera.TABELA[indice]
        if linha_atmosfera[0] + ".tscn" != nivel["runtime_scene"].rsplit("/", 1)[-1]:
            falhar(erros, "%s diverge da tabela de atmosfera" % nivel["level_id"])
        cena_atual = open(caminho_local(nivel["runtime_scene"]), encoding="utf-8").read()
        if atmosfera.renderizar_atmosfera(cena_atual, indice, linha_atmosfera) != \
                atmosfera.renderizar_atmosfera(cena_atual, indice, linha_atmosfera):
            falhar(erros, "%s tem atmosfera não determinística" % nivel["level_id"])

    protegidos = [nivel["level_id"] for nivel in gerados if motivo_protecao(nivel)]
    recusas = gerador.recusas_promocao(protegidos)
    if len(recusas) != len(protegidos):
        falhar(erros, "o gerador não recusa todos os targets protegidos")
    if any(not motivo_protecao(nivel) for nivel in gerados):
        falhar(erros, "há target 31–100 promovível sem classificação deliberada")
    try:
        validar_pasta_staging(os.path.join(RAIZ, "scenes", "levels"))
        falhar(erros, "a pasta runtime pode ser usada como staging")
    except ValueError:
        pass
    return erros


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-of-truth", action="store_true")
    parser.add_argument("--generator-safety", action="store_true")
    args = parser.parse_args()
    executar_todos = not args.source_of_truth and not args.generator_safety
    grupos = []
    if executar_todos or args.source_of_truth:
        grupos.append(("LEVEL SOURCE OF TRUTH", validar_source_of_truth()))
    if executar_todos or args.generator_safety:
        grupos.append(("GENERATOR SAFETY", validar_generator_safety()))

    erros = []
    for nome, falhas in grupos:
        if falhas:
            print("%s: FAIL (%d)" % (nome, len(falhas)))
            erros.extend(falhas)
        else:
            print("%s: PASS" % nome)
    for erro in erros:
        print("- " + erro, file=sys.stderr)
    return 1 if erros else 0


if __name__ == "__main__":
    raise SystemExit(main())
