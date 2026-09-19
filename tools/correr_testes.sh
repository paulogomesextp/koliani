#!/usr/bin/env bash
# CORRER A SUITE SEM TOCAR NO SAVE REAL -- equivalente Linux do
# `correr_testes.ps1` (que so' serve Windows, via %APPDATA%).
#
# No Linux o `user://` do Godot resolve por $XDG_DATA_HOME (por omissao
# ~/.local/share), por isso lancar o motor com essa variavel apontada a uma
# pasta descartavel isola save, opcoes e capturas -- sem mexer no jogo.
# Confirma por SHA256 que o save real ficou intacto.
#
# Uso:  tools/correr_testes.sh [caminho_do_godot]
# Sai com o mesmo codigo que a suite (0 = tudo passou).
set -uo pipefail

GODOT="${1:-/tmp/godot/Godot_v4.7.2-stable_linux.x86_64}"
PROJETO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAVE_REAL="${XDG_DATA_HOME:-$HOME/.local/share}/godot/app_userdata/Koliani/progresso.json"

hash_save() { [ -f "$SAVE_REAL" ] && sha256sum "$SAVE_REAL" | cut -d' ' -f1 || echo "(sem save)"; }

ANTES="$(hash_save)"
SANDBOX="$(mktemp -d -t koliani_testes_XXXXXXXX)"
mkdir -p "$SANDBOX/godot/app_userdata/Koliani"

XDG_DATA_HOME="$SANDBOX" "$GODOT" --headless --path "$PROJETO" res://tests/run_tests.tscn
CODIGO=$?

DEPOIS="$(hash_save)"
rm -rf "$SANDBOX"

if [ "$ANTES" != "$DEPOIS" ]; then
  echo "ERRO: o save real MUDOU durante os testes ($ANTES -> $DEPOIS)" >&2
  exit 1
fi
echo "save real intacto ($ANTES)"
exit $CODIGO
