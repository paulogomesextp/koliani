#!/usr/bin/env bash
# Prova de travessia: a Koliani REAL (fisica, mecanicas, portoes) completa o
# nivel do inicio a' porta final, pilotada pelo bot humano (`bot_humano_r2.gd`).
# Regra do Paulo (30 set 2026): nenhum nivel se junta sem isto a passar.
#
#   tools/correr_travessia.sh <cena.tscn> [perfis...] [tempo_max_s]
#   ex.: tools/correr_travessia.sh res://scenes/levels/Cemiterio_dos_Reis.tscn experiente normal
#
# Sai != 0 se algum perfil nao chegar a' porta. O `user://` e' isolado por
# `tools/godot_isolado.py`. Precisa de GODOT no ambiente (ou no PATH).
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
CENA="$1"; shift
PERFIS=("$@"); [ ${#PERFIS[@]} -eq 0 ] && PERFIS=(experiente normal)
SAIDA="$RAIZ/work/travessia"; mkdir -p "$SAIDA"
nome="$(basename "$CENA" .tscn)"
rc=0
for p in "${PERFIS[@]}"; do
  out="$SAIDA/${nome}_${p}.json"; rm -f "$out"
  python3 "$RAIZ/tools/godot_isolado.py" -- --headless --fixed-fps 60 --path "$RAIZ" \
    --script res://tools/bot_humano_r2.gd -- "$CENA" "$p" 4242 "$out" 600 >/dev/null 2>&1
  python3 - "$out" "$p" <<'PY' || rc=1
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception as e:
    print("FALHOU %s: sem resultado (%s)" % (sys.argv[2], e)); sys.exit(1)
ok = d.get("motivo_fim") == "porta"
print("%s %s: fim=%s tempo=%.0fs mortes=%s x_max=%.0f/%.0f" % (
    "OK   " if ok else "FALHOU", sys.argv[2], d.get("motivo_fim"), d.get("tempo_s", 0),
    d.get("mortes"), d.get("x_max", 0), d.get("x_alvo", 0)))
sys.exit(0 if ok else 1)
PY
done
exit $rc
