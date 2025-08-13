@echo off
setlocal

REM Define target path
set TARGETDIR=C:\Windows
set BATCHNAME=xpfetch.bat
set SCRIPTNAME=xpfetch_ps.ps1
set CONFIGNAME=xpconf.ini

REM Check if running from C:\Windows
if /I "%~dp0"=="%TARGETDIR%\" goto :RUN

REM If already installed, just run
if exist "%TARGETDIR%\%BATCHNAME%" (
    goto :RUN
)

REM Installer: copy batch and PowerShell script to C:\Windows
echo Installing xpfetch...

mkdir "%APPDATA%\xpfetch" 2>nul
copy "%~dp0%BATCHNAME%" "%TARGETDIR%\%BATCHNAME%" >nul
copy "%~dp0%SCRIPTNAME%" "%APPDATA%\xpfetch\%SCRIPTNAME%" >nul
copy "%~dp0%CONFIGNAME%" "%APPDATA%\xpfetch\%CONFIGNAME%" >nul

echo Installed to %TARGETDIR%
goto :RUN

:RUN
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%APPDATA%\xpfetch\%SCRIPTNAME%'"

endlocal
