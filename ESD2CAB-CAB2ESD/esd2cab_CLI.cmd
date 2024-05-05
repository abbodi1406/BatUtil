@echo off
title ESD -^> CAB
set unattend=0
if not "%~1"=="" set unattend=1
cd /d "%~dp0"
if /i "%PROCESSOR_ARCHITECTURE%" equ "AMD64" (set "arch=x64") else (set "arch=x86")
for %%A in (image%arch%.exe,cabarc.exe,SxSExpand.exe) do (
if not exist "bin\%%A" (set "MESSEGE=%%A is not detected."&goto :fin)
)
if not exist "*.esd" (set "MESSEGE=No .esd files detected."&goto :fin)
for %%p in ("bin\image%arch%.exe") do set "IMAGEX=%%~fp"
for %%p in ("bin\cabarc.exe") do set "CABARC=%%~fp"
for %%p in ("bin\SxSExpand.exe") do set "SXS=%%~fp"
set "tempdir=temp%random%"
for /f "delims=" %%i in ('dir /b /a:-d *.esd') do call :esdcab "%%i"
set "MESSEGE=Done."
SET ERRORTEMP=0
goto :fin

:esdcab
set "pack=%~n1"
if exist "%pack%.cab" goto :eof
echo.
echo ============================================================
echo Expand: %pack%.esd
echo ============================================================
rd /s /q "%tempdir%" >nul 2>&1
md "%tempdir%"
"%IMAGEX%" /APPLY "%~1" 1 "%tempdir%" /NOACL ALL /NOTADMIN /TEMP "%temp%" >nul
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (set "MESSEGE=Errors were reported during process."&goto :fin)
echo.
echo ============================================================
echo Create: %pack%.cab
echo ============================================================
pushd "%tempdir%"
md _sxs
for /f %%a in ('dir /b /a:-d *.manifest') do ("%SXS%" %%a _sxs\%%a >nul)
if exist "_sxs\*.manifest" move /y _sxs\* . >nul
rd /s /q _sxs\
"%CABARC%" -m LZX:21 -r -p N "%~dp0%pack%.cab" *.* >nul
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (set "MESSEGE=Errors were reported during process."&goto :fin)
popd
rd /s /q "%tempdir%" >nul 2>&1
goto :eof

:fin
cd /d "%~dp0"
rd /s /q "%tempdir%" >nul 2>&1
IF NOT DEFINED ERRORTEMP SET ERRORTEMP=1
echo.
echo ============================================================
echo %MESSEGE%
echo ============================================================
echo.
if %unattend% neq 1 (
echo Press any key to exit...
pause >nul
)
exit /b %ERRORTEMP%
