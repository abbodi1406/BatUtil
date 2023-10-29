@setlocal DisableDelayedExpansion
@echo off

set DVDPATH=
set ISO=1
set WINPE=1
set SLIM=0

set DEFAULTLANGUAGE=
set MOUNTDIR=

:: enable debug mode
set _Debug=0

:: ###################################################################
:: # NORMALLY THERE IS NO NEED TO CHANGE ANYTHING BELOW THIS COMMENT #
:: ###################################################################

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
set "DVDDIR=%WORKDIR%\_DVD7"
set "TEMPDIR=%~d0\W7MUITEMP"
set "TMPDISM=%TEMPDIR%\scratch"
set "EXTRACTDIR=%TEMPDIR%\extract"
set "_7z=%WORKDIR%\bin\7z.exe"
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
title Windows 7 Multilingual Creator
set "_dLog=%SystemRoot%\Logs\DISM"
set _drv=%~d0
set _ntf=NTFS
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('"wmic volume where DriveLetter='%_drv%' get FileSystem /value"') do set "_ntf=%%#"
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 0 for /f %%# in ('powershell -nop -c "(([WMISEARCHER]'Select * from Win32_Volume where DriveLetter=\"%_drv%\"').Get()).FileSystem"') do set "_ntf=%%#"
if /i not "%_ntf%"=="NTFS" set _drv=%SystemDrive%
if "!MOUNTDIR!"=="" set "MOUNTDIR=%_drv%\W7MUIMOUNT"
set "INSTALLMOUNTDIR=%MOUNTDIR%\install"
set "WINREMOUNTDIR=%MOUNTDIR%\winre"
set "BOOTMOUNTDIR=%MOUNTDIR%\boot"
set EAlang=(ja-jp,ko-kr,zh-cn,zh-hk,zh-tw)
set bootmui=(arunres.dll,cmisetup.dll,compatprovider.dll,dism.exe,dismcore.dll,dismprov.dll,folderprovider.dll,input.dll,logprovider.dll,msxml6r.dll,nlsbres.dll,pnpibs.dll,rollback.exe,setup.exe,smiengine.dll,spwizres.dll,upgloader.dll,uxlibres.dll,w32uires.dll,wdsclient.dll,wdsimage.dll,winsetup.dll)

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
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" if %winbuild% lss 10240 (
set "DISMRoot=%DandIRoot%\%xOS%\DISM\dism.exe"
goto :check
)

:adk10
if %_Debug% neq 0 if %winbuild% geq 9200 goto :skipadk
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
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" if %winbuild% gtr 9600 (
set "DISMRoot=%DandIRoot%\%xOS%\DISM\dism.exe"
goto :check
)

:skipadk
set "DISMRoot=%SystemRoot%\System32\dism.exe"

:check
cd /d "!WORKDIR!"
set _winpe=0
if exist "winpe\*supplement*.iso" (
set _winpe=1
for /f "delims=" %%i in ('dir /b "winpe\*supplement*.iso"') do set "WinPERoot=!WORKDIR!\winpe\%%i"
)
if %_winpe%==0 set WINPE=0

for %%G in (7z.exe,7z.dll,cdimage.exe,imagex.exe) do (
if not exist "bin\%%G" goto :E_BIN
)
if not exist "!DISMRoot!" goto :E_BIN
set _dism2="!DISMRoot!" /English /ScratchDir

if not "!DVDPATH!"=="" goto :prepare
set _iso=0
if exist "*.iso" (for /f "delims=" %%i in ('dir /b /a:-d *.iso') do (call set /a _iso+=1))
if %_iso% neq 1 goto :prompt
for /f "delims=" %%i in ('dir /b /a:-d *.iso') do set "DVDPATH=%%i"
goto :prepare

:prompt
if %_Debug% neq 0 (
set MESSAGE=ERROR: You must auto set DVDPATH in Debug mode
goto :END
)
@cls
set DVDPATH=
echo.
echo ============================================================
echo Enter the distribution path ^(without quotes marks " "^):
echo ISO file^, Extracted ISO folder^, DVD/USB drive letter
echo ============================================================
echo.
set /p DVDPATH=
if not defined DVDPATH exit /b
set "DVDPATH=%DVDPATH:"=%"
if "%DVDPATH:~-1%"=="\" set "DVDPATH=!DVDPATH:~0,-1!"

:prepare
if not exist "!DVDPATH!" goto :E_DVD
echo.
echo ============================================================
echo Prepare work directories
echo ============================================================
echo.
if exist "!DVDDIR!\" rmdir /s /q "!DVDDIR!\" %_Nul3%
if exist "!TEMPDIR!\" rmdir /s /q "!TEMPDIR!\" %_Nul3%
if exist "!MOUNTDIR!\" rmdir /s /q "!MOUNTDIR!\" %_Nul3%
mkdir "!DVDDIR!" || goto :E_MKDIR
mkdir "!TEMPDIR!" || goto :E_MKDIR
mkdir "!TMPDISM!" || goto :E_MKDIR
mkdir "!EXTRACTDIR!" || goto :E_MKDIR
mkdir "%MOUNTDIR%" || goto :E_MKDIR
mkdir "%INSTALLMOUNTDIR%" || goto :E_MKDIR
mkdir "%WINREMOUNTDIR%" || goto :E_MKDIR
mkdir "%BOOTMOUNTDIR%" || goto :E_MKDIR
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
if exist ".\langs\*.exe" for /f %%i in ('dir /b /on ".\langs\*.exe"') do (
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
"!_7z!" e ".\langs\!LPFILE%%j!" -o"!EXTRACTDIR!" microsoft-windows-client-languagepack-package*7601*.mum %_Null%
if not exist "!EXTRACTDIR!\*.mum" set ERRFILE=!LPFILE%%j!&goto :E_SP1
for /f "tokens=3 delims=~" %%V in ('"dir "!EXTRACTDIR!\*.mum" /b" %_Nul6%') do set LPARCH%%j=%%V
del /f /q "!EXTRACTDIR!\*.mum" %_Nul3%
)
for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (echo !LANGUAGE%%j!: 64-bit {x64}) else (echo !LANGUAGE%%j!: 32-bit {x86})
set "WinpeOC%%j=!EXTRACTDIR!\WINPE\!LPARCH%%j!\WINPE_FPS"
)
echo.
echo ============================================================
echo Copy Distribution contents to work directory
echo ============================================================
echo.
echo Source Path:
echo "!DVDPATH!"
del /f /q %_dLog%\* %_Nul3%
if not exist "%_dLog%\" mkdir "%_dLog%" %_Nul3%
if /i "%DVDPATH:~-4%"==".iso" (
   "!_7z!" x "!DVDPATH!" -o"!DVDDIR!" * -r %_Nul1%
) else (
   robocopy "!DVDPATH!" "!DVDDIR!" /E /A-:R /R:1 /W:1 /NFL /NDL /NP %_Nul1%
)
if not exist "!DVDDIR!\sources\install.wim" goto :E_WIM
for /f "tokens=2 delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\install.wim" ^| findstr "Index"') do set imgcount=%%i
if %imgcount% gtr 1 if exist "!DVDDIR!\sources\ei.cfg" (
del /f /q "!DVDDIR!\sources\ei.cfg" %_Nul1%
)
if "%DEFAULTLANGUAGE%"=="" (
for /f "tokens=1" %%i in ('dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\install.wim" /index:1 ^| find /i "Default"') do set "DEFAULTLANGUAGE=%%i"
)
for /f "tokens=2 delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\boot.wim" /index:1 ^| find /i "Architecture"') do set "BOOTARCH=%%i"
if /i %BOOTARCH%==x64 set BOOTARCH=amd64
echo.
echo ============================================================
echo Detect install.wim details
echo ============================================================
echo.
for /L %%i in (1,1,%imgcount%) do (
for /f "tokens=2 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\install.wim" /index:%%i ^| find /i "Architecture"') do set "WIMARCH%%i=%%#"
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
set _PEW86=
set _PEF86=
set _PEM64=
set _PES64=
set _PEX64=
set _PEW64=
set _PEF64=
echo.
echo ============================================================
echo Extract WinPE language packs
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
"!_7z!" x "!WinPERoot!" -o"!EXTRACTDIR!\WINPE" *!LPARCH%1!\WINPE_FPS\!LANGUAGE%1! -r %_Nul1%
if not exist "!WinpeOC%1!\!LANGUAGE%1!\lp_!LANGUAGE%1!.cab" (
call set WINPE=0
goto :eof
)
echo !LANGUAGE%1! / %3
call set _PEM%2=!_PEM%2! /PackagePath:!LANGUAGE%1!\lp_!LANGUAGE%1!.cab /PackagePath:!LANGUAGE%1!\WinPE-SRT_!LANGUAGE%1!.cab
call set _PES%2=!_PES%2! /PackagePath:!LANGUAGE%1!\WinPE-Setup_!LANGUAGE%1!.cab /PackagePath:!LANGUAGE%1!\WinPE-Setup-Client_!LANGUAGE%1!.cab
call set _PEX%2=!_PEX%2! /PackagePath:!LANGUAGE%1!\WinPE-Scripting_!LANGUAGE%1!.cab
call set _PEW%2=!_PEW%2! /PackagePath:!LANGUAGE%1!\WinPE-WDS-Tools_!LANGUAGE%1!.cab /PackagePath:!LANGUAGE%1!\WinPE-WMI_!LANGUAGE%1!.cab
for %%G in %EAlang% do if /i !LANGUAGE%1!==%%G (
"!_7z!" x "!WinPERoot!" -o"!EXTRACTDIR!\WINPE" !LPARCH%1!\WINPE_FPS\WinPE-FontSupport-%%G.cab %_Nul1%
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
"!_7z!" x ".\langs\!LPFILE%1!" -o"!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!" *sp1\setup\sources\ -r %_Null%
"!_7z!" x ".\langs\!LPFILE%1!" -o"!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!" *sp1\sources\license -r %_Null%
"!_7z!" x ".\langs\!LPFILE%1!" -o"!TEMPDIR!\!LPARCH%1!\!LANGUAGE%1!" * -r %_Null%
call set _PP%2=!_PP%2! /PackagePath:!LANGUAGE%1!\update.mum
goto :eof

:dowork
set isomin=0
for /L %%i in (1,1,%imgcount%) do set "_i=%%i"&call :doinstall
goto :rewim

:doinstall
echo.
echo ============================================================
echo Mount install.wim - index %_i%/%imgcount%
echo ============================================================
!_dism2!:"!TMPDISM!" /Mount-Wim /Wimfile:"!DVDDIR!\sources\install.wim" /Index:%_i% /MountDir:"%INSTALLMOUNTDIR%"
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
if %_i%==%imgcount% (
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /Gen-LangINI /Distribution:"!DVDDIR!" /Quiet
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /Set-SetupUILang:%DEFAULTLANGUAGE% /Distribution:"!DVDDIR!" /Quiet
)
if not defined isover if exist "%INSTALLMOUNTDIR%\Windows\WinSxS\Manifests\!WIMARCH%_i%!_microsoft-windows-rollup-version*.manifest" for /f "tokens=6,7 delims=_." %%a in ('dir /b /a:-d /od "%INSTALLMOUNTDIR%\Windows\WinSxS\Manifests\!WIMARCH%_i%!_microsoft-windows-rollup-version*.manifest"') do (set isover=%%a.%%b&set isomin=%%b)
if not defined isolab call :legacyLab
if not defined isodate if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Package_for_RollupFix*.mum" (
if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
for /f %%# in ('dir /b /a:-d /od "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Package_for_RollupFix*.mum"') do copy /y "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\%%#" %SystemRoot%\temp\update.mum %_Nul1%
call :datemum isodate
)
if %_i%==%imgcount% for /L %%j in (1,1,%LANGUAGES%) do (
call :fontsEA %%j
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

:fontsEA
set _yes=0
for %%G in %EAlang% do if /i !LANGUAGE%1!==%%G (
set _yes=1
)
if %_yes%==0 goto :eof
set "_fnti=%INSTALLMOUNTDIR%\Windows\Boot\Fonts"
set "_fntw=%INSTALLMOUNTDIR%\Windows\Fonts"
set "_eal=!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!"
if /i !LANGUAGE%1!==ja-jp xcopy "!_fnti!\*" "!_eal!" /chryi %_Nul1%&copy /y "!_fntw!\meiryo.ttc" "!_eal!" %_Nul1%&copy /y "!_fntw!\msgothic.ttc" "!_eal!" %_Nul1%
if /i !LANGUAGE%1!==ko-kr xcopy "!_fnti!\*" "!_eal!" /chryi %_Nul1%&copy /y "!_fntw!\malgun.ttf" "!_eal!" %_Nul1%&copy /y "!_fntw!\gulim.ttc" "!_eal!" %_Nul1%
if /i !LANGUAGE%1!==zh-cn xcopy "!_fnti!\*" "!_eal!" /chryi %_Nul1%&copy /y "!_fntw!\msyh.ttf" "!_eal!" %_Nul1%&copy /y "!_fntw!\mingliu.ttc" "!_eal!" %_Nul1%&copy /y "!_fntw!\simsun.ttc" "!_eal!" %_Nul1%
if /i !LANGUAGE%1!==zh-hk xcopy "!_fnti!\*" "!_eal!" /chryi %_Nul1%&copy /y "!_fntw!\msjh.ttf" "!_eal!" %_Nul1%&copy /y "!_fntw!\mingliu.ttc" "!_eal!" %_Nul1%&copy /y "!_fntw!\simsun.ttc" "!_eal!" %_Nul1%
if /i !LANGUAGE%1!==zh-tw xcopy "!_fnti!\*" "!_eal!" /chryi %_Nul1%&copy /y "!_fntw!\msjh.ttf" "!_eal!" %_Nul1%&copy /y "!_fntw!\mingliu.ttc" "!_eal!" %_Nul1%&copy /y "!_fntw!\simsun.ttc" "!_eal!" %_Nul1%
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
if exist "!WORKDIR!\bin\Windows6.1-KB2883457-!WIMARCH%1!.cab" if not exist "%WINREMOUNTDIR%\Windows\servicing\packages\*kb2883457*.mum" (
echo.
echo ============================================================
echo Update Recovery Tools
echo ============================================================
!_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIkb2883457.log" /Add-Package /PackagePath:"!WORKDIR!\bin\Windows6.1-KB2883457-!WIMARCH%1!.cab"
)
echo.
echo ============================================================
echo Add LPs to winre.wim
echo ============================================================
pushd "!EXTRACTDIR!\WINPE\!WIMARCH%1!\WINPE_FPS"
if defined _PEM64 if /i !WIMARCH%1!==amd64 (
  !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP64.log" /Add-Package !_PEM64!
  !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP64.log" /Add-Package !_PES64!
  if defined _PEF64 !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP64.log" /Add-Package !_PEF64!
  if !SLIM! NEQ 1 (
  !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP64.log" /Add-Package !_PEX64!
  !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP64.log" /Add-Package !_PEW64!
  )
)
if defined _PEM86 if /i !WIMARCH%1!==x86 (
  !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP86.log" /Add-Package !_PEM86!
  !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP86.log" /Add-Package !_PES86!
  if defined _PEF86 !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP86.log" /Add-Package !_PEF86!
  if !SLIM! NEQ 1 (
  !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP86.log" /Add-Package !_PEX86!
  !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP86.log" /Add-Package !_PEW86!
  )
)
popd
echo.
echo ============================================================
echo Update language settings
echo ============================================================
echo.
!_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE% /Quiet
!_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE% /Quiet
!_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /Gen-LangINI /Distribution:"%WINREMOUNTDIR%" /Quiet
!_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /Set-SetupUILang:%DEFAULTLANGUAGE% /Distribution:"%WINREMOUNTDIR%" /Quiet
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
echo.
"!WORKDIR!\bin\imagex.exe" /BOOT /EXPORT "!TEMPDIR!\WR\!WIMARCH%1!\winre.wim" 1 "!EXTRACTDIR!\winre.wim" %_Nul1%
if exist "!EXTRACTDIR!\winre.wim" move /y "!EXTRACTDIR!\winre.wim" "!TEMPDIR!\WR\!WIMARCH%1!" %_Nul1%
goto :eof

:rewim
for /L %%i in (1,1,2) do set "_i=%%i"&call :doboot
goto :rebuild

:doboot
echo.
echo ============================================================
echo Mount boot.wim - index %_i%/2
echo ============================================================
!_dism2!:"!TMPDISM!" /Mount-Wim /WimFile:"!DVDDIR!\sources\boot.wim" /Index:%_i% /MountDir:"%BOOTMOUNTDIR%"
if !errorlevel! neq 0 goto :E_MOUNT
if exist "!WORKDIR!\bin\Windows6.1-KB2883457-%BOOTARCH%.cab" if not exist "%BOOTMOUNTDIR%\Windows\servicing\packages\*kb2883457*.mum" (
echo.
echo ============================================================
echo Update Recovery Tools
echo ============================================================
!_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIkb2883457.log" /Add-Package /PackagePath:"!WORKDIR!\bin\Windows6.1-KB2883457-%BOOTARCH%.cab"
)
if not %WINPE%==1 (
call :WIMman%_i%
goto :contboot
)
echo.
echo ============================================================
echo Add LPs to boot.wim - index %_i%/2
echo ============================================================
pushd "!EXTRACTDIR!\WINPE\!BOOTARCH!\WINPE_FPS"
if defined _PEM64 if /i !BOOTARCH!==amd64 (
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP64.log" /Add-Package !_PEM64!
  if %_i%==2 !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP64.log" /Add-Package !_PES64!
  if defined _PEF64 !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP64.log" /Add-Package !_PEF64!
  if !SLIM! NEQ 1 (
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP64.log" /Add-Package !_PEX64!
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP64.log" /Add-Package !_PEW64!
  )
)
if defined _PEM86 if /i !BOOTARCH!==x86 (
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP86.log" /Add-Package !_PEM86!
  if %_i%==2 !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP86.log" /Add-Package !_PES86!
  if defined _PEF86 !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP86.log" /Add-Package !_PEF86!
  if !SLIM! NEQ 1 (
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP86.log" /Add-Package !_PEX86!
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP86.log" /Add-Package !_PEW86!
  )
)
popd
echo.
echo ============================================================
echo Update language settings
echo ============================================================
echo.
!_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE% /Quiet
!_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE% /Quiet
if %_i%==2 (
!_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /Gen-LangINI /Distribution:"%BOOTMOUNTDIR%" /Quiet
!_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /Set-SetupUILang:%DEFAULTLANGUAGE% /Distribution:"%BOOTMOUNTDIR%" /Quiet
)
if %_i%==2 if not %wimbit%==96 for /L %%j in (1,1,%LANGUAGES%) do (
  xcopy "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!\*.rtf" "!DVDDIR!\sources\!LANGUAGE%%j!\" /chryi %_Nul3%
  xcopy "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!\*.rtf" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\" /chryi %_Nul3%
)
:contboot
call :cleanmanual "%BOOTMOUNTDIR%"
echo.
echo ============================================================
echo Unmount boot.wim - index %_i%/2
echo ============================================================
!_dism2!:"!TMPDISM!" /Unmount-Wim /MountDir:"%BOOTMOUNTDIR%" /Commit
if !errorlevel! neq 0 goto :E_UNMOUNT
goto :eof

:rebuild
echo.
echo ============================================================
echo Rebuild boot.wim
echo ============================================================
echo.
"!WORKDIR!\bin\imagex.exe" /BOOT /EXPORT "!DVDDIR!\sources\boot.wim" * "!DVDDIR!\boot.wim"
if exist "!DVDDIR!\boot.wim" move /y "!DVDDIR!\boot.wim" "!DVDDIR!\sources" %_Nul1%
echo.
echo ============================================================
echo Rebuild install.wim
echo ============================================================
echo.
"!WORKDIR!\bin\imagex.exe" /EXPORT "!DVDDIR!\sources\install.wim" * "!DVDDIR!\install.wim"
if exist "!DVDDIR!\install.wim" move /y "!DVDDIR!\install.wim" "!DVDDIR!\sources" %_Nul1%
if exist "!DVDDIR!\sources\*.clg" del /f /q "!DVDDIR!\sources\*.clg" %_Nul1%
xcopy "!DVDDIR!\efi\microsoft\boot\fonts\*" "!DVDDIR!\boot\fonts\" /chryi %_Nul3%

:dvdmui
if %SLIM% EQU 1 goto :dvdslm
echo.
echo ============================================================
echo Add language files to distribution
echo ============================================================
echo.
if /i %BOOTARCH%==x86 for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==x86 (
echo !LANGUAGE%%j! / 32-bit
call :ISOmui %%j
)
)
if /i %BOOTARCH%==amd64 for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (
echo !LANGUAGE%%j! / 64-bit
call :ISOmui %%j
)
)

:dvdslm
if %SLIM% NEQ 1 goto :fulldvd
echo.
echo ============================================================
echo Cleanup ISO payload
echo ============================================================
echo.
del /f /s /q "!DVDDIR!\ch*_boot.ttf" %_Nul3%
del /f /s /q "!DVDDIR!\jpn_boot.ttf" %_Nul3%
del /f /s /q "!DVDDIR!\kor_boot.ttf" %_Nul3%
del /f /q "!DVDDIR!\efi\microsoft\boot\cdboot_noprompt.efi" %_Nul3%
del /f /q "!DVDDIR!\efi\microsoft\boot\efisys_noprompt.bin" %_Nul3%
del /f /q "!DVDDIR!\autorun.inf" %_Nul3%
del /f /q "!DVDDIR!\setup.exe" %_Nul3%
if exist "!DVDDIR!\sources\ei.cfg" move /y "!DVDDIR!\sources\ei.cfg" "!DVDDIR!" %_Nul3%
if exist "!DVDDIR!\sources\pid.txt" move /y "!DVDDIR!\sources\pid.txt" "!DVDDIR!" %_Nul3%
move /y "!DVDDIR!\sources\boot.wim" "!DVDDIR!" %_Nul3%
move /y "!DVDDIR!\sources\install.wim" "!DVDDIR!" %_Nul3%
move /y "!DVDDIR!\sources\lang.ini" "!DVDDIR!" %_Nul3%
move /y "!DVDDIR!\sources\setup.exe" "!DVDDIR!" %_Nul3%
rmdir /s /q "!DVDDIR!\sources" %_Nul3%
rmdir /s /q "!DVDDIR!\support" %_Nul3%
rmdir /s /q "!DVDDIR!\upgrade" %_Nul3%
mkdir "!DVDDIR!\sources" %_Nul3%
if exist "!DVDDIR!\ei.cfg" move /y "!DVDDIR!\ei.cfg" "!DVDDIR!\sources" %_Nul3%
if exist "!DVDDIR!\pid.txt" move /y "!DVDDIR!\pid.txt" "!DVDDIR!\sources" %_Nul3%
move /y "!DVDDIR!\boot.wim" "!DVDDIR!\sources" %_Nul3%
move /y "!DVDDIR!\install.wim" "!DVDDIR!\sources" %_Nul3%
move /y "!DVDDIR!\lang.ini" "!DVDDIR!\sources" %_Nul3%
move /y "!DVDDIR!\setup.exe" "!DVDDIR!\sources" %_Nul3%

:fulldvd
call :DATEISO
if %_cwmi% equ 1 for /f "tokens=2 delims==." %%# in ('wmic os get localdatetime /value') do set "_date=%%#"
if %_cwmi% equ 0 for /f "tokens=1 delims=." %%# in ('powershell -nop -c "([WMI]'Win32_OperatingSystem=@').LocalDateTime"') do set "_date=%%#"
if not defined isodate set "isodate=%_date:~2,6%-%_date:~8,4%"
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set isolab=!isolab:%%#=%%#!
)
set _label=%isover%.%isodate%.%isolab%_CLIENT
if %wimbit%==32 (set archl=X86) else if %wimbit%==64 (set archl=X64) else (set archl=X86-X64)
set DVDLABEL=%isover%_%archl%_MUI
pushd "!DVDDIR!"
call :LANGISO
if defined _mui (set "DVDISO=%_label%_%archl%FRE_%_mui%.iso") else (set "DVDISO=%_label%_%archl%FRE_MUI.iso")
if %ISO%==0 (
set MESSAGE=Done. You need to create iso file yourself
goto :E_CREATEISO
)
set /a rnd=%random%
if exist "!WORKDIR!\%DVDISO%" ren "!WORKDIR!\%DVDISO%" "%rnd%_%DVDISO%"
echo.
echo ============================================================
echo Create ISO file
echo ============================================================
if exist "efi\microsoft\boot\efisys.bin" (
"!WORKDIR!\bin\cdimage.exe" -bootdata:2#p0,e,b".\boot\etfsboot.com"#pEF,e,b".\efi\microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -l"%DVDLABEL%" . "%DVDISO%"
call set errcode=!errorlevel!
) else (
"!WORKDIR!\bin\cdimage.exe" -b".\boot\etfsboot.com" -o -m -u2 -udfver102 -l"%DVDLABEL%" . "%DVDISO%"
call set errcode=!errorlevel!
)
if not exist "%DVDISO%" set errcode=1
if %errcode% equ 0 (
move /y "%DVDISO%" "!WORKDIR!\" %_Nul3%
popd
) else (
del /f /q "%DVDISO%" %_Nul3%
set MESSAGE=ERROR: Could not create ISO file
goto :E_CREATEISO
)
echo.
echo ============================================================
echo Remove temporary directories
echo ============================================================
echo.
call :remove
set MESSAGE=Finished
goto :END

:LANGISO
for %%a in (3 2 1) do (for /f "tokens=1 delims== " %%b in ('findstr %%a "sources\lang.ini"') do echo %%b>>"isolang.txt")
for /f "usebackq tokens=1" %%a in ("isolang.txt") do (
set langid=%%a
set lang=!langid:~0,2!
if /i !langid!==pt-pt set lang=pp
if /i !langid!==sr-latn-cs set lang=sr
if /i !langid!==zh-cn set lang=cn
if /i !langid!==zh-hk set lang=hk
if /i !langid!==zh-tw set lang=tw
if defined _mui (set "_mui=!_mui!_!lang!") else (set "_mui=!lang!")
)
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _mui=!_mui:%%#=%%#!
)
del /f /q "isolang.txt" %_Nul3%
goto :eof

:DATEISO
if not defined isover (if defined ntkver (set isover=%ntkver%) else if defined regver (set isover=%regver%) else (set isover=7601.17514))
if not defined isolab (if defined reglab (set isolab=%reglab%) else (set isolab=win7sp1_rtm))
if not defined ntkmin goto :eof
if %isomin% gtr %ntkmin% goto :eof
set isover=%ntkver%
set isodate=%ntkdate%
goto :eof

:legacyLab
reg.exe load HKLM\uiSOFTWARE "%INSTALLMOUNTDIR%\Windows\system32\config\SOFTWARE" %_Nul1%
for /f "skip=2 tokens=3-7 delims=. " %%i in ('"reg.exe query "HKLM\uiSOFTWARE\Microsoft\Windows NT\CurrentVersion" /v BuildLabEx" %_Nul6%') do (set regver=%%i.%%j&set regmin=%%j&set regdate=%%m&set reglab=%%l)
reg.exe unload HKLM\uiSOFTWARE %_Nul1%
for /f "tokens=3-6 delims=.() " %%i in ('powershell -nop -c "(gi '%INSTALLMOUNTDIR%\Windows\system32\ntoskrnl.exe').VersionInfo.FileVersion" %_Nul6%') do (set ntkver=%%i.%%j&set ntkmin=%%j&set ntkdate=%%l&set isolab=%%k)
goto :eof

:datemum
set "mumfile=%SystemRoot%\temp\update.mum"
set "chkfile=!mumfile:\=\\!"
if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!chkfile!'" get LastModified /value') do set "mumdate=%%#"
if %_cwmi% equ 0 for /f %%# in ('powershell -nop -c "([WMI]'CIM_DataFile.Name=''!chkfile!''').LastModified"') do set "mumdate=%%#"
del /f /q %SystemRoot%\temp\*.mum
set "%1=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
goto :eof

:remove
if exist "!DVDDIR!\" rmdir /s /q "!DVDDIR!\" %_Nul3%
if exist "!TEMPDIR!\" rmdir /s /q "!TEMPDIR!\" %_Nul3%
if exist "!MOUNTDIR!\" rmdir /s /q "!MOUNTDIR!\" %_Nul3%
goto :eof

:cleanmanual
if exist "%~1\Windows\servicing\Packages\*WinPE-LanguagePack*.mum" if exist "%~1\Windows\WinSxS\Backup\*" (
del /f /q "%~1\Windows\WinSxS\Backup\*" %_Nul3%
)
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
goto :eof

:ISOmui
set "_eal=!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!"
set "_dsl=!DVDDIR!\sources\!LANGUAGE%1!"
set "_ssl=sp1\setup\sources\!LANGUAGE%1!"
"!_7z!" e ".\langs\!LPFILE%1!" -o"!_eal!" erofflps.txt -r -aos %_Null%
"!_7z!" e ".\langs\!LPFILE%1!" -o"!_eal!" oobe_help_opt_in_details.rtf -r -aos %_Null%
"!_7z!" e ".\langs\!LPFILE%1!" -o"!_eal!" privacy.rtf -r -aos %_Null%
"!_7z!" e ".\langs\!LPFILE%1!" -o"!_eal!\mig" migautoplay.exe.mui -r -aos %_Null%
"!_7z!" e ".\langs\!LPFILE%1!" -o"!_eal!\mig" migres.dll.mui -r -aos %_Null%
"!_7z!" e ".\langs\!LPFILE%1!" -o"!_eal!\mig" migsetup.exe.mui -r -aos %_Null%
"!_7z!" e ".\langs\!LPFILE%1!" -o"!_eal!\mig" migwiz.exe.mui -r -aos %_Null%
"!_7z!" e ".\langs\!LPFILE%1!" -o"!_eal!\mig" postmig.exe.mui -r -aos %_Null%
"!_7z!" e ".\langs\!LPFILE%1!" -o"!_eal!\mig" wet.dll.mui -r -aos %_Null%
xcopy "!_eal!\!_ssl!\*" "!_dsl!" /cheryi %_Nul3%
xcopy "!_eal!\sp1\sources\license\!LANGUAGE%1!\*" "!DVDDIR!\sources\license\!LANGUAGE%1!" /cheryi %_Nul3%
rmdir /s /q "!_dsl!\dlmanifests" %_Nul3%
rmdir /s /q "!_dsl!\etwproviders" %_Nul3%
rmdir /s /q "!_dsl!\replacementmanifests" %_Nul3%
mkdir "!DVDDIR!\sources\dlmanifests\!LANGUAGE%1!" %_Nul3%
mkdir "!DVDDIR!\sources\replacementmanifests\!LANGUAGE%1!" %_Nul3%
xcopy "!_eal!\!_ssl!\dlmanifests\microsoft-windows-iasserver-migplugin\*" "!DVDDIR!\sources\dlmanifests\microsoft-windows-iasserver-migplugin\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!_eal!\!_ssl!\dlmanifests\microsoft-windows-storagemigration\*" "!DVDDIR!\sources\dlmanifests\microsoft-windows-storagemigration\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!_eal!\!_ssl!\etwproviders\*" "!DVDDIR!\sources\etwproviders\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!_eal!\!_ssl!\etwproviders\*" "!DVDDIR!\support\logging\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!_eal!\!_ssl!\replacementmanifests\microsoft-windows-offlinefiles-core\*" "!DVDDIR!\sources\replacementmanifests\microsoft-windows-offlinefiles-core\!LANGUAGE%1!\" /chryi %_Nul3%
copy "!_eal!\erofflps.txt" "!_dsl!" %_Nul3%
copy "!_eal!\oobe_help_opt_in_details.rtf" "!_dsl!" %_Nul3%
copy "!_eal!\privacy.rtf" "!_dsl!" %_Nul3%
xcopy "!_eal!\mig\*" "!DVDDIR!\support\migwiz\!LANGUAGE%1!" /chryi %_Nul3%
xcopy "!_dsl!\input*.mui" "!DVDDIR!\support\migwiz\!LANGUAGE%1!" /chryi %_Nul3%
attrib -A -S -H -I "!_dsl!" /S /D %_Nul3%
attrib -A -S -H -I "!DVDDIR!\sources\license\!LANGUAGE%1!" /S /D %_Nul3%
attrib -A -S -H -I "!DVDDIR!\support\migwiz\!LANGUAGE%1!" /S /D %_Nul3%
goto :eof

:WIMman1
for /L %%j in (1,1,%LANGUAGES%) do (
  if /i !LPARCH%%j!==!BOOTARCH! (
    if not exist "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!\" mkdir "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!"
    call :EAfonts %%j
  )
)
goto :eof

:WIMman2
  echo.
  echo ============================================================
  echo Copy language files to boot.wim - index 2
  echo ============================================================
  echo.
copy /y "!DVDDIR!\sources\lang.ini" "%BOOTMOUNTDIR%\sources" %_Nul1%
for /L %%j in (1,1,%LANGUAGES%) do (
  if /i !LPARCH%%j!==!BOOTARCH! (
    echo !LANGUAGE%%j!
    if not exist "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!\" mkdir "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!"
    copy /y "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\vofflps.rtf" "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!" %_Nul1%
    copy /y "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\help_what_is_activation.rtf" "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!" %_Nul1%
    xcopy "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\sp1\sources\license\!LANGUAGE%%j!\*" "%BOOTMOUNTDIR%\sources\License\!LANGUAGE%%j!" /cheryi %_Nul1%
    del /f /q "%BOOTMOUNTDIR%\sources\License\!LANGUAGE%%j!\_default\lipeula.rtf" %_Nul1%
    del /f /q "%BOOTMOUNTDIR%\sources\License\!LANGUAGE%%j!\_default\lpeula.rtf" %_Nul1%
    for %%G in %bootmui% do (
    copy /y "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\sp1\setup\sources\!LANGUAGE%%j!\%%G.mui" "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!" %_Nul3%
    )
    attrib -A -S -H -I "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!" /S /D %_Nul1%
    attrib -A -S -H -I "%BOOTMOUNTDIR%\sources\license\!LANGUAGE%%j!" /S /D %_Nul1%
    call :EAfonts %%j
  )
)
goto :eof

:EAfonts
set _yes=0
for %%G in %EAlang% do if /i !LANGUAGE%1!==%%G (
set _yes=1
)
if %_yes%==0 goto :eof
set "_eal=!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!"
set "_fntb=%BOOTMOUNTDIR%\Windows\Boot\Fonts"
set "_fntw=%BOOTMOUNTDIR%\Windows\Fonts"
echo.
echo ============================================================
echo Add Font Support: !LANGUAGE%1!
echo ============================================================
echo.
if /i !LANGUAGE%1!==ja-jp (
copy /y "!_eal!\jpn_boot.ttf" "!_fntb!" %_Nul1%
copy /y "!_eal!\meiryo.ttc" "!_fntw!" %_Nul1%&copy /y "!_eal!\msgothic.ttc" "!_fntw!" %_Nul1%
reg.exe load HKLM\OFFLINE "%BOOTMOUNTDIR%\Windows\System32\config\SOFTWARE" %_Nul1%&reg.exe import "!WORKDIR!\bin\EA\ja-jp.reg" %_Nul1%&reg.exe unload HKLM\OFFLINE %_Nul1%
goto :eof
)
if /i !LANGUAGE%1!==ko-kr (
copy /y "!_eal!\kor_boot.ttf" "!_fntb!" %_Nul1%
copy /y "!_eal!\malgun.ttf" "!_fntw!" %_Nul1%&copy /y "!_eal!\gulim.ttc" "!_fntw!" %_Nul1%
reg.exe load HKLM\OFFLINE "%BOOTMOUNTDIR%\Windows\System32\config\SOFTWARE" %_Nul1%&reg.exe import "!WORKDIR!\bin\EA\ko-kr.reg" %_Nul1%&reg.exe unload HKLM\OFFLINE %_Nul1%
goto :eof
)
if /i !LANGUAGE%1!==zh-cn (
copy /y "!_eal!\chs_boot.ttf" "!_fntb!" %_Nul1%
copy /y "!_eal!\msyh.ttf" "!_fntw!" %_Nul1%&copy /y "!_eal!\mingliu.ttc" "!_fntw!" %_Nul1%&copy /y "!_eal!\simsun.ttc" "!_fntw!" %_Nul1%
reg.exe load HKLM\OFFLINE "%BOOTMOUNTDIR%\Windows\System32\config\SOFTWARE" %_Nul1%&reg.exe import "!WORKDIR!\bin\EA\zh-cn.reg" %_Nul1%&reg.exe unload HKLM\OFFLINE %_Nul1%
goto :eof
)
if /i !LANGUAGE%1!==zh-hk (
copy /y "!_eal!\cht_boot.ttf" "!_fntb!" %_Nul1%
copy /y "!_eal!\msjh.ttf" "!_fntw!" %_Nul1%&copy /y "!_eal!\mingliu.ttc" "!_fntw!" %_Nul1%&copy /y "!_eal!\simsun.ttc" "!_fntw!" %_Nul1%
reg.exe load HKLM\OFFLINE "%BOOTMOUNTDIR%\Windows\System32\config\SOFTWARE" %_Nul1%&reg.exe import "!WORKDIR!\bin\EA\zh-hk.reg" %_Nul1%&reg.exe unload HKLM\OFFLINE %_Nul1%
goto :eof
)
if /i !LANGUAGE%1!==zh-tw (
copy /y "!_eal!\cht_boot.ttf" "!_fntb!" %_Nul1%&
copy /y "!_eal!\msjh.ttf" "!_fntw!" %_Nul1%&copy /y "!_eal!\mingliu.ttc" "!_fntw!" %_Nul1%&copy /y "!_eal!\simsun.ttc" "!_fntw!" %_Nul1%
reg.exe load HKLM\OFFLINE "%BOOTMOUNTDIR%\Windows\System32\config\SOFTWARE" %_Nul1%&reg.exe import "!WORKDIR!\bin\EA\zh-tw.reg" %_Nul1%&reg.exe unload HKLM\OFFLINE %_Nul1%
goto :eof
)
goto :eof

:E_BIN
call :remove
set MESSAGE=ERROR: Could not find work binaries
goto :END

:E_DVD
call :remove
set MESSAGE=ERROR: Could not find the specified distribution path
goto :END

:E_WIM
call :remove
set MESSAGE=ERROR: Could not find install.wim file in \sources folder
goto :END

:E_FILES
call :remove
set MESSAGE=ERROR: Could not detect any cab/exe files in "Langs" folder
goto :END

:E_ARCH
call :remove
set MESSAGE=ERROR: None of detected LangPacks match any of WIM images architecture
goto :END

:E_SP1
call :remove
set MESSAGE=ERROR: %ERRFILE% is not a valid Windows 7 SP1 LangPack
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

:E_CREATEISO
echo.
echo ============================================================
echo Remove temporary directories
echo ============================================================
echo.
popd
ren "!DVDDIR!" "%DVDISO:~0,-4%"
if exist "!TEMPDIR!\" rmdir /s /q "!TEMPDIR!\" %_Nul3%
if exist "!MOUNTDIR!\" rmdir /s /q "!MOUNTDIR!\" %_Nul3%
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
