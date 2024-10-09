@setlocal DisableDelayedExpansion
@set uiv=v24.5
@echo off

set DVDPATH=
set ISO=1
set WINPE=1
set SLIM=1
set NET35=0

set DEFAULTLANGUAGE=
set MOUNTDIR=

set WINPEPATH=

set RemoveInboxLP=0 

:: dism.exe tool custom path (if Host OS is Win8.1 or earlier and no Win10 ADK installed)
set "DismRoot=dism.exe"

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
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%SystemRoot%\Sysnative;%SystemRoot%;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)
set "xOS=amd64"
if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set "xOS=arm64"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "xOS=x86"
if /i "%PROCESSOR_ARCHITEW6432%"=="amd64" set "xOS=amd64"
if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" set "xOS=arm64"
set "_Null=1>nul 2>nul"
set "_psc=powershell -nop -c"
set winbuild=1
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
set _cwmi=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
cmd /c "wmic path Win32_ComputerSystem get CreationClassName /value" 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
)
set _pwsh=1
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" set _pwsh=0
cmd /c "%_psc% "$ExecutionContext.SessionState.LanguageMode"" | find /i "FullLanguage" 1>nul || (set _pwsh=0)
if %_cwmi% equ 0 if %_pwsh% equ 0 goto :E_PWS
reg.exe query HKU\S-1-5-19 %_Null% || goto :E_ADMIN
set "_log=%~dpn0"
set "WORKDIR=%~dp0"
set "WORKDIR=%WORKDIR:~0,-1%"
set "DVDDIR=%WORKDIR%\_DVD10"
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
echo.
echo Running in Debug Mode...
echo The window will be closed when finished
@echo on
@prompt $G
@call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"&del "!_log!_tmp.log"
@title %ComSpec%
@exit /b

:Begin
title Windows NT 10.0 Multilingual Creator
set "_dLog=%SystemRoot%\Logs\DISM"
set _drv=%~d0
set _ntf=NTFS
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('"wmic volume where DriveLetter='%_drv%' get FileSystem /value"') do set "_ntf=%%#"
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 0 for /f %%# in ('%_psc% "(([WMISEARCHER]'Select * from Win32_Volume where DriveLetter=\"%_drv%\"').Get()).FileSystem"') do set "_ntf=%%#"
if /i not "%_ntf%"=="NTFS" set _drv=%SystemDrive%
if "!MOUNTDIR!"=="" set "MOUNTDIR=%_drv%\W10MUIMOUNT"
set "MOUNTDIR=%MOUNTDIR:"=%"
if "%MOUNTDIR:~-1%"=="\" set "MOUNTDIR=%MOUNTDIR:~0,-1%"
set "INSTALLMOUNTDIR=%MOUNTDIR%\install"
set "WINREMOUNTDIR=%MOUNTDIR%\winre"
set "BOOTMOUNTDIR=%MOUNTDIR%\boot"
set EAlpid=(ja-jp,ko-kr,zh-cn,zh-hk,zh-tw)
set bootmui=(appraiser.dll,arunres.dll,cmisetup.dll,compatctrl.dll,compatprovider.dll,deployprovider.dll,dism.exe,dismapi.dll,dismcore.dll,dismprov.dll,folderprovider.dll,imagingprovider.dll,input.dll,logprovider.dll,mediasetupuimgr.dll,nlsbres.dll,osimageprovider.dll,pnpibs.dll,reagent.dll,rollback.exe,setup.exe,setupcompat.dll,setupcore.dll,setupmgr.dll,setupplatform.exe,setupprep.exe,smiengine.dll,spwizres.dll,upgloader.dll,uxlibres.dll,vhdprovider.dll,w32uires.dll,wdsclient.dll,wdsimage.dll,wimgapi.dll,wimprovider.dll,windlp.dll,winsetup.dll)
goto :adk10

:DismVer
set _all=0
set "dsmver=10240"
if %_cwmi% equ 1 for /f "tokens=4 delims==." %%# in ('wmic datafile where "name='!dsv!'" get Version /value') do set "dsmver=%%#" 
if %_cwmi% equ 0 for /f "tokens=3 delims=." %%# in ('%_psc% "([WMI]'CIM_DataFile.Name=''!dsv!''').Version"') do set "dsmver=%%#"
if %dsmver% lss 25115 set _all=1
exit /b

:adk10
if /i not "!dismroot!"=="dism.exe" (
goto :check
)
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
if exist "%DandIRoot%\x86\DISM\dism.exe" if /i %xOS%==arm64 (
set "DismRoot=%DandIRoot%\x86\DISM\dism.exe"
goto :check
)
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" (
set "DismRoot=%DandIRoot%\%xOS%\DISM\dism.exe"
goto :check
)

:skipadk
set "DismRoot=!WORKDIR!\dism\dism.exe"
if /i %xOS%==amd64 set "DismRoot=!WORKDIR!\dism\dism64\dism.exe"
if %winbuild% GEQ 10240 set "DismRoot=%SysPath%\dism.exe"

:check
if not exist "!DismRoot!" goto :E_BIN
set _dism2="!DismRoot!" /English /ScratchDir
set "dsv=!dismroot:\=\\!"
call :DismVer
cd /d "!WORKDIR!"
if "!WINPEPATH!"=="" (
for /f %%# in ('dir /b /ad "WinPE\amd64\WinPE_OCs\*-*" %_Nul6%') do if exist "WinPE\amd64\WinPE_OCs\%%#\lp.cab" set "WinPERoot=!WORKDIR!\WinPE"
for /f %%# in ('dir /b /ad "WinPE\x86\WinPE_OCs\*-*" %_Nul6%') do if exist "WinPE\x86\WinPE_OCs\%%#\lp.cab" set "WinPERoot=!WORKDIR!\WinPE"
) else (
for /f %%# in ('dir /b /ad "!WINPEPATH!\amd64\WinPE_OCs\*-*" %_Nul6%') do if exist "!WINPEPATH!\amd64\WinPE_OCs\%%#\lp.cab" set "WinPERoot=!WINPEPATH!"
for /f %%# in ('dir /b /ad "!WINPEPATH!\x86\WinPE_OCs\*-*" %_Nul6%') do if exist "!WINPEPATH!\x86\WinPE_OCs\%%#\lp.cab" set "WinPERoot=!WINPEPATH!"
)
if not exist "!_7z!" goto :E_BIN

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
echo ============================================================
echo Running W10MUI %uiv%
echo ============================================================
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
if exist ".\langs\*.cab" for /f "tokens=* delims=" %%i in ('dir /b /on ".\langs\*.cab"') do (
set /a _ol+=1
set /a count+=1
set "LPFILE!count!=%%i"
)
if exist ".\langs\*.esd" for /f "tokens=* delims=" %%i in ('dir /b /on ".\langs\*.esd"') do (
set /a _ol+=1
set /a count+=1
set "LPFILE!count!=%%i"
)
if %_ol% equ 0 goto :E_FILES
set LANGUAGES=%_ol%
set count=0
set _oa=0
if exist ".\ondemand\x86\*.cab" for /f "tokens=* delims=" %%i in ('dir /b ".\ondemand\x86\*.cab"') do (
set /a _oa+=1
set /a count+=1
set "OAFILE!count!=%%i"
)
set count=0
set _ob=0
if exist ".\ondemand\x64\*.cab" for /f "tokens=* delims=" %%i in ('dir /b ".\ondemand\x64\*.cab"') do (
set /a _ob+=1
set /a count+=1
set "OBFILE!count!=%%i"
)
set foundupdates=0
if exist ".\Updates\W10UI.cmd" (
if exist ".\Updates\SSU-*-*.*" set foundupdates=1
if exist ".\Updates\*Windows1*-KB*.*" set foundupdates=1
for /f "skip=2 tokens=1* delims==" %%A in ('find /i "repo " ".\Updates\W10UI.ini" %_Nul6%') do (
  if exist "%%~B\SSU-*-*.*" set foundupdates=1
  if exist "%%~B\*Windows1*-KB*.*" set foundupdates=1
  )
)

for /L %%j in (1,1,%LANGUAGES%) do (
"!_7z!" e ".\langs\!LPFILE%%j!" -o"!EXTRACTDIR!" langcfg.ini %_Null%
for /f "tokens=2 delims==" %%i in ('type "!EXTRACTDIR!\langcfg.ini" ^| findstr /i "Language"') do set "LANGUAGE%%j=%%i"
del /f /q "!EXTRACTDIR!\langcfg.ini"
"!_7z!" e ".\langs\!LPFILE%%j!" -o"!EXTRACTDIR!" Microsoft-Windows-Common-Foundation-Package*~10.*.mum %_Null%
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
if not exist "!WinpeOC%%j!\!LANGUAGE%%j!\lp.cab" call set WINPE=0
)
set _lpver=%LPBUILD1%

for %%# in (
basic font hand ocr speech tts intl 
ext tra ntwrk 1st 2nd 3rd paint note 
power ppmc pwsf word step snip nots 
ieop ethernet wifi media wmi 
pfs tlnt tftp vbse wocr smb stcp 
adam sync sense tsc vmp 
) do (
set "_OD%%#86="
set "_OD%%#64="
)
if %_oa% neq 0 for /L %%j in (1,1,%_oa%) do (call :setfod 86 OAFILE %%j&popd)
if %_ob% neq 0 for /L %%j in (1,1,%_ob%) do (call :setfod 64 OBFILE %%j&popd)
goto :contwork

:setfod
set "ofc=%2%3"
"!_7z!" x ".\ondemand\x%1\!%2%3!" -o"!TEMPDIR!\FOD%1\!ofc!" * -r %_Null%
if not exist "!TEMPDIR!\FOD%1\!ofc!" (
echo.
echo ERROR: cannot extract !%2%3!
goto :eof
)
pushd "!TEMPDIR!\FOD%1\!ofc!"
findstr /i /m Microsoft-Windows-LanguageFeatures-Basic update.mum %_Nul3% && (call set _ODbasic%1=!_ODbasic%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-LanguageFeatures-Fonts update.mum %_Nul3% && (call set _ODfont%1=!_ODfont%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-LanguageFeatures-Handwriting update.mum %_Nul3% && (call set _ODhand%1=!_ODhand%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-LanguageFeatures-OCR update.mum %_Nul3% && (call set _ODocr%1=!_ODocr%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-LanguageFeatures-Speech update.mum %_Nul3% && (call set _ODspeech%1=!_ODspeech%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-LanguageFeatures-TextToSpeech update.mum %_Nul3% && (call set _ODtts%1=!_ODtts%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-InternationalFeatures update.mum %_Nul3% && (call set _ODintl%1=!_ODintl%1! /PackagePath:!ofc!\update.mum&goto :eof)
if %_lpver% GEQ 19041 (
findstr /i /m Microsoft-Windows-MSPaint-FoD update.mum %_Nul3% && (set _ODext%1=1&call set _ODpaint%1=!_ODpaint%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-Notepad-FoD update.mum %_Nul3% && (set _ODext%1=1&call set _ODnote%1=!_ODnote%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-PowerShell-ISE-FOD update.mum %_Nul3% && (set _ODext%1=1&call set _ODpower%1=!_ODpower%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-Printing-PMCPPC-FoD update.mum %_Nul3% && (set _ODtra%1=1&call set _ODppmc%1=!_ODppmc%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-Printing-WFS-FoD update.mum %_Nul3% && (set _ODtra%1=1&call set _ODpwsf%1=!_ODpwsf%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-WordPad-FoD update.mum %_Nul3% && (set _ODtra%1=1&call set _ODword%1=!_ODword%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-StepsRecorder update.mum %_Nul3% && (set _ODtra%1=1&call set _ODstep%1=!_ODstep%1! /PackagePath:!ofc!\update.mum&goto :eof)
  )
if %_lpver% GEQ 21277 (
findstr /i /m Microsoft-Windows-Notepad-System-FoD update.mum %_Nul3% && (set _ODext%1=1&call set _ODnots%1=!_ODnots%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-SnippingTool-FoD update.mum %_Nul3% && (set _ODtra%1=1&call set _ODsnip%1=!_ODsnip%1! /PackagePath:!ofc!\update.mum&goto :eof)
  )
if %_lpver% GEQ 21382 (
findstr /i /m Microsoft-Windows-Ethernet-Client update.mum %_Nul3% && (set _ODntwrk%1=1&call set _ODethernet%1=!_ODethernet%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-Wifi-Client update.mum %_Nul3% && (set _ODntwrk%1=1&call set _ODwifi%1=!_ODwifi%1! /PackagePath:!ofc!\update.mum&goto :eof)
  )
if %_lpver% GEQ 22000 (
findstr /i /m Microsoft-Windows-InternetExplorer-Optional update.mum %_Nul3% && (set _ODext%1=1&call set _ODieop%1=!_ODieop%1! /PackagePath:!ofc!\update.mum&goto :eof)
  )
if %_lpver% GEQ 22567 (
findstr /i /m Microsoft-Windows-MediaPlayer update.mum %_Nul3% && (set _OD1st%1=1&call set _ODmedia%1=!_ODmedia%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-WMIC-FoD update.mum %_Nul3% && (set _OD1st%1=1&call set _ODwmi%1=!_ODwmi%1! /PackagePath:!ofc!\update.mum&goto :eof)
  )
if %_lpver% GEQ 25330 (
findstr /i /m Microsoft-Windows-ProjFS-OptionalFeature-FOD update.mum %_Nul3% && (set _OD2nd%1=1&call set _ODpfs%1=!_ODpfs%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-Telnet-Client-FOD update.mum %_Nul3% && (set _OD2nd%1=1&call set _ODtlnt%1=!_ODtlnt%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-TFTP-Client-FOD update.mum %_Nul3% && (set _OD2nd%1=1&call set _ODtftp%1=!_ODtftp%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-VBSCRIPT-FoD update.mum %_Nul3% && (set _OD2nd%1=1&call set _ODvbse%1=!_ODvbse%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-WinOcr-FOD update.mum %_Nul3% && (set _OD2nd%1=1&call set _ODwocr%1=!_ODwocr%1! /PackagePath:!ofc!\update.mum&goto :eof)
  )
if %_lpver% GEQ 26040 (
findstr /i /m Microsoft-Windows-DirectoryServices-ADAM-Client-FOD update.mum %_Nul3% && (set _OD3rd%1=1&call set _ODadam%1=!_ODadam%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-EnterpriseClientSync-Host-FOD update.mum %_Nul3% && (set _OD3rd%1=1&call set _ODsync%1=!_ODsync%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-SenseClient-FoD update.mum %_Nul3% && (set _OD3rd%1=1&call set _ODsense%1=!_ODsense%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-SimpleTCP-FOD update.mum %_Nul3% && (set _OD3rd%1=1&call set _ODstcp%1=!_ODstcp%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m Microsoft-Windows-SmbDirect-FOD update.mum %_Nul3% && (set _OD3rd%1=1&call set _ODsmb%1=!_ODsmb%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m TerminalServices-AppServer-Client-FOD update.mum %_Nul3% && (set _OD1st%1=1&call set _ODtsc%1=!_ODtsc%1! /PackagePath:!ofc!\update.mum&goto :eof)
findstr /i /m VirtualMachinePlatform-Client-Disabled-FOD update.mum %_Nul3% && (set _OD1st%1=1&call set _ODvmp%1=!_ODvmp%1! /PackagePath:!ofc!\update.mum&goto :eof)
  )
goto :eof

:contwork
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
for %%# in (19042 19043 19044 19045) do if %_build% equ %%# set _build=19041
for %%# in (22622 22623 22624 22631 22635) do if %_build% equ %%# set _build=22621
if %_build% equ 20349 set _build=20348
if %_build% equ 26120 set _build=26100
for /L %%j in (1,1,%LANGUAGES%) do (
if not !LPBUILD%%j!==%_build% set "ERRFILE=!LPFILE%%j!"&goto :E_VER
)
if %WINPE%==1 for /L %%j in (1,1,%LANGUAGES%) do (
"!_7z!" e "!WinpeOC%%j!\!LANGUAGE%%j!\lp.cab" -o"!EXTRACTDIR!" Microsoft-Windows-Common-Foundation-Package*%_build%*.mum %_Null%
if not exist "!EXTRACTDIR!\*.mum" call set WINPE=0
)
for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\boot.wim" ^| findstr "Index"') do set BOOTCOUNT=%%i
for /f "tokens=2 delims=: " %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\boot.wim" /index:1 ^| find /i "Architecture"') do set "BOOTARCH=%%i"
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
if %_label86%==1 (set wimbit=96) else (set wimbit=64)
)
echo Build: %_build%
echo Count: %imgcount% Image^(s^)
if %wimbit%==96 (echo Arch : Multi) else (echo Arch : %wimbit%-bit)
if %wimbit%==96 set NET35=0
if %_build% GEQ 26040 set SLIM=0
set _pex=0
if %SLIM% NEQ 1 set _pex=1

set _sss=Client
dism\dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\install.wim" /index:1 | findstr /i /c:"Installation : Server" %_Nul1% && set _sss=Server
if "%_sss%"=="Server" dism\dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\install.wim" /index:1 | findstr /i /c:"ServerAzureStackHCI" %_Nul1% && set _sss=ASZ
if %RemoveInboxLP% NEQ 2 if %_build% EQU 26100 if "%_sss%"=="Server" for /L %%j in (1,1,%LANGUAGES%) do (
call :chkSrvLP "!LANGUAGE%%j!"
)
if %RemoveInboxLP% NEQ 1 if "%DEFAULTLANGUAGE%"=="" (
for /f "tokens=1" %%i in ('dism\dism.exe /english /get-wiminfo /wimfile:"!DVDDIR!\sources\install.wim" /index:1 ^| find /i "Default"') do set "DEFAULTLANGUAGE=%%i"
)

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
call set _PES%2=!_PES%2! /PackagePath:!LANGUAGE%1!\WinPE-Setup_!LANGUAGE%1!.cab /PackagePath:!LANGUAGE%1!\WinPE-Setup-%_sss%_!LANGUAGE%1!.cab
call set _PEX%2=!_PEX%2! /PackagePath:!LANGUAGE%1!\WinPE-EnhancedStorage_!LANGUAGE%1!.cab /PackagePath:!LANGUAGE%1!\WinPE-Scripting_!LANGUAGE%1!.cab /PackagePath:!LANGUAGE%1!\WinPE-SecureStartup_!LANGUAGE%1!.cab /PackagePath:!LANGUAGE%1!\WinPE-WDS-Tools_!LANGUAGE%1!.cab /PackagePath:!LANGUAGE%1!\WinPE-WMI_!LANGUAGE%1!.cab
call set _PER%2=!_PER%2! /PackagePath:!LANGUAGE%1!\WinPE-HTA_!LANGUAGE%1!.cab /PackagePath:!LANGUAGE%1!\WinPE-Rejuv_!LANGUAGE%1!.cab /PackagePath:!LANGUAGE%1!\WinPE-StorageWMI_!LANGUAGE%1!.cab
for %%G in %EAlang% do if /i !LANGUAGE%1!==%%G (
call set _PEF%2=!_PEF%2! /PackagePath:WinPE-FontSupport-%%G.cab
)
goto :eof

:chkSrvLP
for %%# in (
ar-SA bg-BG da-DK el-GR en-GB
et-EE fi-FI he-IL hr-HR lt-LT
lv-LV nb-NO ro-RO sk-SK sl-SI
sr-LATN-RS th-TH uk-UA
) do (
if /i "%~1"=="%%#" set RemoveInboxLP=1
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
set "_eal=!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!"
echo !LANGUAGE%1! / %3
"!_7z!" e ".\langs\!LPFILE%1!" -o"!_eal!" vofflps.rtf -r -aos %_Null%
"!_7z!" x ".\langs\!LPFILE%1!" -o"!_eal!" *setup\sources -r %_Null%
"!_7z!" x ".\langs\!LPFILE%1!" -o"!TEMPDIR!\!LPARCH%1!\!LANGUAGE%1!" * -r %_Null%
if not exist "!_eal!\setup\sources\!LANGUAGE%1!\*.mui" (
robocopy "!_eal!\setup\sources" "!EXTRACTDIR!\TEMP\!LANGUAGE%1!" /E /MOVE %_Nul1%
robocopy "!EXTRACTDIR!\TEMP\!LANGUAGE%1!" "!_eal!\setup\sources\!LANGUAGE%1!" /E /MOVE %_Nul1%
) 
call set _PP%2=!_PP%2! /PackagePath:!LANGUAGE%1!\update.mum
goto :eof

:dowork
set _actEP=0
set _SrvEdt=0
set _AszEdt=0
if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
if exist "%SystemRoot%\temp\UpdateAgent.dll" del /f /q "%SystemRoot%\temp\UpdateAgent.dll" %_Nul3%
if exist "%SystemRoot%\temp\Facilitator.dll" del /f /q "%SystemRoot%\temp\Facilitator.dll" %_Nul3%
if %_build% GEQ 19041 if %winbuild% lss 17133 if not exist "%SysPath%\ext-ms-win-security-slc-l1-1-0.dll" (
copy /y %SysPath%\slc.dll %SysPath%\ext-ms-win-security-slc-l1-1-0.dll %_Nul1%
if /i not %xOS%==x86 copy /y %SystemRoot%\SysWOW64\slc.dll %SystemRoot%\SysWOW64\ext-ms-win-security-slc-l1-1-0.dll %_Nul1%
)
set isomin=0
for /L %%i in (1,1,%imgcount%) do set "_i=%%i"&call :doinstall
if defined errMOUNT goto :eof
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
if %RemoveInboxLP% EQU 1 if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-Server-LanguagePack-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1.mum" (
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIEnUsRemove.log" /Remove-Package /PackageName:Microsoft-Windows-Server-LanguagePack-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIEnUsClean.log" /Cleanup-Image /StartComponentCleanup /ResetBase
)
pushd "!TEMPDIR!\!WIMARCH%_i%!"
if defined _PP64 if /i !WIMARCH%_i%!==amd64 (
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallLP64.log" /Add-Package !_PP64!
)
if defined _PP86 if /i !WIMARCH%_i%!==x86 (
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallLP86.log" /Add-Package !_PP86!
)
popd
if /i !WIMARCH%_i%!==amd64 if exist "!TEMPDIR!\FOD64\OBFILE1\update.mum" call :addfod 64
if /i !WIMARCH%_i%!==x86 if exist "!TEMPDIR!\FOD86\OAFILE1\update.mum" call :addfod 86
echo.
echo ============================================================
echo Update language settings
echo ============================================================
echo.
if not "%DEFAULTLANGUAGE%"=="" if not exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-*-LanguagePack-Package*~%DEFAULTLANGUAGE%~*.mum" (
set "DEFAULTLANGUAGE="
)
if "%DEFAULTLANGUAGE%"=="" for /L %%j in (1,1,%LANGUAGES%) do (
if not defined DEFAULTLANGUAGE if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-*-LanguagePack-Package*~!LANGUAGE%%j!~*.mum" call set "DEFAULTLANGUAGE=!LANGUAGE%%j!"
)
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE% /Quiet
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE% /Quiet
if %_i%==%imgcount% (
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /Gen-LangINI /Distribution:"!DVDDIR!" /Quiet
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /Set-SetupUILang:%DEFAULTLANGUAGE% /Distribution:"!DVDDIR!" /Quiet
)
if %foundupdates% EQU 1 call Updates\W10UI.cmd 1 "%INSTALLMOUNTDIR%" "!TMPUPDT!" "!DVDDIR!\sources"
if %_Debug% neq 0 (@echo on) else (@echo off)
cd /d "!WORKDIR!"
if not defined isomaj for /f "tokens=6,7 delims=_." %%a in ('dir /b /a:-d /od "%INSTALLMOUNTDIR%\Windows\WinSxS\Manifests\*_microsoft-windows-coreos-revision*.manifest"') do (set isover=%%a.%%b&set isomaj=%%a&set isomin=%%b)
if not defined isolab (
if %_build% GEQ 15063 (call :detectLab isolab) else (call :legacyLab isolab)
)
if not defined isodate if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Package_for_RollupFix*.mum" (
for /f %%# in ('dir /b /a:-d /od "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Package_for_RollupFix*.mum"') do copy /y "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\%%#" %SystemRoot%\temp\update.mum %_Nul1%
call :datemum isodate
)
if %_actEP% equ 0 if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\microsoft-windows-*enablement-package~*.mum" call :detectEP
if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" set _SrvEdt=1
if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-ServerAzureStackHCI*Edition~*.mum" set _AszEdt=1
if exist "%INSTALLMOUNTDIR%\Windows\system32\UpdateAgent.dll" if not exist "%SystemRoot%\temp\UpdateAgent.dll" copy /y "%INSTALLMOUNTDIR%\Windows\system32\UpdateAgent.dll" %SystemRoot%\temp\ %_Nul3%
if exist "%INSTALLMOUNTDIR%\Windows\system32\Facilitator.dll" if not exist "%SystemRoot%\temp\Facilitator.dll" copy /y "%INSTALLMOUNTDIR%\Windows\system32\Facilitator.dll" %SystemRoot%\temp\ %_Nul3%
if %NET35%==1 if not exist "%INSTALLMOUNTDIR%\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" (
echo.
echo ============================================================
echo Enable .NET Framework 3.5 - index %_i%/%imgcount%
echo ============================================================
!_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUINetFx3.log" /Enable-Feature /Featurename:NetFx3 /All /LimitAccess /Source:"!DVDDIR!\sources\sxs"
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

:addfod
set "_svcn=%INSTALLMOUNTDIR%\Windows\Servicing\Packages"
pushd "!TEMPDIR!\FOD%1"
set "_APext="
if defined _ODext%1 (
if defined _ODieop%1 if exist "%_svcn%\Microsoft-Windows-InternetExplorer-Optional-Package*.mum" set "_APext=!_ODieop%1!"
if defined _ODpower%1 if exist "%_svcn%\Microsoft-Windows-PowerShell-ISE-FOD*.mum" set "_APext=!_ODpower%1! !_APext!"
if defined _ODnots%1 if exist "%_svcn%\Microsoft-Windows-Notepad-System-FoD*.mum" set "_APext=!_ODnots%1! !_APext!"
if defined _ODnote%1 if exist "%_svcn%\Microsoft-Windows-Notepad-FoD*.mum" set "_APext=!_ODnote%1! !_APext!"
if defined _ODpaint%1 if exist "%_svcn%\Microsoft-Windows-MSPaint-FoD*.mum" set "_APext=!_ODpaint%1! !_APext!"
)
set "_APtra="
if defined _ODtra%1 (
if defined _ODsnip%1 if exist "%_svcn%\Microsoft-Windows-SnippingTool-FoD*.mum" set "_APtra=!_ODsnip%1!"
if defined _ODstep%1 if exist "%_svcn%\Microsoft-Windows-StepsRecorder-Package*.mum" set "_APtra=!_ODstep%1! !_APtra!"
if defined _ODword%1 if exist "%_svcn%\Microsoft-Windows-WordPad-FoD*.mum" set "_APtra=!_ODword%1! !_APtra!"
if defined _ODpwsf%1 if exist "%_svcn%\Microsoft-Windows-Printing-WFS-FoD*.mum" set "_APtra=!_ODpwsf%1! !_APtra!"
if defined _ODppmc%1 if exist "%_svcn%\Microsoft-Windows-Printing-PMCPPC-FoD*.mum" set "_APtra=!_ODppmc%1! !_APtra!"
)
set "_AP1st="
if defined _OD1st%1 (
if defined _ODvmp%1 if exist "%_svcn%\*VirtualMachinePlatform-Client-Disabled-FOD*.mum" set "_AP1st=!_ODvmp%1!"
if defined _ODtsc%1 if exist "%_svcn%\*TerminalServices-AppServer-Client-FOD*.mum" set "_AP1st=!_ODtsc%1! !_AP1st!"
if defined _ODwmi%1 if exist "%_svcn%\Microsoft-Windows-WMIC-FoD*.mum" set "_AP1st=!_ODwmi%1! !_AP1st!"
if defined _ODmedia%1 if exist "%_svcn%\Microsoft-Windows-MediaPlayer-Package*.mum" set "_AP1st=!_ODmedia%1! !_AP1st!"
)
set "_AP2nd="
if defined _OD2nd%1 (
if defined _ODwocr%1 if exist "%_svcn%\Microsoft-Windows-WinOcr-FOD*.mum" set "_AP2nd=!_ODwocr%1!"
if defined _ODvbse%1 if exist "%_svcn%\Microsoft-Windows-VBSCRIPT-FoD*.mum" set "_AP2nd=!_ODvbse%1! !_AP2nd!"
if defined _ODtftp%1 if exist "%_svcn%\Microsoft-Windows-TFTP-Client-FOD*.mum" set "_AP2nd=!_ODtftp%1! !_AP2nd!"
if defined _ODtlnt%1 if exist "%_svcn%\Microsoft-Windows-Telnet-Client-FOD*.mum" set "_AP2nd=!_ODtlnt%1! !_AP2nd!"
if defined _ODpfs%1 if exist "%_svcn%\Microsoft-Windows-ProjFS-OptionalFeature-FOD*.mum" set "_AP2nd=!_ODpfs%1! !_AP2nd!"
)
set "_AP3rd="
if defined _OD3rd%1 (
if defined _ODsmb%1 if exist "%_svcn%\Microsoft-Windows-SmbDirect-FOD*.mum" set "_AP3rd=!_ODsmb%1!"
if defined _ODstcp%1 if exist "%_svcn%\Microsoft-Windows-SimpleTCP-FOD*.mum" set "_AP3rd=!_ODstcp%1! !_AP3rd!"
if defined _ODsense%1 if exist "%_svcn%\Microsoft-Windows-SenseClient-FoD*.mum" set "_AP3rd=!_ODsense%1! !_AP3rd!"
if defined _ODsync%1 if exist "%_svcn%\Microsoft-Windows-EnterpriseClientSync-Host-FOD*.mum" set "_AP3rd=!_ODsync%1! !_AP3rd!"
if defined _ODadam%1 if exist "%_svcn%\Microsoft-Windows-DirectoryServices-ADAM-Client-FOD*.mum" set "_AP3rd=!_ODadam%1! !_AP3rd!"
)
if defined _ODbasic%1 !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallFOD%1a.log" /Add-Package !_ODbasic%1!
if defined _ODbasic%1 !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallFOD%1a.log" /Add-Package !_ODfont%1! !_ODtts%1! !_ODhand%1! !_ODocr%1! !_ODspeech%1! !_ODintl%1!
if defined _APext !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallFOD%1b.log" /Add-Package !_APext!
if defined _APtra !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallFOD%1c.log" /Add-Package !_APtra!
if defined _AP1st !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallFOD%1d.log" /Add-Package !_AP1st!
if defined _AP2nd !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallFOD%1e.log" /Add-Package !_AP2nd!
if defined _AP3rd !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallFOD%1f.log" /Add-Package !_AP3rd!
if defined _ODntwrk%1 !_dism2!:"!TMPDISM!" /Image:"%INSTALLMOUNTDIR%" /LogPath:"%_dLog%\MUIinstallFOD%1n.log" /Add-Package !_ODethernet%1! !_ODwifi%1!
popd
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
if /i !LANGUAGE%1!==ja-jp xcopy "!_fnti!\*" "!_eal!\" /chryi %_Nul1%&copy /y "!_fntw!\meiryo.ttc" "!_eal!" %_Nul3%&copy /y "!_fntw!\msgothic.ttc" "!_eal!" %_Nul3%
if /i !LANGUAGE%1!==ko-kr xcopy "!_fnti!\*" "!_eal!\" /chryi %_Nul1%&copy /y "!_fntw!\malgun.ttf" "!_eal!" %_Nul1%&copy /y "!_fntw!\gulim.ttc" "!_eal!" %_Nul3%
if /i !LANGUAGE%1!==zh-cn xcopy "!_fnti!\*" "!_eal!\" /chryi %_Nul1%&copy /y "!_fntw!\msyh.ttc" "!_eal!" %_Nul1%&copy /y "!_fntw!\mingliub.ttc" "!_eal!" %_Nul1%&copy /y "!_fntw!\simsun.ttc" "!_eal!" %_Nul1%&copy /y "!_fntw!\msyhl.ttc" "!_eal!" %_Nul1%
if /i !LANGUAGE%1!==zh-hk xcopy "!_fnti!\*" "!_eal!\" /chryi %_Nul1%&copy /y "!_fntw!\msjh.ttc" "!_eal!" %_Nul1%&copy /y "!_fntw!\mingliub.ttc" "!_eal!" %_Nul1%&copy /y "!_fntw!\simsun.ttc" "!_eal!" %_Nul1%
if /i !LANGUAGE%1!==zh-tw xcopy "!_fnti!\*" "!_eal!\" /chryi %_Nul1%&copy /y "!_fntw!\msjh.ttc" "!_eal!" %_Nul1%&copy /y "!_fntw!\mingliub.ttc" "!_eal!" %_Nul1%&copy /y "!_fntw!\simsun.ttc" "!_eal!" %_Nul1%
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
call :SbS "%WINREMOUNTDIR%"
pushd "!WinPERoot!\!WIMARCH%1!\WinPE_OCs"
if defined _PEM64 if /i !WIMARCH%1!==amd64 (
  !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP64.log" /Add-Package !_PEM64! !_PEF64!
  !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP64.log" /Add-Package !_PER64!
  if %_pex% EQU 1 !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP64.log" /Add-Package !_PEX64!
)
if defined _PEM86 if /i !WIMARCH%1!==x86 (
  !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP86.log" /Add-Package !_PEM86! !_PEF86!
  !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP86.log" /Add-Package !_PER86!
  if %_pex% EQU 1 !_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinreLP86.log" /Add-Package !_PEX86!
)
popd
echo.
echo ============================================================
echo Update language settings
echo ============================================================
!_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /Set-AllIntl:%DEFAULTLANGUAGE% /Quiet
!_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /Set-SKUIntlDefaults:%DEFAULTLANGUAGE% /Quiet
if %foundupdates% NEQ 1 (
!_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinpeClean.log" /Cleanup-Image /StartComponentCleanup
!_dism2!:"!TMPDISM!" /Image:"%WINREMOUNTDIR%" /LogPath:"%_dLog%\MUIwinpeClean.log" /Cleanup-Image /StartComponentCleanup /ResetBase
) else (
echo.
)
if %foundupdates% EQU 1 call Updates\W10UI.cmd 1 "%WINREMOUNTDIR%" "!TMPUPDT!"
if %_Debug% neq 0 (@echo on) else (@echo off)
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
!_dism2!:"!TMPDISM!" /Export-Image /SourceImageFile:"!TEMPDIR!\WR\!WIMARCH%1!\winre.wim" /SourceIndex:1 /DestinationImageFile:"!EXTRACTDIR!\winre.wim"
if exist "!EXTRACTDIR!\winre.wim" move /y "!EXTRACTDIR!\winre.wim" "!TEMPDIR!\WR\!WIMARCH%1!" %_Nul1%
goto :eof

:rewim
for /L %%i in (1,1,%BOOTCOUNT%) do set "_i=%%i"&call :doboot
if defined errMOUNT goto :eof
goto :rebuild

:doboot
echo.
echo ============================================================
echo Mount boot.wim - index %_i%/%BOOTCOUNT%
echo ============================================================
!_dism2!:"!TMPDISM!" /Mount-Wim /WimFile:"!DVDDIR!\sources\boot.wim" /Index:%_i% /MountDir:"%BOOTMOUNTDIR%"
if !errorlevel! neq 0 goto :E_MOUNT
set _stp=0
if exist "%BOOTMOUNTDIR%\Windows\Servicing\Packages\WinPE-Setup-Package~*.mum" set _stp=1
set _rej=0
if exist "%BOOTMOUNTDIR%\Windows\servicing\Packages\WinPE-Rejuv-Package~*.mum" set _rej=1
if %BOOTCOUNT%==1 if not exist "%BOOTMOUNTDIR%\sources\setup.exe" set SLIM=0
if not %WINPE%==1 (
call :WIMman%_i%
goto :contboot
)
echo.
echo ============================================================
echo Add LPs to boot.wim - index %_i%/%BOOTCOUNT%
echo ============================================================
call :SbS "%BOOTMOUNTDIR%"
pushd "!WinPERoot!\!BOOTARCH!\WinPE_OCs"
if defined _PEM64 if /i !BOOTARCH!==amd64 (
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP64.log" /Add-Package !_PEM64! !_PEF64!
  if %_i%==1 if %_rej% EQU 1 !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP64.log" /Add-Package !_PER64!
  if %_pex% EQU 1 !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP64.log" /Add-Package !_PEX64!
  if %_stp% EQU 1 (
    !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP64.log" /Add-Package !_PES64!
    if %_build% GEQ 22557 call :MUIman
  ) else (
    if %_i%==2 call :WIMman%_i%
  )
)
if defined _PEM86 if /i !BOOTARCH!==x86 (
  !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP86.log" /Add-Package !_PEM86! !_PEF86!
  if %_i%==1 if %_rej% EQU 1 !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP86.log" /Add-Package !_PER86!
  if %_pex% EQU 1 !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP86.log" /Add-Package !_PEX86!
  if %_stp% EQU 1 (
    !_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIbootLP86.log" /Add-Package !_PES86!
    if %_build% GEQ 22557 call :MUIman
  ) else (
    if %_i%==2 call :WIMman%_i%
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
if %_stp% EQU 1 (
!_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /Gen-LangINI /Distribution:"%BOOTMOUNTDIR%" /Quiet
!_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /Set-SetupUILang:%DEFAULTLANGUAGE% /Distribution:"%BOOTMOUNTDIR%" /Quiet
)
if %foundupdates% NEQ 1 (
!_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIwinpeClean.log" /Cleanup-Image /StartComponentCleanup
!_dism2!:"!TMPDISM!" /Image:"%BOOTMOUNTDIR%" /LogPath:"%_dLog%\MUIwinpeClean.log" /Cleanup-Image /StartComponentCleanup /ResetBase
)
if %_i%==2 if not %wimbit%==96 for /L %%j in (1,1,%LANGUAGES%) do (
  xcopy "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!\*.rtf" "!DVDDIR!\sources\!LANGUAGE%%j!\" /chryi %_Nul3%
  xcopy "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!\*.rtf" "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\" /chryi %_Nul3%
  copy /y "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!\vofflps.rtf" "!DVDDIR!\sources\!LANGUAGE%%j!\privacy.rtf" %_Nul3%
)
:contboot
set _keep=1
if %_i%==%BOOTCOUNT% set _keep=0
if %foundupdates% EQU 1 call Updates\W10UI.cmd %_keep% "%BOOTMOUNTDIR%" "!TMPUPDT!"
if %_Debug% neq 0 (@echo on) else (@echo off)
cd /d "!WORKDIR!"
if exist "%BOOTMOUNTDIR%\sources\setup.exe" (
if %_i%==1 copy /y "%BOOTMOUNTDIR%\sources\setup.exe" "!DVDDIR!\sources" %_Nul3%
if %_i%==2 call :boots
)
call :cleanmanual "%BOOTMOUNTDIR%"
echo.
echo ============================================================
echo Unmount boot.wim - index %_i%/%BOOTCOUNT%
echo ============================================================
!_dism2!:"!TMPDISM!" /Unmount-Wim /MountDir:"%BOOTMOUNTDIR%" /Commit
if !errorlevel! neq 0 goto :E_UNMOUNT
goto :eof

:rebuild
echo.
echo ============================================================
echo Rebuild boot.wim
echo ============================================================
if %_all% equ 1 !_dism2!:"!TMPDISM!" /Export-Image /SourceImageFile:"!DVDDIR!\sources\boot.wim" /All /DestinationImageFile:"!DVDDIR!\boot.wim"
if %_all% equ 0 for /L %%i in (1,1,%BOOTCOUNT%) do !_dism2!:"!TMPDISM!" /Export-Image /SourceImageFile:"!DVDDIR!\sources\boot.wim" /SourceIndex:%%i /DestinationImageFile:"!DVDDIR!\boot.wim"
if exist "!DVDDIR!\boot.wim" move /y "!DVDDIR!\boot.wim" "!DVDDIR!\sources" %_Nul1%
echo.
echo ============================================================
echo Rebuild install.wim
echo ============================================================
if %_all% equ 1 !_dism2!:"!TMPDISM!" /Export-Image /SourceImageFile:"!DVDDIR!\sources\install.wim" /All /DestinationImageFile:"!DVDDIR!\install.wim"
if %_all% equ 0 for /L %%i in (1,1,%imgcount%) do !_dism2!:"!TMPDISM!" /Export-Image /SourceImageFile:"!DVDDIR!\sources\install.wim" /SourceIndex:%%i /DestinationImageFile:"!DVDDIR!\install.wim"
if exist "!DVDDIR!\install.wim" move /y "!DVDDIR!\install.wim" "!DVDDIR!\sources" %_Nul1%
if %NET35%==1 if exist "!DVDDIR!\sources\sxs\*netfx3*.cab" del /f /q "!DVDDIR!\sources\sxs\*netfx3*.cab" %_Nul3%
xcopy "!DVDDIR!\efi\microsoft\boot\fonts\*" "!DVDDIR!\boot\fonts\" /chryi %_Nul3%
if %_build% GEQ 19041 if %winbuild% lss 17133 if exist "%SysPath%\ext-ms-win-security-slc-l1-1-0.dll" (
del /f /q %SysPath%\ext-ms-win-security-slc-l1-1-0.dll %_Nul3%
if /i not %xOS%==x86 del /f /q %SystemRoot%\SysWOW64\ext-ms-win-security-slc-l1-1-0.dll %_Nul3%
)

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
copy /y "!DVDDIR!\sources\setuphost.exe" %SystemRoot%\temp\ %_Nul3%
copy /y "!DVDDIR!\sources\setupprep.exe" %SystemRoot%\temp\ %_Nul3%
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

:fulldvd
call :DATEISO
if %_cwmi% equ 1 for /f "tokens=2 delims==." %%# in ('wmic os get localdatetime /value') do set "_date=%%#"
if %_cwmi% equ 0 for /f "tokens=1 delims=." %%# in ('%_psc% "([WMI]'Win32_OperatingSystem=@').LocalDateTime"') do set "_date=%%#"
if not defined isodate set "isodate=%_date:~2,6%-%_date:~8,4%"
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set isolab=!isolab:%%#=%%#!
)
set _label=%isover%.%isodate%.%isolab%
if %_SrvEdt% EQU 1 (set _label=%_label%_SERVER) else (set _label=%_label%_CLIENT)
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
set _c_=0
for /f "usebackq tokens=1" %%a in ("isolang.txt") do (
set /a _c_+=1
)
set _short=1
if %_build% GEQ 18362 set _short=0
if %_c_% GEQ 5 set _short=1
for /f "usebackq tokens=1" %%a in ("isolang.txt") do (
set langid=%%a
if %_short% equ 0 (
  set lpid=!langid!
  ) else (
  set lpid=!langid:~0,2!
  if /i !langid!==en-gb set lpid=en-gb
  if /i !langid!==es-mx set lpid=es-mx
  if /i !langid!==fr-ca set lpid=fr-ca
  if /i !langid!==pt-pt set lpid=pp
  if /i !langid!==sr-latn-rs set lpid=sr-latn
  if /i !langid!==zh-cn set lpid=cn
  if /i !langid!==zh-hk set lpid=hk
  if /i !langid!==zh-tw set lpid=ct
  )
if defined _mui (set "_mui=!_mui!_!lpid!") else (set "_mui=!lpid!")
)
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _mui=!_mui:%%#=%%#!
)
del /f /q "isolang.txt" %_Nul3%
goto :eof

:DATEISO
if %_pwsh% equ 0 goto :eof
set _svr1=0&set _svr2=0&set _svr3=0&set _svr4=0
set "_fvr1=%SystemRoot%\temp\UpdateAgent.dll"
set "_fvr2=%SystemRoot%\temp\setuphost.exe"
set "_fvr3=%SystemRoot%\temp\setupprep.exe"
set "_fvr4=%SystemRoot%\temp\Facilitator.dll"
set "cfvr1=!_fvr1:\=\\!"
set "cfvr2=!_fvr2:\=\\!"
set "cfvr3=!_fvr3:\=\\!"
set "cfvr4=!_fvr4:\=\\!"
if %_cwmi% equ 1 (
if exist "!_fvr1!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr1!'" get Version /value ^| find "="') do set /a "_svr1=%%a"
if exist "!_fvr2!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr2!'" get Version /value ^| find "="') do set /a "_svr2=%%a"
if exist "!_fvr3!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr3!'" get Version /value ^| find "="') do set /a "_svr3=%%a"
if exist "!_fvr4!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr4!'" get Version /value ^| find "="') do set /a "_svr4=%%a"
)
if %_cwmi% equ 0 (
if exist "!_fvr1!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr1!''').Version"') do set /a "_svr1=%%a"
if exist "!_fvr2!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr2!''').Version"') do set /a "_svr2=%%a"
if exist "!_fvr3!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr3!''').Version"') do set /a "_svr3=%%a"
if exist "!_fvr4!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr4!''').Version"') do set /a "_svr4=%%a"
)
if %isomin% neq %_svr1% if %isomin% neq %_svr2% if %isomin% neq %_svr3% if %isomin% neq %_svr4% goto :eof
if %isomin% equ %_svr1% set "_chk=!_fvr1!"
if %isomin% equ %_svr2% set "_chk=!_fvr2!"
if %isomin% equ %_svr3% set "_chk=!_fvr3!"
if %isomin% equ %_svr4% set "_chk=!_fvr4!"
if exist "!_chk!" for /f "tokens=6 delims=.) " %%# in ('%_psc% "(gi '!_chk!').VersionInfo.FileVersion" %_Nul6%') do set "_ddd=%%#"
if defined _ddd (
if /i not "%_ddd%"=="winpbld" set "isodate=%_ddd%"
)
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
if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-22H2Enablement-Package~*.mum" set "_fixEP=19045"
if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-ASOSFe22H2Enablement-Package~*.mum" set "_fixEP=20349"
if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-SV2Moment*Enablement-Package~*.mum" for /f "tokens=3 delims=-" %%a in ('dir /b /a:-d /od "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-SV2Moment*Enablement-Package~*.mum"') do (
  for /f "tokens=3 delims=eEtT" %%i in ('echo %%a') do (
    set /a _fixEP=%_build%+%%i
  )
)
if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-SV2Moment4Enablement-Package~*.mum" set "_fixEP=22631"
if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-23H2Enablement-Package~*.mum" set "_fixEP=22631"
if exist "%INSTALLMOUNTDIR%\Windows\Servicing\Packages\Microsoft-Windows-SV2BetaEnablement-Package~*.mum" set "_fixEP=22635"
set "wnt=31bf3856ad364e35_10"
if exist "%INSTALLMOUNTDIR%\Windows\WinSxS\Manifests\*_microsoft-updatetargeting-*os_31bf3856ad364e35_11.*.manifest" set "wnt=31bf3856ad364e35_11"
if exist "%INSTALLMOUNTDIR%\Windows\WinSxS\Manifests\*_microsoft-updatetargeting-*os_31bf3856ad364e35_12.*.manifest" set "wnt=31bf3856ad364e35_12"
if exist "%INSTALLMOUNTDIR%\Windows\WinSxS\Manifests\*_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest" (
for /f "tokens=5-7 delims=_." %%I in ('dir /b /a:-d /od "%INSTALLMOUNTDIR%\Windows\WinSxS\Manifests\*_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest"') do (set uupver=%%I.%%K&set uupmaj=%%I&set uupmin=%%K)
if %_fixEP% equ 0 for /f "tokens=5-7 delims=_." %%I in ('dir /b /a:-d /od "%INSTALLMOUNTDIR%\Windows\WinSxS\Manifests\*_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest"') do (set uupver=%%J.%%K&set uupmaj=%%J&set uupmin=%%K)
)
if not defined uupmaj goto :eof
if not defined uuplab (if defined isolab (set "uuplab=%isolab%") else (call :detectLab uuplab))
if %uupmaj%==18363 if /i "%uuplab:~0,4%"=="19h1" set uuplab=19h2%uuplab:~4%
if %uupmaj%==19041 if /i "%uuplab:~0,2%"=="vb" set uuplab=20h1%uuplab:~2%
if %uupmaj%==19042 if /i "%uuplab:~0,2%"=="vb" set uuplab=20h2%uuplab:~2%
if %uupmaj%==19043 if /i "%uuplab:~0,2%"=="vb" set uuplab=21h1%uuplab:~2%
if %uupmaj%==19044 if /i "%uuplab:~0,2%"=="vb" set uuplab=21h2%uuplab:~2%
if %uupmaj%==19045 if /i "%uuplab:~0,2%"=="vb" set uuplab=22h2%uuplab:~2%
if %uupmaj%==20349 if /i "%uuplab:~0,2%"=="fe" set uuplab=22h2%uuplab:~2%
if %uupmaj%==22631 if /i "%uuplab:~0,2%"=="ni" (echo %uuplab% | find /i "beta" %_Nul1% || set uuplab=23h2_ni%uuplab:~2%)
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
for /f "tokens=5 delims=.( " %%# in ('%_psc% "(gi '%INSTALLMOUNTDIR%\Windows\system32\ntoskrnl.exe').VersionInfo.FileVersion" %_Nul6%') do set "%1=%%#"
goto :eof

:datemum
set "mumfile=%SystemRoot%\temp\update.mum"
set "chkfile=!mumfile:\=\\!"
if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!chkfile!'" get LastModified /value') do set "mumdate=%%#"
if %_cwmi% equ 0 for /f %%# in ('%_psc% "([WMI]'CIM_DataFile.Name=''!chkfile!''').LastModified"') do set "mumdate=%%#"
del /f /q %SystemRoot%\temp\*.mum
set "%1=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
goto :eof

:boots
if %_stp% EQU 1 xcopy /CRUY "%BOOTMOUNTDIR%\sources" "!DVDDIR!\sources\" %_Nul3%
del /f /q "!DVDDIR!\sources\background.bmp" %_Nul3%
del /f /q "!DVDDIR!\sources\xmllite.dll" %_Nul3%
if exist "!DVDDIR!\setup.exe" copy /y "%BOOTMOUNTDIR%\setup.exe" "!DVDDIR!\" %_Nul3%
if not defined uupmaj goto :eof
if %_actEP% equ 0 goto :eof
if %isomaj% gtr %uupmaj% goto :eof
set isover=%uupver%
set isolab=%uuplab%
goto :eof

:remove
if exist "!DVDDIR!\" rmdir /s /q "!DVDDIR!\" %_Nul3%
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
takeown /f "%~1\Windows\WinSxS\Temp\PendingDeletes\*" /A %_Null%
icacls "%~1\Windows\WinSxS\Temp\PendingDeletes\*" /grant *S-1-5-32-544:F %_Null%
del /f /q "%~1\Windows\WinSxS\Temp\PendingDeletes\*" %_Null%
)
if exist "%~1\Windows\WinSxS\Temp\TransformerRollbackData\*" (
takeown /f "%~1\Windows\WinSxS\Temp\TransformerRollbackData\*" /R /A %_Null%
icacls "%~1\Windows\WinSxS\Temp\TransformerRollbackData\*" /grant *S-1-5-32-544:F /T %_Null%
del /s /f /q "%~1\Windows\WinSxS\Temp\TransformerRollbackData\*" %_Null%
)
if exist "%~1\Windows\inf\*.log" (
del /f /q "%~1\Windows\inf\*.log" %_Nul3%
)
for /f "tokens=* delims=" %%# in ('dir /b /ad "%~1\Windows\CbsTemp\" %_Nul6%') do rmdir /s /q "%~1\Windows\CbsTemp\%%#\" %_Nul3%
del /s /f /q "%~1\Windows\CbsTemp\*" %_Nul3%
for /f "tokens=* delims=" %%# in ('dir /b /ad "%~1\Windows\Temp\" %_Nul6%') do rmdir /s /q "%~1\Windows\Temp\%%#\" %_Nul3%
del /s /f /q "%~1\Windows\Temp\*" %_Nul3%
if exist "%~1\Windows\WinSxS\pending.xml" goto :eof
for /f "tokens=* delims=" %%# in ('dir /b /ad "%~1\Windows\WinSxS\Temp\InFlight\" %_Nul6%') do (
takeown /f "%~1\Windows\WinSxS\Temp\InFlight\%%#" /A %_Null%
icacls "%~1\Windows\WinSxS\Temp\InFlight\%%#" /grant:r "*S-1-5-32-544:(OI)(CI)(F)" %_Null%
rmdir /s /q "%~1\Windows\WinSxS\Temp\InFlight\%%#\" %_Nul3%
)
if exist "%~1\Windows\WinSxS\Temp\PendingRenames\*" (
takeown /f "%~1\Windows\WinSxS\Temp\PendingRenames\*" /A %_Nul3%
icacls "%~1\Windows\WinSxS\Temp\PendingRenames\*" /grant *S-1-5-32-544:F %_Nul3%
del /f /q "%~1\Windows\WinSxS\Temp\PendingRenames\*" %_Nul3%
)
goto :eof

:ISOmui
set "_eal=!EXTRACTDIR!\!LPARCH%1!\!LANGUAGE%1!"
set "_dsl=!DVDDIR!\sources\!LANGUAGE%1!"
set "_ssl=setup\sources\!LANGUAGE%1!"
"!_7z!" e ".\langs\!LPFILE%1!" -o"!_eal!" bootsect.exe.mui -r -aos %_Null%
"!_7z!" e ".\langs\!LPFILE%1!" -o"!_eal!" credits.rtf -r -aos %_Null%
"!_7z!" e ".\langs\!LPFILE%1!" -o"!_eal!" oobe_help_opt_in_details.rtf -r -aos %_Null%
if exist "!_eal!\bootsect.exe.mui" (xcopy "!_eal!\bootsect.exe.mui" "!DVDDIR!\boot\!LANGUAGE%1!\" /chryi %_Nul3%)
xcopy "!_eal!\!_ssl!\*" "!_dsl!\" /cheryi %_Nul3%
if exist "!_eal!\!_ssl!\cli\*.mui" xcopy "!_eal!\!_ssl!\cli\*.mui" "!_dsl!\" /chryi %_Nul3%
if %_SrvEdt% EQU 1 if exist "!_eal!\!_ssl!\svr\*.mui" xcopy "!_eal!\!_ssl!\svr\*.mui" "!_dsl!\" /chryi %_Nul3%
if %_AszEdt% EQU 1 if exist "!_eal!\!_ssl!\asz\*.mui" xcopy "!_eal!\!_ssl!\asz\*.mui" "!_dsl!\" /chryi %_Nul3%
rmdir /s /q "!_dsl!\dlmanifests" %_Nul3%
rmdir /s /q "!_dsl!\etwproviders" %_Nul3%
rmdir /s /q "!_dsl!\replacementmanifests" %_Nul3%
rmdir /s /q "!_dsl!\cli" %_Nul3%
rmdir /s /q "!_dsl!\tdb" %_Nul3%
rmdir /s /q "!_dsl!\asz" %_Nul3%
rmdir /s /q "!_dsl!\svr" %_Nul3%
mkdir "!DVDDIR!\sources\dlmanifests\!LANGUAGE%1!"
mkdir "!DVDDIR!\sources\replacementmanifests\!LANGUAGE%1!"
xcopy "!_eal!\!_ssl!\dlmanifests\microsoft-windows-iasserver-migplugin\*" "!DVDDIR!\sources\dlmanifests\microsoft-windows-iasserver-migplugin\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!_eal!\!_ssl!\dlmanifests\microsoft-windows-shmig-dl\*" "!DVDDIR!\sources\dlmanifests\microsoft-windows-shmig-dl\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!_eal!\!_ssl!\dlmanifests\microsoft-windows-storagemigration\*" "!DVDDIR!\sources\dlmanifests\microsoft-windows-storagemigration\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!_eal!\!_ssl!\dlmanifests\microsoft-windows-sxs\*" "!DVDDIR!\sources\dlmanifests\microsoft-windows-sxs\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!_eal!\!_ssl!\replacementmanifests\microsoft-windows-offlinefiles-core\*" "!DVDDIR!\sources\replacementmanifests\microsoft-windows-offlinefiles-core\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!_eal!\!_ssl!\replacementmanifests\microsoft-windows-shmig\*" "!DVDDIR!\sources\replacementmanifests\microsoft-windows-shmig\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!_eal!\!_ssl!\replacementmanifests\microsoft-windows-storagemigration\*" "!DVDDIR!\sources\replacementmanifests\microsoft-windows-storagemigration\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!_eal!\!_ssl!\replacementmanifests\microsoft-windows-sxs\*" "!DVDDIR!\sources\replacementmanifests\microsoft-windows-sxs\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!_eal!\!_ssl!\etwproviders\*" "!DVDDIR!\sources\etwproviders\!LANGUAGE%1!\" /chryi %_Nul3%
xcopy "!_eal!\!_ssl!\etwproviders\*" "!DVDDIR!\support\logging\!LANGUAGE%1!\" /chryi %_Nul3%
copy /y "!_eal!\credits.rtf" "!_dsl!" %_Nul3%
copy /y "!_eal!\oobe_help_opt_in_details.rtf" "!_dsl!" %_Nul3%
copy /y "!_eal!\vofflps.rtf" "!_dsl!" %_Nul3%
copy /y "!_eal!\vofflps.rtf" "!_dsl!\privacy.rtf" %_Nul3%
attrib -A -S -H -I "!_dsl!" /S /D %_Nul3%
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
    copy /y "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\vofflps.rtf" "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!" %_Nul3%
    copy /y "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\reagent.adml" "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!" %_Nul3%
    for %%G in %bootmui% do (
    copy /y "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\%%G.mui" "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!" %_Nul3%
    )
    attrib -A -S -H -I "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!" /S /D %_Nul1%
    if not %WINPE%==1 call :EAfonts %%j
  )
)
if %_build% GEQ 22557 call :MUIman
goto :eof

:MUIman
for /L %%j in (1,1,%LANGUAGES%) do (
  if /i !LPARCH%%j!==!BOOTARCH! if not exist "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!\w32uires.dll.mui" (
    if exist "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\cli\*.mui" xcopy "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\cli\*.mui" "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!\" /chryi %_Nul3%
    if %_SrvEdt% EQU 1 if exist "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\svr\*.mui" xcopy "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\svr\*.mui" "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!\" /chryi %_Nul3%
    if %_AszEdt% EQU 1 if exist "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\asz\*.mui" xcopy "!EXTRACTDIR!\!LPARCH%%j!\!LANGUAGE%%j!\setup\sources\!LANGUAGE%%j!\asz\*.mui" "%BOOTMOUNTDIR%\sources\!LANGUAGE%%j!\" /chryi %_Nul3%
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
if not exist "!_fntb!\jpn_boot.ttf" (
icacls "!_fntb!" /save "!TEMPDIR!\AclFile" %_Nul3%&takeown /f "!_fntb!" %_Nul3%&icacls "!_fntb!" /grant *S-1-5-32-544:F %_Nul3%
copy /y "!_eal!\jpn_boot.ttf" "!_fntb!" %_Nul3%&copy /y "!_eal!\meiryo_boot.ttf" "!_fntb!" %_Nul3%&copy /y "!_eal!\meiryon_boot.ttf" "!_fntb!" %_Nul3%
icacls "!_fntb!" /setowner "NT Service\TrustedInstaller" %_Nul3%&icacls "%BOOTMOUNTDIR%\Windows\Boot" /restore "!TEMPDIR!\AclFile" %_Nul3%
)
reg.exe load HKLM\OFFLINE "%BOOTMOUNTDIR%\Windows\System32\config\SOFTWARE" %_Nul1%&reg.exe import "!WORKDIR!\dism\EA\ja-jp.reg" %_Nul1%&reg.exe unload HKLM\OFFLINE %_Nul1%
copy /y "!_eal!\meiryo.ttc" "!_fntw!" %_Nul3%&copy /y "!_eal!\msgothic.ttc" "!_fntw!" %_Nul3%
goto :eof
)
if /i !LANGUAGE%1!==ko-kr (
if not exist "!_fntb!\kor_boot.ttf" (
icacls "!_fntb!" /save "!TEMPDIR!\AclFile" %_Nul3%&takeown /f "!_fntb!" %_Nul3%&icacls "!_fntb!" /grant *S-1-5-32-544:F %_Nul3%
copy /y "!_eal!\kor_boot.ttf" "!_fntb!" %_Nul3%&copy /y "!_eal!\malgunn_boot.ttf" "!_fntb!" %_Nul3%&copy /y "!_eal!\malgun_boot.ttf" "!_fntb!" %_Nul3%
icacls "!_fntb!" /setowner "NT Service\TrustedInstaller" %_Nul3%&icacls "%BOOTMOUNTDIR%\Windows\Boot" /restore "!TEMPDIR!\AclFile" %_Nul3%
)
reg.exe load HKLM\OFFLINE "%BOOTMOUNTDIR%\Windows\System32\config\SOFTWARE" %_Nul1%&reg.exe import "!WORKDIR!\dism\EA\ko-kr.reg" %_Nul1%&reg.exe unload HKLM\OFFLINE %_Nul1%
copy /y "!_eal!\malgun.ttf" "!_fntw!" %_Nul3%&copy /y "!_eal!\gulim.ttc" "!_fntw!" %_Nul3%
goto :eof
)
if /i !LANGUAGE%1!==zh-cn (
if not exist "!_fntb!\chs_boot.ttf" (
icacls "!_fntb!" /save "!TEMPDIR!\AclFile" %_Nul3%&takeown /f "!_fntb!" %_Nul3%&icacls "!_fntb!" /grant *S-1-5-32-544:F %_Nul3%
copy /y "!_eal!\chs_boot.ttf" "!_fntb!" %_Nul3%&copy /y "!_eal!\msyhn_boot.ttf" "!_fntb!" %_Nul3%&copy /y "!_eal!\msyh_boot.ttf" "!_fntb!" %_Nul3%
icacls "!_fntb!" /setowner "NT Service\TrustedInstaller" %_Nul3%&icacls "%BOOTMOUNTDIR%\Windows\Boot" /restore "!TEMPDIR!\AclFile" %_Nul3%
)
reg.exe load HKLM\OFFLINE "%BOOTMOUNTDIR%\Windows\System32\config\SOFTWARE" %_Nul1%&reg.exe import "!WORKDIR!\dism\EA\zh-cn.reg" %_Nul1%&reg.exe unload HKLM\OFFLINE %_Nul1%
copy /y "!_eal!\msyh.ttc" "!_fntw!" %_Nul3%&copy /y "!_eal!\msyhl.ttc" "!_fntw!" %_Nul3%&copy /y "!_eal!\mingliub.ttc" "!_fntw!" %_Nul3%&copy /y "!_eal!\simsun.ttc" "!_fntw!" %_Nul3%
goto :eof
)
if /i !LANGUAGE%1!==zh-hk (
if not exist "!_fntb!\cht_boot.ttf" (
icacls "!_fntb!" /save "!TEMPDIR!\AclFile" %_Nul3%&takeown /f "!_fntb!" %_Nul3%&icacls "!_fntb!" /grant *S-1-5-32-544:F %_Nul3%
copy /y "!_eal!\cht_boot.ttf" "!_fntb!" %_Nul3%&copy /y "!_eal!\msjhn_boot.ttf" "!_fntb!" %_Nul3%&copy /y "!_eal!\msjh_boot.ttf" "!_fntb!" %_Nul3%
icacls "!_fntb!" /setowner "NT Service\TrustedInstaller" %_Nul3%&icacls "%BOOTMOUNTDIR%\Windows\Boot" /restore "!TEMPDIR!\AclFile" %_Nul3%
)
reg.exe load HKLM\OFFLINE "%BOOTMOUNTDIR%\Windows\System32\config\SOFTWARE" %_Nul1%&reg.exe import "!WORKDIR!\dism\EA\zh-hk.reg" %_Nul1%&reg.exe unload HKLM\OFFLINE %_Nul1%
copy /y "!_eal!\msjh.ttc" "!_fntw!" %_Nul3%&copy /y "!_eal!\mingliub.ttc" "!_fntw!" %_Nul3%&copy /y "!_eal!\simsun.ttc" "!_fntw!" %_Nul3%
goto :eof
)
if /i !LANGUAGE%1!==zh-tw (
if not exist "!_fntb!\cht_boot.ttf" (
icacls "!_fntb!" /save "!TEMPDIR!\AclFile" %_Nul3%&takeown /f "!_fntb!" %_Nul3%&icacls "!_fntb!" /grant *S-1-5-32-544:F %_Nul3%
copy /y "!_eal!\cht_boot.ttf" "!_fntb!" %_Nul3%&copy /y "!_eal!\msjhn_boot.ttf" "!_fntb!" %_Nul3%&copy /y "!_eal!\msjh_boot.ttf" "!_fntb!" %_Nul3%
icacls "!_fntb!" /setowner "NT Service\TrustedInstaller" %_Nul3%&icacls "%BOOTMOUNTDIR%\Windows\Boot" /restore "!TEMPDIR!\AclFile" %_Nul3%
)
reg.exe load HKLM\OFFLINE "%BOOTMOUNTDIR%\Windows\System32\config\SOFTWARE" %_Nul1%&reg.exe import "!WORKDIR!\dism\EA\zh-tw.reg" %_Nul1%&reg.exe unload HKLM\OFFLINE %_Nul1%
copy /y "!_eal!\msjh.ttc" "!_fntw!" %_Nul3%&copy /y "!_eal!\mingliub.ttc" "!_fntw!" %_Nul3%&copy /y "!_eal!\simsun.ttc" "!_fntw!" %_Nul3%
goto :eof
)
goto :eof

:SbS
set savr=1
if %_build% GEQ 18362 set savr=3
reg.exe load HKLM\TEMPWIM "%~1\Windows\System32\Config\SOFTWARE" %_Nul3%
reg.exe add HKLM\TEMPWIM\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v DisableComponentBackups /t REG_DWORD /d 1 /f %_Nul3%
reg.exe add HKLM\TEMPWIM\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d %savr% /f %_Nul3%
reg.exe unload HKLM\TEMPWIM %_Nul3%
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
set errMOUNT=1
goto :END

:E_UNMOUNT
set MESSAGE=ERROR: Could not unmount WIM image
set errMOUNT=1
goto :END

:E_ADMIN
set MESSAGE=ERROR: Run the script as administrator
goto :END

:E_PWS
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
if exist "Updates\msucab.txt" (
  for /f %%# in (Updates\msucab.txt) do (
  if exist "Updates\*%%~#*x86*.msu" if exist "Updates\*%%~#*x86*.cab" del /f /q "Updates\*%%~#*x86*.cab" %_Nul3%
  if exist "Updates\*%%~#*x64*.msu" if exist "Updates\*%%~#*x64*.cab" del /f /q "Updates\*%%~#*x64*.cab" %_Nul3%
  )
  del /f /q Updates\msucab.txt
)
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
