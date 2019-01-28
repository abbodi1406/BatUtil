@echo off
rem Enable menu to choose from multiple editions ESDs
SET MultiChoice=1

rem Check and unify different winre.wim in multiple editions ESDs
SET CheckWinre=1

rem Skip creating ISO file, distribution folder will be kept
SET SkipISO=0

rem script:     abbodi1406
rem initial:    @rgadguard
rem esddecrypt: qad, @tfwboredom
rem wimlib:     synchronicity
rem busybox:    mkuba50
rem offlinereg: erwan.l
rem aio efisys: cdob
rem cryptokey:  MrMagic, Chris123NT, mohitbajaj143, Superwzt, timster

if exist "%Windir%\Sysnative\reg.exe" (set "SysPath=%Windir%\Sysnative") else (set "SysPath=%Windir%\System32")
set "Path=%SysPath%;%Windir%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set xOS=x64
if /i %PROCESSOR_ARCHITECTURE%==x86 (if "%PROCESSOR_ARCHITEW6432%"=="" set xOS=x86)
set "params=%*"
if not "%~1"=="" (
set "params=%params:"=%"
)
cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  cmd /u /c echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~dp0"" && ""%~dpnx0"" ""%params%""", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" 1>nul 2>nul && exit /B )

title ESD ^> ISO
for %%a in (wimlib-imagex,7z,bcdedit,bfi,busybox,esddecrypt,imagex,offlinereg) do (
if not exist "%~dp0bin\%%a.exe" (echo Error: required %%a.exe is missing&pause&exit)
)
if /i "%xOS%" equ "x64" (set "wimlib=%~dp0bin\bin64\wimlib-imagex.exe") else (set "wimlib=%~dp0bin\wimlib-imagex.exe")
cd /d "%~dp0"
setlocal EnableDelayedExpansion
color 1f
SET Backup=OFF
SET ENCRYPTEDESD=
SET ERRORTEMP=
SET ENCRYPTED=0
SET MULTI=0
SET PREPARED=0
SET VOL=0
SET UnifyWinre=0
SET SINGLE=0
SET newkeys=0
SET "ramdiskoptions={7619dcc8-fafe-11d9-b411-000476eba25f}"

if not "%~1"=="" (set "ENCRYPTEDESD=%~1"&set "ENCRYPTEDESDN=%~nx1"&goto :check)
set _esd=0
if exist "*.esd" (for /f "delims=" %%i in ('dir /b /a:-d "*.esd"') do (call set /a _esd+=1))
if !_esd! equ 2 goto :dCheck
if !_esd! equ 0 goto :prompt1
if !_esd! gtr 1 goto :prompt2
for /f "delims=" %%i in ('dir /b /a:-d "*.esd"') do (set "ENCRYPTEDESD=%%i"&set "ENCRYPTEDESDN=%%i"&goto :check)

:prompt1
cls
echo.
echo ============================================================
echo Enter / Paste the complete path to the ESD file
echo ^(without quotes marks "" even if the path contains spaces^)
echo ============================================================
echo.
set /p "ENCRYPTEDESD="
if "%ENCRYPTEDESD%"=="" goto :QUIT
call :setvar "%ENCRYPTEDESD%"
goto :check

:setvar
SET "ENCRYPTEDESDN=%~nx1"
goto :eof

:prompt2
cls
echo.
echo ============================================================
echo Found more than one ESD file in the current directory
echo Enter the name of the desired file to process
echo You may use "Tab" button to ease the selection
echo ============================================================
echo.
set /p "ENCRYPTEDESD="
if "%ENCRYPTEDESD%"=="" goto :QUIT
SET "ENCRYPTEDESDN=%ENCRYPTEDESD%"
goto :check

:check
SET ENCRYPTED=0
if /i %ENCRYPTEDESDN%==install.esd (ren %ENCRYPTEDESD% %ENCRYPTEDESDN%.orig&set ENCRYPTEDESD=%ENCRYPTEDESD%.orig)
bin\wimlib-imagex.exe info "%ENCRYPTEDESD%" 4 1>nul 2>nul
IF %ERRORLEVEL% EQU 74 SET ENCRYPTED=1
IF %ERRORLEVEL% EQU 18 (
cls
echo.
echo =================================================================
echo ERROR: ESD original structure ^(4 images minimum^) is not met.
echo =================================================================
echo.
echo Press any key to exit.
pause >nul
goto :eof
)
IF %ERRORLEVEL% NEQ 0 (
cls
echo.
echo ============================================================
echo ERROR: ESD file is damaged, blocked or not found.
echo ============================================================
echo.
echo Press any key to exit.
pause >nul
goto :eof
)

:PRE_INFO
bin\imagex.exe /info "%ENCRYPTEDESD%">bin\infoall.txt 2>&1
find /i "Professional</EDITIONID>" bin\infoall.txt 1>nul && (set editionida=1) || (set editionida=0)
find /i "ProfessionalN</EDITIONID>" bin\infoall.txt 1>nul && (set editionidn=1) || (set editionidn=0)
find /i "CoreSingleLanguage</EDITIONID>" bin\infoall.txt 1>nul && (set editionids=1) || (set editionids=0)
find /i "CoreCountrySpecific</EDITIONID>" bin\infoall.txt 1>nul && (set editionidc=1) || (set editionidc=0)
bin\imagex.exe /info "%ENCRYPTEDESD%" 4 >bin\info.txt 2>&1
for /f "tokens=3 delims=<>" %%i in ('find /i "<BUILD>" bin\info.txt') do set build=%%i
for /f "tokens=3 delims=<>" %%i in ('find /i "<MAJOR>" bin\info.txt') do set ver1=%%i
for /f "tokens=3 delims=<>" %%i in ('find /i "<MINOR>" bin\info.txt') do set ver2=%%i
for /f "tokens=3 delims=<>" %%i in ('find /i "<DEFAULT>" bin\info.txt') do set langid=%%i
for /f "tokens=3 delims=<>" %%i in ('find /i "<EDITIONID>" bin\info.txt') do set editionid=%%i
for /f "tokens=3 delims=<>" %%i in ('find /i "<ARCH>" bin\info.txt') do (if %%i equ 0 (set arch=x86) else if %%i equ 9 (set arch=x64) else (set arch=arm64))
for /f "tokens=3 delims=: " %%i in ('findstr /i /b /c:"Image Count" bin\infoall.txt') do (if %%i geq 5 set MULTI=%%i)
if %build% LEQ 9600 GOTO :E_W81
find /i "<DISPLAYNAME>" bin\info.txt 1>nul && (
for /f "tokens=3 delims=<>" %%i in ('find /i "<DISPLAYNAME>" bin\info.txt') do set "_os=%%i"
) || (
for /f "tokens=3 delims=<>" %%i in ('find /i "<NAME>" bin\info.txt') do set "_os=%%i"
)
IF NOT %MULTI%==0 FOR /L %%g IN (4,1,%MULTI%) DO (
bin\imagex.exe info "!ENCRYPTEDESD!" %%g | find /i "<DISPLAYNAME>" 1>nul && (
for /f "tokens=3 delims=<>" %%i in ('bin\imagex.exe /info "!ENCRYPTEDESD!" %%g ^| find /i "<DISPLAYNAME>"') do set "_os%%g=%%i"
) || (
for /f "tokens=3 delims=<>" %%i in ('bin\imagex.exe /info "!ENCRYPTEDESD!" %%g ^| find /i "<NAME>"') do set "_os%%g=%%i"
)
)
del /f /q bin\info*.txt
IF NOT %MULTI%==0 (set /a images=%MULTI%-3) else (GOTO :MAINMENU)
IF NOT %MultiChoice%==1 GOTO :MAINMENU

:MULTIMENU
cls
echo ============================================================
echo                ESD file contains %images% editions:
echo ============================================================
FOR /L %%j IN (4,1,%MULTI%) DO (
echo. !_os%%j!
)
echo.
echo ============================================================
echo. Options:
echo. 1 - Continue including all editions
echo. 2 - Include one edition
if %MULTI% gtr 5 echo. 3 - Include consecutive range of editions
if %MULTI% gtr 5 echo. 4 - Include randomly selected editions
echo ============================================================
echo.
choice /c 12340 /n /m "Choose a menu option, or press 0 to quit: "
if errorlevel 5 GOTO :QUIT
if errorlevel 4 if %MULTI% gtr 5 GOTO :RANDOMMENU
if errorlevel 3 if %MULTI% gtr 5 GOTO :RANGEMENU
if errorlevel 2 GOTO :SINGLEMENU
if errorlevel 1 GOTO :MAINMENU
goto :MULTIMENU

:SINGLEMENU
cls
set _single=
echo ============================================================
FOR /L %%j IN (4,1,%MULTI%) DO (
call set /a osnum=%%j-3
echo. !osnum!. !_os%%j!
)
echo ============================================================
echo Enter edition number to include, or zero '0' to return
echo ============================================================
set /p _single= ^> Enter your option and press "Enter": 
if "%_single%"=="" goto :QUIT
if "%_single%"=="0" set _single=&goto :MULTIMENU
if %_single% GTR %images% echo.&echo %_single% is higher than available editions&echo.&PAUSE&goto :SINGLEMENU
set /a _single+=3&goto :MAINMENU

:RANGEMENU
cls
set _range=
set _start=
set _end=
echo ============================================================
FOR /L %%j IN (4,1,%MULTI%) DO (
call set /a osnum=%%j-3
echo. !osnum!. !_os%%j!
)
echo ============================================================
echo Enter consecutive range for editions to include: Start-End
echo examples: 2-4 or 1-3 or 3-9
echo Enter zero '0' to return
echo ============================================================
set /p _range= ^> Enter your option and press "Enter": 
if "%_range%"=="" goto :QUIT
if "%_range%"=="0" set _start=&goto :MULTIMENU
for /f "tokens=1,2 delims=-" %%i in ('echo %_range%') do set _start=%%i&set _end=%%j
if %_end% GTR %images% echo.&echo Range End is higher than available editions&echo.&PAUSE&goto :RANGEMENU
if %_start% GTR %_end% echo.&echo Range Start is higher than Range End&echo.&PAUSE&goto :RANGEMENU
if %_start% EQU %_end% echo.&echo Range Start and End are equal&echo.&PAUSE&goto :RANGEMENU
if %_start% GTR %images% echo.&echo Range Start is higher than available editions&echo.&PAUSE&goto :RANGEMENU
set /a _start+=3&set /a _end+=3&goto :MAINMENU

:RANDOMMENU
cls
set _count=
set _index=
echo ============================================================
FOR /L %%j IN (4,1,%MULTI%) DO (
call set /a osnum=%%j-3
echo. !osnum!. !_os%%j!
)
echo ============================================================
echo Enter editions numbers to include separated with spaces
echo examples: 1 3 4 or 5 1 or 4 2 9
echo Enter zero '0' to return
echo ============================================================
set /p _index= ^> Enter your option and press "Enter": 
if "%_index%"=="" goto :QUIT
if "%_index%"=="0" set _index=&goto :MULTIMENU
for %%i in (%_index%) do call :setindex %%i
if %_count%==1 echo.&echo Only one edition number is entered&echo.&PAUSE&goto :RANDOMMENU
for /L %%i in (1,1,%_count%) do (
if !_index%%i! GTR %images% echo.&echo !_index%%i! is higher than available editions&echo.&PAUSE&goto :RANDOMMENU
)
for /L %%i in (1,1,%_count%) do (
set /a _index%%i+=3
)
goto :MAINMENU

:setindex
set /a _count+=1
set _index%_count%=%1
goto :eof

:MAINMENU
cls
echo ============================================================
echo.       1 - Create ISO with Standard install.wim
echo.       2 - Create ISO with Compressed install.esd
echo.       3 - Create Standard install.wim
echo.       4 - Create Compressed install.esd
IF %ENCRYPTED%==1 (
echo.       5 - Decrypt ESD file only
echo ____________________________________________________________
echo Encrypted ESD Backup is %Backup%. Press 9 to toggle
) else (
echo.       5 - ESD file info
echo ____________________________________________________________
echo ESD is not encrypted.
)
echo ============================================================
echo.
choice /c 1234590 /n /m "Choose a menu option, or press 0 to quit: "
if errorlevel 7 GOTO :QUIT
if errorlevel 6 (if /i %Backup%==OFF (set Backup=ON) else (set Backup=OFF))&goto :MAINMENU
if errorlevel 5 (if %ENCRYPTED%==1 (GOTO :DDECRYPT) else (GOTO :INFO))
if errorlevel 4 (set WIMFILE=install.esd&goto :WIM)
if errorlevel 3 (set WIMFILE=install.wim&goto :WIM)
if errorlevel 2 (set WIMFILE=install.esd&goto :ISO)
if errorlevel 1 (set WIMFILE=install.wim&goto :ISO)
GOTO :MAINMENU

:ISO
cls
echo.
IF %ENCRYPTED%==1 CALL :DECRYPT
IF %PREPARED%==0 CALL :PREPARE
echo.
echo ============================================================
echo Creating Setup Media Layout...
echo ============================================================
IF EXIST ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
echo.
"%wimlib%" apply "%ENCRYPTEDESD%" 1 ISOFOLDER\ >nul 2>&1
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during apply.&echo.&echo Press any key to exit.&pause >nul&GOTO :QUIT)
del /f /q ISOFOLDER\MediaMeta.xml >nul 2>&1
rmdir /s /q ISOFOLDER\sources\uup\ >nul 2>&1
echo.
echo ============================================================
echo Creating boot.wim...
echo ============================================================
echo.
"%wimlib%" export "%ENCRYPTEDESD%" 2 ISOFOLDER\sources\boot.wim --compress=maximum
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&echo.&echo Press any key to exit.&pause >nul&GOTO :QUIT)
echo.
"%wimlib%" export "%ENCRYPTEDESD%" 3 ISOFOLDER\sources\boot.wim --boot
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&echo.&echo Press any key to exit.&pause >nul&GOTO :QUIT)
"%wimlib%" extract ISOFOLDER\sources\boot.wim 2 sources\dism.exe --dest-dir=.\bin\temp --no-acls >nul 2>&1
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (
"%wimlib%" update ISOFOLDER\sources\boot.wim 2 <bin\wim-update.txt 1>nul 2>nul
)
rmdir /s /q .\bin\temp >nul 2>&1
echo.
echo ============================================================
echo Creating %WIMFILE%...
echo ============================================================
echo.
IF %MULTI%==0 (set sourcetime=4) else (set sourcetime=%MULTI%)
for /f "tokens=5-10 delims=: " %%G in ('bin\wimlib-imagex.exe info "%ENCRYPTEDESD%" %sourcetime% ^| find /i "Last Modification Time"') do (set mmm=%%G&set "isotime=%%H/%%L,%%I:%%J:%%K")
call :setdate %mmm%
set source=4
if defined _single set source=%_single%
if defined _start set source=%_start%&set /a _start+=1
if defined _index set source=%_index1%
if /i %WIMFILE%==install.esd (
"%wimlib%" export "%ENCRYPTEDESD%" %source% ISOFOLDER\sources\%WIMFILE%
) else (
"%wimlib%" export "%ENCRYPTEDESD%" %source% ISOFOLDER\sources\%WIMFILE% --compress=maximum
)
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&PAUSE&GOTO :QUIT)
if defined _single (
for /f "tokens=3 delims=<>" %%i in ('bin\imagex.exe /info ISOFOLDER\sources\%WIMFILE% 1 ^| find /i "<EDITIONID>"') do set editionid=%%i
call :SINGLEINFO
1>nul 2>nul call :GUID
goto :ISOCREATE
)
if defined _start FOR /L %%j IN (%_start%,1,%_end%) DO (
echo.&"%wimlib%" export "%ENCRYPTEDESD%" %%j ISOFOLDER\sources\%WIMFILE%
)
if defined _index for /L %%j in (2,1,%_count%) do (
echo.&"%wimlib%" export "%ENCRYPTEDESD%" !_index%%j! ISOFOLDER\sources\%WIMFILE%
)
if not defined _start if not defined _index IF NOT %MULTI%==0 FOR /L %%j IN (5,1,%MULTI%) DO (
echo.&"%wimlib%" export "%ENCRYPTEDESD%" %%j ISOFOLDER\sources\%WIMFILE%
)
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&PAUSE&GOTO :QUIT)
IF %UnifyWinre%==1 CALL :WINRE
1>nul 2>nul call :GUID

:ISOCREATE
IF %SkipISO%==1 (
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
echo Creating ISO...
echo ============================================================
bin\cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -g -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (
  ren ISOFOLDER %DVDISO%
  echo.
  echo Errors were reported during ISO creation.
  echo.
  echo Press any key to exit.
  pause >nul
  GOTO :QUIT
)
rmdir /s /q ISOFOLDER\
echo.
echo Press any key to exit.
pause >nul
GOTO :QUIT

:WIM
cls
if %WIMFILE%==install.wim IF EXIST "%CD%\install.wim" (
echo.
echo ============================================================
echo An install.wim file is already present in the current folder
echo ============================================================
echo.
echo Press any key to exit.
pause >nul
GOTO :QUIT
)
echo.
IF %ENCRYPTED%==1 CALL :DECRYPT
IF %PREPARED%==0 CALL :PREPARE
echo.
echo ============================================================
echo Creating %WIMFILE% file...
echo ============================================================
echo.
set source=4
if defined _single set source=%_single%
if defined _start set source=%_start%&set /a _start+=1
if defined _index set source=%_index1%
if /i %WIMFILE%==install.esd (
"%wimlib%" export "%ENCRYPTEDESD%" %source% %WIMFILE%
) else (
"%wimlib%" export "%ENCRYPTEDESD%" %source% %WIMFILE% --compress=maximum
)
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&PAUSE&GOTO :QUIT)
if defined _single GOTO :WIMproceed
if defined _start FOR /L %%j IN (%_start%,1,%_end%) DO (
echo.&"%wimlib%" export "%ENCRYPTEDESD%" %%j %WIMFILE%
)
if defined _index for /L %%j in (2,1,%_count%) do (
echo.&"%wimlib%" export "%ENCRYPTEDESD%" !_index%%j! %WIMFILE%
)
if not defined _start if not defined _index IF NOT %MULTI%==0 FOR /L %%j IN (5,1,%MULTI%) DO (
echo.&"%wimlib%" export "%ENCRYPTEDESD%" %%j %WIMFILE%
)
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&PAUSE&GOTO :QUIT)
IF %UnifyWinre%==1 CALL :WINRE2

:WIMproceed
1>nul 2>nul call :GUID2
echo.
echo Done.
echo.
echo Press any key to exit.
pause >nul
GOTO :QUIT

:INFO
cls
IF %PREPARED%==0 CALL :PREPARE
cls
echo ============================================================
echo                     ESD Contents Info
echo ============================================================
echo     Arch: %arch%
echo Language: %langid%
echo  Version: %ver1%.%ver2%.%revision%
if defined branch echo   Branch: %branch%
IF %MULTI%==0 echo       OS: %_os%
IF NOT %MULTI%==0 (
echo     OS 1: %_os%
FOR /L %%j IN (5,1,%MULTI%) DO (
call set /a osnum=%%j-3
echo     OS !osnum!: !_os%%j!
)
)
echo.
echo Press any key to continue...
pause >nul
GOTO :MAINMENU

:PREPARE
echo.
echo ============================================================
echo Checking ESD Info...
echo ============================================================
SET PREPARED=1
IF %CheckWinre%==1 for /f "tokens=2 delims== " %%i in ('bin\wimlib-imagex.exe dir "%ENCRYPTEDESD%" 4 --path=Windows\System32\Recovery\winre.wim --detailed 2^>nul ^| findstr /b Hash') do call set "WinreHash=%%i"
IF NOT %MULTI%==0 FOR /L %%g IN (5,1,%MULTI%) DO (
IF !CheckWinre!==1 for /f "tokens=2 delims== " %%i in ('bin\wimlib-imagex.exe dir "!ENCRYPTEDESD!" %%g --path=Windows\System32\Recovery\winre.wim --detailed 2^>nul ^| findstr /b Hash') do if /i not "%%i"=="!WinreHash!" (call set UnifyWinre=1)
)
"%wimlib%" extract "%ENCRYPTEDESD%" 1 sources\ei.cfg --dest-dir=.\bin\temp --no-acls >nul 2>&1
type .\bin\temp\ei.cfg 2>nul | find /i "Volume" 1>nul && set VOL=1

:setlabel
"%wimlib%" extract "%ENCRYPTEDESD%" 3 \Windows\System32\ntoskrnl.exe --dest-dir=.\bin\temp --no-acls >nul 2>&1
bin\7z.exe l .\bin\temp\ntoskrnl.exe >.\bin\temp\version.txt 2>&1
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\temp\version.txt" 2^>nul') do (set version=%%i.%%j&set branch=%%k&set datetime=%%l)
"%wimlib%" extract "%ENCRYPTEDESD%" 4 Windows\WinSxS\Manifests\amd64_microsoft-windows-coreos-revision* --dest-dir=.\bin\temp --no-acls >nul 2>&1 || "%wimlib%" extract "%ENCRYPTEDESD%" 4 Windows\WinSxS\Manifests\x86_microsoft-windows-coreos-revision* --dest-dir=.\bin\temp --no-acls >nul 2>&1 || "%wimlib%" extract "%ENCRYPTEDESD%" 4 Windows\WinSxS\Manifests\arm64_microsoft-windows-coreos-revision* --dest-dir=.\bin\temp --no-acls >nul 2>&1
for /f "tokens=6,7 delims=_." %%i in ('dir /b /od .\bin\temp\*.manifest') do set revision=%%i.%%j
if not "%version%"=="%revision%" (
set version=%revision%
for /f "tokens=5,6,7,8,9,10 delims=: " %%G in ('bin\wimlib-imagex.exe info "%ENCRYPTEDESD%" 4 ^| find /i "Last Modification Time"') do (set mmm=%%G&set yyy=%%L&set ddd=%%H-%%I%%J)
call :setmmm !mmm!
)
set _label2=
if /i "%branch%"=="WinBuild" (
"%wimlib%" extract "%ENCRYPTEDESD%" 4 \Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls >nul
for /f "tokens=3 delims==:" %%a in ('"bin\offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion" getvalue BuildLabEx" 2^>nul') do if not errorlevel 1 (for /f "tokens=1-5 delims=." %%i in ('echo %%~a') do set _label2=%%i.%%j.%%m.%%l_CLIENT&set branch=%%l)
)
if defined _label2 (set _label=%_label2%) else (set _label=%version%.%datetime%.%branch%_CLIENT)
if %revision%==10240.16487 (set _label=10240.16393.150909-1450.th1_refresh_CLIENT&set branch=th1_refresh)
if %revision%==10586.104 (set _label=10586.0.160212-2000.th2_refresh_CLIENT&set branch=th2_refresh)
if %revision%==10586.164 (set _label=10586.0.160426-1409.th2_refresh_CLIENT&set branch=th2_refresh)
if %revision%==14393.447 (set _label=14393.0.161119-1705.rs1_refresh_CLIENT&set branch=rs1_refresh)
if %revision%==15063.413 (set _label=15063.0.170607-1447.rs2_release_svc_refresh_CLIENT&set branch=rs2_release_svc_refresh)
if %revision%==15063.483 (set _label=15063.0.170710-1358.rs2_release_svc_refresh_CLIENT&set branch=rs2_release_svc_refresh)
if %revision%==16299.64  (set _label=16299.15.171109-1522.rs3_release_svc_refresh_CLIENT&set branch=rs3_release_svc_refresh)
if %revision%==16299.125 (set _label=16299.125.171213-1220.rs3_release_svc_refresh_CLIENT&set branch=rs3_release_svc_refresh)
if %revision%==17134.112 (set _label=17134.112.180619-1212.rs4_release_svc_refresh_CLIENT&set branch=rs4_release_svc_refresh)
if %revision%==17763.107 (set _label=17763.107.181029-1455.rs5_release_svc_refresh_CLIENT&set branch=rs5_release_svc_refresh)
if %revision%==17763.253 (set _label=17763.253.190108-0006.rs5_release_svc_refresh_CLIENT&set branch=rs5_release_svc_refresh)
rmdir /s /q .\bin\temp >nul 2>&1

for %%b in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _label=!_label:%%b=%%b!
set branch=!branch:%%b=%%b!
set langid=!langid:%%b=%%b!
set editionid=!editionid:%%b=%%b!
)
if not "%1"=="" exit /b

if /i %arch%==x86 set archl=X86
if /i %arch%==x64 set archl=X64
if /i %arch%==arm64 set archl=A64

IF %MULTI% GEQ 5 (
if %editionidn%==1 set DVDLABEL=CCSNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%COMBINEDN_OEMRET_%archl%FRE_%langid%
if %editionida%==1 set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%COMBINED_OEMRET_%archl%FRE_%langid%
if %editionids%==1 set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%COMBINEDSL_OEMRET_%archl%FRE_%langid%
if %editionidc%==1 set DVDLABEL=CCCHA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%COMBINEDCHINA_OEMRET_%archl%FRE_%langid%
if %build% GEQ 16299 (IF %VOL%==1 (set DVDLABEL=CCSA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%BUSINESS_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CONSUMER_OEMRET_%archl%FRE_%langid%))
if defined branch exit /b
)

:SINGLEINFO
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
if /i %editionid%==PPIPro set DVDLABEL=CPPIA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PPIPRO_OEM_%archl%FRE_%langid%
if /i %editionid%==Cloud set DVDLABEL=CWCA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CLOUD_OEM_%archl%FRE_%langid%
if /i %editionid%==CloudN set DVDLABEL=CWCNNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%CLOUDN_OEM_%archl%FRE_%langid%
if /i %editionid%==EnterpriseG set DVDLABEL=CEGA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISEG_VOL_%archl%FRE_%langid%
if /i %editionid%==EnterpriseGN set DVDLABEL=CEGNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISEGN_VOL_%archl%FRE_%langid%
if /i %editionid%==EnterpriseS set DVDLABEL=CES_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISES_VOL_%archl%FRE_%langid%
if /i %editionid%==EnterpriseSN set DVDLABEL=CESNN_%archl%FREV_%langid%_DV5&set DVDISO=%_label%ENTERPRISESN_VOL_%archl%FRE_%langid%
if /i %editionid%==ProfessionalEducation (IF %VOL%==1 (set DVDLABEL=CPREA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%PROEDUCATION_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPREA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROEDUCATION_OEMRET_%archl%FRE_%langid%))
if /i %editionid%==ProfessionalEducationN (IF %VOL%==1 (set DVDLABEL=CPRENA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%PROEDUCATIONN_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRENA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROEDUCATIONN_OEMRET_%archl%FRE_%langid%))
if /i %editionid%==ProfessionalWorkstation (IF %VOL%==1 (set DVDLABEL=CPRWA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%PROWORKSTATION_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRWA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROWORKSTATION_OEMRET_%archl%FRE_%langid%))
if /i %editionid%==ProfessionalWorkstationN (IF %VOL%==1 (set DVDLABEL=CPRWNA_%archl%FREV_%langid%_DV5&set DVDISO=%_label%PROWORKSTATIONN_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRWNA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROWORKSTATIONN_OEMRET_%archl%FRE_%langid%))
if /i %editionid%==ProfessionalSingleLanguage set DVDLABEL=CPRSLA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROSINGLELANGUAGE_OEM_%archl%FRE_%langid%
if /i %editionid%==ProfessionalCountrySpecific set DVDLABEL=CPRCHA_%archl%FRE_%langid%_DV5&set DVDISO=%_label%PROCHINA_OEM_%archl%FRE_%langid%
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

:GUID
(bin\busybox.exe printf "b\n" & bin\busybox.exe dd if="%ENCRYPTEDESD%" bs=1 skip=24 count=14) | bin\busybox.exe dd of=ISOFOLDER\sources\boot.wim bs=1 seek=24 conv=notrunc
(bin\busybox.exe printf "i\n" & bin\busybox.exe dd if="%ENCRYPTEDESD%" bs=1 skip=24 count=14) | bin\busybox.exe dd of=ISOFOLDER\sources\%WIMFILE% bs=1 seek=24 conv=notrunc
exit /b

:GUID2
(bin\busybox.exe printf "i\n" & bin\busybox.exe dd if="%ENCRYPTEDESD%" bs=1 skip=24 count=14) | bin\busybox.exe dd of=%WIMFILE% bs=1 seek=24 conv=notrunc
exit /b

:WINRE
echo.
echo ============================================================
echo Unifying winre.wim...
echo ============================================================
echo.
for /f "tokens=3 delims=<>" %%i in ('bin\imagex.exe /info "%ENCRYPTEDESD%" 4 ^| findstr /i HIGHPART') do set "installhigh=%%i"
for /f "tokens=3 delims=<>" %%i in ('bin\imagex.exe /info "%ENCRYPTEDESD%" 4 ^| findstr /i LOWPART') do set "installlow=%%i"
"%wimlib%" extract ISOFOLDER\sources\%WIMFILE% 1 Windows\System32\Recovery\winre.wim --dest-dir=.\bin\temp --no-acls
attrib -S -H -I .\bin\temp\winre.wim
echo.
echo Updating winre.wim in different indexes...
FOR /L %%j IN (5,1,%MULTI%) DO (
call set /a inum=%%j-3
for /f "skip=1 delims=" %%i in ('bin\wimlib-imagex.exe dir ISOFOLDER\sources\%WIMFILE% !inum! --path=Windows\WinSxS\ManifestCache 2^>nul') do "%wimlib%" update ISOFOLDER\sources\%WIMFILE% !inum! --command="delete '%%i'" 1>nul 2>nul
"%wimlib%" update ISOFOLDER\sources\%WIMFILE% !inum! --command="add 'bin\temp\winre.wim' '\windows\system32\recovery\winre.wim'" 1>nul 2>nul
"%wimlib%" info ISOFOLDER\sources\%WIMFILE% !inum! --image-property LASTMODIFICATIONTIME/HIGHPART=%installhigh% --image-property LASTMODIFICATIONTIME/LOWPART=%installlow% 1>nul 2>nul
)
for /f "skip=1 delims=" %%i in ('bin\wimlib-imagex.exe dir ISOFOLDER\sources\%WIMFILE% 1 --path=Windows\WinSxS\ManifestCache 2^>nul') do "%wimlib%" update ISOFOLDER\sources\%WIMFILE% 1 --command="delete '%%i'" 1>nul 2>nul
"%wimlib%" info ISOFOLDER\sources\%WIMFILE% 1 --image-property LASTMODIFICATIONTIME/HIGHPART=%installhigh% --image-property LASTMODIFICATIONTIME/LOWPART=%installlow% 1>nul 2>nul
echo.
"%wimlib%" optimize ISOFOLDER\sources\%WIMFILE%
rmdir /s /q .\bin\temp >nul 2>&1
exit /b

:WINRE2
echo.
echo ============================================================
echo Unifying winre.wim...
echo ============================================================
echo.
for /f "tokens=3 delims=<>" %%i in ('bin\imagex.exe /info "%ENCRYPTEDESD%" 4 ^| findstr /i HIGHPART') do set "installhigh=%%i"
for /f "tokens=3 delims=<>" %%i in ('bin\imagex.exe /info "%ENCRYPTEDESD%" 4 ^| findstr /i LOWPART') do set "installlow=%%i"
"%wimlib%" extract %WIMFILE% 1 Windows\System32\Recovery\winre.wim --dest-dir=.\bin\temp --no-acls
attrib -S -H -I .\bin\temp\winre.wim
echo.
echo Updating winre.wim in different indexes...
FOR /L %%j IN (5,1,%MULTI%) DO (
call set /a inum=%%j-3
for /f "skip=1 delims=" %%i in ('bin\wimlib-imagex.exe dir %WIMFILE% !inum! --path=Windows\WinSxS\ManifestCache 2^>nul') do "%wimlib%" update %WIMFILE% !inum! --command="delete '%%i'" 1>nul 2>nul
"%wimlib%" update %WIMFILE% !inum! --command="add 'bin\temp\winre.wim' '\windows\system32\recovery\winre.wim'" 1>nul 2>nul
"%wimlib%" info %WIMFILE% !inum! --image-property LASTMODIFICATIONTIME/HIGHPART=%installhigh% --image-property LASTMODIFICATIONTIME/LOWPART=%installlow% 1>nul 2>nul
)
for /f "skip=1 delims=" %%i in ('bin\wimlib-imagex.exe dir %WIMFILE% 1 --path=Windows\WinSxS\ManifestCache 2^>nul') do "%wimlib%" update %WIMFILE% 1 --command="delete '%%i'" 1>nul 2>nul
"%wimlib%" info %WIMFILE% 1 --image-property LASTMODIFICATIONTIME/HIGHPART=%installhigh% --image-property LASTMODIFICATIONTIME/LOWPART=%installlow% 1>nul 2>nul
echo.
"%wimlib%" optimize %WIMFILE%
rmdir /s /q .\bin\temp >nul 2>&1
exit /b

:DDECRYPT
cls
echo.
CALL :DECRYPT
ren "%ENCRYPTEDESD%" Decrypted-%ENCRYPTEDESDN%
echo.
echo Press any key to exit.
pause >nul
GOTO :QUIT

:DECRYPT
if /i %Backup%==ON (
echo ============================================================
echo Backing up encrypted esd file...
echo ============================================================
copy /y "%ENCRYPTEDESD%" "%ENCRYPTEDESD%.bak" >nul
)
echo.
echo ============================================================
echo Running Decryption program...
echo ============================================================
echo.
for /f "tokens=3 delims=: " %%i in ('find /v /n /c "" bin\key.cmd') do set newkeys=%%i
call bin\key.cmd
IF NOT %newkeys%==0 FOR /L %%c IN (1,1,%newkeys%) DO (
bin\esddecrypt.exe "%ENCRYPTEDESD%" !newkey%%c! 2>nul&& (echo Done&exit /b)
)
bin\esddecrypt.exe "%ENCRYPTEDESD%" >nul && (echo Done&exit /b)
echo.
echo Errors were reported during ESD decryption.
echo.
echo Press any key to exit.
pause >nul
GOTO :QUIT

:E_W81
cls
echo.
echo ============================================================
echo ERROR: The script supports Windows 10 ESDs only.
echo you may use older version 8 to convert Windows 8.1 ESDs.
echo ============================================================
echo.
echo Press any key to exit.
pause >nul
goto :QUIT

rem ##################################################################

:dCheck
echo.
echo ============================================================
echo Please wait...
echo ============================================================
SET combine=0
SET custom=0
SET count=0
FOR /L %%j IN (1,1,2) DO (
SET ESDmulti%%j=0
SET ESDenc%%j=0
SET ESDvol%%j=0
SET ESDarch%%j=0
SET ESDver%%j=0
SET ESDlang%%j=0
)
for /f "delims=" %%i in ('dir /b /a:-d *.esd') do call :dCount %%i
CALL :dInfo 1
CALL :dInfo 2
if /i %ESDarch1% equ %ESDarch2% goto :prompt2
if /i %ESDlang1% neq %ESDlang2% goto :prompt2
if /i %ESDver1% neq %ESDver2% goto :prompt2
bin\wimlib-imagex.exe info "%ESDfile1%" 4 >nul 2>&1
IF %ERRORLEVEL% EQU 74 SET ENCRYPTED=1
bin\wimlib-imagex.exe info "%ESDfile2%" 4 >nul 2>&1
IF %ERRORLEVEL% EQU 74 SET ENCRYPTED=1

:DUALMENU
cls
echo ============================================================================
echo Detected 2 similar ESD files: ^(x64/x86^) / Build: %ESDver1% / Lang: %ESDlang1%
echo create a multi-architecture ISO for both?
echo ============================================================================
echo.
echo 0 - No, continue for prompt to process one file only
echo.
echo 1 - ISO with 2 separate install.esd              ^(same as MediaCreationTool^)
echo 2 - ISO with 2 separate install.wim              ^(similar to 1, bigger size^)
echo 3 - ISO with 1 combined install.wim                             ^(Custom AIO^)
IF %ENCRYPTED%==1 (
echo ____________________________________________________________________________
echo Encrypted ESD Backup is %Backup%. Press 9 to toggle
)
echo ============================================================================
echo.
choice /c 12309 /n /m "Choose a menu option: "
if errorlevel 5 (if /i %Backup%==OFF (set Backup=ON) else (set Backup=OFF))&goto :DUALMENU
if errorlevel 4 goto :prompt2
if errorlevel 3 (set WIMFILE=install.wim&set combine=1&set custom=1&goto :Dual)
if errorlevel 2 (set WIMFILE=install.wim&goto :Dual)
if errorlevel 1 (set WIMFILE=install.esd&goto :Dual)
GOTO :DUALMENU

:Dual
cls
IF EXIST ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
CALL :dISO 1
CALL :dISO 2
set archl=X86-X64
if /i "%DVDLABEL1%" equ "%DVDLABEL2%" (
set "DVDLABEL=%DVDLABEL1%_%archl%FRE_%langid%_DV9"
set "DVDISO=%_label%%DVDISO1%_%archl%FRE_%langid%"
) else (
set "DVDLABEL=CCSA_%archl%FRE_%langid%_DV9"
set "DVDISO=%_label%%DVDISO1%_%ESDarch1%FRE-%DVDISO2%_%ESDarch2%FRE_%langid%"
)
if %combine%==0 goto :BCD
echo.
echo ============================================================
echo Unifying install.wim...
echo ============================================================
echo.
for /f "tokens=3 delims=: " %%i in ('bin\wimlib-imagex.exe info ISOFOLDER\x86\sources\install.wim ^| findstr /c:"Image Count"') do set imagesi=%%i
for /f "tokens=3 delims=: " %%i in ('bin\wimlib-imagex.exe info ISOFOLDER\x64\sources\install.wim ^| findstr /c:"Image Count"') do set imagesx=%%i
for /f "tokens=1* delims=: " %%i in ('bin\wimlib-imagex.exe info ISOFOLDER\x86\sources\install.wim 1 ^| findstr /b "Name"') do set "_osi=%%j x86"
for /f "tokens=1* delims=: " %%i in ('bin\wimlib-imagex.exe info ISOFOLDER\x64\sources\install.wim 1 ^| findstr /b "Name"') do set "_osx=%%j x64"
IF NOT %imagesi%==1 FOR /L %%g IN (2,1,%imagesi%) DO (
for /f "tokens=1* delims=: " %%i in ('bin\wimlib-imagex.exe info ISOFOLDER\x86\sources\install.wim %%g ^| findstr /b "Name"') do set "_osi%%g=%%j x86"
)
IF NOT %imagesx%==1 FOR /L %%g IN (2,1,%imagesx%) DO (
for /f "tokens=1* delims=: " %%i in ('bin\wimlib-imagex.exe info ISOFOLDER\x64\sources\install.wim %%g ^| findstr /b "Name"') do set "_osx%%g=%%j x64"
)
"%wimlib%" info ISOFOLDER\x86\sources\install.wim 1 "%_osi%" "%_osi%" --image-property DISPLAYNAME="%_osi%" --image-property DISPLAYDESCRIPTION="%_osi%" 1>nul 2>nul
IF NOT %imagesi%==1 FOR /L %%g IN (2,1,%imagesi%) DO (
"%wimlib%" info ISOFOLDER\x86\sources\install.wim %%g "!_osi%%g!" "!_osi%%g!" --image-property DISPLAYNAME="!_osi%%g!" --image-property DISPLAYDESCRIPTION="!_osi%%g!" 1>nul 2>nul
)
"%wimlib%" info ISOFOLDER\x64\sources\install.wim 1 "%_osx%" "%_osx%" --image-property DISPLAYNAME="%_osx%" --image-property DISPLAYDESCRIPTION="%_osx%" 1>nul 2>nul
"%wimlib%" export ISOFOLDER\x64\sources\install.wim 1 ISOFOLDER\x86\sources\install.wim
IF NOT %imagesx%==1 FOR /L %%g IN (2,1,%imagesx%) DO (
"%wimlib%" info ISOFOLDER\x64\sources\install.wim %%g "!_osx%%g!" "!_osx%%g!" --image-property DISPLAYNAME="!_osx%%g!" --image-property DISPLAYDESCRIPTION="!_osx%%g!" 1>nul 2>nul
"%wimlib%" export ISOFOLDER\x64\sources\install.wim %%g ISOFOLDER\x86\sources\install.wim
)

:BCD
echo.
echo ============================================================
echo Preparing boot configuration settings...
echo ============================================================
echo.
xcopy ISOFOLDER\x64\boot\* ISOFOLDER\boot\ /cheriky >nul 2>&1
xcopy ISOFOLDER\x64\efi\* ISOFOLDER\efi\ /cheriky >nul 2>&1
copy /y ISOFOLDER\x64\bootmgr* ISOFOLDER\ >nul 2>&1
copy /y ISOFOLDER\x86\boot\bootsect.exe ISOFOLDER\boot\ >nul 2>&1
set "bcde=bin\bcdedit.exe"
set "BCDBIOS=ISOFOLDER\boot\bcd"
set "BCDUEFI=ISOFOLDER\efi\microsoft\boot\bcd"
if %custom%==0 (
copy /y ISOFOLDER\x86\setup.exe ISOFOLDER\ >nul 2>&1
set "entry64=[boot]\x64\sources\boot.wim,%ramdiskoptions%"
set "entry86=[boot]\x86\sources\boot.wim,%ramdiskoptions%"
(echo [AutoRun.Amd64]
echo open=x64\setup.exe
echo icon=x64\setup.exe,0
echo.
echo [AutoRun]
echo open=x86\setup.exe
echo icon=x86\setup.exe,0
echo.)>ISOFOLDER\autorun.inf
) else (
set "entry64=[boot]\sources\bootx64.wim,%ramdiskoptions%"
set "entry86=[boot]\sources\bootx86.wim,%ramdiskoptions%"
(echo [AutoRun.Amd64]
echo icon=sources\setupx64.exe,0
echo.
echo [AutoRun]
echo icon=sources\setupx86.exe,0
echo.)>ISOFOLDER\autorun.inf
)
for /f "tokens=5,6,7,8,9,10 delims=: " %%G in ('bin\wimlib-imagex.exe info ISOFOLDER\x64\sources\boot.wim 2 ^| find /i "Last Modification Time"') do (set mmm=%%G&set "isotime=%%H/%%L,%%I:%%J:%%K")
call :setdate %mmm%
%bcde% /store %BCDBIOS% /set {default} description "Windows 10 Setup (64-bit) - BIOS" >nul 2>&1
%bcde% /store %BCDBIOS% /set {default} device ramdisk=%entry64% >nul 2>&1
%bcde% /store %BCDBIOS% /set {default} osdevice ramdisk=%entry64% >nul 2>&1
%bcde% /store %BCDBIOS% /set {default} bootmenupolicy Legacy >nul 2>&1
for /f "tokens=2 delims={}" %%A in ('%bcde% /store %BCDBIOS% /copy {default} /d "Windows 10 Setup (32-bit) - BIOS"') do set "guid={%%A}"
%bcde% /store %BCDBIOS% /set %guid% device ramdisk=%entry86% >nul 2>&1
%bcde% /store %BCDBIOS% /set %guid% osdevice ramdisk=%entry86% >nul 2>&1
%bcde% /store %BCDBIOS% /timeout 30 >nul 2>&1
attrib -s -h -a "%BCDBIOS%.LOG*" >nul 2>&1
del /f /q "%BCDBIOS%.LOG*" >nul 2>&1
%bcde% /store %BCDUEFI% /set {default} description "Windows 10 Setup (64-bit) - UEFI" >nul 2>&1
%bcde% /store %BCDUEFI% /set {default} device ramdisk=%entry64% >nul 2>&1
%bcde% /store %BCDUEFI% /set {default} osdevice ramdisk=%entry64% >nul 2>&1
%bcde% /store %BCDUEFI% /set {default} isolatedcontext Yes >nul 2>&1
attrib -s -h -a "%BCDUEFI%.LOG*" >nul 2>&1
del /f /q "%BCDUEFI%.LOG*" >nul 2>&1
if %custom%==0 goto :ISOCREATE
echo.
echo ============================================================
echo Preparing Custom AIO settings...
echo ============================================================
echo.
copy /y ISOFOLDER\x86\efi\boot\bootia32.efi ISOFOLDER\efi\boot\ >nul 2>&1
copy /y ISOFOLDER\x86\efi\microsoft\boot\memtest.efi ISOFOLDER\efi\microsoft\boot\memtestx86.efi >nul 2>&1
rename ISOFOLDER\efi\microsoft\boot\memtest.efi memtestx64.efi
mkdir ISOFOLDER\sources
move /y ISOFOLDER\x64\sources\boot.wim ISOFOLDER\sources\bootx64.wim >nul 2>&1
move /y ISOFOLDER\x86\sources\boot.wim ISOFOLDER\sources\bootx86.wim >nul 2>&1
move /y ISOFOLDER\x86\sources\install.wim ISOFOLDER\sources\install.wim >nul 2>&1
move /y ISOFOLDER\x86\sources\lang.ini ISOFOLDER\sources\lang.ini >nul 2>&1
rmdir /s /q ISOFOLDER\x64 >nul 2>&1
rmdir /s /q ISOFOLDER\x86 >nul 2>&1
%bcde% /store %BCDUEFI% /set {default} bootmenupolicy Legacy >nul 2>&1
for /f "tokens=2 delims={}" %%A in ('%bcde% /store %BCDUEFI% /copy {default} /d "Windows 10 Setup (32-bit) - UEFI"') do set "guid={%%A}"
%bcde% /store %BCDUEFI% /set %guid% device ramdisk=%entry86% >nul 2>&1
%bcde% /store %BCDUEFI% /set %guid% osdevice ramdisk=%entry86% >nul 2>&1
%bcde% /store %BCDUEFI% /timeout 30 >nul 2>&1
%bcde% /store %BCDUEFI% /set {memdiag} description "Windows Memory Diagnostic (64-bit)" >nul 2>&1
%bcde% /store %BCDUEFI% /set {memdiag} path \efi\microsoft\boot\memtestx64.efi >nul 2>&1
for /f "tokens=2 delims={}" %%A in ('%bcde% /store %BCDUEFI% /copy {memdiag} /d "Windows Memory Diagnostic (32-bit)"') do set "guid={%%A}"
%bcde% /store %BCDUEFI% /set %guid% path \efi\microsoft\boot\memtestx86.efi >nul 2>&1
%bcde% /store %BCDUEFI% /toolsdisplayorder %guid% /addlast >nul 2>&1
attrib -s -h -a "%BCDUEFI%.LOG*" >nul 2>&1
del /f /q "%BCDUEFI%.LOG*" >nul 2>&1
call :dSETUP x64
call :dSETUP x86
bin\7z.exe x ISOFOLDER\efi\microsoft\boot\efisys.bin -o.\bin\temp\ >nul 2>&1
copy /y ISOFOLDER\efi\boot\bootia32.efi bin\temp\EFI\Boot\BOOTIA32.EFI >nul 2>&1
bin\bfi.exe -t=288 -l=EFISECTOR -f=bin\efisys.ima bin\temp >nul 2>&1
move /y bin\efisys.ima ISOFOLDER\efi\microsoft\boot\efisys.bin >nul 2>&1
del /f /q ISOFOLDER\efi\microsoft\boot\*noprompt.* >nul 2>&1
rmdir /s /q .\bin\temp >nul 2>&1
goto :ISOCREATE

:dSETUP
(echo [LaunchApps]
echo ^%%SystemRoot^%%\system32\wpeinit.exe
echo ^%%SystemDrive^%%\sources\setup%1.exe)>bin\winpeshl.ini
for /f %%i in ('bin\wimlib-imagex.exe dir ISOFOLDER\sources\boot%1.wim 2 --path=\sources ^| find /i "setup.exe.mui"') do "%wimlib%" update ISOFOLDER\sources\boot%1.wim 2 --command="rename '%%i' '%%~pisetup%1.exe.mui'" 1>nul 2>nul
"%wimlib%" update ISOFOLDER\sources\boot%1.wim 2 --command="rename 'sources\setup.exe' 'sources\setup%1.exe'" >nul 2>&1
"%wimlib%" update ISOFOLDER\sources\boot%1.wim 2 --command="add 'bin\winpeshl.ini' '\Windows\system32\winpeshl.ini'" >nul 2>&1
"%wimlib%" extract ISOFOLDER\sources\boot%1.wim 2 sources\setup%1.exe --dest-dir=.\ISOFOLDER\sources --no-acls >nul 2>&1
del /f /q bin\winpeshl.ini >nul 2>&1
exit /b

:dISO
echo.
SET ENCRYPTEDESD=!ESDfile%1!
IF !ESDenc%1!==1 CALL :DECRYPT
CALL :dPREPARE %1
SET UnifyWinre=0
SET WinreHash=
IF %CheckWinre%==1 for /f "tokens=2 delims== " %%i in ('bin\wimlib-imagex.exe dir "%ENCRYPTEDESD%" 4 --path=Windows\System32\Recovery\winre.wim --detailed 2^>nul ^| findstr /b Hash') do call set "WinreHash=%%i"
echo.
echo ============================================================
echo Creating Setup Media Layout ^(!ESDarch%1!^)...
echo ============================================================
echo.
"%wimlib%" apply "%ENCRYPTEDESD%" 1 ISOFOLDER\!ESDarch%1!\ >nul 2>&1
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during apply.&PAUSE&GOTO :QUIT)
del /f /q ISOFOLDER\!ESDarch%1!\MediaMeta.xml >nul 2>&1
rmdir /s /q ISOFOLDER\!ESDarch%1!\sources\uup\ >nul 2>&1
echo.
echo ============================================================
echo Creating boot.wim ^(!ESDarch%1!^)...
echo ============================================================
echo.
"%wimlib%" export "%ENCRYPTEDESD%" 2 ISOFOLDER\!ESDarch%1!\sources\boot.wim --compress=maximum
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&PAUSE&GOTO :QUIT)
echo.
"%wimlib%" export "%ENCRYPTEDESD%" 3 ISOFOLDER\!ESDarch%1!\sources\boot.wim --boot
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&PAUSE&GOTO :QUIT)
echo.
echo ============================================================
echo Creating %WIMFILE% ^(!ESDarch%1!^)...
echo ============================================================
echo.
if /i %WIMFILE%==install.esd (
"%wimlib%" export "%ENCRYPTEDESD%" 4 ISOFOLDER\!ESDarch%1!\sources\%WIMFILE%
) else (
"%wimlib%" export "%ENCRYPTEDESD%" 4 ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% --compress=maximum
)
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&PAUSE&GOTO :QUIT)
IF NOT !ESDmulti%1!==0 FOR /L %%j IN (5,1,!ESDmulti%1!) DO (
echo.
IF !CheckWinre!==1 for /f "tokens=2 delims== " %%i in ('bin\wimlib-imagex.exe dir "!ENCRYPTEDESD!" %%j --path=Windows\System32\Recovery\winre.wim --detailed 2^>nul ^| findstr /b Hash') do if /i not "%%i"=="!WinreHash!" (call set UnifyWinre=1)
"%wimlib%" export "%ENCRYPTEDESD%" %%j ISOFOLDER\!ESDarch%1!\sources\%WIMFILE%
)
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (echo.&echo Errors were reported during export.&PAUSE&GOTO :QUIT)
IF %UnifyWinre%==1 (
echo.
echo ============================================================
echo Unifying winre.wim ^(!ESDarch%1!^)...
echo ============================================================
echo.
"%wimlib%" extract ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% 1 Windows\System32\Recovery\winre.wim --dest-dir=.\bin\temp --no-acls
attrib -S -H -I .\bin\temp\winre.wim
echo.
echo Updating winre.wim in different indexes...
FOR /L %%j IN (5,1,!ESDmulti%1!) DO (
call set /a inum=%%j-3
for /f "skip=1 delims=" %%i in ('bin\wimlib-imagex.exe dir ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% !inum! --path=Windows\WinSxS\ManifestCache') do "%wimlib%" update ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% !inum! --command="delete '%%i'" 1>nul 2>nul
"%wimlib%" update ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% !inum! --command="add 'bin\temp\winre.wim' '\windows\system32\recovery\winre.wim'" 1>nul 2>nul
)
for /f "skip=1 delims=" %%i in ('bin\wimlib-imagex.exe dir ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% 1 --path=Windows\WinSxS\ManifestCache') do "%wimlib%" update ISOFOLDER\!ESDarch%1!\sources\%WIMFILE% 1 --command="delete '%%i'" 1>nul 2>nul
echo.
"%wimlib%" optimize ISOFOLDER\!ESDarch%1!\sources\%WIMFILE%
rmdir /s /q .\bin\temp >nul 2>&1
)
if /i !ESDarch%1!==x86 (set ESDarch%1=X86) else (set ESDarch%1=X64)
exit /b

:dCount
set /a count+=1
set "ESDfile%count%=%1"
exit /b

:dInfo
bin\imagex.exe /info "!ESDfile%1!">bin\infoall.txt 2>&1
find /i "Professional</EDITIONID>" bin\infoall.txt 1>nul && (set ESDeditiona%1=1) || (set ESDeditiona%1=0)
find /i "ProfessionalN</EDITIONID>" bin\infoall.txt 1>nul && (set ESDeditionn%1=1) || (set ESDeditionn%1=0)
find /i "CoreSingleLanguage</EDITIONID>" bin\infoall.txt 1>nul && (set ESDeditions%1=1) || (set ESDeditions%1=0)
find /i "CoreCountrySpecific</EDITIONID>" bin\infoall.txt 1>nul && (set ESDeditionc%1=1) || (set ESDeditionc%1=0)
bin\imagex.exe /info "!ESDfile%1!" 4 >bin\info.txt 2>&1
for /f "tokens=3 delims=<>" %%i in ('find /i "<BUILD>" bin\info.txt') do set ESDver%1=%%i
for /f "tokens=3 delims=<>" %%i in ('find /i "<EDITIONID>" bin\info.txt') do set ESDedition%1=%%i
for /f "tokens=3 delims=<>" %%i in ('find /i "<DEFAULT>" bin\info.txt') do set ESDlang%1=%%i
for /f "tokens=3 delims=<>" %%i in ('find /i "<ARCH>" bin\info.txt') do (IF %%i EQU 0 (SET ESDarch%1=x86) ELSE (SET ESDarch%1=x64))
for /f "tokens=3 delims=: " %%i in ('findstr /i /b /c:"Image Count" bin\infoall.txt') do (IF %%i GEQ 5 SET ESDmulti%1=%%i)
bin\wimlib-imagex.exe info "!ESDfile%1!" 4 >nul 2>&1
IF %ERRORLEVEL% EQU 74 SET ESDenc%1=1
del /f /q bin\info*.txt
exit /b

:dPREPARE
echo.
echo ============================================================
echo Checking ESD Info ^(!ESDarch%1!^)...
echo ============================================================
echo.
"%wimlib%" extract "%ENCRYPTEDESD%" 1 sources\ei.cfg --dest-dir=.\bin --no-acls >nul 2>&1
type .\bin\ei.cfg 2>nul | find /i "Volume" 1>nul && set ESDvol%1=1
del bin\ei.cfg >nul 2>&1
if /i !ESDedition%1!==Core set DVDLABEL%1=CCRA&set DVDISO%1=CORE_OEMRET
if /i !ESDedition%1!==CoreN set DVDLABEL%1=CCRNA&set DVDISO%1=COREN_OEMRET
if /i !ESDedition%1!==CoreSingleLanguage set DVDLABEL%1=CSLA&set DVDISO%1=SINGLELANGUAGE_OEM
if /i !ESDedition%1!==CoreCountrySpecific set DVDLABEL%1=CCHA&set DVDISO%1=CHINA_OEM
if /i !ESDedition%1!==Professional (IF !ESDvol%1!==1 (set DVDLABEL%1=CPRA&set DVDISO%1=PROFESSIONALVL_VOL) else (set DVDLABEL%1=CPRA&set DVDISO%1=PRO_OEMRET))
if /i !ESDedition%1!==ProfessionalN (IF !ESDvol%1!==1 (set DVDLABEL%1=CPRNA&set DVDISO%1=PROFESSIONALNVL_VOL) else (set DVDLABEL%1=CPRNA&set DVDISO%1=PRON_OEMRET))
if /i !ESDedition%1!==Education (IF !ESDvol%1!==1 (set DVDLABEL%1=CEDA&set DVDISO%1=EDUCATION_VOL) else (set DVDLABEL%1=CEDA&set DVDISO%1=EDUCATION_RET))
if /i !ESDedition%1!==EducationN (IF !ESDvol%1!==1 (set DVDLABEL%1=CEDNA&set DVDISO%1=EDUCATIONN_VOL) else (set DVDLABEL%1=CEDNA&set DVDISO%1=EDUCATIONN_RET))
if /i !ESDedition%1!==Enterprise set DVDLABEL%1=CENA&set DVDISO%1=ENTERPRISE_VOL
if /i !ESDedition%1!==EnterpriseN set DVDLABEL%1=CENNA&set DVDISO%1=ENTERPRISEN_VOL
if /i !ESDedition%1!==PPIPro set DVDLABEL%1=CPPIA&set DVDISO%1=PPIPRO_OEM
if /i !ESDedition%1!==Cloud set DVDLABEL%1=CWCA&set DVDISO%1=CLOUD_OEM
if /i !ESDedition%1!==CloudN set DVDLABEL%1=CWCNNA&set DVDISO%1=CLOUDN_OEM
if /i !ESDedition%1!==EnterpriseG set DVDLABEL%1=CEGA&set DVDISO%1=ENTERPRISEG_VOL
if /i !ESDedition%1!==EnterpriseGN set DVDLABEL%1=CEGNA&set DVDISO%1=ENTERPRISEGN_VOL
if /i !ESDedition%1!==EnterpriseS set DVDLABEL%1=CES&set DVDISO%1=ENTERPRISES_VOL
if /i !ESDedition%1!==EnterpriseSN set DVDLABEL%1=CESNN&set DVDISO%1=ENTERPRISESN_VOL
if /i !ESDedition%1!==ProfessionalEducation (IF !ESDvol%1!==1 (set DVDLABEL%1=CPREA&set DVDISO%1=PROEDUCATION_VOL) else (set DVDLABEL%1=CPREA&set DVDISO%1=PROEDUCATION_OEMRET))
if /i !ESDedition%1!==ProfessionalEducationN (IF !ESDvol%1!==1 (set DVDLABEL%1=CPRENA&set DVDISO%1=PROEDUCATIONN_VOL) else (set DVDLABEL%1=CPRENA&set DVDISO%1=PROEDUCATIONN_OEMRET))
if /i !ESDedition%1!==ProfessionalWorkstation (IF !ESDvol%1!==1 (set DVDLABEL%1=CPRWA&set DVDISO%1=PROWORKSTATION_VOL) else (set DVDLABEL%1=CPRWA&set DVDISO%1=PROWORKSTATION_OEMRET))
if /i !ESDedition%1!==ProfessionalWorkstationN (IF !ESDvol%1!==1 (set DVDLABEL%1=CPRWNA&set DVDISO%1=PROWORKSTATIONN_VOL) else (set DVDLABEL%1=CPRWNA&set DVDISO%1=PROWORKSTATIONN_OEMRET))
if /i !ESDedition%1!==ProfessionalSingleLanguage set DVDLABEL%1=CPRSLA&set DVDISO%1=PROSINGLELANGUAGE_OEM
if /i !ESDedition%1!==ProfessionalCountrySpecific set DVDLABEL%1=CPRCHA&set DVDISO%1=PROCHINA_OEM
IF !ESDmulti%1! GEQ 5 (
if !ESDeditionn%1!==1 set DVDLABEL%1=CCSNA&set DVDISO%1=MULTIN_OEMRET
if !ESDeditions%1!==1 set DVDLABEL%1=CCSA&set DVDISO%1=MULTISL_OEMRET
if !ESDeditiona%1!==1 set DVDLABEL%1=CCSA&set DVDISO%1=MULTI_OEMRET
if !ESDeditionc%1!==1 set DVDLABEL%1=CCCHA&set DVDISO%1=MULTICHINA_OEMRET
if !ESDver%1! GEQ 16299 (IF !ESDvol%1!==1 (set DVDLABEL%1=CCSA&set DVDISO%1=BUSINESS_VOL) else (set DVDLABEL%1=CCSA&set DVDISO%1=CONSUMER_OEMRET))
)
if %1==2 exit /b

set build=!ESDver%1!
set langid=!ESDlang%1!
call :setlabel %1
exit /b

:QUIT
IF EXIST bin\temp\ rmdir /s /q bin\temp\
IF EXIST ISOFOLDER\ rmdir /s /q ISOFOLDER\
IF EXIST "%ENCRYPTEDESD%.bak" (
del /f /q "%ENCRYPTEDESD%" >nul 2>&1
ren "%ENCRYPTEDESD%.bak" %ENCRYPTEDESDN%
)
exit