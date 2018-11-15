@echo off
rem 0 - source distributions folders will be directly modified
rem 1 - source distributions folders will be copied then modified
rem if source distributions are .ISO files, this option has no affect
SET Preserve=0

rem script:     abbodi1406
rem wimlib:     synchronicity
rem offlinereg: erwan.l
rem aio efisys: cdob

cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  cmd /u /c echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~dp0"" && ""%~dpnx0""", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )

title Multi-Architecture ISO
for %%a in (wimlib-imagex,7z,bcdedit,bfi,offlinereg) do (
if not exist "%~dp0bin\%%a.exe" (echo Error: required %%a.exe is missing&pause&exit)
)
IF /I "%PROCESSOR_ARCHITECTURE%" EQU "AMD64" (SET "wimlib=%~dp0bin\bin64\wimlib-imagex.exe") ELSE (SET "wimlib=%~dp0bin\wimlib-imagex.exe")
cd /d "%~dp0"
setlocal EnableExtensions
setlocal EnableDelayedExpansion
SET ERRORTEMP=
SET "ramdiskoptions={7619dcc8-fafe-11d9-b411-000476eba25f}"
SET combine=0
SET custom=0
SET winx=1

set _dir64=0
set _dir86=0
set _iso64=0
set _iso86=0

dir /b /ad *x64* 1>nul 2>nul && (for /f "delims=" %%i in ('dir /b /ad *x64*') do if exist "%%i\sources\*.wim" (set _dir64=1&set "ISOdir1=%%i"))
dir /b /ad *x86* 1>nul 2>nul && (for /f "delims=" %%i in ('dir /b /ad *x86*') do if exist "%%i\sources\*.wim" (set _dir86=1&set "ISOdir2=%%i"))
if %_dir64% equ 1 if %_dir86% equ 1 goto :DUALMENU

dir /b /a:-d *_x64*.iso 1>nul 2>nul && (set _iso64=1&for /f "delims=" %%i in ('dir /b /a:-d *_x64*.iso') do set "ISOfile1=%%i")
dir /b /a:-d *_x86*.iso 1>nul 2>nul && (set _iso86=1&for /f "delims=" %%i in ('dir /b /a:-d *_x86*.iso') do set "ISOfile2=%%i")
dir /b /a:-d *_x32*.iso 1>nul 2>nul && (set _iso86=1&for /f "delims=" %%i in ('dir /b /a:-d *_x32*.iso') do set "ISOfile2=%%i")
if %_iso64% equ 1 if %_iso86% equ 1 goto :DUALMENU

:prompt
cls
set _iso1=
set _iso2=
echo ============================================================
echo Enter / Paste the complete path to 1st ISO file
echo ============================================================
echo.
set /p "_iso1="
if "%_iso1%"=="" goto :QUIT
echo %_iso1%| findstr /E /I "\.iso" >nul || (echo.&echo Error: entered path does not represent an ISO file&pause&goto :prompt)
echo %_iso1%| findstr /I /C:"x64" 1>nul && (set _iso64=1&for /f "delims=" %%i in ('echo %_iso1%') do set "ISOfile1=%%i")
echo %_iso1%| findstr /I /C:"x86" 1>nul && (set _iso86=1&for /f "delims=" %%i in ('echo %_iso1%') do set "ISOfile2=%%i")
echo %_iso1%| findstr /I /C:"x32" 1>nul && (set _iso86=1&for /f "delims=" %%i in ('echo %_iso1%') do set "ISOfile2=%%i")
echo.
echo ============================================================
echo Enter / Paste the complete path to 2nd ISO file
echo ============================================================
echo.
set /p "_iso2="
if "%_iso2%"=="" goto :QUIT
echo %_iso2%| findstr /E /I "\.iso" >nul || (echo.&echo Error: entered path does not represent an ISO file&pause&goto :prompt)
echo %_iso2%| findstr /I /C:"x64" 1>nul && (set _iso64=1&for /f "delims=" %%i in ('echo %_iso2%') do set "ISOfile1=%%i")
echo %_iso2%| findstr /I /C:"x86" 1>nul && (set _iso86=1&for /f "delims=" %%i in ('echo %_iso2%') do set "ISOfile2=%%i")
echo %_iso2%| findstr /I /C:"x32" 1>nul && (set _iso86=1&for /f "delims=" %%i in ('echo %_iso2%') do set "ISOfile2=%%i")
if %_iso64% equ 1 if %_iso86% equ 1 goto :DUALMENU
if %_iso64% equ 0 if %_iso86% equ 0 goto :QUIT
if %_iso64% equ 1 if %_iso86% equ 0 (SET "MESSAGE=both ISO files are x64"&GOTO :E_MSG)
if %_iso64% equ 0 if %_iso86% equ 1 (SET "MESSAGE=both ISO files are x86"&GOTO :E_MSG)

:DUALMENU
cls
color 1f
echo ============================================================
echo. Sources:
echo.
if %_iso64% equ 1 (SET Preserve=0&echo "%ISOfile1%"&echo "%ISOfile2%") else (echo "%ISOdir1%"&echo "%ISOdir2%")
echo.
echo ============================================================
echo. Options:
echo.
echo. 0 - Exit
echo. 1 - Create ISO with 1 combined install.wim/.esd
echo. 2 - Create ISO with 2 separate install.wim/.esd ^(Win 10^)
echo ============================================================
echo.
choice /c 120 /n /m "Choose a menu option: "
if errorlevel 3 goto :QUIT
if errorlevel 2 (if %_iso64% equ 1 (goto :dISO) else (goto :dCheck))
if errorlevel 1 (set combine=1&set custom=1&if %_iso64% equ 1 (goto :dISO) else (goto :dCheck))
GOTO :DUALMENU

:dISO
cls
echo.
echo ============================================================
echo Extracting ISO files . . .
echo ============================================================
echo.
set "ISOdir1=ISOx64"
set "ISOdir2=ISOx86"
echo "%ISOfile1%"
IF EXIST %ISOdir1%\ rmdir /s /q %ISOdir1%\
bin\7z.exe x "%ISOfile1%" -o%ISOdir1% * -r >nul
echo.
echo "%ISOfile2%"
IF EXIST %ISOdir2%\ rmdir /s /q %ISOdir2%\
bin\7z.exe x "%ISOfile2%" -o%ISOdir2% * -r >nul

:dCheck
echo.
echo ============================================================
echo Checking distributions Info . . .
echo ============================================================
FOR /L %%j IN (1,1,2) DO (
SET ISOmulti%%j=0
SET ISOvol%%j=0
SET ISOarch%%j=0
SET ISOver%%j=0
SET ISOlang%%j=0
SET BOOTver%%j=0
SET WIMFILE%%j=0
)
CALL :dInfo 1
CALL :dInfo 2
if /i %ISOarch1% equ %ISOarch2% (SET "MESSAGE=ISO distributions have the same architecture."&GOTO :E_MSG)
if /i %ISOver1% neq %ISOver2%   (SET "MESSAGE=ISO distributions have different Windows versions."&GOTO :E_MSG)
if /i %ISOlang1% neq %ISOlang2% (SET "MESSAGE=ISO distributions have different languages."&GOTO :E_MSG)
if /i %WIMFILE1% neq %WIMFILE2% (SET "MESSAGE=ISO distributions have different install file format."&GOTO :E_MSG)
if %combine%==0 if %winx%==0 (SET "MESSAGE=ISO with 2 separate install files require Windows 10 setup files"&GOTO :E_MSG)
set WIMFILE=%WIMFILE1%

:Dual
cls
echo.
echo ============================================================
echo Preparing ISO Info . . .
echo ============================================================
CALL :dPREPARE 1
CALL :dPREPARE 2
IF EXIST ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
if %Preserve%==1 (
echo.
echo ============================================================
echo Copying distributions folders . . .
echo ============================================================
xcopy "%ISOdir1%\*" ISOFOLDER\x64\ /cheriky >nul 2>&1
xcopy "%ISOdir2%\*" ISOFOLDER\x86\ /cheriky >nul 2>&1
) else (
move "%ISOdir1%" .\ISOFOLDER\x64 >nul
move "%ISOdir2%" .\ISOFOLDER\x86 >nul
)
set archl=X86-X64
if /i %DVDLABEL1% equ %DVDLABEL2% (
set DVDLABEL=%DVDLABEL1%_%archl%FRE_%langid%_DV9
set DVDISO=%_label%%DVDISO1%_%archl%FRE_%langid%
) else (
set DVDLABEL=CCSA_%archl%FRE_%langid%_DV9
set DVDISO=%_label%%DVDISO1%_%ISOarch1%FRE-%DVDISO2%_%ISOarch2%FRE_%langid%
)
if %combine%==0 goto :BCD
echo.
echo ============================================================
echo Unifying %WIMFILE% . . .
echo ============================================================
echo.
for /f "tokens=3 delims=: " %%i in ('bin\wimlib-imagex.exe info ISOFOLDER\x86\sources\%WIMFILE% ^| findstr /c:"Image Count"') do set imagesi=%%i
for /f "tokens=3 delims=: " %%i in ('bin\wimlib-imagex.exe info ISOFOLDER\x64\sources\%WIMFILE% ^| findstr /c:"Image Count"') do set imagesx=%%i
for /f "tokens=1* delims=: " %%i in ('bin\wimlib-imagex.exe info ISOFOLDER\x86\sources\%WIMFILE% 1 ^| findstr /b "Name"') do set "_osi=%%j x86"
for /f "tokens=1* delims=: " %%i in ('bin\wimlib-imagex.exe info ISOFOLDER\x64\sources\%WIMFILE% 1 ^| findstr /b "Name"') do set "_osx=%%j x64"
IF NOT %imagesi%==1 FOR /L %%g IN (2,1,%imagesi%) DO (
for /f "tokens=1* delims=: " %%i in ('bin\wimlib-imagex.exe info ISOFOLDER\x86\sources\%WIMFILE% %%g ^| findstr /b "Name"') do set "_osi%%g=%%j x86"
)
IF NOT %imagesx%==1 FOR /L %%g IN (2,1,%imagesx%) DO (
for /f "tokens=1* delims=: " %%i in ('bin\wimlib-imagex.exe info ISOFOLDER\x64\sources\%WIMFILE% %%g ^| findstr /b "Name"') do set "_osx%%g=%%j x64"
)
"%wimlib%" info ISOFOLDER\x86\sources\%WIMFILE% 1 "%_osi%" "%_osi%" --image-property DISPLAYNAME="%_osi%" --image-property DISPLAYDESCRIPTION="%_osi%" 1>nul 2>nul
IF NOT %imagesi%==1 FOR /L %%g IN (2,1,%imagesi%) DO (
"%wimlib%" info ISOFOLDER\x86\sources\%WIMFILE% %%g "!_osi%%g!" "!_osi%%g!" --image-property DISPLAYNAME="!_osi%%g!" --image-property DISPLAYDESCRIPTION="!_osi%%g!" 1>nul 2>nul
)
"%wimlib%" info ISOFOLDER\x64\sources\%WIMFILE% 1 "%_osx%" "%_osx%" --image-property DISPLAYNAME="%_osx%" --image-property DISPLAYDESCRIPTION="%_osx%" 1>nul 2>nul
"%wimlib%" export ISOFOLDER\x64\sources\%WIMFILE% 1 ISOFOLDER\x86\sources\%WIMFILE%
IF NOT %imagesx%==1 FOR /L %%g IN (2,1,%imagesx%) DO (
"%wimlib%" info ISOFOLDER\x64\sources\%WIMFILE% %%g "!_osx%%g!" "!_osx%%g!" --image-property DISPLAYNAME="!_osx%%g!" --image-property DISPLAYDESCRIPTION="!_osx%%g!" 1>nul 2>nul
"%wimlib%" export ISOFOLDER\x64\sources\%WIMFILE% %%g ISOFOLDER\x86\sources\%WIMFILE%
)

:BCD
echo.
echo ============================================================
echo Preparing boot configuration settings . . .
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
for /f "tokens=5-10 delims=: " %%G in ('bin\wimlib-imagex.exe info ISOFOLDER\x64\sources\boot.wim 2 ^| find /i "Last Modification Time"') do (set mmm=%%G&set "isotime=%%H/%%L,%%I:%%J:%%K")
call :setdate %mmm%
%bcde% /store %BCDBIOS% /set {bootmgr} nointegritychecks Yes >nul 2>&1
%bcde% /store %BCDBIOS% /set {default} description "Windows Setup (64-bit) - BIOS" >nul 2>&1
%bcde% /store %BCDBIOS% /set {default} device ramdisk=%entry64% >nul 2>&1
%bcde% /store %BCDBIOS% /set {default} osdevice ramdisk=%entry64% >nul 2>&1
%bcde% /store %BCDBIOS% /set {default} nointegritychecks Yes >nul 2>&1
%bcde% /store %BCDBIOS% /set {default} nx OptIn >nul 2>&1
%bcde% /store %BCDBIOS% /set {default} pae Default >nul 2>&1
%bcde% /store %BCDBIOS% /set {default} ems No >nul 2>&1
%bcde% /store %BCDBIOS% /deletevalue {default} bootmenupolicy >nul 2>&1
for /f "tokens=2 delims={}" %%A in ('%bcde% /store %BCDBIOS% /copy {default} /d "Windows Setup (32-bit) - BIOS"') do set "guid={%%A}"
%bcde% /store %BCDBIOS% /set %guid% device ramdisk=%entry86% >nul 2>&1
%bcde% /store %BCDBIOS% /set %guid% osdevice ramdisk=%entry86% >nul 2>&1
%bcde% /store %BCDBIOS% /timeout 30 >nul 2>&1
attrib -s -h -a "%BCDBIOS%.LOG*" >nul 2>&1
del /f /q "%BCDBIOS%.LOG*" >nul 2>&1
%bcde% /store %BCDUEFI% /set {default} description "Windows Setup (64-bit) - UEFI" >nul 2>&1
%bcde% /store %BCDUEFI% /set {default} device ramdisk=%entry64% >nul 2>&1
%bcde% /store %BCDUEFI% /set {default} osdevice ramdisk=%entry64% >nul 2>&1
%bcde% /store %BCDUEFI% /set {default} isolatedcontext Yes >nul 2>&1
%bcde% /store %BCDUEFI% /set {default} nx OptIn >nul 2>&1
%bcde% /store %BCDUEFI% /set {default} ems No >nul 2>&1
attrib -s -h -a "%BCDUEFI%.LOG*" >nul 2>&1
del /f /q "%BCDUEFI%.LOG*" >nul 2>&1
if not exist ISOFOLDER\efi\boot\bootx64.efi (
"%wimlib%" extract ISOFOLDER\x64\sources\boot.wim 1 Windows\Boot\EFI\bootmgfw.efi --dest-dir=.\ISOFOLDER\efi\boot --no-acls >nul 2>&1
rename ISOFOLDER\efi\boot\bootmgfw.efi bootx64.efi
)
if not exist ISOFOLDER\efi\microsoft\boot\memtest.efi (
"%wimlib%" extract ISOFOLDER\x64\sources\boot.wim 1 Windows\Boot\EFI\memtest.efi --dest-dir=.\ISOFOLDER\efi\microsoft\boot --no-acls >nul 2>&1
del /f /q ISOFOLDER\boot\memtest.efi >nul 2>&1
%bcde% /store %BCDUEFI% /enum all | findstr /i {memdiag} 1>nul || (
  %bcde% /store %BCDUEFI% /create {memdiag} >nul 2>&1
  %bcde% /store %BCDUEFI% /set {memdiag} description "Windows Memory Diagnostic" >nul 2>&1
  %bcde% /store %BCDUEFI% /set {memdiag} device boot >nul 2>&1
  %bcde% /store %BCDUEFI% /set {memdiag} path \efi\microsoft\boot\memtest.efi >nul 2>&1
  %bcde% /store %BCDUEFI% /set {memdiag} locale en-US >nul 2>&1
  %bcde% /store %BCDUEFI% /set {memdiag} inherit {globalsettings} >nul 2>&1
  %bcde% /store %BCDUEFI% /toolsdisplayorder {memdiag} /addlast >nul 2>&1
  )
)
if %custom%==0 goto :ISOCREATE
echo.
echo ============================================================
echo Preparing Custom AIO settings . . .
echo ============================================================
echo.
mkdir ISOFOLDER\sources
move /y ISOFOLDER\x64\sources\boot.wim ISOFOLDER\sources\bootx64.wim >nul 2>&1
move /y ISOFOLDER\x86\sources\boot.wim ISOFOLDER\sources\bootx86.wim >nul 2>&1
move /y ISOFOLDER\x86\sources\%WIMFILE% ISOFOLDER\sources\ >nul 2>&1
move /y ISOFOLDER\x86\sources\lang.ini ISOFOLDER\sources\lang.ini >nul 2>&1
call :dSETUP x64
call :dSETUP x86
if not exist "ISOFOLDER\x86\efi\boot\bootia32.efi" (
rmdir /s /q ISOFOLDER\x64 >nul 2>&1
rmdir /s /q ISOFOLDER\x86 >nul 2>&1
goto :ISOCREATE
)
copy /y ISOFOLDER\x86\efi\boot\bootia32.efi ISOFOLDER\efi\boot\ >nul 2>&1
copy /y ISOFOLDER\x86\efi\microsoft\boot\memtest.efi ISOFOLDER\efi\microsoft\boot\memtestx86.efi >nul 2>&1
rename ISOFOLDER\efi\microsoft\boot\memtest.efi memtestx64.efi
%bcde% /store %BCDUEFI% /deletevalue {default} bootmenupolicy >nul 2>&1
for /f "tokens=2 delims={}" %%A in ('%bcde% /store %BCDUEFI% /copy {default} /d "Windows Setup (32-bit) - UEFI"') do set "guid={%%A}"
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
bin\7z.exe x ISOFOLDER\efi\microsoft\boot\efisys.bin -o.\bin\temp\ >nul 2>&1
copy /y ISOFOLDER\efi\boot\bootia32.efi bin\temp\EFI\Boot\BOOTIA32.EFI >nul 2>&1
bin\bfi.exe -t=288 -l=EFISECTOR -f=bin\efisys.ima bin\temp >nul 2>&1
move /y bin\efisys.ima ISOFOLDER\efi\microsoft\boot\efisys.bin >nul 2>&1
del /f /q ISOFOLDER\efi\microsoft\boot\*noprompt.* >nul 2>&1
rmdir /s /q .\bin\temp >nul 2>&1
rmdir /s /q ISOFOLDER\x64 >nul 2>&1
rmdir /s /q ISOFOLDER\x86 >nul 2>&1

:ISOCREATE
echo.
echo ============================================================
echo Creating ISO . . .
echo ============================================================
if exist "ISOFOLDER\efi\microsoft\boot\efisys.bin" (
bin\cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -g -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO
) else (
bin\cdimage.exe -b"ISOFOLDER\boot\etfsboot.com" -o -m -u2 -udfver102 -t%isotime% -g -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO
)
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

:dInfo
if not exist "!ISOdir%1!\sources\boot.wim" (SET "MESSAGE=ISO %1 is missing boot.wim"&GOTO :E_MSG)
dir /b "!ISOdir%1!\sources\install.wim" 1>nul 2>nul && (set WIMFILE%1=install.wim)
dir /b "!ISOdir%1!\sources\install.esd" 1>nul 2>nul && (set WIMFILE%1=install.esd)
if /i !WIMFILE%1! equ 0 (SET "MESSAGE=ISO %1 is missing install.wim/install.esd"&GOTO :E_MSG)
bin\wimlib-imagex.exe info "!ISOdir%1!\sources\!WIMFILE%1!">bin\infoall.txt 2>&1
find /i "CoreCountrySpecific" bin\infoall.txt 1>nul && (set ISOeditionc%1=1) || (set ISOeditionc%1=0)
bin\wimlib-imagex.exe info "!ISOdir%1!\sources\!WIMFILE%1!" 1 >bin\info.txt 2>&1
for /f "tokens=2 delims=: " %%i in ('findstr /i /b "Build" bin\info.txt') do set ISOver%1=%%i
for /f "tokens=3 delims=: " %%i in ('findstr /i /b "Edition" bin\info.txt') do set ISOedition%1=%%i
for /f "tokens=3 delims=: " %%i in ('find /i "Default" bin\info.txt') do set ISOlang%1=%%i
for /f "tokens=2 delims=: " %%i in ('find /i "Architecture" bin\info.txt') do (IF /I %%i EQU x86 (SET ISOarch%1=x86) ELSE IF /I %%i EQU x86_64 (SET ISOarch%1=x64))
for /f "tokens=3 delims=: " %%i in ('findstr /i /b /c:"Image Count" bin\infoall.txt') do (IF %%i GEQ 2 SET ISOmulti%1=%%i)
for /f "tokens=2 delims=: " %%i in ('bin\wimlib-imagex.exe info "!ISOdir%1!\sources\boot.wim" 1 ^| findstr /i /b "Build"') do set BOOTver%1=%%i
if /i !BOOTver%1! lss 10240 (set winx=0)
if /i !ISOarch%1! equ 0 (SET "MESSAGE=ISO %1 architecture is not supported."&GOTO :E_MSG)
type "!ISOdir%1!\sources\ei.cfg" 2>nul | find /i "Volume" 1>nul && set ISOvol%1=1
del /f /q bin\info*.txt
exit /b

:dPREPARE
set DVDLABEL%1=CCSA&set DVDISO%1=!ISOedition%1!_OEMRET
if /i !ISOedition%1!==Core set DVDLABEL%1=CCRA&set DVDISO%1=CORE_OEMRET
if /i !ISOedition%1!==CoreN set DVDLABEL%1=CCRNA&set DVDISO%1=COREN_OEMRET
if /i !ISOedition%1!==CoreSingleLanguage set DVDLABEL%1=CSLA&set DVDISO%1=SINGLELANGUAGE_OEM
if /i !ISOedition%1!==CoreCountrySpecific set DVDLABEL%1=CCHA&set DVDISO%1=CHINA_OEM
if /i !ISOedition%1!==Professional (IF !ISOvol%1!==1 (set DVDLABEL%1=CPRA&set DVDISO%1=PROFESSIONALVL_VOL) else (set DVDLABEL%1=CPRA&set DVDISO%1=PRO_OEMRET))
if /i !ISOedition%1!==ProfessionalN (IF !ISOvol%1!==1 (set DVDLABEL%1=CPRNA&set DVDISO%1=PROFESSIONALNVL_VOL) else (set DVDLABEL%1=CPRNA&set DVDISO%1=PRON_OEMRET))
if /i !ISOedition%1!==Education (IF !ISOvol%1!==1 (set DVDLABEL%1=CEDA&set DVDISO%1=EDUCATION_VOL) else (set DVDLABEL%1=CEDA&set DVDISO%1=EDUCATION_RET))
if /i !ISOedition%1!==EducationN (IF !ISOvol%1!==1 (set DVDLABEL%1=CEDNA&set DVDISO%1=EDUCATIONN_VOL) else (set DVDLABEL%1=CEDNA&set DVDISO%1=EDUCATIONN_RET))
if /i !ISOedition%1!==Enterprise set DVDLABEL%1=CENA&set DVDISO%1=ENTERPRISE_VOL
if /i !ISOedition%1!==EnterpriseN set DVDLABEL%1=CENNA&set DVDISO%1=ENTERPRISEN_VOL
if /i !ISOedition%1!==PPIPro set DVDLABEL%1=CPPIA&set DVDISO%1=PPIPRO_OEM
if /i !ISOedition%1!==Cloud set DVDLABEL%1=CWCA&set DVDISO%1=CLOUD_OEM
if /i !ISOedition%1!==CloudN set DVDLABEL%1=CWCNNA&set DVDISO%1=CLOUDN_OEM
if /i !ISOedition%1!==EnterpriseG set DVDLABEL%1=CEGA&set DVDISO%1=ENTERPRISEG_VOL
if /i !ISOedition%1!==EnterpriseGN set DVDLABEL%1=CEGNA&set DVDISO%1=ENTERPRISEGN_VOL
if /i !ISOedition%1!==EnterpriseS set DVDLABEL%1=CES&set DVDISO%1=ENTERPRISES_VOL
if /i !ISOedition%1!==EnterpriseSN set DVDLABEL%1=CESNN&set DVDISO%1=ENTERPRISESN_VOL
if /i !ISOedition%1!==ProfessionalEducation (IF !ISOvol%1!==1 (set DVDLABEL%1=CPREA&set DVDISO%1=PROEDUCATION_VOL) else (set DVDLABEL%1=CPREA&set DVDISO%1=PROEDUCATION_OEMRET))
if /i !ISOedition%1!==ProfessionalEducationN (IF !ISOvol%1!==1 (set DVDLABEL%1=CPRENA&set DVDISO%1=PROEDUCATIONN_VOL) else (set DVDLABEL%1=CPRENA&set DVDISO%1=PROEDUCATIONN_OEMRET))
if /i !ISOedition%1!==ProfessionalWorkstation (IF !ISOvol%1!==1 (set DVDLABEL%1=CPRWA&set DVDISO%1=PROWORKSTATION_VOL) else (set DVDLABEL%1=CPRWA&set DVDISO%1=PROWORKSTATION_OEMRET))
if /i !ISOedition%1!==ProfessionalWorkstationN (IF !ISOvol%1!==1 (set DVDLABEL%1=CPRWNA&set DVDISO%1=PROWORKSTATIONN_VOL) else (set DVDLABEL%1=CPRWNA&set DVDISO%1=PROWORKSTATIONN_OEMRET))
if /i !ISOedition%1!==ProfessionalSingleLanguage set DVDLABEL%1=CPRSLA&set DVDISO%1=PROSINGLELANGUAGE_OEM
if /i !ISOedition%1!==ProfessionalCountrySpecific set DVDLABEL%1=CPRCHA&set DVDISO%1=PROCHINA_OEM
IF !ISOmulti%1! GEQ 2 (
set DVDLABEL%1=CCSA&set DVDISO%1=MULTI_OEMRET
if !ISOeditionc%1!==1 set DVDLABEL%1=CCCHA&set DVDISO%1=MULTICHINA_OEMRET
)
if /i !ISOarch%1!==x86 (set ISOarch%1=X86) else (set ISOarch%1=X64)
if %1==2 exit /b

"%wimlib%" extract "!ISOdir%1!\sources\%WIMFILE%" 1 \Windows\System32\ntoskrnl.exe --dest-dir=.\bin\temp --no-acls >nul 2>&1
bin\7z.exe l .\bin\temp\ntoskrnl.exe >.\bin\temp\version.txt 2>&1
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\temp\version.txt" 2^>nul') do set version=%%i.%%j&set branch=%%k&set datetime=%%l
if !ISOver%1! geq 10240 (
"%wimlib%" extract "!ISOdir%1!\sources\%WIMFILE%" 1 Windows\WinSxS\Manifests\amd64_microsoft-windows-coreos-revision* --dest-dir=.\bin\temp --no-acls >nul 2>&1 || "%wimlib%" extract "!ISOdir%1!\sources\%WIMFILE%" 1 Windows\WinSxS\Manifests\x86_microsoft-windows-coreos-revision* --dest-dir=.\bin\temp --no-acls >nul 2>&1
for /f "tokens=6,7 delims=_." %%i in ('dir /b /od .\bin\temp\*.manifest') do set revision=%%i.%%j
if not "!version!"=="!revision!" (
set version=!revision!
for /f "tokens=5,6,7,8,9,10 delims=: " %%G in ('bin\wimlib-imagex.exe info "!ISOdir%1!\sources\%WIMFILE%" 1 ^| find /i "Last Modification Time"') do (set mmm=%%G&set yyy=%%L&set ddd=%%H-%%I%%J)
call :setmmm !mmm!
)
)
set _label2=
if /i "%branch%"=="WinBuild" (
"%wimlib%" extract "!ISOdir%1!\sources\%WIMFILE%" 1 \Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls >nul
for /f "tokens=3 delims==:" %%a in ('"bin\offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion" getvalue BuildLabEx" 2^>nul') do if not errorlevel 1 (for /f "tokens=1-5 delims=." %%i in ('echo %%~a') do set _label2=%%i.%%j.%%m.%%l_CLIENT&set branch=%%l)
)
if defined _label2 (set _label=%_label2%) else (set _label=%version%.%datetime%.%branch%_CLIENT)
if %version%==9600.17031 (set _label=9600.17031.140317-1640.winblue_ir3_CLIENT)
if %version%==9600.17238 (set _label=9600.17238.140923-1144.winblue_ir4_CLIENT)
if %version%==9600.17415 (set _label=9600.17415.141120-0031.winblue_ir5_CLIENT)
if %version%==10240.16487 (set _label=10240.16393.150909-1450.th1_refresh_CLIENT)
if %version%==10586.104 (set _label=10586.0.160212-2000.th2_refresh_CLIENT)
if %version%==10586.164 (set _label=10586.0.160426-1409.th2_refresh_CLIENT)
if %version%==14393.447 (set _label=14393.0.161119-1705.rs1_refresh_CLIENT)
if %version%==15063.413 (set _label=15063.0.170607-1447.rs2_release_svc_refresh_CLIENT)
if %version%==15063.483 (set _label=15063.0.170710-1358.rs2_release_svc_refresh_CLIENT)
if %version%==16299.64 (set _label=16299.15.171109-1522.rs3_release_svc_refresh_CLIENT)
if %version%==16299.125 (set _label=16299.125.171213-1220.rs3_release_svc_refresh_CLIENT)
if %version%==17134.112 (set _label=17134.112.180619-1212.rs4_release_svc_refresh_CLIENT)
rmdir /s /q .\bin\temp >nul 2>&1

set langid=!ISOlang%1!
for %%b in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _label=!_label:%%b=%%b!
set langid=!langid:%%b=%%b!
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

:E_MSG
echo.
echo ============================================================
echo Error:
echo %MESSAGE%
echo.
echo.
echo Press any key to exit.
pause >nul

:QUIT
if exist bin\temp\ rmdir /s /q bin\temp\
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
if exist ISOx64\ rmdir /s /q ISOx64\
if exist ISOx86\ rmdir /s /q ISOx86\
exit