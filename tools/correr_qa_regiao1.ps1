# QA da Região I com o `user://` isolado (ver `correr_testes.ps1`).
param(
  [string]$Godot = "C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64_console.exe",
  [string]$Projeto = (Split-Path -Parent $PSScriptRoot)
)
$sandbox  = Join-Path ([IO.Path]::GetTempPath()) ("koliani_qa_" + [Guid]::NewGuid().ToString("N").Substring(0, 8))
$saveReal = Join-Path $env:APPDATA "Godot\app_userdata\Koliani\progresso.json"
$antes = if (Test-Path $saveReal) { (Get-FileHash $saveReal).Hash } else { "(sem save)" }
New-Item -ItemType Directory -Force -Path (Join-Path $sandbox "Godot\app_userdata\Koliani") | Out-Null
$antigo = $env:APPDATA
try { $env:APPDATA = $sandbox; & $Godot --headless --path $Projeto "res://tests/qa_regiao1.tscn"; $codigo = $LASTEXITCODE }
finally { $env:APPDATA = $antigo }
$depois = if (Test-Path $saveReal) { (Get-FileHash $saveReal).Hash } else { "(sem save)" }
if ($antes -ne $depois) { Write-Output "ERRO: save real mexido"; exit 1 }
Write-Output "save real intacto ($depois)"
Remove-Item $sandbox -Recurse -Force -ErrorAction SilentlyContinue
exit $codigo
