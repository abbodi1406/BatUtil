@echo off

:: Change to 1 to start the process directly, it will create ISO with install.wim by default
SET AutoStart=0

:: Change to 1 for not creating ISO file, setup media folder will be preserved
SET SkipISO=0

:: Change to 1 for not adding winre.wim to install.wim/install.esd
SET SkipWinRE=0

:: Change to 1 to keep converted Reference ESDs
SET RefESD=0

rem script:	   abbodi1406, @rgadguard
rem wimlib:	   synchronicity
rem offlinereg: erwan.l
rem Thanks to: @Ratiborus58, @NecrosoftCore, @DiamondMonday, @WzorNET

set "params=%*"
cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  cmd /u /c echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~dp0"" && ""%~dpnx0"" ""%params%""", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )

title UUP -^> ISO
for %%a in (wimlib-imagex,7z,imagex,offlinereg) do (
if not exist "%~dp0bin\%%a.exe" (echo Error: required %%a.exe is missing&pause&exit)
)
IF /I "%PROCESSOR_ARCHITECTURE%" EQU "AMD64" (SET "wimlib=%~dp0bin\bin64\wimlib-imagex.exe") ELSE (SET "wimlib=%~dp0bin\wimlib-imagex.exe")
cd /d "%~dp0"
setlocal EnableExtensions
setlocal EnableDelayedExpansion
color 1f
SET UUP=
SET ERRORTEMP=
SET PREPARED=0
SET VOL=0
SET EXPRESS=0
SET AIO=0
SET FixDisplay=0
SET uups_esd_num=0
IF %RefESD%==1 (SET level=maximum) else (SET level=fast)
if exist bin\temp\ rmdir /s /q bin\temp\
if exist temp\ rmdir /s /q temp\
mkdir bin\temp
mkdir temp
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
set "dismroot=%windir%\system32\dism.exe"
set "mountdir=%SystemDrive%\MountUUP"

:checkadk
SET regKeyPathFound=1
SET wowRegKeyPathFound=1
REG QUERY "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 1>NUL 2>NUL || SET wowRegKeyPathFound=0
REG QUERY "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 1>NUL 2>NUL || SET regKeyPathFound=0
if %wowRegKeyPathFound% EQU 0 (
  if %regKeyPathFound% EQU 0 (
    SET ADK=0&goto :precheck
  ) else (
    SET regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    SET regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
FOR /F "skip=2 tokens=2*" %%i IN ('REG QUERY "%regKeyPath%" /v KitsRoot10') DO (SET "KitsRoot=%%j")
SET "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
SET "dismroot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\DISM\dism.exe"
SET ADK=1
IF NOT EXIST "%dismroot%" SET ADK=0&SET "dismroot=%windir%\system32\dism.exe"

:precheck
if not "%1"=="" (if exist "%~1\*.esd" set "UUP=%~1"&goto :check)
if exist "%CD%\UUPs\*.esd" set "UUP=%CD%\UUPs"&goto :check

:prompt
cls
set UUP=
echo.
echo ============================================================
echo Enter / Paste the path to UUP files directory
echo ^(without quotes marks "" even if the path contains spaces^)
echo ============================================================
echo.
set /p "UUP="
if "%UUP%"=="" goto :QUIT
goto :check

:check
dir /b /ad "%UUP%\*Package*" 1>nul 2>nul && set EXPRESS=1
del /f /q temp\uups_esd.txt 1>nul 2>nul
for %%A in (
Core,CoreSingleLanguage,CoreCountrySpecific
Professional,ProfessionalEducation,ProfessionalWorkstation
Education,Enterprise,EnterpriseG,Cloud,CloudE
CoreN
ProfessionalN,ProfessionalEducationN,ProfessionalWorkstationN
EducationN,EnterpriseN,EnterpriseGN,CloudN,CloudEN
Starter,StarterN,ProfessionalCountrySpecific,ProfessionalSingleLanguage,ServerRdsh,PPIPro
) do (
dir /b /a:-d "%UUP%\*%%A_*.esd">>temp\uups_esd.txt 2>nul
)
for /f "tokens=3 delims=: " %%i in ('find /v /n /c "" temp\uups_esd.txt') do set uups_esd_num=%%i
if %uups_esd_num% equ 0 (
echo.
echo ============================================================
echo ERROR: UUP Edition file is not found in specified directory
echo ============================================================
echo.
echo Press any key to exit.
pause >nul
goto :QUIT
)
if %uups_esd_num% gtr 1 (
for /L %%i in (1, 1, %uups_esd_num%) do call :uups_esd %%i
goto :MULTIMENU
)
call :uups_esd 1
set "MetadataESD=%UUP%\%uups_esd1%"&set "arch=%arch1%"&set "editionid=%edition1%"&set "langid=%langid1%"
goto :MAINMENU

:MULTIMENU
if %AutoStart%==1 (SET AIO=1&set WIMFILE=install.wim&goto :ISO)
cls
set userinp=
echo ============================================================
echo       UUP directory contains multiple editions files:
echo ============================================================
echo.
for /L %%i in (1, 1, %uups_esd_num%) do (
echo %%i. !name%%i!
)
echo.
echo ============================================================
echo Enter edition number to create, or zero '0' to create AIO
echo ============================================================
set /p userinp= ^> Enter your option and press "Enter": 
if "%userinp%"=="" goto :QUIT
set userinp=%userinp:~0,2%
if %userinp%==0 goto :AIOMENU
for /L %%i in (1, 1, %uups_esd_num%) do (
if %userinp%==%%i set "MetadataESD=%UUP%\!uups_esd%%i!"&set "arch=!arch%%i!"&set "editionid=!edition%%i!"&set "langid=!langid%%i!"&goto :MAINMENU
)
goto :MULTIMENU

:MAINMENU
if %AutoStart%==1 (set WIMFILE=install.wim&goto :ISO)
cls
set userinp=
echo ============================================================
echo.
echo.       1 - Create ISO with install.wim
echo.       2 - Create install.wim
echo.       3 - UUP Edition info
IF %EXPRESS%==0 (
echo.       4 - Create ISO with install.esd
echo.       5 - Create install.esd
)
if %winbuild% LSS 10240 if %ADK%==0 (
echo.
echo Warning:
echo neither Windows 10 Host OS or ADK is detected, boot.wim will be winre.wim
)
echo.
echo ============================================================
set /p userinp= ^> Enter your option and press "Enter": 
if "%userinp%"=="" goto :QUIT
set userinp=%userinp:~0,1%
if %userinp%==0 goto :QUIT
if %userinp%==5 IF %EXPRESS%==0 (set WIMFILE=install.esd&goto :Single)
if %userinp%==4 IF %EXPRESS%==0 (set WIMFILE=install.esd&goto :ISO)
if %userinp%==3 goto :INFO
if %userinp%==2 (set WIMFILE=install.wim&goto :Single)
if %userinp%==1 (set WIMFILE=install.wim&goto :ISO)
GOTO :MAINMENU

:AIOMENU
SET AIO=1
cls
set userinp=
echo ============================================================
echo.
echo.       1 - Create AIO ISO with install.wim
echo.       2 - Create AIO install.wim
echo.       3 - UUP Editions info
IF %EXPRESS%==0 (
echo.       4 - Create AIO ISO with install.esd
echo.       5 - Create AIO install.esd
)
if %winbuild% LSS 10240 if %ADK%==0 (
echo.
echo Warning:
echo neither Windows 10 Host OS or ADK is detected, boot.wim will be winre.wim
)
echo.
echo ============================================================
set /p userinp= ^> Enter your option and press "Enter": 
if "%userinp%"=="" goto :QUIT
set userinp=%userinp:~0,1%
if %userinp%==0 goto :QUIT
if %userinp%==5 IF %EXPRESS%==0 (set WIMFILE=install.esd&goto :Single)
if %userinp%==4 IF %EXPRESS%==0 (set WIMFILE=install.esd&goto :ISO)
if %userinp%==3 goto :INFOAIO
if %userinp%==2 (set WIMFILE=install.wim&goto :Single)
if %userinp%==1 (set WIMFILE=install.wim&goto :ISO)
goto :AIOMENU

:ISO
cls
IF %PREPARED%==0 CALL :PREPARE
CALL :uups_ref
echo.
echo ============================================================
echo Creating Setup Media Layout . . .
echo ============================================================
IF EXIST ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
echo.
"%wimlib%" apply "%MetadataESD%" 1 ISOFOLDER\ >nul 2>&1
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during apply.&echo.&echo Press any key to exit.&pause >nul&GOTO :QUIT)
del /f /q ISOFOLDER\MediaMeta.xml >nul 2>&1
rmdir /s /q ISOFOLDER\sources\uup\ >nul 2>&1
if %AIO%==1 del /f /q ISOFOLDER\sources\ei.cfg >nul 2>&1
echo.
echo ============================================================
echo Creating boot.wim . . .
echo ============================================================
echo.
"%wimlib%" export "%MetadataESD%" 2 ISOFOLDER\sources\boot.wim --compress=LZX:15 --boot
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&echo.&echo Press any key to exit.&pause >nul&GOTO :QUIT)
IF %SkipWinRE%==0 copy /y ISOFOLDER\sources\boot.wim temp\winre.wim >nul
"%wimlib%" info ISOFOLDER\sources\boot.wim 1 --image-property FLAGS=9 1>nul 2>nul
if %winbuild% GEQ 10240 (
call :BootWIM
) else (
if %ADK%==1 (
  call :BootWIM
  ) else (
  copy /y .\bin\reagent.xml .\ISOFOLDER\sources >nul 2>&1
  )
)
echo.
echo ============================================================
echo Creating %WIMFILE% . . .
echo ============================================================
echo.
for /f "tokens=5-10 delims=: " %%G in ('bin\wimlib-imagex info "%MetadataESD%" 3 ^| find /i "Last Modification Time"') do (set mmm=%%G&set "isotime=%%H/%%L,%%I:%%J:%%K")
call :setdate %mmm%
if exist "temp\*.ESD" (set _rrr=--ref="temp\*.esd") else (set "_rrr=")
if /i %WIMFILE%==install.esd (
  "%wimlib%" export "%MetadataESD%" 3 ISOFOLDER\sources\%WIMFILE% --ref="%UUP%\*.esd" %_rrr%
) else (
  "%wimlib%" export "%MetadataESD%" 3 ISOFOLDER\sources\%WIMFILE% --ref="%UUP%\*.esd" %_rrr% --compress=maximum
)
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&echo.&echo Press any key to exit.&pause >nul&GOTO :QUIT)
if %FixDisplay%==1 (
  "%wimlib%" info ISOFOLDER\sources\%WIMFILE% 1 "%_os%" "%_os%" --image-property DISPLAYNAME="%_os%" --image-property DISPLAYDESCRIPTION="%_os%" 1>nul 2>nul
)
if %AIO%==1 for /L %%i in (2, 1, %uups_esd_num%) do (
if /i %WIMFILE%==install.esd (
  "%wimlib%" export "%UUP%\!uups_esd%%i!" 3 ISOFOLDER\sources\%WIMFILE% --ref="%UUP%\*.esd" %_rrr%
) else (
  "%wimlib%" export "%UUP%\!uups_esd%%i!" 3 ISOFOLDER\sources\%WIMFILE% --ref="%UUP%\*.esd" %_rrr% --compress=maximum
)
if %FixDisplay%==1 (
  "%wimlib%" info ISOFOLDER\sources\%WIMFILE% %%i "!_os%%i!" "!_os%%i!" --image-property DISPLAYNAME="!_os%%i!" --image-property DISPLAYDESCRIPTION="!_os%%i!" 1>nul 2>nul
)
)
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&echo.&echo Press any key to exit.&pause >nul&GOTO :QUIT)
IF %SkipWinRE%==0 (
echo.
echo ============================================================
echo Adding winre.wim to %WIMFILE% . . .
echo ============================================================
echo.
"%wimlib%" update ISOFOLDER\sources\%WIMFILE% 1 --command="add 'temp\winre.wim' '\windows\system32\recovery\winre.wim'" 1>nul 2>nul
if %AIO%==1 for /L %%i in (2, 1, %uups_esd_num%) do (
"%wimlib%" update ISOFOLDER\sources\%WIMFILE% %%i --command="add 'temp\winre.wim' '\windows\system32\recovery\winre.wim'" 1>nul 2>nul
)
)
IF %SkipISO%==1 (
  IF %RefESD%==1 call :uups_backup
  ren ISOFOLDER %DVDISO%
  echo.
  echo ============================================================
  echo Done. You chose not to create iso file.
  echo ============================================================
  echo.
  echo Press any key to exit.
  pause >nul
  GOTO :QUIT
)
echo.
echo ============================================================
echo Creating ISO . . .
echo ============================================================
bin\cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -g -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (
  IF %RefESD%==1 call :uups_backup
  ren ISOFOLDER %DVDISO%
  echo.
  echo Errors were reported during ISO creation.
  echo.
  echo Press any key to exit.
  pause >nul
  GOTO :QUIT
)
IF %RefESD%==1 call :uups_backup&echo Finished
rmdir /s /q ISOFOLDER\
echo.
echo Press any key to exit.
pause >nul
GOTO :QUIT

:Single
cls
IF EXIST "%CD%\%WIMFILE%" (
echo.
echo ============================================================
echo An %WIMFILE% file is already present in the current folder
echo ============================================================
echo.
echo Press any key to exit.
pause >nul
GOTO :QUIT
)
IF %PREPARED%==0 CALL :PREPARE
CALL :uups_ref
echo.
echo ============================================================
echo Creating %WIMFILE% . . .
echo ============================================================
echo.
if %AIO%==1 set "MetadataESD=%UUP%\%uups_esd1%"
if exist "temp\*.ESD" (set _rrr=--ref="temp\*.esd") else (set "_rrr=")
if /i %WIMFILE%==install.esd (
  "%wimlib%" export "%MetadataESD%" 3 %WIMFILE% --ref="%UUP%\*.esd" %_rrr%
) else (
  "%wimlib%" export "%MetadataESD%" 3 %WIMFILE% --ref="%UUP%\*.esd" %_rrr% --compress=maximum
)
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&echo.&echo Press any key to exit.&pause >nul&GOTO :QUIT)
if %FixDisplay%==1 (
  "%wimlib%" info %WIMFILE% 1 "%_os%" "%_os%" --image-property DISPLAYNAME="%_os%" --image-property DISPLAYDESCRIPTION="%_os%" 1>nul 2>nul
)
if %AIO%==1 for /L %%i in (2, 1, %uups_esd_num%) do (
if /i %WIMFILE%==install.esd (
  "%wimlib%" export "%UUP%\!uups_esd%%i!" 3 %WIMFILE% --ref="%UUP%\*.esd" %_rrr%
) else (
  "%wimlib%" export "%UUP%\!uups_esd%%i!" 3 %WIMFILE% --ref="%UUP%\*.esd" %_rrr% --compress=maximum
)
if %FixDisplay%==1 (
  "%wimlib%" info %WIMFILE% %%i "!_os%%i!" "!_os%%i!" --image-property DISPLAYNAME="!_os%%i!" --image-property DISPLAYDESCRIPTION="!_os%%i!" 1>nul 2>nul
)
)
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&echo.&echo Press any key to exit.&pause >nul&GOTO :QUIT)
IF %SkipWinRE%==0 (
echo.
echo ============================================================
echo Creating winre.wim . . .
echo ============================================================
echo.
"%wimlib%" export "%MetadataESD%" 2 temp\winre.wim --compress=maximum
echo.
echo ============================================================
echo Adding winre.wim to %WIMFILE% . . .
echo ============================================================
echo.
"%wimlib%" update %WIMFILE% 1 --command="add 'temp\winre.wim' '\windows\system32\recovery\winre.wim'" 1>nul 2>nul
if %AIO%==1 for /L %%i in (2, 1, %uups_esd_num%) do (
"%wimlib%" update %WIMFILE% %%i --command="add 'temp\winre.wim' '\windows\system32\recovery\winre.wim'" 1>nul 2>nul
)
)
IF %RefESD%==1 call :uups_backup
echo.
echo Done.
echo.
echo Press any key to exit.
pause >nul
GOTO :QUIT

:INFO
IF %PREPARED%==0 CALL :PREPARE
cls
echo ============================================================
echo                     UUP Contents Info
echo ============================================================
echo      Arch: %arch%
echo  Language: %langid%
echo   Version: %ver1%.%ver2%.%build%.%svcbuild%
echo    Branch: %branch%
echo        OS: %_os%
echo.
echo Press any key to continue . . .
pause >nul
GOTO :MAINMENU

:INFOAIO
IF %PREPARED%==0 CALL :PREPARE
cls
echo ============================================================
echo                     UUP Contents Info
echo ============================================================
echo      Arch: %arch%
echo   Version: %ver1%.%ver2%.%build%.%svcbuild%
echo    Branch: %branch%
echo  Editions:
for /L %%i in (1, 1, %uups_esd_num%) do (
echo %%i. !name%%i!
)
echo.
echo Press any key to continue . . .
pause >nul
goto :AIOMENU

:PREPARE
cls
echo ============================================================
echo Checking UUP Info . . .
echo ============================================================
SET PREPARED=1
if %AIO%==1 set "MetadataESD=%UUP%\%uups_esd1%"&set "arch=%arch1%"&set "langid=%langid1%"
bin\wimlib-imagex info "%MetadataESD%" 3 >bin\info.txt 2>&1
for /f "tokens=1* delims=: " %%i in ('findstr /b "Name" bin\info.txt') do set "_os=%%j"
for /f "tokens=2 delims=: " %%i in ('findstr /b "Build" bin\info.txt') do set build=%%i
for /f "tokens=4 delims=: " %%i in ('find /i "Service Pack Build" bin\info.txt') do set svcbuild=%%i
for /f "tokens=3 delims=: " %%i in ('find /i "Major" bin\info.txt') do set ver1=%%i
for /f "tokens=3 delims=: " %%i in ('find /i "Minor" bin\info.txt') do set ver2=%%i
del /f /q bin\info.txt >nul 2>&1
for /f "tokens=3 delims=<>" %%i in ('bin\imagex.exe /info "%MetadataESD%" 3 ^| find /i "<DISPLAYNAME>" 2^>nul') do if /i "%%i"=="/DISPLAYNAME" (set FixDisplay=1)
if %FixDisplay%==1 if %AIO%==1 for /L %%i in (2, 1, %uups_esd_num%) do (
for /f "tokens=1* delims=: " %%a in ('bin\wimlib-imagex info "%UUP%\!uups_esd%%i!" 3 ^| findstr /b "Name"') do set "_os%%i=%%b"
)
"%wimlib%" extract "%MetadataESD%" 1 sources\ei.cfg --dest-dir=.\bin\temp --no-acls >nul 2>&1
type .\bin\temp\ei.cfg 2>nul | find /i "Volume" 1>nul && set VOL=1
"%wimlib%" extract "%MetadataESD%" 1 sources\SetupPlatform.dll --dest-dir=.\bin\temp --no-acls >nul 2>&1
bin\7z.exe l .\bin\temp\SetupPlatform.dll >.\bin\temp\version.txt 2>&1
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\temp\version.txt" 2^>nul') do (set version=%%i.%%j&set branch=%%k&set datetime=%%l)
if /i %arch%==x86 (set _ss=x86) else if /i %arch%==x64 (set _ss=amd64) else (set _ss=arm64)
"%wimlib%" extract "%MetadataESD%" 3 Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision* --dest-dir=.\bin\temp --no-acls >nul 2>&1
for /f "tokens=6,7 delims=_." %%i in ('dir /b /od .\bin\temp\*.manifest') do set revision=%%i.%%j
if not "%version%"=="%revision%" (
set version=%revision%
for /f "tokens=5,6,7,8,9,10 delims=: " %%G in ('bin\wimlib-imagex.exe info "%MetadataESD%" 3 ^| find /i "Last Modification Time"') do (set mmm=%%G&set yyy=%%L&set ddd=%%H-%%I%%J)
call :setmmm !mmm!
)
set _label2=
if /i "%branch%"=="WinBuild" (
"%wimlib%" extract "%MetadataESD%" 3 \Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls >nul
for /f "tokens=3 delims==:" %%a in ('"bin\offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion" getvalue BuildLabEx" 2^>nul') do if not errorlevel 1 (for /f "tokens=1-5 delims=." %%i in ('echo %%~a') do set _label2=%%i.%%j.%%m.%%l_CLIENT&set branch=%%l)
)
if defined _label2 (set _label=%_label2%) else (set _label=%version%.%datetime%.%branch%_CLIENT)
rmdir /s /q .\bin\temp >nul 2>&1

for %%b in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _label=!_label:%%b=%%b!
set branch=!branch:%%b=%%b!
set langid=!langid:%%b=%%b!
set editionid=!editionid:%%b=%%b!
set archl=!arch:%%b=%%b!
)

if %AIO%==1 set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%MULTI_UUP_%archl%FRE_%langid%&exit /b

set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%%editionid%_RET_%archl%FRE_%langid%
if /i %editionid%==Core set DVDLABEL=CCRA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CORE_OEMRET_%archl%FRE_%langid%
if /i %editionid%==CoreN set DVDLABEL=CCRNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%COREN_OEMRET_%archl%FRE_%langid%
if /i %editionid%==CoreSingleLanguage set DVDLABEL=CSLA_%archl%FREO_%langid%_DV5&set DVDISO=%_label%SINGLELANGUAGE_OEM_%archl%FRE_%langid%
if /i %editionid%==CoreCountrySpecific set DVDLABEL=CCHA_%archl%FREO_%langid%_DV5&set DVDISO=%_label%CHINA_OEM_%archl%FRE_%langid%
if /i %editionid%==Professional (IF %VOL%==1 (set DVDLABEL=CPRA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%PROFESSIONALVL_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PRO_OEMRET_%archl%FRE_%langid%))
if /i %editionid%==ProfessionalN (IF %VOL%==1 (set DVDLABEL=CPRNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%PROFESSIONALNVL_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PRON_OEMRET_%archl%FRE_%langid%))
if /i %editionid%==Education (IF %VOL%==1 (set DVDLABEL=CEDA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%EDUCATION_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CEDA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%EDUCATION_RET_%archl%FRE_%langid%))
if /i %editionid%==EducationN (IF %VOL%==1 (set DVDLABEL=CEDNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%EDUCATIONN_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CEDNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%EDUCATIONN_RET_%archl%FRE_%langid%))
if /i %editionid%==Enterprise set DVDLABEL=CENA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISE_VOL_%archl%FRE_%langid%
if /i %editionid%==EnterpriseN set DVDLABEL=CENNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISEN_VOL_%archl%FRE_%langid%
if /i %editionid%==Cloud set DVDLABEL=CWCA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CLOUD_OEMRET_%archl%FRE_%langid%
if /i %editionid%==CloudN set DVDLABEL=CWCNNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CLOUDN_OEMRET_%archl%FRE_%langid%
exit /b

:BootWIM
"%wimlib%" info ISOFOLDER\sources\boot.wim 1 "Microsoft Windows PE (%arch%)" "Microsoft Windows PE (%arch%)" 1>nul 2>nul
"%wimlib%" update ISOFOLDER\sources\boot.wim 1 --command="delete '\Windows\system32\winpeshl.ini'" 1>nul 2>nul
if exist "%mountdir%" (
"%dismroot%" /English /Unmount-Wim /MountDir:"%mountdir%" /Discard 1>nul 2>nul
"%dismroot%" /English /Cleanup-Wim 1>nul 2>nul
rmdir /s /q "%mountdir%" 1>nul 2>nul
)
if not exist "%mountdir%" mkdir "%mountdir%"
"%dismroot%" /English /Mount-Wim /Wimfile:ISOFOLDER\sources\boot.wim /Index:1 /MountDir:"%mountdir%" 1>nul 2>nul
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (
"%dismroot%" /English /Unmount-Wim /MountDir:"%mountdir%" /Discard 1>nul 2>nul
"%dismroot%" /English /Cleanup-Wim 1>nul 2>nul
copy /y temp\winre.wim ISOFOLDER\sources\boot.wim >nul
"%wimlib%" info ISOFOLDER\sources\boot.wim 1 --image-property FLAGS=9 1>nul 2>nul
copy /y .\bin\reagent.xml .\ISOFOLDER\sources >nul
exit /b
)
"%dismroot%" /English /Quiet /Image:"%mountdir%" /Set-TargetPath:X:\$windows.~bt\
"%dismroot%" /English /Quiet /Unmount-Wim /MountDir:"%mountdir%" /Commit
rmdir /s /q "%mountdir%" 1>nul 2>nul
"%wimlib%" extract ISOFOLDER\sources\%WIMFILE% 1 Windows\system32\xmllite.dll --dest-dir=ISOFOLDER\sources --no-acls >nul 2>&1
echo delete '^\Windows^\system32^\winpeshl.ini'>bin\boot-wim.txt
echo add 'ISOFOLDER^\setup.exe' '^\setup.exe'>>bin\boot-wim.txt
echo add 'ISOFOLDER^\sources^\inf^\setup.cfg' '^\sources^\inf^\setup.cfg'>>bin\boot-wim.txt
echo add 'ISOFOLDER^\sources^\background_cli.bmp' '^\sources^\background.bmp'>>bin\boot-wim.txt
for /f %%A in (bin\bootwim.txt) do (
if exist "ISOFOLDER\sources\%%A" echo add 'ISOFOLDER^\sources^\%%A' '^\sources^\%%A'>>bin\boot-wim.txt
)
for /f %%A in (bin\bootmui.txt) do (
if exist "ISOFOLDER\sources\%langid%\%%A" echo add 'ISOFOLDER^\sources^\%langid%^\%%A' '^\sources^\%langid%^\%%A'>>bin\boot-wim.txt
)
"%wimlib%" export "%MetadataESD%" 2 ISOFOLDER\sources\boot.wim "Microsoft Windows Setup (%arch%)" "Microsoft Windows Setup (%arch%)" --boot
"%wimlib%" update ISOFOLDER\sources\boot.wim 2 < bin\boot-wim.txt 1>nul 2>nul
"%wimlib%" info ISOFOLDER\sources\boot.wim 2 --image-property FLAGS=2 1>nul 2>nul
"%wimlib%" optimize ISOFOLDER\sources\boot.wim
del /f /q bin\boot-wim.txt >nul 2>&1
del /f /q ISOFOLDER\sources\xmllite.dll >nul 2>&1
exit /b

:uups_ref
echo.
echo ============================================================
echo Preparing Reference ESDs . . .
echo ============================================================
echo.
if exist "%UUP%\*.xml.cab" if exist "%UUP%\Metadata\*" move /y "%UUP%\*.xml.cab" "%UUP%\Metadata\" 1>nul 2>nul
if exist "%UUP%\*.cab" (
for /f "delims=" %%i in ('dir /b /a:-d "%UUP%\*.cab"') do (
	del /f /q temp\update.mum 1>nul 2>nul
	expand.exe -f:update.mum "%UUP%\%%i" .\temp 1>nul 2>nul
	if exist "temp\update.mum" call :uups_cab "%%i"
	)
)
IF %EXPRESS%==1 (
for /f "delims=" %%i in ('dir /b /a:d /o:-n "%UUP%\"') do call :uups_dir "%%i"
)
if exist "%UUP%\Metadata\*.xml.cab" copy /y "%UUP%\Metadata\*.xml.cab" "%UUP%\" 1>nul 2>nul
exit /b

:uups_dir
if /i "%~1"=="Metadata" exit /b
echo %~1| find /i "RetailDemo" 1>nul && exit /b
echo %~1| find /i "Holographic-Desktop-FOD" 1>nul && exit /b
echo %~1| find /i "Windows10.0-KB" 1>nul && exit /b
for /f "tokens=2 delims=_~" %%i in ('echo %~1') do set pack=%%i
if exist "%CD%\temp\%pack%.ESD" exit /b
echo DIR-^>ESD: %pack%
rmdir /s /q "%UUP%\%~1\$dpx$.tmp" 1>nul 2>nul
"%wimlib%" capture "%UUP%\%~1" "temp\%pack%.ESD" --compress=%level% --check --no-acls --norpfix "%pack%" "%pack%" >nul
exit /b

:uups_cab
echo %~1| find /i "RetailDemo" 1>nul && exit /b
echo %~1| find /i "Holographic-Desktop-FOD" 1>nul && exit /b
echo %~1| find /i "Windows10.0-KB" 1>nul && exit /b
set pack=%~n1
if exist "%CD%\temp\%pack%.ESD" exit /b
echo CAB-^>ESD: %pack%
md temp\%pack%
expand.exe -f:* "%UUP%\%pack%.cab" temp\%pack%\ >nul
"%wimlib%" capture "temp\%pack%" "temp\%pack%.ESD" --compress=%level% --check --no-acls --norpfix "%pack%" "%pack%" >nul
rmdir /s /q temp\%pack%
exit /b

:uups_esd
for /f "usebackq  delims=" %%b in (`find /n /v "" temp\uups_esd.txt ^| find "[%1]"`) do set uups_esd=%%b
if %1 GEQ 1 set uups_esd=%uups_esd:~3%
if %1 GEQ 10 set uups_esd=%uups_esd:~1%
if %1 GEQ 100 set uups_esd=%uups_esd:~1%
set "uups_esd%1=%uups_esd%"
for /f "tokens=1* delims=: " %%i in ('bin\wimlib-imagex info "%UUP%\%uups_esd%" 3 ^| findstr /b "Name"') do set "name=%%j"
for /f "tokens=3 delims=: " %%i in ('bin\wimlib-imagex info "%UUP%\%uups_esd%" 3 ^| findstr /b "Edition"') do set "edition%1=%%i"
for /f "tokens=3 delims=: " %%i in ('bin\wimlib-imagex info "%UUP%\%uups_esd%" 3 ^| find /i "Default"') do set "langid%1=%%i"
for /f "tokens=2 delims=: " %%i in ('bin\wimlib-imagex info "%UUP%\%uups_esd%" 3 ^| find /i "Architecture"') do set "arch%1=%%i"
if /i !arch%1!==x86_64 set "arch%1=x64"
set "name%1=!name! (!arch%1! / !langid%1!)"
exit /b

:uups_backup
echo.
echo ============================================================
echo Backing up Reference ESDs . . .
echo ============================================================
echo.
IF %EXPRESS%==1 (
mkdir "%CD%\CanonicalUUP" >nul 2>&1
move /y "%CD%\temp\*.ESD" "%CD%\CanonicalUUP\" >nul 2>&1
for /L %%i in (1, 1, %uups_esd_num%) do (copy /y "%UUP%\!uups_esd%%i!" "%CD%\CanonicalUUP\" >nul 2>&1)
) else (
mkdir "%UUP%\Original" >nul 2>&1
move /y "%UUP%\*.CAB" "%UUP%\Original\" >nul 2>&1
move /y "%CD%\temp\*.ESD" "%UUP%\" >nul 2>&1
)
exit /b

:setdate
if /i %1==Jan set "isotime=01/%isotime%"
if /i %1==Feb set "isotime=02/%isotime%"
if /i %1==Mar set "isotime=03/%isotime%"
if /i %1==Apr set "isotime=04/%isotime%"
if /i %1==May set "isotime=05/%isotime%"
if /i %1==Jun set "isotime=06/%isotime%"
if /i %1==Jul set "isotime=07/%isotime%"
if /i %1==Aug set "isotime=08/%isotime%"
if /i %1==Sep set "isotime=09/%isotime%"
if /i %1==Oct set "isotime=10/%isotime%"
if /i %1==Nov set "isotime=11/%isotime%"
if /i %1==Dec set "isotime=12/%isotime%"
exit /b

:setmmm
if /i %1==Jan set "datetime=%yyy:~2%01%ddd%"
if /i %1==Feb set "datetime=%yyy:~2%02%ddd%"
if /i %1==Mar set "datetime=%yyy:~2%03%ddd%"
if /i %1==Apr set "datetime=%yyy:~2%04%ddd%"
if /i %1==May set "datetime=%yyy:~2%05%ddd%"
if /i %1==Jun set "datetime=%yyy:~2%06%ddd%"
if /i %1==Jul set "datetime=%yyy:~2%07%ddd%"
if /i %1==Aug set "datetime=%yyy:~2%08%ddd%"
if /i %1==Sep set "datetime=%yyy:~2%09%ddd%"
if /i %1==Oct set "datetime=%yyy:~2%10%ddd%"
if /i %1==Nov set "datetime=%yyy:~2%11%ddd%"
if /i %1==Dec set "datetime=%yyy:~2%12%ddd%"
exit /b

:QUIT
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
if exist bin\temp\ rmdir /s /q bin\temp\
if exist temp\ rmdir /s /q temp\
exit