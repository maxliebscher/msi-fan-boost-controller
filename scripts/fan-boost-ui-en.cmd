@echo off
REM Start the colorful terminal UI in English
setlocal
set "SCRIPT_DIR=%~dp0"
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "UI_SCRIPT=%SCRIPT_DIR%fan-boost-ui.ps1"

if not exist "%UI_SCRIPT%" (
    echo %UI_SCRIPT% not found.
    pause
    exit /b 1
)

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%UI_SCRIPT%" -Language en-US
