@echo off
REM Abre o Koliani a correr o codigo atual (nao precisa de reexportar).
REM O atalho no Ambiente de Trabalho aponta para aqui.
set "GODOT=C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" (
  echo Godot nao encontrado em "%GODOT%".
  echo Ajusta o caminho no cimo deste ficheiro ^(jogar.bat^).
  pause
  exit /b 1
)
start "" "%GODOT%" --path "%~dp0."
