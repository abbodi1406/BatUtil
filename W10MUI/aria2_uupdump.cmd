@echo off
:: Limit the download speed, example: 1M, 500K "0 = unlimited"
set "_l=0"

set "_work=%~dp0"
setlocal EnableDelayedExpansion
pushd "!_work!"
set _e=0
if exist "aria2c.exe" set _e=1
for %%i in (aria2c.exe) do @if not "%%~$PATH:i"=="" set _e=1
if %_e%==0 echo.&echo Error: aria2c.exe is not detected&echo.&popd&pause&exit /b
if not exist "aria2_links.txt" echo.&echo Error: aria2_links.txt is not found&echo.&popd&pause&exit /b
echo.
echo Downloading...
for /f "usebackq tokens=* delims=" %%A in ("aria2_links.txt") do (
set "_u=%%A"
for /f "tokens=3 delims==" %%# in ("%%~A") do set "_f=%%#"
call :DoD
)
echo.
echo Finished.
echo.&echo Press any key to exit.&popd&pause >nul&exit /b

:DoD
ping -n 5 localhost >nul && aria2c.exe --async-dns=false --enable-http-keep-alive=false --conditional-get=true --file-allocation=none -x16 -s16 -c -R --max-overall-download-limit=%_l% -d . -o "%_f%" "%_u%"
goto :eof
