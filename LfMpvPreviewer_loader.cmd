@echo off

REM Powershell 5/6
REM powershell -NoProfile -File %~dp0\MpvPreviewer.ps1 %0 %1 %2 %3 %4 %5 %6 %7 %8

REM Powershell 7+
pwsh -NoProfile -File %~dp0\LfMpvPreviewer.ps1 %0 %1 %2 %3 %4 %5 %6 %7 %8
REM disable lf preview cache
exit /b 1