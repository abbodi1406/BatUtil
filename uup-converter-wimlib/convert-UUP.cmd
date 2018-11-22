@echo off

:: Change to 1 to start the process directly, it will create ISO with install.wim by default
set AutoStart=0

:: Change to 1 to integrate updates (if detected) into install.wim/boot.wim/winre.wim
set AddUpdates=0

:: Set to 1 to reset OS image base and remove superseded components (default is to compress them)
set ResetBase=0

:: Change to 1 to start create_virtual_editions.cmd directly after conversion
set StartVirtual=0

:: Change to 1 for not creating ISO file, distribution folder will be kept
set SkipISO=0

:: Change to 1 for not adding winre.wim to install.wim/install.esd
set SkipWinRE=0

:: Change to 1 to keep converted Reference ESDs
set RefESD=0

rem script:	   abbodi1406, @rgadguard
rem wimlib:	   synchronicity
rem offlinereg: erwan.l
rem Thanks to: @Ratiborus58, @NecrosoftCore, @DiamondMonday, @WzorNET

set "params=%*"
if not "%~1"=="" (
set "params=%params:"=%"
)
cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  cmd /u /c echo set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~dp0"" && ""%~dpnx0"" ""%params%""", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" 1>nul 2>nul && exit /B )

title UUP -^> ISO
for %%a in (wimlib-imagex,7z,imagex,offlinereg) do (
if not exist "%~dp0bin\%%a.exe" (echo Error: required %%a.exe is missing&pause&exit)
)
if /i "%PROCESSOR_ARCHITECTURE%" equ "AMD64" (set "wimlib=%~dp0bin\bin64\wimlib-imagex.exe") else (set "wimlib=%~dp0bin\wimlib-imagex.exe")
cd /d "%~dp0"
setlocal EnableExtensions
setlocal EnableDelayedExpansion
color 1f
set UUP=
set ERRORTEMP=
set PREPARED=0
set VOL=0
set EXPRESS=0
set AIO=0
set FixDisplay=0
set uups_esd_num=0
if %RefESD%==1 (set level=maximum) else (set level=fast)
if exist bin\temp\ rmdir /s /q bin\temp\
if exist temp\ rmdir /s /q temp\
mkdir bin\temp
mkdir temp
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
set "dismroot=%windir%\system32\dism.exe"
set "mountdir=%SystemDrive%\MountUUP"
set "line============================================================="

:checkadk
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 1>nul 2>nul || set wowRegKeyPathFound=0
reg query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 1>nul 2>nul || set regKeyPathFound=0
if %wowRegKeyPathFound% EQU 0 (
  if %regKeyPathFound% EQU 0 (
    set ADK=0&goto :precheck
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i IN ('reg query "%regKeyPath%" /v KitsRoot10') do (set "KitsRoot=%%j")
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
set "dismroot=%DandIRoot%\%PROCESSOR_ARCHITECTURE%\DISM\dism.exe"
set ADK=1
if not exist "%dismroot%" set ADK=0&set "dismroot=%windir%\system32\dism.exe"

:precheck
set _dism="%dismroot%" /English
set W10UI=0
if %winbuild% geq 10240 (
set W10UI=1
) else (
if %ADK%==1 set W10UI=1
)
if not "%params%"=="" (if exist "%params%\*.esd" set "UUP=%params%"&goto :check)
if not "%~1"=="" (if exist "%~1\*.esd" set "UUP=%~1"&goto :check)
if exist "%CD%\UUPs\*.esd" set "UUP=%CD%\UUPs"&goto :check

:prompt
cls
set UUP=
echo.
echo %line%
echo Enter / Paste the path to UUP files directory
echo ^(without quotes marks "" even if the path contains spaces^)
echo %line%
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
if exist "%UUP%\*%%A_*.esd" dir /b /a:-d "%UUP%\*%%A_*.esd">>temp\uups_esd.txt 2>nul
)
for /f "tokens=3 delims=: " %%i in ('find /v /n /c "" temp\uups_esd.txt') do set uups_esd_num=%%i
if %uups_esd_num% equ 0 (
echo.
echo %line%
echo ERROR: UUP Edition file is not found in specified directory
echo %line%
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
if %AutoStart%==1 (set AIO=1&set WIMFILE=install.wim&goto :ISO)
cls
set userinp=
echo %line%
echo       UUP directory contains multiple editions files:
echo %line%
for /L %%i in (1, 1, %uups_esd_num%) do (
echo %%i. !name%%i!
)
echo %line%
echo Enter edition number to create, or zero '0' to create AIO
echo %line%
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
echo %line%
echo.       1 - Create ISO with install.wim
echo.       2 - Create install.wim
echo.       3 - UUP Edition info
if %EXPRESS%==0 (
echo.       4 - Create ISO with install.esd
echo.       5 - Create install.esd
)
if exist "%UUP%\*Windows10*KB*.cab" if %W10UI%==1 (
echo ____________________________________________________________
if %AddUpdates%==1 (echo.       9 - Add Updates: Yes) else (echo.       9 - Add Updates: No)
)
if %W10UI%==0 (
echo ____________________________________________________________
echo Warning:
echo neither Windows 10 Host OS or ADK is detected
echo boot.wim will be limited winre.wim
)
echo.
echo %line%
set /p userinp= ^> Enter your option and press "Enter": 
if "%userinp%"=="" goto :QUIT
set userinp=%userinp:~0,1%
if %userinp%==0 goto :QUIT
if %userinp%==9 (if %AddUpdates%==0 (set AddUpdates=1) else (set AddUpdates=0))&goto :MAINMENU
if %userinp%==5 if %EXPRESS%==0 (set WIMFILE=install.esd&goto :Single)
if %userinp%==4 if %EXPRESS%==0 (set WIMFILE=install.esd&goto :ISO)
if %userinp%==3 goto :INFO
if %userinp%==2 (set WIMFILE=install.wim&goto :Single)
if %userinp%==1 (set WIMFILE=install.wim&goto :ISO)
goto :MAINMENU

:AIOMENU
set AIO=1
cls
set userinp=
echo %line%
echo.       1 - Create AIO ISO with install.wim
echo.       2 - Create AIO install.wim
echo.       3 - UUP Editions info
if %EXPRESS%==0 (
echo.       4 - Create AIO ISO with install.esd
echo.       5 - Create AIO install.esd
)
if exist "%UUP%\*Windows10*KB*.cab" if %W10UI%==1 (
echo ____________________________________________________________
if %AddUpdates%==1 (echo.       9 - Add Updates: Yes) else (echo.       9 - Add Updates: No)
)
if %W10UI%==0 (
echo ____________________________________________________________
echo Warning:
echo neither Windows 10 Host OS or ADK is detected
echo boot.wim will be limited winre.wim
)
echo.
echo %line%
set /p userinp= ^> Enter your option and press "Enter": 
if "%userinp%"=="" goto :QUIT
set userinp=%userinp:~0,1%
if %userinp%==0 goto :QUIT
if %userinp%==9 (if %AddUpdates%==0 (set AddUpdates=1) else (set AddUpdates=0))&goto :AIOMENU
if %userinp%==5 if %EXPRESS%==0 (set WIMFILE=install.esd&goto :Single)
if %userinp%==4 if %EXPRESS%==0 (set WIMFILE=install.esd&goto :ISO)
if %userinp%==3 goto :INFOAIO
if %userinp%==2 (set WIMFILE=install.wim&goto :Single)
if %userinp%==1 (set WIMFILE=install.wim&goto :ISO)
goto :AIOMENU

:ISO
cls
if %PREPARED%==0 call :PREPARE
call :uups_ref
echo.
echo %line%
echo Creating Setup Media Layout . . .
echo %line%
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
echo.
"%wimlib%" apply "%MetadataESD%" 1 ISOFOLDER\ --no-acls --no-attributes >nul 2>&1
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 (echo.&echo Errors were reported during apply.&echo.&echo Press any key to exit.&pause >nul&goto :QUIT)
del /f /q ISOFOLDER\MediaMeta.xml >nul 2>&1
rmdir /s /q ISOFOLDER\sources\uup\ >nul 2>&1
if %AIO%==1 del /f /q ISOFOLDER\sources\ei.cfg >nul 2>&1
echo.
echo %line%
echo Creating boot.wim . . .
echo %line%
echo.
"%wimlib%" export "%MetadataESD%" 2 ISOFOLDER\sources\boot.wim --compress=LZX:15 --boot
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 (echo.&echo Errors were reported during export.&echo.&echo Press any key to exit.&pause >nul&goto :QUIT)
if %SkipWinRE%==0 copy /y ISOFOLDER\sources\boot.wim temp\winre.wim >nul
"%wimlib%" info ISOFOLDER\sources\boot.wim 1 --image-property FLAGS=9 1>nul 2>nul
if %W10UI%==1 (
  call :BootWIM
  ) else (
  copy /y .\bin\reagent.xml .\ISOFOLDER\sources >nul 2>&1
)
echo.
echo %line%
echo Creating %WIMFILE% . . .
echo %line%
echo.
for /f "tokens=5-10 delims=: " %%G in ('bin\wimlib-imagex info "%MetadataESD%" 3 ^| find /i "Last Modification Time"') do (set mmm=%%G&set "isotime=%%H/%%L,%%I:%%J:%%K")
call :setdate %mmm%
if exist "temp\*.ESD" (set _rrr=--ref="temp\*.esd") else (set "_rrr=")
if /i %WIMFILE%==install.esd (
  "%wimlib%" export "%MetadataESD%" 3 ISOFOLDER\sources\%WIMFILE% --ref="%UUP%\*.esd" %_rrr%
) else (
  "%wimlib%" export "%MetadataESD%" 3 ISOFOLDER\sources\%WIMFILE% --ref="%UUP%\*.esd" %_rrr% --compress=maximum
)
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 (echo.&echo Errors were reported during export.&echo.&echo Press any key to exit.&pause >nul&goto :QUIT)
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
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 (echo.&echo Errors were reported during export.&echo.&echo Press any key to exit.&pause >nul&goto :QUIT)
if %SkipWinRE%==0 (
echo.
echo %line%
echo Adding winre.wim to %WIMFILE% . . .
echo %line%
echo.
"%wimlib%" update ISOFOLDER\sources\%WIMFILE% 1 --command="add 'temp\winre.wim' '\windows\system32\recovery\winre.wim'" 1>nul 2>nul
if %AIO%==1 for /L %%i in (2, 1, %uups_esd_num%) do (
  "%wimlib%" update ISOFOLDER\sources\%WIMFILE% %%i --command="add 'temp\winre.wim' '\windows\system32\recovery\winre.wim'" 1>nul 2>nul
  )
)
if %AddUpdates%==1 if %WIMFILE%==install.wim if exist "%UUP%\*Windows10*KB*.cab" call :uups_update
if %StartVirtual%==1 if %WIMFILE%==install.wim set SkipISO=1
if %SkipISO%==1 (
  if %RefESD%==1 call :uups_backup
  ren ISOFOLDER %DVDISO%
  if %StartVirtual%==1 if %WIMFILE%==install.wim (
  if %AutoStart%==1 (start /i "" create_virtual_editions.cmd auto&goto :QUIT) else (start /i "" create_virtual_editions.cmd manu&goto :QUIT)
  )
  echo.
  echo %line%
  echo Done. You chose not to create iso file.
  echo %line%
  echo.
  echo Press any key to exit.
  pause >nul
  goto :QUIT
)
echo.
echo %line%
echo Creating ISO . . .
echo %line%
bin\cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -g -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 (
  if %RefESD%==1 call :uups_backup
  ren ISOFOLDER %DVDISO%
  echo.
  echo Errors were reported during ISO creation.
  echo.
  echo Press any key to exit.
  pause >nul
  goto :QUIT
)
if %RefESD%==1 call :uups_backup&echo Finished
rmdir /s /q ISOFOLDER\
echo.
echo Press any key to exit.
pause >nul
goto :QUIT

:Single
cls
if exist "%CD%\%WIMFILE%" (
echo.
echo %line%
echo An %WIMFILE% file is already present in the current folder
echo %line%
echo.
echo Press any key to exit.
pause >nul
goto :QUIT
)
if %PREPARED%==0 call :PREPARE
call :uups_ref
echo.
echo %line%
echo Creating %WIMFILE% . . .
echo %line%
echo.
if %AIO%==1 set "MetadataESD=%UUP%\%uups_esd1%"
if exist "temp\*.ESD" (set _rrr=--ref="temp\*.esd") else (set "_rrr=")
if /i %WIMFILE%==install.esd (
  "%wimlib%" export "%MetadataESD%" 3 %WIMFILE% --ref="%UUP%\*.esd" %_rrr%
) else (
  "%wimlib%" export "%MetadataESD%" 3 %WIMFILE% --ref="%UUP%\*.esd" %_rrr% --compress=maximum
)
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 (echo.&echo Errors were reported during export.&echo.&echo Press any key to exit.&pause >nul&goto :QUIT)
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
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 (echo.&echo Errors were reported during export.&echo.&echo Press any key to exit.&pause >nul&goto :QUIT)
if %SkipWinRE%==0 (
echo.
echo %line%
echo Creating winre.wim . . .
echo %line%
echo.
"%wimlib%" export "%MetadataESD%" 2 temp\winre.wim --compress=maximum
echo.
echo %line%
echo Adding winre.wim to %WIMFILE% . . .
echo %line%
echo.
"%wimlib%" update %WIMFILE% 1 --command="add 'temp\winre.wim' '\windows\system32\recovery\winre.wim'" 1>nul 2>nul
if %AIO%==1 for /L %%i in (2, 1, %uups_esd_num%) do (
  "%wimlib%" update %WIMFILE% %%i --command="add 'temp\winre.wim' '\windows\system32\recovery\winre.wim'" 1>nul 2>nul
  )
)
if %AddUpdates%==1 if %WIMFILE%==install.wim if exist "%UUP%\*Windows10*KB*.cab" call :uups_update 2
if %RefESD%==1 call :uups_backup
echo.
echo Done.
echo.
echo Press any key to exit.
pause >nul
goto :QUIT

:INFO
if %PREPARED%==0 call :PREPARE
cls
echo %line%
echo                     UUP Contents Info
echo %line%
echo      Arch: %arch%
echo  Language: %langid%
echo   Version: %ver1%.%ver2%.%build%.%svcbuild%
echo    Branch: %branch%
echo        OS: %_os%
echo.
echo Press any key to continue . . .
pause >nul
goto :MAINMENU

:INFOAIO
if %PREPARED%==0 call :PREPARE
cls
echo %line%
echo                     UUP Contents Info
echo %line%
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
echo %line%
echo Checking UUP Info . . .
echo %line%
set PREPARED=1
if %AIO%==1 set "MetadataESD=%UUP%\%uups_esd1%"&set "arch=%arch1%"&set "langid=%langid1%"
bin\wimlib-imagex info "%MetadataESD%" 3 >bin\info.txt 2>&1
for /f "tokens=1* delims=: " %%i in ('findstr /b "Name" bin\info.txt') do set "_os=%%j"
for /f "tokens=2 delims=: " %%i in ('findstr /b "Build" bin\info.txt') do set build=%%i
for /f "tokens=4 delims=: " %%i in ('find /i "Service Pack Build" bin\info.txt') do set svcbuild=%%i
for /f "tokens=3 delims=: " %%i in ('find /i "Major" bin\info.txt') do set ver1=%%i
for /f "tokens=3 delims=: " %%i in ('find /i "Minor" bin\info.txt') do set ver2=%%i
del /f /q bin\info.txt >nul 2>&1
for /f "tokens=3 delims=<>" %%i in ('bin\imagex /info "%MetadataESD%" 3 ^| find /i "<DISPLAYNAME>" 2^>nul') do if /i "%%i"=="/DISPLAYNAME" (set FixDisplay=1)
if %FixDisplay%==1 if %AIO%==1 for /L %%i in (2, 1, %uups_esd_num%) do (
for /f "tokens=1* delims=: " %%a in ('bin\wimlib-imagex info "%UUP%\!uups_esd%%i!" 3 ^| findstr /b "Name"') do set "_os%%i=%%b"
)
"%wimlib%" extract "%MetadataESD%" 1 sources\ei.cfg --dest-dir=.\bin\temp --no-acls --no-attributes >nul 2>&1
if exist "bin\temp\ei.cfg" type .\bin\temp\ei.cfg 2>nul | find /i "Volume" 1>nul && set VOL=1
"%wimlib%" extract "%MetadataESD%" 1 sources\setuphost.exe --dest-dir=.\bin\temp --no-acls --no-attributes >nul 2>&1
bin\7z.exe l .\bin\temp\setuphost.exe >.\bin\temp\version.txt 2>&1
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\temp\version.txt" 2^>nul') do (set version=%%i.%%j&set branch=%%k&set labeldate=%%l)
if /i %arch%==x86 (set _ss=x86) else if /i %arch%==x64 (set _ss=amd64) else (set _ss=arm64)
"%wimlib%" extract "%MetadataESD%" 3 Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision* --dest-dir=.\bin\temp --no-acls --no-attributes >nul 2>&1
for /f "tokens=6,7 delims=_." %%i in ('dir /b /a:-d /od .\bin\temp\*.manifest') do set revision=%%i.%%j
if not "%version%"=="%revision%" (
set version=%revision%
"%wimlib%" extract "%MetadataESD%" 3 Windows\servicing\Packages\Package_for_RollupFix*.mum --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul_1_2%
for /f %%i in ('dir /b /a:-d /od .\bin\temp\Package_for_RollupFix*.mum') do set "mumfile=%~dp0bin\temp\%%i"
for /f "tokens=2 delims==" %%i in ('wmic datafile where "name='!mumfile:\=\\!'" get LastModified /value') do set "mumdate=%%i"
set "labeldate=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
)
set _label2=
if /i "%branch%"=="WinBuild" (
"%wimlib%" extract "%MetadataESD%" 3 \Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes >nul
for /f "tokens=3 delims==:" %%a in ('"bin\offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion" getvalue BuildLabEx" 2^>nul') do if not errorlevel 1 (for /f "tokens=1-5 delims=." %%i in ('echo %%~a') do set _label2=%%i.%%j.%%m.%%l_CLIENT&set branch=%%l)
)
if defined _label2 (set _label=%_label2%) else (set _label=%version%.%labeldate%.%branch%_CLIENT)
rmdir /s /q .\bin\temp >nul 2>&1

:setlabel
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
if /i %editionid%==Professional (if %VOL%==1 (set DVDLABEL=CPRA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%PROFESSIONALVL_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PRO_OEMRET_%archl%FRE_%langid%))
if /i %editionid%==ProfessionalN (if %VOL%==1 (set DVDLABEL=CPRNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%PROFESSIONALNVL_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PRON_OEMRET_%archl%FRE_%langid%))
if /i %editionid%==Education (if %VOL%==1 (set DVDLABEL=CEDA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%EDUCATION_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CEDA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%EDUCATION_RET_%archl%FRE_%langid%))
if /i %editionid%==EducationN (if %VOL%==1 (set DVDLABEL=CEDNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%EDUCATIONN_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CEDNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%EDUCATIONN_RET_%archl%FRE_%langid%))
if /i %editionid%==Enterprise set DVDLABEL=CENA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISE_VOL_%archl%FRE_%langid%
if /i %editionid%==EnterpriseN set DVDLABEL=CENNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISEN_VOL_%archl%FRE_%langid%
if /i %editionid%==Cloud set DVDLABEL=CWCA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CLOUD_OEMRET_%archl%FRE_%langid%
if /i %editionid%==CloudN set DVDLABEL=CWCNNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CLOUDN_OEMRET_%archl%FRE_%langid%
exit /b

:BootWIM
"%wimlib%" info ISOFOLDER\sources\boot.wim 1 "Microsoft Windows PE (%arch%)" "Microsoft Windows PE (%arch%)" 1>nul 2>nul
"%wimlib%" update ISOFOLDER\sources\boot.wim 1 --command="delete '\Windows\system32\winpeshl.ini'" 1>nul 2>nul
if exist "%mountdir%" (
%_dism% /Unmount-Wim /MountDir:"%mountdir%" /Discard 1>nul 2>nul
%_dism% /Cleanup-Wim 1>nul 2>nul
rmdir /s /q "%mountdir%" 1>nul 2>nul
)
if not exist "%mountdir%" mkdir "%mountdir%"
%_dism% /Quiet /Mount-Wim /Wimfile:ISOFOLDER\sources\boot.wim /Index:1 /MountDir:"%mountdir%" 1>nul 2>nul
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 (
%_dism% /Unmount-Wim /MountDir:"%mountdir%" /Discard 1>nul 2>nul
%_dism% /Cleanup-Wim 1>nul 2>nul
copy /y temp\winre.wim ISOFOLDER\sources\boot.wim >nul
"%wimlib%" info ISOFOLDER\sources\boot.wim 1 --image-property FLAGS=9 1>nul 2>nul
copy /y .\bin\reagent.xml .\ISOFOLDER\sources >nul
exit /b
)
%_dism% /Quiet /Image:"%mountdir%" /Set-TargetPath:X:\$windows.~bt\
%_dism% /Quiet /Unmount-Wim /MountDir:"%mountdir%" /Commit
rmdir /s /q "%mountdir%" 1>nul 2>nul
"%wimlib%" extract "%MetadataESD%" 3 Windows\system32\xmllite.dll --dest-dir=ISOFOLDER\sources --no-acls --no-attributes >nul 2>&1
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
echo %line%
echo Preparing Reference ESDs . . .
echo %line%
echo.
if exist "%UUP%\*.xml.cab" if exist "%UUP%\Metadata\*" move /y "%UUP%\*.xml.cab" "%UUP%\Metadata\" 1>nul 2>nul
if exist "%UUP%\*.cab" (
for /f "delims=" %%i in ('dir /b /a:-d "%UUP%\*.cab"') do (
	del /f /q temp\update.mum 1>nul 2>nul
	expand.exe -f:update.mum "%UUP%\%%i" .\temp 1>nul 2>nul
	if exist "temp\update.mum" call :uups_cab "%%i"
	)
)
if %EXPRESS%==1 (
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
expand.exe -f:* "%UUP%\%pack%.cab" temp\%pack%\ 1>nul 2>nul
"%wimlib%" capture "temp\%pack%" "temp\%pack%.ESD" --compress=%level% --check --no-acls --norpfix "%pack%" "%pack%" >nul
rmdir /s /q temp\%pack%
exit /b

:uups_esd
for /f "usebackq  delims=" %%b in (`find /n /v "" temp\uups_esd.txt ^| find "[%1]"`) do set uups_esd=%%b
if %1 geq 1 set uups_esd=%uups_esd:~3%
if %1 geq 10 set uups_esd=%uups_esd:~1%
if %1 geq 100 set uups_esd=%uups_esd:~1%
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
echo %line%
echo Backing up Reference ESDs . . .
echo %line%
echo.
if %EXPRESS%==1 (
mkdir "%CD%\CanonicalUUP" >nul 2>&1
move /y "%CD%\temp\*.ESD" "%CD%\CanonicalUUP\" >nul 2>&1
for /L %%i in (1, 1, %uups_esd_num%) do (copy /y "%UUP%\!uups_esd%%i!" "%CD%\CanonicalUUP\" >nul 2>&1)
) else (
mkdir "%UUP%\Original" >nul 2>&1
move /y "%UUP%\*.CAB" "%UUP%\Original\" >nul 2>&1
move /y "%CD%\temp\*.ESD" "%UUP%\" >nul 2>&1
)
exit /b

:uups_update
if %W10UI%==0 exit /b
set directcab=0
set dvd=0
set wim=0
if "%1"=="" (
set dvd=1
set "target=%~dp0ISOFOLDER"
) else (
set wim=1
set "target=%~dp0install.wim"
)
echo.
echo %line%
if %dvd%==1 (
echo Updating Distribution Media . . .
echo %line%
for /f "tokens=3 delims=: " %%i in ('bin\wimlib-imagex info "%target%\sources\install.wim" ^| findstr /c:"Image Count"') do set imgcount=%%i
)
if %wim%==1 (
echo Updating install.wim . . .
echo %line%
for /f "tokens=3 delims=: " %%i in ('bin\wimlib-imagex info "%target%" ^| findstr /c:"Image Count"') do set imgcount=%%i
)
set "repo=%UUP%"
set "cab_dir=%~d0\W10UItemp"
set "mountdir=%SystemDrive%\W10UImount"
set "winremount=%SystemDrive%\W10UImountre"
DEL /F /Q %systemroot%\Logs\DISM\* >nul 2>&1
call :extract
if %wim%==1 (
call :mount "%target%"
)
if %dvd%==1 (
call :mount "%target%\sources\install.wim"
if exist "%~dp0winre.wim" del /f /q "%~dp0winre.wim" >nul
set imgcount=2
call :mount "%target%\sources\boot.wim"
)
cd /d "%~dp0"
if exist "%cab_dir%\*" (
echo.
echo %line%
echo Removing temporary files . . .
echo %line%
echo.
rmdir /s /q "%cab_dir%" >nul
)
if exist "%mountdir%" rmdir /s /q "%mountdir%" >nul
if exist "%winremount%" rmdir /s /q "%winremount%" >nul
if %wim%==1 exit /b

for /f "tokens=3 delims=: " %%i in ('bin\wimlib-imagex info "%target%\sources\install.wim" ^| findstr /c:"Image Count"') do set images=%%i
for /L %%i in (1,1,%images%) do (
  for /f "tokens=3 delims=<>" %%a in ('bin\imagex /info "%target%\sources\install.wim" %%i ^| find /i "<HIGHPART>"') do set "HIGHPART=%%a"
  for /f "tokens=3 delims=<>" %%a in ('bin\imagex /info "%target%\sources\install.wim" %%i ^| find /i "<LOWPART>"') do set "LOWPART=%%a"
  bin\wimlib-imagex info "%target%\sources\install.wim" %%i --image-property CREATIONTIME/HIGHPART=!HIGHPART! --image-property CREATIONTIME/LOWPART=!LOWPART! >nul
)
if defined isoupdate (for %%a in (%isoupdate%) do (expand.exe -f:* "%repo%\%%a" "%target%\sources" >nul))
bin\7z.exe l "%target%\sources\setuphost.exe" >.\bin\version.txt 2>&1
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\version.txt" 2^>nul') do (set version=%%i.%%j&set branch=%%k&set labeldate=%%l)
del /f /q .\bin\version.txt >nul 2>&1
if /i not "%branch%"=="WinBuild" (set _label=%version%.%labeldate%.%branch%_CLIENT)
if not defined isover (call :setlabel&exit /b)
if %isover:.=% gtr %version:.=% (set _label=%isover%.%isodate%.%isobranch%_CLIENT)
call :setlabel
exit /b

:extract
if exist "%cab_dir%" rmdir /s /q "%cab_dir%" >nul
if not exist "%cab_dir%" mkdir "%cab_dir%"
set _cab=0
cd /d "%repo%"
for /f %%a in ('dir /b *Windows10*KB*.cab') do (call set /a _cab+=1)
echo.
echo %line%
echo Extracting files from update cabinets . . .
echo %line%
echo.
set count=0&set isoupdate=
for /f %%G in ('dir /b *Windows10*KB*.cab') do (call :cab2 %%G)
goto :eof

:cab2
set "package=%1"
set "dest=%cab_dir%\%~n1"
set /a count+=1
echo %count%/%_cab%: %package%
if exist "%dest%" rmdir /s /q "%dest%" >nul 2>&1
mkdir "%dest%"
expand.exe -f:* "%package%" "%dest%" 1>nul 2>nul || (set "directcab=!directcab! %package%"&goto :eof)
if exist "%dest%\*.psf.cix.xml" goto :eof
if not exist "%dest%\update.mum" (set "isoupdate=!isoupdate! %package%"&goto :eof)
if not exist "%dest%\*cablist.ini" goto :eof
expand.exe -f:* "%dest%\*.cab" "%dest%" 1>nul 2>nul || (set "directcab=!directcab! %package%"&goto :eof)
del /f /q "%dest%\*cablist.ini" >nul 2>&1
del /f /q "%dest%\*.cab" >nul 2>&1
goto :eof

:update
set verb=1
set "mumtarget=%mountdir%"
set dismtarget=/image:"%mountdir%"
if not "%1"=="" (
set verb=0
set "mumtarget=%winremount%"
set dismtarget=/image:"%winremount%"
)
set servicingstack=
set cumulative=
set ldr=
for /f %%G in ('dir /b *Windows10*KB*.cab') do (call :mum %%G)
if not defined ldr if not defined cumulative if not defined servicingstack goto :eof
if %verb%==1 (
echo.
echo %line%
echo Installing Updates . . .
echo %line%
)
if defined servicingstack (
%_dism% %dismtarget% /Add-Package %servicingstack%
if not defined ldr if not defined cumulative call :cleanup
)
if not defined ldr if not defined cumulative goto :eof
if defined ldr %_dism% %dismtarget% /Add-Package %ldr%
if %errorlevel% equ 1726 %_dism% %dismtarget% /Get-Packages >nul
if defined cumulative %_dism% %dismtarget% /Add-Package %cumulative%
if %errorlevel% equ 1726 %_dism% %dismtarget% /Get-Packages >nul
call :cleanup
goto :eof

:mum
set "package=%1"
set "dest=%cab_dir%\%~n1"
if not exist "%dest%\update.mum" goto :eof
if exist "%dest%\*.psf.cix.xml" goto :eof
if exist "%mumtarget%\sources\recovery\RecEnv.exe" (
findstr /i /m "WinPE" "%dest%\update.mum" 1>nul 2>nul || (findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" 1>nul 2>nul || (goto :eof))
findstr /i /m "WinPE-NetFx-Package" "%dest%\update.mum" 1>nul 2>nul && (findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" 1>nul 2>nul || (goto :eof))
)
if exist "%dest%\*_adobe-flash-for-windows_*.manifest" (
if not exist "%mumtarget%\Windows\servicing\packages\Adobe-Flash-For-Windows-Package*.mum" if not exist "%mumtarget%\Windows\servicing\packages\Microsoft-Windows-Client-Desktop-Required-Package*.mum" goto :eof
if "%build%" geq "16299" (
  set flash=0
  for /f "tokens=3 delims=<= " %%a in ('findstr /i "Edition" "%dest%\update.mum" 2^>nul') do if exist "%mumtarget%\Windows\servicing\packages\%%~a*.mum" set flash=1
  if "!flash!"=="0" goto :eof
  )
)
if exist "%dest%\*_microsoft-windows-servicingstack_*.manifest" (set "servicingstack=!servicingstack! /packagepath:%dest%\update.mum"&goto :eof)
for %%a in (%directcab%) do (
if /i !package!==%%a (set "ldr=!ldr! /packagepath:!package!"&goto :eof)
)
findstr /i /m "Package_for_RollupFix" "%dest%\update.mum" 1>nul 2>nul && (set "cumulative=!cumulative! /packagepath:%dest%\update.mum"&goto :eof)
set ldr=!ldr! /packagepath:%dest%\update.mum
goto :eof

:mount
if exist "%mountdir%" rmdir /s /q "%mountdir%" >nul
if exist "%winremount%" rmdir /s /q "%winremount%" >nul
if not exist "%mountdir%" mkdir "%mountdir%"
for /L %%i in (1, 1, %imgcount%) do (
echo.
echo %line%
echo Mounting %~nx1 - index %%i/%imgcount%
echo %line%
%_dism% /Mount-Wim /Wimfile:%1 /Index:%%i /MountDir:"%mountdir%"
if !errorlevel! neq 0 (
%_dism% /Unmount-Wim /MountDir:"%mountdir%" /Discard 1>nul 2>nul
%_dism% /Cleanup-Wim 1>nul 2>nul
goto :eof
)
call :update
if %dvd%==1 if exist "%mountdir%\sources\setup.exe" (
if defined isoupdate (for %%a in (%isoupdate%) do (expand.exe -f:* "%repo%\%%a" "%mountdir%\sources" >nul))
if exist "%mountdir%\sources\*.sdb" del /f /q "%mountdir%\sources\*.sdb" 1>nul 2>nul
if /i %arch%==x86 (set efifile=bootia32.efi&set sss=x86) else if /i %arch%==x64 (set efifile=bootx64.efi&set sss=amd64) else (set efifile=boota64.efi&set sss=arm64)
copy /y "%mountdir%\Windows\Boot\DVD\EFI\en-US\efisys.bin" "%target%\efi\microsoft\boot\" >nul
copy /y "%mountdir%\Windows\Boot\DVD\EFI\en-US\efisys_noprompt.bin" "%target%\efi\microsoft\boot\" %_Nul_1%
copy /y "%mountdir%\Windows\Boot\EFI\memtest.efi" "%target%\efi\microsoft\boot\" >nul
copy /y "%mountdir%\Windows\Boot\EFI\bootmgfw.efi" "%target%\efi\boot\!efifile!" >nul
copy /y "%mountdir%\Windows\Boot\EFI\bootmgr.efi" "%target%\" >nul
copy /y "%mountdir%\Windows\Boot\PCAT\bootmgr" "%target%\" >nul
copy /y "%mountdir%\Windows\Boot\PCAT\memtest.exe" "%target%\boot\" >nul
for /f "tokens=6,7 delims=_." %%i in ('dir /b /a:-d /od "%mountdir%\Windows\WinSxS\Manifests\!sss!_microsoft-windows-coreos-revision*.manifest"') do set "isover=%%i.%%j"
)
if %%i==1 if %dvd%==1 if not exist "%mountdir%\sources\recovery\RecEnv.exe" if exist "%mountdir%\Windows\servicing\Packages\Package_for_RollupFix*.mum" (
for /f %%i in ('dir /b /a:-d /od "%mountdir%\Windows\servicing\Packages\Package_for_RollupFix*.mum"') do set "mumfile=%mountdir%\Windows\servicing\Packages\%%i"
for /f "tokens=2 delims==" %%i in ('wmic datafile where "name='!mumfile:\=\\!'" get LastModified /value') do set "mumdate=%%i"
set "isodate=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
set "isotime=!mumdate:~4,2!/!mumdate:~6,2!/!mumdate:~0,4!,!mumdate:~8,2!:!mumdate:~10,2!:!mumdate:~12,2!"
set "isokey=Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
for /f %%a in ('%~dp0bin\offlinereg.exe "%mountdir%\Windows\system32\config\SOFTWARE" "!isokey!" enumkeys 2^>nul ^| find /i "Client.OS"') do if not errorlevel 1 (
  for /f "tokens=3 delims==:" %%i in ('%~dp0bin\offlinereg.exe "%mountdir%\Windows\system32\config\SOFTWARE" "!isokey!\%%a" getvalue Branch 2^>nul') do set "isobranch=%%i"
  )
)
if not exist "%mountdir%\sources\recovery\RecEnv.exe" attrib -S -H -I "%mountdir%\Windows\System32\Recovery\winre.wim" 1>nul 2>nul
if exist "%mountdir%\Windows\System32\Recovery\winre.wim" if not exist "%~dp0winre.wim" (
  echo.
  echo %line%
  echo Updating winre.wim . . .
  echo %line%
  if not exist "!winremount!" mkdir "!winremount!"
  copy "!mountdir!\Windows\System32\Recovery\winre.wim" "%~dp0winre.wim" >nul
  %_dism% /Mount-Wim /Wimfile:"%~dp0winre.wim" /Index:1 /MountDir:"!winremount!"
  call :update winre
  %_dism% /Unmount-Wim /MountDir:"!winremount!" /Commit
  %_dism% /Export-Image /SourceImageFile:"%~dp0winre.wim" /All /DestinationImageFile:"%~dp0temp.wim"
  move /y "%~dp0temp.wim" "%~dp0winre.wim" >nul
  set "mumtarget=!mountdir!"
  set dismtarget=/image:"!mountdir!"
)
if exist "%mountdir%\Windows\System32\Recovery\winre.wim" if exist "%~dp0winre.wim" (
echo.
echo %line%
echo Adding updated winre.wim . . .
echo %line%
echo.
copy /y "%~dp0winre.wim" "%mountdir%\Windows\System32\Recovery" >nul
)
echo.
echo %line%
echo Unmounting %~nx1 - index %%i/%imgcount%
echo %line%
%_dism% /Unmount-Wim /MountDir:"%mountdir%" /Commit
)
echo.
echo %line%
echo Rebuilding %~nx1 . . .
echo %line%
%_dism% /Export-Image /SourceImageFile:%1 /All /DestinationImageFile:"%~dp0temp.wim"
move /y "%~dp0temp.wim" %1 >nul
goto :eof

:cleanup
if exist "%mumtarget%\sources\recovery\RecEnv.exe" (
if %verb%==1 (
echo.
echo %line%
echo Cleaning up WinPE image . . .
echo %line%
)
set ksub=SOFTWIM
reg load HKLM\!ksub! "%mumtarget%\Windows\System32\Config\SOFTWARE" >nul
reg add HKLM\!ksub!\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d 1 /f >nul
reg unload HKLM\!ksub! >nul
%_dism% %dismtarget% /Cleanup-Image /StartComponentCleanup
if !errorlevel! equ 1726 %_dism% %dismtarget% /Get-Packages >nul
%_dism% %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase >nul
if !errorlevel! equ 1726 %_dism% %dismtarget% /Get-Packages >nul
call :cleanupmanual
goto :eof
)
if exist "%mumtarget%\Windows\WinSxS\pending.xml" call :cleanupmanual&goto :eof
echo.
echo %line%
echo Cleaning up OS image . . .
echo %line%
if %ResetBase%==1 (
set ksub=SOFTWIM
reg load HKLM\!ksub! "%mumtarget%\Windows\System32\Config\SOFTWARE" >nul
reg add HKLM\!ksub!\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v DisableResetbase /t REG_DWORD /d 0 /f >nul
reg add HKLM\!ksub!\Microsoft\Windows\CurrentVersion\SideBySide\Configuration /v SupersededActions /t REG_DWORD /d 1 /f >nul
reg unload HKLM\!ksub! >nul
)
%_dism% %dismtarget% /Cleanup-Image /StartComponentCleanup
if !errorlevel! equ 1726 %_dism% %dismtarget% /Get-Packages >nul
if %ResetBase%==1 (
%_dism% %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase >nul
if !errorlevel! equ 1726 %_dism% %dismtarget% /Get-Packages >nul
)
call :cleanupmanual
goto :eof

:cleanupmanual
if exist "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" (
takeown /f "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" /A 1>nul 2>nul
icacls "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" /grant *S-1-5-32-544:F 1>nul 2>nul
del /f /q "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" 1>nul 2>nul
)
if exist "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" (
takeown /f "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" /A 1>nul 2>nul
icacls "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" /grant *S-1-5-32-544:F 1>nul 2>nul
del /f /q "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" 1>nul 2>nul
)
if exist "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" (
takeown /f "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" /R /A 1>nul 2>nul
icacls "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" /grant *S-1-5-32-544:F /T 1>nul 2>nul
del /s /f /q "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" 1>nul 2>nul
)
if exist "%mumtarget%\Windows\inf\*.log" (
del /f /q "%mumtarget%\Windows\inf\*.log" 1>nul 2>nul
)
if exist "%mumtarget%\Windows\CbsTemp\*" (
for /f %%i in ('"dir /s /b /ad %mumtarget%\Windows\CbsTemp\*" %_Nul_2e%') do (RD /S /Q %%i 1>nul 2>nul)
del /s /f /q "%mumtarget%\Windows\CbsTemp\*" 1>nul 2>nul
)
goto :eof

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

:QUIT
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
if exist bin\temp\ rmdir /s /q bin\temp\
if exist temp\ rmdir /s /q temp\
exit