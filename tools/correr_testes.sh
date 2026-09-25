#!/usr/bin/env bash
# CORRER A SUITE SEM TOCAR NO SAVE REAL. Isolamento (por SO) e SHA256 do save
# real vivem em `tools/godot_isolado.py`. Sai com o codigo da suite.
# Uso: GODOT=/caminho/godot tools/correr_testes.sh
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY="$(command -v python3 || command -v python)"
exec "$PY" "$RAIZ/tools/godot_isolado.py" -- --headless --path "$RAIZ" res://tests/run_tests.tscn
