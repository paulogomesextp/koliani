#!/usr/bin/env bash
# QA da Koliani 3D (Regiao I) -- corre o bot isolado do save real.
# uso: tools/qa_r3d.sh <nivel> [ate] [dir_fotos] [extra...]
N=${1:-1}; ATE=${2:-$N}; FOT=${3:-}; shift 3 2>/dev/null
SB=${QA_SANDBOX:-$TEMP/koliani_qa_r3d_sb}
ARGS="--nivel=$N --ate=$ATE"
[ -n "$FOT" ] && mkdir -p "$FOT" && ARGS="$ARGS --capturas=$FOT"
timeout ${QA_TIMEOUT:-600} python tools/godot_isolado.py --sandbox "$SB" -- --path . --resolution 1280x720 \
  res://scenes/r3d/QA_R3D.tscn -- $ARGS "$@"
