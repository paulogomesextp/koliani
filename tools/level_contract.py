#!/usr/bin/env python3
"""Contrato pequeno e partilhado para identidade e proteção dos níveis."""

from __future__ import annotations

import json
import os
from typing import Any


RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFESTO = os.path.join(RAIZ, "data", "level_manifest.json")


def carregar_manifesto() -> dict[str, Any]:
    with open(MANIFESTO, encoding="utf-8") as ficheiro:
        return json.load(ficheiro)


def niveis_por_id(manifesto: dict[str, Any] | None = None) -> dict[str, dict[str, Any]]:
    dados = manifesto if manifesto is not None else carregar_manifesto()
    return {nivel["level_id"]: nivel for nivel in dados["levels"]}


def caminho_local(caminho_res: str) -> str:
    if not caminho_res.startswith("res://"):
        raise ValueError("caminho runtime tem de começar por res://")
    return os.path.join(RAIZ, *caminho_res.removeprefix("res://").split("/"))


def validar_pasta_staging(pasta: str) -> str:
    """Recusa usar a árvore das cenas runtime como se fosse staging."""
    resolvida = os.path.realpath(os.path.abspath(pasta))
    runtime = os.path.realpath(os.path.join(RAIZ, "scenes", "levels"))
    if os.path.commonpath([resolvida, runtime]) == runtime:
        raise ValueError("staging não pode ficar dentro de scenes/levels")
    return resolvida


def motivo_protecao(nivel: dict[str, Any]) -> str:
    origem = nivel.get("origin")
    ownership = nivel.get("ownership")
    if ownership == "unknown":
        return "ownership unknown é protegido"
    if ownership == "authored":
        return "ownership authored é protegido"
    if origem == "hybrid":
        return "a cena final hybrid é protegida"
    if origem != "generated" or ownership != "generated":
        return "apenas generated/generated pode ser promovido"
    if nivel.get("auto_regenerate") is not True:
        return "auto_regenerate não está autorizado no manifesto"
    return ""


def pode_promover(nivel: dict[str, Any]) -> bool:
    return motivo_protecao(nivel) == ""
