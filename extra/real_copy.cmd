@echo off
REM add line below to lfrc
REM map <c-c> ${{"PATH\TO\THE\real_copy.cmd" %f%}}

REM Powershell 5/6
powershell -NoProfile -File %~dp0\real_copy.ps1 -inputFile %1 >nul 2>&1
REM
if %errorlevel% equ 0 (
    exit /b 0
)

exit /b