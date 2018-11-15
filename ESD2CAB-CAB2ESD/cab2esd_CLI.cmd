@echo off
set compress=MAX
:: remove :: from below line to get solid ESD (require high amount of CPU/RAM)
:: set compress=LZMS

title CAB -^> ESD
cd /d "%~dp0"
if /i "%PROCESSOR_ARCHITECTURE%" equ "AMD64" (set "arch=x64") else (set "arch=x86")
for %%A in (image%arch%.exe,cabarc.exe) do (
if not exist "bin\%%A" (set "MESSEGE=%%A is not detected."&goto :fin)
)
if not exist "*.cab" (set "MESSEGE=No .cab files detected."&goto :fin)
for %%p in ("bin\image%arch%.exe") do set "IMAGEX=%%~fp"
for %%p in ("bin\cabarc.exe") do set "CABARC=%%~fp"
set "tempdir=temp%random%"
for /f "delims=" %%i in ('dir /b *.cab') do call :cabesd "%%i"
set "MESSEGE=Done."
goto :fin

:cabesd
set "pack=%~n1"
if exist "%pack%.esd" goto :eof
echo.
echo ============================================================
echo Expand: %pack%.cab
echo ============================================================
rd /s /q "%tempdir%" >nul 2>&1
md "%tempdir%"
expand.exe -f:* "%~1" "%tempdir%" >nul
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (set "MESSEGE=Errors were reported during process."&goto :fin)
echo.
echo ============================================================
echo Create: %pack%.esd
echo ============================================================
"%IMAGEX%" /CAPTURE "%tempdir%" %pack%.esd "%pack%" "%pack%" /COMPRESS %compress% /NORPFIX /NOACL ALL /NOTADMIN /TEMP "%temp%" >nul
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (set "MESSEGE=Errors were reported during process."&goto :fin)
rd /s /q "%tempdir%" >nul 2>&1
goto :eof

:fin
cd /d "%~dp0"
rd /s /q "%tempdir%" >nul 2>&1
echo.
echo ============================================================
echo %MESSEGE%
echo ============================================================
echo.
echo Press any key to exit...
pause >nul
exit