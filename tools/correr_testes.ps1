# CORRER A SUITE SEM TOCAR NO SAVE REAL.
# Isolamento e verificacao de SHA vivem em `tools/godot_isolado.py` (unica
# estrategia do projecto: no Windows o `user://` resolve por %APPDATA%, NAO por
# XDG_DATA_HOME). Sai com o codigo da suite (98 = save real alterado, 97 =
# isolamento impossivel).
param([string]$Projeto = (Split-Path -Parent $PSScriptRoot))
python (Join-Path $Projeto "tools\godot_isolado.py") -- --headless --path $Projeto "res://tests/run_tests.tscn"
exit $LASTEXITCODE
