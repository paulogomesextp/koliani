@echo off
REM Publica o jogo atual para o playtester: sobe a versao, faz commit e push.
REM O CI (GitHub Actions) exporta o Koliani.exe e atualiza o Release "win-latest".
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publicar.ps1"
echo.
pause
