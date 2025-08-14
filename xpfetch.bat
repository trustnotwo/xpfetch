@echo off
setlocal

REM Define target paths
set "TARGETDIR=C:\Windows"
set "BATCHNAME=xpfetch.bat"
set "SCRIPTNAME=xpfetch_ps.ps1"
set "CONFIGNAME=xpconf.ini"
set "INSTALLDIR=%APPDATA%\xpfetch"

REM If running from C:\Windows, skip copying
if /I "%~dp0"=="%TARGETDIR%\" goto RUN

REM If running from a fresh folder (has .bat, .ps1, .ini together), overwrite installed files
if exist "%~dp0%SCRIPTNAME%" copy /y "%~dp0%SCRIPTNAME%" "%INSTALLDIR%\%SCRIPTNAME%" >nul
if exist "%~dp0%CONFIGNAME%" copy /y "%~dp0%CONFIGNAME%" "%INSTALLDIR%\%CONFIGNAME%" >nul
if exist "%~dp0%BATCHNAME%" copy /y "%~dp0%BATCHNAME%" "%TARGETDIR%\%BATCHNAME%" >nul

:RUN
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%INSTALLDIR%\%SCRIPTNAME%'"

endlocal
