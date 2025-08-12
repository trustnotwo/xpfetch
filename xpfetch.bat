@echo off
setlocal

REM Define target path
set TARGETDIR=C:\Windows
set BATCHNAME=xpfetch.bat
set SCRIPTNAME=xpfetch_ps.ps1

REM Check if running from C:\Windows
if /I "%~dp0"=="%TARGETDIR%\" goto :RUN

REM If already installed, just run
if exist "%TARGETDIR%\%BATCHNAME%" (
    goto :RUN
)

REM Installer: copy batch and PowerShell script to C:\Windows
echo Installing xpfetch...

copy "%~dp0%BATCHNAME%" "%TARGETDIR%\%BATCHNAME%" >nul
copy "%~dp0%SCRIPTNAME%" "%TARGETDIR%\%SCRIPTNAME%" >nul

echo Installed to %TARGETDIR%
goto :RUN

:RUN
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "%TARGETDIR%\%SCRIPTNAME%"

endlocal
