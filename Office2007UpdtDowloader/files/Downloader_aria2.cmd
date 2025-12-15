@setlocal DisableDelayedExpansion
@echo off
:: Limit the download speed, example: 1M, 500K "0 = unlimited"
set "speedLimit=0"

:: Set the number of parallel downloads
set "parallel=1"


set "_lst=%~1"
if not defined _lst set "_m=Error: Drag and drop the links text file on this script."&goto :TheEnd

set "_work=%~dp0"
setlocal EnableDelayedExpansion
if not exist "!_lst!" set "_m=Error: links text file is not found."&goto :TheEnd
findstr /i "out=" "!_lst!" 1>nul 2>nul || (set "_m=Error: links text file is not aria2 format."&goto :TheEnd)
pushd "!_work!"

set _e=0
if exist "aria2c.exe" set _e=1
for %%i in (aria2c.exe) do @if not "%%~$PATH:i"=="" set _e=1
if %_e%==0 set "_m=Error: aria2c.exe is not detected."&goto :TheEnd

echo.
echo Downloading . . .
aria2c.exe --conditional-get=true --file-allocation=none -x16 -s16 -j %parallel% -c -R --max-overall-download-limit=%speedLimit% -d . -i "!_lst!"
set "_m=Done."&goto :TheEnd

:DoD
goto :eof

:TheEnd
echo.&echo %_m%
echo.&echo Press any key to exit.&pause >nul&exit /b
