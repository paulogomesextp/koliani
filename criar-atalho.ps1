# Cria (ou recria) o atalho "Koliani (testar)" no Ambiente de Trabalho.
# Correr uma vez:  powershell -ExecutionPolicy Bypass -File criar-atalho.ps1
$raiz = Split-Path -Parent $MyInvocation.MyCommand.Path
$ws = New-Object -ComObject WScript.Shell
$lnk = $ws.CreateShortcut([IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), 'Koliani (testar).lnk'))
$lnk.TargetPath = Join-Path $raiz 'jogar.bat'
$lnk.WorkingDirectory = $raiz
$lnk.IconLocation = (Join-Path $raiz 'koliani.ico') + ',0'
$lnk.WindowStyle = 7
$lnk.Description = 'Abre o Koliani (codigo atual) para testar'
$lnk.Save()
Write-Host "Atalho criado: $($lnk.FullName)"
