@setlocal DisableDelayedExpansion
@echo off
set _args=
set _args=%*
if not defined _args goto :NoProgArgs
for %%A in (%_args%) do (
if /i "%%A"=="-wow" set _rel1=1
if /i "%%A"=="-arm" set _rel2=1
)
:NoProgArgs
set "_cmdf=%~f0"
if exist "%SystemRoot%\Sysnative\cmd.exe" if not defined _rel1 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" -wow"
exit /b
)
if exist "%SystemRoot%\SysArm32\cmd.exe" if /i %PROCESSOR_ARCHITECTURE%==AMD64 if not defined _rel2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" -arm"
exit /b
)
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
reg query HKU\S-1-5-19 >nul 2>&1 || (
set "msg=ERROR: right click on the script and 'Run as administrator'"
goto :end
)
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
if %winbuild% LSS 7601 (
set "msg=ERROR: Windows 7 SP1 is the minimum supported OS"
goto :end
)
set "_work=%~dp0bin"
setlocal EnableDelayedExpansion
pushd "!_work!"
if not exist "OLicenseCleanup.vbs" (
set "msg=ERROR: required file OLicenseCleanup.vbs is missing"
goto :end
)
set "_Nul1=1>nul"
set "_Nul2=2>nul"
set "_Nul6=2^>nul"
set "_Nul3=1>nul 2>nul"

title Remove Office Subscription Licenses
echo.
echo ============================================================
echo.
echo.
choice /C YN /N /M "Continue with removing Office subscription licenses? [y/n]: "
if errorlevel 2 goto :eof
if errorlevel 1 goto :main

:main
cls
echo.
echo ============================================================
echo Executing OLicenseCleanup.vbs
echo ============================================================
%_Nul3% cscript //Nologo //B OLicenseCleanup.vbs

if %winbuild% GEQ 17133 if exist "WAMAccounts.ps1" (
echo.
echo ============================================================
echo Executing WAMAccounts.ps1
echo ============================================================
%_Nul3% powershell -ep unrestricted -nop -c "try {& .\WAMAccounts.ps1} catch {}"
)
set "msg=Finished. It's recommended to restart the system."
goto :end

:end
echo.
echo ============================================================
echo %msg%
echo ============================================================
echo.
echo Press any key to exit.
pause >nul
goto :eof