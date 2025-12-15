@setlocal DisableDelayedExpansion
@echo off
:: Limit the download speed, example: 1M, 500K "empty means unlimited"
set speedLimit=


set "_lst=%~1"
if not defined _lst set "_m=Error: Drag and drop the links text file on this script."&goto :TheEnd

set "_work=%~dp0"
setlocal EnableDelayedExpansion
if not exist "!_lst!" set "_m=Error: links text file is not found."&goto :TheEnd
findstr /i /c:"url http" "!_lst!" 1>nul 2>nul || (set "_m=Error: links text file is not curl format."&goto :TheEnd)
pushd "!_work!"

set _e=0
if exist "curl.exe" set _e=1
for %%i in (curl.exe) do @if not "%%~$PATH:i"=="" set _e=1
if %_e%==0 set "_m=Error: curl.exe is not detected."&goto :TheEnd

echo.
echo Downloading . . .
echo.
if defined speedLimit set "speedLimit=--limit-rate %speedLimit%"
curl.exe -q -R --create-dirs --retry 3 --retry-connrefused %speedLimit% -k -L -C - -K "!_lst!"
set "_m=Done."&goto :TheEnd

:DoD
goto :eof

:TheEnd
echo.&echo %_m%
echo.&echo Press any key to exit.&pause >nul&exit /b
