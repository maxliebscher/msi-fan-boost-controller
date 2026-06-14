@echo off
REM Convenience launcher for users who download the repository as a ZIP.
setlocal
set "SCRIPT_DIR=%~dp0"
set "UI_SCRIPT=%SCRIPT_DIR%scripts\fan-boost-ui.ps1"
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

if not exist "%UI_SCRIPT%" (
    echo %UI_SCRIPT% not found.
    pause
    exit /b 1
)

"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%UI_SCRIPT%"
