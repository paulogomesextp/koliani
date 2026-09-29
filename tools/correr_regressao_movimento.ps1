# REGRESSAO DO MOVIMENTO (F1). Corre a bancada em modo `regressao` e sai != 0
# se algum limite da passagem 1 falhar. Isolada (nao toca no save real).
# Demora alguns minutos (envolvente de salto incluida).
param([string]$Projeto = (Split-Path -Parent $PSScriptRoot),
      [string]$Saida = (Join-Path $env:TEMP "f1_regressao.json"))
python (Join-Path $Projeto "tools\godot_isolado.py") -- --headless --fixed-fps 60 --path $Projeto "res://tools/bench_movimento_f1.tscn" -- $Saida regressao
exit $LASTEXITCODE
