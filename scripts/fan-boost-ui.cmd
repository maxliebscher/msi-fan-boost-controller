@echo off
REM Startet die bunte Text-UI für den Fan-Boost Controller
set "SCRIPT_DIR=%~dp0"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" ^
-NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%fan-boost-ui.ps1"
