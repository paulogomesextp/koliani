# Cria (ou recria) os atalhos do Koliani no Ambiente de Trabalho:
#   - "Koliani (testar)"   -> abre o jogo no codigo atual
#   - "Publicar Koliani"   -> sobe versao + commit + push (build para o amigo)
# Correr uma vez:  powershell -ExecutionPolicy Bypass -File criar-atalho.ps1
$raiz = Split-Path -Parent $MyInvocation.MyCommand.Path
$ws = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath('Desktop')

$lnk = $ws.CreateShortcut([IO.Path]::Combine($desktop, 'Koliani (testar).lnk'))
$lnk.TargetPath = Join-Path $raiz 'jogar.bat'
$lnk.WorkingDirectory = $raiz
$lnk.IconLocation = (Join-Path $raiz 'koliani.ico') + ',0'
$lnk.WindowStyle = 7
$lnk.Description = 'Abre o Koliani (codigo atual) para testar'
$lnk.Save()
Write-Host "Atalho criado: $($lnk.FullName)"

$pub = $ws.CreateShortcut([IO.Path]::Combine($desktop, 'Publicar Koliani.lnk'))
$pub.TargetPath = Join-Path $raiz 'publicar.bat'
$pub.WorkingDirectory = $raiz
$pub.IconLocation = (Join-Path $raiz 'koliani.ico') + ',0'
$pub.Description = 'Sobe a versao, faz commit e push -> atualiza a build do playtester'
$pub.Save()
Write-Host "Atalho criado: $($pub.FullName)"
