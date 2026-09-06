@echo off
REM Abre a build Windows local exportada. O atalho no Ambiente de
REM Trabalho aponta para este ficheiro, por isso cada exportacao fica logo
REM disponivel sem abrir o editor Godot.
set "JOGO=%~dp0build\windows\Koliani.exe"
if not exist "%JOGO%" (
  echo Executavel nao encontrado em "%JOGO%".
  echo Exporta o preset Windows Desktop para build\windows\Koliani.exe.
  pause
  exit /b 1
)
start "" "%JOGO%"
