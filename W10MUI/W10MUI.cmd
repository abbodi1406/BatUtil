@setlocal DisableDelayedExpansion
@echo off

set DVDPATH=
set ISO=1
set WINPE=1
set SLIM=1
set NET35=0

set WINPEPATH=

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
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "xOS=amd64"
if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set "xOS=arm64"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "xOS=x86"
if /i "%PROCESSOR_ARCHITEW6432%"=="amd64" set "xOS=amd64"
if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" set "xOS=arm64"
set "_Null=1>nul 2>nul"
reg.exe query HKU\S-1-5-19 %_Null% || goto :E_ADMIN
set "_log=%~dpn0"
set "WORKDIR=%~dp0"
set "WORKDIR=%WORKDIR:~0,-1%"
set "DVDDIR=%WORKDIR%\_DVD"
set "TEMPDIR=%~d0\W10MUITEMP"
set "TMPDISM=%TEMPDIR%\scratch"
set "EXTRACTDIR=%TEMPDIR%\extract"
set "TMPUPDT=%TEMPDIR%\updtemp"
set "_7z=%WORKDIR%\dism\7z.exe"
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
copy /y nul "!WORKDIR!\#.rw" %_Null% && (if exist "!WORKDIR!\#.rw" del /f /q "!WORKDIR!\#.rw") || (set "_log=!_dsk!\%~n0")
if exist "!_log!_Debug.log" (
  call set "_suf="
  for /f "tokens=2 delims==." %%# in ('wmic os get localdatetime /value') do set "_date=%%#"
  set "_suf=_!_date:~8,6!"
)
echo.
echo Running in Debug Mode...
echo The window will be closed when finished
@echo on
@prompt $G
@call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug!_suf!.log"&del "!_log!_tmp.log"
@title %ComSpec%
@exit /b

:Begin
title Windows NT 10.0 Multilingual Creator
set "_dLog=%SystemRoot%\Logs\DISM"
set _drv=%~d0
set _ntf=NTFS
if /i not "%_drv%"=="%SystemDrive%" for /f "tokens=2 delims==" %%# in ('"wmic volume where DriveLetter='%_drv%' get FileSystem /value"') do set "_ntf=%%#"
if /i not "%_ntf%"=="NTFS" set _drv=%SystemDrive%
if "!MOUNTDIR!"=="" set "MOUNTDIR=%_drv%\W10MUIMOUNT"
set "INSTALLMOUNTDIR=%MOUNTDIR%\install"
set "WINREMOUNTDIR=%MOUNTDIR%\winre"
set "BOOTMOUNTDIR=%MOUNTDIR%\boot"
set EAlang=(ja-jp,ko-kr,zh-cn,zh-hk,zh-tw)
set bootmui=(appraiser.dll,arunres.dll,cmisetup.dll,compatctrl.dll,compatprovider.dll,dism.exe,dismapi.dll,dismcore.dll,dismprov.dll,folderprovider.dll,imagingprovider.dll,input.dll,logprovider.dll,mediasetupuimgr.dll,nlsbres.dll,pnpibs.dll,reagent.dll,rollback.exe,setup.exe,setupcompat.dll,setupcore.dll,setupmgr.dll,setupplatform.exe,setupprep.exe,smiengine.dll,spwizres.dll,upgloader.dll,uxlibres.dll,vhdprovider.dll,w32uires.dll,wdsclient.dll,wdsimage.dll,wimgapi.dll,wimprovider.dll,windlp.dll,winsetup.dll)

:adkcheck
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
set "WinPERoot=%KitsRoot%Assessment and Deployment Kit\Windows Preinstallation Environment"
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" (
set "DISMRoot=%DandIRoot%\%xOS%\DISM\dism.exe"
goto :check
)
if /i %xOS%==arm64 if exist "%DandIRoot%\x86\DISM\dism.exe" (
set "DISMRoot=%DandIRoot%\x86\DISM\dism.exe"
goto :check
)

:skipadk
set "DISMRoot=!WORKDIR!\dism\dism.exe"
if /i %xOS%==amd64 set "DISMRoot=!WORKDIR!\dism\dism64\dism.exe"
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
if %winbuild% geq 10240 set "DISMRoot=%SystemRoot%\System32\dism.exe"

:check
if not "!WINPEPATH!"=="" set "WinPERoot=!WINPEPATH!"
if not exist "!WinPERoot!\amd64\WinPE_OCs\*" if not exist "!WinPERoot!\x86\WinPE_OCs\*" set WINPE=0
cd /d "!WORKDIR!"
if not exist "!_7z!" goto :E_BIN
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
if exist ".\langs\*.esd" for /f %%i in ('dir /b /on ".\langs\*.esd"') do (
set /a _ol+=1
set /a count+=1
set "LPFILE!count!=%%i"
)
if %_ol% equ 0 goto :E_FILES
set LANGUAGES=%_ol%
set count=0
set _oa=0
if exist ".\ondemand\x86\*.cab" for /f %%i in ('dir /b ".\ondemand\x86\*.cab"') do (
set /a _oa+=1
set /a count+=1
set "OAFILE!count!=%%i"
)
set count=0
set _ob=0
if exist ".\ondemand\x64\*.cab" for /f %%i in ('dir /b ".\ondemand\x64\*.cab"') do (
set /a _ob+=1
set /a count+=1
set "OBFILE!count!=%%i"
)
set foundupdates=0
if exist ".\Updates\W10UI.cmd" (
if exist ".\Updates\SSU-*-*.cab" set foundupdates=1
if exist ".\Updates\SSU-*-*.msu" set foundupdates=1
if exist ".\Updates\*Windows10*KB*.cab" set foundupdates=1
if exist ".\Updates\*Windows10*KB*.msu" set foundupdates=1
)

for /L %%j in (1,1,%LANGUAGES%) do (
"!_7z!" e ".\langs\!LPFILE%%j!" -o"!EXTRACTDIR!" langcfg.ini %_Nul1%
for /f "tokens=2 delims==" %%i in ('type "!EXTRACTDIR!\langcfg.ini" ^| findstr /i "Language"') do set "LANGUAGE%%j=%%i"
del /f /q "!EXTRACTDIR!\langcfg.ini"
"!_7z!" e ".\langs\!LPFILE%%j!" -o"!EXTRACTDIR!" Microsoft-Windows-Common-Foundation-Package*10.*.mum %_Nul3%
if not exist "!EXTRACTDIR!\*.mum" set "ERRFILE=!LPFILE%%j!"&goto :E_LP
for /f "tokens=7 delims=~." %%g in ('"dir "!EXTRACTDIR!\*.mum" /b" %_Nul6%') do set "LPBUILD%%j=%%g"
for /f "tokens=3 delims=~" %%V in ('"dir "!EXTRACTDIR!\*.mum" /b" %_Nul6%') do set "LPARCH%%j=%%V"
del /f /q "!EXTRACTDIR!\*.mum" %_Nul3%
)
for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (echo !LANGUAGE%%j!: 64-bit {x64} - !LPBUILD%%j!) else (echo !LANGUAGE%%j!: 32-bit {x86} - !LPBUILD%%j!)
set "WinpeOC%%j=!WinPERoot!\!LPARCH%%j!\WinPE_OCs"
)
for /L %%j in (1,1,%LANGUAGES%) do (
if not exist "!WinpeOC%%j!\!LANGUAGE%%j!\lp.cab" set WINPE=0
)
set _lpver=%LPBUILD1%

set _ODbasic86=
set _ODfont86=
set _ODhand86=
set _ODocr86=
set _ODspeech86=
set _ODtts86=
set _ODintl86=
set _ODext86=
set _ODtra86=
set _ODpaint86=
set _ODnote86=
set _ODpower86=
set _ODpmcppc86=
set _ODpwsf86=
set _ODword86=
set _ODsnip86=
set _ODnots86=
if %_oa% neq 0 for /L %%j in (1,1,%_oa%) do (
"!_7z!" x ".\ondemand\x86\!OAFILE%%j!" -o"!TEMPDIR!\FOD86\OAFILE%%j" * -r %_Null%
pushd "!TEMPDIR!\FOD86\OAFILE%%j"
findstr /i /m Microsoft-Windows-LanguageFeatures-Basic update.mum %_Nul3% && call set _ODbasic86=!_ODbasic86! /PackagePath:OAFILE%%j\update.mum
findstr /i /m Microsoft-Windows-LanguageFeatures-Fonts update.mum %_Nul3% && call set _ODfont86=!_ODfont86! /PackagePath:OAFILE%%j\update.mum
findstr /i /m Microsoft-Windows-LanguageFeatures-Handwriting update.mum %_Nul3% && call set _ODhand86=!_ODhand86! /PackagePath:OAFILE%%j\update.mum
findstr /i /m Microsoft-Windows-LanguageFeatures-OCR update.mum %_Nul3% && call set _ODocr86=!_ODocr86! /PackagePath:OAFILE%%j\update.mum
findstr /i /m Microsoft-Windows-LanguageFeatures-Speech update.mum %_Nul3% && call set _ODspeech86=!_ODspeech86! /PackagePath:OAFILE%%j\update.mum
findstr /i /m Microsoft-Windows-LanguageFeatures-TextToSpeech update.mum %_Nul3% && call set _ODtts86=!_ODtts86! /PackagePath:OAFILE%%j\update.mum
findstr /i /m Microsoft-Windows-InternationalFeatures update.mum %_Nul3% && call set _ODintl86=!_ODintl86! /PackagePath:OAFILE%%j\update.mum
if %_lpver% geq 19041 (
findstr /i /m Microsoft-Windows-MSPaint-FoD update.mum %_Nul3% && (set _ODext86=1&call set _ODpaint86=!_ODpaint86! /PackagePath:OAFILE%%j\update.mum)
findstr /i /m Microsoft-Windows-Notepad-FoD update.mum %_Nul3% && (set _ODext86=1&call set _ODnote86=!_ODnote86! /PackagePath:OAFILE%%j\update.mum)
findstr /i /m Microsoft-Windows-PowerShell-ISE-FOD update.mum %_Nul3% && (set _ODext86=1&call set _ODpower86=!_ODpower86! /PackagePath:OAFILE%%j\update.mum)
findstr /i /m Microsoft-Windows-Printing-PMCPPC-FoD update.mum %_Nul3% && (set _ODtra86=1&call set _ODpmcppc86=!_ODpmcppc86! /PackagePath:OAFILE%%j\update.mum)
findstr /i /m Microsoft-Windows-Printing-WFS-FoD update.mum %_Nul3% && (set _ODtra86=1&call set _ODpwsf86=!_ODpwsf86! /PackagePath:OAFILE%%j\update.mum)
findstr /i /m Microsoft-Windows-WordPad-FoD update.mum %_Nul3% && (set _ODtra86=1&call set _ODword86=!_ODword86! /PackagePath:OAFILE%%j\update.mum)
  )
if %_lpver% geq 21277 (
findstr /i /m Microsoft-Windows-SnippingTool-FoD update.mum %_Nul3% && (set _ODtra86=1&call set _ODsnip86=!_ODsnip86! /PackagePath:OAFILE%%j\update.mum)
findstr /i /m Microsoft-Windows-Notepad-System-FoD update.mum %_Nul3% && (set _ODtra86=1&call set _ODnots86=!_ODnots86! /PackagePath:OAFILE%%j\update.mum)
  )
popd
)
set _ODbasic64=
set _ODfont64=
set _ODhand64=
set _ODocr64=
set _ODspeech64=
set _ODtts64=
set _ODintl64=
set _ODext64=
set _ODtra64=
set _ODpaint64=
set _ODnote64=
set _ODpower64=
set _ODpmcppc64=
set _ODpwsf64=
set _ODword64=
set _ODsnip64=
set _ODnots64=
if %_ob% neq 0 for /L %%j in (1,1,%_ob%) do (
"!_7z!" x ".\ondemand\x64\!OBFILE%%j!" -o"!TEMPDIR!\FOD64\OBFILE%%j" * -r %_Null%
pushd "!TEMPDIR!\FOD64\OBFILE%%j"
findstr /i /m Microsoft-Windows-LanguageFeatures-Basic update.mum %_Nul3% && call set _ODbasic64=!_ODbasic64! /PackagePath:OBFILE%%j\update.mum
findstr /i /m Microsoft-Windows-LanguageFeatures-Fonts update.mum %_Nul3% && call set _ODfont64=!_ODfont64! /PackagePath:OBFILE%%j\update.mum
findstr /i /m Microsoft-Windows-LanguageFeatures-Handwriting update.mum %_Nul3% && call set _ODhand64=!_ODhand64! /PackagePath:OBFILE%%j\update.mum
findstr /i /m Microsoft-Windows-LanguageFeatures-OCR update.mum %_Nul3% && call set _ODocr64=!_ODocr64! /PackagePath:OBFILE%%j\update.mum
findstr /i /m Microsoft-Windows-LanguageFeatures-Speech update.mum %_Nul3% && call set _ODspeech64=!_ODspeech64! /PackagePath:OBFILE%%j\update.mum
findstr /i /m Microsoft-Windows-LanguageFeatures-TextToSpeech update.mum %_Nul3% && call set _ODtts64=!_ODtts64! /PackagePath:OBFILE%%j\update.mum
findstr /i /m Microsoft-Windows-InternationalFeatures update.mum %_Nul3% && call set _ODintl64=!_ODintl64! /PackagePath:OBFILE%%j\update.mum
if %_lpver% geq 19041 (
findstr /i /m Microsoft-Windows-MSPaint-FoD update.mum %_Nul3% && (set _ODext64=1&call set _ODpaint64=!_ODpaint64! /PackagePath:OBFILE%%j\update.mum)
findstr /i /m Microsoft-Windows-Notepad-FoD update.mum %_Nul3% && (set _ODext64=1&call set _ODnote64=!_ODnote64! /PackagePath:OBFILE%%j\update.mum)
findstr /i /m Microsoft-Windows-PowerShell-ISE-FOD update.mum %_Nul3% && (set _ODext64=1&call set _ODpower64=!_ODpower64! /PackagePath:OBFILE%%j\update.mum)
findstr /i /m Microsoft-Windows-Printing-PMCPPC-FoD update.mum %_Nul3% && (set _ODtra64=1&call set _ODpmcppc64=!_ODpmcppc64! /PackagePath:OBFILE%%j\update.mum)
findstr /i /m Microsoft-Windows-Printing-WFS-FoD update.mum %_Nul3% && (set _ODtra64=1&call set _ODpwsf64=!_ODpwsf64! /PackagePath:OBFILE%%j\update.mum)
findstr /i /m Microsoft-Windows-WordPad-FoD update.mum %_Nul3% && (set _ODtra64=1&call set _ODword64=!_ODword64! /PackagePath:OBFILE%%j\update.mum)
  )
if %_lpver% geq 21277 (
findstr /i /m Microsoft-Windows-SnippingTool-FoD update.mum %_Nul3% && (set _ODtra64=1&call set _ODsnip64=!_ODsnip64! /PackagePath:OBFILE%%j\update.mum)
findstr /i /m Microsoft-Windows-Notepad-System-FoD update.mum %_Nul3% && (set _ODtra64=1&call set _ODnots64=!_ODnots64! /PackagePath:OBFILE%%j\update.mum)
  )
popd
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
if not exist "!DVDDIR!\sources\sxs\*netfx3*.cab" set NET35=0
if not exist "!DVDDIR!\sources\install.wim" goto :E_WIM
dism\imagex.exe /info "!DVDDIR!\sources\install.wim" | findstr /c:"LZMS" %_Nul1% && goto :E_ESD
for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\install.wim" ^| findstr "Index"') do set imgcount=%%i
for /f "tokens=4 delims=:. " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\install.wim" /index:1 ^| find /i "Version :"') do set _build=%%i
if %_build% equ 18363 set _build=18362
if %_build% equ 19042 set _build=19041
if %_build% equ 19043 set _build=19041
if %_build% equ 19044 set _build=19041
if %_build% equ 19045 set _build=19041
for /L %%j in (1,1,%LANGUAGES%) do (
if not !LPBUILD%%j!==%_build% set "ERRFILE=!LPFILE%%j!"&goto :E_VER
)
if %WINPE%==1 for /L %%j in (1,1,%LANGUAGES%) do (
"!_7z!" e "!WinpeOC%%j!\!LANGUAGE%%j!\lp.cab" -o"!EXTRACTDIR!" Microsoft-Windows-Common-Foundation-Package*%_build%*.mum %_Nul3%
if not exist "!EXTRACTDIR!\*.mum" set WINPE=0
)
if "%DEFAULTLANGUAGE%"=="" (
for /f "tokens=1" %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\install.wim" /index:1 ^| find /i "Default"') do set "DEFAULTLANGUAGE=%%i"
)
for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\boot.wim" ^| findstr "Index"') do set BOOTCOUNT=%%i
for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\boot.wim" /index:1 ^| find /i "Architecture"') do set BOOTARCH=%%i
if /i %BOOTARCH%==x64 set BOOTARCH=amd64
echo.
echo ============================================================
echo Detect install.wim details
echo ============================================================
echo.
for /L %%i in (1,1,%imgcount%) do (
for /f "tokens=2 delims=: " %%# in ('dism\dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\install.wim" /index:%%i ^| find /i "Architecture"') do set "WIMARCH%%i=%%#"
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
if %_label86%==1 (set wimbit=dual) else (set wimbit=64)
)
echo Build: %_build%
echo Count: %imgcount% Image^(s^)
if %wimbit%==dual (echo Arch : Multi) else (echo Arch : %wimbit%-bit)
if %wimbit%==dual set NET35=0

if %WINPE% NEQ 1 goto :extract
set _PEM86=
set _PES86=
set _PEX86=
set _PEF86=
set _PER86=
set _PEM64=
set _PES64=
set _PEX64=
set _PEF64=
set _PER64=
echo.
echo ============================================================
echo Set WinPE language packs paths
echo ============================================================
echo.
if %wimbit%==32 for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==x86 (
echo !LANGUAGE%%j! / 32-bit
call set _PEM86=!_PEM86! /PackagePath:!LANGUAGE%%j!\lp.cab /PackagePath:!LANGUAGE%%j!\WinPE-SRT_!LANGUAGE%%j!.cab
call set _PES86=!_PES86! /PackagePath:!LANGUAGE%%j!\WinPE-Setup_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-Setup-Client_!LANGUAGE%%j!.cab
call set _PER86=!_PER86! /PackagePath:!LANGUAGE%%j!\WinPE-HTA_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-Rejuv_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-StorageWMI_!LANGUAGE%%j!.cab
call set _PEX86=!_PEX86! /PackagePath:!LANGUAGE%%j!\WinPE-EnhancedStorage_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-Scripting_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-SecureStartup_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-WDS-Tools_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-WMI_!LANGUAGE%%j!.cab
 for %%G in %EAlang% do (
 if /i !LANGUAGE%%j!==%%G call set _PEF86=!_PEF86! /PackagePath:WinPE-FontSupport-%%G.cab
 )
)
)
if %wimbit%==64 for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (
echo !LANGUAGE%%j! / 64-bit
call set _PEM64=!_PEM64! /PackagePath:!LANGUAGE%%j!\lp.cab /PackagePath:!LANGUAGE%%j!\WinPE-SRT_!LANGUAGE%%j!.cab
call set _PES64=!_PES64! /PackagePath:!LANGUAGE%%j!\WinPE-Setup_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-Setup-Client_!LANGUAGE%%j!.cab
call set _PER64=!_PER64! /PackagePath:!LANGUAGE%%j!\WinPE-HTA_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-Rejuv_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-StorageWMI_!LANGUAGE%%j!.cab
call set _PEX64=!_PEX64! /PackagePath:!LANGUAGE%%j!\WinPE-EnhancedStorage_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-Scripting_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-SecureStartup_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-WDS-Tools_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-WMI_!LANGUAGE%%j!.cab
 for %%G in %EAlang% do (
 if /i !LANGUAGE%%j!==%%G call set _PEF64=!_PEF64! /PackagePath:WinPE-FontSupport-%%G.cab
 )
)
)
if %wimbit%==dual for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==x86 (
echo !LANGUAGE%%j! / 32-bit
call set _PEM86=!_PEM86! /PackagePath:!LANGUAGE%%j!\lp.cab /PackagePath:!LANGUAGE%%j!\WinPE-SRT_!LANGUAGE%%j!.cab
call set _PES86=!_PES86! /PackagePath:!LANGUAGE%%j!\WinPE-Setup_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-Setup-Client_!LANGUAGE%%j!.cab
call set _PER86=!_PER86! /PackagePath:!LANGUAGE%%j!\WinPE-HTA_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-Rejuv_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-StorageWMI_!LANGUAGE%%j!.cab
call set _PEX86=!_PEX86! /PackagePath:!LANGUAGE%%j!\WinPE-EnhancedStorage_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-Scripting_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-SecureStartup_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-WDS-Tools_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-WMI_!LANGUAGE%%j!.cab
 for %%G in %EAlang% do (
 if /i !LANGUAGE%%j!==%%G call set _PEF86=!_PEF86! /PackagePath:WinPE-FontSupport-%%G.cab
 )
) else (
echo !LANGUAGE%%j! / 64-bit
call set _PEM64=!_PEM64! /PackagePath:!LANGUAGE%%j!\lp.cab /PackagePath:!LANGUAGE%%j!\WinPE-SRT_!LANGUAGE%%j!.cab
call set _PES64=!_PES64! /PackagePath:!LANGUAGE%%j!\WinPE-Setup_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-Setup-Client_!LANGUAGE%%j!.cab
call set _PER64=!_PER64! /PackagePath:!LANGUAGE%%j!\WinPE-HTA_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-Rejuv_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-StorageWMI_!LANGUAGE%%j!.cab
call set _PEX64=!_PEX64! /PackagePath:!LANGUAGE%%j!\WinPE-EnhancedStorage_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-Scripting_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-SecureStartup_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-WDS-Tools_!LANGUAGE%%j!.cab /PackagePath:!LANGUAGE%%j!\WinPE-WMI_!LANGUAGE%%j!.cab
 for %%G in %EAlang% do (
 if /i !LANGUAGE%%j!==%%G call set _PEF64=!_PEF64! /PackagePath:WinPE-FontSupport-%%G.cab
 )
)
)

:extract
set _PP86=
set _PP64=
echo.
echo ============================================================
echo Extract language packs
echo ============================================================
echo.
if %wimbit%==32 for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==x86 (
echo !LANGUAGE%%j! / 32-bit
"!_7z!" e ".\langs\!LPFILE%%j!" -o"!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" vofflps.rtf -r -aos %_Null%
"!_7z!" x ".\langs\!LPFILE%%j!" -o"!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" *setup\sources -r %_Null%
"!_7z!" x ".\langs\!LPFILE%%j!" -o"!TEMPDIR!\!LPARCH%%j!\!LANGUAGE%%j!" * -r %_Null%
if not exist "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\*.mui" (robocopy "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources" "!EXTRACTDIR!\TEMP\!LANGUAGE%%j!" /E /MOVE %_Nul1%&robocopy "!EXTRACTDIR!\TEMP\!LANGUAGE%%j!" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!" /E /MOVE %_Nul1%) 
call set _PP86=!_PP86! /PackagePath:!LANGUAGE%%j!\update.mum
)
)
if %wimbit%==64 for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==amd64 (
echo !LANGUAGE%%j! / 64-bit
"!_7z!" e ".\langs\!LPFILE%%j!" -o"!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" vofflps.rtf -r -aos %_Null%
"!_7z!" x ".\langs\!LPFILE%%j!" -o"!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" *setup\sources -r %_Null%
"!_7z!" x ".\langs\!LPFILE%%j!" -o"!TEMPDIR!\!LPARCH%%j!\!LANGUAGE%%j!" * -r %_Null%
if not exist "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\*.mui" (robocopy "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources" "!EXTRACTDIR!\TEMP\!LANGUAGE%%j!" /E /MOVE %_Nul1%&robocopy "!EXTRACTDIR!\TEMP\!LANGUAGE%%j!" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!" /E /MOVE %_Nul1%) 
call set _PP64=!_PP64! /PackagePath:!LANGUAGE%%j!\update.mum
)
)
if %wimbit%==dual for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LPARCH%%j!==x86 (
echo !LANGUAGE%%j! / 32-bit
"!_7z!" e ".\langs\!LPFILE%%j!" -o"!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" vofflps.rtf -r -aos %_Null%
"!_7z!" x ".\langs\!LPFILE%%j!" -o"!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" *setup\sources -r %_Null%
"!_7z!" x ".\langs\!LPFILE%%j!" -o"!TEMPDIR!\!LPARCH%%j!\!LANGUAGE%%j!" * -r %_Null%
if not exist "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\*.mui" (robocopy "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources" "!EXTRACTDIR!\TEMP\!LANGUAGE%%j!" /E /MOVE %_Nul1%&robocopy "!EXTRACTDIR!\TEMP\!LANGUAGE%%j!" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!" /E /MOVE %_Nul1%) 
call set _PP86=!_PP86! /PackagePath:!LANGUAGE%%j!\update.mum
) else (
echo !LANGUAGE%%j! / 64-bit
"!_7z!" e ".\langs\!LPFILE%%j!" -o"!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" vofflps.rtf -r -aos %_Null%
"!_7z!" x ".\langs\!LPFILE%%j!" -o"!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" *setup\sources -r %_Null%
"!_7z!" x ".\langs\!LPFILE%%j!" -o"!TEMPDIR!\!LPARCH%%j!\!LANGUAGE%%j!" * -r %_Null%
if not exist "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\*.mui" (robocopy "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources" "!EXTRACTDIR!\TEMP\!LANGUAGE%%j!" /E /MOVE %_Nul1%&robocopy "!EXTRACTDIR!\TEMP\!LANGUAGE%%j!" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!" /E /MOVE %_Nul1%) 
call set _PP64=!_PP64! /PackagePath:!LANGUAGE%%j!\update.mum
)
)
if %wimbit%==32 if not defined _PP86 goto :E_ARCH
if %wimbit%==64 if not defined _PP64 goto :E_ARCH

if %SLIM% EQU 1 goto :proceed
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

:proceed
set _actEP=0
set _SrvEdt=0
if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
if exist "%SystemRoot%\temp\UpdateAgent.dll" del /f /q "%SystemRoot%\temp\UpdateAgent.dll" %_Nul3%
if exist "%SystemRoot%\temp\Facilitator.dll" del /f /q "%SystemRoot%\temp\Facilitator.dll" %_Nul3%
for /L %%i in (1,1,%imgcount%) do (
echo.
echo ============================================================
echo Mount install.wim - index %%i/%imgcount%
echo ============================================================
!_dism2!:"!TMPDISM!" /Mount-Wim /Wimfile:"!DVDDIR!\sources\install.wim" /Index:%%i /MountDir:"%INSTALLMOUNTDIR%"
if !errorlevel! neq 0 goto :E_MOUNT
echo.
echo ============================================================
echo Add LPs to install.wim - index %%i/%imgcount%
echo ============================================================
pushd "!TEMPDIR!\!WIMARCH%%i!"
if defined _PP64 if /i !WIMARCH%%i!==amd64 (
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallLP64.log" /Add-Package !_PP64!
)
if defined _PP86 if /i !WIMARCH%%i!==x86 (
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallLP86.log" /Add-Package !_PP86!
)
popd
if /i !WIMARCH%%i!==amd64 if exist "!TEMPDIR!\FOD64\OBFILE1\update.mum" (
pushd "!TEMPDIR!\FOD64"
if defined _ODbasic64 !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallFOD64.log" /Add-Package !_ODbasic64!
if defined _ODbasic64 !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallFOD64.log" /Add-Package !_ODfont64! !_ODtts64! !_ODhand64! !_ODocr64! !_ODspeech64! !_ODintl64!
if defined _ODext64 !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallFOD64.log" /Add-Package !_ODpaint64! !_ODnote64! !_ODpower64!
if defined _ODtra64 !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallFOD64.log" /Add-Package !_ODpmcppc64! !_ODpwsf64! !_ODword64! !_ODsnip64! !_ODnots64!
popd
)
if /i !WIMARCH%%i!==x86 if exist "!TEMPDIR!\FOD86\OAFILE1\update.mum" (
pushd "!TEMPDIR!\FOD86"
if defined _ODbasic86 !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallFOD86.log" /Add-Package !_ODbasic86!
if defined _ODbasic86 !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallFOD86.log" /Add-Package !_ODfont86! !_ODtts86! !_ODhand86! !_ODocr86! !_ODspeech86! !_ODintl86!
if defined _ODext86 !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallFOD86.log" /Add-Package !_ODpaint86! !_ODnote86! !_ODpower86!
if defined _ODtra86 !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallFOD86.log" /Add-Package !_ODpmcppc86! !_ODpwsf86! !_ODword86! !_ODsnip86! !_ODnots86!
popd
)
echo.
echo ============================================================
echo Update language settings
echo ============================================================
echo.
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE% /Quiet
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE% /Quiet
if %%i==%imgcount% (
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /Gen-LangINI /Distribution:"!DVDDIR!" /Quiet
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /Set-SetupUILang:%DEFAULTLANGUAGE% /Distribution:"!DVDDIR!" /Quiet
)
if %foundupdates%==1 call Updates\W10UI.cmd 1 "%INSTALLMOUNTDIR%" "!TMPUPDT!" "!DVDDIR!\sources"
if %_Debug% neq 0 @echo on
cd /d "!WORKDIR!"
if not defined isomaj for /f "tokens=6,7 delims=_." %%i in ('dir /b /a:-d /od "%INSTALLMOUNTDIR%\Windows\WinSxS\Manifests\*_microsoft-windows-coreos-revision*.manifest"') do (set isover=%%i.%%j&set isomaj=%%i&set isomin=%%j)
if not defined isolab (if %_build% geq 15063 (call :detectLab isolab) else (call :legacyLab isolab))
if not defined isodate if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Package_for_RollupFix*.mum" (
copy /y "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Package_for_RollupFix*.mum" %SystemRoot%\temp\ %_Nul1%
for /f %%# in ('dir /b /a:-d /od %SystemRoot%\temp\Package_for_RollupFix*.mum') do set "mumfile=%SystemRoot%\temp\%%#"
for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!mumfile:\=\\!'" get LastModified /value') do set "mumdate=%%#"
del /f /q %SystemRoot%\temp\*.mum
set "isodate=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
)
if %_actEP% equ 0 if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\microsoft-windows-*enablement-package~*.mum" call :detectEP
if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" set _SrvEdt=1
if exist "%INSTALLMOUNTDIR%\Windows\system32\UpdateAgent.dll" if not exist "%SystemRoot%\temp\UpdateAgent.dll" copy /y "%INSTALLMOUNTDIR%\Windows\system32\UpdateAgent.dll" %SystemRoot%\temp\ %_Nul3%
if exist "%INSTALLMOUNTDIR%\Windows\system32\Facilitator.dll" if not exist "%SystemRoot%\temp\Facilitator.dll" copy /y "%INSTALLMOUNTDIR%\Windows\system32\Facilitator.dll" %SystemRoot%\temp\ %_Nul3%
if %foundupdates%==1 if not defined efifile (
if /i %BOOTARCH%==x86 (set efifile=bootia32.efi) else (set efifile=bootx64.efi)
for %%i in (efisys.bin,efisys_noprompt.bin) do if exist "%INSTALLMOUNTDIR%\Windows\Boot\DVD\EFI\en-US\%%i" (copy /y "%INSTALLMOUNTDIR%\Windows\Boot\DVD\EFI\en-US\%%i" "!DVDDIR!\efi\microsoft\boot\" %_Nul3%)
copy /y "%INSTALLMOUNTDIR%\Windows\Boot\PCAT\bootmgr" "!DVDDIR!\" %_Nul1%
copy /y "%INSTALLMOUNTDIR%\Windows\Boot\PCAT\memtest.exe" "!DVDDIR!\boot\" %_Nul1%
copy /y "%INSTALLMOUNTDIR%\Windows\Boot\EFI\memtest.efi" "!DVDDIR!\efi\microsoft\boot\" %_Nul1%
copy /y "%INSTALLMOUNTDIR%\Windows\Boot\EFI\bootmgfw.efi" "!DVDDIR!\efi\boot\!efifile!" %_Nul1%
copy /y "%INSTALLMOUNTDIR%\Windows\Boot\EFI\bootmgr.efi" "!DVDDIR!\" %_Nul1%
if exist "%INSTALLMOUNTDIR%\Windows\Boot\EFI\winsipolicy.p7b" if exist "!DVDDIR!\efi\microsoft\boot\winsipolicy.p7b" copy /y "%INSTALLMOUNTDIR%\Windows\Boot\EFI\winsipolicy.p7b" "!DVDDIR!\efi\microsoft\boot\winsipolicy.p7b" %_Nul3%
if exist "%INSTALLMOUNTDIR%\Windows\Boot\EFI\CIPolicies\" if exist "!DVDDIR!\efi\microsoft\boot\cipolicies\" xcopy /CEDRY "%INSTALLMOUNTDIR%\Windows\Boot\EFI\CIPolicies\*" "!DVDDIR!\efi\microsoft\boot\cipolicies\" %_Nul3%
)
if %NET35%==1 if not exist "%INSTALLMOUNTDIR%\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" (
echo.
echo ============================================================
echo Enable .NET Framework 3.5 - index %%i/%imgcount%
echo ============================================================
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUINetFx3.log" /Enable-Feature /Featurename:NetFx3 /All /LimitAccess /Source:"!DVDDIR!\sources\sxs"
)
if %%i==%imgcount% for /L %%j in (1,1,%LANGUAGES%) do (
if /i !LANGUAGE%%j!==ja-jp xcopy "%INSTALLMOUNTDIR%\Windows\Boot\Fonts\*" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\" /chryi %_Nul1%&if exist "%INSTALLMOUNTDIR%\Windows\Fonts\meiryo.ttc" (copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\meiryo.ttc" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" %_Nul1%)&if exist "%INSTALLMOUNTDIR%\Windows\Fonts\msgothic.ttc" (copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\msgothic.ttc" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" %_Nul1%)
if /i !LANGUAGE%%j!==ko-kr xcopy "%INSTALLMOUNTDIR%\Windows\Boot\Fonts\*" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\" /chryi %_Nul1%&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\malgun.ttf" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" %_Nul1%&if exist "%INSTALLMOUNTDIR%\Windows\Fonts\gulim.ttc" (copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\gulim.ttc" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" %_Nul1%)
if /i !LANGUAGE%%j!==zh-cn xcopy "%INSTALLMOUNTDIR%\Windows\Boot\Fonts\*" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\" /chryi %_Nul1%&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\msyh.ttc" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" %_Nul1%&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\mingliub.ttc" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" %_Nul1%&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\simsun.ttc" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" %_Nul1%&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\msyhl.ttc" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" %_Nul1%
if /i !LANGUAGE%%j!==zh-hk xcopy "%INSTALLMOUNTDIR%\Windows\Boot\Fonts\*" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\" /chryi %_Nul1%&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\msjh.ttc" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" %_Nul1%&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\mingliub.ttc" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" %_Nul1%&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\simsun.ttc" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" %_Nul1%
if /i !LANGUAGE%%j!==zh-tw xcopy "%INSTALLMOUNTDIR%\Windows\Boot\Fonts\*" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\" /chryi %_Nul1%&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\msjh.ttc" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" %_Nul1%&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\mingliub.ttc" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" %_Nul1%&copy /y "%INSTALLMOUNTDIR%\Windows\Fonts\simsun.ttc" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!" %_Nul1%
)
attrib -S -H -I "%INSTALLMOUNTDIR%\Windows\System32\Recovery\winre.wim" %_Nul3%
if %WINPE%==1 if exist "%INSTALLMOUNTDIR%\Windows\System32\Recovery\winre.wim" if not exist "!TEMPDIR!\WR\!WIMARCH%%i!\winre.wim" (
  echo.
  echo ============================================================
  echo Update winre.wim / !WIMARCH%%i!
  echo ============================================================
  echo.
  mkdir "!TEMPDIR!\WR\!WIMARCH%%i!"
  copy "%INSTALLMOUNTDIR%\Windows\System32\Recovery\winre.wim" "!TEMPDIR!\WR\!WIMARCH%%i!"
  echo.
  echo ============================================================
  echo Mount winre.wim
  echo ============================================================
  !_dism2!:"!TMPDISM!" /Mount-Wim /Wimfile:"!TEMPDIR!\WR\!WIMARCH%%i!\winre.wim" /Index:1 /MountDir:"%WINREMOUNTDIR%"
  if !errorlevel! neq 0 goto :E_MOUNT
  echo.
  echo ============================================================
  echo Add LPs to winre.wim
  echo ============================================================
  call :SbS "%WINREMOUNTDIR%"
  pushd "!WinPERoot!\!WIMARCH%%i!\WinPE_OCs"
  if defined _PEM64 if /i !WIMARCH%%i!==amd64 (
    !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP64.log" /Add-Package !_PEM64! !_PEF64!
    !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP64.log" /Add-Package !_PER64!
    if !SLIM! NEQ 1 !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP64.log" /Add-Package !_PEX64!
  )
  if defined _PEM86 if /i !WIMARCH%%i!==x86 (
    !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP86.log" /Add-Package !_PEM86! !_PEF86!
    !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP86.log" /Add-Package !_PER86!
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
  if %foundupdates%==0 (
  !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinpeClean.log" /Cleanup-Image /StartComponentCleanup
  !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinpeClean.log" /Cleanup-Image /StartComponentCleanup /ResetBase
  )
  if %foundupdates%==1 call Updates\W10UI.cmd 1 "%WINREMOUNTDIR%" "!TMPUPDT!"
  if %_Debug% neq 0 @echo on
  cd /d "!WORKDIR!"
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
  !_dism2!:"!TMPDISM!" /Export-Image /SourceImageFile:"!TEMPDIR!\WR\!WIMARCH%%i!\winre.wim" /All /DestinationImageFile:"!EXTRACTDIR!\winre.wim"
  if exist "!EXTRACTDIR!\winre.wim" move /y "!EXTRACTDIR!\winre.wim" "!TEMPDIR!\WR\!WIMARCH%%i!" %_Nul1%
)
if %WINPE%==1 if exist "!TEMPDIR!\WR\!WIMARCH%%i!\winre.wim" (
  echo.
  echo ============================================================
  echo Add updated winre.wim to install.wim - index %%i/%imgcount%
  echo ============================================================
  echo.
  copy /y "!TEMPDIR!\WR\!WIMARCH%%i!\winre.wim" "%INSTALLMOUNTDIR%\Windows\System32\Recovery"
)
call :cleanmanual "%INSTALLMOUNTDIR%"
echo.
echo ============================================================
echo Unmount install.wim - index %%i/%imgcount%
echo ============================================================
!_dism2!:"!TMPDISM!" /Unmount-Wim /MountDir:"%INSTALLMOUNTDIR%" /Commit
if !errorlevel! neq 0 goto :E_UNMOUNT
)

echo.
echo ============================================================
echo Mount boot.wim - index 1/%BOOTCOUNT%
echo ============================================================
!_dism2!:"!TMPDISM!" /Mount-Wim /WimFile:"!DVDDIR!\sources\boot.wim" /Index:1 /MountDir:"%BOOTMOUNTDIR%"
if !errorlevel! neq 0 goto :E_MOUNT

if %BOOTCOUNT%==1 if not exist "%BOOTMOUNTDIR%\sources\setup.exe" set SLIM=0
if %WINPE%==1 (
  echo.
  echo ============================================================
  echo Add LPs to boot.wim - index 1/%BOOTCOUNT%
  echo ============================================================
  call :SbS "%BOOTMOUNTDIR%"
  pushd "!WinPERoot!\!BOOTARCH!\WinPE_OCs"
  if defined _PEM64 if /i !BOOTARCH!==amd64 (
    !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP64.log" /Add-Package !_PEM64! !_PEF64!
    if exist "%BOOTMOUNTDIR%\Windows\servicing\Packages\WinPE-Rejuv-Package~31bf3856ad364e35~*.mum" !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP64.log" /Add-Package !_PER64!
    if !SLIM! NEQ 1 !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP64.log" /Add-Package !_PEX64!
  )
  if defined _PEM86 if /i !BOOTARCH!==x86 (
    !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP86.log" /Add-Package !_PEM86! !_PEF86!
    if exist "%BOOTMOUNTDIR%\Windows\servicing\Packages\WinPE-Rejuv-Package~31bf3856ad364e35~*.mum" !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP86.log" /Add-Package !_PER86!
    if !SLIM! NEQ 1 !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP86.log" /Add-Package !_PEX86!
  )
  popd
  echo.
  echo ============================================================
  echo Update language settings
  echo ============================================================
  echo.
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE% /Quiet
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE% /Quiet
  if %foundupdates%==0 (
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIwinpeClean.log" /Cleanup-Image /StartComponentCleanup
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIwinpeClean.log" /Cleanup-Image /StartComponentCleanup /ResetBase
  )
) else (
  for /L %%j in (1,1,%LANGUAGES%) do (
   if /i !LPARCH%%j!==!BOOTARCH! (
    if not exist "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!\" mkdir "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!"
    call :EAfonts %%j
   )
  )
)
if %foundupdates%==1 call Updates\W10UI.cmd 1 "%BOOTMOUNTDIR%" "!TMPUPDT!"
if %_Debug% neq 0 @echo on
cd /d "!WORKDIR!"
if exist "%BOOTMOUNTDIR%\sources\setup.exe" copy /y "%BOOTMOUNTDIR%\sources\setup.exe" "!DVDDIR!\sources" %_Nul3%
call :cleanmanual "%BOOTMOUNTDIR%"
echo.
echo ============================================================
echo Unmount boot.wim - index 1/%BOOTCOUNT%
echo ============================================================
!_dism2!:"!TMPDISM!" /Unmount-Wim /MountDir:"%BOOTMOUNTDIR%" /Commit
if !errorlevel! neq 0 goto :E_UNMOUNT

if %BOOTCOUNT%==1 goto :rebuild
echo.
echo ============================================================
echo Mount boot.wim - index 2/%BOOTCOUNT%
echo ============================================================
!_dism2!:"!TMPDISM!" /Mount-Wim /WimFile:"!DVDDIR!\sources\boot.wim" /Index:2 /MountDir:"%BOOTMOUNTDIR%"
if !errorlevel! neq 0 goto :E_MOUNT

if %WINPE%==1 (
  echo.
  echo ============================================================
  echo Add LPs to boot.wim - index 2/%BOOTCOUNT%
  echo ============================================================
  call :SbS "%BOOTMOUNTDIR%"
  pushd "!WinPERoot!\!BOOTARCH!\WinPE_OCs"
  if defined _PEM64 if /i !BOOTARCH!==amd64 (
    !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP64.log" /Add-Package !_PEM64! !_PEF64!
    if exist "%BOOTMOUNTDIR%\Windows\servicing\Packages\WinPE-Setup-Package~31bf3856ad364e35~*.mum" (
      !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP64.log" /Add-Package !_PES64!
      ) else (
      call :WIMman 2
    )
    if !SLIM! NEQ 1 !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP64.log" /Add-Package !_PEX64!
  )
  if defined _PEM86 if /i !BOOTARCH!==x86 (
    !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP86.log" /Add-Package !_PEM86! !_PEF86!
    if exist "%BOOTMOUNTDIR%\Windows\servicing\Packages\WinPE-Setup-Package~31bf3856ad364e35~*.mum" (
      !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP86.log" /Add-Package !_PES86!
      ) else (
      call :WIMman 2
    )
    if !SLIM! NEQ 1 !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP86.log" /Add-Package !_PEX86!
  )
  popd
  if not !wimbit!==dual for /L %%j in (1,1,%LANGUAGES%) do (
    xcopy "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!\*.rtf" "!DVDDIR!\sources\!LANGUAGE%%j!\" /chryi %_Nul3%
    xcopy "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!\*.rtf" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\" /chryi %_Nul3%
  )
  echo.
  echo ============================================================
  echo Update language settings
  echo ============================================================
  echo.
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE% /Quiet
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE% /Quiet
  if exist "%BOOTMOUNTDIR%\Windows\servicing\Packages\WinPE-Setup-Package~31bf3856ad364e35~*.mum" (
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /Gen-LangINI /Distribution:"%BOOTMOUNTDIR%" /Quiet
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /Set-SetupUILang:%DEFAULTLANGUAGE% /Distribution:"%BOOTMOUNTDIR%" /Quiet
  )
  if %foundupdates%==0 (
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIwinpeClean.log" /Cleanup-Image /StartComponentCleanup
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIwinpeClean.log" /Cleanup-Image /StartComponentCleanup /ResetBase
  )
) else (
  call :WIMman 1
)
if %foundupdates%==1 call Updates\W10UI.cmd 1 "%BOOTMOUNTDIR%" "!TMPUPDT!"
if %_Debug% neq 0 @echo on
cd /d "!WORKDIR!"
if exist "%BOOTMOUNTDIR%\sources\setup.exe" call :boots
call :cleanmanual "%BOOTMOUNTDIR%"
echo.
echo ============================================================
echo Unmount boot.wim - index 2/%BOOTCOUNT%
echo ============================================================
!_dism2!:"!TMPDISM!" /Unmount-Wim /MountDir:"%BOOTMOUNTDIR%" /Commit
if !errorlevel! neq 0 goto :E_UNMOUNT

:rebuild
echo.
echo ============================================================
echo Rebuild boot.wim
echo ============================================================
!_dism2!:"!TMPDISM!" /Export-Image /SourceImageFile:"!DVDDIR!\sources\boot.wim" /All /DestinationImageFile:"!DVDDIR!\boot.wim"
if exist "!DVDDIR!\boot.wim" move /y "!DVDDIR!\boot.wim" "!DVDDIR!\sources" %_Nul1%
echo.
echo ============================================================
echo Rebuild install.wim
echo ============================================================
!_dism2!:"!TMPDISM!" /Export-Image /SourceImageFile:"!DVDDIR!\sources\install.wim" /All /DestinationImageFile:"!DVDDIR!\install.wim"
if exist "!DVDDIR!\install.wim" move /y "!DVDDIR!\install.wim" "!DVDDIR!\sources" %_Nul1%
if %NET35%==1 if exist "!DVDDIR!\sources\sxs\*netfx3*.cab" del /f /q "!DVDDIR!\sources\sxs\*netfx3*.cab" %_Nul3%
xcopy "!DVDDIR!\efi\microsoft\boot\fonts\*" "!DVDDIR!\boot\fonts\" /chryi %_Nul3%

if %SLIM% NEQ 1 goto :dvd
echo.
echo ============================================================
echo Cleanup ISO payload
echo ============================================================
echo.
del /f /q /s "!DVDDIR!\ch*_boot.ttf" %_Nul3%
del /f /q /s "!DVDDIR!\jpn_boot.ttf" %_Nul3%
del /f /q /s "!DVDDIR!\kor_boot.ttf" %_Nul3%
del /f /q /s "!DVDDIR!\m*_boot.ttf" %_Nul3%
del /f /q /s "!DVDDIR!\m*_console.ttf" %_Nul3%
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
mkdir "!DVDDIR!\sources" %_Nul3%
if exist "!DVDDIR!\ei.cfg" move /y "!DVDDIR!\ei.cfg" "!DVDDIR!\sources" %_Nul3%
if exist "!DVDDIR!\pid.txt" move /y "!DVDDIR!\pid.txt" "!DVDDIR!\sources" %_Nul3%
move /y "!DVDDIR!\boot.wim" "!DVDDIR!\sources" %_Nul3%
move /y "!DVDDIR!\install.wim" "!DVDDIR!\sources" %_Nul3%
move /y "!DVDDIR!\lang.ini" "!DVDDIR!\sources" %_Nul3%
move /y "!DVDDIR!\setup.exe" "!DVDDIR!\sources" %_Nul3%

:dvd
:: if exist "!DVDDIR!\sources\uup" rmdir /s /q "!DVDDIR!\sources\uup" %_Nul3%
call :DATEISO
for /f "tokens=2 delims==." %%# in ('wmic os get localdatetime /value') do set "_date=%%#"
if not defined isodate set "isodate=%_date:~2,6%-%_date:~8,4%"
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set isolab=!isolab:%%#=%%#!
)
set _label=%isover%.%isodate%.%isolab%
if %_SrvEdt% equ 1 (set _label=%_label%_SERVER) else (set _label=%_label%_CLIENT)
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
if exist ".\efi\microsoft\boot\efisys.bin" (
"!WORKDIR!\dism\cdimage.exe" -bootdata:2#p0,e,b".\boot\etfsboot.com"#pEF,e,b".\efi\microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -l"%DVDLABEL%" . "%DVDISO%"
call set errcode=!errorlevel!
) else (
"!WORKDIR!\dism\cdimage.exe" -b".\boot\etfsboot.com" -o -m -u2 -udfver102 -l"%DVDLABEL%" . "%DVDISO%"
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
if /i !langid!==en-gb set lang=en-gb
if /i !langid!==es-mx set lang=es-mx
if /i !langid!==fr-ca set lang=fr-ca
if /i !langid!==pt-pt set lang=pp
if /i !langid!==sr-latn-rs set lang=sr-latn
if /i !langid!==zh-cn set lang=cn
if /i !langid!==zh-hk set lang=hk
if /i !langid!==zh-tw set lang=tw
if /i !langid!==zh-tw if %_build% geq 14393 set lang=ct
if defined _mui (set "_mui=!_mui!_!lang!") else (set "_mui=!lang!")
)
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _mui=!_mui:%%#=%%#!
)
del /f /q "isolang.txt" %_Nul3%
goto :eof

:DATEISO
if not exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" goto :eof
copy /y "!DVDDIR!\sources\setuphost.exe" %SystemRoot%\temp\ %_Nul3%
copy /y "!DVDDIR!\sources\setupprep.exe" %SystemRoot%\temp\ %_Nul3%
set _svr1=0&set _svr2=0&set _svr3=0&set _svr4=0
set "_fvr1=%SystemRoot%\temp\setuphost.exe"
set "_fvr2=%SystemRoot%\temp\setupprep.exe"
set "_fvr3=%SystemRoot%\temp\UpdateAgent.dll"
set "_fvr4=%SystemRoot%\temp\Facilitator.dll"
if exist "!_fvr1!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!_fvr1:\=\\!'" get Version /value ^| find "="') do set /a "_svr1=%%a"
if exist "!_fvr2!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!_fvr2:\=\\!'" get Version /value ^| find "="') do set /a "_svr2=%%a"
if exist "!_fvr3!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!_fvr3:\=\\!'" get Version /value ^| find "="') do set /a "_svr3=%%a"
if exist "!_fvr4!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!_fvr4:\=\\!'" get Version /value ^| find "="') do set /a "_svr4=%%a"
if %isomin% neq %_svr1% if %isomin% neq %_svr2% if %isomin% neq %_svr3% if %isomin% neq %_svr4% goto :eof
if %isomin% equ %_svr1% set "_chk=!_fvr1!"
if %isomin% equ %_svr2% set "_chk=!_fvr2!"
if %isomin% equ %_svr3% set "_chk=!_fvr3!"
if %isomin% equ %_svr4% set "_chk=!_fvr4!"
for /f "tokens=6 delims=.) " %%# in ('powershell -nop -c "(gi '!_chk!').VersionInfo.FileVersion" %_Nul6%') do set "_ddd=%%#"
if defined _ddd set "isodate=%_ddd%"
del /f /q "!_fvr1!" "!_fvr2!" "!_fvr3!" "!_fvr4!" %_Nul3%
goto :eof

:detectEP
set uupmaj=
set _fixEP=0
set _actEP=1
if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-1909Enablement-Package~*.mum" set "_fixEP=18363"
if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-20H2Enablement-Package~*.mum" set "_fixEP=19042"
if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-21H1Enablement-Package~*.mum" set "_fixEP=19043"
if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-21H2Enablement-Package~*.mum" set "_fixEP=19044"
if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-22H1Enablement-Package~*.mum" if %_build% lss 22000 set "_fixEP=19045"
if exist "%INSTALLMOUNTDIR%\Windows\WinSxS\Manifests\*_microsoft-updatetargeting-*os_*10.%_fixEP%*.manifest" (
for /f "tokens=5-7 delims=_." %%I in ('dir /b /a:-d /od "%INSTALLMOUNTDIR%\Windows\WinSxS\Manifests\*_microsoft-updatetargeting-*os_*10.%_fixEP%*.manifest"') do (set uupver=%%I.%%K&set uupmaj=%%I&set uupmin=%%K)
if %_fixEP% equ 0 for /f "tokens=5-7 delims=_." %%I in ('dir /b /a:-d /od "%INSTALLMOUNTDIR%\Windows\WinSxS\Manifests\*_microsoft-updatetargeting-*os_*10.%_fixEP%*.manifest"') do (set uupver=%%J.%%K&set uupmaj=%%J&set uupmin=%%K)
)
if not defined uupmaj goto :eof
if not defined uuplab (if defined isolab (set "uuplab=%isolab%") else (call :detectLab uuplab))
if %uupmaj%==18363 if /i "%uuplab:~0,4%"=="19h1" set uuplab=19h2%uuplab:~4%
if %uupmaj%==19041 if /i "%uuplab:~0,2%"=="vb" set uuplab=20h1%uuplab:~2%
if %uupmaj%==19042 if /i "%uuplab:~0,2%"=="vb" set uuplab=20h2%uuplab:~2%
if %uupmaj%==19043 if /i "%uuplab:~0,2%"=="vb" set uuplab=21h1%uuplab:~2%
if %uupmaj%==19044 if /i "%uuplab:~0,2%"=="vb" set uuplab=21h2%uuplab:~2%
if %uupmaj%==19045 if /i "%uuplab:~0,2%"=="vb" set uuplab=22h1%uuplab:~2%
goto :eof

:detectLab
set "_tikey=HKLM\uiSOFTWARE\Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
reg.exe load HKLM\uiSOFTWARE "%INSTALLMOUNTDIR%\Windows\system32\config\SOFTWARE" %_Nul1%
for /f "tokens=* delims=" %%# in ('reg.exe query "%_tikey%" ^| findstr /i /r ".*\.OS"') do set "_oskey=%%#"
for /f "skip=2 tokens=2*" %%A in ('reg.exe query "%_oskey%" /v Branch') do set "%1=%%B"
reg.exe save HKLM\uiSOFTWARE "%INSTALLMOUNTDIR%\Windows\System32\Config\SOFTWARE2" %_Nul1%
reg.exe unload HKLM\uiSOFTWARE %_Nul1%
move /y "%INSTALLMOUNTDIR%\Windows\System32\Config\SOFTWARE2" "%INSTALLMOUNTDIR%\Windows\System32\Config\SOFTWARE" %_Nul1%
goto :eof

:legacyLab
reg.exe load HKLM\uiSOFTWARE "%INSTALLMOUNTDIR%\Windows\system32\config\SOFTWARE" %_Nul1%
for /f "skip=2 tokens=6 delims=. " %%# in ('"reg.exe query "HKLM\uiSOFTWARE\Microsoft\Windows NT\CurrentVersion" /v BuildLabEx" %_Nul6%') do set "%1=%%#"
reg.exe save HKLM\uiSOFTWARE "%INSTALLMOUNTDIR%\Windows\System32\Config\SOFTWARE2" %_Nul1%
reg.exe unload HKLM\uiSOFTWARE %_Nul1%
move /y "%INSTALLMOUNTDIR%\Windows\System32\Config\SOFTWARE2" "%INSTALLMOUNTDIR%\Windows\System32\Config\SOFTWARE" %_Nul1%
goto :eof

:boots
if exist "%BOOTMOUNTDIR%\Windows\Servicing\Packages\WinPE-Setup-Package~*.mum" xcopy /CRUY "%BOOTMOUNTDIR%\sources" "!DVDDIR!\sources\" %_Nul3%
del /f /q "!DVDDIR!\sources\background.bmp" %_Nul3%
del /f /q "!DVDDIR!\sources\xmllite.dll" %_Nul3%
if exist "!DVDDIR!\setup.exe" copy /y "%BOOTMOUNTDIR%\setup.exe" "!DVDDIR!\" %_Nul3%
if not defined uupmaj goto :eof
if %_actEP% equ 0 goto :eof
if %isomaj% gtr %uupmaj% goto :eof
set isover=%uupver%
set isolab=%uuplab%
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

:E_ESD
call :remove
set MESSAGE=ERROR: Detected install.wim file is actually .esd file
goto :END

:E_FILES
call :remove
set MESSAGE=ERROR: Could not detect any cab/esd files in "Langs" folder
goto :END

:E_ARCH
call :remove
set MESSAGE=ERROR: None of detected LangPacks match any of WIM images architecture
goto :END

:E_LP
call :remove
set MESSAGE=ERROR: %ERRFILE% is not a valid Windows NT 10.0 LangPack
goto :END

:E_VER
call :remove
set MESSAGE=ERROR: %ERRFILE% version does not match WIM version %_build%
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
if exist "Updates\msucab.txt" (
  for /f %%# in (Updates\msucab.txt) do (
  if exist "Updates\*%%~#*x86*.msu" if exist "Updates\*%%~#*x86*.cab" del /f /q "Updates\*%%~#*x86*.cab" %_Nul3%
  if exist "Updates\*%%~#*x64*.msu" if exist "Updates\*%%~#*x64*.cab" del /f /q "Updates\*%%~#*x64*.cab" %_Nul3%
  )
  del /f /q Updates\msucab.txt
)
goto :END

:remove
if exist "!DVDDIR!\" rmdir /s /q "!DVDDIR!" %_Nul3%
if exist "!TEMPDIR!\" rmdir /s /q "!TEMPDIR!\" %_Nul3%
if exist "!MOUNTDIR!\" rmdir /s /q "!MOUNTDIR!\" %_Nul3%
if exist "Updates\msucab.txt" (
  for /f %%# in (Updates\msucab.txt) do (
  if exist "Updates\*%%~#*x86*.msu" if exist "Updates\*%%~#*x86*.cab" del /f /q "Updates\*%%~#*x86*.cab" %_Nul3%
  if exist "Updates\*%%~#*x64*.msu" if exist "Updates\*%%~#*x64*.cab" del /f /q "Updates\*%%~#*x64*.cab" %_Nul3%
  )
  del /f /q Updates\msucab.txt
)
goto :eof

:cleanmanual
if exist "%~1\Windows\WinSxS\ManifestCache\*.bin" (
takeown /f "%~1\Windows\WinSxS\ManifestCache\*.bin" /A %_Nul3%
icacls "%~1\Windows\WinSxS\ManifestCache\*.bin" /grant *S-1-5-32-544:F %_Nul3%
del /f /q "%~1\Windows\WinSxS\ManifestCache\*.bin" %_Nul3%
)
if exist "%~1\Windows\WinSxS\Temp\PendingDeletes\*" (
takeown /f "%~1\Windows\WinSxS\Temp\PendingDeletes\*" /A %_Nul3%
icacls "%~1\Windows\WinSxS\Temp\PendingDeletes\*" /grant *S-1-5-32-544:F %_Nul3%
del /f /q "%~1\Windows\WinSxS\Temp\PendingDeletes\*" %_Nul3%
)
if exist "%~1\Windows\WinSxS\Temp\TransformerRollbackData\*" (
takeown /f "%~1\Windows\WinSxS\Temp\TransformerRollbackData\*" /R /A %_Nul3%
icacls "%~1\Windows\WinSxS\Temp\TransformerRollbackData\*" /grant *S-1-5-32-544:F /T %_Nul3%
del /s /f /q "%~1\Windows\WinSxS\Temp\TransformerRollbackData\*" %_Nul3%
)
if exist "%~1\Windows\inf\*.log" (
del /f /q "%~1\Windows\inf\*.log" %_Nul3%
)
for /f "tokens=* delims=" %%# in ('dir /b /ad "%~1\Windows\CbsTemp\" %_Nul6%') do rmdir /s /q "%~1\Windows\CbsTemp\%%#\" %_Nul3%
del /s /f /q "%~1\Windows\CbsTemp\*" %_Nul3%
goto :eof

:ISOmui
"!_7z!" e ".\langs\!LPFILE%1!" -o"!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!" bootsect.exe.mui -r -aos %_Null%
"!_7z!" e ".\langs\!LPFILE%1!" -o"!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!" credits.rtf -r -aos %_Null%
"!_7z!" e ".\langs\!LPFILE%1!" -o"!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!" oobe_help_opt_in_details.rtf -r -aos %_Null%
if exist "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\bootsect.exe.mui" (xcopy "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\bootsect.exe.mui" "!DVDDIR!\boot\!LANGUAGE%1!\" /chryi %_Nul3%)
xcopy "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\*" "!DVDDIR!\sources\!LANGUAGE%1!\" /cheryi %_Nul3%
if exist "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\cli" xcopy "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\cli\*" "!DVDDIR!\sources\!LANGUAGE%1!\" /chryi %_Nul3%
if exist "!DVDDIR!\sources\!LANGUAGE%1!\cli" rmdir /s /q "!DVDDIR!\sources\!LANGUAGE%1!\cli" %_Nul3%
rmdir /s /q "!DVDDIR!\sources\!LANGUAGE%1!\dlmanifests" %_Nul3%
rmdir /s /q "!DVDDIR!\sources\!LANGUAGE%1!\etwproviders" %_Nul3%
rmdir /s /q "!DVDDIR!\sources\!LANGUAGE%1!\replacementmanifests" %_Nul3%
mkdir "!DVDDIR!\sources\dlmanifests\!LANGUAGE%1!"
mkdir "!DVDDIR!\sources\replacementmanifests\!LANGUAGE%1!"
xcopy "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\dlmanifests\microsoft-windows-iasserver-migplugin\*" "!DVDDIR!\sources\dlmanifests\microsoft-windows-iasserver-migplugin\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\dlmanifests\microsoft-windows-shmig-dl\*" "!DVDDIR!\sources\dlmanifests\microsoft-windows-shmig-dl\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\dlmanifests\microsoft-windows-storagemigration\*" "!DVDDIR!\sources\dlmanifests\microsoft-windows-storagemigration\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\dlmanifests\microsoft-windows-sxs\*" "!DVDDIR!\sources\dlmanifests\microsoft-windows-sxs\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\replacementmanifests\microsoft-windows-offlinefiles-core\*" "!DVDDIR!\sources\replacementmanifests\microsoft-windows-offlinefiles-core\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\replacementmanifests\microsoft-windows-shmig\*" "!DVDDIR!\sources\replacementmanifests\microsoft-windows-shmig\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\replacementmanifests\microsoft-windows-storagemigration\*" "!DVDDIR!\sources\replacementmanifests\microsoft-windows-storagemigration\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\replacementmanifests\microsoft-windows-sxs\*" "!DVDDIR!\sources\replacementmanifests\microsoft-windows-sxs\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\etwproviders\*" "!DVDDIR!\sources\etwproviders\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\setup\sources\!LANGUAGE%1!\etwproviders\*" "!DVDDIR!\support\logging\!LANGUAGE%1!\" /chryi %_Nul3%
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\credits.rtf" "!DVDDIR!\sources\!LANGUAGE%1!" %_Nul3%
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\oobe_help_opt_in_details.rtf" "!DVDDIR!\sources\!LANGUAGE%1!" %_Nul3%
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\vofflps.rtf" "!DVDDIR!\sources\!LANGUAGE%1!" %_Nul3%
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\vofflps.rtf" "!DVDDIR!\sources\!LANGUAGE%1!\privacy.rtf" %_Nul3%
attrib -A -S -H -I "!DVDDIR!\sources\!LANGUAGE%1!" /S /D %_Nul3%
goto :eof

:WIMman
if "%1"=="1" (
  echo.
  echo ============================================================
  echo Add language files to boot.wim - index 2
  echo ============================================================
  echo.
)
copy /y "!DVDDIR!\sources\lang.ini" "%BOOTMOUNTDIR%\sources" %_Nul1%
for /L %%j in (1,1,%LANGUAGES%) do (
  if /i !LPARCH%%j!==!BOOTARCH! (
    if "%1"=="1" echo !LANGUAGE%%j!
    if not exist "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!\" mkdir "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!"
    copy /y "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\vofflps.rtf" "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!" %_Nul3%
    copy /y "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\reagent.adml" "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!" %_Nul3%
    for %%G in %bootmui% do (
    copy /y "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\%%G.mui" "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!" %_Nul3%
    )
    attrib -A -S -H -I "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!" /S /D %_Nul1%
  )
)
if "%1"=="1" for /L %%j in (1,1,%LANGUAGES%) do (
  if /i !LPARCH%%j!==!BOOTARCH! (
    call :EAfonts %%j
  )
)
goto :eof

:EAfonts
if /i !LANGUAGE%1!==ja-jp (
echo.
echo ============================================================
echo Add Font Support: !LANGUAGE%1!
echo ============================================================
echo.
if not exist "%BOOTMOUNTDIR%\Windows\Boot\Fonts\jpn_boot.ttf" (
icacls "%BOOTMOUNTDIR%\Windows\Boot\Fonts" /save "!TEMPDIR!\AclFile" %_Nul3%&takeown /f "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%&icacls "%BOOTMOUNTDIR%\Windows\Boot\Fonts" /grant *S-1-5-32-544:F %_Nul3%
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\jpn_boot.ttf" "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\meiryo_boot.ttf" "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\meiryon_boot.ttf" "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%
icacls "%BOOTMOUNTDIR%\Windows\Boot\Fonts" /setowner "NT Service\TrustedInstaller" %_Nul3%&icacls "%BOOTMOUNTDIR%\Windows\Boot" /restore "!TEMPDIR!\AclFile" %_Nul3%
)
reg.exe load HKLM\OFFLINE "%BOOTMOUNTDIR%\Windows\System32\config\SOFTWARE" %_Nul1%&reg.exe import "!WORKDIR!\dism\EA\ja-jp.reg" %_Nul1%&reg.exe unload HKLM\OFFLINE %_Nul1%
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\meiryo.ttc" "%BOOTMOUNTDIR%\Windows\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msgothic.ttc" "%BOOTMOUNTDIR%\Windows\Fonts" %_Nul3%
)
if /i !LANGUAGE%1!==ko-kr (
echo.
echo ============================================================
echo Add Font Support: !LANGUAGE%1!
echo ============================================================
echo.
if not exist "%BOOTMOUNTDIR%\Windows\Boot\Fonts\kor_boot.ttf" (
icacls "%BOOTMOUNTDIR%\Windows\Boot\Fonts" /save "!TEMPDIR!\AclFile" %_Nul3%&takeown /f "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%&icacls "%BOOTMOUNTDIR%\Windows\Boot\Fonts" /grant *S-1-5-32-544:F %_Nul3%
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\kor_boot.ttf" "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\malgunn_boot.ttf" "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\malgun_boot.ttf" "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%
icacls "%BOOTMOUNTDIR%\Windows\Boot\Fonts" /setowner "NT Service\TrustedInstaller" %_Nul3%&icacls "%BOOTMOUNTDIR%\Windows\Boot" /restore "!TEMPDIR!\AclFile" %_Nul3%
)
reg.exe load HKLM\OFFLINE "%BOOTMOUNTDIR%\Windows\System32\config\SOFTWARE" %_Nul1%&reg.exe import "!WORKDIR!\dism\EA\ko-kr.reg" %_Nul1%&reg.exe unload HKLM\OFFLINE %_Nul1%
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\malgun.ttf" "%BOOTMOUNTDIR%\Windows\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\gulim.ttc" "%BOOTMOUNTDIR%\Windows\Fonts" %_Nul3%
)
if /i !LANGUAGE%1!==zh-cn (
echo.
echo ============================================================
echo Add Font Support: !LANGUAGE%1!
echo ============================================================
echo.
if not exist "%BOOTMOUNTDIR%\Windows\Boot\Fonts\chs_boot.ttf" (
icacls "%BOOTMOUNTDIR%\Windows\Boot\Fonts" /save "!TEMPDIR!\AclFile" %_Nul3%&takeown /f "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%&icacls "%BOOTMOUNTDIR%\Windows\Boot\Fonts" /grant *S-1-5-32-544:F %_Nul3%
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\chs_boot.ttf" "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msyhn_boot.ttf" "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msyh_boot.ttf" "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%
icacls "%BOOTMOUNTDIR%\Windows\Boot\Fonts" /setowner "NT Service\TrustedInstaller" %_Nul3%&icacls "%BOOTMOUNTDIR%\Windows\Boot" /restore "!TEMPDIR!\AclFile" %_Nul3%
)
reg.exe load HKLM\OFFLINE "%BOOTMOUNTDIR%\Windows\System32\config\SOFTWARE" %_Nul1%&reg.exe import "!WORKDIR!\dism\EA\zh-cn.reg" %_Nul1%&reg.exe unload HKLM\OFFLINE %_Nul1%
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msyh.ttc" "%BOOTMOUNTDIR%\Windows\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msyhl.ttc" "%BOOTMOUNTDIR%\Windows\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\mingliub.ttc" "%BOOTMOUNTDIR%\Windows\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\simsun.ttc" "%BOOTMOUNTDIR%\Windows\Fonts" %_Nul3%
)
if /i !LANGUAGE%1!==zh-hk (
echo.
echo ============================================================
echo Add Font Support: !LANGUAGE%1!
echo ============================================================
echo.
if not exist "%BOOTMOUNTDIR%\Windows\Boot\Fonts\cht_boot.ttf" (
icacls "%BOOTMOUNTDIR%\Windows\Boot\Fonts" /save "!TEMPDIR!\AclFile" %_Nul3%&takeown /f "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%&icacls "%BOOTMOUNTDIR%\Windows\Boot\Fonts" /grant *S-1-5-32-544:F %_Nul3%
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\cht_boot.ttf" "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msjhn_boot.ttf" "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msjh_boot.ttf" "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%
icacls "%BOOTMOUNTDIR%\Windows\Boot\Fonts" /setowner "NT Service\TrustedInstaller" %_Nul3%&icacls "%BOOTMOUNTDIR%\Windows\Boot" /restore "!TEMPDIR!\AclFile" %_Nul3%
)
reg.exe load HKLM\OFFLINE "%BOOTMOUNTDIR%\Windows\System32\config\SOFTWARE" %_Nul1%&reg.exe import "!WORKDIR!\dism\EA\zh-hk.reg" %_Nul1%&reg.exe unload HKLM\OFFLINE %_Nul1%
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msjh.ttc" "%BOOTMOUNTDIR%\Windows\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\mingliub.ttc" "%BOOTMOUNTDIR%\Windows\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\simsun.ttc" "%BOOTMOUNTDIR%\Windows\Fonts" %_Nul3%
)
if /i !LANGUAGE%1!==zh-tw (
echo.
echo ============================================================
echo Add Font Support: !LANGUAGE%1!
echo ============================================================
echo.
if not exist "%BOOTMOUNTDIR%\Windows\Boot\Fonts\cht_boot.ttf" (
icacls "%BOOTMOUNTDIR%\Windows\Boot\Fonts" /save "!TEMPDIR!\AclFile" %_Nul3%&takeown /f "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%&icacls "%BOOTMOUNTDIR%\Windows\Boot\Fonts" /grant *S-1-5-32-544:F %_Nul3%
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\cht_boot.ttf" "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msjhn_boot.ttf" "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msjh_boot.ttf" "%BOOTMOUNTDIR%\Windows\Boot\Fonts" %_Nul3%
icacls "%BOOTMOUNTDIR%\Windows\Boot\Fonts" /setowner "NT Service\TrustedInstaller" %_Nul3%&icacls "%BOOTMOUNTDIR%\Windows\Boot" /restore "!TEMPDIR!\AclFile" %_Nul3%
)
reg.exe load HKLM\OFFLINE "%BOOTMOUNTDIR%\Windows\System32\config\SOFTWARE" %_Nul1%&reg.exe import "!WORKDIR!\dism\EA\zh-tw.reg" %_Nul1%&reg.exe unload HKLM\OFFLINE %_Nul1%
copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\msjh.ttc" "%BOOTMOUNTDIR%\Windows\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\mingliub.ttc" "%BOOTMOUNTDIR%\Windows\Fonts" %_Nul3%&copy /y "!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!\simsun.ttc" "%BOOTMOUNTDIR%\Windows\Fonts" %_Nul3%
)
goto :eof

:SbS
set savr=1
if %_build% geq 18362 set savr=3
reg.exe load HKLM\TEMPWIM "%~1\Windows\System32\Config\SOFTWARE" %_Nul3%
reg.exe add HKLM\TEMPWIM\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v DisableComponentBackups /t REG_DWORD /d 1 /f %_Nul3%
reg.exe add HKLM\TEMPWIM\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d %savr% /f %_Nul3%
reg.exe unload HKLM\TEMPWIM %_Nul3%
goto :eof

:END
echo.
echo ============================================================
echo %MESSAGE%
echo ============================================================
echo.
if %_Debug% neq 0 (exit /b) else (echo Press 0 to exit.)
choice /c 0 /n
if errorlevel 1 (exit /b) else (rem.)
