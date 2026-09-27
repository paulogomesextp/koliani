# CORRER A SUITE SEM TOCAR NO SAVE REAL.
# Isolamento e verificacao de SHA vivem em `tools/godot_isolado.py` (unica
# estrategia do projecto: no Windows o `user://` resolve por %APPDATA%, NAO por
# XDG_DATA_HOME). Sai com o codigo da suite (98 = save real alterado, 97 =
# isolamento impossivel).
#
# PREFLIGHT (incidente "cache de classes", 27 set 2026): um `class_name` novo
# ou apagado so' fica visivel a outros scripts depois de o Godot reescrever
# `.godot/global_script_class_cache.cfg` -- e isso so' acontece com um
# `--headless --import`. Sem isto, um script que referencie a classe nova
# falha a compilar; se for uma classe-base (ex. `chefe_base.gd`), arrasta
# consigo TODOS os que dela herdam com o sintoma enganador "Nonexistent
# function '_process' in base 'Nil'" -- pareceu uma regressao de 79 testes
# quando era so' a cache por atualizar. Por isso corre-se SEMPRE o import
# aqui, incondicional (e' barato e idempotente) -- nao depender de alguem se
# lembrar de abrir o editor primeiro.
param([string]$Projeto = (Split-Path -Parent $PSScriptRoot))
$Godot = if ($env:GODOT) { $env:GODOT } else { "C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64_console.exe" }
if (-not (Test-Path $Godot)) { $Godot = "godot" }
& $Godot --headless --import --path $Projeto | Out-Null
python (Join-Path $Projeto "tools\godot_isolado.py") -- --headless --path $Projeto "res://tests/run_tests.tscn"
exit $LASTEXITCODE
