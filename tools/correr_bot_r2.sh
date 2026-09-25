#!/usr/bin/env bash
# Bateria de playtest human-like da Regiao II (N05-N10).
#
#   tools/correr_bot_r2.sh <pasta_saida> [tempo_max_jogo_s] [paralelas]
#
# 3 perfis x 3 seeds x 6 niveis = 54 runs. As seeds sao DETERMINISTAS
# (nivel*1000 + perfil*100 + run), portanto a bateria repete-se igual.
#
# O `user://` de CADA run e' isolado por `tools/godot_isolado.py` (APPDATA no
# Windows, XDG no Linux; fail-fast + SHA do save real). NAO usar XDG_DATA_HOME
# a mao: no Windows nao isola nada.
set -u
SAIDA="${1:-work/bot_r2}"
TMAX="${2:-900}"
PAR="${3:-3}"
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
PY="$(command -v python3 || command -v python)"

mkdir -p "$SAIDA"

NIVEIS=(
  "n05:res://scenes/levels/Coracao_da_Floresta.tscn"
  "n06:res://scenes/levels/Prisao_dos_Condenados.tscn"
  "n07:res://scenes/levels/Fornalha_dos_Pecadores.tscn"
  "n08:res://scenes/levels/Corredor_das_Execucoes.tscn"
  "n09:res://scenes/levels/Ala_dos_Mortos.tscn"
  "n10:res://scenes/levels/A_Cela_Zero.tscn"
)
PERFIS=(casual normal experiente)

i=0
for entrada in "${NIVEIS[@]}"; do
  nome="${entrada%%:*}"
  cena="${entrada#*:}"
  idx=$((10#${nome#n}))
  p=0
  for perfil in "${PERFIS[@]}"; do
    for run in 0 1 2; do
      seed=$((idx * 1000 + p * 100 + run))
      out="$SAIDA/${nome}_${perfil}_${run}.json"
      # cada run tem o seu `user://`: mortes gravam o save, e runs em
      # paralelo a partilhar o mesmo ficheiro contaminavam-se umas as outras
      (
        "$PY" "$RAIZ/tools/godot_isolado.py" -- --headless --fixed-fps 60 --path "$RAIZ" \
          --script res://tools/bot_humano_r2.gd -- \
          "$cena" "$perfil" "$seed" "$out" "$TMAX" >/dev/null 2>&1
        rc=$?
        [ $rc -ge 96 ] && echo "  ERRO isolamento/save ($rc) $nome $perfil #$run" || echo "  ok $nome $perfil #$run (seed $seed)"
      ) &
      i=$((i + 1))
      if [ $((i % PAR)) -eq 0 ]; then wait; fi
    done
    p=$((p + 1))
  done
done
wait
echo "runs: $(ls -1 "$SAIDA"/*.json 2>/dev/null | wc -l)"
