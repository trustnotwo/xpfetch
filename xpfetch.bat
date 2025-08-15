@echo off
setlocal

set "TARGETDIR=C:\Windows"
set "BATCHNAME=xpfetch.bat"
set "SCRIPTNAME=xpfetch_ps.ps1"
set "CONFIGNAME=xpconf.ini"
set "INSTALLDIR=%APPDATA%\xpfetch"
set "LOGODIR=logos"

if /I "%~dp0"=="%TARGETDIR%\" goto RUN

if not exist "%INSTALLDIR%" mkdir "%INSTALLDIR%" >nul

if exist "%~dp0%SCRIPTNAME%" copy /y "%~dp0%SCRIPTNAME%" "%INSTALLDIR%\%SCRIPTNAME%" >nul
if exist "%~dp0%CONFIGNAME%" copy /y "%~dp0%CONFIGNAME%" "%INSTALLDIR%\%CONFIGNAME%" >nul
if exist "%~dp0%BATCHNAME%" copy /y "%~dp0%BATCHNAME%" "%TARGETDIR%\%BATCHNAME%" >nul

if exist "%~dp0%LOGODIR%" xcopy /e /i /y "%~dp0%LOGODIR%" "%INSTALLDIR%\%LOGODIR%" >nul

:RUN
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command " & { & '%INSTALLDIR%\%SCRIPTNAME%' }"

endlocal
