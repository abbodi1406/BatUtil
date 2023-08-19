@setlocal DisableDelayedExpansion
@echo off

set WIMPATH=
set WINPE=1
set SLIM=0

set DEFAULTLANGUAGE=
set MOUNTDIR=

set WINPEPATH=

:: enable debug mode
set _Debug=0

:: ###################################################################
:: # NORMALLY THERE IS NO NEED TO CHANGE ANYTHING BELOW THIS COMMENT #
:: ###################################################################

set NET35=1
set "_cmdf=%~f0"
if exist "%SystemRoot%\Sysnative\cmd.exe" (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" "
exit /b
)
if exist "%SystemRoot%\SysArm32\cmd.exe" if /i %PROCESSOR_ARCHITECTURE%==AMD64 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" "
exit /b
)

set "SysPath=%SystemRoot%\System32"
set "Path=%SystemRoot%\System32;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)
set "xOS=amd64"
if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set "xOS=arm64"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "xOS=x86"
if /i "%PROCESSOR_ARCHITEW6432%"=="amd64" set "xOS=amd64"
if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" set "xOS=arm64"
set "_Null=1>nul 2>nul"
set _cwmi=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
)
set _pwsh=1
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" set _pwsh=0
if %_cwmi% equ 0 if %_pwsh% equ 0 goto :E_PS
reg.exe query HKU\S-1-5-19 %_Null% || goto :E_ADMIN
set "_log=%~dpn0"
set "WORKDIR=%~dp0"
set "WORKDIR=%WORKDIR:~0,-1%"
set "TEMPDIR=%~d0\W81MUITEMP"
set "TMPDISM=%TEMPDIR%\scratch"
set "EXTRACTDIR=%TEMPDIR%\extract"
set "_7z=%WORKDIR%\dism\7z.exe"
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%PUBLIC%\Desktop\desktop.ini" set "_dsk=%PUBLIC%\Desktop"
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
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
copy /y nul "!WORKDIR!\#.rw" %_Null% && (if exist "!WORKDIR!\#.rw" del /f /q "!WORKDIR!\#.rw") || (set "_log=!_dsk!\%~n0")
echo.
echo Running in Debug Mode...
echo The window will be closed when finished
@echo on
@prompt $G
@call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"&del "!_log!_tmp.log"
@title %ComSpec%
@exit /b

:Begin
title Windows 8.1 Multilingual Creator
set "_dLog=%SystemRoot%\Logs\DISM"
set _drv=%~d0
set _ntf=NTFS
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('"wmic volume where DriveLetter='%_drv%' get FileSystem /value"') do set "_ntf=%%#"
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 0 for /f %%# in ('powershell -nop -c "(([WMISEARCHER]'Select * from Win32_Volume where DriveLetter=\"%_drv%\"').Get()).FileSystem"') do set "_ntf=%%#"
if /i not "%_ntf%"=="NTFS" set _drv=%SystemDrive%
if "!MOUNTDIR!"=="" set "MOUNTDIR=%_drv%\W81MUIMOUNT"
set "INSTALLMOUNTDIR=%MOUNTDIR%\install"
set "WINREMOUNTDIR=%MOUNTDIR%\winre"
set EAlang=(ja-jp,ko-kr,zh-cn,zh-hk,zh-tw)

:adk81
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg.exe query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot81 %_Nul3% || set wowRegKeyPathFound=0
reg.exe query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot81 %_Nul3% || set regKeyPathFound=0
if %wowRegKeyPathFound% equ 0 (
  if %regKeyPathFound% equ 0 (
    goto :adk10
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i in ('reg.exe query "%regKeyPath%" /v KitsRoot81') do set "KitsRoot=%%j"
set "WinPERoot=%KitsRoot%Assessment and Deployment Kit\Windows Preinstallation Environment"
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" if %winbuild% lss 10240 (
set "DISMRoot=%DandIRoot%\%xOS%\DISM\dism.exe"
goto :check
)

:adk10
if %_Debug% neq 0 if %winbuild% GEQ 9600 goto :skipadk
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg.exe query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set wowRegKeyPathFound=0
reg.exe query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set regKeyPathFound=0
if %wowRegKeyPathFound% equ 0 (
  if %regKeyPathFound% equ 0 (
    goto :skipadk
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i in ('reg.exe query "%regKeyPath%" /v KitsRoot10') do set "KitsRoot=%%j"
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" (
set "DISMRoot=%DandIRoot%\%xOS%\DISM\dism.exe"
goto :check
)

:skipadk
set "DISMRoot=!WORKDIR!\dism\dism.exe"
if /i %xOS%==amd64 set "DISMRoot=!WORKDIR!\dism\dism64\dism.exe"
if %winbuild% GEQ 9600 set "DISMRoot=%SystemRoot%\System32\dism.exe"

:check
cd /d "!WORKDIR!"
if "!WINPEPATH!"=="" (
for /f %%# in ('dir /b /ad "WinPE\amd64\WinPE_OCs\*-*" %_Nul6%') do if exist "WinPE\amd64\WinPE_OCs\%%#\lp.cab" set "WinPERoot=!WORKDIR!\WinPE"
for /f %%# in ('dir /b /ad "WinPE\x86\WinPE_OCs\*-*" %_Nul6%') do if exist "WinPE\x86\WinPE_OCs\%%#\lp.cab" set "WinPERoot=!WORKDIR!\WinPE"
) else (
for /f %%# in ('dir /b /ad "!WINPEPATH!\amd64\WinPE_OCs\*-*" %_Nul6%') do if exist "!WINPEPATH!\amd64\WinPE_OCs\%%#\lp.cab" set "WinPERoot=!WINPEPATH!"
for /f %%# in ('dir /b /ad "!WINPEPATH!\x86\WinPE_OCs\*-*" %_Nul6%') do if exist "!WINPEPATH!\x86\WinPE_OCs\%%#\lp.cab" set "WinPERoot=!WINPEPATH!"
)
if not exist "!_7z!" goto :E_BIN
if not exist "!DISMRoot!" goto :E_BIN
set _dism2="!DISMRoot!" /English /ScratchDir

if not "!WIMPATH!"=="" goto :prepare
set _wim=0
if exist "*.wim" (for /f "delims=" %%i in ('dir /b /a:-d *.wim') do (call set /a _wim+=1))
if %_wim% neq 1 goto :prompt
for /f "delims=" %%i in ('dir /b /a:-d *.wim') do set "WIMPATH=%%i"
goto :prepare

:prompt
if %_Debug% neq 0 (
set MESSAGE=ERROR: You must auto set WIMPATH in Debug mode
goto :END
)
@cls
set WIMPATH=
echo.
echo ============================================================
echo Enter the install.wim path ^(without quotes marks ""^)
echo ============================================================
echo.
set /p WIMPATH=
if not defined WIMPATH exit /b
set "WIMPATH=%WIMPATH:"=%"
if "%WIMPATH:~-1%"=="\" set "WIMPATH=!WIMPATH:~0,-1!"

:prepare
if not exist "!WIMPATH!" goto :E_DVD
echo.
echo ============================================================
echo Prepare work directories
echo ============================================================
echo.
if exist "!TEMPDIR!\" rmdir /s /q "!TEMPDIR!\" %_Nul3%
if exist "!MOUNTDIR!\" rmdir /s /q "!MOUNTDIR!\" %_Nul3%
mkdir "!TEMPDIR!" || goto :E_MKDIR
mkdir "!TMPDISM!" || goto :E_MKDIR
mkdir "!EXTRACTDIR!" || goto :E_MKDIR
mkdir "%MOUNTDIR%" || goto :E_MKDIR
mkdir "%INSTALLMOUNTDIR%" || goto :E_MKDIR
mkdir "%WINREMOUNTDIR%" || goto :E_MKDIR
echo.
echo ============================================================
echo Detect language packs details
echo ============================================================
echo.
set count=0
set _ol=0
if exist ".\langs\*.cab" for /f %%i in ('dir /b /on ".\langs\*.cab"') do (
set /a _ol+=1
set /a count+=1
set "LPFILE!count!=%%i"
)
if %_ol% equ 0 goto :E_FILES
set LANGUAGES=%_ol%

for /L %%j in (1,1,%LANGUAGES%) do (
"!_7z!" e ".\langs\!LPFILE%%j!" -o"!EXTRACTDIR!" langcfg.ini %_Null%
for /f "tokens=2 delims==" %%i in ('type "!EXTRACTDIR!\langcfg.ini" ^| findstr /i "Language"') do set LANGUAGE%%j=%%i
del /f /q "!EXTRACTDIR!\langcfg.ini"
"!_7z!" e ".\langs\!LPFILE%%j!" -o"!EXTRACTDIR!" Microsoft-Windows-CommonFoundation-LanguagePack-Package*9600*.mum %_Null%
if not exist "!EXTRACTDIR!\*.mum" set ERRFILE=!LPFILE%%j!&goto :E_LP
for /f "tokens=3 delims=~" %%V in ('"dir "!EXTRACTDIR!\*.mum" /b" %_Nul6%') do set LPARCH%%j=%%V
del /f /q "!EXTRACTDIR!\*.mum" %_Nul3%
)
for /L %%j in (1,1,%LANGUAGES%) do (
"!_7z!" e ".\langs\!LPFILE%%j!" -o"!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" RLP-GM-Package_for_KB2919355*.mum %_Null%
if exist "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\RLP-GM-Package_for_KB2919355*.mum" (set LPLevel%%j=S14) else (set LPLevel%%j=RTM)
)
for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (echo !LANGUAGE%%j!: 64-bit {x64}) else (echo !LANGUAGE%%j!: 32-bit {x86})
set "WinpeOC%%j=!WinPERoot!\!LPARCH%%j!\WinPE_OCs"
)
for /L %%j in (1,1,%LANGUAGES%) do (
if not exist "!WinpeOC%%j!\!LANGUAGE%%j!\lp.cab" call set WINPE=0
)
if not exist "!WORKDIR!\dotNetFx35_W8.1_x86_x64.exe" set NET35=0
dism\imagex.exe /info "!WIMPATH!" | findstr /c:"LZMS" %_Nul1% && goto :E_ESD
for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"!WIMPATH!" ^| findstr "Index"') do set imgcount=%%i
for /f "tokens=3 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"!WIMPATH!" /index:1 ^| find /i "ServicePack Build"') do set svcbuild=%%i
if %svcbuild% GEQ 17031 for /L %%j in (1,1,%LANGUAGES%) do (
if /i not !LPLevel%%j!==S14 set ERRFILE=!LPFILE%%j!&goto :E_RTM
)
if "%DEFAULTLANGUAGE%"=="" (
for /f "tokens=1" %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"!WIMPATH!" /index:1 ^| find /i "Default"') do set "DEFAULTLANGUAGE=%%i"
)
echo.
echo ============================================================
echo Detect install.wim details
echo ============================================================
echo.
for /L %%i in (1,1,%imgcount%) do (
for /f "tokens=2 delims=: " %%# in ('dism\dism.exe /english /get-wiminfo /wimfile:"!WIMPATH!" /index:%%i ^| find /i "Architecture"') do set "WIMARCH%%i=%%#"
)
for /L %%i in (1,1,%imgcount%) do (
if /i !WIMARCH%%i!==x64 (call set WIMARCH%%i=amd64)
)
for /L %%i in (1,1,%imgcount%) do (
echo !WIMARCH%%i!>>"!TEMPDIR!\WIMARCH.txt"
)
set _label86=0
findstr /i /v "amd64" "!TEMPDIR!\WIMARCH.txt" %_Nul1%
if %errorlevel%==0 (set wimbit=32&set _label86=1)

findstr /i /v "x86" "!TEMPDIR!\WIMARCH.txt" %_Nul1%
if %errorlevel%==0 (
if %_label86%==1 (set wimbit=96) else (set wimbit=64)
)
echo Count: %imgcount% Image^(s^)
if %wimbit%==96 (echo Arch : Multi) else (echo Arch : %wimbit%-bit)

if %WINPE% NEQ 1 goto :extract
set _PEM86=
set _PES86=
set _PEX86=
set _PEF86=
set _PEM64=
set _PES64=
set _PEX64=
set _PEF64=
echo.
echo ============================================================
echo Set WinPE language packs paths
echo ============================================================
echo.
if %wimbit%==32 for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==x86 call :setpe %%j 86 32-bit
)
if %wimbit%==64 for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 call :setpe %%j 64 64-bit
)
if %wimbit%==96 for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==x86 call :setpe %%j 86 32-bit
if /i !LPARCH%%j!==amd64 call :setpe %%j 64 64-bit
)
goto :extract

:setpe
echo !LANGUAGE%1! / %3
call set _PEM%2=!_PEM%2! /PackagePath:!LANGUAGE%1!\lp.cab /PackagePath:!LANGUAGE%1!\WinPE-SRT_!LANGUAGE%1!.cab
call set _PES%2=!_PES%2! /PackagePath:!LANGUAGE%1!\WinPE-Setup_!LANGUAGE%1!.cab /PackagePath:!LANGUAGE%1!\WinPE-Setup-Client_!LANGUAGE%1!.cab
call set _PEX%2=!_PEX%2! /PackagePath:!LANGUAGE%1!\WinPE-EnhancedStorage_!LANGUAGE%1!.cab /PackagePath:!LANGUAGE%1!\WinPE-Scripting_!LANGUAGE%1!.cab /PackagePath:!LANGUAGE%1!\WinPE-SecureStartup_!LANGUAGE%1!.cab /PackagePath:!LANGUAGE%1!\WinPE-WDS-Tools_!LANGUAGE%1!.cab /PackagePath:!LANGUAGE%1!\WinPE-WMI_!LANGUAGE%1!.cab
for %%G in %EAlang% do if /i !LANGUAGE%1!==%%G (
call set _PEF%2=!_PEF%2! /PackagePath:WinPE-FontSupport-%%G.cab
)
goto :eof

:extract
set _PP86=
set _PP64=
echo.
echo ============================================================
echo Extract language packs
echo ============================================================
echo.
if %wimbit%==32 for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==x86 call :setlp %%j 86 32-bit
)
if %wimbit%==64 for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 call :setlp %%j 64 64-bit
)
if %wimbit%==96 for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==x86 call :setlp %%j 86 32-bit
if /i !LPARCH%%j!==amd64 call :setlp %%j 64 64-bit
)
if %wimbit%==32 if not defined _PP86 goto :E_ARCH
if %wimbit%==64 if not defined _PP64 goto :E_ARCH
goto :dowork

:setlp
echo !LANGUAGE%1! / %3
"!_7z!" x ".\langs\!LPFILE%1!" -o"!TEMPDIR!\!LPARCH%1!\!LANGUAGE%1!" * -r %_Null%
call set _PP%2=!_PP%2! /PackagePath:!LANGUAGE%1!\update.mum
goto :eof

:dowork
if not %NET35%==1 goto :proceed
echo.
echo ============================================================
echo Extract files from .NET Framework 3.5 package
echo ============================================================
echo.
if %wimbit%==32 (
"!_7z!" x .\dotNetFx35_W8.1_x86_x64.exe -o"!EXTRACTDIR!\NET35" x86\* -r %_Null%
)
if %wimbit%==64 (
"!_7z!" x .\dotNetFx35_W8.1_x86_x64.exe -o"!EXTRACTDIR!\NET35" x64\* -r %_Null%
move "!EXTRACTDIR!\NET35\x64" "!EXTRACTDIR!\NET35\amd64" %_Nul1%
)
if %wimbit%==96 (
"!_7z!" x .\dotNetFx35_W8.1_x86_x64.exe -o"!EXTRACTDIR!\NET35" x86\* -r %_Null%
"!_7z!" x .\dotNetFx35_W8.1_x86_x64.exe -o"!EXTRACTDIR!\NET35" x64\* -r %_Null%
move "!EXTRACTDIR!\NET35\x64" "!EXTRACTDIR!\NET35\amd64" %_Nul1%
)

:proceed
for /L %%i in (1,1,%imgcount%) do set "_i=%%i"&call :doinstall
goto :rebuild

:doinstall
echo.
echo ============================================================
echo Mount install.wim - index %_i%/%imgcount%
echo ============================================================
!_dism2!:"!TMPDISM!" /Mount-Wim /Wimfile:"!WIMPATH!" /Index:%_i% /MountDir:"%INSTALLMOUNTDIR%"
if !errorlevel! neq 0 goto :E_MOUNT
echo.
echo ============================================================
echo Add LPs to install.wim - index %_i%/%imgcount%
echo ============================================================
pushd "!TEMPDIR!\!WIMARCH%_i%!"
if defined _PP64 if /i !WIMARCH%_i%!==amd64 (
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallLP64.log" /Add-Package !_PP64!
)
if defined _PP86 if /i !WIMARCH%_i%!==x86 (
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallLP86.log" /Add-Package !_PP86!
)
popd
echo.
echo ============================================================
echo Update language settings
echo ============================================================
echo.
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE% /Quiet
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE% /Quiet
if %NET35%==1 if not exist "%INSTALLMOUNTDIR%\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" (
echo.
echo ============================================================
echo Enable .NET Framework 3.5 - index %_i%/%imgcount%
echo ============================================================
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUINetFx3.log" /Enable-Feature /Featurename:NetFx3 /All /LimitAccess /Source:"!EXTRACTDIR!\NET35\!WIMARCH%_i%!"
)
if exist "%INSTALLMOUNTDIR%\Windows\System32\Recovery\winre.wim" (
attrib -S -H -I "%INSTALLMOUNTDIR%\Windows\System32\Recovery\winre.wim" %_Nul3%
if %WINPE%==1 if not exist "!TEMPDIR!\WR\!WIMARCH%_i%!\winre.wim" call :wimre %_i%
)
if exist "!TEMPDIR!\WR\!WIMARCH%_i%!\winre.wim" (
  echo.
  echo ============================================================
  echo Add updated winre.wim to install.wim - index %_i%/%imgcount%
  echo ============================================================
  echo.
  copy /y "!TEMPDIR!\WR\!WIMARCH%_i%!\winre.wim" "%INSTALLMOUNTDIR%\Windows\System32\Recovery"
)
call :cleanmanual "%INSTALLMOUNTDIR%"
echo.
echo ============================================================
echo Unmount install.wim - index %_i%/%imgcount%
echo ============================================================
!_dism2!:"!TMPDISM!" /Unmount-Wim /MountDir:"%INSTALLMOUNTDIR%" /Commit
if !errorlevel! neq 0 goto :E_UNMOUNT
goto :eof

:wimre
echo.
echo ============================================================
echo Update winre.wim / !WIMARCH%1!
echo ============================================================
echo.
mkdir "!TEMPDIR!\WR\!WIMARCH%1!"
copy "%INSTALLMOUNTDIR%\Windows\System32\Recovery\winre.wim" "!TEMPDIR!\WR\!WIMARCH%1!"
echo.
echo ============================================================
echo Mount winre.wim
echo ============================================================
!_dism2!:"!TMPDISM!" /Mount-Wim /Wimfile:"!TEMPDIR!\WR\!WIMARCH%1!\winre.wim" /Index:1 /MountDir:"%WINREMOUNTDIR%"
if !errorlevel! neq 0 goto :E_MOUNT
echo.
echo ============================================================
echo Add LPs to winre.wim
echo ============================================================
pushd "!WinPERoot!\!WIMARCH%1!\WinPE_OCs"
if defined _PEM64 if /i !WIMARCH%1!==amd64 (
  !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP64.log" /Add-Package !_PEM64! !_PEF64!
  if !SLIM! NEQ 1 !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP64.log" /Add-Package !_PEX64!
)
if defined _PEM86 if /i !WIMARCH%1!==x86 (
  !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP86.log" /Add-Package !_PEM86! !_PEF86!
  if !SLIM! NEQ 1 !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP86.log" /Add-Package !_PEX86!
)
popd
echo.
echo ============================================================
echo Update language settings
echo ============================================================
echo.
!_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE% /Quiet
!_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE% /Quiet
if exist "%WINREMOUNTDIR%\Windows\System32\WimBootCompress.ini" (
!_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinpeClean.log" /Cleanup-Image /StartComponentCleanup /ResetBase
)
call :cleanmanual "%WINREMOUNTDIR%"
echo.
echo ============================================================
echo Unmount winre.wim
echo ============================================================
!_dism2!:"!TMPDISM!" /Unmount-Wim /MountDir:"%WINREMOUNTDIR%" /Commit
if !errorlevel! neq 0 goto :E_UNMOUNT
echo.
echo ============================================================
echo Rebuild winre.wim
echo ============================================================
!_dism2!:"!TMPDISM!" /Export-Image /SourceImageFile:"!TEMPDIR!\WR\!WIMARCH%1!\winre.wim" /All /DestinationImageFile:"!EXTRACTDIR!\winre.wim"
if exist "!EXTRACTDIR!\winre.wim" move /y "!EXTRACTDIR!\winre.wim" "!TEMPDIR!\WR\!WIMARCH%1!" %_Nul1%
goto :eof

:rebuild
echo.
echo ============================================================
echo Rebuild install.wim
echo ============================================================
!_dism2!:"!TMPDISM!" /Export-Image /SourceImageFile:"!WIMPATH!" /All /DestinationImageFile:"!TEMPDIR!\install.wim"
if exist "!TEMPDIR!\install.wim" move /y "!TEMPDIR!\install.wim" "!WIMPATH!" %_Nul1%
echo.
echo ============================================================
echo Remove temporary directories
echo ============================================================
echo.
call :remove
set MESSAGE=Finished
goto :END

:remove
if exist "!TEMPDIR!\" rmdir /s /q "!TEMPDIR!\" %_Nul3%
if exist "!MOUNTDIR!\" rmdir /s /q "!MOUNTDIR!\" %_Nul3%
goto :eof

:cleanmanual
if exist "%~1\Windows\WinSxS\ManifestCache\*.bin" (
takeown /f "%~1\Windows\WinSxS\ManifestCache\*.bin" /A %_Nul3%
icacls "%~1\Windows\WinSxS\ManifestCache\*.bin" /grant *S-1-5-32-544:F %_Nul3%
del /f /q "%~1\Windows\WinSxS\ManifestCache\*.bin" %_Nul3%
)
if exist "%~1\Windows\WinSxS\Temp\PendingDeletes\*" (
takeown /f "%~1\Windows\WinSxS\Temp\PendingDeletes\*" /A %_Null%
icacls "%~1\Windows\WinSxS\Temp\PendingDeletes\*" /grant *S-1-5-32-544:F %_Null%
del /f /q "%~1\Windows\WinSxS\Temp\PendingDeletes\*" %_Null%
)
if exist "%~1\Windows\inf\*.log" (
del /f /q "%~1\Windows\inf\*.log" %_Nul3%
)
for /f "tokens=* delims=" %%# in ('dir /b /ad "%~1\Windows\CbsTemp\" %_Nul6%') do rmdir /s /q "%~1\Windows\CbsTemp\%%#\" %_Nul3%
del /s /f /q "%~1\Windows\CbsTemp\*" %_Nul3%
goto :eof

:E_BIN
call :remove
set MESSAGE=ERROR: Could not find work binaries
goto :END

:E_DVD
call :remove
set MESSAGE=ERROR: Could not find the specified install.wim path
goto :END

:E_ESD
call :remove
set MESSAGE=ERROR: Detected install.wim file is actually .esd file
goto :END

:E_FILES
call :remove
set MESSAGE=ERROR: Could not detect any cab file in "Langs" folder
goto :END

:E_ARCH
call :remove
set MESSAGE=ERROR: None of detected LangPacks match any of WIM images architecture
goto :END

:E_LP
call :remove
set MESSAGE=ERROR: %ERRFILE% is not a valid Windows 8.1 LangPack
goto :END

:E_RTM
call :remove
set MESSAGE=ERROR: %ERRFILE% level ^(RTM^) does not match install.wim level ^(Update^)
goto :END

:E_MKDIR
set MESSAGE=ERROR: Could not create temporary directory
goto :END

:E_MOUNT
set MESSAGE=ERROR: Could not mount WIM image
goto :END

:E_UNMOUNT
set MESSAGE=ERROR: Could not unmount WIM image
goto :END

:E_ADMIN
set MESSAGE=ERROR: Run the script as administrator
goto :END

:E_PS
set MESSAGE=ERROR: wmic.exe or Windows PowerShell is required for this script to work
goto :END

:END
echo.
echo ============================================================
echo %MESSAGE%
echo ============================================================
echo.
if %_Debug% neq 0 goto :eof
echo.
echo Press 0 to exit.
choice /c 0 /n
if errorlevel 1 (goto :eof) else (rem.)
