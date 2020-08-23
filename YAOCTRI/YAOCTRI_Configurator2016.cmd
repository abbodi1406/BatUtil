@setlocal DisableDelayedExpansion
@echo off
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "_err===== ERROR ===="
set "xOS=x64"
set "_ComSpec=%SystemRoot%\System32\cmd.exe"
set "_Common=%CommonProgramFiles%"
set "_Program=%ProgramFiles%"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if defined PROCESSOR_ARCHITEW6432 (
  set "_ComSpec=%SystemRoot%\Sysnative\cmd.exe"
  set "_Common=%CommonProgramW6432%"
  set "_Program=%ProgramW6432%"
  ) else (
  set "xOS=x86"
  )
)
set "_target=%_Common%\Microsoft Shared\ClickToRun"
set "_file=%_target%\OfficeClickToRun.exe"
set "_temp=%temp%"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
reg query HKU\S-1-5-19 >nul 2>&1 || goto :E_Admin
set "_ini=%~dp0"
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%SystemDrive%\Users\Public\Desktop\desktop.ini" set "_dsk=%SystemDrive%\Users\Public\Desktop"
setlocal EnableDelayedExpansion
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
if %winbuild% lss 7601 goto :E_Win
title Office Click-to-Run Configurator - Volume
set lpid=(ar-SA,bg-BG,cs-CZ,da-DK,de-DE,el-GR,en-US,es-ES,et-EE,fi-FI,fr-FR,he-IL,hr-HR,hu-HU,it-IT,ja-JP,ko-KR,lt-LT,lv-LV,nb-NO,nl-NL,pl-PL,pt-BR,pt-PT,ro-RO,ru-RU,sk-SK,sl-SI,sr-Latn-RS,sv-SE,th-TH,tr-TR,uk-UA,zh-CN,zh-TW,hi-IN,id-ID,kk-KZ,MS-MY,vi-VN)
set lcid=(1025,1026,1029,1030,1031,1032,1033,3082,1061,1035,1036,1037,1050,1038,1040,1041,1042,1063,1062,1044,1043,1045,1046,2070,1048,1049,1051,1060,9242,1053,1054,1055,1058,2052,1028,1081,1057,1087,1086,1066)
set bits=(32,64)
set /a cc=0
for %%# in %lpid% do (
set /a cc+=1
set lpid!cc!=%%#
)
set /a cc=0
for %%# in %lcid% do (
set /a cc+=1
set lcid!cc!=%%#
)
set /a cc=0
for %%# in (
5440fd1f-7ecb-4221-8110-145efaa6372f
64256afe-f5d9-4f86-8936-8840a6a4f5be
492350f6-3a01-4f97-b9c0-c7c6ddf67d60
55336b82-a18d-4dd6-b5f6-9e5095c314a6
b8f9b850-328d-4355-9145-c59439a0c4cf
7ffbc6bf-bc32-4f92-8982-f9dd17fd3114
f2e724c1-748f-4b47-8fb8-8e0d210e9208
1d2d2ea6-1680-4c56-ac58-a441c8c24ff9
ea4a4090-de26-49d7-93c1-91bff9e53fc3
b61285dd-d9f7-41f2-9757-8f61cba4e9c8
) do (
set /a cc+=1
set ffn!cc!=%%#
)
set /a cc=0
for %%# in (
InsiderFast
MonthlyPreview
Monthly
MonthlyEnterprise
SemiAnnualPreview
SemiAnnual
Perpetual2016
MicrosoftLTSC
DogfoodDevMain
MicrosoftElite
) do (
set /a cc+=1
set chn!cc!=%%#
)
set "line=============================================================="
if exist "!_work!\Office\Data\*.cab" (
for /f %%# in ('dir /b /ad "!_work!\Office\Data\" 2^>nul') do if exist "!_work!\Office\Data\%%#\stream*.dat" (
  set "CTRsource=%~dp0"
  )
)
if defined CTRsource goto :check
if exist "!_work!\Data\*.cab" (
for /f %%# in ('dir /b /ad "!_work!\Data\" 2^>nul') do if exist "!_work!\Data\%%#\stream*.dat" (
  for /D %%G in ("!_work!\..\") do set "CTRsource=%%~dpG"
  )
)
if defined CTRsource goto :check
for %%# in (C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
if exist "%%#:\Office\Data\*.cab" set "CTRsource=%%#:\"
)
if defined CTRsource goto :check

:prompt
cls
set CTRsource=
echo %line%
echo Enter the directory / drive that contain "Office" folder
echo ^(do not enter the path for Office folder itself^)
echo %line%
echo.
set /p CTRsource=
if not defined CTRsource goto :eof
set "CTRsource=%CTRsource:"=%"
if not exist "!CTRsource!\Office\Data\*.cab" (
echo %_err%
echo Specified path is not a valid Office C2R source
echo.
echo Press any key to continue...
pause >nul
goto :prompt
)

:check
if "!CTRsource:~-1!"=="\" set "CTRsource=!CTRsource:~0,-1!"
cls
echo %line%
echo Source  : "!CTRsource!"
echo %line%
echo.
copy /y nul "!CTRsource!\Office\#.rw" 1>nul 2>nul && (
set CTRtype=Local
if exist "!CTRsource!\Office\#.rw" del /f /q "!CTRsource!\Office\#.rw"
) || (
set CTRtype=DVD
)
if "!CTRsource:~0,2!"=="\\" set CTRtype=UNC
set /a vvv=0
for /f %%# in ('dir /b /ad "!CTRsource!\Office\Data\" 2^>nul') do if exist "!CTRsource!\Office\Data\%%#\stream*.dat" if exist "!CTRsource!\Office\Data\*%%#.cab" (
set /a vvv+=1
set CTRver!vvv!=%%#
set CTRver=%%#
)
if %vvv% equ 0 (
echo %_err%
echo Specified path is not a valid Office C2R source
echo.
echo Press any key to continue...
pause >nul
goto :prompt
)
if %vvv% gtr 9 (
echo.
echo %_err%
echo More than 9 versions detected in Office C2R source
echo remove some of them and try again
goto :TheEnd
)
if %vvv% equ 1 goto :MenuVersion2

:MenuVersion
cls
echo %line%
echo Source  : "!CTRsource!"
echo %line%
echo.
set inpt=
set errortmp=
for /l %%J in (1,1,%vvv%) do (
echo. %%J. !CTRver%%J!
)
echo.
echo %line%
choice /c 123456789X /n /m "Choose a version to proceed, or press X to exit: "
set errortmp=%errorlevel%
if %errortmp%==10 goto :eof
if %errortmp%==9 if %vvv%==9 (set inpt=9&goto :MenuVersion2)
if %errortmp%==8 if %vvv%==8 (set inpt=8&goto :MenuVersion2)
if %errortmp%==7 if %vvv%==7 (set inpt=7&goto :MenuVersion2)
if %errortmp%==6 if %vvv%==6 (set inpt=6&goto :MenuVersion2)
if %errortmp%==5 if %vvv%==5 (set inpt=5&goto :MenuVersion2)
if %errortmp%==4 if %vvv%==4 (set inpt=4&goto :MenuVersion2)
if %errortmp%==3 if %vvv%==3 (set inpt=3&goto :MenuVersion2)
if %errortmp%==2 (set inpt=2&goto :MenuVersion2)
if %errortmp%==1 (set inpt=1&goto :MenuVersion2)
goto :MenuVersion

:MenuVersion2
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver%
echo %line%
echo.
for /f "tokens=3 delims=." %%# in ('echo %CTRver%') do set verchk=%%#
if %verchk% lss 9029 goto :E_VER
if %vvv% gtr 1 set "CTRver=!CTRver%inpt%!"
for %%# in %bits% do (
if exist "!CTRsource!\Office\Data\v%%#*.cab" set vcab%%#=1
)
if exist "!CTRsource!\Office\Data\%CTRver%\stream.x86.x-none.dat" set stream32=1
if exist "!CTRsource!\Office\Data\%CTRver%\stream.x64.x-none.dat" set stream64=1
for %%# in %bits% do (
  if exist "!CTRsource!\Office\Data\%CTRver%\i%%#0.cab" set icab%%#=1
  if exist "!CTRsource!\Office\Data\%CTRver%\s%%#0.cab" set scab%%#=1
)
for /l %%J in (1,1,40) do (
  if exist "!CTRsource!\Office\Data\%CTRver%\i32!lcid%%J!.cab" (set icablp32=1&set icablp32!lpid%%J!=1)
  if exist "!CTRsource!\Office\Data\%CTRver%\i64!lcid%%J!.cab" (set icablp64=1&set icablp64!lpid%%J!=1)
  if exist "!CTRsource!\Office\Data\%CTRver%\s32!lcid%%J!.cab" (set scablp32=1&set scablp32!lpid%%J!=1)
  if exist "!CTRsource!\Office\Data\%CTRver%\s64!lcid%%J!.cab" (set scablp64=1&set scablp64!lpid%%J!=1)
  if exist "!CTRsource!\Office\Data\%CTRver%\stream.x86.!lpid%%J!.dat" (set streamlp32=1&set streamlp32!lpid%%J!=1)
  if exist "!CTRsource!\Office\Data\%CTRver%\stream.x64.!lpid%%J!.dat" (set streamlp64=1&set streamlp64!lpid%%J!=1)
)

for %%# in %bits% do (if "!vcab%%#!"=="1" if "!icab%%#!"=="1" if "!scab%%#!"=="1" if "!stream%%#!"=="1" set main%%#=1)
for %%# in %bits% do (if "!icablp%%#!"=="1" if "!scablp%%#!"=="1" if "!streamlp%%#!"=="1" set lang%%#=1)
set win32=0
set win64=0
set wow64=0
if "%main32%"=="1" if "%lang32%"=="1" set off32=1
if "%main64%"=="1" if "%lang64%"=="1" set off64=1
if "%xOS%"=="x86" if "%off32%"=="1" set "win32=1"
if "%xOS%"=="x64" if "%off64%"=="1" set "win64=1"
if "%xOS%"=="x64" if "%off32%"=="1" if "%icab64%"=="1" if "%icablp64%"=="1" set "wow64=1"

if "%xOS%"=="x86" if "%win32%"=="0" (
  echo %_err%
  echo Could not detect compatible Office 32-bit for current x86 system.
  goto :TheEnd
)
if "%xOS%"=="x64" if "%win64%"=="0" if "%wow64%"=="0" (
  echo %_err%
  echo Could not detect compatible Office 64-bit/32-bit for current x64 system.
  goto :TheEnd
)
if "%win32%"=="1" (set "CTRarc=x86"&goto :MenuArch2)
if "%win64%"=="1" if "%wow64%"=="0" (set "CTRarc=x64"&goto :MenuArch2)
if "%win64%"=="0" if "%wow64%"=="1" (set "CTRarc=x86"&goto :MenuArch2)

:MenuArch
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver%
echo %line%
echo.
echo. 1. Office 64-bit (x64)
echo. 2. Office 32-bit (x86)
echo.
echo %line%
choice /c 12X /n /m "Choose an architecture to proceed, or press X to exit: "
if errorlevel 3 goto :eof
if errorlevel 2 (set "win64=0"&set "CTRarc=x86"&goto :MenuArch2)
if errorlevel 1 (set "wow64=0"&set "CTRarc=x64"&goto :MenuArch2)
goto :MenuArch

:MenuArch2
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc%
echo %line%
echo.
set /a int=0
for /l %%J in (1,1,40) do (
call :checklp !lpid%%J! !lcid%%J!
)
if %int% gtr 9 (
echo.
echo %_err%
echo More than 9 languages detected in Office C2R source
echo remove some of them and try again
goto :TheEnd
)
if %int% equ 1 goto :MenuLang2
goto :MenuLang

:checklp
if "%win64%"=="0" if "!icablp32%1!"=="1" if "!scablp32%1!"=="1" if "!streamlp32%1!"=="1" (
set /a int+=1
set zlng!int!=%1
set zcul!int!=%2
set lng32=%1
set cul32=%2
)
if "%win64%"=="1" if "!icablp64%1!"=="1" if "!scablp64%1!"=="1" if "!streamlp64%1!"=="1" (
set /a int+=1
set zlng!int!=%1
set zcul!int!=%2
set lng64=%1
set cul64=%2
)
exit /b

:MenuLang
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc%
echo %line%
echo.
set inpt=
set errortmp=
echo. 0. All
for /l %%J in (1,1,%int%) do (
echo. %%J. !zlng%%J!
)
echo.
echo %line%
choice /c 1234567890X /n /m "Choose language(s) to proceed, or press X to exit: "
set errortmp=%errorlevel%
if %errortmp%==11 goto :eof
if %errortmp%==10 goto :MenuLangM
if %errortmp%==9 if %int%==9 (set inpt=9&goto :MenuLang2)
if %errortmp%==8 if %int%==8 (set inpt=8&goto :MenuLang2)
if %errortmp%==7 if %int%==7 (set inpt=7&goto :MenuLang2)
if %errortmp%==6 if %int%==6 (set inpt=6&goto :MenuLang2)
if %errortmp%==5 if %int%==5 (set inpt=5&goto :MenuLang2)
if %errortmp%==4 if %int%==4 (set inpt=4&goto :MenuLang2)
if %errortmp%==3 if %int%==3 (set inpt=3&goto :MenuLang2)
if %errortmp%==2 (set inpt=2&goto :MenuLang2)
if %errortmp%==1 (set inpt=1&goto :MenuLang2)
goto :MenuLang

:MenuLang2
cls
if %int% gtr 1 (
set "lng32=!zlng%inpt%!"
set "lng64=!zlng%inpt%!"
set "cul32=!zcul%inpt%!"
set "cul64=!zcul%inpt%!"
)
if %win32%==1 (
set CTRlng=%lng32%&set CTRcul=%cul32%&set CTRvcab=v32_%CTRver%.cab&set CTRicab=i320.cab&set CTRicabr=i32%cul32%.cab
)
if %wow64%==1 (
set CTRlng=%lng32%&set CTRcul=%cul32%&set CTRvcab=v32_%CTRver%.cab&set CTRicab=i640.cab&set CTRicabr=i64%cul32%.cab
)
if %win64%==1 (
set CTRlng=%lng64%&set CTRcul=%cul64%&set CTRvcab=v64_%CTRver%.cab&set CTRicab=i640.cab&set CTRicabr=i64%cul64%.cab
)
set CTRstp=%CTRlng%
goto :MenuInitial

:MenuLangM
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc%
echo %line%
echo.
set inpt=
set errortmp=
for /l %%J in (1,1,%int%) do (
echo. %%J. !zlng%%J!
)
echo.
echo %line%
choice /c 123456789X /n /m "Choose primary language to proceed, or press X to exit: "
set errortmp=%errorlevel%
if %errortmp%==10 goto :eof
if %errortmp%==9 if %int%==9 (set inpt=9&goto :MenuLangM2)
if %errortmp%==8 if %int%==8 (set inpt=8&goto :MenuLangM2)
if %errortmp%==7 if %int%==7 (set inpt=7&goto :MenuLangM2)
if %errortmp%==6 if %int%==6 (set inpt=6&goto :MenuLangM2)
if %errortmp%==5 if %int%==5 (set inpt=5&goto :MenuLangM2)
if %errortmp%==4 if %int%==4 (set inpt=4&goto :MenuLangM2)
if %errortmp%==3 if %int%==3 (set inpt=3&goto :MenuLangM2)
if %errortmp%==2 (set inpt=2&goto :MenuLangM2)
if %errortmp%==1 (set inpt=1&goto :MenuLangM2)
goto :MenuLangM

:MenuLangM2
cls
for /l %%J in (1,1,%int%) do (
if defined CTRlng (set "CTRlng=!CTRlng!_!zlng%%J!") else (set "CTRlng=!zlng%%J!")
if defined CTRcul (set "CTRcul=!CTRcul!,!zcul%%J!") else (set "CTRcul=!zcul%%J!")
)
set CTRstp=!zlng%inpt%!
set CTRprm=!zcul%inpt%!
if %win32%==1 (
set CTRvcab=v32_%CTRver%.cab&set CTRicab=i320.cab&set CTRicabr=i32%CTRprm%.cab
)
if %wow64%==1 (
set CTRvcab=v32_%CTRver%.cab&set CTRicab=i640.cab&set CTRicabr=i64%CTRprm%.cab
)
if %win64%==1 (
set CTRvcab=v64_%CTRver%.cab&set CTRicab=i640.cab&set CTRicabr=i64%CTRprm%.cab
)

:MenuInitial
set _O2016=1
set _Access=ON
set _Excel=ON
set _Lync=ON
set _OneDrive=OFF
set _OneNote=ON
set _Outlook=ON
set _PowerPoint=ON
set _Publisher=ON
set _SkypeForBusiness=ON
set _Word=ON
set _Project=ON
set _Visio=ON
set _Mondo=OFF
set _O365PP=ON
set _Pro=OFF
set _Std=OFF
set _PrjPro=OFF
set _PrjStd=OFF
set _VisPro=OFF
set _VisStd=OFF
set _updt=True
set _eula=True
set _icon=False
set _shut=True
set _disp=True
set _actv=False
set _tele=True
set _Teams=OFF
if %verchk:~0,2% equ 11 if %verchk% lss 11328 set _Teams=0
if %verchk:~0,2% equ 10 if %verchk% lss 10336 set _Teams=0
if %_O2016%==0 goto :MenuSuite
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
echo %line%
echo.
echo. 1. Install Product Suite
echo. 2. Install Single Apps
echo.
echo %line%
choice /c 12X /n /m "Choose a menu option to proceed, or press X to exit: "
if errorlevel 3 goto :eof
if errorlevel 2 goto :MenuApps
if errorlevel 1 goto :MenuSuite
goto :MenuInitial

:MenuSuite
if %_O365PP%==OFF if %_Pro%==OFF if %_Std%==OFF if %_Mondo%==OFF if %_PrjPro%==OFF if %_PrjStd%==OFF if %_VisPro%==OFF if %_VisStd%==OFF set _O365PP=ON
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
echo %line%
echo Select Products to Install:
echo.
echo. 1. Microsoft 365 Enterprise : %_O365PP%
echo. 2. Office Mondo 2016        : %_Mondo%
if %_O2016%==1 (
echo. 3. Office ProPlus 2016      : %_Pro%
echo. 4. Office Standard 2016     : %_Std%
echo.
echo. 5. Project Pro 2016         : %_PrjPro%
echo. 6. Project Standard 2016    : %_PrjStd%
echo. 7. Visio Pro 2016           : %_VisPro%
echo. 8. Visio Standard 2016      : %_VisStd%
)
echo %line%
choice /c 1234567890X /n /m "Change a menu option, press 0 to proceed, 9 to go back, or X to exit: "
if errorlevel 11 goto :eof
if errorlevel 10 goto :MenuSuite2
if errorlevel 9 goto :MenuInitial
if errorlevel 8 (if %_O2016%==1 (if %_VisStd%==ON (set _VisStd=OFF) else if %_Mondo%==OFF (set _VisPro=OFF&set _VisStd=ON)))&goto :MenuSuite
if errorlevel 7 (if %_O2016%==1 (if %_VisPro%==ON (set _VisPro=OFF) else if %_Mondo%==OFF (set _VisPro=ON&set _VisStd=OFF)))&goto :MenuSuite
if errorlevel 6 (if %_O2016%==1 (if %_PrjStd%==ON (set _PrjStd=OFF) else if %_Mondo%==OFF (set _PrjPro=OFF&set _PrjStd=ON)))&goto :MenuSuite
if errorlevel 5 (if %_O2016%==1 (if %_PrjPro%==ON (set _PrjPro=OFF) else if %_Mondo%==OFF (set _PrjPro=ON&set _PrjStd=OFF)))&goto :MenuSuite
if errorlevel 4 (if %_O2016%==1 (if %_Std%==ON (set _Std=OFF) else (set _Std=ON&set _Mondo=OFF&set _O365PP=OFF&set _Pro=OFF)))&goto :MenuSuite
if errorlevel 3 (if %_O2016%==1 (if %_Pro%==ON (set _Pro=OFF) else (set _Pro=ON&set _Mondo=OFF&set _O365PP=OFF&set _Std=OFF)))&goto :MenuSuite
if errorlevel 2 (if %_Mondo%==ON (set _Mondo=OFF) else (set _Mondo=ON&set _O365PP=OFF&set _Pro=OFF&set _Std=OFF&set _PrjPro=OFF&set _PrjStd=OFF&set _VisPro=OFF&set _VisStd=OFF))&goto :MenuSuite
if errorlevel 1 (if %_O365PP%==ON (set _O365PP=OFF) else (set _O365PP=ON&set _Mondo=OFF&set _Pro=OFF&set _Std=OFF))&goto :MenuSuite
goto :MenuSuite

:MenuApps
if %_Access%==OFF if %_Excel%==OFF if %_OneNote%==OFF if %_Outlook%==OFF if %_PowerPoint%==OFF if %_Publisher%==OFF if %_SkypeForBusiness%==OFF if %_Word%==OFF if %_PrjPro%==OFF if %_PrjStd%==OFF if %_VisPro%==OFF if %_VisStd%==OFF set _Word=ON
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
echo %line%
echo Select Apps to install:
echo.
echo. A. Access 2016           : %_Access%
echo. E. Excel 2016            : %_Excel%
echo. N. OneNote 2016          : %_OneNote%
echo. O. Outlook 2016          : %_Outlook%
echo. P. PowerPoint 2016       : %_PowerPoint%
echo. R. Publisher 2016        : %_Publisher%
echo. S. SkypeForBusiness 2016 : %_SkypeForBusiness%
echo. W. Word 2016             : %_Word%
echo.
echo. 5. Project Pro 2016      : %_PrjPro%
echo. 6. Project Standard 2016 : %_PrjStd%
echo. 7. Visio Pro 2016        : %_VisPro%
echo. 8. Visio Standard 2016   : %_VisStd%
echo.
echo. D. OneDrive Desktop      : %_OneDrive%
if not %_Teams%==0 echo. T. Microsoft Teams       : %_Teams%
echo %line%
choice /c AENOPRSWD567890TX /n /m "Change a menu option, press 0 to proceed, 9 to go back, or X to exit: "
if errorlevel 17 goto :eof
if errorlevel 16 (if not %_Teams%==0 (if %_Teams%==ON (set _Teams=OFF) else (set _Teams=ON)))&goto :MenuApps
if errorlevel 15 goto :MenuApps2
if errorlevel 14 goto :MenuInitial
if errorlevel 13 (if %_VisStd%==ON (set _VisStd=OFF) else (set _VisPro=OFF&set _VisStd=ON))&goto :MenuApps
if errorlevel 12 (if %_VisPro%==ON (set _VisPro=OFF) else (set _VisPro=ON&set _VisStd=OFF))&goto :MenuApps
if errorlevel 11 (if %_PrjStd%==ON (set _PrjStd=OFF) else (set _PrjPro=OFF&set _PrjStd=ON))&goto :MenuApps
if errorlevel 10 (if %_PrjPro%==ON (set _PrjPro=OFF) else (set _PrjPro=ON&set _PrjStd=OFF))&goto :MenuApps
if errorlevel 9 (if %_OneDrive%==ON (set _OneDrive=OFF) else (set _OneDrive=ON))&goto :MenuApps
if errorlevel 8 (if %_Word%==ON (set _Word=OFF) else (set _Word=ON))&goto :MenuApps
if errorlevel 7 (if %_SkypeForBusiness%==ON (set _SkypeForBusiness=OFF) else (set _SkypeForBusiness=ON))&goto :MenuApps
if errorlevel 6 (if %_Publisher%==ON (set _Publisher=OFF) else (set _Publisher=ON))&goto :MenuApps
if errorlevel 5 (if %_PowerPoint%==ON (set _PowerPoint=OFF) else (set _PowerPoint=ON))&goto :MenuApps
if errorlevel 4 (if %_Outlook%==ON (set _Outlook=OFF) else (set _Outlook=ON))&goto :MenuApps
if errorlevel 3 (if %_OneNote%==ON (set _OneNote=OFF) else (set _OneNote=ON))&goto :MenuApps
if errorlevel 2 (if %_Excel%==ON (set _Excel=OFF) else (set _Excel=ON))&goto :MenuApps
if errorlevel 1 (if %_Access%==ON (set _Access=OFF) else (set _Access=ON))&goto :MenuApps
goto :MenuApps

:MenuSuite2
set "_retsuite="
set "_suite="
set "_suit2="
for /l %%J in (1,1,15) do (
set "_sku%%J="
)
set "_pkey0="
for /l %%J in (1,1,15) do (
set "_pkey%%J="
)
set /a cc=0
set /a kk=0
if %_O365PP%==ON (
set _suite=O365ProPlusRetail&set _suit2=MondoVolume
set _pkey0=HFTND-W9MK4-8B7MJ-B6C4G-XQBR2
) else if %_Pro%==ON (
set _suite=ProPlusVolume
set _pkey0=XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99
) else if %_Std%==ON (
set _suite=StandardVolume
set _pkey0=JNRGM-WHDWX-FJJG3-K47QV-DRTFM
) else if %_Mondo%==ON (
set _suite=MondoVolume
set _pkey0=HFTND-W9MK4-8B7MJ-B6C4G-XQBR2
)
if %_PrjPro%==ON (
set /a cc+=1
set _sku!cc!=ProjectProVolume
set /a kk+=1
set _pkey!kk!=YG9NW-3K39V-2T3HJ-93F3Q-G83KT
) else if %_PrjStd%==ON (
set /a cc+=1
set _sku!cc!=ProjectStdVolume
set /a kk+=1
set _pkey!kk!=GNFHQ-F6YQM-KQDGJ-327XX-KQBVC
)
if %_VisPro%==ON (
set /a cc+=1
set _sku!cc!=VisioProVolume
set /a kk+=1
set _pkey!kk!=PD3PC-RHNGV-FXJ29-8JK7D-RJRJK
) else if %_VisStd%==ON (
set /a cc+=1
set _sku!cc!=VisioStdVolume
set /a kk+=1
set _pkey!kk!=7WHWN-4T7MP-G96JF-G33KR-W8GF4
)
set "_retsuite=1"
if defined _suite goto :MenuExclude
goto :MenuChannel

:MenuApps2
set "_retsuite="
for /l %%J in (1,1,15) do (
set "_sku%%J="
)
set "_keys="
set "_pkey0="
for /l %%J in (1,1,15) do (
set "_pkey%%J="
)
set /a cc=0
set /a kk=0
if %_Access%==ON (
set /a cc+=1
set _sku!cc!=AccessVolume
set /a kk+=1
set _pkey!kk!=GNH9Y-D2J4T-FJHGG-QRVH7-QPFDW
)
if %_Excel%==ON (
set /a cc+=1
set _sku!cc!=ExcelVolume
set /a kk+=1
set _pkey!kk!=9C2PK-NWTVB-JMPW8-BFT28-7FTBF
)
if %_Outlook%==ON (
set /a cc+=1
set _sku!cc!=OutlookVolume
set /a kk+=1
set _pkey!kk!=R69KK-NTPKF-7M3Q4-QYBHW-6MT9B
)
if %_PowerPoint%==ON (
set /a cc+=1
set _sku!cc!=PowerPointVolume
set /a kk+=1
set _pkey!kk!=J7MQP-HNJ4Y-WJ7YM-PFYGF-BY6C6
)
if %_Publisher%==ON (
set /a cc+=1
set _sku!cc!=PublisherVolume
set /a kk+=1
set _pkey!kk!=F47MM-N3XJP-TQXJ9-BP99D-8K837
)
if %_SkypeForBusiness%==ON (
set /a cc+=1
set _sku!cc!=SkypeForBusinessVolume
set /a kk+=1
set _pkey!kk!=869NQ-FJ69K-466HW-QYCP2-DDBV6
)
if %_Word%==ON (
set /a cc+=1
set _sku!cc!=WordVolume
set /a kk+=1
set _pkey!kk!=WXY84-JN2Q9-RBCCQ-3Q3J3-3PFJ6
)
if %_OneNote%==ON (
set /a cc+=1
set _sku!cc!=OneNoteVolume
set /a kk+=1
set _pkey!kk!=DR92N-9HTF2-97XKM-XW2WJ-XW3J6
)
if %_PrjPro%==ON (
set /a cc+=1
set _sku!cc!=ProjectProVolume
set /a kk+=1
set _pkey!kk!=YG9NW-3K39V-2T3HJ-93F3Q-G83KT
) else if %_PrjStd%==ON (
set /a cc+=1
set _sku!cc!=ProjectStdVolume
set /a kk+=1
set _pkey!kk!=GNFHQ-F6YQM-KQDGJ-327XX-KQBVC
)
if %_VisPro%==ON (
set /a cc+=1
set _sku!cc!=VisioProVolume
set /a kk+=1
set _pkey!kk!=PD3PC-RHNGV-FXJ29-8JK7D-RJRJK
) else if %_VisStd%==ON (
set /a cc+=1
set _sku!cc!=VisioStdVolume
set /a kk+=1
set _pkey!kk!=7WHWN-4T7MP-G96JF-G33KR-W8GF4
)
goto :MenuChannel

:MenuExclude
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
if defined _suit2 (
  if /i not "%_suit2%"=="MondoVolume" (echo Suite   : %_suit2%) else (echo Suite   : %_suite%)
) else (
  echo Suite   : %_suite%
)
echo %line%
echo Select Apps to include ^(OFF ^= exclude^):
echo.
if %_Std%==OFF echo. A. Access           : %_Access%
echo. E. Excel            : %_Excel%
echo. N. OneNote          : %_OneNote%
echo. O. Outlook          : %_Outlook%
echo. P. PowerPoint       : %_PowerPoint%
echo. R. Publisher        : %_Publisher%
if %_Std%==OFF echo. S. SkypeForBusiness : %_Lync%
echo. W. Word             : %_Word%
if %_Mondo%==ON (
echo. J. Project          : %_Project%
echo. V. Visio            : %_Visio%
)
echo. D. OneDrive Desktop : %_OneDrive%
if not %_Teams%==0 echo. T. Microsoft Teams  : %_Teams%
echo %line%
choice /c AENOPRSWJVD90TX /n /m "Change a menu option, press 0 to proceed, 9 to go back, or X to exit: "
if errorlevel 15 goto :eof
if errorlevel 14 (if not %_Teams%==0 (if %_Teams%==ON (set _Teams=OFF) else (set _Teams=ON)))&goto :MenuExclude
if errorlevel 13 goto :MenuExclude2
if errorlevel 12 goto :MenuSuite
if errorlevel 11 (if %_OneDrive%==ON (set _OneDrive=OFF) else (set _OneDrive=ON))&goto :MenuExclude
if errorlevel 10 if %_Mondo%==ON (if %_Visio%==ON (set _Visio=OFF) else (set _Visio=ON))&goto :MenuExclude
if errorlevel 9 if %_Mondo%==ON (if %_Project%==ON (set _Project=OFF) else (set _Project=ON))&goto :MenuExclude
if errorlevel 8 (if %_Word%==ON (set _Word=OFF) else (set _Word=ON))&goto :MenuExclude
if errorlevel 7 if %_Std%==OFF (if %_Lync%==ON (set _Lync=OFF) else (set _Lync=ON))&goto :MenuExclude
if errorlevel 6 (if %_Publisher%==ON (set _Publisher=OFF) else (set _Publisher=ON))&goto :MenuExclude
if errorlevel 5 (if %_PowerPoint%==ON (set _PowerPoint=OFF) else (set _PowerPoint=ON))&goto :MenuExclude
if errorlevel 4 (if %_Outlook%==ON (set _Outlook=OFF) else (set _Outlook=ON))&goto :MenuExclude
if errorlevel 3 (if %_OneNote%==ON (set _OneNote=OFF) else (set _OneNote=ON))&goto :MenuExclude
if errorlevel 2 (if %_Excel%==ON (set _Excel=OFF) else (set _Excel=ON))&goto :MenuExclude
if errorlevel 1 if %_Std%==OFF (if %_Access%==ON (set _Access=OFF) else (set _Access=ON))&goto :MenuExclude
goto :MenuExclude

:MenuExclude2
set "_excluded=Groove"
for %%J in (Access,Excel,Lync,OneDrive,OneNote,Outlook,PowerPoint,Project,Publisher,Teams,Visio,Word) do (
if !_%%J!==OFF set "_excluded=!_excluded!,%%J"
)
goto :MenuChannel

:MenuChannel
set "inpt="
set "CTRffn="
set "CTRchn="
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
echo %line%
echo Select Update Channel:
echo.
echo. 0. Default
echo. 1. Beta    / Insider Fast              ^|   Insiders::DevMain
echo. 2. Current / Monthly Preview           ^|   Insiders::CC
echo. 3. Current / Monthly                   ^| Production::CC
echo.
echo. 4. Monthly Enterprise                  ^| Production::MEC
echo. 5. Semi-Annual Preview                 ^|   Insiders::FRDC
echo. 6. Semi-Annual                         ^| Production::DC
echo.
echo. 7. Perpetual2016 VL                    ^| Production::LTSC
echo. 8. Microsoft Perpetual                 ^|  Microsoft::LTSC
echo.
echo. D. DevMain Channel                     ^|    Dogfood::DevMain
echo. E. Microsoft Elite                     ^|  Microsoft::DevMain
echo %line%
choice /c 12345678DE09X /n /m "Choose a menu option to proceed, press 9 to go back, or X to exit: "
if errorlevel 13 goto :eof
if errorlevel 12 (if defined _retsuite (goto :MenuSuite) else (goto :MenuApps))
if errorlevel 11 (set inpt=0&goto :MenuChannel2)
if errorlevel 10 (set inpt=10&goto :MenuChannel2)
if errorlevel 9 (set inpt=9&goto :MenuChannel2)
if errorlevel 8 (set inpt=8&goto :MenuChannel2)
if errorlevel 7 (set inpt=7&goto :MenuChannel2)
if errorlevel 6 (set inpt=6&goto :MenuChannel2)
if errorlevel 5 (set inpt=5&goto :MenuChannel2)
if errorlevel 4 (set inpt=4&goto :MenuChannel2)
if errorlevel 3 (set inpt=3&goto :MenuChannel2)
if errorlevel 2 (set inpt=2&goto :MenuChannel2)
if errorlevel 1 (set inpt=1&goto :MenuChannel2)
goto :MenuChannel

:MenuChannel2
if %inpt%==0 (
expand.exe -f:*.xml "!CTRsource!\Office\Data\%CTRvcab%" "!_temp!." >nul
for /f "tokens=3 delims=<= " %%# in ('find /i "DeliveryMechanism" "!_temp!\VersionDescriptor.xml" 2^>nul') do set "FFNRoot=%%~#"
if "!FFNRoot!" neq "" for /l %%J in (1,1,9) do (
  if /i !FFNRoot! equ !ffn%%J! set inpt=%%J
  )
if "!FFNRoot!" equ "" set inpt=3
del /f /q "!_temp!\*.xml" 1>nul 2>nul
)
set "CTRffn=!ffn%inpt%!"
set "CTRchn=!chn%inpt%!"
set "_products="
set "_licenses="
set "_exclude1d="
set "_keys="
set "_skus="
set "_show="
set "_tmp="
if defined _suite (
set "_products=%_suite%.16_%CTRlng%_x-none"
set "_keys=%_pkey0%"
if %_O365PP%==ON set "_keys=!_keys!,DRNV7-VGMM2-B3G9T-4BF84-VMFTK"
)
if defined _suit2 set "_licenses=%_suit2%"
if not defined _sku1 goto :MenuMisc
for /l %%J in (1,1,%cc%) do (
if defined _skus (set "_skus=!_skus!,!_sku%%J!") else (set "_skus=!_sku%%J!")
)
for /l %%J in (1,1,%kk%) do (
if defined _keys (set "_keys=!_keys!,!_pkey%%J!") else (set "_keys=!_pkey%%J!")
)
for %%J in (%_skus%) do (
set _tmp=%%J
if /i "!_tmp:~-6!"=="Volume" (
  if defined _show (set "_show=!_show!,%%J") else (set "_show=%%J")
  if defined _products (set "_products=!_products!^|%%J.16_%CTRlng%_x-none") else (set "_products=%%J.16_%CTRlng%_x-none")
  if %_OneDrive%==OFF (if defined _exclude1d (set "_exclude1d=!_exclude1d! %%J.excludedapps.16=onedrive") else (set "_exclude1d=%%J.excludedapps.16=onedrive"))
  )
)
goto :MenuMisc

:MenuMisc
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
echo Channel : %CTRchn%
echo CDN     : %CTRffn%
echo %line%
echo Miscellaneous Options:
echo.
echo. 1. Updates Enabled     : %_updt%
echo. 2. Accept EULA         : %_eula%
echo. 3. Pin Icons To Taskbar: %_icon%
echo. 4. Force App Shutdown  : %_shut%
echo. 5. Display Level       : %_disp%
echo. 6. Auto Activate       : %_actv%
echo. 7. Disable Telemetry   : %_tele%
echo %line%
choice /c 123456790X /n /m "Change a menu option, press 0 to proceed, 9 to go back, or X to exit: "
if errorlevel 10 goto :eof
if errorlevel 9 goto :MenuFinal
if errorlevel 8 goto :MenuChannel
if errorlevel 7 (if %_tele%==True (set _tele=False) else (set _tele=True))&goto :MenuMisc
if errorlevel 6 (if %_actv%==True (set _actv=False) else (set _actv=True))&goto :MenuMisc
if errorlevel 5 (if %_disp%==True (set _disp=False) else (set _disp=True))&goto :MenuMisc
if errorlevel 4 (if %_shut%==True (set _shut=False) else (set _shut=True))&goto :MenuMisc
if errorlevel 3 (if %_icon%==True (set _icon=False) else (set _icon=True))&goto :MenuMisc
if errorlevel 2 (if %_eula%==True (set _eula=False) else (set _eula=True))&goto :MenuMisc
if errorlevel 1 (if %_updt%==True (set _updt=False) else (set _updt=True))&goto :MenuMisc
goto :MenuMisc

:MenuFinal
set _install=False
set _unattend=False
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
echo Channel : %CTRchn%
echo CDN     : %CTRffn%
if defined _suite (
if defined _suit2 (
  if /i not "%_suit2%"=="MondoVolume" (echo Suite   : %_suit2%) else (echo Suite   : %_suite%)
  ) else (
  echo Suite   : %_suite%
  )
)
if defined _skus echo SKUs    : %_show%
if defined _excluded echo Excluded: %_excluded%
echo Updates : %_updt% / AcceptEULA : %_eula% / Display : %_disp%
echo PinIcons: %_icon% / AppShutdown: %_shut% / Activate: %_actv%
echo %line%
echo.
echo. 1. Install Now
echo. 2. Create setup configuration ^(Normal Install^)
echo. 3. Create setup configuration ^(Auto Install^)
echo.
echo %line%
choice /c 1239X /n /m "Choose a menu option to proceed, press 9 to go back, or X to exit: "
if errorlevel 5 goto :eof
if errorlevel 4 goto :MenuMisc
if errorlevel 3 (set _unattend=True&goto :MenuFinal2)
if errorlevel 2 (set _unattend=False&goto :MenuFinal2)
if errorlevel 1 (set _install=True&goto :MenuFinal2)
goto :MenuFinal

:MenuFinal2
cls
for /f "tokens=2 delims==." %%# in ('wmic os get localdatetime /value') do set "_date=%%#"
copy /y nul "!_work!\#.rw" 1>nul 2>nul && (if exist "!_work!\#.rw" del /f /q "!_work!\#.rw") || (set "_ini=!_dsk!")

(
echo [configuration]
echo SourcePath="!CTRsource!"
echo Type=%CTRtype%
echo Version=%CTRver%
echo Architecture=%CTRarc%
echo O32W64=%wow64%
echo Language=%CTRlng%
echo LCID=%CTRcul%
if defined CTRprm echo Primary=%CTRstp%,%CTRprm%
echo Channel=%CTRchn%
echo CDN=%CTRffn%
if defined _suite (
if defined _suit2 (
  if /i not "%_suit2%"=="MondoVolume" (echo Suite=%_suit2%) else (echo Suite=%_suite%)
  ) else (
  echo Suite=%_suite%
  )
echo ExcludedApps=%_excluded%
)
if defined _skus (
echo SKUs=%_show%
if not defined _suite if %_OneDrive%==OFF echo ExcludedApps=OneDrive
)
echo UpdatesEnabled=%_updt%
echo AcceptEULA=%_eula%
echo PinIconsToTaskbar=%_icon%
echo ForceAppShutdown=%_shut%
echo AutoActivate=%_actv%
echo DisableTelemetry=%_tele%
echo DisplayLevel=%_disp%
echo AutoInstallation=%_unattend%
)>"!_ini!\C2R_Config_%_date:~0,8%-%_date:~8,4%.ini" 2>nul

if %_install%==False (
echo %line%
echo Done
echo %line%
goto :TheEnd
)

:MenuInstall
echo %line%
echo Preparing... 
echo %line%
echo.
if defined _suite (
for %%# in (a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z) do set _excluded=!_excluded:%%#=%%#!
)
if %_actv%==True (set "_autoact=autoactivate=1"&set "_activate=Activate=1") else (set "_autoact="&set "_activate=")
set "_CTR=HKLM\SOFTWARE\Microsoft\Office\ClickToRun"
set "_Config=%_CTR%\Configuration"
set "_url=http://officecdn.microsoft.com/pr"

(
echo @echo off
echo reg.exe query "HKU\S-1-5-19" 1^>nul 2^>nul ^|^| ^(echo Run the script as administrator^&pause^&exit /b^)
echo reg.exe delete %_Config% /f /v UpdateUrl 1^>nul 2^>nul
echo reg.exe delete %_Config% /f /v UpdateToVersion 1^>nul 2^>nul
echo reg.exe delete %_CTR%\Updates /f /v UpdateToVersion 1^>nul 2^>nul
echo reg.exe delete HKLM\SOFTWARE\Policies\Microsoft\Office\16.0\Common\OfficeUpdate /f 1^>nul 2^>nul
echo reg.exe add HKLM\SOFTWARE\Policies\Microsoft\Office\16.0\Common\OfficeUpdate /f /v PreventBingInstall /t REG_DWORD /d 1 1^>nul 2^>nul
echo start "" /WAIT "%%CommonProgramFiles%%\Microsoft Shared\ClickToRun\OfficeClickToRun.exe" ^^
echo deliverymechanism=%CTRffn% platform=%CTRarc% culture=%CTRstp% b= displaylevel=%_disp% ^^
echo forceappshutdown=%_shut% piniconstotaskbar=%_icon% acceptalleulas.16=%_eula% ^^
echo updatesenabled.16=%_updt% updatepromptuser=True ^^
echo updatebaseurl.16=%_url%/%CTRffn% ^^
echo cdnbaseurl.16=%_url%/%CTRffn% ^^
echo mediatype.16=%CTRtype% sourcetype.16=%CTRtype% version.16=%CTRver% ^^
echo baseurl.16="!CTRsource!" ^^^^
echo productstoadd="%_products%" ^^
echo pidkeys=%_keys% %_autoact% ^^
if defined _suite echo %_suite%.excludedapps.16=%_excluded% ^^
if defined _exclude1d echo %_exclude1d% ^^
echo flt.useexptransportinplacepl=disabled flt.useofficehelperaddon=disabled flt.useoutlookshareaddon=disabled 1^>nul 2^>nul
echo reg.exe add %_Config% /f /v UpdateChannel /t REG_SZ /d "%_url%/%CTRffn%" 1^>nul 2^>nul
echo reg.exe add %_Config% /f /v UpdateChannelChanged /t REG_SZ /d True 1^>nul 2^>nul
echo exit /b
)>"!_temp!\C2R_Setup.bat"

set "CTRexe=1"
if exist "!_file!" for /f "tokens=4 delims==." %%i in ('wmic datafile where "name='!_file:\=\\!'" get Version /value') do (
  if %%i geq %verchk% (set CTRexe=0)
)
call :StopService 1>nul 2>nul
if %CTRexe%==1 (
if exist "!_target!" rd /s /q "!_target!" 1>nul 2>nul
md "!_target!" 1>nul 2>nul
expand -f:* "!CTRsource!\Office\Data\%CTRver%\%CTRicab%" "!_target!" 1>nul 2>nul
expand -f:* "!CTRsource!\Office\Data\%CTRver%\%CTRicabr%" "!_target!" 1>nul 2>nul
)
echo.
echo %line%
echo Running installation... 
echo %line%
echo.
del /f /q "%SystemRoot%\temp\*.log" 1>nul 2>nul
del /f /q "!_temp!\*.log" 1>nul 2>nul
!_ComSpec! /c ""!_temp!\C2R_Setup.bat" "
del /f /q "!_temp!\C2R_Setup.bat" 1>nul 2>nul
if not exist "!_Program!\Microsoft Office\root\Office16\*.dll" if not exist "%ProgramFiles(x86)%\Microsoft Office\root\Office16\*.dll" (
echo.
echo %line%
echo Installation failed.
echo %line%
goto :TheEnd
)
if %_Mondo%==ON (
set "_licenses=O365ProPlusRetail"
set "_keys=DRNV7-VGMM2-B3G9T-4BF84-VMFTK"
)
if defined _licenses (
echo.
echo %line%
echo Installing Volume Licenses... 
echo %line%
echo.
call :Licenses 1>nul 2>nul
)
if %_tele%==True (
if defined _suit2 (
  if /i not "%_suit2%"=="MondoVolume" call :Telemetry 1>nul 2>nul
  ) else (
  call :Telemetry 1>nul 2>nul
  )
)
echo.
echo %line%
echo Done.
echo %line%
echo.
echo Press any key to exit.
pause >nul
taskkill /t /f /IM OfficeC2RClient.exe 1>nul 2>nul
goto :eof

:StopService
sc query WSearch | find /i "STOPPED" || net stop WSearch /y
sc query WSearch | find /i "STOPPED" || sc stop WSearch
if not exist "!_file!" exit /b
sc query ClickToRunSvc | find /i "STOPPED" || net stop ClickToRunSvc /y
sc query ClickToRunSvc | find /i "STOPPED" || sc stop ClickToRunSvc
taskkill /t /f /IM OfficeC2RClient.exe
taskkill /t /f /IM OfficeClickToRun.exe
exit /b

:Licenses
for /f "skip=2 tokens=2*" %%A in ('reg query %_CTR% /v InstallPath') do set "_Root=%%B\root"
for /f "skip=2 tokens=2*" %%A in ('reg query %_CTR% /v PackageGUID') do set "_GUID=%%B"
for %%J in (%_licenses%) do (
if defined _ids (set "_ids=!_ids!,%%J.16") else (set "_ids=%%J.16")
reg delete %_Config% /f /v %%J.OSPPReady
)
"!_Root!\integration\integrator.exe" /I /License PRIDName=%_ids% PidKey=%_keys% %_activate% PackageGUID="%_GUID%" PackageRoot="!_Root!"
for %%J in (%_licenses%) do (
reg query %_Config% /v ProductReleaseIds | findstr /I "%%J" || (for /f "skip=2 tokens=2*" %%A in ('reg query %_Config% /v ProductReleaseIds') do reg add %_Config% /f /v ProductReleaseIds /t REG_SZ /d "%%J,%%B")
reg add %_Config% /f /v %%J.OSPPReady /t REG_SZ /d 1
)
exit /b

:Telemetry
set "_inter=Software"
if %wow64%==1 (set "_inter=Software\Wow6432Node")
set "_rkey=%_CTR%\REGISTRY\MACHINE\%_inter%\Microsoft\Office\16.0\User Settings\CustomSettings"
set "_skey=%_CTR%\REGISTRY\MACHINE\%_inter%\Microsoft\Office\16.0\User Settings\CustomSettings\Create\Software\Microsoft\Office\16.0"
set "_tkey=%_CTR%\REGISTRY\MACHINE\%_inter%\Microsoft\Office\16.0\User Settings\CustomSettings\Create\Software\Microsoft\Office\Common\ClientTelemetry"
for %%# in (Count,Order) do reg add "%_rkey%" /f /v %%# /t REG_DWORD /d 1
reg add "%_tkey%" /f /v SendTelemetry /t REG_DWORD /d 3
reg add "%_tkey%" /f /v DisableTelemetry /t REG_DWORD /d 1
for %%# in (disconnectedstate,usercontentdisabled,downloadcontentdisabled,controllerconnectedservicesenabled) do reg add "%_skey%\Common\Privacy" /f /v %%# /t REG_DWORD /d 2
for %%# in (qmenable,sendcustomerdata,updatereliabilitydata) do reg add "%_skey%\Common" /f /v %%# /t REG_DWORD /d 0
for %%# in (disableboottoofficestart,optindisable,shownfirstrunoptin,ShownFileFmtPrompt) do reg add "%_skey%\Common\General" /f /v %%# /t REG_DWORD /d 1
for %%# in (BootedRTM,disablemovie) do reg add "%_skey%\Firstrun" /f /v %%# /t REG_DWORD /d 1
for %%# in (EnableLogging,EnableUpload) do reg add "%_skey%\OSM" /f /v %%# /t REG_DWORD /d 0
for %%# in (accesssolution,olksolution,onenotesolution,pptsolution,projectsolution,publishersolution,visiosolution,wdsolution,xlsolution) do reg add "%_skey%\OSM\PreventedApplications" /f /v %%# /t REG_DWORD /d 1
for %%# in (agave,appaddins,comaddins,documentfiles,templatefiles) do reg add "%_skey%\OSM\PreventedSolutiontypes" /f /v %%# /t REG_DWORD /d 1
reg add "%_skey%\Common\Security\FileValidation" /f /v disablereporting /t REG_DWORD /d 1
reg add "%_skey%\Common\PTWatson" /f /v PTWOptIn /t REG_DWORD /d 0
reg add "%_skey%\Lync" /f /v disableautomaticsendtracing /t REG_DWORD /d 1
reg add "%_skey%\Outlook\Options\Mail" /f /v EnableLogging /t REG_DWORD /d 0
reg add "%_skey%\Word\Options" /f /v EnableLogging /t REG_DWORD /d 0
set "_schtasks=SCHTASKS /Change /DISABLE /TN"
set "_schedule=Microsoft\Office"
%_schtasks% "%_schedule%\OfficeInventoryAgentFallBack"
%_schtasks% "%_schedule%\OfficeTelemetryAgentFallBack"
%_schtasks% "%_schedule%\OfficeTelemetryAgentFallBack2016"
%_schtasks% "%_schedule%\OfficeInventoryAgentLogOn"
%_schtasks% "%_schedule%\OfficeTelemetryAgentLogOn"
%_schtasks% "%_schedule%\OfficeTelemetryAgentLogOn2016"
exit /b

:E_VER
echo %_err%
echo Minimum Supported Version is 16.0.9029.2167
goto :TheEnd

:E_Admin
echo %_err%
echo Right click on this script and select 'Run as administrator'
goto :TheEnd

:E_Win
echo %_err%
echo Windows 7 SP1 is the minimum supported OS.

:TheEnd
echo.
echo Press any key to exit.
pause >nul
goto :eof
