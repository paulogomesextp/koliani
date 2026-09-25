# QA da Regiao I com o `user://` isolado (ver `godot_isolado.py`).
param([string]$Projeto = (Split-Path -Parent $PSScriptRoot))
python (Join-Path $Projeto "tools\godot_isolado.py") -- --headless --path $Projeto "res://tests/qa_regiao1.tscn"
exit $LASTEXITCODE
