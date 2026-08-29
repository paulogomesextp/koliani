# Publica o estado atual do jogo para o playtester (o amigo do Paulo).
#
#   1. sobe o patch de `config/version` em project.godot  (0.1.0 -> 0.1.1)
#   2. git commit de tudo o que esteja por guardar
#   3. git push  ->  o CI corre os testes, exporta o Koliani.exe e
#      atualiza o Release "win-latest" (o link que o amigo tem).
#
# Correr:  clicar duas vezes em publicar.bat
#     (ou:  powershell -ExecutionPolicy Bypass -File publicar.ps1)

$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $raiz

# --- 1. bump da versao -----------------------------------------------------
$proj  = Join-Path $raiz 'project.godot'
$texto = Get-Content $proj -Raw
if ($texto -notmatch 'config/version="(\d+)\.(\d+)\.(\d+)"') {
    Write-Host "Nao encontrei config/version em project.godot. A abortar." -ForegroundColor Red
    exit 1
}
$maj = [int]$Matches[1]
$min = [int]$Matches[2]
$pat = [int]$Matches[3] + 1
$nova = "$maj.$min.$pat"
$texto = $texto -replace 'config/version="\d+\.\d+\.\d+"', "config/version=""$nova"""
[System.IO.File]::WriteAllText($proj, $texto, (New-Object System.Text.UTF8Encoding $false))
Write-Host "Versao  ->  $nova" -ForegroundColor Cyan

# --- 2. commit -----------------------------------------------------------
git add -A
git commit -m "playtest v$nova"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Nada de novo para publicar (nenhum ficheiro alterado)." -ForegroundColor Yellow
    # desfaz o bump da versao, ja que nao vai haver commit
    git checkout -- project.godot
    exit 0
}

# --- 3. push -----------------------------------------------------------
git push
if ($LASTEXITCODE -ne 0) {
    Write-Host "O push falhou -- verifica a ligacao / login do GitHub." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Publicado. Daqui a ~5-10 min o CI atualiza o link do amigo:" -ForegroundColor Green
Write-Host "  https://github.com/paulogomesextp/koliani/releases/tag/win-latest"
Write-Host "  (versao v$nova -- aparece no canto do menu)"
