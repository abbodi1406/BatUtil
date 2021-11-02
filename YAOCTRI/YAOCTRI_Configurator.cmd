@setlocal DisableDelayedExpansion
@echo off
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
set lpid=(ar-SA,bg-BG,cs-CZ,da-DK,de-DE,el-GR,en-US,es-ES,et-EE,fi-FI,fr-FR,he-IL,hr-HR,hu-HU,it-IT,ja-JP,ko-KR,lt-LT,lv-LV,nb-NO,nl-NL,pl-PL,pt-BR,pt-PT,ro-RO,ru-RU,sk-SK,sl-SI,sr-Latn-RS,sv-SE,th-TH,tr-TR,uk-UA,zh-CN,zh-TW,hi-IN,id-ID,kk-KZ,MS-MY,vi-VN,en-GB,es-MX,fr-CA)
set lcid=(1025,1026,1029,1030,1031,1032,1033,3082,1061,1035,1036,1037,1050,1038,1040,1041,1042,1063,1062,1044,1043,1045,1046,2070,1048,1049,1051,1060,9242,1053,1054,1055,1058,2052,1028,1081,1057,1087,1086,1066,2057,2058,3084)
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
ea4a4090-de26-49d7-93c1-91bff9e53fc3
b61285dd-d9f7-41f2-9757-8f61cba4e9c8
f2e724c1-748f-4b47-8fb8-8e0d210e9208
1d2d2ea6-1680-4c56-ac58-a441c8c24ff9
5030841d-c919-4594-8d2d-84ae4f96e58e
86752282-5841-4120-ac80-db03ae6b5fdb
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
DogfoodDevMain
MicrosoftElite
PerpetualVL2019
MicrosoftLTSC
PerpetualVL2021
MicrosoftLTSC2021
) do (
set /a cc+=1
set chn!cc!=%%#
)
set unpv=(bg-BG,et-EE,hr-HR,lt-LT,lv-LV,sr-Latn-RS,th-TH,hi-IN,id-ID,kk-KZ,MS-MY,vi-VN,en-GB,es-MX,fr-CA)
set /a cc=0
for %%# in %unpv% do (
set /a cc+=1
set unpv!cc!=%%#
)
set unap=(hi-IN,kk-KZ,MS-MY,en-GB,es-MX,fr-CA)
set /a cc=0
for %%# in %unap% do (
set /a cc+=1
set unap!cc!=%%#
)
set unon=(en-GB,es-MX,fr-CA)
set /a cc=0
for %%# in %unon% do (
set /a cc+=1
set unon!cc!=%%#
)
set _supv=1
set _suap=1
set _suon=1
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
if %errortmp%==9 if %vvv% geq 9 (set inpt=9&goto :MenuVersion2)
if %errortmp%==8 if %vvv% geq 8 (set inpt=8&goto :MenuVersion2)
if %errortmp%==7 if %vvv% geq 7 (set inpt=7&goto :MenuVersion2)
if %errortmp%==6 if %vvv% geq 6 (set inpt=6&goto :MenuVersion2)
if %errortmp%==5 if %vvv% geq 5 (set inpt=5&goto :MenuVersion2)
if %errortmp%==4 if %vvv% geq 4 (set inpt=4&goto :MenuVersion2)
if %errortmp%==3 if %vvv% geq 3 (set inpt=3&goto :MenuVersion2)
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
set _ext=1
if %verchk% lss 14326 set _ext=0
set _cln=40
if %_ext%==1 set _cln=43
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
for /l %%J in (1,1,%_cln%) do (
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
for /l %%J in (1,1,%_cln%) do (
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
if %errortmp%==9 if %int% geq 9 (set inpt=9&goto :MenuLang2)
if %errortmp%==8 if %int% geq 8 (set inpt=8&goto :MenuLang2)
if %errortmp%==7 if %int% geq 7 (set inpt=7&goto :MenuLang2)
if %errortmp%==6 if %int% geq 6 (set inpt=6&goto :MenuLang2)
if %errortmp%==5 if %int% geq 5 (set inpt=5&goto :MenuLang2)
if %errortmp%==4 if %int% geq 4 (set inpt=4&goto :MenuLang2)
if %errortmp%==3 if %int% geq 3 (set inpt=3&goto :MenuLang2)
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
goto :XmlCheck

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
if %errortmp%==9 if %int% geq 9 (set inpt=9&goto :MenuLangM2)
if %errortmp%==8 if %int% geq 8 (set inpt=8&goto :MenuLangM2)
if %errortmp%==7 if %int% geq 7 (set inpt=7&goto :MenuLangM2)
if %errortmp%==6 if %int% geq 6 (set inpt=6&goto :MenuLangM2)
if %errortmp%==5 if %int% geq 5 (set inpt=5&goto :MenuLangM2)
if %errortmp%==4 if %int% geq 4 (set inpt=4&goto :MenuLangM2)
if %errortmp%==3 if %int% geq 3 (set inpt=3&goto :MenuLangM2)
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

:XmlCheck
set _O2019=1
set _O2021=1
if %verchk% lss 14026 set _O2021=0
expand.exe -f:*.xml "!CTRsource!\Office\Data\%CTRvcab%" "!_temp!." >nul
find /i "Word2019Volume" "!_temp!\VersionDescriptor.xml" 1>nul 2>nul || set _O2019=0
for /f "tokens=3 delims=<= " %%# in ('find /i "DeliveryMechanism" "!_temp!\VersionDescriptor.xml" 2^>nul') do set "FFNRoot=%%~#"
del /f /q "!_temp!\*.xml" 1>nul 2>nul
set _SAC=1
if not "!FFNRoot!"=="" for %%J in (1,2,3,4,5,7,8) do (
  if /i "!FFNRoot!"=="!ffn%%J!" set _SAC=0
)
set _C19=0
if not "!FFNRoot!"=="" for %%J in (9,10) do (
  if /i "!FFNRoot!"=="!ffn%%J!" set _C19=1
)
set _C21=0
if not "!FFNRoot!"=="" for %%J in (11,12) do (
  if /i "!FFNRoot!"=="!ffn%%J!" set _C21=1
)
for /l %%J in (1,1,15) do (
if /i "%CTRstp%"=="!unpv%%J!" set _supv=0
)
for /l %%J in (1,1,6) do (
if /i "%CTRstp%"=="!unap%%J!" set _suap=0
)
for /l %%J in (1,1,3) do (
if /i "%CTRstp%"=="!unon%%J!" set _suon=0
)
if %_suon%==0 set _O2019=0

:MenuInitial
set "_return=MenuSuite"
set _OneDrive=OFF
set _Access=ON
set _Excel=ON
set _Lync=ON
set _OneNote=ON
set _Outlook=ON
set _PowerPoint=ON
set _Publisher=ON
set _SkypeForBusiness=ON
set _Word=ON
set _Project=ON
set _Visio=ON
set _O21Access=ON
set _O21Excel=ON
set _O21Lync=ON
set _O21Outlook=ON
set _O21PowerPoint=ON
set _O21Publisher=ON
set _O21SkypeForBusiness=ON
set _O21Word=ON
set _Mondo=OFF
set _O365PP=ON
set _O19Pro=OFF
set _O19Std=OFF
set _O19PrjPro=OFF
set _O19PrjStd=OFF
set _O19VisPro=OFF
set _O19VisStd=OFF
set _O21Pro=OFF
set _O21Std=OFF
set _O21PrjPro=OFF
set _O21PrjStd=OFF
set _O21VisPro=OFF
set _O21VisStd=OFF
set _updt=True
set _eula=True
set _icon=False
set _shut=True
set _disp=True
set _actv=False
set _tele=False
set _Teams=OFF
if %verchk:~0,2% geq 11 if %verchk% lss 11328 set _Teams=0
if %verchk:~0,2% equ 10 if %verchk% lss 10336 set _Teams=0
if %_O2019%==0 if %_O2021%==0 goto :MenuSuite
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
echo %line%
echo.
echo. 1. Install Microsoft Office Suite
if %_O2021%==1 echo. 2. Install Office 2021 Single Apps
if %_O2019%==1 echo. 3. Install Office 2019 Single Apps
echo.
echo %line%
choice /c 123X /n /m "Choose a menu option to proceed, or press X to exit: "
if errorlevel 4 goto :eof
if errorlevel 3 (if %_O2019%==1 (goto :MenuApps) else (goto :MenuInitial))
if errorlevel 2 (if %_O2021%==1 (goto :Menu21Apps) else (goto :MenuInitial))
if errorlevel 1 goto :MenuSuite
goto :MenuInitial

:MenuSuite
if %_Mondo%==OFF if %_O365PP%==OFF if %_O19Pro%==OFF if %_O19Std%==OFF if %_O19PrjPro%==OFF if %_O19PrjStd%==OFF if %_O19VisPro%==OFF if %_O19VisStd%==OFF if %_O21Pro%==OFF if %_O21Std%==OFF if %_O21PrjPro%==OFF if %_O21PrjStd%==OFF if %_O21VisPro%==OFF if %_O21VisStd%==OFF set _O365PP=ON
set errortmp=
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
echo %line%
echo Select Products to Install:
echo.
echo. 1. Microsoft 365 Enterprise : %_O365PP%
echo. 2. Office Mondo 2016        : %_Mondo%
if %_O2021%==1 (
echo.
echo. 3. Office ProPlus 2021      : %_O21Pro%
echo. 4. Office Standard 2021     : %_O21Std%
)
if %_O2021%==1 if %_supv%==1 (
echo. 5. Project Pro 2021         : %_O21PrjPro%
echo. 6. Project Standard 2021    : %_O21PrjStd%
echo. 7. Visio Pro 2021           : %_O21VisPro%
echo. 8. Visio Standard 2021      : %_O21VisStd%
)
if %_O2019%==1 (
echo.
echo. F. Office ProPlus 2019      : %_O19Pro%
echo. D. Office Standard 2019     : %_O19Std%
)
if %_O2019%==1 if %_supv%==1 (
echo. P. Project Pro 2019         : %_O19PrjPro%
echo. R. Project Standard 2019    : %_O19PrjStd%
echo. V. Visio Pro 2019           : %_O19VisPro%
echo. S. Visio Standard 2019      : %_O19VisStd%
)
echo %line%
choice /c 123456789FDPRVS0X /n /m "Change a menu option, press 0 to proceed, 9 to go back, or X to exit: "
set errortmp=%errorlevel%
if %errortmp%==17 goto :eof
if %errortmp%==16 goto :MenuSuit2
if %errortmp%==15 if %_O2019%==1 if %_supv%==1 (if %_O19VisStd%==ON (set _O19VisStd=OFF) else if %_Mondo%==OFF (set _O19VisStd=ON&set _O19VisPro=OFF&set _O21VisPro=OFF&set _O21VisStd=OFF)&goto :MenuSuite)
if %errortmp%==14 if %_O2019%==1 if %_supv%==1 (if %_O19VisPro%==ON (set _O19VisPro=OFF) else if %_Mondo%==OFF (set _O19VisPro=ON&set _O19VisStd=OFF&set _O21VisPro=OFF&set _O21VisStd=OFF)&goto :MenuSuite)
if %errortmp%==13 if %_O2019%==1 if %_supv%==1 (if %_O19PrjStd%==ON (set _O19PrjStd=OFF) else if %_Mondo%==OFF (set _O19PrjStd=ON&set _O19PrjPro=OFF&set _O21PrjPro=OFF&set _O21PrjStd=OFF)&goto :MenuSuite)
if %errortmp%==12 if %_O2019%==1 if %_supv%==1 (if %_O19PrjPro%==ON (set _O19PrjPro=OFF) else if %_Mondo%==OFF (set _O19PrjPro=ON&set _O19PrjStd=OFF&set _O21PrjPro=OFF&set _O21PrjStd=OFF)&goto :MenuSuite)
if %errortmp%==11 if %_O2019%==1 (if %_O19Std%==ON (set _O19Std=OFF) else (set _O19Std=ON&set _Mondo=OFF&set _O365PP=OFF&set _O19Pro=OFF&set _O21Pro=OFF&set _O21Std=OFF)&goto :MenuSuite)
if %errortmp%==10 if %_O2019%==1 (if %_O19Pro%==ON (set _O19Pro=OFF) else (set _O19Pro=ON&set _Mondo=OFF&set _O365PP=OFF&set _O19Std=OFF&set _O21Pro=OFF&set _O21Std=OFF)&goto :MenuSuite)
if %errortmp%==9 goto :MenuInitial
if %errortmp%==8 if %_O2021%==1 if %_supv%==1 (if %_O21VisStd%==ON (set _O21VisStd=OFF) else if %_Mondo%==OFF (set _O21VisStd=ON&set _O21VisPro=OFF&set _O19VisPro=OFF&set _O19VisStd=OFF)&goto :MenuSuite)
if %errortmp%==7 if %_O2021%==1 if %_supv%==1 (if %_O21VisPro%==ON (set _O21VisPro=OFF) else if %_Mondo%==OFF (set _O21VisPro=ON&set _O21VisStd=OFF&set _O19VisPro=OFF&set _O19VisStd=OFF)&goto :MenuSuite)
if %errortmp%==6 if %_O2021%==1 if %_supv%==1 (if %_O21PrjStd%==ON (set _O21PrjStd=OFF) else if %_Mondo%==OFF (set _O21PrjStd=ON&set _O21PrjPro=OFF&set _O19PrjPro=OFF&set _O19PrjStd=OFF)&goto :MenuSuite)
if %errortmp%==5 if %_O2021%==1 if %_supv%==1 (if %_O21PrjPro%==ON (set _O21PrjPro=OFF) else if %_Mondo%==OFF (set _O21PrjPro=ON&set _O21PrjStd=OFF&set _O19PrjPro=OFF&set _O19PrjStd=OFF)&goto :MenuSuite)
if %errortmp%==4 if %_O2021%==1 (if %_O21Std%==ON (set _O21Std=OFF) else (set _O21Std=ON&set _Mondo=OFF&set _O365PP=OFF&set _O21Pro=OFF&set _O19Pro=OFF&set _O19Std=OFF)&goto :MenuSuite)
if %errortmp%==3 if %_O2021%==1 (if %_O21Pro%==ON (set _O21Pro=OFF) else (set _O21Pro=ON&set _Mondo=OFF&set _O365PP=OFF&set _O21Std=OFF&set _O19Pro=OFF&set _O19Std=OFF)&goto :MenuSuite)
if %errortmp%==2 (if %_Mondo%==ON (set _Mondo=OFF) else (set _Mondo=ON&set _O365PP=OFF&set _O19Pro=OFF&set _O19Std=OFF&set _O19PrjPro=OFF&set _O19PrjStd=OFF&set _O19VisPro=OFF&set _O19VisStd=OFF&set _O21Pro=OFF&set _O21Std=OFF&set _O21PrjPro=OFF&set _O21PrjStd=OFF&set _O21VisPro=OFF&set _O21VisStd=OFF))&goto :MenuSuite
if %errortmp%==1 (if %_O365PP%==ON (set _O365PP=OFF) else (set _O365PP=ON&set _Mondo=OFF&set _O19Pro=OFF&set _O19Std=OFF&set _O21Pro=OFF&set _O21Std=OFF))&goto :MenuSuite
goto :MenuSuite

:MenuApps
if %_Access%==OFF if %_Excel%==OFF if %_OneNote%==OFF if %_Outlook%==OFF if %_PowerPoint%==OFF if %_Publisher%==OFF if %_SkypeForBusiness%==OFF if %_Word%==OFF if %_O19PrjPro%==OFF if %_O19PrjStd%==OFF if %_O19VisPro%==OFF if %_O19VisStd%==OFF set _Word=ON
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
echo %line%
echo Select Apps to install:
echo.
echo. A. Access 2019           : %_Access%
echo. E. Excel 2019            : %_Excel%
echo. N. OneNote 2016          : %_OneNote%
echo. O. Outlook 2019          : %_Outlook%
echo. P. PowerPoint 2019       : %_PowerPoint%
echo. R. Publisher 2019        : %_Publisher%
echo. S. SkypeForBusiness 2019 : %_SkypeForBusiness%
echo. W. Word 2019             : %_Word%
if %_supv%==1 (
echo.
echo. 5. Project Pro 2019      : %_O19PrjPro%
echo. 6. Project Standard 2019 : %_O19PrjStd%
echo. 7. Visio Pro 2019        : %_O19VisPro%
echo. 8. Visio Standard 2019   : %_O19VisStd%
)
echo.
echo. D. OneDrive Desktop      : %_OneDrive%
if not %_Teams%==0 echo. T. Microsoft Teams       : %_Teams%
echo %line%
choice /c AENOPRSWD567890TX /n /m "Change a menu option, press 0 to proceed, 9 to go back, or X to exit: "
set errortmp=%errorlevel%
if %errortmp%==17 goto :eof
if %errortmp%==16 if not %_Teams%==0 (if %_Teams%==ON (set _Teams=OFF) else (set _Teams=ON)&goto :MenuApps)
if %errortmp%==15 goto :MenuApp2
if %errortmp%==14 goto :MenuInitial
if %errortmp%==13 if %_supv%==1 (if %_O19VisStd%==ON (set _O19VisStd=OFF) else (set _O19VisPro=OFF&set _O19VisStd=ON)&goto :MenuApps)
if %errortmp%==12 if %_supv%==1 (if %_O19VisPro%==ON (set _O19VisPro=OFF) else (set _O19VisPro=ON&set _O19VisStd=OFF)&goto :MenuApps)
if %errortmp%==11 if %_supv%==1 (if %_O19PrjStd%==ON (set _O19PrjStd=OFF) else (set _O19PrjPro=OFF&set _O19PrjStd=ON)&goto :MenuApps)
if %errortmp%==10 if %_supv%==1 (if %_O19PrjPro%==ON (set _O19PrjPro=OFF) else (set _O19PrjPro=ON&set _O19PrjStd=OFF)&goto :MenuApps)
if %errortmp%==9 (if %_OneDrive%==ON (set _OneDrive=OFF) else (set _OneDrive=ON))&goto :MenuApps
if %errortmp%==8 (if %_Word%==ON (set _Word=OFF) else (set _Word=ON))&goto :MenuApps
if %errortmp%==7 (if %_SkypeForBusiness%==ON (set _SkypeForBusiness=OFF) else (set _SkypeForBusiness=ON))&goto :MenuApps
if %errortmp%==6 (if %_Publisher%==ON (set _Publisher=OFF) else (set _Publisher=ON))&goto :MenuApps
if %errortmp%==5 (if %_PowerPoint%==ON (set _PowerPoint=OFF) else (set _PowerPoint=ON))&goto :MenuApps
if %errortmp%==4 (if %_Outlook%==ON (set _Outlook=OFF) else (set _Outlook=ON))&goto :MenuApps
if %errortmp%==3 (if %_OneNote%==ON (set _OneNote=OFF) else (set _OneNote=ON))&goto :MenuApps
if %errortmp%==2 (if %_Excel%==ON (set _Excel=OFF) else (set _Excel=ON))&goto :MenuApps
if %errortmp%==1 (if %_Access%==ON (set _Access=OFF) else (set _Access=ON))&goto :MenuApps
goto :MenuApps

:Menu21Apps
if %_O21Access%==OFF if %_O21Excel%==OFF if %_OneNote%==OFF if %_O21Outlook%==OFF if %_O21PowerPoint%==OFF if %_O21Publisher%==OFF if %_O21SkypeForBusiness%==OFF if %_O21Word%==OFF if %_O21PrjPro%==OFF if %_O21PrjStd%==OFF if %_O21VisPro%==OFF if %_O21VisStd%==OFF set _O21Word=ON
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
echo %line%
echo Select Apps to install:
echo.
echo. A. Access 2021           : %_O21Access%
echo. E. Excel 2021            : %_O21Excel%
echo. N. OneNote 2016          : %_OneNote%
echo. O. Outlook 2021          : %_O21Outlook%
echo. P. PowerPoint 2021       : %_O21PowerPoint%
echo. R. Publisher 2021        : %_O21Publisher%
echo. S. SkypeForBusiness 2021 : %_O21SkypeForBusiness%
echo. W. Word 2021             : %_O21Word%
if %_supv%==1 (
echo.
echo. 5. Project Pro 2021      : %_O21PrjPro%
echo. 6. Project Standard 2021 : %_O21PrjStd%
echo. 7. Visio Pro 2021        : %_O21VisPro%
echo. 8. Visio Standard 2021   : %_O21VisStd%
)
echo.
echo. D. OneDrive Desktop      : %_OneDrive%
if not %_Teams%==0 echo. T. Microsoft Teams       : %_Teams%
echo %line%
choice /c AENOPRSWD567890TX /n /m "Change a menu option, press 0 to proceed, 9 to go back, or X to exit: "
set errortmp=%errorlevel%
if %errortmp%==17 goto :eof
if %errortmp%==16 if not %_Teams%==0 (if %_Teams%==ON (set _Teams=OFF) else (set _Teams=ON)&goto :Menu21Apps)
if %errortmp%==15 goto :Menu21App2
if %errortmp%==14 goto :MenuInitial
if %errortmp%==13 if %_supv%==1 (if %_O21VisStd%==ON (set _O21VisStd=OFF) else (set _O21VisPro=OFF&set _O21VisStd=ON)&goto :Menu21Apps)
if %errortmp%==12 if %_supv%==1 (if %_O21VisPro%==ON (set _O21VisPro=OFF) else (set _O21VisPro=ON&set _O21VisStd=OFF)&goto :Menu21Apps)
if %errortmp%==11 if %_supv%==1 (if %_O21PrjStd%==ON (set _O21PrjStd=OFF) else (set _O21PrjPro=OFF&set _O21PrjStd=ON)&goto :Menu21Apps)
if %errortmp%==10 if %_supv%==1 (if %_O21PrjPro%==ON (set _O21PrjPro=OFF) else (set _O21PrjPro=ON&set _O21PrjStd=OFF)&goto :Menu21Apps)
if %errortmp%==9 (if %_OneDrive%==ON (set _OneDrive=OFF) else (set _OneDrive=ON))&goto :Menu21Apps
if %errortmp%==8 (if %_O21Word%==ON (set _O21Word=OFF) else (set _O21Word=ON))&goto :Menu21Apps
if %errortmp%==7 (if %_O21SkypeForBusiness%==ON (set _O21SkypeForBusiness=OFF) else (set _O21SkypeForBusiness=ON))&goto :Menu21Apps
if %errortmp%==6 (if %_O21Publisher%==ON (set _O21Publisher=OFF) else (set _O21Publisher=ON))&goto :Menu21Apps
if %errortmp%==5 (if %_O21PowerPoint%==ON (set _O21PowerPoint=OFF) else (set _O21PowerPoint=ON))&goto :Menu21Apps
if %errortmp%==4 (if %_O21Outlook%==ON (set _O21Outlook=OFF) else (set _O21Outlook=ON))&goto :Menu21Apps
if %errortmp%==3 (if %_OneNote%==ON (set _OneNote=OFF) else (set _OneNote=ON))&goto :Menu21Apps
if %errortmp%==2 (if %_O21Excel%==ON (set _O21Excel=OFF) else (set _O21Excel=ON))&goto :Menu21Apps
if %errortmp%==1 (if %_O21Access%==ON (set _O21Access=OFF) else (set _O21Access=ON))&goto :Menu21Apps
goto :Menu21Apps

:MenuSuit2
set "_return=MenuSuite"
set "_suite="
set "_suit2="
for /l %%J in (1,1,20) do (
set "_sku%%J="
)
set "_pkey0="
for /l %%J in (1,1,20) do (
set "_pkey%%J="
)
set /a cc=0
set /a kk=0
if %_O365PP%==ON (
set _suite=O365ProPlusRetail&set _suit2=MondoVolume
set _pkey0=HFTND-W9MK4-8B7MJ-B6C4G-XQBR2
) else if %_O21Pro%==ON (
if %winbuild% lss 10240 (set _suite=O365ProPlusRetail&set _suit2=ProPlus2021Volume) else (set _suite=ProPlus2021Volume)
set _pkey0=FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH
) else if %_O21Std%==ON (
if %winbuild% lss 10240 (set _suite=StandardRetail&set _suit2=Standard2021Volume) else (set _suite=Standard2021Volume)
set _pkey0=KDX7X-BNVR8-TXXGX-4Q7Y8-78VT3
) else if %_O19Pro%==ON (
if %winbuild% lss 10240 (set _suite=O365ProPlusRetail&set _suit2=ProPlus2019Volume) else (set _suite=ProPlus2019Volume)
set _pkey0=NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP
) else if %_O19Std%==ON (
if %winbuild% lss 10240 (set _suite=StandardRetail&set _suit2=Standard2019Volume) else (set _suite=Standard2019Volume)
set _pkey0=6NWWJ-YQWMR-QKGCB-6TMB3-9D9HK
) else if %_Mondo%==ON (
set _suite=MondoVolume
set _pkey0=HFTND-W9MK4-8B7MJ-B6C4G-XQBR2
)
if %_O21PrjPro%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ProjectProRetail&set /a cc+=1&set _sku!cc!=ProjectPro2021Volume) else (set _sku!cc!=ProjectPro2021Volume)
set /a kk+=1
set _pkey!kk!=FTNWT-C6WBT-8HMGF-K9PRX-QV9H8
) else if %_O21PrjStd%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ProjectStdRetail&set /a cc+=1&set _sku!cc!=ProjectStd2021Volume) else (set _sku!cc!=ProjectStd2021Volume)
set /a kk+=1
set _pkey!kk!=J2JDC-NJCYY-9RGQ4-YXWMH-T3D4T
) else if %_O19PrjPro%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ProjectProRetail&set /a cc+=1&set _sku!cc!=ProjectPro2019Volume) else (set _sku!cc!=ProjectPro2019Volume)
set /a kk+=1
set _pkey!kk!=B4NPR-3FKK7-T2MBV-FRQ4W-PKD2B
) else if %_O19PrjStd%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ProjectStdRetail&set /a cc+=1&set _sku!cc!=ProjectStd2019Volume) else (set _sku!cc!=ProjectStd2019Volume)
set /a kk+=1
set _pkey!kk!=C4F7P-NCP8C-6CQPT-MQHV9-JXD2M
)
if %_O21VisPro%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=VisioProRetail&set /a cc+=1&set _sku!cc!=VisioPro2021Volume) else (set _sku!cc!=VisioPro2021Volume)
set /a kk+=1
set _pkey!kk!=KNH8D-FGHT4-T8RK3-CTDYJ-K2HT4
) else if %_O21VisStd%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=VisioStdRetail&set /a cc+=1&set _sku!cc!=VisioStd2021Volume) else (set _sku!cc!=VisioStd2021Volume)
set /a kk+=1
set _pkey!kk!=MJVNY-BYWPY-CWV6J-2RKRT-4M8QG
) else if %_O19VisPro%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=VisioProRetail&set /a cc+=1&set _sku!cc!=VisioPro2019Volume) else (set _sku!cc!=VisioPro2019Volume)
set /a kk+=1
set _pkey!kk!=9BGNQ-K37YR-RQHF2-38RQ3-7VCBB
) else if %_O19VisStd%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=VisioStdRetail&set /a cc+=1&set _sku!cc!=VisioStd2019Volume) else (set _sku!cc!=VisioStd2019Volume)
set /a kk+=1
set _pkey!kk!=7TQNQ-K3YQQ-3PFH7-CCPPM-X4VQ2
)
if defined _suite goto :MenuExclude
goto :MenuChannel

:MenuApp2
set "_return=MenuApps"
for /l %%J in (1,1,20) do (
set "_sku%%J="
)
set "_keys="
set "_pkey0="
for /l %%J in (1,1,20) do (
set "_pkey%%J="
)
set /a cc=0
set /a kk=0
if %_Access%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=AccessRetail&set /a cc+=1&set _sku!cc!=Access2019Volume) else (set _sku!cc!=Access2019Volume)
set /a kk+=1
set _pkey!kk!=9N9PT-27V4Y-VJ2PD-YXFMF-YTFQT
)
if %_Excel%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ExcelRetail&set /a cc+=1&set _sku!cc!=Excel2019Volume) else (set _sku!cc!=Excel2019Volume)
set /a kk+=1
set _pkey!kk!=TMJWT-YYNMB-3BKTF-644FC-RVXBD
)
if %_Outlook%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=OutlookRetail&set /a cc+=1&set _sku!cc!=Outlook2019Volume) else (set _sku!cc!=Outlook2019Volume)
set /a kk+=1
set _pkey!kk!=7HD7K-N4PVK-BHBCQ-YWQRW-XW4VK
)
if %_PowerPoint%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=PowerPointRetail&set /a cc+=1&set _sku!cc!=PowerPoint2019Volume) else (set _sku!cc!=PowerPoint2019Volume)
set /a kk+=1
set _pkey!kk!=RRNCX-C64HY-W2MM7-MCH9G-TJHMQ
)
if %_Publisher%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=PublisherRetail&set /a cc+=1&set _sku!cc!=Publisher2019Volume) else (set _sku!cc!=Publisher2019Volume)
set /a kk+=1
set _pkey!kk!=G2KWX-3NW6P-PY93R-JXK2T-C9Y9V
)
if %_SkypeForBusiness%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=SkypeForBusinessRetail&set /a cc+=1&set _sku!cc!=SkypeForBusiness2019Volume) else (set _sku!cc!=SkypeForBusiness2019Volume)
set /a kk+=1
set _pkey!kk!=NCJ33-JHBBY-HTK98-MYCV8-HMKHJ
)
if %_Word%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=WordRetail&set /a cc+=1&set _sku!cc!=Word2019Volume) else (set _sku!cc!=Word2019Volume)
set /a kk+=1
set _pkey!kk!=PBX3G-NWMT6-Q7XBW-PYJGG-WXD33
)
if %_OneNote%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=OneNoteRetail&set /a cc+=1&set _sku!cc!=OneNoteVolume) else (set _sku!cc!=OneNoteVolume)
set /a kk+=1
set _pkey!kk!=DR92N-9HTF2-97XKM-XW2WJ-XW3J6
)
if %_O19PrjPro%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ProjectProRetail&set /a cc+=1&set _sku!cc!=ProjectPro2019Volume) else (set _sku!cc!=ProjectPro2019Volume)
set /a kk+=1
set _pkey!kk!=B4NPR-3FKK7-T2MBV-FRQ4W-PKD2B
) else if %_O19PrjStd%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ProjectStdRetail&set /a cc+=1&set _sku!cc!=ProjectStd2019Volume) else (set _sku!cc!=ProjectStd2019Volume)
set /a kk+=1
set _pkey!kk!=C4F7P-NCP8C-6CQPT-MQHV9-JXD2M
)
if %_O19VisPro%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=VisioProRetail&set /a cc+=1&set _sku!cc!=VisioPro2019Volume) else (set _sku!cc!=VisioPro2019Volume)
set /a kk+=1
set _pkey!kk!=9BGNQ-K37YR-RQHF2-38RQ3-7VCBB
) else if %_O19VisStd%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=VisioStdRetail&set /a cc+=1&set _sku!cc!=VisioStd2019Volume) else (set _sku!cc!=VisioStd2019Volume)
set /a kk+=1
set _pkey!kk!=7TQNQ-K3YQQ-3PFH7-CCPPM-X4VQ2
)
goto :MenuChannel

:Menu21App2
set "_return=Menu21Apps"
for /l %%J in (1,1,20) do (
set "_sku%%J="
)
set "_keys="
set "_pkey0="
for /l %%J in (1,1,20) do (
set "_pkey%%J="
)
set /a cc=0
set /a kk=0
if %_O21Access%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=AccessRetail&set /a cc+=1&set _sku!cc!=Access2021Volume) else (set _sku!cc!=Access2021Volume)
set /a kk+=1
set _pkey!kk!=WM8YG-YNGDD-4JHDC-PG3F4-FC4T4
)
if %_O21Excel%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ExcelRetail&set /a cc+=1&set _sku!cc!=Excel2021Volume) else (set _sku!cc!=Excel2021Volume)
set /a kk+=1
set _pkey!kk!=NWG3X-87C9K-TC7YY-BC2G7-G6RVC
)
if %_O21Outlook%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=OutlookRetail&set /a cc+=1&set _sku!cc!=Outlook2021Volume) else (set _sku!cc!=Outlook2021Volume)
set /a kk+=1
set _pkey!kk!=C9FM6-3N72F-HFJXB-TM3V9-T86R9
)
if %_O21PowerPoint%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=PowerPointRetail&set /a cc+=1&set _sku!cc!=PowerPoint2021Volume) else (set _sku!cc!=PowerPoint2021Volume)
set /a kk+=1
set _pkey!kk!=TY7XF-NFRBR-KJ44C-G83KF-GX27K
)
if %_O21Publisher%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=PublisherRetail&set /a cc+=1&set _sku!cc!=Publisher2021Volume) else (set _sku!cc!=Publisher2021Volume)
set /a kk+=1
set _pkey!kk!=2MW9D-N4BXM-9VBPG-Q7W6M-KFBGQ
)
if %_O21SkypeForBusiness%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=SkypeForBusinessRetail&set /a cc+=1&set _sku!cc!=SkypeForBusiness2021Volume) else (set _sku!cc!=SkypeForBusiness2021Volume)
set /a kk+=1
set _pkey!kk!=HWCXN-K3WBT-WJBKY-R8BD9-XK29P
)
if %_O21Word%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=WordRetail&set /a cc+=1&set _sku!cc!=Word2021Volume) else (set _sku!cc!=Word2021Volume)
set /a kk+=1
set _pkey!kk!=TN8H9-M34D3-Y64V9-TR72V-X79KV
)
if %_OneNote%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=OneNoteRetail&set /a cc+=1&set _sku!cc!=OneNoteVolume) else (set _sku!cc!=OneNoteVolume)
set /a kk+=1
set _pkey!kk!=DR92N-9HTF2-97XKM-XW2WJ-XW3J6
)
if %_O21PrjPro%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ProjectProRetail&set /a cc+=1&set _sku!cc!=ProjectPro2021Volume) else (set _sku!cc!=ProjectPro2021Volume)
set /a kk+=1
set _pkey!kk!=FTNWT-C6WBT-8HMGF-K9PRX-QV9H8
) else if %_O21PrjStd%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ProjectStdRetail&set /a cc+=1&set _sku!cc!=ProjectStd2021Volume) else (set _sku!cc!=ProjectStd2021Volume)
set /a kk+=1
set _pkey!kk!=J2JDC-NJCYY-9RGQ4-YXWMH-T3D4T
)
if %_O21VisPro%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=VisioProRetail&set /a cc+=1&set _sku!cc!=VisioPro2021Volume) else (set _sku!cc!=VisioPro2021Volume)
set /a kk+=1
set _pkey!kk!=KNH8D-FGHT4-T8RK3-CTDYJ-K2HT4
) else if %_O21VisStd%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=VisioStdRetail&set /a cc+=1&set _sku!cc!=VisioStd2021Volume) else (set _sku!cc!=VisioStd2021Volume)
set /a kk+=1
set _pkey!kk!=MJVNY-BYWPY-CWV6J-2RKRT-4M8QG
)
goto :MenuChannel

:MenuExclude
if %_O21Std%==ON (
set _Access=OFF
set _Lync=OFF
) else if %_O19Std%==ON (
set _Access=OFF
set _Lync=OFF
)
if %_Mondo%==OFF (
set _Project=OFF
set _Visio=OFF
)
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
if %_O21Std%==OFF (
echo. A. Access           : %_Access%
) else if %_O19Std%==OFF (
echo. A. Access           : %_Access%
)
echo. E. Excel            : %_Excel%
echo. N. OneNote          : %_OneNote%
echo. O. Outlook          : %_Outlook%
echo. P. PowerPoint       : %_PowerPoint%
echo. R. Publisher        : %_Publisher%
if %_O21Std%==OFF (
echo. S. SkypeForBusiness : %_Lync%
) else if %_O19Std%==OFF (
echo. S. SkypeForBusiness : %_Lync%
)
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
if errorlevel 13 goto :MenuExcluded
if errorlevel 12 goto :MenuSuite
if errorlevel 11 (if %_OneDrive%==ON (set _OneDrive=OFF) else (set _OneDrive=ON))&goto :MenuExclude
if errorlevel 10 (if %_Mondo%==ON (if %_Visio%==ON (set _Visio=OFF) else (set _Visio=ON)))&goto :MenuExclude
if errorlevel 9 (if %_Mondo%==ON (if %_Project%==ON (set _Project=OFF) else (set _Project=ON)))&goto :MenuExclude
if errorlevel 8 (if %_Word%==ON (set _Word=OFF) else (set _Word=ON))&goto :MenuExclude
if errorlevel 7 (if %_O21Std%==OFF if %_O19Std%==OFF (if %_Lync%==ON (set _Lync=OFF) else (set _Lync=ON)))&goto :MenuExclude
if errorlevel 6 (if %_Publisher%==ON (set _Publisher=OFF) else (set _Publisher=ON))&goto :MenuExclude
if errorlevel 5 (if %_PowerPoint%==ON (set _PowerPoint=OFF) else (set _PowerPoint=ON))&goto :MenuExclude
if errorlevel 4 (if %_Outlook%==ON (set _Outlook=OFF) else (set _Outlook=ON))&goto :MenuExclude
if errorlevel 3 (if %_OneNote%==ON (set _OneNote=OFF) else (set _OneNote=ON))&goto :MenuExclude
if errorlevel 2 (if %_Excel%==ON (set _Excel=OFF) else (set _Excel=ON))&goto :MenuExclude
if errorlevel 1 (if %_O21Std%==OFF if %_O19Std%==OFF (if %_Access%==ON (set _Access=OFF) else (set _Access=ON)))&goto :MenuExclude
goto :MenuExclude

:MenuExcluded
set "_excluded=Groove"
for %%J in (Access,Excel,Lync,OneDrive,OneNote,Outlook,PowerPoint,Publisher,Teams,Word) do (
if !_%%J!==OFF set "_excluded=!_excluded!,%%J"
)
if %_Mondo%==ON for %%J in (Project,Visio) do (
if !_%%J!==OFF set "_excluded=!_excluded!,%%J"
)
goto :MenuChannel

:MenuChannel
if %_C19%==1 goto :Chn19
if %_C21%==1 goto :Chn21
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
echo. 7. DevMain Channel                     ^|    Dogfood::DevMain
echo. 8. Microsoft Elite                     ^|  Microsoft::DevMain
echo %line%
choice /c 1234567809X /n /m "Choose a menu option to proceed, press 9 to go back, or X to exit: "
if errorlevel 11 goto :eof
if errorlevel 10 goto :%_return%
if errorlevel 9 (set inpt=0&goto :MenuChn)
if errorlevel 8 (set inpt=8&goto :MenuChn)
if errorlevel 7 (set inpt=7&goto :MenuChn)
if errorlevel 6 (set inpt=6&goto :MenuChn)
if errorlevel 5 (set inpt=5&goto :MenuChn)
if errorlevel 4 (set inpt=4&goto :MenuChn)
if errorlevel 3 (set inpt=3&goto :MenuChn)
if errorlevel 2 (set inpt=2&goto :MenuChn)
if errorlevel 1 (set inpt=1&goto :MenuChn)
goto :MenuChannel

:Chn19
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
echo. 1. Perpetual2019 VL                    ^| Production::LTSC
echo. 2. Microsoft2019 VL                    ^|  Microsoft::LTSC
echo.
echo %line%
choice /c 1209X /n /m "Choose a menu option to proceed, press 9 to go back, or X to exit: "
if errorlevel 5 goto :eof
if errorlevel 4 goto :%_return%
if errorlevel 3 (set inpt=0&goto :MenuChn)
if errorlevel 2 (set inpt=10&goto :MenuChn)
if errorlevel 1 (set inpt=9&goto :MenuChn)
goto :MenuChannel

:Chn21
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
echo. 1. Perpetual2021 VL                    ^| Production::LTSC2021
echo. 2. Microsoft2021 VL                    ^|  Microsoft::LTSC2021
echo.
echo %line%
choice /c 1209X /n /m "Choose a menu option to proceed, press 9 to go back, or X to exit: "
if errorlevel 5 goto :eof
if errorlevel 4 goto :%_return%
if errorlevel 3 (set inpt=0&goto :MenuChn)
if errorlevel 2 (set inpt=12&goto :MenuChn)
if errorlevel 1 (set inpt=11&goto :MenuChn)
goto :MenuChannel

:MenuChn
if %inpt%==0 (
set inpt=3
if not "!FFNRoot!"=="" for /l %%J in (1,1,12) do (
  if /i "!FFNRoot!"=="!ffn%%J!" set inpt=%%J
  )
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
if /i "!_tmp:~-6!"=="Volume" if %winbuild% geq 10240 (
  if defined _show (set "_show=!_show!,%%J") else (set "_show=%%J")
  if defined _products (set "_products=!_products!^|%%J.16_%CTRlng%_x-none") else (set "_products=%%J.16_%CTRlng%_x-none")
  if %_OneDrive%==OFF (if defined _exclude1d (set "_exclude1d=!_exclude1d! %%J.excludedapps.16=onedrive") else (set "_exclude1d=%%J.excludedapps.16=onedrive"))
  )
if /i "!_tmp:~-6!"=="Volume" if %winbuild% lss 10240 (
  if defined _show (set "_show=!_show!,%%J") else (set "_show=%%J")
  if defined _licenses (set "_licenses=!_licenses!,%%J") else (set "_licenses=%%J")
  )
if /i "!_tmp:~-6!"=="Retail" if %winbuild% lss 10240 (
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
choice /c 123456709X /n /m "Change a menu option, press 0 to proceed, 9 to go back, or X to exit: "
if errorlevel 10 goto :eof
if errorlevel 9 goto :MenuChannel
if errorlevel 8 goto :MenuFinal
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
echo Disable Telemetry: %_tele%
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
if %winbuild% lss 22483 for /f "tokens=2 delims==." %%# in ('wmic os get localdatetime /value') do set "_date=%%#"
if %winbuild% geq 22483 for /f "tokens=1 delims=." %%# in ('powershell -nop -c "([WMI]'Win32_OperatingSystem=@').LocalDateTime"') do set "_date=%%#"
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
set "_url=http://officecdn.microsoft.com/db"

(
echo @echo off
echo reg.exe query "HKU\S-1-5-19" 1^>nul 2^>nul ^|^| ^(echo Run the script as administrator^&pause^&exit /b^)
echo reg.exe delete %_Config% /f /v UpdateUrl 1^>nul 2^>nul
echo reg.exe delete %_Config% /f /v UpdateToVersion 1^>nul 2^>nul
echo reg.exe delete %_CTR%\Updates /f /v UpdateToVersion 1^>nul 2^>nul
echo reg.exe delete HKLM\SOFTWARE\Policies\Microsoft\Office\16.0\Common\OfficeUpdate /f 1^>nul 2^>nul
echo reg.exe add HKLM\SOFTWARE\Policies\Microsoft\Office\16.0\Common\OfficeUpdate /f /v PreventBingInstall /t REG_DWORD /d 1 1^>nul 2^>nul
echo reg.exe add HKCU\software\Policies\Microsoft\Office\16.0\Teams /f /v PreventFirstLaunchAfterInstall /t REG_DWORD /d 1 1^>nul 2^>nul
echo start "" /WAIT "%%CommonProgramFiles%%\Microsoft Shared\ClickToRun\OfficeClickToRun.exe" ^^
echo deliverymechanism=%CTRffn% platform=%CTRarc% culture=%CTRstp% b= displaylevel=%_disp% ^^
echo forceappshutdown=%_shut% piniconstotaskbar=%_icon% acceptalleulas.16=%_eula% ^^
echo updatesenabled.16=%_updt% updatepromptuser=True ^^
echo updatebaseurl.16=%_url%/%CTRffn% ^^
echo cdnbaseurl.16=%_url%/%CTRffn% ^^
echo mediatype.16=%CTRtype% sourcetype.16=%CTRtype% version.16=%CTRver% ^^
echo baseurl.16="!CTRsource!" ^^^^
echo productstoadd="%_products%" ^^
if %winbuild% geq 10240 echo pidkeys=%_keys% %_autoact% ^^
if %winbuild% lss 10240 if /i "%_suite%"=="MondoVolume" echo pidkeys=HFTND-W9MK4-8B7MJ-B6C4G-XQBR2 %_autoact% ^^
if defined _suite echo %_suite%.excludedapps.16=%_excluded% ^^
if defined _exclude1d echo %_exclude1d% ^^
echo flt.useexptransportinplacepl=disabled flt.useofficehelperaddon=disabled flt.useoutlookshareaddon=disabled 1^>nul 2^>nul
echo reg.exe add %_Config% /f /v UpdateChannel /t REG_SZ /d "%_url%/%CTRffn%" 1^>nul 2^>nul
echo reg.exe add %_Config% /f /v UpdateChannelChanged /t REG_SZ /d True 1^>nul 2^>nul
echo exit /b
)>"!_temp!\C2R_Setup.bat"

set "CTRexe=1"
set "cfile=!_file:\=\\!"
if exist "!_file!" if %winbuild% lss 22483 for /f "tokens=4 delims==." %%i in ('wmic datafile where "name='!cfile!'" get Version /value ^| find "="') do (
  if %%i geq %verchk% (set CTRexe=0)
)
if exist "!_file!" if %winbuild% geq 22483 for /f "tokens=3 delims==." %%i in ('powershell -nop -c "([WMI]'CIM_DataFile.Name=\"!cfile!\"').Version"') do (
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
