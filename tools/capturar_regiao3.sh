#!/usr/bin/env bash
# Captura PNGs reais dos niveis da Regiao III para a prova de fidelidade
# (Fase 9). Precisa de framebuffer -- aqui usa-se o Xvfb, que nao exige
# ecra fisico. Isola o `user://` como o `correr_testes.sh`.
#
# Uso: tools/capturar_regiao3.sh <pasta_destino> [sufixo]
set -uo pipefail
# So' Linux (xvfb-run). XDG_DATA_HOME NAO isola nada no Windows -- aqui recusa
# em vez de escrever no save real. Em Windows usar `tools/godot_isolado.py`.
case "$(uname -s)" in Linux) ;; *) echo "capturar_regiao3.sh: so' Linux; no Windows use tools/godot_isolado.py" >&2; exit 97;; esac
GODOT="${GODOT:-/tmp/godot/Godot_v4.7.2-stable_linux.x86_64}"
PROJETO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:?falta a pasta de destino}"; SUF="${2:-}"
mkdir -p "$DEST"

# nivel:cena:x_da_camera (vazio = sala do chefe; negativo = jornada)
ALVOS=(
  "n11:Torre_dos_Sinos:"        "n12:Torre_dos_Ventos:"
  "n13:Torre_da_Tempestade:"    "n14:Observatorio_Lunar:"
  "n15:O_Pico_Esquecido:"
)
for alvo in "${ALVOS[@]}"; do
  IFS=: read -r nome cena kx <<<"$alvo"
  SB="$(mktemp -d)"; mkdir -p "$SB/godot/app_userdata/Koliani"
  XDG_DATA_HOME="$SB" timeout 240 xvfb-run -a -s "-screen 0 1920x1080x24" \
    "$GODOT" --rendering-driver opengl3 --resolution 1280x720 --path "$PROJETO" \
    --script res://tools/shot_plataforma.gd -- \
    "res://scenes/levels/$cena.tscn" "user://shot.png" 3.0 ${kx:+$kx} >/dev/null 2>&1
  if [ -f "$SB/godot/app_userdata/Koliani/shot.png" ]; then
    cp "$SB/godot/app_userdata/Koliani/shot.png" "$DEST/${nome}${SUF}.png"
    echo "ok  $nome -> $DEST/${nome}${SUF}.png"
  else
    echo "FALHOU  $nome"
  fi
  rm -rf "$SB"
done
