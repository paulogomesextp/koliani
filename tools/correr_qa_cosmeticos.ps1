# QA VISUAL + PERSISTENCIA DOS COSMETICOS DA LOJA, em janela real (renderer
# verdadeiro; --headless nao serve, o renderer e' dummy).
#
# Isolamento: o `user://` do Godot resolve por %APPDATA%; aponta-se a uma pasta
# descartavel NOVA em cada corrida (sem estado da anterior) e confirma-se por
# SHA256 que o save real ficou intacto. O saldo de teste e' semeado la' dentro
# pelo modo `semear` -- nada disto existe no runtime normal.
# Capturas: <sandbox>\Godot\app_userdata\Koliani\qa_cosm\*.png (mantidas com -Manter).
#
# Uso:  powershell -ExecutionPolicy Bypass -File tools\correr_qa_cosmeticos.ps1
param(
  [string]$Godot = "C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64_console.exe",
  [string]$Projeto = (Split-Path -Parent $PSScriptRoot),
  [switch]$Manter
)
$ErrorActionPreference = 'Continue'   # o Godot escreve avisos em stderr
$sandbox  = Join-Path ([IO.Path]::GetTempPath()) ("kolqa_" + [Guid]::NewGuid().ToString("N").Substring(0, 8))
$saveReal = Join-Path $env:APPDATA "Godot\app_userdata\Koliani\progresso.json"
function Hash-Save { if (Test-Path $saveReal) { (Get-FileHash $saveReal -Algorithm SHA256).Hash } else { "(sem save)" } }
$antes = Hash-Save
New-Item -ItemType Directory -Force -Path (Join-Path $sandbox "Godot\app_userdata\Koliani") | Out-Null
$antigo = $env:APPDATA
$falhou = $false
function Correr($cena, $extra) {
  $args = @('--path', $Projeto, '--windowed', '--resolution', '1280x720', '--screen', '1', $cena) + $extra
  $saida = & $Godot @args 2>&1 | Where-Object { $_ -match '^(PASS|FALHOU|INFO|QA)' }
  $saida | ForEach-Object { Write-Output $_ }
  if ($LASTEXITCODE -ne 0 -or ($saida -match '^FALHOU')) { $script:falhou = $true }
}
try {
  $env:APPDATA = $sandbox
  Write-Output "== sandbox: $sandbox"
  Correr 'res://tests/qa_cosm_persist.tscn' @('--', 'semear')
  Correr 'res://tests/qa_cosmeticos_visual.tscn' @()
  # persistencia entre PROCESSOS: cada fase e' um Godot novo
  Correr 'res://tests/qa_cosm_persist.tscn' @('--', 'compra')
  Correr 'res://tests/qa_cosm_persist.tscn' @('--', 'verifica')
  Correr 'res://tests/qa_cosm_persist.tscn' @('--', 'desequipa')
  Correr 'res://tests/qa_cosm_persist.tscn' @('--', 'default')
  Correr 'res://tests/qa_loja_colecao_visual.tscn' @()
  Correr 'res://tests/qa_rootbound_visual.tscn' @()
} finally { $env:APPDATA = $antigo }
$depois = Hash-Save
if ($antes -ne $depois) { Write-Output "ERRO: o save real mudou ($antes -> $depois)"; $falhou = $true }
else { Write-Output "save real intacto ($depois)" }
if ($Manter) { Write-Output "capturas em $sandbox" } else { Remove-Item $sandbox -Recurse -Force -ErrorAction SilentlyContinue }
if ($falhou) { Write-Output "QA COSMETICOS (total): FAIL"; exit 1 }
Write-Output "QA COSMETICOS (total): PASS"
