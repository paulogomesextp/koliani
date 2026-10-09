#!/usr/bin/env bash
# Exporta o build Windows de QA da Koliani 3D (Regiao I) com o SHA do HEAD
# visivel em jogo ("KOLIANI 3D REGION I build=<sha>").
# uso: tools/exportar_r3d_qa.sh [saida.exe]
set -e
SAIDA=${1:-/c/Projetos/koliani/build/qa/Koliani-3D-Region01-QA.exe}
GODOT="/c/Users/paulo/Desktop/Godot_v4.7.2-stable_win64_console.exe"
SHA=$(git rev-parse --short HEAD)
printf 'extends RefCounted\n## Gerado por tools/exportar_r3d_qa.sh -- nao editar.\nconst SHA := "%s"\n' "$SHA" > scripts/r3d/build_id.gd
mkdir -p "$(dirname "$SAIDA")"
timeout 600 "$GODOT" --headless --path . --import >/dev/null 2>&1 || true
timeout 900 "$GODOT" --headless --path . --export-release "Windows Desktop" "$SAIDA" 2>&1 | grep -iv "BUG: Unref\|RID alloc" | grep -i "error\|export" | head -20
ls -la "$(dirname "$SAIDA")"
echo "BUILD KOLIANI 3D REGION I build=$SHA -> $SAIDA"
