@setlocal DisableDelayedExpansion
@set uivr=v0.6
@echo off
set _Debug=0

set "_cmdf=%~f0"
if exist "%SystemRoot%\Sysnative\cmd.exe" (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %*"
exit /b
)
if exist "%SystemRoot%\SysArm32\cmd.exe" if /i %PROCESSOR_ARCHITECTURE%==AMD64 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" %*"
exit /b
)
set "_Null=1>nul 2>nul"
set "_err===== ERROR ===="
set _pcab=
set "_args="
set "_args=%~1"
if not defined _args goto :NoProgArgs
if "%~1"=="" set "_args="&goto :NoProgArgs

:NoProgArgs
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "xBT=x64"
if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set "xBT=x86"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "xBT=x86"
if /i "%PROCESSOR_ARCHITEW6432%"=="amd64" set "xBT=x64"
if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" set "xBT=x86"
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
set _pwsh=1
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" set _pwsh=0
if %winbuild% geq 22483 if %_pwsh% EQU 0 goto :E_PS
set "_log=%~dpn0"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
set _drv=%~d0
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%PUBLIC%\Desktop\desktop.ini" set "_dsk=%PUBLIC%\Desktop"
set psfnet=0
if exist "%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\ngen.exe" set psfnet=1
if exist "%SystemRoot%\Microsoft.NET\Framework\v2.0.50727\ngen.exe" set psfnet=1
for %%# in (E F G H I J K L M N O P Q R S T U V W X Y Z) do (
set "_adr%%#=%%#"
)
if %winbuild% lss 22483 for /f "tokens=2 delims==:" %%# in ('"wmic path Win32_Volume where (DriveLetter is not NULL) get DriveLetter /value" ^| findstr ^=') do (
if defined _adr%%# set "_adr%%#="
)
if %winbuild% lss 22483 for /f "tokens=2 delims==:" %%# in ('"wmic path Win32_LogicalDisk where (DeviceID is not NULL) get DeviceID /value" ^| findstr ^=') do (
if defined _adr%%# set "_adr%%#="
)
if %winbuild% geq 22483 for /f "tokens=1 delims=:" %%# in ('powershell -nop -c "(([WMISEARCHER]'Select * from Win32_Volume where DriveLetter is not NULL').Get()).DriveLetter; (([WMISEARCHER]'Select * from Win32_LogicalDisk where DeviceID is not NULL').Get()).DeviceID"') do (
if defined _adr%%# set "_adr%%#="
)
for %%# in (E F G H I J K L M N O P Q R S T U V W X Y Z) do (
if not defined _sdr (if defined _adr%%# set "_sdr=%%#:")
)
setlocal EnableDelayedExpansion
if exist "!_work!\*.cab" if exist "!_work!\*.psf" set "_pcab=!_work!"
if defined _args if exist "!_args!\*.cab" if exist "!_args!\*.psf" set "_pcab=%~1"

if %_Debug% equ 0 (
  set "_Nul1=1>nul"
  set "_Nul2=2>nul"
  set "_Nul6=2^>nul"
  set "_Nul3=1>nul 2>nul"
  set "_Pause=pause >nul"
  set "_Contn=echo Press any key to continue..."
  set "_Exit=echo Press any key to exit."
  set "_Supp="
  goto :Begin
)
  set "_Nul1="
  set "_Nul2="
  set "_Nul6="
  set "_Nul3="
  set "_Pause=rem."
  set "_Contn=rem."
  set "_Exit=rem."
  set "_Supp=1>nul"
copy /y nul "!_work!\#.rw" %_Null% && (if exist "!_work!\#.rw" del /f /q "!_work!\#.rw") || (set "_log=!_dsk!\%~n0")
echo.
echo Running in Debug Mode...
echo The window will be closed when finished
@echo on
@prompt $G
@call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"&del "!_log!_tmp.log"
@color 07
@title %ComSpec%
@exit /b

:Begin
title PSFX Repack %uivr%
pushd "!_work!"
set _file=(PSFExtractor.exe,cabarc.exe)
for %%# in %_file% do (
if not exist ".\bin\%%#" (set _bin=%%#&goto :E_Bin)
)
popd
if %_Debug% equ 0 @cls
if not defined _pcab (
echo ==== NOTICE ====
echo.
echo Could not detect cab and psf files
echo.
%_Exit%
%_Pause%
goto :eof
)
if %psfnet% equ 0 (
echo %_err%
echo.
echo PSFExtractor.exe require .NET Framework 4.x or 2.0
echo.
%_Exit%
%_Pause%
goto :eof
)
if not defined _sdr (
echo %_err%
echo.
echo Could not find or assign unused Drive Letter
echo.
%_Exit%
%_Pause%
goto :eof
)
set _did=0
set _sbst=0
set "_tmp=%_drv%\_temp%random%"
if exist "%_tmp%\" set "_tmp=%_drv%\_temp%random%"
if not exist "%_tmp%\" mkdir "%_tmp%"
pushd "!_pcab!"
for /f "delims=" %%# in ('dir /b *.cab') do (set "pack=%%~n#"&call :psfcab)
if exist "PSFExtractor.exe" del /f /q "PSFExtractor.*" %_Nul3%
if exist "cabarc.exe" del /f /q "cabarc.exe" %_Nul3%
if %_sbst% equ 1 subst %_sdr% /d
popd
if exist "%_tmp%\" rmdir /s /q "%_tmp%\" %_Nul3%
if exist "%_tmp%\" (
mkdir %_drv%\_del286 %_Null%
robocopy %_drv%\_del286 "%_tmp%" /MIR /R:1 /W:1 /NFL /NDL /NP /NJH /NJS %_Null%
rmdir /s /q %_drv%\_del286\ %_Null%
rmdir /s /q "%_tmp%\" %_Nul3%
)
echo.
echo Finished
echo.
%_Exit%
%_Pause%
goto :eof

:psfcab
if exist "%pack%-full_psfx.cab" exit /b
if not exist "%pack%.psf" if not exist "%pack:~0,-8%*.psf" (
echo %pack%.cab / PSF file is missing or named incorrectly
exit /b
)
if not exist "%pack%.psf" if exist "%pack:~0,-8%*.psf" (
for /f %%# in ('dir /b /a:-d "%pack:~0,-8%*.psf"') do rename "%%#" %pack%.psf %_Nul3%
)
if exist "%_tmp%\*.mum" del /f /q "%_tmp%\*.mum" %_Nul3%
if exist "%_tmp%\*.xml" del /f /q "%_tmp%\*.xml" %_Nul3%
:: expand.exe -f:update.mum "!_pcab!\%pack%.cab" "%_tmp%" %_Null%
:: if not exist "%_tmp%\update.mum" exit /b
:: findstr /i /m "PSFX" "%_tmp%\update.mum" %_Nul3% || exit /b
expand.exe -f:*.psf.cix.xml "!_pcab!\%pack%.cab" "%_tmp%" %_Null%
if not exist "%_tmp%\*.psf.cix.xml" (
echo %pack%.cab / psf.cix.xml file is not found
exit /b
)
if %_did% equ 0 (
set _did=1
subst %_sdr% "!_pcab!" && (set _sbst=1) || (echo Error: will proceed without subst drive)
)
if %_sbst% equ 1 pushd %_sdr%
if not exist "PSFExtractor.exe" copy /y "!_work!\bin\PSFExtractor.*" . %_Nul3%
if not exist "cabarc.exe" copy /y "!_work!\bin\cabarc.exe" . %_Nul3%
echo.
echo ============================================================
echo Extract: %pack%.cab
echo ============================================================
if exist "%pack%\" rmdir /s /q "%pack%\" %_Nul3%
if not exist "%pack%\" mkdir "%pack%"
expand.exe -f:* %pack%.cab "%pack%" %_Null%
if exist "%pack%\*cablist.ini" (
  expand.exe -f:* "%pack%\*.cab" "%pack%" %_Null%
  del /f /q "%pack%\*cablist.ini" %_Nul3%
  del /f /q "%pack%\*.cab" %_Nul3%
)
if not exist "%pack%\express.psf.cix.xml" for /f %%# in ('dir /b /a:-d "%pack%\*.psf.cix.xml"') do rename "%pack%\%%#" express.psf.cix.xml %_Nul3%
PSFExtractor.exe %pack%.cab %_Null%
if %errorlevel% neq 0 (
  echo.
  echo Error: PSFExtractor.exe operation failed
  rmdir /s /q "%pack%\" %_Nul3%
  if %_sbst% equ 1 popd
  exit /b
)
echo.
echo ============================================================
echo Create : %pack%-full_psfx.cab
echo ============================================================
cd %pack%
del /f /q *.psf.cix.xml %_Nul3%
..\cabarc.exe -m LZX:21 -r -p N ..\psfx2psfx1.cab *.* %_Null%
if %errorlevel% neq 0 (
  echo.
  echo Error: cabarc.exe operation failed
  cd..
  rmdir /s /q "%pack%\" %_Nul3%
  if %_sbst% equ 1 popd
  exit /b
)
cd..
rmdir /s /q "%pack%\" %_Nul3%
ren psfx2psfx1.cab %pack%-full_psfx.cab
if %_sbst% equ 1 popd
exit /b

:E_Bin
echo %_err%
echo.
echo Required file is missing: %_bin%
echo.
%_Exit%
%_Pause%
goto :eof

:E_PS
echo %_err%
echo.
echo Windows PowerShell is required for this script to work.
echo.
echo Press any key to exit.
pause >nul
goto :eof
