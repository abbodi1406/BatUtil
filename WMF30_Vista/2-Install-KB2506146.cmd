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
set "Path=%SystemRoot%\System32;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)
set "_err===== ERROR ===="
for /f "tokens=6 delims=[]. " %%# in ('ver') do (
if %%# gtr 6100 goto :E_Win
if %%# lss 6002 goto :E_Win
)
reg query HKU\S-1-5-19 1>nul 2>nul || goto :E_Admin

set "_wrn===== WARNING ===="
set "pPKG=%SystemRoot%\Servicing\Packages"
set "xOS=x64"
set "xBT=amd64"
set "xSU=x64\NSudoLC.exe"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if not defined PROCESSOR_ARCHITEW6432 (
  set "xOS=x86"
  set "xBT=x86"
  set "xSU=x86\NSudoLC.exe"
  )
)
if exist "%pPKG%\Microsoft-Windows-Server-LanguagePack-Package~*.mum" goto :E_Win

if exist "%pPKG%\Microsoft-Windows-PowerShell-Client-WTR-Package*7.1.6002.16398.mum" (
echo %_wrn%
echo WMF 3.0 ^(KB2506146^) is already installed.
goto :TheEnd
)
if not exist "%pPKG%\Windows-Management-Framework-Core~*.mum" (
echo %_wrn%
echo WMF 2.0 ^(KB968930^) prerequisite is not installed.
goto :TheEnd
)
if not exist "%pPKG%\Windows-Management-Framework-BITS~*.mum" (
echo %_wrn%
echo BITS 4.0 ^(KB960568^) prerequisite is not installed.
goto :TheEnd
)
if not exist "%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\ngen.exe" (
echo %_wrn%
echo .NET Framework 4.x is not installed.
goto :TheEnd
)
if exist "%SystemRoot%\WinSxS\pending.xml" (
echo %_wrn%
echo Pending update operation detected.
echo Restart the system first, then run the script.
goto :TheEnd
)
if not exist "%SysPath%\windrust.dll" if not exist "%SysPath%\crypt96.dll" (
echo %_err%
echo Servicing stack is not patched.
goto :TheEnd
)

set "_bat=%~f0"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
setlocal EnableDelayedExpansion
pushd "!_work!"
if not exist "%xOS%\" (
echo %_err%
echo Required folder %xOS% is missing.
goto :TheEnd
)
for %%# in (
%xSU%
) do if not exist "%%~#" (
echo %_err%
echo Required file %%# is missing.
goto :TheEnd
)
if not exist "%xOS%\m\*.mum" (
echo %_err%
echo Required .mum files are missing.
goto :TheEnd
)
if not exist "*Windows6.0-KB2506146-%xOS%*.msu" if not exist "*Windows6.0-KB2506146-%xOS%*.cab" (
echo %_err%
echo Windows6.0-KB2506146-%xOS%.msu is not detected.
goto :TheEnd
)

call :TIcmd 1>nul 2>nul
whoami /USER | find /i "S-1-5-18" 1>nul && (
goto :Begin
) || (
if defined _elv goto :E_TI
net start TrustedInstaller 1>nul 2>nul
1>nul 2>nul %xSU% -U:T -P:E cmd.exe /c ""!_bat!" -su" &exit /b
)
whoami /USER | find /i "S-1-5-18" 1>nul || goto :E_TI

:Begin
@cls
echo.
choice /C YN /N /M "Install WMF 3.0 (KB2506146)? [y/n]: "
if errorlevel 2 exit

echo.
echo ____________________________________________________________
echo.
echo Extracting package files . . .
echo.

set "_tmp=_tmp%random%"
if exist "%_tmp%\" rmdir /s /q "%_tmp%\" >nul
mkdir %_tmp%\
if not exist "*Windows6.0-KB2506146-%xOS%*.cab" (
expand.exe -f:*Windows*.cab *Windows6.0-KB2506146-%xOS%*.msu . >nul
expand.exe -f:* Windows6.0-KB2506146-%xOS%.cab .\%_tmp% >nul
del /f /q Windows6.0-KB2506146-%xOS%.cab >nul
) else (
for /f %%# in ('dir /b /a:-d "*Windows6.0-KB2506146-%xOS%*.cab"') do (expand.exe -f:* %%# .\%_tmp% >nul)
)
mkdir %_tmp%\_o\
move /y %_tmp%\Microsoft-Windows-PowerShell-Client-WTR-Package*.mum %_tmp%\_o\ >nul
move /y %_tmp%\Microsoft-Windows-WinMan-Win8IP-Package-MiniLP*.mum %_tmp%\_o\ >nul
move /y %_tmp%\update.mum %_tmp%\_o\Microsoft-Windows-WinMan-Win8IP-Package-TopLevel~31bf3856ad364e35~%xBT%~~7.1.6002.16398.mum >nul
for %%# in (
Microsoft-Windows-PowerShell-WTR-Package
Microsoft-Windows-WinMan-Win8IP-Package
Package_for_KB123456_server
WIN8IP-NT-Microsoft-Windows-WMI-Package
Windows-Management-Protocols-Package-Vista
) do move /y %_tmp%\%%#~31bf3856ad364e35~%xBT%~~7.1.6002.16398.mum %_tmp%\_o\ >nul
copy /y %xOS%\m\*.mum %_tmp%\ >nul

echo.
echo Installing . . .
echo.

start /w PkgMgr.exe /ip /m:"%cd%\%_tmp%\update.mum" /quiet /norestart >nul

if not exist "%pPKG%\Microsoft-Windows-PowerShell-Client-WTR-Package*7.1.6002.16398.mum" (
echo %_err%
echo Installing failed.
start /w PkgMgr.exe /up:Microsoft-Windows-WinMan-Win8IP-Package-TopLevel~31bf3856ad364e35~%xBT%~~7.1.6002.16398 /quiet /norestart >nul
goto :Cleanup
)
for /f %%# in ('dir /b "%_tmp%\_o\*.mum"') do (
if exist "%pPKG%\%%#" copy /y %_tmp%\_o\%%# %pPKG%\ >nul
)

:Cleanup
echo.
echo Removing extracted files . . .
echo.

rmdir /s /q "%_tmp%\" >nul

echo.
echo Done.
goto :TheEnd

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
echo This project is for Windows Vista only.
goto :TheEnd

:TheEnd
echo.
echo Press any key to exit.
pause >nul
goto :eof
