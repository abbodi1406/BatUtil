@setlocal DisableDelayedExpansion
@echo off
set "_args=%*"
set "_elv="
if not defined _args goto :NoProgArgs
if "%~1"=="" set "_args="&goto :NoProgArgs
set _args=%_args:"=%
for %%A in (%_args%) do (
if /i "%%A"=="-wow" (set _rel1=1) else if /i "%%A"=="-arm" (set _rel2=1) else if /i "%%A"=="-su" (set _elv=1)
)
:NoProgArgs
set "_cmdf=%~f0"
if exist "%SystemRoot%\Sysnative\cmd.exe" if not defined _rel1 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" -wow %*"
exit /b
)
if exist "%SystemRoot%\SysArm32\cmd.exe" if /i %PROCESSOR_ARCHITECTURE%==AMD64 if not defined _rel2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" -arm %*"
exit /b
)
set "SysPath=%SystemRoot%\System32"
set "Path=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%SystemRoot%\Sysnative;%SystemRoot%;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)
set "_err===== ERROR ===="
for /f "tokens=6 delims=[]. " %%# in ('ver') do (
if %%# gtr 14393 goto :E_Win
if %%# lss 10240 goto :E_Win
)
reg query HKU\S-1-5-19 1>nul 2>nul || goto :E_Admin

set "_wrn===== WARNING ===="
set "_WUA=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
set "_CBS=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing"
set "pCBS=%_CBS%\Packages"
set "pPKG=%SystemRoot%\Servicing\Packages"
set "xOS=x64"
set "xBT=amd64"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if not defined PROCESSOR_ARCHITEW6432 (
  set "xOS=x86"
  set "xBT=x86"
  )
)

if exist "%SystemRoot%\WinSxS\pending.xml" (
echo %_wrn%
echo Pending update operation detected.
echo Restart the system first, then run the script.
goto :TheEnd
)
set _ssu=
for /f "skip=2 tokens=2*" %%a in ('reg query "%_CBS%\Version" 2^>nul') do call set "_ssu=%%b"
if not defined _ssu for /f "tokens=1" %%# in ('dir /b "%SystemRoot%\servicing\Version"') do (
for /f %%a in ('dir /b /ad "%SystemRoot%\WinSxS\%xBT%_microsoft-windows-servicingstack_31bf3856ad364e35_%%#_*" 2^>nul') do set "_ssu=%SystemRoot%\WinSxS\%%a"
)
if not defined _ssu (
echo %_err%
echo Failed detecting active servicing stack location.
goto :TheEnd
)
if not exist "%_ssu%\CbsCore.old" if not exist "%SysPath%\crypt96.dll" (
echo %_wrn%
echo Servicing stack is not patched.
goto :TheEnd
)

set "_batf=%~f0"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
setlocal EnableDelayedExpansion
pushd "!_work!"
if not exist "%xOS%\" (
echo %_err%
echo Required folder %xOS% is missing.
goto :TheEnd
)
cd %xOS%\
for %%# in (
NSudoLC.exe bbe.exe crypt96.dll
) do if not exist "%%~#" (
echo %_err%
echo Required file %xOS%\%%~nx# is missing.
goto :TheEnd
)

call :TIcmd 1>nul 2>nul
whoami /USER | find /i "S-1-5-18" 1>nul && (
goto :Begin
) || (
if defined _elv goto :E_TI
net start TrustedInstaller 1>nul 2>nul
1>nul 2>nul NSudoLC.exe -U:T -P:E cmd.exe /c ""!_batf!" -su" &exit /b
)
whoami /USER | find /i "S-1-5-18" 1>nul || goto :E_TI

:Begin
@cls
echo.
choice /C YN /N /M "Restore servicing stack? [y/n]: "
if errorlevel 2 exit

set "_ebak=0x1"
for /f "skip=2 tokens=2*" %%a in ('reg query "%_WUA%" /v AUOptions 2^>nul') do set "_ebak=%%b"
reg query "%_WUA%" /v AUOptions_bak 1>nul 2>nul && for /f "skip=2 tokens=2*" %%a in ('reg query "%_WUA%" /v AUOptions_bak 2^>nul') do set "_ebak=%%b"
reg add "%_WUA%" /f /v AUOptions /t REG_DWORD /d %_ebak% >nul 2>&1
reg delete "%_WUA%" /f /v AUOptions_bak >nul 2>&1
call :StopService BITS >nul 2>&1
call :StopService TrustedInstaller >nul 2>&1
call :StopService wuauserv >nul 2>&1

move /y "%_ssu%\CbsCore.old" "%_ssu%\CbsCore.dll" >nul 2>&1
move /y "%_ssu%\wcp.old" "%_ssu%\wcp.dll" >nul 2>&1
del /f /q "%SysPath%\crypt96.dll" >nul 2>&1

echo.
echo Done.
goto :TheEnd

:StopService
sc query %1 | find /i "STOPPED" || net stop %1 /y
sc query %1 | find /i "STOPPED" || sc stop %1
exit /b

:TIcmd
reg delete HKU\.DEFAULT\Console\^%%SystemRoot^%%_system32_cmd.exe /f
reg add HKU\.DEFAULT\Console /f /v FaceName /t REG_SZ /d Consolas
reg add HKU\.DEFAULT\Console /f /v FontFamily /t REG_DWORD /d 0x36
reg add HKU\.DEFAULT\Console /f /v FontSize /t REG_DWORD /d 0x100000
reg add HKU\.DEFAULT\Console /f /v FontWeight /t REG_DWORD /d 0x190
reg add HKU\.DEFAULT\Console /f /v ScreenBufferSize /t REG_DWORD /d 0x12c0050
exit /b

:E_TI
echo %_err%
echo Failed running the script with TrustedInstaller privileges.
goto :TheEnd

:E_Admin
echo %_err%
echo This script requires administrator privileges.
goto :TheEnd

:E_Win
echo %_err%
echo This script is for Windows 10 1507-1607 only.
goto :TheEnd

:TheEnd
echo.
echo Press any key to exit.
pause >nul
goto :eof
