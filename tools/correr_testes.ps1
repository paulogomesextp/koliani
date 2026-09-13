# CORRER A SUITE SEM TOCAR NO SAVE REAL (9H.17 CONTINUATION).
#
# PORQUE E' QUE ISTO EXISTE
#
# A suite headless ESCREVE no save real. Descobriu-se da pior maneira: a
# campanha do Paulo (nivel 1-5, 239 de essencia) ficou com a essencia a
# zero depois de duas corridas de testes. O cabecalho do `run_tests.gd` diz
# que os testes de save usam uma copia de `estado_jogo.gd` para nao tocar no
# ficheiro real, e isso e' verdade PARA ESSES testes -- mas o autoload
# `EstadoJogo` continua vivo na cena de testes, e basta um teste mexer-lhe
# e outro provocar uma gravacao para o save do jogador ir atras.
#
# A correccao nao e' mexer nos testes um a um: e' nao os deixar ver o save.
# No Windows o `user://` do Godot resolve por %APPDATA%, por isso lancar o
# motor com o APPDATA apontado a uma pasta descartavel isola tudo -- save,
# opcoes, capturas -- sem uma linha de codigo do jogo alterada.
#
# Uso:
#   pwsh tools\correr_testes.ps1
#
# Sai com o mesmo codigo que a suite (0 = tudo passou).

param(
  [string]$Godot = "C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64_console.exe",
  [string]$Projeto = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$sandbox  = Join-Path ([IO.Path]::GetTempPath()) ("koliani_testes_" + [Guid]::NewGuid().ToString("N").Substring(0, 8))
$saveReal = Join-Path $env:APPDATA "Godot\app_userdata\Koliani\progresso.json"

function Hash-Save {
  if (Test-Path $saveReal) { return (Get-FileHash $saveReal -Algorithm SHA256).Hash }
  return "(sem save)"
}

$antes = Hash-Save
New-Item -ItemType Directory -Force -Path (Join-Path $sandbox "Godot\app_userdata\Koliani") | Out-Null

$antigo = $env:APPDATA
try {
  $env:APPDATA = $sandbox
  & $Godot --headless --path $Projeto "res://tests/run_tests.tscn"
  $codigo = $LASTEXITCODE
} finally {
  $env:APPDATA = $antigo
}

$depois = Hash-Save
if ($antes -ne $depois) {
  Write-Output ""
  Write-Output "ERRO: a suite mexeu no save real apesar do isolamento."
  Write-Output "  antes  = $antes"
  Write-Output "  depois = $depois"
  Remove-Item $sandbox -Recurse -Force -ErrorAction SilentlyContinue
  exit 1
}

Write-Output ""
Write-Output "save real intacto ($depois)"
Remove-Item $sandbox -Recurse -Force -ErrorAction SilentlyContinue
exit $codigo
