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
set "Path=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%SystemRoot%\Sysnative;%SystemRoot%;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)
set "_psc=powershell -nop -c"
set "_err===== ERROR ===="
set winbuild=1
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
if %winbuild% lss 7601 goto :E_Win
set _cwmi=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
cmd /c "wmic path Win32_ComputerSystem get CreationClassName /value" 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
)
set _pwsh=1
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" set _pwsh=0
if %_cwmi% equ 0 if %_pwsh% equ 0 goto :E_WMI
reg query HKU\S-1-5-19 >nul 2>&1 || goto :E_Admin
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
set "_ini=%~dp0"
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%SystemDrive%\Users\Public\Desktop\desktop.ini" set "_dsk=%SystemDrive%\Users\Public\Desktop"

@title Office Click-to-Run Configurator - Retail
setlocal EnableDelayedExpansion
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
f3260cf1-a92c-4c75-b02e-d64c0a86a968
834504cc-dc55-4c6d-9e71-e024d0253f6d
c4a7726f-06ea-48e2-a13a-9d78849eb706
5462eee5-1e97-495b-9370-853cd873bb07
9a3b7ff2-58ed-40fd-add5-1e5158059d1c
f4f024c8-d611-4748-a7e0-02b6e754c0fe
f2e724c1-748f-4b47-8fb8-8e0d210e9208
1d2d2ea6-1680-4c56-ac58-a441c8c24ff9
5030841d-c919-4594-8d2d-84ae4f96e58e
86752282-5841-4120-ac80-db03ae6b5fdb
7983bac0-e531-40cf-be00-fd24fe66619c
c02d8fe6-5242-4da8-972f-82ee55e00671
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
DogfoodMonthly
DogfoodSemiAnnualPreview
DogfoodSemiAnnual
MicrosoftMonthly
MicrosoftSemiAnnualPreview
MicrosoftSemiAnnual
PerpetualVL2019
MicrosoftLTSC
PerpetualVL2021
MicrosoftLTSC2021
PerpetualVL2024
MicrosoftLTSC2024
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
for /l %%J in (1,1,%vvv%) do (
echo. %%J. !CTRver%%J!
)
echo.
echo %line%
set errlvl=0
choice /c 123456789X /n /m "Choose a version to proceed, or press X to exit: "
set errlvl=%errorlevel%
if %errlvl%==10 goto :eof
if %errlvl%==9 if %vvv% geq 9 (set inpt=9&goto :MenuVersion2)
if %errlvl%==8 if %vvv% geq 8 (set inpt=8&goto :MenuVersion2)
if %errlvl%==7 if %vvv% geq 7 (set inpt=7&goto :MenuVersion2)
if %errlvl%==6 if %vvv% geq 6 (set inpt=6&goto :MenuVersion2)
if %errlvl%==5 if %vvv% geq 5 (set inpt=5&goto :MenuVersion2)
if %errlvl%==4 if %vvv% geq 4 (set inpt=4&goto :MenuVersion2)
if %errlvl%==3 if %vvv% geq 3 (set inpt=3&goto :MenuVersion2)
if %errlvl%==2 (set inpt=2&goto :MenuVersion2)
if %errlvl%==1 (set inpt=1&goto :MenuVersion2)
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
set errlvl=0
choice /c 12X /n /m "Choose an architecture to proceed, or press X to exit: "
set errlvl=%errorlevel%
if %errlvl%==3 goto :eof
if %errlvl%==2 (set "win64=0"&set "CTRarc=x86"&goto :MenuArch2)
if %errlvl%==1 (set "wow64=0"&set "CTRarc=x64"&goto :MenuArch2)
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
echo. 0. All
for /l %%J in (1,1,%int%) do (
echo. %%J. !zlng%%J!
)
echo.
echo %line%
set errlvl=0
choice /c 1234567890X /n /m "Choose language(s) to proceed, or press X to exit: "
set errlvl=%errorlevel%
if %errlvl%==11 goto :eof
if %errlvl%==10 goto :MenuLangM
if %errlvl%==9 if %int% geq 9 (set inpt=9&goto :MenuLang2)
if %errlvl%==8 if %int% geq 8 (set inpt=8&goto :MenuLang2)
if %errlvl%==7 if %int% geq 7 (set inpt=7&goto :MenuLang2)
if %errlvl%==6 if %int% geq 6 (set inpt=6&goto :MenuLang2)
if %errlvl%==5 if %int% geq 5 (set inpt=5&goto :MenuLang2)
if %errlvl%==4 if %int% geq 4 (set inpt=4&goto :MenuLang2)
if %errlvl%==3 if %int% geq 3 (set inpt=3&goto :MenuLang2)
if %errlvl%==2 (set inpt=2&goto :MenuLang2)
if %errlvl%==1 (set inpt=1&goto :MenuLang2)
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
set CTRlng=%lng32%&set CTRcul=%cul32%&set CTRvcab=v32_%CTRver%.cab&set CTRicab=i320.cab&set CTRicabr=i32%cul32%.cab&set CTRscab=s320.cab
)
if %wow64%==1 (
set CTRlng=%lng32%&set CTRcul=%cul32%&set CTRvcab=v32_%CTRver%.cab&set CTRicab=i640.cab&set CTRicabr=i64%cul32%.cab&set CTRscab=s320.cab
)
if %win64%==1 (
set CTRlng=%lng64%&set CTRcul=%cul64%&set CTRvcab=v64_%CTRver%.cab&set CTRicab=i640.cab&set CTRicabr=i64%cul64%.cab&set CTRscab=s640.cab
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
for /l %%J in (1,1,%int%) do (
echo. %%J. !zlng%%J!
)
echo.
echo %line%
set errlvl=0
choice /c 123456789X /n /m "Choose primary language to proceed, or press X to exit: "
set errlvl=%errorlevel%
if %errlvl%==10 goto :eof
if %errlvl%==9 if %int% geq 9 (set inpt=9&goto :MenuLangM2)
if %errlvl%==8 if %int% geq 8 (set inpt=8&goto :MenuLangM2)
if %errlvl%==7 if %int% geq 7 (set inpt=7&goto :MenuLangM2)
if %errlvl%==6 if %int% geq 6 (set inpt=6&goto :MenuLangM2)
if %errlvl%==5 if %int% geq 5 (set inpt=5&goto :MenuLangM2)
if %errlvl%==4 if %int% geq 4 (set inpt=4&goto :MenuLangM2)
if %errlvl%==3 if %int% geq 3 (set inpt=3&goto :MenuLangM2)
if %errlvl%==2 (set inpt=2&goto :MenuLangM2)
if %errlvl%==1 (set inpt=1&goto :MenuLangM2)
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
set CTRvcab=v32_%CTRver%.cab&set CTRicab=i320.cab&set CTRicabr=i32%CTRprm%.cab&set CTRscab=s320.cab
)
if %wow64%==1 (
set CTRvcab=v32_%CTRver%.cab&set CTRicab=i640.cab&set CTRicabr=i64%CTRprm%.cab&set CTRscab=s320.cab
)
if %win64%==1 (
set CTRvcab=v64_%CTRver%.cab&set CTRicab=i640.cab&set CTRicabr=i64%CTRprm%.cab&set CTRscab=s640.cab
)

:XmlCheck
set _O2019=1
set _O2021=1
set _O2024=1
set _D24PF=1
set _D24ST=1
set _D24SB=1
if %verchk% lss 14026 set _O2021=0
if %verchk% lss 17101 set _O2024=0
del /f /q "!_temp!\*.xml" "!_temp!\*.dat" 1>nul 2>nul
expand.exe -f:*.xml "!CTRsource!\Office\Data\%CTRvcab%" "!_temp!." 1>nul 2>nul
expand.exe -f:*.xml "!CTRsource!\Office\Data\%CTRver%\%CTRscab%" "!_temp!." 1>nul 2>nul
expand.exe -f:*.x-none.man.dat "!CTRsource!\Office\Data\%CTRver%\%CTRscab%" "!_temp!." 1>nul 2>nul
pushd "!_temp!"
find /i "Word2019Volume" "VersionDescriptor.xml" 1>nul 2>nul || set _O2019=0
find /i "Word2021Volume" "MasterDescriptor.x-none.xml" 1>nul 2>nul || set _O2021=0
find /i "Word2024Volume" "MasterDescriptor.x-none.xml" 1>nul 2>nul || set _O2024=0
if exist "*.x-none.man.dat" (
findstr /r "W.o.r.d.2.0.2.1.V.L._.K.M.S." *x-none.man.dat >nul || set _O2021=0
findstr /r "W.o.r.d.2.0.2.4.V.L._.K.M.S." *x-none.man.dat >nul || set _O2024=0
)
if exist "*.x-none.man.dat" if %_O2024%==1 (
findstr /r "P.r.o.f.e.s.s.i.o.n.a.l.2.0.2.4.R._.R.e.t.a.i.l." *x-none.man.dat >nul || set _D24PF=0
findstr /r "S.t.a.n.d.a.r.d.2.0.2.4.R._.R.e.t.a.i.l." *x-none.man.dat >nul || set _D24ST=0
findstr /r "S.k.y.p.e.f.o.r.B.u.s.i.n.e.s.s.2.0.2.4.R._.R.e.t.a.i.l." *x-none.man.dat >nul || set _D24SB=0
)
for /f "tokens=3 delims=<= " %%# in ('find /i "DeliveryMechanism" "VersionDescriptor.xml" 2^>nul') do set "FFNRoot=%%~#"
popd
del /f /q "!_temp!\*.xml" "!_temp!\*.dat" 1>nul 2>nul
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
set _C19=0
if not "!FFNRoot!"=="" for %%J in (15,16) do (
  if /i "!FFNRoot!"=="!ffn%%J!" set _C19=1&set _WRvl=1
)
set _C21=0
if not "!FFNRoot!"=="" for %%J in (17,18) do (
  if /i "!FFNRoot!"=="!ffn%%J!" set _C21=1&set _WRvl=1
)
set _C24=0
if not "!FFNRoot!"=="" for %%J in (19,20) do (
  if /i "!FFNRoot!"=="!ffn%%J!" set _C24=1&set _WRvl=1
)
set _WRnc=0
if %winbuild% geq 7600 if %winbuild% lss 8200 (
set "_OSdsc=Windows 7"
if %verchk% gtr 12527 set _WRnc=1
)
if %winbuild% geq 9600 if %winbuild% lss 9900 (
set "_OSdsc=Windows 8.1"
if %verchk% gtr 16207 set _WRnc=1
)
if defined _WRvl if %winbuild% lss 10240 set _WRnc=1
goto :MenuInitial

:showPV
for %%# in (16,19,21,24) do (
if !_O%%#PrjPro!==OFF (set "_opt%%#PP=OFF") else (set "_opt%%#PP=ON ")
if !_O%%#PrjStd!==OFF (set "_opt%%#PS=OFF") else (set "_opt%%#PS=ON ")
if !_O%%#VisPro!==OFF (set "_opt%%#VP=OFF") else (set "_opt%%#VP=ON ")
if !_O%%#VisStd!==OFF (set "_opt%%#VS=OFF") else (set "_opt%%#VS=ON ")
)
exit /b

:MenuInitial
set "_return=Menu365Suite"
set _O2016=0
set _ON21=0
set _OneDrive=OFF
set _Access=ON
set _Excel=ON
set _Lync=ON
set _OneNote=ON
set _Outlook=ON
set _PowerPoint=ON
set _Publisher=ON
set _Word=ON
set _O19Access=ON
set _O19Excel=ON
set _O16OneNote=ON
set _O19Outlook=ON
set _O19PowerPoint=ON
set _O19Publisher=ON
set _O19SkypeForBusiness=ON
set _O19Word=ON
set _O21Access=ON
set _O21Excel=ON
set _O21OneNote=ON
set _O21Outlook=ON
set _O21PowerPoint=ON
set _O21Publisher=ON
set _O21SkypeForBusiness=ON
set _O21Word=ON
set _O24Access=ON
set _O24Excel=ON
set _O24Outlook=ON
set _O24PowerPoint=ON
set _O24SkypeForBusiness=OFF
if %_D24SB%==1 set _O24SkypeForBusiness=ON
set _O24Word=ON
set _O365Pro=ON
set _O365Bus=OFF
set _O365Edu=OFF
set _O365Hom=OFF
set _O365Sma=OFF
set _O16Pro=ON
set _O16Prf=OFF
set _O16Std=OFF
set _O16HmBu=OFF
set _O16HmSt=OFF
set _O16PrjPro=OFF
set _O16PrjStd=OFF
set _O16VisPro=OFF
set _O16VisStd=OFF
set _O19Pro=ON
set _O19Prf=OFF
set _O19Std=OFF
set _O19HmBu=OFF
set _O19HmSt=OFF
set _O19PrjPro=OFF
set _O19PrjStd=OFF
set _O19VisPro=OFF
set _O19VisStd=OFF
set _O21Pro=ON
set _O21Prf=OFF
set _O21Std=OFF
set _O21HmBu=OFF
set _O21HmSt=OFF
set _O21PrjPro=OFF
set _O21PrjStd=OFF
set _O21VisPro=OFF
set _O21VisStd=OFF
set _O24Pro=ON
set _O24Prf=OFF
set _O24Std=OFF
set _O24HmBu=OFF
set _O24HmSt=OFF
set _O24PrjPro=OFF
set _O24PrjStd=OFF
set _O24VisPro=OFF
set _O24VisStd=OFF
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
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
echo %line%
echo.
echo. 1. Install Microsoft 365 Suite
echo. 2. Install Office 2016 Suite
if %_O2019%==1 (
echo. 3. Install Office 2019 Suite
echo. 4. Install Office 2019 Single Apps
)
if %_O2021%==1 (
echo. 5. Install Office 2021 Suite
echo. 6. Install Office 2021 Single Apps
)
if %_O2024%==1 (
echo. 7. Install Office 2024 Suite
echo. 8. Install Office 2024 Single Apps
)
if %_WRnc%==1 (
echo.
echo ==== ^^!^^! WARNING ^^!^^! ====
echo.
if defined _WRvl (
echo Detected Office source files are originated from a Volume LTSC channel.
) else (
echo Detected Office version %CTRver% is higher than the official range.
)
echo This build is not fully compatible with current OS %_OSdsc%
echo Office programs may not work correctly, and installation may fail.
) else if defined _WRvl (
echo.
echo ==== ^^!^^! WARNING ^^!^^! ====
echo.
echo Detected Office source files are originated from a Volume LTSC channel.
echo It is not recommended to install Retail products.
)
echo.
echo %line%
set errlvl=0
choice /c 12345678X /n /m "Choose a menu option to proceed, or press X to exit: "
set errlvl=%errorlevel%
if %errlvl%==9 goto :eof
if %errlvl%==8 (if %_O2024%==1 (set xv=24&goto :Menu00Apps) else (goto :MenuInitial))
if %errlvl%==7 (if %_O2024%==1 (set xv=24&goto :Menu00Suite) else (goto :MenuInitial))
if %errlvl%==6 (if %_O2021%==1 (set xv=21&goto :Menu00Apps) else (goto :MenuInitial))
if %errlvl%==5 (if %_O2021%==1 (set xv=21&goto :Menu00Suite) else (goto :MenuInitial))
if %errlvl%==4 (if %_O2019%==1 (set xv=19&goto :Menu00Apps) else (goto :MenuInitial))
if %errlvl%==3 (if %_O2019%==1 (set xv=19&goto :Menu00Suite) else (goto :MenuInitial))
if %errlvl%==2 (set xv=16&goto :Menu00Suite)
if %errlvl%==1 goto :Menu365Suite
goto :MenuInitial

:Menu365Suite
if %_O365Pro%==OFF if %_O365Bus%==OFF if %_O365Edu%==OFF if %_O365Hom%==OFF if %_O365Sma%==OFF set _O365Pro=ON
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
echo %line%
echo Select Products to Install:
echo.
echo. 1. Microsoft 365 Enterprise     : %_O365Pro%
echo. 2. Microsoft 365 Business       : %_O365Bus%
echo. 3. Microsoft 365 Small Business : %_O365Sma%
echo. 4. Microsoft 365 Family         : %_O365Hom%
echo. 5. Microsoft 365 Education      : %_O365Edu%
if %_supv%==1 (
echo.
echo. 6. Project Online Desktop Client: %_O16PrjPro%
echo. 7. Visio Online Plan 2          : %_O16VisPro%
)
echo.
echo %line%
set errlvl=0
choice /c 12345670BX /n /m "Change a menu option, press 0 to proceed, B to go back, or X to exit: "
set errlvl=%errorlevel%
if %errlvl%==10 goto :eof
if %errlvl%==9 goto :MenuInitial
if %errlvl%==8 goto :Menu365SuiteB
if %errlvl%==7 if %_supv%==1 (if %_O16VisPro%==ON (set _O16VisPro=OFF) else (set _O16VisPro=ON&set _O16VisStd=OFF)&goto :Menu365Suite)
if %errlvl%==6 if %_supv%==1 (if %_O16PrjPro%==ON (set _O16PrjPro=OFF) else (set _O16PrjPro=ON&set _O16PrjStd=OFF)&goto :Menu365Suite)
if %errlvl%==5 (if %_O365Edu%==ON (set _O365Edu=OFF) else (set _O365Edu=ON&set _O365Bus=OFF&set _O365Pro=OFF&set _O365Hom=OFF&set _O365Sma=OFF))&goto :Menu365Suite
if %errlvl%==4 (if %_O365Hom%==ON (set _O365Hom=OFF) else (set _O365Hom=ON&set _O365Bus=OFF&set _O365Pro=OFF&set _O365Edu=OFF&set _O365Sma=OFF))&goto :Menu365Suite
if %errlvl%==3 (if %_O365Sma%==ON (set _O365Sma=OFF) else (set _O365Sma=ON&set _O365Bus=OFF&set _O365Pro=OFF&set _O365Edu=OFF&set _O365Hom=OFF))&goto :Menu365Suite
if %errlvl%==2 (if %_O365Bus%==ON (set _O365Bus=OFF) else (set _O365Bus=ON&set _O365Pro=OFF&set _O365Edu=OFF&set _O365Hom=OFF&set _O365Sma=OFF))&goto :Menu365Suite
if %errlvl%==1 (if %_O365Pro%==ON (set _O365Pro=OFF) else (set _O365Pro=ON&set _O365Bus=OFF&set _O365Edu=OFF&set _O365Hom=OFF&set _O365Sma=OFF))&goto :Menu365Suite
goto :Menu365Suite

:Menu00Suite
set _optPF=1
set _optST=1
if %xv% EQU 24 (
set _optPF=%_D24PF%
set _optST=%_D24ST%
set "_optHome=20%xv%            "
) else (
set "_optHome=and Student 20%xv%"
)
if !_O%xv%Pro!==OFF if !_O%xv%Prf!==OFF if !_O%xv%Std!==OFF if !_O%xv%HmBu!==OFF if !_O%xv%HmSt!==OFF set _O%xv%Pro=ON
call :showPV
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
echo %line%
echo Select Products to Install:
echo.
echo. 1. Office Professional Plus 20%xv% : !_O%xv%Pro!
if %_optPF%==1 (
echo. 2. Office Professional 20%xv%      : !_O%xv%Prf!
) else (echo.)
if %_optST%==1 (
echo. 3. Office Standard 20%xv%          : !_O%xv%Std!
) else (echo.)
echo. 4. Office Home and Business 20%xv% : !_O%xv%HmBu!
echo. 5. Office Home %_optHome%  : !_O%xv%HmSt!
if %_supv%==1 (
echo.
echo. 6. Project Pro 20%xv%: !_opt%xv%PP!   #   7. Project Standard 20%xv%: !_opt%xv%PS!
echo. 8. Visio Pro 20%xv%  : !_opt%xv%VP!   #   9. Visio Standard 20%xv%  : !_opt%xv%VS!
)
echo.
echo %line%
set errlvl=0
choice /c 1234567890BX /n /m "Change a menu option, press 0 to proceed, B to go back, or X to exit: "
set errlvl=%errorlevel%
if %errlvl%==12 goto :eof
if %errlvl%==11 goto :MenuInitial
if %errlvl%==10 goto :Menu%xv%SuiteB
if %errlvl%==9 if %_supv%==1 (if !_O%xv%VisStd!==ON (set _O%xv%VisStd=OFF) else (set _O%xv%VisStd=ON&set _O%xv%VisPro=OFF)&goto :Menu00Suite)
if %errlvl%==8 if %_supv%==1 (if !_O%xv%VisPro!==ON (set _O%xv%VisPro=OFF) else (set _O%xv%VisPro=ON&set _O%xv%VisStd=OFF)&goto :Menu00Suite)
if %errlvl%==7 if %_supv%==1 (if !_O%xv%PrjStd!==ON (set _O%xv%PrjStd=OFF) else (set _O%xv%PrjStd=ON&set _O%xv%PrjPro=OFF)&goto :Menu00Suite)
if %errlvl%==6 if %_supv%==1 (if !_O%xv%PrjPro!==ON (set _O%xv%PrjPro=OFF) else (set _O%xv%PrjPro=ON&set _O%xv%PrjStd=OFF)&goto :Menu00Suite)
if %errlvl%==5 (if !_O%xv%HmSt!==ON (set _O%xv%HmSt=OFF) else (set _O%xv%HmSt=ON&set _O%xv%Prf=OFF&set _O%xv%Pro=OFF&set _O%xv%Std=OFF&set _O%xv%HmBu=OFF))&goto :Menu00Suite
if %errlvl%==4 (if !_O%xv%HmBu!==ON (set _O%xv%HmBu=OFF) else (set _O%xv%HmBu=ON&set _O%xv%Prf=OFF&set _O%xv%Pro=OFF&set _O%xv%Std=OFF&set _O%xv%HmSt=OFF))&goto :Menu00Suite
if %errlvl%==3 if %_optST%==1 (if !_O%xv%Std!==ON (set _O%xv%Std=OFF) else (set _O%xv%Std=ON&set _O%xv%Prf=OFF&set _O%xv%Pro=OFF&set _O%xv%HmBu=OFF&set _O%xv%HmSt=OFF))&goto :Menu00Suite
if %errlvl%==2 if %_optPF%==1 (if !_O%xv%Prf!==ON (set _O%xv%Prf=OFF) else (set _O%xv%Prf=ON&set _O%xv%Pro=OFF&set _O%xv%Std=OFF&set _O%xv%HmBu=OFF&set _O%xv%HmSt=OFF))&goto :Menu00Suite
if %errlvl%==1 (if !_O%xv%Pro!==ON (set _O%xv%Pro=OFF) else (set _O%xv%Pro=ON&set _O%xv%Prf=OFF&set _O%xv%Std=OFF&set _O%xv%HmBu=OFF&set _O%xv%HmSt=OFF))&goto :Menu00Suite
goto :Menu00Suite

:Menu00Apps
if %xv% EQU 19 (set oe=16&set pb=%xv%) else (set oe=21&set pb=21)
if %xv% EQU 24 (set _optSB=%_D24SB%) else (set _optSB=1)
if %_optSB%==1 (set sf=%xv%) else (set sf=21)
if !_O%xv%Access!==OFF if !_O%xv%Excel!==OFF if !_O%oe%OneNote!==OFF if !_O%xv%Outlook!==OFF if !_O%xv%PowerPoint!==OFF if !_O%pb%Publisher!==OFF if !_O%sf%SkypeForBusiness!==OFF if !_O%xv%Word!==OFF if !_O%xv%PrjPro!==OFF if !_O%xv%PrjStd!==OFF if !_O%xv%VisPro!==OFF if !_O%xv%VisStd!==OFF set _O%xv%Word=ON
call :showPV
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
echo %line%
echo Select Apps to install:
echo.
echo. A. Access 20%xv%           : !_O%xv%Access!
echo. E. Excel 20%xv%            : !_O%xv%Excel!
echo. N. OneNote 20%oe%          : !_O%oe%OneNote!
echo. O. Outlook 20%xv%          : !_O%xv%Outlook!
echo. P. PowerPoint 20%xv%       : !_O%xv%PowerPoint!
echo. R. Publisher 20%pb%        : !_O%pb%Publisher!
echo. S. SkypeForBusiness 20%sf% : !_O%sf%SkypeForBusiness!
echo. W. Word 20%xv%             : !_O%xv%Word!
echo.
echo. D. OneDrive Desktop      : %_OneDrive%
if not %_Teams%==0 echo. T. Microsoft Teams       : %_Teams%
if %_supv%==1 (
echo.
echo. 6. Project Pro 20%xv%: !_opt%xv%PP!   #   7. Project Standard 20%xv%: !_opt%xv%PS!
echo. 8. Visio Pro 20%xv%  : !_opt%xv%VP!   #   9. Visio Standard 20%xv%  : !_opt%xv%VS!
)
echo.
echo %line%
set errlvl=0
choice /c AENOPRSWD6789T0BX /n /m "Change a menu option, press 0 to proceed, B to go back, or X to exit: "
set errlvl=%errorlevel%
if %errlvl%==17 goto :eof
if %errlvl%==16 goto :MenuInitial
if %errlvl%==15 goto :Menu%xv%AppsB
if %errlvl%==14 if not %_Teams%==0 (if %_Teams%==ON (set _Teams=OFF) else (set _Teams=ON)&goto :Menu00Apps)
if %errlvl%==13 if %_supv%==1 (if !_O%xv%VisStd!==ON (set _O%xv%VisStd=OFF) else (set _O%xv%VisPro=OFF&set _O%xv%VisStd=ON)&goto :Menu00Apps)
if %errlvl%==12 if %_supv%==1 (if !_O%xv%VisPro!==ON (set _O%xv%VisPro=OFF) else (set _O%xv%VisPro=ON&set _O%xv%VisStd=OFF)&goto :Menu00Apps)
if %errlvl%==11 if %_supv%==1 (if !_O%xv%PrjStd!==ON (set _O%xv%PrjStd=OFF) else (set _O%xv%PrjPro=OFF&set _O%xv%PrjStd=ON)&goto :Menu00Apps)
if %errlvl%==10 if %_supv%==1 (if !_O%xv%PrjPro!==ON (set _O%xv%PrjPro=OFF) else (set _O%xv%PrjPro=ON&set _O%xv%PrjStd=OFF)&goto :Menu00Apps)
if %errlvl%==9 (if %_OneDrive%==ON (set _OneDrive=OFF) else (set _OneDrive=ON))&goto :Menu00Apps
if %errlvl%==8 (if !_O%xv%Word!==ON (set _O%xv%Word=OFF) else (set _O%xv%Word=ON))&goto :Menu00Apps
if %errlvl%==7 (if !_O%sf%SkypeForBusiness!==ON (set _O%sf%SkypeForBusiness=OFF) else (set _O%sf%SkypeForBusiness=ON))&goto :Menu00Apps
if %errlvl%==6 (if !_O%pb%Publisher!==ON (set _O%pb%Publisher=OFF) else (set _O%pb%Publisher=ON))&goto :Menu00Apps
if %errlvl%==5 (if !_O%xv%PowerPoint!==ON (set _O%xv%PowerPoint=OFF) else (set _O%xv%PowerPoint=ON))&goto :Menu00Apps
if %errlvl%==4 (if !_O%xv%Outlook!==ON (set _O%xv%Outlook=OFF) else (set _O%xv%Outlook=ON))&goto :Menu00Apps
if %errlvl%==3 (if !_O%oe%OneNote!==ON (set _O%oe%OneNote=OFF) else (set _O%oe%OneNote=ON))&goto :Menu00Apps
if %errlvl%==2 (if !_O%xv%Excel!==ON (set _O%xv%Excel=OFF) else (set _O%xv%Excel=ON))&goto :Menu00Apps
if %errlvl%==1 (if !_O%xv%Access!==ON (set _O%xv%Access=OFF) else (set _O%xv%Access=ON))&goto :Menu00Apps
goto :Menu00Apps

:Menu365SuiteB
set "_return=Menu365Suite"
set "_suite="
set "_suit2="
for /l %%J in (1,1,20) do (
set "_sku%%J="
)
set /a cc=0
if %_O365Pro%==ON (
set _suite=O365ProPlusRetail
) else if %_O365Bus%==ON (
set _suite=O365BusinessRetail
) else if %_O365Sma%==ON (
set _suite=O365SmallBusPremRetail
) else if %_O365Hom%==ON (
set _suite=O365HomePremRetail
) else if %_O365Edu%==ON (
set _suite=O365EduCloudRetail
)
call :setPrj16
call :setVis16
if defined _sku1 (set _O2016=1) else (set _O2016=0)
set vx=365
if defined _suite goto :Menu00Exclude
goto :MenuChannel

:Menu16SuiteB
set "_return=Menu00Suite"
set "_suite="
set "_suit2="
for /l %%J in (1,1,20) do (
set "_sku%%J="
)
set /a cc=0
if %_O16Pro%==ON (
set _suite=ProPlusRetail
) else if %_O16Prf%==ON (
set _suite=ProfessionalRetail
) else if %_O16Std%==ON (
set _suite=StandardRetail
) else if %_O16HmBu%==ON (
set _suite=HomeBusinessRetail
) else if %_O16HmSt%==ON (
set _suite=HomeStudentRetail
)
call :setPrj16
call :setVis16
if defined _sku1 (set _O2016=1) else (set _O2016=0)
set vx=16
if defined _suite goto :Menu00Exclude
goto :MenuChannel

:Menu19SuiteB
set "_return=Menu00Suite"
set "_suite="
set "_suit2="
for /l %%J in (1,1,20) do (
set "_sku%%J="
)
set /a cc=0
if %_O19Pro%==ON (
if %winbuild% lss 10240 (set _suite=ProPlusRetail&set _suit2=ProPlus2019Retail) else (set _suite=ProPlus2019Retail)
) else if %_O19Prf%==ON (
if %winbuild% lss 10240 (set _suite=ProfessionalRetail&set _suit2=Professional2019Retail) else (set _suite=Professional2019Retail)
) else if %_O19Std%==ON (
if %winbuild% lss 10240 (set _suite=StandardRetail&set _suit2=Standard2019Retail) else (set _suite=Standard2019Retail)
) else if %_O19HmBu%==ON (
if %winbuild% lss 10240 (set _suite=HomeBusinessRetail&set _suit2=HomeBusiness2019Retail) else (set _suite=HomeBusiness2019Retail)
) else if %_O19HmSt%==ON (
if %winbuild% lss 10240 (set _suite=HomeStudentRetail&set _suit2=HomeStudent2019Retail) else (set _suite=HomeStudent2019Retail)
)
call :setPrj19
call :setVis19
set vx=19
if defined _suite goto :Menu00Exclude
goto :MenuChannel

:Menu21SuiteB
set "_return=Menu00Suite"
set "_suite="
set "_suit2="
for /l %%J in (1,1,20) do (
set "_sku%%J="
)
set /a cc=0
if %_O21Pro%==ON (
if %winbuild% lss 10240 (set _suite=ProPlusRetail&set _suit2=ProPlus2021Retail) else (set _suite=ProPlus2021Retail)
) else if %_O21Prf%==ON (
if %winbuild% lss 10240 (set _suite=ProfessionalRetail&set _suit2=Professional2021Retail) else (set _suite=Professional2021Retail)
) else if %_O21Std%==ON (
if %winbuild% lss 10240 (set _suite=StandardRetail&set _suit2=Standard2021Retail) else (set _suite=Standard2021Retail)
) else if %_O21HmBu%==ON (
if %winbuild% lss 10240 (set _suite=HomeBusinessRetail&set _suit2=HomeBusiness2021Retail) else (set _suite=HomeBusiness2021Retail)
) else if %_O21HmSt%==ON (
if %winbuild% lss 10240 (set _suite=HomeStudentRetail&set _suit2=HomeStudent2021Retail) else (set _suite=HomeStudent2021Retail)
)
call :setPrj21
call :setVis21
if defined _sku1 (set _ON21=1) else (set _ON21=0)
set vx=21
if defined _suite goto :Menu00Exclude
goto :MenuChannel

:Menu24SuiteB
set "_return=Menu00Suite"
set "_suite="
set "_suit2="
for /l %%J in (1,1,20) do (
set "_sku%%J="
)
set /a cc=0
if %_O24Pro%==ON (
if %winbuild% lss 10240 (set _suite=ProPlusRetail&set _suit2=ProPlus2024Retail) else (set _suite=ProPlus2024Retail)
) else if %_O24Prf%==ON (
if %winbuild% lss 10240 (set _suite=ProfessionalRetail&set _suit2=Professional2024Retail) else (set _suite=Professional2024Retail)
) else if %_O24Std%==ON (
if %winbuild% lss 10240 (set _suite=StandardRetail&set _suit2=Standard2024Retail) else (set _suite=Standard2024Retail)
) else if %_O24HmBu%==ON (
if %winbuild% lss 10240 (set _suite=HomeBusinessRetail&set _suit2=HomeBusiness2024Retail) else (set _suite=HomeBusiness2024Retail)
) else if %_O24HmSt%==ON (
if %winbuild% lss 10240 (set _suite=HomeStudentRetail&set _suit2=Home2024Retail) else (set _suite=Home2024Retail)
)
call :setPrj24
call :setVis24
set vx=24
if defined _suite goto :Menu00Exclude
goto :MenuChannel

:Menu19AppsB
set "_return=Menu00Apps"
for /l %%J in (1,1,20) do (
set "_sku%%J="
)
set /a cc=0
if %_O19Access%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=AccessRetail&set /a cc+=1&set _sku!cc!=Access2019Retail) else (set _sku!cc!=Access2019Retail)
)
if %_O19Excel%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ExcelRetail&set /a cc+=1&set _sku!cc!=Excel2019Retail) else (set _sku!cc!=Excel2019Retail)
)
if %_O19Outlook%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=OutlookRetail&set /a cc+=1&set _sku!cc!=Outlook2019Retail) else (set _sku!cc!=Outlook2019Retail)
)
if %_O19PowerPoint%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=PowerPointRetail&set /a cc+=1&set _sku!cc!=PowerPoint2019Retail) else (set _sku!cc!=PowerPoint2019Retail)
)
if %_O19Publisher%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=PublisherRetail&set /a cc+=1&set _sku!cc!=Publisher2019Retail) else (set _sku!cc!=Publisher2019Retail)
)
if %_O19SkypeForBusiness%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=SkypeForBusinessRetail&set /a cc+=1&set _sku!cc!=SkypeForBusiness2019Retail) else (set _sku!cc!=SkypeForBusiness2019Retail)
)
if %_O19Word%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=WordRetail&set /a cc+=1&set _sku!cc!=Word2019Retail) else (set _sku!cc!=Word2019Retail)
)
if %_O16OneNote%==ON (
set /a cc+=1
set _sku!cc!=OneNoteRetail
)
call :setPrj19
call :setVis19
goto :MenuChannel

:Menu21AppsB
set "_return=Menu00Apps"
for /l %%J in (1,1,20) do (
set "_sku%%J="
)
set /a cc=0
if %_O21Access%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=AccessRetail&set /a cc+=1&set _sku!cc!=Access2021Retail) else (set _sku!cc!=Access2021Retail)
)
if %_O21Excel%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ExcelRetail&set /a cc+=1&set _sku!cc!=Excel2021Retail) else (set _sku!cc!=Excel2021Retail)
)
if %_O21Outlook%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=OutlookRetail&set /a cc+=1&set _sku!cc!=Outlook2021Retail) else (set _sku!cc!=Outlook2021Retail)
)
if %_O21PowerPoint%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=PowerPointRetail&set /a cc+=1&set _sku!cc!=PowerPoint2021Retail) else (set _sku!cc!=PowerPoint2021Retail)
)
if %_O21Publisher%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=PublisherRetail&set /a cc+=1&set _sku!cc!=Publisher2021Retail) else (set _sku!cc!=Publisher2021Retail)
)
if %_O21SkypeForBusiness%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=SkypeForBusinessRetail&set /a cc+=1&set _sku!cc!=SkypeForBusiness2021Retail) else (set _sku!cc!=SkypeForBusiness2021Retail)
)
if %_O21Word%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=WordRetail&set /a cc+=1&set _sku!cc!=Word2021Retail) else (set _sku!cc!=Word2021Retail)
)
if %_O21OneNote%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=OneNoteRetail&set /a cc+=1&set _sku!cc!=OneNote2021Retail) else (set _sku!cc!=OneNote2021Retail)
)
call :setVis21
call :setPrj21
if defined _sku1 (set _ON21=1) else (set _ON21=0)
goto :MenuChannel

:Menu24AppsB
set "_return=Menu00Apps"
for /l %%J in (1,1,20) do (
set "_sku%%J="
)
set /a cc=0
if %_O24Access%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=AccessRetail&set /a cc+=1&set _sku!cc!=Access2024Retail) else (set _sku!cc!=Access2024Retail)
)
if %_O24Excel%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ExcelRetail&set /a cc+=1&set _sku!cc!=Excel2024Retail) else (set _sku!cc!=Excel2024Retail)
)
if %_O24Outlook%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=OutlookRetail&set /a cc+=1&set _sku!cc!=Outlook2024Retail) else (set _sku!cc!=Outlook2024Retail)
)
if %_O24PowerPoint%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=PowerPointRetail&set /a cc+=1&set _sku!cc!=PowerPoint2024Retail) else (set _sku!cc!=PowerPoint2024Retail)
)
if %_O21Publisher%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=PublisherRetail&set /a cc+=1&set _sku!cc!=Publisher2021Retail) else (set _sku!cc!=Publisher2021Retail)
)
if %_O24SkypeForBusiness%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=SkypeForBusinessRetail&set /a cc+=1&set _sku!cc!=SkypeForBusiness2024Retail) else (set _sku!cc!=SkypeForBusiness2024Retail)
) else if %_O21SkypeForBusiness%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=SkypeForBusinessRetail&set /a cc+=1&set _sku!cc!=SkypeForBusiness2021Retail) else (set _sku!cc!=SkypeForBusiness2021Retail)
)
if %_O24Word%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=WordRetail&set /a cc+=1&set _sku!cc!=Word2024Retail) else (set _sku!cc!=Word2024Retail)
)
if %_O21OneNote%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=OneNoteRetail&set /a cc+=1&set _sku!cc!=OneNote2021Retail) else (set _sku!cc!=OneNote2021Retail)
)
call :setPrj24
call :setVis24
goto :MenuChannel

:setPrj16
if %_O16PrjPro%==ON (
set /a cc+=1
set _sku!cc!=ProjectProRetail
) else if %_O16PrjStd%==ON (
set /a cc+=1
set _sku!cc!=ProjectStdRetail
)
exit /b

:setPrj19
if %_O19PrjPro%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ProjectProRetail&set /a cc+=1&set _sku!cc!=ProjectPro2019Retail) else (set _sku!cc!=ProjectPro2019Retail)
) else if %_O19PrjStd%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ProjectStdRetail&set /a cc+=1&set _sku!cc!=ProjectStd2019Retail) else (set _sku!cc!=ProjectStd2019Retail)
)
exit /b

:setPrj21
if %_O21PrjPro%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ProjectProRetail&set /a cc+=1&set _sku!cc!=ProjectPro2021Retail) else (set _sku!cc!=ProjectPro2021Retail)
) else if %_O21PrjStd%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ProjectStdRetail&set /a cc+=1&set _sku!cc!=ProjectStd2021Retail) else (set _sku!cc!=ProjectStd2021Retail)
)
exit /b

:setPrj24
if %_O24PrjPro%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ProjectProRetail&set /a cc+=1&set _sku!cc!=ProjectPro2024Retail) else (set _sku!cc!=ProjectPro2024Retail)
) else if %_O24PrjStd%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=ProjectStdRetail&set /a cc+=1&set _sku!cc!=ProjectStd2024Retail) else (set _sku!cc!=ProjectStd2024Retail)
)
exit /b

:setVis16
if %_O16VisPro%==ON (
set /a cc+=1
set _sku!cc!=VisioProRetail
) else if %_O16VisStd%==ON (
set /a cc+=1
set _sku!cc!=VisioStdRetail
)
exit /b

:setVis19
if %_O19VisPro%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=VisioProRetail&set /a cc+=1&set _sku!cc!=VisioPro2019Retail) else (set _sku!cc!=VisioPro2019Retail)
) else if %_O19VisStd%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=VisioStdRetail&set /a cc+=1&set _sku!cc!=VisioStd2019Retail) else (set _sku!cc!=VisioStd2019Retail)
)
exit /b

:setVis21
if %_O21VisPro%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=VisioProRetail&set /a cc+=1&set _sku!cc!=VisioPro2021Retail) else (set _sku!cc!=VisioPro2021Retail)
) else if %_O21VisStd%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=VisioStdRetail&set /a cc+=1&set _sku!cc!=VisioStd2021Retail) else (set _sku!cc!=VisioStd2021Retail)
)
exit /b

:setVis24
if %_O24VisPro%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=VisioProRetail&set /a cc+=1&set _sku!cc!=VisioPro2024Retail) else (set _sku!cc!=VisioPro2024Retail)
) else if %_O24VisStd%==ON (
set /a cc+=1
if %winbuild% lss 10240 (set _sku!cc!=VisioStdRetail&set /a cc+=1&set _sku!cc!=VisioStd2024Retail) else (set _sku!cc!=VisioStd2024Retail)
)
exit /b

:Menu00Exclude
set xldAC=0
set xldSB=0
set xldOT=1
set xldPR=1
if %vx% EQU 365 (
set xldAC=1
set xldSB=1
if "!_O%vx%Edu!"=="ON" (
set xldAC=0
set xldSB=0
set xldOT=0
set xldPR=0
)
if "!_O%vx%Hom!"=="ON" (
set xldSB=0
)
)
if %vx% NEQ 365 (
if "!_O%vx%HmSt!"=="ON" (
set xldOT=0
set xldPR=0
)
if "!_O%vx%HmBu!"=="ON" (
set xldPR=0
)
if "!_O%vx%Pro!"=="ON" (
set xldAC=1
set xldSB=1
)
if "!_O%vx%Prf!"=="ON" (
set xldAC=1
)
)
if %vx% EQU 24 (
set xldPR=0
)
cls
echo %line%
echo Source  : "!CTRsource!"
echo Version : %CTRver% / Arch: %CTRarc% / Lang: %CTRlng%
if defined _suit2 (echo Suite   : %_suit2%) else (echo Suite   : %_suite%)
echo %line%
echo Select Apps to include ^(OFF ^= exclude^):
echo.
if %xldAC%==1 (
echo. A. Access           : %_Access%
)
echo. E. Excel            : %_Excel%
echo. N. OneNote          : %_OneNote%
if %xldOT%==1 (
echo. O. Outlook          : %_Outlook%
)
echo. P. PowerPoint       : %_PowerPoint%
if %xldPR%==1 (
echo. R. Publisher        : %_Publisher%
)
if %xldSB%==1 (
echo. S. SkypeForBusiness : %_Lync%
)
echo. W. Word             : %_Word%
echo. D. OneDrive Desktop : %_OneDrive%
if not %_Teams%==0 echo. T. Microsoft Teams  : %_Teams%
echo.
echo %line%
set errlvl=0
choice /c AENOPRSWDT0BX /n /m "Change a menu option, press 0 to proceed, B to go back, or X to exit: "
set errlvl=%errorlevel%
if %errlvl%==13 goto :eof
if %errlvl%==12 goto :%_return%
if %errlvl%==11 goto :MenuExcluded
if %errlvl%==10 if not %_Teams%==0 (if %_Teams%==ON (set _Teams=OFF) else (set _Teams=ON))&goto :Menu00Exclude
if %errlvl%==9 (if %_OneDrive%==ON (set _OneDrive=OFF) else (set _OneDrive=ON))&goto :Menu00Exclude
if %errlvl%==8 (if %_Word%==ON (set _Word=OFF) else (set _Word=ON))&goto :Menu00Exclude
if %errlvl%==7 if %xldSB%==1 (if %_Lync%==ON (set _Lync=OFF) else (set _Lync=ON))&goto :Menu00Exclude
if %errlvl%==6 if %xldPR%==1 (if %_Publisher%==ON (set _Publisher=OFF) else (set _Publisher=ON))&goto :Menu00Exclude
if %errlvl%==5 (if %_PowerPoint%==ON (set _PowerPoint=OFF) else (set _PowerPoint=ON))&goto :Menu00Exclude
if %errlvl%==4 if %xldOT%==1 (if %_Outlook%==ON (set _Outlook=OFF) else (set _Outlook=ON))&goto :Menu00Exclude
if %errlvl%==3 (if %_OneNote%==ON (set _OneNote=OFF) else (set _OneNote=ON))&goto :Menu00Exclude
if %errlvl%==2 (if %_Excel%==ON (set _Excel=OFF) else (set _Excel=ON))&goto :Menu00Exclude
if %errlvl%==1 if %xldAC%==1 (if %_Access%==ON (set _Access=OFF) else (set _Access=ON))&goto :Menu00Exclude
goto :Menu00Exclude

:MenuExcluded
if %xldAC%==0 (
set _Access=ON
)
if %xldOT%==0 (
set _Outlook=ON
)
if %xldPR%==0 (
set _Publisher=ON
)
if %xldSB%==0 (
set _Lync=ON
)
set "_excluded=Groove"
for %%J in (Access,Excel,Lync,OneDrive,OneNote,Outlook,PowerPoint,Publisher,Teams,Word) do if !_%%J!==OFF (
set "_excluded=!_excluded!,%%J"
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
echo. 7. DevMain Channel                     ^|    Dogfood::DevMain
echo. 8. Microsoft Elite                     ^|  Microsoft::DevMain
echo.
echo %line%
set errlvl=0
choice /c 123456780BX /n /m "Choose a menu option to proceed, press B to go back, or X to exit: "
set errlvl=%errorlevel%
if %errlvl%==11 goto :eof
if %errlvl%==10 goto :%_return%
if %errlvl%==9 (set inpt=0&goto :MenuChn)
if %errlvl%==8 (set inpt=8&goto :MenuChn)
if %errlvl%==7 (set inpt=7&goto :MenuChn)
if %errlvl%==6 (set inpt=6&goto :MenuChn)
if %errlvl%==5 (set inpt=5&goto :MenuChn)
if %errlvl%==4 (set inpt=4&goto :MenuChn)
if %errlvl%==3 (set inpt=3&goto :MenuChn)
if %errlvl%==2 (set inpt=2&goto :MenuChn)
if %errlvl%==1 (set inpt=1&goto :MenuChn)
goto :MenuChannel

:MenuChn
if %inpt%==0 (
set inpt=3
if not "!FFNRoot!"=="" for /l %%J in (1,1,20) do (
  if /i "!FFNRoot!"=="!ffn%%J!" set inpt=%%J
  )
)
set "CTRffn=!ffn%inpt%!"
set "CTRchn=!chn%inpt%!"
set "_products="
set "_licenses="
set "_exclude1d="
set "_skus="
set "_show="
set "_tmp="
if defined _suite (
set "_products=%_suite%.16_%CTRlng%_x-none"
)
if defined _suit2 set "_licenses=%_suit2%"
if not defined _sku1 goto :MenuMisc
for /l %%J in (1,1,%cc%) do (
if defined _skus (set "_skus=!_skus!,!_sku%%J!") else (set "_skus=!_sku%%J!")
)
for %%J in (%_skus%) do (
set _tmp=%%J
if /i "!_tmp:~-10!"=="2019Retail" if %winbuild% lss 10240 (
  if defined _show (set "_show=!_show!,%%J") else (set "_show=%%J")
  if defined _licenses (set "_licenses=!_licenses!,%%J") else (set "_licenses=%%J")
  )
if /i "!_tmp:~-10!"=="2019Retail" if %winbuild% geq 10240 (
  if defined _show (set "_show=!_show!,%%J") else (set "_show=%%J")
  if defined _products (set "_products=!_products!^|%%J.16_%CTRlng%_x-none") else (set "_products=%%J.16_%CTRlng%_x-none")
  if %_OneDrive%==OFF (if defined _exclude1d (set "_exclude1d=!_exclude1d! %%J.excludedapps.16=onedrive") else (set "_exclude1d=%%J.excludedapps.16=onedrive"))
  )
if /i "!_tmp:~-10!"=="2021Retail" if %winbuild% lss 10240 (
  if defined _show (set "_show=!_show!,%%J") else (set "_show=%%J")
  if defined _licenses (set "_licenses=!_licenses!,%%J") else (set "_licenses=%%J")
  )
if /i "!_tmp:~-10!"=="2021Retail" if %winbuild% geq 10240 (
  if defined _show (set "_show=!_show!,%%J") else (set "_show=%%J")
  if defined _products (set "_products=!_products!^|%%J.16_%CTRlng%_x-none") else (set "_products=%%J.16_%CTRlng%_x-none")
  if %_OneDrive%==OFF (if defined _exclude1d (set "_exclude1d=!_exclude1d! %%J.excludedapps.16=onedrive") else (set "_exclude1d=%%J.excludedapps.16=onedrive"))
  )
if /i "!_tmp:~-10!"=="2024Retail" if %winbuild% lss 10240 (
  if defined _show (set "_show=!_show!,%%J") else (set "_show=%%J")
  if defined _licenses (set "_licenses=!_licenses!,%%J") else (set "_licenses=%%J")
  )
if /i "!_tmp:~-10!"=="2024Retail" if %winbuild% geq 10240 (
  if defined _show (set "_show=!_show!,%%J") else (set "_show=%%J")
  if defined _products (set "_products=!_products!^|%%J.16_%CTRlng%_x-none") else (set "_products=%%J.16_%CTRlng%_x-none")
  if %_OneDrive%==OFF (if defined _exclude1d (set "_exclude1d=!_exclude1d! %%J.excludedapps.16=onedrive") else (set "_exclude1d=%%J.excludedapps.16=onedrive"))
  )
for %%# in (Access,Excel,Outlook,PowerPoint,Publisher,SkypeForBusiness,Word,OneNote) do if /i "!_tmp!"=="%%#Retail" (
  if defined _products (set "_products=!_products!^|%%J.16_%CTRlng%_x-none") else (set "_products=%%J.16_%CTRlng%_x-none")
  if %_OneDrive%==OFF (if defined _exclude1d (set "_exclude1d=!_exclude1d! %%J.excludedapps.16=onedrive") else (set "_exclude1d=%%J.excludedapps.16=onedrive"))
  )
for %%# in (ProjectPro,ProjectStd,VisioPro,VisioStd) do if /i "!_tmp!"=="%%#Retail" (
  if %_O2016%==1 (if defined _show (set "_show=!_show!,%%J") else (set "_show=%%J"))
  if defined _products (set "_products=!_products!^|%%J.16_%CTRlng%_x-none") else (set "_products=%%J.16_%CTRlng%_x-none")
  if %_OneDrive%==OFF (if defined _exclude1d (set "_exclude1d=!_exclude1d! %%J.excludedapps.16=onedrive") else (set "_exclude1d=%%J.excludedapps.16=onedrive"))
  )
if /i "!_tmp!"=="OneNoteRetail" (
  if %_ON21%==0 (if defined _show (set "_show=!_show!,%%J") else (set "_show=%%J"))
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
echo.
echo %line%
set errlvl=0
choice /c 12345670BX /n /m "Change a menu option, press 0 to proceed, B to go back, or X to exit: "
set errlvl=%errorlevel%
if %errlvl%==10 goto :eof
if %errlvl%==9 goto :MenuChannel
if %errlvl%==8 goto :MenuFinal
if %errlvl%==7 (if %_tele%==True (set _tele=False) else (set _tele=True))&goto :MenuMisc
if %errlvl%==6 (if %_actv%==True (set _actv=False) else (set _actv=True))&goto :MenuMisc
if %errlvl%==5 (if %_disp%==True (set _disp=False) else (set _disp=True))&goto :MenuMisc
if %errlvl%==4 (if %_shut%==True (set _shut=False) else (set _shut=True))&goto :MenuMisc
if %errlvl%==3 (if %_icon%==True (set _icon=False) else (set _icon=True))&goto :MenuMisc
if %errlvl%==2 (if %_eula%==True (set _eula=False) else (set _eula=True))&goto :MenuMisc
if %errlvl%==1 (if %_updt%==True (set _updt=False) else (set _updt=True))&goto :MenuMisc
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
if defined _suit2 (echo Suite   : %_suit2%) else (echo Suite   : %_suite%)
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
set errlvl=0
choice /c 123BX /n /m "Choose a menu option to proceed, press B to go back, or X to exit: "
set errlvl=%errorlevel%
if %errlvl%==5 goto :eof
if %errlvl%==4 goto :MenuMisc
if %errlvl%==3 (set _unattend=True&goto :MenuFinal2)
if %errlvl%==2 (set _unattend=False&goto :MenuFinal2)
if %errlvl%==1 (set _install=True&goto :MenuFinal2)
goto :MenuFinal

:MenuFinal2
cls
if %_cwmi% equ 1 for /f "tokens=2 delims==." %%# in ('wmic os get localdatetime /value') do set "_date=%%#"
if %_cwmi% equ 0 for /f "tokens=1 delims=." %%# in ('%_psc% "([WMI]'Win32_OperatingSystem=@').LocalDateTime"') do set "_date=%%#"
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
if defined _suit2 (echo Suite=%_suit2%) else (echo Suite=%_suite%)
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
)>"!_ini!\C2RR_Config_%_date:~0,8%-%_date:~8,4%.ini" 2>nul

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
set "_autoact="
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
if defined _suite echo %_suite%.excludedapps.16=%_excluded% ^^
if defined _exclude1d echo %_exclude1d% ^^
echo flt.useexptransportinplacepl=disabled flt.useofficehelperaddon=disabled flt.useoutlookshareaddon=disabled ^^
echo flt.useteamsaddon=disabled flt.usebingaddononinstall=disabled flt.usebingaddononupdate=disabled 1^>nul 2^>nul
echo reg.exe add %_Config% /f /v UpdateChannel /t REG_SZ /d "%_url%/%CTRffn%" 1^>nul 2^>nul
echo reg.exe add %_Config% /f /v UpdateChannelChanged /t REG_SZ /d True 1^>nul 2^>nul
echo exit /b
)>"!_temp!\C2R_Setup.bat"

set "CTRexe=1"
set "cfile=!_file:\=\\!"
if exist "!_file!" if %_cwmi% equ 1 for /f "tokens=4 delims==." %%i in ('wmic datafile where "name='!cfile!'" get Version /value ^| find "="') do (
  if %%i geq %verchk% (set CTRexe=0)
)
if exist "!_file!" if %_cwmi% equ 0 for /f "tokens=3 delims==." %%i in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfile!''').Version"') do (
  if %%i geq %verchk% (set CTRexe=0)
)
call :StopService 1>nul 2>nul
if %CTRexe%==1 (
if exist "!_target!" rmdir /s /q "!_target!" 1>nul 2>nul
mkdir "!_target!" 1>nul 2>nul
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
if defined _licenses (
echo.
echo %line%
echo Installing uplevel Licenses...
echo %line%
echo.
call :Licenses 1>nul 2>nul
)
if %_tele%==True (
call :Telemetry 1>nul 2>nul
)
call :Cleanup 1>nul 2>nul
echo.
echo %line%
echo Done.
echo %line%
echo.
echo Press 9 or X to exit.
choice /c 9X /n
if errorlevel 1 (exit /b) else (rem.)
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

:Cleanup
taskkill /t /f /IM OfficeC2RClient.exe
reg delete HKCU\Software\Microsoft\Office\Common /f
reg delete HKCU\Software\Microsoft\Office\16.0 /f
reg add HKCU\Software\Policies\Microsoft\Office\16.0\Teams /f /v PreventFirstLaunchAfterInstall /t REG_DWORD /d 1
exit /b

:Licenses
for /f "skip=2 tokens=2*" %%A in ('reg query %_CTR% /v InstallPath') do set "_Root=%%B\root"
for /f "skip=2 tokens=2*" %%A in ('reg query %_CTR% /v PackageGUID') do set "_GUID=%%B"
for %%J in (%_licenses%) do (
if defined _ids (set "_ids=!_ids!,%%J.16") else (set "_ids=%%J.16")
reg delete %_Config% /f /v %%J.OSPPReady
)
"!_Root!\integration\integrator.exe" /I /License PRIDName=%_ids% PackageGUID="%_GUID%" PackageRoot="!_Root!"
for %%J in (%_licenses%) do (
reg query %_Config% /v ProductReleaseIds | findstr /I "%%J" || (for /f "skip=2 tokens=2*" %%A in ('reg query %_Config% /v ProductReleaseIds') do reg add %_Config% /f /v ProductReleaseIds /t REG_SZ /d "%%J,%%B")
reg add %_Config% /f /v %%J.OSPPReady /t REG_SZ /d 1
)
exit /b

:Telemetry
set _Of365=0
if /i %_return%==Menu365Suite (
set _Of365=1
)
set "_inter=SOFTWARE"
if "%xOS%"=="x64" if %wow64%==1 (set "_inter=SOFTWARE\Wow6432Node")
set "_rkey=HKLM\%_inter%\Microsoft\Office\16.0\User Settings\MyCustomUserSettings"
set "_skey=HKLM\%_inter%\Microsoft\Office\16.0\User Settings\MyCustomUserSettings\Create\Software\Microsoft\Office\16.0"
set "_tkey=HKLM\%_inter%\Microsoft\Office\16.0\User Settings\MyCustomUserSettings\Create\Software\Microsoft\Office\Common\ClientTelemetry"
for %%# in (Count,Order) do reg add "%_rkey%" /f /v %%# /t REG_DWORD /d 1
reg add "%_tkey%" /f /v SendTelemetry /t REG_DWORD /d 3
reg add "%_tkey%" /f /v DisableTelemetry /t REG_DWORD /d 1
if %_Of365%==0 (
for %%# in (disconnectedstate,usercontentdisabled,downloadcontentdisabled,controllerconnectedservicesenabled) do reg add "%_skey%\Common\Privacy" /f /v %%# /t REG_DWORD /d 2
)
for %%# in (disableboottoofficestart) do reg add "%_skey%\Common" /f /v %%# /t REG_DWORD /d 1
for %%# in (qmenable,sendcustomerdata,updatereliabilitydata) do reg add "%_skey%\Common" /f /v %%# /t REG_DWORD /d 0
for %%# in (disableboottoofficestart,optindisable,shownfirstrunoptin,ShownFileFmtPrompt) do reg add "%_skey%\Common\General" /f /v %%# /t REG_DWORD /d 1
for %%# in (skydrivesigninoption) do reg add "%_skey%\Common\General" /f /v %%# /t REG_DWORD /d 0
for %%# in (enabled,includescreenshot) do reg add "%_skey%\Common\Feedback" /f /v %%# /t REG_DWORD /d 0
for %%# in (disableboottoofficestart) do reg add "%_skey%\Common\Internet" /f /v %%# /t REG_DWORD /d 1
for %%# in (serviceleveloptions) do reg add "%_skey%\Common\Internet" /f /v %%# /t REG_DWORD /d 0
for %%# in (disableboottoofficestart) do reg add "%_skey%\Common\PTWatson" /f /v %%# /t REG_DWORD /d 1
for %%# in (PTWOptIn) do reg add "%_skey%\Common\PTWatson" /f /v %%# /t REG_DWORD /d 0
for %%# in (disablereporting) do reg add "%_skey%\Common\Security\FileValidation" /f /v %%# /t REG_DWORD /d 1
for %%# in (BootedRTM,disablemovie) do reg add "%_skey%\Firstrun" /f /v %%# /t REG_DWORD /d 1
for %%# in (disableautomaticsendtracing) do reg add "%_skey%\Lync" /f /v %%# /t REG_DWORD /d 1
for %%# in (EnableLogging) do reg add "%_skey%\Outlook\Options\Mail" /f /v %%# /t REG_DWORD /d 0
for %%# in (EnableLogging) do reg add "%_skey%\Word\Options" /f /v %%# /t REG_DWORD /d 0
for %%# in (EnableLogging,EnableUpload) do reg add "%_skey%\OSM" /f /v %%# /t REG_DWORD /d 0
for %%# in (accesssolution,olksolution,onenotesolution,pptsolution,projectsolution,publishersolution,visiosolution,wdsolution,xlsolution) do reg add "%_skey%\OSM\PreventedApplications" /f /v %%# /t REG_DWORD /d 1
for %%# in (agave,appaddins,comaddins,documentfiles,templatefiles) do reg add "%_skey%\OSM\PreventedSolutiontypes" /f /v %%# /t REG_DWORD /d 1
set "_schtasks=SCHTASKS /Change /DISABLE /TN"
set "_schedule=Microsoft\Office"
%_schtasks% "%_schedule%\OfficeInventoryAgentFallBack"
%_schtasks% "%_schedule%\OfficeTelemetryAgentFallBack"
%_schtasks% "%_schedule%\OfficeTelemetryAgentFallBack2016"
%_schtasks% "%_schedule%\OfficeInventoryAgentLogOn"
%_schtasks% "%_schedule%\OfficeTelemetryAgentLogOn"
%_schtasks% "%_schedule%\OfficeTelemetryAgentLogOn2016"
%_schtasks% "ServiceWatcherSchedule"
exit /b

:E_VER
echo %_err%
echo Minimum Supported Version is 16.0.9029.2167
goto :TheEnd

:E_Admin
echo %_err%
echo This script require administrator privileges.
goto :TheEnd

:E_Win
echo %_err%
echo Windows 7 SP1 is the minimum supported OS.
goto :TheEnd

:E_WMI
echo %_err%
echo WMIC.exe or Windows PowerShell is required for this script to work.
goto :TheEnd

:TheEnd
echo.
echo Press 9 or X to exit.
choice /c 9X /n
if errorlevel 1 (exit /b) else (rem.)
goto :eof
