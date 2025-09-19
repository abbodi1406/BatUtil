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
if exist "_tmp_*.txt" del /f /q "_tmp_*.txt"
for /f "tokens=2,4 delims==&" %%A in ('findstr /i /c:"getfile\.php" aria2_links.txt') do (
set "_i=%%A"
set "_f=%%B"
call :DoD
)
if exist "_tmp_*.txt" del /f /q "_tmp_*.txt"
echo.
echo Finished.
echo.&echo Press any key to exit.&popd&pause >nul&exit /b

:DoD
if not exist "_tmp_%_i%.txt" (
aria2c.exe --async-dns=false --enable-http-keep-alive=false --conditional-get=true --file-allocation=none -x16 -s16 -c -R --max-overall-download-limit=%_l% -d . -o "_tmp_%_i%.txt" "https://uupdump.net/get.php?id=%_i%&pack=0&simple=1"
)
if not exist "_tmp_%_i%.txt" goto :eof
for /f "tokens=1,3 delims=|" %%G in ('findstr /i /c:"%_f%" _tmp_%_i%.txt') do (
aria2c.exe --async-dns=false --enable-http-keep-alive=false --conditional-get=true --file-allocation=none -x16 -s16 -c -R --max-overall-download-limit=%_l% -d . -o "%%G" "%%H"
)
goto :eof
