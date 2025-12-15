@setlocal DisableDelayedExpansion
@echo off
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "_err===== ERROR ===="
set "xOS=64"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if not defined PROCESSOR_ARCHITEW6432 (
  set "xOS=32"
  )
)

reg query HKU\S-1-5-19 1>nul 2>nul || goto :E_Admin
:: for /f "tokens=6 delims=[]. " %%# in ('ver') do (
:: if %%# geq 9200 goto :E_Win
:: if %%# lss 7600 goto :E_Win
:: )

set "IFEO=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
setlocal EnableDelayedExpansion
pushd "!_work!"
call :StopService ClickToRunSvc 1>nul 2>nul
reg delete "%IFEO%\ODTsetup.exe" /f 1>nul 2>nul
reg delete "%IFEO%\OfficeClickToRun.exe" /f 1>nul 2>nul
if exist "%SysPath%\ctrws.dll" del /f /q %SysPath%\ctrws.dll
if exist "%SystemRoot%\SysWOW64\ctrws.dll" del /f /q %SystemRoot%\SysWOW64\ctrws.dll
call :StopService ClickToRunSvc 1>nul 2>nul
echo.
echo Done
goto :TheEnd

:StopService
sc query %1 | find /i "STOPPED" || net stop %1 /y
sc query %1 | find /i "STOPPED" || sc stop %1
taskkill /t /f /IM OfficeC2RClient.exe
taskkill /t /f /IM OfficeClickToRun.exe
goto :eof

:E_Admin
echo %_err%
echo This script requires administrator privileges
goto :TheEnd

:E_Win
echo %_err%
echo This project is only for Windows 7 SP1

:TheEnd
echo.
echo Press any key to exit.
pause >nul
goto :eof
