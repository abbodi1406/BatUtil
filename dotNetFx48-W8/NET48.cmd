@setlocal DisableDelayedExpansion
@echo off
:: offline image drive letter or already mounted directory
:: leave it blank to get prompted
set "target="

:: updates location, leave it blank to automatically detect the current script directory
set "repo="

:: optional, set directory for temporary extracted files (default is on the same drive as the script)
set "tmpdir=_tn48"

:: change to 1 to enable debug mode
set _Debug=0

:: ###################################################################

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
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "_Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "Path=%_Path%"
set "xBT=amd64"
if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set "xBT=arm64"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "xBT=x86"
if /i "%PROCESSOR_ARCHITEW6432%"=="amd64" set "xBT=amd64"
if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" set "xBT=arm64"

set "_Null=1>nul 2>nul"

reg.exe query HKU\S-1-5-19 %_Null% || (echo.&echo Error: right click on the script and 'Run as administrator'&goto :TheEnd)

set _pwsh=1
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" set _pwsh=0
if %_pwsh% equ 0 (echo.&echo Error: Windows PowerShell is required for this script to work&goto :TheEnd)

set "_log=%~dpn0"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%PUBLIC%\Desktop\desktop.ini" set "_dsk=%PUBLIC%\Desktop"
setlocal EnableDelayedExpansion

if %_Debug% equ 0 (
  set "_Nul1=1>nul"
  set "_Nul2=2>nul"
  set "_Nul6=2^>nul"
  set "_Nul3=1>nul 2>nul"
  goto :Begin
)
  set "_Nul1="
  set "_Nul2="
  set "_Nul6="
  set "_Nul3="
copy /y nul "!_work!\#.rw" %_Null% && (if exist "!_work!\#.rw" del /f /q "!_work!\#.rw") || (set "_log=!_dsk!\%~n0")
echo.
echo Running in Debug Mode...
echo The window will be closed when finished
@echo on
@prompt $G
@call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"&del "!_log!_tmp.log"
@title %ComSpec%
@exit /b

:Begin
title .NET 4.8 - Win8
cd /d "!_work!"
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
if /i "!target!"=="%SystemDrive%" set "target="
if "!repo!"=="" set "repo=!_work!"
if "%repo:~-1%"=="\" set "repo=!repo:~0,-1!"
if "!tmpdir!"=="" set "tmpdir=_tn48"
set _drv=%~d0
if /i "%tmpdir:~0,5%"=="_tn48" set "tmpdir=%_drv%\_tn48"
if "%tmpdir:~-1%"=="\" set "tmpdir=!tmpdir:~0,-1!"
if "%tmpdir:~-1%"==":" set "tmpdir=!tmpdir!\"
if not "!tmpdir!"=="!tmpdir: =!" set "tmpdir=!tmpdir: =!"
set "tmpdir=!tmpdir!_%random%"
set "_ln============================================================="

:checkadk
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg.exe query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot8 %_Nul3% || set wowRegKeyPathFound=0
reg.exe query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot8 %_Nul3% || set regKeyPathFound=0
if %wowRegKeyPathFound% equ 0 (
  if %regKeyPathFound% equ 0 (
    goto :check81adk
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i in ('reg.exe query "%regKeyPath%" /v KitsRoot8') do set "KitsRoot=%%j"
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
if exist "%DandIRoot%\%xBT%\DISM\dism.exe" (
if %winbuild% lss 9600 set "Path=%DandIRoot%\%xBT%\DISM;%_Path%"
) else (
goto :check81adk
)
goto :mainboard

:check81adk
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg.exe query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot81 %_Nul3% || set wowRegKeyPathFound=0
reg.exe query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot81 %_Nul3% || set regKeyPathFound=0
if %wowRegKeyPathFound% equ 0 (
  if %regKeyPathFound% equ 0 (
    goto :check10adk
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i in ('reg.exe query "%regKeyPath%" /v KitsRoot81') do set "KitsRoot=%%j"
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
if exist "%DandIRoot%\%xBT%\DISM\dism.exe" (
if %winbuild% lss 10240 set "Path=%DandIRoot%\%xBT%\DISM;%_Path%"
) else (
goto :check10adk
)
goto :mainboard

:check10adk
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg.exe query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set wowRegKeyPathFound=0
reg.exe query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set regKeyPathFound=0
if %wowRegKeyPathFound% equ 0 (
  if %regKeyPathFound% equ 0 (
    if %winbuild% lss 9200 (echo.&echo Error: Windows ADK is required&goto :TheEnd) else (goto :mainboard)
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i in ('reg.exe query "%regKeyPath%" /v KitsRoot10') do set "KitsRoot=%%j"
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
if exist "%DandIRoot%\%xBT%\DISM\dism.exe" (
set "Path=%DandIRoot%\%xBT%\DISM;%_Path%"
) else (
goto :mainboard
)

:mainboard
if not "!target!"=="" goto :proceed
if %_Debug% neq 0 (
echo.
echo Error: you must set target automatically with Debug mode
goto :eof
)

:prompt
@cls
set target=
echo ============================================================
echo Enter the path for a supported target:
echo - Offline image drive letter
echo - Already mounted directory for install.wim
echo.
echo examples:
echo D:
echo H:
echo C:\Mount
echo ============================================================
echo.
set /p target=
if not defined target exit /b
set "target=%target:"=%"

:proceed
if "%target:~-1%"=="\" set "target=!target:~0,-1!"
if /i "!target!"=="%SystemDrive%" goto :prompt
if not exist "!target!\Windows\explorer.exe" (
echo.
echo Error: specified offline image path is not valid
if %_Debug% neq 0 goto :eof
pause
goto :prompt
)
dir /b "!target!\Windows\servicing\Version\6.2.*" %_Nul3% || (
echo.
echo Error: specified offline image is not Windows 8
if %_Debug% neq 0 goto :eof
pause
goto :prompt
)
rem for /f "tokens=3 delims=." %%# in ('dir /b "!target!\Windows\servicing\Version\10.0.*"') do set _build=%%#
rem if %_build% neq 10240 if %_build% neq 10586 (
rem echo.
rem echo Error: only builds 10240/10586 are supported
rem if %_Debug% neq 0 goto :eof
rem pause
rem goto :prompt
rem )
if exist "!target!\Windows\servicing\Packages\*~amd64~~*.mum" (set "xOS=x64"&set "pkg=15 1 22") else (set "xOS=x86"&set "pkg=7 1 16")
set "_dism2=dism.exe /English /NoRestart /ScratchDir"
set dismtarget=/image:"!target!"
set "mountdir=!target!"

call :counter
if %_sum%==0 (echo.&echo Error: Could not detect any update file&goto :TheEnd)
DEL /F /Q %systemroot%\Logs\DISM\* %_Nul3%
call :extract
call :update
call :cleaner
echo.
echo %_ln%
echo    Finished
echo %_ln%
echo.
goto :TheEnd

:extract
call :cleaner
if not exist "!tmpdir!\" mkdir "!tmpdir!"
call :counter
set count=0&set msucab=
if %_msu% neq 0 (
echo.
echo %_ln%
echo Extracting .cab files from .msu files...
echo %_ln%
echo.
for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\*Windows8-RT*KB*%xOS%*.msu"') do (set "package=%%#"&call :cab1)
)
echo.
echo %_ln%
echo Extracting files from from .cab files...
echo %_ln%
echo.
cd /d "!tmpdir!"
set _sum=0
for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\*Windows8-RT*KB*%xOS%*.cab"') do (call set /a _sum+=1)
set count=0
for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\*Windows8-RT*KB*%xOS%*.cab"') do (set "package=%%#"&set "dest=%%~n#"&call :cab2)
goto :eof

:cab1
set kb=
set tn=2
:startcabLoop
for /f "tokens=%tn% delims=-" %%A in ('echo !package!') do (
  if not errorlevel 1 (
    echo %%A|find /i /n "KB"|find /i "]KB" %_Nul1% && (set kb=%%A&goto :endcabLoop)
    set /a tn+=1
    goto :startcabLoop
  ) else (
    goto :endcabLoop
  )
)
:endcabLoop
if "%kb%"=="" goto :eof
cd /d "!repo!"
for /f "tokens=2 delims=: " %%# in ('expand.exe -d -f:*Windows*.cab !package! ^| find /i "%kb%"') do set kbcab=%%#
cd /d "!_work!"
set "msucab=!msucab! %kbcab%"
set /a count+=1
echo %count%/%_msu%: %package%
expand.exe -f:*Windows*.cab "!repo!\!package!" "!repo!" %_Null%
goto :eof

:cab2
if exist "%dest%\" rmdir /s /q "%dest%\" %_Nul3%
if not exist "%dest%\" mkdir "%dest%"
set /a count+=1
echo %count%/%_sum%: %package%
expand.exe -f:* "!repo!\!package!" "%dest%" %_Null%
if exist "%dest%\*cablist.ini" (
  expand.exe -f:* "%dest%\*.cab" "%dest%" %_Null%
  del /f /q "%dest%\*cablist.ini" %_Nul3%
  del /f /q "%dest%\*.cab" %_Nul3%
)
goto :eof

:update
echo.
echo %_ln%
echo Checking Updates...
echo %_ln%
set netpk=
set netlp=
set netcu=
set _sum=0
for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\*Windows8-RT*KB*%xOS%*.cab"') do (call set /a _sum+=1)
for /f "tokens=* delims=" %%# in ('dir /b /on "!repo!\*Windows8-RT*KB*%xOS%*.cab"') do (set "package=%%#"&set "dest=%%~n#"&call :procmum)
if %_sum%==0 (echo.&echo No new or applicable .NET 4.8 packs detected&goto :eof)
if not defined netpk if not exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486081*.mum" (
set netlp=
set netcu=
)
if not defined netpk if not defined netlp if not defined netcu (echo.&echo No new or applicable .NET 4.8 packs detected&goto :eof)
echo.
echo %_ln%
echo Installing updates...
echo %_ln%
if defined netpk call :instpk
if defined netlp call :instlp
rem if defined netcu call :instcu
goto :eof

:procmum
rem set "mumcheck=!mountdir!\Windows\servicing\packages\Package_for_DotNetRollup*.mum"
rem find /i "Package_for_DotNetRollup" "%dest%\update.mum" %_Nul3% && (
rem if exist "!mumcheck!" (
rem call :dnfver Package_for_DotNetRollup
rem if !skip!==1 (set /a _sum-=1&goto :eof)
rem )
rem set "netcu=!netcu! /packagepath:%dest%\update.mum"
rem set "dstcu=!dstcu! %dest%"
rem goto :eof
rem )
set "mumcheck=!mountdir!\Windows\servicing\packages\Package_for_KB4486081*.mum"
find /i "Package_for_KB4486081" "%dest%\update.mum" %_Nul3% && (
if exist "!mumcheck!" (
call :dnfver Package_for_KB4486081
if !skip!==1 (set /a _sum-=1&goto :eof)
)
set "netpk=!netpk! /packagepath:%dest%\update.mum"
set "dstpk=!dstpk! %dest%"
goto :eof
)
find /i "Package_for_KB4486082" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486082*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*ar-SA*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486083" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486083*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*zh-CN*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486084" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486084*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*zh-TW*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486085" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486085*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*cs-CZ*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486086" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486086*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*da-DK*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486087" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486087*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*de-DE*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486088" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486088*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*el-GR*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486089" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486089*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*es-ES*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486090" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486090*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*fi-FI*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486091" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486091*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*fr-FR*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486092" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486092*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*he-IL*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486093" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486093*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*hu-HU*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486094" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486094*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*it-IT*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486095" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486095*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*ja-JP*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486096" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486096*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*ko-KR*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486097" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486097*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*nl-NL*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486098" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486098*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*nb- NO*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486099" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486099*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*pl-PL*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486100" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486100*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*pt-BR*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486101" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486101*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*pt-PT*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486102" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486102*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*ru-RU*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486103" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486103*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*sv-SE*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
find /i "Package_for_KB4486104" "%dest%\update.mum" %_Nul3% && (
if exist "!mountdir!\Windows\servicing\packages\Package_for_KB4486104*.mum" (set /a _sum-=1&goto :eof)
if not exist "!mountdir!\Windows\servicing\packages\Microsoft-Windows-NetFx4*OC-Package~*tr-TR*.mum" (set /a _sum-=1&goto :eof)
set "netlp=!netlp! /packagepath:%dest%\update.mum"
set "dstlp=!dstlp! %dest%"
goto :eof
)
goto :eof

:dnfver
set skip=0
for %%# in (inver_aa inver_bl inver_mj inver_mn kbver_aa kbver_bl kbver_mj kbver_mn) do set %%#=0
for /f %%I in ('dir /b /od "!mumcheck!"') do set _pak=%%~nI
for /f "tokens=4-7 delims=~." %%H in ('echo %_pak%') do set "inver_aa=%%H"&set "inver_bl=%%I"&set "inver_mj=%%J"&set "inver_mn=%%K"
:: self note: do not add " at the end
for /f "tokens=5-8 delims==. " %%H in ('type %dest%\update.mum ^|find /i "%1" ^| find /i /v "_RTM"') do set "kbver_aa=%%~H"&set "kbver_bl=%%I"&set "kbver_mj=%%J"&set "kbver_mn=%%K
if %inver_aa% gtr %kbver_aa% set skip=1
if %inver_aa% equ %kbver_aa% if %inver_bl% gtr %kbver_bl% set skip=1
if %inver_aa% equ %kbver_aa% if %inver_bl% equ %kbver_bl% if %inver_mj% gtr %kbver_mj% set skip=1
if %inver_aa% equ %kbver_aa% if %inver_bl% equ %kbver_bl% if %inver_mj% equ %kbver_mj% if %inver_mn% geq %kbver_mn% set skip=1
goto :eof

:instpk
for %%Q in (%dstpk%) do (
set fol=%%Q
for /L %%A in (%pkg%) do (
for /f %%# in ('dir /b /a:-d !fol!\Package_%%A_for_KB4486081~*.mum') do (set "mum=%%#"&call :xml)
)
if %xOS%==x64 for /f %%# in ('dir /b /a:-d !fol!\Package_24_for_KB4486081~*.mum') do (set "mum=%%#"&call :xml)
)
:: set "mum=update.mum"&call :xml

%_dism2%:"!tmpdir!" %dismtarget% /Add-Package %netpk%
if %errorlevel% equ 1726 %_dism2%:"!tmpdir!" %dismtarget% /Get-Packages %_Nul1%

for %%Q in (%dstpk%) do (
set fol=%%Q
for /L %%A in (%pkg%) do (
for /f %%# in ('dir /b /a:-d !fol!\Package_%%A_for_KB4486081~*.mum') do (set "mum=%%#"&call :rst)
)
if %xOS%==x64 for /f %%# in ('dir /b /a:-d !fol!\Package_24_for_KB4486081~*.mum') do (set "mum=%%#"&call :rst)
for /f "tokens=3,7,8 delims==. " %%H in ('type !fol!\update.mum ^|find /i "Package_for_KB"') do set "ppn=%%~H"&set "ppv=%%I.%%J
)
:: set "mum=update.mum"&call :rst
exit /b

:instlp
for %%Q in (%dstlp%) do (
set fol=%%Q
if %xOS%==x86 for /f %%# in ('dir /b /a:-d !fol!\Package_2_for*.mum') do (set "mum=%%#"&call :xml)
if exist "!fol!\Package_3_for*.mum" for /f %%# in ('dir /b /a:-d !fol!\Package_3_for*.mum') do (set "mum=%%#"&call :xml)
if exist "!fol!\Package_5_for*.mum" for /f %%# in ('dir /b /a:-d !fol!\Package_5_for*.mum') do (set "mum=%%#"&call :xml)
for /f %%# in ('dir /b /a:-d !fol!\Package_for_KB*.mum') do (set "mum=%%#"&call :xml)
set "mum=update.mum"&call :xml
)

%_dism2%:"!tmpdir!" %dismtarget% /Add-Package %netlp%
if %errorlevel% equ 1726 %_dism2%:"!tmpdir!" %dismtarget% /Get-Packages %_Nul1%

for %%Q in (%dstlp%) do (
set fol=%%Q
if %xOS%==x86 for /f %%# in ('dir /b /a:-d !fol!\Package_2_for*.mum') do (set "mum=%%#"&call :rst)
if exist "!fol!\Package_3_for*.mum" for /f %%# in ('dir /b /a:-d !fol!\Package_3_for*.mum') do (set "mum=%%#"&call :rst)
if exist "!fol!\Package_5_for*.mum" for /f %%# in ('dir /b /a:-d !fol!\Package_5_for*.mum') do (set "mum=%%#"&call :rst)
for /f %%# in ('dir /b /a:-d !fol!\Package_for_KB*.mum') do (set "mum=%%#"&call :rst)
for /f "tokens=3,7,8 delims==. " %%H in ('type !fol!\update.mum ^|find /i "Package_for_KB"') do set "ppn=%%~H"&set "ppv=%%I.%%J
set "mum=update.mum"&call :rst
)
exit /b

:instcu
for %%Q in (%dstcu%) do (
set fol=%%Q
for /f %%# in ('dir /b /a:-d !fol!\Package_*_for*.mum') do find /i "WinPE-NetFx4-Package" "!fol!\%%#" %_Nul3% || (set "mum=%%#"&call :xml)
set "mum=update.mum"&call :xml
)

%_dism2%:"!tmpdir!" %dismtarget% /Add-Package %netcu%
if %errorlevel% equ 1726 %_dism2%:"!tmpdir!" %dismtarget% /Get-Packages %_Nul1%

for %%Q in (%dstcu%) do (
set fol=%%Q
for /f %%# in ('dir /b /a:-d !fol!\Package_*_for*.mum') do if exist "!fol!\o_%%#" (set "mum=%%#"&call :rst)
for /f "tokens=3,7,8 delims==. " %%H in ('type !fol!\update.mum ^|find /i "Package_for_Do"') do set "ppn=%%~H"&set "ppv=%%I.%%J
set "mum=update.mum"&call :rst
)
exit /b

:xml
copy /y %fol%\%mum% %fol%\o_%mum% %_Nul1%
if /i %mum%==update.mum (
type %fol%\o_%mum% |find /i /v "customInformation">%fol%\%mum%
)
:: powershell -nop -c "&{$doc = [xml](gc '%fol%\%mum%'); $node = $doc.assembly.package.parent; [void]$node.ParentNode.RemoveChild($node); $utf = [Text.UTF8Encoding]::new($false); $sw = [IO.StreamWriter]::new('%fol%\%mum%', $false, $utf); $doc.save($sw); $sw.Close();}"
powershell -nop -c "&{$doc = [xml](gc '%fol%\%mum%'); $node = $doc.assembly.package.parent; [void]$node.ParentNode.RemoveChild($node); $utf = New-Object Text.UTF8Encoding; $sw = New-Object IO.StreamWriter '%fol%\%mum%', $false, $utf; $doc.save($sw); $sw.Close();}"
exit /b

:rst
set omf="!mountdir!\Windows\servicing\Packages\%mum%"
if /i %mum%==update.mum for /f %%# in ('dir /b /a:-d "!mountdir!\Windows\servicing\Packages\%ppn%*%ppv%.mum"') do set omf="!mountdir!\Windows\servicing\Packages\%%#"
takeown /f %omf% /A %_Nul1%
icacls %omf% /grant *S-1-5-32-544:F %_Nul1%
copy /y %fol%\o_%mum% %omf% %_Nul1%
icacls %omf% /reset %_Nul1%
exit /b

:counter
set _msu=0
set _cab=0
set _sum=0
cd /d "!repo!"
if exist "*Windows8-RT*KB*%xOS%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "*Windows8-RT*KB*%xOS%*.msu"') do call set /a _msu+=1
if exist "*Windows8-RT*KB*%xOS%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "*Windows8-RT*KB*%xOS%*.cab"') do call set /a _cab+=1
cd /d "!_work!"
set /a _sum=%_msu%+%_cab%
goto :eof

:cleaner
cd /d "!_work!"
if defined msucab (
  for %%# in (%msucab%) do del /f /q "!repo!\%%~#" %_Nul3%
  set msucab=
)
if exist "!tmpdir!\" (
echo.
echo %_ln%
echo Removing temporary extracted files...
echo %_ln%
echo.
rmdir /s /q "!tmpdir!\" %_Nul1%
)
if exist "!tmpdir!\" (
mkdir %_drv%\_del286 %_Null%
robocopy %_drv%\_del286 "!tmpdir!" /MIR %_Null%
rmdir /s /q %_drv%\_del286\ %_Null%
rmdir /s /q "!tmpdir!\" %_Nul3%
)
goto :eof

:TheEnd
if defined _work call :cleaner
echo.
echo Press any key to exit.
if %_Debug% equ 0 pause >nul
goto :eof
