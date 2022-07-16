<!-- : Begin batch script
@setlocal DisableDelayedExpansion
@echo off
:: 0 - source distributions folders will be directly modified
:: 1 - source distributions folders will be copied then modified
:: if source distributions are .ISO files, this option has no affect
set Preserve=0

:: script:     abbodi1406
:: wimlib:     synchronicity
:: offlinereg: erwan.l
:: aio efisys: cdob

:: ###################################################################

set "_Null=1>nul 2>nul"
set "_Nul3=1>nul 2>nul"
set "_Nul6=2^>nul"

set _Debug=0
set _elev=
set _args=%*
if not defined _args goto :NoProgArgs
if "%~1"=="" set "_args="&goto :NoProgArgs
if "%~1"=="-elevated" set _elev=1&set "_args="&goto :NoProgArgs
if "%~5"=="-elevated" set _elev=1

:NoProgArgs
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "xOS=%PROCESSOR_ARCHITECTURE%"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if defined PROCESSOR_ARCHITEW6432 (
  set "xOS=%PROCESSOR_ARCHITEW6432%"
  )
)
set "xDS=bin\bin64;bin"
if /i not %xOS%==amd64 set "xDS=bin"
set "Path=%xDS%;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "_err===== ERROR ===="
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
set _cwmi=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
wmic path Win32_ComputerSystem get CreationClassName /value 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
)
set _pwsh=1
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" set _pwsh=0
if %_cwmi% equ 0 if %_pwsh% EQU 0 goto :E_PS

%_Null% reg.exe query HKU\S-1-5-19 && (
  goto :Passed
  ) || (
  if defined _elev goto :E_Admin
)

set _PSarg="""%~f0""" -elevated
if defined _args set _PSarg="""%~f0""" %_args:"="""% -elevated
set _PSarg=%_PSarg:'=''%

(%_Null% cscript //NoLogo "%~f0?.wsf" //job:ELAV /File:"%~f0" -elevated) && (
  exit /b
  ) || (
  call setlocal EnableDelayedExpansion
  %_Null% powershell -nop -c "start cmd.exe -Arg '/c \"!_PSarg!\"' -verb runas" && (
    exit /b
    ) || (
    goto :E_Admin
  )
)

:Passed
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
setlocal EnableDelayedExpansion

:Begin
title Multi-Architecture ISO
pushd "!_work!"
set _file=(7z.dll,7z.exe,bcdedit.exe,bfi.exe,cdimage.exe,libwim-15.dll,offlinereg.exe,offreg.dll,wimlib-imagex.exe)
for %%# in %_file% do (
if not exist ".\bin\%%#" (set _bin=%%#&goto :E_Bin)
)
set ERRORTEMP=
set "ramdiskoptions={7619dcc8-fafe-11d9-b411-000476eba25f}"
set combine=0
set custom=0
set winx=1
set wimswm=0
set "line============================================================="
set _dir64=0
set _dir86=0
set _iso64=0
set _iso86=0

for /f "tokens=* delims=" %%# in ('dir /b /ad *_* %_Nul6%') do if exist "%%~#\sources\install.*" if exist "%%~#\sources\boot.wim" (
call :chkdir "%%~#"
)
if %_dir64% equ 1 if %_dir86% equ 1 goto :DUALMENU
goto :fndiso

:chkdir
if exist "%~1\efi\boot\bootx64.efi" (set _dir64=1&set "ISOdir1=%~1"&exit /b) else if exist "%~1\efi\boot\bootia32.efi" (set _dir86=1&set "ISOdir2=%~1"&exit /b)
if exist "%~1\sources\idwbinfo.txt" (
findstr /i amd64 idwbinfo.txt %_Nul3% && (set _dir64=1&set "ISOdir1=%~1"&exit /b)
findstr /i x86 idwbinfo.txt %_Nul3% && (set _dir86=1&set "ISOdir2=%~1"&exit /b)
)
if exist "%~1\sources\sxs\*amd64*.cab" (set _dir64=1&set "ISOdir1=%~1"&exit /b)
if exist "%~1\sources\sxs\*x86*.cab" (set _dir86=1&set "ISOdir2=%~1"&exit /b)
if not exist "%~1\sources\setup.exe" exit /b
7z.exe l "%~1\sources\setup.exe" >.\bin\version.txt 2>&1
findstr /i /b "CPU" .\bin\version.txt | find /i "x64" %_Nul3% && (set _dir64=1&set "ISOdir1=%~1")
findstr /i /b "CPU" .\bin\version.txt | find /i "x86" %_Nul3% && (set _dir86=1&set "ISOdir2=%~1")
del /f /q .\bin\version.txt %_Nul3%
exit /b

:fndiso
if not exist "*.iso" goto :noiso
for /f "tokens=* delims=" %%# in ('dir /b /a:-d *_x64*.iso %_Nul6%') do (
set _iso64=1
set "ISOfile1=%%#"
)
if %_iso64% equ 0 for /f "tokens=* delims=" %%# in ('dir /b /a:-d *_amd64*.iso %_Nul6%') do (
set _iso64=1
set "ISOfile1=%%#"
)
for /f "tokens=* delims=" %%# in ('dir /b /a:-d *_x86*.iso %_Nul6%') do (
set _iso86=1
set "ISOfile2=%%#"
)
if %_iso86% equ 0 for /f "tokens=* delims=" %%# in ('dir /b /a:-d *_x32*.iso %_Nul6%') do (
set _iso86=1
set "ISOfile2=%%#"
)
if %_iso64% equ 1 if %_iso86% equ 1 goto :DUALMENU

:noiso
setlocal DisableDelayedExpansion

:prompt1
@cls
set _erriso=0
set _iso1=
echo %line%
echo Enter / Paste the complete path to 1st ISO file
echo %line%
echo.
set /p _iso1=
if not defined _iso1 (set _Debug=1&goto :QUIT)
set "_iso1=%_iso1:"=%"
if not exist "%_iso1%" set _erriso=1
if /i not "%_iso1:~-4%"==".iso" set _erriso=1
if %_erriso% equ 1 (
echo.
echo %_err%
echo Specified path is not a valid ISO file
echo.
echo Press any key to continue...
pause >nul
goto :prompt1
)

:prompt2
set _erriso=0
set _iso2=
echo.
echo %line%
echo Enter / Paste the complete path to 2nd ISO file
echo %line%
echo.
set /p _iso2=
if not defined _iso2 (set _Debug=1&goto :QUIT)
set "_iso2=%_iso2:"=%"
if not exist "%_iso2%" set _erriso=1
if /i not "%_iso2:~-4%"==".iso" set _erriso=1
if %_erriso% equ 1 (
echo.
echo %_err%
echo Specified path is not a valid ISO file
echo.
echo Press any key to continue...
pause >nul
@cls
goto :prompt2
)

echo "%_iso1%"| findstr /I /C:"x64" 1>nul && (set _iso64=1&set "ISOfile1=%_iso1%")
if %_iso64% equ 0 echo "%_iso1%"| findstr /I /C:"amd64" 1>nul && (set _iso64=1&set "ISOfile1=%_iso1%")
echo "%_iso1%"| findstr /I /C:"x86" 1>nul && (set _iso86=1&set "ISOfile2=%_iso1%")
if %_iso86% equ 0 echo "%_iso1%"| findstr /I /C:"x32" 1>nul && (set _iso86=1&set "ISOfile2=%_iso1%")
echo "%_iso2%"| findstr /I /C:"x64" 1>nul && (set _iso64=1&set "ISOfile1=%_iso2%")
if %_iso64% equ 0 echo "%_iso2%"| findstr /I /C:"amd64" 1>nul && (set _iso64=1&set "ISOfile1=%_iso2%")
echo "%_iso2%"| findstr /I /C:"x86" 1>nul && (set _iso86=1&set "ISOfile2=%_iso2%")
if %_iso86% equ 0 echo "%_iso2%"| findstr /I /C:"x32" 1>nul && (set _iso86=1&set "ISOfile2=%_iso2%")

setlocal EnableDelayedExpansion
if %_iso64% equ 1 if %_iso86% equ 1 goto :DUALMENU
if %_iso64% equ 0 if %_iso86% equ 0 (set "MESSAGE=could not detect architecture tags"&goto :E_MSG)
if %_iso64% equ 1 if %_iso86% equ 0 (set "MESSAGE=could not detect x86 ISO file"&goto :E_MSG)
if %_iso64% equ 0 if %_iso86% equ 1 (set "MESSAGE=could not detect x64 ISO file"&goto :E_MSG)

:DUALMENU
color 1F
@cls
echo %line%
echo. Sources:
echo.
if %_iso64% equ 1 (set Preserve=0&echo "!ISOfile1!"&echo "!ISOfile2!") else (echo "!ISOdir1!"&echo "!ISOdir2!")
echo.
echo %line%
echo. Options:
echo.
echo. 0 - Exit
echo. 1 - Create ISO with 1 combined install .wim/.esd
echo. 2 - Create ISO with 2 separate install .wim/.esd/.swm ^(Win 11/10^)
echo %line%
echo.
choice /c 120 /n /m "Choose a menu option: "
if errorlevel 3 (set _Debug=1&goto :QUIT)
if errorlevel 2 (if %_iso64% equ 1 (goto :dISO) else (goto :dCheck))
if errorlevel 1 (set combine=1&set custom=1&if %_iso64% equ 1 (goto :dISO) else (goto :dCheck))
goto :DUALMENU

:dISO
@cls
echo.
echo %line%
echo Extracting ISO files . . .
echo %line%
echo.
set "ISOdir1=ISOx64"
set "ISOdir2=ISOx86"
echo "!ISOfile1!"
if exist %ISOdir1%\ rmdir /s /q %ISOdir1%\
7z.exe x "!ISOfile1!" -o%ISOdir1% * -r >nul
echo.
echo "!ISOfile2!"
if exist %ISOdir2%\ rmdir /s /q %ISOdir2%\
7z.exe x "!ISOfile2!" -o%ISOdir2% * -r >nul

:dCheck
if %_iso64% equ 0 @cls
echo.
echo %line%
echo Checking distributions Info . . .
echo %line%
for /L %%# in (1,1,2) do (
set ISOmulti%%#=0
set ISOvol%%#=0
set ISOarch%%#=0
set ISOver%%#=0
set ISOlang%%#=0
set BOOTver%%#=0
set WIMFILE%%#=0
)
call :dInfo 1
call :dInfo 2
if %wimswm% equ 1 (set combine=0&set custom=0)
:: if /i "%ISOver1%" neq "%ISOver2%" (set "MESSAGE=ISO distributions have different Windows versions."&goto :E_MSG)
if /i "%ISOarch1%" equ "%ISOarch2%" (set "MESSAGE=ISO distributions have the same architecture."&goto :E_MSG)
if /i "%ISOlang1%" neq "%ISOlang2%" (set "MESSAGE=ISO distributions have different languages."&goto :E_MSG)
if /i "%WIMFILE1%" neq "%WIMFILE2%" (set "MESSAGE=ISO distributions have different install file format."&goto :E_MSG)
 if %combine% equ 0 if %winx% equ 0 (set "MESSAGE=ISO with 2 separate install files require Windows 11/10 setup files"&goto :E_MSG)
set WIMFILE=%WIMFILE1%
echo.
echo %line%
echo Preparing ISO Info . . .
echo %line%
call :dPREPARE 1
call :dPREPARE 2
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
if %Preserve% equ 1 (
echo.
echo %line%
echo Copying distributions folders . . .
echo %line%
robocopy "!ISOdir1!" "ISOFOLDER\x64" /E /A-:R %_Nul3%
robocopy "!ISOdir2!" "ISOFOLDER\x86" /E /A-:R %_Nul3%
) else (
move "!ISOdir1!" .\ISOFOLDER\x64 %_Nul3%
move "!ISOdir2!" .\ISOFOLDER\x86 %_Nul3%
)
set archl=X86-X64
if /i "%DVDLABEL1%"=="%DVDLABEL2%" (
set DVDLABEL=%DVDLABEL1%_%archl%FRE_%langid%_DV9
set DVDISO=%_label%%DVDISO1%_%archl%FRE_%langid%
) else (
set DVDLABEL=CCSA_%archl%FRE_%langid%_DV9
set DVDISO=%_label%%DVDISO1%_%ISOarch1%FRE-%DVDISO2%_%ISOarch2%FRE_%langid%
)
if %combine% equ 0 goto :BCD
echo.
echo %line%
echo Unifying %WIMFILE% . . .
echo %line%
echo.
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info ISOFOLDER\x86\sources\%WIMFILE% ^| findstr /c:"Image Count"') do set imagesi=%%#
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info ISOFOLDER\x64\sources\%WIMFILE% ^| findstr /c:"Image Count"') do set imagesx=%%#
for /f "tokens=1* delims=: " %%i in ('wimlib-imagex.exe info ISOFOLDER\x86\sources\%WIMFILE% 1 ^| findstr /b "Name"') do set "_osi=%%j x86"
for /f "tokens=1* delims=: " %%i in ('wimlib-imagex.exe info ISOFOLDER\x64\sources\%WIMFILE% 1 ^| findstr /b "Name"') do set "_osx=%%j x64"
if not %imagesi%==1 for /L %%# in (2,1,%imagesi%) do (
for /f "tokens=1* delims=: " %%i in ('wimlib-imagex.exe info ISOFOLDER\x86\sources\%WIMFILE% %%# ^| findstr /b "Name"') do set "_osi%%#=%%j x86"
)
if not %imagesx%==1 for /L %%# in (2,1,%imagesx%) do (
for /f "tokens=1* delims=: " %%i in ('wimlib-imagex.exe info ISOFOLDER\x64\sources\%WIMFILE% %%# ^| findstr /b "Name"') do set "_osx%%#=%%j x64"
)
wimlib-imagex.exe info ISOFOLDER\x86\sources\%WIMFILE% 1 "%_osi%" "%_osi%" --image-property DISPLAYNAME="%_osi%" --image-property DISPLAYDESCRIPTION="%_osi%" %_Nul3%
if not %imagesi%==1 for /L %%# in (2,1,%imagesi%) do (
wimlib-imagex.exe info ISOFOLDER\x86\sources\%WIMFILE% %%# "!_osi%%#!" "!_osi%%#!" --image-property DISPLAYNAME="!_osi%%#!" --image-property DISPLAYDESCRIPTION="!_osi%%#!" %_Nul3%
)
wimlib-imagex.exe info ISOFOLDER\x64\sources\%WIMFILE% 1 "%_osx%" "%_osx%" --image-property DISPLAYNAME="%_osx%" --image-property DISPLAYDESCRIPTION="%_osx%" %_Nul3%
wimlib-imagex.exe export ISOFOLDER\x64\sources\%WIMFILE% 1 ISOFOLDER\x86\sources\%WIMFILE%
if not %imagesx%==1 for /L %%# in (2,1,%imagesx%) do (
wimlib-imagex.exe info ISOFOLDER\x64\sources\%WIMFILE% %%# "!_osx%%#!" "!_osx%%#!" --image-property DISPLAYNAME="!_osx%%#!" --image-property DISPLAYDESCRIPTION="!_osx%%#!" %_Nul3%
wimlib-imagex.exe export ISOFOLDER\x64\sources\%WIMFILE% %%# ISOFOLDER\x86\sources\%WIMFILE%
)

:BCD
echo.
echo %line%
echo Preparing boot configuration settings . . .
echo %line%
echo.
%_Nul3% xcopy ISOFOLDER\x64\boot\* ISOFOLDER\boot\ /cheriy
%_Nul3% xcopy ISOFOLDER\x64\efi\* ISOFOLDER\efi\ /cheriy
%_Nul3% copy /y ISOFOLDER\x64\bootmgr* ISOFOLDER\
%_Nul3% copy /y ISOFOLDER\x86\boot\bootsect.exe ISOFOLDER\boot\
set "BCDBIOS=ISOFOLDER\boot\bcd"
set "BCDUEFI=ISOFOLDER\efi\microsoft\boot\bcd"
if %custom% equ 0 (
%_Nul3% copy /y ISOFOLDER\x86\setup.exe ISOFOLDER\
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
)
for /f "tokens=5-10 delims=: " %%G in ('wimlib-imagex.exe info ISOFOLDER\x64\sources\boot.wim 2 ^| find /i "Last Modification Time"') do (set mmm=%%G&set "isotime=%%H/%%L,%%I:%%J:%%K")
for %%# in (Jan:01 Feb:02 Mar:03 Apr:04 May:05 Jun:06 Jul:07 Aug:08 Sep:09 Oct:10 Nov:11 Dec:12) do for /f "tokens=1,2 delims=:" %%A in ("%%#") do (
if /i %mmm%==%%A set "isotime=%%B/%isotime%"
)
%_Nul3% bcdedit /store %BCDBIOS% /set {bootmgr} nointegritychecks Yes
%_Nul3% bcdedit /store %BCDBIOS% /set {default} description "Windows Setup (64-bit) - BIOS"
%_Nul3% bcdedit /store %BCDBIOS% /set {default} device ramdisk=%entry64%
%_Nul3% bcdedit /store %BCDBIOS% /set {default} osdevice ramdisk=%entry64%
%_Nul3% bcdedit /store %BCDBIOS% /set {default} nointegritychecks Yes
%_Nul3% bcdedit /store %BCDBIOS% /set {default} nx OptIn
%_Nul3% bcdedit /store %BCDBIOS% /set {default} pae Default
%_Nul3% bcdedit /store %BCDBIOS% /set {default} ems No
%_Nul3% bcdedit /store %BCDBIOS% /deletevalue {default} bootmenupolicy
for /f "tokens=2 delims={}" %%# in ('bcdedit /store %BCDBIOS% /copy {default} /d "Windows Setup (32-bit) - BIOS"') do set "guid={%%#}"
%_Nul3% bcdedit /store %BCDBIOS% /set %guid% device ramdisk=%entry86%
%_Nul3% bcdedit /store %BCDBIOS% /set %guid% osdevice ramdisk=%entry86%
%_Nul3% bcdedit /store %BCDBIOS% /timeout 30
%_Nul3% attrib -s -h -a "%BCDBIOS%.LOG*"
%_Nul3% del /f /q "%BCDBIOS%.LOG*"
%_Nul3% bcdedit /store %BCDUEFI% /set {default} description "Windows Setup (64-bit) - UEFI"
%_Nul3% bcdedit /store %BCDUEFI% /set {default} device ramdisk=%entry64%
%_Nul3% bcdedit /store %BCDUEFI% /set {default} osdevice ramdisk=%entry64%
%_Nul3% bcdedit /store %BCDUEFI% /set {default} isolatedcontext Yes
%_Nul3% bcdedit /store %BCDUEFI% /set {default} nx OptIn
%_Nul3% bcdedit /store %BCDUEFI% /set {default} ems No
%_Nul3% attrib -s -h -a "%BCDUEFI%.LOG*"
%_Nul3% del /f /q "%BCDUEFI%.LOG*"
if not exist ISOFOLDER\efi\boot\bootx64.efi (
wimlib-imagex.exe extract ISOFOLDER\x64\sources\boot.wim 1 Windows\Boot\EFI\bootmgfw.efi --dest-dir=.\ISOFOLDER\efi\boot --no-acls --no-attribute %_Nul3%
rename ISOFOLDER\efi\boot\bootmgfw.efi bootx64.efi
)
if not exist ISOFOLDER\efi\microsoft\boot\memtest.efi (
wimlib-imagex.exe extract ISOFOLDER\x64\sources\boot.wim 1 Windows\Boot\EFI\memtest.efi --dest-dir=.\ISOFOLDER\efi\microsoft\boot --no-acls --no-attributes %_Nul3%
del /f /q ISOFOLDER\boot\memtest.efi %_Nul3%
bcdedit /store %BCDUEFI% /enum all | findstr /i {memdiag} 1>nul || (
  %_Nul3% bcdedit /store %BCDUEFI% /create {memdiag}
  %_Nul3% bcdedit /store %BCDUEFI% /set {memdiag} description "Windows Memory Diagnostic"
  %_Nul3% bcdedit /store %BCDUEFI% /set {memdiag} device boot
  %_Nul3% bcdedit /store %BCDUEFI% /set {memdiag} path \efi\microsoft\boot\memtest.efi
  %_Nul3% bcdedit /store %BCDUEFI% /set {memdiag} locale en-US
  %_Nul3% bcdedit /store %BCDUEFI% /set {memdiag} inherit {globalsettings}
  %_Nul3% bcdedit /store %BCDUEFI% /toolsdisplayorder {memdiag} /addlast
  )
)
if %custom% equ 0 goto :ISOCREATE
echo.
echo %line%
echo Preparing Custom AIO settings . . .
echo %line%
echo.
mkdir ISOFOLDER\sources
%_Nul3% move /y ISOFOLDER\x64\sources\boot.wim ISOFOLDER\sources\bootx64.wim
%_Nul3% move /y ISOFOLDER\x86\sources\boot.wim ISOFOLDER\sources\bootx86.wim
%_Nul3% move /y ISOFOLDER\x86\sources\%WIMFILE% ISOFOLDER\sources\
%_Nul3% move /y ISOFOLDER\x86\sources\lang.ini ISOFOLDER\sources\
call :dSETUP x64
call :dSETUP x86
if not exist "ISOFOLDER\x86\efi\boot\bootia32.efi" (
%_Nul3% rmdir /s /q ISOFOLDER\x64\
%_Nul3% rmdir /s /q ISOFOLDER\x86\
goto :ISOCREATE
)
%_Nul3% copy /y ISOFOLDER\x86\efi\boot\bootia32.efi ISOFOLDER\efi\boot\
%_Nul3% copy /y ISOFOLDER\x86\efi\microsoft\boot\memtest.efi ISOFOLDER\efi\microsoft\boot\memtestx86.efi
%_Nul3% rename ISOFOLDER\efi\microsoft\boot\memtest.efi memtestx64.efi
%_Nul3% bcdedit /store %BCDUEFI% /deletevalue {default} bootmenupolicy
for /f "tokens=2 delims={}" %%# in ('bcdedit /store %BCDUEFI% /copy {default} /d "Windows Setup (32-bit) - UEFI"') do set "guid={%%#}"
%_Nul3% bcdedit /store %BCDUEFI% /set %guid% device ramdisk=%entry86%
%_Nul3% bcdedit /store %BCDUEFI% /set %guid% osdevice ramdisk=%entry86%
%_Nul3% bcdedit /store %BCDUEFI% /timeout 30
%_Nul3% bcdedit /store %BCDUEFI% /set {memdiag} description "Windows Memory Diagnostic (64-bit)"
%_Nul3% bcdedit /store %BCDUEFI% /set {memdiag} path \efi\microsoft\boot\memtestx64.efi
for /f "tokens=2 delims={}" %%# in ('bcdedit /store %BCDUEFI% /copy {memdiag} /d "Windows Memory Diagnostic (32-bit)"') do set "guid={%%#}"
%_Nul3% bcdedit /store %BCDUEFI% /set %guid% path \efi\microsoft\boot\memtestx86.efi
%_Nul3% bcdedit /store %BCDUEFI% /toolsdisplayorder %guid% /addlast
%_Nul3% attrib -s -h -a "%BCDUEFI%.LOG*"
%_Nul3% del /f /q "%BCDUEFI%.LOG*"
%_Nul3% 7z.exe x ISOFOLDER\efi\microsoft\boot\efisys.bin -o.\bin\temp\
%_Nul3% copy /y ISOFOLDER\efi\boot\bootia32.efi bin\temp\EFI\Boot\BOOTIA32.EFI
%_Nul3% bfi.exe -t=288 -l=EFISECTOR -f=bin\efisys.ima bin\temp
%_Nul3% move /y bin\efisys.ima ISOFOLDER\efi\microsoft\boot\efisys.bin
%_Nul3% del /f /q ISOFOLDER\efi\microsoft\boot\*noprompt.*
%_Nul3% rmdir /s /q bin\temp\
%_Nul3% rmdir /s /q ISOFOLDER\x64\
%_Nul3% rmdir /s /q ISOFOLDER\x86\

:ISOCREATE
echo.
echo %line%
echo Creating ISO . . .
echo %line%
%_Nul3% robocopy mARCHiso ISOFOLDER /E /XF .README
if exist "ISOFOLDER\efi\microsoft\boot\efisys.bin" (
cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO
) else (
cdimage.exe -b"ISOFOLDER\boot\etfsboot.com" -o -m -u2 -udfver102 -t%isotime% -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO
)
set ERRORTEMP=%ERRORLEVEL%
if %ERRORTEMP% neq 0 (
  ren ISOFOLDER %DVDISO%
  echo.
  echo Errors were reported during ISO creation.
  echo.
  goto :QUIT
)
rmdir /s /q ISOFOLDER\
echo.
goto :QUIT

:dSETUP
(
echo [LaunchApps]
echo ^%%SystemRoot^%%\system32\wpeinit.exe
echo ^%%SystemDrive^%%\sources\setup%1.exe
echo.
)>bin\winpeshl.ini
for /f %%# in ('wimlib-imagex.exe dir ISOFOLDER\sources\boot%1.wim 2 --path=\sources ^| find /i "setup.exe.mui"') do wimlib-imagex.exe update ISOFOLDER\sources\boot%1.wim 2 --command="rename '%%#' '%%~p#setup%1.exe.mui'" %_Nul3%
%_Nul3% wimlib-imagex.exe update ISOFOLDER\sources\boot%1.wim 2 --command="rename 'sources\setup.exe' 'sources\setup%1.exe'"
%_Nul3% wimlib-imagex.exe update ISOFOLDER\sources\boot%1.wim 2 --command="add 'bin\winpeshl.ini' '\Windows\system32\winpeshl.ini'"
%_Nul3% wimlib-imagex.exe extract ISOFOLDER\sources\boot%1.wim 2 sources\setup%1.exe --dest-dir=.\ISOFOLDER\sources --no-acls --no-attributes
%_Nul3% del /f /q bin\winpeshl.ini
exit /b

:dInfo
if not exist "!ISOdir%1!\sources\boot.wim" (set "MESSAGE=ISO %1 is missing boot.wim"&goto :E_MSG)
dir /b "!ISOdir%1!\sources\install.wim" %_Nul3% && (set WIMFILE%1=install.wim)
dir /b "!ISOdir%1!\sources\install.esd" %_Nul3% && (set WIMFILE%1=install.esd)
dir /b "!ISOdir%1!\sources\install.swm" %_Nul3% && (set WIMFILE%1=install.swm&set wimswm=1)
if /i !WIMFILE%1! equ 0 (set "MESSAGE=ISO %1 is missing install .wim/.esd/.swm"&goto :E_MSG)
wimlib-imagex.exe info "!ISOdir%1!\sources\!WIMFILE%1!">bin\infoall.txt 2>&1
find /i "CoreCountrySpecific" bin\infoall.txt 1>nul && (set ISOeditionc%1=1) || (set ISOeditionc%1=0)
wimlib-imagex.exe info "!ISOdir%1!\sources\!WIMFILE%1!" 1 >bin\info.txt 2>&1
for /f "tokens=2 delims=: " %%# in ('findstr /i /b "Build" bin\info.txt') do set _build=%%#
set /a _fixSV=%_build%+1
for /f "tokens=2 delims=: " %%# in ('findstr /i /b "Build" bin\info.txt') do set ISOver%1=%%#
for /f "tokens=3 delims=: " %%# in ('findstr /i /b "Edition" bin\info.txt') do set ISOedition%1=%%#
for /f "tokens=3 delims=: " %%# in ('findstr /i "Default" bin\info.txt') do set ISOlang%1=%%#
for /f "tokens=2 delims=: " %%# in ('findstr /i "Architecture" bin\info.txt') do (if /i %%# equ x86 (set ISOarch%1=x86) else if /i %%# equ x86_64 (set ISOarch%1=x64))
for /f "tokens=3 delims=: " %%# in ('findstr /i /b /c:"Image Count" bin\infoall.txt') do (if %%# geq 2 set ISOmulti%1=%%#)
for /f "tokens=2 delims=: " %%# in ('wimlib-imagex.exe info "!ISOdir%1!\sources\boot.wim" 1 ^| findstr /i /b "Build"') do set BOOTver%1=%%#
if /i !BOOTver%1! lss 10240 (set winx=0)
if /i !ISOarch%1! equ 0 (set "MESSAGE=ISO %1 architecture is not supported."&goto :E_MSG)
if exist "!ISOdir%1!\sources\ei.cfg" type "!ISOdir%1!\sources\ei.cfg" 2>nul | find /i "Volume" 1>nul && set ISOvol%1=1
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
if /i !ISOedition%1!==Cloud set DVDLABEL%1=CWCA&set DVDISO%1=CLOUD_OEM
if /i !ISOedition%1!==CloudN set DVDLABEL%1=CWCNNA&set DVDISO%1=CLOUDN_OEM
if /i !ISOedition%1!==PPIPro set DVDLABEL%1=CPPIA&set DVDISO%1=PPIPRO_OEM
if /i !ISOedition%1!==EnterpriseG set DVDLABEL%1=CEGA&set DVDISO%1=ENTERPRISEG_VOL
if /i !ISOedition%1!==EnterpriseGN set DVDLABEL%1=CEGNA&set DVDISO%1=ENTERPRISEGN_VOL
if /i !ISOedition%1!==EnterpriseS set DVDLABEL%1=CES&set DVDISO%1=ENTERPRISES_VOL
if /i !ISOedition%1!==EnterpriseSN set DVDLABEL%1=CESNN&set DVDISO%1=ENTERPRISESN_VOL
if /i !ISOedition%1!==ProfessionalEducation (if !ISOvol%1!==1 (set DVDLABEL%1=CPREA&set DVDISO%1=PROEDUCATION_VOL) else (set DVDLABEL%1=CPREA&set DVDISO%1=PROEDUCATION_OEMRET))
if /i !ISOedition%1!==ProfessionalEducationN (if !ISOvol%1!==1 (set DVDLABEL%1=CPRENA&set DVDISO%1=PROEDUCATIONN_VOL) else (set DVDLABEL%1=CPRENA&set DVDISO%1=PROEDUCATIONN_OEMRET))
if /i !ISOedition%1!==ProfessionalWorkstation (if !ISOvol%1!==1 (set DVDLABEL%1=CPRWA&set DVDISO%1=PROWORKSTATION_VOL) else (set DVDLABEL%1=CPRWA&set DVDISO%1=PROWORKSTATION_OEMRET))
if /i !ISOedition%1!==ProfessionalWorkstationN (if !ISOvol%1!==1 (set DVDLABEL%1=CPRWNA&set DVDISO%1=PROWORKSTATIONN_VOL) else (set DVDLABEL%1=CPRWNA&set DVDISO%1=PROWORKSTATIONN_OEMRET))
if /i !ISOedition%1!==ProfessionalSingleLanguage set DVDLABEL%1=CPRSLA&set DVDISO%1=PROSINGLELANGUAGE_OEM
if /i !ISOedition%1!==ProfessionalCountrySpecific set DVDLABEL%1=CPRCHA&set DVDISO%1=PROCHINA_OEM
if /i !ISOedition%1!==CloudEdition (if !ISOvol%1!==1 (set DVDLABEL%1=CWCA&set DVDISO%1=CLOUD_VOL) else (set DVDLABEL%1=CWCA&set DVDISO%1=CLOUD_OEMRET))
if /i !ISOedition%1!==CloudEditionN (if !ISOvol%1!==1 (set DVDLABEL%1=CWCNNA&set DVDISO%1=CLOUDN_VOL) else (set DVDLABEL%1=CWCNNA&set DVDISO%1=CLOUDN_OEMRET))
if !ISOmulti%1! geq 2 (
set DVDLABEL%1=CCSA&set DVDISO%1=MULTI_OEMRET
if !ISOeditionc%1!==1 set DVDLABEL%1=CCCHA&set DVDISO%1=MULTICHINA_OEMRET
)
if /i !ISOarch%1!==x86 (set ISOarch%1=X86) else (set ISOarch%1=X64)
if %1==2 exit /b

set "ISOdir=!ISOdir%1!"
if !ISOver%1! geq 17063 (
wimlib-imagex.exe extract "%ISOdir%\sources\boot.wim" 2 sources\setuphost.exe --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
7z.exe l .\bin\temp\setuphost.exe >.\bin\temp\version.txt 2>&1
) else (
wimlib-imagex.exe extract "%ISOdir%\sources\%WIMFILE%" 1 Windows\System32\ntoskrnl.exe --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
7z.exe l .\bin\temp\ntoskrnl.exe >.\bin\temp\version.txt 2>&1
)
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\temp\version.txt" %_Nul6%') do (set uupver=%%i.%%j&set uupmaj=%%i&set uupmin=%%j&set branch=%%k&set uupdate=%%l)
set revver=%uupver%&set revmaj=%uupmaj%&set revmin=%uupmin%
set "tok=6,7"&set "toe=5,6,7"
if /i !ISOarch%1!==x86 (set _ss=x86) else if /i !ISOarch%1!==x64 (set _ss=amd64)
wimlib-imagex.exe extract "%ISOdir%\sources\%WIMFILE%" 1 Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision*.manifest --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
if exist "bin\temp\*_microsoft-windows-coreos-revision*.manifest" for /f "tokens=%tok% delims=_." %%A in ('dir /b /a:-d /od .\bin\temp\*_microsoft-windows-coreos-revision*.manifest') do set revver=%%A.%%B&set revmaj=%%A&set revmin=%%B
if !ISOver%1! geq 15063 (
wimlib-imagex.exe extract "%ISOdir%\sources\%WIMFILE%" 1 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
set "isokey=Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
for /f %%i in ('"offlinereg.exe .\bin\temp\SOFTWARE "!isokey!" enumkeys %_Nul6% ^| findstr /i /r ".*\.OS""') do if not errorlevel 1 (
  for /f "tokens=3 delims==:" %%A in ('"offlinereg.exe .\bin\temp\SOFTWARE "!isokey!\%%i" getvalue Branch %_Nul6%"') do set "revbranch=%%~A"
  for /f "tokens=5,6 delims==:." %%A in ('"offlinereg.exe .\bin\temp\SOFTWARE "!isokey!\%%i" getvalue Version %_Nul6%"') do if %%A gtr !revmaj! (
    set "revver=%%~A.%%B
    set revmaj=%%~A
    set "revmin=%%B
    )
  )
)
set chkmin=%revmin%
if !ISOver%1! geq 17063 (
call :setuphostprep
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\version.txt" %_Nul6%') do (set uupver=%%i.%%j&set uupmaj=%%i&set uupmin=%%j&set branch=%%k&set uupdate=%%l)
del /f /q .\bin\version.txt %_Nul3%
)
if defined revbranch set branch=%revbranch%
if %revmaj%==18363 (
if /i "%branch:~0,4%"=="19h1" set branch=19h2%branch:~4%
if %uupver:~0,5%==18362 set uupver=18363%uupver:~5%
)
if %revmaj%==19042 (
if /i "%branch:~0,2%"=="vb" set branch=20h2%branch:~2%
if %uupver:~0,5%==19041 set uupver=19042%uupver:~5%
)
if %revmaj%==19043 (
if /i "%branch:~0,2%"=="vb" set branch=21h1%branch:~2%
if %uupver:~0,5%==19041 set uupver=19043%uupver:~5%
)
if %revmaj%==19044 (
if /i "%branch:~0,2%"=="vb" set branch=21h2%branch:~2%
if %uupver:~0,5%==19041 set uupver=19044%uupver:~5%
)
if %revmaj%==19045 (
if /i "%branch:~0,2%"=="vb" set branch=22h2%branch:~2%
if %uupver:~0,5%==19041 set uupver=19045%uupver:~5%
)
if %revmaj%==%_fixSV% if %_build% geq 21382 (
if %uupver:~0,5%==%_build% set uupver=%_fixSV%%uupver:~5%
)
if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
del /f /q bin\temp\*.mum %_Nul3%
wimlib-imagex.exe extract "%ISOdir%\sources\%WIMFILE%" 1 Windows\Servicing\Packages\Package_for_RollupFix*.mum --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
if exist "bin\temp\Package_for_RollupFix*.mum" (
set uupver=%revver%
set uupmin=%revmin%
for /f %%# in ('dir /b /a:-d /od bin\temp\Package_for_RollupFix*.mum') do copy /y "bin\temp\%%#" %SystemRoot%\temp\update.mum %_Nul1%
call :datemum uupdate
)
set _legacy=
set _useold=0
if /i "%branch%"=="WinBuild" set _useold=1
if /i "%branch%"=="GitEnlistment" set _useold=1
if /i "%uupdate%"=="winpbld" set _useold=1
if %_useold% equ 1 (
wimlib-imagex.exe extract "%ISOdir%\sources\%WIMFILE%" 1 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Null%
for /f "tokens=3 delims==:" %%# in ('"offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion" getvalue BuildLabEx" %_Nul6%') do if not errorlevel 1 (for /f "tokens=1-5 delims=." %%i in ('echo %%~#') do set _legacy=%%i.%%j.%%m.%%l&set branch=%%l)
)
if defined _legacy (set _label=%_legacy%) else (set _label=%uupver%.%uupdate%.%branch%)
rmdir /s /q bin\temp\
set _label=%_label%_CLIENT
set langid=!ISOlang%1!
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _label=!_label:%%#=%%#!
set langid=!langid:%%#=%%#!
)
exit /b

:datemum
set "mumfile=%SystemRoot%\temp\update.mum"
set "chkfile=!mumfile:\=\\!"
if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!chkfile!'" get LastModified /value') do set "mumdate=%%#"
if %_cwmi% equ 0 for /f %%# in ('powershell -nop -c "([WMI]'CIM_DataFile.Name=\"!chkfile!\"').LastModified"') do set "mumdate=%%#"
del /f /q %SystemRoot%\temp\*.mum
set "%1=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
exit /b

:setuphostprep
wimlib-imagex.exe extract "%ISOdir%\sources\boot.wim" 2 sources\setuphost.exe --dest-dir=%SystemRoot%\temp --no-acls --no-attributes %_Nul3%
wimlib-imagex.exe extract "%ISOdir%\sources\boot.wim" 2 sources\setupprep.exe --dest-dir=%SystemRoot%\temp --no-acls --no-attributes %_Nul3%
wimlib-imagex.exe extract "%ISOdir%\sources\%WIMFILE%" 1 Windows\system32\UpdateAgent.dll --dest-dir=%SystemRoot%\temp --no-acls --no-attributes %_Nul3%
wimlib-imagex.exe extract "%ISOdir%\sources\%WIMFILE%" 1 Windows\system32\Facilitator.dll --dest-dir=%SystemRoot%\temp --no-acls --no-attributes %_Nul3%
set _svr1=0&set _svr2=0&set _svr3=0&set _svr4=0
set "_fvr1=%SystemRoot%\temp\UpdateAgent.dll"
set "_fvr2=%SystemRoot%\temp\setupprep.exe"
set "_fvr3=%SystemRoot%\temp\setuphost.exe"
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
if exist "!_fvr1!" for /f "tokens=4 delims=." %%a in ('powershell -nop -c "([WMI]'CIM_DataFile.Name=\"!cfvr1!\"').Version"') do set /a "_svr1=%%a"
if exist "!_fvr2!" for /f "tokens=4 delims=." %%a in ('powershell -nop -c "([WMI]'CIM_DataFile.Name=\"!cfvr2!\"').Version"') do set /a "_svr2=%%a"
if exist "!_fvr3!" for /f "tokens=4 delims=." %%a in ('powershell -nop -c "([WMI]'CIM_DataFile.Name=\"!cfvr3!\"').Version"') do set /a "_svr3=%%a"
if exist "!_fvr4!" for /f "tokens=4 delims=." %%a in ('powershell -nop -c "([WMI]'CIM_DataFile.Name=\"!cfvr4!\"').Version"') do set /a "_svr4=%%a"
)
set "_chk=!_fvr1!"
if %chkmin% equ %_svr1% set "_chk=!_fvr1!"&goto :prephostsetup
if %chkmin% equ %_svr2% set "_chk=!_fvr2!"&goto :prephostsetup
if %chkmin% equ %_svr3% set "_chk=!_fvr3!"&goto :prephostsetup
if %chkmin% equ %_svr4% set "_chk=!_fvr4!"&goto :prephostsetup
if %_svr2% gtr %_svr1% (
if %_svr2% gtr %_svr3% if %_svr2% gtr %_svr4% set "_chk=!_fvr2!"
if %_svr3% gtr %_svr2% if %_svr3% gtr %_svr4% set "_chk=!_fvr3!"
if %_svr4% gtr %_svr2% if %_svr4% gtr %_svr3% set "_chk=!_fvr4!"
)
if %_svr3% gtr %_svr1% (
if %_svr2% gtr %_svr3% if %_svr2% gtr %_svr4% set "_chk=!_fvr2!"
if %_svr3% gtr %_svr2% if %_svr3% gtr %_svr4% set "_chk=!_fvr3!"
if %_svr4% gtr %_svr2% if %_svr4% gtr %_svr3% set "_chk=!_fvr4!"
)
if %_svr4% gtr %_svr1% (
if %_svr2% gtr %_svr3% if %_svr2% gtr %_svr4% set "_chk=!_fvr2!"
if %_svr3% gtr %_svr2% if %_svr3% gtr %_svr4% set "_chk=!_fvr3!"
if %_svr4% gtr %_svr2% if %_svr4% gtr %_svr3% set "_chk=!_fvr4!"
)

:prephostsetup
7z.exe l "%_chk%" >.\bin\version.txt 2>&1
del /f /q "!_fvr1!" "!_fvr2!" "!_fvr3!" "!_fvr4!" %_Nul3%
exit /b

:E_Admin
echo %_err%
echo This script require administrator privileges.
echo To do so, right click on this script and select 'Run as administrator'
echo.
echo Press any key to exit.
pause >nul
exit /b

:E_PS
echo %_err%
echo Windows PowerShell is required for this script to work.
echo.
echo Press any key to exit.
pause >nul
exit /b

:E_Bin
echo %_err%
echo Required file %_bin% is missing.
echo.
echo Press any key to exit.
pause >nul
exit /b

:E_MSG
echo.
echo %line%
echo %_err%
echo %MESSAGE%
echo.
echo.

:QUIT
if exist bin\temp\ rmdir /s /q bin\temp\
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
if exist ISOx64\ rmdir /s /q ISOx64\
if exist ISOx86\ rmdir /s /q ISOx86\
popd
if %_Debug% neq 0 (exit /b) else (echo Press 0 to exit.)
choice /c 0 /n
if errorlevel 1 (exit) else (rem.)

----- Begin wsf script --->
<package>
   <job id="ELAV">
       <script language="VBScript">
           Set strArg=WScript.Arguments.Named
           If Not strArg.Exists("File") Then
               Wscript.Echo "Switch /File:<File> is missing."
               WScript.Quit 1
           End If
           Set strRdlproc = CreateObject("WScript.Shell").Exec("rundll32 kernel32,Sleep")
           With GetObject("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" & strRdlproc.ProcessId & "'")
               With GetObject("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" & .ParentProcessId & "'")
                   If InStr (.CommandLine, WScript.ScriptName) <> 0 Then
                       strLine = Mid(.CommandLine, InStr(.CommandLine , "/File:") + Len(strArg("File")) + 8)
                   End If
               End With
               .Terminate
           End With
          CreateObject("Shell.Application").ShellExecute "cmd.exe", "/c " & chr(34) & chr(34) & strArg("File") & chr(34) & strLine & chr(34), "", "runas", 1
       </script>
   </job>
</package>