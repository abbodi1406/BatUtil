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
for /f "tokens=6 delims=[]. " %%# in ('ver') do (
if %%# geq 9200 goto :E_Win
if %%# lss 7600 goto :E_Win
)

set "IFEO=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
setlocal EnableDelayedExpansion
pushd "!_work!"
if not exist "bin\" goto :E_DLL
for %%# in (
ctrws32.dll
ctrws64.dll
) do (
if not exist "bin\%%~#" (set "_file=%%~nx#"&goto :E_DLL)
)

call :StopService ClickToRunSvc 1>nul 2>nul
echo.
echo Adding Files...
echo %SystemRoot%\System32\ctrws.dll
if exist "%SysPath%\ctrws" del /f /q %SysPath%\ctrws
copy /y bin\ctrws%xOS%.dll %SysPath%\ctrws.dll 1>nul 2>nul
if %xOS%==64 (
echo %SystemRoot%\SysWOW64\ctrws.dll
if exist "%SystemRoot%\SysWOW64\ctrws.dll" del /f /q %SystemRoot%\SysWOW64\ctrws.dll
copy /y bin\ctrws32.dll %SystemRoot%\SysWOW64\ctrws.dll 1>nul 2>nul
)
echo.
echo Adding IFEO Registry Keys...
for %%# in (ODTsetup.exe,OfficeClickToRun.exe) do (
echo [%%#]
call :CreateIFEO %%# 1>nul 2>nul
)
call :StopService ClickToRunSvc 1>nul 2>nul
echo.
echo Done
goto :TheEnd

:CreateIFEO
reg delete "%IFEO%\%1" /f
reg add "%IFEO%\%1" /f /v VerifierDlls /t REG_SZ /d ctrws.dll
reg add "%IFEO%\%1" /f /v VerifierDebug /t REG_DWORD /d 0x00000000
reg add "%IFEO%\%1" /f /v VerifierFlags /t REG_DWORD /d 0x80000000
reg add "%IFEO%\%1" /f /v GlobalFlag /t REG_DWORD /d 0x00000100
goto :eof

:StopService
sc query %1 | find /i "STOPPED" || net stop %1 /y
sc query %1 | find /i "STOPPED" || sc stop %1
taskkill /t /f /IM OfficeC2RClient.exe
taskkill /t /f /IM OfficeClickToRun.exe
goto :eof

:E_DLL
echo %_err%
echo Required file bin\%_file% is missing
goto :TheEnd

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
